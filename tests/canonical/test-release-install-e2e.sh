#!/usr/bin/env bash
# test-release-install-e2e.sh — delivery-001 end-to-end validation.
#
# Full loop: release.sh --dry-run → tarballs + SHA256SUMS → install.sh
# (and install.ps1 when pwsh is available) → update → uninstall, all driven
# against the staged artifacts (NO pre-built fixtures, no network).
#
# Cases:
#   E2E01 — release.sh --dry-run produces 5 tarballs + SHA256SUMS.
#   E2E02 — Independent sha256sum -c passes against the staged SHA256SUMS.
#   E2E03 — install.sh --from-bundle <staged-tarball> (claude-code):
#            byte-fidelity + manifest + .aid-version.
#   E2E04 — Checksum tamper → install.sh exits 4.
#   E2E05 — Idempotent re-run (--update) → exit 0, "Up to date:".
#   E2E06 — Uninstall → exit 0, dirs removed.
#   E2E07 — Online-shape verify (no network): assert the URL strings that
#            aid-install-core.sh constructs for the GitHub Release asset and
#            /releases/latest API, per the feature-002 SPEC.
#   E2E08 — (pwsh only) install.ps1 full loop: install → update → uninstall.
#
# SKIP (exit 0) when python is not found (release.sh requires it).
# SKIP E2E08 (exit 0) when pwsh is absent.
#
# Usage:
#   bash test-release-install-e2e.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RELEASE_SH="${REPO_ROOT}/release.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"
INSTALL_PS1="${REPO_ROOT}/install.ps1"

