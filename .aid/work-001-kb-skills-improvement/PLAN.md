# Plan -- Knowledge Base Skills Overhaul

> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23
> **Source:** SPEC features feature-001..feature-012 (`features/`), REQUIREMENTS.md, whole-work-review.md

This plan decomposes work-001 into **9 deliveries**. The sequence is user-approved.
Each delivery is one branch/PR (`aid/work-001-delivery-NNN`). The strategy: build the
**essence engine end-to-end first** (delivery-001 = the 'Relative bus' capability), then
flip AID's own surfaces onto the new schema (INDEX, migration), scale it to project shape
(adaptive paths), lock it in with a CI-anchored regression fixture, then layer the
Should-priority lifecycle skills (freshness, topology+ship, governance), and finally the
Could-priority greenfield path.

The strategy is **provide-before-consume**: every feature's frontmatter/schema/oracle
producer lands in or before the delivery that consumes it. delivery-001 establishes the
whole essence substrate (frontmatter primitive f001, concern model f003, the
harvest/spine/closure engine f004, the review panel f005) so the seven downstream
deliveries consume settled contracts.

## Deliverables

### delivery-001: Essence Core

- **What it delivers:** the 'Relative bus' capability end-to-end -- essence capture (mechanical
  coined-term harvest + the non-lexical conceptual-synthesis channel) feeding a grounded concept
  spine, a bounded comprehension/closure loop, and a multi-mandate review panel with teach-back as
  the keystone hard gate. After delivery-001, `/aid-discover` captures a project's essence and
  certifies it (teach-back closure replaces "severity >= A+" as the exit).
- **Features:** feature-001 (frontmatter & `sources:` primitive), feature-003 (KB document model /
  concern model), feature-004 (essence-capture research engine), feature-005 (review panel & rubric)
- **Depends on:** -- (none)
- **Priority:** Must

### delivery-002: INDEX Routing

- **What it delivers:** `INDEX.md` flips from today's prose-`intent:` list to the generated,
  deterministic routing table (Document | Objective | Summary | Tags | See-instead | Audience),
  composed mechanically by `build-kb-index.sh` from the frontmatter fields delivery-001 established.
- **Features:** feature-002 (INDEX routing table)
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: KB Migration

- **What it delivers:** AID's own KB (plus a fixture old-format KB) migrated onto the new
  frontmatter schema and INDEX format; the `lint-frontmatter.sh` flipped to a hard gate **for AID**
  (the shipped soft-skip retained for adopter degrade-grace); old-format coexistence remains
  degrade-graceful. Moved early so AID dogfoods the schema and so later freshness operates on
  stamped `approved_at_commit:` docs.
- **Features:** feature-011 (KB migration)
- **Depends on:** delivery-001, delivery-002
- **Priority:** Must

### delivery-004: Adaptive Paths (brownfield)

- **What it delivers:** a recon pre-pass that **measures** source-availability/complexity and
  **proposes** a path (human-confirmed, not declared from `project.type`), then scales the closure
  engine + review panel to project size for the brownfield-small and brownfield-large paths.
- **Features:** feature-006 -- **BROWNFIELD scope only**: recon classifier, brownfield-small path,
  brownfield-large path (the greenfield elicit branch + greenfield->brownfield transition are
  carved to delivery-009).
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-005: Validation Fixture

- **What it delivers:** the CI-anchored regression proof that locks in the essence engine -- the
  planted 'Relative bus' fixture proving capture-and-define, the closure self-containment proof, the
  calibration-severity calibration, and the brownfield path fixtures.
- **Features:** feature-012 -- **ENGINE + BROWNFIELD scope only**: AC2 'Relative bus' regression,
  AC3 closure self-containment, AC6 calibration tuning, AC7 brownfield-small/large path fixtures
  (the greenfield path fixture is carved to delivery-009).
- **Depends on:** delivery-001, delivery-004
- **Priority:** Must

### delivery-006: Freshness Primitive

- **What it delivers:** a deterministic per-doc, source-keyed staleness check (each doc's `sources:`
  last-changed commit vs its approval commit -> suspect flag) and its surfacing in both dashboard
  readers (replacing the coarse whole-KB badge); auto-detect/flag, never auto-apply.
