#!/usr/bin/env bash
# test-visual-fidelity.sh -- canonical tests for validate-visuals.mjs
#   (D-012 feature-015 S7 visual-fidelity gate, task-075 AC: Playwright fidelity fixtures)
#
# Scope (task-075 AC1):
#   - --check-only and invocation-error paths (no Playwright needed).
#   - Playwright SKIP degrades gracefully (exit 0 + clear message) when Playwright
#     is not installed. Mirrors the CI degradation contract from playwright-provisioning.md.
#   - When Playwright IS available: runs against committed fixture HTML files:
#       VF-GOOD  -> PASS (readable text, no overlap, non-trivial layout).
#       VF-CLIP  -> FAIL T1 (text clipped / font-size below threshold).
#       VF-OVER  -> FAIL T2 (overlapping child elements).
#       VF-COLL  -> FAIL T3 (collapsed / zero-size visual).
#   - "No visuals found" trivially passes (SKIP message + exit 0).
#
# The Playwright gate runs only when Chromium + Playwright are available.
# When not available the suite emits a clear SKIP and exits 0 so CI doesn't
# block branches where Playwright hasn't been provisioned.
#
# Usage:
#   bash test-visual-fidelity.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed (or Playwright unavailable -- SKIP)
#   1 -- one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

SUT="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-visuals.mjs"

# ---------------------------------------------------------------------------
# Node prerequisite check (the mjs itself needs Node)
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not found on PATH -- skipping visual-fidelity suite (needs Node.js)."
    exit 0
fi

