# task-037: feature-007+008 Playwright visual validation (R5 hard gate)

**Type:** TEST

**Source:** feature-007-kb-dashboard + feature-008-skill-task-drilldown → delivery-005

**Depends on:** task-032, task-035, task-034

**Scope:**
- Per the project CLAUDE.md web-review gate (R5, hard): render the served KB dashboard (`#/kb`) and the task drill-down (`#/work/<id>/task/<task-id>`) in Playwright and VISUALLY validate — source/markup inspection is an automatic FAIL.
- Over the grown fixture (task-034, `schema_version: 3`): screenshot/snapshot and confirm —
  - feature-007: the doc inventory table, the freshness/approval indicators across fresh/stale/unapproved states, the summary panel, arrival at `#/kb` from the KB card, back-to-main nav, and the FR18 remediation panels;
  - feature-008: the findings list across severities, the ledger/grade table, the READ-ONLY ESCAPED raw STATE.md viewer (non-editable, deep-anchored), the honest logs panel + FR18 guidance, drill arrival from a task chip, the PARALLEL-drill case (FR14, N independent panels), and back nav;
  - both across mobile/tablet/desktop breakpoints (NFR6), matching the visual family (NFR8).
- Tailscale `serve` may be used to view privately for confirmation if needed.

**Acceptance Criteria:**
- [ ] Both views are rendered in Playwright (screenshots captured) and visually validated; a source-only review is graded FAIL (R5).
- [ ] feature-007 validation confirms the doc table, freshness/approval across fresh/stale/unapproved, the summary panel, the `#/kb` arrival + back nav, and the FR18 remediation panels.
- [ ] feature-008 validation confirms the findings list (across severities), the ledger/grade table, the read-only escaped raw STATE.md viewer (non-editable), the honest logs panel + FR18 guidance, the parallel-drill case (N independent panels, FR14), and back nav.
- [ ] Responsive rendering validated at mobile/tablet/desktop (NFR6); both match the `knowledge-summary.html` visual family (NFR8); live ≤-interval refresh observed (FR4/NFR3).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown (server start/stop) and cover the source ACs (feature-007 + feature-008 visual surface); build passes.
