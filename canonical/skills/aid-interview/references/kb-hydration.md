# Knowledge Base Hydration Process

After interview completion (all sections filled), extract information from
REQUIREMENTS.md into the Knowledge Base documents. This is critical for greenfield
projects where no `/aid-discover` phase runs.

For brownfield projects, this step refines KB docs with requirements-level information
that discovery may not have captured.

---

## Mapping: REQUIREMENTS.md → KB Documents

| KB Document | Primary Sources | What to Extract |
|-------------|----------------|-----------------|
| technology-stack.md | §7 Constraints, §6 NFRs | Languages, frameworks, runtimes, build tools, package managers |
| coding-standards.md | §6 NFRs | Linting rules, test coverage targets, build policy, naming conventions |
| architecture.md | §5 FRs (structure hints), §7 Constraints | High-level architecture pattern, component relationships, data flow |
| project-structure.md | §7 Constraints, §5 FRs | Folder layout, module organization (if discussed) |
| data-model.md | §5 FRs | Entities, relationships, storage format (if discussed) |
| api-contracts.md | §5 FRs | API endpoints, protocols (if applicable) |
| integration-map.md | §8 Dependencies | External services, third-party integrations |
| domain-glossary.md | All sections | Domain-specific terms used throughout the interview |
| test-landscape.md | §6 NFRs | Testing strategy, frameworks, coverage goals |
| security-model.md | §6 NFRs | Auth, encryption, data protection (if applicable) |
| infrastructure.md | §7 Constraints, §8 Assumptions | VCS, CI/CD, deployment targets, hosting, PM tools |
| ui-architecture.md | §5 FRs, §6 NFRs | UI framework, target devices, responsive strategy, HUD/layout |
| tech-debt.md | — | Skip for greenfield (no existing debt). Brownfield: leave to /aid-discover |
| feature-inventory.md | — | Skip — populated after feature decomposition |
| external-sources.md | — | Already populated by /aid-init |

---

## Process

### Step 1: Extract and Write

For each KB document in the mapping above:

1. Scan REQUIREMENTS.md for information matching the "What to Extract" column
2. If substantive content exists (more than a passing mention):
   - Write a proper document with the extracted information
   - Use the document's natural structure — not a copy-paste from requirements
   - Update the header: `**Status:** ✅ From Interview` and `**Last Updated:** {date}`
3. If only minimal info exists:
   - Write what's known
   - Update the header: `**Status:** ⚠️ Partial — From Interview`
4. If nothing relevant was discussed:
   - Leave as "Pending" — will be addressed in gap check

### Step 2: Gap Check

After extraction, review which KB docs are still "Pending" or "Partial".

For each, assess: **Would the user reasonably know this at this stage?**

| Likely knows (ASK) | Likely doesn't know yet (SKIP) |
|---------------------|-------------------------------|
| Technology preferences | Detailed architecture (evolves during specify) |
| Coding conventions they follow | Module map (emerges during development) |
| Deployment target / hosting | API contract details (defined during specify) |
| PM tools they use | Data model specifics (defined during specify) |
| Testing philosophy | Security model details (unless security-focused) |
| Domain terminology | Integration specifics (unless integration-focused) |

### Step 3: Ask Targeted Questions

For each "Likely knows" gap, ask ONE question at a time:

```
[KB Gap: {document name}]

{question}

This helps fill the project Knowledge Base so future phases have full context.

[1] Skip — will figure it out later
[2] Your answer: ___
```

After each answer:
1. Update the KB document with the new information
2. Update REQUIREMENTS.md if the answer adds requirement-level info
3. Update INTERVIEW-STATE.md section status if relevant

### Step 4: Update Meta-Documents

After all KB docs are processed:
1. Update `.aid/knowledge/README.md` completeness table — change status per document
2. Update `.aid/knowledge/INDEX.md` summary column with one-line descriptions
3. Add Change Log entry in REQUIREMENTS.md: `| {date} | KB hydrated from interview | /aid-interview |`
4. Add Revision History entry in README.md: `| {date} | aid-interview | KB hydrated from work-{NNN} requirements |`

---

## Guidelines

- **Don't invent information.** Only write what was explicitly stated or clearly implied.
- **Don't over-fill.** A 5-line technology-stack.md is fine if that's all we know.
- **Don't block on gaps.** If the user says "skip", respect it. The info will emerge later.
- **Brownfield rule:** Only update KB docs where requirements ADD information that
  discovery didn't capture. Never overwrite discovery content.
- **Keep it natural.** Each KB doc should read like a standalone document, not a
  requirements dump reformatted into a different file.
- **Respect N/A.** If a doc is genuinely not applicable (e.g., api-contracts.md for an
  offline game), mark it `N/A` in README.md and move on.
