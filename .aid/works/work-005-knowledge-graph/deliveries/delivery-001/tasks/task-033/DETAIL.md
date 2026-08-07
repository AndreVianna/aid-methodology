# task-033: The relationship table on its own page, loaded on demand

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-033/STATE.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. Full mandate: `aid-execute/references/state-execute.md § MANDATORY:
> State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** feature-007-graph-view-shell + feature-009-accessible-table-view -> delivery-001 (Wave 3)

> **WHY THIS TASK EXISTS.** On 2026-08-06 the owner removed the relationship table from
> `graph.html` (shipped in `eedacc3d`), because this repo's own extraction enumerated
> thousands of candidate relationships and a table that size dominates the page it exists
> to support. That removal has a cost which was stated to the owner and accepted: the
> canvas is deliberately **visual-only** and builds no DOM proxy layer, so the table was
> the **conforming alternate version** carrying WCAG AA for the whole artifact. With it
> gone, `graph.html` has no accessible equivalent, and feature-009's acceptance criteria
> plus the table halves of AC-9 and AC-15 do not hold for that page.
>
> **This task is what makes that acceptable rather than a regression.** The owner's
> resolution, in their words: *"We will construct a second html page that will show the
> relationships table with load on demand (infinit scroll). With no graph. The table will
> allow filtering. This way we do not loos the alternative view without overloading any of
> the pages with excessive data (the graph with the table and the table with the graph)."*
>
> So this is not a nice-to-have companion page. Until it ships, the graph view has no
> conforming alternative at all.

**Depends on:** task-016 (the table rendering), task-013 (the shell)

**Scope:**

**A. A second page, table only.**
- A new rendered page beside `graph.html`, carrying the relationship table and **no graph**:
  no canvas, no drawing rendering in its bundle, none of the viewport controls.
- **Reuse `graph-table.js`. Do not fork it.** It already implements the ten columns, the
  sort contract, the row-header semantics, the unlisted-nodes region and the accessibility
  properties feature-009 was reviewed against. A second copy would drift from the suite
  that tests it (`test-graph-table-view.sh` reads the file directly from disk).
- The mechanism to compose a page without a given rendering **already exists and is
  proven**: `graph-controls.js` mounts each rendering behind `if (mountXFn)`, and
  `resolveMount` yields null when the module is absent from the bundle.
  `build-graph-src.mjs`'s `OWNER_EXCLUDES_TABLE_RENDERING` is the graph page's use of the
  same seam, and `eedacc3d` proved the shell tolerates the absence cleanly -- zero console
  errors, zero warnings, controls and live regions intact. Compose this page the same way,
  with the canvas excluded instead of the table.

**B. Load on demand -- and the trap in it.**
- Render a first window of rows, then extend it as the reader reaches the end.
- **A SCROLL-ONLY TRIGGER IS NOT KEYBOARD OPERABLE, and on this page that is
  disqualifying**, because this page exists to be the accessible surface. A keyboard or
  screen-reader user who cannot fire the loading gesture cannot reach row 201, which
  defeats the entire purpose of building it.
  So: load on scroll **and** provide a real, focusable **"Load more"** button that does
  exactly the same thing. The button is the contract; the scroll handler is a convenience
  on top of it. Never scroll-only.
- Announce the change. The page already owns a polite live region -- extending the table
  by 200 rows with no announcement leaves a screen-reader user with no evidence anything
  happened. Say how many are now shown out of how many.
- State the totals honestly and always: "showing N of M". A reader must never be able to
  mistake a window for the whole set -- that is the failure mode a paged table introduces,
  and it is worse here than a slow page, because it silently understates the data.

**C. Filtering.**
- The filter axes already exist in the shell's manifest and already drive the same store:
  relationship category, node kind, provenance, the orphan toggle and the text search.
  **Reuse them.** Do not author a second filter widget on any field -- feature-009's own
  design notes reject a per-column input for exactly that reason.
- Filtering must apply to the **whole set, not the loaded window.** A filter that only
  searches the 200 rows already rendered is a bug that will look like a working feature on
  a small fixture and mislead on a real one. Assert this against a set larger than one
  window, or the assertion proves nothing.
- Re-filtering resets the window to the first page and re-announces the totals.

**D. The two pages must link to each other. This is not decoration.**
- WCAG's conforming-alternate-version mechanism requires that the alternative be
  **reachable from the non-conforming page**. A table page that exists but cannot be
  reached from `graph.html` does not restore anything.
- So: `graph.html` links to this page, prominently and near the graph, in words that say
  what it is (a text equivalent of every relationship) rather than "view table".
  This page links back.
- The graph page's placeholder text was reworded in `eedacc3d` to stop promising a table
  that was not there. Once this page exists, **that text should point at it** -- it is the
  message a reader sees when the drawing surface cannot run, which is exactly when they
  most need the alternative.

**E. What must NOT regress.**
- `graph-table.js`'s existing suite. `test-graph-table-view.sh` reads the module directly
  from disk; keep it green, and extend it for the windowing and the filter-over-full-set
  behaviour rather than leaving them untested.
- The ten-column contract count. Ten is normative -- `TBL_COLUMNS.length` is read, never
  written as a literal -- and this task adds no column.
- The single-module-scope rule. Every declaration this task adds to a view file must carry
  the file's own prefix; a duplicated top-level name is a SyntaxError that stops the whole
  page, not a shadowed variable.
- The page must not reintroduce the defects just fixed on the graph page: no author
  `display` beating a `hidden` attribute, no sticky rule landing on a row header, no
  header offset measured against the wrong scroll container. Read `graph-css.css`'s
  relationship-table block before writing new table CSS -- it documents all three.

**Out of scope:**
- The graph page's own remaining layout work (viewport width, the graph sitting below the
  fold, the right-button gestures). That is task-032.
- Restoring the table to `graph.html`. The owner's decision stands; this task provides the
  alternative rather than reversing it.
- Any change to the extraction pipeline or to `relationships.md`'s format.

**Acceptance:**
1. The new page renders from the real pipeline, shows the table with no graph, and its
   bundle contains no drawing rendering.
2. A first window renders; the "Load more" button extends it; the button is reachable and
   operable **by keyboard alone**, verified as such and not merely present in the DOM.
3. A filter applied with only the first window rendered returns matches from **outside**
   that window -- verified against a fixture larger than one window.
4. "Showing N of M" is correct at first paint, after loading more, and after filtering.
5. `graph.html` links here and this page links back.
6. `test-graph-table-view.sh` is green, and covers the windowing and the
   filter-over-full-set property with assertions that go red when the behaviour is broken.
