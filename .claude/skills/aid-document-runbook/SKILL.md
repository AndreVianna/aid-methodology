---
name: aid-document-runbook
description: >
  Write a runbook in one pass -- an operational procedure, from trigger through diagnostic
  and remediation to escalation. Use this skill when you already know the document you need
  is runbook, and want it drafted now rather than planned. It is grounded in, and accuracy-
  checked against, the Knowledge Base (`.aid/knowledge/`) and the project source; aid-tech-
  writer produces it and aid-reviewer verifies it. It resolves nothing: it drafts, you
  approve, and only then is the document placed. It never writes into `.aid/knowledge/`. A
  thin kind-sibling of `/aid-create-document`, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<operation/alert> -- the runbook"
---

# Document Runbook (runbook kind-sibling of /aid-create-document)

`/aid-document-runbook` is a thin **kind-sibling** of **`/aid-create-document`**
(`.claude/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: runbook}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.claude/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to runbook** (structure: trigger -> diagnostic -> remediation ->
escalation) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-runbook` instead of `/aid-create-document`).
Deeper genre structures: `.claude/aid/templates/shortcut-scaffolding/document.md`.
