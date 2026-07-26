# Plan -- Skill Explorer

Delivery roadmap for `work-001-skill-explorer`. Each deliverable below is a functional MVP that
stands on its own. Sequenced Must → Should.

> **Wave convention — applies to every `#### Execution Graph` in this file.** A dependency on a
> task in an **earlier delivery** is shown in that delivery's table but treated as satisfied at
> entry for wave numbering, because the earlier delivery must be Done before this one starts.
> So **wave 1 is the set of tasks with no *intra-delivery* dependency**. Within a delivery, wave N
> is every task whose dependencies all sit in waves below N, derived mechanically from the
> `Depends On` table rather than composed by hand.

## Deliverables

### delivery-001: Green, CI-gated site test suite
- **What it delivers:** the `site/` vitest suite passes on a clean `npm ci`, and `docs.yml` runs
  it on every pull request to `master` touching `site/**`. Today the suite is **red before this
  work touches anything** (KI-005) and **no workflow runs it at all** (KI-006).
- **Features:** feature-001-skill-detail-pages *(partial — the owner-amended §7 build-integration
  scope only: correct the eight stale roster items as source-derived checks, triage the five
  TypeScript suites that have never executed in CI, then add the `npm test` step)*
- **Depends on:** --
- **Priority:** Must
- **Stands alone because:** it reverts independently of the generator, and fixes defects that
  predate this work. Per feature-001's own Migration Plan, reverting the generator while keeping
  these leaves the repo strictly better off than it started. Its acceptance is clauses (b), (c)
  and (d) of feature-001's build-integration criterion — each checkable the day it lands.
- **Why it is first, and separate:** every acceptance criterion in this work after AC-1 is
  specified as a vitest test. Landing the generator first and the CI wiring later would leave
  D2's and D3's central quality claims unenforced on the very pull requests that introduce them
  — the exact failure mode KI-006 records as the reason KI-005 went unnoticed. It is split out
  of D2 rather than folded in because **Part C is an open-ended triage**: five TypeScript suites
  have never executed in CI, and an unrelated red suite must not be able to block the generator's
  gate.

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002, task-003 |