[[ -f "$SUT" ]] || { echo "ERROR: validate-visuals.mjs not found at $SUT" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run() { OUT=$(node "$SUT" "$@" 2>&1); RC=$?; }

# ===========================================================================
# === Invocation error paths (no Playwright needed) =========================
# ===========================================================================

echo ""
echo "=== VF01: no args -> usage + exit 2 ==="
run
assert_exit_eq "$RC" 2 "VF01 no args -> exit 2"
assert_output_contains "$OUT" "Usage" "VF01b no args -> prints usage"

echo ""
echo "=== VF02: --help -> usage + exit 2 ==="
run --help
assert_exit_eq "$RC" 2 "VF02 --help -> exit 2"
assert_output_contains "$OUT" "Usage" "VF02b --help -> prints usage"

echo ""
echo "=== VF03: -h -> usage + exit 2 ==="
run -h
assert_exit_eq "$RC" 2 "VF03 -h -> exit 2"

echo ""
echo "=== VF04: unknown flag -> exit 2 ==="
run --no-such-flag "$TMP/x.html"
assert_exit_eq "$RC" 2 "VF04 unknown flag -> exit 2"

echo ""
echo "=== VF05: missing html file -> SKIP exit 0 (not a hard error) ==="
# validate-visuals.mjs exits 0 with a SKIP message when the html file is absent
# so that CI gracefully skips when kb.html hasn't been generated yet.
run "$TMP/does-not-exist.html"
assert_exit_eq "$RC" 0 "VF05 missing html -> exit 0 (graceful SKIP)"
assert_output_contains "$OUT" "SKIP" "VF05b missing html -> SKIP message"

# ===========================================================================
# === --check-only mode (no Playwright needed -- resolves visuals from source)
# ===========================================================================

echo ""
echo "=== VF10: --check-only on html with inline SVG -> resolves + exit 0 ==="
cat > "$TMP/has-svg.html" <<'HTMLEOF'
<!DOCTYPE html>
<html><head><title>T</title></head>
<body>
<svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="10" width="80" height="40" fill="#007F7D"/>
  <text x="50" y="35" font-size="14" fill="white">Label</text>
</svg>
</body></html>
HTMLEOF

run --check-only "$TMP/has-svg.html"
assert_exit_eq "$RC" 0 "VF10 --check-only with inline SVG -> exit 0"
assert_output_contains "$OUT" "check-only" "VF10b --check-only prints check-only header"
assert_output_contains "$OUT" "Inline <svg>" "VF10c --check-only reports inline SVG count"

echo ""
echo "=== VF11: --check-only on html with .diagram-box -> counts it ==="
cat > "$TMP/has-diagram-box.html" <<'HTMLEOF'
<!DOCTYPE html>
<html><head><title>T</title></head>
<body>
<div class="diagram-box" style="width:200px;height:100px">
  <svg width="200" height="100"><rect width="200" height="100" fill="#ccc"/></svg>
</div>
</body></html>
HTMLEOF

run --check-only "$TMP/has-diagram-box.html"
assert_exit_eq "$RC" 0 "VF11 --check-only with diagram-box -> exit 0"
assert_output_contains "$OUT" ".diagram-box" "VF11b reports .diagram-box count"

echo ""
echo "=== VF12: --check-only on html with .infographic -> counts it ==="
cat > "$TMP/has-infographic.html" <<'HTMLEOF'
<!DOCTYPE html>
<html><head><title>T</title></head>
<body>
<div class="infographic" style="width:300px;height:150px">
  <p style="font-size:14px">Infographic content</p>
</div>
</body></html>
HTMLEOF

run --check-only "$TMP/has-infographic.html"
assert_exit_eq "$RC" 0 "VF12 --check-only with infographic -> exit 0"
assert_output_contains "$OUT" ".infographic" "VF12b reports .infographic count"

echo ""
echo "=== VF13: --check-only on html with no visuals -> exit 0 ==="
cat > "$TMP/no-visuals.html" <<'HTMLEOF'
<!DOCTYPE html>
<html><head><title>T</title></head>
<body><p>No visuals here.</p></body></html>
HTMLEOF

run --check-only "$TMP/no-visuals.html"
assert_exit_eq "$RC" 0 "VF13 --check-only on visual-free html -> exit 0"

echo ""
echo "=== VF14: --min-font-size flag is accepted in --check-only mode ==="
run --check-only --min-font-size 12 "$TMP/has-svg.html"
assert_exit_eq "$RC" 0 "VF14 --check-only + --min-font-size -> exit 0"
assert_output_contains "$OUT" "12" "VF14b min-font-size value appears in output"

echo ""
echo "=== VF15: --min-font-size with invalid value -> exit 2 ==="
run --check-only --min-font-size abc "$TMP/has-svg.html"
assert_exit_eq "$RC" 2 "VF15 --min-font-size non-integer -> exit 2"

# ===========================================================================
# === Playwright availability check
# ===========================================================================
# Determine if Playwright + Chromium are available in this environment.
# We do this by attempting to import playwright from the package dir.
PW_PACKAGE_DIR="${REPO_ROOT}/canonical/aid/scripts/summarize"
PW_AVAILABLE=0
if node --input-type=module <<'JSEOF' 2>/dev/null; then
import { chromium } from '/home/andre.vianna/projects/AID/canonical/aid/scripts/summarize/node_modules/playwright/index.mjs';
process.exit(0);
JSEOF
    PW_AVAILABLE=1
fi

# Alternative check: NODE_PATH resolution
if [[ "$PW_AVAILABLE" -eq 0 ]]; then
    if ( cd "$PW_PACKAGE_DIR" && node -e "require('playwright')" 2>/dev/null ); then
        PW_AVAILABLE=1
    fi
fi

# ===========================================================================
# === Playwright SKIP degradation when not available
# ===========================================================================

echo ""
echo "=== VF20: when Playwright not installed -> exit 0 with SKIP message ==="
# Build a fixture with a visible SVG (so the script proceeds to the PW check)
cat > "$TMP/pw-skip-test.html" <<'HTMLEOF'
<!DOCTYPE html>
<html><head><title>T</title></head>
<body>
<svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="10" width="80" height="40" fill="#007F7D"/>
  <text x="50" y="35" font-size="14" fill="white">Label</text>
</svg>
</body></html>
HTMLEOF

if [[ "$PW_AVAILABLE" -eq 0 ]]; then
    # Run directly from the repo root (not from the PW package dir)
    # so Playwright is not on the module search path -> degrades gracefully.
    run "$TMP/pw-skip-test.html"
    assert_exit_eq "$RC" 0 "VF20 Playwright absent -> exit 0 (graceful SKIP)"
    assert_output_contains "$OUT" "SKIP" "VF20b Playwright absent -> prints SKIP"
    assert_output_contains "$OUT" "not installed" "VF20c SKIP message says 'not installed'"
    echo "  (Playwright not available -- SKIP path exercised as expected)"
else
    echo "  (Playwright available -- skip the degradation test; see VF30+ for Playwright tests)"
    pass "VF20 Playwright available in this environment -- SKIP path not testable here"
fi

# ===========================================================================
# === Playwright fixture tests (only run when Playwright is available)
# ===========================================================================

if [[ "$PW_AVAILABLE" -eq 0 ]]; then
    echo ""
    echo "=== VF30-VF50: Playwright visual-fidelity fixtures SKIPPED ==="
    echo "  Playwright / Chromium not available in this environment."
    echo "  These tests require: cd canonical/aid/scripts/summarize && npm ci && npx playwright install chromium"
    echo "  CI runs them automatically via the visual-fidelity job in test.yml."
    echo ""
    echo "  SKIP: VF30-VF50 (Playwright fixture gate) -- exit 0 per graceful-degradation contract."
    echo ""
    test_summary
    exit $?
fi

# ---------------------------------------------------------------------------
# Playwright IS available -- run against fixture HTML files.
# We run validate-visuals.mjs from the PW package dir so it resolves playwright.
# ---------------------------------------------------------------------------

# PLAYWRIGHT_BROWSERS_PATH -- Playwright stores its browser binaries under
# $HOME/.cache/ms-playwright. When this suite is run with HOME overridden to
# a temp dir (e.g. `export HOME=$(mktemp -d); bash tests/run-all.sh` for
# canonical isolation), the browser binary is not found and launch fails.
# Fix: resolve the REAL home directory via /etc/passwd (immune to $HOME
# override) and set PLAYWRIGHT_BROWSERS_PATH so Playwright finds its binary
# regardless of what $HOME is set to.
_PW_BROWSERS_PATH_OVERRIDE=""
_REAL_HOME=$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)
if [[ -n "$_REAL_HOME" && -d "$_REAL_HOME/.cache/ms-playwright" ]]; then
    _PW_BROWSERS_PATH_OVERRIDE="$_REAL_HOME/.cache/ms-playwright"
