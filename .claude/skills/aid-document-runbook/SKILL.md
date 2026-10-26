---
name: aid-document-runbook
description: >
  Write a runbook (operational procedure) in one pass. Use when you need one drafted now.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<operation/alert> -- the runbook"
---

# Document Runbook (runbook kind-sibling of /aid-create-document)

`/aid-document-runbook` is a thin **kind-sibling** of **`/aid-create-document`**
(`.agents/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: runbook}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to runbook** (structure: trigger -> diagnostic -> remediation ->
escalation) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-runbook` instead of `/aid-create-document`).
Deeper genre structures: `.aid/runtime/templates/shortcut-scaffolding/document.md`.
