# task-028: aid-triage routing-mapping test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-027

**Scope:**
- Canonical test with a fixture mapping table of representative descriptions -> correct target: "fix the login crash" -> `/aid-fix`; "add a /orders REST endpoint" -> `/aid-create-api`; "rename OrderSvc everywhere" -> `/aid-refactor`; "write an ADR for the DB choice" -> `/aid-document-decision`; "rewrite the billing subsystem across 4 services" -> `/aid-describe` (broad); genuinely ambiguous -> `/aid-describe`.
- Routes-only proof: after a `/aid-triage` run, no `.aid/work-*/` folder and no `STATE.md` are created; `allowed-tools` excludes Write/Edit.
- Catalog resolution: every suggested `name` exists as a canonical (non-alias) row in `shortcut-catalog.yml` (requires the full catalog from deliveries 002/003).

**Acceptance Criteria:**
- [ ] Fixture descriptions resolve to the correct targets (canonical names, or `/aid-describe` for broad/ambiguous) (AC-13).
- [ ] Routes-only: no work folder/STATE created; `allowed-tools` excludes Write/Edit (FR-13).
- [ ] Every suggested name exists as a canonical (non-alias) catalog row.
- [ ] Test is deterministic with clean setup/teardown; covers feature-014 ACs.
- [ ] All §6 quality gates pass.
