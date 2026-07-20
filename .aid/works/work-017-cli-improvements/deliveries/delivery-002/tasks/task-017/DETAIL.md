# task-017: Registry + tooling op round-trips

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

**Source:** feature-003-project-registry, feature-004-update-tools -> delivery-002

**Depends on:** task-013, task-014, task-015, task-016

**Scope:**
- **Objective:** prove the four new op handlers (`project.add`, `project.remove`, `tools.update`, `tools.update-self`) round-trip correctly at the server op-handler level in **both** twins -- each exit path mapping to the specified HTTP status via its per-op `status_map`, the fail-open guard surfacing a shared-tier no-op as 500 `write-unverified`, and `server.py` / `server.mjs` producing byte-identical responses. Extend the existing `test_server_py.py` / `test_server_node.mjs` (and any parity harness) suites; author no production code (that is tasks 013-016).
- **Automated-coverage boundary (client-side `index.html` JS is out of scope here -- deliberate, work-wide convention).** These suites cover the **server op-handler round-trips + twin byte-parity** only. The new client-side JS added by tasks 014/016 -- `write_enabled` control gating, the Remove confirm button-flip (task-014), and the Update busy-state + `machine.aid_version`-change restart advisory (task-016) -- is **not** placed under automated behavioural/structural test by this task; it is verified by manual acceptance against the task-014 / task-016 ACs. This mirrors the established **delivery-001/task-012** boundary (that TEST task likewise scoped to server op round-trips + model-field parity, leaving the client DOM behaviour to manual acceptance) -- a deliberate work-wide convention, not an isolated omission. **BLUEPRINT AC2 (truthful grid / machine-panel re-render)** is covered here at its **server source of truth** -- the post-op `/api/home` re-read reflects disk with no drift (asserted by the `project.add` 200-persistence, `project.remove` union-absence, and `tools.update*` version-field cases below); the client's `doFetch()`-driven DOM repaint from that truthful model is the manual half of AC2. If the team wants the client-JS behaviours placed under automated coverage, that is a work-wide scope change (touching delivery-001 too), not a task-017-local fix.
- **`project.add` cases:** exit 0 clean -> 200 and the typed path persists to the registry union; exit 0 + `WARN: aid:` on stderr (fail-open shared-tier no-op) -> 500 `write-unverified` (NOT a phantom 200); a relative / NUL / newline / control-char / over-4096 path -> 400 `bad-request` before dispatch; exit 2 (path absent, not an AID project) -> 422 `invalid-value` with the stderr tail in `detail`; other non-zero -> 500 `write-failed`.
- **`project.remove` cases:** exit 0 with the verbatim `id_map` path gone from the re-loaded union -> 200; a `target.id` absent from `id_map` -> 404 `not-found`; exit 0 but the `id_map` path **still present** in the re-loaded union (fail-open) -> 500 `write-unverified`; exit 2 (not registered) -> 422 `invalid-value`. Confirm the resolved path is the verbatim `id_map` value (SEC-2), never a body-supplied path.
- **`tools.update` cases (per-repo route `POST /r/<id>/api/op`):** exit 0 -> 200; unknown repo `<id>` -> 404 `not-found`; non-empty `args` -> 422 `invalid-value`; non-zero exit (and `aid` not resolvable/executable) -> 500 `update-failed`; child exceeding the 600 s ceiling (killed) -> 504 `timed-out`. Confirm the repo path is resolved from `<id>` via `id_map`, not from `target.work_id`.
- **`tools.update-self` cases (home route `POST /api/op`):** exit 0 -> 200; non-empty `args` -> 422 `invalid-value`; non-zero exit -> 500 `update-failed`; child killed at the 600 s ceiling -> 504 `timed-out`.
- **Exit-alphabet coverage.** Assert both distinct per-op alphabets: the `aid projects` alphabet (2 = user/validation -> 422) exercised by `project.add`/`project.remove`, and the `aid update` alphabet (non-zero -> `update-failed`, timeout -> `timed-out`) exercised by `tools.update`/`tools.update-self` -- distinct from feature-001's default `writeback-state.sh` map. Stub/fake the `aid` child (controlled exit code + stderr) rather than performing real registry writes or network updates.
- **Twin op-handler parity.** For every case above, `server.py` and `server.mjs` MUST return the **identical** HTTP status code and response bytes; assert this in the parity suite (the whole delivery ships two twins, so parity is a first-class gate here).
- **Shared-mechanism assertions (KI-004).** Assert that all four ops dispatch through the single self-located `$AID_CODE_HOME/bin/aid` resolver with an argv array (no shell), so a mis-wired helper (e.g. `aid`'s own usage-error `exit 2` leaking through, or `AID_CODE_HOME` wrongly exported) is caught.

**Acceptance Criteria:**
- [ ] `project.add` tests cover and pass: 200 + persistence, 500 `write-unverified` (exit-0 fail-open `WARN`), 400 `bad-request` (relative/NUL/newline/control/over-4096), 422 `invalid-value` (exit 2), 500 `write-failed` (other non-zero).
- [ ] `project.remove` tests cover and pass: 200 (verbatim `id_map` path gone from the re-loaded union), 404 `not-found` (unknown `target.id`), 500 `write-unverified` (union re-read still contains the path), 422 `invalid-value` (not registered); and confirm the path is resolved from `id_map`, never the body.
- [ ] `tools.update` tests cover and pass via `POST /r/<id>/api/op`: 200, 404 `not-found` (unknown `<id>`), 422 `invalid-value` (non-empty `args`), 500 `update-failed` (non-zero / not resolvable), 504 `timed-out` (>600 s).
- [ ] `tools.update-self` tests cover and pass via `POST /api/op`: 200, 422 `invalid-value` (non-empty `args`), 500 `update-failed` (non-zero), 504 `timed-out` (>600 s).
- [ ] Both per-op exit alphabets are asserted (the `aid projects` 2 -> 422 mapping and the `aid update` non-zero -> `update-failed` / timeout -> `timed-out` mapping), distinct from feature-001's default map.
- [ ] Twin op-handler parity is asserted: `server.py` and `server.mjs` return identical HTTP status and response bytes for every case, and the parity suites are green (feature-003 AC1/AC2/AC4, feature-004 AC1/AC1b).
- [ ] The automated/manual coverage boundary is explicit and honoured: server op-handler round-trips + twin byte-parity are automated here, while the client-side `index.html` JS (`write_enabled` gating, Remove confirm button-flip, Update busy-state, restart advisory) is manual-acceptance only -- consistent with the delivery-001/task-012 convention. BLUEPRINT AC2's server source of truth (post-op `/api/home` re-read reflects disk) is asserted by the `project.add` persistence / `project.remove` union-absence / `tools.update*` version-field cases above; the client DOM repaint is the manual half.
- [ ] Tests are deterministic
- [ ] Clean setup/teardown
- [ ] All acceptance criteria from source feature covered
- [ ] All section-6 quality gates pass
