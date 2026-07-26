# Authored Flow Charts

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §5 (FR-1, FR-2, FR-4), §6 (NFR-1), §8, §9 (AC-3/4) | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |
| 2026-07-25 | Review fix round 1 — CONTINUE out-degree resolved, sidecar location re-justified, three citation/precision fixes | /aid-specify |
| 2026-07-25 | Amendment — KI-008: advance-clause separator set closed, residual-text guard added, ` then `-form fixture added | /aid-specify |
| 2026-07-25 | Re-gate fixes — aid-housekeep attribution, extractor 1 line→block | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-1, FR-2, **FR-3 (the in-node derived label only)**, FR-4,
  §6 NFR-1, §8 Assumptions (structural shapes), §9 AC-3, AC-4

> **FR-3 split across features — read this before specifying.** FR-3 has two layers. Its
> **in-node short derived label** (~60 characters) is produced here, as part of the node model.
> Its **verbatim fragment + `canonical/` deep link** is feature-005, and its **click-to-open
> panel** is feature-006. Earlier revisions of these SPECs labelled 005 as "FR-3 layer 1", which
> inverted FR-3's own ordering; the split above is authoritative.
> *(Corrected at cross-reference — the FR-3 label requirement was implemented here but untraced.)*

## Description

The core derivation. This feature defines the **flow-graph model** every chart is expressed in
— nodes carrying a short derived imperative label of roughly 60 characters plus provenance
(source file and exact line range), and edges carrying an optional best-effort condition label
— together with the **shape classifier** that inspects a skill's body (never the catalog's
`repurpose` flag, which signals generator ownership only) and the **well-formedness validator**
that no chart may fail.

It implements the two extractors for skills that carry their own control flow: the `## Dispatch`
table shape, where nodes and edges come mechanically from the `State` and `Advance` columns
while branch conditions are prose scraped best-effort from parentheses, and the inline
`## State:` shape.

**Named sub-scope:** it also owns the **residual heuristic extractor**, so that a curated skill
matching neither shape still produces an approximate chart rather than nothing — FR-2 forbids a
"no flow derivable" fallback state. *(Corrected at Specify: an earlier revision named
`aid-triage` as the residual exemplar. It is not — it carries both a `## State Machine` heading
and a `## Dispatch` table, so it classifies as the Dispatch shape. The real residual population
is curated on-demand skills such as `aid-config`, the ticket skills, and the connector skills,
which use mode/step prose and `### State N — NAME` headings.)*

**Cross-feature decision this feature must settle:** how a chart reaches the page — runtime
`astro-mermaid` versus D-012's build-time pre-rendered inline SVG (§8). Feature-006 is the
feature that pays for a wrong choice, so the decision is made here but must be recorded
explicitly for that consumer.

## User Stories

- As an **AID maintainer**, I want `aid-describe`'s dispatch flow drawn as an ordered chart with
  its loops, branches and exit points so I can change one state without holding all 308 lines
  in my head.
- As an **AID maintainer**, I want the chart to be scannable at a glance, so labels are short
  interpretations rather than pasted prose.
- As a **contributor**, I want a chart for every skill I open, even a rough one, rather than an
  empty page where the parser gave up.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-3 — Chart well-formedness.** Given any generated chart, when it is validated, then it
      has at least one entry node and at least one exit node, and every edge target resolves to
      a node in the same chart (no dangling edges).
- [ ] **AC-4 (first two fixtures) — Feature coverage per structural class.** Given `aid-describe`
      (Dispatch table) and `aid-review` (inline `## State:`), when their charts are generated,
      then each contains the loop, branch, and exit the source expresses. Tested with vitest.
- [ ] Given any skill classified as an authored-flow shape, when its chart is generated, then it
      passes the AC-3 validator.
- [ ] Given a curated skill matching neither authored shape, when the residual extractor runs,
      then an approximate chart is still produced (no skill left chart-less).

---

## Technical Specification

> Grounded in: `.aid/knowledge/module-map.md` (§ Skill Structural Shapes, § Conventions),
> `architecture.md`, `pipeline-contracts.md`, `technology-stack.md`, `coding-standards.md`
> (§ JavaScript / Node Conventions), `test-landscape.md`, `authoring-conventions.md`,
> `decisions.md` **D18**, and direct reading of `canonical/skills/*`,
> `canonical/aid/templates/state-machine-chaining.md`, `canonical/aid/templates/shortcut-engine.md`,
> `site/astro.config.mjs`, `site/package.json`, `site/scripts/gen-reference.mjs`,
> `site/src/content/docs/concepts/methodology.md`, and
> `site/node_modules/astro-mermaid/astro-mermaid-integration.js` (2.0.2).
>
> **Decision-label note.** REQUIREMENTS.md §8 and `.aid/knowledge/STATE.md` (line 100) call the
> Mermaid-runtime-removal decision **D-012**. The KB's `decisions.md` numbers that same decision
> **D18** ("KB forbids diagrams; the HTML summary embraces them", `decisions.md` 322–334); there is
> no `D-012` heading in `decisions.md`. This SPEC writes **D18 (= "D-012")** for both.

This feature owns three contracts that features 004, 005 and 006 are specified against — the
**flow-graph model** (§ Data Model), the **rendering substrate** (§ UI Specs), and the **shape
classifier** (§ State Machines) — plus the two authored-flow extractors, the residual heuristic
extractor, and the reusable well-formedness validator.

### Data Model

**No persisted schema and no database.** Everything here is an in-memory build-time structure
plus two deterministic on-disk build artifacts (a fenced `mermaid` block inside the page body,
and a per-skill JSON sidecar). `.aid/knowledge/` has no `schemas.md`; the closest existing
precedent is `site/scripts/.reference-manifest.json`, a plain JSON build record written by
`gen-reference.mjs` (`gen-reference.mjs` 692–703), and this feature follows it.

#### `FlowChart`

| Field | Type | Notes |
|---|---|---|
| `skill` | string | Directory name under `canonical/skills/`, e.g. `aid-describe`. |
| `shape` | enum | Classifier output: `dispatch-table` \| `inline-states` \| `sibling-doorway` \| `engine-doorway` \| `residual`. |
| `extractor` | string | Which extractor produced this chart (audit + test assertion target). |
| `confidence` | enum | `derived` (a declared state machine was parsed) \| `approximate` (heuristics). Residual charts are always `approximate`. FR-2 / NFR-3. |
| `title` | string | Chart caption, `"<skill> — state flow"`. |
| `nodes` | `FlowNode[]` | Ordered by `order`, ascending, no gaps. |
| `edges` | `FlowEdge[]` | Emission order = `(from.order, to.order, condition)`. |
| `entries` | `string[]` | Node ids with in-degree 0; see the entry rule below. **AC-3 authority.** |
| `exits` | `string[]` | Node ids that terminate the run. **AC-3 authority.** |
| `sources` | `string[]` | Every repo-root-relative file read to build this chart, ASCII-sorted. Feeds the manifest and the drift guard. |
| `warnings` | `string[]` | Best-effort losses (unresolvable advance target, missing purpose line, …). Logged, never thrown — FR-2. |

`entries` = every node with in-degree 0; **plus**, for any weakly-connected component that has no
in-degree-0 node (a pure cycle), that component's lowest-`order` node. This makes `entries`
non-empty by construction and makes the reachability check (V6 below) always satisfiable.

