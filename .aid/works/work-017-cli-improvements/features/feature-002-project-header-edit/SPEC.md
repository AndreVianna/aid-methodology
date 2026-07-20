# Project Header Panel Edit

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.1 (FR-P3) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): consumes feature-001 `settings.set` op + `write-setting.sh` + write gate; adds the DM-1 reader exposure of `project.description` + global `review.minimum_grade` (twin-parity), the home.html project-header redesign, and the `write_enabled` graft. OQ resolved (reader must expose the two new fields; feature-001 made zero parser changes). KI listed in return. | /aid-specify |

## Source

- REQUIREMENTS.md §5.1 FR-P3 (Header panel redesign)

## Description

Redesign the project page header on `home.html` — currently just a clickable card linking
to the KB — into an editable panel. It shows and edits the project's name
(`project.name`), description (`project.description`), and grading (`review.minimum_grade`,
the global value only), and keeps a button to open the KB. Edits go through the
non-interactive `settings.yml` writer (not `writeback-state.sh`). Excluded and left in
`/aid-config`: `max_parallel_tasks`, `heartbeat_interval`, per-skill grade overrides, and
`project.type`.

Depends on the write-infrastructure foundation (feature-001) for the settings writer and
the server write endpoints.

## User Stories

- As a developer running AID on my own project, I want to edit my project's name,
  description, and grading threshold directly from the dashboard header, so that I don't
  have to run an interactive config skill to change them.

## Priority

Must

## Acceptance Criteria

- [ ] AC1 — Given the redesigned header, when I edit the name, description, or global
  minimum grade, then the change is performed from the dashboard and persists to disk.
- [ ] AC2 — Given a header edit is saved, when the page re-renders, then it reflects the new
  on-disk settings with no drift.

## Open Questions

- **OQ-P5 (settings writer) — RESOLVED upstream (feature-001).** The non-interactive settings
  writer FR-P3 needs is `write-setting.sh`, fully specified and owned by
  `features/feature-001-write-infrastructure/SPEC.md` (§API Contracts), with the `settings.set`
  op already seeded on the feature-001 `OP_TABLE` for `project.name` / `project.description` /
  `review.minimum_grade`. This feature CONSUMES it; it introduces no new writer.

- **Header reader-exposure question — RESOLVED (2026-07-17, /aid-specify): extend the DM-1 reader
  to expose `project.description` and the global `review.minimum_grade`.** The header must *display*
  the current name, description, and global grade, but the DM-1 model (`RepoInfo`, `models.py:220`)
  today carries only `project_name` (`parsers.py:173 parse_project_name`) on the `./api/model`
  channel home.html consumes; it exposes no `project.description` and no global `review.minimum_grade`
  there (`WorkModel.minimum_grade` is the per-work value, not the settings default). feature-001
  deliberately made **zero parser changes**; this consuming feature therefore owns the additive
  reader exposure of those two settings scalars, applied identically across the reader/serializer
  twins (AC4). Rejected alternative — reading the values client-side or via a second endpoint — was
  dropped because home.html has exactly one data channel (`./api/model`) and a truthful re-render
  (AC2) must come from that single post-write GET.

  **Caveat — KI-001 read-side hazard (not a new field on disk).** This exposure is new *only to the
  `RepoInfo` / `./api/model` channel*; `project.name` and `project.description` are **already** parsed
  and displayed today by a **distinct** codepath — `server.py` `_read_settings` (line 347) /
  `server.mjs` `readSettings` (line 380) — that feeds the all-projects grid on `index.html`. The DM-1
  read therefore becomes the *fourth* ad-hoc `settings.yml` reader of `project.description`, which is
  exactly the divergent-parser hazard this work's `known-issues.md` **KI-001** catalogs for this field
  (its Source list enumerates all four readers, incl. `_read_settings`/`readSettings`). KI-001 is
  cross-referenced below (§API Contracts) for the write-side output-charset guarantee; it applies
  **equally** here on the read side — the new DM-1 parser MUST strip/round-trip identically to
  `_read_settings`/`readSettings` (same `_strip_yaml_inline_comment` + bare/quoted-scalar handling) so
  both channels display the same value after a write.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature **consumes** the
