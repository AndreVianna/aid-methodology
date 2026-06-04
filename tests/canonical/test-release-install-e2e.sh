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
WORKTREE_BRANCH="worktree-work-002-auto-installer"
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
assert_eq "${TARBALL_COUNT}" "5" "E2E01b staging dir contains exactly 5 tarballs"

for _t in "${TOOLS[@]}"; do
    assert_file_exists "${STAGE_DIR}/aid-${_t}-v${STAGE_VERSION}.tar.gz" \
        "E2E01c aid-${_t}-v${STAGE_VERSION}.tar.gz staged"
done

SUMS_FILE="${STAGE_DIR}/SHA256SUMS"
assert_file_exists "${SUMS_FILE}" "E2E01d SHA256SUMS staged"

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
    --tool "${PRIMARY_TOOL}" \
    --from-bundle "${PRIMARY_TARBALL}" \
    --target "${PRIMARY_TARGET}" 2>&1); INST_RC=$?

assert_exit_zero "$INST_RC" "E2E03 install.sh --from-bundle staged tarball exits 0"
assert_output_contains "$INST_OUT" "Copied:"   "E2E03b install reports Copied:"
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
    --update \
    --tool "${PRIMARY_TOOL}" \
    --from-bundle "${PRIMARY_TARBALL}" \
    --target "${PRIMARY_TARGET}" 2>&1); UPDATE_RC=$?

assert_exit_zero "$UPDATE_RC" "E2E05 --update re-run exits 0"
assert_output_contains "$UPDATE_OUT" "Up to date:" "E2E05b --update same version reports 'Up to date:'"
assert_output_not_contains "$UPDATE_OUT" "Copied:" "E2E05c --update does not re-copy identical files"

# Verify the installed state is unchanged after --update.
CMP_AFTER=$(cmp -s "${PRIMARY_TARGET}/CLAUDE.md" "${CLONE}/profiles/claude-code/CLAUDE.md" \
            && echo same || echo diff)
assert_eq "${CMP_AFTER}" "same" "E2E05d CLAUDE.md unchanged after --update"

# ---------------------------------------------------------------------------
# E2E06 — Uninstall → exit 0, dirs removed.
# ---------------------------------------------------------------------------
echo "--- E2E06: uninstall ---"

UNINST_OUT=$(bash "${INSTALL_SH}" \
    --uninstall \
    --tool "${PRIMARY_TOOL}" \
    --target "${PRIMARY_TARGET}" 2>&1); UNINST_RC=$?

assert_exit_zero "$UNINST_RC" "E2E06 uninstall exits 0"
assert_output_contains "$UNINST_OUT" "Removed:"          "E2E06b uninstall reports Removed:"
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
    _PS1_RC_FILE="${TMP}/.ps1rc"
    run_ps1() {
        PS1_OUT=$(
            {
                "$PWSH" -NoProfile -File "${INSTALL_PS1}" "$@" 2>&1
                printf '%s' "$?" > "${_PS1_RC_FILE}"
            } | sed 's/\x1b\[[0-9;]*m//g'
        )
        PS1_RC=$(cat "${_PS1_RC_FILE}" 2>/dev/null || echo 1)
    }

    # E2E08a — Fresh install via install.ps1.
    run_ps1 -Tool "${PRIMARY_TOOL}" \
        -FromBundle "${PRIMARY_TARBALL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_INST_OUT="$PS1_OUT"; PS1_INST_RC="$PS1_RC"

    assert_exit_zero "$PS1_INST_RC" "E2E08a install.ps1 --from-bundle staged tarball exits 0"
    assert_output_contains "$PS1_INST_OUT" "Copied:" "E2E08b install.ps1 reports Copied:"
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

    # E2E08b — Idempotent -Update.
    run_ps1 -Update \
        -Tool "${PRIMARY_TOOL}" \
        -FromBundle "${PRIMARY_TARBALL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_UPD_OUT="$PS1_OUT"; PS1_UPD_RC="$PS1_RC"

    assert_exit_zero "$PS1_UPD_RC" "E2E08j install.ps1 -Update exits 0"
    assert_output_contains "$PS1_UPD_OUT" "Up to date:" "E2E08k install.ps1 -Update identical files → Up to date"
    assert_output_not_contains "$PS1_UPD_OUT" "Copied:" "E2E08l install.ps1 -Update does not re-copy"

    # E2E08c — Uninstall.
    run_ps1 -Uninstall \
        -Tool "${PRIMARY_TOOL}" \
        -TargetDirectory "${PS1_TARGET}"
    PS1_UNI_OUT="$PS1_OUT"; PS1_UNI_RC="$PS1_RC"

    assert_exit_zero "$PS1_UNI_RC" "E2E08m install.ps1 -Uninstall exits 0"
    assert_output_contains "$PS1_UNI_OUT" "Removed:" \
        "E2E08n install.ps1 uninstall reports Removed:"
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

test_summary
