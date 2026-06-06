#!/usr/bin/env bash
# test-install.sh — integration tests for install.sh + lib/aid-install-core.sh.
#
# Drives install.sh against temp target directories using locally-built fixture
# tarballs (--from-bundle).  No network calls in CI.
#
# Usage:
#   bash test-install.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.
#
# Note: default install output is the concise summary (no per-file lines).
# Tests that check for per-file lines (Copied:, Updated:, Removed:) use --verbose.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/install.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$SUT" ]] || { echo "ERROR: install.sh not found at $SUT" >&2; exit 1; }

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

    # Collect files, excluding README.md and emission-manifest.jsonl.
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

# Helper: run install.sh and capture output + exit code.
# Usage: run_install [args...]
run_install() {
    OUT=$(bash "$SUT" "$@" 2>&1); RC=$?
}

# Helper: run install.sh in verbose mode (per-file output).
run_install_verbose() {
    OUT=$(bash "$SUT" --verbose "$@" 2>&1); RC=$?
}

# ---------------------------------------------------------------------------
# Usage / error cases
# ---------------------------------------------------------------------------

run_install --unknown-flag
assert_exit_eq "$RC" 2 "IN01 unknown flag → exit 2"
assert_output_contains "$OUT" "unknown flag" "IN01b error message mentions 'unknown flag'"

T=$(newtarget)
run_install --tool claude-code --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --version 0.7.0 "$T"
assert_exit_eq "$RC" 2 "IN02 --from-bundle + --version mutually exclusive → exit 2"

run_install --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    /this/does/not/exist
assert_exit_eq "$RC" 2 "IN03 non-existent target dir → exit 2"

# ---------------------------------------------------------------------------
# IN04 – Fresh install: claude-code
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN04 fresh install claude-code → exit 0"
assert_dir_exists "$T/.claude" "IN04b .claude/ created"
assert_file_exists "$T/CLAUDE.md" "IN04c CLAUDE.md created"
# Default output: concise summary (no per-file lines).
assert_output_not_contains "$OUT" "Copied:" "IN04d default output has no per-file Copied: lines"
assert_output_contains "$OUT" "files installed" "IN04d2 concise summary shows 'files installed'"
assert_output_contains "$OUT" "Done." "IN04e done banner"
# With --verbose: per-file lines appear.
T2=$(newtarget)
run_install_verbose --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T2"
assert_exit_eq "$RC" 0 "IN04f verbose fresh install → exit 0"
assert_output_contains "$OUT" "Copied:" "IN04g --verbose shows per-file Copied: lines"

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
run_install --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
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
run_install --tool cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN06 fresh install cursor → exit 0"
assert_dir_exists "$T/.cursor" "IN06b .cursor/ created"
assert_file_exists "$T/AGENTS.md" "IN06c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/cursor/AGENTS.md" && echo same || echo diff)" \
    "same" "IN06d installed AGENTS.md byte-identical to cursor source"

# ---------------------------------------------------------------------------
# IN07 – Fresh install: copilot-cli
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool copilot-cli \
    --from-bundle "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN07 fresh install copilot-cli → exit 0"
assert_dir_exists "$T/.github" "IN07b .github/ created"
assert_file_exists "$T/AGENTS.md" "IN07c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/copilot-cli/AGENTS.md" && echo same || echo diff)" \
    "same" "IN07d installed AGENTS.md byte-identical to copilot-cli source"

# ---------------------------------------------------------------------------
# IN08 – Fresh install: antigravity
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool antigravity \
    --from-bundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN08 fresh install antigravity → exit 0"
assert_dir_exists "$T/.agent" "IN08b .agent/ created"
assert_file_exists "$T/AGENTS.md" "IN08c AGENTS.md created"
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/antigravity/AGENTS.md" && echo same || echo diff)" \
    "same" "IN08d installed AGENTS.md byte-identical to antigravity source"

