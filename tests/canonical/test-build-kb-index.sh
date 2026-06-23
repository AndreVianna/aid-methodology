#!/usr/bin/env bash
# test-build-kb-index.sh -- canonical suite for build-kb-index.sh: table render,
# coexistence fallbacks, pipe-escape, see_also links, determinism, edge cases.
#
# Tests:
#   BI01  Full-field doc renders all 6 table cells populated.
#   BI02  intent:-only doc renders Objective+Summary from fallback; Tags/See-instead/Audience blank.
#   BI03  Literal | in a field is escaped to \| in the table cell.
#   BI04  see_also doc-name entries render as [name](../knowledge/name) links.
#   BI05  Output is byte-stable across two consecutive runs (determinism), timestamp lines filtered.
#   BI06  Summary predicate -- v1.1.0 dot is NOT a sentence boundary.
#   BI07  Summary predicate -- 1.4 decimal dot is NOT a sentence boundary.
#   BI08  Summary predicate -- e.g. abbreviation dot is NOT a sentence boundary.
#   BI09  Summary predicate -- i.e. abbreviation dot is NOT a sentence boundary.
#   BI10  Summary predicate -- no sentence terminator -> whole collapsed line is Summary.
#   BI11  Summary predicate -- sentence exceeding 200 chars is truncated to 200 + '...'
#   BI12  Empty-KB guard -- no docs found emits the no-KB-docs notice.
#   BI13  Category grouping -- primary/meta/extension docs appear in correct sections.
#   BI14  Alphabetical sort within a category table.
#   BI15  Empty cell renders as a single space (table stays well-formed).
#   BI16  Table header row emitted once per category (6-column header + separator).
#   BI17  see_also bare token (no .md suffix) renders as link.
#   BI18  see_also prose entry with spaces renders verbatim (not linked).
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-build-kb-index.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/canonical/aid/scripts/kb/build-kb-index.sh"

if [[ ! -f "$SCRIPT" ]]; then
    fail "BI00 setup -- build-kb-index.sh not found at $SCRIPT"
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# Fixture root: throwaway tmpdir, cleaned up on exit.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Helper: write a fixture doc.
make_doc() {
    local path="$1"
    local content="$2"
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$content" > "$path"
}

# Helper: run the script against a KB root and capture the output.
run_index() {
    local kb_root="$1"
    local out_file="$2"
    bash "$SCRIPT" --root "$kb_root" --output "$out_file" >/dev/null 2>&1
}

# Helper: filter timestamp lines from INDEX output so determinism comparison
# ignores the AUTO-GENERATED and "Generated at:" lines.
filter_timestamps() {
    grep -v -E '(AUTO-GENERATED|Generated at:|: Generated$)' "$1"
}

# ===========================================================================
# BI01  Full-field doc renders all 6 table cells populated.
# ===========================================================================
KB01="${TMPDIR_BASE}/kb01"
mkdir -p "$KB01"
make_doc "${KB01}/alpha.md" "---
kb-category: primary
source: hand-authored
objective: Manages the canonical KB doc lifecycle
summary: Covers creation, update, and retirement of KB documents.
tags: [kb, lifecycle, f001]
see_also: [schemas.md]
audience: [architect, developer]
---

## Body section"

OUT01="${TMPDIR_BASE}/INDEX01.md"
run_index "$KB01" "$OUT01"

assert_file_contains "$OUT01" "[alpha.md](../knowledge/alpha.md)" "BI01 Document cell -- link present"
assert_file_contains "$OUT01" "Manages the canonical KB doc lifecycle" "BI01 Objective cell -- populated"
assert_file_contains "$OUT01" "Covers creation, update, and retirement of KB documents." "BI01 Summary cell -- populated"
assert_file_contains "$OUT01" '`kb`' "BI01 Tags cell -- kb present"
assert_file_contains "$OUT01" '`lifecycle`' "BI01 Tags cell -- lifecycle present"
assert_file_contains "$OUT01" '`f001`' "BI01 Tags cell -- f001 present"
assert_file_contains "$OUT01" "[schemas.md](../knowledge/schemas.md)" "BI01 See-instead cell -- link present"
assert_file_contains "$OUT01" "architect, developer" "BI01 Audience cell -- populated"

