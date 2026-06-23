#!/usr/bin/env bash
# test-frontmatter-lint.sh -- canonical test suite for lint-frontmatter.sh (f001 task-003).
#
# Assertion classes:
#   FL01  pre-migration doc (no new fields)           -> skipped (pass, exit 0)
#   FL02  meta doc                                    -> skipped (pass, exit 0)
#   FL03  generated doc                               -> skipped (pass, exit 0)
#   FL04  missing required field: objective:          -> [FM-MISSING] flagged (exit 1)
#   FL05  missing required field: summary:            -> [FM-MISSING] flagged (exit 1)
#   FL06  missing required field: sources:            -> [FM-MISSING] flagged (exit 1)
#   FL07  sources: is a scalar, not a list            -> [FM-INVALID] flagged (exit 1)
#   FL08  sources: entry is a free sentence           -> [FM-INVALID] flagged (exit 1)
#   FL09  approved_at_commit: is not hex              -> [FM-INVALID] flagged (exit 1)
#   FL10  well-formed doc with all required fields    -> passes (exit 0)
#   FL11  well-formed doc with optional fields        -> passes (exit 0)
#   FL12  empty objective: (present but blank)        -> [FM-MISSING] flagged
#   FL13  tags: as scalar instead of list             -> [FM-INVALID] flagged
#   FL14  see_also: as scalar instead of list         -> [FM-INVALID] flagged
#   FL15  audience: as scalar instead of list         -> [FM-INVALID] flagged
#   FL16  approved_at_commit: uppercase hex rejected  -> [FM-INVALID] flagged
#   FL17  sources: [] empty list is valid             -> passes (exit 0)
#   FL18  sources: URL entry is valid                 -> passes (exit 0)
#   FL19  AID's own KB docs all soft-skip (day-one)  -> passes (exit 0)
#
# Usage:
#   bash test-frontmatter-lint.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINT="${REPO_ROOT}/canonical/aid/scripts/kb/lint-frontmatter.sh"
KB_ROOT="${REPO_ROOT}/.aid/knowledge"

if [[ ! -f "$LINT" ]]; then
    fail "FL00 setup -- lint-frontmatter.sh not found at $LINT"
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------
TMPDIR_FL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_FL"' EXIT

make_kb() {
    # make_kb <dir> <filename> <frontmatter-content>
    # Wraps the content in --- delimiters and adds a body.
    local dir="$1" name="$2" fm="$3"
    mkdir -p "$dir"
    printf -- '---\n%s\n---\n\n# Body\n' "$fm" > "${dir}/${name}"
}

run_lint() {
    local root="$1"
    bash "$LINT" --root "$root" 2>&1
}

# ===========================================================================
# FL01  Pre-migration doc (no new f001 fields) -- must be soft-skipped
# ===========================================================================
D="${TMPDIR_FL}/fl01"; mkdir -p "$D"
make_kb "$D" "legacy.md" "kb-category: primary
source: hand-authored
intent: |
  Legacy doc with only old-schema fields."

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL01 pre-migration soft-skip -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL01 pre-migration soft-skip -- no FM-MISSING"
assert_output_not_contains "$out" "[FM-INVALID]" "FL01 pre-migration soft-skip -- no FM-INVALID"

# ===========================================================================
# FL02  Meta doc -- must be skipped
# ===========================================================================
D="${TMPDIR_FL}/fl02"; mkdir -p "$D"
make_kb "$D" "readme.md" "kb-category: meta
source: hand-authored"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL02 meta skip -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL02 meta skip -- no findings"

# ===========================================================================
# FL03  Generated doc -- must be skipped
# ===========================================================================
D="${TMPDIR_FL}/fl03"; mkdir -p "$D"
make_kb "$D" "INDEX.md" "kb-category: primary
source: generated
generator: build-kb-index.sh"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL03 generated skip -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL03 generated skip -- no findings"

