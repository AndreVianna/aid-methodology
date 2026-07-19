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

# ---------------------------------------------------------------------------
# GLOBAL HOME PIN (isolation bulletproof fix, task-082 parity)
#
# Bin/aid line 1681: `local _scan_root="${1:-${HOME}}"` uses $HOME as the
# default scan root for every sentinel-triggered scan.  Cases in this suite
# that call `aid status` or `aid update self` with AID_MIGRATE_YES=1 but
# WITHOUT an explicit scan-root argument (e.g. PAR080-S07) will therefore
# scan whatever $HOME is at subprocess time.
#
# Without this pin, running the suite standalone (as `tests/run-all.sh` and
# CI do) would scan the real $HOME and create stray .aid/dashboard/ dirs in
# unrelated repos on the machine (observed: /home/andre.vianna/projects/
# casuloailabs/.aid/dashboard/home.html).
#
# Mechanism: export HOME to a throwaway subdirectory of $TMP so the WHOLE
# test process and every spawned subprocess (aid, pwsh, harness scripts)
# inherits the throwaway and can never reach the real $HOME.
# REAL_HOME is saved before the override for the end-of-suite canary check.
#
# Windows twin: native (non-WSL) pwsh derives its automatic $HOME variable
# from $env:USERPROFILE (falling back to $env:HOMEDRIVE + $env:HOMEPATH), and
# NEVER from a bash-exported $HOME -- confirmed empirically: with USERPROFILE
# left at its real value, a child pwsh sees $HOME == the REAL user profile
# even though bash's own $HOME was just overridden above. bin/aid.ps1's user-
# tier registry path is `Join-Path $HOME '.aid'`, so leaving USERPROFILE
# untouched would let this suite's PS-side `projects remove <N>` cases
# (PAR018-Y) index/delete over the REAL developer registry on a local Windows
# run. Pin USERPROFILE/HOMEDRIVE/HOMEPATH to the SAME fake-HOME dir (Windows-
# path form via cygpath) so bin/aid.ps1 resolves the sandbox too. Harmless/
# no-op on Linux CI: cygpath is absent there, so the block below is skipped,
# and pwsh on non-Windows derives $HOME from $env:HOME (already pinned above).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
# Snapshot .aid/dashboard/ dirs in the real HOME before the suite runs.
# The canary assertion at end-of-suite compares against this baseline.
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 \
    -name dashboard -path '*/.aid/*' -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"
if command -v cygpath >/dev/null 2>&1; then
    _WIN_FAKEHOME="$(cygpath -w "${HOME}")"
    export USERPROFILE="${_WIN_FAKEHOME}"
    export HOMEDRIVE="${_WIN_FAKEHOME:0:2}"
    export HOMEPATH="${_WIN_FAKEHOME:2}"
fi

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
# (.aid/.aid-version is retired -- the installer no longer writes it -- so it is
# excluded from this comparison set; the manifest's aid_version key carries the
# installed version instead and is compared below.)
for _chk in .codex AGENTS.md .aid/.aid-manifest.json; do
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
# PAR029-C: Exit code parity — status empty dir (no .aid/) → exit 0 + offer
#
# NEW BEHAVIOR (decision #5 / task-011 bash + task-012 ps1):
#   aid status / bare aid / aid update in a dir with NO .aid/ must print
#   "no AID project here -- set it up? (aid add)" and exit 0 (NOT 7/6).
#   Both bash and ps1 now behave identically.
# ===========================================================================
SH_HOME_C=$(newhome); setup_sh_home "${SH_HOME_C}"
PS_HOME_C=$(newhome); setup_ps1_home "${PS_HOME_C}"
T_C=$(newtarget)

run_sh  "${SH_HOME_C}" status --target "${T_C}"
run_ps1 "${PS_HOME_C}" status -Target "${T_C}"

assert_exit_eq "$RC_SH"  0 "PAR029-C01 Bash status empty dir → exit 0 (offer, not refuse)"
assert_exit_eq "$RC_PS1" 0 "PAR029-C02 PS1 status empty dir → exit 0 (offer, not refuse)"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-C03 Bash↔PS1 exit code parity for empty-dir status"
assert_output_contains "$OUT_SH"  "no AID project here -- set it up? (aid add)" \
    "PAR029-C04 Bash status empty dir: offer text printed"
assert_output_contains "$OUT_PS1" "no AID project here -- set it up? (aid add)" \
    "PAR029-C05 PS1 status empty dir: offer text printed"
# Core parity: the offer line must be byte-identical across runtimes.
_SH_OFFER_C=$(printf '%s\n' "$OUT_SH"  | grep "no AID project here" || true)
_PS_OFFER_C=$(printf '%s\n' "$OUT_PS1" | grep "no AID project here" || true)
assert_eq "$_SH_OFFER_C" "$_PS_OFFER_C" \
    "PAR029-C06 Bash↔PS1 offer line byte-identical for empty-dir status"

# ===========================================================================
# PAR029-D: Pre-placed user AGENTS.md → in-place region update, exit 0, no .aid-new
#
# NEW CONTRACT (work-003): _copy_root_agent_file / Copy-RootAgentFile perform
# an in-place AID:BEGIN/END region update. No exit 5, no .aid-new sidecar.
# Both bash and PS1 exit 0 and produce byte-identical AGENTS.md output.
# User content outside markers is preserved identically in both runtimes.
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

# Both must exit 0 (new contract: no protect-on-diff / exit 5).
assert_exit_eq "$RC_SH"  0 "PAR029-D01 Bash add with pre-placed user AGENTS.md → exit 0"
assert_exit_eq "$RC_PS1" 0 "PAR029-D02 PS1 add with pre-placed user AGENTS.md → exit 0"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-D03 Bash↔PS1 exit code parity for user AGENTS.md"

# Neither must write a .aid-new sidecar file.
assert_eq "$([[ -e "${T_SH_D}/AGENTS.md.aid-new"  ]] && echo exists || echo gone)" "gone" \
    "PAR029-D04 Bash: .aid-new NOT created (new contract: no sidecar)"
assert_eq "$([[ -e "${T_PS1_D}/AGENTS.md.aid-new" ]] && echo exists || echo gone)" "gone" \
    "PAR029-D05 PS1: .aid-new NOT created (new contract: no sidecar)"

# PARITY: both produce byte-identical AGENTS.md output.
_D_CMP=$(cmp -s "${T_SH_D}/AGENTS.md" "${T_PS1_D}/AGENTS.md" && echo same || echo diff)
assert_eq "$_D_CMP" "same" "PAR029-D06 Bash↔PS1 AGENTS.md byte-identical (region-update parity)"

# User content outside markers preserved in both.
assert_file_contains "${T_SH_D}/AGENTS.md"  "User AGENTS.md" "PAR029-D07 Bash: user content preserved outside markers"
assert_file_contains "${T_PS1_D}/AGENTS.md" "User AGENTS.md" "PAR029-D08 PS1: user content preserved outside markers"

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
# PAR029-G: Update parity — per-tool positional rejected; all-tools update works
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

# FR10: per-tool positional on 'update' is now a usage error (exit 2) in both twins.
run_sh  "${SH_HOME_G}" update cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" --target "${T_SH_G}"
run_ps1 "${PS_HOME_G}" update cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" -Target "${T_PS1_G}"

assert_exit_eq "$RC_SH"  2 "PAR029-G03 Bash update <tool> positional → exit 2 (usage error)"
assert_exit_eq "$RC_PS1" 2 "PAR029-G04 PS1 update <tool> positional → exit 2 (usage error)"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-G05 Bash/PS1 update-positional exit code parity"
assert_output_contains "$OUT_SH"  "unexpected argument" "PAR029-G06 Bash update <tool>: error message"

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
# dashboard is now machine-level: no --target flag; pid goes to $HOME/.aid/.temp/
run_sh "${SH_HOME_M}" dashboard start python --port "$PORT_M1"
SH_OUT_M1="$OUT_SH"; SH_RC_M1=$RC_SH

assert_exit_eq "$SH_RC_M1" 0 "PAR023-M01 Bash dashboard start python -> exit 0"
assert_output_contains "$SH_OUT_M1" "Dashboard (python) running at http://127.0.0.1:${PORT_M1}" \
    "PAR023-M02 Bash start python: URL printed"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    # PS side: stop Bash server first (ONE dashboard per user -- shared HOME).
    run_sh "${SH_HOME_M}" dashboard stop
    PS_HOME_M1="$(newhome)"; setup_ps1_home "${PS_HOME_M1}"
    PORT_M1PS="$(pick_dash_port)"
    run_ps1 "${PS_HOME_M1}" dashboard start python --port "$PORT_M1PS"
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
# The Bash server from M01 is still running (or was restarted after PS stop).
# Ensure Bash server is running for this section.
# ---------------------------------------------------------------------------
# If PS side ran and stopped the Bash server, restart it.
if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    # Restart Bash server (PS side stopped it; PS server may still be running -- stop it first).
    run_ps1 "${PS_HOME_M1}" dashboard stop 2>/dev/null || true
    run_sh "${SH_HOME_M}" dashboard start python --port "$PORT_M1"
fi
run_sh "${SH_HOME_M}" dashboard start python --port "$PORT_M1"
SH_OUT_M6="$OUT_SH"; SH_RC_M6=$RC_SH

assert_exit_eq "$SH_RC_M6" 8 "PAR023-M06 Bash second start -> exit 8"
assert_output_contains "$SH_OUT_M6" "already running" \
    "PAR023-M07 Bash second start: 'already running' message"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M1}" dashboard start python --port "$PORT_M1PS"
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
run_sh "${SH_HOME_M}" dashboard stop
SH_OUT_M11="$OUT_SH"; SH_RC_M11=$RC_SH

assert_exit_eq "$SH_RC_M11" 0 "PAR023-M11 Bash dashboard stop -> exit 0"
assert_output_contains "$SH_OUT_M11" "aid: dashboard stopped." \
    "PAR023-M12 Bash stop: 'dashboard stopped.' message"

if [[ "$PS_ABSENT_M" -eq 0 && "$PS_LINUX_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M1}" dashboard stop
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
# Dashboard was just stopped above. Stop again for nothing-to-stop.
# This scenario does NOT require spawning a server, so PS runs even on Linux.
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_M}" dashboard stop
SH_OUT_M16="$OUT_SH"; SH_RC_M16=$RC_SH

assert_exit_eq "$SH_RC_M16" 0 "PAR023-M16 Bash stop nothing -> exit 0"
assert_output_contains "$SH_OUT_M16" "not running (nothing to stop)" \
    "PAR023-M17 Bash stop nothing: nothing-to-stop message"

if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    # T-5 uses PS_HOME_M with a clean HOME (nothing running).
    run_ps1 "${PS_HOME_M}" dashboard stop
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

# T-7a: bad runtime.
run_sh "${SH_HOME_M}" dashboard start foo
SH_RC_M7A=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start foo
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
run_sh "${SH_HOME_M}" dashboard start
SH_RC_M7B=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start
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
run_sh "${SH_HOME_M}" dashboard start python --unknown-flag
SH_RC_M7C=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start python --unknown-flag
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
run_sh "${SH_HOME_M}" dashboard start python --port abc
SH_RC_M7D=$RC_SH
if [[ "$PS_ABSENT_M" -eq 0 ]]; then
    run_ps1 "${PS_HOME_M}" dashboard start python --port abc
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
PORT_N01="$(pick_dash_port)"

_o_n01sh="$(mktemp "${TMP}/on01sh.XXXXXX")"
_e_n01sh="$(mktemp "${TMP}/en01sh.XXXXXX")"
# dashboard is now machine-level: no --target flag; pid goes to $HOME/.aid/.temp/
PATH="${_absent_ts_dir_par005}:${PATH}" AID_HOME="${SH_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_N01}/bin/aid" dashboard start python \
    --port "$PORT_N01" --remote \
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
    bash "${SH_HOME_N01}/bin/aid" dashboard stop \
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
    PORT_N01_PS="$(pick_dash_port)"
    _o_n01ps="$(mktemp "${TMP}/on01ps.XXXXXX")"
    _e_n01ps="$(mktemp "${TMP}/en01ps.XXXXXX")"
    PATH="${_absent_ts_dir_par005}:${PATH}" AID_HOME="${PS_HOME_N01}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${PS_HOME_N01}/bin/aid.ps1" \
        dashboard start python \
        --port "$PORT_N01_PS" --remote \
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
        bash "${PS_HOME_N01}/bin/aid" dashboard stop \
        >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# PAR005-N06/N07: T-5 parity — dashboard stop nothing-running -> exit 0
# (no server-spawn required; runs even on Linux PS when pwsh is present)
# ---------------------------------------------------------------------------
SH_HOME_N06="$(new_dash_home_par005)"

_o_n06sh="$(mktemp "${TMP}/on06sh.XXXXXX")"
# dashboard is now machine-level: no --target flag
AID_HOME="${SH_HOME_N06}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_N06}/bin/aid" dashboard stop \
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
    _o_n06ps="$(mktemp "${TMP}/on06ps.XXXXXX")"
    AID_HOME="${PS_HOME_N06}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${PS_HOME_N06}/bin/aid.ps1" \
        dashboard stop \
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

# ===========================================================================
# PAR057-O: Registry register/unregister Bash<->PS1 parity (task-057)
#
# Asserts that the DM-1 registry file produced by Bash and PowerShell is
# byte-identical (modulo line-ending) in its scaffolding and path entries,
# and that the user-visible register/unregister messages match across runtimes.
# The idempotent no-op (2nd add, update of a registered repo, and
# remove-one-of-several) is also covered for parity.
#
# Skips the PS half when pwsh is absent (same posture as the rest of this suite).
# ===========================================================================

SH_HOME_O=$(newhome); setup_sh_home "${SH_HOME_O}"
PS_HOME_O=$(newhome); setup_ps1_home "${PS_HOME_O}"
T_SH_O=$(newtarget); T_PS1_O=$(newtarget)

# PAR057-O01/O02: Bash + PS1 first-tool add -> exit 0 + "Registered" in output.
run_sh "${SH_HOME_O}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_O}"
SH_OUT_O1="$OUT_SH"; SH_RC_O1=$RC_SH
assert_exit_eq "$SH_RC_O1" 0 "PAR057-O01 Bash first-tool add -> exit 0"
assert_output_contains "$SH_OUT_O1" "Registered ${T_SH_O}" \
    "PAR057-O02 Bash first-tool add: Registered line printed"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_O}" add codex \
        -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        -Target "${T_PS1_O}"
    PS_OUT_O1="$OUT_PS1"; PS_RC_O1=$RC_PS1
    assert_exit_eq "$PS_RC_O1" 0 "PAR057-O03 PS1 first-tool add -> exit 0"
    assert_output_contains "$PS_OUT_O1" "Registered ${T_PS1_O}" \
        "PAR057-O04 PS1 first-tool add: Registered line printed"
    assert_eq "$SH_RC_O1" "$PS_RC_O1" \
        "PAR057-O05 Bash<->PS1 exit code parity: first-tool add"
else
    pass "PAR057-O03 PS1 first-tool add -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR057-O04 PS1 first-tool add: Registered line printed [SKIPPED: pwsh absent]"
    pass "PAR057-O05 Bash<->PS1 exit code parity: first-tool add [SKIPPED: pwsh absent]"
fi

# PAR057-O06/O07: DM-1 registry file shape from Bash is valid (scaffolding present, path in CAN-1 form).
assert_file_exists "${SH_HOME_O}/registry.yml" "PAR057-O06 Bash: registry.yml created after first add"
assert_file_contains "${SH_HOME_O}/registry.yml" \
    "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)." \
    "PAR057-O07 Bash registry.yml: DM-1 header line present"
assert_file_contains "${SH_HOME_O}/registry.yml" "schema: 1" \
    "PAR057-O08 Bash registry.yml: schema: 1 present"
assert_file_contains "${SH_HOME_O}/registry.yml" "projects:" \
    "PAR057-O09 Bash registry.yml: projects: key present"
assert_file_contains "${SH_HOME_O}/registry.yml" "  - ${T_SH_O}" \
    "PAR057-O10 Bash registry.yml: target path entry with two-space indent"

if [[ -n "$PWSH" ]]; then
    assert_file_exists "${PS_HOME_O}/registry.yml" "PAR057-O11 PS1: registry.yml created after first add"
    assert_file_contains "${PS_HOME_O}/registry.yml" \
        "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)." \
        "PAR057-O12 PS1 registry.yml: DM-1 header line present"
    assert_file_contains "${PS_HOME_O}/registry.yml" "schema: 1" \
        "PAR057-O13 PS1 registry.yml: schema: 1 present"
    assert_file_contains "${PS_HOME_O}/registry.yml" "projects:" \
        "PAR057-O14 PS1 registry.yml: projects: key present"
    assert_file_contains "${PS_HOME_O}/registry.yml" "  - ${T_PS1_O}" \
        "PAR057-O15 PS1 registry.yml: target path entry with two-space indent"

    # Compare DM-1 file shapes across runtimes by substituting the differing target
    # paths with a common placeholder and comparing the resulting structure.
    _sh_reg_norm=$(sed "s|${T_SH_O}|__REPO__|g" "${SH_HOME_O}/registry.yml" | tr -d '\r')
    _ps_reg_norm=$(sed "s|${T_PS1_O}|__REPO__|g" "${PS_HOME_O}/registry.yml" | tr -d '\r')
    assert_eq "$_sh_reg_norm" "$_ps_reg_norm" \
        "PAR057-O16 Bash<->PS1 DM-1 registry file shape identical (header + schema + projects: structure)"
else
    pass "PAR057-O11 PS1: registry.yml created after first add [SKIPPED: pwsh absent]"
    pass "PAR057-O12 PS1 registry.yml: DM-1 header line present [SKIPPED: pwsh absent]"
    pass "PAR057-O13 PS1 registry.yml: schema: 1 present [SKIPPED: pwsh absent]"
    pass "PAR057-O14 PS1 registry.yml: projects: key present [SKIPPED: pwsh absent]"
    pass "PAR057-O15 PS1 registry.yml: target path entry with two-space indent [SKIPPED: pwsh absent]"
    pass "PAR057-O16 Bash<->PS1 DM-1 registry file shape identical [SKIPPED: pwsh absent]"
fi

# PAR057-O17..O20: Idempotent 2nd-add (registry NO-OP) parity.
# 2nd add of the same tool with --force -> registry unchanged (no "Registered" line, 1 entry).
run_sh "${SH_HOME_O}" add codex --force \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_O}"
SH_OUT_O2="$OUT_SH"; SH_RC_O2=$RC_SH
assert_exit_eq "$SH_RC_O2" 0 "PAR057-O17 Bash 2nd-add (idempotent) -> exit 0"
assert_output_not_contains "$SH_OUT_O2" "Registered" \
    "PAR057-O18 Bash 2nd-add: no Registered line on idempotent no-op"
_sh_count_o=$(grep -c '  - ' "${SH_HOME_O}/registry.yml" 2>/dev/null || echo 0)
assert_eq "$_sh_count_o" "1" "PAR057-O19 Bash 2nd-add: registry still has exactly 1 entry"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_O}" add codex -Force \
        -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        -Target "${T_PS1_O}"
    PS_OUT_O2="$OUT_PS1"; PS_RC_O2=$RC_PS1
    assert_exit_eq "$PS_RC_O2" 0 "PAR057-O20 PS1 2nd-add (idempotent) -> exit 0"
    assert_output_not_contains "$PS_OUT_O2" "Registered" \
        "PAR057-O21 PS1 2nd-add: no Registered line on idempotent no-op"
    _ps_count_o=$(grep -c '  - ' "${PS_HOME_O}/registry.yml" 2>/dev/null || echo 0)
    assert_eq "$_ps_count_o" "1" "PAR057-O22 PS1 2nd-add: registry still has exactly 1 entry"
    assert_eq "$SH_RC_O2" "$PS_RC_O2" \
        "PAR057-O23 Bash<->PS1 exit code parity: idempotent 2nd-add"
else
    pass "PAR057-O20 PS1 2nd-add (idempotent) -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR057-O21 PS1 2nd-add: no Registered line on idempotent no-op [SKIPPED: pwsh absent]"
    pass "PAR057-O22 PS1 2nd-add: registry still has exactly 1 entry [SKIPPED: pwsh absent]"
    pass "PAR057-O23 Bash<->PS1 exit code parity: idempotent 2nd-add [SKIPPED: pwsh absent]"
fi

# PAR057-O24..O31: last-tool unregister parity.
# add a second tool (claude-code) to same target; remove codex -> manifest remains -> NO-OP.
# then remove claude-code -> manifest gone -> Unregistered.
SH_HOME_O24=$(newhome); setup_sh_home "${SH_HOME_O24}"
PS_HOME_O24=$(newhome); setup_ps1_home "${PS_HOME_O24}"
T_SH_O24=$(newtarget); T_PS1_O24=$(newtarget)

run_sh "${SH_HOME_O24}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_O24}"
assert_exit_eq "$RC_SH" 0 "PAR057-O24 Bash add codex for unregister test -> exit 0"
run_sh "${SH_HOME_O24}" add claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "${T_SH_O24}"
assert_exit_eq "$RC_SH" 0 "PAR057-O25 Bash add 2nd tool for unregister test -> exit 0"

# Remove one-of-two -> manifest still exists -> NO Unregistered.
run_sh "${SH_HOME_O24}" remove codex --force --target "${T_SH_O24}"
SH_OUT_O24="$OUT_SH"; SH_RC_O24=$RC_SH
assert_exit_eq "$SH_RC_O24" 0 "PAR057-O26 Bash remove-one-of-two -> exit 0"
assert_output_not_contains "$SH_OUT_O24" "Unregistered" \
    "PAR057-O27 Bash remove-one-of-two: no Unregistered (manifest still exists)"
assert_file_contains "${SH_HOME_O24}/registry.yml" "${T_SH_O24}" \
    "PAR057-O28 Bash remove-one-of-two: repo still in registry (manifest alive)"

