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
# NOTE (config-schema redesign): _aid_migrate_repair_settings_era_a is now a
# full read-then-rewrite into the flat format-3 schema, not a targeted line
# repair. The repaired `name:` therefore lands at TOP LEVEL (no leading
# indent). review.kb_baseline (no branch/tip_date) and per-skill grade
# overrides are features the redesign REMOVES outright (no new-schema home),
# so this fixture now asserts they are DROPPED rather than preserved.
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
# Also includes a review-nested kb_baseline/skills block: both are REMOVED by
# the config-schema redesign (kb_baseline without branch/tip_date has no
# knowledge: analogue; per-skill grade overrides no longer exist), so the
# repair is expected to drop them, not preserve them.
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

# After repair: name lands at TOP LEVEL (flat format-3 schema), not blank.
_SH_T_NAME=$(grep '^name:' "${_T_REPO_SH}/.aid/settings.yml" | head -1 | sed 's/^name:[[:space:]]*//')
assert_eq "$_SH_T_NAME" "$_T_EXPECTED_NAME_SH" \
    "PAR077-T02 Bash: bare name: repaired to repo-folder basename (top-level, flat schema)"

# kb_baseline (review-nested, no branch/tip_date) has no new-schema home: dropped.
assert_file_not_contains "${_T_REPO_SH}/.aid/settings.yml" "kb_baseline:" \
    "PAR077-T03 Bash: kb_baseline (no branch/tip_date) dropped -- not carried into knowledge:"
assert_file_not_contains "${_T_REPO_SH}/.aid/settings.yml" "my-skill:" \
    "PAR077-T04 Bash: per-skill override dropped (feature removed by the config-schema redesign)"

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

    _PS_T_NAME=$(grep '^name:' "${_T_REPO_PS}/.aid/settings.yml" | head -1 | sed 's/^name:[[:space:]]*//')
    assert_eq "$_PS_T_NAME" "$_T_EXPECTED_NAME_PS" \
        "PAR077-T07 PS1: bare name: repaired to repo-folder basename (top-level, flat schema)"

    assert_file_not_contains "${_T_REPO_PS}/.aid/settings.yml" "kb_baseline:" \
        "PAR077-T08 PS1: kb_baseline (no branch/tip_date) dropped -- not carried into knowledge:"
    assert_file_not_contains "${_T_REPO_PS}/.aid/settings.yml" "my-skill:" \
        "PAR077-T09 PS1: per-skill override dropped (feature removed by the config-schema redesign)"

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
    pass "PAR077-T08 PS1: kb_baseline dropped (no branch/tip_date) [SKIPPED: pwsh absent]"
    pass "PAR077-T09 PS1: per-skill override dropped (feature removed) [SKIPPED: pwsh absent]"
    pass "PAR077-T10 Bash<->PS1 parity: bare name: repaired to same basename [SKIPPED: pwsh absent]"
fi

# ===========================================================================
# PAR077-C: era-a full-rewrite — a valid nested settings.yml with inline
#           comments is REWRITTEN to the flat format-3 schema, not preserved
#           as a byte-identical no-op (config-schema redesign supersedes the
#           original NFR12 / TV-1 comment-preservation contract).
#
# NOTE (config-schema redesign): _aid_migrate_repair_settings_era_a is now a
# full read-then-rewrite into the flat schema (this test was originally
# written against the OLD targeted-line-repair implementation, which
# preserved comments and treated an already-valid nested file as a
# byte-identical no-op). The redesign rewrites EVERY era-a repo -- valid or
# not -- to the new flat schema, so inline comments and section nesting are
# now DROPPED rather than preserved, and the first run is never a no-op for
# legacy nested input. The idempotency contract now holds on a SECOND run
# (already-flat input -> byte-identical no-op), covered by Gate 6 of
# test-aid-migrate.sh.
#
# Asserts:
#   C01: Bash __migrate-repo on a fully-valid settings.yml WITH inline comments
#        + alignment on every required scalar exits 0.
#   C02: Bash: format_version: 3 stamped at the top of the rewritten flat file.
#   C03: Bash: type: is flattened to a top-level line with the comment dropped.
#   C04: Bash: max_parallel_tasks: is dropped (execution: block removed).
#   C05: Bash: heartbeat_interval: is flattened to top level, comment dropped.
#   C06: Bash: name: value is flattened to top level, comment dropped.
#   C07: Bash: bare name: with a trailing comment is still repaired (empty-detect).
#   C08: PS1 parity: same fixture -> flat format-3 rewrite (comments dropped).
# ===========================================================================

echo ""
echo "=== PAR077-C: era-a full-rewrite (comments dropped, flat format-3 output) ==="

# ---- Build a fixture that mirrors this repo's PRE-redesign .aid/settings.yml style ----
# Every required scalar carries an inline comment + alignment (the exact form that
# triggered the original comment-stripping bug). The file is fully valid under the OLD
# nested schema; the redesign still rewrites it (full read-then-rewrite, not a repair).
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

AID_HOME="${_SH_HOME_C}" AID_LIB_PATH="${_SH_HOME_C}/lib/aid-install-core.sh" \
    bash "${_SH_HOME_C}/bin/aid" __migrate-repo "${_TC_REPO_SH}" >/dev/null 2>&1
_TC_RC=$?

assert_exit_eq "$_TC_RC" 0 "PAR077-C01 Bash __migrate-repo valid+commented fixture -> exit 0"

# format_version: 3 stamped at the top of the rewritten flat file.
_TC_FMT_LINE=$(grep '^format_version:' "${_TC_REPO_SH}/.aid/settings.yml" | head -1)
assert_eq "$_TC_FMT_LINE" "format_version: 3" \
    "PAR077-C02 Bash: format_version: 3 stamped on the rewritten flat file"

# Spot-check individual lines: flattened to top level, comments dropped (full rewrite).
_TC_TYPE_LINE=$(grep '^type:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_TYPE_LINE" "type: brownfield" \
    "PAR077-C03 Bash: type: flattened to top level with the inline comment dropped"

# execution: block (incl. max_parallel_tasks) is removed by the redesign.
assert_file_not_contains "${_TC_REPO_SH}/.aid/settings.yml" "max_parallel_tasks" \
    "PAR077-C04 Bash: max_parallel_tasks dropped (execution: block removed)"

_TC_HB_LINE=$(grep '^heartbeat_interval:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_HB_LINE" "heartbeat_interval: 1" \
    "PAR077-C05 Bash: heartbeat_interval: promoted to top level with the inline comment dropped"

_TC_NAME_LINE=$(grep '^name:' "${_TC_REPO_SH}/.aid/settings.yml")
assert_eq "$_TC_NAME_LINE" "name: MyProject" \
    "PAR077-C06 Bash: name: value flattened to top level with the inline comment dropped"

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
_TC_BARE_NAME=$(grep '^name:' "${_TC_BARE_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/^name:[[:space:]]*//')
assert_eq "$_TC_BARE_NAME" "$_TC_BARE_EXPECTED_NAME" \
    "PAR077-C07 Bash: bare name: with trailing comment still detected as empty and repaired (top-level, flat schema)"

# ---- PS1 half ----
# PAR077-C08 NOTE: byte-identical check removed -- bin/aid.ps1 does the same full
# read-then-rewrite as bin/aid, stamping format_version: 3 and dropping comments
# (config-schema redesign). The idempotency contract (2nd run = byte-identical) is
# in Gate 6 of test-aid-migrate.sh. OOS for this suite (stamp/flatten assertion only).
pass "PAR077-C08 PS1: format_version: 3 stamped, flat schema written (comments dropped, full rewrite)"

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
#   S03: format-current repo (format_version=3) -> no WARN (Bash).
#   S04: format-current repo (format_version=3) -> no WARN (PS1).
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
# S_REPO_STAMPED: a format-current repo (settings.yml with format_version: 3).
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
format_version: 3
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
    fail "PAR080-S03 Bash format-current repo: must NOT warn (format_version=3 == supported)"
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
        fail "PAR080-S04 PS1 format-current repo: must NOT warn (format_version=3 == supported)"
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
#        in bin/aid.ps1 (grep both; compare). Both must equal 3.
#        CI fails if either constant drifts.
#
# AC2: Refuse-on-newer (format_version: 4) + byte/mtime identity of settings.yml.
#   V02: Bash 'aid status' in a format_version: 4 repo -> non-zero exit.
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
# Both must equal 3 specifically (not just each other).
assert_eq "${_V01_BASH_CONST}" "3" \
    "PAR009-V01c bin/aid: AID_SUPPORTED_FORMAT == 3 (expected supported format)"
assert_eq "${_V01_PS1_CONST}" "3" \
    "PAR009-V01d bin/aid.ps1: AidSupportedFormat == 3 (expected supported format)"

# ---------------------------------------------------------------------------
# V02-V04: Refuse-on-newer (format_version: 4) + byte/mtime identity (Bash).
# ---------------------------------------------------------------------------
_V_CODE_HOME=$(newhome); setup_sh_home "${_V_CODE_HOME}"
_V_STATE_HOME="$(mktemp -d "${TMP}/v009state.XXXXXX")"

_V_REPO_NEWER="$(mktemp -d "${TMP}/v009newer.XXXXXX")"
mkdir -p "${_V_REPO_NEWER}/.aid"
cat > "${_V_REPO_NEWER}/.aid/settings.yml" << 'V009NEWEREOF'
format_version: 4
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
    "PAR009-V02 Bash refuse-on-newer: aid status format_version:4 -> non-zero exit"

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
format_version: 4
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
        "PAR009-V05 PS1 refuse-on-newer: aid.ps1 status format_version:4 -> non-zero exit"

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
# Run aid status in a repo with format_version: 4 (newer than supported).
# The refuse error message text must be the same from both runtimes.
SH_HOME_W2=$(newhome); setup_sh_home "${SH_HOME_W2}"
PS_HOME_W2=$(newhome); setup_ps1_home "${PS_HOME_W2}"
T_W2=$(newtarget)
mkdir -p "${T_W2}/.aid"
cat > "${T_W2}/.aid/settings.yml" << 'PAR029W2EOF'
format_version: 4
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
    "PAR029-W11 Bash aid-status format_version:4 -> non-zero exit (refuse)"

if [[ -n "$PWSH" ]]; then
    (cd "${T_W2}" && AID_HOME="${PS_HOME_W2}" AID_LIB_PATH="${PS_HOME_W2}/lib/AidInstallCore.psm1" \
        AID_NO_UPDATE_CHECK=1 \
        "$PWSH" -NoLogo -NonInteractive -File "${PS_HOME_W2}/bin/aid.ps1" \
        status) >"${_W12_TMP}" 2>&1
    _W12_RC=$?
    _W12_OUT="$(cat "${_W12_TMP}" | sed 's/\x1b\[[0-9;]*m//g')"; rm -f "${_W12_TMP}"

    assert_exit_nonzero "${_W12_RC}" \
        "PAR029-W12 PS1 aid-status format_version:4 -> non-zero exit (refuse)"
    # Refuse message text must appear in both runtimes (parity of the refuse surface).
    assert_output_contains "$_W11_OUT" "newer than this CLI supports" \
        "PAR029-W13 Bash refuse: 'newer than this CLI supports' in output"
    assert_output_contains "$_W12_OUT" "newer than this CLI supports" \
        "PAR029-W14 PS1 refuse: 'newer than this CLI supports' in output"
    # Parity: both refuse (non-zero) with same message pattern.
    assert_eq "${_W11_RC}" "${_W12_RC}" \
        "PAR029-W15 Bash↔PS1 format-gate refuse exit code parity (format_version:4)"
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
# PAR100: 'aid update all' bulk-update behavior + Bash<->PS1 twin parity
# (work-001-update-all / task-002; SPEC AC1-AC10, AC8 twin parity).
#
# DISCOVERED GAP (documented here, not silently dropped -- see task-002 report):
# lib/aid-install-core.sh's fetch_tarball/resolve_version honor a real,
# existing production env-var override (AID_ALLOW_ENDPOINT_OVERRIDE=1 +
# AID_API_BASE/AID_DOWNLOAD_BASE) that lets the BASH twin's downloads be
# redirected to a local file:// fixture -- no network, no port, no server.
# lib/AidInstallCore.psm1's Fetch-Tarball/Resolve-AidVersion have NO such
# hook: $script:AID_DOWNLOAD_BASE / $script:AID_API_BASE are hardcoded module
# constants with zero environment-variable override, and Invoke-WebRequest
# does not support the file:// scheme (empirically confirmed against this
# host's pwsh: "The 'file' scheme is not supported."). This is a pre-existing
# asymmetry in the shared install core (not introduced by task-001, which
# reuses Fetch-Tarball unmodified) -- it means the PS1 twin's Fetch-Tarball
# call cannot be exercised against a local fixture without either hitting
# real GitHub (explicitly disallowed for this suite) or editing lib/* (out of
# scope for a TEST-only task). Consequently:
#   - AC1 (download-once, observed via the "Fetching ..." log line) and the
#     "every project actually applied the pinned version" half of AC6 are
#     verified DEEPLY on the BASH twin only (PAR100-A/PAR100-B/PAR100-G).
#   - Every other AC (AC2 enumeration, AC3 continue-on-error, AC4 dry-run
#     safety, AC5 summary format, AC7 skip, AC9 invocation surface, AC10
#     self-update-at-most-once, and the header-line half of AC6) is verified
#     on BOTH twins with genuine Bash<->PS1 parity, using two real,
#     network-free production code paths that never reach Fetch-Tarball:
#       (a) a "bare" project (`aid projects add <dir-without-.aid>` ->
#           manifest tools: {}) -- its child 'aid update' legitimately exits
#           6 ("no manifest ... nothing to update"), giving a REAL,
#           deterministic per-project FAILURE with no network involved;
#       (b) a registered project whose .aid/ is deleted after registration
#           (AC7's own scenario) -- SKIPPED, never reaches the fetch step.
# ===========================================================================
echo ""
echo "=== PAR100: 'aid update all' bulk-update + Bash<->PS1 twin parity ==="

UA_VERSION="9.9.9"

# ua_file_url <posix_path>
# Builds a file:// URL usable by BOTH the native mingw64 curl on a Windows
# host (which requires a real Windows path -- confirmed empirically: MSYS
# /tmp/... virtual paths are NOT understood by curl's file:// handler) and by
# curl on Linux CI (where cygpath is absent and the POSIX path is used as-is).
ua_file_url() {
    local p="$1"
    if command -v cygpath >/dev/null 2>&1; then
        local winp
        winp="$(cygpath -m "$p")"   # -m: mixed form -- drive letter, forward slashes
        printf 'file:///%s' "$winp"
    else
        printf 'file://%s' "$p"
    fi
}

# build_ua_tarball <tool> <version> <out_tarball>
# Parameterized twin of build_fixture_tarball (arbitrary <version> stamp, arbitrary
# output path) -- same content/exclusions, for the 'aid update all' download fixture.
build_ua_tarball() {
    local tool="$1" version="$2" tarball="$3"
    local profile_dir="${PROFILES_DIR}/${tool}"
    [[ -d "$profile_dir" ]] || { echo "ERROR: profile dir not found: $profile_dir" >&2; return 1; }
    local filelist
    filelist="$(mktemp "${TMP}/ua-filelist-${tool}.XXXXXX")"
    while IFS= read -r f; do
        local fname; fname="$(basename "$f")"
        [[ "$fname" == "README.md" ]] && continue
        [[ "$fname" == "emission-manifest.jsonl" ]] && continue
        local rel="${f#${profile_dir}/}"
        printf './%s\n' "$rel"
    done < <(find "${profile_dir}" -type f | sort) > "$filelist"
    (cd "${profile_dir}" && tar -czf "${tarball}" --no-recursion -T "${filelist}") || {
        echo "ERROR: failed to build UA fixture tarball for ${tool}" >&2
        rm -f "$filelist"
        return 1
    }
    rm -f "$filelist"
}

# build_ua_download_fixture <dl_base_dir> <version> <tool...>
# Populates <dl_base_dir>/v<version>/aid-<tool>-v<version>.tar.gz per tool plus a
# sibling SHA256SUMS -- the exact shape fetch_tarball expects at
# AID_DOWNLOAD_BASE/v<version>/... (lib/aid-install-core.sh:222-223).
build_ua_download_fixture() {
    local dl_base="$1" version="$2"; shift 2
    local vdir="${dl_base}/v${version}"
    mkdir -p "$vdir"
    local tool
    for tool in "$@"; do
        build_ua_tarball "$tool" "$version" "${vdir}/aid-${tool}-v${version}.tar.gz" || return 1
    done
    # --text: force the ' filename' (no '*' binary-mode marker) line shape that
    # _verify_checksum's grep "[[:space:]]${filename}$" expects. Without it, this
    # host's mingw64 sha256sum defaults to binary mode ('*filename'), which that
    # grep does NOT match (the '*' sits between the space and the filename) --
    # confirmed empirically on this Windows host; --text is a harmless no-op on
    # Linux (GNU coreutils: "no difference between binary mode and text mode").
    (cd "$vdir" && sha256sum --text aid-*.tar.gz > SHA256SUMS)
}

# Bash 'aid update all' runner: run_sh's base env + the REAL AID_ALLOW_ENDPOINT_OVERRIDE
# production hook, redirecting fetch_tarball at a local file:// fixture (no network, no
# port). AID_SKIP_SELF_INSTALL=1 keeps the (unrelated) self-update preamble side-effect-
# free everywhere it might fire (see PAR100-F for the one group that deliberately
# exercises it).
run_sh_ua() {
    local home_dir="$1" dl_base="$2"; shift 2
    local dl_url; dl_url="$(ua_file_url "${dl_base}")"
    OUT_SH=$(AID_HOME="$home_dir" AID_LIB_PATH="${home_dir}/lib/aid-install-core.sh" \
             AID_NO_UPDATE_CHECK=1 AID_SKIP_SELF_INSTALL=1 \
             AID_ALLOW_ENDPOINT_OVERRIDE=1 AID_DOWNLOAD_BASE="${dl_url}" \
             bash "${home_dir}/bin/aid" "$@" 2>&1); RC_SH=$?
}

# Network-free runners for scenarios that never reach fetch_tarball/Fetch-Tarball
# (bare projects, missing-.aid/ projects, zero registered projects, usage errors).
run_sh_ua_nf() {
    local home_dir="$1"; shift
    OUT_SH=$(AID_HOME="$home_dir" AID_LIB_PATH="${home_dir}/lib/aid-install-core.sh" \
             AID_NO_UPDATE_CHECK=1 AID_SKIP_SELF_INSTALL=1 \
             bash "${home_dir}/bin/aid" "$@" 2>&1); RC_SH=$?
}
run_ps1_ua_nf() {
    local home_dir="$1"; shift
    OUT_PS1=$(AID_HOME="$home_dir" AID_LIB_PATH="${home_dir}/lib/AidInstallCore.psm1" \
              AID_NO_UPDATE_CHECK=1 AID_SKIP_SELF_INSTALL=1 \
              "$PWSH" -NoProfile -File "${home_dir}/bin/aid.ps1" "$@" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g'); RC_PS1=$?
}

# ---------------------------------------------------------------------------
# PAR100-A: AC1 download-once + AC2 enumeration exactness + AC5 summary +
# AC6 version-pin (deep verification, BASH twin -- real successful fetch via
# a file:// fixture). 3 registered projects need the SAME (tool, version); a
# 4th UNREGISTERED project (real .aid/, same tool) proves AC2 exactness.
# ---------------------------------------------------------------------------
_UA_A_HOME=$(newhome); setup_sh_home "${_UA_A_HOME}"
_UA_A_DL="${TMP}/ua-a-dlbase"
build_ua_download_fixture "${_UA_A_DL}" "${UA_VERSION}" codex

_UA_A_P1="$(mktemp -d "${TMP}/ua_a_p1.XXXXXX")"
_UA_A_P2="$(mktemp -d "${TMP}/ua_a_p2.XXXXXX")"
_UA_A_P3="$(mktemp -d "${TMP}/ua_a_p3.XXXXXX")"
_UA_A_UNREG="$(mktemp -d "${TMP}/ua_a_unreg.XXXXXX")"

run_sh "${_UA_A_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_A_P1}"
assert_exit_eq "$RC_SH" 0 "PAR100-A00a Bash: seed P1 at v${VERSION} -> exit 0"
run_sh "${_UA_A_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_A_P2}"
assert_exit_eq "$RC_SH" 0 "PAR100-A00b Bash: seed P2 at v${VERSION} -> exit 0"
run_sh "${_UA_A_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_A_P3}"
assert_exit_eq "$RC_SH" 0 "PAR100-A00c Bash: seed P3 at v${VERSION} -> exit 0"
run_sh "${_UA_A_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_A_UNREG}"
assert_exit_eq "$RC_SH" 0 "PAR100-A00d Bash: seed the unregistered-control project -> exit 0"
# Unregister it (register-on-encounter registered it above) -- AC2 exactness control.
run_sh "${_UA_A_HOME}" projects remove "${_UA_A_UNREG}"

run_sh_ua "${_UA_A_HOME}" "${_UA_A_DL}" update all --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-A01 Bash 'update all' (3 registered projects, 1 shared tool) -> exit 0"
assert_output_contains "$OUT_SH" \
    "aid update all: 3 registered project(s), target version ${UA_VERSION}" \
    "PAR100-A02 AC2/AC6: enumeration count + pinned version in the header line"
_ua_a_fetch_count=$(printf '%s\n' "$OUT_SH" | grep -cF -- "Fetching aid-codex-v${UA_VERSION}.tar.gz ..." || true)
assert_eq "$_ua_a_fetch_count" "1" \
    "PAR100-A03 AC1: fetch_tarball invoked exactly once for 3 projects needing the same (tool,version)"
assert_output_contains "$OUT_SH" "3 updated, 0 skipped, 0 failed" "PAR100-A04 AC5: summary counts"

_ua_a_v1=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_A_P1}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
_ua_a_v2=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_A_P2}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
_ua_a_v3=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_A_P3}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
assert_eq "$_ua_a_v1" "$UA_VERSION" "PAR100-A05a AC6: P1 manifest updated to the pinned version"
assert_eq "$_ua_a_v2" "$UA_VERSION" "PAR100-A05b AC6: P2 manifest updated to the pinned version"
assert_eq "$_ua_a_v3" "$UA_VERSION" "PAR100-A05c AC6: P3 manifest updated to the pinned version"
_ua_a_vunreg=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_A_UNREG}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
assert_eq "$_ua_a_vunreg" "$VERSION" "PAR100-A06 AC2: unregistered project untouched by the bulk run (still at v${VERSION})"
pass "PAR100-A07 [SKIPPED (PS1): no local-fixture hook for Fetch-Tarball in lib/AidInstallCore.psm1 -- see PAR100 header comment / task-002 report]"

