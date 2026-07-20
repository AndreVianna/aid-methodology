# Update Tools

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.1 (FR-P6) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): two OP_TABLE ops (`tools.update` per-repo → `aid update --target`, `tools.update-self` home → `aid update self`) on feature-001's dispatch; UI on index.html (machine panel + repo-card action); write-gate + truthful re-render honored. Q4/OQ-P3 design decision recorded in this SPEC — trigger `aid update` as-is (no per-tool CLI), expose `aid update self`, place on index.html; the authoritative work STATE.md Q4 entry has since been synced to Status: Answered (Features State row 4 reads `Q4(ans)`, mirroring sibling feature-001/Q1). 3 known issues registered in work `known-issues.md` (KI-002/003/004); 2 high-stakes assumptions listed in §High-stakes assumptions. | /aid-specify |
| 2026-07-17 | Phase-2 re-check fixes (/aid-specify): broadened §Security "Known hazard" — the per-project `tools.update` op also reaches `bin/aid`'s self-update-if-stale preamble (line 3097–3099 → `_aid_update_self_if_stale` → `_cmd_update_self`), silently mutating the running server's own code with no restart advisory as originally specified; added the version-change restart advisory to the `tools.update` Feature Flow + UI + Data Model, and a new known issue **KI-006** (see RETURN). Corrected the now-stale Q4 sync-back narrative (§Change Log/Open Questions/Applied-to): work STATE.md Q4 is Status: Answered and Features State row 4 reads `Q4(ans)`. | /aid-specify |

## Source

- REQUIREMENTS.md §5.1 FR-P6 (Update Tools)

## Description

Add a control to update the installed host-tools' tooling versions from the dashboard. It
maps to the existing idempotent migration/upgrade mechanism — **`aid update`** (all
installed tools) and **`aid update self`** (the CLI). ⚠️ Corrected by cross-reference:
there is **no `aid update <tool>` per-tool form** (`bin/aid` rejects a tool positional on
`update`), so this is a UI over `aid update` as-is unless per-tool selection is newly built
(see Q4).

Depends on the write-infrastructure foundation (feature-001) for the operation endpoints.

## User Stories

- As a developer running AID on my own project, I want to update my AID tooling from the
  dashboard, so that I can keep my installed host-tool profiles current without leaving the
  dashboard to run the update command by hand.

## Priority

Must

## Acceptance Criteria

- [ ] AC1 — Given the Update Tools control, when I trigger it, then `aid update` runs from
  the dashboard and the tooling update is performed and persists; and if that run also
  self-updated a stale CLI (observable as a changed `machine.aid_version` on the post-op
  `/api/home` re-fetch), then the success notice advises restarting `aid dashboard` to load the
  new code (the running server keeps executing pre-update code until restart — see §Security
  "Known hazard", KI-006).
- [ ] AC1b — Given the global "Update CLI" self-update control, when I trigger it, then `aid
  update self` runs from the dashboard, the channel-installed CLI is updated and persists, and
  the success notice advises restarting `aid dashboard` to load the new code (the running
  server keeps executing pre-update code until restart — see §Security Specs).

## Open Questions

- **OQ-P3 / Q4 — Update Tools scope + placement — DECIDED at the design level in this SPEC
  (2026-07-17, /aid-specify) and SYNCED to the authoritative work STATE.md: the Q4 entry is now
  Status: Answered (carrying this decision as its Answer + the Applied-to list below), and the
  Features-State row 4 Q&A-count cell reads `Q4(ans)` — matching sibling feature-001/Q1, synced
  the same day.**
  **(a) Trigger `aid update` as-is** (updates all installed tools; zero new CLI). Option (b)
  net-new per-tool selection is **rejected**: no `aid update <tool>` form exists (`bin/aid`
  line 3054–3062 rejects any tool positional with exit 2), REQUIREMENTS §10 P1 scopes FR-P6
  as "wire to existing `aid update`", and per-tool selection is net-new CLI + plumbing (out of
  scope for a low-risk P1 "UI over a working command"). **`aid update self` IS also exposed**
  (a real, existing, safe command; same child-dispatch, no new CLI) — as a separate global
  "Update CLI" control. **Placement: both controls live on `index.html`** (NOT `home.html`):
  the global "Update CLI" in the machine panel (`renderMachinePanel`, index.html:700) and a
  per-project "Update Tools" action on each repo card (`_renderRepoCard`, index.html:815).
  Grounded rationale: `index.html` is the **only** surface whose UI actually **renders** the
  update's effect — the CLI version pill (`machine.aid_version`, server.py:516) and each repo's
  installed-tool version chips (`repo.aid_version`, index.html:850–864). `home.html` polls
  DM-1 (`./api/model`, home.html:1042); DM-1's `RepoModel` **does** embed the installed-tool
  version (`tool.aid_version`, parsed from the repo's `.aid/.aid-manifest.json` — models.py:110,
  parsers.py:139 — the very field `aid update --target` writes), but `home.html`'s current UI
  **renders no version**, so an `aid update` triggered there would produce a no-visible-change
  re-render, weakening the perceived AC2/NFR3 truthful re-render. See §Technical Specification below.

  **Applied to:** REQUIREMENTS.md §5.1 FR-P6 and §OQ-P3 (wording already corrected to the real
  `aid update` / `aid update self` verbs — no `aid update <tool>` form); this SPEC (Design
  decisions D1–D5, §API Contracts, §UI Specs). **STATE.md sync-back DONE:** the work
  `STATE.md` § Cross-phase Q&A → **Q4** entry is now Status: Answered — carrying this decision as
  its Answer (2026-07-17, /aid-specify feature-004) plus the Applied-to list above — and the
  Features State row 4 Q&A-count cell reads `Q4(ans)`, mirroring how sibling feature-001's Q1 was
  synced back to STATE.md the same day.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature is a **thin UI over
