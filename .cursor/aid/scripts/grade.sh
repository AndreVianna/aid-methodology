#!/usr/bin/env bash
# grade.sh -- Compute AID grade from a reviewer ledger table.
#
# Reads a markdown file (or stdin) containing a reviewer findings table per
# canonical/aid/templates/reviewer-ledger-schema.md. Parses the Severity and
# Status columns of each data row, counts findings where Status is Pending or
# Recurred by Severity column, applies the universal AID rubric (worst
# severity dominates, count determines modifier), and prints the grade.
#
# Table shape expected (7-column):
#   | # | Severity | Status | Doc | Line | Description | Evidence |
#   |---|---|---|---|---|---|---|
#   | 1 | [HIGH] | Pending | foo.md | 42 | ... | ... |
#
# Column indices after split on "|":
#   cols[1] = "" (empty -- before leading |)
#   cols[2] = " 1 "       (the # / row-counter column)
#   cols[3] = " [HIGH] "  (Severity -- THIS is what is graded)
#   cols[4] = " Pending " (Status -- Pending/Recurred are counted)
#
# Only the Severity column (cols[3]) and Status column (cols[4]) of each data
# row are used for grading. Severity tags in Description/Evidence columns
# are NOT counted (fixes the cycle-7 over-count bug).
#
# Usage:
#   grade.sh <ledger-file>
#   cat <ledger-file> | grade.sh
#   grade.sh --explain <ledger-file>        # also prints count breakdown to stderr
#   grade.sh --non-functional               # forces F (build/run failed)
#   grade.sh --from-prose <file>            # DEPRECATED: legacy grep-everywhere behavior
#
# Flags:
#   --from-prose   DEPRECATED. Falls back to the old grep-everywhere behavior for
#                  ledgers that predate the schema (transition period only). Will be
#                  removed once all legacy ledgers are migrated.
#
# Exit codes:
#   0 -- grade printed successfully
#   1 -- input could not be read
#   2 -- invalid arguments

set -euo pipefail

EXPLAIN=0
NON_FUNCTIONAL=0
FROM_PROSE=0
INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --explain)
      EXPLAIN=1
      shift
      ;;
    --non-functional)
      NON_FUNCTIONAL=1
      shift
      ;;
    --from-prose)
      FROM_PROSE=1
      shift
      ;;
    -h|--help)
      sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "grade.sh: unknown flag: $1" >&2
      exit 2
      ;;
    *)
      INPUT="$1"
      shift
      ;;
  esac
done

if [[ "$NON_FUNCTIONAL" -eq 1 ]]; then
  echo "F"
  [[ "$EXPLAIN" -eq 1 ]] && echo "non-functional flag set: build/run failed or produced no usable output" >&2
  exit 0
fi

# Load content from file or stdin
if [[ -n "$INPUT" ]]; then
  if [[ ! -r "$INPUT" ]]; then
    echo "grade.sh: cannot read input file: $INPUT" >&2
    exit 1
  fi
  CONTENT=$(cat "$INPUT")
else
  CONTENT=$(cat)
fi

# Apply the rubric: worst severity dominates, count determines the modifier.
modifier_for_count() {
  local n="$1"
  if   [[ $n -eq 1 ]]; then echo "+"
  elif [[ $n -le 5 ]]; then echo ""
  else                      echo "-"
  fi
}

# ---------------------------------------------------------------------------
# DEPRECATED legacy path: --from-prose
# ---------------------------------------------------------------------------
if [[ "$FROM_PROSE" -eq 1 ]]; then
  echo "grade.sh: WARNING: --from-prose is deprecated. Migrate ledger to schema table format." >&2

  # Strip fenced code blocks before counting.
  PROSE=$(echo "$CONTENT" | awk '
    /^[[:space:]]*```/ { in_fence = !in_fence; next }
    !in_fence { print }
  ')
  # Strip inline backtick content.
  PROSE=$(echo "$PROSE" | sed -E 's/`[^`]*`//g')

  count_prose_tag() {
    local tag="$1"
    { echo "$PROSE" | grep -oE "\[$tag\]" || true; } | wc -l | tr -d ' '
  }

  CRITICAL=$(count_prose_tag CRITICAL)
  HIGH=$(count_prose_tag HIGH)
  MEDIUM=$(count_prose_tag MEDIUM)
  LOW=$(count_prose_tag LOW)
  MINOR=$(count_prose_tag MINOR)
  TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW + MINOR))

  if   [[ $TOTAL -eq 0 ]]; then
    GRADE="A+"
  elif [[ $CRITICAL -gt 0 ]]; then
    GRADE="E$(modifier_for_count $CRITICAL)"
  elif [[ $HIGH -gt 0 ]]; then
    GRADE="D$(modifier_for_count $HIGH)"
  elif [[ $MEDIUM -gt 0 ]]; then
    GRADE="C$(modifier_for_count $MEDIUM)"
  elif [[ $LOW -gt 0 ]]; then
    GRADE="B$(modifier_for_count $LOW)"
  else
    if [[ $MINOR -le 5 ]]; then GRADE="A"; else GRADE="A-"; fi
  fi

  echo "$GRADE"
  if [[ "$EXPLAIN" -eq 1 ]]; then
    cat >&2 <<EOF
