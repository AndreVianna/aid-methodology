# Pipeline Dashboard App (Render + Poll + Serve)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §5 FR1,FR4,FR5,FR8,FR9,FR11,FR14; §6 NFR1–8; §7 C1,C2; §8 OQ2; §9 AC1–5 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR1 (per-repo dashboard), FR4 (live polling), FR5 (configurable interval),
  FR8 (visual-first design), FR9 (one project per page), FR11 (attention signals),
  FR14 (parallel-execution display)
- REQUIREMENTS.md §6 NFR1–NFR8 (local-only/never-public, read-only, freshness, low overhead,
  cross-platform/browser, responsive, no-agents-at-runtime, summary-style consistency)
- REQUIREMENTS.md §7 C1 (never public), C2 (local private by default)
- REQUIREMENTS.md §8 OQ2 (dependency footprint)
- REQUIREMENTS.md §9 AC1–AC5 (the MVP)

## Description

The single indivisible MVP artifact: the **dashboard web app for one pipeline**. It renders the
pipeline's stages and "where we are," the currently-executing skill/task(s) **including parallel
tasks**, and **actively calls out** paused/blocked/error states (FR11); it **refreshes by polling**
the reader's model (default 5s, user-configurable from the page); and it **serves locally** in a
browser — **one project per page**, **never public**, localhost-bound by default. It follows
dashboard visual best practices (FR8) and matches the existing `knowledge-summary.html`
style/theme/colors (NFR8), renders across major browsers, and is responsive across
mobile/tablet/desktop. At runtime it is **deterministic code with no agents/LLM** (NFR7).

Carries **OQ2** (dependency footprint): decide self-contained HTML vs. a small stdlib-only local
server, bounded by NFR7/NFR4 and the zero-third-party-dep posture of the AID toolchain.

## User Stories

- As an **operator piloting a run**, I want a live local page showing where the pipeline is and
  what's executing, so I know status and what's next at a glance.
- As an **operator**, I want failures and "waiting for me" states called out, so I can act quickly.
- As an **operator**, I want to set the refresh rate, so I can trade freshness for overhead.

## Priority

Must (MVP).

## Acceptance Criteria

- [ ] Given an active pipeline, when I open the dashboard, then I see its stages and current
      position (AC1) and the current skill/task(s) with state, including parallel tasks (AC2).
- [ ] Given a paused or failed pipeline, when I view it, then it clearly distinguishes
      awaiting-input vs. awaiting-confirmation(=input) vs. error/blocked (AC3, FR11).
- [ ] Given the page is open, when state changes on disk, then the view updates within the polling
      interval (default 5s, configurable), so displayed state lags reality by ≤ the interval
      (AC4, FR4/FR5, **NFR3**).
- [ ] Given the dashboard is served, then it is reachable locally in a browser and **never** on the
      public internet (AC5, C1/C2/NFR1); it binds to localhost by default.
- [ ] Given the rendered page, then it matches the `knowledge-summary.html` visual style (NFR8),
      renders in Chrome/Firefox/Edge/Safari (NFR5), and is responsive (NFR6).
- [ ] Given the dashboard at runtime, then it invokes no agent/LLM (NFR7) and writes nothing (NFR2).

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the
> `/api/model` JSON contract — the serialized shape of feature-002's in-memory `RepoModel`, plus a
> `schema_version` field and the cross-runtime parity contract), **Feature Flow** (browser load →
> poll loop → `fetch('/api/model')` → server runs feature-002's `read_repo()` → render; the
> request/response cycle, configurable interval, error/stale handling), **Layers & Components** (the
> two halves: the static front-end and the dual-runtime thin server; the byte-identical parity
> requirement). Conditional: **UI Specs** (REQUIRED by FR8/FR9/FR11/FR14/NFR5/NFR6/NFR8 — the
> pipeline-view component breakdown, attention treatment, responsive breakpoints, design-token
> reuse), **Telemetry & Tracking** (the freshness/liveness badge driven by `ReadMeta` + heartbeat,
> consumed read-only from feature-002). Skipped: **API Contracts → external** (the only API is the
> internal localhost `/api/model`; specified under Feature Flow, not an external integration),
> **Migration Plan** (none — net-new), **Security Specs / remote exposure** (feature-005; this
> feature only notes the bound localhost port is the surface feature-005 fronts), **CLI** (feature-004),
> **State Machines** (the FR16 lifecycle derivation is owned by feature-002; this feature renders
> the derived `lifecycle` literal, it does not re-derive it).

