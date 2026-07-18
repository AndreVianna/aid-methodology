#!/usr/bin/env bash
# test-write-setting.sh — unit tests for dashboard/scripts/write-setting.sh
# (feature-001-write-infrastructure, work-017 task-003).
#
# Covers:
#   Unit 1  — writes project.name (key present, replaced in place)
#   Unit 2  — writes project.description (key present, replaced in place)
#   Unit 3  — writes review.minimum_grade with a valid grade
#   Unit 4  — review.minimum_grade rejects a malformed grade (exit 4)
#   Unit 5  — disallowed --path exits 4
#   Unit 6  — --value with an embedded newline exits 4
#   Unit 7  — --value with an embedded double-quote exits 4
#   Unit 8  — --value with an embedded backslash exits 4
#   Unit 9  — section absent → section + key created fresh at EOF
#   Unit 10 — section present, key absent → key appended at end of section
#   Unit 11 — settings file missing exits 2
#   Unit 12 — missing --path/--value exits 2
#   Unit 13 — unknown flag exits 2
#   Unit 14 — every OTHER line is byte-preserved (surgical rewrite)
#   Unit 15 — write is atomic: no stray temp file left behind on success
#   Unit 16 — writing an empty --value is accepted (clears a scalar)
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../dashboard/scripts/write-setting.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

fixture_full() {
    cat <<'EOF'
format_version: 1
project:
  name: AID
  description: AI Integrated Development
  type: brownfield

review:
  minimum_grade: A+

tools:
  installed:
    - claude-code
EOF
}

echo "== write-setting.sh tests =="

# ---------------------------------------------------------------------------
# Unit 1: project.name replaced in place
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u1.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.name --value "New Name" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U1 write-setting exits 0"
assert_file_contains "$f" "  name: New Name" "U1 project.name replaced"

# ---------------------------------------------------------------------------
# Unit 2: project.description replaced in place
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u2.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.description --value "A new description" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U2 write-setting exits 0"
assert_file_contains "$f" "  description: A new description" "U2 project.description replaced"

# ---------------------------------------------------------------------------
# Unit 3: review.minimum_grade valid grade accepted
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u3.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path review.minimum_grade --value "B-" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U3 write-setting exits 0"
assert_file_contains "$f" "  minimum_grade: B-" "U3 review.minimum_grade replaced"

# ---------------------------------------------------------------------------
# Unit 4: malformed grade rejected
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u4.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path review.minimum_grade --value "Z" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U4 malformed grade 'Z' rejected"

# ---------------------------------------------------------------------------
# Unit 5: disallowed --path
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u5.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path tools.installed --value "x" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U5 disallowed --path exits 4"

# ---------------------------------------------------------------------------
# Unit 6-8: KI-001 charset guard
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u6.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.name --value $'bad\nvalue' --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U6 newline in --value exits 4"

f="${TMPDIR_BASE}/u7.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.name --value 'bad"value' --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U7 embedded double-quote in --value exits 4"

f="${TMPDIR_BASE}/u8.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.name --value 'bad\value' --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 'U8 embedded backslash in --value exits 4'

# ---------------------------------------------------------------------------
# Unit 9: section entirely absent -> created fresh
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u9.yml"
cat > "$f" <<'EOF'
format_version: 1
tools:
  installed:
    - claude-code
EOF
out=$(bash "$SUT" --path project.name --value "Fresh" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U9 write-setting exits 0"
assert_file_contains "$f" "project:" "U9 fresh section header created"
assert_file_contains "$f" "  name: Fresh" "U9 fresh key created"

# ---------------------------------------------------------------------------
# Unit 10: section present, key absent -> appended at end of section
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u10.yml"
cat > "$f" <<'EOF'
format_version: 1
project:
  name: Existing

tools:
  installed:
    - claude-code
EOF
out=$(bash "$SUT" --path project.description --value "Appended" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U10 write-setting exits 0"
assert_file_contains "$f" "  description: Appended" "U10 key appended into existing section"
assert_file_contains "$f" "  name: Existing" "U10 sibling key untouched"

# ---------------------------------------------------------------------------
# Unit 11: settings file missing
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/does-not-exist.yml"
out=$(bash "$SUT" --path project.name --value "X" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U11 missing settings file exits 2"

# ---------------------------------------------------------------------------
# Unit 12: missing required args
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u12.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.name --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U12 missing --value exits 2"

out=$(bash "$SUT" --value "X" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U12b missing --path exits 2"

# ---------------------------------------------------------------------------
# Unit 13: unknown flag
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U13 unknown flag exits 2"

# ---------------------------------------------------------------------------
# Unit 14: byte-preservation — every OTHER line survives untouched
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u14.yml"
fixture_full > "$f"
bash "$SUT" --path project.name --value "Renamed" --file "$f" >/dev/null 2>&1
assert_file_contains "$f" "format_version: 1" "U14 unrelated line 1 preserved"
assert_file_contains "$f" "  type: brownfield" "U14 unrelated sibling key preserved"
assert_file_contains "$f" "  minimum_grade: A+" "U14 unrelated section preserved"
assert_file_contains "$f" "    - claude-code" "U14 unrelated list preserved"

# ---------------------------------------------------------------------------
# Unit 15: atomic write — no stray temp files left behind (mktemp's scratch dir
# pinned to a dedicated, otherwise-empty directory via TMPDIR so leftovers are
# unambiguous).
# ---------------------------------------------------------------------------
u15_scratch="${TMPDIR_BASE}/u15-scratch"
mkdir -p "$u15_scratch"
f="${u15_scratch}/u15.yml"
fixture_full > "$f"
TMPDIR="$u15_scratch" bash "$SUT" --path project.name --value "Atomic" --file "$f" >/dev/null 2>&1
leftover=$(find "$u15_scratch" -mindepth 1 -maxdepth 1 -name 'tmp.*' 2>/dev/null)
if [[ -z "$leftover" ]]; then
    pass "U15 no stray temp file left in fixture dir"
else
    fail "U15 stray temp file found: $leftover"
fi

# ---------------------------------------------------------------------------
# Unit 16: empty --value accepted (clears a scalar)
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u16.yml"
fixture_full > "$f"
out=$(bash "$SUT" --path project.description --value "" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U16 empty --value exits 0"
assert_file_contains "$f" "  description:" "U16 description key present with empty value"

echo
test_summary
exit $?
