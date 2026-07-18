# External Sources List

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.1 (FR-P4) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous /aid-specify): new co-vendored `write-external-source.sh` writer; `external-source.add`/`.remove` ops appended to feature-001's `OP_TABLE`; additive `repo.external_sources` DM-1 key that REUSES the existing parity-tested `parse_doc_frontmatter` `sources:` parser (both twins) — no new parser; home.html external-sources list gated on `write_enabled`. OQ-P4 RESOLVED (frontmatter `sources:` = machine source of truth; body `## Sources` kept in sync as a minimal managed bullet mirror). Scout-vs-dashboard shared-writer conflict on `external-sources.md` registered as work `known-issues.md` KI-005 + STATE.md Cross-phase Q&A Q5 (silent-data-loss path; human ownership decision required before EXECUTE). | /aid-specify |

## Source

- REQUIREMENTS.md §5.1 FR-P4 (External sources list)

## Description

A separate list on the project page (`home.html`) to view, add, and remove external-sources
registry entries (`.aid/knowledge/external-sources.md`). This is the only P3 item because it
requires brand-new writer plumbing: `external-sources.md` has no dedicated add/remove path
today (discovery / Q&A only).

Depends on the write-infrastructure foundation (feature-001) and on a new external-sources
writer (see Open Questions).

## User Stories

- As a developer running AID on my own project, I want to view and manage my project's
  external sources from the dashboard, so that I can register or drop a reference doc without
  hand-editing the KB registry.

## Priority

Should  _(promoted from Could 2026-07-17: shares list-CRUD UI + discover-authoritative ownership with connectors; Q6 resolved, unblocked)_

## Acceptance Criteria

- [ ] AC1 — Given the external-sources list, when I add or remove an entry, then the change is
  performed from the dashboard and persists to `.aid/knowledge/external-sources.md`.
- [ ] AC2 — Given an entry is added or removed, when the list re-renders, then it reflects the
  new on-disk registry with no drift.

## Open Questions

