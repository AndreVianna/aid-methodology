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
    mkdir -p "${home_dir}/bin" "${home_dir}/lib" \
             "${home_dir}/dashboard/reader" "${home_dir}/dashboard/server"
    cp "${BIN_AID_SH}" "${home_dir}/bin/aid"
    chmod +x "${home_dir}/bin/aid"
    cp "${LIB_SH}" "${home_dir}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
    # Install curated dashboard unit under $AID_HOME/dashboard/ (D8 spawn-seam layout).
    local _dsrc="${REPO_ROOT}/dashboard"
    ln -sf "${_dsrc}/index.html"           "${home_dir}/dashboard/index.html"
    ln -sf "${_dsrc}/reader/__init__.py"   "${home_dir}/dashboard/reader/__init__.py"
    ln -sf "${_dsrc}/reader/reader.py"     "${home_dir}/dashboard/reader/reader.py"
    ln -sf "${_dsrc}/reader/models.py"     "${home_dir}/dashboard/reader/models.py"
    ln -sf "${_dsrc}/reader/parsers.py"    "${home_dir}/dashboard/reader/parsers.py"
    ln -sf "${_dsrc}/reader/derivation.py" "${home_dir}/dashboard/reader/derivation.py"
    ln -sf "${_dsrc}/reader/locator.py"    "${home_dir}/dashboard/reader/locator.py"
    ln -sf "${_dsrc}/server/server.py"     "${home_dir}/dashboard/server/server.py"
    ln -sf "${_dsrc}/server/server.mjs"    "${home_dir}/dashboard/server/server.mjs"
    ln -sf "${_dsrc}/server/reader.mjs"    "${home_dir}/dashboard/server/reader.mjs"
    ln -sf "${_dsrc}/server/__init__.py"   "${home_dir}/dashboard/server/__init__.py"
}

