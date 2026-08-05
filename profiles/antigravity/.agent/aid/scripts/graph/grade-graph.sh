#!/usr/bin/env bash
# grade-graph.sh - run /aid-graph's own quality rubric and print its grades.
#
# Purpose:
#   The gate covers THIS SKILL'S OWN ARTIFACTS ONLY. It checks that identifiers
#   resolve, that relation pairs agree, that provenance is populated and that the view
#   is valid. It never scores the Knowledge Base's completeness: that would fail the
#   skill for reasons outside its control and would reward under-reporting, which is
#   the one thing a gap signal cannot afford. The gap findings live in a different
#   ledger that this script is never given -- passing that path here is refused
#   outright, so the gap rows are unreachable by the gate rather than merely unread.
#
#   This is an ORCHESTRATOR, not a fork. Every check body lives in the leaf validator
#   that already implements it; this script invokes them, translates each failure into
#   a reviewer-ledger row at the severity the rubric assigns, and hands the ledger to
#   the project's one grading algorithm. It contains no check body of its own.
#
#   "No row = no finding" is only safe if every check ran, so the gate reports its own
#   coverage: one inventory line per rubric row, `run` / `skip` / `fail`, before the
#   grades and again in the closing summary. A check that could not run emits no row
#   and is named, which is what keeps the grade from being read as stronger evidence
#   than it is.
#
# Usage:
#   grade-graph.sh [--table PATH] [--html PATH] [--ledger PATH] [--grade X]
#                  [--install-root PATH] [--visual-gate PATH]
#   grade-graph.sh -h | --help
#
# Flags:
#   --table PATH        The relationship table to grade.
#                       Default: .aid/knowledge/relationships.md
#   --html PATH         The rendered view to grade, when one is in scope.
#                       Default: .aid/knowledge/graph.html
#   --ledger PATH       The reviewer ledger this run writes and grades.
#                       Default: .aid/.temp/review-pending/graph.md
#   --grade X           Override the minimum acceptable grade FOR THIS RUN ONLY.
#                       Format: ^[A-F][+-]?$. Nothing is persisted: the settings file
#                       is itself a staleness input, so writing a grade floor into it
#                       would force an unrelated regeneration on the next run. A
#                       durable floor is set through /aid-config, which owns that file.
#   --install-root PATH The installed AID tree that carries the reused validators and
#                       the view templates. Default: resolved from this script's own
#                       location.
#   --visual-gate PATH  Where the human gate's recorded answer lives.
#                       Default: .aid/.temp/graph/visual-gate.json
#
# Without --grade, the floor is resolved by the project's single resolver and never by
# parsing a settings file:
#
#   bash <install-root>/aid/scripts/config/read-setting.sh \
#        --skill graph --key minimum_grade --default A
#
# The rubric -- check -> severity, and how many rows a failure emits:
#
#   R*     the gating checks of validate-relationships.sh. Severity is the table
#          schema's own gated column, adopted rather than re-assigned: [HIGH]
#          throughout. One row per emitted finding line. Its two advisory checks are
#          declared advisory-never-gating upstream and emit NO row -- their output is
#          printed and reaches no ledger, so this gate's posture cannot come to depend
#          on a project's configured floor.
#   V-H1   HTML validity. [HIGH] -- an invalid document is invalid.
#   V-A    landmarks, the lightbox's ARIA, its focus trap, the reduced-motion block,
#          :focus-visible. [HIGH] for A2 and A3, where a dialog that traps focus or
#          goes unlabelled DENIES ACCESS to the rest of the page; [MEDIUM] for A1, A4
#          and A5, where every fact stays reachable and the failure is a presentation
#          regression in a reused shared stylesheet.
#   V-ST   the validator's unlabelled structural block -- skip-link, <noscript>
#          fallback, color-scheme. These carry no id, so the code is the authority for
#          the set; each raises the validator's own FAIL flag, and a rubric keyed on
#          ided checks alone would let a grade be printed over a zero-row ledger while
#          a validator it invoked failed. [HIGH] for the <noscript> fallback, without
#          which a reader whose script engine is off gets a page with nothing in it and
#          no route out; [MEDIUM] for the skip-link, whose bypass duty the landmarks
#          answer by a second route, and for color-scheme, which only selects which
#          theme paints.
#   V-L    anchor and relative-link resolution. [HIGH] -- a broken link makes a named
#          document unreachable. One row per broken anchor or link.
#   V-S2   no CDN script or link. [HIGH] -- an artifact that needs the network to
#          render is unreachable offline.
#   V-NM   no runtime diagram engine. [HIGH] -- the guardrail exists because a runtime
#          engine misleads a reader about what the page contains.
#   V-C    contrast. [MEDIUM] -- the marks are drawn and named; the contrast of the
#          presentation is what regressed. One row per failing colour pair.
#   V-T    visual fidelity. [HIGH] for T1, T3, T4 -- text too small to read, a
#          collapsed visual, or a region clipped off the side each mean content is not
#          available; [MEDIUM] for T2, where content is present but crowded.
#
#   The emitted range is exactly [HIGH] and [MEDIUM]. Every V-* row binds page
#   structure and the table view; none asserts a DOM-level check against the canvas,
#   which carries only a text alternative.
#
#   The row set is closed over each validator's FAIL flag and not over its ided
#   checks: a validator that exits non-zero while no row could be attributed to it
#   still yields one row, so a grade is never printed over an unexplained failure.
#
# The human pool:
#   One mandatory check, G1: whether the live graph is LEGIBLE, which is not machine
#   decidable and which the visual validator does not even collect for a canvas. Its
#   recorded answer is read from --visual-gate. A fail forces the Human Grade to F. G1
#   never becomes a ledger row: the ledger is the machine gate, and a human verdict in
#   it would be counted into the Machine Grade.
#
#   Where the view is not in scope, the human pool is N/A and the Overall Grade is the
#   Machine Grade -- the honest form of "no human gate on a table". Where the view is
#   in scope but G1 has not been answered yet, the Human and Overall Grades are
#   reported `pending` and neither enters the exit status: the exit status is keyed on
#   every grade the run COULD compute.
#
# Output:
#   stdout: the check inventory, the ledger path, the three grades, the resolved floor,
#           and the closing skip summary. stderr: diagnostics, prefixed
#           `grade-graph.sh: `.
#
# Exit codes:
#   0 - every grade this run could compute meets the resolved floor
#   1 - one does not
#   2 - a usage error, or a required input is missing

