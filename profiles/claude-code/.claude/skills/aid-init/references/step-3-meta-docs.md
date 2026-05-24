# State: META-DOCS

Write README.md, INDEX.md, and STATE.md to complete the knowledge workspace.

> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [● META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

▶ Writing meta-documents (~5 s)

### .aid/knowledge/README.md

```markdown
# Knowledge Base — {Project Name}

> {One-line description}

## Project Info

| Property | Value |
|----------|-------|
| **Type** | {Brownfield / Greenfield} |
| **Initialized** | {date} |
| **Minimum Grade** | {grade} |
| **External Sources** | {N paths / None} |

## Completeness

| Document | Status | Source |
|----------|--------|--------|
| project-structure.md | ❌ Pending | aid-discover |
| external-sources.md | {⚠️ Paths Registered / ❌ Pending} | aid-init / aid-discover |
| architecture.md | ❌ Pending | aid-discover |
| technology-stack.md | ❌ Pending | aid-discover |
| module-map.md | ❌ Pending | aid-discover |
| coding-standards.md | ❌ Pending | aid-discover |
| data-model.md | ❌ Pending | aid-discover |
| api-contracts.md | ❌ Pending | aid-discover |
| integration-map.md | ❌ Pending | aid-discover |
| domain-glossary.md | ❌ Pending | aid-discover |
| test-landscape.md | ❌ Pending | aid-discover |
| security-model.md | ❌ Pending | aid-discover |
| tech-debt.md | ❌ Pending | aid-discover |
| infrastructure.md | ❌ Pending | aid-discover |
| ui-architecture.md | ❌ Pending | aid-discover |
| feature-inventory.md | ❌ Pending | aid-discover |

## Revision History

| Date | Phase | Description |
|------|-------|-------------|
| {date} | aid-init | Initialized ({brownfield/greenfield}) |
```

### .aid/knowledge/INDEX.md

```markdown
# Knowledge Base Index — {Project Name}

Use this index to find the right document before making assumptions.
If your task touches an area covered here, read the relevant document first.

| Document | Summary |
|----------|---------|
| project-structure.md | Pending discovery |
| external-sources.md | {Pending discovery / N external paths registered} |
| architecture.md | Pending discovery |
| technology-stack.md | Pending discovery |
| module-map.md | Pending discovery |
| coding-standards.md | Pending discovery |
| data-model.md | Pending discovery |
| api-contracts.md | Pending discovery |
| integration-map.md | Pending discovery |
| domain-glossary.md | Pending discovery |
| test-landscape.md | Pending discovery |
| security-model.md | Pending discovery |
| tech-debt.md | Pending discovery |
| infrastructure.md | Pending discovery |
| ui-architecture.md | Pending discovery |
| feature-inventory.md | Pending discovery |
```

### .aid/knowledge/STATE.md

Copy the template from `../../templates/discovery-state-template.md` to
`.aid/knowledge/STATE.md`. Fill in the placeholders:

- `{minimum}` → grade from Q5
- `{Brownfield / Greenfield}` → from Q1
- `{List of paths from init Q4, or "None provided"}` → from Q4

✓ Meta-documents written

**Advance:** Next state is `SETUP` — when this state's work completes, router prints `Next: [State: SETUP] — run /aid-init again` and exits.
