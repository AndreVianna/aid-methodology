# Delivery BLUEPRINT -- delivery-004: Cutover

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-004
> **Work:** work-001-lite-aid-skills
> **Created:** 2026-07-08

---

## Objective

Complete the pipeline restructuring so the shortcut skills become the **sole** Lite-path entry.
Reduce `/aid-describe` to full-path-only (feature-013), stand up the new `/aid-triage` router
(feature-014), delete the now-unused recipe catalog and orphaned lite/triage references
(feature-002), and re-point `aid-monitor` onto the new skills (feature-012). This is the "switch"
— it removes the old lite path, so it runs **last**, only after every shortcut family exists, to
avoid a lite-entry capability gap.

## Scope

- feature-013-aid-describe-full-only — remove `/aid-describe`'s lite path + TRIAGE state
- feature-014-aid-triage-router — the new suggest-only `/aid-triage`
- feature-002-recipe-removal — delete the recipe catalog + `parse-recipe.sh` + orphaned refs
- feature-012-deploy-and-monitor-repurpose — `aid-monitor` re-point (BUG→`/aid-fix`,
  CR→`/aid-triage`) + the optional shortcut invocation-context mode on `aid-deploy`/`aid-monitor`

**Out of scope:** the shortcut families themselves (delivered in 001–003). No new shortcut verbs
are introduced here.

## Gate Criteria

- [ ] `/aid-describe` runs full-path only — no lite branch, no triage prompt; its full-path
      elicitation engine is preserved intact.
- [ ] `/aid-triage` suggests the correct entry for a free-form description (full via
      `/aid-describe`, or the matching shortcut).
- [ ] The recipe catalog is removed: `canonical/aid/recipes/` gone, `parse-recipe.sh` + tests
      retired, and the no-dangling test (scoped to **all of `canonical/`**, incl. the 7 deleted
      reference-doc filenames) is green; `render-drift` green after deletions.
- [ ] `aid-monitor` routes BUG → `/aid-fix` and change-request → `/aid-triage`, with no surviving
      reference to the removed `aid-describe`-lite; `aid-deploy`/`aid-monitor` keep their existing
      pipeline role.
- [ ] No lite-entry regression; `tests/run-all.sh` green. All section-6 quality gates pass.

## Tasks

_none yet_ — filled by `/aid-detail`.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001, delivery-002, delivery-003 (all shortcut families must exist so
  no lite-entry gap opens; feature-012's re-point needs `/aid-fix` (d-001) and `/aid-triage`
  (this delivery))
- **Blocks:** -- (none)

## Notes

Coupling to honor within this delivery: feature-014 must extract `state-triage.md`'s reflect-back
turn **before** feature-002 deletes that file; feature-002 deletes exactly the 7 references
feature-013 orphans (same wave); feature-012's re-point lands after 013+014. See each feature
SPEC's coupling section.
