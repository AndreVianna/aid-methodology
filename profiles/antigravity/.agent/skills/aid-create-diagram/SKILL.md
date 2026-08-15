---
name: aid-create-diagram
description: >
  Create a diagram in one pass, choosing the diagram type that fits the subject --
  flowchart, sequence, entity-relationship, C4, state, and so on, in Mermaid or Graphviz.
  Use this skill when a picture would explain something faster than prose and you do not
  want to pick the notation yourself. It is grounded in, and accuracy-checked against, the
  Knowledge Base (`.aid/knowledge/`) and the project source; aid-tech-writer produces it and
  aid-reviewer verifies it. It resolves nothing: it drafts, you approve, and only then is
  the diagram placed. It never writes into `.aid/knowledge/`. A thin kind-sibling of
  `/aid-create-document` with the output format bound to a diagram.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- what to diagram"
---

# Create Diagram (kind-sibling of /aid-create-document)

`/aid-create-diagram` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agent/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: create, artifact: diagram}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agent/skills/aid-create-document/SKILL.md` exactly as written, with the
output **format bound to diagram** (mermaid/graphviz; pick the diagram type -- flowchart,
sequence, ER, C4, state, ... -- that fits the subject). Substitute only the invocation
name in any printed usage example (`/aid-create-diagram` instead of
`/aid-create-document`). Deeper genre/format structures:
`.agent/aid/templates/shortcut-scaffolding/document.md`.
