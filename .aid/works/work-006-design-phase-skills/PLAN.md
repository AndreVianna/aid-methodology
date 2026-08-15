# Plan -- Design Phase Skill Family

> **Work:** work-006-design-phase-skills
> **Created:** 2026-08-09

Three deliveries, grouped by skill family. The grouping is driven by one property of the
six feature specs: **two feature pairs are mutually dependent**, and a mutual pair cannot
be split across a delivery boundary without producing a cycle between deliveries.

- **feature-001 ↔ feature-003.** feature-001 blocks feature-003 on doctrine and
  membership (feature-001 SPEC § *Dependencies*, *Outbound*), and feature-003 hands back
  the two document **instances** and parts 1–3 of the `### roadmap.md` / `### backlog.md`
  blocks in `document-expectations.md` (feature-001 SPEC § *Dependencies*, *Inbound*;
  feature-003 SPEC § *Dependencies, hand-offs, and sequencing*).
- **feature-004 ↔ feature-005.** feature-004 needs one description edit from feature-005
  (bare `/aid-design`'s narrowing — feature-004 SPEC § *Dependencies and sequencing*), and
  feature-005 needs three counterpart descriptions from feature-004
  (`/aid-design-testing-strategy`, `/aid-design-stack`, `/aid-design-cicd` — feature-005
  SPEC § *Boundaries*).

Each pair is therefore absorbed **inside** one delivery. What that leaves is **almost**
one-directional — delivery-001, then delivery-002, then delivery-003, written in run order as
a comma-separated list per the arrow convention in § *Execution Graph* — with one stated
exception rather than none.

**The one back-edge, named because a blanket claim would be false.** feature-002
(delivery-001) declares a dependency on feature-006 (delivery-003) for *one half of one
oracle*: the render that puts its three new templates into the five profiles runs **once,
in feature-006** (feature-002 SPEC § *Sequencing, dependencies, and shipped-behavior
impact*). Its AC-11 is therefore split — G3 asserts the `canonical/` side at feature-002's
own close, I1 asserts the `profiles/` side after delivery-003's render. This is a
*verification* edge, not a build edge: nothing feature-002 authors waits on feature-006,
so it does not make the two deliveries mutually dependent and does not need absorbing the
way the two pairs above did. It is recorded here so that "every dependency is
one-directional" is never read as "no edge runs backwards". The same shape governs the
deferrals in the deliveries' Out-of-scope sections (the render, the byte-identity gate,
every count-bearing surface) — those are the general case of this one edge.

**This work lives on a single `work-006` branch and merges to master as ONE pull
request.** No intermediate delivery lands on master independently. That is what makes
delivery-003 safe: every count-bearing surface in the repo — the roster counts, the
catalog test assertions, `tests/coverage-baseline.tsv`, the site card counts, the KB and
methodology narratives — can be deferred to the last delivery without the repo-wide count
guard or the coverage-parity lane going red mid-work.

**That safety has a precondition, and it is an action, not a property: open the pull
request only after delivery-003 closes.** CI is not "only ever evaluated against the
merged result". `.github/workflows/test.yml` triggers on `pull_request: branches: [master]`
**and** `push: branches: [master]`, and `.github/workflows/coverage-parity.yml` has the
same shape scoped to `tests/**`. A `pull_request` trigger re-runs on **every push to the
PR head**, so a PR opened during delivery-001 puts render-drift, byte-identity, the count
guard and the coverage-parity lane against every intermediate state — each of which is
mid-flight by design and would go red. Work on the branch, push freely, and open the PR
last. If a PR must be opened earlier for review, expect and accept red on those four lanes
until delivery-003 lands; do not "fix" them by moving count-bearing surfaces earlier,
which is the failure this plan's grouping exists to prevent.

## Deliverables

### delivery-001: Lifecycle Machinery, KB Doctrine, and Planning Skills

- **What it delivers:** The shared foundation every later skill binds to — `.aid/design/`
  landed and corrected, the three-stage `design → create → update` contract and the seed
  shape as canonical templates — plus the KB doctrine and conditional-membership change
  that admits forward-looking documents, and the first nine skills to exercise the whole
  chain end to end (roadmap, backlog, mvp).
- **Features:** feature-002-design-lifecycle-machinery,
  feature-001-kb-doc-set-restructure, feature-003-planning-artifact-skills
- **Depends on:** --
- **Priority:** Must

### delivery-002: Foundation and Grid Skills

- **What it delivers:** The remaining twenty-seven skills — twelve foundation skills
  (architecture, stack, testing strategy, CI/CD) that promote settled technical decisions
  into the correct KB document by concern, and the fourteen `design` grid rows plus
  `/aid-brainstorm`, which make the `design` stage uniform across the existing catalog and
  compose it with the shortcut engine through one additive seed read.
- **Features:** feature-004-foundation-artifact-skills,
  feature-005-design-grid-and-brainstorm
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: Integration and Close-Out

- **What it delivers:** The work made real and consistent repo-wide — the full render to
  five profiles with both dogfood trees resynced and both byte-identity tuples green,
  every count-bearing surface moved to its own new value (and the ones that must not move
  left alone), including the three stale count comments inside `shortcut-catalog.yml` that
  deliveries 001 and 002 hand here; the catalog test assertions and the coverage baseline
  brought into parity; the site card counts; and AID's own description of what it now has
  in the Knowledge Base and the methodology narrative — closing with the two generated
  summaries, `INDEX.md` and then `kb.html`, the latter regenerated by re-running
  `/aid-summarize`.
- **Features:** feature-006-integration-and-close-out
- **Depends on:** delivery-002
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | `tests/coverage-baseline.tsv` gains ~144 rows (36 catalog rows × 4 per-row keys). The `coverage-parity` lane **enforces** — exit 1 — whenever that baseline file is present, and it is present today (`tests/coverage-baseline.tsv`, `tests/coverage-baseline.meta`). Its trigger fires on any `tests/**` change, which delivery-003's own test edits guarantee. The remedy is a **CI-only re-bootstrap** that cannot be run from this Windows worktree. | H | Owned by feature-006 SPEC §4c. Schedule it as an explicit hand-off with a CI run (`workflow_dispatch`, `bootstrap: true`), not as a local command; commit `.tsv` and `.meta` together and never hand-edit the `.tsv`. The re-bootstrapped baseline must still hold exactly 34 `CDP{i}e`/`f`/`g` rows — a second, independent confirmation of risk 3. |
| 2 | `canonical/aid/templates/shortcut-engine.md` is the shared template behind every generated thin doorway, and FR-10's seed read is **the only change in this work that touches shipped behavior of existing skills**. | H | Owned by feature-005 SPEC §4a–§4b, inside delivery-002. The read is bounded by three stated properties — conditional (absent seed ⇒ byte-identical behavior), non-mutating, additive — with REQUIREMENTS AC-10 as the criterion and feature-005 SPEC §8 V13/V14 as its oracles. Note the corrected figure: the engine is the template for the **34** generated doorways, not all 58 catalog rows (the other 24 are `repurpose: true` and never enter it); the read itself reaches the 26 of those 34 that carry a non-empty artifact. REQUIREMENTS FR-10's "58" is the catalog size, not the engine's reach — feature-005 §4a records the correction, and it does not change the conclusion. |
| 3 | The `shortcuts` (emitting) quantity does **not** move from 34: all 36 new rows are `repurpose: true`, so none is counted as emitting. Roughly half the count-bearing sentences in the repo use that phrasing, so a naive "update every count" sweep would corrupt them. | H | Owned by feature-006 SPEC §2 (the per-quantity delta table, stated per quantity rather than as one number) and §3 (the guard binds phrasing to quantity). The `shortcuts`-untouched row in feature-006 SPEC §10 is deliberately a **negative** oracle — it fails when work is over-applied, which is this delivery's most likely error mode — and §4c's unchanged `CDP{i}e/f/g` count is the independent second confirmation. |
| 4 | Both mutual dependency cycles are absorbed inside a single delivery, so no cycle exists across a delivery boundary today. The residual risk is that a spec edit made during Detail or Execute re-opens one **across** a boundary — for example by moving a description, a block's content, or a registration surface to the other side of the 001/002 line. | M | The two pairs are named at the top of this plan; any change that would add an obligation from a later delivery back into an earlier one is resolved by **moving the obligation to the owning delivery**, not by re-ordering deliveries. REQUIREMENTS FR-11's governing rule is the standing guard: a cross-feature rule is stated once in FR-11 and referred to, never restated — restating it is how a boundary quietly moves. |
| 5 | **`kb.html` is regenerated by an authored `/aid-summarize` run, not by a script.** The last recorded full GENERATE took **24m20s** and produced a 178 KB / 20-section file (`.aid/knowledge/STATE.md` § Calibration Log), and its automated visual check does not run at all — `validate-visuals.mjs` is SKIPPED because Playwright is not installed in the summarize package, so the V1 gate is an **orchestrator** step. Two failure modes follow: sizing it as a command inside another task, and promising a visual gate that cannot run. | M | Owned by feature-006 SPEC § *KB and methodology refresh*, inside delivery-003, where it is a named Scope item with its own gate criterion and its own §10 verification row (four conjuncts, plus an explicit *not asserted* row for the visual gate). Cut it as its **own** task, ordered last — it reads `.aid/knowledge/*.md`, so a run started before the KB refresh is final bakes in the pre-refresh figures. Note the interaction with risk 3: the regenerated file must still read `34 verb-first shortcuts`, which makes it a **third** independent witness that `shortcuts` did not move. |

