# Delivery BLUEPRINT -- delivery-001: The review loop, measured then scoped

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-001/STATE.yml.

> **Delivery:** delivery-001
> **Work:** work-012-review-loop-cost
> **Created:** 2026-08-15

---

## Objective

Make a review cycle cost what the change costs rather than what the document costs, and let
a mechanically decidable criterion be settled by running a check instead of re-judging it —
then prove the saving on this work's own review cycles rather than asserting it.

This is scoped as one delivery, not two, because AC-1's measurement subject is **per-task**
review cycles split at the task that lands FR-3. A second delivery would push that split
later and shrink the "after" sample, so splitting would weaken the very evidence the work
exists to produce. The cost of the choice — no partial shipping — is recorded in PLAN.md
§ Cross-Cutting Risks and accepted.

## Scope

In scope — all three features:

- **feature-001-cost-measurement** (FR-15): `tests/review-cost-meter.sh` with `record` and
  `report`, the work-folder `review-cost.tsv` + `.meta` pair, and the baseline reading.
- **feature-002-criterion-oracles** (FR-8..FR-13): the optional `oracle:` key and its
  per-file exit contract; the `Match` selector grammar on the type registry; the reviewer
  instruction to run rather than re-read; `scripts/checks/g07-selector-partition.sh`.
- **feature-003-scoped-review-cycles** (FR-1..FR-7, FR-14): the cycle-N≥2 split into a full
  verification set and a scoped hunt set; the three guards; the requirements slice; and the
  work's close-out (single render, dogfood resync, final measurement).

**Out of scope:** the grading scale, the ledger's 7-column shape, `canonical/aid/scripts/grade.sh`,
and the criteria cascade itself (C-3, C-4, §4). Any `.aid/knowledge/` edit beyond the three
C-5 authorized on 2026-08-15 — the `oracle:` field, the `Match` column, and the scoped-cycle
note. Adding a `work-artifact` registry type, which Q-05 routes to `/aid-discover`.

## Gate Criteria

The delivery gate evaluates every acceptance criterion in REQUIREMENTS.md §9, since all
three features land here. Grouped by what they prove:

**The measurement is real (feature-001)**

- [ ] **AC-1** The reduction is observed on both metrics — cycles-to-close, and the
      within-task re-read ratio — measured before any remedy landed and again after, each
      figure recorded with the command that produced it. A raw cross-task byte comparison is
      refused as evidence.

**The oracle mechanism behaves (feature-002)**

- [ ] **AC-5** A criterion with no `oracle:` key produces no finding and grades as today.
- [ ] **AC-6** `G-07`'s oracle exits 0 on a clean corpus and non-zero naming the file on a
      corpus with an untyped or double-typed file.
- [ ] **AC-7** Two runs over an unchanged tree produce byte-identical output.
- [ ] **AC-8** A missing or non-executable oracle degrades to reading, and the degradation
      is reported.
- [ ] **AC-11** Every oracle shipped names the recurring re-derivation it replaces and its
      measured per-cycle cost; the net trade is reported. An oracle with no recorded
      replacement is not shipped.
- [ ] **AC-14** A criterion carrying an oracle is decided by the oracle's exit status, not
      by a reviewer re-reading it.
- [ ] **AC-15** Oracle generation is lazy — a second re-derivation is the trigger; `G-07` is
      the recorded exception.
- [ ] **AC-16** An oracle verdict lands in the existing 7-column ledger, criterion `id` as a
      `Description` prefix, invocation and output in `Evidence`.

**The scoping is safe (feature-003)**

- [ ] **AC-2** A defect seeded in a section that REFERENCES a changed section is found by a
      scoped cycle.
- [ ] **AC-3** A defect seeded outside the scoped surface, and missed by a scoped cycle, is
      caught by the final full pass.
- [ ] **AC-4** A `Fixed` row that regresses outside the scoped surface is still demoted to
      `Recurred`.
- [ ] **AC-13** The cross-document contradiction pass runs exactly once per phase, and still
      catches a contradiction spanning two features. Both halves required.