# Verify the table header row was emitted.
assert_file_contains "$OUT01" "| Document | Objective | Summary | Tags | See-instead | Audience |" \
    "BI01 table header row present"
assert_file_contains "$OUT01" "|----------|-----------|---------|------|-------------|----------|" \
    "BI01 table separator row present"

# ===========================================================================
# BI02  intent:-only doc renders Objective+Summary from fallback;
#       Tags/See-instead/Audience are blank (single space).
# ===========================================================================
KB02="${TMPDIR_BASE}/kb02"
mkdir -p "$KB02"
make_doc "${KB02}/legacy.md" "---
kb-category: primary
source: hand-authored
intent: |
  Governs the AID process lifecycle. Agents must load this doc before any phase.
---

## Body"

OUT02="${TMPDIR_BASE}/INDEX02.md"
run_index "$KB02" "$OUT02"

# Objective: collapsed intent: literal
assert_file_contains "$OUT02" "Governs the AID process lifecycle." "BI02 Objective fallback from intent:"

# Summary: first sentence of collapsed intent: (boundary after "lifecycle.")
assert_file_contains "$OUT02" "Governs the AID process lifecycle." "BI02 Summary first-sentence fallback"

# Tags/See-instead/Audience: blank cell = single space; table stays well-formed.
# Row format: | [legacy.md](...) | <obj> | <sum> | <tags> | <see> | <aud> |
# The data row for an intent:-only doc must have no backtick tags and no audience values.
# Extract the specific data row to avoid matching frontmatter/header backticks.
data_row_02=$(grep "legacy.md" "$OUT02" || true)
assert_output_not_contains "$data_row_02" '`' "BI02 Tags cell -- no backtick tags in data row (blank)"
assert_output_not_contains "$data_row_02" "architect" "BI02 Audience cell -- blank (no audience in data row)"

# ===========================================================================
# BI03  Literal | in a field is escaped to \| in the table cell.
# ===========================================================================
KB03="${TMPDIR_BASE}/kb03"
mkdir -p "$KB03"
make_doc "${KB03}/pipedoc.md" "---
kb-category: primary
source: hand-authored
objective: Handles A | B routing decisions
summary: Routes between A | B based on context.
---

## Body"

OUT03="${TMPDIR_BASE}/INDEX03.md"
run_index "$KB03" "$OUT03"

assert_file_contains "$OUT03" 'A \| B' "BI03 pipe in objective escaped to \|"
assert_file_contains "$OUT03" 'A \| B routing' "BI03 pipe-escaped objective verbatim"

# ===========================================================================
# BI04  see_also doc-name entries render as [name](../knowledge/name) links.
# ===========================================================================
KB04="${TMPDIR_BASE}/kb04"
mkdir -p "$KB04"
make_doc "${KB04}/guide.md" "---
kb-category: primary
source: hand-authored
objective: Primary guide for onboarding
summary: Walk-through of the onboarding steps.
see_also: [architecture.md, schemas.md]
---

## Body"

OUT04="${TMPDIR_BASE}/INDEX04.md"
run_index "$KB04" "$OUT04"

assert_file_contains "$OUT04" "[architecture.md](../knowledge/architecture.md)" \
    "BI04 see_also architecture.md renders as link"
assert_file_contains "$OUT04" "[schemas.md](../knowledge/schemas.md)" \
    "BI04 see_also schemas.md renders as link"

# ===========================================================================
# BI05  Output is byte-stable across two consecutive runs (determinism).
#       Timestamp lines are filtered before comparison.
# ===========================================================================
KB05="${TMPDIR_BASE}/kb05"
mkdir -p "$KB05"
make_doc "${KB05}/stable.md" "---
kb-category: primary
source: hand-authored
objective: Stable determinism test doc
summary: Checks that output is identical across runs.
tags: [determinism]
---

## Body"

