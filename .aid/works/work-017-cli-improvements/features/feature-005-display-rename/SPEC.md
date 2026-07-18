# Display Rename (Pipeline & Task)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.2 (FR-PL1), §5.4 (FR-T1) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): pipeline.rename consumes feature-001 write-requirement.sh; task.rename op registered on OP_TABLE via extended writeback-state.sh (new `Name`/`display_name` field); reader-twin display_name + slug-fallback render; UI rename controls gated by write_enabled. OQ-T1 RESOLVED (display_name cell, not DETAIL.md); Q3 consumed from feature-001. | /aid-specify |
| 2026-07-17 | Phase-2 fix: aligned the write-target paths for BOTH ops with feature-001's now-worktree-aware resolver. Data Model / Feature Flow / API Contracts / 404 test no longer reconstruct a `<served-root>/.aid/works/<work_id>/` path; they now feed `AID_REQUIREMENTS_FILE` / `AID_STATE_FILE` / `AID_WORK_DIR` from `resolve_work_dir(served_root, work_id)` (invariant WT-1), matching feature-001's OP_TABLE for the same two ops. Required for work-017's own worktree topology. | /aid-specify |

## Source

- REQUIREMENTS.md §5.2 FR-PL1 (Rename pipeline)
- REQUIREMENTS.md §5.4 FR-T1 (Rename task — display reference)

## Description

Let the user rename what the dashboard shows for a pipeline and for a task, non-destructively.
Pipeline rename edits the `REQUIREMENTS.md **Name:**` title; the dashboard renders that title
instead of the folder slug (`WorkModel.name`), falling back to the slug when the title is
empty. The work folder (`work-NNN-{name}`), its branch, and its worktree are untouched. Task
rename changes the shown task label via a mutable display-name cell; the task `DETAIL.md` and
task structure are untouched.

Depends on the write-infrastructure foundation (feature-001) for the write path and the
reader-twin change that surfaces an editable display name.

## User Stories

- As a developer running AID on my own project, I want to rename a pipeline or a task in the
  dashboard so it's easier to identify, without changing any folder, branch, worktree, or
  task file.

## Priority

Must

## Acceptance Criteria

- [ ] AC1 — Given a pipeline or task, when I rename it from the dashboard, then the new label
  is performed from the dashboard and persists to disk.
- [ ] AC2 — Given a rename is saved, when the view re-renders, then it shows the new title
  (falling back to the folder slug when the title is empty) with no drift.
- [ ] AC5 — Given a rename, when it is applied, then only the shown label changes; the folder,
  branch, and worktree (pipeline) and `DETAIL`/structure (task) are untouched.

## Open Questions

- **OQ-T1 — Task rename target — RESOLVED (2026-07-17, /aid-specify): add a mutable
  `display_name` cell, written through the EXISTING `writeback-state.sh --task-id --field`
  path (the same mechanism FR-T2 uses for Notes), NOT by editing `DETAIL.md`.** The cell is
  homed identically to the task's other mutable cells: a `display_name` frontmatter key in the
  per-task `STATE.md` (full/nested layout) and a new trailing `Name` column in the work-root
  `### Tasks lifecycle` table (flat/Lite layout). Both reader twins gain
  `TaskModel.display_name`; `home.html`'s task-label precedence becomes
  `display_name → short_name → task_id`. `DETAIL.md` is never touched (AC5). **Grounding:** the
  decision is *forced* by C1 — a per-task **STATE** cell must go through `writeback-state.sh`, so
  a dedicated non-STATE writer would violate C1, and editing the nominally immutable `DETAIL.md`
  (the `short_name` source, `parsers.py:781` / `reader.mjs:1819`) would violate AC5 and has no
  writer. It is symmetric with the pipeline half (both keep the immutable structural artifact —
  folder slug / `DETAIL.md` — untouched and render the mutable override with fallback to the
  immutable source), and it is the minimal plumbing: reuses the exact write path built for FR-T2,
  adding one field to `writeback-state.sh`'s closed task-field allowlist plus the flat-table
  column, with no new writer. See §API Contracts / §Layers & Components / §Data Model below.
