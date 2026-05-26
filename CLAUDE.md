# CLAUDE.md

## Project

**AID (Agentic Implementation Discipline)** — a methodology for orchestrating AI-assisted
software work as a chain of small, reviewable phases (Discover → Interview → Specify →
Plan → Detail → Execute → Deploy → Monitor). This repo is both the **methodology
specification** (`methodology/aid-methodology.md`, 1,071 lines) and a **multi-tool
distribution** of skills/agents/templates/recipes rendered into 3 install trees
(Claude Code, Codex CLI, Cursor) from a single `canonical/` source via
`run_generator.py`.

## Knowledge Base

After running Discovery, the Knowledge Base lives at `.aid/knowledge/INDEX.md`.
Read `INDEX.md` first for a map of all available documentation. Key starting points:
- `architecture.md` — system patterns + module boundaries
- `module-map.md` — per-skill metadata + thin-router line counts
- `coding-standards.md` — authoring conventions including the Thin-Router SKILL.md
  Convention (state-keyed `references/state-*.md` decomposition)
- `tech-debt.md` — current debt items with severity + resolution roadmap

## Build & Test

This repo has **no application code** — it ships skills, agents, templates, and recipes.
Build = render `canonical/` → 3 profile trees. Test = verify the render is correct +
run the canonical helper test suites.

```bash
# Re-generate all 3 install trees from canonical/ (maintainer-only)
python run_generator.py

# Verify the render is byte-correct and complete
python .claude/skills/aid-generate/scripts/verify_deterministic.py

# Validate KB claims against disk
bash canonical/templates/scripts/verify-kb-claims.sh

# Rebuild project file inventory (used by aid-discover Step 0c)
bash canonical/templates/scripts/build-project-index.sh --root . --output .aid/knowledge/project-index.md

# Run the canonical helper test suite (297/297 expected)
bash canonical/templates/scripts/test-writeback-task-status.sh    # 69 tests
bash canonical/templates/scripts/test-delivery-gate-aggregate.sh  # 18 tests
bash canonical/templates/scripts/test-compute-block-radius.sh     # 17 tests
bash canonical/templates/scripts/test-pool-dispatch.sh            #  7 tests
bash canonical/skills/aid-interview/scripts/test-parse-recipe.sh  # 113 tests
bash .aid/work-001-aid-lite/test-reports/e2e-two-tier-runner.sh   # 35 tests
bash .aid/work-001-aid-lite/test-reports/e2e-lite-path-runner.sh  # 38 tests
```

There is **no CI** — see `tech-debt.md` H2. Quality gates are the AID skills themselves
(`aid-discover` adversarial review, `aid-execute` two-tier review per task + per delivery,
`aid-deploy` verification step).

## Architecture

- **Canonical/ source → 3 profile trees** (claude-code, codex, cursor) — never edit
  profile trees directly; edit `canonical/` and run `run_generator.py`. All skill
  bodies are byte-identical across all 3 trees + the dogfood `.claude/` tree.
- **Thin-Router Skills** (work-001 feature-002) — every `aid-*` SKILL.md is a state
  router (≤~360 lines) that delegates per-state logic to `references/state-*.md`
  files. The Dispatch table is the canonical state machine; advance follows one of
  three forms (Unconditional / Halt / Conditional on a computed criterion).
  Total skill body lines: 2,108 across 10 skills (was 4,467 pre-refactor — 53% reduction).
- **State machine per skill** — each `aid-*` skill exits after one state and
  re-enters on the next slash-command invocation (no auto-advance per IQ9).
- **Two-tier review** (work-001 feature-004) — per-task quick-check (Small-tier
  reviewer, no grade loop; HIGH+ findings deferred to delivery gate) + per-delivery
  quality gate (full review/fix/review loop with `grade.sh` determinism).
- **Parallel pool dispatch** (work-001 feature-009) — `aid-execute` runs a PD-0..PD-6
  pool model with `MaxConcurrent` capacity, wait-for-any-completion, failure-block-radius
  (BFS via `compute-block-radius.sh`), and graceful degradation when host can't
  background-dispatch.
- **Lite path with type-aware sub-paths** (work-001 feature-005) — `aid-interview`
  TRIAGE state routes small work to LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR /
  LITE-FEATURE sub-paths, emitting a single work-root SPEC.md + tasks/ instead of
  the full Interview → Specify → Plan → Detail pipeline.
- **Recipes catalog** (work-001 feature-011) — `canonical/recipes/` ships 5
  pre-filled lite-path templates (bug-fix, method-refactor, add-crud-endpoint,
  add-unit-test, write-release-note) with YAML front-matter + `{{slot}}`
  placeholders; `parse-recipe.sh` handles slot extraction + emission.
- **L1+L2+L3 subagent visibility** (work-003 traceability, always-on) — every
  long-running subagent dispatch surfaces `[State: NAME]` markers (L1), L2 ETA
  bracket pairs (▶/✓), and L3 heartbeat files. Calibration logged unconditionally.

## Skills

AID methodology skills are installed in `.claude/skills/`:
`aid-init`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`,
`aid-execute`, `aid-deploy`, `aid-monitor`, `aid-summarize` (10 skills) plus
maintainer-only `aid-generate`. Use them by invoking the matching slash command.

## Agents

22 specialist agents are available in `.claude/agents/` (10 Opus tier, 9 Sonnet tier,
3 Haiku tier). Skills dispatch them via the Agent tool with `subagent_type`.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands (Python, Bash, PowerShell)
- Do NOT modify files outside the project root

## Conventions

- See `.aid/knowledge/coding-standards.md` for project-specific authoring conventions.
- **Never edit `profiles/{claude-code,codex,cursor}/` directly** — edit `canonical/`
  and run `python run_generator.py`.
- **Thin-Router SKILL.md** — when SKILL.md grows past ~200 lines, extract per-state
  bodies into `references/state-{name}.md`; keep the router as Dispatch table +
  Pre-flight + State Detection only.
- **Area-STATE consolidation (FR2)** — each `.aid/{work}/STATE.md` is the per-area
  state hub; legacy per-feature `STATE.md` and per-task `STATE.md` files are RETIRED.
- **Single-branch work** — commit work-NNN to ONE persistent branch (off master);
  no per-task worktrees or branches. (Worktree sprawl caused PR #12 to lose 63
  commits; recovered via PR #13.)
