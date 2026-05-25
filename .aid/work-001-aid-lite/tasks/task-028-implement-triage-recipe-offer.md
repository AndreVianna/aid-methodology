# task-028: Implement triage recipe-offer step + slot-fill + emit (incl. `{!{` → `{{` rewrite)

**Type:** IMPLEMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** task-015, task-024, task-026, task-027

**Scope:**
- In aid-interview's State TRIAGE, insert a new sub-step **after** Sub-path is accepted (or overridden) and **before** the sub-path's condensed interview begins.
- Filter recipes from rendered `recipes/` directory: `recipe.applies-to == workType OR recipe.applies-to == '*'`.
- If at least one recipe matches, prompt user with the filtered list + the option to decline.
- On accept: run slot-fill loop (one prompt per unique slot, in order; multi-line answers terminated by empty line; empty answers rejected).
- Emit work-root `SPEC.md` + tasks/task-NNN.md files with slot substitution.
- Final emit-time rewrite: replace any remaining `{!{` token in body with literal `{{` (realizes the escape contract).
- Initialize work-area `STATE.md` with `## Tasks Status` table populated from task list + `## Triage` block extended with `Recipe: <recipe-name>` line.
- On decline: control returns to feature-005's sub-path condensed interview.

**Acceptance Criteria:**
- [ ] Recipe-offer step fires only when `path = lite` AND at least one recipe matches `workType`.
- [ ] Slot-fill loop accepts multi-line answers (terminated by empty line + Enter).
- [ ] Empty slot answers rejected; user must supply value or escalate.
- [ ] Emitted work-root `SPEC.md` contains slot-substituted content; no `{{slot-name}}` tokens remain (except literal `{!{` → `{{` from escape).
- [ ] Emitted tasks/task-NNN.md files match the 6-section flat shape per work-003 FR2 area-STATE rule.
- [ ] `## Triage` block contains `Recipe: <name>` line.
- [ ] On decline, control flows to feature-005 State L1 without state corruption.
- [ ] Unit tests for slot-fill + emit + escape-rewrite.
- [ ] All §6 quality gates pass.
