# task-011: Foundation parity + dispatch round-trip suite

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

**Source:** feature-001-write-infrastructure -> delivery-001

**Depends on:** task-001, task-002, task-003, task-004

**Scope:**
- A test suite proving the foundation: twin byte-parity for the additive `write_enabled` envelope + `resolve_work_dir`, and dispatch/gate round-trips (403 gate, DEFAULT_MAP exit->HTTP, per-op `status_map` hook, WT-1 404). Tests only -- no production code.
- Twin byte-parity: assert `write_enabled` is present and byte-identical in the DM-1 envelope (top level, beside `generated_by`) and the DM-2 `machine` block across `server.py` / `server.mjs`, extending the cross-runtime parity suites `dashboard/server/tests/test_server_py.py` and `dashboard/server/tests/test_server_node.mjs`; the regenerated golden fixtures carry the key identically.
- `resolve_work_dir` parity: assert the Python reader and `reader.mjs` select the SAME directory (newest-`updated` winner; tie -> `branch_label` lexical, `main` first) for a work held in a worktree, and both return `None` -> 404 for an absent `work_id`; include a worktree-isolated fixture (WT-1) and the git-absent (SD-3) path.
- Dispatch round-trips: gate closed -> 403 `read-only`; unknown op -> 400; oversize body -> 400; DEFAULT_MAP exit->HTTP mapping (writer exit 1->404, 4->422, 5->422, 2->409, 3/6->500); a row carrying a `status_map` uses its own map while a row without uses `DEFAULT_MAP` unchanged (OP-SM); a pipeline-scoped op with a `work_id` no worktree holds -> 404 (WT-1); a guard that the server file dispatches via an argv array and contains no in-process fs-write primitive (SEC-3) and no agent/LLM import (SEC-4).

**Acceptance Criteria:**
- [ ] The parity suites assert `write_enabled` is present and byte-identical in the DM-1 envelope and the DM-2 `machine` block across both twins (golden fixtures regenerated) and fail on any divergence (AC4).
- [ ] A `resolve_work_dir` parity test asserts Python and `reader.mjs` pick the same directory (newest-`updated` winner) for a worktree-held work, return `None` -> 404 for an absent `work_id`, and cover the worktree-isolated (WT-1) and git-absent (SD-3) paths.
- [ ] Dispatch round-trip tests cover: gate-closed -> 403 `read-only`; unknown op / oversize body -> 400; DEFAULT_MAP exit->HTTP (1->404, 4->422, 5->422, 2->409, 3/6->500); the `op.status_map or DEFAULT_MAP` hook (a row with an override vs one without); and a WT-1 404 for an unresolvable `work_id`.
- [ ] A guard asserts the server file has no in-process fs-write primitive and dispatches via an argv array (SEC-3 / SEC-4).
- [ ] Tests are deterministic
- [ ] Clean setup/teardown
- [ ] All acceptance criteria from source feature covered
- [ ] All section-6 quality gates pass
