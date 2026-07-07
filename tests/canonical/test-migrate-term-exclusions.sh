#!/usr/bin/env bash
# test-migrate-term-exclusions.sh -- canonical tests for the work-014 term-exclusions
# adopter migration (_migrate_term_exclusions in lib/aid-install-core.sh).
#
# The migration carries user-confirmed term exclusions from the retired KB dotfile
# .aid/knowledge/.term-exclusions.md into settings.yml discovery.term_exclusions, then
# retires the file to .aid/.trash/. Covered: inject-under-discovery, the file-absent gate,
# idempotency, append-when-no-discovery-section, and no-double-inject.

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

LIB="${REPO_ROOT}/lib/aid-install-core.sh"
assert_file_exists "$LIB" "installer core present"

# Run the migration against <target> in an isolated subshell (the lib sets shell options
# we don't want leaking into the harness).
run_migrate() { ( source "$LIB"; _migrate_term_exclusions "$1" ) >/dev/null 2>&1; }

mk_settings() { printf 'discovery:\n  closure:\n    max_rounds: 4\n  doc_set:\n    - README.md|skill-self|required\n' > "$1"; }
mk_termfile() { printf '# Term exclusions (user-confirmed)\n\n- In Progress\n- dry-run\n- File System\n' > "$1"; }

# --- MT01: file present -> inject under discovery + retire ---
echo "=== MT01: migrate an existing .term-exclusions.md into settings.yml ==="
T1=$(mktemp -d); mkdir -p "${T1}/.aid/knowledge"; mk_settings "${T1}/.aid/settings.yml"; mk_termfile "${T1}/.aid/knowledge/.term-exclusions.md"
run_migrate "$T1"
assert_file_contains "${T1}/.aid/settings.yml" "  term_exclusions:" "MT01a term_exclusions key injected"
assert_file_contains "${T1}/.aid/settings.yml" "    - In Progress" "MT01b term with spaces preserved"
assert_file_contains "${T1}/.aid/settings.yml" "    - dry-run" "MT01c hyphenated term preserved"
assert_file_contains "${T1}/.aid/settings.yml" "  doc_set:" "MT01d existing discovery keys untouched"
assert_file_exists "${T1}/.aid/.trash/knowledge/.term-exclusions.md" "MT01e old file retired to .aid/.trash/"
[[ ! -f "${T1}/.aid/knowledge/.term-exclusions.md" ]] && pass "MT01f original file removed from KB dir" || fail "MT01f original file still in KB dir"

# --- MT02: file absent -> gate no-ops, settings untouched ---
echo "=== MT02: no .term-exclusions.md -> zero work (gate) ==="
T2=$(mktemp -d); mkdir -p "${T2}/.aid/knowledge"; mk_settings "${T2}/.aid/settings.yml"
before=$(cat "${T2}/.aid/settings.yml")
run_migrate "$T2"; rc=$?
assert_exit_zero "$rc" "MT02a gate returns success when file absent"
assert_eq "$(cat "${T2}/.aid/settings.yml")" "$before" "MT02b settings.yml unchanged"
assert_file_not_contains "${T2}/.aid/settings.yml" "term_exclusions" "MT02c no term_exclusions injected"

# --- MT03: idempotent second run (file already retired) ---
echo "=== MT03: idempotent -- second run is a no-op ==="
before3=$(cat "${T1}/.aid/settings.yml")
run_migrate "$T1"
assert_eq "$(cat "${T1}/.aid/settings.yml")" "$before3" "MT03a re-run leaves settings.yml unchanged"

# --- MT04: no discovery: section -> append one ---
echo "=== MT04: settings.yml without a discovery: section gets one appended ==="
T4=$(mktemp -d); mkdir -p "${T4}/.aid/knowledge"; printf 'project:\n  name: demo\n' > "${T4}/.aid/settings.yml"; mk_termfile "${T4}/.aid/knowledge/.term-exclusions.md"
run_migrate "$T4"
assert_file_contains "${T4}/.aid/settings.yml" "discovery:" "MT04a discovery: section appended"
assert_file_contains "${T4}/.aid/settings.yml" "  term_exclusions:" "MT04b term_exclusions under it"

# --- MT05: term_exclusions already present -> no double-inject, still retire ---
echo "=== MT05: existing term_exclusions key is not duplicated ==="
T5=$(mktemp -d); mkdir -p "${T5}/.aid/knowledge"
printf 'discovery:\n  term_exclusions:\n    - already\n' > "${T5}/.aid/settings.yml"; mk_termfile "${T5}/.aid/knowledge/.term-exclusions.md"
run_migrate "$T5"
assert_eq "$(grep -c '^  term_exclusions:' "${T5}/.aid/settings.yml")" "1" "MT05a exactly one term_exclusions key"
assert_file_exists "${T5}/.aid/.trash/knowledge/.term-exclusions.md" "MT05b orphan file still retired"

rm -rf "$T1" "$T2" "$T4" "$T5" 2>/dev/null || true
test_summary