# ---------------------------------------------------------------------------
# IN09 – Byte-fidelity: .claude tree files (representative sample)
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
# Pick a representative file from .claude/ to verify byte-fidelity.
_sample_claude=$(find "${PROFILES_DIR}/claude-code/.claude" -name "SKILL.md" | head -1)
if [[ -n "$_sample_claude" ]]; then
    _rel="${_sample_claude#${PROFILES_DIR}/claude-code/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_claude" && echo same || echo diff)" \
        "same" "IN09 .claude/SKILL.md byte-identical to source"
fi

# Byte-fidelity: copilot-cli .github tree + AGENTS.md (mirrors SU14 pattern).
T=$(newtarget)
run_install --tool copilot-cli \
    --from-bundle "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz" \
    --target "$T"
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
run_install --tool antigravity \
    --from-bundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" \
    --target "$T"
_sample_rule=$(find "${PROFILES_DIR}/antigravity/.agent/rules" -name "*.md" 2>/dev/null | head -1)
if [[ -n "$_sample_rule" ]]; then
    _rel="${_sample_rule#${PROFILES_DIR}/antigravity/}"
    assert_eq "$(cmp -s "$T/$_rel" "$_sample_rule" && echo same || echo diff)" \
        "same" "IN09d antigravity .agent/rules file byte-identical"
fi

# ---------------------------------------------------------------------------
# IN10 – Idempotent re-install (identical files → concise "up to date" summary)
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
# Second install, same version — default (concise) mode.
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN10 idempotent re-install → exit 0"
assert_output_contains "$OUT" "up to date" "IN10b concise summary shows 'up to date'"
assert_output_not_contains "$OUT" "Copied:" "IN10c no per-file Copied: in default mode"
assert_output_not_contains "$OUT" "Up to date:" "IN10d no per-file Up to date: in default mode"
# With --verbose: per-file lines appear.
run_install_verbose --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN10e verbose idempotent → exit 0"
assert_output_contains "$OUT" "Up to date:" "IN10f --verbose shows per-file Up to date: lines"
assert_output_not_contains "$OUT" "Copied:" "IN10g --verbose idempotent: nothing re-copied"

# ---------------------------------------------------------------------------
# IN11 – --force overwrites a locally-modified non-root file
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
# Find a file inside .claude to modify.
_dot_file=$(find "$T/.claude" -type f | head -1)
printf '\nlocal edit\n' >> "$_dot_file"
# Re-install with --force (default/concise mode): summary shown, no per-file lines.
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --force --target "$T"
assert_exit_eq "$RC" 0 "IN11 --force re-install → exit 0"
assert_output_not_contains "$OUT" "Updated:" "IN11b default mode: no per-file Updated: line"
# --verbose mode shows per-file Updated: line.
printf '\nlocal edit\n' >> "$_dot_file"
run_install_verbose --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --force --target "$T"
assert_exit_eq "$RC" 0 "IN11c --verbose --force → exit 0"
assert_output_contains "$OUT" "Updated:" "IN11d --verbose --force shows per-file Updated: line"
# Verify the file is restored.
_rel="${_dot_file#${T}/}"
assert_eq "$(cmp -s "$_dot_file" "${PROFILES_DIR}/claude-code/${_rel}" && echo same || echo diff)" \
    "same" "IN11e file restored to source after --force"

# ---------------------------------------------------------------------------
# IN12 – Manifest correctness: paths, version, root_agent sha
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
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
run_install --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_exists "$MANIFEST" "IN13 pre-uninstall manifest exists"

run_install --uninstall --tool codex --target "$T"
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
run_install --uninstall --tool codex --target "$T"
assert_exit_eq "$RC" 6 "IN13j second uninstall → exit 6 (no manifest)"

# ---------------------------------------------------------------------------
# IN14 – Protect-on-diff (FR11): pre-placed user AGENTS.md → not overwritten,
#         .aid-new created, exit 5
# ---------------------------------------------------------------------------
T=$(newtarget)
printf 'This is the user AGENTS.md, not from AID\n' > "$T/AGENTS.md"

