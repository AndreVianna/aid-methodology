# Delivery BLUEPRINT -- delivery-004: Verbatim fragments and `canonical/` deep links

[!NOTE]
This is the IMMUTABLE DEFINITION of delivery-004. Written once by aid-plan; not a state file —
delivery-004's lifecycle, gate and Q&A live in `deliveries/delivery-004/STATE.md`.

> **Delivery:** delivery-004
> **Work:** work-001-skill-explorer
> **Created:** 2026-07-26

---

## Objective

Make the charts answerable to their source. A derived node label is an interpretation and can be
wrong in a way verbatim text cannot, so every node gains the exact prompt text that composes that
step, rendered beneath the chart in chart order, together with a deep link to the precise lines
in `canonical/`. The fragment is byte-exact — it passes through the page unaltered — and a
recorded range that no longer matches its file fails the build rather than shipping a link that
points at the wrong thing. This delivery is where the work has delivered everything §9 asks for:
with it, AC-5 is discharged and the reader is never stuck with only an interpretation.

## Scope

- **feature-005** — the `## Source fragments` appender registered in `BODY_APPENDERS`; the
  dynamically sized tilde-fence emission that keeps fragments byte-verbatim; the mandatory
  `title=` on every fence; the deep-link builder reusing the existing `GITHUB_BLOB_BASE`
  constant with `#L<a>-L<b>` anchors pinned to `master`; the six per-node verification checks;
  and the whole-corpus AC-5 vitest sweep.
- **The AC-7 comprehension spot-check**, performed and recorded at this delivery's gate.

**Out of scope:** the interactive panel (delivery-005). Chart derivation is delivery-003's and
is consumed unchanged here.

## Gate Criteria

- [ ] **AC-5 — Verbatim reachability.** Every node in every chart — authored-flow **and** doorway
      — exposes its verbatim prompt fragment and a source deep link that resolves to real lines
      in `canonical/`. Verified by a whole-corpus vitest sweep that enumerates directories from
      disk and carries no literal count.
- [ ] **Byte-exactness holds through rendering.** A fragment survives the page unaltered:
      backticks, pipes, angle brackets, braces and a complete fenced block all pass through. The
      fence is wide enough for the fragment's own tilde runs, and **every fence carries a
      `title=`**, which is what prevents Expressive Code's file-name-comment scan from silently
      deleting a heading line — measured at 4 corpus lines if omitted.
- [ ] **Range verification throws, not warns.** A recorded range that does not exist in its cited
      file, or an excerpt that no longer equals its slice, fails the build with a named guard.
- [ ] **The list works without JavaScript.** It is static markdown with no script and no client
      directive, and it does not depend on the rendered SVG — which is what keeps AC-5 true under
      KI-004's no-JS degradation.
- [ ] **AC-7 — comprehension spot-check (NON-BLOCKING).** Two pages chosen by shape — one
      authored-flow, one doorway — judged once by a human, with the verdict recorded in the work
      folder. A Fail files a ticket; it does **not** block this gate.
- [ ] Deliveries 001–003 still hold: AC-1, AC-2, AC-3, AC-4, AC-6 and AC-8 pass unchanged.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ — `aid-detail` fills this table.

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-003 — an acceptance dependency rather than a code one. feature-005 is
  shape-blind and does not read feature-004's document, but its AC-5 sweep calls `buildFlowChart`
  on every directory under `canonical/skills/`, which cannot return a chart for a delegating
  skill until feature-004's extractors are dispatched. **Nobody should "optimise" this delivery
  ahead of delivery-003 on the strength of the shape-blindness claim.**
- **Blocks:** delivery-005 (the `blobUrl()` builder, the `#fragment-<nodeId>` anchor, and the
  no-JavaScript floor that lets delivery-005 be a Should)

## Notes

- **This is the completion point for the Musts.** Everything REQUIREMENTS §9 asks for is
  discharged when this gate passes; delivery-005 is additive.
- **feature-005 OQ-1 is open and non-blocking:** the fragment list repeats across the delegating
  majority, since those pages share the engine chart. The default is to render it in full, per
  FR-6's standalone-page promise. Alternatives — collapsing behind `<details>`, or
  `data-pagefind-ignore` on doorway pages — are each a one-line change. Revisit on a measured
  Pagefind index size or a search-quality complaint, not speculatively.
- **feature-005 OQ-2 is open:** who performs the AC-7 spot-check. It is a staffing question and
  does not affect verifiability.
- **feature-005 OQ-3 belongs to delivery-001**, not here: whether `docs.yml`'s path filter should
  gain `canonical/**`, since today a `canonical/`-only commit triggers no docs build and deployed
  anchors stay one generation stale. Deciding it while `docs.yml` is already open avoids
  reopening a shipped artifact.
- **KI-007 is a KB correction, deferred:** `test-landscape.md`'s CI-lane row for `docs.yml`
  misstates its triggers in both directions — it claims a `release: published` trigger that does
  not exist and omits the `pull_request` gate that does. Delivery-001 makes that row further
  wrong. Fix it in the KB update at ship.
