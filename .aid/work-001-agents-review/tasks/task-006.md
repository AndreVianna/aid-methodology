# task-006: Author the new agent definitions in the decided format (FR5)

**Type:** IMPLEMENT

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-005

**Scope:**
- For each `proposed_agent` row in `design/target-roster.md`, create/update `canonical/agents/<proposed_agent>/` in the format named by the *Format decision*, applying authoring best practices and reduced boilerplate (the duplicated `## Heartbeat protocol` + `## Self-review discipline` blocks per `coding-standards.md §8e`) (feature-002 SPEC → Rollout Process Flow step 1; AC7).
- For each `drop` agent in `design/migration-map.md`, remove its `canonical/agents/<old>/` directory.
- Edit canonical SOURCE only (`canonical/agents/`). Do NOT rewire dispatch sites, run the generator, hand-edit any `profiles/<tool>/` generated tree, or touch the repo-root `.claude/` dogfood mirror.
- After this task, the `canonical/agents/` directory set must equal the proposed-roster set (no dropped dir survives, no proposed agent missing).

**Acceptance Criteria:**
- [ ] AC7: every new/updated `canonical/agents/<a>/` conforms to the structure mandated by the *Format decision*, with the boilerplate burden reduced as that decision specifies.
- [ ] `canonical/agents/` directory set equals the `proposed_agent` set from `target-roster.md` (empty-diff both directions); all `drop` dirs are removed.
- [ ] No edits land in any `profiles/<tool>/` generated tree or the repo-root `.claude/` dogfood tree.
- [ ] IMPLEMENT baseline: each definition is renderable into all 4 formats (`markdown`/`toml`/`copilot-agent`/`antigravity-rule`) without new per-tool special-casing (decision criterion ii).
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
