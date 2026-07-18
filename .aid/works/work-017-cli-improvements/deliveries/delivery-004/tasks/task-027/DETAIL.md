# task-027: Delete round-trips + guard coverage

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

**Type:** TEST

**Source:** feature-009-pipeline-delete -> delivery-004

**Depends on:** task-024, task-025, task-026

**Scope:**
- **Objective:** Prove the delete round-trip end to end -- gate, resolution, guards, all three removal topologies, and containment -- and prove it identically on both server twins, without changing any existing fixture bytes. (feature-009 SPEC §Migration "twin byte-parity suites gain op-dispatch cases", §Feature Flow failure table, §How the ACs are satisfied.)
- **Add `pipeline.delete` op-dispatch cases to BOTH twin parity suites** -- `dashboard/server/tests/test_server_node.mjs` and `dashboard/server/tests/test_server_py.py` -- applied IDENTICALLY to the Node and Python twins (twin dispatch parity), asserting byte-parity responses. No existing golden-fixture bytes change; no `schema_version` bump.
- **403 gate:** a read-only server (spawned WITHOUT `--allow-writes`, i.e. `write_enabled = false`) refuses `pipeline.delete` -> 403 `read-only`; correspondingly, the UI hides the Danger zone when `write_enabled = false` (task-026 gating).
- **404 (no worktree):** a `target.work_id` that `resolve_work_dir` resolves to nothing (present in no enumerated worktree root) -> 404 `not-found`, no spawn/removal.
- **409 guards:** (a) a pipeline whose STATE.md frontmatter `lifecycle == Running` -> 409 `pipeline-active`; (b) the current worktree as the target -> 409 `pipeline-active`; NEITHER removes anything.
- **200 happy across all three removal topologies** (classified by content, per task-024): **main-folder** -- work under the main worktree's `.aid/works/`; delete does `rm -rf` of the folder only, the main worktree survives. **dedicated-worktree** -- work is the sole `.aid/works/` entry of a non-main worktree; delete does `git worktree remove --force`, removing folder + worktree together. **shared-worktree** -- a non-main worktree that also hosts other works; delete does `rm -rf` of the folder only, sibling works retained.
- **Containment rejection:** a symlinked / `..`-escaping work folder whose realpath is not a child of `$W/.aid/works/` -> 500 `write-failed`, no removal.
- **Post-delete truthfulness assertions:** after a 200, the pipeline is absent from a fresh `/r/<id>/api/model` read (AC2); the git branch still exists (OQ-PL3); and for a `work_id` shadowed across worktrees, only the reconciled winner is removed while the other copy remains (WT-1 symmetry / AC2 edge case).
- **Note on execution environment:** these are twin-parity server-dispatch tests; run them the way the existing `test_server_node.mjs` / `test_server_py.py` suites run in CI. Do not add port-binding live-server or full-bash-suite steps that hang on Windows -- assert dispatch behaviour at the twin-suite layer as the existing op cases do.

**Acceptance Criteria:**
- [ ] Both twin parity suites (`test_server_node.mjs`, `test_server_py.py`) gain `pipeline.delete` dispatch cases applied identically to Node + Python, asserting byte-parity responses. (AC4)
- [ ] 403 gate case: a read-only (`write_enabled = false`) server refuses `pipeline.delete` with 403 `read-only`. (AC8)
- [ ] 404 case: a `work_id` resolving to no worktree root returns 404 `not-found` with no spawn. (WT-1)
- [ ] 409 guard cases: (a) `lifecycle == Running` -> 409 `pipeline-active`; (b) current-worktree target -> 409 `pipeline-active`; neither removes anything. (Guards)
- [ ] 200 happy cases cover all three topologies: main-folder (folder-only `rm -rf`), dedicated-worktree (`git worktree remove --force`), shared-worktree (folder-only, sibling works retained). (AC-PD1, AC7)
- [ ] Containment rejection case: a symlinked / `..`-escaping work folder returns 500 `write-failed` with no removal. (Security)
- [ ] Post-delete: the pipeline is absent from a fresh `/r/<id>/api/model` (AC2); the git branch still exists (OQ-PL3); a `work_id` shadowed in another worktree keeps its non-winner copy (only the winner removed).
- [ ] No existing fixture bytes change and no `schema_version` bump. (AC4)
- [ ] Tests are deterministic
- [ ] Clean setup/teardown
- [ ] All acceptance criteria from source feature covered
- [ ] All section-6 quality gates pass
