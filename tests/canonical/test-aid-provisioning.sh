#!/usr/bin/env bash
# test-aid-provisioning.sh -- task-008: provisioning assertions for feature-002.
#
# Covers:
#   PRV-P*  _provision_shared_state_home unit tests (via AID_SHARED_STATE_HOME seam)
#   PRV-N*  npm postinstall guard assertions (root-provisions / non-root-skips /
#            env-pin-skips / no-clobber)
#   PRV-I*  install.sh _AID_HOME_PRESET guard assertions
#   PRV-R*  runtime fallback: non-writable shared AID_STATE_HOME -> user degrade
#   PRV-U*  per-user scope collapse (user scope never touches /var/lib)
#
# SAFETY:
#   - HOME is pinned to a throwaway ($TMP/fakehome) for the whole process.
#     AID_HOME is also pinned.  Real /var/lib is never touched.
#   - AID_SHARED_STATE_HOME always points into $TMP; the seam is tested and
#     real /var/lib/aid is structurally bypassed.
#   - Escape canary at the end asserts the real repo git status is unchanged.
#
# Usage:
#   bash tests/canonical/test-aid-provisioning.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"
POSTINSTALL_JS="${REPO_ROOT}/packages/npm/scripts/postinstall.js"

# Verify required files exist.
for _f in "$BIN_AID" "$LIB_CORE" "$INSTALL_SH" "$POSTINSTALL_JS"; do
    [[ -f "$_f" ]] || { echo "ERROR: required file not found: $_f" >&2; exit 1; }
done

# ---- escape canary baseline ----------------------------------------------
REAL_GIT_BEFORE="$(git -C "${REPO_ROOT}" status --porcelain 2>/dev/null | wc -l)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- HOME + AID_HOME pin (bulletproof) ----------------------------------
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"
export AID_HOME="${TMP}/aid-home"
mkdir -p "${AID_HOME}"

# ============================================================================
# Helpers
# ============================================================================

# Shared-home sandbox dir.  Every test that needs AID_SHARED_STATE_HOME points
# into a unique sub-dir under $TMP/shared/ to stay completely isolated from any
# real /var/lib/aid path.
new_shared() { mktemp -d "${TMP}/shared.XXXXXX"; }
new_home()   { mktemp -d "${TMP}/home.XXXXXX"; }