- **Q3 — Pipeline-rename writer — RESOLVED (2026-07-17, feature-001 /aid-specify): build a
  writer, do NOT retarget.** FR-PL1 renames a pipeline by editing `REQUIREMENTS.md **Name:**`
  via the new non-interactive `write-requirement.sh` owned by feature-001 (foundation). This
  feature CONSUMES that writer through the pre-seeded `pipeline.rename` OP_TABLE row; it does not
  re-invent it. See `features/feature-001-write-infrastructure/SPEC.md` §API Contracts and work
  `STATE.md` § Cross-phase Q&A → **Q3**.
- **Pipeline/task split note.** Both halves are now unblocked (pipeline → Q3 resolved via
  feature-001; task → OQ-T1 resolved here). They ship together in this feature; no split needed.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature delivers the two
> **display-rename interactions** (FR-PL1 pipeline, FR-T1 task) on top of the write mechanism
> owned by **feature-001** (write-infrastructure). It does **not** re-invent the write path: it
> registers its op handler(s) on feature-001's POST `OP_TABLE`, honors the `write_enabled` /
> `--allow-writes` gate, dispatches to child-process writers (server stays LLM-free per SEC-4),
> keeps the reader twins byte-parity, and re-renders truthfully from disk.
>
> **Grounding anchors (verified on disk):** `dashboard/home.html` (title render + fallback lines
> 1490–1503 / 1922–1939; task label `short_name` fallback lines 2636–2640 / 2939–2942); reader
> twins `dashboard/reader/parsers.py` (`parse_requirements_md` L635, `_re_name` L664,
> `parse_task_short_name` L781, `parse_tasks_lifecycle_md` L1712) + `dashboard/reader/models.py`
> (`WorkModel.title` L320, `TaskModel.short_name` L253) + `dashboard/server/reader.mjs`
> (`parseRequirementsMd` L1679, `RE_NAME` L1695, `parseTaskShortName` L1819, `parseTasksLifecycleMd`
> L3486; task serialize L4357–4358); single writer `.claude/aid/scripts/execute/writeback-state.sh`
> (task-field allowlist L745–748, pipe/newline reject L733–740, `write_task_field_flat` col map
> L830–836); new writer `write-requirement.sh` (owned by feature-001); server task serialize
> `dashboard/server/server.py` L613–614; foundation `features/feature-001-write-infrastructure/SPEC.md`.

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | On-disk artifact set; this feature adds ONE new mutable cell (`display_name`) and reuses one existing AUTHORED field (`REQUIREMENTS.md **Name:**`). |
| Feature Flow | Present | The rename round-trip (click → POST op → writer → re-fetch → re-render) is the core; it reuses feature-001's dispatch loop. |
| Layers & Components | Present | Writer (extend `writeback-state.sh`; consume `write-requirement.sh`), reader-model (new `display_name`, existing `title`), UI (rename controls). |
| API Contracts | Present | `pipeline.rename` (consumed, pre-seeded) + `task.rename` (**registered here**) on feature-001's `OP_TABLE`. |
| Security Specs | Present | Reuses feature-001's write gate + argv-array dispatch; writer-level value validation; non-destructive (AC5). No new surface. |
| UI Specs | Present | Rename affordances on `home.html` (pipeline header + task view), gated by `write_enabled`, with the truthful re-render. |
| Migration / New Plumbing | Present | Additive optional `display_name` frontmatter key + additive trailing `Name` column in `### Tasks lifecycle`; both backward-compatible (positional/forward-compatible readers). No `write_enabled`/envelope-version change (feature-001 owns it). |
| State Machines | N/A | Rename touches no lifecycle enum; the task `state` cell and its enum are untouched. |
| Telemetry & Tracking | N/A | Single-user trust model; writers print `OK:` lines, server logs failures to stderr (inherited from feature-001). |
| Data Migration | N/A | Existing `.aid/` state read/written in place; old files without the new cell fall back to `short_name`/slug at read time. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to two loopback file-mutation display edits. |

### Data Model

**No database.** Two write targets, each owned by exactly one writer (C1 for STATE; a separate
AUTHORED-content writer for REQUIREMENTS):

| Target file | Field written | Owning writer | Zone |
|-------------|---------------|---------------|------|
| `<resolved-work-dir>/REQUIREMENTS.md` | `- **Name:**` bullet | `write-requirement.sh` (feature-001, **consumed**) | AUTHORED content file (identity source) |
| Full/nested: `<resolved-work-dir>/tasks/task-NNN/STATE.md` frontmatter | `display_name` (**new, optional**) | `writeback-state.sh --task-id --field Name` (**extended here**) | FRONTMATTER / AUTHORED (C2-safe) |
| Flat/Lite: `<resolved-work-dir>/STATE.md § ### Tasks lifecycle` (work-root) | new trailing `Name` column (**new**) | `writeback-state.sh --task-id --field Name` (**extended here**) | AUTHORED table (per `artifact-schemas.md` L142/L186; NOT the DERIVED `## Tasks State` view) |

