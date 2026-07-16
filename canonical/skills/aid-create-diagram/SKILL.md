---
name: aid-create-diagram
description: >
  Create a diagram NOW -- a mermaid or graphviz diagram (flowchart, sequence, ER, C4,
  state, ...) chosen for the subject, in one pass. A thin kind-sibling of
  /aid-create-document with the output format bound to diagram. Grounded in and
  accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source;
  produced by aid-tech-writer, verified by aid-reviewer. It RESOLVES NOTHING -- drafts,
  you approve, then it is placed. NEVER writes into .aid/knowledge/. This file carries no
  logic of its own -- its full behavior is defined by
  canonical/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- what to diagram"
---

# Create Diagram (kind-sibling of /aid-create-document)

`/aid-create-diagram` is a thin **kind-sibling** of **`/aid-create-document`**
(`canonical/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: create, artifact: diagram}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `canonical/skills/aid-create-document/SKILL.md` exactly as written, with the
output **format bound to diagram** (mermaid/graphviz; pick the diagram type -- flowchart,
sequence, ER, C4, state, ... -- that fits the subject). Substitute only the invocation
name in any printed usage example (`/aid-create-diagram` instead of
`/aid-create-document`). Deeper genre/format structures:
`canonical/aid/templates/shortcut-scaffolding/document.md`.
