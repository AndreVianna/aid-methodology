# Two-Pass Relationship Extraction

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.8 (FR-29–FR-32), §5.1, FR-1, §9 (AC-5) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — D3 rebound to feature-001's seven-field YAML vocabulary entry; the fields this feature consumes are now stated, and `passes` / `endpoint_kinds` are genuinely read (map-time legality gates + a pass-2 rejection), reconciling feature-001's consumer-table claim | /aid-specify |
| 2026-07-28 | Gate finding 2 [LOW] follow-through — `build-kb-index.sh`'s bare `sort` no longer cited as an `LC_ALL=C` precedent (D2, FR-32 mechanism 3) | /aid-specify |
| 2026-07-28 | Gate finding 3 [HIGH] follow-through — pass 2's closed-node-set bound restated as the downstream half of feature-004's `no-inferred-node` invariant | /aid-specify |

## Source

- REQUIREMENTS.md §5.8 (FR-29, FR-30, FR-31, FR-32)
- REQUIREMENTS.md §5.1 Relationship sources (the three sources every row is drawn from)
- REQUIREMENTS.md §5 FR-1 (this feature produces the content of `relationships.md`; feature-003
  owns its shape)
- REQUIREMENTS.md §5.5 FR-11 (this feature's reproducibility is what makes the staleness check
  meaningful; feature-010 owns the check itself)
- REQUIREMENTS.md §9 (AC-5; produces the rows AC-1 through AC-4 validate)

**Shared implementation seam with feature-004.** The deterministic pass harvests references,
invocations, and dependency edges from the same traversal of the project source that
feature-004 uses to decide structural significance. These are two specifications over **one
scanner walk**, and `/aid-specify` and `/aid-detail` **must not produce two competing
scanners** — a second independent walk would drift from feature-004's and the two would
disagree about what exists. Feature-004 owns which nodes exist; this feature owns which rows
exist.

**Dependency position.** Blocked by feature-001 (rows cannot be typed without the vocabulary),
feature-003 (rows must be written in the agreed shape), and feature-004 (the node set). Blocks
feature-006 (which needs Knowledge Base coverage to compute gaps) and supplies the real data
feature-007 through feature-009 render — though those may be developed against a fixture.

## Description

Relationships are extracted by two passes with different characters, not by one mechanism
asked to do everything. The bulk of the work is done by a deterministic scan; a reading pass
then handles only what the scan could not settle.

The first pass harvests two kinds of thing. It collects what is already stated outright —
cross-references between Knowledge Base documents, the citations documents carry, the
external-source keys they name — and it computes what follows mechanically from the source
itself: which file references which, what invokes what, which artifact depends on which. Rows
from this pass are stamped as either explicitly declared or mechanically derived, according to
which of the two produced them.

The second pass is deliberately bounded. It runs only over the residue: the concept-level
Knowledge Base nodes that genuinely require reading to identify, and the candidate connections
the scan noticed but could not name. Rows from this pass are stamped as inferred, so a reader
always knows which claims rest on judgment.

The split matters for a reason beyond tidiness. Because the deterministic majority is produced
by rules rather than reading, it comes out the same every time on an unchanged repository. That
reproducibility is what makes it possible to tell real drift from noise — without it, the file
would churn on every run and there would be no way to know whether something had actually
changed or the reading had simply come out differently.

## User Stories

- As a **maintainer/architect**, I want most of the table produced by rules rather than by
  reading, so that I can trust it without re-verifying every row by hand.
- As a **maintainer/architect**, I want re-running on an unchanged repository to reproduce the
  same deterministic rows exactly, so that any change I see in the file reflects a change in the
  project rather than a change in the reading.
- As a **KB reviewer**, I want the rows that required reading clearly marked as such, so that I
  know which parts of the table to scrutinise.
- As an **AI agent**, I want relationships harvested from what the Knowledge Base already
  declares — its cross-references, citations, and external-source keys — so that structure I can
  route over is captured rather than re-derived.

## Priority

Must

## Acceptance Criteria

- [ ] AC-5: Given an unchanged repository, when `/aid-graph` regenerates `relationships.md`,
      then the deterministic rows — those stamped as declared or derived — are byte-identical to
      the previous run's.
- [ ] Given a Knowledge Base document that cross-references another, cites evidence, or names an
      external-source key, when the first pass runs, then the corresponding relationship appears
      as a row stamped explicitly declared.
- [ ] Given a mechanically observable connection in the project source — a file reference, an
      invocation, a dependency edge — when the first pass runs, then the corresponding
      relationship appears as a row stamped mechanically derived.
