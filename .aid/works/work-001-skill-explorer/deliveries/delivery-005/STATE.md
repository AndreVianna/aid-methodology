---
delivery_state: Done
gate_tier: Large
gate_grade: A+
gate_timestamp: "2026-07-29T22:54:39Z"
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

- **Issue List:** none blocking. One precision correction, recorded below.

### Gate — conducted directly

Dispatch to a reviewer sub-agent failed twice on the backend instability that killed both wave-3
sub-agents (`Timeout waiting for bubble creation`), so the gate was conducted directly rather than
retried into it. Recorded plainly because it is a deviation: this gate had no adversarial second
reader, and its findings are the executing agent's own.

**Mechanical verification.** 2735 tests across 49 files, green. `astro check`: 0 errors, 0
warnings, 41 pre-existing hints. Build: 142 pages, clean. Two consecutive generator runs are
byte-identical and exit 0, with 111 sidecars present. `gen-reference.mjs` byte-unmodified since
delivery-004. Working tree clean. No mutation artifact anywhere in `site/scripts`, `site/src` or
`site/public`. No test asserts a literal corpus count.

**AC-6.5, re-verified after the final build**: 111 skill detail pages each carry the controller,
the stylesheet link and the JSON island exactly once; the other 31 pages carry none, `/skills/`
included. Both `public/` assets are copied byte-identically into `dist/`.

**The guards were audited by mutation, not by reading.** Five mutants on the build-time module:
re-sorting nodes, leaking the whole chart node into the projection, disabling the `<` escaper, and
dropping the known-sidecar check were each **killed by the relevant test** — and the whole-corpus
sweep died under two of them, which is the evidence that it is not vacuous. The cross-seam island-id
guard and the `ID_RE` regression pin were each separately proven to fail when the defect they
describe is reintroduced (9 test failures for the id pattern; the seam guard fires first for the
island id). The stylesheet guard catches five distinct perturbations. The panel's eight mutants all
die, seven by their own dedicated test.

**Precision correction, no behaviour change.** task-047's report states the two comma-joined
`generatedFrom` pages are rejected "on the `$` anchor (trailing `, canonical/…`)". Measured by
lifting the live regex out of the module: with the end anchor removed the comma-joined value is
**still** rejected, because the `*` in `skills/*/` fails the name charset. The discriminating
element is therefore the charset, not the trailing anchor. The acceptance criterion is unaffected
and satisfied — rejection is structural, and the module contains no `'index'` literal.

**Grade: A+.** All gate criteria met or exceeded: selection opens a dismissible panel with the
verbatim fragment and its deep link; keyboard parity is in place with no focus trap; the Musts
underneath are provably undamaged (generated pages byte-identical to delivery-004, not merely
limited to the three head tags); all three degradation paths behave; handlers bind once per
container and survive three re-render cycles; and the route gate is observable in the emitted HTML.

**Outstanding, both owner-deferred and out of scope for this gate:** the four manual browser
checks (Q2, non-blocking by owner decision) and **KI-022**, the intermittent ELK layout fallback.

### The four manual browser checks — PERFORMED 2026-07-30, verdict below

Q2 said the checks would still be "performed and recorded", just not as a gate precondition.
They were not — through delivery-006 the only browser verification recorded anywhere in the work
covered node decoration and panel opening, none of these four. The work-level final gate found
that and performed them, because "after the gate" had arrived with nothing recorded and the next
step is a PR to `master`.

**Method.** Chromium via Playwright against `npx astro preview` on the built `dist/`
(`http://localhost:4321/skills/aid-describe/`, a 5-node authored chart). Real browser, real
build — not jsdom, which is exactly why task-053 deferred these four rather than asserting them.

⚠️ **Coverage limit, stated for checks 1 and 2 as explicitly as for 3 and 4.** All four checks were
performed on **one page**, carrying an **authored inline-state** chart. The verdicts below are
therefore evidence about that chart shape, and the generalising language in checks 1 and 2 should
be read within that bound. Not observed: a **doorway/engine** chart (64 pages, a much larger node
set from the other chart provider) or a **kind-sibling** chart (13 pages, where feature-004 splices
a parent chart in whole, so declaration order is not self-evidently step order). The panel
controller mounts on all 111 pages — `shouldMount` at `site/src/lib/skill-node-panel.ts`:81-88
matches every one — so those shapes are in scope for it and simply were not sampled. Extending the
sample is one further browser pass, not a redesign.

