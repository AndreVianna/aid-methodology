---
name: aid-create-diagram
description: >
  Draw a diagram (flowchart, sequence, ER, C4) in one pass. Use when a picture beats
  prose.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- what to diagram"
---

# Create Diagram (kind-sibling of /aid-create-document)

`/aid-create-diagram` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: create, artifact: diagram}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
output **format bound to diagram** (mermaid/graphviz; pick the diagram type -- flowchart,
sequence, ER, C4, state, ... -- that fits the subject). Substitute only the invocation
name in any printed usage example (`/aid-create-diagram` instead of
`/aid-create-document`). Deeper genre/format structures:
`.aid/runtime/templates/shortcut-scaffolding/document.md`.