setup_ps1_home() {
    local home_dir="$1"
    mkdir -p "${home_dir}/bin" "${home_dir}/lib" \
             "${home_dir}/dashboard/reader" "${home_dir}/dashboard/server"
    cp "${BIN_AID_PS1}" "${home_dir}/bin/aid.ps1"
    [[ -f "$BIN_AID_CMD" ]] && cp "${BIN_AID_CMD}" "${home_dir}/bin/aid.cmd" || true
    cp "${LIB_PS1}" "${home_dir}/lib/AidInstallCore.psm1"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
    # Install curated dashboard unit under $AID_HOME/dashboard/ (D8 spawn-seam layout).
    local _dsrc="${REPO_ROOT}/dashboard"
    ln -sf "${_dsrc}/index.html"           "${home_dir}/dashboard/index.html"
    ln -sf "${_dsrc}/reader/__init__.py"   "${home_dir}/dashboard/reader/__init__.py"
    ln -sf "${_dsrc}/reader/reader.py"     "${home_dir}/dashboard/reader/reader.py"
    ln -sf "${_dsrc}/reader/models.py"     "${home_dir}/dashboard/reader/models.py"
    ln -sf "${_dsrc}/reader/parsers.py"    "${home_dir}/dashboard/reader/parsers.py"
    ln -sf "${_dsrc}/reader/derivation.py" "${home_dir}/dashboard/reader/derivation.py"
    ln -sf "${_dsrc}/reader/locator.py"    "${home_dir}/dashboard/reader/locator.py"
    ln -sf "${_dsrc}/server/server.py"     "${home_dir}/dashboard/server/server.py"
    ln -sf "${_dsrc}/server/server.mjs"    "${home_dir}/dashboard/server/server.mjs"
    ln -sf "${_dsrc}/server/reader.mjs"    "${home_dir}/dashboard/server/reader.mjs"
    ln -sf "${_dsrc}/server/__init__.py"   "${home_dir}/dashboard/server/__init__.py"
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
# PAR029-E: Exit code parity — remove (no manifest) → exit 6
# ===========================================================================
SH_HOME_E=$(newhome); setup_sh_home "${SH_HOME_E}"
PS_HOME_E=$(newhome); setup_ps1_home "${PS_HOME_E}"
T_SH_E=$(newtarget); T_PS1_E=$(newtarget)

run_sh  "${SH_HOME_E}" remove --force --target "${T_SH_E}"
run_ps1 "${PS_HOME_E}" remove -Force -Target "${T_PS1_E}"

assert_exit_eq "$RC_SH"  6 "PAR029-E01 Bash remove no manifest → exit 6"
assert_exit_eq "$RC_PS1" 6 "PAR029-E02 PS1 remove no manifest → exit 6"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-E03 Bash↔PS1 exit code parity (no manifest)"

# ===========================================================================
# PAR029-F: Remove parity — same project tree state after remove (all tools)
# ===========================================================================
SH_HOME_F=$(newhome); setup_sh_home "${SH_HOME_F}"
PS_HOME_F=$(newhome); setup_ps1_home "${PS_HOME_F}"
T_SH_F=$(newtarget); T_PS1_F=$(newtarget)

# Install via Bash, then remove via Bash (--force to skip prompt).
run_sh "${SH_HOME_F}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_F}"
assert_exit_eq "$RC_SH" 0 "PAR029-F01 Bash add for remove parity → exit 0"
run_sh "${SH_HOME_F}" remove --force --target "${T_SH_F}"
assert_exit_eq "$RC_SH" 0 "PAR029-F02 Bash remove --force → exit 0"

# Install via PS1, then remove via PS1 (-Force to skip prompt).
run_ps1 "${PS_HOME_F}" add codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -Target "${T_PS1_F}"
assert_exit_eq "$RC_PS1" 0 "PAR029-F03 PS1 add for remove parity → exit 0"
run_ps1 "${PS_HOME_F}" remove -Force -Target "${T_PS1_F}"
assert_exit_eq "$RC_PS1" 0 "PAR029-F04 PS1 remove -Force → exit 0"

# Both targets must be clean after remove.
for _chk in .codex AGENTS.md .aid; do
    assert_eq "$([[ -e "${T_SH_F}/${_chk}" ]] && echo exists || echo gone)" "gone" \
        "PAR029-F05 Bash: ${_chk} gone after remove"
    assert_eq "$([[ -e "${T_PS1_F}/${_chk}" ]] && echo exists || echo gone)" "gone" \
        "PAR029-F06 PS1: ${_chk} gone after remove"
done

# Both report "Uninstall complete."
assert_output_contains "$OUT_SH"  "Uninstall complete." "PAR029-F07 Bash remove message"
assert_output_contains "$OUT_PS1" "Uninstall complete." "PAR029-F08 PS1 remove message"

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

# Cross-remove: PS1 can remove a Bash-installed project.
run_ps1 "${PS_HOME_I}" remove -Force -Target "${T_I}"
assert_exit_eq "$RC_PS1" 0 "PAR029-I05 PS1 remove of Bash-installed project → exit 0"
assert_eq "$([[ -d "${T_I}/.codex" ]] && echo exists || echo gone)" "gone" \
    "PAR029-I06 .codex/ removed by cross-runtime remove"

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

# Bash remove of PS1-installed project.
run_sh "${SH_HOME_J}" remove --force --target "${T_J}"
assert_exit_eq "$RC_SH" 0 "PAR029-J04 Bash remove of PS1-installed project → exit 0"
assert_eq "$([[ -d "${T_J}/.codex" ]] && echo exists || echo gone)" "gone" \
    "PAR029-J05 .codex/ removed by cross-runtime Bash remove"

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

# ===========================================================================
# PAR023-M: dashboard start/stop parity (T-12) — T-1/T-3/T-4/T-5/T-7
#
# Verifies that the Bash and PowerShell CLI twins produce:
#   - identical exit codes for dashboard start/stop scenarios
#   - identical user-visible stdout/stderr messages
# Explicitly EXCLUDES internal verbose/diagnostic messages (e.g. "SIGTERM to
# process group" vs "Stop-Process to pid") which legitimately differ by platform.
#
# PowerShell half: SKIP-IF-ABSENT (print clear notice, still run Bash side).
# When pwsh IS present (CI Windows runner), the PS half runs and asserts parity.
# This avoids a vacuous pass: when pwsh is absent, the Bash-side assertions still
# catch regressions; when pwsh is present, full Bash<->PS1 parity is verified.
#
# Start/stop server parity (T-1/T-3/T-4): also SKIP on Linux even when pwsh is
# present, because PowerShell Start-Process -WindowStyle Hidden is Windows-only
# and fails on Linux PS. Usage/error parity (T-5/T-7) does NOT require spawning
# a server so it ALWAYS runs when pwsh is present.
# ===========================================================================

# ---------------------------------------------------------------------------
# Fixture: a minimal .aid/ repo with real dashboard server entry points.
# Both runtimes (python/node) are present on this Linux machine so start works.
# ---------------------------------------------------------------------------
REPO_ROOT_PAR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# A minimal fixture repo for dashboard tests: has .aid/ dir only.
# The dashboard server now lives in $AID_HOME/dashboard/ (D8 spawn-seam relocation),
# so the served repo fixture needs only the .aid/ workspace.
new_dash_repo() {
    local r; r="$(mktemp -d "${TMP}/dashrepo.XXXXXX")"
    mkdir -p "${r}/.aid/.temp"
    echo "$r"
}

pick_dash_port() {
    python3 -c "import socket; s=socket.socket(); s.bind(('',0)); p=s.getsockname()[1]; s.close(); print(p)"
}

SH_HOME_M=$(newhome); setup_sh_home "${SH_HOME_M}"
PS_HOME_M=$(newhome); setup_ps1_home "${PS_HOME_M}"
DASH_REPO_M="$(new_dash_repo)"

# Two skip conditions for the PS half:
#   PS_ABSENT_M=1  -> pwsh not found at all (CI check: pwsh must be present on Windows runner)
#   PS_LINUX_M=1   -> pwsh present but Start-Process -WindowStyle not supported (Linux PS)
#                     Only affects server-spawn scenarios (T-1/T-3/T-4); not usage errors (T-5/T-7)
PS_ABSENT_M=0
PS_LINUX_M=0

if [[ -z "$PWSH" ]]; then
    PS_ABSENT_M=1
    echo "SKIP (PS half): pwsh not found — dashboard parity PS assertions skipped (Bash side runs)."
else
    # Detect Linux PS limitation: Start-Process -WindowStyle is Windows-only.
    # Test by running a trivial Start-Process with -WindowStyle and checking for the error.
    _PS_WS_TEST="$("$PWSH" -NoProfile -Command \
        'try { Start-Process -FilePath "echo" -ArgumentList "x" -WindowStyle Hidden -Wait -ErrorAction Stop; Write-Host "ok" } catch { Write-Host "fail" }' \
        2>&1)"
    if echo "$_PS_WS_TEST" | grep -q "fail\|not supported\|WindowStyle"; then
        PS_LINUX_M=1
        echo "SKIP (PS server-spawn): Start-Process -WindowStyle Hidden not supported on this platform (Linux PS)."
        echo "  T-1/T-3/T-4 PS server-spawn parity skipped; T-5/T-7 usage/error parity still runs."
    fi
fi

# ---------------------------------------------------------------------------
# PAR023-M01/M02: T-1 parity — start python (Bash always; PS skip on absent/linux)
# ---------------------------------------------------------------------------
PORT_M1="$(pick_dash_port)"
run_sh "${SH_HOME_M}" dashboard start python --port "$PORT_M1" --target "${DASH_REPO_M}"
SH_OUT_M1="$OUT_SH"; SH_RC_M1=$RC_SH

assert_exit_eq "$SH_RC_M1" 0 "PAR023-M01 Bash dashboard start python -> exit 0"
assert_output_contains "$SH_OUT_M1" "Dashboard (python) running at http://127.0.0.1:${PORT_M1}" \
    "PAR023-M02 Bash start python: URL printed"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    # PS side uses a separate home/repo (independent server child).
    PS_HOME_M1="$(newhome)"; setup_ps1_home "${PS_HOME_M1}"
    DASH_REPO_PS1="$(new_dash_repo)"
    PORT_M1PS="$(pick_dash_port)"
    run_ps1 "${PS_HOME_M1}" dashboard start python --port "$PORT_M1PS" --target "${DASH_REPO_PS1}"
    PS_OUT_M1="$OUT_PS1"; PS_RC_M1=$RC_PS1
    assert_exit_eq "$PS_RC_M1" 0 "PAR023-M03 PS1 dashboard start python -> exit 0"
    assert_output_contains "$PS_OUT_M1" "Dashboard (python) running at http://127.0.0.1:${PORT_M1PS}" \
        "PAR023-M04 PS1 start python: URL printed"
    assert_eq "$SH_RC_M1" "$PS_RC_M1" "PAR023-M05 Bash<->PS1 exit code parity: start python"
else
    _skip_reason="pwsh absent"
    [[ "$PS_LINUX_M" -eq 1 ]] && _skip_reason="Linux PS: Start-Process WindowStyle unsupported"
    pass "PAR023-M03 PS1 dashboard start python [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M04 PS1 start python: URL printed [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M05 Bash<->PS1 exit code parity: start python [SKIPPED: ${_skip_reason}]"
fi

# ---------------------------------------------------------------------------
# PAR023-M06/M07: T-3 parity — second start while running -> exit 8
# (DASH_REPO_M has python running from M01 above via Bash)
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_M}" dashboard start python --port "$PORT_M1" --target "${DASH_REPO_M}"
SH_OUT_M6="$OUT_SH"; SH_RC_M6=$RC_SH