`exits` = every node whose advance is `HALT`, `PAUSE-FOR-USER-ACTION`, `PAUSE-FOR-USER-DECISION`,
absent, or resolves only to an out-of-chart handoff. **Fallback:** if that set is empty (a chart
whose every state advances into another state), the highest-`order` node is designated an exit and
a `warnings` entry is recorded. Like the `entries` rule, this makes AC-3 satisfiable by
construction rather than by a repair pass — the validator can then treat an empty `exits` as the
hard failure it should be.

#### `FlowNode`

| Field | Type | Notes |
|---|---|---|
| `id` | string | `^[A-Za-z][A-Za-z0-9_]{0,31}$`. Assigned `n1…nN` by first appearance in source order. Mermaid-safe **and** DOM-id-safe — feature-006 keys on it (§ UI Specs H2). |
| `order` | integer | 1-based position in source order. FR-4 "ordered steps". |
| `name` | string | The state's own name, verbatim and uppercase-preserving (`CONTINUE`, `PRESENT-FINDINGS`). |
| `label` | string | The FR-3 / NFR-1 **short derived imperative label**, ≤ 60 Unicode code points, non-empty. Derivation below. |
| `kind` | enum | `entry` \| `step` \| `decision` \| `loop-back` \| `exit`. Rendering shape only. |
| `terminal` | object \| null | On exits: `{ advanceType, handoff }`, e.g. `{ advanceType: 'PAUSE-FOR-USER-DECISION', handoff: 'Run /aid-define {work}' }`. |
| `provenance` | `Provenance` | **Required.** The compact verbatim fragment. Feature-005 interface. |
| `detail` | `Provenance` \| null | Optional pointer to the full step definition (a `references/state-*.md` worker, or the whole `## State:` section). Excerpt omitted. Feature-005 interface. |

`kind` is single-valued with precedence `exit > entry > decision > loop-back > step`. It drives the
mermaid node shape and **is not** what AC-3 is checked against — the validator reads `entries` /
`exits`, so a node that is both an entry and an exit still satisfies AC-3.

- `decision` — two or more outgoing edges **of kind `branch`**. Counting `branch` edges rather than
  raw out-degree is what keeps a node that merely loops (one `sequence` edge plus a rule-5
  self-edge, e.g. `aid-review`'s `VERIFY`) from being drawn as a rhombus it is not.
- `loop-back` — source of at least one `loop-back` edge.

#### `FlowEdge`

| Field | Type | Notes |
|---|---|---|
| `from` | string | Node id. MUST resolve in-chart (V4). |
| `to` | string | Node id. MUST resolve in-chart (V4). |
| `kind` | enum | `sequence` \| `branch` \| `loop-back` \| `re-entry`. |
| `condition` | string \| null | **Best-effort, not a parse.** Verbatim prose lifted from the `Advance` cell/line, never invented. Null when the advance is unconditional. Capped at 80 code points by the **same** truncator the label uses (word boundary ≤ 79, else a hard cut at 79, then `…`), so the two are not independently reinvented. |
| `advanceType` | enum | `CHAIN` \| `HALT` \| `PAUSE-FOR-USER-ACTION` \| `PAUSE-FOR-USER-DECISION` \| `UNSPECIFIED`. The closed vocabulary of `canonical/aid/templates/state-machine-chaining.md` § "The four advance types" — no fifth value is invented. |
| `provenance` | `Provenance` | The exact line the edge was read from. |

REQUIREMENTS §8 is explicit that branch conditions are prose inside parentheses, so `condition` is
recorded verbatim and never normalized into a predicate.

#### `Provenance` — the feature-005 interface

```js
{
  file:      'canonical/skills/aid-describe/SKILL.md', // repo-root-relative, POSIX separators, always under canonical/
  startLine: 275,                                       // 1-based, inclusive
  endLine:   275,                                       // 1-based, inclusive, >= startLine
  sourceKind:'skill',                                   // 'skill' | 'worker' | 'engine' | 'sibling'
  excerpt:   '| CONTINUE | `references/state-continue.md` | …' // verbatim LF-joined slice of [startLine,endLine]
}
```

This is an **interface, not an internal detail**. Feature-005 owns deep-link construction (the
`BLOB` base already defined at `gen-reference.mjs` 83) and line-range verification; its build check
is the cheap equality `excerpt === readFile(file).split('\n').slice(startLine-1, endLine).join('\n')`,
which is exactly how AC-5's "a bad line range is caught by the build" is made possible. `excerpt`
is omitted on `detail` (ranges there can be whole worker files).

Provenance is always a **small** fragment: one table row for a Dispatch state, the heading plus the
lead paragraph for an inline `## State:` section. The full section/worker range goes in `detail`, so
NFR-1's "scannable" and NFR-2's "nothing lost" are served by different fields.

#### Label derivation (FR-3 in-node layer, NFR-1)

Deterministic, in precedence order; the first candidate that yields non-empty text wins:

1. The state section's `Purpose:` line remainder (`aid-review` 40: `Purpose: resolve the target + criteria, pick the path, allocate the work folder.`).
2. The worker doc's first prose sentence (`state-continue.md` 3: `Resume the conversational interview; …`).
3. The lead paragraph of the matching inline `## State: NAME` section, when the Dispatch row's
   `Detail` cell is `inline` (`aid-triage` 77 → `aid-triage/SKILL.md` 84).
4. The state `name`, title-cased.

A `Detail` cell is **never** itself a label candidate: it is either a path
(`references/state-continue.md`) or a pointer word (`inline (below)`), and both make useless labels.
Rejecting it explicitly is what sends `aid-triage`'s states to candidate 3 and its two
Dispatch-only states (`CLASSIFY`, `SUGGEST`, whose `Detail` is a `references/` path) to candidate 2.

Then: strip markdown emphasis, links, backticks and a leading `Purpose:`; collapse whitespace; take
the first sentence; capitalize the first letter; then apply the length cap:

- **Length is counted in Unicode code points** — `Array.from(text).length`, not `String.length` —
  because the corpus uses `—`, `·` and `…` freely. The truncator and validator rule V8 MUST use the
  same measure, and slicing goes through `Array.from` so a surrogate pair can never be split.
- ≤ 60 code points → keep unchanged.
- Otherwise, find the last whitespace boundary at index ≤ 59. If one exists, cut there, strip
  trailing whitespace and any trailing `,` `;` `:` `—` `-`, and append `…`.
- **If there is no whitespace boundary at or before index 59** — a single very long token, such as
  an unbroken state name — hard-cut at exactly 59 code points and append `…`. This character-level
  fallback is what makes the ≤ 60 bound unconditional, so no input can produce a label that fails
  V8 at build time.

The corpus already writes these lines imperatively, so no verb-form rewriting is attempted —
inventing grammar would be an interpretation on top of an interpretation (NFR-3).

#### Serialization

`<skill>.flow.json` = the `FlowChart` with fixed key order (the field order of the tables above),
`JSON.stringify(chart, null, 2)` + one trailing `\n`, LF endings. It is the single machine artifact
feature-005 (ordered fragment list) and feature-006 (click → node record) both read; neither
re-parses `canonical/`.

### Feature Flow

```
canonical/skills/<skill>/SKILL.md
        │
        ▼
  1. read + split frontmatter/body        (own minimal parser — see Layers)
  2. classifySkill()                      → { shape, evidence[] }
  3. extract<Shape>()                     → FlowChart          (this feature: dispatch-table,
        │                                                       inline-states, residual;
        │                                                       feature-004: the two doorway shapes)
        ├── reads referenced references/state-*.md workers for edge refinement + `detail`
        ▼
  4. validateChart()                      → throws on AC-3 violation
  5. renderMermaid()                      → a fenced mermaid block (flowchart TB …)
  6. serializeChart()                     → site/src/data/skill-flows/<skill>.flow.json
        │
        ▼
  7. feature-001's page generator places the fence in the detail page body slot,
     stamps "generated — do not edit", and records both artifacts in its manifest
        │
        ▼
  8. astro build → astro-mermaid remark/rehype → <pre class="mermaid"> → browser renders SVG
```

Steps 1–6 are this feature. Step 7 is feature-001's. Step 8 is the site's existing pipeline,
unchanged.

#### Determinism (NFR-4 / AC-6)

Byte-identical output on a re-run is achieved by construction:

- Skill directories read with `readdirSync(...).sort()` — the default ASCII sort
  `gen-reference.mjs` 373–376 already uses; no `localeCompare`.
- Node ids assigned `n1…nN` by first appearance in source order; never hashed, never random.
- Edge emission ordered by `(from.order, to.order, condition)`.
- Fixed JSON key order; `JSON.stringify(…, null, 2)` + trailing `\n`; LF only.
- No timestamps, no `Date`, no `Math.random`, no environment reads in any emitted string.
- The **only** randomness in the whole rendering path is `'mermaid-' + Math.random()…`
  (`astro-mermaid-integration.js` 423), which is generated **in the browser at render time** and
  never enters a build artifact. The runtime substrate therefore costs nothing against NFR-4.

#### Seam required from feature-001 — DEPENDENCY TO RECONCILE

Feature-001's SPEC has no Technical Specification yet (its `## Technical Specification` is still the
`/aid-specify` placeholder), so the following are stated as **requirements on that seam**, to be
reconciled when feature-001 is specified:

