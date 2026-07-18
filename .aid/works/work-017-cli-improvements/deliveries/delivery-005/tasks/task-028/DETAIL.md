# task-028: write-control-signal.sh stop-signal writer + gitignore

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Type:** IMPLEMENT

**Source:** feature-008-execution-control -> delivery-005

**Depends on:** task-002 (delivery-001)

**Scope:**
- New bash-only writer `.claude/aid/scripts/execute/write-control-signal.sh`, co-vendored with the
  dashboard unit and self-located from `$AID_CODE_HOME`. Signature (SPEC §API Contracts
  "`write-control-signal.sh` contract"):
  `write-control-signal.sh --task-id <NNN> --action <stop|resume> [env AID_WORK_DIR=<abs work dir>]`.
- Target work dir = `AID_WORK_DIR` if set, else `<cwd>`. The server sets `AID_WORK_DIR` to
  feature-001's `resolve_work_dir` output (worktree-aware, WT-1 -- NEVER a reconstructed
  `<served-root>/.aid/works/<work_id>` path). Derive the control dir RELATIVE to that work dir as
  `<work_dir>/../../.control/<work_id>` (i.e. the `.aid/.control/<work_id>/` sibling of the work
  dir's own `.aid/works/`), where `<work_id>` is the work dir's basename -- so the signal lands in
  the SAME worktree tree the executor polls.
- Validate `--task-id` against `^[0-9]{1,3}$` (exit 4 on failure); normalize to
  `task-<zero-padded-3>` matching `writeback-state.sh`'s own padding. Build the filename from the
  normalized `task-<NNN>` token only -- no client string reaches a path segment (traversal
  impossible, SEC-3/§Security Specs).
- `--action stop`: `mkdir -p` the control dir; atomically create (temp-file + `mv`)
  `.aid/.control/<work_id>/task-<NNN>.stop` containing one informational line
  `[<ISO-8601 UTC>] stop | source=dashboard` (presence is the signal; contents advisory).
  Idempotent (re-stop is a no-op success).
- `--action resume`: `rm -f` that file. Idempotent (removing an absent file is success, exit 0).
- Never touches `STATE.md`, the work folder's tracked contents, git, or any worktree.
- Exit codes reuse the writeback alphabet: `0` ok; `2` IO/lock-class failure; `4` invalid arg value;
  `5` missing required arg.
- Co-vendor via a one-line edit to `dashboard/MANIFEST` (the single-source vendor mechanism
  feature-001 established; `vendor.js`/`vendor.py`/`install.sh`/`install.ps1`/`release.sh` all derive
  from it, drift guarded by `tests/canonical/test-dashboard-manifest.sh`).
- Add `.aid/.control/` to the `.gitignore` "AID managed" block
  (delimited `# >>> AID managed ... >>>` / `# <<< AID managed <<<`) alongside the existing
  `.aid/.heartbeat/` entry (SPEC §Security Specs "Gitignore requirement", §Migration).

**Acceptance Criteria:**
- [ ] `write-control-signal.sh` exists at `.claude/aid/scripts/execute/write-control-signal.sh`,
      is `bash`-only, and self-locates from `$AID_CODE_HOME`.
- [ ] `--action stop` creates `<AID_WORK_DIR>/../../.control/<work_id>/task-<NNN>.stop` atomically
      (temp-file + `mv`) with the `[<ISO-8601 UTC>] stop | source=dashboard` line; a second `stop`
      is a no-op success (idempotent).
- [ ] `--action resume` removes that file; resuming when the file is absent exits `0` (idempotent).
- [ ] `--task-id` outside `^[0-9]{1,3}$` exits `4`; a missing required arg exits `5`; an IO/lock-class
      failure exits `2`; success exits `0`. `--task-id` is normalized to `task-<zero-padded-3>`.
- [ ] The control dir derives relative to `AID_WORK_DIR` (basename = `<work_id>`), NOT a
      reconstructed served-tree path (WT-1); no client-supplied string reaches a path segment.
- [ ] The writer never reads or writes `STATE.md` and never touches git, tracked work-folder
      contents, or any worktree (SEC-3).
- [ ] `dashboard/MANIFEST` lists `write-control-signal.sh`; `tests/canonical/test-dashboard-manifest.sh`
      passes (no vendor drift).
- [ ] `.aid/.control/` is added to the `.gitignore` "AID managed" block next to `.aid/.heartbeat/`.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
