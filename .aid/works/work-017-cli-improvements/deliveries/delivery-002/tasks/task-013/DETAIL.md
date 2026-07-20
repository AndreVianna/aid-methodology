# task-013: project.add / project.remove handlers + shared aid-CLI resolver

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

**Source:** feature-003-project-registry -> delivery-002

**Depends on:** task-004 (delivery-001)

**Scope:**
- **Objective:** register the two home registry ops on the server's closed `OP_TABLE`, complete `_serve_home_op`'s dispatch for them, and introduce the single **shared `aid`-CLI resolver** (KI-004) that feature-004 will reuse -- all in both `dashboard/server/server.py` and its `dashboard/server/server.mjs` byte-parity twin. No `index.html` change (task-014), no reader/serializer edit.
- Append two rows to feature-001's closed `OP_TABLE` in **both twins**: `project.add` (scope `home`, `args.path`) and `project.remove` (scope `home`, `target.id`). Complete the `_serve_home_op` gate/dispatch skeleton feature-001 seeds (`server.py` `do_POST` blanket-405 at ~L906; `server.mjs` non-GET 405 at ~L682) so `POST /api/op` dispatches these two ops. Home scope has no `target.work_id` resolution.
- Introduce the **shared `aid`-CLI resolver + argv-array child dispatch** (the KI-004 single-source mechanism). Self-locate the writer at `$AID_CODE_HOME/bin/aid` == `_DASHBOARD_DIR.parent / "bin" / "aid"` (the identical self-location `server.py` already uses for `VERSION` L401 and `lib/tools-catalog.txt` L417). Invoke it **unconditionally** as `bash <that path> projects <verb> <args...>` passed as an argv **array** (no `shell=True`, no command string) -- no OS branch, no bundled-Windows-shim alternative, no `PATH` fallback, no co-vendoring (`bin/aid` already ships in the CLI package). This helper MUST be a single reusable unit so task-015 can call it verb-for-verb.
- Child environment: set `AID_HOME=<self.server.aid_home>` (the value the server booted with -- `server.py` L1145/L1151, from `_dc_start`'s `AID_HOME=$AID_STATE_HOME`, `bin/aid` L1216) so the child resolves the **same** registry union `/api/home` enumerates. Do **not** export `AID_CODE_HOME` (the child self-locates it). Pass no `--local`/`--shared`/`--verbose` (tier selection is the CLI's `_aid_resolve_tier`).
- Build argv per op: `project.add` -> `bash $AID_CODE_HOME/bin/aid projects add <validated-path>`; `project.remove` -> `bash $AID_CODE_HOME/bin/aid projects remove <id_map-resolved-path>`.
- Per-op validation (pre-dispatch): `project.add` requires `args.path` non-empty, **absolute** (`os.path.isabs` / Node `path.isAbsolute`), length <= 4096, rejecting NUL / newline (`\n`/`\r`) / control chars -> 400 `bad-request` (a relative path is rejected, not resolved against the server cwd). `project.remove` requires `target.id` to be a current key of the server's `id_map` -> else 404 `not-found`; the server resolves `id -> canonical path` from `id_map` **verbatim** (SEC-2) and passes that path -- never a body-supplied path.
- Declare the explicit per-op `status_map` overriding feature-001's default (the `aid`-CLI exit alphabet differs: 0 = ok, 2 = user/validation error): exit 0 clean (no `WARN: aid:`) -> 200; exit 0 with a `WARN: aid:` stderr line -> 500 `write-unverified`; exit 2 -> 422 `invalid-value` (stderr tail -> `detail`); other non-zero -> 500 `write-failed` (stderr tail <= 1 KiB -> `detail`).
- Implement the **fail-open post-dispatch guard** (the one net-new handler behaviour beyond the feature-001 skeleton): capture the child's stderr on **every** exit (not only non-zero). On a 0 exit, a `WARN: aid:` (or `_aid_priv_run` `ERROR: aid:`) line means the shared-tier write degraded to a silent no-op -> 500 `write-unverified` with that line in `detail`. For `project.remove` additionally corroborate canonicalisation-free: re-load the union (`_load_union_repos`, `server.py` L160 / `loadUnionRepos`, `server.mjs` L180) and require the **verbatim** `id_map` path to now be **absent** -- else `write-unverified`. (For `project.add` a union-membership check is NOT the detector -- the CLI stores the logical `cd && pwd` form while the registry is read verbatim, CAN-1/DD-5, so the stderr-`WARN` signal is the reliable one.) Only a clean exit 0 (no `WARN`; for remove, path confirmed gone) yields 200.
- Keep both twins behaviourally and byte-for-byte identical (SEC-3: server writes nothing in-process; SEC-4: the child is the `aid` CLI, never an LLM). Success envelope: `{ "ok": true, "op": "project.add|project.remove" }`; failure: `{ "ok": false, "op", "error", "detail" }`.

**Acceptance Criteria:**
- [ ] `OP_TABLE` in **both** `server.py` and `server.mjs` carries a `project.add` (scope `home`, `args.path`) row and a `project.remove` (scope `home`, `target.id`) row, and `_serve_home_op` dispatches each on `POST /api/op` (the prior blanket-405 no longer fires for these ops).
- [ ] A single **shared `aid`-CLI resolver** exists (self-locates `$AID_CODE_HOME/bin/aid` via `_DASHBOARD_DIR.parent`, invokes `bash <path> projects <verb> ...` as an argv array with no shell, no OS branch, no Windows shim, no `PATH` fallback) and is structured for reuse by task-015 (KI-004: not re-invented per op).
- [ ] The child is spawned with `AID_HOME=<server aid_home>` and `AID_CODE_HOME` is NOT exported; no `--local`/`--shared`/`--verbose` flag is passed.
- [ ] `project.add` rejects a missing / empty / relative / over-4096 / NUL-or-newline-or-control path with 400 `bad-request` before dispatch; a validated absolute path is passed verbatim as one argv element.
- [ ] `project.remove` returns 404 `not-found` for a `target.id` absent from `id_map`, and otherwise passes the **verbatim** `id_map`-resolved path (never a body path) to `aid projects remove`.
- [ ] The per-op `status_map` maps exit 0 (clean) -> 200, exit 2 -> 422 `invalid-value`, and other non-zero -> 500 `write-failed`, with the stderr tail (<= 1 KiB) in `detail`.
- [ ] The fail-open guard captures stderr on every exit and converts an exit-0 `WARN: aid:` (or `ERROR: aid:`) into 500 `write-unverified`; for `project.remove` it additionally re-reads the union and returns `write-unverified` unless the verbatim `id_map` path is gone -- so a fail-open no-op is never reported as a phantom 200 (feature-003 AC1).
- [ ] Both twins return identical HTTP status codes and response bytes for every case, and the existing `test_server_py.py` / `test_server_node.mjs` parity suites remain green (feature-003 AC4 / byte-parity).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
