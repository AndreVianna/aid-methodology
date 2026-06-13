# task-069: Reader TaskDetail sub-parser (LC-TR) — findings/ledger/raw_state/logs, Python ∥ Node byte-parity, detail-only (no always-on path change)

**Type:** IMPLEMENT

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-046, task-047

**Scope:**
- Add the **LC-TR detail sub-parser** to the feature-002 reader (Python `dashboard/reader/{models.py,
  parsers.py,derivation.py}` ∥ Node `dashboard/server/reader.mjs`) that populates the `TaskDetail`
  forensic sub-model (DM-1) **only for requested `task_id`s**. Both runtimes change in **lockstep** —
  every parse rule is a literal Python↔Node twin guarded by PT-1-H byte-parity (task-072). This is the
  **single writer** of the reader files in d010 (no same-file race). It runs against the **d008
  install-relocated reader** (task-046/047 `$AID_HOME/dashboard/` layout) — referenced, not duplicated.
- **`TaskDetail` (DM-1), keyed by `task_id`:** `findings: list<Finding>`, `ledger: TaskLedger`,
  `raw_state: RawStateRef`, `logs: LogAvailability`. All **read-derived**; nothing persisted (NFR2).
- **`findings` (DR-2):** parse `STATE.md ## Quick Check Findings → ### task-NNN → **Findings:**` bullets
  into `Finding{severity, description, location, disposition, reviewer_tier}` per the DM-1 table: leading
  bracketed tag → `severity` (`[CRITICAL]`/`[HIGH]`; lower/unknown → `[MINOR]` neutral, **never throws**,
  mirrors feature-002 DM-6); bullet text up to the first ` — ` → `description`; `{file:line}` segment →
  `location` (null if absent); trailing `Fixed-on-spot`/`Deferred-to-gate` token → `disposition`; the
  block's `**Reviewer Tier:**` line → `reviewer_tier`.
- **`ledger` (DR-3/DR-4) — the join, NOT a task grade:** `TaskLedger{delivery_id, grade, reviewer_tier,
  gate_timestamp, deferred_issues}`. Resolve the task's delivery (the `## Tasks Status` row's wave/Notes
  association, or the single lite-path delivery); parse `## Delivery Gates → ### delivery-NNN →
  **Grade:**/**Reviewer Tier:**/**Timestamp:**` for grade/tier/ts (rendered verbatim, **never
  re-graded** — NFR7); read `.aid/{work}/delivery-NNN-issues.md` (`schemas.md §12` 4-col `Source task |
  Severity | Description | Status`) and **filter rows to `Source task == this task_id`** →
  `deferred_issues: list<DeferredIssue{source_task, severity, description, status}>`. `delivery_id==null`
  (task not yet associated / pre-gate) → `grade=null`; absent issues file → empty list. No grade is
  fabricated per task (DM-1: AID grades per delivery).
- **`raw_state` (DR-1) — REUSE already-read bytes, no re-read (NFR4):** `RawStateRef{text, byte_len,
  path}` from the **verbatim bytes of `.aid/{work}/STATE.md` the reader already read this pass**
  (feature-002 Feature Flow step 5a) — `text` = whole work STATE.md, `byte_len` = its length,
  `path` = `.aid/{work}/STATE.md` (a read-only caption label, not an edit link). **Do not re-read** the
  file for the drill (DD-3: one STATE.md per work; zero extra disk I/O for `raw_state`).
- **`logs` (DR-5) — HONEST inventory (DM-4):** `LogAvailability{task_logs, server_log_present,
  heartbeat_present}`. `task_logs = none` **always** (AID persists no per-task execution log — the field
  exists for a future capability). `server_log_present` = `stat .aid/.temp/dashboard.log` (the dashboard
  **server's own** stdout/stderr — a tool diagnostic, **not** a task log; **expected-false on Windows**
  per DM-4). `heartbeat_present` = `stat .aid/.heartbeat/` (a liveness signal, corroborating-only,
  KI-004). **Do not** invent a log model over files that do not exist (KI-008).
- **Detail-only, runs ONLY on request (NFR4, DD-1):** LC-TR executes **only when a composite
  `work_id/task_id` is requested** — the always-on `read_repo` path (pipeline/main/KB views) is
  **untouched**; `model.works[].tasks[]` keep their existing `TaskModel` fields. The signature grows an
  optional `detail_task_ids` parameter (the always-on call passes none).
- **Torn-read tolerance (inherited):** a mid-write STATE.md / issues file yields `parse_warnings` +
  best-effort fields on that one poll; never throws on a missing block (null-fill + `parse_warning`).
- **Read-only / no-LLM (NFR2/NFR7):** LC-TR adds only **reads** of files already in the work folder + a
  **reuse** of bytes already read — no write/lock/append, no new write surface, no agent/LLM. The
  reader's existing no-write self-check (`test_no_write_primitives_in_reader_modules`) MUST still pass and
  now also covers LC-TR; no write-mode `open()` / `Popen`-for-mutation is added. (This task introduces
  **no** subprocess — the only sanctioned reader subprocess is the d009 KB git-read, out of scope here.)

**Acceptance Criteria:**
- [ ] LC-TR populates `TaskDetail{findings, ledger, raw_state, logs}` for a requested `work_id/task_id` in
      **both** runtimes, byte-identically; it runs **only** when a `task_id` is requested — the always-on
      `read_repo` path and `TaskModel` shape are unchanged (NFR4 verified by a no-`details`-on-bare-call test).
- [ ] `findings` parse the `## Quick Check Findings ### task-NNN` block per the DM-1 table (severity
      tag incl. unknown→`[MINOR]` neutral never-throws, description/location/disposition/reviewer_tier);
      a clean task → empty list (not an error).
- [ ] `ledger` is the **join** (DM-1): delivery-resolved grade/tier/ts from `## Delivery Gates` (verbatim,
      never re-graded), `deferred_issues` filtered to `Source task == task_id` from
      `delivery-NNN-issues.md`; `delivery_id==null` → `grade=null`; absent issues file → empty list.
- [ ] `raw_state` REUSES the already-read `.aid/{work}/STATE.md` bytes (no re-read — DR-1/DD-3) with
      `{text, byte_len, path}`; `path` is a read-only label.
- [ ] `logs` is the honest DM-4 inventory: `task_logs=none` always, `server_log_present`=stat of
      `dashboard.log` (expected-false on Windows), `heartbeat_present`=stat of `.aid/.heartbeat/`; no fake
      log model is invented (KI-008).
- [ ] A torn/missing block yields `parse_warnings` + best-effort fields, never throws; the reader stays
      read-only/no-LLM — `test_no_write_primitives_in_reader_modules` still passes; no subprocess introduced.
- [ ] All §6 quality gates pass; IMPLEMENT default unit tests for each sub-parser branch in both runtimes;
      cross-runtime byte-parity of `TaskDetail` is task-072 (the server attach + envelope is task-070).
