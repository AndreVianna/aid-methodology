# task-052 — CLI home page UI breakdown (DESIGN, authoritative for task-053)

**Type:** DESIGN (no production code modified). task-053 (IMPLEMENT the CLI home
`$AID_HOME/dashboard/index.html`, LC-HOME) implements this **verbatim**. Where this
artifact and feature-010 SPEC.md disagree on a *concrete expression*, this artifact
governs; the SPEC governs intent. They are reconciled — no disagreement is intended.

**Source of truth grounded against (read, line-cited):**
- feature-010 SPEC.md — DM-2 (`/api/home` envelope), DD-1/DD-2, UI-H1..UI-H4, FF-3 (poll loop),
  CLI-2 (`--target` residual), residual #2.
- task-048-registry-contract.md — §3.1 (`repos[].id` is opaque, never re-derived client-side),
  §3.3 (`/r/<id>/<leaf>` grammar), §6 (053's consumer row: link by minted `id`, never re-hash,
  never render raw path/id as a title).
- `dashboard/index.html` — the DELIVERED per-repo page. The **visual donor** for the whole
  CLI home: shell (head/top-bar/footer), poll loop, `.card.plugin` machine panel, `.card.card-link`
  whole-card click, badges, grid, Canceled (`⊘`) vocabulary, empty-state. Concrete line refs below.

This breakdown is **component-by-component** with the exact `/api/home` field→DOM mapping and
the donor line refs so task-053 reuses the delivered shell rather than reinventing it.

---

## 0. What is reused wholesale vs. what is new

task-053 produces a **new** `index.html` that is a **sibling** of the delivered per-repo page,
not a fork of it. The reused pieces are **copied** from `dashboard/index.html` at the cited lines
(the design family / `knowledge-summary` assets, NFR8); the page-specific render is new.

| Reuse class | Donor (`dashboard/index.html`) | What task-053 does |
|---|---|---|
| **`<head>` + `meta robots noindex` + color-scheme** | lines **1-9** (`<!DOCTYPE>` … `<meta name="robots" content="noindex">` … `<title>` … `<style>`) | copy verbatim; only `<title>`/brand text changes (§1) |
| **Whole CSS block** (color tokens, `.top-bar`, `.badge*`, `.grid`/`.g2`/`.g3`, `.card`, `.card.plugin`, `.card-link`, `.empty-state`, responsive `@media`, print, a11y) | lines **9-747** | copy verbatim; the machine panel + repo cards consume these classes unchanged. No new CSS primitives. |
| **Skip-link + sticky top-bar shell** | lines **751-779** | copy; retarget brand text (§1) |
| **Footer "served locally / read-only / refreshes every Ns / via <runtime>"** | lines **886-890** | copy verbatim |
| **`<noscript>` fallback** | lines **892-898** | copy verbatim |
| **Boot + interval control + theme + poll loop** (`boot()`, `clampInterval`, `onIntervalChange`, `updateFooterInterval`, `scheduleNextPoll`, `doFetch`, single-in-flight guard, error backoff, `onError` keep-last-good, freshness badge, schema-mismatch banner) | lines **900-1062** + banner markup **784-788** | copy verbatim; change ONLY the fetch URL `'/api/model'`→`'/api/home'` (line **1010**) and the success/render entry (§4) |
| **`.card.plugin` machine panel markup + `dl/dt/dd` rhythm** | CSS **516-524**; donor render `_renderLevel0Card` **1589-1660** | adapt to the THREE machine fields (§2) — NOT the donor's version/installed/tools triple |
| **`.card.card-link` whole-card click pattern** | render **1404-1407** (`<a class="card card-link" href=…>`); CSS **513-514** | apply to available repo cards (§3) |
| **Canceled `⊘` + `badge-dim` muted vocabulary (UI-4)** | **2432** / **2456** (`'Canceled': { cls:'badge-dim', glyph:'⊘', word:'Canceled' }`) | reuse glyph + `badge-dim` for the **unavailable** repo card (§5) |
| **Empty-state primitive** | CSS `.empty-state` **731-736**; donor `_renderEmptyState` pattern **1662-1690** | reuse for the empty-registry state (§5) |

