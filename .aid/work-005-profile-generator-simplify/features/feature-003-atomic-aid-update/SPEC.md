# Atomic aid update

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Feature identified from REQUIREMENTS.md §5 FR7/FR7a/FR10/FR11, §4 In-Scope 4 & 7, §6 NFR4, §7 C5/C6, §9 AC5/AC8 | /aid-interview |
| 2026-06-20 | Technical Specification drafted (aid-specify), bash+PS parity; 9 decisions confirmed — atomicity=(a) stage-all-first + best-effort/idempotent re-run, manifest-diff EXTENDS era-detection, manifest source=extracted bundle staging tree, retired-root sweep in install pass, add-skew honors FR11 + notice, --dry-run on add, mixed-version via tools.*.version, keep .agents as migration signal | /aid-specify |
| 2026-06-20 | A+ review (D → fix): corrected 2 wrong PS twin names (`Get-DetectedTool`→`Detect-Tool`, `Initialize-ToolStaging`→`Prepare-AidToolStaging`), dropped EMISSION-MANIFEST misattribution (bundle staging tree IS the manifest), fixed `Resolve-AidToolList` cite (2898-2934) + `--dry-run` self cite (drop 696) | /aid-specify REVIEW |
| 2026-06-20 | Atomicity machinery trimmed (intent-fidelity review correction): kept stage-all-first; simplified the mid-commit contract — since `aid update` is already idempotent/re-entrant, the sufficient contract is "on any commit failure, exit non-zero with a brief clear message + re-run `aid update` to heal". Dropped the elaborate per-tool precise-inconsistent-state-naming machinery (still honest — no silent skew — just lean); Security-Specs row reworded to drop the "rollback" implication | intent-fidelity review |

## Source

- REQUIREMENTS.md §5 (FR7, FR7a, FR10, FR11)
- REQUIREMENTS.md §4 (In Scope 4, In Scope 7)
- REQUIREMENTS.md §6 (NFR4)
- REQUIREMENTS.md §7 (C5, C6)
- REQUIREMENTS.md §9 (AC5, AC8)

## Description

Make `aid update` a single command that keeps every AID tool installed in a repo at one
version, and performs complete-replacement migration in the same pass. There is no
per-tool selection: outside an AID repo, `aid update` updates only the CLI to the latest
version; inside an AID repo, it updates the CLI first, then advances all of the repo's
installed tools to that same version. The five arguments — `--from-bundle`, `--dry-run`,
`--version`, `--target`, `--force` — behave as specified, with `--version` pinning all
tools.

In the same pass, the update migrates old layouts by complete replacement: the prior
AID-delivered content is fully replaced with the new version's content. The per-version
manifest is the source of truth — anything that is AID-owned (by any of the three
ownership markers: filename starts with `aid-`, lives inside an `aid/` folder, or sits
inside an `AID:BEGIN`/`AID:END` region) and absent from the new version's manifest is
pruned automatically. The Codex `.agents/` split and Cursor's `.cursor/rules/` therefore
disappear on their own, since those paths are AID-owned and not in the new manifest.
Content matching none of the three markers is user content and is never touched.

The same-version invariant holds at every entry point, not just update: `aid add` for
the first tool installs at the CLI's version; `aid add` for an additional tool installs
at the existing tools' version (add does not force a repo-wide update). A partial failure
must never silently leave a repo at mixed versions — the operation is atomic or returns a
clear error naming the inconsistent state. All of this works identically in bash and
PowerShell, and existing installs across all channels migrate cleanly.

## User Stories

- As an AID adopter, I want a single `aid update` that keeps all my installed tools at one version, so that I never have to reason about per-tool versions or end up in a mixed-version state.
- As an AID adopter upgrading from an old layout, I want `aid update` to migrate me by complete replacement — pruning the retired `.agents/` and `.cursor/rules/` trees — without touching my own content, so that the upgrade leaves no stranded or duplicate AID trees.
- As an AID adopter adding a second tool to a repo, I want `aid add` to install it at my existing tools' version rather than forcing a repo-wide update, so that my repo stays internally consistent and only `aid update` advances everything to latest.
- As an AID maintainer, I want migration and version logic to behave identically in bash and PowerShell and to fail atomically, so that no repo on any channel or shell is left half-migrated.

