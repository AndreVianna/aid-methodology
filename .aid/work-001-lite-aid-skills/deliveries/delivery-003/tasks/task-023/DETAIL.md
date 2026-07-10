# task-023: Document family -- catalog rows + document.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-008, task-009

**Scope:**
- Add 8 rows to `canonical/aid/templates/shortcut-catalog.yml` (no aliases): `aid-document` (bare) + `-decision`, `-architecture`, `-guideline`, `-standard`, `-runbook`, `-tutorial`, `-changelog`; all `default_type: DOCUMENT`, group G8.
- Create `canonical/aid/templates/shortcut-scaffolding/document.md`: the 8 archetype document shapes (general Diataxis/status-report; ADR Context->Decision->Alternatives->Consequences; architecture C4/arc42 Mermaid; guideline principle/rationale/do-don't; standard rule/scope/compliance/exceptions; runbook trigger->diagnostic->remediation->escalation; tutorial prerequisites->steps->outcome; changelog Added/Changed/Fixed/Removed/Security) + thin CAPTURE (subject/audience + archetype fields); single DOCUMENT task each; Data Model "no schema changes". Only the status/progress-report half of the old add-report lands here (bare `aid-document`); the analytical half is ceded to G11 `aid-report`.
- Generate the 8 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 8 rows/dirs added; all DOCUMENT; the artifact suffix selects the document structure (not a synonym) (AC-1 G8 subset).
- [ ] `document.md` defines the 8 archetype shapes; the ownership boundary cedes analytical reports to G11.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
