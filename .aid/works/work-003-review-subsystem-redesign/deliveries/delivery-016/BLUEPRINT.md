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

### Inherited defect — one known-false statement already measured

`kb.html:3408` reads *"Configured in `.aid/settings.yml` under `pipeline.minimum_grade`. The AID
dogfood repository requires A+ for all KB documents."* Both halves are false as of 2026-08-07: the
key is the flat `minimum_grade`, not `pipeline.minimum_grade`, and the value is `B-`. Found as the
EXTENT of delivery-015 gate cycle 12 row 1, whose other two sites (`quality-gates.md`,
`pipeline-contracts.md`) were fixed there. **Deliberately not hand-edited**: `kb.html` is generated,
so correcting the render rather than regenerating it is the F2 defect — and this delivery is the
declared owner of its content. It is a worked example of exactly what this delivery exists to catch:
a machine suite proving the HTML is well-formed over a sentence that is simply untrue. The content
pass must produce a row for it.

## Gate Criteria

- [ ] The content pass is dispatched and is separate from the machine and human gates
- [ ] The class registry states both review kinds for `SUMMARY`
- [ ] A summary asserting a fact the KB contradicts yields a row citing the contradiction rule, with
      the KB as the authority
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-004, delivery-012, delivery-015
- **Blocks:** delivery-022

## Notes

**Spine delivery.** It depends on delivery-004 having authored the `SUMMARY` class file with
content-truth rows; without them this delivery has no rule set and its own review becomes a
criteria gap. That dependency is now **stated directly** in `## Dependencies`, matching how every
other delivery that needs delivery-004's output declares it -- 005, 014, 015, 017 and 019 all name
004 explicitly even where a transitive path exists. The graph is **not** transitively reduced, so
leaving 004 implicit here would have made this the only delivery whose stated need had no edge.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | CONFIGURE | 1 | Wire the content pass |
| task-002 | TEST | 2 | The contradiction fixture |
