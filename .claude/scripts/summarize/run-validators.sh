#!/usr/bin/env bash
# run-validators.sh — orchestrator for /aid-summarize VALIDATE state.
# (Renamed from knowledge-summary/scripts/grade.sh in 2026-05-26 script
#  consolidation; the universal grade computation lives at canonical/scripts/grade.sh.)
# Runs all automated checks and emits a structured two-grade report.
#
# Usage:
#   run-validators.sh <html-file> [--fast]
#
# Flags:
#   --fast    Pass --fast to validate-diagrams.mjs (skip render; for development).
#   -h, --help  Print this header and exit.
#
# Exit codes:
#   0  Machine Grade is A- or better (for CI integration).
#   1  Machine Grade is below A-.
#   2  Invocation error.
#
# Two-grade model:
#   Machine Grade  — auto-verifiable checks only (AUTO_POOL = D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; 73 pts max)
#   Human Grade    — manual checklist only (MANUAL_POOL = K1 K2 V1; 30 pts max)
#   Overall Grade  — the lower of the two letter grades.
#
# A+ requires BOTH Machine Grade >= 98% of 73 pts AND Human Grade >= 98% of 30.
# Manual checks default to 0/30 if .manual-checklist.json has not been run.
# V1 (human visual gate) is MANDATORY: V1=0 forces Human Grade = F.
#
# Diagram-count hard rule:
#   Reads active profile from .aid/knowledge/STATE.md `## Knowledge Summary Status`
#   block (**Profile:** line). Pre-FR2 this lived in SUMMARY-STATE.md.
#   Reads target_diagrams from templates/knowledge-summary/section-templates/{profile}.md
#   YAML frontmatter. Falls back to 6 if the field is absent.
#   If actual diagram count < target, grade is capped at C+.

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
            echo "❌ Unknown flag: $arg" >&2
            exit 2
            ;;
        *)
            HTML="$arg"
            ;;
    esac
done

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "❌ Usage: run-validators.sh <html-file> [--fast]" >&2
    exit 2
fi

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
KB_DIR=".aid/knowledge"
STATE="$KB_DIR/STATE.md"
MANUAL_CHECKLIST_FILE="$KB_DIR/.manual-checklist.json"
# Section templates live under templates/knowledge-summary/, not next to the scripts.
# SCRIPT_DIR = .claude/scripts/summarize  →  templates dir is 2 levels up + templates/knowledge-summary/section-templates.
SECTION_TEMPLATES_DIR="$SCRIPT_DIR/../../templates/knowledge-summary/section-templates"

# ---------------------------------------------------------------------------
# Resolve active profile and target_diagrams
# ---------------------------------------------------------------------------
# FR2: profile lives in STATE.md `## Knowledge Summary Status` block.
# Scope the lookup to that section so we don't pick up a Profile line that
# might appear elsewhere (e.g., inside a KB document quoted in another section).
ACTIVE_PROFILE=""
if [ -f "$STATE" ]; then
    ACTIVE_PROFILE=$(awk '
        /^## Knowledge Summary Status/ {in_section=1; next}
        in_section && /^## / {in_section=0}
        in_section && /^\*\*Profile:\*\*/ {print; exit}
    ' "$STATE" \
        | sed 's/^\*\*Profile:\*\*[[:space:]]*//' \
        | awk '{print $1}' \
        | tr -d '\r')
fi

if [ -z "$ACTIVE_PROFILE" ]; then
    echo "⚠️  Cannot determine active profile from $STATE (## Knowledge Summary Status); defaulting to 'cli'."
    ACTIVE_PROFILE="cli"
fi

PROFILE_FILE="$SECTION_TEMPLATES_DIR/${ACTIVE_PROFILE}.md"
TARGET_DIAGRAMS=6  # rubric default

if [ -f "$PROFILE_FILE" ]; then
    # Look for a YAML frontmatter field: target_diagrams: N
    # Also accept it in the body as "target_diagrams: N"
    TD=$(grep -m1 'target_diagrams:' "$PROFILE_FILE" 2>/dev/null \
        | sed 's/.*target_diagrams:[[:space:]]*//' \
        | tr -d '\r ' | grep -E '^[0-9]+$' || true)
    if [ -n "$TD" ]; then
        TARGET_DIAGRAMS="$TD"
    else
        # Fallback: count the rows in the ## Diagrams table in the template
        # (each "| Fig |" row counts as one diagram)
        TD_COUNTED=$(grep -cE '^\|[[:space:]]+[0-9]+[[:space:]]*\|' "$PROFILE_FILE" 2>/dev/null || echo 0)
        if [ "$TD_COUNTED" -gt 0 ]; then
            TARGET_DIAGRAMS="$TD_COUNTED"
        fi
    fi
fi

