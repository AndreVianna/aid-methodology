# Graph View Shell, Lenses And Controls

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.6 (FR-2, FR-3, FR-13–FR-17), §6.1 (NFR-3), §7 (C-1), §9 (AC-6–AC-8, AC-10, AC-15) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned to amended FR-16 — C-1 withdrawn, AC-6 rewritten to a documented-prerequisites criterion | /aid-specify |
| 2026-07-28 | Final-gate finding fixed — the `GV*` assertions now name their containing suite (`tests/canonical/test-graph-view-shell.sh`), matching features 010/012/013 | /aid-specify |
| 2026-07-28 | Added the render-transform invariant to the shared module's contract (`.mjs` is in `render.py`'s `_TEXT_EXTENSIONS`, so no `canonical/…` path and no filename placeholder, in code or comments) and made GV02's comparison basis same-tree, with GV08 asserting render invariance; specified zero-row nodes — materialised as complete `Node` records from `kb_gaps` (`id` + `name`), marked via `nodeLabels`, with grouping/density/focus behaviour fixed and the mismatch alarm structurally excluded from firing on them | Owner review |
| 2026-07-28 | Fixed CRITICAL "AC-15 mechanism contradicts feature-006": coverage predicate moved to a shared Node/browser module (`canonical/aid/scripts/graph/coverage-predicate.mjs`) with an explicit runtime boundary; `kb_gaps` demoted to a recorded generate-time result the view verifies against and fails loudly on; `kb-unbacked` fixed as lens-only; AC-15 scoping closed per owner decision; reliance on feature-004's never-`inferred` `evidence_provenance` invariant stated | Owner review |

## Source

- REQUIREMENTS.md §5.6 (FR-13, FR-14, FR-15, FR-16, FR-17) and §5 FR-2 (the view this feature
  shells), FR-3 (the table is the single input)
- REQUIREMENTS.md §2 Problem Statement (all four purposes are equally primary — this is why
  there are four lenses and why none is a privileged default)
- REQUIREMENTS.md §6.1 NFR-3 (every preset lens applies to **both** renderings)
- REQUIREMENTS.md §5.4 FR-6 (relation category is available as a grouping dimension)
- REQUIREMENTS.md §7 Constraints — **C-1 is withdrawn** (2026-07-28); no packaging constraint binds
  this view. See §5.6 FR-16 as amended, and its four recorded consequences.
- REQUIREMENTS.md §9 (AC-6, AC-7, AC-8, AC-10, AC-15)

**The lens view-model is a first-class contract.** This feature owns the lens and control layer,
and **feature-008 and feature-009 both consume it**. That interface must be specified crisply —
as a named contract with defined inputs and outputs, not as an implementation detail of whichever
rendering is built first. A loose interface here is the direct route to violating **NFR-3** (every
preset applies to both renderings) and **AC-7** (each lens visibly changes the view in both the
graph and the table) at integration time, because the two renderings will drift into interpreting
the same lens differently. `/aid-specify` must treat the lens view-model as a first-class contract
in this SPEC, not a by-product.

**Dependency position.** Blocked by feature-003 (the schema it renders from) and, for real data,
feature-005. Blocks feature-008 and feature-009, which both render inside this shell and consume
this lens layer. Not blocked by feature-002 — the shell, the data loader, and the lens layer are
independent of the rendering-approach decision, which is why the accessible table view can proceed
while the canvas waits.

**Shared acceptance criteria.** AC-7 is shared with feature-009 (table side) and AC-15 with
feature-006 (the ledger owner). Both are mutual obligations and neither owner may consider them
met alone.

## Description

The graph view is something a reader opens and uses. **How it is packaged is deliberately not
constrained** *(FR-16 as amended 2026-07-28; the former single-file/no-network constraint and C-1
are withdrawn)* — it may be one file or several, it may fetch from a hosted library, and it may be
produced by a build step. What replaces the packaging rule is an obligation of disclosure: whatever
the view needs in order to work — network access, companion files, or a build output — is documented
explicitly, so a reader knows where and when it will function. The Knowledge Base summary keeps its
own self-containment bar; this artifact is no longer held to it.

Because the view is genuinely interactive, it runs script at load time, and that is the intended
design rather than an oversight. The project's existing rule against shipping a runtime drawing
engine applies to the Knowledge Base summary and continues to apply there; this artifact is a
documented exception to it.

Everything the view shows comes from the relationship table and nothing else. There is no second
extraction, no parallel path, no chance of the picture and the table telling different stories.

On top of that, the view offers four named starting points, one for each of the purposes this work
serves. One highlights what is unbacked or undocumented and dims the parts that are well-formed.
One collapses to categories and document-level groups so a newcomer can see the shape of things.
One takes a selected node and shows its neighbourhood out to a depth the reader chooses. One shows
only the chains from Knowledge Base concepts down to source and external origins, coloured by how
each was established.

These are entry points, not modes. Arriving through one never takes controls away: grouping,
density, filtering, and zoom stay available throughout, so a reader who starts from a preset can
keep going wherever the question leads. And because all four purposes matter equally, no single
one is installed as the default the others have to be dug out from behind.

Each lens is a saved configuration of the same controls over the same data — which is what allows
a lens to mean the same thing whichever way the data is being displayed.

## User Stories

- As a **newcomer to the project**, I want a lens that collapses the whole picture to categories
  and document groups, so that I can build a mental map without reading documents one by one.
- As a **maintainer/architect**, I want a lens that shows a selected node's neighbourhood to a
  depth I choose, so that I can answer "what does this change touch" before I make it.
- As a **maintainer/architect**, I want to keep adjusting grouping, density, filters, and zoom
  after arriving through a preset, so that a preset starts my investigation instead of ending it.
- As a **maintainer/architect**, I want the view's runtime prerequisites stated plainly, so that I
  know before I rely on it whether it needs the network, companion files, or a build output.
- As a **KB reviewer**, I want the view to render only from the relationship table, so that what I
  see on screen is exactly what I can verify in the file.

## Priority

Should

*In scope and required by §4; ranked Should rather than Must only because §10 states explicitly
that `relationships.md` and the gap ledger ship usefully with no view at all. This is a
schedule-risk ranking, not a statement that the view is optional.*

## Acceptance Criteria

- [ ] AC-6 *(as rewritten 2026-07-28)*: Given the artifact as delivered by whatever packaging the
      rendering research selected, when it is opened by its documented entry point, then it renders
      the graph successfully, and its runtime prerequisites — network access, companion asset files,
      or a build output — are documented explicitly.
- [ ] AC-7 *(shared with feature-009 — mutual obligation; neither feature may consider this met
      alone)*: Given the generated view, when each of the four preset lenses is applied in turn,
      then all four are present, each visibly changes the view, and each applies to both the graph
      rendering and the table rendering.
- [ ] AC-8: Given a reader who has arrived at the view through a preset lens, when they use the
      grouping, density, filter, and zoom controls, then all of those controls remain usable — the
      preset has not locked the view into a mode.
- [ ] AC-10: Given the generated view, when its data source is examined, then it renders from
      `relationships.md` alone, with no second extraction path.
- [ ] AC-15 *(shared with feature-006 — mutual obligation; neither feature may consider this met
      alone)*: Given a generated ledger and a generated view, when the Coverage lens is applied,
      then it surfaces exactly the gaps present in the ledger.
- [ ] Given the generated view, when its default state is inspected, then no one of the four
      purposes is privileged as the default layout.
- [ ] Given the lens view-model, when feature-008 and feature-009 consume it, then both interpret
      each lens identically — the contract is explicit enough that a lens means the same thing in
      the graph and in the table.
- [ ] Given the relation categories established by feature-001, when the reader groups the view,
      then relation category is available as a grouping dimension.

---

## Technical Specification