## Priority

Must

## Acceptance Criteria

- [ ] Given an existing install with an old layout (`.agents/`, `.cursor/rules/`), when `aid update` runs, then the install migrates by complete replacement — AID-owned orphans (by `aid-` prefix / inside `aid/` / inside an AID region) absent from the new version's manifest are pruned, no stranded or duplicate trees remain, and user content is untouched — verified on old-layout fixtures. (AC5)
- [ ] Given a repo with one or more installed tools, when `aid update` runs, then it updates all installed tools to one version via a single command with no per-tool selection — outside-repo updates the CLI only, inside-repo updates the CLI then all tools, the five arguments behave as specified, and no repo ends in a mixed-version state including via `aid add` or initial install. (AC8)

---

## Technical Specification

> **Feature character.** This is the **install/CLI** feature of work-005 — the
> bash+PowerShell twin `aid` CLI (`bin/aid` + `bin/aid.ps1`) and its shared install-core
> (`lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`). It owns the **install-time
> migration of *user* repos** (FR7/FR7a/AC5), the single-`aid update` command shape
> (FR10/AC8), and the same-version invariant across `aid add` / initial install (FR11).
> It is **distinct from feature-002** (the generator), which only reshapes the committed
> `profiles/*` trees + produces the new per-version manifest that THIS feature consumes
> at install time. Where feature-002 guarantees the new manifest correctly *omits* the
> retired paths, this feature is what *acts on* that omission inside a real user repo.

### Section Applicability

| Section | Status | Rationale |
|---------|--------|-----------|
| **API Contracts** | **Activated (the `aid` CLI contract)** | AID ships no HTTP/RPC API; the relevant contract is the **`aid` CLI command/flag surface** (`pipeline-contracts.md` documents `aid` as a contract). This section defines the FR10/FR11 command shape. |
| **Data Model** | **Activated** | No relational DB. The "data model" = `.aid/.aid-manifest.json` (per-repo install state) + the **new per-version shipped manifest** (FR7a) + the derived **version-invariant state**. |
| **Feature Flow** | **Activated** | The `aid update` (outside/inside) and `aid add` (first/additional) flows, plus the complete-replacement migration pass. |
| **Layers & Components** | **Activated** | The bash+PS install-lib + CLI functions changed/added, with the explicit parity surface. |
| **Migration Plan** | **Activated** | The core deliverable: old-layout (`.agents/`, `.cursor/rules/`, `.agent/rules/`) → new layout on `aid update`, tested on old-layout fixtures (AC5). |
| **Security Specs** | **Activated (light)** | The privilege boundary (`_aid_priv_run` / never-elevate `.aid/` creation) and the atomicity contract (FR11 — stage-all-first + brief-message/idempotent re-run, no rollback machinery) — destructive prune must not corrupt a repo on partial failure. |
| **Telemetry & Tracking** | **Activated (light)** | The per-tool install summary + prune/migration counts + `--dry-run` preview surface (the only "telemetry" a CLI has). |
| UI Specs · Events & Messaging · DDD/CQRS/State Machines · BDD · Cache/Search/Batch/Mobile/Cloud/Hardware · AI Enhancements · External Integrations · Recovery Management | **N/A** | The `aid` CLI is offline install tooling: no UI, no event bus, no domain model, no app runtime, no AI surface. The release-download path (`fetch_tarball`/GitHub releases) is an existing integration unchanged by this feature. |

---

### API Contracts — the `aid` CLI command/flag surface (FR10 + FR11)

This feature changes the **`aid update`** and **`aid add`** contracts. `aid remove`,
`aid update self`, `aid remove self`, `aid status`, `aid projects`, `aid dashboard` are
**unchanged**.

#### `aid update` — single command, all tools, one version (FR10)

