# task-027: Commit the generated install trees — the cutover

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-026

**Scope:**
- With bootstrap verification passed in task-026, run `/aid-generate` (live mode, not dry-run) so the three install trees become generated artifacts on disk.
- `git add` the changed install-tree files plus the three `emission-manifest.jsonl` files (per-profile manifests committed alongside the trees per task-003 / task-022).
- Commit message: structured per the repo's existing pattern (no Conventional Commits enforcement, but the existing commits in `git log` use prefixes like `docs:`, `feat:`). Suggested:
  > `feat(generator): cut over install trees to canonical-source generator (work-002 delivery-001)`
  > `Replaces the 4-way hand-maintained duplication of skills/agents/templates with one canonical/ source + three profiles/. The three install trees (claude-code/, codex/.codex/, codex/.agents/, cursor/.cursor/) are now generated artifacts produced by /aid-generate. Per-profile emission-manifest.jsonl committed alongside each tree as the deletion safety boundary. Retires drift (H1), the 36% duplication footprint (H4), and the divergent filename conventions (R12). The H6 installer fix shipped in task-001 / commit <hash>. CONTRIBUTING.md updated in task-028 / commit <hash>.`
- The commit lands on the work branch (or master directly — per the user's preference; the repo currently commits to master per `git status`).
- **Cross-work-edit-freeze window** per PLAN Cross-cutting risks §3: between task-026's verification and this commit, any concurrent hand-edit to an install tree becomes orphaned. The sole-maintainer model makes this a coordination, not a process, problem — but flag it in the commit message body so the next contributor reading `git log` knows the install trees are no longer hand-edit-safe.
- **Post-commit**: the `work-001-aid-lite` FR3 wave (the thin-router refactor of remaining skill bodies) is now unblocked per `work-001-aid-lite/REQUIREMENTS.md §10` and PLAN Sequencing context. The methodology owner should re-sequence the broader work board.

**Acceptance Criteria:**
- [ ] `git log -1` after this task shows a commit touching all three install-tree paths plus the three `emission-manifest.jsonl` files plus `canonical/` and `profiles/`.
- [ ] The committed install trees pass a re-run of `/aid-generate --dry-run` with **zero diff** (the trees are now in sync with what the generator emits).
- [ ] The commit message explicitly enumerates the retired tech-debt items (H1, H4, R12) and references the H6 fix commit and the CONTRIBUTING update commit.
- [ ] The cross-work-edit-freeze warning is in the commit message body for future contributors.
- [ ] No production install-tree file is removed by the cutover (only modified — the file SET is preserved; the file CONTENT is now generated-canonical).
