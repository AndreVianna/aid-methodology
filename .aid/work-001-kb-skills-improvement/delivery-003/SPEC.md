# Delivery SPEC -- delivery-003: KB Migration

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-003/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Ensure no existing KB is stranded on the old format when the new frontmatter schema and INDEX
routing table land. Migrate AID's own KB (plus a fixture old-format KB) onto the new frontmatter
(`objective`/`summary`/`tags`/`see_also`/`owner`/`audience`/`sources`) and the new INDEX format,
following AID's existing migration precedent (`migrate-work-hierarchy`, the content-isolation
migration) and remaining safe/reversible. Migrating AID's whole corpus into compliance makes
`lint-frontmatter.sh` **effectively hard for AID** (the shipped soft-skip is retained for adopter
degrade-grace, NFR-7). Moved early in the sequence so AID dogfoods the new schema, and so later
freshness (delivery-006) operates on docs stamped with `approved_at_commit:`.

## Scope

In scope:

- **feature-011 -- KB migration.** A new shipped migration script under
  `canonical/aid/scripts/migrate/`; a one-line scope-predicate widening of `lint-frontmatter.sh`
  (the soft-skip is **retained**, not removed); a re-run (not edit) of `build-kb-index.sh`; the
  dogfood migration of AID's own ~16 in-scope KB docs (15 hand-authored + the
  `host-tool-capabilities.md` edge case); a fixture old-format KB; and CI wiring. The migration
  moves `intent:` content into `objective:`/`summary:`, seeds `sources:`, and stamps
  `approved_at_commit:` at migration HEAD.

**Out of scope:** authoring the frontmatter field schema or the soft-skip lint (delivery-001, f001);
the INDEX table format + `intent:` coexistence fallbacks (delivery-002, f002); the concern model /
expectations transform / `intent:`->`objective` supersession decision (delivery-001, f003); the
concept-spine *structure* (delivery-001, f004); the calibration grade / review panel
(delivery-001, f005). f011 migrates content INTO these contracts; it does not author them.

## Gate Criteria

- [ ] Given an old-format KB (AID's own and a fixture old-format KB), migration upgrades it to the
  new frontmatter schema and INDEX format. *(f011, AC9)*
- [ ] Given an un-migrated old-format KB, the pipeline degrades gracefully and keeps functioning
  until the KB is upgraded. *(f011, NFR-7, AC9)*
- [ ] The migration follows AID's existing migration precedent and is safe/reversible. *(f011, NFR-7)*
- [ ] After AID's corpus is migrated, `lint-frontmatter.sh` is effectively hard for AID (the
  shipped soft-skip retained for adopters); AID's INDEX renders fully-populated rows; render-drift,
  KB-hygiene, and INDEX-fresh CI green. *(f011)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-002
- **Blocks:** -- (none; delivery-006 reads the stamped `approved_at_commit:` it produces but does not
  hard-depend on it -- an un-stamped doc degrades to freshness verdict `unknown`)

## Notes

Consumes delivery-001 (f001 schema + soft-skip lint; f003 supersession decision; f004 spine
structure; f005 panel) and delivery-002 (f002 INDEX table + coexistence fallbacks). This delivery is
where AID begins dogfooding the new schema. It produces the `approved_at_commit:` stamps that
delivery-006's freshness check uses as the per-doc baseline; an un-stamped doc is never a lint
failure and freshness treats absence as "baseline unknown."
