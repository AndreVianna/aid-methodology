# Plan -- Knowledge Base Skills Overhaul

> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23
> **Source:** SPEC features feature-001..feature-012 (`features/`), REQUIREMENTS.md, whole-work-review.md

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-23 | Initial plan — 9 deliveries (essence-core-first → greenfield Could) | /aid-plan |
| 2026-06-23 | greenfield de-scope — the former greenfield-path delivery (then numbered delivery-009, a now-defunct identifier distinct from the current live delivery-009 Governance created in the later act-back insert) removed; work was 8 deliveries (delivery-001..008) at that point. Greenfield reduced to detect+signpost in delivery-004's recon (no generation engine / elicit path / closure / panel); f006/f012 brownfield-only scope notes updated; R1 (greenfield scope-split) retired. Forward-authored KB-seed deferred to a future interview-side work. | user decision |
| 2026-06-23 | act-back insert — feature-013 (Operational-Sufficiency / act-back gate) inserted as the NEW delivery-005 (4 tasks, 027-030); the downstream paper deliveries shift down one (Validation 005->006, Freshness 006->007, Topology+Ship 007->008, Governance 008->009) and renumber contiguously. delivery-006 (Validation) gains ONE new task (task-039, the act-back V-E fixture family) and now depends on delivery-005. Work is now **9 deliveries / 55 tasks** (delivery-001..004 + tasks 001-026 are FROZEN/byte-untouched — delivery-001 is built). | user decision (feature-013) |

This plan decomposes work-001 into **9 deliveries**. The sequence is user-approved.
Each delivery is one branch/PR (`aid/work-001-delivery-NNN`). The strategy: build the
**essence engine end-to-end first** (delivery-001 = the 'Relative bus' capability), then
flip AID's own surfaces onto the new schema (INDEX, migration), scale it to project shape
(adaptive paths), lock it in with a CI-anchored regression fixture, then layer the
Should-priority lifecycle skills (freshness, topology+ship, governance).

