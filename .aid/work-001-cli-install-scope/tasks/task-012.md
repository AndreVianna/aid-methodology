# task-012: Two-tier registry, A/B/C dispatch, update-self migration (PowerShell parity)

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-registry-and-dispatch → delivery-002

**Depends on:** task-011

**Scope:**
- `bin/aid.ps1` only — parity twin of task-010 + task-011. Per feature-004 "Affected components" (ps1 column) + "bash ↔ ps1 parity":
  - `Get-RegistryRepos` (`:1215-1226`) — unchanged single-file primitive.
  - **NEW `Get-RegistryUnion`** — read both tiers, dedup, quiet-prune stale (`-d .aid` equivalent), per-user collapse.
  - `Registry-Register` (`:1230-1259`) — add tier param; ps1 has no elevation wrapper (writes directly; the underlying tool surfaces its own error and the caller elevates its shell, `:350-351`/`:2002`); both tiers still degrade to skip + warn + return 0 on a failed/declined shared write.
  - `Registry-Unregister` (`:1265+`) — remove from tier(s) where found.
  - **`Invoke-AidScanAndMigrate` (`:1770`) rework** to read the union (mirror the bash swap); its update-self call site is `:1897` (the twin of bash `:2004`) — NOT the FF-3 preamble call at `:335`. Keep the All/Yes/No/Cancel walk; drop scan + marker writes.
  - B-table `aid add` registration + C-table classifier — ps1 twins of the bash dispatch (identical A/B/C matrix shape, tier selection, prune-on-read, migrate-over-registry flow).
  - Dashboard auto-register (`:1014,1021`) — route through tier-aware `Registry-Register`.
- Must not reintroduce `Invoke-AidScanForRepos` (`:1615`/`:1786`, removed in task-002).

**Acceptance Criteria:**
- [ ] `Get-RegistryUnion`, tier-aware `Registry-Register`, the B/C dispatch matrix, and the union-driven `Invoke-AidScanAndMigrate` reproduce the bash behavior (task-010 + task-011) at parity.
- [ ] The update-self migration is wired at `:1897` (not the `:335` FF-3 preamble); no scan / `Invoke-AidScanForRepos` is defined or called.
- [ ] ps1 shared write degrades to skip + warn + return-0 (matching the bash `_aid_priv_run`-declined contract) with no symbol named for a non-existent elevation wrapper.
- [ ] bash/ps1 parity holds and all new/edited lines are ASCII-only.
- [ ] All §6 quality gates pass.
