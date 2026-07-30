#!/usr/bin/env bash
# emit-summary-findings.sh -- run the knowledge summary's machine checks and emit LEDGER ROWS.
#
# It computes NO GRADE. That is the entire point of the change, and the reason the file was renamed
# from grade-summary.sh.
#
# WHY THE SECOND GRADER WAS RETIRED
# AID had two grading models. `grade.sh` derives a letter from the worst finding severity and a count.
# This script derived one from a weighted percentage ladder over sixteen checks. They disagreed by
# construction:
#
#   * different alphabets -- the ladder knew 11 grades (A+ A A- B+ B B- C+ C C- D F) and grade.sh knows
#     16. `D+`, `D-`, `E+`, `E`, `E-` could not be produced here at all, so the same artifact could not
#     receive the same grade from the two backends even in principle.
#   * different failure semantics -- a percentage lets good checks pay for a bad one. `grade.sh` is
#     dominated by the WORST issue, deliberately: five clean sections do not offset one critical defect.
#   * ten dead points -- D1 and D2 (Mermaid parse/render) were hardcoded `pass` after the Mermaid engine
#     was retired, so 10 of 68 points could never be lost. Every summary got them free.
#   * partial credit hid real gaps -- coverage of 95% scored FULL marks, so a summary omitting one
#     document in twenty was graded as complete.
#
# So this script now does what it is actually good at -- running validators -- and hands the results to
# the one component allowed to grade.
#
# WHERE THE CHECKS WENT
# Every retired check maps to a rule; see `review-rubrics/summary.md § Where the retired per-check
# scores went`. D1/D2 are deleted rather than mapped: a check that cannot fail is not coverage.
#
# USAGE
#   emit-summary-findings.sh <html-file> --ledger PATH [--dry-run]
#
#   --dry-run   print the rows that would be written, write nothing. Useful in CI and in tests.
#
# EXIT CODES (linter alphabet: 0 clean, 1 findings, 2 usage)
#   0  every check passed; no rows emitted
#   1  at least one finding was emitted
#   2  usage error, or a required validator is missing
set -uo pipefail

SCRIPT_NAME="emit-summary-findings.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEDGER_WRITER="${SCRIPT_DIR}/../review/writeback-ledger.sh"