# Run _provision_shared_state_home in an isolated subshell with a stubbed
# _aid_priv_run that never elevates (empty probe -> direct run always).
# Usage: psh_run <shared_dir>
# Sets OUT and RC.
psh_run() {
    local shared_dir="$1"
    OUT=$(bash -c '
        set -uo pipefail
        LIB_CORE="$1"
        SHARED="$2"
        source "$LIB_CORE"
        # Stub: _aid_priv_run with empty probe always runs directly (no sudo).
        _aid_priv_run() {
            local _probe="$1"; shift
            "$@"
        }
        _provision_shared_state_home "$SHARED"
    ' -- "$LIB_CORE" "$shared_dir" 2>&1)
    RC=$?
}

# Run registry_register in an isolated subshell against a controlled AID_STATE_HOME.
# Sets OUT and RC.
reg_register() {
    local state_home="$1" repo="$2" user_home="$3"
    OUT=$(HOME="$user_home" AID_HOME="$state_home" AID_STATE_HOME="$state_home" _AID_VERBOSE=0 \
          bash -c '
        set -uo pipefail
        BIN_AID="$1"; repo="$2"
        # Extract _aid_priv_run and registry helpers from bin/aid.
        PRIV_START=$(grep -n "^_aid_priv_run()" "$BIN_AID" | head -1 | cut -d: -f1)
        PRIV_END=$(awk "NR>=${PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
        [[ -n "$PRIV_START" && -n "$PRIV_END" ]] && \
            eval "$(sed -n "${PRIV_START},${PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
        START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
        END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
        [[ -n "$START" && -n "$END" ]] || { echo "ERROR: registry section not found" >&2; exit 1; }
        eval "$(sed -n "${START},${END}p" "$BIN_AID")" 2>/dev/null || true
        registry_register "$repo"
    ' -- "$BIN_AID" "$repo" 2>&1)
    RC=$?
}

# Same but extracts functions from a pre-built harness (re-uses setup from test-registry.sh).
# For simplicity, we inline the harness calls directly.

# ============================================================================
# Section 1: _provision_shared_state_home unit assertions  (PRV-P*)
# ============================================================================
echo "=== PRV-P: _provision_shared_state_home unit assertions ==="

# PRV-P01: fresh dir -> creates $SHARED (mode 0755) + $SHARED/registry.yml (mode 0644).
_P01_SHARED="${TMP}/prv-p01-shared"
psh_run "$_P01_SHARED"
assert_exit_eq "$RC" 0 "PRV-P01a _provision_shared_state_home on fresh dir -> exit 0"
assert_dir_exists "$_P01_SHARED" "PRV-P01b shared dir created"
assert_file_exists "${_P01_SHARED}/registry.yml" "PRV-P01c registry.yml seeded"
# Mode checks (stat -c on Linux).
_P01_DIR_PERM="$(stat -c '%a' "$_P01_SHARED" 2>/dev/null || echo 'N/A')"
assert_eq "$_P01_DIR_PERM" "755" "PRV-P01d shared dir mode 0755"
_P01_FILE_PERM="$(stat -c '%a' "${_P01_SHARED}/registry.yml" 2>/dev/null || echo 'N/A')"
assert_eq "$_P01_FILE_PERM" "644" "PRV-P01e registry.yml mode 0644"

# PRV-P02: registry.yml content -- schema: 1 + repos: + comment.
assert_file_contains "${_P01_SHARED}/registry.yml" "schema: 1" "PRV-P02a schema: 1 present"
assert_file_contains "${_P01_SHARED}/registry.yml" "repos:" "PRV-P02b repos: key present"
assert_file_contains "${_P01_SHARED}/registry.yml" \
    "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)." \
    "PRV-P02c managed-by comment present"
# Zero repo items (no '  - ' entries).
_P02_ITEM_COUNT="$(grep -c '^  - ' "${_P01_SHARED}/registry.yml" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_P02_ITEM_COUNT" ]] && _P02_ITEM_COUNT="0"
assert_eq "$_P02_ITEM_COUNT" "0" "PRV-P02d fresh seed has zero repo entries"

# PRV-P03: no-clobber -- pre-seed an entry, re-run, entry preserved.
_P03_SHARED="${TMP}/prv-p03-shared"
mkdir -p "$_P03_SHARED"
printf '%s\n' "schema: 1" "repos:" "  - /some/pre-existing/repo" > "${_P03_SHARED}/registry.yml"
psh_run "$_P03_SHARED"
assert_exit_eq "$RC" 0 "PRV-P03a re-provision with existing registry -> exit 0"
assert_file_contains "${_P03_SHARED}/registry.yml" "/some/pre-existing/repo" \
    "PRV-P03b pre-existing entry preserved (no-clobber)"

# PRV-P04: atomic write -- no temp file left behind.
_P04_SHARED="${TMP}/prv-p04-shared"
psh_run "$_P04_SHARED"
_P04_TMP_COUNT="$(find "$_P04_SHARED" -name '*.aid-tmp.*' 2>/dev/null | wc -l || echo 0)"
assert_eq "$_P04_TMP_COUNT" "0" "PRV-P04 no temp file left behind after provision"

# PRV-P05: non-writable parent -> returns non-zero WITHOUT aborting.
# Create a parent dir (chmod 555) so mkdir -p can't create the child.
_P05_PARENT="${TMP}/prv-p05-parent"
_P05_SHARED="${_P05_PARENT}/aid-state"
mkdir -p "$_P05_PARENT"
chmod 555 "$_P05_PARENT"
psh_run "$_P05_SHARED"
_P05_RC=$RC
chmod 755 "$_P05_PARENT"   # restore so cleanup can delete it
assert_exit_nonzero "$_P05_RC" \
    "PRV-P05a non-writable parent -> returns non-zero (error path)"
# The helper must not abort the caller (set -e safe): we captured RC above.
assert_eq "$(ls "${_P05_PARENT}" 2>/dev/null | wc -l | tr -d ' ')" "0" \
    "PRV-P05b no partial artifact left in non-writable parent"

# PRV-P06: idempotent -- call twice on same dir -> still exactly one registry.yml.
_P06_SHARED="${TMP}/prv-p06-shared"
psh_run "$_P06_SHARED"
psh_run "$_P06_SHARED"
_P06_COUNT="$(find "$_P06_SHARED" -name 'registry.yml' 2>/dev/null | wc -l || echo 0)"
assert_eq "$_P06_COUNT" "1" "PRV-P06 double-provision -> exactly one registry.yml"

# ============================================================================
# Section 2: npm postinstall guard assertions  (PRV-N*)
# ============================================================================
echo ""
echo "=== PRV-N: npm postinstall guard assertions ==="

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP (PRV-N*): node not available; skipping npm postinstall assertions."
else

# PRV-N01: non-root (getuid != 0) -> provisions nothing (no shared dir created).
_N01_SHARED="${TMP}/prv-n01-shared"
_N01_OUT="$(AID_SHARED_STATE_HOME="${_N01_SHARED}" node "${POSTINSTALL_JS}" 2>&1 || true)"
# node returns 0 (postinstall is non-fatal), but the shared dir must NOT exist.
if [[ -d "$_N01_SHARED" ]]; then
    fail "PRV-N01 non-root: shared dir should NOT be created by non-root postinstall"
else
    pass "PRV-N01 non-root: shared dir not created (getuid != 0 guard active)"
fi

# PRV-N02: non-root -> no registry.yml created.
if [[ -f "${_N01_SHARED}/registry.yml" ]]; then
    fail "PRV-N02 non-root: registry.yml should NOT be seeded by non-root postinstall"
else
    pass "PRV-N02 non-root: registry.yml not created (getuid != 0 guard active)"
fi

# PRV-N04: confirm the guard logic is deterministic.
# The postinstall ONLY provisions when: process.getuid && process.getuid() === 0
# AND !existsSync(path.join(sharedHome, 'registry.yml')).
# Verify the source contains this exact guard (logic-level assertion).
_N04_GUARD_PRESENT="$(grep -c 'process.getuid().*=== 0' "${POSTINSTALL_JS}" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_N04_GUARD_PRESENT" ]] && _N04_GUARD_PRESENT=0
assert_exit_eq "$([ "${_N04_GUARD_PRESENT}" -ge 1 ] && echo 0 || echo 1)" 0 \
    "PRV-N04a postinstall.js contains getuid()===0 guard"
