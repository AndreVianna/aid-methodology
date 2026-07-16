---
name: aid-audit
description: >
  Alias of /aid-review -- review/assess an existing artifact (code, a change/diff,
  a design, a PR, a ticket, a document, a UI, ...) against criteria and return
  findings + recommendations NOW, in one pass. Single-shot, grounded in the
  Knowledge Base (.aid/knowledge/) and the project source, produced by the
  aid-reviewer agent in a clean context and independently verified; you approve
  before anything is published to an external target. This file carries no logic
  of its own -- its full behavior is defined by .claude/skills/aid-review/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)"
---

# Review (alias of /aid-review)

`/aid-audit` is the alias of **`/aid-review`** (`.claude/skills/aid-review/SKILL.md`),
per the same alias-is-a-full-directory convention the shortcut catalog uses
(`.claude/aid/templates/shortcut-catalog.yml` Topology note: an alias is a full,
separate `.claude/skills/<name>/SKILL.md` directory, not a redirect the generator
resolves). It is registered `alias_of: aid-review`, `repurpose: true` (skipped by
`build-shortcut-skills.py`; hand-authored, like `aid-review` itself).

**This file has no logic of its own.** Its entire behavior -- the fast/guided intake, the
work-folder allocation, KB+source grounding enforcement, the clean-context `aid-reviewer`
REVIEW and VERIFY dispatches, the present-before-publish human gate, the publish router,
and every constraint -- is defined exclusively by `.claude/skills/aid-review/SKILL.md`.
Read that file and execute it exactly as written, substituting nothing except the
invocation name in any printed usage example (`/aid-audit` instead of `/aid-review`).
Duplicating the logic here would let the two drift out of sync; this file exists only so a
user who reaches for "audit" gets the exact same skill.