## Execution Graph

> Appended by `/aid-detail`. **All three deliveries.** The work is fully detailed: 74 tasks,
> task-001..task-074.
>
> In the edge lists and the dependency table below, `A → B` reads **“A depends on B”** — B
> runs first. Execution-order sequences are written as comma-separated lists in run order.
>
> **Task numbering is allocation order, not execution order.** This graph and the per-task
> `Depends on:` fields are the sole authority on sequencing. Some edges point from a
> lower-numbered task to a higher-numbered one, and they fall into two causes. The two lists
> are **disjoint**, and their **union is exactly the set of edges in the dependency table whose
> target is higher-numbered than its source** — the one invariant kept here, because it is what
> makes the classification complete rather than illustrative:
>
> - **Appended** — tasks 021–025 were cut during the Detail fix passes and appended rather
>   than inserted: `009 → 023`, `015 → 024`, `016 → 021`, `018 → 023`, `020 → 025`.
> - **Content or shared-state**, between tasks that all predate every fix pass:
>   `007 → 010` (task-007's `find canonical/aid/templates -type f …` walks a directory
>   task-010 writes into — the meet is carried by
>   `canonical/aid/templates/shortcut-catalog.yml`), `009 → 012` (the drain is keyed on the
>   `## Next Release` heading and the `Title` column, which task-012 fixes), `017 → 018`
>   (task-017 asserts against `backlog.md`, whose **last** writer is task-018).
>
> **Neither delivery-002 nor delivery-003 adds an edge to either list, and that is a property
> of their numbering rather than a claim about it:** the task ids of both were allocated in
> execution order, so every edge in their dependency tables points from a higher-numbered task
> to a lower-numbered one. The union above is therefore unchanged at **eight** edges, and the
> invariant it states — that the union is exactly the set of edges whose target is
> higher-numbered than its source — holds over the **combined** table of all 74 tasks, not only
> over delivery-001's block.
>
> The combined graph is acyclic and single-rooted at task-001. delivery-002 enters through the
> single edge `026 → 020` and delivery-003 through the single edge `050 → 049`, which is why
> every earlier task is a transitive ancestor of every later delivery's tasks; task-020 remains
> delivery-001's own leaf, task-049 delivery-002's, and the combined leaf is task-074.

### delivery-001

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-003 |
| task-005 | task-004 |
| task-006 | task-005 |
| task-007 | task-006, task-010 |
| task-008 | task-007 |
| task-009 | task-012, task-023 |
| task-010 | task-005 |
| task-011 | task-007, task-008, task-010 |
| task-012 | task-011 |
| task-013 | task-012 |
| task-014 | task-013 |
| task-015 | task-024 |
| task-016 | task-021 |
| task-017 | task-007, task-018 |
| task-018 | task-009, task-023 |
| task-019 | task-017, task-018 |
| task-020 | task-025 |
| task-021 | task-015 |
| task-022 | task-016 |
| task-023 | task-022 |
| task-024 | task-014 |
| task-025 | task-019, task-023 |

| Can Be Done In Parallel |
|------------------------|
| task-006, task-010 |

```wave-map
delivery: 001
# Totality invariant: every task in the dependency table above appears here exactly once,
# and its wave is 1 + the maximum wave of its dependencies. Both halves are checkable by
# recomputing the map from the table; a task appearing twice, or not at all, is a defect.
wave 1: task-001
wave 2: task-002
wave 3: task-003
wave 4: task-004
wave 5: task-005
wave 6: task-006
wave 6: task-010
wave 7: task-007
wave 8: task-008
wave 9: task-011
wave 10: task-012
wave 11: task-013
wave 12: task-014
wave 13: task-024
wave 14: task-015
wave 15: task-021
wave 16: task-016
wave 17: task-022
wave 18: task-023
wave 19: task-009
wave 20: task-018
wave 21: task-017
wave 22: task-019
wave 23: task-025
wave 24: task-020
```

**Feature lanes.** One wave carries parallelism: wave 6 runs feature-001's doctrine start
(task-006) beside feature-003's first skill task (task-010), and the two share no path. The
interleave this delivery exists for is carried by `018 → 023` and `017 → 018`: feature-001's
steps 5 and 6 cannot start until feature-003 has created the documents and finished
verifying against them.

**Where the `update` skills are consumed.** task-014 is not a leaf — the dependency table
above shows what descends from it, and the `wave-map` shows when. The rows those descendants
carry (V7 and V8/E3; V17, V21, V22, V23, V24 and V27) are named in each task's own Scope.

### delivery-002

#### Execution Graph

Task ids continue from delivery-001's block; delivery-002 holds task-026..task-049. Waves
continue too, because the wave rule is `1 + max(wave of dependencies)` applied to the **one**
dependency table these two blocks together form — task-026 depends on task-020, which sits at
wave 24, so delivery-002 opens at wave 25.

| Task | Depends On |
|------|-----------|
| task-026 | task-020 |
| task-027 | task-026 |
| task-028 | task-027 |
| task-029 | task-028 |
| task-030 | task-029 |
| task-031 | task-030 |
| task-032 | task-031 |
| task-033 | task-032 |
| task-034 | task-033 |
| task-035 | task-034 |
| task-036 | task-035 |
| task-037 | task-036 |
| task-038 | task-037 |
| task-039 | task-038 |
| task-040 | task-039 |
| task-041 | task-040 |
| task-042 | task-041 |
| task-043 | task-042 |
| task-044 | task-043 |
| task-045 | task-043 |
| task-046 | task-043 |
| task-047 | task-043 |
| task-048 | task-044, task-045, task-046, task-047 |
| task-049 | task-048 |

| Can Be Done In Parallel |
|------------------------|
| task-044, task-045, task-046, task-047 |

```wave-map
delivery: 002
# Totality invariant: every task in the dependency table above appears here exactly once,
# and its wave is 1 + the maximum wave of its dependencies. Both halves are checkable by
# recomputing the map from the table; a task appearing twice, or not at all, is a defect.
wave 25: task-026
wave 26: task-027
wave 27: task-028
wave 28: task-029
wave 29: task-030
wave 30: task-031
wave 31: task-032
wave 32: task-033
wave 33: task-034
wave 34: task-035
wave 35: task-036
wave 36: task-037
wave 37: task-038
wave 38: task-039
wave 39: task-040
wave 40: task-041
wave 41: task-042
wave 42: task-043
wave 43: task-044
wave 43: task-045
wave 43: task-046
wave 43: task-047
wave 44: task-048
wave 45: task-049
```

**Why the authoring half is a chain.** Most of the authoring tasks append to the one file
`canonical/aid/templates/shortcut-catalog.yml` — the Writers cell of that resource's row in the
derived view below is the list, kept in one place — and two concurrent appends to one file is
the hazard the writer chain exists to prevent. The authoring tasks that do **not** write it are
task-026, task-027, task-028 and task-034, and each is chained for its own reason rather than
for that one. task-026, task-027 and task-028: every one of the twenty-seven bodies is modelled
on `canonical/skills/aid-design/SKILL.md` (feature-002 §3e), which task-028 rewrites, and
task-028's routing text has to agree with the clause task-027 writes into
`canonical/skills/aid-create-document/SKILL.md` — so feature-005's *edit-what-exists* tasks run
ahead of the new doorways rather than after them. task-034: it lands the doctrine the `create`
bodies that follow it cite, and feature-004 §12 places the registration *"with, or after"* the
doctrine amendment delivery-001 already committed.

**Where the two features interleave, and why the order is that one.** feature-005's fifteen
rows land before feature-004's twelve because feature-004 §1b places its four `design` rows
*"in the G3 block after feature-005's fourteen"*. Inside feature-004, §12's internal order is
then followed exactly: the `design` stage that resolves the destination by concern (task-033),
then `quality-gates.md`'s registration (task-034), then `create` (task-035..task-037), then
`update` (task-038), which needs a destination that exists and is under CC-3 also the consumer
of any seed `create` routes to it.