> two existing CLI verbs** — it adds **no new writer, no new CLI, and no envelope field**. It
> registers two operation handlers on the OP_TABLE that feature-001
> (`feature-001-write-infrastructure/SPEC.md`) defines, and adds two write controls to
> `index.html`. It **consumes** feature-001's write mechanism wholesale: the POST `/api/op`
> (home) and `/r/<id>/api/op` (per-repo) routes, the closed `OP_TABLE`, the `--allow-writes`
> write gate (`write_enabled`), the argv-array child dispatch (server stays LLM-free per SEC-4),
> the writer/exit-code → HTTP status map, and the truthful re-render contract (re-fetch the
> owning GET after `ok`). It does **not** re-invent any of them.
>
> **Grounding anchors (verified on disk):** `aid update` command handler `bin/aid` — `update`
> block line 2837, `update self` line 2839–2917, the "no per-tool positional" reject line
> 3054–3062, outside-repo CLI-only path line 3075–3092, self-update-if-stale preamble line
> 3097–3099, the non-interactive tool-install loop line 3363–3445; `update self`'s
> interactive per-repo migration walk (reads `/dev/tty`, skipped when non-interactive) line
> 2858–2916; dashboard spawn sets `AID_HOME=AID_STATE_HOME` (`bin/aid` line 1216 — the only env
> var set on the spawn), and the server/assets tree is `$AID_CODE_HOME/dashboard` (`bin/aid` line
> 1196; `AID_CODE_HOME` is self-located, not exported to the child). Dashboard server: `do_POST` blanket-405 today (`dashboard/server/server.py`
> line 906–909) + its `server.mjs` twin; DM-2 `machine` block build (`build_home_model`,
> `server.py` line 512–521: `aid_version`/`aid_home`/`tools_catalog`/`registry_path`/`cli_runtime`)
> and its `server.mjs` twin; `_tools_catalog` `server.py` line 406–425. UI: `renderMachinePanel`
> `dashboard/index.html` line 700–765; `_renderRepoCard` line 815–888 (card is `<a class="card
> card-link" href="/r/<id>/home.html">` line 826–828; installed-version chips
> `repo.aid_version` line 850–864); `home.html` polls `./api/model` line 1042; the "Assets out
> of date / restart `aid dashboard`" callout `index.html` line 516–521. Threading:
> `ThreadingHTTPServer` `server.py` line 1150 vs. single-event-loop `createServer` `server.mjs`
> line 880.

### Design decisions (Q4 / OQ-P3 resolution)

