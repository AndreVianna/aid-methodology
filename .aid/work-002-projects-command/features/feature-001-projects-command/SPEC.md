# Projects Command (`aid projects`)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-16 | Feature created from REQUIREMENTS.md | /aid-interview |
| 2026-06-16 | Technical Specification added | /aid-specify |
| 2026-06-16 | A+ review fixes: readers are key-agnostic (no reader migration); ASCII `*` marker (not `▸`, NFR3); psm1 1 emitter; existing broken-assertion updates + `test-aid-provisioning.sh` added; migration simplified (no reader-before-writer coupling) | A+ review (6 findings) |
| 2026-06-16 | A+ round-2 fixes: full 3-line seed-comment rewrite (all "repo" gone, version source corrected to manifest); dashboard JSON `repos` field explicitly OOS | A+ review (3 findings) |
| 2026-06-16 | name source corrected (settings.yml, not manifest); added user-facing string-sweep component (~16 strings, bash+PS) + Terminology rule (retain "git repository"); broadened test-assertion inventory (full PAR057 set incl. O16 byte-compare); corrected vacuous Windows key-assert claim | A+ review (PLAN gate + SPEC r3) |
| 2026-06-16 | CRITICAL fix: FR7 reconcile now covers BOTH tier prompts per platform (cwd-classify `~2152`/`~1315` AND `aid add` B-table `~2754`/`~2609`); migrate never-elevate pinned; added FR7 behavioral-test requirement; seed-header is 6 sites in bin/aid; grep gate scoped (retain back-compat fixtures + JSON field) | A+ review (Detail gate, 8 findings) |

## Source

- REQUIREMENTS.md §5 (FR1–FR9) — command surface, terminology+key migration, list indicators, add/remove, deterministic tier, reconcile, parity, help
- REQUIREMENTS.md §9 (AC1–AC11) — acceptance criteria

## Description

A new top-level CLI command, `aid projects`, that manages the set of directories AID tracks (a *project* = any folder containing `.aid/`). It exposes the existing-but-hidden registry: list registered projects with their live state, register/unregister a project (tracking only — never touching tools), and pick the storage tier deterministically by location. It replaces the only prior management path (hand-editing `registry.yml`) and the inconsistent, interactive auto-registration.

## User Stories

- As an operator, I want `aid projects` to list every tracked project with its AID version/state and which is my current one, so I can see my fleet at a glance.
- As an operator, I want to register/unregister a project without installing or removing tools, so I can fix a bad or missing registry entry.
- As a developer, I want tier selection to be predictable (by location), so the same project doesn't land in different tiers depending on how it was first touched.

## Priority

Should

## Acceptance Criteria

(Inherits REQUIREMENTS.md §9 AC1–AC11 verbatim; the `## Technical Specification` below is the how.)

---

## Technical Specification

> Cited line numbers are anchors from the current `master`; **re-anchor by symbol name** at execute time (lines shift). All shipped edits are ASCII-only.

### Data Model

**Registry file** (`$AID_STATE_HOME/registry.yml` and the `$HOME/.aid/registry.yml` fallback). Current schema:

```yaml
schema: 1
repos:                 # → renamed to `projects:`
  - /abs/canonical/path
```

