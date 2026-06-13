#!/usr/bin/env bash
# test-npm-installer.sh - Task 033/034: Tests for the npm channel (aid-installer).
#
# Tests the packages/npm/bin/aid.js shim: argv passthrough, exit-code relay,
# platform selection, missing runtime, AID_INSTALL_CHANNEL injection,
# pack/install smoke, and version parity.
#
# SKIP (exit 0) when `node` is absent.
#
# Usage:
#   bash test-npm-installer.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PKG_DIR="${REPO_ROOT}/packages/npm"
SHIM="${PKG_DIR}/bin/aid.js"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"

# Gate: skip when node is absent.
if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not found on PATH -- skipping npm installer suite."
    exit 0
fi

# Verify shim exists.
[[ -f "$SHIM" ]] || { echo "ERROR: packages/npm/bin/aid.js not found at $SHIM" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'cleanup_test' EXIT

# Ensure vendor.js has been run so packages/npm/bin/aid exists.
if [[ ! -f "${PKG_DIR}/bin/aid" ]]; then
    node "${PKG_DIR}/scripts/vendor.js" >/dev/null 2>&1 || {
        echo "ERROR: vendor.js failed; cannot continue" >&2
        exit 1
    }
fi

# ---------------------------------------------------------------------------
# The shim always calls `bash <pkgRoot>/bin/aid`.
# For stub tests we create a TEMPORARY wrapper package tree in $TMP that has
# a fake aid.js pointing to our stub bin/aid, so the real packages/npm/bin/aid
# is never modified.
# ---------------------------------------------------------------------------

PKG_STUB_DIR=""

make_stub_pkg() {
    # make_stub_pkg <exit_code>
    # Creates a temporary shim+stub tree. Sets PKG_STUB_DIR and STUB_INFO_DIR.
    local exit_code="${1:-0}"
    PKG_STUB_DIR="$(mktemp -d "${TMP}/stub-pkg.XXXXXX")"
    STUB_INFO_DIR="$(mktemp -d "${TMP}/stub-info.XXXXXX")"
    mkdir -p "${PKG_STUB_DIR}/bin"

    # Write a stub bin/aid that records argv + AID_INSTALL_CHANNEL.
    cat > "${PKG_STUB_DIR}/bin/aid" <<STUBEOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "${STUB_INFO_DIR}/last-argv"
printf '%s\n' "\${AID_INSTALL_CHANNEL:-}" > "${STUB_INFO_DIR}/last-channel"
exit ${exit_code}
STUBEOF
    chmod +x "${PKG_STUB_DIR}/bin/aid"

    # Write a shim that points to this stub package root.
    # We copy the shim source and patch the __dirname resolution by setting pkgRoot.
    cat > "${PKG_STUB_DIR}/bin/aid.js" <<'SHIMEOF'
#!/usr/bin/env node
'use strict';
var spawnSync = require('child_process').spawnSync;
var path      = require('path');
var process   = require('process');

// For stub tests, the package root is one level above this file.
var pkgRoot = path.join(__dirname, '..');

var env = Object.assign({}, process.env, { AID_INSTALL_CHANNEL: 'npm' });
var userArgs = process.argv.slice(2);
var res;

if (process.platform === 'win32') {
    var ps1 = path.join(pkgRoot, 'bin', 'aid.ps1');
    var fixedFlagsPwsh = ['-NoLogo', '-NonInteractive', '-File', ps1];
    res = spawnSync('pwsh', fixedFlagsPwsh.concat(userArgs), { stdio: 'inherit', env: env });
    if (res.error && res.error.code === 'ENOENT') {
        res = spawnSync('powershell', fixedFlagsPwsh.concat(userArgs), { stdio: 'inherit', env: env });
        if (res.error && res.error.code === 'ENOENT') {
            process.stderr.write('ERROR: aid: neither pwsh nor powershell found on PATH. Install PowerShell to use the aid CLI.\n');
            process.exit(1);
        }
    }
} else {
    var aidSh = path.join(pkgRoot, 'bin', 'aid');
    res = spawnSync('bash', [aidSh].concat(userArgs), { stdio: 'inherit', env: env });
    if (res.error && res.error.code === 'ENOENT') {
        process.stderr.write('ERROR: aid: bash not found on PATH. Install bash to use the aid CLI.\n');
        process.exit(1);
    }
}

if (res.status == null) {
    process.exit(res.signal ? 1 : 0);
} else {
    process.exit(res.status);
}
SHIMEOF
    chmod +x "${PKG_STUB_DIR}/bin/aid.js"
}

# Cleanup: nothing special since all stub dirs are under $TMP.
cleanup_test() {
    rm -rf "$TMP"
}

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

echo "=== NM01: argv passthrough 1:1 to stub bin/aid ==="

make_stub_pkg 0
OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" status 2>&1); RC=$?
assert_exit_eq "$RC" 0 "NM01-01 shim with stub -- exit 0"
if [[ -f "${STUB_INFO_DIR}/last-argv" ]]; then
    _argv_content="$(cat "${STUB_INFO_DIR}/last-argv")"
    assert_eq "$_argv_content" "status" "NM01-02 argv 'status' passed to stub"
else
    fail "NM01-02 argv file not written by stub"
fi

echo "=== NM02: space/metachar arg safety ==="

make_stub_pkg 0
OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" add "name with spaces" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "NM02-01 space arg -- exit 0"
if [[ -f "${STUB_INFO_DIR}/last-argv" ]]; then
    _argv_content="$(cat "${STUB_INFO_DIR}/last-argv")"
    assert_output_contains "$_argv_content" "name with spaces" "NM02-02 space arg preserved verbatim"
else
    fail "NM02-02 argv file not written"
fi

make_stub_pkg 0
OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" add "arg;with;semis&&more|pipe" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "NM02-03 shell metachar arg -- exit 0"
if [[ -f "${STUB_INFO_DIR}/last-argv" ]]; then
    _argv_content="$(cat "${STUB_INFO_DIR}/last-argv")"
    assert_output_contains "$_argv_content" "arg;with;semis&&more|pipe" "NM02-04 metachar arg preserved"
else
    fail "NM02-04 argv file not written"
fi

echo "=== NM03: each subcommand reaches the stub unchanged ==="

# Build subcommand list: each element is "subcmd[ arg...]"
_subcommands=("status" "add codex" "add codex,cursor" "update" "update self"
              "remove" "--from-bundle X" "--force" "--verbose")
_nm03_idx=1
for _subcmd_str in "${_subcommands[@]}"; do
    make_stub_pkg 0
    # Word-split intentional here: each element of _subcommands is space-separated tokens.
    # shellcheck disable=SC2086
    OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" $_subcmd_str 2>&1); RC=$?
    assert_exit_eq "$RC" 0 "NM03-${_nm03_idx} subcommand '${_subcmd_str}' -- exit 0"
    _nm03_idx=$(( _nm03_idx + 1 ))
done

echo "=== NM04: exit-code relay 0..7 ==="

for _ec in 0 1 2 3 4 5 6 7; do
    make_stub_pkg $_ec
    OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" status 2>&1); RC=$?
    assert_exit_eq "$RC" $_ec "NM04 exit code relay: $_ec"
done

echo "=== NM05: platform select -- Unix path + AID_INSTALL_CHANNEL reaches child ==="

# NM05-01: on the current (non-Windows) platform, bash path is taken.
make_stub_pkg 0
OUT=$(node "${PKG_STUB_DIR}/bin/aid.js" version 2>&1); RC=$?
assert_exit_eq "$RC" 0 "NM05-01 Unix platform: bash path invoked -- exit 0"

# NM05-02: AID_INSTALL_CHANNEL=npm is injected by the shim and reaches the child.
if [[ -f "${STUB_INFO_DIR}/last-channel" ]]; then
    _channel="$(cat "${STUB_INFO_DIR}/last-channel")"
    assert_eq "$_channel" "npm" "NM05-02 AID_INSTALL_CHANNEL=npm reaches child env"
else
    fail "NM05-02 channel file not written"
fi

echo "=== NM06: missing runtime -> exit 1 + message ==="

# Verify the error messages exist in the production shim source.
if grep -q "bash not found on PATH" "${SHIM}"; then
    pass "NM06-01 shim source contains bash-not-found error message"
else
    fail "NM06-01 shim source missing bash-not-found error message"
fi
if grep -q "neither pwsh nor powershell found on PATH" "${SHIM}"; then
    pass "NM06-02 shim source contains pwsh-not-found error message"
else
    fail "NM06-02 shim source missing pwsh-not-found error message"
fi

echo "=== NM07: AID_INSTALL_CHANNEL=npm -> update self prints npm advice + exit 0 + no re-bootstrap ==="

# Use the real packages/npm/bin/aid.js shim (not the stub shim) pointing at
# the vendored bin/aid, which sees AID_INSTALL_CHANNEL=npm set by the shim.
NM07_HOME="$(mktemp -d "${TMP}/nm07-home.XXXXXX")"
mkdir -p "${NM07_HOME}/bin" "${NM07_HOME}/lib"
cp "${BIN_AID}" "${NM07_HOME}/bin/aid"
chmod +x "${NM07_HOME}/bin/aid"
cp "${LIB_CORE}" "${NM07_HOME}/lib/aid-install-core.sh"
printf '%s\n' "${VERSION}" > "${NM07_HOME}/VERSION"

# The shim at packages/npm/bin/aid.js calls packages/npm/bin/aid (vendored copy),
# which is the real bin/aid. We pass AID_HOME so the real bin/aid finds its lib.
# The shim sets AID_INSTALL_CHANNEL=npm.
NM07_OUT=$(AID_HOME="${NM07_HOME}" AID_NO_UPDATE_CHECK=1 \
           node "${SHIM}" update self 2>&1); NM07_RC=$?
assert_exit_eq "$NM07_RC" 0 "NM07-01 shim update self with channel=npm -> exit 0"
assert_output_contains "$NM07_OUT" "npm i -g aid-installer@latest" \
    "NM07-02 update self prints npm install command"
assert_output_not_contains "$NM07_OUT" "Updating the aid CLI..." \
    "NM07-03 update self does NOT re-bootstrap (no curl path)"

# AID_HOME must not be mutated by re-bootstrap.
assert_dir_exists "${NM07_HOME}" "NM07-04 AID_HOME not removed (no re-bootstrap)"

echo "=== NM08: npm pack --dry-run lists the 17 vendored files + bin/aid.js ==="

NM08_PACK_OUT=$(cd "${PKG_DIR}" && npm pack --dry-run 2>&1) || true

for _expect in "bin/aid.js" "bin/aid" "bin/aid.ps1" "bin/aid.cmd" \
               "lib/aid-install-core.sh" "lib/AidInstallCore.psm1" "VERSION" \
               "dashboard/index.html" \
               "dashboard/reader/__init__.py" \
               "dashboard/reader/reader.py" \
               "dashboard/reader/models.py" \
               "dashboard/reader/parsers.py" \
               "dashboard/reader/derivation.py" \
               "dashboard/reader/locator.py" \
               "dashboard/server/server.py" \
               "dashboard/server/server.mjs" \
               "dashboard/server/reader.mjs" \
               "dashboard/server/__init__.py"; do
    if echo "$NM08_PACK_OUT" | grep -qF "$_expect"; then
        pass "NM08 pack --dry-run includes $_expect"
    else
        fail "NM08 pack --dry-run missing: $_expect"
        [[ "$VERBOSE" -eq 1 ]] && echo "---PACK OUTPUT---" && echo "$NM08_PACK_OUT" && echo "---END---"
    fi
done

# Verify tests/ and .aid/ are excluded.
if echo "$NM08_PACK_OUT" | grep -qF "tests/"; then
    fail "NM08 pack --dry-run should NOT include tests/ entries"
else
    pass "NM08 pack --dry-run excludes tests/"
fi

echo "=== NM09: version parity (package.json == repo VERSION == vendored VERSION) ==="

_pkg_version="$(node -e "process.stdout.write(require('${PKG_DIR}/package.json').version)")"
assert_eq "$_pkg_version" "$VERSION" "NM09-01 package.json version == repo VERSION"

if [[ -f "${PKG_DIR}/VERSION" ]]; then
    _vendored_version="$(tr -d '[:space:]' < "${PKG_DIR}/VERSION")"
    assert_eq "$_vendored_version" "$VERSION" "NM09-02 vendored VERSION == repo VERSION"
else
    fail "NM09-02 vendored VERSION file not found (run vendor.js first)"
fi

echo "=== NM10: npm pack + global install smoke ==="

# Build fixture tarball for codex.
mkdir -p "${TMP}/fixtures"
build_fixture_tarball() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${TMP}/fixtures/aid-${tool}-v${VERSION}.tar.gz"
    [[ -d "$profile_dir" ]] || { echo "WARN: profile dir not found: $profile_dir"; return 1; }
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
    (cd "${profile_dir}" && tar -czf "${tarball}" --no-recursion -T "${filelist}") || return 1
    rm -f "$filelist"
}

