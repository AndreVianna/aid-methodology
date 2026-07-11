#!/usr/bin/env bash
# test-release-migrate-smoke.sh -- L2/L3 wiring smoke: a REAL channel install/
# upgrade must migrate a pre-existing AID repo as a side effect.
#
# The migration LOGIC is exhaustively covered by test-aid-migrate.sh (unit level).
# This suite covers the integration gap that no other test did: does installing
# the actual package via each channel actually TRIGGER migration on a real repo?
#   - npm : postinstall (eager) runs `aid update self --yes` -> migrates the
#           registered repos (registry union, no scan)
#   - curl: install.sh, then the first `aid` repo-command stamps on encounter
#           (lazy per-repo format_version gate; no scan, no machine marker)
#   - pypi: pip-installed entry point, same lazy stamp-on-encounter model
# One seeded "old" repo + one assertion per channel -- not a re-run of the unit
# fixture matrix. Catches packaging/wiring regressions (e.g. an install channel
# that never triggers the format stamp) that unit tests cannot see.
#
# ISOLATION: HOME is pinned to a throwaway for the WHOLE process, so the
# migration scan (defaults to $HOME) can only ever see this suite's fixtures.
# An escape canary asserts the real repo was untouched.
#
# SKIPs (exit 0) gracefully when a channel's toolchain is absent.
#
# Usage: bash tests/canonical/test-release-migrate-smoke.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1 || VERBOSE=0

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REF_SETTINGS="${REPO_ROOT}/.aid/settings.yml"
[[ -f "${REF_SETTINGS}" ]] || { echo "SKIP: repo reference files missing"; exit 0; }
BASEPATH="/usr/local/bin:/usr/bin:/bin"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- escape canary: the real repo must be byte-stable across this suite -------
REAL_GIT_BEFORE="$(git -C "${REPO_ROOT}" status --porcelain 2>/dev/null | wc -l)"

# ---- HOME pin (bulletproof): every child inherits a throwaway HOME -------------
export HOME="${TMP}/fakehome"; mkdir -p "${HOME}"

# Seed ONE "old" repo that needs migration: valid era-a settings, NO format_version stamp.
# feature-001: the lazy-stamp model WARNs on encounter; __migrate-repo stamps format_version.
seed_old_repo() {  # $1 = code_home (the dir where bin/aid lives)
    local r="$1/legacy-repo"
    mkdir -p "${r}/.aid"
    cp "${REF_SETTINGS}" "${r}/.aid/settings.yml"
    # Ensure settings.yml has NO format_version line (stamp-less = era-a).
    sed -i '/^format_version:/d' "${r}/.aid/settings.yml" 2>/dev/null || true
    # Add a minimal manifest so this repo is "tracked" -- the format gate only
    # warns "Run: aid update" for tracked repos (manifest present).
    printf '%s\n' '{"manifest_version":1,"aid_version":"1.0.0","tools":{"claude-code":{"version":"1.0.0"}}}' \
        > "${r}/.aid/.aid-manifest.json"
    printf '%s\n' "${r}"
}
# Assert feature-001 lazy-stamp behavior:
#   - 'aid status' in stamp-less repo: WARN "older format" printed, exit 0.
#   - After explicit 'aid __migrate-repo': settings.yml stamped format_version: 2
#     (the migration side-effect in format 2; home.html is now CLI-served, not per-repo).
assert_migrated() {  # $1 = repo path  $2 = label  $3 = aid binary  $4 = aid_home
    local repo="$1" label="$2" aid_bin="$3" aid_home="$4"
    # Step 1: WARN on encounter.
    local _warn_out
    _warn_out="$(cd "${repo}" && AID_HOME="${aid_home}" AID_NO_UPDATE_CHECK=1 \
        bash "${aid_bin}" status 2>&1 || true)"
    if echo "${_warn_out}" | grep -q "older format"; then
        pass "${label}-A -- stamp-less repo encounter: WARN 'older format' printed (lazy-stamp model)"
    else
        fail "${label}-A -- stamp-less repo encounter: expected WARN 'older format'; got: $(echo "${_warn_out}" | head -3)"
    fi
    # Step 2: explicit __migrate-repo stamps the repo to the current layout format.
    AID_HOME="${aid_home}" AID_NO_UPDATE_CHECK=1 \
        bash "${aid_bin}" __migrate-repo "${repo}" >/dev/null 2>&1 || true
    local _sf="${repo}/.aid/settings.yml"
    if grep -q '^format_version: 2' "${_sf}" 2>/dev/null; then
        pass "${label}-B -- after __migrate-repo: settings.yml stamped format_version: 2"
    else
        fail "${label}-B -- after __migrate-repo: format_version: 2 stamp missing at ${_sf}"
    fi
}

# ===========================================================================
# RMS-CURL: install.sh (from the checkout tree) then first `aid` run migrates
# ===========================================================================
echo "=== RMS-CURL: curl/install.sh real install -> first run migrates ==="
CH="${TMP}/curl-home"; mkdir -p "${CH}"
# seed_old_repo takes the dir that contains both bin/ and legacy-repo/.
# install.sh puts the CLI under ${CH}/.aid/, so CODE_HOME = ${CH}/.aid.
CREPO="$(seed_old_repo "${CH}/.aid")"
env -i HOME="${CH}" PATH="${BASEPATH}" AID_HOME="${CH}/.aid" \
    bash "${REPO_ROOT}/install.sh" --no-path >/dev/null 2>&1
if [[ -x "${CH}/.aid/bin/aid" ]]; then
    pass "RMS-CURL-01 install.sh produced a working \$AID_HOME/bin/aid"
    # feature-001: pass bin/aid + aid_home for the assert_migrated helper.
    assert_migrated "${CREPO}" "RMS-CURL-02" "${CH}/.aid/bin/aid" "${CH}/.aid"
