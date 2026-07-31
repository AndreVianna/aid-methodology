# Interactive Node Panel

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §5 (FR-3 layer 2), §6 note, §10 | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |
| 2026-07-25 | Review fix round 1 — Header.astro, getNodeClasses and Banner.astro citations corrected | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-3 (**the click-to-open panel**; the in-node derived label belongs to
  feature-003 and the verbatim fragment + deep link to feature-005), §6 (known implementation
  cost note), §10 Priority (Should)

> **Scope is settled.** The panel applies to nodes in every chart, doorway pages included, since
> FR-6 was **owner-confirmed** at cross-reference (Q2, 2026-07-25). No re-scoping is pending.
>
> **Rendering substrate.** `astro-mermaid` is already the site's live diagram pipeline
> (configured in `site/astro.config.mjs`, rendering 11 blocks across four pages), so the
> node-interaction implementation depends on whether feature-003 keeps that runtime path or
> adopts D-012's build-time inline SVG — the two expose different DOM hooks.

## Description

Polish on top of feature-005's guaranteed reachability: selecting a node in the chart opens a
panel showing that node's verbatim fragment and its `canonical/` deep link, in place, without
leaving the chart.

This is the acknowledged **custom-JavaScript** cost of FR-3 — the site's diagram rendering
provides no node interaction — and it is deliberately sequenced last because the below-chart
list from feature-005 already satisfies AC-5.

If the owner confirms §10's straw-manned Must/Should split, this stays a **Should**. Given the
overall High priority it is a promotion candidate, and the decomposition supports promoting it
without reshaping anything.

## User Stories

- As an **AID maintainer**, I want to click a node and read its exact wording without losing my
  place in a 12-node chart.
- As a **newcomer to the repo**, I want the chart to be explorable rather than a static picture
  with a wall of text underneath.

## Priority

Should

## Acceptance Criteria

*(Synthesized — §9 is silent here by design, since FR-3's panel is a Should.)*

- [ ] Given any node in a chart, when it is selected, then a panel opens showing that node's
      verbatim fragment and its source deep link.
- [ ] Given JavaScript is unavailable, when the page renders, then feature-005's below-chart
      list is still present and functional, so AC-5 holds without this feature.
- [ ] Given this feature lands, when the site builds, then it adds no runtime dependency beyond
      what `site/` already carries, except as §7 permits.

---

## Technical Specification

> Grounded in: **feature-003's SPEC** (the rendering substrate and hooks **H1–H5**, the
> `FlowChart` / `FlowNode` / `Provenance` model, the sidecar — binding, not re-litigated here),
> **feature-005's SPEC** (the below-chart fragment list, the deep-link contract, and the four
> constraints it places on this feature), **feature-001's SPEC** (the `.md` output contract, the
> `SkillRecord`, `generatedFrom`, the build-console contract, and the explicit statement that
> this feature has no `body.mjs` entry), **feature-002's SPEC** (co-ownership of
> `site/astro.config.mjs`), **feature-004's SPEC** (doorway charts expose the same hooks);
> REQUIREMENTS.md §5 FR-3 / FR-6, §6 NFR-1 / NFR-2 / NFR-3 and its known-implementation-cost
> note, §7, §9 AC-5 / AC-7, §10; `.aid/knowledge/` — `INDEX.md`, `architecture.md`,
> `coding-standards.md` (§ JavaScript / Node Conventions, § Logging and Output),
> `technology-stack.md`, `test-landscape.md`, `integration-map.md` (§ MCP and Playwright);
> and direct reading of `site/astro.config.mjs`, `site/package.json`, `site/tsconfig.json`,
> `site/.nvmrc`, `.gitattributes`, `.github/workflows/docs.yml`,
> `site/src/components/overrides/{Header,PageTitle}.astro`,
> `site/src/components/{Banner,ReportForm}.astro`, `site/src/content.config.ts`,
> `site/public/`, plus the locked installs of `astro-mermaid` 2.0.2, `mermaid` 11.15.0 and
> `@astrojs/starlight` 0.39.3 (read from the **main checkout's** `site/node_modules/`; all three
> are absent from this worktree's partial install, as are `astro` and its tsconfigs — the same
> condition feature-001 records in § Build-integration scope, Part C, and feature-005 in its own
> grounding note).
>
> **Cross-reference convention (inherited from feature-005, § Technical Specification preamble).**
> Citations into **sibling SPECs** name a stable anchor — a section heading, a hook or rule name
> (`H1`–`H5`, `S2`, `V7`), or a schema field — never a line number. Citations into **code, config
> and vendored packages** keep line numbers; every one below was read in this session.
>
> **Two `feature-NNN` numbering collisions, both pre-existing.** `site/src/content.config.ts`
> 12, 14 and 16, and `site/astro.config.mjs` 13–17 and 141–143, label slots for a **previous**
> work's features 005/006/008/009/010. Feature-001 records this (§ Data Model, the boxed note); it
> is restated here because this feature edits `astro.config.mjs`, and the reserved `Banner` /
> `Footer` / `Hero` slots in that comment are **not** this work's and must not be reused. See
> KI-013.

