# task-008: Rewire the aid-execute dispatch cluster (FR6, high-density)

**Type:** REFACTOR

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-006

**Scope:**
- Apply the rewire map from `design/migration-map.md` to the `aid-execute` skill tree — the second high-density cluster (~120 agent-name occurrences) across `canonical/skills/aid-execute/SKILL.md` + `canonical/skills/aid-execute/references/*.md` (incl. `reviewer-{brief,guide}.md`, `task-type-rules.md`) (feature-002 SPEC → Rewire Mechanism).
- Disposition handling: `keep` → no edit; `rename` → word-boundary replace; `merge` → collapse olds to single `new_agent` (dedupe within a dispatch list); `drop` → remove reference + dispatch logic per `dispatch_rewrite_hint`.
- Edit canonical SOURCE only. Do NOT run the generator, edit any `profiles/<tool>/` generated tree, or touch the repo-root `.claude/` dogfood mirror.

**Acceptance Criteria:**
- [ ] Every OLD-name occurrence in the `aid-execute` tree whose disposition ∈ {merge, rename, drop} is rewired; `keep` names are untouched.
- [ ] All replacements use word-boundary matching — no substring corruption.
- [ ] `drop` dispositions leave zero surviving references and restructure the dispatch per `dispatch_rewrite_hint`.
- [ ] No edits land in any `profiles/<tool>/` generated tree or the repo-root `.claude/` dogfood tree.
- [ ] REFACTOR baseline: dispatch behavior unchanged except for the agent each step names.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
