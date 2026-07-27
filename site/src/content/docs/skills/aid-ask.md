---
title: 'aid-ask'
description: 'Friendly-named alias of /aid-query-kb -- the optional on-demand Q&A skill.'
generatedFrom: 'canonical/skills/aid-ask/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/aid-ask/SKILL.md -->

## Frontmatter

- **`name`** — aid-ask
- **`description`** — Friendly-named alias of /aid-query-kb -- the optional on-demand Q&amp;A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an answer with source citations. When the available context cannot answer the question, states the gap explicitly and captures it as a Query-Gap entry so it feeds the KB-improvement loop. This file carries no logic of its own -- its full behavior is defined entirely by canonical/skills/aid-query-kb/SKILL.md, which this skill delegates to.
- **`allowed-tools`** — Read, Glob, Grep, Agent, Write, Edit
- **`argument-hint`** — &lt;question>  — a free-form question about the project

[Definition: `canonical/skills/aid-ask/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md)

<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->
