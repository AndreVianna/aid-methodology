# Detail — The Ultimate Breakdown

Break each deliverable from PLAN.md into small, sequential, testable tasks.
Each task = one agent session = one PR = one human review.

## Core Principle

Detail makes **no new decisions**. Everything in the tasks is already defined in PLAN.md and the feature SPECs. Detail just slices the work into PR-sized pieces.

## What It Does

1. Reads PLAN.md to understand deliverable ordering
2. Reads feature SPECs to understand the technical scope
3. Breaks each deliverable into sequential tasks
4. Each task has: title, source, file list (scope boundary), acceptance criteria
5. User reviews the task list, can split/merge/reorder
6. Task files are written to `aid-workspace/{work}/tasks/`

## The Rules

| Rule | Why |
|------|-----|
| **Always small** | Every task fits one agent session |
| **Sequential** | Within a deliverable, tasks execute in order |
| **Each task = one PR** | Human reviews and merges before next starts |
| **No new decisions** | Detail slices what exists, doesn't invent |

## Task File Format

```markdown
# task-{id}: {Title}

**Source:** feature-NNN-{name} → delivery-{x}

**Files:**
- `path/to/File.java` (create)
- `path/to/OtherFile.java` (modify)
- `test/path/to/FileTest.java` (create)

**Acceptance Criteria:**
- [ ] Criterion 1 — concrete, testable
- [ ] Criterion 2 — concrete, testable
- [ ] All existing tests still pass
```

Four sections. Nothing else.

## How to Slice

Start from the bottom and build up:
1. Foundation — schema, models, core types
2. Services — business logic, handlers, middleware
3. Integration — controllers, endpoints, UI
4. Validation — E2E tests, smoke tests

## Re-run = Review

Running `/aid-detail` on a work that already has tasks triggers review mode:
- Compares existing tasks against current PLAN.md and SPECs
- Grades A (current) through D (major restructuring needed)
- Updates affected tasks, renumbers if sequence changed

## Feedback Loops

| Direction | Trigger |
|-----------|---------|
| → Plan | Plan too vague to decompose |
| → Specify | SPEC missing detail needed for file list |
| → Discovery | KB gap found during decomposition |

## Usage

```
/aid-detail work-001        # Detail a specific work
/aid-detail                  # Auto-select if single work
/aid-detail work-001 --reset # Clear all tasks, regenerate
```
