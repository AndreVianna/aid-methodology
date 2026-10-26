# Document Decision (ADR kind-sibling of /aid-create document)

`/aid-document decision` is a thin **kind-sibling** of **`/aid-create document`**
(`.agents/skills/aid-create/references/document.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: decision}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-create/references/document.md` exactly as written, with the
document **genre bound to ADR** (structure: Context -> Decision -> Alternatives ->
Consequences) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document decision` instead of `/aid-create document`).
Deeper genre structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.
