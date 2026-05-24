# task-027: Implement `canonical/skills/aid-interview/scripts/parse-recipe.sh`

**Type:** IMPLEMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** task-025

**Scope:**
- Create `canonical/skills/aid-interview/scripts/` directory (first script for that skill).
- Create `parse-recipe.sh` — mechanical parser only (not the orchestrator slot-fill loop).
- 5-step contract: (1) YAML front-matter split via `awk`; (2) validate required YAML fields (name/applies-to/slot-count/task-count); (3) extract unique slot tokens via `grep -oE '\{\{[a-z][a-z0-9-]*\}\}' | sort -u` (POSIX ERE, cross-platform); (4) validate slot-count + task-count against actual body counts (warn on mismatch; continue); (5) split body on `## spec` and `## tasks` headings; return each block.
- Output: structured stdout that the orchestrator (aid-interview SKILL.md) consumes.

**Acceptance Criteria:**
- [ ] Script exists and is executable on Linux + macOS + Windows Bash (no GNU-grep-only flags).
- [ ] Each of the 5 contract steps implemented and individually testable.
- [ ] Slot-name regex matches feature-011 SPEC's lexical rule (`[a-z][a-z0-9-]*`).
- [ ] Mismatch warnings (slot-count or task-count) emitted to stderr without aborting.
- [ ] Script exits non-zero on missing required YAML field; zero on success.
- [ ] Unit tests using each of the 5 seed recipes from task-026 as fixtures.
- [ ] All §6 quality gates pass.