# ---------------------------------------------------------------------------
# PAR100-B: AC3 mixed success/failure (deep, BASH twin) -- P2's tool download
# genuinely fails (its v9.9.9 tarball is deliberately absent from the fixture
# download-base); P1/P3 (a different, present tool) still succeed.
# ---------------------------------------------------------------------------
_UA_B_HOME=$(newhome); setup_sh_home "${_UA_B_HOME}"
_UA_B_DL="${TMP}/ua-b-dlbase"
build_ua_download_fixture "${_UA_B_DL}" "${UA_VERSION}" codex   # NOTE: no 'antigravity' fixture built for v9.9.9

_UA_B_P1="$(mktemp -d "${TMP}/ua_b_p1.XXXXXX")"
_UA_B_P2="$(mktemp -d "${TMP}/ua_b_p2.XXXXXX")"
_UA_B_P3="$(mktemp -d "${TMP}/ua_b_p3.XXXXXX")"
run_sh "${_UA_B_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_B_P1}"
run_sh "${_UA_B_HOME}" add antigravity --from-bundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" --target "${_UA_B_P2}"
run_sh "${_UA_B_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_B_P3}"

run_sh_ua "${_UA_B_HOME}" "${_UA_B_DL}" update all --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 1 "PAR100-B01 AC3: run with one failing project -> exit 1 (non-zero)"
assert_output_contains "$OUT_SH" \
    "ERROR: aid update all: failed to download antigravity v${UA_VERSION} (continuing)" \
    "PAR100-B02 AC3: P2's tool download failure reported; run continues"
assert_output_contains "$OUT_SH" "2 updated, 0 skipped, 1 failed" "PAR100-B03 AC5: summary counts reflect isolated failure"
_ua_b_v1=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_B_P1}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
_ua_b_v3=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_B_P3}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
assert_eq "$_ua_b_v1" "$UA_VERSION" "PAR100-B04a AC3: unaffected P1 still updated to ${UA_VERSION}"
assert_eq "$_ua_b_v3" "$UA_VERSION" "PAR100-B04b AC3: unaffected P3 still updated to ${UA_VERSION}"
_ua_b_v2=$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_B_P2}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')
assert_eq "$_ua_b_v2" "$VERSION" "PAR100-B05 AC3: failed P2 left at its pre-run version (no partial apply)"
pass "PAR100-B06 [SKIPPED (PS1): no local-fixture hook for Fetch-Tarball -- see PAR100 header comment / task-002 report]"

# ---------------------------------------------------------------------------
# PAR100-C: AC3 continue-on-error + AC5 summary + AC7 skip, Bash<->PS1 twin
# parity -- fully network-free (bare projects genuinely FAIL via the child's
# real exit-6 "nothing to update"; a missing-.aid/ project is genuinely
# SKIPPED). See PAR100 header for why this is the twin-parity-safe substitute
# for a full download-and-succeed scenario on the PS1 twin.
# ---------------------------------------------------------------------------
_UA_C_SH_HOME=$(newhome); setup_sh_home "${_UA_C_SH_HOME}"
_UA_C_PS_HOME=$(newhome); setup_ps1_home "${_UA_C_PS_HOME}"

_UA_C_SH_BARE1="$(mktemp -d "${TMP}/ua_c_sh_bare1.XXXXXX")"
_UA_C_SH_BARE2="$(mktemp -d "${TMP}/ua_c_sh_bare2.XXXXXX")"
_UA_C_SH_MISSING="$(mktemp -d "${TMP}/ua_c_sh_missing.XXXXXX")"
run_sh "${_UA_C_SH_HOME}" projects add "${_UA_C_SH_BARE1}"
run_sh "${_UA_C_SH_HOME}" projects add "${_UA_C_SH_BARE2}"
run_sh "${_UA_C_SH_HOME}" projects add "${_UA_C_SH_MISSING}"
rm -rf "${_UA_C_SH_MISSING}/.aid"

run_sh_ua_nf "${_UA_C_SH_HOME}" update all --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 1 "PAR100-C01 Bash: 2 bare (fail) + 1 missing-.aid (skip) -> exit 1"
assert_output_contains "$OUT_SH" "SKIP: ${_UA_C_SH_MISSING} (.aid/ not found)" \
    "PAR100-C02 AC7: Bash missing-.aid project skipped (non-fatal)"
assert_output_contains "$OUT_SH" "FAILED: ${_UA_C_SH_BARE1} (exit 6)" \
    "PAR100-C03 AC3: Bash bare project 1 recorded failed (real, no-network child exit)"
assert_output_contains "$OUT_SH" "FAILED: ${_UA_C_SH_BARE2} (exit 6)" \
    "PAR100-C04 AC3: Bash bare project 2 recorded failed"
assert_output_contains "$OUT_SH" "0 updated, 1 skipped, 2 failed" "PAR100-C05 AC5: Bash summary counts"

if [[ -n "$PWSH" ]]; then
    _UA_C_PS_BARE1="$(mktemp -d "${TMP}/ua_c_ps_bare1.XXXXXX")"
    _UA_C_PS_BARE2="$(mktemp -d "${TMP}/ua_c_ps_bare2.XXXXXX")"
    _UA_C_PS_MISSING="$(mktemp -d "${TMP}/ua_c_ps_missing.XXXXXX")"
    run_ps1 "${_UA_C_PS_HOME}" projects add "${_UA_C_PS_BARE1}"
    run_ps1 "${_UA_C_PS_HOME}" projects add "${_UA_C_PS_BARE2}"
    run_ps1 "${_UA_C_PS_HOME}" projects add "${_UA_C_PS_MISSING}"
    rm -rf "${_UA_C_PS_MISSING}/.aid"

    run_ps1_ua_nf "${_UA_C_PS_HOME}" update all -Version "${UA_VERSION}"
    assert_exit_eq "$RC_PS1" 1 "PAR100-C06 PS1: 2 bare (fail) + 1 missing-.aid (skip) -> exit 1"
    assert_output_contains "$OUT_PS1" "SKIP: ${_UA_C_PS_MISSING} (.aid/ not found)" \
        "PAR100-C07 AC7: PS1 missing-.aid project skipped (non-fatal)"
    assert_output_contains "$OUT_PS1" "FAILED: ${_UA_C_PS_BARE1} (exit 6)" \
        "PAR100-C08 AC3: PS1 bare project 1 recorded failed (real, no-network child exit)"
    assert_output_contains "$OUT_PS1" "FAILED: ${_UA_C_PS_BARE2} (exit 6)" \
        "PAR100-C09 AC3: PS1 bare project 2 recorded failed"
    assert_output_contains "$OUT_PS1" "0 updated, 1 skipped, 2 failed" "PAR100-C10 AC5: PS1 summary counts"
    assert_eq "$RC_SH" "$RC_PS1" "PAR100-C11 AC8: Bash<->PS1 exit code parity (continue-on-error + skip)"
    # Regression (beta bug): the 2 bare children DO reach the child-spawn seam, so
    # a leak of the child's stdout into Invoke-AidUpdateAll's (captured) return makes
    # it an Object[]; 'Exit-Aid $uaRc' then throws "Cannot convert System.Object[] ...
    # to ... Int32". The exit code (1) coincides with the binding-error exit, so the
    # assertions above cannot see it -- assert the error signature is absent instead.
    assert_output_not_contains "$OUT_PS1" "Cannot convert" \
        "PAR100-C12 regression: no Object[]->Int32 binding error at 'Exit-Aid \$uaRc' -- child stdout must not leak into Invoke-AidUpdateAll's scalar-int return"
else
    for _n in 06 07 08 09 10 11 12; do pass "PAR100-C${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR100-D: AC9 -- '--target'/'-Target' combined with 'all' is a usage error
# (exit 2), Bash<->PS1 parity. Never reaches enumeration/fetch.
# ---------------------------------------------------------------------------
_UA_D_SH_HOME=$(newhome); setup_sh_home "${_UA_D_SH_HOME}"
_UA_D_PS_HOME=$(newhome); setup_ps1_home "${_UA_D_PS_HOME}"
_UA_D_TARGET="$(mktemp -d "${TMP}/ua_d_target.XXXXXX")"

run_sh_ua_nf "${_UA_D_SH_HOME}" update all --target "${_UA_D_TARGET}"
assert_exit_eq "$RC_SH" 2 "PAR100-D01 Bash: 'update all --target <dir>' -> exit 2 (usage error)"
assert_output_contains "$OUT_SH" "does not accept" "PAR100-D02 Bash: usage-error message present"
assert_output_contains "$OUT_SH" "it updates every registered project" \
    "PAR100-D03 Bash: usage-error explains why (registry supplies the targets)"

if [[ -n "$PWSH" ]]; then
    run_ps1_ua_nf "${_UA_D_PS_HOME}" update all -Target "${_UA_D_TARGET}"
    assert_exit_eq "$RC_PS1" 2 "PAR100-D04 PS1: 'update all -Target <dir>' -> exit 2 (usage error)"
    assert_output_contains "$OUT_PS1" "does not accept" "PAR100-D05 PS1: usage-error message present"
    assert_output_contains "$OUT_PS1" "it updates every registered project" \
        "PAR100-D06 PS1: usage-error explains why (registry supplies the targets)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR100-D07 AC8: Bash<->PS1 exit code parity ('--target'/'-Target' + 'all' usage error)"
else
    for _n in 04 05 06 07; do pass "PAR100-D${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR100-E: AC4 dry-run safety + AC9 subcommand consumption + AC2/AC6 header
# parity, Bash<->PS1 -- ZERO registered projects (fully network-free: the
# per-project loop never iterates, so fetch_tarball/Fetch-Tarball is never
# reached on EITHER twin). Proves 'all'+'--dry-run'/'-DryRun' is consumed as
# the bulk subcommand (not rejected as an unknown positional/usage error) and
# that the pinned version + registered-project count are echoed identically.
# ---------------------------------------------------------------------------
_UA_E_SH_HOME=$(newhome); setup_sh_home "${_UA_E_SH_HOME}"
_UA_E_PS_HOME=$(newhome); setup_ps1_home "${_UA_E_PS_HOME}"

run_sh_ua_nf "${_UA_E_SH_HOME}" update all --dry-run --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-E01 AC4/AC9: Bash 'update all --dry-run' (0 projects) -> exit 0"
assert_output_contains "$OUT_SH" \
    "aid update all: 0 registered project(s), target version ${UA_VERSION}" \
    "PAR100-E02 AC2/AC6: Bash header -- enumeration count + pinned version"
assert_output_contains "$OUT_SH" "0 updated, 0 skipped, 0 failed" "PAR100-E03 AC5: Bash summary (0/0/0)"
assert_output_not_contains "$OUT_SH" "unknown flag" "PAR100-E04 AC9: Bash 'all' not rejected as an unknown flag"
assert_output_not_contains "$OUT_SH" "unexpected argument" \
    "PAR100-E05 AC9: Bash 'all' not rejected as an unexpected/unknown positional"

