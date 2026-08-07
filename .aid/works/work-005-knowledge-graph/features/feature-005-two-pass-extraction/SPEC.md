# Two-Pass Relationship Extraction

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.8 (FR-29–FR-32), §5.1, FR-1, §9 (AC-5) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — D3 rebound to feature-001's seven-field YAML vocabulary entry; the fields this feature consumes are now stated, and `passes` / `endpoint_kinds` are genuinely read (map-time legality gates + a pass-2 rejection), reconciling feature-001's consumer-table claim | /aid-specify |
| 2026-07-28 | Gate finding 2 [LOW] follow-through — `build-kb-index.sh`'s bare `sort` no longer cited as an `LC_ALL=C` precedent (D2, FR-32 mechanism 3) | /aid-specify |
| 2026-07-28 | Gate finding 3 [HIGH] follow-through — pass 2's closed-node-set bound restated as the downstream half of feature-004's `no-inferred-node` invariant | /aid-specify |
| 2026-07-29 | Re-specified against the amended REQUIREMENTS.md and the three A+ upstream SPECs (feature-001, feature-003, feature-004), consumed as immutable inputs. Pass 1 widened to the four KB-side node kinds and their edges (D2); Pass 2 narrowed to typing, bounded by FR-31a's four mechanisms (D6); row record re-shaped to ten columns (D1); `endpoint_kinds` and the edge-relation map re-keyed from id prefixes to `Kind` values (D3); vocabulary entry read as eight keys (D3). Three upstream-routed decisions made: the `fact` carrier (D7), the W3 producer-satisfiability map (D8), the `image-reference` map row (D4 kind 13). The `Evidence:` harvest kind is struck, following FR-30's 2026-07-28 correction. Q17 proxy sweep recorded (§ Proxy sweep) | /aid-specify |
| 2026-07-29 | Gate findings 1–7 fixed: Pass 2's tool restriction stated as part of the bound and its enforcement located (D6 part 1); three W3 justifications re-argued on carrier availability rather than consumer demand, conceivability, or unsourced authority (D8); AC-S8 added for `documents` provenance; every Open Item routed to a gated feature now states the reopen-and-re-gate consequence. Q18 ruling 2 discharged — the false merge is closed by a decidable advisory candidate report (D2f, AC-S7), replacing the recorded blind spot | /aid-specify |
| 2026-07-29 | Gate findings 8–9 fixed. [LOW] D2f keeps condition 4 and publishes four reach counters instead, so its narrowness is measured rather than described, with AC-S7 discharged on A-6/AC-1's synthetic-fixture precedent (new AC-S7a). [MEDIUM] The cross-file ordering of the six extra coverage rows is filed as Open Item 16 — owners feature-003 (ordering contract, reopens and re-gates) and feature-010 (assembly) — and deliberately not specified here | /aid-specify |

## Source