OQ2 is **RESOLVED (REQUIREMENTS §8): Option C (hybrid), dual-runtime.** A pure `file://` page cannot
poll live `.aid/` state (browsers block `file://` `fetch`), so live polling (FR4) requires a runtime
process. This feature delivers two halves that ship together:

1. A **dependency-free static front-end** (`index.html` + inlined CSS/JS, no build step, no web
   fonts, no CDN at runtime) that reuses the `knowledge-summary.html` design family
   (`canonical/templates/knowledge-summary/`) per NFR8, and
2. A **thin local server** — implemented **twice, once per runtime** (Python 3.11+ stdlib
   `http.server` and Node built-in `http`; zero third-party deps per `technology-stack.md`) — that
   serves the static asset(s) on `/` and feature-002's read result as JSON on a single
   **`/api/model`** endpoint, **bound to `127.0.0.1`** (C1/C2).

The user picks the runtime at launch (feature-004 CLI `aid dashboard start node|python`); the
`/api/model` JSON and the front-end are **byte-identical across runtimes**, guaranteed by a parity
test (PT-1). The CLI itself is feature-004 and is **out of scope here**; the `--remote` flag is
feature-005's ACL-scoped Tailscale layer over this bound port and is **out of scope here** except to
note the localhost port is the surface feature-005 fronts.

This feature is the **single-page pipeline-progress view (AC1–AC5)** — the project main page (FR3),
KB dashboard (FR15), full drill-down (FR13), and level-0 card UI (FR7) are later features
(006/007/008). At runtime the whole stack is **deterministic code with no agent/LLM** (NFR7) and the
server **only ever calls `read_repo()`** — it writes nothing (NFR2). These two invariants are
enforced structurally (LC-S below), not merely asserted.

---

### Data Model

There is no relational schema (AID ships no database, `schemas.md`). The "data model" of this
feature is the **`/api/model` JSON contract**: the on-the-wire serialization of feature-002's
in-memory `RepoModel`. **This feature does not redefine the model** — feature-002 owns the
`RepoModel`/`WorkModel`/`TaskModel`/`ToolInfo`/`RepoInfo`/`ReadMeta` types, their fields, parse
rules, and the FR16 lifecycle derivation. This feature defines only (a) how that model is serialized
to JSON, (b) a version/envelope wrapper, and (c) the cross-runtime parity contract.

#### DM-1. `/api/model` response envelope

`GET /api/model` returns `200` with `Content-Type: application/json; charset=utf-8` and this body:

```jsonc
{
  "schema_version": 1,            // int; bumped on any breaking change to the wire shape
  "generated_by": "python",       // "python" | "node" — provenance, MUST NOT appear in the parity-compared subtree (see PT-1)
  "model": { /* serialized RepoModel — DM-2 */ }
}
```

- `schema_version` lets the front-end fail loud (not silently mis-render) if the server is a
  different vintage than the page. The front-end checks `schema_version === EXPECTED` and, on
  mismatch, renders a banner ("dashboard assets are out of date — restart `aid dashboard`") rather
  than guessing. Starts at `1`.
- `generated_by` is **diagnostic only** and is the **single field excluded** from the PT-1 parity
  comparison (it is legitimately runtime-specific). Every other byte of the response MUST be
  identical across runtimes.

#### DM-2. `model` — serialized `RepoModel` (feature-002 DM-1 .. DM-7)

The `model` object is the JSON projection of feature-002's `RepoModel`. Field names are the snake_case
field identifiers feature-002 already defines; the serialization rules are:

| feature-002 type | JSON shape | Serialization rules |
|------------------|-----------|---------------------|
| `RepoModel` | object `{ tool, repo, works, read }` | top-level keys exactly as feature-002 DM-1 |
| `ToolInfo` (DM-2) | object | `manifest_present:false` → other fields `null`; never omit a key (stable shape) |
| `RepoInfo` (DM-3) | object; `kb_state` is `KbStateRef`-object or `null` | absent KB → `kb_state: null` |
| `works: list<WorkModel>` (DM-4) | array, **sorted by `work_id` ascending** (PT-1 determinism) | empty repo → `[]` |
| `WorkModel` (DM-4) | object | enum fields serialize as their **exact enum literal string** (e.g. `"Paused-Awaiting-Input"`); `null`s preserved, keys never dropped |
| `tasks: list<TaskModel>` (DM-5) | array, preserved in **source-row order** (table order; FR14 wave grouping is the renderer's job) | `_none yet_` already skipped by feature-002 → `[]` |
| `TaskModel` (DM-5) | object | `status` serializes the `TaskStatus` literal incl. the reader-only `"Unknown"` sentinel (feature-002 DM-6) |
| `ReadMeta` (DM-7) | object `{ read_at, work_count, fallback_works, parse_warnings, bytes_read }` | `read_at` is the reader's ISO-8601 UTC clock read; drives the freshness badge (Telemetry) |

**Enum values are strings, not codes.** The wire carries the literal enum members feature-002
declares (`Lifecycle ∈ Running | Paused-Awaiting-Input | Blocked | Completed | Canceled`;
`TaskStatus` incl. `Unknown`; `Phase`), so the single source of truth stays feature-002 →
feature-001; the front-end maps each literal to a CSS class (UI-4) but never invents its own
vocabulary. The front-end MUST tolerate an **unrecognized** enum string (forward-compat: a future
feature-001 member) by falling back to a neutral "unknown" badge rather than throwing — mirroring
feature-002's `Unknown` discipline (NFR7 deterministic, never crashes on data).

#### DM-3. Determinism rules (prerequisite for parity, PT-1)

Both runtimes MUST emit a response that is **byte-identical** (excluding `generated_by`) for the same
`.aid/` snapshot. That requires canonicalizing serialization on both sides:

| Rule | Requirement |
|------|-------------|
| Key order | Object keys emitted in a fixed declared order (the field order of each feature-002 type). Python: `json.dumps(..., sort_keys=False)` over an ordered dict built in declared order; Node: construct object literals in declared order (V8 preserves insertion order for string keys). |
| Array order | `works` sorted by `work_id`; `tasks`, `parse_warnings`, `fallback_works` in source order. No set/hash iteration leaks. |
| Separators / whitespace | Compact, fixed: Python `json.dumps(..., separators=(",", ":"), ensure_ascii=False)`; Node `JSON.stringify(obj)` (already compact). Both UTF-8, no trailing newline, no BOM. |
| Numbers | Only integers cross the wire (`work_count`, `bytes_read`, `schema_version`); no floats (avoids `1.0` vs `1` divergence). |
| Strings | `ensure_ascii=false` on Python so non-ASCII content (e.g. a project name) is emitted as UTF-8. (This is **runtime output**, not a shipped script — the ASCII-only rule of `coding-standards.md` governs the `.py`/`.mjs` *source*, not the JSON payload it emits.) ⚠️ **Line/paragraph-separator escaping (mandatory for parity):** Python `json.dumps(ensure_ascii=False)` emits raw `U+2028`/`U+2029`, but Node `JSON.stringify` escapes them to ` `/` ` (ES2019). To make the two runtimes byte-identical, the **Python** server MUST post-process its serialized output with `.replace(" ", "\\u2028").replace(" ", "\\u2029")` (equivalently, Node MUST NOT special-case them — its default already escapes). The canonical form is the **escaped** form (matches Node default). PT-1's fixture MUST include a STATE.md string containing `U+2028` and `U+2029` so this guarantee is enforced, not assumed. |
| `read_at` exclusion | `model.read.read_at` is a wall-clock value and therefore **excluded from parity comparison alongside `generated_by`** — PT-1 compares the model with `read.read_at` normalized/stripped (see PT-1). |

#### PT-1. Parity contract (the dual-runtime guarantee)

A test fixture `.aid/` tree (a checked-in sample with at least: one `Running` work with parallel
tasks, one `Paused-Awaiting-Input`, one `Blocked` with an IMPEDIMENT, one `Completed`, one fallback
`source_mode` work, and a no-`.aid/` empty case) is read by both runtimes. The test asserts:

```
strip(generated_by) and normalize(model.read.read_at) on both responses  ⇒  byte-identical
```

This is the structural guarantee that "implemented twice" never means "behaves twice." It lives in
`tests/` alongside feature-002's reader tests (`test-landscape.md`: bash aggregator + per-runtime
`.mjs`/python validators that skip if the runtime is absent — so a Linux CI box without Node still
runs the Python half and vice-versa, and the parity assertion runs only when **both** runtimes are
present). Registered as a deliverable, not optional polish: it is the verification of OQ2's "the
contract is identical across runtimes" promise.