- [ ] Given a concept-level Knowledge Base node that the scan cannot identify without reading,
      or a candidate connection the scan surfaced but could not type, when the second pass runs,
      then the resulting row is stamped inferred.
- [ ] Given a relationship the first pass has already settled, when the second pass runs, then
      it does not revisit that relationship — the reading pass is bounded to the residue.
- [ ] Given a complete extraction run, when the output is checked against feature-003's schema,
      then every row satisfies AC-1 through AC-4 — identifiers resolve, both relation directions
      are a valid inverse pair, no relationship is recorded twice, and every row carries a
      provenance value.

---

## Technical Specification

### The shared scanner seam (binding on `/aid-detail`)

**Feature-004 owns the walk; this feature owns the rows.** There is exactly one traversal of the
project source, `canonical/aid/scripts/graph/scan-source.sh`, and it belongs to feature-004.
This feature's deterministic pass **consumes** two streams that walk produced and never
re-walks:

- `.aid/.temp/graph/nodes.tsv` — the significant `int:` node set (feature-004 D1). Used as a
  closed set: pass 1 may only emit rows whose `int:` endpoints appear here, and pass 2 may only
  emit rows whose endpoints appear here or in the `kb:` set built in pass 1a.
- `.aid/.temp/graph/observations.tsv` — untyped, mechanically observed references, invocations,
  dependency edges, and includes (feature-004 D5). This feature turns them into typed rows; the
  scanner never types them.
- `.aid/.temp/graph/candidates.tsv` — what the rules could not settle (feature-004 D6). This is
  the *only* input to pass 2.

`tests/canonical/test-graph-single-scanner.sh` (specified in feature-004) asserts that no file
under `canonical/aid/scripts/graph/` other than `scan-source.sh` contains a repository
traversal. This feature's scripts therefore cannot grow a second walk without failing that
suite.

The KB side is different and is **owned here**: pass 1a's traversal of `.aid/knowledge/*.md` is
a single-directory, non-recursive read of the KB, not a repository walk, and it produces the
`kb:` node set nothing else produces.

### Data Model

#### D1. Row record (internal, pre-render)

Passes write a common TSV record; the writer renders it into feature-003's eight-column
markdown table. Tab-separated, LF-only, no header.

| # | Field | Value space |
|---|-------|-------------|
| 1 | `class` | `0` for `declared`/`derived`, `1` for `inferred` — feature-003 D7 |
| 2 | `source_id` | node id, canonical orientation (feature-003 D2, D7) |
| 3 | `source_name` | feature-003 D5 pure function |
| 4 | `target_id` | node id |
| 5 | `target_name` | feature-003 D5 pure function |
| 6 | `s2t` | vocabulary label |
| 7 | `t2s` | vocabulary label |
| 8 | `provenance` | `declared` \| `derived` \| `inferred` |
| 9 | `observation` | empty, or a durable anchor (class 0), or agent prose (class 1) |

Every row is passed through `rel_normalise_row` and keyed with `rel_row_key` (feature-003 D7)
before it enters the merge. Sorting is `LC_ALL=C` over
`(class, source_id, target_id, s2t, t2s, provenance)` — feature-003 D7 — so class 0 is a
contiguous prefix of the emitted table.

#### D2. `kb:` node set (built here)

Pass 1a builds `.aid/.temp/graph/kb-nodes.tsv`: `kb_id | name | doc | anchor`, one row per KB
document and one per ATX heading within it, with `kb_id` per feature-003 D2a and `name` per
feature-003 D5.

The document scan set is the same *set* `build-kb-index.sh` indexes: feature-003 D2a's membership
predicate `find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'` (that script pipes
it through a bare `sort`, so its order — not its membership — is locale-dependent; this feature
orders its own output with `LC_ALL=C`). Two documents are excluded **as sources of edges** while
remaining valid **targets**:

- `relationships.md` itself. Harvesting edges from the artifact being written would make the
  output depend on the previous run's output; the file would bootstrap itself and FR-32 would
  become unprovable. Self-exclusion is mandatory, not tidiness.
- `INDEX.md`. It is a generated re-presentation of every other doc's frontmatter (verified: its
  own frontmatter declares `source: generated`, `generator: build-kb-index.sh`, and the
  contract "One entry per non-dot, non-recursive KB document"). Harvesting its links would
  manufacture a `kb:INDEX.md → kb:<doc>` edge for every document in the KB and a duplicate of
  every `see_also:` edge already harvested from the source doc.

Both remain legitimate targets: a hand-authored doc citing `INDEX.md` produces a real edge.