- **S1 — Verbatim body slot.** The body slot MUST emit a fenced ```` ```mermaid ```` block through
  to the rendered page unaltered. Both `.md` and `.mdx` satisfy this: `astro-mermaid` registers a
  remark plugin over `code` nodes and a rehype plugin over `pre > code.language-mermaid`
  (`astro-mermaid-integration.js` 51–82, 159–203), and both existing `.md`
  (`concepts/methodology.md`) and `.mdx` (`guides/pipeline.mdx`) pages already carry working
  mermaid blocks.
- **S2 — Sidecar location.** A stable per-skill path for `<skill>.flow.json`. Chosen:
  `site/src/data/skill-flows/<skill>.flow.json`, on two grounds that hold independently:
  1. **It must sit outside the docs content collection.** `site/src/content/docs/` is Astro's
     content-collection root, so a non-page file placed there is either parsed as content or
     breaks the collection. `gen-reference.mjs` already draws exactly this line: it writes pages
     into `src/content/docs/reference/` and its build record to `site/scripts/`, under the comment
     "Emit the manifest JSON (outside the collection root)" (`gen-reference.mjs` 692).
  2. **`site/src/data/` is the site's existing home for data modules that site components
     consume.** `site/src/data/version.ts` is imported by `site/src/components/VersionBadge.astro`
     (line 3) and `site/src/components/InstallCommand.astro` (line 4). That is precisely the
     property the sidecar needs: readable by Node at build time (feature-005's generator reads it
     off disk) **and** importable from an Astro component under `src/` (feature-006's island).
     The alternatives fail one side each — `site/public/` is fetch-only, costing feature-006 a
     network round-trip per page, and `site/scripts/` is generator-internal and not importable
     from a component.

  Feature-001 owns page-emission layout and may relocate it; features 005 and 006 must be told.
- **S3 — Manifest + drift guard.** Both the page and its sidecar are recorded in feature-001's
  manifest so AC-1's throw-on-drift guard covers the sidecars too.
- **S4 — Slug convention.** `skills/<skill-name>`, so a node id plus a slug uniquely address a node
  across the site.

### Layers & Components

New code is a **library plus its callers**, not a second page generator: feature-001 keeps sole
ownership of page emission and of the single drift guard (AC-1), and this feature exposes an
importable API that features 004, 005 and 006 all build on.

```
site/scripts/lib/flow-graph/
  model.mjs               — FlowChart/FlowNode/FlowEdge constructors, id assignment,
                            kind/entries/exits computation, serializeChart()
  source.mjs              — frontmatter split, line-addressed slicing, Provenance builder
  classify.mjs            — classifySkill()            [contract 3]
  advance.mjs             — the Advance-clause parser (shared by both extractors)
  extract-dispatch.mjs    — `## Dispatch` table shape   [this feature]
  extract-inline.mjs      — inline `## State:` shape    [this feature]
  extract-residual.mjs    — residual heuristic ladder   [this feature, named sub-scope]
  validate.mjs            — validateChart()             [AC-3, reused by feature-004]
  render-mermaid.mjs      — renderMermaid()
  index.mjs               — buildFlowChart() façade
