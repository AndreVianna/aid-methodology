#!/usr/bin/env bash
# test-install-ps1.sh — integration tests for install.ps1 + lib/AidInstallCore.psm1,
# the PowerShell mirror of install.sh + lib/aid-install-core.sh.
#
# Drives install.ps1 via `pwsh -NoProfile -File` against temp target directories using
# locally-built fixture tarballs (-FromBundle).  No network calls in CI.
#
# FR9 parity: asserts the same user-visible message strings (Copied:, Up to date:,
# Updated:, Removed:, Left in place, Uninstall complete., Done.) and exit codes as
# the bash test-install.sh suite, for all platform-independent paths.
#
# SKIP (exit 0) when `pwsh` is absent — mirroring the test-assemble-3part-ps1.sh
# contract.  CI asserts pwsh IS present so the skip cannot silently fire there.
#
# Usage:
#   bash test-install-ps1.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/install.ps1"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$SUT" ]] || { echo "ERROR: install.ps1 not found at $SUT" >&2; exit 1; }

# Resolve pwsh the same way as test-install-parity.sh and test-release-install-e2e.sh.
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping install.ps1 suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="0.7.0"

# ---------------------------------------------------------------------------
# build_fixture_tarball <tool>
#   Builds a flat-root tarball from profiles/<tool>/, matching the feature-002
#   layout contract (no wrapping dir; excludes README.md + emission-manifest.jsonl).
#   Output: ${FIXTURE_DIR}/aid-<tool>-v${VERSION}.tar.gz
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

# Build fixture tarballs for all five tools.
for _tool in claude-code codex cursor copilot-cli antigravity; do
    build_fixture_tarball "$_tool" || { echo "ERROR: fixture build failed for ${_tool}" >&2; exit 1; }
done

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }

# Helper: run install.ps1 and capture output + exit code.
# Usage: run_install [ps1-args...]
run_install() {
    OUT=$("$PWSH" -NoProfile -File "$SUT" "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
}

# Helper: run install.ps1 in verbose mode (per-file output).
run_install_verbose() {
    OUT=$("$PWSH" -NoProfile -File "$SUT" -Verbose "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
}

# ---------------------------------------------------------------------------
# Usage / error cases
# ---------------------------------------------------------------------------

# IN01 – unknown parameter → exit 2 (usage error, FR9 parity with bash)
run_install -UnknownParam
assert_exit_eq "$RC" 2 "IN01 unknown parameter → exit 2"
assert_output_contains "$OUT" "unknown parameter" "IN01b error message mentions 'unknown parameter'"

T=$(newtarget)
run_install -Tool claude-code -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -Version 0.7.0 -TargetDirectory "$T"
assert_exit_eq "$RC" 2 "IN02 -FromBundle + -Version mutually exclusive → exit 2"

run_install -Tool codex -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory /this/does/not/exist
assert_exit_eq "$RC" 2 "IN03 non-existent target dir → exit 2"

# ---------------------------------------------------------------------------
# IN04 – Fresh install: claude-code
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN04 fresh install claude-code → exit 0"
assert_dir_exists "$T/.claude" "IN04b .claude/ created"
assert_file_exists "$T/CLAUDE.md" "IN04c CLAUDE.md created"
# Default output: concise summary (no per-file lines).
assert_output_not_contains "$OUT" "Copied:" "IN04d default output has no per-file Copied: lines"
assert_output_contains "$OUT" "files installed" "IN04d2 concise summary shows 'files installed'"
assert_output_contains "$OUT" "Done." "IN04e done banner"
# With -Verbose: per-file lines appear.
T2=$(newtarget)
run_install_verbose -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T2"
assert_exit_eq "$RC" 0 "IN04f verbose fresh install → exit 0"
assert_output_contains "$OUT" "Copied:" "IN04g -Verbose shows per-file Copied: lines"

# Byte-fidelity: installed CLAUDE.md matches profile source.
assert_eq "$(cmp -s "$T/CLAUDE.md" "${PROFILES_DIR}/claude-code/CLAUDE.md" && echo same || echo diff)" \
    "same" "IN04f installed CLAUDE.md byte-identical to source"

# Manifest written.
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_exists "$MANIFEST" "IN04g manifest created"
assert_file_contains "$MANIFEST" '"claude-code"' "IN04h manifest contains claude-code tool"
assert_file_contains "$MANIFEST" '"aid_version"' "IN04i manifest contains aid_version"
assert_file_contains "$MANIFEST" '"manifest_version"' "IN04j manifest contains manifest_version"
# Version marker written.
assert_file_exists "${T}/.aid/.aid-version" "IN04k .aid-version marker written"
assert_eq "$(cat "${T}/.aid/.aid-version")" "${VERSION}" "IN04l .aid-version contains correct version"

# ---------------------------------------------------------------------------
# IN05 – Fresh install: codex
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN05 fresh install codex → exit 0"
assert_dir_exists "$T/.codex" "IN05b .codex/ created"
assert_dir_exists "$T/.agents" "IN05c .agents/ created"
assert_file_exists "$T/AGENTS.md" "IN05d AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/codex/AGENTS.md" && echo same || echo diff)" \
    "same" "IN05e installed AGENTS.md byte-identical to codex source"

# ---------------------------------------------------------------------------
# IN06 – Fresh install: cursor
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN06 fresh install cursor → exit 0"
assert_dir_exists "$T/.cursor" "IN06b .cursor/ created"
assert_file_exists "$T/AGENTS.md" "IN06c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/cursor/AGENTS.md" && echo same || echo diff)" \
    "same" "IN06d installed AGENTS.md byte-identical to cursor source"