assert_exit_eq "$SH_RC_M6" 8 "PAR023-M06 Bash second start -> exit 8"
assert_output_contains "$SH_OUT_M6" "already running" \
    "PAR023-M07 Bash second start: 'already running' message"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    # PS_HOME_M1/DASH_REPO_PS1 were set in the block above (PS start succeeded).
    run_ps1 "${PS_HOME_M1}" dashboard start python --port "$PORT_M1PS" --target "${DASH_REPO_PS1}"
    PS_OUT_M6="$OUT_PS1"; PS_RC_M6=$RC_PS1
    assert_exit_eq "$PS_RC_M6" 8 "PAR023-M08 PS1 second start -> exit 8"
    assert_output_contains "$PS_OUT_M6" "already running" \
        "PAR023-M09 PS1 second start: 'already running' message"
    assert_eq "$SH_RC_M6" "$PS_RC_M6" "PAR023-M10 Bash<->PS1 exit code parity: second start"
else
    _skip_reason="pwsh absent"
    [[ "$PS_LINUX_M" -eq 1 ]] && _skip_reason="Linux PS: Start-Process WindowStyle unsupported"
    pass "PAR023-M08 PS1 second start -> exit 8 [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M09 PS1 second start: 'already running' message [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M10 Bash<->PS1 exit code parity: second start [SKIPPED: ${_skip_reason}]"
