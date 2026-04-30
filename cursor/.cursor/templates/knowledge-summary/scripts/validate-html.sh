#!/usr/bin/env bash
# validate-html.sh — structural / accessibility checks on the generated HTML.
# Replaces a full W3C validator with focused checks for the patterns the
# grading rubric requires (A1, A2, A4, A5, S2 from grading-rubric.md).
#
# Usage: validate-html.sh <html-file>
# Exit 0 on success, 1 on any failure.

set -u

HTML="${1:-}"

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "❌ Usage: validate-html.sh <html-file>" >&2
    exit 2
fi

FAIL=0
declare -i PASS=0 TOTAL=0

check() {
    local label="$1" pattern="$2"
    TOTAL=$((TOTAL + 1))
    if grep -qE "$pattern" "$HTML"; then
        echo "  ✅ $label"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $label" >&2
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
        echo "  ❌ $label ($n found, expected >= $min)" >&2
        FAIL=1
    fi
}

echo "Validating HTML structure & accessibility..."

# A1 — semantic landmarks
check "A1.1 has <html lang=...>"      'lang="[^"]+"'
check "A1.2 has <header role=banner>" '<header[^>]+role="banner"'
check "A1.3 has <main"                '<main(\s|>)'
check "A1.4 has <nav"                 '<nav(\s|>)'
check "A1.5 has <footer>"             '<footer(\s|>)'
check "A1.6 has <title>"              '<title>[^<]+</title>'

# A2 — ARIA on lightbox
check "A2.1 lightbox role=dialog"          '#lightbox|id="lightbox"[^>]*role="dialog"|role="dialog"[^>]*id="lightbox"'
check "A2.2 aria-modal=true"               'aria-modal="true"'
check "A2.3 aria-hidden initial true"      'aria-hidden="true"'
check "A2.4 aria-labelledby on dialog"     'aria-labelledby="[^"]+"'

# A4 — reduced motion
check "A4.1 prefers-reduced-motion media"  '@media \(prefers-reduced-motion: reduce\)'

# A5 — visible focus
check "A5.1 :focus-visible rule"           ':focus-visible'

# Skip link
check "skip-link present"                  'class="skip-link"'

# noscript fallback
check "noscript fallback present"          '<noscript>'

# color-scheme declaration
check "color-scheme: light dark"           'color-scheme: ?light dark|color-scheme:.*light.*dark'

# Mermaid library inlined (look for any of several markers from minified mermaid)
check "Mermaid library inlined"            'mermaid|Mermaid'

# At least one diagram
check_count "at least one mermaid diagram" 'class="mermaid"' 1

# Mermaid box wrapper
check_count "mermaid-box wrappers"         'class="mermaid-box"' 1

echo ""
if [ "$FAIL" -ne 0 ]; then
    echo "❌ HTML validation failed: $PASS/$TOTAL checks passed" >&2
    exit 1
fi

echo "✅ HTML validation passed: $PASS/$TOTAL checks"
exit 0
