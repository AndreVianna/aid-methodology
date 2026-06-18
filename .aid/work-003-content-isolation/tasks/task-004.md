# task-004: Net-new install/update prune (bash, aid-install-core.sh)

**Type:** IMPLEMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-003

**Scope:**
- Add a net-new prune step to `install_tool` in `lib/aid-install-core.sh`, running after the per-tool copy + `manifest_write`, scoped to each tool's AID directories.
- Prune basis = `aid-` prefix + new-manifest membership (NOT an old-manifest diff). The manifest stores FILE paths only (never directory entries), so the keep/remove test for a directory is about its CONTENTS, not its own membership. Remove:
  - (a) an `aid-`-prefixed FILE inside a tool-native dir (`agents/`, `skills/`, `rules/`) when its path is NOT in the new manifest's path set;
  - (b) an `aid-`-prefixed DIRECTORY inside a tool-native dir (e.g. `skills/aid-skill/`) when NONE of its files appear in the new manifest's path set — a current/live skill dir whose files ARE in the set is KEPT (do NOT delete it just because the dir path itself can never be a set member);
  - (c) any FILE under the nested `aid/` subtree when its path is NOT in the new manifest's path set (and prune now-empty `aid/` subdirs).
- Never remove non-`aid-`-prefixed entries (user content); never touch anything outside the tool's scoped AID directories. For copilot-cli, walk only `.github/{agents,skills,aid}`, never the `.github` root (R1).
- Keep `bin/aid` ASCII-only.

**Acceptance Criteria:**
- [ ] After install/update, a stale `aid-`-prefixed FILE in a tool-native dir that is NOT in the new manifest is removed; a current one (in the manifest) is kept.
- [ ] A LIVE `aid-`-prefixed skill dir whose files ARE in the new manifest (e.g. `skills/aid-config/SKILL.md`) is KEPT (NOT pruned because the dir path itself is not a manifest member); a stale `aid-`-prefixed dir NONE of whose files are in the manifest is removed.
- [ ] A stale file under the nested `aid/` subtree not in the new manifest is removed (now-empty `aid/` subdirs pruned); user (non-`aid-`-prefixed) files in tool-native dirs are never removed.
- [ ] For copilot-cli the prune touches only `.github/{agents,skills,aid}` and never deletes at the `.github` root (R1).
- [ ] The prune compares candidates against the same new-manifest path set just written by `manifest_write`; it reads no old/previous manifest.
- [ ] `bin/aid` and `lib/aid-install-core.sh` remain ASCII-only; the change is parity-ready for task-005.
- [ ] All §6 quality gates pass.