```

Public API (signatures only — no implementation is specified here):

```js
classifySkill({ name, dir, frontmatter, body }) -> { shape, evidence: string[] }
buildFlowChart({ name, dir })                   -> FlowChart          // classify + extract + validate
validateChart(chart)                            -> { ok, errors: string[] }
renderMermaid(chart)                            -> string             // the fence body
serializeChart(chart)                           -> string             // JSON + trailing LF
```

**Ownership boundaries.**

| Concern | Owner |
|---|---|
| `model.mjs`, `validate.mjs`, `render-mermaid.mjs`, `classify.mjs`, `advance.mjs` | feature-003 |
| `extract-dispatch`, `extract-inline`, `extract-residual` | feature-003 |
| `extract-engine.mjs`, `extract-sibling.mjs` (shapes 3 + 4), doorway `{verb, artifact}` entry-node binding | feature-004, in the same directory, reusing model/validate/render unchanged |
| Ordered verbatim list, deep-link construction, line-range verification | feature-005, reading the sidecar |
| Click-to-open panel, DOM binding | feature-006, reading the sidecar + the hooks in § UI Specs |
| Page emission, frontmatter header, manifest, drift guard | feature-001 |

**Conventions followed.** `site/` is an independent module (`module-map.md` Dependency Graph:
`site/ X canonical/`), so site-local code follows its own established style —
`gen-reference.mjs`'s 2-space ESM with `node:`-scheme imports and no dependencies beyond the
site's — rather than the tab-indented `canonical/aid/scripts/**/*.mjs` house style
(`coding-standards.md` § JavaScript / Node Conventions, § Observed Inconsistencies). Like
`gen-reference.mjs` (36–68, 93–118) this library carries its **own minimal frontmatter parser**
and adds no YAML dependency. `canonical/` is read, never `profiles/*` (§7).

**Test layer.** `site/scripts/__tests__/flow-graph.test.mjs`, run by the site's existing
`npm run test` → `vitest run` (`site/package.json` 20), alongside the existing
`site/scripts/__tests__/gen-reference.test.mjs`. Three tiers:

1. **Contract tests** over frozen inline markdown fixtures written in the test file itself — these
   pin classifier precedence, the Advance-clause grammar, label truncation, id assignment and every
   validator rule. They depend on nothing outside the test, per the tracking rule that tests build
   their own fixtures.
2. **AC-4 corpus tests** over the three real fixtures — see below.
3. **Whole-corpus + idempotence tests**: every directory under `canonical/skills/` classifies into
   exactly one shape and the shape counts **sum** to the directory count (no per-shape count is
   asserted — see the no-hard-coded-counts contract); every chart passes `validateChart`;
   `serializeChart` and `renderMermaid` are equal across two runs on the same input.
4. **Unparsed-advance allow-list** — the standing guard against a repeat of KI-008. The suite
   asserts that the set of `(skill, state)` pairs emitting a W-1 residual-text warning equals a
   checked-in expected set, each entry carrying a one-line reason. A connective the separator set
   does not yet know changes that set and **fails CI**, which is what converts "an edge was
   silently dropped" into "a test went red". Because V9 already errors on the dangerous subset, the
   allow-list only ever holds benign residues, and it stays short enough to review by eye.

**AC-4 for this feature's three fixtures.** Assertions are *structural properties* plus *named
landmarks*, so prose edits inside a skill do not break the suite while a real change to its state
set does:

| Fixture | Shape | Loop | Branch | Exit |
|---|---|---|---|---|
| `aid-describe` (`SKILL.md` 269–277) | `dispatch-table` | a `loop-back` self-edge on `CONTINUE` (rule 5, from the single-target conditional advance in `references/state-continue.md` 43), and a `re-entry` edge into `Q-AND-A` from `## Targeted Interview (Loopback Re-entry)` (287–296) | `CONTINUE` has **out-degree 3**: two `branch` edges → `DESCRIBE-SEED` / `COMPLETION`, conditions lifted verbatim from the parenthesised prose in the `Advance` cell (275), **plus** the `loop-back` self-edge in the Loop column. `CONTINUE.kind === 'decision'` (two `branch` edges) | `COMPLETION` ∈ `exits`, `terminal.advanceType === 'PAUSE-FOR-USER-DECISION'`, `terminal.handoff` mentions `/aid-define` |
| `aid-review` (`SKILL.md` 38–209) | `inline-states` | a `loop-back` edge `VERIFY → REVIEW`, from the back-reference in VERIFY step 3 (159) | `PRESENT-FINDINGS` has **out-degree 2**, both `branch` → `PUBLISH` (`on approval`) / `DONE` (`otherwise`), from `**Advance:** PUBLISH on approval; otherwise DONE.` (184); `PRESENT-FINDINGS.kind === 'decision'` while `VERIFY.kind === 'loop-back'` (its one `PRESENT-FINDINGS` edge is `sequence`, so it is not a decision) | `DONE` ∈ `exits` (no `**Advance:**` line, last in the declared spine) |
| `aid-test` (`SKILL.md` 32–131) — **added for KI-008**, the ` then ` form | `inline-states` | a `loop-back` edge `VERIFY → RUN`, from the **line-wrapped** back-reference at 89–90 (`… -> loop` / `to RUN/consolidate.`) — this fixture is what pins both the block-scoped body scan and the `loops? to X` phrasing | `PRESENT` has **out-degree 2**, both `branch` → `HANDOFF` (`condition: 'optional'`) / `DONE` (`condition: null`), from `**Advance:** HANDOFF (optional) then DONE.` (102); `PRESENT.kind === 'decision'`. Asserted alongside `HANDOFF → DONE` (from HANDOFF's own advance, 111) so the skip path and the through path are distinguished | `DONE` ∈ `exits` (no advance, last in the spine at 32) |

All three fixtures additionally assert `validateChart(chart).ok === true`, `entries.length >= 1`,
`exits.length >= 1`, that every node's `provenance.excerpt` equals the live slice of its cited
`canonical/` file, and that the chart emits **no** W-1 residual-text warning. The out-degree
assertions are written over the edge kinds, not just the count — for `CONTINUE`,
`edges.filter(e => e.from === CONTINUE)` has length 3 with kinds `{branch, branch, loop-back}`, and
for `aid-test`'s `PRESENT`, length 2 with kinds `{branch, branch}` and target set
`{HANDOFF, DONE}` — so neither a future change to rule 5 nor a regression of KI-008 can pass by
accident.

**Known-issue registrations.** Issues found while reading the code this feature touches are
recorded in `.aid/works/work-001-skill-explorer/known-issues.md`. KI-001 (the dropped
`themeVariables`) and KI-002 (stale KB structural-shape facts) shape decisions below; **KI-008**
(the advance-clause separator defect found by feature-004) is fixed by parser rules 6 and 10 and
validator rule V9 above.

### State Machines

*Activated because this feature's entire job is to model **other skills'** state machines: the
extraction semantics, the classifier and the validator are the substance of the feature, not an
implementation detail of some other section.*

#### Source vocabulary

The corpus declares transitions with the closed four-value vocabulary of
`canonical/aid/templates/state-machine-chaining.md` § "The four advance types" — `CHAIN`,
`PAUSE-FOR-USER-ACTION`, `PAUSE-FOR-USER-DECISION`, `HALT` — and that doc states the list is
exhaustive ("Do not invent a third pattern"). `FlowEdge.advanceType` mirrors it exactly, with
`UNSPECIFIED` for an advance whose text names no type (common in `aid-review`, e.g. `**Advance:**
REVIEW.`). Untyped `Stop here.` prose maps to `PAUSE-FOR-USER-ACTION` per that doc's § 2 form.

#### Evidence precedence

1. **Declared spine** — the frontmatter or body `State machine:` line (`aid-describe/SKILL.md` 11;
   `aid-review/SKILL.md` 32–34) or a literal `## State Machine` ASCII map (`aid-triage/SKILL.md`
   58–66). Authoritative for **membership and ordering**, never for edges.
2. **Per-state advance** — the Dispatch row's `Advance` cell, or the state section's
   `**Advance:**` block, or the worker doc's `**Advance:**` block. Authoritative for **edges**.
3. **Body back-references** — used only for `loop-back` / `re-entry` edges (below).

Where the spine and the extracted node set disagree, the extracted set wins and the difference is
pushed to `chart.warnings` — never a throw (FR-2).

#### The Advance-clause parser (`advance.mjs`)

Applied identically to a Dispatch `Advance` cell, an inline `**Advance:**` block, and a worker's
`**Advance:**` block.

**Input is a block, not a line.** An `**Advance:**` runs from its marker to the first blank line,
`---` rule, or heading. Reading only the marker's own line loses whatever wrapped, and that is not
hypothetical: 19 advances in `canonical/skills/**/*.md` wrap, and at least one hides an entire
clause on its continuation line — `aid-create-ticket/SKILL.md` 200–201 ends line 200 mid-clause and
carries a third branch, `` `[3] Cancel` → halt ``, on line 201. The same block rule applies to the
body scans in rules 7 and 8: `aid-test/SKILL.md` 89–90 wraps its loop phrase across the line break
(`… -> loop` / `to RUN/consolidate.`), so a line-anchored scan would miss that skill's only loop.

**Separator set (measured, then validated).** A literal separator list is what let KI-008 through,
so the design is two-phase rather than a growing list:

*Phase 1 — propose.* Cut the block at every occurrence of a member of the measured separator set
below, outside backticks:

| Separator | Where it was measured |
|---|---|
| `;` | 14 `**Advance:**` blocks, e.g. `PUBLISH on approval; else DONE`; also Dispatch cells (`aid-execute`'s 4-outcome cell) |
| ` / ` (spaced slash) | Dispatch cells only — `aid-describe/SKILL.md` 275, `aid-summarize`, `aid-housekeep` |
| `/` (unspaced, between two state-like tokens) | Dispatch cells — `SCOPE/ANALYZE`, `(CONFIRM/SCOPE)` in `aid-update-kb` |
| ` then ` | **5 blocks, all `HANDOFF (optional) then DONE.`** — `aid-test` 102, `aid-design` 91, `aid-prototype` 91, `aid-report` 103, `aid-research` 130. **This is KI-008.** |
| ` or ` | `aid-execute`'s `… continue to [State: REVIEW] or [State: DONE] …`; and the parenthetical form below |
| `(or X …)` parenthetical alternative | `aid-update-kb` `CHAIN -> CONFIRM (or HALT if the Scope Plan is empty …)` and `CHAIN -> SCOPE (or PAUSE-FOR-USER-ACTION …)`; `aid-housekeep` 222 `CHAIN → KB-DELTA (or CLEANUP if Mode=cleanup-only)` |
| sentence boundary `. ` | 3 real cases — `` `[1] File it` → State: FILE …. `[2] Edit` → … `` (`aid-create-ticket` 200), `If user approved: … . If user rejected: … . If user said "changes needed": …` (`aid-summarize`), `… (continue inline). For DONE-IDEMPOTENT branch: **HALT**.` |

*Phase 2 — validate, then accept or reject.* A proposed cut is **accepted only if every resulting
clause resolves** to a declared state or to a terminal keyword (`halt`, `HALT`, `Stop here`, a
`PAUSE-FOR-USER-*` keyword). Otherwise the cut is discarded and the text stays joined.

Phase 2 is what makes the aggressive separators safe, and it is calibrated against the measured
false-positive cases: ` or ` appears inside conditions (`when all sections are Complete or N/A`)
and prose (`add information or re-validate`, `(Discovery loopback, requirement clarification, or
upstream phase fix)`); `. ` precedes commentary far more often than a clause (`Both continue
inline.`, `This is the terminal state.`) — 13 of the 16 measured `. `-bearing blocks are commentary.
In every one of those the trailing fragment resolves to nothing, so the cut is rejected and no
phantom edge is invented.

**Measured absent.** ` and then `, `, then `, and multi-hop state chains (`A → B → C`) do not occur
in any advance in the corpus. The only multi-hop arrows are `<condition> -> KEYWORD -> TARGET`
(`` `[1] Approved` -> CHAIN -> DONE ``, `aid-update-kb`), where the middle token is an advance-type
keyword rather than a state; step 2 therefore strips advance-type keywords **anywhere** in the
clause, not only at its head. These forms are recorded as absent so a future reader knows the set
was checked rather than guessed.

1. Split the block into clauses per the two phases above.
2. Per clause: strip advance-type keywords **wherever they appear**, not only at the head (the
   measured `<condition> -> CHAIN -> TARGET` form puts one in the middle); strip `→`/`->`; strip a
   `[State: X]` wrapper to `X`; the first token matching a declared state name (case-insensitive)
   is the target. Matching is **whole-token and exact, never substring**, and a hyphenated state
   name is one token — so `PRESENT-FINDINGS`, `Q-AND-A`, `DESCRIBE-SEED` and `APPROVAL-HALT`
   resolve, while `DONE-IDEMPOTENT` (`aid-summarize`'s `For DONE-IDEMPOTENT branch: **HALT**`) is
   *not* a match for `DONE`. A token that is itself a rejected split candidate resolves on its head —
   `RUN/consolidate` (`aid-test` 89–90) yields `RUN`, because `consolidate` resolves to nothing and
   phase 2 therefore rejected that cut. If a
   name is declared more than once in the same skill, the **lowest-`order` node wins** and a
   `warnings` entry records the collision — name resolution must be total and deterministic, since
   ids are positional (`n1…nN`) while advance clauses address states by name.
3. Remaining text — a trailing parenthesised group, or trailing prose such as `on approval` /
   `otherwise` / `when all sections are Complete or N/A` — becomes `condition`, verbatim, ≤ 80
   **code points**, measured and truncated by the shared truncator exactly as the `condition` row
   of the FlowEdge schema specifies (`Array.from`, word boundary ≤ 79, else a hard cut at 79, then
   `…`) — **not** `String.length`, which would diverge on a supplementary-plane character. Never
   normalized into a predicate (REQUIREMENTS §8).
4. A clause whose target resolves to **no declared state** (`Run /aid-define {work}`, `halt`) is
   **not an edge**. It becomes the node's `terminal = { advanceType, handoff }` and the node joins
   `exits`. This is what keeps AC-3's "every edge target resolves in-chart" true *by construction*
   rather than by a later repair.
5. **Single-target conditional ⇒ self-loop.** A clause with exactly one target and a `when <guard>`
   condition implies the state stays put while the guard is unmet, so a `loop-back` self-edge is
   emitted with `condition: 'otherwise'`. This is what produces `aid-describe`'s loop from
   `state-continue.md` 43.

   **The rule fires unconditionally.** It is *not* suppressed by the presence of other outgoing
   edges, and in particular not by a dispatch row that already branches. The only guard is
   deterministic and local: at most one rule-5 self-edge per node, and none at all if the node's
   own advance clauses already name that node as a target. Nothing else can duplicate it, because
   V5 forbids a repeated `(from, to, condition)` triple.

   **Why unconditional, when the dispatch row already branches.** In `aid-describe` the worker's
   guard — "all sections are Complete or N/A" (`state-continue.md` 43) — and the dispatch row's two
   conditions — "greenfield: …" / "brownfield or seed already complete"
   (`aid-describe/SKILL.md` 275) — partition **different** things. The guard is about interview
   completeness; the row's conditions choose which path to take *once the interview is complete*.
   The negation of the guard (the interview still running) is therefore represented by no other
   edge, and suppressing rule 5 here would silently drop the very loop FR-4 requires the chart to
   show. `CONTINUE`'s out-degree is consequently **3**: two `branch` edges plus one `loop-back`
   self-edge.
6. **`X then Y` — the optional side-trip (KI-008).** ` then ` is sequential prose, so its two
   clauses are *not* symmetric alternatives and the reading depends on whether `X` is optional:

   - **`X` carries an optionality marker** — `(optional)`, a bare `optional`, a trailing `?`, or an
     `if <cond>` qualifier. `X` may be skipped, so both `X` and `Y` are reachable from the current
     node and **two `branch` edges** are emitted: `→ X` with the marker text as its `condition`
     (verbatim, so `optional` — never invented), and `→ Y` with `condition: null`, the skip path.
     The `X → Y` edge is *not* emitted here; it belongs to `X`'s own advance, and in every measured
     instance `X` already declares it (`aid-test/SKILL.md` 111, `**Advance:** DONE.`).
   - **`X` carries no optionality marker.** `X then Y` then means "go to `X`, which goes on to
     `Y`" — a single `sequence` edge `→ X`, plus a `warnings` entry recording that the `then Y`
     tail was read as `X`'s onward flow rather than as an edge from this node. Measured: this case
     does not occur in the corpus today, so a warning is the honest default rather than an
     invented edge.

   All five measured instances are the first form. Worked, for `aid-test/SKILL.md` 102
   (`**Advance:** HANDOFF (optional) then DONE.`): `PRESENT → HANDOFF` (`branch`,
   `condition: 'optional'`) and `PRESENT → DONE` (`branch`, `condition: null`), both
   `advanceType: 'UNSPECIFIED'` since the block names no keyword. Two `branch` edges means
   **`PRESENT.kind === 'decision'`** falls straight out of the kind rule — it is not a special
   case. The skill's own declared spine corroborates the optional reading independently:
   `aid-test/SKILL.md` 32 writes `… PRESENT [human] -> HANDOFF? -> DONE`, and that `?` is
   registered as an optionality marker in the spine parser for exactly this reason.
7. **Back-reference ⇒ loop-back.** Inside a state's own body, an explicit return phrasing naming a
   state that appears **earlier** in the spine emits a `loop-back` edge. The measured phrasing set
   is `loops? back to X` — `aid-review` 159, `aid-research` 113 (`INVESTIGATE`), `aid-summarize`
   100 and 104 (`VALIDATE`), `aid-update-kb` 74 (`SCOPE`), `state-review.md` 225 (`APPLY`) — plus
   `loops? to X` (`aid-test` 89–90) and `→ [State: X]`. Scanned per the block rule above, so a
   wrapped phrase still matches.

   The same phrasing also occurs pointing at **`Step N` / `PD-2` identifiers rather than states**
   (`aid-config` 120 "loop back to Step 4", `state-execute.md` 311, `state-describe-seed.md` 488).
   Those resolve to no declared state and so emit nothing, which is correct: a step inside a state
   is not a chart node. They are listed here so a later reader does not mistake them for missed
   loops — and they are silent under V9 for the same reason.

   **Kind is decided by position, not by phrasing.** Any edge whose target sits earlier in the
   declared spine than its source is kind `loop-back`, whichever rule produced it. That keeps the
   phrasing list from being load-bearing: a phrasing this set misses costs a *missing* edge, which
   the rule-10 guard reports, rather than a *mis-kinded* one.
8. **Re-entry.** A heading whose text contains `Loopback` or `Re-entry` and whose body names a
   declared state emits a single `re-entry` edge into that state
   (`aid-describe/SKILL.md` 287–296 → `Q-AND-A`). Rendered dotted; never counted as a branch.
   Rule 8 takes precedence over rule 7: an explicitly-headed re-entry is `re-entry`, not
   `loop-back`, even though it also points backwards.
9. **Pause-resume targets are metadata, not edges.** A `PAUSE-FOR-USER-*` clause whose prose names
   the state the user resumes into (`Re-run /aid-specify after the blocker clears to continue to
   [State: CONTINUE]`) records that state in `terminal.handoff` and emits **no** edge — the
   transition does not happen within a run. This populates an existing field; the schema is
   unchanged.
10. **Residual-text guard — the anti-silence rule.** KI-008's real damage was silence: an
    unrecognised connective dropped an edge while every validator rule still passed. After clause
    extraction, subtract the accepted clauses' spans from the block and inspect what is left.

    - **W-1 (warning), always.** Residue that is not pure commentary produces a `warnings` entry
      carrying the skill, the state, the residue text, and the `file:line` — surfaced in the build
      log with a run-level count, never a throw (FR-2). **"Pure commentary" is testable, not a
      judgement call:** residue containing no declared-state token, no advance-type keyword and no
      `[State: …]` reference. Everything else warns.
    - **V9 (error), narrowly.** Residue containing a reference to a **declared state of this
      chart** that is neither already an edge target from this node nor captured in
      `terminal.handoff` is a validator error. That is the precise fingerprint of a dropped edge,
      and it is the rule that would have caught KI-008 at build time: `DONE` would have sat
      unconsumed in `PRESENT`'s residue.

    V9 is deliberately narrow, because a noisy guard is an ignored guard. Checked against every
    measured residue in the corpus, it stays silent on all of them: commentary carries no state
    token (`Both continue inline.`, `This is the terminal state.`); `Step E3` / `Step 1` are not
    declared states of the charts that mention them; `/aid-define` is a skill, not a state;
    `CONTINUE emits the D1 opener …` (`state-first-run.md`) names a state that is *already* that
    node's edge target; and the two aid-specify pause-resume targets land in `terminal.handoff` via
    rule 9. Post-fix, the five ` then ` blocks leave no residue at all.

#### Contract 3 — the shape classifier

Classification is **by inspection of the body only**. The classifier MUST NOT read
`canonical/aid/templates/shortcut-catalog.yml` at all, and specifically not its `repurpose` flag:
that flag marks rows `build-shortcut-skills.py` must never overwrite, and it is carried by both
`aid-review` (221 lines, a full inline state machine) and `aid-test-security` (25 lines, pure
delegation) — `module-map.md` § Skill Structural Shapes, REQUIREMENTS §8.

Discriminators, in strict precedence order; the **first** match wins:

| # | Shape | Discriminator |
|---|---|---|
| D1 | `dispatch-table` | A heading (level ≥ 2) whose text is exactly `Dispatch` or `State Machine`, followed before the next heading by a GFM table whose header row carries both a `State` and an `Advance` column. |
| D2 | `inline-states` | Two or more headings matching `^##\s+State:\s+\S`. |
| D3 | `sibling-doorway` | The body declares it carries no logic of its own (case-insensitive `no logic of its own`) **and** references exactly one other skill's `canonical/skills/<name>/SKILL.md`. Captures `delegatesTo`. |
| D4 | `engine-doorway` | The `GENERATED by … build-shortcut-skills.py` HTML comment, **or** a body reference to `canonical/aid/templates/shortcut-engine.md`. |
| D5 | `residual` | None of the above. |

