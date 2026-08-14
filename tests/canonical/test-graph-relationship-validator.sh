#!/usr/bin/env bash
# test-graph-relationship-validator.sh -- the V1-V15 relationship-table linter.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# A trailing slash means the directory and everything under it. Omitting the
# header entirely is fail-safe (the suite is then always selected); a WRONG
# entry is the only way to lose coverage, so these are reviewed as claims.
# COVERS: canonical/aid/scripts/graph/validate-relationships.sh
# COVERS: canonical/aid/templates/graph/relation-vocabulary.yml
# COVERS: canonical/aid/templates/graph/relationship-schema.yml
#
# Scope:
#   canonical/aid/scripts/graph/validate-relationships.sh -- the read-only linter
#   that grades a `.aid/knowledge/relationships.md` against its contract (work-005,
#   feature-003). Its sibling suite, test-graph-schema-loader.sh, covers the
#   sourceable library this script consumes.
#
# S1 -- SUBJECT INVOCATION BUDGET: 41 subprocess spawns, one per distinct fixture or
#   flag combination; no in-process calls, because there is no library to source here
#   -- the subject is a standalone script whose own arg parsing, exit-code contract
#   and frontmatter/table scan only a real process boundary exercises end to end.
#   That is the opposite shape from the sibling loader suite, and it is why every
#   fixture below is grouped by which INDEPENDENT defects can share one artifact
#   (see "Runtime" below) rather than run singly: each spawn costs ~4s on Windows Git
#   Bash, so 41 is already most of a minute of pure process creation and a fixture
#   that could share an existing spawn must.
#
# S3 -- WHY THIS SUITE CARRIES NO `--self-mutate`, DESPITE BEING SUBPROCESS-BASED.
#   Six sibling graph suites gate a MUTATION MATRIX -- mutating a COPY of the
#   SUBJECT'S OWN SOURCE and re-running assertions to prove a regression would be
#   caught -- behind that flag, because for those subjects a fixture-only rejection
#   case cannot exercise every code path a source mutation can. That extra layer has
#   no work to do here: every rejecting fixture below is already a direct,
#   guard-verified (anchor present, unique, and actually changed -- `mutate()`'s three
#   checks) trigger of the ONE finding it names, paired one-for-one with an accepting
#   case from the same clean baseline, which is the non-vacuous pairing S3 asks for.
#   Adding a second, subject-source-mutating layer on top would be new scope, not a
#   gap this task's added assertions leave open -- so none is added.
#
# What is asserted:
#   Every one of V1-V15 gets BOTH halves -- a fixture the check accepts and a
#   fixture it rejects. A linter that passed everything and one that failed
#   everything would each fail half of this suite. The clean fixture additionally
#   asserts that NO gating tag appears, so a check that fires spuriously is caught
#   rather than being read as thoroughness.
#
#   Also asserted: the two advisories never gate (they print and the run still exits
#   0); the exit-code contract 0/1/2; that `--help` documents exactly the flags the
#   script parses; that the class-0 extraction refuses to print on a defective
#   table; and, per AC-19, that a fixed Kind row reporting `absent`/`0` -- a carrier
#   convention a project genuinely lacks -- is a well-formed outcome and never a
#   REL-COVERAGE finding, which V14c's rejection of an invalid status does not by
#   itself prove (rejecting 'unknown' says nothing about whether 'absent' is the
#   second accepted member of that two-value enum or missing from it entirely).
#
# Orientation safety, which is the one place normalisation could make a report lie:
#   Three of the clean fixture's six rows carry their ids in ascending order with the
#   REVERSE-direction label in the S2T column -- the form the orientation rule stores.
#   For those rows the forward-direction endpoint token is observable ONLY through the
#   row's reverse reading, so the unobserved-token advisory must credit both readings
#   each row asserts. An implementation crediting the stored S2T alone loses the other
#   half of roughly every asymmetric pair.
#
#   The whole advisory output for the clean fixture is therefore pinned EXACTLY: six
#   whole-line matches plus the finding count, which forecloses a seventh. That shape
#   is not decoration. The first draft asserted the ABSENCE of one message shape, and
#   mutation testing showed a validator that dropped the reverse credit simply reported
#   those relations on a DIFFERENT shape (the grouped "no row used these at all" line),
#   so all three assertions passed against a demonstrably broken subject.
#
# AC-MAP -- feature-003's AC-1..AC-20 and AC-S1..AC-S3 (SPEC.md), read against this
# suite's and test-graph-schema-loader.sh's actual assertion ids. Built by work-005
# task-004, because no per-AC map existed before it (task-001's own AC-MAP, in the
# sibling suite, is scoped to feature-001's AC-S1..AC-S6 only). A row with no id is a
# genuine gap the map exists to surface, not a formality; two were found and closed by
# this task (marked NEW below) and none were left open.
#
#   AC-1  (each id resolves by the protocol for its own Kind; ext: proven on a
#         self-built fixture per Q4/A-6, since this repo's external-sources.md
#         registers no keys) -- CLEAN01 (all six rows, one per non-ext Kind plus one
#         ext: web-page, resolve) + V02a-f (one negative per protocol: ext: key
#         unregistered, int: path missing, fact token absent, section slug absent,
#         concept with no definition, document outside the scan set). The ext:
#         `image` sub-case (D1a's unrecoverable-from-the-key arm) resolves via
#         V13-POS's `ext:remote-logo`. The concept exactly-one/qualified-form branch
#         is a library-level property (test-graph-schema-loader.sh KB39/KB40) that V2
#         calls through `rel_resolve_id`, plus V02e/V15d at the validator boundary.
#   AC-2  (both relation labels merged-vocabulary members and a valid inverse pair;
#         symmetric same-label rows are valid) -- V03 (REL-VOCAB), V04 (REL-PAIR),
#         V04-POS (a symmetric row is accepted, pinned present in the clean fixture).
#   AC-2a (Source/Target Kind in the closed enum and agrees with its id's prefix,
#         including the branching `image` case) -- V13a-f (both tiers, one violation
#         per row) + V13-POS (`image` + `ext:` MUST pass, the branching case AC-2a
#         calls out by name).
#   AC-3  (no relationship recorded twice, neither as a repeat nor as a forward row
#         plus a separate inverse row) -- V05a (verbatim repeat), V05b (the mirror,
#         swapped triples and swapped labels, collapsing to the same row key).
#   AC-4  (provenance exactly one of three, never empty) -- V06 (case violation),
#         V06b (value outside the closed enum); "never empty" is V1's generic
#         required-column check (V01c), which runs the same code path for every
#         required column including Provenance, so no Provenance-specific empty
#         fixture is a separate code path to miss.
#   AC-5  (byte-identity of the class-0 block and the whole Coverage notes section,
#         over all of FR-11's staleness inputs unchanged) -- task-004's own Scope
#         bounds this to "a self-built fixture, not this repository's own KB": CON09
#         (the extraction succeeds on a conforming table), CON10 (header included),
#         CON11 (stops before the first inferred row), CON12 (frontmatter excluded),
#         CON13/CON14 (refuses -- prints nothing -- on a table failing V10), CON15/16
#         (two runs of the REPORT are byte-identical). The Coverage-notes half of the
#         same comparison is V14's whole group. What is NOT closed here, by the task's
#         own scope: byte-identity across two live regenerations, which needs
#         feature-005's generator and does not exist yet.
#   AC-16 (table side: no `int:` id carries any fragment; `kb:` ids may) -- V07
#         (`int:tool.sh#main` rejected) + the clean fixture's own ROW_C/D/E (`kb:`
#         fact/section/concept fragments, all accepted).
#   AC-18 (relationships.md carries frontmatter valid for the index generator) --
#         V09a (required key absent), V09b (required key empty), V09c/V09d (a
#         timestamp in the marker / in a row), V09e/V09f (a pipe / a block scalar in
#         a single-line field), V09g (frontmatter not the file's first content).
#   AC-19 (a kind with zero nodes and Status `absent` is well-formed, not a schema
#         violation) -- **NEW, this task**: V14-AC19a/b. No assertion existed before:
#         V14c only proves the enum REJECTS a value outside {present, absent}, which
#         does not by itself prove `absent` is the accepted second member rather than
#         missing from the accepted set entirely.
#   AC-20 (every enum kind appears in the notes, in order, including a zero count,
#         plus the FR-22 exclusion statuses) -- CLEAN01/02 (the clean fixture itself
#         carries all seven kinds, four of them at a `0` count, and all three
#         exclusion rows) + V14h/i (removing a fixed kind/exclusion row is GATING,
#         which is what makes the clean fixture's completeness an enforced property
#         and not an unchecked convention).
#   AC-S1 (ten columns, `Kind` adjacent to its id, no `Strength` column) -- V01a
#         (9-cell row), V01b (unpadded cell), V01d/V01e (header/delimiter not
#         byte-equal the carrier's ten-column form), V01f (CRLF rejected).
#   AC-S2 (a parser reaches the table's end without reading the notes) -- CLEAN02
#         ("Checked: 6 rows" pinned exactly against a fixture whose Coverage notes
#         carry two further pipe-tables; an implementation that kept reading past the
#         boundary would inflate that count) + V14l (the notes-above-table ordering
#         defect is reported distinctly, which is what proves the boundary is an
#         actively checked position and not an assumed one).
#   AC-S3 (D7a-1's extra-row total order: fixed-first/contiguous, charset, no
#         fixed-key collision, uniqueness, `LC_ALL=C` order, matching cell count) --
#         V14a (charset), V14b (cell count), V14e (fixed-key collision), V14f
#         (uniqueness), V14g (order), V14h/i (fixed-first -- a missing fixed row lands
#         the wrong key at a fixed position, the same code path an inserted-above row
#         would hit). The clean fixture's own notes carry the D7a-1 worked example's
#         six extra keys in the SPEC's own order, which V14g's shuffle is checked
#         against.
#
# Fixtures:
#   Self-built under a mktemp dir, removed on EXIT. Nothing here reads or references
#   `.aid/works/` -- work folders are transient and this suite must outlive them.
#
#   The vocabulary is a FIXTURE with placeholder relation labels, placeholder
#   categories and placeholder standards keys. That is deliberate on two counts: no
#   shipped vocabulary value enters the test tree, and a small vocabulary cuts each
#   invocation's load from ~2.6 s to ~0.3 s. The real core vocabulary is exercised by
#   the loader suite, where the assertion is about it.
#
# Runtime, and why the fixtures are grouped:
#   Each invocation costs ~4 s on Windows Git Bash (process start plus two carrier
#   loads plus a KB scan), so one fixture per defect would be minutes of forking.
#   Independent defects therefore share a fixture, each planted on a DIFFERENT row or
#   in a different section -- and every assertion names the tag, the LINE, and the
#   reason substring, all three of which must appear on one output line. That is what
#   stops a finding raised by one mutation from being read as another mutation's
#   check firing. Line numbers are DERIVED from the fixture at runtime by
#   `row_line`, never written down.
#
# Usage:
#   bash test-graph-relationship-validator.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all assertions pass
#   1 -- one or more assertions failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