**`<resolved-work-dir>` is the reader-resolved, worktree-aware directory — never a reconstructed
served-tree path (WT-1, inherited from feature-001).** Both ops are pipeline-scoped, so the server
resolves `target.work_id` to its REAL on-disk directory server-side via feature-001's
`resolve_work_dir(served_root, work_id)` (§Layers component 3 of `feature-001-write-infrastructure/SPEC.md`;
reuses the reader's `enumerate_worktree_roots` + newest-`updated` reconcile winner) before building any
argv — never by reconstructing `<served-root>/.aid/works/<work_id>/`. This is load-bearing for work-017's
own topology: work-017 runs from a git worktree (`.claude/worktrees/<wt>/.aid/works/<work_id>/`), so a
reconstructed served-tree path would 404 the very pipeline the reader rendered. This feature therefore
states **no** served-tree path of its own for either op; it feeds whatever directory the resolver returns
into `AID_REQUIREMENTS_FILE` / `AID_STATE_FILE` / `AID_WORK_DIR` (§API Contracts). A `None` result (no
worktree of the served repo holds the `work_id`) → 404.

**The pipeline half touches no STATE and no DERIVED view.** `write-requirement.sh` rewrites the
single `- **Name:**` bullet — the exact line the reader twins already parse into `WorkModel.title`
(`parse_requirements_md`/`_re_name`, `parsers.py:635/664`; `parseRequirementsMd`/`RE_NAME`,
`reader.mjs:1679/1695`). No reader change is needed for the pipeline half: `WorkModel.title`
already exists (`models.py:320`) and `home.html` already renders it with a slug fallback (below).

**The task half adds one mutable identity cell, `display_name`.** It is NOT a lifecycle scalar —
it is a mutable override of the immutable `short_name` (parsed from `DETAIL.md`'s
`# task-NNN: <title>` first line, `parse_task_short_name` `parsers.py:781` / `parseTaskShortName`
`reader.mjs:1819`). Because a per-task **STATE** cell must be written by the single writer (C1) and
`DETAIL.md` is immutable (AC5), `display_name` is homed exactly where the task's other mutable
cells already live and is written by the same writer:

- **Full/nested layout:** a new **optional** flat frontmatter key `display_name` in
  `tasks/task-NNN/STATE.md` (alongside `state`/`review`/`elapsed`/`notes`;
  `task-state-template.md`). `wb_set_frontmatter` already creates-or-updates arbitrary flat keys,
  and the readers ignore unknown keys, so this is additive and forward/backward compatible.
- **Flat/Lite layout:** a new **trailing** `Name` column appended to the work-root
  `### Tasks lifecycle` table (`| Task | State | Review | Elapsed | Notes | Name |`). The table is
  positional (`parse_tasks_lifecycle_md` reads `_col(0..4)`, `parsers.py:1765–1773`;
  `parseTasksLifecycleMd` reads `fcol(0..4)`, `reader.mjs:3486/3535`), so a legacy 5-column row
  yields `_col(5) == None → display_name None → fallback`. Backward-compatible by construction.

**Reader change (both twins, in lockstep — AC4):** add `TaskModel.display_name: Optional[str] =
None` (`models.py`, beside `short_name` L253), read it from the same two sources the task's
`state`/`review`/`elapsed`/`notes` cells already come from — `parse_task_state_md` (nested per-task
STATE frontmatter, `parsers.py:1354`; joined into `TaskModel` at `reader.py:1265/1290–1293`) and
`parse_tasks_lifecycle_md` (flat `### Tasks lifecycle` row, joined at `reader.py:983/1036–1039`) —
and emit it in the task DM serialization beside `notes`/`short_name` (`server.py:613–614`). The
`reader.mjs` twin mirrors each site (flat join `reader.mjs:3699/3749–3765`; task serialize
`reader.mjs:4357–4358`), plus the flat `parseTasksLifecycleMd` (`reader.mjs:3486/3535`) gains the
`Name` column exactly as the Python `parse_tasks_lifecycle_md` (`parsers.py:1712`, `_col(4)` L1773)
does. This is the ONLY parser/serializer change in this feature and it is applied identically to
both runtimes; golden fixtures for the twin parity suites regenerate in lockstep.

### Feature Flow

Both renames reuse feature-001's POST → gate → dispatch → writer → re-fetch round-trip verbatim;
only the op key, writer, and re-render target differ.

```
home.html                                        Dashboard server (server.py | server.mjs)
─────────                                        ──────────────────────────────────────────
user clicks the rename (pencil) affordance
  │  (rendered only when model.write_enabled === true)
  │  inline text input, prefilled with current display value
  ▼  Save
POST /r/<id>/api/op                    ── HTTP ──▶  feature-001 _serve_op:
  pipeline:  {op:"pipeline.rename",              │   Host allowlist (SEC-6) → write gate → op in
             target:{work_id}, args:{value}}     │   OP_TABLE → resolve <id>→repo (SEC-2) → validate
  task:      {op:"task.rename",                  │   work_id → resolve_work_dir → REAL dir (WT-1,
             target:{work_id, delivery_id?,      │   404 if none) → validate task_id/arg → argv
             task_id}, args:{value}}             │   ARRAY → spawn child writer (SEC-3/4)
                                                 │   pipeline.rename → write-requirement.sh
                                                 │     --field Name --value <v>
                                                 │     (env AID_REQUIREMENTS_FILE=
                                                 │      <resolved-work-dir>/REQUIREMENTS.md)
                                                 │   task.rename → writeback-state.sh --task-id <t>
                                                 │     [--delivery-id <d>] --field Name --value <v>
                                                 │     (env AID_STATE_FILE/AID_WORK_DIR=resolved dir)
  ◀── 200 {ok:true} ── or ── 4xx/5xx {ok:false,error,detail} ──┘
  │  on ok
  ▼
GET /r/<id>/api/model  (truthful re-render from disk — NFR3/AC2)
  ▼
swap model → re-render: pipeline shows new title (slug fallback if empty);
                         task shows new display_name (short_name→task_id fallback if empty)
```

**Empty-value = clear-to-fallback (AC2).** Renaming to an empty string clears the override so the
view returns to the immutable source. **Neither writer accepts a literally empty value**, so the
server op substitutes each writer's null sentinel before spawn (the client still sends `""`):

- **Pipeline:** the `**Name:**` bullet is set to the pending placeholder (`_re_name` requires
  `(.+)`, and `*(pending)*` maps to `None`, `parsers.py:664/691`) → `title None` → home.html de-slug
  fallback.
- **Task:** `writeback-state.sh` rejects an empty `--value` with **exit 5** at top-level
  arg-validation (`[[ -z "$FIELD_VALUE" ]] && die "--value is required with --task-id --field" 5`,
  L403) — this fires BEFORE `mode_field`/layout detection runs, for BOTH the nested and flat
  layouts — so an empty clear cannot pass through literally. The `task.rename` argv-builder
  therefore substitutes the writer's `--` null sentinel (the same value `mode_field` writes to the
  `display_name` key and `write_task_field_flat` writes to a cleared cell, and the value the
  reader's `_is_null`/`_NULL_SENTINELS` set maps to `None`, `parsers.py:2186`) for an empty
  `args.value`. Result on disk: `display_name: --` (nested) or a `--` cell in the `### Tasks
  lifecycle` row (flat) → `_col(5) → None` → `display_name None` → `short_name` → `task_id`.

### Layers & Components

**1. Server / dispatch layer** — **no new mechanism; reuse feature-001.** `_serve_op`, the
`OP_TABLE`, the argv-array child spawn, the exit-code→HTTP map, and the write gate are all
feature-001's. This feature only supplies two `OP_TABLE` rows (one pre-seeded, one new — §API
Contracts) and their argv-builders/arg-schemas. The server file still contains **no in-process
fs-write** and **no agent/LLM import** (SEC-3/SEC-4 unchanged).

