#!/usr/bin/env bash
# emit-summary-findings.sh -- run the knowledge summary's machine checks and emit LEDGER ROWS.
#
# It computes NO GRADE. That is the entire point of the change, and the reason the file was renamed
# from grade-summary.sh.
#
# WHY THE SECOND GRADER WAS RETIRED
# AID had two grading models. `grade.sh` derives a letter from the worst finding severity and a count.
# This script derived one from a weighted percentage ladder: 14 scored checks worth 68 points, plus a
# 30-point manual pool, plus 4 more checks (T1/T2/T3/NM) that carried zero weight and "blocked DONE" in
# prose only. The 14-and-68 are derived rather than asserted -- against the retired file:
#   git show 7a9df485:canonical/aid/scripts/summarize/grade-summary.sh \
#     | awk '/^declare -A WEIGHTS=\(/,/^\)/' | grep -oE '\[[A-Z0-9]+\]=[0-9]+' \
#     | awk -F= '{s+=$2} END {print NR, s}'
# They disagreed by construction:
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

# UNEVALUATED counts check groups that could not be run. It is NOT the same as zero findings, and
# conflating the two is how a gate becomes decorative: with no validators installed this script used to
# print "not evaluated" notes and exit 0 with "no findings", after which grade.sh grades an empty ledger
# A+ and the skill routes to APPROVAL. The exit-code contract in the header promises 2 for a missing
# validator, so honour it.
#
# Defined HERE, above every call site, not beside the exit check where it reads more naturally -- the
# first caller is the SUMMARY-01 branch a few lines below, and bash resolves a function only after its
# definition has been executed. Placed later, the call was a `command not found` on stderr that left
# UNEVALUATED at 0, so an unevaluated run still exited 1 and looked complete.
UNEVALUATED=0
# The note goes to STDERR, with the exit-2 ERROR that references it ("see the notes above"). Splitting
# them across streams put the explanation on stdout and the failure on stderr, so a caller that captures
# only stderr -- the normal way to log a failure -- got "see the notes above" and no notes.
unevaluated() { UNEVALUATED=$((UNEVALUATED + 1)); echo "  note: $1" >&2; }

