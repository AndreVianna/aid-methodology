# Two-Tier Registry, cwd Dispatch Matrix, and Registry Migration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR4, FR5, FR6), §4, §9 (AC2, AC5, AC6), §10 (Priority 2) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): corrected ps1 parity symbol names + call sites | /aid-specify |

## Source

- REQUIREMENTS.md §5 (FR4 Two-tier registry, FR5 cwd-driven dispatch, FR6 Migration over the registry)
- REQUIREMENTS.md §4 Scope (in-scope: two-tier registry, cwd-driven dispatch matrix, migration over registered repos in `update self`)
- REQUIREMENTS.md §9 (AC2, AC5, AC6)
- REQUIREMENTS.md §10 Priority 2 (the coherent model)
- Design note §3.1 (cwd-driven, no scan), §3.3 (two-tier registry), §3.5 (self-command registry migration), §4 (A/B/C dispatch matrix)

## Description

This feature builds the coherent discovery-and-dispatch layer on top of the home
split. It introduces a **two-tier registry**: a user registry
(`~/.aid/registry.yml`, always writable) and, for global installs, a shared
registry (`$AID_STATE_HOME/registry.yml`, privileged-written, world-readable);
the CLI unions both at read time, and for per-user installs the two collapse to
one file. The registry is a rebuildable index for the dashboard's repo list — it
is never required for a single-repo operation. Writes are best-effort: if
registering needs elevation and the user declines or there is no TTY, the CLI
skips and warns but still operates, and stale entries are pruned quietly on read.

It implements **cwd-driven dispatch with no machine scan**: `aid <cmd>` acts on
the current directory's repo and repos are learned incrementally on encounter.
This codifies the A/B/C scenario matrix from the design note — global self-commands,
`aid add`, and repo commands — including the "always ask on a real decision"
rule (shared-vs-user, elevation) and the no-hard-refuse rule (git is not required;
a missing `.aid/` is an offer to set up, not an error; `aid add` into an unwritable
folder errors rather than creating a root-owned `.aid/`).

Finally it adds **migration over the registry**: `aid update self` migrates exactly
the registered repos (union of both tiers, no scan), each with the per-repo
confirmation (All / Yes / No / Cancel). Unregistered repos are caught lazily by the
per-repo stamp (feature-003).

## User Stories

- As an **end user**, I want `aid` to act on the current directory's repo and
  learn repos incrementally, so it never performs a machine-wide scan.
- As a **multi-developer machine user**, I want a shared, unioned repo index that
  reads without elevation, so the dashboard can list machine repos without
  per-command `sudo`.
- As an **end user**, I want registration to be best-effort (skip + warn when
  elevation is unavailable) so a read-only command never blocks just to index.
- As an **end user**, I want to be asked whenever there is a real decision
  (register shared vs user, elevate), and to never be hard-refused for a missing
  `.aid/` or a non-git folder, so the tool is predictable and non-blocking.
- As an **upgrader**, I want `aid update self` to migrate exactly my registered
  repos with a per-repo All/Yes/No/Cancel confirmation and no scan, so upgrade is
  controlled and bounded.

## Priority

Must (Priority 2 — the coherent model)

## Acceptance Criteria

- [ ] Given any `aid` invocation, when it discovers repos, then it performs no
  machine-wide filesystem scan — discovery is cwd-driven and registry-driven only (AC2).
- [ ] Given a global install with both tiers populated, when the CLI reads the
  registry, then it returns the union of user (`~/.aid/registry.yml`) and shared
  (`$AID_STATE_HOME/registry.yml`) registries; for a per-user install the two
  collapse to one file (FR4, AC6 partial).
- [ ] Given a registry write that needs elevation, when the user declines or there
  is no TTY, then the CLI skips registration, warns, and still operates; no
  read-only command force-prompts `sudo` merely to index (FR4, AC6).
- [ ] Given a registry read, when a registered repo has been deleted or moved,
  then the stale entry is pruned quietly (FR4).
- [ ] Given the A/B/C dispatch matrix, when a command runs, then it follows the
  matrix: self-commands machine-scoped; `aid add` registers per the B-table
  (errors on unwritable folder, asks shared-vs-user on global outside `~`); repo
  commands register per the C-table; the "always ask on a real decision" and
  no-hard-refuse (missing `.aid/` = offer; git optional) rules hold (FR5).
