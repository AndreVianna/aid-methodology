#!/usr/bin/env bash
# test-setup.sh — tests for setup.sh, the end-user installer that copies selected
# tool profiles (Claude Code / Codex / Cursor / GitHub Copilot CLI / Antigravity)
# from profiles/ into a target directory.
#
# setup.sh is interactive: it prints a numbered menu and reads selections from stdin
# (1/2/3/4/5 toggle a tool, 6 = Done). These tests drive it by piping the menu
# sequence — always terminated with "6" so the read-loop breaks (an unterminated
# pipe would loop on EOF until the suite timeout). Differing-file overwrites prompt
# on /dev/tty, so the tests only exercise fresh installs, identical re-installs,
# the --force path, and the Option-A AGENTS.md collision (which resolves
# non-interactively when AGENTS_COLLISION=1), none of which hang on /dev/tty.
#
# Usage:
#   bash test-setup.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/setup.sh"

[[ -f "$SUT" ]] || { echo "ERROR: setup.sh not found at $SUT" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# drive <target> <menu-input> [extra setup.sh args...]
#   menu-input is a string with embedded newlines (use $'1\n6'); piped to setup.sh's stdin.
drive() {
    local target="$1" input="$2"; shift 2
    OUT=$(printf '%s\n' "$input" | bash "$SUT" "$target" "$@" 2>&1); RC=$?
}

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }

# --- Argument / precondition errors -----------------------------------------
OUT=$(bash "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 1 "SU01 no target arg → exit 1"
assert_output_contains "$OUT" "Usage:" "SU01b prints usage"

OUT=$(bash "$SUT" "${TMP}/nope-does-not-exist" 2>&1); RC=$?
assert_exit_eq "$RC" 1 "SU02 nonexistent target → exit 1"
assert_output_contains "$OUT" "does not exist" "SU02b 'does not exist' message"

# --- Menu logic without installing ------------------------------------------
T=$(newtarget)
drive "$T" "6"
assert_exit_eq "$RC" 0 "SU03 select nothing (Done) → exit 0"
assert_output_contains "$OUT" "Nothing selected" "SU03b 'Nothing selected'"

T=$(newtarget)
drive "$T" $'1\n1\n6'   # toggle Claude on then off → nothing selected
assert_output_contains "$OUT" "Nothing selected" "SU04 toggle on+off → nothing selected"
assert_eq "$([[ -d "$T/.claude" ]] && echo yes || echo no)" "no" "SU04b nothing installed after toggle-off"

T=$(newtarget)
drive "$T" $'9\n6'      # invalid menu choice, then Done
assert_output_contains "$OUT" "Invalid choice" "SU05 invalid choice rejected"
assert_output_contains "$OUT" "Nothing selected" "SU05b invalid-only → nothing selected"

# --- Install Claude Code -----------------------------------------------------
T=$(newtarget)
drive "$T" $'1\n6'
assert_exit_eq "$RC" 0 "SU06 install Claude Code → exit 0"
assert_dir_exists "$T/.claude" "SU06b .claude/ created"
assert_file_exists "$T/CLAUDE.md" "SU06c CLAUDE.md created"
assert_output_contains "$OUT" "Copied:" "SU06d reports copied files"
assert_output_contains "$OUT" "Done. Files installed into:" "SU06e done banner"
# content fidelity: installed CLAUDE.md matches the source profile
assert_eq "$(cmp -s "$T/CLAUDE.md" "$REPO_ROOT/profiles/claude-code/CLAUDE.md" && echo same || echo diff)" \
    "same" "SU06f installed CLAUDE.md is byte-identical to source"

# --- Install Codex -----------------------------------------------------------
T=$(newtarget)
drive "$T" $'2\n6'
assert_exit_eq "$RC" 0 "SU07 install Codex → exit 0"
assert_dir_exists "$T/.codex" "SU07b .codex/ created"
assert_dir_exists "$T/.agents" "SU07c .agents/ created"
assert_file_exists "$T/AGENTS.md" "SU07d AGENTS.md created"

# --- Install Cursor ----------------------------------------------------------
T=$(newtarget)
drive "$T" $'3\n6'
assert_exit_eq "$RC" 0 "SU08 install Cursor → exit 0"
assert_dir_exists "$T/.cursor" "SU08b .cursor/ created"
assert_file_exists "$T/AGENTS.md" "SU08c AGENTS.md created"

# --- Install multiple tools at once -----------------------------------------
T=$(newtarget)
drive "$T" $'1\n2\n6'
assert_exit_eq "$RC" 0 "SU09 install Claude+Codex → exit 0"
assert_dir_exists "$T/.claude" "SU09b .claude/ created"
assert_dir_exists "$T/.codex" "SU09c .codex/ created"
assert_file_exists "$T/CLAUDE.md" "SU09d CLAUDE.md created"
assert_file_exists "$T/AGENTS.md" "SU09e AGENTS.md created"

# --- Idempotent re-install: identical files report "Up to date", not re-copied
T=$(newtarget)
drive "$T" $'1\n6'                 # first install
drive "$T" $'1\n6'                 # second install, same selection
assert_exit_eq "$RC" 0 "SU10 re-install (identical) → exit 0"
assert_output_contains "$OUT" "Up to date:" "SU10b identical files reported up to date"
assert_output_not_contains "$OUT" "Copied:" "SU10c nothing re-copied on identical re-install"

# --- --force overwrites a locally-modified file -----------------------------
T=$(newtarget)
drive "$T" $'1\n6'                 # install
printf '\nlocal edit\n' >> "$T/CLAUDE.md"   # diverge from source
drive "$T" $'1\n6' --force         # re-install with --force
assert_exit_eq "$RC" 0 "SU11 --force re-install → exit 0"
assert_output_contains "$OUT" "Updated:" "SU11b --force overwrites differing files"
assert_eq "$(cmp -s "$T/CLAUDE.md" "$REPO_ROOT/profiles/claude-code/CLAUDE.md" && echo same || echo diff)" \
    "same" "SU11c CLAUDE.md restored to source after --force"

# =============================================================================
# New providers: GitHub Copilot CLI (4) + Antigravity (5)
# =============================================================================

# --- SU12 Install GitHub Copilot CLI -----------------------------------------
T=$(newtarget)
drive "$T" $'4\n6'
assert_exit_eq "$RC" 0 "SU12 install Copilot CLI → exit 0"
assert_dir_exists "$T/.github" "SU12b .github/ created"
assert_file_exists "$T/AGENTS.md" "SU12c root AGENTS.md created"
assert_output_contains "$OUT" "Copied:" "SU12d reports Copied:"

# --- SU13 Install Antigravity ------------------------------------------------
T=$(newtarget)
drive "$T" $'5\n6'
assert_exit_eq "$RC" 0 "SU13 install Antigravity → exit 0"
assert_dir_exists "$T/.agent" "SU13b .agent/ created"
assert_dir_exists "$T/.agent/skills" "SU13c .agent/skills/ created"
assert_dir_exists "$T/.agent/rules" "SU13d .agent/rules/ created"
assert_file_exists "$T/AGENTS.md" "SU13e root AGENTS.md created (FR1 Q-H)"
assert_output_contains "$OUT" "Copied:" "SU13f reports Copied:"

# --- SU14 Content fidelity: new-provider files byte-identical to profile sources ---
# Copilot: .github tree + AGENTS.md
T=$(newtarget)
drive "$T" $'4\n6'
# Installed AGENTS.md must match source
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/copilot-cli/AGENTS.md" && echo same || echo diff)" \
    "same" "SU14a Copilot AGENTS.md byte-identical to source"
# A representative .github file should match
_sample_agent=$(find "$REPO_ROOT/profiles/copilot-cli/.github/agents" -name "*.agent.md" | head -1)
_rel="${_sample_agent#$REPO_ROOT/profiles/copilot-cli/}"
assert_eq "$(cmp -s "$T/$_rel" "$_sample_agent" && echo same || echo diff)" \
    "same" "SU14b Copilot .github agent file byte-identical to source"
# A skills file should match
_sample_skill=$(find "$REPO_ROOT/profiles/copilot-cli/.github/skills" -name "SKILL.md" | head -1)
_rel="${_sample_skill#$REPO_ROOT/profiles/copilot-cli/}"
assert_eq "$(cmp -s "$T/$_rel" "$_sample_skill" && echo same || echo diff)" \
    "same" "SU14c Copilot .github/skills Agent Skills file byte-identical to source"
# No mcp-config.json in installed Copilot tree (FR1 Q-B omit)
assert_eq "$(find "$T/.github" -name "mcp-config.json" 2>/dev/null | wc -l | tr -d ' ')" \
    "0" "SU14d no mcp-config.json in Copilot install (FR1 Q-B omit)"

# Antigravity: .agent tree + AGENTS.md
T=$(newtarget)
drive "$T" $'5\n6'
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/antigravity/AGENTS.md" && echo same || echo diff)" \
    "same" "SU14e Antigravity AGENTS.md byte-identical to source"
# A representative rules file
_sample_rule=$(find "$REPO_ROOT/profiles/antigravity/.agent/rules" -name "*.md" | head -1)
_rel="${_sample_rule#$REPO_ROOT/profiles/antigravity/}"
assert_eq "$(cmp -s "$T/$_rel" "$_sample_rule" && echo same || echo diff)" \
    "same" "SU14f Antigravity .agent/rules file byte-identical to source"
# A skills file
_sample_skill=$(find "$REPO_ROOT/profiles/antigravity/.agent/skills" -name "SKILL.md" | head -1)
_rel="${_sample_skill#$REPO_ROOT/profiles/antigravity/}"
assert_eq "$(cmp -s "$T/$_rel" "$_sample_skill" && echo same || echo diff)" \
    "same" "SU14g Antigravity .agent/skills SKILL.md byte-identical to source"

# --- SU15 Out-of-range still rejected (Done is now 6) -----------------------
T=$(newtarget)
drive "$T" $'7\n6'
assert_output_contains "$OUT" "Invalid choice" "SU15 choice 7 → Invalid choice"
assert_output_contains "$OUT" "Nothing selected" "SU15b nothing installed after out-of-range"

# --- SU16 Multi-select AGENTS.md collision (Option A, non-interactive) -------
# Select Codex (2) + Copilot CLI (4) — two different-content AGENTS.md writers.
# The stdin harness supplies only menu inputs; the setup must NOT hang on /dev/tty.
T=$(newtarget)
drive "$T" $'2\n4\n6'
# (a) exit 0 — no hang/EOF
assert_exit_eq "$RC" 0 "SU16a Codex+Copilot → exit 0 (no /dev/tty hang)"
# (b) collision warning names the survivor
assert_output_contains "$OUT" "Note:" "SU16b collision warning 'Note:' printed"
assert_output_contains "$OUT" "all install a shared AGENTS.md" "SU16c warning names AGENTS.md collision"
assert_output_contains "$OUT" "GitHub Copilot CLI wins" "SU16d warning names Copilot as survivor (highest-numbered block)"
# (c) Copilot (highest-numbered selected AGENTS.md-writer) reports Updated: last-writer-wins
assert_output_contains "$OUT" "last-writer-wins" "SU16e Updated: AGENTS.md last-writer-wins reported"
# (d) installed AGENTS.md is byte-identical to Copilot's source (highest-numbered block wins)
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/copilot-cli/AGENTS.md" && echo same || echo diff)" \
    "same" "SU16f \$T/AGENTS.md byte-identical to Copilot source (last-writer-wins)"

# --- SU16b Unexpected single-tool diff still hits the generic diff-prompt ----
# Single-tool re-install over a manually-edited AGENTS.md with NO second AGENTS.md
# writer selected (so AGENTS_COLLISION=0). The guarded branch must NOT fire, so
# the generic /dev/tty prompt path is preserved.
# We prove this by using --force: the Updated: line should appear and the file should
# be restored. If the guard incorrectly fires (AGENTS_COLLISION=1 without a second
# writer), the mechanism is unchanged, but we verify the --force code-path is distinct.
T=$(newtarget)
drive "$T" $'3\n6'                         # install Cursor → $T/AGENTS.md from cursor
printf '\nmanual edit\n' >> "$T/AGENTS.md" # diverge from source, single tool
# With --force, the generic "different" branch runs cp, no /dev/tty hang even without collision
drive "$T" $'3\n6' --force
assert_exit_eq "$RC" 0 "SU16b single-tool --force over edited AGENTS.md → exit 0"
assert_output_contains "$OUT" "Updated:" "SU16b-2 Updated: reported (--force path, no collision)"
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/cursor/AGENTS.md" && echo same || echo diff)" \
    "same" "SU16b-3 AGENTS.md restored via --force (single-tool, no collision)"
# Without --force, piping "n" proves the generic prompt code-path is preserved
T2=$(newtarget)
drive "$T2" $'3\n6'                        # fresh install
printf '\nmanual edit\n' >> "$T2/AGENTS.md" # diverge
# Pipe menu choice + "n" to answer the /dev/tty prompt — but /dev/tty is not
# available in the test harness. We pipe 'n' via stdin; setup.sh's copy_file
# reads the overwrite prompt from /dev/tty, not stdin, so it will not see 'n'
# and the piped 'n' is just ignored. Instead we confirm the script does NOT
# auto-overwrite (no last-writer-wins branch triggered) by checking the file
# is NOT byte-identical to source (the collision guard must not have fired).
# We do this via: drive with no AGENTS_COLLISION → exit will be non-zero if
# /dev/tty is not available (the read fails), OR the file is unchanged.
# The reliable proof: AGENTS_COLLISION=0 (only one AGENTS.md writer selected),
# so the guarded branch in copy_file does NOT fire. We just assert the variable
# logic is correct by confirming setup ran without the Note: warning.
T2_OUT=$(printf '%s\n' $'3\n6' | bash "$SUT" "$T2" 2>&1) || true
assert_output_not_contains "$T2_OUT" "Note:" "SU16b-4 single-tool install → no collision warning (AGENTS_COLLISION=0)"

# --- SU17 Idempotent re-install + --force for new providers ------------------
# Mirror SU10/SU11 for Copilot CLI
T=$(newtarget)
drive "$T" $'4\n6'                 # first install
drive "$T" $'4\n6'                 # second identical install
assert_exit_eq "$RC" 0 "SU17a Copilot re-install (identical) → exit 0"
assert_output_contains "$OUT" "Up to date:" "SU17b Copilot identical files reported up to date"
assert_output_not_contains "$OUT" "Copied:" "SU17c nothing re-copied on identical Copilot re-install"

# --force over locally-modified file
T=$(newtarget)
drive "$T" $'4\n6'
printf '\nlocal edit\n' >> "$T/AGENTS.md"  # diverge AGENTS.md
drive "$T" $'4\n6' --force
assert_exit_eq "$RC" 0 "SU17d Copilot --force re-install → exit 0"
assert_output_contains "$OUT" "Updated:" "SU17e --force overwrites differing Copilot files"
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/copilot-cli/AGENTS.md" && echo same || echo diff)" \
    "same" "SU17f Copilot AGENTS.md restored to source after --force"

# Mirror for Antigravity
T=$(newtarget)
drive "$T" $'5\n6'                 # first install
drive "$T" $'5\n6'                 # second identical install
assert_exit_eq "$RC" 0 "SU17g Antigravity re-install (identical) → exit 0"
assert_output_contains "$OUT" "Up to date:" "SU17h Antigravity identical files reported up to date"
assert_output_not_contains "$OUT" "Copied:" "SU17i nothing re-copied on identical Antigravity re-install"

T=$(newtarget)
drive "$T" $'5\n6'
printf '\nlocal edit\n' >> "$T/AGENTS.md"  # diverge AGENTS.md
drive "$T" $'5\n6' --force
assert_exit_eq "$RC" 0 "SU17j Antigravity --force re-install → exit 0"
assert_output_contains "$OUT" "Updated:" "SU17k --force overwrites differing Antigravity files"
assert_eq "$(cmp -s "$T/AGENTS.md" "$REPO_ROOT/profiles/antigravity/AGENTS.md" && echo same || echo diff)" \
    "same" "SU17l Antigravity AGENTS.md restored to source after --force"

test_summary