> **Written against a contract, not a renderer.** The rendering decision belongs to feature-002
> (FR-18, Q2) and is **not settled here**. Everything below is renderer-independent by
> construction: this feature owns a plain data model plus a pure projection function, and both
> renderings read the projection rather than the controls. The one place feature-002's answer
> reaches this SPEC is the *validator surface* (see § Layers & Components → "Validator surface"),
> which is called out explicitly.
>
> **Design pressure on record (research gathered 2026-07-28).** Of the four common approaches —
> native SVG with labelled marks, SVG plus a data-table peer, Canvas with a DOM proxy layer, and
> WebGL with proxies and summaries — only SVG and the DOM produce accessibility-tree semantics
> without hand-built proxies; Canvas and WebGL render into an opaque buffer that exposes nothing
> to assistive technology, so the renderer choice sets how much accessibility work is manual.
> Renderer ceilings run roughly: SVG degrades past a few thousand marks, Canvas is CPU-bound in
> the tens of thousands, WebGL scales to hundreds of thousands. Because **A-5** bounds this
> project's node counts to the hundreds, WebGL's advantage begins far above the scale in play
> while its accessibility cost is the highest of the four — so "most powerful renderer" and "best
> artifact" do not point the same way here, and FR-16's removal of the packaging ceiling does not
> by itself argue for the heavier option. The prior art also warns against exposing every datum
> as a tab stop (expose meaningful aggregates; let the table carry raw rows — directly relevant to
> the Overview lens) and notes that the expensive accessibility operations are forced
> accessibility-tree rebuilds from per-frame ARIA writes, not the visual draws.
>
> The recommended architecture from that research is the one this SPEC implements: **maintain an
> accessibility model alongside the visual model** — one plain structure of nodes, edges and
> current focus, decoupled from drawing, read by the renderer *and* the accessibility layer, so it
> survives a renderer swap and keeps the graph, the table, and the announced text from drifting
> apart. Here that structure and the lens view-model are **unified into one object** (`ViewModel`
> below): one structure, three readers.

### Data Model

**No persistent schema, and no new stored artifact.** `relationships.md` (feature-003) is the only
durable store, and it is the only input — there is no second extraction path (FR-3, AC-10). This
feature adds three in-memory structures, all built at load time in the browser and all derived
from that one file.

#### 1. `GraphModel` — the parsed table (built once, never mutated)

Parsed from the **eight** columns REQUIREMENTS.md §5.2 defines: Source Id, Source Name, Target Id,
Target Name, S2T Relation, T2S Relation, Provenance, Observation. There is no `Strength` column and
therefore **no strength-driven visual encoding anywhere in this work** (Q1, resolved 2026-07-28).

| Field | Type | Built from |
|-------|------|-----------|
| `nodes` | `Map<string, Node>` | the union of `Source Id` and `Target Id` over all rows |
| `edges` | `Edge[]` | one entry per data row, in table order |
| `rowCount` | integer | count of data rows accepted by the loader |
| `categoryOf` | `Map<string, string>` | relation → category (FR-6). A build-time constant (`RELATION_CATEGORY` in `graph-model.js`) authored from feature-001's vocabulary, **not** parsed from the page — the vocabulary is a closed definition, not data about the project, so carrying it in code is not a second extraction path (AC-10). |
| `coverageBearing` | `Set<string>` | The coverage-bearing relation subset — condition 3 of the coverage predicate below. Read from the shared predicate module, not from the page. |
| `recordedGaps` | `Array<{id, name, severity, clause}>` \| `null` | The `kb_gaps` frontmatter list feature-006 wrote at generate time, computed over feature-004's **enumerated node set** rather than over table rows (owner decision, 2026-07-28). `name` is required, not optional: it is the only source of a display name for a zero-row node. `null` when the key is absent. |
| `integrity` | `{status, viewOnly, ledgerOnly, orphans}` | The result of the `kb_gaps` verification below. Computed once, at load. |
| `nameConflicts` | `Array<{id, kept, seen}>` | ids whose display name differs between occurrences |
| `sourceStamp` | string | the generator attribution read from `relationships.md` frontmatter |

`Node` = `{ id, name, kind, glyph, kbDoc, degree, kbDegree, intDegree, extDegree }`

- `kind` is `'kb' | 'int' | 'ext'`, taken from the id prefix (§5.3). It is never inferred from
  anything else, so a malformed prefix is a load error rather than a silent third category.
- `glyph` is the shape/label token that carries `kind` **without colour** (NFR-5). It is assigned
  here, in the model, precisely so the graph and the table cannot disagree about it.
- `kbDoc` is populated for `kind === 'kb'` only: the document part of the id, ahead of the
  heading/concept part (§5.3). It is the grouping key for the Overview lens's document-level
  groups (FR-13).
- `degree` and the three per-kind degree counters are computed in one pass over `edges`. `degree`
  is the density control's sole input. They are **not** inputs to the coverage predicate below —
  that predicate is edge-shape-aware (it asks *which* relation, in *which* direction, to *which*
  endpoint), not degree-based — so "the density slider never hides a gap" is guaranteed by an
  explicit exemption in feature-008 rather than by the two reading the same counter.
- **No qualification field, deliberately — and this feature relies on an invariant it does not
  own.** `Node` carries no FR-24 qualification evidence and needs none. feature-004's node record
  fixes `evidence_provenance` to `declared | derived` and states as a hard rule that it is **never
  `inferred`**: a candidate that only a reading would qualify is written to `candidates.tsv` with a
  `drop_reason` and is *not emitted as a node* (feature-004 SPEC § D1 row 6, § "The hard rule").
  **feature-004 owns that invariant**; this SPEC depends on it and says so here so the dependency
  is visible rather than implicit. Its consequence is that feature-006's F4 filter — "drop `int:`
  nodes whose sole qualification is `inferred`" — has an empty domain and is therefore no part of
  the shared predicate below. Were the invariant ever relaxed, the predicate would need per-node
  qualification evidence *in the browser*, which `relationships.md` does not carry and FR-3/AC-10
  forbid fetching separately; that is the concrete cost of relaxing it, and it is why the invariant
  is load-bearing rather than incidental.

`Edge` = `{ key, sourceId, targetId, s2t, t2s, category, provenance, observation, row }`

- `key` = `sourceId`, `targetId` and `s2t` joined by `U+0000`. It is stable across loads and unique
  by construction, because AC-3 forbids the same relationship appearing twice.
- `category` = `categoryOf.get(s2t)`; an `s2t` value absent from the vocabulary is a load error,
  not an `'uncategorised'` bucket — AC-2 already guarantees vocabulary membership, so tolerating a
  miss here would hide a feature-003 validation failure behind a working-looking view.
- `provenance` is one of `declared`, `derived`, `inferred` (§5.2). **A-3** makes it required by
  construction, so an empty cell is a load error rather than a defaulted value.
- `row` is the 1-based table row index, carried so every surface — a graph mark, a table row, an
  announcement — can cite the row a claim came from.

**Frontmatter tolerance (Q3, resolved 2026-07-28).** `relationships.md` is a KB-indexed document
carrying valid KB frontmatter, so the loader MUST skip a leading `---` … `---` block before it
looks for the table. It skips exactly the *first* such block and resumes scanning after it; a
later `---` in the body is a thematic break, not frontmatter. This mirrors the same
first-block-only scoping the KB's own frontmatter readers use (`build-kb-index.sh` → `ef`,
`extract_field`), so the two agree on where frontmatter ends.

#### 2. `LensState` — the control view-model (the cross-feature contract)

A flat, JSON-serialisable record. Every control writes here and nowhere else; every preset is
expressed purely as values over these fields (FR-13). No field is a function, an element handle, or
a renderer object, which is what lets the same state be logged, diffed, and replayed in a test.

| Field | Type / domain | Meaning | Read by |
|-------|---------------|---------|---------|
| `preset` | `'coverage' \| 'overview' \| 'impact' \| 'provenance' \| null` | Label of the preset last applied. Advisory only — it never gates a control (FR-14, AC-8). | both |
| `grouping` | `'none' \| 'relation-category' \| 'document' \| 'node-kind' \| 'provenance'` | The grouping dimension. `'relation-category'` is the FR-6 dimension. | both |
| `density` | integer `1..5` | Thinning level. Level `1` performs **no thinning at all** — every node is shown, a zero-degree node included. Levels `2`–`5` hide nodes with `degree < density`. Stated as a level rather than a minimum degree precisely so that a zero-row node is not excluded by the level that is supposed to exclude nothing. | both |
| `filters.nodeKinds` | subset of `{kb, int, ext}` | Node kinds admitted. | both |
| `filters.categories` | subset of the vocabulary's categories | Relation categories admitted. | both |
| `filters.provenance` | subset of `{declared, derived, inferred}` | Provenances admitted. | both |
| `filters.text` | string | Case-insensitive substring match over the four id/name columns. | both |
| `focus.nodeId` | node id or `null` | The selected node for the Impact lens. | both |
| `focus.depth` | integer `1..6` | Neighbourhood radius in hops from `focus.nodeId`. | both |
| `emphasis` | `'none' \| 'coverage' \| 'provenance-chain'` | The **only** field that drives dimming/highlighting. | both |
| `zoom` | `{scale, panX, panY}` | Viewport transform. **Graph-only.** | graph |
| `sort` | `{column, direction}` | Table ordering. **Table-only.** | table |

