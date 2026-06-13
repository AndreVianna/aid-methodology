# task-018: PT-1 cross-runtime byte-parity test (incl. U+2028/U+2029 fixture)

**Type:** TEST

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-016, task-017

**Scope:**
- Implement the PT-1 parity contract (feature-003 DM-3 / PT-1): both runtimes' `/api/model` responses, after stripping `generated_by` and normalizing `model.read.read_at`, are BYTE-IDENTICAL for the same `.aid/` snapshot.
- Build the checked-in PT-1 fixture `.aid/` tree containing at least: one `Running` work with parallel tasks, one `Paused-Awaiting-Input`, one `Blocked` with an IMPEDIMENT, one `Completed`, one fallback-`source_mode` work, and a no-`.aid/` empty case — AND a STATE.md string containing `U+2028` and `U+2029` (mandatory, R7 — proves the escaping guarantee, not assumes it).
- Test harness per `test-landscape.md`: bash aggregator + per-runtime `.mjs`/python validators that skip if that runtime is absent; the parity assertion runs only when BOTH runtimes are present.

**Acceptance Criteria:**
- [ ] `strip(generated_by)` + `normalize(model.read.read_at)` on both runtimes' responses ⇒ byte-identical, asserted across the full fixture set.
- [ ] The fixture includes a STATE.md with `U+2028`/`U+2029`; the test fails if either runtime emits a divergent (raw vs escaped) form (R7).
- [ ] The harness runs the Python half on a Node-less box and vice-versa, and runs the parity assertion only when both runtimes are present (skip-if-absent).
- [ ] The test covers feature-003's "implemented twice never behaves twice" guarantee as a deliverable, not optional polish.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown and cover the source AC (PT-1); run green under `tests/run-all.sh`; build passes.
