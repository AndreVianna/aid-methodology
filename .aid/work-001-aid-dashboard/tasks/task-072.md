# task-072: PT-1-H byte-parity for the TaskDetail details envelope — cross-runtime byte-identity + NO-schema-bump assertion + key-order parity

**Type:** TEST

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-069, task-070

**Scope:**
- Extend the cross-runtime byte-parity harness (PT-1 / the d008 PT-1-H multi-repo shape) to cover the
  feature-008 `details` map (DM-2), proving Python (`server.py` + reader) and Node (`server.mjs` +
  `reader.mjs`) emit a **byte-identical** `/r/<id>/api/model?detail=…` envelope. This is the PT-1
  obligation feature-008 SPEC DM-2/DD-2 names — retained as a **parity** obligation even though the
  schema decision is **no-bump** (RC-2).
- **Fixture extension (DM-2):** add a registry-fixture repo/work that exercises the full `TaskDetail`
  surface — a `## Quick Check Findings ### task-NNN` block (with `[CRITICAL]`, `[HIGH]`, and an
  unknown/`[MINOR]` finding so the severity-normalization twin is exercised), a `## Delivery Gates
  ### delivery-NNN` block (grade/tier/ts), a `delivery-NNN-issues.md` (≥1 row with `Source task ==` the
  drilled task + ≥1 row for a *different* task so the filter is exercised), and a **STATE.md containing
  `U+2028`/`U+2029`** (feature-003 DM-3 escaping) — so `details` is proven byte-identical across runtimes
  for a `?detail=` request. Cover the `delivery_id==null` / absent-issues-file / clean-task (empty
  findings) branches so the null/empty paths are parity-checked too.
- **Key-order parity (DM-2):** assert both runtimes emit `details` keys **sorted ascending by
  `"work_id/task_id"`**, byte-identical **regardless of the request comma-list order** — issue the
  `?detail=` list in a scrambled order and confirm both runtimes produce the same sorted-key output
  (FR14 parallel-drill, multi-key).
- **NO-schema-bump assertion (RC-2):** assert the envelope `schema_version` is **still 3** for both a
  bare `/r/<id>/api/model` poll **and** a `?detail=`-bearing one (no bump); assert `details` is **absent
  (key omitted)** on the bare poll and **present** only with `?detail=` (the omittable-additive contract);
  assert the bare-poll body is byte-for-byte unchanged from the pre-d010 envelope (NFR4 — the always-on
  path did not grow). This is the test that pins RC-2's no-bump decision mechanically.
- **R7 escaping under parity:** confirm the `U+2028`/`U+2029` in the fixture STATE.md serialize to the
  same escaped canonical form (DM-3) inside `raw_state.text` across both runtimes — the cross-runtime
  divergence class PT-1 guards, now over the heavy raw-state bytes.
- **Read-only / determinism:** the test observes only — it never mutates `.aid/`; the servers stay bound
  to `127.0.0.1` for the run; `generated_by` is the diagnostic-only field excluded from parity (feature-
  003 DM-1). Skip-if-absent posture consistent with the existing PT-1/PT-1-H harness.

**Acceptance Criteria:**
- [ ] A fixture work exercises the full `TaskDetail` surface (findings across `[CRITICAL]`/`[HIGH]`/
      unknown, a delivery-gates block, a `delivery-NNN-issues.md` with own + other-task rows, a
      `U+2028`/`U+2029` STATE.md) plus the null/empty branches (`delivery_id==null`, absent issues file,
      clean-task empty findings).
- [ ] Python and Node emit a **byte-identical** `/r/<id>/api/model?detail=…` envelope (incl. `details`,
      `raw_state.text` with escaped `U+2028`/`U+2029`); `generated_by` is the only excluded field.
- [ ] `details` keys are emitted **sorted ascending by `"work_id/task_id"`** byte-identically **regardless
      of request comma-list order** (a scrambled-order request yields the same sorted output in both runtimes).
- [ ] **NO schema bump asserted:** `schema_version` is **3** for both the bare and the `?detail=` poll;
      `details` is **absent on the bare poll** and **present only with `?detail=`**; the bare-poll body is
      byte-for-byte unchanged from the pre-d010 envelope (NFR4 always-on path unchanged).
- [ ] The test mutates no `.aid/`, the servers stay bound to `127.0.0.1`, and it follows the existing
      PT-1/PT-1-H skip-if-absent posture.
- [ ] All §6 quality gates pass; the Playwright R5 visual gate over the drill view is task-073.