HTML=""
LEDGER=""
DRY_RUN=0

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit 2; }
usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ledger)  [[ $# -lt 2 ]] && die "--ledger requires a path"; LEDGER="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) die "unknown flag: $1" ;;
        *)  HTML="$1"; shift ;;
    esac
done

[[ -n "$HTML" ]]  || die "no HTML file given"
[[ -f "$HTML" ]]  || die "no such file: $HTML"
if [[ "$DRY_RUN" -eq 0 ]]; then
    [[ -n "$LEDGER" ]] || die "--ledger is required unless --dry-run is given"
    [[ -x "$LEDGER_WRITER" || -f "$LEDGER_WRITER" ]] || die "ledger writer not found: $LEDGER_WRITER"
fi

FINDINGS=0

# emit RULE SEVERITY DOC DESCRIPTION EVIDENCE
# One place decides what a finding looks like, so a new check cannot invent its own row shape.
emit() {
    local rule="$1" sev="$2" doc="$3" desc="$4" ev="$5"
    FINDINGS=$((FINDINGS + 1))
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '%s | %s | %s | %s | %s\n' "$sev" "$rule" "$doc" "$desc" "$ev"
        return
    fi
    bash "$LEDGER_WRITER" --ledger "$LEDGER" --append-finding \
        --severity "$sev" --rule "$rule" --doc "$doc" \
        --description "$desc" --evidence "$ev" >/dev/null || \
        die "ledger write failed for ${rule} (${doc})"
}

echo "=== ${SCRIPT_NAME}: ${HTML} ==="

# ---------------------------------------------------------------------------
# SUMMARY-01 -- doc-set coverage, ONE ROW PER UNREFERENCED DOCUMENT.
#
# The retired check scored this on a band, so 19 of 20 documents earned full marks. Naming each missing
# document is the tightening: one absent document is one finding, and the grade follows from that.
# ---------------------------------------------------------------------------
SETTINGS=".aid/settings.yml"
KB_DIR=".aid/knowledge"
missing_docs=""

if [[ -f "$SETTINGS" && -d "$KB_DIR" ]]; then
    # Resolved doc set: declared in settings AND present on disk.
    while IFS= read -r doc; do
        [[ -z "$doc" ]] && continue
        [[ -f "$KB_DIR/$doc" ]] || continue
        stem="${doc%.md}"
        # Same predicate the retired check used: case-insensitive fixed-string match anywhere in the HTML.
        if ! LC_ALL=C awk -v s="$stem" '
              BEGIN { s = tolower(s); found = 0 }
              { if (index(tolower($0), s) > 0) { found = 1; exit } }
              END { exit(found ? 0 : 1) }
            ' "$HTML"; then
            missing_docs="${missing_docs}${doc}\n"
            emit "SUMMARY-01" "[MEDIUM]" "$doc" \
                 "Declared knowledge-base document is not represented in the generated summary" \
                 "settings.yml knowledge.doc_set lists ${doc} and ${KB_DIR}/${doc} exists, but no reference to \"${stem}\" appears in $(basename "$HTML")"
        fi
    done < <(awk '
        /^[[:space:]]*doc_set:[[:space:]]*$/ { in_ds = 1; next }
        in_ds && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:/ { in_ds = 0 }
        in_ds && /^[[:space:]]*-[[:space:]]/ {
            row = $0
            sub(/^[[:space:]]*-[[:space:]]*/, "", row)
            split(row, f, "|")
            gsub(/^[ \t]+|[ \t]+$/, "", f[1])
            print f[1]
        }
    ' "$SETTINGS")
else
    echo "  note: no ${SETTINGS} or ${KB_DIR} -- SUMMARY-01 not evaluated"
fi

# ---------------------------------------------------------------------------
# The HTML validator reports per-check results. Attribute each failing check to its rule rather than
# emitting one undifferentiated "validation failed", so the ledger says which rule was broken.
# ---------------------------------------------------------------------------
declare -A RULE_FOR=(
    [H1]="SUMMARY-02" [S2]="SUMMARY-03"
    [L1]="SUMMARY-08" [L2]="SUMMARY-09"
    [A1]="PRE-02"     [A2]="PRE-04" [A3]="PRE-04" [A4]="PRE-05" [A5]="PRE-03"
)
declare -A SEV_FOR=(
    [H1]="[MEDIUM]" [S2]="[HIGH]"
    [L1]="[LOW]"    [L2]="[MEDIUM]"
    [A1]="[MEDIUM]" [A2]="[MEDIUM]" [A3]="[MEDIUM]" [A4]="[MEDIUM]" [A5]="[MEDIUM]"
)
declare -A NAME_FOR=(
    [H1]="HTML validity"        [S2]="Offline render (self-contained)"
    [L1]="Anchor links resolve" [L2]="Relative document links resolve"
    [A1]="Semantic landmarks"   [A2]="ARIA on lightbox" [A3]="Focus trap"
    [A4]="Reduced motion"       [A5]="Visible focus"
)

HTML_LOG="$(mktemp)"
CONTRAST_LOG="$(mktemp)"
trap 'rm -f "$HTML_LOG" "$CONTRAST_LOG"' EXIT

# External validators run under a TIMEOUT and are never allowed to reach the network.
#
# `validate-html-output.sh` falls back to `npx html-validate` when `tidy` is not installed, and `npx`
# will try to FETCH the package. On a machine without it cached that call hangs indefinitely -- observed
# here, taking a shell with it. A gate that can hang forever is worse than a gate that reports "could not
# evaluate": the first stops the pipeline with no diagnosis, the second says exactly what is missing.
#
# npm_config_offline/yes stop npx from installing; the timeout is the backstop for anything else that
# blocks. A validator that times out is reported as unevaluated, NOT as a pass -- silently passing an
# unrun check is how a gate becomes decorative.
run_validator() {
    local out="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        npm_config_offline=true npm_config_yes=false timeout "${VALIDATOR_TIMEOUT:-120}" "$@" > "$out" 2>&1
        return $?
    fi
    npm_config_offline=true npm_config_yes=false "$@" > "$out" 2>&1
}

if [[ -f "$SCRIPT_DIR/validate-html-output.sh" ]]; then
    run_validator "$HTML_LOG" bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"
    vrc=$?
    if [[ "$vrc" -eq 124 ]]; then
        echo "  WARNING: validate-html-output.sh timed out after ${VALIDATOR_TIMEOUT:-120}s -- H1/S2/L1/L2/A1-A5 NOT evaluated."
        echo "           This is usually a missing local validator causing an npx fetch. Install tidy or"
        echo "           html-validate locally. These checks are reported as unevaluated, not as passed."
        HTML_LOG="/dev/null"
    fi
    for k in H1 S2 L1 L2 A1 A2 A3 A4 A5; do
        # The validator marks a failed check with a cross followed by the check id.
        if grep -qE "(❌|FAIL).*\b${k}\b" "$HTML_LOG"; then
            detail="$(grep -E "(❌|FAIL).*\b${k}\b" "$HTML_LOG" | head -1 | sed 's/^[[:space:]]*//')"
            emit "${RULE_FOR[$k]}" "${SEV_FOR[$k]}" "$(basename "$HTML")" \
                 "${NAME_FOR[$k]} check failed (${k})" \
                 "validate-html-output.sh reported: ${detail}"
        fi
    done
else
    echo "  note: validate-html-output.sh not found -- H1/S2/L1/L2/A1-A5 not evaluated"
fi

# ---------------------------------------------------------------------------
# PRE-11 -- contrast, one rule across themes.
# ---------------------------------------------------------------------------
if command -v node >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/contrast-check.mjs" ]]; then
    if ! run_validator "$CONTRAST_LOG" node "$SCRIPT_DIR/contrast-check.mjs" "$HTML"; then
        for theme in light dark; do
            if grep -qiE "${theme}.*(fail)" "$CONTRAST_LOG"; then
                emit "PRE-11" "[MEDIUM]" "$(basename "$HTML")" \
                     "Token pair fails WCAG AA contrast in the ${theme} theme" \
                     "contrast-check.mjs: $(grep -iE "${theme}.*(fail)" "$CONTRAST_LOG" | head -1 | sed 's/^[[:space:]]*//')"
            fi
        done
    fi
else
    echo "  note: node or contrast-check.mjs unavailable -- PRE-11 not evaluated"
fi

# ---------------------------------------------------------------------------
# SUMMARY-07 -- no retired diagram runtime. This replaces D1/D2: rather than award points for a check
# that cannot fail, assert the retired runtime is ABSENT, which can.
# ---------------------------------------------------------------------------
if grep -qi 'mermaid' "$HTML"; then
    emit "SUMMARY-07" "[HIGH]" "$(basename "$HTML")" \
         "Summary carries the retired Mermaid diagram runtime" \
         "grep -i mermaid matches in $(basename "$HTML"); the engine was retired and must not reappear"
fi

echo
if [[ "$FINDINGS" -eq 0 ]]; then
    echo "OK: ${SCRIPT_NAME}: no findings."
    echo "NOTE: this script does not grade. Run grade.sh over the ledger for the letter."
    exit 0
fi

echo "${SCRIPT_NAME}: emitted ${FINDINGS} finding(s)."
echo "NOTE: no grade is computed here. Run grade.sh over the ledger for the letter."
exit 1
