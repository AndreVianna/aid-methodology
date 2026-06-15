#!/usr/bin/env bash
# test-pypi-installer.sh - Task 038/039: Tests for the PyPI channel (aid-installer).
#
# Tests the packages/pypi/aid_installer/__main__.py shim: argv passthrough,
# exit-code relay, platform selection, missing runtime, AID_INSTALL_CHANNEL
# injection, pip/pipx smoke, and version parity.
#
# SKIP (exit 0) when `python3` is absent.
#
# Usage:
#   bash test-pypi-installer.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PKG_DIR="${REPO_ROOT}/packages/pypi"
SHIM="${PKG_DIR}/aid_installer/__main__.py"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"

# Gate: skip when python3 is absent.
if ! command -v python3 >/dev/null 2>&1; then
    echo "SKIP: python3 not found on PATH -- skipping PyPI installer suite."
    exit 0
fi

# Verify shim exists.
[[ -f "$SHIM" ]] || { echo "ERROR: packages/pypi/aid_installer/__main__.py not found at $SHIM" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Run vendor.py to populate _vendor/ for tests that need the real CLI.
VENDOR_DIR="${PKG_DIR}/aid_installer/_vendor"
if [[ ! -f "${VENDOR_DIR}/bin/aid" ]]; then
    python3 "${PKG_DIR}/scripts/vendor.py" >/dev/null 2>&1 || {
        echo "ERROR: vendor.py failed; cannot continue" >&2
        exit 1
    }
fi

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

# ---------------------------------------------------------------------------
# For stub tests we create a temporary Python shim + stub bin/aid tree so that
# the real packages/pypi/aid_installer/_vendor/bin/aid is never invoked by stubs.
# ---------------------------------------------------------------------------

STUB_PKG_DIR=""
STUB_INFO_DIR=""

make_stub_pkg() {
    # make_stub_pkg <exit_code>
    # Creates a temporary shim+stub tree. Sets STUB_PKG_DIR and STUB_INFO_DIR.
    local exit_code="${1:-0}"
    STUB_PKG_DIR="$(mktemp -d "${TMP}/stub-pkg.XXXXXX")"
    STUB_INFO_DIR="$(mktemp -d "${TMP}/stub-info.XXXXXX")"
    mkdir -p "${STUB_PKG_DIR}/_vendor/bin"

    # Write a stub bin/aid that records argv + AID_INSTALL_CHANNEL.
    cat > "${STUB_PKG_DIR}/_vendor/bin/aid" <<STUBEOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "${STUB_INFO_DIR}/last-argv"
printf '%s\n' "\${AID_INSTALL_CHANNEL:-}" > "${STUB_INFO_DIR}/last-channel"
exit ${exit_code}
STUBEOF
    chmod +x "${STUB_PKG_DIR}/_vendor/bin/aid"

    # Write an __init__.py (package marker).
    printf '' > "${STUB_PKG_DIR}/__init__.py"

    # Write a __main__.py that uses STUB_PKG_DIR as vendor root.
    cat > "${STUB_PKG_DIR}/__main__.py" <<PYSHIMEOF
#!/usr/bin/env python3
from __future__ import annotations
import os
import shutil
import subprocess
import sys
from pathlib import Path

vendor_root = Path("${STUB_PKG_DIR}/_vendor")
os.environ["AID_INSTALL_CHANNEL"] = "pypi"
user_args = sys.argv[1:]

if os.name == "nt":
    ps1 = vendor_root / "bin" / "aid.ps1"
    fixed_flags = ["-NoLogo", "-NonInteractive", "-File", str(ps1)]
    pwsh = shutil.which("pwsh")
    if pwsh is not None:
        proc = subprocess.run([pwsh] + fixed_flags + user_args, check=False)
        sys.exit(proc.returncode)
    powershell = shutil.which("powershell")
    if powershell is not None:
        proc = subprocess.run([powershell] + fixed_flags + user_args, check=False)
        sys.exit(proc.returncode)
    sys.stderr.write("ERROR: aid: neither pwsh nor powershell found on PATH. Install PowerShell to use the aid CLI.\n")
    sys.exit(1)
else:
    bash = shutil.which("bash")
    if bash is None:
        sys.stderr.write("ERROR: aid: bash not found on PATH. Install bash to use the aid CLI.\n")
        sys.exit(1)
    aid_sh = vendor_root / "bin" / "aid"
    proc = subprocess.run([bash, str(aid_sh)] + user_args, check=False)
    sys.exit(proc.returncode)
PYSHIMEOF
}

# ---------------------------------------------------------------------------
echo "=== PW01: argv passthrough 1:1 to stub bin/aid ==="
# ---------------------------------------------------------------------------

make_stub_pkg 0
OUT=$(python3 "${STUB_PKG_DIR}/__main__.py" status 2>&1); RC=$?
assert_exit_eq "$RC" 0 "PW01-01 shim with stub -- exit 0"
if [[ -f "${STUB_INFO_DIR}/last-argv" ]]; then
    _argv_content="$(cat "${STUB_INFO_DIR}/last-argv")"
    assert_eq "$_argv_content" "status" "PW01-02 argv 'status' passed to stub"
else
    fail "PW01-02 argv file not written by stub"
fi

# Each subcommand reaches the stub unchanged.
_subcommands=("status" "add codex" "add codex,cursor" "update" "update self"
              "remove" "--from-bundle X" "--force" "--verbose")
_pw01_idx=3
for _subcmd_str in "${_subcommands[@]}"; do
    make_stub_pkg 0
    # Word-split intentional: each element is space-separated tokens.
    # shellcheck disable=SC2086
    OUT=$(python3 "${STUB_PKG_DIR}/__main__.py" $_subcmd_str 2>&1); RC=$?
    assert_exit_eq "$RC" 0 "PW01-${_pw01_idx} subcommand '${_subcmd_str}' -- exit 0"
    _pw01_idx=$(( _pw01_idx + 1 ))
done

# Comma-lists reach the stub verbatim.
make_stub_pkg 0
OUT=$(python3 "${STUB_PKG_DIR}/__main__.py" add "codex,cursor" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "PW01-${_pw01_idx} comma-list arg -- exit 0"
if [[ -f "${STUB_INFO_DIR}/last-argv" ]]; then
    _argv_content="$(cat "${STUB_INFO_DIR}/last-argv")"
    assert_output_contains "$_argv_content" "codex,cursor" "PW01-$((${_pw01_idx}+1)) comma-list preserved verbatim"
else
    fail "PW01-$((${_pw01_idx}+1)) argv file not written for comma-list"
fi

# ---------------------------------------------------------------------------
echo "=== PW02: Windows-path selection (source-level check) ==="
# ---------------------------------------------------------------------------

# On this (Unix) runner we verify the shim source contains the correct path-selection logic.
if grep -q "os.name.*nt\|nt.*os.name" "${SHIM}"; then
    pass "PW02-01 shim source contains Windows (os.name == 'nt') branch"
else
    fail "PW02-01 shim source missing os.name == 'nt' Windows branch"
fi
if grep -q "shutil.which.*pwsh" "${SHIM}"; then
    pass "PW02-02 shim source tries pwsh first on Windows"
else
    fail "PW02-02 shim source missing pwsh lookup"
fi
if grep -q "shutil.which.*powershell" "${SHIM}"; then
    pass "PW02-03 shim source falls back to powershell on Windows"
else
    fail "PW02-03 shim source missing powershell fallback"
fi
if grep -q "\-NoLogo.*\-NonInteractive.*\-File\|\-File.*\-NoLogo" "${SHIM}"; then
    pass "PW02-04 shim source passes -NoLogo -NonInteractive -File to pwsh"
else
    fail "PW02-04 shim source missing fixed flags for pwsh"
fi

# ---------------------------------------------------------------------------
echo "=== PW03: exit-code relay 0..7 ==="
# ---------------------------------------------------------------------------

for _ec in 0 1 2 3 4 5 6 7; do
    make_stub_pkg $_ec
    OUT=$(python3 "${STUB_PKG_DIR}/__main__.py" status 2>&1); RC=$?
    assert_exit_eq "$RC" $_ec "PW03 exit code relay: $_ec"
done

# ---------------------------------------------------------------------------
echo "=== PW04: missing runtime -> exit 1 + message ==="
# ---------------------------------------------------------------------------

# Verify the error messages exist in the production shim source.
if grep -q "bash not found on PATH" "${SHIM}"; then
    pass "PW04-01 shim source contains bash-not-found error message"
else
    fail "PW04-01 shim source missing bash-not-found error message"
fi
if grep -q "neither pwsh nor powershell found on PATH" "${SHIM}"; then
    pass "PW04-02 shim source contains pwsh-not-found error message"
else
    fail "PW04-02 shim source missing pwsh-not-found error message"
fi

# ---------------------------------------------------------------------------
echo "=== PW05: _vendor/ byte-identical to the 17 repo-root sources (drift gate) ==="
# ---------------------------------------------------------------------------

_6_PAIRS=(
    "bin/aid:bin/aid"
    "bin/aid.ps1:bin/aid.ps1"
    "bin/aid.cmd:bin/aid.cmd"
    "lib/aid-install-core.sh:lib/aid-install-core.sh"
    "lib/AidInstallCore.psm1:lib/AidInstallCore.psm1"
    "VERSION:VERSION"
    "dashboard/index.html:dashboard/index.html"
    "dashboard/reader/__init__.py:dashboard/reader/__init__.py"
    "dashboard/reader/reader.py:dashboard/reader/reader.py"
    "dashboard/reader/models.py:dashboard/reader/models.py"
    "dashboard/reader/parsers.py:dashboard/reader/parsers.py"
    "dashboard/reader/derivation.py:dashboard/reader/derivation.py"
    "dashboard/reader/locator.py:dashboard/reader/locator.py"
    "dashboard/server/server.py:dashboard/server/server.py"
    "dashboard/server/server.mjs:dashboard/server/server.mjs"
    "dashboard/server/reader.mjs:dashboard/server/reader.mjs"
    "dashboard/server/__init__.py:dashboard/server/__init__.py"
)
for _pair in "${_6_PAIRS[@]}"; do
    _src_rel="${_pair%%:*}"
    _dst_rel="${_pair##*:}"
    _src="${REPO_ROOT}/${_src_rel}"
    _dst="${VENDOR_DIR}/${_dst_rel}"
    if [[ ! -f "$_dst" ]]; then
        fail "PW05 _vendor/${_dst_rel} -- not found (vendor.py not run?)"
    elif cmp -s "$_src" "$_dst"; then
        pass "PW05 _vendor/${_dst_rel} byte-identical to repo source"
    else
        fail "PW05 _vendor/${_dst_rel} differs from ${_src_rel} (drift!)"
    fi
done

# ---------------------------------------------------------------------------
echo "=== PW06: pip wheel + pipx install smoke ==="
# ---------------------------------------------------------------------------

# Gate: only run when python -m build and pipx are available (or in CI).
_PW06_SKIP=0
if ! python3 -c "import build" 2>/dev/null; then
    if ! python3 -m pip show build >/dev/null 2>&1; then
        _PW06_SKIP=1
    fi
fi
# Also try installing build if we're in CI.
if [[ "$_PW06_SKIP" -eq 1 && -n "${CI:-}" ]]; then
    python3 -m pip install --quiet build >/dev/null 2>&1 && _PW06_SKIP=0 || true
fi

if [[ "$_PW06_SKIP" -eq 1 ]]; then
    echo "SKIP (PW06): python build module not available -- skipping wheel build smoke."
else
    # Build the wheel.
    PW06_DIST_DIR="$(mktemp -d "${TMP}/pw06-dist.XXXXXX")"
    if python3 -m build --wheel --outdir "${PW06_DIST_DIR}" "${PKG_DIR}" \
               > "${TMP}/pw06-build-out.txt" 2>&1; then
        pass "PW06-01 python -m build --wheel succeeded"

        PW06_WHL="$(ls "${PW06_DIST_DIR}"/*.whl 2>/dev/null | head -1)"
        if [[ -z "$PW06_WHL" ]]; then
            fail "PW06-02 no .whl produced by build"
        else
            pass "PW06-02 .whl produced: $(basename "${PW06_WHL}")"

            # Try pipx install if available (or installable).
            _PIPX_CMD=""
            if command -v pipx >/dev/null 2>&1; then
                _PIPX_CMD="pipx"
            elif python3 -m pipx --version >/dev/null 2>&1; then
                _PIPX_CMD="python3 -m pipx"
            elif [[ -n "${CI:-}" ]]; then
                python3 -m pip install --quiet pipx >/dev/null 2>&1 && _PIPX_CMD="python3 -m pipx" || true
            fi

            if [[ -z "$_PIPX_CMD" ]]; then
                echo "SKIP (PW06-03..09): pipx not available -- skipping install smoke."
            else
                PW06_PIPX_HOME="$(mktemp -d "${TMP}/pw06-pipx-home.XXXXXX")"
                PW06_BIN_DIR="${PW06_PIPX_HOME}/bin"
                mkdir -p "${PW06_BIN_DIR}"

                # Wire a minimal AID_HOME from repo source for the smoke tests.
                PW06_AID_HOME="$(mktemp -d "${TMP}/pw06-aidh.XXXXXX")"
                mkdir -p "${PW06_AID_HOME}/bin" "${PW06_AID_HOME}/lib"
                cp "${BIN_AID}" "${PW06_AID_HOME}/bin/aid"
                chmod +x "${PW06_AID_HOME}/bin/aid"
                cp "${LIB_CORE}" "${PW06_AID_HOME}/lib/aid-install-core.sh"
                printf '%s\n' "${VERSION}" > "${PW06_AID_HOME}/VERSION"

                # Install via pipx (isolated venv).
                if PIPX_HOME="${PW06_PIPX_HOME}" PIPX_BIN_DIR="${PW06_BIN_DIR}" \
                   ${_PIPX_CMD} install "${PW06_WHL}" \
                   > "${TMP}/pw06-pipx-out.txt" 2>&1; then
                    pass "PW06-03 pipx install succeeded"

                    # Find the installed 'aid' script.
                    PW06_AID_BIN="${PW06_BIN_DIR}/aid"
                    if [[ ! -x "$PW06_AID_BIN" ]]; then
                        # Fallback: search for it.
                        PW06_AID_BIN="$(find "${PW06_PIPX_HOME}" -name "aid" -type f 2>/dev/null | head -1)"
                    fi

                    if [[ -z "$PW06_AID_BIN" ]]; then
                        fail "PW06-04 installed aid not found under ${PW06_PIPX_HOME}"
                        [[ "$VERBOSE" -eq 1 ]] && find "${PW06_PIPX_HOME}" | head -30
                    else
                        pass "PW06-04 installed aid found: ${PW06_AID_BIN}"

                        # Smoke: aid status in empty dir -> exit 7.
                        PW06_EMPTY="$(mktemp -d "${TMP}/pw06-empty.XXXXXX")"
                        PW06_STATUS_OUT=$(AID_HOME="${PW06_AID_HOME}" AID_NO_UPDATE_CHECK=1 \
                            "${PW06_AID_BIN}" status --target "${PW06_EMPTY}" 2>&1)
                        PW06_STATUS_RC=$?
                        assert_exit_eq "$PW06_STATUS_RC" 7 \
                            "PW06-05 installed aid status empty dir -> exit 7"
                        assert_output_contains "$PW06_STATUS_OUT" "No AID install found" \
                            "PW06-06 installed aid status message"

                        # Build codex fixture tarball.
                        mkdir -p "${TMP}/fixtures"
                        PW06_FIXTURE=""
                        if [[ -d "${PROFILES_DIR}/codex" ]]; then
                            _FL="$(mktemp "${TMP}/filelist-codex.XXXXXX")"
                            while IFS= read -r f; do
                                _fname="$(basename "$f")"
                                [[ "$_fname" == "README.md" ]] && continue
                                [[ "$_fname" == "emission-manifest.jsonl" ]] && continue
                                _rel="${f#${PROFILES_DIR}/codex/}"
                                printf './%s\n' "$_rel"
                            done < <(find "${PROFILES_DIR}/codex" -type f | sort) > "$_FL"
                            PW06_FIXTURE="${TMP}/fixtures/aid-codex-v${VERSION}.tar.gz"
                            (cd "${PROFILES_DIR}/codex" && \
                             tar -czf "${PW06_FIXTURE}" --no-recursion -T "$_FL") || PW06_FIXTURE=""
                            rm -f "$_FL"
                        fi

                        if [[ -n "$PW06_FIXTURE" ]]; then
                            # Smoke: aid add codex --from-bundle.
                            PW06_TARGET="$(mktemp -d "${TMP}/pw06-target.XXXXXX")"
                            PW06_ADD_OUT=$(AID_HOME="${PW06_AID_HOME}" AID_NO_UPDATE_CHECK=1 \
                                "${PW06_AID_BIN}" add codex \
                                --from-bundle "${PW06_FIXTURE}" \
                                --target "${PW06_TARGET}" 2>&1)
                            PW06_ADD_RC=$?
                            assert_exit_eq "$PW06_ADD_RC" 0 \
                                "PW06-07 installed aid add codex --from-bundle -> exit 0"
                            assert_dir_exists "${PW06_TARGET}/.codex" \
                                "PW06-08 installed aid add: .codex/ created"
                            assert_file_exists "${PW06_TARGET}/AGENTS.md" \
                                "PW06-09 installed aid add: AGENTS.md created"
                        else
                            echo "SKIP (PW06-07..09): codex profile not found -- skipping add smoke."
                        fi
                    fi
                else
                    fail "PW06-03 pipx install failed"
                    [[ "$VERBOSE" -eq 1 ]] && cat "${TMP}/pw06-pipx-out.txt"
                fi
            fi
        fi
    else
        fail "PW06-01 python -m build --wheel failed"
        [[ "$VERBOSE" -eq 1 ]] && cat "${TMP}/pw06-build-out.txt"
    fi
fi

# ---------------------------------------------------------------------------
echo "=== PW07: AID_INSTALL_CHANNEL=pypi -> update self is channel-aware (pipx upgrade), not curl ==="
# ---------------------------------------------------------------------------

# Use the real packages/pypi/aid_installer/__main__.py shim (not the stub shim) pointing at
# the vendored bin/aid, which sees AID_INSTALL_CHANNEL=pypi set by the shim.
PW07_HOME="$(mktemp -d "${TMP}/pw07-home.XXXXXX")"
mkdir -p "${PW07_HOME}/bin" "${PW07_HOME}/lib"
cp "${BIN_AID}" "${PW07_HOME}/bin/aid"
chmod +x "${PW07_HOME}/bin/aid"
cp "${LIB_CORE}" "${PW07_HOME}/lib/aid-install-core.sh"
printf '%s\n' "${VERSION}" > "${PW07_HOME}/VERSION"

# The shim at __main__.py calls _vendor/bin/aid (vendored copy), which is the
# real bin/aid; the shim sets AID_INSTALL_CHANNEL=pypi. Use --dry-run so the
# channel routing is asserted deterministically without touching the real pipx
# ('update self' is now self-contained, not a printed hint).
PW07_OUT=$(AID_HOME="${PW07_HOME}" AID_NO_UPDATE_CHECK=1 \
           python3 "${SHIM}" update self --dry-run 2>&1); PW07_RC=$?
assert_exit_eq "$PW07_RC" 0 "PW07-01 shim update self --dry-run with channel=pypi -> exit 0"
assert_output_contains "$PW07_OUT" "pipx upgrade aid-installer" \
    "PW07-02 update self routes to the pipx upgrade command"
assert_output_not_contains "$PW07_OUT" "curl -fsSL" \
    "PW07-03 update self does NOT take the curl path on the pypi channel"

# AID_HOME must not be mutated by a dry-run.
assert_dir_exists "${PW07_HOME}" "PW07-04 AID_HOME not removed (dry-run mutates nothing)"

# ---------------------------------------------------------------------------
echo "=== PW08: version parity (pyproject.toml == repo VERSION == vendored _vendor/VERSION) ==="
# ---------------------------------------------------------------------------

_pyproject_version="$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        sys.exit(1)
with open('${PKG_DIR}/pyproject.toml', 'rb') as f:
    data = tomllib.load(f)
sys.stdout.write(data['project']['version'])
" 2>/dev/null)" || _pyproject_version="PARSE_ERROR"

if [[ "$_pyproject_version" == "PARSE_ERROR" ]]; then
    # Fallback: grep the version from pyproject.toml.
    _pyproject_version="$(grep '^version' "${PKG_DIR}/pyproject.toml" | head -1 | \
        sed 's/.*=.*"\([^"]*\)".*/\1/' | tr -d '[:space:]')"
fi

assert_eq "$_pyproject_version" "$VERSION" "PW08-01 pyproject.toml version == repo VERSION"

if [[ -f "${VENDOR_DIR}/VERSION" ]]; then
    _vendored_version="$(tr -d '[:space:]' < "${VENDOR_DIR}/VERSION")"
    assert_eq "$_vendored_version" "$VERSION" "PW08-02 vendored _vendor/VERSION == repo VERSION"
else
    fail "PW08-02 vendored _vendor/VERSION file not found (run vendor.py first)"
fi

# ---------------------------------------------------------------------------
echo "=== PW-ASCII: ASCII-only check on shim and vendor script ==="
# ---------------------------------------------------------------------------

if grep -qP '[^\x00-\x7F]' "${SHIM}"; then
    _offenders=$(grep -oP '[^\x00-\x7F]' "${SHIM}" | python3 -c "
import sys
chars = {}
for line in sys.stdin:
    c = line.rstrip('\n')
    if c:
        chars[c] = chars.get(c, 0) + 1
parts = ['U+{:04X}({}x)'.format(ord(c), n) for c, n in sorted(chars.items(), key=lambda x: ord(x[0]))]
print(' '.join(parts))
" 2>/dev/null || echo "(non-ASCII bytes found)")
    fail "ASCII-only: packages/pypi/aid_installer/__main__.py -- non-ASCII bytes found: $_offenders"
else
    pass "ASCII-only: packages/pypi/aid_installer/__main__.py"
fi

if grep -qP '[^\x00-\x7F]' "${PKG_DIR}/scripts/vendor.py"; then
    fail "ASCII-only: packages/pypi/scripts/vendor.py -- non-ASCII bytes found"
else
    pass "ASCII-only: packages/pypi/scripts/vendor.py"
fi

test_summary
