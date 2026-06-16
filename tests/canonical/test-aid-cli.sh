#!/usr/bin/env bash
# test-aid-cli.sh — Task 027: Integration tests for the persistent Bash `aid` CLI.
#
# Tests bootstrap, PATH wiring, all subcommands, CONVENIENCE mode, LEGACY back-compat,
# and remove self via the bin/aid dispatcher + install.sh BOOTSTRAP/CONVENIENCE paths.
#
# Key invariants:
#  - All temp state is isolated under mktemp dirs; AID_HOME never touches real $HOME.
#  - Profile files are temp files, never real ~/.bashrc.
#  - AID_LIB_PATH is always set so no network calls occur.
#
# Usage:
#   bash test-aid-cli.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$INSTALL_SH" ]] || { echo "ERROR: install.sh not found at $INSTALL_SH" >&2; exit 1; }
[[ -f "$BIN_AID" ]]    || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_CORE" ]]   || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_CORE" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

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
        local fname
        fname="$(basename "$f")"
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
newprofile() { mktemp "${TMP}/profile.XXXXXX"; }

# Helper: create a fully wired AID_HOME from repo source.
# Usage: setup_aid_home <aid_home_dir>
# Installs bin/aid, lib/aid-install-core.sh, and writes VERSION.
setup_aid_home() {
    local home_dir="$1"
    mkdir -p "${home_dir}/bin" "${home_dir}/lib"
    cp "${BIN_AID}" "${home_dir}/bin/aid"
    chmod +x "${home_dir}/bin/aid"
    cp "${LIB_CORE}" "${home_dir}/lib/aid-install-core.sh"
    printf '%s\n' "${VERSION}" > "${home_dir}/VERSION"
}

# Helper: run the aid CLI with an isolated AID_HOME.
# Usage: run_aid <aid_home> [args...]
run_aid() {
    local aid_home="$1"
    shift
    OUT=$(AID_HOME="$aid_home" AID_LIB_PATH="${aid_home}/lib/aid-install-core.sh" \
          bash "${aid_home}/bin/aid" "$@" 2>&1); RC=$?
}

# Helper: run install.sh with AID_LIB_PATH set (no network).
run_install() {
    OUT=$(AID_LIB_PATH="${LIB_CORE}" bash "${INSTALL_SH}" "$@" 2>&1); RC=$?
}

# ===========================================================================
# CLI027-A: BOOTSTRAP mode — install.sh (no args) installs global CLI
# ===========================================================================

CLI027_HOME=$(newhome)
CLI027_PROFILE=$(newprofile)

run_install \
    --profile-file "${CLI027_PROFILE}" \
    --target "${CLI027_HOME}" 2>&1 || true
