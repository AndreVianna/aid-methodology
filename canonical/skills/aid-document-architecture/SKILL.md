---
name: aid-document-architecture
description: >
  Write an architecture write-up in one pass -- a system's components, boundaries, and
  interactions, as C4 or arc42 views with Mermaid diagrams. Use this skill when you already
  know the document you need is architecture write-up, and want it drafted now rather than
  planned. It is grounded in, and accuracy-checked against, the Knowledge Base
  (`.aid/knowledge/`) and the project source; aid-tech-writer produces it and aid-reviewer
  verifies it. It resolves nothing: it drafts, you approve, and only then is the document
  placed. It never writes into `.aid/knowledge/`. A thin kind-sibling of
  `/aid-create-document`, which defines its full behavior.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<system/scope> -- what to document"
---

# Document Architecture (architecture kind-sibling of /aid-create-document)

`/aid-document-architecture` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: architecture}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to architecture** (structure: components, boundaries, and
interactions -- C4/arc42 views + Mermaid diagrams) and the **format = markdown**.
Substitute only the invocation name in any printed usage example
(`/aid-document-architecture` instead of `/aid-create-document`). Deeper genre
structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.

The work is recorded under `aid-create-document`, whose record alone decides a resume. So that a
resumed work keeps the bound genre and format, pass them in the `--detail` of every step the run
enters (`genre: architecture; format: markdown`), as `aid-create-document` ALLOCATE says.