set -euo pipefail
export LC_ALL=C

SELF="grade-graph.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)

TABLE=""
VIEW_HTML=""
LEDGER=""
FLOOR_OVERRIDE=""
VISUAL_GATE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --table)        TABLE="$2"; shift 2 ;;
        --html)         VIEW_HTML="$2"; shift 2 ;;
        --ledger)       LEDGER="$2"; shift 2 ;;
        --grade)        FLOOR_OVERRIDE="$2"; shift 2 ;;
        --install-root) INSTALL_ROOT="$2"; shift 2 ;;
        --visual-gate)  VISUAL_GATE="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"
            exit 0
            ;;
        *)
            echo "${SELF}: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

[ -n "$TABLE" ]       || TABLE=".aid/knowledge/relationships.md"
[ -n "$VIEW_HTML" ]   || VIEW_HTML=".aid/knowledge/graph.html"
[ -n "$LEDGER" ]      || LEDGER=".aid/.temp/review-pending/graph.md"
[ -n "$VISUAL_GATE" ] || VISUAL_GATE=".aid/.temp/graph/visual-gate.json"

# The gap ledger is never graded. Refusing its path here makes that structural at this
# seam rather than a convention a later edit could drop.
case "${LEDGER##*/}" in
    graph-kb-gaps.md)
        echo "${SELF}: refusing to grade ${LEDGER}: the Knowledge Base gap ledger is never graded" >&2
        exit 2
        ;;
esac

if [ ! -f "$TABLE" ]; then
    echo "${SELF}: the relationship table is missing at ${TABLE}" >&2
    exit 2
fi

if [ -n "$FLOOR_OVERRIDE" ]; then
    if ! printf '%s' "$FLOOR_OVERRIDE" | grep -qE '^[A-F][+-]?$'; then
        echo "${SELF}: invalid --grade '${FLOOR_OVERRIDE}' - must match ^[A-F][+-]?\$ (e.g. A, A-, B+, F)." >&2
        exit 2
    fi
    FLOOR="$FLOOR_OVERRIDE"
    FLOOR_SOURCE="--grade (this run only; nothing persisted)"