**The one wave that carries parallelism.** Wave 43 runs four verification tasks side by side —
task-044, task-045, task-046 and task-047. Each confines every run to a scratch project under
`mktemp -d`, so all four declare an empty write set and share no path with each other. That is
what makes them schedulable together, and it is why the four lifecycle tasks before them
(task-040..task-043) are **not**: those allocate `work-NNN` folders in this repository's
tracked `.aid/works/` tree and write seeds into the shared `.aid/design/`.

### delivery-003

#### Execution Graph

Task ids continue from delivery-002's block; delivery-003 holds task-050..task-074. Waves continue
too, by the same rule applied to the **one** dependency table these three blocks together form —
task-050 depends on task-049 at wave 45, so delivery-003 opens at wave 46 and closes at wave 70.

| Task | Depends On |
|------|-----------|
| task-050 | task-049 |
| task-051 | task-050 |
| task-052 | task-051 |
| task-053 | task-052 |
| task-054 | task-053 |
| task-055 | task-054 |
| task-056 | task-055 |
| task-057 | task-056 |
| task-058 | task-057 |
| task-059 | task-058 |
| task-060 | task-059 |
| task-061 | task-060 |
| task-062 | task-061 |
| task-063 | task-062 |
| task-064 | task-063 |
| task-065 | task-064 |
| task-066 | task-065 |
| task-067 | task-066 |
| task-068 | task-067 |
| task-069 | task-068 |
| task-070 | task-069 |
| task-071 | task-070 |
| task-072 | task-071 |
| task-073 | task-072 |
| task-074 | task-073 |

**No `Can Be Done In Parallel` table, and the absence is the finding rather than an omission.**
delivery-003 is a total order: every one of its twenty-five waves holds exactly one task, so there
is no parallel group to list, and a table whose only row said "none" would be a parse hazard for no
information. The reason is in the resources, not in caution. Every authoring task under
`canonical/skills/` shares the tree with task-051 and task-060, each of which runs
`build-shortcut-skills.py`, and that script **walks the whole tree** looking for orphaned
marker-tagged directories (`build-shortcut-skills.py:310`) — a tree-scoped read that pulls every
writer beneath it into conflict. Every Knowledge Base authoring task reads the whole Knowledge Base
to write one document of it. And the seven description slices cannot be split into independent lanes
because the confusable pairs they must preserve cross slice boundaries: `aid-research` is in
task-055 and `aid-brainstorm` in task-058, `aid-prototype-ui` in task-055 and `aid-design-ui` in
task-058. Correctness over concurrency, for the third time in this plan.

```wave-map
delivery: 003
# Totality invariant: every task in the dependency table above appears here exactly once,
# and its wave is 1 + the maximum wave of its dependencies. Both halves are checkable by
# recomputing the map from the table; a task appearing twice, or not at all, is a defect.
wave 46: task-050
wave 47: task-051
wave 48: task-052
wave 49: task-053
wave 50: task-054
wave 51: task-055
wave 52: task-056
wave 53: task-057
wave 54: task-058
wave 55: task-059
wave 56: task-060
wave 57: task-061
wave 58: task-062
wave 59: task-063
wave 60: task-064
wave 61: task-065
wave 62: task-066
wave 63: task-067
wave 64: task-068
wave 65: task-069
wave 66: task-070
wave 67: task-071
wave 68: task-072
wave 69: task-073
wave 70: task-074
```

**Why the order is that one, and where it departs from the BLUEPRINT's own list.** BLUEPRINT
§ Notes fixes the data flow — catalog validated → build helper → full render → dogfood resync →
byte-identity → render-drift → count surfaces → Knowledge Base and methodology refresh →
`INDEX.md` → the `/aid-summarize` re-run → the closing sweeps. Two things sit where the reader of
that list would not put them, each for a stated reason.

The **description sweep runs before the render**, not among the closing sweeps. REQUIREMENTS AC-12
is a change to 112 `SKILL.md` frontmatter blocks and to the generator that emits 34 of them, so it
is authoring work whose output the render carries to five profiles; a sweep run after the render
would need a second one. The closing half — the pair matrix and the five mechanical checks — does
sit at the end, in task-072, which is why AC-8 and AC-12 are **one** pass and not two.

And the **count guard's own constants move last of the count work**, in task-069, after the
documents rather than before them. `CLAIM_FLOOR` must be set near the *post-change* live figure, and
the set of lines a new `CLAIMS` entry newly exposes is not knowable until every document is final.
So task-051, task-059 and task-065 through task-068 fix what the **existing** guard reports over
their own files, and task-069 closes the blind spot and re-ratchets — which is also why criterion 4
is cited by six tasks rather than one.

**The three interactions that shaped this block, stated because each is a place a later pass would
otherwise re-derive the wrong answer.**

- **feature-001 AC-3 is delivery-scoped, not work-scoped.** Its oracle is
  `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` clean, and delivery-003 writes
  three files under `tests/canonical/` plus the two coverage-baseline files — required by BLUEPRINT
  criteria 4, 5 and 7. AC-3 is evaluated at **feature-001's own close**, inside delivery-001, where
  it holds and where its subject (the *conditional* doc-set decision costing no test edit) is what
  is being asserted. Its substance — the seed-count suite set it enumerates by name — survives the
  whole work untouched, and task-062 re-asserts it. `site/scripts/__tests__/` stays writer-free
  across all 74 tasks. This is the same shape as feature-002's split AC-11 named at the top of this
  plan: a criterion evaluated where its subject lives, not re-evaluated at every later gate.
- **The site commits generated content that the roster drives, and feature-006 §5's "nothing to
  build" does not cover it.** `site/src/content/docs/skills/` (77 tracked pages today),
  `site/src/data/skill-flows/` (76 tracked sidecars) and three `site/scripts/.*-manifest.json` files
  are all derived from `canonical/skills/` and all tracked. They move to 113 and 112, and every page
  embeds its skill's description verbatim — so the AC-12 sweep changes all of them. task-064 owns
  that regeneration, which is what makes BLUEPRINT criterion 8's *"the published index holds exactly
  22 cards"* an assertion about a file rather than about an in-memory call.
- **Two of feature-006 §7's named site edit sites are generated, not hand-maintained.**
  `site/scripts/sync-docs.mjs`'s `MANIFEST` (`:30-70`) maps `docs/aid-methodology.md` →
  `site/src/content/docs/concepts/methodology.md` and `docs/glossary.md` →
  `site/src/content/docs/reference/glossary.md`. §7 calls the first *"a separate hand-maintained
  file, not a render of `docs/`"* and offers the four-line offset between the two as evidence; the
  offset is the sync transform, which strips the leading H1 and injects a four-line frontmatter
  block. task-068 therefore edits the `docs/` sources and re-runs the script, rather than
  hand-editing two mirrors that the next `prebuild` would overwrite.

### Shared-state safety, and why the serialisation exists

**The record of who touches what.** The `rw-sets` blocks below declare, for every task in all three
deliveries, a write set and a read set as **concrete paths** — one block per delivery, the same
per-delivery shape the `wave-map` takes. Together they are the source the shared-state check runs
over, and the reason each serialising edge exists. The check is run over the union, because the three
deliveries share one dependency graph and one working tree.