VALIDATOR="${REPO_ROOT}/canonical/aid/scripts/graph/validate-relationships.sh"
SCHEMA="${REPO_ROOT}/canonical/aid/templates/graph/relationship-schema.yml"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$VALIDATOR" "PRE validator present"
assert_file_exists "$SCHEMA" "PRE schema carrier present"

KB="$TMP/kb"
KB2="$TMP/kb-ambig"
REPO="$TMP/repo"
FIXVOCAB="$TMP/vocab.yml"
EXTSRC="$KB/external-sources.md"
CLEAN="$TMP/clean.md"

mkdir -p "$KB" "$KB2" "$REPO/img"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# mutate <label> <src> <dst> <find> <replace>
#   Literal, PATTERN-anchored fixture mutation with three guards -- present, UNIQUE,
#   and actually-changed -- each of which FAILS the suite rather than yielding a
#   fixture that exercises nothing. Uniqueness is the guard earned the hard way: an
#   anchor that also matches a comment edits the comment, leaves the data intact and
#   looks fine. Every mutation below anchors on a WHOLE table row or a whole
#   frontmatter line, which is unique in these fixtures by construction.
mutate() {
    local label="$1" src="$2" dst="$3" find="$4" repl="$5" body new rest occurrences
    body="$(<"$src")"
    case "$body" in
        *"$find"*) ;;
        *) fail "$label — FIXTURE BUG: anchor absent from $(basename "$src"): '$find'"; return 1 ;;
    esac
    occurrences=0
    rest="$body"
    while [[ "$rest" == *"$find"* ]]; do
        occurrences=$((occurrences + 1))
        rest="${rest#*"$find"}"
        [[ $occurrences -gt 1 ]] && break
    done
    if [[ $occurrences -gt 1 ]]; then
        fail "$label — FIXTURE BUG: anchor is AMBIGUOUS in $(basename "$src"): '$find'"
        return 1
    fi
    new="${body/"$find"/"$repl"}"
    if [[ "$new" == "$body" ]]; then
        fail "$label — FIXTURE BUG: the replacement left the fixture byte-identical"
        return 1
    fi
    printf '%s\n' "$new" > "$dst"
    return 0
}

# row_line <file> <unique-substring> -> the 1-based line number, DERIVED not written.
row_line() {
    grep -n -F -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1
}

RC=0
OUT=""
VERR=""

# run_v <fixture> [extra flags...]
run_v() {
    local f="$1"; shift
    RC=0
    bash "$VALIDATOR" --file "$f" \
        --schema "$SCHEMA" --vocabulary "$FIXVOCAB" \
        --kb-root "$KB" --repo-root "$REPO" --external-sources "$EXTSRC" \
        "$@" >"$TMP/out.txt" 2>"$TMP/err.txt" || RC=$?
    OUT="$(<"$TMP/out.txt")"
    VERR="$(<"$TMP/err.txt")"
}

# The four matchers below test their conditions IN PROCESS, with no grep and no pipe.
# Two reasons, and both are this repo's own scars:
#
#   * A `grep -F | grep -F | grep -qF` chain has the trailing `-q` exit on its first
#     match, which SIGPIPEs the grep upstream of it. Under `set -o pipefail` that
#     flips the whole pipeline non-zero and the assertion reports "pattern not found"
#     against output that contains it. tests/lib/assert.sh carries the same note; a
#     CI run on Linux caught it there (work-001 PAR100-H02). This suite sets only
#     `set -u` today, so nothing is broken right now -- but an assertion whose
#     correctness depends on a shell option no one has set yet is a trap left armed.
#   * Forking costs ~100 ms on Windows Git Bash. Three or four greps across ~70
#     matcher calls is most of a minute of pure process creation.

# expect_finding <label> <tag> <line> <reason-substring>
#   The tag, the line and the reason must all appear on ONE output line. Requiring
#   all three together is what stops a finding produced by a different mutation in
#   the same grouped fixture from being read as this check firing. Mutation testing
#   confirms the line dimension is load-bearing: collapsing every reported line
#   number to a constant flips 33 assertions and nothing else.
expect_finding() {
    local label="$1" tag="$2" ln="$3" sub="$4" line
    if [[ -z "$ln" ]]; then
        fail "$label — FIXTURE BUG: could not derive the fixture's line number"
        return
    fi
    while IFS= read -r line; do
        if [[ "$line" == *"[$tag]"* && "$line" == *"line $ln:"* && "$line" == *"$sub"* ]]; then
            pass "$label"; return
        fi
    done <<< "$OUT"
    fail "$label — no [$tag] finding on line $ln carrying '$sub'"
    [[ $VERBOSE -eq 1 ]] && { echo "---OUTPUT---"; printf '%s\n' "$OUT"; echo "---END---"; }
    return 0
}

# expect_finding_global <label> <tag> <reason-substring>   (a whole-table finding)
expect_finding_global() {
    local label="$1" tag="$2" sub="$3" line
    while IFS= read -r line; do
        if [[ "$line" == *"[$tag]"* && "$line" == *"$sub"* ]]; then
            pass "$label"; return
        fi
    done <<< "$OUT"
    fail "$label — no [$tag] finding carrying '$sub'"
    [[ $VERBOSE -eq 1 ]] && { echo "---OUTPUT---"; printf '%s\n' "$OUT"; echo "---END---"; }
    return 0
}

# expect_exact <label> <tag> <file> <message>
#   The WHOLE output line, matched with `grep -xF`. Required wherever the assertion
#   is about a LIST: a substring match on "... token(s): fact->document" also succeeds
#   when the real list is "fact->document section->document", so a check that lost half
#   its input passes a substring assertion. Mutation testing found exactly that hole
#   in this suite's first draft, where three orientation assertions asserted the
#   ABSENCE of one message shape and a broken validator simply emitted the relation on
#   a different one.
expect_exact() {
    local label="$1" tag="$2" f="$3" msg="$4" line
    while IFS= read -r line; do
        if [[ "$line" == "[$tag] $f: $msg" ]]; then pass "$label"; return; fi
    done <<< "$OUT"
    fail "$label — no line exactly: [$tag] <file>: $msg"
    [[ $VERBOSE -eq 1 ]] && { echo "---OUTPUT---"; printf '%s\n' "$OUT"; echo "---END---"; }
    return 0
}

# expect_no_finding <label> <tag> <substring-that-must-not-appear>
expect_no_finding() {
    local label="$1" tag="$2" sub="$3" line
    while IFS= read -r line; do
        if [[ "$line" == *"[$tag]"* && "$line" == *"$sub"* ]]; then
            fail "$label — a [$tag] finding carrying '$sub' was raised and must not be: $line"
            return 0
        fi
    done <<< "$OUT"
    pass "$label"
    return 0
}

GATING_TAGS=(REL-SHAPE REL-UNRESOLVED REL-VOCAB REL-PAIR REL-DUPLICATE REL-PROVENANCE
             REL-GRANULARITY REL-IDENTITY REL-FRONTMATTER REL-ORDER REL-OBSERVATION
             REL-KIND REL-COVERAGE)

