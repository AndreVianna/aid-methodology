# Delivery BLUEPRINT -- delivery-001: Foundation + First Shortcut

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-001-lite-aid-skills
> **Created:** 2026-07-08

---

## Objective

Stand up the shared machinery every shortcut skill depends on — the direct-entry
**shortcut-engine** (feature-003), the **flattened single-feature/single-delivery work
structure** and its `/aid-execute` + dashboard-reader adjustments (feature-001), and the
**batched A+ grading + approval gates** (feature-004) — and prove it end-to-end with one working
shortcut, `/aid-fix` (feature-008). This is scoped as the first delivery because nothing else can
ship without the engine, and the foundation is only meaningful once at least one shortcut runs
through it.

## Scope

- feature-001-flattened-lite-work-structure
- feature-003-direct-entry-shortcut-engine (the shortcut-engine, `shortcut-catalog.yml`, the
  maintainer build helper, the 69-dir topology)
- feature-004-approval-and-grading-gates
- feature-008-fix-family (`/aid-fix`) — the minimal end-to-end proof
- feature-015-full-path-pipeline-rename (the full-path `deliveries/delivery-NNN/{BLUEPRINT,DETAIL}`
  rename across `aid-plan`/`aid-detail`/`aid-execute` + the delivery/task templates + both dashboard
  reader twins, plus the delivery-gate criteria mis-wire fix — grouped here with feature-001's
  structural/reader work)

**Out of scope:** all other shortcut families (delivery-002/003) and the cutover (delivery-004).
`/aid-describe`'s lite path still exists during this delivery — the shortcuts are additive here.

## Gate Criteria

- [ ] The shortcut-engine, flattened work structure, and A+ gates are implemented in `canonical/`
      and render to all five profiles (`render-drift` CI green; dogfood `.claude/` byte-identical).
- [ ] `/aid-fix` invokes directly (no interview/triage), scaffolds a flattened Lite work
      (`REQUIREMENTS.md` + `SPEC.md` + `PLAN.md` + `tasks/task-NNN/`, no `features/` or
      `delivery-NNN/`), each document clears its A+ grading gate, and it **halts at the approval
      gate** with no execution.
- [ ] Both dashboard reader twins (Python + Node) consume the flattened layout identically
      (feature-001 reader-parity fixture passes).
- [ ] The catalog↔dirs parity test passes for the fix-family rows; `/aid-fix` name == its dir.
- [ ] The full-path pipeline is renamed to `deliveries/delivery-NNN/BLUEPRINT.md` +
      `tasks/task-NNN/DETAIL.md` across `aid-plan`/`aid-detail`/`aid-execute`, the two definition
      templates, and both dashboard reader twins — no surviving `delivery-NNN/SPEC.md` or task
      `SPEC.md` (A-10 clean switch); the delivery gate reads its criteria from
      `BLUEPRINT.md § GATE CRITERIA`; `render-drift` + `tests/run-all.sh` green.
- [ ] All section-6 quality gates pass.

## Tasks

_none yet_ — filled by `/aid-detail`.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** -- (none — foundation)
- **Blocks:** delivery-002, delivery-003, delivery-004

## Notes

Foundation could not ship alone (an empty catalog yields no invocable skill), so `/aid-fix` is
bundled as the minimal proof of the whole pattern. Detailed design lives in the five feature
SPEC.md files (all A+).
