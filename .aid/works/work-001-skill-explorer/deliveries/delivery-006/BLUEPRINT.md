# Delivery Blueprint -- delivery-006

> **Delivery:** delivery-006 — unify the two skill sections
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-005 (continued; no new branch — see Sequencing)
> **Source:** work-level **Q4** (answered 2026-07-27 by the work owner), which amends **§7**

---

## Why this delivery exists

The site has **two sections about skills** — `/skills/` and `/reference/skills/` — presenting the
same roster under the same four groups, one derived from `canonical/` and one hand-maintained. The
owner's answer to Q4 is to unify them: repoint readers at the derived section, and **hollow out**
the reference page rather than delete it, because it is the only place the shortcut-engine
narrative lives.

This was deliberately sequenced after delivery-005: nothing in deliveries 003–005 depends on it,
and doing it earlier would have put a third concurrent editor on `astro.config.mjs` (risk R1).

## Scope, measured rather than assumed

Every quantity below was re-derived on 2026-07-29 before planning, not taken from the Q4 record.

~~**The triple is 111 / 21 / 64**~~ — **amended 2026-07-30 (gate cycle 4): the decomposition
that SUMS is 111 = 17 curated + 94 catalog** (itself 64 verb-first + 30 `repurpose`). The 21
curated figure counts four skills that are ALSO catalog rows — `aid-deploy`, `aid-monitor`,
`aid-query-kb` and the `aid-ask` alias — so pairing it with a catalog count double-counts
them. That is the defect this delivery shipped onto the home page and then corrected.
111 directories under `canonical/skills/`; 21 curated entries
(19 classic + `/aid-triage` + `/aid-ask`); 64 emitting catalog rows. The generated
`reference/skills.md` already renders these correctly at line 9, because it derives them at build
time. So **KI-003 is stale comments, not stale output** — `gen-reference.mjs` lines 5–6, 147 and
390 still claim 94 / 16 classic / 76. **Amended at gate cycle 3:** this enumeration is
incomplete -- three further hand-counts were found in the same file, two of them in
reader-facing OUTPUT rather than comments (a "67 near-identical H3 blocks" comment against a
real 64, and "the 4 classic re-registered skills" hard-coded twice into the rendered page).
Six sites, not three. The guard now matches count SHAPES rather than the two literal strings
that had already drifted, which is what found them.

**The stale prose is in hand-authored files only**, exactly where Q4 said:
`site/src/content/docs/index.mdx` lines 76, 77, 91, 92 and
`site/src/content/docs/reference/overview.md` line 16 all claim 92 / 14 classic / 76.

**KI-009 is live and visible in the shipped page.** `reference/skills.md` line 185 renders
``` `aid-test` + 3 typed forms (security, performance, data-quality) = 0 ``` and line 187 renders
``` `aid-document` + -1 typed forms ```. Root cause found at `gen-reference.mjs` 245 and 255: both
templates assume the family has non-`repurpose` catalog rows, then interpolate
`rows.filter(...).length` and `rows.length - 1` against an empty array. Both die with the roster
table this delivery sheds, so KI-009 closes **by deletion** rather than by arithmetic repair.

## Gate Criteria

- [ ] **No hand-counted number is introduced.** Every skill-count claim on a hand-authored page is
      checked against **one shared derivation** by a committed test, so the KI-005 class cannot be
      reintroduced. A wrong number is a red build, not a reader's discovery.
- [ ] **The stale triple is corrected everywhere it appears** — `index.mdx` (4 sites, which
      absorbs delivery-001's escalation **E-1**), `reference/overview.md` line 16, and
      `gen-reference.mjs`'s header comments (**KI-003**). **Amended at gate cycle 4:** this
      enumeration was incomplete in both directions — 55 stale counts were found repo-wide
      across 15 files, most of them in `.aid/knowledge/`, because the guard was rooted at
      `site/` and could not see them. "Everywhere it appears" is now enforced by
      `tests/canonical/check-skill-counts.mjs` rather than by an enumeration in this document.
- [ ] **Inbound links route readers to the better page.** The 8 hand-authored links into
      `/reference/skills/` (7 in `guides/pipeline.mdx`, 1 in `reference/overview.md`) point at
      `/skills/`, verified by grep over the built output as well as the source.
- [ ] **The shortcut-engine narrative survives.** `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE
      → APPROVAL-HALT` and its explanation remain on `reference/skills.md`, which is **hollowed
      out, not deleted**. Asserted by content, not by file existence.
- [ ] **The duplicated roster is gone**, and with it **KI-009**: no family table, no `= 0`, no
      `-1 typed forms` anywhere in the generated page.
- [ ] **§7's amendment is honoured and bounded.** `gen-reference.mjs` is edited — which §7 froze
      and Q4 unfroze — but the other three generated pages (`agents.md`, `kb.md`, `settings.md`)
      are byte-unchanged, and the generator stays idempotent.
- [ ] **Deliveries 001–005 still hold.** The full site suite passes, the build is clean, and the
      111 generated skill pages plus their sidecars are byte-unchanged by this delivery.
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-054 | IMPLEMENT | 1 | One shared skill-count derivation + its drift guard; correct KI-003's stale comments |
| task-055 | IMPLEMENT | 2 | Correct the stale roster prose — `index.mdx` (E-1) and `reference/overview.md` |
| task-056 | IMPLEMENT | 2 | Repoint the 8 inbound links from `/reference/skills/` to `/skills/` |
| task-057 | IMPLEMENT | 3 | Hollow out `reference/skills.md` — keep the narrative, shed the roster (closes KI-009) |

Wave 1 must land first: 055 and 056 are corrected *against* 054's derivation rather than by hand.
055 and 056 are file-disjoint apart from `reference/overview.md`, which both touch — 056 changes a
link target on line 16 and 055 rewrites that line's prose, so they are sequenced, not parallel.

## Dependencies

- **Depends on:** delivery-002 (the `/skills/` index and its `Skills` sidebar group are the
  destination readers are repointed to) and delivery-001 (whose `gen-reference.test.mjs` roster
  assertions are the precedent for deriving rather than hand-counting).
- **Amends:** §7, for the second time. The first amendment was also an owner decision at the
  Specify review, when "vitest suites must keep passing unchanged" proved unsatisfiable. This one
  is a deliberate scope addition rather than a correction.

## Sequencing

Continued on `aid/work-001-delivery-005` rather than a new branch. The five delivery branches are
linear and that branch is now pushed and tracking; a sixth branch would fragment a history that is
about to become one pull request. Recorded so the deviation from the per-delivery branch pattern is
deliberate and visible.