fi

run_from_pw_dir() {
    if [[ -n "$_PW_BROWSERS_PATH_OVERRIDE" ]]; then
        OUT=$(cd "$PW_PACKAGE_DIR" && PLAYWRIGHT_BROWSERS_PATH="$_PW_BROWSERS_PATH_OVERRIDE" node "$SUT" "$@" 2>&1); RC=$?
    else
        OUT=$(cd "$PW_PACKAGE_DIR" && node "$SUT" "$@" 2>&1); RC=$?
    fi
}

# --- Fixture: Good visual (T1/T2/T3 all PASS) ---
# A .diagram-box with non-trivial size, readable text, no overlapping children.
cat > "$TMP/vf-good.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Good Visual Fixture</title>
<style>
body { margin: 0; font-family: sans-serif; }
.diagram-box {
  display: block;
  width: 400px;
  height: 200px;
  padding: 16px;
  box-sizing: border-box;
  background: #f0f4f8;
}
.step {
  display: inline-block;
  margin: 8px;
  padding: 12px 20px;
  background: #007F7D;
  color: white;
  font-size: 14px;
  border-radius: 4px;
}
</style>
</head>
<body>
<div class="diagram-box">
  <div class="step">Step A</div>
  <div class="step">Step B</div>
  <div class="step">Step C</div>
</div>
</body>
</html>
HTMLEOF

echo ""
echo "=== VF30: good visual (readable text, no overlap, non-trivial size) -> PASS ==="
run_from_pw_dir "$TMP/vf-good.html"
assert_exit_eq "$RC" 0 "VF30 good visual -> exit 0 (PASS)"
assert_output_contains "$OUT" "PASS" "VF30b good visual -> PASS in output"

# --- Fixture: Collapsed visual (T3 FAIL) ---
# .diagram-box with display:none -> collapsed to zero dimensions.
cat > "$TMP/vf-collapsed.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Collapsed Visual Fixture</title>
<style>
body { margin: 0; }
.diagram-box { display: none; width: 400px; height: 200px; }
</style>
</head>
<body>
<div class="diagram-box">
  <p>Hidden content</p>
</div>
</body>
</html>
HTMLEOF

