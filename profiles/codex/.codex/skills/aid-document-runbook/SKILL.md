---
name: aid-document-runbook
description: >
  Write a runbook NOW -- an operational procedure (trigger -> diagnostic -> remediation
  -> escalation) -- in one pass. A thin kind-sibling of /aid-create-document with the
  document genre bound to runbook. Grounded in and accuracy-checked against the Knowledge
  Base (.aid/knowledge/) and the project source; produced by aid-tech-writer, verified by
  aid-reviewer. It RESOLVES NOTHING -- drafts, you approve, then it is placed. NEVER writes
  into .aid/knowledge/. This file carries no logic of its own -- its full behavior is
  defined by .codex/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<operation/alert> -- the runbook"
---

# Document Runbook (runbook kind-sibling of /aid-create-document)

`/aid-document-runbook` is a thin **kind-sibling** of **`/aid-create-document`**
(`.codex/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: runbook}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.codex/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to runbook** (structure: trigger -> diagnostic -> remediation ->
escalation) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-runbook` instead of `/aid-create-document`).
Deeper genre structures: `.codex/aid/templates/shortcut-scaffolding/document.md`.
