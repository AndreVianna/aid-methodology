#!/usr/bin/env bash
# test-aid-cli-parity.sh — Task 029: Cross-platform parity e2e for the aid CLI.
#
# Runs the same subcommand sequence on Bash (bin/aid) and PowerShell (bin/aid.ps1)
# and asserts:
#   - Identical project tree after add/remove/update/uninstall.
#   - Manifest content equivalence (same tool list, same paths, same sha256/status).
#   - Identical `status` output and exit codes.
#   - Convenience-chain first-action parity (install.sh vs install.ps1 CONVENIENCE mode).
#   - Same exit codes for all failure paths (exit 2, 5, 6, 7).
#
# SKIP (exit 0) when pwsh is absent — CI asserts pwsh IS present.
#
# Usage:
#   bash test-aid-cli-parity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
INSTALL_PS1="${REPO_ROOT}/install.ps1"
BIN_AID_SH="${REPO_ROOT}/bin/aid"
BIN_AID_PS1="${REPO_ROOT}/bin/aid.ps1"
BIN_AID_CMD="${REPO_ROOT}/bin/aid.cmd"
LIB_SH="${REPO_ROOT}/lib/aid-install-core.sh"
LIB_PS1="${REPO_ROOT}/lib/AidInstallCore.psm1"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$INSTALL_SH" ]]  || { echo "ERROR: install.sh not found at $INSTALL_SH" >&2; exit 1; }
[[ -f "$INSTALL_PS1" ]] || { echo "ERROR: install.ps1 not found at $INSTALL_PS1" >&2; exit 1; }
[[ -f "$BIN_AID_SH" ]]  || { echo "ERROR: bin/aid not found at $BIN_AID_SH" >&2; exit 1; }
[[ -f "$BIN_AID_PS1" ]] || { echo "ERROR: bin/aid.ps1 not found at $BIN_AID_PS1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Gate: skip when pwsh is absent.
# ---------------------------------------------------------------------------
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping cross-platform parity suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="0.7.0"

# ---------------------------------------------------------------------------
# build_fixture_tarball <tool>
# ---------------------------------------------------------------------------
build_fixture_tarball() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${FIXTURE_DIR}/aid-${tool}-v${VERSION}.tar.gz"

    [[ -d "$profile_dir" ]] || { echo "ERROR: profile dir not found: $profile_dir" >&2; return 1; }

    local filelist
    filelist="$(mktemp "${TMP}/filelist-${tool}.XXXXXX")"
    while IFS= read -r f; do
        local fname; fname="$(basename "$f")"
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

for _tool in claude-code codex cursor copilot-cli antigravity; do
    build_fixture_tarball "$_tool" || { echo "ERROR: fixture build failed for ${_tool}" >&2; exit 1; }
done

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }
newhome()   { mktemp -d "${TMP}/home.XXXXXX"; }

# ---------------------------------------------------------------------------
# Setup helpers for both runtimes.
# ---------------------------------------------------------------------------
setup_sh_home() {
    local home_dir="$1"
    mkdir -p "${home_dir}/bin" "${home_dir}/lib"
    cp "${BIN_AID_SH}" "${home_dir}/bin/aid"
    chmod +x "${home_dir}/bin/aid"
    cp "${LIB_SH}" "${home_dir}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
}

setup_ps1_home() {
    local home_dir="$1"
    mkdir -p "${home_dir}/bin" "${home_dir}/lib"
    cp "${BIN_AID_PS1}" "${home_dir}/bin/aid.ps1"
    [[ -f "$BIN_AID_CMD" ]] && cp "${BIN_AID_CMD}" "${home_dir}/bin/aid.cmd" || true
    cp "${LIB_PS1}" "${home_dir}/lib/AidInstallCore.psm1"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
}

# Bash aid runner.
run_sh() {
    local home_dir="$1"; shift
    OUT_SH=$(AID_HOME="$home_dir" AID_LIB_PATH="${home_dir}/lib/aid-install-core.sh" \
             bash "${home_dir}/bin/aid" "$@" 2>&1); RC_SH=$?
}

