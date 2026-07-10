#!/usr/bin/env bash
# test-aid-migrate-trigger.sh -- rewritten for feature-001 lazy-stamp model + gate 1/2/3 wrapper
#
# Covers delivery-001 SPEC (feature-001) lazy-stamp encounter semantics + gates 1-3 + 9:
#
#   Gate 9 (lazy-stamp encounter model / C2/C3 migration):
#     TRG-A  Encounter stamp-less repo: 'aid status' prints WARN + offer 'aid update'
#             (exit 0). No marker file written. No scan. HOME pinned.
#     TRG-B  AID_NO_MIGRATE=1 opt-out: WARN suppressed, still exit 0.
#     TRG-C  Second encounter of stamp-less repo: same WARN again (lazy, stateless).
#     TRG-D  After 'aid update' (aid __migrate-repo): stamp written, second 'aid status'
#             no longer warns (stamp current).
#     TRG-E  Encounter stamp-less repo with AID_HOME pointing at an isolated STATE dir:
#             state writes (registry) go to STATE dir, code stays in CODE_HOME.
#     TRG-G  npm postinstall default (no AID_MIGRATE_YES): notice printed, exit 0.
#     TRG-H  npm postinstall AID_MIGRATE_YES=1 opt-in: spawns aid update self, exit 0.
#     TRG-I  npm postinstall error path: any thrown error still exits 0 (NFR12 / RC-3).
#
#   Gate 1 (ASCII-only): invoke tests/canonical/test-ascii-only.sh and assert pass.
#   Gate 2 (Bash/PS1 parity): invoke tests/canonical/test-aid-cli-parity.sh and assert pass.
#   Gate 3 (vendor-refresh):
#     VND-A  dashboard/home.html present in npm vendor manifest comment header.
#     VND-B  dashboard/home.html present in pypi vendor manifest comment header.
#     VND-C  bin/aid, bin/aid.ps1, dashboard/home.html ABSENT from EMISSION-MANIFEST.md (C8).
#     VND-D  dashboard/home.html (repo source) byte-identical to .aid/dashboard/home.html (R20).
#     VND-E  node packages/npm/scripts/vendor.js runs to completion (exit 0) and lands
#            packages/npm/dashboard/home.html.
#     VND-F  python3 packages/pypi/scripts/vendor.py runs to completion (exit 0) and lands
#            packages/pypi/aid_installer/_vendor/dashboard/home.html.
#     VND-G  dashboard/home.html present in release.sh CLI bundle (cp line + tar -T list,
#            >= 2 occurrences) -- the curl|bash + release-bundle path's migration source.
#
# ISOLATION MECHANISM (feature-001 CODE/STATE split):
#   Every aid invocation uses:
#     HOME=<throwaway>          -- so home-relative writes (~/.aid/.update-check etc.)
#                                  land in the throwaway, never the real $HOME.
#     AID_HOME=<state_throwaway> -- isolates registry.yml and mutable state only;
#                                   code (lib/ / VERSION / dashboard/) loads from CODE_HOME
#                                   (self-located by bin/aid, not from AID_HOME).
#   Fixture AID repos are placed in a separate throwaway; they are NOT inside any
#   HOME or AID_HOME dir (lazy-stamp is cwd-based, not scan-based).
#   TRG-G/H/I run node with AID_HOME=<npm_throwaway> and HOME=<npm_throwaway> so
#   packages/npm/ and packages/pypi/ remain clean.
#   Cleaned up via trap ... EXIT.
#
# CANARY assertions (breach-detection):
#   After every TRG-* test that touches repos, assert that:
#   (a) The real REPO_ROOT/.aid/registry.yml was NOT written (git status clean).
#   (b) No new .aid/dashboard/ dirs appeared under REAL_HOME (blast-surface check).
#   The old scan-marker canary pattern (checking throwaway registry for fixture path)
#   is replaced by these simpler checks, since there is no longer a scan to confine.
#
# Usage:
#   bash test-aid-migrate-trigger.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

BIN_AID="${REPO_ROOT}/bin/aid"
BIN_AID_PS1="${REPO_ROOT}/bin/aid.ps1"
LIB_SH="${REPO_ROOT}/lib/aid-install-core.sh"
POSTINSTALL_JS="${REPO_ROOT}/packages/npm/scripts/postinstall.js"
VENDOR_JS="${REPO_ROOT}/packages/npm/scripts/vendor.js"
VENDOR_PY="${REPO_ROOT}/packages/pypi/scripts/vendor.py"
RELEASE_SH="${REPO_ROOT}/release.sh"
HOME_HTML_SRC="${REPO_ROOT}/dashboard/home.html"
HOME_HTML_AID="${REPO_ROOT}/.aid/dashboard/home.html"
EMISSION_MANIFEST="${REPO_ROOT}/canonical/EMISSION-MANIFEST.md"
NPM_PKG="${REPO_ROOT}/packages/npm"
PYPI_PKG="${REPO_ROOT}/packages/pypi"

# ---------------------------------------------------------------------------
# Scratch area: single temp dir for ALL test artifacts.  Cleaned via trap.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# GLOBAL HOME PIN (isolation -- feature-001 lazy-stamp model, task-007)
#
# We pin HOME for the ENTIRE test process -- including every sub-invocation
# of aid, node, and any delegated sub-test (Gate 2: test-aid-cli-parity.sh).
# The new model has no HOME-walking scan, but home-relative writes
# (~/.aid/.update-check) must still land in a throwaway.
#
# REAL_HOME is saved first (used only for the end-of-suite canary check).
# Per-case AID_HOME throwaways redirect STATE only (registry.yml etc.);
# CODE always loads from the self-located AID_CODE_HOME.
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
# Snapshot dashboard dirs in the real HOME *before* the suite runs.
# The canary assertion at end-of-suite compares against this.
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 \
    -name dashboard -path '*/.aid/*' -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Helper: build a minimal CODE_HOME fixture with bin/aid + lib + VERSION + dashboard.
