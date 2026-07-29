---
delivery_state: Executing
gate_tier: Small | Medium | Large
gate_grade: "{grade or Pending}"
gate_timestamp: "{YYYY-MM-DDTHH:MM:SSZ}"
ticket_ref: "--"
---

# Delivery State -- delivery-005

[!NOTE]
This is the DELIVERY-LEVEL STATE.md. It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`.
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated -> Done, or to Blocked
Enum members: Pending-Spec | Specified | Executing | Gated | Done | Blocked
This authored state is NOT a derivation of child task states. A delivery may be Pending-Spec
with ZERO tasks; the `_none yet_` rollup below is correct and expected for a new delivery.
-->

> **Delivery:** delivery-005
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-005

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. The **State** scalar lives in the
     YAML frontmatter block at the top of this file (`delivery_state`). -->

- **Updated:** 2026-07-26T15:10:51Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block
     at the top of this file (`gate_tier`, `gate_grade`, `gate_timestamp`). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

### Q1 — feature-006 OQ-1: is one test-only devDependency (`jsdom`) acceptable?

- **Category:** Requirements (dependency policy)
- **Impact:** Required — task-045 cannot be Done until this is recorded either way
- **State:** Answered
- **Context:** REQUIREMENTS §7 permits a new dependency only "where FR-3's node interaction
  requires it". `jsdom` never ships to a browser, so feature-006's SPEC reads it as outside that
  prohibition. The stake is explicit and pre-approved: **if declined, delivery-005 is DROPPED**
  rather than shipped with its DOM lifecycle untested, because a node-only suite would leave
  event delegation, the re-attachment lifecycle and every ARIA attribute unverified — most of
  the risk in this feature. Dropping is cheap: delivery-005 is a *Should*, nothing depends on
  it, AC-5 is already discharged by delivery-004's static list.
- **Answer:** **Accepted.** Owner approved `jsdom` as a test-only devDependency at the start of
  this run, in the same pass that settled the other four run-level decisions. `dependencies`
  stays untouched; Playwright remains rejected as an automated gate.
- **Applied to:** task-045; `site/package.json` `devDependencies`.

### Q2 — do the four manual browser checks block this gate?

- **Category:** Process
- **Impact:** Medium
- **State:** Answered
- **Context:** `BLUEPRINT.md` § Gate Criteria carries feature-006's default: the three
  accessibility checks block the gate and the 360 px layout check is an observation. That
  default assumes the person running the gate can drive a browser.
- **Answer:** **Non-blocking, all four.** The owner will run them after the gate. This is an
  owner override of feature-006's default, taken deliberately at the start of the run so the
  pipeline does not stall waiting on a human at the last gate. The checks are still *performed
  and recorded* — just not as a gate precondition. A failure files a ticket.
- **Applied to:** the gate criterion above; the reviewer is briefed not to grade on their absence.

### Q3 — task-045's "no `vitest.config.*`" premise is stale

- **Category:** Requirements (AC-vs-reality)
- **Impact:** Low
- **State:** Answered
- **Context:** task-045's DETAIL asserts "`site/` has **no `vitest.config.*`** … so vitest runs
  in its default `node` environment", and its AC says no such file is introduced. That was true
  when written, but **delivery-002 created `site/vitest.config.mjs`** to route KI-016 (parallel
  workers regenerating the same tree, which flaked the idempotence suites).
- **Answer:** No conflict in substance, and the AC's intent is intact. Delivery-002 anticipated
  exactly this: its Q2 record states the config sets **only** `fileParallelism` and
  **deliberately does not set `environment`**, specifically so feature-006's per-file
  `// @vitest-environment jsdom` opt-in keeps working — and the file carries that reasoning in
  a comment. The runner default is still `node`, and task-045 introduces no config file. Read
  the AC as "the runner's default environment stays `node` and the opt-in is per-file", which
  holds.
- **Applied to:** task-045 acceptance interpretation; recorded here rather than editing the
  immutable DETAIL.

---

## Task Review Findings

<!-- AUTHORED -- per-task review outcomes recorded as each task closes. -->

