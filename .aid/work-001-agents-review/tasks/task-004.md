# task-004: Produce the old→new migration map (FR4)

**Type:** DESIGN

**Source:** feature-001-roster-design → delivery-001

**Depends on:** task-003

**Scope:**
- Produce `design/migration-map.md`: exactly 22 rows (one per existing agent from artifact (b)), each with a disposition from the closed enum `keep | merge | rename | drop` (feature-001 SPEC → Process Flow step 5; Migration Plan considerations; Deliverable Artifact (d)).
- Populate every field per row: `old_agent`, `disposition`, `new_agent` (merge/rename destination; empty for `drop`), `rationale` (one line tied to the firing rule), `dispatch_rewrite_hint` (the *class* of dispatch sites feature-002 FR6 must rewire, referencing measured breadth).
- Ensure the map is internally closed: the set of non-blank `new_agent` values equals the proposed roster from `target-roster.md` (task-003); every roster agent is reachable from ≥1 old agent or marked net-new with rationale; no proposed agent depends on a dropped agent.
- This is the deterministic input contract handed to feature-002. Do NOT execute any rewrite or write outside `design/migration-map.md`. No source/tree mutation.

**Acceptance Criteria:**
- [ ] AC3: exactly 22 rows whose `old_agent` set equals the 22 dirs under `canonical/agents/`; each row has an enum disposition and a non-empty `rationale`.
- [ ] Every `merge`/`rename` row names an exact `new_agent`; every `drop` row has an empty `new_agent` and no roster agent depends on it.
- [ ] Closure holds: non-blank `new_agent` set == proposed-roster set from `target-roster.md`, empty-diff both directions.
- [ ] Every row carries a `dispatch_rewrite_hint` naming the dispatch-site class(es) for feature-002 FR6/FR9.
- [ ] DESIGN baseline: each disposition is justified against a ranked principle/rule; no new roster decision is introduced beyond task-003's roster.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