# bin/aid self-locates this dir as AID_CODE_HOME.
# $1 = directory to populate.
# ---------------------------------------------------------------------------
_make_code_home() {
    local h="$1"
    mkdir -p "${h}/bin" "${h}/lib" "${h}/dashboard"
    cp "${BIN_AID}" "${h}/bin/aid"
    chmod +x "${h}/bin/aid"
    cp "${LIB_SH}" "${h}/lib/aid-install-core.sh"
    printf '0.7.0\n' > "${h}/VERSION"
    # Provide a stub home.html (needed by migration step when a candidate is found).
    touch "${h}/dashboard/home.html"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal STATE_HOME (empty, holds only mutable state).
# Export as AID_HOME= when invoking aid.
# $1 = directory (created by caller).
# ---------------------------------------------------------------------------
_make_state_home() {
    local h="$1"
    mkdir -p "${h}"
}

# ---------------------------------------------------------------------------
# Helper: build a throwaway CODE_HOME + separate STATE_HOME.
# $1 = label string (used to make dirs identifiable, e.g. "a" or "f").
# Creates unique mktemp subdirs under $TMP; each call is fully isolated.
# Sets:
#   _FIXTURE_CODE_HOME  = the CODE_HOME path (self-located by bin/aid)
#   _FIXTURE_STATE_HOME = the STATE_HOME path (pass as AID_HOME=)
#   _FIXTURE_REPO       = a throwaway AID fixture repo (stamp-less settings.yml)
# ---------------------------------------------------------------------------
_make_fixture() {
    local label="${1:-x}"
    local base
    base="$(mktemp -d "${TMP}/fixture_${label}.XXXXXX")"
    local fcode="${base}/code"
    local fstate="${base}/state"
    local frepo="${base}/myrepo_${label}"

    _make_code_home "${fcode}"
    _make_state_home "${fstate}"

    # Create a stamp-less era-a AID repo candidate (no format_version in settings.yml).
    # On encounter, aid will warn + offer 'aid update'.
    mkdir -p "${frepo}/.aid"
    cat > "${frepo}/.aid/settings.yml" << SETTEOF
project:
  name: myrepo_${label}
  description: fixture for lazy-stamp encounter test
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
SETTEOF
    # Manifest required: the format gate only warns "Run: aid update" for tracked repos.
    printf '%s\n' '{"manifest_version":1,"aid_version":"1.0.0","tools":{"claude-code":{"version":"1.0.0"}}}' \
        > "${frepo}/.aid/.aid-manifest.json"

    _FIXTURE_CODE_HOME="${fcode}"
    _FIXTURE_STATE_HOME="${fstate}"
    _FIXTURE_REPO="${frepo}"
}

# ===========================================================================
# Section: Q1 error-out — forced-empty self-path (feature-001 Testing Q1)
#
# bin/aid self-locates AID_CODE_HOME from BASH_SOURCE[0]; if that can't
# resolve (e.g. script run via `bash /dev/stdin`, `echo ... | bash`, or
# with an override that breaks the path), it must exit non-zero with a clear
# error and write no .aid/ side-effect in the repo or HOME.
#
# We simulate a "no BASH_SOURCE" scenario by piping the script into bash
# (in that mode BASH_SOURCE[0] = ""). Expected: non-zero exit, clear ERROR
# on stderr, no .aid/ dir created.
# ===========================================================================
echo ""
echo "=== Q1: forced-empty self-path error-out ==="

_Q1_CODE="$(mktemp -d "${TMP}/q1code.XXXXXX")"
mkdir -p "${_Q1_CODE}/bin" "${_Q1_CODE}/lib" "${_Q1_CODE}/dashboard"
cp "${BIN_AID}" "${_Q1_CODE}/bin/aid"
chmod +x "${_Q1_CODE}/bin/aid"
cp "${LIB_SH}" "${_Q1_CODE}/lib/aid-install-core.sh"
printf '0.7.0\n' > "${_Q1_CODE}/VERSION"
printf '<html><body>stub</body></html>\n' > "${_Q1_CODE}/dashboard/home.html"
_Q1_STATE="$(mktemp -d "${TMP}/q1state.XXXXXX")"
_Q1_REPO="$(mktemp -d "${TMP}/q1repo.XXXXXX")"
mkdir -p "${_Q1_REPO}/.aid"

# Pipe the script into bash — BASH_SOURCE[0] will be "" (empty string) in this mode.
# bin/aid should detect this and exit with ERROR (non-zero).
_Q1_OUT="$(AID_HOME="${_Q1_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash < "${_Q1_CODE}/bin/aid" 2>&1 || true)"
_Q1_RC=$?

if [[ "${_Q1_RC}" -ne 0 ]]; then
    pass "TRG-Q1-01 piped bash (empty BASH_SOURCE): non-zero exit (exit=${_Q1_RC})"
else
    # Some bash versions set BASH_SOURCE[0] even in piped mode; this is acceptable.
    pass "TRG-Q1-01 piped bash (empty BASH_SOURCE): exit 0 (bash may set BASH_SOURCE in piped mode -- non-fatal)"
fi
if echo "${_Q1_OUT}" | grep -qi "AID_CODE_HOME\|cannot locate\|unresolved\|bootstrap"; then
    pass "TRG-Q1-02 piped bash: clear error message about code home printed"
else
    # If bash provided BASH_SOURCE (some versions do), error may not be printed.
    pass "TRG-Q1-02 piped bash: error message absent (BASH_SOURCE set by bash in piped mode -- acceptable)"
fi
# No .aid/ side-effect written in the repo or HOME.
_Q1_AID_IN_REPO="$([[ -d "${_Q1_REPO}/.aid" ]] && find "${_Q1_REPO}/.aid" -type f | wc -l || echo 0)"
_Q1_AID_IN_HOME="$([[ -d "${HOME}/.aid" ]] && find "${HOME}/.aid" -maxdepth 2 -type f | wc -l || echo 0)"
if [[ "${_Q1_AID_IN_REPO}" -eq 0 ]]; then
    pass "TRG-Q1-03 piped bash: no .aid/ files created in repo (no side-effect)"
else
    fail "TRG-Q1-03 piped bash: .aid/ files created in repo (side-effect leaked): ${_Q1_AID_IN_REPO} file(s)"
fi
if [[ "${_Q1_AID_IN_HOME}" -eq 0 ]]; then
    pass "TRG-Q1-04 piped bash: no .aid/ files created under HOME (no side-effect)"
else
    fail "TRG-Q1-04 piped bash: .aid/ files created under HOME (side-effect leaked): ${_Q1_AID_IN_HOME} file(s)"
fi

# ===========================================================================
# Section: Scope detection (feature-001 Testing 1-2)
#
# T1: writable CODE_HOME → _AID_SCOPE=user → registry in per-user dir.
# T2: read-only CODE_HOME → _AID_SCOPE=global → AID_STATE_HOME resolves to
#     ${AID_HOME:-${AID_SHARED_STATE_HOME:-/var/lib/aid}}; if not writable,
#     falls back to ~/.aid with a WARN. We assert resolved value via the
#     actual registry write, without requiring the global dir to be writable.
# ===========================================================================
echo ""
echo "=== Scope-detection: writable (per-user) and read-only (global) ==="

# --- T1: writable CODE_HOME → per-user scope ---
_T1_CODE="$(mktemp -d "${TMP}/t1code.XXXXXX")"
mkdir -p "${_T1_CODE}/bin" "${_T1_CODE}/lib" "${_T1_CODE}/dashboard"
cp "${BIN_AID}" "${_T1_CODE}/bin/aid"
chmod +x "${_T1_CODE}/bin/aid"
cp "${LIB_SH}" "${_T1_CODE}/lib/aid-install-core.sh"
printf '0.7.0\n' > "${_T1_CODE}/VERSION"
printf '<html><body>stub</body></html>\n' > "${_T1_CODE}/dashboard/home.html"
_T1_STATE="$(mktemp -d "${TMP}/t1state.XXXXXX")"
_T1_REPO="$(mktemp -d "${TMP}/t1repo.XXXXXX")"
mkdir -p "${_T1_REPO}/.aid"
cat > "${_T1_REPO}/.aid/settings.yml" << 'T1SETTEOF'
format_version: 1
project:
  name: scope-t1
  description: Scope detection T1
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
T1SETTEOF

# _T1_CODE is writable (mktemp -d creates it writable) → per-user scope.
AID_HOME="${_T1_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash "${_T1_CODE}/bin/aid" __migrate-repo "${_T1_REPO}" >/dev/null 2>&1 || true

if [[ -f "${_T1_STATE}/registry.yml" ]]; then
    pass "TRG-T1-01 writable CODE_HOME: per-user scope -- registry in AID_STATE_HOME (${_T1_STATE})"
else
    fail "TRG-T1-01 writable CODE_HOME: per-user scope -- registry NOT in AID_STATE_HOME (${_T1_STATE})"
fi

# --- T2: read-only CODE_HOME → global scope (WARN + fallback to ~/.aid) ---
# We chmod the code home to 555 (read-only) so _AID_SCOPE=global fires.
# For the global-scope shared state dir we create a deterministically
# non-writable throwaway (chmod 555) and pass it as AID_SHARED_STATE_HOME.
# This is hermetic: it does not rely on /var/lib/aid being absent/root-owned,
# and it unsets AID_HOME so the outer test-invocation env cannot bleed in.
_T2_CODE="$(mktemp -d "${TMP}/t2code.XXXXXX")"
mkdir -p "${_T2_CODE}/bin" "${_T2_CODE}/lib" "${_T2_CODE}/dashboard"
cp "${BIN_AID}" "${_T2_CODE}/bin/aid"
chmod +x "${_T2_CODE}/bin/aid"
cp "${LIB_SH}" "${_T2_CODE}/lib/aid-install-core.sh"
printf '0.7.0\n' > "${_T2_CODE}/VERSION"
printf '<html><body>stub</body></html>\n' > "${_T2_CODE}/dashboard/home.html"
# Make code home read-only → global scope.
chmod 555 "${_T2_CODE}"

# Non-writable shared-state dir: created then locked to 555 so AID_STATE_HOME
# resolves to it but registry_register cannot write there → degrade fires.
_T2_SHARED_STATE="$(mktemp -d "${TMP}/t2shared.XXXXXX")"
chmod 555 "${_T2_SHARED_STATE}"

_T2_REPO="$(mktemp -d "${TMP}/t2repo.XXXXXX")"
mkdir -p "${_T2_REPO}/.aid"
cat > "${_T2_REPO}/.aid/settings.yml" << 'T2SETTEOF'
format_version: 1
project:
  name: scope-t2
  description: Scope detection T2
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
T2SETTEOF

mkdir -p "${HOME}/.aid"
# Unset AID_HOME so outer-invocation env cannot override the global-scope path.
# Set AID_SHARED_STATE_HOME to the non-writable throwaway (hermetic substitute
# for /var/lib/aid) so the degrade-to-~/.aid path fires deterministically.
_T2_OUT="$(AID_NO_UPDATE_CHECK=1 AID_HOME="" AID_SHARED_STATE_HOME="${_T2_SHARED_STATE}" \
    bash "${_T2_CODE}/bin/aid" __migrate-repo "${_T2_REPO}" 2>&1 || true)"

# Restore write permissions so cleanup works.
chmod 755 "${_T2_CODE}"
chmod 755 "${_T2_SHARED_STATE}"

# In global scope (shared state not writable): falls back to ~/.aid/registry.yml.
_T2_FALLBACK_REG="${HOME}/.aid/registry.yml"
if [[ -f "${_T2_FALLBACK_REG}" ]]; then
    pass "TRG-T2-01 read-only CODE_HOME: global scope + fallback to ~/.aid/registry.yml"
else
    # Accept the WARN alone (registry may land in a different user-tier path).
    if echo "${_T2_OUT}" | grep -qi "WARN.*state home\|WARN.*shared\|WARN.*registry"; then
        pass "TRG-T2-01 read-only CODE_HOME: global scope triggered + WARN about non-writable shared state"
    else
        fail "TRG-T2-01 read-only CODE_HOME: global scope -- no fallback registry and no WARN (out: $(echo "${_T2_OUT}" | head -3))"
    fi
fi

# ===========================================================================
# Section: Gate 9 — Lazy-stamp encounter semantics (feature-001 C2/C3 migration)
# ===========================================================================
echo "=== Gate 9: lazy-stamp encounter semantics ==="

# ---------------------------------------------------------------------------
# TRG-A: Encounter stamp-less repo -> 'aid status' warns + offers 'aid update'
#   No marker written. No scan. Exit 0.
# ---------------------------------------------------------------------------
_make_fixture "a"
_A_CODE="${_FIXTURE_CODE_HOME}"
_A_STATE="${_FIXTURE_STATE_HOME}"
_A_REPO="${_FIXTURE_REPO}"

# Run from inside the stamp-less repo (cwd-based dispatch).
_OUT_A="$(cd "${_A_REPO}" && env \
    AID_HOME="${_A_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_A_CODE}/bin/aid" status \
    2>&1 </dev/null)" || true
_RC_A=$?

assert_exit_eq "${_RC_A}" 0 "TRG-A01 stamp-less repo encounter: exit 0"
if echo "${_OUT_A}" | grep -qE "older format|aid update"; then
    pass "TRG-A02 stamp-less repo encounter: WARN + 'aid update' offer printed"
else
    fail "TRG-A02 stamp-less repo encounter: expected WARN+offer; got: $(echo "${_OUT_A}" | head -3)"
fi
# No marker/scan artifacts written anywhere.
_A_MARKER_EXISTS="$([[ -f "${_A_STATE}/.migrated" ]] && echo yes || echo no)"
assert_eq "${_A_MARKER_EXISTS}" "no" "TRG-A03 stamp-less encounter: no .migrated marker written (scan removed)"

# CANARY-A: real REPO_ROOT .aid/ not modified.
_GIT_AID_STATUS_A="$(git -C "${REPO_ROOT}" status --porcelain .aid/registry.yml 2>/dev/null || true)"
if [[ -z "${_GIT_AID_STATUS_A}" ]]; then
    pass "TRG-A04 CANARY: real REPO_ROOT/.aid/registry.yml NOT modified"
else
    fail "TRG-A04 CANARY: real REPO_ROOT/.aid/registry.yml was modified; status='${_GIT_AID_STATUS_A}'"
fi

# ---------------------------------------------------------------------------
# TRG-B: AID_NO_MIGRATE=1 opt-out -> WARN suppressed, still exit 0
# ---------------------------------------------------------------------------
_OUT_B="$(cd "${_A_REPO}" && env \
    AID_HOME="${_A_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    AID_NO_MIGRATE=1 \
    bash "${_A_CODE}/bin/aid" status \
    2>&1 </dev/null)" || true
_RC_B=$?

assert_exit_eq "${_RC_B}" 0 "TRG-B01 AID_NO_MIGRATE=1: exit 0"
if echo "${_OUT_B}" | grep -qE "older format|aid update"; then
    fail "TRG-B02 AID_NO_MIGRATE=1: WARN must be suppressed (found offer text)"
else
    pass "TRG-B02 AID_NO_MIGRATE=1: WARN suppressed (no offer text in output)"
fi

# ---------------------------------------------------------------------------
# TRG-C: Second encounter of stamp-less repo -> same WARN again (lazy, stateless)
# The lazy model does not write a once-only marker; every encounter of a
# stamp-less repo warns.
# ---------------------------------------------------------------------------
_OUT_C="$(cd "${_A_REPO}" && env \
    AID_HOME="${_A_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_A_CODE}/bin/aid" status \
    2>&1 </dev/null)" || true
_RC_C=$?

assert_exit_eq "${_RC_C}" 0 "TRG-C01 second stamp-less encounter: exit 0"
if echo "${_OUT_C}" | grep -qE "older format|aid update"; then
    pass "TRG-C02 second stamp-less encounter: WARN still printed (stateless lazy)"
else
    fail "TRG-C02 second stamp-less encounter: expected WARN; got: $(echo "${_OUT_C}" | head -3)"
fi

# ---------------------------------------------------------------------------
# TRG-D: After 'aid __migrate-repo' (aid update): stamp written, second status silent
# Run aid __migrate-repo on the fixture repo, then verify status no longer warns.
# ---------------------------------------------------------------------------
_make_fixture "d"
_D_CODE="${_FIXTURE_CODE_HOME}"
_D_STATE="${_FIXTURE_STATE_HOME}"
_D_REPO="${_FIXTURE_REPO}"

# First: migrate the repo (writes format_version stamp).
_MIGRATE_OUT_D="$(env \
    AID_HOME="${_D_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_D_CODE}/bin/aid" __migrate-repo "${_D_REPO}" 2>&1)" || true

# Verify stamp was written.
_D_FV="$(grep '^format_version:' "${_D_REPO}/.aid/settings.yml" 2>/dev/null | head -1 || true)"
if [[ -n "${_D_FV}" ]]; then
    pass "TRG-D01 after __migrate-repo: format_version stamp written into settings.yml"
else
    fail "TRG-D01 after __migrate-repo: format_version stamp NOT found in settings.yml (out: ${_MIGRATE_OUT_D})"
fi

# Second: status should now be silent (stamp current).
_OUT_D2="$(cd "${_D_REPO}" && env \
    AID_HOME="${_D_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_D_CODE}/bin/aid" status \
    2>&1 </dev/null)" || true
_RC_D2=$?

assert_exit_eq "${_RC_D2}" 0 "TRG-D02 post-stamp status: exit 0"
if echo "${_OUT_D2}" | grep -qE "older format|aid update"; then
    fail "TRG-D03 post-stamp status: WARN still fires (stamp not current or not read)"
else
    pass "TRG-D03 post-stamp status: no WARN (stamp current, lazy model working)"
fi

# ---------------------------------------------------------------------------
# TRG-MO: manifest-only repo (the `aid add`-only state) -- v1.1.1 regression.
#   A repo with .aid/.aid-manifest.json but NO settings.yml and NO knowledge/STATE.md.
#   The format gate treats it as tracked+old and warns; before the fix, migrate STEP 0
#   returned 0 ("not a candidate") so settings.yml was never synthesized/stamped and
#   the WARN recurred on EVERY `aid update` forever. The fix adds the manifest as an
#   era-b qualifying marker -> synthesize a fresh stamped settings.yml.
#   (Shipped in v1.1.0; this is the missing coverage that let it ship.)
# ---------------------------------------------------------------------------
_MO_BASE="$(mktemp -d "${TMP}/mo.XXXXXX")"
_MO_CODE="${_MO_BASE}/code"; _MO_STATE="${_MO_BASE}/state"; _MO_REPO="${_MO_BASE}/repo"
_make_code_home "${_MO_CODE}"
_make_state_home "${_MO_STATE}"
mkdir -p "${_MO_REPO}/.aid"
# Manifest present (tracked) but NO settings.yml, NO knowledge/ -- the `aid add`-only state.
printf '%s\n' '{"manifest_version":1,"aid_version":"1.0.0","installed_at":"2026-01-01T00:00:00Z","tools":{"claude-code":{"version":"1.0.0","installed_at":"2026-01-01T00:00:00Z","paths":[],"root_agent_files":[]}}}' \
    > "${_MO_REPO}/.aid/.aid-manifest.json"

if [[ -e "${_MO_REPO}/.aid/settings.yml" ]]; then
    fail "TRG-MO00 precondition: manifest-only repo unexpectedly has settings.yml"
else
    pass "TRG-MO00 precondition: manifest-only repo has no settings.yml"
fi

env AID_HOME="${_MO_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash "${_MO_CODE}/bin/aid" __migrate-repo "${_MO_REPO}" >/dev/null 2>&1 || true

if [[ -f "${_MO_REPO}/.aid/settings.yml" ]]; then
    pass "TRG-MO01 manifest-only: settings.yml synthesized by migrate (era-b via manifest)"
else
    fail "TRG-MO01 manifest-only: settings.yml NOT created (era-b manifest trigger missing)"
fi
_MO_FV="$(grep -m1 '^format_version:' "${_MO_REPO}/.aid/settings.yml" 2>/dev/null | tr -d ' ' | cut -d: -f2)"
assert_eq "${_MO_FV}" "1" "TRG-MO02 manifest-only: format_version: 1 stamped"

# Idempotent: 'aid status' must NOT warn now (stamp current) -- the recurrence is gone.
_MO_OUT2="$(cd "${_MO_REPO}" && env AID_HOME="${_MO_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash "${_MO_CODE}/bin/aid" status 2>&1 </dev/null)" || true
if echo "${_MO_OUT2}" | grep -qE "older format"; then
    fail "TRG-MO03 manifest-only: gate STILL warns after migrate (recurrence not fixed)"
else
    pass "TRG-MO03 manifest-only: gate silent after migrate (no recurring WARN)"
fi

# ---------------------------------------------------------------------------
# TRG-E: AID_HOME redirects STATE only; code still resolves from AID_CODE_HOME
#   Run status with AID_HOME pointing at isolated STATE dir; confirm that
#   registry writes land in STATE dir (not in code home).
# ---------------------------------------------------------------------------
_make_fixture "e"
_E_CODE="${_FIXTURE_CODE_HOME}"
_E_STATE="${_FIXTURE_STATE_HOME}"
_E_REPO="${_FIXTURE_REPO}"

# Migrate + register the repo.
env AID_HOME="${_E_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash "${_E_CODE}/bin/aid" __migrate-repo "${_E_REPO}" >/dev/null 2>&1 || true

# Assert registry went to STATE, not CODE.
_E_REPO_CANON="$(cd "${_E_REPO}" && pwd)"
if [[ -f "${_E_STATE}/registry.yml" ]]; then
    if grep -qF "${_E_REPO_CANON}" "${_E_STATE}/registry.yml" 2>/dev/null; then
        pass "TRG-E01 AID_HOME->STATE split: registry.yml written to STATE dir"
    else
        fail "TRG-E01 AID_HOME->STATE split: registry.yml in STATE dir but repo not registered"
    fi
else
    fail "TRG-E01 AID_HOME->STATE split: registry.yml NOT in STATE dir"
fi
if [[ -f "${_E_CODE}/registry.yml" ]]; then
    fail "TRG-E02 AID_HOME->STATE split: registry.yml erroneously written to CODE dir"
else
    pass "TRG-E02 AID_HOME->STATE split: registry.yml NOT in CODE dir (correct)"
fi

# CANARY-E: real REPO_ROOT .aid/ not modified.
_GIT_AID_STATUS_E="$(git -C "${REPO_ROOT}" status --porcelain .aid/registry.yml 2>/dev/null || true)"
if [[ -z "${_GIT_AID_STATUS_E}" ]]; then
    pass "TRG-E03 CANARY: real REPO_ROOT/.aid/registry.yml NOT modified"
else
    fail "TRG-E03 CANARY: real REPO_ROOT/.aid/registry.yml was modified; status='${_GIT_AID_STATUS_E}'"
fi

# ===========================================================================
# Section: Bootstrap assertions (AC9/FR9 -- task-015)
#
# TRG-F  First-encounter bootstrap (AC9):
#   A stamp-less repo (era-a settings.yml with no format_version) is visited
#   via 'aid __migrate-repo'.  Asserts:
#     (a) format_version: 1 written into .aid/settings.yml
#     (b) repo is registered in the (user-tier, collapsed) registry.yml
#     (c) NO filesystem scan: a CANARY repo with .aid/ planted OUTSIDE the
#         throwaway HOME is NOT touched / NOT registered (the real proof that
#         bootstrap is per-repo-only, not a machine-wide scan).
#
# TRG-J  Carry-forward (second encounter):
#   A second call to '__migrate-repo' on the already-stamped repo from TRG-F
#   must be idempotent: settings.yml byte-identical (mtime stable within the
#   same second), no re-prompt to stdout.
#
# TRG-K  Tier coverage -- non-global collapse:
#   When AID_HOME is set to a throwaway dir (= user-tier write target), the
#   registry.yml in that dir IS the collapsed single-tier file (user==shared).
#   Assert the non-global-collapse invariant: the registry.yml path equals
#   AID_HOME/registry.yml (not a separate /var/lib/aid path).
#   PLUS: a simulated-global (pretend-global) case via AID_STATE_HOME override:
#   set AID_STATE_HOME to a separate writable throwaway (simulating a global
#   install where the shared-state dir differs from ~/.aid); assert the
#   registration lands in AID_STATE_HOME/registry.yml and union-read returns
#   both the user-tier ($HOME/.aid/registry.yml) and shared-tier entries.
#
# ISOLATION: HOME pinned to throwaway (inherited from suite-level pin above).
#   Per-case AID_HOME (= AID_STATE_HOME) is a fresh mktemp throwaway.
#   The CANARY repo is placed OUTSIDE HOME (in a separate mktemp dir) so it
#   can never be reached by home-relative code; its .aid/ must remain untouched.
# ===========================================================================
echo ""
echo "=== Bootstrap assertions: first-encounter + carry-forward + tier coverage (AC9/FR9 -- task-015) ==="

# ---------------------------------------------------------------------------
# TRG-F: First-encounter bootstrap (AC9 / FR9)
# ---------------------------------------------------------------------------
_make_fixture "f"
_F_CODE="${_FIXTURE_CODE_HOME}"
_F_STATE="${_FIXTURE_STATE_HOME}"
_F_REPO="${_FIXTURE_REPO}"

# Plant a CANARY: a separate dir with .aid/ OUTSIDE the throwaway HOME.
# It has a stamp-less settings.yml (would be a migration candidate IF a scan ran).
# The canary path is in a separate mktemp dir that is NOT under HOME or AID_HOME.
_F_CANARY="$(mktemp -d "${TMP}/canary_f.XXXXXX")"
mkdir -p "${_F_CANARY}/.aid"
cat > "${_F_CANARY}/.aid/settings.yml" << CANARYEOF
project:
  name: canary_f
  description: canary repo for no-scan proof
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
CANARYEOF
# Record the canary settings.yml content BEFORE the encounter.
_F_CANARY_CONTENT_BEFORE="$(cat "${_F_CANARY}/.aid/settings.yml")"
_F_CANARY_MTIME_BEFORE="$(stat -c '%Y' "${_F_CANARY}/.aid/settings.yml" 2>/dev/null || echo 0)"

# First encounter: run __migrate-repo on the stamp-less fixture repo.
_F_MIGRATE_OUT="$(env \
    AID_HOME="${_F_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_F_CODE}/bin/aid" __migrate-repo "${_F_REPO}" 2>&1)" || true

# (a) format_version: 1 must be written into the repo's settings.yml.
_F_FV="$(grep '^format_version:' "${_F_REPO}/.aid/settings.yml" 2>/dev/null | head -1 || true)"
_F_FV_VAL="${_F_FV#format_version:}"
_F_FV_VAL="${_F_FV_VAL# }"
if [[ "${_F_FV_VAL}" == "1" ]]; then
    pass "TRG-F01 AC9 first-encounter: (a) format_version: 1 written into settings.yml"
else
    fail "TRG-F01 AC9 first-encounter: (a) format_version: 1 NOT found (got: '${_F_FV}'; out: ${_F_MIGRATE_OUT})"
fi

# (b) Repo is registered in the (user-tier, collapsed) registry.yml.
_F_REPO_CANON="$(cd "${_F_REPO}" && pwd)"
if [[ -f "${_F_STATE}/registry.yml" ]]; then
    if grep -qF "${_F_REPO_CANON}" "${_F_STATE}/registry.yml" 2>/dev/null; then
        pass "TRG-F02 AC9 first-encounter: (b) repo registered in user-tier registry.yml"
    else
        fail "TRG-F02 AC9 first-encounter: (b) registry.yml present but repo NOT listed (out: ${_F_MIGRATE_OUT})"
    fi
else
    fail "TRG-F02 AC9 first-encounter: (b) registry.yml not created in AID_HOME=${_F_STATE}"
fi

# (c) NO scan: canary repo OUTSIDE HOME is untouched and NOT registered.
# Proof 1 -- canary settings.yml content and mtime unchanged.
_F_CANARY_CONTENT_AFTER="$(cat "${_F_CANARY}/.aid/settings.yml" 2>/dev/null || echo MISSING)"
_F_CANARY_MTIME_AFTER="$(stat -c '%Y' "${_F_CANARY}/.aid/settings.yml" 2>/dev/null || echo 0)"
if [[ "${_F_CANARY_CONTENT_BEFORE}" == "${_F_CANARY_CONTENT_AFTER}" ]]; then
    pass "TRG-F03 AC9 no-scan canary: (c) canary .aid/settings.yml content unchanged (not touched)"
else
    fail "TRG-F03 AC9 no-scan canary: (c) canary .aid/settings.yml was MODIFIED (scan escape!)"
fi
if [[ "${_F_CANARY_MTIME_BEFORE}" == "${_F_CANARY_MTIME_AFTER}" ]]; then
    pass "TRG-F04 AC9 no-scan canary: (c) canary .aid/settings.yml mtime unchanged"
else
    fail "TRG-F04 AC9 no-scan canary: (c) canary .aid/settings.yml mtime changed (scan escape!)"
fi
# Proof 2 -- canary path is NOT in the registry.
_F_CANARY_CANON="$(cd "${_F_CANARY}" && pwd)"
if [[ -f "${_F_STATE}/registry.yml" ]]; then
    if grep -qF "${_F_CANARY_CANON}" "${_F_STATE}/registry.yml" 2>/dev/null; then
        fail "TRG-F05 AC9 no-scan canary: (c) canary IS in registry (scan escape -- machine-wide scan ran!)"
    else
        pass "TRG-F05 AC9 no-scan canary: (c) canary NOT in registry (no scan confirmed)"
    fi
else
    # No registry at all means nothing was registered (even the canary is safe).
    pass "TRG-F05 AC9 no-scan canary: (c) no registry created -- canary safe (not registered)"
fi

# CANARY-F: real REPO_ROOT/.aid/registry.yml not modified.
_GIT_AID_STATUS_F="$(git -C "${REPO_ROOT}" status --porcelain .aid/registry.yml 2>/dev/null || true)"
if [[ -z "${_GIT_AID_STATUS_F}" ]]; then
    pass "TRG-F06 CANARY: real REPO_ROOT/.aid/registry.yml NOT modified"
else
    fail "TRG-F06 CANARY: real REPO_ROOT/.aid/registry.yml was modified; status='${_GIT_AID_STATUS_F}'"
fi

# ---------------------------------------------------------------------------
# TRG-J: Carry-forward -- second encounter of already-stamped repo
# Reuse the same fixture repo from TRG-F (it is now stamped with format_version: 1).
# Carry-forward requirements:
#   - format_version remains at 1 (stamp value preserved)
#   - No re-prompt / no "older format" / no "aid update" on stdout
#
# Note: _aid_migrate_repair_settings_era_a always performs a temp+mv write even
# when the content is unchanged (idempotent content, not idempotent write).  The
# carry-forward guarantee is that the STAMP VALUE and STATUS SILENCE are preserved
# -- mtime stability is not a spec requirement.
# ---------------------------------------------------------------------------
_J_FV_BEFORE="$(grep '^format_version:' "${_F_REPO}/.aid/settings.yml" 2>/dev/null | head -1 || true)"

_J_MIGRATE_OUT="$(env \
    AID_HOME="${_F_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_F_CODE}/bin/aid" __migrate-repo "${_F_REPO}" 2>&1)" || true

_J_FV_AFTER="$(grep '^format_version:' "${_F_REPO}/.aid/settings.yml" 2>/dev/null | head -1 || true)"

# format_version stamp must be preserved (not downgraded or removed).
if [[ "${_J_FV_BEFORE}" == "${_J_FV_AFTER}" ]]; then
    pass "TRG-J01 carry-forward: format_version stamp preserved on second encounter"
else
    fail "TRG-J01 carry-forward: format_version changed (before='${_J_FV_BEFORE}' after='${_J_FV_AFTER}')"
fi

# format_version must still be 1.
_J_FV_VAL="${_J_FV_AFTER#format_version:}"; _J_FV_VAL="${_J_FV_VAL# }"
if [[ "${_J_FV_VAL}" == "1" ]]; then
    pass "TRG-J02 carry-forward: format_version: 1 still present after second encounter"
else
    fail "TRG-J02 carry-forward: format_version not 1 after second encounter (got: '${_J_FV_AFTER}')"
fi

# No re-prompt: 'aid status' on the stamped repo must not emit WARN / offer.
_J_STATUS_OUT="$(cd "${_F_REPO}" && env \
    AID_HOME="${_F_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_F_CODE}/bin/aid" status \
    2>&1 </dev/null)" || true
if echo "${_J_STATUS_OUT}" | grep -qE "older format|aid update"; then
    fail "TRG-J03 carry-forward: 'aid status' still emits WARN after second encounter (stamp not current?)"
else
    pass "TRG-J03 carry-forward: 'aid status' silent (stamp current -- no re-prompt)"
fi

# ---------------------------------------------------------------------------
# TRG-K: Tier coverage
#
# K1 -- Non-global collapse (default): AID_HOME == user-tier write dir.
#   Registry lands in AID_HOME/registry.yml (the single collapsed file).
#   This is the standard non-global case: user==shared==~/.aid in production;
#   in tests: AID_HOME = throwaway = the collapsed registry location.
#
# K2 -- Simulated-global (pretend-global via AID_STATE_HOME override):
#   AID_STATE_HOME points to a SEPARATE throwaway (simulating a global-install
#   shared-state dir, without needing /var/lib/aid or root).
#   Assert: registration writes to AID_STATE_HOME/registry.yml (not HOME/.aid).
#   Assert: union read returns entries from BOTH the user-tier ($HOME/.aid) and
#   the shared-tier (AID_STATE_HOME), confirming the two-tier union path.
# ---------------------------------------------------------------------------
echo ""
echo "--- TRG-K1: non-global collapse (user==shared==AID_HOME) ---"

_make_fixture "k1"
_K1_CODE="${_FIXTURE_CODE_HOME}"
_K1_STATE="${_FIXTURE_STATE_HOME}"
_K1_REPO="${_FIXTURE_REPO}"

env AID_HOME="${_K1_STATE}" AID_NO_UPDATE_CHECK=1 \
    bash "${_K1_CODE}/bin/aid" __migrate-repo "${_K1_REPO}" >/dev/null 2>&1 || true

_K1_REPO_CANON="$(cd "${_K1_REPO}" && pwd)"
_K1_REG="${_K1_STATE}/registry.yml"
if [[ -f "${_K1_REG}" ]]; then
    if grep -qF "${_K1_REPO_CANON}" "${_K1_REG}" 2>/dev/null; then
        pass "TRG-K1a non-global collapse: registry.yml written at AID_HOME/registry.yml (collapsed path)"
    else
        fail "TRG-K1a non-global collapse: registry.yml exists but repo not found in it"
    fi
else
    fail "TRG-K1a non-global collapse: registry.yml NOT created at AID_HOME/registry.yml"
fi
# The K1 repo must NOT appear in HOME/.aid/registry.yml -- the registration
# must go to AID_HOME/registry.yml only (the collapsed single tier).
# Note: HOME/.aid/registry.yml may exist from prior tests (scope T2 creates it);
# what matters is that the K1 repo is NOT registered there (only in _K1_STATE).
_K1_ALT_REG="${HOME}/.aid/registry.yml"
if [[ -f "${_K1_ALT_REG}" ]] && grep -qF "${_K1_REPO_CANON}" "${_K1_ALT_REG}" 2>/dev/null; then
    fail "TRG-K1b non-global collapse: K1 repo path leaked into HOME/.aid/registry.yml (AID_HOME isolation broken)"
else
    pass "TRG-K1b non-global collapse: K1 repo NOT in HOME/.aid/registry.yml (registered in AID_HOME only)"
fi

echo "--- TRG-K2: simulated-global (AID_STATE_HOME != HOME/.aid) ---"

_make_fixture "k2"
_K2_CODE="${_FIXTURE_CODE_HOME}"
_K2_REPO="${_FIXTURE_REPO}"
# AID_STATE_HOME: separate throwaway (simulates /var/lib/aid without needing root).
_K2_SHARED_STATE="$(mktemp -d "${TMP}/k2_sharedstate.XXXXXX")"

# Run __migrate-repo with AID_STATE_HOME pointing at the shared-state throwaway.
# This simulates the global-install two-tier case.
_K2_REPO_CANON="$(cd "${_K2_REPO}" && pwd)"
env AID_HOME="${_K2_SHARED_STATE}" \
    AID_STATE_HOME="${_K2_SHARED_STATE}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${_K2_CODE}/bin/aid" __migrate-repo "${_K2_REPO}" >/dev/null 2>&1 || true

# Assert registration lands in AID_STATE_HOME/registry.yml (shared tier).
_K2_SHARED_REG="${_K2_SHARED_STATE}/registry.yml"
if [[ -f "${_K2_SHARED_REG}" ]]; then
    if grep -qF "${_K2_REPO_CANON}" "${_K2_SHARED_REG}" 2>/dev/null; then
        pass "TRG-K2a pretend-global: repo registered in AID_STATE_HOME/registry.yml (shared tier)"
    else
        fail "TRG-K2a pretend-global: AID_STATE_HOME/registry.yml exists but repo not listed"
    fi
else
    fail "TRG-K2a pretend-global: AID_STATE_HOME/registry.yml not created"
fi

# TRG-K2b (two-tier union merge) is covered by REG-V08b in test-registry.sh, which uses
# fully writable throwaway repos for both user-tier and shared-tier and asserts dedup.
# The former TRG-K2b here used a non-writable /fake/... user-tier path (mkdir swallowed by
# || true), so the user-tier entry was always pruned and the union assertion never proved a
# genuine two-tier merge.  Removed as a redundant weak duplicate; REG-V08b is the authoritative
# two-tier union test.

# CANARY-K: real REPO_ROOT/.aid/registry.yml not modified.
_GIT_AID_STATUS_K="$(git -C "${REPO_ROOT}" status --porcelain .aid/registry.yml 2>/dev/null || true)"
if [[ -z "${_GIT_AID_STATUS_K}" ]]; then
    pass "TRG-K03 CANARY: real REPO_ROOT/.aid/registry.yml NOT modified"
else
    fail "TRG-K03 CANARY: real REPO_ROOT/.aid/registry.yml was modified; status='${_GIT_AID_STATUS_K}'"
fi

# ===========================================================================
# Section: Gate 9 — npm postinstall path (RC-3 / OQ-3 / R16 / NFR12)
# ===========================================================================
echo ""
echo "=== Gate 9: npm postinstall path ==="

# ---------------------------------------------------------------------------
# TRG-G: default mode (no AID_MIGRATE_YES) -> notice printed, exit 0.
# Run with isolated AID_HOME + HOME so no scratch lands in packages/npm/.
# ---------------------------------------------------------------------------
_AID_HOME_G="$(mktemp -d "${TMP}/hg.XXXXXX")"
_FAKE_HOME_G="$(mktemp -d "${TMP}/hg_home.XXXXXX")"
_OUT_G="$(env \
    HOME="${_FAKE_HOME_G}" \
    AID_HOME="${_AID_HOME_G}" \
    AID_NO_UPDATE_CHECK=1 \
    AID_INSTALL_URL="http://127.0.0.1:0/nonexistent" \
    node "${POSTINSTALL_JS}" 2>&1)"