**The carve-out is part of the contract.** `zoom` and `sort` are the *only* renderer-private
fields, and neither may affect which nodes or edges are present or emphasised. Everything that
decides membership or emphasis lives in the shared fields above, and is interpreted exactly once,
in `project()`. That is the mechanism by which NFR-3 and AC-7 hold — not a convention the two
renderings are asked to honour.

#### 3. `ViewModel` — the derived projection both renderings consume

`ViewModel = project(GraphModel, LensState)` — a pure function: same inputs, same output, no DOM
access, no clock, no randomness. It is also the accessibility model the research recommends
keeping beside the visual model, which is why the announced text and the per-mark labels are
fields on it rather than strings each renderer composes for itself.

| Field | Type | Contract |
|-------|------|----------|
| `visibleEdges` | `Edge[]` | Ordered by `row` ascending — a deterministic order both renderings share. |
| `visibleNodes` | `Node[]` | Every endpoint of `visibleEdges`, plus a focused node with no surviving edges, plus the zero-row nodes materialised from `kb_gaps` (see the predicate below), which are complete `Node` records and are grouped, thinned and filtered exactly like any other node. |
| `groups` | `Array<{key, label, nodeIds}>` | The `grouping` partition; a single `all` group when `grouping === 'none'`. |
| `nodeEmphasis` | `Map<id, 'normal' \| 'dimmed' \| 'kb-unbacked' \| 'int-undocumented' \| 'focus'>` | Per-node emphasis class. |
| `edgeEmphasis` | `Map<key, 'normal' \| 'dimmed' \| 'chain'>` | Per-edge emphasis class. |
| `nodeLabels` | `Map<id, string>` | The accessible name for a node on **every** surface. |
| `coverageGaps` | `{kbUnbacked: string[], intUndocumented: string[]}` | Sorted node-id lists; see the predicate below. Shape unchanged from the first draft of this SPEC, so feature-008 and feature-009 consume it exactly as already specified. |
| `coverageOrigin` | `Map<id, 'verified' \| 'ledger-only' \| 'view-only'>` | Where each `intUndocumented` id came from — recomputed **and** in `kb_gaps`, in `kb_gaps` only, or recomputed only. Additive; a renderer that ignores it still shows every gap. |
| `lensSummary` | string | One sentence naming the active lens and control values. |
| `announcement` | string | The text pushed to the live region after a lens change (WCAG 4.1.3). |
| `revision` | integer | Monotonic counter, incremented per successful projection. |
| `counts` | `{nodes, edges, hiddenNodes, hiddenEdges}` | What the header and the table caption both report. |

**Emphasis is classification, not styling.** `project()` returns *classes*; the graph maps them to
shape/opacity/label and the table maps them to a badge and a row group. Neither maps a class to
colour alone (NFR-5).

#### The coverage predicate — one implementation, two runtimes (AC-15)

*Owner decision, 2026-07-28.* The predicate is defined **exactly once, in a shared JavaScript
module**, imported by the ledger generator in Node and inlined into the view in the browser. One
implementation executed twice, so generator/view agreement is structural rather than asserted. This
subsection is the definitive statement of that module's identity and its runtime boundary;
feature-006 coordinates to it.

##### The module

`canonical/aid/scripts/graph/coverage-predicate.mjs`.

It sits in `scripts/graph/` — beside feature-004's `scan-source.sh` and feature-006's detector, the
two Node-side neighbours it exists to agree with — rather than in the graph's template set, because
`module-map.md` § Conventions places a helper under the phase area it serves, and this one serves
the pipeline as well as the page. It is authored under `canonical/` and rendered to every profile
tree with the rest of `aid/scripts/` (**C-2**), so both consumers get the same bytes in every host.
The `.mjs` extension is what makes it importable by Node with no `package.json` in that directory;
Node ≥ 20 is already the floor (**C-5**).

##### The Node/browser boundary, stated as five rules the file obeys

| Rule | Why it is required |
|---|---|
| No `import`, no `require`, no `node:` specifier | So Node can import it as-is *and* the browser can inline it as-is. A single `import` would break one of the two. |
| No `document`, `window`, `globalThis`, `fetch`, timer, or event | So a Node process can import it without a DOM shim, and so nothing in it can behave differently between the runtimes. |
| Only `export function` / `export const` declarations at top level — no `export {}` list, no default export | An `export` declaration is legal at the top level of an inline `<script type="module">`, where it is simply inert. That is what makes byte-identical inlining possible (below). |
| Every input and output is plain data — arrays, objects, `Map`, `Set` — never a path, handle, or stream | All I/O stays in the callers: reading `relationships.md`, reading `nodes.tsv`, and writing the ledger on the Node side; reading the embedded payload on the browser side. |
| **Render-transform invariant:** no `canonical/…` path reference and none of the three filename placeholders — **in code or in comments** | The profile generator text-processes this file. See below; without this rule the canonical and rendered copies legitimately differ and GV02 would fail inside a profile tree for a reason that is not a defect. |

Rules 1–3 and 5 are greppable, and **GV01** below asserts them, so the boundary is checked rather
than trusted.

**Why rule 5 exists, verified against the generator.** `.mjs` is a member of `render.py`'s
`_TEXT_EXTENSIONS` (`{.md, .txt, .sh, .ps1, .mjs, .js, .html, .css, .py}`), so every rendered copy
of this file passes through `substitute_filenames` and then `rewrite_install_paths`. Both
transforms are narrow, which is what makes the rule cheap to obey:

- `substitute_filenames` replaces only the three literal tokens `{project_context_file}`,
  `{reviewer_output_file}`, `{open_questions_file}` — `_PLACEHOLDER_RE` is built from exactly that
  set, and every other `{…}` token, including a template literal's `${…}`, is left alone.
- `rewrite_install_paths` rewrites `canonical/{scripts,templates,skills,agents,recipes}/…` and the
  `canonical/aid/…` forms to the profile's install root. **Its comment-skip protection does not
  help here:** the skip test is `line.lstrip().startswith("#")`, so a JavaScript `//` or `/* */`
  comment is *not* protected and a `canonical/…` path mentioned in a comment is rewritten like any
  other. This is the trap rule 5 is written to prevent — the file must not name its own canonical
  path even in its header block.

Contrast the vocabulary artifact, which is `.yml` and therefore absent from `_TEXT_EXTENSIONS`: it
is copied byte-for-byte and needs no such rule. This module cannot borrow that exemption, because
it must be executable in both runtimes and `.mjs` is what makes it importable.

A file obeying rule 5 is a **fixed point of both transforms**, so its rendered copies are
byte-identical to the canonical one. That is what makes GV02's comparison meaningful in any tree
and lets **GV08** assert the invariance directly.

##### How each runtime reaches it

**Browser.** The graph's `post-script.html` emits one inline `<script type="module">` whose body is
the concatenation of `coverage-predicate.mjs` followed by the view's own files in manifest order.
The shared file is inlined **byte-identically** — no transform, no wrapper, no re-export — which is
the strongest available form of "the browser runs the same code Node does", and **GV02** asserts it
by diffing the inlined region out of `graph.html` against the canonical file. This is the same
inline-a-JS-file idiom `/aid-summarize` already uses: `html-skeleton.html` carries an
`{{INLINE_LIGHTBOX_JS}}` placeholder that the generate step fills with the full content of
`lightbox.js` (`knowledge-summary/prompt.md` § placeholders).

Because the whole block is one module scope, **the view's own files declare no `import`
statements** and reference the shared exports directly; concatenation order is fixed by the
manifest, shared module first. This is a real constraint on how `graph-model.js`,
`graph-controls.js`, `graph-table.js` and `graph-canvas.js` are authored, and **GV01** asserts it
for them too. The constraint is not avoidable by using real module `import`s at runtime: a
`file://` page cannot import a relative ES module (the request is treated as cross-origin), and the
entry point is a local `file://` open.

**Node.** Bash cannot `import` an ES module, so the boundary this SPEC fixes is: **whatever
computes the ledger's gap set must be a Node process, and must `import` `coverage-predicate.mjs`.**
feature-006 currently specifies its detector as `detect-kb-gaps.sh`. Two shapes satisfy the
boundary and feature-006 may pick either — (a) `detect-kb-gaps.sh` remains the CLI entry, keeping
the interface, the `--table/--nodes/--output/--previous` flags and the unconditional-exit-0
contract feature-006 specifies, and shells out to a thin `detect-kb-gaps.mjs` for the set
computation; or (b) the detector is authored as `.mjs` outright. Shape (a) leaves every statement
in feature-006's SPEC intact and is the one assumed here. What is **not** admissible is an
awk/grep re-derivation of the predicate in Bash — that is the fork this decision exists to remove
(**C-4**).