The `kb:` and `int:` node sets are disjoint by construction — feature-004 D4 Class 4 excludes
`.aid/**` from `int:` enumeration precisely so a KB doc cannot appear on both sides of the
coverage question, and `test-graph-node-partition.sh` asserts it.

#### D3. Vocabulary and observation-kind mapping (unblocking feature-001)

**The vocabulary.** Loaded from the single source feature-001 authors and feature-003 D4 defines
the parse contract for — `canonical/aid/templates/graph/relation-vocabulary.yml` — through
`rel_load_vocabulary`. The file carries two top-level keys — `pairs:` and `categories:` — and each
`pairs:` entry carries **seven keys**: `relation`, `inverse`, `symmetry`, `category`,
`endpoint_kinds`, `passes`, `definition`, with `endpoint_kinds` and `passes` as one-line flow
sequences (feature-003 D4 states the parse contract this feature relies on; feature-001's SPEC
states what each field means). This feature reads the parsed values through the shared loader and
never re-parses the file, so the two consumers cannot drift. No relation label appears in this
feature's code.

Which of the seven this feature reads, and for what — stated explicitly so the claim is checkable
rather than assumed:

| Key | Read here? | Used for |
|-----|-----------|----------|
| `relation` | yes | the `s2t` label a harvest kind maps to; membership check before emitting |
| `inverse` | yes | `t2s`, looked up rather than chosen (below) |
| `passes` | **yes** | map-load legality gate: the pass emitting a kind must be listed in the mapped relation's `passes`; and a pass-2 rejection (Feature Flow step 10) |
| `endpoint_kinds` | **yes** | map-load legality gate: a kind's fixed endpoint prefix pair must be listed by the mapped relation; and a pass-2 rejection |
| `symmetry` | no | not needed: a symmetric pair falls out of `inverse == relation`, and feature-003's V4 owns row-level symmetric acceptance |
| `category` | no | carried by feature-003's loader for feature-007/008's grouping (FR-6); this writer never reads it |
| `definition` | no | human-facing; nothing mechanical depends on it |

**Reconciling feature-001's consumer table.** Feature-001 lists this feature as a consumer of
`Relation`/`Inverse`, `Passes`, and `Endpoint Kinds`. That claim is **correct**, and this revision
is what makes it so — an earlier draft of this spec read only `relation`/`inverse` and left
`passes` unread, which would have made feature-001's table wrong. Both fields are read from
`relation-vocabulary.yml` via `rel_load_vocabulary`, at **map-load time** (not per row), and both
are used as fail-closed configuration gates rather than as row findings. That placement matters
for FR-32: a gate that runs once, before any row exists, cannot introduce per-row variability.
Feature-001's own framing survives intact — it says the two fields "exist to serve consumers, not
to add a gate", meaning no *acceptance criterion* rests on them; the gate here is on this
feature's own configuration file, which is a different thing from gating the artifact.

**The edge-relation map — why a second file exists.** Pass 1 must *choose* a relation per
harvested edge, and the choosing key is a **harvest kind**, which is this feature's own concept:
the vocabulary cannot name harvest kinds without knowing about this feature's scanners, and
should not. So the binding lives in `canonical/aid/templates/graph/edge-relation-map.yml` (new,
owned here). Its **left three fields are fixed by this feature**; its **fourth is filled when
feature-001 lands**, naming a vocabulary relation by its `relation` label:

```yaml
# <harvest-kind>|<emitting-pass>|<endpoint-kinds>|<relation-label>
map:
  - frontmatter-see-also|declared|kb:->kb:|
  - frontmatter-sources-path|declared|kb:->int:|
  - frontmatter-sources-url|declared|kb:->ext:|
  - inline-doc-link|declared|kb:->kb:|
  - inline-durable-anchor|declared|kb:->int:|
  - evidence-citation|declared|kb:->int:,kb:->ext:|
  - path-reference|derived|int:->int:,int:->kb:|
  - invocation|derived|int:->int:|
  - dependency|derived|int:->int:,int:->kb:|
  - include|derived|int:->int:|
  - convention|derived|int:->int:|
```

Field 3 lists multiple endpoint pairs **comma-separated, with no space**, and that is a
correctness requirement rather than a style choice: a plain YAML scalar containing `: `
(colon-space) is read as a mapping, so `int:->int: int:->kb:` would parse as a key/value pair
instead of a value. Comma separation keeps every entry an unambiguous plain scalar and lets the
loader stay a line-oriented awk pass. This file therefore does **not** share the vocabulary's
flow-sequence encoding — feature-001 double-quotes its `endpoint_kinds` tokens because they sit in
*flow* context, which these do not — and the legality gate below compares the two after parsing,
never textually.