- **Features:** feature-007 (per-doc freshness loop)
- **Depends on:** delivery-001
- **Priority:** Should

### delivery-007: Skill Topology + Ship

- **What it delivers:** the `aid-ask` -> `aid-query-kb` rename + the new `aid-update-kb` skill
  (reusing delivery-001's f005 review/calibration gate via the injectable-scope seam) + query-side
  gap-capture, AND the full cross-tree render / orphan-prune / 5-install-manifest lockstep /
  "N user-facing skills" count reconcile / docs-site propagation.
- **Features:** feature-008 (skill topology, author/behavior side), feature-009 (skill-change
  propagation, ship side)
- **Depends on:** delivery-001, delivery-006
- **Priority:** Should

> **Note (f008 + f009 inseparable):** feature-008 and feature-009 are ONE delivery -- one branch,
> one PR, no release tag cut between them. Per the whole-work review, render-drift CI is RED on
> f008 alone (canonical renamed but host trees not re-rendered); f009 is what makes it green.
> Cutting a release between them would ship a half-renamed repo. See Cross-Cutting Risks.

### delivery-008: Lifecycle Governance

- **What it delivers:** the non-overlapping `aid-housekeep` (KB-DELTA, source-driven, global) <->
  `aid-update-kb` (prompt-driven, targeted) boundary contract, with per-doc staleness (f007) as the
  shared scoping signal, AND concept-closure promoted from a discovery-only check to a standing
  invariant re-verified after every KB-mutating skill run.
- **Features:** feature-010 (housekeep <-> update-kb boundary & standing closure)
- **Depends on:** delivery-001, delivery-006, delivery-007
- **Priority:** Should

### delivery-009: Greenfield Path

- **What it delivers:** the forward-authoring greenfield path (elicit intent + vocabulary + design
  via the existing `aid-interview`/`aid-specify` skills, no bespoke greenfield engine) + the
  greenfield->brownfield transition, plus its validation fixture -- a self-contained Could slice.
- **Features:** feature-006 -- **GREENFIELD scope** (elicit branch + transition); feature-012 --
  **GREENFIELD scope** (AC7 greenfield path fixture).
- **Depends on:** delivery-001, delivery-004, delivery-005
- **Priority:** Could

## Cross-Cutting Risks

| # | Risk | Affected deliveries | Mitigation |
|---|------|---------------------|------------|
| R1 | **f006/f012 scope-split** -- feature-006 and feature-012 are each split brownfield-vs-greenfield across delivery-004/005 (brownfield) and delivery-009 (greenfield). Greenfield scope could drift or be double-claimed between the deliveries. | delivery-004, delivery-005, delivery-009 | The split is scoped **explicitly** in each delivery SPEC's Scope section (brownfield ACs named in d004/d005; greenfield ACs named in d009, with the brownfield ACs listed as out-of-scope and vice versa), so no AC is unowned or double-owned. |
| R2 | **f008+f009 inseparability** -- a release tag cut between feature-008 (canonical rename) and feature-009 (cross-tree propagation) would ship a half-renamed repo: canonical renamed but the 5 host trees, install manifests, and skill counts stale, with render-drift CI red. | delivery-007 | The two features are **one delivery** -- one branch, one PR, **no intervening release tag**. render-drift CI is RED on f008 alone and green only once f009 propagates, so the gate itself enforces "ship together." |
| R3 | **calibration-floor back-patch** -- delivery-005 (validation fixtures) and delivery-009 (f006 greenfield/SPIKE-T1 thresholds) re-tune defaults that ALREADY shipped in merged delivery-001 (f004 SPIKE-H2 denylist/salience floor, f005 SPIKE-C1 calibration severity) and delivery-004 (f006 triage thresholds). Per the contract "the default lives in the owning feature's file; the fixture pins it," editing a constant in an already-shipped delivery can regress that delivery's gate. **Impact: M.** | delivery-001, delivery-004, delivery-005, delivery-009 | After any threshold/floor edit prompted by a later delivery's fixture, re-run the owning delivery's gate suite (the owning feature's canonical tests) to confirm no regression. |