# ---------------------------------------------------------------------------
# IN07 – Fresh install: copilot-cli
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool copilot-cli \
    -FromBundle "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN07 fresh install copilot-cli → exit 0"
assert_dir_exists "$T/.github" "IN07b .github/ created"
assert_file_exists "$T/AGENTS.md" "IN07c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/copilot-cli/AGENTS.md" && echo same || echo diff)" \
    "same" "IN07d installed AGENTS.md byte-identical to copilot-cli source"

# ---------------------------------------------------------------------------
# IN08 – Fresh install: antigravity
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool antigravity \
    -FromBundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN08 fresh install antigravity → exit 0"
assert_dir_exists "$T/.agent" "IN08b .agent/ created"
assert_file_exists "$T/AGENTS.md" "IN08c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/antigravity/AGENTS.md" && echo same || echo diff)" \
    "same" "IN08d installed AGENTS.md byte-identical to antigravity source"

# ---------------------------------------------------------------------------
# IN09 – Byte-fidelity: .claude tree files (representative sample)
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
# Pick a representative file from .claude/ to verify byte-fidelity.
_sample_claude=$(find "${PROFILES_DIR}/claude-code/.claude" -name "SKILL.md" | head -1)
if [[ -n "$_sample_claude" ]]; then
    _rel="${_sample_claude#${PROFILES_DIR}/claude-code/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_claude" && echo same || echo diff)" \
        "same" "IN09 .claude/SKILL.md byte-identical to source"
fi

# Byte-fidelity: copilot-cli .github tree + AGENTS.md.
T=$(newtarget)
run_install -Tool copilot-cli \
    -FromBundle "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
_sample_agent=$(find "${PROFILES_DIR}/copilot-cli/.github/agents" -name "*.agent.md" 2>/dev/null | head -1)
if [[ -n "$_sample_agent" ]]; then
    _rel="${_sample_agent#${PROFILES_DIR}/copilot-cli/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_agent" && echo same || echo diff)" \
        "same" "IN09b copilot .github/agents file byte-identical"
fi
_sample_skill=$(find "${PROFILES_DIR}/copilot-cli/.github/skills" -name "SKILL.md" 2>/dev/null | head -1)
if [[ -n "$_sample_skill" ]]; then
    _rel="${_sample_skill#${PROFILES_DIR}/copilot-cli/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_skill" && echo same || echo diff)" \
        "same" "IN09c copilot .github/skills SKILL.md byte-identical"
fi

# Byte-fidelity: antigravity .agent tree.
T=$(newtarget)
run_install -Tool antigravity \
    -FromBundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
_sample_rule=$(find "${PROFILES_DIR}/antigravity/.agent/rules" -name "*.md" 2>/dev/null | head -1)
if [[ -n "$_sample_rule" ]]; then
    _rel="${_sample_rule#${PROFILES_DIR}/antigravity/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_rule" && echo same || echo diff)" \
        "same" "IN09d antigravity .agent/rules file byte-identical"
fi

