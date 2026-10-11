#!/usr/bin/env bash
# test-aid-cli.sh — Task 027: Integration tests for the persistent Bash `aid` CLI.
#
# Tests bootstrap, PATH wiring, all subcommands, CONVENIENCE mode, LEGACY back-compat,
# and remove self via the bin/aid dispatcher + install.sh BOOTSTRAP/CONVENIENCE paths.
#
# COVERS: install.sh
# COVERS: bin/aid
# COVERS: lib/aid-install-core.sh
# COVERS: release.sh
# COVERS: tests/lib/bundle.sh
# COVERS: canonical/skills
# COVERS: canonical/aid
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
source "$(dirname "${BASH_SOURCE[0]}")/../lib/sandbox.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/bundle.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"

[[ -f "$INSTALL_SH" ]] || { echo "ERROR: install.sh not found at $INSTALL_SH" >&2; exit 1; }
[[ -f "$BIN_AID" ]]    || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_CORE" ]]   || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_CORE" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ISOLATION (see memory: aid-scan-tests-must-pin-home): pin HOME for the WHOLE suite so
# home-relative writes land in a throwaway, never the developer's real $HOME. Two classes
# of write would otherwise escape: the update-check cache (~/.aid/.update-check, written by
# the CLI028-* tests that set AID_NO_UPDATE_CHECK=0 with a fake 9.9.9 release) and the
# PATH-wiring rc files (~/.zshrc, ~/.bashrc, ~/.profile in the CLI027-S/T/U bootstrap tests).
# Per-invocation HOME overrides (e.g. CLI028-F, CLI027-S) still win for their own cases.
# A crash mid-suite can't leak because HOME is redirected for the entire process, not cleaned
# up after. An end-of-suite canary (sandbox_assert_aid_untouched) asserts the real HOME's
# .aid subtree was untouched.
sandbox_pin_home
mkdir -p "${HOME}/.aid"

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

aid_test_stage_bundle "${FIXTURE_DIR}" >/dev/null || { echo "ERROR: shared release staging failed" >&2; exit 1; }

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }
newhome()   { mktemp -d "${TMP}/home.XXXXXX"; }
newprofile() { mktemp "${TMP}/profile.XXXXXX"; }

# tree_snapshot <dir>: hash the relative paths, object types and file bytes so a
# rejected write cannot hide behind an unchanged manifest with other changed files.
tree_snapshot() {
    python3 - "$1" <<'PY'
import hashlib, os, stat, sys
root=os.path.abspath(sys.argv[1]); rows=[]
for here, dirs, files in os.walk(root, followlinks=False):
    dirs.sort(); files.sort()
    for name in dirs + files:
        path=os.path.join(here,name); rel=os.path.relpath(path,root).replace(os.sep,'/')
        if os.path.islink(path): rows.append('L '+rel+' '+os.readlink(path))
        elif os.path.isdir(path): rows.append('D '+rel)
        else:
            with open(path,'rb') as stream: digest=hashlib.sha256(stream.read()).hexdigest()
            rows.append('F '+rel+' '+digest)
print(hashlib.sha256(('\n'.join(rows)+'\n').encode()).hexdigest())
PY
}

manifest_versions_are_uniform() {
    python3 - "$1" <<'PY'
import json, sys
try:
    m=json.load(open(sys.argv[1], encoding='utf-8')); version=m['aid_version']; found=[]
    def walk(value):
        if isinstance(value,dict):
            if 'version' in value: found.append(value['version'])
            for child in value.values(): walk(child)
        elif isinstance(value,list):
            for child in value: walk(child)
    walk(m)
    raise SystemExit(0 if found and all(v == version for v in found) else 1)
except Exception:
    raise SystemExit(1)
PY
}

