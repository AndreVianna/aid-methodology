#!/usr/bin/env bash
# check-gaps.sh -- the pre-grade gate. Refuses to let a grade be computed over an open criteria gap.
#
# WHY A SEPARATE SCRIPT FROM gap-register.sh
# This is a LINTER: its exit code is the answer (0 clean / 1 gap found), the way every other lint in
# the tree behaves. gap-register.sh is a STATE WRITER, whose exit codes must distinguish "bad
# argument" from "file unreadable" from "write failed". One script cannot carry both alphabets
# without one of them becoming a lie, so they are split.
#
# WHY THE GATE IS NOT IN grade.sh
# NFR-1 forbids changing grade.sh's behaviour. And grade-inertness is the wrong tool anyway: an inert
# row cannot STOP a grade, only fail to affect it. Stopping requires a gate outside the grader.
#
# WHAT COUNTS AS BLOCKING
# Only `[GAP:CRITERIA]`. The other two discriminators are deliberately non-blocking:
#   [GAP:CRITERIA]     no rule in either authority ladder speaks to the concern  -> BLOCKS
#   [GAP:CRITERIA:NB]  same, but the depth cap was reached, or a family rule set covered it
#   [GAP:EVIDENCE]     no available evidence can confirm or deny the claim
# A gap row whose Status is Resolved never blocks, whatever its discriminator.
#
# USAGE
#   check-gaps.sh --ledger PATH [--ledger PATH ...] [--quiet]
#
#   --ledger may be repeated. That is not a convenience: under aid-discover's parallel mandates each
#   reviewer writes its OWN scratch ledger, and U-/G- rows are deliberately NOT merged into the panel
#   ledger. Reading across ledgers without merging is the only way the batch forms at all.
#
# EXIT CODES (linter alphabet -- the exit code IS the finding)
#   0  no open blocking gap; the caller may grade
#   1  at least one open [GAP:CRITERIA] row -- do NOT grade
#   2  usage error (no --ledger given, or a named ledger is unreadable)
set -uo pipefail

SCRIPT_NAME="check-gaps.sh"
LEDGERS=()
QUIET=0

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit 2; }

usage() {
    sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ledger) [[ $# -lt 2 ]] && die "--ledger requires a path"; LEDGERS+=("$2"); shift 2 ;;
        --quiet)  QUIET=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[[ ${#LEDGERS[@]} -gt 0 ]] || die "at least one --ledger is required"

# A ledger that does not exist is not an error: a review may legitimately have produced none yet, and
# treating absence as failure would block every clean first run. A ledger that exists but cannot be
# read IS an error, because silently passing it would defeat the gate.
for l in "${LEDGERS[@]}"; do
    [[ -e "$l" && ! -r "$l" ]] && die "ledger exists but is not readable: $l"
done

found=0
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    found=$((found + 1))
    [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$line"
done < <(
    for l in "${LEDGERS[@]}"; do
        [[ -f "$l" ]] || continue
        awk -v L="$l" '
          function is_sep(s) { return s ~ /^\|[ \t:|-]+\|$/ }
          /^\|/ {
            if (is_sep($0)) next
            n = split($0, c, "|")
            id = c[2]; gsub(/[ `]/, "", id)
            if (id !~ /^G-/) next                      # only gap rows can block

            status = c[4]; gsub(/^[ \t]+|[ \t]+$/, "", status)
            if (status == "Resolved") next             # already dealt with

            # The discriminator is the FIRST token of Description. Match the blocking form only,
            # and anchor it so [GAP:CRITERIA:NB] does not match [GAP:CRITERIA].
            desc = c[8]; gsub(/^[ \t]+/, "", desc)
            if (desc !~ /^\[GAP:CRITERIA\]/) next

            key = ""
            ev = c[9]
            if (match(ev, /gap-key=[^;|]+/)) {
                key = substr(ev, RSTART + 8, RLENGTH - 8)
                gsub(/^[ \t]+|[ \t]+$/, "", key)
            }
            printf "%s: %s  %s  key=%s\n", L, id, status, (key == "" ? "(none)" : key)
          }
        ' "$l"
    done
)

if [[ "$found" -eq 0 ]]; then
    [[ "$QUIET" -eq 1 ]] || echo "OK: ${SCRIPT_NAME}: no open criteria gap; grading may proceed"
    exit 0
fi

if [[ "$QUIET" -eq 0 ]]; then
    cat >&2 <<EOF

BLOCKED: ${SCRIPT_NAME}: ${found} open criteria gap(s). Do NOT grade.

A criteria gap means the review has no rule to judge the artifact by. Grading now would either
invent a criterion or silently score the artifact against nothing -- both of which this gate exists
to prevent. Resolve the gap, or demote it to [GAP:CRITERIA:NB] if it is genuinely non-blocking.

Next: ask the user once for the whole batch, record the answer with
      gap-register.sh --promote ... , then re-run this gate.
EOF
fi
exit 1