# ===========================================================================
# Fixtures. The vocabulary carries placeholder labels only; its endpoint sets are
# authored so that every row shape below is legal AND so that two relations have a
# declared token no row reaches (which is what gives the per-run advisory something
# to report) and one relation deliberately excludes `document->concept` (which is
# what gives the per-row advisory something to report).
# ===========================================================================
cat > "$FIXVOCAB" <<'EOF'
pairs:

  - relation: aaa-holds
    inverse: aaa-held-by
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section", "document->fact"]
    passes: [declared, derived]
    definition: "The source holds the target as one of its own constituents."

  - relation: aaa-held-by
    inverse: aaa-holds
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "fact->document"]
    passes: [declared, derived]
    definition: "The source is held by the target as one of its constituents."

  - relation: bbb-names
    inverse: bbb-named-by
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermTwo"]
    endpoint_kinds: ["section->concept"]
    passes: [declared]
    definition: "The source introduces the term the target is."

  - relation: bbb-named-by
    inverse: bbb-names
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermTwo"]
    endpoint_kinds: ["concept->section"]
    passes: [declared]
    definition: "The source is the term the target introduces."

  - relation: ccc-shows
    inverse: ccc-shown-by
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermThree"]
    endpoint_kinds: ["source-artifact->image", "document->image"]
    passes: [declared, derived]
    definition: "The source is depicted by the target."

  - relation: ccc-shown-by
    inverse: ccc-shows
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermThree"]
    endpoint_kinds: ["image->source-artifact", "image->document"]
    passes: [declared, derived]
    definition: "The source depicts the target."

  - relation: ddd-cites
    inverse: ddd-cited-by
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermFour"]
    endpoint_kinds: ["document->web-page", "fact->source-artifact"]
    passes: [declared]
    definition: "The source names the target as its checkable support."

  - relation: ddd-cited-by
    inverse: ddd-cites
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermFour"]
    endpoint_kinds: ["web-page->document", "source-artifact->fact"]
    passes: [declared]
    definition: "The source is named by the target as its checkable support."

  - relation: eee-mirrors
    inverse: eee-mirrors
    symmetry: symmetric
    category: cat-one
    derived_from: ["std:TermFive"]
    endpoint_kinds: ["document->document", "section->section"]
    passes: [declared, inferred]
    definition: "The source and the target present overlapping material."

  - relation: fff-unused
    inverse: fff-unused-by
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermSix"]
    endpoint_kinds: ["concept->concept"]
    passes: [declared]
    definition: "The source stands in a relation no fixture row exercises."

  - relation: fff-unused-by
    inverse: fff-unused
    symmetry: asymmetric
    category: cat-two
    derived_from: ["std:TermSix"]
    endpoint_kinds: ["concept->concept"]
    passes: [declared]
    definition: "The source stands in the converse relation no fixture row exercises."

categories:
  - "cat-one|A first placeholder category."
  - "cat-two|A second placeholder category."
EOF

cat > "$KB/alpha.md" <<'EOF'
# Alpha

## Overview

Some prose citing `README.md` (search: "A full-lifecycle methodology") as its evidence.

An anchor-less citation of `docs/notes.md`, with nothing to grep for.

### Widget

**Definition:** A widget is a thing that does a thing.

```bash
# a heading-shaped line inside a fence must NOT close a block
**Definition:** and a marker inside a fence must NOT qualify one
```

## Overview

A second heading with the same text, so its slug takes the ordinal.
EOF
printf '# Beta\n\n## Notes\n\nBeta refers to alpha.\n' > "$KB/beta.md"
cat > "$EXTSRC" <<'EOF'
# External Sources

## Sources

| Key | Origin | Contributed to |
|-----|--------|----------------|
| `remote-logo` | https://example.invalid/logo.png | alpha.md |
| `wcag-22-aa` | https://example.invalid/wcag | alpha.md |
EOF
printf '#!/usr/bin/env bash\necho tool\n' > "$REPO/tool.sh"
printf 'not-really-a-png\n' > "$REPO/img/logo.png"

# The ambiguity KB: the same term defined twice, plus a near-plural pair. Used only
# by the concept advisory, which scans the Knowledge Base and not the table.
cp "$KB/alpha.md" "$KB/beta.md" "$EXTSRC" "$KB2/"
cat >> "$KB2/beta.md" <<'EOF'

### Widget

**Definition:** a second, different definition of a term already defined.

### Widgets

**Definition:** the plural form, which is deliberately not folded into the singular.
EOF

# The clean artifact. Three of its six rows are stored FLIPPED by the orientation
# rule (their ids sort the other way), which is what makes the orientation
# assertions below meaningful rather than decorative.
cat > "$CLEAN" <<'EOF'
---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: Every recorded relationship among Knowledge Base documents, sections, facts and concepts, project source artifacts, images and web pages, with both readings named on one row.
summary: Read this to trace which Knowledge Base claim is backed by which source artifact or external source; it is the single input to the graph view.
tags: [C2, relationships, graph, provenance, coverage, routing]
owner: architect
---
<!-- AUTO-GENERATED by aid/scripts/graph/build-relationships.sh -- regenerate with /aid-graph. Do not edit. -->

# Relationships

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | declared | |
| int:img/logo.png | image | img/logo.png | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | ccc-shows | declared | |
| int:tool.sh | source-artifact | tool.sh | kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology | fact | alpha.md § A full-lifecycle methodology | ddd-cited-by | ddd-cites | declared | |
| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |
| kb:alpha.md#widget | section | alpha.md § Widget | kb:concept:widget | concept | Widget | bbb-names | bbb-named-by | declared | |
| kb:alpha.md | document | alpha.md | kb:beta.md | document | beta.md | eee-mirrors | eee-mirrors | inferred | Both documents describe overlapping material. |

## Coverage notes

### Node kinds

| Kind | Carrier convention | Status | Nodes |
|------|--------------------|--------|-------|
| document | KB documents under `.aid/knowledge/` | present | 3 |
| concept | definition marker under a level-3+ heading | present | 1 |
| fact | checkable source anchor (path + grep-recoverable string) | present | 1 |
| section | ATX headings, levels 2-6 | present | 4 |
| source-artifact | project source, per FR-21 significance | present | 1 |
| image | image files in-repo; external image keys | present | 1 |
| web-page | entries in the external-sources file | present | 2 |
| concept-merge-candidates | terms with more than one definition | present | 0 |
| concept-qualified | concept ids emitted in the qualified form | present | 0 |
| fact-unanchored | markers skipped for want of an anchor string | present | 1 |
| image-external | external image keys distinguished by media type | absent | 0 |
| section-empty-slug | headings whose slug came out empty | present | 0 |
| source-artifact-dropped | paths dropped below the significance floor | present | 0 |

### Enumeration exclusions

| Exclusion | Applied | Note |
|-----------|---------|------|
| generated/derived trees | yes | unconditional (FR-22) |
| vendored third-party code | yes | unconditional (FR-22) |
| `.aid/settings.yml` ignore list | no | setting absent -- ignore list unavailable |
EOF

# Whole-row anchors, each unique in the fixture by construction.
ROW_A='| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | declared | |'
ROW_B='| int:img/logo.png | image | img/logo.png | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | ccc-shows | declared | |'
ROW_C='| int:tool.sh | source-artifact | tool.sh | kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology | fact | alpha.md § A full-lifecycle methodology | ddd-cited-by | ddd-cites | declared | |'
ROW_D='| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |'
ROW_E='| kb:alpha.md#widget | section | alpha.md § Widget | kb:concept:widget | concept | Widget | bbb-names | bbb-named-by | declared | |'
ROW_F='| kb:alpha.md | document | alpha.md | kb:beta.md | document | beta.md | eee-mirrors | eee-mirrors | inferred | Both documents describe overlapping material. |'

# ===========================================================================
# === CLEAN: the accepting half of every check, in one run ==================
# ===========================================================================
echo ""
echo "=== CLEAN: a conforming artifact passes, and NO gating check fires ==="

run_v "$CLEAN"
assert_exit_eq "$RC" 0 "CLEAN01 a conforming artifact exits 0"
assert_output_contains "$OUT" "Checked: 6 rows" \
    "CLEAN02 the trailer reports the row count in its fixed shape"

# The strongest form of the accepting half: not merely "no failure" but "no gating
# tag at all". A check that fires spuriously is caught here rather than being
# mistaken for diligence.
for tag in "${GATING_TAGS[@]}"; do
    assert_output_not_contains "$OUT" "[$tag]" "CLEAN03 no [$tag] on a conforming artifact"
done

# The two advisories DO print, and the run still exits 0 -- that is what "advisory"
# means, and an advisory that gated would fail CLEAN01.
assert_output_contains "$OUT" "[REL-ENDPOINT-UNUSED]" \
    "CLEAN04 the unobserved-token advisory prints on a clean artifact"
assert_exit_eq "$RC" 0 "CLEAN05 advisories never gate: findings present, exit still 0"
assert_output_contains "$OUT" "| Findings: 6" \
    "CLEAN06 the clean artifact's finding count is 6 -- the six advisory lines below and nothing else"

echo ""
echo "=== ORIENT: both readings of every row are credited ==="

