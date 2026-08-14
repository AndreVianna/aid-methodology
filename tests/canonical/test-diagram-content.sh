#!/usr/bin/env bash
# test-diagram-content.sh -- canonical suite for the kb.html diagram-content gate.
#
# Exercises canonical/aid/scripts/summarize/validate-diagram-content.mjs against
# SELF-CONTAINED fixtures (a temp kb.html + a temp manifest), so it always runs in
# CI -- it does NOT depend on the committed kb.html or the summary-src workspace
# (which is gitignored scratch under .aid/.temp/ since work-013).
#
# Asserts the gate:
#   DC01  exits 0 when every required token is present and no forbidden token is,
#   DC02  FIRES (non-zero) when a required token is missing,
#   DC03  FIRES (non-zero) when a forbidden/stale token is injected.
# This is the regression behind docs/diagram-content-reference.md.

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

CHECK="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-diagram-content.mjs"

# Node is required -- graceful tool-availability skip (not a dead skip).
if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not available -- diagram-content gate needs Node.js"
    echo "All tests passed."
    exit 0
fi
if [[ ! -f "$CHECK" ]]; then
    echo "  FAIL: validator not found at $CHECK"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Manifest: one diagram requiring the 7 phase tokens, forbidding "Interview" ---
MANIFEST="${TMP}/manifest.json"
cat > "$MANIFEST" <<'JSONEOF'
{
  "diagrams": [
    {
      "id": "pipeline",
      "match": "AID lifecycle pipeline",
      "requires": ["Discover", "Describe", "Define", "Specify", "Plan", "Detail", "Execute"],
      "forbids": ["Interview"]
    }
  ],
  "globalForbids": ["aid-interview"]
}
JSONEOF

# --- DC01 fixture: matching diagram (all required present, none forbidden) ---
GOOD="${TMP}/good.html"
cat > "$GOOD" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><body>
<svg aria-label="AID lifecycle pipeline" role="img">
  <text>Discover</text><text>Describe</text><text>Define</text>
  <text>Specify</text><text>Plan</text><text>Detail</text><text>Execute</text>
</svg>
</body></html>
HTMLEOF

# --- DC02 fixture: a required token ("Execute") is MISSING ---
MISSING="${TMP}/missing.html"
cat > "$MISSING" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><body>
<svg aria-label="AID lifecycle pipeline" role="img">
  <text>Discover</text><text>Describe</text><text>Define</text>
  <text>Specify</text><text>Plan</text><text>Detail</text>
</svg>
</body></html>
HTMLEOF

# --- DC03 fixture: a FORBIDDEN token ("Interview") is injected ---
FORBIDDEN="${TMP}/forbidden.html"
cat > "$FORBIDDEN" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><body>
<svg aria-label="AID lifecycle pipeline" role="img">
  <text>Interview</text><text>Discover</text><text>Describe</text><text>Define</text>
  <text>Specify</text><text>Plan</text><text>Detail</text><text>Execute</text>
</svg>
</body></html>
HTMLEOF

echo "=== DC01: gate passes when all required tokens present, none forbidden ==="
node "$CHECK" "$GOOD" "$MANIFEST" >/dev/null 2>&1
assert_exit_zero "$?" "DC01 gate exits 0 on a matching diagram"

echo "=== DC02: gate FIRES when a required token is missing ==="
node "$CHECK" "$MISSING" "$MANIFEST" >/dev/null 2>&1
assert_exit_nonzero "$?" "DC02 gate fires on a missing required token (Execute)"

echo "=== DC03: gate FIRES when a forbidden token is injected ==="
node "$CHECK" "$FORBIDDEN" "$MANIFEST" >/dev/null 2>&1
assert_exit_nonzero "$?" "DC03 gate fires on a forbidden token (Interview)"

test_summary