```
aid update [--version <v>] [--target <dir>] [--from-bundle <path>] [--dry-run] [--force]
aid update self ...                         # UNCHANGED (channel-aware CLI self-update)
```

**Removed:** the `aid update [<tool>...]` **positional** (evidence: `bin/aid:147-148`,
`bin/aid:2855-2885` positional collection, `bin/aid:2971-3008` `_resolve_tools_for_aid`,
and the PS twin `bin/aid.ps1:2898-2934` `Resolve-AidToolList`). After this feature, any
non-flag positional on `aid update` (other than `self`) is a **usage error (exit 2)** —
there is no per-tool update.

**Two modes (FR10):**

| Mode | Condition | Behavior |
|------|-----------|----------|
| **Outside an AID repo** | `_aid_is_project_dir <target>` is false | Update the **CLI only** to latest (delegates to the existing `_cmd_update_self` / `_aid_update_self_if_stale` path); **no-op if already latest**. Today this case calls `_aid_cwd_no_aid_offer` and exits (`bin/aid:2909-2914`) — FR10 changes it to "update CLI only". |
| **Inside an AID repo** | `_aid_is_project_dir <target>` is true | (a) Update the **CLI first** (the existing `_aid_update_self_if_stale` preamble at `bin/aid:2919-2921`), then (b) update **ALL** tools in `tools.*` of the repo manifest to one version, in a single atomic pass. |

**Argument semantics (the 5 args):**

| Arg | Semantics |
|-----|-----------|
| `--version <v>` | Pin **ALL** tools (and, when self-update runs, the CLI target) to version `v`. Mutually exclusive with `--from-bundle` (existing rule, `bin/aid:2926-2929`). Replaces today's per-resolved version. |
| `--target <dir>` | Operate on `<dir>` as the repo root instead of cwd (existing `_AID_TARGET`, `bin/aid:2869-2871`). The outside/inside-repo decision is made against `<dir>`. |
| `--from-bundle <path>` | Offline source: a release-staging dir (or per-tool tarball) for the tool bundles. Each tool's bundle is `aid-<tool>-v<ver>.tar.gz` (existing `_prepare_tool_staging_aid`, `bin/aid:3050-3103`). The bundle **must carry the FR7a per-version manifest** (see Data Model). |
| `--dry-run` | **NEW on the main path.** Print the full plan — every tool that would update, every file that would be copied/updated, every AID-owned path that would be **pruned/replaced** by the migration — then exit 0 with **no filesystem change**. Today `--dry-run` exists only on `update self`/`remove self` (`bin/aid:692,2696`); FR10 broadens it to the whole update pass (deliberate change, REQUIREMENTS FR10 note). |
| `--force` | Overwrite differing non-AID-region files (existing `_AID_FORCE` → `copy_file force=1`). Does **not** change prune authority — pruning is driven by markers + manifest membership, not by `--force`. |

#### `aid add <tool>[,<tool>...]` — same-version invariant (FR11)

```
aid add <tool>[,<tool>...] [--version <v>] [--target <dir>] [--from-bundle <path>] [--dry-run] [--force]
```

**Version selection (FR11) — the new rule replacing today's "resolve latest per call":**

| Case | Version installed |
|------|-------------------|
| **First tool** (manifest absent / no `tools.*` entries) | The **CLI's own version** (`$AID_CODE_HOME/VERSION`), unless `--version <v>` / `--from-bundle` overrides. |
| **Additional tool** (manifest already has ≥1 tool) | The **existing tools' version** (read from the manifest's uniform `tools.*.version`). `add` does **NOT** force a repo-wide update. `--version` may still override but then it must apply to ALL tools (see atomicity) or error. |

> **Confirmed (2026-06-20) — CLI-ahead-of-repo skew on `aid add` additional-tool.** When the
> CLI is newer than the repo's existing tools (e.g. CLI v1.2.0, repo tools at v1.1.0) and
> the user runs `aid add cursor`, FR11 says install cursor at the **existing-tools** version
> (v1.1.0) to preserve repo consistency — NOT the CLI version. **Recommended:** honor FR11
> literally — pin the new tool to the repo version, and print a one-line notice
> *"repo is at v1.1.0; cursor installed at v1.1.0. Run `aid update` to advance all tools to
> v1.2.0."* This keeps `add` non-escalating (FR11) and makes the skew visible. Confirm vs the
> alternative (refuse the add and require `aid update` first).

