# task-003: bash helpers — raw union, tier resolver, project-state

**Type:** IMPLEMENT

**Source:** feature-001-projects-command → delivery-001

**Depends on:** — (none)

**Scope:** Add three reusable bash helpers in `bin/aid` (per SPEC §Layers A):
- **`_registry_read_raw_union`** — mirrors `_registry_read_union` (`~1313-1330`) but **omits** the `[[ -d "$p/.aid" ]]` quiet-prune (`~1326-1329`), returning every registered path (deduped union of `$AID_STATE_HOME` + `$HOME/.aid` tiers, with the per-user collapse). Leave the pruning `_registry_read_union` intact for its existing callers.
- **`_aid_resolve_tier <canon-path>`** — deterministic, non-interactive: returns `user` if `_AID_SCOPE != global` OR the path is under `$HOME`; else `shared`. Honors `--local`/`--shared` override; `--shared` under a per-user install returns `user` and emits a "no shared tier" notice.
- **`_aid_project_state <path>`** — prints `vX.Y.Z` (manifest/`.aid-version` present), `untracked` (`.aid/` present, no manifest), `no-aid` (folder exists, no `.aid/`), or `missing` (folder absent); plus a helper reading the tool list from `<path>/.aid/.aid-manifest.json`.
- ASCII-only; re-anchor by symbol name.

**Acceptance Criteria:**
- [ ] `_registry_read_raw_union` returns paths whose `.aid/` is absent/missing (NOT pruned), and equals `_registry_read_union` minus the prune on a fixture set.
- [ ] `_aid_resolve_tier` matches the FR6 table for all cases (per-user → user; global+under-home → user; global+outside-home → shared; `--local`/`--shared` overrides; `--shared` under per-user → user + notice).
- [ ] `_aid_project_state` returns the correct enum value for each of the four fixtures (versioned manifest, no manifest, no `.aid/`, missing dir).
- [ ] ASCII-only; `bin/aid` parses/runs.
- [ ] All §6 quality gates pass.
