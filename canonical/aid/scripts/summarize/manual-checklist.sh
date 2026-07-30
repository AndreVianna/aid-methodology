#!/usr/bin/env bash
# manual-checklist.sh — human-review checklist for /aid-summarize MANUAL-CHECKLIST state.
#
# RECORDS the human-judgment answers that no automated check can produce:
#   K1  KB completeness    y | p | n
#   K2  fact grounding     y | p | n
#   V1  human visual check y | n      -- MANDATORY: a fail blocks APPROVAL
#
# IT NO LONGER SCORES THEM. The answers become ledger findings, and grade.sh derives the letter from
# the ledger -- one grading backend for every artifact in AID. The scores this script used to compute
# (10/15/5 into a 30-point pool) belonged to a second grading model that has been retired; see
# review-rubrics/summary.md and knowledge-summary/grading-rubric.md.
#
# An UNANSWERED checklist now produces NO GRADE rather than an F. Reporting a failing grade for a check
# nobody performed states a result that was never observed, and makes a real failure indistinguishable
# from an absent answer.
#
# V1 is a GATE, not a graded scale: the reviewer must open the HTML in a real
# browser and confirm ALL of: (a) every diagram/infographic/visual renders cleanly
# (nothing clipped, collapsed, or broken); (b) text in every visual is legible and
# elements do not overlap, in BOTH light and dark themes (the automated visual-fidelity
# gate checks size/overlap/layout; the human judges clarity + quality);
# (c) the light/dark theme toggle works; (d) the lightbox opens, Esc closes,
# and Tab cycles focus inside it. Any failure => V1=n, which becomes a SUMMARY-06
# finding AND blocks approval until fixed.
#
# Two modes:
#   Non-interactive (preferred inside a host AI tool): the agent gathers the
#   answers via the host's question UI, then calls this script with flags.
#     manual-checklist.sh --k1 y --k2 p --v1 y --notes "..." --html <file>
#   Interactive (contributor in a raw terminal):
#     manual-checklist.sh --interactive [--html <file>]
#
# Flags:
#   --k1 <y|p|n>      K1 answer (KB completeness).  Non-interactive trigger.
#   --k2 <y|p|n>      K2 answer (fact grounding).   Non-interactive trigger.
#   --v1 <y|n>        V1 answer (visual gate).      Non-interactive trigger.
#   --notes <text>    Free-text reviewer notes.
#   --html <file>     HTML file under review (display + recorded in JSON).
#   --out  <file>     Output JSON path (default: .aid/.temp/summarize/manual-checklist.json).
#   --input <file>    Validate an already-written checklist JSON, recompute
#                     normalises its answers, and rewrite it canonically.
#   --interactive     Force interactive prompts even if flags are given.
#   -h, --help        Print this header and exit.
#
# Exit codes:
#   0  Checklist completed and written.
#   1  User aborted (interactive gate answered 'n' to "opened in browser").
#   2  Invocation error (bad flag, bad value, missing --input file).
#
# Output JSON keys:
#   K1_answer, K2_answer, V1_answer,
#   notes, html_file, timestamp

set -euo pipefail

# --- Defaults ---
OUT_FILE=".aid/.temp/summarize/manual-checklist.json"
HTML_FILE=""
INPUT_FILE=""
FORCE_INTERACTIVE=0
K1_ANS=""
K2_ANS=""
V1_ANS=""
NOTES=""

# --- Argument parsing ---
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -48
            exit 0
            ;;
        --html)        HTML_FILE="${2:-}"; shift 2 ;;
        --out)         OUT_FILE="${2:-}"; shift 2 ;;
        --input)       INPUT_FILE="${2:-}"; shift 2 ;;
        --interactive) FORCE_INTERACTIVE=1; shift ;;
        --k1)          K1_ANS=$(echo "${2:-}" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        --k2)          K2_ANS=$(echo "${2:-}" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        --v1)          V1_ANS=$(echo "${2:-}" | tr '[:upper:]' '[:lower:]'); shift 2 ;;
        --notes)       NOTES="${2:-}"; shift 2 ;;
        *)
            echo "❌ Unknown argument: $1" >&2
            echo "   Run 'manual-checklist.sh --help' for usage." >&2
            exit 2
            ;;
    esac