**2. Writer layer:**
- `write-requirement.sh` — **consumed as-is** from feature-001 for `pipeline.rename`
  (`--field Name`, `env AID_REQUIREMENTS_FILE`). Non-destructive: touches only the `**Name:**`
  bullet — never the work folder, branch, or worktree (AC5, per feature-001's contract).
- `writeback-state.sh` — **extended** for `task.rename` in two coordinated places:
  - **Nested/full layout (`mode_field`).** Add `name` to the closed task-field allowlist
    (`case "$field_lower" in state|review|elapsed|notes)`, `writeback-state.sh:745–748`) **and**
    add an explicit `name → display_name` frontmatter-key translation. The translation is
    load-bearing, not incidental: `mode_field` today passes `field_lower` **verbatim** as the
    frontmatter key — `wb_set_frontmatter "$TASK_STATE_FILE" "$field_lower" …` (L790), verified by
    `wb_frontmatter_verify "$tmp" "$field_lower"` (L792), documented in-code as "field_lower IS the
    frontmatter key verbatim, no name mapping needed" (L785–787). That holds for
    `state`/`review`/`elapsed`/`notes` (field name = key) but NOT for `name`, whose reader key is
    `display_name` (`models.py:253`); adding `name` to the allowlist alone would write a literal
    `name:` key that no reader reads — a silent AC1/AC2 failure for this layout. The extension MUST
    introduce the same `fm_key` indirection `mode_gate_field` already uses (`field_lower` →
    `fm_key`, `tier|grade|timestamp → gate_tier|gate_grade|gate_timestamp`, L1116–1123; then
    `wb_set_frontmatter … "$fm_key"` L1152 / `wb_frontmatter_verify … "$fm_key"` L1154): map
    `name → display_name`, route BOTH the write (L790) and the verify (L792) through the mapped
    key, and update the "no name mapping needed" comment to record the `name` exception.
  - **Flat/Lite layout (`write_task_field_flat`).** Add `name) col_idx=7` to the
    `case "$field_lower"` col map (L830–836) and extend the `new_row()`/row-rewrite awk that
    currently emits columns 3–6 (L853–924) to also emit the trailing column 7, so the flat path
    writes the `Name` **data** cell. The awk touches DATA rows only: it prints the header row
    (L899) and the separator row (L894) **byte-verbatim, with no column-count reconciliation**, so
    it does NOT create the `Name` header column — that column must ship in the seed template's
    authored header/separator (§Migration follow-up (4)). The positional readers (`_col(0..4)` →
    `_col(5)`, `parsers.py:1765–1773`) tolerate a legacy 5-column header at runtime, but without
    the template change the AUTHORED table is left permanently header/data-mismatched.
  The existing `|`/newline rejection (`mode_field`, L733–740) already guards row/line corruption;
  no other change. This keeps `writeback-state.sh` the single STATE writer (C1) and a dashboard task
  rename byte-indistinguishable from an agent edit. _(Cross-feature note: feature-001 lists
  `writeback-state.sh` as "unchanged" for ITS scope — the one-field extension here is owned by
  feature-005; the script is single-sourced in `canonical/aid/scripts/execute/` and rendered to
  the profile trees + co-vendored to the dashboard unit per feature-001's `dashboard/MANIFEST`
  discipline, so all consumers stay version-locked.)_

**3. Reader / model layer** — the one parser/serializer change described in §Data Model
(`TaskModel.display_name`, both twins, lockstep). The pipeline half needs **no** reader change.

**4. UI layer** (`dashboard/home.html`) — rename controls + label-precedence, §UI Specs.

### API Contracts

Reuses feature-001's `POST /r/<id>/api/op` envelope, success/failure schema, and exit-code→HTTP
map verbatim. Two rows:

| `op` | Scope | Writer + argv | Owning FR | Status |
|------|-------|---------------|-----------|--------|
| `pipeline.rename` | per-repo | `write-requirement.sh --field Name --value <v>` (env `AID_REQUIREMENTS_FILE=<resolved-work-dir>/REQUIREMENTS.md`, from `resolve_work_dir`; worktree-aware, WT-1) | FR-PL1 | **pre-seeded by feature-001**; consumed here |
| `task.rename` | per-repo | `writeback-state.sh --task-id <t> [--delivery-id <d>] --field Name --value <v>` (env `AID_STATE_FILE=<resolved-work-dir>/STATE.md`, `AID_WORK_DIR=<resolved-work-dir>`, from `resolve_work_dir`; worktree-aware, WT-1) | FR-T1 | **registered here** (feature-001 listed `task.rename` as owned by 005) |

**Request** (per feature-001):
```json
{ "op": "task.rename",
  "target": { "work_id": "work-017-cli-improvements", "delivery_id": null, "task_id": "task-003" },
  "args": { "value": "Wire up the rename dispatch" } }
```
- `target.work_id` required (both ops are pipeline-scoped): validated `^work-[0-9]+`, then resolved to its REAL on-disk directory by feature-001's worktree-aware `resolve_work_dir(served_root, work_id)` (WT-1). A `None` result — no git worktree of the served repo holds the `work_id` — → 404. The op targets whatever directory the resolver returns; it never tests or reconstructs a `<served-root>/.aid/works/<work_id>` path (this is what makes work-017's own worktree-isolated pipeline reachable). The served repo root is resolved server-side from `id_map` (SEC-2) — never from the body.
- `task.rename` additionally requires `target.task_id` (`^\d{1,3}$`); `target.delivery_id` is passed to `--delivery-id` when the model's `TaskModel.delivery` is set (nested), omitted for flat.
- `args.value` (both ops): a single-line string, length-capped by the op arg-schema; rejected if it contains a newline or `|` (validated server-side and again by the writer — `write-requirement.sh` rejects `\n`/`|` → exit 4; `writeback-state.sh mode_field` rejects `|`/newline → exit 4). Empty string is an **accepted** input meaning clear-to-fallback, but is NOT forwarded verbatim: `writeback-state.sh` dies **exit 5** on an empty `--value` (`--value is required with --task-id --field`, L403) and `write-requirement.sh` needs a non-empty bullet, so the argv-builder substitutes each writer's null sentinel first — `--` for `task.rename`, `*(pending)*` for `pipeline.rename` (§Feature Flow). Exit 4 → HTTP 422 `invalid-value` (feature-001 map).