run_install --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
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
# IN15 – Protect-on-diff with --force: pre-placed user AGENTS.md → overwritten
# ---------------------------------------------------------------------------
T=$(newtarget)
printf 'This is the user AGENTS.md\n' > "$T/AGENTS.md"

run_install --tool codex --force \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN15 protect-on-diff with --force → exit 0"
# AGENTS.md must now be the profile version.
assert_eq "$(cmp -s "$T/AGENTS.md" "${PROFILES_DIR}/codex/AGENTS.md" && echo same || echo diff)" \
    "same" "IN15b AGENTS.md overwritten with profile version when --force"
# No .aid-new file.
assert_eq "$([[ -f "$T/AGENTS.md.aid-new" ]] && echo exists || echo none)" "none" \
    "IN15c no AGENTS.md.aid-new when --force used"

# ---------------------------------------------------------------------------
# IN16 – Uninstall safety (FR11): modified AID-owned AGENTS.md left in place
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T"
# Modify the installed AGENTS.md after install.
printf '\nuser post-install edit\n' >> "$T/AGENTS.md"

run_install --uninstall --tool codex --target "$T"
assert_exit_eq "$RC" 0 "IN16 uninstall with modified AGENTS.md → exit 0"
assert_output_contains "$OUT" "Left in place" "IN16b reports 'Left in place' for modified file"
# AGENTS.md should still exist (not removed).
assert_file_exists "$T/AGENTS.md" "IN16c modified AGENTS.md left in place after uninstall"

# ---------------------------------------------------------------------------
# IN17 – Comma-list --tool codex,cursor: second AGENTS.md is byte-identical (FR12) -> skipped as up-to-date, no .aid-new
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool codex,cursor \
    --from-bundle "${FIXTURE_DIR}" \
    --target "$T"
# codex installs AGENTS.md (its profile content).
# cursor also writes AGENTS.md — under FR12 all four root AGENTS.md are byte-identical,
# so the second write is skipped as up-to-date → exit 0, no .aid-new created.
assert_exit_eq "$RC" 0 "IN17 codex,cursor comma-list: second AGENTS.md is byte-identical (FR12) -> skipped as up-to-date, exit 0"
assert_eq "$([[ -f "$T/AGENTS.md.aid-new" ]] && echo exists || echo none)" "none" \
    "IN17b no AGENTS.md.aid-new when second AGENTS.md is byte-identical (FR12)"
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
run_install --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" --target "$T"
assert_exit_eq "$RC" 0 "IN18 auto-detect single .claude marker → install claude-code, exit 0"
assert_file_exists "$T/CLAUDE.md" "IN18b CLAUDE.md installed via auto-detect"

# ---------------------------------------------------------------------------
# IN19 – Auto-detect: two markers → exit 2 (ambiguous)
# ---------------------------------------------------------------------------
T=$(newtarget)
mkdir -p "$T/.claude"
mkdir -p "$T/.cursor"
run_install --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" --target "$T"
assert_exit_eq "$RC" 2 "IN19 auto-detect two markers → exit 2 (ambiguous)"
assert_output_contains "$OUT" "ambiguous" "IN19b error message says 'ambiguous'"

# ---------------------------------------------------------------------------
# IN20 – Auto-detect: no markers → exit 2
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" --target "$T"
assert_exit_eq "$RC" 2 "IN20 auto-detect no markers → exit 2"
assert_output_contains "$OUT" "cannot auto-detect" "IN20b error message says 'cannot auto-detect'"

# ---------------------------------------------------------------------------
# IN21 – --update: re-install over an existing setup
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN21 initial install for update test"
# Run again with --update; same version → concise "up to date" (default mode).
run_install --update --tool cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN21b --update same version → exit 0"
assert_output_contains "$OUT" "up to date" "IN21c --update identical files → concise 'up to date'"
assert_output_not_contains "$OUT" "Up to date:" "IN21d --update default mode has no per-file Up to date: line"