> **Schema constant.** The donor pins `var EXPECTED_SCHEMA_VERSION = 3;` (line **907**) for
> `/api/model`. The CLI home polls `/api/home`, whose **`schema_version` is independent** (DM-2:
> "int; CLI-home wire shape version (independent of /api/model's)") and is **`1`** at ship. task-053
> sets `var EXPECTED_HOME_SCHEMA = 1;` and gates the success handler on `envelope.schema_version !== 1`
> reusing the donor's schema-mismatch banner (markup **784-788**, handler **1031-1038**). Do NOT copy
> the `3`.

---

## 1. UI-H1a — Page shell (reuse feature-003 UI-1)

Reuse the donor shell verbatim with these text-only retargets:

| Element | Donor | CLI-home value |
|---|---|---|
| `<title id="page-title">` | `AID Dashboard` (line **8**) | `AID — this machine` |
| `.brand` strong + dot suffix | `<strong id="brand-name">AID Dashboard</strong><span class="dot">·</span>Pipeline` (**757**) | `<strong>AID</strong><span class="dot">·</span>this machine` — **static text, no `brand-name` substitution.** The donor swaps `brand-name` to the repo's project name at render (line **1177-1178**); the CLI home brand is **fixed "AID — this machine"** (machine scope, not a repo name). Drop the `id="brand-name"` and its render-time set. |
| freshness badge | `<span class="badge badge-dim" id="freshness-badge">` (**764**) | keep verbatim (drives off `/api/home` read freshness) |
| interval control | **766-771** | keep verbatim |
| theme toggle | **772-777** | keep verbatim |
| footer | **886-890** | keep verbatim ("served locally by `aid dashboard` · read-only · refreshes every Ns · via <runtime>") |

Keep `meta robots noindex` (**7**), the skip-link (**752**), the `<noscript>` fallback (**892-898**),
and the print/`a11y` CSS. No new shell chrome.

---

## 2. UI-H1b — Machine panel (the relocated Level-0 `.card.plugin`)

A single `.card.plugin` card directly under the top-bar, rendered from `envelope.machine`. It reuses
the donor's `.card.plugin` CSS (**516-524**: `dl` two-column grid, `dt` `--text-dim`, monospace
`.plugin-name`) and the `_renderLevel0Card` shape (**1589-1660**) — but renders **exactly THREE**
parity-stable fields, NOT the donor's version/installed/tools triple.

**Kicker:** reuse the donor's `'AID CLI (this machine)'` kicker text (donor line **1596**).

**`/api/home` `machine.*` field → DOM mapping (exactly three `dt`/`dd` rows, in this order):**

| # | `dt` label | source field | `dd` render | null / empty handling |
|---|---|---|---|---|
| 1 | `version` | `machine.aid_version` (string\|null) | a `<span class="badge badge-info">` chip with the version (mirrors donor **1614-1621**) | **null → the literal text `CLI version unavailable`** (UI-H1; NOT an em-dash, NOT an error — this is the explicit parity-stable copy the SPEC pins, SPEC.md:641-643) |
| 2 | `install location` | `machine.aid_home` (string) | the path as plain text in the `dd` (monospace-friendly; reuse `.plugin-name` styling or plain `dd`) | always present (FR7 "install location"); if somehow empty, em-dash `—` |
| 3 | `tool catalog` | `machine.tools_catalog` (list<string>) | one `badge badge-dim` chip per tool (mirrors donor tools loop **1644-1655**, `marginRight:0.25rem`) | empty list → em-dash `—` |

