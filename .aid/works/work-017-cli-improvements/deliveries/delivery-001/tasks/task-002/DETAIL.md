# task-002: Worktree-aware resolve_work_dir resolver (WT-1)

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

**Source:** feature-001-write-infrastructure -> delivery-001

**Depends on:** task-001

**Scope:**
- Add the single reader-layer function that maps a `work_id` to the REAL on-disk work directory (worktree-aware), reusing the reader's own enumeration + reconcile-winner logic so a write hits exactly the copy the reader rendered (invariant WT-1). This task adds the resolver only; the op wiring that consumes it is task-004.
- New `resolve_work_dir(served_root, work_id) -> Path | None` in the Python reader package + its `dashboard/server/reader.mjs` twin, with identical behavior.
- Reuse `enumerate_worktree_roots` (`locator.py` line 126 -- `git worktree list --porcelain`, main worktree first) to walk the served repo's git worktrees; select the copies whose `<wt>/.aid/works/<work_id>` exists.
- Apply the SAME winner rule as `_reconcile_same_work` step 2 (`reader.py` line 131 -- newest `updated`; tie -> `branch_label` lexical, `main` first) so the returned directory is the very copy the reader rendered.
- Return `None` (caller maps to 404) when no worktree of the served repo holds the `work_id`; inherit the reader's SD-3 degradation (git absent / non-git -> main-root-only) so the resolver can only ever target a work the reader itself surfaced.
- Live in the reader layer (single source of truth for "where does a `work_id` live"), imported by the server alongside `read_repo` / `read_repo_detail`; applied identically to both reader twins (byte-parity discipline, AC4).

**Acceptance Criteria:**
- [ ] `resolve_work_dir(served_root, work_id)` returns the directory `_reconcile_same_work` would pick (newest `updated`; tie -> `branch_label` lexical, `main` first) when at least one worktree holds the `work_id`.
- [ ] It returns `None` for a `work_id` no worktree of the served repo holds.
- [ ] A worktree-isolated pipeline under `.claude/worktrees/<wt>/.aid/works/<work_id>/` resolves to its worktree copy -- never a reconstructed `<served-root>/.aid/works/<work_id>` path (WT-1).
- [ ] A git-absent / non-git served root degrades to main-root-only (SD-3), matching the reader.
- [ ] The function is added to the Python reader and `reader.mjs` identically (byte-parity discipline; AC4).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