# ---------------------------------------------------------------------------
# IN10 – Idempotent re-install (identical files → "Up to date")
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
# Second install, same version.
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN10 idempotent re-install → exit 0"
assert_output_contains "$OUT" "up to date" "IN10b concise summary shows 'up to date'"
assert_output_not_contains "$OUT" "Copied:" "IN10c no per-file Copied: in default mode"
assert_output_not_contains "$OUT" "Up to date:" "IN10d no per-file Up to date: in default mode"
# With -Verbose: per-file lines appear.
run_install_verbose -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN10e verbose idempotent → exit 0"
assert_output_contains "$OUT" "Up to date:" "IN10f -Verbose shows per-file Up to date: lines"
assert_output_not_contains "$OUT" "Copied:" "IN10g -Verbose idempotent: nothing re-copied"

# ---------------------------------------------------------------------------
# IN11 – -Force overwrites a locally-modified non-root file
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
# Find a file inside .claude to modify.
_dot_file=$(find "$T/.claude" -type f | head -1)
printf '\nlocal edit\n' >> "$_dot_file"
# Re-install with -Force.
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -Force -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN11 -Force re-install → exit 0"
# Default mode: no per-file Updated: line.
assert_output_not_contains "$OUT" "Updated:" "IN11b default mode: no per-file Updated: line"
# -Verbose mode shows per-file Updated: line.
printf '\nlocal edit\n' >> "$_dot_file"
run_install_verbose -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -Force -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN11c -Verbose -Force → exit 0"
assert_output_contains "$OUT" "Updated:" "IN11d -Verbose -Force shows per-file Updated: line"
# Verify the file is restored.
_rel="${_dot_file#${T}/}"
assert_eq "$(cmp -s "$_dot_file" "${PROFILES_DIR}/claude-code/${_rel}" && echo same || echo diff)" \
    "same" "IN11e file restored to source after -Force"

# ---------------------------------------------------------------------------
# IN12 – Manifest correctness: paths, version, root_agent sha
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_exists "$MANIFEST" "IN12 manifest exists"
assert_file_contains "$MANIFEST" '"aid_version": "'"${VERSION}"'"' "IN12b manifest aid_version matches"
assert_file_contains "$MANIFEST" '"version": "'"${VERSION}"'"' "IN12c tool version matches"
assert_file_contains "$MANIFEST" '"AGENTS.md"' "IN12d AGENTS.md listed in paths"
assert_file_contains "$MANIFEST" '"sha256"' "IN12e root_agent sha256 recorded"
assert_file_contains "$MANIFEST" '"status": "owned"' "IN12f root_agent status is owned"

# ---------------------------------------------------------------------------
# IN13 – Uninstall exactness: removes manifested paths, leaves repo clean
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_exists "$MANIFEST" "IN13 pre-uninstall manifest exists"

run_install -Uninstall -Tool codex -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN13b uninstall → exit 0"
# Default mode: concise summary (no per-file Removed: lines).
assert_output_not_contains "$OUT" "Removed:" "IN13c default uninstall has no per-file Removed: lines"
assert_output_contains "$OUT" "files removed" "IN13c2 concise summary shows 'files removed'"
assert_output_contains "$OUT" "Uninstall complete." "IN13d uninstall complete banner"

# All installed dirs should be gone.
assert_eq "$([[ -d "$T/.codex" ]] && echo exists || echo gone)" "gone" \
    "IN13e .codex/ removed after uninstall"
assert_eq "$([[ -d "$T/.agents" ]] && echo exists || echo gone)" "gone" \
    "IN13f .agents/ removed after uninstall"
assert_eq "$([[ -f "$T/AGENTS.md" ]] && echo exists || echo gone)" "gone" \
    "IN13g AGENTS.md removed after uninstall"
# Manifest itself is removed when no tools remain.
assert_eq "$([[ -f "$MANIFEST" ]] && echo exists || echo gone)" "gone" \
    "IN13h manifest removed after full uninstall"
# .aid/ dir should be gone (empty after removing manifest).
assert_eq "$([[ -d "$T/.aid" ]] && echo exists || echo gone)" "gone" \
    "IN13i .aid/ dir removed after full uninstall"

# Second uninstall → exit 6 (no manifest).
run_install -Uninstall -Tool codex -TargetDirectory "$T"
assert_exit_eq "$RC" 6 "IN13j second uninstall → exit 6 (no manifest)"

# ---------------------------------------------------------------------------
# IN14 – Protect-on-diff (FR11): pre-placed user AGENTS.md → not overwritten,
#         .aid-new created, exit 5
# ---------------------------------------------------------------------------
T=$(newtarget)
printf 'This is the user AGENTS.md, not from AID\n' > "$T/AGENTS.md"