else
    RESOLVER="${INSTALL_ROOT}/aid/scripts/config/read-setting.sh"
    if [ ! -f "$RESOLVER" ]; then
        echo "${SELF}: the settings resolver is missing at ${RESOLVER}" >&2
        exit 2
    fi
    FLOOR=$(bash "$RESOLVER" --skill graph --key minimum_grade --default A) || {
        echo "${SELF}: the settings resolver failed" >&2
        exit 2
    }
    FLOOR_SOURCE="read-setting.sh --skill graph --key minimum_grade --default A"
fi

# view_expected -- one decidable fact, the same one graph-stale-check.sh reads for the
# expected-artifact set: the view is in scope for a run iff the skeleton is installed.
SKELETON="${INSTALL_ROOT}/aid/templates/knowledge-graph/graph-skeleton.html"
VIEW_EXPECTED=0
if [ -f "$SKELETON" ]; then
    VIEW_EXPECTED=1
fi

W=$(mktemp -d 2>/dev/null) || { echo "${SELF}: cannot create a scratch directory" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT

: > "$W/findings"     # rubric \t severity \t doc \t description \t evidence
: > "$W/status"       # rubric \t run|skip|fail \t reason

record_status() {
    printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >> "$W/status"
}

status_of() {
    awk -F'\t' -v r="$1" '$1 == r { print $2; exit }' "$W/status"
}

reason_of() {
    awk -F'\t' -v r="$1" '$1 == r { print $3; exit }' "$W/status"
}

# Every rubric row, in the order the inventory prints them. Held as an array because
# `R*` would otherwise be glob-expanded by the shell. The inventory carries a line for
# EVERY row, so an absent row can only mean a passed check.
RUBRIC_ROWS=("R*" "V-H1" "V-A" "V-ST" "V-L" "V-S2" "V-NM" "V-C" "V-T")

count_findings() {
    awk -F'\t' -v r="$1" '$1 == r { n++ } END { print n + 0 }' "$W/findings"
}

# Every reused validator shares one exit-code contract: 0 pass, 1 failure, 2
# invocation. The three are classified apart because they mean different things about
# different subjects:
#
#   0 with no attributed line   the check RAN and passed. No row: no row = no finding.
#   1                           the ARTIFACT failed. One row per attributed line -- and
#                               where nothing could be attributed, one row anyway, so a
#                               grade is never printed over an unexplained failure.
#   2                           the VALIDATOR could not be invoked. The artifact is not
#                               what failed, so this is a RECORDED SKIP that emits no
#                               row and is repeated in the closing summary -- never a
#                               silent pass, and never a finding against the artifact.
classify_validator() {
    local rubric="$1" validator="$2" rc="$3" outfile="$4" doc="$5"
    local attributed
    attributed=$(count_findings "$rubric")
    if [ "$rc" -eq 2 ] && [ "$attributed" -eq 0 ]; then
        record_status "$rubric" "skip" "${validator} could not be invoked (exit 2): $(tail -1 "$outfile" | tr '\t' ' ')"
        return 0
    fi
    if [ "$rc" -ne 0 ] && [ "$attributed" -eq 0 ]; then
        printf '%s\t%s\t%s\t%s\t%s\n' "$rubric" "[HIGH]" "$doc" \
            "${validator} exited ${rc} with no attributable check line; the failure is real and unclassified" \
            "$(tail -3 "$outfile" | tr '\t\n' '  ')" >> "$W/findings"
        attributed=1
    fi
    if [ "$attributed" -gt 0 ]; then
        record_status "$rubric" "fail" ""
    else
        record_status "$rubric" "run" ""
    fi
}

# ---------------------------------------------------------------------------
# R* -- the relationship table's own validator.
# ---------------------------------------------------------------------------
REL_VALIDATOR="${SCRIPT_DIR}/validate-relationships.sh"
# The validator's OWN declared advisory tags, adopted rather than re-derived: each is
# advisory by design, carries no acceptance criterion, and gating one would make this
# gate's posture depend on a project's configured floor. The list is the only tag
# knowledge this script holds, because "not advisory" is what closes the gating set --
# a new gating check needs no edit here, while a new advisory does.
ADVISORY_TAGS="REL-ENDPOINT REL-ENDPOINT-UNUSED REL-CONCEPT-AMBIG"

if [ ! -f "$REL_VALIDATOR" ]; then
    record_status "R*" "skip" "validate-relationships.sh is not installed at ${REL_VALIDATOR}"
else
    REL_RC=0
    bash "$REL_VALIDATOR" --file "$TABLE" > "$W/rel.out" 2>&1 || REL_RC=$?
    # One finding per emitted `[TAG] <doc>: <message>` line. Tags carry hyphens.
    awk -v table="$TABLE" -v advisory="$ADVISORY_TAGS" '
        BEGIN {
            n = split(advisory, a, " ")
            for (i = 1; i <= n; i++) adv[a[i]] = 1
        }
        /^\[[A-Za-z0-9-]+\]/ {
            tag = $0
            sub(/^\[/, "", tag)
            sub(/\].*$/, "", tag)
            if (tag in adv) next
            msg = $0
            sub(/^\[[A-Za-z0-9-]+\][[:space:]]*/, "", msg)
            gsub(/\t/, " ", msg)
            printf "R*\t[HIGH]\t%s\trelationship-table check %s failed: %s\t%s\n", table, tag, msg, $0
        }
    ' "$W/rel.out" >> "$W/findings"
    # The advisory output is printed and reaches no ledger.
    awk -v advisory="$ADVISORY_TAGS" '
        BEGIN {
            n = split(advisory, a, " ")
            for (i = 1; i <= n; i++) adv[a[i]] = 1
        }
        /^\[[A-Za-z0-9-]+\]/ {
            tag = $0
            sub(/^\[/, "", tag)
            sub(/\].*$/, "", tag)
            if (tag in adv) print "[advisory, no ledger row] " $0
        }
    ' "$W/rel.out"
    classify_validator "R*" "validate-relationships.sh" "$REL_RC" "$W/rel.out" "$TABLE"
fi

# ---------------------------------------------------------------------------
# The view rubric rows. They exist iff a view is in scope AND there is a rendered
# page to check; otherwise each is a recorded skip that emits no row.
# ---------------------------------------------------------------------------
VIEW_SKIP_REASON=""
if [ "$VIEW_EXPECTED" -eq 0 ]; then
    VIEW_SKIP_REASON="the view templates are not installed, so no view is in scope on this install"
elif [ ! -f "$VIEW_HTML" ]; then
    VIEW_SKIP_REASON="no rendered view at ${VIEW_HTML}"
fi

HTML_VALIDATOR="${INSTALL_ROOT}/aid/scripts/summarize/validate-html-output.sh"
CONTRAST_VALIDATOR="${INSTALL_ROOT}/aid/scripts/summarize/contrast-check.mjs"
VISUAL_VALIDATOR="${INSTALL_ROOT}/aid/scripts/summarize/validate-visuals.mjs"

if [ -n "$VIEW_SKIP_REASON" ]; then
    for row in V-H1 V-A V-ST V-L V-S2 V-NM V-C V-T; do
        record_status "$row" "skip" "$VIEW_SKIP_REASON"
    done
else
    # --- validate-html-output.sh: V-H1, V-A, V-ST, V-L, V-S2, V-NM -----------
    # Invoked as installed. Its --kb-dir flag is deliberately not passed: L2 resolves
    # every relative link against the page's OWN directory, so the flag would change
    # nothing this rubric routes on.
    if [ ! -f "$HTML_VALIDATOR" ]; then
        for row in V-H1 V-A V-ST V-L V-S2 V-NM; do
            record_status "$row" "skip" "validate-html-output.sh is not installed at ${HTML_VALIDATOR}"
        done
    else
        HTML_RC=0
        bash "$HTML_VALIDATOR" "$VIEW_HTML" > "$W/html.out" 2>&1 || HTML_RC=$?
        awk -v doc="$VIEW_HTML" '
            function emit(rubric, sev, what,   line) {
                line = $0
                gsub(/\t/, " ", line)
                printf "%s\t%s\t%s\t%s\t%s\n", rubric, sev, doc, what, line
            }
            # Per-link detail lines come before their summary line, so a summary is
            # only emitted when no detail explained it.
            /^    ❌ #/       { emit("V-L", "[HIGH]", "L1 failed: an anchor link resolves to no id in the page"); l1 = 1; next }
            /^    ❌ \.\//    { emit("V-L", "[HIGH]", "L2 failed: a relative document link resolves to no file"); l2 = 1; next }
            /^  ❌ H1[.: ]/   { emit("V-H1", "[HIGH]", "H1 failed: the page is not valid HTML"); next }
            /^  ❌ A1[.: ]/   { emit("V-A", "[MEDIUM]", "A1 failed: a semantic landmark is missing"); next }
            /^  ❌ A2[.: ]/   { emit("V-A", "[HIGH]", "A2 failed: the dialog is unlabelled, denying access to the rest of the page"); next }
            /^  ❌ A3[.: ]/   { emit("V-A", "[HIGH]", "A3 failed: the dialog does not release focus, trapping the reader"); next }
            /^  ❌ A4[.: ]/   { emit("V-A", "[MEDIUM]", "A4 failed: the reduced-motion block is missing"); next }
            /^  ❌ A5[.: ]/   { emit("V-A", "[MEDIUM]", "A5 failed: no visible focus rule"); next }
            /^  ❌ skip-link/ { emit("V-ST", "[MEDIUM]", "structural check failed: no skip link"); next }
            /^  ❌ noscript/  { emit("V-ST", "[HIGH]", "structural check failed: no <noscript> fallback, so a reader without script gets an empty page and no route out"); next }
            /^  ❌ color-scheme/ { emit("V-ST", "[MEDIUM]", "structural check failed: no color-scheme declaration"); next }
            /^  ❌ NM[.: ]/   { emit("V-NM", "[HIGH]", "NM failed: a runtime diagram engine is present in the page"); next }
            /S2\. Offline render \[FAIL\]/ { emit("V-S2", "[HIGH]", "S2 failed: the page references a network resource and cannot render offline"); next }
            /^  ❌ L1[.: ]/   { if (!l1) emit("V-L", "[HIGH]", "L1 failed: at least one anchor link resolves to no id in the page"); next }
            /^  ❌ L2[.: ]/   { if (!l2) emit("V-L", "[HIGH]", "L2 failed: at least one relative document link resolves to no file"); next }
        ' "$W/html.out" >> "$W/findings"

        # One shared FAIL flag over six rubric rows, so the closure is applied once and
        # attributed to the structural row that exists for exactly this hole.
        HTML_ATTRIBUTED=$(awk -F'\t' '
            $1 == "V-H1" || $1 == "V-A" || $1 == "V-ST" || $1 == "V-L" || $1 == "V-S2" || $1 == "V-NM" { n++ }
            END { print n + 0 }
        ' "$W/findings")
        if [ "$HTML_RC" -eq 2 ] && [ "$HTML_ATTRIBUTED" -eq 0 ]; then
            # An invocation error is a recorded skip over every row it would have
            # decided: the artifact is not what failed.
            for row in V-H1 V-A V-ST V-L V-S2 V-NM; do
                record_status "$row" "skip" "validate-html-output.sh could not be invoked (exit 2): $(tail -1 "$W/html.out" | tr '\t' ' ')"
            done
        else
            if [ "$HTML_RC" -ne 0 ] && [ "$HTML_ATTRIBUTED" -eq 0 ]; then
                printf 'V-ST\t[HIGH]\t%s\t%s\t%s\n' "$VIEW_HTML" \
                    "validate-html-output.sh exited ${HTML_RC} with no attributable check line; the failure is real and unclassified" \
                    "$(tail -3 "$W/html.out" | tr '\t\n' '  ')" >> "$W/findings"
            fi
            for row in V-H1 V-A V-ST V-L V-S2 V-NM; do
                if [ "$(count_findings "$row")" -gt 0 ]; then
                    record_status "$row" "fail" ""
                else
                    record_status "$row" "run" ""
                fi
            done
        fi
    fi

    # --- contrast-check.mjs: V-C ------------------------------------------
    if ! command -v node >/dev/null 2>&1; then
        record_status "V-C" "skip" "Node.js is not available"
    elif [ ! -f "$CONTRAST_VALIDATOR" ]; then
        record_status "V-C" "skip" "contrast-check.mjs is not installed at ${CONTRAST_VALIDATOR}"
    else
        C_RC=0
        node "$CONTRAST_VALIDATOR" "$VIEW_HTML" > "$W/contrast.out" 2>&1 || C_RC=$?
        awk -v doc="$VIEW_HTML" '
            /^  ❌ .*:1 \(target/ {
                line = $0
                gsub(/\t/, " ", line)
                printf "V-C\t[MEDIUM]\t%s\t%s\t%s\n", doc, "contrast failed: a declared colour pair is below its target ratio", line
            }
        ' "$W/contrast.out" >> "$W/findings"
        classify_validator "V-C" "contrast-check.mjs" "$C_RC" "$W/contrast.out" "$VIEW_HTML"
    fi

    # --- validate-visuals.mjs: V-T ---------------------------------------
    if ! command -v node >/dev/null 2>&1; then
        record_status "V-T" "skip" "Node.js is not available"
    elif [ ! -f "$VISUAL_VALIDATOR" ]; then
        record_status "V-T" "skip" "validate-visuals.mjs is not installed at ${VISUAL_VALIDATOR}"
    else
        T_RC=0
        node "$VISUAL_VALIDATOR" "$VIEW_HTML" > "$W/visual.out" 2>&1 || T_RC=$?
        if grep -q '^SKIP -- ' "$W/visual.out"; then
            record_status "V-T" "skip" "$(grep -m1 '^SKIP -- ' "$W/visual.out" | sed 's/^SKIP -- //')"
        else
            awk -v doc="$VIEW_HTML" '
                /^Visual [0-9]+: / { visual = $0; next }
                /^  T[1-4] .*FAIL/ {
                    t = substr($0, 4, 1)
                    sev = (t == "2") ? "[MEDIUM]" : "[HIGH]"
                    what["1"] = "T1 failed: text inside a visual is too small to read or is clipped to zero height"
                    what["2"] = "T2 failed: the child elements of a visual materially overlap"
                    what["3"] = "T3 failed: a visual is collapsed and not rendered"
                    what["4"] = "T4 failed: a visual is clipped off the side of its container at a supported width"
                    line = visual " / " $0
                    gsub(/\t/, " ", line)
                    printf "V-T\t%s\t%s\t%s\t%s\n", sev, doc, what[t], line
                }
            ' "$W/visual.out" >> "$W/findings"
            classify_validator "V-T" "validate-visuals.mjs" "$T_RC" "$W/visual.out" "$VIEW_HTML"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# The ledger. Rows are append-only across REVIEW -> FIX cycles: only Status moves.
# A previously-Pending finding that no longer reproduces becomes Fixed; a Fixed one
# that reproduces again becomes Recurred; the schema's human-cycle values are never
# rewritten by a generator. New findings append with the next sequential number.
# ---------------------------------------------------------------------------
LEDGER_DIR=$(dirname -- "$LEDGER")
mkdir -p "$LEDGER_DIR" || { echo "${SELF}: cannot create ${LEDGER_DIR}" >&2; exit 2; }

# Cells are normalised on the way IN, in exactly the form they will be read back out
# of the rendered table: tabs and newlines flattened, pipes escaped, and surrounding
# whitespace trimmed. The trim is load-bearing rather than cosmetic -- a validator's
# finding line arrives indented, the rendered cell is read back trimmed, and without
# the trim a row's identity would differ between the run that wrote it and the run that
# reads it, so every re-run would mark the previous row Fixed and append a duplicate.
escape_cell() {
    printf '%s' "$1" \
        | tr '\t\n' '  ' \
        | sed -e 's/|/\\|/g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# A row is identified across cycles by its Doc, its Description and its Evidence
# together. Doc plus Description alone is not enough: two broken anchors carry the same
# sentence, and the rubric emits one row per broken link -- keying on the pair would
# collapse them into one row and under-report.
: > "$W/current"      # doc \t description \t evidence \t severity, all cells escaped
while IFS=$'\t' read -r rubric severity doc description evidence; do
    [ -n "${rubric:-}" ] || continue
    printf '%s\t%s\t%s\t%s\n' \
        "$(escape_cell "$doc")" "$(escape_cell "$description")" \
        "$(escape_cell "$evidence")" "$severity" >> "$W/current"
done < "$W/findings"
cut -f1-3 "$W/current" > "$W/current.keys"

# Read the previous ledger, if any, into the same TSV shape. Evidence is the last cell,
# so a pipe escaped inside it is rejoined rather than truncated.
: > "$W/prev"
if [ -f "$LEDGER" ]; then
    awk -F'|' '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        /^\|/ {
            if ($0 ~ /^\|[[:space:]]*[-:]+[[:space:]]*\|/) next
            if (NF < 9) next
            sev = trim($3)
            if (sev == "Severity" || sev == "#") next
            ev = $8
            for (i = 9; i < NF; i++) ev = ev "|" $i
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
                trim($2), sev, trim($4), trim($5), trim($6), trim($7), trim(ev)
        }
    ' "$LEDGER" > "$W/prev"
fi

: > "$W/ledger.body"
: > "$W/seen.keys"
NEXT=0

# Carry every existing row forward. Only Status moves: the schema is append-only, and
# the human-cycle values (Accepted, OOS, Invalid) are never rewritten by a generator.
while IFS=$'\t' read -r num sev st doc ln desc ev; do
    [ -n "${num:-}" ] || continue
    key=$(printf '%s\t%s\t%s' "$doc" "$desc" "$ev")
    if grep -Fxq "$key" "$W/current.keys"; then
        present=1
    else
        present=0
    fi
    case "$st" in
        Pending|Recurred)
            [ "$present" -eq 1 ] || st="Fixed"
            ;;
        Fixed)
            [ "$present" -eq 1 ] && st="Recurred"
            ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$num" "$sev" "$st" "$doc" "$ln" "$desc" "$ev" >> "$W/ledger.body"
    printf '%s\n' "$key" >> "$W/seen.keys"
    case "$num" in
        ''|*[!0-9]*) ;;
        *) [ "$num" -le "$NEXT" ] || NEXT="$num" ;;
    esac