**NOT rendered — state explicitly:**
- **`machine.cli_runtime` is NOT rendered.** It is an internal runtime echo (like envelope
  `generated_by`), diagnostic-only and **excluded from PT-1 parity** (DM-2; SEC-5 parity-excluded
  set `{generated_by, machine.cli_runtime, read.read_at}`). The operator-facing panel carries ONLY the
  three fields above. (`machine.registry_path` is operator-awareness metadata; the panel MAY show it as
  a quiet footnote line but it is **not** one of the three required fields and is **not** required.
  task-053 may render it as a `.meta` line under the `dl` or omit it — recommended: a single quiet
  `.meta` line `registry: <registry_path>` for operator awareness, since it is not parity-excluded and
  is cheap. This is advisory, not a gate.)
- **Per-repo installed tools are NOT in this panel.** FR7/FR33 "installed tools" is realized
  **machine-scoped as `tools_catalog` here** (the manageable-tool catalog), and **per-repo on each repo
  card** as `repos[].tools_installed` (§3). The machine panel never shows a per-repo install. This is
  the FR7/FR33 reconciliation the SPEC pins (SPEC.md:638-640).

**Donor-divergence note for 053:** the donor `_renderLevel0Card` renders `version`/`installed`/`tools`
off a per-repo `tool` manifest object (`tool.aid_version`, `tool.installed_at`, `tool.tools_installed`).
The CLI home renders off `envelope.machine` instead, and its three rows are
`version`/`install location`/`tool catalog` — there is **no `installed`/`installed_at` row** on the
machine panel (that is a per-repo concept). Reuse the donor's `dl`/`dt`/`dd` + badge-chip *mechanics*,
not its field list.

---

## 3. UI-H2 — Registered-repo card grid

A responsive grid of one `.card` per `repos[]` entry, under the machine panel. Reuse the donor grid
classes (`.grid.g2` / `.grid.g3`, CSS **177-187**) — recommend **`.grid.g2`** (the donor's main-page
section grid, line **861**) for repo cards (each card carries name + description + chips, so the wider
380px-min `g2` track reads better than `g3`). A section heading `<h2 class="main-section-head">Repos</h2>`
(reuse `.main-section-head`, CSS **526-527**, donor usage **860**) precedes the grid.

### 3.1 Available card (`available === true`)

The **whole card is the click target** → `/r/<id>/home.html` (FR27 navigation). Use the donor's
whole-card-clickable pattern: an `<a class="card card-link">` element (donor **1404-1407**; CSS
`.card-link` **513-514** neutralizes anchor styling), `href = '/r/' + repo.id + '/home.html'`.

> **`repo.id` is OPAQUE (task-048 §3.1/§6).** task-053 uses `repos[].id` from `/api/home`
> **verbatim** to build the href. It MUST NOT re-hash the path client-side and MUST NOT construct
> the URL from `repo.path`. The server minted the id (possibly collision-lengthened, task-048 §3.5);
> the page just links by it.

**`repos[].*` field → DOM mapping (available card):**

| Slot | source field | render | fallback / null |
|---|---|---|---|
| **title** (`<h3>`, reuse `.card h3` **199**) | `repo.name` (string\|null) | the display name | **null → the folder basename of `repo.path`** (last `/`-segment). **NEVER render `repo.path` or `repo.id` as the title** (feature-009 FR25 discipline; task-048 §6 "must NOT render the raw path/id as a card title"). If even the basename is empty (root path), fall back to the em-dash `—` rather than the raw path. |
| **description** (`<p class="meta">`, reuse `.card .meta` **202**) | `repo.description` (string\|null) | the description text | **null → em-dash `—`** (feature-009 FR25 placeholder) |
| **version chip** | `repo.aid_version` (string\|null) | `<span class="badge badge-info">` with the version (mirror **1614-1621**) | null → omit the chip (no em-dash chip) |
| **tools chips** | `repo.tools_installed` (list<string>) | one `badge badge-dim` chip per tool (mirror **1644-1655**) — this is the **per-repo installed tools**, FR7/FR33 homed on the card | empty list **OR manifest absent** → **omit the chip row entirely** (no `—`; "omitted when manifest absent", UI-H2) |
| **KB affordance** | `repo.has_kb` (bool) | when `true`, a small `<span class="badge badge-purple">KB</span>` (or a quiet `.meta` "KB" link) — advisory only; the card already navigates to `home.html` | `false` → omit |

