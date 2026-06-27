# Delivery SPEC -- delivery-005: Operational-Sufficiency (Act-Back Gate)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan/aid-detail; not a state file. State lives in delivery-005/STATE.md.

> **Delivery:** delivery-005
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Close the **agent-actionability** gap. The KB's primary purpose is operating guidance for an AI
agent doing work in the project, but the delivery-001 panel verifies only *comprehension* +
*correctness* (teach-back/calibration/closure), never *actionability* -- "could an agent, given ONLY
the KB, correctly DO a representative change?". This delivery adds the **act-back gate** (FR-36) as
the **operational sibling of teach-back**: a 6th mandate (M6) grafted onto delivery-001 f005's review
panel in which a clean-context `aid-reviewer`, given ONLY the KB + a representative project task, must
(a) produce a correct plan AND (b) flag every point of KB insufficiency, each flag a `[HIGH]`
`[ACTBACK]` row in the **existing** merged `discovery.md` ledger the **existing** `grade.sh` already
grades. To make the KB *act-on-able*, it also **tightens f003's doc model** so operational guidance
(conventions / invariants / gotchas / contracts) is **first-class greppable structure**, and ships
**one** small ASCII helper (`kb-actback-task.sh`) that selects the representative task + runs the
operational-structure presence check. After delivery-005, `/aid-discover`'s REVIEW reports the
**triple** `Grade | Teach-back | Act-back`, with act-back as a sibling keystone.

## Scope

In scope -- **feature-013, the act-back gate** (an *extension* of f005's panel + f003's doc model;
it re-specs neither):

- **M6 act-back mandate wired into f005's `state-review.md`** -- the 5->6 parallel-dispatch edit, the
  new `discovery-actback.md` scratch ledger merged into the single `discovery.md`, and the Step-3
  reporting **triple** (`Grade | Teach-back | Act-back`); plus the new `reviewer-prompt-actback.md`
  FOCUS body and the `[ACTBACK]` tag added to `review-rubric.md`. The act-back keystone is realized
  through the `[HIGH] [ACTBACK]` rows the existing `grade.sh` already enforces -- **no new grading
  infra, no separate verdict sentinel.**
- **`kb-actback-task.sh` (NEW, ASCII bash, pure coreutils)** -- (1) emits the representative-task
  spec from the machine-readable substrate (resolved `discovery.doc_set` filenames + presence + the
  operational sections present); (2) the operational-structure presence check scoped per f003's
  owning-table. Added to `test-ascii-only.sh`'s allow-list; CI-asserted by its own canonical suite.
- **Doc-model tightening (extends f003)** -- "operational guidance is first-class structure" authored
  into `concern-model.md` + `principles.md` (the four classes -> named greppable sections -> owning
  concerns table) + an **operational open-question** added to the relevant docs' entries in
  `document-expectations.md`. No f003 machinery change (concern list, seed mapping, resolver untouched);
  **no** f001 schema change (named sections, not a frontmatter field).