**Argv-builder invariant.** The server forwards only the fixed writer flags plus the validated,
server-resolved values; the client never supplies a path, flag, or command — traversal/injection
posture is inherited unchanged from feature-001 (argv array, no shell, closed `OP_TABLE`).

### UI Specs

Grounded in the existing `home.html` render functions; every control below is created only when
the per-repo `model.write_enabled === true` (the signal feature-001 echoes into the DM envelope)
and triggers the feature-001 re-fetch/re-render on success.

- **Pipeline rename (FR-PL1).** The pipeline's display title is already rendered by
  `renderWorkHeader` into `#overview-title` with a de-slug fallback (`home.html:1922–1939`) and by
  `renderWorkCard` into the card `<h3>` (`home.html:1490–1503`). Add a small inline **edit (pencil)**
  affordance next to `#overview-title` in the drilled-in work header: click reveals a text input
  prefilled with `work.title` (empty when unset), Save → `POST /r/<id>/api/op {op:"pipeline.rename",
  target:{work_id}, args:{value}}`, Cancel restores. On `ok`, re-fetch `/r/<id>/api/model` and
  re-render — the existing title/fallback code then shows the new title (or the slug when cleared).
  Because the display switch + fallback already exist, **AC2 for the pipeline half is satisfied by
  existing code**; this feature adds only the edit control.