```rw-sets
delivery: 001
# One line per task, 25 lines, each id exactly once.
# A path ending in `/` is TREE-SCOPED. Two accesses MEET when one is a prefix of the other.
# Granularity is therefore not chosen here: it is whatever the task actually touches, and a
# tree-scoped reader pulls every writer beneath it into conflict.
task-001 W= canonical/aid/templates/design-folder-readme.md .aid/design/ .aid/knowledge/project-structure.md | R= .gitignore
task-002 W= canonical/aid/templates/design-seed.md | R= canonical/aid/templates/knowledge-base/ tests/ site/scripts/__tests__/
task-003 W= canonical/aid/templates/design-lifecycle.md | R= canonical/aid/templates/design-folder-readme.md canonical/aid/templates/design-seed.md lib/ canonical/skills/ canonical/aid/templates/shortcut-engine.md canonical/aid/templates/shortcut-scaffolding/
task-004 W= canonical/aid/templates/design-lifecycle.md | R= canonical/aid/templates/design-folder-readme.md canonical/aid/templates/design-seed.md .aid/design/README.md tests/ site/scripts/__tests__/
task-005 W= -- | R= canonical/ lib/ install.sh install.ps1 .github/ tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-006 W= canonical/aid/templates/kb-authoring/concern-model.md .aid/knowledge/authoring-conventions.md | R= tests/ site/scripts/__tests__/
task-007 W= canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/templates/kb-authoring/concern-model.md | R= canonical/aid/templates/ tests/ site/scripts/__tests__/
task-008 W= canonical/aid/scripts/kb/ | R= canonical/skills/aid-discover/references/doc-set-resolve.md tests/ site/scripts/__tests__/
task-009 W= .claude/skills/release-aid/SKILL.md | R= canonical/ canonical/skills/aid-create-backlog/ profiles/ .claude/ .cursor/
task-010 W= canonical/skills/aid-design-roadmap/ canonical/skills/aid-design-mvp/ canonical/skills/aid-design-backlog/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md profiles/ .claude/ .cursor/
task-011 W= canonical/skills/aid-create-roadmap/ canonical/aid/templates/shortcut-catalog.yml canonical/skills/aid-config/SKILL.md | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/scripts/kb/ profiles/ .claude/ .cursor/
task-012 W= canonical/skills/aid-create-backlog/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/skills/aid-create-roadmap/ canonical/aid/scripts/kb/ profiles/ .claude/ .cursor/
task-013 W= canonical/skills/aid-create-mvp/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/skills/aid-create-roadmap/ profiles/ .claude/ .cursor/
task-014 W= canonical/skills/aid-update-roadmap/ canonical/skills/aid-update-mvp/ canonical/skills/aid-update-backlog/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/skills/ profiles/ .claude/ .cursor/ tests/ site/scripts/__tests__/
task-015 W= .aid/knowledge/roadmap.md .aid/settings.yml .aid/knowledge/README.md .aid/works/ .aid/design/ | R= profiles/ .claude/ .cursor/ .aid/knowledge/ canonical/aid/scripts/kb/
task-016 W= -- | R= profiles/ .claude/ .cursor/ .aid/settings.yml .aid/knowledge/ .aid/design/ .aid/works/ tests/ site/scripts/__tests__/
task-017 W= canonical/skills/aid-discover/references/document-expectations.md .aid/knowledge/tech-debt.md | R= .aid/knowledge/roadmap.md .aid/knowledge/backlog.md .aid/knowledge/tech-debt.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-018 W= .aid/knowledge/backlog.md .aid/knowledge/release-tracking.md | R= .aid/knowledge/backlog.md .aid/knowledge/tech-debt.md .aid/knowledge/STATE.md .aid/knowledge/kb.html profiles/ .claude/ .cursor/ canonical/aid/scripts/kb/ .aid/knowledge/
task-019 W= .aid/knowledge/INDEX.md .aid/knowledge/relationships.md .aid/knowledge/graph.html | R= .aid/knowledge/ profiles/ .claude/ .cursor/ canonical/aid/scripts/kb/
task-020 W= -- | R= tests/ site/scripts/__tests__/ canonical/aid/templates/ canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/scripts/kb/ canonical/skills/aid-discover/references/document-expectations.md .aid/knowledge/ .aid/settings.yml profiles/ .claude/ .cursor/
task-021 W= .aid/knowledge/backlog.md .aid/settings.yml .aid/knowledge/README.md .aid/knowledge/tech-debt.md .aid/works/ .aid/design/ | R= profiles/ .claude/ .cursor/ .aid/knowledge/ canonical/aid/scripts/kb/
task-022 W= .aid/knowledge/roadmap.md .aid/works/ | R= profiles/ .claude/ .cursor/ .aid/knowledge/roadmap.md tests/ site/scripts/__tests__/ .aid/design/
task-023 W= .aid/knowledge/roadmap.md .aid/knowledge/backlog.md .aid/knowledge/tech-debt.md .aid/works/ .aid/design/ | R= profiles/ .claude/ .cursor/ .aid/knowledge/roadmap.md .aid/knowledge/backlog.md .aid/knowledge/tech-debt.md .aid/settings.yml tests/ site/scripts/__tests__/
task-024 W= profiles/ .claude/ .cursor/ | R= canonical/skills/ canonical/aid/templates/ profiles/ .claude/ .cursor/ .aid/connectors/.secrets/
task-025 W= profiles/ .claude/ .cursor/ .aid/knowledge/graph.html .aid/works/ | R= profiles/ .claude/ .cursor/ .aid/knowledge/ .aid/works/ canonical/ .aid/settings.yml .aid/connectors/.secrets/
```

```rw-sets
delivery: 002
# One line per task, 24 lines, each id exactly once.
# A path ending in `/` is TREE-SCOPED. Two accesses MEET when one is a prefix of the other.
# Granularity is therefore not chosen here: it is whatever the task actually touches, and a
# tree-scoped reader pulls every writer beneath it into conflict.
task-026 W= canonical/aid/templates/shortcut-engine.md | R= canonical/aid/templates/design-seed.md canonical/aid/templates/shortcut-catalog.yml canonical/aid/templates/shortcut-scaffolding/ canonical/skills/aid-ask/SKILL.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-027 W= canonical/skills/aid-create-document/SKILL.md canonical/skills/aid-update-document/SKILL.md | R= canonical/aid/templates/shortcut-engine.md canonical/aid/templates/design-seed.md canonical/aid/templates/shortcut-catalog.yml canonical/skills/aid-document/SKILL.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-028 W= canonical/skills/aid-design/SKILL.md canonical/skills/aid-research/SKILL.md canonical/skills/aid-prototype-ui/SKILL.md canonical/skills/aid-document/SKILL.md | R= canonical/skills/ canonical/aid/templates/shortcut-catalog.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-029 W= canonical/skills/aid-design-api/ canonical/skills/aid-design-ui/ canonical/skills/aid-design-theme/ canonical/skills/aid-design-cli/ canonical/skills/aid-design-data-model/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/aid/templates/work-initiation-gate.md canonical/aid/scripts/works/ canonical/skills/aid-design/SKILL.md canonical/skills/aid-prototype-ui/SKILL.md canonical/skills/aid-create-api/SKILL.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-030 W= canonical/skills/aid-design-data-pipeline/ canonical/skills/aid-design-messaging/ canonical/skills/aid-design-integration/ canonical/skills/aid-design-job/ canonical/skills/aid-design-config/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-031 W= canonical/skills/aid-design-infra/ canonical/skills/aid-design-test/ canonical/skills/aid-design-document/ canonical/skills/aid-design-dashboard/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/skills/aid-document/SKILL.md canonical/skills/aid-create-document/SKILL.md canonical/skills/aid-update-document/SKILL.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-032 W= canonical/skills/aid-brainstorm/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/skills/aid-research/SKILL.md canonical/aid/templates/shortcut-engine.md canonical/aid/templates/shortcut-scaffolding/ site/scripts/skills/groups.mjs tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-033 W= canonical/skills/aid-design-architecture/ canonical/skills/aid-design-stack/ canonical/skills/aid-design-testing-strategy/ canonical/skills/aid-design-cicd/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/aid/templates/work-initiation-gate.md canonical/aid/scripts/works/ canonical/skills/aid-design/SKILL.md canonical/aid/templates/kb-authoring/concern-model.md canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/templates/knowledge-base/ canonical/skills/aid-discover/references/doc-set-resolve.md canonical/skills/aid-config/SKILL.md .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-034 W= canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/templates/kb-authoring/concern-model.md | R= canonical/skills/aid-discover/references/document-expectations.md canonical/skills/aid-discover/references/doc-set-resolve.md canonical/aid/scripts/kb/ canonical/aid/templates/knowledge-base/ .aid/knowledge/quality-gates.md .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-035 W= canonical/skills/aid-create-architecture/ canonical/skills/aid-create-stack/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/aid/templates/kb-authoring/ canonical/aid/templates/knowledge-base/ canonical/skills/aid-update-kb/references/state-apply.md canonical/skills/aid-discover/references/doc-set-resolve.md canonical/skills/aid-config/SKILL.md .aid/knowledge/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-036 W= canonical/skills/aid-create-testing-strategy/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/aid/templates/kb-authoring/ canonical/aid/templates/knowledge-base/ canonical/skills/aid-update-kb/references/state-apply.md canonical/skills/aid-discover/references/doc-set-resolve.md canonical/skills/aid-create-test/ .aid/knowledge/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-037 W= canonical/skills/aid-create-cicd/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/aid/templates/kb-authoring/ canonical/aid/templates/knowledge-base/ canonical/skills/aid-update-kb/references/state-apply.md canonical/skills/aid-discover/references/doc-set-resolve.md .aid/knowledge/ .aid/settings.yml .github/ tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-038 W= canonical/skills/aid-update-architecture/ canonical/skills/aid-update-stack/ canonical/skills/aid-update-testing-strategy/ canonical/skills/aid-update-cicd/ canonical/aid/templates/shortcut-catalog.yml | R= canonical/aid/templates/design-lifecycle.md canonical/aid/templates/design-seed.md canonical/skills/aid-design/SKILL.md canonical/skills/aid-create-architecture/ canonical/skills/aid-create-stack/ canonical/skills/aid-create-testing-strategy/ canonical/skills/aid-create-cicd/ canonical/skills/aid-design-architecture/ canonical/skills/aid-design-stack/ canonical/skills/aid-design-testing-strategy/ canonical/skills/aid-design-cicd/ canonical/skills/aid-housekeep/references/state-kb-delta.md canonical/skills/aid-update-kb/references/state-apply.md canonical/aid/templates/kb-authoring/ canonical/aid/templates/knowledge-base/ .aid/knowledge/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-039 W= profiles/ .claude/ .cursor/ canonical/skills/ | R= canonical/ tests/ site/scripts/__tests__/ .aid/connectors/.secrets/ profiles/ .claude/ .cursor/
task-040 W= .aid/knowledge/architecture.md .aid/knowledge/decisions.md .aid/design/ .aid/works/ | R= .aid/knowledge/ .aid/settings.yml .github/ canonical/aid/scripts/kb/ tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-041 W= .aid/knowledge/technology-stack.md .aid/knowledge/decisions.md .aid/design/ .aid/works/ | R= .aid/knowledge/ .aid/settings.yml .github/ canonical/aid/scripts/kb/ canonical/aid/templates/kb-authoring/domain-doc-matrix.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-042 W= .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md .aid/design/ .aid/works/ | R= .aid/knowledge/ .aid/settings.yml .github/ canonical/aid/scripts/kb/ canonical/aid/templates/kb-authoring/domain-doc-matrix.md tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-043 W= .aid/knowledge/infrastructure.md .aid/design/ .aid/works/ | R= .aid/knowledge/ .aid/settings.yml .github/ canonical/aid/scripts/kb/ tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-044 W= -- | R= canonical/skills/ .aid/knowledge/ .aid/design/ .aid/works/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-045 W= -- | R= canonical/aid/templates/kb-authoring/domain-doc-matrix.md canonical/aid/scripts/kb/ .aid/knowledge/ .aid/design/ .aid/works/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-046 W= -- | R= canonical/skills/ .aid/knowledge/ .aid/design/ .aid/works/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-047 W= -- | R= canonical/aid/templates/shortcut-engine.md canonical/aid/templates/shortcut-scaffolding/ .aid/knowledge/ .aid/design/ .aid/works/ .aid/settings.yml tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-048 W= profiles/ .claude/ .cursor/ canonical/skills/ .aid/knowledge/architecture.md .aid/knowledge/technology-stack.md .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md .aid/knowledge/infrastructure.md .aid/knowledge/decisions.md .aid/design/ .aid/works/ | R= canonical/ .aid/knowledge/ .aid/design/ .aid/works/ .aid/settings.yml .aid/connectors/.secrets/ tests/ site/scripts/__tests__/ profiles/ .claude/ .cursor/
task-049 W= -- | R= canonical/ tests/ site/scripts/__tests__/ site/scripts/skills/groups.mjs .aid/knowledge/ .aid/settings.yml .aid/design/ .aid/works/ profiles/ .claude/ .cursor/
```

