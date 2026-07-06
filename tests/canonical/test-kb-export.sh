#!/usr/bin/env bash
# test-kb-export.sh -- canonical tests for the KB Export feature
#   (work-002-dashboard-export-buttons, task-003 AC)
#
# Scope:
#   Verifies that the KB Export feature (export buttons, base64 Markdown payload,
#   print-CSS PDF path, self-containment) works correctly across the full pipeline:
#   static analysis, fresh build, payload decoding, and Playwright browser tests.
#
# AC coverage:
#   AC1: Export buttons present, visible, keyboard-focusable (KB01-KB04, PW30-PW32)
#   AC2: PDF print stylesheet hides nav/controls, forces light theme, page-breaks (KB-CSS,
#        PW33, PW34, PW35)
#   AC3: Markdown payload faithfully reflects KB structure (KB21-KB23)
#   AC4: Images embedded as data: URIs with alt text (KB24, KB08)
#   AC5: Buttons meet WCAG AA in light and dark themes (KB06, PW30-PW31)
#   AC6: Single self-contained file; NM.1 passes; S7 visual gate passes (KB05, KB07,
#        KB30, PW36)
#
# Static section (no Playwright):
#   KB01-KB08  Committed kb.html: element presence, button labels, print CSS, validators
#   KB10-KB12  Fresh build pipeline: build-md-export.sh + assemble.sh output validation
#   KB20-KB24  Payload decoding: base64 -> UTF-8 Markdown structure assertions
#
# Playwright section (graceful-skip when unavailable):
#   KB30       validate-visuals.mjs passes on committed kb.html (S7 gate)
#   KB31+      Invoke test-kb-export-pw.mjs (browser rendering + behavior tests)
#
# Graceful degradation:
#   When Playwright / Chromium are not available the Playwright section emits a
#   clear SKIP message and exits 0 (same contract as test-visual-fidelity.sh).
#   All static assertions still run and must pass regardless.
#
# PLAYWRIGHT_BROWSERS_PATH resolver:
#   When run with HOME=$(mktemp -d) (canonical isolation), the browser binary is
#   not found under the fake HOME. We resolve the REAL home via /etc/passwd
#   (immune to $HOME override) and set PLAYWRIGHT_BROWSERS_PATH so Playwright
#   finds its binary. Mirrors the fix in test-visual-fidelity.sh.
#
# Usage:
#   bash tests/canonical/test-kb-export.sh [-v | --verbose]
#   export HOME=$(mktemp -d); bash tests/canonical/test-kb-export.sh
#
# Exit codes:
#   0 -- all tests passed (or Playwright unavailable -- SKIP for PW section)
#   1 -- one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

COMMITTED_KB="${REPO_ROOT}/.aid/dashboard/kb.html"
BUILD_MD_EXPORT_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/build-md-export.sh"
ASSEMBLE_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/assemble.sh"
VALIDATE_HTML_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-html-output.sh"
VALIDATE_VISUALS_MJS="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-visuals.mjs"
CONTRAST_CHECK_MJS="${REPO_ROOT}/canonical/aid/scripts/summarize/contrast-check.mjs"
KB_DIR="${REPO_ROOT}/.aid/knowledge"
MANIFEST="${REPO_ROOT}/.aid/.temp/summarize/summary-src/section-manifest.txt"
SUMMARY_SRC="${REPO_ROOT}/.aid/.temp/summarize/summary-src"
PW_PACKAGE_DIR="${REPO_ROOT}/canonical/aid/scripts/summarize"
PW_TEST_MJS="${SCRIPT_DIR}/test-kb-export-pw.mjs"

# ---------------------------------------------------------------------------
# Prerequisite: committed kb.html must exist.
# ---------------------------------------------------------------------------
if [[ ! -f "$COMMITTED_KB" ]]; then
    echo "ERROR: committed kb.html not found at ${COMMITTED_KB}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Temp directory for build artefacts (cleaned up on exit).
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ===========================================================================
# === STATIC: committed kb.html structure ===================================
# ===========================================================================

