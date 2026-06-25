#!/usr/bin/env bash
# test-assemble-determinism.sh -- determinism tests for assemble.sh (Change 6 / FR-50).
#
# Scope (task-075 AC2):
#   The deterministic assembler (assemble.sh --manifest) must produce the SAME structural
#   output (byte-identical) for the SAME input (manifest + section files + shell parts).
#   "Same input -> same output" is the Change 6 / FR-50 reproducibility guarantee.
#
# Covers:
#   AD01  --manifest mode produces identical output on two consecutive runs.
#   AD02  Different manifests produce different outputs (order matters).
#   AD03  Lexical-glob fallback produces consistent output (same glob = same result).
#   AD04  Manifest with blank lines and # comments is correctly ignored.
#   AD05  Manifest listing a non-existent section -> exit non-zero.
#   AD06  --manifest with an empty manifest file -> exit non-zero.
#   AD07  Output from --manifest is byte-exact concatenation of skeleton-head +
#         sections (in manifest order) + skeleton-foot + post-script.
#   AD08  --manifest output contains no Mermaid engine (NM guardrail from assembler).
#
# Usage:
#   bash test-assemble-determinism.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

SUT="${REPO_ROOT}/canonical/aid/scripts/summarize/assemble.sh"

[[ -f "$SUT" ]] || { echo "ERROR: assemble.sh not found at $SUT" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Build a minimal summary-src layout in TMP
# ---------------------------------------------------------------------------
SRC="${TMP}/summary-src"
mkdir -p "${SRC}/sections"

# shell parts
cat > "${SRC}/skeleton-head.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>KB Summary</title></head>
<body>
HTMLEOF

cat > "${SRC}/skeleton-foot.html" <<'HTMLEOF'
</main>
HTMLEOF

cat > "${SRC}/post-script.html" <<'HTMLEOF'
<footer><p>Generated.</p></footer>
</body>
</html>
HTMLEOF

# Section files
cat > "${SRC}/sections/01-at-a-glance.html" <<'HTMLEOF'
<section id="at-a-glance"><h2>At a Glance</h2><p>Plain language intro.</p></section>
HTMLEOF

cat > "${SRC}/sections/02-glossary.html" <<'HTMLEOF'
<section id="glossary"><h2>Key Vocabulary</h2><p>Terms here.</p></section>
HTMLEOF

cat > "${SRC}/sections/03-decisions.html" <<'HTMLEOF'
<section id="decisions"><h2>Key Decisions</h2><p>ADRs here.</p></section>
HTMLEOF

cat > "${SRC}/sections/04-capabilities.html" <<'HTMLEOF'
<section id="capabilities"><h2>What This Can Do</h2><p>Caps here.</p></section>
HTMLEOF

cat > "${SRC}/sections/05-architecture.html" <<'HTMLEOF'
<section id="architecture"><h2>Architecture</h2><p>Arch here.</p></section>
HTMLEOF

# Manifest A: deterministic order (01..05)
MANIFEST_A="${TMP}/manifest-a.txt"
cat > "$MANIFEST_A" <<'EOF'
01-at-a-glance.html
02-glossary.html
03-decisions.html
04-capabilities.html
05-architecture.html
EOF

# Manifest B: reverse order (05..01)
MANIFEST_B="${TMP}/manifest-b.txt"
cat > "$MANIFEST_B" <<'EOF'
05-architecture.html
04-capabilities.html
03-decisions.html
02-glossary.html
01-at-a-glance.html
EOF

# Manifest with blank lines and comments
MANIFEST_COMMENTS="${TMP}/manifest-comments.txt"
cat > "$MANIFEST_COMMENTS" <<'EOF'
# at a glance always first

01-at-a-glance.html

# concept trio
02-glossary.html
03-decisions.html

# remaining primaries
04-capabilities.html
05-architecture.html
EOF

# Helper: run assemble from TMP (cd sets cwd for relative path defaults)
run_assemble() {
    OUT=$(cd "$TMP" && bash "$SUT" "$@" 2>&1); RC=$?
}

# ===========================================================================
# AD01: same manifest -> byte-identical output on two consecutive runs
# ===========================================================================

echo ""
echo "=== AD01: same manifest -> same structural output (reproducible / FR-50) ==="

OUT_AD01_A="${TMP}/run1.html"
OUT_AD01_B="${TMP}/run2.html"

run_assemble --src "$SRC" --manifest "$MANIFEST_A" --output "$OUT_AD01_A"
assert_exit_zero "$RC" "AD01a first run exits 0"
assert_file_exists "$OUT_AD01_A" "AD01b first run produced output file"

run_assemble --src "$SRC" --manifest "$MANIFEST_A" --output "$OUT_AD01_B"
assert_exit_zero "$RC" "AD01c second run exits 0"
assert_file_exists "$OUT_AD01_B" "AD01d second run produced output file"

if cmp -s "$OUT_AD01_A" "$OUT_AD01_B"; then
    pass "AD01e two runs with same manifest -> byte-identical output (deterministic)"
else
    fail "AD01e two runs with same manifest produced different output (non-deterministic)"
fi

# ===========================================================================
# AD02: different manifest order -> different output
# ===========================================================================

echo ""
echo "=== AD02: different manifest order -> different structural output ==="

OUT_AD02="${TMP}/run-b.html"
run_assemble --src "$SRC" --manifest "$MANIFEST_B" --output "$OUT_AD02"
assert_exit_zero "$RC" "AD02a manifest-B run exits 0"

if ! cmp -s "$OUT_AD01_A" "$OUT_AD02"; then
    pass "AD02b different manifest order -> different output (order matters)"
else
    fail "AD02b different manifest order produced identical output (order ignored)"
fi

# The first section in output-A should be at-a-glance; in output-B it should be architecture.
if grep -q "at-a-glance" <(head -c 500 "$OUT_AD01_A") && \
   grep -q "architecture" <(head -c 500 "$OUT_AD02"); then
    pass "AD02c manifests produce correct leading sections"
else
    fail "AD02c manifest ordering not reflected in output sections"
fi

# ===========================================================================
# AD03: lexical-glob fallback produces consistent output
# ===========================================================================

echo ""
echo "=== AD03: lexical-glob fallback (no --manifest) -> consistent on repeat runs ==="

OUT_AD03_A="${TMP}/glob-run1.html"
OUT_AD03_B="${TMP}/glob-run2.html"

run_assemble --src "$SRC" --output "$OUT_AD03_A"
assert_exit_zero "$RC" "AD03a lexical-glob first run exits 0"
assert_file_exists "$OUT_AD03_A" "AD03b lexical-glob first run produced output"

run_assemble --src "$SRC" --output "$OUT_AD03_B"
assert_exit_zero "$RC" "AD03c lexical-glob second run exits 0"

if cmp -s "$OUT_AD03_A" "$OUT_AD03_B"; then
    pass "AD03d lexical-glob produces consistent output on repeat runs"
else
    fail "AD03d lexical-glob produced different output on repeat runs"
fi

assert_output_contains "$OUT" "lexical glob" "AD03e output labels the order mode as 'lexical glob'"

# ===========================================================================
# AD04: blank lines and # comments in manifest are ignored
# ===========================================================================

echo ""
echo "=== AD04: manifest with blank lines + # comments -> same output as plain manifest ==="

OUT_AD04="${TMP}/run-comments.html"
run_assemble --src "$SRC" --manifest "$MANIFEST_COMMENTS" --output "$OUT_AD04"
assert_exit_zero "$RC" "AD04a manifest with comments exits 0"
assert_file_exists "$OUT_AD04" "AD04b manifest with comments produced output"

# Both manifests specify the same section order; output should be identical.
if cmp -s "$OUT_AD01_A" "$OUT_AD04"; then
    pass "AD04c blank lines + # comments ignored: output matches plain manifest"
else
    fail "AD04c manifest with comments produced different output from plain manifest"
fi

# ===========================================================================
# AD05: manifest referencing missing section -> non-zero exit
# ===========================================================================

echo ""
echo "=== AD05: manifest with missing section -> non-zero exit ==="

MANIFEST_MISSING="${TMP}/manifest-missing.txt"
cat > "$MANIFEST_MISSING" <<'EOF'
01-at-a-glance.html
99-does-not-exist.html
EOF

run_assemble --src "$SRC" --manifest "$MANIFEST_MISSING" --output "${TMP}/bad.html"
assert_exit_nonzero "$RC" "AD05 manifest with missing section -> non-zero exit"

# ===========================================================================
# AD06: empty manifest -> non-zero exit
# ===========================================================================

echo ""
echo "=== AD06: empty manifest -> non-zero exit ==="

MANIFEST_EMPTY="${TMP}/manifest-empty.txt"
# Only blank lines and comments -- effectively empty
cat > "$MANIFEST_EMPTY" <<'EOF'
# no sections

EOF

run_assemble --src "$SRC" --manifest "$MANIFEST_EMPTY" --output "${TMP}/empty-out.html"
assert_exit_nonzero "$RC" "AD06 empty manifest -> non-zero exit"

# ===========================================================================
# AD07: output is byte-exact concatenation (skeleton-head + sections + skeleton-foot + post-script)
# ===========================================================================

echo ""
echo "=== AD07: --manifest output is byte-exact concatenation of shell parts + sections ==="

REF_AD07="${TMP}/ref-ad07.html"
# Build expected output by hand: head + sections in manifest-A order + foot + post-script
cat \
    "${SRC}/skeleton-head.html" \
    "${SRC}/sections/01-at-a-glance.html" \
    "${SRC}/sections/02-glossary.html" \
    "${SRC}/sections/03-decisions.html" \
    "${SRC}/sections/04-capabilities.html" \
    "${SRC}/sections/05-architecture.html" \
    "${SRC}/skeleton-foot.html" \
    "${SRC}/post-script.html" \
    > "$REF_AD07"

if cmp -s "$OUT_AD01_A" "$REF_AD07"; then
    pass "AD07 --manifest output is byte-exact concatenation of shell parts + sections"
else
    fail "AD07 --manifest output differs from expected byte-exact concatenation"
fi

# ===========================================================================
# AD08: assemble.sh output contains no Mermaid engine (NM guardrail)
# ===========================================================================

echo ""
echo "=== AD08: assembled output contains no Mermaid engine or init call (NM) ==="

# NM.1: no very large inline script block containing 'mermaid'
INLINE_MERMAID=$(awk '
    /^<script/ { buf=""; in_script=1 }
    in_script { buf = buf $0 "\n" }
    /<\/script>/ { in_script=0; if (length(buf) > 100000 && tolower(buf) ~ /mermaid/) print "FOUND" }
' "$OUT_AD01_A" 2>/dev/null || echo "")
if [[ -z "$INLINE_MERMAID" ]]; then
    pass "AD08a no inline Mermaid engine bundle (NM.1)"
else
    fail "AD08a inline Mermaid engine bundle detected (NM.1)"
fi

# NM.2: no mermaid.initialize() call
if ! grep -qE 'mermaid\.initialize\(' "$OUT_AD01_A" 2>/dev/null; then
    pass "AD08b no mermaid.initialize() call (NM.2)"
else
    fail "AD08b mermaid.initialize() call found in assembled output (NM.2)"
fi

# NM.3: no CDN Mermaid script src
if ! grep -qE '<script[^>]+src="https?://[^"]*mermaid[^"]*"' "$OUT_AD01_A" 2>/dev/null; then
    pass "AD08c no CDN Mermaid <script src> (NM.3)"
else
    fail "AD08c CDN Mermaid <script src> found in assembled output (NM.3)"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
test_summary
exit $?
