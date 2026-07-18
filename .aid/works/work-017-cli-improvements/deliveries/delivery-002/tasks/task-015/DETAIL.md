# task-015: tools.update / tools.update-self handlers

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

**Source:** feature-004-update-tools -> delivery-002

**Depends on:** task-013

**Scope:**
- **Objective:** register the two tooling-update ops on feature-001's closed `OP_TABLE` -- per-repo `tools.update` (`aid update --target`) and home `tools.update-self` (`aid update self`) -- **reusing the shared `aid`-CLI resolver task-013 introduced** (KI-004, not re-invented), in both `dashboard/server/server.py` and its `dashboard/server/server.mjs` byte-parity twin. No `index.html` change (task-016), no reader/serializer edit.
- Append two rows to feature-001's closed `OP_TABLE` in **both twins**:
  - `tools.update` -- scope **per-repo, project-scoped** (it does **not** consume `target.work_id`; the repo path is resolved solely from `<id>` via `id_map`, SEC-2). Route `POST /r/<id>/api/op`. argv: `bash $AID_CODE_HOME/bin/aid update --target <id_map-resolved-repo-path>`. Reuse feature-001's per-repo `_serve_op` gate + dispatch verbatim. This **refines** the tentative `tools.update` row feature-001 seeded (fixing its scope to per-repo project-scoped and its argv to `update --target <repo>`).
  - `tools.update-self` -- scope **home** (`POST /api/op`, no `<id>`, no `target`). argv: `bash $AID_CODE_HOME/bin/aid update self`. **Completes** feature-001's `_serve_home_op` gate/dispatch skeleton for this op (the same relationship task-013 has for `project.add`/`project.remove`).
- **Reuse the shared resolver from task-013 (KI-004).** Both ops shell out through the single self-located `$AID_CODE_HOME/bin/aid` resolver (`_DASHBOARD_DIR.parent / "bin" / "aid"`), invoked as `bash <path> update ...` via an argv **array** (no shell) -- no OS branch, no bundled-Windows-shim, no `PATH` fallback, no co-vendoring. Do not add a second resolver; call the one task-013 built.
- **Child environment:** `AID_HOME=AID_STATE_HOME` **only** (the one env var `bin/aid` L1216 sets on the dashboard spawn); `AID_CODE_HOME` is **not** exported (the child self-locates it per `bin/aid` L45-52). Spawn with **no controlling tty**, so `aid update`'s non-interactive tool-install loop (`bin/aid` L3363-3445) runs clean and `aid update self`'s `/dev/tty` migration walk self-skips (`bin/aid` L2881-2883).
- **Arg-schema:** both ops are **argument-free** -- absent/empty `args` accepted; **non-empty `args` -> 422 `invalid-value`** (feature-001 arg-schema convention). No `--force`/`--dry-run`/per-tool knobs (D4).
- **Dispatch:** synchronous child (feature-001's `subprocess.run(..., capture_output=True, timeout=...)` / `execFileSync`/`spawnSync` with an array), **generous 600 s timeout**, capture exit + stderr/stdout tail (SEC-3 no in-process fs-write; SEC-4 child is the `aid` CLI, not an LLM).
- **Status map** (extends feature-001's map with the CLI-op rows): untrusted Host header -> 403 `bad-host`; write gate closed -> 403 `read-only`; malformed/oversize body or unknown `op` -> 400 `bad-request`; non-empty `args` -> 422 `invalid-value`; unknown repo `<id>` (per-repo op only) -> 404 `not-found`; `aid` not resolvable / not executable -> 500 `update-failed`; `aid` exits non-zero -> 500 `update-failed`; child exceeds the 600 s ceiling (killed) -> 504 `timed-out`; `aid` exits 0 -> 200. Failure envelope carries the `aid` stderr/stdout tail (<= 1 KiB) in `detail`.
- The server **controls the entire argv** (fixed tokens + a server-resolved path), so `aid`'s own usage-error exits (e.g. the tool-positional reject, `bin/aid` L3054-3062, `exit 2` at L3061) are **not reachable** through this surface; they would collapse to `update-failed` only if the shared helper were mis-wired (a task-017 test target).
- Keep both twins behaviourally and byte-for-byte identical. Success envelope: `{ "ok": true, "op": "<op>" }`; failure: `{ "ok": false, "op", "error", "detail" }`. No reader/serializer edit (the updated versions are already read fields), so AC4 byte-parity is untouched by construction.

**Acceptance Criteria:**
- [ ] `OP_TABLE` in **both** twins carries a `tools.update` row (scope per-repo project-scoped; route `POST /r/<id>/api/op`; argv `bash $AID_CODE_HOME/bin/aid update --target <id_map-resolved-repo-path>`; reuses feature-001's `_serve_op`) that resolves the repo path from `<id>` via `id_map` (SEC-2), never from `target.work_id`.
- [ ] `OP_TABLE` in **both** twins carries a `tools.update-self` row (scope home; route `POST /api/op`; argv `bash $AID_CODE_HOME/bin/aid update self`) dispatched by the completed `_serve_home_op`.
- [ ] Both ops invoke the **single shared `aid`-CLI resolver from task-013** (self-located `$AID_CODE_HOME/bin/aid`, argv array, no OS branch/Windows shim/`PATH` fallback) -- verified single-sourced, not a re-invented resolver (KI-004).
- [ ] The child is spawned with `AID_HOME=AID_STATE_HOME` only, `AID_CODE_HOME` NOT exported, and no controlling tty; the synchronous dispatch uses a 600 s timeout and captures exit + stderr/stdout tail.
- [ ] Both ops are argument-free: a non-empty `args` yields 422 `invalid-value`; an unknown repo `<id>` on `tools.update` yields 404 `not-found`.
- [ ] The per-op `status_map` maps exit 0 -> 200, non-zero (or not-resolvable/not-executable) -> 500 `update-failed`, and a child killed at the 600 s ceiling -> 504 `timed-out`, with the `aid` output tail (<= 1 KiB) in `detail`.
- [ ] Both twins return identical HTTP status codes and response bytes for every case; no reader/serializer change is made and the `test_server_py.py` / `test_server_node.mjs` parity suites remain green (feature-004 AC1/AC1b, AC4).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
