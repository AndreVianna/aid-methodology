# task-025-STATE

**Status:** Done
**Grade:** A
**Cycle:** 1

## Review History

| Cycle | Grade | Notes |
|-------|-------|-------|
| 1 | A | .claude/skills/aid-generate/SKILL.md exists. Valid Claude Code frontmatter (name, description folded YAML, allowed-tools, argument-hint). Body has all 7 sections: Pre-flight, State Detection, LOAD, VALIDATE, RENDER, VERIFY, REPORT plus Quality Checklist. Uses coding-standards.md Print: idiom throughout. |

## Citations

- Placement: .claude/skills/aid-generate/ (repo root, maintainer-only, never shipped in install trees).
- Naming: aid-generate (follows aid-{verb} slug convention per coding-standards.md §8).
- Frontmatter: name, description (folded YAML >), allowed-tools, argument-hint — Claude Code shape.
- State machine: LOAD -> VALIDATE -> RENDER -> VERIFY -> REPORT (per SPEC §148-204).
- --tool argument: SELECTED_PROFILES = single named profile or all three.
- --dry-run argument: renders to scratch dir; prints would-delete instead of deleting.
- RENDER section: render_agents.py -> render_skills.py -> render_templates.py in order; manifest write; deletion pass (removed_dst from diff).
- VERIFY-4a: exit non-zero → abort. VERIFY-4b: always 0, skipped_count surfaced in REPORT.
- REPORT: per-profile file counts, manifest locations, VERIFY-4a status, VERIFY-4b skipped_count+warning_count, git diff --stat.
- Print: [State: {STATE}] and [i/N] progress idioms used throughout (coding-standards.md §1.5).

## Spot-check

Frontmatter:
- name: aid-generate ✓
- description: folded YAML block (state machine LOAD -> VALIDATE -> RENDER -> VERIFY -> REPORT) ✓
- allowed-tools: Read, Glob, Grep, Bash, Write, Edit ✓
- argument-hint: --tool and --dry-run documented ✓

Body sections: Pre-flight, State Detection, LOAD, VALIDATE, RENDER, VERIFY (4a+4b), REPORT, Quality Checklist ✓ (7 sections + checklist = 8 total)
Print: idiom present at state transitions ✓