Issue counts (legacy prose mode):
  CRITICAL: $CRITICAL
  HIGH:     $HIGH
  MEDIUM:   $MEDIUM
  LOW:      $LOW
  MINOR:    $MINOR
  TOTAL:    $TOTAL
Grade: $GRADE
EOF
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Schema-table parsing path (new default)
#
# The 7-column ledger schema is:
#   | # | Severity | Status | Doc | Line | Description | Evidence |
#
# After split($0, cols, "|") on a row like "| 1 | [HIGH] | Pending | ...":
#   cols[1] = "" (empty, before leading |)
#   cols[2] = " 1 "       -- the row-counter (#) column
#   cols[3] = " [HIGH] "  -- the Severity column (graded)
#   cols[4] = " Pending "  -- the Status column (Pending/Recurred counted)
#
# Severity tags in cols[5..8] (Doc, Line, Description, Evidence) are ignored.
# This is the fix for the cycle-7 bug where summary prose in the old format
# would inject severity tags into the grep count.
# ---------------------------------------------------------------------------

CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
MINOR=0

COUNTS=$(echo "$CONTENT" | awk '
function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}
/^\|/ {
  # Skip separator rows (|---|...) -- cells that are purely dashes/colons
  if ($0 ~ /^\|[[:space:]]*[-:]+[[:space:]]*\|/) next

  # Split on literal pipe; cols[1] is empty (before leading |)
  n = split($0, cols, "|")
  if (n < 5) next  # need at least cols[3] (Severity) and cols[4] (Status)

  severity = trim(cols[3])
  status   = trim(cols[4])

  # Skip header rows
  if (severity == "Severity") next
  if (severity == "#")        next

  # Match Severity column against the bracketed severity enum only.
  # Any other value (including bare text) is skipped -- protects against
  # narrative table rows and the cycle-7 description-text false-positive.
  if      (severity == "[CRITICAL]") sev = "CRITICAL"
  else if (severity == "[HIGH]")     sev = "HIGH"
  else if (severity == "[MEDIUM]")   sev = "MEDIUM"
  else if (severity == "[LOW]")      sev = "LOW"
  else if (severity == "[MINOR]")    sev = "MINOR"
  else next

  # Only count Pending or Recurred rows
  if (status != "Pending" && status != "Recurred") next

  print sev
}
')

while IFS= read -r sev; do
  case "$sev" in
    CRITICAL) CRITICAL=$((CRITICAL + 1)) ;;
    HIGH)     HIGH=$((HIGH + 1)) ;;
    MEDIUM)   MEDIUM=$((MEDIUM + 1)) ;;
    LOW)      LOW=$((LOW + 1)) ;;
    MINOR)    MINOR=$((MINOR + 1)) ;;
  esac
done <<< "$COUNTS"

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW + MINOR))

# Compute grade
if   [[ $TOTAL -eq 0 ]]; then
  GRADE="A+"
elif [[ $CRITICAL -gt 0 ]]; then
  GRADE="E$(modifier_for_count $CRITICAL)"
elif [[ $HIGH -gt 0 ]]; then
  GRADE="D$(modifier_for_count $HIGH)"
elif [[ $MEDIUM -gt 0 ]]; then
  GRADE="C$(modifier_for_count $MEDIUM)"
elif [[ $LOW -gt 0 ]]; then
  GRADE="B$(modifier_for_count $LOW)"
else
  # Only minors remain
  if [[ $MINOR -le 5 ]]; then
    GRADE="A"
  else
    GRADE="A-"
  fi
fi

echo "$GRADE"

if [[ "$EXPLAIN" -eq 1 ]]; then
  cat >&2 <<EOF
Issue counts (schema-table mode):
  CRITICAL: $CRITICAL
  HIGH:     $HIGH
  MEDIUM:   $MEDIUM
  LOW:      $LOW
  MINOR:    $MINOR
  TOTAL:    $TOTAL
Grade: $GRADE
EOF
fi
