# {work title}

- **Name:** *(pending)*
- **Description:** *(pending)*
- **Work:** {work-NNN-name}
- **Created:** {YYYY-MM-DD}
- **Source:** /aid-interview lite path — {LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE}
- **Status:** Draft | Ready

## Goal

{One paragraph: what this work is and what success looks like.
For LITE-BUG-FIX: what is broken and its impact.
For LITE-REFACTOR: what is changing and why (incl. changing existing docs/reports).
For LITE-FEATURE: what the feature does and the user problem it solves (incl. adding new docs/reports).}

## Context

{Condensed problem statement + architectural constraints.
For LITE-BUG-FIX: bug description + reproduction steps + intended behavior.
For LITE-REFACTOR: before/after sketch + scope (for doc/report changes: audience + purpose + outline).
For LITE-FEATURE: scope + KB references (for new docs/reports: audience + purpose + document outline).
KB references by INDEX.md doc name.}

## Acceptance Criteria

- [ ] {Given {precondition}, when {action}, then {expected result}.}
- [ ] All §6 quality gates pass.

## Tasks

> Each `tasks/task-NNN.md` uses `**Source:** {work-NNN-name} → delivery-001` (lite path always uses `delivery-001`).

| Task | Type | Title |
|------|------|-------|
| task-001 | {Type} | {title} |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| {date} | Initial lite-path SPEC created | /aid-interview {sub-path} |