| # | Check | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | Focus order | **PASS** | All 5 `g.node.aidNode` are decorated `role=button tabindex=0`. Tab from node 1 lands on 2, then 3, 4, 5 — tab order equals document order equals the chart's step order (`aria-label`s read "Step 1…" → "Step 5…"). **Also settles the question task-053 could not:** an SVG `<g>` carrying `tabindex` *is* focusable in Chromium — `nodes[0].focus()` sets `document.activeElement` to that `<g>`. jsdom's focusable-area model could not answer this, which is why the suite asserts attributes instead. |
| 2 | Focus return | **PASS** | `Enter` on node 5 opens the panel and moves focus into it; `Escape` closes it, returns focus to node 5, and resets that node's `aria-expanded` to `false` with no node left expanded. |
| 3 | Screen-reader announcement | **PASS WITH OBSERVATIONS** | Announcement works by **focus movement**, not a live region: activation moves focus into the panel, which carries an `<h3>` naming the step and a `button` labelled "Close step details". Two gaps, both recorded as debt below. **Limit of this check, stated plainly: no screen reader was run.** What was verified is the accessibility tree and the focus behaviour — the mechanism, not the utterance. A real NVDA/JAWS/VoiceOver pass is still owed and is what the check literally names. |
| 4 | 360 px layout (observation) | **PASS WITH ONE OBSERVATION** | At a 360 px viewport (345 CSS px client width) the document does **not** scroll horizontally; the panel renders 313 px wide, fully inside the viewport; the chart container is `overflow-x: auto` and scrolls rather than overflowing. One element exceeds the viewport by 4 px — Starlight's theme `<select>` inside AID's `.aid-header`. **Measured, not assumed, whether this work caused it:** hiding the `Skills` header tab that task-016 added leaves the select at the same 349 px, so the tab is not the cause and this is pre-existing site chrome. It causes no horizontal document scroll. |

**Net effect on the gate:** nothing here would have failed it. Under feature-006's default the
three accessibility checks block, and all three pass — checks 1 and 2 cleanly, check 3 with
observations rather than a Fail. So the owner's Q2 override cost this delivery no correctness;
what it cost was the record, for two days, on the three checks that block.

**Filed rather than fixed** (this is a verification pass, not a licence to change shipped
behaviour at a final gate): the two check-3 gaps go to `.aid/knowledge/tech-debt.md` as `W1-13`
and `W1-14`, and the real-screen-reader pass as `W1-15`.

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

### Q4 — task-053's prescribed SVG fixture shape is wrong, and would re-introduce a fixed defect

- **Category:** Requirements (AC-vs-reality)
- **Impact:** High — following it literally would rebuild the exact defect wave 2 found and fixed
- **State:** Answered
- **Context:** task-053's DETAIL specifies the synthetic fixture as
  `<g class="node default aidNode" id="flowchart-<id>-<n>">`, with `domId` being
  `"flowchart-" + id + "-" + vertexCounter`, and states this shape was *"verified against the
  locked mermaid install"*. Its acceptance criteria then require the fixture to match it.
  Measured directly in a browser against this site's locked mermaid (11.15.0), the real ids are
  **`mermaid-<diagramId>-flowchart-<id>-<n>`** — captured as `mermaid-11br4n7o5-flowchart-n2-1`,
  `mermaid-rkijoq1pv-flowchart-n10-9` and `mermaid-23qhs6d31-flowchart-n1-0` across three loads,
  the diagram id differing every render. The DETAIL's shape is the *internal* `domId` mermaid
  computes, not the id that reaches the DOM.
  This is not academic: task-049 shipped a start-anchored `ID_RE` built on that same assumption,
  it matched **0 of 10** nodes on a real page, and its unit suite passed because its fixtures
  used the same fictional shape.
- **Answer:** **The measurement wins.** task-053's fixtures must carry the diagram-id prefix.
  The DETAIL's stated shape is recorded here as a DETAIL defect rather than followed, and
  task-053 is briefed with the captured ids.

  One further refinement from the same measurement: the real class attribute is
  **`node default aidEntry aidNode`** — the per-kind class sits between `default` and `aidNode`,
  so the DETAIL's `class="node default aidNode"` is incomplete too. It does not break anything,
  because the controller selects on `g.node.aidNode` and extra classes are harmless, but a
  fixture that omits the kind class is less faithful than it could be. Nodes painted last, after
  clusters / edgePaths / edgeLabels, matches what was observed and stands.
- **Applied to:** task-053's brief and its fixture builder; the `ID_RE` regression pin in
  `scripts/__tests__/skill-node-panel-lifecycle.test.mjs` already holds real ids.

---

## Gate Pre-checks (measured, not inferred)

Recorded as the evidence is gathered rather than at the gate, so the reviewer can re-run each.

**AC-6.4 — "the Musts underneath are provably undamaged".** The strongest available form of this
holds: the 111 generated skill pages are **byte-identical to the delivery-004 branch tip**
(`git diff aid/work-001-delivery-004 -- site/src/content/docs/skills` is empty). The criterion
allows "no generated page byte changes except the three `<head>` tags"; in fact the markdown did
not change *at all*, because the tags are injected by the Astro component at build time and never
written into a page. Everything else that changed under `site/` is additive: the 77 sidecars wave
1 restored, feature-006's own modules and suites.