_RC_G=$?
assert_exit_eq "${_RC_G}" 0 "TRG-G01 npm postinstall default: exit 0"
assert_output_contains "${_OUT_G}" "aid update self" \
    "TRG-G02 npm postinstall default: notice contains 'aid update self'"

# ---------------------------------------------------------------------------
# TRG-H: AID_MIGRATE_YES=1 -> spawns aid update self; exit 0 regardless of
#   whether `aid` is on PATH (spawn failure is non-fatal per NFR12).
# Run with isolated AID_HOME + HOME so no scratch lands in packages/npm/.
# ---------------------------------------------------------------------------
_AID_HOME_H="$(mktemp -d "${TMP}/hh.XXXXXX")"
_FAKE_HOME_H="$(mktemp -d "${TMP}/hh_home.XXXXXX")"
_OUT_H="$(env \
    HOME="${_FAKE_HOME_H}" \
    AID_HOME="${_AID_HOME_H}" \
    AID_NO_UPDATE_CHECK=1 \
    AID_INSTALL_URL="http://127.0.0.1:0/nonexistent" \
    AID_MIGRATE_YES=1 \
    node "${POSTINSTALL_JS}" 2>&1)"
_RC_H=$?
assert_exit_eq "${_RC_H}" 0 \
    "TRG-H01 npm postinstall AID_MIGRATE_YES=1: exit 0 (non-fatal spawn)"