> **Confirmed (2026-06-20) — `--dry-run` on `aid add`.** REQUIREMENTS FR10 lists `--dry-run`
> under `aid update`; FR11 does not mention it for `add`. **Recommended:** add `--dry-run`
> to `aid add` too (same preview semantics) for symmetry and testability, since both share
> the dispatch block (`bin/aid:3108-3162`). Confirm.

---

### Data Model

#### 1. `.aid/.aid-manifest.json` — per-repo install state (existing; schema UNCHANGED)

The on-disk install ledger (`schemas.md` / `manifest_write`). Shape (abridged):

```jsonc
{
  "manifest_version": 1,
  "aid_version": "1.1.1",                  // top-level: last version written
  "installed_at": "…",
  "tools": {
    "claude-code": {
      "version": "1.1.1",                  // per-tool version — the FR10/FR11 invariant key
      "installed_at": "…",
      "paths": [ ".claude/agents/aid-architect.md", … ],   // the new manifest's path set
      "root_agent_files": [ { "path": "CLAUDE.md", "sha256": "…", "status": "owned" } ]
    }
  }
}
```

**The version invariant (FR10/FR11) is a derived property of this structure:** *all
`tools.*.version` are equal*. `_render_tools_block` already classifies **uniform vs
divergent** (`aid-install-core.sh:1345-1410`) and shows `- all at vX` vs a per-tool list.
This feature makes the invariant a **post-condition** of `aid update` / `aid add`, not just
a display state. No schema field is added.

> **Confirmed (2026-06-20) — represent "inconsistent state" without a schema change.** A
> mixed-version repo is already detectable (the divergent branch of `_render_tools_block`).
> **Recommended:** do NOT add a manifest field; detect mixed-version by reading
> `tools.*.version` and comparing. The atomicity contract (below) prevents *creating* one;
> a pre-existing divergent repo is reported by `aid status` and healed by `aid update`.
> Confirm vs adding an explicit `"consistent": false` marker.

#### 2. The per-version shipped manifest (FR7a) — NEW input, produced by feature-002

Each shipped version carries a manifest enumerating its **complete AID-delivered file set
per tool** (feature-002 emits it; the per-version path set is the **extracted tool-bundle staging tree** — see below). This
feature **reads** the new version's file set from the **extracted tool bundle staging dir**
during install — the staging tree IS the authoritative new-version path set for that tool
(`_prepare_tool_staging_aid` already extracts it). The prune/replace diff is therefore:
*on-disk AID-owned content (by FR7 markers) MINUS the staging tree's file set = orphans to
remove.*

> **Confirmed (2026-06-20) — manifest source: the extracted bundle, not a separate JSON.**
> Today the prune authority is built from the just-written `install_paths` set
> (`install_tool`, `aid-install-core.sh:1859-1866`), i.e. exactly the new bundle's files.
> **Recommended:** keep this — the staged bundle tree per tool is the per-version manifest
> (FR7a satisfied by feature-002 emitting the bundle), and the prune set is derived from it
> as today, just **broadened to all three markers + retired roots** (see Migration Plan). No
> new shipped JSON file needed; the bundle's file list IS the manifest. Confirm vs shipping a
> discrete `manifest.json` inside each tarball and diffing against that.

#### 3. The version source for FR11 (no schema change)

`aid add` first-tool reads `$AID_CODE_HOME/VERSION`; additional-tool reads
`manifest_read_tool_version` of any existing tool (they are uniform by invariant). `aid
update` resolves one target version (latest, or `--version`, or the bundle version) and
applies it to every tool + the CLI.

---

### Feature Flow

#### A. `aid update` — outside an AID repo

