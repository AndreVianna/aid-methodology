# Task Type Execution Rules

Per-type agent instructions for Step 1 (EXECUTE). Each section defines the rules
the working agent must follow based on the task's Type field.

## IMPLEMENT
```
RULES:
- YAGNI — implement exactly what the task specifies. Nothing more.
- Follow coding-standards from KB exactly (naming, patterns, error handling)
- Write clean code:
  · Meaningful names · Small methods · Guard clauses · DRY without over-abstraction
  · Clear error handling · Minimal comments (WHY not WHAT) · No magic numbers
- Match interface contracts from feature SPEC
- Write unit tests for all new code AND update existing tests
- Verify gates pass (from KB — technology-stack.md § Commands via INDEX):
  1. Build — ALWAYS
  2. Lint — IF CONFIGURED
  3. Unit tests — IF CONFIGURED
- Contradiction between SPEC and codebase → STOP, report as IMPEDIMENT
- Commit: "task-NNN: {description}"
```

## TEST
```
RULES:
- Write integration/E2E/UI/load tests as specified in the task scope
- Use the testing framework and patterns from KB (test-landscape.md via INDEX)
- Each test must trace to a specific acceptance criterion
- Tests must be deterministic — no timing dependencies, no external state leaks
- Clean up test data after runs (teardown/cleanup hooks)
- Run the test suite and report results
- If tests FAIL on first run, that's a finding — document it, don't hide it
- Test environment setup: verify prerequisites before running
- Commit: "task-NNN: {description}"
```

## RESEARCH
```
RULES:
- Investigate the question/topic defined in the task scope
- Compare at least 2 alternatives (unless task specifies otherwise)
- Cite sources — URLs, documentation references, code examples
- Document trade-offs explicitly (pros/cons, not just recommendation)
- End with a clear, actionable recommendation
- Write findings to the path specified in task Scope
- No code changes to the project — research produces documents only
```

## DESIGN
```
RULES:
- Create design artifacts as specified in task scope (mockups, wireframes, flows)
- Follow ui-architecture.md from KB (design system, tokens, component patterns)
- Reference REQUIREMENTS.md for user stories and personas
- Show responsive behavior if specified in SPEC
- Note accessibility considerations
- Write artifacts to paths specified in task Scope
```

## DOCUMENT
```
RULES:
- Write documentation as specified in task scope (ADRs, API docs, runbooks, diagrams)
- Verify accuracy against current codebase and KB
- Match the project's existing documentation style (check KB)
- ADRs follow: Context → Decision → Consequences format
- Diagrams use Mermaid or the project's standard (check KB)
- Commit: "task-NNN: {description}"
```

## MIGRATE
```
RULES:
- Write migration scripts as specified in task scope
- Migration MUST be reversible (include rollback script)
- Migration MUST be idempotent (safe to run twice)
- Verify data integrity — before/after counts, referential integrity
- Document the migration steps in a runbook
- Test with realistic data volume (not just empty/trivial)
- Commit: "task-NNN: {description}"
```

## REFACTOR
```
RULES:
- Restructure code as specified — NO behavior changes
- Run full test suite BEFORE refactoring (baseline)
- Run full test suite AFTER refactoring (must match baseline — same pass/fail)
- If tests change, justify why (test was testing implementation, not behavior)
- Measurable improvement: fewer lines, lower complexity, better naming, clearer structure
- Commit: "task-NNN: {description}"
```

## CONFIGURE
```
RULES:
- Create/modify config as specified in task scope
- Configuration MUST be idempotent (applying twice = same result)
- No secrets in plaintext — use environment variables or secret managers
- Document what each config value does (inline comments or companion doc)
- Verify the configuration works (service starts, healthcheck passes)
- Commit: "task-NNN: {description}"
```
