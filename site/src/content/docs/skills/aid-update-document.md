---
title: 'aid-update-document'
description: 'Alias of /aid-change-document -- update an EXISTING document NOW (revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, ...) in one pass.'
generatedFrom: 'canonical/skills/aid-update-document/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-update-document/SKILL.md -->

## Frontmatter

- **`name`** — aid-update-document
- **`description`** — Alias of /aid-change-document -- update an EXISTING document NOW (revise/extend a markdown doc, an ADR, a runbook, a changelog, a diagram, ...) in one pass. Reads the existing document first, then edits it, grounded in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source; produced by aid-tech-writer, verified by aid-reviewer. It RESOLVES NOTHING -- drafts the change, you approve (with a diff shown), then it is written back. NEVER writes into .aid/knowledge/. This file carries no logic of its own -- its full behavior is defined by canonical/skills/aid-change-document/SKILL.md.
- **`allowed-tools`** — Read, Glob, Grep, Bash, Write, Edit, Agent
- **`argument-hint`** — &lt;document + change> -- which existing document to update, and how

[Definition: `canonical/skills/aid-update-document/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-document/SKILL.md)

<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->