done

# --- Helpers ---
escape_json() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# These used to return point values (10/5/0, 15/8/0, 5/0) feeding a 30-point pool. The points are gone
# with the second grading model; the VALIDATION they also performed is not, so each now normalises the
# answer and rejects anything outside its alphabet. An unvalidated answer would reach the JSON and, from
# there, the ledger.
normalize_ypn() {
    # $1 = answer, $2 = check name (for the error message)
    case "$1" in
        y|yes)     echo y ;;
        p|partial) echo p ;;
        n|no)      echo n ;;
        *) echo "❌ Invalid $2 answer: '$1' (expected y|p|n)" >&2; exit 2 ;;
    esac
}

normalize_yn() {
    # The human visual check is a gate: it passed or it did not. There is no partial.
    case "$1" in
        y|yes) echo y ;;
        n|no)  echo n ;;
        *) echo "❌ Invalid $2 answer: '$1' (expected y|n)" >&2; exit 2 ;;
    esac
}

ask_ypn() {
    local prompt="$1" varref="$2" ans
    while true; do
        printf "%s [y/p/n]: " "$prompt"
        read -r ans </dev/tty || { echo ""; ans="n"; }
        ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
        case "$ans" in
            y|yes)     eval "$varref=y"; return ;;
            p|partial) eval "$varref=p"; return ;;
            n|no)      eval "$varref=n"; return ;;
            *) echo "  Please answer y (yes), p (partial), or n (no)." ;;
        esac
    done
}

ask_yn() {
    local prompt="$1" varref="$2" ans
    while true; do
        printf "%s [y/n]: " "$prompt"
        read -r ans </dev/tty || { echo ""; ans="n"; }
        ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
        case "$ans" in
            y|yes) eval "$varref=y"; return ;;
            n|no)  eval "$varref=n"; return ;;
            *) echo "  Please answer y or n." ;;
        esac
    done
}

ask_text() {
    local prompt="$1" varref="$2" ans
    printf "%s: " "$prompt"
    read -r ans </dev/tty || ans=""
    eval "$varref=\"\$ans\""
}

write_json() {
    local k1 k2 v1
    k1=$(normalize_ypn "$K1_ANS" "K1") || exit 2
    k2=$(normalize_ypn "$K2_ANS" "K2") || exit 2
    v1=$(normalize_yn  "$V1_ANS" "V1") || exit 2

    local timestamp html_esc notes_esc out_dir
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    html_esc=$(escape_json "${HTML_FILE:-}")
    notes_esc=$(escape_json "${NOTES:-}")
    out_dir=$(dirname "$OUT_FILE")
    mkdir -p "$out_dir"

    # No *_score fields: this file records what the human ANSWERED. The grade is derived by grade.sh
    # from the review ledger, and emitting scores here would resurrect the second grading model as data.
    cat > "$OUT_FILE" << EOF
{
  "K1_answer": "$k1",
  "K2_answer": "$k2",
  "V1_answer": "$v1",
  "notes": "$notes_esc",
  "html_file": "$html_esc",
  "timestamp": "$timestamp"
}
EOF

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Answers recorded -- K1: $k1   K2: $k2   V1: $v1"
    if [ "$v1" = "n" ]; then
        echo "  ⚠️  VISUAL CHECK FAILED — the summary CANNOT be approved"
        echo "      until the visual issue is fixed and V1 re-confirmed."
    fi
    echo "  Saved to: $OUT_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Append the findings to the review ledger, then run grade.sh over it for the grade."
}