Fields 2 and 3 are not new facts — they are the *declaration* of facts this spec already fixes,
moved to where the loader can check them mechanically. Field 2 restates which pass emits the kind
(D4's carriers are pass 1a `declared`; feature-004 D5's observation kinds are pass 1b `derived`).
Field 3 restates the endpoint prefixes each kind can produce, taken from D4's "Row" column and
from feature-004 D5, whose `to_id` is "an `int:` or `kb:` node id". Two derived kinds are therefore
listed with both pairs: `dependency`, which crosses into `kb:` when `.aid/settings.yml`
`knowledge.doc_set` names a KB doc, and `path-reference`, since a source artifact citing
`.aid/knowledge/<doc>.md` is a real and useful coverage edge. `invocation`, `include`, and
`convention` stay `int:->int:` because their triggers are executable, include, and structural
references — none of which can resolve to a KB document.

Loader contract:

- Each entry is exactly four `|`-separated fields, the same intra-entry separator
  `.aid/settings.yml` already uses for `knowledge.doc_set`. Wrong arity → exit 2 naming the
  resolved absolute path and the entry.
- Every left-hand kind this feature can emit **must** have a non-empty relation label, and that
  label must be a vocabulary member; otherwise exit 2 naming the path and the unmapped kind.
- **Pass legality.** The entry's `<emitting-pass>` must appear in that relation's `passes` list.
  A map that routes a `derived` harvest to a relation the vocabulary marks `declared`-only is a
  configuration defect and exits 2.
- **Endpoint legality.** Every pair in the entry's `<endpoint-kinds>` must appear in that
  relation's `endpoint_kinds`. Same treatment: exit 2, at load, naming both sets.
- All three gates are fail-closed and run before any row is produced, so a misconfiguration
  surfaces as a usage error rather than as a table full of mistyped rows.
- `t2s` is never chosen: it is looked up as the `inverse` of the mapped relation. A pair is
  therefore internally consistent by construction, which is why feature-003's V4 should never
  fire on this writer's output; and because the endpoint gate already passed, feature-003's
  advisory V12 should not fire either.
- An observation whose kind carries no mapping becomes a **pass-2 candidate**, never an untyped
  row. There is no code path that emits a row with a blank or invented relation.

Consequence to state plainly: **feature-001 blocks a runnable pipeline, not this
specification.** `scan-source.sh` (feature-004) and `harvest-declared.sh` /
`derive-edges.sh` can be built and tested against a fixture vocabulary; only the real
`relationships.md` needs the real vocabulary. That is what D-1 means concretely.

#### D4. Declared-edge carriers — what actually exists in this KB

FR-30 names "KB frontmatter and cross-references, `Evidence:` citations, external-source keys".
Verified against this repository's KB, the harvestable carriers are:

| Harvest kind | Carrier, verified on disk | Row |
|---|---|---|
| `frontmatter-see-also` | `see_also:` list; present in every primary doc (e.g. `coding-standards.md` → `[authoring-conventions.md, module-map.md, test-landscape.md]`) | `kb:<doc>` → `kb:<entry>` |
| `frontmatter-sources-path` | `sources:` list entries that are repo-relative paths or globs (e.g. `authoring-conventions.md` → `.claude/aid/scripts/kb/lint-frontmatter.sh`) | `kb:<doc>` → `int:<resolved node>` |
| `frontmatter-sources-url` | `sources:` entries matching the URL shape `^[a-z][a-z0-9+.-]*://` (the detector `kb-freshness-check.sh` `is_url` already uses) | `kb:<doc>` → `ext:<key>`, **only if** the URL resolves to a registered key |
| `inline-doc-link` | a markdown link to a sibling KB doc, `[x.md](x.md)` or `[x.md](../knowledge/x.md)` — the two forms this KB uses (hand-authored inline links, and the `../knowledge/` form `build-kb-index.sh` emits) | `kb:<doc>` → `kb:<target doc>` |
| `inline-durable-anchor` | a path-or-basename citation in prose, matched with **the exact character class and extension set `kb-citation-lint.sh` already uses**: `[A-Za-z0-9_./-]+\.(md\|sh\|py\|mjs\|js\|ts\|yml\|yaml\|json\|toml\|txt\|ps1)` | `kb:<doc>` → `int:<resolved node>` |
| `evidence-citation` | a line whose first token is `Evidence:` | `kb:<doc>` → `int:` / `ext:` |

Two verified facts must be stated because they change what AC coverage means on this project:

