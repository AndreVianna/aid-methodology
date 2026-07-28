# Relationship Table Schema And Validation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.2, §5.3, FR-1, FR-4, FR-9, §7 (C-7), §9 (AC-1–AC-4, AC-18); STATE.md Q1, Q3 | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned — Q1/Q3 recorded Resolved (eight columns, KB-indexed); stale nine-column and rework-warning text removed | /aid-specify |
| 2026-07-28 | Final-gate findings fixed — D4's two "residual mismatches with feature-001" and Open Items 6/7 removed: the ownership mismatch was already corrected in feature-001, and the encoding mismatch never existed (its record table specifies no encoding). Both restated as closed | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — vocabulary entry widened to feature-001's seven fields (D4, D9), ownership restated (feature-001 creates and authors the file; this feature owns only the loader/validation contract), advisory endpoint check V12 added | /aid-specify |
| 2026-07-28 | Gate finding 2 [LOW] fixed — `build-kb-index.sh`'s scan quoted accurately (bare `sort`, no `LC_ALL=C`) in D2a and the Feature Flow inputs; ordering claims re-grounded on this feature's own `LC_ALL=C` sorts (D7) | /aid-specify |

## Source

- REQUIREMENTS.md §5.2 `relationships.md` table schema (**eight** columns — `Strength` dropped per
  Q1, resolved 2026-07-28)
- REQUIREMENTS.md §5.3 Node identity (`kb:` / `int:` / `ext:<key>` prefixes and id forms)
- REQUIREMENTS.md §5 FR-1 (the artifact this feature contracts), FR-4 (the closed vocabulary
  this schema binds and validates), FR-9 (`relationships.md` placement)
- REQUIREMENTS.md §5.9 FR-28 (this feature implements the data half of the skill's
  own-artifacts-only quality gate; feature-010 owns the gate and rubric)
- REQUIREMENTS.md §7 Constraints — **C-7** (KB-adjacent artifact must obey KB authoring
  conventions; the index generator emits one entry per non-dot KB document)
- REQUIREMENTS.md §8 (A-1 external-sources file resolves `ext:` keys; A-3 provenance is
  required by construction)
- REQUIREMENTS.md §9 (AC-1, AC-2, AC-3, AC-4, AC-18)

**Both parked questions that landed here are now RESOLVED** (2026-07-28, owner decision; recorded in
STATE.md `## Cross-phase Q&A` and REQUIREMENTS.md §5.2 / FR-9 / C-7). No rework is outstanding.

- **Q1 — `Strength` disposition: DROPPED.** `Provenance` carries trust and layout hops convey
  distance, so a per-row number would duplicate the picture while being unreproducible across runs.
  The table is **eight** columns: `Source Id`, `Source Name`, `Target Id`, `Target Name`,
  `S2T Relation`, `T2S Relation`, `Provenance`, `Observation`. There is no ninth column, and
  feature-008 gains no `Strength` input.
- **Q3 — `relationships.md` placement: KB-INDEXED.** The file carries valid KB frontmatter and is
  indexed like any other generated KB document, consistent with the routing index itself being
  generated. **C-7 and AC-18 therefore hold exactly as written**, and this feature keeps its full
  scope — the earlier warning that this SPEC would need rework if Q3 went the other way is
  discharged.

**Dependency position.** Blocked by feature-001 (the vocabulary this schema validates
against). Blocks feature-005 (which writes rows in this shape), feature-006 (which reads
coverage from it), and feature-007 (which renders from it).

## Description

The relationship table is the single artifact everything else in this work depends on. This
feature defines its shape and the checks that prove a given table is well-formed.

Each row records exactly one relationship, once and never twice, because both readings —
source-to-target and target-to-source — are named on the same row. Each endpoint is carried
twice over: as a machine-verifiable identifier a validator can resolve, and as a human-friendly
display name a reader can recognise. Every identifier is prefixed to say which of the three
relationship sources it belongs to: a Knowledge Base concept, an artifact in the project
source, or an external source that contributed information. External identifiers carry only a
key, never a raw path or address, because the Knowledge Base already keeps the file that
resolves those keys — and keeping resolution in one place means it stays correct in one place.

Every row also records how the relationship was established: explicitly stated, mechanically
computed, or concluded by reading. That value is what lets a reader trust or discount a row, so
it is never absent.

Because the file lives alongside the Knowledge Base, it must behave like a Knowledge Base
document where the conventions apply — carrying the frontmatter the index generator needs, so
that regenerating the index leaves the index and the file consistent rather than at odds.

This feature also delivers the validation that makes the table checkable rather than merely
conventional: that every identifier resolves to something real, that both relation directions
on a row are a genuine inverse pair, that no relationship was recorded twice, and that no row
is missing its provenance.

## User Stories

- As an **AI agent**, I want every endpoint identifier to resolve to a real document, path, or
  external-source key, so that I can follow a row to its subject instead of dead-ending on a
  stale reference.
- As a **KB reviewer**, I want each row to state how the relationship was established, so that
  I can weigh a mechanically-derived claim differently from one concluded by reading.
- As a **maintainer/architect**, I want each relationship recorded exactly once with both
  readings on the same row, so that the table's row count means something and I never have to
  reconcile a forward row against its mirror.
- As an **AI agent**, I want `relationships.md` to carry valid Knowledge Base frontmatter, so
  that it appears in the routing index like every other Knowledge Base document rather than
  being invisible to the mechanism I route by.

## Priority

Must

## Acceptance Criteria

- [ ] AC-1: Given a generated `relationships.md`, when every row's source and target identifier
      is resolved, then each `kb:` identifier resolves to an existing Knowledge Base document
      and heading or concept within it, each `int:` identifier resolves to an existing
      repository-relative path, and each `ext:` identifier resolves to an entry in the
      external-sources file — with no unresolvable identifier.
- [ ] AC-2: Given a generated `relationships.md`, when each row's two relation columns are
      checked against the closed vocabulary from feature-001, then both values are members of
      the vocabulary and form a valid inverse pair, and no row's two directions disagree.
- [ ] AC-3: Given a generated `relationships.md`, when the table is scanned for duplicates,
      then no relationship appears twice — neither as a repeated row nor as a forward row plus
      a separate inverse row for the same endpoint pair.
- [ ] AC-4: Given a generated `relationships.md`, when every row's provenance column is read,
      then each carries exactly one of the three permitted values and none is empty.
- [ ] AC-18: Given `relationships.md` in `.aid/knowledge/`, when the Knowledge Base index is
      regenerated, then `relationships.md` carries frontmatter valid for the index generator
      and both the index and `relationships.md` are left consistent with each other.
      *(Q3 resolved KB-indexed, so this holds as written.)*
- [ ] Given the resolved schema, when the table is emitted, then it has exactly **eight** columns
      and no `Strength` column appears in the header or in any row *(Q1 resolved — dropped)*.

