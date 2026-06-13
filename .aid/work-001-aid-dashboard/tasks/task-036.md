# task-036: PT-1 parity re-validation at schema_version 3 (KbModel + details)

**Type:** TEST

**Source:** feature-007-kb-dashboard + feature-008-skill-task-drilldown → delivery-005

**Depends on:** task-032, task-034, task-035

**Scope:**
- Re-validate the PT-1 cross-runtime byte-parity contract at `schema_version: 3` over the grown fixture (task-034): both runtimes' responses, after stripping `generated_by` and normalizing `model.read.read_at`, are BYTE-IDENTICAL — now covering the rich `KbModel` (feature-007 DM-2) AND the lazy `details`/`TaskDetail` map (feature-008 DM-2).
- Assert a `GET /api/model` (no param) still omits `details` and a `GET /api/model?detail=<work_id>/<task_id>[,...]` request yields byte-identical `details` across runtimes regardless of the request comma-list order (keys sorted ascending by `work_id/task_id`).
- Assert the `U+2028`/`U+2029` STATE.md content flows byte-identically through both `KbModel` and `details` (escaped canonical form, feature-003 DM-3).
- Reuse the skip-if-runtime-absent harness; the parity assertion runs only when both runtimes are present.

**Acceptance Criteria:**
- [ ] At `schema_version: 3`, both runtimes' `/api/model` (and `?detail=`) responses are byte-identical after stripping `generated_by` + normalizing `read_at`, across the grown fixture incl. `KbModel` + `details`.
- [ ] `details` is absent without the param and present + key-sorted (byte-identical regardless of request order) with it (feature-008 DM-2 parity rule).
- [ ] The `U+2028`/`U+2029` STATE.md content is byte-identical (escaped) through both `KbModel` and `details` (R7).
- [ ] The harness skips a missing runtime and runs the parity assertion only when both are present.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown and cover the source AC (PT-1 at schema_version 3); run green under `tests/run-all.sh`; build passes.