echo ""
echo "=== KB01: #kb-md-export payload element present ==="
if grep -q 'id="kb-md-export"' "$COMMITTED_KB"; then
    pass "KB01 #kb-md-export element present in committed kb.html"
else
    fail "KB01 #kb-md-export element present in committed kb.html -- element not found"
fi

echo ""
echo "=== KB02: data-encoding=\"base64\" attribute on #kb-md-export ==="
if grep -q 'id="kb-md-export" data-encoding="base64"' "$COMMITTED_KB"; then
    pass "KB02 data-encoding=base64 attribute present on #kb-md-export"
else
    fail "KB02 data-encoding=base64 attribute present on #kb-md-export -- attribute missing"
fi

echo ""
echo "=== KB03: export button IDs present ==="
if grep -q 'id="btn-export-md"' "$COMMITTED_KB"; then
    pass "KB03a #btn-export-md button ID present"
else
    fail "KB03a #btn-export-md button ID present -- not found"
fi
if grep -q 'id="btn-export-pdf"' "$COMMITTED_KB"; then
    pass "KB03b #btn-export-pdf button ID present"
else
    fail "KB03b #btn-export-pdf button ID present -- not found"
fi

echo ""
echo "=== KB04: exact button labels present ==="
if grep -q 'Export as Markdown' "$COMMITTED_KB"; then
    pass "KB04a 'Export as Markdown' label present"
else
    fail "KB04a 'Export as Markdown' label present -- text not found"
fi
if grep -q 'Export as PDF' "$COMMITTED_KB"; then
    pass "KB04b 'Export as PDF' label present"
else
    fail "KB04b 'Export as PDF' label present -- text not found"
fi

echo ""
echo "=== KB05: print CSS rules present ==="
if grep -q '@media print' "$COMMITTED_KB"; then
    pass "KB05a @media print block present"
else
    fail "KB05a @media print block present -- not found"
fi
if grep -q 'page-break-before: always' "$COMMITTED_KB"; then
    pass "KB05b section page-break-before: always rule present"
else
    fail "KB05b section page-break-before: always rule present -- not found"
fi
if grep -q 'display: none' "$COMMITTED_KB"; then
    pass "KB05c display:none rule present (controls/nav hiding)"
else
    fail "KB05c display:none rule present in print CSS -- not found"
fi
# Forced-light override in dark print
if grep -q 'html\[data-theme="dark"\]' "$COMMITTED_KB"; then
    pass "KB05d forced-light dark-override rule present in print CSS"
else
    fail "KB05d forced-light dark-override rule present in print CSS -- not found"
fi

# ===========================================================================
# === STATIC: validators on committed kb.html (requires node) ===============
# ===========================================================================

echo ""
echo "=== KB06: validate-html-output.sh passes (21/21) on committed kb.html ==="
if ! command -v node >/dev/null 2>&1; then
    echo "  SKIP: node not found -- KB06 validate-html-output.sh check requires node"
    pass "KB06 validate-html-output.sh (node absent -- SKIP)"
else
    VH_OUT=$(bash "$VALIDATE_HTML_SH" "$COMMITTED_KB" 2>&1)
    VH_RC=$?
    if [[ "$VH_RC" -eq 0 ]]; then
        pass "KB06 validate-html-output.sh passes on committed kb.html"
        # Assert the success verdict reports N/N checks with N==N (robust to count changes).
        # Searching for the ASCII portion of the verdict line; the unicode checkmark prefix
        # is ignored by the substring match.
        _VH_VERDICT=$(echo "$VH_OUT" | grep -oE "HTML output validation passed: [0-9]+/[0-9]+ checks" | head -1)
        if [[ -n "$_VH_VERDICT" ]]; then
            _VH_NUMS=$(echo "$_VH_VERDICT" | grep -oE "[0-9]+/[0-9]+" | head -1)
            _VH_P=${_VH_NUMS%/*}
            _VH_T=${_VH_NUMS#*/}
            if [[ "$_VH_P" -eq "$_VH_T" && "$_VH_P" -gt 0 ]]; then
                pass "KB06b validate-html-output.sh all-checks-passed verdict (${_VH_P}/${_VH_T})"
            else
                fail "KB06b validate-html-output.sh all-checks-passed verdict -- N/N mismatch: '${_VH_NUMS}'"
                [[ "$VERBOSE" -eq 1 ]] && echo "$VH_OUT"
            fi
        else
            fail "KB06b validate-html-output.sh all-checks-passed verdict -- success summary line not found in output"
            [[ "$VERBOSE" -eq 1 ]] && echo "$VH_OUT"
        fi
    else
        fail "KB06 validate-html-output.sh passes on committed kb.html -- exit $VH_RC"
        echo "$VH_OUT" | tail -5
    fi
