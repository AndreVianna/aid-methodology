# task-001: Coordinated de-"repo" terminology sweep + key flip (all writers, all platforms)

**Type:** IMPLEMENT

**Source:** feature-001-projects-command → delivery-001

**Depends on:** — (none)

**Scope:**
- Flip every registry **writer** to emit `projects:` instead of `repos:` (readers are key-agnostic — DO NOT touch them). Per SPEC §Data Model + §Layers:
  - `bin/aid` — the 6 `repos:` emitters.
  - `lib/aid-install-core.sh` — the single emitter (`~1435`; `~1399` is a comment).
  - `bin/aid.ps1` — the 2 emitters (`~1401`, `~1511`).
  - `lib/AidInstallCore.psm1` — the single emitter (`~931`).
- Rewrite the **full 3-line seed header comment** at **every** emit site — `bin/aid` has **6** (`~1379`, `~1411`, `~1459`, `~1517`, `~1547`, `~1580`), plus `lib/aid-install-core.sh:1431-1433` and the PowerShell equivalents — to the SPEC-specified text: drop ALL "repo/repos" across all 3 lines and correct the version source (`L3`: name/description from `.aid/settings.yml`; version/tools from the manifest). (Backstop: `grep -c "machine repo registry" bin/aid lib/*.sh bin/aid.ps1 lib/*.psm1` → 0 after.)
- **Sweep the user-facing message strings** (bash + PS) per SPEC §Terminology rule: in every `printf`/`echo`/`Write-Host`/`Write-Error`/`Write-Warning` string that refers to an AID-tracked directory or the registry, change `repo`/`repos` → `project`/`projects` (e.g. "could not update the machine **repo** registry", "**repo** not registered in shared tier", "No registered **repos** to migrate", "Migrate **repo** X?", "manage AID across your **repositories**"). **Retain** literal `git repository`, the `__migrate-repo` token, and variable names (`$repo`, `_canon_repo`, `$Repo`).
- **Do NOT edit either tier-prompt region** — bash `_aid_cwd_classify` (`~2152`) and the `aid add` B-table prompt (`~2754`), and their PS counterparts (`~1315`/`~2609`). Both prompts are *removed* by the FR7 reconcile (task-005 bash / task-007 PS); leaving them avoids a parallel-edit conflict on those regions.
- Re-anchor by symbol name (lines shift). ASCII-only edits.

**Acceptance Criteria:**
- [ ] Every writer emits `projects:` (no `repos:` emitter remains in `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`).
- [ ] No "repo"/"repos" remains in any seed header comment line (all 3 lines, all sites); the version-source line names the manifest.
- [ ] `grep -nE '[Rr]epo' bin/aid bin/aid.ps1 lib/aid-install-core.sh lib/AidInstallCore.psm1` shows every remaining hit is a retained category only (`git repositor*`, `__migrate-repo`, variable identifiers) — no user-facing "repo/repos" referring to a project/registry.
- [ ] Registry **readers** (`_registry_read_repos`, `Get-RegistryRepos`, Python `load_registry`) are unchanged.
- [ ] All four scripts parse/run; edits are ASCII-only (passes `tests/canonical/test-ascii-only.sh`).
- [ ] All §6 quality gates pass.
