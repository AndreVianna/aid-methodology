# Execution Control (Pipeline Finish & Task Stop/Resume)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.2 (FR-PL2), §5.4 (FR-T3) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): cooperative stop-signal channel grounded in the heartbeat cadence; pipeline-finish uses the lifecycle field itself as the poll signal (no new writer); task stop/resume uses a new `.aid/.control/` per-task signal file + `write-control-signal.sh`; `task.stop`/`task.resume` registered on feature-001's OP_TABLE; additive derived `stop_requested` model field (no schema bump). OQ-PL2/OQ-T2 resolved (cooperative signal, no `Paused` enum). KI-008-A/B/C flagged in return. | /aid-specify |
| 2026-07-17 | Phase-2 re-check fix (worktree-awareness): feature-001 is now worktree-aware (`resolve_work_dir`, WT-1). Rebased the stop/resume signal TARGET and the `pipeline.finish` path onto `resolve_work_dir` output — Data Model, reader-derived `stop_requested`, §Layers reader/writer, API Contracts `task.stop`/`task.resume`/`pipeline.finish` rows, and the `write-control-signal.sh` contract no longer assume a reconstructed `<served-root>/.aid/works/<work_id>` path; the control dir now derives relative to the resolved work dir so it lands in the same worktree tree the executor polls. Cooperative stop-signal CHANNEL design (heartbeat-based) unchanged; "stopped" = `In Progress` + derived overlay unchanged. | /aid-specify |

## Source

- REQUIREMENTS.md §5.2 FR-PL2 (Finish pipeline)
- REQUIREMENTS.md §5.4 FR-T3 (Stop / Resume the running task)

## Description

Control the execution of running work from the dashboard. Finish a pipeline has two effects:
stop any executing task or skill, and mark the pipeline concluded (`lifecycle = Completed`).
Stop/Resume the running task pauses and resumes execution of the currently-running task only:
it cannot rerun a completed task (Done/Failed/Canceled) or start a not-yet-executed (Pending)
task, and the control is offered only while a task is actively executing. Both rely on a
cooperative stop-signal that the running agent (in a separate session) polls, because the
server cannot kill that session directly.

Depends on the write-infrastructure foundation (feature-001). This feature owns the
cooperative stop-signal channel shared by pipeline-finish and task-stop/resume; it is the
highest-uncertainty item in the work.

## User Stories

- As a developer running AID on my own project, I want to finish a running pipeline or
  stop/resume the task currently executing from the dashboard, so that I can halt or pause
  work in progress without killing the agent session by hand.

## Priority

Should

## Acceptance Criteria

- [ ] AC-EC1 — Given a running pipeline or task, when I finish it or stop/resume it from the
  dashboard, then the action is performed from the dashboard and persists to disk.
  (Feature-local criterion, derived from FR-PL2 / FR-T3 — both "Should" priority. This is
  NOT the REQUIREMENTS.md §9 AC1, whose enumerated closed P1 list excludes Finish and
  Stop/Resume; the shared "performed + persists" shape is intentional, the identifier is not.
  AC2 / AC3 / AC6 below do map directly to the same-numbered REQUIREMENTS.md ACs.)
- [ ] AC2 — Given a finish or stop/resume action, when the view re-renders, then it reflects
  the new on-disk state with no drift.
- [ ] AC3 — Given a state write (e.g. `lifecycle = Completed`), when it is persisted, then it
  goes through `writeback-state.sh` and no DERIVED section is hand-written.
- [ ] AC6 — Given a task, when it is the currently-running task, then the Stop/Resume control
  appears; for completed or pending tasks no rerun/start control is offered.

## Open Questions

- **OQ-PL2 / OQ-T2 — Stop mechanism — RESOLVED (2026-07-17, /aid-specify): cooperative
  file-signal polled at the heartbeat cadence.** The dashboard server is LLM-free (SEC-4) and
  cannot kill a separate agent session, so a cooperative signal is the only viable mechanism.
  **Two channels, both grounded in the existing heartbeat design** (file-based, no event bus,
  polled at `traceability.heartbeat_interval`): (a) **Pipeline Finish** uses the work's own
  `lifecycle` frontmatter field as the signal — the dashboard writes `lifecycle = Completed`
  via `writeback-state.sh` (already an `OP_TABLE` row from feature-001), and the executor,
  which already reads state on its dispatch-loop poll, treats any non-`Running` lifecycle as
  "stop, do not advance." No new writer/file for finish. (b) **Task Stop/Resume** uses a new
  per-task signal file under a gitignored `.aid/.control/` directory (sibling of
  `.aid/.heartbeat/`), written/removed by the new `write-control-signal.sh`; the executor stats
  it on the same poll and winds the task down cooperatively. State-only marking was rejected
  because the task enum has no way to express "one task paused while the pipeline keeps running"
  without inventing an enum value (see OQ-T2). See §Feature Flow and §Layers & Components.