done < "$W/prev"

# Append every finding the previous ledger does not already carry.
while IFS=$'\t' read -r doc desc ev severity; do
    [ -n "${doc:-}" ] || continue
    key=$(printf '%s\t%s\t%s' "$doc" "$desc" "$ev")
    if grep -Fxq "$key" "$W/seen.keys"; then
        continue
    fi
    NEXT=$((NEXT + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$NEXT" "$severity" "Pending" "$doc" "—" "$desc" "$ev" >> "$W/ledger.body"
    printf '%s\n' "$key" >> "$W/seen.keys"
done < "$W/current"

{
    echo "| # | Severity | Status | Doc | Line | Description | Evidence |"
    echo "|---|---|---|---|---|---|---|"
    awk -F'\t' '{ printf "| %s | %s | %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6, $7 }' "$W/ledger.body"
} > "$W/ledger.md"
mv -f "$W/ledger.md" "$LEDGER"

# ---------------------------------------------------------------------------
# The grades.
# ---------------------------------------------------------------------------
GRADER="${INSTALL_ROOT}/aid/scripts/grade.sh"
if [ ! -f "$GRADER" ]; then
    echo "${SELF}: the grading algorithm is missing at ${GRADER}" >&2
    exit 2
fi
MACHINE=$(bash "$GRADER" "$LEDGER") || {
    echo "${SELF}: grade.sh could not grade ${LEDGER}" >&2
    exit 2
}

grade_rank() {
    case "$1" in
        A+) echo 16 ;; A) echo 15 ;; A-) echo 14 ;;
        B+) echo 13 ;; B) echo 12 ;; B-) echo 11 ;;
        C+) echo 10 ;; C) echo  9 ;; C-) echo  8 ;;
        D+) echo  7 ;; D) echo  6 ;; D-) echo  5 ;;
        E+) echo  4 ;; E) echo  3 ;; E-) echo  2 ;;
        F+|F|F-) echo 1 ;;
        *)  echo 0 ;;
    esac
}