build_different_version_bundle() {
    local dest="$1" tool="$2" other="$3" old="$4" tool_root
    tool_root=".$tool"
    mkdir -p "$dest/shared" "$dest/tool"
    tar -xzf "${FIXTURE_DIR}/aid-shared-v${old}.tar.gz" -C "$dest/shared"
    tar -xzf "${FIXTURE_DIR}/aid-${tool}-v${old}.tar.gz" -C "$dest/tool"
    python3 - "$dest/shared/aid-payload.conf" "$old" "$other" <<'PY'
from pathlib import Path
import sys
for raw in sys.argv[1:2]:
    path=Path(raw); data=path.read_text(); old=sys.argv[2]; new=sys.argv[3]
    if old not in data: raise SystemExit('fixture descriptor lacks source version')
    path.write_text(data.replace(old,new))
PY
    tar -czf "${dest}/aid-shared-v${other}.tar.gz" -C "$dest/shared" aid-payload.conf skills runtime
    tar -czf "${dest}/aid-${tool}-v${other}.tar.gz" -C "$dest/tool" aid-tool.conf "${tool_root}/agents"
}

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
# CLI027-E: aid status — empty dir → exit 0 + offer message (new behavior)
# ===========================================================================
CLI027E_HOME=$(newhome)
setup_aid_home "${CLI027E_HOME}"
T=$(newtarget)

run_aid "${CLI027E_HOME}" status --target "$T"
assert_exit_eq "$RC" 0 "CLI027-E01 aid status empty dir → exit 0 (offer-and-exit)"
assert_output_contains "$OUT" "no AID project here" "CLI027-E02 status empty dir prints offer message"
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
     --from-bundle "${FIXTURE_DIR}" \
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

# G01-G06: dir with .aid/ fixture → exit 0, dashboard blocks present.
# Per new behavior bare 'aid' in a dir with NO .aid/ shows the offer-and-exit-0 path;
# to keep testing the dashboard landing we provide a minimal .aid/ fixture so the
# repo-command path renders the header, description, no-tools message, and usage block.
CLI027G_HOME=$(newhome)
setup_aid_home "${CLI027G_HOME}"
TG=$(newtarget)
mkdir -p "${TG}/.aid"
printf 'format_version: 1\n' > "${TG}/.aid/settings.yml"

