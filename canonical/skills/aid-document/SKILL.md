---
name: aid-document
description: >
  Write a document outside the KB: how-to, runbook, decision, tutorial, changelog and
  more. Use when one is needed.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "[kind] <subject> -- kind: architecture, changelog, decision, guideline, runbook, standard, tutorial; or a general how-to/reference"
---

# Document (general kind-sibling of /aid-create document)

**Kinds.** When the argument starts with one of these kinds, read `references/<kind>.md` in this skill's folder and follow it
with the rest of the argument instead of the steps below: `architecture`, `changelog`, `decision`, `guideline`, `runbook`, `standard`, `tutorial`.

`/aid-document` is a thin **kind-sibling** of **`/aid-create document`**
(`.agents/skills/aid-create/references/document.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: ""}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-create/references/document.md` exactly as written, with the
document **genre bound to general** (structure: a Diataxis how-to / reference /
explanation, or a status/progress report) and the **format = markdown**. Substitute only
the invocation name in any printed usage example (`/aid-document` instead of
`/aid-create document`). Deeper genre structures:
`.aid/runtime/templates/shortcut-scaffolding/document.md`.