Rationale for the order: a skill's **own** declared flow always beats a delegation marker, and a
Dispatch table beats partial inline sections because it is the more machine-readable of the two.
Both facts are load-bearing on real files — `aid-triage` carries a `## State Machine` heading *and*
a Dispatch table *and* two inline `## State:` sections (58, 73–81, 84, 109), and it classifies
`dispatch-table`. `shortcut-engine.md` likewise carries both a `## State Machine` table (85–95) and
inline `## State:` sections, which is why D1's table form accepts the `State Machine` heading text
too — that is what makes the same extractor reusable by feature-004.

**No count may be hard-coded, anywhere — including in this SPEC.** The per-shape population is an
*output* of this classifier. The generator writes `shapeCounts` into feature-001's manifest, any
page prose that states a number interpolates it from that object, and the corpus test asserts only
that the counts **sum** to the on-disk directory count.

No per-shape figures are quoted here on purpose. Two independent scans of the corpus during
specification and review agreed on the `inline-states` population but differed on the
doorway/residual split, because that split moves with fine details of D3 and D4 — exactly the
fragility REQUIREMENTS §8 anticipated when it named the classifier the only authority. Any figure
written into a document is stale the moment a discriminator is tuned or a skill is edited; the
manifest is the place to read one. See KI-002 for the KB figures this supersedes.

