# task-011: Bootstrap `canonical/skills/aid-discover/SKILL.md` (router body)

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Parent task of the four-way split for `aid-discover` — **this is the largest single risk in the work item** per PLAN Risks §1 (Claude Code 453 vs Codex 1,078 vs Cursor 1,090 lines — ~625 lines of structural drift). Splitting bootstrap into one task per artifact keeps each subtask ~30–40 min and FR2-meaningful.
- This task ships **only the `SKILL.md` router body**:
  - `canonical/skills/aid-discover/SKILL.md` (~453 lines).
  - `canonical/skills/aid-discover/scripts/check-preflight.sh` (45 lines).
  - `canonical/skills/aid-discover/scripts/verify-kb.sh` (60 lines).
- The three `references/*.md` files are split off into sibling tasks:
  - **task-011a** — `references/agent-prompts.md` (142 lines).
  - **task-011b** — `references/document-expectations.md` (121 lines).
  - **task-011c** — `references/reviewer-prompt.md` (75 lines).
- Decision F (recorded in the SPEC's 2026-05-22 change-log entry) says all three profiles will use `references` decomposition going forward, so the canonical bootstrap takes the Claude Code form as-is — the inlining in Codex / Cursor is what the renderer eliminates.
- **Bootstrap drift resolution methodology (per PLAN Risks §1, applied to this SKILL.md body only):**
  - Confirm the Claude Code SKILL.md body equals the corresponding non-inlined portion of `codex/.agents/skills/aid-discover/SKILL.md` and `cursor/.cursor/skills/aid-discover/SKILL.md` — i.e. the parts that are NOT one of the three inlined references. Use grep on a distinctive line from each to locate the boundaries.
  - Any block that genuinely differs (not just inlining vs externalization) is enumerated, with each divergence resolved explicitly. Default to the Claude Code content unless the Codex / Cursor variant carries a fix (e.g. an updated agent name or path) that Claude Code missed.
- Apply abstract-frontmatter + `{filename_map}` placeholder discipline.
- Spot-check the sub-agent dispatch table (`SKILL.md:142-149` per module-map.md) — agent file paths must use the canonical-relative form so the renderer can per-profile-rewrite them.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-discover/SKILL.md` exists at ~453 lines with abstract frontmatter and `{filename_map}` placeholders applied.
- [ ] Both `scripts/*.sh` files carried over.
- [ ] An explicit drift-resolution log in the execution record enumerates every non-cosmetic divergence between the Claude Code SKILL.md body (excluding inlined-reference regions) and the corresponding non-reference content in the Codex / Cursor SKILL.md, with the resolution chosen for each. Empty log is acceptable (meaning all divergences were cosmetic) but must be explicitly stated.
- [ ] Re-render verification (post task-020): rendering aid-discover with the Claude Code profile reproduces the current `claude-code/.claude/skills/aid-discover/SKILL.md` exactly modulo frontmatter; rendering with the Codex / Cursor profiles produces a thin SKILL.md (NOT the current 1,078-/1,090-line inlined form — Decision F).
- [ ] FR2-style per-task quick check: the maintainer reviews this drift-resolution log before any subsequent task depends on this bootstrap.