# This is the one place normalisation could make a report lie, so the whole advisory
# output is pinned EXACTLY -- six lines, matched whole, plus the count above that
# forecloses a seventh. Nothing here is a substring or an absence-of-one-shape claim.
#
# Rows A, B and C carry their ids in ascending order with the REVERSE-direction label
# in the S2T column, which is how the orientation rule stores them. So for those rows
# the forward-direction token is observable only through the row's reverse reading. An
# implementation crediting the stored S2T alone loses it.
#
# `ddd-cites` and `ddd-cited-by` are the sharpest case: every token either declares is
# reachable only that way, so a correct run says NOTHING about them -- they are neither
# incomplete nor unused. A validator crediting one reading only reports them in the
# grouped "no row used these relations at all" line, which is why ORIENT02/03 assert
# the relation is absent from the advisory ENTIRELY rather than absent from one line
# shape. ORIENT01's exact token list is what closes that grouped line.
expect_exact "ORIENT01 the grouped line names EXACTLY the two genuinely unused relations" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "no row used these relations at all, so every token each declares is unobserved: fff-unused fff-unused-by"
expect_no_finding "ORIENT02 'ddd-cites' is fully observed -- via reverse readings only -- so it is named nowhere" \
    REL-ENDPOINT-UNUSED "ddd-cites"
expect_no_finding "ORIENT03 'ddd-cited-by' is fully observed via forward readings, so it is named nowhere" \
    REL-ENDPOINT-UNUSED "ddd-cited-by"
expect_exact "ORIENT04 'aaa-held-by' misses ONLY fact->document, so section->document was credited from row D's reverse reading" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "relation 'aaa-held-by' has rows but no row exercised its declared endpoint token(s): fact->document"
expect_exact "ORIENT05 'ccc-shows' misses ONLY document->image, so source-artifact->image was credited from row B's reverse reading" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "relation 'ccc-shows' has rows but no row exercised its declared endpoint token(s): document->image"
expect_exact "ORIENT06 'aaa-holds' misses ONLY document->fact (the forward reading of row D was credited)" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "relation 'aaa-holds' has rows but no row exercised its declared endpoint token(s): document->fact"
expect_exact "ORIENT07 'ccc-shown-by' misses ONLY image->document" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "relation 'ccc-shown-by' has rows but no row exercised its declared endpoint token(s): image->document"
expect_exact "ORIENT08 'eee-mirrors' (symmetric) misses ONLY section->section" \
    REL-ENDPOINT-UNUSED "$CLEAN" \
    "relation 'eee-mirrors' has rows but no row exercised its declared endpoint token(s): section->section"
expect_no_finding "ORIENT09 'bbb-named-by' is fully observed via row E's reverse reading, so it is named nowhere" \
    REL-ENDPOINT-UNUSED "bbb-named-by"

# ===========================================================================
# === V1 [REL-SHAPE] =======================================================
# ===========================================================================
echo ""
echo "=== V1 [REL-SHAPE]: the ten-column byte grammar ==="

mutate "V01a" "$CLEAN" "$TMP/v1a.md" "$ROW_A" \
    '| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | declared |' \
    && mutate "V01b" "$TMP/v1a.md" "$TMP/v1a.md" "$ROW_B" \
        '|int:img/logo.png|image|img/logo.png|int:tool.sh|source-artifact|tool.sh|ccc-shown-by|ccc-shows|declared| |' \
    && mutate "V01c" "$TMP/v1a.md" "$TMP/v1a.md" "$ROW_D" \
        '| kb:alpha.md | | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |' \
    && {
        run_v "$TMP/v1a.md"
        assert_exit_eq "$RC" 1 "V01 a shape defect is GATING (exit 1)"
        expect_finding "V01a a row with nine cells" REL-SHAPE \
            "$(row_line "$TMP/v1a.md" 'ddd-cited-by | ddd-cites | declared |')" "9 cells, want 10"
        # The padding finding is keyed "line N cell M:", not "line N:", so the line
        # number goes INSIDE the reason substring rather than through the standard
        # three-part matcher. It is the same discrimination either way: tag, line and
        # reason must land on one output line.
        expect_finding_global "V01b a cell with no padding" REL-SHAPE \
            "line $(row_line "$TMP/v1a.md" '|int:img/logo.png|') cell 1: cell is not ' <content> '"
        expect_finding "V01c a required column left empty" REL-SHAPE \
            "$(row_line "$TMP/v1a.md" '| kb:alpha.md | | alpha.md |')" "required column 'Source Kind' is empty"
    }

mutate "V01d" "$CLEAN" "$TMP/v1d.md" \
    '| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |' \
    '| Src Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |' \
    && mutate "V01e" "$TMP/v1d.md" "$TMP/v1d.md" \
        '|---|---|---|---|---|---|---|---|---|---|' '|---|---|---|---|---|---|---|---|---|' \
    && {
        run_v "$TMP/v1d.md"
        expect_finding "V01d the header row is not byte-equal the carrier's column list" REL-SHAPE \
            "$(row_line "$TMP/v1d.md" '| Src Id |')" "header row is not byte-equal"
        expect_finding "V01e the delimiter row has the wrong cell count" REL-SHAPE \
            "$(row_line "$TMP/v1d.md" '|---|---|---|---|---|---|---|---|---|')" "delimiter row is not byte-equal"
    }

# Line endings are LF only, including the last line -- the emission rule this repo
# needs because it is authored on Windows.
#
# The fixture guard counts BYTES rather than grepping for the CR. MSYS grep strips a
# trailing CR before matching, so `grep -q $'\r'` reports "no CR present" on a file
# that carries one -- a guard that fails on a correct fixture, which is the same class
# of lie as an assertion that passes on a broken one. One injected CR is exactly one
# byte, so the comparison is exact.
awk -v tgt='| kb:alpha.md#widget |' '
    index($0, tgt) == 1 { printf "%s\r\n", $0; next }
    { printf "%s\n", $0 }
' "$CLEAN" > "$TMP/v1f.md"
if [[ "$(wc -c < "$TMP/v1f.md")" -ne "$(( $(wc -c < "$CLEAN") + 1 ))" ]]; then
    fail "V01f a CRLF line ending — FIXTURE BUG: expected exactly one added byte, got $(( $(wc -c < "$TMP/v1f.md") - $(wc -c < "$CLEAN") ))"
else
    run_v "$TMP/v1f.md"
    expect_finding_global "V01f a CRLF line ending is rejected" REL-SHAPE "carries CR characters"
fi

# ===========================================================================
# === V2 [REL-UNRESOLVED] -- one per resolution protocol ===================
# ===========================================================================
echo ""
echo "=== V2 [REL-UNRESOLVED]: each id resolves by the protocol for its own Kind ==="

cp "$CLEAN" "$TMP/v2.md"
mutate "V02a" "$TMP/v2.md" "$TMP/v2.md" "$ROW_A" \
    '| ext:unregistered-key | web-page | unregistered-key | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | declared | |' \
    && mutate "V02b" "$TMP/v2.md" "$TMP/v2.md" "$ROW_B" \
        '| int:img/missing.png | image | img/missing.png | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | ccc-shows | declared | |' \
    && mutate "V02c" "$TMP/v2.md" "$TMP/v2.md" "$ROW_C" \
        '| int:tool.sh | source-artifact | tool.sh | kb:alpha.md#fact:readme-md--not-a-real-anchor | fact | alpha.md § A full-lifecycle methodology | ddd-cited-by | ddd-cites | declared | |' \
    && mutate "V02d" "$TMP/v2.md" "$TMP/v2.md" "$ROW_D" \
        '| kb:alpha.md | document | alpha.md | kb:alpha.md#no-such-heading | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |' \
    && mutate "V02e" "$TMP/v2.md" "$TMP/v2.md" "$ROW_E" \
        '| kb:alpha.md#widget | section | alpha.md § Widget | kb:concept:no-such-term | concept | Widget | bbb-names | bbb-named-by | declared | |' \
    && mutate "V02f" "$TMP/v2.md" "$TMP/v2.md" "$ROW_F" \
        '| kb:alpha.md | document | alpha.md | kb:absent.md | document | absent.md | eee-mirrors | eee-mirrors | inferred | Both documents describe overlapping material. |' \
    && {
        run_v "$TMP/v2.md"
        assert_exit_eq "$RC" 1 "V02 an unresolvable id is GATING (exit 1)"
        expect_finding "V02a an ext: key absent from the registry" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'ext:unregistered-key')" "unregistered-external-key"
        expect_finding "V02b an int: image path that does not exist" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'int:img/missing.png')" "no-such-file"
        expect_finding "V02c a fact token that recomputes to nothing" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'not-a-real-anchor')" "no-such-fact-anchor"
        expect_finding "V02d a heading slug that recomputes to nothing" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'kb:alpha.md#no-such-heading')" "no-such-section"
        expect_finding "V02e a concept with no definition block" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'kb:concept:no-such-term')" "no-such-concept-definition"
        expect_finding "V02f a document outside the KB scan set" REL-UNRESOLVED \
            "$(row_line "$TMP/v2.md" 'kb:absent.md')" "no-such-document"
    }