- **OQ-P4 — External-sources writer (new). RESOLVED (2026-07-17, /aid-specify): build a new
  co-vendored `write-external-source.sh`; frontmatter `sources:` is the machine source of truth;
  the `## Sources` body is kept truthful as a minimal managed bullet mirror.** `external-sources.md`
  has no dedicated add/remove path today (discovery/Q&A only), so a new non-interactive writer is
  built, parallel to `write-setting.sh` / `write-requirement.sh` (feature-001). **Decision:** the
  writer's authoritative target is the frontmatter `sources:` YAML list — it is (a) the machine-
  readable registry the KB frontmatter schema defines for this doc ("the one template where
  `sources:` are external URLs", `external-sources.md` template comment), (b) already lint-validated
  per entry by `lint-frontmatter.sh` `sources_entry_shape()` (line 270 — URL `^https?://` or a
  whitespace-free path/glob), and (c) **already parsed, with a byte-parity twin,** by the reader's
  `parse_doc_frontmatter()` (`parsers.py` line 513 / `reader.mjs` `parseDocFrontmatter` line 1073) —
  so the read side needs no new parser. The writer edits the `## Sources` **body** only as a minimal
  deterministic bullet mirror (swapping the "No external documentation was provided…" prose ⇄ a
  `- <entry>` list) so the human-facing doc never contradicts the frontmatter; it deliberately does
  **not** synthesize the rich `| Path | Type | Accessible | Key Content |` table (those columns need
  semantic knowledge the LLM-free server can't produce — that stays a discovery/Q&A concern). Full
  design in §API Contracts / §Layers & Components below.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature adds the External Sources
> list to a project's `home.html`: view the registry, add an entry, remove an entry. It is the sole
> P3 item because it needs **net-new writer plumbing** — `external-sources.md` has no add/remove path
> today. It **consumes** the write mechanism defined in feature-001 (foundation): it registers two
> op handlers on the foundation's `OP_TABLE`, honors the `write_enabled` / `--allow-writes` gate,
> uses the child-process writer dispatch (server stays LLM-free — SEC-4), keeps the reader twins in
> byte-parity, and re-renders truthfully from disk. It does **not** re-invent any of that.
>
> **Grounding anchors:** registry doc `.aid/knowledge/external-sources.md` (frontmatter `sources:`
> list + `## Sources` body); reader twins `dashboard/reader/parsers.py` (`parse_doc_frontmatter`
> line 513, `is_url_source` line 623 / regex `_RE_URL` line 510) + `dashboard/server/reader.mjs`
> (`parseDocFrontmatter` line 1073, `isUrlSource` line 1068 / regex `RE_URL_SOURCE` line 1066 —
> the URL predicate the client-side link render in §UI Specs mirrors); `RepoInfo` model
> `dashboard/reader/models.py` line 220; DM-1 serializers
> `dashboard/server/server.py` `_ser_repo_info` line 595 + `reader.mjs` `_buildRepoInfo` line 4327;
> home page markup + render `dashboard/home.html` (`#knowledge-tool-section` line 877, `renderMainPage`
> line 1318, `_renderKbCard` call line 1350, `./api/model` fetch line 1042); lint contract
> `canonical/aid/scripts/kb/lint-frontmatter.sh` `sources_entry_shape` line 270; writer siblings
> `.claude/aid/scripts/config/read-setting.sh` + feature-001's `write-setting.sh`/`write-requirement.sh`;
> feature-001 SPEC (§API Contracts `OP_TABLE`, status map, write gate, `dashboard/MANIFEST` co-vendor).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The store is the on-disk `external-sources.md`; the frontmatter `sources:` list is the machine-readable registry (a new additive `repo.external_sources` model field). |
| Feature Flow | Present | The add/remove → gate → dispatch → writer → re-fetch round-trip, built on feature-001's flow. |
| Layers & Components | Present | Reader (new model field, reusing an existing parser), writer (new script), server (2 new op rows), UI (new list card) all change. |
| API Contracts | Present | Two new `OP_TABLE` rows + the new `write-external-source.sh` writer contract. |
| Security Specs | Present | Value validation mirrors the lint `sources_entry_shape`; traversal/injection defenses; SEC-3/4 + the write gate reused from feature-001. |
| Migration / New Plumbing | Present | Additive `external_sources` envelope key (no `schema_version` bump); one net-new co-vendored writer script (`dashboard/MANIFEST` one-line edit). |
| UI Specs | Present | A new external-sources list card on `home.html`, gated on `write_enabled`, with add/remove controls + truthful re-render. |
| State Machines | N/A | No lifecycle/enum. An entry is present or absent; there is no state transition. |
| Telemetry & Tracking | N/A | Single-user trust model (REQUIREMENTS §3); the writer prints `OK:`/stderr, sufficient — same posture as feature-001. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations (runtime), Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback single-file registry edit. (The entries *catalogued* are external docs, but this feature manages a local markdown registry — no runtime external call.) |

### Data Model

**No database.** The store is the on-disk registry `<repo>/.aid/knowledge/external-sources.md`. Two
regions matter:

| Region | Role | Written by this feature | Read by this feature |
|--------|------|-------------------------|----------------------|
| Frontmatter `sources:` YAML list | **Machine-readable registry** (authoritative). Per the `external-sources.md` template, this is the one KB doc where `sources:` holds external URLs/paths, not repo-relative cites. | YES (add/remove entry) | YES → `repo.external_sources` |
| `## Sources` body (prose or table) | **Human-facing** narrative/table. | YES (minimal managed bullet mirror only — see §API Contracts) | NO (never machine-parsed) |

**New model field (additive):** `RepoInfo.external_sources: list[str]` (`models.py`, add beside
`kb_state`, line 225). It is the deduped, order-preserved list of `sources:` entries with the
discovery placeholder `(none)` filtered out. Absent/empty registry ⇒ `[]`. It is surfaced on the
DM-1 envelope under `model.repo.external_sources` (the same object that already carries `kb_state`,
consumed by `home.html`). No other model field changes; the DM-2 `/api/home` model is untouched
(the list lives on the per-project page only, per REQUIREMENTS §5.1).

**Entry shape.** An entry is a single string — a URL (`^https?://…`) or a whitespace-free path/glob
— exactly what `lint-frontmatter.sh sources_entry_shape()` (line 270) accepts, so a dashboard-added
entry keeps `lint-frontmatter.sh` green. No label/type/note is captured in the registry (a label
would contain spaces and fail the lint shape); richer per-source metadata (Type, Accessible, Key
Content) stays an agent/discovery concern (see OQ-P4 resolution).

**No DERIVED section is written (C2); no STATE.md is touched (C1 untouched — this feature writes
neither `STATE.md` nor via `writeback-state.sh`).** The registry is an AUTHORED KB content file.

### Feature Flow

```
home.html (project page)                          Dashboard server (server.py | server.mjs)
────────────────────────                          ──────────────────────────────────────────
external-sources card rendered from
  model.repo.external_sources
  (controls shown only when model.write_enabled === true — feature-001 gate)
  │
  ├─ user types a URL/path, clicks "Add"
  │     POST /r/<id>/api/op {op:"external-source.add",  target:{}, args:{value}}
  └─ user clicks "Remove" on an entry
        POST /r/<id>/api/op {op:"external-source.remove", target:{}, args:{value}}
        │
        ▼   (feature-001 pipeline, unchanged)
   _serve_op:  Host allowlist (SEC-6) → write gate (write_enabled?) → JSON parse
               → op ∈ OP_TABLE → resolve <id> → repo path (id_map; SEC-2)
               → validate args (value shape) → build argv ARRAY for write-external-source.sh
               → spawn child (SEC-3 no in-proc write; SEC-4 shell script, not an agent)
               → map exit code → HTTP status
        ◀── 200 {ok:true} ── or ── 4xx/5xx {ok:false,error,detail} ──┘
  │ on ok
  ▼ targeted re-fetch  GET /r/<id>/api/model  → re-render list off disk (NFR3 / AC2)
```

These are **per-repo, work-id-less** operations (like feature-001's `settings.set`): they target
`<repo>/.aid/knowledge/external-sources.md`, resolved server-side from `<id>` alone (never from the
body). The request carries a **present-but-empty `target: {}`** (project-scoped — per feature-001's
rule that `target.work_id` "is omitted for project-scoped ops", the object is present but the
pipeline-scoped `work_id` is left out entirely, never sent as `null`); this is the same wire shape
as sibling feature-002's `settings.set` and feature-007's `connector.*` ops. The `OP_TABLE` schema
declares the op does not consume `work_id`.

### Layers & Components

**1. Reader / model layer** (`dashboard/reader/parsers.py` + `dashboard/server/reader.mjs` twins) —
**no new parser; reuse the existing one.** The `sources:` frontmatter list is already parsed, with a
byte-parity twin, by `parse_doc_frontmatter()` (`parsers.py` line 513, inline + block list forms) /
`parseDocFrontmatter()` (`reader.mjs` line 1073), whose cross-runtime byte-parity is exercised by
`test_task044_freshness_parity.py` (it invokes `node --input-type=module` against `reader.mjs` and
byte-compares the frontmatter-`sources:`-derived output to the Python reader). This feature adds a
thin wrapper:

- `parse_external_sources(kb_dir)` (Python) / `parseExternalSources(kbDir)` (Node): call
  `parse_doc_frontmatter(kb_dir / "external-sources.md")`, take its `sources_list`, drop the
  `(none)` placeholder, dedupe preserving order, return the list. Absent file ⇒ `[]` (the parser
  already returns `[]` for a missing/frontmatter-less file — NFR-never-raises).
- Wire it where `RepoInfo` is built: `reader.py` (beside the `parse_kb_state(loc.kb_dir)` call,
  ~line 402) and `reader.mjs` (beside `parseKbState(loc.kbDir)`, ~line 2619), setting
  `RepoInfo.external_sources`.

  **Reader-parity constraint (verified against the existing parser).** `parse_doc_frontmatter`'s
  block-list continuation matches only contiguous `^[ \t]+-[ \t]*` item lines; a comment or blank
  line between `sources:` and its items **ends the block**. The live `external-sources.md` has a
  `# EXTERNAL …` comment line between `sources:` and `- (none)`, so today it parses to `[]` (benign —
  the placeholder isn't a real source). The **writer therefore normalizes the block to contiguous
  `  - <item>` lines directly under the `sources:` key** (see §API Contracts) so every
  dashboard-managed entry is reader-visible (required for AC2). The writer also emits **clean item
  lines with no inline `# comment`** (the parser does not strip trailing inline comments from a block
  item, so an inline comment would pollute the parsed value).

**2. Writer layer** — **new** `write-external-source.sh`, a scriptable sibling of feature-001's
`write-setting.sh` / `write-requirement.sh` (and of `read-setting.sh`). Bash-only (the dashboard
already requires bash). Co-vendored with the dashboard unit and self-located from `$AID_CODE_HOME`
exactly as feature-001 co-vendors its writers — added by a **one-line edit of `dashboard/MANIFEST`**
(from which `vendor.js`/`vendor.py`/`install.sh`/`install.ps1`/`release.sh` all derive, guarded by
`tests/canonical/test-dashboard-manifest.sh`). Contract in §API Contracts.

**3. Server layer** (`dashboard/server/server.py` + `server.mjs` twins) — **two new `OP_TABLE`
rows only.** feature-001 owns the POST `/r/<id>/api/op` route, the write gate, the argv-array child
dispatch, and the exit-code→HTTP map. This feature appends `external-source.add` /
`external-source.remove` (concretizing the `external-sources` placeholder feature-001 reserved for
"010"). No new route, no new gate, no in-process fs write (SEC-3), no agent import (SEC-4).

**4. UI layer** (`dashboard/home.html`) — a new external-sources list card in the main page,
rendered from `model.repo.external_sources`, controls gated on `model.write_enabled`. See §UI Specs.

### API Contracts

**`OP_TABLE` rows appended by feature-010** (per-repo scope; both twins, byte-parity):

| `op` | Scope | Writer + argv | Owning FR | Introduced by |
|------|-------|---------------|-----------|---------------|
| `external-source.add` | per-repo (no `work_id`) | `write-external-source.sh --op add --value <v> --file <repo>/.aid/knowledge/external-sources.md` | FR-P4 | feature-010 |
| `external-source.remove` | per-repo (no `work_id`) | `write-external-source.sh --op remove --value <v> --file <repo>/.aid/knowledge/external-sources.md` | FR-P4 | feature-010 |

- **Request** (feature-001 envelope): `{ "op": "external-source.add", "target": {}, "args": { "value": "<url|path>" } }`.
  `target` is **present but empty (`target: {}`)** — project-scoped ops omit the pipeline-scoped
  `work_id` entirely rather than sending it as `null` (feature-001's rule: `target.work_id` "is
  omitted for project-scoped ops"), consuming sibling feature-002's `settings.set` and feature-007's
  `connector.*` envelope shape verbatim. The op's schema declares it consumes no work. The
  `--file` path is built server-side from `<id>`→repo (SEC-2, verbatim from `id_map`) — **never from
  the body** (traversal-proof).
- **Server-side arg validation** (before any spawn; feature-001's per-op schema step): `args.value`
  required, length 1–2048, and must match the **same alphabet the KB lint accepts** — a URL
  (`^https?://\S+$`) or a whitespace-free path/glob (`^\S+$`) — and must contain no newline and no
  `|`. Fail ⇒ 422 `invalid-value` (before spawn). The writer re-validates (defense in depth).
- **Success:** `{ "ok": true, "op": "<op>" }`; client re-fetches `GET /r/<id>/api/model` and
  re-renders (AC2). **Failure:** the feature-001 status map applies unchanged (403 gate/host, 400
  bad-request, 404 not-found, 422 invalid-value, 409 busy, 500 write-failed).

**`write-external-source.sh` contract** (new):

```
write-external-source.sh --op <add|remove> --value <url|path> [--file <external-sources.md>]
```

- `--op`: `add` | `remove`; any other ⇒ exit 4.
- `--value`: the source URL/path. Validated to the lint alphabet: URL (`^https?://`) OR whitespace-
  free path/glob (`^[^[:space:]]+$`) — mirrors `lint-frontmatter.sh sources_entry_shape()` (line 270)
  so an added entry keeps the KB linter green. Rejects any whitespace, newline, or `|` ⇒ exit 4.
- `--file`: target registry; default `.aid/knowledge/external-sources.md`.
- **`add`** — idempotent: if `--value` already in the `sources:` list ⇒ exit 0 (no-op). Else insert
  a `  - <value>` item **immediately under the `sources:` key line** (contiguous block form the
  reader consumes); if the block held only the discovery placeholder `- (none)`, drop it. Also add a
  `- <value>` bullet to the `## Sources` body list (see body handling below).
- **`remove`** — remove the matching `  - <value>` frontmatter item; if that empties the real list,
  write the lint-clean empty form `sources: []`; remove the matching `## Sources` body bullet; if the
  body list empties, restore the canonical "No external documentation was provided…" paragraph. If
  `--value` is not present ⇒ exit 1 (→ 404 `not-found`, surfacing drift; the UI offers Remove only
  for listed entries, so this is an edge/racing case).
- **Body (`## Sources`) handling — minimal managed mirror.** The writer maintains, under the
  `## Sources` heading, a simple `- <entry>` bullet list bounded by a stable HTML-comment marker
  pair (e.g. `<!-- managed:external-sources -->` … `<!-- /managed:external-sources -->`). On the
  first add it replaces the "No external documentation…" paragraph with the marked list; on removing
  the last entry it restores that paragraph. It never writes the rich `| Path | Type | Accessible |
  Key Content |` table (semantic columns the LLM-free server can't fill — OQ-P4). If a hand-authored
  table already exists, the managed bullet block is inserted/updated adjacent to it without rewriting
  the human rows (the body is never machine-read, so this is cosmetic-truthfulness only).
- **Atomicity & preservation:** surgical edit via temp file + `mv` (as `writeback-state.sh`'s
  `wb_set_frontmatter` and feature-001's writers do); every non-target line byte-preserved; the
  frontmatter block boundary is the leading `---`…`---`.
- **Exit codes** (the **feature-001 canonical status map** — the `writeback-state.sh` exit alphabet
  feature-001 §API Contracts codifies as the OP_TABLE exit→HTTP contract; **not** `write-setting.sh` /
  `read-setting.sh`, whose own local contract assigns exit `2` to arg/IO rather than lock contention):
  `0` ok; `1` remove-target-absent (→404); `2` lock contention (→409 `busy`, exactly as feature-001's
  canonical map assigns exit 2); `3` IO/write error (→500 `write-failed`); `4` invalid value (→422).
  No lock is required for correctness (single-file, single-user), but the writer MAY reuse the
  `writeback-state.sh` sentinel pattern for uniformity; if it does, sentinel contention ⇒ exit 2
  (→409), matching every other feature-001 writer.

### Security Specs

The write path is feature-001's; this feature adds no network surface and no new enforcement point.

- **Write gate reused (AC8 / NFR2 / C3).** Both ops flow through feature-001's `write_enabled`
  gate: loopback ⇒ writable; `--remote` ⇒ 403 `read-only` unless `--allow-writes`. The UI also hides
  the add/remove controls when `model.write_enabled !== true` (defense-in-depth + UX).
- **Injection / traversal.** argv array only (no shell string); `op` from the closed `OP_TABLE`;
  the registry path is built server-side from `<id>` (never from the body); `value` is validated to
  the URL-or-whitespace-free-path shape and rejects whitespace / newline / `|` before spawn, and the
  writer re-validates. Because a valid entry is whitespace-free, a YAML inline-comment injection
  (` #…`) or a markdown-table-cell break (`|`) into either region is impossible.
- **SEC-3 preserved** — the server performs no in-process filesystem mutation; it dispatches the new
  writer as a child process with an argv array. The server-file audit (`open(...,'w')` /
  `writeFileSync` / `appendFile` / `unlink`) stays empty.
- **SEC-4 preserved** — the dispatched child is a plain bash writer, never an agent/LLM. This is why
  Add is a **native writer form** (a single validated URL/path), not the interactive elicitation that
  gates FR-P5's connector Add (Q2): a URL/path needs no LLM, so no SEC-4 tension arises here.
- **KB-lint integrity** — the entry alphabet is deliberately identical to
  `lint-frontmatter.sh sources_entry_shape()`, so dashboard writes never produce a `sources:` entry
  that CI's `lint-frontmatter.sh` would flag `[FM-INVALID]`.

### Migration / New Plumbing

- **Additive envelope key `repo.external_sources`** (DM-1). Back-compat: an older UI ignores it; the
  new UI treats missing/absent ⇒ `[]`. Following the DM-A3 (task-064) / RC-2 no-bump precedents used
  by feature-001 for `write_enabled`, **do not bump** `schema_version` — the field is purely
  additive and defaults empty. Twin golden fixtures (`test_server_py.py` / `test_server_node.mjs`
  DM-1 fixtures) are regenerated in lockstep to keep DM-3 byte-parity.
- **One net-new co-vendored writer** — `write-external-source.sh` added to the dashboard unit by a
  **one-line `dashboard/MANIFEST` edit** (same single-source mechanism feature-001 uses for its
  writers; `test-dashboard-manifest.sh` guards drift).
- **No data migration** — existing `external-sources.md` files are edited in place; no format change
  to any other artifact; `writeback-state.sh` untouched (C1). The empty/initial state (the `- (none)`
  placeholder, or no `sources:` key) is handled by the writer's add path and by the reader's `[]`
  default.
- **KB follow-up (REAL — must be reconciled with a human before build; flagged, not fixed here).**
  This feature makes the dashboard a **second writer** of `external-sources.md`'s frontmatter
  `sources:`, which directly contradicts a documented discovery invariant: `aid-discover`'s
  `state-elicit.md` states "Scout remains its single writer" (STATE.md Q7 item 4;
  `canonical/skills/aid-discover/references/state-elicit.md` line 119), and on an ELICIT E1 reset
  (when the declared `## External Documentation` path set changes) "Scout fully rewrites the doc
  (including frontmatter) on its next pass regardless" (same file, line 115). That is a genuine
  **silent-data-loss path**: a dashboard-added source survives the immediate re-fetch (AC1/AC2 hold
  *within* the dashboard round-trip), but a later discovery GENERATE pass can wholesale-overwrite
  the frontmatter and drop it — so **AC1's persistence guarantee does not extend across a subsequent
  Scout run.** This is not resolvable by writer plumbing alone; it needs a human decision on the
  ownership model, e.g. (a) make Scout's rewrite merge/preserve dashboard-managed `sources:` rather
  than replace, (b) mark dashboard-added entries so Scout retains them, or (c) accept the loss and
  redocument `external-sources.md` as discovery-owned with dashboard edits declared explicitly
  transient. The "single writer" language in `state-elicit.md` (and STATE.md Q7 item 4) must be
  reconciled with this feature's shared-ownership reality. `/aid-specify` edits no KB text — this is
  a flag for the human, not a change. **Registered via the work's established coordination channels
  for /aid-plan to consume:** work `known-issues.md` **KI-005** (sequencing hazard) and work
  `STATE.md` Cross-phase Q&A **Q5** (Pending, Impact: High) — feature-010 must not reach EXECUTE
  until this ownership decision is made.

### UI Specs

Grounded in the existing `home.html` main-page pattern (the KB card).

- **Placement.** Add a sibling container to the Knowledge Base band. Today the main page has
  `<div id="knowledge-tool-section">` (line 877) rendered by `_renderKbCard(model.repo.kb_state)`
  (`renderMainPage`, line 1350). Add a new `<h2 class="main-section-head">External Sources</h2>` +
  `<div id="external-sources-section">` immediately after the KB band (before the Pipelines section,
  line 879), and in `renderMainPage` call a new `_renderExternalSourcesCard(model.repo,
  model.write_enabled)`. This keeps both `.aid/knowledge/`-derived views together and touches only
  additive markup + one render call.
- **Read view (always).** The card lists each `model.repo.external_sources` entry (URL rendered as
  a link, else plain text). **Client-side URL detection (specified).** `external_sources` is a
  `list[str]` with **no** serialized per-entry `is_url` flag (the Data Model stays minimal), so
  `home.html` decides link-vs-text itself with a **browser-side regex twin** of the reader predicate:
  `/^[a-z][a-z0-9+.\-]*:\/\//` — byte-identical to Python `_RE_URL` (`parsers.py` line 510, backing
  `is_url_source` line 623) and Node `RE_URL_SOURCE` (`reader.mjs` line 1066, backing `isUrlSource`
  line 1068). A match ⇒ an `<a href>` (with `rel="noopener noreferrer"`); otherwise plain text. This
  is a pure display choice on an already-validated value (no security surface — the value alphabet is
  enforced server-side + in the writer), so no new serialized field is warranted. Empty ⇒ an
  empty-state line ("No external sources registered."). This view renders regardless of
  `write_enabled`, so `--remote` read-only users still see the registry.
- **Write controls (only when `model.write_enabled === true`).** Per entry, a **Remove** button;
  below the list, an **Add** row = one text input (placeholder "https://… or path/to/doc") + an
  **Add** button. When `write_enabled !== true`, no controls render (feature-001 gate contract).
- **Actions.** Add → `POST /r/<id>/api/op {op:"external-source.add", target:{}, args:{value:<input>}}`; Remove →
  `{op:"external-source.remove", target:{}, args:{value:<entry>}}`, issued as a direct same-origin
  `fetch` to `POST /r/<id>/api/op` — the same client call sibling feature-002 introduces for
  `settings.set` and feature-007 for `connector.*` (no shared op-helper abstraction exists yet; CSP
  `connect-src 'self'` already permits the call). On `ok`, re-fetch `./api/model` (the existing
  `fetchUrl`, line 1042) and re-render — the drift
  window is one immediate round-trip (AC2). On failure, surface the `error`/`detail` inline (e.g.
  422 invalid-value → "Enter a URL or a path with no spaces"; 404 → the entry was already gone;
  re-render from the fresh model regardless).
- **Client-side validation** mirrors the server: trim the input, block empty and any-whitespace
  values before POST (fast feedback), but the server + writer remain the authority.

### How the Acceptance Criteria are satisfied

- **AC1 (add/remove persists to `external-sources.md`).** The Add/Remove controls POST an op that
  feature-001's dispatcher routes to `write-external-source.sh`, which surgically mutates the
  `sources:` frontmatter list (authoritative) and the `## Sources` body mirror in
  `<repo>/.aid/knowledge/external-sources.md` via temp-file + `mv`. The change is made entirely from
  the dashboard and lands on disk in that one file. **Scope caveat:** this satisfies AC1 for the
  dashboard round-trip; durability *across a later discovery GENERATE pass* is a shared-ownership
  concern flagged for the human in §Migration / New Plumbing (Scout may wholesale-rewrite the
  frontmatter), not a guarantee this feature can make alone.
- **AC2 (re-render reflects on-disk registry, no drift).** On op success the client immediately
  re-fetches `GET /r/<id>/api/model`; the reader re-parses `external-sources.md`'s `sources:` list
  (via the existing `parse_doc_frontmatter` twin) into `model.repo.external_sources`, and the card
  re-renders from that post-write model — so the list is always a truthful projection of disk, with
  the drift window collapsed to a single round-trip. The writer's contiguous-block normalization
  guarantees every managed entry is reader-visible.
