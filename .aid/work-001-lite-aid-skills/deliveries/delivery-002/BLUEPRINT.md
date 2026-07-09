# Delivery BLUEPRINT -- delivery-002: Core Create/Change/Test Shortcuts

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-001-lite-aid-skills
> **Created:** 2026-07-08

---

## Objective

Deliver the Must pilot-cohort shortcuts on top of the delivery-001 engine: the `aid-create`
family (create a new artifact from scratch), the `aid-change` + `aid-refactor` family (modify an
existing artifact / restructure without behavior change), and the `aid-test` + `aid-experiment`
family (verification) — including the `aid-add-*` and `aid-update-*` alias families. These are the
day-to-day workhorse + pilot capabilities (REQUIREMENTS §10 Must), so they ship first after the
foundation.

## Scope

- feature-006-create-family — `aid-create` (bare) + 11 artifact suffixes + 12 `aid-add-*` aliases
- feature-007-change-and-refactor-family — `aid-change` (bare) + 11 suffixes + 12 `aid-update-*`
  aliases + `aid-refactor` (bare)
- feature-009-test-and-experiment-family — `aid-test` (+ `-security`/`-performance`/`-data-quality`)
  + `aid-experiment` (moved here from delivery-003: `aid-test` is a Must pilot skill per §10)

**Out of scope:** the breadth families (delivery-003) and the cutover (delivery-004).

## Gate Criteria

- [ ] All `aid-create*` / `aid-change*` / `aid-refactor` dirs + aliases exist (catalog↔dirs
      parity; count matches feature-006/007), each producing a correct flattened Lite work via
      the engine.
- [ ] Each artifact's **change** task-chain mirrors its **create** task-chain, modify-framed
      (feature-007 ↔ feature-006 consistency).
- [ ] `aid-refactor` stays bare (behavior-preserving) and `aid-fix`/`aid-refactor` take no
      artifact suffixes.
- [ ] The `aid-test` family (`aid-test` + `-security`/`-performance`/`-data-quality`) and
      `aid-experiment` exist and scaffold correct flattened works (test→TEST, experiment→RESEARCH;
      the `aid-test` model-eval mode present); test/vuln findings route to `aid-fix`.
- [ ] `render-drift` CI green; all section-6 quality gates pass.

## Tasks

_none yet_ — filled by `/aid-detail`.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-004

## Notes

Families are mutually independent (each adds catalog rows + a scaffolding reference), so
delivery-002 and delivery-003 could run in parallel once delivery-001 lands.
