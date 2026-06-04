# task-001: Build the needs→role matrix (demand side, FR1)

**Type:** RESEARCH

**Source:** feature-001-roster-design → delivery-001

**Depends on:** — (none)

**Scope:**
- Catalogue the demand side: produce `design/needs-matrix.md` with one row per (skill phase × distinct agent-work need), derived from the *process*, independent of today's agents (feature-001 SPEC → Deliverable Artifact (a); Process Flow step 1).
- Inputs to read: the 12 consumers' `SKILL.md` + `references/state-*.md` under `canonical/skills/` (the 11 user-facing skills) plus the maintainer-only `aid-generate` at `.claude/skills/aid-generate/`; `architecture.md` skill inventory + phase/tier model.
- Populate every schema field per row: `consumer`, `phase / state`, `need` (stated as a capability), `tier-pressure` (advisory, per the three-tier model in `architecture.md`), `reuse-count` (distinct consumers sharing the need), `source-evidence` (file:section citation).
- Do NOT decide the roster, audit existing agents, or write any file outside `design/needs-matrix.md`. No `canonical/`, `profiles/`, KB, or install-tree mutation.

**Acceptance Criteria:**
- [ ] AC1 consumer two-way set-equality holds: `set(matrix.consumer) == {11 canonical/skills/ dirs} ∪ {aid-generate}`, empty-diff in both directions.
- [ ] AC1 phase/state two-way set-equality holds: `set(matrix.(consumer, phase/state) pairs) == set((skill, state) pairs across all SKILL.md dispatch tables / `references/state-*.md` file stems)`, empty-diff both directions.
- [ ] Every row carries all six schema fields, with a verifiable `source-evidence` file:section citation per row.
- [ ] RESEARCH baseline: ≥2 phase/need-derivation sources cited (SKILL.md dispatch tables AND references/state-*.md); the matrix is derived from the process, not back-filled from the current agent set.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
