# task-011c: Bootstrap `canonical/skills/aid-discover/references/reviewer-prompt.md`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- One of the three `references/*.md` artifacts split off from task-011's parent. Author **only this file**:
  - `canonical/skills/aid-discover/references/reviewer-prompt.md` (~75 lines, per module-map.md table).
- Source of truth: `claude-code/.claude/skills/aid-discover/references/reviewer-prompt.md`.
- **Drift resolution for this reference:**
  - Locate the corresponding inlined block in `codex/.agents/skills/aid-discover/SKILL.md` and `cursor/.cursor/skills/aid-discover/SKILL.md`.
  - Diff and resolve. **Special attention here:** this file is the most likely site of the `DISCOVERY-STATE.md` vs `DISCOVERY-GRADE.md` and `additional-info.md` vs `open-questions.md` divergence per `coding-standards.md §2.4` — apply `{reviewer_output_file}` and `{open_questions_file}` placeholders carefully.
- Apply abstract-frontmatter + `{filename_map}` placeholder discipline.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-discover/references/reviewer-prompt.md` exists at ~75 lines with `{reviewer_output_file}` and `{open_questions_file}` placeholders applied wherever the body refers to the per-tool reviewer-output / open-questions artifact.
- [ ] Drift-resolution log enumerates each non-cosmetic divergence (empty log explicitly stated if none).
- [ ] FR2 quick check: a re-render of `aid-discover` post task-020 emits this reference into all three profiles' trees with the per-profile `filename_map` substitution applied (so Claude Code's emitted body shows `DISCOVERY-STATE.md`, Codex's shows `DISCOVERY-GRADE.md` if its profile so declares — verify against the Q72 / R12 canonical decision recorded in profile authoring).
