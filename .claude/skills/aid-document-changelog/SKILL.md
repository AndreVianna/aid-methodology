---
name: aid-document-changelog
description: >
  Write a changelog (release notes) in one pass. Use when you need one drafted now.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<version/changes> -- the changelog"
---

# Document Changelog (changelog kind-sibling of /aid-create-document)

`/aid-document-changelog` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: changelog}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to changelog** (structure: sections Added / Changed / Fixed /
Removed / Security) and the **format = markdown**. Substitute only the invocation name in
any printed usage example (`/aid-document-changelog` instead of `/aid-create-document`).
Deeper genre structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.
