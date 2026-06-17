# Requirements — work-002-projects-command

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-16 | Created from settled design discussion | /aid-interview |
| 2026-06-16 | Corrected tier model (scope-gated + per-user collapse), raw-read for list, 3-language key migration, added missing ACs | A+ review (12 findings) |
| 2026-06-16 | SPEC-phase code check: readers are key-agnostic (no reader migration needed); "you are here" marker is ASCII `*` not `▸` (NFR3) | /aid-specify |

## 1. Objective

Add a first-class `aid projects` command that lets a user **inspect and manage the set of projects registered with AID** — the directories AID tracks (those containing a `.aid/` folder). Today the registry is only ever mutated as a side-effect of `aid add` / `aid update` / `aid dashboard`, and the only way to *see* it is the graphical bare-`aid` dashboard. There is no text listing and no way to add/remove a registry entry directly.

## 2. Problem Statement

The registry plumbing (`registry_register`, `registry_unregister`, `_registry_read_union`, the `$AID_STATE_HOME` ∪ `$HOME/.aid` store) is fully built but **unexposed**. Real consequences observed while dogfooding on `SRVRIVIND01`:

- A wrong entry — the state-home directory itself, registered as if it were its own project — had to be **removed by hand-editing `registry.yml`** (there is no command to inspect or repair the registry).
- Building a fleet inventory (which projects exist, at what AID version, tracked vs untracked) required a manual, ad-hoc investigation.
- Tier assignment when AID auto-registers a project is **inconsistent across call sites**: `aid add`/cwd classification runs a scope-and-location-gated *interactive* prompt, while the `aid dashboard` and migrate side-effects always write the user tier — so the same project can land in different tiers depending on how it was first touched.

There is no supported, scriptable way to do any of this.

## 3. Users & Stakeholders

- **AID maintainers / operators** managing many projects on one machine (the primary user — fleet view + cleanup).
- **Individual developers** who want to see/curate which of their projects AID tracks.
- **The dashboard server** (`dashboard/server/server.py`), indirectly — it consumes the same registry file.

## 4. Scope

**In scope:** a new top-level `aid projects` command with sub-actions `list` (default), `add`, `remove`, `help`; a live project-state listing; deterministic (non-interactive) tier selection by path location within what the install scope allows; cross-platform parity (bash + PowerShell); reconciling existing auto-registration call sites to the same deterministic rule (preserving the dashboard's never-elevate behavior); dropping "repo/repos" from the user-facing surface; and migrating the on-disk registry key `repos:`→`projects:` across **all three** readers (bash, PowerShell, and the Python `load_registry` parser) and all writers, with legacy back-compat.

**Out of scope:** changing what `aid add`/`aid remove` do to *tools* (this command manages *tracking only*, never installs/removes tools); the dashboard's **HTML/UI** rendering (the server's registry *parsing* IS in scope, its presentation is not); a registry garbage-collector beyond surfacing stale entries (a `prune` action is a possible later addition, not required here); cutting the release.

## 5. Functional Requirements

- **FR1 — Command surface.** A new top-level command `aid projects [list|add|remove|help] [path] [flags]`. Bare `aid projects` ⇒ `list`. `aid projects -h|--help` and `aid projects help` print usage.

- **FR2 — "Project", not "repo"; writer key migration.** A *project* is any directory containing a `.aid/` folder (git is irrelevant). All user-facing output (including the ~16 WARN/message strings in `bin/aid`/`bin/aid.ps1`), help, and the registry's own header comment use "project(s)" instead of "repo/repos" when referring to an AID-tracked directory or the registry. **Retained** (not swept): the literal phrase "git repository" (it describes git, not the AID-project concept), the internal `__migrate-repo` token, variable names, and the dashboard server's JSON `repos` field (an API boundary). The on-disk registry key migrates `repos:` → `projects:`:
  - **Readers need no change — they are already key-agnostic.** Bash `_registry_read_repos`, PowerShell `Get-RegistryRepos`, and the Python `load_registry` all parse list **items** by regex (`^  - <path>`) and ignore the section key, so they read both `projects:` and legacy `repos:` files identically. (The requirement "both keys are read" is satisfied with no reader edit.)
  - **All writers emit `projects:`** (the 6 emitters in `bin/aid`, 1 in `lib/aid-install-core.sh`, 2 in `bin/aid.ps1`, 1 in `lib/AidInstallCore.psm1`); the seed header comment changes "machine repo registry" → "machine project registry".
  - **Lazy migration:** a legacy-keyed file is transparently re-keyed to `projects:` on its next write; because writers always emit a single canonical key, a file is never left mixed-key, and because readers are key-agnostic, no machine ever holds an unreadable file at any point.

