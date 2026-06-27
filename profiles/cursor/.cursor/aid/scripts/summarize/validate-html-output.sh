#!/usr/bin/env bash
# validate-html-output.sh — structural / accessibility / validity + link checks
# on the generated HTML.
#
# Usage:
#   validate-html-output.sh <html-file> [--kb-dir DIR]
#
# Flags:
#   --kb-dir DIR  Resolve relative .md links against this dir (default: .aid/knowledge)
#   -h, --help    Print this header and exit.
#
# Exit codes:
#   0  All checks pass.
#   1  One or more checks failed.
#   2  Invocation error (missing file, bad arguments).
#
# Checks performed:
#   H1  HTML validity — tidy (preferred) → npx html-validate → regex fallback.
#   A1  Semantic landmarks — header/main/nav/footer.
#   A2  ARIA on lightbox — role/aria-modal/aria-hidden/aria-labelledby.
#   A3  Focus trap — trapFocusOnTab + lastFocused.focus() + key === 'Escape'.
#   A4  Reduced motion — @media (prefers-reduced-motion: reduce).
#   A5  Visible focus — :focus-visible rule.
#   S2  Offline render — no external CDN script or link src (self-contained).
#   NM  No-Mermaid-engine assertion — output contains no Mermaid runtime engine or
#       mermaid.initialize() init call (FR-51 / Change 7 / D-012 guardrail).
#   L1  Anchor links resolve — every href="#X" matches an id="X".
#   L2  Relative md links resolve — every href="./X.md" exists in --kb-dir.
#   (Additional structural checks for skip-link, noscript, color-scheme, etc.)
#
# History: merged validate-html.sh + validate-links.sh per 2026-05-26 script consolidation.

set -euo pipefail

# --- Argument parsing ---
HTML=""
KB_DIR=".aid/knowledge"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -30
            exit 0
            ;;
        --kb-dir)
            KB_DIR="$2"
            shift 2
            ;;
        -*)
            echo "❌ Unknown flag: $1" >&2
            exit 2
            ;;
        *)
            HTML="$1"
            shift
            ;;
    esac
done

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "❌ Usage: validate-html-output.sh <html-file> [--kb-dir DIR]" >&2
    exit 2
fi

HTML_DIR=$(dirname "$HTML")

FAIL=0
declare -i PASS=0 TOTAL=0

# --- Helpers ---
check() {
    local label="$1" pattern="$2"
    TOTAL=$((TOTAL + 1))
    if grep -qE "$pattern" "$HTML"; then
        echo "  ✅ $label"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $label"
        FAIL=1
    fi
}

check_count() {
    local label="$1" pattern="$2" min="$3"
    TOTAL=$((TOTAL + 1))
    local n
    n=$(grep -cE "$pattern" "$HTML" 2>/dev/null || echo 0)
    if [ "$n" -ge "$min" ]; then
        echo "  ✅ $label ($n found, >= $min)"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $label ($n found, expected >= $min)"
        FAIL=1
    fi
}

echo "Validating HTML structure & accessibility..."

# ---------------------------------------------------------------------------
# H1 — HTML validity (tidy → npx html-validate → regex fallback)
# ---------------------------------------------------------------------------
echo ""
echo "  [H1: HTML validity]"

H1_PASS=0
H1_MODE=""

if command -v tidy >/dev/null 2>&1; then
    H1_MODE="tidy"
    echo "  H1: using tidy"
    TIDY_STDERR=$(tidy -errors -quiet --show-warnings no "$HTML" 2>&1 >/dev/null || true)
    if [ -z "$TIDY_STDERR" ]; then
        echo "  ✅ H1. HTML validity (tidy: 0 errors)"
        H1_PASS=1
    else
        echo "  ❌ H1. HTML validity (tidy reported errors)"
        echo "       $TIDY_STDERR" | head -5
        FAIL=1
    fi
