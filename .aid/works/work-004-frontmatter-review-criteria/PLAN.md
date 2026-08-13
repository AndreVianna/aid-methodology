# Plan -- Declared Review Criteria

## Deliverables

Three deliveries, one per stream, in strict load-bearing order. The order is not a
preference: each delivery's output is a precondition for the next, and the single
end-of-work render (C-2 / NFR-4) lands in the last one.

### delivery-001: Mechanism -- declarations exist and are read
- **What it delivers:** the `review-criteria:` schema, the two KB tables (type registry +
  criteria, levels 1-2 in `authoring-conventions.md`), the readers (reviewer, dispatch,
  ledger-schema, 6 briefs, FIX contract), the writer-side instruction in
  `agent-boilerplate.md` + the 5 profile context files, `render.py` carry-through, the
  severity reconciliation, the rename of the emitters/parser/definitions, and the
  `imports-from-work-003.md` log. After this, the review process resolves and cites declared
  criteria for anything already covered at type level.
- **Features:** feature-001-declaration-standard-and-enforcement
- **Depends on:** -- (none)
- **Priority:** Must

### delivery-002: Populate -- the exceptions pass across the trees
- **What it delivers:** the 20 internal READMEs deleted (with the `aid-clerk` contract
  relocated and the 3 `aid-monitor` test assertions removed); the 290-file walk with each file
  typed; per-file `review-criteria:` blocks written only where a file has its own criteria; the
  8 in-scope `contracts: []` KB docs corrected and the 8 that declare verified; the on-disk data
  rename of the 18 field-bearing KB docs + 4 fixtures.
- **Features:** feature-002-declarations-across-the-trees
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: Retire + render -- remove the stand-ins and ship once
- **What it delivers:** the derived removal set (AC-3); the `check-skill-counts.mjs`
  disposition (full-delete default, narrow flagged); the front face brought current
  (`docs/*.md`, root `README.md`, `examples/**/README.md`); the **single render** of both
  chains (`canonical/`->`profiles/`->2 dogfood trees, and the site chain), run exactly once;
  the exit arithmetic (379 guard floor kept separate from 1,802 doc lines); and the C-7 audit.
- **Features:** feature-003-superseded-guard-retirement
- **Depends on:** delivery-002
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The single render lands only in delivery-003, so deliveries 001-002 leave `profiles/` and the dogfood trees intentionally stale -- a mid-work checkout will fail byte-identity until 003. | M | By design (C-2 / NFR-4); staleness is correct, not a defect. The byte-identity gate is only expected to pass after 003's render. Do not render early. |
| 2 | `work-003` edits 26 of the same review-related files under `canonical/`; whichever branch merges second inherits a collision. | M | C-7's six gates (facts not files); keep every stream-1 edit additive and localized (NFR-3); the `imports-from-work-003.md` log records the only three admitted facts. |
| 3 | Owner judgment call open in delivery-003: full-delete vs narrow of `check-skill-counts.mjs` (affects the 379 guard-line floor). | L | Surfaced in feature-003 SPEC §2 and flagged, not hidden; default is full delete; decided at execution against disk. |
| 4 | The AC-2 proof runs a planted defect; a forgotten plant could become a real defect. | L | NFR-1: disposable worktree at the same commit, never the work branch, never committed; the plant class is self-announcing. |

## Deferred

*None -- all three Ready features are included.*

## Execution Graphs

*Task numbering is global (001-017). Deliveries run in series: delivery-002 after delivery-001,
delivery-003 after delivery-002. The graphs below are the intra-delivery order + parallelism.*

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002, task-003 |
| task-005 | task-001 |
| task-006 | task-002 |
| task-007 | task-004, task-005 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-005 |
| task-003, task-006 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-005
wave 3: task-003, task-006
wave 4: task-004
wave 5: task-007
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-008 | — |
| task-009 | task-008 |
| task-010 | task-008, task-009 |
| task-011 | task-010 |
| task-012 | task-009, task-010 |

| Can Be Done In Parallel |
|------------------------|
| task-011, task-012 |

```wave-map
delivery: 002
wave 1: task-008
wave 2: task-009
wave 3: task-010
wave 4: task-011, task-012
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-013 | — |
| task-014 | — |
| task-015 | task-013, task-014 |
| task-016 | task-013, task-015 |
| task-017 | task-013 |

| Can Be Done In Parallel |
|------------------------|
| task-013, task-014 |
| task-015, task-017 |

```wave-map
delivery: 003
wave 1: task-013, task-014
wave 2: task-015, task-017
wave 3: task-016
```
