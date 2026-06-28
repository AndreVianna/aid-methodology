# task-014: In-place engine wiring of the aid-interview spine

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-013

**Scope:**
- Extend the existing `canonical/skills/aid-interview/` spine IN PLACE (C-2 extend-don't-fork) to
  delegate to the engine docs authored in tasks 010-013. No new top-level state; the `SKILL.md` State
  Detection table and dispatch rows stay UNCHANGED. The five spine touch-points (per the feature-002
  SPEC "Files extended in place" table):
  - `references/interview-loop.md` -- its `### Decide what to ask next` step delegates to the
    five-step next-move selector in `elicitation-engine.md`; the one-question-per-turn (`### Rules`)
    and update-after-each-answer (`### Update after each answer`) invariants are retained.
  - `references/interview-strategies.md` -- `## Decide What to Ask Next -- Priority Order` becomes (or
    points at) the gap-precedence ranking; `## Question Design Principles` folds into the move playbook
    + advisor stance; this file POINTS AT the new engine docs by real path.
  - `references/state-continue.md` -- replace the bare opener (`What are we building?...`) with the
    D1 fixed opener CONTENT from `elicitation-engine.md`, and have the CONTINUE loop body delegate to
    the engine. (This task lands the opener CONTENT only; making the emission CONDITIONAL on the TRIAGE
    `## Triage **Opener:**` capture is feature-004's de-dup, task-016 -- do NOT add the conditional
    here.)
  - `references/state-triage.md` -- re-point Step 1's free-form-description prompt at the same D1
    opener (the routing decision stays untouched here; feature-004 / task-015 owns Step 1b + routing).
  - `SKILL.md` -- update the description / state-summary prose to NAME the engine; leave the State
    Detection table and dispatch rows byte-unchanged.
- ASCII-only. Targeted edits only -- no behavior removed from the existing spine; this is a
  generalization, so existing aid-interview behavior is preserved or strictly improved (NFR-2 / AC-10).
- **Out of scope:** the triage gap inventory / Step 1b loop / KB-context detection / `**Opener:**`
  field (task-015); the state-continue.md conditional de-dup (task-016); generator render (task-017).

**Acceptance Criteria:**
- [ ] `interview-loop.md`'s `### Decide what to ask next` delegates to the five-step selector in `elicitation-engine.md`; the one-question-per-turn and update-after-each-answer invariants are retained verbatim. *(D2, gate criterion 3)*
- [ ] `interview-strategies.md` repoints its priority-order + question-design sections at the new engine/playbook/advisor/calibration docs (no contradictory leftover guidance). *(feature-002 Files-extended table)*
- [ ] `state-continue.md`'s bare opener is replaced by the D1 opener content; the CONTINUE loop body delegates to the engine. The opener is left UNCONDITIONAL here (the conditional skip is task-016). *(feature-002 / feature-004 ownership split)*
- [ ] `state-triage.md` Step 1 is re-pointed at the D1 opener; the Steps 2-4 routing computation is left untouched by this task. *(feature-002 scope boundary)*
- [ ] `SKILL.md` description / state-summary names the engine; the State Detection table and dispatch rows are byte-unchanged (verify via diff). *(AC-10 / NFR-2, gate criterion 5)*
- [ ] ASCII-only; skill is prose-executed (no unit test; IMPLEMENT unit-test default overridden). Existing canonical tests still pass at task-018; generator render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