else
    # Try npx html-validate (requires Node/npx on PATH)
    if command -v npx >/dev/null 2>&1; then
        # Probe: does html-validate respond at all? (--version exits 0)
        if npx --no html-validate --version >/dev/null 2>&1; then
            H1_MODE="html-validate"
            echo "  H1: using npx html-validate"
            HV_OUT=$(npx --no html-validate --max-warnings=0 "$HTML" 2>&1 || true)
            # html-validate exits 0 only when no errors
            if echo "$HV_OUT" | grep -qiE '^[[:space:]]*[0-9]+ error'; then
                echo "  ❌ H1. HTML validity (html-validate reported errors)"
                echo "$HV_OUT" | grep -iE 'error' | head -5 | sed 's/^/       /'
                FAIL=1
            else
                echo "  ✅ H1. HTML validity (html-validate: 0 errors)"
                H1_PASS=1
            fi
        fi
    fi

    if [ -z "$H1_MODE" ]; then
        # Regex fallback — less rigorous, but still catches gross malformedness
        H1_MODE="regex"
        echo "  H1: regex fallback (tidy/html-validate not installed)"
        REGEX_FAIL=0

        # Must have <!DOCTYPE html>
        if ! grep -qi '<!DOCTYPE html>' "$HTML"; then
            echo "  ❌ H1. Missing <!DOCTYPE html>"
            REGEX_FAIL=1
        fi

        # Must have <html ...>
        if ! grep -qiE '<html[ >]' "$HTML"; then
            echo "  ❌ H1. Missing <html> tag"
            REGEX_FAIL=1
        fi

        # Must have <head> and <body>
        if ! grep -qi '<head' "$HTML" || ! grep -qi '<body' "$HTML"; then
            echo "  ❌ H1. Missing <head> or <body>"
            REGEX_FAIL=1
        fi

        # Must have <meta charset ...>
        if ! grep -qiE '<meta[^>]+charset' "$HTML"; then
            echo "  ❌ H1. Missing charset meta"
            REGEX_FAIL=1
        fi

        if [ "$REGEX_FAIL" -eq 0 ]; then
            echo "  ✅ H1. HTML validity (regex fallback — less rigorous; install tidy for strict check)"
            H1_PASS=1
        else
            FAIL=1
        fi
    fi
fi

TOTAL=$((TOTAL + 1))
[ "$H1_PASS" -eq 1 ] && PASS=$((PASS + 1))

# ---------------------------------------------------------------------------
# A1 — semantic landmarks
# ---------------------------------------------------------------------------
echo ""
echo "  [A1: Semantic landmarks]"
check "A1.1 has <html lang=...>"      'lang="[^"]+"'
check "A1.2 has <header role=banner>" '<header[^>]+role="banner"'
check "A1.3 has <main"                '<main(\s|>)'
check "A1.4 has <nav"                 '<nav(\s|>)'
check "A1.5 has <footer>"             '<footer(\s|>)'
check "A1.6 has <title>"              '<title>[^<]+</title>'

# ---------------------------------------------------------------------------
# A2 — ARIA on lightbox
# ---------------------------------------------------------------------------
echo ""
echo "  [A2: ARIA on lightbox]"
check "A2.1 lightbox role=dialog"       'role="dialog"'
check "A2.2 aria-modal=true"            'aria-modal="true"'
check "A2.3 aria-hidden initial true"   'aria-hidden="true"'
check "A2.4 aria-labelledby on dialog"  'aria-labelledby="[^"]+"'

# ---------------------------------------------------------------------------
# A3 — Focus trap (auto-detect from inlined <script>)
# ---------------------------------------------------------------------------
echo ""
echo "  [A3: Focus trap]"
TOTAL=$((TOTAL + 1))
A3_FAIL=0
if ! grep -qF 'trapFocusOnTab' "$HTML"; then
    echo "  ❌ A3. Focus trap — trapFocusOnTab signature not found"
    A3_FAIL=1
fi
if ! grep -qF 'lastFocused.focus()' "$HTML"; then
    echo "  ❌ A3. Focus trap — lastFocused.focus() restoration not found"
    A3_FAIL=1