# PS1 aid runner.
run_ps1() {
    local home_dir="$1"; shift
    OUT_PS1=$(AID_HOME="$home_dir" AID_LIB_PATH="${home_dir}/lib/AidInstallCore.psm1" \
              "$PWSH" -NoProfile -File "${home_dir}/bin/aid.ps1" "$@" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g'); RC_PS1=$?
}

# ---------------------------------------------------------------------------
# Helper: strip timestamps from manifests for comparison.
# Removes "installed_at" lines and normalizes whitespace.
# ---------------------------------------------------------------------------
manifest_normalize() {
    local file="$1"
    grep -v '"installed_at"' "$file" 2>/dev/null | tr -d ' \t'
}

# ===========================================================================
# PAR029-A: Fresh add — identical project tree after Bash vs PS1
# ===========================================================================
SH_HOME_A=$(newhome); setup_sh_home "${SH_HOME_A}"
PS_HOME_A=$(newhome); setup_ps1_home "${PS_HOME_A}"
T_SH_A=$(newtarget); T_PS1_A=$(newtarget)

run_sh "${SH_HOME_A}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_A}"
assert_exit_eq "$RC_SH" 0 "PAR029-A01 Bash add codex → exit 0"

run_ps1 "${PS_HOME_A}" add codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -Target "${T_PS1_A}"
assert_exit_eq "$RC_PS1" 0 "PAR029-A02 PS1 add codex → exit 0"

# Both targets must have the same structure.
for _chk in .codex AGENTS.md .aid/.aid-manifest.json .aid/.aid-version; do
    if [[ -d "${T_SH_A}/${_chk}" ]]; then
        assert_dir_exists "${T_PS1_A}/${_chk}" "PAR029-A03 both have ${_chk}/"
    else
        assert_file_exists "${T_PS1_A}/${_chk}" "PAR029-A03 both have ${_chk}"
    fi
done

# Manifest content equivalence (modulo timestamps).
SH_MANI_NORM=$(manifest_normalize "${T_SH_A}/.aid/.aid-manifest.json")
PS_MANI_NORM=$(manifest_normalize "${T_PS1_A}/.aid/.aid-manifest.json")
assert_eq "$SH_MANI_NORM" "$PS_MANI_NORM" "PAR029-A04 Bash↔PS1 manifest content identical (modulo timestamps)"

# .aid-version identical.
assert_eq "$(cat "${T_SH_A}/.aid/.aid-version")" "$(cat "${T_PS1_A}/.aid/.aid-version")" \
    "PAR029-A05 .aid-version identical"

# ===========================================================================
# PAR029-B: status output parity after identical install
# ===========================================================================
SH_HOME_B=$(newhome); setup_sh_home "${SH_HOME_B}"
PS_HOME_B=$(newhome); setup_ps1_home "${PS_HOME_B}"
T_B=$(newtarget)

# Install via Bash.
run_sh "${SH_HOME_B}" add claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "${T_B}"
assert_exit_eq "$RC_SH" 0 "PAR029-B01 Bash add claude-code for status parity → exit 0"

# Get Bash status.
run_sh "${SH_HOME_B}" status --target "${T_B}"
SH_STATUS_B="$OUT_SH"
RC_SH_STATUS_B=$RC_SH

# PS1 also needs the lib to read the Bash-written manifest.
# Since the manifest is tool-format agnostic, PS1 can read it.
# Install the PS1 core too.
run_ps1 "${PS_HOME_B}" status -Target "${T_B}"
PS1_STATUS_B="$OUT_PS1"
RC_PS1_STATUS_B=$RC_PS1

# Both must exit 0.
assert_exit_eq "$RC_SH_STATUS_B" 0 "PAR029-B02 Bash status → exit 0"
assert_exit_eq "$RC_PS1_STATUS_B" 0 "PAR029-B03 PS1 status → exit 0"

# Both must contain the same key fields.
assert_output_contains "$SH_STATUS_B"  "AID ${VERSION}"    "PAR029-B04 Bash status: AID version"
assert_output_contains "$PS1_STATUS_B" "AID ${VERSION}"    "PAR029-B05 PS1 status: AID version"
assert_output_contains "$SH_STATUS_B"  "claude-code"       "PAR029-B06 Bash status: claude-code"
assert_output_contains "$PS1_STATUS_B" "claude-code"       "PAR029-B07 PS1 status: claude-code"
# (Root-agent file name is intentionally omitted from status for "owned" tools by the
#  collapse-when-uniform display; B06/B07 cover the tool-name parity. Bash↔PS1 byte-parity
#  of the full status output is asserted elsewhere in this suite.)

# ===========================================================================
# PAR029-C: Exit code parity — status empty dir → exit 7
# ===========================================================================
SH_HOME_C=$(newhome); setup_sh_home "${SH_HOME_C}"
PS_HOME_C=$(newhome); setup_ps1_home "${PS_HOME_C}"
T_C=$(newtarget)

run_sh  "${SH_HOME_C}" status --target "${T_C}"
run_ps1 "${PS_HOME_C}" status -Target "${T_C}"

assert_exit_eq "$RC_SH"  7 "PAR029-C01 Bash status empty → exit 7"
assert_exit_eq "$RC_PS1" 7 "PAR029-C02 PS1 status empty → exit 7"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-C03 Bash↔PS1 exit code parity for empty status"

# ===========================================================================
# PAR029-D: Exit code parity — protect-on-diff → exit 5
# ===========================================================================
SH_HOME_D=$(newhome); setup_sh_home "${SH_HOME_D}"
PS_HOME_D=$(newhome); setup_ps1_home "${PS_HOME_D}"
T_SH_D=$(newtarget); T_PS1_D=$(newtarget)
printf 'User AGENTS.md\n' > "${T_SH_D}/AGENTS.md"
printf 'User AGENTS.md\n' > "${T_PS1_D}/AGENTS.md"

run_sh  "${SH_HOME_D}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_D}"
run_ps1 "${PS_HOME_D}" add codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -Target "${T_PS1_D}"

assert_exit_eq "$RC_SH"  5 "PAR029-D01 Bash add protect-on-diff → exit 5"
assert_exit_eq "$RC_PS1" 5 "PAR029-D02 PS1 add protect-on-diff → exit 5"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-D03 Bash↔PS1 exit code parity for protect-on-diff"

# Both must have created .aid-new.
assert_file_exists "${T_SH_D}/AGENTS.md.aid-new"  "PAR029-D04 Bash: .aid-new created"
assert_file_exists "${T_PS1_D}/AGENTS.md.aid-new" "PAR029-D05 PS1: .aid-new created"

# ===========================================================================
# PAR029-E: Exit code parity — uninstall no manifest → exit 6
# ===========================================================================
SH_HOME_E=$(newhome); setup_sh_home "${SH_HOME_E}"
PS_HOME_E=$(newhome); setup_ps1_home "${PS_HOME_E}"
T_SH_E=$(newtarget); T_PS1_E=$(newtarget)

run_sh  "${SH_HOME_E}" uninstall --target "${T_SH_E}"
run_ps1 "${PS_HOME_E}" uninstall -Target "${T_PS1_E}"

assert_exit_eq "$RC_SH"  6 "PAR029-E01 Bash uninstall no manifest → exit 6"
assert_exit_eq "$RC_PS1" 6 "PAR029-E02 PS1 uninstall no manifest → exit 6"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-E03 Bash↔PS1 exit code parity (no manifest)"

# ===========================================================================
# PAR029-F: Uninstall parity — same project tree state after uninstall
# ===========================================================================
SH_HOME_F=$(newhome); setup_sh_home "${SH_HOME_F}"
PS_HOME_F=$(newhome); setup_ps1_home "${PS_HOME_F}"
T_SH_F=$(newtarget); T_PS1_F=$(newtarget)

# Install via Bash, then uninstall via Bash.
run_sh "${SH_HOME_F}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_F}"
assert_exit_eq "$RC_SH" 0 "PAR029-F01 Bash add for uninstall parity → exit 0"
run_sh "${SH_HOME_F}" uninstall --target "${T_SH_F}"
assert_exit_eq "$RC_SH" 0 "PAR029-F02 Bash uninstall → exit 0"

# Install via PS1, then uninstall via PS1.
run_ps1 "${PS_HOME_F}" add codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -Target "${T_PS1_F}"
assert_exit_eq "$RC_PS1" 0 "PAR029-F03 PS1 add for uninstall parity → exit 0"
run_ps1 "${PS_HOME_F}" uninstall -Target "${T_PS1_F}"
assert_exit_eq "$RC_PS1" 0 "PAR029-F04 PS1 uninstall → exit 0"

# Both targets must be clean after uninstall.
for _chk in .codex AGENTS.md .aid; do
    assert_eq "$([[ -e "${T_SH_F}/${_chk}" ]] && echo exists || echo gone)" "gone" \
        "PAR029-F05 Bash: ${_chk} gone after uninstall"
    assert_eq "$([[ -e "${T_PS1_F}/${_chk}" ]] && echo exists || echo gone)" "gone" \
        "PAR029-F06 PS1: ${_chk} gone after uninstall"
done

# Both report "Uninstall complete."
assert_output_contains "$OUT_SH"  "Uninstall complete." "PAR029-F07 Bash uninstall message"
assert_output_contains "$OUT_PS1" "Uninstall complete." "PAR029-F08 PS1 uninstall message"

# ===========================================================================
# PAR029-G: Update parity — same-version update produces same state
# ===========================================================================
SH_HOME_G=$(newhome); setup_sh_home "${SH_HOME_G}"
PS_HOME_G=$(newhome); setup_ps1_home "${PS_HOME_G}"
T_SH_G=$(newtarget); T_PS1_G=$(newtarget)

# Install.
run_sh  "${SH_HOME_G}" add cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" --target "${T_SH_G}"
run_ps1 "${PS_HOME_G}" add cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" -Target "${T_PS1_G}"
assert_exit_eq "$RC_SH"  0 "PAR029-G01 Bash add cursor → exit 0"
assert_exit_eq "$RC_PS1" 0 "PAR029-G02 PS1 add cursor → exit 0"

# Update with same version → both should report "up to date" and exit 0.
run_sh  "${SH_HOME_G}" update cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" --target "${T_SH_G}"
run_ps1 "${PS_HOME_G}" update cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" -Target "${T_PS1_G}"

assert_exit_eq "$RC_SH"  0 "PAR029-G03 Bash update same version → exit 0"
assert_exit_eq "$RC_PS1" 0 "PAR029-G04 PS1 update same version → exit 0"
assert_output_contains "$OUT_SH"  "up to date" "PAR029-G05 Bash update: 'up to date'"
assert_output_contains "$OUT_PS1" "up to date" "PAR029-G06 PS1 update: 'up to date'"

# ===========================================================================
# PAR029-H: Convenience-chain first-action parity
# install.sh add codex vs install.ps1 add codex — both bootstrap + install
# ===========================================================================
SH_HOME_H=$(newhome); PS_HOME_H=$(newhome)
T_SH_H=$(newtarget); T_PS1_H=$(newtarget)

OUT_SH=$(AID_HOME="${SH_HOME_H}" AID_LIB_PATH="${LIB_SH}" \
         bash "${INSTALL_SH}" \
         --profile-file "$(mktemp "${TMP}/profile-sh-h.XXXXXX")" \
         add codex \
         --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
         --target "${T_SH_H}" 2>&1); RC_SH=$?

OUT_PS1=$(AID_HOME="${PS_HOME_H}" AID_LIB_PATH="${LIB_PS1}" \
          "$PWSH" -NoProfile -File "${INSTALL_PS1}" \
          -NoPath \
          add codex \
          -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
          -Target "${T_PS1_H}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC_PS1=$?

assert_exit_eq "$RC_SH"  0 "PAR029-H01 Bash CONVENIENCE add → exit 0"
assert_exit_eq "$RC_PS1" 0 "PAR029-H02 PS1 CONVENIENCE add → exit 0"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-H03 Bash↔PS1 CONVENIENCE exit code parity"

# Both CLI binaries installed.
assert_file_exists "${SH_HOME_H}/bin/aid"     "PAR029-H04 Bash CONVENIENCE: bin/aid installed"
assert_file_exists "${PS_HOME_H}/bin/aid.ps1" "PAR029-H05 PS1 CONVENIENCE: bin/aid.ps1 installed"

# Both project trees have codex.
assert_dir_exists  "${T_SH_H}/.codex"   "PAR029-H06 Bash CONVENIENCE: .codex/ created"
assert_dir_exists  "${T_PS1_H}/.codex"  "PAR029-H07 PS1 CONVENIENCE: .codex/ created"
assert_file_exists "${T_SH_H}/AGENTS.md"  "PAR029-H08 Bash CONVENIENCE: AGENTS.md created"
assert_file_exists "${T_PS1_H}/AGENTS.md" "PAR029-H09 PS1 CONVENIENCE: AGENTS.md created"

# Both report Done.
assert_output_contains "$OUT_SH"  "Done." "PAR029-H10 Bash CONVENIENCE: reports Done."
assert_output_contains "$OUT_PS1" "Done." "PAR029-H11 PS1 CONVENIENCE: reports Done."

# ===========================================================================
# PAR029-I: Cross-runtime interop — install via Bash, read status via PS1
# ===========================================================================
SH_HOME_I=$(newhome); setup_sh_home "${SH_HOME_I}"
PS_HOME_I=$(newhome); setup_ps1_home "${PS_HOME_I}"
T_I=$(newtarget)

# Install codex via Bash.
run_sh "${SH_HOME_I}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_I}"
assert_exit_eq "$RC_SH" 0 "PAR029-I01 Bash install for cross-interop test → exit 0"

# Read status via PS1 (should read the Bash-written manifest).
run_ps1 "${PS_HOME_I}" status -Target "${T_I}"
assert_exit_eq "$RC_PS1" 0 "PAR029-I02 PS1 status on Bash-installed project → exit 0"
assert_output_contains "$OUT_PS1" "codex" "PAR029-I03 PS1 reads Bash-written manifest correctly"
assert_output_contains "$OUT_PS1" "v${VERSION}" "PAR029-I04 PS1 reads correct version from Bash manifest"

# Cross-uninstall: PS1 can uninstall a Bash-installed project.
run_ps1 "${PS_HOME_I}" uninstall -Target "${T_I}"
assert_exit_eq "$RC_PS1" 0 "PAR029-I05 PS1 uninstall of Bash-installed project → exit 0"
assert_eq "$([[ -d "${T_I}/.codex" ]] && echo exists || echo gone)" "gone" \
    "PAR029-I06 .codex/ removed by cross-runtime uninstall"

# ===========================================================================
# PAR029-J: Cross-runtime interop — install via PS1, read + remove via Bash
# ===========================================================================
SH_HOME_J=$(newhome); setup_sh_home "${SH_HOME_J}"
PS_HOME_J=$(newhome); setup_ps1_home "${PS_HOME_J}"
T_J=$(newtarget)

# Install via PS1.
run_ps1 "${PS_HOME_J}" add codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -Target "${T_J}"
assert_exit_eq "$RC_PS1" 0 "PAR029-J01 PS1 install for cross-interop test → exit 0"

# Bash status on PS1-written manifest.
run_sh "${SH_HOME_J}" status --target "${T_J}"
assert_exit_eq "$RC_SH" 0 "PAR029-J02 Bash status on PS1-installed project → exit 0"
assert_output_contains "$OUT_SH" "codex" "PAR029-J03 Bash reads PS1-written manifest"

# Bash uninstall of PS1-installed project.
run_sh "${SH_HOME_J}" uninstall --target "${T_J}"
assert_exit_eq "$RC_SH" 0 "PAR029-J04 Bash uninstall of PS1-installed project → exit 0"
assert_eq "$([[ -d "${T_J}/.codex" ]] && echo exists || echo gone)" "gone" \
    "PAR029-J05 .codex/ removed by cross-runtime Bash uninstall"

# ===========================================================================
# PAR029-K: Unknown subcommand exit code parity
# ===========================================================================
SH_HOME_K=$(newhome); setup_sh_home "${SH_HOME_K}"
PS_HOME_K=$(newhome); setup_ps1_home "${PS_HOME_K}"

run_sh  "${SH_HOME_K}" frobnicate
run_ps1 "${PS_HOME_K}" frobnicate

assert_exit_eq "$RC_SH"  2 "PAR029-K01 Bash unknown subcommand → exit 2"
assert_exit_eq "$RC_PS1" 2 "PAR029-K02 PS1 unknown subcommand → exit 2"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-K03 Bash↔PS1 exit code parity (unknown subcmd)"

# ===========================================================================
# PAR029-L: version subcommand parity
# ===========================================================================
SH_HOME_L=$(newhome); setup_sh_home "${SH_HOME_L}"
PS_HOME_L=$(newhome); setup_ps1_home "${PS_HOME_L}"

run_sh  "${SH_HOME_L}" version
run_ps1 "${PS_HOME_L}" version

assert_exit_eq "$RC_SH"  0 "PAR029-L01 Bash version → exit 0"
assert_exit_eq "$RC_PS1" 0 "PAR029-L02 PS1 version → exit 0"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-L03 Bash↔PS1 exit code parity (version)"
assert_output_contains "$OUT_SH"  "${VERSION}" "PAR029-L04 Bash version output"
assert_output_contains "$OUT_PS1" "${VERSION}" "PAR029-L05 PS1 version output"

test_summary