- **OQ-T2 — "Stopped" state representation — RESOLVED (2026-07-17, /aid-specify): NO enum
  change; task stays `In Progress`, pause is a derived read-time flag.** The closed task `State`
  enum (`Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`) is NOT
  extended with a `Paused` value, and `Blocked` is NOT reused. Rationale: (1) a new `Paused`
  member forces lockstep template edits across all five profiles + a `writeback-state.sh` enum
  change + reader-twin parity work — disproportionate for a "Should" feature; (2) `Blocked` is
  reserved (per the closed `State` enum note in `.claude/aid/templates/work-state-template.md`
  ~line 210 — the canonical template source of the rule, echoed in CLAUDE.md) for an
  *orchestrator-assigned* downstream task that depends on a
  *failed* one — overloading it would collide semantically and with the orchestrator's own
  writes; (3) a pause-requested task genuinely *is* still `In Progress` (work unfinished, merely
  halted) so `In Progress` is the truthful state; (4) keeping the pause OUT of `STATE.md` means
  Resume leaves zero residue and a concurrent agent edit is never masked. The "paused" status
  is surfaced to the UI as an additive **derived** boolean `stop_requested`, computed at read
  time from the presence of the `.aid/.control/…` signal file (never persisted to STATE). See
  §Data Model and §State Machines.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature **consumes** the write
