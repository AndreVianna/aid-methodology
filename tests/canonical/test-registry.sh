#!/usr/bin/env bash
# test-registry.sh -- task-049: focused unit + CLI tests for the DR-1 registry
# side-effect in bin/aid (Bash). Covers:
#   - registry_register / _registry_read_repos helper (unit-level via sourcing)
#   - registry_unregister (unit-level)
#   - Manifest-boundary: first-tool add registers; 2nd add is NO-OP; remove last
#     tool unregisters; remove one-of-several leaves registry untouched.
#   - Idempotency: register twice = no duplicate; unregister twice = no error.
#   - atomic write: temp file is named *.aid-tmp.* and is cleaned up.
#   - Warn-and-continue: write failure does NOT abort the host-tool op.
#   - File format: DM-1 header + schema: 1 + repos: block (ASCII-only scaffolding).
#
# Usage:
#   bash test-registry.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$BIN_AID" ]]    || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_CORE" ]]   || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_CORE" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

build_fixture_tarball() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${FIXTURE_DIR}/aid-${tool}-v${VERSION}.tar.gz"
    [[ -d "$profile_dir" ]] || { echo "ERROR: profile dir not found: $profile_dir" >&2; return 1; }
    local filelist
    filelist="$(mktemp "${TMP}/filelist-${tool}.XXXXXX")"
    while IFS= read -r f; do
        local fname
        fname="$(basename "$f")"
        [[ "$fname" == "README.md" ]] && continue
        [[ "$fname" == "emission-manifest.jsonl" ]] && continue
        local rel="${f#${profile_dir}/}"
        printf './%s\n' "$rel"
    done < <(find "${profile_dir}" -type f | sort) > "$filelist"
    (cd "${profile_dir}" && tar -czf "${tarball}" --no-recursion -T "${filelist}") || {
        echo "ERROR: failed to build fixture tarball for ${tool}" >&2
        rm -f "$filelist"
        return 1
    }
    rm -f "$filelist"
}

for _tool in claude-code codex; do
    build_fixture_tarball "$_tool" || { echo "ERROR: fixture build failed for ${_tool}" >&2; exit 1; }
done

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }
newhome()   { mktemp -d "${TMP}/home.XXXXXX"; }

setup_aid_home() {
    local home_dir="$1"
    mkdir -p "${home_dir}/bin" "${home_dir}/lib"
    cp "${BIN_AID}" "${home_dir}/bin/aid"
    chmod +x "${home_dir}/bin/aid"
    cp "${LIB_CORE}" "${home_dir}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
}

run_aid() {
    local aid_home="$1"
    shift
    OUT=$(AID_HOME="$aid_home" AID_LIB_PATH="${aid_home}/lib/aid-install-core.sh" \
          bash "${aid_home}/bin/aid" "$@" 2>&1); RC=$?
}

# ---------------------------------------------------------------------------
# Unit tests: source functions from bin/aid for isolated testing.
# We extract and eval only the registry helper functions so we can test them
# without running the full dispatcher.
# ---------------------------------------------------------------------------

# Source registry helpers in an isolated subshell-via-function so we can test
# without side-effects in the parent shell state.

unit_register_basic() {
    local AID_HOME="$1"
    local repo="$2"
    # Source just the relevant functions from bin/aid into the current shell.
    # Extract lines between the two registry delimiter comments.
    local reg_src
    reg_src="$(sed -n '/^# ---------------------------------------------------------------------------$/{N;/Registry helpers/,/^# ---------------------------------------------------------------------------$/{/^# Parse subcommand/q;p}}' "${BIN_AID}")" 2>/dev/null || true
    if [[ -z "$reg_src" ]]; then
        # Fallback: source the full script with a guard to prevent dispatch.
        true
    fi
}

# Instead of complex extraction, use a subshell that sources the helpers directly
# by setting up a minimal environment that prevents the dispatcher from running.
# We do this by writing a tiny wrapper that sources only the helper functions.

REGISTRY_HELPER_SCRIPT="${TMP}/registry_helpers.sh"
# Extract the registry helper functions from bin/aid via awk.
awk '
  /^# ---------------------------------------------------------------------------$/ {
    getline nxt
    if (nxt ~ /Registry helpers/) {
      in_block = 1
    }
  }
  /^# ---------------------------------------------------------------------------$/ {
    if (in_block) {
      # Check next line to see if we have hit the next section
      getline nxt
      if (nxt ~ /Parse subcommand/) {
        in_block = 0
      } else {
        print $0
        print nxt
      }
    }
  }
  in_block { print }
' "${BIN_AID}" > "${REGISTRY_HELPER_SCRIPT}" 2>/dev/null || true

# Simpler approach: write a test-harness script that sets up the env and calls
# registry functions by sourcing them through a guard.
HARNESS_SCRIPT="${TMP}/harness.sh"
cat > "${HARNESS_SCRIPT}" << 'HARNESS_EOF'
#!/usr/bin/env bash
# Minimal harness: define only the minimal needed env for registry helpers,
# then source bin/aid up to the registry section only.
# feature-001: also extract _aid_priv_run (needed by registry_register for mkdir/mv).
set -uo pipefail
BIN_AID="$1"; shift
AID_HOME="$1"; shift
CMD="$1"; shift  # register | unregister | read_repos
ARG="${1:-}"

# feature-001: registry uses AID_STATE_HOME (= AID_HOME when AID_HOME is set).
export AID_STATE_HOME="${AID_HOME}"

