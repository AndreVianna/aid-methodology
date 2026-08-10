# Delivery BLUEPRINT -- delivery-021: Greenfield split and record corrections

> **Delivery:** delivery-021
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Deliver the greenfield criteria-vs-evidence split that `delivery-007` closed `Done` without
delivering, and correct two statements in this work's own record that disk contradicts. Scoped as a
distinct unit because reopening a closed delivery would rewrite what its gate actually certified --
and the fact worth preserving is precisely that a delivery's recorded scope outran what was
performed.

## Scope

- The greenfield criteria-vs-evidence edit in
  `canonical/skills/aid-discover/references/document-expectations.md`. **Both regions
  `feature-004`'s SPEC claims are in scope, not just the split** -- `SPEC.md:435` assigns **13-19**
  (*"The mode header re-framed as criteria-versus-evidence"*) and **36-54** (which contains the
  split at 50-52), and this delivery's second gate criterion requires the SPEC's claimed regions to
  resolve after the edit, so scoping only 50-52 would leave that criterion undischargeable.
  Work-003 never touched the file -- its newest commit is from work-023 -- and `grep -i resolvable`
  over it returns nothing.
- `Q5` decision 7's text: it reads *"restart, not resume"*, which `Q6` proposal 3 consciously
  reversed. `criteria-gap-protocol.md` ships *"coverage rows resume rather than restart"*, so the
  entry's TEXT is wrong, not merely its status.
- `Q8` N3's carrier claim: it asserts *"Each feature SPEC now carries this note"* about the AC-12
  parity gate. `grep -c AC-12` across the eight returns `1,1,0,0,0,7,0,0` -- three of eight. The
  decision is sound; the claim about where it is recorded is false.

**Out of scope:** reopening `delivery-007` or any other delivery that has closed; the AC-12 parity gate's own
design, which is sound and is not revisited here.

## Gate Criteria

- [ ] `document-expectations.md` carries the criteria-vs-evidence split, and the universal rule it
      implements (`[GAP:CRITERIA]` blocks everywhere, `[GAP:EVIDENCE]` does not) is stated where a
      greenfield reviewer will read it
- [ ] The regions `feature-004`'s SPEC names for this edit resolve to text that exists **after** the
      edit lands -- i.e. the SPEC's claim becomes true because the edit was made, not because the
      SPEC was rewritten. This delivery edits `document-expectations.md`, never the SPEC
- [ ] `Q5` decision 7 states the resume behaviour that shipped, and cites `Q6` as the supersession
- [ ] `Q8` N3 states a measured carrier set rather than a universal claim, and each figure it gives
      is re-derived at the time of the edit rather than copied from this criterion -- the BLUEPRINT
      total moved from 18 to 23 while this delivery was being planned, which is exactly how the
      original claim went stale
- [ ] No delivery whose `delivery_state` is `Done` is modified by this delivery
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-007
- **Blocks:** delivery-022

## Notes

**These are not new defects; they are decided work that was never built, found by triaging eight
stale `Pending` Q&A entries against disk on 2026-08-09.** The stale `Status` field was the trivial
finding. The real one was that four decisions read as settled in prose while disk disagreed --
**three of them inside a delivery that closed `Done` or `Gated`, and one never scheduled into any
delivery at all**: `reviewer-guide.md`'s retirement. `grep -rln reviewer-guide deliveries/`, run
from this work folder, returns four files, and neither of the two that predate 2026-08-09 scopes the
deletion -- `delivery-001/BASELINE-ac11.md` merely measures the file for the `AC-11` baseline, and
`delivery-004/BLUEPRINT.md`'s **Out of scope** line calls it *"the retired `reviewer-guide.md`"*
while assigning the deletion to no one. The other two are `delivery-021` (this file) and `delivery-022`, written on
2026-08-09 precisely to carry the retirement that had no home (`STATE.md` `Q26` item 1). The two failure modes differ and
both matter: a closed gate that did not cover its recorded scope, and a decision that reached no
gate because it reached no delivery.

**Same class as `Q22`, from the other end.** There, a delivery was marked `Gated` with no gate ever
run. Here, a gate *did* run, over a delivery whose recorded scope included work nobody performed.
In both cases the tracking said the work was complete and no artifact of it exists.