FR-3's panel is the only part of this work that runs in a browser. Everything else in the
delivery is a build-time text transform. This feature therefore owns exactly three artifacts —
**a mount** (one Starlight component override), **a data island** (a per-page JSON projection of
feature-003's sidecar), and **a client controller** (one vanilla-ESM file plus its stylesheet) —
and it changes no generator, no page bytes, and no markdown.

It derives no chart, renders no diagram, emits no page markdown, and reads no `canonical/` file.

### Data Model

**No schema changes, no persisted artifact, no manifest entry, no content-collection change.**
`site/src/content.config.ts` is not modified: the gate below reads the `generatedFrom` field the
schema already declares (`content.config.ts` 15, under the misleading comment at 14) and
feature-001 already emits (§ Output contract, the page-shape block). `site/package.json` gains no
script key and no `dependencies` entry, so the `prebuild` / `predev` chains are untouched.

#### Consumed contracts (unchanged by this feature)

| Contract | Owner | Where |
|---|---|---|
| `FlowChart.nodes` ordered by `order`, ascending, no gaps | feature-003 | § `FlowChart` (the `nodes` row) |
| `FlowNode` = `{ id, order, name, label, kind, terminal, provenance, detail }`; `id` matches `^[A-Za-z][A-Za-z0-9_]{0,31}$` and is DOM-id-safe | feature-003 | § `FlowNode` |
| `Provenance` = `{ file, startLine, endLine, sourceKind, excerpt }`, verified byte-equal to the file slice at build time | feature-003 § `Provenance`; verified by feature-005 § Telemetry & Tracking (checks **P0–P6**) |
| `<skill>.flow.json` at `site/src/data/skill-flows/` — the node record | feature-003 | § Serialization; § UI Specs → hook **H4**; seam **S2** |
| `H1` readiness, `H2` id template, `H3` `g.node.aidNode`, `H5` re-render caveat | feature-003 | § UI Specs → Hooks this gives feature-006 |
| `#fragment-<nodeId>` per-entry anchor | feature-005 | § Entry anatomy (the Anchor row) |
| `blobUrl()` / `lineAnchor()` — deep-link construction, path-charset guard | feature-005 | § Layers & Components (Public API) |
| Pages are `.md`; no per-page component import; attach at the site level | feature-001 | § Output contract |
| This feature has **no** `BODY_PROVIDERS` / `BODY_APPENDERS` entry | feature-001 | § Body slot; § Module layout (the `body.mjs` row) |
| `generatedFrom: 'canonical/skills/<dir>/SKILL.md'` on every generated skill page | feature-001 | § Output contract |

#### What this feature adds — `FlowProjection`

One in-memory shape, computed at build time in the override and serialized into the page as a
JSON island. It is a **projection of the sidecar**, never a second model:

```ts
type PanelSource = { file: string; startLine: number; endLine: number; url: string };

type PanelNode = {
  id: string;              // FlowNode.id            — also the #fragment-<id> anchor suffix
  order: number;           // FlowNode.order         — 1-based chart position
  name: string;            // FlowNode.name          — verbatim state name
  label: string;           // FlowNode.label         — derived, <= 60 code points
  kind: string;            // FlowNode.kind          — closed enum
  exit: string | null;     // node.terminal?.advanceType ?? null — closed enum, exits only
  fragment: string;        // provenance.excerpt     — byte-for-byte
  source: PanelSource;     // from provenance,  url = blobUrl(file, startLine, endLine)
  detail: PanelSource | null; // from node.detail, link only — it carries no excerpt by contract
};

type FlowProjection = { v: 1; skill: string; confidence: string; nodes: PanelNode[] };
```

- **`v` is a schema version, and it is load-bearing.** The client controller ships from
  `site/public/`, which Astro copies verbatim and does not content-hash, so a browser can hold a
  stale copy after a deploy. The controller refuses to run unless `v === 1`. That makes the
  stale-asset failure mode provably benign: the page falls back to its no-JavaScript behaviour
  (feature-005's list) rather than mis-rendering. A schema change bumps `v` and the old
  controller no-ops.
- **`url` is not re-derived here.** It is `blobUrl(file, startLine, endLine)` imported from
  feature-005's `site/scripts/lib/provenance/deep-link.mjs`, so the panel's link and the list's
  `[Source: …]` link have one authority and cannot disagree about the `#L<a>-L<b>` form. The
  import is build-time only (Astro component frontmatter never reaches the client) and is safe
  because feature-005 guarantees "pure exported functions with no import-time side effect"
  (§ Layers & Components, Conventions followed) and feature-001 guarantees the same for
  `paths.mjs` (§ Module layout, "Two deliberate divergences").
- **Deliberately excluded**, to hold page weight down: `edges[]` (and therefore every
  `FlowEdge.provenance.excerpt`), `sources`, `warnings`, `entries`, `exits`, `title`, `shape`,
  `extractor`. The panel is **node-indexed**; a self-edge (feature-003 § The Advance-clause
  parser, **rule 5**) adds nothing to it, exactly as it adds no entry to feature-005's list.
  Edge conditions stay where feature-005 also left them: on the chart.

**Accepted cost, stated not hidden.** `fragment` duplicates text that feature-005 already put in
the page, so a skill page carries each excerpt twice. Three things bound it: the projection omits
edge excerpts (the larger half of the sidecar); the two copies are near-identical text inside one
HTTP response, so the compressed transfer cost is far below the byte doubling even though the
parse cost is real; and a `<script type="application/json">` is not rendered text, so Pagefind
does not index it and feature-005's OQ-1 search concern is not made worse. The alternative —
cloning the rendered list entry — is **forbidden** by feature-005 (§ Coexistence with feature-006,
and the no-JavaScript guarantee, third constraint: feature-006 "must **not** read the list's DOM
as a data source"), and rightly: it would freeze that markup.

### Feature Flow

Two phases. Nothing in phase 1 depends on this feature's own code running; nothing in phase 2 runs
at all unless the reader has JavaScript.

```
BUILD  (astro build, after prebuild has run gen:skills)
  page render for src/content/docs/skills/<skill>.md
        │
        ▼
  Head override  (site/src/components/overrides/Head.astro)
        1. <Default />                                  ← Starlight's own Head, unchanged
        2. shouldMount(entry.data.generatedFrom, sidecars)   → skill dir | null
             └─ null  → emit nothing.  END.  (every non-skill page takes this branch)
        3. load site/src/data/skill-flows/<skill>.flow.json  (import.meta.glob, build-time)
        4. buildProjection(chart)  → FlowProjection      (blobUrl from feature-005)
        5. embedJson(projection)   → JSON with every '<' escaped as \u003c
        6. emit three tags into <head>:
             <link rel="stylesheet" href="{base}skill-node-panel.css">
             <script type="application/json" id="aid-flow-data" set:html={json}></script>
             <script type="module" is:inline src="{base}skill-node-panel.mjs"></script>

RUNTIME  (browser, generated skill detail page only)
  module script (deferred by definition) runs after HTML parse
        │
        1. read + parse #aid-flow-data ; bail unless v === 1
        2. for the chart container (pre.mermaid inside .sl-markdown-content):
             a. install the delegated click + keydown listeners on the CONTAINER
             b. install a MutationObserver on the container (attributeFilter: data-processed)
             c. THEN check the current state  ← install-before-check closes the race
        3. on each readiness transition: decorate every g.node.aidNode
             (tabindex / role / aria-label / aria-expanded / aria-controls / data-aid-node)
        4. on activation: fill and reveal the panel from the projection — never from the DOM
```

Step 8 of feature-003's flow (browser-side mermaid rendering) is the thing phase 2 waits on. It
is the **only** thing it waits on, and every way that wait can fail is enumerated in
§ UI Specs → Degradation.

### Layers & Components

#### Module layout

| File | State | Purpose |
|---|---|---|
| `site/src/components/overrides/Head.astro` | **new** | The mount. Renders Starlight's default `Head`, then the three tags above when the gate passes. Sits beside the two existing overrides (`Header.astro`, `PageTitle.astro`). |
| `site/src/lib/skill-node-panel.ts` | **new** | The pure build-time half: `shouldMount()`, `buildProjection()`, `embedJson()`. TypeScript, so `astro check` covers it and vitest can import it without a DOM. |
| `site/public/skill-node-panel.mjs` | **new** | The client controller. Vanilla ESM, **no imports, no fetch, no storage**. |
| `site/public/skill-node-panel.css` | **new** | Panel + node-focus styles. |
| `site/src/lib/__tests__/skill-node-panel.test.ts` | **new** | Pure-logic suite (default `node` environment). |
| `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | **new** | Lifecycle / ARIA suite (`// @vitest-environment jsdom`). |
| `site/astro.config.mjs` | **edited** | **One** added key in the existing `components:` map. |
| `site/package.json` | **edited** | **One** added `devDependencies` entry: `jsdom`. |

Public API — signatures only:

```ts
shouldMount(generatedFrom: string | undefined, known: Set<string>): string | null
buildProjection(chart: FlowChart): FlowProjection
embedJson(projection: FlowProjection): string      // JSON.stringify, then '<' -> '\u003c'
```

**Ownership.** Everything above is feature-006's except the two edited files. No file owned by
feature-003, 004 or 005 is modified; `deep-link.mjs` is consumed read-only. `body.mjs` is not
touched — feature-001 § Body slot states this feature has no entry there, and it does not.

#### Decision — how the script is delivered

**Chosen: a Starlight `Head` component override, gated per page, emitting one `is:inline` module
script that points at a file in `site/public/`.**

Feature-001 § Output contract hands this feature two options ("a Starlight component override or
a `head` entry in `astro.config.mjs`"). The grounds for the override, and for narrowing it
further, are all checkable:

1. **The site already overrides Starlight components, and `Head` is safe to compose with.**
   `astro.config.mjs` 144–153 maps `Header`, `PageTitle`, `Banner` and `Footer`, so adding a
   fifth override is a familiar edit rather than a new mechanism. The specific move this design
   makes — rendering the override target's **own packaged default** and appending to it — rests
   on two checked facts about the package, not on a precedent in this repo: Starlight's `exports`
   map publishes `"./components/*"` (verified in `@astrojs/starlight/package.json`), so
   `@astrojs/starlight/components/Head.astro` resolves; and that file is a **five-line
   pass-through** whose entire body is
   `{head.map(({ tag: Tag, attrs, content }) => <Tag {...attrs} set:html={content} />)}` over
   `Astro.locals.starlightRoute.head`. Composing with it therefore preserves Starlight's head
   output exactly, and reimplementing those five lines would be a copy that silently rots.

   *A note on what the neighbouring overrides do and do not show.* `Header.astro` is **not** an
   example of this pattern: it is a complete reimplementation that never renders a default
   `<Header />`. Its comment at 8–10 documents a *different* convention — importing the
   individual Starlight built-ins it is **not** overriding (`Search.astro`, `ThemeSelect.astro`)
   so their behaviour and types stay intact. That convention supports the weaker claim that
   importing from the package inside an override is normal here; it is not evidence for
   composing with the override target's own default, and this SPEC does not lean on it for that.
2. **A `head:` entry in `astro.config.mjs` is unconditional.** Starlight's `head` option is a
   static array applied to every page; it has no route predicate, so it would ship the script to
   the whole site. Rejected on that alone.
3. **The gate is a data test, not a path test, and the anchors are load-bearing.**
   `shouldMount()` matches `entry.data.generatedFrom` against
   `^canonical/skills/([a-z0-9]+(?:-[a-z0-9]+)*)/SKILL\.md$` — feature-001 § Route and path
   derivation verified that every skill directory matches that charset — and then requires a
   sidecar to exist for the captured name. That is strictly better than
   `pathname.startsWith('/skills/')`, and the exclusions are measured rather than assumed. Four
   pages on the site carry `generatedFrom` today (measured 2026-07-25):
   `reference/agents.md`, `reference/kb.md`, `reference/settings.md` and `reference/skills.md`,
   at line 4 of each. Three cite a path outside `canonical/skills/`; the fourth is
   `'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'`, which the
   pattern rejects on the `*` and on the trailing second source — and that is the **same string**
   feature-002's index page will carry (§ Migration Plan → **Manifest participation**: "identical
   to the index page's own `generatedFrom` value"), so `/skills/index.md` is excluded by the same
   anchor rather than by a special case. The gate is also independent of `base`, and it fails
   closed if the sidecars have not been generated yet — so this feature can land in any order
   relative to 003/005 without breaking a build.
4. **`is:inline` is what makes the gate observable.** Astro's processed `<script>` tags are
   collected and attached per page from the build's module graph, so a processed script inside a
   `{condition && …}` block in a component that renders on **every** page is not reliably
   excluded from the pages where the condition is false. `is:inline` opts the tag out of
   processing entirely — it is emitted exactly like ordinary HTML, so the runtime conditional
   genuinely controls whether it appears. The result is verifiable by grepping
   `site/dist/**/*.html`, which is what the delivery-gate check does.

   `Banner.astro` 17 already puts a `<script is:inline>` inside a runtime conditional, so the
   construct is established in this codebase — but **for a different reason, and the distinction
   matters**. Banner's own comment at 16 says "blocking inline script: hide iff this tag was
   already dismissed": it needs `is:inline` so the tag executes *synchronously, in place, before
   first paint*, which is what prevents an already-dismissed banner from flashing. This feature
   wants the opposite of blocking — its script is `type="module"` and therefore deferred — and
   uses `is:inline` purely so that the emitted HTML is a faithful record of the gate. The two
   uses share a directive and an effect (the tag appears only when the branch renders); they do
   not share a motivation, and neither one's justification transfers to the other.
5. **Why the scoping matters, beyond bytes.** The site carries 28 non-skill doc pages today
   (measured 2026-07-25 — a dated diagnostic, not a contract), four of which contain fenced
   mermaid blocks: `index.mdx` (1), `concepts/methodology.md` (7), `guides/pipeline.mdx` (1),
   `guides/maintainer.mdx` (2). Those are hand-authored charts whose nodes carry **no** `aidNode`
   class and have **no** sidecar, so an ungated controller would decorate nothing there — but it
   would still install listeners, an observer and a stylesheet on pages this work has no business
   touching, and any future defect in it would land on pages §7 requires to keep working
   unchanged. Gating removes that blast radius rather than arguing about it.

**Rejected, one line each.** A `head:` entry in `astro.config.mjs` (unconditional — see 2). A
`head:` key written into every generated page's frontmatter by feature-001's renderer (it would
change feature-001's fixed page shape and move a site concern into generator output bytes, for no
gain over an override). Overriding `MarkdownContent` instead (it would put the tags in the
content column, where a `<link rel="stylesheet">` is non-conforming, and buy nothing). Bundling
the controller as a processed `<script>` in a component (see 4). Fetching the sidecar at runtime
from `site/public/` (feature-003 seam **S2** already rejected that location precisely because it
costs "a network round-trip per page", and it would put a second copy of the data in the repo).

**Cost accepted:** a `public/` asset is not bundled, not minified and not content-hashed, and
`astro check` does not type-check it (`site/tsconfig.json` extends `astro/tsconfigs/strict`,
whose base sets `allowJs: true` but not `checkJs`, so the file is included in the program and not
checked). Mitigations, all real: the pure logic lives in the type-checked `.ts` module beside it;
the controller is small vanilla ESM with a vitest suite of its own; `.gitattributes` 10
(`*.mjs text eol=lf`) already pins its line endings; and cache staleness is disarmed by the `v`
check above.

#### Safety of an override that renders on every page

`Head` is rendered by every page of the site, so §7's "the existing `site/` build and its four
generated reference pages must keep working unchanged" is at stake in this one file. Three
properties make that bearable, and each is a design constraint on the override rather than an
observation:

- **The failing path does no work.** `shouldMount()` is a regex match plus a `Set.has`, with no
  I/O; when it returns `null` the component emits `<Default />` and nothing else, and never awaits
  the sidecar. A page with no `generatedFrom` — every hand-authored page on the site — takes that
  branch.
- **The sidecar load is build-time and server-only.** `import.meta.glob('../../data/skill-flows/*.flow.json', { import: 'default' })` is evaluated in the component's frontmatter, which Astro
  strips from the client, so no flow JSON and no glob machinery reaches a browser on any page.
  If the directory does not exist yet — this feature landing before feature-003's generator does
  — the glob is an empty object, every gate returns `null`, and the override is inert rather than
  broken.
- **Nothing in the override can throw.** The only operations on the mounting path are a `JSON`
  serialization of an object the sidecar already round-tripped and a `blobUrl` call whose input
  feature-005's verifier has already accepted at generation time. There is no `readFileSync`, no
  network, no `process.env`.

Verifying it is a build and a grep, and that is what AC-6.5's delivery-gate check is.

#### Seams and cross-feature edits

- **S6-1 — one key in `components:`.** `astro.config.mjs`'s map is owned by that file
  (12–17, 139–153) and its comment says to *add* keys, never rewrite the map. This feature adds
  exactly `Head: './src/components/overrides/Head.astro'`. Feature-002 states its own edit to
  this file "is confined to the `sidebar` array" and that it touches "any component" not at all
  (§ Migration Plan → What is touched, exhaustively), so the two edits are in different literals.
  With feature-003's OQ-1 (the KI-001 `themeVariables` fix) that makes **three** possible editors
  of one file in this work; as feature-002 already noted for its own case, they should be
  sequenced rather than applied concurrently. The map comment itself is stale (it claims the map
  is empty and reserves slots for another work's features) — KI-013.
- **S6-2 — one `devDependencies` entry.** `jsdom`, for the DOM suite; justified under § Test
  layer. `dependencies` is unchanged, which is the half §7 constrains.
- **S6-3 — read-only consumption of feature-005.** `blobUrl` from
  `site/scripts/lib/provenance/deep-link.mjs`. If feature-005 relocates that module, this
  override's import moves with it; nothing else couples.
- **S6-4 — read-only consumption of feature-003's sidecar** at the **S2** location. If
  feature-001 relocates it (feature-003 § Seam required from feature-001, S2, reserves that
  right), only the `import.meta.glob` pattern changes.

**Rollback** is four deletions and two one-line reverts: remove the `Head` key from
`astro.config.mjs`, remove `jsdom` from `package.json`, delete the override, the `.ts` module,
the two `public/` files and the two test files. No generated page, no manifest, no markdown and
no other feature's file changes, so nothing else in the work depends on this feature being
present — which is exactly the separability §10's Should/Must split assumes.

#### Conventions followed

`coding-standards.md` § JavaScript / Node Conventions with the directory-local divergence
feature-001 records (§ Module layout, "Two deliberate divergences") and feature-005 restates:
**2-space indentation**, matching every file already under `site/src/`, not the tab rule mined
from `canonical/aid/scripts/summarize/*.mjs`. ESM throughout; kebab-case filenames; pure exported
functions with no import-time side effect in the `.ts` module. `process.exit` codes and the
`node:` import scheme do not apply — no file in this feature is a Node entrypoint. The client
controller is written to the same plain-DOM style as the site's two existing client scripts
(`ReportForm.astro` 149–233 and `Banner.astro` 17–29): an IIFE-scoped module, `querySelector`,
`addEventListener`, no framework, no dependency.

#### Test layer

Two new files under `site/src/lib/__tests__/`, run by the site's existing `npm test` →
`vitest run` (`site/package.json` 20). Like feature-005's suite, they become enforceable on pull
requests only once feature-001's CI step lands (feature-001 § Build-integration scope, Part B;
KI-006), and they are subject to the same environmental caveat feature-001 records in Part C —
the TypeScript suites in this directory cannot load in this worktree because `node_modules/astro`
is absent, and a clean `npm ci` fixes it.

**What the runner can and cannot do, stated plainly.** `site/` has **no** `vitest.config.*` file
(verified: `astro.config.mjs` is the only `*.config.*` in the directory), so vitest runs in its
default `node` environment — there is no `document`, no `MutationObserver`, no focus model. Half
of this feature is DOM lifecycle. Two honest options existed:

| Option | Verdict |
|---|---|
| **`jsdom` as a devDependency**, one file opted in with `// @vitest-environment jsdom` | **Chosen.** One devDependency, no browser download, no CI step, seconds of runtime. It cannot run mermaid — and does not need to: the fixture reproduces the exact rendered shape verified below, and *tests build their own fixtures* per the tracking rule. |
| **Playwright** (vitest browser mode, or a standalone spec) | **Rejected as an automated gate.** It is genuinely new to `site/`: `docs.yml` has no browser step and would need `npx playwright install chromium` on every PR. §7's "except where FR-3's node interaction requires it" is an allowance for a *runtime* dependency, and this is not one. Playwright already exists in the repo's other CI lane — `technology-stack.md` records it as the "headless visual-fidelity gate", and `test-landscape.md` § CI Lanes and Where They Run lists a `visual-fidelity` (Playwright) job in `test.yml` — which is why the manual check below is credible without adding a second browser lane. (`docs.yml` was read directly for this feature; `test.yml` was not, so that lane is cited from the KB rather than from source.) |

**The mermaid facts the fixture encodes, each verified against the locked install
(`mermaid` 11.15.0, read from the main checkout):**

- A node's group element is `<g class="node default aidNode" id="flowchart-<id>-<n>">`. In full,
  `getNodeClasses` is

  ```js
  (node, extra) => (node.look === "handDrawn" ? "rough-node" : "node") + " " + node.cssClasses + " " + (extra || "")
  ```

  (`dist/chunks/mermaid.esm/chunk-HQMLCRZ6.mjs` 128), and the flow parser sets
  `cssClasses = "default " + vertex.classes.join(" ")`
  (`dist/chunks/mermaid.esm/flowDiagram-3HAHYXQ6.mjs` 909), where `vertex.classes` is what a
  `class n7 aidNode` statement pushes (`setClass`, same file 426–441). The renderer writes both
  attributes together — `.attr("class", getNodeClasses(node)).attr("id", node.domId ?? node.id)`
  (`chunk-HQMLCRZ6.mjs` 943, 1025, 1649, 1739, 2585 — one call site per shape).

  Two parts of that expression are quoted but inert here, and both are stated rather than
  elided. Every flowchart call site above invokes `getNodeClasses(node)` with a single argument,
  so `extra` is `undefined`, `(extra || "")` is `""`, and it contributes only a trailing space.
  The `handDrawn` branch cannot be reached on
  these pages: `look` is an optional config key (`dist/config.type.d.ts` 76,
  `look?: 'classic' | 'handDrawn' | 'neo'`) that must be opted into explicitly, and nothing in
  this pipeline does — `astro.config.mjs` 30–47 passes no `mermaidConfig`, so the client
  initialize call is `{ startOnLoad: false, theme, gitGraph: {…} }`
  (`astro-mermaid-integration.js` 362–366, 401–410), and feature-003 § Chart presentation fixes
  the fence contents (dialect, node shapes, `classDef`, edge forms) with no `look` directive and
  no frontmatter config block. Worth noting for a future reader: the branch swaps the `node`
  token for `rough-node` and leaves `node.cssClasses` — and therefore `aidNode` — in place
  either way, so if mermaid's look ever changed the failure mode would be the resolve-or-skip
  path below (zero nodes matched, one warning, no panel), not a mis-resolved node.
- `domId = "flowchart-" + id + "-" + vertexCounter` (`flowDiagram-3HAHYXQ6.mjs` 60, 187).
- Layer order inside the SVG is `clusters`, `edgePaths`, `edgeLabels`, `nodes`
  (`dist/chunks/mermaid.esm/dagre-ZXKKJJHT.mjs` 451–454), so **nodes paint last**.

| Group | Covers | Environment |
|---|---|---|
| **Gate** | `shouldMount()` against: a real skill `generatedFrom`; a `reference/*.md` page's `generatedFrom`; `undefined`; a skill name absent from the sidecar set; a name failing the charset. Returns the dir name or `null`. | node |
| **Projection** | `buildProjection()` on an inline `FlowChart` fixture: field set is exactly `PanelNode`'s (assert no `edges`/`warnings`/`sources` key survives anywhere in the JSON); `nodes` keeps chart array order without re-sorting; `fragment === provenance.excerpt` byte-for-byte; `source.url === blobUrl(...)` for both the single-line and multi-line anchor forms; `detail` is `null` or link-only. | node |
| **Embedding** | `embedJson()` output contains no literal `<`; `JSON.parse` of it round-trips to a deep-equal object; fixtures include a fragment containing `</script>`, `<!--`, `<div>`, a 4-backtick run, a pipe, `{braces}` and a lone surrogate-safe `—`. | node |
| **Controller — source shape** | The text of `site/public/skill-node-panel.mjs` contains no `import ` statement, no `fetch(`, no `localStorage`, no `innerHTML`, no `eval`/`new Function`. This is the mechanically checkable half of "no new runtime dependency" and of the XSS rule. | node |
| **Activation (AC-6.1)** | Fixture: a `pre.mermaid[data-processed]` containing a synthetic SVG in the verified shape, a JSON island, and **no fragment list at all**. Clicking a node reveals the panel with that node's `name`, `label`, `kind`, and a `<pre>` whose `textContent === projection fragment`; the `[Source]` href equals `source.url`; the `full step` link appears iff `detail !== null`; the `#fragment-<id>` link is present. Omitting the list is the point: it *proves* the data path does not run through feature-005's DOM. | jsdom |
| **Keyboard + ARIA (AC-6.2)** | Every decorated node has `role="button"`, `tabindex="0"`, a non-empty `aria-label`, `aria-controls` = the panel id, and `aria-expanded` tracking open state. `Enter` and `Space` open; `Space` calls `preventDefault`; `Escape` closes and resets `aria-expanded`; re-activating the open node toggles it closed. | jsdom |
| **Re-render survival (AC-6.3)** | Simulate the theme observer exactly as `astro-mermaid-integration.js` 466–473 and 435–436 do it, in that order: remove `data-processed`, replace the container's `innerHTML` with a fresh SVG, set `data-processed` again. Assert every new node is decorated, and that **one** activation produces **one** panel-open (a counting spy on the panel's reveal) — the duplicate-handler guard. Repeat three cycles. | jsdom |
| **Degradation (AC-6.4)** | (a) container has no `data-processed` → no decoration, no panel, no throw; (b) `data-processed` set **after** the controller loads → decoration happens on the mutation; (c) `data-processed` set with an error `<div>` and **no** `<svg>` (the failed-render shape, `astro-mermaid-integration.js` 438–452) → no decoration, no panel, exactly one `console.warn`. | jsdom |
| **Resolve-or-skip** | A `g.node.aidNode` whose `id` does not match the template, and one whose recovered id is absent from the projection: both are left undecorated; siblings still work; one `console.warn` per page, not per node. | jsdom |
| **Schema guard** | `v: 2` in the island → the controller no-ops entirely and warns once. | jsdom |

**What is verified by hand, once, at the delivery gate — and why.** Focus *placement* is not
asserted in jsdom: jsdom's focusable-area model does not reliably treat an SVG `<g>` carrying
`tabindex` as focusable, so `document.activeElement` there would prove nothing about a browser.
The jsdom suite therefore asserts the *attributes and state* that make focus possible, and the
following are checked once, manually, in a real browser, recorded like feature-005's AC-7 (a
dated note in the work folder with a Pass / Pass-with-observations / Fail verdict):

1. Tab reaches every chart node in document order; the focus ring is visible in both themes.
2. Opening moves focus to the panel; `Escape` returns it to the invoking node.
3. A screen reader announces the node's `aria-label` and the panel's heading.
4. The layout is usable at a 360 px viewport.
5. `test-landscape.md` § Known Test Gaps (the "Web-output review" row: any review touching the
   site "MUST visually validate via Playwright") is satisfied by doing 1–4 through the MCP the repo
   already configures (`integration-map.md` § MCP and Playwright) — a review action, not a new
   dependency and not a CI job.

#### Acceptance criteria — testable form

The three criteria above the line remain this feature's criteria. These are their operational
form; each names its gate.

| # | Criterion | Maps to | Gate |
|---|---|---|---|
| **AC-6.1** | Given a rendered chart, when a node is activated by pointer or keyboard, then a panel opens showing that node's `name`, derived `label`, byte-exact verbatim fragment and a `canonical/` deep link equal to feature-005's `blobUrl` for the same range. | criterion 1 | vitest — Activation, Projection |
| **AC-6.2** | Given any node the panel can be opened on by pointer, then it is also reachable by Tab, operable by `Enter`/`Space`, dismissible by `Escape`, and exposes `role="button"` with a non-empty accessible name and an `aria-expanded` that tracks state. | criterion 1 (accessibility of "selected") | vitest — Keyboard + ARIA; focus placement manual |
| **AC-6.3** | Given a theme switch that destroys and rebuilds the SVG, when a node is then activated once, then the panel opens exactly once and every node is interactive again. | criterion 1 under H5 | vitest — Re-render survival |
| **AC-6.4** | Given no JavaScript, JavaScript before mermaid has rendered, or a mermaid render that failed, then no panel exists, nothing throws, and feature-005's below-chart list is present and functional. | criterion 2 | vitest — Degradation; plus feature-005's own No-JS invariant row |
| **AC-6.5** | Given a full build, then every generated skill detail page references the controller exactly once and **no** other page in `dist/` references it at all. | criterion 3 (blast radius) | vitest — Gate (the pure predicate); a `dist/**/*.html` grep at the delivery gate |
| **AC-6.6** | Given this feature lands, then `site/package.json` `dependencies` is unmodified, the one added `devDependencies` entry is `jsdom`, and the delivered client asset performs no import, no fetch and no storage access. | criterion 3 | vitest — Controller source shape; diff review |

AC-6.4 is the criterion that keeps this feature honest: it is the machine-checkable statement
that a **Should** cannot damage the **Must** underneath it.

### State Machines

*Activated because the hard problem in this feature is a lifecycle, not a rendering. Feature-003
hook **H5** hands over the delegation requirement but explicitly leaves attach / re-attach /
duplicate-suppression to this SPEC, and the substrate destroys the DOM this feature decorates on
every theme change.*

#### Why a lifecycle exists at all

Three facts, all read from `site/node_modules/astro-mermaid/astro-mermaid-integration.js` 2.0.2:

1. **Rendering is asynchronous and the script order is not fixed.** The integration injects its
   client script with `injectScript('page', …)` (line 500) — on *every* page — and that script
   imports mermaid lazily and renders in an `async` loop (324–359, 375–454). This controller is a
   deferred module script. Which finishes first is not defined, so readiness must be *observed*
   (H1), and the observer must be installed **before** the current state is sampled.
2. **A theme change destroys the SVG.** The integration's `MutationObserver` on `data-theme`
   strips `data-processed` from every `pre.mermaid` and calls `initMermaid()` (466–487), which
   assigns `diagram.innerHTML = svg` (435). Everything inside the container — every listener
   bound to a node — is discarded. The container element itself survives, which is why H5
   mandates delegation on it.
3. **`data-processed` means "attempted", not "rendered".** On a render failure the integration
   replaces the content with an error `<div>` and still sets `data-processed="true"` (438–452).
   A consumer that treats the attribute as "an SVG exists" is wrong. See **KI-011**.

#### Per-container attachment machine

One instance per `pre.mermaid` element. Containers are tracked in a module-level `WeakSet`, not by
a DOM attribute: the set keys on element identity, so a container that survives a theme change is
recognised as already bound, while a container in a document replaced by `astro:after-swap` is a
different object and binds cleanly. That single choice is the duplicate-handler guard.

| State | Entered when | What is true |
|---|---|---|
| `UNBOUND` | initial | No listeners, no observer. |
| `BOUND_PENDING` | `bind(container)` ran | Delegated `click` + `keydown` on the container; `MutationObserver(attributeFilter: ['data-processed'])` on the container. No node is decorated. |
| `BOUND_READY` | a readiness transition resolved ≥ 1 node | Every resolvable `g.node.aidNode` carries the interaction attributes; the panel element exists as the container's next sibling. |
| `BOUND_INERT` | readiness fired but no `<svg>`, or zero ids resolved | Bound, decorated nothing, warned once. Page behaves as if this feature were absent. |

| Transition | Trigger | Action |
|---|---|---|
| `UNBOUND → BOUND_PENDING` | controller init, or `astro:after-swap` re-scan | Install listeners, then the observer, **then** sample state (order is the race fix). |
| `BOUND_PENDING → BOUND_READY` | `data-processed` present **and** `container.querySelector('svg')` non-null **and** ≥ 1 id resolved | Create the panel on first entry; decorate. |
| `BOUND_PENDING → BOUND_INERT` | `data-processed` present, guard fails | One `console.warn`; no further work for this container. |
| `BOUND_READY → BOUND_PENDING` | `data-processed` removed (theme switch, step 1 of the integration's re-render) | Nothing is torn down. Decoration on the doomed subtree is left alone: it costs nothing, and an activation during the window still works, **because the panel's content comes from the projection and never from the SVG.** |
| `BOUND_READY → BOUND_READY` | `data-processed` re-added | Re-decorate the new subtree. Idempotent: a node already carrying `data-aid-node` is skipped, so a spurious or duplicated mutation cannot double-decorate. This also absorbs **KI-014** (the integration has no re-entrancy guard, so two rapid theme toggles can interleave two render loops and fire the transition twice). |
| any → any | panel open across a re-render | The open node id is re-resolved in the new subtree and `aria-expanded="true"` is re-applied there. The panel stays open with valid content. If the id no longer exists, the panel closes and focus is not moved. |

**`astro:after-swap` is registered and currently inert.** The controller listens for it and
re-scans, mirroring what the integration does (`astro-mermaid-integration.js` 491–497). It will
not fire today: the site enables no view transitions — there is no `<ClientRouter />` or
`<ViewTransitions />` anywhere under `site/src/` or in `astro.config.mjs` (measured 2026-07-25).
It is registered anyway because the cost is one listener and the alternative is a silent
regression the day Starlight or this site turns view transitions on. Stated as inert rather than
claimed as working, because an untriggerable path is untested by definition.

**One chart per page is an assumption with a guard.** Feature-001's body slot admits exactly one
`BODY_PROVIDERS` result (§ Body slot, "first match wins"), and 003/004 each emit one fence, so a
skill page carries one `pre.mermaid`. The controller binds the first one inside
`.sl-markdown-content`; if it finds more, it binds the first, leaves the rest alone, and emits
the `panel container` warning rather than guessing which chart the single projection describes.

Listeners are attached **once per container**, never per node: `click` and `keydown` both resolve
their target with `event.target.closest('g.node.aidNode')`. Two consequences worth stating:

- Because mermaid paints the `nodes` layer last (`dagre-ZXKKJJHT.mjs` 451–454), an edge can never
  steal a pointer event from a node. **Self-edges** — which feature-003's rule 5 emits and
  feature-004 renders as `n8 -.-> n8` (§ UI Specs, item 3) — are drawn in `edgePaths`, *under*
  the node. A click on the visible arc outside the node shape therefore resolves to `null` and is
  ignored, which is the correct behaviour: a self-edge is not a node.
- `closest()` is defined on `Element`, so it works from an SVG `<text>`, `<tspan>` or
  `foreignObject` descendant up to the node group. Clicking a node's label works.

#### Node identification — the class hook, and how the id is recovered

**Selection uses `g.node.aidNode` (H3), not the `flowchart-<nodeId>-<n>` id template (H2).**
Four reasons, in descending weight:

1. **The `-<n>` suffix is a parser-call counter, not a model value.** `this.vertexCounter++` runs
   on *every* `addVertex` call (`flowDiagram-3HAHYXQ6.mjs` 187, 193), including the calls an edge
   statement makes for nodes that already exist. Nothing in feature-003's `FlowChart` predicts it.
2. **One query instead of N.** The class selects the whole node set without knowing the id set in
   advance, so decoration is a single `querySelectorAll` rather than one prefix query per node.
3. **It is a hook feature-003 owns and guarantees** for both authored charts (H3) and doorway
   charts (feature-004 § UI Specs: doorway nodes carry "the same `class … aidNode` statement
   (H3)"), whereas the id template is mermaid's internal detail — verified at 11.15.0, but not a
   contract that version pins.
4. **It excludes foreign diagrams.** Should a skill page ever carry a second, non-generated
   mermaid block, its nodes have no `aidNode` class and are not touched.

**Id recovery** still needs the DOM id, because the `class n7 aidNode` statement puts `aidNode`
into the class list but not `n7` (`setClass` pushes only the class name —
`flowDiagram-3HAHYXQ6.mjs` 426–441). So:

```
id = /^flowchart-([A-Za-z][A-Za-z0-9_]{0,31})-\d+$/.exec(el.id)?.[1]
```

The capture group **is** feature-003's `FlowNode.id` charset (§ `FlowNode`, the `id` row), which
contains no `-`, so the split is unambiguous and `flowchart-n7-1` can never be confused with
`flowchart-n71-5`. Anchoring at `^flowchart-` is safe: `lookUpDomId` in the same file (133–144)
shows a conditional `<diagramId>-` prefix exists for gen-1 tooltip/click lookups, but the
renderer takes `node.domId` (911, and `chunk-HQMLCRZ6.mjs` 943) which is the unprefixed form.

**Resolve-or-skip is the contract.** The recovered id is looked up in the projection's `nodes[]`
by `id` (hook **H4** — "no SVG text scraping, no re-parse of `canonical/`"). A node whose id does
not match the pattern, or does not resolve, is **left undecorated**: it gets no `tabindex`, no
`role`, and cannot be activated. It never produces a broken panel. If **zero** nodes resolve for
a container, the container goes `BOUND_INERT` with one warning. That converts every conceivable
drift in mermaid's id template into "the panel silently isn't there" — the same state a reader
without JavaScript is in, and one feature-005's list already covers.

#### Panel machine

| State | `hidden` | `aria-expanded` on nodes | Focus |
|---|---|---|---|
| `CLOSED` | true | all `false` | untouched |
| `OPEN(nodeId)` | false | `true` on that node only | on the panel container (`tabindex="-1"`) |

| Transition | Trigger |
|---|---|
| `CLOSED → OPEN(a)` | click / `Enter` / `Space` on node `a` |
| `OPEN(a) → OPEN(b)` | activation of a different node — content is refilled, focus returns to the panel |
| `OPEN(a) → CLOSED` | activation of `a` again (toggle), the close button, or `Escape` while focus is inside the panel or on a node |
| `OPEN(a) → CLOSED` | the open node disappears from the DOM and cannot be re-resolved after a re-render |

Not a dismissal trigger: **clicking elsewhere on the page.** The panel is non-modal and sits in
the document flow; a reader scrolling to feature-005's list to compare, or selecting text
anywhere, must not lose it. Rejected explicitly rather than omitted.

### UI Specs

*Activated because what the reader sees, how it is operated without a mouse, and how it fails are
the substance of this feature — and because feature-005 § Coexistence with feature-006, and the
no-JavaScript guarantee makes some of that a cross-feature contract rather than a local choice.*

**How the panel discharges §6.** NFR-1 keeps the *chart* scannable by capping the in-node text at
a ~60-character derived label and says completeness "is served by the panel" — so the panel is
where the length budget is spent, and nothing here shortens, wraps or summarizes the fragment.
NFR-2's "nothing lost" is satisfied twice over on every skill page: once by feature-005's list
and once, on demand and in place, by this panel; the panel is the *convenient* copy, never the
only one. NFR-3's interpretation risk is why the panel puts the derived `label` and the verbatim
`fragment` in the same view, with the `canonical/` deep link beneath both as the final authority —
a reader who distrusts the label can falsify it without leaving the paragraph.

#### Where the panel renders

The controller creates one panel per bound container and inserts it as the container's **next
sibling**, inside `.sl-markdown-content`. So it appears directly beneath the chart, above
feature-005's `## Source fragments` section — "in place, without leaving the chart", as the
Description asks.

It is not server-rendered. An empty hidden shell in the page would serve nobody: without
JavaScript there is nothing to fill it, and its presence would be one more thing to keep correct.
Creating it on first successful decoration means the no-JavaScript page and the mermaid-failed
page are byte-identical in the region below the chart.

#### Anatomy

```html
<div class="aid-node-panel" id="aid-node-panel-1" tabindex="-1" hidden>
  <div class="aid-node-panel__bar">
    <h3 id="aid-node-panel-1-title">
      <span class="aid-node-panel__order">3</span>
      <code>CONTINUE</code>
      <span class="aid-node-panel__kind">decision</span>
      <span class="aid-node-panel__exit">PAUSE-FOR-USER-DECISION</span>
    </h3>
    <button type="button" class="aid-node-panel__close" aria-label="Close step details">…</button>
  </div>
  <p class="aid-node-panel__label">Resume the conversational interview</p>
  <pre class="aid-node-panel__fragment"><code>| CONTINUE | `references/…` | … |</code></pre>
  <p class="aid-node-panel__links">
    <a href="https://github.com/…/SKILL.md#L275">Source: canonical/…/SKILL.md#L275</a>
    <a href="https://github.com/…/state-continue.md#L1-L43">full step</a>
    <a href="#fragment-n3">show in the list below</a>
  </p>
</div>
```

| Element | Content | Rule |
|---|---|---|
| order / name / kind / exit | `order`, `name`, `kind`, `exit` from the projection | Written with `textContent`. `name` in a `<code>`; `exit` rendered only when non-null. |
| label | `label` | `textContent`. The derived interpretation, ≤ 60 code points by feature-003's **V8**. |
| fragment | `fragment` | `textContent` on the inner `<code>`. Byte-for-byte `provenance.excerpt`. No highlighting: a syntax grammar reinterpreting the one text whose literalness is the point is the same trap feature-005 rejected (§ The verbatim-versus-safe-rendering resolution, **Language, meta and wrapping**). |
| source link | `source.url` | Same tab, same as feature-005's list links. |
| detail link | `detail.url`, rendered only when `detail !== null` | Link only, never inlined — `detail` carries no excerpt by contract (feature-003 § `Provenance`). |
| list link | `#fragment-<id>` | Feature-005's provided hook (§ Coexistence with feature-006, fourth bullet). It is a plain in-page anchor; the panel does not read anything at that target. |
| heading level | `h3` | Semantically under the chart's `## Flow` H2. Starlight builds its table of contents from the markdown at build time, so a DOM-inserted heading cannot pollute it. |

#### Accessibility

The chart is an image to a screen reader and a dead zone to a keyboard user. A click-only
affordance on a documentation site would therefore make the *chart* less accessible than the
static page it replaced — so keyboard parity is a requirement here, not a nicety.

- **Pattern: disclosure, not dialog.** Each node is the disclosure control
  (`role="button"`, `tabindex="0"`, `aria-expanded`, `aria-controls="<panel id>"`); the panel is
  the disclosed region. One panel is shared by all nodes, and only the open node carries
  `aria-expanded="true"`. **Rejected: `<dialog>` / `role="dialog"` with `aria-modal`** — a modal
  would hide the chart and the list behind it, which directly contradicts "without losing my
  place", and it would oblige a focus trap.
- **No focus trap, deliberately.** The panel is non-modal and in the document flow; Tab out of it
  continues into the page, which is what a reader comparing the panel against the list below
  actually wants. Trapping focus on a docs page is hostile, and there is nothing to trap it *for*
  — no state is lost by leaving.
- **Focus is still managed.** Opening moves focus to the panel container (which carries
  `tabindex="-1"`), so the content is announced and the close button is one Tab away; the browser
  scrolls it minimally into view, which is also the correct small-screen behaviour and is why no
  `preventScroll` is used. `Escape` and the close button return focus to the invoking node, guarded
  by a re-resolution in case a theme re-render replaced it.
- **Accessible names are composed, not scraped.** `aria-label` on each node is
  `"Step <order>: <name> — <label>"`, plus `" (exit: <advanceType>)"` when `exit` is non-null.
  Mermaid renders the two-line node text as `<tspan>`s or a `foreignObject` (feature-003 emits
  `"NAME<br/>label"`, § Chart presentation), so the computed name from content would be
  unreliable and unpunctuated. The label overrides it with text taken from the projection.
- **Keys.** `Enter` and `Space` activate; `Space` calls `preventDefault()` so the page does not
  scroll. `Escape` closes. No other key is bound, and no key is intercepted globally.
- **Focus visibility.** `:focus-visible` styling is applied to the node group and, as a
  belt-and-braces measure for engines with patchy `outline` support on SVG, also to its child
  shape via a stroke change. Both are colour-and-width changes; there is no animation, so
  `prefers-reduced-motion` needs no special case.
- **Contrast.** Focus and open-state indication use stroke width plus a colour drawn from the
  casulo tokens already defined in `src/styles/casulo.css` (`--casulo-accent-glow` 37,
  `--casulo-border-accent` 40, `--casulo-radius-sm` 42) and Starlight's own `--sl-color-*`
  variables, so they track both themes without a second palette. KI-001 does not reach here: this
  is CSS, not mermaid `themeVariables`.

#### Small screens

The panel is in normal flow, so it stacks under the chart at any width and needs no positioning,
no overlay and no scroll lock. Below the site's existing narrow breakpoint it goes full-bleed
within the content column; the fragment block is capped (`max-height` with `overflow:auto`) so a
long dispatch row cannot push feature-005's list off the screen, and wraps
(`white-space: pre-wrap; overflow-wrap: anywhere`) rather than scrolling horizontally — the same
readability choice feature-005 makes with its `wrap` meta option (§ The
verbatim-versus-safe-rendering resolution, **Language, meta and wrapping**).
**Rejected: a fixed bottom sheet** — it would need a scroll lock and a dismissal overlay, i.e. the
modal complexity the disclosure pattern exists to avoid.

#### Degradation — three paths, all ending at feature-005's list

| Path | What the reader gets | Why it holds |
|---|---|---|
| **No JavaScript** | The `<pre class="mermaid">` shows the escaped `flowchart TB …` source inside the integration's shimmer placeholder (KI-004), and the full `## Source fragments` list below it: every node's position, name, label, verbatim fragment and deep link, as ordinary HTML. | The list is static markdown emitted **unconditionally** at build time (feature-005 § Coexistence with feature-006, first constraint). This feature adds no `<script>` the list depends on, and applies **no** collapsing — the second constraint permits runtime, reversible collapsing, and this SPEC declines to use it: hiding the evidence NFR-2 requires would be a poor trade for a scroll saving. |
| **JavaScript, before mermaid has rendered** | Same as above, transiently; the panel appears the moment the chart does. | The observer is installed *before* the state is sampled, so a render that completes in the gap between script parse and check is caught by the mutation rather than missed. Nothing polls, and nothing times out. |
| **Mermaid failed to render** | The integration's red error box (`astro-mermaid-integration.js` 438–452), plus the complete list. | The readiness guard requires `data-processed` **and** an `<svg>` child **and** at least one resolvable id. The failure shape satisfies only the first, so the container goes `BOUND_INERT`, one warning is logged, and no panel is created. KI-011. |

AC-5 is untouched in all three, because AC-5 is satisfied by markup this feature never writes and
never reads. That is the whole reason FR-3's panel could be sequenced last.

### Security Specs

*Activated because this feature is the first in the work to put arbitrary `canonical/` prompt
text into a `<script>` element and then back into the DOM. Feature-005 solved the same corpus's
markdown-containment problem; the script-context and DOM-injection problems are new, and they are
the kind that fail silently and badly.*

| Surface | Rule | Basis |
|---|---|---|
| JSON island | After `JSON.stringify`, **every `<` is replaced with `\u003c`**. In `stringify` output a `<` can only occur inside a JSON string — a key or a value — and `\u003c` is a valid escape in both, so the transform is lossless and `JSON.parse` round-trips to a deep-equal object. It closes `</script>` and `<!--` with one rule rather than two. | `astro-mermaid-integration.js` 22–26 applies the same class of guard (`sanitizeJsonForScript`) with two targeted regexes; the single-character rule is a strict superset. |
| Island emission | `set:html` on the `<script type="application/json">`, not an interpolated child. | The HTML parser does **not** decode character references inside a raw-text element, so an escaped `{json}` expression would be read back with literal `&amp;` and fail to parse. `set:html` emits the string as authored. |
| Island reading | `JSON.parse(el.textContent)` inside `try/catch`; a parse failure warns once and no-ops. | Fail-closed to the no-JavaScript state. |
| DOM writing | **`textContent` and `createElement` only. No `innerHTML`, anywhere, ever** — the fragment is arbitrary repository text and will contain `<`, `&` and complete code fences. Enforced by the source-shape test. | Same reasoning that made feature-005 choose a fence over escaping. |
| Link hrefs | Only `source.url` / `detail.url` from the projection, and `#fragment-<id>`. No user input, no `javascript:` reachable: `blobUrl` already throws on any character outside `[A-Za-z0-9._/-]`, on `..`, and on a leading `/` (feature-005 § External Integrations, Path safety), and `<id>` is constrained by feature-003's id charset. | Reuse, not reinvention. |
| Code execution | No `eval`, no `new Function`, no dynamic `import()`, no `fetch`, no `localStorage`/`sessionStorage`, no cookie. The controller is a leaf. | Asserted by the source-shape test. |
| Content Security Policy | The site sets no CSP today. If one is added later, this feature needs only `script-src 'self'` and `style-src 'self'`: the script and the stylesheet are both same-origin files, and **no style is injected from JavaScript**. | This is why the CSS is a `public/*.css` linked in `<head>` rather than a `<style>` element built at runtime the way `astro-mermaid-integration.js` 503–583 does it. |

### Telemetry & Tracking

*Activated for the same reason feature-001 and feature-005 activate it: the diagnostics are the
contract. Theirs is a build console; this is the only part of the work whose diagnostics land in
a reader's browser, where noise is permanent and unreviewable.*

No analytics, no beacon, no network call, no storage. The panel is inert until activated and
leaves no trace when closed.

| Channel | Contract |
|---|---|
| Build console | **Nothing added.** This feature contributes no generator code, so feature-001's "exactly four lines per successful run" stdout contract (§ Telemetry & Tracking, the stdout row) is untouched, and `gen:skills` behaviour is unchanged. |
| Browser console, success | **Silent.** No `console.log` in the shipped controller. |
| Browser console, failure | `console.warn('[aid-node-panel] <guard>: <detail>')`, **at most once per guard per page**. Never `throw` — `init()` is wrapped so an unexpected error degrades to the no-JavaScript state instead of leaving half-decorated nodes. |
| Guard names (new, stable, greppable, assertable) | `panel schema` (`v !== 1`), `panel data` (island missing or unparseable), `panel container` (more than one `pre.mermaid` on the page — the first is bound, the rest are left alone), `panel nodes` (readiness reached but nothing resolvable). |
| Exit codes | Not applicable — nothing in this feature is a Node entrypoint. |

Guard names follow the same discipline feature-001 sets (§ Telemetry & Tracking, the Failures
row: "Guard names are stable strings") so a test can assert on them; the prefix is
`[aid-node-panel]` rather than `[gen-skills]` because this code does not run inside that
generator.

**Pre-existing noise this feature does not create and cannot fix from here:**
`astro-mermaid`'s `enableLog` defaults to `true` (`astro-mermaid-integration.js` 229–235,
specifically 234) and
`astro.config.mjs` 30–47 does not set it, so its client script logs `[astro-mermaid] …` on
**every page of the site**, including a "No mermaid diagrams found on initial load" line on pages
that have none (312, 457–462; the script is injected page-wide at 500). Registered as **KI-012**;
the one-line fix belongs to whoever next edits that options object.

### Open Questions

- **OQ-1 — Is one new devDependency (`jsdom`) acceptable, or should the DOM lifecycle go
  untested?** §7 allows "no new runtime beyond what `site/` already depends on"; `jsdom` is a
  test-only dependency that never ships, so this SPEC reads it as outside that prohibition and
  takes it. The
  alternative is a node-only suite that covers the projection and the pure predicates but leaves
  event delegation, the re-attachment lifecycle and every ARIA attribute unverified — which is
  most of the risk in this feature. **Owner decision:** accept `jsdom`, or accept the coverage
  gap. (A third option, Playwright in `docs.yml`, is rejected in § Test layer on CI cost; if the
  owner wants a real-browser gate instead, that is a larger decision than this feature.)
- **OQ-2 — Should the panel be promoted from Should to Must?** §10 flags it as a promotion
  candidate given the work's overall High priority, and this SPEC is written so promotion changes
  nothing structural — only the sequencing and the delivery gate's tolerance for dropping it.
  Recorded because §10 asked for it to be revisited, not because anything here depends on it.
- **OQ-3 — Who performs the manual browser check, and does a Fail block the gate?** § Test layer
  specifies four browser-only checks (focus order, focus return, screen-reader announcement,
  360 px layout) recorded like feature-005's AC-7. Unlike AC-7 these are *accessibility*
  findings, not comprehension judgements, so "non-blocking" is not obviously right: a keyboard
  trap or an unreachable node is a defect, while an imperfect focus ring is not. **Owner
  decision:** the severity line, and which human runs it. This SPEC's default is that checks 1–3
  are blocking and check 4 is an observation.
- **OQ-4 — Three features now edit `site/astro.config.mjs`.** Feature-002 (one sidebar group),
  this feature (one `components:` key), and — if feature-003's OQ-1 is answered "fix it here" —
  the KI-001 `themeVariables` repair. The three edits are in three different literals and do not
  conflict semantically, but they should be **sequenced** rather than made concurrently by
  parallel agents. Feature-002 raised the same point for the two it knew about; this is the third.