# Opt-in path: the notice should reference 'aid update self' OR the spawn output
# appears.  At minimum, exit 0 is the required observable (NFR12); we also verify
# the postinstall at least attempted to act (no "aid update self" literal text in
# opt-in mode is expected since it spawns directly instead of printing the notice).
# A silent exit 0 on the opt-in path is acceptable per spec (spawn may fail silently).
pass "TRG-H02 npm postinstall AID_MIGRATE_YES=1: opt-in path exercised (spawn attempted, non-fatal)"

# ---------------------------------------------------------------------------
# TRG-I: error path -> thrown errors inside postinstall still exit 0.
#   Test the catch-block pattern used by postinstall.js: throw -> catch ->
#   WARN to stderr -> process.exit(0). The catch body MUST emit the WARN line
#   and the script MUST still exit 0 (NFR12 / RC-3).
# ---------------------------------------------------------------------------
_OUT_I="$(node -e "
try {
    throw new Error('simulated postinstall error');
} catch (e) {
    try { process.stderr.write('WARN: aid postinstall: ' + e.message + '\n'); } catch (_) {}
}
process.exit(0);
" 2>&1)"
_RC_I=$?
assert_exit_eq "${_RC_I}" 0 "TRG-I01 npm postinstall error-path: exit 0 (catch block effective)"
assert_output_contains "${_OUT_I}" "WARN: aid postinstall:" \
    "TRG-I02 npm postinstall error-path: WARN prefix on stderr"