| Can Be Done In Parallel |
|------------------------|
| — (none — a hard chain by design: the triage must run against the corrected suite, and CI is wired only once the suite is confirmed green) |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002
wave 3: task-003
wave 4: task-004
```

### delivery-002: A browsable `/skills/` catalog
- **What it delivers:** a new published `/skills/` section — an index of one card per skill for
  all 111, nested under the four curated groups with `Definition` subdivided by verb family, and
  a detail page per skill whose header renders **every** frontmatter key the file carries. Wired
  into the sidebar and the header tab bar. None of this exists today: `reference/skills.md` shows
  only `description` and deliberately collapses the shortcuts into family tables.
- **Features:** feature-001-skill-detail-pages *(remainder — the generator harness)*,
  feature-002-grouped-skill-index
- **Depends on:** delivery-001
- **Priority:** Must
- **Stands alone because:** it is the smallest state in which a reader can find and read a
  skill's complete declared contract — including the `allowed-tools` and `argument-hint` keys the
  existing parser drops. The chart slot renders as a comment, so a page is visibly a page with an
  unfilled slot rather than a broken one, and AC-1, AC-2, AC-6 and AC-8 are all fully satisfied
  and independently testable the day it lands.
- **Why feature-002 is here and not later:** without the index, the 111 pages are reachable only
  by typing a URL — no index, no sidebar entry, and the Skills tab never highlights on any of
  them. A page set outside the site's navigation is not a shippable state.

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-005 | task-004 *(delivery-001)* |
| task-006 | task-004 *(delivery-001)* |
| task-007 | task-004 *(delivery-001)* |
| task-008 | task-004 *(delivery-001)* |
| task-009 | task-005 |
| task-010 | task-006, task-007 |
| task-011 | task-008 |
| task-012 | task-009, task-010 |
| task-013 | task-012 |
| task-014 | task-007, task-011 |
| task-015 | task-012, task-014 |
| task-016 | task-015 |
| task-017 | task-015 |
| task-018 | task-015 |

| Can Be Done In Parallel |
|------------------------|
| task-005, task-006, task-007, task-008 |
| task-009, task-010, task-011 |
| task-012, task-014 |
| task-013, task-015 |
| task-016, task-017, task-018 |

> **Not parallel, and load-bearing:** task-012 and task-015 both own `gen-skills.mjs` — 015 adds
> the index steps to the entrypoint 012 creates, so it must follow, never accompany.

```wave-map
delivery: 002
wave 1: task-005, task-006, task-007, task-008
wave 2: task-009, task-010, task-011
wave 3: task-012, task-014
wave 4: task-013, task-015
wave 5: task-016, task-017, task-018
```

### delivery-003: A flow chart on every skill page
- **What it delivers:** every skill detail page carries a derived flow chart in its body — ordered
  steps, loops, decision branches and exit points, with a short derived label in each node.
  Authored-flow skills get their own chart; the delegating majority get the shared
  shortcut-engine chart inline with their `{verb, artifact}` binding at the entry node, and
  kind-siblings additionally show the hop into their parent's spliced chart. FR-2's whole-corpus
  coverage completes here.
- **Features:** feature-003-authored-flow-charts, feature-004-doorway-engine-charts
- **Depends on:** delivery-002
- **Priority:** Must
- **Stands alone because:** it is the first deliverable that fulfils §1's actual promise — a
  reader can state what a skill does step by step without opening the source. It carries AC-3 and
  all four AC-4 fixtures, so its acceptance closes cleanly.
- **Why 003 and 004 are one deliverable:** feature-003's providers claim the authored-flow and
  residual shapes only, so the delegating majority stays chart-less until 004. Shipping 003 alone
  would publish a corpus where a minority of pages have charts and most have an empty slot —
  visibly inconsistent, and it would make AC-3's "every chart" trivially true over a partial
  corpus while FR-2 goes unmet. They are one user-facing outcome. Internally: 003 first (model,
  classifier, validator, renderer, substrate), then 004, which consumes 003's published API
  unchanged.

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-019 | task-018 *(delivery-002)* |
| task-020 | task-019 |
| task-021 | task-019 |
| task-022 | task-020 |
| task-023 | task-022 |
| task-024 | task-020 |
| task-025 | task-020, task-021, task-023 |
| task-026 | task-020, task-021, task-023 |
| task-027 | task-020, task-021, task-023 |
| task-028 | task-020 |
| task-029 | task-024, task-025, task-026, task-027, task-028 |
| task-030 | task-019, task-029 |
| task-031 | task-030 |
| task-032 | task-031 |
| task-033 | task-032 |
| task-034 | task-032 |
| task-035 | task-033, task-034 |
| task-036 | task-033, task-034 |
| task-037 | task-035, task-036 |
| task-038 | task-037 |
| task-039 | task-038 |

| Can Be Done In Parallel |
|------------------------|
| task-020, task-021 |
| task-022, task-024, task-028 |
| task-025, task-026, task-027 |
| task-033, task-034 |
| task-035, task-036 |

> **Two hard serializations.** task-022 → task-023 both write `advance.mjs`, so they are a strict
> sequence, not a pair. And **no feature-004 task (task-033 onward) may start before task-032 is
> Done** — task-037 edits `flow-graph/index.mjs`, which feature-003 creates in task-029, and
> `body.mjs`, which **feature-001 created back in task-010** and which feature-003 only appends a
> provider entry to. Either way task-037 edits files it does not own, so the edges encode the
> ordering rather than merely describing it.

```wave-map
delivery: 003
wave 1: task-019
wave 2: task-020, task-021
wave 3: task-022, task-024, task-028
wave 4: task-023
wave 5: task-025, task-026, task-027
wave 6: task-029
wave 7: task-030
wave 8: task-031
wave 9: task-032
wave 10: task-033, task-034
wave 11: task-035, task-036
wave 12: task-037
wave 13: task-038
wave 14: task-039
```

### delivery-004: Verbatim fragments and `canonical/` deep links
- **What it delivers:** beneath every chart, an ordered `## Source fragments` list — one entry per
  node, in chart order, carrying the byte-exact prompt text that composes that step plus a deep
  link to the exact lines in `canonical/`. A recorded range that no longer matches its file fails
  the build.