### task-045 — `jsdom` devDependency and the DOM test environment

`jsdom@29.1.1` added as the single new `devDependencies` entry, with a caret range matching
`vitest` and the devDep majority. `dependencies` and `scripts` are byte-identical to HEAD
(compared programmatically, not by eye), the `prebuild`/`predev` chains are untouched,
`vitest.config.mjs` is unmodified, and the lock marks jsdom `dev: true` so it cannot reach a
production install.

Two things worth recording.

**The opt-in is guarded in both directions.** AC-4 asks only that the
`// @vitest-environment jsdom` mechanism be demonstrated so task-053 does not discover it
missing. A one-way demonstration would pass equally well if someone later set
`environment: 'jsdom'` globally in `vitest.config.mjs` — which is exactly the change that would
silently alter the other 40 suites. So there are two files:
`scripts/__tests__/jsdom-environment.test.mjs` opts in and asserts `document`, `window`,
`MutationObserver`, `getComputedStyle`, event dispatch and the focus model the Escape handler
needs; `scripts/__tests__/node-environment.test.mjs` carries no docblock and asserts `document`
and `window` are **absent**. The second is the half that fails if the default ever flips.

**The audit warning is pre-existing and not attributable to jsdom.** `npm audit` reports 10
advisories (1 low, 3 moderate, 6 high). Every advisory package is Astro-ecosystem —
`astro`, `@astrojs/starlight`, `@astrojs/mdx`, `astro-expressive-code`, `dompurify`, `fast-uri`,
`js-yaml`, `postcss`, `sharp`, `svgo`. None is in jsdom's dependency tree. Recorded rather than
acted on: upgrading the Astro toolchain is well outside this delivery.

**A false alarm worth noting so it is not re-investigated.** The first idempotence check
reported lockfile drift. It was not drift: `npm install --save-dev jsdom` had not written the
full transitive tree, and the following plain `npm install` completed it. Two consecutive
installs after that produce a byte-identical lockfile (diff of 0 lines).

The deferred clean-install check has since run: `npm ci` exits 0 from scratch and `jsdom@29.1.1`
resolves from the lock.

### task-046 — build-time panel logic, and an upstream defect it exposed

The module itself is right: `shouldMount` is a pure regex plus a `Set.has` with no I/O,
`buildProjection` imports `blobUrl` from delivery-004 rather than rebuilding a URL,
`embedJson` escapes `<` to `\u003c` losslessly, and `v: 1` is emitted. The deep field-set
exclusion is proven by walking the parsed JSON recursively rather than checking the top level,
and `embedJson` is proven by parse-back deep equality rather than containment.

**The important finding is upstream, and task-046 only made it visible.** Verifying
`shouldMount` against every `generatedFrom` value that actually exists on disk — rather than
against the fixtures — showed it admitting **34 of 111 skill pages**. The gate was correct;
the data was not. `CHARTABLE_SHAPES` in `gen-skills.mjs` still listed only feature-003's three
authored shapes, so **77 of the 111 skills carried a chart on the page but no sidecar**.

Two reasons this survived three delivery gates:

1. The constant carried a comment predicting its own fix — "feature-004 adds the two doorway
   shapes in tasks 035–037, at which point every skill charts and this set equals
   `SHAPE_ORDER`". Those tasks shipped in delivery-003 and the set was never widened.
2. Nothing could see it. The task-030 drift guard derives **both** its expected and its
   on-disk sidecar set from that same constant, so the omission was self-consistent. The
   test asserting sidecar coverage carried its **own second copy** of the three-shape list and
   an assertion that doorway skills have no sidecar — so production and test agreed with each
   other and both were wrong. I had even seen "34 sidecars" while measuring the cache in
   delivery-004 and did not follow it up.

Fixed by deriving `CHARTABLE_SHAPES` from `SHAPE_ORDER`, which removes the second list that
could drift. Sidecars are now 111, the manifest lists 111, and `shouldMount` admits exactly
111 pages. The test was rewritten to read the shape list from the manifest — computed from the
live classifier — and to assert one sidecar per skill against the directory enumeration.