# ===========================================================================
# === V3 / V4 / V6 / V7 -- independent, one per row =========================
# ===========================================================================
echo ""
echo "=== V3 V4 V6 V7: vocabulary membership, pairing, provenance, granularity ==="

cp "$CLEAN" "$TMP/v3467.md"
mutate "V03" "$TMP/v3467.md" "$TMP/v3467.md" "$ROW_A" \
    '| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | document | beta.md | zz-not-a-relation | ddd-cites | declared | |' \
    && mutate "V04" "$TMP/v3467.md" "$TMP/v3467.md" "$ROW_B" \
        '| int:img/logo.png | image | img/logo.png | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | aaa-holds | declared | |' \
    && mutate "V07" "$TMP/v3467.md" "$TMP/v3467.md" "$ROW_C" \
        '| int:tool.sh#main | source-artifact | tool.sh | kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology | fact | alpha.md § A full-lifecycle methodology | ddd-cited-by | ddd-cites | declared | |' \
    && mutate "V06" "$TMP/v3467.md" "$TMP/v3467.md" "$ROW_D" \
        '| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | Declared | alpha.md "Overview" |' \
    && {
        run_v "$TMP/v3467.md"
        assert_exit_eq "$RC" 1 "V03467 each of these defects is GATING (exit 1)"
        expect_finding "V03 a relation label outside the merged vocabulary" REL-VOCAB \
            "$(row_line "$TMP/v3467.md" 'zz-not-a-relation')" "is not a member of the merged vocabulary"
        expect_finding "V04 two valid labels that are not an inverse pair" REL-PAIR \
            "$(row_line "$TMP/v3467.md" '| ccc-shown-by | aaa-holds |')" "is not an inverse pair in either orientation"
        expect_finding "V07 an int: id carrying a '#' fragment" REL-GRANULARITY \
            "$(row_line "$TMP/v3467.md" 'int:tool.sh#main')" "carries a '#' fragment"
        expect_finding "V06 a Provenance that is not lowercase" REL-PROVENANCE \
            "$(row_line "$TMP/v3467.md" '| Declared |')" "is not one of: declared derived inferred"
    }

# A symmetric relation's row carries the SAME label in both columns, and that is
# VALID rather than the two directions disagreeing -- the edge case a naive pairing
# check gets wrong. CLEAN03's no-[REL-PAIR] result is the acceptance; this assertion
# is what makes that result mean something, by pinning that the clean fixture really
# does carry a row of that shape. Without it the acceptance is indistinguishable from
# a fixture that lost the case, which is the difference between a passing test and a
# test of nothing.
assert_eq "$(grep -cF '| eee-mirrors | eee-mirrors |' "$CLEAN")" "1" \
    "V04-POS the clean fixture carries exactly one symmetric row (same label in both columns), so CLEAN03's no-[REL-PAIR] result is an acceptance of that shape"

echo ""
echo "=== V6b / V11: the enum's other half, and the Observation constraints ==="

cp "$CLEAN" "$TMP/v611.md"
mutate "V06b" "$TMP/v611.md" "$TMP/v611.md" "$ROW_A" \
    '| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | asserted | |' \
    && mutate "V11a" "$TMP/v611.md" "$TMP/v611.md" "$ROW_D" \
        '| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | This row was obvious from reading the document. |' \
    && mutate "V11b" "$TMP/v611.md" "$TMP/v611.md" "$ROW_F" \
        '| kb:alpha.md | document | alpha.md | kb:beta.md | document | beta.md | eee-mirrors | eee-mirrors | inferred | alpha.md:42 |' \
    && {
        run_v "$TMP/v611.md"
        expect_finding "V06b a Provenance outside the closed enum" REL-PROVENANCE \
            "$(row_line "$TMP/v611.md" '| asserted |')" "is not one of: declared derived inferred"
        expect_finding "V11a free prose in Observation on a class-0 row" REL-OBSERVATION \
            "$(row_line "$TMP/v611.md" 'This row was obvious')" "must be empty or a durable anchor"
        expect_finding "V11b a bare file.ext:LINE citation on any row" REL-OBSERVATION \
            "$(row_line "$TMP/v611.md" 'alpha.md:42')" "bare file.ext:LINE citation"
    }

# ===========================================================================
# === V5 [REL-DUPLICATE] -- both halves of the criterion ====================
# ===========================================================================
echo ""
echo "=== V5 [REL-DUPLICATE]: a repeat AND a separately written inverse row ==="

mutate "V05a" "$CLEAN" "$TMP/v5a.md" "$ROW_D" "$ROW_D
$ROW_D" \
    && {
        run_v "$TMP/v5a.md"
        assert_exit_eq "$RC" 1 "V05a a duplicate is GATING (exit 1)"
        expect_finding_global "V05a a verbatim repeated row" REL-DUPLICATE "is already recorded on line"
    }

# The mirror carries the swapped triples and the swapped labels: a different row,
# the same relationship. It must collapse to the same key.
mutate "V05b" "$CLEAN" "$TMP/v5b.md" "$ROW_D" "$ROW_D
| kb:alpha.md#overview | section | alpha.md § Overview | kb:alpha.md | document | alpha.md | aaa-held-by | aaa-holds | declared | alpha.md \"Overview\" |" \
    && {
        run_v "$TMP/v5b.md"
        expect_finding_global "V05b the same relationship written in the opposite orientation" \
            REL-DUPLICATE "written in the opposite orientation"
    }

# ===========================================================================
# === V8 [REL-IDENTITY] ====================================================
# ===========================================================================
echo ""
echo "=== V8 [REL-IDENTITY]: a name is DERIVED, and an id carries one name and one Kind ==="

cp "$CLEAN" "$TMP/v8.md"
mutate "V08a" "$TMP/v8.md" "$TMP/v8.md" "$ROW_D" \
    '| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |' \
    && mutate "V08b" "$TMP/v8.md" "$TMP/v8.md" "$ROW_F" \
        '| kb:alpha.md | document | Alpha Doc | kb:beta.md | document | beta.md | eee-mirrors | eee-mirrors | inferred | Both documents describe overlapping material. |' \
    && mutate "V08c" "$TMP/v8.md" "$TMP/v8.md" "$ROW_E" \
        '| kb:alpha.md#widget | section | | kb:concept:widget | concept | Widget | bbb-names | bbb-named-by | declared | |' \
    && {
        run_v "$TMP/v8.md"
        assert_exit_eq "$RC" 1 "V08 an identity defect is GATING (exit 1)"
        expect_finding "V08a a Name that is not the derived name for its Kind" REL-IDENTITY \
            "$(row_line "$TMP/v8.md" '| section | Overview |')" "the rule for Kind 'section' derives"
        expect_finding "V08b one id carrying two different names" REL-IDENTITY \
            "$(row_line "$TMP/v8.md" 'Alpha Doc')" "carries name 'Alpha Doc' here and"
        expect_finding "V08c an empty Name" REL-IDENTITY \
            "$(row_line "$TMP/v8.md" '| kb:alpha.md#widget | section | |')" "Name is empty"
    }

mutate "V08d" "$CLEAN" "$TMP/v8d.md" "$ROW_A" \
    '| ext:wcag-22-aa | web-page | wcag-22-aa | kb:beta.md | section | beta.md | ddd-cited-by | ddd-cites | declared | |' \
    && {
        run_v "$TMP/v8d.md"
        # The finding lands on the SECOND row to carry the id and names the FIRST by
        # line, which is the useful orientation -- a reader needs both sites, not one.
        # So the assertion pins both: the report's own line is row F's, and the line
        # it cites is row A's. Asserting only "the tag appeared somewhere" would pass
        # for a check that named one site and left the reader to hunt for the other.
        expect_finding "V08d one id carrying two different Kinds, with BOTH sites named" REL-IDENTITY \
            "$(row_line "$TMP/v8d.md" "$ROW_F")" \
            "id 'kb:beta.md' carries Kind 'document' here and 'section' on line $(row_line "$TMP/v8d.md" '| kb:beta.md | section |')"
    }

# ===========================================================================
# === V9 [REL-FRONTMATTER] =================================================
# ===========================================================================
echo ""
echo "=== V9 [REL-FRONTMATTER]: the emitted block, and the timestamp ban ==="

cp "$CLEAN" "$TMP/v9.md"
mutate "V09a" "$TMP/v9.md" "$TMP/v9.md" \
    'objective: Every recorded relationship among Knowledge Base documents, sections, facts and concepts, project source artifacts, images and web pages, with both readings named on one row.
' '' \
    && mutate "V09b" "$TMP/v9.md" "$TMP/v9.md" \
        'summary: Read this to trace which Knowledge Base claim is backed by which source artifact or external source; it is the single input to the graph view.' \
        'summary:' \
    && mutate "V09c" "$TMP/v9.md" "$TMP/v9.md" \
        'regenerate with /aid-graph' 'regenerated 2026-08-05' \
    && {
        run_v "$TMP/v9.md"
        assert_exit_eq "$RC" 1 "V09 a frontmatter defect is GATING (exit 1)"
        expect_finding_global "V09a a required frontmatter key absent" REL-FRONTMATTER \
            "frontmatter key 'objective' is absent"
        expect_finding_global "V09b a required frontmatter key present but empty" REL-FRONTMATTER \
            "frontmatter key 'summary' is empty"
        expect_finding "V09c a timestamp in the AUTO-GENERATED marker" REL-FRONTMATTER \
            "$(row_line "$TMP/v9.md" 'regenerated 2026-08-05')" "a timestamp appears in the table or the AUTO-GENERATED marker"
    }

