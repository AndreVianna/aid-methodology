---
pipeline:
  path: lite
  initiator: none
started: "2026-07-15"
minimum_grade: "A+"
user_approved: no
lifecycle: Paused-Awaiting-Input
phase: Detail
active_skill: none
updated: "2026-07-16T02:03:12Z"
pause_reason: "pre-regen checkpoint -- canonical source A+ gate CLEARED; batch regen (run_generator + dogfood resync + verify) pending user go-ahead"
block_reason: --
block_artifact: --
delivery_state: Pending-Spec
gate_tier: Large
gate_grade: "A+"
gate_timestamp: "2026-07-16T02:03:12Z"
---

# Work State -- work-005-lite-skills-refactor

Review-and-refactor of the canonical **Lite (direct-entry shortcut) skills**. Driven by a
direct maintainer prompt (`initiator: none`), not a pipeline skill. Two root problems:

1. **Red tape** -- several Lite skills promise a deliverable in their objective but the
   shared shortcut engine only *plans* the work and halts before executing, so the user
   never gets the thing they asked for (the "clear mismatch" set).
2. **Over-provisioned dispatch** -- every Lite invocation fires ~5 Opus dispatches at
   fixed max tier regardless of how trivial the request is.

This work redesigns the mismatch skills one at a time (design + lock a spec under
`specs/`, then implement in `canonical/`), and threads model/effort tiering through each.

---

## Pipeline State

> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute | Deploy
> Active Skill enum: aid-{skill} | none

Values live in the YAML frontmatter above. `phase` maps loosely: the effort is in a
design/specify stage. Standalone read-only skills produced by this work do **not** drive
the 7-phase `phase` scalar (see `specs/aid-review.md §10`).

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-15 | Work created | -- | Direct-prompt maintainer effort; branch work-005-lite-skills-refactor |
| 2026-07-15 | Mismatch analysis | -- | Classified all engine-driven Lite skills; 15 clear mismatches, 6 gray, 55 correct-as-is |
| 2026-07-15 | aid-review/aid-audit spec LOCKED | -- | specs/aid-review.md; 3 open items settled with user |
| 2026-07-15 | task-002 design started | -- | research/investigate/spike; deltas from aid-review |
| 2026-07-15 | aid-research spec LOCKED | -- | specs/aid-research.md; resolves-nothing frame, 2-tier grounding, authorized-spike escalation |
| 2026-07-15 | task-003 design started | -- | report; deltas from aid-research |
| 2026-07-15 | aid-report spec LOCKED | -- | specs/aid-report.md; data/usage input, data-quality caveats first-class, viz-vs-dashboard boundary |
| 2026-07-15 | task-004 design started | -- | experiment; deltas from aid-research/report |
| 2026-07-15 | task-004 RECLASSIFIED | -- | experiment is NOT a collapse; keep the plan->execute cycle + specialize its rigor (pre-run design + pre-registered AC + design-validity gate) |
| 2026-07-15 | aid-experiment spec LOCKED | -- | specs/aid-experiment.md; content-only scaffolding adaptation, no engine/catalog change; +3 capture slots |
| 2026-07-15 | Classification refined + folded in | -- | specs/classification.md; 2-axis discriminator; gray zone resolved (prototype->collapse; test family restructured); tasks 006/007 split out |
| 2026-07-15 | task-005 design started | -- | document*; producer=aid-tech-writer, 8 archetypes, placement gate, KB boundary |
| 2026-07-15 | aid-document spec LOCKED | -- | specs/aid-document.md; RESTRUCTURED to create/change-document artifact + generic skill + hint-aliases (genre+format); collapse; KB boundary |
| 2026-07-15 | task-006 design started | -- | prototype/prototype-ui; spike-shaped collapse, producer=aid-architect |
| 2026-07-15 | aid-prototype + aid-design spec LOCKED | -- | specs/aid-prototype-design.md; split throwaway(prototype)/kept(design); NEW aid-design; light vs full verify by longevity |
| 2026-07-15 | task-007 design started | -- | test-family restructure; formalizing settled shape |
| 2026-07-15 | aid-test spec LOCKED | -- | specs/aid-test.md; create/change-test keep-cycle + aid-test run-consolidate collapse + test-* hint-aliases |
| 2026-07-15 | task-008 folded in + aid-dashboard spec LOCKED | -- | specs/aid-dashboard.md; show-dashboard reframed to create/change-dashboard artifact (2nd re-examination find); +14 new skills total |
| 2026-07-15 | DESIGN PHASE COMPLETE (8/8 tasks locked) | -- | all specs/ locked; implementation-plan.md written |
| 2026-07-15 | Paused: Phase-0 decision | -- | shared collapse-engine vs per-skill bodies -- awaiting user before review implementation |
| 2026-07-15 | Phase-0 RESOLVED | -- | per-skill hand-authored bodies (aid-query-kb model), no shared collapse-engine |
| 2026-07-15 | task-001 implementation started | -- | review pilot: source edits (catalog repurpose, aid-review + aid-audit SKILL.md, engine detach) |
| 2026-07-16 | Housekeeping committed (a0007312) | -- | v2.1.0 install residue honored + knowledge-base/README removed everywhere + aid-discover link fixed |
| 2026-07-16 | task-001 pilot source committed (c03ae93d) + APPROVED | -- | user reviewed the collapse pattern; approved to replicate |
| 2026-07-16 | task-002 canonical source done | -- | aid-research collapse + investigate/spike aliases + engine detach; --check: 71 up-to-date, 9 repurpose, 0 orphans |
| 2026-07-16 | task-003 canonical source done | -- | aid-report collapse (aid-researcher producer, data/usage input, caveats mandatory) + engine detach; --check: 70/10/0 |
| 2026-07-16 | task-006 canonical source done | -- | aid-prototype collapse + aid-prototype-ui hint-alias + NEW aid-design skill + engine detach; --check: 68/13/0 (catalog +1) |
| 2026-07-16 | task-004 canonical source done | -- | experiment: content-only scaffolding adaptation (test-experiment.md); no catalog/engine/skill change |
| 2026-07-16 | task-005 canonical source done | -- | document restructure: create/change-document + aliases + create-diagram + 8 genre kind-siblings (subagent-authored delegations, spot-checked) + engine detach; --check 60/26/0 |
| 2026-07-16 | task-007 canonical source done | -- | test restructure: create/change-test authoring doorways generated; aid-test run collapse + 3 kind-siblings; create.md test artifact + ownership fix; engine detach; --check 60/30/0. (build-shortcut-skills WRITE deleted the marker-orphan test doorways before I re-authored them -- expected) |
| 2026-07-16 | task-008 canonical source done | -- | dashboard reframe: create/change-dashboard + aliases + show-dashboard alias (engine-driven); create.md dashboard artifact; engine detach; --check 64/30/0 |
| 2026-07-16 | ALL 8 families canonical source DONE -- PRE-REGEN CHECKPOINT | -- | catalog 94 rows, 64 doorways / 30 repurpose / 0 orphans; +14 new skills; batch regen (run_generator + dogfood resync + verify) pending user go-ahead |
| 2026-07-16 | A+ GATE cleared (canonical source) | A+ | aid-reviewer adversarial gate, 5 REVIEW->FIX cycles: C (4 findings) -> 3 fix-everywhere residuals -> A+ (0 findings). minimum_grade raised A -> A+. Ledger: .aid/.temp/review-pending/work-005-impl.md |

