#!/usr/bin/env bash
# test-connector-secret-ac3-leak-sweep.sh -- AC-3 leak-proof sweep for
# canonical/aid/scripts/connectors/connector-secret.{sh,ps1} (task-011,
# work-002-external_sources / feature-003 "Local Auth Registration").
#
# task-006 already shipped two suites that cover the twin's own unit
# behavior in full:
#   - tests/canonical/test-connector-secret.sh      (29 assertions, Bash twin)
#   - tests/canonical/test-connector-secret-ps1.sh  (26 assertions, PS1 twin)
# Both already prove: write stores exact bytes and records only the `file:`
# reference; no-echo (the value is absent from the twin's OWN captured
# stdout/stderr); path-confinement rejects separators/`..`; purge is
# idempotent; write fails closed when the ignore precondition is unmet. This
# suite does NOT re-implement ANY of those assertions -- it references them
# and adds the one thing they do not cover: AC-3's repo-wide leak-proof
# SWEEP -- proving a secret this feature registers is not merely absent from
# the twin's own process output, but absent from the repo working tree, the
# Knowledge Base, and every STATE.md, once the write has completed and the
# process has exited.
#
# Scope (work-002 STATE.md Q5 / feature-003 SPEC.md "Security Specs" --
# "Leak-proof (AC-3)"): this sweep proves OUR registered secret does not
# leak. It is explicitly NOT a repo-wide scan for pre-existing committed
# secrets -- that is out of scope for this feature (Q5b) and is the
# discovery phase's tech-debt/risk concern, not remediated here.
#
# On "the session transcript" (REQUIREMENTS.md §9 AC-3 wording; feature-003
# SPEC.md "Security Specs"): a session transcript is the live agent
# conversation, not a repo-tracked, git-checkout-local artifact -- there is
# no deterministic file this suite can sweep for it in an isolated test run.
# What a transcript WOULD capture is exactly this twin's stdout/stderr, and
# task-006's T4/T5 (both twins) already assert the value is absent from
# captured stdout AND stderr in every `write` invocation. That is the
# automatable proxy for "never reaches a transcript"; this suite adds no
# separate transcript check because there is no addressable transcript file
# to check.
#
# Tests cover:
#   T1  sweep: sentinel absent from the repo working tree (excl. fixture, .git)
#   T2  sweep: sentinel absent from .aid/knowledge/ (the KB)
#   T3  sweep: sentinel absent from every STATE.md under .aid/
#   T4  sweep: sentinel found ONLY at the fixture's own .secrets/<stem> store
#   T5  reference-not-value: a simulated committed descriptor holding the
#       printed `file:` reference never carries the secret value
#   T6  (pwsh only, skipped when pwsh is unavailable) repeats T1-T3 for a
#       SECOND, independent sentinel registered via the connector-secret.ps1
#       twin -- proves the leak-proof property holds regardless of which
#       twin performed the write (AC-8 cross-platform intent). This does NOT
#       re-run test-connector-secret-ps1.sh's own unit assertions; it is the
#       repo-wide sweep only, which that suite does not perform.
#
# Usage:
#   bash test-connector-secret-ac3-leak-sweep.sh [--verbose]
#
# Exit codes:
#   0  all tests passed (or skipped, for the pwsh-gated T6)
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-secret.sh"
SUT_PS1="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-secret.ps1"

source "${SCRIPT_DIR}/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

echo "== connector-secret AC-3 leak-proof sweep =="

# ---------------------------------------------------------------------------
# Fixture: a throwaway connectors root under the OS temp dir (mktemp -d is
# never under $REPO_ROOT), removed unconditionally on exit via trap -- this
# suite never writes its sentinel(s) anywhere persistent. NEVER touches the
# repo's real .aid/connectors/.
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ROOT="${TMPDIR}/connectors"
mkdir -p "$ROOT"
printf '.secrets/\n' > "${ROOT}/.gitignore"

# A sentinel unique to this run: random, so a clean sweep is a true negative
# (the value could not plausibly pre-exist anywhere in the repo/KB/STATE),
# not a coincidental one. This is a synthetic, disposable test token -- not a
# real credential -- so printing it to this run's own console output below is
# not a leak of anything AC-3 governs (AC-3 governs the committed repo / KB /
# STATE, not a script's transient stdout on the developer's own machine).
gen_sentinel() {
    local suffix="$1" randid
    randid="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
    if [[ -z "$randid" ]]; then
        randid="$$-$(date +%s%N 2>/dev/null || date +%s)"
    fi
    printf 'AC3-LEAK-SWEEP-SENTINEL-%s-%s' "$suffix" "$randid"
}

SENTINEL="$(gen_sentinel bash)"
STEM="ac3sweep"
echo "Sentinel for this run (synthetic, disposed at exit): ${SENTINEL}"