```rw-sets
delivery: 003
# One line per task, 25 lines, each id exactly once.
# A path ending in `/` is TREE-SCOPED. Two accesses MEET when one is a prefix of the other.
# Granularity is therefore not chosen here: it is whatever the task actually touches, and a
# tree-scoped reader pulls every writer beneath it into conflict.
task-050 W= -- | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-051 W= .claude/skills/generate-profile/scripts/build-shortcut-skills.py canonical/skills/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-052 W= canonical/skills/aid-config/ canonical/skills/aid-discover/ canonical/skills/aid-describe/ canonical/skills/aid-define/ canonical/skills/aid-specify/ canonical/skills/aid-plan/ canonical/skills/aid-detail/ canonical/skills/aid-execute/ canonical/skills/aid-triage/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-053 W= canonical/skills/aid-graph/ canonical/skills/aid-housekeep/ canonical/skills/aid-summarize/ canonical/skills/aid-update-kb/ canonical/skills/aid-set-connector/ canonical/skills/aid-unset-connector/ canonical/skills/aid-read-ticket/ canonical/skills/aid-create-ticket/ canonical/skills/aid-update-ticket/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-054 W= canonical/skills/aid-create-document/ canonical/skills/aid-update-document/ canonical/skills/aid-create-diagram/ canonical/skills/aid-document/ canonical/skills/aid-document-decision/ canonical/skills/aid-document-architecture/ canonical/skills/aid-document-guideline/ canonical/skills/aid-document-standard/ canonical/skills/aid-document-runbook/ canonical/skills/aid-document-tutorial/ canonical/skills/aid-document-changelog/ canonical/skills/aid-ask/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-055 W= canonical/skills/aid-deploy/ canonical/skills/aid-monitor/ canonical/skills/aid-design/ canonical/skills/aid-prototype/ canonical/skills/aid-prototype-ui/ canonical/skills/aid-report/ canonical/skills/aid-research/ canonical/skills/aid-review/ canonical/skills/aid-test/ canonical/skills/aid-test-security/ canonical/skills/aid-test-performance/ canonical/skills/aid-test-data-quality/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-056 W= canonical/skills/aid-design-roadmap/ canonical/skills/aid-create-roadmap/ canonical/skills/aid-update-roadmap/ canonical/skills/aid-design-backlog/ canonical/skills/aid-create-backlog/ canonical/skills/aid-update-backlog/ canonical/skills/aid-design-mvp/ canonical/skills/aid-create-mvp/ canonical/skills/aid-update-mvp/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-057 W= canonical/skills/aid-design-architecture/ canonical/skills/aid-create-architecture/ canonical/skills/aid-update-architecture/ canonical/skills/aid-design-stack/ canonical/skills/aid-create-stack/ canonical/skills/aid-update-stack/ canonical/skills/aid-design-testing-strategy/ canonical/skills/aid-create-testing-strategy/ canonical/skills/aid-update-testing-strategy/ canonical/skills/aid-design-cicd/ canonical/skills/aid-create-cicd/ canonical/skills/aid-update-cicd/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-058 W= canonical/skills/aid-design-api/ canonical/skills/aid-design-ui/ canonical/skills/aid-design-theme/ canonical/skills/aid-design-cli/ canonical/skills/aid-design-data-model/ canonical/skills/aid-design-data-pipeline/ canonical/skills/aid-design-messaging/ canonical/skills/aid-design-integration/ canonical/skills/aid-design-job/ canonical/skills/aid-design-config/ canonical/skills/aid-design-infra/ canonical/skills/aid-design-test/ canonical/skills/aid-design-document/ canonical/skills/aid-design-dashboard/ canonical/skills/aid-brainstorm/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-059 W= canonical/aid/templates/shortcut-catalog.yml | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-060 W= profiles/ .claude/ .cursor/ canonical/skills/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/ .aid/connectors/.secrets/
task-061 W= -- | R= canonical/ tests/ site/ docs/ .aid/knowledge/ .github/ profiles/ .claude/ .cursor/
task-062 W= tests/canonical/test-deploy-monitor-repurpose.sh tests/canonical/test-catalog-dirs-parity.sh | R= canonical/ tests/ site/ .claude/
task-063 W= tests/coverage-baseline.tsv tests/coverage-baseline.meta | R= canonical/ tests/ site/scripts/__tests__/ .github/ profiles/ .claude/ .cursor/ .aid/connectors/.secrets/
task-064 W= site/src/content/docs/skills/ site/src/content/docs/reference/skills.md site/src/data/skill-flows/ site/scripts/.skills-manifest.json site/scripts/.reference-manifest.json | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/ .aid/connectors/.secrets/
task-065 W= .aid/knowledge/capability-inventory.md .aid/knowledge/architecture.md .aid/knowledge/module-map.md .aid/knowledge/project-structure.md | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-066 W= .aid/knowledge/pipeline-contracts.md .aid/knowledge/domain-glossary.md .aid/knowledge/decisions.md | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-067 W= .aid/knowledge/test-landscape.md .aid/knowledge/tech-debt.md | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-068 W= docs/aid-methodology.md docs/glossary.md docs/install.md docs/diagram-content-reference.md site/src/content/docs/concepts/methodology.md site/src/content/docs/concepts/faq.md site/src/content/docs/reference/glossary.md site/src/content/docs/reference/repository-structure.md site/src/content/docs/index.mdx site/scripts/.synced-manifest.json | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-069 W= tests/canonical/check-skill-counts.mjs canonical/skills/aid-triage/references/state-classify.md README.md .claude/skills/release-aid/SKILL.md | R= canonical/ tests/ site/ docs/ .aid/knowledge/ README.md profiles/ .claude/ .cursor/
task-070 W= .aid/knowledge/INDEX.md | R= canonical/ tests/ site/ docs/ .aid/knowledge/ .aid/settings.yml profiles/ .claude/ .cursor/
task-071 W= .aid/knowledge/kb.html .aid/knowledge/tech-debt.md .aid/knowledge/STATE.md .aid/knowledge/INDEX.md .aid/.temp/summarize/ | R= canonical/ tests/ site/ docs/ .aid/knowledge/ .aid/settings.yml .aid/.temp/summarize/ .gitignore profiles/ .claude/ .cursor/
task-072 W= -- | R= canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
task-073 W= -- | R= canonical/ tests/ site/ docs/ .aid/ CLAUDE.md AGENTS.md profiles/ .claude/ .cursor/
task-074 W= -- | R= canonical/ tests/ site/ docs/ .aid/ profiles/ .claude/ .cursor/
```