---

## Delivery Lifecycle

- **Updated:** 2026-07-15T20:25:30Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

State enum: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 aid-review / aid-audit | In Progress | -- | -- | PILOT: canonical source committed (c03ae93d), pattern APPROVED by user; profiles/dogfood pending batch regen |
| task-002 research / investigate / spike | In Progress | -- | -- | Canonical source done (aid-research hand-authored + investigate/spike aliases + engine detach); profiles/dogfood pending batch regen |
| task-003 report | In Progress | -- | -- | Canonical source done (aid-report hand-authored collapse; engine detach); profiles/dogfood pending batch regen |
| task-004 experiment | In Progress | -- | -- | Canonical source done: test-experiment.md aid-experiment section adapted (+3 capture slots, rigor->REQUIREMENTS §5/§9, Experiment Design section in SPEC). Engine-driven, unchanged topology; profiles/dogfood pending batch regen |
| task-005 document family restructure | In Progress | -- | -- | Canonical source done: aid-create/change-document full bodies + add/update pure aliases + aid-create-diagram + 8 legacy aid-document* rewritten as kind-siblings (delegate) + engine detach; --check 60/26/0 (catalog 86 rows). profiles/dogfood pending batch regen |
| task-006 prototype + new aid-design | In Progress | -- | -- | Canonical source done: aid-prototype hand-authored collapse (LIGHT verify), aid-prototype-ui hint-alias, NEW aid-design (kept, full verify) + engine detach; profiles/dogfood pending batch regen |
| task-007 test-family restructure | In Progress | -- | -- | Canonical source done: create/change-test (+add/update) engine-driven authoring doorways generated; aid-test hand-authored run collapse + 3 kind-siblings; create.md gains test artifact + ownership fix; engine detach. --check 60/30/0 (catalog 90). FOLLOW-UP: trim dormant test sections in test-experiment.md. profiles/dogfood pending batch regen |
| task-008 dashboard reframe | In Progress | -- | -- | Canonical source done: create/change-dashboard (+add/update + show-dashboard aliases) engine-driven doorways generated; create.md gains dashboard artifact; engine detach (analyze-report.md now orphaned -- follow-up trim). --check 64/30/0 (catalog 94). profiles/dogfood pending batch regen |

---

## Delivery Gate

- **Issue List:** none yet

---

## Follow-ups (deferred; not in the A+-graded set)

- **Reframe + re-gate `test-experiment.md` (test half) + `analyze-report.md`.** Both still
  carry the stale "consulted by the shared engine" framing for now-detached families
  (same class the A+ gate fixed in document.md/prototype.md). Deferred out of the gate
  scope deliberately; reframe them and run their own A+ gate together, then regenerate.
  (`test-experiment.md` is still live for `experiment`; `analyze-report.md` is orphaned.)
- **`generate-profile` VALIDATE prose** hardcodes "92 skills / 76 shortcuts / aid-ask
  only hand-authored" -- update to the new counts (maintainer tooling; not shipped).

## Notes

- **Classification map:** `specs/classification.md` is the authoritative refactor map
  (refined 2-axis discriminator; collapse / keep-cycle / correct-as-is; the test-family
  restructure). Per-skill locked contracts live in `specs/aid-*.md`.
- **Regeneration reminder:** any `canonical/` edit here must flow through
  `build-shortcut-skills.py` → full `run_generator.py` → dogfood `.claude/` resync
  (test-dogfood-byte-identity enforces it) before the change reaches an installed CLI.
