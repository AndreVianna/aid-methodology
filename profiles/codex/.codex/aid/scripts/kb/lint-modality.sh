#!/usr/bin/env bash
# lint-modality.sh -- every requirement and acceptance criterion must carry an explicit modality.
#
# WHY THIS GATE EXISTS
# The canonical severity scale's FIRST STEP reads the violated rule's modality: MUST continues to the
# blast-radius step, SHOULD is [LOW], COULD is [MINOR]. An untagged requirement gives step 1 no input, so
# severity silently falls back to the judgment the scale was built to remove. The same applies to the
# defect taxonomy's "unmet criterion" class, which INHERITS the criterion's modality -- with none to
# inherit, it has nothing to compute.
#
# So this is not a style rule. An untagged criterion makes every finding against it ungradeable.
#
# WHY AT AUTHORING TIME
# A missing modality is a criteria gap once a reviewer meets it -- and a gap blocks a grade and costs a
# human round trip. Catching it when the requirement is written is strictly cheaper than catching it when
# something is being graded against it.
#
# WHAT IT CHECKS
#   - every `| FR-* |` / `| NFR-* |` row carries a modality from the closed set
#   - every `| AC-* |` row does too
#   - the tag is one of MUST / SHOULD / COULD, in that spelling
# A row struck through (`~~FR-A7~~`) is a CUT requirement and is skipped: cut requirements legitimately
# keep their historical shape, and forcing a modality onto them would corrupt the record.
#
# USAGE
#   lint-modality.sh --root DIR [--quiet]
#   lint-modality.sh --file PATH [...]
#
# EXIT CODES (linter alphabet, per the coding standard: 0 clean, 1 violations, 2 usage)
#   0  every requirement and acceptance criterion carries a valid modality
#   1  at least one is missing or non-conforming
#   2  usage error, or a named file is unreadable
set -uo pipefail