- REQUIREMENTS.md §5.8 — **FR-29** (script-majority, agent-in-the-gaps), **FR-30** (Pass 1, widened to
  produce the `section`, `fact` and `concept` nodes and their declaring edges), **FR-31** (Pass 2,
  narrowed to typing edges rather than discovering nodes), **FR-31a** (the four-part bound),
  **FR-32** (byte-identity over the grown deterministic set, keyed to FR-11's five staleness inputs)
- REQUIREMENTS.md §5.1 — the three relationship sources every row is drawn from
- REQUIREMENTS.md §5.2 / §5.3 — the **ten**-column shape, the `Kind` enum, and the per-kind id
  grammars this feature writes rows into; **owned by feature-003**, consumed here
- REQUIREMENTS.md §5 — **FR-1** (this feature produces the *content* of `relationships.md`),
  **FR-3** (the table is the single input to the graph — so a node with no row is not in the graph,
  which is why Pass 1 emits containment edges), **FR-9a** (the `## Coverage notes` rows this feature
  contributes), **FR-10** (read-only with respect to KB content), **FR-11** (the five staleness
  inputs this feature's reproducibility makes meaningful; feature-010 owns the check)
- REQUIREMENTS.md §5.7 — **FR-21a** (KB-side nodes qualify **by kind**, via FR-30's deterministic
  extraction, not by significance), **FR-23** (asymmetric granularity), **FR-24** (derivable rather
  than judged — the requirement Pass 1's decidability argument answers)
- REQUIREMENTS.md §5.5 — **FR-8a** (genericity: any project with an approved AID KB; KB authoring
  conventions are legitimate carriers, this repository's content is not)
- REQUIREMENTS.md §9 — **AC-1**, **AC-2**, **AC-2a**, **AC-3**, **AC-4**, **AC-5**, **AC-12**
  (support), **AC-16** (KB clause), **AC-19**, **AC-20**
- STATE.md `## Cross-phase Q&A` — **Q13** (what a fact is, what a concept is, and the **concept merge
  rule**), **Q14** (the ten-column consequence and the `Kind` enum), **Q15** (the deferred
  author-level decisions, made by feature-003 and consumed here), **Q17** (the proxy-defect class —
  swept for at § Proxy sweep)

**Immutable upstream inputs.** feature-001, feature-003 and feature-004 are gated A+ and are consumed,
never restated as this feature's own:

| Owner | What it owns that this feature consumes |
|-------|------------------------------------------|
| **feature-003** | the ten-column contract and its byte grammar (D1), both closed enums (D1a), the per-kind id grammars and resolution checks (D2), heading slugification (D2a-1), the `<anchor-token>` format (D2a-2), concept normalisation and same-label disambiguation (D2a-3), the **block-body algorithm** (D2a-3a), the vocabulary loader and merge (D4), display names (D5), the `Observation` constraint (D6), row normalisation, the row key and the **total row order** (D7), the class-0 block extraction (D7b), the coverage-notes **shape** (D7a), the frontmatter (D8), the loader library (D9), and validators V1–V15 |
| **feature-001** | the vocabulary itself — 31 pairs / 57 entries / 14 categories, the **eight**-key entry with `derived_from`, `endpoint_kinds` **re-keyed to the seven `Kind` values**, the six cross-entry properties, and the `image-reference` → `illustrated-by`/`illustrates` mapping (D6c) |
| **feature-004** | the single source walk and its four streams — `nodes.tsv`, `media-nodes.tsv`, `observations.tsv`, `candidates.tsv` — the `source-artifact` / `image` / `web-page` node kinds, the `no-inferred-node` invariant, the observation kinds and their resolution rules (D5), and the `present`-iff-≥1-carrier-instance predicate (D7) |

Where this SPEC needed something an upstream feature owns, it consumes that contract. Where it
disagrees or needs more, the item is routed under **Open Items** with the owner named and is never
resolved silently here.

**Dependency position.** Blocked by feature-001 (rows cannot be typed without the vocabulary),
feature-003 (rows must be written in the agreed shape, and every id-computing function is its
library), and feature-004 (three of the seven node kinds, plus every observation). Blocks
feature-006 (which needs KB coverage to compute gaps), feature-002 (whose bench needs **merged**
concept nodes to exist — D-2a), and supplies the real data feature-007 through feature-009 render.

## Description

Relationships are extracted by two passes with different characters, not by one mechanism asked to
do everything. The bulk of the work is done by a deterministic scan; a reading pass then handles
only what the scan could not settle.

The first pass does two jobs that used to be thought of as one. It **finds the things inside the
Knowledge Base that are worth pointing at** — each document, each section of each document, each
claim that carries a checkable reference to its evidence, and each term the Knowledge Base defines —
and it **records how those things relate**, to each other and to the project's own files, images and
external sources. Both jobs are done by rules rather than by reading, because a heading, a citation
and a glossary entry are all literal text: finding them takes no judgment, so they must not fall to
the pass that judges.

A defined term is one thing, however many documents talk about it. A term defined once and mentioned
in five places is a single node reached by five relationships, not five copies of the same idea, so
how often a term is discussed shows up as how connected it is rather than as clutter.

The second pass reads, and it is deliberately fenced in. It may read each Knowledge Base document
once and nothing else — it may not follow a reference out of the Knowledge Base, walk the project
source, or fetch anything. It may record relationships between things that already exist, and it may
never bring a new thing into existence. Its two jobs are naming the relationships the scan noticed
but could not classify, and recording the relationships a person only sees by reading — and the
second of those is genuine discovery, which is in scope. It finishes only when every one of those
leftover relationships has either been named or been explicitly marked as one it could not name.
Leaving one unaccounted for is a failure of the run, not a quiet omission.

Rows the rules produced are marked as either stated outright or mechanically computed; rows the
reading pass produced are marked as concluded by reading. That marking is what lets a reader trust
or discount any single row.

The split matters for a reason beyond tidiness. Because the deterministic majority is produced by
rules, it comes out the same every time so long as none of the five things the run depends on has
changed. That reproducibility is what makes it possible to tell real drift from noise — without it,
the file would churn on every run and no one could tell whether something had actually changed or
the reading had simply come out differently.

## User Stories

- As a **maintainer/architect**, I want most of the table produced by rules rather than by reading,
  so that I can trust it without re-verifying every row by hand.
- As a **maintainer/architect**, I want a term defined once and discussed everywhere to be one node
  with many connections, so that the graph shows me what is central instead of showing me the same
  idea repeatedly.
- As a **maintainer/architect**, I want re-running with nothing changed to reproduce the same
  deterministic rows exactly, so that any change I see in the file reflects a change in the project
  rather than a change in the reading.
- As a **KB reviewer**, I want the rows that required reading clearly marked as such, so that I know
  which parts of the table to scrutinise.
- As a **KB reviewer**, I want a leftover the reading pass could not classify to be reported rather
  than dropped, so that the pass cannot finish by giving up quietly.
- As an **AI agent**, I want each section and each anchored claim to be addressable in its own right
  and connected to the document that carries it, so that I can route to the paragraph rather than to
  the file.
- As a **maintainer adopting AID on another project**, I want a Knowledge Base with no glossary, no
  citation anchors or no headings to yield fewer nodes rather than a failed run, so that the tool
  works before my conventions are complete.

## Priority

Must

## Acceptance Criteria

- [ ] AC-1 (producer side): Given a generated `relationships.md`, when feature-003's V2 resolves
      every id this feature wrote, then each resolves by the protocol for its own `Kind` — because
      every id is computed by a feature-003 D9 function (`rel_doc_slugs`, `rel_fact_tokens`,
      `rel_normalise_term` + `rel_concept_defs`) and V2 recomputes it with the same function rather
      than trusting the table.
- [ ] AC-2 / AC-2a: Given a generated `relationships.md`, when V3, V4 and V13 run, then no finding
      is raised against a row this feature wrote — every relation label comes from the merged
      vocabulary through `rel_load_vocabulary`, `T2S` is looked up as the mapped relation's
      `inverse` and never chosen, and both `Kind` cells are carried from their node record rather
      than derived from a prefix.
- [ ] AC-3: Given a generated `relationships.md`, when V5 runs, then no two rows share a
      `rel_row_key` — every row is normalised with `rel_normalise_row` and de-duplicated on that key
      by a total rule before it is emitted.
- [ ] AC-4: Given a generated `relationships.md`, when V6 runs, then every row carries exactly one
      of `declared`, `derived`, `inferred`, assigned by D5's carrier rule rather than left to a
      default.
- [ ] AC-5: Given a regeneration with **all five of FR-11's staleness inputs unchanged**, when
      `rel_class0_block` and the `## Coverage notes` section are byte-compared against
      `git show HEAD:.aid/knowledge/relationships.md`, then both are byte-identical — including the
      `section`, `fact` and `concept` nodes and their declaring edges, which the deterministic set
      grew to cover on 2026-07-29.
- [ ] AC-16 (KB clause): Given a generated `relationships.md`, when every id is inspected, then
      `kb:` ids carry section, fact and concept forms while no `int:` id carries a `#` fragment of
      any kind — this feature emits no `int:` id it did not read from feature-004's streams.
- [ ] AC-19 (this feature's four kinds): Given a KB lacking a carrier convention, when the run
      completes, then it exits successfully with **zero** nodes of the affected kind — no definition
      marker ⇒ zero `concept` nodes; no checkable source anchor ⇒ zero `fact` nodes; no heading at
      level 2–6 ⇒ zero `section` nodes — and each absence is recorded in the coverage notes with its
      convention, status and count, never as a gap-ledger row.
- [ ] AC-20 (this feature's contribution): Given a run on a project where every carrier convention
      is present, when `kb-coverage.tsv` is read, then this feature has still contributed a row for
      **every** one of `document`, `section`, `fact` and `concept`, each with its carrier text,
      `present`/`absent` status and node count.
- [ ] AC-S1: Given Pass 1, when a KB document is scanned, then it is read in **one** forward pass
      that computes heading slugs, fact tokens, block bodies, the enclosing-node chain and every
      inline carrier from a **single shared fenced-code state** — so the heading counter, the block
      boundaries and the marker scan cannot disagree about where a fence begins.
- [ ] AC-S2: Given a concept named in more than one document, when Pass 1 emits, then exactly one
      `concept` node exists for its normalised term and each mention is a separate `mentions` edge —
      so mention count appears as graph degree and never as duplicate nodes (Q13).
- [ ] AC-S3: Given Pass 2, when it runs, then every id it writes already appears in `kb-nodes.tsv`,
      `nodes.tsv` or `media-nodes.tsv`, and a row naming any other id is rejected by the merge —
      enforced by the merge and not by the dispatch prompt (FR-31a part 2).
- [ ] AC-S4: Given Pass 2 has run and returned, when the run completes, then every candidate in
      `candidates.tsv` carries either an accepted class-1 row or a `cannot-type` disposition, and
      every document in the input manifest appears exactly once in the read ledger; a shortfall in
      either exits `1` naming each item (FR-31a part 4).
- [ ] AC-S5: Given the edge-relation map, when it loads, then every entry's kind pair is a member of
      the mapped relation's `endpoint_kinds` and every provenance it can emit is a member of that
      relation's `passes` — checked once at load, before any row exists, and exiting `2` on failure.
- [ ] AC-S6: Given a run, when the W3 producer-satisfiability report (D8) is produced, then every
      declared `endpoint_kinds` token of every core entry carries exactly one of `producer`,
      `inferred-only` or `unreachable`, and the report gates nothing.
- [ ] AC-S7: Given a plain-form `concept` node whose mentioning document is linked to its defining
      document by no class-0 row **and** shares no other concept with it, when the run completes,
      then the pair is listed in `concept-merge-candidates.tsv`, reported on stdout at `[LOW]` and
      counted in the coverage notes — while a pair failing either condition, a pair whose concept is
      in the `@<doc>` qualified form, and a pair whose defining document names no second concept are
      each **not** listed, no gap-ledger row is written, and the exit code is unaffected (D2f, Q18
      ruling 2, FR-24). **Discharged against the self-built fixture, on A-6's and AC-1's precedent** —
      the `ext:` branch is validated against a synthetic fixture because this project's own file
      would satisfy it vacuously, and the same reasoning applies here: the fixture proves the detector
      fires whether or not this repository's KB holds an ambiguous label.
- [ ] AC-S7a: Given any run, when it completes, then the run reports `pairs_1_3`,
      `filtered_by_shared_vocabulary`, `skipped_single_concept` and `candidates`, with
      `candidates = pairs_1_3 − filtered_by_shared_vocabulary` — so a zero candidate count is
      distinguishable from a detector that never reached condition 4, and condition 4's reach loss is
      a number rather than a caveat (D2f).
- [ ] AC-S8: Given a `sources:` entry that is a bare basename resolving to exactly one path, when the
      `documents` row is emitted, then its `Provenance` is **`declared`** — keyed on the statement,
      per D5 and Open Item 4 — even though the target id required resolution, which is the case where
      following `illustrated-by`'s resolution-keyed precedent (feature-001 D6c) would wrongly yield
      `derived`.

> **The `AC-S<n>` scheme** is feature-003's, introduced in its own SPEC and also adopted by
> feature-001. It is reused here unchanged for the same reason: the eight criteria above are
> **SPEC-authored** — no requirement states them — so they carry no requirement number, and the
> requirements' grammar always places a digit immediately after `AC-`, which makes `AC-S<n>`
> collision-proof. `AC-S7a` takes a letter suffix on the same convention the requirements use for a
> criterion added beside an existing one (`AC-2a`, `FR-31a`): it is the reach half of AC-S7, not a
> separate obligation.

---

## Technical Specification

> The amended REQUIREMENTS.md (2026-07-29) is the authority, and feature-001's, feature-003's and
> feature-004's contracts are **immutable inputs**.

**How to read the "which requirement, checked how" claims.** Every mechanism below names the
requirement it satisfies and the validator or test that decides it. That pairing is deliberate: this
work's recorded failure mode (Q9, Q15) was an artifact that was complete, traceable and internally
consistent while answering the wrong question, so a mechanism with nothing behind it is treated here
as undelivered.

**Reading convention for `D`-references.** An unqualified `D1`, `D2a`, `D5` and so on always means
**this SPEC's** section. A reference to a sibling's is always written `feature-003 D<n>`,
`feature-004 D<n>` or `feature-001 D<n>`. The overlap is real — feature-003's `D5` is the
display-name rule, feature-004's `D5` is the observation record, and this SPEC's `D5` is the
provenance rule — so the qualification is load-bearing rather than pedantic.

### The extraction boundary — what this feature produces

Stated first, because the previous revision produced **file-level relationships only** and a reader
must not carry that model forward.

| §5.2 `Kind` | Node produced by | Mechanism |
|-------------|------------------|-----------|
| `document` | **this feature**, Pass 1a | the KB scan set — feature-003 D2a's membership predicate |
| `section` | **this feature**, Pass 1a | ATX headings, levels 2–6 — feature-003 D2a-1 (FR-30) |
| `fact` | **this feature**, Pass 1a | checkable source anchors — feature-003 D2a-2 (FR-30) |
| `concept` | **this feature**, Pass 1a | definition markers under a level-3+ heading, merged on the normalised term — feature-003 D2a-3 / D2a-3a (FR-30, Q13) |
| `source-artifact` | feature-004 | the single source walk + FR-21 significance |
| `image` | feature-004 | the same walk + the `image_extensions:` test; or the `ext:` registry |
| `web-page` | feature-004 | the `ext:` registry predicate |

Four consequences, each checkable rather than trusted:

1. **Pass 2 produces no node of any kind.** FR-31a part 2 states it; D6 enforces it in the merge.
   The complete node set is therefore feature-004's two streams plus this feature's Pass 1a output,
   with no third producer and no promotion path.
2. **Every KB-side node is `declared` or `derived`, never `inferred`.** FR-21a makes KB-side nodes
   qualify **by kind** via FR-30's deterministic extraction rather than by significance, and Q13
   requires a fact node's provenance to be `declared` or `derived`. This is the KB-side half of
   feature-004's `no-inferred-node` invariant, and D2 holds it by construction: every node id is the
   output of a feature-003 D9 function over document bytes.
3. **A node with no row does not appear in the graph.** FR-3 makes the table the single input to
   the graph, so a node the extraction emits but never relates is invisible. That is why Pass 1
   emits containment edges (`has-part`) for `section` and `fact` nodes and a definition edge
   (`defines`) for every `concept` — without them, roughly doubling the node count would add nothing
   a reader could see.
4. **This feature never walks the project source.** feature-004 owns the one walk; the KB scan is a
   depth-1 read of a single directory, which feature-004's own seam guard exempts by name.

### Extraction rules at a glance

One row per rule this feature owns. Every decision procedure is a total function whose inputs are
document bytes, a feature-004 stream, or a shipped data file — which is what makes FR-24's
*derivable rather than judged* hold by construction rather than by discipline.

| # | Rule | Requirement | Decision procedure (what makes it decidable) | Checked by |
|---|------|-------------|----------------------------------------------|-----------|
| R1 | The KB scan set is feature-003's membership predicate, consumed as a set | FR-30, AC-18 | `find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'` — locale-independent as a *set*; this feature supplies its own `LC_ALL=C` order | feature-003 **V2** (`document` branch); `test-harvest-declared.sh` |
| R2 | Two generated documents are excluded as sources of sub-document nodes and edges | FR-32 | a two-name literal test (`relationships.md`, `INDEX.md`), applied before the scan; both remain valid **targets** (D2a) | `test-harvest-declared.sh` (source-exclusion assertions) |
| R3 | Every node id is computed by a feature-003 D9 function, never authored | AC-1, FR-24 | `rel_doc_slugs`, `rel_fact_tokens`, `rel_normalise_term`, `rel_concept_defs` — the same functions **V2** recomputes | feature-003 **V2**; `test-kb-node-set.sh` |
| R4 | One forward pass per document, one shared fence state | FR-32, AC-1 | slugs, fact tokens, block bodies, the enclosing chain and inline carriers are computed together; no second scan can disagree about a fence | AC-S1; `test-kb-node-set.sh` (a fenced heading-shaped line and a fenced marker) |
| R5 | A concept is one node per normalised term; each mention is an edge | Q13, §5.3 | `rel_normalise_term` for identity; `rel_concept_defs` requires **exactly one** definition or forces the `@<doc>` qualified form; mentions are literal token-bounded matches of the defining heading text (D2d) | AC-S2; feature-003 **V2**, **V15**; `test-concept-merge.sh` |
| R6 | An inline carrier's source is the nearest enclosing node the mapped relation admits | FR-23, AC-2 | the enclosing chain `fact ⊃ section ⊃ document` is computed in R4's pass; the **ceiling** is data — the map entry's kind pair, gated against `endpoint_kinds` at load (D2e, D3) | AC-S5; `test-derive-edges.sh` |
| R7 | Provenance is a property of the **carrier**, not of the content | §5.2, FR-24 | `declared` iff the carrier states the relationship in the source text; `derived` iff the scan computed the relationship; one inherited exception, stated at D5 | feature-003 **V6**; `test-provenance-rule.sh` |
| R8 | No relation label appears in this feature's code | FR-4, FR-8a | every label is read from the merged vocabulary through `rel_load_vocabulary` and reached through the edge-relation map; a grep of `canonical/aid/scripts/graph/` returns none | `test-derive-edges.sh`; reviewable by grep |
| R9 | Pass 2 may create edges, never nodes | FR-31a part 2 | the merge tests both endpoint ids against the union of the three node streams; anything else is rejected | AC-S3; `test-agent-pass-bounds.sh` |
| R10 | Pass 2 reads each KB document at most once | FR-31a part 1 | **one dispatch per document**, driven by a manifest built before the pass starts, with the document's text **inlined and no tool granted** (D6 part 1) — the loop and the empty tool set, not the agent's discipline, are what make "at most once" true | AC-S4; `test-agent-pass-bounds.sh` (including the `agent-pass.md` tool-set clause) |
| R11 | Every Pass-1 candidate ends typed or explicitly dispositioned | FR-31a part 4 | a set difference over three key sets, computed after the pass returns; a non-empty difference exits `1` naming each item | AC-S4; `test-agent-pass-bounds.sh` |
| R12 | Every value inside FR-32's boundary is byte-stable | FR-32, AC-5 | no timestamp, absolute path, line number, size or Pass-2-derived count appears in the class-0 block or in this feature's coverage rows | AC-5; `test-relationships-reproducible.sh` |
| R13 | A concept mention sitting in the structural position of a false merge is reported, never asserted | Q18 ruling 2, FR-24 | a four-condition predicate over the frozen class-0 set — plain-form concept, mention outside the defining document, no class-0 row linking the two documents, no second shared concept — evaluated as set operations with no threshold, and skipped where the defining document names no second concept; the output is an advisory candidate list that gates nothing, published with four reach counters so its narrowness is a measured quantity rather than a caveat (D2f) | AC-S7, AC-S7a; `test-concept-merge-candidates.sh` |

### The shared scanner seam (binding on `/aid-detail`)

**Feature-004 owns the walk; this feature owns the rows.** There is exactly one traversal of the
project source, `canonical/aid/scripts/graph/scan-source.sh`, and it belongs to feature-004. This
feature consumes four streams and never re-walks:

| Stream | Owner | Used here for |
|--------|-------|---------------|
| `.aid/.temp/graph/nodes.tsv` | feature-004 D1 | the closed `source-artifact` set; `node_kind` (field 7) is **read**, never derived |
| `.aid/.temp/graph/media-nodes.tsv` | feature-004 D1a | the `image` and `web-page` sets; `node_kind` (field 3) is **read**, never derived |
| `.aid/.temp/graph/observations.tsv` | feature-004 D5 | untyped observations that Pass 1b types |
| `.aid/.temp/graph/candidates.tsv` | feature-004 D6 | the typing half of Pass 2's work |

`tests/canonical/test-graph-single-scanner.sh` (specified in feature-004) asserts that no file under
`canonical/aid/scripts/graph/` other than `scan-source.sh` contains a **repository** traversal. This
feature's scripts therefore cannot grow a second walk without failing that suite.

The KB side is different and is **owned here**: Pass 1a's read of `.aid/knowledge/` is a
single-directory, depth-1 read that produces the four KB-side node kinds nothing else produces.
feature-004's seam section names this exemption explicitly, so the two contracts agree rather than
merely coexist.

### Data Model

#### D1. Row record (internal, pre-render) — **eleven fields, ten columns**

Both passes write a common TSV record; `build-relationships.sh` renders it into feature-003 D1's
ten-column markdown table. Tab-separated, LF-only, no header.

| # | Field | Value space |
|---|-------|-------------|
| 1 | `class` | `0` for `declared`/`derived`, `1` for `inferred` — feature-003 D3 |
| 2 | `source_id` | node id in canonical orientation — feature-003 D2, D7 |
| 3 | `source_kind` | §5.2 `Kind`, **carried from the node record**, never parsed out of the id |
| 4 | `source_name` | `rel_display_name` — feature-003 D5 |
| 5 | `target_id` | node id |
| 6 | `target_kind` | §5.2 `Kind`, carried |
| 7 | `target_name` | `rel_display_name` |
| 8 | `s2t` | the mapped relation's `relation` label |
| 9 | `t2s` | that entry's `inverse`, **looked up and never chosen** |
| 10 | `provenance` | `declared` \| `derived` \| `inferred` — D5 |
| 11 | `observation` | empty, or a durable anchor (class 0), or agent prose (class 1) — feature-003 D6 |

**Fields 3 and 6 are new this revision, and the row-normalisation consequence is not cosmetic.**
Every row passes through feature-003 `rel_normalise_row`, whose D7 rule swaps the two **`(Id, Kind,
Name)` triples** together. feature-003 states plainly that "any implementation carried over from the
eight-column design has this bug" — a rule that moved ids and names while leaving the two `Kind`
cells in place would emit a row whose kinds no longer match their ids and would fail **V13** on a
row that was correct before normalisation. This feature calls the library function rather than
implementing the swap, which is what makes the hazard unrepresentable here.

**The sort key is feature-003 D7's, exactly:** `LC_ALL=C` ascending over
`(class, source_id, target_id, s2t, t2s)`. The previous revision appended `provenance` to that
tuple, which is a **divergence from the owner's contract** and is removed: feature-003's totality
argument rests on the last four components being exactly `rel_row_key`, which **V5** forbids two rows
from sharing, and a sixth component would neither strengthen the order nor match what **V10** checks.

**Ordering, keying and normalisation are all reached through feature-003 D9** — `rel_normalise_row`,
`rel_row_key`, `rel_sort_key`, `rel_class0_block`. None is reimplemented here, so writer and
validator cannot disagree about where a row sorts or whether two rows are the same relationship.

#### D2. Pass 1a — the KB scan and the four node kinds it emits (FR-30)

Pass 1a emits `.aid/.temp/graph/kb-nodes.tsv` — `node_id | node_kind | name | doc`, one row per
`document`, `section`, `fact` and `concept` node, `LC_ALL=C`-sorted by `node_id`, LF-only, no header,
with `node_kind` carried as data for the same reason feature-004 D1 carries it (so no consumer
re-derives a kind from a prefix) and `doc` empty for a `concept`, which is not document-scoped
(feature-003 D2). It is the KB half of the closed node set Pass 2's merge tests against (D6).

One forward pass per document computes everything below. The pass maintains exactly one fenced-code
state, shared by every rule — feature-003's Feature Flow step 5 establishes this discipline for its
validator ("All three share the single fenced-code state that pass maintains, which is what keeps
the heading counter, the block boundaries and the marker scan from disagreeing about where a fence
begins"), and the writer must match it or the two would compute different node sets from the same
bytes.

##### D2a. `document` nodes, and the two documents excluded as sources

The `document` node set is the KB scan set, consumed as feature-003 D2a's membership predicate.
`node_kind` is `document`; the id is `kb:<doc>`; the name is `rel_display_name`.

**Two documents are excluded as sources of sub-document nodes and of edges, and both remain valid
targets.** The previous revision excluded them as edge sources only; the exclusion is widened here
because FR-30 made Pass 1 a node producer, and a node harvested from a generated file inherits that
file's instability.

| Document | Why it is not a source | Why it is still a target |
|---|---|---|
| `relationships.md` | it is this feature's own output. Harvesting nodes or edges from it would make a run depend on the previous run's output — the file would bootstrap itself and **FR-32 would be unprovable**. Total either way, since the name test does not require the file to exist | a hand-authored document citing it produces a real edge |
| `INDEX.md` | a generated re-presentation of every other document's frontmatter (verified: its own frontmatter carries `source: generated`, `generator: build-kb-index.sh`, and the contract "One entry per non-dot, non-recursive KB document under .aid/knowledge/"). Harvesting its links would manufacture one edge per KB document and duplicate every `see_also:` edge already harvested from the authoring document; harvesting its headings would mint `section` nodes for a generated table of contents. It also embeds a timestamp in its `changelog:`, so anything harvested from it would churn | a hand-authored document citing it produces a real edge |

Both remain `document` **nodes** — membership is feature-003's predicate and diverging from it would
break the AC-18 property that a document the index lists is exactly a document a `kb:` id may name.

##### D2b. `section` nodes and their containment edges

Emitted for ATX heading levels **2–6** by feature-003 `rel_doc_slugs`, which applies D2a-1's
slugification, the levels-1–6 duplicate counter and the fenced-code exclusion. Level 1 is excluded
because the H1 *is* the document. A heading whose slug comes out empty yields no node and is counted
in the coverage notes (D7) — feature-003 D2a-1's degrade-gracefully rule, consumed.

**Containment is computed with a level stack, and that is a different computation from the block
body.** feature-003 D2a-3a fixes a heading's *block body* as the lines up to the next heading of
**any** level — deliberately not a nesting rule, because nesting is not a partition and one marker
would then mint a concept per ancestor. Containment needs the opposite: a `section`'s parent is the
**nearest preceding emitted heading of a shallower level**, or the `document` when there is none.
The two are maintained side by side in the same pass and are never unified:

| Edge | Source → target | Relation | Provenance |
|---|---|---|---|
| a level-2 heading, or any heading with no shallower emitted ancestor | `document->section` | `has-part` / `part-of` | `derived` |
| a heading nested under a shallower emitted heading | `section->section` | `has-part` / `part-of` | `derived` |

`has-part`'s `endpoint_kinds` declares both tokens and its `passes` admits `derived` (feature-001
D6), so both are legal by the map's load-time gate. Provenance is `derived` because nothing in the
document *states* that a section is part of it — the scan computes it from heading levels (D5).

**Conflating the two computations is precisely the defect feature-003 D2a-3a warns about, in
reverse**, so it is named: an implementer who reused the block-body scan for parentage would attach
a level-4 heading to the nearest preceding heading of *any* level, which is correct for a body and
wrong for containment whenever a level-4 follows a level-5.

##### D2c. `fact` nodes, their containment edge, and their citation edge

A `fact` node is emitted for every **well-formed checkable source anchor**, by feature-003
`rel_fact_tokens`. feature-003 D2a-2 owns what "well-formed" means — a citation carrying both a path
and a grep-recoverable anchor string, in one of the two forms `authoring-conventions.md`'s Citation
Rule admits — and owns the `<path-slug>--<anchor-slug>[-<N-1>]` token grammar, its four-step
truncation and its wrapped-anchor block matching. None of that is restated here; the writer calls
the function and **V2** recomputes it.

A marker carrying **no** anchor string yields **no** fact node. feature-003 D2a-2 records why (a node
that resolves to nothing is exactly what AC-1 exists to prevent) and requires the skipped count in
the coverage notes; D7 supplies that row.

| Edge | Source → target | Relation | Provenance |
|---|---|---|---|
| the anchor's enclosing section, or the document when the anchor sits above the first emitted heading | `section->fact` / `document->fact` | `has-part` / `part-of` | `derived` |
| the fact to the artifact its anchor cites, when the cited path resolves to an enumerated `int:` node | `fact->source-artifact` | `cites-as-evidence` / `cited-as-evidence-by` | `declared` |
| the fact to the artifact its anchor cites, when the cited path is a member of the KB scan set | `fact->document` | `cites-as-evidence` / `cited-as-evidence-by` | `declared` |

**The second and third rows are one rule with a two-branch target, and the branch is decided by
where the cited path lives**, not by a guess: feature-004 D4 Class 4 cuts `.aid/**` from `int:`
enumeration, so a cited path under `.aid/knowledge/` cannot be a `source-artifact` and can only be a
`document`. `cites-as-evidence` declares both tokens (feature-001 D6), so the branch needs no second
relation. A cited path that resolves to neither becomes a candidate, never a row.

This is FR-30's "each also yielding a `declared` edge to the `int:` path the anchor cites",
discharged — with the KB-internal branch added because the vocabulary declares it and the requirement
does not forbid it.

##### D2d. `concept` nodes, the merge rule, and what a false merge does

**Identity and the merge.** A concept node is emitted for every definition block feature-003
D2a-3/D2a-3a identifies — a heading at level 3 or deeper whose block body carries a
`**Definition:**` or `**Definition-as-used-here:**` marker line. Identity is `rel_normalise_term`
over the heading text; the id is `kb:concept:<normalised-term>`. Because identity is the term and
not the document, **a term defined once and named in five documents is one node** (Q13), and every
naming is an edge. Mention count therefore appears as graph degree — which is the property
feature-002's bench needs and D-2a serialises this feature ahead of it for.

**Resolution and disambiguation are feature-003's, consumed exactly.** `rel_concept_defs` requires
**exactly one** definition of a term for the plain id to resolve; where two or more exist, the plain
form is never emitted and each definition takes the document-qualified `kb:concept:<term>@<doc>`
form, one node per definition. **V15** reports the underlying glossary defect at `[LOW]`. The writer
calls the function, so the qualified form is forced mechanically rather than by instruction.

**The definition edge is `document->concept`, and the section-level alternative was considered.**

| Edge | Source → target | Relation | Provenance |
|---|---|---|---|
| each defining document to the concept it defines | `document->concept` | `defines` / `defined-by` | `declared` |

FR-30 says "plus a `declared` edge from each **defining document**", and that is the edge emitted.
`section->concept` — the owning heading, which always exists because a marker's owner is a level-3+
heading and levels 2–6 are all emitted — was the alternative and is **not** adopted, for three
reasons: FR-30 names the document; one definition edge per (document, concept) pair keeps degree
meaningful under Q13, where a second redundant edge per definition would inflate exactly the number
the merge rule exists to make significant; and nothing downstream needs section granularity here —
FR-14a's open gesture resolves a concept to its **defining document**, and the Overview lens groups
concepts by category. The defining heading is not lost: it is carried in the row's `Observation`
durable anchor. The consequence is that `defines`'s `section->concept` token has no producer, which
D8 reports rather than hides.

**Mentions.** For each concept node, each **other** location naming it becomes an edge:

| Edge | Source → target | Relation | Provenance |
|---|---|---|---|
| the enclosing node of each occurrence | `document->concept`, `section->concept`, `fact->concept` | `mentions` / `mentioned-in` | `derived` |

**Mention detection is decidable, and the matchable surface is deliberately narrow.** The single
surface form is the **defining heading's text verbatim**, matched case-insensitively and
token-bounded (the match must be preceded and followed by a non-alphanumeric character, a line start
or a line end), with fenced-code lines and the concept's own defining block excluded. Three
properties follow, and each is why the rule is this and not something cleverer:

- **Detection runs from the node set outward, not from arbitrary text inward.** For each existing
  concept, find its occurrences — so a term nobody defined can never produce a mention edge with no
  node at its end. The scan is bounded by the concept set, and there is no "unmatched term" residue
  to account for.
- **A missed mention is an under-count and never a wrong edge.** A document writing "AID install
  core" where the glossary heading reads `AidInstallCore` produces no `derived` edge. That is the
  correct conservative outcome, and it is not a permanent loss: `mentions`'s `passes` includes
  `inferred`, so recording such a mention is exactly the reading-dependent work FR-31a part 3 puts
  in scope for Pass 2.
- **The glossary alias line is not used, and the reason is FR-8a rather than convenience.**
  feature-003 D2a-3 records that this repository's glossary carries an `Aliases:` marker line **that
  the shipped template does not define**, and leaves its use to this feature. It is declined: FR-8a permits
  relying on the KB's *authoring conventions* and forbids relying on this repository's content, and
  an un-templated marker is the second of those. Letting it drive edges would also mean a project
  that happens to use the field gets a differently-shaped graph from one that does not, with no
  convention to appeal to. Routed as Open Item 6 — if aliases should drive mentions, the marker must
  first become a shipped glossary-template convention.

**What a false merge does — the case that is impossible, and the case that is not.** Q13's merge
rule creates exactly one new failure mode: two genuinely distinct concepts whose labels normalise to
one term.

| Case | What happens | Detectable? |
|---|---|---|
| both are **defined** | `rel_concept_defs` returns ≥ 2, so the plain id never resolves and each definition takes the `@<doc>` form — **one node per definition**. Nothing is merged and nothing is dropped. **V15** additionally reports the term at `[LOW]` | **yes**, and the split is structural rather than advisory: feature-003 D2a-3 makes the exactly-one rule what forces the qualified form |
| one is defined, the other only **mentioned** | the mention edges of the undefined sense attach to the defined sense's node. The node is right; some of its edges are wrong | **not provable** — no validator can decide which sense a paragraph meant. But it is **not undetected**: D2f computes a decidable candidate signal and reports it advisorily |

For the second case the mitigation is **detection plus disclosure**, not prevention. Disclosure was
already bounded three ways: the edge is `derived`, so a reader discounts it relative to a `declared`
one; its `Observation` is a durable anchor naming the mentioning document and the matched literal, so
any single edge is checkable in one grep; and the underlying condition is a **glossary defect** —
two distinct ideas sharing one label with only one defined — which §2 purpose 1 makes the graph's job
to surface rather than paper over. That was the whole of the previous revision's answer, and the work
owner **overruled it** (STATE.md Q18 ruling 2): a bounded, recorded blind spot still ships silent
wrong edges, and detection is required. D2f is that detector. It respects FR-24 by reporting
*candidates* and asserting no defect — the same posture feature-003's **V12** and **V15** take.

The inverse risk — a false **split**, one concept written two ways — is also left unfixed and
reported: feature-003 D2a-3 does not fold plurals, and **V15** reports terms differing only by a
trailing `s`/`es` or an `ies`↔`y` alternation. Both directions are therefore measure-and-warn, which
is the posture Q14 item 7 and NFR-8 already establish for scale.

##### D2e. The enclosing-node chain — one rule for every inline carrier

An inline carrier (a link, a path citation, an image reference, an external-source key) lies at some
line of some document. Its **source node** is chosen by one rule, computed in R4's pass:

> The enclosing chain of a line is `fact ⊃ section ⊃ document`: the `fact` node whose anchor block
> contains the line, if any; otherwise the nearest preceding emitted heading's `section` node, if
> any; otherwise the `document` node. The carrier's source is the **finest member of that chain the
> mapped relation admits**.

**The chain is uniform; the ceiling is data.** The map entry (D3) names the kind pairs the harvest
kind may emit, and the load-time gate proves each is a member of the mapped relation's
`endpoint_kinds`. So the ceiling is not a carve-out written into the scanner — it is what the
vocabulary declares, checked once before any row exists. Two worked consequences:

- **`kb-image-reference` reaches the `fact` level**, because `illustrated-by` declares
  `document->image`, `section->image` **and** `fact->image` (feature-001 D6c). All three are
  therefore produced, which is the confirmation feature-001 Open Item 5 asked for.
- **`kb-inline-doc-link` stops at the `section` level**, because `mentions` — the only relation whose
  definition matches a link in content and whose `passes` admits this carrier's provenance — declares
  `document->document` and `section->document` but no `fact->document`. Promoting the source to
  `fact` would produce a row the endpoint gate rejects. The consequence, that `cites`'s `fact->document`
  token has no producer, is reported in D8 and routed to feature-001 rather than worked around.

##### D2f. The false-merge candidate report — closing Q13's one open failure mode

**Why this exists and what it may not do.** STATE.md Q18 ruling 2 requires the D2d case-2 false merge
to be **closed by detection**, overruling the previous revision's recorded blind spot, and constrains
the mechanism in the same breath: FR-24 forbids manufacturing a defect from opinion, so the mechanism
must be **decidable** and must surface **candidates advisorily** rather than assert a merge it cannot
prove. Those two together define the shape exactly — a computed predicate with no threshold, whose
output is a list a human adjudicates, which gates nothing and appears in no gap ledger.

**The signal.** Computed over the **frozen class-0 row set** (Feature Flow step 11), which is where
the concept's neighbourhood first exists. A pair *(concept C, mentioning document M)* is a
**merge candidate** iff all four hold:

| # | Condition | Why it is part of the predicate |
|---|---|---|
| 1 | C is in the **plain** id form — `rel_concept_defs` found exactly one definition, in document D | the ≥ 2 case is split structurally into `@<doc>` nodes (D2d case 1), so no merge occurred and none can be false |
| 2 | M ≠ D, and a `mentions` row exists from a node of M to C | restricts the report to edges the merge rule actually created |
| 3 | **No class-0 row links M and D in either direction**, at document granularity — a section- or fact-sourced row counts for its owning document | three carriers make one KB document point at another: `see_also:` (kind 8), an inline doc link (kind 12) and a fact anchor citing a KB document (kind 5). A document discussing D's subject usually reaches D through one of them |
| 4 | **M and D share no concept but C** — the sets of concepts each defines or mentions intersect in C alone | a second document genuinely using D's term almost always shares more of D's vocabulary than the single colliding label |

Conditions 3 and 4 are two independent disconnection tests over rows this feature has already
emitted. Both are set operations on finite sets; neither carries a threshold, a score, or a tunable
constant; and both are functions of the frozen class-0 block, so the candidate set is deterministic
and identical across runs on unchanged inputs — it sits inside FR-32's guarantee rather than beside
it.

**One degenerate input is excluded explicitly, because it would make condition 4 vacuous.** If D's
own concept set is exactly `{C}` — D defines C and names no other concept — then *every* mentioning
document trivially shares nothing else with it, and condition 4 would fire on all of them while
discriminating nothing. Where that holds, the pair is **not** reported and the coverage note records
the count it does report as usual. Failing conservative is the right direction here: an
over-reporting advisory is ignored, and an ignored advisory closes nothing.

**What it is not.** The predicate is a **correlation, not a proof**, and the SPEC says so where a
reader will meet it. It over-reports: a legitimate mention in a genuinely isolated document satisfies
all four conditions. It under-reports: a colliding second sense inside a well-connected document
satisfies neither 3 nor 4 and is missed. Neither is a defect in the mechanism, because the mechanism
claims only what it computes — *these pairs sit in the structural position a false merge occupies* —
and the adjudication is the reader's, performed with the `Observation` anchor D2d already guarantees.
Q18 ruling 2 anticipates exactly this: the risk of a heuristic is to be **managed**, and managing it
means never letting the output cross into an assertion.

**The under-reporting is stated as four counts, not as an adjective — and condition 4 is the one that
narrows it.** A cohesive KB shares vocabulary across its documents, so condition 4 is expected to
filter most pairs that reach it, and on some projects it will filter all of them. That is a real
property of the detector and it is reported rather than described. Every run emits four numbers, all
functions of the frozen class-0 set and therefore byte-stable:

| Counter | What it counts | What a reader learns |
|---|---|---|
| `pairs_1_3` | (concept, document) pairs satisfying conditions **1–3** | how many mentions are structurally isolated at all — the population condition 4 filters |
| `filtered_by_shared_vocabulary` | of those, how many **fail** condition 4 | **the detector's reach loss, quantified.** Large ⇒ the narrowness is a number a reader can weigh, not a caveat; zero ⇒ condition 4 cost nothing on this KB |
| `skipped_single_concept` | plain-form concepts excluded by the degenerate rule | how much of the KB condition 4 could not discriminate over at all |
| `candidates` | `pairs_1_3` − `filtered_by_shared_vocabulary` | the reported set |

A zero in `candidates` is now interpretable rather than ambiguous: paired with `pairs_1_3` it
distinguishes *"no mention is even isolated"* from *"isolated mentions exist and shared vocabulary
explained every one of them."* No figure for any counter is predicted here — each is a runtime output
of the project it runs on, and predicting one would be inventing a measurement.

**Condition 4 is deliberately not relaxed, and the vacuity is handled by the precedent this work
already set.** Loosening it — allowing one shared concept, or two — would trade a silent under-report
for a stream of pairs whose isolation the KB itself explains, which is the advisory-nobody-reads
failure and the one FR-24 treats most strictly: a report a reader learns to skip is worse than a
narrow one they trust. The vacuity risk is instead met the way REQUIREMENTS **A-6** and **AC-1** meet
it for the `ext:` branch, where "this project's own `external-sources.md` has zero entries and would
satisfy the criterion vacuously", so Q4 validated the branch against a **synthetic fixture** with
"both resolvable and deliberately unresolvable keys, so the check is proven to fire". **AC-S7 is
discharged the same way**: the fixture set in `tests/canonical/fixtures/graph/` supplies the firing
case and the three near-misses, so the criterion is proven to fire independently of whether this
repository's KB happens to contain an ambiguous label — and the four counters make the real-KB
outcome visible on every run instead of hiding it behind a zero.

**Where it is reported, and how a reader acts on it.**

| Surface | Content | Why there |
|---|---|---|
| `.aid/.temp/graph/concept-merge-candidates.tsv` | `concept_id \| defining_doc \| mention_doc \| mention_anchor`, `LC_ALL=C`-sorted | the per-candidate detail, machine-readable for feature-006/007; scratch, like `dispositions.tsv` |
| **stdout**, at `[LOW]`, naming each pair | the same list, one line per pair, followed by the four reach counters | visible on every run in feature-003 **V15**'s advisory register — the near-plural warning is the adjacent case and this joins it |
| a fourth extra coverage row, `concept-merge-candidates` (D7) | `candidates`, plus `filtered_by_shared_vocabulary` and `skipped_single_concept` in the same `note` | makes both the finding and its reach durable in the artifact and byte-stable, because all three are Pass-1 functions. They share one row on purpose: the extra-row inventory is already the subject of Open Item 16, and a detector that widened it while that item is open would be arguing against its own routing |
| a gap-ledger row | **never** | FR-26 keys ledger rows on an `int:` node and FR-24 forbids a defect claim from an undecidable inference. The same boundary D6 draws for `cannot-type` |

A reader acts on a candidate in one step: open the mention anchor, read the sentence, and decide
whether the label means what the glossary defines. If it does not, the fix is a **glossary** fix —
define the second sense, at which point D2d case 1 fires and the two split into `@<doc>` nodes
mechanically, with no change to this feature. That is the property that makes the report worth
running: its true positives are self-resolving through a rule that already exists.

**Layer, owner, and what remains elsewhere.** The signal is computed **here**, by
`build-relationships.sh`, because the neighbourhood it needs is this feature's own frozen class-0 set
and computing it later would mean re-deriving what this run already holds. It is a **binding
obligation with an acceptance criterion (AC-S7)**, not an Open Item — Q18 ruling 2 makes it a
requirement, and a requirement with a test cannot be dropped the way an item can — validated on the
A-6 / AC-1 fixture precedent so it cannot pass vacuously. What remains
elsewhere is presentation only: feature-007's Coverage/Impact lens may render the same set as a
signal beside the graph. Open Item 7 is rewritten to that narrower shape. The inverse risk — a false
**split** — needs no detector: D2d already leaves it to **V15**'s near-plural advisory.

#### D3. The vocabulary and the edge-relation map

**The vocabulary.** Loaded through feature-003 `rel_load_vocabulary` from the core file feature-001
authors, merged with the optional project extension. The entry carries **eight** keys in fixed order
— `relation`, `inverse`, `symmetry`, `category`, `derived_from`, `endpoint_kinds`, `passes`,
`definition` (feature-001 D2; `derived_from` was added at position 5 on 2026-07-29 and is
feature-001's Open Item 1 against feature-003's loader). This feature reads the parsed values
through the shared loader and never re-parses the file, and **no relation label appears anywhere in
this feature's code** (R8).

Which of the eight this feature reads, stated so the claim is checkable:

| Key | Read here? | Used for |
|-----|-----------|----------|
| `relation` | yes | the `s2t` label a harvest kind maps to; membership check before emitting |
| `inverse` | yes | `t2s`, looked up rather than chosen |
| `passes` | **yes** | the map-load pass-legality gate, and a Pass-2 rejection |
| `endpoint_kinds` | **yes** | the map-load endpoint-legality gate, and a Pass-2 rejection — now over **kind** pairs |
| `derived_from` | no | the audit trail FR-5 requires; feature-001 D2 states plainly that no runtime consumer interprets it |
| `symmetry` | no | a symmetric pair falls out of `inverse == relation`; feature-003 **V4** owns row-level symmetric acceptance |
| `category` | no | carried by feature-003's loader to feature-007/008/009 for FR-6 grouping and FR-6a filtering; this writer never reads it |
| `definition` | no | human-facing; nothing mechanical depends on it |

**The edge-relation map — why a second file exists.** Pass 1 must *choose* a relation per harvested
edge, and the choosing key is a **harvest kind**, which is this feature's own concept: the vocabulary
cannot name harvest kinds without knowing about this feature's scanners, and should not. The binding
lives in `canonical/aid/templates/graph/edge-relation-map.yml`, owned here:

```yaml
# <harvest-kind>|<emitting-provenances>|<kind-pairs>|<relation-label>
map:
  - kb-doc-section|derived|document->section|has-part
  - kb-section-section|derived|section->section|has-part
  - kb-doc-fact|derived|document->fact|has-part
  - kb-section-fact|derived|section->fact|has-part
  - kb-fact-anchor|declared|fact->source-artifact,fact->document|cites-as-evidence
  - kb-concept-definition|declared|document->concept|defines
  - kb-concept-mention|derived|document->concept,section->concept,fact->concept|mentions
  - frontmatter-see-also|declared|document->document|cross-references
  - frontmatter-sources-path|declared|document->source-artifact|documents
  - frontmatter-sources-url|declared|document->web-page|documents
  - kb-inline-path-citation|declared|document->source-artifact,section->source-artifact,fact->source-artifact|cites
  - kb-inline-doc-link|declared|document->document,section->document|mentions
  - kb-image-reference|declared,derived|document->image,section->image,fact->image|illustrated-by
  - kb-ext-key-citation|declared|document->web-page,section->web-page,fact->web-page|cites
  - invocation|derived|source-artifact->source-artifact|invokes
  - dependency|derived|source-artifact->source-artifact,source-artifact->image,source-artifact->web-page|depends-on
  - include|derived|source-artifact->source-artifact|depends-on
  - convention|derived|source-artifact->source-artifact|depends-on
  - image-reference|declared,derived|source-artifact->image|illustrated-by
```

**Field 3 is re-keyed from prefixes to kinds, and one of the previous revision's arguments dies with
it.** The old field held tokens like `int:->int:`, and the SPEC argued at length that they must be
comma-separated with no space because "a plain YAML scalar containing `: ` is read as a mapping".
That hazard was a property of the **prefix** notation: a `Kind` token contains no `:` at all, so
`document->section section->section` would parse cleanly. Comma separation is nonetheless retained,
because one separator for a multi-valued field is one fewer thing to get wrong and because the
`|`-separated entry already uses a positional grammar. **The argument is restated as void rather than
deleted**, because a reader who remembered it would otherwise think field 3 still carries prefixes —
which is exactly the proxy-defect class Q17 names.

Loader contract (`load_edge_relation_map`, fail-closed, run before any row exists):

- Each entry is exactly four `|`-separated fields — the same intra-entry separator `.aid/settings.yml`
  already uses for `knowledge.doc_set`. Wrong arity → exit 2 naming the resolved absolute path and
  the entry.
- **Completeness is checked against a declared kind list, so a deliberate omission and an accidental
  one cannot look the same.** The loader carries the closed list of harvest kinds this feature
  recognises — D4's twenty — and requires each to be either mapped, with a non-empty relation label
  that is a member of the merged vocabulary, or listed in the script's `UNMAPPED_KINDS` set. Exactly
  one kind is in that set, `path-reference`, for the reason below. Any other kind missing from the
  map exits 2 naming the path and the kind.
- **Pass legality (AC-S5).** Every provenance in field 2 must appear in that relation's `passes`. A
  map routing a `derived` harvest to a relation the vocabulary marks `declared`-only is a
  configuration defect and exits 2.
- **Endpoint legality (AC-S5).** Every kind pair in field 3 must appear in that relation's
  `endpoint_kinds`, compared **after parsing** and never textually — field 3's encoding and
  feature-001's double-quoted flow sequence are different notations for the same token set.
- `t2s` is never chosen: it is looked up as the mapped relation's `inverse`. A pair is therefore
  internally consistent by construction, which is why feature-003's **V4** should never fire on this
  writer's output; and because the endpoint gate already passed, its advisory **V12** should not
  either.
- An observation whose kind carries no mapping becomes a **Pass-2 edge candidate**, never an untyped
  row. There is no code path that emits a row with a blank or invented relation.

**`path-reference` is deliberately unmapped, and that is a finding rather than an omission.**
feature-004's `path-reference` trigger is "the bytes of one node contain another node's path or
uniquely-resolving basename" — which spans a script reading a data file and a document naming one in
prose. The relation whose definition matches ("names the target in its content without asserting
that the target is its subject or its evidence") is `mentions`, and `mentions` declares **no
`source-artifact->` token at all** (feature-001 D6). Inventing a mapping would mean typing every
coarse path reference as `depends-on`, asserting a data dependency the observation does not evidence
— and the endpoint gate would reject it anyway. So `path-reference` observations become Pass-2 edge
candidates, which is the first of FR-31a part 3's two kinds of work and exactly what it exists for.
The volume consequence is stated rather than hidden: the derived majority is carried by the four
observation kinds that *are* typed (`invocation`, `dependency`, `include`, `convention`) plus
`image-reference`, and `path-reference` is the residual. Routed as Open Item 2.

**Two conflations in feature-004's observation kinds are recorded, not worked around.** Its
`dependency` kind lumps six manifest semantics together (`package.json` `bin`/`files`/`dependencies`,
`pyproject.toml` entry points, `profiles/<tool>.toml`, `generated-files.txt` output ↔ build command,
`shortcut-catalog.yml` row ↔ emitted doorway, `.aid/settings.yml` `knowledge.doc_set` ↔ the named KB
doc). One observation kind can carry only one relation, so all six type as `depends-on`. Two costs
follow: `generated-by` — whose definition ("produced from the target by a named deterministic
process") is exactly what `generated-files.txt` records — gets **no producer**, and the `doc_set`
edge crosses to a `document` target that `depends-on` does not declare, so it too becomes a Pass-2
candidate. Subdividing the observation kind is feature-004's call; routed as Open Item 3.

**Consequence to state plainly: feature-001 blocks a runnable pipeline, not this specification.**
`harvest-declared.sh` and `derive-edges.sh` can be built and tested against a fixture vocabulary;
only the real `relationships.md` needs the real one. That is what D-1 means concretely.

#### D4. Carriers — what Pass 1 harvests, and from where

Every carrier below is an **AID KB authoring convention** or a feature-004 observation, never an
instance in this repository (FR-8a). Where a file under `.aid/knowledge/` is cited, it is to show a
rule fires on real content, never to derive the rule.

**Pass 1a — the Knowledge Base side.** Kinds 1–7 are the node-yielding harvests FR-30 widened Pass 1
to include; kinds 8–14 are the reference carriers.

| # | Harvest kind | Carrier | Row |
|---|---|---|---|
| 1 | `kb-doc-section` | an emitted heading with no shallower emitted ancestor (D2b) | `kb:<doc>` → `kb:<doc>#<slug>` |
| 2 | `kb-section-section` | an emitted heading nested under a shallower one (D2b) | `kb:<doc>#<parent>` → `kb:<doc>#<child>` |
| 3 | `kb-doc-fact` | a well-formed anchor above the first emitted heading (D2c) | `kb:<doc>` → `kb:<doc>#fact:<token>` |
| 4 | `kb-section-fact` | a well-formed anchor inside an emitted section (D2c) | `kb:<doc>#<slug>` → `kb:<doc>#fact:<token>` |
| 5 | `kb-fact-anchor` | the path the anchor cites (D2c) | `kb:<doc>#fact:<token>` → `int:<path>` or `kb:<doc>` |
| 6 | `kb-concept-definition` | a definition marker under a level-3+ heading (D2d) | `kb:<doc>` → `kb:concept:<term>` |
| 7 | `kb-concept-mention` | a token-bounded occurrence of a defining heading's text (D2d) | enclosing node → `kb:concept:<term>` |
| 8 | `frontmatter-see-also` | the `see_also:` list — a shipped-template frontmatter field, present in this repository's primary documents. An entry is split at `#` and only the document part is resolved; the fragment, which `frontmatter-schema.md` permits without endorsing (its rule is **SHOULD** be a sibling doc name), is carried in the row's `Observation` and drives no section-level edge (D8, Open Item 15) | `kb:<doc>` → `kb:<entry>` |
| 9 | `frontmatter-sources-path` | a `sources:` entry that is a repo-relative path or glob | `kb:<doc>` → `int:<resolved node>` |
| 10 | `frontmatter-sources-url` | a `sources:` entry matching the URL shape `^[a-z][a-z0-9+.-]*://` — the detector `kb-freshness-check.sh` `is_url` already uses — **only if** it resolves to a registered key | `kb:<doc>` → `ext:<key>` |
| 11 | `kb-inline-path-citation` | a path-or-basename citation in prose that is **not** part of a well-formed anchor, matched with the character class and extension set `kb-citation-lint.sh` already uses: `[A-Za-z0-9_./-]+\.(md\|sh\|py\|mjs\|js\|ts\|yml\|yaml\|json\|toml\|txt\|ps1)` | enclosing node → `int:<resolved node>` |
| 12 | `kb-inline-doc-link` | a markdown link whose target is a member of the KB scan set | enclosing node (section ceiling) → `kb:<target doc>` |
| 13 | `kb-image-reference` | a markdown image `![alt](<ref>)` or an HTML `src`/`href` whose resolved target is an `image` node | enclosing node → `int:<image>` |
| 14 | `kb-ext-key-citation` | a prose citation of a key the external-sources registry registers | enclosing node → `ext:<key>` |

**Pass 1b — feature-004's observations, typed here.** The scanner emits them without typing them;
`derive-edges.sh` does all typing and adds no traversal of its own.

| # | Observation kind (feature-004 D5) | Relation | Kind pairs |
|---|---|---|---|
| 15 | `invocation` | `invokes` / `invoked-by` | `source-artifact->source-artifact` |
| 16 | `dependency` | `depends-on` / `dependency-of` | `source-artifact->source-artifact`, `source-artifact->image`, `source-artifact->web-page` |
| 17 | `include` | `depends-on` / `dependency-of` | `source-artifact->source-artifact` |
| 18 | `convention` | `depends-on` / `dependency-of` | `source-artifact->source-artifact` |
| 19 | `image-reference` | `illustrated-by` / `illustrates` | `source-artifact->image` |
| 20 | `path-reference` | *(unmapped — Pass-2 edge candidate, D3)* | — |

**The `image-reference` mapping, discharged.** feature-001 D6c settled the relation, the direction
(feature-004's `from_id` is the citing artifact, so `illustrated-by` is the correct `S2T` label), the
legal endpoints and the `passes` set; feature-001 Open Item 5 left this feature the map row and the
Pass-1 producer for the three KB-side tokens. Both are supplied: harvest kind 19 above carries
`source-artifact->image`, and harvest kind 13 carries `document->image`, `section->image` and
`fact->image` through D2e's chain. `concept->image` is **not** produced and correctly so —
feature-001 D6c excludes it because a concept has no text extent of its own, and D2d's mention rule
confirms it operationally: a concept is reached *by* an edge from a text extent, never as the origin
of one.

**Two verified facts about this repository, stated because they change what acceptance means here
and not because they define any rule:**

1. **No KB document carries a markdown image reference or an `<img>` element** (verified across
   `.aid/knowledge/*.md`, 2026-07-29). Harvest kind 13 therefore contributes **zero** rows on this
   project, while its producer exists and is exercised by a fixture. This is a fact about this
   repository, not about the carrier — the same posture feature-001 D9 takes toward the `ext:` row.
2. **No `ext:` edge is producible on this project.** feature-003 D2c and feature-004 D1a both record
   that `.aid/knowledge/external-sources.md` registers zero keys, so harvest kinds 10 and 14
   contribute nothing here and AC-1's `ext:` branch lives on the Q4 synthetic fixture (A-6).

**Explicitly not a carrier:** the frontmatter `contracts:` list. FR-30's carrier bullet names
"frontmatter cross-references (`see_also`, `contracts`)", but `contracts:` entries are structural
cardinality *assertions* (`frontmatter-schema.md`, "`contracts:` (optional, list)"), not references
to a node, so they carry no endpoint and cannot form a row. Also not carriers: `tags:`, `audience:`,
`owner:`, `changelog:`, `objective:` and `summary:`. Recorded as a wording observation against FR-30,
not as a change (Open Item 1).

**The `Evidence:` carrier is struck.** The previous revision carried an `evidence-citation` harvest
kind and an Open Item asking for FR-30 to be amended. Both are void: REQUIREMENTS.md's change log
records the correction on 2026-07-28 ("FR-30's `Evidence:` carrier does not exist in this KB … Replaced
with the verified carriers"), and FR-30 as amended names the four carriers kinds 8–11 and 14
implement. Carrying a harvest kind for a pattern no requirement asks for would be dead configuration
that the map's own completeness gate would then demand a relation for.

**Resolution never guesses.** A `sources:` glob is expanded against feature-004's streams and each
match becomes an edge; a glob matching nothing becomes a candidate. A basename citation resolving to
exactly one surviving node becomes an edge — which works precisely because feature-004's exclusion
filter removes the render copies, as its D5 records. A basename resolving to more than one, or to
zero, becomes a candidate with `drop_reason` `ambiguous-basename` or `unresolved-reference`, using
feature-004 D6's existing values rather than new ones.

#### D5. The provenance rule

> **`declared`** iff the carrier **states the relationship** in the source text a person wrote.
> **`derived`** iff the scan **computed the relationship**. **`inferred`** iff Pass 2 concluded it by
> reading. Provenance is a property of the carrier, never of the content and never of the endpoint
> kinds at the row's ends.

Applied to D4, kind by kind so nothing is left to inference: kinds **1–4** and **7** are `derived`
(nothing *states* that a section is part of a document or that a paragraph names a defined term —
heading levels and a token match are both computations); kinds **5, 6, 8, 9, 10, 11, 12** and **14**
are `declared` (an anchor, a definition marker, a `see_also:` entry, a `sources:` entry, a prose
citation, a link and a key citation are each a statement someone wrote); kinds **15–18** are
`derived` (feature-004's scanner computed each observation). Kinds **13** and **19** carry both
values, by the inherited rule immediately below.

**One rule is inherited rather than invented, and it is named because it is the only asymmetry.**
feature-001 D6c additionally stamps an illustration row `derived` "where the target is reached by
feature-004's basename or relative-path resolution rather than by a literal full path". That is
feature-001's contract for `illustrated-by`, whose `passes` admits both values, so it is honoured
exactly for harvest kinds 13 and 19 and nowhere else.

**Why it is not generalised, and why the question is routed rather than settled here.** Applying
"computed id ⇒ `derived`" to every carrier would make five relations unusable, because
`cites`, `cites-as-evidence`, `defines`, `documents` and `cross-references` all carry
`passes: [declared]` while the targets of their carriers are routinely reached by basename
resolution — feature-003 D2a-2's own verdict table admits a **basename** citation
(`` `read-setting.sh` -> `lookup_list` ``) as a correct durable anchor, and this repository's
`sources:` lists name paths under the dogfood render tree that feature-004 excludes, so basename
resolution is the common case rather than the edge case. Under the strict reading, the entire
evidence and documentation half of the vocabulary would have no producer. The rule above avoids that
by keying provenance on the *statement*, which is also how feature-004 D1a keys its own
`evidence_provenance` (`declared` because "the project registered the key itself", `derived` because
"the scanner computed the extension match"). The general question — whether `Provenance` tracks the
statement or the resolution — is feature-001's to confirm, and is routed as Open Item 4 with both
readings stated. **Until it is confirmed, the asymmetry is pinned by a criterion rather than left to
precedent**: **AC-S8** requires the `documents` row from a basename-resolved `sources:` entry to
carry `declared`, and `test-provenance-rule.sh` asserts it — so an implementer who generalises
feature-001 D6c's resolution-keyed rule to this carrier fails the suite instead of shipping `derived`
rows the vocabulary cannot accept.

**Row provenance is not node provenance, and conflating them would produce a wrong validator.**
feature-003 D3 states it: FR-31a part 2 lets Pass 2 create edges over nodes that already exist, so an
`inferred` row touching a `fact` node is legitimate, and no rule here restricts a row's provenance by
the kinds at its ends. Q13's "a fact node's provenance is always `declared` or `derived`" is a
property of the **node**, held by D2c.

#### D6. Pass 2 — FR-31a's four-part bound, made mechanical

FR-31a asserts a bound that had been claimed since FR-29 without being specified, and its own review
records a first draft that would have banned the reading-dependent edges FR-31 exists to produce. The
four parts are implemented as four mechanisms, none of which is a prompt instruction — **a
prompt-only bound is not a bound.**

##### Part 1 — a closed input set, each document read at most once

Pass 2's inputs are fixed before it starts and written to
`.aid/.temp/graph/pass2-inputs.tsv`: one row per document in the KB scan set (R1, minus D2a's two
excluded generated documents), plus the node inventory (`kb-nodes.tsv`, `nodes.tsv`,
`media-nodes.tsv`) and `candidates.tsv`. The set is therefore finite, known up front, and its size is
reportable before the pass runs — which is what FR-31a part 1 asks for.

**"At most once" is a property of the dispatch loop, not of the agent's discipline.** There are
exactly two dispatch classes:

| Dispatch | Count | Context it receives | Tools it receives | What it may return |
|---|---|---|---|---|
| **discovery** | one per document in the manifest | that **one** document's text, **inlined in the prompt**, plus the node inventory | **none** — no file read, no directory listing, no shell, no network fetch | class-1 rows whose endpoints are in the inventory |
| **typing** | one | `candidates.tsv` and the node inventory, likewise inlined — **no document text at all** | **none**, on the same terms | a typed relation or a `cannot-type` disposition, per candidate |

**The tool restriction is part of the bound, not an assumption behind it.** Column 4 is a contract
term, stated here because the bound is false without it: a dispatch holding a file-read or fetch tool
could read a second document whatever its prompt says, and the read ledger below would never see it.
Given the restriction, "at most once" is a property of the dispatch shape — a dispatch cannot read a
second document because it is neither given one nor able to obtain one, and outward crawling,
source-tree walking and fetching are closed off the same way. Without it, the same sentences would be
mere instructions — which is the standard this section opens with and fails: *a prompt-only bound is
not a bound.*

**Where the restriction is enforced, and what it is conditional on.** Two places, neither of them the
prompt's wording:

1. `canonical/skills/aid-graph/references/agent-pass.md` — this feature's own deliverable (Layers &
   Components) — states both dispatch shapes **and their empty tool sets** as the contract a caller
   must honour.
2. The dispatcher that performs the call constructs each dispatch with that tool set. The dispatcher
   is feature-010's runtime, so the enforcement point is **outside this feature**; routed as Open
   Item 14 rather than assumed.

**Neither enforcement point exists yet, and the claim is stated at that strength rather than above
it.** `agent-pass.md` is this feature's deliverable but is unwritten, and the
`canonical/skills/aid-graph/` directory that will hold it is created by the skill-wiring feature
(FR-7); feature-010's dispatcher is likewise unbuilt. So the bound is **structural given a stated
restriction that two unbuilt artifacts must carry** — not structural unconditionally. The distinction
matters to a reader deciding how much to trust FR-31a part 1 before those artifacts land: today the
restriction is a specified contract with a test hook (`test-agent-pass-bounds.sh` greps
`agent-pass.md` for the clause), not yet a running guarantee. The residual risk is named in Open
Item 12: batching
several documents into one dispatch would keep the tool set empty but weaken read-at-most-once from a
property of the shape to an instruction about the inlined text.

Each dispatch appends its document path to `.aid/.temp/graph/pass2-reads.tsv`; the completion check
(part 4) requires exactly one entry per manifest row. The ledger is a check on the **dispatcher**,
not on the agent: it proves each manifest document was dispatched exactly once, and it cannot observe
a read that happened outside the dispatch. That is precisely why the tool restriction, and not the
ledger, is the load-bearing half.

##### Part 2 — edges may be created, nodes never

The merge tests both endpoint ids of every returned row against the **union of the three node
streams** and rejects anything else. This is the downstream half of feature-004's `no-inferred-node`
invariant: enumeration never admits a node on inferred evidence, and this bound stops the only later
stage that could reintroduce one. Together they keep FR-24 intact end to end — every node carries
`declared` or `derived` evidence, so no reported gap can originate in an opinion, and no consumer
needs a filter for the case (feature-004 D3 names this consequence and asks to rely on it).

##### Part 3 — two kinds of work, both bounded by part 1

- **Typing** the candidates Pass 1 surfaced but could not classify — `candidates.tsv` is a closed
  list, produced by feature-004's rules and by D3's unmapped-kind path.
- **Discovery** — recording relationships visible only by reading a document the pass is already
  permitted to read once. **This is in scope**, and FR-31a says so explicitly. Concretely it is where
  the taxonomy, agreement and annotation families live: `broader-than` between two concepts,
  `supports` or `contradicts` between two facts, `exemplifies`, `same-as`, and the `mentions` edges
  D2d's literal matcher deliberately misses. D8's report marks these tokens `inferred-only`, which is
  what makes the discovery half's scope a list rather than an invitation.

##### Part 4 — the completion signal, and what `cannot-type` looks like

Every returned disposition is written to `.aid/.temp/graph/dispositions.tsv` —
`candidate_key | disposition | reason`, where `disposition` is `typed` or `cannot-type` and `reason`
is free text on the second value. After the pass returns, `build-relationships.sh` computes:

```
undispositioned = keys(candidates.tsv) \ ( keys(accepted class-1 rows) ∪ keys(dispositions.tsv) )
unread          = manifest rows with no entry, or more than one entry, in pass2-reads.tsv
```

A non-empty `undispositioned` or `unread` set **exits `1`, naming every item**, with the artifact
still written. FR-31a part 4 states the reason: "An untyped, undispositioned candidate is a failure,
not a silent omission — otherwise the pass could 'finish' by giving up quietly."

**Where a `cannot-type` disposition appears in the artifact — and where it deliberately does not.**

| Surface | Carries the disposition? | Why |
|---|---|---|
| a `relationships.md` row | **no** | a row needs a valid relation pair (V3, V4). A row typed with a null relation is unrepresentable, and inventing a `cannot-type` vocabulary member would put a non-relation in a closed vocabulary |
| `## Coverage notes` | **no** | this is the load-bearing constraint. feature-003 D7a places the whole section inside FR-32's guarantee and AC-5's second byte-comparison, and states that "no value varies between two runs on identical inputs". A Pass-2-derived count is non-deterministic by construction, so putting one there would break AC-5 for every project |
| `dispositions.tsv` + stdout + the exit code | **yes** | outside the byte-identity boundary, machine-readable, and visible on every run |
| a gap-ledger row | **no** | FR-26 requires every ledger row to carry the offending `int:` node as evidence and FR-20 keys the class on `Kind = source-artifact`; an untyped edge is neither. The same boundary FR-8a draws for convention absences |

This is the single sharpest interaction between FR-31a part 4 and AC-5, and getting it the other way
round would have produced an artifact that satisfied the completion signal while failing byte-identity
on every run — which is the shape of defect Q15 records three times.

##### The one degradation case, and why it is not a loophole

If Pass 2 **cannot be dispatched at all** — no host agent, or a dispatch failure — the orchestrator
writes a `cannot-type` disposition with reason `pass-2-unavailable` for **every** candidate, the
completion check passes by construction, and the artifact ships with class-0 rows only. If Pass 2
**ran and returned** while leaving a candidate undispositioned, that is the failure part 4 names.
Distinguishing the two is the whole point: graceful degradation is a recorded, total outcome; a
silent shortfall is not. The precedent for the first is the one `test-landscape.md` records for the
Playwright visual-fidelity gate, which "exits 0 with a SKIP" when its runtime is absent, and it keeps
FR-25's reporting-not-gating posture.

##### The four rejections the merge applies to every returned row

Enforced in `build-relationships.sh`, not in the prompt:

1. **Closed node set** — both endpoint ids appear in the three node streams (part 2, AC-S3).
2. **No revisiting** — a row whose `rel_row_key` is already in the frozen class-0 key set is
   rejected. This is the mechanical form of FR-31's "runs only over what the scan could not settle".
3. **Class 1 only** — every accepted row is stamped `provenance = inferred`, `class = 1`; a row
   arriving with any other provenance is rejected.
4. **Typed from the vocabulary** — `s2t` must be a merged-vocabulary member and `t2s` is looked up as
   its inverse; the chosen relation's `passes` must include `inferred`; and its `endpoint_kinds` must
   list the row's **`<source-kind>-><target-kind>`** pair, taken from the two node records. *(The
   previous revision compared a **prefix** pair here. That is the Q17 defect in miniature — under
   seven kinds a prefix pair cannot distinguish a document defining a concept from a section
   mentioning one, so the check would have passed rows the re-keyed vocabulary forbids.)*

Rejected rows are reported to stderr with a reason and dropped; a rejection is never fatal, because
FR-25's reporting-not-gating posture applies to the run as a whole. A rejected row still needs a
disposition, so the merge writes one with the rejection reason — otherwise a rejection would create
the very shortfall part 4 exists to catch.

#### D7. The coverage-note content this feature supplies — and the `fact` carrier decision

**Routed here by feature-003 and feature-004, and this is the discharge.** feature-003 owns the
`## Coverage notes` section's shape, row set, order and validation (its D7a, **V14**) and its Open
Item 5 assigns the *content* for extraction counts to this feature. feature-004 D7 fixes the
`present`/`absent` predicate and its Open Item 4 leaves this feature the four KB-side rows plus one
decision. This feature writes its contribution to `.aid/.temp/graph/kb-coverage.tsv` in feature-004
D7's five-field shape (`scope | key | status | count | note`); feature-010 assembles the rendered
section.

**The predicate is feature-004 D7's, consumed unchanged**, so the section does not carry two
definitions of `present`:

> A kind's status is **`present` iff this project supplied at least one instance of that kind's
> carrier convention** for the run to read, **`absent` otherwise**. The `count` remains the number of
> nodes emitted — so **`present` with a count of `0` is legal and meaningful**.

##### The `fact` carrier — decided: **the marker is the carrier**

feature-004 D7 states both readings and picks neither, naming this feature the owner. The decision:

> **One instance of the `fact` carrier is one citation marker of the KB's citation convention,
> whether or not it carries a grep-recoverable anchor string.** The anchor is the *qualifying test*
> that turns a marker into a node, not the carrier itself.

Four grounds, in the order they bear:

1. **It is what FR-9a asks for.** FR-9a wants "the **carrier convention** the kind depends on
   (glossary, checkable source anchors, headings, the external-sources file); whether that convention
   was **present or absent** in this project". Every carrier it names is a **project-side** thing a
   project either practises or does not. A project whose documents carry `CONFIRMED via directory
   listing.` markers — a real form feature-003 D2a-2 verified on disk — **practises the convention**
   and practises it badly. Reporting `absent` would assert the convention was missing, which is a
   false statement about the project.
2. **It keeps status and count carrying different information.** Under anchored-marker-as-carrier,
   `present` is exactly `count > 0` and the status column is redundant. That is the conflation
   feature-004 D7 removed for `source-artifact`, and reintroducing it one row below would leave the
   section with two predicates again.
3. **It makes a KB defect visible instead of disguising it as a tooling absence.** §2 purpose 1 makes
   the graph a KB *quality* signal. An unanchored citation marker is precisely the "unbacked KB
   claim" defect; reporting `present` / `0` alongside the skipped count shows a reader that the
   convention is being used and is not producing checkable claims. `absent` / `0` would read as "this
   project does not cite its sources", which is the opposite diagnosis.
4. **The reporting channel already exists and is already required.** feature-003 D2a-2 requires "the
   count of markers skipped for want of an anchor" in the coverage notes and D7a's own extra-row
   example is that count. So marker-as-carrier needs no new mechanism — it produces exactly the
   `source-artifact` / `source-artifact-dropped` pair feature-004 already established.

**feature-003 D7a's worked example stays satisfiable, as feature-004 required this decision to
confirm.** Its `fact` row reads `absent` / `0`, and that outcome remains reachable under
marker-as-carrier: a project with **no** citation marker of any form supplies zero carrier instances,
so the status is `absent` and the count is `0`. feature-004 D7 already isolated the only place the two
predicates can differ — "where a carrier is present and produces nothing, which the example does not
exercise" — and that case does not appear in D7a's skeleton. The example is therefore satisfiable
under the chosen reading without amendment, and no change is owed to feature-003.

**On this repository the row reads `present` with a non-zero count**, because citation markers are
present and well-formed ones exist (feature-003 D2a-2 verifies both the well-formed and the
anchor-less forms on disk). AC-19's `fact` arm is therefore validated against a fixture, not here —
the same reasoning A-6 applies to AC-1's `ext:` branch.

##### The four fixed `kind` rows this feature owns

| `key` | `note` (carrier convention) | `status` | `count` |
|---|---|---|---|
| `document` | `KB documents under .aid/knowledge/` | `present` iff ≥ 1 document in the scan set | `document` nodes |
| `concept` | `definition marker under a level-3+ heading` | `present` iff ≥ 1 definition marker | `concept` nodes |
| `fact` | `checkable source anchor (path + grep-recoverable string)` | `present` iff ≥ 1 citation marker | `fact` nodes |
| `section` | `ATX headings, levels 2-6` | `present` iff ≥ 1 heading at levels 2–6 outside a fence | `section` nodes |

The `note` text reproduces feature-003 D7a's example wording verbatim in all four rows; no
divergence is needed here, unlike feature-004's `image` row. For `document`, `section` and `concept`
every carrier instance becomes a node, so status and a non-zero count coincide and feature-004 D7's
revision changes nothing; `fact` is the one row where the two can differ, which is why it needed the
decision above.

##### Four permitted additional rows

Using the extension mechanism feature-003 D7a provides ("Extra rows below the fixed ones are
ignored"):

| `scope` | `key` | `status` | `count` | `note` |
|---|---|---|---|---|
| `kind` | `fact-unanchored` | `--` | `--` | `citation markers skipped for want of an anchor string: <n>` |
| `kind` | `section-empty-slug` | `--` | `--` | `headings whose slug normalised to empty, emitting no section node: <n>` |
| `kind` | `concept-qualified` | `--` | `--` | `terms carrying more than one definition, emitted in the @<doc> qualified form: <n>` |
| `kind` | `concept-merge-candidates` | `--` | `--` | `concept mentions sitting in the structural position of a false merge, advisory: <n>; filtered by shared vocabulary: <n>; concepts skipped as single-concept-defining: <n>` |

The first two are **required by feature-003**, not optional: D2a-2 requires the skipped-marker count
and D2a-1 requires the empty-slug count, and neither has anywhere else to go. The third makes the
structurally split false-merge case (D2d case 1) countable. The fourth carries D2f's candidate count
**and two of its three reach counters in the same `note`**, and it belongs in the artifact rather
than only on stdout for one reason: Q18 ruling 2 requires the case to be **closed**, and a number
that survives the run is the difference between a detector and a log line — while the reach counters
are what stop a zero in that number from being ambiguous. All three values are functions of the
frozen class-0 set, so they are Pass-1-deterministic like the other rows. **Three numbers in one
`note` rather than three rows is deliberate restraint:** the aggregate extra-row inventory is itself
under review at Open Item 16, and a detector that widened the inventory while that item is open would
be arguing against its own routing. All four rows report their numbers in the `note` and carry `--`
in `count`, because feature-004 D7 fixes `count` as a **node** count so the rendered `Nodes` column
stays summable — none of the four is a node count.

**The same reliance and the same fallback as feature-004 Open Item 6a.** All four rows depend on
**V14** tolerating a non-enum label in an extra row's first cell. If feature-003 declines or defers
that tolerance, the four numbers move into the fixed rows' `note` cells, which V14 does not
constrain — presentation is lost, content is not. Relayed at Open Item 5 rather than assumed.

**Every value here is Pass-1-only, and that is required rather than incidental.** feature-003 D7a
puts the whole section inside FR-32's guarantee; FR-31a part 2 forbids Pass 2 to create nodes, so
every count above is a function of the deterministic pass — including D2f's three, which are computed
from the frozen class-0 set before Pass 2 is dispatched. This is the same argument that keeps the
Pass-2 disposition count **out** of the section (D6).

**What this feature can guarantee about the section, and what it cannot.** Every *value* and every
*row* this feature contributes is byte-stable, and `test-relationships-reproducible.sh` asserts it.
The **order in which the extra rows of two contributing files appear in the rendered section** is not
this feature's to fix: feature-010 assembles `kb-coverage.tsv` and feature-004's `coverage.tsv` into
one section, feature-003 owns the section contract, and AC-5 byte-compares the whole section. Six
extra rows now arrive from two files with no stated ordering rule between them, so byte-identity of
the extra-row block rests on assembly behaviour no gated SPEC specifies. Recorded as **Open Item 16**
and deliberately **not** settled here — writing an ordering rule into this SPEC would bind
feature-003's section contract from outside it, which is the silent divergence the routing discipline
exists to prevent.

#### D8. The W3 producer-satisfiability map (feature-001 Open Item 6, discharged)

feature-001 D3a defines four layers of endpoint checking and assigns **W3** to this feature, because
the edge-relation map is the only enumeration of what produces which relation. Its definition,
quoted:

> A token `"a->b"` on relation `r` is **satisfiable** iff at least one entry of feature-005's
> edge-relation map that resolves to `r` — or resolves to `r`'s inverse with the token transposed —
> can produce a source node of kind `a` and a target node of kind `b`.

**The report is a report and never a gate**, for the reason feature-001 states: a core vocabulary is
deliberately larger than any one project's producers, and gating would mean a project could not ship
a comprehensive core until it also shipped a producer for every entry.

##### Shape

`.aid/.temp/graph/w3-satisfiability.tsv`, emitted by `report-endpoint-satisfiability.sh` after the
map loads and before any row is written — it depends on the map and the vocabulary alone, never on a
generated table (that is W4, feature-003's):

| # | Field | Value space |
|---|-------|-------------|
| 1 | `relation` | a merged-vocabulary `relation` label — one block of rows per **entry**, all 57 |
| 2 | `token` | one of that entry's `endpoint_kinds` tokens, `<kind>-><kind>` |
| 3 | `mark` | `producer` \| `inferred-only` \| `unreachable` |
| 4 | `producers` | the `\|`-separated harvest kinds that can emit it, or `--` |

**The report is authored per pair and rendered per entry.** feature-001 D4 property 6 makes an
inverse entry's `endpoint_kinds` the exact transpose of its partner's and its `passes` equal, so an
inverse entry's marks are its partner's marks transposed. Computing one and transposing is what stops
the two halves of a pair from being classified inconsistently.

**Orientation does not disturb the classification.** feature-003 D7 normalises a row's orientation
before it is stored, swapping the two `(Id, Kind, Name)` triples **and** the two relation labels
together — so the (relation, token) pairing survives normalisation and the report can be computed
from the map rather than from emitted rows.

##### Two different questions, and only the second is W3

This distinction is the substance of the report, and collapsing it is a Q17-shaped error — a **kind**
standing in as a proxy for a **relation–token**:

- **The kind-pair matrix** asks: *is this ordered pair of kinds producible at all?* It is a property
  of the producer set, 49 cells, independent of the vocabulary.
- **W3** asks: *can this relation's declared token be produced?* It is strictly stronger, because a
  producible kind pair says nothing about whether any producer resolves to the relation that declares
  it.

##### The kind-pair matrix — all 49 cells

Rows are the source kind, columns the target kind, both in §5.2's enum order. `P` = some map entry
emits the pair (in either reading — emitting `document->section` as `has-part` also emits
`section->document` as `part-of`); `I` = no producer, but some core entry declaring the token admits
`inferred`, so Pass 2 may create it; `—` = **no core entry declares the token at all**, so W3 says
nothing about it.

| source \ target | document | concept | fact | section | source-artifact | image | web-page |
|---|---|---|---|---|---|---|---|
| **document** | P | P | P | P | P | P | P |
| **concept** | P | I | P | P | I | I | — |
| **fact** | P | P | I | P | P | P | P |
| **section** | P | P | P | P | P | P | P |
| **source-artifact** | P | I | P | P | P | P | P |
| **image** | P | I | P | P | P | I | — |
| **web-page** | P | — | P | P | P | — | I |

Totals: **37 producible, 8 `inferred-only`, 4 undeclared** — and, notably, **no `unreachable` cell**.
The eight `inferred-only` cells are `concept->concept`, `concept->source-artifact`, `concept->image`,
`fact->fact`, `source-artifact->concept`, `image->concept`, `image->image` and `web-page->web-page`;
the four undeclared are `concept->web-page`, `image->web-page`, `web-page->concept` and
`web-page->image`.

**The three empty source rows in the producer set are the informative part.** `concept`, `image` and
`web-page` originate no edge in Pass 1, and each cell marked `P` in those rows is produced only as
the *inverse reading* of a row whose source is a KB text extent or a source artifact. The reason is
structural rather than an omission: an edge is harvested from a carrier, a carrier is a literal in
some text, and none of those three kinds has a text extent of its own — which is exactly the argument
feature-001 D6c used to exclude `concept->image` from `illustrated-by`, applied to the whole matrix.

##### The `unreachable` tokens W3 exposes

Unreachability lives entirely at the (relation, token) level. The map resolves to **10 of the
vocabulary's 31 pairs** — `has-part`, `defines`, `mentions`, `documents`, `cites`,
`cites-as-evidence`, `depends-on`, `invokes`, `illustrated-by` and `cross-references`. The other
**21** have no producer, and they divide cleanly: **eleven** admit `inferred` and are therefore
`inferred-only`, reachable through Pass 2's discovery half (`broader-than`, `related-concept`,
`exemplifies`, `derived-from`, `supersedes`, `implements`, `same-as`, `similar-to`, `supports`,
`contradicts`, `annotates`); **ten** do not, and are wholly unreachable.

**Those ten unmapped pairs, and why each has no producer** — no map entry resolves to them and their
`passes` excludes `inferred`, so no pass can emit them:

| Pair | `passes` | Tokens | Why no producer, and where the fix belongs |
|---|---|---|---|
| `has-member` / `member-of` | `declared` | 4 | no carrier declares set enrolment; `.aid/settings.yml` `knowledge.doc_set` is the closest, and it arrives inside feature-004's conflated `dependency` observation (Open Item 3) |
| `precedes` / `follows` | `declared`, `derived` | 2 | **no carrier declares sequence.** Adjacency in a document's own layout is derivable, but it is not a carrier — it is the layout itself, and feature-003 D7's total row order already reproduces it losslessly for every project, so an edge per adjacent pair would re-encode a property the artifact carries. A carrier would be a field or marker *asserting* order (a `follows:` frontmatter entry, a numbered-step convention); the AID KB conventions define none |
| `generated-by` / `generates` | `derived` | 3 | `generated-files.txt`'s output ↔ build-command edge is exactly this relation, but it arrives as feature-004's `dependency` kind and types as `depends-on` (Open Item 3) |
| `quotes` / `quoted-in` | `declared` | 4 | verbatim reproduction has no mechanical carrier — detecting it is a reading task, and the `passes` set excludes `inferred` (Open Item 8) |
| `revision-of` / `has-revision` | `declared`, `derived` | 3 | no KB or source carrier declares a version relation between two artifacts |
| `lockstep-with` | `declared` | 2 | the mutual-maintenance invariant feature-001 D6a cites is stated in KB **prose**, which is a reading task; `passes` excludes `inferred` (Open Item 8) |
| `tests` / `tested-by` | `declared`, `derived` | 4 | **no carrier supplies the subject.** feature-004's `convention` observation identifies a test file, but its payload is the file, not what the file tests; nothing in this design turns the second into the first. This is a *current* absence with two named routes to a producer, not an impossibility — Open Item 13 |
| `renders-to` / `rendered-from` | `declared`, `derived` | 3 | the canonical → profile render relation is real and is excluded upstream: feature-004 D4 Class 1 cuts the render trees, so the target of every such edge is not a node |
| `alternate-of` | `declared`, `derived` | 4 | no carrier declares alternate presentation |
| `canonical-form-of` / `has-canonical-form` | `declared`, `derived` | 3 | same as `renders-to` — the copies are excluded, so the token has no second endpoint |

Plus **eleven tokens on mapped relations** whose specific kind pair no map entry produces, each with
`passes` excluding `inferred`:

| Relation | Unreachable token(s) | Why |
|---|---|---|
| `cites-as-evidence` | `fact->web-page`, `fact->image` | the Citation Rule's two forms both require a path plus a grep-recoverable string; a registered `ext:` key is not a path, and an image carries no greppable string |
| `defines` | `section->concept` | D2d emits the definition edge from the **document**, for the three reasons stated there |
| `cross-references` | `section->section`, `concept->document`, and `document->section` **by design choice, not by prohibition** | the carrier is a `see_also:` entry, which has no source finer than the document it sits in — so no `section->` or `concept->` token is producible. `document->section` is different and is stated as such: `frontmatter-schema.md`'s rule for the field is that each entry **SHOULD** be a sibling doc name, which is advisory, so an entry carrying a section anchor is convention-permitted. Kind 8 nonetheless resolves an entry to its document — splitting at `#` and discarding the fragment — because a SHOULD-discouraged form is not an authoring convention this design can rely on across projects (FR-8a), and the discarded fragment is preserved in the row's `Observation` anchor. Widening kind 8 is a one-line change gated on the convention being stated; Open Item 15 |
| `documents` | `section->source-artifact`, `document->document`, `section->document`, `document->image` | `sources:` is likewise document-level and names files, so only `document->source-artifact` and `document->web-page` are produced |
| `cites` | `fact->document` | D2e's ceiling: a doc link inside a fact's anchor block attributes to the enclosing section, because `mentions` — the relation that types doc links — declares no `fact->document` |

**None of these is a defect in the vocabulary**, and the report says so: feature-001 D3a records that
"a core relation may be unreachable on one project and central on another, and feature-005's map is
allowed to grow after the vocabulary ships". **Five of the ten carry a named route to a producer**,
and each route is an Open Item rather than a wish: `has-member` and `generated-by` would gain
producers if feature-004 subdivided its `dependency` observation kind (Open Item 3); `quotes` and
`lockstep-with` describe relationships a reader can see and a scanner cannot, so widening their
`passes` to include `inferred` would move them to `inferred-only` and into Pass 2's discovery scope
(Open Item 8); and `tests` would gain one from either a subject-bearing frontmatter field or a
subject-bearing widening of the `convention` observation (Open Item 13). The remaining five —
`precedes`, `revision-of`, `renders-to`, `alternate-of`, `canonical-form-of` — have no route in
sight, and the table says why for each. **No pair is marked unreachable because this project has no
consumer for it**: the ruling on that is the work owner's (STATE.md Q18 ruling 1) — unreachable
relations stay in the vocabulary and W3 reports reachability per project — so every justification
above is about carrier availability alone.

**And the one entry the report clears explicitly**: `illustrated-by`'s four declared tokens —
`document->image`, `section->image`, `fact->image`, `source-artifact->image` — are **all `producer`**,
three from harvest kind 13 and one from harvest kind 19. feature-001 D6c called this "the worked
example that shows the report is not ceremony", and it is: it is the only entry in the vocabulary
whose tokens are satisfied by producers in two different features.

### Feature Flow

Inputs: feature-004's four streams; `.aid/knowledge/*.md`; the merged vocabulary and the
edge-relation map; `.aid/knowledge/external-sources.md` (or a fixture via `--external-sources`);
`<install-root>/aid/templates/graph/relationship-schema.yml` via `rel_load_schema`. Output:
`.aid/knowledge/relationships.md`. No KB content is modified (FR-10) — the only write outside
`.aid/.temp/graph/` is the artifact itself.

**Load — fail closed before any row exists**

1. Parse arguments with the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop and `shift 2`
   per flag that `read-setting.sh` establishes; unknown flag → stderr + exit 2.
2. `rel_load_schema` (both enums, `image_extensions:`) and `rel_load_vocabulary` (core + optional
   extension, merged, six properties). Any missing or malformed required input, or a core/extension
   collision → exit 2.
3. `load_edge_relation_map` — arity, completeness, pass legality and endpoint legality (D3, AC-S5).
   Exit 2 on any failure, naming the resolved absolute path.
4. Emit the **W3 report** (D8). It depends on steps 2 and 3 alone and gates nothing.

**Pass 1a — the Knowledge Base** (`harvest-declared.sh`)

5. Build the scan set (R1) and apply D2a's two source exclusions. Write the manifest that will bound
   Pass 2 (D6 part 1).
6. **One forward pass per document** (R4, AC-S1), maintaining a single fenced-code state and
   computing together: `rel_doc_slugs` (section nodes and the duplicate counter), the shallower-level
   stack (containment parentage, D2b), `rel_fact_tokens` (fact nodes, D2c), `rel_block_bodies` +
   the definition-marker test (concept candidates, D2d), the enclosing-node chain (D2e), and the
   inline carriers of D4 kinds 11–14.
7. Read each document's frontmatter once with the batched awk extractor pattern shared by
   `lint-frontmatter.sh` (`load_frontmatter`) and `kb-freshness-check.sh` (`fm_scalar` / `fm_list`) —
   one pass per document, arrays populated, no per-field fork. Harvest kinds 8–10.
8. Resolve the concept set across documents (`rel_concept_defs`), applying the exactly-one rule and
   the `@<doc>` qualified form where it fires. **This is the merge point** and it must follow step 6
   for every document, because the plain-versus-qualified decision is a property of the whole KB and
   not of one file.
9. Emit `kb-nodes.tsv` — `node_id | node_kind | name | doc` — and one row per D4 kind 1–14, each
   typed through the map, stamped by D5, and given an `Observation` **whose first whitespace-delimited
   token is a path**, so feature-003 **V11**'s durable-anchor predicate is satisfied by construction
   on every class-0 row. Unresolved or ambiguous references append to `candidates.tsv` using
   feature-004 D6's existing `drop_reason` values.

**Pass 1b — feature-004's observations** (`derive-edges.sh`)

10. Read `observations.tsv`; for each row look up `observation_kind` in the map, resolve `s2t`/`t2s`
    from the vocabulary, carry both `node_kind` values from the node records, and emit with
    `provenance = derived`, `class = 0`, and the observation's evidence anchor verbatim as
    `Observation`. An unmapped kind — `path-reference` by design — appends to `candidates.tsv` and
    emits nothing.

One consequence worth recording: the `dependency` observation over
`profiles/*/emission-manifest.jsonl` `src` → `dst` pairs yields no rows, because every `dst` is
inside an excluded render tree (feature-004 D4 Class 1). The manifest's own `src` side is already
covered by the `canonical/EMISSION-MANIFEST.md` declared carrier.

**The reproducibility boundary sits here — after step 10, before step 11.**

11. **Merge and freeze class 0** (`build-relationships.sh`). Normalise every class-0 row with
    `rel_normalise_row`, key it with `rel_row_key`, and de-duplicate: a repeated key keeps the row
    with the stronger provenance (`declared` over `derived`) and, on a tie, the lexicographically
    smaller `Observation` — a total rule, so the survivor never depends on arrival order. Sort by
    `rel_sort_key` under `LC_ALL=C`. Write `.aid/.temp/graph/rows-class0.tsv` and record its key set.
11a. **Compute the false-merge candidate report** (D2f, AC-S7 / AC-S7a) over the frozen set from
    step 11: evaluate the four-condition predicate per (plain-form concept, mentioning document)
    pair, accumulating the four reach counters as it goes; write `concept-merge-candidates.tsv`,
    print each pair at `[LOW]` followed by the counters, and carry `candidates`,
    `filtered_by_shared_vocabulary` and `skipped_single_concept` into the coverage contribution.
    Advisory throughout — it changes no row and no exit code.

**Pass 2 — the bounded agent pass**

12. Dispatch per D6: one discovery dispatch per manifest document, one typing dispatch over
    `candidates.tsv`. Append to `pass2-reads.tsv` and `dispositions.tsv`.
13. **Merge class 1.** Apply D6's four rejections, normalise, key, de-duplicate against both the
    class-0 key set and other class-1 rows, sort under `LC_ALL=C`. Write a disposition for every
    rejected row.
14. **Completion check** (D6 part 4, AC-S4). Compute `undispositioned` and `unread`; a non-empty
    either exits `1` naming every item, after the artifact is written.

**Render and verify**

15. Emit feature-003 D8's frontmatter, the `AUTO-GENERATED` marker (no timestamp), the
    `# Relationships` H1, then the **ten**-column table — class-0 rows as a contiguous prefix,
    class-1 rows after — then the `## Coverage notes` section assembled by feature-010 from this
    feature's and feature-004's contributions. LF endings, single-space cell padding, `|` escaped as
    `\|`, an empty `Observation` rendered as a single space.
16. **Self-validate.** Invoke feature-003's `validate-relationships.sh` on the file just written. A
    non-zero exit is reported and surfaces as ledger findings; the artifact is still written, so the
    failure is visible rather than hidden behind a missing file.

Exit codes: `0` success; `1` a write failure, a validator finding, or a completion shortfall; `2` a
usage error or a missing/malformed schema, vocabulary, edge-relation map, or feature-004 stream.
Reusing the documented scheme rather than inventing codes, per `coding-standards.md` ("A new failure
mode SHOULD reuse an existing code with matching semantics").

#### What guarantees FR-32 / AC-5

Byte-identity of the deterministic majority, with **all five of FR-11's staleness inputs unchanged**,
rests on eight mechanisms, each a stated rule with a test. The list is longer than the previous
revision's by one, and the scope of several has grown, because the deterministic set now covers the
`section`, `fact` and `concept` nodes and their declaring edges — and because AC-5 now byte-compares
**two** extractions, not one.

1. **Contiguity.** Class-major sort order (feature-003 D7) makes class 0 a contiguous prefix, so no
   class-1 change can move, split, or reflow a deterministic row. **V10** asserts it, and
   `rel_class0_block` (feature-003 D7b) is only sound on a V10-passing table — so the extraction runs
   after V10, never before.
2. **Enforced one-way merge.** Step 13 rejects any class-1 row colliding with a class-0 key and any
   row not stamped `inferred`, so Pass 2 has no write path into class 0 at all.
3. **Node ids are pure functions of document bytes.** Every KB-side id comes from a feature-003 D9
   function over the current text, and the same function recomputes it in **V2**. Nothing is
   remembered between runs, so there is no state to drift.
4. **The concept set is order-independent.** Identity is the normalised term and resolution requires
   exactly one definition across the whole KB, so the node set does not depend on which document was
   read first. The `@<doc>` qualified form is likewise decided from the full definition set (step 8).
5. **Stable ordering.** `LC_ALL=C` on every sort this feature performs, including its own enumeration
   of the scan set. The precedent is `build-project-index.sh` (`| LC_ALL=C sort`, line 185) and
   `kb-freshness-check.sh` (line 460); `build-kb-index.sh`'s scan is **not** a precedent, because its
   `sort` is bare (line 471) — feature-003 D2a quotes it. This feature relies on nothing that script
   orders.
6. **No time and no position inside the boundary.** No timestamp in the table, in any row, in the
   coverage notes, or in the `AUTO-GENERATED` marker — the deliberate divergence from `INDEX.md`,
   which embeds a timestamp and therefore churns — and no `changelog:`. No mtime, no file size, no
   line number; every `Observation` anchor is a grep-recoverable literal, which is both the Citation
   Rule and a byte-stability requirement. feature-010's `graph_inputs_digest` and
   `graph_generated_at` sit **outside** the boundary by feature-003 D8's design.
7. **Total tie-breaks.** Both de-duplication rules (steps 11 and 13) are total orders, so the
   surviving row never depends on arrival order.
8. **The coverage notes are Pass-1-only.** feature-003 D7a puts the whole section inside the
   guarantee and AC-5 byte-compares it as a second extraction, so every number this feature
   contributes is a function of the deterministic pass — and the Pass-2 disposition count is
   deliberately **not** among them (D6).

Plus LF-only output throughout, written the way `canonical/EMISSION-MANIFEST.md` mandates ("**`LF`
(`\n`) only**, even on Windows"). This repository is authored on Windows, so it is a live hazard
rather than a formality.

**AC-5's mechanical check** is feature-003 D7's: regenerate, then byte-compare `rel_class0_block` and
the whole `## Coverage notes` section against
`git show HEAD:.aid/knowledge/relationships.md`. No stored hash and no side-channel file is needed,
and `.aid/knowledge/` is not gitignored (only `.aid/knowledge/.cache/` is — verified by feature-003
D7). Whether a staleness *decision* follows from that comparison is FR-11 / feature-010's call.

### Proxy sweep (Q17)

Q17 records a defect class — a clause keyed on a **proxy** for something the model change altered —
and issues a standing instruction to sweep for it during re-specification. The sweep of this SPEC's
previous revision found five, all fixed above. Recorded rather than merely fixed, because the value
of the instruction is in the pattern.

| # | Clause in the previous revision | The proxy | What broke |
|---|---|---|---|
| 1 | the edge-relation map's field 3 held `int:->int:`, `kb:->ext:` and so on | a **prefix** standing in for a **kind** | with seven kinds, `kb:->kb:` cannot distinguish a document defining a concept from a section mentioning one, so the endpoint gate would have passed rows the re-keyed vocabulary forbids (D3) |
| 2 | Pass 2's typing bound checked "the row's `<source-prefix>-><target-prefix>` pair" against `endpoint_kinds` | the same proxy, one layer down | the same defect, in the one place a wrong row reaches the artifact (D6, rejection 4) |
| 3 | field 3's encoding argument — "a plain scalar containing `: ` is read as a mapping" | a **notation artifact** standing in for a rule | the hazard was a property of the colon in a prefix token; a `Kind` token has none, so the argument is void and is recorded as void rather than silently kept (D3) |
| 4 | Pass 2's residue was "heading-level `kb:` ids carrying **zero** class-0 edge" | a **count** standing in for a **set** | it defined Pass 2's job as finding nodes the scan had not connected, which is node discovery in all but name. FR-31 narrowed Pass 2 to typing edges, and FR-31a part 1 replaced the residue with a closed input set (D6) |
| 5 | `rel_normalise_row` was described as swapping ids and names | an **eight-column shape** standing in for a ten-column one | a swap that moved ids and names while leaving the two `Kind` cells would fail **V13** on a row that was correct before normalisation; feature-003 D7 names it as a bug any carried-over implementation has (D1) |

Two further clauses were checked and confirmed **not** proxies, so the sweep's negative results are
recorded too: `class` (`0`/`1`) is a partition of the provenance enum and remains exact under the
widening, because feature-003 D3 defines it that way; and the KB scan-set predicate keys on a
**path shape**, not on a node kind, so widening the node model left it exact.

### Layers & Components

New files only; no existing script is forked (C-4). Authored in `canonical/`, then rendered by the
FULL `run_generator.py` — never hand-edited under `profiles/` or the dogfood `.claude/` (C-2;
`module-map.md` Invariants). `canonical/aid/scripts/` and `canonical/aid/templates/` are both
recognised asset kinds in `canonical/EMISSION-MANIFEST.md`'s "Asset Kinds" table, so the `graph/`
subdirectory renders into all five profiles with no renderer change; the per-profile
`emission-manifest.jsonl` records are regenerated by the same run and the render-drift CI job gates
the result (C-3). `canonical/aid/templates/graph/` already exists on disk, so the path is proven
rather than proposed.

| Layer | Path | Purpose |
|-------|------|---------|
| Script | `canonical/aid/scripts/graph/harvest-declared.sh` | Pass 1a — the four KB-side node kinds and D4 harvest kinds 1–14 |
| Script | `canonical/aid/scripts/graph/derive-edges.sh` | Pass 1b — types feature-004's observations; no traversal of its own |
| Script | `canonical/aid/scripts/graph/build-relationships.sh` | steps 11–16 — merge, freeze class 0, compute D2f's candidate report, bound and merge class 1, run the completion check, render, self-validate. This is the `generator:` value in feature-003 D8's frontmatter |
| Script | `canonical/aid/scripts/graph/report-endpoint-satisfiability.sh` | D8 — the W3 report; reads the map and the vocabulary only, gates nothing |
| Template | `canonical/aid/templates/graph/edge-relation-map.yml` | D3 — `<harvest-kind>\|<emitting-provenances>\|<kind-pairs>\|<relation-label>` |
| Reference (prose) | `canonical/skills/aid-graph/references/agent-pass.md` | the two Pass-2 dispatch shapes, **their empty tool sets** (D6 part 1 — the contract term the read-at-most-once bound rests on) and the four bounds, authored as skill prose per `authoring-conventions.md` "Prose Over Scripts"; row-level enforcement lives in `build-relationships.sh`, and honouring the tool sets at call time is the dispatcher's (Open Item 14). The `canonical/skills/aid-graph/` directory itself is created by the skill-wiring feature (FR-7); this feature contributes only this reference file |
| Script library | reuses `canonical/aid/scripts/graph/relationship-schema.sh` (feature-003 D9) | id parsing and resolution, slugs, fact tokens, term normalisation, block bodies, concept definitions, display names, normalisation, keys, sort keys, the class-0 block, and both loaders |
| Test | `tests/canonical/test-kb-node-set.sh` | Pass 1a's node production: a section node per level-2–6 heading and none for level 1; the empty-slug heading emitting no node but incrementing the coverage count; a well-formed anchor yielding a fact node and an anchor-less marker yielding none; a definition marker under a level-3+ heading yielding a concept; **containment computed with a level stack** (a level-4 following a level-5 attaches to the nearest *shallower* emitted heading, not to the nearest preceding one); and a **fenced** heading-shaped line and a **fenced** marker each producing nothing, from the one shared fence state (AC-S1) |
| Test | `tests/canonical/test-concept-merge.sh` | AC-S2: a term defined once and named in three documents yields **one** node and three `mentions` edges; a term defined twice yields **two** `@<doc>` nodes and **no** plain-form node; a mention inside the concept's own defining block yields no self-edge; a mention inside a fence yields nothing; a term occurring as a substring of a longer token yields nothing (token-bounded matching); and an `**Aliases:**` value yields **no** edge (D2d) |
| Test | `tests/canonical/test-harvest-declared.sh` | one fixture per D4 kind 5–14, plus the two source-exclusion assertions of D2a — a heading and an anchor inside `INDEX.md` and inside `relationships.md` produce **no** node and **no** edge, while a citation *of* either produces a real edge |
| Test | `tests/canonical/test-derive-edges.sh` | one fixture per observation kind; `path-reference` becoming a candidate and never an untyped row; and the four map-load gates (wrong arity, unmapped kind, pass-illegal mapping, endpoint-illegal mapping) each exiting 2 — with the endpoint-illegal fixture using a **kind** pair, so a loader still comparing prefixes fails the suite |
| Test | `tests/canonical/test-provenance-rule.sh` | D5: a containment edge is `derived` and an anchor edge is `declared`; **AC-S8** — a `sources:` entry that is a bare basename resolving to one path emits a `documents` row whose provenance is `declared`, asserted directly so an implementer generalising `illustrated-by`'s resolution-keyed rule fails the suite; an image reference resolved by relative path is `derived` while one naming a literal repo path is `declared` (feature-001 D6c) |
| Test | `tests/canonical/test-concept-merge-candidates.sh` | AC-S7 / D2f: a mention in a document that neither links the defining document nor shares another concept with it is reported; the same pair with a `see_also:` entry added is **not** (condition 3); the same pair sharing a second concept is **not** (condition 4); a `@<doc>` qualified concept is never reported (condition 1); a defining document naming no second concept reports nothing however isolated its mentions (the degenerate exclusion); the count reaches the coverage notes and the per-pair detail reaches the TSV and stdout; **AC-S7a** — all four reach counters are reported and `candidates = pairs_1_3 − filtered_by_shared_vocabulary` holds, asserted on a fixture where the condition-4 filter is non-empty so a run that silently stopped counting the filtered population fails the suite; and a run with candidates still exits `0` and writes no gap-ledger row |
| Test | `tests/canonical/test-agent-pass-bounds.sh` | D6: each of the four rejections drops a crafted violating row (an id in neither stream, a colliding key, a non-`inferred` provenance, and — for the typing bound — a non-vocabulary label, a relation whose `passes` excludes `inferred`, and a relation whose `endpoint_kinds` excludes the row's **kind** pair); the read ledger rejecting a document dispatched twice; the completion check exiting `1` on an undispositioned candidate **with the artifact present**; the `pass-2-unavailable` path dispositioning every candidate and exiting `0`; and a grep assertion that `agent-pass.md` states the **empty tool set** for both dispatch shapes — the only mechanical check a prose contract admits, and the one that fails loudly if the clause the bound rests on is ever dropped |
| Test | `tests/canonical/test-relationships-reproducible.sh` | AC-5: two consecutive runs on an unchanged fixture tree yield a byte-identical class-0 block **and** a byte-identical coverage-notes section; then a class-1 row is added, removed and reworded and both are asserted unchanged; then a Pass-2 disposition count is changed and the coverage notes are asserted unchanged, which is the assertion that would fail if a Pass-2 number ever reached the section |
| Test | `tests/canonical/test-w3-report.sh` | D8: every entry's every token carries exactly one mark; an inverse entry's marks are its partner's transposed; `illustrated-by`'s four tokens are all `producer`; a fixture map with no entry for a `declared`-only relation marks its tokens `unreachable`; and the report exits `0` regardless |
| Fixtures | `tests/canonical/fixtures/graph/` | a self-built miniature KB carrying a level-4 heading nested under a level-3 (which this repository's KB cannot supply), a duplicate heading, a wrapped anchor, an anchor-less marker, a term defined twice, a near-plural pair, a fenced heading-shaped line and a fenced marker, a markdown image reference (which this repository's KB does not carry), a document with **no** glossary, **no** anchors and **no** headings for AC-19, and a four-document set exercising D2f's predicate (isolated mention, linked mention, concept-sharing mention, qualified concept); a fixture source tree with one observation of each kind; fixture core and extension vocabularies and an edge-relation map; and the Q4 synthetic `external-sources.md` |

Conventions honoured (`coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; a header block stating Purpose / Usage / Exit codes; `-h|--help` re-printing
  a slice of that header.
- `set -euo pipefail` for the writing scripts; `set -uo pipefail` for `report-endpoint-satisfiability.sh`,
  following the read-only reporting precedent (`kb-citation-lint.sh`).
- Argument parsing via the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with `shift 2`;
  unknown flag → stderr + exit 2; file errors print the resolved absolute path.
- stdout carries results, stderr carries diagnostics; a one-line prefixed summary per script
  (`[harvest] …`, `[derive] …`, `[relationships] …`, `[endpoints] …`), matching the `[index]`-prefixed
  style of `build-project-index.sh`.
- Every sort **this feature writes** is `LC_ALL=C`, following `build-project-index.sh` line 185 and
  `kb-freshness-check.sh` line 460. The repository is not uniform on this, so the convention is
  stated as this feature's own rule rather than as an inherited one.
- Frontmatter is parsed with the project's awk extractors — one batched pass per document, no
  per-field fork (the pattern `lint-frontmatter.sh` `load_frontmatter` and `kb-freshness-check.sh`
  `fm_scalar`/`fm_list` establish, and which `build-kb-index.sh` records as a deliberate
  Windows-Git-Bash fork-cost optimisation).
- No YAML/JSON binary dependency; the flat YAML this feature reads is parsed with awk, as
  `coding-standards.md` prescribes for AID's own simple configs.
- Any value read from frontmatter or from a template file is treated as untrusted when passed to git —
  `--end-of-options` guards a commit-ish, as `kb-freshness-check.sh` does.
- Tests are discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob; fixtures are
  self-built and reference nothing under `.aid/works/` (A-6, and the project's transient-work-folder
  rule).

### External Integrations

Pass 2 is the one part of this feature that is not a script, so its integration surface is stated
rather than assumed.

- **What it is.** A sub-agent dispatch to the host AI harness the user is running under. There is no
  network call, no MCP server and no external service: `integration-map.md` records that "AID is a
  distributed toolkit, not a networked service" and that the only runtime HTTP surface in the project
  is the loopback-bound dashboard server. Pass 2 adds no external dependency and no credential. That
  is the *architecture* half of FR-31a part 1's "may not … fetch anything"; the half that binds the
  dispatched agent is the empty tool set (D6 part 1), and neither substitutes for the other.
- **Which role.** `aid-researcher` — the agent whose remit is reading code and docs to produce
  structured analysis. `aid-architect` designs and `aid-developer` writes production code; neither
  fits a read-and-classify task.
- **Contract.** Input: for a discovery dispatch, one document's text plus the node inventory; for the
  typing dispatch, `candidates.tsv` plus the node inventory — both **inlined in the prompt, with no
  tool granted** (D6 part 1). Output: class-1 rows in D1's TSV shape
  appended to `.aid/.temp/graph/rows-class1.tsv`, and disposition rows appended to
  `.aid/.temp/graph/dispositions.tsv`. Nothing else is writable by the pass.
- **Trust boundary.** The agent's output is untrusted input to `build-relationships.sh`, which applies
  D6's four rejections and drops violations. This is the same posture the project takes elsewhere with
  agent- or frontmatter-sourced values.
- **Graceful degradation.** Covered by D6's one degradation case — every candidate is dispositioned
  `pass-2-unavailable`, the completion check passes by construction, and the artifact ships with
  class-0 rows only. The deterministic majority is the product; the reading pass is an enrichment.
- **Heartbeat and stop.** A long dispatch follows the project's sub-agent heartbeat and
  cooperative-stop protocol (`HEARTBEAT_FILE` / `HEARTBEAT_INTERVAL`, with `heartbeat_interval`
  resolved from `.aid/settings.yml`, where it is a top-level scalar). The per-document dispatch shape
  (D6 part 1) makes a stop cheap: the loop resumes at the next unread manifest row rather than
  restarting the pass.

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the
methodology, that owner is named and the item is **not** absorbed here. None blocks this feature's
own implementation.

> **Standing rule for every item below whose owner is already gated A+** (STATE.md Q18 ruling 3, *"if
> there is a defect, the A+ is false"*): a gate grade is a live claim about the artifact, not a
> milestone banked and then defended. Scheduling such an item therefore **reopens that feature's SPEC
> and re-gates it** — the grade does not survive the change, and the cost of re-gating is never an
> argument against making it. feature-001, feature-003 and feature-004 are gated as of 2026-07-29, so
> Open Items 2, 3, 4, 5, 8, 13 and 16 each carry the consequence explicitly below. Items owned by an
> ungated feature carry no such consequence and say so.

1. **FR-30's carrier bullet names `contracts:`, which cannot carry an edge.** Its "frontmatter
   cross-references (`see_also`, `contracts`)" pairs a real reference field with a field whose
   entries are structural cardinality assertions rather than references to a node
   (`frontmatter-schema.md`, "`contracts:` (optional, list)"). `see_also` is harvested (D4 kind 8);
   `contracts:` is not and cannot be. A wording amendment would remove the mismatch; nothing depends
   on it. *(The previous revision's Open Item 1 on the `Evidence:` carrier is **closed** — FR-30 was
   corrected on 2026-07-28 and the harvest kind is struck.)* **Owner: whoever performs the next
   REQUIREMENTS.md amendment pass.**
2. **`mentions` declares no `source-artifact->` token, so a coarse path reference between two source
   artifacts cannot be typed deterministically.** D3 therefore leaves feature-004's `path-reference`
   observation unmapped and routes it to Pass 2 as an edge candidate, which is FR-31a part 3's first
   kind of work but shifts volume from the script majority to the reading pass. Adding
   `source-artifact->source-artifact` and `source-artifact->document` to `mentions`'s
   `endpoint_kinds` would let Pass 1b type it as `derived`. The judgment is feature-001's: `mentions`
   is currently a KB-side relation by its token set, and widening it is a vocabulary decision, not a
   producer decision. **Owner: feature-001 — gated A+; scheduling this reopens and re-gates that
   SPEC.**
3. **feature-004's `dependency` observation kind conflates six manifest semantics, and two relations
   lose their producer as a result.** One observation kind can carry only one relation, so
   `generated-files.txt`'s output ↔ build-command edge — which is `generated-by` by its definition —
   types as `depends-on`, and the `.aid/settings.yml` `knowledge.doc_set` edge targets a `document`
   that `depends-on` does not declare, so it becomes a Pass-2 candidate. Splitting the kind into
   `dependency`, `generation` and `enrolment` would give `generated-by` and `has-member` producers
   and move six tokens out of D8's unreachable list. Nothing here blocks: the shipped behaviour is
   correct, only coarser. **Owner: feature-004 — gated A+; scheduling this reopens and re-gates that
   SPEC.** Q18 ruling 3 names this item specifically as the case that tests the rule.
4. **Does `Provenance` track the statement or the target resolution?** D5 keys it on the statement, and
   feature-001 D6c keys `illustrated-by` on the resolution. The two are reconciled by scoping D6c to
   the relation it was stated for, and the alternative — generalising it — is recorded as untenable
   at D5, because it would leave `cites`, `cites-as-evidence`, `defines`, `documents` and
   `cross-references` with no producer for any basename-resolved target, which is the common case in
   an AID KB. Confirming the general rule, or widening those five `passes` sets, is the vocabulary's
   call. Until it is confirmed, the exception is not left to an implementer's reading: **AC-S8** binds
   the basename-resolved `documents` row to `declared` and a test asserts it, so the two provenance
   semantics are distinguished by a criterion rather than by precedent. **Owner: feature-001 — gated
   A+; scheduling this reopens and re-gates that SPEC.**
5. **V14 must tolerate a non-enum label in an extra coverage row's first cell.** D7 emits four
   additional rows (`fact-unanchored`, `section-empty-slug`, `concept-qualified`,
   `concept-merge-candidates`) using the extension mechanism feature-003 D7a explicitly provides. The
   first two are **required** by feature-003's own D2a-1 and D2a-2 and have nowhere else to go; the
   fourth carries D2f's count, which Q18 ruling 2 requires to be durable. This is the same reliance
   feature-004 raised as its Open Item 6a, with the same fallback: if declined, the four numbers move
   into the fixed rows' `note` cells, costing presentation and not content. **Owner: feature-003 —
   gated A+; scheduling this reopens and re-gates that SPEC.**
6. **`**Aliases:**` is not an AID authoring convention, so it drives no mention edge.** feature-003
   D2a-3 records that this repository's glossary carries the marker while the shipped template does
   not define it, and leaves its use to this feature; D2d declines it on FR-8a grounds. If alias-driven
   mentions are wanted, the marker must first be added to the shipped glossary template with a stated
   value format — at which point D2d's matchable surface widens by one line and nothing else moves.
   **Owner: feature-013** (KB authoring-convention and template content), **with the work owner** to
   decide whether the capability is wanted.
7. **The false-merge candidate set may also want a view-layer surface.** *(Rewritten — the detection
   obligation this item used to carry is discharged, not routed.)* Q18 ruling 2 rejected recording the
   D2d case-2 merge as an accepted blind spot, so **D2f specifies the detector here** with a decidable
   predicate, an advisory report and **AC-S7**; a count reaches the coverage notes on every run. What
   is left is presentation: feature-007's Coverage/Impact lens reads the graph the predicate is
   computed over, so it could render the candidate set beside the concept node rather than leaving it
   to stdout and a scratch TSV. This is an enhancement to an already-satisfied requirement, not a
   gap. **Owner: feature-007** (ungated — no reopen consequence), **with feature-006** if a candidate
   should additionally appear as a `[LOW]` finding rather than only as a lens signal.
8. **Two relations describe things only a reader can see, and their `passes` excludes `inferred`.**
   D8 marks `quotes` and `lockstep-with` `unreachable` for that reason: verbatim reproduction and a
   mutual maintenance invariant are both stated in prose, which is Pass 2's territory, but neither
   entry admits an `inferred` pass. Adding `inferred` to both would move them from `unreachable` to
   `inferred-only` and put them in Pass 2's discovery scope at no cost to the deterministic majority.
   **Owner: feature-001 — gated A+; scheduling this reopens and re-gates that SPEC.**
9. **feature-006's coverage-bearing selection must avoid `documentation`.** feature-001 Open Item 8
   asks feature-006 to choose among the `documentation`, `evidence` and `provenance` categories. D8
   narrows the choice with a fact rather than an opinion: `documents` is the only pair in
   `documentation`'s producing half whose tokens this map produces, and it produces just two of its
   six; `evidence` (`cites`, `cites-as-evidence`) and `provenance` (`derived-from`, via Pass 2) carry
   the KB-claim-to-source edges the Coverage lens keys on. Selecting `documentation` alone would give
   the lens document-level `sources:` edges and nothing finer. **Owner: feature-006.**
10. **The Pass-2 disposition count has no durable home, deliberately.** D6 keeps it out of the coverage
    notes because feature-003 D7a places that section inside FR-32's byte-identity guarantee. It lives
    in `.aid/.temp/graph/dispositions.tsv`, which the shared scratch lifecycle deletes at skill DONE.
    If the owner wants it durable, feature-003 D8 already establishes the pattern: a generator-written
    frontmatter scalar sitting **outside** the byte-identity boundary, alongside `graph_inputs_digest`
    and `graph_generated_at`. **Owner: feature-010**, which owns those scalars and the run summary.
11. **`ext:` coverage on this project is zero** until `external-sources.md` gains registered entries in
    the form feature-003 D2c defines, and that file's writer is `/aid-discover`'s ELICIT state, not
    this skill (FR-10). Q4's fixture decision already covers acceptance; what is open is whether the
    owner wants real entries registered so the dogfood graph exercises the `ext:` path at all.
    **Owner: `/aid-discover` ELICIT (upstream), tracked as feature-003 Open Item 1 and D-5.** The
    tracking is a cross-reference only — resolving this changes KB *content*, not feature-003's SPEC,
    so no gated artifact is reopened.
12. **Pass-2 dispatch volume is bounded by the document count, not by the residue.** D6 part 1 makes
    the discovery half one dispatch per KB document, which is the strongest available reading of
    "reads each at most once" and is reportable up front — but it also means the pass runs a dispatch
    per document even where a document yields nothing. Batching several documents into one dispatch
    would weaken the bound from *structural* to *instructed*, which is the trade feature-010 should
    make deliberately if run time proves unacceptable. Every bound in D6 is per row, so batching
    changes no contract. **Owner: feature-010** (run orchestration; ungated — no reopen consequence).
13. **`tests` / `tested-by` has no producer *today*, and two routes would give it one.** D8 marks the
    pair `unreachable` because no carrier supplies a test's **subject**: feature-004's `convention`
    observation identifies a test file, which is the wrong half of the relation. The gate is right
    that this is a current absence rather than an impossibility, and the two routes differ in owner.
    (a) A **subject-bearing widening of `convention`** — emitting the tested artifact alongside the
    test file where a naming convention determines it — would make the pair `derived`-producible with
    one map row here. **Owner: feature-004 — gated A+; scheduling this reopens and re-gates that
    SPEC.** (b) A **`tested-components:` frontmatter field** would make it `declared`-producible, but
    it does not exist in the shipped schema, and FR-8a forbids relying on a field no template defines
    — the same ground on which D2d declines `**Aliases:**`. **Owner: feature-013** (KB
    authoring-convention and template content, ungated), **with the work owner** on whether the
    capability is wanted. Neither route blocks: the shipped graph is complete without the pair, and
    W3 reports its absence per project.
14. **The Pass-2 tool restriction must be honoured by whoever performs the dispatch.** D6 part 1 makes
    the empty tool set a contract term rather than an assumption, and this feature writes it into
    `agent-pass.md`. But the caller constructs the dispatch, so the restriction holds only if the
    runtime passes no file-read, shell or network tool to either dispatch shape. Stated as an item so
    it is scheduled rather than assumed: the read ledger cannot detect a violation after the fact, and
    a violated restriction silently demotes FR-31a part 1 from a bound to a hope. **Owner:
    feature-010** (run orchestration; ungated — no reopen consequence).
15. **Should an anchored `see_also:` entry drive a `document->section` edge?** `frontmatter-schema.md`
    makes the sibling-doc-name form a **SHOULD**, so an entry carrying a section anchor is permitted;
    kind 8 nonetheless resolves only the document part, and D8 therefore reports
    `cross-references`'s `document->section` token as unreachable **by design choice**. If anchored
    entries become a stated convention, kind 8 gains the token by adding it to one map row and
    resolving the fragment through `rel_doc_slugs` — nothing else moves. **Owner: feature-013** (the
    schema's authoring convention, ungated), **with the work owner** on whether the finer edge is
    wanted; the map row and the resolution are this feature's to add once it is.
16. **Six extra coverage rows now arrive from two files, and no SPEC states the order they appear
    in — so AC-5's byte-identity guarantee rests on unspecified assembly behaviour.** feature-003 D7a
    permits extra rows below the fixed ones and has **V14** *ignore* them, while feature-003 D7's
    AC-5 check byte-compares the **whole** `## Coverage notes` section. Nothing in between fixes their
    order, and two features now contribute them through feature-010's assembly. The full inventory,
    so whoever fixes it needs no second search:

    | Source file | Owner | `key` | Required by |
    |---|---|---|---|
    | `kb-coverage.tsv` | this feature (D7) | `fact-unanchored` | feature-003 D2a-2 |
    | `kb-coverage.tsv` | this feature (D7) | `section-empty-slug` | feature-003 D2a-1 |
    | `kb-coverage.tsv` | this feature (D7) | `concept-qualified` | this feature |
    | `kb-coverage.tsv` | this feature (D7) | `concept-merge-candidates` | Q18 ruling 2 (D2f) |
    | `coverage.tsv` | feature-004 (its D7) | `image-external` | feature-004 |
    | `coverage.tsv` | feature-004 (its D7) | `source-artifact-dropped` | feature-004 |

    Each row's *content* is deterministic and each contributing file is emitted in a fixed order, so
    the gap is strictly the **cross-file** rule. Two owners, and the split matters: **feature-003**
    owns the ordering contract, because the extra-row block is part of the section shape its D7a
    defines and its AC-5 comparison covers — **gated A+; scheduling this reopens and re-gates that
    SPEC**, which the work owner has already ruled for this defect under Q18 ruling 3 (*"if there is
    a defect, the A+ is false"*), the reasoning being that a section contract whose own byte-identity
    guarantee is unachievable as specified is a defect in that contract rather than in its consumers.
    **feature-010** owns assembly and must implement whatever order feature-003 states (ungated — no
    reopen consequence). **This feature deliberately specifies neither.** Choosing an order here —
    contributor-major, key-lexicographic, or any other — would bind feature-003's section contract
    from outside it and leave two SPECs asserting the same rule independently, which is the divergence
    the routing discipline exists to prevent. Once the order is stated, this feature changes nothing:
    its contribution is already a fixed-order file.