---

## Technical Specification

> Q1 and Q3 are **Resolved** (STATE.md `## Cross-phase Q&A`; REQUIREMENTS.md §5.2, FR-9, C-7).
> `Strength` is dropped — the table is **eight** columns. `relationships.md` is a generated,
> KB-indexed document. The Q1 acceptance criterion above is satisfied by the "dropped" branch;
> AC-18 holds as written. No rework of the requirements half was needed.

This feature ships a **contract plus its validators**, not a pipeline. Everything below is
stated so that a machine, not a reviewer's judgment, decides whether a given
`relationships.md` conforms: the column shape, the id grammars, the enums, and the frontmatter
live in declarative files under `canonical/aid/templates/graph/`, and one linter reads those
files and grades the artifact against them.

### Data Model

#### D1. Column contract

`.aid/knowledge/relationships.md` carries exactly one GFM pipe table with **eight** columns in
this fixed order:

| # | Column | Required | Value space |
|---|--------|----------|-------------|
| 1 | `Source Id` | yes | a node id (D2) |
| 2 | `Source Name` | yes | display name of `Source Id` (D5) |
| 3 | `Target Id` | yes | a node id (D2) |
| 4 | `Target Name` | yes | display name of `Target Id` (D5) |
| 5 | `S2T Relation` | yes | a member of the closed vocabulary (D4) |
| 6 | `T2S Relation` | yes | a member of the closed vocabulary (D4) |
| 7 | `Provenance` | yes | `declared` \| `derived` \| `inferred` (D3) |
| 8 | `Observation` | no | free text (D6) |

Byte-level row grammar, fixed so the artifact is byte-stable (FR-32):

- Header row: `| Source Id | Source Name | Target Id | Target Name | S2T Relation | T2S Relation | Provenance | Observation |`
- Delimiter row: `|---|---|---|---|---|---|---|---|` (eight cells).
- Every data row: a leading `|`, then each cell surrounded by exactly one space, then a
  trailing `|`. An empty `Observation` renders as a single space (`| |`) — the same
  well-formed-empty-cell rule `build-kb-index.sh` applies to its own blank cells (see its
  `END` block, "Empty cell renders as a single space").
- Cell content contains no newline and no raw `|`. A literal pipe inside a cell is escaped as
  `\|`, reusing the escaping already implemented by `build-kb-index.sh` `esc()`.
- Line endings are **LF only**, including the last line — the same rule
  `canonical/EMISSION-MANIFEST.md` states for the emission manifest ("Line endings: LF (`\n`)
  only, even on Windows"). This matters here because the repository is authored on Windows
  (see `.aid/knowledge/test-landscape.md`, "Exec-bit fix" — "The repo is authored on Windows").

The machine-readable form of this contract is `canonical/aid/templates/graph/relationship-schema.yml`
(new; see Layers & Components), a flat YAML file parsed with the project's existing awk
frontmatter/list extractors rather than a YAML binary, per `coding-standards.md`
("YAML/text parsing without binaries"):

```yaml
columns: [Source Id, Source Name, Target Id, Target Name, S2T Relation, T2S Relation, Provenance, Observation]
required: [Source Id, Source Name, Target Id, Target Name, S2T Relation, T2S Relation, Provenance]
optional: [Observation]
provenance: [declared, derived, inferred]
prefixes: [kb, int, ext]
```

No script hard-codes the column list, the enum, or the prefix set; all three are read from
this file. Adding a column is therefore a one-file change plus a validator-test update, not a
grep across the pipeline.

#### D2. Node id grammars (§5.3)

Every id is `<prefix>:<body>`, `<prefix>` ∈ {`kb`, `int`, `ext`}. Bodies:

| Prefix | Grammar | Resolution target | Resolution test |
|--------|---------|-------------------|-----------------|
| `kb:` | `kb:<doc>` or `kb:<doc>#<anchor>` | a KB document, optionally a heading within it | `<doc>` is a basename in the KB scan set; `<anchor>` is the slug of an ATX heading in that doc |
| `int:` | `int:<repo-relative-path>` (file) or `int:<repo-relative-path>/` (directory) | an artifact in the project source | `test -f` / `test -d` from the repo root |
| `ext:` | `ext:<key>` | an entry in the external-sources registry | `<key>` is a registered key in `.aid/knowledge/external-sources.md` (D2c) |

**D2a — `kb:` bodies.** `<doc>` is the *basename* of a file in the KB scan set, and that set is
defined by the same **membership predicate** `build-kb-index.sh` applies to the docs it indexes.
Quoted exactly, from `canonical/aid/scripts/kb/build-kb-index.sh` line 471:

```bash
done < <(find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)
```

Two consequences, which must not be conflated:

- **Membership is what AC-18 needs, and membership is locale-independent.** The `find`
  predicates (`-maxdepth 1`, `-type f`, `-name '*.md'`, `! -name '.*'`) select the same *set*
  under any locale; the trailing `sort` only orders it. So the AC-18 property holds
  unconditionally: a doc the index lists is exactly a doc a `kb:` id may name, and vice versa.
- **That `sort` is bare — there is no `LC_ALL=C` on it** — so `build-kb-index.sh`'s row *order*
  is locale-dependent. This feature therefore inherits no ordering from it. Every byte-identity
  claim in this spec rests on **this feature's own** `LC_ALL=C` sorts (D7) applied to the rows of
  `relationships.md`, so a non-C locale cannot reorder a single row: the scan set is consumed as
  a set (membership tests only), and the one place order is observable — the table — is ordered
  by D7's explicit `LC_ALL=C` key. The repo is not uniform here; `lint-frontmatter.sh` (line 501)
  and `kb-citation-lint.sh` (line 37) also enumerate the KB with a bare `| sort`, where order
  affects only the sequence findings print. The two scripts that *do* pin the locale —
  `build-project-index.sh` (`| LC_ALL=C sort`, line 185) and `kb-freshness-check.sh`
  (`LC_ALL=C find … | LC_ALL=C sort`, line 460) — are this feature's precedent.

`<anchor>` is the GitHub-style slug of an ATX heading (`##`, `###`, …) present in that doc.
The slug rule, confirmed against this KB's own hand-maintained `## Contents` links:

1. take the heading text with leading `#`s and surrounding whitespace stripped;
2. lowercase it;
3. delete every character outside `[a-z0-9 -]`;
4. replace each remaining space with `-`.

Confirmed twice on disk: `coding-standards.md` renders `## JavaScript / Node Conventions` as
`#javascript--node-conventions` (the `/` is deleted, leaving two spaces → two hyphens), and
`test-landscape.md` renders `## Performance & Health` as `#performance--health`. The validator
recomputes the slug for every ATX heading in the named doc and checks membership; it never
parses the doc's `## Contents` list, which is hand-maintained and therefore not authoritative.

**D2b — `int:` bodies.** Repo-relative, `/`-separated, exact on-disk case, no leading `./`,
no `\`, no `..` segment, no drive letter, no leading `/`. Rejecting `..`/`\` before any I/O
follows the path-confinement rule `coding-standards.md` records for
`connector-secret.sh` ("both reject a `<stem>` containing `/`, `\`, or `..` before any I/O").
The repo root is resolved once via `git rev-parse --show-toplevel`, the same way
`kb-freshness-check.sh` resolves `--repo`.

A trailing `/` marks a **directory artifact**. Directory ids are necessary because two of this
project's artifact kinds *are* directories by its own convention: a skill is
`canonical/skills/aid-<name>/` (`SKILL.md` + `references/`) and an agent is
`canonical/agents/aid-<role>/` (`AGENT.md` + `README.md`) — see `module-map.md` "Where a new
skill goes" / "Where a new agent goes". The directory form also matches the shape KB
frontmatter `sources:` entries already use (`canonical/aid/scripts/kb/`, `tests/canonical/`).

**Symbol narrowing — a deliberate, recorded tension.** §5.3 permits an `int:` id "optionally
narrowed to a symbol within the file", while FR-23 and AC-16 forbid any node finer-grained
than a whole artifact. Both are honoured by separating grammar from emission: the grammar
admits `int:<path>#<symbol>`, so §5.3's option is not destroyed; but `/aid-graph` never emits
it (feature-004 produces file- and directory-level nodes only), and the validator's
granularity check (V7) **rejects** a narrowed `int:` id found in `relationships.md`. Any future
need for symbol-level nodes must lift V7 and revisit AC-16 deliberately rather than by
accident.

**D2c — `ext:` bodies and the registry gap.** `<key>` matches
`[A-Za-z0-9][A-Za-z0-9._-]*` — no whitespace, no `/`, no `\`, no `..`, no `://` scheme. Rows
never carry a raw path or URL for an external node (§5.3, A-1); the key is all that appears.

`.aid/knowledge/external-sources.md` today has **zero registered entries** and states so in
prose ("No external documentation was provided during discovery"), with a placeholder
`- (none)` in its `sources:` frontmatter. It therefore has no machine-readable entry format at
all. This feature defines the one the resolver reads: **within the `## Sources` section, a GFM
table row whose first cell is a key rendered as inline code registers that key** —

```markdown
| Key | Origin | Contributed to |
|-----|--------|----------------|
| `docker-dockerfile` | https://docs.docker.com/reference/dockerfile/ | integration-map.md |
```

The resolver's predicate is a single awk scan: inside `## Sources`, a line matching
`^\|[[:space:]]*` + a backticked key + `[[:space:]]*\|` registers that key. A table-first
format is chosen because `authoring-conventions.md` makes tables the primary structure for KB
reference material and `external-sources.md` already carries one for its `## Change Log`.
Against today's prose-only file the predicate registers zero keys, which is the literal truth
and exactly why Q4 resolved to a fixture: AC-1's `ext:` branch is proven against a self-built
synthetic `external-sources.md` supplying both resolvable and deliberately unresolvable keys
(A-6 — fixtures are self-built and depend on no work folder).

Two consequences are recorded rather than assumed: `/aid-graph` is read-only with respect to
the KB (FR-10) so it can never *register* a key itself; and the writer of
`external-sources.md` is `/aid-discover`'s ELICIT state (`module-map.md` dependency graph:
`state-elicit.md -> .aid/knowledge/external-sources.md`), so emitting this table form is an
upstream change outside this feature's scope. See Open Items.