> **`has_kb` is advisory, not a second click target.** The whole card navigates to `/r/<id>/home.html`.
> The "KB" affordance is a visual hint that the repo has a `kb.html`; task-053 SHOULD render it as a
> non-interactive chip inside the card (nesting a second `<a>` inside the card `<a>` is invalid HTML).
> The repo's own `home.html` links onward to its `kb.html`; the CLI home need not deep-link `kb.html`.

### 3.2 Generated-but-not-yet card (`available === true` AND `has_home === false`)

A registered, reachable repo that has **no `home.html` yet** (e.g. `aid summarize`/`aid discover` not
yet run). Render a **non-clickable** card (a plain `<div class="card">`, NOT an `<a class="card-link">`)
with the same name/description/version/tools slots as §3.1, plus a quiet `.meta` note:
**`dashboard not generated yet`** (UI-H2). This is **not** a dead link — there is no `href`, so the card
does not navigate. (Rationale: linking to a `/r/<id>/home.html` that 404s would be a dead link; the
note tells the operator why the card is inert and what is missing.)

### 3.3 Sort order

The model sorts `repos` by `path` ascending for determinism (DM-2, PT-1). task-053 **MAY re-sort by
display name** (the §3.1 title: `name` or basename) client-side for a friendlier reading order (UI-H2:
"the renderer may re-sort by display name client-side"). Use a stable, case-insensitive compare on the
resolved display name. This is presentation-only and does not affect the wire contract.

---

## 4. Render entry-point (wiring the reused poll loop)

The reused `doFetch()` (donor **1003-1029**) calls `fetch('/api/model')`; task-053 changes line **1010**
to `fetch('/api/home')`. The reused `onSuccess(envelope)` (donor **1031-1050**) is adapted:

1. Schema gate: `if (envelope.schema_version !== EXPECTED_HOME_SCHEMA) { showSchemaMismatch(); return; }`
   (reuse the donor banner, §0).
2. Footer runtime: `footer-generated-by` ← `'via ' + envelope.generated_by` (reuse donor **1043-1046**;
   `generated_by` is the envelope-level diagnostic — fine to show in the footer, it is the same echo the
   per-repo page shows).
3. `renderMachinePanel(envelope.machine)` (§2) — into a fixed container `<div id="machine-panel">`.
4. `renderRepoGrid(envelope.repos)` (§3 + §5) — into `<div class="grid g2" id="repo-grid">`.
5. `updateFreshnessBadge('live', envelope.read && envelope.read.read_at)` — reuse the donor freshness
   badge (**1067-…**); `read.read_at` drives the stale/live computation exactly as the per-repo page
   uses the model's read time.

Keep the donor's keep-last-good `onError` (**1052-1062**), single-in-flight guard, and error backoff
**verbatim** — never blank the page; show "Reconnecting" on error (donor **1071-1074**).

The `repo_count` / `unavailable_count` from `envelope.read` MAY drive a quiet header count line
(e.g. `2 repos · 0 unavailable`) but this is advisory, not required.

---

## 5. UI-H3 — Unavailable cards + prune offer + empty-state

### 5.1 Unavailable card (`available === false`)