#### Extractor 1 — `## Dispatch` table (`extract-dispatch.mjs`)

1. Locate the D1 table. Each row is one node, in row order; `State` cell → `name`;
   `provenance` = that single row line in `SKILL.md`, `sourceKind: 'skill'`.
2. When the `Detail` cell is a path to `references/state-*.md`, read that worker: its first prose
   sentence supplies the label candidate, its whole file range becomes `detail`
   (`sourceKind: 'worker'`), and its `**Advance:**` **block** refines the row's `Advance` (the worker
   is more precise about conditions; the table remains the membership authority). When the cell
   instead says `inline`, the matching `## State: NAME` section in the same `SKILL.md` plays the
   worker's role — this is `aid-triage`'s mixed shape (`aid-triage/SKILL.md` 77–80, 84, 109), and it
   is why extractor 2's section reader is a shared helper rather than private to that extractor.
3. Run the Advance-clause parser on the row cell, then on the worker **advance block**, merging by
   `(from, to)` with worker conditions winning.
4. A worker naming a state absent from the table produces a `warnings` entry and **no** edge — the
   no-dangling invariant is preserved without a repair pass.

Nodes and edges come mechanically from the `State` and `Advance` columns exactly as REQUIREMENTS §8
describes; only the condition labels are best-effort.

