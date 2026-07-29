# task-030: The six feature-010-owned state reference bodies

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-007, task-026, task-027, task-029

**Scope:**

- Author the six state reference bodies feature-010 owns, under
  `canonical/skills/aid-graph/references/`:
  `state-preflight.md`, `state-stale-check.md`, `state-validate.md`, `state-visual-gate.md`,
  `state-fix.md`, `state-done.md`.
- These are **agent-executed skill behaviour**, not documentation about behaviour -- the state
  body is what the skill does when it enters the state -- so this task is IMPLEMENT even though
  its medium is prose (`authoring-conventions.md` "Prose Over Scripts").
- Each body carries its `**Advance:**` line exactly as feature-010's State Machines table fixes
  it. Every transition is **CHAIN** or **HALT**; none is `PAUSE-FOR-USER-ACTION` or
  `PAUSE-FOR-USER-DECISION`, per `.claude/aid/templates/state-machine-chaining.md`, whose
  anti-patterns section allows a pause only when the user must do work outside the chat and puts
  a question in an inline `AskUserQuestion`:
  - `state-preflight.md` -- **CHAIN -> ENUMERATE**; aborts the run on failure.
  - `state-stale-check.md` -- **CHAIN -> EXTRACT** on `STALE` / `FIRST_RUN`; **CHAIN -> DONE**
    (idempotent variant) on `CURRENT`.
  - `state-validate.md` -- **CHAIN -> VISUAL-GATE** when Machine Grade >= minimum;
    **CHAIN -> FIX** otherwise.
  - `state-visual-gate.md` -- **CHAIN -> DONE** when `G1` passes and Overall Grade >= minimum;
    **CHAIN -> FIX** otherwise.
  - `state-fix.md` -- **CHAIN -> VALIDATE**.
  - `state-done.md` -- **HALT**.
- Body content, per state:
  - **PREFLIGHT** -- run `graph-preflight.sh` (task-026) before any other state; then **raise the
    KB write fence** with `kb-write-fence.sh --snapshot` (task-028). State that the fence's
    matching `--verify` runs on **every** exit path, including the idempotent one and the failure
    ones, so no route bypasses it.
  - **STALE-CHECK** -- runs *third*, after ENUMERATE, because the `SRC` digest component is
    defined over the enumerated node set. Invoke `graph-stale-check.sh` (task-027), read the last
    stdout line as the verdict, and **tell the user why** it is regenerating by naming which of
    `KB` / `SRC` / `EXT` changed. Record that the script always exits 0 and that there is no
    `CURRENT_UNAPPROVED` branch.
  - **VALIDATE** -- run `grade-graph.sh` (task-029); translate each failed check into a `Pending`
    row of `.aid/.temp/review-pending/graph.md` using the seven-column schema and D4's
    severities, carrying the "no row = no finding" rule verbatim; compute the Machine Grade with
    `bash canonical/aid/scripts/grade.sh --explain`. Record the Playwright-absent degradation:
    `validate-visuals.mjs` SKIPs and exits 0, `V-T` emits no rows, and the closing summary must
    say so, because `G1` then becomes the sole carrier of visual assurance.
  - **VISUAL-GATE** -- **skipped as `N/A` when `graph.html` is not in scope, which is the case
    for the whole of delivery-002.** Write the full body anyway (surface the artifact, ask `G1`
    inline via `AskUserQuestion` requiring the user to have actually opened it in a browser,
    record the answer in the transient `.aid/.temp/graph/visual-gate.json` under allowlist W5,
    recompute Overall as `min(Machine, Human)`, `G1` fail => Human `F` => Overall `F` => FIX) and
    state that the answer is transient by design, so `G1` is re-asked on every regeneration.
  - **FIX** -- split by failure kind, as `canonical/skills/aid-summarize/references/state-fix.md`
    does. Machine-pool rows: read the `Pending` / `Recurred` rows, apply the repair, and **do not
    touch the `Status` column** -- the next VALIDATE re-verifies and the fixer never marks a row
    `Fixed`. `G1` failure: the **expose -> propose -> ask** loop; never guess-fix a judgment.
  - **DONE** -- the two variants. Normal completion prints the artifact paths and grades, prints
    feature-006's routing block, deletes **only** `.aid/.temp/review-pending/graph.md`, retains
    `graph-kb-gaps.md`, and removes the `.aid/.temp/graph/` scratch. Idempotent completion prints
    `relationships.md and graph.html are current for this project. Nothing to do. Re-run with
    --reset to force regeneration.` and writes no file.