1. **`Evidence:` has essentially zero occurrences in this KB.** A grep over
   `.aid/knowledge/` finds two hits, both in `coding-standards.md`, and both are prose labels
   inside a table/bullet ("Evidence: `read-setting.sh` opens with…"), not citation records. The
   pattern is supported for portability to other projects' KBs, but on AID's own KB it
   contributes no rows, and the real citation carrier in this project is the durable-anchor form
   `authoring-conventions.md` mandates and `kb-citation-lint.sh` gates. Recorded as a
   requirements-wording observation, not a change.
2. **No `ext:` edge is producible on this project.** `.aid/knowledge/external-sources.md` has
   zero registered entries (its `sources:` frontmatter holds the placeholder `- (none)` and its
   `## Sources` section says so in prose). The `frontmatter-sources-url` harvest therefore
   yields nothing here, which is exactly what Q4 found and why AC-1's `ext:` branch is proven
   against a synthetic fixture (A-6) rather than against this repository.

**Explicitly not an edge:** the frontmatter `contracts:` list. Its entries are structural
cardinality *assertions* (`frontmatter-schema.md` "`contracts:` (optional, list)"), not
references to a node, so they carry no endpoint pair. Also not an edge: `tags:`, `audience:`,
`owner:`, and `changelog:`.

**Resolution never guesses.** A `sources:` glob is expanded against `nodes.tsv` and each match
becomes an edge; a glob matching nothing becomes a candidate. A basename citation resolving to
exactly one surviving node becomes an edge — which works because feature-004's exclusion filter
removes the render copies (`build-kb-index.sh` exists at eight paths on disk; excluding
`profiles/**`, `.claude/**`, and `.cursor/**` leaves exactly one). A basename resolving to more
than one, or to zero, becomes a candidate with `drop_reason` `ambiguous-basename` or
`unresolved-reference`.

### Feature Flow

Inputs: the three feature-004 streams; `.aid/knowledge/*.md`; the vocabulary and edge-relation
map; `.aid/knowledge/external-sources.md`. Output: `.aid/knowledge/relationships.md`. No KB
content is modified (FR-10) — the only write outside `.aid/.temp/graph/` is the artifact itself.

**Pass 1a — declared harvest** (`harvest-declared.sh`)

1. Build the `kb:` node set (D2): the document scan set, minus `relationships.md` and
   `INDEX.md` as edge sources; ATX headings slugged per feature-003 D2a.
2. Read each source doc's frontmatter once with the batched awk extractor pattern shared by
   `lint-frontmatter.sh` (`load_frontmatter`) and `kb-freshness-check.sh` (`fm_scalar` /
   `fm_list`) — one pass per doc, arrays populated, no per-field fork.
3. Emit a row per D4 carrier; stamp `provenance = declared`, `class = 0`; type it through the
   edge-relation map (D3); set `observation` to the matched carrier anchor (e.g.
   `authoring-conventions.md sources: .claude/aid/scripts/kb/lint-frontmatter.sh`).
4. Unresolved or ambiguous references append to `candidates.tsv`.

**Pass 1b — derived harvest** (`derive-edges.sh`)

5. Read `observations.tsv`. For each row, look the `observation_kind` up in the edge-relation
   map, resolve `s2t`/`t2s` from the vocabulary, and emit a row with
   `provenance = derived`, `class = 0`, and `observation` set to the observation's evidence
   anchor verbatim.
6. An unmapped kind appends to `candidates.tsv` and emits nothing.

One consequence worth recording: the `dependency` observation over
`profiles/*/emission-manifest.jsonl` `src` → `dst` pairs yields no rows, because every `dst`
is inside an excluded render tree (feature-004 D4 Class 1). The manifest's *own* `src` side is
already covered by the `canonical/EMISSION-MANIFEST.md` declared carrier.

**The reproducibility boundary sits here — after step 6, before step 7.**

7. **Merge and freeze class 0** (`build-relationships.sh`). Normalise every class-0 row
   (feature-003 D7), key it, and de-duplicate: a repeated key keeps the row with the stronger
   provenance (`declared` over `derived`) and, on a tie, the lexicographically smaller
   `observation` — a total rule, so the survivor never depends on arrival order. Sort with
   `LC_ALL=C`. Write the frozen class-0 block to `.aid/.temp/graph/rows-class0.tsv` and record
   its key set.

**Pass 2 — bounded agent pass**

8. Compute the residue and nothing more. Pass 2's entire input is two closed sets:
   - `candidates.tsv` — the edges the rules could not settle; and
   - the concept-level `kb:` residue: heading-level `kb:` ids carrying **zero** class-0 edge.
     This is *computed* from step 7's output, not judged, so the residue is itself
     reproducible.