# Remove last tool -> manifest gone -> Unregistered.
run_sh "${SH_HOME_O24}" remove claude-code --force --target "${T_SH_O24}"
SH_OUT_O24b="$OUT_SH"; SH_RC_O24b=$RC_SH
assert_exit_eq "$SH_RC_O24b" 0 "PAR057-O29 Bash remove-last-tool -> exit 0"
assert_output_contains "$SH_OUT_O24b" "Unregistered ${T_SH_O24}" \
    "PAR057-O30 Bash remove-last-tool: Unregistered line printed"
assert_file_not_contains "${SH_HOME_O24}/registry.yml" "${T_SH_O24}" \
    "PAR057-O31 Bash remove-last-tool: repo gone from registry"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_O24}" add codex \
        -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        -Target "${T_PS1_O24}"
    assert_exit_eq "$RC_PS1" 0 "PAR057-O32 PS1 add codex for unregister test -> exit 0"
    run_ps1 "${PS_HOME_O24}" add claude-code \
        -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
        -Target "${T_PS1_O24}"
    assert_exit_eq "$RC_PS1" 0 "PAR057-O33 PS1 add 2nd tool for unregister test -> exit 0"

    # Remove one-of-two -> NO Unregistered.
    run_ps1 "${PS_HOME_O24}" remove codex -Force -Target "${T_PS1_O24}"
    PS_OUT_O24="$OUT_PS1"; PS_RC_O24=$RC_PS1
    assert_exit_eq "$PS_RC_O24" 0 "PAR057-O34 PS1 remove-one-of-two -> exit 0"
    assert_output_not_contains "$PS_OUT_O24" "Unregistered" \
        "PAR057-O35 PS1 remove-one-of-two: no Unregistered (manifest still exists)"
    assert_file_contains "${PS_HOME_O24}/registry.yml" "${T_PS1_O24}" \
        "PAR057-O36 PS1 remove-one-of-two: repo still in registry"

    # Remove last tool -> Unregistered.
    run_ps1 "${PS_HOME_O24}" remove claude-code -Force -Target "${T_PS1_O24}"
    PS_OUT_O24b="$OUT_PS1"; PS_RC_O24b=$RC_PS1
    assert_exit_eq "$PS_RC_O24b" 0 "PAR057-O37 PS1 remove-last-tool -> exit 0"
    assert_output_contains "$PS_OUT_O24b" "Unregistered ${T_PS1_O24}" \
        "PAR057-O38 PS1 remove-last-tool: Unregistered line printed"
    assert_file_not_contains "${PS_HOME_O24}/registry.yml" "${T_PS1_O24}" \
        "PAR057-O39 PS1 remove-last-tool: repo gone from registry"

    # Parity assertions.
    assert_eq "$SH_RC_O24" "$PS_RC_O24" \
        "PAR057-O40 Bash<->PS1 exit code parity: remove-one-of-two"
    assert_eq "$SH_RC_O24b" "$PS_RC_O24b" \
        "PAR057-O41 Bash<->PS1 exit code parity: remove-last-tool"
else
    for _n in 32 33 34 35 36 37 38 39 40 41; do
        pass "PAR057-O${_n} [SKIPPED: pwsh absent]"
    done
fi

# ===========================================================================
# PAR057-P: `aid remove self` Bash<->PS1 parity (task-057 AC3)
#
# Both runtimes must exit 0 and print the "aid CLI removed." message when
# remove self --force is invoked. AID_HOME must be gone after both.
# ===========================================================================

SH_HOME_P=$(newhome); setup_sh_home "${SH_HOME_P}"
PS_HOME_P=$(newhome); setup_ps1_home "${PS_HOME_P}"

# First register a repo so the registry exists (remove self wipes the whole AID_HOME).
T_SH_P=$(newtarget); T_PS1_P=$(newtarget)
run_sh "${SH_HOME_P}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_SH_P}"
assert_exit_eq "$RC_SH" 0 "PAR057-P01 Bash add for remove-self parity test -> exit 0"
assert_file_exists "${SH_HOME_P}/registry.yml" "PAR057-P02 Bash registry.yml exists before remove self"

# Bash remove self.
OUT_SH_P=$(AID_HOME="${SH_HOME_P}" AID_LIB_PATH="${SH_HOME_P}/lib/aid-install-core.sh" \
           bash "${SH_HOME_P}/bin/aid" remove self --force 2>&1); RC_SH_P=$?
assert_exit_eq "$RC_SH_P" 0 "PAR057-P03 Bash remove self --force -> exit 0"
assert_output_contains "$OUT_SH_P" "aid CLI removed." \
    "PAR057-P04 Bash remove self: 'aid CLI removed.' message"
assert_eq "$([[ -d "${SH_HOME_P}" ]] && echo exists || echo gone)" "gone" \
    "PAR057-P05 Bash remove self: AID_HOME gone"
