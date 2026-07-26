---
name: aid-document
description: >
  Write a general document NOW -- a Diataxis how-to / reference / explanation, or a
  status/progress report -- in one pass. A thin kind-sibling of /aid-create-document
  with the document genre bound to general. Grounded in and accuracy-checked against the
  Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer,
  verified by aid-reviewer. It RESOLVES NOTHING -- drafts, you approve, then it is placed.
  NEVER writes into .aid/knowledge/. This file carries no logic of its own -- its full
  behavior is defined by .cursor/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<subject> -- what to document"
---

# Document (general kind-sibling of /aid-create-document)

`/aid-document` is a thin **kind-sibling** of **`/aid-create-document`**
(`.cursor/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: ""}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.cursor/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to general** (structure: a Diataxis how-to / reference /
explanation, or a status/progress report) and the **format = markdown**. Substitute only
the invocation name in any printed usage example (`/aid-document` instead of
`/aid-create-document`). Deeper genre structures:
`.cursor/aid/templates/shortcut-scaffolding/document.md`.