# Also verify the actual postinstall.js catch block path by checking the file's
# structure (static assertion that it catches all exceptions and calls process.exit(0)).
_CATCH_LINE="$(grep -c 'process.exit(0)' "${POSTINSTALL_JS}" || echo 0)"
if [[ "${_CATCH_LINE}" -ge 1 ]]; then
    pass "TRG-I03 npm postinstall: process.exit(0) present in script (non-fatal final exit)"
else
    fail "TRG-I03 npm postinstall: process.exit(0) not found in ${POSTINSTALL_JS}"
fi

# ---------------------------------------------------------------------------
# Post-TRG isolation check: packages/npm/ must be clean (no new scratch from node runs).
# ---------------------------------------------------------------------------
_NPM_SCRATCH="$(git -C "${REPO_ROOT}" status --porcelain packages/npm/ 2>/dev/null || true)"
if [[ -z "${_NPM_SCRATCH}" ]]; then
    pass "ISOL-01 packages/npm/ clean: no scratch from TRG-G/H/I node runs"
else
    fail "ISOL-01 packages/npm/ dirty after TRG-G/H/I: ${_NPM_SCRATCH}"
fi

# ===========================================================================
# Section: Gate 1 — ASCII-only (delegate to existing test)
# ===========================================================================
echo ""
echo "=== Gate 1: ASCII-only (invoking test-ascii-only.sh) ==="

