#!/usr/bin/env bash
# grade-summary.sh -- orchestrator for /aid-summarize VALIDATE state.
# (Renamed from knowledge-summary/scripts/grade.sh in 2026-05-26 script
#  consolidation; the universal grade computation lives at canonical/scripts/grade.sh.)
# Runs all automated checks and emits a structured two-grade report.
#
# Usage:
#   grade-summary.sh <html-file> [--fast]
#
# Flags:
#   --fast    Reserved for development; no-op since validate-diagrams.mjs was retired (D-012).
#   -h, --help  Print this header and exit.
#
# Exit codes:
#   0  Machine Grade is A- or better (for CI integration).
#   1  Machine Grade is below A-.
#   2  Invocation error.
#
# Two-grade model:
#   Machine Grade  -- auto-verifiable checks (AUTO_POOL = COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; 68 pts max)
#   Human Grade    -- manual checklist only (MANUAL_POOL = K1 K2 V1; 30 pts max)
#   Overall Grade  -- the lower of the two letter grades.
#
# A+ requires BOTH Machine Grade >= 98% of 68 pts AND Human Grade >= 98% of 30.
# Manual checks default to 0/30 if .manual-checklist.json has not been run.
# V1 (human visual gate) is MANDATORY: V1=0 forces Human Grade = F.
#
# Coverage hard rule (COV):
#   Reads discovery.doc_set from .aid/settings.yml, intersects with files
#   present in .aid/knowledge/ (resolved doc-set), checks the HTML for a
#   reference to each resolved doc. Coverage < 60% forces Machine Grade F.
#   The old diagram-count cap (C+ ceiling unless N Mermaid diagrams present)
#   has been REMOVED. Diagram count does not affect the grade ceiling.
#
# D1/D2/S2: Mermaid checks are trivially passed when no Mermaid blocks exist.
#   A Mermaid parse failure reduces the score but does NOT force automatic F.

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
HTML=""
FAST=""

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -40
            exit 0
            ;;
        --fast) FAST="--fast" ;;
        -*)
            echo "Unknown flag: $arg" >&2
            exit 2
            ;;
        *)
            HTML="$arg"
            ;;
    esac
done

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "Usage: grade-summary.sh <html-file> [--fast]" >&2
    exit 2
fi

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
KB_DIR=".aid/knowledge"
SETTINGS=".aid/settings.yml"
MANUAL_CHECKLIST_FILE="$KB_DIR/.manual-checklist.json"

echo "Validating $HTML ..."
echo ""

# ---------------------------------------------------------------------------
# COV: Resolved-doc-set coverage
# ---------------------------------------------------------------------------
# Reads discovery.doc_set from .aid/settings.yml, intersects with files
# present in .aid/knowledge/, checks the HTML for references to each doc.
# ---------------------------------------------------------------------------

COV_TOTAL=0      # number of docs in resolved doc-set
COV_FOUND=0      # number of resolved docs referenced in HTML
COV_SKIPPED=0    # set to 1 if settings.yml has no doc_set
COV_EARNED=0     # points earned (0, 3, 8, or 15)
COV_LABEL=""     # full/partial/minimal/none

if [ ! -f "$SETTINGS" ]; then
    COV_SKIPPED=1
