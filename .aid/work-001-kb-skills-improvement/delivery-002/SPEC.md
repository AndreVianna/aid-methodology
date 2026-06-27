# Delivery SPEC -- delivery-002: INDEX Routing

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-002/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Flip `INDEX.md` from today's prose-`intent:` list to a generated, deterministic **routing table**
so agents and humans find the right doc fast and reliably. Each row carries
*Document (link = path) | Objective | Summary | Tags | See-instead | Audience*, where Audience lets
a human filter to docs for their role and See-instead provides negative routing ("use this doc, not
that one") against the siloed-logic trap. The table is composed mechanically by `build-kb-index.sh`
from the frontmatter fields delivery-001 established -- no LLM, git-diffable, dependency-free -- and
the INDEX-fresh / KB-hygiene CI checks are updated to assert the new format.

## Scope

In scope:

- **feature-002 -- INDEX routing table.** Change `build-kb-index.sh` from prose-`intent:` emission
  to a per-category routing table (Document | Objective | Summary | Tags | See-instead | Audience),
  consuming f001's frontmatter fields + `extract_list` helper; update the INDEX-fresh / KB-hygiene
  CI expectations to the new table format; keep the `objective`->`intent` coexistence fallback so an
  un-migrated KB still renders. The rejected vector/MCP router is out of scope.

**Out of scope:** the frontmatter schema + `extract_list` + soft-skip lint (delivery-001, f001 --
consumed here as final); migrating AID's own KB so its INDEX rows are fully populated rather than
fallback-rendered (delivery-003, f011).

## Gate Criteria

- [ ] When `build-kb-index.sh` runs, `INDEX.md` is the generated routing table with columns
  Document | Objective | Summary | Tags | See-instead | Audience. *(f002, AC4)*
- [ ] The table is composed deterministically from frontmatter with no LLM, and the INDEX-fresh /
  KB-hygiene CI checks pass under the new format. *(f002, AC4)*
- [ ] For two docs with a conflicting rule, See-instead negative routing points an agent to the
  authoritative/related doc. *(f002; addresses the P6 siloed-logic trap)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-003

## Notes

Consumes delivery-001's f001 frontmatter schema + `extract_list` parser. The `objective`->`intent`
coexistence fallback (and first-sentence Summary fallback) keep an un-migrated KB rendering until
delivery-003 (f011) migrates AID's own docs and fully populates the table cells. The INDEX-fresh CI
step is format-agnostic (regen + timestamp-filtered diff) but its asserted shape is updated here.
