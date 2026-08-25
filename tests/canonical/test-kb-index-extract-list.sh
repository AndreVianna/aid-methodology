#!/usr/bin/env bash
# test-kb-index-extract-list.sh -- unit assertions for the extract_list helper in
# build-kb-index.sh (added in f001 task-002).
#
# Tests:
#   EL01  inline list  -- tags: [a, b, c]         -> 3 items, one per line
#   EL02  block list   -- tags:\n  - a\n  - b      -> 2 items, one per line
#   EL03  empty inline -- tags: []                 -> empty output
#   EL04  absent field -- (no tags: line)          -> empty output
#   EL05  scalar field -- (not a list)             -> empty output (no crash)
#   EL06  inline list with spaces -- [a , b, c]   -> trimmed items
#   EL07  block list with indented dashes          -> items extracted
#   EL08  inline sources with URL entries          -> items extracted
#   EL09  block sources with multiple paths        -> items extracted
#   EL10  extract_list is frontmatter-scoped       -- body list not picked up
#   EL11  objective: present  -> objective used as description (not intent)
#   EL12  objective: absent   -> intent: used as description (backward-compat)
#   EL13  summary: present alongside objective     -> both used in description
#   EL14  full doc with all new fields parses without error
#
# Usage:
#   bash test-kb-index-extract-list.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/canonical/aid/scripts/kb/build-kb-index.sh"

if [[ ! -f "$SCRIPT" ]]; then
    fail "EL00 setup -- build-kb-index.sh not found at $SCRIPT"
    test_summary
    exit 1
fi

# Source only the helper functions from build-kb-index.sh, not the main body.
# We do this by sourcing after overriding the arg-parsing block.
# Strategy: create a minimal loader that sources the helpers via awk extraction.
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Extract only the helper function definitions from build-kb-index.sh.
# We capture everything from a "^# Helper:" comment to the closing "^}" of each
# function, so we get extract_field, extract_literal, and extract_list without
# the arg-parsing / validation / output blocks.
HELPERS_WRAP="${TMPDIR_BASE}/helpers_wrap.sh"
{
    echo "#!/usr/bin/env bash"
    echo "set -u"
    # Extract function bodies: lines starting from "^extract_" or the preceding
    # comment block through the closing brace, up to "# --- Begin output ---".
    awk '/^# --- Begin output ---/{exit} /^extract_[a-z_]+\(\)/{p=1} p{print} /^}$/{p=0}' "$SCRIPT"
} > "$HELPERS_WRAP"

# shellcheck source=/dev/null
source "$HELPERS_WRAP"

# ---------------------------------------------------------------------------
# Fixture builder
# ---------------------------------------------------------------------------
make_doc() {
    local path="$1"
    local content="$2"
    echo "$content" > "$path"
}

# ===========================================================================
# EL01  Inline list
# ===========================================================================
f="${TMPDIR_BASE}/el01.md"
make_doc "$f" "---
kb-category: primary
tags: [alpha, beta, gamma]
---
body"

out=$(extract_list "$f" "tags")
assert_output_contains "$out" "alpha" "EL01 inline list -- alpha present"
assert_output_contains "$out" "beta"  "EL01 inline list -- beta present"
assert_output_contains "$out" "gamma" "EL01 inline list -- gamma present"
count=$(echo "$out" | grep -c .)
assert_eq "$count" "3" "EL01 inline list -- exactly 3 items"

# ===========================================================================
# EL02  Block list
# ===========================================================================
f="${TMPDIR_BASE}/el02.md"
make_doc "$f" "---
kb-category: primary
tags:
  - foo
  - bar
---
body"

out=$(extract_list "$f" "tags")
assert_output_contains "$out" "foo" "EL02 block list -- foo present"
assert_output_contains "$out" "bar" "EL02 block list -- bar present"
count=$(echo "$out" | grep -c .)
assert_eq "$count" "2" "EL02 block list -- exactly 2 items"