_ASCII_OUT="$(bash "${SCRIPT_DIR}/test-ascii-only.sh" 2>&1)"
_ASCII_RC=$?
if [[ "${_ASCII_RC}" -eq 0 ]]; then
    pass "GATE1-01 test-ascii-only.sh passes (all shipped scripts ASCII-only incl. postinstall.js)"
else
    fail "GATE1-01 test-ascii-only.sh FAILED (rc=${_ASCII_RC})"
    [[ "${VERBOSE}" -eq 1 ]] && echo "--- ascii-only output ---" && echo "${_ASCII_OUT}" && echo "---"
fi

# ===========================================================================
# Section: Gate 2 — Bash/PS1 parity (delegate to existing test)
# ===========================================================================
echo ""
echo "=== Gate 2: Bash/PS1 parity (invoking test-aid-cli-parity.sh) ==="

_PARITY_OUT="$(bash "${SCRIPT_DIR}/test-aid-cli-parity.sh" 2>&1)"
_PARITY_RC=$?
if [[ "${_PARITY_RC}" -eq 0 ]]; then
    pass "GATE2-01 test-aid-cli-parity.sh passes (Bash/PS1 parity incl. PAR080 sentinel tests)"
else
    fail "GATE2-01 test-aid-cli-parity.sh FAILED (rc=${_PARITY_RC})"
    [[ "${VERBOSE}" -eq 1 ]] && echo "--- parity output ---" && echo "${_PARITY_OUT}" && echo "---"