else
    # Extract doc_set filenames: lines under "  doc_set:" that look like
    # "    - filename.md|...", taking the filename before the first pipe.
    # Use awk to scope the extraction to the doc_set block only.
    DOCSET_FILES=$(awk '
        /^[[:space:]]+doc_set:/ { in_docset=1; next }
        in_docset && /^[[:space:]]+-[[:space:]]/ {
            # extract the entry (after "- ")
            sub(/^[[:space:]]+-[[:space:]]*/, "")
            # take only the filename (before "|")
            split($0, parts, "|")
            print parts[1]
            next
        }
        in_docset && /^[^[:space:]]/ { in_docset=0 }
        in_docset && /^[[:space:]][^[:space:]-]/ { in_docset=0 }
    ' "$SETTINGS" 2>/dev/null || true)

    if [ -z "$DOCSET_FILES" ]; then
        COV_SKIPPED=1
    else
        # Resolve: only count docs that exist on disk. Collect the stem of every
        # resolved doc so the HTML can be scanned ONCE (a single awk pass) below,
        # instead of spawning one `grep` per doc (was O(docs) full-file greps).
        RESOLVED_STEMS=""
        while IFS= read -r docfile; do
            [ -z "$docfile" ] && continue
            if [ -f "$KB_DIR/$docfile" ]; then
                COV_TOTAL=$((COV_TOTAL + 1))
                # Check the HTML for a reference to this doc by stem or filename.
                # Stem = filename without .md extension.
                stem="${docfile%.md}"
                # Look for: the filename itself, the stem as an id/anchor, or
                # a heading containing the stem (case-insensitive).
                RESOLVED_STEMS="$RESOLVED_STEMS$stem
"
            fi
        done <<EOF
$DOCSET_FILES
EOF

        # Single-pass scan: reproduce `grep -qiF "$stem" "$HTML"` for every
        # resolved stem in ONE awk invocation (zero per-item spawns). Semantics
        # match grep -qiF EXACTLY -- case-insensitive, fixed-string (literal, no
        # regex) substring, matched within a single line via index(). Stems are
        # passed through the environment (ENVIRON) so awk applies no escape
        # processing to them; LC_ALL=C gives deterministic cross-OS folding
        # (identical to grep -qiF for the ASCII doc-stems used here).
        if [ -n "$RESOLVED_STEMS" ]; then
            COV_FOUND=$(RESOLVED_STEMS="$RESOLVED_STEMS" LC_ALL=C awk '
                BEGIN {
                    n = split(ENVIRON["RESOLVED_STEMS"], arr, "\n")
                    for (i = 1; i <= n; i++) stem[i] = tolower(arr[i])
                }
                {
                    line = tolower($0)
                    for (i = 1; i <= n; i++)
                        if (stem[i] != "" && !seen[i] && index(line, stem[i]) > 0)
                            seen[i] = 1
                }
                END {
                    found = 0
                    for (i = 1; i <= n; i++)
                        if (stem[i] != "" && seen[i]) found++
                    print found
                }
            ' "$HTML" 2>/dev/null)
            COV_FOUND="${COV_FOUND:-0}"
        fi
    fi
fi

if [ "$COV_SKIPPED" -eq 1 ]; then
    COV_EARNED=15
    COV_LABEL="skipped (no doc_set in settings.yml)"
    COV_RESULT="pass"
    COV_DISPLAY="COV trivially passed -- settings.yml has no doc_set field"
else
    if [ "$COV_TOTAL" -eq 0 ]; then
        COV_EARNED=15
        COV_LABEL="skipped (0 resolved docs)"
        COV_RESULT="pass"
        COV_DISPLAY="COV trivially passed -- 0 docs in resolved doc-set"
    else
        COV_PCT=$(( COV_FOUND * 100 / COV_TOTAL ))
        if [ "$COV_PCT" -ge 95 ]; then
            COV_EARNED=15
            COV_LABEL="full"
            COV_RESULT="pass"
        elif [ "$COV_PCT" -ge 80 ]; then
            COV_EARNED=8
            COV_LABEL="partial"
            COV_RESULT="pass"
        elif [ "$COV_PCT" -ge 60 ]; then
            COV_EARNED=3
            COV_LABEL="minimal"
            COV_RESULT="pass"
        else
            COV_EARNED=0
            COV_LABEL="insufficient"
            COV_RESULT="fail"
        fi
        COV_DISPLAY="Coverage: $COV_FOUND/$COV_TOTAL resolved docs referenced in HTML ($COV_PCT%)"
    fi
fi

echo "Resolved doc-set: $COV_TOTAL docs in discovery.doc_set present on disk."
echo "$COV_DISPLAY"
echo ""

# ---------------------------------------------------------------------------
# Per-check result tracking
# ---------------------------------------------------------------------------
declare -A RESULTS
for k in COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    RESULTS[$k]=fail
done
RESULTS[COV]="$COV_RESULT"

# AUTO_POOL weights (68 pts total -- summed dynamically into AUTO_MAX below)
declare -A WEIGHTS=(
    [COV]=15
    [D1]=5  [D2]=5
    [L1]=5  [L2]=5
    [H1]=5
    [A1]=5  [A2]=3  [A3]=5  [A4]=2  [A5]=3
    [C1]=4  [C2]=4
    [S2]=2
)

# Partial scoring for COV (0, 3, 8, or 15 -- not just 0/15)
declare -A PARTIAL_SCORES
PARTIAL_SCORES[COV]="$COV_EARNED"

# Metadata for check names (display only)
declare -A CHECK_NAMES=(
    [COV]="Resolved-doc-set coverage"
    [D1]="Mermaid parse (if present)"
    [D2]="Mermaid render (if present)"
    [L1]="Anchor links"
    [L2]="Relative md links"
    [H1]="HTML validity"
    [A1]="Semantic landmarks"
    [A2]="ARIA on lightbox"
    [A3]="Focus trap"
    [A4]="Reduced motion"
    [A5]="Visible focus"
    [C1]="Light theme contrast"
    [C2]="Dark theme contrast"
    [S2]="Offline render"
)

H1_MODE_NOTE=""  # captures "regex fallback" if that path was taken

# ---------------------------------------------------------------------------
# D1 + D2: Mermaid validation -- trivially passed (Mermaid engine retired D-012)
# CHANGE 7 (FR-51): The Mermaid engine is removed. D-012 output contains no
# <pre class="mermaid"> blocks. D1 and D2 are trivially passed (5/5 each).
# The section-6 visual-fidelity gate (task-074) provides the replacement check
# for inline SVG authored visuals.
# ---------------------------------------------------------------------------
echo "========================================================"
echo "[Mermaid diagrams -- D1 parse, D2 render]"
echo "  Mermaid engine retired (Change 7 / FR-51 / D-012)."
echo "  No Mermaid blocks in output -- D1 and D2 trivially passed."
RESULTS[D1]=pass
RESULTS[D2]=pass

# ---------------------------------------------------------------------------
# H1 + A1-A5 + S2 + L1 + L2: HTML structure/validity/a11y + link validation
# (validate-html-output.sh merges the former validate-html.sh + validate-links.sh
#  per 2026-05-26 script consolidation)
# ---------------------------------------------------------------------------
echo "========================================================"
echo "[HTML output validation -- H1 A1 A2 A3 A4 A5 S2 + L1 L2]"
HTML_LOG=$(mktemp)
if bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML" > "$HTML_LOG" 2>&1; then
    cat "$HTML_LOG"
    RESULTS[H1]=pass
    RESULTS[A1]=pass
    RESULTS[A2]=pass
    RESULTS[A3]=pass
    RESULTS[A4]=pass
    RESULTS[A5]=pass
    # S2: validate-html-output.sh exited 0 means S2 passed (CDN-free)
    RESULTS[S2]=pass
    RESULTS[L1]=pass
    RESULTS[L2]=pass
else
    cat "$HTML_LOG"
    # Detect individual pass/fail from validate-html-output.sh output.
    # validate-html-output.sh emits lines prefixed with a pass/fail marker.
    # Pass lines have unique text absent in fail lines for H1/L1/L2/A3:
    #   H1 pass only: "0 errors" or "regex fallback" in the H1 message
    #   A3 pass only: "trapFocusOnTab + lastFocused" in the success message
    #   L1 pass only: "N/N anchor links resolve"
    #   L2 pass only: "N/N relative md links resolve"
    # For A1/A2/A4/A5: the check() helper emits the same label for pass and fail;
    # the only distinguisher is the prefix marker. Use inverse: check for absence
    # of a fail-specific line for these checks.
    grep -qE "H1\..*0 errors|H1\..*regex fallback" "$HTML_LOG" \
        && RESULTS[H1]=pass
    # A1: pass if no A1 sub-check reported a fail indicator (missing/not found)
    if ! grep -qE "A1\..*(Missing|not found|not present)" "$HTML_LOG" 2>/dev/null \
       && grep -qE "A1\." "$HTML_LOG" 2>/dev/null; then
        RESULTS[A1]=pass
    fi
    # A2: pass if no A2 sub-check reported a fail indicator
    if ! grep -qE "A2\..*(missing|not found|not present)" "$HTML_LOG" 2>/dev/null \
       && grep -qE "A2\." "$HTML_LOG" 2>/dev/null; then
        RESULTS[A2]=pass
    fi
    # A3: pass text is unique
    grep -qE "A3\..*trapFocusOnTab.*lastFocused" "$HTML_LOG" && RESULTS[A3]=pass
    # A4: pass if no A4 line with a fail indicator
    if ! grep -qE "A4\..*(not found|missing)" "$HTML_LOG" 2>/dev/null \
       && grep -qE "A4\." "$HTML_LOG" 2>/dev/null; then
        RESULTS[A4]=pass
    fi
    # A5: pass if no A5 line with a fail indicator
    if ! grep -qE "A5\..*(not found|missing)" "$HTML_LOG" 2>/dev/null \
       && grep -qE "A5\." "$HTML_LOG" 2>/dev/null; then
        RESULTS[A5]=pass
    fi

    # S2: the Mermaid engine is retired (Change 7 / FR-51 / D-012). S2 now checks
    # that no CDN references were introduced. Pass: validate-html-output.sh emits
    # "S2. Offline render [PASS]" when no external CDN script/link is present.
    grep -qE "S2\..*\[PASS\]" "$HTML_LOG" && RESULTS[S2]=pass

    # L1/L2: pass lines contain unique "N/N ... resolve" text
    grep -qE "L1\..*resolve" "$HTML_LOG" && RESULTS[L1]=pass
    grep -qE "L2\..*resolve" "$HTML_LOG" && RESULTS[L2]=pass
fi

# Capture H1 mode note for report
if grep -q "regex fallback" "$HTML_LOG" 2>/dev/null; then
    H1_MODE_NOTE="(regex fallback -- tidy/html-validate not installed)"
elif grep -qE "H1: using (npx )?html-validate|using html.validate" "$HTML_LOG" 2>/dev/null; then
    H1_MODE_NOTE="(html-validate)"
elif grep -q "H1: using tidy" "$HTML_LOG" 2>/dev/null; then
    H1_MODE_NOTE="(tidy)"
fi

rm -f "$HTML_LOG"
echo ""

# ---------------------------------------------------------------------------
# C1 + C2: contrast
# ---------------------------------------------------------------------------
echo "========================================================"
echo "[Theme contrast -- C1 light, C2 dark]"
CONTRAST_LOG=$(mktemp)
if node "$SCRIPT_DIR/contrast-check.mjs" "$HTML" > "$CONTRAST_LOG" 2>&1; then
    cat "$CONTRAST_LOG"
    RESULTS[C1]=pass
    RESULTS[C2]=pass
else
    cat "$CONTRAST_LOG"
    # Light theme: no failure in the block after [light theme]
    if ! grep -A50 '\[light theme\]' "$CONTRAST_LOG" | grep -m1 '^\[dark' >/dev/null 2>&1; then
        # Only light block in output
        if ! grep -A50 '\[light theme\]' "$CONTRAST_LOG" | grep -q 'FAIL\|fail'; then
            RESULTS[C1]=pass
        fi
    else
        LIGHT_BLOCK=$(sed -n '/\[light theme\]/,/\[dark theme\]/p' "$CONTRAST_LOG")
        if ! echo "$LIGHT_BLOCK" | grep -q 'FAIL\|fail'; then RESULTS[C1]=pass; fi
        DARK_BLOCK=$(sed -n '/\[dark theme\]/,$p' "$CONTRAST_LOG")
        if ! echo "$DARK_BLOCK" | grep -q 'FAIL\|fail'; then RESULTS[C2]=pass; fi
    fi
    if grep -q "All contrast checks passed" "$CONTRAST_LOG"; then
        RESULTS[C1]=pass; RESULTS[C2]=pass
    fi
fi
rm -f "$CONTRAST_LOG"
echo ""

# ---------------------------------------------------------------------------
# Manual checklist -- K1 + K2 + V1
# ---------------------------------------------------------------------------
MANUAL_K1=0
MANUAL_K2=0
MANUAL_V1=0
MANUAL_RUN=0

if [ -f "$MANUAL_CHECKLIST_FILE" ]; then
    MANUAL_RUN=1
    # Parse K1_score / K2_score / V1_score VALUES from JSON.
    # NOTE: extract the number AFTER the colon -- a naive grep -oE '[0-9]+'
    # would grab the "1"/"2" from the key name "K1_score"/"K2_score" itself.
    MANUAL_K1=$(sed -nE 's/.*"K1_score"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$MANUAL_CHECKLIST_FILE" 2>/dev/null | head -1)
    MANUAL_K2=$(sed -nE 's/.*"K2_score"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$MANUAL_CHECKLIST_FILE" 2>/dev/null | head -1)
    MANUAL_V1=$(sed -nE 's/.*"V1_score"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$MANUAL_CHECKLIST_FILE" 2>/dev/null | head -1)
    MANUAL_K1="${MANUAL_K1:-0}"
    MANUAL_K2="${MANUAL_K2:-0}"
    MANUAL_V1="${MANUAL_V1:-0}"
fi

MANUAL_EARNED=$((MANUAL_K1 + MANUAL_K2 + MANUAL_V1))
MANUAL_MAX=30

# ---------------------------------------------------------------------------
# Grade computation
# ---------------------------------------------------------------------------

# AUTO_POOL -- 68 pts max (summed below)
AUTO_MAX=0
AUTO_EARNED=0
for k in COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    w="${WEIGHTS[$k]}"
    AUTO_MAX=$((AUTO_MAX + w))
    if [ "$k" = "COV" ]; then
        # COV uses partial scoring
        AUTO_EARNED=$((AUTO_EARNED + COV_EARNED))
    elif [ "${RESULTS[$k]}" = "pass" ]; then
        AUTO_EARNED=$((AUTO_EARNED + w))
    fi
done

# Grade letter function (shared for machine and human pools)
# Usage: letter_grade <earned> <max>
letter_grade() {
    local earned="$1" max="$2"
    local pct
    # Use integer math: pct = earned * 100 / max
    pct=$(( earned * 100 / max ))
    if   [ "$pct" -ge 98 ]; then echo "A+"
    elif [ "$pct" -ge 95 ]; then echo "A"
    elif [ "$pct" -ge 90 ]; then echo "A-"
    elif [ "$pct" -ge 85 ]; then echo "B+"
    elif [ "$pct" -ge 80 ]; then echo "B"
    elif [ "$pct" -ge 75 ]; then echo "B-"
    elif [ "$pct" -ge 70 ]; then echo "C+"
    elif [ "$pct" -ge 65 ]; then echo "C"
    elif [ "$pct" -ge 60 ]; then echo "C-"
    elif [ "$pct" -ge 49 ]; then echo "D"
    else echo "F"
    fi
}

# Grade order for min() comparison
grade_order() {
    case "$1" in
        A+) echo 11 ;;
        A)  echo 10 ;;
        A-) echo 9  ;;
        B+) echo 8  ;;
        B)  echo 7  ;;
        B-) echo 6  ;;
        C+) echo 5  ;;
        C)  echo 4  ;;
        C-) echo 3  ;;
        D)  echo 2  ;;
        F)  echo 1  ;;
        *)  echo 0  ;;
    esac
}