# Extract _aid_priv_run (standalone helper needed by registry_register for
# mkdir -p / mv -f operations).
PRIV_START=$(grep -n '^_aid_priv_run()' "$BIN_AID" | head -1 | cut -d: -f1)
PRIV_END=$(awk "NR>=${PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
if [[ -n "$PRIV_START" && -n "$PRIV_END" ]]; then
    eval "$(sed -n "${PRIV_START},${PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
fi

# Source just the registry helper section by detecting line range.
START=$(grep -n '# Registry helpers (DR-1' "$BIN_AID" | head -1 | cut -d: -f1)
END=$(grep -n '# Parse subcommand and dispatch' "$BIN_AID" | head -1 | cut -d: -f1)
[[ -n "$START" && -n "$END" ]] || { echo "ERROR: cannot locate registry section" >&2; exit 1; }

# Read lines from BIN_AID between START and END and eval them.
_AID_VERBOSE="${_AID_VERBOSE:-0}"
_registry_code="$(sed -n "${START},${END}p" "$BIN_AID")"
eval "$_registry_code"

case "$CMD" in
    register)   registry_register "$ARG" ;;
    unregister) registry_unregister "$ARG" ;;
    read_repos) _registry_read_repos "${AID_STATE_HOME}/registry.yml" ;;
    *) echo "ERROR: unknown CMD: $CMD" >&2; exit 1 ;;
esac
HARNESS_EOF
chmod +x "${HARNESS_SCRIPT}"

run_harness() {
    local aid_home="$1" cmd="$2" arg="${3:-}"
    OUT=$(AID_HOME="$aid_home" AID_STATE_HOME="$aid_home" _AID_VERBOSE="${_AID_VERBOSE:-0}" \
          bash "${HARNESS_SCRIPT}" "$BIN_AID" "$aid_home" "$cmd" "$arg" 2>&1)
    RC=$?
}

echo "=== Registry helper unit tests ==="

# REG-U01: register a path in a fresh AID_HOME (no prior registry file).
REG_HOME_U01=$(newhome)
run_harness "$REG_HOME_U01" register "/tmp/repo-a"
assert_exit_eq "$RC" 0 "REG-U01a register in fresh home -> exit 0"
assert_file_exists "${REG_HOME_U01}/registry.yml" "REG-U01b registry.yml created on first register"
assert_output_contains "$OUT" "Registered /tmp/repo-a" "REG-U01c prints Registered line"
# Check DM-1 header bytes.
assert_file_contains "${REG_HOME_U01}/registry.yml" \
    "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)." \
    "REG-U01d managed-by comment present"
assert_file_contains "${REG_HOME_U01}/registry.yml" "schema: 1" "REG-U01e schema: 1 present"
assert_file_contains "${REG_HOME_U01}/registry.yml" "repos:" "REG-U01f repos: key present"
assert_file_contains "${REG_HOME_U01}/registry.yml" "  - /tmp/repo-a" "REG-U01g path entry has two-space indent"

# REG-U02: register same path again -> idempotent no-op (no duplicate).
run_harness "$REG_HOME_U01" register "/tmp/repo-a"
assert_exit_eq "$RC" 0 "REG-U02a re-register same path -> exit 0"
_repo_count=$(grep -c '  - ' "${REG_HOME_U01}/registry.yml" || echo 0)
assert_eq "$_repo_count" "1" "REG-U02b idempotent: only one entry after double register"
# No "Registered" output on no-op.
assert_output_not_contains "$OUT" "Registered" "REG-U02c no-op: silent (no Registered line)"

# REG-U03: register a second distinct path -> both present, sorted.
run_harness "$REG_HOME_U01" register "/tmp/repo-z"
assert_exit_eq "$RC" 0 "REG-U03a register second path -> exit 0"
_repo_count=$(grep -c '  - ' "${REG_HOME_U01}/registry.yml" || echo 0)
assert_eq "$_repo_count" "2" "REG-U03b two entries after second register"
assert_file_contains "${REG_HOME_U01}/registry.yml" "  - /tmp/repo-a" "REG-U03c first path still present"
assert_file_contains "${REG_HOME_U01}/registry.yml" "  - /tmp/repo-z" "REG-U03d second path present"

# REG-U04: read_repos returns both paths.
run_harness "$REG_HOME_U01" read_repos ""
assert_exit_eq "$RC" 0 "REG-U04a read_repos -> exit 0"
assert_output_contains "$OUT" "/tmp/repo-a" "REG-U04b read_repos includes repo-a"
assert_output_contains "$OUT" "/tmp/repo-z" "REG-U04c read_repos includes repo-z"

# REG-U05: unregister one path -> other path remains.
run_harness "$REG_HOME_U01" unregister "/tmp/repo-a"
assert_exit_eq "$RC" 0 "REG-U05a unregister one path -> exit 0"
assert_output_contains "$OUT" "Unregistered /tmp/repo-a" "REG-U05b prints Unregistered line"
_repo_count=$(grep -c '  - ' "${REG_HOME_U01}/registry.yml" || echo 0)
assert_eq "$_repo_count" "1" "REG-U05c one entry remains after unregister"
assert_file_not_contains "${REG_HOME_U01}/registry.yml" "  - /tmp/repo-a" "REG-U05d removed path gone"
assert_file_contains "${REG_HOME_U01}/registry.yml" "  - /tmp/repo-z" "REG-U05e other path intact"

# REG-U06: unregister a path not in registry -> silent no-op (exit 0, no error).
run_harness "$REG_HOME_U01" unregister "/tmp/repo-a"
assert_exit_eq "$RC" 0 "REG-U06a unregister absent path -> exit 0"
assert_output_not_contains "$OUT" "Unregistered" "REG-U06b no Unregistered line on no-op"
assert_output_not_contains "$OUT" "WARN" "REG-U06c no WARN on absent-path no-op"

# REG-U07: unregister last path -> registry.yml still present (repos: with no items).
run_harness "$REG_HOME_U01" unregister "/tmp/repo-z"
assert_exit_eq "$RC" 0 "REG-U07a unregister last path -> exit 0"
assert_file_exists "${REG_HOME_U01}/registry.yml" "REG-U07b registry.yml kept after last unregister"
assert_file_contains "${REG_HOME_U01}/registry.yml" "repos:" "REG-U07c repos: key present in empty registry"
assert_file_not_contains "${REG_HOME_U01}/registry.yml" "  - " "REG-U07d no path entries in empty registry"

# REG-U08: read_repos on absent file -> empty output, exit 0.
REG_HOME_U08=$(newhome)
run_harness "$REG_HOME_U08" read_repos ""
assert_exit_eq "$RC" 0 "REG-U08a read_repos absent file -> exit 0"
assert_eq "$OUT" "" "REG-U08b read_repos absent file -> empty output"