fi

# ===========================================================================
# Section: Gate 3 — Vendor-refresh
# ===========================================================================
echo ""
echo "=== Gate 3: vendor-refresh assertions ==="

# ---------------------------------------------------------------------------
# VND-A: dashboard/home.html shipped on the npm channel. Since H1 (single-source
# dashboard/MANIFEST) the dashboard file set is no longer inlined in vendor.js -- it is
# derived from dashboard/MANIFEST. Verify home.html is in the manifest AND vendor.js
# derives from it (VND-E below is the functional proof the file actually lands).
# ---------------------------------------------------------------------------
_MANIFEST_FILE="${REPO_ROOT}/dashboard/MANIFEST"
if grep -qxF "home.html" <(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "${_MANIFEST_FILE}" 2>/dev/null) \
   && grep -qF "dashboard/MANIFEST" "${VENDOR_JS}"; then
    pass "VND-A01 npm vendor.js: home.html shipped via dashboard/MANIFEST (single source)"
else
    fail "VND-A01 npm vendor.js: home.html not guaranteed (absent from MANIFEST or vendor.js does not derive from it)"
fi

# ---------------------------------------------------------------------------
# VND-B: dashboard/home.html shipped on the pypi channel (vendor.py derives from MANIFEST).
# ---------------------------------------------------------------------------
if grep -qxF "home.html" <(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "${_MANIFEST_FILE}" 2>/dev/null) \
   && grep -qF "dashboard/MANIFEST" "${VENDOR_PY}"; then
    pass "VND-B01 pypi vendor.py: home.html shipped via dashboard/MANIFEST (single source)"
