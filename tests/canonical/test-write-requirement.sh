#!/usr/bin/env bash
# test-write-requirement.sh — unit tests for dashboard/scripts/write-requirement.sh
# (feature-001-write-infrastructure, work-017 task-003, Q3 resolution).
#
# Covers:
#   Unit 1  — replaces an existing **Name:** bullet
#   Unit 2  — replaces an existing **Description:** bullet (lowercase --field input)
#   Unit 3  — inserts a **Name:** bullet under "# Requirements" when absent
#   Unit 4  — inserts a **Description:** bullet under "# Requirements" when absent
#   Unit 5  — unknown --field exits 4
#   Unit 6  — --value with an embedded newline exits 4
#   Unit 7  — --value with an embedded pipe exits 4
#   Unit 8  — requirements file missing exits 2
#   Unit 9  — missing required args exits 2
#   Unit 10 — AID_REQUIREMENTS_FILE env var is honored
#   Unit 11 — no env var set → defaults to <cwd>/REQUIREMENTS.md
#   Unit 12 — every OTHER line (Change Log, etc.) is byte-preserved
#   Unit 13 — neither bullet nor "# Requirements" heading present → exit 2
#   Unit 14 — write is atomic: no stray temp file left behind on success
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../dashboard/scripts/write-requirement.sh"

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
# Requirements

- **Name:** Interactive AID Dashboard
- **Description:** Turn the read-only dashboard into an interactive control surface.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-16 | Initial | /aid-describe |
EOF
}

fixture_no_bullets() {
    cat <<'EOF'
# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
EOF
}

fixture_no_heading() {
    cat <<'EOF'
## Change Log

| Date | Change | Source |
|------|--------|--------|
EOF
}

echo "== write-requirement.sh tests =="

# ---------------------------------------------------------------------------
# Unit 1: replaces existing Name bullet
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u1.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "Renamed Pipeline" 2>&1)
ec=$?
assert_exit_zero "$ec" "U1 write-requirement exits 0"
assert_file_contains "$f" "- **Name:** Renamed Pipeline" "U1 Name bullet replaced"
assert_file_not_contains "$f" "Interactive AID Dashboard" "U1 old Name value gone"

# ---------------------------------------------------------------------------
# Unit 2: replaces existing Description bullet (lowercase --field input)
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u2.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field description --value "New description" 2>&1)
ec=$?
assert_exit_zero "$ec" "U2 write-requirement exits 0"
assert_file_contains "$f" "- **Description:** New description" "U2 Description bullet replaced (normalized case)"

# ---------------------------------------------------------------------------
# Unit 3: inserts Name bullet under heading when absent
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u3.md"
fixture_no_bullets > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "Brand New" 2>&1)
ec=$?
assert_exit_zero "$ec" "U3 write-requirement exits 0"
assert_file_contains "$f" "- **Name:** Brand New" "U3 Name bullet inserted"
assert_file_contains "$f" "## Change Log" "U3 rest of file survives"

# ---------------------------------------------------------------------------
# Unit 4: inserts Description bullet under heading when absent
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u4.md"
fixture_no_bullets > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Description --value "Desc here" 2>&1)
ec=$?
assert_exit_zero "$ec" "U4 write-requirement exits 0"
assert_file_contains "$f" "- **Description:** Desc here" "U4 Description bullet inserted"

# ---------------------------------------------------------------------------
# Unit 5: unknown --field
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u5.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Objective --value "X" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U5 unknown --field exits 4"

# ---------------------------------------------------------------------------
# Unit 6-7: --value corruption guards
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u6.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value $'a\nb' 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U6 newline in --value exits 4"

f="${TMPDIR_BASE}/u7.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "a|b" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U7 pipe in --value exits 4"

# ---------------------------------------------------------------------------
# Unit 8: requirements file missing
# ---------------------------------------------------------------------------
out=$(AID_REQUIREMENTS_FILE="${TMPDIR_BASE}/does-not-exist.md" bash "$SUT" --field Name --value "X" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U8 missing requirements file exits 2"

# ---------------------------------------------------------------------------
# Unit 9: missing required args
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u9.md"
fixture_full > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U9 missing --value exits 2"

out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --value "X" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U9b missing --field exits 2"

# ---------------------------------------------------------------------------
# Unit 10: AID_REQUIREMENTS_FILE env var honored
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u10.md"
fixture_full > "$f"
AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "Env Targeted" >/dev/null 2>&1
assert_file_contains "$f" "- **Name:** Env Targeted" "U10 AID_REQUIREMENTS_FILE target written"

# ---------------------------------------------------------------------------
# Unit 11: default cwd fallback when env var unset
# ---------------------------------------------------------------------------
subdir="${TMPDIR_BASE}/cwd-default"
mkdir -p "$subdir"
fixture_full > "${subdir}/REQUIREMENTS.md"
( cd "$subdir" && env -u AID_REQUIREMENTS_FILE bash "$SUT" --field Name --value "CwdDefault" >/dev/null 2>&1 )
assert_file_contains "${subdir}/REQUIREMENTS.md" "- **Name:** CwdDefault" "U11 cwd-default REQUIREMENTS.md written"

# ---------------------------------------------------------------------------
# Unit 12: byte-preservation — Change Log and other bullet untouched
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u12.md"
fixture_full > "$f"
AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "Only Name Changes" >/dev/null 2>&1
assert_file_contains "$f" "Turn the read-only dashboard into an interactive control surface." "U12 Description bullet untouched"
assert_file_contains "$f" "| 2026-07-16 | Initial | /aid-describe |" "U12 Change Log row untouched"

# ---------------------------------------------------------------------------
# Unit 13: neither bullet nor heading present
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u13.md"
fixture_no_heading > "$f"
out=$(AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "X" 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "U13 no heading + no bullet exits 2"

# ---------------------------------------------------------------------------
# Unit 14: atomic write — no stray temp file left behind (mktemp's scratch dir
# pinned to a dedicated, otherwise-empty directory via TMPDIR so leftovers are
# unambiguous).
# ---------------------------------------------------------------------------
u14_scratch="${TMPDIR_BASE}/u14-scratch"
mkdir -p "$u14_scratch"
f="${u14_scratch}/u14.md"
fixture_full > "$f"
TMPDIR="$u14_scratch" AID_REQUIREMENTS_FILE="$f" bash "$SUT" --field Name --value "Atomic" >/dev/null 2>&1
leftover=$(find "$u14_scratch" -mindepth 1 -maxdepth 1 -name 'tmp.*' 2>/dev/null)
if [[ -z "$leftover" ]]; then
    pass "U14 no stray temp file left in fixture dir"
else
    fail "U14 stray temp file found: $leftover"
fi

echo
test_summary
exit $?