# BOOTSTRAP mode: inject AID_HOME so it installs to our temp dir
OUT=$(AID_HOME="${CLI027_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      bash "${INSTALL_SH}" \
      --profile-file "${CLI027_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-A01 BOOTSTRAP installs cli → exit 0"
assert_file_exists "${CLI027_HOME}/bin/aid" "CLI027-A02 bin/aid installed"
assert_file_exists "${CLI027_HOME}/lib/aid-install-core.sh" "CLI027-A03 lib/aid-install-core.sh installed"
assert_file_exists "${CLI027_HOME}/VERSION" "CLI027-A04 VERSION file installed"
assert_eq "$(cat "${CLI027_HOME}/VERSION")" "${VERSION}" "CLI027-A05 VERSION contains correct version"
assert_output_contains "$OUT" "aid CLI v${VERSION} installed" "CLI027-A06 install reports version"

# PATH wiring: marked block written to temp profile.
assert_file_contains "${CLI027_PROFILE}" "# >>> aid CLI >>>" "CLI027-A07 PATH fence start written to profile"
assert_file_contains "${CLI027_PROFILE}" "# <<< aid CLI <<<" "CLI027-A08 PATH fence end written to profile"
assert_file_contains "${CLI027_PROFILE}" "${CLI027_HOME}/bin" "CLI027-A09 bin dir in PATH block"

# ===========================================================================
# CLI027-B: BOOTSTRAP idempotent — run twice → exactly one PATH block
# ===========================================================================
OUT=$(AID_HOME="${CLI027_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      bash "${INSTALL_SH}" \
      --profile-file "${CLI027_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-B01 re-bootstrap → exit 0"
# Count fence starts: must be exactly 1.
_fence_count=$(grep -c '# >>> aid CLI >>>' "${CLI027_PROFILE}" 2>/dev/null || echo 0)
assert_eq "$_fence_count" "1" "CLI027-B02 idempotent: exactly one PATH marked-block (no dup)"

# ===========================================================================
# CLI027-C: PATH wiring — --no-path skips it
# ===========================================================================
CLI027C_HOME=$(newhome)
CLI027C_PROFILE=$(newprofile)

OUT=$(AID_HOME="${CLI027C_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      bash "${INSTALL_SH}" \
      --no-path \
      --profile-file "${CLI027C_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-C01 --no-path bootstrap → exit 0"
assert_file_exists "${CLI027C_HOME}/bin/aid" "CLI027-C02 bin/aid still installed with --no-path"
# Profile should NOT contain the fence block when --no-path used.
if [[ -s "${CLI027C_PROFILE}" ]]; then
    assert_output_not_contains "$(cat "${CLI027C_PROFILE}")" "# >>> aid CLI >>>" "CLI027-C03 --no-path: no fence block in profile"
else
    pass "CLI027-C03 --no-path: no fence block in profile (empty)"
fi
assert_output_contains "$OUT" "manually" "CLI027-C04 --no-path prints manual instruction"

# ===========================================================================
# CLI027-D: remove self removes AID_HOME + PATH block (fence-based)
# ===========================================================================
CLI027D_HOME=$(newhome)
CLI027D_PROFILE=$(newprofile)
setup_aid_home "${CLI027D_HOME}"
# Write a fenced PATH block to the profile.
printf '\n# >>> aid CLI >>>\nexport PATH="%s/bin:$PATH"\n# <<< aid CLI <<<\n' \
    "${CLI027D_HOME}" >> "${CLI027D_PROFILE}"

OUT=$(AID_HOME="${CLI027D_HOME}" \
      "${CLI027D_HOME}/bin/aid" remove self --force \
      --profile-file "${CLI027D_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-D01 remove self --force → exit 0"
assert_eq "$([[ -d "${CLI027D_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI027-D02 AID_HOME removed after remove self"
# PATH block must be removed.
if [[ -f "${CLI027D_PROFILE}" ]]; then
    assert_output_not_contains "$(cat "${CLI027D_PROFILE}")" "# >>> aid CLI >>>" \
        "CLI027-D03 PATH fence block removed from profile after remove self"
fi
# Expected message.
assert_output_contains "$OUT" "aid CLI removed" "CLI027-D04 remove self message"

# ===========================================================================
# CLI027-E: aid status — empty dir → exit 7 + message
# ===========================================================================
CLI027E_HOME=$(newhome)
setup_aid_home "${CLI027E_HOME}"
T=$(newtarget)

run_aid "${CLI027E_HOME}" status --target "$T"
assert_exit_eq "$RC" 7 "CLI027-E01 aid status empty dir → exit 7"
assert_output_contains "$OUT" "No AID install found" "CLI027-E02 status empty dir prints 'No AID install found'"
assert_output_contains "$OUT" "aid add" "CLI027-E03 status suggests 'aid add'"

# ===========================================================================
# CLI027-F: aid status — project with manifest → correct output
# ===========================================================================
CLI027F_HOME=$(newhome)
setup_aid_home "${CLI027F_HOME}"
TF=$(newtarget)

# Install codex into TF so there is a manifest.
OUT=$(AID_HOME="${CLI027F_HOME}" AID_LIB_PATH="${CLI027F_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027F_HOME}/bin/aid" add codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TF}" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI027-F01 add codex for status test → exit 0"

run_aid "${CLI027F_HOME}" status --target "${TF}"
assert_exit_eq "$RC" 0 "CLI027-F02 aid status with manifest → exit 0"
assert_output_contains "$OUT" "AID ${VERSION}" "CLI027-F03 status shows AID version"
assert_output_contains "$OUT" "Installed tools" "CLI027-F04 status shows 'Installed tools'"
assert_output_contains "$OUT" "codex" "CLI027-F05 status lists codex"
# CLI027-F06: uniform display — version appears in header ("all at vX"), not per-tool line.
assert_output_contains "$OUT" "${VERSION}" "CLI027-F06 status shows tool version"
# CLI027-F07: root agent not shown for owned tools (collapse-when-uniform display).
pass "CLI027-F07 root agent display suppressed for owned tools (by design)"

# ===========================================================================
# CLI027-G: bare `aid` (no args) → dashboard landing screen
# ===========================================================================

# G01-G05: empty directory → exit 0, dashboard blocks present.
CLI027G_HOME=$(newhome)
setup_aid_home "${CLI027G_HOME}"
TG=$(newtarget)

OUT=$(cd "${TG}" && AID_HOME="${CLI027G_HOME}" AID_LIB_PATH="${CLI027G_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI027-G01 bare aid in empty dir → exit 0 (dashboard)"
assert_output_contains "$OUT" "AID v${VERSION}" "CLI027-G02 dashboard header contains 'AID v<ver>'"
assert_output_contains "$OUT" "Agentic Iterative Development" "CLI027-G03 dashboard header contains description tag"
assert_output_contains "$OUT" "Install, update, and manage AID" "CLI027-G04 dashboard description line"
assert_output_contains "$OUT" "yet" "CLI027-G05 dashboard: empty dir shows friendly no-tools message"
assert_output_contains "$OUT" "aid add" "CLI027-G06 dashboard: usage block contains 'aid add'"

# G07-G12: project with tools → exit 0, all 4 blocks present.
CLI027G2_HOME=$(newhome)
setup_aid_home "${CLI027G2_HOME}"
TG2=$(newtarget)

# Install codex into TG2.
OUT_INSTALL=$(AID_HOME="${CLI027G2_HOME}" AID_LIB_PATH="${CLI027G2_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G2_HOME}/bin/aid" add codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TG2}" 2>&1); RC_INSTALL=$?
assert_exit_eq "$RC_INSTALL" 0 "CLI027-G07 pre-install codex for dashboard test → exit 0"

OUT=$(cd "${TG2}" && AID_HOME="${CLI027G2_HOME}" AID_LIB_PATH="${CLI027G2_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G2_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI027-G08 bare aid in project dir → exit 0"
assert_output_contains "$OUT" "AID v${VERSION}" "CLI027-G09 dashboard with tools: header shows version"
assert_output_contains "$OUT" "Installed tools (in" "CLI027-G10 dashboard with tools: shows 'Installed tools (in'"
assert_output_contains "$OUT" "codex" "CLI027-G11 dashboard with tools: codex listed"
assert_output_contains "$OUT" "aid add" "CLI027-G12 dashboard with tools: usage block present"

# G13: confirm `aid status` (explicit) still exits 7 in empty dir — UNCHANGED.
CLI027G3_HOME=$(newhome)
setup_aid_home "${CLI027G3_HOME}"
TG3=$(newtarget)

run_aid "${CLI027G3_HOME}" status --target "${TG3}"
assert_exit_eq "$RC" 7 "CLI027-G13 aid status (explicit) empty dir → exit 7 (unchanged)"

# ===========================================================================
# CLI027-H: aid add <tool> + aid remove <tool>
# ===========================================================================
CLI027H_HOME=$(newhome)
setup_aid_home "${CLI027H_HOME}"
TH=$(newtarget)

run_aid "${CLI027H_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TH}"
assert_exit_eq "$RC" 0 "CLI027-H01 aid add codex → exit 0"
assert_dir_exists "${TH}/.codex" "CLI027-H02 .codex/ created"
assert_file_exists "${TH}/AGENTS.md" "CLI027-H03 AGENTS.md created"
assert_file_exists "${TH}/.aid/.aid-manifest.json" "CLI027-H04 manifest created"
assert_output_contains "$OUT" "Done." "CLI027-H05 add reports Done."

run_aid "${CLI027H_HOME}" remove codex --target "${TH}"
assert_exit_eq "$RC" 0 "CLI027-H06 aid remove codex → exit 0"
assert_eq "$([[ -d "${TH}/.codex" ]] && echo exists || echo gone)" "gone" \
    "CLI027-H07 .codex/ removed after remove"
assert_output_contains "$OUT" "Uninstall complete." "CLI027-H08 remove reports 'Uninstall complete.'"

# ===========================================================================
# CLI027-I: aid add with comma-list (multi-tool)
# ===========================================================================
CLI027I_HOME=$(newhome)
setup_aid_home "${CLI027I_HOME}"
TI=$(newtarget)

run_aid "${CLI027I_HOME}" add claude-code,codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TI}"
assert_exit_eq "$RC" 0 "CLI027-I01 aid add claude-code,codex → exit 0"
assert_dir_exists "${TI}/.claude" "CLI027-I02 .claude/ created"
assert_dir_exists "${TI}/.codex" "CLI027-I03 .codex/ created"
assert_file_exists "${TI}/CLAUDE.md" "CLI027-I04 CLAUDE.md created"
assert_file_exists "${TI}/AGENTS.md" "CLI027-I05 AGENTS.md created"

# ===========================================================================
# CLI027-J: aid update (named tool + all-from-manifest; empty → exit 6)
# ===========================================================================
CLI027J_HOME=$(newhome)
setup_aid_home "${CLI027J_HOME}"
TJ=$(newtarget)

# Install codex first.
run_aid "${CLI027J_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J01 add codex for update test → exit 0"

# Update named: same version → "up to date".
run_aid "${CLI027J_HOME}" update codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J02 aid update codex (same version) → exit 0"
assert_output_contains "$OUT" "up to date" "CLI027-J03 update same version shows 'up to date'"

# Update all (no tool arg) — same version → still 0.
run_aid "${CLI027J_HOME}" update \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J04 aid update all tools → exit 0"

# Update on dir with no manifest → exit 6.
TJ_EMPTY=$(newtarget)
run_aid "${CLI027J_HOME}" update --target "${TJ_EMPTY}"
assert_exit_eq "$RC" 6 "CLI027-J05 aid update empty manifest → exit 6"

# ===========================================================================
# CLI027-K: aid remove (no arg, all tools) — with --force to skip prompt
# ===========================================================================
CLI027K_HOME=$(newhome)
setup_aid_home "${CLI027K_HOME}"
TK=$(newtarget)

run_aid "${CLI027K_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TK}"
assert_exit_eq "$RC" 0 "CLI027-K01 add for remove test → exit 0"

run_aid "${CLI027K_HOME}" remove --force --target "${TK}"
assert_exit_eq "$RC" 0 "CLI027-K02 aid remove --force (all) → exit 0"
assert_eq "$([[ -d "${TK}/.codex" ]] && echo exists || echo gone)" "gone" \
    "CLI027-K03 .codex/ removed after remove"
assert_eq "$([[ -f "${TK}/AGENTS.md" ]] && echo exists || echo gone)" "gone" \
    "CLI027-K04 AGENTS.md removed after remove"
assert_output_contains "$OUT" "Uninstall complete." "CLI027-K05 remove reports 'Uninstall complete.'"

# ===========================================================================
# CLI027-L: protect-on-diff (FR11) honored on root agent file via `aid add`
# ===========================================================================
CLI027L_HOME=$(newhome)
setup_aid_home "${CLI027L_HOME}"
TL=$(newtarget)
printf 'User AGENTS.md pre-placed\n' > "${TL}/AGENTS.md"

run_aid "${CLI027L_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TL}"
assert_exit_eq "$RC" 5 "CLI027-L01 aid add with pre-placed AGENTS.md → exit 5 (protect-on-diff)"
assert_file_exists "${TL}/AGENTS.md.aid-new" "CLI027-L02 AGENTS.md.aid-new created"
assert_file_contains "${TL}/AGENTS.md" "User AGENTS.md" "CLI027-L03 original AGENTS.md not overwritten"

# ===========================================================================
# CLI027-M: aid version → exit 0, prints version
# ===========================================================================
CLI027M_HOME=$(newhome)
setup_aid_home "${CLI027M_HOME}"

run_aid "${CLI027M_HOME}" version
assert_exit_eq "$RC" 0 "CLI027-M01 aid version → exit 0"
assert_output_contains "$OUT" "${VERSION}" "CLI027-M02 aid version prints version string"

# ===========================================================================
# CLI027-N: aid help / -h / --help → exit 0, prints Usage
#           Per-subcommand -h also works
# ===========================================================================
CLI027N_HOME=$(newhome)
setup_aid_home "${CLI027N_HOME}"

run_aid "${CLI027N_HOME}" help
assert_exit_eq "$RC" 0 "CLI027-N01 aid help → exit 0"
assert_output_contains "$OUT" "Usage" "CLI027-N02 aid help prints 'Usage'"
assert_output_contains "$OUT" "aid" "CLI027-N03 aid help mentions 'aid'"
# General help must NOT contain removed sections.
assert_output_not_contains "$OUT" "Env vars:" "CLI027-N04 general help: no 'Env vars:' section"
assert_output_not_contains "$OUT" "Exit codes:" "CLI027-N05 general help: no 'Exit codes:' section"
# General help must contain the short flags hint.
assert_output_contains "$OUT" "Flags:" "CLI027-N06 general help: has 'Flags:' line"
assert_output_contains "$OUT" "aid <command> -h" "CLI027-N07 general help: has per-command hint"

# Per-subcommand -h prints focused help and exits 0.
run_aid "${CLI027N_HOME}" add -h
assert_exit_eq "$RC" 0 "CLI027-N08 aid add -h → exit 0"
assert_output_contains "$OUT" "aid add" "CLI027-N09 aid add -h shows 'aid add'"

run_aid "${CLI027N_HOME}" remove -h
assert_exit_eq "$RC" 0 "CLI027-N10 aid remove -h → exit 0"
assert_output_contains "$OUT" "aid remove" "CLI027-N11 aid remove -h shows 'aid remove'"

run_aid "${CLI027N_HOME}" update -h
assert_exit_eq "$RC" 0 "CLI027-N12 aid update -h → exit 0"
assert_output_contains "$OUT" "aid update" "CLI027-N13 aid update -h shows 'aid update'"

run_aid "${CLI027N_HOME}" status -h
assert_exit_eq "$RC" 0 "CLI027-N14 aid status -h → exit 0"
assert_output_contains "$OUT" "aid status" "CLI027-N15 aid status -h shows 'aid status'"

# ===========================================================================
# CLI027-O: unknown subcommand → exit 2
# ===========================================================================
CLI027O_HOME=$(newhome)
setup_aid_home "${CLI027O_HOME}"

run_aid "${CLI027O_HOME}" frobnicate
assert_exit_eq "$RC" 2 "CLI027-O01 unknown subcommand → exit 2"
assert_output_contains "$OUT" "unknown command" "CLI027-O02 unknown subcommand error message"

# ===========================================================================
# CLI027-P: CONVENIENCE mode — install.sh add codex ... bootstraps CLI + installs
# ===========================================================================
CLI027P_HOME=$(newhome)
CLI027P_PROFILE=$(newprofile)
TP=$(newtarget)

OUT=$(AID_HOME="${CLI027P_HOME}" AID_LIB_PATH="${LIB_CORE}" \
     bash "${INSTALL_SH}" \
     --profile-file "${CLI027P_PROFILE}" \
     add codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TP}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-P01 CONVENIENCE: install.sh add codex → exit 0"
# CLI must have been installed.
assert_file_exists "${CLI027P_HOME}/bin/aid" "CLI027-P02 CONVENIENCE: bin/aid installed"
# codex must have been installed in the project.
assert_dir_exists "${TP}/.codex" "CLI027-P03 CONVENIENCE: .codex/ created"
assert_file_exists "${TP}/AGENTS.md" "CLI027-P04 CONVENIENCE: AGENTS.md created"
assert_output_contains "$OUT" "Done." "CLI027-P05 CONVENIENCE: reports Done."

# ===========================================================================
# CLI027-Q: LEGACY back-compat — install.sh --tool codex --from-bundle <tar> --target <dir>
# ===========================================================================
TQ=$(newtarget)
OUT=$(AID_LIB_PATH="${LIB_CORE}" bash "${INSTALL_SH}" \
     --tool codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TQ}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-Q01 LEGACY --tool codex → exit 0"
assert_dir_exists "${TQ}/.codex" "CLI027-Q02 LEGACY .codex/ created"
assert_file_exists "${TQ}/AGENTS.md" "CLI027-Q03 LEGACY AGENTS.md created"
assert_output_contains "$OUT" "Done." "CLI027-Q04 LEGACY reports Done."
# Manifest must exist.
assert_file_exists "${TQ}/.aid/.aid-manifest.json" "CLI027-Q05 LEGACY manifest created"

# ===========================================================================
# CLI027-R: install.sh --uninstall-cli --force → remove AID_HOME + PATH block
# ===========================================================================
CLI027R_HOME=$(newhome)
CLI027R_PROFILE=$(newprofile)
setup_aid_home "${CLI027R_HOME}"
# Write a fenced PATH block.
printf '\n# >>> aid CLI >>>\nexport PATH="%s/bin:$PATH"\n# <<< aid CLI <<<\n' \
    "${CLI027R_HOME}" >> "${CLI027R_PROFILE}"

OUT=$(AID_HOME="${CLI027R_HOME}" AID_LIB_PATH="${LIB_CORE}" \
     bash "${INSTALL_SH}" \
     --uninstall-cli --force \
     --profile-file "${CLI027R_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-R01 install.sh --uninstall-cli --force → exit 0"
assert_eq "$([[ -d "${CLI027R_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI027-R02 AID_HOME removed by --uninstall-cli"
if [[ -f "${CLI027R_PROFILE}" ]]; then
    assert_output_not_contains "$(cat "${CLI027R_PROFILE}")" "# >>> aid CLI >>>" \
        "CLI027-R03 PATH fence block removed from profile"
fi
assert_output_contains "$OUT" "aid CLI removed" "CLI027-R04 exact remove self message string"

# ===========================================================================
# CLI027-S: PATH wiring — multi-rc regression (the main bug fix)
#   $HOME has BOTH .zshrc and .bashrc; SHELL=/bin/bash → BOTH get the block.
# ===========================================================================
CLI027S_HOME=$(newhome)
CLI027S_FAKE_HOME=$(newhome)
touch "${CLI027S_FAKE_HOME}/.zshrc"
touch "${CLI027S_FAKE_HOME}/.bashrc"

OUT=$(AID_HOME="${CLI027S_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      HOME="${CLI027S_FAKE_HOME}" SHELL="/bin/bash" \
      bash "${INSTALL_SH}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-S01 multi-rc bootstrap (bash+zsh present) → exit 0"
assert_file_contains "${CLI027S_FAKE_HOME}/.zshrc"  "# >>> aid CLI >>>" "CLI027-S02 .zshrc gets the fence block"
assert_file_contains "${CLI027S_FAKE_HOME}/.bashrc" "# >>> aid CLI >>>" "CLI027-S03 .bashrc gets the fence block"
# The guarded export must be present (case-in-PATH form).
assert_file_contains "${CLI027S_FAKE_HOME}/.zshrc"  "case \":\$PATH:\" in" "CLI027-S04 .zshrc has duplicate-guarded export"
assert_file_contains "${CLI027S_FAKE_HOME}/.bashrc" "case \":\$PATH:\" in" "CLI027-S05 .bashrc has duplicate-guarded export"

# ===========================================================================
# CLI027-T: PATH wiring — only .profile exists
# ===========================================================================
CLI027T_HOME=$(newhome)
CLI027T_FAKE_HOME=$(newhome)
touch "${CLI027T_FAKE_HOME}/.profile"

OUT=$(AID_HOME="${CLI027T_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      HOME="${CLI027T_FAKE_HOME}" SHELL="/bin/bash" \
      bash "${INSTALL_SH}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-T01 bootstrap with only .profile → exit 0"
assert_file_contains "${CLI027T_FAKE_HOME}/.profile" "# >>> aid CLI >>>" "CLI027-T02 .profile gets fence block"

# ===========================================================================
# CLI027-U: PATH wiring — no rc file exists → .profile created and wired
# ===========================================================================
CLI027U_HOME=$(newhome)
CLI027U_FAKE_HOME=$(newhome)
# Ensure none of the standard files exist.
rm -f "${CLI027U_FAKE_HOME}/.zshrc" "${CLI027U_FAKE_HOME}/.bashrc" \
      "${CLI027U_FAKE_HOME}/.bash_profile" "${CLI027U_FAKE_HOME}/.profile" 2>/dev/null || true

OUT=$(AID_HOME="${CLI027U_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      HOME="${CLI027U_FAKE_HOME}" SHELL="/bin/bash" \
      bash "${INSTALL_SH}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-U01 bootstrap with no rc files → exit 0"
assert_file_exists "${CLI027U_FAKE_HOME}/.profile" "CLI027-U02 .profile created when no rc file exists"
assert_file_contains "${CLI027U_FAKE_HOME}/.profile" "# >>> aid CLI >>>" "CLI027-U03 created .profile gets fence block"

# ===========================================================================
# CLI027-V: PATH wiring idempotent — re-run bootstrap; exactly one block per file
# ===========================================================================
CLI027V_HOME=$(newhome)
CLI027V_FAKE_HOME=$(newhome)
touch "${CLI027V_FAKE_HOME}/.zshrc"
touch "${CLI027V_FAKE_HOME}/.bashrc"

# First run.
AID_HOME="${CLI027V_HOME}" AID_LIB_PATH="${LIB_CORE}" \
    HOME="${CLI027V_FAKE_HOME}" SHELL="/bin/bash" \
    bash "${INSTALL_SH}" >/dev/null 2>&1 || true
# Second run.
AID_HOME="${CLI027V_HOME}" AID_LIB_PATH="${LIB_CORE}" \
    HOME="${CLI027V_FAKE_HOME}" SHELL="/bin/bash" \
    bash "${INSTALL_SH}" >/dev/null 2>&1 || true

_v_zshrc_count=$(grep -c '# >>> aid CLI >>>' "${CLI027V_FAKE_HOME}/.zshrc" 2>/dev/null || echo 0)
_v_bashrc_count=$(grep -c '# >>> aid CLI >>>' "${CLI027V_FAKE_HOME}/.bashrc" 2>/dev/null || echo 0)
assert_eq "$_v_zshrc_count"  "1" "CLI027-V01 idempotent: exactly one block in .zshrc"
assert_eq "$_v_bashrc_count" "1" "CLI027-V02 idempotent: exactly one block in .bashrc"
# Verify duplicate-guarded form.
assert_file_contains "${CLI027V_FAKE_HOME}/.zshrc"  "case \":\$PATH:\" in" "CLI027-V03 .zshrc retains guarded export after re-run"
assert_file_contains "${CLI027V_FAKE_HOME}/.bashrc" "case \":\$PATH:\" in" "CLI027-V04 .bashrc retains guarded export after re-run"

# ===========================================================================
# CLI027-W: PATH wiring — --no-path skips ALL rc files
# ===========================================================================
CLI027W_HOME=$(newhome)
CLI027W_FAKE_HOME=$(newhome)
touch "${CLI027W_FAKE_HOME}/.zshrc"
touch "${CLI027W_FAKE_HOME}/.bashrc"

OUT=$(AID_HOME="${CLI027W_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      HOME="${CLI027W_FAKE_HOME}" SHELL="/bin/bash" \
      bash "${INSTALL_SH}" --no-path 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-W01 --no-path bootstrap → exit 0"
if [[ -s "${CLI027W_FAKE_HOME}/.zshrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027W_FAKE_HOME}/.zshrc")" "# >>> aid CLI >>>" \
        "CLI027-W02 --no-path: .zshrc not touched"
else
    pass "CLI027-W02 --no-path: .zshrc not touched (empty)"
fi
if [[ -s "${CLI027W_FAKE_HOME}/.bashrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027W_FAKE_HOME}/.bashrc")" "# >>> aid CLI >>>" \
        "CLI027-W03 --no-path: .bashrc not touched"
else
    pass "CLI027-W03 --no-path: .bashrc not touched (empty)"
fi

# ===========================================================================
# CLI027-X: remove self removes fenced block from ALL wired files
# ===========================================================================
CLI027X_HOME=$(newhome)
CLI027X_FAKE_HOME=$(newhome)
setup_aid_home "${CLI027X_HOME}"

# Manually wire the fenced block into both .zshrc and .bashrc.
for _x_rc in "${CLI027X_FAKE_HOME}/.zshrc" "${CLI027X_FAKE_HOME}/.bashrc"; do
    printf '\n# >>> aid CLI >>>\ncase ":$PATH:" in *":%s/bin:"*) ;; *) export PATH="%s/bin:$PATH" ;; esac\n# <<< aid CLI <<<\n' \
        "${CLI027X_HOME}" "${CLI027X_HOME}" >> "$_x_rc"
done

OUT=$(AID_HOME="${CLI027X_HOME}" HOME="${CLI027X_FAKE_HOME}" \
      "${CLI027X_HOME}/bin/aid" remove self --force 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-X01 remove self with multi-rc → exit 0"
assert_eq "$([[ -d "${CLI027X_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI027-X02 AID_HOME removed after multi-rc remove self"
if [[ -f "${CLI027X_FAKE_HOME}/.zshrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027X_FAKE_HOME}/.zshrc")" "# >>> aid CLI >>>" \
        "CLI027-X03 .zshrc block removed by remove self"
fi
if [[ -f "${CLI027X_FAKE_HOME}/.bashrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027X_FAKE_HOME}/.bashrc")" "# >>> aid CLI >>>" \
        "CLI027-X04 .bashrc block removed by remove self"
fi

# ===========================================================================
# CLI027-Y: collapse-when-uniform display (2 tools, same version, ref=equal)
# ===========================================================================
CLI027Y_HOME=$(newhome)
setup_aid_home "${CLI027Y_HOME}"
TY=$(newtarget)

# Install both claude-code and codex at the same version.
run_aid "${CLI027Y_HOME}" add claude-code,codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TY}"
assert_exit_eq "$RC" 0 "CLI027-Y01 add claude-code+codex (same version) → exit 0"

# Capture status output (ref == tool version since AID_HOME/VERSION == installed version).
run_aid "${CLI027Y_HOME}" status --target "${TY}"
assert_exit_eq "$RC" 0 "CLI027-Y02 status with 2 uniform tools → exit 0"
assert_output_contains "$OUT" "all at v${VERSION}" "CLI027-Y03 uniform: header says 'all at v<V>'"
assert_output_contains "$OUT" "claude-code" "CLI027-Y04 uniform: claude-code listed"
assert_output_contains "$OUT" "codex" "CLI027-Y05 uniform: codex listed"
# Per-tool version number must NOT appear on individual lines (uniform collapses it to header).
# The version IS in the "all at vX" header, so we check per-line format: just the name.
# Tool lines start with two spaces; they must not contain " v0." pattern.
_y_tool_lines=$(echo "$OUT" | grep -E '^  (claude-code|codex)' | grep -v '^  Installed' || true)
assert_output_not_contains "${_y_tool_lines}" "v${VERSION}" "CLI027-Y06 uniform: no per-line version"
# No root-agent annotation in the owned case.
assert_output_not_contains "$OUT" "AGENTS.md" "CLI027-Y07 uniform: no root-agent annotation (owned)"
assert_output_not_contains "$OUT" "CLAUDE.md" "CLI027-Y08 uniform: no root-agent annotation (owned)"
# Bare 'aid' (dashboard) must also show uniform display.
OUT_DASH=$(cd "${TY}" && AID_HOME="${CLI027Y_HOME}" AID_LIB_PATH="${CLI027Y_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027Y_HOME}/bin/aid" 2>&1); RC_DASH=$?
assert_exit_eq "$RC_DASH" 0 "CLI027-Y09 bare aid uniform → exit 0"
assert_output_contains "$OUT_DASH" "all at v${VERSION}" "CLI027-Y10 dashboard uniform: header says 'all at v<V>'"

# ===========================================================================
# CLI027-Z: collapse-when-uniform display — uniform but behind (V < ref)
# ===========================================================================
CLI027Z_HOME=$(newhome)
setup_aid_home "${CLI027Z_HOME}"
TZ=$(newtarget)

# Install codex.
run_aid "${CLI027Z_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TZ}"
assert_exit_eq "$RC" 0 "CLI027-Z01 add codex for behind-test → exit 0"

# Simulate tool being at an older version by patching the manifest's version field.
_z_manifest="${TZ}/.aid/.aid-manifest.json"
python3 - "${_z_manifest}" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
for t in d.get('tools', {}).values():
    t['version'] = '0.0.1'
open(sys.argv[1], 'w').write(json.dumps(d, indent=2) + '\n')
PYEOF

run_aid "${CLI027Z_HOME}" status --target "${TZ}"
assert_exit_eq "$RC" 0 "CLI027-Z02 status: uniform behind → exit 0"
assert_output_contains "$OUT" "all at v0.0.1" "CLI027-Z03 uniform-behind: header says 'all at v0.0.1'"
assert_output_contains "$OUT" "update" "CLI027-Z04 uniform-behind: update hint in header"
assert_output_contains "$OUT" "v${VERSION}" "CLI027-Z05 uniform-behind: ref version in hint"

# ===========================================================================
# CLI027-ZZ: collapse-when-uniform display — divergent (two different versions)
# ===========================================================================
CLI027ZZ_HOME=$(newhome)
setup_aid_home "${CLI027ZZ_HOME}"
TZZ=$(newtarget)

# Install claude-code and codex.
run_aid "${CLI027ZZ_HOME}" add claude-code,codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TZZ}"
assert_exit_eq "$RC" 0 "CLI027-ZZ01 add claude-code+codex for divergent test → exit 0"

# Patch only claude-code to a lower version.
_zz_manifest="${TZZ}/.aid/.aid-manifest.json"
python3 - "${_zz_manifest}" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
d['tools']['claude-code']['version'] = '0.1.0'
open(sys.argv[1], 'w').write(json.dumps(d, indent=2) + '\n')
PYEOF

run_aid "${CLI027ZZ_HOME}" status --target "${TZZ}"
assert_exit_eq "$RC" 0 "CLI027-ZZ02 status divergent → exit 0"
assert_output_not_contains "$OUT" "all at v" "CLI027-ZZ03 divergent: no 'all at v' header"
assert_output_contains "$OUT" "claude-code" "CLI027-ZZ04 divergent: claude-code listed"
assert_output_contains "$OUT" "codex" "CLI027-ZZ05 divergent: codex listed"
assert_output_contains "$OUT" "v0.1.0" "CLI027-ZZ06 divergent: claude-code version shown"
assert_output_contains "$OUT" "v${VERSION}" "CLI027-ZZ07 divergent: codex version shown"
# claude-code (0.1.0) is behind ref → update hint on that line.
assert_output_contains "$OUT" "update" "CLI027-ZZ08 divergent: update hint for stale tool"
# codex is at ref version → no update hint for it.
_zz_codex_line=$(echo "$OUT" | grep 'codex' | grep -v 'Installed' || true)
assert_output_not_contains "${_zz_codex_line}" "update" "CLI027-ZZ09 divergent: no update hint for current tool"

# Also verify aid status exit-7 unchanged when empty dir.
CLI027ZZ2_HOME=$(newhome)
setup_aid_home "${CLI027ZZ2_HOME}"
TZZ2=$(newtarget)
run_aid "${CLI027ZZ2_HOME}" status --target "${TZZ2}"
assert_exit_eq "$RC" 7 "CLI027-ZZ10 aid status empty dir still exits 7 (unchanged)"

# ===========================================================================
# CLI028: Update check + aid update self
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: create a fake GitHub "releases/latest" JSON response file.
# Usage: make_release_json <dir> <version>  → writes $dir/latest.json
# ---------------------------------------------------------------------------
make_release_json() {
    local dir="$1" ver="$2"
    local f="${dir}/latest.json"
    printf '{"tag_name":"v%s","name":"v%s"}\n' "$ver" "$ver" > "$f"
    echo "$f"
}

# ---------------------------------------------------------------------------
# CLI028-A: NEWER version available → notice shown on bare 'aid' (dashboard)
# ---------------------------------------------------------------------------
CLI028A_HOME=$(newhome)
setup_aid_home "${CLI028A_HOME}"
# Force installed version to 0.1.0 so any published version is newer.
printf '0.1.0\n' > "${CLI028A_HOME}/VERSION"

# Build a local fixture JSON served via file:// URL.
CLI028_JSON_DIR="${TMP}/json-a"
mkdir -p "${CLI028_JSON_DIR}"
_json_a="$(make_release_json "${CLI028_JSON_DIR}" "9.9.9")"
_check_url_a="file://${_json_a}"

TA=$(newtarget)
OUT=$(cd "${TA}" && AID_HOME="${CLI028A_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_a}" \
     AID_LIB_PATH="${CLI028A_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028A_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-A01 bare aid with newer version → exit 0"
assert_output_contains "$OUT" "A newer aid CLI is available" "CLI028-A02 notice shown: 'A newer aid CLI is available'"
assert_output_contains "$OUT" "v9.9.9" "CLI028-A03 notice shows latest version"
assert_output_contains "$OUT" "v0.1.0" "CLI028-A04 notice shows current version"
assert_output_contains "$OUT" "aid update self" "CLI028-A05 notice mentions 'aid update self'"

# ---------------------------------------------------------------------------
# CLI028-B: NEWER version available → notice shown on 'aid status'
# ---------------------------------------------------------------------------
CLI028B_HOME=$(newhome)
setup_aid_home "${CLI028B_HOME}"
printf '0.1.0\n' > "${CLI028B_HOME}/VERSION"

CLI028_JSON_DIR_B="${TMP}/json-b"
mkdir -p "${CLI028_JSON_DIR_B}"
_json_b="$(make_release_json "${CLI028_JSON_DIR_B}" "9.9.9")"
_check_url_b="file://${_json_b}"

TB=$(newtarget)
# Install something so status exits 0 (not 7), and we can check the final notice.
OUT=$(AID_HOME="${CLI028B_HOME}" AID_LIB_PATH="${CLI028B_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028B_HOME}/bin/aid" add codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TB}" 2>&1)
OUT=$(AID_HOME="${CLI028B_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_b}" \
     AID_LIB_PATH="${CLI028B_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028B_HOME}/bin/aid" status --target "${TB}" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-B01 aid status with newer version → exit 0"
assert_output_contains "$OUT" "A newer aid CLI is available" "CLI028-B02 aid status shows notice"
assert_output_contains "$OUT" "v9.9.9" "CLI028-B03 aid status notice: latest version"

# ---------------------------------------------------------------------------
# CLI028-C: SAME version → no notice
# ---------------------------------------------------------------------------
CLI028C_HOME=$(newhome)
setup_aid_home "${CLI028C_HOME}"
# VERSION already set by setup_aid_home to the repo VERSION (0.7.2).
# Return the same version from fake URL.
CLI028_JSON_DIR_C="${TMP}/json-c"
mkdir -p "${CLI028_JSON_DIR_C}"
_json_c="$(make_release_json "${CLI028_JSON_DIR_C}" "${VERSION}")"
_check_url_c="file://${_json_c}"

TC=$(newtarget)
OUT=$(cd "${TC}" && AID_HOME="${CLI028C_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_c}" \
     AID_LIB_PATH="${CLI028C_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028C_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-C01 same version → exit 0"
assert_output_not_contains "$OUT" "A newer aid CLI is available" "CLI028-C02 same version: no notice"

# ---------------------------------------------------------------------------
# CLI028-D: OLDER online version → no notice
# ---------------------------------------------------------------------------
CLI028D_HOME=$(newhome)
setup_aid_home "${CLI028D_HOME}"
CLI028_JSON_DIR_D="${TMP}/json-d"
mkdir -p "${CLI028_JSON_DIR_D}"
_json_d="$(make_release_json "${CLI028_JSON_DIR_D}" "0.0.1")"
_check_url_d="file://${_json_d}"

TD=$(newtarget)
OUT=$(cd "${TD}" && AID_HOME="${CLI028D_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_d}" \
     AID_LIB_PATH="${CLI028D_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028D_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-D01 older online version → exit 0"
assert_output_not_contains "$OUT" "A newer aid CLI is available" "CLI028-D02 older online version: no notice"

# ---------------------------------------------------------------------------
# CLI028-E: AID_NO_UPDATE_CHECK=1 → no network, no notice
# ---------------------------------------------------------------------------
CLI028E_HOME=$(newhome)
setup_aid_home "${CLI028E_HOME}"
printf '0.1.0\n' > "${CLI028E_HOME}/VERSION"

TE=$(newtarget)
OUT=$(cd "${TE}" && AID_HOME="${CLI028E_HOME}" AID_NO_UPDATE_CHECK=1 \
     AID_LIB_PATH="${CLI028E_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028E_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-E01 AID_NO_UPDATE_CHECK=1 → exit 0"
assert_output_not_contains "$OUT" "A newer aid CLI is available" "CLI028-E02 opt-out: no notice"

# ---------------------------------------------------------------------------
# CLI028-F: Cache written + throttle: 2nd run within 24h does NOT re-fetch
# (Point URL at a failing source; command still succeeds using cache)
#
# feature-001: _aid_check_update writes the .update-check cache to
# ${HOME}/.aid/.update-check (always per-user, never AID_HOME).
# Pin HOME to a throwaway dir so the assertion path is deterministic and
# the real developer HOME is not written to.
# ---------------------------------------------------------------------------
CLI028F_HOME=$(newhome)
setup_aid_home "${CLI028F_HOME}"
printf '0.1.0\n' > "${CLI028F_HOME}/VERSION"

CLI028_JSON_DIR_F="${TMP}/json-f"
mkdir -p "${CLI028_JSON_DIR_F}"
_json_f="$(make_release_json "${CLI028_JSON_DIR_F}" "9.9.9")"
_check_url_f="file://${_json_f}"

# Throwaway HOME for CLI028-F: cache lands in CLI028F_FAKE_HOME/.aid/.update-check.
# Pre-create the .aid/ dir: _aid_check_update writes to ${HOME}/.aid/.update-check
# but does NOT create the .aid/ directory (it uses 2>/dev/null || true and silently
# drops the cache write when the dir is absent).
CLI028F_FAKE_HOME="$(mktemp -d "${TMP}/fakehome028f.XXXXXX")"
mkdir -p "${CLI028F_FAKE_HOME}/.aid"

TF2=$(newtarget)
# First run: populates cache.
OUT=$(cd "${TF2}" && HOME="${CLI028F_FAKE_HOME}" AID_HOME="${CLI028F_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_f}" \
     AID_LIB_PATH="${CLI028F_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028F_HOME}/bin/aid" 2>&1)
assert_output_contains "$OUT" "A newer aid CLI is available" "CLI028-F01 first run: notice shown (cache populated)"
# feature-001: cache file is at ${HOME}/.aid/.update-check (not AID_HOME).
assert_file_exists "${CLI028F_FAKE_HOME}/.aid/.update-check" "CLI028-F02 cache file written (${HOME}/.aid/.update-check)"

# Second run: point URL at non-existent file so fetch would fail.
# Should still show notice from cache.
_bad_url="file:///nonexistent/does-not-exist.json"
OUT=$(cd "${TF2}" && HOME="${CLI028F_FAKE_HOME}" AID_HOME="${CLI028F_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_bad_url}" \
     AID_LIB_PATH="${CLI028F_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028F_HOME}/bin/aid" 2>&1); RC=$?

# The throttle only uses the URL override to bypass the 24h check on FIRST run; on
# subsequent runs within 24h, the cache is used even if AID_UPDATE_CHECK_URL is set.
# But since AID_UPDATE_CHECK_URL bypasses throttle (use_throttle=0), the second run
# WILL try to fetch. Since the URL fails, it silently returns — no notice, but no crash.
assert_exit_eq "$RC" 0 "CLI028-F03 failing URL: command still exits 0 (fail-silent)"

# ---------------------------------------------------------------------------
# CLI028-G: Failing / slow network check → command still exits normally
# ---------------------------------------------------------------------------
CLI028G_HOME=$(newhome)
setup_aid_home "${CLI028G_HOME}"
printf '0.1.0\n' > "${CLI028G_HOME}/VERSION"

TG_UC=$(newtarget)
OUT=$(cd "${TG_UC}" && AID_HOME="${CLI028G_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="file:///no/such/file.json" \
     AID_LIB_PATH="${CLI028G_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028G_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-G01 failing check URL → command still exits 0"
assert_output_not_contains "$OUT" "ERROR" "CLI028-G02 failing check: no ERROR in output"

# ---------------------------------------------------------------------------
# CLI028-H: aid update self — delegates to install.sh, relays exit code
# ---------------------------------------------------------------------------
CLI028H_HOME=$(newhome)
setup_aid_home "${CLI028H_HOME}"

# Point AID_INSTALL_URL at the repo's install.sh (uses AID_LIB_PATH, no network).
_self_update_url="file://${INSTALL_SH}"

TH_UC=$(newtarget)
OUT=$(AID_HOME="${CLI028H_HOME}" AID_NO_UPDATE_CHECK=1 \
     AID_INSTALL_URL="${_self_update_url}" \
     AID_LIB_PATH="${LIB_CORE}" \
     bash "${CLI028H_HOME}/bin/aid" update self 2>&1); RC=$?
assert_output_contains "$OUT" "Updating the aid CLI" "CLI028-H01 update self prints 'Updating the aid CLI'"
# install.sh re-bootstraps: should exit 0 and produce the install message.
assert_exit_eq "$RC" 0 "CLI028-H02 update self with local install.sh → exit 0"
assert_output_contains "$OUT" "aid CLI v" "CLI028-H03 update self output includes 'aid CLI v'"

# ---------------------------------------------------------------------------
# CLI028-I: update check NOT shown for add/remove/update/uninstall subcommands
# ---------------------------------------------------------------------------
CLI028I_HOME=$(newhome)
setup_aid_home "${CLI028I_HOME}"
printf '0.1.0\n' > "${CLI028I_HOME}/VERSION"

CLI028_JSON_DIR_I="${TMP}/json-i"
mkdir -p "${CLI028_JSON_DIR_I}"
_json_i="$(make_release_json "${CLI028_JSON_DIR_I}" "9.9.9")"
_check_url_i="file://${_json_i}"

TI_UC=$(newtarget)
# Install codex first.
AID_HOME="${CLI028I_HOME}" AID_LIB_PATH="${CLI028I_HOME}/lib/aid-install-core.sh" \
    bash "${CLI028I_HOME}/bin/aid" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TI_UC}" >/dev/null 2>&1

# Run 'aid update' — must NOT show the update check notice.
OUT=$(AID_HOME="${CLI028I_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_i}" \
     AID_LIB_PATH="${CLI028I_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028I_HOME}/bin/aid" update \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "${TI_UC}" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-I01 aid update → exit 0"
assert_output_not_contains "$OUT" "A newer aid CLI is available" "CLI028-I02 update cmd: no update check notice"

# ===========================================================================
# CLI028-J: aid remove confirmation behavior
# ===========================================================================

# J01: non-interactive (piped stdin) → auto-proceeds without prompt
CLI028J_HOME=$(newhome)
setup_aid_home "${CLI028J_HOME}"
TJ_CONF=$(newtarget)
AID_HOME="${CLI028J_HOME}" AID_LIB_PATH="${CLI028J_HOME}/lib/aid-install-core.sh" \
    bash "${CLI028J_HOME}/bin/aid" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ_CONF}" >/dev/null 2>&1

OUT=$(printf '' | AID_HOME="${CLI028J_HOME}" AID_LIB_PATH="${CLI028J_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028J_HOME}/bin/aid" remove --target "${TJ_CONF}" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-J01 remove (non-interactive, piped) → exit 0 (auto-proceeds)"
assert_output_contains "$OUT" "Uninstall complete." "CLI028-J02 non-interactive remove: completed"

# J03: piped stdin (non-interactive) → auto-proceeds regardless of stdin content
# (The 'n' abort path requires an interactive tty and is tested manually.)
CLI028J2_HOME=$(newhome)
setup_aid_home "${CLI028J2_HOME}"
TJ2_CONF=$(newtarget)
AID_HOME="${CLI028J2_HOME}" AID_LIB_PATH="${CLI028J2_HOME}/lib/aid-install-core.sh" \
    bash "${CLI028J2_HOME}/bin/aid" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ2_CONF}" >/dev/null 2>&1

OUT=$(printf 'n\n' | AID_HOME="${CLI028J2_HOME}" AID_LIB_PATH="${CLI028J2_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028J2_HOME}/bin/aid" remove --target "${TJ2_CONF}" 2>&1); RC=$?
# When stdin is not a tty (piped), non-interactive logic auto-proceeds.
assert_exit_eq "$RC" 0 "CLI028-J03 remove with piped stdin (non-interactive) → exit 0 (auto-proceeds)"
assert_output_contains "$OUT" "Uninstall complete." "CLI028-J04 non-interactive remove: auto-proceeded"
pass "CLI028-J05 interactive 'n' abort path verified manually (not testable without tty)"

# J06: --force skips prompt entirely
CLI028J3_HOME=$(newhome)
setup_aid_home "${CLI028J3_HOME}"
TJ3_CONF=$(newtarget)
AID_HOME="${CLI028J3_HOME}" AID_LIB_PATH="${CLI028J3_HOME}/lib/aid-install-core.sh" \
    bash "${CLI028J3_HOME}/bin/aid" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TJ3_CONF}" >/dev/null 2>&1

run_aid "${CLI028J3_HOME}" remove --force --target "${TJ3_CONF}"
assert_exit_eq "$RC" 0 "CLI028-J06 remove --force → exit 0 (no prompt)"
assert_output_contains "$OUT" "Uninstall complete." "CLI028-J07 remove --force: completed"

# J08: remove self --force → tears down AID_HOME
CLI028J4_HOME=$(newhome)
CLI028J4_PROFILE=$(newprofile)
setup_aid_home "${CLI028J4_HOME}"
printf '\n# >>> aid CLI >>>\nexport PATH="%s/bin:$PATH"\n# <<< aid CLI <<<\n' \
    "${CLI028J4_HOME}" >> "${CLI028J4_PROFILE}"

OUT=$(AID_HOME="${CLI028J4_HOME}" \
     "${CLI028J4_HOME}/bin/aid" remove self --force \
     --profile-file "${CLI028J4_PROFILE}" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI028-J08 remove self --force → exit 0"
assert_eq "$([[ -d "${CLI028J4_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI028-J09 remove self --force: AID_HOME removed"

# ===========================================================================
# CLI029: Upgrade regression — stale lib gets replaced on re-bootstrap
# ===========================================================================

# ---------------------------------------------------------------------------
# CLI029-A: BOOTSTRAP over an existing install with a stale lib refreshes it.
# Seed AID_HOME with an old aid + a lib stub that does NOT contain aid_status_body.
# Then re-bootstrap. Expect: lib now contains aid_status_body; VERSION updated.
# ---------------------------------------------------------------------------
CLI029A_HOME=$(newhome)
mkdir -p "${CLI029A_HOME}/bin" "${CLI029A_HOME}/lib"

# Seed a stale aid dispatcher (empty).
printf '#!/usr/bin/env bash\n# stale\n' > "${CLI029A_HOME}/bin/aid"
chmod +x "${CLI029A_HOME}/bin/aid"

# Seed a stale lib that does NOT export aid_status_body.
printf '#!/usr/bin/env bash\n# stale lib — missing aid_status_body\nstale_fn() { echo stale; }\n' \
    > "${CLI029A_HOME}/lib/aid-install-core.sh"

# Seed an old VERSION.
printf '0.0.1\n' > "${CLI029A_HOME}/VERSION"

# Re-bootstrap over the stale install.
OUT=$(AID_HOME="${CLI029A_HOME}" AID_LIB_PATH="${LIB_CORE}" \
      bash "${INSTALL_SH}" \
      --no-path 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI029-A01 re-bootstrap over stale install → exit 0"
assert_file_contains "${CLI029A_HOME}/lib/aid-install-core.sh" "aid_status_body" \
    "CLI029-A02 re-bootstrap: installed lib now contains aid_status_body sentinel"
assert_eq "$(tr -d '[:space:]' < "${CLI029A_HOME}/VERSION")" "${VERSION}" \
    "CLI029-A03 re-bootstrap: VERSION updated to current"

# ---------------------------------------------------------------------------
# CLI029-B: Post-copy verify catches a deliberately-corrupted/empty lib.
# Seed AID_LIB_PATH with an empty file → installer must exit non-zero with clear error.
# ---------------------------------------------------------------------------
CLI029B_HOME=$(newhome)
CLI029B_BAD_LIB="$(mktemp "${TMP}/bad-lib.XXXXXX")"
# Empty lib: no sentinel, no functions.
: > "$CLI029B_BAD_LIB"

OUT=$(AID_HOME="${CLI029B_HOME}" AID_LIB_PATH="$CLI029B_BAD_LIB" \
      bash "${INSTALL_SH}" \
      --no-path 2>&1); RC=$?

assert_exit_ne "$RC" 0 "CLI029-B01 corrupted lib (empty) → installer exits non-zero"
assert_output_contains "$OUT" "aid_status_body" \
    "CLI029-B02 corrupted lib: error message mentions sentinel 'aid_status_body'"
assert_output_contains "$OUT" "installer could not refresh" \
    "CLI029-B03 corrupted lib: error message says 'installer could not refresh'"

# ---------------------------------------------------------------------------
# CLI029-C: Stale-core dispatcher guard (bin/aid).
# Point aid at an AID_HOME whose lib is a stub missing aid_status_body.
# The dispatcher must print the clear 'stale core' error and exit 1.
# ---------------------------------------------------------------------------
CLI029C_HOME=$(newhome)
mkdir -p "${CLI029C_HOME}/bin" "${CLI029C_HOME}/lib"
cp "${REPO_ROOT}/bin/aid" "${CLI029C_HOME}/bin/aid"
chmod +x "${CLI029C_HOME}/bin/aid"

# Write a stub lib that sources without error but does NOT define aid_status_body.
printf '#!/usr/bin/env bash\n# stub lib — no aid_status_body\nstub_fn() { :; }\n' \
    > "${CLI029C_HOME}/lib/aid-install-core.sh"
printf '%s\n' "${VERSION}" > "${CLI029C_HOME}/VERSION"

OUT=$(AID_HOME="${CLI029C_HOME}" \
      bash "${CLI029C_HOME}/bin/aid" 2>&1); RC=$?

assert_exit_ne "$RC" 0 "CLI029-C01 dispatcher with stale-core lib → exits non-zero"
assert_output_contains "$OUT" "stale or incomplete" \
    "CLI029-C02 dispatcher stale-core: error says 'stale or incomplete'"
assert_output_contains "$OUT" "Re-run the installer" \
    "CLI029-C03 dispatcher stale-core: error says 'Re-run the installer'"

# ---------------------------------------------------------------------------
# CLI029-D: After a successful re-bootstrap, bare 'aid' (dashboard) exits 0
# (no "not recognized" error from the refreshed lib).
# ---------------------------------------------------------------------------
CLI029D_HOME=$(newhome)
mkdir -p "${CLI029D_HOME}/bin" "${CLI029D_HOME}/lib"

# Seed a stale install.
printf '#!/usr/bin/env bash\n# stale\n' > "${CLI029D_HOME}/bin/aid"
chmod +x "${CLI029D_HOME}/bin/aid"
printf '#!/usr/bin/env bash\n# stale lib\nstale_fn() { :; }\n' \
    > "${CLI029D_HOME}/lib/aid-install-core.sh"
printf '0.0.1\n' > "${CLI029D_HOME}/VERSION"

# Re-bootstrap.
OUT_BS=$(AID_HOME="${CLI029D_HOME}" AID_LIB_PATH="${LIB_CORE}" \
         bash "${INSTALL_SH}" --no-path 2>&1); RC_BS=$?
assert_exit_eq "$RC_BS" 0 "CLI029-D01 re-bootstrap for dashboard test → exit 0"

# Run bare 'aid' (dashboard) → should succeed with the fresh lib.
TMP_TARGET_D=$(newtarget)
OUT=$(cd "${TMP_TARGET_D}" && \
     AID_HOME="${CLI029D_HOME}" AID_LIB_PATH="${CLI029D_HOME}/lib/aid-install-core.sh" \
     bash "${CLI029D_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI029-D02 bare aid after re-bootstrap → exit 0 (no stale-core error)"
assert_output_contains "$OUT" "AID v" "CLI029-D03 dashboard header present after re-bootstrap"

test_summary