OUT=$(cd "${TG}" && AID_HOME="${CLI027G_HOME}" AID_LIB_PATH="${CLI027G_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI027-G01 bare aid in repo with .aid/ → exit 0 (dashboard)"
assert_output_contains "$OUT" "AID v${VERSION}" "CLI027-G02 dashboard header contains 'AID v<ver>'"
assert_output_contains "$OUT" "AI Integrated Development" "CLI027-G03 dashboard header contains description tag"
assert_output_contains "$OUT" "Install, update, and manage AID" "CLI027-G04 dashboard description line"
assert_output_contains "$OUT" "yet" "CLI027-G05 dashboard: no-tools dir shows friendly no-tools message"
assert_output_contains "$OUT" "aid add" "CLI027-G06 dashboard: usage block contains 'aid add'"

# G07-G12: project with tools → exit 0, all 4 blocks present.
CLI027G2_HOME=$(newhome)
setup_aid_home "${CLI027G2_HOME}"
TG2=$(newtarget)

# Install codex into TG2.
OUT_INSTALL=$(AID_HOME="${CLI027G2_HOME}" AID_LIB_PATH="${CLI027G2_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G2_HOME}/bin/aid" add codex \
     --from-bundle "${FIXTURE_DIR}" \
     --target "${TG2}" 2>&1); RC_INSTALL=$?
assert_exit_eq "$RC_INSTALL" 0 "CLI027-G07 pre-install codex for dashboard test → exit 0"

OUT=$(cd "${TG2}" && AID_HOME="${CLI027G2_HOME}" AID_LIB_PATH="${CLI027G2_HOME}/lib/aid-install-core.sh" \
     bash "${CLI027G2_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI027-G08 bare aid in project dir → exit 0"
assert_output_contains "$OUT" "AID v${VERSION}" "CLI027-G09 dashboard with tools: header shows version"
assert_output_contains "$OUT" "Installed tools (in" "CLI027-G10 dashboard with tools: shows 'Installed tools (in'"
assert_output_contains "$OUT" "codex" "CLI027-G11 dashboard with tools: codex listed"
assert_output_contains "$OUT" "aid add" "CLI027-G12 dashboard with tools: usage block present"

# G13: confirm `aid status` (explicit) exits 0 + offer message in empty dir — new behavior.
CLI027G3_HOME=$(newhome)
setup_aid_home "${CLI027G3_HOME}"
TG3=$(newtarget)

run_aid "${CLI027G3_HOME}" status --target "${TG3}"
assert_exit_eq "$RC" 0 "CLI027-G13 aid status (explicit) empty dir → exit 0 (offer-and-exit)"

# ===========================================================================
# CLI027-H: aid add <tool> + aid remove <tool>
# ===========================================================================
CLI027H_HOME=$(newhome)
setup_aid_home "${CLI027H_HOME}"
TH=$(newtarget)

run_aid "${CLI027H_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}" \
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
# CLI027-J: aid update (all-from-manifest; per-tool positional → exit 2; empty → CLI-only)
# ===========================================================================
CLI027J_HOME=$(newhome)
setup_aid_home "${CLI027J_HOME}"
TJ=$(newtarget)

# Install codex first.
run_aid "${CLI027J_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J01 add codex for update test → exit 0"

# FR10: per-tool positional on 'update' is now a usage error (exit 2).
run_aid "${CLI027J_HOME}" update codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J02 named aid update codex updates selected tool"
assert_output_not_contains "$OUT" "unexpected argument" "CLI027-J03 named aid update is accepted"

# Update all (no tool arg) — same version → still 0.
run_aid "${CLI027J_HOME}" update \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TJ}"
assert_exit_eq "$RC" 0 "CLI027-J04 aid update all tools → exit 0"

# FR10: Update on dir with no .aid/ → update CLI only (exit 0).
TJ_EMPTY=$(newtarget)
run_aid "${CLI027J_HOME}" update --target "${TJ_EMPTY}"
assert_exit_eq "$RC" 0 "CLI027-J05 aid update empty dir → exit 0 (CLI-only update)"

# ===========================================================================
# CLI027-K: aid remove (no arg, all tools) — with --force to skip prompt
# ===========================================================================
CLI027K_HOME=$(newhome)
setup_aid_home "${CLI027K_HOME}"
TK=$(newtarget)

run_aid "${CLI027K_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}" \
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
# CLI027-L: root-agent in-place merge honored on root agent file via `aid add`
#           (NEW contract: exit 0, no .aid-new, user content preserved)
# ===========================================================================
CLI027L_HOME=$(newhome)
setup_aid_home "${CLI027L_HOME}"
TL=$(newtarget)
printf 'User AGENTS.md pre-placed\n' > "${TL}/AGENTS.md"

run_aid "${CLI027L_HOME}" add codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TL}"
assert_exit_eq "$RC" 0 "CLI027-L01 aid add with pre-placed AGENTS.md → exit 0 (in-place merge)"
assert_eq "$([[ -f "${TL}/AGENTS.md.aid-new" ]] && echo exists || echo none)" "none" \
    "CLI027-L02 no AGENTS.md.aid-new sidecar (sidecar eliminated)"
assert_file_contains "${TL}/AGENTS.md" "User AGENTS.md" "CLI027-L03 user content preserved in AGENTS.md"
assert_output_not_contains "$OUT" "Install complete with warnings" "CLI027-L04 no warning banner"
assert_output_not_contains "$OUT" "pending-merge" "CLI027-L05 no pending-merge mention"
# The AID region MUST be injected even when the pre-placed file has no AID
# headings to anchor it (brownfield user file). Regression: previously the
# region was silently dropped, so AGENTS.md never gained AID instructions.
assert_file_contains "${TL}/AGENTS.md" "<!-- AID:BEGIN -->" "CLI027-L06 AID region injected into marker-less user AGENTS.md (no drop)"
assert_file_contains "${TL}/AGENTS.md" "<!-- AID:END -->" "CLI027-L07 AID region closing marker present"

# ===========================================================================
# CLI027-M: aid version → exit 0, prints version
# ===========================================================================
CLI027M_HOME=$(newhome)
setup_aid_home "${CLI027M_HOME}"

