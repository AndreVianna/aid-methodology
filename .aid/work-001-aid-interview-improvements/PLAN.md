# Plan -- AID-Interview Improvements

> Plan history: **pass 1** sequenced the 3 spike-independent features (delivery-001 spike +
> delivery-002 infra debt, both now EXECUTED). **pass 2 (this re-plan)** adds delivery-003..006 for
> the content features 002/003/004/005 + the feature-006 split, now all specified at A+ from the
> spike's findings. Deliveries build on the executed delivery-001/002.

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

### delivery-003: Seasoned-Analyst Engine + Guided Triage
- **What it delivers:** the seasoned-analyst elicitation engine (one fixed "what+why" opener +
  adaptive next-move selection, read+ask calibration, expert-advisor stance, and the NFR-7
  suggested-answer-+-rationale contract on every question) PLUS analyst-driven guided triage
  (draws out the path/recipe-deciding signals, KB-context-aware) -- improving the interview for
  EVERY user (brownfield and greenfield). In-place extension of the aid-interview skill; the
  existing brownfield path is preserved (AC-10).
- **Features:** feature-002-seasoned-analyst-engine, feature-004-guided-triage
- **Depends on:** -- (extends the current skill; builds on the executed delivery-001 findings)
- **Priority:** Must

### delivery-004: Greenfield Seed Authoring
- **What it delivers:** forward-author a minimal-but-sufficient KB seed from intent for code-less
  (greenfield) projects -- the 5-element seed model + the `source: forward-authored` marker
  (schema/lint/index/freshness edits), a greenfield-mode review gate, and the layered
  seed<->requirements coherence check. The inverse of brownfield extraction (the authored design
  IS the source of truth, design->code).
- **Features:** feature-003-greenfield-seed-authoring
- **Depends on:** delivery-003 (the engine elicits the seed)
- **Priority:** Must

### delivery-005: Build-Time Conformance
- **What it delivers:** a NEW code->design conformance check (extract-and-diff) that flags when
  as-built code diverges from a forward-authored design seed, for human-gated reconciliation --
  authority stays design->code until a human reconciles. Runs as an additive aid-housekeep
  KB-DELTA conformance lane (carving forward-authored docs out of the doc<-code update lane).
- **Features:** feature-005-build-time-conformance
- **Depends on:** delivery-004 (the seed model + marker it checks against)
- **Priority:** Must

### delivery-006: Split aid-interview -> aid-describe + aid-define
- **What it delivers:** split the (now-enhanced) `aid-interview` skill into two outcome-named
  skills at the approval gate -- `aid-describe` (TRIAGE + interview + COMPLETION + the entire lite
  path -> approved REQUIREMENTS) and `aid-define` (FEATURE-DECOMPOSITION + CROSS-REFERENCE ->
  feature folders). Byte-identical render across the 5 host trees + dogfood mirror, old dir
  orphan-pruned, install manifests / docs-site / skill-count (+1, 13->14) updated, the
  `aid-interviewer` agent untouched, CI green.
- **Features:** feature-006-rename-aid-define
- **Depends on:** delivery-003, delivery-004 (operates on the FINAL in-place content), AND
  **delivery-005** (a sequencing edge -- not a content dependency: d006's name-sweep and d005's
  `output_root` param both edit `canonical/skills/aid-discover/references/state-generate.md`, so
  they must NOT run in parallel; d006 lands LAST regardless).
- **Priority:** Should

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Shared-file coupling across deliveries.** Two collision surfaces: (a) delivery-003 (002+004), delivery-004 (003), and delivery-006 all edit `canonical/skills/aid-interview/` IN PLACE; (b) delivery-005 AND delivery-006 BOTH edit `canonical/skills/aid-discover/references/state-generate.md` (d005 adds the `output_root` param; d006's name-sweep rewrites the `/aid-interview` tokens there). Parallel delivery branches would collide on these files. | M | Both surfaces are resolved by strict sequencing the dependency graph already enforces: d003 -> d004 -> d005 -> d006 (d006 now also depends on d005 -- a sequencing edge for the shared `state-generate.md`). No two deliveries that share a file run concurrently. |
| 2 | **feature-006 split operates on a moving target.** Its blast-radius inventory + the 13->14 skill-count surfaces are computed against today's tree; delivery-003/004 add/restructure `references/` before it runs. | L | feature-006 is sequenced LAST (depends on delivery-003+004) and its spec already states it partitions the FINAL post-content file set; aid-detail/aid-execute re-derive the inventory against the then-current tree before the split task runs. |

## Deferred

_None -- all Ready features are now assigned to a delivery (feature-006 is delivery-006, no longer deferred)._

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
| task-009 | — |

| Can Be Done In Parallel |
|------------------------|
| task-004, task-005, task-006, task-008, task-009 |

```wave-map
delivery: 002
wave 1: task-004, task-005, task-006, task-008, task-009
wave 2: task-007
```

task-004 = install-manifests-lockstep suite (TEST, H1) · task-005 = refresh repository-structure.md
(DOCUMENT, M3) · task-006 = multi-viewport check in validate-visuals.mjs (IMPLEMENT, M4) ·
task-007 = verify T4 catches a clip + wire suite (TEST, M4; depends on task-006) ·
task-008 = record M1 publish-enablement deferral (DOCUMENT, M1) ·
task-009 = grant aid-researcher web tools (CONFIGURE, R1; added 2026-06-27, owner direction).
Five items are mutually independent (wave 1); only the M4 TEST waits on the M4 IMPLEMENT.