##### What the module exports

| Export | Shape | Called by |
|---|---|---|
| `COVERAGE_BEARING` | `Set<string>` of relation names | both |
| `isCovered(nodeId, edges)` | `boolean` — the three-condition test below | both (internal to the two set functions, exported for its own test) |
| `detectKbGaps({nodeIds, edges})` | sorted `string[]` — the `int-undocumented` set | both |
| `kbUnbacked({nodeIds, edges})` | sorted `string[]` — the `kb-unbacked` set | browser only; colocated so all coverage logic reads from one file |

`detectKbGaps` returns the gap **set** and nothing else. Severity and the FR-21 clause stay
Node-side in feature-006, because they need feature-004's `nodes.tsv` (`qualifier`, `evidence`),
which the browser does not have and must not fetch. That split is the point of the boundary: the
part both runtimes must agree on is shared; the part only one runtime can compute is not.

**`nodeIds` is the one input that legitimately differs between the runtimes, and it is why the
`orphans` class below exists.** Node passes feature-004's full enumerated inventory from
`nodes.tsv` — this is required, not optional (owner decision, 2026-07-28): computing the ledger
over table nodes alone would silently drop the most undocumented artifact there is. The browser can
only pass the ids present in the table, because `GraphModel.nodes` is the union of the two id
columns. `edges` is identical in both runtimes — the final post-pass-2 table — so the *predicate*
has one behaviour in both; only its candidate set is wider on the side that can see more.

##### The predicate itself

Adopted verbatim from feature-006 § D2, which owns its semantics. An enumerated `int:` node is
**covered** when at least one edge satisfies all three conditions:

1. the node is one of the edge's endpoints, **or** an ancestor path of the node is that endpoint —
   a `kb:` doc that documents a directory covers the artifacts inside it (feature-006 § D3, class
   F2). Path matching needs no new `Node` field: an `int:` id *is* its repo-relative path with the
   prefix stripped (feature-006 § D5, `Doc` column);
2. the other endpoint carries the `kb:` prefix (§5.3);
3. the relation naming that direction is a member of `COVERAGE_BEARING`.

Coverage counts from edges of **any** `Provenance`, including `inferred` (feature-006 § D3, class
F3) — liberal about what counts as coverage, strict about what counts as a defect. An uncovered
node is a gap. F4 is absent by construction, per the feature-004 invariant recorded above.

**`COVERAGE_BEARING`'s two copies and the test that binds them.** feature-006 owns the *selection*
and records it as a named subset beside feature-001's vocabulary artifact, where a reviewer reads
the two together. `coverage-predicate.mjs` carries the *executable* copy, because rule 1 above
forbids importing it. **GV04** asserts the two sets are equal — the same doc↔code lockstep the
project already uses for render drift — so the reviewable statement and the running code cannot
diverge silently. **GV05** asserts `COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`, so a member that
is not a real relation is a build failure rather than a member that never matches.

##### Reconciliation with feature-006's current text

feature-006 was written in parallel and converged on the same *semantics* by a different route. All
three differences below are **resolved in this SPEC's favour** by the owner's 2026-07-28 decisions;
feature-006 is being repointed. They are recorded rather than deleted so that a reviewer reading a
not-yet-repointed feature-006 sees an accounted-for divergence instead of a live contradiction.

| feature-006 says | This SPEC says | Why |
|---|---|---|
| The predicate is `coverageGaps(graphModel)` exported from `canonical/aid/templates/knowledge-graph/graph-model.js` (§ D2) | It is `detectKbGaps` / `kbUnbacked` exported from `canonical/aid/scripts/graph/coverage-predicate.mjs` | Two concrete blockers, both checkable. (i) `graph-model.js` also carries the markdown parser, `project()`, the store and the presets, so importing it from Node pulls the whole view layer in — the precise thing the owner's boundary exists to prevent. (ii) Node resolves a `.js` file by the nearest `package.json`; there is none at the repo root and none under `templates/`, so `.js` there is CommonJS and `export` is a **parse error**. The only `"type": "module"` in the tree is scoped to `canonical/aid/scripts/summarize/`. An `.mjs` under `scripts/graph/` needs no `package.json` at all. |
| The predicate is `kbDegree === 0`, with refinements K1 (coverage-bearing only) and K2 (ancestor attribution) applied to the counter (§ D2) | The predicate is the three-condition `isCovered` test above; **K1 is condition 3 and K2 is condition 1** | Semantically identical — this SPEC adopts both refinements in full. It declines the *counter* framing because `kbDegree` is a plain per-kind counter that sums with `intDegree` and `extDegree` to `degree`; a `kbDegree` that counted only coverage-bearing, ancestor-attributed edges would silently break that arithmetic while keeping the name. `Node.kbDegree` therefore stays plain and unused by coverage. |
| An enumerated node absent from the table is invisible to the lens *and* the ledger equally, left as a residue (§ D2, "One residue") | `kb_gaps` is computed over feature-004's enumerated node set, so such a node **is** an entry and a ledger row; the view materialises it as a complete `Node` from that entry | **Owner decision, 2026-07-28.** This closes the residue instead of deferring it, and it is what FR-19/FR-20 require — a source concept with no KB representation is "not silently dropped and not merely rendered as an unconnected node". A node with no relationships at all is the most undocumented artifact in the repository, which is why the residue was upgraded rather than accepted. |

The first two are edits feature-006's D2 and L2 need. The third additionally requires each
`kb_gaps` entry to carry a **`name`** alongside its `id`, since the frontmatter is the only place a
display name for a zero-row node can come from.

##### Two node classes: one verified against the ledger, one view-only

| Class | Definition | Ledger relationship |
|---|---|---|
| **`int-undocumented`** | `kind === 'int'` and not covered by the predicate above | **Verified.** One ledger row per member (FR-20, FR-26); this is the class AC-15's equality binds. |
| **`kb-unbacked`** | `kind === 'kb'` with no edge to an `int:` node — REQUIREMENTS.md §2 item 1's "a `kb:` node with no `int:` edge". Deliberately *not* narrowed by `COVERAGE_BEARING`: §2 item 1 says "no `int:` edge", full stop | **View-only.** Computed in the browser, **never** written to `kb_gaps`, **never** a ledger row. It has no ledger counterpart and is never compared against one. |

