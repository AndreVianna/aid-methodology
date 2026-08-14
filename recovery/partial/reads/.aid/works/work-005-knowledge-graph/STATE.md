## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Q1

- **Category:** Requirements
- **Impact:** Low
- **Status:** Resolved 2026-07-28 — **`Strength` dropped.** `Provenance` carries trust and layout
  hops convey distance, so a per-row number would duplicate the picture while being unreproducible.
  The table was eight columns at the time of this resolution. **Superseded 2026-07-29 (Q14): the
  table is now TEN columns** — `Source Kind` and `Target Kind` were added by owner decision. Dropping
  `Strength` still stands and is not reinstated. Recorded at REQUIREMENTS.md §5.2.
- **Original status:** Deferred
- **Context:** The `relationships.md` schema keeps a `Strength` column as TBD. `Provenance`
  (`declared`/`derived`/`inferred`) was adopted to carry trust, which was `Strength`'s main
  candidate meaning; what remains for `Strength` is an optional confidence or distance measure.
  Owner chose to retain the column as a possibility rather than settle or drop it now. Raised
  during /aid-describe work-005 interview.
- **Suggested:** Decide at /aid-specify: either an optional numeric weight used only for graph
  layout tuning, or drop the column. Graph distance is already conveyed by layout hops, so the
  bar for keeping it is a use the layout cannot express.

### Q2

- **Category:** Architecture
- **Impact:** High
- **Status:** Deferred to RESEARCH — **scope widened 2026-07-28.** The owner dropped all three
  packaging restrictions (FR-16 rewritten, C-1 withdrawn), so the option space is no longer bounded
  by self-containment: multi-file output, CDN delivery, and a real build step with third-party
  dependencies are all admissible, at any payload size. SVG, Canvas, and WebGL renderers are all in
  scope. The research optimises for interaction quality and legibility, not packaging purity.
- **Context:** The rendering approach is undecided. It was originally bounded by a single-file
  self-containment constraint; that constraint is withdrawn. The remaining tension is that