Changes:
- **Writer key rename `repos:` → `projects:`.** Entries unchanged (one canonical absolute project base path per `  - ` line; produced by `cd && pwd`). `schema: 1` unchanged.
- **Readers need NO change — they are already key-agnostic.** Verified: bash `_registry_read_repos` greps `^[[:space:]]*-[[:space:]]+` items (`bin/aid:1297`), PS `Get-RegistryRepos` matches `^\s*-\s+(.+\S)` (`bin/aid.ps1:1236`), and Python `load_registry` extracts items via `_ITEM` regex (`server.py:61`), all ignoring the section key. They read `projects:` and legacy `repos:` files identically with no edit.
- **Writers emit `projects:`** only. A legacy file is re-keyed on its next write (lazy migration; never mixed-key — each writer emits the whole file with one key). Because readers are key-agnostic, no reader breaks at any point in the migration.
- **Seed header comment (full 3-line block, all writer sites).** Every writer emits the same 3-line header; ALL "repo" usages across ALL three lines are de-"repo"-ed, and the stale version source is corrected. Replace verbatim at each emit site (`lib/aid-install-core.sh:1431-1433`, `bin/aid:1379-1381`, `bin/aid:1411-1413`, and any other writer copies; PowerShell equivalents in `bin/aid.ps1`/`lib/AidInstallCore.psm1`):
  - L1: `# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).`
  - L2: `# Holds ONLY the base folders of projects this CLI install manages. Per-project name and`
  - L3: `# description come from .aid/settings.yml; version/tools from the manifest, at render time.`
  - (L3 fixes the stale "version … from .aid/settings.yml": name/description are from `.aid/settings.yml` (`models.py:166`), but version/tools are from `.aid/.aid-manifest.json`/`.aid-version` — consistent with this SPEC's state model.)
- The registry stores **folder paths only** — read live at render time (never cached): per-project **name/description** from `.aid/settings.yml` (`models.py:166`), and **version/tools** from `.aid/.aid-manifest.json` / `.aid/.aid-version`.

### Feature Flow

```
aid projects [ACTION] [PATH] [--local|--shared] [--verbose]
  ACTION ∈ {list (default), add, remove, help}

list:
  raw_entries = read_raw_union()         # BOTH tiers, deduped, NO prune
  for e in raw_entries:
     state = compute_state(e)            # vX.Y.Z | untracked | no-aid | missing
     tools = read_manifest_tools(e)      # from e/.aid/.aid-manifest.json
     tier  = which_tier_holds(e)         # user | shared
     mark  = "*" if canon(cwd) == e      # ASCII marker (NFR3); no non-ASCII glyphs
  render table; footnote if canon(cwd) is an AID project not in raw_entries

add [path=cwd]:
  t = canon(path); require -d t/.aid     # else clear error, exit 2
  tier = resolve_tier(t, --local/--shared)
  registry_register t tier               # reuse; reports tier actually written

remove [path=cwd]:
  t = canon(path)                        # no .aid/ requirement (repair stale)
  registry_unregister t                  # reuse; idempotent no-op message

help / -h: print usage
```

### Layers & Components

#### A. bash — `bin/aid`

| Site (symbol ~line) | Change |
|---|---|
| dispatch chain (after `dashboard`, ~2408; before final reject ~2433) | **Add** `if [[ "$SUBCMD" == "projects" ]]` block → parse sub-action + `[path]` + `--local/--shared/--verbose`, call `_cmd_projects`. |
| **new** `_cmd_projects` | Orchestrates list/add/remove/help per Feature Flow. The "you are here" marker is ASCII `*` (NFR3 — `bin/aid` is ASCII-guarded by `tests/canonical/test-ascii-only.sh`); never a non-ASCII glyph. |
| **new** `_registry_read_raw_union` | Like `_registry_read_union` (`~1313`) but **WITHOUT** the `[[ -d "$p/.aid" ]]` prune (`~1326-1329`) — returns every registered path so `list` can render `no-aid`/`missing`. Keep `_registry_read_union` (pruning) for existing callers. |
| **new** `_aid_resolve_tier <canon-path>` | Extract the deterministic rule: `user` if `_AID_SCOPE != global` OR path under `$HOME`; else `shared`. Honors `--local/--shared` override; `--shared` under per-user scope → user + notice. Reused by both `_cmd_projects` and `_aid_cwd_classify`. |
| **new** `_aid_project_state <path>` | Print `vX.Y.Z`/`untracked`/`no-aid`/`missing` (reads manifest/`.aid-version`); plus a tools reader from the manifest. |
| `_aid_cwd_classify` tier block (`~2145-2163`) — prompt **#1** "Register this repo…" (`~2152`) | **Replace** the interactive y/N prompt with `_aid_resolve_tier` (FR7; no prompt). |
| `aid add` B-table tier prompt **#2** "Add this repo to the shared machine registry?" (`bin/aid:~2754`) | **Also replace** with `_aid_resolve_tier` — this is a SEPARATE second prompt; FR7/AC6 require BOTH gone so `aid add <tool>` on a global/outside-home install no longer prompts. |
| dashboard auto-register (`~1212,1221`) | Adopt `_aid_resolve_tier` BUT keep **never-elevate**: a shared result that needs elevation degrades silently to user (no prompt during render). |
| migrate side-effect register (`~1776`) | Pass the `_aid_resolve_tier` result; **never-elevate** (degrade silently — must not newly prompt under a TTY). |
| `_registry_read_repos` (`~1294-1300`) | **No change** — already key-agnostic (greps `^  - ` items, ignores the section key). |
| registry writers (the 6 `repos:` emitters) + seed comment | Emit `projects:`; rewrite the full 3-line seed header comment (above). |
| **User-facing message strings** (registry WARN lines "machine/shared repo registry", "repo not registered in shared tier"; the `update self` migrate prompts "No registered repos…/Skipping repo migration/Migrate repo X?"; "manage AID across your repositories") | **Sweep `repo`/`repos` → `project`/`projects`** in every `printf`/`echo` user-facing string that refers to an AID-tracked directory or the registry. **Retain** literal `git repository`, the `__migrate-repo` token, and shell variable names. Verify by grep (§Terminology rule). NOTE: the **two tier prompts** ("Register this repo…" `~2152` in `_aid_cwd_classify`, and "Add this repo…" `~2754` in the `aid add` B-table) are **NOT** swept here — they are *removed* by the FR7 reconcile (component below). To avoid parallel-edit conflicts, task-001 leaves both prompt regions untouched. |
| `_aid_usage` (`~91-158`): default block (`~140-156`) + new per-cmd case (`~94-139`) | List `projects`; add `aid projects -h` help text. |
| file header comment (`~12-18`) | Add `aid projects` to the command list. |

#### B. bash core — `lib/aid-install-core.sh`

| Site | Change |
|---|---|
| registry seed/emit (single emitter `~1435`; `~1399` is a comment) | Emit `projects:`; change the seed header comment "machine repo registry"→"machine project registry". |

#### C. PowerShell — `bin/aid.ps1` + `lib/AidInstallCore.psm1`

| Site (symbol ~line) | Change |
|---|---|
| dispatch (`ps1 ~2286`, after `__migrate-repo`, before final reject) | **Add** `projects` branch → `Invoke-AidProjects`. |
| **new** `Invoke-AidProjects` | Mirror `_cmd_projects` (list/add/remove/help). |
| **new** `Get-RegistryRawUnion` | Non-pruning union (mirror of A). |
| **new** `Resolve-AidTier` | Mirror `_aid_resolve_tier` (Windows: no elevation prompt; per-user/global + degrade still apply). |
| `Invoke-AidCwdClassify` prompt **#1** (`ps1 ~1315`) AND the `aid add` B-table prompt **#2** (`ps1 ~2609`) | Replace **both** with `Resolve-AidTier` (FR7/AC6 — same two-prompt situation as bash; both must go). |
| `Get-RegistryRepos` (`ps1 ~1231-1241`) | **No change** — already key-agnostic (matches `^\s*-\s+` items). |
| PS registry writers (`bin/aid.ps1` ×2 `~1401,~1511`; `lib/AidInstallCore.psm1` ×1 `~931`) + seed comment | Emit `projects:`; rewrite the full 3-line seed header comment. |
| **PS user-facing message strings** (`Write-Host`/`Write-Error`/`Write-Warning`: "Registered …", migrate prompts `~2084/2091/2100`, "manage AID across your repositories" `~1612`) | Same sweep as bash: `repo(s)`→`project(s)` for the tracked-dir/registry concept; retain `git repository`. NOTE: the two tier prompts (`~1315`, `~2609`) are **NOT** swept here — they are *removed* by the FR7 reconcile (task-007); leave them for that task. |
| `Resolve-AidTier` marker | ASCII `*` (NFR3; `bin/aid.ps1` is ASCII-guarded). |
| `Show-AidUsage` (`ps1 ~140-207`, default `~189-206`) | List `projects` + per-cmd help. |

#### D. Python — `dashboard/server/server.py`

| Site | Change |
|---|---|
| `load_registry` (`~64-92`) | **No change required** — `_ITEM` regex (`~61`) already extracts items key-agnostically, so `projects:` files parse correctly today. *(Optional cosmetic tidy: the header-skip at `~86`, currently `stripped == "repos:" or stripped.startswith("repos:")`, may add `projects:` for clarity — not needed for correctness.)* |

#### E. Tests

> The writer key flip (`repos:`→`projects:`), the 3-line seed-comment rewrite, AND the user-facing string sweep **break existing assertions** that pin the old key/header/strings — ALL must be updated in lockstep. Known inventory (re-confirm by grep — treat as a floor, not a ceiling): `test-registry.sh` (REG-U01d `:202` header, REG-U01f `:205`, REG-U07c `:249`), `test-aid-provisioning.sh` (PRV-P02b `:129`, PRV-P02c `:130-131`), `test-aid-cli-parity.sh` (**PAR057-O07 `:984`, O09 `:989`, O12 `:996`, O14 `:1001`, O16 `:1010` (byte-for-byte bash↔PS `registry.yml` compare), S02 `:1442-1443`, S03 `:1444`**). Completeness check (NOT a blanket grep — input fixtures and output assertions must be distinguished): **every test that asserts the CLI's *emitted/produced* registry content** (output assertions) expects `projects:` + the new header + swept strings. **Legacy `repos:` / old-header strings are RETAINED, untouched, ONLY where they are back-compat INPUT fixtures or the API field** — namely: the `test-registry.sh` legacy-input heredocs feeding the key-agnostic reader (REG-V0x, ~`:497/505/518/539/605/671/803`), the `test-dashboard-parity.sh`/`test-dashboard-parity-h.sh` legacy fixtures, and the dashboard JSON `repos` field reads. After editing, confirm by inspection that **each** remaining `machine repo registry`/`repos:` hit under `tests/` is one of those retained input-fixture/JSON categories (a `→ 0` grep is wrong by design and must NOT be used as the gate).

| File | Add / Update |
|---|---|
| `tests/canonical/test-registry.sh` | **Update** REG-U01d/U01f/U07c to expect `projects:` + new header comment. **Add** units: raw (non-pruning) list incl. `no-aid`/`missing`/`untracked`/`vX.Y.Z` states; `add` rejects non-`.aid/`; `add`/`remove` idempotent; `remove` repairs stale; tier resolution per-user vs global + override + degrade; legacy-`repos:` read still works; writer emits `projects:` (legacy re-key); ASCII `*` marker. HOME pinned + escape canary (registry/migration default root to `$HOME`). |
| `tests/canonical/test-aid-provisioning.sh` | **Update** PRV-P02b/P02c to expect `projects:` key + new seed-comment header. |
| `tests/canonical/test-aid-cli-parity.sh` | **Update** PAR057-O09/O14/S03 + header asserts (`:984/996`) to expect `projects:`/new comment. **Add** bash↔PS parity for `projects list/add/remove` (output shape, exit codes). |
| `tests/windows/Test-AidInstaller.ps1` | New `T<NN>` IDs for `aid projects` on Windows-native PS (list/add/remove/help). NOTE: this suite has **no** registry key/header assertion today, so the writer flip breaks nothing here; only the new command tests are added. Update a message-string assertion only if one is later found by grep. |

#### F. Docs / KB (count-drift — routed to `/aid-housekeep`, not inline except code-adjacent)

`bin/aid` header comment (C), `_aid_usage`/`Show-AidUsage` (code) updated in-task. KB enumerations (`feature-inventory.md`, `infrastructure.md`) + any "N commands" counts reconciled via `/aid-housekeep`. A `[NEW] aid projects` line added to `.aid/knowledge/release-tracking.md` (Unreleased).

### Terminology rule (de-"repo")

In ALL user-facing output (`printf`/`echo`/`Write-Host`/`Write-Error`/`Write-Warning`) and the registry header comment, "repo"/"repos" referring to an AID-tracked directory or the registry becomes "project"/"projects". **Retained as-is** (NOT swept): the literal phrase `git repository`/`git repo` (it describes git, not the AID-project concept — consistent with "a project need not be a git repo"); the internal `__migrate-repo` subcommand token; shell/PowerShell variable identifiers (`$repo`, `_canon_repo`, `$Repo`); and the dashboard server's JSON field `repos` (API boundary — see Out of Scope). Verification: `grep -nE '[Rr]epo' bin/aid bin/aid.ps1 lib/aid-install-core.sh lib/AidInstallCore.psm1` shows every remaining hit is one of those retained categories.

### Migration Plan

- **Key rename is write-only** (no version bump, no separate migration pass, no reader edit). Readers are **key-agnostic by construction** (item-regex; verified for all three), so an existing `repos:`-keyed registry keeps working on every platform and is silently upgraded to `projects:` the first time a writer rewrites it. No mixed-key state is reachable, and no reader can break at any point — so the writer flip is order-independent across bash/PowerShell (it does not impose a reader-before-writer sequencing constraint).

### Security Specs

- `add`/`remove` mutate only the registry file; never touch project contents or tools (NFR1).
- Shared-tier writes reuse the existing `_aid_priv_run` elevation probe; on decline / no-TTY they **degrade to the user tier with a notice** (never block, never silently misreport — the command prints the tier actually written). The `aid dashboard` auto-register path is **never-elevate** by design and must keep degrading silently rather than prompting.
- No new network or filesystem surface beyond the registry file.

### Out of Scope (restated)

Tool install/removal semantics; the dashboard HTML/UI; a registry GC/`prune` action; cutting the 1.2.0 release.

**Intentionally NOT renamed:** the dashboard server's JSON response field `"repos"` (`dashboard/server/server.py:349`) is a frontend/API contract consumed by the dashboard HTML — renaming it would break presentation. It is the API boundary, not the on-disk registry key, and stays `repos` (FR2 targets the registry file key + user-facing CLI text, not the internal JSON API field).