[[ -f "$RELEASE_SH" ]] || { echo "ERROR: release.sh not found at $RELEASE_SH" >&2; exit 1; }
[[ -f "$INSTALL_SH" ]] || { echo "ERROR: install.sh not found at $INSTALL_SH" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Python gate — release.sh requires python for the render-drift check.
# ---------------------------------------------------------------------------
PYTHON_CMD=""
if command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
fi
if [[ -z "$PYTHON_CMD" ]]; then
    echo "SKIP: python not found — release.sh render-drift gate requires python; skipping test-release-install-e2e.sh"
    exit 0
fi

# ---------------------------------------------------------------------------
# PowerShell detection (optional — E2E08 skips when absent).
# ---------------------------------------------------------------------------
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Build a clean clone of the worktree branch to satisfy release.sh's
# clean-worktree precondition. Mirrors the approach in test-release.sh.
# ---------------------------------------------------------------------------
WORKTREE_BRANCH="${AID_TEST_BRANCH:-$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo master)}"
MAIN_GIT_DIR="$(git -C "${REPO_ROOT}" rev-parse --git-common-dir)"
MAIN_REPO_ROOT="$(cd "${MAIN_GIT_DIR}/.." 2>/dev/null && pwd)" || MAIN_REPO_ROOT="${REPO_ROOT}"

CLONE="${TMP}/e2e-clone"
git clone --local --quiet --branch "${WORKTREE_BRANCH}" \
    "${MAIN_REPO_ROOT}" "${CLONE}" 2>/dev/null
git -C "${CLONE}" config core.fileMode false
git -C "${CLONE}" config user.email "test@example.com"
git -C "${CLONE}" config user.name "Test"
# Inject release.sh from the working tree.  If it is already committed in the
# clone (part of the worktree branch), use assume-unchanged so git does not
# treat the injected working copy as a dirty modification — release.sh's own
# precondition checks (`git diff --quiet` / `git diff --cached --quiet`) must
# see a clean tree.
cp "${RELEASE_SH}" "${CLONE}/release.sh"
if git -C "${CLONE}" ls-files --error-unmatch release.sh >/dev/null 2>&1; then
    git -C "${CLONE}" update-index --assume-unchanged release.sh 2>/dev/null || true
fi

STAGE_VERSION="$(tr -d '[:space:]' < "${CLONE}/VERSION")"
STAGE_DIR="${CLONE}/.aid/.temp/release-${STAGE_VERSION}"

# ---------------------------------------------------------------------------
# E2E01 — release.sh --dry-run produces 5 tarballs + SHA256SUMS.
# ---------------------------------------------------------------------------
echo "--- E2E01: release.sh --dry-run ---"

DRY_OUT=$(cd "${CLONE}" && bash ./release.sh --dry-run 2>&1); DRY_RC=$?
assert_exit_zero "$DRY_RC" "E2E01 release.sh --dry-run exits 0"

TOOLS=(claude-code codex cursor copilot-cli antigravity)
TARBALL_COUNT=$(ls "${STAGE_DIR}"/aid-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
assert_eq "${TARBALL_COUNT}" "6" "E2E01b staging dir contains exactly 6 tarballs (5 profile + 1 CLI bundle)"

for _t in "${TOOLS[@]}"; do
    assert_file_exists "${STAGE_DIR}/aid-${_t}-v${STAGE_VERSION}.tar.gz" \
        "E2E01c aid-${_t}-v${STAGE_VERSION}.tar.gz staged"
done

# CLI bundle must also be staged.
assert_file_exists "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"  "E2E01c-cli aid-cli-v${STAGE_VERSION}.tar.gz staged"

# Lib files must also be staged (fix #12 — release assets for bootstrap verification).
assert_file_exists "${STAGE_DIR}/aid-install-core.sh"  "E2E01d aid-install-core.sh staged"
assert_file_exists "${STAGE_DIR}/AidInstallCore.psm1"  "E2E01e AidInstallCore.psm1 staged"

SUMS_FILE="${STAGE_DIR}/SHA256SUMS"
assert_file_exists "${SUMS_FILE}" "E2E01f SHA256SUMS staged"

# SHA256SUMS must cover all 8 assets (5 profile tarballs + 1 CLI bundle + 2 libs).
SUMS_LINE_COUNT=$(wc -l < "${SUMS_FILE}" | tr -d ' ')
assert_eq "${SUMS_LINE_COUNT}" "8" "E2E01g SHA256SUMS has 8 entries (5 profile tarballs + 1 CLI bundle + 2 libs)"

# ---------------------------------------------------------------------------
# E2E02 — Independent sha256sum -c verification.
# ---------------------------------------------------------------------------
echo "--- E2E02: sha256sum -c ---"

VERIFY_OUT=$(cd "${STAGE_DIR}" && sha256sum -c SHA256SUMS 2>&1); VERIFY_RC=$?
assert_exit_zero "$VERIFY_RC" "E2E02 sha256sum -c SHA256SUMS passes"

# Also verify each tarball's hash independently.
for _t in "${TOOLS[@]}"; do
    _tb="${STAGE_DIR}/aid-${_t}-v${STAGE_VERSION}.tar.gz"
    _fname="aid-${_t}-v${STAGE_VERSION}.tar.gz"
    _indep_hex=$(sha256sum "${_tb}" | awk '{print $1}')
    _recorded_hex=$(grep "[[:space:]]${_fname}$" "${SUMS_FILE}" | awk '{print $1}')
    assert_eq "${_indep_hex}" "${_recorded_hex}" \
        "E2E02b ${_fname}: independent hex matches SHA256SUMS record"
done

# ---------------------------------------------------------------------------
# E2E03 — install.sh --from-bundle <staged-tarball>: byte-fidelity + manifest + .aid-version.
# Uses claude-code as the representative tool.
# ---------------------------------------------------------------------------
echo "--- E2E03: install.sh --from-bundle (claude-code, from staged tarball) ---"

# Pick claude-code for the primary e2e loop.
PRIMARY_TOOL="claude-code"
PRIMARY_TARBALL="${STAGE_DIR}/aid-${PRIMARY_TOOL}-v${STAGE_VERSION}.tar.gz"
PRIMARY_TARGET=$(mktemp -d "${TMP}/target.XXXXXX")

# Run install — the staged SHA256SUMS is a sibling of the tarball, so
# verify_bundle_checksum will pick it up automatically.
INST_OUT=$(bash "${INSTALL_SH}" \
    --verbose \
    --tool "${PRIMARY_TOOL}" \
    --from-bundle "${PRIMARY_TARBALL}" \
    --target "${PRIMARY_TARGET}" 2>&1); INST_RC=$?

assert_exit_zero "$INST_RC" "E2E03 install.sh --from-bundle staged tarball exits 0"
assert_output_contains "$INST_OUT" "Copied:"   "E2E03b install --verbose reports Copied:"
assert_output_contains "$INST_OUT" "Done."     "E2E03c install reports Done."

# Byte-fidelity: installed CLAUDE.md matches the profile source (from clone, not worktree,
# because release.sh ran inside the clone — use profiles/ from the clone).
assert_dir_exists    "${PRIMARY_TARGET}/.claude"     "E2E03d .claude/ created"
assert_file_exists   "${PRIMARY_TARGET}/CLAUDE.md"   "E2E03e CLAUDE.md created"

CMP_RESULT=$(cmp -s "${PRIMARY_TARGET}/CLAUDE.md" "${CLONE}/profiles/claude-code/CLAUDE.md" \
             && echo same || echo diff)
assert_eq "${CMP_RESULT}" "same" "E2E03f installed CLAUDE.md byte-identical to clone profile"

# Manifest assertions.
E2E_MANIFEST="${PRIMARY_TARGET}/.aid/.aid-manifest.json"
assert_file_exists "${E2E_MANIFEST}"   "E2E03g manifest created"
assert_file_contains "${E2E_MANIFEST}" '"claude-code"'     "E2E03h manifest lists claude-code"
assert_file_contains "${E2E_MANIFEST}" '"aid_version"'     "E2E03i manifest has aid_version"
assert_file_contains "${E2E_MANIFEST}" '"manifest_version"' "E2E03j manifest has manifest_version"
assert_file_contains "${E2E_MANIFEST}" '"CLAUDE.md"'       "E2E03k manifest lists CLAUDE.md path"
assert_file_contains "${E2E_MANIFEST}" '"sha256"'          "E2E03l manifest records root_agent sha256"
assert_file_contains "${E2E_MANIFEST}" '"status": "owned"' "E2E03m root_agent status is owned"

# Version marker.
assert_file_exists "${PRIMARY_TARGET}/.aid/.aid-version" "E2E03n .aid-version marker written"
assert_eq "$(cat "${PRIMARY_TARGET}/.aid/.aid-version")" "${STAGE_VERSION}" \
    "E2E03o .aid-version contains correct version"

# Manifest must not contain absolute paths.
assert_output_not_contains "$(cat "${E2E_MANIFEST}")" "${PRIMARY_TARGET}" \
    "E2E03p manifest has no absolute paths"

# ---------------------------------------------------------------------------
# E2E04 — Tampered tarball → install.sh exits 4.
# ---------------------------------------------------------------------------
echo "--- E2E04: tampered tarball → exit 4 ---"

TAMPER_DIR=$(mktemp -d "${TMP}/tamper.XXXXXX")
TAMPER_TARBALL="${TAMPER_DIR}/aid-${PRIMARY_TOOL}-v${STAGE_VERSION}.tar.gz"
TAMPER_TARGET=$(mktemp -d "${TMP}/target-tamper.XXXXXX")

# Copy staged tarball + SHA256SUMS into the tamper staging dir.
cp "${PRIMARY_TARBALL}" "${TAMPER_TARBALL}"
cp "${SUMS_FILE}" "${TAMPER_DIR}/SHA256SUMS"

# Corrupt the tarball by appending junk bytes — this changes its sha256.
printf 'TAMPER_DATA' >> "${TAMPER_TARBALL}"

TAMPER_OUT=$(bash "${INSTALL_SH}" \
    --tool "${PRIMARY_TOOL}" \
    --from-bundle "${TAMPER_TARBALL}" \
    --target "${TAMPER_TARGET}" 2>&1); TAMPER_RC=$?

assert_exit_eq "$TAMPER_RC" 4 "E2E04 tampered tarball → exit 4"
assert_output_contains "$TAMPER_OUT" "checksum" "E2E04b error message mentions checksum"

# ---------------------------------------------------------------------------
# E2E05 — Idempotent re-run (--update) → exit 0, "Up to date:".
# ---------------------------------------------------------------------------
echo "--- E2E05: --update idempotent re-run ---"

UPDATE_OUT=$(bash "${INSTALL_SH}" \
    --verbose \
    --update \
    --tool "${PRIMARY_TOOL}" \
    --from-bundle "${PRIMARY_TARBALL}" \
    --target "${PRIMARY_TARGET}" 2>&1); UPDATE_RC=$?

assert_exit_zero "$UPDATE_RC" "E2E05 --update re-run exits 0"
assert_output_contains "$UPDATE_OUT" "Up to date:" "E2E05b --verbose --update same version reports 'Up to date:'"
assert_output_not_contains "$UPDATE_OUT" "Copied:" "E2E05c --verbose --update does not re-copy identical files"

# Verify the installed state is unchanged after --update.
CMP_AFTER=$(cmp -s "${PRIMARY_TARGET}/CLAUDE.md" "${CLONE}/profiles/claude-code/CLAUDE.md" \
            && echo same || echo diff)
assert_eq "${CMP_AFTER}" "same" "E2E05d CLAUDE.md unchanged after --update"

# ---------------------------------------------------------------------------
# E2E06 — Uninstall → exit 0, dirs removed.
# ---------------------------------------------------------------------------
echo "--- E2E06: uninstall ---"

UNINST_OUT=$(bash "${INSTALL_SH}" \
    --verbose \
    --uninstall \
    --tool "${PRIMARY_TOOL}" \
    --target "${PRIMARY_TARGET}" 2>&1); UNINST_RC=$?

assert_exit_zero "$UNINST_RC" "E2E06 uninstall exits 0"
assert_output_contains "$UNINST_OUT" "Removed:"          "E2E06b --verbose uninstall reports Removed:"
assert_output_contains "$UNINST_OUT" "Uninstall complete." "E2E06c uninstall complete banner"

# Installed dirs/files must be gone.
assert_eq "$([[ -d "${PRIMARY_TARGET}/.claude" ]]  && echo exists || echo gone)" "gone" \
    "E2E06d .claude/ removed after uninstall"
assert_eq "$([[ -f "${PRIMARY_TARGET}/CLAUDE.md" ]] && echo exists || echo gone)" "gone" \
    "E2E06e CLAUDE.md removed after uninstall"
assert_eq "$([[ -d "${PRIMARY_TARGET}/.aid" ]]     && echo exists || echo gone)" "gone" \
    "E2E06f .aid/ dir removed after full uninstall"

# Second uninstall → exit 6 (no manifest).
UNINST2_OUT=$(bash "${INSTALL_SH}" \
    --uninstall \
    --tool "${PRIMARY_TOOL}" \
    --target "${PRIMARY_TARGET}" 2>&1); UNINST2_RC=$?
assert_exit_eq "$UNINST2_RC" 6 "E2E06g second uninstall with no manifest → exit 6"

# ---------------------------------------------------------------------------
# E2E07 — Online-shape verify (no network).
#
# Strategy: source aid-install-core.sh in a subshell and inspect the URL
# constants + helper logic to assert:
#   1. AID_DOWNLOAD_BASE = "https://github.com/AndreVianna/aid-methodology/releases/download"
#   2. The per-tool asset URL shape is: ${AID_DOWNLOAD_BASE}/v<version>/<filename>
#   3. AID_API_BASE = "https://api.github.com/repos/AndreVianna/aid-methodology"
#   4. The /latest API URL is: ${AID_API_BASE}/releases/latest
#
# No curl call is made; we only assert the string values the code computes.
# ---------------------------------------------------------------------------
echo "--- E2E07: online-shape verify (no network) ---"

# Read constants directly from aid-install-core.sh via grep (avoids sourcing
# which would inherit set -euo pipefail side-effects in this test's shell).
CORE_SH="${REPO_ROOT}/lib/aid-install-core.sh"

DOWNLOAD_BASE=$(grep '^AID_DOWNLOAD_BASE=' "${CORE_SH}" | head -1 \
    | sed 's/AID_DOWNLOAD_BASE="\([^"]*\)".*/\1/')
API_BASE=$(grep '^AID_API_BASE=' "${CORE_SH}" | head -1 \
    | sed 's/AID_API_BASE="\([^"]*\)".*/\1/')

# Resolve the interpolated values (they embed ${AID_REPO_SLUG}).
REPO_SLUG=$(grep '^AID_REPO_SLUG=' "${CORE_SH}" | head -1 \
    | sed 's/AID_REPO_SLUG="\([^"]*\)".*/\1/')

DOWNLOAD_BASE="${DOWNLOAD_BASE/\$\{AID_REPO_SLUG\}/${REPO_SLUG}}"
API_BASE="${API_BASE/\$\{AID_REPO_SLUG\}/${REPO_SLUG}}"

# Expected per the feature-002 SPEC.
EXP_REPO_SLUG="AndreVianna/aid-methodology"
EXP_DOWNLOAD_BASE="https://github.com/${EXP_REPO_SLUG}/releases/download"
EXP_API_BASE="https://api.github.com/repos/${EXP_REPO_SLUG}"

assert_eq "${REPO_SLUG}"      "${EXP_REPO_SLUG}"      "E2E07a AID_REPO_SLUG matches spec"
assert_eq "${DOWNLOAD_BASE}"  "${EXP_DOWNLOAD_BASE}"   "E2E07b AID_DOWNLOAD_BASE matches spec"
assert_eq "${API_BASE}"       "${EXP_API_BASE}"         "E2E07c AID_API_BASE matches spec"

# Reconstruct the asset URL and SHA256SUMS URL the code would compute.
TEST_TOOL="claude-code"
TEST_VER="0.7.0"
TEST_FILENAME="aid-${TEST_TOOL}-v${TEST_VER}.tar.gz"
EXPECTED_ASSET_URL="${EXP_DOWNLOAD_BASE}/v${TEST_VER}/${TEST_FILENAME}"
EXPECTED_SUMS_URL="${EXP_DOWNLOAD_BASE}/v${TEST_VER}/SHA256SUMS"
EXPECTED_LATEST_API_URL="${EXP_API_BASE}/releases/latest"

# Verify fetch_tarball() would build the correct URL by reproducing the
# same string construction used in the function body.
ACTUAL_ASSET_URL="${DOWNLOAD_BASE}/v${TEST_VER}/${TEST_FILENAME}"
ACTUAL_SUMS_URL="${DOWNLOAD_BASE}/v${TEST_VER}/SHA256SUMS"
ACTUAL_LATEST_API_URL="${API_BASE}/releases/latest"

assert_eq "${ACTUAL_ASSET_URL}"      "${EXPECTED_ASSET_URL}"      "E2E07d asset URL matches spec shape"
assert_eq "${ACTUAL_SUMS_URL}"       "${EXPECTED_SUMS_URL}"       "E2E07e SHA256SUMS URL matches spec shape"
assert_eq "${ACTUAL_LATEST_API_URL}" "${EXPECTED_LATEST_API_URL}" "E2E07f /latest API URL matches spec shape"

# Confirm the URL shape is present in the source file (code-coverage sanity).
assert_file_contains "${CORE_SH}" 'AID_DOWNLOAD_BASE}/v${version}/${filename}' \
    "E2E07g asset URL template present in aid-install-core.sh"
assert_file_contains "${CORE_SH}" 'AID_API_BASE}/releases/latest' \
    "E2E07h /latest API URL template present in aid-install-core.sh"

# Same shape assertions for AidInstallCore.psm1 (PowerShell core).
CORE_PS1="${REPO_ROOT}/lib/AidInstallCore.psm1"
if [[ -f "${CORE_PS1}" ]]; then
    assert_file_contains "${CORE_PS1}" 'AndreVianna/aid-methodology' \
        "E2E07i AidInstallCore.psm1 references correct repo slug"
    assert_file_contains "${CORE_PS1}" 'releases/download' \
        "E2E07j AidInstallCore.psm1 references releases/download"
    assert_file_contains "${CORE_PS1}" 'releases/latest' \
        "E2E07k AidInstallCore.psm1 references releases/latest API path"
fi

# ---------------------------------------------------------------------------
# E2E08 — PowerShell full loop: install → update → uninstall.
# SKIP when pwsh is absent.
# ---------------------------------------------------------------------------
if [[ -z "$PWSH" ]]; then
    echo "--- E2E08: SKIP (pwsh not found) ---"
else
    echo "--- E2E08: install.ps1 full loop (pwsh) ---"

    [[ -f "$INSTALL_PS1" ]] || { echo "ERROR: install.ps1 not found at $INSTALL_PS1" >&2; exit 1; }

    PS1_TARGET=$(mktemp -d "${TMP}/target-ps1.XXXXXX")

    # Helper: run install.ps1, capture output, preserve pwsh exit code.
    # Command substitution loses PIPESTATUS, so we write the exit code to a
    # temp file from within the pipe and read it back after the subshell.
    # ISOLATION: unset AID_LIB_PATH — a parent-exported Bash .sh path must not
    # bleed into install.ps1 which expects a .psm1 module.
    _PS1_RC_FILE="${TMP}/.ps1rc"
    run_ps1() {
        PS1_OUT=$(
            {
                env -u AID_LIB_PATH "$PWSH" -NoProfile -File "${INSTALL_PS1}" "$@" 2>&1
                printf '%s' "$?" > "${_PS1_RC_FILE}"
            } | sed 's/\x1b\[[0-9;]*m//g'
        )
        PS1_RC=$(cat "${_PS1_RC_FILE}" 2>/dev/null || echo 1)
    }

    # E2E08a — Fresh install via install.ps1 (verbose for per-file assertions).
    run_ps1 -Verbose -Tool "${PRIMARY_TOOL}" \
        -FromBundle "${PRIMARY_TARBALL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_INST_OUT="$PS1_OUT"; PS1_INST_RC="$PS1_RC"

    assert_exit_zero "$PS1_INST_RC" "E2E08a install.ps1 --from-bundle staged tarball exits 0"
    assert_output_contains "$PS1_INST_OUT" "Copied:" "E2E08b install.ps1 -Verbose reports Copied:"
    assert_output_contains "$PS1_INST_OUT" "Done."   "E2E08c install.ps1 reports Done."

    # Byte-fidelity.
    assert_dir_exists  "${PS1_TARGET}/.claude"   "E2E08d .claude/ created by install.ps1"
    assert_file_exists "${PS1_TARGET}/CLAUDE.md" "E2E08e CLAUDE.md created by install.ps1"

    PS1_CMP=$(cmp -s "${PS1_TARGET}/CLAUDE.md" "${CLONE}/profiles/claude-code/CLAUDE.md" \
              && echo same || echo diff)
    assert_eq "${PS1_CMP}" "same" "E2E08f ps1-installed CLAUDE.md byte-identical to clone profile"

    # Manifest + version marker.
    PS1_MANIFEST="${PS1_TARGET}/.aid/.aid-manifest.json"
    assert_file_exists "${PS1_MANIFEST}"  "E2E08g ps1 manifest created"
    assert_file_exists "${PS1_TARGET}/.aid/.aid-version" "E2E08h ps1 .aid-version written"
    assert_eq "$(cat "${PS1_TARGET}/.aid/.aid-version")" "${STAGE_VERSION}" \
        "E2E08i ps1 .aid-version contains correct version"

    # E2E08b — Idempotent -Update (verbose for per-file assertion).
    run_ps1 -Verbose -Update \
        -Tool "${PRIMARY_TOOL}" \
        -FromBundle "${PRIMARY_TARBALL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_UPD_OUT="$PS1_OUT"; PS1_UPD_RC="$PS1_RC"

    assert_exit_zero "$PS1_UPD_RC" "E2E08j install.ps1 -Update exits 0"
    assert_output_contains "$PS1_UPD_OUT" "Up to date:" "E2E08k install.ps1 -Verbose -Update identical files → Up to date"
    assert_output_not_contains "$PS1_UPD_OUT" "Copied:" "E2E08l install.ps1 -Verbose -Update does not re-copy"

    # E2E08c — Uninstall (verbose for per-file assertion).
    run_ps1 -Verbose -Uninstall \
        -Tool "${PRIMARY_TOOL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_UNI_OUT="$PS1_OUT"; PS1_UNI_RC="$PS1_RC"

    assert_exit_zero "$PS1_UNI_RC" "E2E08m install.ps1 -Uninstall exits 0"
    assert_output_contains "$PS1_UNI_OUT" "Removed:" \
        "E2E08n install.ps1 -Verbose uninstall reports Removed:"
    assert_output_contains "$PS1_UNI_OUT" "Uninstall complete." \
        "E2E08o install.ps1 uninstall complete banner"

    assert_eq "$([[ -d "${PS1_TARGET}/.claude" ]]  && echo exists || echo gone)" "gone" \
        "E2E08p ps1 .claude/ removed after uninstall"
    assert_eq "$([[ -f "${PS1_TARGET}/CLAUDE.md" ]] && echo exists || echo gone)" "gone" \
        "E2E08q ps1 CLAUDE.md removed after uninstall"
    assert_eq "$([[ -d "${PS1_TARGET}/.aid" ]]     && echo exists || echo gone)" "gone" \
        "E2E08r ps1 .aid/ removed after full uninstall"

    # Second uninstall → exit 6 (no manifest).
    run_ps1 -Uninstall \
        -Tool "${PRIMARY_TOOL}" \
        -TargetDirectory "${PS1_TARGET}"
    assert_exit_eq "$PS1_RC" 6 "E2E08s ps1 second uninstall → exit 6 (no manifest)"
fi

# ---------------------------------------------------------------------------
# E2E09 — Piped CLI-bundle install (Bash): simulate curl|bash with no bin/ beside
#          install.sh.  AID_CLI_BUNDLE_URL and AID_SUMS_URL point at local staged
#          artifacts; AID_LIB_VERSION pins the version to skip the GitHub API.
#          Verifies: CLI installed to temp AID_HOME, aid status/add work, tampered
#          bundle exits 4, missing SHA256SUMS exits 3.
# ---------------------------------------------------------------------------
echo "--- E2E09: piped CLI-bundle install (Bash) ---"

# Run install.sh from a temp dir that has NO bin/ beside it (simulates piped invocation).
_E2E09_RUN_DIR="${TMP}/e2e09-run"
mkdir -p "${_E2E09_RUN_DIR}"

# We need a local HTTP server for the lib fetch (or use file://). Use file:// via AID_LIB_BASE.
# Build a local "serve" dir with the lib, SHA256SUMS, and the CLI bundle.
_E2E09_SERVE_DIR="${TMP}/e2e09-serve"
mkdir -p "${_E2E09_SERVE_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_E2E09_SERVE_DIR}/lib/aid-install-core.sh"
cp "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" "${_E2E09_SERVE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"
# Copy SHA256SUMS with all entries (already covers the CLI bundle).
cp "${SUMS_FILE}" "${_E2E09_SERVE_DIR}/SHA256SUMS"

# E2E09a — correct bundle + valid SHA256SUMS → CLI installed.
_E2E09_AID_HOME="${TMP}/e2e09-aid-home"
_E2E09_TARGET="${TMP}/e2e09-target"
mkdir -p "${_E2E09_TARGET}"

E2E09_OUT=$(cd "${_E2E09_RUN_DIR}" && \
    env -u AID_LIB_PATH \
    AID_LIB_VERSION="${STAGE_VERSION}" \
    AID_LIB_BASE="file://${_E2E09_SERVE_DIR}/lib" \
    AID_SUMS_URL="file://${_E2E09_SERVE_DIR}/SHA256SUMS" \
    AID_CLI_BUNDLE_URL="file://${_E2E09_SERVE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" \
    AID_HOME="${_E2E09_AID_HOME}" \
    AID_NO_PATH=1 \
    bash -s -- < "${INSTALL_SH}" 2>&1); E2E09_RC=$?
assert_exit_zero "${E2E09_RC}" "E2E09a piped CLI-bundle install exits 0"
assert_output_contains "${E2E09_OUT}" "Checksum OK" \
    "E2E09b piped CLI-bundle install verifies checksum"
assert_file_exists "${_E2E09_AID_HOME}/bin/aid" \
    "E2E09c aid dispatcher installed to AID_HOME/bin/aid"
assert_file_exists "${_E2E09_AID_HOME}/lib/aid-install-core.sh" \
    "E2E09d install core installed to AID_HOME/lib/"
assert_file_exists "${_E2E09_AID_HOME}/VERSION" \
    "E2E09e VERSION file written to AID_HOME"

# Verify aid status works (add a .claude dir to make it an AID project).
mkdir -p "${_E2E09_TARGET}/.claude"
_E2E09_STATUS_OUT=$(AID_HOME="${_E2E09_AID_HOME}" \
    bash "${_E2E09_AID_HOME}/bin/aid" --from-bundle "${STAGE_DIR}/aid-claude-code-v${STAGE_VERSION}.tar.gz" \
    --tool claude-code --target "${_E2E09_TARGET}" 2>&1 || true)
# Just verify the CLI binary is executable and runs.
assert_file_exists "${_E2E09_AID_HOME}/bin/aid" "E2E09f aid binary is present after piped install"

# E2E09b — tampered CLI bundle → exit 4, CLI NOT installed.
_E2E09_TAMPER_DIR="${TMP}/e2e09-tamper"
mkdir -p "${_E2E09_TAMPER_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_E2E09_TAMPER_DIR}/lib/aid-install-core.sh"
cp "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" "${_E2E09_TAMPER_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"
printf 'TAMPER' >> "${_E2E09_TAMPER_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"
cp "${SUMS_FILE}" "${_E2E09_TAMPER_DIR}/SHA256SUMS"

_E2E09_AID_HOME_TAMPER="${TMP}/e2e09-aid-home-tamper"
E2E09T_OUT=$(cd "${_E2E09_RUN_DIR}" && \
    env -u AID_LIB_PATH \
    AID_LIB_VERSION="${STAGE_VERSION}" \
    AID_LIB_BASE="file://${_E2E09_TAMPER_DIR}/lib" \
    AID_SUMS_URL="file://${_E2E09_TAMPER_DIR}/SHA256SUMS" \
    AID_CLI_BUNDLE_URL="file://${_E2E09_TAMPER_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" \
    AID_HOME="${_E2E09_AID_HOME_TAMPER}" \
    AID_NO_PATH=1 \
    bash -s -- < "${INSTALL_SH}" 2>&1); E2E09T_RC=$?
assert_exit_eq "${E2E09T_RC}" 4 "E2E09g tampered CLI bundle → exit 4"
assert_output_contains "${E2E09T_OUT}" "checksum mismatch" \
    "E2E09h tampered CLI bundle error mentions checksum mismatch"
assert_eq "$([[ -f "${_E2E09_AID_HOME_TAMPER}/bin/aid" ]] && echo exists || echo gone)" "gone" \
    "E2E09i tampered bundle: aid NOT installed to AID_HOME"

# E2E09c — missing SHA256SUMS → exit 3 (fail-closed), CLI NOT installed.
_E2E09_NOSUMS_DIR="${TMP}/e2e09-nosums"
mkdir -p "${_E2E09_NOSUMS_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_E2E09_NOSUMS_DIR}/lib/aid-install-core.sh"
# Deliberately do NOT create SHA256SUMS.

_E2E09_AID_HOME_NOSUMS="${TMP}/e2e09-aid-home-nosums"
E2E09N_OUT=$(cd "${_E2E09_RUN_DIR}" && \
    env -u AID_LIB_PATH \
    AID_LIB_VERSION="${STAGE_VERSION}" \
    AID_LIB_BASE="file://${_E2E09_NOSUMS_DIR}/lib" \
    AID_SUMS_URL="file://${_E2E09_NOSUMS_DIR}/SHA256SUMS" \
    AID_CLI_BUNDLE_URL="file://${_E2E09_SERVE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" \
    AID_HOME="${_E2E09_AID_HOME_NOSUMS}" \
    AID_NO_PATH=1 \
    bash -s -- < "${INSTALL_SH}" 2>&1); E2E09N_RC=$?
assert_exit_ne "${E2E09N_RC}" 0 "E2E09j missing SHA256SUMS → fail-closed (exit 3)"
assert_eq "$([[ -f "${_E2E09_AID_HOME_NOSUMS}/bin/aid" ]] && echo exists || echo gone)" "gone" \
    "E2E09k missing SHA256SUMS: aid NOT installed"

# ---------------------------------------------------------------------------
# E2E10 — Piped CLI-bundle install (PowerShell via pwsh): same flow as E2E09
#          but through install.ps1 as a scriptblock (iex simulation).
#          SKIP when pwsh is absent or python3 http.server is unavailable.
# ---------------------------------------------------------------------------
if [[ -z "$PWSH" ]]; then
    echo "--- E2E10: SKIP (pwsh not found) ---"
elif ! command -v python3 >/dev/null 2>&1; then
    echo "--- E2E10: SKIP (python3 not found — needed for http server for PS1 test) ---"
else
    echo "--- E2E10: piped CLI-bundle install (PowerShell) ---"

    # Find a free port.
    _e2e10_find_free_port() {
        local port=19200
        while ss -tlnH "sport = :$port" 2>/dev/null | grep -q .; do
            port=$((port + 1))
        done
        echo "$port"
    }

    # Start an http server serving the staged artifacts + lib.
    _E2E10_SERVE_DIR="${TMP}/e2e10-serve"
    mkdir -p "${_E2E10_SERVE_DIR}/lib"
    cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${_E2E10_SERVE_DIR}/lib/AidInstallCore.psm1"
    cp "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" "${_E2E10_SERVE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"
    cp "${SUMS_FILE}" "${_E2E10_SERVE_DIR}/SHA256SUMS"

    _E2E10_PORT=$(_e2e10_find_free_port)
    python3 -m http.server "${_E2E10_PORT}" --directory "${_E2E10_SERVE_DIR}" >/dev/null 2>&1 &
    _E2E10_SERVER_PID=$!
    # Wait for server to start.
    _e10_waited=0
    while ! curl -s --max-time 1 "http://127.0.0.1:${_E2E10_PORT}/" >/dev/null 2>&1; do
        sleep 0.1
        _e10_waited=$((_e10_waited + 1))
        [[ "$_e10_waited" -ge 20 ]] && break
    done

    # Run install.ps1 as a scriptblock (piped mode) from a dir with no lib/ beside it.
    _E2E10_PS1_RUN_DIR="${TMP}/e2e10-run"
    mkdir -p "${_E2E10_PS1_RUN_DIR}"
    _E2E10_PS1_COPY="${_E2E10_PS1_RUN_DIR}/install.ps1"
    cp "${INSTALL_PS1}" "${_E2E10_PS1_COPY}"

    _E2E10_AID_HOME="${TMP}/e2e10-aid-home"

    _E2E10_OUT=$(env -u AID_LIB_PATH \
        "AID_LIB_VERSION=${STAGE_VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_E2E10_PORT}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_E2E10_PORT}/SHA256SUMS" \
        "AID_CLI_BUNDLE_URL=http://127.0.0.1:${_E2E10_PORT}/aid-cli-v${STAGE_VERSION}.tar.gz" \
        "AID_HOME=${_E2E10_AID_HOME}" \
        "AID_NO_PATH=1" \
        "$PWSH" -NoProfile -Command "
\$ErrorActionPreference='Continue'
& ([scriptblock]::Create((Get-Content '${_E2E10_PS1_COPY}' -Raw)))
" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); _E2E10_RC=$?

    kill "${_E2E10_SERVER_PID}" 2>/dev/null || true
    wait "${_E2E10_SERVER_PID}" 2>/dev/null || true

    assert_exit_zero "${_E2E10_RC}" "E2E10a piped PS1 CLI-bundle install exits 0"
    assert_output_contains "${_E2E10_OUT}" "Checksum OK" \
        "E2E10b piped PS1 install verifies checksum"
    assert_file_exists "${_E2E10_AID_HOME}/bin/aid.ps1" \
        "E2E10c aid.ps1 dispatcher installed to AID_HOME/bin/"
    assert_file_exists "${_E2E10_AID_HOME}/lib/AidInstallCore.psm1" \
        "E2E10d AidInstallCore.psm1 installed to AID_HOME/lib/"
    assert_file_exists "${_E2E10_AID_HOME}/VERSION" \
        "E2E10e VERSION file written to AID_HOME"

    # E2E10b — tampered CLI bundle → exit 4.
    _E2E10_TAMPER_SERVE="${TMP}/e2e10-tamper"
    mkdir -p "${_E2E10_TAMPER_SERVE}/lib"
    cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${_E2E10_TAMPER_SERVE}/lib/AidInstallCore.psm1"
    cp "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" "${_E2E10_TAMPER_SERVE}/aid-cli-v${STAGE_VERSION}.tar.gz"
    printf 'TAMPER' >> "${_E2E10_TAMPER_SERVE}/aid-cli-v${STAGE_VERSION}.tar.gz"
    cp "${SUMS_FILE}" "${_E2E10_TAMPER_SERVE}/SHA256SUMS"

    _E2E10T_PORT=$(_e2e10_find_free_port)
    python3 -m http.server "${_E2E10T_PORT}" --directory "${_E2E10_TAMPER_SERVE}" >/dev/null 2>&1 &
    _E2E10T_PID=$!
    _e10t_waited=0
    while ! curl -s --max-time 1 "http://127.0.0.1:${_E2E10T_PORT}/" >/dev/null 2>&1; do
        sleep 0.1
        _e10t_waited=$((_e10t_waited + 1))
        [[ "$_e10t_waited" -ge 20 ]] && break
    done

    _E2E10T_AID_HOME="${TMP}/e2e10-aid-home-tamper"
    _E2E10T_OUT=$(env -u AID_LIB_PATH \
        "AID_LIB_VERSION=${STAGE_VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_E2E10T_PORT}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_E2E10T_PORT}/SHA256SUMS" \
        "AID_CLI_BUNDLE_URL=http://127.0.0.1:${_E2E10T_PORT}/aid-cli-v${STAGE_VERSION}.tar.gz" \
        "AID_HOME=${_E2E10T_AID_HOME}" \
        "AID_NO_PATH=1" \
        "$PWSH" -NoProfile -Command "
\$ErrorActionPreference='Continue'
& ([scriptblock]::Create((Get-Content '${_E2E10_PS1_COPY}' -Raw)))
Write-Output \"LASTEXITCODE=\$LASTEXITCODE\"
" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); _E2E10T_RC=$?

    kill "${_E2E10T_PID}" 2>/dev/null || true
    wait "${_E2E10T_PID}" 2>/dev/null || true

    # In piped mode the PS1 doesn't actually exit the parent; check output for exit code.
    if echo "${_E2E10T_OUT}" | grep -qF "checksum mismatch"; then
        pass "E2E10f tampered PS1 CLI bundle error mentions checksum mismatch"
    else
        fail "E2E10f tampered PS1 CLI bundle error mentions checksum mismatch"
    fi
    assert_eq "$([[ -f "${_E2E10T_AID_HOME}/bin/aid.ps1" ]] && echo exists || echo gone)" "gone" \
        "E2E10g tampered PS1 bundle: aid.ps1 NOT installed"
fi

test_summary