**The safety property, checked over all three blocks.** Two tasks are safe to run concurrently only
if neither touches what the other writes:

> for every pair where one task's read set meets the other's write set, **or** their write
> sets meet, one task must be a transitive ancestor of the other in the dependency table above.

**Granularity is dictated, not chosen.** Because the meet rule is a prefix test, the scope of
each access is fixed by how the resource is actually *read* — a tree-scoped reader anywhere
forces tree granularity for every writer beneath it. The six resources where that matters:

| Resource | Granularity | The reader that fixes it |
|---|---|---|
| `profiles/` + `.claude/` + `.cursor/` | **tree** | Most tasks in all three deliveries assert `git status --porcelain profiles/ .claude/ .cursor/` over all three trees at once. That is how task-009's edit to `.claude/skills/release-aid/SKILL.md` — tracked, and ignored by nothing — conflicts with readers that never name it. delivery-003 adds two more writers of the same shape inside these trees: task-051 edits `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` and task-069 edits `.claude/skills/release-aid/SKILL.md`. Both are repo-local maintainer paths in `test-dogfood-byte-identity.sh`'s documented allowlist (`:149-150`), so neither breaks the gate task-060 runs |
| `canonical/` | **tree** | task-005's `git diff --name-status <range> -- lib/ canonical/ …` (its shipped-footprint audit asserts *no* `M` and *no* `D` entry anywhere under the tree), task-009's `git diff --exit-code -- canonical/`, task-025's and task-048's `git diff --exit-code HEAD -- … canonical/`, task-039's full `run_generator.py` read, task-049's audit, and in delivery-003 task-060's full render plus task-061's regenerate-and-diff and task-072/073/074's audits. task-007 and task-020 are **not** on this row: their `find` is scoped to `canonical/aid/templates` |
| `canonical/skills/` | **tree** | `tests/canonical/test-catalog-dirs-parity.sh:50` sets `SKILLS_ROOT` to the whole tree and asserts over it at `:58`, and task-014 requires that suite green; task-024 and task-039 each run `build-shortcut-skills.py` and the full `run_generator.py` over the same tree; task-028's diff asserts which files under it changed, and task-044 and task-046 grep it whole. In delivery-003 the same helper's **orphan walk** (`build-shortcut-skills.py:310` iterates the whole tree) is what makes task-051 and task-060 tree-scoped readers, and task-072 greps all 112 bodies — which is why the seven description slices are a chain and not a fan |
| `tests/` | **tree** | Read whole by the tasks in the Readers column below. delivery-003 gives it **three writers** — task-062 (two suites), task-063 (the coverage baseline pair) and task-069 (the count guard) — required by BLUEPRINT criteria 4, 5 and 7. That is why this resource is now its own row: the previous combined row's claim of *"written by none"* is true of `site/scripts/__tests__/` alone |
| `site/scripts/__tests__/` | **tree** | Read whole by the tasks in the Readers column below, and **written by none across all 74 tasks** — which is the half of feature-001 AC-3 that holds work-wide. AC-3's `tests/canonical/` half is evaluated at feature-001's own close, inside delivery-001; see § *delivery-003* / *Execution Graph* |
| `docs/` + `site/src/content/docs/` | **tree** | Read whole by every delivery-003 task that asserts `git diff --exit-code -- docs/ site/` or runs the count guard, whose scan admits both trees (`check-skill-counts.mjs:145-196`). Two writers, task-064 (the generated skill surface) and task-068 (the hand-authored sources plus the `sync-docs.mjs` mirrors), and they touch disjoint paths under the second tree — the ordering edge is what makes that irrelevant rather than load-bearing |

Everything else in the three `rw-sets` blocks is per-directory or per-file, because no reader of
it reads a wider tree that contains it — except the six above, which is precisely why those rows
exist.

**Shared resources, as a derived view of the blocks.** Every Writers, Readers and Execution
order cell below is computed over **all three** `rw-sets` blocks: Writers and Readers are the tasks
whose `W=` (respectively `R=`) list meets that resource under the prefix rule, and Execution
order is those members sorted by their wave in the three `wave-map` blocks. The sets are larger
than intuition suggests, and that is the prefix rule working: a task that reads
`.aid/knowledge/` whole is a reader of **every** document in it, and one that reads `canonical/`
whole is a reader of everything beneath it. Two rows changed shape rather than only growing: the
former combined `tests/` + `site/scripts/__tests__/` row is **split**, because `tests/` acquires
three writers in delivery-003 while `site/scripts/__tests__/` stays writer-free; and a
`docs/` + `site/src/content/docs/` row is **new**, because delivery-003 is the first delivery to
write either tree.