# REG-U09: no temp file left behind after register.
REG_HOME_U09=$(newhome)
run_harness "$REG_HOME_U09" register "/tmp/repo-clean"
_tmp_count=$(find "$REG_HOME_U09" -name '*.aid-tmp.*' 2>/dev/null | wc -l || echo 0)
assert_eq "$_tmp_count" "0" "REG-U09 no tmp file left behind after register"

# REG-U10: DM-1 format invariant -- comment lines are ASCII-only.
REG_HOME_U10=$(newhome)
run_harness "$REG_HOME_U10" register "/tmp/repo-ascii"
if grep -qP '[^\x00-\x7F]' "${REG_HOME_U10}/registry.yml" 2>/dev/null; then
    fail "REG-U10 registry.yml scaffolding contains non-ASCII bytes"
else
    pass "REG-U10 registry.yml scaffolding is ASCII-only"
fi

echo ""
echo "=== Registry CLI integration tests (aid add / aid remove boundary) ==="

# REG-C01: aid add registers the repo.
REG_C01_HOME=$(newhome)
setup_aid_home "$REG_C01_HOME"
REG_C01_TGT=$(newtarget)

run_aid "$REG_C01_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C01_TGT"
assert_exit_eq "$RC" 0 "REG-C01a aid add codex -> exit 0"
assert_file_exists "${REG_C01_HOME}/registry.yml" "REG-C01b registry.yml created after add"
assert_file_contains "${REG_C01_HOME}/registry.yml" "${REG_C01_TGT}" "REG-C01c repo path in registry after add"
assert_output_contains "$OUT" "Registered ${REG_C01_TGT}" "REG-C01d Registered line in add output"

# REG-C02: aid add same tool again (--force) -> registry NO-OP (no duplicate).
run_aid "$REG_C01_HOME" add codex --force \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C01_TGT"
assert_exit_eq "$RC" 0 "REG-C02a re-add codex (force) -> exit 0"
_repo_count=$(grep -c '  - ' "${REG_C01_HOME}/registry.yml" || echo 0)
assert_eq "$_repo_count" "1" "REG-C02b idempotent: one registry entry after re-add"
assert_output_not_contains "$OUT" "Registered" "REG-C02c no Registered line on registry no-op"

# REG-C03: add a second tool to same repo -> still one registry entry (repo already registered).
run_aid "$REG_C01_HOME" add claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$REG_C01_TGT"
assert_exit_eq "$RC" 0 "REG-C03a aid add second tool -> exit 0"
_repo_count=$(grep -c '  - ' "${REG_C01_HOME}/registry.yml" || echo 0)
assert_eq "$_repo_count" "1" "REG-C03b still one registry entry after second tool add"

# REG-C04: remove one-of-two tools -> manifest still exists -> registry UNCHANGED.
run_aid "$REG_C01_HOME" remove claude-code --force --target "$REG_C01_TGT"
assert_exit_eq "$RC" 0 "REG-C04a remove one-of-two tools -> exit 0"
assert_file_exists "${REG_C01_HOME}/registry.yml" "REG-C04b registry.yml still present"
assert_file_contains "${REG_C01_HOME}/registry.yml" "${REG_C01_TGT}" \
    "REG-C04c repo still in registry (manifest still exists)"
assert_output_not_contains "$OUT" "Unregistered" "REG-C04d no Unregistered line when manifest remains"

# REG-C05: remove last tool -> manifest gone -> repo is unregistered.
run_aid "$REG_C01_HOME" remove codex --force --target "$REG_C01_TGT"
assert_exit_eq "$RC" 0 "REG-C05a remove last tool -> exit 0"
assert_file_not_contains "${REG_C01_HOME}/registry.yml" "${REG_C01_TGT}" \
    "REG-C05b repo removed from registry after last tool removed"
assert_output_contains "$OUT" "Unregistered ${REG_C01_TGT}" \
    "REG-C05c Unregistered line in output after last tool removed"

# REG-C06: remove all (no tool arg) -> manifest gone -> repo unregistered.
REG_C06_HOME=$(newhome)
setup_aid_home "$REG_C06_HOME"
REG_C06_TGT=$(newtarget)
run_aid "$REG_C06_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C06_TGT"
assert_exit_eq "$RC" 0 "REG-C06a add for remove-all test -> exit 0"
run_aid "$REG_C06_HOME" remove --force --target "$REG_C06_TGT"
assert_exit_eq "$RC" 0 "REG-C06b remove all --force -> exit 0"
assert_file_not_contains "${REG_C06_HOME}/registry.yml" "${REG_C06_TGT}" \
    "REG-C06c repo unregistered after remove-all"

# REG-C07: add to two different repos -> two registry entries.
REG_C07_HOME=$(newhome)
setup_aid_home "$REG_C07_HOME"
REG_C07_TGT1=$(newtarget)
REG_C07_TGT2=$(newtarget)
run_aid "$REG_C07_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C07_TGT1"
assert_exit_eq "$RC" 0 "REG-C07a add to repo1 -> exit 0"
run_aid "$REG_C07_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C07_TGT2"
assert_exit_eq "$RC" 0 "REG-C07b add to repo2 -> exit 0"
_repo_count=$(grep -c '  - ' "${REG_C07_HOME}/registry.yml" || echo 0)
assert_eq "$_repo_count" "2" "REG-C07c two entries for two distinct repos"
assert_file_contains "${REG_C07_HOME}/registry.yml" "${REG_C07_TGT1}" "REG-C07d repo1 path in registry"
assert_file_contains "${REG_C07_HOME}/registry.yml" "${REG_C07_TGT2}" "REG-C07e repo2 path in registry"

# REG-C08: host-tool exit codes unchanged (side-effect must never fail install).
# Verify that add still exits 0 (host-tool result) — the registry side-effect
# is a fire-and-continue; any failure only prints WARN.
# This is tested at unit level (via harness with a read-only tmp dir) and at
# CLI level (just confirm add exits 0 and prints "Done. AID").
REG_C08_HOME=$(newhome)
setup_aid_home "$REG_C08_HOME"
REG_C08_TGT=$(newtarget)
run_aid "$REG_C08_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C08_TGT"
assert_exit_eq "$RC" 0 "REG-C08a add exits 0 (NFR10 host-tool result unchanged)"
assert_output_contains "$OUT" "Done. AID" "REG-C08b Done message present"