HUMAN=""
HUMAN_NOTE=""
if [ "$VIEW_EXPECTED" -eq 0 ]; then
    HUMAN="N/A"
    HUMAN_NOTE="no view is in scope on this install, so there is nothing to judge"
elif [ ! -f "$VISUAL_GATE" ]; then
    HUMAN="pending"
    HUMAN_NOTE="G1 has not been answered yet (no record at ${VISUAL_GATE})"
else
    G1=$(grep -oE '"g1"[[:space:]]*:[[:space:]]*"(pass|fail)"' "$VISUAL_GATE" 2>/dev/null | head -1 | sed -E 's/.*"(pass|fail)"$/\1/') || G1=""
    case "${G1:-}" in
        pass)
            HUMAN="A+"
            HUMAN_NOTE="G1 passed: the graph was judged legible and usable in a real browser"
            ;;
        fail)
            HUMAN="F"
            HUMAN_NOTE="G1 FAILED - the mandatory human visual gate; the Human Grade is forced to F"
            ;;
        *)
            HUMAN="pending"
            HUMAN_NOTE="G1's recorded answer at ${VISUAL_GATE} is not readable as pass or fail"
            ;;
    esac
fi

case "$HUMAN" in
    N/A)     OVERALL="$MACHINE" ;;
    pending) OVERALL="pending" ;;
    *)
        if [ "$(grade_rank "$MACHINE")" -le "$(grade_rank "$HUMAN")" ]; then
            OVERALL="$MACHINE"
        else
            OVERALL="$HUMAN"
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# Report. The inventory carries a line for EVERY rubric row, so an absent row can
# only mean a passed check and never an unrun one.
# ---------------------------------------------------------------------------
SUBJECT="$TABLE"
if [ "$VIEW_EXPECTED" -eq 1 ]; then
    SUBJECT="${TABLE} and ${VIEW_HTML}"