| Shared resource | Writers (derived) | Readers (derived) | Execution order, wave-sorted (derived) | Note |
|---|---|---|---|---|
| `profiles/` + `.claude/` + `.cursor/` | 009, 024, 025, 039, 048, 051, 060, 069 | 005, 009, 010, 011, 012, 013, 014, 015, 016, 017, 018, 019, 020, 021, 022, 023, 024, 025, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 005, 010, 011, 012, 013, 014, 024, 015, 021, 016, 022, 023, 009, 018, 017, 019, 025, 020, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | Deliveries 001 and 002 each render once and revert once — 024/025 and 039/048. **delivery-003 renders once and does NOT revert:** task-060's render is the committed one, which is why there is no `048`-shaped reverter in its block and why every later task's `git status --porcelain` over these trees is expected clean rather than restored. The other three writers write single repo-local files: 009 and 069 `.claude/skills/release-aid/SKILL.md`, 051 `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`. Each render is **additive** on those paths, so the hazard is read/write, not data loss; every task that commits while an uncommitted render is live stages explicit paths only |
| `canonical/aid/templates/shortcut-catalog.yml` | 010, 011, 012, 013, 014, 029, 030, 031, 032, 033, 035, 036, 037, 038, 059 | 005, 007, 009, 020, 024, 025, 026, 027, 028, 039, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 005, 010, 007, 011, 012, 013, 014, 024, 009, 025, 020, 026, 027, 028, 029, 030, 031, 032, 033, 035, 036, 037, 038, 039, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | Two concurrent appends to one file is the hazard the writer chain is serialised to prevent, and it is why nine of delivery-002's fourteen authoring tasks form a chain rather than a fan. Every reader reaches it by name or through a tree-scoped walk. delivery-003 adds **one** writer, 059 — its three stale count comments, handed here so that three features do not collide on one file — and it is the **last** write to the file in the work, which is what lets task-060's render carry a correct copy to five profiles |
| `canonical/skills/` as a tree | 010, 011, 012, 013, 014, 017, 027, 028, 029, 030, 031, 032, 033, 035, 036, 037, 038, 039, 048, 051, 052, 053, 054, 055, 056, 057, 058, 060, 069 | 003, 005, 008, 009, 012, 013, 014, 020, 024, 025, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 044, 046, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 003, 005, 010, 008, 011, 012, 013, 014, 024, 009, 017, 025, 020, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 044, 046, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | Most members meet this tree only under the prefix rule. The readers that read it **whole**, and so fix its granularity, are 003 (whose diff asserts nothing changed under `canonical/skills/*/SKILL.md`), 014 (the parity suite's `SKILLS_ROOT`), 024 and 039 (delivery-001's and delivery-002's renders), 028 (whose diff asserts which files under it changed), 044/046 (which grep the authored bodies), and in delivery-003: 050 and 060 (the parity suite and the committed render), 051 (the build helper's orphan walk) and 072 (which greps all 112 descriptions). delivery-003's nine writers under it — 051 through 058, plus 060 and 069 — write disjoint per-skill paths, so it is the tree-scoped **readers** and nothing else that force them into a chain |
| `canonical/` as a whole | 001, 002, 003, 004, 006, 007, 008, 010, 011, 012, 013, 014, 017, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 048, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 069 | 002, 003, 004, 005, 007, 008, 009, 010, 011, 012, 013, 014, 015, 018, 019, 020, 021, 024, 025, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 001, 002, 003, 004, 005, 006, 010, 007, 008, 011, 012, 013, 014, 024, 015, 021, 009, 018, 017, 019, 025, 020, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | The tree-scoped readers are 005 (its shipped-footprint diff), 009, 025, 039 (delivery-002's render), 048 (its no-committed-artifact-reverted guard), 049 (the static sweep), and in delivery-003: 050 (the whole-catalog validation), 060 (the committed render), 061 (regenerate-and-diff) and 072/073/074 (the three closing audits); every other member meets it per-file or per-directory |
| `.aid/settings.yml` + `.aid/knowledge/README.md` (one shared doc-set count) | 015, 021 | 015, 016, 018, 019, 020, 021, 023, 025, 033, 034, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 015, 021, 016, 023, 018, 019, 025, 020, 033, 034, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | One shared doc-set count with two writers, so two concurrent increments is the hazard the `021 → 015` edge prevents. **Neither delivery-002 nor delivery-003 adds a writer**: every destination a `create` skill could create is already a declared member, so CC-2's registration path fires only inside the scratch projects task-045 builds, and task-070 asserts `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` clean for exactly that reason. Most delivery-003 members reach `README.md` through a whole-tree `.aid/knowledge/` read rather than by name; 062 and 063 are absent because neither reads that tree |
| `.aid/knowledge/roadmap.md` | 015, 022, 023 | 015, 016, 017, 018, 019, 020, 021, 022, 023, 025, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 015, 021, 016, 022, 023, 018, 017, 019, 025, 020, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 015 creates it; the other two writers mutate and restore it, each with its own restoration criterion. Neither delivery-002 nor delivery-003 adds a writer — every later member reaches it through a whole-tree `.aid/knowledge/` read rather than by name, which is why 070's regenerated `INDEX.md` covers it without either task writing it |
| `.aid/knowledge/backlog.md` | 018, 021, 023 | 015, 016, 017, 018, 019, 020, 021, 023, 025, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 015, 021, 016, 023, 018, 017, 019, 025, 020, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 021 creates it, but 018's migration is the **last** write — which is why 017 was edged to follow 018 rather than its creator. Neither delivery-002 nor delivery-003 adds a writer; both add only whole-tree readers |
| `.aid/knowledge/tech-debt.md` | 017, 021, 023, 067, 071 | 015, 016, 017, 018, 019, 020, 021, 023, 025, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 015, 021, 016, 023, 018, 017, 019, 025, 020, 035, 036, 037, 038, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 023 reaches it through `/aid-update-backlog`'s promotion path and restores it; 017 and 021 add rows. **delivery-003 adds two writers, and the order between them is the point:** 067 moves `W1-11`'s two live figures and deliberately leaves its `kb.html` half open, and 071 closes that half — after the regeneration it describes. 071 is therefore the file's last writer, and the `INDEX.md` summary of it is re-derived there rather than assumed unaffected |
| `.aid/design/` | 001, 015, 021, 023, 040, 041, 042, 043, 048 | 004, 016, 022, 044, 045, 046, 047, 048, 049, 073, 074 | 001, 004, 015, 021, 016, 022, 023, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 073, 074 | 001 creates the folder. In deliveries 001 and 002 every writer's seed is consumed by that writer's own run, so none outlives its task; delivery-002's four lifecycle tasks each restore the folder to `HEAD`, and 048 backstops. **delivery-003 adds no writer at all** — it runs no skill that produces a seed — and appears here only through 073's and 074's whole-tree `.aid/` reads |
| `.aid/works/` | 015, 021, 022, 023, 025, 040, 041, 042, 043, 048 | 016, 025, 044, 045, 046, 047, 048, 049, 073, 074 | 015, 021, 016, 022, 023, 025, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 073, 074 | Each allocator removes its own folder and worktree after capturing the `phase:` evidence; 025 and 048 backstop by asserting none survive. delivery-002's 044–047 allocate **inside `mktemp -d`** instead, so they appear here as readers only — which is exactly what makes wave 43's four-way parallelism sound. delivery-003 allocates none, and appears only through 073's and 074's whole-tree `.aid/` reads |
| `tests/` | 062, 063, 069 | 002, 004, 005, 006, 007, 008, 014, 016, 017, 020, 022, 023, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 002, 004, 005, 006, 007, 008, 014, 016, 022, 023, 017, 020, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | Writer-free through deliveries 001 and 002, which is what every task in those two asserts with `git diff --exit-code -- tests/ site/scripts/__tests__/`. **delivery-003 is where that changes, by criterion rather than by accident:** 062 moves the four `DMR*` assertions and four comment blocks (criterion 5), 063 commits the re-bootstrapped coverage baseline pair (criterion 7) and 069 extends the count guard and raises its two ratchets (criterion 4). The three write disjoint files, and every task after them asserts `HEAD`-relative rather than `master`-relative so the committed edits do not read as drift |
| `site/scripts/__tests__/` | — (none) | 002, 004, 005, 006, 007, 008, 014, 016, 017, 020, 022, 023, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 002, 004, 005, 006, 007, 008, 014, 016, 022, 023, 017, 020, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | The empty writer set holds across **all 74 tasks**, and it is the half of feature-001 AC-3 that is work-wide. task-064 and task-068 both regenerate committed site content and both carry `git diff --exit-code -- site/scripts/__tests__/` clean as their own criterion; a red site suite at 112 / 94 / 60 is a finding to report, never to fix by editing a spec under this tree |
| `docs/` + `site/src/content/docs/` | 064, 068 | 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 064, 065, 066, 067, 068, 069, 070, 071, 072, 073, 074 | A **new** row: deliveries 001 and 002 neither read nor wrote either tree, and delivery-003 is the first to do both. Two writers on disjoint paths — 064 the generated skill pages, published index, flow sidecars and two generator manifests; 068 the four hand-authored `docs/` sources, `index.mdx`, and the four `sync-docs.mjs` mirrors plus `.synced-manifest.json`. The count guard scans both trees (`check-skill-counts.mjs:145-196`), which is why 069 is a reader and why its `CLAIM_FLOOR` cannot be pinned before 068 lands. 062 is a member because it runs `npx vitest run gen-reference` from `site/`, a whole-`site/` read; 063 is **not**, because its only site access is the scoped `site/scripts/__tests__/` diff |

Checked mechanically over all three `rw-sets` blocks, across **all 74 tasks** — delivery-003's
among themselves and against all 49 that precede them, since the three share one graph and one
working tree: **zero unordered write/write pairs, zero unordered read/write pairs, zero same-wave
conflicts.** Only **7** of the 2,701 pairs are unordered at all, and every one of them predates
delivery-003: the wave-6 pair `006`/`010` and the six pairs among the wave-43 four,
`044`/`045`/`046`/`047`, all of which declare an empty write set.

delivery-003 reaches zero by construction on both axes. Cross-delivery: its single entry edge
`050 → 049` makes every delivery-001 and delivery-002 task a transitive ancestor of every
delivery-003 task, and the three wave ranges — 1–24, 25–45, 46–70 — are disjoint. Within
delivery-003: the block is a total order, so every pair is ordered and every wave holds exactly
one task, which is why its serialisation had to be justified in the block above rather than
merely stated. The two replays that make the zeros non-vacuous are still the earlier ones:
delivery-001's pre-fix graph returns nine unordered pairs — `007`/`010` and `009` against
`013, 014, 015, 016, 021, 022, 023, 024`, the last conflicting on both axes — every one of which
the two edges `007 → 010` and `009 → 023` close.

The cost is real and accepted: **70 waves across the three deliveries, with parallelism only at
wave 6 and wave 43.** Correctness over concurrency; the work is a chain of authored artifacts and
was never wide.

**The per-delivery heading shape is a contract with two shipped consumers, and it was wrong here
until it was corrected.** Both `canonical/aid/scripts/execute/compute-block-radius.sh` and
`canonical/aid/scripts/execute/complexity-score.sh` scope a multi-delivery PLAN by scanning for a
`### delivery-NNN` section and then, inside it, an `Execution Graph` heading — `complexity-score.sh`
requiring that heading at level **four** specifically (`:90`, `/^#### Execution Graph/`). That shape
is what both suites encode as the tested form (`tests/canonical/test-complexity-score.sh:71-85`,
`tests/canonical/test-compute-block-radius.sh:361-368`) and what `aid-execute`'s own delivery gate
documents as its read path (`canonical/skills/aid-execute/references/state-delivery-gate.md:105-106`,
*"`#### Execution Graph` block for this delivery"*).

This PLAN originally carried the graphs under `### delivery-NNN execution graph` — level three, with
the words *execution graph* folded into the delivery heading and no level-four heading anywhere. Both
consumers therefore failed, and they failed differently: `compute-block-radius.sh` re-armed only on
the single `## Execution Graph` above all three blocks, so an unscoped parse saw delivery-001's 25
rows and stopped while a `--delivery-id 002`/`003` parse saw none; `complexity-score.sh` was routed
to its multi-delivery branch by the presence of `### delivery-` lines and then found no level-four
heading at all, capturing **zero** rows for every delivery — 001 included.

The headings are now `### delivery-NNN` followed by `#### Execution Graph`, the documented form. This
is a correction to **this table's shape**, not a change to either script and not new enforcement
machinery — the frozen surface is unaffected. Verified by re-implementing both awk state machines
against this file rather than by running either script: `compute-block-radius.sh` yields 25 / 24 / 25
nodes for deliveries 001 / 002 / 003 with a 74-node union, and `complexity-score.sh` yields
`parsed_rows` of 25 / 24 / 25 under its own row regex (`:120`), which requires two pipe-delimited
columns and so correctly ignores the one-column `| task-006, task-010 |` row of a parallel-point
table. No defect against either shipped script survives, and none is recorded.

## Revision History

> PLAN.md's content-history section. The name is `## Revision History`, not `## Change Log`:
> `.aid/knowledge/pipeline-contracts.md` § *Typed Artifact Contracts* gives each artifact its
> own section list, and `## Change Log` is the name it prescribes for `REQUIREMENTS.md` and
> the feature `SPEC.md` files, while `PLAN.md`'s row reads *"`## Deliverables` … + execution
> graph (Detail) + `## Revision History`"*. The work `STATE.md`'s template note uses
> `## Change Log` as a generic label for all four artifact files; where the two differ, the
> per-artifact schema is the narrower and is followed here.

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | PLAN.md authored — three deliveries grouped by skill family; both mutual dependency pairs absorbed inside a delivery | /aid-plan |
| 2026-08-09 | Plan-review close-out (14 findings). **Owner decision applied:** `kb.html` **is** regenerated in this work — the premise that it could not be (a false clause in `tech-debt.md` W1-11, since corrected) had left delivery-001's `## Unreleased` criterion with no delivery owning a path that could clear it. The regeneration is a `/aid-summarize` re-run owned by delivery-003, with its ~24-minute cost and its orchestrator-only visual gate stated rather than assumed; new cross-cutting risk 5 records it. Also: the blanket one-directionality claim replaced with the one real back-edge (feature-002 depends on feature-006, verification-only — written as prose because the arrow convention reserves arrows for task pairs); the "CI is only ever evaluated against the merged result" premise corrected with its actual precondition (open the PR after delivery-003 closes); delivery-003 given the three stale `shortcut-catalog.yml` count comments as a named Scope item and criterion; the `aid-config/SKILL.md` amendment assigned to delivery-001 and gated instead of left to "whichever feature lands first"; feature-002 AC-9 given a gate criterion in delivery-002; delivery-002's criterion 4 corrected — it forbade the `source: generated` refusal feature-004 mandates, the exclusion list being `hand-authored`; delivery-001's Notes corrected on a dependency both source specs deny; the execution path for behavioral criteria that run before the render stated in both deliveries; and this section added | /aid-plan |
| 2026-08-10 | § Execution Graph appended for delivery-001 — dependency table, `wave-map`, `rw-sets`, the derived shared-resource view, and the granularity rule that makes the shared-state check sound | /aid-detail |
| 2026-08-10 | **Owner decision: the enforcement layer is stripped. Do not rebuild it.** Detail review rounds 5–8 found the *executable* breakdown clean — graph, waves, read/write sets, fixtures, criteria and oracles all verified against disk — while the findings count rose from 9 to 20, because each round's answer to a bookkeeping defect was another layer of policing, and that layer became the next round's defects. **Deleted:** the counted-claim rule and its 23-entry `counted-claim-exemptions` block (six entries were wrong, dead or unbounded, and the rule contradicted itself on how many tasks state a run total); the arrow convention as a *rule* with its four clauses and falsifier (its glyph set missed U+2194, its chain test was positional, and its clause-4 falsifier named a "defining phrase" that was never defined); the `probes` block; and the checkers `claimcheck`, `cellcheck` and `arrowcheck`. **Where a count or membership list lost its enforcement, the claim was deleted rather than justified** — a sentence saying "N tasks do X" carries nothing the 25 task files do not. **Kept, because each verifies executable content and each came back confirmed:** the `| Task | Depends On |` table (`compute-block-radius.sh` and `complexity-score.sh` require one per delivery block), the `wave-map` with its totality invariant (eight rounds, zero recurrences), the `rw-sets` block (the record of *why* each serialising edge exists), the derived shared-resource view, and the three checks that read them — `graphwalk`, `wavecheck`, `partition`. Three checkers, not six; two machine-readable blocks plus the dependency table, not five. The arrow *notation* survives as one sentence of notation, not as a policed rule | owner decision / /aid-detail |
| 2026-08-10 | § Execution Graph appended for **delivery-002** — task-026..task-049, its dependency table, its `wave-map` (waves 25–45, continuing the single graph rather than restarting at 1) and its `rw-sets` block, one per delivery in the same shape the `wave-map` already took. The derived shared-resource view and the granularity table were **recomputed over both blocks**, not extended by hand. **The enforcement surface was not touched:** still three checkers, two block kinds and the dependency table — no new checker, no new fenced block kind, no invariant section, no exemption list. delivery-002 enters the graph through one edge, `026 → 020`, which makes every delivery-001 task a transitive ancestor of every delivery-002 task; its ids were allocated in execution order, so it contributes **zero** forward edges and the partition's two lists are unchanged. Checked across all 49 tasks: zero unordered write/write, zero unordered read/write, zero same-wave conflicts. One delivery-001 residue fixed in passing, because the cell was being recomputed anyway: the `tests/` row's Note cited *"probe **P3**"*, a pointer into the deleted `probes` block, and now names the per-task `git diff --exit-code -- tests/ site/scripts/__tests__/` criterion instead | /aid-detail |
| 2026-08-10 | § Execution Graph appended for **delivery-003**, completing the work at 74 tasks — task-050..task-074, its dependency table, its `wave-map` (waves 46–70) and its `rw-sets` block. **The enforcement surface was not touched:** still three checkers, two block kinds and the dependency table. delivery-003 enters through one edge, `050 → 049`; its ids were allocated in execution order, so it contributes **zero** forward edges and the partition's two lists stay at eight. It is a **total order** — twenty-five waves, one task each, no `Can Be Done In Parallel` table because there is no group to list — and the serialisation is justified in the block from the resources rather than asserted: the build helper's orphan walk makes `canonical/skills/` tree-scoped for its two runners, Knowledge Base authoring reads the whole Knowledge Base, and the confusable pairs the description slices must preserve cross slice boundaries. Checked across all 74 tasks: zero unordered write/write, zero unordered read/write, zero same-wave conflicts, with only 7 of 2,701 pairs unordered at all and every one of them predating this delivery. **Three recomputations rather than extensions:** the former combined `tests/` + `site/scripts/__tests__/` row is **split**, because `tests/` acquires three writers here (criteria 4, 5 and 7) while `site/scripts/__tests__/` stays writer-free across all 74; a `docs/` + `site/src/content/docs/` row is **new**; and the granularity table grew from four resources to six. **Three interactions surfaced against disk and recorded rather than left to be re-derived:** feature-001 AC-3's tree-scoped clean-diff over `tests/canonical/` is delivery-scoped, evaluated at feature-001's own close, and its substance — the seed-count suite set it names — survives untouched; the site commits roster-derived generated content (`site/src/content/docs/skills/`, `site/src/data/skill-flows/`, three generator manifests) that feature-006 §5's *"nothing to build"* does not cover; and two of feature-006 §7's named site edit sites are `sync-docs.mjs` targets, not hand-maintained files, so the fix goes in the `docs/` source and the mirror is regenerated. Also surfaced, and **fixed here rather than reported**: the per-delivery graph headings did not match the shape both `compute-block-radius.sh` and `complexity-score.sh` require — `### delivery-NNN` followed by a level-four `#### Execution Graph`, the form both suites test and `state-delivery-gate.md:105-106` documents. This PLAN had written them as level-three `### delivery-NNN execution graph`, so an unscoped `compute-block-radius.sh` parse saw delivery-001's 25 rows and stopped while a scoped one saw none, and `complexity-score.sh` captured **zero** rows for every delivery including 001. Diagnosed at first as a defect in those scripts; it was this table's shape. Corrected to the documented form, verified by re-implementing both awk state machines against this file rather than running either script — 25 / 24 / 25 nodes with a 74-node union, and `parsed_rows` 25 / 24 / 25. **No shipped-script defect against either consumer survives, and none is recorded** | /aid-detail |
