# Delivery SPEC -- delivery-006: Split aid-interview into aid-describe + aid-define

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-006
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Restructure the (now-enhanced) `aid-interview` skill into two outcome-named skills at the natural
seam -- the approved-requirements gate -- so the pipeline reads as the informal-to-formal progression
the work intends: `aid-describe` (the conversational intent-gathering half) then `aid-define` (the
feature-shaping half). This is the disruptive directory restructure, so it lands LAST, after the
content deliveries have finalized the skill's file set.

## Scope

feature-006-rename-aid-define (re-spec'd to the D3 SPLIT): partition the state machine + `references/`
between `aid-describe` (FIRST-RUN / Q-AND-A / TRIAGE / CONTINUE / COMPLETION + the entire lite path)
and `aid-define` (FEATURE-DECOMPOSITION / CROSS-REFERENCE / DONE); the inter-skill seam (redirect
COMPLETION's existing pause-resume signpost from `/aid-interview` to `/aid-define`); byte-identical
render of both new dirs across the 5 host trees + dogfood mirror; orphan-prune the old
`aid-interview/` dir; update install manifests (x2) + docs-site (x2) + the skill-count surfaces
(+1, 13->14, incl. spelled-out forms); preserve the `aid-interviewer` agent (substring guard).

**Out of scope:** any conversational behavior change (delivery-003/004 own that); the seed model
(delivery-004); the conformance check (delivery-005). This delivery is partition + propagation only.

## Gate Criteria

- [ ] `aid-interview` is replaced by `aid-describe` + `aid-define` with the state machine + `references/` correctly partitioned and the inter-skill hand-off at the approval gate working (aid-describe pauses at approval -> /aid-define; aid-define precondition = Interview State: Approved). *(AC-8)*
- [ ] Both new skill dirs render byte-identically across the 5 host trees + dogfood mirror (DBI); the old `aid-interview/` dir is orphan-pruned from every tree. *(AC-8 / NFR-6)*
- [ ] Install manifests, docs-site entries, and skill-count surfaces are updated for +1 skill (13->14, numeric AND spelled-out); two manifest + two docs entries. *(AC-8 / D3)*
- [ ] The `aid-interviewer` agent is untouched -- its token count is unchanged before/after the boundary-aware sweep. *(AC-8)*
- [ ] CI is green: render-drift, DBI, the gen-reference skills-drift guard, ASCII-only, installer (incl. Windows lane), docs/Astro build -- including the master-only heavy gates. *(AC-8 / NFR-6)*

## Tasks

Detailed by aid-detail. Per the delivery note, task-036 re-derives the blast-radius inventory + the
final `references/` partition against the THEN-current tree (post delivery-003/004/005) before the
canonical carve (task-037) runs. Global numbering continues from delivery-005's last (task-035).

| Task | Type | Title |
|------|------|-------|
| task-036 | DOCUMENT | Re-derived blast-radius inventory + final references/ partition |
| task-037 | IMPLEMENT | Canonical carve into aid-describe + aid-define with partitioned states and inter-skill seam |
| task-038 | IMPLEMENT | Boundary-aware external skill-name sweep + 13->14 count-increment surfaces |
| task-039 | CONFIGURE | Full generator render of both new dirs + orphan-prune + mirror/manifests/docs regen |
| task-040 | TEST | Split verification -- DBI, orphan-prune, count +1, substring guard, CI green |

## Dependencies

- **Depends on:** delivery-003, delivery-004 (operates on the FINAL in-place content; the split partitions their resulting `references/` set), AND **delivery-005** (a sequencing edge, not a content dependency -- both d005 and d006 edit `canonical/skills/aid-discover/references/state-generate.md`, so they must not run in parallel)
- **Blocks:** -- (none; the work's terminal delivery)

## Notes

The disruptive restructure -- sequenced LAST (after delivery-005). It shares
`aid-discover/references/state-generate.md` with delivery-005 (d005 adds the `output_root` param;
d006's name-sweep rewrites the `/aid-interview` tokens there), so it must run AFTER d005, not
alongside. Per the feature SPEC, the inter-skill seam is the ONE state-machine edit beyond moving
files (COMPLETION already PAUSEs; only its resume target changes).
