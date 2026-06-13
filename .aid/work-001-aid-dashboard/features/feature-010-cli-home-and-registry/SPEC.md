# CLI Home + Repo Registry + Multi-Repo Server Routing (Machine Level)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-12 | Feature created from the two-level dashboard re-architecture — REQUIREMENTS.md §5 FR27, FR28, FR29, FR30, FR33 (receive half), FR36 (`bin/aid` half) | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR7 (Level-0 CLI info — now rendered on the CLI home, relocated via FR33)
- REQUIREMENTS.md §5 FR27 (two-level dashboard — Level A CLI home: machine/CLI info + registered-repo list)
- REQUIREMENTS.md §5 FR28 (machine-level repo registry — `$AID_HOME/registry.yml`, paths-only, the CLI install's own registry)
- REQUIREMENTS.md §5 FR29 (registry maintained as a side-effect of `aid add` / `aid remove` — OQ6 RESOLVED)
- REQUIREMENTS.md §5 FR30 (multi-repo server routing — `/`, per-repo `home.html`/`kb.html`/`/api/model`; contract-level change to feature-003's delivered server)
- REQUIREMENTS.md §5 FR33 (Level-0 CLI panel relocation — this feature is the **receiving** page)
- REQUIREMENTS.md §5 FR36 (producer-skill changes — the `bin/aid` registry side-effect + routing half)
- REQUIREMENTS.md §6 NFR9 (multi-root read-only scoping), NFR10 (stale-registry tolerance), NFR11 (co-located artifacts)
- REQUIREMENTS.md §7 C6 (multi-root read-only + no path traversal; preserve feature-003 server invariants), C7 (dogfood-rendered producers)
- REQUIREMENTS.md §8 OQ5 (RESOLVED: `--remote` exposes the CLI home — all registered repos — owned here, with feature-005/C3)
- REQUIREMENTS.md §8 OQ6 (RESOLVED: registry maintenance is a side-effect of `aid add` / `aid remove` — no new verb)
- REQUIREMENTS.md §3a (Level-0 machine scope), §4 (per-repo independence — navigation, not aggregation)

## Description

The **machine/CLI level** of the two-level dashboard. AID's CLI is installed **once per machine** but
spans **many** repos; this feature gives that global tool a **home page**. It introduces three tightly
coupled pieces:

1. **A machine-level repo registry** — a new **`$AID_HOME/registry.yml`** (default
   `~/.aid/registry.yml`) holding **only the list of registered repo base folders** (paths). This is the
   **CLI install's own registry of the repos it manages** — *not* a per-repo project artifact: `~/.aid/`
   is `AID_HOME`, the installed CLI tree (`bin/`, `lib/`, `VERSION`), and the registry is a new file
   inside it, distinct from any repo's `.aid/settings.yml`. (A full uninstall — `aid remove self`,
   `rm -rf $AID_HOME` — removes the registry too; that is acceptable, it is rebuilt by re-adding repos.)
   Per-repo name/description/version are **not** duplicated here; they are read from each repo's own
   `.aid/settings.yml` at render time. Maintained as a **side-effect of the existing `aid add` /
   `aid remove`** (OQ6 RESOLVED, 2026-06-12 — **no new verb**): those commands keep their host-tool
   install/uninstall behavior unchanged and **also** keep the registry in sync — a repo is registered on
   its **first** tool added and unregistered on its **last** tool removed. These are the only writers of
   the registry. This is additive, not an overload.
2. **A multi-repo-aware server (a contract-level change to feature-003's delivered server)** — the
   existing one-server-per-CLI-install becomes multi-repo aware. ⚠️ This is **not** a mere routing
   extension: feature-003 already **delivered** a **CLOSED two-route allowlist** server (`/` +
   `/api/model`, single `--root`). This feature **replaces that closed allowlist with a NEW explicit
   closed allowlist**: `/` (CLI home `index.html`) plus, for **each registered repo** (resolved via the
   registry), that repo's **`home.html`**, **`kb.html`**, and its **`/api/model`** (feature-002
   `read_repo` against that repo's root). It must **preserve feature-003's hard invariants** — loopback
   bind / local-only (C1/C2), no-write (NFR2), no-LLM (NFR7) — serve files **only** from registered
   repos' `.aid/dashboard/`, fixed filenames, **no path traversal** (C6), and **extend feature-003's
   PT-1 cross-runtime parity + no-write self-checks to the multi-repo shape**. The blast radius on the
   delivered feature-003 server is explicit (C6).
3. **The CLI home page** — `<CLI install>/dashboard/index.html` shows the **machine/CLI info** panel
   (version, install location, and the CLI's manageable-tool **catalog** — the machine-scoped Level-0
   panel **relocated** here from the per-repo page, FR33; per-repo *installed* tools live on the repo
   cards, where they belong) plus the **list of registered repos** as **repo-cards** that link to each
   repo's `home.html`. A moved/deleted registered repo renders as **"unavailable"** with an offer to
   prune — never an error (NFR10).

This is **navigation, not aggregation**: the CLI home enumerates repos, but each repo's pipeline data
stays independent and is never blended (FR9 preserved). It is the new entry point **above** the
per-repo `home.html` (feature-006).

## User Stories

- As an **operator** who runs AID across several repos on one machine, I want a single CLI home that
  lists all my registered repos and the machine's AID version/tools, so I can pick a repo to monitor
  from one place.
- As an **operator**, I want my existing `aid add` / `aid remove` to **also** register/unregister a
  repo folder **as a side-effect** (a repo is registered on its first tool added, unregistered on its
  last tool removed — their host-tool install/uninstall behavior is unchanged), so the CLI home reflects
  exactly the repos I care about without learning a new verb (OQ6 RESOLVED).
- As an **operator** whose repo was moved or deleted, I want its card shown as "unavailable" with a
  prune offer, so the home page never breaks and I can clean it up.

## Priority

**Must** (this is the spine of the two-level refactor — feature-006's per-repo `home.html` and
feature-007's per-repo `kb.html` are reached *through* this home + server).

## Owned Requirements

- **FR7** (Level-0 CLI info — the machine version/install-location panel; "installed tools" is realized
  machine-scoped as the CLI's manageable-tool **catalog** in the panel, and per-repo as each repo card's
  installed-tools chips — see DM-2/UI-H1/UI-H2 reconciliation; it **renders here on the CLI home** now,
  relocated from the per-repo page via FR33), **FR27** (two-level dashboard —
  Level A: CLI home), **FR28** (repo registry — `$AID_HOME/registry.yml`), **FR29** (registry
  maintained as a side-effect of `aid add` / `aid remove`), **FR30** (multi-repo server routing — a
  contract-level change to feature-003's delivered closed two-route server), **FR33** (Level-0 panel
  relocation — the **receiving** CLI home; the *removal* from the per-repo page is owned by
  feature-006), **FR36** (the **`bin/aid`** registry-side-effect + routing portion only; the
  summarize/discover/housekeep portion is owned by feature-007).
- **NFR9** (multi-root read-only scoping), **NFR10** (stale-registry tolerance), **NFR11**
  (co-located per-repo artifacts — this feature defines the registry/`$AID_HOME` scope half).
- **C6** (multi-root read-only + no path traversal; preserve feature-003's delivered server invariants
  + extend PT-1), **C7** (dogfood-rendered — note: `bin/aid`/`bin/aid.ps1` are **hand-maintained**, NOT
  `canonical/`-render artifacts, so C7's dogfood-render rule does **not** apply to them; their gates are
  ASCII-only + Bash↔PowerShell parity + vendored-copy refresh, CLI-1. The registry side-effect is
  behavior-additive, leaving `aid add`/`aid remove` host-tool behavior unchanged).
- **OQ5** (RESOLVED 2026-06-12: `--remote` exposes the **CLI home — all registered repos**;
  tailnet-private/never-public/host-user-ACL-scoped per NFR1/C1/C3, the repo list exposed to *granted*
  identities is an accepted trade-off) — resolved here in concert with feature-005 (C3).
- **OQ6** (RESOLVED 2026-06-12: registry maintenance is a **side-effect of `aid add` / `aid remove`** —
  no new verb, no change to host-tool install/uninstall behavior; additive, C4/C7 preserved).

## Acceptance Criteria

- [ ] Given a machine with `aid` installed, when I `aid add` the first tool to a repo then
      `aid remove` its last tool, then `$AID_HOME/registry.yml` (default `~/.aid/registry.yml`) gains
      then loses that repo's base path **as a side-effect**, contains **only** paths (no
      name/description/version duplicated), and the existing `aid add`/`aid remove` **host-tool**
      install/uninstall behavior is **unchanged** (FR28, FR29, OQ6 RESOLVED, C4/C7).
- [ ] Given one or more registered repos, when I open the CLI home `index.html`, then I see the
      **machine/CLI info** panel (version, install location, and the CLI's manageable-tool **catalog**
      — the machine-scoped realization of FR7/FR33 "installed tools") and a **repo-card per registered
      repo** whose name/description/version **and that repo's installed tools** are read from that
      repo's own `.aid/settings.yml` + `.aid/.aid-manifest.json` (per-repo installed tools home here,
      not in the machine panel), and clicking a repo-card opens that repo's `home.html` (FR7, FR27, FR30, FR33).
- [ ] Given the multi-repo server is running (the NEW closed allowlist replacing feature-003's
      delivered `/` + `/api/model` two-route server), when a browser requests `/`, a registered repo's
      `home.html`/`kb.html`, or that repo's `/api/model`, then each is served correctly, and any
      unregistered path or path-traversal attempt (`..`, symlink escape, absolute injection, arbitrary
      `.aid/` content) is **refused**; feature-003's hard invariants (loopback bind, no-write, no-LLM)
      hold and its **PT-1 parity + no-write self-checks are extended to the multi-repo shape**
      (FR30, C6, NFR9).
- [ ] Given a registered repo that has been moved/deleted, when I open the CLI home, then its card
      shows **"unavailable"** with a prune offer, and **no** other repo's view or the server errors
      (NFR10).
- [ ] Given the read-only posture, when the server serves N registered roots, then it **writes to
      none** of them (NFR2/NFR9), binds local-only (C1/C2), and the **hand-maintained** `bin/aid` /
      `bin/aid.ps1` registry edits pass their applicable gates — **ASCII-only**
      (`test-ascii-only.sh`), **Bash↔PowerShell parity** (`test-aid-cli-parity.sh`), and
      **vendored-copy refresh** (`vendor.js` / `vendor.py`) — `bin/aid` being hand-maintained, NOT
      render-drift / `run_generator.py` (C7 governs the `canonical/`-rendered producers, not
      `bin/aid`).

## Decomposition Rationale (one feature, not three)

> _Recorded for /aid-plan. Reviewed for over/under-splitting._

The registry, the multi-repo server routing, and the CLI home **page** were considered as up to three
features. They are kept as **one** because they form a single thin vertical slice with no useful
standalone sub-deliverable: the page is meaningless without the server, the server's routing is
meaningless without the registry it resolves against, and the registry has no consumer until the page
exists. Splitting them would manufacture cross-feature dependencies on a small surface (one new yml
file, one server-routing change, one new static page + a relocated panel) and three coordination seams
where one suffices. The producer split is instead drawn along the **domain** boundary: machine/registry/
server producers (`bin/aid`) live here; KB-domain producers (`aid-summarize`/`aid-discover`/
`aid-housekeep`) and the reader's KB-status/git-read live in feature-007. This keeps every FR27–FR36
requirement owned exactly once with no homeless cross-cutting "reader/producer" feature.

---

## Technical Specification

> Added by `/aid-specify`. Do not fill during interview.
> The sections below are determined by Specify based on KB, codebase, and developer discussion.
> Resolved at interview (2026-06-12): OQ5 (`--remote` exposes the CLI home — all registered repos) and
> OQ6 (registry maintenance is a side-effect of `aid add` / `aid remove` — no new verb) are **decided**;
> they are no longer open for /aid-specify.
> Open decisions to resolve at /aid-specify: exact `$AID_HOME/registry.yml` schema; the `aid add` /
> `aid remove` registry side-effect mechanics (first-tool-add registers / last-tool-remove unregisters);
> server-routing path-resolution + traversal-refusal mechanism for the NEW closed allowlist that replaces
> feature-003's delivered two-route server (and the matching PT-1 + no-write self-check extension);
> CLI-home `index.html` location relative to the existing `dashboard/` shared-app folder and how the
> machine/CLI manifest is read; PowerShell-twin parity for the `aid add`/`aid remove` registry side-effect.

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the
> `$AID_HOME/registry.yml` schema + the CLI-home machine-model / `/api/home` model — the serialized
> repo-list the CLI home polls), **Feature Flow** (the three runtime cycles: the `aid add`/`aid remove`
> registry side-effect; the multi-repo server request→registry-resolution→route cycle; the CLI-home
> poll loop), **Layers & Components** (registry I/O = `LC-REG`; the multi-repo server rewrite =
> `LC-MS`; the CLI-home page = `LC-HOME`; the dual-runtime split). Conditional: **CLI / Command spec**
> (REQUIRED — the `aid add`/`aid remove` registry side-effect grammar/semantics + the unchanged
> `aid dashboard` start/stop now serving the CLI home), **API Contracts** (REQUIRED — the
> NEW closed allowlist replacing feature-003's two-route server: route shapes, repo addressing, the
> `/api/home` machine endpoint, exit/refusal codes), **UI Specs** (REQUIRED by FR7/FR27/NFR6/NFR8 —
> the CLI home page: relocated Level-0 panel + repo-card grid + unavailable/stale rendering), **Security
> Specs** (REQUIRED — multi-root read-only scoping, no-traversal refusal, the loopback-bind/no-write/
> no-LLM invariants extended to N roots, the `--remote` repo-list-to-grantees note, the PT-1 +
> self-check extension). **Skipped:** **State Machines** (none new — the registry has only a
> present/absent path and an availability display state, both trivial enough to live in Feature Flow;
> the FR16 lifecycle stays feature-002's, unchanged by this feature), **Migration Plan** (no data
> migration — the registry is **derived** state, rebuilt by re-adding repos per FR28; there is nothing
> to migrate, an absent registry is simply empty), **Telemetry** (none generated — the CLI home renders
> feature-002's read-only model and a directory `stat`; NFR7), **BDD Scenarios** (the acceptance
> criteria + the FF-1/FF-2/FF-3 flow walkthroughs + the PT-1-H/SEC self-check tests already express the
> behavioral contract concretely; a separate Gherkin layer would only restate them), **Recovery
> Management** (no transactional/rollback recovery surface — the only write is the registry's
> atomic temp-file-rename (DD-3), which is failure-atomic by construction, and a failed registry sync
> degrades to "not listed until next add" per NFR10, not a recovery procedure), **External
> Integrations** (none — zero third-party deps, stdlib/built-ins only, no network egress; `--remote`
> reuses feature-005's existing Tailscale layer unchanged and is not a new integration owned here),
> **Events & Messaging / CQRS / DDD / Cache / Batch / Mobile-native / Search / AI / Cloud / Hardware**
> (not applicable to a paths-only registry + a thin static server).

OQ5 and OQ6 are **RESOLVED** at interview (2026-06-12) and baked into this spec; they are not re-opened.
This feature is the **machine/CLI tier** of the two-level dashboard and the spine the per-repo features
(006 `home.html`, 007 `kb.html`) are reached *through*. Three tightly-coupled deliverables (DR-1 the
registry, DR-2 the multi-repo server, DR-3 the CLI home page) ship together; the `--remote` change
(DR-4) is a serving-scope adjustment layered over feature-005's unchanged mechanism. Everything at
runtime is **deterministic code with no agent/LLM** (NFR7) and **writes to no registered repo** (NFR2/
NFR9); the registry is written **only** by `aid add`/`aid remove` (DR-1), never by the server or the page.

---

### Data Model

No relational schema — AID ships no database (`schemas.md`). This feature defines **two** data shapes:
(a) the on-disk **`$AID_HOME/registry.yml`** registry file (DM-1), and (b) the on-the-wire **CLI-home
model** the home page polls (DM-2). It introduces **no** change to feature-002's `RepoModel` — the
per-repo `/api/model` envelope (feature-003 DM-1) is reused verbatim, once per registered repo.

#### DM-1. `$AID_HOME/registry.yml` — the machine repo registry (FR28)

| Property | Value |
|----------|-------|
| **Path** | `$AID_HOME/registry.yml` — default `~/.aid/registry.yml`. `$AID_HOME` is resolved by the CLI exactly as `bin/aid` already resolves it (`bin/aid:40-47`: real-path of `bin/aid` → `dirname/dirname`; env override `AID_HOME`; fallback `${HOME}/.aid`). The PowerShell twin resolves the same value. **This is the installed CLI tree** (`bin/`, `lib/`, `VERSION`; plus `.update-check`, a **lazily-created** cache file — written on the first update check, `bin/aid:159,174` — not a guaranteed member of a fresh install tree) — *not* any repo's `.aid/` folder. |
| **Scope** | Machine-level, one per CLI install. Distinct from every per-repo `.aid/settings.yml` and `.aid/.aid-manifest.json`. |
| **Writers** | **Only** `aid add` and `aid remove` (DR-1 side-effect, FR29/OQ6). Neither the server (DR-2) nor the CLI home (DR-3) ever writes it. A prune offer on the home page (NFR10) is **advice that tells the user to run `aid remove`** — it is not a write surface (FR18; consistent with MEMORY "ask user over auto-proof"). |
| **Lifecycle** | Created lazily on the **first** repo registered; removed wholesale by `aid remove self` (`rm -rf $AID_HOME`, FR28 — acceptable, rebuilt by re-adding). An absent registry ≡ an empty registry (zero registered repos); the home page renders an empty-state, never an error. |
| **Format** | A minimal YAML document, **paths-only** (FR28: no name/description/version duplicated). ASCII-only file *content as the CLI writes it* — repo paths may legitimately contain non-ASCII on some hosts, but the CLI-emitted scaffolding (keys, comments) is ASCII (the ASCII-only rule governs the shipped `bin/aid`/`bin/aid.ps1` **source**, not arbitrary user path bytes; mirrors feature-003 DM-3's "runtime output vs. source" split). |

Schema (the entire file):

```yaml
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/
# description/version are read from each repo's own .aid/settings.yml at render time.
schema: 1
repos:
  - /abs/path/to/repoA
  - /abs/path/to/repoB
```

- **`schema`** (int) — registry format version; bumped on any breaking shape change. Read by DR-1/DR-2/
  DR-3; an unrecognized higher `schema` is tolerated read-only (the reader takes `repos:` best-effort and
  records a parse note rather than erroring — NFR10 posture).
- **`repos`** (list of strings) — **absolute, canonicalized** repo base-folder paths (the repo root that
  *contains* `.aid/`, **not** the `.aid/` dir itself — symmetric with `aid add`'s `--target` which is the
  repo root, `bin/aid:1255`). Canonicalized by the **single canonicalization rule CAN-1** (below) —
  `cd "$path" && pwd` — applied identically by the writer, the registry, and both server runtimes, so
  set-membership comparisons are exact and idempotent.
- **CAN-1 — the single canonicalization rule (one rule, four sites).** A repo path is canonicalized as
  **`cd "$path" && pwd`** — the EXACT semantics `aid add`'s `--target` already applies at `bin/aid:1255`
  (`_AID_TARGET="$(cd "$_AID_TARGET" && pwd)"`) and `aid dashboard --target` at `bin/aid:804`
  (`_dc_target="$(cd "$_dc_target" && pwd)"`): absolutize + collapse `.`/`..`/`//`, but **NOT** `-P`
  (symlinks are **not** resolved). This is deliberately the existing `--target` semantics, **not** the
  `pwd -P` `bin/aid:43` uses for `$AID_HOME` self-resolution (a different value, different purpose). The
  rule MUST be applied **identically** at all four sites so the stored path, the `sha256` id (DD-1), and
  every per-request id→path resolution can never diverge: (1) the registry **writer** (`aid add`/`remove`
  `--target` → `registry_register`/`unregister`, FF-1), (2) the registry **storage** (DM-1 `repos[]` —
  paths are stored already-canonical), (3) the **Python** server's id→path map (DD-1), and (4) the
  **Node** server's id→path map (DD-1). The PowerShell twin applies the equivalent (resolve to an
  absolute path without following symlinks). (If symlink-resolution were ever wanted it would require
  changing `--target` *and* all four sites to `pwd -P` **together**; the spec adopts the no-`-P`
  existing semantics, so no `bin/aid` `--target` change is made.)
- **No per-repo metadata.** Name/description/version are deliberately absent (FR28): a repo rename or
  version bump never touches the registry. They are read live from `<repo>/.aid/settings.yml` by DR-3.
- **DD-3 (registry concurrency / atomic write):** see Design Decisions — writes are
  read-modify-write under a temp-file-rename to stay torn-write-safe across the rare concurrent
  `aid add` in two repos.

> **DD-REG-FMT — why YAML, not a paths-newline file or JSON.** REQUIREMENTS FR28 names the file
> `registry.yml`. AID already standardizes on YAML for the sibling per-repo `settings.yml` and the
> CLI already ships a tolerant YAML scalar/list read posture (feature-002 reads `settings.yml`
> `project.name`). A flat list-of-scalars is the minimal YAML the CLI must emit and either runtime must
> parse — and crucially it is parseable by a **single anchored line-scan** (`grep -E '^\s*-\s'` →
> strip the `- ` prefix), keeping the zero-third-party-dep, dual-runtime posture (no YAML library on
> either side). JSON was considered (the manifest is JSON) but the requirement pins `.yml` and a
> bracketed-list JSON is *harder* to line-scan than a YAML block sequence; a bare newline-delimited
> `.txt` was considered but loses the `schema:` version handle and contradicts the named `.yml`.

#### DM-2. The CLI-home model — `/api/home` (DR-3 data feed; FR7/FR27/FR33)

The CLI home is **live** (it must reflect repos appearing/disappearing and each repo's status changing;
NFR3-class freshness). Per **DD-2** (CLI-home data feed) it is fed by a **new machine-level endpoint**
`GET /api/home` on the same multi-repo server — *not* by N parallel `/api/model` polls and *not* by a
static bake. `GET /api/home` returns `200` `application/json; charset=utf-8` with this envelope (parallel
to feature-003 DM-1, same `schema_version`/`generated_by` discipline so PT-1 extends cleanly):

```jsonc
{
  "schema_version": 1,            // int; CLI-home wire shape version (independent of /api/model's)
  "generated_by": "python",       // "python" | "node"; diagnostic only, EXCLUDED from PT-1 parity (DM-3 f-003)
  "machine": {                    // Level-0 — the relocated "AID CLI (this machine)" panel (FR7/FR33)
    "aid_version": "1.2.0",       // string|null; from $AID_HOME/VERSION (trimmed) -- the CLI's own version
    "aid_home":    "/home/u/.aid",// string; the resolved install location (FR7 "install location")
    "tools_catalog": ["claude-code","codex","cursor"],  // list<string>; the CLI's MANAGEABLE-tool catalog (machine-scoped, FR7/FR33). NOT per-repo installed tools -- those are per-repo, surfaced on each repo card (see `repos[].tools_installed`)
    "registry_path": "/home/u/.aid/registry.yml",  // string; for the operator's awareness
    "cli_runtime": "python"       // "python"|"node"; internal echo of the serving runtime (like generated_by). EXCLUDED from PT-1 parity; NOT rendered as machine info (see UI-H1) -- diagnostic only
  },
  "repos": [                      // the registered-repo list (FR27/FR28), sorted by `path` ascending (PT-1 determinism)
    {
      "path":        "/abs/repoA",        // string; the registry entry (the addressable key, see DD-1)
      "id":          "a1b2c3d4",          // string; the stable URL id derived from `path` (DD-1)
      "available":   true,                // bool; false => moved/deleted (NFR10) -- everything below may be null
      "name":        "AID",               // string|null; <repo>/.aid/settings.yml project.name (folder basename fallback)
      "description": "Agentic IID toolkit",// string|null; settings.yml project.description if present, else null
      "aid_version": "1.0.0",             // string|null; <repo>/.aid/.aid-manifest.json aid_version (per-repo install)
      "tools_installed": ["claude-code"], // list<string>; <repo>/.aid/.aid-manifest.json tools keys (feature-002 DM-2). PER-REPO -- this is FR7/FR33's "installed tools", homed on the repo (NOT the machine panel)
      "has_home":    true,                // bool; <repo>/.aid/dashboard/home.html exists (clickable target, feature-006)
      "has_kb":      false                // bool; <repo>/.aid/dashboard/kb.html exists (feature-007); advisory
    }
  ],
  "read": {                       // provenance of THIS read pass (mirrors feature-002 ReadMeta subset)
    "read_at": "2026-06-12T18:00:00Z",   // ISO-8601 UTC; EXCLUDED/normalized in PT-1 parity (DM-3 f-003)
    "repo_count": 2,                       // int; registered entries
    "unavailable_count": 0,                // int; entries whose `available=false`
    "parse_warnings": []                   // list<string>; never raised as exceptions (NFR10)
  }
}
```

- **`machine`** is the relocated Level-0 panel (FR33 receive-half). It is **machine-scoped** — read
  from `$AID_HOME` (the CLI's own `VERSION`/path), *not* from any repo. This is the panel feature-006
  is **removing** from the per-repo page; this feature is the **receiving** surface. **FR7/FR33
  "installed tools" reconciliation:** the only genuinely machine-scoped tool concept is the CLI's
  *manageable-tool catalog* (`tools_catalog` — the fixed set of host-tools `aid add` knows how to
  install: claude-code, codex, cursor, …); per-repo **installed** tools are intrinsically PER-REPO
  (each repo's `.aid/.aid-manifest.json:tools`, feature-002 DM-2), so they have no single machine-global
  value and are surfaced on **each repo card** (`repos[].tools_installed`, UI-H2) and on that repo's
  own `home.html`, **not** in the machine panel. `cli_runtime` is an internal runtime echo (like
  `generated_by`), excluded from parity and not rendered as machine info (UI-H1).
- **Per-repo display fields are read live, never from the registry** (FR28). For each registered `path`:
  `available` = does `path/.aid/` still exist; if false,
  `name/description/aid_version/tools_installed/has_home/has_kb` are best-effort and may be
  `null`/`[]`/`false` (the card renders "unavailable" + prune offer, NFR10). When
  available, `name`/`description` come from `<repo>/.aid/settings.yml` (the reader's existing tolerant
  settings parse, feature-002 DM-7), `aid_version` + `tools_installed` from
  `<repo>/.aid/.aid-manifest.json` (feature-002 DM-2 `ToolInfo.aid_version` + `tools_installed` =
  manifest `tools` keys), and `has_home`/`has_kb` from `stat` of the co-located artifacts (NFR11).
- **Determinism (PT-1 extension).** `repos` sorted by `path` ascending; object keys in declared order;
  compact UTF-8, no BOM, `U+2028`/`U+2029` escaped to the canonical form — **identical to feature-003
  DM-3** so the same serialization helpers and the same parity harness apply (PT-1-H below). The
  **parity-excluded/normalized set is `{generated_by, machine.cli_runtime, read.read_at}`** — all three
  are runtime-/timestamp-valued echoes that cannot be byte-identical across runtimes: `generated_by`
  and `machine.cli_runtime` echo the serving runtime (`"python"` vs `"node"`) and `read.read_at` is the
  per-read timestamp. Every other field is byte-identical across both runtimes.
- **No new lifecycle/enum.** `/api/home` carries no FR16 lifecycle — it is a *navigation* surface
  (FR27: navigation, not aggregation). A repo's pipeline lifecycle lives behind its own `home.html` +
  `/api/model`; the CLI home never blends or rolls-up across repos (FR9 preserved).

---

### Feature Flow

Three independent runtime cycles. None writes to any registered repo (NFR2/NFR9); the only write in the
whole feature is DR-1's registry update, performed by `aid add`/`aid remove` (already a write command).

#### FF-1. The `aid add` / `aid remove` registry side-effect (DR-1, FR29/OQ6)

The registry is kept in sync as a **post-success side-effect** of the existing tool-install/uninstall,
keyed off the **per-repo manifest** (`<target>/.aid/.aid-manifest.json`) — the authoritative record of
"which AID host-tools this repo has." The manifest already encodes the *first-tool* / *last-tool*
boundary precisely: `install_tool` **creates** the manifest on the first tool; `uninstall_tool`
**removes** the manifest when the last tool is gone (`aid-install-core.sh:1633`). So:

```
aid add|update <tool> [--target <repo>]:        # NOTE: 'add' and 'update' SHARE this case (bin/aid:1431 `case "$SUBCMD" in add|update)`)
  ... existing host-tool install/update (install_tool, UNCHANGED) ...
  AFTER the add|update loop succeeds (the shared exit-0 tail of the add|update case, bin/aid:1452):
    if the repo is NOT yet in $AID_HOME/registry.yml:
        registry_register(CAN-1(<repo>))             # DR-1 / LC-REG; first-tool-add registers
  # idempotent SET-MEMBERSHIP: a 2nd/3rd tool added, OR an `aid update` of an already-registered repo,
  # is a NO-OP on the registry. The hook fires for both `add` and `update` (shared seam) but registers
  # only if the repo path is absent -- so `update` of an already-registered repo changes nothing, and an
  # `update` that happens to be the repo's first registry entry simply ensures membership (still correct).

aid remove <tool> [--target <repo>]:
  ... existing host-tool uninstall (uninstall_tool, UNCHANGED) ...
  AFTER the remove loop succeeds (exit 0 path, bin/aid:1473):
    if <repo>/.aid/.aid-manifest.json NO LONGER EXISTS (last tool removed):
        registry_unregister(CAN-1(<repo>))       # DR-1 / LC-REG; last-tool-remove unregisters
  # 'aid remove' with no tool arg (remove ALL) also lands here: manifest gone => unregister
  # 'aid remove self' (rm -rf $AID_HOME) removes the whole registry with the tree (FR28) -- no per-repo step
```

- **Manifest-as-boundary is exact and cheap (DD-4 detail).** "First tool" = the manifest did not exist
  *before* this `add` (or the repo path was absent from the registry — the registry-membership check is
  the simpler, idempotent test and is what DR-1 uses). "Last tool" = the manifest does not exist *after*
  this `remove`. No tool-counting heuristic is needed; the engine already maintains the manifest's
  existence at exactly these boundaries (`install_tool` writes it, `uninstall_tool` deletes it when
  empty). This makes the side-effect a 2-line addition at each command's success tail, not a rewrite.
- **Host-tool behavior is UNCHANGED (C4/C7, OQ6).** The side-effect runs *only on the success path*,
  *after* the existing install/uninstall completed; it adds no prompt, changes no exit code on the
  install path, and never blocks the host-tool operation. A registry write failure (e.g. `$AID_HOME`
  read-only) is logged as a `WARN` and the command still exits with the host-tool result — the registry
  is *derived* state, so a failed sync degrades to "this repo isn't listed on the CLI home until the next
  add," never a failed install (NFR10 posture extended to the writer).
- **Idempotency (covers `add` AND `update`).** `registry_register` is a set-insert (no-op if present);
  `registry_unregister` is a set-remove (no-op if absent). Because `aid add` and `aid update` share the
  one `add|update` success seam (`bin/aid:1431`), the register hook fires for both — but as
  set-membership it is a **no-op for `update` of an already-registered repo** (the common case: you only
  `update` a repo that already has the tool, hence is already registered). The rare `update` that is a
  repo's first registry presence simply ensures membership, which is still the correct end-state.
  `update` never *unregisters* and never duplicates. Re-adding a tool to a registered repo, updating it,
  or removing one tool of several, all leave the registry untouched.
- **`--target` honored.** The repo registered is the resolved `--target` (default cwd), canonicalized
  by **CAN-1** — the same `cd "$_AID_TARGET" && pwd` the command already applies (`bin/aid:1255`; **no
  `-P`**, symlinks not resolved). The registry stores, and both server runtimes resolve, the **same**
  CAN-1 form so the stored path, its id, and per-request resolution stay identical (DM-1 CAN-1, DD-1).

#### FF-2. The multi-repo server request cycle (DR-2, FR30/C6)

One server per CLI install (feature-004 spawns it; the spawn seam is unchanged except for what `--root`
becomes — see CLI below). The server resolves **every** request against the registry and a **closed
allowlist**; anything not on the allowlist is refused.

```
LAUNCH (feature-004 'aid dashboard start <runtime>' spawns the chosen runtime's server)
  server.start():
    bind 127.0.0.1:<port>            # C1/C2 -- UNCHANGED loopback invariant; literal, never 0.0.0.0
    load $AID_HOME/registry.yml      # the resolution table; mtime-cached (DD-1) -- re-parsed only when the file changes, so live add/remove is reflected without a per-request rehash
    routes (the NEW closed allowlist, replacing feature-003's '/' + '/api/model'):
      GET /                          -> CLI home index.html       (the machine page, DR-3)            [static, fixed]
      GET /api/home                  -> build CLI-home model (DM-2) -> 200 JSON                        [dynamic, machine]
      GET /r/<id>/home.html          -> <repo(id)>/.aid/dashboard/home.html                           [static, per repo]
      GET /r/<id>/kb.html            -> <repo(id)>/.aid/dashboard/kb.html                              [static, per repo]
      GET /r/<id>/api/model          -> read_repo(repo(id)) -> feature-003 DM-1 envelope -> 200 JSON  [dynamic, per repo]
      *                              -> 404           (closed allowlist; nothing else is reachable)
    non-GET verb                     -> 405           (NFR2: no write surface, UNCHANGED from f-003)

PER REQUEST on /r/<id>/...:
  1. parse <id> from the path (fixed grammar: /r/<id>/<fixed-leaf>); reject if <id> malformed
  2. resolve <id> -> a registered repo path via the registry (DD-1 id<->path map)
       - <id> not in registry            -> 404 (unregistered; refused)
       - repo path no longer exists       -> 404 for static leaves; /api/model returns the empty
         RepoModel feature-002 already yields for an absent .aid/ (NFR10: no error)
  3. for a STATIC leaf (home.html|kb.html): the served file path is CONSTRUCTED, never taken from input:
       served = <repo>/.aid/dashboard/<leaf>      where <leaf> in {home.html, kb.html} ONLY (fixed set)
       -> the request path contributes ONLY the <id>; the filename is chosen from a 2-element allowlist,
          so '..', encoded traversal, symlink targets, and absolute injection cannot widen it (SEC below)
  4. for /api/model: call feature-002 read_repo(<repo>) (read-only) -> serialize (feature-003 DM-1)
```

- **Resolution is registry-gated, every request.** A path addresses a repo only via a registered `<id>`;
  an `<id>` absent from the registry is a 404. The server never serves a repo it does not have in the
  registry, and never serves a file outside `<repo>/.aid/dashboard/` (the two fixed leaves only). This is
  the C6 "structurally refuse any path that escapes a registered repo's `.aid/dashboard/`" requirement,
  realized by **construction** (the filesystem path is built from a registered root + a fixed leaf), not
  by sanitizing attacker-controlled strings.
- **Registry freshness, mtime-cached (cheap, live; NFR4 bound).** The registry is a tiny paths list,
  but rather than re-parse + rehash it on **every** request, the server caches the parsed list + the
  id↔path map keyed on the registry file's **mtime/size** (DD-1) and rebuilds **only when the file
  changes**. A `stat` per request (O(1)) detects an `aid add`/`aid remove` mutation and triggers exactly
  one rebuild; between mutations every request is a cached lookup. This reflects a repo added/removed
  without restarting the server (NFR3-class freshness for the repo *set*, matching the home page's poll)
  while keeping the per-request cost bounded under the default ~5s poll across many tabs (NFR4). A torn
  read (registry being rewritten by a concurrent `aid add`, DD-3) yields a best-effort list + a parse
  note, never a 500.
- **Invariants preserved (C6, hard).** Loopback bind (C1/C2), no-write (NFR2), no-LLM (NFR7) are
  **carried over verbatim** from feature-003's delivered server — the `--host` loopback gate, the absence
  of any `fs.write*`/append/`os.remove`, and the absence of any agent/LLM import all remain and are now
  asserted across the **N-root** route set (SEC-1..3 below). The read-only contract spans N registered
  roots simultaneously (NFR9).

#### FF-3. The CLI-home poll loop (DR-3, FR27/FR4-class)

```
BROWSER LOAD of /  (CLI home index.html; static, served by DR-2)
  1. GET /                  -> CLI home index.html (HTML + inlined CSS/JS; no build, no CDN -- NFR8 family)
  2. page boot: read poll interval from localStorage (default 5000 ms; reuses feature-003 UI-5)
  3. POLL LOOP (self-rescheduling setTimeout; single in-flight; reuses feature-003 Feature-Flow loop):
       a. fetch('/api/home')                                  (same-origin)
       b. on 200: if schema_version !== EXPECTED -> stale-assets banner, keep last-good
       c. render machine panel (machine.*) + repo-card grid (repos[])         [UI-H1..UI-H3]
       d. on error/non-200/timeout: keep last-good view + "reconnecting" badge (never blank)
  4. CLICK a repo-card (available) -> navigate to /r/<id>/home.html  (that repo's per-repo page, feature-006)
       - the per-repo page then polls /r/<id>/api/model (feature-003 front-end, parameterized by <id>)
  5. CLICK an unavailable card's prune-offer -> show FR18 step-by-step guidance (run 'aid remove ...'),
       NOT a write (the page is read-only; NFR2)
```

The CLI home reuses feature-003's poll-loop machinery, freshness badge, interval control, and design
family wholesale (NFR8) — it differs only in the endpoint (`/api/home` vs `/api/model`) and the render
target (machine panel + repo grid vs pipeline view).

---

### Layers & Components

Behind one HTTP origin and the existing `bin/aid` launcher. Per `coding-standards.md` (small,
single-purpose, deterministic, no hidden I/O) and `module-map.md` (new modules consuming feature-002's
`read_repo` and `$AID_HOME`).

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-REG Registry I/O (×2: Bash in `bin/aid`/core + the server's per-runtime reader)** | CLI + server | `registry_register`/`registry_unregister` (Bash + PS twin; atomic read-modify-write, DD-3); a read-only `load_registry()` in each server runtime (line-scan `repos:`) | duplicate per-repo metadata; write the registry from the server or page; error on a missing/torn file (degrade per NFR10) |
| **LC-MS Multi-repo server (×2: Python + Node)** | server | bind `127.0.0.1`; the NEW closed allowlist (`/`, `/api/home`, `/r/<id>/{home.html,kb.html,api/model}`); resolve `<id>`→repo via LC-REG; construct static paths from registered-root + fixed-leaf; call `read_repo(repo)`; serialize `/api/home` (DM-2) and `/api/model` (f-003 DM-1) | bind non-loopback; expose any write verb; serve any path outside `<repo>/.aid/dashboard/`; trust a request-supplied filename; call any agent/LLM; cache/persist a model |
| **LC-HOME CLI home page (`<install>/dashboard/index.html`)** | static | boot, poll `/api/home`, render the machine panel + repo-card grid, unavailable/stale handling, navigate to `/r/<id>/home.html` | mutate any `.aid/`; fetch a CDN/web-font at runtime; blend two repos' pipeline data (FR9); call an agent/LLM |
| **LC-R Reader (feature-002)** | server | `read_repo(repo_root) -> RepoModel`, run **per registered repo** — consumed as-is | (owned by feature-002; not re-specified) |
| **LC-A Assets (feature-003 design family)** | static | the inlined design-family CSS+JS reused from `knowledge-summary/` (NFR8) | fetch external assets at runtime |

- **The per-repo page is RELOCATED, not duplicated.** Feature-003/006 delivered the per-repo SPA as
  `<repo>/dashboard/index.html` served at `/` with a single `--root`. Under DR-2 the **per-repo** page
  moves to `<repo>/.aid/dashboard/home.html` (NFR11, owned by feature-006's revision) and the **CLI home**
  takes the `<install>/dashboard/index.html` + `/` slot. The server no longer takes a single `--root`; it
  takes the registry. (CLI seam change below.)
- **Two server implementations stay siblings (feature-003 LC-S posture).** Each runtime grows: a
  `load_registry()` line-scan, the `<id>`↔path map (DD-1), the `/api/home` builder (DM-2), and the
  per-`<id>` route handlers. They share **no code** but share the **contract** (DM-1/DM-2/DM-3) and are
  held to it by the **extended PT-1** (PT-1-H below). Each calls feature-002's `read_repo` in its own
  runtime, now once per addressed repo.
- **Bind-address invariant (C1/C2, hard) — UNCHANGED & re-asserted (SEC-1).** The listen address stays
  the literal `127.0.0.1` (loopback-gated `--host`, server.py:299 / server.mjs:72). The grep-level
  no-`0.0.0.0`/wildcard self-check (feature-003) is **retained** and re-run against the rewritten server.
- **No-write invariant (NFR2/NFR9, hard) — EXTENDED to N roots (SEC-2).** LC-MS has no mutating route and
  opens no file for write/append across **any** of the N registered roots; the only filesystem touch is
  `read_repo()`'s read path + `stat`s for `/api/home` + reading the two fixed static leaves. The
  feature-003 no-write self-check (no `fs.write*`/append/`os.remove`/`unlink`) is retained and re-run.
- **No-LLM invariant (NFR7, hard) — UNCHANGED.** LC-MS + LC-HOME are plain code; no agent/LLM import,
  same-origin `fetch` only. The feature-003 grep self-check is retained.
- **Dependency direction.** feature-004 CLI spawns → **LC-MS** → {LC-REG read, LC-R `read_repo` per
  repo}. LC-MS depends on the registry **file contract** (DM-1), not on `bin/aid`'s registry *writer*.
  LC-HOME depends only on `/api/home` (DM-2) + LC-A. LC-REG's **writer** (`bin/aid`) depends on nothing
  in the server. This keeps the registry a clean file boundary between the CLI (writer) and the server +
  page (readers).
- **Zero build step / zero third-party deps (UNCHANGED).** `index.html` ships ready-to-serve; the YAML
  line-scan needs no YAML library on either runtime (DD-REG-FMT); Python stays stdlib-only, Node
  built-ins-only (`technology-stack.md`).

---

### CLI / Command spec

This feature touches the CLI in two places: the `aid add`/`aid remove` **registry side-effect** (the new
behavior) and the `aid dashboard start` **spawn seam** (a small contract change — what the server is
pointed at). Bare `aid` and the `aid dashboard` grammar are otherwise **unchanged**.

#### CLI-1. `aid add` / `aid remove` registry side-effect (DR-1, FR29/OQ6)

- **Grammar: UNCHANGED.** No new verb, no new flag (OQ6). `aid add <tool>[,...] [--target <dir>]` and
  `aid remove [<tool>[,...] | self] [--target <dir>]` keep their exact existing surface, help text
  (`bin/aid:78-89`), and exit codes.
- **New semantics (success-path tail only):**
  - `aid add` / `aid update` success → if `<repo>` not yet registered, **register** `CAN-1(<repo>)`
    (FF-1; `add` and `update` share the `add|update` seam at `bin/aid:1431`). This is idempotent
    set-membership: `update` of an already-registered repo is a **no-op** on the registry; only a
    genuine first-tool registration writes.
  - `aid remove` success → if `<repo>/.aid/.aid-manifest.json` is now gone (last tool), **unregister**
    `CAN-1(<repo>)` (FF-1).
  - `aid remove self` → removes `$AID_HOME` (and thus `registry.yml`) wholesale; no per-repo step.
- **Output:** a single concise line on a registry change (e.g. `Registered <repo> with the AID CLI.` /
  `Unregistered <repo> from the AID CLI.`), gated by the existing `--verbose` for detail; silent when the
  registry is unchanged (idempotent add/remove). A registry-write failure prints `WARN: aid: could not
  update the machine repo registry (<path>): <reason>` and the command **still exits with its host-tool
  result** (FF-1; NFR10).
- **Cross-platform parity (NFR5).** The registry side-effect is a **direct edit to the
  HAND-MAINTAINED root `bin/aid` (Bash) and `bin/aid.ps1` (PowerShell twin)** — byte-behavior twins:
  same registry path resolution, same first-tool/last-tool boundary off the manifest, same atomic
  write (DD-3). **`bin/aid`/`bin/aid.ps1` are NOT `canonical/`→render artifacts** — they are not in
  `canonical/EMISSION-MANIFEST.md` and the render-drift / `run_generator.py` pipeline never touches
  them (verified; feature-004 LC-4 SPEC.md:271-291, feature-005 SPEC.md:353-358). The edits land on
  the root files **directly**; the shipped CLI is the **vendored copy**
  (`packages/npm/bin/aid`, `packages/pypi/aid_installer/_vendor/bin/aid` + `.ps1`/`.cmd`), refreshed
  by the prepack vendor step (`node packages/npm/scripts/vendor.js` +
  `python3 packages/pypi/scripts/vendor.py`) — a task runs the vendor scripts (or relies on CI) so
  the side-effect ships vendored. **The applicable gates are:** ASCII-only source on both
  (`tests/canonical/test-ascii-only.sh`; `coding-standards.md`; MEMORY "ASCII-only PowerShell
  scripts"), **Bash↔PowerShell parity** (`tests/canonical/test-aid-cli-parity.sh` — identical
  exit codes + messages), and **vendored-copy refresh** — **NOT** render-drift / `run_generator.py`,
  which does not apply to these hand-maintained files (C7's dogfood-render rule governs the
  `canonical/`-rendered producers, not `bin/aid`).

#### CLI-2. `aid dashboard start` spawn seam (DR-2 contract change)

- **Grammar: UNCHANGED** — `aid dashboard start <node|python> [--remote] [--port <n>] [--target <dir>]`
  / `aid dashboard stop` (`bin/aid:100-108`). The help text and exit codes are preserved.
- **Spawn-seam change (the one real edit):** feature-004 today spawns
  `<interp> <repo>/dashboard/server/server.* --root <target> --host 127.0.0.1 --port <n>` (`bin/aid:890`).
  Under DR-2 the **single `--root`** is replaced by a **registry-driven** server: the launcher passes the
  resolved `$AID_HOME` (so the server can find `registry.yml` and the CLI-home `index.html`) instead of a
  single repo root. The server entry point relocates to the **install tree** (`$AID_HOME/dashboard/...`)
  rather than a per-repo `<repo>/dashboard/...`, because it now serves the machine (all registered repos),
  not one repo. (Exact entry-point path + `--target`'s residual meaning — "register-and-open this repo as
  a convenience" vs. "no-op for a machine server" — is a **DR-2 detail-phase item**, see Open Questions.)
- **`--target` semantics under a machine server (flagged).** `aid dashboard` historically operated on the
  cwd repo. With a machine-level server, `--target` no longer scopes *what is served* (the registry does).
  The detail phase must decide whether `--target` (a) is accepted and used to *auto-register + deep-link*
  that repo's `home.html` on open, or (b) becomes a no-op with a deprecation note. The spec's
  recommendation: **(a)** — preserve the "run it in my repo and see my repo" ergonomic by auto-opening
  `/r/<id>/home.html` for the cwd repo when it is registered, while the home page remains reachable at `/`.

---

### API Contracts

The NEW closed allowlist (DR-2), replacing feature-003's delivered `/` + `/api/model` two-route server.

| Method | Route | Handler | Success | Refusal |
|--------|-------|---------|---------|---------|
| GET | `/` | CLI home `index.html` (static, from `$AID_HOME/dashboard/index.html`) | `200 text/html` | `404` if asset missing |
| GET | `/api/home` | build CLI-home model (DM-2) from registry + per-repo `settings.yml`/manifest stats | `200 application/json` | `500` only on an unexpected internal error (a missing/torn registry degrades to an empty/best-effort list, not 500) |
| GET | `/r/<id>/home.html` | static `<repo(id)>/.aid/dashboard/home.html` (feature-006 output) | `200 text/html` | `404` if `<id>` unregistered, repo absent, or file absent |
| GET | `/r/<id>/kb.html` | static `<repo(id)>/.aid/dashboard/kb.html` (feature-007 output) | `200 text/html` | `404` if `<id>` unregistered, repo absent, or file absent |
| GET | `/r/<id>/api/model` | `read_repo(repo(id))` → feature-003 DM-1 envelope | `200 application/json` | `404` if `<id>` unregistered; **empty `RepoModel`** (not 404/500) if the repo path is registered but its `.aid/` is gone (NFR10) |
| GET | (any other path) | — | — | `404` (closed allowlist) |
| non-GET | (any) | — | — | `405` (NFR2 — no write surface; UNCHANGED from f-003) |

- **Route grammar is fixed and narrow.** The per-repo prefix is the literal `/r/`, followed by a single
  `<id>` segment (DD-1 grammar: `[0-9a-f]{8,}` hex — no `/`, no `.`, no `%`), followed by exactly one of
  three fixed leaves (`home.html`, `kb.html`, `api/model`). Any deviation (extra segments, a non-leaf
  filename, a malformed `<id>`) falls through to `404`. The grammar itself excludes traversal: an `<id>`
  cannot contain `.` or `/`, and the leaf is chosen from a 3-element allowlist, never echoed from input.
- **`<id>` ↔ path resolution (DD-1).** The server builds an in-memory map from the loaded registry:
  `id(path) = first 8+ hex chars of sha256(CAN-1(path))` → `path`, where `CAN-1` is the single
  canonicalization rule (DM-1: `cd "$path" && pwd`, no `-P`). Because the writer stores paths
  already in CAN-1 form and both runtimes hash that **same** stored byte-string, the id is identical
  across the Python and Node servers (cross-runtime id parity, DD-5). The URL carries the **id**, never
  the path. Justification under Design Decisions (DD-1).
- **Same-origin only.** The front-end issues only same-origin `fetch` to `/api/home` (CLI home) or
  `/r/<id>/api/model` (per-repo page); no CORS, no cross-origin egress (NFR7).
- **Parity (PT-1-H).** `/api/home` and every `/r/<id>/api/model` response is byte-identical across
  runtimes (excluding the runtime-/timestamp-valued echoes `generated_by`, `machine.cli_runtime`, and
  `read.read_at`), enforced by the extended parity harness below.

---

### UI Specs

The CLI home page — `<install>/dashboard/index.html` — required by FR7/FR27/NFR6/NFR8. Built on the
**same `knowledge-summary/` design family** feature-003 uses (NFR8), reusing feature-003's shell,
top-bar, theme toggle, freshness badge, interval control, and poll loop. It renders **navigation, not
aggregation** (FR27/FR9).

#### UI-H1. Page shell + machine panel (FR7/FR33, NFR8)

The page reuses feature-003 UI-1's shell (sticky `.top-bar` with brand + freshness badge + interval
control + theme toggle; system fonts; `meta robots noindex`; the "served locally / read-only / refreshes
every Ns" footer). The brand reads **"AID — this machine"** (machine scope, not a repo name). Below the
top bar sits the **relocated Level-0 "AID CLI (this machine)" panel** (FR7/FR33) — a `.card.plugin`-family
card showing the **machine-scoped** CLI info: `machine.aid_version` (CLI version), `machine.aid_home`
(install location, FR7/FR33), and `machine.tools_catalog` (the CLI's **manageable-tool catalog** — the
host-tools `aid add` can install, FR7/FR33 "installed tools" rendered at machine scope as the catalog).
**`machine.cli_runtime` is NOT rendered** — it is an internal runtime echo (like `generated_by`),
diagnostic only and excluded from parity (#2/#12); the operator-facing panel carries only the three
parity-stable machine fields above. Per-repo **installed** tools (which host-tools a given repo has)
are PER-REPO and render on each **repo card** (UI-H2, `repos[].tools_installed`), not in this machine
panel — FR7/FR33's "installed tools" is machine-scoped as the catalog here, and per-repo on the cards.
When `aid_version` is null (no `VERSION` file) the card shows
"CLI version unavailable" rather than erroring — the same graceful-degradation posture feature-006 uses
for an absent manifest.

#### UI-H2. Registered-repo card grid (FR27/FR28)

The repo list renders as a responsive card grid (reusing `.grid.g2`/`.g3` + `.card`), one card per
`repos[]` entry. An **available** card shows: `name` (settings.yml; folder basename fallback, never the
raw path as a title — mirrors feature-009 FR25's "never render the id as a title" discipline),
`description` (or an em-dash `—` when null, feature-009 FR25 placeholder), `aid_version` chip,
`tools_installed` (this repo's installed host-tools, FR7/FR33 per-repo "installed tools" — small
tool chips; empty/omitted when the manifest is absent), and (when
`has_kb`) a small "KB" affordance. The **whole card is the click target** → `/r/<id>/home.html` (FR27
navigation). `has_home=false` (registered repo with no `home.html` yet — e.g. summarize/discover not yet
run) renders the card non-clickable with a quiet "dashboard not generated yet" note rather than a dead
link. Cards sort by `name` (stable; the model already sorts `repos` by `path` for determinism, the
renderer may re-sort by display name client-side).

#### UI-H3. Unavailable / stale cards + prune offer (NFR10, FR18)

A card whose `available=false` (the registered path's `.aid/` is gone — moved or deleted) renders in a
**muted "unavailable" treatment** (greyed, `--text-dim`, a ⊘ glyph reusing the feature-003 UI-4 Canceled
shape vocabulary) showing the registered `path` and a **prune offer**. Per FR18 + MEMORY
("ask-user-over-auto-proof"), the prune offer is **step-by-step guidance** — it tells the operator the
exact command to clean it up (`aid remove --target <path>` once, which unregisters the now-toolless repo;
or a future explicit prune) and how to verify — it is **not** a button that writes (NFR2: the page is
read-only). The empty registry (no repos) renders a friendly empty-state ("No repos registered yet — run
`aid add <tool>` in a repo to see it here", FR18), never a blank or an error.

#### UI-H4. Responsive + cross-browser (NFR6, NFR5)

Reuses feature-003 UI-6 verbatim: the design family's 768px mobile collapse (card grid → single column),
2-col tablet, full grid desktop (`max-width: 1200px`). Baseline primitives only (CSS custom properties,
grid/flex, `fetch`, `localStorage`, `setTimeout`) — Chrome/Firefox/Edge/Safari. **Per the global
CLAUDE.md web-review gate, the reviewer MUST render the served CLI home in Playwright** (not inspect
source) to validate the machine panel + repo grid + unavailable card + empty-state + dark theme +
responsive reflow, and the navigation click into a repo's `home.html`.

---

### Security Specs

The multi-root read-only scoping — the heart of C6/NFR9. The feature-003 server's three hard invariants
are **carried over and extended to the N-root, new-allowlist shape**; the extension is the explicit blast
radius C6 names.

- **SEC-1. Loopback bind (C1/C2) — UNCHANGED.** The server binds the literal `127.0.0.1` (loopback-gated
  `--host`; `server.py:299`, `server.mjs:72`). The grep-level no-`0.0.0.0`/`::`/wildcard self-check is
  retained and re-run against the rewritten LC-MS. The server can never go public; `--remote` (DR-4) is
  feature-005's ACL-scoped Tailscale layer over this loopback port — unchanged.
- **SEC-2. No path traversal — multi-root, by construction (C6, hard).** A static request supplies only
  `<id>` (hex, no `.`/`/`/`%`) and selects a leaf from a **3-element fixed allowlist** ({`home.html`,
  `kb.html`, `api/model`}). The served filesystem path is **constructed** as
  `registry[id] + "/.aid/dashboard/" + leaf` — the request never contributes a filename, a path segment,
  or a directory component beyond the `<id>` lookup. Therefore `..`, percent-encoded traversal, an
  absolute-path injection, a symlink whose target escapes `.aid/dashboard/`, and any attempt to read
  arbitrary `.aid/` content (e.g. `settings.yml`, `STATE.md`, a work folder) are all **structurally
  unreachable** — there is no code path that opens a request-derived path. A self-check test asserts the
  static handler resolves only `registry[id]/.aid/dashboard/{home.html,kb.html}` and 404s every crafted
  traversal/escape input (`..`, `%2e%2e`, absolute `/etc/passwd`, `/r/<id>/../settings.yml`,
  `/r/<id>/work-001-x/STATE.md`, a symlinked `home.html`→outside). This is the C6 "structurally refuse"
  requirement.
- **SEC-3. No-write across N roots (NFR2/NFR9, hard).** LC-MS opens no file for write/append/delete in
  any of the N registered roots; the only filesystem touches are `read_repo()` (read), `stat`s for
  `/api/home`, and reading the two fixed static leaves. The feature-003 no-write grep self-check
  (no `fs.write*`/`appendFile`/`unlink`/`os.remove`/open-for-append) is retained and re-run on the
  rewritten LC-MS. The read-only contract now provably spans all registered roots simultaneously.
- **SEC-4. No-LLM (NFR7) — UNCHANGED.** No agent/LLM import anywhere in LC-MS or LC-HOME; same-origin
  `fetch` only. The feature-003 grep self-check is retained.
- **SEC-5. PT-1 parity extension (C6 blast radius — PT-1-H).** Feature-003's PT-1 fixture/harness is
  **extended** to the multi-repo shape: a checked-in **registry fixture** pointing at ≥2 fixture repos
  (one with `home.html`+`kb.html`, one without; plus one **unavailable** entry whose path does not
  exist), driven through both runtimes. The harness asserts byte-identical (excluding the
  runtime-/timestamp echoes `generated_by`, `machine.cli_runtime`, `read.read_at`) output for
  **`/api/home`** and for **each `/r/<id>/api/model`**, and asserts the
  SEC-2 traversal-refusal set returns identical refusals from both runtimes. The harness keeps the
  feature-003 skip-if-runtime-absent shape (Linux-only box runs the Python half; the parity assertion
  runs only when both runtimes are present). Registered as a deliverable, not optional polish — it is the
  verification that the contract-level rewrite did not let the two runtimes diverge.
- **SEC-6. `--remote` repo-list-to-grantees (OQ5, DR-4) — accepted trade-off.** `aid dashboard --remote`
  exposes the **CLI home (all registered repos)** over feature-005's **unchanged** ACL-scoped Tailscale
  Serve mechanism. The change is purely *what is served* (the machine home, hence the registered-repo
  **list** — paths/names — and every registered repo's `home.html`/`kb.html`/`/api/model`), not *how* it
  is exposed: it stays tailnet-private, **never public** (C1/NFR1), and reachable only by the granted
  host/user ACL identities (C3). Exposing the repo list (paths/names) to a *granted* tailnet identity is
  the **accepted trade-off** (OQ5): a granted user is already a trusted operator of that host. The
  feature-005 expose/teardown helpers, the FR18 ACL-grant guidance, and the SEC-1 never-public structural
  guarantee are all unchanged — DR-4 changes neither the helper nor the bind, only the page behind the
  port.

---

### `--remote` (DR-4) — serving-scope adjustment (OQ5, feature-005 cross-ref)

DR-4 is a one-line conceptual change with zero change to feature-005's mechanism: when `--remote` is
passed, the loopback port now fronts the **CLI home** (all registered repos) instead of a single repo's
page. Concretely:

- The feature-005 expose helper (`_aid_remote_expose` / its PS twin), its tailnet-only `tailscale serve`
  invocation, its FR18 ACL-grant guidance, its `dashboard.pid` `remote_handle` record, and its teardown
  path are **all unchanged** (`bin/aid:540-721`). It exposes "the loopback port"; *what* lives behind that
  port is decided by DR-2, not by feature-005.
- Therefore `aid dashboard start <runtime> --remote` brings up the multi-repo server (DR-2) on the
  loopback port, then exposes that port via feature-005 — a grantee opening the private `.ts.net` URL
  lands on `/` (the CLI home), sees the registered-repo list, and can navigate into any registered repo's
  `home.html`/`kb.html`/`/api/model` (OQ5). Never-public (C1) and host/user-ACL scoping (C3) hold exactly
  as feature-005 specifies.
- The security note (SEC-6) — repo-list-to-grantees is an accepted trade-off — is the only new posture;
  no new exposure code, no new bind, no new public path.

---

### Design Decisions

| ID | Decision | Rationale / alternatives rejected |
|----|----------|-----------------------------------|
| **DD-1** | **Repo URL addressing = an opaque hex `<id>` = `sha256(CAN-1(path))[:8+]`, mapped to the path server-side; URL grammar `/r/<id>/<fixed-leaf>`.** | The id is `sha256` of the **CAN-1-canonical path** (DM-1: `cd "$path" && pwd`, no `-P`) — the *same* byte-string the writer stored — so the id is **identical across both runtimes** (cross-runtime id parity, DD-5) and stable. A path-in-URL (`/r/%2Fabs%2Frepo/home.html`) was rejected: it pushes attacker-controllable path bytes into the route, makes traversal-refusal a *sanitization* problem (fragile), and leaks absolute paths into browser history/logs. A registry **index** (`/r/0/home.html`) was rejected: indices renumber when a repo is unregistered, breaking bookmarks/deep-links and the `aid dashboard --target` auto-open. A content-hash `<id>` is **stable** (survives unregister/re-register of *other* repos), **opaque** (no path leak in the URL), and **structurally traversal-safe** (hex only — cannot encode `.`/`/`). 8 hex chars (32 bits) is ample for a per-machine repo set (collision-checked at load; on the astronomically-unlikely collision the server lengthens the prefix). **Caching/invalidation (NFR4 bound):** the path↔id map is **not** rebuilt on every request — it is cached keyed on the registry file's **mtime** (+size) and rebuilt **only when the registry changes** (`stat` per request is O(1); the sha256 rehash over all paths runs only on a genuine add/remove). So under the default ~5s poll across many tabs the per-request cost is one `stat` + a map lookup, never an N-path rehash — bounding the re-hash to actual registry mutations (NFR4). |
| **DD-2** | **CLI-home data feed = a new machine endpoint `GET /api/home` on the same server (not N parallel `/api/model` polls, not a static bake).** | A static bake was rejected: the home must reflect live add/remove + per-repo status changes (FR27 live, NFR3-class) and a paths-only registry has nothing to bake. N parallel `/api/model` polls were rejected: the home needs only a thin per-repo summary (name/desc/version/availability), not each repo's full `RepoModel` — N full reads per tick is wasteful (NFR4) and N round-trips is chattier than one. A single `/api/home` builder does N cheap `stat`s + one settings/manifest scalar read per repo, in one response, reusing feature-003's exact poll-loop/freshness machinery. It parity-extends cleanly (DM-2 mirrors DM-1's envelope). |
| **DD-3** | **Registry concurrency / atomic write = read-modify-write under a `mktemp`+`mv` rename; reads tolerate a torn file.** | Two `aid add`s in two repos can race on the single registry file. A naive append/in-place rewrite can interleave and corrupt the list. The writer reads the current `repos:` set, applies the set-insert/remove, writes a temp file in `$AID_HOME`, and `mv`s it over `registry.yml` (atomic rename on the same filesystem — the same `mktemp`+`mv` pattern `bin/aid`'s PATH-wiring already uses, `bin/aid:297-305`). The PS twin uses the equivalent `Move-Item -Force`. Readers (server, page-feed) take the file best-effort: a read landing mid-rename either sees the old or new complete file (atomic rename) and never a half-written one; a parse anomaly degrades to a best-effort list + a parse note (NFR10), never a 500. No lock file, no daemon — consistent with AID's no-daemon posture. |
| **DD-4** | **First-tool/last-tool boundary = the per-repo manifest's existence (created on first `install_tool`, deleted on last `uninstall_tool`), and registry membership is the idempotent test.** | A tool-count heuristic (parse the manifest, count `tools.*`, register when count goes 0→1) was rejected as redundant: the engine already maintains the manifest at *exactly* these boundaries (`aid-install-core.sh:1407` writes it on install; `:1633` deletes it when empty). DR-1 therefore needs no counting — on `add` success it set-inserts the repo (idempotent: a no-op if already registered); on `remove` success it checks whether the manifest is now gone and set-removes if so. This makes the side-effect a tiny, behavior-additive tail on each command (C4/C7), not a manifest re-parse. |
| **DD-5** | **The multi-repo server stays byte-parity by reusing feature-003's exact serialization discipline (DM-3) + extending PT-1 to the new routes (PT-1-H).** | The contract-level rewrite reopens the dual-runtime divergence risk feature-006 DD-1 leaned on (C6 blast radius). Rather than invent a new parity mechanism, DM-2 mirrors feature-003 DM-1's envelope (`schema_version`/`generated_by`/declared key order/compact UTF-8/`U+2028`-escape) so the **same** serialization helpers and the **same** harness shape apply; PT-1-H adds a registry fixture + asserts `/api/home` and per-`<id>` `/api/model` byte-identity + identical traversal-refusals across runtimes. Both runtimes also derive the **same `<id>`** for a given repo because both hash the identical CAN-1-canonical stored path (DD-1) — so a `/r/<id>/…` URL minted under one runtime resolves under the other; the PT-1-H fixture's per-`<id>` assertions exercise this id parity. Byte-parity is thus a *carried* property, not a re-derived one. |

---

### Acceptance-criteria → spec map

| AC (charter) | Requirement | Satisfied by |
|----|-------------|--------------|
| AC-1 | `aid add` first-tool registers / `aid remove` last-tool unregisters; paths-only; host-tool behavior unchanged (FR28/FR29/OQ6/C4/C7) | FF-1 + CLI-1 + DD-4 (manifest-boundary side-effect, success-tail only); DM-1 (paths-only schema) |
| AC-2 | CLI home shows machine panel (version/install-location/manageable-tool catalog — FR7/FR33 machine-scoped) + a repo-card per repo (name/desc/version + that repo's installed tools); card → that repo's `home.html` (FR7/FR27/FR30/FR33) | DM-2 (`/api/home`: `machine.tools_catalog` + `repos[].tools_installed`) + UI-H1/UI-H2 + DD-2; navigation `/r/<id>/home.html` (DD-1) |
| AC-3 | multi-repo server serves `/`, `home.html`/`kb.html`/`api/model` per repo; refuses unregistered/traversal paths; f-003 invariants hold; PT-1 + no-write self-checks extended (FR30/C6/NFR9) | FF-2 + API-routing table + SEC-1..5 (the NEW closed allowlist, construct-not-sanitize, parity + self-check extension) |
| AC-4 | moved/deleted repo → "unavailable" + prune offer; no other view/server errors (NFR10) | DM-2 (`available`) + UI-H3 + FF-2 (404/empty-RepoModel, never 500) |
| AC-5 | N roots served read-only with none written; local-only bind; hand-maintained `bin/aid`/`bin/aid.ps1` registry edits pass ASCII-only + Bash↔PowerShell parity + vendored-copy refresh (NFR2/NFR9/C1/C2; `bin/aid` is NOT a `canonical/`-render artifact) | SEC-1/SEC-3 (loopback + no-write across N roots, self-checks); CLI-1 (direct edit to hand-maintained `bin/aid`/`bin/aid.ps1`; `test-ascii-only.sh` + `test-aid-cli-parity.sh` + `vendor.js`/`vendor.py` — NOT render-drift) |

---

### Known issues registered by this feature

This feature performs a **contract-level rewrite** of feature-003's delivered server (DR-2) — the
explicit C6 blast radius. It introduces no *new* known defect: the bind/no-write/no-LLM/no-traversal
properties are enforced by self-check tests (SEC-1..4) and the dual-runtime divergence is closed by the
extended PT-1-H (SEC-5) as a deliverable. The relocation of the per-repo page (`<repo>/dashboard/` →
`<repo>/.aid/dashboard/home.html`, NFR11) is owned by feature-006's revision and the `kb.html` output by
feature-007; this feature consumes those outputs and does not re-specify them. No new `known-issues.md`
entry is warranted at spec time. (If, during implementation, an `<id>` collision or a registry-format edge
proves to need handling beyond DD-1/DD-3, that becomes a real KI at that time; it is not a defect now.)

---

### Residual open questions (for /aid-plan and /aid-detail)

These are **detail-phase** mechanics, not design gaps — the design is decided; these are "exact wiring"
items deliberately left for the plan/detail phases:

1. **Server entry-point relocation (DR-2/CLI-2) — the vendored install-tree unit (server + reader).**
   Exact install-tree path for the machine server (`$AID_HOME/dashboard/server/server.{py,mjs}`?) and
   how it is vendored into the CLI install tree (today the per-repo `dashboard/` is *not* install-wired
   — MEMORY "dashboard-not-install-wired"; the machine server **must** be, since it lives in
   `$AID_HOME`). **The vendored unit is NOT the server entry alone: the feature-002 reader (LC-R) must
   be co-vendored and importable from the new location.** The Python server imports the reader via a
   `sys.path` insert relative to the `dashboard/` parent (`from reader import read_repo`,
   `server.py:30-41`) and the Node twin does likewise; relocating the entry into `$AID_HOME/dashboard/`
   without co-vendoring the reader (importable on the same relative module layout) is a runtime import
   failure. So the install-tree unit is **`dashboard/server/{server.py,server.mjs}` + the reader
   module(s) it imports**, laid out so the existing relative import resolves. This intersects an open
   packaging item; still plan-deferred.
2. **`aid dashboard --target` residual meaning (CLI-2).** Recommendation (a) auto-register + deep-link
   the cwd repo vs. (b) no-op-with-note; pick at detail.
3. **`<id>` prefix length + collision policy (DD-1).** 8 hex is the spec default; confirm the collision-
   lengthen mechanic and whether to expose the full id anywhere for diagnostics.
4. **Prune ergonomics (UI-H3/NFR10).** Whether the eventual prune is purely "run `aid remove`" guidance
   (spec default, NFR2-safe) or a future dedicated `aid` prune affordance — out of this feature's scope,
   noted for the roadmap.
5. **FR35 `kb_baseline` settings key validation owner.** Cross-references feature-007/`/aid-config`
   (RE§FR35 schema-ownership note) — not owned here, flagged so the two features' `settings.yml` reads
   agree.
