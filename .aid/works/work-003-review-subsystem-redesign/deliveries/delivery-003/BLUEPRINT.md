# Delivery BLUEPRINT -- delivery-003: Severity single source

> **Delivery:** delivery-003
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Collapse six competing severity definitions into one canonical scale, and remove "established best
practice" as an admissible criterion source. This is the first delivery on the AGENT.md spine and
every later spine delivery's line-number inventory goes stale the moment it lands.

## Scope

- The canonical severity scale as the single definition, in `grading-rubric.md`.
- The six former host files reduced to pointers.
- `aid-reviewer/AGENT.md`: the local severity table removed; the two-sources rule and "no criterion,
  no finding" added.
- `quality-gates.md`'s prose severity definition.

**RE-SCOPED 2026-08-11 (`STATE.md` Q32), and this delivery already closed `Done`/`A+` on the old
scope.** Two bullets above were: *"the canonical two-step severity scale (modality, then blast radius x
reversibility)"*, and *"'severity is your judgment' replaced with severity-as-lookup"*. Both are
retired. **What shipped is therefore now wrong on disk** -- `canonical/agents/aid-reviewer/AGENT.md`
carries the two-step lookup at its `## Severity Classification` section and in three further bullets,
and it is rendered into seven profile trees. Correcting it is **delivery-028**'s, because that
delivery owns the judgment boundary and this one is closed. Recorded here rather than by editing this
delivery's history, so the trail from decision to shipped defect to owner stays readable.

**Out of scope:** `lint-modality.sh` and the modality back-fill (delivery-013); the rubric catalog
(delivery-004).

## Gate Criteria

- [ ] Exactly one severity definition exists; a sweep for rival definition tables returns only
      pointers (AC-1)
- [ ] The six named former host files no longer carry a severity definition
- [ ] `quality-gates.md`'s prose definition is replaced, asserted by a targeted check
- [ ] "established best practice" no longer appears as a criterion source (AC-2)
- [ ] `git diff` on `AGENT.md` touches only this delivery's declared regions
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-004, delivery-013

## Notes

**Spine delivery.** Restate the claimed `AGENT.md` regions as quoted strings before editing -- the
SPEC's line numbers are valid only against the pre-003 base.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The canonical severity scale |
| task-002 | REFACTOR | 2 | Reduce the six former hosts to pointers |
| task-003 | IMPLEMENT | 2 | AGENT.md: severity becomes a lookup |
