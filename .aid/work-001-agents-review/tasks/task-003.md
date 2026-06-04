# task-003: Derive the target roster + format/generation decision (FR3)

**Type:** DESIGN

**Source:** feature-001-roster-design → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Derive the minimal target roster by intersecting the needs matrix (task-001) with the audit (task-002) under the ranked principles, applying derivation rules R1–R5 (feature-001 SPEC → Process Flow steps 3–4; Roster-derivation criteria).
- Produce `design/target-roster.md`: one row per `proposed_agent` with `single_responsibility`, `covers_needs`, `consumers`, `proposed_tier`, `derivation_rationale`; each keep/merge/rename/drop decision records which rule fired.
- Add the two required sub-sections: **Format decision** (choose one of the four weighed options — status-quo / shared-include / single-file-per-agent / consolidated-manifest, justified against principle 3) and **Generation decision** (how definitions emit into the 5 trees, referencing `render_agents.py`'s per-format branches; must note the `aid-generate` stale "three trees"/`--tool` refs as input to feature-002 FR7).
- Inputs: artifacts (a) and (b); `coding-standards.md §8e`; the boilerplate template sources; `render_agents.py` format branches; `profiles/*.toml [agent]` blocks.
- Do NOT author definitions, rewire dispatch sites, run the generator, or write outside `design/target-roster.md`. No source/tree mutation.

**Acceptance Criteria:**
- [ ] AC2: every roster row's `covers_needs` is non-empty (R4) and references valid `needs-matrix` rows; pairwise `single_responsibility` check finds no overlap (R1).
- [ ] Each disposition records the firing rule (R1–R5); no rule targets a specific final count (R5 / §6 count-neutrality).
- [ ] Format AC: the *Format decision* names one of the four weighed options and justifies it against principle 3 + the buildable/4-format render constraint (decision criteria i–iv).
- [ ] The *Generation decision* states whether `render_agents.py`/`profiles` need changes and flags the `aid-generate` stale-refs as a feature-002 FR7 input.
- [ ] DESIGN baseline: ≥2 format/generation alternatives compared with trade-offs; the recommendation is actionable and grounded in cited KB.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
