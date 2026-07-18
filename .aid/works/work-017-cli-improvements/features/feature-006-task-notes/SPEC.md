# Task Notes Edit

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.4 (FR-T2) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): `task.set-notes` argv-builder + arg-schema on feature-001's OP_TABLE; Notes card + inline edit in home.html task drill view (write_enabled-gated); empty→`--` clear semantics resolved; no new plumbing, no reader/serializer change. | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW): (1) flagged + reconciled the `target.task_id` regex divergence with feature-001 (superset accepts prefixed `task-NNN` and bare `NNN`, normalizes to bare numeric); (2) added exit 5 → 422 (`resolve_delivery_for_task_mode` unresolvable-delivery path, writeback-state.sh line 438) to §API Contracts reachable exit-code enumeration. | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW, cycle 3): layout-qualified the exit 1 → 404 claim in §API Contracts and documented the flat-layout task-existence asymmetry — `write_task_field_flat` (writeback-state.sh line 823–936) has no task-row existence check and silently auto-creates a phantom row (exit 0/200) for a non-existent `task_id`, vs. nested's exit-1/404 die (line 770–772); noted the `renderTaskView` "Task not found" UI mitigation (line 2945–2954) and the non-UI / delete-race exposure, flagged as a feature-001 writer cleanup. | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW, Phase-2 — worktree-awareness): reconciled the write-target derivation with feature-001's re-opened **WT-1** invariant. Replaced every reconstructed served-tree `<repo>/.aid/works/<work_id>` derivation of `AID_STATE_FILE`/`AID_WORK_DIR` (Feature Flow, Writer layer, Op scope, argv-builder env, API path-derivation paragraph, Injection defenses, AC1) with feature-001's worktree-aware `resolve_work_dir(repo, work_id)` output; added `resolve_work_dir`/WT-1 references to the grounding anchors, Open-Questions inherited-list, and Server-layer inherited-list. No served-tree path is assumed; the resolver is feature-001's (OP_TABLE `task.set-notes` row, feature-001 SPEC.md:349), consumed verbatim. | /aid-specify |

## Source

- REQUIREMENTS.md §5.4 FR-T2 (Edit notes)

## Description

Let the user edit a task's `notes` field from the dashboard. The write goes through
`writeback-state.sh` (the single writer), targeting the task's authored `notes` cell — a
dashboard edit is indistinguishable from an agent edit at the write layer, and no DERIVED
view is hand-written.

Depends on the write-infrastructure foundation (feature-001) for the `writeback-state.sh`
wiring and the server write endpoints.

## User Stories

- As a developer running AID on my own project, I want to edit a task's notes from the
  dashboard, so that I can jot context on a task without editing its state file by hand.

## Priority

Must

## Acceptance Criteria

- [ ] AC1 — Given a task, when I edit its notes from the dashboard, then the change is
  performed from the dashboard and persists to disk.
- [ ] AC2 — Given a notes edit is saved, when the view re-renders, then it reflects the new
  on-disk notes with no drift.
- [ ] AC3 — Given the notes write, when it is persisted, then it goes through
  `writeback-state.sh` and no DERIVED section is hand-written.

## Open Questions

- **No feature-local design questions.** The write mechanism (server op endpoints, the
  `--allow-writes`/`write_enabled` gate, the worktree-aware `resolve_work_dir` target resolution
  (WT-1), child-process writer dispatch, the truthful re-render contract, and the `task.set-notes`
  OP_TABLE row itself) is fully specified by the foundation feature-001 and consumed verbatim here. FR-T2 is a single-field edit through the *existing*
  single writer (`writeback-state.sh --field Notes`), which already parses/round-trips the notes
  cell — no new plumbing, no reader/parser/serializer change.