Proven, not assumed: restoring the stale constant now produces **7 test failures** and makes
`gen-skills.mjs` itself **exit 1**, because the 77 sidecars become orphans and the drift guard
fires. The defect class is closed in both directions from here.

**Impact had it shipped:** delivery-005's first gate criterion is that selecting a node in
*any* chart opens a panel. The panel would have been absent from 77 of 111 pages, and the
route gate would have looked like the culprit.

### task-049 — client controller lifecycle, and a defect only the browser could show

The controller's structure is sound: the three-part readiness predicate is implemented as
KI-011 requires, binding is once-per-container via a `WeakSet` keyed on element identity,
decoration is idempotent through `data-aid-node`, and `init()` is wrapped so an unexpected
throw degrades to the no-JavaScript state.

**The defect: the node-id pattern matched nothing on a real page.** `ID_RE` was
`/^flowchart-([A-Za-z][A-Za-z0-9_]{0,31})-\d+$/`, anchored at the start. The ids mermaid
actually emits are `mermaid-<diagramId>-flowchart-<nodeId>-<n>` — measured on the running site
as `mermaid-rkijoq1pv-flowchart-n10-9`, with the diagram id differing on every render
(`11br4n7o5`, `rkijoq1pv`, `23qhs6d31` across three loads). The start anchor matched **0 of 10**
nodes. Every node would have failed to resolve, the container would have gone `BOUND_INERT`, and
the panel would never have opened on any page — while the unit suite stayed green.

It stayed green because the fixtures built ids as `flowchart-n1-0`, a format no page produces.
The suite tested a fiction consistently, so nothing inside it could disagree. This is the same
shape as KI-021 from wave 1: **an assumption held identically by the code and its tests is
invisible to those tests.**

Fixed by dropping the start anchor while keeping the end anchor, which leaves the capture
unambiguous — feature-003's id charset contains no `-`, so in `…-flowchart-n10-9` group 1 can
only be `n10`. All fixtures now carry a realistic diagram-id prefix, and a regression test pins
four ids **copied verbatim from rendered pages**, asserts the pattern is not start-anchored, and
asserts it is still end-anchored.

Proven: restoring the start anchor now fails **9 tests** including the dedicated real-id case,
where before the change the suite passed with the bug present.

**Not a defect: a chart that failed to render.** `aid-create-api` showed mermaid's "Syntax error
in text" on load, twice. Chased to ground because a broken chart would sink this delivery: the
generated source **parses and renders fine** when driven directly (a 200 KB SVG), the two
charts for `aid-add-api` and `aid-create-api` are byte-identical apart from one label, and with
the browser cache disabled the page renders perfectly. It was a stale cached page from an
earlier poisoned render — KI-018's family, not a regression, and not caused by anything in this
delivery. Worth recording that the KI-018 workaround is doing its job: `data-diagram` held the
correct source throughout.

### task-047 / task-048 — Head override, and a second seam mismatch

`Head.astro` is well-judged: it composes Starlight's packaged `Head` rather than replacing it,
so non-skill pages keep their output; the sidecar set comes from `import.meta.glob`, which is
frontmatter-only and so cannot reach a client bundle; and the gate fails closed when the glob
resolves empty. The `set:html` choice is correct for a reason worth keeping — the HTML parser
does not decode character references inside a raw-text element, so an interpolated `{expr}`
child would be read back with literal `&amp;` and fail to parse.

**The defect: the two halves disagreed on the island id.** `Head.astro` emits
`id="aid-flow-data"`, which is what feature-006's SPEC fixes. The controller from task-049 read
`getElementById('aid-panel-data')` — an id no page contains. It would have warned "island element
not found" and no-opped on every page.

This is the **second** instance in this delivery of the same failure mode, after the node-id
pattern: two halves written in parallel, each with its own fixtures, each passing its own suite
while contradicting the other. Testing each side against its own fixture cannot detect it.
Fixed on the controller side, since the SPEC and the emitting component already agreed.