# ---------------------------------------------------------------------------
# sweep_for VALUE LABEL -- greps the repo working tree (excluding the
# fixture and .git), the KB, and every STATE.md under .aid/ for VALUE;
# asserts each comes back empty.
# ---------------------------------------------------------------------------
sweep_for() {
    local value="$1" label="$2"
    local repo_hits kb_hits state_hits state_file

    repo_hits=$(grep -rF --exclude-dir=.git -- "$value" "$REPO_ROOT" 2>/dev/null \
                | grep -v -F -- "$TMPDIR" || true)
    assert_eq "$repo_hits" "" "${label}: sentinel absent from the repo working tree"

    kb_hits=$(grep -rF -- "$value" "${REPO_ROOT}/.aid/knowledge" 2>/dev/null || true)
    assert_eq "$kb_hits" "" "${label}: sentinel absent from .aid/knowledge/ (KB)"

    state_hits=""
    while IFS= read -r state_file; do
        if grep -qF -- "$value" "$state_file" 2>/dev/null; then
            state_hits="${state_hits}${state_file}"$'\n'
        fi
    done < <(find "${REPO_ROOT}/.aid" -iname 'STATE.md' -type f)
    assert_eq "$state_hits" "" "${label}: sentinel absent from every STATE.md under .aid/"
}

# ---------------------------------------------------------------------------
# T1-T3: register the sentinel via the Bash twin, then sweep repo/KB/STATE.
# ---------------------------------------------------------------------------
ref_out=$(printf '%s\n' "$SENTINEL" | bash "$SUT" write "$STEM" --root "$ROOT" 2>"${TMPDIR}/stderr_write")
write_ec=$?
if [[ $write_ec -ne 0 ]]; then
    fail "T0-setup: connector-secret.sh write failed unexpectedly (exit $write_ec)"
fi

sweep_for "$SENTINEL" "T1-T3 (bash-twin write)"

# ---------------------------------------------------------------------------
# T4: the sentinel is found ONLY at the fixture's own store -- not merely
# "absent everywhere we checked" but "present exactly where it should be".
# ---------------------------------------------------------------------------
store_file="${ROOT}/.secrets/${STEM}"
stored_value="$(cat "$store_file" 2>/dev/null)"
assert_eq "$stored_value" "$SENTINEL" "T4: sentinel found ONLY at the fixture's .secrets/${STEM} store"

# ---------------------------------------------------------------------------
# T5: reference-not-value -- a descriptor artifact (the shape feature-002
# authors and feature-003 guarantees stays a reference; see
# tests/canonical/test-build-connectors-index.sh for the real frontmatter
# shape) holding the printed reference never carries the secret value.
# ---------------------------------------------------------------------------
assert_eq "${ref_out#file:}" "${store_file}" "T5a: write's printed reference points at the fixture store path"

descriptor="${TMPDIR}/descriptor.md"
cat > "$descriptor" <<EOF
---
name: ac3sweep-fixture
connection_type: cli
auth_method: pat
secret_reference: "${ref_out}"
summary: AC-3 leak-sweep fixture descriptor.
---
EOF
assert_file_not_contains "$descriptor" "$SENTINEL" "T5b: a committed descriptor holding the reference never carries the value"
assert_file_contains "$descriptor" "file:" "T5c: the descriptor's secret_reference is a reference (file: prefix), not the raw value"

# ---------------------------------------------------------------------------
# T6: cross-platform intent (AC-8) -- repeat the sweep for a second,
# independent sentinel registered via the PowerShell twin, proving the
# leak-proof property is independent of which twin performed the write.
# Skipped (not failed) when pwsh is unavailable, mirroring
# test-connector-secret-ps1.sh's own skip convention.
# ---------------------------------------------------------------------------
if [[ -f "$SUT_PS1" ]] && command -v pwsh >/dev/null 2>&1; then
    SENTINEL2="$(gen_sentinel ps1)"
    STEM2="ac3sweepps1"
    echo "Sentinel for ps1-twin run (synthetic, disposed at exit): ${SENTINEL2}"

    ps1_out=$(printf '%s\n' "$SENTINEL2" | pwsh -NoProfile -NonInteractive -File "$SUT_PS1" write "$STEM2" -Root "$ROOT" 2>"${TMPDIR}/ps1_stderr")
    ps1_ec=$?
    if [[ $ps1_ec -ne 0 ]]; then
        fail "T6-setup: connector-secret.ps1 write failed unexpectedly (exit $ps1_ec)"
    fi

    sweep_for "$SENTINEL2" "T6 (ps1-twin write)"

    ps1_store_file="${ROOT}/.secrets/${STEM2}"
    ps1_stored_value="$(cat "$ps1_store_file" 2>/dev/null)"
    assert_eq "$ps1_stored_value" "$SENTINEL2" "T6d: ps1-twin sentinel found ONLY at the fixture's .secrets/${STEM2} store"
else
    echo "SKIP: pwsh not found on PATH (or connector-secret.ps1 missing) -- T6 cross-platform sweep skipped."
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
test_summary
exit $?