echo ""
echo "=== VF31: collapsed visual (display:none -> zero size) -> FAIL T3 ==="
run_from_pw_dir "$TMP/vf-collapsed.html"
assert_exit_eq "$RC" 1 "VF31 collapsed visual -> exit 1 (FAIL)"
assert_output_contains "$OUT" "FAIL" "VF31b collapsed visual -> FAIL in output"

# --- Fixture: Overlapping visual (T2 FAIL) ---
# Two absolutely-positioned children inside a .diagram-box that fully overlap each other.
cat > "$TMP/vf-overlap.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Overlap Visual Fixture</title>
<style>
body { margin: 0; }
.diagram-box {
  position: relative;
  width: 400px;
  height: 200px;
  background: #f0f4f8;
}
.box-a {
  position: absolute;
  top: 10px; left: 10px;
  width: 200px; height: 180px;
  background: rgba(255,0,0,0.3);
}
.box-b {
  position: absolute;
  top: 10px; left: 10px;
  width: 200px; height: 180px;
  background: rgba(0,0,255,0.3);
}
</style>
</head>
<body>
<div class="diagram-box">
  <div class="box-a">Box A</div>
  <div class="box-b">Box B</div>
</div>
</body>
</html>
HTMLEOF

echo ""
echo "=== VF32: overlapping children -> FAIL T2 ==="
run_from_pw_dir "$TMP/vf-overlap.html"
assert_exit_eq "$RC" 1 "VF32 overlapping children -> exit 1 (FAIL)"
assert_output_contains "$OUT" "FAIL" "VF32b overlapping children -> FAIL in output"

# --- Fixture: Clipped text (T1 FAIL) ---
# .diagram-box with text in a zero-height overflow:hidden container -> clipped.
cat > "$TMP/vf-clipped.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Clipped Text Fixture</title>
<style>
body { margin: 0; }
.diagram-box {
  width: 400px;
  height: 200px;
  background: #f0f4f8;
}
.tiny-text {
  font-size: 3px;
  overflow: hidden;
  color: #333;
}
</style>
</head>
<body>
<div class="diagram-box">
  <div class="tiny-text">This text is illegibly small (3px font-size).</div>
</div>
</body>
</html>
HTMLEOF

echo ""
echo "=== VF33: illegibly small text (3px font-size) -> FAIL T1 ==="
run_from_pw_dir "$TMP/vf-clipped.html"
assert_exit_eq "$RC" 1 "VF33 clipped/tiny text -> exit 1 (FAIL)"
assert_output_contains "$OUT" "FAIL" "VF33b tiny text -> FAIL in output"

# --- Fixture: No visuals (trivially passes) ---
cat > "$TMP/vf-no-visuals.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>No Visuals</title></head>
<body><p>No visuals here.</p></body>
</html>
HTMLEOF

echo ""
echo "=== VF34: no visuals in HTML -> PASS (trivially, exit 0) ==="
run_from_pw_dir "$TMP/vf-no-visuals.html"
assert_exit_eq "$RC" 0 "VF34 no visuals -> exit 0 (trivially passed)"
assert_output_contains "$OUT" "0 visuals" "VF34b no visuals -> '0 visuals' in output"

# --- Fixture: inline SVG with readable content -> T1/T2/T3 all pass ---
cat > "$TMP/vf-inline-svg.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Inline SVG</title>
<style>body { margin: 0; }</style>
</head>
<body>
<svg width="300" height="150" xmlns="http://www.w3.org/2000/svg">
  <g id="group-a">
    <rect x="10" y="10" width="80" height="60" fill="#007F7D"/>
    <text x="50" y="45" font-size="14" fill="white" text-anchor="middle">Node A</text>
  </g>
  <g id="group-b">
    <rect x="200" y="10" width="80" height="60" fill="#0B1F3A"/>
    <text x="240" y="45" font-size="14" fill="white" text-anchor="middle">Node B</text>
  </g>
</svg>
</body>
</html>
HTMLEOF

echo ""
echo "=== VF35: inline SVG with readable groups -> PASS ==="
run_from_pw_dir "$TMP/vf-inline-svg.html"
assert_exit_eq "$RC" 0 "VF35 inline SVG readable -> exit 0 (PASS)"
assert_output_contains "$OUT" "PASS" "VF35b inline SVG readable -> PASS in output"

# ===========================================================================
# === Summary
# ===========================================================================
echo ""
test_summary
exit $?