- **Resolved micro-decision (this spec) — "clear notes" semantics.** `writeback-state.sh` rejects
  an empty `--value` (exit 5, "value is required"), so it cannot persist a literally-empty notes
  string. The op's argv-builder therefore substitutes the null sentinel `--` when the client sends
  an empty `value`; the reader twins already treat `--`/`-`/`—`/`""` as null (`reader.mjs`
  `NULL_SENTINELS`, line 122), so "clear" round-trips to a rendered-empty notes without any change
  to the unchanged single writer. See §API Contracts.
- **Resolved micro-decision (this spec) — single-line, no-pipe value.** The flat-layout notes home
  is a markdown table cell, so `writeback-state.sh` `mode_field` rejects `|` and newlines in
  `--value` (exit 4, lines 733/738). The notes control is a single-line `<input>`, and the op
  arg-schema rejects `|`/newline at validation (422) before any spawn — mirroring the writer.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This is the **smallest** consuming
> feature: a single task-field edit that rides entirely on the feature-001 foundation. It adds
> (1) the concrete argv-builder + arg-schema for the `task.set-notes` row feature-001 seeded on the
> server `OP_TABLE` (both twins), and (2) a write-gated Notes control in the `home.html` task drill
> view. It introduces **no** new writer, endpoint, gate, envelope key, or reader/parser/serializer
> change — those are feature-001's, consumed verbatim.
>
> **Grounding anchors:** foundation spec
> `features/feature-001-write-infrastructure/SPEC.md` (write mechanism, gate, OP_TABLE,
> `write_enabled`, worktree-aware `resolve_work_dir` + invariant WT-1, re-render contract,
> SEC-1/3/4/6); single writer
> `.claude/aid/scripts/execute/writeback-state.sh` (`mode_field` lines ~731–808;
> `write_task_field_flat` lines ~823–960; exit codes lines 142–149); reader twins
> `dashboard/reader/models.py` (`TaskModel.notes`, line 251) + `dashboard/server/reader.mjs`
> (`RE_TS_NOTES` line 3148; `NULL_SENTINELS` line 122; `FREETEXT_FM_KEYS` line 160;
> `_buildTaskModel` notes line 4357); serializers `dashboard/server/server.py` `_ser_task`
> (`notes`, line 613); UI `dashboard/home.html` (`renderTaskView` line 2877; `makeTaskChip`
> line 2590; `doFetch` line 1033 / `onSuccess` line 1067 / `renderModel` dispatch line ~1210;
> `EXPECTED_SCHEMA_VERSION = 3`, line 926; `./api/model` poll, line 1042).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The write target is one on-disk cell — the task `notes` field; two physical homes (nested frontmatter key vs flat `### Tasks lifecycle` row), both owned by `writeback-state.sh`. |
| Feature Flow | Present | The edit → POST `task.set-notes` → gate → dispatch → writer → re-fetch round-trip is the feature; thin, delegating to feature-001. |
| Layers & Components | Present | Server (OP_TABLE row), writer (unchanged), reader (unchanged), UI (drill-view Notes control) — only two of the four actually change. |
| API Contracts | Present | The concrete `task.set-notes` argv-builder + arg-schema + target resolution registered on feature-001's OP_TABLE. |
| Security Specs | Present (thin) | Inherits feature-001's write gate (`write_enabled`/403), SEC-3/4/6; feature-local charset/length arg validation. |
| UI Specs | Present | A `write_enabled`-gated Notes card + inline editor in the `home.html` task drill view, grounded in existing card/kicker/`btn-ghost`/badge patterns. |
| Migration / New Plumbing | N/A | No new writer, endpoint, gate, envelope key, or fixture change — all inherited from feature-001; the `notes` field is already parsed, serialized, and writable today. |
| State Machines | N/A | `notes` is free text, not an enum; no lifecycle transition. |
| Telemetry & Tracking | N/A | Single-user trust model; the writer's `OK:` line + server stderr on failure (feature-001) suffice; no audit requirement. |
| Data Model (DB), Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a single-field loopback file edit. |

### Data Model

**No database.** The single write target is the task's `notes` cell, which has two physical homes
depending on the work layout (`writeback-state.sh` auto-detects and writes the correct one; both are
AUTHORED, never DERIVED — C2):