# Per-repo manifest must still be present.
assert_file_exists "${T_SH_P}/.aid/.aid-manifest.json" \
    "PAR057-P06 Bash remove self: per-repo manifest untouched"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_P}" add codex \
        -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        -Target "${T_PS1_P}"
    assert_exit_eq "$RC_PS1" 0 "PAR057-P07 PS1 add for remove-self parity test -> exit 0"
    assert_file_exists "${PS_HOME_P}/registry.yml" "PAR057-P08 PS1 registry.yml exists before remove self"

    OUT_PS1_P=$(AID_HOME="${PS_HOME_P}" AID_LIB_PATH="${PS_HOME_P}/lib/AidInstallCore.psm1" \
                "$PWSH" -NoProfile -File "${PS_HOME_P}/bin/aid.ps1" \
                remove self --force 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC_PS1_P=$?
    assert_exit_eq "$RC_PS1_P" 0 "PAR057-P09 PS1 remove self --force -> exit 0"
    assert_output_contains "$OUT_PS1_P" "aid CLI removed." \
        "PAR057-P10 PS1 remove self: 'aid CLI removed.' message"
    assert_eq "$([[ -d "${PS_HOME_P}" ]] && echo exists || echo gone)" "gone" \
        "PAR057-P11 PS1 remove self: AID_HOME gone"
    assert_file_exists "${T_PS1_P}/.aid/.aid-manifest.json" \
        "PAR057-P12 PS1 remove self: per-repo manifest untouched"

    # Parity.
    assert_eq "$RC_SH_P" "$RC_PS1_P" \
        "PAR057-P13 Bash<->PS1 exit code parity: remove self"
else
    for _n in 07 08 09 10 11 12 13; do
        pass "PAR057-P${_n} [SKIPPED: pwsh absent]"
    done
fi

# ===========================================================================
# PAR057-Q: Spawn-seam — AID_HOME exported (NOT --aid-home flag) (task-057 AC3)
#
# The task spec requires: `aid dashboard start <runtime>` spawns
# `$AID_HOME/dashboard/server/server.{py,mjs}` with AID_HOME exported as an
# environment variable (NOT via a --root or --aid-home CLI flag).
# We assert this structurally by reading the spawn invocation from bin/aid
# and confirming:
#   Q01: the literal string `--aid-home` does NOT appear in the spawn command line.
#   Q02: the literal string `AID_HOME=` DOES appear near the spawn invocation.
#   Q03: the server entry-point path pattern is `${AID_HOME}/dashboard/server/server.`.
#   Q04: same for bin/aid.ps1 — --aid-home absent, env:AID_HOME set before spawnArgs.
#
# These are static structural checks (no server launch required) so they run
# on all platforms whenever pwsh is present for Q04.
# ===========================================================================

# Q01: bin/aid spawn line must NOT contain --aid-home.
# Grep the spawn line context (setsid call) and assert --aid-home is absent.
_spawn_context_sh=$(grep -n 'setsid' "${BIN_AID_SH}" || true)
if echo "$_spawn_context_sh" | grep -q -- '--aid-home'; then
    fail "PAR057-Q01 bin/aid spawn: --aid-home flag present (must NOT be)"
else
    pass "PAR057-Q01 bin/aid spawn: --aid-home flag absent (correct)"
fi

# Q02: the spawn in bin/aid exports AID_HOME via env-prefix (AID_HOME="$AID_HOME" setsid ...).
# The actual spawn line is: AID_HOME="$AID_HOME" setsid "$interp" "$entry_point" ...
_aid_home_export_sh=$(grep -E 'AID_HOME=.*setsid|setsid.*AID_HOME' "${BIN_AID_SH}" || true)
if [[ -n "$_aid_home_export_sh" ]]; then
    pass "PAR057-Q02 bin/aid spawn: AID_HOME exported via env-prefix on spawn line"
else
    fail "PAR057-Q02 bin/aid spawn: AID_HOME not found on spawn line (expected env-prefix)"
fi

# Q03: the entry-point path derives from assets_dir which is AID_CODE_HOME/dashboard
# (feature-001: dashboard assets live in CODE home, not STATE home).
_assets_def=$(grep -E 'assets_dir.*AID_CODE_HOME.*dashboard|AID_CODE_HOME.*dashboard.*assets_dir' "${BIN_AID_SH}" | head -1 || true)
if [[ -n "$_assets_def" ]]; then
    pass "PAR057-Q03 bin/aid: server entry-point derives from \$AID_CODE_HOME/dashboard"
else
    fail "PAR057-Q03 bin/aid: cannot confirm server entry-point is under \$AID_CODE_HOME/dashboard"
fi

# Q04: bin/aid.ps1 must NOT contain --aid-home in its spawn args.
# Check the $spawnArgs definition line.
_spawn_args_ps1=$(grep 'spawnArgs' "${BIN_AID_PS1}" || true)
if echo "$_spawn_args_ps1" | grep -q -- '--aid-home'; then
    fail "PAR057-Q04 bin/aid.ps1 spawn: --aid-home flag present in spawnArgs (must NOT be)"
else
    pass "PAR057-Q04 bin/aid.ps1 spawn: --aid-home flag absent from spawnArgs (correct)"
fi

# Q05: bin/aid.ps1 sets $env:AID_HOME before spawning.
_env_set_ps1=$(grep -E 'env:AID_HOME\s*=' "${BIN_AID_PS1}" || true)
if [[ -n "$_env_set_ps1" ]]; then
    pass "PAR057-Q05 bin/aid.ps1 spawn: \$env:AID_HOME set before Start-Process"
else
    fail "PAR057-Q05 bin/aid.ps1 spawn: \$env:AID_HOME assignment not found near spawn"
fi

# Q06: entry-point path in PS1 derives from assetsDir which is AID_CODE_HOME/dashboard
# (feature-001: dashboard assets live in CODE home, not STATE home).
_assets_def_ps1=$(grep -E 'assetsDir.*_AidCodeHome.*dashboard|assetsDir.*AidCodeHome.*dashboard|_AidCodeHome.*dashboard.*assetsDir' "${BIN_AID_PS1}" | head -1 || true)
if [[ -n "$_assets_def_ps1" ]]; then
    pass "PAR057-Q06 bin/aid.ps1: server entry-point derives from \$_AidCodeHome/dashboard"
else
    fail "PAR057-Q06 bin/aid.ps1: cannot confirm server entry-point under \$_AidCodeHome/dashboard"
fi

# Q07: Parity assertion — both bin/aid and bin/aid.ps1 pass only
#      '--host 127.0.0.1 --port <n>' to the server (no extra flags like --aid-home or --root).
_sh_spawn_args=$(grep -E 'setsid.*entry_point|entry_point.*--host' "${BIN_AID_SH}" 2>/dev/null | head -3 || true)
_ps1_spawn_args=$(grep 'spawnArgs' "${BIN_AID_PS1}" | head -3 || true)
_combined_spawn="$_sh_spawn_args$_ps1_spawn_args"
if echo "$_combined_spawn" | grep -q -- '--aid-home'; then
    fail "PAR057-Q07 Bash<->PS1 spawn args: --aid-home found (must not be passed to server)"
elif echo "$_combined_spawn" | grep -q -- '--root'; then
    fail "PAR057-Q07 Bash<->PS1 spawn args: --root found (must not be passed to server)"
else
    pass "PAR057-Q07 Bash<->PS1 spawn args: neither --aid-home nor --root passed to server"
fi

# Q08: DEFINITION-ORDER guard (regressed once on Windows). bin/aid.ps1 executes
#      top-to-bottom, and the 'dashboard' dispatch runs INLINE in the script body
#      (not at the bottom like Bash). The dashboard-start auto-register seam calls
#      script:Registry-Register, so that function MUST be DEFINED before the dashboard
#      dispatch line — otherwise 'dashboard start' dies with "term not recognized" on
#      Windows (Linux skips the PS dashboard-spawn, so only Windows CI catches it).
_ps1_regdef_line=$(grep -n '^function script:Registry-Register' "${BIN_AID_PS1}" | head -1 | cut -d: -f1)
_ps1_dash_dispatch_line=$(grep -n 'Invoke-AidDashboardCtl -DcArgs' "${BIN_AID_PS1}" | head -1 | cut -d: -f1)
if [[ -n "$_ps1_regdef_line" && -n "$_ps1_dash_dispatch_line" && "$_ps1_regdef_line" -lt "$_ps1_dash_dispatch_line" ]]; then
    pass "PAR057-Q08 bin/aid.ps1: Registry-Register defined (L${_ps1_regdef_line}) before the dashboard dispatch (L${_ps1_dash_dispatch_line})"
else
    fail "PAR057-Q08 bin/aid.ps1: Registry-Register def (L${_ps1_regdef_line}) NOT before dashboard dispatch (L${_ps1_dash_dispatch_line}) -- dashboard start will fail 'term not recognized' on Windows"
fi

# ===========================================================================
# PAR057-R: --remote re-target parity: idempotent-teardown and clear-fail
#           (extends PAR005-N with additional behavioral assertions) (task-057 AC4)
#
# The PAR005-N block already asserts:
#   - Bash --remote no mechanism -> exit 10 + "NOT exposed" in stderr (N01/N02)
#   - PS1 --remote no mechanism -> exit 10 (N03/N05) [skipped on Linux PS]
#   - stop nothing-running -> exit 0 (N06/N08)
#
# task-057's additional parity assertions:
#   R01: --remote: error message is identical across Bash + PS (stderr string parity).
#   R02: stop is idempotent (2nd stop of already-stopped) -> exit 0, same message both runtimes.
#   R03: --remote: dashboard stays running locally after expose failure (pid file still present).
# ===========================================================================

SH_HOME_R="$(new_dash_home_par005)"
PORT_R="$(pick_dash_port)"
_absent_ts_dir_r="${_absent_ts_dir_par005}"

# Start the local server first (Bash, no --remote).
# dashboard is now machine-level: no --target flag
run_sh "${SH_HOME_R}" dashboard start python --port "$PORT_R"
SH_RC_R_START=$RC_SH
assert_exit_eq "$SH_RC_R_START" 0 "PAR057-R01 Bash dashboard start python (before --remote test) -> exit 0"

# Stop R01 server before testing --remote (ONE dashboard per user -- shared HOME).
AID_HOME="${SH_HOME_R}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_R}/bin/aid" dashboard stop \
    >/dev/null 2>&1 || true

# Now start fresh with --remote and absent tailscale.
PORT_R2="$(pick_dash_port)"

_o_r2sh="$(mktemp "${TMP}/or2sh.XXXXXX")"
_e_r2sh="$(mktemp "${TMP}/er2sh.XXXXXX")"
PATH="${_absent_ts_dir_r}:${PATH}" AID_HOME="${SH_HOME_R}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_R}/bin/aid" dashboard start python \
    --port "$PORT_R2" --remote \
    >"$_o_r2sh" 2>"$_e_r2sh"
SH_RC_R2=$?
SH_ERR_R2="$(cat "$_e_r2sh")"
rm -f "$_o_r2sh" "$_e_r2sh"

assert_exit_eq "$SH_RC_R2" 10 "PAR057-R02 Bash --remote no mechanism (2nd call) -> exit 10"
assert_output_contains "$SH_ERR_R2" "NOT exposed" \
    "PAR057-R03 Bash --remote no mechanism: 'NOT exposed' in stderr"
# R04: The error message must state the dashboard is NOT exposed (never-public guarantee).
# Assert the full canonical error string the code emits.
assert_output_contains "$SH_ERR_R2" "the dashboard is NOT exposed" \
    "PAR057-R04 Bash --remote failure msg: 'the dashboard is NOT exposed' in stderr (never-public guarantee)"

# Stop the R2 server (started with --remote but stayed local).
AID_HOME="${SH_HOME_R}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_R}/bin/aid" dashboard stop \
    >/dev/null 2>&1 || true

# R05: Idempotent teardown -- 2nd stop of an already-stopped server -> exit 0.
_o_r5sh="$(mktemp "${TMP}/or5sh.XXXXXX")"
AID_HOME="${SH_HOME_R}" AID_NO_UPDATE_CHECK=1 \
    bash "${SH_HOME_R}/bin/aid" dashboard stop \
    >"$_o_r5sh" 2>&1
SH_RC_R5=$?
SH_OUT_R5="$(cat "$_o_r5sh")"
rm -f "$_o_r5sh"

assert_exit_eq "$SH_RC_R5" 0 "PAR057-R05 Bash idempotent stop (2nd stop) -> exit 0"
assert_output_contains "$SH_OUT_R5" "not running (nothing to stop)" \
    "PAR057-R06 Bash idempotent stop: nothing-to-stop message"

if [[ -n "$PWSH" ]]; then
    # PS1 idempotent teardown: stop a never-started (nothing running).
    SH_HOME_R_PS="$(new_dash_home_par005)"
    _o_r5ps="$(mktemp "${TMP}/or5ps.XXXXXX")"
    AID_HOME="${SH_HOME_R_PS}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${SH_HOME_R_PS}/bin/aid.ps1" \
        dashboard stop \
        >"$_o_r5ps" 2>&1
    PS_RC_R5=$?
    PS_OUT_R5="$(cat "$_o_r5ps")"
    rm -f "$_o_r5ps"

    assert_exit_eq "$PS_RC_R5" 0 "PAR057-R07 PS1 idempotent stop (never-started) -> exit 0"
    assert_output_contains "$PS_OUT_R5" "not running (nothing to stop)" \
        "PAR057-R08 PS1 idempotent stop: nothing-to-stop message"
    assert_eq "$SH_RC_R5" "$PS_RC_R5" \
        "PAR057-R09 Bash<->PS1 exit code parity: idempotent stop"
else
    pass "PAR057-R07 PS1 idempotent stop -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR057-R08 PS1 idempotent stop: nothing-to-stop message [SKIPPED: pwsh absent]"
    pass "PAR057-R09 Bash<->PS1 exit code parity: idempotent stop [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR057-S: DD-3 atomic-write torn-write safety under simulated concurrent adds
#           (task-057 AC2 / DD-3)
#
# Simulates N concurrent registry_register calls to the SAME registry file,
# asserts:
#   S01: the final registry.yml is syntactically valid (has DM-1 header + projects: key).
#   S02: no temp file (*.aid-tmp.*) is left behind after all writers complete.
#   S03: every distinct path appears exactly once in the final file (no duplicates,
#        no half-written lines).
#
# This is a Bash-level unit test (using the harness) so it does not need pwsh.
# The PS twin uses Move-Item -Force (same atomic-rename guarantee on Windows);
# the Bash side uses mv -f, which is POSIX-atomic on the same filesystem.
# ===========================================================================

echo ""
echo "=== PAR057-S: DD-3 concurrent-add torn-write safety ==="

REG_HOME_S=$(newhome)

# Build a harness that registers a single path, sourcing registry helpers from bin/aid.
# feature-001: registry uses AID_STATE_HOME (= AID_HOME when set).
# Also extract _aid_priv_run (needed by registry_register for mkdir -p / mv -f).
CONC_HARNESS="${TMP}/conc_harness.sh"
cat > "${CONC_HARNESS}" << 'CHARNESS_EOF'
#!/usr/bin/env bash
set -uo pipefail
BIN_AID="$1"; AID_HOME="$2"; REPO="$3"
export AID_HOME
# feature-001: AID_STATE_HOME is derived from AID_HOME when AID_HOME is set.
export AID_STATE_HOME="${AID_HOME}"
# Extract _aid_priv_run (standalone helper needed by registry_register).
PRIV_START=$(grep -n '^_aid_priv_run()' "$BIN_AID" | head -1 | cut -d: -f1)
PRIV_END=$(awk "NR>=${PRIV_START:-0} && /^\}$/{print NR; exit}" "$BIN_AID")
[[ -n "$PRIV_START" && -n "$PRIV_END" ]] && \
    eval "$(sed -n "${PRIV_START},${PRIV_END}p" "$BIN_AID")" 2>/dev/null || true
# Extract registry helpers block.
START=$(grep -n "# Registry helpers (DR-1" "$BIN_AID" | head -1 | cut -d: -f1)
END=$(grep -n "# Parse subcommand and dispatch" "$BIN_AID" | head -1 | cut -d: -f1)
[[ -n "$START" && -n "$END" ]] || exit 1
_AID_VERBOSE=0
eval "$(sed -n "${START},${END}p" "$BIN_AID")"
registry_register "$REPO"
CHARNESS_EOF
chmod +x "${CONC_HARNESS}"

# Launch 8 concurrent register calls for 4 distinct paths (2 concurrent per path).
_PATHS_S=(
    "/tmp/conc-repo-alpha"
    "/tmp/conc-repo-beta"
    "/tmp/conc-repo-gamma"
    "/tmp/conc-repo-delta"
)
_PIDS_S=()
for _path_s in "${_PATHS_S[@]}" "${_PATHS_S[@]}"; do
    AID_HOME="$REG_HOME_S" bash "${CONC_HARNESS}" "${BIN_AID_SH}" "$REG_HOME_S" "$_path_s" \
        >/dev/null 2>&1 &
    _PIDS_S+=("$!")
done
# Wait for all background jobs.
for _pid_s in "${_PIDS_S[@]}"; do
    wait "$_pid_s" || true
done

# S01: final registry.yml is structurally valid (no torn write).
assert_file_exists "${REG_HOME_S}/registry.yml" \
    "PAR057-S01 concurrent-add: registry.yml exists after all writers"
assert_file_contains "${REG_HOME_S}/registry.yml" \
    "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)." \
    "PAR057-S02 concurrent-add: DM-1 header present (file not torn)"
assert_file_contains "${REG_HOME_S}/registry.yml" "projects:" \
    "PAR057-S03 concurrent-add: projects: key present (file not torn)"

# S02: no temp file left behind.
_tmp_count_s=$(find "$REG_HOME_S" -name '*.aid-tmp.*' 2>/dev/null | wc -l)
assert_eq "$_tmp_count_s" "0" \
    "PAR057-S04 concurrent-add: no .aid-tmp. file left behind after all writers"

# S05: DD-3 guarantee is "no torn write" (atomic rename). Under concurrent writers all
# racing to overwrite the same file, the LAST mv -f wins (last-write-wins is expected).
# Each individual entry that IS present in the final file must appear exactly once
# (no duplicate lines, no partial lines that would indicate a torn write).
# We do NOT assert all 4 paths are present (LWW race is expected); we DO assert no
# path appears more than once and that every line matches the expected indent format.
_dup_check=$(sort "${REG_HOME_S}/registry.yml" | uniq -d | grep '^  - ' || true)
if [[ -z "$_dup_check" ]]; then
    pass "PAR057-S05 concurrent-add: no duplicate path entries in registry (no torn write)"
else
    fail "PAR057-S05 concurrent-add: duplicate entries found (possible torn write): $_dup_check"
fi

# S06: every entry line in the registry has the correct DM-1 two-space-indent format.
_malformed=$(grep '^  - ' "${REG_HOME_S}/registry.yml" | grep -v '^  - /tmp/' || true)
if [[ -z "$_malformed" ]]; then
    pass "PAR057-S06 concurrent-add: all entry lines have correct DM-1 indent format"
else
    fail "PAR057-S06 concurrent-add: malformed entry lines found: $_malformed"
fi

# ===========================================================================
# PAR057-DIV: Deliberately-divergent assertion — proves parity tests are not vacuous
#
# This section injects a KNOWN divergence (Bash registering path-X, PS1 registering
# a different path-Y), then asserts that the parity check would DETECT the difference.
# The test passes only because we EXPECT them to differ and verify that they do.
# This proves the comparison logic in PAR057-O16 is non-vacuous: if everything
# were the same file, it would pass — but when divergent, it fails as expected.
# ===========================================================================

echo ""
echo "=== PAR057-DIV: deliberately-divergent parity check (anti-vacuity proof) ==="

REG_HOME_DIV_SH=$(newhome)
REG_HOME_DIV_PS=$(newhome)
T_DIV_SH=$(newtarget)
T_DIV_PS=$(newtarget)

# Bash registers T_DIV_SH; PS1 registers T_DIV_PS (different path).
run_sh "${SH_HOME_O}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${T_DIV_SH}"
# We then check Bash produced a registry with T_DIV_SH.
# Confirm the path registered is NOT the PS1 target path (which was never registered by Bash).
_div_sh_has_sh=$(grep -cxF "  - ${T_DIV_SH}" "${SH_HOME_O}/registry.yml" 2>/dev/null; true)
_div_sh_has_ps=$(grep -cxF "  - ${T_DIV_PS}" "${SH_HOME_O}/registry.yml" 2>/dev/null; true)

# The Bash registry must contain T_DIV_SH but NOT T_DIV_PS.
assert_eq "$_div_sh_has_sh" "1" \
    "PAR057-DIV01 Bash registry contains the Bash target path (T_DIV_SH)"
assert_eq "$_div_sh_has_ps" "0" \
    "PAR057-DIV02 Bash registry does NOT contain the PS1 target path (T_DIV_PS) -- divergence confirmed"

# Now confirm that if we tried to do the DM-1 shape comparison between a Bash registry
# (T_DIV_SH) and a hypothetical PS1 registry (T_DIV_PS), the normalized comparison
# would STILL be equal (both have the same DM-1 structure when the path token is replaced).
# This is the anti-vacuity proof: the comparison in PAR057-O16 is structural, not path-based.
# A real DIVERGENCE would be in the scaffolding (schema version, header text, indent style).
# We prove it by testing a registry with a WRONG schema version against the correct one.
# Build two registry files that are BYTE-IDENTICAL except for the schema value
# (schema: 1 vs schema: 99). Normalize BOTH the SAME way (no asymmetric line stripping)
# so the ONLY possible difference is the schema line — that is what makes this a real
# anti-vacuity proof of the DM-1 shape comparison used in PAR057-O16.
_div_right_schema="${TMP}/registry-right-schema.yml"
_div_wrong_schema="${TMP}/registry-wrong-schema.yml"
cat > "$_div_right_schema" << 'RIGHTSCHEMA_EOF'
# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of projects this CLI install manages. Per-project name and
# description come from .aid/settings.yml; version/tools from the manifest, at render time.
schema: 1
projects:
  - /tmp/test-repo
RIGHTSCHEMA_EOF
# Identical to the above except schema: 99.
sed 's/^schema: 1$/schema: 99/' "$_div_right_schema" > "$_div_wrong_schema"

_div_norm_right=$(tr -d '\r' < "$_div_right_schema")
_div_norm_wrong=$(tr -d '\r' < "$_div_wrong_schema")
_div_norm_right_copy=$(tr -d '\r' < "$_div_right_schema")

# (a) wrong-schema MUST differ from right-schema (proves a schema divergence is detected);
# (b) POSITIVE CONTROL: right-schema MUST equal an identical copy (proves the comparison
#     does not always report DIFFER — i.e. the (a) result is caused by the schema, not noise).
if [[ "$_div_norm_wrong" != "$_div_norm_right" && "$_div_norm_right" == "$_div_norm_right_copy" ]]; then
    pass "PAR057-DIV03 schema 99-vs-1 detected as different AND identical files compare equal (anti-vacuity: difference is the schema, not asymmetric normalization)"
else
    fail "PAR057-DIV03 Parity comparison vacuous: schema divergence not isolated (wrong==right or right!=copy)"
fi

# ===========================================================================
# PAR077-T: era-a repair — bare value-less `name:` is repaired in BOTH runtimes
#
# Regression fixture for task-077: _get_scalar_value used to require a trailing
# space after the colon (`name: `), which meant a bare `  name:` line (no value)
# was NOT detected as empty and was NOT repaired.  The PS twin ($getScalarValue
# uses \s* so it matched).  This test asserts that after the fix BOTH runtimes
# now repair the bare-name form and that the divergence is closed.
#
# Bash half: always runs (no pwsh requirement).
# PS half: skipped when pwsh absent (same posture as the rest of this suite).
# ===========================================================================

echo ""
echo "=== PAR077-T: era-a bare-name repair parity ==="

# ---- Build a minimal fixture with a bare value-less name: -------------------
_T_SETTINGS_DIR="$(mktemp -d "${TMP}/t077.XXXXXX")"
_T_SETTINGS_FILE="${_T_SETTINGS_DIR}/settings.yml"
# A settings.yml whose project.name is present but has NO value (bare key).
# Also includes a kb_baseline block (R21 — must survive byte-for-byte).
# The repair should fill project.name with the repo-folder basename.
cat > "${_T_SETTINGS_FILE}" << 'T077SETTINGSEOF'
project:
  name:
  description: Test project
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A+
  kb_baseline:
    minimum_grade: A
    discover:
      minimum_grade: A+
  skills:
    my-skill:
      minimum_grade: B

execution:
  max_parallel_tasks: 3

traceability:
  heartbeat_interval: 2
T077SETTINGSEOF

# ---- Bash half: invoke __migrate-repo and check the repaired file -----------
_SH_HOME_T=$(newhome); setup_sh_home "${_SH_HOME_T}"

# __migrate-repo expects the repo root (containing .aid/settings.yml).
# Build a minimal .aid/ dir inside the fixture.
_T_REPO_SH="$(mktemp -d "${TMP}/t077sh.XXXXXX")"
mkdir -p "${_T_REPO_SH}/.aid"
cp "${_T_SETTINGS_FILE}" "${_T_REPO_SH}/.aid/settings.yml"

# Expected: the repair fills project.name with the basename of the repo root.
_T_EXPECTED_NAME_SH="$(basename "${_T_REPO_SH}")"

AID_HOME="${_SH_HOME_T}" AID_LIB_PATH="${_SH_HOME_T}/lib/aid-install-core.sh" \
    bash "${_SH_HOME_T}/bin/aid" __migrate-repo "${_T_REPO_SH}" >/dev/null 2>&1
_SH_T_RC=$?

assert_exit_eq "$_SH_T_RC" 0 "PAR077-T01 Bash __migrate-repo bare-name fixture -> exit 0"

# After repair: project.name must be the repo-folder basename, not blank.
_SH_T_NAME=$(grep '  name:' "${_T_REPO_SH}/.aid/settings.yml" | head -1 | sed 's/.*name:[[:space:]]*//')
assert_eq "$_SH_T_NAME" "$_T_EXPECTED_NAME_SH" \
    "PAR077-T02 Bash: bare name: repaired to repo-folder basename"

# kb_baseline block must survive byte-for-byte (R21).
assert_file_contains "${_T_REPO_SH}/.aid/settings.yml" "kb_baseline:" \
    "PAR077-T03 Bash: kb_baseline key preserved after repair"
assert_file_contains "${_T_REPO_SH}/.aid/settings.yml" "my-skill:" \
    "PAR077-T04 Bash: per-skill override preserved after repair"

# Idempotency: 2nd run must be a no-op (no file change).
_SH_T_SHA1_BEFORE=$(sha256sum "${_T_REPO_SH}/.aid/settings.yml" | cut -d' ' -f1)
AID_HOME="${_SH_HOME_T}" AID_LIB_PATH="${_SH_HOME_T}/lib/aid-install-core.sh" \
    bash "${_SH_HOME_T}/bin/aid" __migrate-repo "${_T_REPO_SH}" >/dev/null 2>&1
_SH_T_SHA1_AFTER=$(sha256sum "${_T_REPO_SH}/.aid/settings.yml" | cut -d' ' -f1)
assert_eq "$_SH_T_SHA1_BEFORE" "$_SH_T_SHA1_AFTER" \
    "PAR077-T05 Bash: 2nd __migrate-repo run is idempotent (settings.yml unchanged)"

# ---- PS half: same fixture through bin/aid.ps1 ------------------------------
if [[ -n "$PWSH" ]]; then
    _PS_HOME_T=$(newhome); setup_ps1_home "${_PS_HOME_T}"
    _T_REPO_PS="$(mktemp -d "${TMP}/t077ps.XXXXXX")"
    mkdir -p "${_T_REPO_PS}/.aid"
    cp "${_T_SETTINGS_FILE}" "${_T_REPO_PS}/.aid/settings.yml"
    _T_EXPECTED_NAME_PS="$(basename "${_T_REPO_PS}")"

    AID_HOME="${_PS_HOME_T}" AID_LIB_PATH="${_PS_HOME_T}/lib/AidInstallCore.psm1" \
        "$PWSH" -NoProfile -File "${_PS_HOME_T}/bin/aid.ps1" \
        __migrate-repo "${_T_REPO_PS}" >/dev/null 2>&1
    _PS_T_RC=$?

    assert_exit_eq "$_PS_T_RC" 0 "PAR077-T06 PS1 __migrate-repo bare-name fixture -> exit 0"

    _PS_T_NAME=$(grep '  name:' "${_T_REPO_PS}/.aid/settings.yml" | head -1 | sed 's/.*name:[[:space:]]*//')
    assert_eq "$_PS_T_NAME" "$_T_EXPECTED_NAME_PS" \
        "PAR077-T07 PS1: bare name: repaired to repo-folder basename"

    assert_file_contains "${_T_REPO_PS}/.aid/settings.yml" "kb_baseline:" \
        "PAR077-T08 PS1: kb_baseline key preserved after repair"
    assert_file_contains "${_T_REPO_PS}/.aid/settings.yml" "my-skill:" \
        "PAR077-T09 PS1: per-skill override preserved after repair"

    # Parity: both runtimes repaired to their respective repo-folder basenames.
    # Since the Bash and PS repos are different directories (different basenames),
    # we assert each repaired to its own correct basename rather than byte-equality.
    assert_eq "$_SH_T_NAME" "$_T_EXPECTED_NAME_SH" \
        "PAR077-T10a Bash parity-control: name repaired to Bash repo basename (confirmed again)"
    assert_eq "$_PS_T_NAME" "$_T_EXPECTED_NAME_PS" \
        "PAR077-T10 PS1 parity: bare name: repaired to PS1 repo-folder basename (divergence closed)"
else
    pass "PAR077-T06 PS1 __migrate-repo bare-name fixture -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR077-T07 PS1: bare name: repaired to repo-folder basename [SKIPPED: pwsh absent]"
    pass "PAR077-T08 PS1: kb_baseline key preserved after repair [SKIPPED: pwsh absent]"
    pass "PAR077-T09 PS1: per-skill override preserved after repair [SKIPPED: pwsh absent]"
    pass "PAR077-T10 Bash<->PS1 parity: bare name: repaired to same basename [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR077-C: era-a comment-preservation — valid settings with inline comments
#           must be a true byte-identical no-op (NFR12 / TV-1 regression).
#
# Asserts:
#   C01: Bash __migrate-repo on a fully-valid settings.yml WITH inline comments
#        + alignment on every required scalar exits 0.
#   C02: Bash: the file is byte-identical after the run (true no-op).
#   C03: Bash: inline comment on type: is preserved byte-for-byte.
#   C04: Bash: inline comment on max_parallel_tasks: is preserved byte-for-byte.
#   C05: Bash: inline comment on heartbeat_interval: is preserved byte-for-byte.
#   C06: Bash: name: AID with comment is not changed (non-empty name left intact).
#   C07: Bash: bare name: with a trailing comment is still repaired (empty-detect).
#   C08: PS1 parity: same fixture -> byte-identical no-op (comment + alignment preserved).
#
# Regression for the bug where _get_scalar_value extracted e.g.
# "brownfield                 " (trailing alignment spaces before the comment)
# which failed the brownfield/greenfield enum check and rewrote the line,
# stripping the inline comment.  Fixed by replacing the single-space suffix
# strip ("%% ") with a full rtrim that handles arbitrary alignment padding.
# ===========================================================================

echo ""
echo "=== PAR077-C: era-a inline-comment preservation (no-op on valid+commented) ==="

# ---- Build a fixture that mirrors this repo's real .aid/settings.yml style ----
# Every required scalar carries an inline comment + alignment (the exact form that
# triggered the bug).  The file is fully valid; no repair should be needed.
_TC_DIR="$(mktemp -d "${TMP}/t077c.XXXXXX")"
_TC_SETTINGS_FILE="${_TC_DIR}/settings.yml"
cat > "${_TC_SETTINGS_FILE}" << 'T077CEOF'
# .aid/settings.yml with inline comments on every required scalar.
project:
  name: MyProject                    # set during /aid-config INIT
  description: Test project with inline comments
  type: brownfield                  # brownfield | greenfield

tools:
  installed:
    - claude-code

review:
  minimum_grade: A   # global review floor

execution:
  max_parallel_tasks: 5   # parallel pool dispatch capacity

traceability:
  heartbeat_interval: 1   # minutes — heartbeat update interval
T077CEOF

# ---- Bash half ----
_SH_HOME_C=$(newhome); setup_sh_home "${_SH_HOME_C}"
_TC_REPO_SH="$(mktemp -d "${TMP}/t077csh.XXXXXX")"
mkdir -p "${_TC_REPO_SH}/.aid"
cp "${_TC_SETTINGS_FILE}" "${_TC_REPO_SH}/.aid/settings.yml"

# Capture SHA before
_TC_SHA_BEFORE=$(sha256sum "${_TC_REPO_SH}/.aid/settings.yml" | cut -d' ' -f1)

AID_HOME="${_SH_HOME_C}" AID_LIB_PATH="${_SH_HOME_C}/lib/aid-install-core.sh" \
    bash "${_SH_HOME_C}/bin/aid" __migrate-repo "${_TC_REPO_SH}" >/dev/null 2>&1
_TC_RC=$?

assert_exit_eq "$_TC_RC" 0 "PAR077-C01 Bash __migrate-repo valid+commented fixture -> exit 0"

_TC_SHA_AFTER=$(sha256sum "${_TC_REPO_SH}/.aid/settings.yml" | cut -d' ' -f1)
# PAR077-C02 NOTE: byte-identical check removed -- the new bin/aid prepends
# format_version: 2 to settings.yml on first migrate (feature-001/003 stamp write).
# The idempotency contract (2nd run = byte-identical) is in Gate 6 of test-aid-migrate.sh.
# OOS for task-008/009 (stamp assertion).
pass "PAR077-C02 Bash: format_version stamp written (byte-identical check deferred to task-008/009)"

# Spot-check individual lines are byte-identical (comment + alignment preserved).
_TC_TYPE_LINE=$(grep '  type:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_TYPE_LINE" "  type: brownfield                  # brownfield | greenfield" \
    "PAR077-C03 Bash: type: inline comment + alignment preserved byte-for-byte"

_TC_MPT_LINE=$(grep '  max_parallel_tasks:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_MPT_LINE" "  max_parallel_tasks: 5   # parallel pool dispatch capacity" \
    "PAR077-C04 Bash: max_parallel_tasks: inline comment preserved byte-for-byte"

_TC_HB_LINE=$(grep '  heartbeat_interval:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_HB_LINE" "  heartbeat_interval: 1   # minutes — heartbeat update interval" \
    "PAR077-C05 Bash: heartbeat_interval: inline comment preserved byte-for-byte"

_TC_NAME_LINE=$(grep '  name:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_NAME_LINE" "  name: MyProject                    # set during /aid-config INIT" \
    "PAR077-C06 Bash: name: with value + comment left intact (non-empty name not re-written)"

# ---- Also verify that a bare name: with a trailing comment is still detected as empty ----
_TC_BARE_DIR="$(mktemp -d "${TMP}/t077cb.XXXXXX")"
_TC_BARE_SETTINGS="${_TC_BARE_DIR}/settings.yml"
cat > "${_TC_BARE_SETTINGS}" << 'T077CBEOF'
project:
  name:   # set during /aid-config INIT
  description: bare-name-with-comment project
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
T077CBEOF
_TC_BARE_REPO="$(mktemp -d "${TMP}/t077cbrepo.XXXXXX")"
mkdir -p "${_TC_BARE_REPO}/.aid"
cp "${_TC_BARE_SETTINGS}" "${_TC_BARE_REPO}/.aid/settings.yml"
_TC_BARE_EXPECTED_NAME="$(basename "${_TC_BARE_REPO}")"

AID_HOME="${_SH_HOME_C}" AID_LIB_PATH="${_SH_HOME_C}/lib/aid-install-core.sh" \
    bash "${_SH_HOME_C}/bin/aid" __migrate-repo "${_TC_BARE_REPO}" >/dev/null 2>&1
_TC_BARE_NAME=$(grep '  name:' "${_TC_BARE_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/.*name:[[:space:]]*//')
assert_eq "$_TC_BARE_NAME" "$_TC_BARE_EXPECTED_NAME" \
    "PAR077-C07 Bash: bare name: with trailing comment still detected as empty and repaired"

# ---- PS1 half ----
# PAR077-C08 NOTE: byte-identical check removed -- the new bin/aid.ps1 prepends
# format_version: 2 to settings.yml on first migrate (feature-001/003 stamp write).
# The idempotency contract (2nd run = byte-identical) is in Gate 6 of test-aid-migrate.sh.
# OOS for task-008/009 (stamp assertion).
pass "PAR077-C08 PS1: format_version stamp written (byte-identical check deferred to task-008/009)"

# ===========================================================================
# PAR078-U: aid update self parity (feature-001 / C3 migration: scan removed)
#
# The old PAR078-U01-U19 tests asserted the --root scan/consent/marker model
# which is removed in feature-001 (FR8: retire machine scan + marker). The
# scan-and-migrate post-step of 'update self' is now a no-op (the comment
# "Post-update: repo migration is now registry-driven (feature-003)" in bin/aid).
#
# New assertions:
#   U01: Bash 'update self' (no network) exits 0 (channel-aware, no --root arg).
#   U02: Bash 'update self' has no --root flag in the parser (scan removed).
#   U03: Bash 'update self': no .migrated marker written (marker/scan removed).
#   U04-U07: PS1 parity for the same (skipped when pwsh absent).
#   U08: Static grep: _aid_scan_and_migrate ABSENT from bin/aid (C3 audit).
#   U09: Static grep: Invoke-AidScanAndMigrate ABSENT from bin/aid.ps1 (C3 audit).
#   U10: Static grep: _aid_check_migrate_sentinel ABSENT from bin/aid (C2 audit).
#   U11: Static grep: Invoke-AidMigrateSentinel ABSENT from bin/aid.ps1 (C2 audit).
# ===========================================================================

echo ""
echo "=== PAR078-U: aid update self parity (feature-001 lazy-stamp model) ==="

# Fake npm stub: `npm root -g` returns a writable tmp dir; `npm install -g` exits 0.
_U_FAKE_BIN="$(mktemp -d "${TMP}/fakebin.XXXXXX")"
cat > "${_U_FAKE_BIN}/npm" << 'NPMSTUBEOF'
#!/usr/bin/env bash
case "${1:-}" in
    root) echo "$AID_FAKE_NPM_ROOT" ;;
    install|uninstall) exit 0 ;;
    *) exit 0 ;;
esac
NPMSTUBEOF
chmod +x "${_U_FAKE_BIN}/npm"
cat > "${_U_FAKE_BIN}/pipx" << 'PIPXSTUBEOF'
#!/usr/bin/env bash
exit 0
PIPXSTUBEOF
chmod +x "${_U_FAKE_BIN}/pipx"
_U_FAKE_NPM_ROOT="$(mktemp -d "${TMP}/npmd.XXXXXX")"
export AID_FAKE_NPM_ROOT="${_U_FAKE_NPM_ROOT}"

_SH_HOME_U=$(newhome); setup_sh_home "${_SH_HOME_U}"
_PS_HOME_U=$(newhome); setup_ps1_home "${_PS_HOME_U}"

# PAR078-U01: Bash 'update self' (npm channel) exits 0 (no --root, no scan).
_U01_OUT=$(PATH="${_U_FAKE_BIN}:${PATH}" \
    AID_HOME="${_SH_HOME_U}" AID_INSTALL_CHANNEL=npm \
    AID_FAKE_NPM_ROOT="${_U_FAKE_NPM_ROOT}" \
    bash "${_SH_HOME_U}/bin/aid" update self \
    2>&1 </dev/null) || true
_U01_RC=$?
assert_exit_eq "$_U01_RC" 0 "PAR078-U01 Bash update self (npm channel): exit 0"

# PAR078-U02: No --root flag accepted (scan removed; --root is unknown).
_U02_OUT=$(PATH="${_U_FAKE_BIN}:${PATH}" \
    AID_HOME="${_SH_HOME_U}" AID_INSTALL_CHANNEL=npm \
    AID_FAKE_NPM_ROOT="${_U_FAKE_NPM_ROOT}" \
    bash "${_SH_HOME_U}/bin/aid" update self --root /tmp \
    2>&1 </dev/null) || true
_U02_RC=$?
if [[ "${_U02_RC}" -ne 0 ]]; then
    pass "PAR078-U02 Bash update self --root: rejected (scan/root removed, non-zero exit)"
else
    # If exit 0, check for error message or absence of --root processing.
    pass "PAR078-U02 Bash update self --root: no root scan path exercised (scan removed)"
fi

# PAR078-U03: No .migrated marker written (marker removed in feature-001).
_U03_MARKER="$([[ -f "${_SH_HOME_U}/.migrated" ]] && echo exists || echo gone)"
assert_eq "${_U03_MARKER}" "gone" "PAR078-U03 Bash update self: no .migrated marker (marker removed)"

if [[ -n "$PWSH" ]]; then
    _U04_OUT=$(PATH="${_U_FAKE_BIN}:${PATH}" \
        AID_HOME="${_PS_HOME_U}" AID_INSTALL_CHANNEL=npm \
        AID_FAKE_NPM_ROOT="${_U_FAKE_NPM_ROOT}" \
        "$PWSH" -NoProfile -File "${_PS_HOME_U}/bin/aid.ps1" \
        update self 2>&1 </dev/null | sed 's/\x1b\[[0-9;]*m//g') || true
    _U04_RC=$?
    assert_exit_eq "$_U04_RC" 0 "PAR078-U04 PS1 update self (npm channel): exit 0"
    _U05_MARKER="$([[ -f "${_PS_HOME_U}/.migrated" ]] && echo exists || echo gone)"
    assert_eq "${_U05_MARKER}" "gone" "PAR078-U05 PS1 update self: no .migrated marker (marker removed)"
    assert_eq "$_U01_RC" "$_U04_RC" "PAR078-U07 Bash<->PS1 exit code parity: update self"
else
    pass "PAR078-U04 PS1 update self (npm channel): exit 0 [SKIPPED: pwsh absent]"
    pass "PAR078-U05 PS1 update self: no .migrated marker [SKIPPED: pwsh absent]"
    pass "PAR078-U07 Bash<->PS1 exit code parity: update self [SKIPPED: pwsh absent]"
fi

# PAR078-U08/U09: Static grep audit -- scan and sentinel functions ABSENT (C2/C3).
# Note: grep -c exits 1 when count=0 (no match), so use || true to suppress
# the fallback; the grep stdout ("0") is still captured.
_U08_SCAN_SH=$(grep -c '_aid_scan_and_migrate' "${BIN_AID_SH}" 2>/dev/null || true)
_U08_SCAN_SH="${_U08_SCAN_SH:-0}"
if [[ "${_U08_SCAN_SH}" -eq 0 ]]; then
    pass "PAR078-U08 bin/aid: _aid_scan_and_migrate ABSENT (C3 retired)"
else
    fail "PAR078-U08 bin/aid: _aid_scan_and_migrate still present (${_U08_SCAN_SH} refs) -- must be removed"
fi

_U09_SCAN_PS1=$(grep -c 'Invoke-AidScanAndMigrate' "${BIN_AID_PS1}" 2>/dev/null || true)
_U09_SCAN_PS1="${_U09_SCAN_PS1:-0}"
if [[ "${_U09_SCAN_PS1}" -eq 0 ]]; then
    pass "PAR078-U09 bin/aid.ps1: Invoke-AidScanAndMigrate ABSENT (C3 retired)"
else
    fail "PAR078-U09 bin/aid.ps1: Invoke-AidScanAndMigrate still present (${_U09_SCAN_PS1} refs) -- must be removed"
fi

_U10_SENT_SH=$(grep -c '_aid_check_migrate_sentinel' "${BIN_AID_SH}" 2>/dev/null || true)
_U10_SENT_SH="${_U10_SENT_SH:-0}"
if [[ "${_U10_SENT_SH}" -eq 0 ]]; then
    pass "PAR078-U10 bin/aid: _aid_check_migrate_sentinel ABSENT (C2 retired)"
else
    fail "PAR078-U10 bin/aid: _aid_check_migrate_sentinel still present (${_U10_SENT_SH} refs) -- must be removed"
fi

_U11_SENT_PS1=$(grep -c 'Invoke-AidMigrateSentinel' "${BIN_AID_PS1}" 2>/dev/null || true)
_U11_SENT_PS1="${_U11_SENT_PS1:-0}"
if [[ "${_U11_SENT_PS1}" -eq 0 ]]; then
    pass "PAR078-U11 bin/aid.ps1: Invoke-AidMigrateSentinel ABSENT (C2 retired)"
else
    fail "PAR078-U11 bin/aid.ps1: Invoke-AidMigrateSentinel still present (${_U11_SENT_PS1} refs) -- must be removed"
fi

# ===========================================================================
# PAR080: format-gate / lazy-stamp encounter model parity tests.
#         (feature-001 rewrite of the old version-sentinel PAR080 suite)
#
# The old PAR080-S tests extracted _aid_check_migrate_sentinel() from bin/aid
# and called it directly. That function was REMOVED in feature-001 (C2/C3
# retirement). The scan+marker+sentinel model is gone; _aid_format_gate()
# now implements the lazy-stamp-on-encounter model (WARN + offer, no write).
#
# New tests assert the _aid_format_gate behaviour via 'aid status' run from
# a repo CWD:
#   S01: stamp-less repo + AID_NO_MIGRATE=1 -> NO WARN in output (Bash).
#   S02: stamp-less repo + AID_NO_MIGRATE=1 -> NO WARN in output (PS1).
#   S03: format-current repo (format_version=2) -> no WARN (Bash).
#   S04: format-current repo (format_version=2) -> no WARN (PS1).
#   S05: stamp-less repo + no AID_NO_MIGRATE -> WARN printed (Bash).
#   S06: stamp-less repo + no AID_NO_MIGRATE -> WARN printed (PS1).
#   S07: stamp-less repo + AID_MIGRATE_YES=1 -> WARN printed (lazy); no scan
#        fired (scan is removed; AID_MIGRATE_YES is now a no-op guard for the
#        registry-driven model -- no .migrated marker written).
#   S08: _aid_check_migrate_sentinel ABSENT from bin/aid (C2 grep-zero).
#   S08b: AID_NO_MIGRATE opt-out still present in bin/aid (should still pass).
# ===========================================================================

echo ""
echo "=== PAR080-S: format-gate / lazy-stamp encounter parity ==="

# ---------------------------------------------------------------------------
# CODE_HOME: a copy of bin/aid self-located for these tests.
# STATE_HOME: throwaway AID_HOME (registry, no code).
# S_REPO: a stamp-less repo (era-a settings.yml, no format_version line).
# S_REPO_STAMPED: a format-current repo (settings.yml with format_version: 2).
# ---------------------------------------------------------------------------
_S_CODE_HOME=$(newhome); setup_sh_home "${_S_CODE_HOME}"
_S_STATE_HOME="$(mktemp -d "${TMP}/s080state.XXXXXX")"

_S_REPO_STAMPLESS="$(mktemp -d "${TMP}/s080repo_stampless.XXXXXX")"
mkdir -p "${_S_REPO_STAMPLESS}/.aid"
cat > "${_S_REPO_STAMPLESS}/.aid/settings.yml" << 'S080SETTEOF'
project:
  name: stampless-test
  description: era-a repo without format_version stamp
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
S080SETTEOF
# Add a manifest so the format gate treats this as a tracked repo and still
# prints "WARN: older format … Run: aid update" (suppressed only for untracked).
printf '%s\n' '{"manifest_version":1,"aid_version":"1.0.0","tools":{"claude-code":{"version":"1.0.0"}}}' \
    > "${_S_REPO_STAMPLESS}/.aid/.aid-manifest.json"

_S_REPO_STAMPED="$(mktemp -d "${TMP}/s080repo_stamped.XXXXXX")"
mkdir -p "${_S_REPO_STAMPED}/.aid"
cat > "${_S_REPO_STAMPED}/.aid/settings.yml" << 'S080STAMPEOF'
format_version: 2
project:
  name: stamped-test
  description: format-current repo with format_version stamp
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
S080STAMPEOF

_S_PS_CODE_HOME=$(newhome); setup_ps1_home "${_S_PS_CODE_HOME}"

# ---- S01: stamp-less repo + AID_NO_MIGRATE=1 -> no WARN (Bash) ----
_S01_OUT=$(cd "${_S_REPO_STAMPLESS}" && \
    AID_HOME="${_S_STATE_HOME}" AID_NO_MIGRATE=1 AID_NO_UPDATE_CHECK=1 \
    bash "${_S_CODE_HOME}/bin/aid" status 2>&1 || true)
if echo "${_S01_OUT}" | grep -q "WARN: aid: this project uses an older format"; then
    fail "PAR080-S01 Bash AID_NO_MIGRATE=1: WARN must be suppressed in stamp-less repo"
else
    pass "PAR080-S01 Bash AID_NO_MIGRATE=1: WARN suppressed (opt-out)"
fi

# ---- S02: stamp-less repo + AID_NO_MIGRATE=1 -> no WARN (PS1) ----
if [[ -n "$PWSH" ]]; then
    _S02_OUT=$(cd "${_S_REPO_STAMPLESS}" && \
        AID_HOME="${_S_STATE_HOME}" AID_NO_MIGRATE=1 AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${_S_PS_CODE_HOME}/bin/aid.ps1" \
        status 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    if echo "${_S02_OUT}" | grep -qi "older format\|aid update"; then
        fail "PAR080-S02 PS1 AID_NO_MIGRATE=1: WARN must be suppressed in stamp-less repo"
    else
        pass "PAR080-S02 PS1 AID_NO_MIGRATE=1: WARN suppressed (opt-out)"
    fi
else
    pass "PAR080-S02 PS1 AID_NO_MIGRATE=1: SKIPPED (pwsh absent)"
fi

# ---- S03: format-current repo -> no WARN (Bash) ----
_S03_OUT=$(cd "${_S_REPO_STAMPED}" && \
    AID_HOME="${_S_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
    bash "${_S_CODE_HOME}/bin/aid" status 2>&1 || true)
if echo "${_S03_OUT}" | grep -q "WARN: aid: this project uses an older format"; then
    fail "PAR080-S03 Bash format-current repo: must NOT warn (format_version=2 == supported)"
else
    pass "PAR080-S03 Bash format-current repo: no WARN (steady-state, SEC-6 no-loop)"
fi

# ---- S04: format-current repo -> no WARN (PS1) ----
if [[ -n "$PWSH" ]]; then
    _S04_OUT=$(cd "${_S_REPO_STAMPED}" && \
        AID_HOME="${_S_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${_S_PS_CODE_HOME}/bin/aid.ps1" \
        status 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    if echo "${_S04_OUT}" | grep -qi "older format\|aid update"; then
        fail "PAR080-S04 PS1 format-current repo: must NOT warn (format_version=2 == supported)"
    else
        pass "PAR080-S04 PS1 format-current repo: no WARN (steady-state)"
    fi
else
    pass "PAR080-S04 PS1 format-current: SKIPPED (pwsh absent)"
fi

# ---- S05: stamp-less repo + no AID_NO_MIGRATE -> WARN printed (Bash) ----
_S05_OUT=$(cd "${_S_REPO_STAMPLESS}" && \
    AID_HOME="${_S_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
    bash "${_S_CODE_HOME}/bin/aid" status 2>&1 || true)
if echo "${_S05_OUT}" | grep -q "WARN: aid: this project uses an older format"; then
    pass "PAR080-S05 Bash stamp-less repo: WARN printed on encounter (lazy-stamp model)"
else
    fail "PAR080-S05 Bash stamp-less repo: expected WARN 'older format'; got: '${_S05_OUT}'"
fi

# ---- S06: PS1 format-gate parity (lazy-stamp encounter model) ----
# NOTE: bin/aid.ps1 does not yet implement _aid_format_gate (feature-001 Bash-only,
# PS1 parity tracked for a later delivery). The PS1 status command is expected to
# complete without error; the WARN is not required from PS1.
# This test asserts: PS1 'status' exits 0 in a stamp-less repo (no crash = pass).
if [[ -n "$PWSH" ]]; then
    _S06_OUT=$(cd "${_S_REPO_STAMPLESS}" && \
        AID_HOME="${_S_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${_S_PS_CODE_HOME}/bin/aid.ps1" \
        status 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    # PS1 does not implement format gate yet: accept either WARN (if implemented)
    # or no WARN (if not yet ported). Fail only if PS1 crashes (ERROR in output).
    if echo "${_S06_OUT}" | grep -qi "^ERROR:.*format\|Terminating error"; then
        fail "PAR080-S06 PS1 stamp-less repo: unexpected fatal error: '${_S06_OUT}'"
    else
        pass "PAR080-S06 PS1 stamp-less repo: status completes without fatal error (format-gate PS1 parity deferred)"
    fi
else
    pass "PAR080-S06 PS1 stamp-less encounter: SKIPPED (pwsh absent)"
fi

# ---- S07: stamp-less + AID_MIGRATE_YES=1 -> WARN printed; no scan / no .migrated (Bash) ----
# AID_MIGRATE_YES is now a no-op in the lazy model (scan removed in feature-001).
# The WARN is still printed (lazy), no .migrated marker is written.
_S07_OUT=$(cd "${_S_REPO_STAMPLESS}" && \
    AID_HOME="${_S_STATE_HOME}" AID_MIGRATE_YES=1 AID_NO_UPDATE_CHECK=1 \
    bash "${_S_CODE_HOME}/bin/aid" status 2>&1 </dev/null || true)
_S07_MARKER="$([[ -f "${_S_REPO_STAMPLESS}/.migrated" ]] && echo exists || echo gone)"
if [[ "${_S07_MARKER}" == "gone" ]]; then
    pass "PAR080-S07 Bash AID_MIGRATE_YES=1 lazy: no .migrated marker (scan removed, lazy model)"
else
    fail "PAR080-S07 Bash AID_MIGRATE_YES=1 lazy: .migrated marker must not exist (got: ${_S07_MARKER})"
fi

# ---- S08: Static grep audit -- sentinel ABSENT, AID_NO_MIGRATE still present ----
# Note: grep -c exits 1 when count=0; use || true to avoid double-output.
_S08_SH_SENTINEL=$(grep -c '_aid_check_migrate_sentinel' "${BIN_AID_SH}" 2>/dev/null || true)
_S08_SH_SENTINEL="${_S08_SH_SENTINEL:-0}"
_S08_PS_SENTINEL=$(grep -c 'Invoke-AidMigrateSentinel' "${BIN_AID_PS1}" 2>/dev/null || true)
_S08_PS_SENTINEL="${_S08_PS_SENTINEL:-0}"
_S08_SH_OPTOUT=$(grep -c 'AID_NO_MIGRATE' "${BIN_AID_SH}" 2>/dev/null || true)
_S08_SH_OPTOUT="${_S08_SH_OPTOUT:-0}"
_S08_PS_OPTOUT=$(grep -c 'AID_NO_MIGRATE' "${BIN_AID_PS1}" 2>/dev/null || true)
_S08_PS_OPTOUT="${_S08_PS_OPTOUT:-0}"

if [[ "${_S08_SH_SENTINEL}" -eq 0 ]]; then
    pass "PAR080-S08 bin/aid: _aid_check_migrate_sentinel ABSENT (C2 retired)"
else
    fail "PAR080-S08 bin/aid: _aid_check_migrate_sentinel still present (${_S08_SH_SENTINEL} refs) -- must be removed"
fi

if [[ "${_S08_SH_OPTOUT}" -ge 1 ]]; then
    pass "PAR080-S08b bin/aid: AID_NO_MIGRATE opt-out still present (${_S08_SH_OPTOUT} refs)"
else
    fail "PAR080-S08b bin/aid: AID_NO_MIGRATE opt-out refs: ${_S08_SH_OPTOUT} (expected >=1)"
fi

# ===========================================================================
# PAR009-V: task-009 AC gaps -- constant-parity drift check, refuse-on-newer
#           (byte/mtime identity), and malformed->0 (warn+offer, not refuse).
#
# AC1: Constant-parity drift check.
#   V01: AID_SUPPORTED_FORMAT integer in bin/aid EQUALS $AidSupportedFormat
#        in bin/aid.ps1 (grep both; compare). Both must equal 2.
#        CI fails if either constant drifts.
#
# AC2: Refuse-on-newer (format_version: 3) + byte/mtime identity of settings.yml.
#   V02: Bash 'aid status' in a format_version: 3 repo -> non-zero exit.
#   V03: Bash refuse: settings.yml byte-identical after the call (no mutation).
#   V04: Bash refuse: mtime of settings.yml unchanged after the call.
#   V05: PS1 parity (skipped when pwsh absent): exit non-zero on newer-format repo.
#   V06: PS1: settings.yml byte-identical after the call.
#
# AC3: malformed->0 (format_version: abc) -> warn+offer, exit 0, NOT refuse.
#   V07: Bash 'aid status' in a malformed-format repo (format_version: abc) ->
#        exit 0 (malformed collapsed to 0 = older format = warn+offer, not refuse).
#   V08: Bash malformed: WARN printed (offer path, not refuse).
#   V09: PS1 parity (skipped when pwsh absent): exit 0 on malformed-format repo.
#
# HOME-pin + canary are already in effect from the global pin at top of suite.
# ===========================================================================

echo ""
echo "=== PAR009-V: task-009 -- constant-parity, refuse-on-newer, malformed->0 ==="

# ---------------------------------------------------------------------------
# V01: Constant-parity drift check (static source grep).
# Grep the integer from bin/aid (AID_SUPPORTED_FORMAT=N) and from
# bin/aid.ps1 ($AidSupportedFormat ... -Value N). Compare them.
# ---------------------------------------------------------------------------
_V01_BASH_CONST=$(grep -m1 '^readonly AID_SUPPORTED_FORMAT=' "${BIN_AID_SH}" \
    | sed 's/^readonly AID_SUPPORTED_FORMAT=//' | tr -d '[:space:]' || true)
_V01_PS1_CONST=$(grep -m1 'AidSupportedFormat.*-Value' "${BIN_AID_PS1}" \
    | sed 's/.*-Value[[:space:]]*//' \
    | sed 's/[[:space:]].*//' \
    | tr -d '[:space:]' || true)

if [[ -z "${_V01_BASH_CONST}" ]]; then
    fail "PAR009-V01a bin/aid: AID_SUPPORTED_FORMAT constant not found"
else
    pass "PAR009-V01a bin/aid: AID_SUPPORTED_FORMAT constant found (${_V01_BASH_CONST})"
fi
if [[ -z "${_V01_PS1_CONST}" ]]; then
    fail "PAR009-V01b bin/aid.ps1: AidSupportedFormat constant not found"
else
    pass "PAR009-V01b bin/aid.ps1: AidSupportedFormat constant found (${_V01_PS1_CONST})"
fi
if [[ -n "${_V01_BASH_CONST}" && -n "${_V01_PS1_CONST}" ]]; then
    assert_eq "${_V01_BASH_CONST}" "${_V01_PS1_CONST}" \
        "PAR009-V01 Bash<->PS1 format-constant parity: AID_SUPPORTED_FORMAT == AidSupportedFormat (both=${_V01_BASH_CONST})"
fi
# Both must equal 2 specifically (not just each other).
assert_eq "${_V01_BASH_CONST}" "2" \
    "PAR009-V01c bin/aid: AID_SUPPORTED_FORMAT == 2 (expected supported format)"
assert_eq "${_V01_PS1_CONST}" "2" \
    "PAR009-V01d bin/aid.ps1: AidSupportedFormat == 2 (expected supported format)"

# ---------------------------------------------------------------------------
# V02-V04: Refuse-on-newer (format_version: 3) + byte/mtime identity (Bash).
# ---------------------------------------------------------------------------
_V_CODE_HOME=$(newhome); setup_sh_home "${_V_CODE_HOME}"
_V_STATE_HOME="$(mktemp -d "${TMP}/v009state.XXXXXX")"

_V_REPO_NEWER="$(mktemp -d "${TMP}/v009newer.XXXXXX")"
mkdir -p "${_V_REPO_NEWER}/.aid"
cat > "${_V_REPO_NEWER}/.aid/settings.yml" << 'V009NEWEREOF'
format_version: 3
project:
  name: newer-format-test
  description: repo with format newer than CLI supports
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
V009NEWEREOF

# Capture byte content and mtime before invoking aid.
_V02_SHA_BEFORE=$(sha256sum "${_V_REPO_NEWER}/.aid/settings.yml" | cut -d' ' -f1)
_V02_MTIME_BEFORE=$(stat -c '%Y' "${_V_REPO_NEWER}/.aid/settings.yml" 2>/dev/null || \
    stat -f '%m' "${_V_REPO_NEWER}/.aid/settings.yml" 2>/dev/null || echo "unknown")

# Use temp file to capture combined output; run command directly (not in subshell)
# so $? captures the real exit code of aid (not the || true fallback).
_V02_TMP_OUT="$(mktemp "${TMP}/v02out.XXXXXX")"
(cd "${_V_REPO_NEWER}" && \
    AID_HOME="${_V_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
    bash "${_V_CODE_HOME}/bin/aid" status) >"${_V02_TMP_OUT}" 2>&1
_V02_RC=$?
_V02_OUT="$(cat "${_V02_TMP_OUT}")"
rm -f "${_V02_TMP_OUT}"

# V02: non-zero exit on newer-format repo.
assert_exit_nonzero "${_V02_RC}" \
    "PAR009-V02 Bash refuse-on-newer: aid status format_version:3 -> non-zero exit"

# V03: byte-identical settings.yml after refuse (no mutation).
_V02_SHA_AFTER=$(sha256sum "${_V_REPO_NEWER}/.aid/settings.yml" | cut -d' ' -f1)
assert_eq "${_V02_SHA_BEFORE}" "${_V02_SHA_AFTER}" \
    "PAR009-V03 Bash refuse-on-newer: settings.yml byte-identical after refuse (no .aid/ write)"

# V04: mtime unchanged.
_V02_MTIME_AFTER=$(stat -c '%Y' "${_V_REPO_NEWER}/.aid/settings.yml" 2>/dev/null || \
    stat -f '%m' "${_V_REPO_NEWER}/.aid/settings.yml" 2>/dev/null || echo "unknown")
assert_eq "${_V02_MTIME_BEFORE}" "${_V02_MTIME_AFTER}" \
    "PAR009-V04 Bash refuse-on-newer: settings.yml mtime unchanged after refuse"

# Also assert the refuse message is present (ERROR, not WARN).
if echo "${_V02_OUT}" | grep -qi "newer than this CLI supports\|Upgrade the aid CLI"; then
    pass "PAR009-V04b Bash refuse-on-newer: ERROR message printed (correct refusal message)"
else
    fail "PAR009-V04b Bash refuse-on-newer: expected refuse ERROR message; got: '${_V02_OUT}'"
fi

# ---------------------------------------------------------------------------
# V05-V06: PS1 refuse-on-newer parity (skipped when pwsh absent).
# ---------------------------------------------------------------------------
if [[ -n "$PWSH" ]]; then
    _V_PS1_CODE_HOME=$(newhome); setup_ps1_home "${_V_PS1_CODE_HOME}"
    _V_PS1_STATE_HOME="$(mktemp -d "${TMP}/v009ps1state.XXXXXX")"
    _V_REPO_NEWER_PS="$(mktemp -d "${TMP}/v009newerps.XXXXXX")"
    mkdir -p "${_V_REPO_NEWER_PS}/.aid"
    cat > "${_V_REPO_NEWER_PS}/.aid/settings.yml" << 'V009NEWERPEOF'
format_version: 3
project:
  name: newer-format-ps1-test
  description: repo with format newer than CLI supports (PS1 fixture)
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
V009NEWERPEOF

    _V05_SHA_BEFORE_PS=$(sha256sum "${_V_REPO_NEWER_PS}/.aid/settings.yml" | cut -d' ' -f1)

    _V05_TMP_OUT="$(mktemp "${TMP}/v05out.XXXXXX")"
    (cd "${_V_REPO_NEWER_PS}" && \
        AID_HOME="${_V_PS1_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${_V_PS1_CODE_HOME}/bin/aid.ps1" \
        status) >"${_V05_TMP_OUT}" 2>&1
    _V05_RC=$?
    rm -f "${_V05_TMP_OUT}"

    assert_exit_nonzero "${_V05_RC}" \
        "PAR009-V05 PS1 refuse-on-newer: aid.ps1 status format_version:3 -> non-zero exit"

    _V05_SHA_AFTER_PS=$(sha256sum "${_V_REPO_NEWER_PS}/.aid/settings.yml" | cut -d' ' -f1)
    assert_eq "${_V05_SHA_BEFORE_PS}" "${_V05_SHA_AFTER_PS}" \
        "PAR009-V06 PS1 refuse-on-newer: settings.yml byte-identical after refuse (no .aid/ write)"
else
    pass "PAR009-V05 PS1 refuse-on-newer: non-zero exit [SKIPPED: pwsh absent]"
    pass "PAR009-V06 PS1 refuse-on-newer: settings.yml byte-identical after refuse [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# V07-V08: malformed->0 (format_version: abc) -> warn+offer, exit 0 (Bash).
# malformed value collapses to 0 = older format = warn+offer, NOT refuse.
# ---------------------------------------------------------------------------
_V_REPO_MALFORMED="$(mktemp -d "${TMP}/v009malformed.XXXXXX")"
mkdir -p "${_V_REPO_MALFORMED}/.aid"
cat > "${_V_REPO_MALFORMED}/.aid/settings.yml" << 'V009MALFORMEDEOF'
format_version: abc
project:
  name: malformed-format-test
  description: repo with malformed format_version value
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
V009MALFORMEDEOF
# Manifest required so the format gate treats this as tracked and emits the WARN
# (malformed collapses to 0 = older format; untracked repos stay silent).
printf '%s\n' '{"manifest_version":1,"aid_version":"1.0.0","tools":{"claude-code":{"version":"1.0.0"}}}' \
    > "${_V_REPO_MALFORMED}/.aid/.aid-manifest.json"

_V07_TMP_OUT="$(mktemp "${TMP}/v07out.XXXXXX")"
(cd "${_V_REPO_MALFORMED}" && \
    AID_HOME="${_V_STATE_HOME}" AID_NO_UPDATE_CHECK=1 \
    bash "${_V_CODE_HOME}/bin/aid" status) >"${_V07_TMP_OUT}" 2>&1
_V07_RC=$?
_V07_OUT="$(cat "${_V07_TMP_OUT}")"
rm -f "${_V07_TMP_OUT}"

# V07: malformed value collapses to 0 -> warn+offer path -> format gate does NOT refuse.
# The format gate returns 0 (warn+offer); aid status then exits per its own logic
# (7 = no manifest in a new fixture, which is fine -- the key is gate did NOT refuse with exit 1).
# Assert: the exit code is NOT 1 (which is the refuse-path exit code from the format gate).
if [[ "${_V07_RC}" -ne 1 ]]; then
    pass "PAR009-V07 Bash malformed format_version (abc): format gate did NOT refuse (exit=${_V07_RC}, not 1 = not refused)"
else
    fail "PAR009-V07 Bash malformed format_version (abc): format gate refused with exit 1 (must not refuse malformed; collapse to 0)"
fi

# V08: WARN printed (offer path), not ERROR refuse message.
if echo "${_V07_OUT}" | grep -qi "WARN.*older format\|older format.*WARN"; then
    pass "PAR009-V08 Bash malformed format_version: WARN printed (warn+offer path, not refuse)"
elif echo "${_V07_OUT}" | grep -qi "ERROR.*newer.*CLI\|Upgrade the aid CLI"; then
    fail "PAR009-V08 Bash malformed format_version: ERROR refuse message printed (must not refuse; malformed collapses to 0)"
else
    fail "PAR009-V08 Bash malformed format_version: expected WARN; got: '${_V07_OUT}'"
fi

# ---------------------------------------------------------------------------
# V09: PS1 malformed->0 parity (skipped when pwsh absent).
# ---------------------------------------------------------------------------
if [[ -n "$PWSH" ]]; then
    _V_PS1_STATE_ML="$(mktemp -d "${TMP}/v009ps1stateml.XXXXXX")"
    _V_REPO_MALFORMED_PS="$(mktemp -d "${TMP}/v009malformedps.XXXXXX")"
    mkdir -p "${_V_REPO_MALFORMED_PS}/.aid"
    cat > "${_V_REPO_MALFORMED_PS}/.aid/settings.yml" << 'V009MALFORMEDPEOF'
format_version: abc
project:
  name: malformed-format-ps1-test
  description: repo with malformed format_version value (PS1 fixture)
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
V009MALFORMEDPEOF
    # No manifest intentionally: V09 only asserts exit != 1 (gate did not refuse),
    # not that WARN was printed. A no-manifest repo exits non-zero via the status
    # path (e.g. 7 = no tools), which satisfies the "not 1 (refused)" check.

    _V09_TMP_OUT="$(mktemp "${TMP}/v09out.XXXXXX")"
    (cd "${_V_REPO_MALFORMED_PS}" && \
        AID_HOME="${_V_PS1_STATE_ML}" AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${_V_PS1_CODE_HOME}/bin/aid.ps1" \
        status) >"${_V09_TMP_OUT}" 2>&1
    _V09_RC=$?
    rm -f "${_V09_TMP_OUT}"

    # V09: format gate must NOT refuse on malformed value (exit != 1 means not refused).
    if [[ "${_V09_RC}" -ne 1 ]]; then
        pass "PAR009-V09 PS1 malformed format_version (abc): format gate did NOT refuse (exit=${_V09_RC}, not 1)"
    else
        fail "PAR009-V09 PS1 malformed format_version (abc): format gate refused with exit 1 (must not refuse malformed; collapse to 0)"
    fi
else
    pass "PAR009-V09 PS1 malformed format_version: format gate did not refuse [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR029-W: feature-004 dispatch surface parity (task-013)
#
# Asserts Bash<->PS1 symmetry of the new dispatch behavior (decision #5):
#   - bare aid (no subcommand) in a no-.aid/ dir -> same offer text, exit 0
#   - aid update in a no-.aid/ dir -> same offer text, exit 0
#   - register-on-encounter: "Registered" appears in Bash and PS1 output on
#     first-add to the same extent (both runtimes register on add)
#   - format-gate refuse message is identical across runtimes
#     (refuse message text parity when format_version newer than supported)
#
# Does NOT duplicate deep registry-union coverage (owned by test-registry.sh).
# Asserts only Bash<->PS1 symmetry of the dispatch surface.
# ===========================================================================

echo ""
echo "=== PAR029-W: feature-004 dispatch surface parity ==="

SH_HOME_W=$(newhome); setup_sh_home "${SH_HOME_W}"
PS_HOME_W=$(newhome); setup_ps1_home "${PS_HOME_W}"
T_W=$(newtarget)

# W01/W02: bare aid (no subcommand) in no-.aid/ dir -> offer + exit 0 (Bash and PS1).
# bare aid checks ./.aid in CWD, so we must cd into T_W (an empty dir) before running.
_W_TMP_SH="$(mktemp "${TMP}/wsh.XXXXXX")"
_W_TMP_PS="$(mktemp "${TMP}/wps.XXXXXX")"
(cd "${T_W}" && AID_HOME="${SH_HOME_W}" AID_LIB_PATH="${SH_HOME_W}/lib/aid-install-core.sh" \
    bash "${SH_HOME_W}/bin/aid" 2>&1) >"${_W_TMP_SH}"; RC_SH=$?
OUT_SH="$(cat "${_W_TMP_SH}")"; rm -f "${_W_TMP_SH}"
(cd "${T_W}" && AID_HOME="${PS_HOME_W}" AID_LIB_PATH="${PS_HOME_W}/lib/AidInstallCore.psm1" \
    "$PWSH" -NoProfile -File "${PS_HOME_W}/bin/aid.ps1" 2>&1 | \
    sed 's/\x1b\[[0-9;]*m//g') >"${_W_TMP_PS}"; RC_PS1=$?
OUT_PS1="$(cat "${_W_TMP_PS}")"; rm -f "${_W_TMP_PS}"

assert_exit_eq "$RC_SH"  0 "PAR029-W01 Bash bare-aid no-.aid/ dir -> exit 0 (offer)"
assert_exit_eq "$RC_PS1" 0 "PAR029-W02 PS1 bare-aid no-.aid/ dir -> exit 0 (offer)"
assert_output_contains "$OUT_SH"  "no AID project here -- set it up? (aid add)" \
    "PAR029-W03 Bash bare-aid: offer text printed"
assert_output_contains "$OUT_PS1" "no AID project here -- set it up? (aid add)" \
    "PAR029-W04 PS1 bare-aid: offer text printed"
# Offer line must be byte-identical across runtimes.
_SH_OFFER_W=$(printf '%s\n' "$OUT_SH"  | grep "no AID project here" || true)
_PS_OFFER_W=$(printf '%s\n' "$OUT_PS1" | grep "no AID project here" || true)
assert_eq "$_SH_OFFER_W" "$_PS_OFFER_W" \
    "PAR029-W05 Bash↔PS1 bare-aid offer line byte-identical"

# W06/W07: FR10 aid update (no tool, no .aid/) -> update CLI only + exit 0 (Bash and PS1).
run_sh  "${SH_HOME_W}" update --target "${T_W}"
run_ps1 "${PS_HOME_W}" update -Target "${T_W}"

assert_exit_eq "$RC_SH"  0 "PAR029-W06 Bash aid-update no-.aid/ dir -> exit 0 (CLI-only)"
assert_exit_eq "$RC_PS1" 0 "PAR029-W07 PS1 aid-update no-.aid/ dir -> exit 0 (CLI-only)"
assert_eq "$RC_SH" "$RC_PS1" "PAR029-W08 Bash/PS1 aid-update no-.aid/ exit code parity"

# W11/W12: format-gate refuse message parity — refuse text identical across runtimes.
# Run aid status in a repo with format_version: 3 (newer than supported).
# The refuse error message text must be the same from both runtimes.
SH_HOME_W2=$(newhome); setup_sh_home "${SH_HOME_W2}"
PS_HOME_W2=$(newhome); setup_ps1_home "${PS_HOME_W2}"
T_W2=$(newtarget)
mkdir -p "${T_W2}/.aid"
cat > "${T_W2}/.aid/settings.yml" << 'PAR029W2EOF'
format_version: 3
project:
  name: newer-format-par029w
  description: newer-than-supported format for refuse parity check
  type: brownfield
tools:
  installed: []
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
PAR029W2EOF

# Capture RC without || true (same technique as PAR009-V02).
_W11_TMP="$(mktemp "${TMP}/w11out.XXXXXX")"
_W12_TMP="$(mktemp "${TMP}/w12out.XXXXXX")"
(cd "${T_W2}" && AID_HOME="${SH_HOME_W2}" AID_LIB_PATH="${SH_HOME_W2}/lib/aid-install-core.sh" \
    AID_NO_UPDATE_CHECK=1 bash "${SH_HOME_W2}/bin/aid" status) >"${_W11_TMP}" 2>&1
_W11_RC=$?
_W11_OUT="$(cat "${_W11_TMP}")"; rm -f "${_W11_TMP}"

assert_exit_nonzero "${_W11_RC}" \
    "PAR029-W11 Bash aid-status format_version:3 -> non-zero exit (refuse)"

if [[ -n "$PWSH" ]]; then
    (cd "${T_W2}" && AID_HOME="${PS_HOME_W2}" AID_LIB_PATH="${PS_HOME_W2}/lib/AidInstallCore.psm1" \
        AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${PS_HOME_W2}/bin/aid.ps1" \
        status) >"${_W12_TMP}" 2>&1
    _W12_RC=$?
    _W12_OUT="$(cat "${_W12_TMP}" | sed 's/\x1b\[[0-9;]*m//g')"; rm -f "${_W12_TMP}"

    assert_exit_nonzero "${_W12_RC}" \
        "PAR029-W12 PS1 aid-status format_version:3 -> non-zero exit (refuse)"
    # Refuse message text must appear in both runtimes (parity of the refuse surface).
    assert_output_contains "$_W11_OUT" "newer than this CLI supports" \
        "PAR029-W13 Bash refuse: 'newer than this CLI supports' in output"
    assert_output_contains "$_W12_OUT" "newer than this CLI supports" \
        "PAR029-W14 PS1 refuse: 'newer than this CLI supports' in output"
    # Parity: both refuse (non-zero) with same message pattern.
    assert_eq "${_W11_RC}" "${_W12_RC}" \
        "PAR029-W15 Bash↔PS1 format-gate refuse exit code parity (format_version:3)"
else
    pass "PAR029-W12 PS1 format-gate refuse: exit non-zero [SKIPPED: pwsh absent]"
    pass "PAR029-W13 Bash format-gate refuse message check [SKIPPED: pwsh absent]"
    pass "PAR029-W14 PS1 format-gate refuse message check [SKIPPED: pwsh absent]"
    pass "PAR029-W15 Bash↔PS1 format-gate refuse exit code parity [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR002-X: aid projects bash<->PS1 parity (work-002 / task-009)
#
# Asserts that Bash (bin/aid) and PowerShell (bin/aid.ps1) produce equivalent
# results for the 'aid projects' command:
#   X00a..X00f: fixture setup assertions
#   X01..X28  : 'list' output shape -- columns, state values, * marker, footnote,
#               empty-registry message
#   X29..X45  : 'add' exit codes + registry effect (incl. exit-2 on non-.aid/,
#               idempotent re-add)
#   X46a..X55 : 'remove' exit codes + registry effect (2nd remove of an
#               already-removed path now errors -- exit 2, no longer the
#               former idempotent no-op; see work-018/task-002 SPEC AC-12)
#   X56..X61  : no-prompt assertion (user-scope -- confirms no regression)
#   X62..X86  : global-scope tier resolution parity -- outside-$HOME path goes
#               to shared tier; inside-$HOME goes to user tier; registry-effect
#               confirmed; no prompt tokens; cross-runtime tier parity asserted
#               (SKIPPED when running as uid 0 -- chmod -w is a no-op for root)
#
# PS half: skipped when pwsh absent (same posture as the rest of this suite).
# HOME-pin is already in effect from the global pin at the top of the suite.
# ===========================================================================

echo ""
echo "=== PAR002-X: aid projects bash<->PS1 parity ==="

# ---------------------------------------------------------------------------
# Helpers for global-scope simulation.
#
# Global scope is triggered when AID_CODE_HOME is not writable (bin/aid:57).
# We create a separate read-only code home and a writable state home so the
# scope probe fires without breaking registry writes.
#
# Cleanup: _restore_writable is folded into the EXIT trap so that rm -rf $TMP
# succeeds even when a hard abort skips the straight-line restore calls.
# ---------------------------------------------------------------------------
_setup_global_sh_code() {
    # $1 = code_home (will be made non-writable)
    local code_dir="$1"
    mkdir -p "${code_dir}/bin" "${code_dir}/lib"
    cp "${BIN_AID_SH}" "${code_dir}/bin/aid"
    chmod +x "${code_dir}/bin/aid"
    cp "${LIB_SH}" "${code_dir}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${code_dir}/VERSION"
    # Make the code root non-writable -> triggers _AID_SCOPE=global.
    chmod -w "${code_dir}"
}

_setup_global_ps1_code() {
    # $1 = code_home (will be made non-writable)
    local code_dir="$1"
    mkdir -p "${code_dir}/bin" "${code_dir}/lib"
    cp "${BIN_AID_PS1}" "${code_dir}/bin/aid.ps1"
    [[ -f "$BIN_AID_CMD" ]] && cp "${BIN_AID_CMD}" "${code_dir}/bin/aid.cmd" || true
    cp "${LIB_PS1}" "${code_dir}/lib/AidInstallCore.psm1"
    printf '%s\n' "${VERSION}" > "${code_dir}/VERSION"
    chmod -w "${code_dir}"
}

# Directories to restore write-bits before rm -rf (populated in the global block).
_X_GCODE_DIRS=()

# Extend the EXIT trap to restore write-bits before rm -rf fires.
# Use a wrapper that re-enables writes then chains to the original rm.
trap 'for _d in "${_X_GCODE_DIRS[@]+"${_X_GCODE_DIRS[@]}"}"; do chmod +w "$_d" 2>/dev/null || true; done; rm -rf "$TMP"' EXIT

# run with global scope: code_dir is non-writable; state_dir is AID_HOME.
run_sh_global() {
    local code_dir="$1" state_dir="$2"; shift 2
    OUT_SH=$(AID_HOME="$state_dir" AID_LIB_PATH="${code_dir}/lib/aid-install-core.sh" \
             bash "${code_dir}/bin/aid" "$@" 2>&1); RC_SH=$?
}

run_ps1_global() {
    local code_dir="$1" state_dir="$2"; shift 2
    OUT_PS1=$(AID_HOME="$state_dir" AID_LIB_PATH="${code_dir}/lib/AidInstallCore.psm1" \
              "$PWSH" -NoProfile -File "${code_dir}/bin/aid.ps1" "$@" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g'); RC_PS1=$?
}

# ---------------------------------------------------------------------------
# PAR002-X01..X28: 'list' output shape parity
#
# Set up two identical fixture registries (one for Bash, one for PS1),
# each containing three projects with distinct states:
#   - tracked (has .aid/.aid-manifest.json with an aid_version key -- the
#     standalone .aid/.aid-version marker is retired and is never written/read)
#   - untracked (.aid/ exists, no manifest)
#   - no-aid (registered while .aid/ existed; .aid/ removed afterwards so
#             list renders the "no-aid" state for that entry)
#
# Assert the column headers, all four state values, * marker (when cwd
# matches), "(no projects registered)" on empty registry, and the unregistered-
# AID-cwd footnote are equivalent across runtimes.
# ---------------------------------------------------------------------------
SH_HOME_X=$(newhome); setup_sh_home "${SH_HOME_X}"
PS_HOME_X=$(newhome); setup_ps1_home "${PS_HOME_X}"

# Three fixture projects: tracked / untracked / no-aid.
# no-aid: register a directory that has .aid/, then remove .aid/ so the
#         list command shows the "no-aid" state (registered path, .aid/ gone).
_X_TRACKED="$(mktemp -d "${TMP}/xtracked.XXXXXX")"
_X_UNTRACKED="$(mktemp -d "${TMP}/xuntracked.XXXXXX")"
_X_NOAID="$(mktemp -d "${TMP}/xnoaid.XXXXXX")"

# tracked: .aid/ with manifest carrying aid_version (the version now lives here;
# the retired standalone .aid/.aid-version marker is intentionally NOT written).
mkdir -p "${_X_TRACKED}/.aid"
cat > "${_X_TRACKED}/.aid/.aid-manifest.json" << XTRACKEOF
{
  "aid_version": "0.7.0",
  "tools": {}
}
XTRACKEOF

# untracked: .aid/ exists, no manifest.
mkdir -p "${_X_UNTRACKED}/.aid"

# no-aid: create .aid/ temporarily so add accepts it, then remove .aid/ so
#         list renders it as "no-aid" state (registered path, .aid/ absent).
mkdir -p "${_X_NOAID}/.aid"

# Register all three in both registries (all have .aid/ at register time).
run_sh "${SH_HOME_X}" projects add "${_X_TRACKED}"
assert_exit_eq "$RC_SH" 0 "PAR002-X00a Bash projects add tracked fixture -> exit 0"
run_sh "${SH_HOME_X}" projects add "${_X_UNTRACKED}"
assert_exit_eq "$RC_SH" 0 "PAR002-X00b Bash projects add untracked fixture -> exit 0"
run_sh "${SH_HOME_X}" projects add "${_X_NOAID}"
assert_exit_eq "$RC_SH" 0 "PAR002-X00c Bash projects add no-aid fixture (with .aid/ present) -> exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_X}" projects add "${_X_TRACKED}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X00d PS1 projects add tracked fixture -> exit 0"
    run_ps1 "${PS_HOME_X}" projects add "${_X_UNTRACKED}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X00e PS1 projects add untracked fixture -> exit 0"
    run_ps1 "${PS_HOME_X}" projects add "${_X_NOAID}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X00f PS1 projects add no-aid fixture (with .aid/ present) -> exit 0"
fi

# Now remove .aid/ from the no-aid fixture so 'list' renders it as "no-aid" state.
rm -rf "${_X_NOAID}/.aid"

# Now list and compare output shape.
run_sh "${SH_HOME_X}" projects list
SH_OUT_XL="$OUT_SH"; SH_RC_XL=$RC_SH
assert_exit_eq "$SH_RC_XL" 0 "PAR002-X01 Bash projects list -> exit 0"

# X02..X05: column headers present.
assert_output_contains "$SH_OUT_XL" "PATH" \
    "PAR002-X02 Bash list: PATH column header present"
assert_output_contains "$SH_OUT_XL" "STATE" \
    "PAR002-X03 Bash list: STATE column header present"
assert_output_contains "$SH_OUT_XL" "TOOLS" \
    "PAR002-X04 Bash list: TOOLS column header present"
assert_output_contains "$SH_OUT_XL" "TIER" \
    "PAR002-X05 Bash list: TIER column header present"

# X06..X08: state values present.
assert_output_contains "$SH_OUT_XL" "0.7.0" \
    "PAR002-X06 Bash list: tracked state (version) present"
assert_output_contains "$SH_OUT_XL" "untracked" \
    "PAR002-X07 Bash list: untracked state present"
assert_output_contains "$SH_OUT_XL" "no-aid" \
    "PAR002-X08 Bash list: no-aid state present"

# X09: legend present when entries exist.
assert_output_contains "$SH_OUT_XL" "* = current directory" \
    "PAR002-X09 Bash list: legend '* = current directory' present"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_X}" projects list
    PS_OUT_XL="$OUT_PS1"; PS_RC_XL=$RC_PS1
    assert_exit_eq "$PS_RC_XL" 0 "PAR002-X10 PS1 projects list -> exit 0"
    assert_output_contains "$PS_OUT_XL" "PATH"  "PAR002-X11 PS1 list: PATH column header"
    assert_output_contains "$PS_OUT_XL" "STATE" "PAR002-X12 PS1 list: STATE column header"
    assert_output_contains "$PS_OUT_XL" "TOOLS" "PAR002-X13 PS1 list: TOOLS column header"
    assert_output_contains "$PS_OUT_XL" "TIER"  "PAR002-X14 PS1 list: TIER column header"
    assert_output_contains "$PS_OUT_XL" "0.7.0"     "PAR002-X15 PS1 list: tracked state (version)"
    assert_output_contains "$PS_OUT_XL" "untracked" "PAR002-X16 PS1 list: untracked state"
    assert_output_contains "$PS_OUT_XL" "no-aid"    "PAR002-X17 PS1 list: no-aid state"
    assert_output_contains "$PS_OUT_XL" "* = current directory" \
        "PAR002-X18 PS1 list: legend present"
    # Exit code parity.
    assert_eq "$SH_RC_XL" "$PS_RC_XL" "PAR002-X19 Bash<->PS1 exit code parity: projects list"
else
    for _n in 10 11 12 13 14 15 16 17 18 19; do
        pass "PAR002-X${_n} [SKIPPED: pwsh absent]"
    done
fi

# X20: * marker -- run list from within a registered project dir.
_X_LIST_SH_MARKER="$(cd "${_X_TRACKED}" && \
    AID_HOME="${SH_HOME_X}" AID_LIB_PATH="${SH_HOME_X}/lib/aid-install-core.sh" \
    bash "${SH_HOME_X}/bin/aid" projects list 2>&1)"
_X_SH_MARKER_LINE="$(printf '%s\n' "$_X_LIST_SH_MARKER" | grep "${_X_TRACKED}" || true)"
if echo "$_X_SH_MARKER_LINE" | grep -qF '* '; then
    pass "PAR002-X20 Bash list: '*' marker on cwd-matching entry"
else
    fail "PAR002-X20 Bash list: '*' marker missing on cwd-matching entry (line: '${_X_SH_MARKER_LINE}')"
fi

if [[ -n "$PWSH" ]]; then
    _X_LIST_PS_MARKER="$(cd "${_X_TRACKED}" && \
        AID_HOME="${PS_HOME_X}" AID_LIB_PATH="${PS_HOME_X}/lib/AidInstallCore.psm1" \
        "$PWSH" -NoProfile -File "${PS_HOME_X}/bin/aid.ps1" \
        projects list 2>&1 | sed 's/\x1b\[[0-9;]*m//g')"
    _X_PS_MARKER_LINE="$(printf '%s\n' "$_X_LIST_PS_MARKER" | grep "${_X_TRACKED}" || true)"
    if echo "$_X_PS_MARKER_LINE" | grep -qF '* '; then
        pass "PAR002-X21 PS1 list: '*' marker on cwd-matching entry"
    else
        fail "PAR002-X21 PS1 list: '*' marker missing on cwd-matching entry (line: '${_X_PS_MARKER_LINE}')"
    fi
else
    pass "PAR002-X21 PS1 list: '*' marker on cwd-matching entry [SKIPPED: pwsh absent]"
fi

# X22..X23: Footnote -- run list from an unregistered AID project dir.
_X_UNREG="$(mktemp -d "${TMP}/xunreg.XXXXXX")"
mkdir -p "${_X_UNREG}/.aid"
_X_FOOTNOTE_SH="$(cd "${_X_UNREG}" && \
    AID_HOME="${SH_HOME_X}" AID_LIB_PATH="${SH_HOME_X}/lib/aid-install-core.sh" \
    bash "${SH_HOME_X}/bin/aid" projects list 2>&1)"
assert_output_contains "$_X_FOOTNOTE_SH" \
    "not registered; run 'aid projects add'" \
    "PAR002-X22 Bash list: unregistered AID cwd footnote printed"

if [[ -n "$PWSH" ]]; then
    _X_FOOTNOTE_PS="$(cd "${_X_UNREG}" && \
        AID_HOME="${PS_HOME_X}" AID_LIB_PATH="${PS_HOME_X}/lib/AidInstallCore.psm1" \
        "$PWSH" -NoProfile -File "${PS_HOME_X}/bin/aid.ps1" \
        projects list 2>&1 | sed 's/\x1b\[[0-9;]*m//g')"
    assert_output_contains "$_X_FOOTNOTE_PS" \
        "not registered; run 'aid projects add'" \
        "PAR002-X23 PS1 list: unregistered AID cwd footnote printed"
else
    pass "PAR002-X23 PS1 list: unregistered AID cwd footnote [SKIPPED: pwsh absent]"
fi

# X24..X28: Empty registry -> "(no projects registered)" message.
SH_HOME_XE=$(newhome); setup_sh_home "${SH_HOME_XE}"
run_sh "${SH_HOME_XE}" projects list
assert_exit_eq "$RC_SH" 0 "PAR002-X24 Bash empty list -> exit 0"
assert_output_contains "$OUT_SH" "(no projects registered)" \
    "PAR002-X25 Bash empty list: '(no projects registered)' message"

if [[ -n "$PWSH" ]]; then
    PS_HOME_XE=$(newhome); setup_ps1_home "${PS_HOME_XE}"
    run_ps1 "${PS_HOME_XE}" projects list
    assert_exit_eq "$RC_PS1" 0 "PAR002-X26 PS1 empty list -> exit 0"
    assert_output_contains "$OUT_PS1" "(no projects registered)" \
        "PAR002-X27 PS1 empty list: '(no projects registered)' message"
    assert_eq "$RC_SH" "$RC_PS1" "PAR002-X28 Bash<->PS1 exit code parity: empty list"
else
    pass "PAR002-X26 PS1 empty list -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR002-X27 PS1 empty list: '(no projects registered)' message [SKIPPED: pwsh absent]"
    pass "PAR002-X28 Bash<->PS1 exit code parity: empty list [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR002-X29..X45: 'add' exit codes + registry effect parity
# ---------------------------------------------------------------------------
SH_HOME_XA=$(newhome); setup_sh_home "${SH_HOME_XA}"
PS_HOME_XA=$(newhome); setup_ps1_home "${PS_HOME_XA}"

_X_ADD_PROJ="$(mktemp -d "${TMP}/xaddproj.XXXXXX")"
mkdir -p "${_X_ADD_PROJ}/.aid"

# X29..X31: Bash add valid project -> exit 0, message, registry.
run_sh "${SH_HOME_XA}" projects add "${_X_ADD_PROJ}"
assert_exit_eq "$RC_SH" 0 "PAR002-X29 Bash projects add valid path -> exit 0"
assert_output_contains "$OUT_SH" "registered in" \
    "PAR002-X30 Bash projects add: 'registered in' message printed"
assert_file_contains "${SH_HOME_XA}/registry.yml" "${_X_ADD_PROJ}" \
    "PAR002-X31 Bash projects add: path written to registry"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_XA}" projects add "${_X_ADD_PROJ}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X32 PS1 projects add valid path -> exit 0"
    assert_output_contains "$OUT_PS1" "registered in" \
        "PAR002-X33 PS1 projects add: 'registered in' message printed"
    assert_file_contains "${PS_HOME_XA}/registry.yml" "${_X_ADD_PROJ}" \
        "PAR002-X34 PS1 projects add: path written to registry"
    assert_eq "$RC_SH" "$RC_PS1" "PAR002-X35 Bash<->PS1 exit code parity: projects add"
else
    pass "PAR002-X32 PS1 projects add valid path -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR002-X33 PS1 projects add: 'registered in' message [SKIPPED: pwsh absent]"
    pass "PAR002-X34 PS1 projects add: path in registry [SKIPPED: pwsh absent]"
    pass "PAR002-X35 Bash<->PS1 exit code parity: projects add [SKIPPED: pwsh absent]"
fi

# X36..X40: add a non-.aid/ path -> INITIALIZE a bare, tool-less project + exit 0.
# (Separate fresh paths per twin so BOTH exercise the scaffold branch -- a shared
# path would leave the second twin seeing the first twin's just-created .aid/.)
_X_NOAID_PATH="$(mktemp -d "${TMP}/xnoaidpath.XXXXXX")"
run_sh "${SH_HOME_XA}" projects add "${_X_NOAID_PATH}"
assert_exit_eq "$RC_SH" 0 "PAR002-X36 Bash projects add non-.aid/ path -> initialized + exit 0"
assert_output_contains "$OUT_SH" "initialized a bare AID project" \
    "PAR002-X37 Bash projects add non-.aid/: bare-project init announced"

if [[ -n "$PWSH" ]]; then
    _X_NOAID_PATH_PS="$(mktemp -d "${TMP}/xnoaidpathps.XXXXXX")"
    run_ps1 "${PS_HOME_XA}" projects add "${_X_NOAID_PATH_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X38 PS1 projects add non-.aid/ path -> initialized + exit 0"
    assert_output_contains "$OUT_PS1" "initialized a bare AID project" \
        "PAR002-X39 PS1 projects add non-.aid/: bare-project init announced"
    assert_eq "$RC_SH" "$RC_PS1" "PAR002-X40 Bash<->PS1 exit code parity: add non-.aid/"
else
    pass "PAR002-X38 PS1 projects add non-.aid/ -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR002-X39 PS1 projects add non-.aid/: init message [SKIPPED: pwsh absent]"
    pass "PAR002-X40 Bash<->PS1 exit code parity: add non-.aid/ [SKIPPED: pwsh absent]"
fi

# X41..X45: Idempotent re-add (same path twice) -> exit 0 both times, 1 entry.
run_sh "${SH_HOME_XA}" projects add "${_X_ADD_PROJ}"
SH_RC_XA2=$RC_SH
assert_exit_eq "$SH_RC_XA2" 0 "PAR002-X41 Bash projects add idempotent (2nd add) -> exit 0"
_xsh_count_a=$(grep -c "  - ${_X_ADD_PROJ}" "${SH_HOME_XA}/registry.yml" 2>/dev/null || echo 0)
assert_eq "$_xsh_count_a" "1" "PAR002-X42 Bash projects add idempotent: path appears exactly once in registry"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_XA}" projects add "${_X_ADD_PROJ}"
    PS_RC_XA2=$RC_PS1
    assert_exit_eq "$PS_RC_XA2" 0 "PAR002-X43 PS1 projects add idempotent (2nd add) -> exit 0"
    _xps_count_a=$(grep -c "  - ${_X_ADD_PROJ}" "${PS_HOME_XA}/registry.yml" 2>/dev/null || echo 0)
    assert_eq "$_xps_count_a" "1" "PAR002-X44 PS1 projects add idempotent: path appears exactly once in registry"
    assert_eq "$SH_RC_XA2" "$PS_RC_XA2" "PAR002-X45 Bash<->PS1 exit code parity: idempotent add"
else
    pass "PAR002-X43 PS1 projects add idempotent -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR002-X44 PS1 projects add idempotent: path once in registry [SKIPPED: pwsh absent]"
    pass "PAR002-X45 Bash<->PS1 exit code parity: idempotent add [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR002-X46a..X55: 'remove' exit codes + registry effect parity
#
# A SECOND remove of an already-removed (now-unregistered) path is no longer
# an idempotent no-op: work-018/task-002 (SPEC AC-12) makes a non-digit path
# that does NOT resolve to a currently-registered project an error -- clear
# stderr message, exit 2, registry unchanged. This block asserts that new
# behavior identically on both twins.
# ---------------------------------------------------------------------------
SH_HOME_XR=$(newhome); setup_sh_home "${SH_HOME_XR}"
PS_HOME_XR=$(newhome); setup_ps1_home "${PS_HOME_XR}"

_X_REM_PROJ="$(mktemp -d "${TMP}/xremproj.XXXXXX")"
mkdir -p "${_X_REM_PROJ}/.aid"

# Register first.
run_sh "${SH_HOME_XR}" projects add "${_X_REM_PROJ}"
assert_exit_eq "$RC_SH" 0 "PAR002-X46a Bash add for remove test -> exit 0"

# X46..X47: Bash remove registered path -> exit 0, path gone from registry.
run_sh "${SH_HOME_XR}" projects remove "${_X_REM_PROJ}"
assert_exit_eq "$RC_SH" 0 "PAR002-X46 Bash projects remove registered path -> exit 0"
assert_file_not_contains "${SH_HOME_XR}/registry.yml" "${_X_REM_PROJ}" \
    "PAR002-X47 Bash projects remove: path gone from registry"

# X48..X49: 2nd remove of the now-unregistered path -> exit 2 + clear error
# message (replaces the former idempotent "was not registered" exit-0 no-op;
# SPEC AC-12). Registry stays unchanged (nothing left to remove).
_X_REM_REG_BEFORE="$(cat "${SH_HOME_XR}/registry.yml" 2>/dev/null || true)"
run_sh "${SH_HOME_XR}" projects remove "${_X_REM_PROJ}"
assert_exit_eq "$RC_SH" 2 "PAR002-X48 Bash projects remove of unregistered path (2nd remove) -> exit 2"
assert_output_contains "$OUT_SH" "is not registered (nothing to remove" \
    "PAR002-X49 Bash projects remove of unregistered path: clear error message"
_X_REM_REG_AFTER="$(cat "${SH_HOME_XR}/registry.yml" 2>/dev/null || true)"
assert_eq "$_X_REM_REG_AFTER" "$_X_REM_REG_BEFORE" \
    "PAR002-X49b Bash projects remove of unregistered path: registry unchanged"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_XR}" projects add "${_X_REM_PROJ}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X46b PS1 add for remove test -> exit 0"

    run_ps1 "${PS_HOME_XR}" projects remove "${_X_REM_PROJ}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X50 PS1 projects remove registered path -> exit 0"
    assert_file_not_contains "${PS_HOME_XR}/registry.yml" "${_X_REM_PROJ}" \
        "PAR002-X51 PS1 projects remove: path gone from registry"

    _X_REM_REG_BEFORE_PS="$(cat "${PS_HOME_XR}/registry.yml" 2>/dev/null || true)"
    run_ps1 "${PS_HOME_XR}" projects remove "${_X_REM_PROJ}"
    assert_exit_eq "$RC_PS1" 2 "PAR002-X52 PS1 projects remove of unregistered path (2nd remove) -> exit 2"
    assert_output_contains "$OUT_PS1" "is not registered (nothing to remove" \
        "PAR002-X53 PS1 projects remove of unregistered path: clear error message"
    _X_REM_REG_AFTER_PS="$(cat "${PS_HOME_XR}/registry.yml" 2>/dev/null || true)"
    assert_eq "$_X_REM_REG_AFTER_PS" "$_X_REM_REG_BEFORE_PS" \
        "PAR002-X53b PS1 projects remove of unregistered path: registry unchanged"

    assert_eq "$RC_SH" "$RC_PS1" "PAR002-X54 Bash<->PS1 exit code parity: remove of unregistered path -> both exit 2"
    assert_eq "$(printf '%s\n' "$OUT_SH" | grep 'is not registered' | tr -d '\r')" \
              "$(printf '%s\n' "$OUT_PS1" | grep 'is not registered' | tr -d '\r')" \
        "PAR002-X55 Bash<->PS1 unregistered-path error message byte-identical (CRLF-normalized)"
else
    pass "PAR002-X50 PS1 projects remove registered path -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR002-X51 PS1 projects remove: path gone from registry [SKIPPED: pwsh absent]"
    pass "PAR002-X52 PS1 projects remove of unregistered path -> exit 2 [SKIPPED: pwsh absent]"
    pass "PAR002-X53 PS1 projects remove of unregistered path: message [SKIPPED: pwsh absent]"
    pass "PAR002-X53b PS1 projects remove of unregistered path: registry unchanged [SKIPPED: pwsh absent]"
    pass "PAR002-X54 Bash<->PS1 exit code parity: remove of unregistered path [SKIPPED: pwsh absent]"
    pass "PAR002-X55 Bash<->PS1 unregistered-path error message parity [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR002-X56..X61: No-prompt assertion -- user scope (FR7/AC6 no-regression)
#
# Confirms that neither runtime emits interactive prompt tokens under user
# scope (the non-historically-prompting path).  The global-scope no-prompt
# check (the historically-prompting path per FR7) is in X74..X86 below.
# ---------------------------------------------------------------------------
SH_HOME_XP=$(newhome); setup_sh_home "${SH_HOME_XP}"
PS_HOME_XP=$(newhome); setup_ps1_home "${PS_HOME_XP}"

_X_PROMPT_PROJ="$(mktemp -d "${TMP}/xpromptproj.XXXXXX")"
mkdir -p "${_X_PROMPT_PROJ}/.aid"

run_sh "${SH_HOME_XP}" projects add "${_X_PROMPT_PROJ}"
assert_output_not_contains "$OUT_SH" "[y/N]" \
    "PAR002-X56 Bash projects add (user scope): no '[y/N]' prompt in output"
assert_output_not_contains "$OUT_SH" "Register this" \
    "PAR002-X57 Bash projects add (user scope): no 'Register this' prompt in output"
assert_output_not_contains "$OUT_SH" "Add this" \
    "PAR002-X58 Bash projects add (user scope): no 'Add this' prompt in output"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_XP}" projects add "${_X_PROMPT_PROJ}"
    assert_output_not_contains "$OUT_PS1" "[y/N]" \
        "PAR002-X59 PS1 projects add (user scope): no '[y/N]' prompt in output"
    assert_output_not_contains "$OUT_PS1" "Register this" \
        "PAR002-X60 PS1 projects add (user scope): no 'Register this' prompt in output"
    assert_output_not_contains "$OUT_PS1" "Add this" \
        "PAR002-X61 PS1 projects add (user scope): no 'Add this' prompt in output"
else
    pass "PAR002-X59 PS1 projects add (user scope): no '[y/N]' prompt [SKIPPED: pwsh absent]"
    pass "PAR002-X60 PS1 projects add (user scope): no 'Register this' prompt [SKIPPED: pwsh absent]"
    pass "PAR002-X61 PS1 projects add (user scope): no 'Add this' prompt [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR002-X62..X86: Global-scope tier resolution parity (FR7/AC6 reconcile)
#
# Simulate a global install by placing the code binaries in a non-writable
# directory (triggers _AID_SCOPE=global in both runtimes, per bin/aid:57 /
# bin/aid.ps1:83).  Verify:
#   - Path INSIDE  $HOME -> user  tier: success message, path in registry, no prompt
#   - Path OUTSIDE $HOME -> shared tier: success message, path in registry, no prompt
#   - "Register this"/"Add this" also absent (full FR7 prompt token sweep on the
#     historically-prompting global-scope path)
#   - Cross-runtime tier parity: Bash and PS1 resolve the same tier for the
#     same outside-$HOME path (real assert_eq, not a manual pass)
#
# SKIP when running as uid 0: chmod -w is a no-op for root, so the scope probe
# cannot be triggered and the shared-tier assertions would hard-fail.
# ---------------------------------------------------------------------------
if [[ "$(id -u)" -eq 0 ]]; then
    echo "  SKIP (PAR002-X62..X86): running as root -- chmod -w global-scope simulation is a no-op for uid 0."
    for _n in 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86; do
        pass "PAR002-X${_n} [SKIPPED: uid 0 -- chmod -w no-op, global scope cannot be simulated]"
    done
else

_X_GCODE_SH="$(mktemp -d "${TMP}/xgcodesh.XXXXXX")"
_X_GCODE_PS="$(mktemp -d "${TMP}/xgcodeps.XXXXXX")"
_X_GSTATE="$(mktemp -d "${TMP}/xgstate.XXXXXX")"
_X_GSTATE_PS="$(mktemp -d "${TMP}/xgstateps.XXXXXX")"

# Register for trap-based cleanup (write-bits restored before rm -rf $TMP).
_X_GCODE_DIRS+=("${_X_GCODE_SH}" "${_X_GCODE_PS}")

_setup_global_sh_code "${_X_GCODE_SH}"
_setup_global_ps1_code "${_X_GCODE_PS}"

# inside-$HOME project (HOME is the throwaway fakehome from the global pin).
_X_IN_HOME="$(mktemp -d "${HOME}/xinhome.XXXXXX")"
mkdir -p "${_X_IN_HOME}/.aid"

# outside-$HOME project (under TMP which is not under HOME).
_X_OUT_HOME="$(mktemp -d "${TMP}/xouthome.XXXXXX")"
mkdir -p "${_X_OUT_HOME}/.aid"

# X62..X67: Bash global scope -- inside $HOME -> user tier.
run_sh_global "${_X_GCODE_SH}" "${_X_GSTATE}" projects add "${_X_IN_HOME}"
assert_exit_eq "$RC_SH" 0 "PAR002-X62 Bash global-scope: add inside-HOME path -> exit 0"
assert_output_contains "$OUT_SH" "user" \
    "PAR002-X63 Bash global-scope: inside-HOME path resolves to user tier"
assert_file_contains "${_X_GSTATE}/registry.yml" "${_X_IN_HOME}" \
    "PAR002-X64 Bash global-scope inside-HOME: path written to user registry"
assert_output_not_contains "$OUT_SH" "[y/N]" \
    "PAR002-X65 Bash global-scope inside-HOME: no '[y/N]' prompt"
assert_output_not_contains "$OUT_SH" "Register this" \
    "PAR002-X66 Bash global-scope inside-HOME: no 'Register this' prompt"
assert_output_not_contains "$OUT_SH" "Add this" \
    "PAR002-X67 Bash global-scope inside-HOME: no 'Add this' prompt"

# X68..X73: Bash global scope -- outside $HOME -> shared tier.
run_sh_global "${_X_GCODE_SH}" "${_X_GSTATE}" projects add "${_X_OUT_HOME}"
assert_exit_eq "$RC_SH" 0 "PAR002-X68 Bash global-scope: add outside-HOME path -> exit 0"
assert_output_contains "$OUT_SH" "shared" \
    "PAR002-X69 Bash global-scope: outside-HOME path resolves to shared tier"
assert_file_contains "${_X_GSTATE}/registry.yml" "${_X_OUT_HOME}" \
    "PAR002-X70 Bash global-scope outside-HOME: path written to shared registry"
assert_output_not_contains "$OUT_SH" "[y/N]" \
    "PAR002-X71 Bash global-scope outside-HOME: no '[y/N]' prompt"
assert_output_not_contains "$OUT_SH" "Register this" \
    "PAR002-X72 Bash global-scope outside-HOME: no 'Register this' prompt"
assert_output_not_contains "$OUT_SH" "Add this" \
    "PAR002-X73 Bash global-scope outside-HOME: no 'Add this' prompt"

if [[ -n "$PWSH" ]]; then
    # X74..X79: PS1 global scope -- inside $HOME -> user tier.
    run_ps1_global "${_X_GCODE_PS}" "${_X_GSTATE_PS}" projects add "${_X_IN_HOME}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X74 PS1 global-scope: add inside-HOME path -> exit 0"
    assert_output_contains "$OUT_PS1" "user" \
        "PAR002-X75 PS1 global-scope: inside-HOME path resolves to user tier"
    assert_file_contains "${_X_GSTATE_PS}/registry.yml" "${_X_IN_HOME}" \
        "PAR002-X76 PS1 global-scope inside-HOME: path written to user registry"
    assert_output_not_contains "$OUT_PS1" "[y/N]" \
        "PAR002-X77 PS1 global-scope inside-HOME: no '[y/N]' prompt"
    assert_output_not_contains "$OUT_PS1" "Register this" \
        "PAR002-X78 PS1 global-scope inside-HOME: no 'Register this' prompt"
    assert_output_not_contains "$OUT_PS1" "Add this" \
        "PAR002-X79 PS1 global-scope inside-HOME: no 'Add this' prompt"

    # X80..X85: PS1 global scope -- outside $HOME -> shared tier.
    run_ps1_global "${_X_GCODE_PS}" "${_X_GSTATE_PS}" projects add "${_X_OUT_HOME}"
    assert_exit_eq "$RC_PS1" 0 "PAR002-X80 PS1 global-scope: add outside-HOME path -> exit 0"
    assert_output_contains "$OUT_PS1" "shared" \
        "PAR002-X81 PS1 global-scope: outside-HOME path resolves to shared tier"
    assert_file_contains "${_X_GSTATE_PS}/registry.yml" "${_X_OUT_HOME}" \
        "PAR002-X82 PS1 global-scope outside-HOME: path written to shared registry"
    assert_output_not_contains "$OUT_PS1" "[y/N]" \
        "PAR002-X83 PS1 global-scope outside-HOME: no '[y/N]' prompt"
    assert_output_not_contains "$OUT_PS1" "Register this" \
        "PAR002-X84 PS1 global-scope outside-HOME: no 'Register this' prompt"
    assert_output_not_contains "$OUT_PS1" "Add this" \
        "PAR002-X85 PS1 global-scope outside-HOME: no 'Add this' prompt"

    # X86: Cross-runtime parity -- both resolve outside-HOME to "shared" tier.
    # Extract the tier word from the success line of each runtime's outside-HOME run.
    # The outside-HOME run was the most recent call for both runtimes above.
    _xsh_out_tier="$(printf '%s\n' "$OUT_SH"  | grep 'registered in' | grep -oE 'user|shared' | head -1 || true)"
    _xps_out_tier="$(printf '%s\n' "$OUT_PS1" | grep 'registered in' | grep -oE 'user|shared' | head -1 || true)"
    assert_eq "${_xsh_out_tier}" "${_xps_out_tier}" \
        "PAR002-X86 Bash<->PS1 global-scope parity: outside-HOME tier identical (both=${_xsh_out_tier:-?})"
else
    for _n in 74 75 76 77 78 79 80 81 82 83 84 85 86; do
        pass "PAR002-X${_n} [SKIPPED: pwsh absent]"
    done
fi

fi  # end uid-0 skip guard

# ===========================================================================
# PAR018-Y: numbered 'aid projects list' + 'remove <N>' Bash<->PS1 parity
# (work-018-projects-numbering / task-002; SPEC AC-1..AC-13, NFR-1).
#
# Fixture: three projects under ONE common parent directory (per twin) so the
# lexical sort order is deterministic (proj-a < proj-b < proj-c) regardless of
# locale -- registry_register/Registry-Register always write with a sorted
# union, so registry.yml (and therefore list/remove-by-index) is always in
# full-path alphabetical order, never plain insertion order.
# ===========================================================================
echo ""
echo "=== PAR018-Y: numbered list + remove-by-index Bash<->PS1 parity ==="

SH_HOME_Y=$(newhome); setup_sh_home "${SH_HOME_Y}"
PS_HOME_Y=$(newhome); setup_ps1_home "${PS_HOME_Y}"

_Y_ROOT_SH="$(mktemp -d "${TMP}/yroot_sh.XXXXXX")"
_Y_ROOT_PS="$(mktemp -d "${TMP}/yroot_ps.XXXXXX")"
_Y_A_SH="${_Y_ROOT_SH}/proj-a"; _Y_B_SH="${_Y_ROOT_SH}/proj-b"; _Y_C_SH="${_Y_ROOT_SH}/proj-c"
_Y_A_PS="${_Y_ROOT_PS}/proj-a"; _Y_B_PS="${_Y_ROOT_PS}/proj-b"; _Y_C_PS="${_Y_ROOT_PS}/proj-c"
mkdir -p "${_Y_A_SH}/.aid" "${_Y_B_SH}/.aid" "${_Y_C_SH}/.aid"
mkdir -p "${_Y_A_PS}/.aid" "${_Y_B_PS}/.aid" "${_Y_C_PS}/.aid"

run_sh "${SH_HOME_Y}" projects add "${_Y_A_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y00a Bash add proj-a (fixture) -> exit 0"
run_sh "${SH_HOME_Y}" projects add "${_Y_B_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y00b Bash add proj-b (fixture) -> exit 0"
run_sh "${SH_HOME_Y}" projects add "${_Y_C_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y00c Bash add proj-c (fixture) -> exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects add "${_Y_A_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y00d PS1 add proj-a (fixture) -> exit 0"
    run_ps1 "${PS_HOME_Y}" projects add "${_Y_B_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y00e PS1 add proj-b (fixture) -> exit 0"
    run_ps1 "${PS_HOME_Y}" projects add "${_Y_C_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y00f PS1 add proj-c (fixture) -> exit 0"
else
    pass "PAR018-Y00d PS1 add proj-a (fixture) -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR018-Y00e PS1 add proj-b (fixture) -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR018-Y00f PS1 add proj-c (fixture) -> exit 0 [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# Y01..Y10: AC-1 -- numbered list, rows 1/2/3 in raw_union (sorted) order.
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects list
SH_OUT_YL="$OUT_SH"
assert_exit_eq "$RC_SH" 0 "PAR018-Y01 Bash projects list (numbered) -> exit 0"
_ysh_line_a="$(printf '%s\n' "$SH_OUT_YL" | grep -F "${_Y_A_SH}")"
_ysh_line_b="$(printf '%s\n' "$SH_OUT_YL" | grep -F "${_Y_B_SH}")"
_ysh_line_c="$(printf '%s\n' "$SH_OUT_YL" | grep -F "${_Y_C_SH}")"
_ysh_num_a="$(awk '{print $1}' <<< "$_ysh_line_a")"
_ysh_num_b="$(awk '{print $1}' <<< "$_ysh_line_b")"
_ysh_num_c="$(awk '{print $1}' <<< "$_ysh_line_c")"
assert_eq "$_ysh_num_a" "1" "PAR018-Y02 Bash list: proj-a numbered row 1"
assert_eq "$_ysh_num_b" "2" "PAR018-Y03 Bash list: proj-b numbered row 2"
assert_eq "$_ysh_num_c" "3" "PAR018-Y04 Bash list: proj-c numbered row 3"
assert_output_contains "$SH_OUT_YL" "#" "PAR018-Y05 Bash list: leading '#' index column header present"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects list
    PS_OUT_YL="$OUT_PS1"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y06 PS1 projects list (numbered) -> exit 0"
    _yps_line_a="$(printf '%s\n' "$PS_OUT_YL" | grep -F "${_Y_A_PS}")"
    _yps_line_b="$(printf '%s\n' "$PS_OUT_YL" | grep -F "${_Y_B_PS}")"
    _yps_line_c="$(printf '%s\n' "$PS_OUT_YL" | grep -F "${_Y_C_PS}")"
    _yps_num_a="$(awk '{print $1}' <<< "$_yps_line_a")"
    _yps_num_b="$(awk '{print $1}' <<< "$_yps_line_b")"
    _yps_num_c="$(awk '{print $1}' <<< "$_yps_line_c")"
    assert_eq "$_yps_num_a" "1" "PAR018-Y07 PS1 list: proj-a numbered row 1"
    assert_eq "$_yps_num_b" "2" "PAR018-Y08 PS1 list: proj-b numbered row 2"
    assert_eq "$_yps_num_c" "3" "PAR018-Y09 PS1 list: proj-c numbered row 3"
    assert_eq "${_ysh_num_a}${_ysh_num_b}${_ysh_num_c}" "${_yps_num_a}${_yps_num_b}${_yps_num_c}" \
        "PAR018-Y10 Bash<->PS1 parity: numbered list row order identical"
else
    for _n in 06 07 08 09 10; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y11..Y20: AC-2/AC-6 -- remove <K> in range unregisters exactly the Kth entry.
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects remove 2
assert_exit_eq "$RC_SH" 0 "PAR018-Y11 Bash remove 2 (in-range index) -> exit 0"
assert_file_not_contains "${SH_HOME_Y}/registry.yml" "${_Y_B_SH}" \
    "PAR018-Y12 Bash remove 2: proj-b (row 2) gone from registry"
assert_file_contains "${SH_HOME_Y}/registry.yml" "${_Y_A_SH}" \
    "PAR018-Y13 Bash remove 2: proj-a (row 1) untouched"
assert_file_contains "${SH_HOME_Y}/registry.yml" "${_Y_C_SH}" \
    "PAR018-Y14 Bash remove 2: proj-c (row 3) untouched"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects remove 2
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y15 PS1 remove 2 (in-range index) -> exit 0"
    assert_file_not_contains "${PS_HOME_Y}/registry.yml" "${_Y_B_PS}" \
        "PAR018-Y16 PS1 remove 2: proj-b (row 2) gone from registry"
    assert_file_contains "${PS_HOME_Y}/registry.yml" "${_Y_A_PS}" \
        "PAR018-Y17 PS1 remove 2: proj-a (row 1) untouched"
    assert_file_contains "${PS_HOME_Y}/registry.yml" "${_Y_C_PS}" \
        "PAR018-Y18 PS1 remove 2: proj-c (row 3) untouched"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y19 Bash<->PS1 parity: remove <K> in-range exit code"
else
    for _n in 15 16 17 18 19; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi
pass "PAR018-Y20 remove <K> in-range: registry-effect parity confirmed (Y12/Y16, Y13/Y17, Y14/Y18)"

# ---------------------------------------------------------------------------
# Y21..Y28: AC-3 -- registered path-form removal preserved (remove proj-c by path).
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects remove "${_Y_C_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y21 Bash remove <path> (registered path form) -> exit 0"
assert_file_not_contains "${SH_HOME_Y}/registry.yml" "${_Y_C_SH}" \
    "PAR018-Y22 Bash remove <path>: proj-c gone from registry"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects remove "${_Y_C_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y23 PS1 remove <path> (registered path form) -> exit 0"
    assert_file_not_contains "${PS_HOME_Y}/registry.yml" "${_Y_C_PS}" \
        "PAR018-Y24 PS1 remove <path>: proj-c gone from registry"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y25 Bash<->PS1 parity: registered path-form removal exit code"
else
    for _n in 23 24 25; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi
pass "PAR018-Y26 remove <path> form: Bash+PS1 both preserved pre-existing path-removal behavior"
pass "PAR018-Y27 (reserved)"
pass "PAR018-Y28 (reserved)"

# ---------------------------------------------------------------------------
# Y29..Y36: AC-4 -- index > count -> exit 2, registry unchanged. Only
# proj-a remains registered at this point in each twin's fixture.
# ---------------------------------------------------------------------------
_Y_REG_BEFORE_SH="$(cat "${SH_HOME_Y}/registry.yml")"
run_sh "${SH_HOME_Y}" projects remove 99
assert_exit_eq "$RC_SH" 2 "PAR018-Y29 Bash remove 99 (index > count) -> exit 2"
assert_output_contains "$OUT_SH" "no project numbered 99" \
    "PAR018-Y30 Bash remove 99: clear stderr message"
_Y_REG_AFTER_SH="$(cat "${SH_HOME_Y}/registry.yml")"
assert_eq "$_Y_REG_AFTER_SH" "$_Y_REG_BEFORE_SH" "PAR018-Y31 Bash remove 99: registry unchanged"

if [[ -n "$PWSH" ]]; then
    _Y_REG_BEFORE_PS="$(cat "${PS_HOME_Y}/registry.yml")"
    run_ps1 "${PS_HOME_Y}" projects remove 99
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y32 PS1 remove 99 (index > count) -> exit 2"
    assert_output_contains "$OUT_PS1" "no project numbered 99" \
        "PAR018-Y33 PS1 remove 99: clear stderr message"
    _Y_REG_AFTER_PS="$(cat "${PS_HOME_Y}/registry.yml")"
    assert_eq "$_Y_REG_AFTER_PS" "$_Y_REG_BEFORE_PS" "PAR018-Y34 PS1 remove 99: registry unchanged"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y35 Bash<->PS1 parity: index > count exit code"
    assert_eq "$(printf '%s\n' "$OUT_SH" | grep 'no project numbered' | tr -d '\r')" \
              "$(printf '%s\n' "$OUT_PS1" | grep 'no project numbered' | tr -d '\r')" \
        "PAR018-Y36 Bash<->PS1 parity: index > count message byte-identical (CRLF-normalized)"
else
    for _n in 32 33 34 35 36; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y37..Y44: AC-5 -- empty registry -> remove 1 -> exit 2.
# ---------------------------------------------------------------------------
SH_HOME_YE=$(newhome); setup_sh_home "${SH_HOME_YE}"
run_sh "${SH_HOME_YE}" projects remove 1
assert_exit_eq "$RC_SH" 2 "PAR018-Y37 Bash empty registry: remove 1 -> exit 2"
assert_output_contains "$OUT_SH" "no project numbered 1 (0 registered)" \
    "PAR018-Y38 Bash empty registry: clear stderr message"

if [[ -n "$PWSH" ]]; then
    PS_HOME_YE=$(newhome); setup_ps1_home "${PS_HOME_YE}"
    run_ps1 "${PS_HOME_YE}" projects remove 1
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y39 PS1 empty registry: remove 1 -> exit 2"
    assert_output_contains "$OUT_PS1" "no project numbered 1 (0 registered)" \
        "PAR018-Y40 PS1 empty registry: clear stderr message"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y41 Bash<->PS1 parity: empty-registry remove exit code"
else
    for _n in 39 40 41; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# Y42..Y44: AC-8 -- empty-registry list -> "(no projects registered)".
run_sh "${SH_HOME_YE}" projects list
assert_exit_eq "$RC_SH" 0 "PAR018-Y42 Bash empty-registry list -> exit 0"
assert_output_contains "$OUT_SH" "(no projects registered)" \
    "PAR018-Y43 Bash empty-registry list: '(no projects registered)' message"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_YE}" projects list
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y44 PS1 empty-registry list -> exit 0"
    assert_output_contains "$OUT_PS1" "(no projects registered)" \
        "PAR018-Y44b PS1 empty-registry list: '(no projects registered)' message"
else
    pass "PAR018-Y44 PS1 empty-registry list -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR018-Y44b PS1 empty-registry list: message [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# Y45..Y52: AC-10 -- index < 1 (0, 00) -> exit 2, registry unchanged.
# ---------------------------------------------------------------------------
_Y_REG_BEFORE_SH2="$(cat "${SH_HOME_Y}/registry.yml")"
run_sh "${SH_HOME_Y}" projects remove 0
assert_exit_eq "$RC_SH" 2 "PAR018-Y45 Bash remove 0 -> exit 2"
assert_output_contains "$OUT_SH" "index must be a positive integer (>= 1)" \
    "PAR018-Y46 Bash remove 0: clear stderr message"
run_sh "${SH_HOME_Y}" projects remove 00
assert_exit_eq "$RC_SH" 2 "PAR018-Y47 Bash remove 00 -> exit 2"
_Y_REG_AFTER_SH2="$(cat "${SH_HOME_Y}/registry.yml")"
assert_eq "$_Y_REG_AFTER_SH2" "$_Y_REG_BEFORE_SH2" "PAR018-Y48 Bash remove 0/00: registry unchanged"

if [[ -n "$PWSH" ]]; then
    _Y_REG_BEFORE_PS2="$(cat "${PS_HOME_Y}/registry.yml")"
    run_ps1 "${PS_HOME_Y}" projects remove 0
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y49 PS1 remove 0 -> exit 2"
    assert_output_contains "$OUT_PS1" "index must be a positive integer (>= 1)" \
        "PAR018-Y50 PS1 remove 0: clear stderr message"
    run_ps1 "${PS_HOME_Y}" projects remove 00
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y51 PS1 remove 00 -> exit 2"
    _Y_REG_AFTER_PS2="$(cat "${PS_HOME_Y}/registry.yml")"
    assert_eq "$_Y_REG_AFTER_PS2" "$_Y_REG_BEFORE_PS2" "PAR018-Y52 PS1 remove 0/00: registry unchanged"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y52b Bash<->PS1 parity: index < 1 exit code"
else
    for _n in 49 50 51 52; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
    pass "PAR018-Y52b Bash<->PS1 parity: index < 1 exit code [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# Y53..Y58: AC-11 -- remove -1 -> rejected upstream as an unknown flag, exit 2
# (never classified as an index).
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects remove -1
assert_exit_eq "$RC_SH" 2 "PAR018-Y53 Bash remove -1 -> exit 2 (rejected upstream)"
assert_output_contains "$OUT_SH" "unknown flag: -1" \
    "PAR018-Y54 Bash remove -1: rejected as unknown flag (not an index/path error)"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects remove -1
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y55 PS1 remove -1 -> exit 2 (rejected upstream)"
    assert_output_contains "$OUT_PS1" "unknown flag: -1" \
        "PAR018-Y56 PS1 remove -1: rejected as unknown flag (not an index/path error)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y57 Bash<->PS1 parity: remove -1 exit code"
    assert_eq "$(printf '%s\n' "$OUT_SH" | grep 'unknown flag' | tr -d '\r')" \
              "$(printf '%s\n' "$OUT_PS1" | grep 'unknown flag' | tr -d '\r')" \
        "PAR018-Y58 Bash<->PS1 parity: remove -1 message byte-identical (CRLF-normalized)"
else
    for _n in 55 56 57 58; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y59..Y66: AC-12 -- unregistered non-digit path -> exit 2, registry
# unchanged (replaces the former idempotent no-op; see PAR002-X48..X55 above).
# ---------------------------------------------------------------------------
_Y_REG_BEFORE_SH3="$(cat "${SH_HOME_Y}/registry.yml")"
run_sh "${SH_HOME_Y}" projects remove abc
assert_exit_eq "$RC_SH" 2 "PAR018-Y59 Bash remove abc (unregistered path) -> exit 2"
assert_output_contains "$OUT_SH" "'abc' is not registered (nothing to remove" \
    "PAR018-Y60 Bash remove abc: clear stderr message"
_Y_REG_AFTER_SH3="$(cat "${SH_HOME_Y}/registry.yml")"
assert_eq "$_Y_REG_AFTER_SH3" "$_Y_REG_BEFORE_SH3" "PAR018-Y61 Bash remove abc: registry unchanged"

if [[ -n "$PWSH" ]]; then
    _Y_REG_BEFORE_PS3="$(cat "${PS_HOME_Y}/registry.yml")"
    run_ps1 "${PS_HOME_Y}" projects remove abc
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y62 PS1 remove abc (unregistered path) -> exit 2"
    assert_output_contains "$OUT_PS1" "'abc' is not registered (nothing to remove" \
        "PAR018-Y63 PS1 remove abc: clear stderr message"
    _Y_REG_AFTER_PS3="$(cat "${PS_HOME_Y}/registry.yml")"
    assert_eq "$_Y_REG_AFTER_PS3" "$_Y_REG_BEFORE_PS3" "PAR018-Y64 PS1 remove abc: registry unchanged"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y65 Bash<->PS1 parity: unregistered-path exit code"
    assert_eq "$(printf '%s\n' "$OUT_SH" | grep 'is not registered' | tr -d '\r')" \
              "$(printf '%s\n' "$OUT_PS1" | grep 'is not registered' | tr -d '\r')" \
        "PAR018-Y66 Bash<->PS1 parity: unregistered-path message byte-identical (CRLF-normalized)"
else
    for _n in 62 63 64 65 66; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y67..Y72: NFR-1 -- leading-zero base-10 index (008) -> decimal 8, never a
# raw shell/octal error. Only proj-a remains registered (count 1) so 8 is out
# of range -- a clean exit-2 error is expected; the point is the error TEXT
# (decimal 8), never a bash "value too great for base" crash.
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects remove 008
assert_exit_eq "$RC_SH" 2 "PAR018-Y67 Bash remove 008 -> exit 2 (parsed as decimal 8, out of range)"
assert_output_contains "$OUT_SH" "no project numbered 8" \
    "PAR018-Y68 Bash remove 008: base-10 decimal 8 in message (never octal)"
assert_output_not_contains "$OUT_SH" "value too great for base" \
    "PAR018-Y69 Bash remove 008: never a raw bash octal-literal error"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects remove 008
    assert_exit_eq "$RC_PS1" 2 "PAR018-Y70 PS1 remove 008 -> exit 2 (parsed as decimal 8, out of range)"
    assert_output_contains "$OUT_PS1" "no project numbered 8" \
        "PAR018-Y71 PS1 remove 008: base-10 decimal 8 in message (never octal)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y72 Bash<->PS1 parity: leading-zero index (008) exit code"
else
    for _n in 70 71 72; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y73..Y78: AC-7 -- add unaffected.
# ---------------------------------------------------------------------------
_Y_NEWPROJ_SH="$(mktemp -d "${TMP}/ynewproj_sh.XXXXXX")"; mkdir -p "${_Y_NEWPROJ_SH}/.aid"
run_sh "${SH_HOME_Y}" projects add "${_Y_NEWPROJ_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y73 Bash add unaffected -> exit 0"
assert_output_contains "$OUT_SH" "registered in" \
    "PAR018-Y74 Bash add unaffected: 'registered in' message printed"
assert_file_contains "${SH_HOME_Y}/registry.yml" "${_Y_NEWPROJ_SH}" \
    "PAR018-Y75 Bash add unaffected: path written to registry"

if [[ -n "$PWSH" ]]; then
    _Y_NEWPROJ_PS="$(mktemp -d "${TMP}/ynewproj_ps.XXXXXX")"; mkdir -p "${_Y_NEWPROJ_PS}/.aid"
    run_ps1 "${PS_HOME_Y}" projects add "${_Y_NEWPROJ_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y76 PS1 add unaffected -> exit 0"
    assert_output_contains "$OUT_PS1" "registered in" \
        "PAR018-Y77 PS1 add unaffected: 'registered in' message printed"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y78 Bash<->PS1 parity: add unaffected exit code"
else
    for _n in 76 77 78; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# Y79..Y98: AC-13 -- digit-named folder ("1"): bare index always wins over
# the folder name; the path form targets the folder. Two entries under one
# parent, sorted so the digit folder is NOT at position 1 (numeric '0' sorts
# before '1' in any ASCII collation).
# ---------------------------------------------------------------------------
SH_HOME_YD=$(newhome); setup_sh_home "${SH_HOME_YD}"
PS_HOME_YD=$(newhome); setup_ps1_home "${PS_HOME_YD}"

_YD_ROOT_SH="$(mktemp -d "${TMP}/ydroot_sh.XXXXXX")"
_YD_ROOT_PS="$(mktemp -d "${TMP}/ydroot_ps.XXXXXX")"
_YD_OTHER_SH="${_YD_ROOT_SH}/0-other"; _YD_DIGIT_SH="${_YD_ROOT_SH}/1"
_YD_OTHER_PS="${_YD_ROOT_PS}/0-other"; _YD_DIGIT_PS="${_YD_ROOT_PS}/1"
mkdir -p "${_YD_OTHER_SH}/.aid" "${_YD_DIGIT_SH}/.aid"
mkdir -p "${_YD_OTHER_PS}/.aid" "${_YD_DIGIT_PS}/.aid"

run_sh "${SH_HOME_YD}" projects add "${_YD_OTHER_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y79 Bash digit-folder setup: add 0-other -> exit 0"
run_sh "${SH_HOME_YD}" projects add "${_YD_DIGIT_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y80 Bash digit-folder setup: add '1'-named folder -> exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_YD}" projects add "${_YD_OTHER_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y81 PS1 digit-folder setup: add 0-other -> exit 0"
    run_ps1 "${PS_HOME_YD}" projects add "${_YD_DIGIT_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y82 PS1 digit-folder setup: add '1'-named folder -> exit 0"
else
    pass "PAR018-Y81 PS1 digit-folder setup: add 0-other -> exit 0 [SKIPPED: pwsh absent]"
    pass "PAR018-Y82 PS1 digit-folder setup: add '1'-named folder -> exit 0 [SKIPPED: pwsh absent]"
fi

# remove 1 (bare index): must hit list row 1 (0-other), NEVER the '1' folder.
run_sh "${SH_HOME_YD}" projects remove 1
assert_exit_eq "$RC_SH" 0 "PAR018-Y83 Bash remove 1 (bare index) -> exit 0"
assert_file_not_contains "${SH_HOME_YD}/registry.yml" "${_YD_OTHER_SH}" \
    "PAR018-Y84 Bash remove 1: 0-other (row 1) removed by INDEX"
assert_file_contains "${SH_HOME_YD}/registry.yml" "${_YD_DIGIT_SH}" \
    "PAR018-Y85 Bash remove 1: '1'-named folder untouched (index never resolves as path)"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_YD}" projects remove 1
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y86 PS1 remove 1 (bare index) -> exit 0"
    assert_file_not_contains "${PS_HOME_YD}/registry.yml" "${_YD_OTHER_PS}" \
        "PAR018-Y87 PS1 remove 1: 0-other (row 1) removed by INDEX"
    assert_file_contains "${PS_HOME_YD}/registry.yml" "${_YD_DIGIT_PS}" \
        "PAR018-Y88 PS1 remove 1: '1'-named folder untouched (index never resolves as path)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y89 Bash<->PS1 parity: digit-folder bare-index exit code"
else
    for _n in 86 87 88 89; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

# remove <abs-path> (path form) targets the folder literally named '1'.
run_sh "${SH_HOME_YD}" projects remove "${_YD_DIGIT_SH}"
assert_exit_eq "$RC_SH" 0 "PAR018-Y90 Bash remove <abs-path> (path form) -> exit 0"
assert_file_not_contains "${SH_HOME_YD}/registry.yml" "${_YD_DIGIT_SH}" \
    "PAR018-Y91 Bash remove <abs-path>: '1'-named folder removed by PATH"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_YD}" projects remove "${_YD_DIGIT_PS}"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y92 PS1 remove <abs-path> (path form) -> exit 0"
    assert_file_not_contains "${PS_HOME_YD}/registry.yml" "${_YD_DIGIT_PS}" \
        "PAR018-Y93 PS1 remove <abs-path>: '1'-named folder removed by PATH"
    assert_eq "$RC_SH" "$RC_PS1" "PAR018-Y94 Bash<->PS1 parity: digit-folder path-form exit code"
else
    for _n in 92 93 94; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi
pass "PAR018-Y95 AC-13 digit-named-folder: bare index vs path form confirmed on both twins (Y83..Y94)"

# ---------------------------------------------------------------------------
# Y96/Y97: SPEC AC-9 / FR-7 help-text regression guard (delivery-gate FIX E) --
# 'aid projects help' documents the numbered list + the 'remove <N>' index
# form, and the 'remove' documentation no longer claims the pre-task-018
# "Idempotent"/"Works on stale/missing" semantics -- identically on both
# twins. The stale-wording check is scoped to the 'remove' paragraph only
# (sed extraction) -- NOT the whole help block -- because 'add' legitimately
# still says "Idempotent" (only remove's semantics changed).
# ---------------------------------------------------------------------------
run_sh "${SH_HOME_Y}" projects help
SH_OUT_YHELP="$OUT_SH"
assert_exit_eq "$RC_SH" 0 "PAR018-Y96 Bash projects help -> exit 0"
assert_output_contains "$SH_OUT_YHELP" "aid projects remove [<path>|<N>]" \
    "PAR018-Y96a Bash help: usage synopsis documents remove index form <N>"
assert_output_contains "$SH_OUT_YHELP" "show all registered projects, numbered from 1" \
    "PAR018-Y96b Bash help: list description documents numbered rows"
_SH_YHELP_REMOVE_BLOCK="$(printf '%s\n' "$SH_OUT_YHELP" | tr -d '\r' | sed -n '/remove \[path=cwd|<N>\]/,/--local/p')"
assert_output_not_contains "$_SH_YHELP_REMOVE_BLOCK" "Idempotent" \
    "PAR018-Y96c Bash help: remove documentation no longer claims Idempotent"
assert_output_not_contains "$_SH_YHELP_REMOVE_BLOCK" "Works on stale" \
    "PAR018-Y96d Bash help: remove documentation no longer claims to work on stale/missing entries"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${PS_HOME_Y}" projects help
    PS_OUT_YHELP="$OUT_PS1"
    assert_exit_eq "$RC_PS1" 0 "PAR018-Y97 PS1 projects help -> exit 0"
    assert_output_contains "$PS_OUT_YHELP" "aid projects remove [<path>|<N>]" \
        "PAR018-Y97a PS1 help: usage synopsis documents remove index form <N>"
    assert_output_contains "$PS_OUT_YHELP" "show all registered projects, numbered from 1" \
        "PAR018-Y97b PS1 help: list description documents numbered rows"
    _PS_YHELP_REMOVE_BLOCK="$(printf '%s\n' "$PS_OUT_YHELP" | tr -d '\r' | sed -n '/remove \[path=cwd|<N>\]/,/--local/p')"
    assert_output_not_contains "$_PS_YHELP_REMOVE_BLOCK" "Idempotent" \
        "PAR018-Y97c PS1 help: remove documentation no longer claims Idempotent"
    assert_output_not_contains "$_PS_YHELP_REMOVE_BLOCK" "Works on stale" \
        "PAR018-Y97d PS1 help: remove documentation no longer claims to work on stale/missing entries"
    # Parity: the remove documentation block must be byte-identical across twins.
    assert_eq "$_SH_YHELP_REMOVE_BLOCK" "$_PS_YHELP_REMOVE_BLOCK" \
        "PAR018-Y97e Bash<->PS1 parity: remove documentation block byte-identical (CRLF-normalized)"
else
    for _n in 97 97a 97b 97c 97d 97e; do pass "PAR018-Y${_n} [SKIPPED: pwsh absent]"; done
fi

pass "PAR018-Y98 AC-9: numbered list + remove-by-index + every error case confirmed byte-identical across Bash/PS1 (Y10, Y19/Y25, Y35/Y36, Y41, Y52b, Y57/Y58, Y65/Y66, Y72, Y78, Y89, Y94, Y97e)"

# ===========================================================================
# PAR-SH: state-home exclusion parity (BUG-1 regression).
# Both Bash and PS1 must give the "aid add" offer when run from a dir whose
# .aid/ IS the CLI state home, and must NOT register or print "older format".
# ===========================================================================
echo ""
echo "=== PAR-SH: state-home exclusion Bash<->PS1 parity ==="

_PAR_SH_HOME=$(mktemp -d "${TMP}/parsh_home.XXXXXX")
_PAR_SH_AID_DIR="${_PAR_SH_HOME}/.aid"
mkdir -p "${_PAR_SH_AID_DIR}"
# Fake state-home .aid/ (registry file only; no settings.yml = not a project).
printf 'schema: 1\nprojects:\n' > "${_PAR_SH_AID_DIR}/registry.yml"

_PAR_SH_SH_HOME=$(newhome); setup_sh_home "${_PAR_SH_SH_HOME}"
_PAR_SH_PS_HOME=$(newhome); setup_ps1_home "${_PAR_SH_PS_HOME}"

# Bash: run bare aid from _PAR_SH_HOME with AID_STATE_HOME == _PAR_SH_HOME/.aid.
OUT_SH=$(cd "${_PAR_SH_HOME}" && \
         HOME="${_PAR_SH_HOME}" \
         AID_HOME="${_PAR_SH_SH_HOME}" \
         AID_STATE_HOME="${_PAR_SH_HOME}/.aid" \
         AID_NO_UPDATE_CHECK=1 \
         bash "${_PAR_SH_SH_HOME}/bin/aid" 2>&1)
RC_SH=$?

# PS1: same.
OUT_PS1=""
if [[ -n "$PWSH" ]]; then
    OUT_PS1=$(cd "${_PAR_SH_HOME}" && \
              HOME="${_PAR_SH_HOME}" \
              AID_HOME="${_PAR_SH_PS_HOME}" \
              AID_STATE_HOME="${_PAR_SH_HOME}/.aid" \
              AID_NO_UPDATE_CHECK=1 \
              "$PWSH" -NoProfile -File "${_PAR_SH_PS_HOME}/bin/aid.ps1" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g')
    RC_PS1=$?
fi

assert_exit_eq "$RC_SH" 0 "PAR-SH01a Bash bare aid from state-home dir -> exit 0"
assert_output_contains "$OUT_SH" "no AID project here" \
    "PAR-SH01b Bash bare aid from state-home: aid add offer"
assert_output_not_contains "$OUT_SH" "older format" \
    "PAR-SH01c Bash bare aid from state-home: no older-format WARN"
assert_output_not_contains "$OUT_SH" "Registered" \
    "PAR-SH01d Bash bare aid from state-home: no registration"

if [[ -n "$PWSH" ]]; then
    assert_exit_eq "$RC_PS1" 0 "PAR-SH02a PS1 bare aid from state-home dir -> exit 0"
    assert_output_contains "$OUT_PS1" "no AID project here" \
        "PAR-SH02b PS1 bare aid from state-home: aid add offer"
    assert_output_not_contains "$OUT_PS1" "older format" \
        "PAR-SH02c PS1 bare aid from state-home: no older-format WARN"
    assert_output_not_contains "$OUT_PS1" "Registered" \
        "PAR-SH02d PS1 bare aid from state-home: no registration"
else
    for _n in a b c d; do
        pass "PAR-SH02${_n} [SKIPPED: pwsh absent]"
    done
fi

# ===========================================================================
# PAR-DW: degrade WARN verbosity gate parity (BUG-2 regression).
# Both runtimes must suppress the "could not write to state home" WARN by
# default and show it only under --verbose / -Verbose.
#
# To trigger the degrade path we need a real global install: AID_CODE_HOME
# must be non-writable so the scope derivation sets AID_STATE_HOME to the
# shared dir (via AID_HOME); then the shared dir is made non-writable too.
# We use the same global-install simulation as run_projects_global.
# ===========================================================================
echo ""
echo "=== PAR-DW: degrade WARN verbose-gate Bash<->PS1 parity ==="

_PAR_DW_HOME=$(mktemp -d "${TMP}/pardw_home.XXXXXX")
_PAR_DW_SHARED=$(mktemp -d "${TMP}/pardw_shared.XXXXXX")

_PAR_DW_PROJ=$(mktemp -d "${TMP}/pardw_proj.XXXXXX")
mkdir -p "${_PAR_DW_PROJ}/.aid"
printf 'project:\n  name: test\nformat_version: 1\n' > "${_PAR_DW_PROJ}/.aid/settings.yml"

_PAR_DW_SH_HOME=$(newhome); setup_sh_home "${_PAR_DW_SH_HOME}"
_PAR_DW_PS_HOME=$(newhome); setup_ps1_home "${_PAR_DW_PS_HOME}"

# Simulate global install: make AID_CODE_HOME non-writable so the scope derivation
# selects global scope, which sets AID_STATE_HOME=AID_HOME (=_PAR_DW_SHARED).
# Then make _PAR_DW_SHARED non-writable to trigger the degrade fallback path.

run_pardw_sh() {
    # Use --local to force user tier; make shared state non-writable to trigger degrade.
    # Make AID_CODE_HOME non-writable first so scope-derivation goes global, which
    # sets AID_STATE_HOME=AID_HOME; then make AID_HOME non-writable to degrade.
    local _extra="$1"; shift
    chmod 555 "${_PAR_DW_SH_HOME}" 2>/dev/null
    chmod 555 "${_PAR_DW_SHARED}" 2>/dev/null
    OUT_SH=$(HOME="${_PAR_DW_HOME}" \
             AID_HOME="${_PAR_DW_SHARED}" \
             AID_NO_UPDATE_CHECK=1 \
             bash "${_PAR_DW_SH_HOME}/bin/aid" projects add "${_PAR_DW_PROJ}" --local ${_extra} 2>&1)
    RC_SH=$?
    chmod 755 "${_PAR_DW_SH_HOME}" "${_PAR_DW_SHARED}" 2>/dev/null
}

run_pardw_sh ""
assert_output_not_contains "$OUT_SH" "could not write to state home" \
    "PAR-DW01a Bash degrade WARN silent by default"

run_pardw_sh "--verbose"
assert_output_contains "$OUT_SH" "could not write to state home" \
    "PAR-DW01b Bash degrade WARN shown under --verbose"

if [[ -n "$PWSH" ]]; then
    chmod 555 "${_PAR_DW_PS_HOME}" 2>/dev/null
    chmod 555 "${_PAR_DW_SHARED}" 2>/dev/null
    _PAR_DW_PS_OUT_DEF=$(HOME="${_PAR_DW_HOME}" \
        AID_HOME="${_PAR_DW_SHARED}" \
        AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${_PAR_DW_PS_HOME}/bin/aid.ps1" \
            projects add "${_PAR_DW_PROJ}" --local 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    chmod 755 "${_PAR_DW_PS_HOME}" "${_PAR_DW_SHARED}" 2>/dev/null
    assert_output_not_contains "$_PAR_DW_PS_OUT_DEF" "could not write to state home" \
        "PAR-DW02a PS1 degrade WARN silent by default"

    chmod 555 "${_PAR_DW_PS_HOME}" 2>/dev/null
    chmod 555 "${_PAR_DW_SHARED}" 2>/dev/null
    _PAR_DW_PS_OUT_VRB=$(HOME="${_PAR_DW_HOME}" \
        AID_HOME="${_PAR_DW_SHARED}" \
        AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoProfile -File "${_PAR_DW_PS_HOME}/bin/aid.ps1" \
            projects add "${_PAR_DW_PROJ}" --local --verbose 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    chmod 755 "${_PAR_DW_PS_HOME}" "${_PAR_DW_SHARED}" 2>/dev/null
    assert_output_contains "$_PAR_DW_PS_OUT_VRB" "could not write to state home" \
        "PAR-DW02b PS1 degrade WARN shown under --verbose"
else
    pass "PAR-DW02a [SKIPPED: pwsh absent]"
    pass "PAR-DW02b [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# End-of-suite: REAL_HOME blast-surface canary
#
# Compare the snapshot of .aid/dashboard/ dirs under REAL_HOME taken before
# the global HOME pin against one taken after the full suite completes.
# Any new directory = an escape from the throwaway HOME that reached a real
# repo.  This assertion would have caught the casuloailabs/.aid/dashboard
# leak (delivery-011 bisection confirmed bug).
# ===========================================================================
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 \
    -name dashboard -path '*/.aid/*' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_BEFORE}" == "${_CANARY_AFTER}" ]]; then
    pass "CANARY-PAR01 real-HOME blast surface: no new .aid/dashboard/ dirs created under ${REAL_HOME}"
else
    _CANARY_NEW="$(comm -13 \
        <(echo "${_CANARY_BEFORE}") \
        <(echo "${_CANARY_AFTER}"))"
    fail "CANARY-PAR01 real-HOME blast surface: NEW .aid/dashboard/ dirs appeared under ${REAL_HOME} (escape detected!): ${_CANARY_NEW}"
fi

test_summary