```
aid update                       (cwd has no project .aid/)
  → _aid_is_project_dir(target) == false
  → run CLI self-update path (_cmd_update_self via the existing channel logic)
      · already latest        → "CLI is current (vX)"; exit 0   (no-op)
      · newer available       → update CLI; exit 0
  → (NO tool loop — there are no installed tools here)
```

This **replaces** today's `_aid_cwd_no_aid_offer`-and-exit behavior (`bin/aid:2909-2914`)
for `update`. (The "offer to set up" prompt was the old no-tools-here UX; FR10 makes the
no-repo case mean "update the CLI only".)

#### B. `aid update` — inside an AID repo (the core path)

```
aid update [--version v] [--target d] [--from-bundle b] [--dry-run] [--force]
  1. CLI-FIRST: _aid_update_self_if_stale   (existing preamble, bin/aid:2919-2921)
  2. resolve target version V := --version | bundle-version | resolve_version (latest)
  3. tools := manifest_list_tools(manifest)            (NOT a positional — FR10)
  4. STAGE ALL: for each tool, _prepare_tool_staging_aid(tool, V, bundle)   → fail-fast
       · all tools staged & checksum-verified BEFORE any write   (atomicity, FR11)
  5. if --dry-run: print plan (per-tool copy/update + prune/replace set) → exit 0
  6. COMMIT: for each tool:
       install_tool(staging, tool, target, V, force)
         · copy new tree (new layout)
         · _copy_root_agent_file (AID:BEGIN/END region merge — marker #3)
         · manifest_write(tool, V)
         · _prune_tool_dirs (complete-replacement prune — see Migration Plan)
  7. _aid_migrate_repo(target)    (existing .aid/ metadata migration — settings/home.html/registry)
  8. result: all tools.*.version == V   (invariant holds)
```

#### C. `aid add` — first tool vs additional tool (FR11)

```
aid add <tool>...
  · writability pre-check (B-table, bin/aid:3112-3119) — never create root-owned .aid/
  · V := (manifest has tools?) ? existing-tools-version : $AID_CODE_HOME/VERSION
        (overridable by --version / --from-bundle, subject to atomicity below)
  · STAGE ALL requested tools at V → fail-fast
  · if --dry-run: print plan → exit 0
  · COMMIT each: install_tool(...) at V    → invariant preserved (new tool == repo version)
  · registry_register (existing)
```

#### D. Atomicity (FR11) — all-or-nothing across the multi-tool pass

The repo must never be left mid-update at mixed versions. **Mechanism (staged-then-commit):**

1. **Stage-all-first:** every tool's bundle is fetched, checksum-verified, and extracted to
   a temp staging dir **before any destination write** (the loop is split: today
   `_prepare_tool_staging_aid` + `install_tool` are interleaved per tool at
   `bin/aid:3130-3135` — this feature **hoists all staging ahead of all commits**). A
   fetch/checksum/extract failure aborts with **no destination mutation**.
2. **Commit phase:** once all tools are staged, the per-tool `install_tool` writes run. A
   failure *here* (mid-commit) is the only window that can produce a mixed-version repo.