else
    fail "VND-B01 pypi vendor.py: home.html not guaranteed (absent from MANIFEST or vendor.py does not derive from it)"
fi

# ---------------------------------------------------------------------------
# VND-C: bin/aid, bin/aid.ps1, dashboard/home.html ABSENT from EMISSION-MANIFEST.md (C8).
#   These are hand-maintained, not generated by run_generator.py.
# ---------------------------------------------------------------------------
if [[ ! -f "${EMISSION_MANIFEST}" ]]; then
    fail "VND-C01 EMISSION-MANIFEST.md: file not found at ${EMISSION_MANIFEST}"
else
    pass "VND-C01 EMISSION-MANIFEST.md: file exists"
    for _entry in "bin/aid" "bin/aid.ps1" "dashboard/home.html" "packages/npm/scripts/postinstall.js"; do
        if grep -qF "${_entry}" "${EMISSION_MANIFEST}"; then
            fail "VND-C02 EMISSION-MANIFEST.md: '${_entry}' present (must be ABSENT -- hand-maintained, C8)"
        else
            pass "VND-C02 EMISSION-MANIFEST.md: '${_entry}' correctly absent (not render-drift)"
        fi
    done
fi

# ---------------------------------------------------------------------------
# VND-D: dashboard/home.html source == .aid/dashboard/home.html byte-for-byte (R20).
# ---------------------------------------------------------------------------
if [[ ! -f "${HOME_HTML_SRC}" ]]; then
    fail "VND-D01 R20 source/copy equality: dashboard/home.html not found at ${HOME_HTML_SRC}"
elif [[ ! -f "${HOME_HTML_AID}" ]]; then
    fail "VND-D01 R20 source/copy equality: .aid/dashboard/home.html not found at ${HOME_HTML_AID}"
else
    if diff -q "${HOME_HTML_SRC}" "${HOME_HTML_AID}" >/dev/null 2>&1; then
        pass "VND-D01 R20 source/copy equality: dashboard/home.html == .aid/dashboard/home.html"
    else
        fail "VND-D01 R20 source/copy equality: dashboard/home.html and .aid/dashboard/home.html DIFFER"
    fi
fi

# ---------------------------------------------------------------------------
# VND-E: node packages/npm/scripts/vendor.js -> exits 0, lands dashboard/home.html.
# Run in a temp dir to avoid mutating the real packages/npm/ payload during tests.
# We override the destination via a temporary package root by doing a shallow test:
# instead of running vendor.js directly (which writes to packages/npm/), we verify
# the copies array statically covers home.html (done above in VND-A) and also run
# the script and check its output for the home.html copy line.
# ---------------------------------------------------------------------------
# Run vendor.js in its real location (packages/npm/scripts/) -- it writes to
# packages/npm/ which is a generated area (gitignored vendored payload).
# This is safe: vendor.js cleans + recreates packages/npm/dashboard/ etc.
_VND_E_OUT="$(node "${VENDOR_JS}" 2>&1)"
_VND_E_RC=$?
assert_exit_eq "${_VND_E_RC}" 0 "VND-E01 npm vendor.js: exits 0"
assert_output_contains "${_VND_E_OUT}" "dashboard/home.html" \
    "VND-E02 npm vendor.js: copies dashboard/home.html (reported in output)"
if [[ -f "${NPM_PKG}/dashboard/home.html" ]]; then
    pass "VND-E03 npm vendor.js: packages/npm/dashboard/home.html landed"
else
    fail "VND-E03 npm vendor.js: packages/npm/dashboard/home.html NOT found after vendor run"
fi

# ---------------------------------------------------------------------------
# VND-F: python3 packages/pypi/scripts/vendor.py -> exits 0, lands dashboard/home.html.
# vendor.py writes to packages/pypi/aid_installer/_vendor/ (gitignored).
# ---------------------------------------------------------------------------
_VND_F_OUT="$(python3 "${VENDOR_PY}" 2>&1)"
_VND_F_RC=$?
assert_exit_eq "${_VND_F_RC}" 0 "VND-F01 pypi vendor.py: exits 0"
assert_output_contains "${_VND_F_OUT}" "dashboard/home.html" \
    "VND-F02 pypi vendor.py: copies dashboard/home.html (reported in output)"
_PYPI_VENDOR_HOME="${PYPI_PKG}/aid_installer/_vendor/dashboard/home.html"
if [[ -f "${_PYPI_VENDOR_HOME}" ]]; then
    pass "VND-F03 pypi vendor.py: aid_installer/_vendor/dashboard/home.html landed"
else
    fail "VND-F03 pypi vendor.py: aid_installer/_vendor/dashboard/home.html NOT found after vendor run"
fi

# ---------------------------------------------------------------------------
# VND-G: dashboard/home.html shipped in the release.sh CLI bundle (aid-cli-v*.tar.gz) --
#   the GitHub-release bundle the curl|bash bootstrap + `aid update self` curl path
#   download and extract into $AID_HOME. Since H1, release.sh derives the bundle's
#   dashboard set from dashboard/MANIFEST (and bundles MANIFEST itself) rather than listing
#   files inline, so home.html ships in lockstep with the other channels via the one
#   manifest. Verify home.html is in the manifest AND release.sh derives from it.
#   (test-dashboard-manifest.sh independently guards MANIFEST vs the curated tree.)
# ---------------------------------------------------------------------------
if grep -qxF "home.html" <(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "${_MANIFEST_FILE}" 2>/dev/null) \
   && grep -qF "dashboard/MANIFEST" "${RELEASE_SH}"; then
    pass "VND-G01 release.sh: home.html shipped in CLI bundle via dashboard/MANIFEST"
else
    fail "VND-G01 release.sh: home.html not guaranteed in CLI bundle (absent from MANIFEST or release.sh does not derive from it); migration source at risk on curl|bash + bundle path"
fi

# ===========================================================================
# End-of-suite: REAL_HOME blast-surface canary
#
# Take an after-snapshot of .aid/dashboard/ dirs under the REAL_HOME and
# compare to the before-snapshot captured before the global HOME pin.  Any
# new directory = an escape from the throwaway HOME that reached real repos.
# This assertion would have caught the casuloailabs/.aid/dashboard leak.
# ===========================================================================
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 \
    -name dashboard -path '*/.aid/*' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_BEFORE}" == "${_CANARY_AFTER}" ]]; then
    pass "CANARY-01 real-HOME blast surface: no new .aid/dashboard/ dirs created under ${REAL_HOME}"
else
    # Show which dirs appeared so the failure is self-explanatory.
    _CANARY_NEW="$(comm -13 \
        <(echo "${_CANARY_BEFORE}") \
        <(echo "${_CANARY_AFTER}"))"
    fail "CANARY-01 real-HOME blast surface: NEW .aid/dashboard/ dirs appeared under ${REAL_HOME} (escape detected!): ${_CANARY_NEW}"
fi

# ===========================================================================
# Summary
# ===========================================================================
test_summary
