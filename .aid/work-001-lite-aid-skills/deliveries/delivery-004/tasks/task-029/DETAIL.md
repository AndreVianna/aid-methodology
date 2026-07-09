# task-029: aid-describe full-path-only rewire

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-027

**Scope:**
- Rewire `canonical/skills/aid-describe/SKILL.md`: frontmatter `State machine:` -> `FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> /aid-define]` (drop TRIAGE + the lite branch); `## Agents Involved` (remove TRIAGE/L1-L4 rows + the covers-paragraph); `## Workspace` (delete the lite-path block); `## State Detection` (delete State T + L1-L4, the Path reads, the escalated branch, the pre-TRIAGE exception; collapse to FIRST-RUN/Q-AND-A/CONTINUE/DESCRIBE-SEED/COMPLETION); all "you are here" maps; `## Dispatch` (remove TRIAGE/lite rows; rewire FIRST-RUN Advance -> CONTINUE and Q-AND-A Advance -> CONTINUE); delete the `## Scripts` section (parse-recipe.sh/test rows).
- Rewire the 7 reference files (preserve engine, strip triage/lite wiring): `state-first-run.md`, `state-q-and-a.md`, `state-continue.md` (promote the "NEITHER signal" branch to primary entry emitting the D1 opener), `state-describe-seed.md`, `elicitation-engine.md`, `move-playbook.md`, `calibration.md`. Leave the 6 preserve-clean files untouched.
- C-3: preserve the elicitation engine intact (D1 opener text + five-step selector unchanged; only the opener's invocation site moves TRIAGE -> CONTINUE).
- Do NOT delete the 7 lite/triage reference files (feature-002/task-030 owns deletion, same wave).

**Acceptance Criteria:**
- [ ] `/aid-describe` runs full-path only: `State machine:` line has no TRIAGE/CONDENSED-INTAKE/LITE- token; FIRST-RUN + Q-AND-A both advance to CONTINUE; no lite branch, no triage prompt (AC-14/FR-12).
- [ ] Dispatch/State-Detection/Scripts pointers to the 7 deleted refs + `parse-recipe.sh` removed.
- [ ] Elicitation engine preserved intact (D1 opener + five-step selector byte-unchanged; opener relocated to CONTINUE) (C-3).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
