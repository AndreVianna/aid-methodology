#!/usr/bin/env bash
# test-validate-diagrams.sh — tests for canonical/scripts/summarize/validate-diagrams.mjs,
# the Node validator that extracts <pre|div class="mermaid"> blocks from an HTML file and
# checks each (D1 regex sanity, always; D2 render, --fast skips it).
#
# Scope: only the D1 (regex) + invocation paths are exercised, via --fast. D2 (render)
# needs jsdom or a network npx mermaid-cli fetch and is therefore NOT hermetic — it is
# intentionally out of scope here so the suite is deterministic on any host with Node.
#
# Usage:
#   bash test-validate-diagrams.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail. Skips (exit 0) if Node is not on PATH.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/summarize/validate-diagrams.mjs"

[[ -f "$SUT" ]] || { echo "ERROR: validate-diagrams.mjs not found at $SUT" >&2; exit 1; }

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not found on PATH — skipping validate-diagrams suite (needs Node.js)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# run <html-file> [extra-args...] -> captures OUT, RC
run() {
    OUT=$(node "$SUT" "$@" 2>&1); RC=$?
}

# --- Fixtures ---------------------------------------------------------------
cat > "$TMP/valid-single.html" <<'EOF'
<html><body>
<pre class="mermaid">graph TD
  A --> B
  B --> C</pre>
</body></html>
EOF

cat > "$TMP/valid-multi.html" <<'EOF'
<html><body>
<pre class="mermaid">graph TD
  A --> B</pre>
<pre class="mermaid">sequenceDiagram
  Alice ->> Bob: hi</pre>
</body></html>
EOF

cat > "$TMP/valid-div.html" <<'EOF'
<html><body>
<div class="mermaid">flowchart LR
  X --> Y</div>
</body></html>
EOF

cat > "$TMP/none.html" <<'EOF'
<html><body><p>No diagrams here.</p></body></html>
EOF

# Single line → fewer than 2 content lines → "empty or contains only a directive"
cat > "$TMP/directive-only.html" <<'EOF'
<html><body><pre class="mermaid">graph TD; A --> B; B --> C</pre></body></html>
EOF

cat > "$TMP/bad-type.html" <<'EOF'
<html><body>
<pre class="mermaid">notarealtype foo
  bar baz</pre>
</body></html>
EOF

cat > "$TMP/empty-block.html" <<'EOF'
<html><body><pre class="mermaid"></pre></body></html>
EOF

cat > "$TMP/mixed.html" <<'EOF'
<html><body>
<pre class="mermaid">graph TD
  A --> B</pre>
<pre class="mermaid">notarealtype x
  y z</pre>
</body></html>
EOF

# --- Invocation paths -------------------------------------------------------
run
assert_exit_eq "$RC" 2 "VD01 no args → usage exit 2"

run --help
assert_exit_eq "$RC" 2 "VD02 --help → exit 2"
assert_output_contains "$OUT" "Usage" "VD02b --help prints usage"

run -h
assert_exit_eq "$RC" 2 "VD03 -h → exit 2"

run "$TMP/does-not-exist.html" --fast
assert_exit_eq "$RC" 2 "VD04 missing file → exit 2"
assert_output_contains "$OUT" "Cannot read" "VD04b missing file → 'Cannot read'"

# --- Zero diagrams (warn, but pass) ----------------------------------------
run "$TMP/none.html" --fast
assert_exit_eq "$RC" 0 "VD05 zero diagrams → exit 0"
assert_output_contains "$OUT" "No <pre class=\"mermaid\"> or <div class=\"mermaid\">" "VD05b zero diagrams → warning"

# --- Valid diagrams (D1 passes under --fast) --------------------------------
run "$TMP/valid-single.html" --fast
assert_exit_eq "$RC" 0 "VD06 valid single diagram (--fast) → exit 0"
assert_output_contains "$OUT" "pass regex sanity check" "VD06b valid single → pass message"

run "$TMP/valid-multi.html" --fast
assert_exit_eq "$RC" 0 "VD07 valid multi-diagram (--fast) → exit 0"
assert_output_contains "$OUT" "Validating 2 Mermaid diagram" "VD07b counts 2 diagrams"

run "$TMP/valid-div.html" --fast
assert_exit_eq "$RC" 0 "VD08 <div class=mermaid> variant recognized (--fast) → exit 0"

# --- Failing diagrams (D1 catches them) ------------------------------------
run "$TMP/directive-only.html" --fast
assert_exit_eq "$RC" 1 "VD09 single-line directive-only → exit 1"
assert_output_contains "$OUT" "empty or contains only a directive" "VD09b directive-only message"

run "$TMP/bad-type.html" --fast
assert_exit_eq "$RC" 1 "VD10 unrecognized diagram type → exit 1"
assert_output_contains "$OUT" "Diagram type not recognized" "VD10b unrecognized-type message"

run "$TMP/empty-block.html" --fast
assert_exit_eq "$RC" 1 "VD11 empty mermaid block → exit 1"

run "$TMP/mixed.html" --fast
assert_exit_eq "$RC" 1 "VD12 mixed valid+invalid → exit 1"
assert_output_contains "$OUT" "of 2 diagram(s) failed" "VD12b mixed → 'X of 2 failed'"

test_summary