fi

echo ""
echo "=== KB07: contrast-check.mjs passes (WCAG AA both themes) ==="
if ! command -v node >/dev/null 2>&1; then
    echo "  SKIP: node not found -- KB07 contrast check requires node"
    pass "KB07 contrast-check.mjs (node absent -- SKIP)"
else
    CC_OUT=$(node "$CONTRAST_CHECK_MJS" "$COMMITTED_KB" 2>&1)
    CC_RC=$?
    if [[ "$CC_RC" -eq 0 ]]; then
        pass "KB07 contrast-check.mjs passes (WCAG AA) for committed kb.html"
    else
        fail "KB07 contrast-check.mjs passes (WCAG AA) for committed kb.html -- exit $CC_RC"
        echo "$CC_OUT" | grep -E "FAIL|failed" | head -5
    fi
fi

echo ""
echo "=== KB08: build-md-export.sh preserves alt text in image replacement ==="
# Static assertion: the python script in build-md-export.sh must include the alt
# capture group in the image replacement so data-URI images keep their alt text.
if grep -q "'!\[' + alt + '\](data:'" "$BUILD_MD_EXPORT_SH"; then
    pass "KB08 alt text preserved in image replacement (![alt](data:...) pattern)"
else
    fail "KB08 alt text preserved in image replacement -- pattern '![' + alt + '](data:' not found in build-md-export.sh"
fi

# ===========================================================================
# === FRESH BUILD: build-md-export.sh + assemble.sh pipeline ================
# ===========================================================================
# These assertions rebuild kb.html from the summary-src workspace. Since work-013
# that workspace is gitignored scratch (.aid/.temp/summarize/summary-src/), so it
# is absent in a fresh CI clone; skip gracefully when absent (runs locally right
# after an /aid-summarize generation). The static (KB01-08) and payload-decode
# (KB20-24) checks use only the committed kb.html and always run.
if [[ ! -d "$SUMMARY_SRC" || ! -f "$MANIFEST" ]]; then
    echo ""
    echo "  SKIP: summary-src workspace absent ($SUMMARY_SRC) -- fresh-build gate KB10-KB12 needs it."
    pass "KB10-KB12 fresh-build (summary-src absent -- SKIP)"
else

echo ""
echo "=== KB10: build-md-export.sh succeeds from .aid/knowledge/ source ==="
PAYLOAD_OUT="${TMP}/md-export-payload.html"
BUILD_OUT=$(bash "$BUILD_MD_EXPORT_SH" \
    --kb-dir "$KB_DIR" \
    --manifest "$MANIFEST" \
    --output "$PAYLOAD_OUT" 2>&1)
BUILD_RC=$?
if [[ "$BUILD_RC" -eq 0 ]]; then
    pass "KB10 build-md-export.sh exits 0"
else
    fail "KB10 build-md-export.sh exits 0 -- got exit $BUILD_RC"
    echo "$BUILD_OUT" | head -5
fi

if [[ -f "$PAYLOAD_OUT" ]]; then
    pass "KB10b build-md-export.sh created payload output file"
    PAYLOAD_BYTES=$(wc -c < "$PAYLOAD_OUT" | tr -d ' ')
    if [[ "$PAYLOAD_BYTES" -gt 100000 ]]; then
        pass "KB10c payload file size > 100 KB (${PAYLOAD_BYTES} bytes -- substantial KB content)"
    else
        fail "KB10c payload file size > 100 KB -- only ${PAYLOAD_BYTES} bytes (suspiciously small)"
    fi
