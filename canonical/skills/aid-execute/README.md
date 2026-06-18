> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-execute — Phase 6: Execute

Type-aware task execution with built-in review loop.

## What It Does

Reads a task's **Type** field and executes accordingly. Every task type follows the
same universal loop (execute → review → fix → done) but with type-specific rules
for both execution and review.

## Task Types

| Type | Agent Does | Reviewer Checks |
|------|-----------|----------------|
| **RESEARCH** | Investigate, compare, document findings | Completeness, bias, sources, actionability |
| **DESIGN** | Mockups, wireframes, interaction flows | Requirements adherence, design system, a11y |
| **IMPLEMENT** | Code + unit tests | Code quality, conventions, test coverage, build |
| **TEST** | Integration/E2E/UI/load tests | Coverage vs acceptance criteria, test quality |
| **DOCUMENT** | ADRs, API docs, runbooks, diagrams | Accuracy vs KB/SPECs, completeness |
| **MIGRATE** | Migration scripts + rollback | Reversibility, idempotency, data integrity |
| **REFACTOR** | Restructure code, same behavior | Behavior preserved, tests match, improvement |
| **CONFIGURE** | Config, CI/CD, infra-as-code | Correctness, security, idempotency |

## The Loop

```
1. EXECUTE  → agent does the work (type-specific rules)
2. REVIEW   → separate agent grades (type-specific criteria, deterministic rubric)
3. PRESENT  → all issues shown to user (CODE/TASK/SPEC/KB sources)
4. FIX      → CODE issues auto-fixed, non-CODE marked as loopback
→ back to REVIEW until grade ≥ minimum
```

## Branch Isolation

One branch per delivery (`aid/{work}-delivery-NNN`). All tasks in a delivery share the branch.
RESEARCH and DOCUMENT tasks that produce only `.aid/` artifacts may skip branching.

## Usage

```
/aid-execute work-001 task-001
/aid-execute task-001
```

## Input

- `task-NNN.md` with Type, Source, Scope, Acceptance Criteria
- Feature SPEC (from Source reference)
- KB docs via INDEX.md
- known-issues.md (if exists)

## Output

- Artifacts appropriate to task type
- Work `STATE.md` `## Tasks State` row updated with review history
- Grade ≥ minimum (from `bash canonical/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`)
- IMPEDIMENT-task-NNN.md if blocked
