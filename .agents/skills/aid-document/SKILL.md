---
name: aid-document
description: >
  Write a how-to, reference, explanation or status report, outside the KB. Use when no
  named genre fits.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- what to document"
---

# Document (general kind-sibling of /aid-create-document)

`/aid-document` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: ""}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to general** (structure: a Diataxis how-to / reference /
explanation, or a status/progress report) and the **format = markdown**. Substitute only
the invocation name in any printed usage example (`/aid-document` instead of
`/aid-create-document`). Deeper genre structures:
`.aid/runtime/templates/shortcut-scaffolding/document.md`.