run_aid "${CLI027M_HOME}" version
assert_exit_eq "$RC" 0 "CLI027-M01 aid version → exit 0"
assert_output_contains "$OUT" "${VERSION}" "CLI027-M02 aid version prints version string"
_M_VERSION_SUBCMD_OUT="$OUT"

# ===========================================================================
# CLI027-M1: top-level bare `aid --version` / `-V` (task-008) → exit 0,
#            identical output to `aid version`. Regression: the pre-existing
#            add/remove/update `--version <v>` value-flag (release pin) is
#            unaffected -- it is only matched among the args AFTER the
#            subcommand, so the top-level bare-flag check (first arg only)
#            never shadows it.
# ===========================================================================
run_aid "${CLI027M_HOME}" --version
assert_exit_eq "$RC" 0 "CLI027-M1-01 aid --version → exit 0"
assert_output_contains "$OUT" "${VERSION}" "CLI027-M1-02 aid --version prints version string"
assert_eq "$OUT" "$_M_VERSION_SUBCMD_OUT" "CLI027-M1-03 aid --version output identical to 'aid version'"

run_aid "${CLI027M_HOME}" -V
assert_exit_eq "$RC" 0 "CLI027-M1-04 aid -V → exit 0"
assert_eq "$OUT" "$_M_VERSION_SUBCMD_OUT" "CLI027-M1-05 aid -V output identical to 'aid version'"

# Regression: subcommand `--version <v>` pin flag still requires (and parses) a
# value -- proves the top-level bare --version/-V check does not intercept it
# (SUBCMD is already "add" by the time this loop runs, not the bare first-arg
# check above).
run_aid "${CLI027M_HOME}" add --version
assert_exit_eq "$RC" 2 "CLI027-M1-06 'aid add --version' (no value) still errors -- pin flag unaffected"
assert_output_contains "$OUT" "--version requires a value" "CLI027-M1-07 pin flag value-required message unchanged"

# Regression (positive path): --version <v> together with --from-bundle
# correctly hits the PRE-EXISTING mutual-exclusivity guard (a --from-bundle
# install IS the pinned artifact; --version has nothing to resolve) -- proving
# the value was parsed and consumed by the same downstream logic as before,
# unaffected by the new top-level flag.
TM1=$(newtarget)
run_aid "${CLI027M_HOME}" add codex --version "${VERSION}" \
    --from-bundle "${FIXTURE_DIR}" --dry-run --target "${TM1}"
assert_exit_eq "$RC" 2 "CLI027-M1-08 add --version <v> + --from-bundle → exit 2 (pre-existing mutual-exclusivity guard, unaffected)"
assert_output_contains "$OUT" "mutually exclusive" "CLI027-M1-09 pin flag reaches the same downstream validation as before"

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
# Public subcommands must appear in general help (chat shipped without this line once).
for _cmd in status add update remove version dashboard projects chat; do
    assert_output_contains "$OUT" "aid ${_cmd}" "CLI027-N07b general help lists 'aid ${_cmd}'"
done
assert_output_not_contains "$OUT" "__migrate-repo" "CLI027-N07c general help omits the hidden migrate command"

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

run_aid "${CLI027N_HOME}" chat -h
assert_exit_eq "$RC" 0 "CLI027-N16 aid chat -h → exit 0"
assert_output_contains "$OUT" "aid chat register" "CLI027-N17 aid chat -h shows register"
assert_output_contains "$OUT" "aid chat heartbeat" "CLI027-N18 aid chat -h shows heartbeat"
assert_output_contains "$OUT" "aid chat node start" "CLI027-N19 aid chat -h shows node start"

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
     --from-bundle "${FIXTURE_DIR}" \
     --target "${TP}" 2>&1); RC=$?