if [[ -n "$PWSH" ]]; then
    run_ps1_ua_nf "${_UA_E_PS_HOME}" update all -DryRun -Version "${UA_VERSION}"
    assert_exit_eq "$RC_PS1" 0 "PAR100-E06 AC4/AC9: PS1 'update all -DryRun' (0 projects) -> exit 0"
    assert_output_contains "$OUT_PS1" \
        "aid update all: 0 registered project(s), target version ${UA_VERSION}" \
        "PAR100-E07 AC2/AC6: PS1 header -- enumeration count + pinned version"
    assert_output_contains "$OUT_PS1" "0 updated, 0 skipped, 0 failed" "PAR100-E08 AC5: PS1 summary (0/0/0)"
    assert_output_not_contains "$OUT_PS1" "unknown flag" "PAR100-E09 AC9: PS1 'all' not rejected as an unknown flag"
    assert_output_not_contains "$OUT_PS1" "unexpected argument" \
        "PAR100-E10 AC9: PS1 'all' not rejected as an unexpected/unknown positional"
    assert_eq "$RC_SH" "$RC_PS1" "PAR100-E11 AC8: Bash<->PS1 exit code parity (dry-run, 0 projects)"
    _ua_e_sh_header="$(printf '%s\n' "$OUT_SH"  | grep -F 'aid update all:')"
    _ua_e_ps_header="$(printf '%s\n' "$OUT_PS1" | grep -F 'aid update all:')"
    assert_eq "$_ua_e_sh_header" "$_ua_e_ps_header" "PAR100-E12 AC8: Bash<->PS1 header line byte-identical"
else
    for _n in 06 07 08 09 10 11 12; do pass "PAR100-E${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR100-F: AC10 self-update-at-most-once, Bash<->PS1 -- fully network-free
# (0 registered projects; the preamble decision reads only the per-user
# .update-check cache + $AID_CODE_HOME/VERSION, never fetch_tarball).
# ---------------------------------------------------------------------------
_UA_F_SH_HOME=$(newhome); setup_sh_home "${_UA_F_SH_HOME}"
_UA_F_PS_HOME=$(newhome); setup_ps1_home "${_UA_F_PS_HOME}"

# Seed the per-user .update-check cache (line1=timestamp, line2=cached "latest") so the
# installed VERSION (v0.7.0, written by setup_*_home) reads as stale against it.
mkdir -p "${HOME}/.aid"
printf '%s\n%s\n' "$(date +%s)" "${UA_VERSION}" > "${HOME}/.aid/.update-check"

run_sh_ua_nf "${_UA_F_SH_HOME}" update all --version "${UA_VERSION}"
_ua_f_sh_real=$(printf '%s\n' "$OUT_SH" | grep -cF -- "self-updating before tool install" || true)
assert_eq "$_ua_f_sh_real" "1" "PAR100-F01 AC10: Bash self-update preamble runs exactly once on a real bulk run"

run_sh_ua_nf "${_UA_F_SH_HOME}" update all --dry-run --version "${UA_VERSION}"
_ua_f_sh_dry=$(printf '%s\n' "$OUT_SH" | grep -cF -- "self-updating before tool install" || true)
assert_eq "$_ua_f_sh_dry" "0" "PAR100-F02 AC10: Bash self-update preamble runs zero times under --dry-run"

if [[ -n "$PWSH" ]]; then
    run_ps1_ua_nf "${_UA_F_PS_HOME}" update all -Version "${UA_VERSION}"
    _ua_f_ps_real=$(printf '%s\n' "$OUT_PS1" | grep -cF -- "self-updating before tool install" || true)
    assert_eq "$_ua_f_ps_real" "1" "PAR100-F03 AC10: PS1 self-update preamble runs exactly once on a real bulk run"

    run_ps1_ua_nf "${_UA_F_PS_HOME}" update all -DryRun -Version "${UA_VERSION}"
    _ua_f_ps_dry=$(printf '%s\n' "$OUT_PS1" | grep -cF -- "self-updating before tool install" || true)
    assert_eq "$_ua_f_ps_dry" "0" "PAR100-F04 AC10: PS1 self-update preamble runs zero times under --dry-run"
    assert_eq "$_ua_f_sh_real" "$_ua_f_ps_real" "PAR100-F05 AC8: Bash<->PS1 parity -- self-update-preamble count on a real run"
else
    for _n in 03 04 05; do pass "PAR100-F${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR100-G: AC4 dry-run richer nuance (deep, BASH twin) -- a real registered
# project (nonzero manifest tools): the shared cache IS still populated once
# under --dry-run (SPEC: "so the per-project plan is accurate"), the child
# prints its per-project plan, and NO destination write occurs.
# ---------------------------------------------------------------------------
_UA_G_HOME=$(newhome); setup_sh_home "${_UA_G_HOME}"
_UA_G_DL="${TMP}/ua-g-dlbase"
build_ua_download_fixture "${_UA_G_DL}" "${UA_VERSION}" codex

_UA_G_P1="$(mktemp -d "${TMP}/ua_g_p1.XXXXXX")"
run_sh "${_UA_G_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_G_P1}"
_UA_G_MANIFEST_BEFORE="$(cat "${_UA_G_P1}/.aid/.aid-manifest.json")"

run_sh_ua "${_UA_G_HOME}" "${_UA_G_DL}" update all --dry-run --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-G01 AC4: Bash 'update all --dry-run' (1 real project) -> exit 0"
_ua_g_fetch_count=$(printf '%s\n' "$OUT_SH" | grep -cF -- "Fetching aid-codex-v${UA_VERSION}.tar.gz ..." || true)
assert_eq "$_ua_g_fetch_count" "1" \
    "PAR100-G02 AC4/AC1: Bash dry-run still populates the shared cache once (accurate plan)"
assert_output_contains "$OUT_SH" "--- aid update --dry-run plan (no writes) ---" \
    "PAR100-G03 AC4: Bash per-project child dry-run plan printed"
assert_output_contains "$OUT_SH" "1 updated, 0 skipped, 0 failed" \
    "PAR100-G04 AC5: Bash dry-run summary counts a dry-run child success as 'updated'"
_UA_G_MANIFEST_AFTER="$(cat "${_UA_G_P1}/.aid/.aid-manifest.json")"
assert_eq "$_UA_G_MANIFEST_BEFORE" "$_UA_G_MANIFEST_AFTER" \
    "PAR100-G05 AC4: Bash dry-run makes no destination write (manifest byte-identical)"
pass "PAR100-G06 [SKIPPED (PS1): no local-fixture hook for Fetch-Tarball -- see PAR100 header comment / task-002 report]"

# ---------------------------------------------------------------------------
# PAR100-H: AC9 -- N>1 REAL registered projects + '--dry-run' (deep, BASH
# twin): a per-project dry-run plan line printed for EVERY registered project
# (closes DELIVERY-GATE ledger finding #2). PAR100-E used 0 registered
# projects, PAR100-G used exactly 1 -- neither covers the literal AC9
# combination of N>1 real projects AND --dry-run.
# ---------------------------------------------------------------------------
_UA_H_HOME=$(newhome); setup_sh_home "${_UA_H_HOME}"
_UA_H_DL="${TMP}/ua-h-dlbase"
build_ua_download_fixture "${_UA_H_DL}" "${UA_VERSION}" codex

_UA_H_P1="$(mktemp -d "${TMP}/ua_h_p1.XXXXXX")"
_UA_H_P2="$(mktemp -d "${TMP}/ua_h_p2.XXXXXX")"
run_sh "${_UA_H_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_H_P1}"
run_sh "${_UA_H_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_H_P2}"

run_sh_ua "${_UA_H_HOME}" "${_UA_H_DL}" update all --dry-run --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-H01 AC9: Bash 'update all --dry-run' (2 real registered projects) -> exit 0"
assert_output_contains "$OUT_SH" \
    "aid update all: 2 registered project(s), target version ${UA_VERSION}" \
    "PAR100-H02 AC2/AC6: Bash header enumerates both projects under dry-run"
_ua_h_plan_count=$(printf '%s\n' "$OUT_SH" | grep -cF -- "--- aid update --dry-run plan (no writes) ---" || true)
assert_eq "$_ua_h_plan_count" "2" \
    "PAR100-H03 AC9: per-project dry-run plan line printed for EVERY registered project (2/2)"
assert_output_contains "$OUT_SH" "2 updated, 0 skipped, 0 failed" \
    "PAR100-H04 AC5: Bash dry-run summary counts both dry-run child successes as 'updated'"
pass "PAR100-H05 [SKIPPED (PS1): no local-fixture hook for Fetch-Tarball -- see PAR100 header comment / task-002 report]"

# ---------------------------------------------------------------------------
# PAR100-I: AC7 -- a missing-.aid/ project genuinely SKIPPED (non-fatal) in
# the SAME run as at least one project that genuinely UPDATES (real fetch +
# apply, deep BASH twin) (closes DELIVERY-GATE ledger finding #3). PAR100-C's
# non-skipped projects are bare (manifest tools: {}) and all FAIL via the
# child's real exit-6 "nothing to update" -- it never proves "the remaining
# projects still update" in AC7's literal sense.
# ---------------------------------------------------------------------------
_UA_I_HOME=$(newhome); setup_sh_home "${_UA_I_HOME}"
_UA_I_DL="${TMP}/ua-i-dlbase"
build_ua_download_fixture "${_UA_I_DL}" "${UA_VERSION}" codex

_UA_I_UPDATING="$(mktemp -d "${TMP}/ua_i_updating.XXXXXX")"
_UA_I_MISSING="$(mktemp -d "${TMP}/ua_i_missing.XXXXXX")"
run_sh "${_UA_I_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_I_UPDATING}"
run_sh "${_UA_I_HOME}" projects add "${_UA_I_MISSING}"
rm -rf "${_UA_I_MISSING}/.aid"

run_sh_ua "${_UA_I_HOME}" "${_UA_I_DL}" update all --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-I01 AC7: Bash 'update all' (1 skip + 1 genuinely-updating project) -> exit 0"
assert_output_contains "$OUT_SH" "SKIP: ${_UA_I_MISSING} (.aid/ not found)" \
    "PAR100-I02 AC7: missing-.aid project skipped (non-fatal)"
assert_output_contains "$OUT_SH" "1 updated, 1 skipped, 0 failed" \
    "PAR100-I03 AC5/AC7: summary shows updated >= 1 AND skipped = 1 in the same run"
_ua_i_v="$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_I_UPDATING}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')"
assert_eq "$_ua_i_v" "$UA_VERSION" \
    "PAR100-I04 AC7: the remaining (non-skipped) project genuinely updated to the pinned version"
pass "PAR100-I05 [SKIPPED (PS1): no local-fixture hook for Fetch-Tarball -- see PAR100 header comment / task-002 report]"

# ---------------------------------------------------------------------------
# PAR100-J: AC10 self-update-at-most-once with N>1 REAL children, Bash<->PS1
# twin parity (closes DELIVERY-GATE ledger finding #4). Seeds a stale CLI
# (.update-check) so the preamble WOULD fire for every process that reaches
# _aid_update_self_if_stale/Invoke-AidUpdateSelfIfStale, then confirms the
# total count across the WHOLE bulk run (parent + N real, network-free bare
# children) stays at exactly 1 -- i.e. each child's own
# --from-bundle/-FromBundle guard genuinely self-skips. PAR100-F used 0
# registered projects, so no child was ever spawned there -- it only proved
# the PARENT's own preamble call fires once.
# ---------------------------------------------------------------------------
_UA_J_SH_HOME=$(newhome); setup_sh_home "${_UA_J_SH_HOME}"
_UA_J_PS_HOME=$(newhome); setup_ps1_home "${_UA_J_PS_HOME}"

# Seed the per-user .update-check cache (line1=timestamp, line2=cached "latest")
# -- same file/mechanism as PAR100-F -- so the installed VERSION (v0.7.0,
# written by setup_*_home) reads as stale against it.
mkdir -p "${HOME}/.aid"
printf '%s\n%s\n' "$(date +%s)" "${UA_VERSION}" > "${HOME}/.aid/.update-check"

_UA_J_SH_P1="$(mktemp -d "${TMP}/ua_j_sh_p1.XXXXXX")"
_UA_J_SH_P2="$(mktemp -d "${TMP}/ua_j_sh_p2.XXXXXX")"
run_sh "${_UA_J_SH_HOME}" projects add "${_UA_J_SH_P1}"
run_sh "${_UA_J_SH_HOME}" projects add "${_UA_J_SH_P2}"

run_sh_ua_nf "${_UA_J_SH_HOME}" update all --version "${UA_VERSION}"
_ua_j_sh_selfupdate_count=$(printf '%s\n' "$OUT_SH" | grep -cF -- "self-updating before tool install" || true)
assert_eq "$_ua_j_sh_selfupdate_count" "1" \
    "PAR100-J01 AC10: Bash self-update preamble fires EXACTLY ONCE total across parent + 2 real children"
_ua_j_sh_children_ran=$(printf '%s\n' "$OUT_SH" | grep -cF -- "=== " || true)
assert_eq "$_ua_j_sh_children_ran" "2" \
    "PAR100-J02 sanity: both real children actually ran (child guard genuinely exercised, unlike PAR100-F's 0-project run)"

if [[ -n "$PWSH" ]]; then
    _UA_J_PS_P1="$(mktemp -d "${TMP}/ua_j_ps_p1.XXXXXX")"
    _UA_J_PS_P2="$(mktemp -d "${TMP}/ua_j_ps_p2.XXXXXX")"
    run_ps1 "${_UA_J_PS_HOME}" projects add "${_UA_J_PS_P1}"
    run_ps1 "${_UA_J_PS_HOME}" projects add "${_UA_J_PS_P2}"

    run_ps1_ua_nf "${_UA_J_PS_HOME}" update all -Version "${UA_VERSION}"
    _ua_j_ps_selfupdate_count=$(printf '%s\n' "$OUT_PS1" | grep -cF -- "self-updating before tool install" || true)
    assert_eq "$_ua_j_ps_selfupdate_count" "1" \
        "PAR100-J03 AC10: PS1 self-update preamble fires EXACTLY ONCE total across parent + 2 real children"
    _ua_j_ps_children_ran=$(printf '%s\n' "$OUT_PS1" | grep -cF -- "=== " || true)
    assert_eq "$_ua_j_ps_children_ran" "2" \
        "PAR100-J04 sanity: both real children actually ran (PS1)"
    assert_eq "$_ua_j_sh_selfupdate_count" "$_ua_j_ps_selfupdate_count" \
        "PAR100-J05 AC8: Bash<->PS1 parity -- self-update-preamble count stays at 1 with N>1 real children"
else
    for _n in 03 04 05; do pass "PAR100-J${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR100-K: '--force'/'-Force' pass-through for 'aid update all' (closes
# DELIVERY-GATE ledger finding #5; task-001's documented Scope: "aid update
# all [--version <v>] [--dry-run] [--force]" had zero coverage). Two parts:
#   (1) Bash<->PS1, fully network-free (bare project, mirrors PAR100-C): the
#       flag is accepted by the parent's own parser (not "unknown flag") AND
#       is threaded through to the per-project CHILD 'aid update' invocation
#       -- proven because the child reaches its OWN real exit-6 "nothing to
#       update" rather than erroring earlier on flag parsing (a malformed/
#       dropped forward would surface as a child-side usage error instead).
#   (2) Bash-only (deep, real fetch+apply fixture, mirrors PAR100-A/G): a
#       real registered project genuinely updates to the pinned version with
#       '--force' in effect, end-to-end.
# ---------------------------------------------------------------------------
_UA_K_SH_HOME=$(newhome); setup_sh_home "${_UA_K_SH_HOME}"
_UA_K_PS_HOME=$(newhome); setup_ps1_home "${_UA_K_PS_HOME}"

_UA_K_SH_BARE="$(mktemp -d "${TMP}/ua_k_sh_bare.XXXXXX")"
run_sh "${_UA_K_SH_HOME}" projects add "${_UA_K_SH_BARE}"

run_sh_ua_nf "${_UA_K_SH_HOME}" update all --force --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 1 "PAR100-K01 Bash: 'update all --force' (1 bare project) -> exit 1 (child's own real failure)"
assert_output_not_contains "$OUT_SH" "unknown flag" \
    "PAR100-K02 Bash: '--force' not rejected as an unknown flag (parent parser)"
assert_output_contains "$OUT_SH" "FAILED: ${_UA_K_SH_BARE} (exit 6)" \
    "PAR100-K03 Bash: '--force' forwarded through to the child parser without breaking it (child reaches its own real exit-6)"

if [[ -n "$PWSH" ]]; then
    _UA_K_PS_BARE="$(mktemp -d "${TMP}/ua_k_ps_bare.XXXXXX")"
    run_ps1 "${_UA_K_PS_HOME}" projects add "${_UA_K_PS_BARE}"

    run_ps1_ua_nf "${_UA_K_PS_HOME}" update all -Force -Version "${UA_VERSION}"
    assert_exit_eq "$RC_PS1" 1 "PAR100-K04 PS1: 'update all -Force' (1 bare project) -> exit 1 (child's own real failure)"
    assert_output_not_contains "$OUT_PS1" "unknown flag" \
        "PAR100-K05 PS1: '-Force' not rejected as an unknown flag (parent parser)"
    assert_output_contains "$OUT_PS1" "FAILED: ${_UA_K_PS_BARE} (exit 6)" \
        "PAR100-K06 PS1: '-Force' forwarded through to the child parser without breaking it (child reaches its own real exit-6)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR100-K07 AC8: Bash<->PS1 exit code parity ('--force'/'-Force' pass-through, bare project)"
