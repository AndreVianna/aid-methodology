# Plan -- AID-Interview Improvements

> Scope of this plan pass: the **3 spike-independent features already specified** (001, 006, 007).
> Features 002-005 are deferred behind the feature-001 spike (their technical design *is* the
> spike's output) and will be specified + planned in a future pass once the spike executes.

## Deliverables

### delivery-001: Elicitation Research Spike
- **What it delivers:** a `findings.md` research deliverable cataloguing the best
  Requirements-Elicitation / Domain-Discovery techniques used by seasoned analysts (RQ-A seed
  content + RQ-B analyst conversation; 7 technique families + the web-trending "grill-me"
  comparative), with an explicit consumption contract for features 002-005. Pure research; no
  production code.
- **Features:** feature-001-elicitation-research-spike
- **Depends on:** -- (foundation)
- **Priority:** Must

### delivery-002: Infra Debt Paydown
- **What it delivers:** hardened maintainer infrastructure, independent of the elicitation work:
  H1 (`tests/canonical/test-install-manifests-lockstep.sh` asserting the 5 install manifests agree
  on the dashboard 12-file set), M3 (refreshed `repository-structure.md` -- counts + all three
  prose paths + the ASCII tree), M4 (multi-viewport check in `validate-visuals.mjs`), M1
  (npm/PyPI publish enablement -- owner-gated/externally-blocked; not a code change, recommended
  for **deferral with rationale** per AC-9, the publish workflow already being OIDC-ready).
- **Features:** feature-007-infra-debt-paydown
- **Depends on:** -- (independent; parallel-capable with delivery-001)
- **Priority:** Could

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The spike (delivery-001) exists to shape features 002-005; its findings may expand or reshape their scope -- and feature-006's rename blast-radius inventory (~758 files) is computed against today's tree, so it can drift before the rename executes. | L | Expected by design, not a defect. The deferred re-plan pass (post-spike) re-specifies 002-005 from findings and re-runs feature-006's inventory against the then-current tree before the rename task is built. |

## Deferred

| Feature | Reason | Revisit When |
|---------|--------|--------------|
| feature-006-rename-aid-define | Hard-gated AFTER content features 002/003/004 (they edit the skill dir in place; a concurrent dir rename collides). Those predecessors are deferred behind the feature-001 spike, so 006 has no satisfiable predecessor to depend on yet. NOT gated by the spike itself. | A future `/aid-plan` pass, after 002/003/004 are specified (post-spike) and built. |

## Execution Graphs

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | — |
| task-003 | task-001, task-002 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-002 |

```wave-map
delivery: 001
wave 1: task-001, task-002
wave 2: task-003
```

task-001 = Classic elicitation/domain-discovery technique survey (RESEARCH) ·
task-002 = grill-me comparative (RESEARCH) · task-003 = Synthesis & Recommendations -> findings.md
(RESEARCH). The two surveys write separate research notes (no shared-file contention), so they run
in parallel; the synthesis assembles findings.md from both.

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-004 | — |
| task-005 | — |
| task-006 | — |
| task-007 | task-006 |
| task-008 | — |

| Can Be Done In Parallel |
|------------------------|
| task-004, task-005, task-006, task-008 |

```wave-map
delivery: 002
wave 1: task-004, task-005, task-006, task-008
wave 2: task-007
```

task-004 = install-manifests-lockstep suite (TEST, H1) · task-005 = refresh repository-structure.md
(DOCUMENT, M3) · task-006 = multi-viewport check in validate-visuals.mjs (IMPLEMENT, M4) ·
task-007 = verify T4 catches a clip + wire suite (TEST, M4; depends on task-006) ·
task-008 = record M1 publish-enablement deferral (DOCUMENT, M1). Four items are mutually
independent (wave 1); only the M4 TEST waits on the M4 IMPLEMENT.