run_install -Tool codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 5 "IN14 protect-on-diff (user AGENTS.md) → exit 5"
assert_file_exists "$T/AGENTS.md.aid-new" "IN14b AGENTS.md.aid-new created"
# Original user file must NOT be overwritten.
assert_file_contains "$T/AGENTS.md" "user AGENTS.md" "IN14c user AGENTS.md not overwritten"
# Manifest records status pending-merge.
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_contains "$MANIFEST" '"pending-merge"' "IN14d manifest status is pending-merge"
# .aid-new content matches the incoming (profile) version.
assert_eq "$(cmp -s "$T/AGENTS.md.aid-new" "${PROFILES_DIR}/codex/AGENTS.md" && echo same || echo diff)" \
    "same" "IN14e AGENTS.md.aid-new byte-identical to codex source"

# ---------------------------------------------------------------------------
# IN15 – Protect-on-diff with -Force: pre-placed user AGENTS.md → overwritten
# ---------------------------------------------------------------------------
T=$(newtarget)
printf 'This is the user AGENTS.md\n' > "$T/AGENTS.md"

run_install -Tool codex -Force \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN15 protect-on-diff with -Force → exit 0"
# AGENTS.md must now be the profile version.
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/codex/AGENTS.md" && echo same || echo diff)" \
    "same" "IN15b AGENTS.md overwritten with profile version when -Force"
# No .aid-new file.
assert_eq "$([[ -f "$T/AGENTS.md.aid-new" ]] && echo exists || echo none)" "none" \
    "IN15c no AGENTS.md.aid-new when -Force used"

# ---------------------------------------------------------------------------
# IN16 – Uninstall safety (FR11): modified AID-owned AGENTS.md left in place
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool codex \
    -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
# Modify the installed AGENTS.md after install.
printf '\nuser post-install edit\n' >> "$T/AGENTS.md"

run_install -Uninstall -Tool codex -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN16 uninstall with modified AGENTS.md → exit 0"
assert_output_contains "$OUT" "Left in place" "IN16b reports 'Left in place' for modified file"
# AGENTS.md should still exist (not removed).
assert_file_exists "$T/AGENTS.md" "IN16c modified AGENTS.md left in place after uninstall"

# ---------------------------------------------------------------------------
# IN17 – Comma-list -Tool codex,cursor: second AGENTS.md triggers protect-on-diff
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool codex,cursor \
    -FromBundle "${FIXTURE_DIR}" \
    -TargetDirectory "$T"
# codex installs AGENTS.md (its profile content).
# cursor also writes AGENTS.md, which differs from codex's → protect-on-diff → exit 5.
assert_exit_eq "$RC" 5 "IN17 codex,cursor comma-list: second AGENTS.md triggers protect-on-diff → exit 5"
assert_file_exists "$T/AGENTS.md.aid-new" "IN17b AGENTS.md.aid-new created for second AGENTS.md write"
# codex dirs should have been installed.
assert_dir_exists "$T/.codex" "IN17c .codex/ created by codex"
assert_dir_exists "$T/.agents" "IN17d .agents/ created by codex"
# cursor dirs should have been installed.
assert_dir_exists "$T/.cursor" "IN17e .cursor/ created by cursor"

# ---------------------------------------------------------------------------
# IN18 – Auto-detect: single marker → used
# ---------------------------------------------------------------------------
T=$(newtarget)
# Pre-create the .claude marker to simulate an already-partially-configured project.
mkdir -p "$T/.claude"
run_install -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN18 auto-detect single .claude marker → install claude-code, exit 0"
assert_file_exists "$T/CLAUDE.md" "IN18b CLAUDE.md installed via auto-detect"

# ---------------------------------------------------------------------------
# IN19 – Auto-detect: two markers → exit 2 (ambiguous)
# ---------------------------------------------------------------------------
T=$(newtarget)
mkdir -p "$T/.claude"
mkdir -p "$T/.cursor"
run_install -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" -TargetDirectory "$T"
assert_exit_eq "$RC" 2 "IN19 auto-detect two markers → exit 2 (ambiguous)"
assert_output_contains "$OUT" "ambiguous" "IN19b error message says 'ambiguous'"

# ---------------------------------------------------------------------------
# IN20 – Auto-detect: no markers → exit 2
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" -TargetDirectory "$T"
assert_exit_eq "$RC" 2 "IN20 auto-detect no markers → exit 2"
assert_output_contains "$OUT" "cannot auto-detect" "IN20b error message says 'cannot auto-detect'"