> write mechanism delivered by `feature-001-write-infrastructure` — it does NOT re-invent it.
> From feature-001 it uses: the `settings.set` op (already on `OP_TABLE`), the `write-setting.sh`
> writer, the child-process writer dispatch (server stays LLM-free, SEC-4), the `--allow-writes`
> write gate + `write_enabled` envelope signal, the reader-twin byte-parity discipline, and the
> truthful re-render contract. This feature ADDS: (1) an additive DM-1 reader exposure of
> `project.description` + global `review.minimum_grade`; (2) the `home.html` project-header
> redesign (view/edit name/description/grade + a KB button); (3) the client-side `settings.set`
> call + targeted re-fetch, gated on `write_enabled`.
>
> **Grounding anchors:** UI — `dashboard/home.html` (`#main-page` line 874, `#knowledge-tool-section`
> line 877, `renderMainPage` line 1318, `_renderKbCard` line 1604, KB href `./kb.html` line 1618,
> the `envelope.details` graft in `onSuccess` line 1081, the `./api/model` fetch line 1046).
> Reader twins — `dashboard/reader/models.py` `RepoInfo` (line 220), `dashboard/reader/parsers.py`
> `parse_project_name` (line 173), `dashboard/reader/reader.py` `parse_project_name` call (line 392)
> + `RepoInfo(...)` construction at line 371 (empty-model early-return, no-`.aid` path) and line 423
> (LEVEL-1 build site);
> Node twin `dashboard/server/reader.mjs` `parseProjectName` (line 594), `repoInfo` (line 2640),
> `_buildRepoInfo` (line 4327). Serializers — Python `dashboard/server/server.py` `_ser_repo_info`
> (line 595); Node `dashboard/server/reader.mjs` `_buildRepoInfo` (line 4327, which fixes the
> emitted key order — `server.mjs serializeModel` at line 566 just wraps the already-built object).
> Writer + op — feature-001 SPEC
> §API Contracts (`write-setting.sh`, `settings.set`). Grade alphabet `^[A-F][+-]?$`
> (`writeback-state.sh` line 1392; reused by `write-setting.sh`).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The store is `<repo>/.aid/settings.yml`; this feature adds two read-exposed scalars to the DM-1 model and writes three via the feature-001 op. |
| Feature Flow | Present | The click → edit → `settings.set` POST → gate → `write-setting.sh` → re-fetch `./api/model` → re-render round-trip is the feature. |
| Layers & Components | Present | Reader/model layer (new exposed fields), serializer twins, and the home.html UI layer all change. |
| API Contracts | Present | The `settings.set` op handler (consumed from feature-001) — the three allowed `--path` values, per-path arg validation, and status mapping. |
| Security Specs | Present (mostly inherited) | The write gate, argv-array/no-shell, value-charset rejection, and SEC-3/4/6 preservation all come from feature-001; this feature adds only field-level input constraint (grade `<select>`). |
| UI Specs | Present (required) | The home.html header redesign is the visible deliverable — controls, placement, `write_enabled` gating, re-render. |
| Migration / New Plumbing | Present | Additive DM-1 model fields (no `schema_version` bump); golden-fixture regen for the parity twins. |
| State Machines | N/A | No lifecycle/enum owned here; `settings.yml` scalars have no state machine. |
| Telemetry & Tracking | N/A | Single-user trust model; `write-setting.sh` prints `OK:`/errors, the server logs failures to stderr (feature-001) — sufficient. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback settings-scalar edit panel. |

### Data Model

**No database.** The edited store is `<repo>/.aid/settings.yml`, flat-section YAML. This feature
touches three scalars, all owned by the feature-001 `write-setting.sh` writer (**FR-P3 §5.1** pins
the mechanism — settings edits use the non-interactive `settings.yml` writer, **not**
`writeback-state.sh`; C1 governs STATE.md writes only and explicitly disclaims settings-writer edits
(`REQUIREMENTS.md` §7 C1 scope note), so — since the header issues no STATE write — C1/C2 are
untouched by construction):