# ---------------------------------------------------------------------------
# IN22 – Help flag exits 0.
# ---------------------------------------------------------------------------
run_install --help
assert_exit_eq "$RC" 0 "IN22 --help → exit 0"
assert_output_contains "$OUT" "Usage" "IN22b --help prints Usage"

run_install -h
assert_exit_eq "$RC" 0 "IN22c -h → exit 0"

# ---------------------------------------------------------------------------
# IN23 – --from-bundle with a directory: picks up per-tool tarballs
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool antigravity \
    --from-bundle "${FIXTURE_DIR}" \
    --target "$T"
assert_exit_eq "$RC" 0 "IN23 --from-bundle directory → picks correct tarball, exit 0"
assert_dir_exists "$T/.agent" "IN23b .agent/ created from bundle directory"
assert_file_exists "$T/AGENTS.md" "IN23c AGENTS.md created from bundle directory"

# ---------------------------------------------------------------------------
# IN24 – Multi-tool install (no AGENTS.md collision): claude-code + codex
#         claude-code owns CLAUDE.md, codex owns AGENTS.md — no conflict.
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --tool claude-code,codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "$T"
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
run_install --tool claude-code,codex \
    --from-bundle "${FIXTURE_DIR}" \
    --target "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
# Uninstall only codex.
run_install --uninstall --tool codex --target "$T"
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
run_install --tool claude-code \
    --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
    --target "$T"
MANIFEST="${T}/.aid/.aid-manifest.json"
# Manifest must NOT contain absolute paths.
assert_output_not_contains "$(cat "$MANIFEST")" "${T}" "IN26 manifest has no absolute paths"
# Manifest must contain the root agent path as a relative entry.
assert_file_contains "$MANIFEST" '"CLAUDE.md"' "IN26b CLAUDE.md in paths as relative entry"

# ---------------------------------------------------------------------------
# IN27 – --uninstall with no manifest → exit 6
# ---------------------------------------------------------------------------
T=$(newtarget)
run_install --uninstall --tool codex --target "$T"
assert_exit_eq "$RC" 6 "IN27 uninstall with no manifest → exit 6"

# ---------------------------------------------------------------------------
# IN28 – Pure-Bash manifest fallback (python3+jq stripped from PATH):
#         install codex then cursor; both tools' root_agent_files survive.
#         Guards finding #3.
# ---------------------------------------------------------------------------
T=$(newtarget)
# Force the pure-Bash _manifest_write_bash path by overriding command_v_python3 and
# command_v_jq to fail.  We cannot simply shadow PATH because /usr/bin contains both
# bash (needed) and python3.  Instead we write a wrapper script that launches
# install.sh with aid-install-core.sh modified via an env override to skip python3/jq.
# The cleanest test-safe approach: source the lib with _AID_FORCE_BASH_MANIFEST=1
# as a way to bypass the python3 fast-path.  We add that env-gate to the lib.
#
# Since modifying the lib for test purposes is invasive, we use a different
# strategy: create a clean env subshell with a minimal PATH that contains a
# directory where python3/jq do NOT exist, but where bash IS present.
# We copy /usr/bin/bash (or use its absolute path) to a writable temp dir.
_NO_PY_DIR="${TMP}/no-py-bin"
mkdir -p "$_NO_PY_DIR"
# Symlink essential tools (all except python3/jq) into a shadow bin.
for _tool in bash tar gzip gunzip find sort awk sed grep tr wc mktemp date cmp cp mv rm mkdir dirname basename cat printf head tail cut id uname od stat ls sha256sum shasum; do
    # Use 'which' to find the actual binary (avoids picking up shell function wrappers
    # that 'command -v' would return, e.g. grep is wrapped by the Claude Code env).
    _bin="$(which "$_tool" 2>/dev/null || command -v "$_tool" 2>/dev/null)"
    # Resolve to absolute path if it's relative.
    if [[ -n "$_bin" && "${_bin:0:1}" != "/" ]]; then
        _bin="$(type -P "$_tool" 2>/dev/null || true)"
    fi
    if [[ -n "$_bin" && -x "$_bin" ]]; then
        ln -sf "$_bin" "${_NO_PY_DIR}/${_tool}" 2>/dev/null || true
    fi
