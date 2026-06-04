# task-009: Rewire the remaining canonical/skills mid+tail clusters (FR6)

**Type:** REFACTOR

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-006

**Scope:**
- Apply the rewire map from `design/migration-map.md` to every remaining `canonical/skills/<skill>/SKILL.md` + `canonical/skills/<skill>/references/*.md` (ALL reference docs, not only `state-*.md`) outside the `aid-discover` and `aid-execute` trees — the mid cluster and low tail (`aid-config`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`) (feature-002 SPEC → Rewire Mechanism). This matches the broad `SKILL.md + references/*.md` rewire surface used by tasks 007/008; whole-word agent role-nouns (`reviewer`, `developer`, `architect`, `orchestrator`, incl. live `subagent_type:` dispatch values) appear in many NON-state reference files (e.g. `aid-plan/references/first-run-loop.md`, `aid-detail/references/{first-run,review,task-decomposition}.md`, the four `references/reviewer-brief.md` files, and the escalation docs), so the rewrite must cover them.
- Disposition handling: `keep` → no edit; `rename` → word-boundary replace; `merge` → collapse olds to single `new_agent` (dedupe within a dispatch list); `drop` → remove reference + dispatch logic per `dispatch_rewrite_hint`.
- Word-boundary caveat: only whole-word agent-name matches are rewired (e.g. live `subagent_type: reviewer`/`architect` values); leave substrings like `architecture`/`architectural` intact.
- Edit canonical SOURCE only. Do NOT run the generator, edit any `profiles/<tool>/` generated tree, or touch the repo-root `.claude/` dogfood mirror. The maintainer-only `aid-generate` SOURCE-exception is handled in its own task (task-011), not here.

**Acceptance Criteria:**
- [ ] Every OLD-name occurrence in the remaining `canonical/skills/<skill>/SKILL.md` + `canonical/skills/<skill>/references/*.md` (ALL reference docs, not only `state-*.md`) whose disposition ∈ {merge, rename, drop} is rewired; `keep` names untouched.
- [ ] Zero-gap union — every `canonical/**` entry that task-014 sweeps is owned by exactly one rewire task: task-006 authors/owns `canonical/agents/`; tasks 007/008/009 own `canonical/skills/**` — task-007 (`aid-discover` SKILL.md + references/*.md) + task-008 (`aid-execute` SKILL.md + references/*.md) + this task (the other 9 skills' SKILL.md + references/*.md); task-010 owns `canonical/{templates,recipes,scripts,rules}/` + `canonical/EMISSION-MANIFEST.md` + the aid-generate SOURCE-exception. That union equals `canonical/**` exactly — ZERO unowned surface.
- [ ] All replacements use word-boundary matching — no substring corruption (e.g. `architecture`/`architectural` left intact).
- [ ] `drop` dispositions leave zero surviving references and restructure the dispatch per `dispatch_rewrite_hint`.
- [ ] No edits land in any `profiles/<tool>/` generated tree or the repo-root `.claude/` dogfood tree.
- [ ] REFACTOR baseline: dispatch behavior unchanged except for the agent each step names.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
