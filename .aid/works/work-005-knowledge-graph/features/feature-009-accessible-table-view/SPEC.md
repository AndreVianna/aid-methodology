# Accessible Table View

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-30 | **Authored fresh against the frozen 001–007 spine** (STATE.md Q24 item 6, Q26 § Fresh authoring). Supersedes the pre-decision draft of 2026-07-28 in its entirety: that draft was written against the file-only node model and against the **eight**-column shape §5.2's two `Kind` columns voided on 2026-07-29, and it carried the two defect classes fresh authoring exists to remove — a clause keyed on a proxy (`int:` for the gap class) and a load-bearing citation to a withdrawn figure (A-5 bounding the row count). Nothing was edited into shape; the old file was read once as a checklist of concerns. **Owner decisions implemented:** the table is **one row per edge** with a dedicated region for nodes no listed row names, because an enumerated node with no relationship row would otherwise be invisible in a per-edge table — the FR-19/FR-20 worst case; **delivery-001's research is invalidated**, so no measured quantity and no bench size is asserted anywhere and every target names FR-18's replacement research as its owner; the canvas is **visual-only** and this table is the **conforming alternate version** that carries WCAG AA (Q9, NFR-2); FR-13's Coverage domains are `{document, concept}` and `Kind = source-artifact` (Q21 item 1); FR-14a's `web-page` / external `image` target is **`./external-sources.md`** (Q21 item 2), reached through feature-007's Open control, which this feature does not duplicate; and AC-6a is named accurately as feature-008's frame-rate criterion rather than claimed here. **Consumed as frozen:** feature-007's `ViewModel`, `LensState`, store API and § API Contracts consumer rules; feature-003's ten columns and D7 row order. **Two corrections the draft's model made invisible:** it emitted per-column filter inputs, which would break feature-007 D8 assertion 2's `data-control` bijection and put two widgets on one field; and it selected the zero-row region by `degree === 0`, which misses a node the canvas draws whose every row `edgeFold` marks `'collapsed'` | /aid-specify |
| 2026-07-30 | **First review cycle closed: seven findings, one of them a missing contract rather than a wrong sentence.** The select gesture's **third clause was unowned** — feature-007 D7a (its SPEC.md:1046–1047) and FR-14a (`REQUIREMENTS.md`:470–471) both have a select *show the node's rows in the table view*, this SPEC quoted that sentence twice while implementing only its emphasis and Impact-depth clauses, and `data-row` is the only node-to-`<tr>` tie, so no other surface could take it. § Feature Flow step 6 now specifies the reveal from the `ViewModel` and not from `LensState`: the target is the id `nodeEmphasis` marks `'focus'`, already fold-resolved and keyed over `visibleNodes` alone, so it is always a node this region names — with the sort-order case (the first row of the *current* order), the all-`'collapsed'` case and the unlisted-region case stated, and **AC-S8**/**TV18** as its hooks. The other six correct what a sentence claimed, three of them in the *assert only what the platform provides* class this surface exists to hold: the tab-stop enumeration and TV04's "exactly" omitted the caption's own `./relationships.md` and unlisted-region anchors, both focusable and both in the tab order, so TV04 failed against a conforming implementation; "`Enter` and `Space` operate every control" was false for the first stop in its own list, an `<a href>`, which the APG Link pattern activates on `Enter` alone — all SC 2.1.1 asks; and AC-S7/TV15's "accessible name **equals** `nodeLabels`" is unachievable while the same `Name` cell holds its select `<button>` and `role=cell` names from contents, so it is restated as **containment**, feature-007's AC-S8 being the achievable form. The unlisted region put the `nodeEmphasis` badge in the `Name` cell where D3 and the Component breakdown both put it in the **Id** cell; AC-S2's "then the order changes" is false for a uniform column, D2's tie-break being `edge.row` ascending in **both** directions, so it now states D2's comparator and TV10 carries where the directions differ and where they coincide; and NFR-5's carrier row claimed hidden **nodes** are counted in a caption that states only `counts.edges` and `counts.hiddenEdges` — editorial under Q26, the operative Caption row having been unambiguous, so the row now names removal as the carrier and cites where `counts.hiddenNodes` is reported (feature-007's SPEC.md:643). **Each class was swept rather than its instance fixed:** the empty state names the control panel in words rather than linking it (feature-007 fixes no id for that panel, and a third in-page `href` would depend on one); the checklist's `<label for>`/`aria-label` item is scoped to form **inputs**, which this feature emits none of; § Responsive's second accessible-name equality is corrected; AC-S5 gains **TV11** as thinning's hook and TV09 names AC-S1's canvas-absent case as the buildable one; and TV14 adds `scroll-behavior: smooth` to its CSS grep. No measured quantity, no new colour token, and no new `ViewModel` field | /aid-specify |
| 2026-07-30 | **Second review cycle closed: six findings, three of them inside the reveal contract the first cycle's fix introduced** — the measured pattern on this work being that a fix pass's new prose carries the next cycle's findings. **The reveal's trigger could fail to exist.** `nodeEmphasis` gives an id **one** class and, **as the upstream then stood**, fixed **no** precedence between `'focus'` and a coverage class or `'dimmed'`, so a select made under Coverage or Provenance had two candidate classes and one slot — and **AC-S8**, keyed on the mark, went **vacuous**, so TV18 passed green while the reveal, the `selected` badge and NFR-5's text carrier for the selection were all absent. Step 6 now states the precedence this feature assumes — the resolved focused id carries `'focus'`, the reading feature-007's own **GV22** instantiates (its :1816) — AC-S8 is keyed on the **gesture** rather than on the mark, TV18 asserts the mark under every `emphasis` value, and **Open Item 5** routes the upstream silence on Open Item 1's shape: owner feature-007, class mechanism, stated and hooked, not blocking, and **no** change invented on a frozen SPEC's behalf. **`RowOrder.focusRevealed` had no clearing rule**, so select A → a preset setting `focus.nodeId: null` (feature-007 D6a, its :815–816) → select A again was not a "new" id and the reveal stayed suppressed; the field is now carried across the per-revision rebuild and **cleared** by any rebuild finding no marked id — the one rule under which both readings of its lifetime agree — with TV18 asserting the re-arm. And **"instantaneous" was hooked only to TV14's CSS grep**: `scrollIntoView` declares no CSS property, and the reused file's own `html { scroll-behavior: smooth }` (`component-css.css`:67) would have animated the reveal, so the scroll now passes an explicit `behavior: 'instant'` and TV14 greps that call too. **Each class was swept.** The vacuity audit — *would an implementation that does nothing at all pass this row?* — ran over all eighteen `TV` rows and closed four more (TV06 quantified over rendered cells and over an empty file, TV08 over emitted controls, TV14 over re-emitted rows, TV16 over emitted regions) plus TV02's zero-row fixture; the two-table scoping sweep corrected TV05's `aria-sort` universal, § Screen-reader's same universal, TV02's `<tbody>` count, TV06's cell-provenance routes and TV15's `Name` cell; the NFR-5 row's `counts.hiddenNodes` attribution now agrees with the line it cites (feature-007:643 names that field's readers, not a per-field obligation on each); the single-route sweep extended TV05 to the implicitly live roles and TV13 to every colour-literal form, since one negative clause greps only the routes it names; `orderedFor` gained the write rule the missing `focusRevealed` one exposed as a class; the precedence's own converse cost — a selected gap endpoint reading `selected` in place of its gap badge, one class per id — is stated in the Coverage row and asserted by TV07 rather than left for the next cycle; and § Figures adopts feature-006's fourth class, "an enumeration made on the spot and reproducible from the cited source" (its SPEC.md:1409–1414), which this SPEC uses throughout. Restatements another section already owned were cut throughout to pay for the new contract text. No measured quantity, no new colour token, no new `ViewModel` field, and no edit to a frozen SPEC | /aid-specify |
| 2026-07-30 | **Upstream re-sweep after feature-007's scoped freeze exception (Q25) — bookkeeping, no design reopened.** feature-007 was reopened for four seams and re-gated; its Open Item 13 (its :1985–1990) records that its decisions answer **this SPEC's Open Item 5 in place** and that a re-sweep is owed. **The one substantive change is provenance, not content.** D4's `nodeEmphasis` row now states the composition as a **total precedence over all five values with `'focus'` first** (its :630) and **GV28** asserts all four steps (its :1822) — which is the precedence § Feature Flow step 6 had stated as *this feature's assumption* and hooked from this side. So step 6, **AC-S8** and the Coverage row attribute it to the **upstream contract** instead, `AC-S5`/`AC-S8`/**TV18** are confirmed rather than corrected, and **Open Item 5 closes as answered**, keeping its number per feature-007's own rule (its :1834–1837). **The other three seams touch nothing here, and that is the honest answer rather than a skipped check:** the store's new `getPreferences()` / `setPreferences()` / `subscribePreferences()` route is unused because this feature reads **no** preference — its reduced-motion and forced-colours clauses consume the reused `component-css.css` `@media` blocks (:658, :684) and nothing else, and its own motion claim is unconditional (`behavior: 'instant'`), which is stronger than a preference-gated one; the **viewport handle** is canvas-side and this region emits no zoom control; and the **withdrawn density exemption** leaves the Coverage row's zero-row guarantee resting solely on that preset's `density: 1`, which is the scope it was already stated at, while AC-15 binds on the gap **set** that D10 computes once per load and never thins. **One clause gained a citation that strengthens it:** the Impact row's "dimmed, not dropped" now names its route — the **endpoints'** `nodeEmphasis`, selection assigning no edge class at all (its `edgeEmphasis` row, :631) — which is what D3's mapping already meant by taking `'dimmed'` from either map. **Every line-numbered citation into feature-007 was re-verified on disk and re-pointed** — feature-007 grew by the **+25 lines** its own entry states, so every anchor below its first insertion moved: fourteen sites held a stale anchor, of which **ten were re-pointed in place over five anchors** (`:621`→`:630`, `:634`→`:643`, `:805–806`→`:815–816`, `:1036–1037`→`:1046–1047`, `:1795`→`:1816`), **three retired** with Open Item 5, and **one de-numbered** rather than re-pointed, because the line that now answers it would contradict the sentence recording the silence. `GV01`, `GV17`, `GV22` and `GV25` keep their numbers and concerns, so every `GV` citation here was re-checked for meaning as well as position. `TV01`–`TV18` keep their numbers and concerns; no measured quantity, no new colour token, no new `ViewModel` field, no new `TV` row, and no edit outside this file. Delta **−2 lines** | /aid-specify |
| 2026-08-06 | **task-034 review cycle closed: eight findings, two fixed by the owner directly in `graph-controls.js`/`graph-css.css` and six closed here.** The owner's two: `restoreHiddenSelection`'s "hide-everything" notice was written into `[data-conflicts]` and then unconditionally erased by `reportConflicts`'s own `clear(host)` on the same element eight lines later, so the graph page reported nothing for a suppressed selection — split into `restoreHiddenSelection` (writes the lens early) and `reportSuppressedHiddenSelection` (reports after `reportConflicts`); and the two new tables inherited the un-scoped `.tbl th` sticky rule with no override, reproducing the sticky-row-header defect "what must not regress" names — `graph-css.css`'s corrective rule now names `[data-files-table]`/`[data-concepts-table]` too. **The six closed here:** Open Item 6 is now **ANSWERED** — it described the graph-page restore as absent from a file this task does not edit, but the call was already made in the same commit, and the SPEC now says so; the NFR-5 colour table's "Node kind" row, missed by the D3 sweep, now states the relocation task-034 actually made; `resolveHiddenSelection` now **deduplicates** a stored selection before measuring it against "hides everything" (a repeated id previously inflated the raw count past the model's own and could suppress a selection that did not actually cover every node — reproduced against the live 976-node file); `tblRenderFilesTree`/`tblRenderConcepts` now give every checkbox, toggle and row a `scroll-margin-top` over both sticky layers, which they had carried none of at all; the "unattached document" fallback in `tblBuildFilesTree` — kept for the completeness guarantee even against a malformed artifact — is now exercised by a hand-built, deliberately malformed fixture rather than left untested; and three stale "ten column(s)" labels (two in `graph-view-dom.mjs`'s own `CLASSES` array, one in `test-graph-table-view.sh`'s `TV05b`) are swept to six. **Five new test ids**: **TFC15**–**TFC17** (`graph-table-files-check.mjs`, cited by TV21/TV24/TV25) and **GV29** (`graph-view-dom.mjs`) — the last drives a FULL `mountShell()` boot with a real, `localStorage`-seeded hide-everything selection and asserts the notice survives to be visible, which is what the first version of the restore/report split needed and did not have, and which is why the erasure passed every existing check (all of which only ever drove `resolveHiddenSelection` in isolation) | task-034 fix cycle |
| 2026-08-06 | **task-034: the ten-column Relations table becomes six, node kind and node name move to two new tables.** The owner read the real, 3550-row `relationships.md` and measured that 86% of the cells this table drew were the same node property repeated on every relationship row naming it. D3 is revised: `TBL_COLUMNS` drops `Source Kind`, `Source Name`, `Target Kind`, `Target Name`, keeping `Source Id`, `Target Id`, `S2T Relation`, `T2S Relation`, `Provenance`, `Observation` — **six is now the contract count Q19's exemption protects**, and the change log records the reduction as deliberate rather than accidental. The select control (FR-14a, feature-007 D7a) relocates from the (now-removed) Name cell to the Id cell every row still carries — the same mechanism, one native control per endpoint, not a new gesture. **A new § "The Files tree, the Concepts table, and the checkbox-hide axis"** adds the node half this reduction needs a home for: every node in the model (not the lens-filtered `visibleNodes`) partitions exhaustively into the Concepts table (`kind === 'concept'`, flat) and the Files tree (everything else, `section`/`fact` nested under their `document`, folders by repository path) — an exhaustive rule over the closed kind enum, so the partition cannot silently miss a kind. A new `LensState` field, `filters.hiddenIds` (graph-model.js §§ 3, 9 — fifteen fields now, not fourteen), is the checkbox-hide axis DETAIL.md's owner decided on: a VIEW filter, excluded at node admission exactly like a kind filter, structurally unable to reach `verifyCoverage` (which runs once at load, before any lens exists) — so `graphModel.integrity` and `viewModel.coverageGaps` are provably identical before and after any hide, which is the measured reason (32 of 319 KB claims losing their only backing artifact under a blanket data-level exclusion) the owner rejected dropping a node from the data instead. Persisted per page-directory (`hiddenSelectionKey`, `readHiddenSelection`, `writeHiddenSelection`, `resolveHiddenSelection` — graph-model.js's own one documented exception to "touches no storage"), restored once at mount, with an unknown id dropped and a hide-everything selection suppressed and reported rather than silently applied. **What is NOT retired:** the unlisted-nodes region (D4, AC-S4, TV12) stays exactly as it was — it is a property of the Relations table's own lens-filtered `visibleNodes`, orthogonal to the new tables' unfiltered inventory, and there is no cost to removing it that this task needs to pay. **What is NOT here:** restoring the persisted selection into the GRAPH page's own initial `LensState` needs a change inside `graph-controls.js`'s `mountShell`/`createStore` call, a frozen, concurrently-owned file this task does not edit — recorded as **Open Item 6**, owner feature-007/the work owner, class mechanism. Nine new test ids, **TFC01–TFC12** plus **TFC14** (`tests/canonical/graph-table-files-check.mjs`, task-033's own self-contained-fixture precedent), close acceptance items 1 and 3–6; item 2 (the `relationships.md`/coverage/gap-badge invariance) is TFC04's own subject and item 7 (the suite stays green) is this change's own verification. TV05/TV06/TV13/TV15 are revised in place rather than retired, since their CRITERIA survive the slimming even where their subject cell moved | task-034 |

## Source

- REQUIREMENTS.md §6.1 — **NFR-1** (WCAG AA, the bar `kb.html` holds), **NFR-2** (two first-class
  renderings; the accessible table view is **sortable, filterable, keyboard-navigable, screen-reader
  friendly**, a **peer** view and the conforming alternate version), **NFR-3** (every preset lens applies
  to **both** renderings; "Coverage" in table form lists exactly the gap rows the graph highlights),
  **NFR-5** (colour is never the sole carrier; the relationship **name** is always readable as text here),
  **NFR-6** (*widened* — every interactive gesture has a keyboard equivalent, and **this view provides the
  keyboard-operable route to select and open**, which is what lets the canvas stay visual-only)
- REQUIREMENTS.md §5 — **FR-3** (the table is the **single input**, so the peer rendering adds no second
  data path), **FR-17** (runtime JS is mandatory for this view)
- REQUIREMENTS.md §5.2 / §5.3 — the **ten**-column table and the closed `Kind` enum; the per-kind id
  grammars, whose prefix is the one carrier that answers *where a node comes from* for every kind,
  `image` included — the one kind whose `Kind` cell cannot answer it (§5.2's branching case)
- REQUIREMENTS.md §5.6 — **FR-13** (the four lenses, with the Coverage domains as amended 2026-07-29 by
  owner decision), **FR-14** (controls remain available at all times), **FR-14a** (the control surface:
  the filter axes it names — relationship category, node kind, provenance — **at minimum**, plus the
  orphan toggle; filters that **compose**; `density` as view density; the **two
  node gestures**, and the `./external-sources.md` open target)
- REQUIREMENTS.md §4 — In Scope ("an accessible table view as a peer rendering of the graph"); and Out of
  Scope, of which two bind here: **no degraded rendering mode** for very large graphs (the ceiling is
  measured, documented and warned about — NFR-8), and **no dashboard reachability** (C-8)
- REQUIREMENTS.md §9 — **AC-7** (table side), **AC-8a parts 1–2** (both renderings), **AC-9** (the table view is
  keyboard-navigable and screen-reader usable; the DOM-level checks apply to page structure and the table
  view, **not** the canvas), **AC-10** (renders from `relationships.md` alone), **AC-15** (table side),
  **AC-21** (every named control keyboard-operable, asserted **complete in the DOM**)
- STATE.md `## Cross-phase Q&A` — **Q9** (the canvas is visual-only; AA rests on this table), **Q11** (the
  relationship name is on hover in the graph and always text here), **Q13** (concept merge, so a concept's
  rows are its mentions), **Q14** (the `Kind` columns and the ten-column consequence), **Q17** with
  **Q21**'s refinement (*a prefix is correct when the clause is about where an id comes from, wrong when it
  is about what class a node belongs to*), **Q19** (a count that **is** the contract stays a numeral; cite
  every other set), **Q20 (loader sync)** (an inbound item on a gated SPEC is a pending reopen),
  **Q20 (A-5 figure)** (no bench figure is stated), **Q23** (read every occurrence; search the path the
  artifact cites), **Q25** (re-sweep a draft when its upstream is re-gated), **Q26** (fresh authoring;
  mechanism reopens, editorial batches; the 001–007 **freeze**)
- Gated inputs consumed as **fixed contracts, never re-litigated**: **feature-007** (`GraphModel`,
  `LensState`, `ViewModel`, `project()`, the store, its § API Contracts consumer rules, `CONTROL_MANIFEST`, the
  palette, the two live regions, and § Validator surface — the authority for AC-9's check-to-surface
  mapping); **feature-003** (D1's ten columns and header literal, D1a's `Kind` enum, D5's display names,
  **D7's row order and normalisation**, `rel_row_key`); **feature-001** (D5's category set, D5a's colour
  assignment as feature-007 D5b adopts it); **feature-004** (the enumerated node set); **feature-005**
  (what the table contains); **feature-006** (D6's `kb_gaps` entry shape and D6a's lens/ledger asymmetry)

**Dependency position.** Blocked by **feature-007** only — the shell, the projection and the control
surface. **Not blocked by feature-002**: nothing below changes with the rendering research's verdict, and
that independence is the reason the table is a separate feature. It can be built while the research runs,
and it gives the WCAG AA bar a named owner instead of leaving it a footnote on a drawing feature.

**Shared acceptance criteria — mutual obligations; no owner may consider one met alone.** **AC-7**,
**AC-8a** and **AC-21** are shared with feature-007 (which owns the criteria) and with feature-008 (the
canvas). **AC-9** is shared three ways: its table-view half is owned here, its check-to-surface mapping is
feature-007's (§ Validator surface), and its settled-graph clause is feature-008's. **AC-15**'s table side
is owned here, with feature-006 the ledger owner. **AC-6a is not shared and is not this feature's**: it is
the frame-rate criterion, measured at the research-derived bench against NFR-7's floor (feature-007 Open
Item 13, owner feature-008), and this SPEC asserts no part of it — see § Figures.

## Description

The same relationships, presented as a real table on the page: one row per relationship, sorted from the
column headers, navigable from the keyboard, and usable with a screen reader.

This is not a fallback hidden behind the drawing. It is a peer view, and since the canvas became
visual-only it is the surface that carries the accessibility standard for the whole artifact — a drawing
canvas cannot hold a screen-reader experience convincingly, and a table can, mechanically checkable at
that. When the question is "which rows are unbacked", a list also simply beats a picture.

Every preset lens and every filter applies here exactly as it applies to the graph, and that holds because
the table reads the one projection the shell computes rather than interpreting the lens a second time.
Asking for Coverage lists precisely the gap rows the graph highlights, not an approximation of them.
Filtering reaches this table in the same tick, but the *controls* live in one place — the shell's panel —
because a second set of widgets over the same state is how two surfaces start disagreeing.

Two facts about the shape of the file drive the design. The table is one row per **edge**, so a node that
participates in no listed row has no row of its own — and the sharpest Knowledge Base defect this whole
work exists to surface is exactly that: an artifact the project considers significant with nothing said
about it anywhere. Such a node therefore gets a region of its own inside this view, so the table can never
silently omit something the graph draws. And the file carries each endpoint's **kind** in its own column,
so a defined concept, a document section and a claim with a checkable source read as three different
things in a cell even though all three identifiers begin the same way.

Meaning here is never carried by colour alone, and by construction rather than by discipline: kind,
provenance and both readings of every relationship are literal columns, and every id carries its prefix.

## User Stories

- As a **maintainer/architect** using a screen reader, I want the relationships as a real, navigable table
  rather than only as a drawing, so that the artifact is usable to me at all.
- As a **KB reviewer**, I want the gap rows listed and labelled by which class they belong to, so that I
  can work through them systematically and see which have a ledger counterpart.
- As a **maintainer/architect**, I want every preset lens and every filter to change this table exactly as
  it changes the graph, so that switching surface never changes what I am looking at.
- As a **maintainer/architect** working from the keyboard, I want to reach and operate the table without a
  mouse, and to skip past it in one keystroke, so that neither navigation nor escape is gated on pointing.
- As a **KB reviewer**, I want an enumerated artifact with no recorded relationship to appear here even
  though the table is one row per relationship, so that the worst gap is not the one the view drops.

## Priority

Should

*In scope and required by §4 and §6.1; ranked Should rather than Must only because §10 states explicitly
that `relationships.md` and the gap ledger ship usefully with no view at all. This is a schedule-risk
ranking, not a statement that accessibility is optional — within the view the accessibility bar is
mandatory, and since Q9 made the canvas visual-only this surface is where it is met.*

## Acceptance Criteria

- [ ] **AC-7** *(table side; feature-007 owns the criterion — mutual obligation)*: Given the generated
      view, when each of the four preset lenses is applied in turn, then each visibly changes the table
      rendering as well as the graph. *Hook: **TV01**.*
- [ ] **AC-8a parts 1–2** *(shared with feature-007 and feature-008; **part 3, the eight-colour palette
      cap, is feature-007's** and is no part of this surface)*: Given the generated view, then the table's
      listed row set responds to a category filter exactly as the drawn edge set does, and a filter
      composes with the active lens rather than resetting it. *Hook: **TV02**.*
- [ ] **AC-9** *(table half owned here; the mapping is feature-007's § Validator surface and the
      settled-graph clause is feature-008's — mutual obligation)*: Given `graph.html`, when the existing
      structural and a11y checks are run, then the table view satisfies every check bound to it, is
      keyboard-navigable, and is screen-reader usable at WCAG AA. *Hooks: **TV03** (checks), **TV04**
      (keyboard), **TV05** (screen-reader semantics), **TV16** (the checklist's 200 % zoom and
      confined-scroll item), **TV17** (an emptied table states why rather than reading as broken).*
- [ ] **AC-10** *(table side)*: Given the table, when its content is examined, then every cell is taken
      from the `ViewModel` the shell projected from `relationships.md`, with no second data path and no
      re-derivation of membership. *Hook: **TV06**.*
- [ ] **AC-15** *(table side; feature-006 is the ledger owner — mutual obligation)*: Given the Coverage
      lens applied to the table, when the listed rows are compared with the gap ledger, then the table
      lists exactly the `Kind = source-artifact` gaps the ledger carries, and labels the lens-only
      `kb-unbacked` class distinctly so a reader can tell which has a ledger counterpart. *Hook: **TV07**.*
- [ ] **AC-21** *(shared with feature-007 and feature-008)*: Given every control this feature emits, when
      each is driven by keyboard input only, then each is operable; and none carries `data-control`, so
      feature-007's manifest↔DOM bijection stays true with this region in the page. *Hook: **TV08**.*

Spec-authored criteria, numbered under the `AC-S<n>` scheme feature-003 introduced and offered to the
sibling SPECs. They are **this feature's** numbers; cite them elsewhere as `feature-009 AC-S<n>`, the way
feature-007 cites "feature-003's own AC-S2".

- [ ] **AC-S1** *(NFR-2, peer not fallback)*: Given the generated page, then the table region is a
      **sibling** of the graph region and **first in DOM order**, and it mounts unconditionally — so a
      build where the canvas module is absent or WebGL is unavailable still yields a complete, usable
      artifact. *Hook: **TV09**.*
- [ ] **AC-S2** *(NFR-2, sortable)*: Given the table, when a column header is activated, then the order is
      exactly D2's comparator over that column, `aria-sort` reflects it on exactly that header, a third
      activation returns to the file's own order, and the listed row **set** is unchanged by any of it.
      *Hook: **TV10**, which states where the two directions differ and where D2's tie-break coincides.*
- [ ] **AC-S3** *(NFR-3, the mechanism)*: Given any `LensState`, then the table's row order is a
      **permutation** of the rows `edgeFold` does not mark `'collapsed'` — never an addition, a removal or
      a re-selection. *Hook: **TV11**.*
- [ ] **AC-S4** *(NFR-2 and FR-19/FR-20, the worst-case gap)*: Given any `LensState`, then every node in
      `visibleNodes` is named somewhere in the table region — in a listed row, or in the unlisted-nodes
      region — so no node the graph draws is absent from the table. *Hook: **TV12**.*
- [ ] **AC-S5** *(NFR-5)*: Given the table, when node kind, provenance, emphasis, sort state and thinning
      are examined, then each is carried by text or by a non-colour channel, and no new colour token is
      declared. *Hooks: **TV13**; thinning's carrier is removal rather than fading, which is **TV11**.*
- [ ] **AC-S6** *(AC-9's reduced-motion half, from this side)*: Given the table, then nothing this feature
      drives animates — sorting, filtering and lens changes re-emit rows with no transition, and step 6's
      reveal scrolls instantaneously by `behavior: 'instant'`, declaring motion nowhere. *Hook: **TV14**.*
- [ ] **AC-S7** *(feature-007's **AC-S8**, table half)*: Given a node whose display name exceeds the label
      budget, then the shortened form sits only inside `aria-hidden="true"` and so reaches no accessibility
      tree, and the cell's accessible name **contains** the full `nodeLabels` value — asserted as containment
      rather than equality because `role=cell` names from contents and a Files-tree Name cell may also hold a
      collapse toggle `<button>` of its own (task-034 relocates this cell to the Files tree, D3; the
      Relations table's own Id cell held the select `<button>` this clause originally cited, and now holds it
      still — see D3's own relocation note). A LEAF row's Name cell, holding no other focusable content,
      achieves equality as the tighter case containment already covers; a folder or document row's does not,
      and containment is the property this criterion asks for either way. *Hook: **TV15**.*
- [ ] **AC-S8** *(FR-14a and feature-007 D7a — the reveal clause)*: Given a select of any node this region
      names, then `nodeEmphasis` marks that node `'focus'` (feature-007 D4's precedence, step 1) and the
      table reveals it — the first row of the current order naming it, else its unlisted-region row —
      moving no focus and animating nothing; and a re-selection after a focus-clearing preset reveals it
      again. *Hook: **TV18**.*

---

## Technical Specification

> **Renderer-independent by construction.** Nothing below changes with feature-002's verdict. The canvas is
> visual-only (Q9) and AA conformance rests on this table as the conforming alternate version (NFR-2), so
> this feature's obligations survive even total WebGL failure — the load-order consequence is step 1's.
>
> **This feature interprets no lens.** `project()` interprets the lens exactly once (feature-007 D3). Every
> statement below reads the `ViewModel` and re-derives nothing from it: an edge's endpoints from `edgeFold`,
> the drawn counts from `counts`, accessible names from `nodeLabels`, a group's state — if it is ever needed
> — from `groups[].expanded` verbatim rather than from `foldable` or `foldedInto`. The one `LensState` field
> it reads is `sort`, its own renderer-private carve-out.

### The table-view boundary — what this feature does not own

Stated first so no reader infers scope this SPEC never claimed. Each item is another owner's, named.

| Not owned here | Owner | Why it matters that this feature stays out |
|---|---|---|
| **Any filter control** | feature-007 (the control panel, built from `CONTROL_MANIFEST`) | Every filterable column maps onto a filter axis the shell already offers — the two `Kind` columns onto `filters.kinds`, the two relation columns onto `filters.categories` via `Edge.category`, `Provenance` onto `filters.provenance`, and the four id/name columns onto `filters.text`. So a per-column input would be a **second widget on one field**: it would break feature-007 D8 assertion 2's `data-control` bijection, or, unlabelled, become a shadow control that can disagree with the panel. NFR-2's "filterable" is satisfied because those axes are **shared** fields — filtering the panel removes rows here in the same tick (feature-007 § Feature Flow step 7), which is exactly what NFR-3 asks for |
| **The Open gesture** | feature-007 D7b (a real `<button>` in the selected-node detail region) | FR-14a's per-kind targets, including `./external-sources.md` for a `web-page` or external `image`, are resolved by `store.openTarget(nodeId)`. This feature's row controls perform FR-14a's **other** gesture, `select`, and duplicating Open per row would break the same bijection |
| **The group expand/collapse disclosure** | feature-007 (its § UI Specs "Group headers" row, which carries **no** delegation note where the graph-region and table-region rows carry one) | Its **GV22** asserts **exactly one** focusable `data-group-toggle` per group whose `foldable` is non-zero. Two surfaces each rendering one would make that false, so this feature renders **none** and derives no expansion state; it reads `groups[].expanded` only where it needs to know a group's state |
| **The two live regions** | feature-007 (§ Feature Flow step 8: `graph-controls.js` writes `announcement`) | The page has exactly two live regions and no more. This feature writes to **neither** and creates no third; see § Screen-reader behaviour for what carries a sort change instead |
| **The legend, the coverage panel, the footer, `<noscript>`** | feature-007 § UI Specs | FR-9a's coverage notes reach the reader through feature-007's panel. FR-17's honest answer to a script-free reader is `relationships.md` itself, which the shell's `<noscript>` links |
| **The palette, and every colour value** | feature-007 D5 | This feature declares **no** colour token, so `contrast-check.mjs`'s existing pair list is untouched |
| **Any measured quantity** | FR-18's replacement research (NFR-7, NFR-8) | See § Figures |

### Data Model

**No persistent schema and no data model of its own.** The table renders feature-007's `ViewModel` and
holds one piece of private, non-authoritative state.

| Structure | Fields | Lifetime | Authority |
|---|---|---|---|
| `RowOrder` | `order: Edge[]`, `orderedFor: integer`, `focusRevealed: string \| null` | `order` and `orderedFor` are rebuilt together when `viewModel.revision` changes, `orderedFor` taking the revision the order was built for. `focusRevealed` **survives** that rebuild, is written when step 6's reveal fires, and is **reset to `null` by any rebuild that finds no `'focus'`-marked id** — both rules, because one without the other either scrolls twice for one selection or suppresses a re-selection after a preset clears `focus.nodeId` (feature-007 D6a, its :815–816) | **Private.** Nothing outside this module reads it |

**One rebuild trigger, not two.** `sort` is a `LensState` field (feature-007 D3), so a sort change goes
through `store.setLens` and produces a new `revision` like any other change. Caching **the order** against
`revision` alone is therefore total; a second key on `sort` would be dead.

#### D1. `RowOrder.order` is a permutation, never a selection

`order` contains exactly the `viewModel.visibleEdges` rows whose `edgeFold` entry is **not** `'collapsed'`
— consumer rule 7 — reordered and nothing else. The table may not add, drop, or re-derive a row:
membership belongs to `project()` — the single restriction that makes the Coverage listing exact rather
than approximate, and this feature's half of NFR-3 and AC-7 (**AC-S3**).

#### D2. The sort contract — the value space of `sort`, and why the order is total

feature-007 fixes `sort` as `{column, direction}`, table-only, initial `{column: 'row', direction: 'asc'}`
(its D6a and GV25). Its **value space is this feature's to define**, and is:

- `column` — the literal `'row'`, or one token per column of D3's own six (task-034; originally feature-003
  D1's ten, back when this table's columns and the file's were identical — they no longer are). `'row'` is
  the file's own order, so an unsorted table reads exactly as `relationships.md` reads (feature-003 D7).
- `direction` — `'asc'` or `'desc'`.

**The comparator.** Primary key is the sorted column's **value** — never its visible text, which the
responsive collapse can shorten (§ Responsive behaviour), so a narrow viewport cannot reorder rows.
Compared **by code unit** (`<` / `>`), never with `localeCompare`; `'desc'` reverses the primary comparison
only. Tie-break is `edge.row` **ascending** in both directions. Three properties follow, and each is
load-bearing:

- **The order is total.** `row` is the 1-based table row index, unique per row by construction, so no two
  rows compare equal. Order is therefore a function of the row set and the sort key alone. That is the same
  *shape* of argument feature-003 D7 makes for the emitted order — there from `rel_row_key`'s uniqueness
  under **V5**, here from an index's.
- **The order does not vary with the reader.** `localeCompare` would reorder rows by browser locale, and
  `int:` ids carry exact on-disk case (feature-003 D2b). This is the same reason feature-003 D7 pins
  `LC_ALL=C` for every sort it writes (its SPEC.md:1328–1333), applied to the browser's only equivalent.
- **Sorting cannot change membership.** It reorders `RowOrder.order` and writes nothing but `sort`, which
  feature-007 D3 fixes as renderer-private and forbids from affecting presence or emphasis.

#### D3. Six columns, node kind and node name moved off the row (task-034)

**Revised by task-034, 2026-08-06 — the number itself changes, which the change log records as a deliberate
break of Q19's own "ten is normative" statement, not an accidental drift.** The owner read the real,
3550-row `relationships.md` this table renders and found that 86% of the cells it drew were the same fact
restated: a node's kind and name repeat on every relationship row naming it, so a project with 976 distinct
nodes and 3550 relationship rows was carrying 14200 node-property cells to say what 2008 would say once. The
fix task-034 makes is the SPEC's own: a **node table** (two of them — see § The Files tree and the Concepts
table, added by this task) plus an **edge table** says the same thing once, so this table becomes the edge
table alone. **The ten-column count is therefore reduced to six, and stays a contract count**: `Source Id`,
`Target Id`, `S2T Relation`, `T2S Relation`, `Provenance`, `Observation` — feature-003 D1's own order, with
its two `Kind` columns and two `Name` columns removed. `TBL_COLUMNS.length` is still read, never written as
a literal, so the new count cannot drift by accident any more than the old one could.

**Where node kind and node name went, so a reader of this file's history is not left to guess.** Every node's
own kind, name, provenance and coverage state now has exactly one home — its row in the Files tree or the
Concepts table (§ 13 below) — instead of one appearance per relationship row that names it. A reader who
wants to know a node's kind or its full name reads that row once; this table answers a different question,
"what relates to what and how", and answers it with nothing repeated.

**The select control moves from the (now-removed) Name cell to the Id cell it shares a row with.** Every row
still carries an Id cell per endpoint — Source Id and Target Id both survive the slimming — so FR-14a's
select gesture (feature-007 D7a) keeps exactly the mechanism it had: one native control per endpoint, one
per row's Source Id cell and one per row's Target Id cell, writing the same `{'focus.nodeId': id}` patch.
This is a relocation, not a new gesture, and every consumer rule this SPEC states about it (§ Feature Flow
step 6, **AC-S8**) is unchanged in substance.

**No seventh column is added.** The two emphasis channels land on the elements they are keyed over, and the
mapping is **total over both value spaces** so no class can render as nothing:

| Source | Value | Rendering |
|---|---|---|
| `nodeEmphasis[id]` | `kb-unbacked` / `artifact-undocumented` / `focus` | a text badge — `no source` / `no KB doc` / `selected` — inside **that endpoint's** Id cell |
| `edgeEmphasis[key]` | `chain` | a text badge `chain` inside the `S2T Relation` cell, which is the reading the chain is on |
| either | `dimmed` | `data-emphasis="dimmed"` on the `<tr>` and visual de-emphasis, **and nothing else** — see § Colour for why that carries no information of its own |
| either | `normal` | nothing |

Every listed row has an `edgeEmphasis` entry by construction, because that map is keyed over exactly the
rows `edgeFold` does not mark `'collapsed'` (feature-007 D4) — the same set D1 lists. The file row index is
carried as `data-row`. So the table stays a rendering of the file rather than a re-shaped derivative of it.

**Where each cell comes from.** The two Id cells name the endpoints **as `edgeFold` resolves them** — the
ids the row is "drawn between and listed as" (feature-007 D4). The relation, provenance and observation
cells come from the `Edge` record.

**What faithfulness this claims, and where it stops.** Under `grouping: 'none'` — `INITIAL_LENS`, and every
non-folding dimension — `edgeFold` holds identity pairs, so the six cell **values** are the file's row
verbatim (its Source Id, Target Id, both relation readings, Provenance and Observation columns; Kind and
Name are no longer among the values this table states at all). Under `grouping: 'document'` a row whose
endpoint is a `section` or `fact` is listed against its document head instead, which is the fold's accepted
cost (feature-007 D6c clause 2), and `data-row` is what still ties the listed row to the file row it came
from. The claim is stated at the state where it holds rather than asserted generally.

#### D4. The unlisted-nodes set — derived, with no new `ViewModel` field

The set is `visibleNodes` minus every id named by a non-`'collapsed'` entry of `edgeFold`. Three
populations reach it, and enumerating them is what shows the derivation is the right one rather than a
convenient one:

1. **Zero-row `source-artifact` nodes** materialised from `kb_gaps` (feature-007 D10). `degree === 0`, and
   `nodeLabels` already ends `— no recorded relationships`. This is FR-19/FR-20's sharpest case and the
   reason the region exists.
2. **A head whose every incident row the fold collapsed.** Under `grouping: 'document'` a document whose
   only rows reach its own `section` and `fact` members has every one of them `'collapsed'`, so the canvas
   draws it and no listed row names it. **Selecting on `degree === 0` misses this population entirely** —
   `degree` is computed at load over the full edge set and is 1 or more here — which is why the derivation
   is over `edgeFold` and not over `degree`.
3. **The focused node when it has no surviving edges**, which `visibleNodes` admits by contract
   (feature-007 D4).

A node whose rows were merely *filtered* out is not in this set and needs no handling: it is not an
endpoint of any `visibleEdges` row, so `visibleNodes` does not contain it unless it is also (1) or (3).

**What the region is not.** It is not gated on the Coverage lens — these nodes are a fact about the
projection, not a lens result. It is not exempt from the filters: a reader who filtered `source-artifact`
nodes out meant it, and `project()` has already applied that to `visibleNodes`. And it carries no severity
and no new badge: an entry's emphasis is `nodeEmphasis`'s, unchanged.

**One absence stated rather than discovered.** An enumerated `image` or `web-page` node with **no**
relationship row cannot appear here either, because it never reaches `GraphModel.nodes`: `kb_gaps` is
scoped to `Kind = source-artifact` and feature-006's Open Item 7 declines to widen it. Such a node is
reported only in FR-9a's coverage-note counts, which feature-007's coverage panel renders. This feature
invents no carrier for it — see Open Item 2.

### Feature Flow

Client-side, at page load and on every store notification. No server, no request, no second fetch.

1. **Mount.** `mountTable(container, store)` renders from `store.getViewModel()` and subscribes. The shell
   mounts this module **first and unconditionally** (feature-007 § Feature Flow step 6), which is the
   load-order form of NFR-2 and of **AC-S1**.
2. **Order.** Build `RowOrder` per D1 and D2.
3. **Render the main table.** One `<tr>` per ordered row: `<th scope="row">` for `Source Id` and nine
   `<td>`, plus the emphasis badges, `data-emphasis` and `data-row`. **Every row is rendered** — no
   pagination and no virtualisation, because a partially-present table breaks screen-reader row counts,
   the browser's own find-in-page, and printing. What bounds the rendered size is the reader's own
   `density` and filter controls, which is where FR-14a puts it; the size question itself is § Figures'.
4. **Render the unlisted-nodes region** when D4's set is non-empty, and emit the caption's link to it in
   the same step, so the `href`/`id` pair is created together and **L1** can never dangle.
5. **Sort.** A header button cycles `ascending → descending → none`, writing
   `store.setLens({sort: {column, direction}})`; `none` writes `{sort: {column: 'row', direction: 'asc'}}`.
   Rows are re-emitted in place with no transition.
6. **Select.** A select control writes the single dotted key `{'focus.nodeId': id}` through
   `store.setLens`. `LensState` is a **flat** record with dotted field names — feature-007 D3 says so, and
   D6a's preset patches are written the same way (`focus.depth: 2`) — so the shallow merge leaves
   `focus.depth` untouched, and the graph's Impact neighbourhood moves to this node at the depth the reader
   already chose. **The reveal is that gesture's third clause** (feature-007 D7a, its SPEC.md:1046–1047;
   FR-14a, `REQUIREMENTS.md`:470–471 — *show the node's rows in the table view*), and `data-row` is the only
   node-to-`<tr>` tie, so no other surface can perform it. The target is the id `nodeEmphasis` marks
   `'focus'` — resolved through the fold already (feature-007 D6c clause 2) and keyed over `visibleNodes`
   alone (its :630), so it is always a node this region names. **That trigger is an upstream guarantee, not
   this feature's assumption:** the same D4 row makes the node axis a **total precedence** whose first step
   is the fold-resolved `focus.nodeId`, `'focus'` whatever else applies, and its **GV28** asserts all four
   steps (its :1822); **TV18** asserts the mark here as well, under every `emphasis` value. What is
   revealed is the **first row of `RowOrder.order`** naming it — so the reveal follows the reader's sort
   order rather than the file's — or, where every row naming it is `'collapsed'` or it names none, its
   unlisted-region row. The scroll is the **minimal** one clearing both sticky layers (§ Keyboard reach) and
   is instantaneous by an explicit `behavior: 'instant'` — the reused `html` rule is
   `scroll-behavior: smooth` (`component-css.css`:67), so omitting the option would animate it (**AC-S6**).
   It moves **no** focus — **AC-S8** and **TV18** here; Open Item 1's keystroke question stays feature-007's.
7. **Reconcile.** On every notification, rebuild from the new `ViewModel`: row set and order, `aria-sort`,
   the badges, the `<caption>` text, the unlisted region, and — only where a **new** id is `'focus'`-marked,
   which `RowOrder.focusRevealed` records and which a rebuild finding **no** marked id clears (Data Model),
   so a select repeated after a focus-clearing preset reveals again — step 6's reveal. **No component-local
   copy of anything.** The only two states this module displays are the projection and `sort`, both taken
   from the notification, so nothing here can go stale relative to the store. Nothing is persisted; the
   theme stays on the shared `aid-dashboard-theme` key the shell already uses.

### Layers & Components

Authored once under `canonical/` and rendered to every host profile by the existing generator (**C-2**);
the rendered copies are build output and are never hand-edited (`.aid/knowledge/module-map.md`
§ Invariants, its "Single source of truth" rule at :271–273).

```
canonical/aid/templates/knowledge-graph/
├── graph-table.js    # THIS FEATURE: ordering, rendering, sort/select wiring, ARIA state
├── graph-model.js    # feature-007 — consumed, never modified
└── graph-css.css     # feature-007's file; this feature adds table-only rules and no colour token
```

**This file is inside feature-007's browser boundary, and GV01 binds it.** `graph-table.js` declares **no
top-level `import`** and contains no `fetch`, `XMLHttpRequest` or dynamic `import(`: the view's files are
concatenated into one `<script type="module">` in manifest order behind `coverage-predicate.mjs`, so they
reference `graph-model.js`'s exports by name (feature-007 D10 § How each runtime reaches it). That is also
AC-10's greppable half from this side.

**Reused verbatim, not reimplemented (FR-12, C-4, AC-17).** This feature adds no assembler, no validator,
and no table CSS from scratch. Every line number below was read on disk at the `canonical/` path cited.

| Reused | What it already provides |
|---|---|
| `canonical/aid/templates/knowledge-summary/component-css.css` | `.tbl-wrap`, the horizontally scrollable bordered container (:322); `table.tbl` (:323) with the `.tbl th, .tbl td` padding and border rules (:328); `.tbl th` as a **sticky** header (the rule at :334–343, its `position: sticky; top: 0` at :341–342); row hover (:345); the `.badge-*` classes for `ok`/`warn`/`err`/`info`/`purple` (:225–229); `.sr-only` (:671) |
| the same file's `:focus-visible` rule (:645) | The focus ring **A5** asserts; every control here is a native focusable element |
| the same file's `@media (prefers-reduced-motion: reduce)` (:658) | What **A4** asserts. This feature animates nothing, so it adds no motion for the block to suppress |
| the same file's `@media (forced-colors: active)` (:684) | Keeps `.badge` borders and `forced-color-adjust: none` under Windows High Contrast (:688–691), so the badge text survives with its boundary intact |
| the same file's `@media print` (:575) | A usable printed form of the table with no extra work |
| `canonical/aid/scripts/summarize/validate-html-output.sh` | H1, A1, A4, A5, L1, L2 against the assembled page |
| `canonical/aid/scripts/summarize/contrast-check.mjs` | Its existing pair list (:97–108, all at `target: 4.5`) covers every badge pair this feature uses |
| `canonical/aid/templates/knowledge-summary/accessibility-checklist.md` | The AA checklist this artifact is measured against; feature-007's graph addendum extends it rather than replacing it |

### UI Specs

#### Component breakdown

| Component | Markup | Contract |
|---|---|---|
| Table region | The `<section aria-label="Relationship table">` feature-007's Component breakdown fixes | This feature emits its contents. The region's accessible name stays feature-007's `aria-label` |
| Section heading | `<h2>` inside that region | At the same level as the graph region's, so the page lists both as peers — the visible form of NFR-2. Its text is **not** a repeat of the region's `aria-label`, so entering the region does not announce the same words twice |
| Skip-past-table link | `<a href="#graph-table-end">Skip relationship table</a>`, first element in the region | Its target `<span id="graph-table-end" tabindex="-1">` is emitted after **both** tables, so the link skips all tabular content. It is **not** the shell's `class="skip-link"` element, which `validate-html-output.sh`:248 asserts and feature-007 owns |
| Caption | `<caption>` on the main table | States `counts.edges` listed and `counts.hiddenEdges` hidden — the **drawn** counts, so the caption and the shell's header can never disagree — plus `viewModel.lensSummary`, a link to `./relationships.md`, and, when D4's set is non-empty, a link to the unlisted region. Screen readers read it on table entry, so the reader learns the scope before the data |
| Header row | `<thead>` with `<th scope="col">` per column, each wrapping a `<button>` | The button is the sort control; `aria-sort` lives on the `<th scope="col">` and on no other `<th>` |
| Body rows | `<tbody>` with one `<tr data-emphasis data-row>` per ordered row | Six cells (task-034): `<th scope="row">` for `Source Id`, `<td>` for the other five |
| Emphasis badges | `.badge-*` spans placed by D3's total mapping — `nodeEmphasis` in the endpoint's Id cell, `edgeEmphasis`'s `chain` in the `S2T Relation` cell | Each carries its meaning as **text** — `no source`, `no KB doc`, `selected`, `chain` — never as colour alone |
| Row select controls | `<button data-row-select>` in **each** of the `Source Id` and `Target Id` cells (task-034 relocates it here — the `Source Name`/`Target Name` cells it used to sit in no longer exist), its accessible name `Select ` + that endpoint's `nodeLabels` value | FR-14a's single-click gesture (feature-007 D7a's keyboard equivalent, "on the node's row in the table view"); D7a's third clause, the reveal, is § Feature Flow step 6's. **One per endpoint, not one per row:** feature-003 D7 normalises every row so `Source Id ≤ Target Id`, so a node whose id sorts last in every row it appears on would be **unselectable** from a source-only control. Deliberately **not** `data-control`: this DOM is per projection while `CONTROL_MANIFEST` is built once at load, so a manifest entry per row would falsify feature-007 D8 assertion 2 the moment a filter removed a row — the same reason feature-007's own group disclosure carries a distinct marker instead |
| Empty state | One `<tr>` with a single `<td colspan="6">` naming `viewModel.lensSummary` and naming the control panel **in words** | A blank `<tbody>` is indistinguishable from a broken one. It quotes `lensSummary` rather than inspecting `filters`, because consumer rule 1 permits this module only `sort`. Not a link: feature-007 fixes no id for that panel, so an in-page `href` here would depend on one and add a third **L1** input |
| Unlisted-nodes region | A nested `<section>` with an `<h3>`, holding a three-column `<table class="tbl">`, emitted only when D4's set is non-empty | See below. Kept as-is by task-034 (not retired): it is a property of the Relations table's own lens-filtered `visibleNodes`, orthogonal to the Files tree/Concepts table's UNFILTERED inventory (§ 13), and removing it would cost nothing this task needs to cost |

#### The unlisted-nodes region

- **Three columns**, `Id`, `Kind` and `Name`, with `Id` as `<th scope="row">` — the main table's
  convention. The triple is deliberately the one feature-003 D7 normalises as a unit, so a node reads the
  same way here as it does in a listed row, and `Kind` keeps node type carried as **text** (NFR-5).
  The `nodeEmphasis` badge sits in the **`Id`** cell, D3's placement — here the row header.
- **Its own `<caption>`**, stating the count and the meaning: nodes the graph draws that no listed
  relationship row names — an enumerated artifact with no recorded relationship at all (FR-19, FR-20), or
  a node whose rows are folded away. The caption explains the region on entry rather than leaving it to
  read as a stray table.
- **No second encoding to keep in sync.** The "no recorded relationships" fact is already appended to
  `nodeLabels` by `project()` (feature-007 D10), which the `Name` column renders, so the graph and this
  region name such a node identically.
- **The same select control** as the main table — one per row, since a row here is one node — so choosing
  one moves the graph's Impact neighbourhood to it and the reader learns in words that it has no
  neighbours.
- **Reuses `table.tbl` and `.badge-*`.** It is a real `<table>` with `<caption>`, `<thead>` and
  `<th scope>`, so **H1** holds by the same construction as the main table, and it adds no colour token.

**Forcing these nodes into the main table was considered and rejected.** A row with a real
`(Id, Kind, Name)` triple and **seven** em-dashes claims a relationship the file does not contain, breaks
the caption's count of relationships, and costs a screen-reader user seven empty-cell announcements first.

#### Which AC-9 checks this surface answers

feature-007 § Validator surface is the authority for the check-to-surface mapping AC-9 demands. Of the
assertions it binds to "page structure and the table view", these are the ones this feature satisfies:

| Check | How the table satisfies it |
|---|---|
| **H1** (validity — `tidy`, else `npx html-validate`, else a regex fallback) | A real `<table>` with `<caption>`, `<thead>`, `<tbody>` and `<th scope>` is valid by construction. A div-grid imitation is where validity failures come from |
| **A1** (semantic landmarks) | Satisfied by the shell: A1's sub-checks are `lang`, `header role="banner"`, `main`, `nav`, `footer` and `title` (`validate-html-output.sh`:184–189), all of them feature-007's. This region contributes the `<section>` inside `<main>` |
| **A4** / **A5** | Reused from `component-css.css`; and this feature animates nothing, and every control here is a native focusable element |
| **L1** (every `href="#X"` resolves to an `id="X"` in the page) | It extracts every `href="#…"` (`:345`) and tests each against the page's own `id="…"` set. Both in-page hrefs this feature emits are created with their targets: the skip link with `#graph-table-end`, and the caption's link with the unlisted region's own id, emitted in the same step (§ Feature Flow step 4) |
| **L2** (relative `.md` links) | The caption cites `./relationships.md`. L2 greps the emitted file (`:386`) and resolves each target against **the file's own directory** — `HTML_DIR=$(dirname "$HTML")` at `:62`, consumed at `:391`. Its `--kb-dir` flag sets **no** resolution basis whatever its `--help` (`:9`) and header comment (`:28`) say; that discrepancy is a known `canonical/` defect already routed, and this row cites the code. `graph.html` sits in `.aid/knowledge/` beside `relationships.md` (FR-9), and the footer already carries the same target, which the script's `sort -u` (`:386`) collapses — so this feature adds **no** new L2 input |
| **C1 / C2** (`contrast-check.mjs`) | Tokens only. The badge pairs used here are already in that script's pair list (`:97–108`) |
| **S2 / NM** | Not this surface: the table introduces no `<script src>`, no `<link href>` and no drawing engine |
| **S7 / T1–T4** (`validate-visuals.mjs`) | The collector walks `.diagram-box`, `.infographic` and `<svg>` (`:303–304`, `:328`). The table is **none of those and is not collected** — and must not be given one of those classes to "get it checked", since T2's sibling-`<g>` overlap rule is meaningless for tabular layout. The table's own containment is asserted by **TV16** instead |

The manual items in `accessibility-checklist.md` this feature owns: no skipped heading levels (:113); a
44 × 44 px minimum hit area (:100); and a layout usable at 200 % zoom with horizontal scrolling confined to
`.tbl-wrap`, where a wide table legitimately scrolls (:105–106). Its `<label for>`/`aria-label` item (:117)
is scoped to form **inputs**, which this feature emits none of; its `<button>`s name themselves.

#### Keyboard reach (SC 2.1.1) and focus (SC 2.4.7, SC 2.4.11)

- **Cells are not tab stops.** Screen readers navigate cells with their own table-navigation commands, and
  a tab stop per datum would produce a stop count proportional to rows × columns and defeat both audiences.
  The tab stops are: the skip link; the caption's two links — `./relationships.md` always, the unlisted
  region when D4's set is non-empty, both `href` anchors and so both in the tab order; one sort button per
  column header; **two** select controls per listed row (one per endpoint); and one per unlisted-region row.
- **The skip link is what bounds the traversal**: one keystroke leaves the whole region, which is why it is
  the region's first element — and the caption's links add at most two stops, never a per-row cost.
- **Two sticky layers can obscure a focused row control, and SC 2.4.11 requires accounting for both**: the
  shell's top bar (`design-tokens.md` § "Spacing & sizing": ~60 px, sticky, :103) and the reused `.tbl th`
  rule, itself `position: sticky; top: 0` (`component-css.css`:341–342). So the sticky header takes a top
  offset equal to the bar height rather than pinning to the viewport edge, and focusable elements inside
  `<tbody>` carry a `scroll-margin-top` covering **both** layers, which step 6's reveal honours. **All
  three tables carry this, not only Relations** (task-034): the Files tree's and the Concepts table's own
  checkbox, collapse toggle and row each get the same allowance `tblRenderFilesTree`/`tblRenderConcepts`
  compute from their own `<thead>`, mirroring `tblBodyRow`/`tblRenderUnlisted` rather than assuming a new
  table inherits it for free — it does not, since a detached `<thead>` measures zero height (**TFC17**,
  found by review: the two new tables initially carried none at all).
- **Activation is per element type**: sort and select are `<button>`s, taking `Enter` **and** `Space`;
  the skip and caption links are `<a href>`, which the APG Link pattern activates on `Enter` alone —
  all SC 2.1.1 asks. Nothing is pointer-only or a drag gesture, so NFR-6's exemption is not needed here.
- **Open is two steps from a row, deliberately and not silently.** Selecting a row populates feature-007's
  selected-node detail region, whose Open `<button>` is the keyboard route NFR-6 requires. Whether focus
  moves there is feature-007's to decide — Open Item 1.

#### Screen-reader behaviour (SC 1.3.1, SC 4.1.3) — asserting only what the platform provides

Real table semantics do most of the work: the `<caption>`, the `<th scope>` associations and the `aria-sort`
the Component breakdown fixes, so the current order is announced rather than merely drawn.

**`aria-sort` is used at its real value space and nowhere beyond it.** Values are `ascending`,
`descending` and `none`; it appears on the **listed** table's six `<th scope="col">` (task-034 slims ten to
six) and nowhere else — never on a row header, which is not a sortable column, and never in the unlisted
region, whose three column headers wrap no sort control, nor in the Files tree's or Concepts table's own
headers, which wrap no sort control either — **at most one** of the six carries a non-`none` value, and when
`sort.column === 'row'` every one of them carries `none`, which is the platform-correct statement of "not
sorted by this column" and gives the reader a way back to the file's order with no extra control.

**A sort change writes no live region.** The gesture's own control is the focused element, and its
`aria-sort` state change is conveyed there; feature-007's polite region already carries
`viewModel.announcement` once per lens change (its § Feature Flow step 8), and the page has exactly two
live regions and no more. Creating a third, or writing into a region another module owns, would make
"which region said that" unanswerable and risk doubled or lost announcements.

**Row-level detail is not announced.** It is already reachable by table navigation, and announcing it
would flood the region — the same granularity judgment feature-007 § Accessibility records for the shell.

#### Colour is never the sole carrier (NFR-5)

| Meaning | Non-colour carrier | Colour (additive only) |
|---|---|---|
| Node kind | **relocated by task-034**: the Relations table carries no `Kind` cell of any kind (D3 drops both `Source Kind` and `Target Kind`) — the carrier is now the Files tree's and the Concepts table's own `Kind` column, a literal text value from §5.2's enum (**TV13**, reused `tblKindCell`) | the `--gk-*` token feature-007 D5c assigns |
| Which of §5.1's three sources a node comes from | the `kb:` / `int:` / `ext:` prefix is part of every id and so is present in the cell text (§5.3). This is a prefix read about **where an id comes from**, which is exactly where Q21's refinement says a prefix is correct — the clause is not about what class the node belongs to, which the `Kind` cell answers | none |
| Relationship category | `S2T Relation` / `T2S Relation` are literal text; the name is always present here, which is what NFR-5 relies on when the graph shows it only on hover | the `--gc-*` token feature-007 D5b assigns |
| Provenance | `Provenance` is a literal column with a text value | badge tint |
| `kb-unbacked` | a `no source` badge — text | `--warn` on `--warn-bg` |
| `artifact-undocumented` | a `no KB doc` badge — text | `--err` on `--err-bg` |
| `focus` / `chain` | a `selected` / `chain` badge — text | badge tint |
| Sort state | `aria-sort`, plus a caret glyph in the header button | none |
| Thinned, folded, collapsed | those rows and nodes are **removed**, never merely faded: the caption states the hidden **row** count (`counts.hiddenEdges`), and a thinned or folded **node** is absent from `visibleNodes` altogether, so this surface renders nothing of it to fade. `counts.hiddenNodes` is a **node** figure and no part of this caption's row pair: feature-007's `counts` row names the surfaces that **read** that field — this caption among them (its SPEC.md:643) — rather than obliging each to state every member, which is this feature's reading of the line and is stated because the Caption row fixes the caption's content exactly | none |
| `dimmed` | nothing, deliberately — see below | reduced emphasis |

**`dimmed` is the one class with no text carrier, and that is sound rather than an exception.** `dimmed` is
the **complement** of the marked set: every positively-marked row and endpoint carries a text badge, so
"this row is in the lens's highlighted set" is readable as text and "this row is not" is readable as the
absence of that text. No information rests on the visual de-emphasis, which is what SC 1.4.1 asks. Giving
`dimmed` its own badge would put a marker on the majority of rows and bury the signal — the same reasoning
FR-13's Coverage domain was narrowed on.

A colour-only encoding is therefore impossible here by construction — part of why this table carries AA.

#### The four lenses in the table (AC-7 table side, NFR-3)

Each lens changes the table visibly, and does so because the table reads the same projection the graph
does — not because a second interpretation was written to match.

**Which channel each lens moves, stated before the table because getting it wrong is the easy error.**
Membership is decided by the filters, the density level and the fold, and by nothing else — `visibleEdges`
is "the rows surviving the filters and the density level" (feature-007 D4). `emphasis` and `focus`
therefore **do not remove rows**; they classify them, and feature-007 says so in the same words for the
graph: the Provenance lens "marks edges on a path … **and dims the rest**" (D6f), and selection
"highlights its neighbourhood, dims the rest" (D7a). So only Overview shrinks the row set, carrying as it
alone does a density level above `1` and a folding dimension.

| Lens | Visible change in the table |
|---|---|
| **Coverage** | Each gap endpoint gains its text badge, `data-emphasis` separates the dimmed remainder, `grouping: 'node-kind'` repartitions `groups`, and the caption reports the two gap counts from `coverageGaps`. `density: 1` thins nothing, so **no row is hidden and the row set is unchanged** — which is what makes this the lens where a zero-row node is guaranteed present in the unlisted region. The preset clears `focus.nodeId` (feature-007 D6a), so every gap endpoint is badged on arrival; select one afterwards and that endpoint reads `selected` in its place — feature-007 D4's precedence, one class per id — while the row set, the caption's counts and AC-15's row-to-ledger equality are untouched (**TV07** asserts both states) |
| **Overview** | The one lens that changes membership: `grouping: 'document'` folds each document's `section` and `fact` members, so those rows list against the document head and a row between two members of one group disappears as `'collapsed'`; `density: 3` thins low-degree nodes; and the caption reports `counts.hiddenEdges`. The disclosure that expands a group is the shell's, not this region's (§ boundary), so nothing here derives an expansion state |
| **Impact** | Rows outside `focus.depth` hops of `focus.nodeId` are **dimmed, not dropped** — and dimmed through their **endpoints'** `nodeEmphasis`, selection assigning no edge class at all (feature-007 D4's `edgeEmphasis` row, its :631), which is why D3's mapping takes `'dimmed'` from either map; the focused endpoint carries the `selected` badge, and the caption names the node and the depth through `lensSummary` rather than composing a sentence of its own. A focused node with no surviving edges is in `visibleNodes` by contract, so it appears in the unlisted region — "what does this touch" answered with "nothing recorded" rather than with an empty table |
| **Provenance** | The cross-side chain rows carry the `chain` badge and the rest are dimmed; `grouping: 'provenance'` repartitions `groups`; and the `Provenance` column's own text value carries, as literal text, the distinction FR-13 asks colour to carry in the graph |

**The row order changes for no lens, and that is deliberate.** Order is a function of `sort` alone (D2) and
no preset patch sets `sort` (feature-007 D6a), so a lens that reordered rows would be a second ordering
mechanism outside the one field that owns it. A "gaps first" order would need one more `sort.column` token;
the value space is this feature's to extend (D2) and no requirement asks for it, so it is not taken today.

**The Coverage row set is not recomputed here.** The two classes come from `viewModel.coverageGaps`,
produced by the single shared predicate in `coverage-predicate.mjs`, the same module feature-006's detector
runs. This feature adds no second gap computation, which is how its side of AC-15 holds. It labels the two
classes distinctly because feature-006 D6a's asymmetry is deliberate: `artifact-undocumented` has one
ledger row per member and is the class AC-15's equality binds, while `kb-unbacked` is **lens-only** with no
ledger counterpart, and its presence does not breach the criterion.

#### Responsive behaviour

`.tbl-wrap` supplies the horizontal scroll a wide table legitimately needs, so the page itself never
scrolls sideways — and that scroll is the whole responsive answer for column width, which
`accessibility-checklist.md` explicitly permits for a wide table (:105–106). **No cell collapses into a
disclosure**: a `<details>` per row would add a tab stop per row for content the reader can already reach
by scrolling, which is the opposite of the granularity judgment above.

**Revised by task-034: the shortened-cell contract moves to the Files tree and the Concepts table.** The
Relations table no longer carries a `Name` cell of any kind (D3), so it has nothing left to shorten; every
node's own name — including a `fact`'s, which reproduces a KB anchor string verbatim (feature-003 D5) and is
the case this contract exists for — is stated once, in that node's Files-tree or Concepts-table row, and it
is THERE that the 768 px mobile breakpoint (`design-tokens.md` § "Spacing & sizing", :104) applies: below it,
a Name cell whose text exceeds the label budget renders `nodeShortLabels` as its **visible** text with the
full `nodeLabels` value in the accessibility tree beside it — a visible `<span aria-hidden="true">` beside a
`.sr-only` span (`component-css.css`:671), which adds no tab stop. That is the "collapsed cell" feature-007
D9 names as the one place the shortened form may appear, and why **feature-007's AC-S8** holds — the
accessible name is never the shortened form (**AC-S7** and **TV15**, relocated to the Files tree/Concepts
table in the same change, which state what `role=cell`'s name-from-contents allows and the equality it rules
out). The unlisted region's `Name` column shortens **nothing**, unchanged from before this task: its table is
three columns wide, and `nodeLabels` there ends with the "no recorded relationships" fact the column exists
to carry.

Containment is checked at the two widths the visual gate uses — 732 px and 390 px, read from
`validate-visuals.mjs`'s `OVERFLOW_VIEWPORTS` (`:95`) — so this surface is measured at the same widths as
the rest of the artifact even though it is not collected by that gate (**TV16**). Task-034 adds two more
tables to that same measurement, not a second scale: the Files tree and the Concepts table reuse `.tbl-wrap`
identically.

#### Reduced motion (AC-9, from this side)

**AC-S6** in full: no transition on a sort, a filter or a lens change, no animated row height, and a reveal
scrolling by an explicit `behavior: 'instant'` — the route no CSS grep reaches, and the one the reused
`html { scroll-behavior: smooth }` (`component-css.css`:67) would otherwise take. So the reused
`@media (prefers-reduced-motion: reduce)` block (**A4**) has nothing of **this feature's** to suppress: the
in-page links this region emits scroll by that `html` rule, which the same block forces to `auto` (:663–665).
AC-9's settled-graph clause is feature-008's (NFR-4).

#### The Files tree, the Concepts table, and the checkbox-hide axis (task-034)

Added in full by task-034, 2026-08-06, against DETAIL.md's own numbered acceptance items (cited below as
**AC-T34-n**). This is the node half D3 retired from the Relations table: two more tables, over EVERY node
in the model — not `viewModel.visibleNodes`, which the lens and the filters already narrow, but
`graphModel.nodes` directly — so a reader can find and check any node whether or not the current lens draws
it. The Relations table stays lens-filtered exactly as before; only these two are unconditional.

**The partition (AC-T34-1).** `kind === 'concept'` → the Concepts table, flat (32 nodes, measured). Every
other kind → the Files tree: `section`/`fact` nest under the `document` their id names (`kbDocOf`,
graph-model.js); `document`, `source-artifact` and an in-repo `image` sort into a folder tree by repository
path; an external `image` or any `web-page` — neither has a repository path — buckets into a synthetic
"External sources" folder. That rule is **exhaustive over the closed seven-kind enum**: every node either is
a concept or is not, so the partition needs no enumeration of what "file" means, cannot silently miss a kind
a future schema change adds, and needs no new field — a folder is a synthetic grouping over existing ids, not
persisted anywhere. 520 file-backed + 424 nested (section + fact) + 32 concepts = 976 over the live
`relationships.md`, the arithmetic completeness check DETAIL.md names; this SPEC asserts no total (§ Figures)
and the test asserts the arithmetic against its own fixture instead (**TFC01**).

**Both tables carry the same six columns**: Show (the checkbox), Name, Id, Kind, Provenance, Coverage. `Id`
and `Kind` render exactly as D3's own `tblKindCell`/badge machinery already does for a Relations-row
endpoint, reused rather than reimplemented. `Provenance` is a NODE property nowhere else in this SPEC: a
relationship's provenance is an `Edge` field, not a `Node` field, so a node's provenance is the set of values
across every edge naming it, textually joined where it has more than one and stated as "no relationships"
where it has none — computed once per render over the edge list, not per row. `Coverage` reads
`viewModel.coverageGaps` directly rather than `nodeEmphasis`, because `nodeEmphasis`'s
`kb-unbacked`/`artifact-undocumented` classes only populate under the Coverage preset (feature-007 D4's
`classifyNode`), while these two tables state a node's coverage class **unconditionally** — the same two
sets, computed once at load and never touched by this axis (below).

**The checkbox hides from the VIEW, never from the DATA (AC-T34-3, the owner's ruling and why).** Unchecking
a row writes every real node id in its subtree into a new `LensState` field, `filters.hiddenIds`
(graph-model.js § 3), which node admission excludes at the SAME point a kind or a provenance filter does
(graph-model.js § 9) — a view filter, structurally incapable of reaching `verifyCoverage`, which runs once at
load, before any lens exists (`createStore`). The owner chose this over dropping a node from the data because
a blanket dot-path exclusion — measured in the same session — stripped every backing artifact from 32 of the
319 KB claims that have any, turning 32 satisfied claims into red gap badges caused by the filter itself. A
checkbox that did that silently would mislead the reader about their own coverage; routing it through
`filters.hiddenIds` instead means `graphModel.integrity` and `viewModel.coverageGaps` are **provably
identical** before and after any hide (**TFC04**), because neither reads the lens at all. A folder's checkbox
governs its whole subtree — every id `tblSubtreeIds` collects under it — and nothing outside it
(**AC-T34-4**, **TFC05**/**TFC06**); a folder contributes no id of its own, so hiding one can never itself
appear in `filters.hiddenIds`. The existing `counts.hiddenNodes` figure (feature-007's own, "the count a lens
reports") already includes a checkbox-hidden node without any change here, because `graphModel.nodes.size` is
untouched by this axis and only `visibleNodes.length` shrinks — the "hidden by the reader, not absent from
the model" distinction DETAIL.md asks for is therefore a property of the existing arithmetic, not a new
counter.

**Persistence (AC-T34-5, Scope C).** The selection is written to `localStorage` under a key scoped to the
DIRECTORY the page was opened from (`hiddenSelectionKey`, graph-model.js § 13) — not the full path, which is
what lets `graph.html` and `table.html`, siblings in the same generated directory, share one selection, and
not the browser's own origin partitioning, which a `file://` page cannot rely on. Restored once, at mount,
before the first render (`tblRestoreHiddenSelection`): an id the model no longer has is dropped and the rest
restores (**TFC10**); a selection that would hide EVERY node restores nothing and reports why, through the
shell's existing non-live callout channel, rather than leaving an emptied artifact that reads as broken
(**TFC11**). This is the one documented exception to graph-model.js's own header claim of touching no
storage — see that file's § 13 for why the exception is narrow and named rather than silent.

**The graph reads the same selection.** `filters.hiddenIds` flows through `project()` exactly like every
other filter, so the drawing rendering — which consumes `viewModel.visibleNodes` and `visibleEdges`
unconditionally — already stops drawing a hidden node with no change of its own beyond the shared filtering
mechanism. Restoring the persisted selection into the GRAPH page's OWN initial `LensState` needed one more
call, made in the SAME commit: `graph-controls.js`'s `mountShell` calls `restoreHiddenSelection(store,
graphModel)` immediately after `createStore`, writing `filters.hiddenIds` before the first projection runs,
and `reportSuppressedHiddenSelection(root, resolved)` **after** `reportConflicts` — split into two calls at
two different moments because a single call whose notice landed before `reportConflicts`'s own unconditional
`clear(host)` on the same `[data-conflicts]` element had that notice erased eight lines later (a defect a
review cycle found; **GV29** now drives a full `mountShell()` boot with a real, stored hide-everything
selection and asserts the notice survives to be visible, not merely that `resolveHiddenSelection` returned
`suppressed: true` in isolation, which is what let the erasure through undetected the first time). See
**Open Item 6**, closed in place.

**Accessibility.** The Files tree is a `<table role="treegrid">` (the Concepts table stays a plain `<table>`
— it has no hierarchy); each row carries `aria-level` and, where it has children, `aria-expanded`, which is
the STRUCTURAL carrier of nesting this task's own constraints require — indentation and connecting-line
guides are presentation only. The collapse/expand control is a real `<button>`, marked `data-tree-toggle`
(never feature-007's own group-disclosure marker, so the two counters — a lens grouping's and a file-tree
folder's — cannot be confused with each other), toggling the native `hidden` attribute on descendant rows,
never an author `display` rule (this feature's CSS declares none for a tree row, so the UA's own
`[hidden] { display: none }` is never outranked — the first of the three defects "what must not regress"
names, guarded against rather than merely avoided by omission). The Show checkbox is a native
`<input type="checkbox">`; a folder's is `indeterminate` (the native IDL property, which browsers map to
`aria-checked="mixed"` with no ARIA authored here) when some but not all of its subtree is hidden
(**TFC08**). Every control is native, so `Enter` and `Space` operate each by the platform's own behaviour —
verified the same way task-033's own suite verifies it, by asserting the element IS the native, enabled type
its behaviour depends on (**TFC07**).

| ID | Assertion | Criterion |
|---|---|---|
| **TFC01** | the Files-tree file rows and the Concepts rows partition `graphModel.nodes` — every node in exactly one, none missing, none duplicated, asserted as set equality against a self-built fixture | **AC-T34-1** |
| **TFC02** | a document's `section`/`fact` nodes render nested under it (a strictly greater `aria-level`) and are absent from the Concepts table | **AC-T34-1** |
| **TFC03** | unchecking a leaf hides it from the Relations projection (`visibleNodes`/`visibleEdges`) while its own row stays present, visible and re-checkable in the Files tree | **AC-T34-3** |
| **TFC04**, **TFC14** | hiding a node changes nothing about the coverage answer, and the persisted value round-trips through `resolveHiddenSelection` to the same hidden set the store is applying | **AC-T34-3** |
| **TFC05**, **TFC06** | unchecking a folder with two children hides both and touches no id outside the subtree; re-checking restores exactly that subtree, leaving an independently-hidden node elsewhere untouched | **AC-T34-4** |
| **TFC07**, **TFC08** | the Show checkbox and the collapse toggle are both native, keyboard-operable controls; a folder checkbox is indeterminate when its subtree is partially hidden | **AC-T34-6** |
| **TFC09** | collapsing hides descendant rows via the native `hidden` attribute and exposes `aria-expanded="false"`; expanding restores them; collapsing never touches `filters.hiddenIds` | **AC-T34-6** |
| **TFC10**, **TFC11**, **TFC15** | `resolveHiddenSelection` drops an unknown id and keeps the rest; it suppresses (restores nothing) a selection that would hide every node; it **deduplicates** the stored list first, so a repeated real id cannot inflate the count past the model's own and trip a false suppression (found by review against the live, real 976-node file) | **AC-T34-5** |
| **TFC12** | the Files/Concepts regions create no live region and no `data-control`/group-disclosure marker (the two-region and manifest-bijection contracts hold with these regions present) | feature-007's own contracts |
| **TFC16** | a `section`/`fact` naming a document the model has no node for (malformed input) is attached under `tblBuildFilesTree`'s own "unattached" fallback rather than silently dropped — exercised directly against a hand-built, deliberately malformed `graphModel`, which is the only way to reach a branch `parseRelationships`'s well-formed output cannot | **AC-T34-1** |
| **TFC17** | every focusable Files-tree and Concepts-table control (the Show checkbox, the collapse toggle) carries a numeric `scroll-margin-top`, the same SC 2.4.11 allowance `tblBodyRow`/`tblRenderUnlisted` already give the Relations table and its unlisted region | **AC-T34-6**, SC 2.4.11 |
| **GV29** (`graph-view-dom.mjs`, not this file) | a stored selection naming every node survives a full `mountShell()` boot as a **visible** notice in `[data-conflicts]` — the graph page's own half of **TFC11**'s rule, needing a real `mountShell()` boot rather than the pure function alone to catch the erasure Open Item 6 records | **AC-T34-5**, Open Item 6 |

### Tests

Fixtures are self-built and depend on no work folder's contents (**A-6**). The `TV*` assertions live in
**`tests/canonical/test-graph-table-view.sh`**, which `tests/run-all.sh` discovers by its
`tests/canonical/test-*.sh` glob (its :112).

| ID | Assertion | Criterion |
|---|---|---|
| **TV01** | for each of the four presets, the rendered table differs from the initial projection's on at least one of: the listed row set, the listed endpoint ids, the emphasis badges, `data-emphasis`, or the caption text; and the render input is the store's **current** `ViewModel` instance, asserted by identity — the table's half of "both renderings consume the same projection". The cross-surface pairing is Open Item 3 | **AC-7** |
| **TV02** | at `grouping: 'none'` with a single-category filter that removes some rows and leaves others, the **listed** table's `<tbody>` row count equals `counts.edges` and is non-zero, and the caption states it; and applying each preset afterwards leaves the listed row set filtered — the filter composed rather than reset | **AC-8a** parts 1–2 |
| **TV03** | `validate-html-output.sh` passes H1, A1, A4, A5, L1 and L2 over a generated `graph.html`; the table region contains a `<table>` with `<caption>`, `<thead>`, `<th scope="col">` per column and `<th scope="row">` per row; and the L2 target set is unchanged by this feature's caption link | **AC-9** |
| **TV04** | the region's tab stops are exactly the skip link, the caption's `./relationships.md` link, the caption's unlisted-region link where D4's set is non-empty, one button per column header, **two** `data-row-select` per listed row, and one per unlisted-region row — **no cell and no `<summary>` is focusable, at both gate widths**, so the responsive layout cannot add or drop a stop; the skip link's target receives focus; and each stop is operable by the keys its element type provides — `Enter` **and** `Space` on every `<button>`, `Enter` on every `<a href>` | **AC-9**, **AC-21**, NFR-6 |
| **TV05** | `aria-sort` is present on every `<th scope="col">` of the **listed** table — its **six** sortable columns (task-034 slims ten to six) — and on **no** other `<th>` in the region, neither a row header nor one of the unlisted region's three column headers, which wrap no sort control; it is `none` on all six when `sort.column === 'row'` and non-`none` on **exactly one** otherwise; and no element this feature emits carries `aria-live` or any implicitly live role — `alert`, `status` or `log` — so the page's two-region count is untouched by every route into it | **AC-9**, feature-007's two-region contract |
| **TV06** | **each** of the six columns renders a value taken from the `ViewModel` alone — listed ids via `edgeFold`, the rest from the `Edge` record — and each of the unlisted region's three likewise, from `visibleNodes` and `nodeLabels`, so an implementation rendering no cell at all fails rather than satisfying the row vacuously; and `graph-table.js` contains no top-level `import`, no `fetch`, no `XMLHttpRequest` and no dynamic `import(`. A node's kind and name are no longer this table's cells to prove — that obligation moves to **TFC01**/**TFC02** over the Files tree and the Concepts table | **AC-10**, feature-007 GV01 |
| **TV07** | under the Coverage preset as D6a applies it — `focus.nodeId: null`, so no id is `'focus'`-marked — the ids badged `no KB doc` equal `coverageGaps.artifactUndocumented` and equal the fixture ledger's `Doc` column; the ids badged `no source` equal `coverageGaps.kbUnbacked` and appear in **neither** the ledger nor `kb_gaps`; the two badges are textually distinct; and with a gap endpoint then selected, that id reads `selected` while the remaining badged ids equal its class minus that id and the listed row set is unchanged — the one-slot cost, asserted rather than left to be discovered | **AC-15** |
| **TV08** | no element this feature emits carries `data-control` or `data-group-toggle`, so feature-007's GV17 bijection and GV22's "exactly one disclosure per foldable group" both hold with this region in the page; and over a fixture rendering **both** control kinds, every `data-row-select` and every header button is driven by keyboard alone with its `LensState` effect asserted — `{'focus.nodeId': id}` for the first, leaving `focus.depth` unchanged | **AC-21**, feature-007 D8, GV22 |
| **TV09** | in a generated `graph.html` the table region precedes the graph region in **DOM order**, is not nested inside it, and renders completely when the canvas module is removed from the manifest — the buildable form of AC-S1's canvas-absent case, the WebGL-absent one being feature-008's runtime | **AC-S1** |
| **TV10** | activating a header button three times yields `ascending`, `descending`, then `{column: 'row', direction: 'asc'}`; each order is a permutation of the same row multiset; over a column with more than one distinct value the `ascending` and `descending` orders differ, and over a **uniform** column both equal the file's own order — D2's both-directions tie-break, not a defect; two rows with equal cell text in the sorted column order by `row` ascending in **both** directions; and the order is unchanged when the test process's locale is changed | **AC-S2**, D2 |
| **TV11** | over a fixture exercising all four presets plus a folding dimension, the listed rows are exactly the `visibleEdges` rows whose `edgeFold` entry is not `'collapsed'` — asserted as a **set equality in both directions**, so neither an extra row nor a dropped one passes — which is also thinning's carrier, removal rather than fading | **AC-S3**, **AC-S5** |
| **TV12** | over the same fixture, every `visibleNodes` id appears in the table region — in a listed row's Id cell or in the unlisted region; and each of D4's three populations is exercised, including a **document whose every row is `'collapsed'` and whose `degree` is non-zero**, which a `degree === 0` selection would miss | **AC-S4**, D4 |
| **TV13** | source prefix, both relation names and provenance are present as **text** in Relations-table cells (node kind moves to the Files tree/Concepts table, where it is stated as text there too — `role=col` `Kind` column, reused `tblKindCell`); **every** value of `nodeEmphasis` and `edgeEmphasis` renders per D3's mapping, with `dimmed` and `normal` the only two that render no text marker; `aria-sort` is present alongside the caret glyph; and `graph-table.js` and this feature's CSS rules declare no `--gk-*`/`--gc-*` token and contain no colour literal by any route — no hex, no `rgb(`/`hsl(`/`oklch(`, no named colour | **AC-S5** |
| **TV14** | this feature's CSS rules declare no `animation`, no `transition` and no `scroll-behavior: smooth`; `graph-table.js`'s **one** scroll call passes `behavior: 'instant'` and the module contains `'smooth'` nowhere — the scripted route no CSS grep reaches, and the one the reused `html` rule would otherwise supply; and a sort, a filter and a lens change each re-emit rows with no transition property set | **AC-S6** |
| **TV15** | **relocated to the Files tree by task-034** (the Relations table carries no `Name` cell of any kind — D3): below 768 px a Files-tree row's Name cell whose node name exceeds the label budget shows `nodeShortLabels` as its only visible text, that span carrying `aria-hidden="true"` so no shortened form is in the accessibility tree, while the cell's computed accessible name **contains** the full `nodeLabels` value; and the shortened form appears nowhere above the breakpoint and nowhere in the unlisted region at either width | **AC-S7**, feature-007 AC-S8 |
| **TV16** | at 732 px, at 390 px, and at 200 % text zoom, over a fixture where **both** tables are present, no region this feature emits overflows its own container, with a wide table's horizontal overflow confined to `.tbl-wrap` | **AC-9** (`accessibility-checklist.md`:105–106) |
| **TV17** | a projection with no surviving row renders the empty-state row quoting `lensSummary`, and a projection with rows never renders it | **AC-9** (an emptied table is not a broken-looking one) |
| **TV18** | a select of a node in `visibleNodes` leaves that id `'focus'`-marked in `nodeEmphasis` — asserted under `emphasis: 'none'`, `'coverage'` **and** `'provenance-chain'`, so a projection that marks no id fails here instead of passing on a vacuous antecedent — and brings that node's **first row in the current order** into view clear of both sticky layers, asserted at the file's order and at a non-default `sort`; where every row naming the id is `'collapsed'` the unlisted-region row is brought into view instead; `document.activeElement` is unchanged across the reveal; a re-projection that leaves the marked id alone scrolls nothing; and select A, then feature-007 D6a's Coverage or Overview patch (`focus.nodeId: null`, its :815–816), then select A again reveals **again** — `focusRevealed`'s clearing rule | **AC-S8**, FR-14a, feature-007 D7a |

### Open Items

Recorded rather than silently assumed. Every item still **asking another owner for a change** names that
owner and its **Q26 class** — **mechanism** (reopens that SPEC, and since 001–007 are frozen that now
needs an explicit owner decision) or **editorial** (collected onto STATE.md § Editorial queue and fixed in
the Q24 item-9 batched pass); an **answered** item keeps its number and says so in place, since sibling
SPECs cite these numbers (feature-007's own rule, its :1834–1837). None blocks this feature's implementation.

1. **Reaching the Open control from a table row costs an unbounded number of keystrokes.** NFR-6 makes
   this view "the keyboard-operable route to select **and** open". Select is this feature's row control;
   Open is feature-007 D7b's `<button>` in the selected-node detail region. feature-007 fixes neither that
   region's position in DOM order nor an id for it, and does not say whether activating a select moves
   focus — so a keyboard reader deep in the table must traverse the remaining rows to reach Open. Two
   resolutions are available and both are feature-007's: a fixed id on the region, which lets this
   feature's row control carry `aria-controls`; or moving focus to the region on selection. **Reachability
   is not in question and this feature does not block** — the item is about keystroke cost, and the row
   control is complete and operable without it. **Owner: feature-007** (it owns the region, DOM order and
   the focus contract). **Q26 class: mechanism** — it changes focus behaviour or adds a fixed id.
2. **A zero-row `image` or `web-page` node is absent from this view, and this feature invents no carrier.**
   D4 records why: such a node never reaches `GraphModel.nodes`, `kb_gaps` is scoped to
   `Kind = source-artifact`, and feature-006's Open Item 7 declines to widen it — "putting media ids in
   that list would reintroduce the prefix-keyed defect through the frontmatter instead of through the
   predicate". This SPEC therefore states the absence and relies on FR-9a's coverage-note counts, which
   feature-007's coverage panel renders. **Owner: the work owner**, on the composition feature-006 Open
   Item 7 and feature-007 Open Item 3 already record (feature-003 owns any second frontmatter key —
   **frozen; scheduling needs an owner decision**; feature-006 writes; this feature and feature-007
   consume; feature-004 is the source and makes no change). **Q26 class: mechanism** — a new frontmatter
   key is a contract.
3. **The canvas's side of the parity obligations is feature-008's, and is being authored concurrently.**
   AC-7, AC-8a and AC-21 are mutual: this SPEC states each obligation as feature-007's contract requires
   it and specifies **no** canvas internals. What is owed is the pairing at integration: TV01 asserts only
   that **this** surface renders from the store's current `ViewModel`, and TV08 only that **this** region
   emits no `data-control` — the matching assertions over the canvas's emitted DOM, and the one that pairs
   the two surfaces against a single projection, belong in whichever suite feature-008 or feature-013
   places them. **Owner: feature-008**, with **feature-013** (test placement). **Q26 class: mechanism** —
   it fixes where a shared assertion runs. *No joint mechanism is invented here; feature-007 is the shared
   authority and this feature defers to it.*
4. **`validate-html-output.sh`'s `--help` (`:9`) and header comment (`:28`) both claim `--kb-dir` resolves
   relative `.md` links, while the code resolves against `HTML_DIR=$(dirname "$HTML")` (`:62`, consumed at
   `:391`) and the flag sets no basis at all.** § "Which AC-9 checks this surface answers" cites the code's
   behaviour, not the help text; recorded only so a reader who checks the flag is not misled, the defect
   being already routed and **nothing owed to this feature**. **Owner: feature-011** (it owns that script's
   parameterisation and already carries feature-007 Open Item 4 against the same file). **Q26 class:
   editorial** — the code is right and no behaviour changes.
5. **ANSWERED by feature-007 — the `nodeEmphasis` precedence.** *(Filed as: nothing ranked `'focus'`
   against a coverage class or `'dimmed'` on one node, so the reveal's trigger could fail to exist.)* D4
   now states the node axis as a **total precedence over all five values with `'focus'` first** (its :630,
   owner decision on this gate's finding), **GV28** asserts all four steps (its :1822), and feature-007's
   Open Item 13 records the answer. It is the reading this SPEC assumed, so step 6, **AC-S8** and **TV18**
   are re-attributed and unchanged in substance. Nothing is routed onward.
6. **ANSWERED — the graph page restores the checkbox-hide selection on load.** *(Filed as: the four-file
   boundary this task was given — no edit to `graph-skeleton.html`/`graph-css.css`/`graph-controls.js`/
   `graph-canvas.js` — left no file of this task's own to make the one call from.)* The task escalated
   rather than crossing that boundary, and **the coordinating agent that owned those four files made the
   edit itself** — the work owner neither reviewed nor authorised it, and no statement here should be read
   as their decision. The change landed in the SAME commit as this SPEC change: `graph-controls.js`'s
   `mountShell` calls
   `restoreHiddenSelection(store, graphModel)` right after `createStore`, and `reportSuppressedHiddenSelection`
   after `reportConflicts` (§ "The Files tree, the Concepts table..." above states why the call is split in
   two rather than made once). Both pages now share the mechanism (`filters.hiddenIds` through `project()`)
   **and** the restore-on-load call, so a hide made on the table page reaches the graph on the next load with
   no further change owed anywhere. A first version of the call landed the notice before `reportConflicts`'s
   own clear of the same host and lost it silently — found by review, fixed by splitting the write from the
   report, and closed by **GV29**, which drives the actual defect's reproduction route (a real `mountShell()`
   boot, a real stored selection) rather than the pure function alone. Nothing is routed onward.

### Figures

**No quantity in this SPEC is a measurement.** Every quantity above is one of four things, and each is
labelled where it appears: a **contract count** (feature-003 D1's ten columns; AC-8a part 3's
at-most-eight colour cap, `REQUIREMENTS.md`:930), a value **read from a cited artifact on disk** (every
line number above; the 768 px breakpoint and ~60 px top-bar height; the 732 px and 390 px gate widths;
the 44 × 44 px hit area and 200 % zoom; the 4.5:1 contrast target — each read from the artifact named
where it appears), a **set cited rather than counted** (§5.2's `Kind` enum, feature-001 D5's categories,
`GraphModel.categories`, `PROVENANCE_VALUES`, `keys(PRESETS)`), or **an enumeration made on the spot and
reproducible from the cited source** — feature-006's class, adopted verbatim (its SPEC.md:1409–1414) —
which covers every count made on the spot here — § Description's two facts, D2's three properties, D3's two
qualifiers, D4's three populations, the unlisted region's three columns, the nine `<td>` beside each row
header, the seven em-dashes a merged row would carry — and every count in the change log, each reproducible
from the entry or the table it names. Exactly one quantity is none of the four: the change log's reference
to the superseded **eight**-column shape, which names what §5.2 voided and is marked voided where it appears.

**No row count, node count, bench size, frame rate or payload figure is asserted anywhere in this
document**, and none is needed by anything in it. `delivery-001/FINDINGS.md` is stamped SUPERSEDED, so the
bench it measured and every conclusion built on it are void; A-5 is void and states no total of its own;
and neither withdrawn figure is reproduced here, because quoting a figure in order to retire it is exactly
how the last one kept reappearing (Q20 (A-5 figure); Q23 instance 2). Where this feature would otherwise
have leaned on a size — the decision to render every row with no pagination or virtualisation (§ Feature
Flow step 3) — it states the **derivation** instead: full rendering is required by screen-reader row
counts, find-in-page and printing; what bounds the rendered size is the reader's own `density` and filter
controls; and whether that stays comfortable at the project's derived bench is a measurand **FR-18's
replacement research** owns under NFR-7, with the over-ceiling case NFR-8's warning. **AC-6a** is the
frame-rate criterion and belongs to feature-008 (feature-007 Open Item 13); this SPEC satisfies no part of it
and asserts nothing about it.