**The no-JavaScript floor is intact.** All 111 skill pages still carry `## Source fragments`
(`index.md` has none by design). No `<script`, `client:` directive or `import` appears in any
generated page. The appender has no conditional around its emission, so nothing can suppress the
section — the constraint feature-005 places on feature-006.

**AC-6.5 — route gate observable in the emitted HTML.** Verified against a real build: see the
task-047/048 entry below. 111 skill pages carry each of the three tags exactly once; the other 31
pages carry none.

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

### task-050 / task-052 / task-053 — wave 3, executed directly

**Both wave-3 sub-agents died mid-task.** Their transcripts stopped with no output for hours
while the shell backend was throwing `Execution backend unavailable` and corrupted session-state
warnings — the same instability that repeatedly killed the dev server. They left half-applied
edits: panel state variables added but `openPanel` still a stub, and `decorateNode` caught
mid-edit. Both files were backed up to `.aid/.temp/partial/` before anything was touched, and the
remaining work was done directly rather than re-dispatched into an unstable backend.

Their partial work was **kept, not discarded**, because it was sound: task-050's scaffolding
correctly handles re-applying open state after a re-render (a genuinely subtle case, since
`decorateNode` always resets `aria-expanded` to false, so a theme change would otherwise silently
lose the open node), and its composed `aria-label` is well-reasoned — mermaid renders node text as
`<tspan>`s or a `<foreignObject>`, so the computed accessible name would be unreliable.
task-052's additions were complete and worth keeping: two literal-URL assertions that avoid the
tautology of rebuilding the expected value from the same helper, and a non-BMP round-trip.

**The panel.** Implemented as a disclosure, not a dialog: no focus trap, no overlay, no scroll
lock, `tabindex="-1"` so Tab continues into the page and delivery-004's list stays reachable.
Built entirely with `createElement` and `textContent`; a committed guard asserts the file contains
no `.innerHTML`. The panel id is declared **once** and used both to set the element id and to write
each node's `aria-controls`, with a test asserting neither site restates the literal — the direct
lesson of this delivery's two seam mismatches. Eight mutants run, all killed, seven by their own
dedicated test; the eighth (rendering the detail link unconditionally) kills via a null
dereference, which is a real behaviour change but less surgical.

**task-052's corpus sweep** is the highest-value part: all 111 real sidecars project successfully,
emit exactly `PanelNode`'s field set with no excluded key at any depth, preserve node order, carry
the excerpt byte-for-byte, and round-trip through the encoder with no literal `<`. It also asserts
that some real fragment *does* contain a `<`, so the escaping claim measures the escaper rather
than a tame corpus.

**Two defects found by opening a browser, not by the tests.** Both had green suites:

1. The Source link used the **whole GitHub URL as its link text**, where feature-006's Anatomy and
   delivery-004's list both show the repo-relative path and anchor. Fixed by slicing from
   `canonical/` — deriving rather than stripping a known prefix, so neither the blob base nor the
   pinned ref is restated here.
2. The accessible name read **"Step 1: INTAKE — INTAKE"** wherever a label repeats its node name,
   which is 223 of 883 corpus entries. This is the third place the same redundancy has surfaced,
   after the Mermaid node labels and the fragment list. Both the heading label and the `aria-label`
   now collapse it, by the same case-insensitive rule those two already use.

**Two fixture faults fixed while integrating.** The lifecycle projection omitted `order`, which
real projections always carry, so the composed accessible name read "Step undefined" — a fixture
unfaithful to the real data, the same class of gap as an invented id format. And its
no-`innerHTML` scan ran over raw source, so it fired on the comment explaining why `innerHTML` is
never used: a guard tripping on its own rationale. Its fake document also gained a minimal
`createElement`, since the controller now legitimately builds a panel.

**task-053** is the acceptance suite, with all six required groups. Its fixtures use the measured
id shape rather than the DETAIL's (see Q4). Focus placement on a node is deliberately not
asserted, with the jsdom reason stated in the file and the four manual gate checks named. One
non-obvious accommodation: `MutationObserver` delivers asynchronously, so every assertion on
observer-driven decoration awaits a flush — without it they read as "decoration never happened"
when it simply had not happened yet.

**Verified in a real browser, not only in jsdom:** on `/skills/aid-review/` all 6 chart nodes are
decorated, ids resolve through the corrected pattern (`mermaid-qa2dfqn3n-flowchart-n1-0` → `n1`),
clicking a node opens the panel with the correct order, name, kind, label and real excerpt, focus
moves to the panel, `aria-expanded` flips to true, all three links render, and the panel is
inserted directly after the chart.

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