*Owner decision, 2026-07-28 — the AC-15 scoping question raised in the first draft is closed.*
AC-15's "the two agree" binds the `int:` class only. The Coverage lens still surfaces both classes,
because FR-13 says it highlights unbacked `kb:` nodes as well as undocumented `int:` nodes; the two
are labelled distinctly on both surfaces (feature-008's `kb-unbacked` / `int-undocumented` emphasis
classes, feature-009's `no source` / `no KB doc` badges) so a reader can tell which has a ledger
counterpart. No widening of FR-20 or FR-26 follows, and nothing else in this SPEC depends on the
scope.

##### `kb_gaps` as a recorded result, and the verification against it

*Owner decision, 2026-07-28.* `kb_gaps` stays in `relationships.md` frontmatter but is **demoted
from mechanism to record**: it is the generate-time result, not the lens's source of truth. The
view recomputes with the shared predicate and **verifies** its answer against the record.

**When it runs.** Once per load, inside `createStore` (Feature Flow step 3b), after `GraphModel` is
built and before either rendering mounts. Not per lens application — it is a property of the data,
not of the lens, and re-running it on every projection would be noise.

**What it compares.** Let `R` be the recomputed `int-undocumented` set, `G` the id set of
`recordedGaps`, and `T` the `int:` ids present in the table:

| Set | Meaning | Verdict |
|---|---|---|
| `viewOnly = R \ G` | the view found a gap the ledger does not carry | **Mismatch** |
| `ledgerOnly = (G ∩ T) \ R` | the ledger carries a gap the view can see the node for but did not find | **Mismatch** |
| `orphans = G \ T` | a ledger gap whose node appears in no row at all — a **zero-row node** | **Expected asymmetry — never a mismatch** |

`coverageGaps.intUndocumented` is **always the sorted union `R ∪ G`**. A disagreement therefore
cannot hide a gap on either surface — hiding one is the only failure mode here that actually costs
a reader something — and `coverageOrigin` records which side each id came from. The union is also
what makes zero-row nodes cost nothing: they arrive through `G` and are surfaced by the same code
path as every other gap.

##### Zero-row nodes (`orphans`) — the most undocumented artifact there is

*Owner decision, 2026-07-28.* `orphans = G \ T` is the same set, under the same definition,
feature-006 § D6 names — one symbol across both SPECs. "Zero-row node" is its prose name here.

An enumerated `int:` node that appears in **no** relationship row is reachable in practice:
feature-004 qualifies by structural significance, and an entry point or a named unit (a test suite,
a manifest, a settings schema) need not have a single typed edge. Such a node is not an edge case
to tolerate — it is the sharpest instance of FR-19/FR-20, an artifact the project considers
significant with nothing said about it anywhere. It must be impossible for the view to lose.

Because `GraphModel.nodes` is built from the table's two id columns, the view cannot discover these
nodes. `kb_gaps` is how they reach the page, which is `kb_gaps`'s second job beyond verification.
Reading it is not a second extraction path: it is frontmatter of the one file the view already
renders from (AC-10) — the argument feature-006 § D6 makes for the key's existence.

**Materialisation.** For each id in `orphans`, the loader synthesises a **complete `Node` record**
and inserts it into `GraphModel.nodes`:

| Field | Value | Source |
|---|---|---|
| `id` | the `kb_gaps` entry's `id` | frontmatter |
| `name` | the entry's `name` | frontmatter — the only place a display name for this node exists, which is why `name` is a required key rather than an optional one |
| `kind` | `'int'` | the id prefix, read the same way as for any node (§5.3) |
| `glyph` | the `int` glyph | assigned by the same rule as every other node |
| `kbDoc` | `null` | `kbDoc` is `kb:`-only |
| `degree`, `kbDegree`, `intDegree`, `extDegree` | `0` | it has no edges; the counters are honest, not sentinels |

The record is **complete, not partial, and carries no "synthetic" flag**. That is the load-bearing
design choice: every consumer that iterates `visibleNodes` — feature-008's draw loop, feature-009's
selection, the focus combobox, the grouping partition — handles a zero-row node correctly without
knowing the class exists. A flag would invite `if (node.synthetic)` branches in two renderings,
which is the drift NFR-3 exists to prevent. The one place the distinction is legible is
`coverageOrigin`, which reports `'ledger-only'` for these ids like any other record-only gap.

**Not a mismatch, and the alarm specified below must not fire on one.** `orphans` is excluded from
the comparison by construction rather than by a guard clause: `ledgerOnly` is defined as
`(G ∩ T) \ R`, intersected with `T` precisely so that a node the view could never have found is not
counted against it. There is no code path on which a zero-row node reaches the error channel — the
alarm cannot be made to fire on one by a later edit without changing that set definition, which is a
visible change. A run that finds zero-row nodes is
a **normal** run — on a repository with any at all, it is *every* run — and an alarm that fired
each time would train the reader to dismiss the one that matters. The reader is told about them in
the legend and the caption, in the ordinary reporting channel, not through the error channel.

**Visual distinction — carried by `nodeLabels`, so neither rendering needs a change.** A zero-row
node takes the `int-undocumented` emphasis like any gap; the additional fact — that it has no
recorded relationship at all, which is the more severe of the two — is appended by `project()` to
its **`nodeLabels`** entry: `"<name> — no recorded relationships"`. `nodeLabels` is already defined
as "the accessible name for a node on **every** surface", so both renderings pick the marker up
through machinery they already implement, and neither can render it differently from the other.
This is the ViewModel earning its keep: a new distinction propagates to both surfaces without a
line of renderer-specific work and without a `degree === 0` branch in either.

It is text, never colour (NFR-5), so it survives forced-colors mode; and it is a *label*, not a
badge, so it also reaches the graph's accessibility proxies and the announced text, where a purely
visual "this mark has no lines attached to it" would reach nobody using a screen reader.

**Grouping, density and focus.** Each of the three is specified rather than left to fall out,
because a zero-edge node is exactly where an edge-derived control quietly drops a row:

| Control | Behaviour for a zero-row node | Why |
|---|---|---|
| `grouping: 'node-kind'` | the `int` group, like any `int:` node | Derived from the node, not from edges |
| `grouping: 'document'` | the ungrouped bucket | `kbDoc` is `null`; the same treatment every `int:` node gets under this dimension |
| `grouping: 'relation-category'` / `'provenance'` | a dedicated **`no relationships`** group, listed last | These dimensions are derived from edges and a zero-row node has none. A dedicated group is the only option that neither invents a category nor drops the node — dropping it would defeat the entire mechanism, and the Overview lens is where a newcomer would most benefit from seeing an unattached artifact |
| `density` | shown at level `1`, thinned at levels `2`–`5` like any node below the threshold | Level 1 performs no thinning at all (see `LensState`), and the Coverage preset sets `density: 1`, so a zero-row node is visible in the lens that exists to surface it by two independent routes. Above level 1 the reader has explicitly asked for less |
| `filters` | admitted and excluded exactly like any other node | No special case; a reader who filters out `int:` nodes meant it |
| `focus.nodeId` | selectable in the combobox; at any depth the neighbourhood is the node alone, and `lensSummary` / `announcement` say **"no recorded relationships"** | "What does this touch?" answered with "nothing recorded" is a real and useful answer. Saying it in words is what stops an empty Impact view from reading as a broken one |

**No feature-008 change is needed — checked, not assumed.** It draws from `visibleNodes`,
`visibleEdges`, `groups`, `nodeEmphasis`, `edgeEmphasis`, `nodeLabels` and `counts`, and takes its
accessible names from `nodeLabels` directly, so a complete `Node` record with no incident edges and
a label already carrying the marker flows through unchanged. Its density paragraph already exempts
`coverageGaps` members under Coverage emphasis, which these are.
A disconnected node has no attractive force acting on it, so its position comes from the layout's
centring behaviour alone — acceptable, and a placement concern feature-008 already owns through
`LayoutCache`.

**Failing loudly, in a browser artifact.** There is no exit code and no log a reader will see, so
"loudly" means three things at once, and none of them blanks the page:

1. **A persistent error callout**, first child of `<main>`, ahead of both renderings, reusing the
   existing `.callout.err` rule from `component-css.css` (no new style, no new colour token). It is
   not dismissible: a reader who closes it would be left with a view that looks trustworthy and is
   not.
2. **Announced.** Its container is present in the shell markup from load with `role="alert"` and
   empty; the text is written into it one task after mount. A live region must exist before its
   content is injected in order to announce reliably, which is why it is authored empty rather than
   inserted whole. It is written at most once per load and never again.
3. **`console.error`** with the stable prefix `graph.html: kb_gaps integrity check failed`,
   followed by the two id lists, so a headless check can assert on the string.

**What the reader sees.** Plain language, the exact ids both ways, and the fix:

```
⚠ Coverage data disagrees with the recorded gap ledger

This view recomputed the KB-gap set from the relationship table and got a
different answer from the kb_gaps list recorded in relationships.md when this
page was generated. The Coverage lens below shows the union of both sets, so
no gap is hidden here — but one of the two is stale.

  Found by this view, absent from the ledger (2):
    int:canonical/aid/scripts/graph/detect-kb-gaps.sh
    int:canonical/aid/templates/knowledge-graph/graph-model.js
  In the ledger, not found by this view (1):
    int:tests/canonical/test-graph-gap-ledger.sh

Most likely cause: graph.html and relationships.md came from different runs.
Regenerate both with /aid-graph.
```

The rest of the view still renders. This mirrors FR-25's reporting-not-gating posture: a blank page
would tell the reader less than a working view with an honest warning on it, and the gap ledger —
the artifact that *does* need to be right — is a Node-side product this page cannot affect.

**When `kb_gaps` is absent** (`recordedGaps === null`), the check cannot run. That is a `.callout.warn`,
not an error: the page states that the ledger cross-check was unavailable and that the Coverage lens
is showing the view's own recomputation. Treating a file that predates the field as corruption would
be a false alarm, and a false alarm here trains a reader to ignore the real one.

##### Tests

Fixtures are self-built and depend on no work folder's contents (**A-6**); suites live under
`tests/canonical/` as `test-*.sh`, which is how the runner discovers them.

**Suite:** the `GV*` assertions below live in **`tests/canonical/test-graph-view-shell.sh`** — named
explicitly so this feature matches the convention features 010, 012 and 013 already follow, and so
`test-coverage-parity.sh` can attribute the assertions to a file.

| ID | Assertion |
|---|---|
| **GV01** | `coverage-predicate.mjs` contains no `import`/`require`, no `node:` specifier, no `document`/`window`/`globalThis`, no `canonical/` substring, and none of the three filename placeholders (rules 1–3, 5); the view's `.js` files contain no top-level `import` |
| **GV02** | the module's inlined region in a generated `graph.html` is byte-identical to the `coverage-predicate.mjs` **of the tree that generated it** — `<install-root>/aid/scripts/graph/coverage-predicate.mjs`, never a hard-coded `canonical/…` path. `graph.html` is a run-time artifact written by the installed tree's own scripts, so same-tree is the only basis under which the comparison means "the browser runs what the generator ran" |
| **GV08** | every rendered copy of `coverage-predicate.mjs` under `profiles/` is byte-identical to the canonical file — the fixed-point property rule 5 buys. GV02 and GV08 together make the module's bytes identical everywhere, so a ledger generated under one host and a page generated under another still agree. The suite may name `canonical/…` freely: rule 5 binds the module, and `tests/` sits outside `canonical/` so the generator never renders it |
| **GV03** | `import`ing the module in a bare Node process succeeds and `detectKbGaps` returns the expected set over a fixture — proving no browser dependency leaked in |
| **GV04** | `COVERAGE_BEARING` equals feature-006's recorded subset beside the vocabulary artifact |
| **GV05** | `COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)` |
| **GV06** | over a fixture with a deliberately wrong `kb_gaps`, the load-time check reports the exact `viewOnly`/`ledgerOnly` ids, `coverageGaps.intUndocumented` is the union, and both renderings still mount |
| **GV07** | a zero-row `kb_gaps` entry produces a complete `Node` record carrying the entry's `name`, `degree === 0`, `coverageOrigin === 'ledger-only'`, **no** mismatch alarm, presence at `density: 1`, membership of the `no relationships` group under the two edge-derived grouping dimensions, and a row in feature-009's zero-row region |

GV02 and feature-006's GL09 are complementary, not duplicates: GL09 asserts the ledger, the
frontmatter, and a from-rows recomputation are the same set on the Node side; GV02 asserts the
browser is running the same bytes that produced it.

#### The preset table (FR-13, FR-14, FR-15)

Each preset is a frozen partial assignment over `LensState`, applied by patching the store. That is
the whole mechanism, and it is why arriving through a preset cannot lock the view (FR-14, AC-8):
the patch lands in the same state every control writes to, so every control keeps working
afterwards, and nothing is disabled or hidden by a preset.

| Preset | Patch | Serves |
|--------|-------|--------|
| **Coverage** | `emphasis: 'coverage'`, `grouping: 'node-kind'`, `density: 1`, filters all-on, `focus.nodeId: null` | §2 purpose 1 |
| **Overview** | `grouping: 'document'`, `density: 3`, `emphasis: 'none'`, filters all-on, `focus.nodeId: null` | §2 purpose 2 |
| **Impact** | `focus.depth: 2`, `density: 1`, `emphasis: 'none'`, `grouping: 'none'`; keeps the current `focus.nodeId` and prompts for one when unset | §2 purpose 3 |
| **Provenance** | `emphasis: 'provenance-chain'`, `filters.nodeKinds: {kb, int, ext}`, `grouping: 'provenance'`, `density: 1` | §2 purposes 1 and 4 |

Because all four purposes are equally primary (§2), the **initial** `LensState` is
`preset: null`, `grouping: 'none'`, `density: 1`, all filters on, `emphasis: 'none'`,
`focus.nodeId: null` — the unfiltered whole table with no lens applied. No preset is the default,
which is what makes the "no privileged default" criterion checkable rather than a matter of taste
(FR-15).

`'provenance-chain'` emphasis marks edges on a path from a `kb:` node to an `int:` or `ext:` node
and dims the rest; the Provenance lens's "coloured by the `Provenance` column" (FR-13) is carried
by a per-provenance **shape and label** in addition to colour, never by colour alone (NFR-5).

### Feature Flow

The whole flow runs client-side at page load. There is no server, no request, and no fetch.

1. **Read the embedded payload.** The generator embeds `relationships.md` verbatim in the page as
   `<script type="text/markdown" id="graph-relationships" data-encoding="base64">`, using the same
   payload element contract `/aid-summarize` already ships for its Markdown export (`state-generate.md`
   § "Payload element contract": base64 of the UTF-8 bytes, decoded with
   `new TextDecoder().decode(Uint8Array.from(atob(b64), c => c.charCodeAt(0)))`). Reusing that
   contract matters for two reasons: the base64 body cannot contain `<`, so it can never be
   mis-parsed as markup; and a `type="text/markdown"` script is the exact case
   `validate-html-output.sh`'s NM.1 awk rule already excludes from its inline-engine heuristic, so a
   large payload does not trip a Mermaid check it has nothing to do with.
2. **Parse.** `parseRelationships(text)` skips the first frontmatter block, locates the single
   eight-column table, and builds `GraphModel`. Any structural failure — wrong column count, an
   unknown relation, an empty `Provenance`, a malformed id prefix — surfaces in the page as a
   visible error region and leaves the rest of the shell inert rather than half-rendered. All of
   these conditions are ones feature-003's validators already reject at generate time, so hitting
   one at load time means the artifact shipped broken.
3. **Create the store.** `createStore(graphModel, initialLensState)` computes the first `ViewModel`
   and holds `{graphModel, lensState, viewModel}`.
   **3b. Verify against `kb_gaps`.** Still inside `createStore`, before any subscriber exists:
   recompute the `int-undocumented` set with the shared predicate, compare it to `recordedGaps`,
   and store the outcome on `graphModel.integrity`. On a mismatch the shell fills the `role="alert"`
   container one task after mount and writes the `console.error` line; on an absent `kb_gaps` it
   fills the warning callout instead. Both renderings mount either way.
4. **Mount the renderings.** `graph-table.js` (feature-009) and the canvas module (feature-008)
   each subscribe and perform a first render from the current `ViewModel`. **The table mounts
   first and unconditionally**, so the artifact is complete and usable on a build where the canvas
   module is absent or fails — which is what makes NFR-2's "peer view, not a hidden fallback"
   true at the level of load order, not just wording.
5. **Interact.** A control or a preset button calls `store.setLens(patch)`. The store merges,
   re-projects, bumps `revision`, and notifies every subscriber with the new `ViewModel`. Both
   renderings update from the same object in the same tick, so there is no window in which the
   graph and the table disagree.
6. **Announce.** `graph-controls.js` writes `viewModel.announcement` into the single
   `aria-live="polite"` status region — written once per lens change, never per frame. This is the
   WCAG 4.1.3 status-message obligation, and batching it at the state boundary rather than the draw
   boundary is what keeps accessibility-tree rebuilds off the frame path.

**Exactly two live regions, and no more.** The polite status region above carries lens changes; the
`role="alert"` region of step 3b carries the integrity failure and is written at most once per
load. Two regions with disjoint purposes and a fixed count stay checkable; a third would make
"which region said that" unanswerable.

### Layers & Components

Authored **once in `canonical/`** and rendered to every host profile by the existing generator
(**C-2**); the rendered copies under `profiles/`, `packages/*/_vendor/`, and the dogfood `.claude/`
tree are build output and are never hand-edited (`module-map.md` § Invariants, "Single source of
truth"). New files follow the placement conventions in `module-map.md` § Conventions: a template
set beside the existing one, and no new script where prose or an existing script will do.

```
canonical/aid/templates/knowledge-graph/        # new; sibling of knowledge-summary/
├── graph-skeleton.html        # placeholder shell, seeded from knowledge-summary/html-skeleton.html
├── graph-css.css              # graph, table and control styles — declares no new colour token
├── graph-model.js             # THIS FEATURE: parser, RELATION_CATEGORY, LensState, project(), store, presets
├── graph-controls.js          # THIS FEATURE: control wiring + both live regions
├── graph-table.js             # feature-009
├── graph-canvas.js            # feature-008
├── lens-presets.md            # the preset patch table above, in prose, for reviewers
└── accessibility-checklist.md # graph addendum to knowledge-summary/accessibility-checklist.md

canonical/aid/scripts/graph/                    # shared with feature-004 and feature-006
└── coverage-predicate.mjs     # THIS FEATURE: the single coverage predicate, run in Node and inlined in the browser
```

`coverage-predicate.mjs` is the one file in this feature that does **not** live in the template
set, and the placement is deliberate: it is imported by a Node process as well as inlined into the
page, so it belongs under the phase area it serves, beside the two Node-side scripts it must agree
with. See § "The coverage predicate" for the boundary rules it obeys and how each runtime reaches
it.

**Reused verbatim, not forked (FR-12, C-4, AC-17).** This feature adds **no assembler and no
validator**:

| Reused | How |
|--------|-----|
| `canonical/aid/scripts/summarize/assemble.sh` | Invoked with `--src .aid/.temp/graph/graph-src --manifest …/section-manifest.txt --output .aid/knowledge/graph.html`. Every path it touches is flag-overridable, so the graph needs no fork: it writes the same `skeleton-head.html` / `sections/*.html` / `section-manifest.txt` / `skeleton-foot.html` / `post-script.html` layout the script already validates for existence and non-emptiness. |
| `canonical/aid/scripts/summarize/validate-html-output.sh` | Run against `graph.html` for H1, A1–A5, S2, NM, L1, L2. |
| `canonical/aid/scripts/summarize/contrast-check.mjs` | Run against `graph.html` for C1/C2 — it extracts `:root, html[data-theme="light"]` and `html[data-theme="dark"]` from the inlined `<style>` and checks the eleven token pairs it already knows. |
| `canonical/aid/templates/knowledge-summary/component-css.css` | Inlined ahead of `graph-css.css`. It already carries `.tbl-wrap`/`table.tbl` (the table view's base styling), `.skip-link`, the `:focus-visible` rule, the `@media (prefers-reduced-motion: reduce)` block, the `@media (forced-colors: active)` block, and the `@media print` rules. |
| `canonical/aid/templates/knowledge-summary/lightbox.js` | Inlined **verbatim** into the `<script>` block that `html-skeleton.html` carries as `{{INLINE_LIGHTBOX_JS}}` — the tail the generate step renders into `post-script.html` (`knowledge-summary/prompt.md` § placeholders). It supplies the theme toggle (shared `aid-dashboard-theme` key), scrollspy, and the lightbox with `getLightboxFocusables` / `trapFocusOnTab` / `lastFocused.focus()` / the Escape handler — which is exactly what `validate-html-output.sh`'s A3 greps for. |
| `canonical/aid/templates/knowledge-summary/design-tokens.md` | The single palette source. `graph-css.css` consumes tokens via `var(--token)` and **defines no new colour**, so contrast stays inside the set `contrast-check.mjs` verifies. |

**No modal of our own.** The only dialog in `graph.html` is the reused lightbox, used for the
legend/structure visual. Node and row detail is an inline expanding region, not a modal — so the
page ships exactly one focus trap (the existing one), A2 and A3 pass against unforked code, and
there is no second trap to keep correct.

#### Packaging and the entry point (FR-16, AC-6, A-4, FR-9)

All three original packaging restrictions are withdrawn (FR-16; **C-1** withdrawn), so this SPEC
specifies a packaging *contract* that admits every layout FR-16 permits rather than mandating one —
narrowing the option space here would pre-empt feature-002, which FR-16 forbids.

- **Entry point:** `.aid/knowledge/graph.html` (FR-9, A-4). This is the documented entry point
  AC-6 refers to.
- **Companion assets, when the layout produces any:** `.aid/knowledge/graph-assets/`. A
  subdirectory is safe by construction: the KB index generator enumerates candidates with
  `find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`, so nothing below the first level,
  nothing without a `.md` extension, and nothing dot-prefixed is ever treated as a KB document.
  `INDEX.md`'s own `contracts:` entry states the same rule ("One entry per non-dot, non-recursive
  KB document under `.aid/knowledge/`"). This satisfies FR-9's naming requirement three times over
  and needs no change to the generator.
- **Runtime prerequisites must be written down (AC-6).** The generator emits, into the page footer
  *and* into the run's console summary, the artifact's prerequisites: whether a network is
  required, which companion files must travel with the entry point, and whether a build output is
  involved. AC-6 asks for the prerequisites to be explicit, not for them to be absent.
- **Reference layout.** This SPEC is written against a **local-vendored** layout — assets beside
  the entry point, no network at load — because that is the only layout with no runtime
  prerequisite at all, and because FR-16's third recorded consequence directs the research to
  prefer vendoring where interaction quality is comparable. A CDN layout stays admissible under
  FR-16; its cost is enumerated below so the choice is made with the bill in hand.

#### Validator surface — what changes with feature-002's answer

REQUIREMENTS.md §5.6 consequence 1 requires the shared validators to be *parameterised, not
weakened*, with `kb.html` keeping every check unchanged. Owning that parameterisation is
**feature-011's** job; naming precisely which assertions need it is this SPEC's. Read against the
scripts as they actually are:

| Assertion | Verdict for `graph.html` | Depends on feature-002? |
|-----------|--------------------------|-------------------------|
| **S2** (`validate-html-output.sh`, "Offline render") | Greps for `<script src="http…">` and `<link href="http…">`. Under the reference local-vendored layout it **passes unchanged**. It fails **by design only if the chosen packaging actually references a CDN**. | Yes |
| **NM** (`validate-html-output.sh`, "No-Mermaid-engine assertion") | All three sub-checks are keyed on the literal token `mermaid`: NM.1 needs a non-`text/markdown` inline `<script>` over 100 KB whose text contains `mermaid`; NM.2 needs `mermaid.initialize(`; NM.3 needs a CDN `<script src>` whose URL contains `mermaid`. A non-Mermaid graph renderer trips **none** of them, so NM **passes unchanged**. | Yes — only if the adopted bundle matches one of those literal patterns |
| **S7 / T1–T4** (`validate-visuals.mjs`) | Its collector walks `.diagram-box`, `.infographic`, and **every `<svg>`**. A live force-directed graph would be collected if drawn in SVG, and would then fail **T2** (sibling `<g>` bounding boxes may not overlap by more than 20% of the smaller area) — overlapping groups are what a graph layout *is* — and can fail **T1** (rendered font-size ≥ 10 px) for node labels at low zoom. A `<canvas>` or WebGL surface is **not** collected at all. | **Yes — this is the sharpest renderer dependency in the SPEC** |
| **S7 hermetic render** (`validate-visuals.mjs`) | It aborts every request whose URL does not start with `file://`. A CDN layout therefore renders **without its renderer** under the visual gate and cannot pass it. | Yes |
| **A1–A5, H1, L1, L2, C1, C2** | Pass by construction for any renderer; see the reuse table above. L2 resolves `href="./x.md"` against the HTML file's own directory, and `graph.html` sits beside `relationships.md`, so citing the source table by relative link resolves. | No |

Concretely: **if feature-002 recommends SVG, `validate-visuals.mjs` needs a parameterised
exclusion for the live graph surface; if it recommends Canvas or WebGL, no S7 exemption is needed
because the collector never sees the surface.** Either way the graph must keep any *authored*
visual (the legend, an infographic) inside the gate — the exclusion is for the live drawing
surface, not for the page.

One further consequence worth recording, because it is packaging-driven rather than
renderer-driven: the local dashboard server serves a **closed leaf allowlist** of `home.html` and
`kb.html` and sets `default-src 'self'` in its Content-Security-Policy header. `graph.html` is
therefore not reachable through the dashboard today, and a CDN-fetching layout would additionally
be blocked by that CSP if it ever were. This SPEC's entry point is a local `file://` open; adding
a dashboard route is a dashboard change and is out of scope for this work (§4).

### API Contracts

The store is the only interface feature-008 and feature-009 hold against this feature. It is a
plain module — no framework, no build step of its own, ES module syntax per the project's JS
conventions (`coding-standards.md` § JavaScript / Node Conventions).

```js
// graph-model.js — the whole surface feature-008 and feature-009 may use.

parseRelationships(markdownText)        // -> GraphModel        (throws on malformed input)
project(graphModel, lensState)          // -> ViewModel         (pure)
PRESETS                                 // frozen preset -> Partial<LensState>
INITIAL_LENS                            // frozen LensState, preset: null
RELATION_CATEGORY                       // frozen relation -> category (FR-6)

createStore(graphModel, initialLens)    // -> Store
// Store:
//   getViewModel()        -> ViewModel   (current projection)
//   getLens()             -> LensState   (frozen copy; mutating it does nothing)
//   setLens(patch)        -> ViewModel   (shallow merge, re-project, notify, return the new VM)
//   applyPreset(name)     -> ViewModel   (setLens(PRESETS[name]) plus preset: name)
//   subscribe(listener)   -> unsubscribe
//     listener(viewModel, lensState, changedKeys)
```

**Coverage is not on this surface.** `coverageGaps` and `coverageOrigin` reach feature-008 and
feature-009 as `ViewModel` fields, exactly as before; the functions that produce them live in
`coverage-predicate.mjs`, which the renderings never call directly. Neither consumer's contract
changed when the predicate moved there — which is why neither SPEC needed rewriting for it.

Four rules bind every consumer, and together they are what make NFR-3 and AC-7 mechanical:

1. **Render from `ViewModel`, never from `LensState`.** A renderer may read `lensState` only for
   its own private field (`zoom` for the graph, `sort` for the table). Deciding membership or
   emphasis from `LensState` re-implements `project()` and is the exact drift NFR-3 forbids.
2. **`project()` stays pure.** No DOM, no `Date`, no `Math.random`, no layout measurement. This is
   what lets the same `LensState` be asserted against both renderings in a test with no browser.
3. **Notification is synchronous and total.** Every subscriber is called on every change, with the
   same `ViewModel` instance. A renderer may debounce its own *drawing*, but not its reading —
   which is how a graph that skips frames still never shows a different edge set from the table.
4. **`ViewModel` is treated as frozen.** Consumers do not mutate it; ordering (`visibleEdges` by
   `row`) and labels (`nodeLabels`) are shared values, and a renderer that adjusts them locally
   makes the two surfaces disagree about what a node is called.

**Test hook for AC-7.** Because the store is pure and headless, the per-lens obligation is a plain
assertion rather than a UI walk: for each of the four presets, project it over a fixture and assert
(a) the projection differs from the initial projection — "each visibly changes the view" — and
(b) the same `ViewModel` drives both renderings, so a lens that changes one changes the other.
Suites live under `tests/canonical/` as `test-*.sh` files, which is how the runner discovers them
(`technology-stack.md` § Test Commands); the Node validators they invoke require Node ≥ 20, the
floor the validator tooling's own `package.json` declares (**C-5**).

### UI Specs

#### Component breakdown

| Component | Role | Notes |
|-----------|------|-------|
| Skip link | First focusable element, `class="skip-link"` href to the main region | Reused; asserted by the structural check in `validate-html-output.sh` |
| Top bar | `<header role="banner">` — title, breadcrumb, theme toggle | Structure and classes mirror the summary shell; A1.2 asserts the role |
| Lens bar | Four preset buttons, each a real `<button>` in a `<nav aria-label="Preset lenses">` | `aria-pressed` reflects `lensState.preset`; never `disabled` (AC-8) |
| Control panel | Grouping `<select>`, density `<input type="range" min="1" max="5">`, three filter fieldsets, a text `<input type="search">`, focus-node combobox, depth stepper | Every control has a real `<label for>`; all remain enabled at all times (FR-14) |
| Graph region | `<section aria-label="Relationship graph">` wrapping the drawing surface | Owned by feature-008 |
| Table region | `<section aria-label="Relationship table">` wrapping the peer table | Owned by feature-009 |
| Legend | A `.diagram-box` mapping each `glyph` and each provenance marker to its meaning, and — when the set is non-empty — reporting the zero-row node count and what it means | Authored visual; stays inside the S7 gate. The zero-row count is reported here and in feature-009's captions, i.e. through the ordinary reporting channel, never through the integrity alarm |
| Integrity banner | A `.callout.err` region with `role="alert"`, first child of `<main>`, present but empty at load and filled only on a `kb_gaps` mismatch | Not dismissible; degrades to `.callout.warn` when `kb_gaps` is absent. Reuses an existing style; adds no colour token |
| Status line | One `aria-live="polite"` region carrying `viewModel.announcement` | The page's only *polite* region; the integrity banner is the only other live region |
| Footer | Generation stamp, the relative link to `./relationships.md`, and the AC-6 prerequisites | L2 resolves the link against the file's own directory |
| `<noscript>` | Explains that the view needs script and links `./relationships.md` and `./INDEX.md` | Asserted by the structural check; and it is the honest answer to FR-17 |

Both regions are present in the DOM at all times and neither is nested inside the other — the
table is a sibling of the graph, not a child, which is the structural form of "peer rendering"
(NFR-2). Their order is graph-then-table on wide viewports and table-then-graph below the mobile
breakpoint; DOM order is table-first, with the visual order set in CSS, so tab order reaches the
usable-everywhere surface first without either region being hidden.

#### State management

One store, one `ViewModel`, no component-local copies of anything in `LensState`. Controls are
uncontrolled inputs whose values are written into the store on `change`/`input`; the store's
notification then reconciles every control's displayed value against `lensState`, so a preset
button and a slider can never disagree about the current density. Nothing is persisted between
loads except the theme, which stays on the existing shared `aid-dashboard-theme` key so the graph,
the summary, and the dashboard agree — a new key would visibly desynchronise them.

#### Responsive behaviour

Mobile breakpoint is 768 px and the max content width is 1200 px, matching
`design-tokens.md` § "Spacing & sizing" — the graph must not introduce a second breakpoint scale.
Below the breakpoint the control panel collapses into a `<details>` disclosure and the grid
collapses to a single column. The two widths the visual gate measures at are 732 px and 390 px,
so those are the two the layout is checked against; no region may overflow its own container
horizontally at either (T4).

#### Design-token integration

`graph-css.css` uses `var(--token)` exclusively and adds **no colour token**. The graph's five
semantic roles map onto tokens already in the palette and already contrast-checked: `--accent` for
focus and selection, `--ok` for well-formed structure, `--warn` for `kb-unbacked`, `--err` for
`int-undocumented`, `--purple` for `inferred` provenance, with `--text-dim` for dimmed marks.
Because each is already covered by a pair in `contrast-check.mjs`, C1/C2 keep passing without new
pairs being added to the script. Any inline SVG the graph authors uses `fill="var(--token)"` rather
than a hex literal, per `design-tokens.md`, so both themes work from one authoring.

#### Accessibility

NFR-1 sets WCAG AA. The criteria this feature is answerable for, and how:

| Criterion | How this feature satisfies it |
|-----------|------------------------------|
| 1.3.1 Info & Relationships | Real landmarks and real controls; the table is a real `<table>` (feature-009), and the two regions are siblings |
| 2.1.1 Keyboard | Every control is a native element; nothing is pointer-only. Zoom and pan keyboard equivalents are feature-008's, per NFR-6 |
| 2.4.7 Focus Visible | The reused `:focus-visible` rule from `component-css.css`; asserted by A5 |
| 2.4.11 Focus Not Obscured | The top bar is sticky, so scroll-into-view uses `scroll-margin-top` on focusable targets sized to the ~60 px bar |
| 1.4.3 / 1.4.11 Contrast | Tokens only; C1/C2 verify both themes |
| 4.1.3 Status Messages | Two live regions and no more: one `aria-live="polite"`, written once per lens change from `viewModel.announcement`; one `role="alert"`, present-but-empty at load and written at most once, for the `kb_gaps` integrity failure |
| 1.1.1 Non-text Content | Every authored visual carries a text alternative; the legend states each glyph in words |
| Reduced motion | The reused `@media (prefers-reduced-motion: reduce)` block; the settled-layout obligation is feature-008's (NFR-4, AC-9) |

**Granularity, deliberately.** Following the research's warning against one tab stop per datum,
the shell exposes the *aggregates* — the lens bar, the controls, each group, and the focused node —
as tab stops, and lets the table carry the raw rows. That keeps announcements useful at Overview
density, where a per-node tab order would be hundreds of stops deep and would say almost nothing.

### Deliberately left open

Three items are contracts here and content later, plus one closed on 2026-07-28 that leaves a
residual obligation on another feature. Each is scheduled rather than unresolved, so `/aid-detail`
can sequence the work.

| # | Open item | Closes when | Blocks |
|---|---|---|---|
| 1 | `COVERAGE_BEARING`'s membership and `RELATION_CATEGORY`'s contents | feature-001's relation-vocabulary research lands (D-1). Both are enumerated *by pair name* once the closed vocabulary exists; GV04 and GV05 then become runnable. | The task that authors `coverage-predicate.mjs`, not this SPEC |
| 2 | Which Node shape feature-006 gives its detector — Bash CLI over a thin `.mjs`, or `.mjs` outright | feature-006 repoints its D2 and L2 at `coverage-predicate.mjs`. Either shape satisfies the boundary; this SPEC assumes the first because it leaves feature-006's stated interface and exit contract intact. | Nothing here — the module's contract is identical under both |
| 3 | `kb_gaps`'s candidate set and entry shape — **decided 2026-07-28**, computed over feature-004's enumerated node set with every entry carrying `id` **and** `name`. Listed because the decision leaves a live obligation on another feature, not because it is unsettled | feature-006's frontmatter writer emits `name` | This SPEC's zero-row handling: without `name`, such a node has no display name anywhere |
| 4 | Whether `validate-visuals.mjs` needs a parameterised exclusion for the live drawing surface | feature-002 names the renderer (see § "Validator surface"). | feature-011, which owns the parameterisation |

Three things are **not** open and are recorded so they are not reopened, all owner decisions of
2026-07-28: the module's identity and its Node/browser boundary; AC-15's scope — the equality binds
the `int:` class only; and that a zero-row node is an expected asymmetry the integrity alarm never
fires on, surfaced through the union rather than through equality.