#### Extractor 2 — inline `## State:` (`extract-inline.mjs`)

1. Each `^##\s+State:\s+(NAME)` heading is a node, in document order. Trailing parenthetical gloss
   in the heading (`## State: VERIFY  (who reviews the reviewer)`) is stripped from `name` and kept
   as a label candidate.
2. `provenance` = the heading line through the end of its lead paragraph (`sourceKind: 'skill'`);
   `detail` = the full section range, heading line to the line before the next `## ` heading or
   `---` rule.
3. Edges from the section's `**Advance:**` block via the shared parser, plus rules 7 and 8
   (back-reference and re-entry).
4. A state with no `**Advance:**` line and no outgoing back-reference is an exit
   (`advanceType: 'UNSPECIFIED'`) — this is how `aid-review`'s `DONE` terminates.

#### Extractor 3 — the residual heuristic (`extract-residual.mjs`) — named sub-scope

FR-2 forbids a "no flow derivable" fallback, so this extractor always emits a chart. Ladder; the
first rung producing ≥ 2 nodes wins, and every chart it emits is stamped
`confidence: 'approximate'`:

| Rung | Signal | Nodes / edges |
|---|---|---|
| R1 | An ASCII state map — a fenced or indented block of `->`/`→`-separated bracketed tokens — or a `State machine:` line with `->`-separated tokens. The canonical example of the *form* is `aid-triage/SKILL.md` 65, which reaches this parser as a corroborating spine rather than as a residual skill (see OQ-2). | Tokens in order; sequence edges between consecutive tokens; bracketed/parenthesised suffixes become conditions. |
| R2 | `^###\s+State\s+\d+\s*[—-]\s*(NAME)` headings — the three ticket skills use exactly this form (`aid-create-ticket/SKILL.md` 73–222). | Headings in order; sequence edges consecutive. |
| R3 | `^###\s+Step\s+\d+` headings (`aid-config`, `aid-query-kb`, `aid-set-connector`, `aid-unset-connector`). A `## Mode N` ancestor heading starts a separate lane, each with its own entry — this is exactly `aid-config`'s two-mode shape (`aid-config/SKILL.md` 36, 73). | Headings in order within a lane; sequence edges consecutive. |
| R4 | A top-level ordered list whose items begin with a verb. | Items in order; sequence edges consecutive. |
| R5 | Last resort. | A three-node spine `Entry → "Run <skill>" → Exit`, labelled from the frontmatter `description`. Passes AC-3 and honours "no skill left chart-less". |

R1 also runs as a **corroborating spine** for the two authored shapes (evidence precedence 1) —
it is the same token parser.

#### Contract — the well-formedness validator (`validate.mjs`, AC-3, reusable)

`validateChart(chart)` is a pure function over a `FlowChart` and is the **same** function
feature-004's doorway charts must pass. Its rules:

| # | Rule | Severity |
|---|---|---|
| V1 | `nodes` non-empty; ids unique; every id matches `^[A-Za-z][A-Za-z0-9_]{0,31}$`. | error |
| V2 | `entries.length >= 1` and every entry id ∈ node ids. | error — **AC-3** |
| V3 | `exits.length >= 1` and every exit id ∈ node ids. | error — **AC-3** |
| V4 | Every `edge.from` and `edge.to` ∈ node ids (no dangling edges). | error — **AC-3** |
| V5 | No duplicate `(from, to, condition)` triple. | error |
| V6 | Every node reachable by walking edges from some entry. | error (always satisfiable — see the `entries` rule) |
| V7 | Every node has `provenance` with a non-empty `file` under `canonical/`, `1 <= startLine <= endLine`, and an `excerpt` whose line count equals `endLine - startLine + 1`. | error |
| V8 | Every `label` non-empty and ≤ 60 Unicode code points (`Array.from(label).length` — the same measure the truncator uses, so the two cannot disagree). | error — NFR-1 / FR-3 |
| V9 | No advance block leaves residual text referencing a declared state of this chart that is neither an edge target from that node nor recorded in its `terminal.handoff`. | error — the KI-008 anti-silence guard (parser rule 10) |

The caller **throws** on any error, matching AC-1's "the generator throws" guard shape already used
at `gen-reference.mjs` 377–381. `chart.warnings` are logged, never thrown — that is the FR-2
best-effort boundary: a chart may be *approximate*, never *malformed*.

### UI Specs

*Activated because how a chart reaches the page is a cross-feature contract, not a presentation
afterthought: FR-3's node interaction, feature-005's list and feature-006's DOM binding all depend
on the substrate chosen here.*

#### Contract 2 — the rendering substrate

**Decision: the site's established runtime `astro-mermaid` path**, with a build-time JSON sidecar
carrying the interaction data. **Rejected: D18 ("D-012")-style build-time pre-rendered inline SVG** —
it would require adding a headless Mermaid compiler the site does not have, for a load-time argument
that does not transfer from `kb.html`.

Grounds, all verified rather than assumed:

- `astro-mermaid` 2.0.2 is configured in `site/astro.config.mjs` (21, 28–47), deliberately ordered
  before `starlight()`, and already renders 11 fenced blocks across four pages. It is the
  established mechanism, and using it adds **zero** new dependencies (§7).