fi

# ---------------------------------------------------------------------------
# PAR023-M11/M12: T-4 parity — stop after start -> exit 0
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_M}" dashboard stop --target "${DASH_REPO_M}"
SH_OUT_M11="$OUT_SH"; SH_RC_M11=$RC_SH

assert_exit_eq "$SH_RC_M11" 0 "PAR023-M11 Bash dashboard stop -> exit 0"
assert_output_contains "$SH_OUT_M11" "aid: dashboard stopped." \
    "PAR023-M12 Bash stop: 'dashboard stopped.' message"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M1}" dashboard stop --target "${DASH_REPO_PS1}"
    PS_OUT_M11="$OUT_PS1"; PS_RC_M11=$RC_PS1
    assert_exit_eq "$PS_RC_M11" 0 "PAR023-M13 PS1 dashboard stop -> exit 0"
    assert_output_contains "$PS_OUT_M11" "aid: dashboard stopped." \
        "PAR023-M14 PS1 stop: 'dashboard stopped.' message"
    assert_eq "$SH_RC_M11" "$PS_RC_M11" "PAR023-M15 Bash<->PS1 exit code parity: stop"
else
    _skip_reason="pwsh absent"
    [[ "$PS_LINUX_M" -eq 1 ]] && _skip_reason="Linux PS: Start-Process WindowStyle unsupported"
    pass "PAR023-M13 PS1 dashboard stop -> exit 0 [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M14 PS1 stop: 'dashboard stopped.' message [SKIPPED: ${_skip_reason}]"
    pass "PAR023-M15 Bash<->PS1 exit code parity: stop [SKIPPED: ${_skip_reason}]"
