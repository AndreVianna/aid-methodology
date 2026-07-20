# task-004: POST op-router + closed OP_TABLE + op.status_map or DEFAULT_MAP dispatch

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

**Depends on:** task-001, task-002, task-003

**Scope:**
- Replace the blanket POST-405 with the op router and the closed dispatch engine -- the core write mechanism every consuming feature registers against. Enforce the write gate (403), resolve pipeline targets via `resolve_work_dir` (WT-1, 404), dispatch to allowlisted writers via argv arrays, and map exit-code -> HTTP via `op.status_map or DEFAULT_MAP`. Seed the four feature-001-owned OP_TABLE rows. Applied identically to both server twins.
- Routing (`server.py` `do_POST` ~line 906; `server.mjs` handler `method !== "GET"` guard ~line 682): replace the blanket 405 for POST with `POST /r/<id>/api/op` -> `_serve_op` (per-repo) and `POST /api/op` -> `_serve_home_op` (home-level); any other POST path -> 405; PUT/DELETE/PATCH/HEAD stay 405.
- Write gate: in `_serve_op`/`_serve_home_op`, after the existing `_reject_bad_host` (SEC-6), check `self.write_enabled` (Python) / module `WRITE_ENABLED` (Node) -- not enabled => JSON `{ok:false,error:"read-only"}` with HTTP 403. This is the AC8 enforcement point and consumes the task-001 signal.
- `OP_TABLE`: a static, closed dict mapping `op` -> `{writer, argv-builder, arg-schema, scope, status_map?}`. The dispatcher resolves the effective map as `op.status_map or DEFAULT_MAP`; `DEFAULT_MAP` is the exit-code -> HTTP table derived from `writeback-state.sh`'s exit alphabet (1->404, 4->422, 5->422, 2->409, 3/6/*->500) plus the gate/host/bad-request 403/400 rows (OP-SM foundation contract for delivery-002).
- Pipeline-scoped ops: validate `target.work_id` (`^work-[0-9]+`), then `resolve_work_dir(root, work_id)` (task-002) -> REAL on-disk dir -> 404 `not-found` when `None`; point `AID_STATE_FILE` / `AID_WORK_DIR` / `AID_REQUIREMENTS_FILE` at the resolved dir (WT-1). Project-scoped `settings.set` skips work_id resolution and targets `<served-root>/.aid/settings.yml` (read from the served root exactly as `_read_settings` reads it).
- Child-process invocation: `subprocess.run([...])` (Python) / `child_process.execFileSync`/`spawnSync` (Node) with an argument ARRAY (never `shell=True`, never a concatenated command string). SEC-3 refined (server file keeps NO in-process fs-write primitive); SEC-4 (child is a shell script or the `aid` CLI, never an agent/LLM import).
- Request/response envelope (both twins byte-parity): `Content-Type: application/json`, body <= 64 KiB (larger -> 400); success `{ok:true, op}` (200); failure `{ok:false, op, error, detail (<=1 KiB)}` with status per the effective map. On success the client re-fetches the owning GET endpoint (per-repo `/r/<id>/api/model`; home `/api/home`).
- Seed the four feature-001-owned OP_TABLE rows (writer + scope + default status_map, per feature-001 §API Contracts): `task.set-notes`, `pipeline.finish` (value FIXED to `Completed`; the op forwards no other lifecycle value), `settings.set`, `pipeline.rename`. The concrete per-op arg-schemas / argv-builders for these are finalized by their consuming tasks (task-006 settings.set; task-008 BOTH feature-005 server-side rename argv-builders -- the new `task.rename` row AND the pre-seeded `pipeline.rename` argv-builder, incl. its empty-value -> `*(pending)*` null-sentinel substitution, per feature-005 SPEC §Layers component 1; task-009 rename UI only; task-010 task.set-notes); this task seeds the rows and the writer/argv shape feature-001 declares.

**Acceptance Criteria:**
- [ ] POST router: `/r/<id>/api/op` -> `_serve_op`, `/api/op` -> `_serve_home_op`, other POST + PUT/DELETE/PATCH/HEAD -> 405; both twins return byte-identical responses.
- [ ] Gate enforced: with `write_enabled` false, every op -> HTTP 403 `read-only`, checked after the SEC-6 Host-header allowlist (AC8 enforcement point).
- [ ] Closed `OP_TABLE` dispatch: unknown `op` -> 400; oversize/malformed body -> 400; args validated per the op's schema before any child spawn.
- [ ] A pipeline-scoped op resolves `target.work_id` via `resolve_work_dir` and targets the resolved dir; `None` -> 404 `not-found` (WT-1). Project-scoped `settings.set` skips work_id and targets `<served-root>/.aid/settings.yml`.
- [ ] The dispatcher resolves the effective status map as `op.status_map or DEFAULT_MAP`: a row without `status_map` uses `DEFAULT_MAP` unchanged; a row with one uses its own map (OP-SM foundation contract for delivery-002).
- [ ] Children are spawned with an argv ARRAY (no shell); the server file contains no in-process fs-write primitive (`open(...,'w')` / `writeFileSync` / `appendFile` / `unlink` / `os.remove`) -- SEC-3 -- and no agent/LLM import -- SEC-4.
- [ ] The four feature-001-owned rows (`task.set-notes`, `pipeline.finish` [value fixed `Completed`], `settings.set`, `pipeline.rename`) are seeded (writer + scope + default map) identically in both twins; `pipeline.finish` forwards no lifecycle value other than `Completed`.
- [ ] Every op success returns `{ok:true, op}` and failure returns `{ok:false, op, error, detail}` with status per the effective map; both twins byte-parity (AC4).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
