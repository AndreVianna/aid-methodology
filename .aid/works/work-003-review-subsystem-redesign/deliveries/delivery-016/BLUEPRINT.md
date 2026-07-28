# Delivery BLUEPRINT -- delivery-016: kb.html content pass

> **Delivery:** delivery-016
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Give the generated knowledge summary an adversarial content review. Its machine suite can prove the
HTML is well-formed and accessible but cannot tell you the content is wrong, and the human checklist
spot-checks only a handful of facts.

## Scope

- A deep-review dispatch over `.aid/knowledge/kb.html` against the `SUMMARY` rule set, replacing the
  5-to-10-fact spot check with a sweep of the whole document.
- The human checklist question retained -- the human confirms or extends the agent's rows and adds
  the visual verdict no agent can produce.
- The class registry recording `SUMMARY` as the one artifact carrying two review kinds.

**Out of scope:** removing the machine validators or the human checklist; this pass is in addition
to them, not instead of them.

## Gate Criteria

- [ ] The content pass is dispatched and is separate from the machine and human gates
- [ ] The class registry states both review kinds for `SUMMARY`
- [ ] A summary asserting a fact the KB contradicts yields a row citing the contradiction rule, with
      the KB as the authority
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-015, delivery-012
- **Blocks:** -- (none)

## Notes

**Spine delivery.** It depends on delivery-004 having authored the `SUMMARY` class file with
content-truth rows; without them this delivery has no rule set and its own review becomes a
criteria gap.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | CONFIGURE | 1 | Wire the content pass |
| task-002 | TEST | 2 | The contradiction fixture |
