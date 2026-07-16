---
name: aid-document-guideline
description: >
  Write a guideline NOW -- an advisory recommended practice (principle -> rationale ->
  do/don't examples) -- in one pass. A thin kind-sibling of /aid-create-document with the
  document genre bound to guideline. Grounded in and accuracy-checked against the
  Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer,
  verified by aid-reviewer. It RESOLVES NOTHING -- drafts, you approve, then it is placed.
  NEVER writes into .aid/knowledge/. This file carries no logic of its own -- its full
  behavior is defined by .agent/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<practice> -- the guideline"
---

# Document Guideline (guideline kind-sibling of /aid-create-document)

`/aid-document-guideline` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agent/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: guideline}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.agent/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to guideline** (structure: principle -> rationale -> do/don't
examples) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-guideline` instead of `/aid-create-document`).
Deeper genre structures: `.agent/aid/templates/shortcut-scaffolding/document.md`.
