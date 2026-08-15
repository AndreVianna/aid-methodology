---
name: aid-document-decision
description: >
  Write an ADR in one pass -- an architecture decision record: the context, the decision
  itself, the alternatives considered, and the consequences. Use this skill when you already
  know the document you need is ADR, and want it drafted now rather than planned. It is
  grounded in, and accuracy-checked against, the Knowledge Base (.aid/knowledge/) and the
  project source; aid-tech-writer produces it and aid-reviewer verifies it. It resolves
  nothing: it drafts, you approve, and only then is the document placed. It never writes
  into .aid/knowledge/. A thin kind-sibling of /aid-create-document, which defines its full
  behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<decision> -- the decision to record"
---

# Document Decision (ADR kind-sibling of /aid-create-document)

`/aid-document-decision` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agent/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: decision}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agent/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to ADR** (structure: Context -> Decision -> Alternatives ->
Consequences) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-decision` instead of `/aid-create-document`).
Deeper genre structures: `.agent/aid/templates/shortcut-scaffolding/document.md`.
