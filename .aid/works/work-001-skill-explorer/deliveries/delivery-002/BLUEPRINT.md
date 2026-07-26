# Delivery BLUEPRINT -- delivery-002: A browsable `/skills/` catalog

[!NOTE]
This is the IMMUTABLE DEFINITION of delivery-002. Written once by aid-plan; not a state file —
delivery-002's lifecycle, gate and Q&A live in `deliveries/delivery-002/STATE.md`.

> **Delivery:** delivery-002
> **Work:** work-001-skill-explorer
> **Created:** 2026-07-26

---

## Objective

Publish the catalog itself: a `/skills/` section of the docs site with one detail page per skill
in `canonical/skills/`, and an index that makes them findable. Each detail page renders that
skill's **complete** frontmatter — every key the file carries, including the list-valued and
folded-scalar keys the existing reference generator drops — and the index lists one card per
skill under the owner-corrected taxonomy. This is the smallest state in which a reader can find
and read a skill's declared contract, and it is strictly more than `reference/skills.md` offers
today. The chart body is deliberately empty here: the body slot renders as a comment, so a page
reads as a page with an unfilled slot rather than a broken one, and delivery-003 fills it.

## Scope

- **feature-001 (remainder)** — the generator harness: `site/scripts/gen-skills.mjs` plus the
  `site/scripts/skills/` module cluster; the `gen:skills` npm script threaded into
  `prebuild`/`predev` after `gen:reference`; identity slug derivation to `/skills/<dir>/`; `.md`
  output with the "generated — do not edit" marker; `site/scripts/.skills-manifest.json`; the
  strict frontmatter parser that satisfies AC-2; the throw-on-drift guard; and the
  `BODY_PROVIDERS` / `BODY_APPENDERS` body slot that deliveries 003–004 register into.
- **feature-002** — `skills/index.md`: one card per skill, two-level grouping (the curated four,
  with `Definition` subdivided by catalog verb family), the `catalog.mjs` one-way catalog reader,
  the sidebar group in `site/astro.config.mjs`, and the 15-assertion AC-8 suite.

**Out of scope:** every chart (delivery-003) and every verbatim fragment or deep link
(delivery-004); the interactive panel (delivery-005); `gen-reference.mjs`, still frozen by §7,
so KI-003, KI-009 and KI-010 remain open and the grouping divergence between `/skills/` and
`reference/skills.md` is signposted rather than resolved.

## Gate Criteria

- [ ] **AC-1 — Coverage.** Every directory under `canonical/skills/` has a generated detail page,
      and the generator **throws** when the generated page set diverges from the on-disk skill
      set, in either direction.
- [ ] **AC-2 — Header completeness.** Every frontmatter key present in a skill's `SKILL.md`
      appears in its page header; no key is silently dropped. Verified at fixture granularity
      against the list-valued and folded-scalar keys the existing parser mishandles.
- [ ] **AC-6 — Idempotence.** Two consecutive generator runs produce byte-identical output.
- [ ] **AC-8 — Index shape.** One card per skill, nested under the four curated groups, with
      `Definition` cards subdivided by the catalog-derived verb family. `aid-triage` appears under
      **Support**; `aid-deploy` and `aid-monitor` appear under their own `deploy` / `monitor`
      families, **not** in the full-path block; the five full-path skills appear in pipeline
      order in the un-subdivided opening block and are exempt from the family check. No assertion
      compares against a numeric literal.
- [ ] The **clamp** holds: a skill directory that is neither curated nor catalog-backed fails the
      build **by name** rather than silently missing its card.
- [ ] **Build integration clause (a):** `gen-reference.mjs` is byte-unmodified, its drift guard
      passes, and its four generated reference pages are byte-unchanged after a full `prebuild`.
- [ ] Every card links to a page that exists — no dead cards — and the section is reachable from
      the sidebar and highlights in the header tab bar.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ — `aid-detail` fills this table.

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001 (its acceptance is expressed as vitest tests, which nothing runs
  until delivery-001 lands)
- **Blocks:** delivery-003 (body slot, manifest, `SkillRecord`, slug identity)

## Notes

- **This delivery is the first to open `site/astro.config.mjs`**, and two one-line ride-alongs
  are proposed for it, both **pending owner approval** rather than assumed: **KI-012**
  (`enableLog` defaults to true, so the production site logs to every visitor's console on every
  page — and this work multiplies that by 111 pages) and **KI-013** (the component-map comment
  claims the map is empty when it holds four keys, and reserves slots using a *previous* work's
  `feature-NNN` numbers). Neither is in the gate criteria above.
- **Risk R7 — page-count multiplication.** This adds 111 pages to the content collection and the
  Pagefind index, plus ~112 sidebar anchors on every page of the site. Nothing is gated on a
  budget, but feature-001 asks for the `docs.yml` build time to be read on the first run; that
  reading belongs at this delivery's gate.
- **feature-002 OQ-1 is open and non-blocking:** `aid-query-kb` and `aid-ask` stay in Knowledge
  Base Maintenance by default, which leaves the `query` verb family rendering no section at all.
  Reversal is two names deleted from one array. Best judged against the rendered index at this
  gate.
- Contract text frozen here is **reopened by delivery-003** — see delivery-003's Notes for the
  four unreconciled seams. That is anticipated, not a surprise.