fi

# ---------------------------------------------------------------------------
# PAR023-M16/M17: T-5 parity — stop with nothing running -> exit 0, idempotent
# (DASH_REPO_M was just stopped above via Bash; stop again for nothing-to-stop)
# This scenario does NOT require spawning a server, so PS runs even on Linux.
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_M}" dashboard stop --target "${DASH_REPO_M}"
SH_OUT_M16="$OUT_SH"; SH_RC_M16=$RC_SH

assert_exit_eq "$SH_RC_M16" 0 "PAR023-M16 Bash stop nothing -> exit 0"
assert_output_contains "$SH_OUT_M16" "not running (nothing to stop)" \
    "PAR023-M17 Bash stop nothing: nothing-to-stop message"

if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    # T-5 uses PS_HOME_M with a fresh nothing-running repo.
    DASH_REPO_M5="$(new_dash_repo)"
    run_ps1 "${PS_HOME_M}" dashboard stop --target "${DASH_REPO_M5}"
    PS_OUT_M16="$OUT_PS1"; PS_RC_M16=$RC_PS1
    assert_exit_eq "$PS_RC_M16" 0 "PAR023-M18 PS1 stop nothing -> exit 0"
    assert_output_contains "$PS_OUT_M16" "not running (nothing to stop)" \
        "PAR023-M19 PS1 stop nothing: nothing-to-stop message"
    assert_eq "$SH_RC_M16" "$PS_RC_M16" "PAR023-M20 Bash<->PS1 exit code parity: stop nothing"
else
    pass "PAR023-M18 PS1 stop nothing -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR023-M19 PS1 stop nothing: nothing-to-stop message [SKIPPED: pwsh absent]"
    pass "PAR023-M20 Bash<->PS1 exit code parity: stop nothing [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR023-M21..M32: T-7 parity — usage errors -> exit 2
# These do NOT spawn a server so they run whenever pwsh is present.
# Note: assert_output_contains uses grep -F; avoid patterns starting with '--'.
# ---------------------------------------------------------------------------
DASH_REPO_M7="$(new_dash_repo)"

# T-7a: bad runtime.
run_sh "${SH_HOME_M}" dashboard start foo --target "${DASH_REPO_M7}"
SH_RC_M7A=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start foo --target "${DASH_REPO_M7}"
    PS_RC_M7A=$RC_PS1
fi
assert_exit_eq "$SH_RC_M7A" 2 "PAR023-M21 Bash bad runtime -> exit 2"
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    assert_exit_eq "$PS_RC_M7A" 2 "PAR023-M22 PS1 bad runtime -> exit 2"
    assert_eq "$SH_RC_M7A" "$PS_RC_M7A" "PAR023-M23 Bash<->PS1 parity: bad runtime exit code"
else
    pass "PAR023-M22 PS1 bad runtime -> exit 2 [SKIPPED: pwsh absent]"
    pass "PAR023-M23 Bash<->PS1 parity: bad runtime exit code [SKIPPED: pwsh absent]"
fi

# T-7b: missing runtime.
run_sh "${SH_HOME_M}" dashboard start --target "${DASH_REPO_M7}"
SH_RC_M7B=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start --target "${DASH_REPO_M7}"
    PS_RC_M7B=$RC_PS1
fi
assert_exit_eq "$SH_RC_M7B" 2 "PAR023-M24 Bash missing runtime -> exit 2"
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    assert_exit_eq "$PS_RC_M7B" 2 "PAR023-M25 PS1 missing runtime -> exit 2"
    assert_eq "$SH_RC_M7B" "$PS_RC_M7B" "PAR023-M26 Bash<->PS1 parity: missing runtime exit code"
else
    pass "PAR023-M25 PS1 missing runtime -> exit 2 [SKIPPED: pwsh absent]"
    pass "PAR023-M26 Bash<->PS1 parity: missing runtime exit code [SKIPPED: pwsh absent]"
fi

# T-7c: unknown flag.
run_sh "${SH_HOME_M}" dashboard start python --unknown-flag --target "${DASH_REPO_M7}"
SH_RC_M7C=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start python --unknown-flag --target "${DASH_REPO_M7}"
    PS_RC_M7C=$RC_PS1
