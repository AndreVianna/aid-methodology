#!/usr/bin/env bash
# test-setup.sh — tests for setup.sh, the end-user installer that copies selected
# tool profiles (Claude Code / Codex / Cursor) from profiles/ into a target directory.
#
# setup.sh is interactive: it prints a numbered menu and reads selections from stdin
# (1/2/3 toggle a tool, 4 = Done). These tests drive it by piping the menu sequence —
# always terminated with "4" so the read-loop breaks (an unterminated pipe would loop
# on EOF until the suite timeout). Differing-file overwrites prompt on /dev/tty, so the
# tests only exercise fresh installs, identical re-installs, and the --force path, none
# of which touch /dev/tty.
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
#   menu-input is a string with embedded newlines (use $'1\n4'); piped to setup.sh's stdin.
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
drive "$T" "4"
assert_exit_eq "$RC" 0 "SU03 select nothing (Done) → exit 0"
assert_output_contains "$OUT" "Nothing selected" "SU03b 'Nothing selected'"

T=$(newtarget)
drive "$T" $'1\n1\n4'   # toggle Claude on then off → nothing selected
assert_output_contains "$OUT" "Nothing selected" "SU04 toggle on+off → nothing selected"
assert_eq "$([[ -d "$T/.claude" ]] && echo yes || echo no)" "no" "SU04b nothing installed after toggle-off"

T=$(newtarget)
drive "$T" $'9\n4'      # invalid menu choice, then Done
assert_output_contains "$OUT" "Invalid choice" "SU05 invalid choice rejected"
assert_output_contains "$OUT" "Nothing selected" "SU05b invalid-only → nothing selected"

# --- Install Claude Code -----------------------------------------------------
T=$(newtarget)
drive "$T" $'1\n4'
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
drive "$T" $'2\n4'
assert_exit_eq "$RC" 0 "SU07 install Codex → exit 0"
assert_dir_exists "$T/.codex" "SU07b .codex/ created"
assert_dir_exists "$T/.agents" "SU07c .agents/ created"
assert_file_exists "$T/AGENTS.md" "SU07d AGENTS.md created"

# --- Install Cursor ----------------------------------------------------------
T=$(newtarget)
drive "$T" $'3\n4'
assert_exit_eq "$RC" 0 "SU08 install Cursor → exit 0"
assert_dir_exists "$T/.cursor" "SU08b .cursor/ created"
assert_file_exists "$T/AGENTS.md" "SU08c AGENTS.md created"

# --- Install multiple tools at once -----------------------------------------
T=$(newtarget)
drive "$T" $'1\n2\n4'
assert_exit_eq "$RC" 0 "SU09 install Claude+Codex → exit 0"
assert_dir_exists "$T/.claude" "SU09b .claude/ created"
assert_dir_exists "$T/.codex" "SU09c .codex/ created"
assert_file_exists "$T/CLAUDE.md" "SU09d CLAUDE.md created"
assert_file_exists "$T/AGENTS.md" "SU09e AGENTS.md created"

# --- Idempotent re-install: identical files report "Up to date", not re-copied
T=$(newtarget)
drive "$T" $'1\n4'                 # first install
drive "$T" $'1\n4'                 # second install, same selection
assert_exit_eq "$RC" 0 "SU10 re-install (identical) → exit 0"
assert_output_contains "$OUT" "Up to date:" "SU10b identical files reported up to date"
assert_output_not_contains "$OUT" "Copied:" "SU10c nothing re-copied on identical re-install"

# --- --force overwrites a locally-modified file -----------------------------
T=$(newtarget)
drive "$T" $'1\n4'                 # install
printf '\nlocal edit\n' >> "$T/CLAUDE.md"   # diverge from source
drive "$T" $'1\n4' --force         # re-install with --force
assert_exit_eq "$RC" 0 "SU11 --force re-install → exit 0"
assert_output_contains "$OUT" "Updated:" "SU11b --force overwrites differing files"
assert_eq "$(cmp -s "$T/CLAUDE.md" "$REPO_ROOT/profiles/claude-code/CLAUDE.md" && echo same || echo diff)" \
    "same" "SU11c CLAUDE.md restored to source after --force"

test_summary