mutate "V09d" "$CLEAN" "$TMP/v9d.md" "$ROW_D" \
    '| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | section | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview 2026-08-05" |' \
    && {
        run_v "$TMP/v9d.md"
        expect_finding "V09d a timestamp inside a table row" REL-FRONTMATTER \
            "$(row_line "$TMP/v9d.md" 'Overview 2026-08-05')" "a timestamp appears in the table"
    }

cp "$CLEAN" "$TMP/v9e.md"
mutate "V09e" "$TMP/v9e.md" "$TMP/v9e.md" \
    'objective: Every recorded' 'objective: A pipe | inside the objective, which the index cell escaper cannot carry. Every recorded' \
    && mutate "V09f" "$TMP/v9e.md" "$TMP/v9e.md" \
        'summary: Read this to trace which Knowledge Base claim is backed by which source artifact or external source; it is the single input to the graph view.' \
        'summary: |' \
    && {
        run_v "$TMP/v9e.md"
        expect_finding_global "V09e objective carrying a pipe" REL-FRONTMATTER "contains a '|'"
        expect_finding_global "V09f summary written as a block scalar" REL-FRONTMATTER "is a block scalar"
    }

{ printf 'A stray line above the frontmatter.\n'; cat "$CLEAN"; } > "$TMP/v9g.md"
run_v "$TMP/v9g.md"
expect_finding_global "V09g the frontmatter block is not the first content in the file" \
    REL-FRONTMATTER "not the first content in the file"

# ===========================================================================
# === V10 [REL-ORDER] ======================================================
# ===========================================================================
echo ""
echo "=== V10 [REL-ORDER]: the recomputed total order, and the class-0 prefix ==="

mutate "V10a" "$CLEAN" "$TMP/v10a.md" "$ROW_B
$ROW_C" "$ROW_C
$ROW_B" \
    && {
        run_v "$TMP/v10a.md"
        assert_exit_eq "$RC" 1 "V10a a mis-ordered table is GATING (exit 1)"
        expect_finding_global "V10a two rows transposed out of the recomputed sort order" \
            REL-ORDER "is not the recomputed (class, source id, target id, S2T, T2S) LC_ALL=C ascending order"
    }

# Moving the inferred row above a class-0 row breaks the contiguous prefix. Both
# clauses fire, and both are asserted: sort-order correctness implies contiguity, so
# the contiguity clause can never fire alone -- which is why it is asserted here
# alongside rather than isolated in a fixture that cannot exist.
mutate "V10b0" "$CLEAN" "$TMP/v10b.md" "$ROW_F
" "" \
    && mutate "V10b" "$TMP/v10b.md" "$TMP/v10b.md" "$ROW_B" "$ROW_F
$ROW_B" \
    && {
        run_v "$TMP/v10b.md"
        expect_finding_global "V10b1 a class-0 row after a class-1 row breaks the sort order" \
            REL-ORDER "is not the recomputed"
        expect_finding_global "V10b2 ... and the contiguous-prefix clause names it directly" \
            REL-ORDER "the deterministic block must be a contiguous prefix"
    }

# ===========================================================================
# === V12 [REL-ENDPOINT] -- advisory, per row ===============================
# ===========================================================================
echo ""
echo "=== V12 [REL-ENDPOINT]: an advisory the prefix-keyed form could not see ==="

# `bbb-names` declares section->concept and NOT document->concept. Both endpoints
# are `kb:` ids, so the superseded prefix-keyed check saw the same pair either way
# and could not raise this at all.
mutate "V12" "$CLEAN" "$TMP/v12.md" "$ROW_E" \
    '| kb:alpha.md | document | alpha.md | kb:concept:widget | concept | Widget | bbb-names | bbb-named-by | declared | |' \
    && {
        run_v "$TMP/v12.md"
        expect_finding "V12 a row whose kind pair the chosen relation does not declare" REL-ENDPOINT \
            "$(row_line "$TMP/v12.md" '| kb:alpha.md | document | alpha.md | kb:concept:widget |')" \
            "does not declare the endpoint pair 'document->concept'"
        assert_exit_eq "$RC" 0 "V12-ADV the per-row endpoint advisory does NOT gate (exit 0)"
    }

# ===========================================================================
# === V13 [REL-KIND] -- both tiers, spread one per row ======================
# ===========================================================================
echo ""
echo "=== V13 [REL-KIND]: the kind/prefix pairing and the kind/grammar agreement ==="

cp "$CLEAN" "$TMP/v13.md"
mutate "V13a" "$TMP/v13.md" "$TMP/v13.md" "$ROW_A" \
    '| ext:wcag-22-aa | document | wcag-22-aa | kb:beta.md | document | beta.md | ddd-cited-by | ddd-cites | declared | |' \
    && mutate "V13b" "$TMP/v13.md" "$TMP/v13.md" "$ROW_B" \
        '| int:img/logo.png | source-artifact | img/logo.png | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | ccc-shows | declared | |' \
    && mutate "V13c" "$TMP/v13.md" "$TMP/v13.md" "$ROW_C" \
        '| int:tool.sh | image | tool.sh | kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology | fact | alpha.md § A full-lifecycle methodology | ddd-cited-by | ddd-cites | declared | |' \
    && mutate "V13d" "$TMP/v13.md" "$TMP/v13.md" "$ROW_D" \
        '| kb:alpha.md | document | alpha.md | kb:alpha.md#overview | document | alpha.md § Overview | aaa-holds | aaa-held-by | declared | alpha.md "Overview" |' \
    && mutate "V13e" "$TMP/v13.md" "$TMP/v13.md" "$ROW_E" \
        '| kb:alpha.md#widget | gadget | alpha.md § Widget | kb:concept:widget | concept | Widget | bbb-names | bbb-named-by | declared | |' \
    && mutate "V13f" "$TMP/v13.md" "$TMP/v13.md" "$ROW_F" \
        '| kb:alpha.md | image | alpha.md | kb:beta.md | document | beta.md | eee-mirrors | eee-mirrors | inferred | Both documents describe overlapping material. |' \
    && {
        run_v "$TMP/v13.md"
        assert_exit_eq "$RC" 1 "V13 a kind defect is GATING (exit 1)"
        expect_finding "V13a tier 1: document does not permit the ext: prefix" REL-KIND \
            "$(row_line "$TMP/v13.md" '| ext:wcag-22-aa | document |')" "permits prefix(es) 'kb', not 'ext'"
        expect_finding "V13b tier 2: an int: image extension typed source-artifact" REL-KIND \
            "$(row_line "$TMP/v13.md" '| int:img/logo.png | source-artifact |')" "is 'image', not 'source-artifact'"
        expect_finding "V13c tier 2: an int: non-image extension typed image" REL-KIND \
            "$(row_line "$TMP/v13.md" '| int:tool.sh | image |')" "is 'source-artifact', not 'image'"
        expect_finding "V13d tier 2: a kb: id whose own grammar implies another kind" REL-KIND \
            "$(row_line "$TMP/v13.md" '| kb:alpha.md#overview | document |')" "implies kind 'section'"
        expect_finding "V13e a Kind outside the closed enum entirely" REL-KIND \
            "$(row_line "$TMP/v13.md" '| gadget |')" "is not in the Kind enum"
        expect_finding "V13f tier 1: image does not permit the kb: prefix" REL-KIND \
            "$(row_line "$TMP/v13.md" '| kb:alpha.md | image |')" "permits prefix(es) 'int ext', not 'kb'"
    }

# The POSITIVE half of the branching case, and it is the one that matters: an
# implementation rejecting every external image passes a suite of rejections. This
# fixture adds an `image` node carried on an `ext:` prefix and must PASS.
mutate "V13-POS" "$CLEAN" "$TMP/v13pos.md" "$ROW_A" \
    '| ext:remote-logo | image | remote-logo | int:tool.sh | source-artifact | tool.sh | ccc-shown-by | ccc-shows | declared | |
'"$ROW_A" \
    && mutate "V13-POSb" "$TMP/v13pos.md" "$TMP/v13pos.md" \
        '| image | image files in-repo; external image keys | present | 1 |' \
        '| image | image files in-repo; external image keys | present | 2 |' \
    && {
        run_v "$TMP/v13pos.md"
        assert_exit_eq "$RC" 0 "V13-POS an 'image' node on an 'ext:' prefix MUST PASS (the branching case)"
        assert_output_contains "$OUT" "Checked: 7 rows" "V13-POSb ... and the added row is checked"
    }

# ===========================================================================
# === V14 [REL-COVERAGE] ===================================================
# ===========================================================================
echo ""
echo "=== V14 [REL-COVERAGE]: the section's shape, its position, and the extra-row order ==="

