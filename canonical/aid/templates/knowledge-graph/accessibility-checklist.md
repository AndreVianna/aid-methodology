# Accessibility Checklist — Graph Addendum (WCAG AA)

Read this **after** `../knowledge-summary/accessibility-checklist.md`, not instead of it. Every
item in that file applies to `graph.html`, because the graph reuses the same shell, the same
stylesheet and the same lightbox. This file adds only what the graph introduces, and it states
which surface each item binds — because the graph has one surface that cannot satisfy a
DOM-level check at all, and asserting one against it would be a check that can only ever fail.

Items marked **[auto]** are verifiable by a script. Items marked **[manual]** are for the human
visual gate. Items marked **[contract]** are properties of the view model rather than of the
page, and are asserted headless.

---

## 0. Which surface each existing check binds

| Existing check | Surface it binds | Why |
|---|---|---|
| HTML validity, landmarks, ARIA on the dialog, focus trap, reduced-motion rule, visible focus | **the page structure and the table rendering** | These are questions about elements, and every element on this page is a real element |
| anchor-link and relative-link resolution | **the page** | Both read the emitted file |
| offline render, no-diagram-engine | **the page** | Both read the emitted file |
| contrast | **the declared custom properties** | The checker is a text extractor with no browser; see §4 |
| the authored-visual gate | **the legend's inline diagram** | A drawing canvas matches none of that gate's selectors, so the reserved live-surface exclusion is a recorded no-op |
| **the drawing surface itself** | **nothing** | It carries a graphical role and a text alternative and no other markup. It is visual-only, and this page's conformance rests on the table rendering as the equivalent alternative |

That last row is the one worth stating plainly: **no DOM-level accessibility assertion is made
against the drawing surface.** Not because it is exempt, but because the conformance route runs
through a peer rendering that is always present, and a bitmap has no accessibility tree to
assert over. What replaces the assertion is the obligation in §2 — that the table rendering is
present, complete and reached first.

---

## 1. Two live regions, and no more

- **[auto]** Exactly one `aria-live="polite"` region. It carries the lens summary and the drawn
  counts, written **once per lens change** and never per frame.
- **[auto]** Exactly one `role="alert"` region, present in the markup **from load and empty**. A
  live region has to exist before its content is injected in order to announce reliably, so it
  is authored empty rather than inserted whole.
- **[auto]** The alert region is written **at most once per load**. It carries whichever
  load-time failure occurred — an unreadable table, or a disagreement with the recorded gap
  list — and the two are **mutually exclusive**, because an unreadable table mounts neither
  rendering and so the comparison never runs. That is why the count holds without a guard.
- **[auto]** The drawing surface's text alternative is **not** a live region and is not announced
  on change. It is an accessible name, and re-announcing it on every lens change would talk over
  the polite region that exists for that.
- **[manual]** A third live region is a defect even if each is individually correct: two regions
  with disjoint purposes stay checkable, and a third makes "which region said that" unanswerable.

## 2. The two renderings are peers

- **[auto]** Both are present in the DOM at all times and **neither is nested inside the other**.
  They are siblings — that is the structural form of "peer rendering".
- **[auto]** **DOM order is table-first.** The visual order is graph-then-table on wide viewports
  and table-then-graph below the breakpoint, and both are set in the stylesheet. So the keyboard
  reaches the surface that works everywhere before it reaches the one that may not.
- **[auto]** Neither region is ever hidden, collapsed or `disabled`.
- **[auto]** The table rendering mounts **first and unconditionally**, before the drawing
  rendering is even looked for.
- **[manual]** With the drawing module absent, or with no usable graphics context, the page is
  still **complete** — a stated explanation in place of the surface, and every relationship
  present as text. If that reads as a broken page rather than as a complete one, the explanation
  is wrong.
- **[auto]** A link from the graph region to the table region, so a keyboard reader can pass the
  drawing surface rather than tab through whatever it contains.

## 3. Colour is never the sole carrier

- **[auto]** **Node kind by colour AND shape** — seven colours, seven shapes, one per kind.
- **[auto]** **Relationship category by colour AND line style**, with the (colour, style) pair
  unique across all fourteen categories and **no two categories sharing a colour sharing a line
  style**.
- **[auto]** **Direction by an arrowhead**, and a relationship reading the same in both directions
  has **no arrowhead** — the absence is itself the signal, so direction is not carried by a
  colour or a weight.
- **[auto]** Every relationship name is present as **text** in the table rendering, always, and
  on hover or selection in the graph.
- **[auto]** The legend states **every glyph, every colour and every line style in words**, not
  only shows them.
- **[auto]** An emphasis class maps to shape, weight, outline or opacity — **never to colour
  alone**. The projection returns *classes*; each surface decides what to do with one.
- **[manual]** Four line styles cannot distinguish fourteen categories, and the design does not
  claim they can. What must hold at the visual gate is only the weaker, stated property:
  distinctness *within* a colour. If two categories sharing a colour are hard to tell apart at
  the sizes the density and zoom controls reach, the answer is filtering, which is a required
  feature for this reason.

## 4. Contrast — and one live defect in the checker

- **[auto]** Every node-kind and category colour is declared as a **CSS custom property** whose
  name matches the checker's charset — **lowercase letters and hyphens only, no digits, no
  underscore, no uppercase**. A numbered token would be silently unchecked.
- **[auto]** **No colour literal appears in drawing code.** A colour a drawing layer passes to
  its graphics API as a value is never looked for by the checker, which produces neither a
  warning nor a failure: the check simply never runs. The projection therefore carries token
  names, and the drawing code resolves one to a value at draw time.
- **[auto]** The palette's two blocks use selectors that **do not already occur** in the page, and
  the dark block occurs **exactly once and never inside a print block**. The checker resolves the
  *first* block matching a selector, and the print rules re-declare every dark token with light
  values in order to force a light print rendering.