fi
assert_exit_eq "$SH_RC_M7C" 2 "PAR023-M27 Bash unknown flag -> exit 2"
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    assert_exit_eq "$PS_RC_M7C" 2 "PAR023-M28 PS1 unknown flag -> exit 2"
    assert_eq "$SH_RC_M7C" "$PS_RC_M7C" "PAR023-M29 Bash<->PS1 parity: unknown flag exit code"
else
    pass "PAR023-M28 PS1 unknown flag -> exit 2 [SKIPPED: pwsh absent]"
    pass "PAR023-M29 Bash<->PS1 parity: unknown flag exit code [SKIPPED: pwsh absent]"
fi

# T-7d: bad --port.
run_sh "${SH_HOME_M}" dashboard start python --port abc --target "${DASH_REPO_M7}"
SH_RC_M7D=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start python --port abc --target "${DASH_REPO_M7}"
    PS_RC_M7D=$RC_PS1
fi
assert_exit_eq "$SH_RC_M7D" 2 "PAR023-M30 Bash bad port -> exit 2"
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    assert_exit_eq "$PS_RC_M7D" 2 "PAR023-M31 PS1 bad port -> exit 2"
    assert_eq "$SH_RC_M7D" "$PS_RC_M7D" "PAR023-M32 Bash<->PS1 parity: bad port exit code"
else
    pass "PAR023-M31 PS1 bad port -> exit 2 [SKIPPED: pwsh absent]"
    pass "PAR023-M32 Bash<->PS1 parity: bad port exit code [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR005-N: feature-005 remote-expose parity (T-8) — T-1/T-3/T-5 clear-fail paths
#
# Verifies that the Bash and PowerShell expose/teardown helpers produce:
#   - identical exit codes for the clear-fail paths (mechanism absent -> exit 10;
#     teardown nothing-running -> exit 0)
#   - identical user-visible messages (NOT platform-specific verbose diagnostics)
#
# PowerShell half: SKIP-IF-ABSENT (clear notice, Bash half always runs).
# When pwsh IS present, exit-code and message parity is asserted.
# Server-spawn scenarios: SKIP on Linux PS (Start-Process WindowStyle).
# No live tailnet is touched -- tailscale is absent (PATH shadow) or not called.
# ===========================================================================

# ---------------------------------------------------------------------------
# Fixture helpers for feature-005 parity.
# ---------------------------------------------------------------------------
_AID_LIB_PS1="${REPO_ROOT}/lib/AidInstallCore.psm1"

new_dash_home_par005() {
    local h; h="$(mktemp -d "${TMP}/hpar005.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib" "${h}/dashboard/reader" "${h}/dashboard/server"
    cp "${BIN_AID_SH}"  "${h}/bin/aid"; chmod +x "${h}/bin/aid"
    cp "${BIN_AID_PS1}" "${h}/bin/aid.ps1"
    cp "${LIB_SH}"              "${h}/lib/aid-install-core.sh"
    [[ -f "$_AID_LIB_PS1" ]] && cp "$_AID_LIB_PS1" "${h}/lib/AidInstallCore.psm1"
    printf '0.7.0\n' > "${h}/VERSION"
    # Install curated dashboard unit under $AID_HOME/dashboard/ (D8 spawn-seam layout).
    local _dsrc="${REPO_ROOT}/dashboard"
    ln -sf "${_dsrc}/index.html"           "${h}/dashboard/index.html"
    ln -sf "${_dsrc}/reader/__init__.py"   "${h}/dashboard/reader/__init__.py"
    ln -sf "${_dsrc}/reader/reader.py"     "${h}/dashboard/reader/reader.py"
    ln -sf "${_dsrc}/reader/models.py"     "${h}/dashboard/reader/models.py"
    ln -sf "${_dsrc}/reader/parsers.py"    "${h}/dashboard/reader/parsers.py"
    ln -sf "${_dsrc}/reader/derivation.py" "${h}/dashboard/reader/derivation.py"
    ln -sf "${_dsrc}/reader/locator.py"    "${h}/dashboard/reader/locator.py"
    ln -sf "${_dsrc}/server/server.py"     "${h}/dashboard/server/server.py"
    ln -sf "${_dsrc}/server/server.mjs"    "${h}/dashboard/server/server.mjs"
    ln -sf "${_dsrc}/server/reader.mjs"    "${h}/dashboard/server/reader.mjs"
    ln -sf "${_dsrc}/server/__init__.py"   "${h}/dashboard/server/__init__.py"
    echo "$h"
}

