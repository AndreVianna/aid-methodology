# task-009: Make task-state updates emphatic + unmissable in the execution flow

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-004

**Scope:**
- **The gap (user-diagnosed, root cause):** the mechanism to write task state exists
  (`writeback-state.sh --field State`; the flattened `--field` path updates the
  `### Tasks lifecycle` table; both reader twins read it; the dashboard renders it) — but the
  **execution instructions do not clearly and emphatically require the executing agent to update
  the task's state AS IT CHANGES.** The `In Progress` / `In Review` state-writes are buried mid-list
  in `aid-execute/references/state-execute.md` (steps 177/528/564), easy to skip, and the
  sub-agent EXECUTE dispatch does not carry an explicit, mandatory "write the state now" instruction.
  Result: a task sits at `Pending` in the dashboard for its entire execution, then jumps to `Done`.
- **Fix — make the instruction impossible to miss (canonical edits, then re-render):**
  - `canonical/skills/aid-execute/SKILL.md` + `references/state-execute.md` (+ `state-fix.md`,
    `state-review.md`, `state-execute-drilldown.md` as needed): elevate the state-transition writes
    from buried numbered steps to an **explicit, emphatic, unmissable mandate** — a task's state
    MUST be written the moment it changes: `In Progress` at EXECUTE-start (before any work),
    `In Review` at EXECUTE-complete (before dispatching the reviewer), `Done`/`Failed`/`Blocked` at
    terminal. State the WHY (the dashboard reflects live progress from this state; an unwritten
    transition = an invisible/misleading task). Cover BOTH layouts (full per-task STATE.md and
    flattened `### Tasks lifecycle` table) and BOTH single-task and pool dispatch.
  - The mandate binds **whoever executes the task — the main/orchestrator agent driving it
    DIRECTLY, or a dispatched sub-agent — with NO exception.** The instruction must state that an
    agent MUST NOT bypass the per-transition state write, even when orchestrating a task itself
    rather than delegating it. Make the EXECUTE dispatch brief carry this, AND make the
    orchestrator step that dispatches (or self-executes) carry it.
  - Reinforce the global IMPERATIVE tracking rule in CLAUDE.md/AGENTS.md so it explicitly names the
    per-transition writes (`In Progress` at start, `In Review` at execute-complete, terminal at end)
    and states that no agent — including the main orchestrator executing directly — may bypass them
    (do NOT cite a context-file by line from a KB doc — per convention).
- **Validate-first:** confirm the flattened `--field` write path + both reader twins already
  surface each transition end-to-end (they do, per task-004/002); if any transition is genuinely
  unwired for the flattened/pool path, fix the writer/reference too.
- **Durable guard (regression test):** add a `tests/canonical/` test driving a scratch flattened
  task row `Pending -> In Progress -> In Review -> Done` via `writeback-state.sh --field State`,
  asserting after each write that the `### Tasks lifecycle` table AND both reader twins reflect the
  new state — so live task-state visibility cannot silently regress.
- **Render:** if canonical edited, run `run_generator.py`, resync dogfood `.claude/`, byte-identity
  deferred to CI (hangs locally).

**Acceptance Criteria:**
- [ ] `aid-execute` SKILL.md + execute references carry an explicit, emphatic, unmissable mandate to write the task state at EACH transition (`In Progress` at start, `In Review` at execute-complete, terminal at end), covering both full and flattened layouts and single + pool dispatch — verified by reading the rendered instructions (traces to BLUEPRINT gate criteria #15).
- [ ] The mandate explicitly binds the executing agent WHOEVER it is — the main/orchestrator agent executing a task directly AND a dispatched sub-agent — stating no agent may bypass the per-transition writes; the EXECUTE dispatch brief and the orchestrator/self-execute step both require the `In Progress`/`In Review` writes, not only the terminal write (traces to gate criteria #15).
- [ ] A `tests/canonical/` regression test drives a flattened task row `Pending -> In Progress -> In Review -> Done` and asserts the table + both reader twins reflect each transition (traces to gate criteria #15).
- [ ] Consistent with the global IMPERATIVE tracking rule; no KB->context-file line citation introduced.
- [ ] If canonical was edited: `run_generator.py` re-rendered; dogfood resynced (byte-identity deferred to CI).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
