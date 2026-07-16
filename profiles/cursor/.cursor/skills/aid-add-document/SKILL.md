---
name: aid-add-document
description: >
  Alias of /aid-create-document -- create a document NOW (markdown/reference/how-to,
  an ADR, an architecture write-up, a runbook, a tutorial, a changelog, a mermaid
  diagram, a table), determining the format AND structure from the request, in one
  pass. Grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/)
  and the project source; produced by aid-tech-writer, verified by aid-reviewer. It
  RESOLVES NOTHING -- drafts, you approve, then it is placed. NEVER writes into
  .aid/knowledge/. This file carries no logic of its own -- its full behavior is
  defined by .cursor/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<subject> -- what to document"
---

# Create Document (alias of /aid-create-document)

`/aid-add-document` is the alias of **`/aid-create-document`**
(`.cursor/skills/aid-create-document/SKILL.md`), per the alias-is-a-full-directory
convention the shortcut catalog uses (an alias is a full, separate
`.cursor/skills/<name>/SKILL.md` directory, not a redirect the generator resolves).
Registered `alias_of: aid-create-document`, `repurpose: true` (skipped by
`build-shortcut-skills.py`; hand-authored, like `aid-create-document`).

**This file has no logic of its own.** Its entire behavior -- the fast/guided intake,
the work-folder allocation, KB+source grounding, the clean-context `aid-tech-writer`
AUTHOR and `aid-reviewer` VERIFY loop, the present-before-place human gate, the
`.aid/knowledge/` boundary, and every constraint -- is defined exclusively by
`.cursor/skills/aid-create-document/SKILL.md`. Read that file and execute it exactly
as written, substituting nothing except the invocation name in any printed usage
example (`/aid-add-document` instead of `/aid-create-document`). Duplicating the logic
here would let the two drift out of sync.