- **[auto]** The graph's pairs target **3:1**, not 4.5:1. Node and edge marks are graphical
  objects that carry meaning, which is the threshold that applies to them; the page's existing
  text pairs stay at 4.5:1 and are unchanged.
- **[manual, and this one matters]** **Do not take the checker's word for the dark theme.** As it
  stands, its block lookup is built without a global flag, so the dark lookup resolves the
  *first* block whose selector matches — which in the assembled page is a two-line block
  declaring no custom properties at all. It therefore harvests nothing and re-checks the light
  values under the dark heading. Until that is parameterised, **the dark palette's ratios must be
  computed independently and recorded**, and a green run of the checker is not evidence about the
  dark theme.

## 5. Every control is a real element, and the set is complete

- **[auto]** Every control is a **native focusable element** — no drawn control, no synthetic
  role over a non-interactive element.
- **[auto]** The control set is asserted **complete against the data**, not merely reachable. The
  question is not "can a keyboard reach the controls that exist" but "is the full set of controls
  the requirements name actually present" — because a control painted on the drawing surface is
  absent from the set a keyboard drive walks, so it passes the first question while failing the
  standard.
- **[auto]** Every enumerable filter axis offers **every value in the loaded vocabulary**, derived
  from the data the model already holds. A vocabulary that grows cannot leave a value unoffered.
- **[auto]** **No control is ever `disabled` or hidden by a preset**, on any viewport, including
  the viewport controls when no drawing rendering is present.
- **[auto]** The control panel's contents **stay in the DOM when the panel is collapsed** below
  the mobile breakpoint. A panel that unmounted them would fail the completeness check on a
  narrow viewport while passing on a wide one.
- **[auto]** Every group the fold governs carries exactly one focusable disclosure, **before and
  after** an expansion, and no other group carries one. Presence is keyed on the count the fold
  *governs* — never on the count currently folded away, which expanding drives to zero.
- **[auto]** Each filter axis is a real `<fieldset>` with a real `<legend>`, so the axis name is
  the group name in the accessibility tree.
- **[auto]** Every control has a real `<label for>`.
- **[contract]** Selecting a node and opening its artifact are **separate**, and Open is a real
  button — which is the only reason the open gesture is reachable at all, a double click having
  no keyboard equivalent.
- **[auto]** Node **dragging** is excluded, and the exclusion is the standard's own
  path-dependent one: dragging repositions a mark and conveys nothing a keyboard reader is
  denied. Every other gesture has a keyboard equivalent, including zoom and pan.

## 6. Motion and system preferences

- **[auto]** The shared reduced-motion rule is inherited, not forked.
- **[contract]** The two system preferences — reduced motion and forced colours — are detected
  **by the shell** and published on the store, with a getter, a setter and a subscription. That
  is **one route** both renderings read. They are not fields of the control state and not fields
  of the projection: a preference is not a function of the lens, and the projection is pure with
  no page access, so a field on either would make a preference the product of a projection it is
  not.
- **[contract]** A mid-session flip of either preference **reprojects nothing** — no revision
  bump, no lens notification, and no membership or emphasis decided. The same control state
  projects an identical result under both values of both preferences.
- **[contract]** No rendering queries a media feature for itself. One detector, one route.
- **[manual]** With reduced motion set, the graph is **settled** — a still picture, reached
  without a visible simulation. That is the fallback, not the default.
- **[manual]** With forced colours active, the page is remapped and the drawing surface is not,
  because a remap applies to colours declared on elements and not to pixels in a bitmap. The
  drawing rendering must therefore drop the palette **entirely** in that mode and rely on shape,
  line style and filtering. A half-remapped picture — some marks recoloured, some not — is worse
  than a monochrome one.

## 7. Names, labels and truncation

- **[contract]** The **accessible name is never the shortened form.** A shortened label exists for
  drawing and for a collapsed table cell; no screen-reader user is handed a truncated identifier.
- **[contract]** A shortened label is computed **once at load over the full node set** and does
  not change when a filter or a lens changes. Resolved over the visible set instead, one node
  would be called two things in one session.
- **[contract]** The text filter matches the **stored** name and the identifier, never the
  shortened label.
- **[contract]** A node with no recorded relationship at all carries that fact **in its
  accessible name**, as text. It is text and not a badge, so it survives forced colours and
  reaches the announced summary — where a purely visual "this mark has no lines attached" would
  reach nobody using a screen reader.

## 8. Focus and scrolling

- **[auto]** The shared visible-focus rule is inherited, not forked.
- **[auto]** The top bar is sticky, so focusable targets carry a scroll margin sized to it and a
  focused element is not scrolled underneath it.
- **[auto]** Exactly **one** focus trap on the page — the reused lightbox. Node and row detail is
  an inline expanding region and not a modal, so there is no second trap to keep correct.
- **[manual]** Tab order follows a useful granularity: the **aggregates** are tab stops — the lens
  bar, the controls, each group, the selected node — and the table carries the raw rows. One tab
  stop per node would be hundreds deep at Overview density and would say almost nothing.

## 9. What this addendum deliberately does not cover

- **The frame-rate floor and the settled render.** Both belong to the drawing rendering. This
  shell hosts the loop and publishes the preference; it measures nothing and gates nothing.
- **The node-count warning.** The threshold is a measured figure that has not been taken, and its
  carrier deliberately holds the key with no value. Nothing here invents one: with no declared
  threshold there is no comparison to make and no warning to decide, and the run that emits the
  page is where that decision belongs.
- **The table rendering's own internals** — its headers, its sort affordances, its row semantics.
  Those belong to the table rendering, which owns them and their checks.
