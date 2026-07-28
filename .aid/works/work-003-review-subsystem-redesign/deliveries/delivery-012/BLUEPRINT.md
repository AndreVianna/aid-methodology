# Delivery BLUEPRINT -- delivery-012: Review extraction

> **Delivery:** delivery-012
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Extract review into two shared skills so nine pipeline callers stop carrying their own copies of the
dispatch, ledger and FIX-loop machinery. This is where AC-11 is earned.

## Scope

- `aid-light-review` (screens, computes no grade, writes no coverage rows) and `aid-deep-review`
  (the full sweep, ledger, gap gate, grade and FIX loop).
- The shared `reviewer-brief-template.md`, and the six per-skill briefs shrunk in place to their two
  genuinely per-skill sections.
- The invocation manifest, replacing free-text brief passing.
- Nine caller migrations: the eight dispatch owners plus `aid-review`, whose meta-review VERIFY loop
  is deliberately retained.
- The terminal hand-off line under CHAIN's use list -- a new use of an existing advance type, not a
  fifth type.
- `aid-triage` routing so a human review request lands on `/aid-review`.

**Out of scope:** the `aid-reviewer` body rewrite (delivery-011); the ~19 `repurpose` VERIFY
dispatches (deferred).

## Gate Criteria

- [ ] Every migrated caller's review-mechanics line count strictly decreases against the
      delivery-001 baseline
- [ ] The shared-asset budget plus the new shared assets is below the pre-migration budget -- the
      anti-gaming clause
- [ ] Aggregate per-caller count falls by at least 40% (AC-11, **provisional** -- re-certified at
      delivery-014)
- [ ] A clean light pass leaves no coverage artifact a deep pass could mistake for clearance
- [ ] Identical review behaviour on all five profiles (AC-12) -- this delivery owns the criterion of
      record
- [ ] The six brief files still exist at their paths, so the inherited mode-declaration oracle stays
      non-vacuous
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-009, delivery-010
- **Blocks:** delivery-014, delivery-016, delivery-017, delivery-018

## Notes

**Spine delivery.** Two inherited oracles must be inverted here: the gap-policy brief assertion, and
the mode-declaration surface, which shrinks from 12 files to 7.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | Shared brief and invocation manifest |
| task-002 | IMPLEMENT | 2 | aid-light-review |
| task-003 | IMPLEMENT | 2 | aid-deep-review |
| task-004 | REFACTOR | 3 | Shrink the six briefs |
| task-005 | MIGRATE | 3 | Migrate nine callers |
| task-006 | TEST | 4 | AC-11 and AC-12 |
