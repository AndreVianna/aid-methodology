# {work title}

- **Name:** *(pending)*
- **Description:** *(pending)*
- **Work:** {work-NNN-name}
- **Created:** {YYYY-MM-DD}
- **Source:** /aid-describe lite path — {LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE}
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

> Tasks live under `tasks/task-NNN/SPEC.md` directly under the work folder -- no `deliveries/`
> and no `delivery-001/` folder for lite works. Each task's `**Source:**` field reads
> `{work-NNN-name} → delivery-001` (lite path always uses `delivery-001` as the conceptual
> delivery id, even though no `delivery-001/` folder exists).

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
| {date} | Initial lite-path SPEC created | /aid-describe {sub-path} |
