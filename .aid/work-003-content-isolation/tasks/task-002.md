# task-002: Rename committed skills/README.md → aid-README.md in all profiles

**Type:** REFACTOR

**Source:** work-003-content-isolation → delivery-001

**Depends on:** — (none)

**Scope:**
- Rename the committed, profile-local file `skills/README.md` → `skills/aid-README.md` in `profiles/claude-code/.claude/`, `profiles/codex/.agents/`, and `profiles/cursor/.cursor/` (these are committed data, NOT generated, and appear in no `emission-manifest.jsonl`).
- Update any body reference to the old `skills/README.md` path within the profiles or canonical/skill bodies that point at it.
- Do not change file contents beyond the rename and reference updates.

**Acceptance Criteria:**
- [ ] `profiles/{claude-code/.claude,codex/.agents,cursor/.cursor}/skills/README.md` no longer exists; `skills/aid-README.md` exists in each with the same content.
- [ ] No remaining reference to the old `skills/README.md` path in `profiles/` or in any rendered/canonical body (grep clean).
- [ ] The renamed file is `aid-`-prefixed so it is managed by the prefix-based prune (task-004/005) — i.e. nothing AID-owned remains un-prefixed in `skills/`.
- [ ] All §6 quality gates pass.