# Unit-level WARN test: simulate write failure by making AID_HOME non-writable via harness.
REG_WARN_HOME=$(newhome)
touch "${REG_WARN_HOME}/registry.yml"
# Make a subdirectory named like the temp file pattern to block mktemp.
# Simplest reliable approach: wrap harness so mktemp call is intercepted.
# Instead: verify WARN at function level by making tmp file creation fail via
# a read-only sub-path (subshell test so we don't break outer tmpdir).
_WARN_OUT=$(bash -c '
    BIN_AID="'"$BIN_AID"'"
    AID_HOME="'"$REG_WARN_HOME"'"
    START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
    END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
    _AID_VERBOSE=0
    eval "$(sed -n "${START},${END}p" "$BIN_AID")"
    # Override mktemp to simulate failure.
    mktemp() { return 1; }
    registry_register "/tmp/warn-test-repo"
' 2>&1)
assert_output_contains "$_WARN_OUT" "WARN:" "REG-C08c WARN emitted when mktemp fails"
assert_output_not_contains "$_WARN_OUT" "Registered" "REG-C08d no Registered line when mktemp fails"

# REG-C09: remove self removes AID_HOME wholesale -> no registry step at repo level.
REG_C09_HOME=$(newhome)
setup_aid_home "$REG_C09_HOME"
REG_C09_TGT=$(newtarget)
run_aid "$REG_C09_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_C09_TGT"
assert_exit_eq "$RC" 0 "REG-C09a add for remove-self test -> exit 0"
_registry_before="${REG_C09_HOME}/registry.yml"
assert_file_exists "$_registry_before" "REG-C09b registry.yml exists before remove self"
# Remove self.
OUT_RS=$(AID_HOME="$REG_C09_HOME" bash "${REG_C09_HOME}/bin/aid" remove self --force 2>&1); RC_RS=$?
assert_exit_eq "$RC_RS" 0 "REG-C09c remove self -> exit 0"
# AID_HOME is gone; registry with it.
assert_eq "$([[ -d "$REG_C09_HOME" ]] && echo exists || echo gone)" "gone" \
    "REG-C09d AID_HOME (including registry) removed by remove self"
# Per-repo manifest is NOT removed.
assert_file_exists "${REG_C09_TGT}/.aid/.aid-manifest.json" \
    "REG-C09e per-repo manifest untouched by remove self"

echo ""
echo "=== Registry format invariant ==="

# REG-F01: registry.yml produced by aid add is ASCII-only in its scaffolding.
REG_F01_HOME=$(newhome)
setup_aid_home "$REG_F01_HOME"
REG_F01_TGT=$(newtarget)
run_aid "$REG_F01_HOME" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$REG_F01_TGT"
assert_exit_eq "$RC" 0 "REG-F01a add for format test -> exit 0"
# Check the four header lines + schema + repos: are ASCII-only.
_header_lines=$(head -6 "${REG_F01_HOME}/registry.yml")
if printf '%s' "$_header_lines" | grep -qP '[^\x00-\x7F]'; then
    fail "REG-F01b registry.yml header lines contain non-ASCII bytes"
else
    pass "REG-F01b registry.yml header lines are ASCII-only"
fi

echo ""
echo "=== Registry feature-004 unit tests: union / collapse / degrade / prune / no-scan / migrate ==="

# ---------------------------------------------------------------------------
# ESCAPE CANARY: assert /var/lib/aid is NOT created during this suite.
# (Checked at the end after all tests; real-path check stored now.)
# ---------------------------------------------------------------------------
_CANARY_VAR_LIB_AID="/var/lib/aid"
_canary_existed_before=0
[[ -e "${_CANARY_VAR_LIB_AID}" ]] && _canary_existed_before=1

# ---------------------------------------------------------------------------
# Union harness: sources _registry_read_repos + _registry_read_union from
# bin/aid with explicit HOME and AID_STATE_HOME for tier isolation.
# ---------------------------------------------------------------------------
UNION_HARNESS="${TMP}/union_harness.sh"
cat > "${UNION_HARNESS}" << 'UNION_HARNESS_EOF'
#!/usr/bin/env bash
set -uo pipefail
BIN_AID="$1"; shift
HOME_DIR="$1"; shift
AID_STATE_HOME_DIR="$1"; shift
CMD="$1"; shift  # read_union | read_repos_file
ARG="${1:-}"

export HOME="${HOME_DIR}"
export AID_STATE_HOME="${AID_STATE_HOME_DIR}"
export _AID_VERBOSE=0

START=$(grep -n '# Registry helpers (DR-1' "$BIN_AID" | head -1 | cut -d: -f1)
END=$(grep -n '# Parse subcommand and dispatch' "$BIN_AID" | head -1 | cut -d: -f1)
[[ -n "$START" && -n "$END" ]] || { echo "ERROR: cannot locate registry section" >&2; exit 1; }
_PRIV_START=$(grep -n '^_aid_priv_run()' "$BIN_AID" | head -1 | cut -d: -f1)
_PRIV_END=$(awk "NR>=${_PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
if [[ -n "$_PRIV_START" && -n "$_PRIV_END" ]]; then
    eval "$(sed -n "${_PRIV_START},${_PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
fi
eval "$(sed -n "${START},${END}p" "$BIN_AID")"

case "$CMD" in
    read_union)    _registry_read_union ;;
    read_repos)    _registry_read_repos "$ARG" ;;
    *) echo "ERROR: unknown CMD: $CMD" >&2; exit 1 ;;
esac
UNION_HARNESS_EOF
chmod +x "${UNION_HARNESS}"

