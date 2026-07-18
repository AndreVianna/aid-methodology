# Write Infrastructure (Dashboard Write / Operation Foundation)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5 (New plumbing), §6 (NFR2/NFR3), §7 (C1/C2/C3), §8, §10 (P1) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): server op endpoints, writer dispatch, settings + REQUIREMENTS writers, --allow-writes gate, reader-twin parity, truthful re-render. Q1 gate design specified; Q3 resolved (build writer, not retarget). KI-001 registered. | /aid-specify |
| 2026-07-17 | Re-opened (work STATE.md Q5, user-decided) to close a foundation gap found in feature-009 review: write-op target resolution assumed the served tree and would 404 for a worktree-isolated pipeline (work-017's own topology). Added worktree-aware `resolve_work_dir` (reuses the reader's `enumerate_worktree_roots` + reconcile-winner), invariant WT-1, and a WT-1 acceptance criterion; updated Data Model / Feature Flow / Layers / API Contracts. | /aid-specify |
| 2026-07-17 | Re-opened (plan-review CRITICAL / KI-004): added the OPTIONAL per-op `status_map` field to the `OP_TABLE` row schema (dispatcher uses `op.status_map or DEFAULT_MAP`) so `aid`-CLI-backed ops (features 003/004) can map `aid`'s exit alphabet without touching the STATE-op default. Documented in Layers + API Contracts + OP_TABLE column + OP-SM acceptance note. Optional + default-behavior-preserving. | /aid-specify |

## Source

- REQUIREMENTS.md §5 ("New plumbing this work must introduce")
- REQUIREMENTS.md §6 NFR2 (single-user trust model incl. `--remote`), NFR3 (truthful re-render)
- REQUIREMENTS.md §7 C1 (single-writer invariant), C2 (DERIVED sections stay read-only), C3 (no new network surface)
- REQUIREMENTS.md §8 (dependencies + new plumbing)
- REQUIREMENTS.md §10 (P1 — write infrastructure enabler)

## Description

The foundation that makes the dashboard interactive. Today the server only reads and
serves state over a closed GET allowlist and never writes to disk. This feature adds the
write / operation endpoints on the dashboard server, wires every Pipeline and Task state
write through the existing single writer (`writeback-state.sh`) so a dashboard edit is
indistinguishable from an agent edit at the write layer, adds a non-interactive
`settings.yml` writer (needed because `/aid-config` is interactive today), keeps the
Python reader and its `reader.mjs` twin byte-consistent, and re-renders truthfully so the
view never drifts from disk. DERIVED union views are never written directly — edits target
the AUTHORED source cell or frontmatter of the owning unit.

This feature exposes no single user-facing interaction on its own; it is the plumbing every
other feature in this work depends on.

## User Stories

- As a developer running AID on my own project, I want the dashboard to write to disk
  safely through the same single writer the agents use, so that every interactive change I
  make persists correctly and the view stays truthful to disk.

## Priority

Must

## Acceptance Criteria

- [ ] AC2 — Given any dashboard write or operation, when it completes, then the dashboard
  reflects the new on-disk state with no drift.
- [ ] AC3 — Given a Pipeline or Task state write, when it is persisted, then it goes through
  `writeback-state.sh` and no DERIVED section is ever hand-written.
- [ ] AC4 — Given a change to the reader/parser layer, when the readers run, then the Python
  reader and `reader.mjs` stay byte-consistent (parity).
- [ ] AC8 — On loopback, writes/operations work fully. Under `--remote`, the dashboard is
  read-only unless the explicit write opt-in is set; when opted in (flag + tailnet ACL),
  writes work. No built-in auth is introduced.