**Out of scope (elsewhere):** the **5-mandate panel + parallel fan-out + merged-ledger + `grade.sh` +
`{{SCOPE}}` seam** (f005, delivery-001 -- *reused verbatim*, not re-specced); the **doc model** itself
(f003, delivery-001 -- *extended* with one structural rule); the **`sources:` schema** (f001,
delivery-001 -- *consumed* so M6 can say "the KB defers this to source"); the **panel-size scaling by
path** (f006, delivery-004 -- M6 joins the per-mandate dispatch list f006 scales); **migration** of
AID's own KB to add the operational sections (f011, already-merged delivery-003); and the **end-to-end
act-back fixture (representative-task spec fixture + `actback-pass-kb`/`actback-fail-kb` pair + the V-E
regression family + the AC16 Judgment-Boundary row)**, which is **delivery-006 / f012**'s to build +
exercise (this delivery ships only `kb-actback-task.sh`'s small in-suite unit fixture). f013 defines the
act-back fixture *shape*; f012 owns the *files + suites + threshold-pinning* ([SPIKE-A1] is
f012-calibrated).

## Gate Criteria

- [ ] Given a reviewed KB, when the panel runs, then it applies a **6th mandate (M6 act-back)**: a
  clean-context reviewer, given ONLY the KB + the representative-task spec, produces a plan AND flags
  every KB-insufficiency point; each flag is a `[HIGH]` `[ACTBACK]` row in the same merged ledger; any
  open `[ACTBACK]` row forces grade <= D (sibling keystone alongside teach-back). *(f013, AC1; FR-36)*
- [ ] Given a KB doc that carries operational guidance, when it is authored, then its conventions /
  invariants / gotchas / contracts are **first-class named greppable sections** (per the
  `concern-model.md` rule), scoped to the classes each doc is expected to own; the M6 presence check
  reports `present|absent` only for expected classes. *(f013, AC2; extends FR-9/FR-11)*
- [ ] Given the act-back fixture shape, the **mechanical half** (`kb-actback-task.sh` emits the task
  deterministically + byte-reproducibly; the presence check reports present/absent correctly over an
  in-suite fixture) is CI-asserted here; the end-to-end pass/fail-KB fixture + judgment-anchored
  assertions (V-E family) are exercised by delivery-006 / f012. *(f013, AC3; supports AC16)*
- [ ] `kb-actback-task.sh` is pure coreutils, ASCII, stable-sorted, byte-reproducible, on
  `test-ascii-only.sh`'s allow-list; all canonical edits render to all 5 trees (render-drift green via
  `run_generator.py`). *(f013, C1/C2/C3/NFR-3)*
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-027 | IMPLEMENT | kb-actback-task.sh -- representative-task selector + operational-structure presence check |
| task-028 | IMPLEMENT | Doc-model tightening -- operational guidance first-class (concern-model + principles + document-expectations) |
| task-029 | IMPLEMENT | M6 act-back mandate wired into f005's panel (state-review 5->6 + reviewer-prompt-actback + [ACTBACK] rubric tag) |
| task-030 | TEST | test-actback-task.sh canonical suite + ascii-only allow-list |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-006 (f012 exercises the act-back fixture shape defined here)

## Notes

**Act-back inserted as delivery-005 (2026-06-23).** feature-013 was authored post-detail to close the
agent-actionability gap. It is inserted as the new delivery-005, **before** the Validation delivery
(now delivery-006) that exercises its fixture, and **after** delivery-001 whose f001/f003/f005 it
consumes/extends (provide-before-consume, extend-after-base -- [SPIKE-A4]). The downstream paper
deliveries shifted down by one: Validation 005->006, Freshness 006->007, Topology+Ship 007->008,
Governance 008->009.

**Reuse, don't re-spec.** M6 reuses f005's parallel-dispatch + merged-ledger + `grade.sh` machinery
verbatim ([SPIKE-A4]); the act-back keystone is `[HIGH] [ACTBACK]` rows the existing grader enforces
(no separate boolean, no AND/OR). Because M6 joins the per-mandate dispatch list, f006's panel-size
scaling applies to it automatically (brownfield-small folds M6 into the single checklist reviewer --
[SPIKE-A3]). The doc-model rule is the same additive class as f003's summary+pointer rule.

**Fixture ownership ([SPIKE-A5]).** This delivery ships only `kb-actback-task.sh`'s in-suite unit
fixture (`test-actback-task.sh`). The end-to-end act-back corpus (`actback-pass-kb`/`actback-fail-kb`
+ the representative-task spec fixture) and its V-E regression family + the AC16 Judgment-Boundary row
are **delivery-006 / f012**'s -- f013 defines the shape, f012 builds + exercises it (the f005/f006 ->
f012 arrangement). The [SPIKE-A1] task-shape heuristic is f012-calibrated, not pinned here.

**Render-drift ([SPIKE-A2]).** Edit canonical only; re-run `run_generator.py`; commit regenerated
`profiles/`. Verify the renderer auto-emits the net-new `reviewer-prompt-actback.md` reference and the
net-new `scripts/kb/kb-actback-task.sh` to all 5 trees; if an emission manifest pins the
`aid-discover/references/` or `scripts/kb/` list, update canonical + regen, never hand-place.
