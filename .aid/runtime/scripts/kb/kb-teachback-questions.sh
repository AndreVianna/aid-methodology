#!/usr/bin/env bash
# kb-teachback-questions.sh -- deterministic teach-back question-set generator.
#
# From .aid/generated/candidate-concepts.md, emits one "What is X?" question
# for every emitted Term row where:
#   (a) Spread >= 2  (cross-source lexical terms), OR
#   (b) Source == synthesis  (synthesis-tagged concepts; Spread is empty/dash)
#
# The OR clause is load-bearing: synthesis rows are emitted with an empty/'-'
# Spread, so a bare spread>=2 numeric filter would drop every synthesis concept.
#
# PLUS the one fixed engine question:
#   "Explain how this system works, in its own language."
#
# Bounded by the emitted table (never invents un-emitted terms).
# ASCII bash; coreutils only (grep/awk/sort/tr). No LLM, no network.
# Byte-reproducible: re-runs on the same input are identical.
#
# Usage:
#   kb-teachback-questions.sh [--concepts PATH] [--output PATH]
#
# Defaults:
#   --concepts  .aid/generated/candidate-concepts.md
#   --output    stdout
#
# Output format (plain text, one question per line):
#   What is <Term>?
#   ...
#   Explain how this system works, in its own language.
#
# Exit codes:
#   0  success
#   1  concepts file not found or not readable

set -euo pipefail

CONCEPTS=".aid/generated/candidate-concepts.md"
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --concepts) CONCEPTS="$2"; shift 2 ;;
    --output)   OUTPUT="$2";   shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "kb-teachback-questions.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$CONCEPTS" ]]; then
  echo "kb-teachback-questions.sh: concepts file not found: $CONCEPTS" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Parse the Ranked Candidates table from candidate-concepts.md.
#
# Table header (9 columns):
#   | # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source |
#   col: 1   2        3      4       5      6        7          8          9
#
# Selection rule (awk, pipe-delimited):
#   include row if:
#     field 2 (Source) == "synthesis"   -- synthesis rows (Spread is empty/dash)
#     OR
#     field 6 (Spread) is a number >= 2 -- cross-source lexical rows
#
# Row lines start with "| " followed by a digit (data rows only, skipping header).
# Backtick-quoted terms are stripped (harvest rows use `Term`; synthesis rows may too).
# ---------------------------------------------------------------------------

_emit_questions() {
  local concepts="$1"

  # Extract Term column from qualifying rows, sort for stability, then emit.
  # awk: split on ' | ' (with surrounding spaces) to get clean field values.
  awk -F' \\| ' '
    # Only data rows: line starts with "| " then a digit
    /^\| [0-9]/ {
      # Splitting "| 1 | harvest | `Term` | ..." on " | " yields:
      #   $1 = "| 1"   $2 = Source  $3 = Term    $4 = Class
      #   $5 = Freq     $6 = Spread  $7 = Channels  $8 = Salience  $9 = "Example |"
      source = $2
      term   = $3
      spread = $6

      # Strip leading/trailing whitespace
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", source)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", term)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", spread)

      # Strip backtick quoting from Term (harvest rows emit `Term`)
      gsub(/^`|`$/, "", term)

      # Skip header row or malformed rows
      if (term == "Term" || term == "") next

      # Selection: synthesis rows (any spread) OR spread >= 2 numeric
      selected = 0
      if (source == "synthesis") {
        selected = 1
      } else {
        # spread must be a valid integer >= 2
        if (spread ~ /^[0-9]+$/ && spread + 0 >= 2) {
          selected = 1
        }
      }

      if (selected) print term
    }
  ' "$concepts" | sort -u
}

# ---------------------------------------------------------------------------
# Emit output
# ---------------------------------------------------------------------------

if [[ -n "$OUTPUT" ]]; then
  {
    _emit_questions "$CONCEPTS" | while IFS= read -r term; do
      echo "What is ${term}?"
    done
    echo "Explain how this system works, in its own language."
  } > "$OUTPUT"
else
  _emit_questions "$CONCEPTS" | while IFS= read -r term; do
    echo "What is ${term}?"
  done
  echo "Explain how this system works, in its own language."
fi
