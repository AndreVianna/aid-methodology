# task-011: Complete-replacement migration — prune re-point and retired-root sweep (FR7/FR7a)

**Type:** MIGRATE

**Source:** work-005-profile-generator-simplify -> delivery-002

**Depends on:** -- (none; consumes delivery-001's manifest/bundle path-set seam — runs parallel to task-009/010, different files: the install engine, not CLI dispatch)

**Scope:**
- **Both twins.** Land every change in BOTH `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1` (+ vendored copies) with byte-equivalent semantics (C6 parity).
- **Re-point the marker-prune to the new layout (feature-002):** in `_prune_tool_dirs` (`aid-install-core.sh:1699-1728`) / `Invoke-PruneToolDirs` (`AidInstallCore.psm1:1139-…`), codex prunes `.codex/{agents,skills}` + `.codex/aid` (the unified root); **remove** the `.cursor/rules` and `.agent/rules` native-dir walks (those dirs no longer exist in the new bundle). The marker rules themselves (marker 1 = `aid-` prefix via `_prune_native_dir`; marker 2 = inside `aid/` via `_prune_aid_subtree`) are unchanged — only re-pointed.
- **Re-point `install_tool` copy dispatch:** in `install_tool` (`aid-install-core.sh:1776-1835`) / `Install-AidTool` (`AidInstallCore.psm1:1296-…`), codex copies only `.codex` (drop the `.agents` copy).
- **Add the retired-root sweep:** new `_migrate_retired_layout <target> <tool>` (bash) / `Invoke-MigrateRetiredLayout` (PS), keyed by a **static list of retired AID roots** (`.agents/` for codex, `.cursor/rules/`, `.agent/rules/`). For each retired path it removes AID-owned content under it (markers 1+2 — `aid-` prefix / inside `aid/`) then prunes the now-empty dir. Called from `install_tool` / `Install-AidTool` **BEFORE** `_prune_tool_dirs` / `Invoke-PruneToolDirs`, in the same `aid update` pass. Idempotent: a no-op when the retired path is absent. Lives in the install pass — NOT in `_aid_migrate_repo` (which migrates only `.aid/` metadata).
- **Keep `.agents` as the migration signal:** in `detect_tool` (`aid-install-core.sh:124-154`, the `.codex` OR `.agents` recognition at lines 129-130) / `Detect-Tool` (`AidInstallCore.psm1:126`), **retain** the `.agents` recognition (tolerant-keep) so an un-migrated codex repo still resolves to codex during the migrating `aid update`. NO removal in this task.
- **Summary counts:** add the retired-root removal count to the install/prune summary (`aid-install-core.sh:1730-1732` prune summary + the `install_tool` counts).
- **Manifest-seam entry-gate check (PLAN risk #3, the 001→002 seam):** before pruning, assert delivery-001's emitted bundle/staging path-set for the tool **omits** the retired roots (`.agents/`, `.cursor/rules/`, `.agent/rules/`). If a retired path leaked into the new bundle, **fail loudly** (do not prune against a contaminated manifest).
- **Out of scope:** the `aid update` / `aid add` command shape + version selection (task-009/010); marker #3 (`AID:BEGIN/END` region merge in `_copy_root_agent_file`) is unchanged; migration test fixtures (task-012/013).
- ASCII-only for both shipped scripts.

**Acceptance Criteria:**
- [ ] Retired roots (`.agents/`, `.cursor/rules/`, `.agent/rules/`) are removed only where the content is marker-owned (markers 1+2) AND absent from the new version's bundle path-set.
- [ ] User content is untouched: the marker-#3 `AID:BEGIN/END` region and all unmarked files are preserved byte-for-byte.
- [ ] The retired-root sweep is idempotent — a no-op when the retired roots are already absent (re-run produces no further mutation).
- [ ] `.agents` is **retained** in `detect_tool` / `Detect-Tool` as the migration signal (no removal in this task).
- [ ] The manifest-seam entry-gate check passes on a clean delivery-001 bundle and **fails loudly** if a retired path leaked into the new bundle.
- [ ] The retired-root removal count appears in the install/prune summary.
- [ ] bash + PowerShell parity for every changed/added function; both shipped scripts are ASCII-only.
- [ ] MIGRATE defaults: migration is reversible (replaceable via re-install / `--from-bundle`); migration is idempotent; data integrity verified (user content byte-identical, no stranded or duplicate AID trees).
- [ ] All §6 quality gates pass.