cp "$CLEAN" "$TMP/v14a.md"
mutate "V14a" "$TMP/v14a.md" "$TMP/v14a.md" \
    '| concept-qualified | concept ids emitted in the qualified form | present | 0 |' \
    '| Concept-Qualified | concept ids emitted in the qualified form | present | 0 |' \
    && mutate "V14b" "$TMP/v14a.md" "$TMP/v14a.md" \
        '| section-empty-slug | headings whose slug came out empty | present | 0 |' \
        '| section-empty-slug | headings whose slug came out empty | present |' \
    && mutate "V14c" "$TMP/v14a.md" "$TMP/v14a.md" \
        '| web-page | entries in the external-sources file | present | 2 |' \
        '| web-page | entries in the external-sources file | unknown | 2 |' \
    && mutate "V14d" "$TMP/v14a.md" "$TMP/v14a.md" \
        '| section | ATX headings, levels 2-6 | present | 4 |' \
        '| section | ATX headings, levels 2-6 | present | many |' \
    && {
        run_v "$TMP/v14a.md"
        assert_exit_eq "$RC" 1 "V14 a coverage-notes defect is GATING (exit 1)"
        expect_finding_global "V14a an extra key breaking the [a-z0-9][a-z0-9-]* charset" \
            REL-COVERAGE "extra key 'Concept-Qualified' must match"
        expect_finding "V14b an extra row whose cell count differs from its host table" REL-COVERAGE \
            "$(row_line "$TMP/v14a.md" '| section-empty-slug | headings whose slug came out empty | present |')" \
            "cells; the '### Node kinds' table carries 4"
        expect_finding "V14c a Status outside present/absent" REL-COVERAGE \
            "$(row_line "$TMP/v14a.md" '| unknown | 2 |')" "is not 'present' or 'absent'"
        expect_finding "V14d a node count that is not a non-negative integer" REL-COVERAGE \
            "$(row_line "$TMP/v14a.md" '| present | many |')" "is not a non-negative integer"
    }

cp "$CLEAN" "$TMP/v14e.md"
mutate "V14e" "$TMP/v14e.md" "$TMP/v14e.md" \
    '| concept-qualified | concept ids emitted in the qualified form | present | 0 |' \
    '| document | concept ids emitted in the qualified form | present | 0 |' \
    && mutate "V14f" "$TMP/v14e.md" "$TMP/v14e.md" \
        '| fact-unanchored | markers skipped for want of an anchor string | present | 1 |' \
        '| image-external | markers skipped for want of an anchor string | present | 1 |' \
    && {
        run_v "$TMP/v14e.md"
        expect_finding_global "V14e an extra key equal to a FIXED key of the same table" \
            REL-COVERAGE "repeats fixed key 'document' below the fixed block"
        expect_finding_global "V14f the same extra key twice in one table" \
            REL-COVERAGE "carries extra key 'image-external' more than once"
    }

mutate "V14g" "$CLEAN" "$TMP/v14g.md" \
    '| concept-merge-candidates | terms with more than one definition | present | 0 |
| concept-qualified | concept ids emitted in the qualified form | present | 0 |' \
    '| concept-qualified | concept ids emitted in the qualified form | present | 0 |
| concept-merge-candidates | terms with more than one definition | present | 0 |' \
    && {
        run_v "$TMP/v14g.md"
        expect_finding_global "V14g extra rows out of LC_ALL=C ascending key order" \
            REL-COVERAGE "are not in LC_ALL=C ascending key order"
    }

cp "$CLEAN" "$TMP/v14h.md"
mutate "V14h" "$TMP/v14h.md" "$TMP/v14h.md" \
    '| image | image files in-repo; external image keys | present | 1 |
' '' \
    && mutate "V14i" "$TMP/v14h.md" "$TMP/v14h.md" \
        '| vendored third-party code | yes | unconditional (FR-22) |
' '' \
    && {
        run_v "$TMP/v14h.md"
        expect_finding_global "V14h a fixed kind row missing from the enum-ordered block" \
            REL-COVERAGE "the fixed set must appear first, complete and in its fixed order"
        expect_finding_global "V14i an FR-22 exclusion row missing" \
            REL-COVERAGE "'### Enumeration exclusions' table has"
    }

mutate "V14j" "$CLEAN" "$TMP/v14j.md" \
    '| generated/derived trees | yes | unconditional (FR-22) |' \
    '| generated/derived trees | yes | applied 2026-08-05 |' \
    && {
        run_v "$TMP/v14j.md"
        expect_finding "V14j a timestamp anywhere in the Coverage notes section" REL-COVERAGE \
            "$(row_line "$TMP/v14j.md" 'applied 2026-08-05')" "a timestamp appears in the Coverage notes section"
    }

awk '/^## Coverage notes$/ { exit } { print }' "$CLEAN" > "$TMP/v14k.md"
if grep -q '^## Coverage notes' "$TMP/v14k.md"; then
    fail "V14k the section absent — FIXTURE BUG: the section survived the truncation"
else
    run_v "$TMP/v14k.md"
    expect_finding_global "V14k the '## Coverage notes' section absent entirely" \
        REL-COVERAGE "section is absent; it is required on EVERY run"
fi

# The notes moved ABOVE the table. Asserted against the relationship table's own
# byte-exact header wherever it sits, so this reports the ordering defect it is
# rather than "no table found".
{
    awk '/^# Relationships$/ { exit } { print }' "$CLEAN"
    printf '# Relationships\n\n'
    awk '/^## Coverage notes$/ { p = 1 } p { print }' "$CLEAN"
    printf '\n'
    awk '/^\| Source Id \|/ { p = 1 } /^## Coverage notes$/ { exit } p { print }' "$CLEAN"
} > "$TMP/v14l.md"
run_v "$TMP/v14l.md"
expect_finding_global "V14l the notes section placed ABOVE the relationship table" \
    REL-COVERAGE "is ABOVE the relationship table's header row"

# AC-19: a kind with ZERO nodes and Status 'absent' is a WELL-FORMED outcome, not a
# schema violation -- the case a project genuinely lacking a carrier convention hits
# on every run. V14c above already proves the two-value enum REJECTS anything outside
# {present, absent} ('unknown'); that is a DIFFERENT claim from this one, since an
# implementation narrowed to `present) ;;` alone -- silently breaking every such
# project -- would still pass V14c, which never spells the word 'absent'. Only a
# fixture that USES 'absent' and must be accepted closes that gap.
mutate "V14-AC19" "$CLEAN" "$TMP/v14ac19.md" \
    '| web-page | entries in the external-sources file | present | 2 |' \
    '| web-page | entries in the external-sources file | absent | 0 |' \
    && {
        run_v "$TMP/v14ac19.md"
        assert_exit_eq "$RC" 0 \
            "V14-AC19a a fixed Kind row reporting a missing carrier convention (Status absent, Nodes 0) is well-formed"
        assert_output_not_contains "$OUT" "[REL-COVERAGE]" \
            "V14-AC19b ... and raises no REL-COVERAGE finding at all"
    }

# ===========================================================================
# === V15 [REL-CONCEPT-AMBIG] -- advisory ==================================
# ===========================================================================
echo ""
echo "=== V15 [REL-CONCEPT-AMBIG]: a glossary defect surfaced, never merged, never gating ==="

RC=0
bash "$VALIDATOR" --file "$CLEAN" --schema "$SCHEMA" --vocabulary "$FIXVOCAB" \
    --kb-root "$KB2" --repo-root "$REPO" --external-sources "$KB2/external-sources.md" \
    >"$TMP/out.txt" 2>"$TMP/err.txt" || RC=$?
OUT="$(<"$TMP/out.txt")"
expect_finding_global "V15a a term carrying more than one definition" \
    REL-CONCEPT-AMBIG "carries 2 definitions"
expect_finding_global "V15b two terms differing only by plurality" \
    REL-CONCEPT-AMBIG "differ only by plurality"
assert_output_contains "$OUT" "'widget' and 'widgets'" \
    "V15c ... and it names both terms, so the glossary defect is actionable"
# The ambiguous term makes the plain concept id unresolvable, which is the mechanism
# that forces the qualified form -- so this run is expected to gate on V2, not on V15.
expect_finding_global "V15d the ambiguity makes the plain concept id unresolvable" \
    REL-UNRESOLVED "ambiguous-concept-definition"

# V15 alone must not gate. Proven on the clean KB, where CLEAN01 exits 0 while
# nothing ambiguous exists; here the run gates only because V2 also fired.
run_v "$CLEAN"
assert_output_not_contains "$OUT" "[REL-CONCEPT-AMBIG]" \
    "V15e no concept advisory on a KB with one definition per term"

# ===========================================================================
# === EXIT / FLAGS / EXTRACTION: the script's own contract =================
# ===========================================================================
echo ""
echo "=== CONTRACT: the exit-code scheme, the flag surface, and the class-0 seam ==="

RC=0
bash "$VALIDATOR" --file "$TMP/no-such-artifact.md" --schema "$SCHEMA" --vocabulary "$FIXVOCAB" \
    >/dev/null 2>&1 || RC=$?