# emit RULE SEVERITY DOC DESCRIPTION EVIDENCE
# One place decides what a finding looks like, so a new check cannot invent its own row shape.
# $6 (LINE) is optional and carries the check id where two checks share one rule. The reconcile join is
# `(Doc, Rule)` with Line as its ONLY tiebreaker (reviewer-ledger-schema.md § The join key): A2 and A3
# both map to PRE-04, so with Line left at `--` their rows are the same key and fixing the lightbox ARIA
# would silently reconcile the focus-trap finding to `Fixed` as well.
emit() {
    local rule="$1" sev="$2" doc="$3" desc="$4" ev="$5" line="${6:-}"
    FINDINGS=$((FINDINGS + 1))
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '%s | %s | %s | %s | %s | %s\n' "$sev" "$rule" "$doc" "${line:---}" "$desc" "$ev"
        return
    fi
    local -a line_arg=()
    [[ -n "$line" ]] && line_arg=(--line "$line")
    bash "$LEDGER_WRITER" --ledger "$LEDGER" --append-finding \
        --severity "$sev" --rule "$rule" --doc "$doc" "${line_arg[@]}" \
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
    # A settings.yml that EXISTS but declares no doc_set is not a pass. Without this the loop below ran
    # zero times, emitted nothing, and the script exited 0 "no findings" -- reporting a clean coverage
    # check against a doc-set it never had. `grading-rubric.md § COV` promises the opposite in as many
    # words: "reports itself as not evaluated rather than passing".
    DECLARED=0
    while IFS= read -r d; do [[ -n "$d" ]] && DECLARED=$((DECLARED + 1)); done < <(awk '
        /^[[:space:]]*doc_set:[[:space:]]*$/ { in_ds = 1; next }
        in_ds && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:/ { in_ds = 0 }
        in_ds && /^[[:space:]]*-[[:space:]]/ { print "row" }
    ' "$SETTINGS")
    if [[ "$DECLARED" -eq 0 ]]; then
        unevaluated "${SETTINGS} declares no knowledge.doc_set rows -- SUMMARY-01 not evaluated"
    fi

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
    unevaluated "no ${SETTINGS} or ${KB_DIR} -- SUMMARY-01 not evaluated"
fi

# ---------------------------------------------------------------------------
# The HTML validator reports per-check results. Attribute each failing check to its rule rather than
# emitting one undifferentiated "validation failed", so the ledger says which rule was broken.
# ---------------------------------------------------------------------------
declare -A RULE_FOR=(
    [H1]="SUMMARY-02" [S2]="SUMMARY-03"
    [L1]="SUMMARY-08" [L2]="SUMMARY-09"
    [A1]="PRE-02"     [A2]="PRE-04" [A3]="PRE-04" [A4]="PRE-05" [A5]="PRE-03"
    [NM]="SUMMARY-07"
    # Two of validate-html-output.sh's [Structural checks] -- it prints them with no id prefix, so the
    # key IS the label. Without these PRE-01 had no key at all and could never fire, though both are
    # MUST items in accessibility-checklist.md § Document level, the criterion PRE-01 cites.
    #
    # Its third structural check, `skip-link present`, is deliberately NOT mapped: the skip link is
    # declared in that checklist's separate `## Skip link` section, which no PRE rule cites, so pinning
    # it on PRE-01 would attribute a finding to a criterion that does not cover it. "No Criterion, no
    # row" binds this script as much as a reviewer. The unmapped-check guard below reports it as
    # unevaluated rather than passing it silently -- which is the honest outcome for a real check with
    # no rule to carry it.
    ["noscript fallback present"]="PRE-01"
    ["color-scheme: light dark"]="PRE-01"
)
declare -A SEV_FOR=(
    [H1]="[MEDIUM]" [S2]="[HIGH]"
    [L1]="[LOW]"    [L2]="[MEDIUM]"
    [A1]="[MEDIUM]" [A2]="[MEDIUM]" [A3]="[MEDIUM]" [A4]="[MEDIUM]" [A5]="[MEDIUM]"
    [NM]="[HIGH]"
    ["noscript fallback present"]="[MEDIUM]"
    ["color-scheme: light dark"]="[MEDIUM]"
)
declare -A NAME_FOR=(
    [H1]="HTML validity"        [S2]="Offline render (self-contained)"
    [L1]="Anchor links resolve" [L2]="Relative document links resolve"
    [A1]="Semantic landmarks"   [A2]="ARIA on lightbox" [A3]="Focus trap"
    [A4]="Reduced motion"       [A5]="Visible focus"
    [NM]="No retired diagram runtime"
    ["noscript fallback present"]="Noscript fallback present"
    ["color-scheme: light dark"]="color-scheme declares light and dark"
)

HTML_LOG="$(mktemp)"
CONTRAST_LOG="$(mktemp)"
trap 'rm -f "$HTML_LOG" "$CONTRAST_LOG"' EXIT

# External validators run under a TIMEOUT and are never allowed to reach the network.
#
# `validate-html-output.sh` falls back to `npx html-validate` when `tidy` is not installed. It passes
# `--no` (no-install), so that call does NOT fetch -- an earlier version of this comment said it hangs
# indefinitely, which is not true of the script as it stands (measured: 1.7s when absent). The timeout
# stays as a backstop for any future caller that drops `--no`, and for anything else that blocks: a gate
# that can hang forever is worse than a gate that reports "could not
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

# check_failed ID LOGFILE -- did the HTML validator report ID as failed?
#
# The validator uses TWO line shapes and both must be recognised:
#   marker first:  "  ❌ H1. HTML validity (tidy reported errors)"   (H1, A*, L*, and NM.1/NM.2/NM.3)
#   marker last:   "  S2. Offline render [FAIL] found CDN reference(s)"  (S2, and NM's PASS line)
# The old detector required the marker to come FIRST, so **S2** -- emitted only in the second shape --
# could never fire and SUMMARY-03 was unreachable. Be precise about NM: its FAIL lines ARE marker-first,
# so the old detector did match them; NM was broken for an unrelated reason (a bare `grep -i mermaid`
# over the HTML -- see the SUMMARY-07 note below). The two are fixed together here, but they were not
# the same bug, and saying so kept a wrong claim in the file that a reader could check in one command.
#
# Both patterns anchor at line start and require the ID to be followed by a delimiter, so a mention of an
# id inside another line's prose or detail text cannot trip the wrong rule.
check_failed() {
    local k="$1" log="$2"
    grep -qE "^[[:space:]]*(❌|FAIL)[[:space:]]*${k}([.[:space:]]|\$)" "$log" && return 0
    grep -qE "^[[:space:]]*${k}([.[:space:]]).*\[FAIL\]" "$log" && return 0
    return 1
}

# check_detail ID LOGFILE -- the first reported line for ID, for the Evidence cell.
check_detail() {
    local k="$1" log="$2"
    grep -E "^[[:space:]]*((❌|FAIL)[[:space:]]*${k}([.[:space:]]|\$)|${k}([.[:space:]]).*\[FAIL\])" \
        "$log" | head -1 | sed 's/^[[:space:]]*//'
}

if [[ -f "$SCRIPT_DIR/validate-html-output.sh" ]]; then
    run_validator "$HTML_LOG" bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"
    vrc=$?
    if [[ "$vrc" -eq 124 ]]; then
        echo "  WARNING: validate-html-output.sh timed out after ${VALIDATOR_TIMEOUT:-120}s -- H1/S2/L1/L2/A1-A5 NOT evaluated." >&2
        echo "           This is usually a missing local validator causing an npx fetch. Install tidy or" >&2
        echo "           html-validate locally. These checks are reported as unevaluated, not as passed." >&2
        HTML_LOG="/dev/null"
    fi
    if [[ "$vrc" -eq 124 ]]; then
        UNEVALUATED=$((UNEVALUATED + 1))
    else
        before_html=$FINDINGS
        for k in H1 S2 L1 L2 A1 A2 A3 A4 A5 NM \
                 "noscript fallback present" "color-scheme: light dark"; do
            if check_failed "$k" "$HTML_LOG"; then
                emit "${RULE_FOR[$k]}" "${SEV_FOR[$k]}" "$(basename "$HTML")" \
                     "${NAME_FOR[$k]} check failed (${k})" \
                     "validate-html-output.sh reported: $(check_detail "$k" "$HTML_LOG")" \
                     "$k"
            fi
        done
        # EVERY failure line the validator printed must have been claimed by a mapped key. The earlier
        # version compared only the aggregate finding COUNT before and after the loop, so it fired only
        # when NOTHING matched -- one mapped failure alongside an unmapped one, which is the ordinary
        # case, hid the unmapped one completely and the run still exited 1 ("a complete run with
        # findings"). Attribute line by line instead: a failure no key claims is a check with no rule
        # here, and reporting it as unevaluated is what turns a silent false pass into a fixable one.
        while IFS= read -r fail_line; do
            [[ -n "$fail_line" ]] || continue
            claimed=0
            for k in "${!RULE_FOR[@]}"; do
                if printf '%s\n' "$fail_line" | grep -qE "^[[:space:]]*((❌|FAIL)[[:space:]]*${k}([.[:space:]]|\$)|${k}([.[:space:]]).*\[FAIL\])"; then
                    claimed=1; break
                fi
            done
            if [[ "$claimed" -eq 0 ]]; then
                unevaluated "validate-html-output.sh reported a failure no rule claims -- add it to RULE_FOR: $(printf '%s' "$fail_line" | sed 's/^[[:space:]]*//' | cut -c1-72)"
            fi
        # Exclude the validator's own AGGREGATE line ("❌ HTML output validation failed: 19/21 checks
        # passed"). It is a roll-up of the per-check lines above it, not a check, and it is unindented --
        # so without this the guard would report an unattributed failure on every genuinely-failing run,
        # which is a false positive that would train a reader to ignore the note.
        done < <(grep -E '^[[:space:]]*(❌|FAIL)|\[FAIL\]' "$HTML_LOG" 2>/dev/null \
                 | grep -vE 'validation (failed|passed)|checks passed|check\(s\) failed' || true)
    fi
else
    unevaluated "validate-html-output.sh not found -- H1/S2/L1/L2/A1-A5/NM not evaluated"
fi

# ---------------------------------------------------------------------------
# PRE-11 -- contrast, one rule across themes.
# ---------------------------------------------------------------------------
if command -v node >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/contrast-check.mjs" ]]; then
    run_validator "$CONTRAST_LOG" node "$SCRIPT_DIR/contrast-check.mjs" "$HTML"
    crc=$?

    # A pair the validator could not RESOLVE is neither a pass nor a finding, and it exits 0 -- so
    # without this the run reported PRE-11 clean for pairs it never measured. Worse, an HTML with no
    # `:root` block at all resolves nothing and prints "All contrast checks passed: 0/0 (light) + 0/0
    # (dark)", a green line for zero work. Both are the unevaluated case, which is what the exit-2
    # contract exists for.
    unresolved=$(grep -c '⚠️' "$CONTRAST_LOG" 2>/dev/null || true)
    if [[ "${unresolved:-0}" -gt 0 ]]; then
        unevaluated "contrast-check.mjs could not resolve ${unresolved} token pair(s) -- PRE-11 incomplete"
    fi
    if grep -qE 'passed: 0/0' "$CONTRAST_LOG" 2>/dev/null; then
        unevaluated "contrast-check.mjs measured 0 of 0 pairs (no resolvable :root tokens) -- PRE-11 not evaluated"
    fi

    if [[ "$crc" -ne 0 ]]; then
        # The theme name appears ONLY on its own header line ("[light theme]"); a failing pair line
        # carries a cross, the label and the ratio -- no theme name and no word "fail". So the previous
        # `grep -qiE "${theme}.*(fail)"` matched neither line shape and PRE-11 could never fire. The
        # retired grader DID catch contrast failures, so this was a real coverage regression. Attribute
        # each failing pair to the header above it instead.
        while IFS="$(printf '\t')" read -r theme detail; do
            [[ -n "$theme" ]] || continue
            # PRE-11 is the one rule that emits N rows for one (Doc, Rule) key -- one per failing token
            # pair -- so Line MUST distinguish them or the reconcile join collapses all N into one and
            # fixing a single pair moves no grade. Key it on theme + the pair's own label, which is the
            # leading text of the validator's line before the ratio.
            pair=$(printf '%s' "$detail" | sed 's/^[^ ]* *//; s/  *[0-9.]*:1 .*$//; s/  *$//')
            emit "PRE-11" "[MEDIUM]" "$(basename "$HTML")" \
                 "Token pair '${pair}' fails WCAG AA contrast in the ${theme} theme" \
                 "contrast-check.mjs [${theme} theme]: ${detail}" \
                 "${theme}/${pair}"
        # A failing PAIR line is indented; the trailing "❌ N contrast check(s) failed." summary sits at
        # column 0. Requiring the indent is what keeps that summary from being attributed to whichever
        # theme happened to come last and emitted as a phantom extra finding.
        done < <(awk '
            /^\[[A-Za-z]+ theme\]/     { theme = $1; gsub(/[][]/, "", theme); next }
            theme != "" && /^[[:space:]]+❌/ { line = $0; sub(/^[[:space:]]*/, "", line)
                                              printf "%s\t%s\n", theme, line }
        ' "$CONTRAST_LOG")
    fi
else
    unevaluated "node or contrast-check.mjs unavailable -- PRE-11 not evaluated"
fi

# ---------------------------------------------------------------------------
# SUMMARY-07 -- no retired diagram runtime. This replaces D1/D2: rather than award points for a check
# that cannot fail, assert the retired runtime is ABSENT, which can.
# ---------------------------------------------------------------------------
# NM is evaluated by validate-html-output.sh, in the loop above -- NOT here.
#
# It used to be `grep -qi 'mermaid' "$HTML"`, which fires on any prose mention of the word. This
# project's own kb.html contains five, every one of them a CSS comment or a sentence saying the engine
# was RETIRED, so the check reported the presence of exactly the thing whose absence it asserts: a
# spurious [HIGH] that alone caps the summary at D+. The validator's NM.1/NM.2/NM.3 test for an inline
# engine bundle, a mermaid.initialize() call and a CDN <script src> -- the actual claim.

echo
if [[ "$UNEVALUATED" -gt 0 ]]; then
    echo "ERROR: ${SCRIPT_NAME}: ${UNEVALUATED} check group(s) could not be evaluated -- see the notes above." >&2
    echo "       ${FINDINGS} finding(s) were emitted, but this run is INCOMPLETE. Reporting it as clean" >&2
    echo "       would let grade.sh grade an empty ledger as A+ for an artifact nothing actually checked," >&2
    echo "       which is the exit-2 case this script's header promises. Install the missing validator(s)" >&2
    echo "       and re-run." >&2
    exit 2
fi

if [[ "$FINDINGS" -eq 0 ]]; then
    echo "OK: ${SCRIPT_NAME}: no findings."
    echo "NOTE: this script does not grade. Run grade.sh over the ledger for the letter."
    exit 0
fi

echo "${SCRIPT_NAME}: emitted ${FINDINGS} finding(s)."
echo "NOTE: no grade is computed here. Run grade.sh over the ledger for the letter."
exit 1
