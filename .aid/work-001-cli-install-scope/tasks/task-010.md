# task-010: Two-tier registry union read + best-effort write-tier selection (bash)

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-registry-and-dispatch → delivery-002

**Depends on:** task-007, task-008, task-009

**Scope:**
- `bin/aid` only — feature-004 mechanism 1 (union read + quiet prune) and mechanism 2 (write-tier selection + best-effort elevation). Per the "Affected components" table:
  - `_registry_read_repos` (`:1190-1196`) — unchanged single-file primitive.
  - **NEW `_registry_read_union`** — calls the primitive once per existing tier (user `~/.aid/registry.yml`; shared `$AID_STATE_HOME/registry.yml` only when global), concatenates, `sed '/^$/d' | sort -u` (the `:1222` dedup idiom), then **quiet-prunes** stale entries (emit a path only if `[[ -d "$p/.aid" ]]`); never mutates the shared tier on read. Per-user collapse: when `$AID_STATE_HOME == ~/.aid` the two paths are one file → union degenerates to one tier, no shared read.
  - `registry_register` (`:1202-1235`) — add a tier parameter. Default → **user** tier (existing temp+`mv -f` body, path only changes). **Shared** write routes temp-write+`mv -f` through `_aid_priv_run`; declined elevation / no-TTY ⇒ skip + warn + `return 0` (preserve and extend the existing return-0-on-failure contract at `:1213,1227,1232`). Registration never blocks the host command.
  - `registry_unregister` (`:1241-1273`) — remove from the tier(s) where found; best-effort user-tier prune-on-write.
  - Dashboard auto-register (`:1109,1117`) — route through the tier-aware `registry_register` (user tier by default).
- Must not reintroduce any `$HOME`-walking scan (AC2; the scan was removed in task-001).

**Acceptance Criteria:**
- [ ] `_registry_read_union` returns the deduped `sort -u` union of user + (global-only) shared tiers, drops any path whose `.aid/` no longer exists with no warning/error, and never writes the shared tier on read.
- [ ] Per-user install (`$AID_STATE_HOME == ~/.aid`) performs no shared read; the union equals the single-file read (backward compat).
- [ ] `registry_register` takes a tier param: user-tier writes never elevate; shared-tier writes route through `_aid_priv_run` and degrade to skip+warn+`return 0` on declined elevation / no-TTY; dashboard auto-register uses the user tier by default.
- [ ] No `$HOME`-walking scan is defined or called anywhere in the changed paths.
- [ ] All new/edited `bin/aid` lines are ASCII-only.
- [ ] All §6 quality gates pass.
