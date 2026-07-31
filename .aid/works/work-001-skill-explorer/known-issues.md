# Known Issues

> **§7 AMENDED (2026-07-30, delivery-006).** REQUIREMENTS §7's **second amendment**
> (work-level Q4) lifted the `gen-reference.mjs` freeze so delivery-006 could hollow out
> `reference/skills.md`. Entries below that read "§7 freezes/forbids", "the frozen
> generator" or "terse family summary" were TRUE WHEN FILED and are kept as the record;
> none describes the repository today. See KI-010, which records what survived: the
> competing grouping moved from a page to the curated roster.

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
- **Status:** **RESOLVED, and the remedy this entry prescribes was proved WRONG — do not apply
  it.** Recorded at the work-001 final gate, 2026-07-30.
  - **What shipped.** `site/astro.config.mjs` **deleted** the `themeVariables` block rather than
    relocating it, and moved per-theme colour into CSS where `[data-theme]` can select (the mermaid
    block in `site/src/styles/casulo.css`). `mermaidConfig` now carries layout only — which is
    theme-independent and therefore safe to fix in config.
  - **Why the prescribed fix is harmful.** The Description below ends "The fix is to nest the
    palette under `mermaidConfig`". Doing that forwards the palette successfully but pins **one**
    palette across **both** themes `autoTheme` switches between, so the dark colours would bleed
    into light mode. A future reader following this entry would trade an inert palette for a
    visibly broken one. The config carries the same warning inline at `astro.config.mjs`:35-42 so
    the correction is discoverable from the code, not only from here.
  - **The mitigation still holds and is still load-bearing:** every generated chart emits a
    self-contained `classDef` block, so charts are legible independent of theme config.
  - The tech-debt inventory carries the residue as `W1-1`, which is about the upstream
    integration never forwarding a top-level `themeVariables` at all — an `astro-mermaid` bug this
    work worked around rather than fixed, and correctly still open.
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
- **Status:** **CLOSED by delivery-006 (task-054), 2026-07-30.**
- **Affects:** feature-001-skill-detail-pages, feature-003-authored-flow-charts
- **Source:** `site/scripts/gen-reference.mjs`:5-7
- **Description:** The file header said it generates "94 skill directories (16 classic +
  aid-triage + aid-ask + 76 catalog-driven shortcuts)". Measured before acting: the code's
  runtime output was always correct (111 / 19 / 64), because it derives at build time — only the
  **comments** drifted. So this issue was narrower than recorded when filed: a comment defect
  with no reader-visible symptom, and no rendering bug for a future reader to hunt.
  **How it was closed:** the stale comments are gone, and authority for the triple moved to
  `site/scripts/skills/skill-counts.mjs`, which derives it once. `skill-counts.test.mjs` guards
  every file that could restate it — matching count *shapes* rather than the specific stale
  values, so a NEW hand-count is caught as readily as the old one was. Review of task-054 found
  one such survivor the first pass missed (`gen-reference.mjs` claimed "67 near-identical H3
  blocks" against a real 64) — it is fixed, and it is why the guard checks shapes.

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
- **Status:** **CLOSED by delivery-001 (task-001), 2026-07-26.** All eight stale items were
  replaced with checks re-derived from `canonical/skills/` and `shortcut-catalog.yml`, and a
  **clamp** was added that fails by name for any on-disk skill directory that is neither a
  catalog row nor in the curated roster — demonstrated against the three ticket skills, the
  very drift that produced this entry. No corpus count literal survives in the roster region.
  `gen-reference.mjs` stayed byte-unmodified throughout, per §7.
  _(Was: "Scheduled for fix by feature-001" — owner decision at the Specify review, 2026-07-25;
  REQUIREMENTS.md §7 amended. The design is at feature-001's SPEC § Build-integration scope,
  Part A; the acceptance is its fourth criterion clause (b).)_
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
- **Status:** **CLOSED by delivery-001 (task-004), 2026-07-26.** `docs.yml`'s `build` job now
  runs `npm test` in `site/` between `npm ci` and `npm run build`, so a red suite fails the pull
  request before any Pages artifact can be produced. The sequencing constraint this entry sets
  was honoured: task-002 measured the whole suite on a clean `npm ci` first (8 files, 228 tests,
  one genuine stale assertion), task-003 corrected it, and only then did the CI step land — so
  the wiring never turned an invisible problem into a permanently red pipeline. The five
  TypeScript suites that had never executed in CI ran here for the first time and are green.
  _(Was: "Scheduled for fix by feature-001" — owner decision at the Specify review, 2026-07-25;
  REQUIREMENTS.md §7 amended. Design at feature-001's SPEC § Build-integration scope, Part B;
  acceptance is its fourth criterion clause (d).)_
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
- **Status:** **RESOLVED** at the work-001 final gate, 2026-07-30. The row now states the real
  triggers (push **and** `pull_request` to `master`, both path-filtered including `canonical/**`;
  no `release:` key), names the `npm test` step, and answers the feature-branch column with the
  distinction that actually holds — the test+build job gates every PR, only `deploy` is
  master-only. The "CONFIRMED by the `on:` blocks" claim was re-verified against
  `.github/workflows/docs.yml`:10-29 (the whole `on:` block) and dated.
  **Fixed as a class, not as the cited line.** Grepping the signature found the same wrong lane in
  two more KB docs the ledger did not cite — `infrastructure.md`'s release/deploy row and
  `integration-map.md`'s trigger row — both corrected in the same pass. The corresponding
  tech-debt item `W1-4` was deleted per the KB's resolved-debt convention.
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
- **Status:** **CLOSED by delivery-006 (task-057), 2026-07-30 — by deletion.** The family table
  is gone: work-level Q4 unified the two skill sections, so `reference/skills.md` was hollowed
  out to the shortcut-engine narrative and the duplicated roster (table included) was shed. Every
  symptom below went with it — the six zero-count families, the `= 0` and `-1 typed forms`
  arithmetic, and the dead `show-dashboard` family. The arithmetic was deliberately **not**
  repaired: repairing it would have preserved a hand-maintained family table duplicating what
  `/skills/` derives, which is the very thing the delivery removed. Verified in the built output:
  `dist/reference/skills/index.html` contains zero `typed forms` and zero per-skill headings.
  Family-coverage drift for the surviving derived roster is guarded by `gen-skills.mjs` and
  `scripts/__tests__/skills-groups.test.mjs`.
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
- **Status:** **STILL OPEN, but half of it is resolved and the rest is now disclosed rather than
  invisible.** Updated by delivery-006 (task-057), 2026-07-30:
  - **The asymmetry of the remedy — resolved.** It rested on "§7 freezes `gen-reference.mjs` <!-- SUPERSEDED 2026-07-30: §7's second amendment (work-level Q4) lifted the gen-reference.mjs freeze; delivery-006 hollowed out reference/skills.md. Kept as the design record. -->", and
    §7's second amendment lifted that freeze (work-level Q4). The point is moot anyway: that page
    no longer publishes a roster at all, so there is no longer a second grouping on a *page* for
    the two to disagree about.
  - **The stale grouping itself — still open.** `SKILL_GROUPS` (now at
    `site/scripts/skills/curated-roster.mjs`, extracted by task-054) still files `aid-triage`
    under **Definition** where FR-5 puts it in **Support**. It is no longer rendered, but it is
    still read — by the corpus drift guard, by `skill-counts.mjs`'s `curatedOnly`, and by the
    divergence disclosure below — so correcting it is a real change with real consequences and is
    deliberately not folded into this delivery.
  - **The divergence is now DERIVED, not curated.** `/skills/`'s note used to hard-code three
    skill names; it now computes which skills the two groupings actually disagree about and names
    those. That measurement shows the hard-coded list was itself wrong: only `aid-triage` diverges
    — `aid-deploy` and `aid-monitor` agree (both Definition on either side). So this entry's
    original "three skills" framing was over-stated.
- **Affects:** feature-002-grouped-skill-index
- **Source:** `site/scripts/skills/curated-roster.mjs` — the `SKILL_GROUPS` table, specifically
  `aid-triage` listed under the `Definition` group. Task-054 extracted the constant out of
  `site/scripts/gen-reference.mjs` (where it stood at `:150-199`, with the divergent entries at
  `:179` and `:185-186`) into that module; `gen-reference.mjs` now imports it at `:27`. This
  locator is deliberately kept current rather than left as a historical reference, because
  KI-010 is carried forward **open** past the PR and this is the field a later reader will use
  to find the code. The `aid-deploy` / `aid-monitor` half of the original locator no longer
  describes a defect — see the Status note above: measurement showed both agree on either side,
  and only `aid-triage` actually diverges.
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
- **Status:** **CLOSED by delivery-002 (task-016), 2026-07-27.** Landed as an owner-approved
  ride-along (delivery-002 Q1) in the first edit this work makes to `site/astro.config.mjs`, which
  is the sequencing risk R1 describes. The fix is the single property this entry names —
  `enableLog: false` in the `mermaid({ … })` options. Verified at the **bundle** level rather than
  by reading the config: in the built output the integration's logger compiles to a no-op, the
  injected page script contains zero `console.log` calls, and the only surviving `[astro-mermaid]`
  literal sits inside a `console.error`. The console is silent on success, which is what
  feature-006's telemetry contract requires.
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
- **Status:** **CLOSED by delivery-002 (task-016), 2026-07-27.** Owner-approved ride-along
  (delivery-002 Q1), landed in the same edit as the sidebar group. Both comment blocks now state
  that the map already holds four keys and that **no slot is reserved for a feature of this work**,
  which removes the previous work's `feature-NNN` numbering this entry flags as the confusing part.
  The one instruction that was still correct and load-bearing — "do not rewrite this map, only
  add" — is preserved. Comment-only: the four map keys are byte-unchanged, verified by `git diff`.
  Two secondary stale sub-comments inside the `components:` object (a "Reserved slots" line and a
  commented-out `Hero:` placeholder) carried the identical defect over the same cited line range
  and were corrected with it.
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

## KI-016: two vitest suites re-run the same generator concurrently, with no config to stop them

- **Type:** Bug
- **Severity:** Medium
- **Status:** **CLOSED by delivery-002, 2026-07-27.** Routed as delivery-002 **Q2** — an
  orchestrator decision, since this entry states the fix is a routing choice and "not a
  task-boundary problem". Option (b) of the three listed was taken: a minimal
  `site/vitest.config.mjs` setting **only** `test.fileParallelism: false`.
  - **Why not the other two.** Vitest has no per-file opt-out of *file* parallelism, so the
    "shared serial-file annotation" option cannot express what is needed. Per-suite output
    isolation is stronger and survives any future parallelism, but it would require
    `gen-skills.mjs` to accept an output-root override purely for tests — a production API shaped
    by a test constraint, coupling task-017/018 back into task-012/015 while both were still being
    written. It is recorded as the fallback if serial execution ever becomes a measurable cost;
    today the suite is ~870 tests in seconds against a 26s `npm ci`.
  - **It bit before the tasks it was routed for.** The decision expected to land with
    task-017/018, but task-014 had to snapshot the output directory at module-import time to stay
    stable while `gen-skills.test.mjs` regenerated the same tree in a parallel worker — so the fix
    was brought forward to the wave-3 commit. That snapshot is now redundant and deliberately
    retained, as a documented defence rather than a silent fragility if the setting is ever relaxed.
  - **Deliberately does not set `environment`.** feature-006 opts a single file into jsdom with a
    `// @vitest-environment jsdom` docblock and depends on the default staying `node`; setting it
    here would silently break that. Verified.
  - **Residual hazard this does NOT remove:** serialising files stops concurrent *writers*, but a
    suite that reads the generated tree can still be stale relative to the source. That surfaced
    for real at the delivery-002 gate — an over-escaping check passed when its file ran alone
    because it read committed pages and only a sibling suite regenerated them. The durable answer
    is to drive the module in memory rather than read its past output, which is what that check
    now does.
- **Affects:** task-017 and task-018 (delivery-002); grows in delivery-003 (task-031, task-032,
  task-038, task-039) and delivery-004 (task-044)
- **Source:** `site/` has **no `vitest.config.*`** — verified absent; `site/scripts/__tests__/`
- **Description:** Vitest runs test **files** in parallel workers by default. Two suites this work
  adds each prove idempotence by **re-running the generator and comparing bytes**:
  `gen-skills.test.mjs` (AC-6, task-017) and `gen-skills-index.test.mjs` (the index must be
  byte-identical across runs, task-018). Two workers re-running `gen-skills.mjs` against the same
  `src/content/docs/skills/` tree at the same time is a real flake source — one worker's write
  lands between the other's read and compare. Neither feature-001's nor feature-002's SPEC mentions
  it, and feature-006's SPEC notes the missing config file for an unrelated reason.

  It **grows** with the work: delivery-003 adds sidecar and cross-page byte-identity assertions,
  and delivery-004 adds a whole-corpus provenance sweep — all reading the same generated tree.

  **Not a task-boundary problem** — no task list changes. It needs one routing decision before
  task-017 and task-018 land. Three known options: a shared serial-file annotation on the affected
  suites, `--no-file-parallelism` (or a `vitest.config.*` setting) for them, or per-suite output
  isolation so each writes to its own temp tree.
- **Surfaced by:** `/aid-detail` task decomposition, as item G of the architect's "what I had to
  decide" report — a hazard neither SPEC addresses, recorded rather than silently resolved.

## KI-022: ELK layout intermittently not applied — diagrams fall back to dagre routing

- **Type:** Rendering defect (intermittent). **OPEN** — owner deferred the fix; recorded so it is not lost.
- **Severity:** Medium — cosmetic but conspicuous. It is a visible regression of the layout the
  owner explicitly chose at the delivery-003 UI checkpoint ("the pure ELK is the best"), and the
  symptom is exactly the complaint that drove that choice: "some shapes almost overlap and the
  lines are bending strangely".
- **Observed 2026-07-29 (delivery-005, wave 3):** `/skills/aid-define/` rendered with curved,
  diagonally wandering edges and edge labels detached from their edges — dagre routing, not ELK's
  orthogonal segments. Reported by the owner as intermittent: sometimes a diagram renders with the
  correct layout, sometimes not.
- **Ruled out** (checked at the time of the report, so a later investigation need not repeat it):
  - `layout: 'elk'` is present in `astro.config.mjs` `mermaidConfig` (line 53) and **untouched by
    delivery-005** — the only change that delivery makes to that file is the `Head` key
    (`git diff aid/work-001-delivery-004 -- site/astro.config.mjs`).
  - `@mermaid-js/layout-elk@0.2.2` and `elkjs@0.9.3` are both installed, and neither lock entry
    was altered by this delivery's `jsdom` install.
  - The dev server logs `[astro-mermaid] Enabling ELK support` on startup, so the integration
    does register the loader.
- **Two live hypotheses, in order of suspicion:**
  1. **A race between registration and first render.** ELK is registered by a dynamic import; a
     diagram that renders before the loader resolves would fall back to the built-in dagre layout.
     Intermittency, and per-page variation, both fit this. It is also the same family as KI-018 and
     as the stale-cache render failure seen earlier in this delivery.
  2. **Session pollution during diagnosis.** While investigating an unrelated chart failure, this
     session imported mermaid into the live page and called `initialize({ startOnLoad: false })`
     without `layout: 'elk'`. If Vite deduped that to the integration's own instance, the live
     config was overwritten for that tab. This would be self-inflicted and session-only — but it
     cannot explain the owner seeing it intermittently in their own browsing, so it is at most a
     contributing observation, not the cause.
- **Next step when picked up:** compare a `dist` build served by `astro preview` against the dev
  server on a clean browser profile. If `dist` is consistently ELK, the fault is in dev-mode
  timing; if `dist` shows it too, instrument the registration to log whether the ELK loader had
  resolved before the first `render` call. Do not start by changing the config — it is correct.

---

## KI-021: `CHARTABLE_SHAPES` was never widened when the doorway extractors landed — 77 skills charted with no sidecar

- **Type:** Product defect (delivery-003; found in delivery-005, wave 1). **CLOSED** by the same wave.
- **Severity:** High — it would have made delivery-005's headline criterion false on 77 of 111 pages.
- **Affects:** `site/scripts/gen-skills.mjs` (`CHARTABLE_SHAPES`),
  `site/src/data/skill-flows/` (77 missing sidecars), `.skills-manifest.json` (`sidecars`),
  and every downstream consumer of a sidecar — feature-005's guard set and feature-006's route gate.
- **What happened:** task-030 introduced the sidecar write pass gated on `CHARTABLE_SHAPES`, set
  to feature-003's three authored shapes, with a comment predicting its own fix: *"feature-004
  adds the two doorway shapes in tasks 035–037, at which point every skill charts and this set
  equals `SHAPE_ORDER`."* Tasks 035–037 shipped in delivery-003. The set was never widened, so
  the 77 doorway skills rendered a chart on the page and got no sidecar.
- **Why three delivery gates missed it — the part worth keeping:** the omission was
  **self-consistent**. task-030's drift guard derives *both* its expected and its on-disk sidecar
  set from that same constant, so a missing sidecar was never an expected one. And the test
  asserting sidecar coverage carried its **own second copy** of the three-shape list, plus an
  assertion that doorway skills have *no* sidecar. Production and test agreed with each other,
  and both were wrong. A count of "34 sidecars" was even observed during delivery-004's cache
  measurement and not followed up.
- **How it surfaced:** delivery-005's route gate was verified against every `generatedFrom` value
  that actually exists on disk, rather than against fixtures. It admitted 34 of 111 pages. The
  gate was correct; the data was not.
- **Fix:** `CHARTABLE_SHAPES` is now `new Set(SHAPE_ORDER)` — derived, so there is no second list
  to drift. The coverage test reads the shape list from the manifest, which is computed from the
  live classifier, and asserts one sidecar per skill against the directory enumeration.
- **Proven closed in both directions:** restoring the stale constant produces **7 test failures**
  and makes `gen-skills.mjs` **exit 1**, because the 77 sidecars become orphans and the drift
  guard fires. Sidecars are 111, the manifest lists 111, and the route gate admits exactly 111.
- **Lesson, generalisable:** a guard that derives its expectation and its observation from one
  constant cannot detect an error in that constant. Both sides must be independently sourced —
  here, the classifier for one and the filesystem for the other.

---

## KI-020: `index.md` byte-identity test is intermittent in full-suite runs only — **CLOSED, root cause was a 5s test budget**

**Resolution (delivery-005, wave 2).** Not flakiness and never a byte difference: the test
shells the whole generator out **twice** and carried **no explicit timeout**, so it ran against
vitest's 5000 ms default. One generator run measures ~2.4 s, so the pair sits exactly on that
budget and tips over under any additional load — which is precisely the "full-suite runs only"
signature. The failure surfaced as `Test timed out in 5000ms`, which reads like a determinism
failure and sent the original investigation toward parallelism and the dev server.

The sibling two-run test in `gen-skills.test.mjs` had already solved this, budgeting **90000 ms**
at line 748. The index suite now matches it. Verified green both in isolation and in a full
suite run **with the dev server running**, the condition that previously provoked it.

Aggravated, though not caused, by delivery-005 wave 1: fixing KI-021 took the generator from 34
sidecars to 111, lengthening each run and moving the pair from "usually just under" to "usually
just over".

**Lesson:** a test that shells out to a real build step needs a budget sized to that step. A
timeout reported as a test failure is easy to misread as the behaviour under test being wrong.

**Recurrence, and the wider fix (2026-07-29, post-merge).** The per-test annotation closed the
index suite only. The same failure then appeared in `gen-skills.test.mjs` as **7 timeouts at
once**, on a tree where the merge had touched no file under `site/` — so not a regression, just a
slower machine. The suite has **11** `spawnSync`/`execSync` call sites that run the whole
generator, several of them twice to prove byte-identical regeneration, and only **1** carried an
explicit timeout. Generator wall clock measured **~2.4s idle and ~70s under load**, so against
vitest's 5000ms default those tests are a coin flip.

Closed at the class level instead of per site: `site/vitest.config.mjs` now sets
`testTimeout: 90000` and `hookTimeout: 90000`, matching the one annotation that already existed.
That covers tests not yet written rather than relying on each author to remember. The cost is that
a genuinely hung test reports in 90s rather than 5s, which is acceptable here — none of these are
tight unit tests where 5s would be a meaningful signal.

<details>
<summary>Original entry, kept for the investigation record</summary>

**KI-020 (original entry — superseded by the CLOSED entry above; kept for the investigation
record, demoted from a heading so there is exactly one `## KI-020`)**

- **Type:** Flaky test (pre-existing; task-014, delivery-002)
- **Severity:** Low-Medium — it is a real red build when it fires, but no product defect is implicated
- **Affects:** `site/scripts/__tests__/gen-skills-index.test.mjs`, assertion 14 —
  *"re-running the generator leaves index.md byte-identical (buffer comparison, not git diff)"*
- **Observed 2026-07-28, wave 11:** failed **2 of 3** full `npx vitest run` invocations; passed the
  third. Passes **every** time in isolation, and passed **two consecutive** runs of just the two
  generator-touching suites together (`gen-skills` + `gen-skills-index`, 127 tests). So it needs the
  full 35-file run to reproduce, which is why it did not surface during the waves that added those
  suites.
- **What the test does:** `execSync` the generator, read `index.md`, `execSync` again, read again,
  compare buffers. Self-contained, and nothing between the two reads should be able to change bytes.
- **Leading hypothesis, not yet proven: an Astro dev server watching the same tree.** One was running
  on `:4321` throughout tonight's session, watching `site/src/`, while the generator rewrote 111 pages
  plus the index twice per invocation. `fileParallelism: false` (KI-016) serialises test *files* and so
  rules out two suites regenerating at once, which was the previous cause of this class. It does not
  rule out an external watcher. Attempts to stop that server failed — `taskkill` was denied on a child
  process — so the hypothesis is untested rather than confirmed.
- **Why it is not blocking wave 11:** the failure is in a delivery-002 test, unrelated to feature-004's
  scope; wave 11's own suites are green and fully mutation-proven; and the generated tree is
  byte-unchanged, so idempotence itself is not in question — only the test's ability to observe it on
  this machine, under this watcher.
- **CI is the authority.** `.github/workflows/docs.yml` runs `npm test` with no dev server and no
  editor watching, which is the environment the assertion was written for. **Check the delivery-003
  gate's CI run specifically**: if it is green there and flaky only locally, the finding is
  environmental and the fix is to stop running a dev server during a full suite. If it fires in CI
  too, the test needs to stop depending on an unlocked file — capture both runs' bytes under a
  temporary output directory rather than the live tree.

</details>

---

## KI-019: work-004 shrinks the skill corpus 111 → 74 and also edits `site/` — merge-order hazard

- **Type:** Cross-work collision (not a defect in either work)
- **Severity:** Medium — no code change owed by work-001, but a large conflict surface if merged second
- **Affects:** `site/` in its entirety; one hard-coded roster in `site/scripts/__tests__/gen-reference.test.mjs`
- **Source:** `work-004-optimize-skill-library`, worktree `.cursor/worktrees/work-004-optimize-skill-library`,
  branch `work-004`. In **Specify** as of 2026-07-28, no commits yet (branch still at master's `16ea056f`).

### What work-004 removes — measured from the catalogue, not from prose

**37 of the 111 directories under `canonical/skills/` go away, leaving 74** (its AC-1 says "exactly 75";
the one-off is worth reconciling when it lands, not now):

- the 15 `aid-add-*` rows plus bare `aid-add` — all alias rows, deleted with the alias mechanism
- the 15 `aid-change-*` canonical rows — **renamed** to `aid-update-*`, not deleted
- `aid-delete`, `aid-audit`, `aid-investigate`, `aid-spike` — alias rows / hand-authored stubs
- `aid-show-dashboard` — deleted outright (its Q2: viewing a dashboard is a CLI concern)
- `aid-query-kb` — deleted; `aid-ask` becomes the canonical row (its Q1)

**`aid-update-*` and `aid-ask` survive.** The `aid-update-*` names are deleted as *aliases* and recreated
as *canonical* by the rename, so the names persist across the change. Retired names resolve to nothing —
work-004's Q6 dropped every synonym mechanism.

### Why work-001 owes no code change, and must not pre-empt this

`gen-skills.mjs` enumerates `canonical/skills/` and contains no per-skill code. 111 pages exist because
111 directories do; after work-004 lands, one `npm run gen:skills` yields 74 pages, 74 sidecars and a
corrected `shapeCounts` with **no source edit**. That is the dividend from task-001 deleting the count
literals and from every subsequent AC forbidding them.

**Pre-emptively excluding the 37 was considered and rejected** (owner asked, 2026-07-28). It would require
*adding* a hard-coded 37-name list — the exact anti-pattern this delivery's reviews exist to prevent —
and would make work-001 wrong on master meanwhile: the drift guard would throw 37 missing pages, and
suppressing it would ship a knowingly incomplete site. work-004 is also still in Specify with scope that
has already moved repeatedly (Q6 abolished the synonym mechanism; feature-002 folded into feature-004;
FR-12 was reassigned), so any list frozen now would likely be stale before it merged.

### The two things that will actually need doing, and when

1. **`CURATED_SKILL_NAMES` names `aid-query-kb`** (`gen-reference.test.mjs`) — work-001's **only**
   hard-coded roster. It cannot be corrected in advance: the directory still exists, so removing the name
   today makes the clamp fire, correctly. Whoever merges second removes it **at that point**, and should
   check whether `aid-ask` needs its curated/catalogue classification revisited, since work-004 promotes
   it from alias row to canonical row.
2. **work-004's FR-5 sweeps `site/`** — "fix every dangling reference … in the README, `docs/`, `site/`".
   Almost everything under `site/src/content/docs/skills/` and `site/src/data/skill-flows/` is
   **generated**, and work-004 already carries a no-hand-editing-generated-artifacts constraint, so the
   correct action there is to re-run the generator rather than edit pages. Hand-editing them would
   produce ~150 conflicting files and be reverted by the next build anyway.

### Merge order

work-001 should land first — it is nine waves into its final large delivery, and its output is a
regenerable function of the corpus, whereas work-004's changes to the corpus are the input. Landing
work-004 first is survivable but means regenerating the whole site tree inside their branch.

**Related:** work-004's worktree is registered with a **WSL-style gitdir** (`/mnt/c/Projects/…`), which is
the exact path dialect KI-017 documents as arming the next prune. Expect it to lose its registration.

## KI-018: astro-mermaid re-renders from its own output on theme change, breaking every diagram

- **Type:** Bug (third-party integration)
- **Severity:** Medium — cosmetic but total: the diagram is replaced by "Syntax error in text"
- **Affects:** **Every mermaid diagram on the site**, not only generated skill charts. Reproduced on
  the hand-authored pipeline diagram at `/` (17 edges → 0), which no AID code emits.
- **Source:** `site/node_modules/astro-mermaid/astro-mermaid-integration.js` (v11-era build), the
  render loop at ~line 418 and the `data-theme` MutationObserver at ~line 465.
- **Reproduce:** load any page with a diagram, then switch the theme with the Dark/Light selector.
  The diagram renders correctly on load and fails after the switch. A page reload fixes it, so a
  visitor who never toggles the theme never sees it.
- **Mechanism, read from the source.** On first render the integration caches the diagram source:

  ```js
  if (!diagram.hasAttribute('data-diagram')) {
    diagram.setAttribute('data-diagram', diagram.textContent || '');
  }
  ...
  diagram.innerHTML = svg;              // the <pre> now contains the rendered SVG
  ```

  The guard is not atomic across the `await mermaid.render(...)` that follows, and `initMermaid()`
  runs from more than one trigger — initial load, the theme observer, and `astro:after-swap` (Starlight
  uses view transitions). A second pass that arrives after `innerHTML = svg` reads `textContent` from
  the **rendered SVG** and caches that as the "source". Measured: `data-diagram` on a broken page holds
  `#mermaid-1785268632684{font-family:"trebuchet ms",…}` — the SVG's stylesheet. The next theme change
  feeds that to the parser, which is exactly the reported syntax error.
- **Not caused by AID, and specifically not by the `config:` removal in delivery-003 wave 9.** The
  hand-authored diagram at `/` has never carried a per-diagram config block and fails identically.
- **RESOLVED (2026-07-28, owner chose option 1).** Three options were costed:
  1. **Chosen.** Cache the source ourselves before the integration's script runs.
  2. Drop `autoTheme` and accept one diagram theme — rejected, it discards the per-theme legibility
     the sibling fix had just delivered.
  3. `patch-package`, or upstream a fix moving the caching above the render — heavier, and leaves the
     site broken until a release lands.
- **The fix, and why the ordering is sound rather than lucky.** `site/src/scripts/mermaid-source-cache.js`
  is inlined into `<head>` by Starlight's `head:` option. astro-mermaid ships its code through
  `injectScript('page', …)`, which emits a **deferred module** — deferred modules execute after
  parsing, so a classic inline head script installing a `MutationObserver` sees every `pre.mermaid`
  as the parser appends it and is always first. It claims `data-diagram` from the real source, after
  which the integration's `if (!hasAttribute(...))` guard finds it present and never overwrites it.
  This is a property of script types and document order, not a race we happen to win.
- **Three guards, because there are three ways to cache the wrong thing:** an attribute already
  present (never clobber a correct value), an element that already contains an `<svg>`, and content
  containing `@keyframes` (the fingerprint of the SVG stylesheet actually observed in the wild).
- **Verified in the browser, both directions:** the hand-authored diagram at `/` holds 17 edges across
  two theme toggles where it previously went to 0 with a syntax error, and a generated ELK chart holds
  8 edges while its stroke and label colours track the theme on each switch.
- **Tested** in `site/scripts/__tests__/mermaid-source-cache.test.mjs` — the script is a bare IIFE with
  no imports, so it is executed against a minimal fake `document`/`MutationObserver` rather than being
  asserted to merely exist. Seven mutants, all killed.
- **Two things this exercise taught, recorded because both are general.** The happy-path test is what
  exposed that the two guard tests were passing for the wrong reason — the fake element lacked
  `nodeType`, so the script skipped every fixture and "did not cache" was vacuously true. And the
  element-node filter was initially redundant (two downstream `&&` short-circuits absorbed text nodes
  anyway), so removing it killed nothing; rather than pin an assertion that changes no behaviour, the
  downstream guards were dropped so the one remaining filter is load-bearing.
- **Interaction with the wave-9 CSS fix.** The per-theme edge colours in `casulo.css` are selected by
  `[data-theme]`, so they re-colour correctly the instant the theme changes, with no re-render needed.
  They are unaffected by this bug and would keep working under option 2 for one theme only.

## KI-017: worktrees must be created by Windows git, not WSL git

- **Type:** Bug
- **Severity:** High
- **Affects:** `/aid-execute` for every delivery — it provisions **ephemeral per-task worktrees**
  at `.aid/.worktrees/task-NNN/` on the shared delivery branch
- **Source:** `.claude/aid/scripts/works/worktree-lifecycle.sh`; the two git installations
  (WSL git 2.43.0, Windows git 2.54.0 at `C:\Program Files\Git`)
- **Description:** This machine has **two git installations addressing the same repository by
  different names** — `C:\Projects\Personal\AID` for Windows git, `/mnt/c/Projects/Personal/AID`
  for WSL git. Ordinary repository work is unaffected, because git locates `.git` by walking up
  relative paths. **Worktrees are not**: a worktree's `.git` file and its admin directory point at
  each other by **absolute path**, written in the dialect of whichever git created it.

  A WSL-created worktree therefore records `gitdir: /mnt/c/...`, which Windows git cannot resolve.
  Windows git concludes the worktree is abandoned and **prunes its registration during routine
  housekeeping** — which is exactly what happened once in this work: the `work-001` worktree was
  created by WSL git, a Windows `git push` pruned it, and the worktree had to be rebuilt.

  **RECURRED 2026-07-27, during delivery-003 task-020 — with the mechanism now measured rather
  than inferred, and a non-destructive recovery.** The registry directory
  `.git/worktrees/work-001/` was **gone entirely** (only `work-003` remained), so every git
  command inside the worktree answered `fatal: not a git repository: (NULL)`. It surfaced
  indirectly and was nearly mis-filed: task-020 reported `gen-reference.test.mjs` and
  `sync-docs.test.mjs` as *"pre-existing intermittent failures … unrelated to this task"*. They
  were neither pre-existing nor unrelated — both call `git diff` to prove idempotence, and both
  pass again now. **A test suite that shells out to git is this corruption's canary; treat two
  git-dependent suites failing together as this bug until proven otherwise.**

  **The precise trigger, confirmed by `git worktree prune --dry-run -v`:** the `gitdir` file's
  **path dialect** is the whole mechanism. With MSYS-style `/c/Projects/…` git reports
  *"gitdir file points to non-existent location"* and flags the entry **prunable**; with
  Windows-style `C:/Projects/…` it does not. So the entry does not have to be written by WSL git to
  be lost — **any** writer that puts a POSIX-style absolute path there arms the next prune, and
  prunes fire during routine housekeeping.

  **Recovery, non-destructive and preferred over recreating the worktree** (which matters when
  another agent is mid-write inside it — task-021 was, and no working file was touched):
  1. `git worktree repair` **does not help** when the registry directory is absent; it only fixes a
     stale pointer. It fails with *"unable to locate repository"*.
  2. Recreate `.git/worktrees/<name>/` by hand with four files, copying a healthy sibling entry's
     shape: `HEAD` (`ref: refs/heads/<branch>`), `commondir` (`../..`), `gitdir` (the worktree's
     `.git`, **Windows-style**), and an empty `logs/HEAD`.
  3. `git reset` (mixed, no paths) in the worktree to rebuild the missing index — it does not touch
     working files.
  4. Verify with `git worktree prune --dry-run -v`: the entry must **not** be listed.

  **Nothing is at risk but time.** Commits live in the main repository's object store and the
  branch ref survives independently, so all three `aid/work-001-delivery-*` branches and every
  commit were intact; only the administrative link was lost.

  **RECURRED TWICE MORE 2026-07-28, during the delivery-003 tasks-019–029 review checkpoint.** The
  recovery above worked both times unchanged, so it is now the standing procedure rather than a
  one-off. Two refinements worth recording:

  - **The second occurrence presented differently: the registry directory was present and the
    *index* was empty.** `git status` reported **3801 files staged as deletions** with the entire
    tree untracked — alarming, and easily mistaken for catastrophic loss. It is the same bug at a
    later stage: git had recreated the pruned entry without an index. `git reset --mixed HEAD`
    restored it in one step and touched no working file. **Do not reach for `checkout`, `clean`, or
    `stash` on seeing mass deletions in a worktree** — check the registry first.
  - **Both recoveries were triggered by, and both were survivable because of, committing early.**
    The uncommitted edits at the time of the second wipe were five files, all on disk and all
    intact after the rebuild.

  **New, related hazard — a BOM introduced by a PowerShell-mediated file write.** After the review
  sub-agent ran mutation tests, `extract-residual.mjs` and `index.mjs` each differed from `HEAD` by
  a single leading `\ufeff`. The agent had restored them byte-for-byte *as it understood it*; the
  BOM came from the write path, not the content — Windows PowerShell's `Set-Content`/`Out-File`
  emit UTF-8 **with** BOM by default. Node strips a leading BOM, so nothing failed and no test
  caught it; only `git status` did. **Any agent instructed to mutate-and-restore a file must be told
  to restore via a BOM-free write** (`python`'s `write_text(..., encoding="utf-8")`, or
  `Set-Content -Encoding utf8NoBOM` on PowerShell 6+), and the orchestrator should diff the
  supposedly-restored files rather than trusting the report.

  **Standing rule for this repository: use Windows git.** The worktree at
  `.claude/worktrees/work-001` has been recreated with Windows git and now records
  `gitdir: C:/Projects/Personal/AID/.git/worktrees/work-001`.
  - Run AID's shell scripts under **Git Bash** (`C:\Program Files\Git\bin\bash.exe`), which
    provides `grep`, `sed`, `awk`, `find`, `sort`, `uniq`, `xargs` and `python` (pyenv shims) —
    verified — while using Windows git underneath.
  - Do **not** invoke the scripts through WSL bash; a bare `bash` on this machine resolves to WSL.
  - Windows git also already has credentials via the Git Credential Manager, so pushes work;
    WSL git has no credential helper and hangs silently on an invisible prompt.
  - Watch for MSYS path translation under Git Bash: it rewrites POSIX-looking arguments into
    Windows paths when calling native binaries. Relative paths are fine; an absolute path passed
    as an argument can be mangled. Escape hatch: `MSYS2_ARG_CONV_EXCL`.
  - Secondary evidence for the same choice: Windows git is markedly faster here, because the repo
    is on NTFS and WSL reaches it over `/mnt/c`. Measured in this session — 51s vs 5–9s for the
    same read-only git commands, and 95s for a checkout plus worktree create.
- **See also:** KI-005, which records the resulting `git diff`-based idempotency failures as
  "environmental" — this entry is the operational cause and the rule that prevents them.