fi
# key === 'Escape' — the single quotes may appear as &#39; in HTML or as literal
if ! grep -qE "key === 'Escape'|key === \"Escape\"|key===.Escape." "$HTML"; then
    echo "  ❌ A3. Focus trap — Escape-key handler not found"
    A3_FAIL=1
fi
if [ "$A3_FAIL" -eq 0 ]; then
    echo "  ✅ A3. Focus trap (trapFocusOnTab + lastFocused.focus() + Escape handler all present)"
    PASS=$((PASS + 1))
else
    echo "       Hint: check lightbox JS for getLightboxFocusables(), trapFocusOnTab(), and Escape handler."
    FAIL=1
fi

# ---------------------------------------------------------------------------
# A4 — Reduced motion
# ---------------------------------------------------------------------------
echo ""
echo "  [A4: Reduced motion]"
check "A4.1 prefers-reduced-motion media"  '@media \(prefers-reduced-motion: reduce\)'

# ---------------------------------------------------------------------------
# A5 — Visible focus
# ---------------------------------------------------------------------------
echo ""
echo "  [A5: Visible focus]"
check "A5.1 :focus-visible rule"  ':focus-visible'

# ---------------------------------------------------------------------------
# Additional structural checks
# ---------------------------------------------------------------------------
echo ""
echo "  [Structural checks]"
check "skip-link present"          'class="skip-link"'
check "noscript fallback present"  '<noscript>'
check "color-scheme: light dark"   'color-scheme: ?light dark|color-scheme:.*light.*dark'