# Count actual diagrams in the HTML
ACTUAL_DIAGRAMS=$(grep -cE 'class="mermaid"' "$HTML" 2>/dev/null || echo 0)

echo "Validating $HTML ..."
echo "Profile: $ACTIVE_PROFILE | Target diagrams: $TARGET_DIAGRAMS | Actual: $ACTUAL_DIAGRAMS"
echo ""

# ---------------------------------------------------------------------------
# Per-check result tracking
# ---------------------------------------------------------------------------
declare -A RESULTS
for k in D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    RESULTS[$k]=fail
done

# AUTO_POOL weights (73 pts total — summed dynamically into AUTO_MAX below)
declare -A WEIGHTS=(
    [D1]=20 [D2]=10
    [L1]=5  [L2]=5
    [H1]=5
    [A1]=5  [A2]=3  [A3]=5  [A4]=2  [A5]=3
    [C1]=4  [C2]=4
    [S2]=2
)

# Metadata for check names (display only)
declare -A CHECK_NAMES=(
    [D1]="Mermaid parse"
    [D2]="Mermaid render"
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
# D1 + D2: Mermaid validation
# ---------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[Mermaid diagrams — D1 parse, D2 render]"
DIAG_LOG=$(mktemp)
node "$SCRIPT_DIR/validate-diagrams.mjs" "$HTML" $FAST > "$DIAG_LOG" 2>&1 || true
cat "$DIAG_LOG"

# D1 and D2 are scored INDEPENDENTLY by parsing the validator's explicit
# ✅/❌ markers — not by the process exit code (a D2-only failure must not
# drag D1 down to fail, which would trigger the automatic-F rule).
if grep -qE "❌ D1:" "$DIAG_LOG"; then
    RESULTS[D1]=fail
elif grep -qE "✅ D1:" "$DIAG_LOG"; then
    RESULTS[D1]=pass
else
    # No explicit D1 verdict — treat as unverified.
    RESULTS[D1]=fail
fi

# D2: explicit failure wins; then "pass-trivial" (jsdom AND mmdc both absent —
# render never actually verified) counts as fail; an explicit ✅ D2 is a pass.
if grep -qE "❌ D2:" "$DIAG_LOG"; then
    RESULTS[D2]=fail
elif grep -qE "D2:.*pass-trivial" "$DIAG_LOG"; then
    RESULTS[D2]=fail
elif grep -qE "✅ D2:" "$DIAG_LOG"; then
    RESULTS[D2]=pass
else
    RESULTS[D2]=fail
fi
rm -f "$DIAG_LOG"
echo ""

# ---------------------------------------------------------------------------
# H1 + A1-A5 + S2 + L1 + L2: HTML structure/validity/a11y + link validation
# (validate-html-output.sh merges the former validate-html.sh + validate-links.sh
#  per 2026-05-26 script consolidation)
# ---------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[HTML output validation — H1 A1 A2 A3 A4 A5 S2 + L1 L2]"
HTML_LOG=$(mktemp)
if bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML" > "$HTML_LOG" 2>&1; then
    cat "$HTML_LOG"
    RESULTS[H1]=pass
    RESULTS[A1]=pass
    RESULTS[A2]=pass
    RESULTS[A3]=pass
    RESULTS[A4]=pass
    RESULTS[A5]=pass
    RESULTS[S2]=pass
    RESULTS[L1]=pass
    RESULTS[L2]=pass
else
    cat "$HTML_LOG"
    grep -q "✅ H1\."        "$HTML_LOG" && RESULTS[H1]=pass
    grep -q "✅ A1\."        "$HTML_LOG" && RESULTS[A1]=pass
    grep -q "✅ A2\."        "$HTML_LOG" && RESULTS[A2]=pass
    grep -q "✅ A3\."        "$HTML_LOG" && RESULTS[A3]=pass
    grep -q "✅ A4\."        "$HTML_LOG" && RESULTS[A4]=pass
    grep -q "✅ A5\."        "$HTML_LOG" && RESULTS[A5]=pass
    grep -q "✅ S2\."        "$HTML_LOG" && RESULTS[S2]=pass
    # L1/L2 link checks (merged from former validate-links.sh into validate-html-output.sh)
    grep -q "✅ L1\."        "$HTML_LOG" && RESULTS[L1]=pass
    grep -q "✅ L2\."        "$HTML_LOG" && RESULTS[L2]=pass

    # Fallback: check older label styles used by sub-checks
    grep -q "✅ A1.1"        "$HTML_LOG" && RESULTS[A1]=pass
    grep -q "✅ A2.1"        "$HTML_LOG" && RESULTS[A2]=pass
    grep -q "✅ A4.1"        "$HTML_LOG" && RESULTS[A4]=pass
    grep -q "✅ A5.1"        "$HTML_LOG" && RESULTS[A5]=pass
    grep -q "✅ S2\. Mermaid" "$HTML_LOG" && RESULTS[S2]=pass
fi

# Capture H1 mode note for report (match the labels printed by validate-html.sh)
if grep -q "regex fallback" "$HTML_LOG" 2>/dev/null; then
    H1_MODE_NOTE="(regex fallback — tidy/html-validate not installed)"
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[Theme contrast — C1 light, C2 dark]"
CONTRAST_LOG=$(mktemp)
if node "$SCRIPT_DIR/contrast-check.mjs" "$HTML" > "$CONTRAST_LOG" 2>&1; then
    cat "$CONTRAST_LOG"
    RESULTS[C1]=pass
    RESULTS[C2]=pass
else
    cat "$CONTRAST_LOG"
    # Light theme: no ❌ in the block after [light theme]
    if ! grep -A50 '\[light theme\]' "$CONTRAST_LOG" | grep -m1 '^\[dark' >/dev/null 2>&1; then
        # Only light block in output
        if ! grep -A50 '\[light theme\]' "$CONTRAST_LOG" | grep -q '❌'; then
            RESULTS[C1]=pass
        fi
    else
        LIGHT_BLOCK=$(sed -n '/\[light theme\]/,/\[dark theme\]/p' "$CONTRAST_LOG")
        if ! echo "$LIGHT_BLOCK" | grep -q '❌'; then RESULTS[C1]=pass; fi
        DARK_BLOCK=$(sed -n '/\[dark theme\]/,$p' "$CONTRAST_LOG")
        if ! echo "$DARK_BLOCK" | grep -q '❌'; then RESULTS[C2]=pass; fi
    fi
    if grep -q "All contrast checks passed" "$CONTRAST_LOG"; then
        RESULTS[C1]=pass; RESULTS[C2]=pass
    fi
fi
rm -f "$CONTRAST_LOG"
echo ""

# ---------------------------------------------------------------------------
# Manual checklist — K1 + K2 + V1
# ---------------------------------------------------------------------------
MANUAL_K1=0
MANUAL_K2=0
MANUAL_V1=0
MANUAL_RUN=0

if [ -f "$MANUAL_CHECKLIST_FILE" ]; then
    MANUAL_RUN=1
    # Parse K1_score / K2_score / V1_score VALUES from JSON.
    # NOTE: extract the number AFTER the colon — a naive `grep -oE '[0-9]+'`
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
# Diagram-count hard rule
# ---------------------------------------------------------------------------
DIAG_RULE_VIOLATED=0
if [ "$ACTUAL_DIAGRAMS" -lt "$TARGET_DIAGRAMS" ]; then
    DIAG_RULE_VIOLATED=1
fi

# ---------------------------------------------------------------------------
# Grade computation
# ---------------------------------------------------------------------------

# AUTO_POOL — 73 pts max (summed below)
AUTO_MAX=0
AUTO_EARNED=0
for k in D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    w="${WEIGHTS[$k]}"
    AUTO_MAX=$((AUTO_MAX + w))
    if [ "${RESULTS[$k]}" = "pass" ]; then
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
        C-)  echo 3 ;;
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

