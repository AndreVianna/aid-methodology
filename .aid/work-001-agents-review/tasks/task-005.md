# task-005: Consolidate artifacts + self-consistency check for the approval gate

**Type:** DOCUMENT

**Source:** feature-001-roster-design → delivery-001

**Depends on:** task-004

**Scope:**
- Package the four decision artifacts (`needs-matrix.md`, `current-audit.md`, `target-roster.md`, `migration-map.md`) under `.aid/work-001-agents-review/design/` into the reviewable decision set presented at the work's single human approval gate (feature-001 SPEC → Process Flow step 6; Description).
- Run the pre-approval self-consistency check: verify AC1, AC2, AC3, and the Format/generation AC all hold across the four artifacts per the SPEC's *Acceptance Criteria mapping* (the two-way set-equality diffs, the 22-row check, the non-overlap check, the closure check).
- Record the check outcome and any cross-artifact discrepancies as a short approval-readiness note alongside the artifacts; ensure cross-references between artifacts resolve (covers_needs → needs-matrix rows; new_agent → target-roster rows).
- This is documentation/verification packaging only — no analysis re-derivation, no roster change, no source/KB/tree mutation. If a check fails, flag back to the relevant DESIGN task rather than editing the decision here.

**Acceptance Criteria:**
- [ ] All four artifacts are present, internally cross-resolvable, and named/located per feature-001 A1 (`design/`, combined or split).
- [ ] The self-consistency note records the result of each AC check (AC1 two-way diffs, AC2 non-overlap, AC3 22-row, Format AC) with empty-diff confirmation or an explicit flag.
- [ ] The artifact set is presentable as a single frozen, human-approvable decision (the feature-002 input contract).
- [ ] DOCUMENT baseline: no new decisions introduced; the note only reports verification of existing artifacts.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
