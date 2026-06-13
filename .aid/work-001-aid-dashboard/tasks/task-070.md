# task-070: Server lazy ?detail= branch (LC-SD) — per-<id> /api/model attaches details, NO schema_version bump (RC-2), key-order parity

**Type:** IMPLEMENT

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-069, task-050, task-051

**Scope:**
- Add the **LC-SD server detail branch** to feature-010's multi-repo server (`dashboard/server/server.py`
  ∥ `dashboard/server/server.mjs`, the d008 LC-MS rewrite — task-050/051) on the **existing per-repo
  `/r/<id>/api/model` route**. Both runtimes change in **lockstep** (separate files, identical contract,
  byte-parity held by task-072). This is the **single writer** of the two server files in d010; it
  references the d008 LC-MS servers, it does not re-write them.
- **No new route/path/verb (DD-1, RC-1):** parse an **optional additive `?detail=` query param** on the
  already-served `GET /r/<id>/api/model` route; the server's closed allowlist (`/` + `/api/home` +
  per-`<id>` `/r/<id>/{home.html,kb.html,api/model}`) is **unchanged** — still GET-only, loopback-bound,
  read-only, no-LLM. No `/api/task/<id>` endpoint is added.
- **`?detail=<work_id>/<task_id>[,...]` (FR14 comma-list):** parse the comma-list of composite
  `work_id/task_id` keys; pass that `task_id` list to the reader (task-069 LC-TR via the
  `detail_task_ids` param); for each, attach the returned `TaskDetail` under
  `details["work_id/task_id"]`. **`details` is PRESENT ONLY when `?detail=` is supplied — the key is
  OMITTED entirely otherwise** (the always-polled pipeline/main/KB body is byte-for-byte unchanged, NFR4).
- **DM-2 key-order parity (on top of feature-003 DM-3):** both runtimes MUST emit `details` keys **sorted
  ascending by the `"work_id/task_id"` string**, so the response is byte-identical regardless of the
  request comma-list order or the runtime — enforced by PT-1-H (task-072). Serialize with the existing
  DM-3 canonical form (compact, `ensure_ascii=False`, **U+2028/U+2029 escaped** — R7).
- **NO `schema_version` bump (RC-2 — stays at 3):** per the SPEC's RC-2 reconciliation, `details` is a
  new top-level envelope key that is **additive + omittable + lazy + consumer-tolerant** and ships in
  lockstep with its sole consumer (the d010 drill view, task-071) — the **`created` shape, not the
  feature-009 shape** (DM-A3 reconciling rule). The envelope **stays at `schema_version 3`**; the
  front-end `EXPECTED` is **unchanged**; the stale-assets banner does not fire. **Do not** bump to 4.
  (The SPEC body's old "2→3 / composes with feature-007's 1→2" DM-2/DD-2 wording is superseded by RC-2.)
- **R15 / no-write across N roots:** the `?detail=` branch reads only through the d008 construct-not-
  sanitize per-`<id>` static-path discipline (R9) — it adds **no** write surface, binds **no** non-
  loopback address, and calls **no** agent/LLM. Re-assert the feature-003/feature-010 self-checks
  (grep no-`0.0.0.0`/non-loopback, no-`fs.write*`/write-mode `open()`, no-LLM) over the new branch in
  both runtimes; the served raw STATE.md content (from LC-TR `raw_state`) flows out **escaped by the
  front-end** (task-071), and the server passes it through verbatim (never executes/edits it).
- **First-tick tolerance:** a `?detail=` request for a `task_id` the reader cannot resolve (disappeared
  row, FR12) attaches no entry for that key (or a best-effort `parse_warning`-bearing one) — never throws,
  never 500s; the front-end renders the "no longer in the work's state" / "loading…" state (task-071).

**Acceptance Criteria:**
- [ ] Both servers parse `?detail=<work_id>/<task_id>[,...]` on the **existing** `/r/<id>/api/model` route
      and attach a `details` map; **no new route/path/verb** is added to the closed allowlist; GET-only,
      loopback-bound, read-only preserved.
- [ ] `details` is **present only when `?detail=` is supplied** and **omitted otherwise** — a bare
      `/r/<id>/api/model` poll is byte-for-byte unchanged (no `details` key) — verified in both runtimes.
- [ ] `details` keys are emitted **sorted ascending by `"work_id/task_id"`**, byte-identical regardless of
      request order or runtime (DM-2), serialized in the DM-3 canonical form with U+2028/U+2029 escaped.
- [ ] **NO `schema_version` bump** — the envelope stays at **3**, the front-end `EXPECTED` is unchanged,
      no stale-assets-banner churn (RC-2 no-bump decision applied; SPEC DM-2/DD-2 "2→3" superseded).
- [ ] The `?detail=` branch adds no write surface / non-loopback bind / agent call across N roots (R15);
      the feature-003/feature-010 no-`0.0.0.0`/no-write/no-LLM self-checks pass over the new branch in
      both runtimes; raw STATE.md content is passed through verbatim (escaped downstream by task-071).
- [ ] An unresolvable/disappeared requested `task_id` attaches no entry (or a best-effort warning), never
      throws/500s; the always-on path is unaffected (NFR4).
- [ ] All §6 quality gates pass; IMPLEMENT default server self-tests in both runtimes; cross-runtime
      byte-parity of the `details` envelope is task-072.