| settings.yml path | Header control | Read into DM-1 as | Written by |
|-------------------|----------------|-------------------|------------|
| `project.name` | name field | `repo.project_name` (existing) | `write-setting.sh --path project.name` (feature-001) |
| `project.description` | description field | `repo.project_description` (**new**, this feature) | `write-setting.sh --path project.description` |
| `review.minimum_grade` (global) | grade `<select>` | `repo.minimum_grade` (**new**, this feature) | `write-setting.sh --path review.minimum_grade` |

**DM-1 model additions (additive; the core of this feature's non-UI work).** `RepoInfo`
(`models.py:220`) gains two `Optional[str]` fields — `project_description` and `minimum_grade`
(the global settings default; deliberately distinct from `WorkModel.minimum_grade`, the per-work
value). Both default `None` and are read from `settings.yml`; `project_name` is unchanged. No
DERIVED view is read or written (C2). Excluded scalars stay out of the model and the panel:
`max_parallel_tasks`, `heartbeat_interval`, per-skill grade overrides, `project.type` (they remain
`/aid-config`-only, per FR-P3).

### Feature Flow

```
Browser (home.html #main-page, project-header panel)          Server (server.py | server.mjs)
──────────────────────────────────────────────────           ────────────────────────────────
render header from model.repo.{project_name,
  project_description, minimum_grade}
  │  edit affordances rendered ONLY when model.write_enabled === true (feature-001 signal)
  ▼
user edits a field and Saves
  │
  ▼
POST ./api/op   (resolves to /r/<id>/api/op — feature-001)   do_POST → _serve_op
  body: {op:"settings.set",                                  1. SEC-6 Host allowlist            → 403 bad-host
         target:{}, (no work_id — project-scoped)            2. write gate write_enabled?        → 403 read-only
         args:{path:"project.description", value:"…"}}       3. parse body; oversize/unknown     → 400
                                                             4. op ∈ OP_TABLE ("settings.set")   → 400 if not
                                                             5. resolve <id> → repo path (id_map; SEC-2)
                                                             6. settings-scoped: skip work_id dir check
                                                             7. validate args: path ∈ {project.name,
                                                                project.description, review.minimum_grade};
                                                                grade value ^[A-F][+-]?$          → 422 invalid-value
                                                             8. argv ARRAY: write-setting.sh --path <p>
                                                                --value <v> --file <repo>/.aid/settings.yml
                                                             9. spawn child (SEC-3/SEC-4)         → exit→HTTP map
  ◀── 200 {ok:true,op:"settings.set"} ── or ── 4xx/5xx {ok:false,error,detail} ──┘
  │ on ok
  ▼
targeted re-fetch  GET ./api/model  → swap model → renderMainPage() re-renders header from disk (AC2)
  │ on failure
  ▼
inline error (reuse .callout.err); field reverts to last on-disk value; no optimistic mutation
```

The panel never writes optimistically: the displayed value always comes from a post-write
`./api/model` GET off disk, so it cannot drift (NFR3 / AC2). Edit affordances are hidden entirely
when `write_enabled` is false (read-only display), so the panel offers no control the server would
403 (defense-in-depth + honest UX, per feature-001 §Security Specs).

### Layers & Components

**1. Reader / model layer** (`dashboard/reader/parsers.py` + `dashboard/server/reader.mjs`, twins) —
the parser additions this feature owns (two calls — one per settings section):

- Add a small settings-scalar read for `project.description` and global `review.minimum_grade`,
  modelled on the existing flat-section line-scan `parse_project_name` (`parsers.py:173`) and its
  Node twin `parseProjectName` (`reader.mjs:594`) — same section-entry rule, same
  `_strip_yaml_inline_comment` handling, same quote-stripping, same bounded read
  (`read_bytes_bounded`). **The two new scalars live in two structurally separate sections, so this
  is two parser calls, not one combined pass** — mirroring `reader.py`'s own one-parser-call-per-section
  precedent (`parse_project_name`, `parse_kb_baseline`, `parse_kb_state` are each a distinct call):
  - (a) `project.name` and `project.description` are both in the **same** `project:` block, so they
    can share one project-section scan: factor the body of `parse_project_name` into a combined
    `parse_project_settings(settings_path) -> (name, description, bytes_read)` (and its Node twin),
    keeping a thin `parse_project_name` wrapper for its existing callers/tests.
  - (b) `review.minimum_grade` lives in a **structurally separate** top-level `review:` section. In
    a real `settings.yml` the `tools:` section sits *between* `project:` and `review:`, so
    `parse_project_name`'s break-on-next-top-level-key logic (`parsers.py:207-208`) exits the loop at
    `tools:` and never reaches `review:` — reusing the `project:`-section scan for it is impossible.
    It therefore needs its **own** `review:`-section scan as a separate call
    (`parse_minimum_grade(settings_path) -> (grade, bytes_read)`), not a widened project-section pass.
  `review.minimum_grade` is read literally as a display scalar (no resolution — `read-setting.sh`
  remains the resolution contract, per the `parse_project_name` docstring note at `parsers.py:179`).
- `reader.py` populates the two new `RepoInfo` fields at the LEVEL-1 build site (`reader.py:423`;
  the `parse_project_name`/new-parser calls sit just above at `reader.py:392`). The empty-model
  early-return `RepoInfo(...)` (`reader.py:371`, the no-`.aid` path) leaves both at their `None`
  default — there is no `settings.yml` to read on that branch. The Node twin populates `repoInfo`
  (`reader.mjs:2640`). Absent/unreadable → `None` (fallback tolerant; folder-basename fallback for
  `project_name` is unchanged).

**2. Serializer twins** — Python `dashboard/server/server.py` `_ser_repo_info` (line 595) and Node
`dashboard/server/reader.mjs` `_buildRepoInfo` (line 4327, the site that fixes the emitted key
order; `server.mjs serializeModel` at line 566 merely wraps the already-built object). Emit the two
new keys in declared field order, **identically** in both twins, to preserve DM-3 byte-parity (AC4).
New key order: `project_name, project_description, minimum_grade, aid_dir, kb_state` (new keys
inserted after `project_name`; both `_ser_repo_info` and `_buildRepoInfo` currently emit
`project_name, aid_dir, kb_state`, so apply the identical insertion to both + the fixtures). This is an additive model change — following the DM-A3 (task-064) /
RC-2 no-bump precedent cited in feature-001, `schema_version` stays **3**; older UIs ignore the new
keys, and this UI treats missing → `null`/fallback.

**3. UI layer** (`dashboard/home.html`) — see §UI Specs. Adds a `#project-header` panel to
`#main-page`, rendered by a new `_renderProjectHeader(model)` invoked at the top of `renderMainPage`
(line 1318); adds the `settings.set` client call + `./api/model` re-fetch; and adds the one shared
`envelope.write_enabled → model.write_enabled` graft in `onSuccess` (mirroring the existing
`envelope.details` graft at line 1081; missing → `false`). The graft is shared infrastructure that
later consuming features (005/006/…) reuse; feature-002 introduces it as the first consumer.

**4. Writer + dispatch layer** — entirely feature-001: `write-setting.sh`, the `settings.set`
`OP_TABLE` row, argv-array child spawn, and the write gate. This feature adds no server write
primitive and imports no writer of its own (SEC-3/SEC-4 preserved by inheritance).

### API Contracts

**Op consumed: `settings.set`** (seeded on the feature-001 `OP_TABLE`; this is its first consumer).
Endpoint `POST /r/<id>/api/op` (issued as relative `./api/op` from home.html), request/response
envelope exactly as feature-001 §API Contracts defines. Project-scoped: `target.work_id` is
**omitted** (the writer targets `<repo>/.aid/settings.yml`, which has no work); `<id>` alone
resolves the repo path from `id_map` (SEC-2 — never from the body).

Request `args` schema this feature pins for `settings.set`:

```json
{ "op": "settings.set", "target": {}, "args": { "path": "review.minimum_grade", "value": "A" } }
```

- `args.path` (required): closed allowlist `{ "project.name", "project.description",
  "review.minimum_grade" }` — any other value → 422 `invalid-value` (the writer also rejects it,
  exit 4; the server pre-validates for a clean status). This is the exact allowlist the
  `write-setting.sh` contract declares.
- `args.value` (required): for `review.minimum_grade`, must match `^[A-F][+-]?$` (server + writer,
  same alphabet as `writeback-state.sh:1392`). For `project.name` / `project.description`: rejected
  if it contains a newline, embedded `"`, or `\` (KI-001, this work's `known-issues.md` — keeps the
  written scalar inside the strip-only alphabet every settings reader round-trips identically); empty string
  allowed for `project.description` (clears it), rejected for `project.name` (name is required —
  the reader would fall back to the folder basename).
- Success 200 `{ok:true,op:"settings.set"}` → client re-fetches `./api/model`. Failure → the
  feature-001 status map (403 gate/host, 400 bad-request, 422 invalid-value, 409 busy, 500
  write-failed); the UI renders `detail` in an inline `.callout.err`.

This feature registers **no new op** and **no new writer** — the `settings.set` handler, its
argv-builder, and `write-setting.sh` are delivered by feature-001; feature-002 finalizes the
`settings.set` arg-schema (the three paths + per-path value rules above) and is its sole UI caller.

### Security Specs

Inherited whole from feature-001 (no new network surface — C3):

- **Write gate (AC8).** The header's edit controls appear only when `write_enabled` is true, and
  the server 403s any `settings.set` when the gate is closed. On loopback ⇒ editable; under
  `--remote` without `--allow-writes` ⇒ read-only display, no edit affordances.
- **SEC-3 / SEC-4 preserved.** The server performs no in-process fs-write; `settings.set` dispatches
  to `write-setting.sh` via an argv array (no shell string), and the child is a shell script, never
  an agent/LLM (`integration-map.md` SEC-3/SEC-4, lines 267/312).
- **SEC-6 + CSP.** The Host-header allowlist runs before the write gate on the POST path; CSP
  `form-action 'none'` + `connect-src 'self'` keep the panel's `fetch` same-origin (feature-001).
- **Injection/traversal.** `op` from the closed table; repo path from `id_map` (never the body);
  `args.path` from the three-value allowlist; grade regex-validated; the writer itself rejects
  `\n`/`"`/`\`. No `work_id`/`delivery_id`/`task_id` is consumed (project-scoped op).

Feature-level addition: the grade control is a `<select>` bound to the `^[A-F][+-]?$` alphabet, so
an invalid grade cannot be constructed in the UI (defense-in-depth ahead of the 422).

### UI Specs

**Placement.** A new project-header panel `#project-header` is added at the **top of `#main-page`**
(before the existing `Knowledge Base` heading + `#knowledge-tool-section`, home.html line 874-877),
rendered by a new `_renderProjectHeader(model)` called first inside `renderMainPage` (line 1318).
It is the project page's identity/edit header; the per-work view (`renderWorkView`) is untouched,
and `index.html` (the all-projects grid, feature-003) is out of scope.

**Visual grounding.** Reuse the established identity-panel pattern already in this file — the
`.work-overview` panel (home.html lines 353-417: `.work-overview`, `.work-overview-identity`,
`.work-overview-title`, `.work-overview-desc`) — so the header is visually consistent with the
work-overview panel. Controls reuse existing styles: `.btn-ghost` (line 155) for buttons,
`.interval-input` (line 719) as the text-input model, `.badge` (line 178) for the grade/KB-status
chips, `.callout.err` (line 244) for inline save errors. No new CSS framework; add only a handful of
scoped classes alongside the existing `Dashboard-specific` block.

**Panel contents (redesign of the current KB-link card):**

1. **Identity + name.** Project name shown as `.work-overview-title`, sourced from
   `model.repo.project_name`. When `write_enabled`: an inline pencil/`Edit` `.btn-ghost` swaps the
   title for a text input (seeded with the current value) + `Save`/`Cancel`; Save issues
   `settings.set {path:"project.name"}`. Empty name is rejected client-side (name required).
2. **Description.** Shown as `.work-overview-desc` from `model.repo.project_description` (hidden/muted
   placeholder when empty). Same edit affordance (multi-line `<textarea>`); Save issues
   `settings.set {path:"project.description"}`; empty clears it.
3. **Global minimum grade.** A labelled `<select>` (options `A+ A A- B+ … F`, matching
   `^[A-F][+-]?$`) seeded from `model.repo.minimum_grade`; changing it issues
   `settings.set {path:"review.minimum_grade"}`. Copy notes it is the **global** default (per-work
   and per-skill overrides are out of scope). Read-only rendering shows the value as a `.badge`.
4. **Open Knowledge Base button.** A `.btn-ghost` "Open Knowledge Base" that navigates to
   `./kb.html` — preserving the exact target and clickability rule of today's KB card
   (`_renderKbCard`, href `./kb.html` line 1618: clickable only when `kb_state.status` is `approved`
   or `outdated`, otherwise a disabled button carrying the 5-state status label). This satisfies
   FR-P3(b) "keep a button to open the KB" while subsuming the standalone card into the header, so
   the 5-state KB status signal is preserved on the button rather than lost.

**write_enabled gating.** Every edit affordance (pencil buttons, inputs, Save, the `<select>`'s
editability) renders only when `model.write_enabled === true`. When false, the panel is pure
read-only display (name/description text, grade badge, KB button). This is the UI half of AC8.

**Re-render.** On a successful `settings.set`, the client re-fetches `./api/model`, swaps
`lastGoodModel`, and calls `renderMainPage` — the header re-renders from disk (AC2). The regular
poll loop is unaffected; the immediate re-fetch just collapses the drift window to one round-trip.

**Accessibility (grounded in existing patterns).** Each editable field has a `<label>` (or
`aria-label`); the panel is keyboard-operable and honours the file's `:focus-visible` outline (line
304) and `prefers-reduced-motion` rules; Save/error status is announced via an `aria-live="polite"`
region (mirroring the freshness badge at line 780); the KB button, when disabled, uses
`aria-disabled` rather than removal so its status label stays readable. Edit toggles use
`aria-expanded`, matching the existing `.work-overview-header` button (line 817).