#### D3. `Provenance` enum

Closed, lowercase, exactly one value per row, never empty (A-3 — provenance is required by
construction):

| Value | Meaning | Producer |
|-------|---------|----------|
| `declared` | stated outright in the KB or the source | feature-005 pass 1a |
| `derived` | computed by a deterministic scan, no judgment | feature-005 pass 1b |
| `inferred` | concluded by the agent from reading | feature-005 pass 2 |

`declared` and `derived` together form the **deterministic class** (class 0); `inferred` is
class 1. The class partition is what FR-32/AC-5 is stated over and what D7's ordering rule
makes contiguous. FR-24's rule that a reported KB gap must carry `declared` or `derived`
provenance is enforced on feature-004's node evidence, not on this table; this enum is what
makes that enforcement expressible.

#### D4. Vocabulary loading (the loader contract; feature-001 owns the file)

**Ownership, stated so it cannot be read two ways.** Feature-001 owns the vocabulary's *schema*
**and** its *content* — which relation types exist, what each field means, and each field's value
rule. Its SPEC's "The vocabulary record" table **is** that schema, and feature-001 therefore also
**creates** the file. This feature owns exactly one thing: the *loader and validation contract* —
how the file is parsed, which fields this validator consumes, which invariants the loader
enforces, and what happens when the file is absent, empty, or malformed. No relation label
appears anywhere in this feature's code (a reviewer can prove it by grepping the `graph/` script
tree once feature-001 lands), which is what makes the split real rather than nominal: this
feature's library and tests are built against a *fixture* vocabulary while feature-001 is still
open (D-1).

**Carrier.** `canonical/aid/templates/graph/relation-vocabulary.yml` — YAML, because the file's
runtime consumers are shell (`rel_load_vocabulary` here, feature-005's writer), and the repo
ships no YAML library for shell. Precedent, on both counts:
`canonical/aid/templates/shortcut-catalog.yml` is a `.yml` under `canonical/aid/templates/`
holding a block sequence of flat mappings (`shortcuts:` at line 111, then `- name:` /`verb:` /
`artifact:` / `alias_of:` entries), machine-read by tooling *and* by a shell consumer:
`tests/canonical/test-catalog-dirs-parity.sh` parses it in awk (lines 60–88) and names the
subset it relies on — "Restricted YAML subset (flat single-level mappings, one row per
`- name:` line)". This spec adopts the same physical shape and the same restricted subset.