**The related win, and nothing broken (feature-003 close-out)**

- [ ] **AC-9** The specify gate carries the traced requirements slice, with the saving
      stated as a measured byte reduction on a real feature.
- [ ] **AC-10** The ledger is still 7 columns and `grade.sh` is byte-identical to its state
      at the start of the work.
- [ ] **AC-12** The render-drift gate and the dogfood byte-identity gate are green.

**Ordering, which the gate also checks**

- [ ] The baseline was captured before the first remedy landed. Mechanically: the earliest
      `review-cost.tsv` row's `commit` is an ancestor of the commit landing the first
      feature-002 or feature-003 task. If it is not, AC-1 is unprovable and no later
      evidence can repair it.
- [ ] **No feature-003 task precedes FR-3's task in the execution graph.** This replaces an
      earlier criterion reading "FR-3's task landed at the earliest point its dependencies
      allowed", which required a judgment about the task graph that the gate cannot make and
      that `/aid-detail` owns. The restated form is a lookup against the graph: list the
      feature-003 tasks, confirm FR-3's is first.
- [ ] The "after" sample's row count is reported alongside the AC-1 figures, so a thin
      sample is visible on the same line as the number it produced.

## Tasks

Written by `/aid-detail`: 15 tasks in 10 waves. The execution graph, the wave assignment
and the parallel-safety check live in `PLAN.md § Execution Graph`. `task-008` is FR-3 and
the AC-1 measurement split point.

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Review-cost meter: record and report |
| task-002 | TEST | Meter test suite |
| task-003 | IMPLEMENT | The optional `oracle:` key and its exit contract |
| task-004 | IMPLEMENT | Match selector grammar and oracle field in the criteria tables |
| task-005 | IMPLEMENT | G-07 selector-partition oracle |
| task-006 | IMPLEMENT | Reviewer instruction: run the oracle rather than re-read the criterion |
| task-007 | TEST | Oracle behaviour and coverage measurement |
| task-008 | IMPLEMENT | Cycle-2-and-later split: verification set and hunt set |
| task-009 | IMPLEMENT | Two-set ARTIFACTS rendering across every reviewer brief |
| task-010 | IMPLEMENT | Guard 2: contradiction pass on cycle 1 of each multi-artifact review |
| task-011 | IMPLEMENT | Requirements slice for the per-feature specify gate |
| task-012 | IMPLEMENT | Scoped-cycle convention in the criteria tables |
| task-013 | TEST | Scoping guards: seeded-defect verification |
| task-014 | IMPLEMENT | Close-out render and dogfood resync |
| task-015 | TEST | Final measurement and reporting |

## Dependencies

- **Depends on:** -- (none). `work-004`, the work's only dependency, merged to `master` on
  2026-08-14.
- **Blocks:** -- (none)

## Notes

- **C-5 is authorized but enumerated.** Three edits to
  `.aid/knowledge/authoring-conventions.md` only: the `oracle:` field, the `Match` selector
  column, and the scoped-cycle note. A task that finds it needs a fourth must stop and ask,
  not extend the grant by inference. In particular, formalising a selector must not change
  what that selector *means* — the acceptance test is that the oracle's classification of
  the current corpus is identical before and after.
- **The render happens once, at the end, with the full generator** — never a per-script
  renderer, or the render-drift gate fails on stale emission manifests.
- **feature-003 adds no executable surface at all**; feature-002 adds exactly one script.
  That accounting is what NFR-1 is measured against, so a task that adds an unplanned script
  changes the work's exit condition and needs to say so.
- **Expected gate tier: Large.** `STATE.yml` carries the template default `Small`, and
  `aid-plan` deliberately left it there — `gate_tier` is written by `aid-execute` via
  `writeback-state.sh --delivery-id NNN --field Tier`, so setting it here would be writing
  another skill's field. It is recorded as a note instead, because the default is a trap for
  this delivery: one delivery carries all three features, sixteen acceptance criteria, a new
  script, an owner-authorized KB edit and edits across two `canonical/` template families.
  A `Small` gate would under-resource that. `aid-execute` should set `Large` at the gate.