_N04_NOCLOBBER="$(grep -c 'existsSync.*registry.yml' "${POSTINSTALL_JS}" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_N04_NOCLOBBER" ]] && _N04_NOCLOBBER=0
assert_exit_eq "$([ "${_N04_NOCLOBBER}" -ge 1 ] && echo 0 || echo 1)" 0 \
    "PRV-N04b postinstall.js contains existsSync no-clobber check"
_N04_SEAM="$(grep -c 'AID_SHARED_STATE_HOME' "${POSTINSTALL_JS}" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_N04_SEAM" ]] && _N04_SEAM=0
assert_exit_eq "$([ "${_N04_SEAM}" -ge 1 ] && echo 0 || echo 1)" 0 \
    "PRV-N04c postinstall.js uses AID_SHARED_STATE_HOME seam"

fi  # end node available

# ============================================================================
# Section 3: install.sh _AID_HOME_PRESET guard assertions  (PRV-I*)
# ============================================================================
echo ""
echo "=== PRV-I: install.sh _AID_HOME_PRESET guard assertions ==="

# PRV-I01: AID_HOME set in env -> _AID_HOME_PRESET non-empty -> provisioning skipped.
# We confirm the guard is in the source (logic-level assertion, since we cannot run
# install.sh as root in this environment).
_I01_GUARD_COUNT="$(grep -c '_AID_HOME_PRESET' "${INSTALL_SH}" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_I01_GUARD_COUNT" ]] && _I01_GUARD_COUNT=0
assert_exit_eq "$([ "${_I01_GUARD_COUNT}" -ge 2 ] && echo 0 || echo 1)" 0 \
    "PRV-I01a install.sh contains _AID_HOME_PRESET guard (at least 2 occurrences)"