- [ ] WT-1 — Given a write op for a pipeline that lives in a worktree (not the served
  tree's `.aid/works/`), when the op runs, then it targets the exact on-disk work directory
  the reader resolved for that `work_id` (via `resolve_work_dir`) — never a reconstructed
  served-tree path — and returns 404 when the work resolves to nothing.
- [ ] OP-SM — Given an op whose `OP_TABLE` row declares a `status_map`, when its writer
  exits, then the dispatcher maps the exit code → HTTP status via that op's `status_map`;
  and given an op with no `status_map`, then it uses `DEFAULT_MAP` unchanged. (The optional
  field is the foundation contract the `aid`-CLI-backed ops of features 003/004 rely on.)

## Open Questions

- **STATE.md Q1 — RESOLVED (2026-07-17); gate design SPECIFIED (2026-07-17, /aid-specify).**
  `aid dashboard --remote` is **live** (tailscale `serve`), not a stub (the KB
  `infrastructure.md` entry is stale). It exposes the dashboard to the whole tailnet with no
  auth. **Decision (user):** opt-in remote writes — loopback is fully interactive; under
  `--remote` the dashboard is **read-only by default**, and writable interactions require an
  explicit opt-in (`--remote --allow-writes`) plus a documented, user-scoped tailnet ACL. No
  built-in auth added. **Gate design (this spec, §Security Specs):** a fail-safe server flag
  `--allow-writes` (default OFF) that `bin/aid` `_dc_start` appends to the spawn argv iff
  `write_enabled = (loopback) OR (--remote AND --allow-writes)`; the server refuses every
  mutation (HTTP 403) unless spawned write-enabled, and echoes `write_enabled` into the DM
  envelopes so the UI hides write controls it cannot use. See NFR2 / C3 / AC8 and work
  `STATE.md` § Cross-phase Q&A → **Q1**.

- **STATE.md Q3 — RESOLVED (2026-07-17, /aid-specify): build a writer, do NOT retarget.**
  FR-PL1 renames a pipeline by editing `REQUIREMENTS.md`'s `- **Name:**` line. This spec
  introduces a small non-interactive `write-requirement.sh` (surgical single-line rewrite of
  the `- **Name:**` / `- **Description:**` bullet), because that line is the single source of
  truth the reader twins already parse into `WorkModel.title`
  (`parse_requirements_md` / `parseRequirementsMd`). Retargeting to a STATE.md frontmatter cell
  was rejected: no `title` frontmatter key exists, the work-state template forbids authoring
  identity fields there ("`title`/`description`/`objective` … NEVER authored here — computed at
  read time"), and adding one would need a reader change + a precedence rule — strictly more
  plumbing and parity risk than the line writer. §8 "New plumbing" already lists this writer;
  the design is in §API Contracts / §Layers & Components below.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This is the **foundation** feature:
> it delivers the write *mechanism* (server endpoints, writer dispatch, the write gate, the
> re-render contract, the reader-twin parity discipline) plus the two brand-new writers it owns
> (`write-setting.sh`, `write-requirement.sh`) and the wiring of the existing single writer
> (`writeback-state.sh`). Individual interactions (header edit, task notes, rename, delete, …)
> live in features 002–010 and register their op handlers against the dispatch table defined here.
>
> **Grounding anchors:** dashboard server twins `dashboard/server/server.py` +
> `dashboard/server/server.mjs`; reader twins `dashboard/reader/` (Python) +
> `dashboard/server/reader.mjs` (Node); single writer
> `.claude/aid/scripts/execute/writeback-state.sh`; settings reader
> `.claude/aid/scripts/config/read-setting.sh`; CLI `bin/aid` (`_cmd_dashboard_ctl`, `_dc_start`,
> `_aid_remote_expose`); KB `integration-map.md` (SEC-1/3/4/6, DM contracts, dashboard server).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The store is the on-disk `.aid/` artifact set; no relational schema. |
| Feature Flow | Present | The POST → gate → dispatch → writer → re-fetch round-trip is the core of the feature. |
| Layers & Components | Present | Server / writer / reader-model / UI-gate layers all change. |
| API Contracts | Present | New POST write/operation endpoints — request/response schema + status mapping. |
| Security Specs | Present | The `--allow-writes` gate, SEC-1/3/4/6 preservation, injection/traversal defenses, tailnet ACL. |
| Migration / New Plumbing | Present | Additive `write_enabled` envelope key; co-vendored writer scripts (install-manifest lockstep). |
| UI Specs | N/A | The foundation adds no UI components; consuming features (002/005/006/…) add controls. This spec only defines the `write_enabled` gating signal + re-render contract they consume. |
| State Machines | N/A | No new state machine. Lifecycle/task enums are owned by `writeback-state.sh` + `artifact-schemas.md`; the "stopped-task" enum question (OQ-T2) is deferred to feature-008. |
| Telemetry & Tracking | N/A | Single-user trust model; no audit requirement. Writers print `OK:` lines and the server logs failures to stderr — sufficient. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback file-mutation foundation. |

### Data Model

**No database and no relational schema.** The "store" is the on-disk AID artifact set under
each repo's `.aid/`; writes are surgical mutations of those files, each owned by exactly one
writer (C1). The write targets and their owning writer:

| Target file | Field(s) written | Owning writer | Zone (three-zone vocabulary per `work-state-template.md`; `artifact-schemas.md` uses a two-zone model that subsumes frontmatter into AUTHORED) |
|-------------|------------------|---------------|----------------------------------|
| `<resolved-work-dir>/STATE.md` (or per-task/-delivery `STATE.md` beneath it) | `lifecycle`, `phase`, `active_skill`, task `state`/`review`/`elapsed`/`notes`, delivery scalars | `writeback-state.sh` (existing) | FRONTMATTER / AUTHORED — never DERIVED (C2) |
| `<served-root>/.aid/settings.yml` | `project.name`, `project.description`, `review.minimum_grade` | `write-setting.sh` (**new**) | settings (flat-section YAML) |
| `<resolved-work-dir>/REQUIREMENTS.md` | `- **Name:**`, `- **Description:**` bullet | `write-requirement.sh` (**new**) | AUTHORED content file (identity source) |

**`<resolved-work-dir>` is worktree-aware — NOT a reconstructed served-tree path (Q5).** A pipeline
folder may live under the served project's own `.aid/works/`, **or** under a git worktree of that
project (`.claude/worktrees/<wt>/.aid/works/<work_id>/`) — the exact topology work-017 itself runs
in. The dashboard reader does not assume `<served-root>/.aid/works/<work_id>`; it enumerates every
work by walking the served repo's git worktrees (`locator.enumerate_worktree_roots`, `locator.py`
line 126 — `git worktree list --porcelain`, main worktree first) and reading each worktree's
`.aid/works/*` (`_enumerate_work_dirs`, `locator.py` line 70). When the same `work_id` appears in
more than one worktree, `_reconcile_same_work` (`reader.py` line 131) picks the **newest-`updated`**
copy (tie → `branch_label` lexical, `main` first) as the rendered winner. **Worktree-isolated
pipelines therefore surface under the PARENT registered project, not as separate registry entries**
(verified: `enumerate_worktree_roots` runs on the served repo root and returns all its linked
worktrees — there is no per-worktree registry row). The serialized model carries only `work_id`
(no `branch_label`, no absolute directory — see `_ser_work`), so the write path MUST re-resolve the
real directory server-side rather than reconstruct it. `<served-root>/.aid/settings.yml`
(project-scoped) is NOT worktree-resolved — it is read from the served root's `.aid/` exactly as the
reader reads it (`_read_settings(canon_path)`), so `settings.set` correctly targets the served root.

**Invariant WT-1.** A write op targets **exactly the on-disk work directory the reader resolved for
that `work_id`** (worktree-aware, via the shared resolver in §Layers) — never a reconstructed
`<served-root>/.aid/works/<work_id>/` path.

**No DERIVED section is ever a write target (C2).** The DERIVED union views (Tasks State,
Plan/Deliveries, Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches) are assembled at
read time by the reader twins; every dashboard edit targets the AUTHORED source cell / frontmatter
of the owning unit, exactly as an agent edit does. `writeback-state.sh` already enforces this by
construction — its `--pipeline`/`--task-id`/`--delivery-id` modes write only frontmatter scalars,
the per-task row of the flattened `### Tasks lifecycle` table, or per-unit authored blocks; it has
no mode that writes a union view.

**Envelope model change (additive):** a single boolean `write_enabled` key is added to the DM-1
model envelope (`serialize_model`, top level beside `generated_by`) and the DM-2 `machine` block
(`build_home_model`, after `cli_runtime`). See §Migration and §API Contracts. No other model field
changes.

### Feature Flow

```
Browser (home.html / index.html)                    Dashboard server (server.py | server.mjs)
────────────────────────────────                    ──────────────────────────────────────────
user clicks a write control
  │  (control only rendered when model.write_enabled == true)
  ▼
POST /r/<id>/api/op            ── HTTP ──▶  do_POST / handler(method==POST)
  body: {op, target:{work_id,             │  1. SEC-6 Host-header allowlist  (_reject_bad_host)  → 403 on fail
         delivery_id?, task_id?}, args}   │  2. write gate: self.write_enabled?                  → 403 "read-only"
                                          │  3. parse JSON body; unknown/oversize → 400
                                          │  4. op ∈ OP_TABLE allowlist?          → 400 unknown op
                                          │  5. resolve <id> → served repo root (id_map, verbatim; SEC-2)
                                          │  6. if op is pipeline-scoped: validate target.work_id
                                          │     (^work-[0-9]); resolve_work_dir(root, work_id) →
                                          │     REAL on-disk dir via worktree-aware resolver → 404
                                          │     if no copy in any worktree (settings/home ops skip; WT-1)
                                          │  7. validate args per op schema (enum/len/charset)  → 422
                                          │  8. build argv ARRAY (no shell string) for the op's
                                          │     writer; point AID_STATE_FILE / AID_WORK_DIR /
                                          │     AID_REQUIREMENTS_FILE at the RESOLVED work dir
                                          │     (settings: --file <served-root>/.aid/settings.yml)
                                          │  9. spawn child: bash <vendored writer> …            (SEC-3: no in-process
                                          │     capture exit code + stderr                        fs-write; SEC-4: child
                                          │                                                       is a shell script,
                                          │                                                       never an agent/LLM)
                                          │ 10. map writer exit code → HTTP status (table below)
  ◀── 200 {ok:true, op} ── or ── 4xx/5xx {ok:false, error, detail} ──┘
  │
  ▼ on ok
targeted re-fetch:
  GET /r/<id>/api/model   (per-repo ops)   ── truthful re-render from disk (NFR3/AC2)
  GET /api/home           (home ops)
  ▼
swap model → re-render (drift window = one immediate re-fetch, not the poll interval)
```

Home-level operations that are not scoped to a single existing repo id (Add Project;
feature-003) use the sibling route **`POST /api/op`** with the same envelope minus `target.work_id`
resolution; on success the client re-fetches `/api/home`. feature-001 defines both routes; it seeds
the per-repo table and leaves `/api/op` handlers to the registry feature.

### Layers & Components

**1. Server layer** (`dashboard/server/server.py` + `dashboard/server/server.mjs`, byte-parity twins):

- **Routing.** Today every non-GET verb short-circuits to 405 (`server.py` `do_POST` line ~906;
  `server.mjs` `handler` `method !== "GET"` guard line ~682). Replace the blanket 405 for **POST**
  with a router: `POST /r/<id>/api/op` → `_serve_op` (per-repo); `POST /api/op` → `_serve_home_op`
  (home-level); any other POST path → 405 (unchanged). PUT/DELETE/PATCH/HEAD stay 405 — the API is
  POST-only for mutations (no REST verbs; simplest surface, easiest to gate and to keep twin-parity).
- **Host-header + write gate.** `_serve_op` runs *after* the existing `_reject_bad_host` (SEC-6)
  and then checks `self.write_enabled` (Python) / module `WRITE_ENABLED` (Node). Not enabled → a
  JSON `{ok:false,error:"read-only"}` with HTTP 403. This is the single enforcement point for AC8.
- **Op dispatch table** (`OP_TABLE`): a static, closed dict mapping `op` → `{writer, argv-builder,
  arg-schema, scope, status_map?}`. The server never interprets a client-supplied path or command;
  it only picks a pre-declared writer and fills its argv from validated, server-resolved values. The
  **optional 5th field `status_map`** is a per-op exit-code→HTTP override: the dispatcher resolves the
  effective map as **`op.status_map or DEFAULT_MAP`** — absent ⇒ the op uses the default
  `writeback-state.sh`-derived map (§API Contracts); present ⇒ the dispatcher uses the op's own map.
  This exists because the `aid`-CLI-backed ops (features 003/004) shell out to `aid`, whose exit-code
  alphabet differs from `writeback-state.sh`'s. Seeded by this feature (see §API Contracts); extended
  by later features.
- **Child-process invocation.** The server shells out via `subprocess.run([...], ...)` (Python) /
  `child_process.execFileSync`/`spawnSync` (Node) with an **argument array** (never `shell=True`,
  never a concatenated command string). SEC-3 is refined, not broken: the server file still contains
  **no in-process fs-write primitive** (`open(...,'w')`, `writeFileSync`, `appendFile`, `unlink`);
  all mutation happens in a separate, canonical writer process. SEC-4 holds: the child is a shell
  script or the `aid` CLI — never an agent/LLM import.

**2. Writer layer** (the processes the server dispatches to):

- `writeback-state.sh` — **existing single writer**, unchanged. Invoked for STATE writes with
  `AID_STATE_FILE=<resolved-work-dir>/STATE.md` and `AID_WORK_DIR=<resolved-work-dir>` (both honored
  today, lines ~157/161), where `<resolved-work-dir>` is the **worktree-aware** directory returned by
  the shared resolver (component 3 below) — never a reconstructed served-tree path (WT-1). The script
  then auto-detects flat vs nested layout (`is_flat_layout`) and resolves per-task/-delivery paths
  itself. The server passes `--delivery-id` when the model's `TaskModel.delivery` is set (nested), or
  omits it (flat). No change to the script.
- `write-setting.sh` — **new**, a scriptable counterpart to `read-setting.sh`. Writes one scalar to
  `.aid/settings.yml`. See §API Contracts for its contract.
- `write-requirement.sh` — **new**, surgical single-line rewrite of the `- **Name:**` /
  `- **Description:**` bullet in a work's `REQUIREMENTS.md` (Q3 resolution).
- `aid` CLI (`bin/aid`) — for operation-triggering ops owned by later features (`aid projects
  add/remove`, `aid update`); listed here for completeness, not built by feature-001.

  **Locating the writers at runtime.** `writeback-state.sh` lives in the per-project *profile* tree
  (`.claude/aid/scripts/…`, `.codex/aid/scripts/…`, …), not in the CLI vendor (`packages/npm`
  `files`: `bin/`, `lib/`, `dashboard/`). The reader/writer STATE.md frontmatter format is a shared
  contract, so the writer MUST be version-locked to the running server+reader unit. **Decision:**
  co-vendor the canonical writers (`writeback-state.sh`, `write-setting.sh`, `write-requirement.sh`)
  with the dashboard unit and self-locate them from `$AID_CODE_HOME` (as `home.html` is CLI-served
  to avoid per-repo staleness — same rationale, `bin/aid` line ~1196 `assets_dir="$AID_CODE_HOME/
  dashboard"`). The dashboard file set is single-sourced: adding these three scripts is a **one-file
  edit of `dashboard/MANIFEST`** (one path per line), from which `vendor.js`, `vendor.py`,
  `install.sh`, `install.ps1`, and `release.sh`'s CLI bundle all derive their file set — guarded by
  `tests/canonical/test-dashboard-manifest.sh` (H1 fix, `tech-debt.md`: "Add/remove a dashboard
  source file by editing `dashboard/MANIFEST` only"). See §Migration.

**3. Reader / model layer** (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`): **no parser
change** (the writers round-trip the *existing* parsed formats), plus **one new worktree-aware
resolver** that reuses the reader's own enumeration + reconciliation logic:

- **`resolve_work_dir(served_root, work_id) → Path | None`** (new; a Python function in the reader
  package + its `reader.mjs` twin). It reuses `enumerate_worktree_roots` (`locator.py` line 126) to
  walk the served repo's git worktrees, selects the copies whose `<wt>/.aid/works/<work_id>` exists,
  and applies the **same winner rule** as `_reconcile_same_work` step 2 (`reader.py` line 131 —
  newest `updated`; tie → `branch_label` lexical, `main` first), so the directory it returns is the
  very copy the reader rendered (WT-1 / AC2). Returns `None` (→ 404) when no worktree holds the
  `work_id`. It inherits the reader's SD-3 degradation (git absent / non-git → main-root-only), so it
  can only ever be asked to target a work the reader itself surfaced — consistency by construction.
  It lives in the reader layer (single source of truth for "where does a `work_id` live"); the server
  imports it alongside the existing `read_repo` / `read_repo_detail` and feeds its result into
  `AID_WORK_DIR` / `AID_STATE_FILE` / `AID_REQUIREMENTS_FILE`. _(Consumer note: `resolve_work_dir`
  returns the work **directory**, which is all the STATE / notes / rename ops need. feature-009's
  destructive delete additionally needs the owning **worktree root + branch** to run
  `git worktree remove`; it derives both from the same `enumerate_worktree_roots` `(branch_label,
  aid_dir)` pairs — `aid_dir.parent` is the worktree root — a thin reuse of this enumeration, not new
  plumbing. feature-008's stop/resume signal must likewise target the resolver's work dir, never a
  reconstructed path.)_
- `write-requirement.sh` writes exactly the bullet `parse_requirements_md` /`parseRequirementsMd`
  read via `^\s*-\s*\*\*Name:\*\*\s*(.+)` (`parsers.py` `_re_name` line ~664; reader.mjs `RE_NAME`
  line 1695) → `WorkModel.title` (`models.py` line 320). FR-PL1's *display* switch (render `title`,
  fall back to slug `name`) is a home.html change owned by feature-005 — no reader change here.
- `write-setting.sh` writes `project.name`/`description`/`review.minimum_grade` in the flat-section
  shape the settings readers already consume.

The only *serializer* change is the additive `write_enabled` key in both DM envelopes — applied
**identically** to `server.py` and `server.mjs` (and their fixtures) to preserve DM-3 byte-parity.
The new `resolve_work_dir` is likewise added to both reader twins identically (AC4).

**4. UI gating layer** (`dashboard/index.html`, `dashboard/home.html`): consuming features render a
write control only when `model.write_enabled === true` and re-fetch on op success. feature-001 owns
only the *signal* and the *re-render contract*, not the controls.

### API Contracts

**New endpoints (POST-only mutation surface; both twins, byte-parity request/response):**

`POST /r/<id>/api/op` — per-repo operation. `POST /api/op` — home-level operation.

**Request** (`Content-Type: application/json`, body ≤ 64 KiB — larger → 400):

```json
{ "op": "task.set-notes",
  "target": { "work_id": "work-017-cli-improvements", "delivery_id": null, "task_id": "task-003" },
  "args": { "value": "blocked on upstream fix" } }
```

- `op` (required): a key in the closed `OP_TABLE`. Unknown → 400.
- `target.work_id` (required for **pipeline-scoped** ops — those that write STATE.md or
  REQUIREMENTS.md, e.g. `task.set-notes`, `pipeline.finish`, `pipeline.rename`): validated
  `^work-[0-9]+`, then resolved to its **real on-disk directory** by the worktree-aware
  `resolve_work_dir(served_root, work_id)` (§Layers component 3). A `None` result — no git worktree
  of the served repo holds the `work_id` — → 404. The op targets whatever directory the resolver
  returns (WT-1); it never tests or uses a reconstructed `<served-root>/.aid/works/<work_id>` path.
  It is **omitted for project-scoped ops** whose writer takes no work (`settings.set` →
  `write-setting.sh` targets `<served-root>/.aid/settings.yml`, read from the served root exactly as
  `_read_settings` reads it); each op's schema in `OP_TABLE` declares whether it consumes `work_id`.
  In all cases `<id>` alone resolves the served repo root (verbatim from `id_map`, SEC-2) and the
  work directory is resolver-derived — **paths are never taken from the body** (traversal-proof).
- `target.delivery_id` / `target.task_id`: `^\d{1,3}$` when present.
- `args`: per-op, validated against the op's schema before any child spawn.

**Success (200):** `{ "ok": true, "op": "<op>" }`. The client then re-fetches the owning GET
endpoint and re-renders (NFR3/AC2). (The server MAY inline the fresh model as a future optimization;
the contract only requires `ok`.)

**Failure:** `{ "ok": false, "op": "<op>", "error": "<class>", "detail": "<writer stderr, ≤1 KiB>" }`
with status per the op's effective map — **`op.status_map or DEFAULT_MAP`**. `DEFAULT_MAP` (below) is
derived from `writeback-state.sh` exit codes (lines ~142–149; `write-setting.sh` /
`write-requirement.sh` reuse the same alphabet):

| Condition | Writer exit | HTTP | `error` |
|-----------|-------------|------|---------|
| Untrusted Host header | — | 403 | `bad-host` |
| Write gate closed (read-only) | — | 403 | `read-only` |
| Malformed/oversize body, unknown `op`, bad `target` shape | — | 400 | `bad-request` |
| Unknown repo `<id>`, or `resolve_work_dir` returns None (no worktree holds `work_id`) | 1 | 404 | `not-found` |
| Invalid arg value (enum/grade/charset) | 4 | 422 | `invalid-value` |
| Missing required writer arg | 5 | 422 | `invalid-value` |
| Lock contention (another writer holds the sentinel) | 2 | 409 | `busy` |
| Empty/unverifiable write, malformed STATE.md, other | 3/6/* | 500 | `write-failed` |

**Per-op `status_map` override.** An `OP_TABLE` row MAY carry an optional `status_map` — a table in
the same `{writer-exit → (HTTP, error)}` shape as `DEFAULT_MAP` — which the dispatcher uses **instead
of** `DEFAULT_MAP` for that op. The field is **optional and additive**: a row without it behaves
exactly as before (STATE/settings/requirement ops are unaffected). It exists so `aid`-CLI-backed ops
can map `aid`'s own exit-code alphabet (which differs from `writeback-state.sh`'s) to the right HTTP
statuses; features 003/004 supply the concrete `aid` maps.

**`OP_TABLE` seeded by feature-001** (later features append rows). The `status_map` column names the
effective map: **default** = uses `DEFAULT_MAP` (no override field); **override** = the owning feature
supplies a per-op `status_map` for `aid`'s exit alphabet.

| `op` | Scope | Writer + argv | `status_map` | Owning FR | Introduced by |
|------|-------|---------------|--------------|-----------|---------------|
| `task.set-notes` | per-repo | `writeback-state.sh --task-id <t> [--delivery-id <d>] --field Notes --value <v>` (env `AID_STATE_FILE`/`AID_WORK_DIR` = `resolve_work_dir` output; worktree-aware) | default | FR-T2 | feature-001 (used by 006) |
| `pipeline.finish` | per-repo | `writeback-state.sh --pipeline --field Lifecycle --value Completed` — value is **fixed to `Completed`** (the op takes no lifecycle argument); the server never forwards any other of `writeback-state.sh`'s Lifecycle enum values, so general pipeline-lifecycle editing stays closed per REQUIREMENTS §5.2 (Pipeline level = Rename/Finish/Delete only) | default | FR-PL2 (state half) | feature-001 (used by 008) |
| `settings.set` | per-repo (project-scoped; no `work_id`) | `write-setting.sh --path <project.name\|project.description\|review.minimum_grade> --value <v> --file <served-root>/.aid/settings.yml` | default | FR-P3 | feature-001 (used by 002) |
| `pipeline.rename` | per-repo | `write-requirement.sh --field Name --value <v>` (env `AID_REQUIREMENTS_FILE=<resolved-work-dir>/REQUIREMENTS.md`, from `resolve_work_dir`) | default | FR-PL1 | feature-001 (used by 005) |
| `project.add` / `project.remove` | home | `aid projects add/remove …` | **override** (`aid` exit alphabet; set by feature-003) | FR-P1/P2 | feature-003 |
| `tools.update` / `tools.update-self` | per-repo/home | `aid update` / `aid update self` | **override** (`aid` exit alphabet; set by feature-004) | FR-P6 | feature-004 |
| `task.rename`, `task.stop`/`resume`, `pipeline.delete`, connector/external-sources | per-repo | see owning features | per owning feature | FR-T1/T3, FR-PL3, FR-P5/P4 | 005/008/009/007/010 |

**`write-setting.sh` contract** (new; sibling of `read-setting.sh`):

```
write-setting.sh --path <section.key> --value <V> [--file <settings.yml>]
```
- Allowed `--path` (closed allowlist for the dashboard's needs): `project.name`,
  `project.description`, `review.minimum_grade`. Any other path → exit 4.
- `review.minimum_grade` validated `^[A-F][+-]?$` (same alphabet as `writeback-state.sh`'s grade
  check). `--value` rejects `\n`, embedded `"` and `\` → exit 4 (see KI-001: keeps the written
  value inside the strip-only alphabet every settings reader round-trips identically).
- Surgical flat-section rewrite of the `<section>:` → `  <key>: <value>` line (mirrors
  `read-setting.sh`'s `lookup` model); creates the key (and section) if absent; every other line
  byte-preserved; atomic temp-file + `mv`. Exit codes mirror `read-setting.sh` (0 ok; 2 arg/IO;
  plus 4 invalid value). bash-only (as `read-setting.sh` is; the dashboard already requires bash).

**`write-requirement.sh` contract** (new; Q3 resolution):

```
write-requirement.sh --field <Name|Description> --value <V> [env AID_REQUIREMENTS_FILE=<abs path>]
```
- Target: `AID_REQUIREMENTS_FILE` if set, else `<cwd>/REQUIREMENTS.md`.
- Surgical rewrite of the single `^\s*-\s*\*\*<Field>:\*\*\s*.*` bullet (matching the reader regex);
  creates it under the leading `# Requirements` heading if absent; all other lines byte-preserved;
  atomic temp-file + `mv`. `--value` rejects `\n`/`|` → exit 4. Non-destructive: touches only that
  bullet — never the work folder, branch, or worktree (AC5). Exit codes as above. bash-only.

### Security Specs

**The write gate (Q1 / NFR2 / C3 / AC8) — fail-safe, opt-in-under-remote.**

- **New CLI flag.** `aid dashboard start` gains `--allow-writes` (parsed in `_cmd_dashboard_ctl`
  arg loop, `bin/aid` ~line 1049, beside `--remote`/`--port`/`--verbose`; rejected for the `stop`
  verb like `--remote` is). `_dc_start` receives it as a 5th positional.
- **Policy** (`_dc_start`, `bin/aid` ~line 1141): `write_enabled = (remote == 0) || (remote == 1
  && allow_writes == 1)`. Loopback ⇒ always write-enabled. `--remote` without `--allow-writes` ⇒
  read-only. `--remote --allow-writes` ⇒ write-enabled (and the existing `_aid_remote_expose`
  tailnet-ACL guidance, ~line 951, is the documented user-scoped ACL note — extend it to state that
  writes are now reachable by every granted identity). `--allow-writes` on loopback is accepted and
  redundant (documented; no error).
- **How the server learns it — fail-safe default.** `_dc_start` appends `--allow-writes` to the
  interpreter argv **iff** `write_enabled` (extending the existing spawn line
  `… "$entry_point" --host 127.0.0.1 --port "$port"`, ~line 1216). The server's `_parse_args`
  (`server.py` ~line 1113; `server.mjs` `parseArgs` ~line 65) gains a `--allow-writes` store-true;
  **absent ⇒ read-only.** A bare `python server.py --host 127.0.0.1 --port N` (no flag) is therefore
  read-only — the safe default. Like `--host`, the flag is a fixed token, never read from
  request/config/env, so SEC-1's "never read the bind from input" posture is unaffected.
- **Enforcement.** The server refuses every mutation (HTTP 403 `read-only`) unless `write_enabled`
  — checked in `_serve_op`/`_serve_home_op` right after the Host-header allowlist, before any op
  dispatch. This is the AC8 enforcement point. `write_enabled` is also echoed in both DM envelopes
  so the UI never offers a control the server will refuse (defense-in-depth + UX).
- **No built-in auth** is added (NFR2). On the tailnet, the *only* access control is the user's
  Tailscale ACL grant; the spec's `_aid_remote_expose` guidance already prints a deny-by-default
  grant template (`{"grants":[{"src":[…],"dst":[…],"ip":["tcp:443"]}]}`), and must add the line:
  "with `--allow-writes`, any granted identity can also modify this project's state."

**Preserved invariants (no new network surface — C3):**

- **SEC-1** unchanged — literal `127.0.0.1` bind only; the `--allow-writes` flag is orthogonal to the
  bind and never widens it. No listener is added; the write endpoints ride the existing loopback
  server and (opt-in) the existing tailscale `serve` frontend. No new port, no new process.
- **SEC-3 refined** — the server performs **no in-process filesystem mutation**; it delegates to the
  canonical writer processes. The server-file audit (`grep` for `open(...,'w')` / `writeFileSync` /
  `appendFile` / `unlink` / `os.remove`) must stay empty; the only new syscalls are
  `subprocess`/`child_process` of an allowlisted writer with an argv array.
- **SEC-4 unchanged** — no agent/LLM import in the server; dispatched children are shell scripts or
  the `aid` CLI.
- **SEC-6 unchanged and now load-bearing for writes** — the Host-header anti-DNS-rebinding allowlist
  runs before the write gate on the POST path, so a malicious page cannot drive a mutation through a
  victim's browser even on a write-enabled loopback server. CSP `form-action 'none'` +
  `connect-src 'self'` already constrain the page to same-origin `fetch`.

**Injection / traversal defenses:** argv arrays only (no shell); `op` from a closed allowlist;
`work_id`/`delivery_id`/`task_id` regex-validated; repo path resolved server-side from `id_map`
(never from the body); writer args validated against per-op schemas before spawn; writers themselves
reject `|`/newline (`writeback-state.sh` `mode_field` already does, lines ~733/738).

### Migration / New Plumbing

- **Additive envelope key `write_enabled`** in DM-1 (`serialize_model`) and DM-2 (`machine`).
  Back-compat: an older `index.html`/`home.html` that predates the key ignores it; a newer UI treats
  **missing ⇒ false** (fail-safe). Following the DM-A3 (task-064) and RC-2 no-bump precedents,
  **do not bump** `schema_version` (DM-1 stays 3, DM-2 stays 1) — the key is purely additive and the
  UI defaults it. Golden fixtures for the twin byte-parity suites are regenerated in lockstep.
- **Co-vendored writer scripts.** `writeback-state.sh`, `write-setting.sh`, `write-requirement.sh`
  ship inside the dashboard unit (self-located from `$AID_CODE_HOME`). Add them by **editing
  `dashboard/MANIFEST` only** (one path per line): `vendor.js`, `vendor.py`, `install.sh`,
  `install.ps1`, and `release.sh`'s CLI bundle all derive their file set from that single source,
  and `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts from the curated
  `dashboard/` tree or a consumer stops referencing it (H1 fix, per `tech-debt.md`). _(Note: the
  `integration-map.md` "Install-manifest contract" still describes the older four-way inline-lockstep
  framing; the `dashboard/MANIFEST` single-source mechanism supersedes it for dashboard files — a KB
  follow-up item.)_
- **No data migration** — existing `.aid/` state is read/written in place; no format change to any
  artifact. `writeback-state.sh` is untouched.
- **KB follow-up (out of scope for this write; flagged for the human) — full post-ship punch-list:**
  (1) `integration-map.md` (Write surface = "none"; "read-only"; the SEC-3 invariant) and the
  `server.py`/`server.mjs` header comments ("No write/append/remove primitive anywhere (SEC-3)")
  describe the pre-feature server and will need the SEC-3-refined wording once this ships;
  (2) `infrastructure.md`'s stale `--remote`-stub entry (Q1) needs correcting; and
  (3) `integration-map.md`'s "Install-manifest contract" four-way inline-lockstep framing is
  superseded by the `dashboard/MANIFEST` single-source mechanism for dashboard files (see the
  Co-vendored-writer-scripts note in Migration above).

### How the Acceptance Criteria are satisfied

- **AC2 (truthful re-render / NFR3).** Every successful op returns `ok` and the client performs an
  immediate targeted re-fetch — `/r/<id>/api/model` (per-repo) or `/api/home` (home) — then swaps in
  the fresh model. State is rendered from a post-write GET off disk, so the view cannot drift; the
  drift window collapses from the poll interval to one immediate round-trip.
- **AC3 (single-writer intact / C1+C2).** All Pipeline/Task STATE writes are dispatched to the
  existing `writeback-state.sh` via `AID_STATE_FILE`/`AID_WORK_DIR` pointed at the reader-resolved
  work directory (WT-1); the server has no STATE-writing code of its own, so a dashboard STATE edit is
  byte-indistinguishable from an agent edit. No op in `OP_TABLE` targets a DERIVED union view —
  settings/REQUIREMENTS writers target AUTHORED files, and `writeback-state.sh` only ever writes
  frontmatter scalars / the flattened task row / per-unit authored blocks.
- **AC4 (reader twins in parity).** feature-001 makes **zero parser changes** (writers round-trip
  the existing parsed formats), adds **one new reader-layer function** (`resolve_work_dir`, which
  reuses the existing `enumerate_worktree_roots` + reconcile-winner logic) to BOTH twins identically,
  and makes exactly one *additive* serializer change (`write_enabled`) in both. The new server
  op-routing/gate/dispatch code is added to both twins with identical behavior and response bytes,
  guarded by the existing cross-runtime parity suites (`dashboard/server/tests/test_server_node.mjs`,
  `test_server_py.py`) with fixtures regenerated together.
- **WT-1 (worktree-aware targeting — Q5).** Every pipeline-scoped op resolves its target via
  `resolve_work_dir`, which reuses the reader's worktree enumeration + newest-`updated` reconcile
  winner, so the op writes **exactly the on-disk file the reader read** — including a
  worktree-isolated pipeline under `.claude/worktrees/<wt>/.aid/works/<work_id>/` (work-017's own
  topology) — and never a reconstructed served-tree path. A `work_id` with no copy in any worktree of
  the served repo yields 404 (the reader would not have rendered it either).
- **AC8 (trust model enforced).** Loopback ⇒ server spawned with `--allow-writes` ⇒ writes work.
  `--remote` alone ⇒ server spawned WITHOUT the flag ⇒ every mutation 403s (read-only), and the UI
  hides write controls (`write_enabled:false`). `--remote --allow-writes` ⇒ writes work, gated only
  by the user's tailnet ACL; no built-in auth is introduced, and no new network surface is added
  beyond the existing loopback bind + tailscale `serve` (C3).
- **OP-SM (per-op status-map override — plan-review / KI-004).** The `OP_TABLE` row schema carries an
  **optional** `status_map` field and the dispatcher resolves the effective map as
  `op.status_map or DEFAULT_MAP`. This is a **contract consumers 003/004 rely on**: their `aid`-CLI
  ops attach a `status_map` for `aid`'s exit-code alphabet without touching the dispatcher or the
  STATE-op default. The field is optional and additive — seeded feature-001 rows omit it and their
  behavior is unchanged (`DEFAULT_MAP`).