---

### Feature Flow

The runtime cycle. Browser is a pure consumer; the server's only state-touching call is feature-002's
`read_repo()`, which is itself read-only (NFR2) and LLM-free (NFR7).

```
LAUNCH (feature-004 spawns the chosen runtime's server; out of scope here)
  server.start():
    bind 127.0.0.1:<port>        # C1/C2 — NEVER 0.0.0.0; bind addr is hard-coded, not configurable
    routes: GET /            -> static index.html (+ any cached assets)   [LC-S route table]
            GET /api/model   -> read_repo(aid_root) -> serialize (DM-1)   [the only dynamic route]
            *                -> 404
    (no other verbs; POST/PUT/DELETE/PATCH -> 405; NFR2 has no write surface to expose)

BROWSER LOAD
  1. GET /                       -> index.html (HTML + inlined CSS/JS; no build, no CDN at runtime)
  2. page boot:
       read poll interval from localStorage (default 5000 ms, FR5)        [UI-5]
       immediate first fetch (don't wait one interval to show anything)
  3. POLL LOOP (setInterval / self-rescheduling setTimeout):
       a. fetch('/api/model')                                              (same-origin, no CORS)
       b. on 200: parse JSON; if schema_version !== EXPECTED -> stale-assets banner, keep last good view
       c. validate envelope; render(model)                                [UI-1..UI-6]
       d. update freshness badge from model.read.read_at + heartbeat       [Telemetry]
       e. on network error / non-200 / timeout: keep last good view, show "reconnecting" badge,
          back off (do NOT hammer); next tick retries. The page never goes blank on a transient miss.
  4. interval change (FR5): user edits interval control -> clamp [1s..600s] -> persist to localStorage
       -> reschedule loop (takes effect next tick; an in-flight fetch is allowed to finish)
```

- **Refresh = re-read, by design.** Each poll is one `read_repo()` pass; feature-002 builds the
  model fresh with no caching, so displayed state lags disk by **≤ one interval** (NFR3, AC4). There
  is no server-side cache to invalidate and no push channel (FR4: polling; push is explicitly a
  future evolution).
- **Single in-flight poll.** The loop guards against overlap: if a `fetch` is still pending when the
  next tick fires (slow read on a huge `.aid/`), the tick is skipped rather than stacking requests
  (NFR4 low overhead). The self-rescheduling `setTimeout` variant is preferred over naive
  `setInterval` precisely so the next poll is scheduled only after the current one resolves.
- **Error/stale handling is first-class (AC4/NFR3).** Three render states the page distinguishes:
  *live* (last fetch ok, `read_at` recent), *stale* (last fetch ok but model is older than ~2×
  interval, or `parse_warnings` present), *disconnected* (last fetch failed — server stopped). The
  freshness badge in the top bar shows which, so the operator never mistakes a frozen view for a
  frozen pipeline.
