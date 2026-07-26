# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

<!-- Entry format:
## KI-NNN: {Title}
- **Type:** Bug | Security | Deprecated Dependency | Breaking API Contract
- **Severity:** Critical | High | Medium
- **Affects:** feature-NNN-{name}, feature-NNN-{name}
- **Source:** {file path}:{line} or {dependency}:{version}
- **Description:** {what's wrong and why it matters for the affected features}
- **See also:** tech-debt.md #TD-NNN (if already catalogued in KB)
-->

## KI-001: `astro-mermaid` silently drops the site's custom `themeVariables` palette

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-003-authored-flow-charts, feature-004-doorway-engine-charts
- **Source:** `site/astro.config.mjs`:30-47 vs `site/node_modules/astro-mermaid/astro-mermaid-integration.js`:229-235, 362-366
- **Description:** `astro.config.mjs` passes `themeVariables` as a **top-level** option to
  `mermaid({ theme, themeVariables })`. The integration destructures only
  `{ theme, autoTheme, mermaidConfig, iconPacks, enableLog }` and builds its client config as
  `{ startOnLoad: false, theme, ...mermaidConfig }`, so `themeVariables` is never forwarded to
  `mermaid.initialize`. The casulo dark palette (background `#0a0e1a`, nodeBorder `#d4a853`, …) is
  therefore inert: the site's 11 existing diagrams render with the stock `dark` theme. The fix is to
  nest the palette under `mermaidConfig`. Impact on this work: any chart relying on the configured
  palette for legibility would fail NFR-1. Mitigated in feature-003's SPEC by emitting a
  self-contained `classDef` block in every generated chart (the same approach
  `site/src/content/docs/concepts/methodology.md`:32-39 already uses), so the charts are correct
  whether or not the config bug is fixed. `astro.config.mjs` is owned by feature-002, so the fix
  scope is an open question (feature-003 SPEC § Open Questions OQ-1).

## KI-002: KB and REQUIREMENTS structural-shape facts do not match the measured corpus

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-003-authored-flow-charts, feature-004-doorway-engine-charts
- **Source:** `.aid/knowledge/module-map.md`:196-214 (§ Skill Structural Shapes);
  `.aid/works/work-001-skill-explorer/REQUIREMENTS.md`:247-291 (§8)
- **Description:** Two recorded facts are contradicted by direct inspection of the directories under
  `canonical/skills/`, using the discriminators in feature-003's SPEC § State Machines:
  (a) **Resolved.** `aid-triage` was cited in both documents as the skill "matching neither shape" /
  carrying only a literal `## State Machine` heading. It in fact carries a full `## Dispatch` table
  with `State` and `Advance` columns (`canonical/skills/aid-triage/SKILL.md`:73-81), so it
  classifies as the Dispatch shape; its `## State Machine` heading at line 58 is followed by ASCII
  art, not a table. Independently confirmed at review and corrected in REQUIREMENTS §8 and this
  feature's SPEC Description by the orchestrator on 2026-07-25. Consequence retained here because
  it shapes design: feature-003's residual extractor must be built for the curated non-delegating
  skills (the `## Mode`/`### Step` and `### State N — NAME` heading shapes, e.g. `aid-config` and
  the ticket skills), not for `aid-triage`.
  (b) **Open.** `module-map.md`'s per-shape figures are stale: it lists the hand-authored collapse
  shape as five skills when `aid-change-document`, `aid-create-document` and `aid-report` also carry
  six inline `## State:` sections each, and it records the delegating population as "roughly 94 of
  the 111", which no measurement supports. No corrected figure is written here: two independent
  scans during specification and review agreed on the inline-state population but differed on the
  doorway/residual split, because that split moves with fine details of the D3/D4 discriminators.
  That is precisely why REQUIREMENTS §8 forbids hard-coding any count and names feature-003's
  classifier the only authority; the live figures belong in the generator's `shapeCounts` manifest
  entry, not in prose. The KB row should either be regenerated from that manifest or lose its
  numbers.

## KI-003: `gen-reference.mjs`'s header comment states a stale skill inventory

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001-skill-detail-pages, feature-003-authored-flow-charts
- **Source:** `site/scripts/gen-reference.mjs`:5-7
- **Description:** The file header says it generates "94 skill directories (16 classic +
  aid-triage + aid-ask + 76 catalog-driven shortcuts)". The code's own runtime output says 111
  directories / 19 classic / 64 shortcuts (`site/src/content/docs/reference/skills.md`:9), and the
  drift guard at `gen-reference.mjs`:377-381 enforces the live set. Matters because
  `gen-reference.mjs` is the declared pattern for this work's new sibling generator (REQUIREMENTS
  §4), so its header is the first thing an implementer reads and it is wrong about the very
  quantity this work is sensitive to.