# ===========================================================================
# FL04  Missing required field: objective:
# ===========================================================================
D="${TMPDIR_FL}/fl04"; mkdir -p "$D"
make_kb "$D" "noobjective.md" "kb-category: primary
source: hand-authored
summary: One sentence summary.
sources: []"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL04 missing objective -- exit nonzero"
assert_output_contains "$out" "[FM-MISSING]" "FL04 missing objective -- FM-MISSING emitted"
assert_output_contains "$out" "objective"    "FL04 missing objective -- mentions field name"

# ===========================================================================
# FL05  Missing required field: summary:
# ===========================================================================
D="${TMPDIR_FL}/fl05"; mkdir -p "$D"
make_kb "$D" "nosummary.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
sources: []"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL05 missing summary -- exit nonzero"
assert_output_contains "$out" "[FM-MISSING]" "FL05 missing summary -- FM-MISSING emitted"
assert_output_contains "$out" "summary"      "FL05 missing summary -- mentions field name"

# ===========================================================================
# FL06  Missing required field: sources:
# ===========================================================================
D="${TMPDIR_FL}/fl06"; mkdir -p "$D"
make_kb "$D" "nosources.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary."

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL06 missing sources -- exit nonzero"
assert_output_contains "$out" "[FM-MISSING]" "FL06 missing sources -- FM-MISSING emitted"
assert_output_contains "$out" "sources"      "FL06 missing sources -- mentions field name"

# ===========================================================================
# FL07  sources: is a scalar (not a list)
# ===========================================================================
D="${TMPDIR_FL}/fl07"; mkdir -p "$D"
make_kb "$D" "scalsrc.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: this is a scalar not a list"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL07 scalar sources -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL07 scalar sources -- FM-INVALID emitted"
assert_output_contains "$out" "sources"      "FL07 scalar sources -- mentions field name"

# ===========================================================================
# FL08  sources: entry is a free sentence (not a path/glob/URL)
# ===========================================================================
D="${TMPDIR_FL}/fl08"; mkdir -p "$D"
make_kb "$D" "proseentry.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources:
  - This is a prose sentence describing a source file."

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL08 prose sources entry -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL08 prose sources entry -- FM-INVALID emitted"

# ===========================================================================
# FL09  approved_at_commit: is not hex
# ===========================================================================
D="${TMPDIR_FL}/fl09"; mkdir -p "$D"
make_kb "$D" "badhex.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: []
approved_at_commit: not-a-hex-value"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL09 bad approved_at_commit -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]"         "FL09 bad approved_at_commit -- FM-INVALID emitted"
assert_output_contains "$out" "approved_at_commit"   "FL09 bad approved_at_commit -- mentions field name"

# ===========================================================================
# FL10  Well-formed doc with all three required fields -- must pass
# ===========================================================================
D="${TMPDIR_FL}/fl10"; mkdir -p "$D"
make_kb "$D" "wellformed.md" "kb-category: primary
source: hand-authored
objective: The doc objective as a noun phrase.
summary: One sentence describing scope of this document.
sources:
  - canonical/aid/scripts/kb/lint-frontmatter.sh
  - canonical/aid/templates/kb-authoring/frontmatter-schema.md"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL10 well-formed -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL10 well-formed -- no FM-MISSING"
assert_output_not_contains "$out" "[FM-INVALID]" "FL10 well-formed -- no FM-INVALID"

# ===========================================================================
# FL11  Well-formed doc with optional fields -- must pass
# ===========================================================================
D="${TMPDIR_FL}/fl11"; mkdir -p "$D"
make_kb "$D" "fullfields.md" "kb-category: primary
source: hand-authored
objective: The doc objective as a noun phrase.
summary: One sentence describing scope of this document.
sources:
  - canonical/aid/scripts/kb/lint-frontmatter.sh
tags: [kb, lint, f001]
see_also: [schemas.md, architecture.md]
owner: architect
audience: [architect, developer]
approved_at_commit: a1b2c3d"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL11 full optional fields -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL11 full optional fields -- no FM-MISSING"
assert_output_not_contains "$out" "[FM-INVALID]" "FL11 full optional fields -- no FM-INVALID"

