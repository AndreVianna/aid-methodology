---
name: aid-document-guideline
description: >
  Write a guideline (advisory practice) in one pass. Use when you need one drafted now.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<practice> -- the guideline"
---

# Document Guideline (guideline kind-sibling of /aid-create-document)

`/aid-document-guideline` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: guideline}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to guideline** (structure: principle -> rationale -> do/don't
examples) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-guideline` instead of `/aid-create-document`).
Deeper genre structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.