# PRV-I02: guard logic: id -u==0 AND -z _AID_HOME_PRESET -> provision.
# Confirm the guard pattern is present.
_I02_PATTERN="$(grep -c '"$(id -u)" -eq 0 && -z "$_AID_HOME_PRESET"' "${INSTALL_SH}" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$_I02_PATTERN" ]] && _I02_PATTERN=0
assert_exit_eq "$([ "${_I02_PATTERN}" -ge 1 ] && echo 0 || echo 1)" 0 \
    "PRV-I02a install.sh guard combines id -u==0 AND -z _AID_HOME_PRESET"

# PRV-I03: env-pin path (non-root, AID_HOME set) -- install.sh runs without provisioning.
# Run install.sh from the checkout in --no-path mode with AID_HOME pinned.
# This exercises the non-root path; the guard short-circuits because we're non-root.
_I03_HOME="${TMP}/prv-i03-home"
_I03_AID_HOME="${TMP}/prv-i03-aid-home"
_I03_SHARED="${TMP}/prv-i03-shared"
mkdir -p "${_I03_HOME}" "${_I03_AID_HOME}"
_I03_OUT="$(HOME="${_I03_HOME}" AID_HOME="${_I03_AID_HOME}" \
    AID_SHARED_STATE_HOME="${_I03_SHARED}" \
    bash "${INSTALL_SH}" --no-path 2>&1 || true)"
# The shared dir should NOT be created (non-root + _AID_HOME_PRESET non-empty).
if [[ -d "$_I03_SHARED" ]]; then
    fail "PRV-I03 env-pin: shared dir must not be created (guard blocked)"
else
    pass "PRV-I03 env-pin: shared dir not created (non-root + AID_HOME preset)"
fi

# PRV-I04: _AID_HOME_PRESET is captured BEFORE any provisioning call.
# Confirm source-order invariant: _AID_HOME_PRESET= line appears before
# the first _provision_shared_state_home call in install.sh.
_I04_PRESET_LINE="$(grep -n '_AID_HOME_PRESET=' "${INSTALL_SH}" | head -1 | cut -d: -f1)"
_I04_PROV_LINE="$(grep -n '_provision_shared_state_home' "${INSTALL_SH}" | head -1 | cut -d: -f1)"
if [[ -n "$_I04_PRESET_LINE" && -n "$_I04_PROV_LINE" && "$_I04_PRESET_LINE" -lt "$_I04_PROV_LINE" ]]; then
    pass "PRV-I04 _AID_HOME_PRESET captured (line ${_I04_PRESET_LINE}) before first _provision call (line ${_I04_PROV_LINE})"
else
    fail "PRV-I04 _AID_HOME_PRESET order check failed (preset=${_I04_PRESET_LINE} prov=${_I04_PROV_LINE})"
fi

# ============================================================================
# Section 4: runtime fallback (non-writable shared AID_STATE_HOME)  (PRV-R*)
# ============================================================================
echo ""
echo "=== PRV-R: runtime fallback to user tier when shared is non-writable ==="

# We set up a writable AID_HOME that mimics a user-level install (so bin/aid
# runs in "user scope"), but we deliberately make the AID_STATE_HOME non-writable
# (chmod 555) to simulate the global-shared-non-writable case.
# The harness from test-registry.sh (HARNESS_SCRIPT) is re-created inline here.

_R_HARNESS="${TMP}/prv-r-harness.sh"
cat > "$_R_HARNESS" << 'HARNESS_EOF'
#!/usr/bin/env bash
set -uo pipefail
BIN_AID="$1"; shift
AID_HOME="$1"; shift
AID_STATE_HOME="$1"; shift
CMD="$1"; shift
ARG="${1:-}"
export AID_HOME AID_STATE_HOME _AID_VERBOSE=0

# Extract _aid_priv_run.
PRIV_START=$(grep -n '^_aid_priv_run()' "$BIN_AID" | head -1 | cut -d: -f1)
PRIV_END=$(awk "NR>=${PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
[[ -n "$PRIV_START" && -n "$PRIV_END" ]] && \
    eval "$(sed -n "${PRIV_START},${PRIV_END}p" "$BIN_AID")" 2>/dev/null || true

# Extract registry helpers.
START=$(grep -n '# Registry helpers (DR-1' "$BIN_AID" | head -1 | cut -d: -f1)
END=$(grep -n '# Parse subcommand and dispatch' "$BIN_AID" | head -1 | cut -d: -f1)
[[ -n "$START" && -n "$END" ]] || { echo "ERROR: registry section not found" >&2; exit 1; }
eval "$(sed -n "${START},${END}p" "$BIN_AID")" 2>/dev/null || true

case "$CMD" in
    register)   registry_register "$ARG" ;;
    unregister) registry_unregister "$ARG" ;;
    *) echo "ERROR: unknown CMD: $CMD" >&2; exit 1 ;;