if ! build_fixture_tarball codex; then
    fail "NM10 could not build codex fixture tarball"
    test_summary
    exit $?
fi

# npm pack the package.
NM10_PACK_DIR="$(mktemp -d "${TMP}/nm10-pack.XXXXXX")"
if ! (cd "${PKG_DIR}" && npm pack --pack-destination "${NM10_PACK_DIR}") > "${TMP}/nm10-pack-out.txt" 2>&1; then
    fail "NM10-01 npm pack failed"
    [[ "$VERBOSE" -eq 1 ]] && cat "${TMP}/nm10-pack-out.txt"
else
    pass "NM10-01 npm pack succeeded"

    NM10_TGZ="$(ls "${NM10_PACK_DIR}"/*.tgz 2>/dev/null | head -1)"
    if [[ -z "$NM10_TGZ" ]]; then
        fail "NM10-02 no .tgz produced by npm pack"
    else
        pass "NM10-02 .tgz produced: $(basename "${NM10_TGZ}")"

        # Global install into a temp prefix.
        NM10_PREFIX="$(mktemp -d "${TMP}/nm10-prefix.XXXXXX")"
        if npm install -g "${NM10_TGZ}" --prefix "${NM10_PREFIX}" \
               > "${TMP}/nm10-install-out.txt" 2>&1; then
            pass "NM10-03 npm install -g succeeded"

            # Find the installed aid entry point (Node.js wraps bin in a shell script on Linux).
            # On Linux npm global install creates <prefix>/bin/aid (a shell wrapper that calls aid.js).
            NM10_AID=""
            if [[ -x "${NM10_PREFIX}/bin/aid" ]]; then
                NM10_AID="${NM10_PREFIX}/bin/aid"
            else
                # Fallback: find the .js directly.
                NM10_AID="$(find "${NM10_PREFIX}" -name "aid.js" \
                    ! -path "*/scripts/*" 2>/dev/null | head -1)"
            fi

            if [[ -z "$NM10_AID" ]]; then
                fail "NM10-04 installed aid binary not found under ${NM10_PREFIX}"
                [[ "$VERBOSE" -eq 1 ]] && find "${NM10_PREFIX}" | head -30
            else
                pass "NM10-04 installed aid binary found: ${NM10_AID}"

                # Wire a minimal AID_HOME from repo source for the smoke tests.
                NM10_AID_HOME="$(mktemp -d "${TMP}/nm10-aidh.XXXXXX")"
                mkdir -p "${NM10_AID_HOME}/bin" "${NM10_AID_HOME}/lib"
                cp "${BIN_AID}" "${NM10_AID_HOME}/bin/aid"
                chmod +x "${NM10_AID_HOME}/bin/aid"
                cp "${LIB_CORE}" "${NM10_AID_HOME}/lib/aid-install-core.sh"
                printf '%s\n' "${VERSION}" > "${NM10_AID_HOME}/VERSION"

                # Smoke: aid status in empty dir -> exit 7.
                NM10_EMPTY="$(mktemp -d "${TMP}/nm10-empty.XXXXXX")"
                NM10_STATUS_OUT=$(AID_HOME="${NM10_AID_HOME}" AID_NO_UPDATE_CHECK=1 \
                    "${NM10_AID}" status --target "${NM10_EMPTY}" 2>&1); NM10_STATUS_RC=$?
                assert_exit_eq "$NM10_STATUS_RC" 7 \
                    "NM10-05 installed aid status empty dir -> exit 7"
                assert_output_contains "$NM10_STATUS_OUT" "No AID install found" \
                    "NM10-06 installed aid status message"

                # Smoke: aid add codex --from-bundle -> exit 0, files created.
                NM10_TARGET="$(mktemp -d "${TMP}/nm10-target.XXXXXX")"
                NM10_ADD_OUT=$(AID_HOME="${NM10_AID_HOME}" AID_NO_UPDATE_CHECK=1 \
                    "${NM10_AID}" add codex \
                    --from-bundle "${TMP}/fixtures/aid-codex-v${VERSION}.tar.gz" \
                    --target "${NM10_TARGET}" 2>&1); NM10_ADD_RC=$?
                assert_exit_eq "$NM10_ADD_RC" 0 \
                    "NM10-07 installed aid add codex --from-bundle -> exit 0"
                assert_dir_exists "${NM10_TARGET}/.codex" \
                    "NM10-08 installed aid add: .codex/ created"
                assert_file_exists "${NM10_TARGET}/AGENTS.md" \
                    "NM10-09 installed aid add: AGENTS.md created"
            fi
        else
            fail "NM10-03 npm install -g failed"
            [[ "$VERBOSE" -eq 1 ]] && cat "${TMP}/nm10-install-out.txt"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# ASCII-only assert on the shim.
# ---------------------------------------------------------------------------
echo "=== NM-ASCII: ASCII-only check on packages/npm/bin/aid.js and vendor.js ==="

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
    fail "ASCII-only: packages/npm/bin/aid.js -- non-ASCII bytes found: $_offenders"
else
    pass "ASCII-only: packages/npm/bin/aid.js"
fi

if grep -qP '[^\x00-\x7F]' "${PKG_DIR}/scripts/vendor.js"; then
    fail "ASCII-only: packages/npm/scripts/vendor.js -- non-ASCII bytes found"
else
    pass "ASCII-only: packages/npm/scripts/vendor.js"
fi

test_summary
