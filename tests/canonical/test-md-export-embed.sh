#!/usr/bin/env bash
# test-md-export-embed.sh -- canonical suite for assemble.sh's Markdown-export embedding.
#
# Exercises canonical/aid/scripts/summarize/assemble.sh against a SELF-CONTAINED
# fixture summary-src (built in a temp dir), so it always runs in CI -- it does NOT
# depend on the committed kb.html or the gitignored summary-src workspace (work-013).
#
# Asserts:
#   ME01  when a md-export-payload.html is present in the source layout, assemble.sh
#         embeds it into kb.html (#kb-md-export element) and reports "MD Export: embedded".
#   ME02  when the payload is absent, assemble.sh omits it and reports "MD Export: not present"
#         (backward-compatible -- no error, no #kb-md-export element).
# Replaces the committed-workspace-dependent KB10-KB12 checks removed from test-kb-export.sh.

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

ASSEMBLE_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/assemble.sh"
if [[ ! -f "$ASSEMBLE_SH" ]]; then
    echo "  FAIL: assemble.sh not found at $ASSEMBLE_SH"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Build a minimal fixture summary-src layout ---
SRC="${TMP}/summary-src"
mkdir -p "${SRC}/sections"
printf '<!DOCTYPE html>\n<html lang="en"><head><meta charset="UTF-8"><title>KB</title></head><body>\n<main>\n' > "${SRC}/skeleton-head.html"
printf '<section id="at-a-glance"><h2>At a Glance</h2><p>Intro.</p></section>\n' > "${SRC}/sections/01-at-a-glance.html"
printf '</main>\n' > "${SRC}/skeleton-foot.html"
printf '<footer><p>Generated.</p></footer>\n</body></html>\n' > "${SRC}/post-script.html"

MANIFEST="${TMP}/manifest.txt"
printf '01-at-a-glance.html\n' > "$MANIFEST"

# Tiny prebuilt MD-export payload (base64 body, matches build-md-export.sh's element contract).
PAYLOAD="${SRC}/md-export-payload.html"
printf '<script type="text/markdown" id="kb-md-export" data-encoding="base64">SGVsbG8gS0I=</script>\n' > "$PAYLOAD"

echo "=== ME01: assemble.sh embeds the MD-export payload when present ==="
OUT_KB="${TMP}/kb-with-payload.html"
ASM_OUT=$(bash "$ASSEMBLE_SH" --src "$SRC" --manifest "$MANIFEST" --output "$OUT_KB" 2>&1)
assert_exit_zero "$?" "ME01a assemble.sh exits 0 with payload present"
assert_output_contains "$ASM_OUT" "MD Export: embedded" "ME01b assemble.sh reports 'MD Export: embedded'"
assert_file_contains "$OUT_KB" 'id="kb-md-export"' "ME01c assembled kb.html contains the #kb-md-export element"
assert_file_contains "$OUT_KB" 'SGVsbG8gS0I=' "ME01d assembled kb.html contains the base64 payload body"

echo "=== ME02: assemble.sh omits the payload when absent (backward-compatible) ==="
rm -f "$PAYLOAD"
OUT_KB2="${TMP}/kb-no-payload.html"
ASM_OUT2=$(bash "$ASSEMBLE_SH" --src "$SRC" --manifest "$MANIFEST" --output "$OUT_KB2" 2>&1)
assert_exit_zero "$?" "ME02a assemble.sh exits 0 with payload absent"
assert_output_contains "$ASM_OUT2" "MD Export: not present" "ME02b assemble.sh reports 'MD Export: not present'"
assert_file_not_contains "$OUT_KB2" 'id="kb-md-export"' "ME02c assembled kb.html omits #kb-md-export when payload absent"

test_summary