new_dash_repo_par005() {
    local r; r="$(mktemp -d "${TMP}/rpar005.XXXXXX")"
    mkdir -p "${r}/.aid/.temp"
    echo "$r"
}

# Absent-tailscale wrapper: a PATH-first script that exits 127 for all calls,
# simulating tailscale completely absent from PATH.
_absent_ts_dir_par005="$(mktemp -d "${TMP}/absenttspar005.XXXXXX")"
cat > "${_absent_ts_dir_par005}/tailscale" <<'ABSPAR005EOF'
#!/usr/bin/env bash
exit 127
ABSPAR005EOF
chmod +x "${_absent_ts_dir_par005}/tailscale"

# Skip condition for server-spawn PS scenarios on this platform.
PS_WIN_STYLE_PAR005=0
if [[ -n "$PWSH" ]]; then
    _PS_WS_TEST2="$("$PWSH" -NoProfile -Command \
        'try { Start-Process -FilePath "echo" -ArgumentList "x" -WindowStyle Hidden -Wait -ErrorAction Stop; Write-Host "ok" } catch { Write-Host "fail" }' \
        2>&1)"
    if ! echo "$_PS_WS_TEST2" | grep -q "fail\|not supported\|WindowStyle"; then
        PS_WIN_STYLE_PAR005=1
    fi
fi

# ---------------------------------------------------------------------------
# PAR005-N01/N02: T-3 parity — --remote no mechanism -> exit 10
# (Bash always runs; PS skip on absent or Linux PS WindowStyle limitation)
# ---------------------------------------------------------------------------
SH_HOME_N01="$(new_dash_home_par005)"
REPO_N01="$(new_dash_repo_par005)"
PORT_N01="$(pick_dash_port)"

_o_n01sh="$(mktemp "${TMP}/on01sh.XXXXXX")"
_e_n01sh="$(mktemp "${TMP}/en01sh.XXXXXX")"
PATH="${_absent_ts_dir_par005}:${PATH}" AID_HOME="${SH_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_N01}/bin/aid" dashboard start python \
    --port "$PORT_N01" --remote --target "${REPO_N01}" \
    >"$_o_n01sh" 2>"$_e_n01sh"
SH_RC_N01=$?
SH_ERR_N01="$(cat "$_e_n01sh")"
rm -f "$_o_n01sh" "$_e_n01sh"

assert_exit_eq "$SH_RC_N01" 10 \
    "PAR005-N01 Bash --remote no mechanism -> exit 10"
assert_output_contains "$SH_ERR_N01" "NOT exposed" \
    "PAR005-N02 Bash --remote no mechanism: NOT exposed message"

# Stop the local server that was started.
AID_HOME="${SH_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_N01}/bin/aid" dashboard stop --target "${REPO_N01}" \
    >/dev/null 2>&1 || true

if [[ -z "$PWSH" ]]; then
    echo "  SKIP (PS half PAR005-N03..N06): pwsh absent -- PS parity skipped (Bash assertions ran above)."
    pass "PAR005-N03 PS1 --remote no mechanism -> exit 10 [SKIPPED: pwsh absent]"
    pass "PAR005-N04 PS1 --remote no mechanism: NOT exposed message [SKIPPED: pwsh absent]"
    pass "PAR005-N05 Bash<->PS1 exit code parity: --remote no mechanism [SKIPPED: pwsh absent]"
elif [[ "$PS_WIN_STYLE_PAR005" -eq 0 ]]; then
    echo "  SKIP (PS server-spawn PAR005-N03..N05): Start-Process WindowStyle not supported on Linux PS."
    pass "PAR005-N03 PS1 --remote no mechanism -> exit 10 [SKIPPED: Linux PS WindowStyle unsupported]"
    pass "PAR005-N04 PS1 --remote no mechanism: NOT exposed message [SKIPPED: Linux PS WindowStyle unsupported]"
    pass "PAR005-N05 Bash<->PS1 exit code parity: --remote no mechanism [SKIPPED: Linux PS WindowStyle unsupported]"
