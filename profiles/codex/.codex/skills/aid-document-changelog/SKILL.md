---
name: aid-document-changelog
description: >
  Write a changelog in one pass -- release notes grouped as Added, Changed, Fixed, Removed
  and Security. Use this skill when you already know the document you need is changelog, and
  want it drafted now rather than planned. It is grounded in, and accuracy-checked against,
  the Knowledge Base (.aid/knowledge/) and the project source; aid-tech-writer produces it
  and aid-reviewer verifies it. It resolves nothing: it drafts, you approve, and only then
  is the document placed. It never writes into .aid/knowledge/. A thin kind-sibling of
  /aid-create-document, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<version/changes> -- the changelog"
---

# Document Changelog (changelog kind-sibling of /aid-create-document)

`/aid-document-changelog` is a thin **kind-sibling** of **`/aid-create-document`**
(`.codex/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: changelog}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.codex/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to changelog** (structure: sections Added / Changed / Fixed /
Removed / Security) and the **format = markdown**. Substitute only the invocation name in
any printed usage example (`/aid-document-changelog` instead of `/aid-create-document`).
Deeper genre structures: `.codex/aid/templates/shortcut-scaffolding/document.md`.