- **Features:** feature-005-verbatim-source-provenance
- **Depends on:** delivery-003
- **Priority:** Must
- **Stands alone because:** it is static markdown needing no JavaScript, so it discharges AC-5 and
  NFR-2 on its own — which is precisely the property that lets delivery-005 remain a Should. This
  is also the point at which the work has delivered everything §9 asks for.
- **Why it follows delivery-003 rather than running beside it:** feature-005 is shape-blind and
  does not read feature-004's document, but its AC-5 sweep walks *every* directory under
  `canonical/skills/` and calls `buildFlowChart` on each — which cannot return a chart for a
  delegating skill until feature-004's extractors are dispatched. The dependency is real; it is
  an acceptance dependency rather than a code one.

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-040 | task-039 *(delivery-003)* |
| task-041 | task-039 *(delivery-003)* |
| task-042 | task-040 |
| task-043 | task-041, task-042 |
| task-044 | task-043 |

| Can Be Done In Parallel |
|------------------------|
| task-040, task-041 |

```wave-map
delivery: 004
wave 1: task-040, task-041
wave 2: task-042
wave 3: task-043
wave 4: task-044
```

### delivery-005: Click-to-open node panel
- **What it delivers:** selecting a node in a chart — by pointer or keyboard — opens a panel in
  place showing that node's name, derived label, verbatim fragment and `canonical/` deep link,
  without leaving the chart.
- **Features:** feature-006-interactive-node-panel
- **Depends on:** delivery-004
- **Priority:** **Should**
- **Stands alone because:** it is additive polish over a page that is already complete. Its own
  AC-6.4 is the machine-checkable statement that it cannot damage the Musts beneath it, and its
  rollback is four deletions and two one-line reverts.
- **Explicitly droppable.** This delivery may be dropped at delivery-004's gate **without
  replanning anything** — nothing depends on it, and AC-5 is already discharged by delivery-004's
  static list. Two owner decisions must be answered before it starts, not before delivery-001:
  whether `jsdom` is acceptable as a test-only devDependency, and whether the manual browser
  checks are blocking and who runs them. **If `jsdom` is declined, drop this delivery rather than
  ship its riskiest half unverified.**

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-045 | task-044 *(delivery-004)* |
| task-046 | task-044 *(delivery-004)* |
| task-047 | task-046 |
| task-048 | task-047 |
| task-049 | task-046 |
| task-050 | task-049 |
| task-051 | task-046 |
| task-052 | task-046, task-049 |
| task-053 | task-045, task-049, task-050, task-051 |

| Can Be Done In Parallel |
|------------------------|
| task-045, task-046 |
| task-047, task-049, task-051 |
| task-048, task-050, task-052 |

> **task-049 → task-050 is a strict sequence** — both write `site/public/skill-node-panel.mjs`,
> and task-049 deliberately lands an incomplete intermediate state (`aria-controls` naming a panel
> that task-050 creates). It is the one point in the work where a task's gate passes on a file that
> is not yet shippable; all three of its own documents say so.
>
> **task-048 is the third editor of `site/astro.config.mjs`** (risk R1). It must follow
> delivery-002's task-016 and any KI-001 ride-along, and must never run concurrently with either.
> The task template has no cross-delivery dependency field, so task-048 states the constraint in
> Scope and requires evidence in the delivery record that it was honoured.

