---
name: aid-document-guideline
description: >
  Write a guideline in one pass -- an advisory recommended practice, stating the principle,
  its rationale, and do/don't examples. Use this skill when you already know the document
  you need is guideline, and want it drafted now rather than planned. It is grounded in, and
  accuracy-checked against, the Knowledge Base (`.aid/knowledge/`) and the project source;
  aid-tech-writer produces it and aid-reviewer verifies it. It resolves nothing: it drafts,
  you approve, and only then is the document placed. It never writes into `.aid/knowledge/`.
  A thin kind-sibling of `/aid-create-document`, which defines its full behavior.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, Agent
argument-hint: "<practice> -- the guideline"
---

# Document Guideline (guideline kind-sibling of /aid-create-document)

`/aid-document-guideline` is a thin **kind-sibling** of **`/aid-create-document`**
(`.github/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: guideline}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.github/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to guideline** (structure: principle -> rationale -> do/don't
examples) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-guideline` instead of `/aid-create-document`).
Deeper genre structures: `.github/aid/templates/shortcut-scaffolding/document.md`.