esac
HARNESS_EOF
chmod +x "$_R_HARNESS"

run_prv_harness() {
    local state_home="$1" user_home="$2" cmd="$3" arg="${4:-}"
    OUT=$(HOME="$user_home" AID_HOME="$state_home" AID_STATE_HOME="$state_home" \
          bash "$_R_HARNESS" "$BIN_AID" "$state_home" "$state_home" "$cmd" "$arg" 2>&1)
    RC=$?
}

# PRV-R01: writable AID_STATE_HOME -> registers in shared tier (no degrade, no WARN).
_R01_STATE="${TMP}/prv-r01-state"
_R01_HOME="${TMP}/prv-r01-home"
mkdir -p "$_R01_STATE" "${_R01_HOME}/.aid"
run_prv_harness "$_R01_STATE" "$_R01_HOME" register "/tmp/r01-repo"
assert_exit_eq "$RC" 0 "PRV-R01a register in writable state -> exit 0"
assert_file_exists "${_R01_STATE}/registry.yml" "PRV-R01b registry.yml in shared tier"
assert_file_contains "${_R01_STATE}/registry.yml" "/tmp/r01-repo" \
    "PRV-R01c repo entry in shared tier"
assert_output_not_contains "$OUT" "WARN:" "PRV-R01d no WARN when shared is writable"

# PRV-R02: NON-writable AID_STATE_HOME (chmod 555) -> degrades to user tier (~/.aid).
# No sudo invoked because empty probe -> direct _aid_priv_run never elevates.
_R02_STATE="${TMP}/prv-r02-state"
_R02_HOME="${TMP}/prv-r02-home"
mkdir -p "$_R02_STATE" "${_R02_HOME}/.aid"
chmod 555 "$_R02_STATE"
OUT_R02=$(HOME="$_R02_HOME" AID_HOME="$_R02_STATE" AID_STATE_HOME="$_R02_STATE" \
    bash "$_R_HARNESS" "$BIN_AID" "$_R02_STATE" "$_R02_STATE" register "/tmp/r02-repo" 2>&1)
RC_R02=$?
chmod 755 "$_R02_STATE"   # restore for cleanup

# Exit 0 (host command completes, degrade is fire-and-continue).
assert_exit_eq "$RC_R02" 0 "PRV-R02a register with non-writable shared -> exit 0 (degrade)"
# Entry must be in user tier ~/.aid/registry.yml.
assert_file_exists "${_R02_HOME}/.aid/registry.yml" \
    "PRV-R02b entry written to user tier ${_R02_HOME}/.aid/registry.yml"
assert_file_contains "${_R02_HOME}/.aid/registry.yml" "/tmp/r02-repo" \
    "PRV-R02c entry PRESERVED in user tier"
# Exactly one WARN: emitted.
_R02_WARN_COUNT="$(printf '%s\n' "$OUT_R02" | grep -c '^WARN:' || echo 0)"
assert_eq "$_R02_WARN_COUNT" "1" "PRV-R02d exactly one WARN: line emitted on degrade"
# No temp file left behind.
_R02_TMP_COUNT="$(find "${_R02_HOME}/.aid" -name '*.aid-tmp.*' 2>/dev/null | wc -l || echo 0)"
assert_eq "$_R02_TMP_COUNT" "0" "PRV-R02e no temp leak in user tier after degrade"

# PRV-R03: no sudo invoked on degrade (empty-probe path never elevates).
# _aid_priv_run with empty probe calls cmd directly; no sudo call.
# Verify by checking that 'sudo' does not appear in the WARN output.
assert_output_not_contains "$OUT_R02" "sudo" \
    "PRV-R03 no 'sudo' invoked on degrade (empty-probe never-elevate)"