assert_exit_eq "$RC" 2 "CON01 an unreadable artifact is exit 2, not a finding"
RC=0
bash "$VALIDATOR" --file "$CLEAN" --schema "$TMP/no-such-schema.yml" >/dev/null 2>&1 || RC=$?
assert_exit_eq "$RC" 2 "CON02 a missing schema carrier is exit 2 before any check runs"
RC=0
bash "$VALIDATOR" --file "$CLEAN" --schema "$SCHEMA" --vocabulary "$TMP/no-such-vocab.yml" >/dev/null 2>&1 || RC=$?
assert_exit_eq "$RC" 2 "CON03 a missing core vocabulary is exit 2 (fail closed)"
RC=0
bash "$VALIDATOR" --bogus-flag >/dev/null 2>&1 || RC=$?
assert_exit_eq "$RC" 2 "CON04 an unknown flag is a usage error"

# A vocabulary that fails a cross-entry property must reach exit 2 THROUGH the
# validator, not merely through the library -- pair coherence included.
mutate "CON05" "$FIXVOCAB" "$TMP/vocab-incoherent.yml" \
    '    endpoint_kinds: ["concept->section"]' '    endpoint_kinds: ["section->section"]' \
    && {
        RC=0
        bash "$VALIDATOR" --file "$CLEAN" --schema "$SCHEMA" \
            --vocabulary "$TMP/vocab-incoherent.yml" --kb-root "$KB" --repo-root "$REPO" \
            >/dev/null 2>"$TMP/err.txt" || RC=$?
        assert_exit_eq "$RC" 2 "CON05 an incoherent pair reaches exit 2 through the validator"
        assert_file_contains "$TMP/err.txt" "pair coherence" \
            "CON05b ... and says pair coherence, naming the clause that failed"
    }

# --help must document exactly the flags the parser accepts. Both directions:
# a documented flag that is not parsed is a lie, and a parsed flag that is not
# documented is a hidden surface.
parsed="$(grep -oE '^ +--[a-z0-9-]+\)' "$VALIDATOR" | tr -d ' )' | sort -u)"
documented="$(bash "$VALIDATOR" --help | grep -oE '^  --[a-z0-9-]+' | tr -d ' ' | sort -u)"
assert_eq "$(comm -23 <(printf '%s\n' "$documented") <(printf '%s\n' "$parsed") | tr '\n' ' ')" "" \
    "CON06 every flag --help documents is actually parsed"
assert_eq "$(comm -13 <(printf '%s\n' "$documented") <(printf '%s\n' "$parsed") | tr '\n' ' ')" "" \
    "CON07 every flag the parser accepts is documented in --help"
help_out="$(bash "$VALIDATOR" --help 2>&1)"
last_hdr="$(awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$VALIDATOR" | tail -1)"
assert_eq "$(printf '%s\n' "$help_out" | tail -1)" "$last_hdr" \
    "CON08 --help ends at the header's last comment line and leaks no shell"

# The class-0 extraction seam: it prints the byte sequence on a clean table, and
# REFUSES on a defective one -- with stdout carrying nothing, so a caller
# byte-comparing the stream is never handed a findings list to compare.
RC=0
bash "$VALIDATOR" --file "$CLEAN" --schema "$SCHEMA" --vocabulary "$FIXVOCAB" \
    --kb-root "$KB" --repo-root "$REPO" --external-sources "$EXTSRC" --print-class0-block \
    >"$TMP/c0.txt" 2>/dev/null || RC=$?
assert_exit_eq "$RC" 0 "CON09 the class-0 extraction succeeds on a conforming table"
assert_file_contains "$TMP/c0.txt" "| Source Id | Source Kind |" \
    "CON10 the extraction includes the header row, so a column rename fails the comparison"
assert_file_not_contains "$TMP/c0.txt" "inferred" \
    "CON11 the extraction stops before the first inferred row"
assert_file_not_contains "$TMP/c0.txt" "kb-category" \
    "CON12 the extraction excludes frontmatter"

RC=0
bash "$VALIDATOR" --file "$TMP/v10a.md" --schema "$SCHEMA" --vocabulary "$FIXVOCAB" \
    --kb-root "$KB" --repo-root "$REPO" --external-sources "$EXTSRC" --print-class0-block \
    >"$TMP/c0bad.txt" 2>/dev/null || RC=$?
assert_exit_eq "$RC" 1 "CON13 the extraction REFUSES on a table that fails the order check"
if [[ -s "$TMP/c0bad.txt" ]]; then
    fail "CON14 stdout carries nothing on refusal — it carried $(wc -c < "$TMP/c0bad.txt") bytes"
else
    pass "CON14 stdout carries NOTHING on refusal (findings go to stderr, so a byte comparison is never fed a findings list)"
fi

# Determinism: two runs, byte-identical on both streams. Byte-identity of the
# artifact is the point of the ordering contract; byte-identity of the REPORT is
# what makes a diff of two runs meaningful.
run_v "$CLEAN"; first_out="$OUT"; first_err="$VERR"
run_v "$CLEAN"
assert_eq "$OUT" "$first_out" "CON15 two runs produce byte-identical stdout"
assert_eq "$VERR" "$first_err" "CON16 two runs produce byte-identical stderr"

# ---- Hygiene over the whole graph test area, this file included ------------
#
# Both of these needles are DERIVED, never written down as literals. A hygiene check
# spelling out the very string it forbids matches itself and fails on a clean tree --
# which is how the first draft of these two behaved.
GRAPH_SUITES=("$SCRIPT_DIR/test-graph-schema-loader.sh" "${BASH_SOURCE[0]}")

# The fixture vocabulary carries no shipped value. Stated as a SET INTERSECTION of
# the two carriers' declared labels, not as a substring scan of the suite text: the
# shipped set includes bare words like `cites` and `tests`, so a substring scan
# reports the word `tests` in this suite's own directory path and the label `cites`
# inside the placeholder `ddd-cites`. Both are noise, and a check that cries wolf on
# a clean tree gets read as broken rather than as a finding.
sed_labels() { grep -oE '^  - relation: [a-z0-9-]+' "$1" | sed 's/^  - relation: //' | sort -u; }
shipped_labels="$(sed_labels "${REPO_ROOT}/canonical/aid/templates/graph/relation-vocabulary.yml")"
fixture_labels="$(sed_labels "$FIXVOCAB")"
n_shipped="$(printf '%s\n' "$shipped_labels" | grep -c .)"
n_fixture="$(printf '%s\n' "$fixture_labels" | grep -c .)"
if [[ "$n_shipped" -lt 2 || "$n_fixture" -lt 2 ]]; then
    fail "CON17 — FIXTURE BUG: read $n_shipped shipped and $n_fixture fixture labels, so the intersection compared against nothing"
else
    assert_eq "$(comm -12 <(printf '%s\n' "$fixture_labels") <(printf '%s\n' "$shipped_labels") | tr '\n' ' ')" "" \
        "CON17 the fixture vocabulary's $n_fixture labels are disjoint from the shipped carrier's $n_shipped"
fi
# The shipped keys carry real standards prefixes (`cito:`, `dcterms:`, `skos:` ...)
# while the fixture's carry a placeholder one, so the extraction must be keyed on the
# `derived_from` field rather than on any one prefix -- a `std:`-only regex read ZERO
# shipped keys and the FIXTURE BUG guard caught that rather than reporting an empty
# intersection as a pass.
sed_std() {
    grep -oE '^    derived_from: \[.*\]' "$1" \
        | sed 's/^    derived_from: \[//; s/\]$//' | tr ',' '\n' | tr -d '" ' | grep . | sort -u
}
shipped_std="$(sed_std "${REPO_ROOT}/canonical/aid/templates/graph/relation-vocabulary.yml")"
fixture_std="$(sed_std "$FIXVOCAB")"
n_sstd="$(printf '%s\n' "$shipped_std" | grep -c .)"
n_fstd="$(printf '%s\n' "$fixture_std" | grep -c .)"
if [[ "$n_sstd" -lt 2 || "$n_fstd" -lt 2 ]]; then
    fail "CON17b — FIXTURE BUG: read $n_sstd shipped and $n_fstd fixture standards keys"
else
    assert_eq "$(comm -12 <(printf '%s\n' "$fixture_std") <(printf '%s\n' "$shipped_std") | tr '\n' ' ')" "" \
        "CON17b the fixture's $n_fstd standards keys are disjoint from the shipped carrier's $n_sstd"
fi

# No executable dependency on a work folder. Comment lines are excluded on purpose:
# a prose mention of the rule is not a dependency, and the rule itself has to be
# stateable in a header. The needle is assembled so this check's own code line, which
# is not a comment, cannot satisfy it.
work_needle=".aid/wor""ks/"
work_hits=""
for f in "${GRAPH_SUITES[@]}"; do
    grep -v '^[[:space:]]*#' "$f" | grep -qF -- "$work_needle" && work_hits="${work_hits}$(basename "$f") "
done
assert_eq "$work_hits" "" \
    "CON18 no graph suite references a work folder in executable code (work folders are transient by project rule)"

# ===========================================================================
# Summary
# ===========================================================================
echo ""
test_summary
exit $?