9. Dispatch the agent with those two files as its whole context and four hard bounds. The
   bounds are enforced by the merge in step 10, not by the prompt — a prompt-only bound is not
   a bound:
   - **Closed node set.** Both endpoints must already exist in `nodes.tsv` or `kb-nodes.tsv`.
     Pass 2 cannot mint a node. This is the downstream half of feature-004's `no-inferred-node`
     invariant (its D3): enumeration never admits a node on inferred evidence, and this bound
     stops the only later stage that could reintroduce one. Together they keep FR-24 intact end
     to end — every node carries `declared` or `derived` evidence, so no reported gap can
     originate in an opinion, and no consumer needs a filter for the case.
   - **No revisiting.** A row whose `rel_row_key` is already in step 7's key set is rejected.
     This is the mechanical form of the criterion "when the second pass runs, then it does not
     revisit that relationship".
   - **Class 1 only.** Every pass-2 row is stamped `provenance = inferred`, `class = 1`. A row
     arriving with any other provenance is rejected.
   - **Typed from the vocabulary.** `s2t` must be a vocabulary member and `t2s` is looked up as
     its inverse, exactly as in pass 1. Two further vocabulary checks apply here, using the two
     fields D3 records this feature as reading: the chosen relation's `passes` must include
     `inferred`, and its `endpoint_kinds` must list the row's `<source-prefix>-><target-prefix>`
     pair. A relation the vocabulary reserves for the deterministic passes, or one used across
     an endpoint pair it does not admit, is rejected. Free text goes in `observation`, per §5.4.
10. **Merge class 1.** Apply the four rejections above, normalise, key, de-duplicate against
    both the class-0 key set and other class-1 rows, sort with `LC_ALL=C`. Rejected rows are
    reported to stderr with a reason and dropped; a rejection is never fatal, because FR-25's
    reporting-not-gating posture applies to the run as a whole.
11. **Render and write.** Emit feature-003 D8's frontmatter, the `AUTO-GENERATED` marker (with
    no timestamp), the `# Relationships` title, then the eight-column table: class-0 rows first
    as a contiguous block, class-1 rows after. LF endings, single-space cell padding, `|`
    escaped as `\|`.
12. **Self-validate.** Invoke `validate-relationships.sh` (feature-003) on the file just
    written. A non-zero exit is reported and surfaces as ledger findings; the artifact is still
    written, so the failure is visible rather than hidden behind a missing file.

