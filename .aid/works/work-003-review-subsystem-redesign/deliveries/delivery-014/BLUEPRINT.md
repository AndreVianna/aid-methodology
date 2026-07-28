# Delivery BLUEPRINT -- delivery-014: Settings and frontmatter gates

> **Delivery:** delivery-014
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Close the two highest-leverage unreviewed artifacts: the settings file, which carries every gate's
minimum grade and which nothing validates, and KB frontmatter, whose mechanical linter exists and is
invoked by no skill state. Also re-certifies AC-11 after this feature's own edits.

## Scope

- `lint-settings.sh` validating the minimum-grade enum, the config enums, the doc-set row shape and
  the term exclusions -- deriving the grade alphabet from the rubric rather than restating it.
- Three wiring sites, including `aid-deep-review` INTAKE, where a later hand-edit is caught at the
  moment it would loosen a gate.
- `lint-frontmatter.sh` wired as a runtime gate, with `--fail-on-skip`, and the M2 mandate's
  duplicate hand-checks retired.
- The renderer-blind `.claude/aid/` invocation path corrected.
- AC-11 re-measured and re-certified.

**Out of scope:** the settings-history mechanism -- the loosening criterion is satisfied by printing
the resolved bar at every gate site.

## Gate Criteria

- [ ] An out-of-enum minimum grade is rejected; the live settings file passes
- [ ] The grade enum is derived from the rubric, not restated -- so no sixth grade alphabet appears
- [ ] Every gate-relevant settings key is covered, over a mechanically derived key set
- [ ] The frontmatter lint is invoked by a skill state, and the M2 duplicate checks are gone while a
      pointer to the lint remains
- [ ] No canonical body carries a hardcoded `.claude/aid/` script path
- [ ] AC-11 re-certified on the delivery-001 baseline
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-004, delivery-012
- **Blocks:** -- (none)

## Notes

**Spine delivery.** Its consumption-time settings check is affordable only because delivery-012
collapsed 27 minimum-grade reads into one INTAKE.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | lint-settings.sh |
| task-002 | IMPLEMENT | 1 | The frontmatter runtime gate |
| task-003 | CONFIGURE | 2 | Wire the settings gate |
| task-004 | TEST | 3 | AC-11 re-certification |
