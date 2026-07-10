---
kb-category: meta
source: generated
objective: Completeness tracker and revision history for the AID Knowledge Base.
summary: Lists every document in the confirmed doc-set with its status, and records the revision history of discovery runs. Start at INDEX.md for per-document summaries.
sources:
  - .aid/settings.yml
  - .aid/knowledge/STATE.md
tags: [meta, readme, completeness]
see_also: [INDEX.md, STATE.md]
owner: skill-self
audience: [developer, architect, product]
---

# Knowledge Base — AID

This Knowledge Base describes **AID (AI Integrated Development)** — a full-lifecycle
methodology for building software with AI agents, delivered as a multi-profile CLI installer.

- **Domain:** hybrid:methodology-tooling+software-cli
- **Doc-set:** 19 documents (curated hybrid composition), confirmed at discovery Step 0d.
- **Discovery path:** brownfield-large.

Read **INDEX.md** for a 2–3 line summary of every document. Read **STATE.md** for discovery
run-state, grades, and open questions.

## Index

- [Completeness](#completeness)
- [Revision History](#revision-history)
- [Change Log](#change-log)

## Completeness

> One row per document in the confirmed doc-set (`discovery.doc_set`). "Generated" = authored
> this discovery run; semantic grading happens in the REVIEW state.

| # | Document | Concern | Owner | Status |
|---|----------|---------|-------|--------|
| 1 | project-structure.md | C1 | scout | Generated |
| 2 | external-sources.md | meta | scout | Generated |
| 3 | architecture.md | C1 | architecture | Generated |
| 4 | technology-stack.md | C0 | architecture | Generated |
| 5 | module-map.md | C2 | analyst | Generated |
| 6 | coding-standards.md | C3 | analyst | Generated |
| 7 | authoring-conventions.md | C3 | analyst | Generated |
| 8 | artifact-schemas.md | C5 | analyst | Generated |
| 9 | pipeline-contracts.md | C2 | integrator | Generated |
| 10 | integration-map.md | C2 | integrator | Generated |
| 11 | domain-glossary.md | C4 | integrator | Generated |
| 12 | test-landscape.md | C6 | quality | Generated |
| 13 | quality-gates.md | C6 | quality | Generated |
| 14 | tech-debt.md | C7 | quality | Generated |
| 15 | infrastructure.md | C8 | quality | Generated |
| 16 | release-tracking.md | C8 | skill-self | Restored (hand-authored) |
| 17 | capability-inventory.md | C9 | skill-self | Generated |
| 18 | decisions.md | D | architecture | Generated |
| 19 | README.md | meta | skill-self | Generated |
| — | INDEX.md | meta | skill-self | Generated (build-kb-index.sh) |

Spine coverage: all 11 dimensions (C0–C9 + D) covered; see STATE.md `## Discovery Domain`
and the doc-set proposal for the per-dimension mapping.

## Revision History

| # | Date | Update |
|---|------|--------|
| 1 | 2026-06-25 | Initial generation. Domain classified (hybrid:methodology-tooling+software-cli), 18-doc doc-set confirmed, brownfield-large fan-out (4 lanes), concept-spine closure (29 grounded / 80 excluded / 0 ungrounded). |
| 2 | 2026-06-25 | Restored `release-tracking.md` (hand-authored release ledger) as a 19th doc-set member (C8, skill-self); doc-set, STATE, and INDEX updated to match. Resolves the dangling `infrastructure.md` reference. |
| 3 | 2026-07-09 | /aid-housekeep KB-DELTA refresh — reconciled the KB with the work-002 connectors subsystem (PR #133) across 15 docs: connector-catalog capability + section (capability-inventory, integration-map), Connector Registry vocabulary + Connectors lexicon (domain-glossary), D19 catalog-not-manager decision (decisions), connector descriptor/`secret_reference` schemas (artifact-schemas), `connectors/` script area + test coverage (module-map; test-landscape 82→105 suites), aid-discover ELICIT wiring (architecture, pipeline-contracts, capability-inventory), P7 write-zone + connector-secret convention (coding-standards), `forward-authored` source enum (authoring-conventions), `.gitguardian.yaml`/`.mcp.json`/`.secrets` infra (infrastructure). Plus accumulated release-drift fixes (version de-hardcoded to `VERSION` across architecture/infrastructure/project-structure/technology-stack; Shell count 327→376) and two Unreleased entries (release-tracking). INDEX regenerated. |
| 4 | 2026-07-09 | work-001-lite-aid-skills KB refresh — reconciled the KB with the direct-entry shortcut system (PR #134) across 12 docs. Skill taxonomy 14 → **82 skill dirs** (14 classic + `/aid-triage` + 67 shortcuts from a 69-row catalog) everywhere (capability-inventory, architecture, module-map, project-structure, pipeline-contracts). Recipe catalog + `parse-recipe.sh` removal (C5) purged from architecture, module-map, project-structure, domain-glossary, technology-stack, pipeline-contracts, artifact-schemas. `/aid-describe` full-only + standalone `/aid-triage` router + three-entry model + shortcut engine (capability-inventory, architecture, domain-glossary, pipeline-contracts). `BLUEPRINT.md`/`DETAIL.md` + nested `deliveries/` rename and flattened-Lite (no per-task STATE.md) shape (artifact-schemas, pipeline-contracts, project-structure, module-map, domain-glossary); fixed dangling cites to the deleted `delivery-spec-template.md`/`task-spec-template.md`. `/aid-monitor` re-point BUG→`/aid-fix`, CR→`/aid-triage` (pipeline-contracts L9/L10, capability-inventory, architecture). test-suite count 105 → **118** (test-landscape); global gate `A`→`A+` corrected (quality-gates). tech-debt: closed L7/M2/L1, added L8 (writeback `--task-id` octal footgun) + L9 (generate-profile 14-skill VALIDATE). 6 new ADRs D20–D25 + D14 superseded (decisions). INDEX regenerated. |

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-25 | Initial KB README generated by /aid-discover. |
| 1.1 | 2026-06-25 | Added release-tracking.md to the doc-set (19 docs). |
| 1.2 | 2026-07-09 | /aid-housekeep KB-DELTA connectors + release-drift refresh (15 docs); INDEX regenerated. |
| 1.3 | 2026-07-09 | work-001-lite-aid-skills KB refresh (12 docs): shortcut system (82 skills), recipe removal, `/aid-triage`, describe-full-only, monitor re-point, BLUEPRINT/DETAIL rename, D20–D25 ADRs; INDEX regenerated. |