```wave-map
delivery: 005
wave 1: task-045, task-046
wave 2: task-047, task-049, task-051
wave 3: task-048, task-050, task-052
wave 4: task-053
```

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| R1 | `site/astro.config.mjs` has three would-be editors — delivery-002's sidebar group, delivery-005's `components:` key, and conditionally delivery-003's KI-001 repair. All three SPECs independently flag it. | M | The sequence already serialises them (002 → optionally 003 → 005), so the residual risk is only parallel agents *within* a delivery. Two one-line ride-alongs (KI-012, KI-013) belong with whichever edit lands first, which is delivery-002's. |
| R2 | Every delivery's acceptance is "tested with vitest", and nothing runs vitest today. Until delivery-001 lands, the `prebuild` throw is the only automated gate on a pull request. | H | This is exactly what delivery-001 retires, and it is the strongest argument for its position first. |
| R3 | Five TypeScript suites have never run in CI; their assertions are unverified and may carry staleness of the same kind as KI-005. An open-ended triage sits inside delivery-001. | M | Isolated in delivery-001 so it cannot block the generator's gate, and surfaced at the earliest possible point. **Escalation path:** anything delivery-001 cannot absorb is a gate escalation to the owner, not silent scope. |
| R4 | `body.mjs` is created by feature-001 and appended to by 003, 004 and 005; `flow-graph/index.mjs` is created by 003 and gains two dispatch rows from 004. | M | The two chart providers *partition* the shape enum, so array order is not load-bearing, guarded by a test asserting exactly one `applies()` fires per directory. Within delivery-003 the two features must still be ordered, not concurrent. |
| R5 | Four contract seams between the SPECs are unreconciled (sidecars in the drift guard, the `shapeCounts` fourth manifest key, the `## Flow` heading, `delegatesTo`), so **delivery-003 must reopen contract text delivery-002 froze**. | M | Each is a one-line decision, and all four are explicit delivery-003 gate criteria rather than implementer discoveries. Anticipated by feature-001 framing the harness as a published interface. |
| R6 | A commit editing `canonical/` without regenerating pages triggers no docs build, so deployed deep-link anchors can sit one generation stale. | L | Decide feature-005's OQ-3 (whether `docs.yml`'s path filter gains `canonical/**`) at delivery-001, while the workflow is already open, rather than at delivery-004 where it would reopen a shipped artifact. |
| R7 | This work is the first change to multiply the site's page count by an order of magnitude: 111 pages into the content collection and Pagefind index, ~112 extra sidebar anchors on every page, then a client-rendered chart on each, then a near-duplicate fragment list across the delegating majority. | L | Every increase is linear and none is gated on a budget. feature-001 asks for the `docs.yml` build time to be read on the first run; that reading belongs at delivery-002's gate. |

## Deferred

Nothing is deferred **out of the plan** — every `Ready` feature is assigned to a delivery. What
follows is work adjacent to the plan, each with its revisit trigger.

| Item | Reason | Revisit When |
|------|--------|--------------|
| KI-009 (family table renders six `0` rows and `-1 typed forms`), KI-010 (stale `SKILL_GROUPS`), KI-003 (stale header comment) | All inside `gen-reference.mjs`, which §7 freezes. Fixing them is a different work. | The §7 freeze lifts. At that point feature-002's divergence note should be **deleted**, not left to rot. |
| KI-002 (KB structural-shape figures are stale) | A KB correction, not a product change. The live figures belong in delivery-003's `shapeCounts` manifest entry. | The KB update at ship — regenerate the row from the manifest or remove its numbers. |
| KI-007 (the KB's `docs.yml` trigger row is wrong in both directions) | KB correction. Delivery-001 makes it further wrong. | The KB update accompanying delivery-001's ship. |
| AC-7 formalized into a repeatable review step | §10 Could; feature-005 wires it into nothing deliberately. | A Fail or Pass-with-observations verdict at delivery-004's AC-7 spot-check. |
| feature-002 OQ-1 — do `aid-query-kb` / `aid-ask` stay in Knowledge Base Maintenance? | Default implemented (they stay), which leaves the `query` family rendering no section. Non-blocking. | Owner review of the rendered index at delivery-002's gate. Reversal is two names deleted from one array. |
| feature-004 OQ-2 — `aid-ask`'s own `## Pre-flight` guard is not drawn | Accepted as a recorded warning; a rule tuned to one file is worse than the loss. | A second sibling-doorway skill acquires its own control-flow sections. |
| feature-005 OQ-1 — the doorway fragment list repeats across most of the corpus | Default is render in full, per FR-6's standalone-page promise. Alternatives are each a one-line change. | Measured Pagefind index size or a search-quality complaint after delivery-004. |
| KI-001 / KI-012 / KI-013 if the owner declines the ride-alongs | Cosmetic-to-medium defects in a file this work already opens. | The next edit to `site/astro.config.mjs`. |