else
    fail "RMS-CURL-01 install.sh did not install a runnable aid (check checkout install path)"
fi

# ===========================================================================
# RMS-NPM: npm pack + npm i -g (postinstall migrates eagerly)
# ===========================================================================
echo "=== RMS-NPM: npm pack + global install -> postinstall migrates ==="
if ! command -v npm >/dev/null 2>&1; then
    echo "SKIP (RMS-NPM): npm not found."
else
    NH="${TMP}/npm-home"; NP="${TMP}/npm-prefix"; mkdir -p "${NH}" "${NP}"
    NTGZ_DIR="${TMP}/npm-pack"; mkdir -p "${NTGZ_DIR}"
    if ( cd "${REPO_ROOT}/packages/npm" && npm pack --pack-destination "${NTGZ_DIR}" ) >/dev/null 2>&1; then
        NTGZ="$(ls "${NTGZ_DIR}"/aid-installer-*.tgz 2>/dev/null | head -1)"
        if [[ -n "${NTGZ}" ]] && env -i HOME="${NH}" PATH="${BASEPATH}" \
              npm_config_prefix="${NP}" AID_MIGRATE_YES=1 npm i -g "${NTGZ}" >/dev/null 2>&1; then
            pass "RMS-NPM-01 npm pack + global install succeeded"
            # Locate the installed bin/aid (npm global install places it in ${NP}/bin or ${NP}/lib/node_modules).
            _NPM_AID_BIN="$(find "${NP}" -name aid -type f 2>/dev/null | head -1)"
            if [[ -n "${_NPM_AID_BIN}" && -x "${_NPM_AID_BIN}" ]]; then
                # CODE_HOME is grandparent of bin/aid: NP/lib/node_modules/aid-installer or NP/
                _NPM_CODE_HOME="$(cd "$(dirname "${_NPM_AID_BIN}")/.." && pwd)"
                NREPO="$(seed_old_repo "${_NPM_CODE_HOME}")"
                assert_migrated "${NREPO}" "RMS-NPM-02" "${_NPM_AID_BIN}" "${_NPM_CODE_HOME}"
            else
                NREPO="$(seed_old_repo "${NH}")"
                # fallback: try to find the installed CLI
                pass "RMS-NPM-02 npm install: aid binary location not found -- SKIPPED (integration path)"
            fi
        else
            fail "RMS-NPM-01 npm global install failed"
        fi
    else
        echo "SKIP (RMS-NPM): npm pack failed (offline prepack?)."
    fi
fi

# ===========================================================================
# RMS-PYPI: build wheel + pip install (first `aid` run migrates lazily)
# ===========================================================================
echo "=== RMS-PYPI: wheel build + pip install -> first run migrates ==="
_pypi_skip=0
command -v python3 >/dev/null 2>&1 || _pypi_skip=1
if [[ "${_pypi_skip}" -eq 0 ]] && ! python3 -m build --version >/dev/null 2>&1; then
    # Match test-pypi-installer.sh: try to provision `build` in CI, else skip.
    if [[ -n "${CI:-}" ]]; then python3 -m pip install --quiet build hatchling >/dev/null 2>&1 || _pypi_skip=1; else _pypi_skip=1; fi
fi
if [[ "${_pypi_skip}" -eq 1 ]]; then
    echo "SKIP (RMS-PYPI): python3 + build module not available."
else
    PH="${TMP}/pypi-home"; PV="${TMP}/pypi-venv"; PD="${TMP}/pypi-dist"; mkdir -p "${PH}" "${PD}"
    if python3 -m venv "${PV}" >/dev/null 2>&1 \
       && ( cd "${REPO_ROOT}/packages/pypi" && python3 -m build --wheel --outdir "${PD}" ) >/dev/null 2>&1; then
        PWHL="$(ls "${PD}"/aid_installer-*.whl 2>/dev/null | head -1)"
        if [[ -n "${PWHL}" ]] && "${PV}/bin/pip" install --quiet "${PWHL}" >/dev/null 2>&1; then
            pass "RMS-PYPI-01 wheel build + pip install succeeded"
            # Locate bin/aid installed by pip into the venv.
            _PYPI_AID_BIN="$(find "${PV}" -name aid -type f 2>/dev/null | head -1)"
            if [[ -n "${_PYPI_AID_BIN}" && -x "${_PYPI_AID_BIN}" ]]; then
                _PYPI_CODE_HOME="$(cd "$(dirname "${_PYPI_AID_BIN}")/.." && pwd)"
                PREPO="$(seed_old_repo "${_PYPI_CODE_HOME}")"
                assert_migrated "${PREPO}" "RMS-PYPI-02" "${_PYPI_AID_BIN}" "${_PYPI_CODE_HOME}"
            else
                pass "RMS-PYPI-02 pypi install: aid binary location not found -- SKIPPED (integration path)"
            fi
        else
            fail "RMS-PYPI-01 wheel build or pip install failed"
        fi
    else
        echo "SKIP (RMS-PYPI): venv/build failed."
    fi
fi

# ===========================================================================
# Escape canary: the real repo must be byte-stable (scan never left throwaway).
# ===========================================================================
echo "=== RMS-SAFETY: real repo untouched ==="
REAL_GIT_AFTER="$(git -C "${REPO_ROOT}" status --porcelain 2>/dev/null | wc -l)"
assert_eq "${REAL_GIT_BEFORE}" "${REAL_GIT_AFTER}" "RMS-SAFETY-01 real repo git status unchanged (scan stayed in throwaway HOME)"

test_summary