# --- Mode: --input (validate + recompute an existing JSON) ---
if [ -n "$INPUT_FILE" ]; then
    if [ ! -f "$INPUT_FILE" ]; then
        echo "❌ --input file not found: $INPUT_FILE" >&2
        exit 2
    fi
    K1_ANS=$(grep -oE '"K1_answer"[[:space:]]*:[[:space:]]*"[ypn]"' "$INPUT_FILE" | grep -oE '"[ypn]"' | tr -d '"' | head -1)
    K2_ANS=$(grep -oE '"K2_answer"[[:space:]]*:[[:space:]]*"[ypn]"' "$INPUT_FILE" | grep -oE '"[ypn]"' | tr -d '"' | head -1)
    V1_ANS=$(grep -oE '"V1_answer"[[:space:]]*:[[:space:]]*"[yn]"'  "$INPUT_FILE" | grep -oE '"[yn]"'  | tr -d '"' | head -1)
    if [ -z "$K1_ANS" ] || [ -z "$K2_ANS" ] || [ -z "$V1_ANS" ]; then
        echo "❌ --input JSON missing required K1_answer / K2_answer (y|p|n) / V1_answer (y|n)." >&2
        exit 2
    fi
    OUT_FILE="$INPUT_FILE"
    echo "[manual-checklist] Validated $INPUT_FILE — normalising answers."
    write_json
    exit 0
fi

# --- Mode: non-interactive (answers supplied via flags) ---
if [ -n "$K1_ANS" ] && [ -n "$K2_ANS" ] && [ -n "$V1_ANS" ] && [ "$FORCE_INTERACTIVE" -eq 0 ]; then
    echo "[manual-checklist] Non-interactive mode — recording supplied answers."
    write_json
    exit 0
fi

# --- Mode: interactive ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  /aid-summarize — Manual Review Checklist (interactive)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ -n "$HTML_FILE" ] && echo "  File: $HTML_FILE"
echo "  Records K1 (KB completeness) + K2 (fact grounding) + V1 (visual check). No scoring."
echo "  Saved to: $OUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GATE=""
ask_yn "Q1. Have you opened the kb.html file in a browser?" GATE
if [ "$GATE" = "n" ]; then
    echo ""
    echo "  Checklist aborted — open the file in a browser first, then re-run."
    echo "  (No JSON written.)"
    exit 1
fi
echo ""

echo "Q2. K1 — KB completeness"
echo "     Does the HTML cover every populated Knowledge Base document?"
echo "     (y = all sections present; p = minor gaps; n = major gaps)"
ask_ypn "     K1 answer" K1_ANS
echo ""

echo "Q3. K2 — Fact accuracy"
echo "     Spot-check 5 numeric/named facts against the source KB."
echo "     (Tip: run spot-check-facts.sh first for a prepared list.)"
echo "     (y = all verified; p = 1-2 minor discrepancies; n = errors found)"
ask_ypn "     K2 answer" K2_ANS
echo ""

echo "Q4. V1 — HUMAN VISUAL CHECK (mandatory)"
echo "     With the file open in a browser, confirm ALL of the following:"
echo "       (a) every diagram / infographic / visual renders cleanly — nothing clipped, collapsed, or broken;"
echo "       (b) text in every visual is LEGIBLE and elements do NOT overlap, in BOTH light AND dark themes"
echo "           (the automated visual-fidelity gate checks size/overlap/layout — YOU judge clarity + quality);"
echo "       (c) the light/dark theme toggle works;"
echo "       (d) the lightbox opens on click, Esc closes it, Tab cycles inside."
echo "     Answer y ONLY if all four hold. Any failure = n (gate fails)."
V1_ANS=""
ask_yn "     V1 visual gate — all four confirmed?" V1_ANS
if [ "$V1_ANS" = "n" ]; then
    echo "     ⚠️  Visual gate FAILED — note what is wrong below; the summary"
    echo "         cannot be approved until it is fixed."
fi
echo ""

echo "Q5. Free text — what failed, or anything else worth noting? (Enter to skip)"
ask_text "     Notes" NOTES
echo ""

write_json
exit 0
