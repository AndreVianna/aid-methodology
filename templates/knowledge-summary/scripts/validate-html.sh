#!/usr/bin/env bash
# validate-html.sh — structural / accessibility / validity checks on the generated HTML.
#
# Usage:
#   validate-html.sh <html-file>
#
# Flags:
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
#   S2  Offline render — Mermaid library inlined.
#   (Additional structural checks for skip-link, noscript, color-scheme, etc.)

set -euo pipefail

# --- Argument parsing ---
HTML=""
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -20
            exit 0
            ;;
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
    echo "❌ Usage: validate-html.sh <html-file>" >&2
    exit 2
fi

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
            HV_EXIT=$?
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

        # Emit the "fallback" note regardless so grade.sh can detect the mode
        echo "  H1: regex fallback (tidy/html-validate not installed)"
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

# S2 — Mermaid library inlined
check "S2. Mermaid library inlined"   'mermaid|Mermaid'

# Diagram counts
check_count "at least one mermaid diagram"  'class="mermaid"'     1
check_count "mermaid-box wrappers"          'class="mermaid-box"' 1

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [ "$FAIL" -ne 0 ]; then
    echo "❌ HTML validation failed: $PASS/$TOTAL checks passed"
    exit 1
fi

echo "✅ HTML validation passed: $PASS/$TOTAL checks"
exit 0