> mechanism delivered by **feature-001** (`features/feature-001-write-infrastructure/SPEC.md`) —
> the POST `OP_TABLE` dispatch, the `--allow-writes` / `write_enabled` gate, the child-process
> writer dispatch (server stays LLM-free per SEC-4 / no in-process fs-write per SEC-3), the
> reader-twin byte-parity discipline, and the truthful re-render contract. It does **not**
> re-invent any of them. It adds: (1) resolution of the cooperative stop/resume mechanism
> (OQ-PL2/OQ-T2), (2) one new writer (`write-control-signal.sh`), (3) two new `OP_TABLE` rows
> (`task.stop`, `task.resume`), (4) one additive derived model field (`stop_requested`), and
> (5) an executor-side poll contract for `aid-execute`.
>
> **Grounding anchors:** single writer `.claude/aid/scripts/execute/writeback-state.sh`
> (`--pipeline --field Lifecycle --value Completed`; `--pipeline --field` usage block lines
> ~119–132; Lifecycle enum validated line ~1375, incl. `Completed`; closed task `State` enum
> line ~753); heartbeat channel
> `.claude/aid/templates/subagent-heartbeat-protocol.md` (`.aid/.heartbeat/`, gitignored;
> `read-setting.sh --path traceability.heartbeat_interval --default 1`); executor poll loop
> `.claude/skills/aid-execute/references/state-execute.md` (~line 349, "read heartbeat files for
> each in-flight task"); reader model `dashboard/reader/models.py` `TaskModel` (line 233) +
> serializer `dashboard/server/server.py` `_ser_task` (line 604) and its Node twin
> `dashboard/server/reader.mjs` `_buildTaskModel` (line 4347); UI `dashboard/home.html`
> `makeTaskChip` (line 2590), `makeLifecycleBadge` (line 2651), `makeTaskStatusBadge` (line
> 2673); SEC-3/SEC-4 `.aid/knowledge/integration-map.md` (line 267); work-level lifecycle enum
> `STATE.md` (line 41).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The store is the on-disk `.aid/` artifact set + a new gitignored control-signal file; plus one additive derived model field. No relational schema. |
| Feature Flow | Present | The finish and stop/resume round-trips (POST → gate → dispatch → writer → re-fetch) plus the executor poll are the core of the feature. |
| Layers & Components | Present | Server op handlers, a new writer, a reader-derived flag, the executor poll, and UI controls all change. |
| API Contracts | Present | Two new `OP_TABLE` rows (`task.stop`/`task.resume`) + the `pipeline.finish` consumption + the `write-control-signal.sh` contract. |
| Security Specs | Present | SEC-3/SEC-4 preserved (mutation via a child writer, no LLM), the inherited `write_enabled` gate, signal-path traversal defenses, and the `.aid/.control/` gitignore. |
| State Machines | Present | Resolves the OQ-T2 enum question: no new `Paused` value; a stopped task stays `In Progress` with a derived overlay. |
| UI Specs | Present | Pipeline Finish + Task Stop/Resume controls, their `write_enabled` gating, AC6 visibility gating, and the re-render. |
| Migration / New Plumbing | Present | New co-vendored writer (via `dashboard/MANIFEST`), additive derived field (no schema bump), `.aid/.control/` gitignore, and the `aid-execute` poll change. |
| Events & Messaging | N/A | The stop/resume "channel" is a polled gitignored file, not an event bus/queue; specified under Feature Flow, not a messaging middleware. |
| Telemetry & Tracking | N/A | Single-user trust model; no audit requirement. Writer prints `OK:`/errors to stderr — sufficient. |
| DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback file-mutation feature over the on-disk `.aid/` store. |

### Data Model

**No database.** Two on-disk artifacts back this feature; one model field is derived from them:

| Artifact | Purpose | Owner / writer | Persisted? |
|----------|---------|----------------|-----------|
| `<resolved-work-dir>/STATE.md` frontmatter `lifecycle` | Pipeline Finish signal + persisted lifecycle (`Completed`) | `writeback-state.sh --pipeline --field Lifecycle` (existing) | Yes — `STATE.md` (AUTHORED frontmatter; never DERIVED, C2) |
| `<resolved-work-dir>/../../.control/<work_id>/task-<NNN>.stop` | Per-task cooperative pause request (presence = pause requested) | `write-control-signal.sh` (**new**, feature-008) | Yes — but a **control artifact**, NOT `STATE.md` (see C1 scope below) |

**`<resolved-work-dir>` is feature-001's worktree-aware `resolve_work_dir` output — NOT a reconstructed
served-tree path (WT-1).** Both artifacts hang off the exact on-disk directory
`resolve_work_dir(served_root, work_id)` returns (feature-001 §Layers component 3), which is the very
copy the reader rendered. The server feeds that resolved dir into `AID_WORK_DIR` for **both**
`pipeline.finish` (→ `writeback-state.sh`) and `task.stop`/`task.resume` (→ `write-control-signal.sh`),
exactly as feature-001 dispatches every pipeline-scoped op (feature-001 §Feature Flow steps 6/8, §API
Contracts). The control file is derived **relative to that resolved work dir** —
`<resolved-work-dir>/../../.control/<work_id>/` is the `.aid/.control/<work_id>/` sibling of the
resolved dir's own `.aid/works/`, so it always lands in the SAME worktree tree the executor polls. For
work-017's own worktree topology the resolved dir is
`.claude/worktrees/<wt>/.aid/works/<work_id>/`, so the signal correctly lands in that worktree's
`.aid/.control/`. A literal `<served-root>/.aid/works/<work_id>` (the reconstructed path WT-1 forbids,
and that feature-001 SPEC line 280-281 explicitly directs feature-008 to avoid) would silently `mkdir`
the `.stop` signal in the wrong `.aid/` tree while the executor polls its own worktree's
`.aid/.control/` — a no-op stop the dashboard would falsely report as succeeding.

**Residual assumption (flagged, KI-008-D).** Routing through `resolve_work_dir` makes the dashboard
target the reconcile **winner** (newest-`updated` copy). The design relies on that winner being the
copy whose executor session is actually running — which holds in practice because an actively
executing pipeline continuously rewrites its own `STATE.md` (heartbeats, task transitions), so it is
by construction the newest-`updated` copy. The one pathological case is a `work_id` duplicated across
worktrees where a *stale* copy is somehow newer than the running one; then the signal would land in
the winner while a non-winner executor polls elsewhere. It is a narrow, self-limiting edge (the
running copy normally wins) and is called out as a low-severity documentation KI, not an MVP gate.

**New derived model field (additive):** a single boolean **`stop_requested`** is added to `TaskModel`
(`dashboard/reader/models.py` line 233, after `lane`) and to its serializer `_ser_task`
(`server.py` line 604) + the Node twin (`reader.mjs` `_buildTaskModel`, line 4347). It is **derived
at read time** — the reader stats the control file at `<walked-work-dir>/../../.control/<work_id>/task-<NNN>.stop`
(the `.aid/.control/` sibling **within the same worktree copy it is already walking**, never
`<served-root>/.aid/.control/…`) and sets the flag to that presence; deriving relative to the walked
work dir keeps the flag reading the identical tree the writer and executor act on (WT-1). It is
**never parsed from or written to `STATE.md`** (consistent with the reader's existing derived fields
such as `status`). Both twins
perform the identical `stat` (no `STATE.md` parser change), so DM byte-parity (AC4) is preserved by
construction.

**C1 scope note.** C1 ("all dashboard-initiated Pipeline/Task STATE writes go through
`writeback-state.sh`") governs `STATE.md`. The **only** `STATE.md` write in this feature is
`pipeline.finish` → `lifecycle = Completed`, which does go through `writeback-state.sh` (AC3). The
per-task `.stop` signal is a **new control-artifact class** (like the `.aid/.heartbeat/` files),
not `STATE.md`, so C1 does not reach it — but it is still written by a dispatched child process, not
in-process, to honor SEC-3 (see §Security Specs).

**Envelope / schema version.** Following feature-001's `write_enabled` precedent and the DM-A3
(task-064) / RC-2 no-bump rule, `stop_requested` is purely additive and **does not** bump
`schema_version` (DM-1 stays 3). Golden fixtures for the twin parity suites are regenerated in
lockstep.

### Feature Flow

**Two dashboard actions and one executor poll. `[F-*]` = feature-001-defined step, reused verbatim.**

```
A. PIPELINE FINISH (FR-PL2)
───────────────────────────
Browser (home.html)                         Server (server.py | server.mjs)       Executor session (aid-execute)
user clicks "Finish" on a work card
  │ (control shown only when work.lifecycle=='Running' && model.write_enabled)
  ▼
POST /r/<id>/api/op                    [F-*]  Host allowlist → write gate → OP_TABLE
  {op:"pipeline.finish",                      dispatch: writeback-state.sh
   target:{work_id}}                            --pipeline --field Lifecycle --value Completed
                                               (value FIXED to Completed by feature-001)
  ◀── 200 {ok:true} ──────────────────[F-*]
  ▼ re-fetch GET /r/<id>/api/model → lifecycle now "Completed" (AC2, truthful)
                                                                          ┌── on its next dispatch-loop
                                                                          │   poll tick, re-reads STATE.md
                                                                          │   lifecycle; sees != Running ⇒
                                                                          │   STOP: dispatch no new tasks,
                                                                          │   let in-flight sub-agents reach
                                                                          │   their next safe checkpoint,
                                                                          └── do not advance the pipeline.

B. TASK STOP / RESUME (FR-T3)
─────────────────────────────
user clicks "Stop" (or "Resume") on an In-Progress task chip
  │ (control shown only when task.status=='In Progress' && model.write_enabled; label = stop_requested?Resume:Stop)
  ▼
POST /r/<id>/api/op                    [F-*]  Host allowlist → write gate → OP_TABLE
  {op:"task.stop"|"task.resume",              dispatch: write-control-signal.sh
   target:{work_id,task_id}}                    --task-id <NNN> --action stop|resume
                                               stop  → create .aid/.control/<work_id>/task-<NNN>.stop
                                               resume→ rm -f    .aid/.control/<work_id>/task-<NNN>.stop
  ◀── 200 {ok:true} ──────────────────[F-*]
  ▼ re-fetch GET /r/<id>/api/model → task.stop_requested now true/false (AC2)
                                                                          ┌── on its poll tick, stats the
                                                                          │   .stop file for each in-flight
                                                                          │   task; present ⇒ PAUSE that task
                                                                          │   (no next reviewer/fix cycle
                                                                          │   dispatched; running sub-agent
                                                                          │   winds down at its heartbeat
                                                                          │   tick); absent again ⇒ resume.
                                                                          └── Task State stays In Progress.
```

**The cooperative channel, grounded in the heartbeat design.** Two poll hooks, both riding ticks
that already fire in the running session — so no new poll infrastructure is introduced:

- **Baseline — the orchestrator `aid-execute` (required, narrow blast radius).** At every
  task-dispatch boundary (between tasks / between reviewer-fix cycles) and at its existing
  heartbeat-read point (`state-execute.md` ~line 349, where it already reads in-flight heartbeat
  files), it re-reads the work `lifecycle` and stats each in-flight task's `.stop` file, then
  declines to dispatch new work / new reviewer cycles accordingly. This alone delivers cooperative
  stop; the only edit is to `state-execute.md` (+ its renders). Consequence: stop takes effect at the
  **next boundary**, not necessarily mid-task.
- **Enhancement — the executing sub-agent (recommended, broader blast radius).** A long-running task
  sub-agent already wakes every `traceability.heartbeat_interval` minutes to *write* its
  `.aid/.heartbeat/` line (`subagent-heartbeat-protocol.md` §"Subagent-side responsibilities": "Every
  N minutes of work … write a single-line status"). Extending that contract so the sub-agent, at the
  same tick, also stats **its own** `.stop` file and re-reads `lifecycle` — halting at the next safe
  checkpoint — gives **mid-task** responsiveness at exactly `heartbeat_interval` cadence. So a
  sub-agent can identify **which** `.stop` path is its own (and **whether** it has one at all), the
  orchestrator passes an opt-in dispatch parameter directly analogous to `HEARTBEAT_FILE=…` — a
  `STOP_FILE=.aid/.control/<work_id>/task-<NNN>.stop` line added to the dispatch prompt. An absent
  `STOP_FILE` disables the stop-poll for that sub-agent exactly as an absent `HEARTBEAT_FILE`
  disables heartbeat (no sub-agent ever guesses its own control path; un-updated dispatch sites are
  unaffected). This edit touches the sub-agent contract (`subagent-heartbeat-protocol.md` + the agent
  boilerplate, which would gain the `STOP_FILE` parameter alongside `HEARTBEAT_FILE`) across all
  profiles, so it is scoped as a follow-on enhancement, not the MVP gate (see §Migration).

The control channel deliberately mirrors the heartbeat channel's proven properties
(`subagent-heartbeat-protocol.md` §"Why this design"): pure file-based, no event stream, no
host-tool cooperation, gitignored, works on every host — only two extra reads at ticks that already
fire. The interval is read the same way the heartbeat does:
`read-setting.sh --path traceability.heartbeat_interval --default 1`.

**Poll cadence degradation.** If heartbeat is disabled (`traceability.heartbeat_interval: 0`), the
sub-agent has no per-N-minute write tick; stop then takes effect at the orchestrator's next
task-dispatch **boundary** (between tasks / reviewer cycles) rather than mid-task. Stop still takes
effect — just less promptly. Documented, not a failure.

### Layers & Components

**1. Server layer** (`dashboard/server/server.py` + `server.mjs`, byte-parity twins) — **reuses
feature-001's router + gate + dispatch unchanged.** This feature only appends `OP_TABLE` rows
(below). No new endpoint, no new routing branch, no change to the `write_enabled` enforcement point.
The `pipeline.finish` row already exists (feature-001); `task.stop` / `task.resume` are new rows
whose declared writer is `write-control-signal.sh`.

**2. Writer layer:**

- `writeback-state.sh` — **existing, unchanged.** Invoked for `pipeline.finish` exactly as
  feature-001 specifies (`--pipeline --field Lifecycle --value Completed`, env `AID_STATE_FILE`,
  `AID_WORK_DIR` — both pointed at feature-001's `resolve_work_dir` output, worktree-aware, never a
  reconstructed served-tree path per WT-1). `Completed` is already a member of the Lifecycle enum the
  script validates.
- `write-control-signal.sh` — **new (feature-008-owned).** Co-vendored with the dashboard unit and
  self-located from `$AID_CODE_HOME`, added by a one-line edit to `dashboard/MANIFEST` (the
  single-source mechanism feature-001 established; guarded by
  `tests/canonical/test-dashboard-manifest.sh`). Contract in §API Contracts. It is the only process
  that touches `.aid/.control/` (create on stop, `rm -f` on resume) — the server never does fs
  mutation itself (SEC-3).

**3. Reader / model layer** (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`): **no
`STATE.md` parser change.** The single change is the additive **derived** `stop_requested` field
(see §Data Model) — a filesystem `stat` of the control file performed identically in both twins
while assembling each work's tasks. The control root is derived from **the resolved/enumerated work
dir the reader is currently walking** (`<walked-work-dir>/../../.control/<work_id>/`, worktree-aware —
never a reconstructed `<served-root>/.aid/.control/<work_id>/`), so the reader stats the same tree the
writer targets and the executor polls (WT-1); a missing directory ⇒ all tasks `stop_requested=false`
(fail-safe, never throws — mirrors the reader's forward-compat posture).

**4. Executor layer** (`aid-execute` — `canonical/skills/aid-execute/references/state-execute.md`
+ the 5 profile renders + dogfood `.claude/`): **the load-bearing consumer**, per the two-hook
model in §Feature Flow. **Baseline (required):** the orchestrator, at each task-dispatch boundary and
at its existing heartbeat-read point, re-reads `lifecycle` (not `Running` ⇒ stop dispatching, do not
advance — Pipeline Finish) and stats each in-flight task's `.stop` file (present ⇒ dispatch no next
reviewer/fix cycle for it — Task Stop; absent again ⇒ resume). **Enhancement (recommended):** the
executing sub-agent polls the same two signals at its own `heartbeat_interval` write tick for
mid-task responsiveness (broader blast radius — the sub-agent contract). Task `State` is never
mutated by a pause. These edits are additive (new reads at ticks that already fire) and must be
rendered to all profiles in lockstep. **Note (scope / risk):** the dashboard-side write (server +
writer + reader + UI) fully satisfies AC-EC1/AC2/AC3/AC6 on its own; the executor edit is what makes the
raised signal *effective*. Its blast radius (canonical skill + 5-profile render + dogfood + parity) is
the single largest risk in this work and is called out as a separate deliverable — see §Migration
and the return.

**5. UI gating layer** (`dashboard/home.html`) — controls rendered only when
`model.write_enabled === true` (feature-001 gate) and gated further per §UI Specs; re-fetch on op
success (feature-001 re-render contract).

### API Contracts

**No new endpoints.** Both actions ride feature-001's `POST /r/<id>/api/op` (per-repo) with the
feature-001 request/response envelope, gate, status map, and validation. This feature registers two
`OP_TABLE` rows and consumes one existing row:

| `op` | Scope | Writer + argv | Owning FR | Introduced by |
|------|-------|---------------|-----------|---------------|
| `pipeline.finish` | per-repo | `writeback-state.sh --pipeline --field Lifecycle --value Completed` (value fixed; env `AID_STATE_FILE`/`AID_WORK_DIR` = feature-001 `resolve_work_dir` output, worktree-aware — WT-1) | FR-PL2 (state half) | feature-001 (**consumed** here; the "stop executing work" half is the executor's lifecycle poll — no extra writer) |
| `task.stop` | per-repo | `write-control-signal.sh --task-id <NNN> --action stop` (env `AID_WORK_DIR` = feature-001 `resolve_work_dir(served_root, work_id)` output — the real worktree-resolved dir per WT-1, **never** a reconstructed `<served-root>/.aid/works/<work_id>` path) | FR-T3 | **feature-008** |
| `task.resume` | per-repo | `write-control-signal.sh --task-id <NNN> --action resume` (env `AID_WORK_DIR` = feature-001 `resolve_work_dir(served_root, work_id)` output — the real worktree-resolved dir per WT-1, **never** a reconstructed `<served-root>/.aid/works/<work_id>` path) | FR-T3 | **feature-008** |

`task.stop`/`task.resume` are **pipeline-scoped** (require `target.work_id`, validated `^work-[0-9]+`
+ dir-exists per feature-001) and require `target.task_id` (`^\d{1,3}$`, per feature-001). `args` is
empty (`{}`) for both — the action is encoded in the op name, not a client value, so no lifecycle or
free string is ever forwarded (keeps general task-state editing closed, mirroring how feature-001
fixed `pipeline.finish`'s value to `Completed`).

**`write-control-signal.sh` contract** (new):

```
write-control-signal.sh --task-id <NNN> --action <stop|resume> [env AID_WORK_DIR=<abs work dir>]
```
- Target work dir: `AID_WORK_DIR` if set, else `<cwd>`. **The server sets `AID_WORK_DIR` to
  feature-001's `resolve_work_dir` output — the worktree-aware real dir (WT-1), never a reconstructed
  served-tree path.** The control dir is derived **relative to that work dir** as
  `<work_dir>/../../.control/<work_id>` (i.e. the `.aid/.control/<work_id>/` sibling of the work dir's
  own `.aid/works/`, inside whatever worktree the resolver selected), where `<work_id>` is the work
  dir's basename. Deriving relative to `AID_WORK_DIR` — not to a served root — is precisely what keeps
  the signal in the SAME tree the executor polls. `--task-id` validated `^[0-9]{1,3}$` → exit 4
  otherwise; normalized to `task-<zero-padded-3>` (matching `writeback-state.sh`'s own padding).
- `--action stop`: `mkdir -p` the control dir; atomically create
  `.aid/.control/<work_id>/task-<NNN>.stop` (temp-file + `mv`) containing one informational line
  `[<ISO-8601 UTC>] stop | source=dashboard` (presence is the signal; contents are advisory).
  Idempotent (re-stop is a no-op success).
- `--action resume`: `rm -f` that file (idempotent; removing an absent file is success, exit 0).
- Never touches `STATE.md`, the work folder's tracked contents, git, or any worktree.
- Exit codes reuse the writeback alphabet: `0` ok; `2` IO/lock-class failure; `4` invalid arg value;
  `5` missing required arg. The server maps these to HTTP exactly as feature-001's table does
  (`4/5 → 422`, `2 → 409`, other → 500). `bash`-only (as the other writers are).

### Security Specs

**Inherited from feature-001 (unchanged):** the `--allow-writes` / `write_enabled` gate is the AC8
enforcement point — `task.stop`/`task.resume`/`pipeline.finish` are all mutations and are refused
(HTTP 403 `read-only`) unless the server was spawned write-enabled. The SEC-6 Host-header allowlist
runs before the gate on the POST path. No new endpoint, port, or listener (C3).

**Preserved invariants:**

- **SEC-3 (refined, not broken).** The server still contains **no in-process fs primitive** — it
  neither creates nor `unlink`s the `.aid/.control/` files. Both stop (create) and resume (`rm -f`)
  happen inside `write-control-signal.sh`, a dispatched child process invoked with an **argv array**
  (never `shell=True` / concatenated string). The server-file audit (`grep` for `open(...,'w')` /
  `writeFileSync` / `appendFile` / `unlink` / `os.remove`) stays empty. The reader's `stat` of the
  control file is a **read**, not a mutation.
- **SEC-4 (unchanged).** No agent/LLM import in the server; the dispatched child is a shell script.
  The cooperative design exists *because of* SEC-4 — the LLM-free server cannot kill the agent
  session, so it can only raise a signal a separate session polls.
- **Injection / traversal.** `op` from the closed `OP_TABLE`; `work_id`/`task_id` regex-validated by
  the server before spawn (feature-001); the repo path resolved server-side from `id_map`, never
  from the body; `write-control-signal.sh` re-validates `--task-id` (`^[0-9]{1,3}$`) and builds the
  filename from the normalized `task-<NNN>` token only — no client string reaches a path segment, so
  `../` traversal into or out of `.aid/.control/` is impossible.

**Gitignore requirement.** `.aid/.control/` holds ephemeral runtime artifacts and MUST be
gitignored, exactly like `.aid/.heartbeat/` (`subagent-heartbeat-protocol.md` §"File lifecycle").
The live exclusion mechanism is the `.gitignore` "AID managed" block (delimited
`# >>> AID managed … >>>` / `# <<< AID managed <<<`, maintained by `aid add`/`aid update`), which
already lists `.aid/.heartbeat/`; `.aid/.control/` should be added there alongside it. (There is no
`/aid-config`-driven gitignore step — `aid-config` has only its two view/update modes.) Flagged as a
follow-up (see §Migration); a resume that leaves an empty
`.aid/.control/<work_id>/` directory is harmless if it were ever committed, but the gitignore keeps
the tree clean.

### State Machines

**No new state-machine and no enum change — this section records the OQ-T2 decision.** The closed
task `State` enum (`Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`,
`writeback-state.sh` line ~753) is left intact. A stop-requested task **remains `In Progress`**; the
"paused" condition is an orthogonal, derived overlay (`stop_requested`, from the control-file
presence) — not a state value. Transitions are therefore unchanged:

- Pipeline: the dashboard drives only `Running → Completed` (via `pipeline.finish`; `Completed` is an
  existing terminal member of the work Lifecycle enum, `STATE.md` line 41). No `Paused-Awaiting-Input`
  is used here — Finish is terminal, not a pause.
- Task: `In Progress → In Progress` with `stop_requested` toggling true/false. The executor's own
  normal transitions (`In Progress → In Review → Done/Failed`) are untouched; a pause merely defers
  the *next* transition until Resume, and never writes a state itself.

Rejected alternatives are enumerated in the resolved OQ-T2 above (new `Paused` member; reuse of
`Blocked`).

### UI Specs

Grounded in `dashboard/home.html`'s existing factories; both controls are **write controls** and
render only when `model.write_enabled === true` (feature-001 signal) and re-fetch
`/r/<id>/api/model` on op success (feature-001 re-render contract).

- **Pipeline Finish (FR-PL2).** A "Finish" action on the **work / pipeline card** (the same card that
  carries `makeLifecycleBadge`, `home.html` line 2651). Visible only when `work.lifecycle === 'Running'`
  (finishing a `Completed`/`Canceled`/`Blocked` pipeline is meaningless) **and** `write_enabled`. It
  posts `{op:"pipeline.finish", target:{work_id}}`. Because Finish is terminal and irreversible from
  the dashboard's side, it uses a lightweight confirm ("Finish this pipeline? This marks it
  Completed and stops any running work.") — a plain confirm, distinct from FR-PL3 Delete's strong
  destructive guard (feature-009). On success the re-fetch shows the `Done` lifecycle badge
  (`LIFECYCLE_MAP['Completed']`, line 2656).

- **Task Stop/Resume (FR-T3, AC6).** A single toggle control added to the **task chip**
  (`makeTaskChip`, `home.html` line 2590) — and mirrored on the task drill view (SEAM-2 route
  `#/work/<id>/task/<tid>`, line ~2600) for discoverability. **AC6 visibility gate:** the control
  renders **iff `task.status === 'In Progress'`** (FR-T3's "execution of the currently running task")
  **and** `write_enabled`. For `Pending`, `Blocked`, `Done`, `Failed`, `Canceled` tasks **no control
  is rendered** — there is no rerun/start affordance anywhere (AC6). **`In Review` is deliberately
  excluded**: although the existing chip logic paints both `In Progress` and `In Review` as "active"
  (`home.html` lines 2334 / 2608), FR-T3 scopes Stop/Resume to *task execution*, and an `In Review`
  task's executor has already finished (a reviewer sub-agent is what is running) — stopping a review
  is out of scope. This narrows the gate below the codebase's "active" set on purpose (flagged as a
  minor interpretation in the return). The control **label/action flips on `task.stop_requested`**:
  `false` ⇒ "Stop" → posts `task.stop`; `true` ⇒ "Resume" → posts `task.resume`. A paused
  (`stop_requested===true`) chip also shows a small "paused" pill (a decorative glyph badge in the
  `makeTaskStatusBadge` family, line 2673) so the state is legible at a glance without changing the
  status badge itself. On op success the re-fetch re-derives `stop_requested` from disk (AC2).

- **Gating recap (defense-in-depth).** The UI hides a control it cannot use (`write_enabled===false`
  ⇒ no Finish/Stop/Resume), and the server independently refuses the op (403) — so a hand-crafted
  request under `--remote` without `--allow-writes` still fails closed.

### Migration / New Plumbing

- **New co-vendored writer.** `write-control-signal.sh` ships inside the dashboard unit
  (self-located from `$AID_CODE_HOME`), added by **editing `dashboard/MANIFEST` only** — the
  single-source mechanism feature-001 established (`vendor.js`/`vendor.py`/`install.sh`/`install.ps1`/
  `release.sh` all derive from it; `tests/canonical/test-dashboard-manifest.sh` guards drift).
- **Additive derived field `stop_requested`.** No `schema_version` bump (feature-001 `write_enabled`
  / DM-A3 / RC-2 precedent). Twin serializers + golden parity fixtures regenerated in lockstep (AC4).
- **`.aid/.control/` gitignore.** Add to the `.gitignore` "AID managed" block (the delimited
  `# >>> AID managed … >>>` region maintained by `aid add`/`aid update`) next to `.aid/.heartbeat/`.
  **KB/plumbing follow-up (flagged for the human).**
- **Executor poll change — the largest, highest-risk deliverable (flagged for the human).**
  *Baseline (required for the feature to bite):* `state-execute.md` (canonical) + 5 profile renders +
  dogfood `.claude/` gain the orchestrator's two poll reads (lifecycle + `.stop` stat) at the
  existing dispatch boundary / heartbeat-read point. *Enhancement (recommended, separable):* the
  sub-agent contract (`subagent-heartbeat-protocol.md` + agent boilerplate, all profiles) gains the
  mid-task poll at each `heartbeat_interval` tick, driven by a new opt-in `STOP_FILE=…` dispatch
  parameter (directly analogous to `HEARTBEAT_FILE=…`; absent ⇒ no stop-poll). Both are additive but
  carry a broad render-lockstep
  + parity blast radius; they are the reason this feature is the highest-uncertainty item in the work.
- **No data migration.** Existing `.aid/` state is read/written in place; `writeback-state.sh` is
  untouched; the control channel is new files only.

### How the Acceptance Criteria are satisfied

- **AC-EC1 (action performed from dashboard + persists).** Finish posts `pipeline.finish`, persisting
  `lifecycle = Completed` to `STATE.md` frontmatter (durable). Stop/Resume posts `task.stop`/
  `task.resume`, persisting/removing the `.aid/.control/<work_id>/task-<NNN>.stop` file (durable on
  disk). Both are initiated entirely from the dashboard.
- **AC2 (truthful re-render, NFR3).** Each op returns feature-001's `{ok:true}` and the client
  immediately re-fetches `/r/<id>/api/model`; Finish then shows `lifecycle: Completed`, and
  Stop/Resume then shows the re-derived `stop_requested` — both read from disk, so no drift.
- **AC3 (single-writer intact, C1+C2).** The only `STATE.md` write (`lifecycle = Completed`) goes
  through `writeback-state.sh` and touches a frontmatter scalar only — no DERIVED view is written.
  The `.stop` signal is a non-`STATE` control artifact, outside C1's scope, and is written by a
  dispatched child process (SEC-3), never by the server in-process.
- **AC6 (Stop/Resume gating).** The control renders iff `task.status === 'In Progress'` and
  `write_enabled`; every other task status renders no control, so completed/pending tasks offer no
  rerun/start affordance. The Stop↔Resume label is driven by the derived `stop_requested`.
- **AC4 (reader-twin parity, inherited).** The one reader change is an additive derived field
  computed by an identical filesystem `stat` in both twins (no `STATE.md` parser change), guarded by
  the existing cross-runtime parity suites with fixtures regenerated together.
- **AC8 (trust model, inherited).** All three ops are mutations gated by feature-001's
  `write_enabled` (loopback ⇒ enabled; `--remote` ⇒ read-only unless `--allow-writes` + tailnet
  ACL); no new network surface (C3).