- **FR3 — `list` (default) with two indicators, over a RAW read.** Prints every registered project. It MUST read the **raw union of registry entries** (both tiers, deduped) — NOT `_registry_read_union`, which quiet-prunes any entry whose `.aid/` is absent and would therefore hide the `no-aid`/`missing` states. For each entry, state is computed live at render time:
  - **Indicator A — state:** one of `vX.Y.Z` (tracked: `.aid/.aid-manifest.json` present, version read from it / `.aid/.aid-version`) · `untracked` (`.aid/` present, no manifest) · `no-aid` (folder exists, `.aid/` absent) · `missing` (folder does not exist).
  - **Indicator B — "you are here" marker:** marks the entry matching the current directory with an **ASCII** marker (`*` in a leading marker column; shipped scripts are ASCII-only per NFR3 — no non-ASCII glyphs). The match uses the **same canonicalization the registry uses** (`cd && pwd`, i.e. canonical absolute path) so symlinked/relative cwd still matches.
  - **Columns:** marker · path · state · **tools** (read live from each project's `.aid/.aid-manifest.json`; the registry stores folder paths only) · tier. If the cwd *is* an AID project but is **not** in the registry, footnote it (`(here) — not registered; run 'aid projects add'`).

- **FR4 — `add [path]`.** Register an existing AID project (default: cwd) **without installing or modifying any tools**. Validate the target contains `.aid/`; refuse with a clear message otherwise (this also prevents registering a non-project root such as a bare home directory). Idempotent.

- **FR5 — `remove [path]`.** Unregister a project (default: cwd) — stop tracking it / drop it from the dashboard — **without uninstalling AID or touching the folder**. Works on `no-aid`/`missing`/stale entries too (so a bad entry like an accidentally-registered state-home can be repaired). Idempotent (removing an unregistered path is a no-op with a clear message).

- **FR6 — Deterministic tier by location, within install scope.** Tier selection is driven by install scope (`_AID_SCOPE`) and path location, with **no interactive prompt**:
  - Under a **per-user install** (`_AID_SCOPE == user`, where `AID_STATE_HOME == $HOME/.aid`) there is **only the user tier**; every project is user-tier. `--shared` is a no-op that prints a notice ("no shared tier under a per-user install").
  - Under a **global install** (`_AID_SCOPE == global`), tier is derived from the canonical path: **outside** the user's home ⇒ **shared** tier (`$AID_STATE_HOME`), **under** home ⇒ **user** tier (`$HOME/.aid`). This replaces the current interactive y/N prompt.
  - `--local` / `--shared` override the automatic choice where the scope permits.
  - Shared-tier writes reuse the existing elevation probe and **degrade to the user tier with a notice** when elevation is unavailable; the command reports the tier it **actually** wrote.

- **FR7 — Reconcile auto-registration to the same rule (preserving never-elevate).** The existing auto-registration sites adopt FR6's deterministic rule:
  - `aid add` / cwd classification (`_aid_cwd_classify`): the interactive shared-vs-user prompt is **replaced** by the deterministic location rule (no behavior regression — it already gated on scope+location, only the prompt is removed).
  - `aid dashboard` auto-register: adopts the location rule but **preserves its deliberate never-elevate behavior** — a shared write that would require elevation degrades silently to the user tier (it must never prompt during a render).
  - the migrate side-effect: uses the location rule.

- **FR8 — PowerShell parity.** Identical command, sub-actions, output shape, state enum, and tier rule in `bin/aid.ps1` / `lib/AidInstallCore.psm1` (Windows has no elevation prompt; the per-user/global distinction and degrade still apply).

- **FR9 — Help/usage updated.** The top-level `aid` usage block (bash `_aid_usage`, PowerShell `Show-AidUsage`) lists `projects`, and a per-command `aid projects -h` block is added in both.

## 6. Non-Functional Requirements

- **NFR1 — Tracking-only / non-destructive.** The command never installs, removes, or edits tools or any file inside a project; it only mutates the registry. `list` never writes.
- **NFR2 — Cross-platform parity.** bash and PowerShell behave identically (same states, same tier rule, same exit codes).
- **NFR3 — ASCII-only** shipped scripts (`bin/aid`, `bin/aid.ps1`, libs).
- **NFR4 — Atomic + idempotent** registry writes (reuse the existing atomic-write helpers in `registry_register`/`registry_unregister`).
- **NFR5 — Graceful degrade** when the shared store is unwritable (no hard failure; notice + user-tier fallback).
- **NFR6 — Back-compat** with existing `registry.yml` files: all three readers accept the legacy `repos:` key (FR2).
- **NFR7 — Reuse**, not reimplement, the existing registry plumbing; `add`/`remove` route through `registry_register`/`registry_unregister`.

## 7. Constraints

- Reuse `registry_register` / `registry_unregister` (bash) and `Registry-Register` / `Registry-Unregister` (PowerShell) for writes; for `list`, use a raw read of registry entries (NOT the pruning `_registry_read_union`).
- "One version for all tools": this ships as a unified **1.2.0** release; it must NOT be folded into the 1.1.0 bug-fix release.
- Adding a command causes "N commands" count drift across help/KB docs — reconciled via `/aid-housekeep` (CI does not catch it; precedent: skill-count drift).

## 8. Assumptions & Dependencies

- The fixed 1.1.0 CLI (PR #83) is the baseline; this builds on it.
- The `_AID_SCOPE` / `AID_STATE_HOME` scope model and the `$AID_STATE_HOME` ∪ `$HOME/.aid` union (work-001) are in effect; SRVRIVIND01's current global install means the shared tier is exercised there.
- The Python dashboard reader (`dashboard/server/server.py load_registry`) is a registry consumer and is in scope for the key migration (FR2).
- Windows installer CI (`tests/windows/Test-AidInstaller.ps1`) is the ONLY gate for PowerShell behavior; it must be extended in lockstep.

## 9. Acceptance Criteria

- [ ] **AC1 (list):** `aid projects` / `aid projects list` prints every registered project from a **raw** read (no prune), each with state ∈ {`vX.Y.Z`,`untracked`,`no-aid`,`missing`} computed live, a `tools` column read from each project's manifest, a `tier` column, and an ASCII `*` marker on the canonical-cwd match; an unregistered-but-AID cwd is footnoted.
- [ ] **AC2 (add):** `aid projects add [path]` registers an existing `.aid/` project without installing tools; rejects a path lacking `.aid/` (incl. a bare home/state-home root) with a clear message; is idempotent.
- [ ] **AC3 (remove):** `aid projects remove [path]` unregisters without touching tools/files; succeeds on `no-aid`/`missing`/stale entries (repairs a bad registration); is idempotent.
- [ ] **AC4 (tier — per-user):** under a per-user install, every project registers user-tier and `--shared` prints a "no shared tier" notice; no prompt is shown.
- [ ] **AC5 (tier — global):** under a global install, tier is derived from location (outside `$HOME` ⇒ shared, under ⇒ user) with no interactive prompt; `--local`/`--shared` override; a shared write that can't elevate degrades to user-tier with a notice, and the command prints the tier actually written.
- [ ] **AC6 (reconcile):** the cwd-classify prompt is removed in favor of the deterministic rule; `aid dashboard` auto-register still never elevates (degrades silently); behavior is consistent across add/update/dashboard/migrate.
- [ ] **AC7 (terminology + key):** no "repo/repos" in user-facing output/help or the registry header comment; readers (already key-agnostic) read both `projects:` and legacy `repos:` with no reader edit; all writers emit `projects:`; a legacy file is re-keyed on next write; existing tests asserting the old key/header are updated.
- [ ] **AC8 (parity + ASCII):** bash and PowerShell behave identically; shipped scripts are ASCII-only.
- [ ] **AC9 (tests):** covered by `tests/canonical/test-registry.sh` (raw-list + add/remove units), `tests/canonical/test-aid-cli-parity.sh` (bash↔PS parity for `projects`), and **`tests/windows/Test-AidInstaller.ps1`** (new `projects` test IDs) — the Windows suite extended in lockstep.
- [ ] **AC10 (help):** top-level `aid --help` and `aid projects -h` list/describe `projects` in both bash and PowerShell.
- [ ] **AC11 (count-drift):** no stale "N commands" counts remain in help/KB after adding `projects`; reconciliation routed through `/aid-housekeep` and verified (no dangling old counts in `feature-inventory.md` / `infrastructure.md` / file-header comments).

## 10. Priority

**Should** — high-value operability/UX gap with the plumbing already in place; ships in the next unified release (1.2.0) after the 1.1.0 fixes.