- [ ] Given `aid update self`, when it migrates, then it migrates exactly the
  registered repos (union of both tiers) with per-repo All/Yes/No/Cancel
  confirmation and performs no scan; unregistered repos are left to the lazy
  per-repo stamp (FR6, AC5).
- [ ] Given `bin/aid` and `bin/aid.ps1`, when the registry/dispatch logic changes,
  then they remain at parity and ASCII-only (AC8).

> **Cross-cutting NFRs (apply to all ACs):** bash/ps1 parity, ASCII-only shipped
> scripts (CI-enforced), least-privilege (no `sudo` to read/index), no data loss.
> Out of scope: concurrency control for racing privileged writers on the shared
> registry beyond atomic set-insert / prune.
>
> **Dependencies:** feature-001 (state-home split — registry paths and scope),
> feature-002 (shared `/var/lib/aid` registry for the shared tier), feature-003
> (the per-repo stamp — FR6 registry migration writes the stamp and unregistered
> repos fall back to it). Consumes `_aid_priv_run` and the channel-aware
> `update self` from PR #78 (gated to master first; this work adds the
> registry-migration step on top).

---

## Technical Specification

### Approach

This feature converts the single-tier, machine-scanning discovery layer into a
two-tier, cwd-driven one. Three mechanisms, all in `bin/aid` (bash) and
`bin/aid.ps1` (PowerShell):

1. **Registry union + quiet prune (read path).** Replace the single
   `${AID_HOME}/registry.yml` read with a *union of two tiers*: the user
   registry (`~/.aid/registry.yml`, always present/writable) and — for global
   installs only — the shared registry (`$AID_STATE_HOME/registry.yml`,
   world-readable). The current reader `_registry_read_repos <reg-path>`
   (bin/aid:1190-1196) stays a single-file primitive; a new
   `_registry_read_union` calls it once per existing tier, concatenates,
   `sed '/^$/d' | sort -u` (the dedup idiom already used at bin/aid:1222),
   then **prunes stale entries quietly**: a path is emitted only if its
   `.aid/` still exists (`[[ -d "$p/.aid" ]]`). A moved/deleted repo is simply
   dropped from the returned set; no warning, no error (FR4; AC: prune-on-read).
   Pruning the *file* is best-effort and only attempted on the user tier (see
   write path) — read never mutates the shared tier.