fi
echo "Grading ${SUBJECT} ..."
echo ""
echo "Check inventory:"
SKIPPED=0
for row in "${RUBRIC_ROWS[@]}"; do
    st=$(status_of "$row")
    rs=$(reason_of "$row")
    [ -n "$st" ] || st="skip"
    if [ "$st" = "skip" ]; then
        SKIPPED=$((SKIPPED + 1))
    fi
    if [ -n "$rs" ]; then
        printf '  %-6s %-4s -- %s\n' "$row" "$st" "$rs"
    else
        printf '  %-6s %-4s\n' "$row" "$st"
    fi
done

ROWS=$(awk 'END { print NR }' "$W/ledger.body")
echo ""
echo "Ledger: ${LEDGER} (${ROWS} row(s))"
echo ""
echo "Minimum grade:  ${FLOOR}   [${FLOOR_SOURCE}]"
echo "Machine Grade:  ${MACHINE}"
if [ -n "$HUMAN_NOTE" ]; then
    echo "Human Grade:    ${HUMAN}   (${HUMAN_NOTE})"
else
    echo "Human Grade:    ${HUMAN}"
fi
echo "Overall Grade:  ${OVERALL}"

if [ "$SKIPPED" -gt 0 ]; then
    echo ""
    echo "Skipped checks (${SKIPPED}) - each emits no row, so this grade is weaker evidence than a full run:"
    for row in "${RUBRIC_ROWS[@]}"; do
        if [ "$(status_of "$row")" = "skip" ] || [ -z "$(status_of "$row")" ]; then
            printf '  %-6s %s\n' "$row" "$(reason_of "$row")"
        fi
    done
fi

# ---------------------------------------------------------------------------
# The exit status is keyed on the resolved floor, never on a hardcoded band, and on
# every grade this run could compute.
# ---------------------------------------------------------------------------
FLOOR_RANK=$(grade_rank "$FLOOR")
RC=0
if [ "$(grade_rank "$MACHINE")" -lt "$FLOOR_RANK" ]; then
    RC=1
fi
case "$HUMAN" in
    N/A|pending) ;;
    *)
        if [ "$(grade_rank "$HUMAN")" -lt "$FLOOR_RANK" ]; then
            RC=1
        fi
        ;;
esac
exit "$RC"