- **Task rename (FR-T1).** Task labels render `short_name` today — with a `task_id` fallback in the
  task card (`shortName = task.short_name || task.task_id`, `home.html:2636–2640`) and shown when
  present in `renderTaskView`'s name element (`if (task.short_name)`, `home.html:2939–2942`).
  Add the same pencil affordance next to the task name in the task drill view (primary) prefilled
  with the current display value; Save → `POST … {op:"task.rename", target:{work_id, delivery_id?,
  task_id}, args:{value}}`; on `ok`, re-fetch `/r/<id>/api/model` and re-render. Change the label
  precedence to `display_name → short_name → task_id` (i.e. `task.display_name || task.short_name ||
  task.task_id`) at both render sites, in lockstep with the reader emitting `display_name`.
- **Gate behavior.** When `write_enabled` is false (e.g. `--remote` without `--allow-writes`), the
  pencil affordances are not rendered at all (defense-in-depth: even if forced, the server 403s the
  op) — inherited from feature-001's gate.
- **No new page/route.** Both controls live on the existing `home.html` per-project view; no
  `index.html` change (the all-projects grid owns Add/Remove Project, feature-003, not rename).

### Security Specs

- **Write gate (AC8) — inherited.** Both ops flow through feature-001's single enforcement point
  (`_serve_op`, after the SEC-6 Host-header allowlist, checking `write_enabled`); no new gate.
- **SEC-1/3/4/6 preserved.** No new listener/port/process; the server performs no in-process
  fs-write and imports no agent/LLM — it spawns the two allowlisted writers with an argv array.