2. **Write-tier selection + best-effort elevation (write path).**
   `registry_register <canon-path>` (bin/aid:1202-1235) is parameterized with a
   target tier. Default writes go to the **user** tier (`~/.aid/registry.yml`) —
   never needs elevation, so the existing temp+`mv -f` body is unchanged except
   for the path. A **shared** write (global install, user chose "shared") routes
   the same temp-write+`mv -f` through `_aid_priv_run` (from PR #78, a GIVEN):
   if the probe shows the shared dir is user-writable, write directly; else
   elevate. If elevation is declined or there is no TTY, **skip + warn + return
   0** (the function already returns 0 on every failure path, bin/aid:1213,1227,
   1232 — that contract is preserved and extended to the elevation-declined
   case). Registration never blocks the host command (FR4; decision #2; AC6).

3. **cwd-driven dispatch decision tree (no scan).** A single dispatch
   entry, evaluated once per invocation before the command body, classifies the
   invocation into the A/B/C matrix (see Dispatch matrix below) and decides:
   register-or-not, which tier, whether to ask, whether to offer setup/update.
   The `$HOME`-walking scan (`_aid_scan_for_repos`, bin/aid:1680) and the
   sentinel/marker plumbing are **removed** (FR8, owned by feature-001/003;
   this feature consumes their removal and must not reintroduce a scan — AC2).

### On-disk layout

| Tier | Path | Owner / writability | Present when |
|---|---|---|---|
| User registry | `~/.aid/registry.yml` | current user, always writable | always |
| Shared registry | `$AID_STATE_HOME/registry.yml` (= `/var/lib/aid/registry.yml`) | root, world-readable; writes elevate | global install only |

- **Per-user install:** `$AID_STATE_HOME == ~/.aid` (feature-001), so the two
  paths are the **same file** — the union degenerates to one tier, no shared
  read, no elevation ever. The two-tier code path is a strict superset.
- **Schema (unchanged):** `schema: 1` header + `repos:` list of canonical
  absolute paths, two-space-indented `  - <path>` items, sorted, deduped
  (bin/aid:1219-1223). Both tiers use the identical schema; backward compatible
  with the single-tier file shipped in v1.0/v1.1.
- **Union semantics:** result = `sort -u` of (user repos ++ shared repos), with
  any path whose `.aid/` no longer exists dropped. **No precedence conflict is
  possible** — entries are bare paths (a set), not keyed records, so a path in
  both tiers collapses to one. The dashboard repo list consumes the union.
- **Write precedence:** a repo is recorded in exactly one tier (the tier chosen
  at registration time). `registry_unregister` (bin/aid:1241-1273) removes from
  the tier it is found in; if (pathologically) present in both, it is removed
  from each tier it can write.

### Dispatch matrix (design §4 → shell control flow)

A new classifier runs before any command body. Pseudocode (bash; ps1 identical
shape). `cwd` = `$(pwd)`; `in_home` = cwd is under `$HOME`; `global` = scope
from feature-001 (`AID_CODE_HOME` not user-writable); `has_aid` =
`[[ -d "$cwd/.aid" ]]`; `registered` = union contains canonical cwd;
`stale` = repo `format_version` < `AID_SUPPORTED_FORMAT` or absent (feature-003).

**A. Self-commands — `update self` / `remove self` (cwd-independent):**
These bypass the classifier entirely (matched at bin/aid:1990-2008 / the
`remove self` block at 2011-2017). No cwd repo logic. `update self` runs its
channel-aware self-update (PR #78), then the **registry migration** step
(Behavior c). `remove self` is unchanged by this feature.

**B. `aid add [tool]` — install into cwd + register:**
At the add dispatch (registration today at bin/aid:2315), replace the
unconditional `registry_register "$_AID_TARGET"` with the B-table:

| `global` | `in_home` | folder writable | "add as shared?" answer | action |
|---|---|---|---|---|
| any | yes | (own) | — | install; register → **user** (silent) |
| no (per-user) | no | yes | — | install; register → **user** (silent) |
| no (per-user) | no | **no** | — | **error + abort** (decision #3) |
| yes (global) | no | yes | **yes** | install; register → **shared** (elevate write, best-effort) |
| yes (global) | no | yes | **no** | install; register → **user** |
| yes (global) | no | **no** | — | **error + abort** (never elevate `.aid/` creation, decision #3) |

The "add as shared?" prompt fires **only** on the `global && !in_home &&
writable` row (the one real decision — #4); every other row is silent. The
unwritable-folder rows error *before* any `.aid/` is created (the writability
check precedes install; `aid add` never `mkdir`s a root-owned `.aid/`).

**C. Repo-commands — bare `aid`, `status`, `update`, `dashboard`:**
At the repo-command entry (the dispatch fall-through after self/add handling),
run the classifier:

| `has_aid` | `in_home` | `global` | `registered` | `stale` | action |
|---|---|---|---|---|---|
| yes | yes | any | no | no | register → user (silent); operate |
| yes | yes | any | no | yes | register → user; **warn + offer `aid update`**; operate |
| yes | any | any | yes | no | operate |
| yes | any | any | yes | yes | **warn + offer `aid update`**; operate |
| yes | no | yes (global) | no | either | **ask** shared-vs-user → register chosen tier (shared elevates, best-effort); if stale: offer update; operate |
| yes | no | no (per-user) | no | either | register → user (silent); if stale: offer update; operate |
| **no** | any | any | — | — | **not an error**: print `no AID project here -- set it up? (aid add)`; if cwd is not a git repo, add the note that `.aid/` will not be version-controlled; **operate is a no-op / exit 0** |

Two cross-cutting rules baked into the table (decisions #4, #5):
- **Always ask on a real decision (#4):** the only prompt is the
  `global && !in_home && !registered` shared-vs-user ask. In-`~` registration is
  silent (unambiguous → user tier). Stale ⇒ *offer* update (prompt), never
  auto-migrate.
- **No hard refuse / git optional (#5):** missing `.aid/` is an offer, not an
  error (last row). A non-git folder still operates; it only gets a
  no-persistence note (cannot version-control `.aid/`). The *only* hard refusals
  are the B-table unwritable-folder rows (genuine access failure) and the
  feature-003 fail-safe (`format_version > AID_SUPPORTED_FORMAT`).

### Affected components

| Component | bash (`bin/aid`) | PowerShell (`bin/aid.ps1`) | Change |
|---|---|---|---|
| Single-tier read primitive | `_registry_read_repos` :1190-1196 | `Get-RegistryRepos` :1215-1226 | Unchanged (per-file primitive) |
| **Union read (NEW)** | `_registry_read_union` (new) | `Get-RegistryUnion` (new) | Reads both tiers, dedup, quiet-prune stale (`-d .aid` check) |
| Register (write) | `registry_register` :1202-1235 | `Registry-Register` :1230-1259 | Add tier param; bash shared tier routes write via `_aid_priv_run`; ps1 has no elevation wrapper (writes directly; npm/pipx surface their own error, caller elevates its shell); both skip+warn+return 0 on a failed/declined shared write |
| Unregister | `registry_unregister` :1241-1273 | `Registry-Unregister` :1265+ | Remove from tier(s) where found |
| **`update self` migration source (SWAP)** | call site :2004 (`_aid_scan_and_migrate`); fn :1778-1879 | call site :1897 (`Invoke-AidScanAndMigrate -ApplyAllFlag $usMigrateYes -ScanRoot $usRoot`, the update-self dispatch twin of bash :2004); fn :1770+ — NOT the FF-3 preamble call at :335 | **Replace** scan-based source with iteration over `_registry_read_union`; keep the All/Yes/No/Cancel walk (:1828-1871), drop scan + marker writes |
| Scan (REMOVE) | `_aid_scan_for_repos` :1680, `_aid_scan_and_migrate` scan calls :1797-1804 | `Invoke-AidScanForRepos` :1615, :1786 | Removed by feature-001/008; this feature must not call them |
| `aid add` registration | call site :2315 | call site (add handler) | Replace unconditional register with B-table (tier select + shared-vs-user ask + unwritable-folder error) |
| Repo-command dispatch entry | fall-through after self/add (post :2008) | post self/add handler | NEW classifier implementing C-table (register-on-encounter, ask, offer-update, missing-`.aid/` offer) |
| Dashboard auto-register | :1109, :1117 | :1014, :1021 | Now routes through tier-aware `registry_register` (user tier by default) |

### Behavior / Flow

**(a) Repo-command register-on-encounter.** On bare `aid` / `status` / `update`
/ `dashboard`:
1. Classify cwd (has_aid, in_home, global, registered, stale).
2. If `!has_aid` → print the offer (`aid add`) + optional non-git note; exit 0.
3. If `!registered`: pick tier — `global && !in_home` ⇒ **ask** shared-vs-user;
   else ⇒ user (silent). Call `registry_register <canon-cwd> <tier>` (best-effort:
   declined elevation / no-TTY ⇒ skip + warn, still continue).
4. If `stale` → warn + offer `aid update` (the user may decline; the command
   still operates on the current repo — registry is an INDEX, never a gate, AC2).
5. Operate.

**(b) `aid add` shared-vs-user.** After a successful install into cwd:
1. Determine writability of cwd's parent (the install already proved cwd
   writable; the unwritable rows error before install).
2. If `global && !in_home && writable` → prompt `Add this repo to the shared
   machine registry? [y/N]`. Yes ⇒ shared tier (elevate write, best-effort);
   No ⇒ user tier. All other rows ⇒ user tier silently.
3. Register via the tier-aware `registry_register`.

**(c) `update self` migrate-over-registry.** After the channel-aware self-update
(PR #78) completes at the :2004 call site:
1. Build the candidate set from `_registry_read_union` (**no scan**; the union
   already drops stale/moved paths).
2. For each candidate, run the existing All/Yes/No/Cancel consent walk
   (bin/aid:1828-1871, reused verbatim), calling `_aid_migrate_repo` on Yes/All.
3. No `.migrated` marker write (the marker is removed, feature-001/003);
   migration-done state is the per-repo `format_version` stamp (feature-003).
   Unregistered repos are NOT migrated here — they are caught lazily on next
   visit by the feature-003 stamp comparison (decision #1; AC5).

### Edge cases & fail-safes

- **Shared write denied / no elevation / no TTY:** `registry_register` to the
  shared tier degrades to skip + warn + `return 0`; the host command proceeds
  (AC6; decision #2). Same for the union read — it never attempts a shared write.
- **No-TTY non-interactive run:** the shared-vs-user ask (B/C) cannot prompt ⇒
  default to **user tier** silently (the safe, always-writable choice); never
  block. `update self`'s All/Yes/No/Cancel walk keeps its existing non-TTY
  opt-in behavior (`--yes` / `AID_MIGRATE_YES=1`); without opt-in, no migration
  is forced.
- **Stale / moved repo:** dropped from the union on read (quiet prune); the
  user-tier file is rewritten to drop it on the next user-tier write (best-effort;
  shared tier pruned only when a shared write is already elevating).
- **Registry is an INDEX, never required (AC2):** every single-repo command
  operates on cwd's `.aid/` directly; if both registries are empty/absent the
  command still works. Registration failure never changes the command's exit code.
- **Duplicate paths:** collapsed by `sort -u` at both read (union) and write
  (set-insert). A path present in both tiers appears once in the union.
- **Empty / absent registry file:** `_registry_read_repos` already returns
  empty on a missing file (bin/aid:1192) — the union of two absent tiers is the
  empty set; `update self` then reports "no registered repos to migrate" and
  exits 0.
- **Non-git folder:** operates normally; only emits the no-persistence note
  (decision #5). Not a blocker.

### bash ↔ ps1 parity

The A/B/C matrix, tier selection, prune-on-read, and the migrate-over-registry
flow are **identical** across `bin/aid` and `bin/aid.ps1`. Windows has no
`sudo` and PR #78 ships **no ps1 elevation wrapper** (no `_aid_priv_run` twin
exists): the shared tier still applies, but the ps1 write is attempted directly
— if the privileged location is not writable the underlying tool surfaces its
own error and the caller elevates its own shell (bin/aid.ps1:350-351, :2002), so
the ps1 shared write degrades to the same skip + warn + return-0 contract as the
bash `_aid_priv_run`-declined path (no symbol is named on the ps1 side because
none exists). All new strings and the consent prompts are **ASCII-only**
(CI-enforced; per memory note on ASCII-only shipped scripts). The ps1
`Invoke-AidScanAndMigrate` (:1770) is reworked to read the union, mirroring the
bash swap; its update-self call site is :1897 (the twin of bash :2004), not the
FF-3 preamble call at :335.

### Testing

Canonical assertions (HOME-pinned; throwaway `$HOME` and `$AID_STATE_HOME` per
the AID-scan-safety memory note):

1. **Union read:** populate user tier with repo A and shared tier with repo B;
   assert the union returns {A, B}; assert a path in both tiers appears once.
2. **Per-user collapse:** with `$AID_STATE_HOME == ~/.aid`, assert no shared
   read occurs and the result equals the single-file read (backward compat).
3. **Best-effort write degrade:** simulate an unwritable shared tier (and a
   `_aid_priv_run` that declines); assert `registry_register --shared` warns,
   returns 0, and the host command still completes (AC6).
4. **NO scan anywhere (AC2):** assert `_aid_scan_for_repos` /
   `Invoke-AidScanForRepos` is not defined/called; grep the dispatch paths for
   any `$HOME`-walk; a canary repo outside the registry is never touched.
5. **`update self` migrates exactly registered repos (AC5):** register A and B,
   leave C unregistered; run `update self --yes`; assert A and B are migrated
   (stamped) and C is untouched.
6. **Dispatch-matrix rows:** table-driven cases for each A/B/C row — silent
   in-`~` register, global-outside-`~` shared-vs-user ask, unwritable-folder
   `aid add` error, missing-`.aid/` offer (exit 0, not error), non-git note,
   stale ⇒ offer-update.
7. **Prune-on-read:** register a repo, delete its `.aid/`, assert the union
   drops it quietly (no warning, no error).
8. **Parity:** the ps1 suite mirrors 1-7; ASCII-only lint passes.

### Backward compatibility

- A single-tier `registry.yml` written by v1.0/v1.1 (same `schema: 1` +
  `repos:` shape) **reads cleanly as the user tier** — no migration of the
  registry file is needed; the union of {legacy user file} + {absent shared} =
  the legacy contents (minus quietly-pruned stale paths).
- The `AID_HOME` env override continues to redirect state (feature-001), so
  existing HOME-pinned tests that point `AID_HOME` at a throwaway dir continue
  to find the (now user-tier) registry there.
- No machine marker is read or written; an upgrader mid-flight is never
  stranded by a missing `.migrated` or a missing `/var/lib/aid` (the shared tier
  is simply absent ⇒ union falls back to the user tier).