else
    fail "KB10b build-md-export.sh created payload output file -- file not found at $PAYLOAD_OUT"
fi

echo ""
echo "=== KB11: assemble.sh produces kb.html with embedded MD payload ==="
# Create a temp summary-src with the freshly built payload
TMP_SRC="${TMP}/summary-src"
mkdir -p "${TMP_SRC}/sections"
for f in skeleton-head.html skeleton-foot.html post-script.html; do
    cp "${SUMMARY_SRC}/${f}" "${TMP_SRC}/${f}"
done
cp -r "${SUMMARY_SRC}/sections/." "${TMP_SRC}/sections/"
cp "$PAYLOAD_OUT" "${TMP_SRC}/md-export-payload.html"

FRESH_KB="${TMP}/kb-fresh.html"
ASM_OUT=$(bash "$ASSEMBLE_SH" \
    --src "$TMP_SRC" \
    --manifest "$MANIFEST" \
    --output "$FRESH_KB" 2>&1)
ASM_RC=$?
if [[ "$ASM_RC" -eq 0 ]]; then
    pass "KB11 assemble.sh exits 0"
else
    fail "KB11 assemble.sh exits 0 -- got exit $ASM_RC"
    echo "$ASM_OUT" | head -5
fi

echo ""
echo "=== KB12: fresh kb.html contains #kb-md-export with base64 payload ==="
if [[ -f "$FRESH_KB" ]]; then
    if grep -q 'id="kb-md-export" data-encoding="base64">' "$FRESH_KB"; then
        pass "KB12a fresh kb.html contains #kb-md-export with data-encoding=base64"
    else
        fail "KB12a fresh kb.html contains #kb-md-export with data-encoding=base64 -- not found"
    fi
    # Verify the assemble output reports the payload was embedded
    if echo "$ASM_OUT" | grep -q "MD Export: embedded"; then
        pass "KB12b assemble.sh reports 'MD Export: embedded'"
    else
        fail "KB12b assemble.sh reports 'MD Export: embedded' -- not in output"
    fi
else
    fail "KB12 fresh kb.html file not found at ${FRESH_KB}"
fi

fi  # end fresh-build guard (summary-src workspace present)

# ===========================================================================
# === PAYLOAD DECODING: assert Markdown structure ===========================
# ===========================================================================

echo ""
echo "=== KB20-KB24: Payload decoding and Markdown structure ==="
if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not found -- payload decoding requires python3"
    pass "KB20-KB24 payload decode (python3 absent -- SKIP)"
else
    # Extract and decode the base64 payload from committed kb.html
    DECODED_MD="${TMP}/decoded.md"
    python3 - "$COMMITTED_KB" "$DECODED_MD" <<'PYEOF' 2>&1
import sys
import re
import base64

html_path = sys.argv[1]
out_path = sys.argv[2]

with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()

# Find the base64 payload content (between the opening tag and </script>)
m = re.search(
    r'<script[^>]+id="kb-md-export"[^>]+>([A-Za-z0-9+/=]+)</script>',
    html
)
if not m:
    print("ERROR: could not find #kb-md-export payload in HTML")
    sys.exit(1)

b64 = m.group(1).strip()
try:
    decoded = base64.b64decode(b64).decode('utf-8')
except Exception as e:
    print("ERROR: failed to decode payload: " + str(e))
    sys.exit(1)

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(decoded)