| Layout | Physical home of `notes` | Written by |
|--------|--------------------------|------------|
| Full-nested (`deliveries/delivery-NNN/tasks/task-NNN/STATE.md`) | the flat top-level `notes:` **frontmatter** key (a `FREETEXT_FM_KEYS` scalar — `reader.mjs` line 160) | `writeback-state.sh` `mode_field` → `wb_set_frontmatter` (surgical YAML rewrite; body byte-invariant) |
| Flattened single-delivery (work-root `STATE.md`, `### Tasks lifecycle` table) | the task's row, **column 6** (`\| Task \| State \| Review \| Elapsed \| Notes \|`) | `writeback-state.sh` `write_task_field_flat` (col_idx 6, lines ~834/959) |

- **Value domain.** Free-text single line. Null is represented by the sentinel `--` (also `-`, `—`,
  `""`); the reader twins collapse all of these to `notes: null` (`reader.mjs` `NULL_SENTINELS`
  line 122 / `isNull` line 124; mirrored in `parsers.py`). Forbidden characters: `|` (table column
  separator) and newline (row separator) — rejected by the writer (`mode_field` lines 733/738,
  exit 4) and pre-rejected by the op arg-schema (422).
- **Read path (unchanged).** `notes` is already parsed into `TaskModel.notes`
  (`models.py` line 251) via `RE_TS_NOTES` / the frontmatter key / the flat-table column, and already
  serialized into the DM-1 model envelope (`server.py` `_ser_task` line 613; `reader.mjs`
  `_buildTaskModel` line 4357). **This feature changes no parser or serializer** — it only begins to
  *display and edit* a field the model already carries.
- **DERIVED views are never a write target (C2/AC3).** The work-level `## Tasks State` union view is
  assembled at read time; the edit targets the AUTHORED per-task frontmatter (nested) or the AUTHORED
  `### Tasks lifecycle` row (flat) — exactly the cells `writeback-state.sh` already owns.

### Feature Flow

```
home.html task drill view (#/work/<work_id>/task/<task_id>)        Dashboard server (server.py | .mjs)
──────────────────────────────────────────────────────────        ───────────────────────────────────
user edits the Notes field and clicks Save
  │  (edit affordance rendered only when write_enabled === true)
  ▼
POST ./api/op   (→ /r/<id>/api/op)          ── HTTP ──▶  _serve_op   (feature-001)
  body: {op:"task.set-notes",                        │  SEC-6 Host allowlist → write gate (403 read-only)
         target:{work_id, delivery_id?, task_id},    │  → op ∈ OP_TABLE → resolve <id>→repo (id_map)
         args:{value}}                                │  → validate work_id; resolve_work_dir(repo, work_id) → REAL on-disk work dir (worktree-aware; 404 if no worktree holds it) [WT-1]; validate task_id + args (422)
                                                      │  → argv-builder (this feature): empty value → "--";
                                                      │    build [writeback-state.sh --task-id <t>
                                                      │      (--delivery-id <d> iff task.delivery set)
                                                      │      --field Notes --value <v>]
                                                      │    env AID_STATE_FILE, AID_WORK_DIR (abs; = resolve_work_dir output, worktree-aware — WT-1)
                                                      │  → spawn child (SEC-3/SEC-4) → exit→HTTP map
  ◀── 200 {ok:true, op:"task.set-notes"} ── or ── 4xx {ok:false,error,detail} ──┘
  │
  ▼ on ok: immediate doFetch()  → GET ./api/model?detail=<work_id>/<task_id>  (truthful re-render)
           → onSuccess → renderModel → (route.view==='task') → renderTaskView(fresh model)
             → Notes card now shows the new on-disk value (drift window = one round-trip)  [AC2]
  ▼ on failure: inline error note in the Notes card (writer stderr, ≤1 KiB); prior value preserved
```