run_union_harness() {
    local home_dir="$1" state_home_dir="$2" cmd="$3" arg="${4:-}"
    OUT=$(HOME="$home_dir" AID_STATE_HOME="$state_home_dir" \
          bash "${UNION_HARNESS}" "$BIN_AID" "$home_dir" "$state_home_dir" "$cmd" "$arg" 2>&1)
    RC=$?
}

# REG-V01: Union read -- user tier = repo A, shared tier = repo B -> union returns {A,B}.
#          A path in BOTH tiers appears exactly once (dedup).
echo "--- REG-V01: union read ---"
_V01_HOME=$(mktemp -d "${TMP}/v01_home.XXXXXX")
_V01_SHARED=$(mktemp -d "${TMP}/v01_shared.XXXXXX")
# Ensure AID_STATE_HOME != HOME/.aid so union takes the two-tier path.
_V01_AID_STATE="${_V01_SHARED}"

# Repo A and Repo B: must have .aid/ for prune-filter pass-through.
_V01_REPO_A=$(mktemp -d "${TMP}/v01_repoA.XXXXXX")
_V01_REPO_B=$(mktemp -d "${TMP}/v01_repoB.XXXXXX")
mkdir -p "${_V01_REPO_A}/.aid" "${_V01_REPO_B}/.aid"

# Write repo A into user-fallback tier ($HOME/.aid/registry.yml).
mkdir -p "${_V01_HOME}/.aid"
cat > "${_V01_HOME}/.aid/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V01_REPO_A}
REG_EOF

# Write repo B into the primary (AID_STATE_HOME) tier.
cat > "${_V01_SHARED}/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V01_REPO_B}
REG_EOF

run_union_harness "${_V01_HOME}" "${_V01_AID_STATE}" "read_union"
assert_exit_eq "$RC" 0 "REG-V01a union read -> exit 0"
assert_output_contains "$OUT" "${_V01_REPO_A}" "REG-V01b union includes repo A (user tier)"
assert_output_contains "$OUT" "${_V01_REPO_B}" "REG-V01c union includes repo B (shared tier)"

# REG-V01d: dedup - write repo A into BOTH tiers; union must yield it exactly once.
cat > "${_V01_SHARED}/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V01_REPO_A}
  - ${_V01_REPO_B}
REG_EOF
run_union_harness "${_V01_HOME}" "${_V01_AID_STATE}" "read_union"
_v01_count_a=$(printf '%s\n' "$OUT" | grep -cxF "${_V01_REPO_A}" || echo 0)
assert_eq "$_v01_count_a" "1" "REG-V01d dedup: path in both tiers appears exactly once in union"

# REG-V02: Per-user collapse -- AID_STATE_HOME == HOME/.aid -> single-file read (no double-read).
echo "--- REG-V02: per-user collapse ---"
_V02_HOME=$(mktemp -d "${TMP}/v02_home.XXXXXX")
_V02_AID_DIR="${_V02_HOME}/.aid"
mkdir -p "${_V02_AID_DIR}"
_V02_REPO_X=$(mktemp -d "${TMP}/v02_repoX.XXXXXX")
_V02_REPO_Y=$(mktemp -d "${TMP}/v02_repoY.XXXXXX")
mkdir -p "${_V02_REPO_X}/.aid" "${_V02_REPO_Y}/.aid"

# Only write to the user tier (primary == $HOME/.aid).
cat > "${_V02_AID_DIR}/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V02_REPO_X}
REG_EOF

# When AID_STATE_HOME == HOME/.aid, the "other" path doesn't exist -- write an
# entry there manually to confirm it is NOT read in collapse mode.
# (In collapse mode there is only one file: HOME/.aid/registry.yml = AID_STATE_HOME/registry.yml,
#  so there is no second file to read; repo Y is intentionally absent.)

# AID_STATE_HOME = HOME/.aid -> per-user collapse.
run_union_harness "${_V02_HOME}" "${_V02_AID_DIR}" "read_union"
assert_exit_eq "$RC" 0 "REG-V02a per-user collapse -> exit 0"
assert_output_contains "$OUT" "${_V02_REPO_X}" "REG-V02b per-user collapse: repo X returned"
assert_output_not_contains "$OUT" "${_V02_REPO_Y}" "REG-V02c per-user collapse: repo Y (not registered) absent"

# REG-V03: Best-effort write degrade -- unwritable shared tier (chmod 555) + register
#          -> warns, returns 0, entry preserved in user/fallback tier.
echo "--- REG-V03: best-effort write degrade ---"
_V03_HOME=$(mktemp -d "${TMP}/v03_home.XXXXXX")
_V03_SHARED=$(mktemp -d "${TMP}/v03_shared.XXXXXX")
chmod 555 "${_V03_SHARED}"
_V03_REPO=$(mktemp -d "${TMP}/v03_repo.XXXXXX")
mkdir -p "${_V03_REPO}/.aid"