# ===========================================================================
# EL03  Empty inline list
# ===========================================================================
f="${TMPDIR_BASE}/el03.md"
make_doc "$f" "---
tags: []
---
body"

out=$(extract_list "$f" "tags")
assert_eq "$out" "" "EL03 empty inline -- empty output"

# ===========================================================================
# EL04  Absent field
# ===========================================================================
f="${TMPDIR_BASE}/el04.md"
make_doc "$f" "---
kb-category: primary
source: hand-authored
---
body"

out=$(extract_list "$f" "tags")
assert_eq "$out" "" "EL04 absent field -- empty output"

# ===========================================================================
# EL05  Scalar field (not a list) -- must not crash, must emit nothing
# ===========================================================================
f="${TMPDIR_BASE}/el05.md"
make_doc "$f" "---
owner: architect
---
body"

out=$(extract_list "$f" "owner")
assert_eq "$out" "" "EL05 scalar field -- empty output (no crash)"

# ===========================================================================
# EL06  Inline list with spaces around commas and items
# ===========================================================================
f="${TMPDIR_BASE}/el06.md"
make_doc "$f" "---
tags: [ alpha , beta ,  gamma ]
---
body"

out=$(extract_list "$f" "tags")
assert_output_contains "$out" "alpha" "EL06 trimmed inline -- alpha"
assert_output_contains "$out" "beta"  "EL06 trimmed inline -- beta"
assert_output_contains "$out" "gamma" "EL06 trimmed inline -- gamma"

# ===========================================================================
# EL07  Block list with deeper indentation
# ===========================================================================
f="${TMPDIR_BASE}/el07.md"
make_doc "$f" "---
see_also:
  - schemas.md
  - architecture.md
---
body"

out=$(extract_list "$f" "see_also")
assert_output_contains "$out" "schemas.md"      "EL07 deeper indent -- schemas.md"
assert_output_contains "$out" "architecture.md" "EL07 deeper indent -- architecture.md"