done

_RUN_NO_PYTHON_JQ() {
    PATH="${_NO_PY_DIR}" bash "$SUT" "$@"
}
OUT=$(_RUN_NO_PYTHON_JQ --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN28 pure-bash fallback: install codex (no python3/jq) → exit 0"
MANIFEST="${T}/.aid/.aid-manifest.json"
assert_file_exists "$MANIFEST" "IN28b manifest created by pure-bash writer"
assert_file_contains "$MANIFEST" '"codex"' "IN28c manifest contains codex"
assert_file_contains "$MANIFEST" '"sha256"' "IN28d manifest contains sha256 (root_agent_files)"
assert_file_contains "$MANIFEST" '"status": "owned"' "IN28e root_agent status owned"

# Second tool: cursor — also installs AGENTS.md; under FR12 all root AGENTS.md are
# byte-identical so the second write is skipped as up-to-date → exit 0.
# BOTH tools must still appear in the manifest with their root_agent_files.
OUT=$(_RUN_NO_PYTHON_JQ --tool cursor \
    --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
    --target "$T" 2>&1); RC=$?
# exit 0 because cursor's AGENTS.md is byte-identical to codex's (FR12) → up-to-date, not a collision.
assert_exit_eq "$RC" 0 "IN28f pure-bash fallback: install cursor (FR12 byte-identical AGENTS.md) -> skipped as up-to-date, exit 0"
MANIFEST="${T}/.aid/.aid-manifest.json"
# Both tools must be listed in the manifest.
assert_file_contains "$MANIFEST" '"codex"' "IN28g manifest still contains codex after cursor install"
assert_file_contains "$MANIFEST" '"cursor"' "IN28h manifest contains cursor"
# Codex's root_agent_files must survive (the bug this guards).
# Extract the root_agent_files section within the codex block and check for sha256.
# Use python3 if available, otherwise grep for sha256 in the entire manifest and
# verify the codex section exists with a non-empty sha256.
if command -v python3 >/dev/null 2>&1; then
    _CODEX_SHA="$(python3 - "$MANIFEST" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    for e in d.get("tools",{}).get("codex",{}).get("root_agent_files",[]):
        if e.get("sha256"):
            print(e["sha256"])
            break
except Exception:
    pass
PY
)"
    if [[ -n "$_CODEX_SHA" ]]; then
        pass "IN28i codex root_agent_files sha256 preserved after cursor install (guards #3)"
    else
        fail "IN28i codex root_agent_files sha256 preserved after cursor install (guards #3) — codex RAF sha256 is empty in manifest"
    fi
else
    # Fallback: verify the manifest has both "codex" and "sha256" lines (sha256 is
    # in the root_agent_files section of the codex block since only codex has RAF entries).
    if grep -qF '"codex"' "$MANIFEST" && grep -qF '"sha256"' "$MANIFEST"; then
        pass "IN28i codex root_agent_files sha256 preserved after cursor install (guards #3)"
    else
        fail "IN28i codex root_agent_files sha256 preserved after cursor install (guards #3) — codex or sha256 not found in manifest"
    fi
fi