### Migration / New Plumbing

- **Additive DM-1 fields** `repo.project_description` + `repo.minimum_grade`. No `schema_version`
  bump (stays 3; DM-A3/RC-2 precedent, additive + UI-tolerant). Older assets ignore the keys; this
  UI treats missing → `null`/fallback (fail-safe display).
- **Golden-fixture regen.** The cross-runtime parity suites' fixtures
  (`dashboard/server/tests/test_server_py.py`, `dashboard/server/tests/test_server_node.mjs`, and
  the reader fixtures under `dashboard/reader/tests/`) are regenerated in lockstep so the new keys
  appear identically in both twins (AC4). No `dashboard/MANIFEST` change — no new dashboard source
  file ships (the writer + op are feature-001's; this feature edits existing files only).
- **No data migration** — `settings.yml` is read/written in place; no format change. Reads are
  tolerant of a `settings.yml` missing `project.description` / `review.minimum_grade` (→ `None`).

### How the Acceptance Criteria are satisfied

- **AC1 (edit persists from the dashboard).** Each of the three fields dispatches `settings.set`
  (feature-001 op) → `write-setting.sh` → a surgical, atomic rewrite of the target scalar in
  `<repo>/.aid/settings.yml`. The edit is performed entirely from the header and persists to disk
  through the canonical settings writer (not `writeback-state.sh`), exactly as FR-P3 requires.
- **AC2 (truthful re-render, no drift).** On write success the client immediately re-fetches
  `./api/model` and re-renders the header from the freshly parsed on-disk model (which now carries
  `project_description` + `minimum_grade`); the displayed values are never optimistic, so they
  cannot drift from disk (NFR3).
- **(AC4, inherited work-level criterion) Reader-twin parity.** The two parser additions (one per
  settings section) and the two serializer additions are applied identically to `parsers.py`/`reader.mjs`,
  `reader.py`/`reader.mjs`, and `server.py`/`server.mjs`, with fixtures regenerated together and
  the existing parity suites as the gate.
- **(AC8, inherited) Trust model.** Edit controls and the server both honour `write_enabled`:
  editable on loopback, read-only under `--remote` without `--allow-writes`.