grade_from_order() {
    case "$1" in
        11) echo "A+" ;;
        10) echo "A"  ;;
        9)  echo "A-" ;;
        8)  echo "B+" ;;
        7)  echo "B"  ;;
        6)  echo "B-" ;;
        5)  echo "C+" ;;
        4)  echo "C"  ;;
        3)  echo "C-" ;;
        2)  echo "D"  ;;
        *)  echo "F"  ;;
    esac
}

# COV coverage < 60% = automatic F on Machine Grade
MACHINE_GRADE_REASON=""
if [ "$COV_RESULT" = "fail" ]; then
    MACHINE_GRADE="F"
    MACHINE_GRADE_REASON="COV coverage < 60% -- completeness gate failed (doc-set coverage insufficient)"
else
    MACHINE_GRADE=$(letter_grade "$AUTO_EARNED" "$AUTO_MAX")
fi

# Human Grade -- if checklist not run, default to 0/30 -> F
if [ "$MANUAL_RUN" -eq 0 ]; then
    HUMAN_GRADE="F"
    HUMAN_GRADE_REASON="manual-checklist.sh not yet run (0/30 assumed)"
elif [ "${MANUAL_V1:-0}" -eq 0 ]; then
    # V1 is a MANDATORY GATE. If the human visual gate failed (or was not
    # affirmed), the summary cannot be approved -- Human Grade is forced to F
    # regardless of K1/K2, so the Overall Grade (min) is F too.
    HUMAN_GRADE="F"
    HUMAN_GRADE_REASON="V1 human visual gate FAILED -- mandatory gate; summary cannot be approved until the visual issue is fixed and V1 re-confirmed"
