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
set -uo pipefail
BIN_AID="$1"; shift
AID_HOME="$1"; shift
CMD="$1"; shift  # register | unregister | read_repos
ARG="${1:-}"

# Source just the helper section by detecting line range.
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
    read_repos) _registry_read_repos "${AID_HOME}/registry.yml" ;;
    *) echo "ERROR: unknown CMD: $CMD" >&2; exit 1 ;;
esac
HARNESS_EOF
chmod +x "${HARNESS_SCRIPT}"

run_harness() {
    local aid_home="$1" cmd="$2" arg="${3:-}"
    OUT=$(AID_HOME="$aid_home" _AID_VERBOSE="${_AID_VERBOSE:-0}" \
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

test_summary
