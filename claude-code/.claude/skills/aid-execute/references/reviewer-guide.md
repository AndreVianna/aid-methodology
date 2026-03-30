# Reviewer Guide

Reference for Step 2 (REVIEW). Contains severity/source classifications
and type-specific review checklists for the reviewer agent.

## Issue Severity

| Severity | Meaning |
|----------|---------|
| **Minor** | Cosmetic, style, trivial. Does not affect functionality. |
| **Low** | Convention deviation, could be better but works correctly. |
| **Medium** | Incorrect behavior, missing edge case, incomplete coverage. |
| **High** | Blocks functionality, security risk, data integrity concern. |
| **Critical** | System failure, data loss, security breach, fundamentally wrong. |

## Issue Source

| Source | Meaning |
|--------|---------|
| **CODE** | Implementation bug, style, or quality issue (any type's output) |
| **TASK** | Task spec is wrong or incomplete |
| **SPEC** | Feature SPEC is wrong or missing |
| **KB** | Convention not documented |

## Type-Specific Review Focus

### IMPLEMENT
1. Specification Compliance — every acceptance criterion met?
2. Architecture Compliance — patterns, boundaries, dependencies?
3. Convention Compliance — naming, error handling, logging?
4. Code Quality — clean code? YAGNI? No over-engineering?
5. Test Coverage — unit tests for new code? Edge cases?
6. Build Health — build/lint/tests green?

### TEST
1. Coverage — every acceptance criterion from source feature has a test?
2. Test Quality — deterministic? Clean setup/teardown? No flaky patterns?
3. Test Results — what passed/failed? Failures documented?
4. Environment — test isolation? No side effects?
5. Gaps — what couldn't be automated? Manual checklist adequate?

### RESEARCH
1. Completeness — question fully addressed? Alternatives compared?
2. Sources — cited and verifiable?
3. Bias — balanced presentation of trade-offs?
4. Actionability — clear recommendation with reasoning?
5. Relevance — findings applicable to the project context?

### DESIGN
1. Requirements Adherence — user stories/personas reflected?
2. Design System — tokens, components, patterns from KB used?
3. Responsive — breakpoints handled (if specified)?
4. Accessibility — keyboard, contrast, screen reader considered?
5. Completeness — all states shown (empty, loading, error, success)?

### DOCUMENT
1. Accuracy — matches current codebase and KB?
2. Completeness — covers what the task specified?
3. Clarity — target audience can follow?
4. Format — matches project conventions?

### MIGRATE
1. Reversibility — rollback script exists and works?
2. Idempotency — safe to run twice?
3. Data Integrity — counts, references, constraints preserved?
4. Runbook — steps documented clearly?

### REFACTOR
1. Behavior Preserved — test results identical before/after?
2. Measurable Improvement — complexity/lines/clarity actually better?
3. Test Changes Justified — if any tests changed, why?
4. No Scope Creep — only refactored what the task specified?

### CONFIGURE
1. Correctness — config values right? Service starts?
2. Idempotency — applying twice = same result?
3. Security — no plaintext secrets? Proper permissions?
4. Documentation — values explained?