- **D18's precedent does not carry a reusable tool.** `kb.html`'s "pre-rendered inline SVG" visuals
  are *hand-authored* SVG/HTML+CSS validated by Playwright (`validate-visuals.mjs`,
  `integration-map.md` § MCP and Playwright: "Playwright-render every authored visual … the S7 gate
  that replaced the prior Mermaid auto-layout guarantee"). There is no mermaid→SVG compiler anywhere
  under `canonical/aid/scripts/summarize/`. Hand-authoring is impossible at whole-corpus scale,
  so following D18 here would mean introducing `@mermaid-js/mermaid-cli` (Puppeteer/Chromium) or
  mermaid+jsdom into the site build — precisely the "no new runtime beyond what `site/` already
  depends on" that §7 forbids.
- **D18's rationale is `kb.html`-specific.** It optimised a single self-contained, offline,
  bundler-less HTML file (dropping a ~3 MB engine, `decisions.md` 330–333). `/skills/` is a bundled
  Astro site that already ships mermaid to four pages; the offline and dependency-weight arguments do
  not apply with the same force, and `astro-mermaid` loads mermaid lazily — only on pages that
  actually contain `pre.mermaid` (`astro-mermaid-integration.js` 316–318, 381–383).
- **Idempotence is unaffected.** Build output is deterministic text; the only random identifier in
  the pipeline is generated in the browser (`astro-mermaid-integration.js` 423). Build-time SVG
  would be the *riskier* choice for AC-6, since headless-rendered SVG embeds generated element and
  ARIA ids that would need normalizing to stay byte-identical.

Cost accepted: charts render client-side, so a chart is not present in the initial HTML. NFR-2 and
AC-5 are unaffected because feature-005's below-chart list is static markdown; see KI-004.

#### Hooks this gives feature-006

Feature-006 attaches to exactly these, and to nothing else:

- **H1 — readiness.** The container is `pre.mermaid`; the integration sets
  `data-processed="true"` on it after `mermaid.render` resolves
  (`astro-mermaid-integration.js` 435–437). Rendering is asynchronous, so feature-006 MUST observe
  the `data-processed` attribute transition rather than assume DOM at load.
- **H2 — per-node group.** Inside the rendered SVG each node is a `g.node` whose DOM id is
  `flowchart-<nodeId>-<vertexCounter>`, where `<nodeId>` is **this feature's `FlowNode.id`,
  verbatim**. Verified against the locked install, mermaid **11.15.0**
  (`site/package-lock.json` pins `node_modules/mermaid`; the peer is auto-installed by
  `astro-mermaid`'s `peerDependencies`): `dist/**/flowDiagram-*.mjs` builds
  `domId: MERMAID_DOM_ID_PREFIX + id + "-" + this.vertexCounter` with
  `MERMAID_DOM_ID_PREFIX = "flowchart-"`, and the node renderer emits
  `parent.insert("g").attr("class", getNodeClasses(node)).attr("id", node.domId ?? node.id)`.
  Selector: `pre.mermaid svg g.node[id^="flowchart-n7-"]`. The id contract
  (`^[A-Za-z][A-Za-z0-9_]{0,31}$`, unique, stable across builds) exists for this consumer.
- **H3 — id-template-independent selector.** Every node also carries a mermaid `class` statement
  (`class n7 aidNode;`) backed by a `classDef aidNode` in the same fence, so `g.node.aidNode`
  selects all chart nodes without depending on mermaid's id template.
- **H4 — the node record.** `<skill>.flow.json` is the serialized `FlowChart`; its `nodes[]` gives,
  for each `id`, that node's `name`, `label`, `kind`, `provenance` and `detail`. Feature-006
  resolves a clicked node by looking its `id` up there — no SVG text scraping, no re-parse of
  `canonical/`. Feature-005 renders its ordered list from the same array in `order` sequence, so
  the two features cannot disagree about what a node is.
- **H5 — re-render caveat.** The integration observes `data-theme`; on change its `MutationObserver`
  removes `data-processed` from every `pre.mermaid` and calls `initMermaid()`
  (`astro-mermaid-integration.js` 466–473). It is `initMermaid()` that then replaces the container's
  contents — `diagram.innerHTML = svg` (435) — so on every theme switch the whole SVG subtree, and
  any listener bound to a node inside it, is destroyed. Feature-006 MUST therefore use **event
  delegation on the `pre.mermaid` container**, which survives because only its `innerHTML` is
  rewritten, and re-run any decoration on each `data-processed` transition. It must also handle
  `astro:after-swap` (491–497).
- **Not available:** mermaid's `click` directive. `astro-mermaid` never sets `securityLevel` — its
  client config is `{ startOnLoad: false, theme, ...mermaidConfig }` and `mermaidConfig` is empty
  here (`astro-mermaid-integration.js` 362–366; `astro.config.mjs` 30–47) — so mermaid's default
  `strict` level applies and click callbacks are disabled. Loosening it would apply globally to the
  site's existing 11 diagrams. H2–H4 are the sanctioned hooks.

Under the rejected build-time-SVG option feature-006 would instead get server-rendered `g` ids and
no readiness dance — that difference is the whole reason H1 and H5 are stated as obligations here
rather than left for feature-006 to discover.

#### Chart presentation

- Dialect: `flowchart TB`, matching the site's established usage
  (`concepts/methodology.md` 30–68).
- Node shapes by `kind`: `entry` and `exit` stadium `([...])`, `decision` rhombus `{...}`,
  `step` / `loop-back` rectangle `[...]`.
- Node label: `"NAME<br/>derived label"` — the same two-line pattern
  `concepts/methodology.md` already uses (`"2a · aid-describe<br/>full path only"`). Escaping:
  `&` `<` `>` `"` → HTML entities; any residual backtick or pipe → a space.
- Edges: `-->` sequence; `-->|"condition"|` branch; `-. "condition" .-> ` for `loop-back` and
  `re-entry`, matching methodology.md's `TR -. suggests .-> SC` (46).
- Every chart carries its **own `classDef` block** in the casulo palette rather than relying on the
  integration's theme configuration — see KI-001, where `themeVariables` is silently dropped by
  `astro-mermaid` 2.0.2. Self-contained `classDef`s are also what `concepts/methodology.md` 32–39
  already does, so this is the site's convention as well as a defence.
- A chart whose `confidence` is `approximate` renders a short notice line above the fence
  ("Approximate — derived from an unstructured source; the fragments below are authoritative"),
  which is NFR-3's interpretation-risk acknowledgement made visible.
- The fence is preceded by an H2 the page's table of contents can anchor
  (`tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 }`, `astro.config.mjs` 74).

### Open Questions

- **OQ-1 — Fix `themeVariables` here, or file it?** KI-001 is a real defect in
  `site/astro.config.mjs` that already silently degrades the site's 11 existing diagrams. Fixing it
  is a two-line change (nest the palette under `mermaidConfig`), but `astro.config.mjs` is owned by
  feature-002 and §7 requires existing pages to keep passing. This SPEC works correctly either way
  (per-chart `classDef`s do not depend on it). **Owner decision:** fix in this work, or file a
  separate ticket.
- **OQ-2 — `aid-triage` is not a residual skill. ✅ RESOLVED 2026-07-25.** REQUIREMENTS §8 and this
  feature's Description had named `aid-triage`'s literal `## State Machine` heading as the exemplar
  of a skill "matching neither shape". It carries a full `## Dispatch` table with `State` and
  `Advance` columns (`aid-triage/SKILL.md` 73–81) and classifies `dispatch-table`; the
  `## State Machine` heading at 58 is followed by ASCII art, not a table, which is why D1's table
  requirement is what settles it. Confirmed independently at review; both documents were corrected
  by the orchestrator. The residual extractor's fixture is `aid-config` (the R3 mode+step shape).
  Recorded here because the reasoning is load-bearing for D1's precedence, not because anything
  remains open.
- **OQ-3 — Feature-001 seam.** S1–S4 above are requirements on a SPEC that does not exist yet. If
  feature-001 chooses a sidecar location other than `site/src/data/skill-flows/`, features 005 and
  006 must be re-notified before they are specified.