- **Injection/traversal.** `op` from the closed `OP_TABLE`; `work_id`/`task_id`/`delivery_id`
  regex-validated; repo path from `id_map` (never the body); `args.value` validated (single line,
  length-capped) before spawn and again rejected for `|`/newline by both writers.
- **AC5 non-destructive.** `write-requirement.sh` rewrites only the `**Name:**` bullet (folder,
  branch, worktree untouched); `writeback-state.sh --field Name` rewrites only the `display_name`
  frontmatter key (nested) or the task's `### Tasks lifecycle` row (flat) — `DETAIL.md` and task
  structure untouched. Neither writer deletes or moves any file.

### Migration / New Plumbing

- **Additive `display_name` (task) — no version bump.** Optional frontmatter key + optional
  trailing `### Tasks lifecycle` column, both readable-by-fallback on legacy files; the DM
  `schema_version` is owned by feature-001's `write_enabled` change and is not touched here.
- **`writeback-state.sh` +1 field.** The `Name`→`display_name` extension is single-sourced in
  `canonical/aid/scripts/execute/writeback-state.sh` and propagates via the render + co-vendor
  path feature-001 established; no new `dashboard/MANIFEST` edit (the writer is already listed).
- **No data migration** — existing `.aid/` state read/written in place.
- **KB / template follow-ups (out of scope for this write; flagged for the human).**
  (1) `task-state-template.md` should document the new optional `display_name` frontmatter key;
  (2) `artifact-schemas.md` § Task STATE.md / § Work STATE.md `### Tasks lifecycle` should note
  the `display_name` cell / `Name` column; (3) the `writeback-state.sh` usage/header comment
  should list `Name` in the task-field allowlist; (4) **[structural, not doc-only]**
  `work-state-template.md`'s seed `### Tasks lifecycle` header **and** separator row (currently the
  5-column `| Task | State | Review | Elapsed | Notes |` / `|------|...|`, no `Name`,
  `work-state-template.md:214–216`) must gain the trailing `Name` column so a newly seeded flat/Lite
  work has a 6-column AUTHORED header/separator matching the data rows the extended
  `write_task_field_flat` emits. Unlike (1)–(3), this is not documentation polish: because the awk
  prints the header/separator byte-verbatim (§Layers & Components — no column-count reconciliation),
  omitting it leaves every authored `### Tasks lifecycle` table header/data-mismatched (harmless to
  the positional reader, but a malformed authored artifact). (Per instructions, the KB/templates are
  not edited by this run — this completes the Migration inventory so the human applies it alongside
  the code.)

### How the Acceptance Criteria are satisfied

- **AC1 (rename performs from the dashboard and persists).** Pipeline rename posts
  `pipeline.rename` → `write-requirement.sh` writes `REQUIREMENTS.md **Name:**` to disk; task
  rename posts `task.rename` → `writeback-state.sh --field Name` writes the `display_name` cell to
  disk (per-task frontmatter or flat table row). Both persist through the single canonical writer
  process (no in-process write).
- **AC2 (truthful re-render with slug/short_name fallback).** On `ok`, the client re-fetches
  `/r/<id>/api/model` and re-renders from disk (feature-001 contract). The pipeline already renders
  `WorkModel.title` with a de-slug fallback (`home.html:1922–1939/1490–1503`); the task renders the
  new precedence `display_name → short_name → task_id`. Empty rename clears the override (via the
  server-side null-sentinel substitution — `--` for the task, `*(pending)*` for the pipeline —
  since neither writer accepts a literally empty value; §Feature Flow) → the view returns to the
  immutable source (slug / `short_name`).
- **AC5 (display-only, non-destructive).** Neither writer touches the folder, branch, worktree,
  `DETAIL.md`, or task structure — only the single `**Name:**` bullet or the single `display_name`
  cell (see §Security Specs). The immutable `short_name`/slug remain the fallback, proving the
  structural identity is unchanged.
- **AC3/AC4 (inherited invariants).** All task-STATE writes go through `writeback-state.sh` (C1);
  no DERIVED view is written (the flat `### Tasks lifecycle` table is AUTHORED, C2). The single
  reader change (`TaskModel.display_name`) is applied identically to `parsers.py`/`reader.py` and
  `reader.mjs` with fixtures regenerated together (AC4), guarded by the existing cross-runtime
  parity suites.