Exit codes: `0` success, `1` a write failure or a validator finding, `2` usage error or a
missing/malformed vocabulary, edge-relation map, or feature-004 stream. Reusing the documented
scheme rather than inventing codes, per `coding-standards.md` ("A new failure mode SHOULD reuse
an existing code with matching semantics").

#### What guarantees FR-32 / AC-5

Byte-identity of the deterministic majority on an unchanged repository rests on seven
mechanisms, each of which is a stated rule with a test:

1. **Contiguity.** Class-major sort order (feature-003 D7) makes class 0 a contiguous prefix, so
   no class-1 change can move, split, or reflow a deterministic row.
2. **Enforced one-way merge.** Step 10 rejects any class-1 row that collides with a class-0
   key and any row not stamped `inferred`, so pass 2 has no write path into class 0 at all.
3. **Stable ordering.** `LC_ALL=C` on every sort this feature performs, including its own
   enumeration of the D2 scan set. The precedent is `build-project-index.sh`
   (`| LC_ALL=C sort`, line 185) and `kb-freshness-check.sh` (line 460); `build-kb-index.sh`'s
   scan is *not* a precedent, because its `sort` is bare (line 471) — see feature-003 D2a. This
   feature relies on nothing that script orders.
4. **Stable ids and names.** Ids are pure functions of on-disk paths and document/heading text;
   names are pure functions of ids (feature-003 D5). No `$PWD`, no absolute path, no drive
   letter, no repo-root prefix appears in any cell.
5. **No time and no position inside the boundary.** No timestamp in the table, in any row, or
   in the `AUTO-GENERATED` marker — the deliberate divergence from `INDEX.md`, which embeds
   `$TS` and therefore churns — and no `changelog:` date. No mtime, no file size, no line
   number; `observation` anchors are grep-recoverable literals, which is both the citation rule
   (`authoring-conventions.md` "Citation Rule") and a byte-stability requirement. Feature-010's
   two generator-written frontmatter scalars (`graph_inputs_digest`, `graph_generated_at`) sit
   **outside** the boundary by design — see feature-003 D8. This is why the boundary is drawn
   around the class-0 row block rather than the whole file: FR-32 binds "the deterministic
   majority", so a content-addressed staleness record in the frontmatter and a byte-identical
   deterministic block can both hold at once.
6. **Total tie-breaks.** Both de-duplication rules (step 7 and step 10) are total orders, so
   the surviving row never depends on arrival order; and step 6's fixed-point settling in
   feature-004 makes the node set independent of traversal order.
7. **LF-only output**, written the way `canonical/EMISSION-MANIFEST.md` mandates for the
   emission manifest ("LF (`\n`) only, even on Windows"). The repository is authored on Windows
   (`test-landscape.md`, "Exec-bit fix"), so this is a live hazard, not a formality.

**AC-5's mechanical check** is feature-003 D7's: regenerate, extract the class-0 prefix, and
byte-compare against the class-0 prefix of `git show HEAD:.aid/knowledge/relationships.md`. No
stored hash and no side-channel file is needed, and `.aid/knowledge/` is not gitignored
(verified: `.gitignore` excludes only `.aid/knowledge/.cache/`). Whether a staleness *decision*
follows from that comparison is FR-11/feature-010's call. For contrast, the existing
`/aid-summarize` staleness mechanism —
`.claude/aid/scripts/summarize/stale-check.sh` — compares two **dates** from
`.aid/knowledge/STATE.md` (`## Review History` versus `## Summarization History`) and emits
`STALE` / `CURRENT_APPROVED` / `CURRENT_UNAPPROVED` / `FIRST_RUN`. A date comparison cannot
tell drift from model nondeterminism, which is precisely the gap FR-32 closes and FR-11 relies
on: `/aid-graph`'s staleness input set is wider (KB + project source + external-sources file),
so a content comparison is the only sound basis for it.

### Layers & Components

New files only; no existing script is forked (C-4). Authored in `canonical/`, then rendered by
the FULL `run_generator.py` — never hand-edited under `profiles/` or the dogfood `.claude/`
(C-2; `module-map.md` Invariants). `canonical/aid/scripts/` and `canonical/aid/templates/` are
both recognised asset kinds in `canonical/EMISSION-MANIFEST.md`'s "Asset Kinds" table, so a new
`graph/` subdirectory renders into all five profiles with no renderer change; render-drift CI
gates the result (C-3).

| Layer | Path | Purpose |
|-------|------|---------|
| Script | `canonical/aid/scripts/graph/harvest-declared.sh` | pass 1a — the `kb:` node set and the declared carriers (D4) |
| Script | `canonical/aid/scripts/graph/derive-edges.sh` | pass 1b — types feature-004's observations; no traversal of its own |
| Script | `canonical/aid/scripts/graph/build-relationships.sh` | steps 7, 10, 11, 12 — merge, freeze class 0, bound and merge class 1, render, self-validate. This is the `generator:` value in feature-003 D8's frontmatter |
| Template | `canonical/aid/templates/graph/edge-relation-map.yml` | D3 — `<harvest-kind>\|<emitting-pass>\|<endpoint-kinds>\|<relation-label>`; the first three fields fixed here, the fourth filled by feature-001 |
| Reference (prose) | `canonical/skills/aid-graph/references/agent-pass.md` | the pass-2 dispatch prompt and its four bounds, authored as skill prose per `authoring-conventions.md` "Prose Over Scripts"; the enforcement lives in `build-relationships.sh`. The `canonical/skills/aid-graph/` directory itself is created by the skill-wiring feature (FR-7); this feature contributes only this reference file into it |
| Script library | reuses `canonical/aid/scripts/graph/relationship-schema.sh` (feature-003 D9) | id parsing, normalisation, keys, sort keys, vocabulary loading |
| Test | `tests/canonical/test-harvest-declared.sh` | one fixture per D4 carrier, plus the `relationships.md`/`INDEX.md` source-exclusion assertions |
| Test | `tests/canonical/test-derive-edges.sh` | one fixture per observation kind; unmapped kind → candidate, never an untyped row; and the three D3 map-load gates (unmapped kind, pass-illegal mapping, endpoint-illegal mapping) each exit 2 |
| Test | `tests/canonical/test-relationships-reproducible.sh` | AC-5: two consecutive runs on an unchanged fixture tree yield a byte-identical class-0 block; then a class-1 row is added, removed, and reworded and the class-0 block is asserted unchanged |
| Test | `tests/canonical/test-agent-pass-bounds.sh` | each of the four bounds rejects a crafted violating row (new node id, colliding key, non-`inferred` provenance, and — for the typing bound — a non-vocabulary label, a relation whose `passes` excludes `inferred`, and a relation whose `endpoint_kinds` excludes the row's prefix pair) |
| Fixtures | `tests/canonical/fixtures/graph/` | a self-built miniature KB + source tree, a fixture vocabulary and edge-relation map, and the Q4 synthetic `external-sources.md` |

Conventions honoured (`coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; header block with Purpose / Usage / Exit codes; `-h|--help` re-printing
  a slice of it.
- `set -euo pipefail` for the three writing scripts; argument parsing via the
  `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with `shift 2`; unknown flag →
  stderr + exit 2; file errors print the resolved absolute path.
- stdout carries results, stderr carries diagnostics; a one-line prefixed summary per script
  (`[harvest] …`, `[derive] …`, `[relationships] …`), matching the `[index]`-prefixed style of
  `build-project-index.sh`.
- Frontmatter is parsed with the project's awk extractors — one batched pass per doc, no per-field
  fork (the pattern both `lint-frontmatter.sh` `load_frontmatter` and `kb-freshness-check.sh`
  `fm_scalar`/`fm_list` establish, and which `build-kb-index.sh` records as a deliberate
  Windows-Git-Bash fork-cost optimisation).
- No YAML/JSON binary dependency; the flat YAML this feature reads is parsed with awk, as
  `coding-standards.md` prescribes for AID's own simple configs.
- Any value read from frontmatter or from a template file is treated as untrusted when passed to
  git — `--end-of-options` guards a commit-ish, as `kb-freshness-check.sh` does.
- Tests are discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob; fixtures are
  self-built and reference nothing under `.aid/works/` (A-6 and the project's
  transient-work-folder rule).

### External Integrations

Pass 2 is the one part of this feature that is not a script, so its integration surface is
stated rather than assumed.

- **What it is.** A sub-agent dispatch to the host AI harness the user is running under. There
  is no network call, no MCP server, and no external service: `integration-map.md` records that
  "AID is a distributed toolkit, not a networked service" and that the only runtime HTTP surface
  in the project is the loopback-bound dashboard server. Pass 2 adds no new external dependency
  and no credential.
- **Which role.** `aid-researcher` — the agent whose remit is reading code and docs to produce
  structured analysis. `aid-architect` designs and `aid-developer` writes production code;
  neither fits a read-and-classify task.
- **Contract.** Input: the two closed residue files (step 8) and the vocabulary. Output: class-1
  rows in D1's TSV shape, appended to `.aid/.temp/graph/rows-class1.tsv`. Nothing else is
  writable by the pass.
- **Trust boundary.** The agent's output is untrusted input to `build-relationships.sh`, which
  applies the four bounds of step 9 and drops violations. This is the same posture the project
  takes elsewhere with agent- or frontmatter-sourced values.
- **Graceful degradation.** If the pass cannot run — no host agent available, dispatch failure,
  or an empty residue — the run completes and the artifact ships with class-0 rows only. The
  deterministic majority is the product; the reading pass is an enrichment. This mirrors the
  precedent `test-landscape.md` records for the Playwright visual-fidelity gate, which "exits 0
  with a SKIP" when its runtime is absent, and it keeps FR-25's reporting-not-gating posture.
- **Heartbeat and stop.** A long pass-2 dispatch follows the project's sub-agent heartbeat and
  cooperative-stop protocol (`HEARTBEAT_FILE` / `HEARTBEAT_INTERVAL`, with
  `heartbeat_interval` resolved from `.aid/settings.yml`, where it is a top-level scalar).

### Open Items

1. **FR-30's `Evidence:` carrier.** Named in the requirement, effectively absent from this
   project's KB (D4 fact 1). The harvest supports it for portability; on AID's own KB the
   acceptance criterion "a Knowledge Base document that … cites evidence" is satisfied through
   the durable-anchor citation form instead. A wording amendment to FR-30 would remove the
   mismatch; it is not required for implementation.
2. **`ext:` coverage on this project** is zero until `external-sources.md` gains registered
   entries in the form feature-003 D2c defines, and that file's writer is `/aid-discover`
   ELICIT, not this skill (FR-10). Q4's fixture decision already covers acceptance; what is
   open is whether the owner wants real entries registered so the dogfood graph exercises the
   `ext:` path at all.
3. **Residue size for pass 2.** The heading-level `kb:` residue is bounded only by the KB's
   heading count. If it proves large enough to strain a single dispatch, the pass splits per
   document — a batching decision, not a contract change, since every bound in step 9 is
   per-row.