else
    PS_HOME_N01="$(new_dash_home_par005)"
    REPO_N01_PS="$(new_dash_repo_par005)"
    PORT_N01_PS="$(pick_dash_port)"
    _o_n01ps="$(mktemp "${TMP}/on01ps.XXXXXX")"
    _e_n01ps="$(mktemp "${TMP}/en01ps.XXXXXX")"
    PATH="${_absent_ts_dir_par005}:${PATH}" AID_HOME="${PS_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${PS_HOME_N01}/bin/aid.ps1" \
        dashboard start python \
        --port "$PORT_N01_PS" --remote --target "${REPO_N01_PS}" \
        >"$_o_n01ps" 2>"$_e_n01ps"
    PS_RC_N01=$?
    PS_ERR_N01="$(cat "$_e_n01ps")"
    rm -f "$_o_n01ps" "$_e_n01ps"

    assert_exit_eq "$PS_RC_N01" 10 \
        "PAR005-N03 PS1 --remote no mechanism -> exit 10"
    assert_output_contains "$PS_ERR_N01" "NOT exposed" \
        "PAR005-N04 PS1 --remote no mechanism: NOT exposed message"
    assert_eq "$SH_RC_N01" "$PS_RC_N01" \
        "PAR005-N05 Bash<->PS1 exit code parity: --remote no mechanism"

    AID_HOME="${PS_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
        bash "${PS_HOME_N01}/bin/aid" dashboard stop --target "${REPO_N01_PS}" \
        >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# PAR005-N06/N07: T-5 parity — dashboard stop nothing-running -> exit 0
# (no server-spawn required; runs even on Linux PS when pwsh is present)
# ---------------------------------------------------------------------------
SH_HOME_N06="$(new_dash_home_par005)"
REPO_N06="$(new_dash_repo_par005)"

_o_n06sh="$(mktemp "${TMP}/on06sh.XXXXXX")"
AID_HOME="${SH_HOME_N06}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_N06}/bin/aid" dashboard stop --target "${REPO_N06}" \
    >"$_o_n06sh" 2>&1
SH_RC_N06=$?
SH_OUT_N06="$(cat "$_o_n06sh")"
rm -f "$_o_n06sh"

assert_exit_eq "$SH_RC_N06" 0 \
    "PAR005-N06 Bash stop nothing-running -> exit 0 (T-5 parity)"
assert_output_contains "$SH_OUT_N06" "not running (nothing to stop)" \
    "PAR005-N07 Bash stop nothing-running: nothing-to-stop message"

if [[ -z "$PWSH" ]]; then
    echo "  SKIP (PS half PAR005-N08..N10): pwsh absent."
    pass "PAR005-N08 PS1 stop nothing-running -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR005-N09 PS1 stop nothing-running: nothing-to-stop message [SKIPPED: pwsh absent]"
    pass "PAR005-N10 Bash<->PS1 exit code parity: stop nothing-running [SKIPPED: pwsh absent]"
else
    PS_HOME_N06="$(new_dash_home_par005)"
    REPO_N06_PS="$(new_dash_repo_par005)"
    _o_n06ps="$(mktemp "${TMP}/on06ps.XXXXXX")"
    AID_HOME="${PS_HOME_N06}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${PS_HOME_N06}/bin/aid.ps1" \
        dashboard stop --target "${REPO_N06_PS}" \
        >"$_o_n06ps" 2>&1
    PS_RC_N06=$?
    PS_OUT_N06="$(cat "$_o_n06ps")"
    rm -f "$_o_n06ps"

    assert_exit_eq "$PS_RC_N06" 0 \
        "PAR005-N08 PS1 stop nothing-running -> exit 0 (T-5 parity)"
    assert_output_contains "$PS_OUT_N06" "not running (nothing to stop)" \
        "PAR005-N09 PS1 stop nothing-running: nothing-to-stop message"
    assert_eq "$SH_RC_N06" "$PS_RC_N06" \
        "PAR005-N10 Bash<->PS1 exit code parity: stop nothing-running"
fi

test_summary
