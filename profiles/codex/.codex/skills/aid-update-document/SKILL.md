---
name: aid-update-document
description: >
  Alias of /aid-change-document -- update an EXISTING document NOW (revise/extend a
  markdown doc, an ADR, a runbook, a changelog, a diagram, ...) in one pass. Reads the
  existing document first, then edits it, grounded in and accuracy-checked against the
  Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer,
  verified by aid-reviewer. It RESOLVES NOTHING -- drafts the change, you approve (with a
  diff shown), then it is written back. NEVER writes into .aid/knowledge/. This file
  carries no logic of its own -- its full behavior is defined by
  .codex/skills/aid-change-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<document + change> -- which existing document to update, and how"
---

# Change Document (alias of /aid-change-document)

`/aid-update-document` is the alias of **`/aid-change-document`**
(`.codex/skills/aid-change-document/SKILL.md`), per the alias-is-a-full-directory
convention the shortcut catalog uses (an alias is a full, separate
`.codex/skills/<name>/SKILL.md` directory, not a redirect the generator resolves).
Registered `alias_of: aid-change-document`, `repurpose: true` (skipped by
`build-shortcut-skills.py`; hand-authored, like `aid-change-document`).

**This file has no logic of its own.** Its entire behavior -- locating and reading the
existing document first, the intake, work-folder allocation, KB+source grounding, the
clean-context `aid-tech-writer` AUTHOR and `aid-reviewer` VERIFY loop, the diff shown at
the present-before-write human gate, the `.aid/knowledge/` boundary, and every
constraint -- is defined exclusively by `.codex/skills/aid-change-document/SKILL.md`.
Read that file and execute it exactly as written, substituting nothing except the
invocation name in any printed usage example (`/aid-update-document` instead of
`/aid-change-document`). Duplicating the logic here would let the two drift out of sync.
