---
name: aid-document-standard
description: >
  Write a standard in one pass -- a mandatory rule, stating the rule, its scope, how
  compliance is enforced, and the exceptions. Use this skill when you already know the
  document you need is standard, and want it drafted now rather than planned. It is grounded
  in, and accuracy-checked against, the Knowledge Base (.aid/knowledge/) and the project
  source; aid-tech-writer produces it and aid-reviewer verifies it. It resolves nothing: it
  drafts, you approve, and only then is the document placed. It never writes into
  .aid/knowledge/. A thin kind-sibling of /aid-create-document, which defines its full
  behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<rule> -- the standard"
---

# Document Standard (standard kind-sibling of /aid-create-document)

`/aid-document-standard` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agent/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: standard}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agent/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to standard** (structure: rule -> scope -> compliance/enforcement
-> exceptions) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-standard` instead of `/aid-create-document`).
Deeper genre structures: `.agent/aid/templates/shortcut-scaffolding/document.md`.
