# task-028: Replace `CONTRIBUTING.md`'s cross-tree update rule

**Type:** DOCUMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-027

**Scope:**
- Modify `CONTRIBUTING.md:21-26` (the "Important: When updating a skill or agent, update ALL locations" block).
- Replace the existing 6-line manual cross-tree update instructions with a single rule:
  > **Important: To update a skill, agent, or template, edit the canonical source under `canonical/` and run `/aid-generate`. The three install trees (`claude-code/.claude/`, `codex/.codex/` + `codex/.agents/`, `cursor/.cursor/`) are generated artifacts — do not hand-edit them. See `canonical/EMISSION-MANIFEST.md` for the deletion safety boundary and `.claude/skills/aid-generate/SKILL.md` for the full pipeline.**
- Additionally update the repo-structure block at `CONTRIBUTING.md:6-19` (per H5 / Q34 / Q72 / R15) to:
  - Include `canonical/` and `profiles/` as first-class top-level directories.
  - Use the correct dotted-hidden on-disk paths for the install trees (`claude-code/.claude/`, `codex/.codex/`, `codex/.agents/`, `cursor/.cursor/`) — fixes the stale paths the existing CONTRIBUTING shows.
  - Include the Cursor tree explicitly (R15: "Quadruplicate, not triplicate" — though the new rule actually makes it **canonical + profiles**, eliminating the quadruplicate problem altogether).
- Add a short paragraph noting that `skills/` and `agents/` at the repo root remain hand-maintained human-readable READMEs (out-of-scope for the generator per SPEC Migration Plan §7) — these are the one residue of manual upkeep.
- Add a one-line pointer to the relevant slash command for end-users (`/aid-generate` is maintainer-only; end-users still install via `setup.sh` / `setup.ps1`).
- This task **retires tech-debt H4 (the quadruplication pattern itself) and H5 (Cursor omission + wrong paths in CONTRIBUTING)** per the AC5 condition in `REQUIREMENTS.md §6`.

**Acceptance Criteria:**
- [ ] `CONTRIBUTING.md:21-26` (the original "update ALL locations" block) is replaced with the new "edit `canonical/`, run the generator" rule.
- [ ] The repo-structure block at the top of CONTRIBUTING.md is corrected to use the dotted-hidden paths and includes `canonical/`, `profiles/`, and `cursor/.cursor/`.
- [ ] The human-readable `skills/` and `agents/` READMEs are explicitly called out as the one hand-maintained exception.
- [ ] No other CONTRIBUTING.md content is modified (verified via `git diff` review — diff is confined to lines 6–19 and 21–26 plus the small added paragraph).
- [ ] After this commit, `grep -n "update ALL locations" CONTRIBUTING.md` returns nothing (the old rule is gone).