OUT05A="${TMPDIR_BASE}/INDEX05a.md"
OUT05B="${TMPDIR_BASE}/INDEX05b.md"
run_index "$KB05" "$OUT05A"
run_index "$KB05" "$OUT05B"

filtered_a="${TMPDIR_BASE}/filtered05a.txt"
filtered_b="${TMPDIR_BASE}/filtered05b.txt"
filter_timestamps "$OUT05A" > "$filtered_a"
filter_timestamps "$OUT05B" > "$filtered_b"

if diff -q "$filtered_a" "$filtered_b" >/dev/null 2>&1; then
    pass "BI05 byte-stable across two runs (timestamp lines filtered)"
else
    fail "BI05 byte-stable across two runs -- outputs differ after timestamp filtering"
    if [[ "$VERBOSE" -eq 1 ]]; then
        diff "$filtered_a" "$filtered_b" || true
    fi
fi

# ===========================================================================
# BI06  Summary predicate -- v1.1.0 dot is NOT a sentence boundary.
# ===========================================================================
KB06="${TMPDIR_BASE}/kb06"
mkdir -p "$KB06"
# The dot in "v1.1.0" is NOT followed by space+uppercase, so it must not split there.
# The real sentence boundary is at the end of the whole intent:.
make_doc "${KB06}/version.md" "---
kb-category: primary
source: hand-authored
intent: |
  Introduced in v1.1.0 this feature handles routing.
---

## Body"

OUT06="${TMPDIR_BASE}/INDEX06.md"
run_index "$KB06" "$OUT06"

# The whole sentence should appear in the Summary cell (not truncated at v1.1.)
assert_file_contains "$OUT06" "Introduced in v1.1.0 this feature handles routing." \
    "BI06 v1.1.0 dot not a sentence boundary"

# ===========================================================================
# BI07  Summary predicate -- 1.4 decimal dot is NOT a sentence boundary.
# ===========================================================================
KB07="${TMPDIR_BASE}/kb07"
mkdir -p "$KB07"
make_doc "${KB07}/decimal.md" "---
kb-category: primary
source: hand-authored
intent: |
  Targets version 1.4 of the specification. All agents must load this.
---

## Body"

OUT07="${TMPDIR_BASE}/INDEX07.md"
run_index "$KB07" "$OUT07"

assert_file_contains "$OUT07" "Targets version 1.4 of the specification." \
    "BI07 decimal 1.4 dot not a sentence boundary"

# ===========================================================================
# BI08  Summary predicate -- e.g. abbreviation dot is NOT a sentence boundary.
# ===========================================================================
KB08="${TMPDIR_BASE}/kb08"
mkdir -p "$KB08"
make_doc "${KB08}/egdoc.md" "---
kb-category: primary
source: hand-authored
intent: |
  Covers edge cases, e.g. abbreviations and decimals. Use this doc for reference.
---

## Body"

OUT08="${TMPDIR_BASE}/INDEX08.md"
run_index "$KB08" "$OUT08"

# "e.g." has a dot after lowercase "g", not space+uppercase, so not a boundary.
# The split should happen after "decimals." (followed by space+uppercase "U").
assert_file_contains "$OUT08" "Covers edge cases, e.g. abbreviations and decimals." \
    "BI08 e.g. dot not a sentence boundary -- first sentence intact"

# ===========================================================================
# BI09  Summary predicate -- i.e. abbreviation dot is NOT a sentence boundary.
# ===========================================================================
KB09="${TMPDIR_BASE}/kb09"
mkdir -p "$KB09"
make_doc "${KB09}/iedoc.md" "---
kb-category: primary
source: hand-authored
intent: |
  Provides the canonical definition, i.e. the one true source. Agents rely on it.
---

## Body"

OUT09="${TMPDIR_BASE}/INDEX09.md"
run_index "$KB09" "$OUT09"

assert_file_contains "$OUT09" "Provides the canonical definition, i.e. the one true source." \
    "BI09 i.e. dot not a sentence boundary -- first sentence intact"

# ===========================================================================
# BI10  Summary predicate -- no sentence terminator -> whole collapsed line.
# ===========================================================================
KB10="${TMPDIR_BASE}/kb10"
mkdir -p "$KB10"
make_doc "${KB10}/noterminator.md" "---
kb-category: primary
source: hand-authored
intent: |
  A KB doc with no terminating punctuation at all
