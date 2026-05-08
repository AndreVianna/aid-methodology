#!/usr/bin/env bash
# grade.sh — Compute AID grade from a structured issue list.
#
# Reads a markdown file (or stdin) containing issue tags of the form
# [CRITICAL], [HIGH], [MEDIUM], [LOW], [MINOR]. Counts occurrences,
# applies the universal AID rubric (worst severity dominates, count
# determines modifier), and prints the resulting grade.
#
# Usage:
#   grade.sh REVIEW.md
#   cat REVIEW.md | grade.sh
#   grade.sh --explain REVIEW.md           # also prints count breakdown
#   grade.sh --non-functional              # forces F (build/run failed)
#
# Exit codes:
#   0 — grade printed successfully
#   1 — input could not be read
#   2 — invalid arguments

set -euo pipefail

EXPLAIN=0
NON_FUNCTIONAL=0
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
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
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

# Strip content inside fenced code blocks (``` ... ```) before counting.
# This prevents false positives from prose-quoted severity tags inside code
# examples ("the previous code had a [CRITICAL] race condition that's now fixed").
# Fence detection is line-based; opening and closing fences are excluded along
# with everything between them.
CONTENT=$(echo "$CONTENT" | awk '
  /^[[:space:]]*```/ { in_fence = !in_fence; next }
  !in_fence { print }
')

# Strip inline backtick content (`...`) before counting. Prose that documents
# the tag convention often quotes the tag in backticks (e.g., "tag with `[CRITICAL]`")
# — these are documentation, not actual issues. Real issues are tagged at the
# start of a line or in a table cell, both of which use bare brackets.
CONTENT=$(echo "$CONTENT" | sed -E 's/`[^`]*`//g')

# Count each severity tag (case-sensitive on the bracketed ALL-CAPS form).
# `grep` exits 1 when no matches are found; under pipefail this would abort
# the script. We suppress that with `|| true` so zero counts return cleanly.
count_tag() {
  local tag="$1"
  { echo "$CONTENT" | grep -oE "\[$tag\]" || true; } | wc -l | tr -d ' '
}

CRITICAL=$(count_tag CRITICAL)
HIGH=$(count_tag HIGH)
MEDIUM=$(count_tag MEDIUM)
LOW=$(count_tag LOW)
MINOR=$(count_tag MINOR)

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW + MINOR))

# Apply the rubric: worst severity dominates, count determines the modifier.
modifier_for_count() {
  local n="$1"
  if   [[ $n -eq 1 ]]; then echo "+"
  elif [[ $n -le 5 ]]; then echo ""
  else                      echo "-"
  fi
}

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
Issue counts:
  CRITICAL: $CRITICAL
  HIGH:     $HIGH
  MEDIUM:   $MEDIUM
  LOW:      $LOW
  MINOR:    $MINOR
  TOTAL:    $TOTAL
Grade: $GRADE
EOF
fi
