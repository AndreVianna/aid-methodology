---
name: aid-document-tutorial
description: >
  Write a tutorial in one pass -- a learning-oriented walkthrough, from prerequisites
  through worked steps to the outcome. Use this skill when you already know the document you
  need is tutorial, and want it drafted now rather than planned. It is grounded in, and
  accuracy-checked against, the Knowledge Base (`.aid/knowledge/`) and the project source;
  aid-tech-writer produces it and aid-reviewer verifies it. It resolves nothing: it drafts,
  you approve, and only then is the document placed. It never writes into `.aid/knowledge/`.
  A thin kind-sibling of `/aid-create-document`, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<learning goal> -- the tutorial"
---

# Document Tutorial (tutorial kind-sibling of /aid-create-document)

`/aid-document-tutorial` is a thin **kind-sibling** of **`/aid-create-document`**
(`.codex/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: tutorial}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.codex/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to tutorial** (structure: prerequisites -> worked steps ->
outcome) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-tutorial` instead of `/aid-create-document`).
Deeper genre structures: `.codex/aid/templates/shortcut-scaffolding/document.md`.
