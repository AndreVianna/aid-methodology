# task-045: aid-ask -> aid-query-kb canonical rename (behavior preserved)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** -- (none)

**Scope:**
- f008 Part 1 (FR-26, R1-R6) -- the `aid-ask` -> `aid-query-kb` rename, **canonical source only**.
  Do NOT touch the rendered host trees, install manifests, or KB counts (that is f009 / task-049+).
- R1: rename the skill directory `canonical/skills/aid-ask/` -> `canonical/skills/aid-query-kb/`
  (preserve via `git mv` so history follows).
- R2: frontmatter `name: aid-ask` -> `name: aid-query-kb`.
- R3: rewrite every `/aid-ask` mention in `description:` / `argument-hint:` -> `/aid-query-kb`.
- R4: rewrite every body self-reference -- each `/aid-ask` / "aid-ask" token, the
  `Usage: /aid-ask <question>` pre-flight line, and the example file-path citation
  `.claude/skills/aid-ask/SKILL.md` (SKILL.md line 72) -> `/aid-query-kb`,
  `.claude/skills/aid-query-kb/SKILL.md`.
- R5: add NO `references/` dir -- behavior stays single-shot (the skill keeps the existing
  optional-skill thin variant: no multi-state machine).
- R6: agent default -- no canonical agent hard-codes `aid-ask` (confirmed); make no agent edit,
  but assert it via the grep gate below.
- **Behavior preserved verbatim:** keep `allowed-tools: Read, Glob, Grep, Agent` (the gap-capture
  `Write, Edit` grant is task-046, NOT here); keep the single-shot no-state-machine pass
  (classify -> answer inline or dispatch `aid-researcher` read-only -> emit `## Answer` /
  `## Sources`); keep the "no work folder, no STATE.md for its own use" rule and the
  source-citation discipline. This task changes the NAME, not the behavior.
- Keep the SKILL.md ASCII-only for sibling consistency (C2; markdown, not gated, but kept ASCII).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-query-kb/SKILL.md` exists; `canonical/skills/aid-ask/` no longer exists.
- [ ] `grep -rn 'aid-ask' canonical/` returns ZERO matches (the in-feature f008 verification gate
  for R1-R6: dir gone, all self-references rewritten, no canonical agent default lingers).
- [ ] Frontmatter is `name: aid-query-kb`; `allowed-tools:` is still exactly
  `Read, Glob, Grep, Agent` (unchanged -- the Write/Edit grant is deferred to task-046).
- [ ] The renamed SKILL.md still parses as a valid single-shot skill (frontmatter present; no
  `references/` dir added; behavior text describes the unchanged classify->answer/dispatch pass).
- [ ] `aid-query-kb/SKILL.md` is ASCII-only.
- [ ] The rendered host trees, install manifests, and KB skill counts are NOT touched in this task
  (render-drift is expected RED on this branch until f009/task-049 -- by design).
- [ ] All section-6 quality gates pass.
