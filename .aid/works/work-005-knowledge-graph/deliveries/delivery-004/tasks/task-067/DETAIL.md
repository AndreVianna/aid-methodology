# task-067: SKILL.md RENDER dispatch row and state-map node

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-007, task-051, task-066

**Scope:**
- Edit `canonical/skills/aid-graph/SKILL.md` in exactly two places: add the **RENDER** row to the
  Dispatch table (state → `references/state-render.md` → its Advance), and add the `[ RENDER ]`
  node to the state-map diagram between `[ GAP-REPORT ]` and `[ VALIDATE ]`.
- This is the one edit that turns the machine shipped in delivery-002 (**nine** states) and extended
  in delivery-003 (+GAP-REPORT, **ten**) into the **eleven**-state machine feature-010's State
  Machines section specifies. *(Owner correction 2026-07-28: the task table's row said "nine into
  ten", which double-counted GAP-REPORT — task-051 already took it to ten.)*
- Reconcile any state-count statement in the file to **eleven**.
- **Re-point two Advance lines so the sequence closes** *(owner correction 2026-07-28).* Task-051
  necessarily left `GAP-REPORT` advancing to `VALIDATE`, because RENDER did not exist at that
  delivery boundary. This task therefore sets `GAP-REPORT`'s Advance to **`CHAIN → RENDER`** and gives
  RENDER **`CHAIN → VALIDATE`**, producing the order feature-010's table describes. The machine must
  be runnable at the end of every delivery, so neither re-point could have happened earlier.
- **Also append delivery-004's new files to `## References`.** Task-008 authors that section in
  delivery-002 for delivery-002's files only, and task-051 appends delivery-003's; without this the
  shipped skill's reference list omits the `knowledge-graph/` template set and `state-render.md`.
  Narrow, deliberate exception to the feature-010 ÷ feature-012 named-section seam, matching task-051.
- **Out of scope:** every other part of `SKILL.md` -- the frontmatter, Pre-flight, Arguments,
  State Detection, the other dispatch rows, Quality Gate and Failure modes (task-007), the
  `## References` entries belonging to earlier deliveries (tasks 008 and 051), and the GAP-REPORT
  row itself (task-051); the state body
  (task-066). `SKILL.md` is a shared file: this task edits only its own two lines.

**Acceptance Criteria:**
- [ ] Exactly one row is added to the Dispatch table: `RENDER` → `references/state-render.md`,
      with the Advance `CHAIN → VALIDATE`, matching feature-010's State Machines table and
      task-066's Advance line character for character.
- [ ] The state-map diagram gains `[ RENDER ]` in the position feature-010's diagram shows --
      after `[ GAP-REPORT ]`, before `[ VALIDATE ]` -- and the diagram now reads as the
      **eleven**-state machine.
- [ ] Every state-count statement in `SKILL.md` reads **eleven**, with no stale "nine" or "ten" left
      behind. *(Nine states shipped in delivery-002; task-051 took it to ten by adding GAP-REPORT;
      this task adds RENDER, making eleven.)*
- [ ] **`GAP-REPORT`'s Advance is re-pointed from `CHAIN → VALIDATE` to `CHAIN → RENDER`.** Task-051
      necessarily left it on VALIDATE because RENDER did not exist at the delivery-003 boundary, and
      this is the task that closes the sequence feature-010's table describes.
- [ ] **`## References` gains delivery-004's entries** — the `knowledge-graph/` template set and
      `references/state-render.md` — so the shipped skill's reference list is complete. Entries
      belonging to earlier deliveries (tasks 008 and 051) are left untouched.
- [ ] The diff touches no line authored by task-007 or task-008, and touches task-051's lines **only**
      to re-point `GAP-REPORT`'s Advance: `git diff -- canonical/skills/aid-graph/SKILL.md` shows the
      RENDER dispatch row, the diagram node, the GAP-REPORT Advance re-point, this delivery's
      `## References` entries, and the count reconciliation.
- [ ] Every transition in the file remains CHAIN or HALT -- no `PAUSE-FOR-USER-ACTION` and no
      `PAUSE-FOR-USER-DECISION` is introduced
      (`.claude/aid/templates/state-machine-chaining.md`).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the shipped
      registration of this file across all five trees is asserted by
      `tests/canonical/test-graph-skill-registration.sh` (task-091, delivery-006). *(Stated
      override of the IMPLEMENT default "unit tests for all new public methods": skill prose has
      no unit-test vehicle.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
