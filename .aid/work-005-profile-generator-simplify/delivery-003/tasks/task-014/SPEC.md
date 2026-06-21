# task-014: release.sh codex tarball roots collapse to single `.codex`

**Type:** CONFIGURE

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Edit `release.sh` so the codex tarball packages from a single root after FR2 unifies Codex under `.codex/{agents,skills,aid}` and retires `.agents/` (feature-004 SPEC §B.1):
  - `release.sh:281` — change `build_tarball "codex" "profiles/codex" ".agents" ".codex" "AGENTS.md"` → `build_tarball "codex" "profiles/codex" ".codex" "AGENTS.md"` (drop the `.agents` root argument only).
  - `release.sh:189-194` — update the root-map comment block to drop the codex `.agents/` entry.
  - `release.sh:280` — update the codex comment to drop `.agents/`.
- **Touch ONLY the codex row.** No other tool's roots change: claude-code `.claude`, cursor `.cursor`, copilot-cli `.github`, antigravity `.agent` are unchanged (rules-folder removal lives *inside* those roots via the omitted-from-manifest mechanism, not the tarball root list).
- **Out of scope (do NOT touch):** the CLI bundle, `SHA256SUMS`, the 5-tool loop shape, any `profiles/*` / `canonical/*` tree, the `lib/*`/`bin/*` twins, and the emitter-test CI de-wire (`test.yml:97-98`, `release.yml:166-167`) — all owned by features 002/003 or other tasks.

**Acceptance Criteria:**
- [ ] The codex tarball is packaged from `.codex` only (the `.agents` root argument is removed at `release.sh:281`).
- [ ] The root-map comment block (`release.sh:189-194`) and the codex comment (`:280`) no longer reference `.agents/`.
- [ ] The `build_tarball` "expected install root not found" guard (`release.sh:261`) now fails the release if `profiles/codex/.agents/` were to reappear (free regression catch verified by inspection).
- [ ] No other tool's tarball roots change (claude-code, cursor, copilot-cli, antigravity unchanged); the CLI bundle, SHA256SUMS, and the 5-tool loop are untouched.
- [ ] `release.sh` parses cleanly (`bash -n release.sh`).
- [ ] CONFIGURE defaults: configuration is idempotent; no plaintext secrets.
- [ ] All §6 quality gates pass.