## KI-004: client-side mermaid rendering degrades to raw diagram source without JavaScript

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-003-authored-flow-charts, feature-004-doorway-engine-charts, feature-006-interactive-node-panel
- **Source:** `site/node_modules/astro-mermaid/astro-mermaid-integration.js`:64, 316-318, 508-532
- **Description:** `astro-mermaid` emits `<pre class="mermaid">` containing the escaped diagram
  source and renders the SVG in the browser. Its injected CSS gives an unprocessed block
  `min-height: 200px` plus a shimmer animation, so with JavaScript disabled (or before the lazy
  mermaid import resolves) a reader sees raw `flowchart TB …` text inside an animated placeholder.
  Today this affects 4 pages; after this work it affects every one of the 111 skill detail pages.
  Accepted, with mitigation: feature-005's below-chart ordered list is static markdown and
  independently satisfies AC-5, and feature-006's own acceptance criteria already require the page
  to remain functional without JavaScript. Recorded so the degradation is a known, chosen cost of
  the substrate decision in feature-003's SPEC § UI Specs rather than a surprise at review.

## KI-005: `gen-reference.test.mjs` carries stale roster state that already fails

- **Type:** Bug
- **Severity:** High
- **Status:** **Scheduled for fix by feature-001** (owner decision at the Specify review,
  2026-07-25; REQUIREMENTS.md §7 amended). No longer a standing observation — see
  feature-001's SPEC § Build-integration scope, Part A, which carries the full corrected-assertion
  design, and its fourth acceptance criterion clause (b).
- **Affects:** feature-001-skill-detail-pages (owner of the fix), and transitively every feature in
  this work whose acceptance depends on a green site suite
- **Source:** `site/scripts/__tests__/gen-reference.test.mjs`:101-141
- **Description:** The suite hard-codes a 94-directory skill corpus
  (`expect(skillDirs).toHaveLength(94)`, `:123`) and a `**Total** | **76**` family-table row
  (`:140`). The corpus is 111 directories and the shortcut catalog emits 64 doorway rows, so both
  fail on the current tree — verified with
  `npx vitest run scripts/__tests__/gen-reference.test.mjs` before any change from this work.
  **The stale class is larger than those two.** Specifying the fix surfaced **eight** stale items
  in the file, enumerated here in full so the count and the list agree:
  1. `:101-116` — the `CURATED_SKILL_NAMES` constant, missing `aid-read-ticket`,
     `aid-create-ticket` and `aid-update-ticket`, so it holds 18 names where the generator's
     `SKILL_GROUPS` curates 21.
  2. `:119` — an `it(...)` title restating the wrong arithmetic.
  3. `:123` — `expect(skillDirs).toHaveLength(94)`. **Fails today.**
  4. `:126` — `expect(shortcutDirs).toHaveLength(76)`, also wrong (90 with the corrected roster),
     masked because `:123` short-circuits the block first.
  5. `:132` — `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)`, resolving to 18 against
     a page that renders 21 sections. **Latent** — repaired for free once item 1 is.
  6. `:135` — a second `it(...)` title, hard-coding "76" in its description string. Cosmetic; it
     is a title, not an assertion.
  7. `:138-139` — an explanatory comment restating the 76/80/4 arithmetic.
  8. `:140` — the `toMatch` regex over the family table's `**Total**` row. **Fails today.**

  So the file carries **one constant, two `it` titles, four assertions and one comment**. A
  two-number swap therefore leaves the suite red.
  The generator itself is **not** at fault: its expected set is derived (`SKILL_GROUPS` ∪ catalog
  rows) rather than hard-coded, so `node scripts/gen-reference.mjs` runs clean and its drift guard
  passes. Only the test's literals are stale, and the fix is confined to the test file —
  `gen-reference.mjs` stays frozen per §7.
  Two failures observed alongside these are **environmental, not defects**: the `git diff`-based
  idempotency test fails in this work's git worktree because its `.git` file holds a WSL path
  Windows `git` cannot resolve (re-running the generator left every output byte-identical), and
  five TypeScript suites cannot load at all here because `node_modules/astro` is absent so
  `tsconfig.json`'s `extends: "astro/tsconfigs/strict"` will not resolve. Both clear under a clean
  `npm ci`.
