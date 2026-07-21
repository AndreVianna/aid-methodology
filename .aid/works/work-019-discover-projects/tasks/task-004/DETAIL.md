# task-004: Help text, user docs, and release-tracking entry

[!NOTE]
This is the TASK-LEVEL DETAIL.md — the IMMUTABLE DEFINITION for this task in a flattened (Lite)
work. Written once; not a state file. This flattened work has NO per-task `STATE.md`; each task's
mutable cells live in the work-root `STATE.md § ## Delivery Lifecycle → ### Tasks lifecycle`.

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

**Type:** DOCUMENT

**Source:** work-019-discover-projects -> delivery-001

**Depends on:** task-003

**Scope:**
- Verify and, if needed, polish the `aid projects -h` help text in BOTH twins (`_aid_usage projects`
  in `bin/aid`; `Show-AidUsage 'projects'` in `bin/aid.ps1`) so it documents the scan action, every
  flag (`--dry-run`, `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`,
  `--verbose`), and the default whole-machine scope — with byte-identical user-visible text across
  twins.
- Update any user-facing CLI documentation that lists the `projects` subcommands (e.g. the repo
  README / CLI reference) to include the new action alongside `list`/`add`/`remove`.
- Add a `[NEW]` entry to `.aid/knowledge/release-tracking.md` `## Unreleased` describing the new
  subcommand (register-only machine scan; whole-machine default; `<root>`/`--dry-run`/guardrail
  flags).
- Apply the final subcommand name confirmed at the approval gate as a find/replace across the
  command string, dispatch cases, usage lines, docs, and test identifiers if it differs from the
  working name `aid projects scan`.

**Acceptance Criteria:**
- [ ] `aid projects -h` documents the scan action, its flags, and its default whole-machine scope in
  both twins, with byte-identical user-visible help text (AC-12, FR-10).
- [ ] Every user-facing CLI doc that enumerates the `projects` subcommands lists the new action.
- [ ] `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[NEW]` entry for the subcommand.
- [ ] The documented subcommand name matches the shipped name (approval-gate-confirmed) across help
  text, docs, and tests.
- [ ] All section-6 quality gates pass.
