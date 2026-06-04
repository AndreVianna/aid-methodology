# task-002: Audit all 22 existing agents (supply side, FR2)

**Type:** RESEARCH

**Source:** feature-001-roster-design → delivery-001

**Depends on:** — (none)

**Scope:**
- Catalogue the supply side: produce `design/current-audit.md` with exactly one row per existing agent — all 22 dirs under `canonical/agents/` (feature-001 SPEC → Deliverable Artifact (b); Process Flow step 2).
- Inputs to read: each `canonical/agents/<a>/AGENT.md` + `README.md`; a word-boundary name-grep of dispatch sites across `canonical/skills/` + `references/` (re-confirm the cross-ref measurements, e.g. `reviewer` ~392 refs/74 files down to `operator` in 2 files).
- Populate every schema field per row: `agent`, `tier`, `agent_md_lines`, `dispatched_by`, `dispatch_breadth`, `responsibility`, `overlap_flags`, `boilerplate_burden`, `evidence`.
- Record the disk-measured boilerplate truth (per A5: Heartbeat in all 22, Self-review in 19, absent only in `discovery-reviewer`/`orchestrator`/`reviewer`) — note where it contradicts stale KB claims, but do NOT fix KB here.
- Do NOT decide dispositions, derive the roster, or write outside `design/current-audit.md`. No source/KB/tree mutation.

**Acceptance Criteria:**
- [ ] Exactly 22 rows; the `agent` set equals the 22 dirs under `canonical/agents/` (empty-diff both directions).
- [ ] Every row carries all nine schema fields with file:section `evidence` for the dispatch-breadth and overlap claims.
- [ ] `dispatch_breadth` per row is re-measured with word-boundary matching (no `architect` ⊂ `discovery-architect` false positives).
- [ ] RESEARCH baseline: dispatch + overlap claims are sourced (file:section citations), and the audit is the measured supply state, not a proposed disposition.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