# Uninstall safety: both tools' uninstall must work.
OUT=$(_RUN_NO_PYTHON_JQ --uninstall --tool codex --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN28j pure-bash: uninstall codex → exit 0"
assert_eq "$([[ -d "$T/.codex" ]] && echo exists || echo gone)" "gone" "IN28k .codex/ removed"
# Manifest must still contain cursor.
assert_file_contains "$MANIFEST" '"cursor"' "IN28l manifest still contains cursor after codex uninstall"
# Codex gone from manifest — check via grep.
if ! grep -q '"codex"' "$MANIFEST" 2>/dev/null; then
    pass "IN28m codex removed from manifest after uninstall"
else
    fail "IN28m codex still in manifest after uninstall"
fi

# ---------------------------------------------------------------------------
# IN29 – Piped invocation: cat install.sh | bash -s -- ...
#         AID_LIB_PATH points at the local lib so no network needed.
#         Guards finding #1.
# ---------------------------------------------------------------------------
T=$(newtarget)
LIB_PATH="${REPO_ROOT}/lib/aid-install-core.sh"
OUT=$(AID_LIB_PATH="$LIB_PATH" bash -s -- \
    --tool codex \
    --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
    --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN29 piped invocation (cat|bash -s) with AID_LIB_PATH → exit 0"
assert_dir_exists "$T/.codex" "IN29b .codex/ created via piped invocation"
assert_file_exists "$T/AGENTS.md" "IN29c AGENTS.md created via piped invocation"
assert_output_contains "$OUT" "Done." "IN29d piped invocation reports Done."
assert_file_exists "${T}/.aid/.aid-manifest.json" "IN29e manifest created via piped invocation"

# ---------------------------------------------------------------------------
# IN30 – Piped --help: AID_LIB_PATH set to avoid network; $0 is 'bash' (not a
#         readable file), so usage() must print the stub (fix #11).
#         Guards finding #11.
# ---------------------------------------------------------------------------
LIB_PATH="${REPO_ROOT}/lib/aid-install-core.sh"

OUT=$(AID_LIB_PATH="$LIB_PATH" bash -s -- --help < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN30 piped --help exits 0"
assert_output_contains "$OUT" "install.sh" "IN30b piped --help output contains 'install.sh'"
assert_output_contains "$OUT" "Usage" "IN30c piped --help output contains 'Usage'"
assert_output_contains "$OUT" "tool" "IN30d piped --help output mentions '--tool'"
# Must NOT contain 'sed: can't read bash'
assert_output_not_contains "$OUT" "can't read" "IN30e piped --help has no sed error"

# IN30f – Piped bad flag: prints stub + error, exits 2.
OUT=$(AID_LIB_PATH="$LIB_PATH" bash -s -- --badflag-xyz < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 2 "IN30f piped bad flag exits 2"
assert_output_not_contains "$OUT" "can't read" "IN30g piped bad flag: no sed error"

# ---------------------------------------------------------------------------
# IN31 – Lib checksum verification: AID_LIB_BASE + AID_SUMS_URL local overrides.
#         Simulate the piped (no sibling lib) path using local file:// URLs for
#         the lib and SHA256SUMS so no real network is needed.
#         Guards finding #12.
#
# Key: run the piped invocation from a temp directory that has NO lib/ subdir,
# so the script cannot find the sibling lib (path 2) and must use path 3 (remote
# fetch with AID_LIB_BASE override).  AID_LIB_PATH must also be unset.
# ---------------------------------------------------------------------------
_LIB_SERVE_DIR="${TMP}/libserve"
mkdir -p "${_LIB_SERVE_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_LIB_SERVE_DIR}/lib/aid-install-core.sh"

# Compute the correct sha256 for SHA256SUMS.
_LIB_SHA256=$(sha256sum "${_LIB_SERVE_DIR}/lib/aid-install-core.sh" | awk '{print $1}')
printf '%s  aid-install-core.sh\n' "$_LIB_SHA256" > "${_LIB_SERVE_DIR}/SHA256SUMS"

# Run from a temp dir so there is no sibling lib/ dir that would short-circuit to path 2.
_RUN_IN_DIR="${TMP}/run-in-dir"
mkdir -p "${_RUN_IN_DIR}"

T=$(newtarget)
# Note: AID_LIB_VERSION avoids the GitHub API call for version resolution
# (--version is mutually exclusive with --from-bundle in the main arg parser).
# ISOLATION: AID_LIB_PATH must be unset so the remote-fetch code path (path 3) is
# exercised instead of the sibling-lib shortcut.  'env -u' is the portable way.
OUT=$(cd "${_RUN_IN_DIR}" && \
      env -u AID_LIB_PATH \
      AID_LIB_VERSION="${VERSION}" \
      AID_LIB_BASE="file://${_LIB_SERVE_DIR}/lib" \
      AID_SUMS_URL="file://${_LIB_SERVE_DIR}/SHA256SUMS" \
      bash -s -- \
        --tool codex \
        --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN31 piped with correct checksum → exit 0"
assert_output_contains "$OUT" "Checksum OK" "IN31b checksum verification success reported"

# IN31c – Tampered lib: SHA256SUMS has the REAL hash but we serve a TAMPERED lib.
_TAMPER_DIR="${TMP}/libtamper"
mkdir -p "${_TAMPER_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_TAMPER_DIR}/lib/aid-install-core.sh"
printf '\n# TAMPER\n' >> "${_TAMPER_DIR}/lib/aid-install-core.sh"
# SHA256SUMS still has the ORIGINAL (non-tampered) hash.
printf '%s  aid-install-core.sh\n' "$_LIB_SHA256" > "${_TAMPER_DIR}/SHA256SUMS"

T=$(newtarget)
OUT=$(cd "${_RUN_IN_DIR}" && \
      env -u AID_LIB_PATH \
      AID_LIB_VERSION="${VERSION}" \
      AID_LIB_BASE="file://${_TAMPER_DIR}/lib" \
      AID_SUMS_URL="file://${_TAMPER_DIR}/SHA256SUMS" \
      bash -s -- \
        --tool codex \
        --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 4 "IN31c tampered lib → exit 4 (checksum mismatch)"
assert_output_contains "$OUT" "checksum mismatch" "IN31d tampered lib error mentions checksum mismatch"

# IN31e – PWNED-prevention: tampered lib with echo PWNED injection must NOT execute.
# The lib in _TAMPER_DIR contains '# TAMPER' appended; if the installer were to source
# it despite the mismatch it would exit 0 (or run arbitrary code). We verify it aborts
# before sourcing by checking the PWNED string never appears and exit is non-zero.
_PWNED_DIR="${TMP}/libpwned"
mkdir -p "${_PWNED_DIR}/lib"
printf '#!/usr/bin/env bash\necho PWNED\n' > "${_PWNED_DIR}/lib/aid-install-core.sh"
# SHA256SUMS has the ORIGINAL (real) hash — mismatch since we replaced the lib.
printf '%s  aid-install-core.sh\n' "$_LIB_SHA256" > "${_PWNED_DIR}/SHA256SUMS"

T=$(newtarget)
OUT=$(cd "${_RUN_IN_DIR}" && \
      env -u AID_LIB_PATH \
      AID_LIB_VERSION="${VERSION}" \
      AID_LIB_BASE="file://${_PWNED_DIR}/lib" \
      AID_SUMS_URL="file://${_PWNED_DIR}/SHA256SUMS" \
      bash -s -- \
        --tool codex \
        --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_ne "$RC" 0 "IN31e PWNED lib → must NOT exit 0 (abort before source)"
assert_output_not_contains "$OUT" "PWNED" "IN31f PWNED lib → 'PWNED' must NOT appear in output (abort before source)"
assert_output_contains "$OUT" "checksum mismatch" "IN31g PWNED lib → checksum mismatch error reported"

# ---------------------------------------------------------------------------
# IN32 – Missing SHA256SUMS → fail-closed (non-zero, lib NOT sourced).
#         Guards finding #14: when SHA256SUMS cannot be fetched the remote-fetch
#         path must refuse to source the lib (exit 3), not silently proceed.
# ---------------------------------------------------------------------------
_NOSUMS_DIR="${TMP}/libnosums"
mkdir -p "${_NOSUMS_DIR}/lib"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${_NOSUMS_DIR}/lib/aid-install-core.sh"
# Deliberately do NOT create SHA256SUMS in _NOSUMS_DIR.
# AID_SUMS_URL points to a non-existent file → fetch fails.

T=$(newtarget)
OUT=$(cd "${_RUN_IN_DIR}" && \
      env -u AID_LIB_PATH \
      AID_LIB_VERSION="${VERSION}" \
      AID_LIB_BASE="file://${_NOSUMS_DIR}/lib" \
      AID_SUMS_URL="file://${_NOSUMS_DIR}/SHA256SUMS" \
      bash -s -- \
        --tool codex \
        --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_ne "$RC" 0 "IN32 missing SHA256SUMS → fail-closed non-zero (lib NOT sourced)"
assert_output_contains "$OUT" "fail-closed" "IN32b missing SHA256SUMS → 'fail-closed' mentioned in error"

# IN32c – AID_INSECURE_SKIP_LIB_VERIFY=1 must be the explicit opt-out only.
T=$(newtarget)
OUT=$(cd "${_RUN_IN_DIR}" && \
      env -u AID_LIB_PATH \
      AID_LIB_VERSION="${VERSION}" \
      AID_LIB_BASE="file://${_NOSUMS_DIR}/lib" \
      AID_SUMS_URL="file://${_NOSUMS_DIR}/SHA256SUMS" \
      AID_INSECURE_SKIP_LIB_VERIFY=1 \
      bash -s -- \
        --tool codex \
        --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
        --target "$T" < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN32c AID_INSECURE_SKIP_LIB_VERIFY=1 → bypass succeeds (explicit opt-out)"
assert_output_contains "$OUT" "INSECURE" "IN32d insecure bypass emits loud warning"

# ---------------------------------------------------------------------------
# IN33 – AID_TOOL env var: selects tool when --tool not given.
# ---------------------------------------------------------------------------
T=$(newtarget)
OUT=$(AID_TOOL=codex AID_LIB_PATH="${REPO_ROOT}/lib/aid-install-core.sh" \
     bash "$SUT" \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" \
     --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN33 AID_TOOL=codex (no --tool) → installs codex, exit 0"
assert_dir_exists "$T/.codex" "IN33b .codex/ created via AID_TOOL env"
assert_file_exists "$T/AGENTS.md" "IN33c AGENTS.md created via AID_TOOL env"

# IN33d – explicit --tool overrides AID_TOOL (precedence check).
T=$(newtarget)
OUT=$(AID_TOOL=codex AID_LIB_PATH="${REPO_ROOT}/lib/aid-install-core.sh" \
     bash "$SUT" \
     --tool cursor \
     --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" \
     --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN33d explicit --tool cursor overrides AID_TOOL=codex → exit 0"
assert_dir_exists "$T/.cursor" "IN33e .cursor/ created (cursor, not codex)"
assert_eq "$([[ -d "$T/.codex" ]] && echo exists || echo none)" "none" \
    "IN33f .codex/ not created (codex NOT installed)"

# ---------------------------------------------------------------------------
# IN34 – AID_VERBOSE=1 env var: enables per-file output.
# ---------------------------------------------------------------------------
T=$(newtarget)
OUT=$(AID_VERBOSE=1 bash "$SUT" \
     --tool claude-code \
     --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
     --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN34 AID_VERBOSE=1 → exit 0"
assert_output_contains "$OUT" "Copied:" "IN34b AID_VERBOSE=1 shows per-file Copied: lines"

# IN34c – --verbose flag overrides AID_VERBOSE=0 (flag takes precedence).
T=$(newtarget)
OUT=$(AID_VERBOSE=0 bash "$SUT" \
     --tool claude-code \
     --verbose \
     --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" \
     --target "$T" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN34c --verbose flag (AID_VERBOSE=0) → exit 0"
assert_output_contains "$OUT" "Copied:" "IN34d --verbose flag shows per-file Copied: even when AID_VERBOSE=0"

# ---------------------------------------------------------------------------
# IN35 – AID_TARGET env var: sets the target directory.
# ---------------------------------------------------------------------------
T=$(newtarget)
OUT=$(AID_TARGET="$T" bash "$SUT" \
     --tool codex \
     --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN35 AID_TARGET env sets target dir → exit 0"
assert_dir_exists "$T/.codex" "IN35b .codex/ created in AID_TARGET dir"

test_summary
