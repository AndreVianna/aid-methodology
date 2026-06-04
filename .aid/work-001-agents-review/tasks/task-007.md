# task-007: Rewire the aid-discover dispatch cluster (FR6, high-density)

**Type:** REFACTOR

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-006

**Scope:**
- Apply the `{old_agent → new_agent}` rewire map from `design/migration-map.md` to the `aid-discover` skill tree — the highest-density cluster (~218 agent-name occurrences, including all six `discovery-*` agents) across `canonical/skills/aid-discover/SKILL.md` + `canonical/skills/aid-discover/references/*.md` (feature-002 SPEC → Rewire Mechanism).
- Disposition handling: `keep` → no edit; `rename` → word-boundary textual replace old→new; `merge` → all olds in a group collapse to the single `new_agent` (dedupe within a dispatch list); `drop` → remove the reference and the dispatch logic per the row's `dispatch_rewrite_hint`.
- Edit canonical SOURCE only. Do NOT run the generator, edit any `profiles/<tool>/` generated tree, or touch the repo-root `.claude/` dogfood mirror.

**Acceptance Criteria:**
- [ ] Every OLD-name occurrence in the `aid-discover` tree whose disposition ∈ {merge, rename, drop} is rewired; `keep` names are untouched.
- [ ] All replacements use word-boundary matching — no substring corruption (e.g. `architect` inside `discovery-architect`).
- [ ] `drop` dispositions leave zero surviving references and restructure the dispatch per `dispatch_rewrite_hint`.
- [ ] No edits land in any `profiles/<tool>/` generated tree or the repo-root `.claude/` dogfood tree.
- [ ] REFACTOR baseline: the skill's dispatch behavior is unchanged except for the agent each step names (no pipeline-phase or skill change).
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