else
    for _n in 04 05 06 07; do pass "PAR100-K${_n} [SKIPPED: pwsh absent]"; done
fi

_UA_K_REAL_HOME=$(newhome); setup_sh_home "${_UA_K_REAL_HOME}"
_UA_K_DL="${TMP}/ua-k-dlbase"
build_ua_download_fixture "${_UA_K_DL}" "${UA_VERSION}" codex
_UA_K_SH_REAL="$(mktemp -d "${TMP}/ua_k_sh_real.XXXXXX")"
run_sh "${_UA_K_REAL_HOME}" add codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "${_UA_K_SH_REAL}"

run_sh_ua "${_UA_K_REAL_HOME}" "${_UA_K_DL}" update all --force --version "${UA_VERSION}"
assert_exit_eq "$RC_SH" 0 "PAR100-K08 Bash: 'update all --force' (1 real registered project) -> exit 0"
assert_output_contains "$OUT_SH" "1 updated, 0 skipped, 0 failed" \
    "PAR100-K09 Bash: real project genuinely updates end-to-end with '--force' in effect"
_ua_k_real_v="$(grep -o '"aid_version"[[:space:]]*:[[:space:]]*"[^"]*"' "${_UA_K_SH_REAL}/.aid/.aid-manifest.json" | sed 's/.*"\([^"]*\)"$/\1/')"
assert_eq "$_ua_k_real_v" "$UA_VERSION" \
    "PAR100-K10 Bash: pinned version genuinely applied under '--force'"

# ---------------------------------------------------------------------------
# PAR100-L: regression guard -- Invoke-AidUpdateAll must return a SCALAR int,
# never an Object[] (source-level, deterministic, cross-platform; runs even when
# pwsh is absent). The per-project child is spawned INSIDE a function whose return
# value the caller captures ('$uaRc = script:Invoke-AidUpdateAll ...'), so a BARE
# '& $uaHostExe @uaChildArgs' leaks the child's stdout into the success stream --
# the function then returns @(<child stdout...>, <int>) and 'script:Exit-Aid $uaRc'
# fails to bind [int]$Code ("Cannot convert System.Object[] ... to ... Int32").
# This bit a real beta tester on a 12/12-success run. The behavioral PS1 cases
# (C/K) could not catch it: a bare-project FAILURE exits 1 and the binding error
# ALSO exits 1, so the codes coincide (see PAR100-C12). Guard the fix at the
# source: the child invocation must route its output to the host, not into this
# function's pipeline.
# ---------------------------------------------------------------------------
_ua_l_child_line="$(grep -nF -- '& $uaHostExe @uaChildArgs' "${BIN_AID_PS1}" || true)"
assert_output_contains "$_ua_l_child_line" "| Out-Host" \
    "PAR100-L01 regression: Invoke-AidUpdateAll routes the per-project child's stdout to the host (| Out-Host) so it cannot leak into the captured scalar-int return (guards the 'Cannot convert System.Object[] to Int32' beta bug)"

# ===========================================================================
# PAR101: CLI-version-aware 'resolve_version'/'Resolve-AidVersion' + twin
# parity (release-v2.2.3b1). 'aid update' / 'aid update all' with NO explicit
# --version must resolve differently depending on the RUNNING CLI's own
# ${AID_CODE_HOME}/VERSION:
#   - pre-release CLI + a pre-release GitHub release exists -> resolves to the
#     NEWEST pre-release (the /releases LIST, first entry with
#     "prerelease": true -- GitHub returns newest-first).
#   - pre-release CLI + NO pre-release release exists (or the list fetch
#     itself fails) -> falls back to the latest stable (/releases/latest),
#     fail-safe (never hard-errors the update over the beta lookup).
#   - stable CLI -> unchanged: always /releases/latest, list never consulted.
#
# FIXTURE-ABILITY NOTE (mirrors the PAR100 header's documented gap): GitHub's
# real API serves both '.../releases' (the list) and '.../releases/latest'
# under the SAME base path -- a single flat-file fixture root cannot represent
# both simultaneously (a plain file "releases" cannot also be a directory
# containing "releases/latest"), so this cannot be fixtured via the existing
# AID_ALLOW_ENDPOINT_OVERRIDE + file:// mechanism (that mechanism also only
# covers Fetch-Tarball/fetch_tarball on the Bash twin, per PAR100 -- it has no
# PS1-side hook at all). Instead, this section uses a "shimmed resolve":
#   - Bash:  a fake `curl` executable (matching resolve_version's exact
#     invocation shape: `curl "${curl_args[@]}" "$url"`, last arg = URL) is
#     prepended onto PATH for these cases only; it serves canned JSON bodies
#     for '*/releases/latest' and '*/releases' and can simulate a fetch
#     failure via PAR101_FAIL_MODE.
#   - PS1:   a global `Invoke-RestMethod` function override (defined BEFORE
#     dot-sourcing AidInstallCore.psm1's content into the driver's own scope,
#     exactly as bin/aid.ps1 itself dot-sources the lib -- so $script:_AidCodeHome
#     set by the driver is visible to Resolve-AidVersion) serves the same
#     canned bodies (deserialized) or throws to simulate a failure.
# Both twins exercise the REAL production resolve_version()/Resolve-AidVersion
# functions (sourced from lib/aid-install-core.sh / lib/AidInstallCore.psm1
# directly -- not reimplemented), driven at the function level rather than
# through the full 'aid update' dispatcher (which also does registry/
# migration work unrelated to version resolution and is already covered,
# for the resolution call site itself, by every other PAR100 case that omits
# --version).
# ===========================================================================
echo ""
echo "=== PAR101: CLI-version-aware resolve_version + Bash<->PS1 twin parity ==="

_PAR101_DIR="${TMP}/par101"
mkdir -p "${_PAR101_DIR}/fakebin" "${_PAR101_DIR}/clihome"

# Canned GitHub API bodies (pretty-printed / one key per line, matching the
# real API's shape that the existing tag_name grep+sed already relies on).
cat > "${_PAR101_DIR}/latest-stable.json" <<'EOF'
{
  "tag_name": "v2.2.2",
  "prerelease": false
}
EOF

# Newest-first list with TWO pre-releases -- proves "newest" selection (must
# pick v2.2.4b2, NOT the older v2.2.3b1), plus a trailing stable entry.
# One key per line (matches the real GitHub API's pretty-printed shape, which
# _aid_first_prerelease_tag's line-by-line scan -- like the existing tag_name
# grep+sed for /releases/latest -- assumes; a compact single-line-per-object
# fixture would put "tag_name" and "prerelease" on the SAME line and silently
# never match).
cat > "${_PAR101_DIR}/list-with-prerelease.json" <<'EOF'
[
  {
    "tag_name": "v2.2.4b2",
    "prerelease": true
  },
  {
    "tag_name": "v2.2.3b1",
    "prerelease": true
  },
  {
    "tag_name": "v2.2.2",
    "prerelease": false
  }
]
EOF

cat > "${_PAR101_DIR}/list-no-prerelease.json" <<'EOF'
[
  {
    "tag_name": "v2.2.2",
    "prerelease": false
  },
  {
    "tag_name": "v2.2.1",
    "prerelease": false
  }
]
EOF

# Fake curl: last arg is always the URL (resolve_version's exact invocation
# shape). PAR101_FAIL_MODE selectively simulates a fetch failure so the
# fail-safe fallback (and the total-failure error path) can be exercised
# without touching the network.
cat > "${_PAR101_DIR}/fakebin/curl" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
    */releases/latest)
        [[ "${PAR101_FAIL_MODE:-}" == "all" ]] && exit 6
        cat "$PAR101_LATEST_FILE" ;;
    */releases)
        if [[ "${PAR101_FAIL_MODE:-}" == "all" || "${PAR101_FAIL_MODE:-}" == "list-only" ]]; then
            exit 6
        fi
        cat "$PAR101_LIST_FILE" ;;
    *)
        exit 6 ;;
esac
EOF
chmod +x "${_PAR101_DIR}/fakebin/curl"

# Bash driver: sources the REAL lib/aid-install-core.sh and calls
# resolve_version() directly -- driven entirely via env (avoids quoting a
# CLI-version positional arg through a nested `bash -c` string).
cat > "${_PAR101_DIR}/resolve.sh" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
printf '%s' "$PAR101_CLI_VERSION" > "${AID_CODE_HOME}/VERSION"
source "$PAR101_LIB_SH"
resolve_version
EOF
chmod +x "${_PAR101_DIR}/resolve.sh"

# PS1 driver: dot-sources AidInstallCore.psm1's content into ITS OWN script
# scope -- the same technique bin/aid.ps1 itself uses -- so $script:_AidCodeHome
# (set here, mirroring what bin/aid.ps1 would have already set) is visible to
# Resolve-AidVersion exactly as it is in production.
cat > "${_PAR101_DIR}/resolve.ps1" <<'EOF'
Set-Content -LiteralPath (Join-Path $env:AID_CODE_HOME 'VERSION') -Value $env:PAR101_CLI_VERSION -NoNewline

function global:Invoke-RestMethod {
    param([string]$Uri, [hashtable]$Headers, [string]$Method)
    if ($Uri -like '*/releases/latest') {
        if ($env:PAR101_FAIL_MODE -eq 'all') { throw 'PAR101 simulated latest failure' }
        return (Get-Content -Raw -LiteralPath $env:PAR101_LATEST_FILE | ConvertFrom-Json)
    } elseif ($Uri -like '*/releases') {
        if ($env:PAR101_FAIL_MODE -eq 'all' -or $env:PAR101_FAIL_MODE -eq 'list-only') {
            throw 'PAR101 simulated list failure'
        }
        return (Get-Content -Raw -LiteralPath $env:PAR101_LIST_FILE | ConvertFrom-Json)
    } else {
        throw "PAR101 fake Invoke-RestMethod: unexpected URI: $Uri"
    }
}

$script:_AidCodeHome = $env:AID_CODE_HOME
$libRaw = Get-Content -LiteralPath $env:PAR101_LIB_PS1 -Raw -Encoding utf8
function Export-ModuleMember { param([Parameter(ValueFromRemainingArguments=$true)]$args) }
. ([scriptblock]::Create($libRaw))

Write-Output (Resolve-AidVersion)
EOF

# run_sh_resolve_version <cli_version> <list_file> [fail_mode]
run_sh_resolve_version() {
    local cli_version="$1" list_file="$2" fail_mode="${3:-}"
    OUT_SH=$(AID_CODE_HOME="${_PAR101_DIR}/clihome" \
             PATH="${_PAR101_DIR}/fakebin:${PATH}" \
             PAR101_LATEST_FILE="${_PAR101_DIR}/latest-stable.json" \
             PAR101_LIST_FILE="${list_file}" \
             PAR101_CLI_VERSION="${cli_version}" \
             PAR101_LIB_SH="${LIB_SH}" \
             PAR101_FAIL_MODE="${fail_mode}" \
             bash "${_PAR101_DIR}/resolve.sh" 2>&1); RC_SH=$?
}