> **Confirmed (2026-06-20, intent-review correction) — mid-commit failure → brief-message +
> idempotent re-run.** Keep **stage-all-first** (good + cheap — it already makes network/checksum
> failures fully atomic). Since `aid update` is **idempotent and re-entrant** (it always drives
> every tool to the target V), the sufficient mid-commit contract is simply: **on any commit
> failure, exit non-zero with a brief, clear message + re-run `aid update` to heal** — e.g.
> *"ERROR: aid update failed mid-commit; repo may be at mixed versions. Re-run `aid update` to
> heal."* This is honest (no silent skew) but lean — it **drops the elaborate per-tool
> precise-inconsistent-state-naming machinery** the spec earlier carried (enumerating each tool's
> exact old/new version in the error). No per-tool rollback machinery is added: a *true rollback*
> (snapshot each tool's tree pre-commit, restore on failure) is materially more code in both twins
> and risks its own partial-failure modes — and is unnecessary given re-run-heals. This matches the
> existing WARN-not-fail / fail-loud idioms.

---

### Migration Plan — complete-replacement on `aid update` (FR7/FR7a/AC5)

#### What "complete replacement" means here

On `aid update`, the prior AID-delivered content for each tool is **fully replaced** by the
new version's content. Anything that is **AID-owned** (by ANY of the three markers) **and
absent from the new version's file set** is pruned. User content (no marker) is never
touched. The retired layouts (`.agents/` Codex split, `.cursor/rules/`, `.agent/rules/`)
drop out automatically because their paths are AID-owned and **not in the new bundle**.

#### The three ownership markers (content-isolation cornerstone, work-003)

| # | Marker | Where enforced today | Change for FR7 |
|---|--------|----------------------|----------------|
| 1 | filename starts `aid-` | `_prune_native_dir` walks `"$ndir"/aid-*` (`aid-install-core.sh:1630`) | Unchanged rule; applied to the **new-layout dirs** (see below). |
| 2 | inside an `aid/` folder | `_prune_aid_subtree` walks `{root}/aid` (`aid-install-core.sh:1666`) | Unchanged rule; pointed at the new `{root}/aid`. |
| 3 | inside an `AID:BEGIN`→`AID:END` region | `_copy_root_agent_file` region-replace (`aid-install-core.sh:388-554`) | Unchanged — region merge already replaces only the marked region in `CLAUDE.md`/`AGENTS.md`. |

#### Where today's prune is layout-locked (the bug FR7 fixes)

`_prune_tool_dirs` (`aid-install-core.sh:1699-1728`) hardcodes the **old** layout per tool:

```
codex)        _prune_native_dir .codex/agents ; _prune_native_dir .agents/skills ; _prune_aid_subtree .agents/aid
cursor)       … _prune_native_dir .cursor/rules ; …
antigravity)  _prune_native_dir .agent/rules ; …
```

Two changes are required (both twins):

1. **Re-point to the new layout (feature-002):** codex prunes `.codex/{agents,skills}` +
   `.codex/aid` (the unified root); the `.cursor/rules` and `.agent/rules` native-dir prunes
   are **removed** (those dirs no longer exist in the new bundle). `install_tool`'s per-tool
   copy dispatch (`aid-install-core.sh:1776-1835`) likewise drops the `.agents` copy for
   codex and copies only `.codex`.
2. **Add a one-time RETIRED-ROOT sweep:** the prefix-scoped prune will NOT remove a *whole
   retired tree* (`.agents/`, `.cursor/rules/`, `.agent/rules/`) because it only walks
   dirs that still exist in the new layout. Add an explicit **migration sweep** that, for
   each retired path, removes AID-owned content under it (by markers 1+2) and prunes the now-
   empty dir. This is what turns "the new manifest omits `.agents/`" into "the user's
   `.agents/` is actually deleted".

> **Confirmed (2026-06-20) — retired-root sweep lives in the install pass, not `_aid_migrate_repo`.**
> `_aid_migrate_repo` today migrates only `.aid/` *metadata* (settings.yml / home.html /
> registry — `bin/aid:1861-1959`); it does NOT touch tool trees. **Recommended:** implement
> the retired-root sweep inside the tool-install pass (a new `_migrate_retired_layout <target>
> <tool>` helper called from `install_tool` right before `_prune_tool_dirs`), keyed by a
> **static list of retired AID roots** `{.agents (codex), .cursor/rules, .agent/rules}`. It
> runs in the SAME `aid update` pass (FR7 "same pass that moves the repo to latest") and is
> idempotent (no-op when the retired path is absent). Confirm this placement vs extending
> `_aid_migrate_repo`.

> **Confirmed (2026-06-20) — manifest-diff EXTENDS era-detection** (orthogonal: era-a/b repairs `.aid/` *metadata*; the marker-prune + retired-root sweep is the *tree* mechanism — no new era). Today
> there are TWO migration mechanisms with different jobs: (i) `_prune_tool_dirs` =
> **tree-level** orphan prune (marker + new-manifest membership — already the FR7 model, just
> layout-locked); (ii) `_aid_migrate_repo` era-a/era-b = **`.aid/`-metadata** repair/synthesis
> (settings.yml stamp, home.html, registry). These are orthogonal. **Recommended: EXTEND, not
> supersede.** FR7's manifest-driven prune is the *tree* mechanism — it gains the new layout +
> the retired-root sweep. The era-detection stays as the *metadata* mechanism (it has nothing
> to do with tool-tree layout and still correctly handles old `.aid/` state). The layout
> migration is fully expressed by "new bundle omits the retired paths + marker-based prune +
> retired-root sweep" — it needs no new era. Confirm vs folding tree-migration into the
> era machine.

#### Old-layout fixtures (AC5)

Migration is verified on fixtures that reproduce a real pre-work-005 install: a `.agents/`
+ `.codex/agents/` split, a `.cursor/rules/aid-*.mdc`, a `.agent/rules/aid-*.md`, plus
**user content** in each (a non-`aid-` file in `agents/`, a user `.cursor/rules/my.mdc`,
user lines outside the `AID:BEGIN/END` region of `AGENTS.md`). Post-`aid update` assertions:
the retired AID trees are gone, the new `.codex/{agents,skills,aid}` is present, **every
user file is byte-identical**, and `tools.*.version` are uniform. Extends
`tests/canonical/test-aid-migrate.sh` (Gate-style) + the Windows
`tests/windows/Test-AidInstaller.ps1`, honoring the **HOME-pinning + escape-canary**
discipline (the migration scan defaults its root to `$HOME`; any test firing it must
`export HOME=<throwaway>` — see test-landscape / coding-standards).

---

### Layers & Components — bash + PowerShell parity surface (C6)

Every change lands in BOTH twins with byte-equivalent semantics. The map:

| Concern | bash (`lib/aid-install-core.sh`, `bin/aid`) | PowerShell (`lib/AidInstallCore.psm1`, `bin/aid.ps1`) | Change |
|---------|---------------------------------------------|--------------------------------------------------------|--------|
| **`aid update` dispatch** | `bin/aid:2683-2765` (self branch) + `2839-3162` (shared add/update) | `bin/aid.ps1:2469-…` + shared dispatch `2763-…` | **CHANGE** — remove positional tool resolution for `update`; add outside-repo = CLI-only mode; split staging-then-commit. |
| **`aid add` version rule (FR11)** | new logic in the `add` branch (`bin/aid:3109-3146`) | PS twin `add` branch | **ADD** — first-tool=CLI ver, additional=existing-repo ver. |
| **tool resolution** | `_resolve_tools_for_aid` (`bin/aid:2971-3008`) | `Resolve-AidToolList` (`bin/aid.ps1:2898-2934`) | **CHANGE** — `update` always = `manifest_list_tools`; reject `update <tool>` positional. |
| **per-tool copy dispatch** | `install_tool` case block (`aid-install-core.sh:1776-1835`) | `Install-AidTool` (`AidInstallCore.psm1:1296-…`) | **CHANGE** — codex copies only `.codex` (drop `.agents`); drop cursor/antigravity rules dirs. |
| **orphan prune** | `_prune_tool_dirs` + `_prune_native_dir`/`_prune_aid_subtree` (`aid-install-core.sh:1605-1736`) | `Invoke-PruneToolDirs` (`AidInstallCore.psm1:1139-…`) | **CHANGE** — re-point to new layout; remove rules-dir walks. |
| **retired-root sweep** | new `_migrate_retired_layout` | new `Invoke-MigrateRetiredLayout` | **ADD** — delete AID-owned content under `.agents/`, `.cursor/rules/`, `.agent/rules/`; prune empty roots. |
| **root-agent region merge (marker #3)** | `_copy_root_agent_file` (`aid-install-core.sh:388-554`) | `Copy-RootAgentFile` (`AidInstallCore.psm1:490-…`) | **NO CHANGE** — already region-correct. |
| **manifest read/write** | `manifest_*` (`aid-install-core.sh:578-1268`) | `Read-Manifest*`/`Write-AidManifest` (`AidInstallCore.psm1:675-…`) | **NO SCHEMA CHANGE** — used for version-invariant reads. |
| **staging (atomicity)** | `_prepare_tool_staging_aid` (`bin/aid:3050-3103`) | PS twin `Prepare-AidToolStaging` (`bin/aid.ps1:2974`) | **CHANGE** — hoist all staging ahead of all commits (stage-all-first). |
| **`--dry-run` on main path** | new `_AID_DRY_RUN` flag in the shared parser (`bin/aid:2859-2885`) | PS twin shared parser | **ADD** — preview, no writes. |
| **`detect_tool` codex marker** | `detect_tool` (`aid-install-core.sh:124-154`) treats `.codex` OR `.agents` as codex | PS twin `Detect-Tool` (`AidInstallCore.psm1:126`) | **CHANGE (tolerant)** — keep `.agents` as a *migration-source* detection signal so an un-migrated repo still resolves to codex during the migrating `aid update`; drop it only post-migration. |
| **CLI usage text** | `_aid_usage update`/`add` (`bin/aid:130-156`) | `Show-AidUsage` | **CHANGE** — remove `[<tool>...]`, add `--dry-run`. |

> **Confirmed (2026-06-20) — keep `.agents` in `detect_tool`.** `detect_tool` currently
> recognizes codex by `.codex` OR `.agents` (`aid-install-core.sh:130`). Until every repo is
> migrated, an un-migrated codex repo has only `.agents/skills` + `.codex/agents`.
> **Recommended:** retain the `.agents` recognition **as a migration signal** so the migrating
> `aid update` correctly identifies the tool; the retired-root sweep then removes `.agents`,
> and a future cleanup can drop the signal. Confirm.

---

### Security Specs (light)

- **Never-elevate `.aid/` creation** — the existing B-table writability pre-check
  (`bin/aid:3112-3119`) is retained for `add`; the retired-root sweep and prune operate only
  inside the repo's already-writable tool dirs (user-owned), never elevating.
- **Privileged self-update step** — the CLI-first self-update reuses `_aid_priv_run`
  (`bin/aid:331-350`); the post-update tool migration runs in the **invoking user's** context,
  never under the sudo used for the CLI install (existing invariant, preserved).
- **Destructive-prune safety** — the prune/sweep removes files only when (marker-owned AND
  absent from the new bundle); a `--dry-run` preview lets the user audit the removal set
  before any write. The stage-all-first ordering guarantees a network/checksum failure never
  leaves the repo partially pruned.

---

### Telemetry & Tracking (light)

The CLI's only "telemetry" is its console surface: the per-tool install summary
(`install_tool` counts at `aid-install-core.sh:1872-1891`), the prune count
(`_prune_tool_dirs` summary, `aid-install-core.sh:1730-1732`), a new **retired-root removal
count**, and the `--dry-run` plan. Work state is tracked in the work `STATE.md` per AID
discipline (the orchestrator owns the writes; this feature's spec registers nothing).

---

### Acceptance-Criteria Coverage

| AC | Where satisfied |
|----|-----------------|
| **AC5** — old-layout installs migrate by complete replacement; AID orphans pruned; user content untouched; verified on fixtures | Migration Plan (markers + new-layout prune + retired-root sweep) + the old-layout fixture suite |
| **AC8** — single `aid update`, no per-tool selection; outside=CLI-only, inside=CLI-then-all; 5 args as specified; no mixed-version state incl. `add`/initial | API Contracts (`aid update`/`aid add`) + Feature Flow A–D + atomicity mechanism |
| **FR7/FR7a** | Migration Plan (three markers, new-bundle membership, retired-root sweep) + Data Model #2 |
| **FR10** | API Contracts `aid update` + Feature Flow A/B |
| **FR11** | API Contracts `aid add` + Feature Flow C/D (atomicity) |
| **NFR4 / C5 / C6** | Layers parity surface (both twins) + prune semantics preserved (content-isolation R3) + cross-channel `--from-bundle` path |
