# State: EXECUTE

Task work is dispatched to the type-appropriate executor agent to produce deliverables; state is entered when no prior execution exists or when resuming an in-progress task.

## Task Types

| Type | What the agent does | What the reviewer checks |
|------|--------------------|-----------------------|
| **RESEARCH** | Investigate, compare options, document findings | Completeness, bias, sources cited, actionable conclusion |
| **DESIGN** | Mockups, wireframes, UI prototypes, interaction flows | Adherence to requirements, UX consistency, design system |
| **IMPLEMENT** | Write code + unit tests | Code quality, conventions, test coverage, build health |
| **TEST** | Write integration/E2E/UI/load tests, run them, report results | Coverage vs acceptance criteria, test quality, environment |
| **DOCUMENT** | Docs, diagrams, ADRs, API docs, runbooks | Accuracy vs KB and SPECs, completeness, audience clarity |
| **MIGRATE** | Data migration scripts, schema changes, data transformation | Reversibility, data integrity, rollback plan, idempotency |
| **REFACTOR** | Restructure code without changing behavior | Behavior preserved, tests still pass, measurable improvement |
| **CONFIGURE** | Config files, environment setup, CI/CD, infra-as-code | Correctness, security, idempotency, documentation |

## Agent Selection

Each task type dispatches a specific executor agent. The reviewer is always the same role (`reviewer`), separate from the executor for clean context. Specialist consults are dispatched in addition to the reviewer when the task type warrants it.

| Task Type | Executor | Reviewer | Specialist consult |
|-----------|----------|----------|---------------------|
| RESEARCH | `researcher` | `reviewer` | — |
| DESIGN | `ux-designer` | `reviewer` | — |
| IMPLEMENT | `developer` | `reviewer` | `security` if task touches auth/PII; `performance` if hot path |
| TEST | `developer` | `reviewer` | `performance` for load/integration tests |
| DOCUMENT | `tech-writer` | `reviewer` | — |
| MIGRATE | `data-engineer` | `reviewer` | `data-engineer` review (different instance than executor) |
| REFACTOR | `developer` | `reviewer` | — |
| CONFIGURE | `devops` | `reviewer` | `security` if config touches secrets/auth |

**Reviewer ≠ executor invariant.** Even when a task type uses the same agent role for both execution and consult-review (MIGRATE), they run as separate dispatches with clean context. The reviewer never sees the executor's working notes.

**Model override per task type.** Each executor has a default tier from its agent definition (Developer is Medium tier, etc.). For genuinely complex work — REFACTOR over a tangled module, MIGRATE with edge cases, IMPLEMENT touching critical security paths — the orchestrator may dispatch with an explicit higher-tier model in the Task tool's `model` parameter. This is a runtime decision per dispatch, not a skill configuration.

**Mechanical sub-tasks.** Executors may delegate mechanical work (extraction, file enumeration, template filling) to `simple-extractor`, `simple-glob`, `simple-formatter` — Small-tier utility sub-agents. See `agents/simple-*/README.md` for the caller contract.

<!-- INSERTION POINT: task-033 (pool dispatch) — when delivery-005 ships, the
     Worker column for EXECUTE will point at a pool-dispatcher sub-agent instead
     of the type-specific agent directly. The pool dispatcher reads the task type
     and routes to the correct executor from an available agent pool. The step
     body below (Step 1) is the natural insertion point for pool-dispatch logic. -->

## Step 1: EXECUTE (Do the Work)

Update work `STATE.md` `## Tasks Status` table: set this task's row Status to `In Progress`.

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH → `researcher`, DESIGN → `ux-designer`, IMPLEMENT/TEST/REFACTOR → `developer`, DOCUMENT → `tech-writer`, MIGRATE → `data-engineer`, CONFIGURE → `devops`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor — this overrides the skill's default `agent: developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: ux-designer`; an IMPLEMENT task uses `subagent_type: developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task → subagent_type={executor}` (substituting actual values).

Also update the task's row in work `STATE.md` `## Dispatches` sub-column (always — mandatory per work-003 traceability, not conditional): `| 1 | {executor} | EXECUTE Type={Type} | {cycle} |`.

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
✓ {executor} done (record actual time) — or ✗ {executor} failed: {reason}
When execution passes → update work `STATE.md` `## Tasks Status` row Status to `In Review` → proceed to Step 2 (REVIEW).

**Advance:** Next state is `REVIEW` — when this state's work completes, router prints `Next: [State: REVIEW] — run /aid-execute again` and exits.