# ---------------------------------------------------------------------------
# IN21 – -Update: re-install over an existing setup
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN21 initial install for update test"
# Run again with -Update; same version → Up to date.
run_install -Update -Tool cursor \
    -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN21b -Update same version → exit 0"
assert_output_contains "$OUT" "up to date" "IN21c -Update identical files → concise 'up to date'"
assert_output_not_contains "$OUT" "Up to date:" "IN21d -Update default mode has no per-file Up to date: line"

# ---------------------------------------------------------------------------
# IN22 – Help flag exits 0.
# ---------------------------------------------------------------------------
run_install -Help
assert_exit_eq "$RC" 0 "IN22 -Help → exit 0"
assert_output_contains "$OUT" "Usage" "IN22b -Help prints Usage"

# ---------------------------------------------------------------------------
# IN23 – -FromBundle with a directory: picks up per-tool tarballs
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool antigravity \
    -FromBundle "${FIXTURE_DIR}" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN23 -FromBundle directory → picks correct tarball, exit 0"
assert_dir_exists "$T/.agent" "IN23b .agent/ created from bundle directory"
assert_file_exists "$T/AGENTS.md" "IN23c AGENTS.md created from bundle directory"

# ---------------------------------------------------------------------------
# IN24 – Multi-tool install (no AGENTS.md collision): claude-code + codex
#         claude-code owns CLAUDE.md, codex owns AGENTS.md — no conflict.
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code,codex \
    -FromBundle "${FIXTURE_DIR}" \
    -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN24 claude-code,codex → no AGENTS.md conflict, exit 0"
assert_file_exists "$T/CLAUDE.md" "IN24b CLAUDE.md created"
assert_file_exists "$T/AGENTS.md" "IN24c AGENTS.md created"
assert_dir_exists "$T/.claude" "IN24d .claude/ created"
assert_dir_exists "$T/.codex" "IN24e .codex/ created"
# Manifest should list both tools.
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_contains "$MANIFEST" '"claude-code"' "IN24f manifest lists claude-code"
assert_file_contains "$MANIFEST" '"codex"' "IN24g manifest lists codex"

# ---------------------------------------------------------------------------
# IN25 – Uninstall one tool from a multi-tool install
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code,codex \
    -FromBundle "${FIXTURE_DIR}" \
    -TargetDirectory "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
# Uninstall only codex.
run_install -Uninstall -Tool codex -TargetDirectory "$T"
assert_exit_eq "$RC" 0 "IN25 uninstall codex from claude-code+codex → exit 0"
assert_eq "$([[ -d "$T/.codex" ]] && echo exists || echo gone)" "gone" \
    "IN25b .codex/ removed"
# claude-code install must survive.
assert_dir_exists "$T/.claude" "IN25c .claude/ preserved"
assert_file_exists "$T/CLAUDE.md" "IN25d CLAUDE.md preserved"
# Manifest should still exist with claude-code.
assert_file_exists "$MANIFEST" "IN25e manifest still exists after partial uninstall"
assert_file_contains "$MANIFEST" '"claude-code"' "IN25f manifest still lists claude-code"

# ---------------------------------------------------------------------------
# IN26 – Manifest correctness: paths list contains relative POSIX paths
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Tool claude-code \
    -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    -TargetDirectory "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
# Manifest must NOT contain absolute paths.
assert_output_not_contains "$(cat "$MANIFEST")" "${T}" "IN26 manifest has no absolute paths"
# Manifest must contain the root agent path as a relative entry.
assert_file_contains "$MANIFEST" '"CLAUDE.md"' "IN26b CLAUDE.md in paths as relative entry"

# ---------------------------------------------------------------------------
# IN27 – -Uninstall with no manifest → exit 6
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install -Uninstall -Tool codex -TargetDirectory "$T"
assert_exit_eq "$RC" 6 "IN27 uninstall with no manifest → exit 6"

# ---------------------------------------------------------------------------
# IN31 – PS1 lib checksum verification via http:// (fix #15).
#
# Invoke-WebRequest rejects file:// URIs, so we spin up a tiny python3 HTTP
# server in a temp dir and serve the lib + SHA256SUMS over http://127.0.0.1.
# Skip cleanly if python3 is absent.
#
# Three cases:
#   IN31   correct lib + valid SHA256SUMS → exit 0
#   IN31c  tampered lib + SHA256SUMS with REAL hash → exit 4
#   IN32   missing SHA256SUMS (404) → fail-closed non-zero (guards #14 on ps1 side)
#   IN32c  AID_INSECURE_SKIP_LIB_VERIFY=1 → bypass (explicit opt-out)
# ---------------------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
    echo "SKIP: python3 not found — skipping ps1 checksum http:// tests (IN31/IN32)."