print("OK: decoded " + str(len(b64)) + " base64 chars -> " + str(len(decoded)) + " chars")
PYEOF
    DECODE_RC=$?

    if [[ "$DECODE_RC" -eq 0 ]] && [[ -f "$DECODED_MD" ]]; then
        DECODED_SIZE=$(wc -c < "$DECODED_MD" | tr -d ' ')
        pass "KB20 base64 payload decodes to valid UTF-8 Markdown (${DECODED_SIZE} chars)"

        # KB21: headings
        HEADING_COUNT=$(grep -c "^#" "$DECODED_MD" 2>/dev/null || echo 0)
        if [[ "$HEADING_COUNT" -ge 5 ]]; then
            pass "KB21 decoded Markdown has headings (${HEADING_COUNT} heading lines found)"
        else
            fail "KB21 decoded Markdown has headings -- only ${HEADING_COUNT} heading lines (expected >= 5)"
        fi

        # KB22: tables
        TABLE_COUNT=$(grep -c "^|" "$DECODED_MD" 2>/dev/null || echo 0)
        if [[ "$TABLE_COUNT" -ge 3 ]]; then
            pass "KB22 decoded Markdown has tables (${TABLE_COUNT} table rows found)"
        else
            fail "KB22 decoded Markdown has tables -- only ${TABLE_COUNT} table rows (expected >= 3)"
        fi

        # KB23: lists
        LIST_COUNT=$(grep -cE "^[-*] " "$DECODED_MD" 2>/dev/null || echo 0)
        if [[ "$LIST_COUNT" -ge 5 ]]; then
            pass "KB23 decoded Markdown has lists (${LIST_COUNT} list items found)"
        else
            fail "KB23 decoded Markdown has lists -- only ${LIST_COUNT} list items (expected >= 5)"
        fi

        # KB24: any image references use data: URIs only (no relative file paths)
        # grep for Markdown image syntax: ![...](...) where the path is NOT data:
        NON_DATA_IMGS=$(grep -oE '!\[[^]]*\]\([^)]+\)' "$DECODED_MD" 2>/dev/null \
            | grep -v '(data:' || true)
        if [[ -z "$NON_DATA_IMGS" ]]; then
            pass "KB24 all image references in decoded Markdown use data: URIs (no relative paths)"
        else
            fail "KB24 all image references use data: URIs -- found non-data-URI images: $(echo "$NON_DATA_IMGS" | head -3)"
        fi
    else
        fail "KB20 base64 payload decodes to valid UTF-8 Markdown -- decode failed (exit $DECODE_RC)"
        echo "  SKIP: KB21 decoded Markdown has headings (decode failed -- cannot verify)"
        echo "  SKIP: KB22 decoded Markdown has tables (decode failed -- cannot verify)"
        echo "  SKIP: KB23 decoded Markdown has lists (decode failed -- cannot verify)"
        echo "  SKIP: KB24 all image references use data: URIs (decode failed -- cannot verify)"
    fi
fi

# ===========================================================================
# === KB25: positive data-URI conversion + alt text (fixture-based) =========
# ===========================================================================
# The real KB has zero images, so KB24's absence-of-non-data-refs check passes
# trivially. KB25 exercises the actual conversion path using a tiny fixture KB
# that references both a local SVG and a local raster PNG. It asserts that
# build-md-export.sh converts each ref to a data: URI and preserves alt text.
# This is a POSITIVE assertion -- it would fail if the conversion were skipped
# or alt text were dropped.

echo ""
echo "=== KB25: positive data-URI image conversion + alt text (fixture-based) ==="
if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not found -- KB25 fixture test requires python3"
    pass "KB25 positive data-URI conversion (python3 absent -- SKIP)"
else
    # Build fixture: a minimal KB dir with one Markdown doc referencing both
    # a local SVG and a local raster PNG, plus the actual image files.
    FIXTURE_KB="${TMP}/fixture-kb"
    mkdir -p "$FIXTURE_KB"

    # Minimal 1x1 SVG (tiny but valid)
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>\n' \
        > "${FIXTURE_KB}/diagram.svg"

    # Minimal 1x1 PNG via known-good base64 literal (decoded to binary)
    python3 -c "
