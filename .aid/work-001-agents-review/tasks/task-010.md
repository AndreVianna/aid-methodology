# task-010: Rewire non-skill SOURCE surfaces — templates, recipes, scripts, rules, EMISSION-MANIFEST + the aid-generate SOURCE-exception (FR6)

**Type:** REFACTOR

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-006

**Scope:**
- Apply the rewire map from `design/migration-map.md` to every agent-naming file under `canonical/templates/*` (~36 files — heartbeat/self-review protocol references, delivery-plan/spec templates that assign agents to tasks), `canonical/recipes/*` (recipe steps that name an agent), `canonical/scripts/**` (empirically contains agent role-noun references — e.g. `reviewer`/`orchestrator` in `grade.sh`, `kb/discover-preflight.sh`, `summarize/manual-checklist.sh`, `summarize/grade-summary.sh`, `execute/writeback-state.sh`), and `canonical/rules/*` (feature-002 SPEC → Rewire Mechanism). This task owns ALL non-skill `canonical/**` agent-naming surfaces; the `canonical/skills/` surface is split across tasks 007/008/009.
- Also rewire the top-level SOURCE file `canonical/EMISSION-MANIFEST.md` for any non-`keep` whole-word agent-name occurrence (same word-boundary caveat). Empirically it holds only whole-word `architect` in path references (e.g. `canonical/agents/architect.md`, `.codex/agents/architect.toml`) for a surviving (`keep`) agent, so it is a covered-but-likely-no-op surface — bring it under scope so the FR9 sweep (task-014) has no unowned `canonical/**` top-level entry, even if no edit lands.
- Word-boundary caveat: only whole-word agent-name matches (per `design/migration-map.md`) are rewired. Do NOT touch unrelated substrings (e.g. leave `architecture`/`architectural` and any non-agent compound names intact). `canonical/rules/` empirically holds only `architecture`/`architectural` (no whole-word agent names), so it is a covered-but-likely-no-op surface — bring it under scope so the FR9 sweep (task-014) has no unowned `canonical/**` surface, even if no edit lands.
- Also rewire any agent name in the maintainer-only `aid-generate` SOURCE-exception (hand-edited in place at `.claude/skills/aid-generate/`, since it is not a generator output and not in `canonical/`). This is the FR6 agent-name rewrite only — the FR7 stale "three trees"/`--tool` fix is a separate task (task-011).
- Disposition handling: `keep` → no edit; `rename` → word-boundary replace; `merge` → collapse olds to single `new_agent` (dedupe); `drop` → remove the reference and the dispatch logic per `dispatch_rewrite_hint`.
- Edit hand-edited SOURCE only (`canonical/templates/`, `canonical/recipes/`, `canonical/scripts/`, `canonical/rules/`, `canonical/EMISSION-MANIFEST.md`, `.claude/skills/aid-generate/`). Do NOT run the generator, edit any `profiles/<tool>/` generated tree, or touch the repo-root `.claude/` dogfood mirror.

**Acceptance Criteria:**
- [ ] Every OLD-name occurrence in `canonical/templates/` + `canonical/recipes/` + `canonical/scripts/` + `canonical/rules/` + `canonical/EMISSION-MANIFEST.md` + `.claude/skills/aid-generate/` whose disposition ∈ {merge, rename, drop} is rewired; `keep` names untouched.
- [ ] Zero-gap union — every `canonical/**` entry that task-014 sweeps is owned by exactly one rewire task: task-006 authors/owns `canonical/agents/`; tasks 007/008/009 own `canonical/skills/**` (each skill's `SKILL.md` + `references/*.md`); this task (task-010) owns `canonical/{templates,recipes,scripts,rules}/` + `canonical/EMISSION-MANIFEST.md` + the aid-generate SOURCE-exception (`.claude/skills/aid-generate/`). That union equals `canonical/**` exactly — zero unowned surface.
- [ ] All replacements use word-boundary matching — no substring corruption (e.g. `architecture`/`architectural` left intact).
- [ ] `drop` dispositions leave zero surviving references in templates/recipes/scripts/rules/EMISSION-MANIFEST/aid-generate.
- [ ] No edits land in any `profiles/<tool>/` generated tree or the repo-root `.claude/` dogfood tree.
- [ ] REFACTOR baseline: template/recipe/script/rule structure and behavior unchanged except for the agent each names.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.