---

## Body"

OUT10="${TMPDIR_BASE}/INDEX10.md"
run_index "$KB10" "$OUT10"

assert_file_contains "$OUT10" "A KB doc with no terminating punctuation at all" \
    "BI10 no sentence boundary -- whole collapsed line used as Summary"

# ===========================================================================
# BI11  Summary predicate -- sentence exceeding 200 chars truncated to 200 + '...'
# ===========================================================================
KB11="${TMPDIR_BASE}/kb11"
mkdir -p "$KB11"

# Build a single-sentence intent: that exceeds 200 chars (this one is 208).
long_sentence="This is a very long single sentence that keeps going and going and going and going and going and going and going and going and going and going and going and going past the two hundred character boundary here."
char_count=${#long_sentence}

make_doc "${KB11}/longdoc.md" "---
kb-category: primary
source: hand-authored
intent: |
  ${long_sentence}
---

## Body"

OUT11="${TMPDIR_BASE}/INDEX11.md"
run_index "$KB11" "$OUT11"

# Must end with '...' (truncated)
assert_file_contains "$OUT11" "..." "BI11 >200-char sentence truncated -- ellipsis present"

# The first 200 chars of the sentence must appear (not more, not less)
first200="${long_sentence:0:200}"
assert_file_contains "$OUT11" "${first200}" "BI11 >200-char sentence -- first 200 chars present"

# The 201st char and beyond must NOT appear in the cell (except as part of '...')
char_201="${long_sentence:200:1}"
# The cell is first200 + "..."  which is first200...
# The 201st char should not appear directly after first200 in the output
# (instead, '...' follows). We check the overall cell ends in "...".
assert_file_contains "$OUT11" "${first200}..." "BI11 >200-char sentence -- truncated to 200+'...'"

# ===========================================================================
# BI12  Empty-KB guard -- no docs found emits the no-KB-docs notice.
# ===========================================================================
KB12="${TMPDIR_BASE}/kb12"
mkdir -p "$KB12"
# Empty directory -- no .md files

OUT12="${TMPDIR_BASE}/INDEX12.md"
run_index "$KB12" "$OUT12"

assert_file_contains "$OUT12" "*(no KB docs found" "BI12 empty KB -- no-docs notice present"

# ===========================================================================
# BI13  Category grouping -- docs appear under correct ## section headers.
# ===========================================================================
KB13="${TMPDIR_BASE}/kb13"
mkdir -p "$KB13"
make_doc "${KB13}/primary-doc.md" "---
kb-category: primary
source: hand-authored
objective: A primary doc
summary: Belongs in the primary section.
---
body"
make_doc "${KB13}/meta-doc.md" "---
kb-category: meta
source: hand-authored
objective: A meta doc
summary: Belongs in the meta section.
---
body"
make_doc "${KB13}/ext-doc.md" "---
kb-category: extension
source: hand-authored
objective: An extension doc
summary: Belongs in the extension section.
---
body"

OUT13="${TMPDIR_BASE}/INDEX13.md"
run_index "$KB13" "$OUT13"

# Category headers
assert_file_contains "$OUT13" "## Primary" "BI13 Primary category header present"
assert_file_contains "$OUT13" "## Meta" "BI13 Meta category header present"
assert_file_contains "$OUT13" "## Extension" "BI13 Extension category header present"

# Each doc in its correct section -- verify by checking the file contains the link
assert_file_contains "$OUT13" "[primary-doc.md](../knowledge/primary-doc.md)" "BI13 primary-doc.md in output"
assert_file_contains "$OUT13" "[meta-doc.md](../knowledge/meta-doc.md)" "BI13 meta-doc.md in output"
assert_file_contains "$OUT13" "[ext-doc.md](../knowledge/ext-doc.md)" "BI13 ext-doc.md in output"

# ===========================================================================
# BI14  Alphabetical sort within a category table.
# ===========================================================================
KB14="${TMPDIR_BASE}/kb14"
mkdir -p "$KB14"
make_doc "${KB14}/zebra.md" "---
kb-category: primary
source: hand-authored
objective: Z comes last alphabetically
summary: Zebra doc.
---
body"
make_doc "${KB14}/alpha.md" "---
kb-category: primary
source: hand-authored
objective: A comes first alphabetically
summary: Alpha doc.
---
body"
make_doc "${KB14}/mango.md" "---
kb-category: primary
source: hand-authored
objective: M comes in the middle
summary: Mango doc.
---
body"

OUT14="${TMPDIR_BASE}/INDEX14.md"
run_index "$KB14" "$OUT14"

# alpha.md must appear before mango.md, which must appear before zebra.md.
alpha_line=$(grep -n "alpha.md" "$OUT14" | head -1 | cut -d: -f1)
mango_line=$(grep -n "mango.md" "$OUT14" | head -1 | cut -d: -f1)
zebra_line=$(grep -n "zebra.md" "$OUT14" | head -1 | cut -d: -f1)

if [[ -n "$alpha_line" && -n "$mango_line" && -n "$zebra_line" ]]; then
    if [[ "$alpha_line" -lt "$mango_line" && "$mango_line" -lt "$zebra_line" ]]; then
        pass "BI14 alphabetical sort -- alpha < mango < zebra"
    else
        fail "BI14 alphabetical sort -- expected alpha($alpha_line) < mango($mango_line) < zebra($zebra_line)"
    fi
else
    fail "BI14 alphabetical sort -- could not find all three docs in output"
fi

# ===========================================================================
# BI15  Empty cell renders as a single space (table well-formedness).
# ===========================================================================
# Use kb02 output which has blank Tags/See-instead/Audience cells.
# The row template is: echo "| ... | ${cell} | ..."
# An empty cell is set to " " (single space), so the output is "| <sp> |"
# with the surrounding " | " separators giving "| <sp> |" -> "|   |" (3 spaces).
assert_file_contains "$OUT02" "|   |" "BI15 blank cell renders as single space (|<sp+sp+sp>| in rendered row)"

# ===========================================================================
# BI16  Table header row emitted once per category (6-column header).
# ===========================================================================
# kb13 has all three categories; each must have exactly one header row.
header_count=$(grep -c "| Document | Objective | Summary | Tags | See-instead | Audience |" "$OUT13")
assert_eq "$header_count" "3" "BI16 table header row emitted once per category (3 categories = 3 headers)"

# ===========================================================================
# BI17  see_also bare token (no .md suffix) renders as link.
# ===========================================================================
KB17="${TMPDIR_BASE}/kb17"
mkdir -p "$KB17"
make_doc "${KB17}/routing.md" "---
kb-category: primary
source: hand-authored
objective: Routing doc
summary: Handles routing decisions.
see_also: [architecture]
---
body"

OUT17="${TMPDIR_BASE}/INDEX17.md"
run_index "$KB17" "$OUT17"

# Bare token "architecture" (no .md, no spaces) -> rendered as link
assert_file_contains "$OUT17" "[architecture](../knowledge/architecture)" \
    "BI17 bare token see_also renders as link"

# ===========================================================================
# BI18  see_also prose entry with spaces renders verbatim (not linked).
# ===========================================================================
KB18="${TMPDIR_BASE}/kb18"
mkdir -p "$KB18"
make_doc "${KB18}/prose.md" "---
kb-category: primary
source: hand-authored
objective: Prose see-also doc
summary: Has a prose see-also entry.
see_also:
  - use the architect role for design decisions
---
body"

OUT18="${TMPDIR_BASE}/INDEX18.md"
run_index "$KB18" "$OUT18"

# Prose entry (contains spaces) -> rendered verbatim, no [...](../knowledge/...) wrapping
assert_file_contains "$OUT18" "use the architect role for design decisions" \
    "BI18 prose see_also entry appears verbatim"
assert_file_not_contains "$OUT18" "[use the architect" \
    "BI18 prose see_also entry NOT wrapped in a markdown link"

# ===========================================================================
test_summary