**Greenfield is detect-and-signpost, not a generation path.** A from-scratch project
(recon detects ~0 source) is not discovered by a bespoke greenfield engine; `aid-discover`
emits a signpost and halts ("Nothing to discover yet — run /aid-interview to define the
project; the KB fills in via re-triage once code lands"). The two generation paths this
work builds are brownfield-small and brownfield-large. Forward-authored greenfield KB-seed
(eliciting intended architecture/conventions/ubiquitous-language for a from-scratch
project) is a **future interview-side capability, out of scope here.**

The strategy is **provide-before-consume**: every feature's frontmatter/schema/oracle
producer lands in or before the delivery that consumes it. delivery-001 establishes the
whole essence substrate (frontmatter primitive f001, concern model f003, the
harvest/spine/closure engine f004, the review panel f005) so the downstream deliveries
consume settled contracts.

## Deliverables

### delivery-001: Essence Core

- **What it delivers:** the 'Relative bus' capability end-to-end -- essence capture (mechanical
  coined-term harvest + the non-lexical conceptual-synthesis channel) feeding a grounded concept
  spine, a bounded comprehension/closure loop, and a multi-mandate review panel with teach-back as
  the keystone hard gate. After delivery-001, `/aid-discover` captures a project's essence and
  certifies it (teach-back closure replaces "severity >= A+" as the exit).
- **Features:** feature-001 (frontmatter & `sources:` primitive), feature-003 (KB document model /
  concern model), feature-004 (essence-capture research engine), feature-005 (review panel & rubric)
- **Depends on:** -- (none)
- **Priority:** Must

### delivery-002: INDEX Routing

- **What it delivers:** `INDEX.md` flips from today's prose-`intent:` list to the generated,
  deterministic routing table (Document | Objective | Summary | Tags | See-instead | Audience),
  composed mechanically by `build-kb-index.sh` from the frontmatter fields delivery-001 established.
- **Features:** feature-002 (INDEX routing table)
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: KB Migration

- **What it delivers:** AID's own KB (plus a fixture old-format KB) migrated onto the new
  frontmatter schema and INDEX format; the `lint-frontmatter.sh` flipped to a hard gate **for AID**
  (the shipped soft-skip retained for adopter degrade-grace); old-format coexistence remains
  degrade-graceful. Moved early so AID dogfoods the schema and so later freshness operates on
  stamped `approved_at_commit:` docs.
- **Features:** feature-011 (KB migration)
- **Depends on:** delivery-001, delivery-002
- **Priority:** Must

### delivery-004: Adaptive Paths (brownfield)

- **What it delivers:** a recon pre-pass that **measures** source-availability/complexity and
  **proposes** a path (human-confirmed, not declared from `project.type`), then scales the closure
  engine + review panel to project size for the brownfield-small and brownfield-large paths.
- **Features:** feature-006 -- recon classifier (which **detects** greenfield, ~0 source),
  brownfield-small path, brownfield-large path. **Greenfield = detect + signpost, not a path:**
  when the classifier detects ~0 source, `aid-discover` emits a signpost and halts ("Nothing to
  discover yet — run /aid-interview to define the project; the KB fills in via re-triage once code
  lands"). There is **no** greenfield generation engine / elicit-via-interview-specify path /
  greenfield closure / greenfield panel. The only two *generation* paths are brownfield-small and
  brownfield-large. (Forward-authored greenfield KB-seed is a future interview-side work, out of
  scope — see the work-level scope note.)
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-005: Operational-Sufficiency (Act-Back Gate)

- **What it delivers:** the **act-back gate** (FR-36) -- the operational sibling of teach-back. A 6th
  mandate (M6) grafted onto delivery-001 f005's review panel in which a clean-context `aid-reviewer`,
  given ONLY the KB + a representative project task, must produce a correct plan AND flag every point
  of KB insufficiency (each a `[HIGH]` `[ACTBACK]` row the **existing** `grade.sh` already grades --
  no new grading infra, no separate verdict sentinel). It also **tightens f003's doc model** so
  operational guidance (conventions / invariants / gotchas / contracts) is first-class greppable
  structure, and ships ONE small ASCII helper (`kb-actback-task.sh`: representative-task selector +
  operational-structure presence check). After delivery-005, `/aid-discover`'s REVIEW reports the
  **triple** `Grade | Teach-back | Act-back`, with act-back as a sibling keystone.
- **Features:** feature-013 (operational sufficiency / act-back gate)
- **Depends on:** delivery-001 (extends f005's panel + f003's doc model + consumes f001's `sources:`)
- **Priority:** Must

> **Note (extend, don't re-spec; [SPIKE-A4]):** f013 reuses f005's parallel-dispatch + merged-ledger +
> `grade.sh` + `{{SCOPE}}` seam **verbatim** and *adds one mandate alongside them*; it *extends* f003's
> doc model with one structural rule and *consumes* f001's `sources:`. It lands **after** delivery-001
> (extend-after-base) and **before** delivery-006 (Validation), which builds + exercises the act-back
> fixture shape f013 defines ([SPIKE-A5], provide-before-exercise). Because M6 joins the per-mandate
> dispatch list, f006's brownfield-small panel collapse folds M6 in automatically ([SPIKE-A3]).

### delivery-006: Validation Fixture

- **What it delivers:** the CI-anchored regression proof that locks in the essence engine -- the
  planted 'Relative bus' fixture proving capture-and-define, the closure self-containment proof, the
  calibration-severity calibration, the teach-back closure proof (pass/fail KBs), the two brownfield
  path fixtures, and a greenfield **detection + signpost** test.
- **Features:** feature-012 -- AC1 teach-back closure fixture, AC2 'Relative bus' regression,
  AC3 closure self-containment, AC6 calibration tuning, AC7 the **two brownfield-small/large path
  fixtures + a greenfield detection/signpost test** (asserts the classifier detects ~0 source and
  that `aid-discover` emits the signpost and halts -- **not** a greenfield path-runs/reaches-closure
  fixture, since greenfield is not a generation path), AND **AC16 -- the act-back V-E fixture family**
  (the new task-039): the representative-task spec fixture + the `actback-pass-kb`/`actback-fail-kb`
  pair + the V-E mechanical assertion that delivery-005's `kb-actback-task.sh` emits the task
  byte-reproducibly and the presence check reports the operational sections present/absent; the M6
  plan-success/flag judgment is runtime-anchored (Judgment-Boundary row), mirroring the
  teach-back/calibration mechanical-vs-judgment split. f013 defines the fixture *shape*; f012 builds +
  exercises it ([SPIKE-A5]).
- **Depends on:** delivery-001, delivery-004, delivery-005
- **Priority:** Must

### delivery-007: Freshness Primitive

- **What it delivers:** a deterministic per-doc, source-keyed staleness check (each doc's `sources:`
  last-changed commit vs its approval commit -> suspect flag) and its surfacing in both dashboard
  readers (replacing the coarse whole-KB badge); auto-detect/flag, never auto-apply.
- **Features:** feature-007 (per-doc freshness loop)
- **Depends on:** delivery-001
- **Priority:** Should

### delivery-008: Skill Topology + Ship

- **What it delivers:** the `aid-ask` -> `aid-query-kb` rename + the new `aid-update-kb` skill
  (reusing delivery-001's f005 review/calibration gate via the injectable-scope seam) + query-side
  gap-capture, AND the full cross-tree render / orphan-prune / 5-install-manifest lockstep /
  "N user-facing skills" count reconcile / docs-site propagation.
- **Features:** feature-008 (skill topology, author/behavior side), feature-009 (skill-change
  propagation, ship side)
- **Depends on:** delivery-001, delivery-007
- **Priority:** Should

> **Note (f008 + f009 inseparable):** feature-008 and feature-009 are ONE delivery -- one branch,
> one PR, no release tag cut between them. Per the whole-work review, render-drift CI is RED on
> f008 alone (canonical renamed but host trees not re-rendered); f009 is what makes it green.
> Cutting a release between them would ship a half-renamed repo. See Cross-Cutting Risks.

### delivery-009: Lifecycle Governance

- **What it delivers:** the non-overlapping `aid-housekeep` (KB-DELTA, source-driven, global) <->
  `aid-update-kb` (prompt-driven, targeted) boundary contract, with per-doc staleness (f007) as the
  shared scoping signal, AND concept-closure promoted from a discovery-only check to a standing
  invariant re-verified after every KB-mutating skill run.
- **Features:** feature-010 (housekeep <-> update-kb boundary & standing closure)
- **Depends on:** delivery-001, delivery-007, delivery-008
- **Priority:** Should

## Cross-Cutting Risks

> **Retired R1 (greenfield scope-split).** The original R1 tracked the f006/f012
> brownfield-vs-greenfield split across delivery-004 (Adaptive Paths) + the Validation delivery
> (then delivery-005, now delivery-006 after the act-back insert) and the deleted greenfield-path
> delivery (the defunct pre-act-back greenfield-path delivery -- NOT the current live delivery-009
> Governance). With greenfield reduced to detect + signpost inside delivery-004's recon (no separate
> greenfield delivery, no greenfield generation path), there is no split to manage and the
> risk is moot. R2/R3 below retain their original numbering.

| # | Risk | Affected deliveries | Mitigation |
|---|------|---------------------|------------|
| R2 | **f008+f009 inseparability** -- a release tag cut between feature-008 (canonical rename) and feature-009 (cross-tree propagation) would ship a half-renamed repo: canonical renamed but the 5 host trees, install manifests, and skill counts stale, with render-drift CI red. | delivery-008 | The two features are **one delivery** -- one branch, one PR, **no intervening release tag**. render-drift CI is RED on f008 alone and green only once f009 propagates, so the gate itself enforces "ship together." |
| R3 | **calibration-floor back-patch** -- delivery-006 (validation fixtures) re-tunes defaults that ALREADY shipped in merged delivery-001 (f004 SPIKE-H2 denylist/salience floor, f005 SPIKE-C1 calibration severity) and delivery-004 (f006 triage thresholds). Per the contract "the default lives in the owning feature's file; the fixture pins it," editing a constant in an already-shipped delivery can regress that delivery's gate. **Impact: M.** | delivery-001, delivery-004, delivery-006 | After any threshold/floor edit prompted by a later delivery's fixture, re-run the owning delivery's gate suite (the owning feature's canonical tests) to confirm no regression. |

## Execution Graphs

The graphs below are derived mechanically from the `Depends on:` line of every
task SPEC (`delivery-NNN/tasks/task-NNN/SPEC.md`). Each delivery's `Depends On`
table lists the task's FULL dependency set; dependencies that point into an
**earlier** delivery are marked `(d-NNN)` and are pre-satisfied by the
delivery-order sequence (d001 -> d009), so they do not affect intra-delivery
wave ordering. The `wave-map` block is total over the delivery's own tasks.

**Global-DAG validation (all 55 tasks assembled):** acyclic (55/55
topo-sorted); every dependency resolves to an existing task; no forward
reference across deliveries (no dep points into a later delivery); no
intra-delivery dependency on a higher-numbered sibling. Roots (no deps):
task-001, task-031, task-032, task-033, task-037, task-045, task-047.
(feature-013 / act-back was inserted as delivery-005 = tasks 027-030, all of
which depend into delivery-001, so none is a root; the downstream paper
deliveries shifted down one and renumbered contiguously. 55 tasks across
delivery-001..009; tasks 001-026 / delivery-001..004 are FROZEN/byte-untouched.)

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | task-002 |
| task-007 | task-006 |
| task-008 | task-002, task-006 |
| task-009 | task-008 |
| task-010 | task-001, task-004 |
| task-011 | task-006, task-008, task-010 |
| task-012 | task-006 |
| task-013 | task-008 |
| task-014 | task-008, task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-004, task-005 |
| task-003, task-006, task-010 |
| task-007, task-008, task-012 |
| task-009, task-011, task-013, task-014 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-004, task-005
wave 3: task-003, task-006, task-010
wave 4: task-007, task-008, task-012
wave 5: task-009, task-011, task-013, task-014
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-015 | task-002 (d001) |
| task-016 | task-015 |
| task-017 | task-015, task-016 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 002
wave 1: task-015
wave 2: task-016
wave 3: task-017
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-018 | task-001 (d001), task-003 (d001), task-015 (d002) |
| task-019 | task-018 |
| task-020 | task-003 (d001), task-018 |
| task-021 | task-010 (d001), task-018 |
| task-022 | task-018, task-019, task-020, task-021 |

| Can Be Done In Parallel |
|------------------------|
| task-019, task-020, task-021 |

```wave-map
delivery: 003
wave 1: task-018
wave 2: task-019, task-020, task-021
wave 3: task-022
```

### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-023 | task-006 (d001) |
| task-024 | task-023 |
| task-025 | task-023, task-011 (d001) |
| task-026 | task-014 (d001), task-025 |

| Can Be Done In Parallel |
|------------------------|
| task-024, task-025 |

```wave-map
delivery: 004
wave 1: task-023
wave 2: task-024, task-025
wave 3: task-026
```

### delivery-005 execution graph

| Task | Depends On |
|------|-----------|
| task-027 | task-004 (d001), task-010 (d001) |
| task-028 | task-008 (d001), task-027 (d005) |
| task-029 | task-027, task-028, task-014 (d001) |
| task-030 | task-028 |

| Can Be Done In Parallel |
|------------------------|
| task-029, task-030 |

```wave-map
delivery: 005
wave 1: task-027
wave 2: task-028
wave 3: task-029, task-030
```

### delivery-006 execution graph

| Task | Depends On |
|------|-----------|
| task-031 | — |
| task-032 | — |
| task-033 | — |
| task-034 | task-031, task-006 (d001), task-008 (d001) |
| task-035 | task-032, task-008 (d001) |
| task-036 | task-033, task-023 (d004) |
| task-037 | — |
| task-038 | task-037, task-012 (d001) |
| task-039 | task-028 (d005), task-029 (d005) |

| Can Be Done In Parallel |
|------------------------|
| task-031, task-032, task-033, task-037 |
| task-034, task-035, task-036, task-038, task-039 |

```wave-map
delivery: 006
wave 1: task-031, task-032, task-033, task-037
wave 2: task-034, task-035, task-036, task-038, task-039
```

### delivery-007 execution graph

| Task | Depends On |
|------|-----------|
| task-040 | task-001 (d001), task-002 (d001) |
| task-041 | task-040 |
| task-042 | task-040, task-001 (d001) |
| task-043 | task-042 |
| task-044 | task-042 |

| Can Be Done In Parallel |
|------------------------|
| task-041, task-042 |
| task-043, task-044 |

```wave-map
delivery: 007
wave 1: task-040
wave 2: task-041, task-042
wave 3: task-043, task-044
```

### delivery-008 execution graph

| Task | Depends On |
|------|-----------|
| task-045 | — |
| task-046 | task-045 |
| task-047 | — |
| task-048 | task-047, task-014 (d001), task-040 (d007) |
| task-049 | task-046, task-048 |
| task-050 | task-049 |
| task-051 | task-050 |
| task-052 | task-049 |

| Can Be Done In Parallel |
|------------------------|
| task-045, task-047 |
| task-046, task-048 |
| task-050, task-052 |

```wave-map
delivery: 008
wave 1: task-045, task-047
wave 2: task-046, task-048
wave 3: task-049
wave 4: task-050, task-052
wave 5: task-051
```

### delivery-009 execution graph

| Task | Depends On |
|------|-----------|
| task-053 | task-048 (d008) |
| task-054 | task-053, task-040 (d007), task-008 (d001) |
| task-055 | task-054 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 009
wave 1: task-053
wave 2: task-054
wave 3: task-055
```