SCRIPT_NAME="lint-modality.sh"
ROOT=""
FILES=()
QUIET=0

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit 2; }
usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)  [[ $# -lt 2 ]] && die "--root requires a directory"; ROOT="$2"; shift 2 ;;
        --file)  [[ $# -lt 2 ]] && die "--file requires a path"; FILES+=("$2"); shift 2 ;;
        --quiet) QUIET=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

if [[ -n "$ROOT" ]]; then
    [[ -d "$ROOT" ]] || die "not a directory: $ROOT"
    while IFS= read -r f; do FILES+=("$f"); done < <(
        find "$ROOT" -type f \( -name 'REQUIREMENTS.md' -o -name 'SPEC.md' \) 2>/dev/null | sort
    )
fi

[[ ${#FILES[@]} -gt 0 ]] || die "nothing to lint -- give --root or at least one --file"

# An EXPLICITLY NAMED file that does not exist is a usage error, not a clean result. Skipping it would
# make a typo'd path report "0 rows, all valid" and exit 0 -- a gate that silently checks nothing is
# worse than no gate, because it produces a passing record. (Files discovered via --root cannot hit this.)
for f in "${FILES[@]}"; do
    [[ -e "$f" ]] || die "no such file: $f"
    [[ -r "$f" ]] || die "exists but is not readable: $f"
done

violations=0
checked=0

for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || continue
    # ONE pass decides both what counts as a requirement row and whether it is tagged. An earlier draft
    # counted rows in a second awk with its own copy of the ID pattern; two copies of the same rule drift,
    # and when they do the reported total silently stops describing what was actually inspected.
    while IFS= read -r report; do
        [[ -z "$report" ]] && continue
        if [[ "$report" == __COUNT__* ]]; then
            checked=$((checked + ${report#__COUNT__}))
            continue
        fi
        violations=$((violations + 1))
        [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$report"
    done < <(
        awk -v FNAME="$f" '
          function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
          /^\|/ {
            # NO separate separator-row test. It used to sit here and was pure redundancy: a separator
            # cell trims to "---", which the ID anchor below already rejects for not being an ID. Proved
            # by mutation -- deleting it left the whole suite green, which is what made MG14 an assertion
            # that could not fail. A guard that restates a rule its neighbour already enforces is a
            # second implementation waiting to drift, so the anchor is left as the single decider.
            n = split($0, c, "|")
            id = trim(c[2])
            gsub(/`/, "", id)

            # A struck-through row is a CUT requirement: it keeps its historical shape on purpose.
            # Decided from the ID CELL ALONE. The earlier form also skipped on `$0 ~ /~~(FR|NFR|AC)-/`
            # -- the WHOLE ROW -- so a live untagged requirement whose description merely NAMES the cut
            # requirement it replaces ("supersedes ~~FR-A7~~") was dropped from both the violation list
            # and the count. And the `id ~ /^~~/` limb beside it was unreachable: the ID anchor below
            # ran first and had already rejected `~~FR-A7~~` for not being a bare ID, so the over-broad
            # limb was the only one doing any work. Strip the marks, then decide.
            cut = (id ~ /^~~.*~~$/)
            bare = id
            gsub(/~~/, "", bare)

            # Only requirement and acceptance-criterion rows are in scope, and the ID cell must BE an
            # id -- not merely start with one. A results table can legitimately hold a row whose first
            # cell reads "FR-G2 resolution -- [UNRESOLVED]"; anchoring the match at both ends keeps
            # those out. (A looser prefix match reported five such rows as untagged requirements.)
            # The trailing `[a-z]?` admits a SPLIT requirement -- FR-B5a / FR-B5b. Without it the anchor
            # silently skipped both halves, FR-B5a being the requirement that mandates modality at all,
            # and the reported count understated the population the script claimed to have checked.
            if (bare !~ /^(FR|NFR|AC)-[A-Z]?[0-9]+[a-z]?$/) next

            if (cut) next

            CHECKED++

            # The modality is expected in the cell immediately after the ID.
            mod = trim(c[3])
            gsub(/[*`]/, "", mod)

            if (mod == "") {
              printf "%s:%d: %s has an EMPTY modality cell -- step 1 of the severity scale has no input\n", FNAME, FNR, id
              next
            }
            if (mod != "MUST" && mod != "SHOULD" && mod != "COULD") {
              # Distinguish "wrote something else there" from "has no modality column at all", because
              # the fixes differ: one is a typo, the other is a schema change. Three cases, not two --
              # a wrong WORD in a present column used to fall into the "no modality column" branch,
              # which is the one diagnosis this script says it exists to keep separate: it sent the
              # author after a schema change when the fix was a typo.
              if (mod ~ /^(must|should|could|Must|Should|Could)$/) {
                printf "%s:%d: %s modality \"%s\" is not in the canonical spelling (MUST / SHOULD / COULD)\n", FNAME, FNR, id, mod
              } else if (mod ~ /^[A-Za-z][A-Za-z-]*$/) {
                printf "%s:%d: %s modality \"%s\" is not one of MUST / SHOULD / COULD\n", FNAME, FNR, id, mod
              } else {
                printf "%s:%d: %s has no modality column -- cell 2 holds \"%s\"\n", FNAME, FNR, id, substr(mod, 1, 46)
              }
            }
          }
          END { printf "__COUNT__%d\n", CHECKED+0 }
        ' "$f" 2>/dev/null
    )
done

# ZERO ROWS INSPECTED. Printing "OK: 0 requirement(s) / criterion(s) all carry a valid modality" is a
# positive assertion about content that was never read. But zero is not automatically wrong, and the
# two modes differ in what it MEANS -- so they are answered differently rather than with one blunt rule:
#
#   --file  a named file legitimately holds no requirement rows (a results table, a file carrying only
#           a cut requirement). There is nothing to complain about, so exit 0 -- but say what actually
#           happened instead of certifying a population of zero.
#   --root  a sweep that discovers files and then inspects nothing across all of them is a gate that is
#           not reaching the corpus: a changed row shape, a moved tree, a neutered pattern. That is
#           indistinguishable from a clean tree in the exit code, which is why it gets the loud answer.
#           Same non-vacuity floor the repo's other repo-wide guards carry.
if [[ "$checked" -eq 0 ]]; then
    if [[ -n "$ROOT" ]]; then
        echo "ERROR: ${SCRIPT_NAME}: swept ${#FILES[@]} file(s) under '${ROOT}' and inspected 0 requirement/criterion rows -- the sweep is not reaching the corpus, so this is not a pass. Verify the tables use the '| FR-A1 | MUST | ... |' row shape." >&2
        exit 2
    fi
    [[ "$QUIET" -eq 1 ]] || echo "OK: ${SCRIPT_NAME}: no requirement or acceptance-criterion rows found in ${#FILES[@]} file(s) -- nothing to check"
    exit 0
fi

if [[ "$violations" -eq 0 ]]; then
    [[ "$QUIET" -eq 1 ]] || echo "OK: ${SCRIPT_NAME}: ${checked} requirement(s) / criterion(s) across ${#FILES[@]} file(s) all carry a valid modality"
    exit 0
fi

# The FAIL summary goes to STDOUT, with the per-row reports it counts. It used to go to stderr while
# they went to stdout, so one diagnostic was split across two streams and a caller keeping either
# lost half of it. The contract is now uniform: stdout carries the lint REPORT (OK, or the rows plus
# this summary); stderr carries only invocation errors, which is what `die` already does.
if [[ "$QUIET" -eq 0 ]]; then
    cat <<EOF

FAIL: ${SCRIPT_NAME}: ${violations} of ${checked} rows lack a usable modality.

Every requirement and acceptance criterion needs one of MUST / SHOULD / COULD in the cell after its ID:

  | FR-A1 | MUST   | The system does X. |
  | AC-1  | SHOULD | Given Y, when Z, then W. |

This is what step 1 of the severity scale reads. Without it, a finding against the criterion cannot be
graded -- and once a reviewer meets it, the missing modality becomes a criteria gap that blocks the
grade and costs a human round trip.
EOF
fi
exit 1