| # | Decision | Grounded rationale |
|---|----------|-------------------|
| D1 | **Trigger `aid update` as-is** (all installed tools). Reject net-new per-tool selection. | No `aid update <tool>` form exists — `bin/aid` line 3054–3062 rejects any tool positional (`exit 2`). REQUIREMENTS §10 P1 scopes FR-P6 as "wire to existing `aid update`". Per-tool selection is net-new CLI + plumbing (violates scope discipline for a low-risk P1 item). |
| D2 | **Expose `aid update self`** as a separate global "Update CLI" control. | It is a real, existing, channel-aware command (`_cmd_update_self`, `bin/aid` line 2856); dispatching it costs one extra OP_TABLE row and one button — no new CLI. The machine panel already surfaces `machine.aid_version`, making "update the CLI" the natural adjacent action. |
| D3 | **Both controls on `index.html`, not `home.html`.** Per-project "Update Tools" on the repo card; global "Update CLI" in the machine panel. | `index.html` is the **only** surface whose UI **renders** the update's effect — `machine.aid_version` (server.py:516) and per-repo `repo.aid_version` version chips (index.html:850–864). `home.html` polls DM-1 (`./api/model`, home.html:1042); DM-1's `RepoModel` **does** embed the installed-tool version (`tool.aid_version`, from the repo's `.aid/.aid-manifest.json`, parsers.py:139), but `home.html`'s current UI **renders no version** ⇒ an `aid update` fired there would re-render with no visible change, undercutting AC2/NFR3. |
| D4 | **No `args`, no per-tool/version knobs, no `--force`, no `--dry-run`** in v1. | Keeps the CLI surface minimal (AC1 needs only that `aid update` runs and persists — its conditional restart notice is UI-only, adding no CLI flag); `aid update` is idempotent by design (line 3406 comment). Dry-run preview and version-pinning are deferred enhancements, not built. |
| D5 | **Synchronous child dispatch (feature-001's model), generous timeout, UI busy-state — no async job machinery.** | Single-user, infrequent, explicitly-triggered op. Adding a job/status subsystem would over-engineer it. The one real cost — a Node-runtime event-loop freeze during a long update — is mitigated by a UI busy state, not by new plumbing (see §Security/Known-limitations and the returned known issues). |

### High-stakes assumptions

Two assumptions are load-bearing for the decisions above; if either is false the design must
change. These are the "2 high-stakes assumptions flagged" the Change Log records:

- **A1 — Single-user, infrequent, explicitly-triggered.** D5's synchronous child dispatch with
  no async job machinery — and the "acceptable" Node event-loop freeze (§Security) — rest on
  this assumption. If the dashboard became multi-user, or the op were automated/frequent, the
  whole-server freeze and the absence of any concurrency control would be a real defect, not an
  accepted UX cost.
- **A2 — Both `aid update` verbs stay idempotent and non-interactive-safe.** The "double-click /
  retry is safe" claim (§Data Model), the no-tty dispatch, and the best-effort self-update all
  assume `aid update` / `aid update self` remain idempotent (`bin/aid` line 3406) and self-skip
  their interactive `/dev/tty` migration walk when non-interactive (`bin/aid` line 2881–2883). A
  future `aid update` that added a destructive or interactive-only path would silently break
  this surface — a regression-test target.

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB, no schema change) | The "store" is the on-disk tool profiles + the channel-installed CLI; both are written by the `aid` CLI, not by this feature. Table below names the targets. |
| Feature Flow | Present | The two POST → gate → dispatch(`aid`) → re-fetch round-trips are the feature. |
| Layers & Components | Present | Two OP_TABLE rows (server) + two UI controls (`index.html`). No reader/parser change. |
| API Contracts | Present | The two op handlers registered on feature-001's OP_TABLE: argv, scope, arg-schema, status map. |
| Security Specs | Present | SEC-1/3/4/6 + the `--allow-writes` gate all preserved; the running-server-code-replacement hazard reached by **both** ops (`aid update self` explicitly, and `tools.update` implicitly via `bin/aid`'s stale-CLI self-update preamble, line 3097–3099); C3 (outbound fetch ≠ new network surface). |
| UI Specs | Present | Machine-panel "Update CLI" + repo-card "Update Tools", write_enabled gating, busy-state, truthful re-render, feature-003 card-action coordination. |
| Migration / New Plumbing | Present (minimal) | Two additive OP_TABLE rows + shared CLI-invocation helper; **no** new writer, **no** envelope key (reuses feature-001's `write_enabled`), **no** MANIFEST change. |
| State Machines | N/A | A tool/CLI update changes no work/pipeline/task lifecycle enum; nothing in `writeback-state.sh`'s state machine is touched. |
| Telemetry & Tracking | N/A | Single-user trust model; the child's stdout/stderr tail in the op response + server stderr on failure is sufficient (matches feature-001). |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback UI that shells out to two idempotent CLI verbs. |

### Data Model

**No database, no relational schema, no artifact-format change.** The mutations are performed
entirely by the `aid` CLI child; this feature writes nothing itself. Targets:

| Target | Written by (child) | Op | Visible in |
|--------|--------------------|----|-----------|
| A project's installed tool profiles (`<repo>/.claude/`, `.codex/`, …) + its `<repo>/.aid/.aid-manifest.json` `aid_version` | `aid update --target <repo>` → `install_tool` loop (`bin/aid` line 3408) | `tools.update` | repo card version chips `repo.aid_version` (index.html:850–864), re-fetched via `/api/home` |
| The channel-installed CLI at `$AID_CODE_HOME` (npm/pypi/curl) | `aid update self` → `_cmd_update_self` (`bin/aid` line 2856) | `tools.update-self` | machine-panel CLI pill `machine.aid_version` (index.html:712–717), re-fetched via `/api/home` |

> **Conditional secondary write (`tools.update` only):** before its tool-install loop, `aid update`
> may **also** self-update the channel CLI at `$AID_CODE_HOME` if it is stale — the self-update-if-stale
> preamble (`bin/aid` line 3097–3099 → `_cmd_update_self`, line 516). So `tools.update` can write the
> **same** target as `tools.update-self` as a side effect, mutating the running server's own code. This
> is surfaced by the changed `machine.aid_version` pill and the restart advisory (§Security "Known
> hazard", **KI-006**).

**C1/C2 relationship:** neither op writes `STATE.md` or any DERIVED view, so C1 (single-writer
via `writeback-state.sh`) and C2 (DERIVED read-only) are **not engaged** by this feature — they
are preserved trivially because this feature never touches those files. `aid` is the canonical
single owner of tool-profile installation, so delegating to it is the direct analogue of C1's
"one writer per target" discipline. Both verbs are idempotent (`bin/aid` line 3406), so a
double-click or retry is safe.

### Feature Flow

```
index.html machine panel  ── "Update CLI" (shown iff machine.write_enabled) ──▶ POST /api/op
   body: { "op": "tools.update-self" }                                          (home route)
index.html repo card      ── "Update Tools" (shown iff write_enabled && repo.available) ──▶
   POST /r/<repo.id>/api/op   body: { "op": "tools.update" }                    (per-repo route)

Dashboard server (server.py | server.mjs) — feature-001's _serve_op (per-repo) + the
_serve_home_op gate/dispatch skeleton feature-004 completes for tools.update-self (see §Layers):
  1. SEC-6 Host-header allowlist (_reject_bad_host)               → 403 bad-host
  2. write gate: write_enabled?                                   → 403 read-only
  3. parse JSON body; op ∈ OP_TABLE?                              → 400 bad-request
     non-empty args on these argument-free ops (arg-schema)       → 422 invalid-value
  4. per-repo op only: resolve <id> → repo path (id_map, SEC-2)   → 404 not-found
  5. build argv ARRAY for the op (feature-001 CLI-op dispatch; shared helper per feature-003):
        tools.update      → ["bash", <$AID_CODE_HOME/bin/aid>, "update", "--target", <repo-path>]
        tools.update-self → ["bash", <$AID_CODE_HOME/bin/aid>, "update", "self"]
     env: AID_HOME=AID_STATE_HOME only (AID_CODE_HOME NOT passed — the aid child self-locates it); no tty
  6. spawn child, generous timeout (600s); capture exit + stderr tail  (SEC-3: no in-process
                                                                        fs-write; SEC-4: child is
                                                                        the aid CLI, not an LLM)
  7. map exit → HTTP status (table in §API Contracts)
  ◀── 200 {ok:true, op} ── or ── 4xx/5xx {ok:false, op, error, detail}
  │ on ok
  ▼ re-fetch GET /api/home  (BOTH ops — the effect is a DM-2 field) → truthful re-render (AC2/NFR3)
    + tools.update-self: success toast advises restarting `aid dashboard` (running server still
      executes pre-update code; see §Security).
    + tools.update: if the post-op machine.aid_version changed vs. pre-op (bin/aid's stale-CLI
      self-update preamble, line 3097-3099, fired inside `aid update`), show the SAME restart
      advisory — the running server's code was mutated as a side effect (see §Security "Known
      hazard", KI-006).
```

Note that even the per-repo `tools.update` re-renders via **`/api/home`** (DM-2), not
`/r/<id>/api/model` (DM-1): the control lives on `index.html` — a page already bound to
`/api/home` (`fetch('/api/home')`, index.html:594) — and that page is where the updated version
is actually **rendered** (the repo-card chips). DM-1 also carries the updated value
(`tool.aid_version`), but `home.html` never displays it, so re-rendering there would show no
change — the concrete reason D3 places the control on `index.html`.

### Layers & Components

**1. Server layer** (`dashboard/server/server.py` + `dashboard/server/server.mjs`, byte-parity twins) —
**no new endpoint, no routing change of its own.** This feature appends two rows to the
`OP_TABLE` feature-001 introduces. It reuses feature-001's per-repo `_serve_op` gate + dispatch
verbatim, and — for the home op `tools.update-self` — **completes** feature-001's `_serve_home_op`
gate/dispatch **skeleton**: feature-001 seeds the per-repo table but explicitly leaves `/api/op`
handlers "to the registry feature", so each consuming home op registers its own OP_TABLE row and
completes the dispatch. This is the same relationship feature-003 declares for
`project.add`/`project.remove` ("completes `_serve_home_op` for the two registry ops"):

- `tools.update` — scope **per-repo, project-scoped** (like `settings.set`: it does **not**
  consume `target.work_id`; the repo path is resolved solely from `<id>` via `id_map`). argv:
  `aid update --target <resolved-repo-path>`.
- `tools.update-self` — scope **home** (POST `/api/op`, no `<id>`, no `target`). argv:
  `aid update self`.

**CLI-invocation helper (shared with feature-003 — feature-003's SPEC §Layers is the authoritative
definition of this mechanism).** Both ops shell out to the `aid` CLI via
feature-001's argv-array child dispatch (`subprocess.run([...], capture_output=True, timeout=…)` /
`execFileSync`/`spawnSync` with an array). `aid` is resolved **deterministically, never from
request input**: the server self-locates it at `$AID_CODE_HOME/bin/aid` (`_DASHBOARD_DIR.parent /
"bin" / "aid"`, the same self-location feature-003 uses) and invokes it **unconditionally as
`bash <$AID_CODE_HOME/bin/aid> update …`** — there is **no** OS branch, **no** bundled-Windows-shim
alternative, and **no** `PATH` fallback (the dashboard already requires bash for feature-001's
writers, and `bin/aid` already ships in the CLI package, so **no co-vendoring is needed**). This
matches feature-003's `project.add`/`project.remove` dispatch verb-for-verb; the resolver MUST be a
**single shared helper**, and where the two SPECs previously diverged **feature-003's description is
authoritative** (this reconciles that divergence). Flagged as cross-feature
coordination (**KI-004** in work `known-issues.md`; see §Migration). The child is spawned with
`AID_HOME=AID_STATE_HOME` (the correct registry root — the only env var `bin/aid` line 1216 sets on
the dashboard spawn); `AID_CODE_HOME` is **not** exported — `bin/aid` self-locates it per-invocation
from its own path and, per its header (`bin/aid` line 45–52), it is **never overridden by an env
var**. The child runs with **no controlling
tty**, so `aid update`'s tool-install loop (non-interactive, `bin/aid` line 3363–3445) runs clean and
`aid update self`'s `/dev/tty` migration walk self-skips ("Skipping project migration
(non-interactive…)", `bin/aid` line 2881–2883).

**2. Writer/child layer:** the `aid` CLI only (already listed as an allowed dispatch target in
feature-001 §Layers "aid CLI (bin/aid) … aid update"). No `writeback-state.sh`, no
`write-setting.sh`, no `write-requirement.sh`, no new writer script.

**3. Reader / model layer** (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`): **no change.**
The updated versions are already read by the existing model builders — the CLI pill from
`_read_aid_version()`/`machine.aid_version` (server.py:516) and per-repo `repo.aid_version`
(reader.mjs ToolInfo, line 531/537). Re-fetching `/api/home` after the op surfaces them with **zero**
parser/serializer change, so AC4 (reader-twin byte-parity) is untouched by construction.

**4. UI layer** (`dashboard/index.html` only): two controls added — see §UI Specs. `home.html`
is **not modified** by this feature.

### API Contracts

Two rows appended to feature-001's closed `OP_TABLE` (later features never re-key these):

| `op` | Scope | argv (server-built array; never a shell string) | `args` | Route |
|------|-------|-----------------------------------------------|--------|-------|
| `tools.update` | per-repo (project-scoped; **no** `work_id`) | `bash $AID_CODE_HOME/bin/aid update --target <id→repo path>` | none (empty/absent; non-empty ⇒ 422) | `POST /r/<id>/api/op` |
| `tools.update-self` | home | `bash $AID_CODE_HOME/bin/aid update self` | none (empty/absent; non-empty ⇒ 422) | `POST /api/op` |

> `tools.update` **refines** the row feature-001 seeded (it had listed `tools.update` with a
> tentative "per-repo/home" scope and bare `aid update`): this spec fixes the scope to
> **per-repo project-scoped** and the argv to `aid update --target <repo>`. `tools.update-self`
> is **added** by this feature.

**Request** (`Content-Type: application/json`, body ≤ 64 KiB per feature-001):

```json
{ "op": "tools.update" }
```
(no `target.work_id`, no `args`). For `tools.update-self`: `{ "op": "tools.update-self" }`.

**Success (200):** `{ "ok": true, "op": "<op>" }`; the client re-fetches `/api/home` and
re-renders (NFR3/AC2).

**Failure:** `{ "ok": false, "op": "<op>", "error": "<class>", "detail": "<aid stderr/stdout tail, ≤1 KiB>" }`.
Status map (extends feature-001's map with the CLI-op-specific rows `timed-out` and
`update-failed`, which fold into feature-001's 500 `write-failed` alphabet where a caller does
not distinguish them):

| Condition | HTTP | `error` |
|-----------|------|---------|
| Untrusted Host header | 403 | `bad-host` |
| Write gate closed (read-only) | 403 | `read-only` |
| Malformed/oversize body, or unknown `op` | 400 | `bad-request` |
| Non-empty `args` on an argument-free op (arg-schema violation; feature-001 §API-Contracts convention) | 422 | `invalid-value` |
| Unknown repo `<id>` (per-repo op only) | 404 | `not-found` |
| `aid` not resolvable / not executable | 500 | `update-failed` |
| `aid` exits non-zero (mid-commit heal, staging/checksum, usage) | 500 | `update-failed` |
| Child exceeds the 600 s ceiling (killed) | 504 | `timed-out` |
| `aid` exits 0 | 200 | — |

The server **controls the entire argv** (fixed tokens + a server-resolved path), so `aid`'s own
usage-error exits (e.g. the tool-positional reject, `bin/aid` line 3054–3062 — the `exit 2` is at line 3061) are not
reachable through this surface; they collapse to `update-failed` only if the shared helper is
mis-wired — a test target.

### Security Specs

**Write gate (AC8) — inherited unchanged from feature-001.** Both ops are refused with HTTP 403
`read-only` unless the server was spawned `--allow-writes` (`write_enabled = loopback OR
(--remote AND --allow-writes)`). `machine.write_enabled` also gates the UI (controls hidden when
false), so under `--remote` without the opt-in the update buttons never render and the endpoint
403s — no new enforcement code, this feature just adds two gated ops.

**Preserved invariants:**

- **SEC-1** — unchanged; no bind/listener added. The literal `127.0.0.1` bind is orthogonal to
  these ops.
- **SEC-3** — refined exactly as feature-001 specified: the server performs **no in-process
  filesystem mutation**; all writing happens in the `aid` child process. The server-file audit
  (`open(...,'w')`/`writeFileSync`/`appendFile`/`unlink`) stays empty; the only new syscalls are
  a `subprocess`/`child_process` of the allowlisted `aid` CLI with an argv **array** (no
  `shell=True`, no string concatenation).
- **SEC-4** — unchanged; the dispatched child is the `aid` CLI (a shell program), never an
  agent/LLM import.
- **SEC-6** — unchanged and load-bearing: the Host-header anti-DNS-rebinding allowlist runs
  before the write gate on the POST path, so a hostile page cannot drive an update through a
  victim's write-enabled loopback browser. There are **no `args`** to validate (closed,
  argument-free ops), so the injection surface is nil beyond the op key itself.
- **C3 (no new network surface)** — preserved. `aid update`/`aid update self` make **outbound**
  fetches to GitHub/npm/PyPI, but that is the pre-existing behavior of the CLI when run in a
  terminal; it adds **no new inbound listener, port, or bind** to the dashboard. C3 governs the
  dashboard's network surface, which is unchanged (loopback + the existing opt-in tailscale
  `serve`).

**Known hazard — BOTH ops can mutate the running server's own code.** `aid update self`
reinstalls the channel package at `$AID_CODE_HOME`, i.e. the very tree the dashboard server
(`server.py`/`reader.mjs`) was launched from (`bin/aid` line 1196). The running process keeps
executing the **already-loaded** pre-update code until `aid dashboard stop && aid dashboard
start`.

**The per-project `tools.update` op reaches the identical code-mutation — silently, via a
non-obvious trigger.** The plain `update` reach (`aid update --target <repo>`, i.e. the per-project
"Update Tools" button — NOT `update self`) fires `bin/aid`'s **self-update-if-stale preamble**
(`bin/aid` line 3097–3099; its own comment reads *"For 'update' inside an AID repo only (not 'add',
not 'update self')"*) → `_aid_update_self_if_stale` (`bin/aid` line 475) → `_cmd_update_self` (called
`bin/aid` line 516) **whenever the installed CLI is stale** vs. the cached `~/.aid/.update-check`
latest (the preamble self-skips only when no cached latest is known — line 490, no network call — or
under `--from-bundle` — line 496; it never downgrades — line 508). There is **no tty gate** on this
path (it is WARN-not-fail / best-effort, line 514–517), so triggering a routine tool update can
reinstall `$AID_CODE_HOME` — mutating the running server's own code — **as a silent side effect the
user did not think of as a CLI self-update**, and with **no restart advisory** on the `tools.update`
response as originally specified. This is the same running-server-code hazard as `aid update self`,
reached through the per-project control.

Mitigations: (1) the `tools.update-self` success toast explicitly advises restarting
`aid dashboard` (reusing the existing "Assets out of date … restart `aid dashboard`" copy,
index.html:516–521); (2) the **same restart advisory is shown after `tools.update`** whenever the
post-op `/api/home` re-fetch reports a `machine.aid_version` that differs from the pre-op value — the
observable signal that the stale-CLI preamble self-updated the running server (**no new plumbing**:
`machine.aid_version` is already a DM-2 field, server.py:516); (3) both ops are idempotent and
best-effort (a failed self-update leaves the old CLI intact). Registered as known issues: **KI-002**
(the explicit `aid update self` hazard) and **KI-006** (the implicit `tools.update` self-update
reachability — see RETURN; number to be confirmed by the orchestrator). Neither is fully solved here —
an in-process hot-reload is out of scope.

**Known limitation — Node event-loop block.** feature-001's dispatch is synchronous
(`execFileSync`/`spawnSync`). On the Python runtime `ThreadingHTTPServer` (server.py:1150) runs
each request on its own thread, so a long `aid update` does not stall polling; on the Node
runtime (`createServer`, single event loop, server.mjs:880) the synchronous child **blocks the
whole server** for the update's duration (potentially minutes). For a single-user, infrequent,
explicitly-triggered op this is an acceptable UX freeze, mitigated by the UI busy-state + button
disable (§UI Specs) and the 600 s ceiling; introducing async job machinery would over-engineer
it. Registered as a known issue (**KI-003** in work `known-issues.md`).

### UI Specs

Both controls are on **`dashboard/index.html`** and follow the existing `btn-ghost` button
idiom (e.g. the Refresh button, index.html:503). Neither renders unless
`machine.write_enabled === true` (feature-001's DM-2 gate; **missing ⇒ false**, fail-safe).

**1. Global "Update CLI" — machine panel** (`renderMachinePanel`, index.html:700–765). Append an
action row to the `card.plugin` (after the `dl`, before `container.appendChild(card)`):

- Control: `<button class="btn-ghost">Update CLI</button>`, shown only when
  `machine.write_enabled === true`.
- Click: disable the button, swap label to "Updating…" (busy state), `fetch('/api/op', {method:'POST',
  headers:{'Content-Type':'application/json'}, body: JSON.stringify({op:'tools.update-self'})})`.
- On `ok`: re-fetch `/api/home`, re-render (the `machine.aid_version` pill, index.html:712–717,
  reflects the new version), and show a dismissible notice: "AID CLI updated — restart
  `aid dashboard` to load the new dashboard code."
- On failure: re-enable the button and surface `error`/`detail` inline (no silent failure).

**2. Per-project "Update Tools" — repo card** (`_renderRepoCard`, index.html:815–888). The card
is an `<a class="card card-link" href="/r/<id>/home.html">` (index.html:826–828), so a
`<button>` **must not** be nested inside it (invalid/inaccessible interactive nesting). Instead,
wrap the card: the grid item becomes a container holding the existing `<a>`/`<div>` card **plus a
sibling action row** (`<div class="card-actions">`) carrying the "Update Tools" button. The
whole-card navigation link is preserved; the action lives outside it.

- Control: `<button class="btn-ghost">Update Tools</button>`, shown only when
  `machine.write_enabled === true` **and** `repo.available === true` (an unavailable repo has no
  `.aid/`/manifest to update; `_renderUnavailableCard`, index.html:820 path gets no button).
  `_renderRepoCard` currently receives only `repo` (index.html:815); the envelope-level
  `machine.write_enabled` (read in `renderMachinePanel`, index.html:632) must be threaded through
  `renderRepoGrid` → `_renderRepoCard` so the card can gate its button on the same global flag.
- Click: busy-state, `fetch('/r/' + repo.id + '/api/op', … body {op:'tools.update'})`.
- On `ok`: re-fetch `/api/home`, re-render — the card's installed-tool version chips
  (`repo.aid_version`, index.html:850–864) reflect the new version (AC2/NFR3). **If the re-fetched
  `machine.aid_version` differs from the pre-op value** — the observable signal that `aid update`'s
  stale-CLI self-update preamble ran (§Security "Known hazard", **KI-006**) — also show the same
  dismissible "AID CLI updated — restart `aid dashboard` to load the new dashboard code" notice as
  the "Update CLI" control, because the running server's code was mutated as a side effect.
- On failure: re-enable + inline `error`/`detail`.

**Cross-feature UI coordination (flagged — KI-004).** feature-003 (Add/Remove Project) also adds
a per-repo-card action (Remove Project) and a page-level Add Project control to `index.html`.
The `card-actions` sibling row this spec introduces should be the **same single scaffold**
feature-003 uses, with "Update Tools" and "Remove Project" as buttons within it — not two
independently-invented action rows. This must be reconciled when both features are built
(**KI-004** in work `known-issues.md`; see RETURN).

**Long-running feedback.** Because a real update takes seconds-to-minutes, the busy-state is
mandatory: the triggering button is disabled and labelled "Updating…" until the op resolves; on
the Node runtime the page is unresponsive during that window (documented limitation above) — the
busy label sets the expectation.

### Migration / New Plumbing

- **Two additive OP_TABLE rows** (`tools.update`, `tools.update-self`) — the only server-side
  change; no route, gate, envelope, or reader change.
- **No envelope key added** — reuses feature-001's `write_enabled` (DM-2 `machine` block). DM-2
  `schema_version` stays 1.
- **No `dashboard/MANIFEST` change** — no new script is co-vendored (the `aid` CLI already ships
  in `bin/`; the dashboard unit already ships). AC4 parity fixtures are unaffected (no model
  bytes change).
- **Shared CLI-invocation helper** — the deterministic `aid`-resolver + argv-array dispatch
  (feature-003's authoritative `bash $AID_CODE_HOME/bin/aid <verb>` form — self-located, no OS
  branch, no Windows shim, no `PATH` fallback, no co-vendoring) must be implemented **once** and
  shared with feature-003's `project.*` ops (see §Layers). Flagged as cross-feature coordination
  (**KI-004** in work `known-issues.md`).
- **No data migration** — nothing in `.aid/` state format changes.

### How the Acceptance Criteria are satisfied

- **AC1 (Update Tools works end-to-end and persists).** The "Update Tools" repo-card control
  POSTs `{op:"tools.update"}`; the server (write-gate-passed) resolves `<id>`→repo path and
  spawns `aid update --target <repo>`, which drives every installed tool in that project to the
  current version and writes the project's profile trees + manifest on disk (`bin/aid` line
  3408). Note `aid update` may also self-update a stale CLI first (the line 3097–3099 preamble →
  `_cmd_update_self`) — the running-server-code hazard documented in §Security "Known hazard"/KI-006,
  surfaced by a changed `machine.aid_version` and the restart advisory. On `ok` the client re-fetches
  `/api/home` and the card's version chips reflect the persisted change. Both controls are gated by feature-001's `--allow-writes` write gate (AC8),
  leave `writeback-state.sh`/STATE.md/DERIVED untouched (C1/C2 preserved trivially), require no
  reader/serializer change (AC4 parity intact), and re-render truthfully from a post-write
  `/api/home` GET (AC2/NFR3).
- **AC1b (Update CLI self-update works end-to-end and persists).** The global "Update CLI"
  machine-panel control POSTs `{op:"tools.update-self"}`; the server (write-gate-passed) spawns
  `aid update self` (`_cmd_update_self`, `bin/aid` line 2856), which reinstalls the channel CLI
  at `$AID_CODE_HOME` and persists it. On `ok` the client re-fetches `/api/home`, the
  `machine.aid_version` pill (index.html:712–717) reflects the new version, and the success
  notice advises restarting `aid dashboard` (the running server keeps executing pre-update code
  until restart — §Security "Known hazard", KI-002). This makes the FR-P6 "`aid update self`"
  half independently testable, not just implied by AC1.