- **See also:** KI-003 (the same stale inventory, in the generator's header comment) and KI-006
  (why this went unnoticed). REQUIREMENTS.md §8 forbids hard-coding a count — the failure mode this
  work must avoid, already realised in the existing test suite, which is why the fix replaces the
  literals with checks derived from `canonical/skills/` and `shortcut-catalog.yml` rather than
  swapping in new numbers.

## KI-006: No CI workflow runs the site's vitest suite

- **Type:** Bug
- **Severity:** Medium
- **Status:** **Scheduled for fix by feature-001** (owner decision at the Specify review,
  2026-07-25; REQUIREMENTS.md §7 amended). Was recorded as "outside this feature's declared
  scope"; the owner brought it in. See feature-001's SPEC § Build-integration scope, Part B, and
  its fourth acceptance criterion clause (d).
- **Affects:** feature-001-skill-detail-pages (owner of the fix), feature-003-authored-flow-charts,
  feature-004-doorway-engine-charts, feature-005-verbatim-source-provenance
- **Source:** `.github/workflows/docs.yml`:40-76 (the only workflow with a `site/**` path filter)
- **Description:** `docs.yml` runs `npm ci` then `npm run build` and nothing else; no workflow
  invokes `npm test` / `vitest run` in `site/`. `test.yml` covers the canonical shell suites, the
  render-drift gate and the generator self-tests, but not `site/`. This is why KI-005 went
  unnoticed. It matters here because AC-4 (features 003 and 004) and the AC-2 / AC-6 checks
  specified for feature-001 are all "tested with vitest" — those tests would exist but nothing in
  CI would run them, leaving the `prebuild` generator throw as the only automated gate on a pull
  request. The fix is one step in the `build` job, between `npm ci` and `npm run build`; because
  that job already runs on `pull_request` to `master` with a `site/**` path filter, no trigger
  change is needed and pull requests are gated automatically.
  **Sequencing constraint:** this must land *after* KI-005, and only once `npm test` is confirmed
  green on a clean `npm ci` install. Wiring CI while the suite is red converts an invisible problem
  into a permanently red pipeline. Note that five of the eight test files (the TypeScript suites
  under `src/lib/__tests__/` and `src/data/__tests__/`) have **never** run in CI, so their
  assertions are unverified and may hold staleness of the same kind; they must be triaged during
  that verification pass rather than discovered by the first red pipeline.
- **See also:** `.aid/knowledge/test-landscape.md` § CI Lanes, which records `docs.yml` as
  "Astro Starlight build → GitHub Pages deploy" (accurate, and confirms there is no test step), and
  its Gaps table entry "Canonical suite on feature branches". That KB doc will need a revision once
  this lands, since the CI-lane table will no longer be accurate. See also KI-007, which records a
  second inaccuracy in the same row.

## KI-007: `test-landscape.md`'s CI-lane row for `docs.yml` misstates its triggers

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-005-verbatim-source-provenance, feature-001-skill-detail-pages
- **Source:** `.aid/knowledge/test-landscape.md`:160 (and its "CONFIRMED by the `on:` blocks of each
  workflow" claim at :162) vs `.github/workflows/docs.yml`:10-25
- **Description:** The row states the Docs workflow's triggers as "push to `master` touching
  `site/**`, `docs/**`, `VERSION`, or the workflow; `release: published`; `workflow_dispatch`. It is
  wrong in both directions: `docs.yml` has **no `release:` trigger at all** (its header comment at
  :5-8 says the `github-pages` environment permits master-ref deploys only, so a tag/release ref is
  rejected and a post-release refresh is a manual `workflow_dispatch`), and it **omits the
  `pull_request` trigger** to `master` with the same path filter (:18-24), which is the trigger that
  makes the build — and, once KI-006 is fixed, the vitest suite — a pull-request gate. The
  "CONFIRMED by the `on:` blocks" line one row below makes the error more likely to be trusted.
  Matters for this work twice over: feature-005's deep links pin the `master` ref, and that choice
  is justified by the site only ever being built and deployed from `master` — a reader checking that
  claim against the KB would find a phantom release-triggered build; and feature-001's Part B rests
  on the `pull_request` trigger the row omits (feature-001 read the workflow directly, so its SPEC
  is correct). Fix is a one-row correction to the KB table, out of scope for this work's product
  changes.

## KI-008: the `X (optional) then Y` advance form is not split into two clauses

- **Type:** Bug
- **Severity:** High
- **Affects:** feature-003-authored-flow-charts (owner of the parser), feature-004-doorway-engine-charts
  (its AC-4 fixture 2 depends on the fix)
- **Source:** `canonical/skills/aid-test/SKILL.md`:102, `canonical/skills/aid-design/SKILL.md`:91,
  `canonical/skills/aid-prototype/SKILL.md`:91, `canonical/skills/aid-report/SKILL.md`:103,
  `canonical/skills/aid-research/SKILL.md`:130 vs
  `.aid/works/work-001-skill-explorer/features/feature-003-authored-flow-charts/SPEC.md`:424
  (the Advance-clause parser, rule 1)
- **Description:** Feature-003's Advance-clause parser splits an advance line into clauses on top-level
  ` / ` or `; ` only. Five inline-states skills instead write a two-target advance with ` then `:
  `**Advance:** HANDOFF (optional) then DONE.` — byte-identical in all five files. Unsplit, the line is
  one clause, so rule 2 takes the first token matching a declared state (`HANDOFF`) as the sole target
  and rule 3 sweeps the remainder into the edge condition as `(optional) then DONE`. The result is a
  single edge `PRESENT → HANDOFF` and **no `PRESENT → DONE` edge**, so the optional-handoff branch —
  the only branch those five skills express at that state — is dropped, and `PRESENT.kind` is `step`
  rather than `decision`.
  **It fails silently, which is what makes it High.** `DONE` stays reachable through
  `HANDOFF → DONE` (e.g. `aid-test/SKILL.md`:111), so V6 is satisfied, no validator rule fires, and
  nothing throws; the five charts are simply wrong in a way only a reader comparing chart to source
  would notice. It is also directly load-bearing for this work's acceptance: `aid-test` is the
  resolved source of feature-004's AC-4 kind-sibling fixture (`aid-test-security`), and the branch
  that fixture asserts is exactly the one being dropped.
  **Required fix** (feature-003's `advance.mjs`, test-visible, no model change): add ` then ` to the
  top-level clause separators, so `HANDOFF (optional) then DONE` yields the clause pair
  `HANDOFF (optional)` + `DONE` (target `HANDOFF` with condition `optional`; target `DONE` with no
  condition); and, when an advance line yields two or more target clauses, kind every resulting edge
  `branch` — already the behaviour feature-003's own `aid-review` fixture assumes for
  `**Advance:** PUBLISH on approval; otherwise DONE.` (`aid-review/SKILL.md`:184) — which makes
  `PRESENT.kind === 'decision'`.
  ~~Routing is an open owner decision, recorded as OQ-1 in feature-004's SPEC~~ — **routed
  2026-07-25: the owner assigned the fix to feature-003**, the SPEC that owns the parser, rather
  than patching it downstream in feature-004's delivery.
- **See also:** feature-004's SPEC § Layers & Components, E-DEP-4, and its AC-4 fixture 2 table. Two
  further multi-target advance forms exist in the corpus and are **not** in scope here because they
  belong to feature-003's residual/worker paths rather than to an inline-states skill:
  `canonical/skills/aid-read-ticket/SKILL.md`:100,115 (`CHAIN → State 3 (FETCH) …; STOP/exit on …`)
  and `canonical/skills/aid-summarize/references/state-approval.md`:55 (three `If user …:` arms).
- **Resolution — specified 2026-07-25 in feature-003's SPEC** (§ State Machines → The Advance-clause
  parser; § the validator table). Fixed as a **class**, not as a ` then ` special case, after a
  sweep of every `**Advance:**` block in `canonical/skills/**/*.md` (139 blocks, 98 distinct texts)
  plus every Dispatch `Advance` cell:
  - The parser now takes a **block**, not a line — 19 advances wrap, and
    `aid-create-ticket/SKILL.md`:200-201 hides a third clause (`` `[3] Cancel` → halt ``) on its
    continuation line. Same fix applied to the rule-6 body scan, which is what
    `aid-test/SKILL.md`:89-90 needs (its loop phrase wraps mid-sentence).
  - The separator set is measured and now covers `;`, ` / `, unspaced `/` between state tokens,
    **` then `**, ` or `, the `(or X …)` parenthetical alternative, and the sentence boundary `. `.
    Splits are **proposed then validated**: a cut is accepted only if every resulting clause
    resolves to a state or a terminal keyword, which is what keeps prose `or`/`.` from inventing
    phantom edges. ` and then `, `, then ` and multi-hop state chains were checked for and are
    measured absent.
  - Both forms this entry listed as out of scope are now covered by that set: the `;` form
    (`aid-read-ticket`) and the three `If user …:` arms (`state-approval.md`:55, via the sentence
    boundary).
  - `X (optional) then Y` semantics are specified explicitly (parser rule 6), yielding two
    `branch` edges — `→ X` with `condition: 'optional'` and `→ Y` with `condition: null` — so
    `PRESENT.kind === 'decision'` falls out of the existing kind rule and feature-004's assertion
    holds unchanged.
  - **Anti-silence guard added** (parser rule 10 + validator **V9**), which is the part that
    addresses this entry's "fails silently" severity: residual unparsed text referencing a declared
    state that became neither an edge nor a `terminal.handoff` is now a validator **error**, and a
    checked-in allow-list test makes any newly-unrecognised connective fail CI.
  - `aid-test` added as feature-003's third AC-4 fixture, so the regression is caught in the
    parser's own suite rather than feature-004's.
  No model change: `FlowChart` / `FlowNode` / `FlowEdge` / `Provenance` are untouched. The only
  contract movement is `validateChart` gaining V9 — see feature-003's return notes.

## KI-009: `reference/skills.md`'s family table renders empty and nonsensical rows

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-grouped-skill-index
- **Source:** `site/scripts/gen-reference.mjs`:212-304 (`SHORTCUT_FAMILIES`) vs
  `site/scripts/gen-reference.mjs`:132-134, 311 (the `repurpose` filter); rendered output at
  `site/src/content/docs/reference/skills.md`:185-194
- **Description:** `generateShortcutFamiliesSection` computes each family's count over the
  **emitting** rows only — every catalog row except `repurpose: true` (`:132-134`, `:311`) — but
  `SHORTCUT_FAMILIES` still carries hand-written entries for families whose rows have all since
  become `repurpose: true`. Six family rows therefore render with a count of `0`
  (`Prototype`, `Document`, `Report`, `Show dashboard`, `Review`, `Research`), and two carry
  detail prose whose interpolated arithmetic is visibly wrong: `Test + Experiment` reads
  "`aid-test` + 3 typed forms (security, performance, data-quality) = **0**" (`:245`, rendered at
  `skills.md`:185) and `Document` reads "`aid-document` + **-1** typed forms" (`:255`, rendered at
  `skills.md`:187). The `Show dashboard` family is dead outright: it matches `r.verb ===
  'show-dashboard'` (`:264`) and no such verb exists — the catalog's `aid-show-dashboard` row
  carries `verb: create` (`canonical/aid/templates/shortcut-catalog.yml`:771-777). The
  family-drift guard at `:317-323` does not catch any of this, because it only checks that the
  family counts *sum* to the emitting-row total; a family matching zero rows contributes zero and
  passes. Matters for this feature in two ways: (a) it is direct evidence that a hand-maintained
  family table drifts from the catalog, which is why feature-002 derives its verb-family sections
  from the catalog's `verb` field in first-appearance order and hard-codes no family list; and
  (b) it widens the visible gap between the two surfaces a reader will compare, which
  feature-002's SPEC § Divergence must account for. `gen-reference.mjs` is frozen by §7, so this
  is **not** fixed by this work.
- **See also:** KI-003 and KI-005 — the same stale-inventory class, in the generator's header
  comment and in its test suite respectively.

## KI-010: `SKILL_GROUPS`'s skill grouping is stale, and the divergence can only be signposted from one side

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-grouped-skill-index
- **Source:** `site/scripts/gen-reference.mjs`:150-199, specifically `:179` (`aid-triage` in the
  Definition group) and `:185-186` (`aid-deploy` / `aid-monitor` as curated Definition members)
- **Description:** `reference/skills.md` groups `aid-triage` under **Definition** and lists
  `aid-deploy` / `aid-monitor` among the full-path Definition skills. Per REQUIREMENTS.md §5 FR-5
  (Placement rules, owner-corrected at cross-reference, Q1) that grouping is wrong: `aid-triage`
  is a Support skill, the full path is exactly the five skills `aid-describe` → `aid-detail`, and
  `aid-deploy` / `aid-monitor` are ordinary shortcut skills under their own `deploy` / `monitor`
  verb families. §7 freezes `gen-reference.mjs`, so the two pages will visibly disagree about
  three skills once `/skills/` ships. The inconsistency itself is accepted and recorded in
  REQUIREMENTS §5; what is registered here is the **asymmetry of the remedy**: feature-002 can
  publish a note on `/skills/` explaining the difference and declaring itself authoritative for
  grouping, but no reciprocal note can be added to `reference/skills.md` — its content is
  regenerated from the frozen generator on every `prebuild`, so a hand edit would be overwritten.
  A reader arriving at the reference page first therefore gets no signal. Follow-on fix, outside
  this work: correct `SKILL_GROUPS` (and the `shortcutsAfter: 'aid-detail'` nesting at `:192`,
  which assumes the old eight-skill Definition list) once the freeze lifts, at which point
  feature-002's divergence note should be deleted rather than left to rot.
- **See also:** REQUIREMENTS.md §5 FR-5 (the accepted, recorded divergence) and KI-007 (a second,
  independent axis on which the same page disagrees with the catalog).

## KI-011: `data-processed` means "render attempted", not "SVG present"

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-006-interactive-node-panel, feature-003-authored-flow-charts (the wording of
  its hook H1), feature-004-doorway-engine-charts
- **Source:** `site/node_modules/astro-mermaid/astro-mermaid-integration.js`:438-452, specifically
  `:451`, vs feature-003's SPEC § UI Specs → Hooks this gives feature-006, hook **H1**
- **Description:** Hook H1 tells feature-006 to observe the `data-processed` attribute transition
  on `pre.mermaid` as its readiness signal, citing the success path at `:435-437`. But the
  integration's `catch` block also sets `data-processed="true"` after a **failed** render (`:451`),
  having first replaced the container's contents with a plain error `<div>` (`:441-450`). So the
  attribute means "mermaid attempted this diagram", not "an SVG exists". A consumer that treats it
  as the latter would run its node query against a container with no `<svg>` and no `g.node`
  elements at all. Impact is bounded — the query returns an empty list, so nothing crashes — but
  the distinction has to be *designed for* rather than discovered: the honest readiness predicate
  is `data-processed` **and** a non-null `container.querySelector('svg')` **and** at least one
  resolvable node id. Feature-006's SPEC § State Machines adopts exactly that three-part guard and
  routes the failure to a `BOUND_INERT` state (one warning, no panel, feature-005's list remains
  the working path). Recorded because H1's current wording would mislead any future consumer that
  attaches to the same substrate, and because the two other features that render charts share the
  hook.

## KI-012: `astro-mermaid` logs to the browser console on every page of the production site

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-006-interactive-node-panel (its browser-console contract),
  feature-002-grouped-skill-index (owner of `site/astro.config.mjs`),
  feature-003-authored-flow-charts, feature-004-doorway-engine-charts
- **Source:** `site/node_modules/astro-mermaid/astro-mermaid-integration.js`:229-235 (the
  `enableLog = true` default at `:234`), `:312`, `:457-462`, `:500` vs `site/astro.config.mjs`:30-47
- **Description:** The integration's `enableLog` option defaults to `true` and `astro.config.mjs`
  never sets it, so the generated client script builds a live logger (`:312`) rather than a no-op.
  That script is injected with `injectScript('page', …)` (`:500`), i.e. into **every** page of the
  site, and it logs unconditionally on load — `'Mermaid diagrams detected on initial load'` or
  `'No mermaid diagrams found on initial load'` (`:457-462`) — followed by one line per diagram
  found, initialized and rendered (`:376`, `:379`, `:425`, `:437`). The production site therefore
  writes `[astro-mermaid] …` to the console of every visitor on every page, including the pages
  that contain no diagram at all. Matters for this work in two ways: it multiplies with the page
  count once ~111 skill detail pages land, each of which *does* carry a diagram; and it sits
  directly against feature-006's Telemetry contract, which specifies a silent console on success
  and reserves `console.warn` for four named guards — a reader debugging a panel issue has to read
  past the neighbour's noise. The fix is one property (`enableLog: false`) in the `mermaid({ … })`
  options object at `astro.config.mjs`:30-47, which is feature-002's file and is already the
  subject of feature-003's OQ-1 (KI-001) and feature-006's OQ-4. Not fixed by this work unless the
  owner folds it into whichever edit to that object happens first.
- **See also:** KI-001 (a second defect in the same options object) and KI-004 (the no-JavaScript
  degradation of the same substrate).

## KI-013: `astro.config.mjs`'s component-map comment claims a map that is neither empty nor reserved as described

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-006-interactive-node-panel (adds a key to this map),
  feature-002-grouped-skill-index (edits the same file)
- **Source:** `site/astro.config.mjs`:12-17 and `:139-153`, against the live map at `:144-153`
- **Description:** Two comment blocks describe the Starlight `components:` override map. Both are
  wrong about the current state, and both are the first thing an implementer adding a key reads.
  `:12` says "components: map is EMPTY here" and `:139-140` repeats "OWNED HERE, intentionally
  empty" — but the map already holds four keys: `Header` and `PageTitle` at `:147-148` and
  `Banner` and `Footer` at `:150-151`. Worse, the "Reserved slots (later deliveries add ONE key
  each)" lists at `:14-16` and `:141-143` name `Banner: feature-009`, `Footer: feature-010` and
  `Hero: feature-008` — those are a **previous** work's feature numbers, the same collision
  feature-001 records for `src/content.config.ts` (§ Data Model, the boxed note), and two of the
  three slots they reserve are already filled. So a reader of this work who sees "feature-006" or
  "feature-009" in that file can reasonably conclude a slot is reserved for, or already taken by,
  a feature of *this* work; none of them are. The one instruction in the comment that is still
  correct and load-bearing — "do not rewrite this map, only add" — is the one buried among the
  stale text. Matters because this work adds keys from two features to that file. Fix is a
  comment correction in `astro.config.mjs`, which is feature-002's file; it can ride along with
  whichever edit to that file lands first, and it is not a product change.
- **See also:** feature-001's SPEC § Data Model (the identical collision in `content.config.ts`),
  KI-001 and KI-012 (two live defects in the same file), and feature-006's SPEC OQ-4 (three
  features editing this file).