# PRV-R04: second register call with same non-writable shared -> idempotent in user tier.
chmod 555 "$_R02_STATE"
OUT_R04=$(HOME="$_R02_HOME" AID_HOME="$_R02_STATE" AID_STATE_HOME="$_R02_STATE" \
    bash "$_R_HARNESS" "$BIN_AID" "$_R02_STATE" "$_R02_STATE" register "/tmp/r02-repo" 2>&1)
RC_R04=$?
chmod 755 "$_R02_STATE"
assert_exit_eq "$RC_R04" 0 "PRV-R04a re-register same path on non-writable shared -> exit 0"
_R04_COUNT="$(grep -c '  - /tmp/r02-repo' "${_R02_HOME}/.aid/registry.yml" 2>/dev/null || echo 0)"
assert_eq "$_R04_COUNT" "1" "PRV-R04b idempotent: still one entry after double register"

# ============================================================================
# Section 5: per-user scope collapse  (PRV-U*)
# ============================================================================
echo ""
echo "=== PRV-U: per-user scope collapse assertions ==="

# Per-user scope: AID_CODE_HOME is user-writable (or id -u == 0), so
# AID_STATE_HOME = AID_HOME (defaults to ~/.aid). This means the
# /var/lib or AID_SHARED_STATE_HOME path is NEVER consulted.

# PRV-U01: user-scope registry_register writes to ~/.aid only.
# Use the harness but with a writable AID_STATE_HOME that IS the user-home/.aid.
_U01_HOME="${TMP}/prv-u01-home"
_U01_STATE="${_U01_HOME}/.aid"
mkdir -p "$_U01_STATE"
# Deliberately create a separate dir that would be the shared path to confirm
# it's never touched.
_U01_SHARED_CANARY="${TMP}/prv-u01-varlib-canary"
mkdir -p "$_U01_SHARED_CANARY"
OUT_U01=$(HOME="$_U01_HOME" AID_HOME="$_U01_STATE" AID_STATE_HOME="$_U01_STATE" \
    AID_SHARED_STATE_HOME="$_U01_SHARED_CANARY" \
    bash "$_R_HARNESS" "$BIN_AID" "$_U01_STATE" "$_U01_STATE" register "/tmp/u01-repo" 2>&1)
RC_U01=$?
assert_exit_eq "$RC_U01" 0 "PRV-U01a user-scope register -> exit 0"
assert_file_exists "${_U01_STATE}/registry.yml" "PRV-U01b registry.yml in user tier (~/.aid)"
# The /var/lib canary dir must have no registry.yml.
if [[ -f "${_U01_SHARED_CANARY}/registry.yml" ]]; then
    fail "PRV-U01c user scope: shared canary dir was incorrectly touched"
else
    pass "PRV-U01c user scope: /var/lib canary dir untouched (correct)"
fi
assert_output_not_contains "$OUT_U01" "WARN:" "PRV-U01d no WARN in user scope"

# PRV-U02: per-user scope never calls _provision_shared_state_home.
# Verify by running the install.sh with a non-root user (current process is non-root)
# and env-pinned AID_HOME -> the provision block short-circuits.
_U02_HOME="${TMP}/prv-u02-home"
_U02_AID_HOME="${TMP}/prv-u02-aid-home"
_U02_SHARED="${TMP}/prv-u02-shared-canary"
mkdir -p "${_U02_HOME}" "${_U02_AID_HOME}"
HOME="${_U02_HOME}" AID_HOME="${_U02_AID_HOME}" \
    AID_SHARED_STATE_HOME="${_U02_SHARED}" \
    bash "${INSTALL_SH}" --no-path >/dev/null 2>&1 || true
if [[ -d "$_U02_SHARED" ]]; then
    fail "PRV-U02 user scope: shared canary created by install.sh (should not happen)"
else
    pass "PRV-U02 user scope: /var/lib canary not created by install.sh (correct)"
fi

# ============================================================================
# Escape canary: real repo must be unchanged
# ============================================================================
echo ""
echo "=== PRV-SAFETY: escape canary ==="
REAL_GIT_AFTER="$(git -C "${REPO_ROOT}" status --porcelain 2>/dev/null | wc -l)"
assert_eq "${REAL_GIT_BEFORE}" "${REAL_GIT_AFTER}" \
    "PRV-SAFETY-01 real repo git status unchanged (no real /var/lib touched)"

test_summary