else
    # Find a free port (try from 18900 upward).
    _find_free_port() {
        local port=18900
        while ss -tlnH "sport = :$port" 2>/dev/null | grep -q .; do
            port=$((port + 1))
        done
        echo "$port"
    }

    # Spin up a python3 HTTP server serving a directory on a given port.
    # Usage: _start_http_server <dir> <port>
    # Sets _HTTP_SERVER_PID.
    _HTTP_SERVER_PID=""
    _start_http_server() {
        local dir="$1" port="$2"
        python3 -m http.server "$port" --directory "$dir" >/dev/null 2>&1 &
        _HTTP_SERVER_PID=$!
        # Wait up to 2 seconds for the server to be ready.
        local waited=0
        while ! curl -s --max-time 1 "http://127.0.0.1:${port}/" >/dev/null 2>&1; do
            sleep 0.1
            waited=$((waited + 1))
            if [[ "$waited" -ge 20 ]]; then
                echo "WARN: http server did not start on port $port" >&2
                break
            fi
        done
    }

    _stop_http_server() {
        if [[ -n "${_HTTP_SERVER_PID:-}" ]]; then
            kill "$_HTTP_SERVER_PID" 2>/dev/null || true
            wait "$_HTTP_SERVER_PID" 2>/dev/null || true
            _HTTP_SERVER_PID=""
        fi
    }

    # Prepare serve directories.
    _PS1_LIB_SRC="${REPO_ROOT}/lib/AidInstallCore.psm1"
    _LIB_SHA256_PS1=$(sha256sum "$_PS1_LIB_SRC" | awk '{print $1}')

    # Copy install.ps1 to a temp dir that has NO sibling lib/ so that
    # $ScriptDir does not point to a dir containing lib/AidInstallCore.psm1.
    # This forces the remote-fetch (path 3) code to run.
    # (Analogous to how the bash tests use `bash -s -- < $SUT`.)
    _PS1_RUN_DIR="${TMP}/ps1-run-in-dir"
    mkdir -p "$_PS1_RUN_DIR"
    _PS1_COPY="${_PS1_RUN_DIR}/install.ps1"
    cp "$SUT" "$_PS1_COPY"

    # --- IN31: correct lib + valid SHA256SUMS ---
    _SERVE_GOOD="${TMP}/ps1-serve-good"
    mkdir -p "${_SERVE_GOOD}/lib"
    cp "$_PS1_LIB_SRC" "${_SERVE_GOOD}/lib/AidInstallCore.psm1"
    printf '%s  AidInstallCore.psm1\n' "$_LIB_SHA256_PS1" > "${_SERVE_GOOD}/SHA256SUMS"

    _PORT_GOOD=$(_find_free_port)
    _start_http_server "${_SERVE_GOOD}" "$_PORT_GOOD"

    T=$(newtarget)
    OUT=$(env \
        "AID_LIB_VERSION=${VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_PORT_GOOD}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_PORT_GOOD}/SHA256SUMS" \
        "$PWSH" -NoProfile -File "$_PS1_COPY" \
            -Tool codex \
            -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
            -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
    assert_exit_eq "$RC" 0 "IN31 ps1 correct checksum (http://) → exit 0"
    assert_output_contains "$OUT" "Checksum OK" "IN31b ps1 checksum verification success reported"

    _stop_http_server

    # --- IN31c: tampered lib (REAL hash in SHA256SUMS) → exit 4 ---
    _SERVE_TAMPER="${TMP}/ps1-serve-tamper"
    mkdir -p "${_SERVE_TAMPER}/lib"
    cp "$_PS1_LIB_SRC" "${_SERVE_TAMPER}/lib/AidInstallCore.psm1"
    printf '\n# TAMPER\n' >> "${_SERVE_TAMPER}/lib/AidInstallCore.psm1"
    # SHA256SUMS still has ORIGINAL (real) hash → mismatch.
    printf '%s  AidInstallCore.psm1\n' "$_LIB_SHA256_PS1" > "${_SERVE_TAMPER}/SHA256SUMS"

    _PORT_TAMPER=$(_find_free_port)
    _start_http_server "${_SERVE_TAMPER}" "$_PORT_TAMPER"

    T=$(newtarget)
    OUT=$(env \
        "AID_LIB_VERSION=${VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_PORT_TAMPER}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_PORT_TAMPER}/SHA256SUMS" \
        "$PWSH" -NoProfile -File "$_PS1_COPY" \
            -Tool codex \
            -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
            -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
    assert_exit_eq "$RC" 4 "IN31c ps1 tampered lib → exit 4 (checksum mismatch)"
    assert_output_contains "$OUT" "checksum mismatch" "IN31d ps1 tampered lib error mentions checksum mismatch"

    _stop_http_server

    # ---------------------------------------------------------------------------
    # IN32 – Missing SHA256SUMS (404) → fail-closed non-zero.
    #         Guards finding #14 on the ps1 side.
    # ---------------------------------------------------------------------------
    _SERVE_NOSUMS="${TMP}/ps1-serve-nosums"
    mkdir -p "${_SERVE_NOSUMS}/lib"
    cp "$_PS1_LIB_SRC" "${_SERVE_NOSUMS}/lib/AidInstallCore.psm1"
    # Deliberately do NOT create SHA256SUMS — 404 when fetched.

    _PORT_NOSUMS=$(_find_free_port)
    _start_http_server "${_SERVE_NOSUMS}" "$_PORT_NOSUMS"

    T=$(newtarget)
    OUT=$(env \
        "AID_LIB_VERSION=${VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_PORT_NOSUMS}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_PORT_NOSUMS}/SHA256SUMS" \
        "$PWSH" -NoProfile -File "$_PS1_COPY" \
            -Tool codex \
            -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
            -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
    assert_exit_ne "$RC" 0 "IN32 ps1 missing SHA256SUMS → fail-closed non-zero"
    assert_output_contains "$OUT" "fail-closed" "IN32b ps1 missing SHA256SUMS → 'fail-closed' in error"

    _stop_http_server

    # IN32c – AID_INSECURE_SKIP_LIB_VERIFY=1 → bypass (explicit opt-out).
    _PORT_NOSUMS2=$(_find_free_port)
    _start_http_server "${_SERVE_NOSUMS}" "$_PORT_NOSUMS2"

    T=$(newtarget)
    OUT=$(env \
        "AID_LIB_VERSION=${VERSION}" \
        "AID_LIB_BASE=http://127.0.0.1:${_PORT_NOSUMS2}/lib" \
        "AID_SUMS_URL=http://127.0.0.1:${_PORT_NOSUMS2}/SHA256SUMS" \
        "AID_INSECURE_SKIP_LIB_VERIFY=1" \
        "$PWSH" -NoProfile -File "$_PS1_COPY" \
            -Tool codex \
            -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
            -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
    assert_exit_eq "$RC" 0 "IN32c ps1 AID_INSECURE_SKIP_LIB_VERIFY=1 → bypass succeeds (explicit opt-out)"
    assert_output_contains "$OUT" "INSECURE" "IN32d ps1 insecure bypass emits loud warning"

    _stop_http_server
fi  # end python3 check for IN31/IN32 tests

# ---------------------------------------------------------------------------
# IN33 – Host-survival (piped/iex mode): the key regression guard.
#
# When install.ps1 is run as a scriptblock (simulating `irm <url> | iex` or
# `& ([scriptblock]::Create(...))`), `exit` would normally kill the HOST
# session.  The fix routes all exits through script:Exit-Install which, in
# piped mode, sets $global:LASTEXITCODE and throws a sentinel exception that
# unwinds cleanly — the host session SURVIVES.
#
# Verifies:
#   IN33  success path: install exits 0, HOST-SURVIVED printed, parent's exit 7 wins.
#   IN33b failure path: bad flag exits 2, HOST-SURVIVED printed, parent's exit 7 wins.
#   IN33c LASTEXITCODE from install is visible to caller after scriptblock returns.
#
# Uses AID_LIB_PATH to inject the local lib (avoids remote fetch, no network needed).
# ---------------------------------------------------------------------------

# Scriptblock helper: invokes install.ps1 as a raw scriptblock (simulating iex).
# The parent pwsh session is the outer `pwsh -NoProfile -Command ...`.
# After the scriptblock returns, we write HOST-SURVIVED and exit 7.
# PARENT-EXIT must be 7 (parent's own exit) not the install code.
_run_scriptblock_host_test() {
    local extra_args="$1"   # extra install.ps1 args (quoted as PS literal)
    local extra_vars="$2"   # extra env-var assignments for env(...)
    local extra_env=""
    [[ -n "$extra_vars" ]] && extra_env="$extra_vars"

    # Write a small wrapper PS1 that runs the install scriptblock and reports results.
    local wrapper
    wrapper=$(cat <<PSEOF
\$ErrorActionPreference = 'Continue'
& ([scriptblock]::Create((Get-Content '${SUT}' -Raw))) ${extra_args} 2>&1
\$code = \$LASTEXITCODE
Write-Output "INSTALL-LASTEXITCODE=\$code"
Write-Output 'HOST-SURVIVED'
exit 7
PSEOF
)
    env $extra_env "$PWSH" -NoProfile -Command "$wrapper" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
}

T=$(newtarget)
_hs_out=$(_run_scriptblock_host_test \
    "-Tool codex -FromBundle '${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz' -TargetDirectory '${T}'" \
    "AID_LIB_PATH=${REPO_ROOT}/lib/AidInstallCore.psm1")
_hs_parent_exit=$?

assert_exit_eq "$_hs_parent_exit" 7 \
    "IN33 host-survival success: parent exit 7 wins (install did NOT kill host)"
assert_output_contains "$_hs_out" "HOST-SURVIVED" \
    "IN33b host-survival success: HOST-SURVIVED printed after scriptblock returns"
assert_output_contains "$_hs_out" "INSTALL-LASTEXITCODE=0" \
    "IN33c host-survival success: install LASTEXITCODE=0 visible to caller"

# Failure path: bad flag → install exits 2, host still survives.
_hs_fail_out=$(_run_scriptblock_host_test \
    "-BadFlag" \
    "AID_LIB_PATH=${REPO_ROOT}/lib/AidInstallCore.psm1")
_hs_fail_parent=$?

assert_exit_eq "$_hs_fail_parent" 7 \
    "IN33d host-survival failure: parent exit 7 wins (bad-flag install did NOT kill host)"
assert_output_contains "$_hs_fail_out" "HOST-SURVIVED" \
    "IN33e host-survival failure: HOST-SURVIVED printed after bad-flag scriptblock returns"
assert_output_contains "$_hs_fail_out" "INSTALL-LASTEXITCODE=2" \
    "IN33f host-survival failure: install LASTEXITCODE=2 (usage error) visible to caller"

# ---------------------------------------------------------------------------
# IN33 – $env:AID_TOOL: selects tool when -Tool not given.
# ---------------------------------------------------------------------------
T=$(newtarget)
OUT=$(env "AID_TOOL=codex" "AID_LIB_PATH=${REPO_ROOT}/lib/AidInstallCore.psm1" \
     "$PWSH" -NoProfile -File "$SUT" \
     -FromBundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
assert_exit_eq "$RC" 0 "IN33 AID_TOOL=codex (no -Tool) → installs codex, exit 0"
assert_dir_exists "$T/.codex" "IN33b .codex/ created via AID_TOOL env"
assert_file_exists "$T/AGENTS.md" "IN33c AGENTS.md created via AID_TOOL env"

# IN33d – explicit -Tool overrides $env:AID_TOOL (precedence check).
T=$(newtarget)
OUT=$(env "AID_TOOL=codex" "AID_LIB_PATH=${REPO_ROOT}/lib/AidInstallCore.psm1" \
     "$PWSH" -NoProfile -File "$SUT" \
     -Tool cursor \
     -FromBundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
     -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
assert_exit_eq "$RC" 0 "IN33d explicit -Tool cursor overrides AID_TOOL=codex → exit 0"
assert_dir_exists "$T/.cursor" "IN33e .cursor/ created (cursor, not codex)"
assert_eq "$([[ -d "$T/.codex" ]] && echo exists || echo none)" "none" \
    "IN33f .codex/ not created (codex NOT installed)"

# ---------------------------------------------------------------------------
# IN34 – $env:AID_VERBOSE=1: enables per-file output.
# ---------------------------------------------------------------------------
T=$(newtarget)
OUT=$(env "AID_VERBOSE=1" "AID_LIB_PATH=${REPO_ROOT}/lib/AidInstallCore.psm1" \
     "$PWSH" -NoProfile -File "$SUT" \
     -Tool claude-code \
     -FromBundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
     -TargetDirectory "$T" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); RC=$?
assert_exit_eq "$RC" 0 "IN34 AID_VERBOSE=1 → exit 0"
assert_output_contains "$OUT" "Copied:" "IN34b AID_VERBOSE=1 shows per-file Copied: lines"

test_summary
