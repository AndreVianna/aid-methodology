# Plan -- Ticket-Tracker Integration Skills + PM-Tool Retirement

## Deliverables

### delivery-001: Dedicated ticket skills
- **What it delivers:** The three explicit, tool-agnostic, user-invoked ticket commands
  (`/aid-read-ticket`, `/aid-create-ticket`, `/aid-update-ticket`) plus the shared
  connector-resolution ladder they consume -- the standalone-functional read/create/update
  surface every later reroute points at.
- **Features:** feature-001-dedicated-ticket-skills
- **Depends on:** --
- **Priority:** Must

### delivery-002: Retire & consolidate automated ticket integration
- **What it delivers:** A single sanctioned outward tracker surface -- the older PM-TOOL
  automated writes are retired across the six FR-7 sites, the newer CONNECTORS read/write seams
  are rerouted onto the delivery-001 skills (auto status-mirror removed, `aid-plan` Step 4c
  split, human-gated comment writes routed through `/aid-update-ticket`), and
  `consumption-protocol.md` is revised to describe the read-delegates / writes-via-dedicated-skills
  model.
- **Features:** feature-002-pm-tool-write-retirement, feature-003-connector-seam-consolidation,
  feature-004-consumption-protocol-revision
- **Depends on:** delivery-001
- **Priority:** Must
- **Rationale:** FR-6's "single sanctioned outward surface / no silent writes" holds only when
  BOTH generations retire together -- feature-002 alone leaves the CONNECTORS auto-writes;
  feature-003 alone leaves the PM-TOOL writes -- and feature-004's protocol doc *describes* the
  model feature-003 implements, so the three ship as one coherent increment.

### delivery-003: KB update + canonical propagation
- **What it delivers:** The terminal step -- the discovery-guidance + KB project-management
  guidance edits, then a single generator render over the FULLY-edited `canonical/` tree
  (features 001-004 + the discovery-guidance edit), the dogfood `.claude/` resync, and the
  byte/path-parity + CLI-parity green pass that ships the whole change consistently across all
  five profiles.
- **Features:** feature-005-kb-update-and-propagation
- **Depends on:** delivery-002
- **Priority:** Must
- **Terminal:** the render must run ONCE over the fully-edited canonical tree (feature-005's
  terminal-by-construction spec) + dogfood resync + byte/path/CLI parity + the KB &
  discovery-guidance edit.

## Cross-Cutting Risks

| # | Risk | Deliveries / Features | Severity | Mitigation |
|---|------|-----------------------|----------|------------|
| R1 | **Terminal-render completeness.** delivery-003's single render must run over the *fully-edited* `canonical/` tree (every features-001-004 canonical edit + the discovery-guidance edit). A canonical edit that landed in delivery-001/002 but is missed at render time ships un-rendered -- render-drift / byte-identity fails, or a profile ships stale. | delivery-003 (feature-005); depends on 001+002 edits | High | feature-005 Feature Flow (b) step 1 is an explicit "confirm every canonical edit from 001-004 has landed" check *before* invoking `run_generator.py`; a single render + single commit of `canonical/` + `profiles/*` + dogfood `.claude/` + KB doc together keeps render-drift green on every commit. |
| R2 | **Dual-generation coordination inside delivery-002.** Three skills -- `aid-describe`, `aid-plan`, `aid-execute` -- carry BOTH the PM-TOOL generation (feature-002) and the CONNECTORS generation (feature-003), at *distinct* anchors (e.g. `aid-plan/SKILL.md` PM-TOOL Sprint write vs `first-run-loop.md` Step 4c CONNECTORS create/register; `aid-execute/SKILL.md` PM-TOOL update vs `state-execute.md` Connector Mirroring). Both generations must be retired for FR-6 to hold, and the `aid-plan` Step 4c split (retire outward-file half, keep+reroute the record half) must be applied exactly once. | delivery-002 (features 002 + 003) | Medium | Grouping all three features in one delivery lets the delivery reviewer verify BOTH signature classes together -- a zero-signature grep spanning the PM-TOOL guards AND the CONNECTORS mirror/create signatures across the shared skills, per-site per feature-002 §Testing + feature-003 §Testing. |
| R3 | **Single-branch, deferred parity.** The whole work executes on one work-023 branch with one render deferred to delivery-003; deliveries 001 and 002 leave `profiles/*` + dogfood `.claude/` STALE by design (each feature SPEC states byte/path-parity is feature-005's gate, "not duplicated here"). A delivery-001/002 gate that demanded parity would fail spuriously. | delivery-001, delivery-002 (gate scoping) | Low | delivery-001/002 gate criteria are scoped to `canonical/`-only checks (structural / per-site / zero-signature grep); byte/path-parity + CLI-parity belong SOLELY to delivery-003's terminal gate. The 001 -> 002 -> 003 dependency spine also prevents feature-003/004 reroutes from dangling before feature-001's skills exist. |

## Execution Graphs

_Authored by `/aid-detail` (FIRST-RUN). One graph per delivery. `/aid-execute` reads the
`wave-map` blocks below to determine ordering and parallelism. Cross-delivery ordering
(delivery-001 -> delivery-002 -> delivery-003) is enforced by the delivery-level `Depends on`
above; each delivery's graph is self-contained (its wave-1 tasks show `—`, their only real
prerequisite being the prior delivery)._

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001 |
| task-005 | task-002, task-003, task-004 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003, task-004 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003, task-004
wave 3: task-005
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-006 | — |
| task-007 | task-006 |
| task-008 | task-007 |
| task-009 | task-008 |
| task-010 | task-009 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 002
wave 1: task-006
wave 2: task-007
wave 3: task-008
wave 4: task-009
wave 5: task-010
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-011 | — |
| task-012 | — |
| task-013 | task-011 |
| task-014 | task-012, task-013 |

| Can Be Done In Parallel |
|------------------------|
| task-011, task-012 |

```wave-map
delivery: 003
wave 1: task-011, task-012
wave 2: task-013
wave 3: task-014
```
