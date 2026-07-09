# task-032: aid-describe full-only + engine-preserved test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-029, task-030

**Scope:**
- Full-only assertion: `aid-describe/SKILL.md` frontmatter `State machine:` has no TRIAGE/CONDENSED-INTAKE/LITE- token; the `## Dispatch` table has no row whose Detail path resolves to any of the 7 deleted reference files; a scripted read of the state-detection prose confirms FIRST-RUN + Q-AND-A both advance to CONTINUE.
- Engine-preserved assertion (C-3): all 13 surviving reference files exist (6 untouched + 7 rewired; 20 - 7 deleted); the D1 opener text + the five-step selector in `elicitation-engine.md` are unchanged; a fixture run of the full-path interview emits the D1 opener at CONTINUE and completes FIRST-RUN -> Q-AND-A -> CONTINUE -> [DESCRIBE-SEED] -> COMPLETION.

**Acceptance Criteria:**
- [ ] Full-only: no TRIAGE/LITE token in the State machine line; no dispatch row to a deleted ref; FIRST-RUN + Q-AND-A -> CONTINUE (AC-14).
- [ ] Engine-preserved: 13 surviving refs exist; D1 opener + five-step selector byte-unchanged; fixture emits D1 at CONTINUE (C-3).
- [ ] Test is deterministic with clean setup/teardown; covers feature-013 ACs.
- [ ] All §6 quality gates pass.
