# task-033: feature-008 reader extension LC-TR + server ?detail= branch (LC-SD) — populate TaskDetail lazily

**Type:** IMPLEMENT

**Source:** feature-008-skill-task-drilldown → delivery-005

**Depends on:** task-031, task-016, task-017

**Scope:**
- Implement LC-TR (feature-002 reader, both runtimes): a detail sub-parser that populates `TaskDetail` (feature-008 DM-1) ONLY when a composite `work_id/task_id` is requested — DR-1 reuse the already-read work `STATE.md` bytes → `raw_state` (no re-read); DR-2 parse `## Quick Check Findings ### task-NNN` → `findings[]` (`Finding`: severity `[CRITICAL]`/`[HIGH]`/neutral, description, location, disposition, reviewer tier); DR-3 resolve the task's delivery + parse `## Delivery Gates ### delivery-NNN` → `ledger` (delivery_id, grade, tier, gate timestamp — a JOIN, never a "task grade"); DR-4 read `delivery-NNN-issues.md` filtered to `Source task == task_id` → `ledger.deferred_issues`; DR-5 stat `.aid/.temp/dashboard.log` + `.aid/.heartbeat/` → `logs` (`LogAvailability`: `task_logs=none` always per KI-008, server-log-present, heartbeat-present).
- Implement LC-SD (feature-003 server branch, both runtimes): parse the additive `?detail=<work_id>/<task_id>[,...]` query on the EXISTING `GET /api/model` route (no new route/path/verb — closed allowlist intact); pass the task-id list to the reader; attach a `details` map (present ONLY when the param is supplied; keys sorted ascending by `work_id/task_id` for parity); serialize deterministically (feature-003 DM-3, incl. U+2028/U+2029).
- LC-TR runs only on `?detail=` (always-on poll path untouched, NFR4); stays inside the audited read-only/no-LLM reader; best-effort null-tolerant; honest logs (never fabricate a task-log viewer, KI-008/DD-4).

**Acceptance Criteria:**
- [ ] `GET /api/model` (no param) omits the `details` key (always-on body unchanged, NFR4); `GET /api/model?detail=ids` attaches a `details` map with one `TaskDetail` per requested `work_id/task_id`, keys sorted for byte-parity.
- [ ] `TaskDetail` populates findings (severity/description/location/disposition/tier), ledger (delivery-level grade/tier/timestamp + the task's filtered deferred-`[HIGH]` rows — labeled a join, never "task grade"), `raw_state` (the work's STATE.md bytes reused, no re-read), and honest `logs` (`task_logs=none`, server-log/heartbeat stats — KI-008).
- [ ] LC-SD adds NO new route/path/verb to feature-003's closed two-route allowlist; stays GET-only, read-only, bound `127.0.0.1`; both runtimes byte-identical (held by task-036 PT-1).
- [ ] LC-TR runs only when a `task_id` is requested; the reader's no-write self-check still holds and now covers LC-TR; no agent/LLM (NFR2/NFR7).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit tests for the detail sub-parser + the `?detail=` branch public behavior added; existing tests pass; build passes (`schema_version` bump + parity is task-034/036).
