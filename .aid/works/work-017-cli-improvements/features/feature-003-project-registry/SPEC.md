# Add / Remove Project (Home Registry)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.1 (FR-P1, FR-P2) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): home OP_TABLE rows `project.add`/`project.remove` on `POST /api/op` via child `aid projects add/remove`, index.html Add/Remove UI gated on `write_enabled`, truthful `/api/home` re-fetch. OQ-P1 resolved (typed-path input; File System Access API + server-side dialog both rejected). OQ-P2 resolved (dashboard uses `aid projects` exclusively; reconcile stale `aid remove --target` guidance in index.html). KI + OP_TABLE `status_map` integration note registered. | /aid-specify |

## Source

- REQUIREMENTS.md §5.1 FR-P1 (Add Project), FR-P2 (Remove Project)

## Description

On the main all-projects grid (`index.html`, `#repo-grid`), add controls to manage which
projects the dashboard tracks. Add Project registers an existing folder for tracking via
`aid projects add [<path>]` (path defaults to cwd); it does NOT scaffold `.aid/` or install
tools — the folder is expected to already be an AID project. Remove Project unregisters a
tracked project via `aid projects remove [<path>|<N>]`; it is untrack-only ("no files
removed"). The dashboard uses the unambiguous `<path>` form per card.

This is distinct from Delete Pipeline (feature-009): Remove Project only unregisters a whole
project and leaves all files in place; Delete Pipeline destroys one pipeline's work folder +
worktree. Depends on the write-infrastructure foundation (feature-001) for the operation
endpoints.

## User Stories

- As a developer running AID on my own project, I want to add and remove projects from the
  dashboard's Home grid, so that I can control which of my AID projects appear without
  editing the registry by hand.

## Priority

Must

## Acceptance Criteria

- [ ] AC1 — Given the Home grid, when I add or remove a project, then the `aid projects`
  command runs from the dashboard and the change persists to disk.
- [ ] AC2 — Given a project is added or removed, when the grid re-renders, then it reflects
  the new registry state with no drift.

## Open Questions

- **OQ-P1 — Folder dialog from a browser. RESOLVED (2026-07-17, /aid-specify): typed-path
  input.** A loopback web page cannot obtain a real OS filesystem path from a native folder
  picker. **File System Access API rejected:** `showDirectoryPicker()` returns a
  `FileSystemDirectoryHandle` that deliberately exposes only the leaf `name`, never the
  absolute path the CLI needs (`aid projects add <path>` canonicalises with `cd && pwd`,
  `bin/aid` line ~2598). **Server-side native dialog rejected:** it would open on the *server's*
  display (nonsensical headless / under `--remote` in a container/VM — the reason `--remote`
  exists) and adds per-OS GUI plumbing (zenity/osascript/PowerShell). **Decision:** a typed
  absolute-path text input; the `aid projects add` CLI is the validation authority (rejects a
  non-existent path or a non-AID folder with a clear `ERROR:` line the UI surfaces). Remove needs
  no picker — each card already carries its path (server resolves it from `id_map`). See
  §UI Specs / §API Contracts.
- **OQ-P2 — CLI reconciliation. RESOLVED (2026-07-17, /aid-specify): dashboard uses
  `aid projects` exclusively.** The write path invokes only the confirmed work-018 shape
  (`aid projects add [<path>]`, `aid projects remove [<path>|<N>]`); the dashboard uses the
  `<path>` form for both (Add = typed path; Remove = the card's `id_map`-resolved path — never
  the volatile `<N>` index). Within this feature's own surface, the **only** stale command text in
  `index.html` is the unavailable-card prune guidance `aid remove --target <path>` (line ~936) — a
  *tool-uninstall* command (removes tools; unregisters only when the last tool goes, `bin/aid`
  L3457/L3468), wrong for an untrack-only need — reconciled to the untrack-only `aid projects
  remove <path>`. The empty-registry hint `aid add <tool>` (line 533) is **deliberately left
  unchanged**: it is the brand-new-user *bootstrap* command that scaffolds `.aid/` **and**
  auto-registers (`registry_register`, `bin/aid` L3430). `aid projects add` cannot replace it — it
  requires a pre-existing `.aid/` (`_aid_is_project_dir`, L2604) and only *registers*, so aiming a
  brand-new user (empty registry, no `.aid/`) at it would break bootstrap. The two are
  complementary: the new Add-Project UI control registers an already-AID folder; the static hint
  scaffolds a not-yet-AID folder. Consistent with this, the CLI's own not-an-AID-project error
  (L2605), surfaced verbatim in UI-P1, correctly directs the user to `aid add <tool>` — that
  citation is intended, not a leftover. The broader naming of the tool-lifecycle `aid remove
  --target` command is a separate CLI-cleanup theme, out of scope here (see RETURN known-issue).

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature is a **consumer of the
> feature-001 write foundation** — it re-uses, and does not re-invent, that feature's write
> mechanism: the `POST /api/op` home route + `_serve_home_op` gate/dispatch skeleton, the
> `--allow-writes` / `write_enabled` gate (AC8), the argv-array child-process discipline (SEC-3),
> the LLM-free-server posture (SEC-4), the response envelope, the reader-twin byte-parity rule, and
> the truthful re-render contract (NFR3). feature-003 adds only: the two **home OP_TABLE rows**
> (`project.add`, `project.remove`), completes `_serve_home_op`'s dispatch for them, and the
> **index.html** Add/Remove UI controls.
>
> **Grounding anchors (verified on disk):** `dashboard/index.html` (`#repo-grid` L528,
> `#repo-section` L526, `#empty-registry` L532, `renderRepoGrid` L770, `_renderRepoCard` L815,
> `_renderUnavailableCard` L902 incl. `aid remove --target` guidance L936, `doFetch` L590,
> `renderMachinePanel` L700, `escHtml` L689, boot/Refresh L577); server twins
> `dashboard/server/server.py` (`do_POST` 405 L906, `build_home_model` L428 machine block
> L512–529, `serialize_home` L841, `_get_id_map` L230, `_R` id regex `[0-9a-f]{8,}` L274,
> `_CSP_HEADER` `form-action 'none'`/`connect-src 'self'` L290, `$AID_CODE_HOME` self-location via
> `_DASHBOARD_DIR.parent` L401/L417) + `dashboard/server/server.mjs` (non-GET 405 L682,
> `buildHomeModel` L457, `serializeHome` L585, `getIdMap` L232, `serveApiHome` L744); CLI
> `bin/aid` (`_cmd_projects` L2458, `_cmd_projects_add` L2592, `_cmd_projects_remove` L2636,
> usage L188, `AID_CODE_HOME` self-locate L45–52, `_dc_start` spawn `AID_HOME=$AID_STATE_HOME` L1216,
> `_aid_resolve_tier` L1490 incl. shared-tier rule L1520–1523, `registry_register` L1619 incl.
> fail-open WARN+`return 0` L1662–1666, `registry_unregister` L1763, `_aid_priv_run` L367 incl.
> `return 13` when sudo absent L382–383, verbose-gated benign fallback WARN L1714–1715);
> server-side union re-read `_load_union_repos` (`server.py` L160 / `loadUnionRepos` `server.mjs`
> L180); CAN-1/DD-5 verbatim stored paths, no `realpathSync` (`server.mjs` L108/L264);
> foundation `features/feature-001-write-infrastructure/SPEC.md` (OP_TABLE, `/api/op`, write gate).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The "store" is the two-tier `registry.yml` union the server already reads; no new schema. |
| Feature Flow | Present | The click → `POST /api/op` → gate → argv → `aid projects` child → exit-map → `/api/home` re-fetch round-trip is the feature. |
| Layers & Components | Present | UI (index.html controls), server home-op handler + OP_TABLE rows, and the `aid` CLI writer. |
| API Contracts | Present | Two new OP_TABLE rows (`project.add`, `project.remove`): target/args schema, argv-builders, child env, exit→HTTP map. |
| Security Specs | Present | SEC-4 (child is the `aid` CLI, never an LLM), argv-array no-shell, add-path validation, remove path-from-`id_map` (not body), write-gate + Host-header + `--remote` reuse. |
| UI Specs | Present | Required — Add Project + per-card Remove on `#repo-grid`, `write_enabled` gating, re-render. |
| Migration / New Plumbing | Present (small) | No new writer script (re-uses `aid`). One integration note: OP_TABLE needs a per-op `status_map` (the `aid`-CLI exit alphabet differs from `writeback-state.sh`'s). |
| State Machines | N/A | No lifecycle enum touched — the registry is a flat path set; add/remove are idempotent set ops. |
| Telemetry & Tracking | N/A | Single-user trust model; the CLI prints `aid projects: …` lines and the server logs failures to stderr — sufficient. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback registry add/remove wired to an existing CLI. |

### Data Model

**No database, no new schema.** The registry store is the two files the home server already
reads as a union: `$AID_STATE_HOME/registry.yml` (primary) and `$HOME/.aid/registry.yml` (user
fallback), collapsed when equal (`_load_union_repos` / `_get_id_map`, `server.py` L230–266; twin
`getIdMap`, `server.mjs` L232). Each file holds a flat `projects:` list of base-folder paths
(`bin/aid` registry writers, e.g. the header at L1648/L1651). The server derives an **`id → path`**
map from that union; `index.html` renders one card per entry with both `repo.id` (an 8+ hex id,
matched by `_R` at `server.py` L274) and `repo.path`.

| Target | Field(s) written | Owning writer | Read back by |
|--------|------------------|---------------|--------------|
| `registry.yml` (tier chosen by `_aid_resolve_tier`) | one `projects:` path entry added | `aid projects add <path>` (existing CLI, `bin/aid` L2592) | `/api/home` two-tier union |
| `registry.yml` (whichever tier holds it) | one `projects:` path entry removed | `aid projects remove <path>` (existing CLI, `bin/aid` L2636) | `/api/home` two-tier union |

**No `.aid/` files are created, scaffolded, or deleted** by either op — Add *registers* an
already-existing AID folder (the CLI rejects a non-AID folder, L2604) and Remove is
**untrack-only** ("no files removed", usage L199). This is categorically distinct from feature-009
Delete Pipeline (which destroys a work folder + worktree). No DERIVED view is a target (C2 holds
trivially — the registry is not a STATE.md view); C1 is unaffected (no STATE.md write).

**Truthful re-render mechanism (AC2), grounded:** the server caches the `id_map` keyed on the
`(mtime_ns, size)` of *both* registry tiers (`_get_id_map` L248–254). `aid projects add/remove`
rewrites a `registry.yml`, changing its stat, so the next `/api/home` busts the cache and rebuilds
the union — the grid cannot drift from disk. **This holds only when the write actually lands:** when
a shared-tier write fails open (no elevation available), the stat is unchanged and the path never
enters the union — the exit-0 fail-open guard (§API Contracts) converts that silent no-op into a
surfaced 500, so it cannot masquerade as a successful add / a phantom card.

### Feature Flow

```
Browser (index.html #repo-grid)                    Home server (server.py | server.mjs)
────────────────────────────────                    ───────────────────────────────────
[controls render only when envelope.machine.write_enabled === true]

ADD:  user clicks "Add project", types an absolute path, submits
  │   fetch POST /api/op  {op:"project.add", args:{path:"<typed>"}}
REMOVE: user clicks a card's "Remove", confirms (lightweight — untrack, not delete)
  │   fetch POST /api/op  {op:"project.remove", target:{id:"<repo.id>"}}
  ▼
POST /api/op            ── HTTP ──▶  handler(method==POST) → _serve_home_op  (feature-001 skeleton)
                                    │ 1. SEC-6 Host-header allowlist                → 403 bad-host
                                    │ 2. write gate: write_enabled?                 → 403 read-only
                                    │ 3. parse JSON (≤64 KiB); op ∈ OP_TABLE?        → 400 bad-request
                                    │ 4. per-op arg/target validation (this spec):
                                    │      add    → args.path: non-empty, absolute, ≤4096, no NUL/newline/ctrl
                                    │      remove → target.id ∈ id_map (verbatim, SEC-2) → 404 not-found
                                    │ 5. build argv ARRAY (no shell):
                                    │      add    → bash <$AID_CODE_HOME/bin/aid> projects add    <path>
                                    │      remove → bash <$AID_CODE_HOME/bin/aid> projects remove <resolved-path>
                                    │      child env: AID_HOME=<server aid_home>   (same registry the server reads)
                                    │ 6. spawn child; CAPTURE stderr on EVERY exit (SEC-3 no in-process
                                    │      fs-write; SEC-4 child = aid CLI, not LLM)
                                    │ 7. map aid-CLI exit → HTTP (§API Contracts status_map)
                                    │ 8. fail-open guard: exit 0 + `WARN: aid:` on stderr (or, for
                                    │      remove, id_map path STILL in the re-loaded union)
                                    │      ⇒ 500 write-unverified — NOT a phantom 200
  ◀── 200 {ok:true, op} ── or ── 4xx/5xx {ok:false, error, detail:<stderr≤1 KiB>} ──┘
  │
  ▼ on verified ok
  doFetch()  →  GET /api/home  →  truthful re-render of #repo-grid from disk (NFR3/AC2)
```

### Layers & Components

**1. UI layer — `dashboard/index.html`** (the only file with net-new UI in this feature):

- **`write_enabled` read.** `onSuccess(envelope)` already calls `renderMachinePanel(envelope.machine)`
  and `renderRepoGrid(envelope.repos)` (L632–633). feature-001 adds `write_enabled` to the DM-2
  `machine` block (after `cli_runtime`, `server.py` L520 / `server.mjs` L538). index.html reads
  `envelope.machine.write_enabled` once per load and threads it into the render (see §UI Specs).
  **Missing ⇒ false** (fail-safe, matching feature-001's UI contract).
- **Add Project control** — a button in the `#repo-section` head (and mirrored in the
  `#empty-registry` state so the first project can be added) that reveals an inline typed-path
  form; on submit it `fetch`-POSTs `project.add` then calls the existing `doFetch()` (L590) to
  re-render. Rendered only when `write_enabled`.
- **Remove Project control** — a per-card button added in `_renderRepoCard` (L815, available cards)
  and `_renderUnavailableCard` (L902, stale cards); posts `project.remove` with the card's
  `repo.id`, then `doFetch()`. Rendered only when `write_enabled`. When read-only, the existing
  static prune guidance stays (its command text reconciled per OQ-P2).
- No new external assets; the form uses `fetch` (not a native `<form>` submit) so the CSP
  `form-action 'none'` + `connect-src 'self'` (`_CSP_HEADER` L290) is satisfied unchanged. All
  dynamic text is inserted via `textContent` / `escHtml` (L689) — no `innerHTML` with the
  user-typed path or the writer's stderr.

**2. Server home-op layer — `dashboard/server/server.py` + `server.mjs` (byte-parity twins):**

- feature-001 owns the POST router, `_serve_home_op` gate/dispatch skeleton, the write gate, the
  JSON-body parse/size guard, the argv-array spawn, and the response envelope. **feature-003
  completes `_serve_home_op` for the two registry ops and registers their OP_TABLE rows.**
- **Home scope has no `work_id`.** Unlike the per-repo `_serve_op`, `_serve_home_op` does not
  resolve `target.work_id` (feature-001 Feature Flow: "the same envelope minus `target.work_id`
  resolution"). `project.add` carries no `target`; `project.remove` carries `target.id`, which the
  server resolves to a path **from `id_map`** (verbatim, SEC-2) — never from the body.
- **Locating the writer.** The `aid` CLI is a shipped code asset at `$AID_CODE_HOME/bin/aid`,
  self-located as `_DASHBOARD_DIR.parent / "bin" / "aid"` — the identical self-location the server
  already uses for `VERSION` (`server.py` L401) and `lib/tools-catalog.txt` (L417). It is invoked
  as `bash <that path> projects …` so it runs on any host with bash (the dashboard already requires
  bash for the feature-001 writers). No co-vendoring is needed — `bin/aid` is already in the CLI
  package (unlike the profile-tree scripts feature-001 co-vendors).
- **Child environment.** The handler sets `AID_HOME=<self.server.aid_home>` (the value the server
  booted with — `server.py` L1145/L1151, set by `_dc_start` as `AID_HOME=$AID_STATE_HOME`,
  `bin/aid` L1216) so the child `aid projects` process resolves the **same** registry union the
  server enumerates. Without this the add could land in a different tier than `/api/home` reads,
  breaking AC2. Tier selection is left to the CLI's `_aid_resolve_tier`; the dashboard passes no
  `--local`/`--shared`.
- **Post-dispatch verification (fail-open guard) — the one net-new handler behaviour beyond the
  feature-001 skeleton.** Because `aid projects add/remove` are *fail-open* (they `return 0` with
  only a stderr `WARN` when a shared-tier write needs unavailable elevation — §API Contracts), the
  handler does **not** treat exit 0 as proof of persistence: it captures the child stderr on every
  exit and, on a 0 exit, maps a `WARN: aid:` line (and, for remove, an `id_map` path still present
  in the re-loaded union) to a **500 `write-unverified`**. This is what makes AC1/AC2 truthful under
  a global, headless install (the case where the CLI silently no-ops).

**3. Writer layer — `bin/aid` (`aid projects add` / `aid projects remove`), existing, unchanged:**

- `aid projects add <path>` (`_cmd_projects_add` L2592): canonicalises `<path>` (`cd && pwd`,
  L2598 — exit 2 if it does not exist), **requires an AID project** (`_aid_is_project_dir`, L2604 —
  exit 2 otherwise), then `registry_register` (idempotent). Non-interactive — no prompt. **Fail-open
  caveat:** `registry_register` is fail-open — a shared-tier write needing unavailable elevation
  WARNs to stderr and returns 0 *without writing* (L1662–1666), yet `_cmd_projects_add` still prints
  "registered in … tier" and exits 0 (L2617–2631); the server's post-dispatch guard (§API Contracts)
  exists to catch exactly this.
- `aid projects remove <path>` (`_cmd_projects_remove` L2636): a non-digit argument is treated as a
  path, matched against the registry union verbatim/canonicalised (L2677–2700 — exit 2 if not
  registered), then `registry_unregister`. Works for **unavailable** (folder-gone) entries too
  (falls back to the raw path, L2682). Non-interactive.
- **SEC-4 note:** both paths are pure file-registry manipulation with **no `AskUserQuestion` /
  agent / LLM** step — unlike the connector-Add path (work `STATE.md` Q2 / feature-007), the
  LLM-free server *can* invoke these directly. Confirmed: `_cmd_projects_add/remove` contain no
  interactive `read`.

**4. Reader / model layer — no change.** `build_home_model` / `buildHomeModel` already enumerate
the registry union and emit `repo.id` + `repo.path` per entry. The re-render is a re-fetch of the
unchanged `/api/home` shape. The only serializer change in the whole work — the additive
`write_enabled` key — is owned by feature-001 and applied identically to both twins; feature-003
makes **zero parser or serializer edits**, so AC4 (byte-parity) is trivially preserved for this
feature (its server changes are the two twin op-handlers, added with identical behaviour and
response bytes and covered by the existing `test_server_py.py` / `test_server_node.mjs` parity
suites).

### API Contracts

**Route (feature-001):** `POST /api/op` (home-level; no `/r/<id>/` prefix). Request/response
envelope, size limit (≤64 KiB), and generic error classes are feature-001's; below are the two
rows feature-003 adds to `OP_TABLE` and completes in `_serve_home_op`.

**`project.add`** — register an existing AID folder for tracking (FR-P1).

```json
{ "op": "project.add", "args": { "path": "/abs/path/to/aid/project" } }
```
- Scope: `home` (no `target`).
- `args.path` (required): string; non-empty; **must be absolute** (`os.path.isabs` / Node
  `path.isAbsolute` — a POSIX `/…` root or a Windows drive/UNC root); length ≤ 4096; **rejects**
  NUL, newline (`\n`/`\r`), and other control chars → 400 `bad-request`. (Belt-and-suspenders — the
  argv array already precludes shell injection; the `aid` CLI performs the *semantic* validation.)
  **A relative path is rejected** (400 `bad-request`): the child `aid` canonicalises it (`cd && pwd`,
  L2598) against the *dashboard server process's* cwd — not the browser user's, and meaningless
  under `--remote` — so the UI collects an absolute path (placeholder `/absolute/path/to/aid/project`,
  §UI-P1) and the server enforces absoluteness before dispatch. The validated absolute path is
  handed verbatim as one argv element.
- Writer + argv: `bash $AID_CODE_HOME/bin/aid projects add <path>`; env `AID_HOME=<server aid_home>`.
- Rationale for accepting a body path (a documented exception to feature-001's "paths never from
  the body"): a *not-yet-registered* folder has no `id` to resolve, so registration is intrinsically
  path-driven. The exposure is bounded — the path is (a) never used to read/serve a file inside the
  server's own allowlist, only handed to a sub-CLI; (b) passed as an argv-array element (no shell);
  (c) fully validated by `aid projects add` (must exist + be an AID project) before anything
  persists.

**`project.remove`** — untrack a registered project (FR-P2).

```json
{ "op": "project.remove", "target": { "id": "<repo.id from the card>" } }
```
- Scope: `home`.
- `target.id` (required): must be a current key of the server's `id_map` → else 404 `not-found`.
  The server resolves `id → canonical path` from `id_map` (verbatim, SEC-2) and passes **that**
  path to the CLI. The untrusted body never supplies a path here (strictly safer than Add).
- Writer + argv: `bash $AID_CODE_HOME/bin/aid projects remove <resolved-path>`; env
  `AID_HOME=<server aid_home>`.
- The **`<path>` form** is used deliberately (never the `<N>` index form) so a concurrent list
  re-order cannot make the dashboard untrack the wrong project (FR-P2 "unambiguous per card").
  Works for unavailable/stale cards (the CLI accepts a gone folder's stored path).

**Exit → HTTP `status_map` (feature-003 rows).** The `aid` CLI uses its **own** exit alphabet
(0 = ok; **2 = user/validation error** for every `aid projects` failure — bad/absent path, not an
AID project, not registered, out-of-range index; `bin/aid` L2599/L2605/L2665/L2698). This differs
from the `writeback-state.sh` alphabet feature-001's default map assumes (where 2 = lock
contention). Each feature-003 row therefore declares an explicit map:

| `aid projects` exit | stderr | HTTP | `error` | Meaning |
|---------------------|--------|------|---------|---------|
| 0 | clean (no `WARN: aid:`) | 200 | — | registered / unregistered; client re-fetches `/api/home` |
| 0 | carries a `WARN: aid:` line (fail-open no-op) | 500 | `write-unverified` | CLI exited 0 but the (shared-tier) write was **skipped, not applied** — see the fail-open guard below; the `WARN` line → `detail` |
| 2 | (`ERROR: aid projects: …`) | 422 | `invalid-value` | path absent, not an AID project (add); not registered (remove) — stderr → `detail` |
| other nonzero | (any) | 500 | `write-failed` | unexpected CLI failure (stderr → `detail`, ≤1 KiB) |

**Fail-open guard — exit 0 is necessary but NOT sufficient for AC1/AC2.** `aid projects add/remove`
are *fail-open by design* (NFR10 / DD-3 / CLI-1): when a **shared-tier** write needs privilege
elevation and none is available, `registry_register` / `registry_unregister` print an
**unconditional** `WARN: aid: … not registered / could not update …` to **stderr** and **`return 0`
without writing** (`bin/aid` L1662–1666; the `_aid_priv_run` real probe returns 13 when sudo is
absent, L382–383, and cannot prompt in a non-TTY child either way). This is exactly the dashboard's
case: a **global CLI install** adding a path **outside `$HOME`** resolves to the `shared` tier
(`_aid_resolve_tier` L1520–1523), whose dir is not user-writable, and the dashboard spawns the child
**headless / non-TTY** — so the write silently no-ops while `_cmd_projects_add` still prints
"registered in … tier" and exits 0 (L2617–2631). A naive exit-0 → 200 would report a **phantom
success**: the UI re-fetches, the project never appears, and AC1 (persists to disk) / AC2 (no
surfaced drift) are violated with no error shown. **Therefore the handler captures the child's
stderr on EVERY exit (not only on nonzero) and, on a 0 exit, applies the guard:** a `WARN: aid:`
(or the `_aid_priv_run` `ERROR: aid:`) line on stderr means the write degraded to a no-op → **500
`write-unverified`** with that line in `detail`. This detector cannot false-positive on a healthy
add: the only *benign* WARN (the user-tier-fallback notice) is `--verbose`-gated (L1714–1715) and
the dashboard passes no `--verbose`, so on a non-verbose invocation every emitted `WARN: aid:` line
is an unconditional degrade signal (L1657 / 1664 / 1689 / 1694 / 1726 / 1740 / 1746). For **remove**
the guard is additionally corroborated **canonicalisation-free**: the resolved path is the
**verbatim** `id_map` value (SEC-2), so the handler re-loads the union (`_load_union_repos`,
`server.py` L160 / `loadUnionRepos`, `server.mjs` L180) and requires that exact string to now be
**absent** — else `write-unverified`. (For **add** a union-membership check is *not* used as the
detector, because the CLI stores the *logical* `cd && pwd` form while the registry is read
**verbatim** — no `realpath` on stored paths, CAN-1/DD-5, `server.mjs` L108/L264 — so the two forms
can differ under symlinks; the stderr-`WARN` signal is the reliable, canonicalisation-independent
one.) Only a clean exit 0 (no `WARN`; for remove, path confirmed gone) yields 200.

Host-header (403 `bad-host`), write-gate (403 `read-only`), malformed body / unknown op / bad
target shape (400 `bad-request`) are feature-001's generic pre-dispatch classes and apply
unchanged. **Integration requirement on feature-001:** the OP_TABLE row schema must carry an
optional per-op `status_map` (default = the `writeback-state.sh` alphabet), so the `aid`-CLI ops
(this feature's `project.add/remove`, and feature-004's `tools.update`) can override it. Flagged in
the RETURN as a cross-feature note since feature-001's spec is already graded.

**Success (200):** `{ "ok": true, "op": "project.add|project.remove" }`; the client then calls
`doFetch()` → `GET /api/home` and re-renders (NFR3/AC2).

### Security Specs

- **SEC-4 (LLM-free server) — preserved and load-bearing here.** The dispatched child is the `aid`
  CLI shell script; `aid projects add/remove` do pure registry-file manipulation with no
  `AskUserQuestion`/agent/LLM step (verified in `_cmd_projects_add/remove`). This is exactly why
  the registry ops are safe to run same-page, whereas the connector-Add path (Q2) is not.
- **SEC-3 (no in-process fs-write) — preserved.** The server writes nothing itself; it spawns the
  `aid` CLI with an argv array. The server-file audit (`open(...,'w')`/`writeFileSync`/…) stays
  empty; the only new syscall is `subprocess`/`child_process` of the allowlisted `aid` binary.
- **Injection / traversal.** argv **array** only — no `shell=True`, no command string, so metachars
  in a typed path cannot break out. `op` is from the closed OP_TABLE. For remove, the path comes
  from `id_map` (server-side, SEC-2 verbatim), not the body. For add, the body path is validated
  (absolute + length + no NUL/newline/ctrl; a relative path is rejected so it cannot silently
  resolve against the server's cwd) and then only ever handed to `aid`, which itself canonicalises
  and requires an AID project before persisting.
- **Write gate / trust model (AC8) — reused, not re-implemented.** `_serve_home_op` checks
  `write_enabled` after the Host-header allowlist (feature-001). On loopback ⇒ enabled ⇒ Add/Remove
  work. Under `--remote` without `--allow-writes` ⇒ read-only ⇒ every `project.*` op 403s and the
  UI hides both controls (`write_enabled:false`). Under `--remote --allow-writes` ⇒ writes work,
  gated only by the user's tailnet ACL. **No new network surface (C3):** the ops ride the existing
  loopback bind / tailscale `serve`; no new port or listener.
- **SEC-6 (Host-header allowlist)** runs before the gate on POST, so a malicious page cannot drive
  a registry mutation through a victim's browser even on a write-enabled loopback server.

### Migration / New Plumbing

- **No new writer script, no schema change, no data migration.** feature-003 re-uses the existing
  `aid projects` CLI and the existing `registry.yml` format; nothing is co-vendored (the `aid`
  binary already ships in the CLI package).
- **OP_TABLE `status_map` extension** (see §API Contracts) — the one cross-feature integration
  item; carried in the RETURN because feature-001's spec is already Ready/graded.
- **index.html command-text reconciliation (OQ-P2):** update the one stale command string in the
  read-only fallbacks — the unavailable-card guidance `aid remove --target <path>` (L936, a
  tool-uninstall command) → the untrack-only `aid projects remove <path>`. Text-only; no behaviour
  change. The empty-registry hint `aid add <tool>` (L533) is **left as-is** — it is the bootstrap
  command that scaffolds `.aid/` + auto-registers (`bin/aid` L3430), which `aid projects add`
  (register-only, requires a pre-existing `.aid/`, L2604) cannot replace; changing it would break
  the brand-new-user flow (OQ-P2).

### UI Specs

Grounded in the existing `index.html` patterns: the page is **load-once, no auto-poll** (boot at
L577; `doFetch` re-runs on the Refresh button and now on op success), renders `#repo-section` /
`#repo-grid` (L526/L528), an `#empty-registry` state (L532), and per-card content via
`_renderRepoCard` / `_renderUnavailableCard`. All new controls follow the existing `.card` /
`.btn-ghost` / `.badge` styling and the `escHtml`/`textContent` safety rule.

**Gating (single signal).** All write controls below render **only when
`envelope.machine.write_enabled === true`**; otherwise the current read-only presentation is
unchanged (the static prune guidance remains, text reconciled per OQ-P2). This mirrors feature-001's
"UI never offers a control the server will refuse."

**UI-P1 — Add Project.**
- Placement: a right-aligned "Add project" `.btn-ghost` in the `#repo-section` header row beside the
  "Projects" `<h2>` (L527); also surfaced inside `#empty-registry` (so the first project can be
  registered when the grid is empty).
- Interaction: clicking reveals an inline row — a text `<input>` (`placeholder="/absolute/path/to/aid/project"`,
  labelled; note "must already be an AID project — Add only registers it, it installs nothing"), a
  "Register" submit `.btn-ghost`, and "Cancel". Submit is a JS `fetch` POST of `project.add` with
  the trimmed input value (empty input → inline validation, no request). No native form submit
  (CSP `form-action 'none'`).
- Result: on `200`, `doFetch()` re-renders the grid (new card appears; AC2). On `422`/`500`, the
  form shows the writer's `detail` inline (e.g. "'…' is not an AID project; run 'aid add <tool>'
  first.") via `textContent` — the input stays populated so the user can correct it.
- No OS folder picker (OQ-P1): typed path only.

**UI-P2 — Remove Project.**
- Placement: a small "Remove" `.btn-ghost` on each card — added in `_renderRepoCard` (available,
  L815) and `_renderUnavailableCard` (stale, L902). On stale cards the button replaces the manual
  prune steps when `write_enabled` (the steps remain as the read-only fallback).
- Interaction: **lightweight confirm** — click flips the button **in place** to "Confirm untrack" +
  "Cancel" with copy stating **"Untracks this project from the dashboard. No files are removed."**
  This is a decided **inline button-flip, not a `window.confirm`**: the button-flip is
  keyboard-reachable, stylable with the existing `.btn-ghost`, `aria-live`-announceable, and
  consistent with UI-P1's inline reveal — whereas `window.confirm` is an unstylable blocking modal
  that breaks that consistency. This is intentionally *not* the strong destructive guard feature-009 Delete
  Pipeline requires (untrack is reversible via Add). On confirm, JS `fetch` POST of `project.remove`
  with `{target:{id: repo.id}}`.
- Result: on `200`, `doFetch()` re-renders (card disappears; AC2). On error, a transient inline
  message on the card (writer `detail`, `textContent`).

**Accessibility / consistency.** Buttons are real `<button type="button">` with discernible labels;
the confirm affordance is keyboard-reachable; error text uses `aria-live="polite"` consistent with
the existing `#freshness-badge` (L501). No layout/theme changes beyond the added controls.

### How the Acceptance Criteria are satisfied

- **AC1 — `aid projects` runs from the dashboard and the change persists.** Add clicks →
  `POST /api/op {op:"project.add"}` → server spawns `bash $AID_CODE_HOME/bin/aid projects add
  <typed-path>` with `AID_HOME=<server aid_home>`; the CLI writes the tier's `registry.yml`. Remove
  → `project.remove` → `aid projects remove <id_map-resolved-path>` → `registry_unregister`. Both
  persist to the exact registry the server reads (env-pinned), so the change survives reload. Because
  the CLI is **fail-open** on an unavailable shared-tier elevation (§API Contracts), the handler
  returns 200 **only after** confirming the mutation (clean stderr; for remove, the `id_map` path
  gone from the re-loaded union); a fail-open no-op yields **500 `write-unverified`**, never a
  phantom success — so a 200 always implies persistence.
- **AC2 — truthful re-render, no drift.** Each *landed* `aid projects` write changes a `registry.yml`
  stat; the client's immediate `doFetch()` → `/api/home` busts the `_get_id_map` stat cache
  (L248–254), rebuilds the two-tier union, and re-renders `#repo-grid` from disk — the added card
  appears / the removed card disappears with no manual refresh. The drift window collapses from
  "next manual Refresh" to one immediate round-trip. When a shared-tier write instead **fails open**,
  the stat is unchanged and no card would appear; the exit-0 guard turns that silent nothing into a
  surfaced 500 rather than a confusing success-with-no-new-card, so the UI never reports a change
  that did not reach disk.
- **AC8 (foundation-inherited) — trust model.** Controls and server both honour feature-001's
  `write_enabled` gate: fully interactive on loopback; read-only (403 + hidden controls) under
  `--remote` unless `--allow-writes` + tailnet ACL. No new network surface (C3).
