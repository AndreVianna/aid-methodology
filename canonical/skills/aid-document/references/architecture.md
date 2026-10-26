# Document Architecture (architecture kind-sibling of /aid-create document)

`/aid-document architecture` is a thin **kind-sibling** of **`/aid-create document`**
(`.agents/skills/aid-create/references/document.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: architecture}`),
`repurpose: true` (skipped by `build-shortcut-skills.py`; hand-authored). It carries
**no logic of its own.**

Execute `.agents/skills/aid-create/references/document.md` exactly as written, with the
document **genre bound to architecture** (structure: components, boundaries, and
interactions -- C4/arc42 views + Mermaid diagrams) and the **format = markdown**.
Substitute only the invocation name in any printed usage example
(`/aid-document architecture` instead of `/aid-create document`). Deeper genre
structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.