else
    HUMAN_GRADE=$(letter_grade "$MANUAL_EARNED" "$MANUAL_MAX")
    HUMAN_GRADE_REASON=""
fi

# Overall grade = min of the two
MG_ORDER=$(grade_order "$MACHINE_GRADE")
HG_ORDER=$(grade_order "$HUMAN_GRADE")
if [ "$MG_ORDER" -le "$HG_ORDER" ]; then
    OVERALL_ORDER="$MG_ORDER"
else
    OVERALL_ORDER="$HG_ORDER"
fi
OVERALL_GRADE=$(grade_from_order "$OVERALL_ORDER")

# A+ requires both pools near-perfect
if [ "$OVERALL_GRADE" = "A+" ]; then
    # Machine: all 68 pts; Human: all 30 pts
    if [ "$AUTO_EARNED" -lt "$AUTO_MAX" ] || [ "$MANUAL_EARNED" -lt "$MANUAL_MAX" ]; then
        OVERALL_GRADE="A"
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "========================================================"
echo "Grade Report"
echo "========================================================"
echo ""
echo "  [AUTO POOL -- Machine Grade]"
printf "  %-4s  %-36s  %-8s  %s\n" "ID" "Check" "Status" "Pts"

for k in COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    w="${WEIGHTS[$k]}"
    name="${CHECK_NAMES[$k]}"
    # Append H1 mode note
    if [ "$k" = "H1" ] && [ -n "$H1_MODE_NOTE" ]; then
        name="$name $H1_MODE_NOTE"
    fi

    if [ "$k" = "COV" ]; then
        # Special: partial scoring + label
        if [ "$COV_RESULT" = "pass" ]; then
            status="pass"
            symbol="[PASS]"
        else
            status="FAIL"
            symbol="[FAIL]"
        fi
        printf "  %-4s  %-44s  %-8s  %d/%d\n" "$k" "$name ($COV_LABEL)" "$symbol" "$COV_EARNED" "$w"
    elif [ "$k" = "D1" ] || [ "$k" = "D2" ]; then
        # D1/D2: Mermaid engine retired (Change 7 / FR-51 / D-012) -- trivially passed
        printf "  %-4s  %-44s  %-8s  %d/%d\n" "$k" "$name (engine retired)" "[PASS]" "$w" "$w"
    else
        if [ "${RESULTS[$k]}" = "pass" ]; then
            status="pass"
            symbol="[PASS]"
            earned="$w"
        else
            status="FAIL"
            symbol="[FAIL]"
            earned=0
        fi
        printf "  %-4s  %-44s  %-8s  %d/%d\n" "$k" "$name" "$symbol" "$earned" "$w"
    fi