# ===========================================================================
# FL12  Empty objective: (present but blank)
# ===========================================================================
D="${TMPDIR_FL}/fl12"; mkdir -p "$D"
make_kb "$D" "emptyobj.md" "kb-category: primary
source: hand-authored
objective:
summary: One sentence summary.
sources: []"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL12 empty objective -- exit nonzero"
assert_output_contains "$out" "[FM-MISSING]" "FL12 empty objective -- FM-MISSING emitted"

# ===========================================================================
# FL13  tags: as scalar instead of list
# ===========================================================================
D="${TMPDIR_FL}/fl13"; mkdir -p "$D"
make_kb "$D" "scaltags.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: []
tags: not-a-list-just-a-scalar"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL13 scalar tags -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL13 scalar tags -- FM-INVALID emitted"
assert_output_contains "$out" "tags"         "FL13 scalar tags -- mentions field name"

# ===========================================================================
# FL14  see_also: as scalar instead of list
# ===========================================================================
D="${TMPDIR_FL}/fl14"; mkdir -p "$D"
make_kb "$D" "scalseealso.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: []
see_also: scalar-not-list"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL14 scalar see_also -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL14 scalar see_also -- FM-INVALID emitted"
assert_output_contains "$out" "see_also"     "FL14 scalar see_also -- mentions field name"

# ===========================================================================
# FL15  audience: as scalar instead of list
# ===========================================================================
D="${TMPDIR_FL}/fl15"; mkdir -p "$D"
make_kb "$D" "scalaud.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: []
audience: scalar-not-list"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL15 scalar audience -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL15 scalar audience -- FM-INVALID emitted"
assert_output_contains "$out" "audience"     "FL15 scalar audience -- mentions field name"

# ===========================================================================
# FL16  approved_at_commit: uppercase hex -- should be rejected (must be lowercase)
# ===========================================================================
D="${TMPDIR_FL}/fl16"; mkdir -p "$D"
make_kb "$D" "upperhex.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources: []
approved_at_commit: A1B2C3D"

out=$(run_lint "$D"); code=$?
assert_exit_nonzero "$code"        "FL16 uppercase hex -- exit nonzero"
assert_output_contains "$out" "[FM-INVALID]" "FL16 uppercase hex -- FM-INVALID emitted"

# ===========================================================================
# FL17  sources: [] empty list is valid (pure-synthesis doc)
# ===========================================================================
D="${TMPDIR_FL}/fl17"; mkdir -p "$D"
make_kb "$D" "emptysrc.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective for a synthesis doc.
summary: One sentence summary for a synthesis doc.
sources: []"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL17 empty sources list -- exit 0"
assert_output_not_contains "$out" "[FM-MISSING]" "FL17 empty sources list -- no FM-MISSING"
assert_output_not_contains "$out" "[FM-INVALID]" "FL17 empty sources list -- no FM-INVALID"

# ===========================================================================
# FL18  sources: URL entry is valid
# ===========================================================================
D="${TMPDIR_FL}/fl18"; mkdir -p "$D"
make_kb "$D" "urlsrc.md" "kb-category: primary
source: hand-authored
objective: A noun-phrase objective.
summary: One sentence summary.
sources:
  - https://vendor.example/spec
  - https://docs.example.com/api/v2"

out=$(run_lint "$D"); code=$?
assert_exit_zero "$code"           "FL18 URL sources -- exit 0"
assert_output_not_contains "$out" "[FM-INVALID]" "FL18 URL sources -- no FM-INVALID"

# ===========================================================================
# FL19  AID's own KB docs all soft-skip on day one (no migration yet)
# ===========================================================================
if [[ -d "$KB_ROOT" ]]; then
    out=$(run_lint "$KB_ROOT"); code=$?
    assert_exit_zero "$code"           "FL19 AID KB day-one soft-skip -- exit 0"
    assert_output_not_contains "$out" "[FM-MISSING]" "FL19 AID KB day-one soft-skip -- no FM-MISSING"
    assert_output_not_contains "$out" "[FM-INVALID]" "FL19 AID KB day-one soft-skip -- no FM-INVALID"
else
    fail "FL19 setup -- KB root not found: $KB_ROOT"
fi

# ===========================================================================
test_summary
