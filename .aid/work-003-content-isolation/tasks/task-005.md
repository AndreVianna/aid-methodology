# task-005: Net-new install/update prune (PowerShell, AidInstallCore.psm1) — parity

**Type:** IMPLEMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-004

**Scope:**
- Mirror the bash prune (task-004) in `Install-Tool` within `lib/AidInstallCore.psm1`: after the per-tool copy + manifest write, prune by `aid-` prefix + new-manifest membership, scoped to each tool's AID directories, with byte-for-byte equivalent semantics to bash. The manifest stores FILE paths only (never directory entries), so the keep/remove test for a directory is about its CONTENTS, not its own membership. Remove:
  - (a) an `aid-`-prefixed FILE inside a tool-native dir (`agents/`, `skills/`, `rules/`) when its path is NOT in the new manifest's path set;
  - (b) an `aid-`-prefixed DIRECTORY inside a tool-native dir (e.g. `skills/aid-skill/`) when NONE of its files appear in the new manifest's path set — a current/live skill dir whose files ARE in the set is KEPT (do NOT delete it because the dir path itself can never be a set member);
  - (c) any FILE under the nested `aid/` subtree when its path is NOT in the new manifest's path set (and prune now-empty `aid/` subdirs).
- Scope the prune walk to the R1-scoped AID directory set — `.github/{agents,skills,aid}` for copilot-cli, never the `.github` root. Do NOT reuse the existing PS AID-dir map at `AidInstallCore.psm1` ~`:1165` AS the prune scope: that map (uninstall empty-dir prune) points copilot-cli at the `.github` ROOT, which R1 forbids for this walk. Cite it only as a reference for the per-tool dir convention, not as the scope.
- Keep `bin/aid.ps1` ASCII-only.

**Acceptance Criteria:**
- [ ] The PS prune's candidate selection, keep/remove decision, and per-tool scoping are equivalent to the bash prune (task-004): same removals, same preserved user content, same `.github` scoping.
- [ ] A LIVE `aid-`-prefixed skill dir whose files ARE in the new manifest is KEPT; a stale `aid-`-prefixed dir NONE of whose files are in the manifest is removed.
- [ ] Stale `aid-`-prefixed FILES and stale files under the nested `aid/` subtree (not in the new manifest) are removed; current ones kept; non-`aid-` user files never removed.
- [ ] The prune walk is scoped to the R1 set (`.github/{agents,skills,aid}` for copilot-cli), NOT the root-scoped `~:1165` AID-dir map.
- [ ] The PS prune reads no old/previous manifest; it uses the new-manifest path set just written.
- [ ] `bin/aid.ps1` and `lib/AidInstallCore.psm1` remain ASCII-only.
- [ ] All §6 quality gates pass.