A registered path whose `.aid/` is gone (moved/deleted, NFR10). Render a **muted, non-clickable**
card (plain `<div class="card">`, never an `<a>`) using the donor's **Canceled vocabulary (UI-4)**:
the `⊘` glyph and `badge-dim` muted treatment (donor **2432**/**2456**:
`'Canceled': { cls:'badge-dim', glyph:'⊘', word:'Canceled' }`). Apply `color: var(--text-dim)` to the
card body for the greyed look.

**Render:**
- A status chip/glyph: `<span class="badge badge-dim">⊘ unavailable</span>`.
- The registered **`repo.path`** shown as plain (monospace-friendly) text — here it is correct to show
  the path, because the repo can't be named (its `.aid/settings.yml` is gone) and the operator needs the
  path to prune it. (This is NOT the §3.1 "never render path as a title" case — that rule is about the
  *title slot of an available, nameable* card; an unavailable card has no name to show and the path IS
  the actionable identifier.)
- A **prune offer = step-by-step FR18 guidance**, NOT a write button (NFR2; MEMORY
  "ask-user-over-auto-proof"). Render it as a quiet expandable/inline `.meta` block giving the exact
  command and verification, e.g.:
  > This repo's folder is gone. To remove it from the CLI home:
  > 1. Run `aid remove --target <repo.path>` (unregisters the now-toolless repo).
  > 2. Verify: this card disappears on the next refresh (within the poll interval).

  Substitute the literal `repo.path` into the `aid remove --target …` line. The page **issues no
  write and renders no button that mutates anything** — it is read-only (NFR2). This mirrors the
  donor's FR18 step-by-step `_renderEmptyState` pattern (**1662-1690**: kicker + intro + `<ol>` with
  a `<code>` command step + a "Verify:" step).

### 5.2 Empty registry (`repos` is `[]`)

When the registry is absent/empty (`envelope.repos.length === 0`), render a friendly empty-state
(reuse the `.empty-state` primitive, CSS **731-736**; donor `_renderEmptyState` shape **1662-1690**),
**never** a blank page or an error:

> **No repos registered yet** — run `aid add <tool>` in a repo to see it here.

Wrap the command in `<code>`. The machine panel (§2) still renders above the empty-state (the machine
info is independent of whether any repo is registered). This is the FR18 friendly empty-state UI-H3 pins.

---

## 6. UI-H4 — Responsive + cross-browser

Reuse feature-003 UI-6 **verbatim** via the donor CSS — no new media queries:
- **768px single-column collapse:** donor `@media (max-width: 768px)` (**243-251**) already sets
  `.grid, .grid.g2, .grid.g3 { grid-template-columns: 1fr; }` — the repo grid collapses to one column.
- **2-col tablet:** donor `@media (min-width: 769px) and (max-width: 1024px)` (**239-241**) gives
  `.grid.g3` two columns; `.grid.g2` is `auto-fit minmax(380px,…)` so it naturally reflows to 1–2 cols
  on a tablet. (If task-053 wants a guaranteed 2-col tablet for the repo grid, use `.grid.g3`; either
  is contract-valid.)
- **Desktop max-width:** `main { max-width: 1200px }` (**147-148**).
- **Extra-narrow / print / a11y:** donor **253-263**, **265-…** reused as-is.

**Baseline primitives only** (CSS custom properties, grid/flex, `fetch`, `localStorage`, `setTimeout`).
**No CDN, no web-font at runtime** — the donor ships system fonts inline and no external asset; task-053
inherits that. Per the global CLAUDE.md web-review gate, the reviewer MUST render the served CLI home in
**Playwright** (machine panel + repo grid + unavailable card + empty-state + dark theme + responsive
reflow + a navigation click into a repo's `home.html`) — source inspection is an automatic fail.

---

## 7. Residual #2 — `aid dashboard --target` residual meaning — RESOLVED

**DECISION: option (a) — auto-register + deep-link the cwd repo's `/r/<id>/home.html` on open.**

When `aid dashboard [start] --target <dir>` (default cwd) is run, the launcher:
1. Resolves `<dir>` via **CAN-1** (`cd && pwd`, no `-P`; task-048 §2) — the same canonicalization the
   `--target` already applies.
2. **Auto-registers** that repo if it is not already in `$AID_HOME/registry.yml` (consumed by
   **task-049** — the same `registry_register(CAN-1(<repo>))` side-effect, idempotent set-insert; this
   is the "register side-effect" task-049 owns, reused here at the dashboard-launch seam, not a new
   writer).
3. **Deep-links** the browser to that repo's per-repo page by opening
   `/r/<id>/home.html` (id = the server-minted opaque id for the CAN-1 path, task-048 §3.1) **instead
   of** the bare `/`. The CLI home at `/` remains fully reachable (the user can navigate "up" to it).

**Rationale:**
- **Preserves the established ergonomic.** `aid dashboard` historically operated on the cwd repo
  ("run it in my repo, see my repo"). A machine-level server changes *what is served* (the whole
  registry) but operators still expect `cd my-repo && aid dashboard` to land them on *their* repo, not
  a machine index they then have to click through. Option (a) keeps that muscle memory.
- **Auto-register is the natural superset of the registry side-effect.** A repo you launch the
  dashboard in is a repo you manage; registering it on launch is consistent with FR29's "registered as
  a side-effect of the commands you already run" philosophy, and it is idempotent (no-op if already
  registered), so it never surprises. It also guarantees the deep-link target exists in the registry
  (the `<id>` resolves) — option (b) would risk deep-linking a repo the server can't route.
- **`/` stays the home.** Deep-linking does not hide the CLI home; it just chooses the initial landing
  page. A repo with no `home.html` yet (`has_home=false`) deep-links to `/r/<id>/home.html`, which the
  server 404s — in that case the launcher SHOULD fall back to opening `/` (the CLI home), where the
  repo shows as a §3.2 "dashboard not generated yet" card. task-049 owns this fallback ordering.
- **Read-only posture intact.** The only write is the registry side-effect (task-049's existing
  `registry_register`, atomic temp-file-rename, WARN-and-continue on failure) — the server and page
  remain read-only (NFR2). A failed auto-register degrades to "land on `/`", never a failed launch.

**Option (b) (no-op-with-note) rejected** because it strands the historical `aid dashboard --target`
ergonomic: an operator who runs the command in their repo would land on a machine index with no special
relationship to their cwd, and a freshly-`add`ed repo they want to inspect would not even appear unless
separately added — a worse first-run experience for the common single-repo case.

**Consumers of this decision:**
- **task-049** (registry side-effect / writer): implements the launch-time `registry_register(CAN-1(cwd))`
  auto-register + the deep-link target selection + the `has_home=false` → fall-back-to-`/` ordering.
- **task-055** (`--remote`): `--remote` exposes the **CLI home** (OQ5, all registered repos). When
  `--target` and `--remote` are combined, the remote grantee still lands on the CLI home `/` (the
  exposed surface is the machine home); the local-launch deep-link convenience (open `/r/<id>/home.html`
  in the *local* operator's browser) is a local-open affordance and does not change *what is exposed*
  over the tailnet. task-055 keeps the feature-005 expose/teardown unchanged; only the local browser-open
  target is affected by this decision.

---

## 8. Acceptance-criteria → section map (for task-053 and the reviewer)

| task-052 AC | Satisfied by |
|---|---|
| UI-H1..UI-H4 grounded in delivered family + `index.html` line refs, concrete enough to implement without re-deciding | §0 reuse table (donor line refs), §1 shell, §2 machine panel, §3 grid, §5 unavailable/empty, §6 responsive |
| Machine panel = exactly three parity-stable fields; `cli_runtime` explicitly NOT rendered; per-repo tools on cards not panel | §2 (three-row table + "NOT rendered" block + FR7/FR33 reconciliation) |
| Repo card never renders raw path/id as title; em-dash null description; whole-card → `/r/<id>/home.html`; `has_home=false` non-clickable note; `has_kb` affordance | §3.1 mapping table, §3.2, §3.3 (opaque `id`, basename fallback) |
| Unavailable/prune is guidance-only (no write, NFR2/FR18); empty-registry empty-state specified | §5.1 (FR18 step-by-step, no button), §5.2 (friendly empty-state) |
| Residual #2 resolved with recommended option + rationale, consumed by task-049/task-055 | §7 (option (a), rationale, consumers) |
| No production code modified (DESIGN) | this artifact only; no edits to `dashboard/` or `bin/aid` |
