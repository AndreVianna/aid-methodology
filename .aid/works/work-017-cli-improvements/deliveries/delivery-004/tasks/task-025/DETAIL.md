# task-025: pipeline.delete op row + exit-7->409 map

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

**Source:** feature-009-pipeline-delete -> delivery-004

**Depends on:** task-024, task-004 (delivery-001)

**Scope:**
- **Objective:** Wire the `delete-pipeline.sh` writer (task-024) into feature-001's dispatch table so a `POST /r/<id>/api/op` with `op:"pipeline.delete"` spawns it and its guard exit maps to the right HTTP status -- all on both server twins, with no reader change. (feature-009 SPEC §Layers component 1, §API Contracts.)
- **Append the `pipeline.delete` `OP_TABLE` row** to BOTH byte-parity server twins -- `dashboard/server/server.py` and `dashboard/server/server.mjs` -- with an IDENTICAL row: `op = pipeline.delete`; scope = per-repo; writer + argv = `delete-pipeline.sh --work-id <work_id>` with env `AID_REPO_ROOT=<server-resolved repo root>`; arg-schema = `args` MUST be absent/empty. NO op-schema flag is added (the earlier-draft `cross_worktree` flag is gone -- feature-001's step-6 `resolve_work_dir`/WT-1 already resolves this op's target worktree-aware, exactly like `pipeline.finish`/`pipeline.rename`). This replaces the feature-001 seed placeholder row (`pipeline.delete ... see owning features ... FR-PL3 ... feature-009`).
- **Add the exit-7 -> HTTP 409 status-map row** via feature-001's OPTIONAL per-op `status_map` field (OP-SM; dispatcher resolves `op.status_map or DEFAULT_MAP`): the `pipeline.delete` row carries a `status_map` that maps writer **exit 7 -> HTTP 409 `pipeline-active`** while preserving every `DEFAULT_MAP` row (1 -> 404 `not-found`, 2 -> 409 `busy`, 3 -> 500 `write-failed`, 4/5 -> 422 `invalid-value`). This is the one row feature-009 adds to the map; no other status changes, no change to the STATE-op default.
- **Server-side validation before spawn** (§Feature Flow steps 6-7, both twins), in the SPEC's Feature Flow order: **(step 6)** validate `target.work_id` against `^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$`, length <= 64, INLINE before spawn -- a failing value -> **422 `invalid-value`**; a structurally malformed or absent `target` -> the separate **400 `bad-request`**; then call `resolve_work_dir(repo, work_id)` (WT-1), a `None` result -> **404 `not-found`**. **(step 7)** Reject a non-empty `args` as an arg-schema violation -> **422 `invalid-value`** (per feature-001 step 7, not 400). Only after all these pass does the dispatcher build the argv array and spawn the child (`delete-pipeline.sh` re-validates as a defense-in-depth backstop via its exit 4/5).
- **No path from the body:** the repo root is resolved verbatim from `id_map` (`id_map.get(rid)` -- `server.py` line 1004 / `idMap.get` -- `server.mjs` line 768; SEC-2); the writer receives ONLY the validated `work_id` + the server-resolved `AID_REPO_ROOT`, passed as an argv ARRAY (never `shell=True`, never a concatenated string; SEC-3).
- **No reader/parser change; no new endpoint** (rides feature-001's `_serve_op` on the existing POST route); no `schema_version` bump (DM-1 stays 3, DM-2 stays 1); no existing golden-fixture bytes change (dispatch cases are added by task-027). The two twins stay byte-parity for the delete op's request/response (AC4).

**Acceptance Criteria:**
- [ ] Both `server.py` and `server.mjs` carry an IDENTICAL `pipeline.delete` `OP_TABLE` row: writer `delete-pipeline.sh`, argv `--work-id <work_id>`, env `AID_REPO_ROOT=<resolved repo root>`, scope per-repo, arg-schema requiring `args` absent/empty, and no op-schema flag. (AC4 parity, API contract)
- [ ] The `pipeline.delete` row carries a `status_map` (OP-SM) mapping writer exit 7 -> HTTP 409 `pipeline-active`, and preserves all `DEFAULT_MAP` rows (1 -> 404, 2 -> 409 busy, 3 -> 500, 4/5 -> 422). (Guards, feature-001 OP-SM)
- [ ] A `target.work_id` failing `^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$` or length <= 64 is rejected INLINE (no spawn) with 422 `invalid-value`; a malformed/absent `target` returns 400 `bad-request`. (API contract)
- [ ] After work_id validation the server calls `resolve_work_dir(repo, work_id)` (step 6); a `None` result returns 404 `not-found` with no spawn. (WT-1)
- [ ] A request with a non-empty `args` returns 422 `invalid-value` with no spawn (step 7, after the step-6 resolve). (API contract)
- [ ] The writer is spawned with only the validated `work_id` + server-resolved `AID_REPO_ROOT`, via an argv array (never a body-supplied path, never `shell=True`). (SEC-2 / SEC-3)
- [ ] No reader/parser change, no new endpoint, no `schema_version` bump, and no existing fixture bytes change; the two twins return byte-identical request/response for the delete op. (AC4)
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