assert_exit_eq "$RC" 0 "CLI027-P01 CONVENIENCE: install.sh add codex → exit 0"
# CLI must have been installed.
assert_file_exists "${CLI027P_HOME}/bin/aid" "CLI027-P02 CONVENIENCE: bin/aid installed"
# codex must have been installed in the project.
assert_dir_exists "${TP}/.codex" "CLI027-P03 CONVENIENCE: .codex/ created"
assert_file_exists "${TP}/AGENTS.md" "CLI027-P04 CONVENIENCE: AGENTS.md created"
assert_output_contains "$OUT" "Done." "CLI027-P05 CONVENIENCE: reports Done."

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
    --from-bundle "${FIXTURE_DIR}" \
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

# Also verify aid status exits 0 (offer-and-exit) when empty dir — new behavior.
CLI027ZZ2_HOME=$(newhome)
setup_aid_home "${CLI027ZZ2_HOME}"
TZZ2=$(newtarget)
run_aid "${CLI027ZZ2_HOME}" status --target "${TZZ2}"
assert_exit_eq "$RC" 0 "CLI027-ZZ10 aid status empty dir → exit 0 (offer-and-exit, new behavior)"

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

# Provide a .aid/ fixture so bare 'aid' takes the repo-command path and renders the notice.
TA=$(newtarget)
mkdir -p "${TA}/.aid"
printf 'format_version: 1\n' > "${TA}/.aid/settings.yml"
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
     --from-bundle "${FIXTURE_DIR}" \
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

# Provide a .aid/ fixture so bare 'aid' takes the repo-command path and renders the notice.
TF2=$(newtarget)
mkdir -p "${TF2}/.aid"
printf 'format_version: 1\n' > "${TF2}/.aid/settings.yml"
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
    --from-bundle "${FIXTURE_DIR}" \
    --target "${TI_UC}" >/dev/null 2>&1

