#!/usr/bin/env bash
# manual-checklist.sh — human-review checklist for /aid-summarize MANUAL-CHECKLIST state.
#
# Scores the MANUAL_POOL (30 pts) that the automated grader cannot verify:
#   K1  KB completeness   (10 pts)  y=10 p=5 n=0
#   K2  fact grounding    (15 pts)  y=15 p=8 n=0
#   V1  human visual gate ( 5 pts)  y=5  n=0   — MANDATORY: V1=0 blocks APPROVAL
#
# V1 is a GATE, not a graded scale: the reviewer must open the HTML in a real
# browser and confirm ALL of: (a) every diagram/infographic/visual renders cleanly
# (nothing clipped, collapsed, or broken); (b) text in every visual is legible and
# elements do not overlap, in BOTH light and dark themes (the automated visual-fidelity
# gate checks size/overlap/layout; the human judges clarity + quality);
# (c) the light/dark theme toggle works; (d) the lightbox opens, Esc closes,
# and Tab cycles focus inside it. Any failure => V1=n (0 pts) AND the summary
# cannot be approved until fixed.
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
#                     scores from its answers, and rewrite it canonically.
#   --interactive     Force interactive prompts even if flags are given.
#   -h, --help        Print this header and exit.
#
# Exit codes:
#   0  Checklist completed and written.
#   1  User aborted (interactive gate answered 'n' to "opened in browser").
#   2  Invocation error (bad flag, bad value, missing --input file).
#
# Output JSON keys:
#   K1_score, K2_score, V1_score, K1_answer, K2_answer, V1_answer,
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

score_k1() {
    case "$1" in
        y|yes)     echo 10 ;;
        p|partial) echo 5  ;;
        n|no)      echo 0  ;;
        *) echo "❌ Invalid K1 answer: '$1' (expected y|p|n)" >&2; exit 2 ;;
    esac
}

score_k2() {
    case "$1" in
        y|yes)     echo 15 ;;
        p|partial) echo 8  ;;
        n|no)      echo 0  ;;
        *) echo "❌ Invalid K2 answer: '$1' (expected y|p|n)" >&2; exit 2 ;;
    esac
}

score_v1() {
    # V1 is a GATE: pass (5) or fail (0). No partial.
    case "$1" in
        y|yes) echo 5 ;;
        n|no)  echo 0 ;;
        *) echo "❌ Invalid V1 answer: '$1' (expected y|n)" >&2; exit 2 ;;
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
    local k1_score k2_score v1_score total
    k1_score=$(score_k1 "$K1_ANS")
    k2_score=$(score_k2 "$K2_ANS")
    v1_score=$(score_v1 "$V1_ANS")
    total=$((k1_score + k2_score + v1_score))

    local timestamp html_esc notes_esc out_dir
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    html_esc=$(escape_json "${HTML_FILE:-}")
    notes_esc=$(escape_json "${NOTES:-}")
    out_dir=$(dirname "$OUT_FILE")
    mkdir -p "$out_dir"

    cat > "$OUT_FILE" << EOF
{
  "K1_score": $k1_score,
  "K2_score": $k2_score,
  "V1_score": $v1_score,
  "K1_answer": "$(echo "$K1_ANS" | cut -c1)",
  "K2_answer": "$(echo "$K2_ANS" | cut -c1)",
  "V1_answer": "$(echo "$V1_ANS" | cut -c1)",
  "notes": "$notes_esc",
  "html_file": "$html_esc",
  "timestamp": "$timestamp"
}
EOF

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Manual score: $total / 30   (K1: $k1_score/10   K2: $k2_score/15   V1: $v1_score/5)"
    if [ "$v1_score" -eq 0 ]; then
        echo "  ⚠️  VISUAL GATE FAILED (V1=0) — the summary CANNOT be approved"
        echo "      until the visual issue is fixed and V1 re-confirmed."
    fi
    echo "  Saved to: $OUT_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Re-run grade.sh to see the updated Human + Overall Grade."
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
    echo "[manual-checklist] Validated $INPUT_FILE — recomputing scores from answers."
    write_json
    exit 0
fi

# --- Mode: non-interactive (answers supplied via flags) ---
if [ -n "$K1_ANS" ] && [ -n "$K2_ANS" ] && [ -n "$V1_ANS" ] && [ "$FORCE_INTERACTIVE" -eq 0 ]; then
    echo "[manual-checklist] Non-interactive mode — scoring supplied answers."
    write_json
    exit 0
fi

# --- Mode: interactive ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  /aid-summarize — Manual Review Checklist (interactive)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ -n "$HTML_FILE" ] && echo "  File: $HTML_FILE"
echo "  Scores K1 (10) + K2 (15) + V1 visual gate (5) = 30 pts."
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
ask_ypn "     K1 score" K1_ANS
echo ""

echo "Q3. K2 — Fact accuracy"
echo "     Spot-check 5 numeric/named facts against the source KB."
echo "     (Tip: run spot-check-facts.sh first for a prepared list.)"
echo "     (y = all verified; p = 1-2 minor discrepancies; n = errors found)"
ask_ypn "     K2 score" K2_ANS
echo ""

echo "Q4. V1 — HUMAN VISUAL GATE (mandatory, 5 pts)"
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
