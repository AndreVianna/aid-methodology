---
pipeline:
  path: lite
  initiator: none
started: "2026-07-15"
minimum_grade: "A"
user_approved: no
lifecycle: Running
phase: Specify
active_skill: none
updated: "2026-07-15T23:31:05Z"
pause_reason: --
block_reason: --
block_artifact: --
delivery_state: Pending-Spec
gate_tier: Large
gate_grade: "Pending"
gate_timestamp: "--"
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

---

## Delivery Lifecycle

- **Updated:** 2026-07-15T20:25:30Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

State enum: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 aid-review / aid-audit | In Progress | -- | -- | Spec LOCKED (specs/aid-review.md); canonical implementation pending |
| task-002 research / investigate / spike | In Progress | -- | -- | Spec LOCKED (specs/aid-research.md); canonical implementation pending |
| task-003 report | In Progress | -- | -- | Spec LOCKED (specs/aid-report.md); canonical implementation pending |
| task-004 experiment | In Progress | -- | -- | Spec LOCKED (specs/aid-experiment.md). NOT a collapse: keep cycle, engine-driven; content-only adaptation of test-experiment.md (3 new capture slots, rigor->REQUIREMENTS, validation->SPEC). Implementation pending |
| task-005 document family restructure | In Progress | -- | -- | Spec LOCKED (specs/aid-document.md). RESTRUCTURED: document is a create/change ARTIFACT -> generic aid-create-document/aid-change-document (+add/update aliases); 8 old aid-document* + aid-create-diagram = hint-aliases; collapse; KB boundary. Implementation pending |
| task-006 prototype + new aid-design | In Progress | -- | -- | Spec LOCKED (specs/aid-prototype-design.md). aid-prototype generic (throwaway, LIGHT verify); aid-prototype-ui -> hint-alias; NEW aid-design (kept design, full verify, fills DESIGN gap). Both collapse. Implementation pending |
| task-007 test-family restructure | Pending | -- | -- | NEW +4 skills (aid-create-test/+add-test, aid-change-test/+update-test = keep-cycle); aid-test -> generic run+consolidate (collapse); test-security/performance/data-quality -> hint-aliases; removal via bare aid-remove. Not yet designed |

---

## Delivery Gate

- **Issue List:** none yet

---

## Notes

- **Classification map:** `specs/classification.md` is the authoritative refactor map
  (refined 2-axis discriminator; collapse / keep-cycle / correct-as-is; the test-family
  restructure). Per-skill locked contracts live in `specs/aid-*.md`.
- **Regeneration reminder:** any `canonical/` edit here must flow through
  `build-shortcut-skills.py` → full `run_generator.py` → dogfood `.claude/` resync
  (test-dogfood-byte-identity enforces it) before the change reaches an installed CLI.
