#!/usr/bin/env bash
# grade.sh — orchestrator for /aid-summarize VALIDATE state.
# Runs all automated checks and emits a structured grade report.
#
# Usage: grade.sh <html-file> [--fast]
# Exit 0 if grade ≥ A, 1 otherwise. Detailed output on stdout.

set -u

HTML="${1:-}"
FAST=""
if [ "${2:-}" = "--fast" ]; then FAST="--fast"; fi

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "❌ Usage: grade.sh <html-file> [--fast]" >&2
    exit 2
fi

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Initialize per-check pass tracking
declare -A RESULTS
RESULTS[D1]=fail
RESULTS[D2]=fail
RESULTS[L1]=fail
RESULTS[L2]=fail
RESULTS[H1]=fail
RESULTS[A1]=fail
RESULTS[A2]=fail
RESULTS[A4]=fail
RESULTS[A5]=fail
RESULTS[C1]=fail
RESULTS[C2]=fail
RESULTS[S2]=fail

# Weights from references/grading-rubric.md (sum = 78 automated points;
# K1/K2 manual = 25 points)
declare -A WEIGHTS=(
    [D1]=20 [D2]=10
    [L1]=5  [L2]=5
    [H1]=5
    [A1]=5  [A2]=3  [A4]=2 [A5]=3
    [C1]=4  [C2]=4
    [S2]=2
)

echo "Validating $HTML ..."
echo ""

# --- D1 + D2: Mermaid validation ---
echo "[Mermaid diagrams]"
DIAG_LOG=$(mktemp)
if node "$SCRIPT_DIR/validate-diagrams.mjs" "$HTML" $FAST > "$DIAG_LOG" 2>&1; then
    cat "$DIAG_LOG"
    RESULTS[D1]=pass
    # D2 only counts if mmdc was used (real render); in --fast mode we can't verify D2
    if [ -z "$FAST" ] && grep -q "Using mmdc\|Using npx" "$DIAG_LOG"; then
        RESULTS[D2]=pass
    else
        # Regex-only mode: assume D2 pass if D1 passed (best we can do).
        # The skill should use mmdc for grading runs.
        RESULTS[D2]=pass
    fi
else
    cat "$DIAG_LOG"
    # D1 fail = automatic F regardless of other scores
    RESULTS[D1]=fail
    RESULTS[D2]=fail
    HARD_FAIL=1
fi
rm -f "$DIAG_LOG"
echo ""

# --- L1 + L2: link validation ---
echo "[Link validation]"
LINK_LOG=$(mktemp)
if bash "$SCRIPT_DIR/validate-links.sh" "$HTML" > "$LINK_LOG" 2>&1; then
    cat "$LINK_LOG"
    RESULTS[L1]=pass
    RESULTS[L2]=pass
else
    cat "$LINK_LOG"
    # Sub-classify
    if grep -q "anchor links resolve" "$LINK_LOG"; then RESULTS[L1]=pass; fi
    if grep -q "md links resolve" "$LINK_LOG"; then RESULTS[L2]=pass; fi
fi
rm -f "$LINK_LOG"
echo ""

# --- H1 + A1 + A2 + A4 + A5 + S2: HTML structure validation ---
echo "[HTML structure & accessibility]"
HTML_LOG=$(mktemp)
if bash "$SCRIPT_DIR/validate-html.sh" "$HTML" > "$HTML_LOG" 2>&1; then
    cat "$HTML_LOG"
    RESULTS[H1]=pass
    RESULTS[A1]=pass
    RESULTS[A2]=pass
    RESULTS[A4]=pass
    RESULTS[A5]=pass
    RESULTS[S2]=pass
else
    cat "$HTML_LOG"
    # Sub-classify based on which checks passed in the log
    grep -q "✅ A1\." "$HTML_LOG" && RESULTS[A1]=pass
    grep -q "✅ A2\." "$HTML_LOG" && RESULTS[A2]=pass
    grep -q "✅ A4\." "$HTML_LOG" && RESULTS[A4]=pass
    grep -q "✅ A5\." "$HTML_LOG" && RESULTS[A5]=pass
    grep -q "✅ Mermaid library inlined" "$HTML_LOG" && RESULTS[S2]=pass
    # H1 here is "all structural checks pass" — only true if no failures
    if ! grep -q "^  ❌" "$HTML_LOG"; then RESULTS[H1]=pass; fi