The op is **per-repo** (`POST /r/<id>/api/op`); `home.html` already polls the location-relative
`./api/model`, which resolves to `/r/<id>/api/model` (per-repo route, `server.py` `_serve_repo_model`
line 1068), so the same relative base gives `./api/op` → `/r/<id>/api/op`. No home-level (`/api/op`)
route is used by this feature.

### Layers & Components

**1. Server layer — one `OP_TABLE` row (both twins).** feature-001 seeds the `task.set-notes` row on
the closed `OP_TABLE` in `server.py` and `server.mjs`; this feature supplies its concrete
**argv-builder** and **arg-schema** (added identically to both twins for DM/behaviour parity — this
is this feature's only parity obligation, since it touches no serializer). All routing, the write
gate, `id_map` repo resolution, the worktree-aware `resolve_work_dir` work-directory resolution
(WT-1), child-process dispatch, and the exit-code→HTTP map are feature-001's
and are consumed unchanged. See §API Contracts.

**2. Writer layer — `writeback-state.sh`, UNCHANGED.** Invoked in `mode_field` with `--task-id`,
`--field Notes`, `--value <v>`, and (nested only) `--delivery-id <d>`, plus env
`AID_STATE_FILE=<work-dir>/STATE.md` and `AID_WORK_DIR=<work-dir>`, where `<work-dir>` is the
**worktree-aware** directory feature-001's `resolve_work_dir(repo, work_id)` returns for `work_id` —
the exact on-disk copy the reader rendered, **never** a reconstructed served-tree
`<repo>/.aid/works/<work_id>` path (feature-001 invariant WT-1; OP_TABLE `task.set-notes` row,
feature-001 SPEC.md:349). This feature adds **no** path-resolution logic of its own; it consumes
feature-001's resolver verbatim, so a pipeline isolated in a git worktree — work-017's own topology,
`.claude/worktrees/<wt>/.aid/works/<work_id>/` — is targeted correctly and a `work_id` no worktree
holds yields 404. The script auto-detects layout (`is_flat_layout`) and
routes to the frontmatter write (nested) or `write_task_field_flat` (flat) itself. The client sends
the rendered `TaskModel.delivery` as `target.delivery_id`; the server forwards it to `--delivery-id`
(omitted when null). Passing it is harmless in flat layout (`mode_field` checks `is_flat_layout`
before delivery resolution, line 762), and when omitted in nested layout the script resolves it from
the task `**Source:**` line (`resolve_delivery_from_task_spec`).

**3. Reader / model layer — UNCHANGED.** `notes` is already parsed and serialized in both twins
(see §Data Model). Zero parser/serializer change ⇒ AC4 (twin byte-parity) is not at risk from this
feature; the only cross-twin artifact it adds is the `task.set-notes` argv-builder/arg-schema, added
identically to both server files.

**4. UI layer — `dashboard/home.html`, task drill view (`renderTaskView`, line 2877).** Adds a Notes
card + inline editor, gated on `write_enabled`, plus a small `postOp()` fetch helper and an
immediate re-fetch on success. `index.html` (the all-projects Projects grid) renders no tasks and is
**not** touched. See §UI Specs.

### API Contracts

This feature registers the concrete handler for the `task.set-notes` row that feature-001 seeded on
the `OP_TABLE` (feature-001 §API Contracts). Request/response envelope, status mapping, and the write
gate are feature-001's; the feature-local additions are the **arg-schema**, **argv-builder**, and
**target resolution**.

**Op:** `task.set-notes` — scope: **per-repo** (pipeline-scoped: writes STATE.md, so `target.work_id`
is required and must resolve to a real on-disk work directory via feature-001's worktree-aware
`resolve_work_dir(repo, work_id)` → else 404; the write targets the resolver's output, never a
reconstructed `<repo>/.aid/works/<work_id>` served-tree path — WT-1).

**Request (example):**

```json
{ "op": "task.set-notes",
  "target": { "work_id": "work-017-cli-improvements", "delivery_id": null, "task_id": "task-003" },
  "args": { "value": "blocked on upstream fix" } }
```

- `target.task_id` (required): `^task-\d{1,3}$` (or bare `\d{1,3}$`, normalized) — the numeric id
  is passed to `writeback-state.sh --task-id`. **Contract reconciliation with feature-001 (shared
  request-envelope field).** feature-001 §API Contracts states `^\d{1,3}$` (bare-digit) for
  `target.task_id`, yet its own request example uses `"task_id": "task-003"` (prefixed) — an internal
  contradiction in the foundation spec. feature-006's arg-schema here is a deliberate **superset**
  that accepts BOTH the prefixed `task-NNN` and the bare `NNN` forms and normalizes to the bare
  numeric id before the writer spawn (`--task-id <numeric>`), so it satisfies feature-001's stated
  bare-digit regex AND its prefixed example — the divergence is reconciled, not silent. The
  `"task_id": "task-003"` request example below is that prefixed form. (The foundation spec's own
  regex-vs-example contradiction is a feature-001 cleanup — flagged here, not a feature-006 blocker,
  since the superset already accepts whichever form feature-001 settles on.)
- `target.delivery_id` (optional): `^\d{1,3}$` when present. The client sources it from the
  **rendered `TaskModel.delivery`** (the value already in the model it drew the drill view from); the
  server validates and forwards it to `--delivery-id`. Null/absent ⇒ omitted, and
  `writeback-state.sh` resolves it itself (flat layout: ignored — `is_flat_layout`; nested: read from
  the task `**Source:**` line, `resolve_delivery_from_task_spec`). It only ever selects a numeric
  `delivery-NNN` subdir under the already-validated `work_id` path — never a caller-supplied path.
- `args.value` (required): string, length ≤ 1 KiB; **rejects** `|`, newline, and backslash `\`
  (422 `invalid-value`) — the `|`/newline guards mirror the writer's `mode_field` (lines 733/738);
  the backslash guard (added during the delivery-001 gate, mirroring `settings.set`'s KI-001) stops a
  two-char `\n`/`\t` sequence corrupting the STATE table cell. Defense-in-depth: the writer reads the
  value via `ENVIRON[...]` in `awk`, so a stray backslash is written literally, not interpreted. A bad
  value fails validation *before* any child spawn. An **empty string is accepted** and mapped by the argv-builder to the null
  sentinel `--` (the writer forbids an empty `--value`, exit 5; the reader renders `--` as null).

**Argv-builder (registered by this feature):**

```
value := (args.value == "") ? "--" : args.value            # clear → null sentinel
argv  := [ "<vendored>/writeback-state.sh",
           "--task-id", <numeric task_id>,
           ("--delivery-id", <numeric delivery_id>)?,       # iff target.delivery_id present (client sends rendered TaskModel.delivery)
           "--field", "Notes",
           "--value", value ]
env   := { AID_STATE_FILE=<work-dir>/STATE.md,             # <work-dir> = resolve_work_dir(repo, work_id):
           AID_WORK_DIR=<work-dir> }                       #   worktree-aware (WT-1); never <repo>/.aid/works/<work_id>
```

The server never builds a shell string and never takes a path from the body — the served repo root
comes from `id_map` (feature-001; `server.py` `build_id_map` line 112); the work directory is then
resolved from it by feature-001's worktree-aware `resolve_work_dir(repo, work_id)` (never a
reconstructed served-tree path — WT-1); the writer path self-locates from `$AID_CODE_HOME` per
feature-001's co-vendoring decision; and `work_id` is regex-validated.

**Response / status mapping (inherited from feature-001):** `200 {ok:true, op:"task.set-notes"}`;
on failure `{ok:false, op, error, detail}` with `writeback-state.sh` exit → HTTP per feature-001's
map — the ones reachable here: exit 1 → 404 `not-found` (**layout-qualified**: *nested* — a
non-existent `task_id` (its per-task STATE.md absent, `mode_field` writeback-state.sh line 770–772)
or a missing `work_id` dir; *flat* — the missing work-root STATE.md / `work_id` dir **only**, since
a non-existent `task_id` does **not** 404 here — see the flat-layout task-existence caveat below);
exit 4 → 422 `invalid-value` (bad `--value` charset — pre-caught by the arg-schema); exit 5 → 422
`invalid-value` (unresolvable delivery: nested layout with `target.delivery_id` omitted **and** the
task's `**Source:**` line missing/unresolvable — `resolve_delivery_for_task_mode`, writeback-state.sh
line 438; feature-001's generic exit-5→422 mapper covers it, so no feature-local handling is needed);
exit 2 → 409 `busy` (lock contention); exit 3/6 → 500 `write-failed` (empty/unverifiable write,
malformed STATE.md). Gate-closed → 403 `read-only`; bad Host → 403 `bad-host`; malformed body /
unknown op → 400 `bad-request`.

**Flat-layout task-existence asymmetry (a feature-001 writer behavior — surfaced here, not silent).**
The exit 1 → 404 above 404s on a missing *task* only in the **nested** layout, where `mode_field`
dies (exit 1) when the per-task STATE.md is absent (writeback-state.sh line 770–772). In the **flat**
layout, `write_task_field_flat` (writeback-state.sh line 823–936) performs **no** task-row existence
check: a `task_id` with no existing row falls through to `new_row()` (line 855–862) and is **silently
auto-created** — State/Review/Elapsed = `--`, Notes = the posted `value` — returning exit 0 → **200**,
not 404. So a `task.set-notes` targeting a non-existent task **fabricates a phantom task row** in flat
layout rather than 404-ing, and the exit-code table above therefore does **not** universally hold for
a missing task. Exposure is bounded but real: `home.html`'s `renderTaskView` renders a "Task not
found" callout and returns (line 2945–2954) **before** the Notes card is ever appended (line 2956+),
so the in-product UI never POSTs `task.set-notes` for a task absent from the model; but a **non-UI
client**, or a UI request **racing a concurrent task deletion**, hits the silent fabrication instead
of the implied 404. Closing it (a server-side or flat-writer task-existence pre-check) is a
**feature-001 writer cleanup** — flagged here, not a feature-006 blocker, since feature-006 adds no
writer and consumes `writeback-state.sh` unchanged, and the UI gate covers the in-product path.

### Security Specs

**Write gate (inherited — AC8).** The op is refused with HTTP 403 `read-only` unless the server was
spawned `write_enabled` (loopback, or `--remote --allow-writes`); enforced in `_serve_op` after the
SEC-6 Host-header allowlist (feature-001 §Security Specs). The UI additionally hides the edit
affordance when `write_enabled !== true` (defense-in-depth + UX; §UI Specs).

**Injection / traversal.** argv array only (no shell); `op` from the closed `OP_TABLE`;
`work_id`/`delivery_id`/`task_id` regex-validated; repo path resolved server-side from `id_map` and
the work directory from feature-001's worktree-aware `resolve_work_dir` (WT-1), never from the body;
`args.value` length-capped and rejected for `|`/newline before spawn; the writer
independently re-rejects the same (`mode_field` lines 733/738) — the client value can never be
interpreted as a shell token, a path, or a table/row separator.

**Preserved invariants (no new surface — C3).** SEC-1 (literal `127.0.0.1` bind) unchanged; SEC-3
(server performs no in-process fs mutation — the write happens in the `writeback-state.sh` child)
unchanged; SEC-4 (no agent/LLM in the server; the child is a shell script) unchanged; SEC-6
(anti-DNS-rebinding Host allowlist runs before the write gate on POST) unchanged. This feature adds
no endpoint, port, or listener beyond feature-001's already-specified POST surface.

### UI Specs

**Surface:** `dashboard/home.html`, the SEAM-2 task **drill view** (`renderTaskView`, line 2877),
reached from any task chip (`makeTaskChip` navigates to `#/work/<work_id>/task/<task_id>`, line 2600).
Notes are not rendered anywhere today; this feature introduces their display and edit. `index.html`
is unaffected (no task surface there).

**Placement — a "TASK NOTES" card.** Inserted **immediately after the drill-view header**
(`container.appendChild(headerDiv)`, line 2956) and **before** the `if (!detail)` first-tick
early-return (line 2962), so the Notes card renders even before the forensic `detail` payload loads
(`task.notes` comes from the already-present model, not from `details`). It reuses the existing
`card` + `kicker` block styling used by the findings/ledger panels (`_renderFindingsPanel`,
line 3007) and the `btn-ghost` control used by the back link (line 2916).

**States:**

- **Read (always).** Kicker "TASK NOTES"; the current `task.notes` value as body text, or a dimmed
  "No notes." (`var(--text-dim)`) when null — matching the empty-state pattern of the findings panel
  (line 3019).
- **Edit affordance (only when `model.write_enabled === true`).** An "Edit" `btn-ghost` reveals an
  inline single-line `<input type="text">` seeded with the current value, plus **Save** and
  **Cancel** buttons. Single-line input enforces the writer's no-newline rule structurally; a `|`
  typed into the field is flagged inline (client-side pre-check) before the request. When
  `write_enabled` is false (or absent — fail-safe), no Edit button is rendered and the card is
  read-only, so the UI never offers a control the server would 403.
- **Saving.** Save calls `postOp("task.set-notes", {work_id, delivery_id, task_id}, {value})` — a new
  thin `fetch('./api/op', {method:'POST', headers:{'Content-Type':'application/json'}, body:…})`
  helper modeled on the existing `doFetch` (line 1033). Buttons disable during the in-flight request.
- **Success → truthful re-render (AC2).** On `{ok:true}`, call `doFetch()` immediately (respecting the
  existing `fetchPending` single-in-flight guard, line 1034); `onSuccess`→`renderModel` re-dispatches
  to `renderTaskView` with the fresh model, and the Notes card shows the new on-disk value. No
  optimistic DOM mutation — the rendered value always comes from a post-write GET off disk.
- **Failure.** On `{ok:false}` (or a non-2xx), the card shows an inline error line (the `detail`
  string) using the `callout warn` style (line 2891); the input keeps the user's text so they can
  correct and retry.

**`write_enabled` threading.** feature-001 places `write_enabled` at the DM-1 **envelope** top level
(beside `generated_by`), not inside `model`. `home.html` reads it in `onSuccess` (line 1067) and
grafts it onto the model — `lastGoodModel.write_enabled = (envelope.write_enabled === true)` —
mirroring the existing `details` graft (line 1081); `renderTaskView` then reads
`model.write_enabled`. Missing ⇒ `false` (fail-safe, matches feature-001's UI default).

### How the Acceptance Criteria are satisfied

- **AC1 (edit performed from the dashboard, persists to disk).** The drill-view Notes editor POSTs
  `task.set-notes`; the server dispatches `writeback-state.sh --task-id … --field Notes --value …`,
  which surgically writes the task's authored `notes` cell under the work directory feature-001's
  `resolve_work_dir` returned (worktree-aware — WT-1; never a reconstructed served-tree path). The
  edit originates in the dashboard and is persisted by the single writer.
- **AC2 (truthful re-render, no drift).** On `{ok:true}` the client immediately re-fetches
  `./api/model` (`doFetch`) and `renderModel`→`renderTaskView` re-renders the Notes card from the
  fresh on-disk model; the drift window collapses from the poll interval to one round-trip.
- **AC3 (single-writer intact; no DERIVED write).** The write goes exclusively through
  `writeback-state.sh` (`mode_field`), so a dashboard notes edit is byte-indistinguishable from an
  agent edit. The target is the AUTHORED per-task frontmatter (nested) or the AUTHORED
  `### Tasks lifecycle` row (flat); the DERIVED `## Tasks State` union view is never written. The
  server contains no notes-writing code of its own.
