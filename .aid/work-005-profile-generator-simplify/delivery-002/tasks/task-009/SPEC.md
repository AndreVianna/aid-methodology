# task-009: Single `aid update` command shape, stage-all-first atomicity, and `--dry-run`

**Type:** IMPLEMENT

**Source:** work-005-profile-generator-simplify -> delivery-002

**Depends on:** -- (none; cross-delivery — consumes delivery-001's new layout + per-version bundle path-set)

**Scope:**
- **Both twins.** Land every change in BOTH `bin/aid` + `bin/aid.ps1` (CLI dispatch/usage) with byte-equivalent semantics (C6 parity). No bash-only or PS-only behavior.
- **Remove the per-tool positional on `update`** (FR10): in `_resolve_tools_for_aid` (`bin/aid:2971-3008`) and its PS twin `Resolve-AidToolList` (`bin/aid.ps1:2898-2934`), `update` always resolves to `manifest_list_tools` — never a positional. Any non-flag positional on `aid update` other than `self` is a usage error → **exit 2**. (`aid update self ...` is UNCHANGED.)
- **Two modes (FR10):**
  - **Outside an AID repo** (`_aid_is_project_dir <target>` false): update the **CLI only** to latest via the existing `_cmd_update_self` / `_aid_update_self_if_stale` path; **no-op if already latest** (print "CLI is current (vX)", exit 0). Replaces today's `_aid_cwd_no_aid_offer`-and-exit (`bin/aid:2909-2914`). NO tool loop.
  - **Inside an AID repo** (`_aid_is_project_dir <target>` true): **CLI-first** (existing `_aid_update_self_if_stale` preamble, `bin/aid:2919-2921`), THEN advance all `tools.*` in the repo manifest to ONE version V in a single pass.
- **Stage-all-first atomicity (FR11):** split today's interleaved per-tool loop (`bin/aid:3130-3135`, where `_prepare_tool_staging_aid` + `install_tool` alternate per tool). Resolve target V once → **stage ALL tools** (`_prepare_tool_staging_aid` / `Prepare-AidToolStaging`, fetch + checksum-verify + extract to temp) BEFORE any `install_tool` commit → then run all commits. A fetch/checksum/extract failure aborts with **zero destination mutation**.
- **`--dry-run` (NEW on the main path):** add the shared `_AID_DRY_RUN` flag to the **shared add/update argument parser** (`bin/aid:2859-2885`) + PS twin parser. When set, print the full plan — every tool that would update, every file copied/updated, every AID-owned path pruned/replaced — then exit 0 with **no filesystem change**. (Today `--dry-run` exists only on `update self`/`remove self`, `bin/aid:692,2696`.) The parser flag is shared so `aid add` inherits it (task-010 does not re-plumb it).
- **Mid-commit failure contract:** on any commit-phase (`install_tool`) failure, exit **non-zero** with a brief clear message + re-run-to-heal guidance (e.g. "ERROR: aid update failed mid-commit; repo may be at mixed versions. Re-run `aid update` to heal."). NO rollback machinery and NO per-tool inconsistent-state enumeration — `aid update` is idempotent/re-entrant.
- **Wire the 5 args** through the update path: `--version <v>` pins ALL tools (and the self-update target) to V, mutually exclusive with `--from-bundle` (existing rule, `bin/aid:2926-2929`); `--target <dir>` (existing `_AID_TARGET`, the outside/inside decision is made against `<dir>`); `--from-bundle <path>` (offline source, existing `_prepare_tool_staging_aid`); `--force` (existing `_AID_FORCE`; does NOT change prune authority); `--dry-run` (above).
- **Update usage text** (`_aid_usage update`, `bin/aid:130-156`, + PS `Show-AidUsage`): remove `[<tool>...]` from `aid update`; add `--dry-run`.
- **Out of scope:** the prune re-point / retired-root sweep / `install_tool` copy-dispatch changes (task-011, runs parallel — different files); the `aid add` FR11 version-selection rule (task-010); migration test fixtures (task-012/013).
- ASCII-only for both shipped scripts (Windows ANSI-codepage parse safety).

**Acceptance Criteria:**
- [ ] `aid update <tool>` (any non-`self` positional) exits **2** (usage error) in both twins; `aid update self ...` is unchanged.
- [ ] Outside an AID repo, `aid update` updates the **CLI only** (no tool loop) and is a no-op when already latest.
- [ ] Inside an AID repo, `aid update` updates the CLI first, then advances **every** `tools.*` to one version V; the post-condition is all `tools.*.version == V`.
- [ ] `--version <v>` pins ALL tools (and the self-update target) to V; mutually exclusive with `--from-bundle`.
- [ ] **Stage-all-first:** a network/checksum/extract failure during staging leaves **zero** destination mutation (all staging precedes all commits).
- [ ] `--dry-run` writes nothing and previews the full plan (per-tool copy/update + prune/replace set), then exits 0; the flag lives in the shared parser so `add` can inherit it.
- [ ] A mid-commit (`install_tool`) failure exits non-zero with the brief re-run-`aid update`-to-heal message; no rollback/enumeration machinery is added.
- [ ] Re-running `aid update` after a successful run is idempotent (no further mutation).
- [ ] bash + PowerShell parity for every changed function; both shipped scripts are ASCII-only.
- [ ] IMPLEMENT defaults: unit tests for all new/changed public functions; all existing tests still pass; build passes.
- [ ] All §6 quality gates pass.