- **Payload budget (NFR4).** The per-poll body is only the small `model` JSON (a handful of works ×
  a few tasks each). Heavy assets — if Mermaid is ever used for a diagram view — are served **once**
  as cached static files (or inlined into `index.html` like `knowledge-summary.html` does) and the
  diagram is rendered **client-side from the polled JSON**; the library is **never** re-sent per
  poll. MVP stage/state views are plain CSS/HTML (UI-2/UI-3) and need no Mermaid at all, so the MVP
  poll payload is JSON-only.
- **No write / no lock / no agent path.** The server process exposes no write route (the route table
  is a closed allowlist) and `read_repo()` itself acquires no lock and tolerates torn reads (a
  mid-write STATE.md yields a `parse_warning` on that one poll; the next poll self-corrects —
  feature-002 Feature Flow). There is no Agent/LLM call anywhere in the request path.

---

### Layers & Components

Two halves behind one HTTP origin. Per `coding-standards.md` (small, single-purpose, deterministic,
no hidden I/O) and `module-map.md` (these are new modules consuming feature-002's `read_repo`).

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-S Server (×2: Python + Node)** | server | bind `127.0.0.1`; route `/` (static) + `/api/model` (dynamic); call `read_repo(aid_root)`; serialize (DM-1/DM-3); return JSON | bind `0.0.0.0`; expose any write/mutating verb; call any agent/LLM; cache or persist the model; reach feature-005/CLI code |
| **LC-R Reader (feature-002)** | server | `read_repo(aid_root) -> RepoModel` — consumed as-is | (owned by feature-002; not re-specified) |
| **LC-F Front-end** | static | boot, poll loop, interval control, render the model, attention signals, freshness badge | mutate `.aid/`; call any external network at runtime; depend on a build step or CDN |
| **LC-A Assets** | static | the inlined/cached design-family CSS+JS reused from `knowledge-summary/` | fetch web fonts or CDN at runtime (NFR8: "no external assets") |

- **The two server implementations are siblings, not a port-of-one.** Each is the idiomatic thin
  server for its runtime (`http.server.ThreadingHTTPServer` + a `BaseHTTPRequestHandler`; Node
  `http.createServer`). They share **no code** but share the **contract** (DM-1/DM-3) and are held to
  it by PT-1. Each calls feature-002's `read_repo` **in its own runtime** — feature-002 specifies the
  reader in implementation-neutral terms (its own SPEC: every parse rule is "a single anchored
  grep / line-scan expressible in either runtime with zero third-party dependencies"), so OQ2's
  dual-runtime decision realizes `read_repo` once per runtime alongside its server. The reader↔server
  pair is therefore per-runtime, and PT-1 covers the whole `/api/model` output of each pair (reader +
  serializer together), not just the serializer.
- **Bind-address invariant (C1/C2, hard).** The listen address is the **literal `127.0.0.1`**,
  hard-coded, never read from config, never `0.0.0.0`, never `::`. A test asserts the server source
  contains no `0.0.0.0`/`INADDR_ANY`/wildcard-bind token and binds loopback (mirrors feature-002's
  "reader contains no write primitive" self-check pattern, `pipeline-contracts.md`). Remote
  reachability is **exclusively** feature-005's job, layered *over* this loopback port — the server
  itself can never go public, satisfying C1 structurally rather than by convention.
- **No-write invariant (NFR2, hard).** LC-S has no route that mutates and never opens a file for
  write/append; the only filesystem touch is `read_repo()`'s read path. A test asserts the server
  module contains no write/open-for-append/`os.remove`/`fs.write*` primitive (same self-check
  family).
- **No-LLM invariant (NFR7, hard).** LC-S + LC-F are plain code; there is no Agent/LLM client, no
  network egress except the browser↔server localhost loop. The static front-end makes exactly one
  kind of network call: same-origin `fetch('/api/model')`. A grep-level test asserts no
  `anthropic`/`openai`/agent-dispatch import in either server.
- **Dependency direction:** feature-004 (CLI) spawns → **LC-S** → `read_repo` (feature-002) →
  feature-001's *contract*. LC-S depends on nothing in feature-004/005. LC-F depends only on LC-S's
  `/api/model` contract and LC-A's stylesheet — not on any runtime detail, which is why the same
  `index.html` is served verbatim by both servers.
- **Zero build step.** `index.html` is shipped ready-to-serve (CSS + JS inlined, like
  `html-skeleton.html`). No bundler, no transpile, no `node_modules`. This keeps the "zero
  third-party deps" posture and means the Node server needs only Node's built-in `http` + `fs`, the
  Python server only stdlib `http.server` + `pathlib`/`json`.

---

### UI Specs

The MVP single page: one project, one pipeline-progress view (FR9 — one project per page; multiple
projects = multiple browser tabs, never blended). Built on the `knowledge-summary/` design family for
NFR8.

#### UI-1. Design-family reuse (NFR8)

| Reused from `canonical/templates/knowledge-summary/` | Used for |
|------------------------------------------------------|----------|
| `design-tokens.md` color palette — `--primary/--accent/--ok/--warn/--err/--info/--purple` + `*-bg` tints, light **and** dark theme | every status color; semantic tokens `--ok/--warn/--err` carry meaning and are reused verbatim |
| `component-css.css` `.top-bar`, `.brand`, `.controls` + `html-skeleton.html` `#theme-toggle` (`.btn-ghost`) | sticky header with project name + freshness badge + interval control + theme toggle |
| `component-css.css` `.card`, `.grid.g2/.g3/.g4`, `.kicker`, `.stat`, `.meta`, `.badge`, `.badge-ok/-warn/-err/-info/-purple/-primary/-accent` | work cards, task chips, stage pills, attention badges |
| `html-skeleton.html` shell (`<header role="banner">`, `<main id="top">`, theme toggle markup, system-font stack, `meta viewport`, `meta robots noindex`) | the page skeleton; **footer reworded** for the dashboard ("served locally by `aid dashboard` · read-only · refreshes every Ns"), Mermaid/lightbox blocks dropped for the MVP (no diagrams) |
| `lightbox.js`, `mermaid-init.js` | **NOT used in MVP** (no diagrams); cited only as the cached-once path if a future diagram view is added (Feature Flow payload note) |

System fonts only, CSS custom properties, no web fonts, no CDN — exactly the "no external assets"
posture `html-skeleton.html`'s footer advertises (NFR8). Theme toggle (light/dark) is carried over
as-is.

#### UI-2. Pipeline stages + "where we are" (AC1, FR8)

A horizontal **stage rail** rendered from `model.works[].phase` (feature-002 `Phase ∈ Interview |
Specify | Plan | Detail | Execute | Deploy | Monitor`) — one pill per phase, the **current phase**
emphasized (filled `--primary`/`--accent`; prior phases `--ok` muted "done"; later phases
`--text-dim` "upcoming"). The rail communicates "where in the process" at a glance (FR8: single short
words, color + shape, minimal text). The "full vs lite path" distinction (AC1) is reflected by which
phases the work actually carries in its data (a lite-path work simply shows fewer/merged phases —
the rail renders what `phase` reports, it does not assume a fixed 7-stop path). On the MVP page,
because FR9 is one-project-per-page and the MVP is the single-pipeline view, the page renders the
**one active/selected work**; the multi-work card grid (FR3) is feature-006.

#### UI-3. Current + parallel skill/tasks (AC2, FR14)

The level-3 view renders `model.works[].tasks[]` grouped by `wave` (feature-002 DM-5 carries each
task's own `status` + `wave`). Each wave is a row/cluster; **every concurrently-active task is its
own chip rendered side-by-side** — the view never collapses parallel tasks into a single "current
task" (AC2/FR14). Each task chip shows: short `type` (CODE/DESIGN/RESEARCH…), a `status` badge
(UI-4 color), `review_grade` if present, and `elapsed`. Active waves (any task `In Progress`/`In
Review`) are visually foregrounded; `Pending` waves are dimmed. Layout: `.grid.g3`/`.g4` of task
chips within a wave, wave groups stacked — so N simultaneous tasks are all visible at once on a
desktop viewport and reflow to a column on mobile (UI-6).

#### UI-4. Attention signals — color **and** shape (AC3, FR11, FR8)

FR11 requires *active call-out*, and FR8 requires color **and shape** (not color alone). The
work-level `lifecycle` literal (from `model.works[].lifecycle`, derived by feature-002) maps to a
badge that pairs a **distinct color + a distinct glyph/shape + one short word** so the three
attention states are distinguishable on shape alone (forward-compatible with the deferred
color-blind work, and robust under the dark theme):

| `lifecycle` literal | Color token | Shape / glyph | Word | AC3 mapping |
|---------------------|-------------|---------------|------|-------------|
| `Running` | `--accent` (teal) | ▶ filled, optional subtle pulse on the freshness dot | "Running" | active |
| `Paused-Awaiting-Input` | `--warn` (amber) | ❚❚ pause bars (rounded) | "Input" | **awaiting user input** (incl. confirmation/approval — feature-002 folds approvals into pending Q&A, so this one state covers AC3's "input" and "confirmation/decision" — they are the same FR16 state) |
| `Blocked` | `--err` (red) | ✕ / octagon | "Blocked" | **error / failure / impediment** |
| `Completed` | `--ok` (green) | ✓ check | "Done" | terminal |
| `Canceled` | `--text-dim` (grey) | ⊘ slash | "Canceled" | terminal |

The Paused and Blocked cases additionally surface their reason text (`pause_reason` /
`block_reason`) and, for Blocked, the `block_artifact` path (e.g. the IMPEDIMENT file) — read-only,
so the operator sees *why* and *where* without opening files. AC3's three-way distinction
(input vs confirmation vs error) is honored: **error/blocked** is its own red state, while
input-and-confirmation are deliberately the **same** amber state because REQUIREMENTS FR16 defines
"an approval is a kind of input — not a separate state" (and feature-002 SM-2 prio-4 derives both
from pending Q&A). The page makes blocked/paused works *jump out* (top-of-page attention strip +
colored card border), not merely listing them (FR11 "actively calls out").

> **Design note worth user attention (not a blocker):** AC3 literally lists three buckets — "waiting
> for user input", "waiting for a confirmation/decision", "error/failure". FR16 (the authoritative
> resolved requirement) collapses the first two into one `Paused-Awaiting-Input` state ("an approval
> is a kind of input"), and feature-002 derives them identically. This spec therefore renders **two**
> attention colors (amber Input / red Blocked), not three. If the operator genuinely needs to *see*
> "this is an approval gate" vs "this is an open question" as distinct visuals, that is a
> sub-distinction *within* the amber state and would require feature-001 to type the pause sub-kind
> (it does not today). Flagged for confirmation; the spec assumes the FR16 two-color reading is correct.

#### UI-5. Refresh-interval control (FR5, AC4)

A control in the top bar (numeric input or stepper, labeled "Refresh") lets the user set the polling
interval; default **5s** (FR5). Value is **clamped to [1s, 600s]** (a 0/negative value would busy-
loop and violate NFR4; an absurdly large value is harmless but bounded) and **persisted to
`localStorage`** so it survives reload. Changing it reschedules the poll loop on the next tick
(Feature Flow step 4). The current effective interval is echoed in the footer ("refreshes every Ns").

#### UI-6. Responsive + cross-browser (NFR6, NFR5)

- **Breakpoints** reuse the design family's 768px mobile collapse (`design-tokens.md` "Mobile
  breakpoint 768px (collapse grids to 1fr)"). Three target ranges: **mobile** (<768px — single
  column, stage rail becomes a horizontally-scrollable strip or vertical list, task chips stack),
  **tablet** (768–1024px — 2-col grids), **desktop** (>1024px — full grid, `max-width: 1200px`
  centered per the design tokens).
- **Cross-browser (NFR5):** Chrome/Firefox/Edge/Safari. Uses only broadly-supported primitives —
  CSS custom properties, `grid`/`flex`, `fetch`, `localStorage`, `setTimeout` — all baseline across
  the four targets for years. No bleeding-edge CSS, no runtime polyfill, no transpile. Per the global
  CLAUDE.md web-review gate, the reviewer MUST render the served page in Playwright (not inspect
  source) to validate AC1–AC3 + NFR5/NFR6 visually.

---

### Telemetry & Tracking

The dashboard *renders* feature-002's telemetry; it generates none of its own (NFR7 — no agent, and
NFR4 — no extra disk traffic beyond `read_repo`).

- **Freshness badge (NFR3, AC4):** computed from `model.read.read_at` vs the browser's wall clock and
  the last-successful-fetch time — drives the live/stale/disconnected state of the top-bar badge
  (Feature Flow error/stale handling). This is the operator's assurance that "≤ one interval behind"
  is actually holding.
- **Liveness hint (feature-002 Telemetry, KI-004):** feature-002 may expose a heartbeat-derived
  liveness freshness via `ReadMeta`; the front-end renders it as an advisory "live/stale" dot beside
  a `Running` work. Per KI-004 it is **repo-level and corroborating only** — the page never lets
  heartbeat absence demote a `Running` work to looking blocked/idle. The badge wording reflects this
  ("no recent heartbeat" ≠ "stopped").
- **`parse_warnings` surfacing:** if `model.read.parse_warnings` is non-empty (a torn read, a
  malformed STATE.md), the page shows a small non-alarming "data note" affordance rather than
  hiding it — so a transient parse glitch is visible but not mistaken for a pipeline failure.

---

### Acceptance-criteria → spec map

| AC | Requirement | Satisfied by |
|----|-------------|--------------|
| **AC1** | stages + where-we-are | UI-2 stage rail from `model.works[].phase`; full/lite path reflected by the phases present in data |
| **AC2** | current + parallel tasks, with state | UI-3 wave-grouped task chips, every concurrent task rendered side-by-side (FR14); DM-2 preserves per-task `status`/`wave` |
| **AC3** | paused/blocked distinction | UI-4 attention badges: amber Input (input+confirmation, per FR16) vs red Blocked (error/impediment), color **and** shape (FR8/FR11); reasons surfaced read-only |
| **AC4** | live update ≤ interval | Feature Flow poll loop + re-read-each-tick (NFR3); UI-5 configurable 5s default; Telemetry freshness badge proves the lag bound |
| **AC5** | local, never public | LC-S bind-`127.0.0.1` invariant (C1/C2) + closed read-only route table; remote exposure is feature-005's separate ACL layer, never this server going public |
| (cross) | NFR8 style / NFR5 browsers / NFR6 responsive | UI-1 design-family reuse; UI-6 breakpoints + baseline primitives + Playwright visual gate |
| (cross) | NFR2 read-only / NFR7 no-LLM | LC-S no-write + no-LLM invariants (grep-level self-check tests); server only calls `read_repo()` |

---

### Known issues registered by this feature

This feature consumes feature-002's `read_repo` and adds a thin server + static front-end over it.
It introduces **no new schema/contract defect**: the bind-address, no-write, and no-LLM properties
are enforced by self-check tests rather than carried as debt, and the dual-runtime divergence risk is
closed by PT-1 (parity test) as a deliverable. No new `known-issues.md` entry is warranted — KI-003
(IMPEDIMENT path) and KI-004 (heartbeat granularity) are feature-002's and this feature only renders
their already-handled results. (If, during implementation, the two runtimes prove unable to emit
byte-identical JSON for some edge value, that becomes a real KI at that time; it is not a known
defect now.)