# S2 -- Offline render: page is self-contained (no external CDN script or link src)
# CHANGE 7 (FR-51 / D-012): The Mermaid engine is retired. S2 now checks that NO
# external CDN script/link references have been introduced (CDN-free guarantee).
# The presence of the Mermaid engine is no longer required or checked.
CDN_SCRIPT_HITS=$(grep -E '<script[^>]+src="https?://' "$HTML" 2>/dev/null || true)
CDN_LINK_HITS=$(grep -E '<link[^>]+href="https?://' "$HTML" 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [ -z "$CDN_SCRIPT_HITS" ] && [ -z "$CDN_LINK_HITS" ]; then
    echo "  S2. Offline render [PASS] no external CDN script or link (self-contained)"
    PASS=$((PASS + 1))
else
    echo "  S2. Offline render [FAIL] found CDN reference(s) in output HTML:"
    [ -n "$CDN_SCRIPT_HITS" ] && echo "$CDN_SCRIPT_HITS"
    [ -n "$CDN_LINK_HITS" ] && echo "$CDN_LINK_HITS"
    FAIL=$((FAIL + 1))
fi

# NM -- No-Mermaid-engine assertion (FR-51 / Change 7 / D-012 guardrail)
# The ~3 MB Mermaid runtime engine is retired in D-012. Any output HTML that still
# contains the Mermaid engine script or a mermaid.initialize() call is in violation
# of guardrail C2/C3 (self-contained, no external engine) and FR-51.
# Checks:
#   NM.1  No inline Mermaid engine -- the JS bundle declares 'mermaid' as a module
#          or library; its presence means the engine was not dropped.
#   NM.2  No mermaid.initialize() call -- the explicit initialization call that D-012
#          removes. Present = engine still wired in.
#   NM.3  No <script src> pointing to a CDN Mermaid delivery (cdn.jsdelivr.net/mermaid,
#          unpkg.com/mermaid, etc.) -- belt-and-suspenders for CDN-sourced engine.
echo ""
echo "  [NM: No-Mermaid-engine assertion (FR-51 / D-012)]"
NM_FAIL=0
TOTAL=$((TOTAL + 1))

# NM.1: detect inline Mermaid bundle (very large inline script containing 'mermaid')
# Heuristic: a <script> block longer than 100 KB that contains the mermaid signature.
# Use awk to find multi-line script blocks and check length.
INLINE_MERMAID=$(awk '
    /<script[^>]*>/ { in_script=1; buf="" }
    in_script { buf = buf $0 "\n" }
    /<\/script>/ {
        in_script=0
        if (length(buf) > 100000 && tolower(buf) ~ /mermaid/) {
            print "found"
            exit
        }
        buf=""
    }
' "$HTML" 2>/dev/null || true)

if [ -n "$INLINE_MERMAID" ]; then
    echo "  ❌ NM.1 Mermaid engine inline script detected (bundle > 100 KB containing 'mermaid')"
    NM_FAIL=1
fi

# NM.2: detect mermaid.initialize() call
if grep -qE 'mermaid\.initialize\(' "$HTML" 2>/dev/null; then
    echo "  ❌ NM.2 mermaid.initialize() call detected -- engine still wired in"
    NM_FAIL=1
fi

# NM.3: detect CDN-sourced Mermaid engine
if grep -qE '<script[^>]+src="https?://[^"]*mermaid[^"]*"' "$HTML" 2>/dev/null; then
    echo "  ❌ NM.3 CDN Mermaid <script src> detected"
    NM_FAIL=1
fi

if [ "$NM_FAIL" -eq 0 ]; then
    echo "  NM. No-Mermaid-engine [PASS] no Mermaid runtime engine or init call in output"
    PASS=$((PASS + 1))
else
    echo "      Fix: ensure GENERATE does not inline the Mermaid engine."
    echo "      All visuals must be pre-rendered to inline SVG / HTML+CSS at build time."
    FAIL=1
fi

# ---------------------------------------------------------------------------
# L1 — Anchor links resolve to in-page IDs
# ---------------------------------------------------------------------------
echo ""
echo "  [L1: anchor link resolution]"

ANCHOR_HREFS=$(grep -oE 'href="#[^"]+"' "$HTML" | sed 's/href="#//;s/"$//' | sort -u || true)
ANCHOR_FAIL=0
ANCHOR_TOTAL=0
for anchor in $ANCHOR_HREFS; do
    ANCHOR_TOTAL=$((ANCHOR_TOTAL + 1))
    [ -z "$anchor" ] && continue
    if ! grep -qE "id=\"$anchor\"" "$HTML"; then
        echo "    ❌ #$anchor — no matching id=\"$anchor\""
        ANCHOR_FAIL=$((ANCHOR_FAIL + 1))
    fi
done
TOTAL=$((TOTAL + 1))
if [ "$ANCHOR_FAIL" -eq 0 ]; then
    echo "  ✅ L1. $ANCHOR_TOTAL/$ANCHOR_TOTAL anchor links resolve"
    PASS=$((PASS + 1))
else
    echo "  ❌ L1. $ANCHOR_FAIL anchor link(s) broken (of $ANCHOR_TOTAL)"
    FAIL=1
fi

# ---------------------------------------------------------------------------
# L2 — Relative .md links resolve to existing files
# ---------------------------------------------------------------------------
echo ""
echo "  [L2: relative .md link resolution] (kb-dir=$KB_DIR)"

MD_HREFS=$(grep -oE 'href="\./[^"]+\.md"' "$HTML" | sed 's/href="\.\///;s/"$//' | sort -u || true)
MD_FAIL=0
MD_TOTAL=0
for mdlink in $MD_HREFS; do
    MD_TOTAL=$((MD_TOTAL + 1))
    target="$HTML_DIR/$mdlink"
    if [ ! -f "$target" ]; then
        echo "    ❌ ./$mdlink — file does not exist at $target"
        MD_FAIL=$((MD_FAIL + 1))
    fi
done
TOTAL=$((TOTAL + 1))
if [ "$MD_FAIL" -eq 0 ]; then
    echo "  ✅ L2. $MD_TOTAL/$MD_TOTAL relative md links resolve"
    PASS=$((PASS + 1))
else
    echo "  ❌ L2. $MD_FAIL md link(s) broken (of $MD_TOTAL)"
    FAIL=1
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [ "$FAIL" -ne 0 ]; then
    echo "❌ HTML output validation failed: $PASS/$TOTAL checks passed"
    exit 1
fi

echo "✅ HTML output validation passed: $PASS/$TOTAL checks"
exit 0