# ===========================================================================
# EL08  Inline sources with URL entries
# ===========================================================================
f="${TMPDIR_BASE}/el08.md"
make_doc "$f" "---
sources: [https://example.com/spec, src/foo.ts]
---
body"

out=$(extract_list "$f" "sources")
assert_output_contains "$out" "https://example.com/spec" "EL08 URL in inline sources"
assert_output_contains "$out" "src/foo.ts"               "EL08 path in inline sources"

# ===========================================================================
# EL09  Block sources with multiple paths
# ===========================================================================
f="${TMPDIR_BASE}/el09.md"
make_doc "$f" "---
sources:
  - canonical/aid/scripts/kb/build-kb-index.sh
  - tests/canonical/test-kb-index-extract-list.sh
  - https://vendor.example/spec
---
body"

out=$(extract_list "$f" "sources")
assert_output_contains "$out" "canonical/aid/scripts/kb/build-kb-index.sh"     "EL09 block sources -- path1"
assert_output_contains "$out" "tests/canonical/test-kb-index-extract-list.sh"  "EL09 block sources -- path2"
assert_output_contains "$out" "https://vendor.example/spec"                    "EL09 block sources -- url"

# ===========================================================================
# EL10  Body list must not bleed into frontmatter extraction
# ===========================================================================
f="${TMPDIR_BASE}/el10.md"
make_doc "$f" "---
kb-category: primary
---

## Section

- body-item-one
- body-item-two"

out=$(extract_list "$f" "tags")
assert_eq "$out" "" "EL10 body list -- not picked up as tags"

# ===========================================================================
# EL11  objective: present -> used in INDEX description (not intent)
# This test drives build-kb-index.sh via its --root/--output interface.
# ===========================================================================
KB_DIR="${TMPDIR_BASE}/kb11"
mkdir -p "$KB_DIR"
make_doc "${KB_DIR}/mydoc.md" "---
kb-category: primary
source: hand-authored
objective: Noun-phrase objective line
summary: One sentence summary.
sources: []
---

## Body"

OUT11="${TMPDIR_BASE}/INDEX11.md"
bash "$SCRIPT" --root "$KB_DIR" --output "$OUT11" >/dev/null 2>&1
assert_file_contains "$OUT11" "Noun-phrase objective line" "EL11 objective used in INDEX"
assert_file_not_contains "$OUT11" "*(no intent: declared)*" "EL11 no missing-intent placeholder when objective present"

# ===========================================================================
# EL12  objective: absent -> falls back to intent: block
# ===========================================================================
KB_DIR="${TMPDIR_BASE}/kb12"
mkdir -p "$KB_DIR"
make_doc "${KB_DIR}/mylegacy.md" "---
kb-category: primary
source: hand-authored
intent: |
  Legacy intent block content here.
---

## Body"

OUT12="${TMPDIR_BASE}/INDEX12.md"
bash "$SCRIPT" --root "$KB_DIR" --output "$OUT12" >/dev/null 2>&1
assert_file_contains "$OUT12" "Legacy intent block content here." "EL12 intent fallback when objective absent"

# ===========================================================================
# EL13  summary: present alongside objective -> both in description
# ===========================================================================
KB_DIR="${TMPDIR_BASE}/kb13"
mkdir -p "$KB_DIR"
make_doc "${KB_DIR}/myful.md" "---
kb-category: primary
source: hand-authored
objective: Manage feature specifications
summary: Covers creation and lifecycle of features.
sources: []
---

## Body"

OUT13="${TMPDIR_BASE}/INDEX13.md"
bash "$SCRIPT" --root "$KB_DIR" --output "$OUT13" >/dev/null 2>&1
assert_file_contains "$OUT13" "Manage feature specifications" "EL13 objective in description"
assert_file_contains "$OUT13" "Covers creation and lifecycle" "EL13 summary in description"

# ===========================================================================
# EL14  Full doc with all new fields parses without error
# ===========================================================================
f="${TMPDIR_BASE}/el14.md"
make_doc "$f" "---
kb-category: primary
source: hand-authored
objective: Full-field document objective
summary: Covers all eight new frontmatter fields introduced in f001.
sources:
  - canonical/aid/scripts/kb/build-kb-index.sh
  - canonical/aid/templates/kb-authoring/frontmatter-schema.md
tags: [kb, frontmatter, f001]
see_also: [schemas.md, architecture.md]
owner: architect
audience: [architect, developer]
approved_at_commit: a1b2c3d
---
body"

obj=$(extract_field "$f" "objective")
assert_eq "$obj" "Full-field document objective" "EL14 objective parsed"

summ=$(extract_field "$f" "summary")
assert_eq "$summ" "Covers all eight new frontmatter fields introduced in f001." "EL14 summary parsed"

tags_out=$(extract_list "$f" "tags")
assert_output_contains "$tags_out" "kb"          "EL14 tags -- kb"
assert_output_contains "$tags_out" "frontmatter" "EL14 tags -- frontmatter"
assert_output_contains "$tags_out" "f001"        "EL14 tags -- f001"

see_out=$(extract_list "$f" "see_also")
assert_output_contains "$see_out" "schemas.md"      "EL14 see_also -- schemas.md"
assert_output_contains "$see_out" "architecture.md" "EL14 see_also -- architecture.md"

aud_out=$(extract_list "$f" "audience")
assert_output_contains "$aud_out" "architect"  "EL14 audience -- architect"
assert_output_contains "$aud_out" "developer"  "EL14 audience -- developer"

src_out=$(extract_list "$f" "sources")
assert_output_contains "$src_out" "canonical/aid/scripts/kb/build-kb-index.sh"            "EL14 sources -- script"
assert_output_contains "$src_out" "canonical/aid/templates/kb-authoring/frontmatter-schema.md" "EL14 sources -- schema"

own=$(extract_field "$f" "owner")
assert_eq "$own" "architect" "EL14 owner parsed"

approved=$(extract_field "$f" "approved_at_commit")
assert_eq "$approved" "a1b2c3d" "EL14 approved_at_commit parsed"

# ===========================================================================
test_summary