# Run 'aid update' — must NOT show the update check notice.
OUT=$(AID_HOME="${CLI028I_HOME}" AID_NO_UPDATE_CHECK=0 \
     AID_UPDATE_CHECK_URL="${_check_url_i}" \
     AID_LIB_PATH="${CLI028I_HOME}/lib/aid-install-core.sh" \
     bash "${CLI028I_HOME}/bin/aid" update \
     --from-bundle "${FIXTURE_DIR}" \
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
    --from-bundle "${FIXTURE_DIR}" \
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
    --from-bundle "${FIXTURE_DIR}" \
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
    --from-bundle "${FIXTURE_DIR}" \
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
# Provide a .aid/ fixture so bare 'aid' takes the repo-command path and renders the header.
TMP_TARGET_D=$(newtarget)
mkdir -p "${TMP_TARGET_D}/.aid"
printf 'format_version: 1\n' > "${TMP_TARGET_D}/.aid/settings.yml"
OUT=$(cd "${TMP_TARGET_D}" && \
     AID_HOME="${CLI029D_HOME}" AID_LIB_PATH="${CLI029D_HOME}/lib/aid-install-core.sh" \
     bash "${CLI029D_HOME}/bin/aid" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI029-D02 bare aid after re-bootstrap → exit 0 (no stale-core error)"
assert_output_contains "$OUT" "AID v" "CLI029-D03 dashboard header present after re-bootstrap"

# TASK019: version pinning, on-disk version agreement, migration fences, and update-all cache.
TASK019_BAD_VERSION="0.0.0"
[[ "$TASK019_BAD_VERSION" == "$VERSION" ]] && TASK019_BAD_VERSION="0.0.1"
TASK019_HOME=$(newhome); setup_aid_home "$TASK019_HOME"; TASK019_TARGET=$(newtarget)
run_aid "$TASK019_HOME" add codex --from-bundle "$FIXTURE_DIR" --target "$TASK019_TARGET"
assert_exit_eq "$RC" 0 "CLI019-V01 seed pinned project"
TASK019_BEFORE=$(tree_snapshot "$TASK019_TARGET")
TASK019_VERSION_RELEASE="$TMP/version-release/v${TASK019_BAD_VERSION}"
mkdir -p "$TASK019_VERSION_RELEASE"
build_different_version_bundle "$TASK019_VERSION_RELEASE" cursor "$TASK019_BAD_VERSION" "$VERSION"
OUT=$(AID_ALLOW_ENDPOINT_OVERRIDE=1 AID_DOWNLOAD_BASE="file://${TMP}/version-release" \
    AID_HOME="$TASK019_HOME" AID_LIB_PATH="${TASK019_HOME}/lib/aid-install-core.sh" \
    bash "${TASK019_HOME}/bin/aid" add cursor --version "$TASK019_BAD_VERSION" --target "$TASK019_TARGET" 2>&1); RC=$?
assert_exit_eq "$RC" 2 "CLI019-V02 reject add version different from project"
assert_eq "$(tree_snapshot "$TASK019_TARGET")" "$TASK019_BEFORE" "CLI019-V03 version refusal preserves whole target tree"
run_aid "$TASK019_HOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_TARGET"
assert_exit_eq "$RC" 0 "CLI019-V04 omitted version inherits project version"
python3 - "$TASK019_TARGET/.aid/.aid-manifest.json" "$TASK019_BAD_VERSION" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['tools']['codex']['version']=sys.argv[2]; open(p,'w').write(json.dumps(d,indent=2)+'\n')
PY
run_aid "$TASK019_HOME" add claude-code --from-bundle "$FIXTURE_DIR" --target "$TASK019_TARGET"
assert_exit_ne "$RC" 0 "CLI019-V05 divergent project versions reject add"
assert_output_contains "$OUT" "aid update" "CLI019-V06 divergent refusal directs user to aid update"
run_aid "$TASK019_HOME" update --from-bundle "$FIXTURE_DIR" --target "$TASK019_TARGET"
assert_exit_eq "$RC" 0 "CLI019-V07 update repairs divergent versions"
if manifest_versions_are_uniform "$TASK019_TARGET/.aid/.aid-manifest.json"; then
    assert_eq "uniform" "uniform" "CLI019-V08 update leaves all shared and tool versions equal"
else
    assert_eq "divergent" "uniform" "CLI019-V08 update leaves all shared and tool versions equal"
fi

TASK019_MISMATCH="$TMP/mismatch"; mkdir -p "$TASK019_MISMATCH"
build_different_version_bundle "$TASK019_MISMATCH" cursor "$TASK019_BAD_VERSION" "$VERSION"
TASK019_MHOME=$(newhome); setup_aid_home "$TASK019_MHOME"; TASK019_MT=$(newtarget)
run_aid "$TASK019_MHOME" add codex --from-bundle "$FIXTURE_DIR" --target "$TASK019_MT"
TASK019_MBEFORE=$(tree_snapshot "$TASK019_MT")
run_aid "$TASK019_MHOME" add cursor --from-bundle "$TASK019_MISMATCH" --target "$TASK019_MT"
assert_exit_ne "$RC" 0 "CLI019-V09 staging bundle version mismatch refuses install"
assert_output_contains "$OUT" "aid update" "CLI019-V09b staging bundle mismatch directs user to aid update"
assert_eq "$(tree_snapshot "$TASK019_MT")" "$TASK019_MBEFORE" "CLI019-V10 bundle mismatch preserves whole target tree"

# Empty/bare project migrations accept supported legacy forms and write current formats.
TASK019_BARE=$(newtarget); TASK019_BHOME=$(newhome); setup_aid_home "$TASK019_BHOME"
run_aid "$TASK019_BHOME" projects add "$TASK019_BARE"
assert_exit_eq "$RC" 0 "CLI019-M01 projects add initializes bare project"
run_aid "$TASK019_BHOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_BARE"
assert_exit_eq "$RC" 0 "CLI019-M02 bare projects-add project accepts first tool"
assert_file_contains "$TASK019_BARE/.aid/.aid-manifest.json" '"format_version": 3' "CLI019-M03 bare project writes manifest format 3"
assert_file_contains "$TASK019_BARE/.aid/settings.yml" 'format_version: 5' "CLI019-M04 bare project writes settings format 5"

TASK019_V2=$(newtarget); TASK019_V2HOME=$(newhome); setup_aid_home "$TASK019_V2HOME"
mkdir -p "$TASK019_V2/.aid"; printf '{"format_version":2,"aid_version":"%s","tools":{}}\n' "$VERSION" > "$TASK019_V2/.aid/.aid-manifest.json"
printf 'format_version: 4\n' > "$TASK019_V2/.aid/settings.yml"
run_aid "$TASK019_V2HOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_V2"
assert_exit_eq "$RC" 0 "CLI019-M05 empty format-2 manifest migrates on add"
assert_file_contains "$TASK019_V2/.aid/.aid-manifest.json" '"format_version": 3' "CLI019-M06 format-2 manifest upgraded to format 3"
assert_file_contains "$TASK019_V2/.aid/settings.yml" 'format_version: 5' "CLI019-M07 empty legacy settings stamp upgraded to 5"

TASK019_INST=$(newtarget); TASK019_IHOME=$(newhome); setup_aid_home "$TASK019_IHOME"
run_aid "$TASK019_IHOME" add codex --from-bundle "$FIXTURE_DIR" --target "$TASK019_INST"
printf 'format_version: 4\n' > "$TASK019_INST/.aid/settings.yml"
TASK019_IB=$(tree_snapshot "$TASK019_INST")
run_aid "$TASK019_IHOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_INST"
assert_exit_eq "$RC" 2 "CLI019-M08 installed project refuses settings stamp 4"
assert_eq "$(tree_snapshot "$TASK019_INST")" "$TASK019_IB" "CLI019-M09 installed stamp refusal preserves tree"

TASK019_FUTURE=$(newtarget); TASK019_FHOME=$(newhome); setup_aid_home "$TASK019_FHOME"
mkdir -p "$TASK019_FUTURE/.aid"; printf '{"format_version":4,"aid_version":"%s","tools":{}}\n' "$VERSION" > "$TASK019_FUTURE/.aid/.aid-manifest.json"
TASK019_FB=$(tree_snapshot "$TASK019_FUTURE")
run_aid "$TASK019_FHOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_FUTURE"
assert_exit_ne "$RC" 0 "CLI019-M10 future manifest format refuses add"
assert_eq "$(tree_snapshot "$TASK019_FUTURE")" "$TASK019_FB" "CLI019-M11 future format refusal preserves tree"

# Projects add migrates a legacy folder's settings but leaves its missing manifest visible.
TASK019_LEGACY=$(newtarget); TASK019_LHOME=$(newhome); setup_aid_home "$TASK019_LHOME"
mkdir -p "$TASK019_LEGACY/.aid" "$TASK019_LEGACY/.codex/aid"
printf 'legacy managed payload\n' > "$TASK019_LEGACY/.codex/aid/legacy-skill.md"
printf 'format_version: 4\n' > "$TASK019_LEGACY/.aid/settings.yml"
run_aid "$TASK019_LHOME" projects add "$TASK019_LEGACY"
assert_exit_eq "$RC" 0 "CLI019-M12 projects add accepts manifestless legacy folder"
assert_eq "$([[ -f "$TASK019_LEGACY/.aid/.aid-manifest.json" ]] && echo manifest || echo absent)" absent "CLI019-M13 projects-add leaves legacy manifest absent"
TASK019_LB=$(tree_snapshot "$TASK019_LEGACY")
run_aid "$TASK019_LHOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_LEGACY"
assert_exit_ne "$RC" 0 "CLI019-M14 manifestless legacy refuses tool add"
assert_eq "$(tree_snapshot "$TASK019_LEGACY")" "$TASK019_LB" "CLI019-M15 manifestless refusal preserves tree"

# update all downloads one shared/tool cache and launches a real child update.
TASK019_ALLHOME=$(newhome); setup_aid_home "$TASK019_ALLHOME"; TASK019_ALLTARGET=$(newtarget)
run_aid "$TASK019_ALLHOME" add cursor --from-bundle "$FIXTURE_DIR" --target "$TASK019_ALLTARGET"
assert_exit_eq "$RC" 0 "CLI019-U01 seed registered update-all project"
run_aid "$TASK019_ALLHOME" projects add "$TASK019_ALLTARGET"
assert_exit_eq "$RC" 0 "CLI019-U02 register update-all project"
TASK019_DL="$TMP/update-download/v${VERSION}"; mkdir -p "$TASK019_DL"
cp "$FIXTURE_DIR"/aid-*.tar.gz "$TASK019_DL/"
(cd "$TASK019_DL" && sha256sum aid-*.tar.gz > SHA256SUMS)
TASK019_CAPTURE="$TMP/captured-cache"; TASK019_CHILD_RC="$TMP/captured-child-rc"
TASK019_REAL_BASH=$(command -v bash); export TASK019_REAL_BASH TASK019_CAPTURE TASK019_CHILD_RC
bash() {
    if [[ "${1##*/}" == aid && "${2:-}" == update ]]; then
        local arg cache="" previous="" has_bundle=0
        for arg in "$@"; do
            [[ "$arg" == --from-bundle ]] && has_bundle=1
            [[ "$previous" == --from-bundle ]] && cache="$arg"
            previous="$arg"
        done
        if [[ "$has_bundle" == 1 && -n "$cache" ]]; then
            cp -a "$cache" "$TASK019_CAPTURE"
            "$TASK019_REAL_BASH" "$@"; local child_rc=$?
            printf '%s\n' "$child_rc" > "$TASK019_CHILD_RC"
            return "$child_rc"
        fi
    fi
    "$TASK019_REAL_BASH" "$@"
}
export -f bash
OUT=$(AID_SKIP_SELF_INSTALL=1 AID_ALLOW_ENDPOINT_OVERRIDE=1 AID_DOWNLOAD_BASE="file://${TMP}/update-download" \
    AID_HOME="$TASK019_ALLHOME" AID_LIB_PATH="${TASK019_ALLHOME}/lib/aid-install-core.sh" \
    bash "${TASK019_ALLHOME}/bin/aid" update all --version "$VERSION" 2>&1); RC=$?
unset -f bash
assert_exit_eq "$RC" 0 "CLI019-U03 update all succeeds using local release"
assert_file_exists "$TASK019_CAPTURE/aid-cursor-v${VERSION}.tar.gz" "CLI019-U04 update-all cache contains cursor artifact"
assert_file_exists "$TASK019_CAPTURE/aid-shared-v${VERSION}.tar.gz" "CLI019-U05 update-all cache contains shared artifact"
assert_file_exists "$TASK019_CAPTURE/SHA256SUMS" "CLI019-U06 update-all cache contains verified checksums"
assert_eq "$(cat "$TASK019_CHILD_RC")" 0 "CLI019-U07 update-all child update exits successfully"
assert_output_contains "$OUT" "1 updated" "CLI019-U08 update-all reports project updated"
unset TASK019_REAL_BASH TASK019_CAPTURE TASK019_CHILD_RC

# AC15 detector must not interpret a generic .agents directory as Codex.
TASK019_D="$TMP/detect"; mkdir -p "$TASK019_D/.agents"
OUT=$(bash -c 'source "$1"; detect_tool "$2"' _ "$LIB_CORE" "$TASK019_D" 2>&1); RC=$?
assert_exit_eq "$RC" 2 "CLI019-D01 .agents-only target is ambiguous and not Codex"
assert_output_not_contains "$OUT" codex "CLI019-D02 .agents-only detection emits no codex"
rm -rf "$TASK019_D/.agents"; mkdir -p "$TASK019_D/.codex"
OUT=$(bash -c 'source "$1"; detect_tool "$2"' _ "$LIB_CORE" "$TASK019_D" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "CLI019-D03 .codex target is detected"
assert_output_contains "$OUT" codex "CLI019-D04 .codex detection names codex"

# ISOLATION CANARY: the real HOME's .aid subtree must be byte-unchanged by this suite
# ISOLATION CANARY: the real HOME's .aid subtree must be byte-unchanged by this suite
# (superset check via sandbox.sh, still asserted under the suite's original label). A
# mismatch means an invocation escaped the throwaway HOME and wrote to the real one.
# Guards against the suite ever polluting a developer's box.
sandbox_assert_aid_untouched "ISOL-HOME real \$HOME/.aid/.update-check untouched by suite (no isolation escape)"

test_summary