## KI-014: `initMermaid()` has no re-entrancy guard, so a rapid theme toggle can run two render loops over the same containers

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-006-interactive-node-panel, feature-003-authored-flow-charts,
  feature-004-doorway-engine-charts
- **Source:** `site/node_modules/astro-mermaid/astro-mermaid-integration.js`:375-454 vs `:465-487`
- **Description:** `initMermaid()` is `async` and awaits `mermaid.render()` once per diagram inside
  its loop (`:413-453`); it holds no in-flight flag. Its only idempotence guard is
  `if (diagram.hasAttribute('data-processed')) continue` (`:415`), and that attribute is not set
  until *after* the await resolves (`:436`). The theme `MutationObserver` (`:466-476`) strips
  `data-processed` from every container and calls `initMermaid()` on each `data-theme` change,
  without debounce and without awaiting the previous call. Two theme changes closer together than
  one render therefore start two concurrent loops over the same containers: both see
  `data-processed` absent, both render, and whichever `diagram.innerHTML = svg` (`:435`) lands
  second wins. The visible result is benign (both renders produce the same SVG from the same
  stored `data-diagram` text at `:418-422`), but the *event sequence* is not: `data-processed` is
  written more than once per user action, so any consumer keyed on that transition is invoked more
  than once, against a subtree that may be replaced moments later. This is precisely the
  duplicate-handler / stale-decoration hazard feature-006 must survive. Recorded rather than fixed:
  feature-006's SPEC § State Machines absorbs it by binding listeners once per container (identity
  tracked in a `WeakSet`, never per node) and by making decoration idempotent via a
  `data-aid-node` marker, so a repeated transition re-decorates the current subtree and cannot
  double-bind.   Fixing the integration itself would mean patching a vendored dependency, which is
  out of scope for this work.