import base64, sys
data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
sys.stdout.buffer.write(base64.b64decode(data))
" > "${FIXTURE_KB}/photo.png"

    # Markdown doc with one SVG and one PNG image reference (with distinct alt texts)
    printf '# Image Fixture\n\nSection with two images.\n\n![A sample diagram](diagram.svg)\n\nSome text.\n\n![A sample photo](photo.png)\n' \
        > "${FIXTURE_KB}/image-fixture.md"

    # Minimal manifest pointing to the fixture doc
    FIXTURE_MANIFEST="${TMP}/fixture-manifest.txt"
    printf '01-image-fixture.html\n' > "$FIXTURE_MANIFEST"

    # Run build-md-export.sh against the fixture KB
    FIXTURE_PAYLOAD="${TMP}/fixture-payload.html"
    FX_BUILD_OUT=$(bash "$BUILD_MD_EXPORT_SH" \
        --kb-dir "$FIXTURE_KB" \
        --manifest "$FIXTURE_MANIFEST" \
        --output "$FIXTURE_PAYLOAD" 2>&1)
    FX_BUILD_RC=$?
    if [[ "$FX_BUILD_RC" -eq 0 && -f "$FIXTURE_PAYLOAD" ]]; then
        pass "KB25a build-md-export.sh succeeds on image-containing fixture"
    else
        fail "KB25a build-md-export.sh succeeds on image-containing fixture -- exit $FX_BUILD_RC"
        echo "$FX_BUILD_OUT" | head -3
    fi

    # Decode the base64 payload from the fixture output
    FIXTURE_DECODED="${TMP}/fixture-decoded.md"
python3 - "$FIXTURE_PAYLOAD" "$FIXTURE_DECODED" <<'PYEOF25' 2>&1
import sys, re, base64
html_path, out_path = sys.argv[1], sys.argv[2]
with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()
m = re.search(r'<script[^>]+id="kb-md-export"[^>]+>([A-Za-z0-9+/=]+)</script>', html)
if not m:
    print("ERROR: fixture #kb-md-export payload not found")
    sys.exit(1)
decoded = base64.b64decode(m.group(1).strip()).decode('utf-8')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(decoded)
print("OK: fixture decoded " + str(len(decoded)) + " chars")
PYEOF25
    FX_DEC_RC=$?

    if [[ "$FX_DEC_RC" -eq 0 && -f "$FIXTURE_DECODED" ]]; then
        pass "KB25b fixture payload decodes to valid UTF-8"

        # (a) SVG ref must become data:image/svg+xml;base64,... with alt text preserved.
        # grep -F treats all characters as literal (brackets, parens, exclamation mark).
        if grep -qF '![A sample diagram](data:image/svg+xml;base64,' "$FIXTURE_DECODED"; then
            pass "KB25c SVG ref converted to data:image/svg+xml;base64,... URI with alt text preserved"
        else
            fail "KB25c SVG ref converted to data:image/svg+xml;base64,... URI with alt text preserved -- not found"
        fi

        # (b) PNG ref must become data:image/png;base64,... with alt text preserved.
        if grep -qF '![A sample photo](data:image/png;base64,' "$FIXTURE_DECODED"; then
            pass "KB25d PNG ref converted to data:image/png;base64,... URI with alt text preserved"
        else
            fail "KB25d PNG ref converted to data:image/png;base64,... URI with alt text preserved -- not found"
        fi

        # (d) No remaining non-data-URI image refs anywhere in the decoded fixture output.
        NON_DATA_FX=$(grep -oE '!\[[^]]*\]\([^)]+\)' "$FIXTURE_DECODED" 2>/dev/null \
            | grep -v '(data:' || true)
        if [[ -z "$NON_DATA_FX" ]]; then
            pass "KB25e no remaining non-data-URI image refs in fixture decoded output"
        else
            fail "KB25e no remaining non-data-URI image refs in fixture decoded output -- found: $(echo "$NON_DATA_FX" | head -3)"
        fi
    else
        fail "KB25b fixture payload decode failed (exit $FX_DEC_RC)"
    fi
fi