done

echo ""
printf "  Auto score: %d / %d\n" "$AUTO_EARNED" "$AUTO_MAX"
printf "  Machine Grade: %s\n" "$MACHINE_GRADE"
if [ -n "$MACHINE_GRADE_REASON" ]; then
    echo "  Note: $MACHINE_GRADE_REASON"
fi

echo ""
echo "  [MANUAL POOL -- Human Grade]"
if [ "$MANUAL_RUN" -eq 1 ]; then
    printf "  %-4s  %-36s  %-8s  %s\n" "ID" "Check" "Status" "Pts"
    printf "  %-4s  %-44s  %-8s  %d/%d\n" "K1" "Resolved-doc-set coverage (human)" \
        "$([ "$MANUAL_K1" -gt 0 ] && echo "[pass]" || echo "[0 pts]")" "$MANUAL_K1" 10
    printf "  %-4s  %-44s  %-8s  %d/%d\n" "K2" "KB facts grounded" \
        "$([ "$MANUAL_K2" -gt 0 ] && echo "[pass]" || echo "[0 pts]")" "$MANUAL_K2" 15
    printf "  %-4s  %-44s  %-8s  %d/%d\n" "V1" "Human visual gate (mandatory)" \
        "$([ "${MANUAL_V1:-0}" -gt 0 ] && echo "[pass]" || echo "[GATE FAILED]")" "${MANUAL_V1:-0}" 5
    echo ""
    if [ "${MANUAL_V1:-0}" -eq 0 ]; then
        echo "  WARNING: V1 VISUAL GATE FAILED -- APPROVAL is blocked. A human must open"
        echo "  the HTML in a browser, confirm all visuals render + text is legible"
        echo "  in BOTH themes + theme toggle + lightbox all work, then re-run"
        echo "  manual-checklist.sh with --v1 y."
        echo "  (If no visuals are present, V1 is trivially passed -- confirm with --v1 y.)"
        echo ""
    fi
    # Read timestamp if present
    CHECKLIST_TS=$(grep '"timestamp"' "$MANUAL_CHECKLIST_FILE" 2>/dev/null \
        | sed 's/.*"timestamp":[[:space:]]*"\([^"]*\)".*/\1/' || true)
    [ -n "$CHECKLIST_TS" ] && echo "  Checklist completed: $CHECKLIST_TS"
else
    echo "  WARNING: manual-checklist.sh not yet run."
    echo "  Run: bash .github/aid/scripts/summarize/manual-checklist.sh --html $HTML"
    echo "  Then re-run grade-summary.sh to see your Human Grade."
fi

printf "  Manual score: %d / %d\n" "$MANUAL_EARNED" "$MANUAL_MAX"
printf "  Human Grade: %s\n" "$HUMAN_GRADE"
if [ -n "$HUMAN_GRADE_REASON" ]; then
    echo "  Note: $HUMAN_GRADE_REASON"
fi

echo ""
echo "========================================================"
echo ""
echo "  Overall Grade: $OVERALL_GRADE  (min of Machine=$MACHINE_GRADE, Human=$HUMAN_GRADE)"
echo ""

# ---------------------------------------------------------------------------
# Exit code: 0 if Machine Grade is A- or better
# ---------------------------------------------------------------------------
MG_ORDER=$(grade_order "$MACHINE_GRADE")
if [ "$MG_ORDER" -ge 9 ]; then  # A- or better
    exit 0
else
    exit 1
fi
