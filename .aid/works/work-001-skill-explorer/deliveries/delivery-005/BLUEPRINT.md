# Delivery BLUEPRINT -- delivery-005: Click-to-open node panel

[!NOTE]
This is the IMMUTABLE DEFINITION of delivery-005. Written once by aid-plan; not a state file —
delivery-005's lifecycle, gate and Q&A live in `deliveries/delivery-005/STATE.md`.

> **Delivery:** delivery-005
> **Work:** work-001-skill-explorer
> **Created:** 2026-07-26

---

## Objective

Let a reader interrogate a chart in place. Selecting a node — by pointer or by keyboard — opens a
panel showing that node's name, its derived label, the verbatim prompt fragment behind it and the
deep link to its `canonical/` lines, without scrolling away to the list beneath the chart. This is
the only browser-side code in the work and the only **Should**: the page is already complete
without it, because delivery-004's static list discharges AC-5 on its own. It is therefore scoped
as additive polish that must be provably unable to damage what it sits on top of.

## Scope

- **feature-006** — a route-gated Starlight `Head` component override composing with the packaged
  default; a build-time JSON projection of delivery-003's sidecar as a data island; a `public/`
  vanilla-ESM controller using delegated `click`/`keydown` on the chart container; the
  `MutationObserver` lifecycle that survives mermaid's async render and its theme re-render; node
  identification via the `aidNode` class hook; the panel as a **disclosure** (not a dialog), with
  keyboard activation, managed focus and `aria-expanded`/`aria-controls`; and one new test-only
  devDependency, `jsdom`.

**Out of scope:** any change to the generated markdown, the charts, or delivery-004's fragment
list — this delivery adds no page bytes beyond the three tags in `<head>`. Playwright is
explicitly **not** adopted as an automated gate.

## Gate Criteria

- [ ] Selecting any node in any chart opens a panel showing that node's verbatim fragment and its
      `canonical/` deep link, and the panel is dismissible.
- [ ] **Keyboard parity.** Nodes are reachable and activatable by keyboard, carry
      `role="button"`, `tabindex="0"`, `aria-expanded` and `aria-controls`, and Escape returns
      focus to the originating node. There is deliberately **no focus trap** — the panel is
      non-modal, and trapping would break the comparison against delivery-004's list that a
      reader is doing.
- [ ] **The Musts underneath are provably undamaged** (feature-006's AC-6.4): delivery-004's
      fragment list remains present, unconditional and functional; no generated page byte changes
      except the three `<head>` tags; and AC-5 still holds with JavaScript unavailable.
- [ ] **All three degradation paths behave**: no JavaScript, JavaScript-before-render, and
      mermaid-failed-to-render. Note that mermaid sets `data-processed` on **failed** renders too,
      so readiness is a three-part predicate — `data-processed` **and** an `<svg>` child **and**
      at least one resolvable node id.
- [ ] **Handlers are bound exactly once per container** and survive a theme re-render without
      duplicating, verified against a synthetic SVG fixture the test builds itself.
- [ ] **The route gate is observable in the emitted HTML** — the script ships on skill detail
      pages and not on the other doc pages, verifiable by grep over the build output.
- [ ] The four manual browser checks are performed and recorded; per feature-006's default the
      three accessibility checks block and the 360 px layout check is an observation.
- [ ] All section-6 quality gates pass

## Tasks

Filled at execution time from the per-task DETAILs, matching the practice used for
deliveries 001–004 where the detail phase left the same table unfilled.

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-045 | CONFIGURE | 1 | `jsdom` test-only devDependency and the DOM test environment |
| task-046 | IMPLEMENT | 1 | Build-time panel logic — gate, projection and island encoding |
| task-047 | IMPLEMENT | 2 | Route-gated `Head` component override |
| task-049 | IMPLEMENT | 2 | Client controller attachment lifecycle and node decoration |
| task-051 | IMPLEMENT | 2 | Panel and focus stylesheet |
| task-048 | IMPLEMENT | 3 | `Head` key in the Starlight `components:` map |
| task-050 | IMPLEMENT | 3 | The node panel — disclosure, focus and key handling |
| task-052 | TEST | 3 | `skill-node-panel.test.ts` — node-environment suite |
| task-053 | TEST | 4 | `skill-node-panel.dom.test.ts` — jsdom lifecycle and ARIA suite |

Execution graph (from the per-task `Depends on` fields): 045 and 046 are file-disjoint and run
in parallel; 047, 049 and 051 each depend only on 046; 048 depends on 047, 050 on 049, and 052
on 046 plus 049; 053 depends on 045, 049, 050 and 051, so it runs last.

## Dependencies

- **Depends on:** delivery-004 (the `blobUrl()` builder, the `#fragment-<nodeId>` anchor, and the
  no-JavaScript floor that lets this delivery be a Should). Also consumes delivery-003's sidecar
  and DOM hooks, and delivery-002's `generatedFrom` field for its route gate.
- **Blocks:** -- (none — this is a leaf)

## Notes

- **This delivery is explicitly droppable at delivery-004's gate**, without replanning anything.
  Nothing depends on it; AC-5 is already discharged; rollback is four deletions and two one-line
  reverts.
- **Two owner decisions must be answered before it starts** — not before delivery-001:
  1. **Is `jsdom` acceptable** as a test-only devDependency? §7 permits new dependencies only
     "where FR-3's node interaction requires it". `site/` has no `vitest.config.*`, so vitest runs
     in the `node` environment with no DOM, and without `jsdom` the delegation lifecycle and every
     ARIA attribute go untested. **If declined, drop this delivery rather than ship its riskiest
     half unverified.**
  2. **Are the manual browser checks blocking, and who runs them?**
- **Promotion candidate.** §10 flags this as a candidate for Should → Must given the work's overall
  High priority, and feature-006's own OQ-2 puts the question to the owner. Nothing structural
  depends on the answer; promoting it changes no dependency and no other BLUEPRINT.
- **This delivery is the third editor of `site/astro.config.mjs`** (risk R1) — one `components:`
  key. It must be sequenced after delivery-002's sidebar edit, never applied concurrently.
- feature-006 registered **KI-011** (`data-processed` means "attempted", not "rendered", which
  contradicts hook H1's wording), **KI-012** (`enableLog` defaults on, so the site logs to every
  visitor's console — proposed as a delivery-002 ride-along), **KI-013** (the component-map comment
  is wrong and reserves slots by a previous work's feature numbers) and **KI-014**
  (`initMermaid()` has no re-entrancy guard, so a fast theme toggle can run two render loops).
  This delivery designs around all four rather than depending on any being fixed.