# D1 fail = automatic F on Machine Grade
if [ "${RESULTS[D1]}" = "fail" ]; then
    MACHINE_GRADE="F"
    MACHINE_GRADE_REASON="D1 (Mermaid parse) failed — automatic F per rubric"
else
    MACHINE_GRADE=$(letter_grade "$AUTO_EARNED" "$AUTO_MAX")
    MACHINE_GRADE_REASON=""
fi

# Human Grade — if checklist not run, default to 0/30 → F
if [ "$MANUAL_RUN" -eq 0 ]; then
    HUMAN_GRADE="F"
    HUMAN_GRADE_REASON="manual-checklist.sh not yet run (0/30 assumed)"
elif [ "${MANUAL_V1:-0}" -eq 0 ]; then
    # V1 is a MANDATORY GATE. If the human visual gate failed (or was not
    # affirmed), the summary cannot be approved — Human Grade is forced to F
    # regardless of K1/K2, so the Overall Grade (min) is F too.
    HUMAN_GRADE="F"
    HUMAN_GRADE_REASON="V1 human visual gate FAILED — mandatory gate; summary cannot be approved until the visual issue is fixed and V1 re-confirmed"
else
    HUMAN_GRADE=$(letter_grade "$MANUAL_EARNED" "$MANUAL_MAX")
    HUMAN_GRADE_REASON=""
fi

