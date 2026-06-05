#!/usr/bin/env bash
# test-aid-cli.sh — Task 027: Integration tests for the persistent Bash `aid` CLI.
#
# Tests bootstrap, PATH wiring, all subcommands, CONVENIENCE mode, LEGACY back-compat,
# and self-uninstall via the bin/aid dispatcher + install.sh BOOTSTRAP/CONVENIENCE paths.
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
# CLI027-D: self-uninstall removes AID_HOME + PATH block (fence-based)
# ===========================================================================
CLI027D_HOME=$(newhome)
CLI027D_PROFILE=$(newprofile)
setup_aid_home "${CLI027D_HOME}"
# Write a fenced PATH block to the profile.
printf '\n# >>> aid CLI >>>\nexport PATH="%s/bin:$PATH"\n# <<< aid CLI <<<\n' \
    "${CLI027D_HOME}" >> "${CLI027D_PROFILE}"

OUT=$(AID_HOME="${CLI027D_HOME}" \
      "${CLI027D_HOME}/bin/aid" self-uninstall --force \
      --profile-file "${CLI027D_PROFILE}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-D01 self-uninstall --force → exit 0"
assert_eq "$([[ -d "${CLI027D_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI027-D02 AID_HOME removed after self-uninstall"
# PATH block must be removed.
if [[ -f "${CLI027D_PROFILE}" ]]; then
    assert_output_not_contains "$(cat "${CLI027D_PROFILE}")" "# >>> aid CLI >>>" \
        "CLI027-D03 PATH fence block removed from profile after self-uninstall"
fi
# Expected message.
assert_output_contains "$OUT" "aid CLI removed" "CLI027-D04 self-uninstall message"

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
assert_output_contains "$OUT" "Installed tools:" "CLI027-F04 status shows 'Installed tools:'"
assert_output_contains "$OUT" "codex" "CLI027-F05 status lists codex"
assert_output_contains "$OUT" "v${VERSION}" "CLI027-F06 status shows tool version"
assert_output_contains "$OUT" "AGENTS.md" "CLI027-F07 status shows root agent file"

# ===========================================================================
# CLI027-G: bare `aid` (no args) → status (alias)
# ===========================================================================
CLI027G_HOME=$(newhome)
setup_aid_home "${CLI027G_HOME}"
TG=$(newtarget)

# Run from TG (empty dir without manifest) so status consistently returns exit 7.
OUT=$(cd "${TG}" && AID_HOME="${CLI027G_HOME}" AID_LIB_PATH="${CLI027G_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G_HOME}/bin/aid" 2>&1); RC=$?
# Should be status of cwd — since TG has no manifest, exit 7.
assert_exit_eq "$RC" 7 "CLI027-G01 bare aid → status (exit 7 since no manifest in cwd)"

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
# CLI027-K: aid uninstall (all tools)
# ===========================================================================
CLI027K_HOME=$(newhome)
setup_aid_home "${CLI027K_HOME}"
TK=$(newtarget)

run_aid "${CLI027K_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "${TK}"
assert_exit_eq "$RC" 0 "CLI027-K01 add for uninstall test → exit 0"

run_aid "${CLI027K_HOME}" uninstall --target "${TK}"
assert_exit_eq "$RC" 0 "CLI027-K02 aid uninstall all → exit 0"
assert_eq "$([[ -d "${TK}/.codex" ]] && echo exists || echo gone)" "gone" \
    "CLI027-K03 .codex/ removed after uninstall"
assert_eq "$([[ -f "${TK}/AGENTS.md" ]] && echo exists || echo gone)" "gone" \
    "CLI027-K04 AGENTS.md removed after uninstall"
assert_output_contains "$OUT" "Uninstall complete." "CLI027-K05 uninstall reports 'Uninstall complete.'"

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
# CLI027-N: aid help → exit 0, prints Usage
# ===========================================================================
CLI027N_HOME=$(newhome)
setup_aid_home "${CLI027N_HOME}"

run_aid "${CLI027N_HOME}" help
assert_exit_eq "$RC" 0 "CLI027-N01 aid help → exit 0"
assert_output_contains "$OUT" "Usage" "CLI027-N02 aid help prints 'Usage'"
assert_output_contains "$OUT" "aid" "CLI027-N03 aid help mentions 'aid'"

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
assert_output_contains "$OUT" "aid CLI removed" "CLI027-R04 exact self-uninstall message string"

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
# CLI027-X: self-uninstall removes fenced block from ALL wired files
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
      "${CLI027X_HOME}/bin/aid" self-uninstall --force 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-X01 self-uninstall with multi-rc → exit 0"
assert_eq "$([[ -d "${CLI027X_HOME}" ]] && echo exists || echo gone)" "gone" \
    "CLI027-X02 AID_HOME removed after multi-rc self-uninstall"
if [[ -f "${CLI027X_FAKE_HOME}/.zshrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027X_FAKE_HOME}/.zshrc")" "# >>> aid CLI >>>" \
        "CLI027-X03 .zshrc block removed by self-uninstall"
fi
if [[ -f "${CLI027X_FAKE_HOME}/.bashrc" ]]; then
    assert_output_not_contains "$(cat "${CLI027X_FAKE_HOME}/.bashrc")" "# >>> aid CLI >>>" \
        "CLI027-X04 .bashrc block removed by self-uninstall"
fi

test_summary
