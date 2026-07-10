# Plan -- AID Lite Shortcut Skills

## Deliverables

### delivery-001: Foundation + First Shortcut
- **What it delivers:** The shared shortcut-engine + the flattened single-feature/single-delivery work structure + the batched A+ grading/approval gates, proven end-to-end by the first working shortcut (`/aid-fix`): a user invokes `/aid-fix`, the engine scaffolds a flattened Lite work (REQUIREMENTS → SPEC → PLAN → tasks), each document passes its A+ grading gate, and it halts for approval before any execution. It also lands the **full-path pipeline structural rename** (feature-015): delivery definitions become `deliveries/delivery-NNN/BLUEPRINT.md` and task definitions `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`, `aid-plan`/`aid-detail`/`aid-execute` and both dashboard reader twins repoint to the new paths, and the delivery gate reads its criteria from `BLUEPRINT.md § GATE CRITERIA` (mis-wire fix) — grouping the structural/reader work with feature-001.
- **Features:** feature-001-flattened-lite-work-structure, feature-003-direct-entry-shortcut-engine, feature-004-approval-and-grading-gates, feature-008-fix-family, feature-015-full-path-pipeline-rename
- **Depends on:** --
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001 |
| task-005 | task-004 |
| task-006 | task-001 |
| task-007 | — |
| task-008 | task-001, task-007 |
| task-009 | task-007, task-008 |
| task-010 | task-009, task-013 |
| task-011 | task-008 |
| task-012 | task-011, task-013 |
| task-013 | task-007, task-008, task-009 |
| task-014 | task-011, task-013 |
| task-036 | — |
| task-037 | task-036 |
| task-038 | task-036 |
| task-039 | task-036 |
| task-040 | task-036 |
| task-041 | task-037, task-038, task-039, task-040 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-007, task-036 |
| task-002, task-003, task-004, task-006, task-008, task-037, task-038, task-039, task-040 |
| task-005, task-009, task-011, task-041 |
| task-010, task-012, task-014 |

```wave-map
delivery: 001
wave 1: task-001, task-007, task-036
wave 2: task-002, task-003, task-004, task-006, task-008, task-037, task-038, task-039, task-040
wave 3: task-005, task-009, task-011, task-041
wave 4: task-013
wave 5: task-010, task-012, task-014
```

### delivery-002: Core Create/Change/Test Shortcuts
- **What it delivers:** The Must pilot-cohort shortcuts — `/aid-create[-<artifact>]`, `/aid-change[-<artifact>]`, `/aid-refactor`, and the test family (`/aid-test` + `-security`/`-performance`/`-data-quality`, `/aid-experiment`) — plus the `aid-add-*` / `aid-update-*` alias families, each entering the Lite path directly via the delivery-001 engine.
- **Features:** feature-006-create-family, feature-007-change-and-refactor-family, feature-009-test-and-experiment-family
- **Depends on:** delivery-001
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-015 | — |
| task-016 | task-015 |
| task-017 | task-015 |
| task-018 | task-017 |
| task-019 | — |
| task-020 | task-019 |

| Can Be Done In Parallel |
|------------------------|
| task-015, task-019 |
| task-016, task-017, task-020 |

```wave-map
delivery: 002
wave 1: task-015, task-019
wave 2: task-016, task-017, task-020
wave 3: task-018
```

_Intra-delivery ordering. The whole delivery is gated on delivery-001 (see Depends on above); each task's full prerequisites, including cross-delivery foundation tasks (e.g. task-008 engine, task-009 build helper), are listed in its DETAIL.md._

### delivery-003: Breadth Families
- **What it delivers:** Completes the shortcut catalog — `/aid-prototype[-ui]`, the 8 `/aid-document-*` archetypes, and `/aid-report` + `/aid-show-dashboard`.
- **Features:** feature-005-prototype-family, feature-010-document-family, feature-011-analyze-and-report-family
- **Depends on:** delivery-001
- **Priority:** Should

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-021 | — |
| task-022 | task-021 |
| task-023 | — |
| task-024 | task-023 |
| task-025 | — |
| task-026 | task-025 |

| Can Be Done In Parallel |
|------------------------|
| task-021, task-023, task-025 |
| task-022, task-024, task-026 |

```wave-map
delivery: 003
wave 1: task-021, task-023, task-025
wave 2: task-022, task-024, task-026
```

_Intra-delivery ordering. The whole delivery is gated on delivery-001 (see Depends on above); each task's full prerequisites, including cross-delivery foundation tasks (e.g. task-008 engine, task-009 build helper), are listed in its DETAIL.md._

### delivery-004: Cutover
- **What it delivers:** Makes the shortcut skills the sole Lite-path entry: `/aid-describe` reduced to full-path-only, the new `/aid-triage` router live, the recipe catalog removed, and `aid-monitor` re-pointed (BUG → `/aid-fix`, change-request → `/aid-triage`). Completes the pipeline restructuring so the three clean entry points (know-full → `/aid-describe`; know-shortcut → the shortcut; unsure → `/aid-triage`) hold.
- **Features:** feature-013-aid-describe-full-only, feature-014-aid-triage-router, feature-002-recipe-removal, feature-012-deploy-and-monitor-repurpose
- **Depends on:** delivery-001, delivery-002, delivery-003
- **Priority:** Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-027 | — |
| task-028 | task-027 |
| task-029 | task-027 |
| task-030 | task-027, task-029 |
| task-031 | task-029, task-030 |
| task-032 | task-029, task-030 |
| task-033 | task-027, task-029 |
| task-034 | task-033 |
| task-035 | task-033, task-034 |

| Can Be Done In Parallel |
|------------------------|
| task-028, task-029 |
| task-030, task-033 |
| task-031, task-032, task-034 |

```wave-map
delivery: 004
wave 1: task-027
wave 2: task-028, task-029
wave 3: task-030, task-033
wave 4: task-031, task-032, task-034
wave 5: task-035
```

_Cutover ordering (extract-before-delete: task-027 before task-030; task-029 before task-030). This graph carries intra-delivery edges; cross-delivery prerequisites — task-033 needs task-013 (/aid-fix, delivery-001); task-034 needs task-008 (engine, delivery-001) — are listed in each task's DETAIL.md and the delivery is gated on delivery-001/002/003 above._

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Cutover (delivery-004) removes the old Lite path before the shortcut families are complete → lite-entry regression / stranded "don't-know" users | H | delivery-004 depends on delivery-001…003; the no-dangling test + the `aid-monitor` re-point are wave-level gates that pass only once all families ship |
| 2 | Catalog ↔ 69-directory drift ships a broken install | M | feature-003 catalog↔dirs parity test + `render-drift` CI |
| 3 | The flattened-layout dashboard readers (Python + Node twins) must land in lockstep or the two disagree | M | feature-001 reader-parity fixture (both twins read one flattened fixture identically) |

*(All 14 features assigned to a deliverable; no Deferred section.)*
