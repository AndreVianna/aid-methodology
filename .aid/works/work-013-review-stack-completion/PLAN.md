# Plan -- Review Stack Completion

## Deliverables

### delivery-001: The Single, Watched Stack
- **What it delivers:** One review system, documented as it actually runs, with the useful
  checks from the abandoned catalog kept as citable criteria — and its six remaining blind
  spots closed by gates that each prove they fire. Closes with a re-runnable audit command
  whose output is recorded, not a claim.
- **Features:** feature-001-single-review-path-alignment, feature-002-coverage-gate-completion
- **Depends on:** --
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | task-003, task-004, task-005 |
| task-007 | task-001 |
| task-008 | task-007 |
| task-009 | task-002, task-006, task-007, task-008 |
| task-010 | task-009 |
| task-011 | task-010 |
| task-012 | task-011 |
| task-013 | task-009 |
| task-014 | task-013 |
| task-015 | task-013 |
| task-016 | task-009 |
| task-017 | task-016 |
| task-018 | task-010 |
| task-019 | task-014 |
| task-020 | task-019 |
| task-021 | task-006, task-020 |
| task-022 | task-002, task-009 |
| task-023 | task-009 |
| task-024 | task-009 |
| task-025 | task-010, task-011, task-012, task-013, task-014, task-015, task-016, task-017, task-018, task-019, task-020, task-021, task-022, task-023, task-024 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003, task-004, task-005, task-007 |
| task-006, task-008 |
| task-010, task-013, task-016, task-022, task-023, task-024 |
| task-011, task-014, task-015, task-017, task-018 |
| task-012, task-019 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003, task-004, task-005, task-007
wave 3: task-006, task-008
wave 4: task-009
wave 5: task-010, task-013, task-016, task-022, task-023, task-024
wave 6: task-011, task-014, task-015, task-017, task-018
wave 7: task-012, task-019
wave 8: task-020
wave 9: task-021
wave 10: task-025
```

### delivery-002: An Honest Grade
- **What it delivers:** A grade that means distance from the ideal — every finding carries a
  why-line naming the consequence, a new review cycle is structurally unable to read the
  previous one's ledger, recall against seeded defects is measured rather than assumed, and a
  fix sweeps its own defect class before closing.
- **Features:** feature-003-severity-and-recall-measurement
- **Depends on:** delivery-001
- **Priority:** Should

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-026 | — |
| task-027 | task-026 |
| task-028 | task-027 |
| task-029 | task-028 |
| task-030 | task-028 |
| task-031 | task-026 |
| task-032 | task-031 |
| task-033 | task-032 |
| task-034 | task-033 |
| task-035 | task-034 |
| task-036 | task-026 |
| task-037 | task-036 |
| task-038 | task-036, task-037 |
| task-039 | task-038 |
| task-040 | task-038 |
| task-041 | task-026 |
| task-042 | task-027, task-037, task-041 |
| task-043 | task-028 |
| task-044 | task-027, task-043 |
| task-045 | task-031 |
| task-046 | task-045 |
| task-047 | task-046 |
| task-048 | task-029, task-030, task-035, task-040, task-042, task-044, task-047 |

| Can Be Done In Parallel |
|------------------------|
| task-027, task-031, task-036, task-041 |
| task-028, task-032, task-037, task-045 |
| task-029, task-030, task-033, task-038, task-042, task-043, task-046 |
| task-034, task-039, task-040, task-044, task-047 |

```wave-map
delivery: 002
wave 1: task-026
wave 2: task-027, task-031, task-036, task-041
wave 3: task-028, task-032, task-037, task-045
wave 4: task-029, task-030, task-033, task-038, task-042, task-043, task-046
wave 5: task-034, task-039, task-040, task-044, task-047
wave 6: task-035
wave 7: task-048
```

## Why two, and not one or three

Recorded because the owner asked for one delivery and the answer is two; a reader deserves the
reasoning rather than the count.

Most of the argument that made this work **three features** does not transfer to deliveries, and
was tested rather than inherited:

| Inherited claim | Holds for deliveries? |
|---|---|
| A feature is atomic to a delivery, so one feature means one delivery | Not applicable — that bound features. `first-run-loop.md` Step 2 groups features *into* a deliverable |
| One delivery has one gate, so T1 never closes | **False.** FR-A5's "closes with a recorded audit" is a *task* running a named command, ordered by the execution graph — not a gate |
| AC-2's "after T1" needs a delivery boundary | **False.** Every `aid-execute` dispatch renders a brief to disk and runs `review-cost-meter.sh record`, so the first T2 task's own review already is a real dispatch after T1 |
| §10's Must/Must/Should needs three Priority scalars | **Mostly false.** Nothing parses `Priority`; it appears only in templates, examples, and one reviewer check |

One argument survives, and it is why the count is not one: **one delivery is one branch, one
gate, and one 3-cycle circuit breaker** (`state-delivery-gate.md`; `quality-gates.md`) over the
union of all 23 acceptance criteria. This work's own artifacts have already needed **six** cycles
to clear a single gate at minimum grade `A` (`review-cost.tsv`, rows 1–6 for
`specify-feature-002`). A trip would halt T1 work that had already passed. And T3 is priority
`Should` while containing four `MUST` criteria, so a single delivery would let Should work block
Must work from merging.

The count is not three because feature-001 and feature-002 are both `Must`, are ordered T1 → T2,
and their **one shared file is orderable rather than conflicting**: `reviewer-dispatch.md` is
edited by feature-001 for FR-A2 and by feature-002 for the in-document changelog FR-B7 inherits,
in different sections, so task order inside one delivery resolves it at no cost (Risk 1 below
carries that ordering). A boundary between them would buy isolation and pay a third gate for it.
The boundary is placed where the tension is not orderable: feature-003 **edits**
`reviewer-ledger-schema.md`, the one file feature-001 requires **unchanged** — a contradiction a
shared gate would have to resolve, not an ordering a task list can.

**What one delivery would have cost, stated plainly:** the Must half would not merge until the
Should half cleared the same gate. The alternative single-delivery shape — feature-001 plus
feature-002 with feature-003 explicitly deferred — was available and not chosen, because it drops
T3 rather than sequencing it.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | `reviewer-dispatch.md`, `authoring-conventions.md` and `frontmatter-schema.md` are each edited by two or three features, in different sections | M | Order the tasks: feature-001's edit before feature-002's inside delivery-001; delivery-002 branches from delivery-001's merged state, so feature-003 rebases onto both rather than merging around them |
| 2 | `reviewer-ledger-schema.md` is required **unchanged** by feature-001 and **edited** by feature-003; a reviewer seeing both reads a contradiction | M | The delivery boundary is the mitigation — each gate diffs against its own recorded base. Read Q1's second disjunct only ("touches neither counting logic nor column shape"); feature-003 verifies that behaviourally, three ways |
| 3 | Both deliveries drive the generator, and a **partial** render leaves stale emission manifests, so CI render-drift fails. delivery-001 drives five generated regions, not the usual four | H | Full `run_generator.py` (never a per-script renderer) plus `verify_deterministic.py` PASS as explicit gate criteria, plus `gen-skills.mjs` and `sync-docs.mjs` for delivery-001's site regions. Never edit a rendered copy |
| 4 | Nine of eleven Q&A entries are Pending, and five land on feature-002 — inside delivery-001 | H for Detail, not for Plan | Each SPEC states what it does *regardless* of its open questions, so the boundaries are not blocked. **Q5 and Q6 must be answered before `/aid-detail` on delivery-001**: they change task count and one criterion's wording |
| 5 | The delivery gate stops on a 3-cycle circuit breaker, and this work's own artifacts have needed 6 cycles at minimum grade `A` | H | The two-delivery split is the primary mitigation — it halves each gate's surface and stops a T3 stall from halting passed T1/T2 work. Secondary: per-task quick checks catch `[CRITICAL]`/`[HIGH]` before the gate accumulates them |

## Open before Detail

Not blockers for this plan; each blocks task-writing on the delivery named.

| Item | Blocks | Why |
|---|---|---|
| **Q5** — FR-B6 vs NFR-1, and how the V1 gate's `F` is expressed | delivery-001 | Decides whether the SHOULD gate criterion is satisfied or recorded as declined |
| **Q6** — what "specify per-section review" means | delivery-001 | A task criterion cannot be written against an undefined mechanism |
| **Q3** — `kb.html` as a registry type vs a standalone check | delivery-001 | The registry route also needs `G-07`'s wording widened; materially more task work |
| **Q2** — the 11 dashboard parser fixtures | delivery-001 | Rewrite-and-rebase, or a named exclusion — about one task's difference |
| **Q1** — AC-11's base ref | both | All three SPECs already use the work's own base commit; the wording fix is still owed |
| Criterion id allocation | both | All three SPECs deliberately allocate zero ids, because an invented id is itself a defect. At least four allocations are owed |
