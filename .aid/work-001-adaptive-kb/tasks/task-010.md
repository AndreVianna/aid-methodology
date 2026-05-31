# task-010: Propose→confirm flow (Step 0d) insertion

**Type:** IMPLEMENT

**Source:** feature-004-declared-doc-set → delivery-002 (DERIVATION wave)

**Depends on:** task-008

**Scope:**
- Insert **Step 0d — Propose & Confirm Doc-Set** into `canonical/skills/aid-discover/references/state-generate.md` between Step 0c and Step 1:
  - Read `project-index.md` (a file inventory, NOT a project-type label) → the LLM infers a proposed doc-set (default seed + deltas; heuristics live in the SKILL prose; NO archetype classifier / seed-files / fixtures).
  - Present the proposal as a diff vs the default seed; this is a **PAUSE-FOR-USER-DECISION** per `state-machine-chaining.md` (the user-confirm step is the heuristic's safety net).
  - On confirm, write/update `discovery.doc_set` in `.aid/settings.yml` (or write nothing if the default is accepted); idempotent re-entry shows the existing set for re-confirm.
  - Continue to Step 1 with the confirmed set driving the data-driven dispatch (from task-008).
- Re-render with `python run_generator.py`.

**Acceptance Criteria:**
- [ ] Step 0d derives the proposal from `project-index.md` (default + deltas), never a static pick-list; no archetype classifier/seed-files/fixtures introduced.
- [ ] The confirm step is a genuine PAUSE-FOR-USER-DECISION; accepting the default writes nothing; idempotent re-entry shows the existing set.
- [ ] The confirmed set flows into the task-008 data-driven dispatch (Step 1).
- [ ] All §6 quality gates pass (render-drift clean, 13 suites green, generator self-tests).