## KI-015: the two task templates disagree, and one claims conformance to the other

- **Type:** Bug
- **Severity:** Medium
- **Affects:** every task in this work (53 `DETAIL.md` files), and every future `/aid-detail` run
- **Source:** `.claude/aid/templates/task-detail-template.md` vs
  `.claude/aid/templates/delivery-plans/task-template.md`
- **Description:** AID carries two task templates that disagree on four points, and the disagreement
  is not cosmetic — it caused three independent reviewers to raise the same finding against tasks
  that were, in fact, conformant with the template the skill actually names.

  | Field | `task-detail-template.md` (the file `/aid-detail` seeds from) | `delivery-plans/task-template.md` |
  |---|---|---|
  | `Source:` | `work-NNN-{name} -> delivery-NNN` | `feature-NNN-{name} → delivery-NNN` |
  | No-dependency marker | `-- (none)` | `— (none)` |
  | Closing criterion | `All section-6 quality gates pass` | `All §6 quality gates pass` |
  | Arrow glyph | ASCII `->` | U+2192 `→` |

  **The sharpest form of the defect:** `task-detail-template.md`'s own `[!NOTE]` states
  *"Shape: 6 sections matching `.claude/aid/templates/delivery-plans/task-template.md`"* — it
  asserts conformance to the very file it contradicts.

  The tie-breaker favours the seeding template on two of the four: `aid-detail/references/
  task-decomposition.md` names `task-detail-template.md` as the seeding source (:121) and restates
  its `work-NNN-{name} -> delivery-NNN` shape (:132). But the same reference sides with the *other*
  template on the closing criterion, instructing authors to write `All §6 quality gates pass`
  (:170) — so no single file is authoritative throughout.

  **Resolution applied in this work:** tasks keep the seeding template's shape and append the
  feature — `work-001-skill-explorer -> delivery-NNN (feature-NNN-name)` — which satisfies
  traceability without abandoning the format `/aid-detail` prescribes. All 53 tasks retain
  `All section-6 quality gates pass`, per the seeding template.

  **Not fixed here:** reconciling the templates is a change to the AID toolkit itself, outside this
  work's scope. It should be one edit deciding which file is authoritative, correcting the other,
  and fixing the false conformance claim in the note.
- **See also:** raised independently by the delivery-001, delivery-003 and delivery-004 task
  reviewers; delivery-001's reviewer subsequently marked its own row **Invalid** on discovering it
  had cited the non-authoritative template.