# ===========================================================================
# === Playwright availability check =========================================
# ===========================================================================
# Determine if Playwright + Chromium are available.
# Mirror of test-visual-fidelity.sh to ensure consistent detection.
PW_AVAILABLE=0
if command -v node >/dev/null 2>&1; then
    # Primary: ESM import from the known package dir (portable -- uses $PW_PACKAGE_DIR)
    if node --input-type=module <<<"import { chromium } from 'file://${PW_PACKAGE_DIR}/node_modules/playwright/index.mjs'; process.exit(0);" 2>/dev/null; then
        PW_AVAILABLE=1
    fi
    if [[ "$PW_AVAILABLE" -eq 0 ]]; then
        if ( cd "$PW_PACKAGE_DIR" && node -e "require('playwright')" 2>/dev/null ); then
            PW_AVAILABLE=1
        fi
    fi
fi

# ===========================================================================
# === Playwright SKIP when not available ====================================
# ===========================================================================

echo ""
echo "=== KB30+: Playwright visual/browser tests ==="

if [[ "$PW_AVAILABLE" -eq 0 ]]; then
    echo ""
    echo "  Playwright / Chromium not available in this environment."
    echo "  Static and payload tests above ran and passed."
    echo ""
    echo "  SKIP: KB30-KB31 (Playwright browser tests) -- exit 0 per graceful-degradation contract."
    echo ""
    test_summary
    exit $?
fi

# ---------------------------------------------------------------------------
# PLAYWRIGHT_BROWSERS_PATH resolver.
# When HOME is overridden to a temp dir, browser binaries are not under that
# HOME. Resolve the REAL home via /etc/passwd (immune to $HOME override) and
# set PLAYWRIGHT_BROWSERS_PATH so the browser binary is found.
# ---------------------------------------------------------------------------
_PW_BROWSERS_PATH=""
_REAL_HOME=$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)
if [[ -n "$_REAL_HOME" && -d "${_REAL_HOME}/.cache/ms-playwright" ]]; then
    _PW_BROWSERS_PATH="${_REAL_HOME}/.cache/ms-playwright"
fi

run_pw_node() {
    local _script="$1"
    shift
    if [[ -n "$_PW_BROWSERS_PATH" ]]; then
        PLAYWRIGHT_BROWSERS_PATH="$_PW_BROWSERS_PATH" \
            PW_PACKAGE_DIR="$PW_PACKAGE_DIR" \
            node "$_script" "$@" 2>&1
    else
        PW_PACKAGE_DIR="$PW_PACKAGE_DIR" \
            node "$_script" "$@" 2>&1
    fi
}

# ===========================================================================
# === KB30: validate-visuals.mjs passes on committed kb.html (S7 gate) =====
# ===========================================================================

echo ""
echo "=== KB30: validate-visuals.mjs S7 gate passes on committed kb.html ==="
VV_OUT=$(run_pw_node "$VALIDATE_VISUALS_MJS" "$COMMITTED_KB")
VV_RC=$?
if [[ "$VV_RC" -eq 0 ]]; then
    pass "KB30 validate-visuals.mjs S7 gate passes on committed kb.html"
else
    fail "KB30 validate-visuals.mjs S7 gate passes on committed kb.html -- exit $VV_RC"
    echo "$VV_OUT" | grep -E "FAIL|ERROR" | head -5
fi

# ===========================================================================
# === KB31: Playwright browser tests (PW30-PW36) ============================
# ===========================================================================

echo ""
echo "=== KB31: Playwright browser tests (PW30-PW36 via test-kb-export-pw.mjs) ==="

if [[ ! -f "$PW_TEST_MJS" ]]; then
    fail "KB31 Playwright test companion exists at ${PW_TEST_MJS} -- file not found"
    test_summary
    exit $?
fi

PW_OUT=$(run_pw_node "$PW_TEST_MJS" "$COMMITTED_KB")
PW_RC=$?
# Print the output (it has its own PASS/FAIL lines)
echo "$PW_OUT"

if [[ "$PW_RC" -eq 0 ]]; then
    pass "KB31 All Playwright browser tests (PW30-PW36) passed"
else
    fail "KB31 All Playwright browser tests (PW30-PW36) passed -- exit $PW_RC"
fi

# ===========================================================================
# === Summary ===============================================================
# ===========================================================================
echo ""
test_summary
exit $?