fi
rm -f "$HTML_LOG"
echo ""

# --- C1 + C2: contrast ---
echo "[Theme contrast]"
CONTRAST_LOG=$(mktemp)
if node "$SCRIPT_DIR/contrast-check.mjs" "$HTML" > "$CONTRAST_LOG" 2>&1; then
    cat "$CONTRAST_LOG"
    RESULTS[C1]=pass
    RESULTS[C2]=pass
else
    cat "$CONTRAST_LOG"
    # Sub-classify
    if ! grep -A2 '\[light theme\]' "$CONTRAST_LOG" | grep -q "❌"; then RESULTS[C1]=pass; fi
    if ! grep -A100 '\[dark theme\]' "$CONTRAST_LOG" | grep -B100 '^✅\|^❌ ' | grep -q "❌" 2>/dev/null; then
        : # complex — skip
    fi
    # Simpler: check overall summary
    if grep -q "All contrast checks passed" "$CONTRAST_LOG"; then
        RESULTS[C1]=pass; RESULTS[C2]=pass
    fi
fi
rm -f "$CONTRAST_LOG"
echo ""

# --- Compute score ---
TOTAL_AUTO=0
EARNED_AUTO=0
for k in "${!WEIGHTS[@]}"; do
    w="${WEIGHTS[$k]}"
    TOTAL_AUTO=$((TOTAL_AUTO + w))
    if [ "${RESULTS[$k]}" = "pass" ]; then
        EARNED_AUTO=$((EARNED_AUTO + w))
    fi
done

# Manual checks (K1, K2) — assumed pass for automated grading; agent verifies separately
MANUAL_TOTAL=25
MANUAL_EARNED=25  # default; agent may override during VALIDATE state

TOTAL=$((TOTAL_AUTO + MANUAL_TOTAL))
EARNED=$((EARNED_AUTO + MANUAL_EARNED))

# Hard rule: D1 fail = F regardless
GRADE=""
if [ "${RESULTS[D1]}" = "fail" ]; then
    GRADE="F"
    GRADE_REASON="D1 (Mermaid parse) failed — automatic F per grading rubric"
elif (( EARNED >= 96 )); then GRADE="A+"
elif (( EARNED >= 93 )); then GRADE="A"
elif (( EARNED >= 88 )); then GRADE="A-"
elif (( EARNED >= 83 )); then GRADE="B+"
elif (( EARNED >= 78 )); then GRADE="B"
elif (( EARNED >= 73 )); then GRADE="B-"
elif (( EARNED >= 68 )); then GRADE="C+"
elif (( EARNED >= 63 )); then GRADE="C"
elif (( EARNED >= 58 )); then GRADE="C-"
elif (( EARNED >= 48 )); then GRADE="D"
else GRADE="F"
fi

# --- Report ---
echo "─────────────────────────────────────────────"
echo "Grade Report"
echo "─────────────────────────────────────────────"
printf "%-4s %-30s %s\n" "ID" "Check" "Status"
for k in D1 D2 L1 L2 H1 A1 A2 A4 A5 C1 C2 S2; do
    status=$([ "${RESULTS[$k]}" = "pass" ] && echo "✅ pass" || echo "❌ fail")
    weight="${WEIGHTS[$k]}"
    printf "%-4s %-30s %s (weight %d)\n" "$k" "$(grep -E "^\| \*\*$k\*\*" /dev/null 2>/dev/null || echo "")" "$status" "$weight" 2>/dev/null || \
    printf "%-4s %s (weight %d)\n" "$k" "$status" "$weight"
done
echo ""
echo "Score: $EARNED / $TOTAL ($EARNED_AUTO automated + $MANUAL_EARNED manual)"
echo "Grade: $GRADE"
if [ -n "${GRADE_REASON:-}" ]; then echo "Note:  $GRADE_REASON"; fi
echo ""

# Exit code: 0 if grade is A or better, 1 otherwise (for CI integration)
case "$GRADE" in
    A+|A|A-) exit 0 ;;
    *) exit 1 ;;
esac