- **Delivery-002 ships a nine-state machine** (PREFLIGHT, ENUMERATE, STALE-CHECK, EXTRACT, EMIT,
  VALIDATE, VISUAL-GATE, FIX, DONE). `state-gap-report.md` (delivery-003, task-050) and
  `state-render.md` (delivery-004, task-066) are **out of scope**; write no Advance line pointing
  at either, and write neither file.
- Also out of scope: the three pipeline state bodies ENUMERATE / EXTRACT / EMIT (**task-031**),
  every `SKILL.md` section including the Dispatch table rows (tasks 007 and 008), and the scripts
  themselves (tasks 026, 027, 028, 029).
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] All six files exist under `canonical/skills/aid-graph/references/`:
      `state-preflight.md`, `state-stale-check.md`, `state-validate.md`, `state-visual-gate.md`,
      `state-fix.md`, `state-done.md`. No `state-gap-report.md` and no `state-render.md` is
      created.
- [ ] Each of the six carries exactly one `**Advance:**` line, and each matches feature-010's
      State Machines table: preflight CHAIN -> ENUMERATE; stale-check CHAIN -> EXTRACT on
      `STALE`/`FIRST_RUN` and CHAIN -> DONE on `CURRENT`; validate CHAIN -> VISUAL-GATE or
      CHAIN -> FIX; visual-gate CHAIN -> DONE or CHAIN -> FIX; fix CHAIN -> VALIDATE; done HALT.
- [ ] No body contains `PAUSE-FOR-USER-ACTION` or `PAUSE-FOR-USER-DECISION`; `G1` is asked
      inline via `AskUserQuestion`.
- [ ] No Advance line anywhere names GAP-REPORT or RENDER.
- [ ] `state-preflight.md` names `graph-preflight.sh` and raises the fence with
      `kb-write-fence.sh --snapshot`, and states that `--verify` runs on every exit path.
- [ ] `state-stale-check.md` names `graph-stale-check.sh`, states the three verdicts, states that
      the script always exits 0, requires the changed-component reason to be shown to the user,
      and states that no `CURRENT_UNAPPROVED` branch exists.
- [ ] `state-validate.md` names `grade-graph.sh` and `grade.sh --explain`, carries the seven-column
      ledger target `.aid/.temp/review-pending/graph.md`, carries the "no row = no finding" rule,
      and records the Playwright-absent SKIP consequence for `V-T` and `G1`.
- [ ] `state-visual-gate.md` states that the state is `N/A` when `graph.html` is out of scope,
      records the answer only in `.aid/.temp/graph/visual-gate.json`, computes Overall as
      `min(Machine, Human)`, and states that `G1` is re-asked on every regeneration.
- [ ] `state-fix.md` states that the fixer never writes the `Status` column, and carries the
      expose -> propose -> ask loop for `G1`.
- [ ] `state-done.md` carries both variants, deletes only `.aid/.temp/review-pending/graph.md`,
      retains `graph-kb-gaps.md`, and quotes the idempotent message verbatim.
- [ ] No body instructs a write to any `.aid/knowledge/` path outside the D3 allowlist.
- [ ] No rendered copy is hand-authored under `profiles/`, `.claude/`, `.cursor/`, `.codex/`,
      `.agent/` or `.github/aid/`.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden.** Prose state bodies
      expose no method, and `.aid/knowledge/test-landscape.md` records prompt-driven skill state
      machines as "not machine-tested (by design) -- dogfooding + human/AI review only". The
      testable surface is the scripts these states call, whose suites are **task-040**
      (`test-graph-preflight.sh`), **task-041** (`test-graph-stale-check.sh`), **task-042**
      (`test-graph-read-only.sh`) and **task-043** (validator reuse).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md` and
      `.aid/knowledge/authoring-conventions.md`; the delivery gate reaches this repository's
      resolved `minimum_grade` of **A+** (`review.minimum_grade` in `.aid/settings.yml`), i.e.
      zero ledger rows with Status `Pending` or `Recurred`. REQUIREMENTS.md section 6 holds only
      the six accessibility NFRs and is not a code baseline.