Added a **cross-seam guard** that extracts the id the controller passes to `getElementById` and
the id the override puts on its JSON island, and asserts they are equal — plus a check that the
override's asset paths match the controller and stylesheet filenames. Reverting the id now fails
that guard first. This is the general remedy for the class: assert the two sides against each
other, not each against a fixture.

**task-048** added exactly one key, `Head`, to the `components:` map. Diff confirmed to touch
nothing else — the `sidebar` array and the `mermaid({...})` options are untouched, so risk R1
(third editor of `astro.config.mjs`) is discharged, and it ran strictly after task-016 and the
KI-001 ride-along, never concurrently.

**AC-6.5 verified against a real build, not inferred.** After `npm run build`: 142 HTML pages,
of which **111 are skill detail pages and each carries the controller, the stylesheet link and
the JSON island exactly once**; the other **31 pages carry none of the three**, including
`/skills/` itself. Also confirmed: `public/skill-node-panel.css` and `.mjs` are copied
byte-identically into `dist/`, which discharges task-051's deferred check, and **no client JS
bundle contains the island id or any corpus excerpt** — the flow JSON reaches the browser only
as a per-page island. One grep hit in a mermaid bundle was a false positive: a Langium parser
grammar containing `"$type":"ParserRule","fragment":true`.

### task-051 — panel and focus stylesheet

`site/public/skill-node-panel.css` covers the block and all eight Anatomy elements, and styles
nothing outside that list. Executed directly rather than dispatched, since delivery-003's UI
work already established how this site's theming behaves.

Two decisions worth recording.

**Nodes are selected by their decoration, not by a container class.** The rules key off
`g.node[role='button']` — the attribute the controller applies — rather than any wrapper name.
That keeps this file off task-049's ground while it was being written in parallel, and it is
also the more honest selector: the styling applies to exactly those nodes that are actually
interactive.

**Colours come only from Starlight's `--sl-color-*` variables.** `casulo.css` maps those per
theme, dark under `:root:not([data-theme='light'])` and light under the explicit light scope,
so referencing them tracks both themes with no second palette here. `!important` is used on the
shape-stroke rules for the same load-bearing reason it is used on the edge rules in
`casulo.css`: mermaid injects a `<style>` block inside each generated SVG scoped by the
diagram's generated id, and an id selector outranks any attribute selector a stylesheet can
write.

The criteria here are mostly **negative** — no hard-coded colour, no animation or transition on
focus and open states, no `position: fixed`, no scroll lock, no second breakpoint — and
negatives rot silently: an edit that adds a hex colour or a transition breaks a stated property
of the feature (theme tracking, and `prefers-reduced-motion` needing no branch) without
breaking anything a rendering test would notice. So they are now a committed guard,
`scripts/__tests__/skill-node-panel-css.test.mjs`, 17 tests, which strips comments first so no
criterion can be satisfied by prose that merely mentions the thing.

Proven capable of failing, not merely passing: five perturbations — a hard-coded hex, a
transition on focus, dropping one shape from the focus selector list, making the panel
`position: fixed`, and removing the fragment's height cap — are each caught by the relevant
check.

The narrow-screen rule reuses the site's existing 50rem breakpoint from `shell.css`, where the
header tab row folds, rather than introducing one; a test asserts that is the only media query
in the file.

Deferred to the wave-2 build: confirming the file is copied verbatim into `dist/`. Running a
build here would have regenerated 111 pages while tasks 047 and 049 were working. The mechanism
is not in doubt — `CNAME`, `favicon.svg` and `robots.txt` all reach `dist/` from `public/` — so
this is a check of the specific file, not of Astro's behaviour.

**A benign measurement drift, recorded so it is not re-investigated.** task-046's DETAIL says
"four pages carry `generatedFrom` today". It is now five: `reference/agents.md`,
`reference/kb.md` and `reference/settings.md` cite paths outside `canonical/skills/`, and
**two** pages carry the comma-joined two-source string — `reference/skills.md` plus
`skills/index.md`, which feature-002 added in delivery-002 after this DETAIL was written. Both
are rejected by the anchor rather than by any special case, so the AC holds twice over.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder). NEVER written directly.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
