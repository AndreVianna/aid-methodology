# task-008: Add the format-4 state conversion step to the repo migration engine

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-008/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** MIGRATE

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-007

**Scope:**
- Append a state-format conversion step to the existing per-repo format migration engine --
  `_aid_migrate_repo` in `bin/aid` (`:2017+`) and its PowerShell twin in `bin/aid.ps1` /
  `lib/AidInstallCore.psm1` -- rather than adding a standalone hand-run script
  (`SPEC.md § L-6`: a standalone converter has no automated caller; `migrate-work-hierarchy.sh` is
  referenced by nothing in `canonical/`, `bin/`, `lib/` or `packages/`).
- Per repo, for every `.aid/works/*/STATE.md` and, on the full layout, every
  `deliveries/*/STATE.md` and `deliveries/*/tasks/*/STATE.md`: emit `STATE.yml` preserving every
  scalar, every table row and every Q&A entry per the `SPEC.md § D-2` zone mapping and the
  `§ D-4` target shapes; verify the result parses and round-trips; only then delete the `.md`.
- DERIVED sections are dropped, not translated -- with a guard: a DERIVED section holding a real
  (non-placeholder) row is a **hard error** naming the file and the section, not a silent drop, and
  the remedy the message names is running the hierarchy migration first (SP-3).
- Idempotent: a work with a `STATE.yml` and no `STATE.md` is a no-op; a second run changes nothing.
- WARN-not-fail per the engine's contract (`_aid_migrate_repo` runs ordered steps and always
  returns 0), with the one exception above surfacing as a named WARN carrying the file and section.
- Fail-safe and rollback (`task-type-rules.md § MIGRATE`): the `.md` is deleted only after the
  `.yml` parses and round-trips, so an aborted or failed per-file conversion is a no-op that leaves
  the original in place. A reverse (yml -> md) converter is deliberately NOT written -- it would be
  the dual-format window `SPEC.md § L-6` rejects; the documented rollback is therefore
  restore-from-VCS (or the untouched `.md` for a failed file) plus the format stamp, recorded as a
  runbook note in the step's header comment.
- Document, in the step's header comment and in `migrate-work-hierarchy.{sh,ps1}`'s header, the
  ordering rule: **hierarchy migration first, format conversion second** --
  `migrate-work-hierarchy.{sh,ps1}` stays markdown-in / markdown-out and feeds this step
  (`SPEC.md § L-6`). Neither migrate script's conversion logic changes.
- OUT of this task: the `AID_SUPPORTED_FORMAT` bump (task-009); converting this repository's own
  live works (task-010); the migrate suites (task-015); `test-migrate-hierarchy.sh` and
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/`, both triaged OUT of the
  change-set and to be left untouched.

**Acceptance Criteria:**
- [ ] Against a fixture repository carrying legacy-format works in BOTH layouts, the step replaces
      every in-scope `STATE.md` with a `STATE.yml` preserving every scalar, every table row and
      every Q&A entry; the `.md` is gone (SP-12).
- [ ] Running the step a second time changes nothing -- no file content, no mtime-only rewrite,
      exit unchanged (SP-12, `task-type-rules.md § MIGRATE` idempotence).
- [ ] The converted output carries no key for Features State, Plan/Deliveries, Tasks State,
      Delivery Gates, Calibration Log or Dispatches, and `qa` is emitted only where it is AUTHORED
      (SP-3).
- [ ] A legacy file whose DERIVED section holds a real, non-placeholder row produces a named
      failure identifying the file AND the section and drops no data; the message names running the
      hierarchy migration first (SP-3).
- [ ] Data integrity is verified before/after per file: the scalar count, the row count per former
      table and the Q&A entry count match, and the emitted file parses under the D-3 subset with no
      `parse_warning` from either reader twin (SP-12).
- [ ] A conversion that fails verification leaves the original `.md` in place and untouched, and
      the run continues WARN-not-fail with the engine still returning 0 (SP-12).
- [ ] The Bash step and the PowerShell twin produce identical results on identical input,
      byte-for-byte on the emitted `.yml` (SP-12, C-4).
- [ ] The rollback procedure and the "hierarchy migration first, format conversion second" ordering
      are documented in the step's header comment and in both `migrate-work-hierarchy` script
      headers; neither script's conversion logic is otherwise changed.
- [ ] `tests/canonical/test-migrate-hierarchy.sh` and
      `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/` are byte-unchanged
      (`SPEC.md § L-6` triage).
- [ ] All section-6 quality gates pass.