**File shape — two top-level keys, `pairs:` and `categories:`.** This is feature-001's
§ "The parse contract" restated as the loader's obligation, field for field, because two loaders
(this one and feature-005's) must agree exactly. Keeping the top-level key as **`pairs:`** is
deliberate: widening the entry from a three-field scalar to a seven-key mapping does not also move
the key the loader looks for.

```yaml
pairs:
  - relation: <relation>
    inverse: <inverse>
    symmetry: asymmetric          # or: symmetric
    category: <category>
    endpoint_kinds: ["kb:->int:", "kb:->ext:"]
    passes: [declared, derived]
    definition: "<one sentence>"

categories:
  - "<name>|<one-line meaning>"
```

(Values are placeholders — this feature fixes no vocabulary member.)

**Entry shape — seven keys, fixed order, one key per physical line.** The keys are feature-001's
seven fields in snake_case, matching `shortcut-catalog.yml`'s `alias_of` / `default_type`
convention. The table below is what the loader accepts and rejects; feature-001's SPEC remains
authoritative on what each field *means*.

| Key | feature-001 field | Physical form | Value space this loader enforces |
|-----|-------------------|---------------|----------------------------------|
| `relation` | `Relation` | plain scalar, **always the entry's first key** (`  - relation:`) | required, non-empty, `[a-z][a-z0-9-]*`; **unique** across `pairs:` |
| `inverse` | `Inverse` | plain scalar | required, `[a-z][a-z0-9-]*`; must itself appear as some entry's `relation` |
| `symmetry` | `Symmetry` | plain scalar | closed enum `asymmetric` \| `symmetric` |
| `category` | `Category` | plain scalar | required, single-valued; **must be a name declared in `categories:`** |
| `endpoint_kinds` | `Endpoint Kinds` | one-line **flow sequence** of double-quoted tokens | non-empty; each token `<p>-><p>` with both `<p>` in `kb:`, `int:`, `ext:` (D2's prefix set) |
| `passes` | `Passes` | one-line **flow sequence** | non-empty subset of `declared`, `derived`, `inferred` — the same three values D3's `Provenance` enum holds |
| `definition` | `Definition` | double-quoted scalar, one physical line | required, non-empty |

`categories:` is a block sequence of double-quoted `"<name>|<one-line meaning>"` scalars — the
same intra-entry `|` separator `.aid/settings.yml` uses for `knowledge.doc_set`. It is the closed
set every entry's `category` is checked against, which is how feature-001's "category totality"
property becomes mechanical here.

Loader contract (`rel_load_vocabulary`, D9):

- **Parse.** A single forward pass with one flush point: a four-space-indented `key: value` line
  belongs to the most recent `  - relation:` line, and an entry ends at the next `  - relation:`,
  at `categories:`, or at end of file. Comments (`#`) and blank lines are skipped anywhere.
  Implemented as a small awk state machine — the class of parser
  `test-catalog-dirs-parity.sh` already proves sufficient for a block sequence of flat mappings
  in this repo ("Restricted YAML subset (flat single-level mappings, one row per `- name:` line)",
  lines 60–88). It is **not** a `read-setting.sh` `lookup_list` reuse: that helper handles
  "flat-section dotted-path lookups … plus list-valued top-level keys" and defers to `yq` for
  anything nested (its header, lines 38–42), and a sequence of mappings is past it. Writing the
  state machine here rather than acquiring `yq` is what keeps the toolkit's zero-runtime-dependency
  posture. Values are read as **opaque data**.
- **The restricted subset is enforced, not assumed.** No anchors, aliases, merge keys, multi-line
  block scalars (`|`, `>`), or a second document (`---`); no nesting below an entry's scalar and
  flow values; `endpoint_kinds` and `passes` on one physical line each. Any of these → exit 2.
  This is what makes two independently written loaders read the same seven values.
- **All seven keys are validated, whether or not this feature consumes them.** An entry missing a
  key, carrying one twice, carrying a key outside the seven, holding an empty value, or presenting
  its keys out of the fixed order → exit 2 with an actionable message naming the resolved absolute
  path of the file, the entry's `relation` (or its ordinal, when `relation` is what is missing),
  and the offending key. Being *tolerant of* the fields it does not use while still refusing a
  malformed one is deliberate: this loader is the single mechanical check on feature-001's output
  shape, so it must not silently pass a defect in a field only a sibling feature reads.
- **Cross-entry invariants**, which are feature-001's stated properties enforced here rather than
  assumed: **closure** (every `inverse` is some entry's `relation`), **involution**
  (`inverse(inverse(r)) == r`), **symmetric consistency** (`symmetry == symmetric` iff
  `inverse == relation`, `asymmetric` iff not — no third case), **`relation` uniqueness**, and
  **category totality** (every entry's `category` is declared in `categories:`, and no
  `categories:` name is declared twice). Any violation → exit 2. These are file-level defects,
  never row findings.
- **Entry order is not enforced.** Feature-001 sorts `pairs:` by `category` then `relation`, and
  `categories:` by name, so a vocabulary change reads as a clean diff. That is an authoring
  convention with no acceptance criterion behind it, and membership and pairing are order-free, so
  the loader neither requires nor checks it.
- **Membership** (V3): a label is valid iff it is some entry's `relation` or `inverse`.
- **Pairing** (V4): the ordered pair `(S2T, T2S)` is valid iff some entry has
  `relation == S2T && inverse == T2S`, **or** `relation == T2S && inverse == S2T`. Accepting the
  mirror is what makes D7's orientation normalisation safe. A **symmetric** entry
  (`relation == inverse`) is permitted and yields rows where `S2T Relation == T2S Relation`;
  V4 accepts those rows rather than reading them as "the two directions disagree" — the edge case
  feature-001 flags as the one a naive validator gets wrong. And because D7 normalises orientation
  *before* keying, a symmetric relation's `(A,B)` and `(B,A)` rows collapse to a single
  `rel_row_key`, which is what AC-3 requires for the symmetric case.
- **Which fields this feature uses.** `relation` + `inverse` drive V3 and V4. `category` is
  carried through untouched and exposed to feature-007/feature-008 as FR-6's grouping dimension;
  this feature never interprets it. `endpoint_kinds` drives **V12**, an advisory check on a row
  whose prefix pair the chosen relation does not list — advisory exactly as feature-001 specifies
  ("lets feature-003's validator emit an **advisory** warning on a prefix pair the vocabulary
  does not list — advisory, because AC-2 is scoped to membership and inverse consistency only").
  `symmetry` is read, enforced against `inverse == relation`, and used by V4 as the *declaration*
  that a self-inverse entry is intentional: a row with `S2T == T2S` is accepted because its entry
  says `symmetry: symmetric`, not merely tolerated because the two labels happen to match. An entry
  whose labels are self-inverse while `symmetry` says `asymmetric` (or the reverse) is a file-level
  defect and exits 2, so V4 never has to guess. `passes` is validated here and consumed by
  feature-005 (its D3), not by this validator.
- **Missing file, absent `pairs:` key, or a present-but-empty `pairs:`** (the seeded
  pre-authoring state) → exit 2 with a message naming feature-001 as the blocking dependency
  (D-1). Failing closed is deliberate: an absent vocabulary must halt validation, never silently
  pass every row.

**Alignment with feature-001 — both previously-recorded mismatches are now closed** *(verified
2026-07-28 against feature-001's current text; an earlier revision of this section recorded them as
open, which is superseded):*

1. **Physical form is consistent.** Feature-001's vocabulary-record table describes `endpoint_kinds`
   as a "Non-empty list of … tokens" and `passes` as a "Non-empty subset of …" — it specifies no
   encoding, so it never conflicted with its own § "The parse contract", which fixes both as one-line
   **flow sequences** (`["kb:->int:", "kb:->ext:"]`, `[declared, derived]`). This loader implements
   the parse contract, and no correction to feature-001 is outstanding.
2. **File ownership is settled and agreed.** Feature-001 § Ownership states that the earlier
   creator-split is superseded: **feature-001 creates and authors the file** — schema and contents —
   and this feature owns only the loader and validation contract. Both specs now say the same thing.

One item feature-001 explicitly leaves to this feature is settled above: it lists "Whether
`endpoint_kinds` drives an advisory validator warning, and at what severity" as feature-003's
call. The answer is **yes, as V12, at `[LOW]`, never gating** — see the Validators table.

#### D5. Display-name rule

`Source Name` / `Target Name` are **pure functions of the id**, never authored per row. This
keeps AC-1 checkable in both directions and removes a churn source from FR-32.

| Id form | Name |
|---------|------|
| `kb:<doc>` | `<doc>` |
| `kb:<doc>#<anchor>` | `<doc> § <heading-text>` — heading text verbatim, `#`s and surrounding whitespace stripped |
| `int:<path>` / `int:<path>/` | `<path>` / `<path>/` verbatim |
| `ext:<key>` | `<key>` |

For `int:` the full repo-relative path is the name because a basename is not unique in this
repository — `build-kb-index.sh` exists at eight paths and `reader.mjs` at three
(`project-structure.md` "Unusual Structure Notes", "Heavy, deliberate file duplication").
Shortening a path for legibility is a *render-time* concern owned by feature-007, not a
stored value. For a node feature-004 emits, the name must equal that node record's `name`
field, which is where feature-004's per-kind naming lives — this feature only enforces that
the same id never carries two different names (V8).

#### D6. `Observation` cell

Optional, and constrained by provenance so it cannot destabilise class 0:

- On a `declared` or `derived` row, `Observation` is either empty or a **rule-derived durable
  anchor** — a path plus a grep-recoverable symbol/heading/literal, per
  `authoring-conventions.md` "Citation Rule (Durable Anchors)". Free prose is forbidden here,
  because prose is not reproducible and would break AC-5.
- On an `inferred` row, free prose is permitted; §5.4 designates `Observation` as the home for
  nuance no vocabulary pair captures.
- A bare `file.ext:LINE` citation is forbidden in any row. This is not a new rule — it is the
  existing one `kb-citation-lint.sh` already gates mechanically, and line numbers would also
  make the row churn on every unrelated edit above them.

"Durable anchor" is given a mechanical predicate so V11 is falsifiable rather than a judgment
call: on a class-0 row, `Observation` is empty, **or** its first whitespace-delimited token
matches `kb-citation-lint.sh`'s own path pattern
`[A-Za-z0-9_./-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)`. That is exactly the shape
feature-005's harvesters emit (`authoring-conventions.md sources: .claude/aid/scripts/kb/lint-frontmatter.sh`),
and a prose sentence cannot satisfy it. The bare-line-citation half of V11 reuses
`kb-citation-lint.sh`'s discrimination verbatim: a colon followed by digits is a violation
unless the next character is a letter, a `-` plus a letter, or a `.` plus a digit (an IP or
version).

#### D7. Row normalisation and ordering (the byte-identity contract)

This feature owns the ordering contract; feature-005 implements it and feature-007 renders it.

**Normalisation.** Before comparison or sorting, a row is put in canonical orientation: if
`Source Id > Target Id` under `LC_ALL=C` byte ordering, swap the two ids, swap the two names,
and swap `S2T Relation` with `T2S Relation`. The swap is information-preserving precisely
because both readings live on one row (§5.2). Self-edges (`Source Id == Target Id`) are left
as written.

**Row key.** `key = source_id \x1f target_id \x1f s2t \x1f t2s` on the *normalised* row
(`\x1f` is US, which cannot occur in any id or label). A verbatim repeat and a separately
written inverse row both collapse to the same key, which is what makes V4 catch both halves of
AC-3.

**Sort order.** `LC_ALL=C` lexicographic ascending over the tuple
`(class, source_id, target_id, s2t, t2s, provenance)`, where `class` is `0` for
`declared`/`derived` and `1` for `inferred` (D3). `LC_ALL=C` follows the two repo scripts that
pin the locale for reproducible output — `build-project-index.sh` (`| LC_ALL=C sort`, line 185)
and `kb-freshness-check.sh` (line 460). It deliberately does **not** follow
`build-kb-index.sh`, whose scan uses a bare `| sort` (line 471, quoted in D2a): this ordering is
the byte-identity contract, so it cannot be left to the environment's collation.

Class-major ordering is the mechanism that keeps the agent pass from destabilising the
deterministic majority: **the class-0 rows are a contiguous prefix of the table and the class-1
rows a contiguous suffix**, so adding, removing, or rewording any `inferred` row cannot move,
split, or reflow a single deterministic row. No in-file boundary marker is used, which keeps
§5.2's one-table rule intact; the block boundary is a *predicate* (`Provenance ∈ {declared,
derived}`) that the ordering guarantees is contiguous.

**AC-5's mechanical check** is therefore: regenerate, extract the class-0 prefix, and byte
compare it against the class-0 prefix of the previously committed artifact obtained with
`git show HEAD:.aid/knowledge/relationships.md`. This needs no side-channel file and no stored
hash, and it reuses the git-native, machine-neutral comparison style
`kb-freshness-check.sh` already established. `.aid/knowledge/` is not gitignored (verified in
`.gitignore` — only `.aid/knowledge/.cache/` is), so the previous blob is always available.
Whether a staleness *decision* is taken from that comparison is feature-010/FR-11's call, not
this feature's.

#### D8. Emitted KB frontmatter (AC-18, C-7)

`relationships.md` opens with this block, as the first bytes of the file (no BOM, no blank
line before), followed by the `<!-- AUTO-GENERATED ... -->` marker, the `# Relationships`
title, and the table:

```yaml
---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: Every recorded relationship among Knowledge Base concepts, project source artifacts, and external sources, with both readings named on one row.
summary: Read this to trace which Knowledge Base concept is backed by which source artifact or external source; it is the single input to the graph view and the machine-readable structure agents route over.
sources:
  - .aid/knowledge/
  - .aid/knowledge/external-sources.md
tags: [C2, relationships, graph, provenance, coverage, routing]
see_also: [INDEX.md, external-sources.md]
owner: architect
audience: [developer, architect]
contracts:
  - "Eight columns in fixed order: Source Id / Source Name / Target Id / Target Name / S2T Relation / T2S Relation / Provenance / Observation"
  - "Every row carries a Provenance of declared, derived, or inferred"
  - "One row per relationship; both readings named on the same row"
---
```

Every field choice is forced by a checked fact, not preference:

- **`kb-category: primary` + `source: generated`** mirrors `INDEX.md` exactly (verified in
  `.aid/knowledge/INDEX.md`'s own frontmatter). `frontmatter-schema.md` states that this
  combination routes to the "Full Primary + Build-Verify" rubric, where both content
  correctness and generator freshness are checked — the right rubric for a generated,
  load-bearing routing artifact. Q3's resolution ("consistent with `INDEX.md` itself being
  generated") is satisfied literally.
- **`generator: build-relationships.sh`** — a bare basename naming the *build script*, as
  `frontmatter-schema.md` specifies ("Name of the build script (relative to
  `canonical/aid/scripts/`…)", examples `build-kb-index.sh`, `build-metrics.sh`) and as
  `INDEX.md` does. Feature-010's SPEC currently names the *skill* (`aid-graph`) in this field;
  the schema wants the script, and `build-relationships.sh` is the script that writes the file.
  Flagged for cross-feature reconciliation rather than resolved unilaterally — see Open Items.
- **`objective:` and `summary:` are single physical lines containing no `|`.** Both are
  required: `build-kb-index.sh` reads them with `ef()`, a single-line scalar extractor scoped
  to the first frontmatter block, and pipes each through `esc()` into an INDEX table cell. A
  block scalar (`objective: |`) would render an empty Objective cell; a raw `|` would still
  render, escaped, but the single-line rule is what the schema mandates.
- **`tags:` includes the concern id `C2`** — `authoring-conventions.md` makes the concern id a
  by-convention requirement, and C-7 names `tags` explicitly. C2 (modules/dependencies/wiring)
  is the spine dimension this artifact serves.
- **No `changelog:`, and no timestamp in the table, in any row, or in the `AUTO-GENERATED`
  comment.** This is a deliberate divergence from `INDEX.md`, which embeds `$TS` in both its
  `changelog:` entry and its `AUTO-GENERATED` comment and therefore churns on every run. A date
  inside the table would make the deterministic rows differ on an unchanged repository and
  defeat FR-32 outright. `changelog:` is optional and review-exempt per
  `frontmatter-schema.md`, so omitting it costs nothing. The `AUTO-GENERATED` comment carries
  the generator path and the regenerate command only.
- **Three generator-written fields are reserved for sibling features** and appear in the block
  alongside this feature's own: `graph_inputs_digest` and `graph_generated_at` (feature-010's
  content-addressed staleness record — the composite digest and an informational UTC timestamp)
  and `kb_gaps` (feature-006's gap list). They are named here so the frontmatter contract is
  complete, but their values, shapes, semantics, and writers belong to those features; this
  feature neither produces nor validates them. **They sit outside the byte-identity boundary by
  design**: FR-32 binds "the deterministic majority of `relationships.md`", and D7 makes that
  majority the contiguous class-0 row block. Scoping byte-identity to that block rather than to
  the whole file is what lets a content-addressed staleness record and a gap list live in the
  frontmatter without the two requirements colliding. `frontmatter-schema.md` tolerates unknown
  fields ("Unknown fields are tolerated (forward-compatible with future schema additions)"),
  and `build-kb-index.sh` composes its INDEX row from named fields only, so none of the three
  disturbs the index generator or any lint.
- **No `approved_at_commit:`** — generator-written on approval by `/aid-discover` or
  `/aid-update-kb`, never by this skill; absence is always valid.
- **No `intent:`** — superseded by `objective:` + `summary:`.
- **`sources:` and the frontmatter lint.** `lint-frontmatter.sh` skips every
  `source: generated` doc outright (verified in its own header and its `lint_doc` skip
  branch), so none of these fields is lint-graded. They are emitted anyway because C-7
  requires four of them and because a generated doc with no `objective:`/`summary:` would
  render a degraded INDEX row.

A body-level `---` thematic break is safe but is not used: `build-kb-index.sh`'s extractors
exit when they leave the first frontmatter block ("Symmetric with `extract_literal`: exit when
we leave that block, so a body-level thematic-break `---` cannot re-enter 'frontmatter
mode'"). The file's body carries no column-0 `---` line regardless, so no reader can be
confused.

#### D9. Loader library surface

`canonical/aid/scripts/graph/relationship-schema.sh` is sourceable and side-effect-free on
import, carrying a `Provides:` header index in the style of `lib/aid-install-core.sh`:

| Function | Contract |
|----------|----------|
| `rel_load_schema <file>` | populates the column list, required set, provenance enum, prefix set from D1's YAML |
| `rel_load_vocabulary <file>` | parses the seven-key entries per D4 into a relation table (`relation`, `inverse`, `symmetry`, `category`, `endpoint_kinds`, `passes`, `definition`), validating all seven and the four cross-entry invariants; exposes membership, pairing, `category`, and `endpoint_kinds` lookups; exit 2 on absent/empty/malformed |
| `rel_parse_id <id>` | splits `<prefix>`/`<body>`/`<anchor-or-symbol>`; returns non-zero on a grammar violation |
| `rel_resolve_id <id>` | resolves per D2; prints `ok` or a reason token |
| `rel_display_name <id>` | the D5 pure function |
| `rel_normalise_row <8 fields>` | the D7 orientation swap |
| `rel_row_key <8 fields>` | the D7 `\x1f` key |
| `rel_sort_key <8 fields>` | the D7 `(class, …)` tuple |

### Feature Flow

Validation is a single read-only run. Inputs, steps, outputs:

**Inputs**

1. `.aid/knowledge/relationships.md` — the artifact under test (or a fixture path via `--file`).
2. `canonical/aid/templates/graph/relationship-schema.yml` — D1.
3. `canonical/aid/templates/graph/relation-vocabulary.yml` — D4; created and authored by
   feature-001, read-only here.
4. The KB scan set — D2a's membership predicate
   `find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'`, consumed as a set.
5. The repo root — `git rev-parse --show-toplevel`.
6. `.aid/knowledge/external-sources.md` — the `ext:` registry (or a fixture via `--external-sources`).

**Steps** (`validate-relationships.sh`)

1. Parse arguments with the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop and
   `shift 2` per flag that `read-setting.sh` establishes; unknown flag → stderr + exit 2.
2. Load the schema and the vocabulary (D9). Either missing or malformed → exit 2 before any
   check runs, so a configuration error is never reported as an artifact defect.
3. Read the frontmatter block once with the awk extractor pattern shared by
   `lint-frontmatter.sh` / `kb-freshness-check.sh` (one pass, arrays populated). Run **V9**.
4. Locate the single table; assert the header row and delimiter row byte-equal D1's forms.
   Run **V1** over every data row (cell count, padding, escaping, no embedded newline, LF).
   A V1 failure is fatal for the remaining checks on that row — the row is reported and
   skipped, not guessed at.
5. For each well-shaped row: resolve both ids with `rel_parse_id` + `rel_resolve_id` (**V2**),
   check vocabulary membership (**V3**) and inverse-pairing (**V4**), provenance membership
   (**V6**), granularity (**V7**), name purity and intra-file name consistency (**V8**), the
   `Observation` constraints of D6 (**V11**), and the advisory endpoint-kind check (**V12**).
6. Accumulate `rel_row_key` per row; a repeated key is a duplicate (**V5**).
7. Assert the table's actual row order equals the D7 sort order and that class 0 is a
   contiguous prefix (**V10**).
8. Print every finding to stdout as `[TAG] <doc>: <message>` and a
   `Checked: N rows | Findings: M` trailer, mirroring `lint-frontmatter.sh`'s output shape.

**Outputs**

- stdout: findings + trailer. stderr: diagnostics only. (`coding-standards.md`: stdout carries
  the result, stderr the diagnostics.)
- Exit codes: `0` clean, `1` one or more findings, `2` usage / unreadable input / malformed
  schema or vocabulary. This is the linter scheme `coding-standards.md` records verbatim:
  "Linters use `0` clean, `1` violations, `2` usage".
- No file writes. The skill's REVIEW state transcribes findings into the 7-column ledger at
  `.aid/.temp/review-pending/<scope>.md` and grades them with `grade.sh` (C-6, FR-26). The
  validator emits **rubric tags**, not severities — the same division of labour
  `lint-frontmatter.sh` uses with `[FM-MISSING]`/`[FM-INVALID]`.

#### Validators

| # | Tag | Check | Failure mode | Ledger severity | AC |
|---|-----|-------|--------------|-----------------|-----|
| V1 | `[REL-SHAPE]` | header/delimiter byte-equal D1; every data row has 8 cells with D1 padding; no embedded newline; no unescaped `|`; LF endings | row reported and excluded from V2–V8, V11, and V12; run continues | `[HIGH]` | — (enables AC-1–AC-4) |
| V2 | `[REL-UNRESOLVED]` | each id parses per D2 and resolves: `kb:` doc in the scan set and anchor among that doc's recomputed heading slugs; `int:` path exists as file or dir from the repo root; `ext:` key registered in the registry | finding names the id and which resolution step failed | `[HIGH]` | AC-1 |
| V3 | `[REL-VOCAB]` | both relation labels are vocabulary members | finding names the offending label | `[HIGH]` | AC-2 |
| V4 | `[REL-PAIR]` | `(S2T, T2S)` is a vocabulary pair in either orientation (D4); a symmetric relation's row (`S2T == T2S`) is **valid**, not a disagreement | finding names both labels and states they are not inverses | `[HIGH]` | AC-2 |
| V5 | `[REL-DUPLICATE]` | no two rows share a `rel_row_key` | finding names the key and both row ordinals | `[HIGH]` | AC-3 |
| V6 | `[REL-PROVENANCE]` | exactly one of `declared`/`derived`/`inferred`, non-empty, lowercase | finding names the offending value or reports it empty | `[HIGH]` | AC-4 |
| V7 | `[REL-GRANULARITY]` | no `int:` id carries a `#<symbol>` narrowing | finding names the id | `[HIGH]` | AC-16 (table side) |
| V8 | `[REL-NAME]` | each name equals `rel_display_name` for `kb:`/`ext:`; no id carries two different names anywhere in the file; no name is empty | finding names the id and both spellings | `[HIGH]` | AC-1 (support) |
| V9 | `[REL-FRONTMATTER]` | D8's block is present and is the first content in the file; `kb-category`, `source`, `generator`, `objective`, `summary`, `tags` all present and non-empty; `objective`/`summary` are single-line and pipe-free; no timestamp appears in the table, in any row, or in the `AUTO-GENERATED` marker. Fields owned by sibling features and any other unknown key are tolerated and not validated | finding names the missing or malformed field | `[HIGH]` | AC-18 |
| V10 | `[REL-ORDER]` | actual row order equals D7's sort order; class 0 is a contiguous prefix | finding names the first out-of-order ordinal | `[HIGH]` | AC-5 (support) |
| V11 | `[REL-OBSERVATION]` | on a `declared`/`derived` row, `Observation` is empty or a durable anchor — not free prose; no row's `Observation` carries a bare `file.ext:LINE` citation | finding names the row ordinal and the offending text | `[HIGH]` | AC-5 (support) |
| V12 | `[REL-ENDPOINT]` | **advisory** — the row's `<source-prefix>-><target-prefix>` pair appears in the chosen relation's `endpoint_kinds` (D4) | finding names the relation, the observed prefix pair, and the pair set the vocabulary lists; never gates | `[LOW]` | none (by design) |

V1–V11 all map to `[HIGH]` because every one of them maps to a stated acceptance criterion; no
middle tier is defined, so a passing grade cannot be bought with tier arithmetic among them.
V12 is the one deliberate exception and it is `[LOW]` for a stated reason, not for convenience:
feature-001 specifies `endpoint_kinds` as a consumer aid that "exist[s] to serve consumers, not
to add a gate", and no acceptance criterion checks it — AC-2 is scoped to membership and inverse
consistency. Emitting it as `[LOW]` keeps the signal (a genuinely mistyped endpoint pair is
visible) without inventing a gate the requirements do not have.

**Two interpretation decisions, recorded so they are not re-litigated:**

1. **Multiple rows over the same endpoint pair are legal** when their relation pairs differ.
   AC-3's wording ("nor as a forward row plus a separate inverse row for the same endpoint
   pair") could be read as one-row-per-pair, but FR-4 admits a comprehensive vocabulary and
   §5.4 says nuance no *pair* captures goes to `Observation` — so two genuinely different
   typed relations between the same two nodes are distinct relationships. V5 keys on the
   relation pair as well as the endpoints, which catches every repeat and every mirror of the
   *same* relationship while permitting a second, different one.
2. **`Observation` is not part of the duplicate key.** Two rows identical but for their
   `Observation` text are the same relationship recorded twice and V5 flags them.

### Layers & Components

New files only; no existing script is forked (C-4). Every row below is created by this feature
except `relation-vocabulary.yml`, which is feature-001's and is listed so the read dependency is
visible. Authored in `canonical/`, then rendered by
the FULL `run_generator.py` — never hand-edited under `profiles/` or the dogfood `.claude/`
(C-2; `module-map.md` Invariants "Single source of truth"; `project-structure.md` Invariants).
`canonical/aid/scripts/` and `canonical/aid/templates/` are both recognised asset kinds in
`canonical/EMISSION-MANIFEST.md`'s "Asset Kinds" table, so a new `graph/` subdirectory under
either is rendered into all five profiles without a renderer change; the per-profile
`emission-manifest.jsonl` records are regenerated by the same run, and the render-drift CI job
gates the result (C-3).

| Layer | Path | Purpose |
|-------|------|---------|
| Template / contract | `canonical/aid/templates/graph/relationship-schema.yml` | D1 — columns, required set, provenance enum, prefix set |
| Template / contract *(feature-001's file — not created here)* | `canonical/aid/templates/graph/relation-vocabulary.yml` | D4 — created and authored by feature-001, which owns its schema and content; this feature only reads it and owns the parse/validation contract |
| Script library | `canonical/aid/scripts/graph/relationship-schema.sh` | D9 — sourceable loader/normaliser; no import-time side effects |
| Script | `canonical/aid/scripts/graph/validate-relationships.sh` | V1–V12; `0`/`1`/`2` exit scheme |
| Test | `tests/canonical/test-relationship-schema.sh` | the D9 library: id grammars, slug rule, normalisation, row key, sort key, and `rel_load_vocabulary` — a well-formed seven-key fixture loads, and one fixture per rejection class (missing key, unknown key, duplicate key, empty value, keys out of order, enum violation, undeclared `category`, broken closure, broken involution, `symmetry`/`inverse` disagreement, absent file, empty `pairs:`) exits 2 |
| Test | `tests/canonical/test-validate-relationships.sh` | one negative fixture per validator, proving each check fires, plus a clean-pass fixture |
| Fixtures | `tests/canonical/fixtures/graph/` | hand-built tables (well-formed and one per defect class) and the Q4 synthetic `external-sources.md` with both resolvable and unresolvable keys |

Conventions honoured (all from `coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; a header block stating Purpose / Usage / Exit codes; `-h|--help`
  re-printing a slice of that header.
- `set -uo pipefail` (not `-euo`) for `validate-relationships.sh`, following the read-only
  linter precedent (`kb-citation-lint.sh`) which intentionally tolerates non-zero from
  `grep`/`awk`; the library uses `set -eu` like `build-kb-index.sh`.
- kebab-case file names, `snake_case` bash functions with a `rel_` prefix, `UPPER_SNAKE`
  globals.
- Every sort **this feature writes** is `LC_ALL=C`, following `build-project-index.sh` and
  `kb-freshness-check.sh`. The repo is not uniform on this (D2a), so the convention is stated as
  this feature's own rule rather than as an inherited one.
- File errors print the resolved absolute path.
- No new exit code is invented; `0`/`1`/`2` reuse the documented linter semantics.
- `tests/run-all.sh` discovers `tests/canonical/test-*.sh` by glob, so no runner edit is needed
  (`test-landscape.md`, "Glob discovery"). Fixtures are self-built and reference nothing under
  `.aid/works/` (A-6, and the project's transient-work-folder rule).
- `relationships.md` is **not** added to `canonical/aid/templates/generated-files.txt`. That
  registry's declared consumers are `/aid-discover`'s FIX state and its `state-fix.md` Step 4
  `test -f` loop (stated in the registry's own header), which run *before* KB approval —
  whereas `/aid-graph` is gated on an approved KB (FR-8). Registering it would make discovery
  attempt to build the graph mid-cycle. The `AUTO-GENERATED` marker and the
  `source: generated` + `generator:` frontmatter that `authoring-conventions.md` requires of
  generated content are still emitted (D8). See Open Items.

### Open Items

These are recorded rather than silently assumed; none blocks this feature's own
implementation.

1. **`external-sources.md` entry format is an upstream change.** D2c defines the table form
   the resolver reads, but `/aid-graph` cannot author it (FR-10) and the file's writer is
   `/aid-discover` ELICIT. Until ELICIT emits it, `ext:` resolution registers zero keys on
   this project and AC-1's `ext:` branch lives entirely on the Q4 fixture (which is exactly
   what Q4 decided). Emitting the table form from ELICIT is a candidate follow-on.
2. **Generated-file registry placement.** The decision not to register `relationships.md` in
   `generated-files.txt` is argued above. If the owner prefers registration for symmetry with
   `INDEX.md`, the registry line must be conditioned on KB approval, which the registry's
   flat `<output-path>|<build-command>` format cannot currently express.
3. **`kb:` anchor stability.** A `kb:<doc>#<anchor>` id breaks when a heading is reworded. This
   is inherent to heading-level identity and is the same exposure the KB's own `## Contents`
   links already carry; V2 turns it into a mechanical finding rather than a silent dead link.
4. **`generator:` value — cross-feature reconciliation with feature-010.** This SPEC emits
   `build-relationships.sh` (the script, per `frontmatter-schema.md`); feature-010's SPEC emits
   `aid-graph` (the skill). One value must win before V9 is implemented, since V9 checks the
   field's presence and the two specs would otherwise disagree about its content. The schema
   text favours the script name. Feature-010's related claim that
   `lint-frontmatter.sh` "requires" `generator:` when `source: generated` is also worth
   checking during that reconciliation: the linter skips every `source: generated` doc outright
   (verified in its own skip branch), so the requirement comes from `frontmatter-schema.md`, not
   from the lint.
5. **Frontmatter scalars owned elsewhere.** `graph_inputs_digest` and `graph_generated_at` are
   feature-010's. If feature-010's design changes to store the staleness record outside the
   artifact, D8 loses two lines and nothing else in this feature moves.
6. ~~**Vocabulary-file authorship, in feature-001's text.**~~ **CLOSED 2026-07-28.** Feature-001
   § Ownership now states that it creates and authors `relation-vocabulary.yml` and that the earlier
   creator-split is superseded. Both specs agree; nothing outstanding. (Nothing in this feature's
   implementation ever depended on which side creates the file, only on its parse contract.)
7. ~~**Feature-001's encoding wording for `endpoint_kinds` / `passes`.**~~ **CLOSED 2026-07-28 — the
   premise was mistaken.** Feature-001's record table specifies no encoding at all ("Non-empty list
   of … tokens", "Non-empty subset of …"), so it never contradicted its parse contract's flow
   sequences. No correction was needed on either side.
8. **`build-kb-index.sh`'s KB scan is locale-dependent** (bare `| sort`, line 471; the same is
   true of `lint-frontmatter.sh` line 501 and `kb-citation-lint.sh` line 37). Nothing in this
   feature depends on it — D2a consumes the scan set as a set, and D7 supplies its own
   `LC_ALL=C` order — but `INDEX.md`'s own row order can differ between machines, which is a
   pre-existing reproducibility wrinkle in a *generated* KB artifact. Worth a one-line fix in
   that script some day; out of scope here (C-4 forbids forking it, and changing it is not this
   feature's requirement).