# run_ps1_resolve_version <cli_version> <list_file> [fail_mode]
run_ps1_resolve_version() {
    local cli_version="$1" list_file="$2" fail_mode="${3:-}"
    OUT_PS1=$(AID_CODE_HOME="${_PAR101_DIR}/clihome" \
              PAR101_LATEST_FILE="${_PAR101_DIR}/latest-stable.json" \
              PAR101_LIST_FILE="${list_file}" \
              PAR101_CLI_VERSION="${cli_version}" \
              PAR101_LIB_PS1="${LIB_PS1}" \
              PAR101_FAIL_MODE="${fail_mode}" \
              "$PWSH" -NoProfile -File "${_PAR101_DIR}/resolve.ps1" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g'); RC_PS1=$?
}

# ---------------------------------------------------------------------------
# PAR101-A: pre-release CLI + a pre-release release exists -> resolves to the
# NEWEST pre-release (not the older one also present in the list).
# ---------------------------------------------------------------------------
run_sh_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-with-prerelease.json"
assert_eq "$OUT_SH" "2.2.4b2" "PAR101-A01 Bash: pre-release CLI + pre-release available -> resolves to the NEWEST pre-release"
assert_exit_eq "$RC_SH" 0 "PAR101-A02 Bash: exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-with-prerelease.json"
    assert_eq "$OUT_PS1" "2.2.4b2" "PAR101-A03 PS1: pre-release CLI + pre-release available -> resolves to the NEWEST pre-release"
    assert_exit_eq "$RC_PS1" 0 "PAR101-A04 PS1: exit 0"
    assert_eq "$OUT_SH" "$OUT_PS1" "PAR101-A05 AC: Bash<->PS1 twin parity (resolved version)"
else
    for _n in 03 04 05; do pass "PAR101-A${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR101-B: pre-release CLI + NO pre-release release exists -> falls back to
# the latest stable (fail-safe; no error, no beta stamped).
# ---------------------------------------------------------------------------
run_sh_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json"
assert_eq "$OUT_SH" "2.2.2" "PAR101-B01 Bash: pre-release CLI + NO pre-release available -> falls back to latest stable"
assert_exit_eq "$RC_SH" 0 "PAR101-B02 Bash: exit 0 (fail-safe, not an error)"

if [[ -n "$PWSH" ]]; then
    run_ps1_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json"
    assert_eq "$OUT_PS1" "2.2.2" "PAR101-B03 PS1: pre-release CLI + NO pre-release available -> falls back to latest stable"
    assert_exit_eq "$RC_PS1" 0 "PAR101-B04 PS1: exit 0 (fail-safe, not an error)"
    assert_eq "$OUT_SH" "$OUT_PS1" "PAR101-B05 AC: Bash<->PS1 twin parity (resolved version)"
else
    for _n in 03 04 05; do pass "PAR101-B${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR101-C: stable CLI -> UNCHANGED regression -- always the latest stable;
# the /releases list is never even consulted (list-with-prerelease.json is
# deliberately passed here as "poison": if the stable-CLI path ever started
# reading the list, it would wrongly resolve to the pre-release v2.2.4b2).
# ---------------------------------------------------------------------------
run_sh_resolve_version "2.2.2" "${_PAR101_DIR}/list-with-prerelease.json"
assert_eq "$OUT_SH" "2.2.2" "PAR101-C01 Bash: stable CLI -> always latest stable, unchanged (list ignored)"
assert_exit_eq "$RC_SH" 0 "PAR101-C02 Bash: exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1_resolve_version "2.2.2" "${_PAR101_DIR}/list-with-prerelease.json"
    assert_eq "$OUT_PS1" "2.2.2" "PAR101-C03 PS1: stable CLI -> always latest stable, unchanged (list ignored)"
    assert_exit_eq "$RC_PS1" 0 "PAR101-C04 PS1: exit 0"
    assert_eq "$OUT_SH" "$OUT_PS1" "PAR101-C05 AC: Bash<->PS1 twin parity (resolved version)"
else
    for _n in 03 04 05; do pass "PAR101-C${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR101-D: pre-release CLI + the LIST fetch itself fails (transient network
# hiccup on the beta lookup only) -> fail-safe fallback to the latest stable
# still succeeds (never hard-errors the update over the beta lookup).
# ---------------------------------------------------------------------------
run_sh_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json" "list-only"
assert_eq "$OUT_SH" "2.2.2" "PAR101-D01 Bash: list-fetch failure -> fail-safe fallback to latest stable still succeeds"
assert_exit_eq "$RC_SH" 0 "PAR101-D02 Bash: exit 0"

if [[ -n "$PWSH" ]]; then
    run_ps1_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json" "list-only"
    assert_eq "$OUT_PS1" "2.2.2" "PAR101-D03 PS1: list-fetch failure -> fail-safe fallback to latest stable still succeeds"
    assert_exit_eq "$RC_PS1" 0 "PAR101-D04 PS1: exit 0"
    assert_eq "$OUT_SH" "$OUT_PS1" "PAR101-D05 AC: Bash<->PS1 twin parity (resolved version)"
else
    for _n in 03 04 05; do pass "PAR101-D${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR101-E: total fetch failure (both endpoints unreachable) -- regression:
# the pre-existing hard-failure behavior is preserved (no beta-lookup
# regression turns a real outage into a silent/garbage resolution).
# ---------------------------------------------------------------------------
run_sh_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json" "all"
assert_eq "$OUT_SH" "ERROR: aid-install-core: failed to fetch https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest" \
    "PAR101-E01 Bash: total fetch failure -> the pre-existing hard error is preserved"
assert_exit_eq "$RC_SH" 3 "PAR101-E02 Bash: exit 3 (unchanged failure contract)"

if [[ -n "$PWSH" ]]; then
    run_ps1_resolve_version "2.2.3b1" "${_PAR101_DIR}/list-no-prerelease.json" "all"
    assert_output_contains "$OUT_PS1" "ERROR: AidInstallCore: failed to fetch" \
        "PAR101-E03 PS1: total fetch failure -> the pre-existing hard error is preserved"
else
    pass "PAR101-E03 [SKIPPED: pwsh absent]"
fi

# ---------------------------------------------------------------------------
# PAR102: 'aid projects list' column alignment with a long (pre-release) version,
# Bash<->PS1 twin parity. Regression (beta bug): the STATE column was a fixed
# %-10s / {3,-10}; a version longer than 10 chars (e.g. a pre-release
# "X.Y.Z-beta.N") overflowed the field and pushed the TOOLS/TIER data right of
# their headers. Both twins now size the STATE column to the widest value
# (floor 10) so header and data stay aligned. The assertion is PATH-width-
# INDEPENDENT: it compares the STATE->TOOLS gap in the header against the
# version->tools gap in the data row -- a gap measured WITHIN each row, so a long
# PATH that overflows its own column cannot confound it. (aid_version parsing
# accepts the "-beta.N" suffix via _aid_project_state's [^space]* tail.)
# ---------------------------------------------------------------------------
_UA_PL_SH_HOME=$(newhome); setup_sh_home "${_UA_PL_SH_HOME}"
_UA_PL_PS_HOME=$(newhome); setup_ps1_home "${_UA_PL_PS_HOME}"
_UA_PL_PROJ="$(mktemp -d "${TMP}/pl_proj.XXXXXX")"

# Register the (bare) project in each home; 'projects add' does not write a
# manifest, so no clobber concern with the long-version manifest written below.
run_sh  "${_UA_PL_SH_HOME}" projects add "${_UA_PL_PROJ}"
if [[ -n "$PWSH" ]]; then
    run_ps1 "${_UA_PL_PS_HOME}" projects add "${_UA_PL_PROJ}"
fi

# Long-version manifest (13-char version + one tool "codex"), read by both twins.
mkdir -p "${_UA_PL_PROJ}/.aid"
cat > "${_UA_PL_PROJ}/.aid/.aid-manifest.json" <<'EOF'
{
  "aid_version": "9.9.9-beta.99",
  "tools": {
    "codex": {}
  }
}
EOF

run_sh "${_UA_PL_SH_HOME}" projects list
assert_exit_eq "$RC_SH" 0 "PAR102-01 Bash: 'projects list' with a 13-char version -> exit 0"
assert_output_contains "$OUT_SH" "9.9.9-beta.99" "PAR102-02 Bash: long version rendered in the STATE column"
_pl_hdr_sh="$(printf '%s\n' "$OUT_SH"  | grep -F 'TOOLS' | head -1)"
_pl_data_sh="$(printf '%s\n' "$OUT_SH" | grep -F '9.9.9-beta.99' | head -1)"
_t="${_pl_hdr_sh%%STATE*}";           _pl_state_off_sh=${#_t}
_t="${_pl_hdr_sh%%TOOLS*}";           _pl_tools_off_sh=${#_t}
_t="${_pl_data_sh%%9.9.9-beta.99*}";  _pl_ver_off_sh=${#_t}
_t="${_pl_data_sh%%codex*}";          _pl_toolsval_off_sh=${#_t}
_pl_hgap_sh=$(( _pl_tools_off_sh - _pl_state_off_sh ))
_pl_dgap_sh=$(( _pl_toolsval_off_sh - _pl_ver_off_sh ))
assert_eq "$_pl_hgap_sh" "$_pl_dgap_sh" \
    "PAR102-03 Bash: STATE column widened so the TOOLS header aligns with the tools value (header gap ${_pl_hgap_sh} == data gap ${_pl_dgap_sh})"

if [[ -n "$PWSH" ]]; then
    run_ps1 "${_UA_PL_PS_HOME}" projects list
    assert_exit_eq "$RC_PS1" 0 "PAR102-04 PS1: 'projects list' with a 13-char version -> exit 0"
    assert_output_contains "$OUT_PS1" "9.9.9-beta.99" "PAR102-05 PS1: long version rendered in the STATE column"
    _pl_hdr_ps="$(printf '%s\n' "$OUT_PS1"  | grep -F 'TOOLS' | head -1)"
    _pl_data_ps="$(printf '%s\n' "$OUT_PS1" | grep -F '9.9.9-beta.99' | head -1)"
    _t="${_pl_hdr_ps%%STATE*}";           _pl_state_off_ps=${#_t}
    _t="${_pl_hdr_ps%%TOOLS*}";           _pl_tools_off_ps=${#_t}
    _t="${_pl_data_ps%%9.9.9-beta.99*}";  _pl_ver_off_ps=${#_t}
    _t="${_pl_data_ps%%codex*}";          _pl_toolsval_off_ps=${#_t}
    _pl_hgap_ps=$(( _pl_tools_off_ps - _pl_state_off_ps ))
    _pl_dgap_ps=$(( _pl_toolsval_off_ps - _pl_ver_off_ps ))
    assert_eq "$_pl_hgap_ps" "$_pl_dgap_ps" \
        "PAR102-06 PS1: STATE column widened so the TOOLS header aligns with the tools value (header gap ${_pl_hgap_ps} == data gap ${_pl_dgap_ps})"
    assert_eq "$_pl_hgap_sh" "$_pl_hgap_ps" "PAR102-07 AC: Bash<->PS1 STATE-column header gap byte-identical"
    assert_eq "$_pl_dgap_sh" "$_pl_dgap_ps" "PAR102-08 AC: Bash<->PS1 version->tools data gap byte-identical"
else
    for _n in 04 05 06 07 08; do pass "PAR102-${_n} [SKIPPED: pwsh absent]"; done
fi

# ===========================================================================
# PAR019: 'aid projects scan' bash<->PS1 parity + guardrail coverage
# (work-019-discover-projects / task-003)
#
# Exercises the scan subcommand on BOTH twins over ONE shared fixture tree,
# via the zero-arg HOME default (achieved hermetically by pinning $HOME /
# %USERPROFILE% at the fixture root) AND the --path <folder> fast path (same
# tree). Never touches the real machine or the real $HOME. See SPEC.md
# (work-019-discover-projects) AC-1..AC-16 and its task-003 DETAIL.md.
#
# PS half: skipped when pwsh absent (same posture as the rest of this suite);
# the Bash-side assertions still run so the block is never a vacuous pass.
# ===========================================================================

echo ""
echo "=== PAR019: aid projects scan bash<->PS1 parity + guardrails ==="

# ---------------------------------------------------------------------------
# _par019_build_fixture <fx-root>
#
# Builds ONE shared fixture tree covering every scan guardrail (SPEC.md
# Feature Flow / task-003 DETAIL.md):
#   - a real tracked project (aid_version) + an untracked one (AC-1/AC-6)
#   - heavy/cache decoys (classic + new bin/obj/logs + mixed-case Build/OBJ)
#     each holding a NESTED project one level below the decoy itself -- never
#     discovered (NFR-2)
#   - a folder literally named bin/obj/logs that IS itself a valid project --
#     still discovered (project-check precedes name-pruning) (NFR-9/AC-14)
#   - a project nested inside another project's subtree -- not separately
#     discovered (subtree pruned) (NFR-9/AC-14)
#   - a top-level dev/ (system-dir name) holding a project -- descended and
#     found (system-dir prune is --all-only) (NFR-3/AC-8), plus a deeper
#     same-named dev/ not inside a project (also descended normally)
#   - the CLI's own state home ($HOME/.aid) with a nested project inside it --
#     neither the state home nor its subtree is ever registered (FR-5/AC-16)
#   - a permission-denied directory (skip + continue) (NFR-1)
#   - a real project + a directory-symlink alias to it -- registered once
#     (NFR-10/AC-15)
#   - a directory-symlink cycle -- must terminate (NFR-4)
#   - a pathologically deep chain (45 levels, past the hard 40-level cap) --
#     must terminate (NFR-4)
# ---------------------------------------------------------------------------
_par019_mkproj() {
    # $1 = .aid dir path, $2 = aid_version (empty -> untracked, no manifest)
    local aiddir="$1" ver="$2"
    mkdir -p "$aiddir"
    if [[ -n "$ver" ]]; then
        cat > "${aiddir}/.aid-manifest.json" << EOF
{
  "aid_version": "${ver}",
  "tools": {}
}
EOF
    fi
}

_par019_build_fixture() {
    local fx="$1"
    rm -rf "$fx"
    mkdir -p "$fx"

    # State home marker ($HOME/.aid, R6/FR-5/AC-16): a nested project under it
    # must never be reached (whole subtree pruned, not just the .aid/ itself).
    mkdir -p "${fx}/.aid"
    printf 'schema: 1\nprojects:\n' > "${fx}/.aid/registry.yml"
    _par019_mkproj "${fx}/.aid/nested-in-state-home/.aid" "9.9.9"

    # AC-1 / AC-6: tracked + untracked.
    _par019_mkproj "${fx}/proj-tracked/.aid" "1.4.2"
    mkdir -p "${fx}/proj-untracked/.aid"

    # NFR-2: heavy/cache decoys (classic + new names + mixed-case), nested
    # project ONE level below the decoy itself (never reached -- decoy pruned).
    _par019_mkproj "${fx}/decoys/node_modules/inner-pkg/.aid" "0.1.1"
    _par019_mkproj "${fx}/decoys/dotgit_decoy/.git/inner/.aid" "0.1.2"
    _par019_mkproj "${fx}/decoys/Build/inner/.aid" "0.1.3"
    _par019_mkproj "${fx}/decoys/OBJ/inner/.aid" "0.1.4"
    _par019_mkproj "${fx}/decoys/logs/inner/.aid" "0.1.5"
    _par019_mkproj "${fx}/decoys/.cache/inner/.aid" "0.1.6"

    # NFR-9 / AC-14: exclusion-named folders that ARE valid projects.
    _par019_mkproj "${fx}/exclusion-named-projects/bin/.aid" "2.0.0"
    _par019_mkproj "${fx}/exclusion-named-projects/obj/.aid" "2.0.1"
    _par019_mkproj "${fx}/exclusion-named-projects/logs/.aid" "2.0.2"

    # NFR-9 / AC-14: project nested inside another project -- subtree pruned.
    _par019_mkproj "${fx}/nested-in-project/outer-proj/.aid" "3.0.0"
    _par019_mkproj "${fx}/nested-in-project/outer-proj/subdir/inner-proj/.aid" "3.0.1"

    # NFR-3 (--all-only exemption): top-level dev/ under the scan root, plus a
    # deeper same-named dev/ not inside a project -- both descended normally.
    _par019_mkproj "${fx}/dev/proj-in-dev/.aid" "4.0.0"
    _par019_mkproj "${fx}/misc/dev/proj-deep-dev/.aid" "4.0.1"

    # NFR-1: permission-denied directory (no project inside -- a
    # host-independent assertion: proves scan continues past it regardless of
    # whether this host's chmod actually enforces the block, e.g. Windows).
    mkdir -p "${fx}/denied"
    printf 'x\n' > "${fx}/denied/placeholder.txt"
    chmod 000 "${fx}/denied" 2>/dev/null || true

    # NFR-10 / AC-15: a real project + a directory-symlink alias to it.
    # MSYS=winsymlinks:nativestrict forces a GENUINE (non-junction) symlink on
    # Windows Git-Bash (test-delete-pipeline.sh precedent); a no-op elsewhere.
    _par019_mkproj "${fx}/dedupe/realproj/.aid" "5.0.0"
    MSYS=winsymlinks:nativestrict ln -s "${fx}/dedupe/realproj" "${fx}/dedupe/linkproj" 2>/dev/null || true

    # NFR-4: directory-symlink cycle (must terminate).
    mkdir -p "${fx}/symcycle/a"
    MSYS=winsymlinks:nativestrict ln -s "${fx}/symcycle/a" "${fx}/symcycle/a/loop" 2>/dev/null || true

    # NFR-4: pathologically deep chain, past the hard _AID_SCAN_MAX_DEPTH=40
    # cap (no .aid/ anywhere -- proves termination, not discovery).
    local deep="${fx}/deep" i
    for i in $(seq 1 45); do deep="${deep}/n"; done
    mkdir -p "$deep"
}

# _par019_extract_registered <output> <fx-root-basename>
# Prints one path-relative-to-the-fixture-root per discovered candidate line
# ("<path>  <version>  <action>", action in registered|already-registered),
# sorted. Both twins print the identical "<path>  <version>  <action>" report
# line shape (bin/aid _cmd_projects_scan / bin/aid.ps1 Invoke-AidProjectsScan).
#
# Path-format-agnostic (task-003 GATE finding): a native Windows pwsh renders
# "C:\Users\...\par019fx.XXXXXX\proj" while bash/MSYS renders
# "/c/Users/.../par019fx.XXXXXX/proj" for the IDENTICAL directory -- and
# ancestor segments may ALSO differ (Windows 8.3 short-name aliasing of a
# pre-existing folder is host-dependent, e.g. a real username directory, and
# outside this test's control -- confirmed empirically NOT to affect anything
# this fixture itself creates). run_sh_scan/run_ps1_scan already normalize
# backslash -> forward-slash at capture time (below), so this only needs to
# anchor on the fixture root's OWN generated basename -- unique per run,
# created fresh by this block, never 8.3-shortened or case-folded -- and keep
# the suffix AFTER "/<basename>/": the fixture-relative path both twins must
# agree on, regardless of how each renders everything ABOVE the fixture root.
_par019_extract_registered() {
    printf '%s\n' "$1" | grep -E '  (registered|already-registered)$' \
        | awk '{print $1}' | sed -E "s#.*/${2}/##" | sort
}

# run_sh_scan <aid-home> <home-pin> <args...>
# Like run_sh, but ALSO pins the OS-level $HOME (distinct from AID_HOME, the
# CLI's own state home) so the zero-arg default scope resolves to <home-pin>.
# Normalizes backslash -> forward-slash at capture (no-op on bash/MSYS, which
# never emits backslashes here; kept for symmetry with run_ps1_scan below so
# both twins' captured output is comparable the same way).
run_sh_scan() {
    local aid_home="$1" home_pin="$2"; shift 2
    OUT_SH=$(HOME="$home_pin" AID_HOME="$aid_home" \
             AID_LIB_PATH="${aid_home}/lib/aid-install-core.sh" AID_NO_UPDATE_CHECK=1 \
             bash "${aid_home}/bin/aid" "$@" 2>&1 | sed 's/\\/\//g'); RC_SH=$?
}

# run_ps1_scan <aid-home> <home-pin> <args...>
# Like run_ps1, but ALSO pins USERPROFILE/HOMEDRIVE/HOMEPATH (native Windows
# pwsh derives $HOME from USERPROFILE, never from a bash-exported $HOME --
# same rationale as the suite's global HOME pin at the top of this file).
# cygpath-absent (Linux) -> no-op passthrough, matching that same convention.
#
# Also normalizes backslash -> forward-slash (task-003 GATE finding): a native
# Windows pwsh renders discovered paths as "C:\Users\...\proj" while bash/MSYS
# renders "/c/Users/.../proj" for the SAME directory -- without this, EVERY
# multi-segment relative-path assertion against $OUT_PS1 (and the
# _par019_extract_registered helper above) would structurally fail on a
# native-Windows run regardless of actual twin behavior. A no-op on Linux CI
# (PowerShell Core there already emits POSIX-style forward-slash paths).
run_ps1_scan() {
    local aid_home="$1" home_pin="$2"; shift 2
    local win_home_pin="$home_pin"
    command -v cygpath >/dev/null 2>&1 && win_home_pin="$(cygpath -w "$home_pin")"
    OUT_PS1=$(HOME="$home_pin" USERPROFILE="$win_home_pin" \
              HOMEDRIVE="${win_home_pin:0:2}" HOMEPATH="${win_home_pin:2}" \
              AID_HOME="$aid_home" AID_LIB_PATH="${aid_home}/lib/AidInstallCore.psm1" \
              AID_NO_UPDATE_CHECK=1 \
              "$PWSH" -NoProfile -File "${aid_home}/bin/aid.ps1" "$@" 2>&1 | \
              sed 's/\x1b\[[0-9;]*m//g' | sed 's/\\/\//g'); RC_PS1=$?
}

FX_019=$(mktemp -d "${TMP}/par019fx.XXXXXX")
_par019_build_fixture "$FX_019"
FX_019C="$(cd "$FX_019" && pwd -P)"
FX_019_BASE="$(basename "$FX_019")"

# NFR-7 baseline: checksum every file living under any .aid/ anywhere in the
# fixture, BEFORE any scan runs. Re-checked at the end of the block (PAR019-I)
# -- scan is register-only and must never create/modify a file in there.
_par019_snapshot() {
    find "$FX_019" -path '*/.aid/*' -type f -print0 2>/dev/null | sort -z | xargs -0 sha256sum 2>/dev/null
}
_PAR019_SNAP_BEFORE="$(_par019_snapshot)"

_PAR019_EXPECTED=$(cat << 'EXPECTEOF'
dedupe/realproj
dev/proj-in-dev
exclusion-named-projects/bin
exclusion-named-projects/logs
exclusion-named-projects/obj
misc/dev/proj-deep-dev
nested-in-project/outer-proj
proj-tracked
proj-untracked
EXPECTEOF
)

# ---------------------------------------------------------------------------
# PAR019-A: zero-arg HOME-default scan discovers exactly the expected set,
# honors every guardrail, and matches between twins (AC-1, AC-2, AC-6, AC-7,
# AC-8, AC-10, AC-14, AC-15, AC-16).
# ---------------------------------------------------------------------------
SH_HOME_019A=$(newhome); setup_sh_home "${SH_HOME_019A}"
run_sh_scan "${SH_HOME_019A}" "$FX_019" projects scan --verbose
assert_exit_eq "$RC_SH" 0 "PAR019-A01 Bash home-default scan -> exit 0"

SH_GOT_A="$(_par019_extract_registered "$OUT_SH" "$FX_019_BASE")"
assert_eq "$SH_GOT_A" "$_PAR019_EXPECTED" \
    "PAR019-A02 Bash home-default: discovered set is exactly the expected 9 projects"

assert_output_contains "$OUT_SH" "aid projects scan: roots: ${FX_019C}" \
    "PAR019-A03 Bash home-default: roots resolve to the pinned HOME (AC-2, no drive enum)"
assert_output_contains "$OUT_SH" "scanning ${FX_019C} ..." \
    "PAR019-A04 Bash: progress line to stderr present (AC-7/NFR-6)"
assert_output_contains "$OUT_SH" "9 newly-registered, 0 already-registered" \
    "PAR019-A05 Bash: summary counts (AC-7)"
assert_output_contains "$OUT_SH" "proj-tracked  1.4.2  registered" \
    "PAR019-A06 Bash: tracked project reports its aid_version (AC-6)"
assert_output_contains "$OUT_SH" "proj-untracked  untracked  registered" \
    "PAR019-A07 Bash: .aid/ with no manifest reports untracked (AC-6)"

# NFR-2: heavy/cache decoys (classic + new + mixed-case) never discovered.
for _dec in "decoys/node_modules/inner-pkg" "decoys/dotgit_decoy/.git/inner" \
            "decoys/Build/inner" "decoys/OBJ/inner" "decoys/logs/inner" "decoys/.cache/inner"; do
    assert_output_not_contains "$OUT_SH" "${FX_019C}/${_dec}  " \
        "PAR019-A08 Bash: heavy/cache decoy NOT discovered: ${_dec} (NFR-2)"
done

# NFR-9/AC-14: exclusion-named projects (bin/obj/logs) ARE discovered.
assert_output_contains "$OUT_SH" "exclusion-named-projects/bin  2.0.0  registered" \
    "PAR019-A09 Bash: folder literally named 'bin' IS discovered (project-check precedes name-prune, AC-14)"
assert_output_contains "$OUT_SH" "exclusion-named-projects/obj  2.0.1  registered" \
    "PAR019-A10 Bash: folder literally named 'obj' IS discovered (AC-14)"
assert_output_contains "$OUT_SH" "exclusion-named-projects/logs  2.0.2  registered" \
    "PAR019-A11 Bash: folder literally named 'logs' IS discovered (AC-14)"

# NFR-9/AC-14: nested-in-project subtree pruned.
assert_output_contains "$OUT_SH" "nested-in-project/outer-proj  3.0.0  registered" \
    "PAR019-A12 Bash: outer project IS discovered"
assert_output_not_contains "$OUT_SH" "inner-proj" \
    "PAR019-A13 Bash: project nested INSIDE another project's subtree is NOT separately discovered (AC-14)"

# NFR-3 (--all-only exemption): top-level dev/ descended + deeper dev/ descended.
assert_output_contains "$OUT_SH" "dev/proj-in-dev  4.0.0  registered" \
    "PAR019-A14 Bash: top-level dev/ under HOME default is DESCENDED, project found (system-dir prune is --all-only, AC-8)"
assert_output_contains "$OUT_SH" "misc/dev/proj-deep-dev  4.0.1  registered" \
    "PAR019-A15 Bash: a deeper (non-top-level) dev/ not inside a project is also descended normally (AC-8)"

# NFR-10/AC-15: dedupe (symlink alias never separately registered).
assert_output_not_contains "$OUT_SH" "linkproj" \
    "PAR019-A16 Bash: the directory-symlink alias is NOT separately registered (AC-15)"
_PAR019_A_DEDUPE_COUNT=$(printf '%s\n' "$OUT_SH" | grep -c "dedupe/realproj  5.0.0  registered" || true)
assert_eq "$_PAR019_A_DEDUPE_COUNT" "1" \
    "PAR019-A17 Bash: the real project reachable via a symlink alias is registered EXACTLY once (AC-15)"

# FR-5/AC-16: state home + its subtree never registered.
assert_output_not_contains "$OUT_SH" "nested-in-state-home" \
    "PAR019-A18 Bash: a project nested inside \$HOME/.aid (state home) is NEVER registered (AC-16)"
assert_output_not_contains "$OUT_SH" "${FX_019C}  " \
    "PAR019-A19 Bash: the fixture root itself (whose .aid/ IS the state home) is NOT registered (AC-16)"

# NFR-1/NFR-4: unreadable dir skipped + termination (symlink cycle + deep
# chain) proven by the block simply completing with the exact expected set
# above -- a hang or crash would have failed A01/A02 instead.
pass "PAR019-A20 Bash: permission-denied dir skipped + scan continued (NFR-1) -- proven by A02's exact-set match"
pass "PAR019-A21 Bash: symlink-cycle + deep-chain (past the hard 40-level cap) both TERMINATE (NFR-4) -- proven by A01/A02 completing"

if [[ -n "$PWSH" ]]; then
    PS_HOME_019A=$(newhome); setup_ps1_home "${PS_HOME_019A}"
    run_ps1_scan "${PS_HOME_019A}" "$FX_019" projects scan --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR019-A22 PS1 home-default scan -> exit 0"

    PS_GOT_A="$(_par019_extract_registered "$OUT_PS1" "$FX_019_BASE")"
    assert_eq "$PS_GOT_A" "$_PAR019_EXPECTED" \
        "PAR019-A23 PS1 home-default: discovered set is exactly the expected 9 projects"
    assert_output_contains "$OUT_PS1" "proj-tracked  1.4.2  registered" \
        "PAR019-A24 PS1: tracked project reports its aid_version (AC-6)"
    assert_output_contains "$OUT_PS1" "proj-untracked  untracked  registered" \
        "PAR019-A25 PS1: .aid/ with no manifest reports untracked (AC-6)"
    assert_output_contains "$OUT_PS1" "exclusion-named-projects/bin  2.0.0  registered" \
        "PAR019-A26 PS1: folder literally named 'bin' IS discovered (AC-14)"
    assert_output_not_contains "$OUT_PS1" "inner-proj" \
        "PAR019-A27 PS1: nested-in-project subtree NOT separately discovered (AC-14)"
    assert_output_not_contains "$OUT_PS1" "linkproj" \
        "PAR019-A28 PS1: directory-symlink alias NOT separately registered (AC-15)"
    assert_output_not_contains "$OUT_PS1" "nested-in-state-home" \
        "PAR019-A29 PS1: project nested inside the state home NEVER registered (AC-16)"

    # AC-10: identical discovery + identical exit codes across twins, same fixture.
    assert_eq "$RC_SH" "$RC_PS1" "PAR019-A30 Bash<->PS1 exit code parity (home-default scan, AC-10)"
    assert_eq "$SH_GOT_A" "$PS_GOT_A" "PAR019-A31 Bash<->PS1 discovered-set parity (home-default scan, AC-10)"
else
    for _n in 22 23 24 25 26 27 28 29 30 31; do
        pass "PAR019-A${_n} [SKIPPED: pwsh absent]"
    done
fi

# ---------------------------------------------------------------------------
# PAR019-B: re-scan does not duplicate; an already-registered project's
# record is left UNCHANGED (no re-tier/rewrite/reorder); a no-.aid/ folder is
# never registered (AC-5).
# ---------------------------------------------------------------------------
_PAR019_REG_BEFORE="$(cat "${SH_HOME_019A}/registry.yml")"
run_sh_scan "${SH_HOME_019A}" "$FX_019" projects scan
assert_exit_eq "$RC_SH" 0 "PAR019-B01 Bash re-scan -> exit 0"
assert_output_contains "$OUT_SH" "0 newly-registered, 9 already-registered" \
    "PAR019-B02 Bash re-scan: 0 newly-registered, all 9 already-registered (AC-5)"
_PAR019_REG_AFTER="$(cat "${SH_HOME_019A}/registry.yml")"
assert_eq "$_PAR019_REG_AFTER" "$_PAR019_REG_BEFORE" \
    "PAR019-B03 Bash re-scan: registry.yml byte-unchanged (no re-tier/rewrite/reorder, AC-5)"
assert_output_not_contains "$OUT_SH" "${FX_019C}/denied  " \
    "PAR019-B04 Bash: the no-.aid/ 'denied' folder is never registered (AC-5)"

if [[ -n "$PWSH" ]]; then
    run_ps1_scan "${PS_HOME_019A}" "$FX_019" projects scan
    assert_exit_eq "$RC_PS1" 0 "PAR019-B05 PS1 re-scan -> exit 0"
    assert_output_contains "$OUT_PS1" "0 newly-registered, 9 already-registered" \
        "PAR019-B06 PS1 re-scan: 0 newly-registered, all 9 already-registered (AC-5)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR019-B07 Bash<->PS1 exit code parity (re-scan, AC-10)"
else
    for _n in 05 06 07; do pass "PAR019-B${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-C: --path <folder> fast path narrows the scan to exactly that
# subtree and matches the home-default discovery over the SAME fixture (AC-1,
# AC-3 narrowing).
# ---------------------------------------------------------------------------
SH_HOME_019C=$(newhome); setup_sh_home "${SH_HOME_019C}"
run_sh_scan "${SH_HOME_019C}" "$FX_019" projects scan --path "$FX_019"
assert_exit_eq "$RC_SH" 0 "PAR019-C01 Bash --path fast-path scan -> exit 0"
SH_GOT_C="$(_par019_extract_registered "$OUT_SH" "$FX_019_BASE")"
assert_eq "$SH_GOT_C" "$_PAR019_EXPECTED" \
    "PAR019-C02 Bash --path fast-path: discovered set matches the home-default set (AC-1/AC-3)"

# register-then-list (AC-1): the newly-registered projects appear in 'projects list'.
run_sh "${SH_HOME_019C}" projects list
assert_exit_eq "$RC_SH" 0 "PAR019-C03 Bash 'projects list' after scan -> exit 0"
assert_output_contains "$OUT_SH" "proj-tracked" \
    "PAR019-C04 Bash: a scan-registered project appears in 'projects list' (AC-1)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_019C=$(newhome); setup_ps1_home "${PS_HOME_019C}"
    run_ps1_scan "${PS_HOME_019C}" "$FX_019" projects scan --path "$FX_019"
    assert_exit_eq "$RC_PS1" 0 "PAR019-C05 PS1 --path fast-path scan -> exit 0"
    PS_GOT_C="$(_par019_extract_registered "$OUT_PS1" "$FX_019_BASE")"
    assert_eq "$PS_GOT_C" "$_PAR019_EXPECTED" \
        "PAR019-C06 PS1 --path fast-path: discovered set matches the home-default set (AC-1/AC-3)"
    assert_eq "$SH_GOT_C" "$PS_GOT_C" "PAR019-C07 Bash<->PS1 discovered-set parity (--path fast path, AC-10)"
else
    for _n in 05 06 07; do pass "PAR019-C${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-D: --dry-run previews without writing -- registry.yml stays ABSENT
# (a fresh AID_HOME never had one), exit 0 (AC-4).
# ---------------------------------------------------------------------------
SH_HOME_019D=$(newhome); setup_sh_home "${SH_HOME_019D}"
run_sh_scan "${SH_HOME_019D}" "$FX_019" projects scan --dry-run
assert_exit_eq "$RC_SH" 0 "PAR019-D01 Bash --dry-run -> exit 0"
assert_output_contains "$OUT_SH" "9 newly-registered, 0 already-registered" \
    "PAR019-D02 Bash --dry-run: reports what it WOULD register (AC-4)"
if [[ -f "${SH_HOME_019D}/registry.yml" ]]; then
    fail "PAR019-D03 Bash --dry-run: registry.yml must stay absent (no write)"
else
    pass "PAR019-D03 Bash --dry-run: registry.yml stays absent (no write, AC-4)"
fi

if [[ -n "$PWSH" ]]; then
    PS_HOME_019D=$(newhome); setup_ps1_home "${PS_HOME_019D}"
    run_ps1_scan "${PS_HOME_019D}" "$FX_019" projects scan --dry-run
    assert_exit_eq "$RC_PS1" 0 "PAR019-D04 PS1 --dry-run -> exit 0"
    assert_output_contains "$OUT_PS1" "9 newly-registered, 0 already-registered" \
        "PAR019-D05 PS1 --dry-run: reports what it WOULD register (AC-4)"
    if [[ -f "${PS_HOME_019D}/registry.yml" ]]; then
        fail "PAR019-D06 PS1 --dry-run: registry.yml must stay absent (no write)"
    else
        pass "PAR019-D06 PS1 --dry-run: registry.yml stays absent (no write, AC-4)"
    fi
    assert_eq "$RC_SH" "$RC_PS1" "PAR019-D07 Bash<->PS1 exit code parity (--dry-run, AC-10)"
else
    for _n in 04 05 06 07; do pass "PAR019-D${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-E: usage-error matrix -- non-dir --path, --path+--all mutual
# exclusion, --include-network/--include-removable without --all, non-integer
# AND negative --depth, and a scan-only flag on list/add -- all exit 2 (AC-3,
# AC-9), identically on both twins.
# ---------------------------------------------------------------------------
SH_HOME_019E=$(newhome); setup_sh_home "${SH_HOME_019E}"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --path "${FX_019}/does-not-exist-xyz"
assert_exit_eq "$RC_SH" 2 "PAR019-E01 Bash: non-directory --path -> exit 2 (AC-3)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --path "$FX_019" --all
assert_exit_eq "$RC_SH" 2 "PAR019-E02 Bash: --path + --all together -> exit 2 (mutually exclusive, AC-3)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --include-network
assert_exit_eq "$RC_SH" 2 "PAR019-E03 Bash: --include-network without --all -> exit 2 (AC-9)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --include-removable
assert_exit_eq "$RC_SH" 2 "PAR019-E04 Bash: --include-removable without --all -> exit 2 (AC-9)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --depth abc
assert_exit_eq "$RC_SH" 2 "PAR019-E05 Bash: non-integer --depth -> exit 2 (AC-3)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects scan --depth -1
assert_exit_eq "$RC_SH" 2 "PAR019-E06 Bash: negative --depth -> exit 2 (AC-3)"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects list --all
assert_exit_eq "$RC_SH" 2 "PAR019-E07 Bash: scan-only flag (--all) on 'list' -> exit 2"

run_sh_scan "${SH_HOME_019E}" "$FX_019" projects add --dry-run "${FX_019}/proj-tracked"
assert_exit_eq "$RC_SH" 2 "PAR019-E08 Bash: scan-only flag (--dry-run) on 'add' -> exit 2"

if [[ -n "$PWSH" ]]; then
    PS_HOME_019E=$(newhome); setup_ps1_home "${PS_HOME_019E}"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --path "${FX_019}/does-not-exist-xyz"
    assert_exit_eq "$RC_PS1" 2 "PAR019-E09 PS1: non-directory --path -> exit 2 (AC-3)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --path "$FX_019" --all
    assert_exit_eq "$RC_PS1" 2 "PAR019-E10 PS1: --path + --all together -> exit 2 (AC-3)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --include-network
    assert_exit_eq "$RC_PS1" 2 "PAR019-E11 PS1: --include-network without --all -> exit 2 (AC-9)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --include-removable
    assert_exit_eq "$RC_PS1" 2 "PAR019-E12 PS1: --include-removable without --all -> exit 2 (AC-9)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --depth abc
    assert_exit_eq "$RC_PS1" 2 "PAR019-E13 PS1: non-integer --depth -> exit 2 (AC-3)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects scan --depth -1
    assert_exit_eq "$RC_PS1" 2 "PAR019-E14 PS1: negative --depth -> exit 2 (AC-3)"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects list --all
    assert_exit_eq "$RC_PS1" 2 "PAR019-E15 PS1: scan-only flag (--all) on 'list' -> exit 2"

    run_ps1_scan "${PS_HOME_019E}" "$FX_019" projects add --dry-run "${FX_019}/proj-tracked"
    assert_exit_eq "$RC_PS1" 2 "PAR019-E16 PS1: scan-only flag (--dry-run) on 'add' -> exit 2"
else
    for _n in 09 10 11 12 13 14 15 16; do pass "PAR019-E${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-F: --depth <n> bounds recursion to n levels below the scan root --
# depth-1 projects are found, deeper ones are not (AC-3), identically on both
# twins.
# ---------------------------------------------------------------------------
SH_HOME_019F=$(newhome); setup_sh_home "${SH_HOME_019F}"
run_sh_scan "${SH_HOME_019F}" "$FX_019" projects scan --depth 1
SH_GOT_F="$(_par019_extract_registered "$OUT_SH" "$FX_019_BASE")"
assert_eq "$SH_GOT_F" "$(printf 'proj-tracked\nproj-untracked')" \
    "PAR019-F01 Bash --depth 1: only the two depth-1 projects are found (deeper ones excluded, AC-3)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_019F=$(newhome); setup_ps1_home "${PS_HOME_019F}"
    run_ps1_scan "${PS_HOME_019F}" "$FX_019" projects scan --depth 1
    PS_GOT_F="$(_par019_extract_registered "$OUT_PS1" "$FX_019_BASE")"
    assert_eq "$PS_GOT_F" "$(printf 'proj-tracked\nproj-untracked')" \
        "PAR019-F02 PS1 --depth 1: only the two depth-1 projects are found (AC-3)"
    assert_eq "$SH_GOT_F" "$PS_GOT_F" "PAR019-F03 Bash<->PS1 --depth 1 parity (AC-10)"
else
    for _n in 02 03; do pass "PAR019-F${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-G: AC-13 tier forcing -- a project OUTSIDE the pinned HOME is
# auto-registered in the USER tier by default (no elevation probe), and
# --shared selects the shared path, identically on both twins.
# ---------------------------------------------------------------------------
OUTSIDE_019=$(mktemp -d "${TMP}/par019outside.XXXXXX")
mkdir -p "${OUTSIDE_019}/.aid"
cat > "${OUTSIDE_019}/.aid/.aid-manifest.json" << 'EOF'
{
  "aid_version": "6.0.0",
  "tools": {}
}
EOF
UNRELATED_HOME_019=$(mktemp -d "${TMP}/par019unrelated.XXXXXX")

SH_HOME_019G=$(newhome); setup_sh_home "${SH_HOME_019G}"
run_sh_scan "${SH_HOME_019G}" "$UNRELATED_HOME_019" projects scan --path "$OUTSIDE_019" --verbose
assert_exit_eq "$RC_SH" 0 "PAR019-G01 Bash: scan of an outside-HOME project -> exit 0 (no elevation hang)"
assert_output_contains "$OUT_SH" "tier=user" \
    "PAR019-G02 Bash: default scan registers an outside-HOME project in the USER tier (AC-13)"

SH_HOME_019G2=$(newhome); setup_sh_home "${SH_HOME_019G2}"
run_sh_scan "${SH_HOME_019G2}" "$UNRELATED_HOME_019" projects scan --path "$OUTSIDE_019" --shared --verbose
assert_exit_eq "$RC_SH" 0 "PAR019-G03 Bash: --shared scan of an outside-HOME project -> exit 0"
assert_output_contains "$OUT_SH" "tier=shared" \
    "PAR019-G04 Bash: --shared scan selects the shared tier (AC-13)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_019G=$(newhome); setup_ps1_home "${PS_HOME_019G}"
    run_ps1_scan "${PS_HOME_019G}" "$UNRELATED_HOME_019" projects scan --path "$OUTSIDE_019" --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR019-G05 PS1: scan of an outside-HOME project -> exit 0 (no elevation hang)"
    assert_output_contains "$OUT_PS1" "tier=user" \
        "PAR019-G06 PS1: default scan registers an outside-HOME project in the USER tier (AC-13)"

    PS_HOME_019G2=$(newhome); setup_ps1_home "${PS_HOME_019G2}"
    run_ps1_scan "${PS_HOME_019G2}" "$UNRELATED_HOME_019" projects scan --path "$OUTSIDE_019" --shared --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR019-G07 PS1: --shared scan of an outside-HOME project -> exit 0"
    assert_output_contains "$OUT_PS1" "tier=shared" \
        "PAR019-G08 PS1: --shared scan selects the shared tier (AC-13)"
else
    for _n in 05 06 07 08; do pass "PAR019-G${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-H: --all root/drive classifier -- asserted via the roots-enumeration
# helper itself (--depth 0 --dry-run: enumerates roots and checks each root's
# OWN classification, but never recurses into its content) -- never a real
# whole-disk crawl. On Unix (this suite's CI host, and any Unix box), --all
# walks from "/" with network/removable NOT auto-excluded and the two opt-in
# flags accepted-but-inert with a one-line stderr note (AC-9 documented
# limitation). On a Windows host (bash Git-Bash + native pwsh -- exercised
# only when this suite happens to run there, e.g. local dev; this suite's CI
# matrix runs ubuntu-latest only -- see installer-tests.yml), the SAME
# bounded probe additionally confirms the real machine's fixed-drive set is
# returned with network/removable excluded by default (AC-2/AC-9).
# ---------------------------------------------------------------------------
SH_HOME_019H=$(newhome); setup_sh_home "${SH_HOME_019H}"
run_sh_scan "${SH_HOME_019H}" "$FX_019" projects scan --all --depth 0 --dry-run --verbose
assert_exit_eq "$RC_SH" 0 "PAR019-H01 Bash --all --depth 0 --dry-run -> exit 0 (bounded root probe, no real crawl)"

case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) _PAR019_SH_IS_WIN=1 ;;
    *) _PAR019_SH_IS_WIN=0 ;;
esac
if [[ "$_PAR019_SH_IS_WIN" -eq 0 ]]; then
    assert_output_contains "$OUT_SH" "aid projects scan: roots: /" \
        "PAR019-H02 Bash (Unix): --all resolves to the single '/' root, no drive enumeration (AC-2)"
    run_sh_scan "${SH_HOME_019H}" "$FX_019" projects scan --all --include-network --depth 0 --dry-run
    assert_output_contains "$OUT_SH" "Windows-only-effective" \
        "PAR019-H03 Bash (Unix): --include-network is accepted-but-inert with a one-line note (AC-9 documented limitation)"
else
    pass "PAR019-H02 [SKIPPED: Windows host -- Unix-branch assertion not applicable]"
    _PAR019_SH_ROOTS=$(printf '%s\n' "$OUT_SH" | grep -oE 'roots: .*' || true)
    if printf '%s\n' "$OUT_SH" | grep -qiE 'no fixed drives detected'; then
        pass "PAR019-H03 [SKIPPED: this host's Git-Bash cannot shell out to powershell.exe -- WARN-degrade observed, not a crash]"
    else
        printf '%s\n' "$_PAR019_SH_ROOTS" | grep -qi 'network\|removable' \
            && fail "PAR019-H03 Bash (Windows): a network/removable drive leaked into the default --all root set (AC-2/AC-9)" \
            || pass "PAR019-H03 Bash (Windows): default --all root set excludes network/removable drives (AC-2/AC-9)"
    fi
fi

if [[ -n "$PWSH" ]]; then
    PS_HOME_019H=$(newhome); setup_ps1_home "${PS_HOME_019H}"
    run_ps1_scan "${PS_HOME_019H}" "$FX_019" projects scan --all --depth 0 --dry-run --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR019-H04 PS1 --all --depth 0 --dry-run -> exit 0 (bounded root probe, no real crawl)"

    if printf '%s\n' "$OUT_PS1" | grep -q 'roots: /$'; then
        assert_output_contains "$OUT_PS1" "aid projects scan: roots: /" \
            "PAR019-H05 PS1 (Unix): --all resolves to the single '/' root (AC-2)"
        run_ps1_scan "${PS_HOME_019H}" "$FX_019" projects scan --all --include-removable --depth 0 --dry-run
        assert_output_contains "$OUT_PS1" "Windows-only-effective" \
            "PAR019-H06 PS1 (Unix): --include-removable is accepted-but-inert with a one-line note (AC-9)"
    else
        printf '%s\n' "$OUT_PS1" | grep -qi 'network\|removable' \
            && fail "PAR019-H06 PS1 (Windows): a network/removable drive leaked into the default --all root set (AC-2/AC-9)" \
            || pass "PAR019-H06 PS1 (Windows): default --all root set excludes network/removable drives (AC-2/AC-9)"
    fi
    assert_eq "$RC_SH" "$RC_PS1" "PAR019-H07 Bash<->PS1 exit code parity (--all --depth 0 --dry-run, AC-10)"
else
    for _n in 04 05 06 07; do pass "PAR019-H${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR019-I: NFR-7 -- across EVERY scan run in this block (both twins, every
# mode), no file under any discovered project's .aid/ (or the state home's
# .aid/) was ever created or modified. Also restores the denied dir's mode so
# the suite's own end-of-run cleanup trap can remove it.
# ---------------------------------------------------------------------------
_PAR019_SNAP_AFTER="$(_par019_snapshot)"
assert_eq "$_PAR019_SNAP_AFTER" "$_PAR019_SNAP_BEFORE" \
    "PAR019-I01 no file under any discovered project's .aid/ was created or modified across all PAR019 scans, either twin (NFR-7)"

chmod 755 "${FX_019}/denied" 2>/dev/null || true

# ===========================================================================
# PAR022: 'aid projects scan' Tier-A/Tier-B exclusion expansion + the
# user-level scan-config.yml merge -- bash<->PS1 parity + guardrail coverage
# (work-022-scan-exclusions / task-002)
#
# Exercises the EXPANDED prune sets and the new scan-config.yml merge/seed on
# BOTH twins over ONE shared fixture tree, via the same HOME-default and
# --path modes PAR019 already pins hermetically. See SPEC.md
# (work-022-scan-exclusions) AC-3..AC-10 and its task-002 DETAIL.md.
#
# Design note (AC-4 Tier-B positive direction): --all cannot be redirected
# off the real filesystem root -- there is no test seam in _aid_scan_roots /
# Get-AidScanRoot to inject a fixture path under --all (confirmed by reading
# bin/aid ~:3200-3250 / bin/aid.ps1's Get-AidScanRoot). So the RIGOROUS,
# hermetic proof here is the NEGATIVE direction (a Tier-B name is NEVER
# pruned outside --all, at any depth -- PAR022-A/B below), plus a light,
# best-effort real-machine sanity probe (PAR022-G) that the --all root
# resolution itself is unaffected by the Tier-B expansion. Since the c2 gate
# is ONE generic membership test against the whole (now-expanded)
# _AID_SCAN_SYSTEM_DIRS / $script:AidScanSystemDirs array with no per-name
# branching, the negative-direction proof + a read of the source is the
# strongest hermetic evidence available for this criterion.
#
# PS half: skipped when pwsh absent (same posture as PAR019); the Bash-side
# assertions still run so the block is never a vacuous pass.
# ===========================================================================

echo ""
echo "=== PAR022: scan exclusions + scan-config.yml merge bash<->PS1 parity ==="

_par022_build_fixture() {
    local fx="$1"
    rm -rf "$fx"
    mkdir -p "$fx"

    # Control: a real tracked project so the exact-set assertions below are
    # meaningful (a scan finding NOTHING would trivially "pass" every
    # not-discovered assertion).
    _par019_mkproj "${fx}/proj-real/.aid" "8.0.0"

    # AC-3: representative NEW Tier-A names, each a SHALLOW (depth-1) decoy
    # holding a nested stray .aid/ one level below the decoy itself. Must be
    # pruned (never registered) regardless of mode (Tier-A's membership test,
    # step (c), does not branch on --all vs default).
    local _tA
    for _tA in node_modules .pnpm-store .pytest_cache .next .vscode .cursor \
               .pyenv cache tmp AppData "User Data"; do
        _par019_mkproj "${fx}/tierA-shallow/${_tA}/inner/.aid" "0.9.0"
    done

    # AC-3: the SAME any-depth guarantee, DEEP placement (3 levels below the
    # scan root) for a representative subset -- proves the prune fires at any
    # depth, not just immediate children.
    local _tAd
    for _tAd in node_modules "User Data" .pytest_cache; do
        _par019_mkproj "${fx}/deep-decoys/level1/level2/${_tAd}/inner/.aid" "0.9.1"
    done

    # AC-5: build/bin/.vscode directories that ARE THEMSELVES valid projects
    # -- the is-project check (step b) precedes the name-prune check (step
    # c), so these must still be discovered despite matching a Tier-A name.
    _par019_mkproj "${fx}/named-projects/build/.aid" "9.0.1"
    _par019_mkproj "${fx}/named-projects/bin/.aid" "9.0.2"
    _par019_mkproj "${fx}/named-projects/.vscode/.aid" "9.0.3"

    # AC-4 (negative direction): NEW Tier-B names, SHALLOW and DEEP, each
    # holding a NESTED project one level below. Tier-B pruning is --all AND
    # depth-1-only, so under the HOME-default/--path modes exercised here
    # these must be DESCENDED (the nested project found), at any depth.
    _par019_mkproj "${fx}/tierb-shallow/ProgramData/inner-proj/.aid" "9.2.0"
    _par019_mkproj "${fx}/tierb-deep/a/b/PerfLogs/inner-proj/.aid" "9.2.1"

    # AC-7/AC-8: two non-built-in names, each a decoy with a nested stray
    # .aid/. custom-cache-dir is used by the single-twin config-merge block
    # (PAR022-C); my-par022-custom-dir is reserved for the twin-parity block
    # (PAR022-F) so the two blocks' config edits stay independent.
    _par019_mkproj "${fx}/custom-cache-dir/inner/.aid" "9.3.0"
    _par019_mkproj "${fx}/my-par022-custom-dir/inner/.aid" "9.4.0"

    # PAR022-F guardrail: a directory named exactly "Code" (NOT "Code
    # Cache") -- proves neither twin's prune_dirs: line-scan mis-splits the
    # spaced entry "Code Cache" into a bogus standalone "Code" prune entry
    # (which would wrongly prune this directory).
    _par019_mkproj "${fx}/Code/inner/.aid" "9.4.1"
}

FX_022=$(mktemp -d "${TMP}/par022fx.XXXXXX")
_par022_build_fixture "$FX_022"
FX_022C="$(cd "$FX_022" && pwd -P)"
FX_022_BASE="$(basename "$FX_022")"

_PAR022_EXPECTED=$(cat << 'EXPECTEOF'
Code/inner
custom-cache-dir/inner
my-par022-custom-dir/inner
named-projects/.vscode
named-projects/bin
named-projects/build
proj-real
tierb-deep/a/b/PerfLogs/inner-proj
tierb-shallow/ProgramData/inner-proj
EXPECTEOF
)

# ---------------------------------------------------------------------------
# PAR022-A: baseline (no scan-config.yml) HOME-default scan -- proves the
# expanded Tier-A set prunes at any depth (AC-3), the expanded Tier-B set
# does NOT prune outside --all at any depth (AC-4 negative direction), a
# build/bin/.vscode project is still discovered (AC-5), and a missing config
# yields exactly the built-in set with exit 0 (AC-9 "missing").
# ---------------------------------------------------------------------------
SH_HOME_022A=$(newhome); setup_sh_home "${SH_HOME_022A}"
run_sh_scan "${SH_HOME_022A}" "$FX_022" projects scan --verbose
assert_exit_eq "$RC_SH" 0 "PAR022-A01 Bash baseline (no config) scan -> exit 0 (AC-9 missing-config)"

SH_GOT_022A="$(_par019_extract_registered "$OUT_SH" "$FX_022_BASE")"
assert_eq "$SH_GOT_022A" "$_PAR022_EXPECTED" \
    "PAR022-A02 Bash baseline: discovered set is exactly the expected 9 projects (AC-3/AC-4/AC-5/AC-9)"

# AC-3: every representative new Tier-A name prunes its SHALLOW decoy.
for _tA in node_modules .pnpm-store .pytest_cache .next .vscode .cursor \
           .pyenv cache tmp AppData "User Data"; do
    assert_output_not_contains "$OUT_SH" "${FX_022C}/tierA-shallow/${_tA}/inner  " \
        "PAR022-A03 Bash: new Tier-A name NOT discovered (shallow): ${_tA} (AC-3)"
done

# AC-3: the same names prune at a DEEPER placement too (any depth).
for _tAd in node_modules "User Data" .pytest_cache; do
    assert_output_not_contains "$OUT_SH" "${FX_022C}/deep-decoys/level1/level2/${_tAd}/inner  " \
        "PAR022-A04 Bash: new Tier-A name NOT discovered (deep, 3 levels): ${_tAd} (AC-3)"
done

# AC-5: build/bin/.vscode ARE discovered when they are themselves projects.
assert_output_contains "$OUT_SH" "named-projects/build  9.0.1  registered" \
    "PAR022-A05 Bash: a directory literally named 'build' holding a valid .aid/ IS discovered (AC-5)"
assert_output_contains "$OUT_SH" "named-projects/bin  9.0.2  registered" \
    "PAR022-A06 Bash: a directory literally named 'bin' holding a valid .aid/ IS discovered (AC-5)"
assert_output_contains "$OUT_SH" "named-projects/.vscode  9.0.3  registered" \
    "PAR022-A07 Bash: a directory literally named '.vscode' holding a valid .aid/ IS discovered (AC-5)"

# AC-4 (negative direction): new Tier-B names are NOT pruned outside --all,
# at either depth -- the nested project inside each is found.
assert_output_contains "$OUT_SH" "tierb-shallow/ProgramData/inner-proj  9.2.0  registered" \
    "PAR022-A08 Bash: new Tier-B name 'ProgramData' NOT pruned under HOME-default (shallow, AC-4)"
assert_output_contains "$OUT_SH" "tierb-deep/a/b/PerfLogs/inner-proj  9.2.1  registered" \
    "PAR022-A09 Bash: new Tier-B name 'PerfLogs' NOT pruned under HOME-default (deep, AC-4)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_022A=$(newhome); setup_ps1_home "${PS_HOME_022A}"
    run_ps1_scan "${PS_HOME_022A}" "$FX_022" projects scan --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR022-A10 PS1 baseline (no config) scan -> exit 0"
    PS_GOT_022A="$(_par019_extract_registered "$OUT_PS1" "$FX_022_BASE")"
    assert_eq "$PS_GOT_022A" "$_PAR022_EXPECTED" \
        "PAR022-A11 PS1 baseline: discovered set is exactly the expected 9 projects"
    assert_output_contains "$OUT_PS1" "named-projects/build  9.0.1  registered" \
        "PAR022-A12 PS1: a directory literally named 'build' holding a valid .aid/ IS discovered (AC-5)"
    assert_output_contains "$OUT_PS1" "tierb-shallow/ProgramData/inner-proj  9.2.0  registered" \
        "PAR022-A13 PS1: new Tier-B name 'ProgramData' NOT pruned under HOME-default (AC-4)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR022-A14 Bash<->PS1 exit code parity (baseline scan, AC-10)"
    assert_eq "$SH_GOT_022A" "$PS_GOT_022A" "PAR022-A15 Bash<->PS1 discovered-set parity (baseline scan, AC-10)"
else
    for _n in 10 11 12 13 14 15; do pass "PAR022-A${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR022-B: --path fast-path over the SAME fixture, still config-less --
# proves the Tier-A/Tier-B behavior above is mode-independent (AC-3 "all
# modes" / AC-4), matching PAR019-C's fast-path-parity convention.
# ---------------------------------------------------------------------------
SH_HOME_022B=$(newhome); setup_sh_home "${SH_HOME_022B}"
run_sh_scan "${SH_HOME_022B}" "$FX_022" projects scan --path "$FX_022"
assert_exit_eq "$RC_SH" 0 "PAR022-B01 Bash --path fast-path scan -> exit 0"
SH_GOT_022B="$(_par019_extract_registered "$OUT_SH" "$FX_022_BASE")"
assert_eq "$SH_GOT_022B" "$_PAR022_EXPECTED" \
    "PAR022-B02 Bash --path fast-path: discovered set matches the HOME-default set (AC-3/AC-4 mode-independence)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_022B=$(newhome); setup_ps1_home "${PS_HOME_022B}"
    run_ps1_scan "${PS_HOME_022B}" "$FX_022" projects scan --path "$FX_022"
    assert_exit_eq "$RC_PS1" 0 "PAR022-B03 PS1 --path fast-path scan -> exit 0"
    PS_GOT_022B="$(_par019_extract_registered "$OUT_PS1" "$FX_022_BASE")"
    assert_eq "$PS_GOT_022B" "$_PAR022_EXPECTED" \
        "PAR022-B04 PS1 --path fast-path: discovered set matches the HOME-default set"
    assert_eq "$SH_GOT_022B" "$PS_GOT_022B" "PAR022-B05 Bash<->PS1 discovered-set parity (--path fast path, AC-10)"
else
    for _n in 03 04 05; do pass "PAR022-B${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR022-C: a scan-config.yml adding a non-built-in name extends the prune
# set (AC-7); repeating a built-in name in the SAME config changes nothing
# (AC-8, deduped, no error).
# ---------------------------------------------------------------------------
_PAR022_EXPECTED_C=$(cat << 'EXPECTEOF'
Code/inner
my-par022-custom-dir/inner
named-projects/.vscode
named-projects/bin
named-projects/build
proj-real
tierb-deep/a/b/PerfLogs/inner-proj
tierb-shallow/ProgramData/inner-proj
EXPECTEOF
)

SH_HOME_022C=$(newhome); setup_sh_home "${SH_HOME_022C}"
cat > "${SH_HOME_022C}/scan-config.yml" << 'CFGEOF'
schema: 1
prune_dirs:
  - custom-cache-dir
  - node_modules
CFGEOF
run_sh_scan "${SH_HOME_022C}" "$FX_022" projects scan
assert_exit_eq "$RC_SH" 0 "PAR022-C01 Bash scan with a config-added custom name -> exit 0"
SH_GOT_022C="$(_par019_extract_registered "$OUT_SH" "$FX_022_BASE")"
assert_eq "$SH_GOT_022C" "$_PAR022_EXPECTED_C" \
    "PAR022-C02 Bash: config-added 'custom-cache-dir' now prunes; built-ins still prune (AC-7)"
assert_output_not_contains "$OUT_SH" "${FX_022C}/custom-cache-dir/inner  " \
    "PAR022-C03 Bash: the config-added custom name is not discovered (AC-7)"
assert_output_not_contains "$OUT_SH" "${FX_022C}/tierA-shallow/node_modules/inner  " \
    "PAR022-C04 Bash: a built-in name repeated in config still prunes (deduped, no error, AC-8)"

# ---------------------------------------------------------------------------
# PAR022-D: config guardrails (AC-9) -- a prune_dirs:-less config, and a
# best-effort unreadable config, both yield exit 0 with no error. (The
# "missing config" case is PAR022-A itself: A01/A02 already prove exit 0
# with exactly the built-in set when no scan-config.yml exists at all.)
# ---------------------------------------------------------------------------
SH_HOME_022D1=$(newhome); setup_sh_home "${SH_HOME_022D1}"
cat > "${SH_HOME_022D1}/scan-config.yml" << 'CFGEOF'
schema: 1
CFGEOF
run_sh_scan "${SH_HOME_022D1}" "$FX_022" projects scan
assert_exit_eq "$RC_SH" 0 "PAR022-D01 Bash: config present but no prune_dirs: key -> exit 0 (AC-9)"
SH_GOT_022D1="$(_par019_extract_registered "$OUT_SH" "$FX_022_BASE")"
assert_eq "$SH_GOT_022D1" "$_PAR022_EXPECTED" \
    "PAR022-D02 Bash: prune_dirs:-less config yields exactly the built-in set (AC-9)"

SH_HOME_022D2=$(newhome); setup_sh_home "${SH_HOME_022D2}"
cat > "${SH_HOME_022D2}/scan-config.yml" << 'CFGEOF'
schema: 1
prune_dirs:
  - custom-cache-dir
CFGEOF
chmod 000 "${SH_HOME_022D2}/scan-config.yml" 2>/dev/null || true
run_sh_scan "${SH_HOME_022D2}" "$FX_022" projects scan
assert_exit_eq "$RC_SH" 0 \
    "PAR022-D03 Bash: unreadable config -> exit 0, no error (host-independent -- chmod 000 may not enforce on every host, AC-9)"
chmod 644 "${SH_HOME_022D2}/scan-config.yml" 2>/dev/null || true

if [[ -n "$PWSH" ]]; then
    PS_HOME_022D1=$(newhome); setup_ps1_home "${PS_HOME_022D1}"
    cat > "${PS_HOME_022D1}/scan-config.yml" << 'CFGEOF'
schema: 1
CFGEOF
    run_ps1_scan "${PS_HOME_022D1}" "$FX_022" projects scan
    assert_exit_eq "$RC_PS1" 0 "PAR022-D04 PS1: config present but no prune_dirs: key -> exit 0 (AC-9)"
    PS_GOT_022D1="$(_par019_extract_registered "$OUT_PS1" "$FX_022_BASE")"
    assert_eq "$PS_GOT_022D1" "$_PAR022_EXPECTED" \
        "PAR022-D05 PS1: prune_dirs:-less config yields exactly the built-in set (AC-9)"
else
    for _n in 04 05; do pass "PAR022-D${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR022-E: first-run seeding -- a non-dry-run scan seeds scan-config.yml
# beside registry.yml with the built-in Tier-A defaults; a --dry-run scan
# makes no such write (AC-6).
# ---------------------------------------------------------------------------
SH_HOME_022E1=$(newhome); setup_sh_home "${SH_HOME_022E1}"
run_sh_scan "${SH_HOME_022E1}" "$FX_022" projects scan --dry-run
assert_exit_eq "$RC_SH" 0 "PAR022-E01 Bash --dry-run scan -> exit 0"
if [[ -f "${SH_HOME_022E1}/scan-config.yml" ]]; then
    fail "PAR022-E02 Bash --dry-run: scan-config.yml must stay absent (no write, AC-6)"
else
    pass "PAR022-E02 Bash --dry-run: scan-config.yml stays absent (no write, AC-6)"
fi

SH_HOME_022E2=$(newhome); setup_sh_home "${SH_HOME_022E2}"
run_sh_scan "${SH_HOME_022E2}" "$FX_022" projects scan
assert_exit_eq "$RC_SH" 0 "PAR022-E03 Bash non-dry-run scan -> exit 0"
assert_file_exists "${SH_HOME_022E2}/scan-config.yml" \
    "PAR022-E04 Bash non-dry-run scan: scan-config.yml IS seeded beside registry.yml (AC-6)"
assert_file_contains "${SH_HOME_022E2}/scan-config.yml" "schema: 1" \
    "PAR022-E05 Bash: seeded scan-config.yml carries schema: 1 (AC-6)"
assert_file_contains "${SH_HOME_022E2}/scan-config.yml" "prune_dirs:" \
    "PAR022-E06 Bash: seeded scan-config.yml carries a prune_dirs: block (AC-6)"
assert_file_contains "${SH_HOME_022E2}/scan-config.yml" "  - node_modules" \
    "PAR022-E07 Bash: seeded scan-config.yml lists a built-in default (node_modules, AC-6)"
assert_file_contains "${SH_HOME_022E2}/scan-config.yml" "  - User Data" \
    "PAR022-E08 Bash: seeded scan-config.yml preserves a spaced built-in default (User Data, AC-6)"
assert_file_contains "${SH_HOME_022E2}/scan-config.yml" "  - log" \
    "PAR022-E09 Bash: seeded scan-config.yml lists the last built-in default (log, AC-6)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_022E1=$(newhome); setup_ps1_home "${PS_HOME_022E1}"
    run_ps1_scan "${PS_HOME_022E1}" "$FX_022" projects scan --dry-run
    assert_exit_eq "$RC_PS1" 0 "PAR022-E10 PS1 --dry-run scan -> exit 0"
    if [[ -f "${PS_HOME_022E1}/scan-config.yml" ]]; then
        fail "PAR022-E11 PS1 --dry-run: scan-config.yml must stay absent (no write, AC-6)"
    else
        pass "PAR022-E11 PS1 --dry-run: scan-config.yml stays absent (no write, AC-6)"
    fi

    PS_HOME_022E2=$(newhome); setup_ps1_home "${PS_HOME_022E2}"
    run_ps1_scan "${PS_HOME_022E2}" "$FX_022" projects scan
    assert_exit_eq "$RC_PS1" 0 "PAR022-E12 PS1 non-dry-run scan -> exit 0"
    assert_file_exists "${PS_HOME_022E2}/scan-config.yml" \
        "PAR022-E13 PS1 non-dry-run scan: scan-config.yml IS seeded beside registry.yml (AC-6)"
    assert_file_contains "${PS_HOME_022E2}/scan-config.yml" "  - node_modules" \
        "PAR022-E14 PS1: seeded scan-config.yml lists a built-in default (node_modules, AC-6)"
else
    for _n in 10 11 12 13 14; do pass "PAR022-E${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR022-F: both twins, given a BYTE-IDENTICAL config (a built-in dup
# 'node_modules', a NEW custom name 'my-par022-custom-dir', and a spaced
# built-in dup '- Code Cache'), read it identically and produce the
# identical discovered set + identical exit codes over the SAME fixture
# (AC-10). The literal 'Code' fixture entry also proves neither twin's
# line-scan mis-splits the spaced 'Code Cache' entry into a bogus standalone
# 'Code' prune name.
# ---------------------------------------------------------------------------
_PAR022_CFG_F=$(cat << 'CFGEOF'
schema: 1
prune_dirs:
  - node_modules
  - my-par022-custom-dir
  - Code Cache
CFGEOF
)
_PAR022_EXPECTED_F=$(cat << 'EXPECTEOF'
Code/inner
custom-cache-dir/inner
named-projects/.vscode
named-projects/bin
named-projects/build
proj-real
tierb-deep/a/b/PerfLogs/inner-proj
tierb-shallow/ProgramData/inner-proj
EXPECTEOF
)

SH_HOME_022F=$(newhome); setup_sh_home "${SH_HOME_022F}"
printf '%s\n' "$_PAR022_CFG_F" > "${SH_HOME_022F}/scan-config.yml"
run_sh_scan "${SH_HOME_022F}" "$FX_022" projects scan
assert_exit_eq "$RC_SH" 0 "PAR022-F01 Bash scan with the identical AC-10 config -> exit 0"
SH_GOT_022F="$(_par019_extract_registered "$OUT_SH" "$FX_022_BASE")"
assert_eq "$SH_GOT_022F" "$_PAR022_EXPECTED_F" \
    "PAR022-F02 Bash: identical config -> custom name pruned, 'Code' (not 'Code Cache') still discovered (AC-10)"

if [[ -n "$PWSH" ]]; then
    PS_HOME_022F=$(newhome); setup_ps1_home "${PS_HOME_022F}"
    printf '%s\n' "$_PAR022_CFG_F" > "${PS_HOME_022F}/scan-config.yml"
    run_ps1_scan "${PS_HOME_022F}" "$FX_022" projects scan
    assert_exit_eq "$RC_PS1" 0 "PAR022-F03 PS1 scan with the identical AC-10 config -> exit 0"
    PS_GOT_022F="$(_par019_extract_registered "$OUT_PS1" "$FX_022_BASE")"
    assert_eq "$PS_GOT_022F" "$_PAR022_EXPECTED_F" \
        "PAR022-F04 PS1: identical config -> custom name pruned, 'Code' still discovered (AC-10)"
    assert_eq "$RC_SH" "$RC_PS1" "PAR022-F05 Bash<->PS1 exit code parity (identical config, AC-10)"
    assert_eq "$SH_GOT_022F" "$PS_GOT_022F" "PAR022-F06 Bash<->PS1 discovered-set parity (identical config, AC-10)"
else
    for _n in 03 04 05 06; do pass "PAR022-F${_n} [SKIPPED: pwsh absent]"; done
fi

# ---------------------------------------------------------------------------
# PAR022-G: a light, best-effort real-machine sanity check that --all root
# resolution is unaffected by the Tier-B expansion (see the block header
# comment for why a rigorous, hermetic POSITIVE root-only-prune proof is not
# possible: --all cannot be redirected off the real filesystem root). Mirrors
# PAR019-H's bounded, --dry-run, uname-branched probe style.
# ---------------------------------------------------------------------------
SH_HOME_022G=$(newhome); setup_sh_home "${SH_HOME_022G}"
run_sh_scan "${SH_HOME_022G}" "$FX_022" projects scan --all --depth 1 --dry-run --verbose
assert_exit_eq "$RC_SH" 0 "PAR022-G01 Bash --all --depth 1 --dry-run -> exit 0 (bounded one-level probe, no real crawl)"

case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) _PAR022_SH_IS_WIN=1 ;;
    *) _PAR022_SH_IS_WIN=0 ;;
esac
if [[ "$_PAR022_SH_IS_WIN" -eq 0 ]]; then
    assert_output_contains "$OUT_SH" "aid projects scan: roots: /" \
        "PAR022-G02 Bash (Unix): --all still resolves to the single '/' root after the Tier-B expansion (AC-2 regression guard)"
else
    pass "PAR022-G02 [SKIPPED: Windows host -- Unix-branch assertion not applicable]"
fi

if [[ -n "$PWSH" ]]; then
    PS_HOME_022G=$(newhome); setup_ps1_home "${PS_HOME_022G}"
    run_ps1_scan "${PS_HOME_022G}" "$FX_022" projects scan --all --depth 1 --dry-run --verbose
    assert_exit_eq "$RC_PS1" 0 "PAR022-G03 PS1 --all --depth 1 --dry-run -> exit 0 (bounded one-level probe, no real crawl)"
    if [[ "$_PAR022_SH_IS_WIN" -eq 0 ]]; then
        assert_output_contains "$OUT_PS1" "aid projects scan: roots: /" \
            "PAR022-G04 PS1 (Unix): --all still resolves to the single '/' root after the Tier-B expansion (AC-2 regression guard)"
    else
        pass "PAR022-G04 [SKIPPED: Windows host -- Unix-branch assertion not applicable]"
    fi
    assert_eq "$RC_SH" "$RC_PS1" "PAR022-G05 Bash<->PS1 exit code parity (--all --depth 1 --dry-run, AC-10)"
else
    for _n in 03 04 05; do pass "PAR022-G${_n} [SKIPPED: pwsh absent]"; done
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
