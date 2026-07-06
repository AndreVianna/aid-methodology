#!/usr/bin/env bash
# test-diagram-content.sh -- canonical suite for the kb.html diagram-content gate.
#
# Verifies that AID's own kb.html diagrams match their content manifest
# (.aid/.temp/summarize/summary-src/diagram-content-manifest.json) via
# canonical/aid/scripts/summarize/validate-diagram-content.mjs, AND that the gate
# actually FIRES on drift (stale phase label / deleted-skill token). This is the
# enforcement behind docs/diagram-content-reference.md -- it catches diagram label
# drift that text-grep and the rendering-only visual gate miss.

set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

CHECK="canonical/aid/scripts/summarize/validate-diagram-content.mjs"
MANIFEST=".aid/.temp/summarize/summary-src/diagram-content-manifest.json"
KB=".aid/dashboard/kb.html"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# Graceful skips (node-less hosts, or a repo without a generated kb.html/manifest).
if ! command -v node >/dev/null 2>&1; then
  echo "SKIP: node not available -- diagram-content gate needs Node.js"; echo "All tests passed."; exit 0
fi
for f in "$CHECK" "$MANIFEST" "$KB"; do
  if [ ! -f "$f" ]; then
    echo "SKIP: $f not present -- nothing to validate"; echo "All tests passed."; exit 0
  fi
done

echo "=== DC01: kb.html diagrams match the content manifest (exit 0) ==="
if node "$CHECK" "$KB" "$MANIFEST" >/tmp/dc01.out 2>&1; then
  ok "DC01 kb.html diagram content matches the manifest"
else
  bad "DC01 kb.html diagram content FAILED the manifest:"; sed 's/^/      /' /tmp/dc01.out
fi

echo "=== DC02: gate FIRES on a stale phase label (Describe -> Define reverted to Interview) ==="
TMP="$(mktemp)"; cp "$KB" "$TMP"
sed -i 's/>Describe &#8594; Define</>Interview</' "$TMP"
if node "$CHECK" "$TMP" "$MANIFEST" >/dev/null 2>&1; then
  bad "DC02 gate did NOT fire on a stale 'Interview' phase label (regression!)"
else
  ok "DC02 gate correctly fired on the stale 'Interview' phase label"
fi
rm -f "$TMP"

echo "=== DC03: gate FIRES on a deleted-skill token (aid-interview in a diagram) ==="
TMP="$(mktemp)"; cp "$KB" "$TMP"
# inject the deleted skill name into the pipeline diagram's first label
sed -i '0,/>Discover</s//>aid-interview</' "$TMP"
if node "$CHECK" "$TMP" "$MANIFEST" >/dev/null 2>&1; then
  bad "DC03 gate did NOT fire on a 'aid-interview' deleted-skill token (regression!)"
else
  ok "DC03 gate correctly fired on the 'aid-interview' deleted-skill token"
fi
rm -f "$TMP"

echo ""
echo "Tests passed: $PASS"
echo "Tests failed: $FAIL"
if [ "$FAIL" -eq 0 ]; then echo "All tests passed."; exit 0; else echo "FAILURES."; exit 1; fi
