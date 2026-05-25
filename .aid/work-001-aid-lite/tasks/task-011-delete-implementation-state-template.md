# task-011: Delete `canonical/templates/implementation-state.md` + orphan-ref grep sweep

**Type:** IMPLEMENT

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- Verify `canonical/templates/implementation-state.md` is absent (already retired by work-002; this task's "delete" step is a no-op verification rather than an action).
- **Primary work — orphan reference sweep:** grep across `.aid/knowledge/` (data-model.md, architecture.md, module-map.md, feature-inventory.md, api-contracts.md), `.aid/work-001-aid-lite/`, `.aid/work-003-traceability/`, `canonical/`, `profiles/` for any remaining reference to `implementation-state.md`.
- Update KB references to point at the per-area STATE rule (work-003 FR2) as the consolidation mechanism instead.
- Remove stale references in spec/plan/task bodies (excluding historical change-log rows + commit messages).
- Re-run work-002 generator + verify install trees no longer mention the template.

**Acceptance Criteria:**
- [ ] `canonical/templates/implementation-state.md` confirmed absent (already retired).
- [ ] `grep -r 'implementation-state.md' canonical profiles .aid --include='*.md'` returns zero matches in current-state docs (historical change-log rows in REQUIREMENTS / SPECs may still cite it as part of the historical record — those are acceptable; current-state KB docs must not).
- [ ] KB docs (data-model.md, architecture.md, module-map.md, feature-inventory.md, api-contracts.md) updated to reference the per-area STATE rule (work-003 FR2) instead.
- [ ] `canonical/EMISSION-MANIFEST.md` does not claim the file.
- [ ] All §6 quality gates pass.