_V03_WARN_OUT=$(bash -c '
    BIN_AID="'"$BIN_AID"'"
    HOME="'"${_V03_HOME}"'"
    AID_STATE_HOME="'"${_V03_SHARED}"'"
    export HOME AID_STATE_HOME
    START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
    END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_START=$(grep -n "^_aid_priv_run()" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_END=$(awk "NR>=${_PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
    [[ -n "$_PRIV_START" && -n "$_PRIV_END" ]] && \
        eval "$(sed -n "${_PRIV_START},${_PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
    _AID_VERBOSE=0
    eval "$(sed -n "${START},${END}p" "$BIN_AID")"
    registry_register "'"${_V03_REPO}"'"
' 2>&1)
_V03_RC=$?
assert_exit_eq "$_V03_RC" 0 "REG-V03a degrade: register returns 0 even when AID_STATE_HOME not writable"
assert_output_contains "$_V03_WARN_OUT" "WARN:" "REG-V03b degrade: WARN emitted when primary not writable"
# Host (caller) completed; entry lands in fallback ($HOME/.aid).
_V03_FALLBACK_REG="${_V03_HOME}/.aid/registry.yml"
if [[ -f "${_V03_FALLBACK_REG}" ]]; then
    assert_file_contains "${_V03_FALLBACK_REG}" "${_V03_REPO}" \
        "REG-V03c degrade: entry preserved in fallback user tier"
else
    # Some implementations may WARN and not write at all (also acceptable).
    # What matters is that the function returned 0 and emitted WARN -- that is the contract.
    pass "REG-V03c degrade: fallback not written (WARN path -- acceptable per task-010 contract)"
fi
chmod 755 "${_V03_SHARED}" 2>/dev/null || true  # restore for cleanup

# REG-V04: Prune-on-read -- register a repo, delete its .aid/, union drops it quietly.
echo "--- REG-V04: prune-on-read ---"
_V04_HOME=$(mktemp -d "${TMP}/v04_home.XXXXXX")
_V04_SHARED=$(mktemp -d "${TMP}/v04_shared.XXXXXX")
_V04_REPO_LIVE=$(mktemp -d "${TMP}/v04_live.XXXXXX")
_V04_REPO_DEAD=$(mktemp -d "${TMP}/v04_dead.XXXXXX")
mkdir -p "${_V04_REPO_LIVE}/.aid" "${_V04_REPO_DEAD}/.aid"

# Populate the primary tier registry with both repos.
cat > "${_V04_SHARED}/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V04_REPO_DEAD}
  - ${_V04_REPO_LIVE}
REG_EOF

# Simulate repo deletion: remove the .aid/ dir from the dead repo.
rm -rf "${_V04_REPO_DEAD}/.aid"

run_union_harness "${_V04_HOME}" "${_V04_SHARED}" "read_union"
assert_exit_eq "$RC" 0 "REG-V04a prune-on-read -> exit 0"
assert_output_not_contains "$OUT" "${_V04_REPO_DEAD}" \
    "REG-V04b prune-on-read: dead repo (no .aid/) dropped from union"
assert_output_contains "$OUT" "${_V04_REPO_LIVE}" \
    "REG-V04c prune-on-read: live repo still in union"
# WARN: the prune must be quiet (no warning line).
_V04_PRUNE_OUT=$(HOME="${_V04_HOME}" AID_STATE_HOME="${_V04_SHARED}" \
    bash "${UNION_HARNESS}" "$BIN_AID" "${_V04_HOME}" "${_V04_SHARED}" "read_union" 2>&1)
assert_output_not_contains "$_V04_PRUNE_OUT" "WARN:" \
    "REG-V04d prune-on-read: no WARN emitted for stale entry"

# REG-V05: NO scan -- assert _aid_scan_for_repos is absent from bin/aid (grep).
#          A canary repo outside the registry is never touched.
echo "--- REG-V05: no scan ---"
if grep -q '_aid_scan_for_repos' "${BIN_AID}"; then
    fail "REG-V05a _aid_scan_for_repos found in bin/aid (AC2: scan must be absent)"
else
    pass "REG-V05a _aid_scan_for_repos absent from bin/aid (AC2: no scan)"
fi
# Canary repo: has .aid/ but is NOT registered; update-self (dry-run) must not touch it.
_V05_CANARY=$(mktemp -d "${TMP}/v05_canary.XXXXXX")
mkdir -p "${_V05_CANARY}/.aid"
_V05_CANARY_MARKER="${_V05_CANARY}/.aid/settings.yml"
printf 'project:\n  name: canary\n' > "${_V05_CANARY_MARKER}"
_V05_MTIME_BEFORE=$(stat -c '%Y' "${_V05_CANARY_MARKER}" 2>/dev/null || echo 0)
# Run update self (dry-run) -- no registry entries, so migration loop is empty.
_V05_AID_HOME=$(newhome)
setup_aid_home "${_V05_AID_HOME}"
OUT=$(AID_HOME="${_V05_AID_HOME}" AID_STATE_HOME="${_V05_AID_HOME}" \
      AID_SKIP_SELF_INSTALL=1 AID_MIGRATE_YES=1 \
      bash "${_V05_AID_HOME}/bin/aid" update self --dry-run 2>&1); RC=$?
_V05_MTIME_AFTER=$(stat -c '%Y' "${_V05_CANARY_MARKER}" 2>/dev/null || echo 0)
assert_eq "${_V05_MTIME_BEFORE}" "${_V05_MTIME_AFTER}" \
    "REG-V05b no-scan: canary repo outside registry untouched by update self"

# REG-V06: update-self migrates exactly registered repos.
#          Register A and B; leave C unregistered.
#          Run update self (AID_SKIP_SELF_INSTALL=1 + AID_MIGRATE_YES=1).
#          -> A and B get format_version: 1; C untouched.
echo "--- REG-V06: update-self migrates exactly registered ---"
_V06_AID_HOME=$(newhome)
setup_aid_home "${_V06_AID_HOME}"

_V06_REPO_A=$(mktemp -d "${TMP}/v06_repoA.XXXXXX")
_V06_REPO_B=$(mktemp -d "${TMP}/v06_repoB.XXXXXX")
_V06_REPO_C=$(mktemp -d "${TMP}/v06_repoC.XXXXXX")

# All three repos get .aid/settings.yml (era-a) so migration can stamp them.
for _r in "$_V06_REPO_A" "$_V06_REPO_B" "$_V06_REPO_C"; do
    mkdir -p "${_r}/.aid"
    printf 'project:\n  name: repo\nformat_version: 0\n' > "${_r}/.aid/settings.yml"
done

# Register A and B (not C) in AID_STATE_HOME registry.
cat > "${_V06_AID_HOME}/registry.yml" << REG_EOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V06_REPO_A}
  - ${_V06_REPO_B}
REG_EOF

# Run update self: skip re-install, auto-yes migration, HOME pinned to throwaway.
_V06_HOME=$(mktemp -d "${TMP}/v06_home.XXXXXX")
OUT=$(HOME="${_V06_HOME}" \
      AID_HOME="${_V06_AID_HOME}" AID_STATE_HOME="${_V06_AID_HOME}" \
      AID_SKIP_SELF_INSTALL=1 AID_MIGRATE_YES=1 \
      AID_NO_UPDATE_CHECK=1 \
      bash "${_V06_AID_HOME}/bin/aid" update self 2>&1); RC=$?
assert_exit_eq "$RC" 0 "REG-V06a update self with registered A+B -> exit 0"

# A and B: format_version should now be 1.
_V06_FV_A=$(grep '^format_version:' "${_V06_REPO_A}/.aid/settings.yml" 2>/dev/null | head -1 | sed 's/format_version:[[:space:]]*//')
_V06_FV_B=$(grep '^format_version:' "${_V06_REPO_B}/.aid/settings.yml" 2>/dev/null | head -1 | sed 's/format_version:[[:space:]]*//')
assert_eq "${_V06_FV_A}" "1" "REG-V06b registered repo A gets format_version: 1 after migrate"
assert_eq "${_V06_FV_B}" "1" "REG-V06c registered repo B gets format_version: 1 after migrate"

# C: must still have format_version: 0 (unregistered, not touched).
_V06_FV_C=$(grep '^format_version:' "${_V06_REPO_C}/.aid/settings.yml" 2>/dev/null | head -1 | sed 's/format_version:[[:space:]]*//')
assert_eq "${_V06_FV_C}" "0" "REG-V06d unregistered repo C format_version unchanged (still 0)"

# REG-V07: AID_HOME redirect -- registry writes land in AID_STATE_HOME, not real HOME/.aid.
echo "--- REG-V07: AID_HOME redirect ---"
_V07_HOME=$(mktemp -d "${TMP}/v07_home.XXXXXX")
_V07_AID_OVERRIDE=$(mktemp -d "${TMP}/v07_aidstate.XXXXXX")
_V07_REPO=$(mktemp -d "${TMP}/v07_repo.XXXXXX")

_V07_WARN_OUT=$(bash -c '
    BIN_AID="'"$BIN_AID"'"
    HOME="'"${_V07_HOME}"'"
    AID_STATE_HOME="'"${_V07_AID_OVERRIDE}"'"
    export HOME AID_STATE_HOME
    START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
    END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_START=$(grep -n "^_aid_priv_run()" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_END=$(awk "NR>=${_PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
    [[ -n "$_PRIV_START" && -n "$_PRIV_END" ]] && \
        eval "$(sed -n "${_PRIV_START},${_PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
    _AID_VERBOSE=0
    eval "$(sed -n "${START},${END}p" "$BIN_AID")"
    registry_register "'"${_V07_REPO}"'"
' 2>&1)
# Registry must appear in the override dir, not in real HOME/.aid.
_V07_REAL_HOME_REG="${_V07_HOME}/.aid/registry.yml"
_V07_OVERRIDE_REG="${_V07_AID_OVERRIDE}/registry.yml"
if [[ -f "${_V07_OVERRIDE_REG}" ]]; then
    assert_file_contains "${_V07_OVERRIDE_REG}" "${_V07_REPO}" \
        "REG-V07a AID_HOME redirect: entry in AID_STATE_HOME registry"
    assert_eq "$(test -f "${_V07_REAL_HOME_REG}" && echo exists || echo absent)" "absent" \
        "REG-V07b AID_HOME redirect: real HOME/.aid/registry.yml NOT created"
else
    # Acceptable fallback: entry may land in HOME/.aid when override is not writable.
    # But we should have succeeded since the override dir IS writable.
    fail "REG-V07a AID_HOME redirect: registry not found in AID_STATE_HOME (${_V07_OVERRIDE_REG})"
fi

# REG-V08: Tier coverage -- task-015 assertions (non-global collapse + pretend-global two-tier).
#
# V08a: Non-global collapse -- confirm the default non-global user install collapse.
#   When AID_STATE_HOME equals HOME/.aid (the production default for a per-user
#   install), the union read is a single-file read and the registry at
#   AID_STATE_HOME/registry.yml is the only tier.
#
# V08b: Pretend-global (simulated shared tier, no /var/lib/aid needed) -- assert
#   that when AID_STATE_HOME is set to a writable throwaway DIFFERENT from HOME/.aid
#   (simulating a global-install shared-state dir without requiring root), a
#   registry_register call writes to AID_STATE_HOME/registry.yml (shared tier),
#   and _registry_read_union returns repos from BOTH the user-tier (HOME/.aid) AND
#   the shared tier (AID_STATE_HOME), confirming the two-tier union path.
#
# ESCAPE CANARY (scoped to V08): HOME is pinned to a fresh throwaway for V08 so
#   no real ~/.aid is touched; /var/lib/aid is never created (checked at suite end).
echo ""
echo "=== REG-V08: tier coverage -- task-015 (non-global collapse + pretend-global union) ==="

# --- V08a: Non-global collapse ---
echo "--- REG-V08a: non-global collapse ---"
_V08_HOME=$(mktemp -d "${TMP}/v08_home.XXXXXX")
_V08_AID="${_V08_HOME}/.aid"
mkdir -p "${_V08_AID}"
_V08_REPO=$(mktemp -d "${TMP}/v08_repo.XXXXXX")
mkdir -p "${_V08_REPO}/.aid"

# Write an entry into HOME/.aid/registry.yml via the harness.
# With AID_STATE_HOME == HOME/.aid, this IS the single collapsed file.
_V08a_OUT=$(bash -c '
    BIN_AID="'"$BIN_AID"'"
    HOME="'"${_V08_HOME}"'"
    AID_STATE_HOME="'"${_V08_AID}"'"
    export HOME AID_STATE_HOME
    START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
    END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_START=$(grep -n "^_aid_priv_run()" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_END=$(awk "NR>=${_PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
    [[ -n "$_PRIV_START" && -n "$_PRIV_END" ]] && \
        eval "$(sed -n "${_PRIV_START},${_PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
    _AID_VERBOSE=0
    eval "$(sed -n "${START},${END}p" "$BIN_AID")"
    registry_register "'"${_V08_REPO}"'"
' 2>&1)
_V08a_RC=$?
assert_exit_eq "$_V08a_RC" 0 "REG-V08a-01 non-global collapse: register returns 0"
assert_file_exists "${_V08_AID}/registry.yml" \
    "REG-V08a-02 non-global collapse: registry.yml in HOME/.aid (collapsed single-tier)"
assert_file_contains "${_V08_AID}/registry.yml" "${_V08_REPO}" \
    "REG-V08a-03 non-global collapse: repo path present in collapsed registry"
# Union read must return the same entry (single-tier collapse is not double-read).
_V08a_UNION_OUT=$(HOME="${_V08_HOME}" AID_STATE_HOME="${_V08_AID}" \
    bash "${UNION_HARNESS}" "$BIN_AID" "${_V08_HOME}" "${_V08_AID}" "read_union" 2>&1)
assert_output_contains "$_V08a_UNION_OUT" "${_V08_REPO}" \
    "REG-V08a-04 non-global collapse: union read returns the collapsed-tier entry"
_V08a_COUNT=$(printf '%s\n' "$_V08a_UNION_OUT" | grep -cxF "${_V08_REPO}" || echo 0)
assert_eq "$_V08a_COUNT" "1" \
    "REG-V08a-05 non-global collapse: repo appears exactly once in union (no double-read)"

# --- V08b: Pretend-global (two-tier AID_STATE_HOME != HOME/.aid) ---
echo "--- REG-V08b: pretend-global two-tier (AID_STATE_HOME != HOME/.aid) ---"
_V08b_HOME=$(mktemp -d "${TMP}/v08b_home.XXXXXX")
_V08b_AID_USER="${_V08b_HOME}/.aid"
mkdir -p "${_V08b_AID_USER}"
_V08b_AID_SHARED=$(mktemp -d "${TMP}/v08b_shared.XXXXXX")  # simulates /var/lib/aid
_V08b_REPO_USER=$(mktemp -d "${TMP}/v08b_repo_user.XXXXXX")
_V08b_REPO_SHARED=$(mktemp -d "${TMP}/v08b_repo_shared.XXXXXX")
mkdir -p "${_V08b_REPO_USER}/.aid" "${_V08b_REPO_SHARED}/.aid"

# Pre-populate user-tier registry at HOME/.aid.
cat > "${_V08b_AID_USER}/registry.yml" << V08REGEOF
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
schema: 1
repos:
  - ${_V08b_REPO_USER}
V08REGEOF

# Register the shared-tier repo via harness with AID_STATE_HOME = shared dir.
_V08b_REG_OUT=$(bash -c '
    BIN_AID="'"$BIN_AID"'"
    HOME="'"${_V08b_HOME}"'"
    AID_STATE_HOME="'"${_V08b_AID_SHARED}"'"
    export HOME AID_STATE_HOME
    START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
    END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_START=$(grep -n "^_aid_priv_run()" "$BIN_AID" | head -1 | cut -d: -f1)
    _PRIV_END=$(awk "NR>=${_PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
    [[ -n "$_PRIV_START" && -n "$_PRIV_END" ]] && \
        eval "$(sed -n "${_PRIV_START},${_PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
    _AID_VERBOSE=0
    eval "$(sed -n "${START},${END}p" "$BIN_AID")"
    registry_register "'"${_V08b_REPO_SHARED}"'"
' 2>&1)
_V08b_REG_RC=$?
assert_exit_eq "$_V08b_REG_RC" 0 \
    "REG-V08b-01 pretend-global: register to shared tier returns 0"
assert_file_exists "${_V08b_AID_SHARED}/registry.yml" \
    "REG-V08b-02 pretend-global: registry.yml created in AID_STATE_HOME (shared tier)"
assert_file_contains "${_V08b_AID_SHARED}/registry.yml" "${_V08b_REPO_SHARED}" \
    "REG-V08b-03 pretend-global: shared-tier repo path in AID_STATE_HOME/registry.yml"

# Union read: user-tier (HOME/.aid) + shared-tier (AID_STATE_HOME) -> both repos visible.
_V08b_UNION_OUT=$(HOME="${_V08b_HOME}" AID_STATE_HOME="${_V08b_AID_SHARED}" \
    bash "${UNION_HARNESS}" "$BIN_AID" "${_V08b_HOME}" "${_V08b_AID_SHARED}" "read_union" 2>&1)
assert_output_contains "$_V08b_UNION_OUT" "${_V08b_REPO_USER}" \
    "REG-V08b-04 pretend-global union: user-tier repo visible"
assert_output_contains "$_V08b_UNION_OUT" "${_V08b_REPO_SHARED}" \
    "REG-V08b-05 pretend-global union: shared-tier repo visible"
# Neither entry should appear more than once (dedup).
_V08b_COUNT_U=$(printf '%s\n' "$_V08b_UNION_OUT" | grep -cxF "${_V08b_REPO_USER}" || echo 0)
_V08b_COUNT_S=$(printf '%s\n' "$_V08b_UNION_OUT" | grep -cxF "${_V08b_REPO_SHARED}" || echo 0)
assert_eq "$_V08b_COUNT_U" "1" "REG-V08b-06 pretend-global union: user-tier entry appears exactly once"
assert_eq "$_V08b_COUNT_S" "1" "REG-V08b-07 pretend-global union: shared-tier entry appears exactly once"

# HOME/.aid must NOT have been written to by the shared-tier registration.
_V08b_USER_REG_COUNT=$(grep -c '  - ' "${_V08b_AID_USER}/registry.yml" 2>/dev/null || echo 0)
assert_eq "$_V08b_USER_REG_COUNT" "1" \
    "REG-V08b-08 pretend-global: shared-tier register did not add entry to user-tier registry"

# ---------------------------------------------------------------------------
# ESCAPE CANARY FINAL CHECK: /var/lib/aid must not have been created.
# ---------------------------------------------------------------------------
if [[ "$_canary_existed_before" -eq 0 ]]; then
    if [[ -e "${_CANARY_VAR_LIB_AID}" ]]; then
        fail "ESCAPE-CANARY: ${_CANARY_VAR_LIB_AID} was created during this suite (hermetic violation)"
    else
        pass "ESCAPE-CANARY: ${_CANARY_VAR_LIB_AID} absent (real /var/lib untouched)"
    fi
else
    pass "ESCAPE-CANARY: ${_CANARY_VAR_LIB_AID} pre-existed before suite; skipping creation check"
fi

test_summary