# Apply diagram-count hard rule: cap at C+ if violated
if [ "$DIAG_RULE_VIOLATED" -eq 1 ]; then
    MG_ORDER=$(grade_order "$MACHINE_GRADE")
    CP_ORDER=$(grade_order "C+")
    if [ "$MG_ORDER" -gt "$CP_ORDER" ]; then
        MACHINE_GRADE="C+"
        MACHINE_GRADE_REASON="Diagram count ($ACTUAL_DIAGRAMS) < target ($TARGET_DIAGRAMS) — capped at C+"
    fi
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
    # Machine: all 73 pts; Human: all 30 pts
    if [ "$AUTO_EARNED" -lt "$AUTO_MAX" ] || [ "$MANUAL_EARNED" -lt "$MANUAL_MAX" ]; then
        OVERALL_GRADE="A"
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Grade Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  [AUTO POOL — Machine Grade]"
printf "  %-4s  %-26s  %-8s  %s\n" "ID" "Check" "Status" "Pts"

for k in D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2; do
    status=$([ "${RESULTS[$k]}" = "pass" ] && echo "pass" || echo "FAIL")
    symbol=$([ "${RESULTS[$k]}" = "pass" ] && echo "✅" || echo "❌")
    w="${WEIGHTS[$k]}"
    earned=$([ "${RESULTS[$k]}" = "pass" ] && echo "$w" || echo "0")
    name="${CHECK_NAMES[$k]}"
    # Append H1 mode note
    if [ "$k" = "H1" ] && [ -n "$H1_MODE_NOTE" ]; then
        name="$name $H1_MODE_NOTE"
    fi
    printf "  %-4s  %-40s  %s %-4s  %d/%d\n" "$k" "$name" "$symbol" "$status" "$earned" "$w"
done

echo ""
printf "  Auto score: %d / %d\n" "$AUTO_EARNED" "$AUTO_MAX"
printf "  Machine Grade: %s\n" "$MACHINE_GRADE"
if [ -n "$MACHINE_GRADE_REASON" ]; then
    echo "  Note: $MACHINE_GRADE_REASON"
fi

echo ""
echo "  [MANUAL POOL — Human Grade]"
if [ "$MANUAL_RUN" -eq 1 ]; then
    printf "  %-4s  %-26s  %-8s  %s\n" "ID" "Check" "Status" "Pts"
    printf "  %-4s  %-40s  %s  %d/%d\n" "K1" "KB completeness" \
        "$([ "$MANUAL_K1" -gt 0 ] && echo "✅ pass" || echo "❌ 0 pts")" "$MANUAL_K1" 10
    printf "  %-4s  %-40s  %s  %d/%d\n" "K2" "KB facts grounded" \
        "$([ "$MANUAL_K2" -gt 0 ] && echo "✅ pass" || echo "❌ 0 pts")" "$MANUAL_K2" 15
    printf "  %-4s  %-40s  %s  %d/%d\n" "V1" "Human visual gate (mandatory)" \
        "$([ "${MANUAL_V1:-0}" -gt 0 ] && echo "✅ pass" || echo "❌ GATE FAILED")" "${MANUAL_V1:-0}" 5
    echo ""
    if [ "${MANUAL_V1:-0}" -eq 0 ]; then
        echo "  ⚠️  V1 VISUAL GATE FAILED — APPROVAL is blocked. A human must open"
        echo "     the HTML in a browser, confirm diagrams render + text is legible"
        echo "     in BOTH themes + theme toggle + lightbox all work, then re-run"
        echo "     manual-checklist.sh with --v1 y."
        echo ""
    fi
    # Read timestamp if present
    CHECKLIST_TS=$(grep '"timestamp"' "$MANUAL_CHECKLIST_FILE" 2>/dev/null \
        | sed 's/.*"timestamp":[[:space:]]*"\([^"]*\)".*/\1/' || true)
    [ -n "$CHECKLIST_TS" ] && echo "  Checklist completed: $CHECKLIST_TS"
else
    echo "  ⚠️  manual-checklist.sh not yet run."
    echo "     Run: bash canonical/scripts/summarize/manual-checklist.sh --html $HTML"
    echo "     Then re-run run-validators.sh to see your Human Grade."
fi

printf "  Manual score: %d / %d\n" "$MANUAL_EARNED" "$MANUAL_MAX"
printf "  Human Grade: %s\n" "$HUMAN_GRADE"
if [ -n "$HUMAN_GRADE_REASON" ]; then
    echo "  Note: $HUMAN_GRADE_REASON"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Diagram count rule note
if [ "$DIAG_RULE_VIOLATED" -eq 1 ]; then
    echo "  ⚠️  Diagram count: $ACTUAL_DIAGRAMS < target $TARGET_DIAGRAMS (profile: $ACTIVE_PROFILE)"
    echo "     Machine Grade capped at C+ per rubric hard rule."
else
    echo "  Diagram count: $ACTUAL_DIAGRAMS / $TARGET_DIAGRAMS (profile: $ACTIVE_PROFILE) ✅"
fi

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
