# Graph View Shell, Lenses And Controls

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.6 (FR-2, FR-3, FR-13–FR-17), §6.1 (NFR-3), §7 (C-1), §9 (AC-6–AC-8, AC-10, AC-15) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned to amended FR-16 — C-1 withdrawn, AC-6 rewritten to a documented-prerequisites criterion | /aid-specify |
| 2026-07-28 | Final-gate finding fixed — the `GV*` assertions now name their containing suite (`tests/canonical/test-graph-view-shell.sh`), matching features 010/012/013 | /aid-specify |
| 2026-07-28 | Added the render-transform invariant to the shared module's contract (`.mjs` is in `render.py`'s `_TEXT_EXTENSIONS`, so no `canonical/…` path and no filename placeholder, in code or comments) and made GV02's comparison basis same-tree, with GV08 asserting render invariance; specified zero-row nodes — materialised as complete `Node` records from `kb_gaps` (`id` + `name`), marked via `nodeLabels`, with grouping/density/focus behaviour fixed and the mismatch alarm structurally excluded from firing on them | Owner review |
| 2026-07-28 | Fixed CRITICAL "AC-15 mechanism contradicts feature-006": coverage predicate moved to a shared Node/browser module (`canonical/aid/scripts/graph/coverage-predicate.mjs`) with an explicit runtime boundary; `kb_gaps` demoted to a recorded generate-time result the view verifies against and fails loudly on; `kb-unbacked` fixed as lens-only; AC-15 scoping closed per owner decision; reliance on feature-004's never-`inferred` `evidence_provenance` invariant stated | Owner review |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles then the reopens STATE.md records — Q19, Q20 (A-5 figure), Q21, and FR-4's one-line count of 2026-07-30 — the third of them caused by this SPEC's own findings; STATE.md Q9–Q21) and against the five A+ SPECs this feature consumes (001, 002, 003, 004, 005). Four load-bearing premises of the previous revision are void, not adjusted.** (1) **`Node.kind` was the id prefix, "never inferred from anything else."** §5.2 makes kind an **explicit column** and states that the renderer "reads `Kind` directly to choose node colour and shape; it never parses the id to recover kind." `Node.kind` is therefore re-defined as §5.2's seven-value enum read from `Source Kind`/`Target Kind`, and the id prefix is demoted to a separate field `Node.prefix` used only where a clause is about **where an id comes from** — the AC-2a agreement check, `int:` path semantics, and the Provenance lens's cross-side chain (D1a enumerates all three) — which also discharges feature-004's Open Item 2, whose three-way "kind" collision this rename resolves. Prefix-derivation was not merely superseded but **unsound**: `image` permits `int:` *or* `ext:`, so the prefix never determined the kind for that value. (2) **The table is TEN columns**, so the loader's header literal, delimiter, cell indexing and column-count assertion are rewritten against feature-003 D1, and cell splitting now has to respect the `\|` escape D1 introduces because a `fact` display name reproduces a KB anchor string verbatim. (3) **`relationships.md` now carries a `## Coverage notes` section** (FR-9a) with a totally-ordered extra-row block (feature-003 D7a-1); the table parser is bound to feature-003 D1's stop rule so FR-3/AC-S2 hold structurally, and a **second, explicitly-scoped reader** (`parseCoverageNotes`) reads the notes for **reporting only**, never for graph membership. (4) **The claim that the graph "adds no colour token" is void** (feature-002 Open Item 4, routed here): the palette is **eight category colours plus one per value of §5.2's `Kind` enum**, it must be declared as **CSS custom properties** because `contrast-check.mjs` cannot see anything else, and the new pairs target **3:1** per WCAG 2.2 SC 1.4.11 (Level AA). Also rewritten: the graph is **live** (`d3-force` + PixiJS/WebGL, Q9), so the design-pressure block arguing SVG-versus-WebGL on accessibility grounds is struck and the reserved `validate-visuals.mjs` T2 exclusion becomes a **recorded no-op**; **filtering is required** (FR-6a) rather than one of FR-14's controls, and it is load-bearing for legibility at fourteen categories against eight colours (feature-001 D5a); the **control surface is specified** (FR-14a) — three filter axes, an orphan toggle, filters that compose with lenses, `density` as view density and not physics, and the **two node gestures**; the **Overview lens's grouping model** changes (sub-document nodes fold into their parent document, `concept` nodes group by relationship category because they have no parent document by construction); the **Coverage lens and the predicate are re-keyed from the `int:` prefix to `Kind = source-artifact`** (feature-004 Open Item 1, AC-15 as re-keyed), and `kb-unbacked` is re-scoped off the `kb:` prefix, which the widened node model turned into a Q17 proxy; **AC-21's completeness-in-DOM trap** is closed by a data-derived control manifest with a two-way DOM assertion; and **AC-9's check-to-surface mapping** is stated as the requirement demands. Discharged from other features: feature-001 Open Item 7 (the eight-colour assignment), feature-002 Open Item 4 (the palette), feature-003 Open Items 9 (label shortening) and 15 (the duplicate-heading suffix — discharged by removing the dependency rather than by claiming a verification), feature-004 Open Items 1 and 2, and feature-005 Open Item 7 in part. No measured figure is asserted anywhere: every number here is a contract count, an enumeration made on the spot, or a labelled design choice. *(Corrected 2026-07-30: this row read "then **two** reopens; STATE.md Q9–**Q20**" — a count standing in for an externally-owned set (Q19's rule) written hours before the **third** reopen this SPEC's own findings caused was recorded, and a source list that stopped one entry short of the owner's ruling **on those findings**. The reopen count is now a citation and the source range reaches Q21.)* | /aid-specify |
| 2026-07-30 | **STATE.md Q21 is consumed — the owner's ruling on this SPEC's own two findings — and STATE.md Q25 item 2's executed decision is applied.** Q21 was never read by the 2026-07-29 revision, and four clauses were wrong as a direct result: D6d quoted FR-13's **superseded** wording, Open Item 2 scheduled the `{document, concept}` narrowing as an unmade **author** decision when the owner had already made it, Open Item 1 routed FR-14a's `web-page` open target as an open **choice** when the owner had already chosen `./external-sources.md`, and Open Items 5 and 6 stood open after feature-006 discharged both. All are re-framed as settled; **no behaviour changes**, because the mechanism this SPEC implements was already the one the owner ruled for. Q21's refinement to Q17 — *a prefix is correct when the clause is about where an id comes from, wrong when it is about what class a node belongs to* — then decides the one clause left standing on the wrong side of it: `kb-unbacked`'s **test** is re-keyed from "an incident edge to a node whose `prefix` is `int:`" to `kind === 'source-artifact'`, which closes feature-006's proxy-sweep row 13 here rather than routing it, and removes a literal (`int:`) that was never in `Node.prefix`'s value space. **Q25 item 2 applied:** `RELATION_CATEGORY` is **authored in `coverage-predicate.mjs`** and read from there — it was declared in the browser-only `graph-model.js`, which feature-006's D6 forbids the Node side importing, so its F6 counter, AC-G5, GL12 and GL17 had no reachable data source; GV05 becomes a check inside one file and GV01 is unaffected on both sides. Also fixed in the same pass: **feature-006 is added to § Source's gated inputs** (it is now A+ and this SPEC consumes its D2 semantics, its `COVERAGE_BEARING` selection and its `kb_gaps` entry shape); five expired citations into re-specified upstreams (`clause` → `qualifier`; the detector is `detect-kb-gaps.mjs`, shape (b); Open Item 3's owner is **feature-003**, not feature-004; Open Item 8's selection is **made**, and its two inbound co-owned halves added; the `concept-merge-candidates` row carries the count and the two reach counters sharing its `note`); **four contract holes** — the Overview fold had no carrier in `LensState`/`ViewModel` (`expandedGroups` + `foldedInto` + the group disclosure), the `'document'` partition was specified two ways for `source-artifact`, the two enumerable filter axes named an unreachable runtime source, and the fatal-load-error surface contradicted "exactly two live regions"; AC-S3's fixture, which was unconstructible over one id and undecisive over two; D5a's verified-mechanism row, whose named line was wrong **by execution** (the third `extractVars` call returns `component-css.css` line 4, not line 37, and harvests zero custom properties); D7b's two overstatements of what L2 reaches; GV07's dependency on a sibling's internals; and test hooks for AC-6's prerequisite text and AC-8's controls-remain-usable half. **Q26 note:** six of these are editorial and would batch to the item-9 pass; they are fixed here because the file is open for fifteen mechanism findings anyway, so the exception is deliberate and avoids a second touch | /aid-specify |
| 2026-07-30 | **The Overview fold carrier is re-derived as one contract, and five independent findings are closed.** The carrier added earlier the same day was a set of separate clauses across three types, and five defects were the direct consequence. `groups[].folded` counted the **undrawn** members while three sites gated the disclosure's *existence* on that count being non-zero, so expanding a group deleted the only control that could collapse it again, `aria-expanded` could never render `true`, and the sole reset was re-applying the whole Overview patch — breaking **AC-8** and contradicting the "never `disabled`" promise the Component row makes for that control. D6c clause 1 listed a `document` among the branches with "no member to fold", against its own opening sentence and the partition table two rows above, so read literally nothing folded. `visibleNodes` both added a focused node and subtracted folded ones with no precedence, reachable by selecting a `section` and then choosing `'document'` from the grouping select. `counts.hiddenEdges` counted edges still *in* `visibleEdges` while `counts.hiddenNodes` counted nodes *removed* from `visibleNodes`, and `counts.edges` was undefined, so `canvasAlt` and the table caption could not report a consistent pair. And consumer rule 7 made edge membership **a per-renderer convention**, falsifying D3's "interpreted exactly once, in `project()` … not a convention the two renderings are asked to honour". **The re-derivation is three clauses over three fields**, not five patches: `groups[].foldable` — the count the fold *governs*, **independent of expansion** — with `groups[].expanded`, which is the `aria-expanded` value verbatim; `foldedInto` demoted to the fold's **record** rather than an instruction; and a second projection field **`edgeFold`**, carrying each surviving row's resolved endpoints or the literal `'collapsed'`. `project()` therefore states the drawn set itself, D3's promise holds unchanged, rule 7 shrinks to "read `edgeFold`", and both hidden-counters become complements of the loaded whole on their own axis. Focus resolves through the same map, which settles the precedence — the fold is applied **last and wins** — and `nodeEmphasis` is keyed over `visibleNodes`, so no class can land on a node neither rendering draws. **The no-synthesised-aggregate-edges decision is kept**, with its evidence written in (feature-003's `rel_row_key`, its SPEC.md:1306, made unique per row by **V5**, its :1777) and its cost restated. Independently: D1a's "three uses, and no fourth" was **false** — D6c, D7b and D9 each split `image` in-repo versus external, a distinction only the prefix carries — so the numeral becomes an enumeration (Q19) and the test is sharpened to *a prefix standing in for the kind*, under which all three are admissible and are now defended in place; the missing-test-hook class opened by cycle 1 is closed at its two remaining instances (**GV25** for FR-15's no-privileged-default, **GV26** for FR-6's grouping dimension) with AC-10's greppable half folded into GV01, and `INITIAL_LENS` gains the `filters.text`, `focus.depth`, `zoom` and `sort` values GV25 needs in order to be total and decisive; the Footer row's "the **only** `./*.md` links L2 sees" was false, since `<noscript>` links `./INDEX.md`, and it and the Validator-surface row now name **three** targets; D5a row 3's 7/2/4 are `component-css.css`'s own line numbers, so `kb.html`'s 22/17/19 are stated beside them; and GV24's appositive mis-stated both its own scope and GV15's | /aid-specify |
| 2026-07-30 | **Three sentences the two preceding passes added are corrected, and one change-log list completed. Every edit corrects what a sentence *claims* about a mechanism; no mechanism, field, count or test obligation changes.** AC-8a part 1's hook **keeps** `counts.edges`, and the criterion's own words settle that: AC-8a part 1 is "checkable by comparing the **rendered count** against `relationships.md`" (REQUIREMENTS.md), and `counts.edges` is the drawn count — what the header, `canvasAlt` and the table caption report (D4). What was wrong is the reason appended to it, which claimed that count *survives* a folding dimension, the one property it does not have: under `grouping: 'document'` a `structure` row from a document to its own `section` is `'collapsed'` (D6c clause 2), so the drawn count falls short of that category's row count by exactly the collapsed rows and an implementer following the sentence writes a failing test. The assertion is therefore stated at `grouping: 'none'` — where the criterion's equality is well-posed at all — and the shortfall is named rather than denied. Q19's fourth class, "a sound conclusion resting on a false premise", and it arrived *in prose written to defend a field swap*, which is the cost of defending rather than correcting. D7b's `document` row and the Validator-surface **L2** row both had L2 resolving a relative `.md` link against `--kb-dir`; on disk that variable is assigned at `validate-html-output.sh`:35/:43 and read only by L2's progress line at :384, while resolution is `HTML_DIR=$(dirname "$HTML")` at :62, used at :391 — so both now state the **file's own directory**, which the Footer row already did, and record that the flag sets no basis whatever its own help text says. Nothing delivered changes (`graph.html` sits in `.aid/knowledge`, so the two coincide), but AC-9 makes this SPEC the authority for the mapping. **GV26** asserted a "real **focusable** `<option>`"; an `<option>` in a native `<select>` takes no tab stop and never becomes `document.activeElement`, so the row was unrunnable as literally written — the word is struck, leaving the obligation exactly as D3's `grouping` row states it, with focus belonging to the `<select>` that GV17's `data-control` bijection already covers. **Both defect classes were then swept and return nothing further:** every appended justification in the `GV*` table, in the AC-7/AC-8a hook and in § Validator surface was re-read against the field it names, and every claim this SPEC makes about a reused script was re-read or re-executed on disk — S2's two CDN greps, NM.1's awk (100 000-byte non-payload block, `text/markdown` skipped), L1's `id="…"` set membership, A3's three signatures, A5's `:focus-visible`, `assemble.sh`'s three real flags and its existence/non-emptiness loop over the three shell parts, `build-kb-index.sh`:471's `find` line, `render.py`'s `_TEXT_EXTENSIONS` and `render_lib.py`'s `line.lstrip().startswith("#")` comment skip, `contrast-check.mjs`'s eleven pairs at 4.5 with its five selector blocks at 2/4/7/37/588 in `component-css.css` and 17/19/22/52/601 in `kb.html`, and `validate-visuals.mjs`'s three selectors and non-`file://` abort — all hold as stated. Also: the row above listed **three** values `INITIAL_LENS` gained where four were missing, so `filters.text` is added to it (STATE.md § Editorial queue **E9**, confirmed from the fix author's report because the re-specification is uncommitted and cannot be diffed) | /aid-specify |

## Source

- REQUIREMENTS.md §5.6 — **FR-13** (the four preset lenses; the **Overview grouping model as amended
  2026-07-29**; the **Coverage lens's two domains as amended 2026-07-29 by owner decision** — unbacked
  **`document` and `concept`** nodes and undocumented **`Kind = source-artifact`** nodes, with an unbacked
  `fact` an integrity warning (STATE.md **Q21** item 1); and the finding that the **Impact lens already
  *is* the local-graph view**), **FR-14**
  (full manual controls available at all times; presets are entry points, not modes), **FR-14a**
  (*new 2026-07-29* — the control surface: the three filter axes, the orphan-node toggle, filters that
  **compose** with lenses, `density` as view density and **not** an exposure of `d3-force`'s physics
  parameters, the **two node gestures**, and the **`web-page` open target as amended the same day by
  owner decision** — `./external-sources.md`, the file that resolves the key, the URL form having been
  rejected (STATE.md **Q21** item 2)), **FR-15** (no purpose is privileged as the default),
  **FR-16** (quality and interaction over packaging; C-1 withdrawn), **FR-17** (runtime JS is
  mandatory), **FR-18** (*rewritten* — the renderer is **decided**: `d3-force` + PixiJS (WebGL), 2D),
  and §5.6's four recorded consequences of dropping the packaging restrictions
- REQUIREMENTS.md §5 — **FR-2** (the view this feature shells is **live, continuously simulating,
  interactive**), **FR-3** (the table is the **single input** to the graph)
- REQUIREMENTS.md §5.2 — the **ten**-column table and the **closed `Kind` enum** with its
  required-prefix pairing table; the statement that the renderer reads `Kind` directly and **never
  parses the id to recover kind**; and that **`image` is the one branching case** (`int:` *or* `ext:`)
- REQUIREMENTS.md §5.3 — the per-kind id grammars; that a **`concept` id is deliberately not
  document-scoped**, which is why the Overview lens cannot group concepts by document
- REQUIREMENTS.md §5.4 — **FR-6** (category is a grouping dimension), **FR-6a** (*new* — filtering and
  highlighting by relationship category is a **required feature** with its own criterion), **FR-6b**
  (category governance; **the colour palette does not grow with the category count**)
- REQUIREMENTS.md §5.5 — **FR-9** (both artifacts land in `.aid/knowledge/`; companion assets in a
  subdirectory named so the KB index generator ignores them), **FR-9a** (*new* — the `## Coverage
  notes` section, which sits **after** the table so FR-3 still holds), **FR-12** (reuse
  `/aid-summarize`'s HTML toolchain at the script layer)
- REQUIREMENTS.md §6.1 — **NFR-1** (WCAG AA), **NFR-2** (the accessible table view is a **peer**
  rendering and the conforming alternate version), **NFR-3** (every lens applies to **both**
  renderings), **NFR-4** (reduced motion is the **fallback**, not the default), **NFR-5** (colour is
  never the sole carrier — node type by colour **and shape**, category by colour **and line style**,
  relationship name on hover/selection, direction by an arrowhead whose **absence** is the signal for a
  symmetric relation; SC 1.4.1, Level A), **NFR-6** (*widened* — every interactive gesture has a
  keyboard equivalent, dragging exempt; SC 2.1.1, Level A), **NFR-7** / **NFR-8** (the frame-rate floor
  and the measured ceiling — both feature-008's and feature-010's to satisfy; this feature hosts them)
- REQUIREMENTS.md §7 — **C-2** (canonical authoring, rendered per profile), **C-4** (reuse, never fork,
  `/aid-summarize`'s scripts), **C-5** (Node ≥ 20; Playwright degrades gracefully, **and** its extended
  second failure mode: provisioned but unable to draw), **C-8** (*new* — `graph.html` is **deliberately
  not** dashboard-reachable; the local-file open is the intended access path)
- REQUIREMENTS.md §8 — **A-4** (the entry point is `graph.html`, companions beside it), **A-6**
  (self-built fixtures), **A-5** (void; **no bench figure is stated anywhere and none is stated here**)
- REQUIREMENTS.md §9 — **AC-6** (*extended* — "renders successfully" means the live simulation runs, and
  **WebGL support is itself a documented runtime prerequisite**), **AC-7**, **AC-8**, **AC-8a** (*new* —
  filtering present and functional in both renderings, filters **compose** with lenses, and **at most
  eight** distinct category colours), **AC-9** (*scoped* — the DOM-level structural and a11y checks
  apply to the page structure and the table view, **not** to the canvas; the SPEC must state which
  check applies to which part), **AC-10**, **AC-15** (*re-keyed* — the equality binds **`Kind =
  source-artifact`** only), **AC-21** (*new* — every interactive control keyboard-operable)
- STATE.md `## Cross-phase Q&A` — **Q9** (the graph is live; the canvas is visual-only), **Q11** (edge
  encoding: directed, colour + line style, hover-only names), **Q13** (concept merge; the performance
  floor; concept click target), **Q14** (the `Kind` columns and the ten-column consequence), **Q17**
  (proxy-keyed clauses — the standing sweep instruction), **Q18** (the reopen principle: *if there is a
  defect, the A+ is false*), **Q19**/**Q20** (cross-feature defect classes; "verified by count" is a
  claim to re-derive, not a credential; an Open Item routed **into** a gated SPEC is a **pending
  reopen**, not a note), **Q21** (the owner's ruling on **this SPEC's own two findings** — FR-13's
  `{document, concept}` narrowing and FR-14a's `./external-sources.md` target — together with the
  refinement Q17 needed: *a prefix is correct when the clause is about where an id comes from, and wrong
  when it is about what class a node belongs to*), **Q25** (item 2, the executed decision that
  `RELATION_CATEGORY` is authored in `coverage-predicate.mjs`; and the converse of Q20 (loader sync) —
  when an upstream SPEC is re-gated, every downstream draft written against its previous revision is
  re-swept), **Q26** (mechanism items reopen and re-gate; **editorial** items are classified in the
  routing item's own text and batched, never denied)
- Gated inputs consumed as fixed contracts: **feature-003** (D1 column contract and file skeleton, D1a
  the `Kind` enum, D2 the id grammars, D5 display names, D7 row order, D7a/D7a-1 the coverage notes,
  V1–V15), **feature-001** (D5 the fourteen categories, D5a the eight-colour ranking), **feature-002**
  (Q9's decided architecture, D8 the palette contrast hole, D9 the AC-21 route), **feature-004** (the
  node kinds and the two node streams), **feature-005** (what the table actually contains), and
  **feature-006** (*added 2026-07-30, gated A+ that day* — its **D2** predicate semantics and the
  direction rule of condition 3, its **D2a** `COVERAGE_BEARING` selection and the
  `coverage-bearing.yml` copy GV04 binds, its **D6/D6a** runtime boundary and lens/ledger asymmetry, and
  its **D6** `kb_gaps` entry shape. It was drafted concurrently with this SPEC rather than ahead of it,
  which Q26 § Dependency-ordered gating names as the violation that cost both of its HIGH findings; the
  converse re-sweep that rule requires is what this list was missing)

**The lens view-model is a first-class contract, and wave 3 makes that structural rather than
aspirational.** This feature is the first feature of wave 3 and it **blocks feature-008 (the canvas)
and feature-009 (the table view)**. Both render inside this shell and both consume the projection
defined here. Everything those two features need in order to interpret a lens identically is therefore
fixed *here* and not negotiated later: the node and edge records, the palette and its non-colour
channels, the filter axes, the composition rule, the two gestures, and the control manifest. A loose
interface here is the direct route to violating **NFR-3** and **AC-7** at integration time.

**Dependency position.** Blocked by **feature-003** (the schema it renders from) and, for real data,
**feature-004** and **feature-005**. Blocked by **feature-002** for three statements only — the
runtime-prerequisite text (AC-6), the vendored-bundle shape, and the verdict on whether the drawing
layer can consume computed CSS custom properties at acceptable cost (feature-002 D8). Everything else
here is renderer-independent by construction. Blocks **feature-008** and **feature-009**.

**Shared acceptance criteria.** AC-7, AC-8a and AC-21 are shared with feature-009 (table side) and
AC-15 with feature-006 (the ledger owner). All four are mutual obligations and no owner may consider
them met alone.

## Description

The graph view is something a reader opens and uses, and as of the 2026-07-29 redesign it is **alive**:
nodes drift toward equilibrium and keep simulating, dragging one pulls its neighbours, hovering focuses
a neighbourhood and dims the rest. A reader who prefers no motion gets a settled picture instead — that
is the fallback, not the default. How the view is packaged is deliberately unconstrained: it may be one
file or several, it may fetch from a hosted library, and it may be produced by a build step. What
replaces the packaging rule is an obligation of disclosure — whatever the view needs in order to work,
including a working WebGL context, is written down where a reader will see it.

Everything the view shows comes from the relationship table and nothing else. There is no second
extraction, no parallel path, no chance of the picture and the table telling different stories. The
table now carries each endpoint's **kind** in its own column, so the view reads the kind rather than
guessing it from the identifier — which is what lets a defined concept, a document section and a claim
with a checkable source look like three different things on screen even though all three identifiers
begin the same way. The file also carries, after the table, a short report of what the run could see and
what it deliberately did not; the view reads that report to tell the reader how thin or complete the
picture is, and it never lets that report decide what appears in the graph.

Edges are drawn with direction, because the table records both readings of every relationship and the
old picture was throwing that away. A relationship that reads the same in both directions gets no
arrowhead, and the absence of the arrow is itself the signal. Relationship names are not painted on
every line — they appear when a reader hovers or selects, and they are always there as plain text in
the table view.

Colour carries meaning here, and it is not free. There are more relationship categories than any
palette can distinguish, so a fixed number of them hold a dedicated colour and the rest share colours
and are separated by line style. What makes the picture legible is not more visual channels: it is
**filtering**, which is why filtering is a required feature with its own acceptance criterion rather
than a convenience. And because a colour that lives inside drawing code is invisible to the project's
contrast checker — verified, and the checker produces neither a warning nor a failure in that case —
the palette is declared as style variables the checker can read, and the checked pairs are held to the
threshold the accessibility standard sets for graphical objects rather than the one it sets for text.

On top of that the view offers four named starting points, one for each of the purposes this work
serves. One highlights what is unbacked or undocumented and dims the parts that are well-formed. One
collapses the picture so a newcomer can see its shape, folding a document's sections and claims back
into the document while grouping defined concepts by what kind of relationship they participate in,
because a concept belongs to no single document by construction. One takes a selected node and shows
its neighbourhood out to a depth the reader chooses. One shows only the chains from Knowledge Base
content down to source and external origins.

These are entry points, not modes. Arriving through one never takes controls away, and — the part that
had to be made mechanical rather than promised — arriving through one never clears the filters a reader
has already set. Selecting a node and opening the thing it stands for are two different gestures, so
exploring never navigates away by accident. Every one of these controls is a real, focusable element in
the page, and the check that proves it is not "can I reach the controls that exist" but "is the full
set of controls the requirements name actually present" — because a control painted onto the drawing
surface would pass the first question and fail the standard.

## User Stories

- As a **newcomer to the project**, I want a lens that folds each document's sections and claims back
  into the document and groups defined concepts by relationship category, so that I can see the shape
  of the project without a picture dominated by sub-document detail.
- As a **maintainer/architect**, I want a lens that shows a selected node's neighbourhood to a depth I
  choose, so that I can answer "what does this change touch" before I make it.
- As a **maintainer/architect**, I want to filter by relationship category, node kind and provenance
  **without losing the lens I arrived through**, so that a lens narrows rather than restarts my
  investigation.
- As a **maintainer/architect**, I want a single click to select a node and a separate, deliberate
  gesture to open the artifact behind it, so that exploring the graph never navigates me out of it.
- As a **reader who cannot rely on colour**, I want node kind carried by shape and relationship
  category carried by line style as well as colour, and every relationship name available as text, so
  that the picture is not a colour puzzle.
- As a **reader using a keyboard only**, I want every control the requirements name — each lens, each
  filter axis, the orphan toggle, select, and open — to be a real focusable element, so that none of
  them is trapped on a drawing surface I cannot reach.
- As a **maintainer/architect**, I want the view's runtime prerequisites stated plainly, including
  whether it needs a working WebGL context, so that I know before I rely on it where it will function.
- As a **KB reviewer**, I want the view to render only from the relationship table, so that what I see
  on screen is exactly what I can verify in the file — and I want the run's coverage report visible
  beside it so I can tell a thin Knowledge Base from a failed extraction.

## Priority

Should

*In scope and required by §4; ranked Should rather than Must only because §10 states explicitly that
`relationships.md` and the gap ledger ship usefully with no view at all. This is a schedule-risk
ranking, not a statement that the view is optional.*

## Acceptance Criteria

- [ ] **AC-6** *(as rewritten 2026-07-28, extended 2026-07-29)*: Given the artifact as delivered by
      whatever packaging feature-002's Stage 3 settles, when it is opened by its documented entry point,
      then the **live simulation runs** — nodes drift toward equilibrium, hovering focuses a
      neighbourhood and dims the rest, and dragging a node pulls its neighbours — and its runtime
      prerequisites are documented explicitly, **WebGL support among them**, alongside network access,
      companion asset files and any build output.
- [ ] **AC-7** *(shared with feature-009 — mutual obligation)*: Given the generated view, when each of
      the four preset lenses is applied in turn, then all four are present, each visibly changes the
      view, and each applies to both the graph rendering and the table rendering.
- [ ] **AC-8**: Given a reader who arrived through a preset lens, when they use the grouping, density,
      filter and zoom controls, then all of them remain usable — the preset has not locked the view.
- [ ] **AC-8a** *(shared with feature-009)*: Given the generated view, then (1) **every** category in
      the loaded vocabulary is offered as a filter value and selecting one reduces the rendered edge set
      to exactly the rows carrying that category, checkable against `relationships.md`; (2) filters
      **compose** with the four preset lenses rather than resetting them; and (3) the palette assigns
      **at most eight** distinct category colours, with further categories reusing colours and being
      disambiguated by line style and by filtering.
- [ ] **AC-9** *(as scoped 2026-07-29)*: Given `graph.html`, when the existing structural and a11y
      checks are run, then each check applies to the part of the artifact that can satisfy it — page
      structure and the table view, **not** the canvas, which carries only a text alternative — the
      table view is keyboard-navigable and screen-reader usable, and a reduced-motion preference yields
      a settled graph. The check-to-surface mapping is stated in this SPEC (§ Validator surface).
- [ ] **AC-10**: Given the generated view, when its data source is examined, then it renders from
      `relationships.md` alone, with no second extraction path. Reading the `## Coverage notes` section
      of that same file for **reporting** is not a second path; nothing in the notes may decide graph
      membership.
- [ ] **AC-15** *(shared with feature-006 — mutual obligation; **re-keyed 2026-07-29**)*: Given a
      generated ledger and a generated view, when the Coverage lens is applied, then it surfaces exactly
      the gaps present in the ledger, the equality binding **`Kind = source-artifact`** only. The
      lens-only `kb-unbacked` signal has no ledger counterpart and its presence does not breach this.
- [ ] **AC-21** *(shared with feature-008 and feature-009)*: Given every interactive control the
      requirements name — selecting a node, opening its artifact, choosing a preset lens, and filtering
      by category, plus FR-14a's node-kind and provenance axes and its orphan toggle — when each is
      driven by keyboard input only, then each is operable; **and** the control set is asserted to be
      **complete in the DOM**, not merely that the DOM controls present are reachable. Node dragging is
      excluded per NFR-6's path-dependent exemption.
- [ ] Given the generated view, when its default state is inspected, then no one of the four purposes is
      privileged as the default layout (FR-15). *Hook: **GV25**, over `INITIAL_LENS` and the four patches.*
- [ ] Given the relation categories feature-001 establishes, when the reader groups the view, then
      relation category is available as a grouping dimension (FR-6). *Hook: **GV26**.*

Spec-authored criteria, numbered under the `AC-S<n>` scheme **feature-003 introduced and offered to the
sibling SPECs** (feature-003 § "The `AC-S<n>` scheme"), so task DETAILs and test plans can cite them:

- [ ] **AC-S1**: Given a `relationships.md` whose header row is not byte-identical to feature-003 D1's
      ten-column literal, when the view loads it, then the load fails visibly with the expected and
      actual header quoted — no positional guessing, no tolerated column count.
- [ ] **AC-S2**: Given a `relationships.md` carrying a `## Coverage notes` section, when the table
      parser runs, then it stops at the first line that is not a table row and reads no part of the
      notes; and the separate notes reader contributes nothing to `visibleNodes`, `visibleEdges`,
      `edgeFold` or any emphasis class.
- [ ] **AC-S3**: Given any node, when its `kind` is determined, then it comes from the `Source Kind` /
      `Target Kind` cell and from nowhere else. Asserted **decisively rather than by grep**: over a
      fixture containing two **`ext:`** nodes carrying different keys, one with `Kind` = `web-page` and
      one with `Kind` = `image`, their colour token and glyph differ. That is the one construction no
      id-deriving implementation can produce, and feature-003 D1a says why: for an `ext:` id "`image`
      versus `web-page` **cannot be recovered from the key**", so it is "the single place in the schema
      where `Kind` is unchecked by construction" and V13 has no fragment tier there. *(The obvious
      fixture — two `kb:` nodes "differing only in the `Kind` cell" — is not the one, and both halves of
      why are worth stating: `nodes` is a `Map<string, Node>`, so one id is **one** node and that case is
      D1c check 5's `kindConflict` rather than this criterion; and once the ids differ they differ by
      grammar, which feature-003 **V13 tier 2** makes kind a function of, so an id-deriving
      implementation would pass while violating "from nowhere else".)*
- [ ] **AC-S4**: Given the palette, when `graph.html` is inspected, then every node-kind colour and
      every category colour is declared as a **CSS custom property** whose name matches
      `contrast-check.mjs`'s extraction charset, in a block that script extracts, and none appears as a
      literal in drawing code.
- [ ] **AC-S5**: Given the fourteen-category vocabulary, when each category's encoding is read, then the
      (colour, line-style) pair is **unique per category** and **no two categories sharing a colour
      share a line style**.
- [ ] **AC-S6**: Given the four presets, when their patches are inspected, then none contains a key in
      the `filters.*` namespace — so a preset cannot reset a filter by construction (AC-8a part 2).
- [ ] **AC-S7**: Given the control manifest, when it is checked against `GraphModel.categories`,
      `keys(KIND_ENCODING)`, `PROVENANCE_VALUES` and `PRESETS`, then every value of every enumerable
      axis has a manifest entry — so a vocabulary that grows cannot leave a filter value unoffered. The
      two closed enums are checked in the **same run** against
      `canonical/aid/templates/graph/relationship-schema.yml`'s `kinds:` and `provenance:` lists
      (feature-003 D1), which the suite reads from disk and the page cannot (D3, D8 assertion 1).
- [ ] **AC-S8**: Given a node whose stored display name exceeds the label budget, when it is labelled,
      then the shortened form is used only for drawing and for the table's collapsed cell, the
      **accessible name is never the shortened form**, and shortening never changes when a filter or a
      lens changes.

---

## Technical Specification

> **Written against a decided architecture.** FR-18 is no longer a renderer selection: the architecture
> is `d3-force` for physics plus **PixiJS (WebGL)** for drawing, 2D, and the canvas is **visual-only**
> with WCAG AA carried by the accessible table view as the conforming alternate version (Q9, NFR-2).
> Two consequences shape this SPEC. First, the previous revision's design-pressure block — which weighed
> SVG against WebGL on accessibility-tree grounds and leaned on A-5's "node counts land in the hundreds"
> — is **struck**: A-5 is void, the accessibility trade-off was closed by making the canvas visual-only,
> and the renderer is not this feature's to weigh. Second, the recommendation that block arrived at is
> nevertheless the one implemented here, for a reason that survives the supersession: **one plain
> structure of nodes, edges and current focus, decoupled from drawing, read by the canvas, the table and
> the accessibility layer alike.** That is what keeps three surfaces from drifting apart, and it is why
> `ViewModel` below carries labels and announced text as fields rather than leaving each renderer to
> compose its own.
>
> **No figure in this SPEC is a measurement.** Q20's standing consequence is that "verified by count" is
> a claim to re-derive. Counts appearing below are one of three things, and each is labelled: a
> **contract count** (ten columns, seven kinds, fourteen categories, eight colours, four line styles), a
> set **enumerated on the spot**, or a **labelled design choice** (the label budget, the depth and
> density ranges). Where a quantity would be a measurement — frame rate, bench size, payload — this SPEC
> states the owner and asserts nothing.

### Data Model

**No persistent schema and no new stored artifact.** `relationships.md` (feature-003) is the only
durable store and the only input (FR-3, AC-10). This feature adds four in-memory structures, all built
in the browser at load time from that one file.

#### D1. `GraphModel` — the parsed table (built once, never mutated)

Parsed from the **ten** columns feature-003 D1 fixes: `Source Id`, `Source Kind`, `Source Name`,
`Target Id`, `Target Kind`, `Target Name`, `S2T Relation`, `T2S Relation`, `Provenance`, `Observation`.
There is no `Strength` column and therefore **no strength-driven visual encoding anywhere in this work**
(Q1, resolved 2026-07-28 and not reinstated by the widening).

| Field | Type | Built from |
|-------|------|-----------|
| `nodes` | `Map<string, Node>` | the union of `Source Id` and `Target Id` over all rows, plus the zero-row nodes materialised from `kb_gaps` (D10) |
| `edges` | `Edge[]` | one entry per data row, in table order — which is feature-003 D7's total order, class-0 rows a contiguous prefix |
| `rowCount` | integer | data rows accepted by the loader |
| `categoryOf` | `Map<string, string>` | relation → category (FR-6). A build-time constant — `RELATION_CATEGORY`, **authored in `coverage-predicate.mjs`** and read from there (D10; STATE.md Q25 item 2) — taken from feature-001's vocabulary and **not** parsed from the page, because the vocabulary is a shipped definition rather than data about the project, so carrying it in code is not a second extraction path (AC-10) |
| `categories` | `string[]` | the vocabulary's category set, in feature-001 D5's declared order. The filter axis and the palette both read **this**, never a literal list (AC-S7) |
| `coverageBearing` | `Set<string>` | the coverage-bearing relation subset — condition 3 of the predicate at D10. Read from the shared predicate module, not from the page |
| `recordedGaps` | `Array<{id, name, severity, qualifier}>` \| `null` | the `kb_gaps` frontmatter list feature-006 writes at generate time over feature-004's **enumerated `source-artifact` set**. The fourth key is `qualifier`, matching the emitted block byte for byte — it was `clause` here until feature-006 renamed it, because the values are feature-004's four `qualifier` values and never FR-21's three clause names (feature-006 D6, its Open Item 4(a)). `name` is required, not optional: it is the only source of a display name for a zero-row node. `null` when the key is absent |
| `integrity` | `{status, viewOnly, ledgerOnly, orphans, unbackedFacts}` | the result of the load-time checks at D1c and D10 |
| `nameConflicts` | `Array<{id, kept, seen}>` | ids whose display name differs between occurrences (feature-003 **V8** forbids this at generate time) |
| `kindConflicts` | `Array<{id, kept, seen}>` | ids whose `Kind` differs between occurrences — **new at ten columns**, and the same V8 invariant. Recorded separately from `nameConflicts` because a kind conflict changes colour, shape and every kind-keyed filter, whereas a name conflict changes only a label |
| `coverage` | `CoverageReport` \| `null` | the `## Coverage notes` section, read by the **separate** reader at D2d. Reporting only |
| `sourceStamp` | string | the generator attribution read from `relationships.md` frontmatter |

##### D1a. `Node`

`Node = { id, kind, prefix, name, shortLabel, glyph, kbDoc, degree, degreeByKind }`

- **`kind` is one of §5.2's seven enum values** — `document`, `concept`, `fact`, `section`,
  `source-artifact`, `image`, `web-page` — taken **from the `Source Kind` / `Target Kind` cell of the
  row the node was first seen on**. §5.2 states the rule this field exists to obey: "The renderer reads
  `Kind` directly to choose node colour and shape; **it never parses the id to recover kind**." A value
  outside the enum is a **load error**, not an eighth bucket: `Kind` is a closed vocabulary loaded
  fail-closed, exactly like the relation vocabulary (§5.2, feature-003 D1a).
- **`prefix` is one of `'kb' | 'int' | 'ext'`**, parsed from the id. It is **not** the kind, and every
  clause that reads it is a clause about **where an id comes from or how it is spelled** — never about
  what class a node belongs to, which is Q21's refinement of Q17 and the test this field is held to.
  The sites are **enumerated, not counted**, the numeral having been itself a count standing in for a set
  this document kept growing (Q19): D1c check 4's AC-2a agreement assertion; `int:` path semantics, since an
  `int:` id *is* its repo-relative path with the prefix stripped, which lets the coverage predicate do
  ancestor matching with no extra field (D10); the Provenance lens's **cross-side chain**, the one thing the
  prefix names and no kind does (D6f); and the three tables that split `image` **in-repo versus external**
  — the `'document'` partition (D6c), the Open target (D7b), the label basis (D9). Those three decide a
  group, a target and a label from that split, so the test is stated sharply: a prefix read is a defect when
  it **stands in for the kind**, and `image` is the one kind spanning two sides (§5.2), so all three ask
  D6f's own question — *where does the artifact live* — about the one value whose `Kind` cell cannot answer
  it. `kb-unbacked`'s test was this family's real defect and is now kind-keyed (D6d).

  > **This is the rename feature-004's Open Item 2 left to this feature, and it is taken.** The previous
  > revision called the id prefix `Node.kind` and said it was "never inferred from anything else". Three
  > distinct things were called "kind" across the document set: feature-003's `Kind` column, feature-004's
  > former `nodes.tsv` field-3 `kind` (since renamed `artifact_class`), and this field. feature-004 removed
  > one and left the third to this feature's judgment. Splitting `kind` from `prefix` removes the second
  > collision and, more importantly, makes the §5.2 rule enforceable by name: a reader of this SPEC can no
  > longer satisfy "read the kind" by reading a prefix.
  >
  > **Prefix-derivation was never merely superseded — it was unsound.** §5.2 pins six of the seven kinds
  > to exactly one prefix but gives **`image` two** (`int:` *or* `ext:`), and `kb:` covers four kinds at
  > once. So the prefix determined the kind for no value of the enum except by accident. A prefix-derived
  > implementation would have drawn a document, a section, a fact and a concept identically, and would have
  > had no answer at all for an external image.

- `name` is the stored display name from the row — feature-003 D5's derived, never-authored value.
  **Never truncated** (feature-003 D5 says so explicitly, and routes shortening here as Open Item 9).
- `shortLabel` is the render-time abbreviation specified at **D9**. It is computed once at load over the
  **full** node set, never per projection, so a label cannot change when a filter changes (AC-S8).
- `glyph` is the shape token that carries `kind` **without colour** (NFR-5) — `KIND_ENCODING[kind].glyph`,
  copied onto the node so a consumer iterating `visibleNodes` needs no second lookup. There are now
  **seven** shapes, one per enum value, where the previous revision had three. The colour half of the
  encoding is deliberately *not* copied onto `Node`: it reaches consumers as a **token name** through
  `ViewModel.nodeEncoding` (D4), because the value must be resolved from CSS at draw time (D5a).
- `kbDoc` is the document part of the id, populated for `document`, `section` and `fact` — and
  **`null` for `concept`**. That is not an omission: §5.3 states that a `concept` id is "deliberately
  **not** document-scoped, and that follows from the merge rule", so there is no document part to take.
  This single `null` is what forces FR-13's amended Overview grouping model (D6c).
- `degree` and `degreeByKind` (a `Map<Kind, integer>`) are computed in one pass over `edges`. `degree`
  is the density control's sole input. Neither is an input to the coverage predicate — that predicate is
  edge-shape-aware (it asks *which* relation, in *which* direction, to *which* endpoint), not
  degree-based — so "the density control never hides a gap" is guaranteed by an explicit exemption in
  feature-008 rather than by two mechanisms sharing a counter.

  > `degreeByKind` replaces the previous revision's three fixed counters (`kbDegree`, `intDegree`,
  > `extDegree`), which were prefix-keyed. A map over the enum is the same information at the granularity
  > the model now has, and it is what lets the Coverage lens ask "does this concept touch any
  > `source-artifact`?" — a question three prefix counters could not express, because `int:` now spans
  > `source-artifact` **and** `image`.

- **No qualification field, deliberately, and this feature relies on an invariant it does not own.**
  `Node` carries no FR-24 qualification evidence and needs none. feature-004's `no-inferred-node`
  invariant fixes `evidence_provenance` to `declared | derived` and states as a hard rule that it is
  never `inferred`: a candidate only a reading would qualify goes to `candidates.tsv` with a
  `drop_reason` and is not emitted as a node. **feature-004 owns that invariant**; this SPEC depends on
  it and says so here so the dependency is visible. Its consequence is that feature-006's F4 filter —
  drop nodes whose sole qualification is `inferred` — has an empty domain and is no part of the shared
  predicate. Were the invariant relaxed, the predicate would need per-node qualification evidence *in
  the browser*, which `relationships.md` does not carry and FR-3/AC-10 forbid fetching separately. That
  is the concrete cost of relaxing it, and it is why the invariant is load-bearing rather than
  incidental.

##### D1b. `Edge`

`Edge = { key, sourceId, targetId, s2t, t2s, category, symmetric, provenance, observation, row }`

- `key` = `sourceId`, `targetId`, `s2t` and `t2s` joined by `U+001F` — the same US separator and the
  same four components as feature-003 D7's `rel_row_key`, so the browser's identity of an edge is the
  identity the validator deduplicated on. Stable across loads and unique by construction, because
  **V5** rejects two rows sharing a key.
- `category` = `categoryOf.get(s2t)`. An `s2t` absent from the vocabulary is a **load error**, not an
  `'uncategorised'` bucket: AC-2 already guarantees membership, so tolerating a miss would hide a
  feature-003 validation failure behind a working-looking view.
- **`symmetric` = `s2t === t2s`, and it is the arrowhead switch.** Q14 item 5 and NFR-5: an asymmetric
  relation is drawn with an arrowhead read Source→Target; **a symmetric relation is drawn with no
  arrowhead, and the absence is itself the signal.** Computing it here rather than in the draw loop is
  what stops the canvas and the table from disagreeing about whether a relationship has a direction —
  the table renders the same fact as "↔" versus "→". feature-003 **V4** accepts `S2T == T2S` as valid
  rather than as a disagreement, so this is a data property, not an anomaly.
- `provenance` is one of `declared`, `derived`, `inferred`. **A-3** makes it required by construction,
  so an empty cell is a load error rather than a defaulted value.
- `observation` is the `Observation` cell, empty-normalised: feature-003 D1 renders an empty cell as a
  single space, so a lone space becomes `''`.
- `row` is the 1-based table row index, carried so every surface — a graph mark, a table row, an
  announcement — can cite the row a claim came from.

##### D1c. Load-time integrity checks

Every condition below is one feature-003's validators already reject at generate time, so hitting one
at load means the artifact shipped broken. They are still checked, because a browser artifact has no
exit code and a silently-wrong picture is the failure this whole work exists to prevent.

| # | Condition | Which validator owns it | View behaviour |
|---|---|---|---|
| 1 | Header row not byte-identical to feature-003 D1's ten-column literal | AC-S1 here; the emitter's own contract | **Fatal load error** — the shell fills **the same `role="alert"` banner** step 4b uses (§ UI Specs; no third live region, and the two writers are mutually exclusive, since a fatal load error mounts neither rendering and so no `kb_gaps` check ever runs) and mounts neither rendering. Quotes expected and actual (AC-S1) |
| 2 | A row whose unescaped-cell count ≠ 10 | feature-003 **V1** | Fatal |
| 3 | A `Kind` cell outside §5.2's enum | feature-003 **V13** tier 1 | Fatal — fail-closed, per §5.2's "loaded fail-closed in the same way" |
| 4 | A `Kind` that disagrees with its id's prefix by §5.2's pairing table | **AC-2a**, feature-003 **V13** | Fatal. **`image` is the branching case**: `int:` *and* `ext:` are both valid, and rejecting `ext:` here is the specific bug §5.2 warns a naive one-to-one implementation commits. The pairing is carried as **data** (a `Map<Kind, Set<prefix>>` mirroring feature-003's `"image\|int,ext"` encoding), so the branch is a value rather than a code path someone must remember |
| 5 | The same id carrying two different `Kind` values | feature-003 **V8** | Recorded in `kindConflicts`; first occurrence wins; a non-fatal but **prominent** callout, because it changes colour, shape and kind-filter membership |
| 6 | The same id carrying two different names | feature-003 **V8** | Recorded in `nameConflicts`; first occurrence wins; non-fatal callout |
| 7 | An `s2t` or `t2s` outside the merged vocabulary | feature-003 **V3** | Fatal |
| 8 | An empty `Provenance` | feature-003 **V6**, A-3 | Fatal |
| 9 | A `fact` node with no edge to a `source-artifact`, `image` or `web-page` node | *none* — see below | Recorded in `integrity.unbackedFacts`; a `.callout.warn`, **not** a lens class |

**Condition 9 is a new check and it exists because a widened model made an old class incoherent.** Q13
defines a `fact` as a claim **carrying** a checkable source anchor, and FR-30 emits, with every fact
node, "a `declared` edge to the `int:` path the anchor cites". So an unbacked `fact` is *structurally
impossible* in a well-formed artifact. If one appears, it is a defect in extraction — not a Knowledge
Base gap — and reporting it as a Coverage-lens signal would tell the reader to go fix their KB when the
thing that is broken is the tool. It therefore reaches the reader through the integrity channel and is
excluded from `kb-unbacked` (D6d).

#### D2. The loader — reading ten columns and stopping before the coverage notes

`parseRelationships(text) -> GraphModel`. Five steps, in order, each pinned to feature-003 D1's file
skeleton so the parser and the emitter cannot disagree about where the table is.

##### D2a. Frontmatter, H1, and the header literal

1. **Skip exactly one leading frontmatter block.** `relationships.md` is a KB-indexed document carrying
   valid KB frontmatter (Q3, C-7, feature-003 D8), so the loader skips a leading `---` … `---` block and
   resumes after it. It skips the **first** such block only; a later `---` in the body is a thematic
   break. This mirrors the first-block-only scoping the KB's own frontmatter readers use
   (`build-kb-index.sh` → `extract_field`), so the two agree on where frontmatter ends.
2. **Find the `# Relationships` H1.** feature-003 D1's skeleton fixes it, and its rule 1 states that the
   first non-blank line after it is the header row.
3. **Assert the header literal.** The header must equal feature-003 D1's verbatim string:
   `| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |`.
   Column positions are then **fixed by that assertion**, and cells are read by index. The loader does
   **not** locate columns by name, and does not tolerate a different count — which is the whole point of
   AC-S1. The eight-to-ten widening is precisely the change a name-matching loader would have absorbed
   silently while mis-reading `Source Name` as `Source Kind`, and feature-003 D1 notes the same property
   from the emitter side: the widening is a change to one data file plus the header and delimiter
   literals.
4. **Skip the delimiter row**, which D1 fixes as `|---|` × 10.

##### D2b. Cell splitting respects the `\|` escape

feature-003 D1 permits a literal pipe inside a cell escaped as `\|`, and says why this matters more at
ten columns than at eight: a `fact` display name is `<doc> § <anchor-string>` with the anchor string
reproduced from a KB document verbatim (D5), and such a string may legitimately contain a pipe. So the
loader splits on **unescaped** `|` only and then unescapes `\|` to `|` in each cell. A naive
`split('|')` would produce an eleven-cell row and fail check 2 of D1c on a valid table — a fatal error
on correct input, which is the worst failure mode available.

Two further defensive rules, labelled as defensive rather than as contract changes: cells are trimmed of
the single surrounding space D1 mandates, and a trailing `\r` is stripped although D1 fixes LF-only line
endings (`canonical/EMISSION-MANIFEST.md` § "Line endings"), because this repository is authored on
Windows and a CRLF artifact should fail loudly on its header rather than confusingly on every cell.

##### D2c. The stop rule — how FR-3 survives FR-9a

FR-9a adds a `## Coverage notes` section to the file FR-3 calls "the single input to the graph". The two
coexist **by position and by a one-pass stopping rule**, and feature-003 D1 states the rule this loader
implements: *the table runs from the header row to the first line that is not a table row; a parser
stops there.* Concretely:

- A line is a table row iff its first non-whitespace character is `|`.
- On the first non-table line the table parse **ends**. `GraphModel.edges` is closed. The loader does
  not look ahead, does not search for a second table, and does not treat the notes' own tables — which
  D7a makes expected — as continuation rows.
- feature-003 D1 rule 4 guarantees the relationship table is the only pipe table above `## Coverage
  notes`, so this rule cannot stop early on a stray table.

This is **AC-S2**, and it is why FR-3 holds structurally rather than by trust. feature-003's matching
criterion (its own AC-S2) states the emitter's half of the same guarantee; the two are the same property
checked from both ends.

##### D2d. `parseCoverageNotes` — a second reader over a disjoint region, reporting only

The stop rule leaves the notes unread, and the previous revision would have left them unread
permanently. That is a loss the reader should not take: FR-9a's notes are the answer to "is this graph
thin because my Knowledge Base is thin, or because the tool failed" — §2 purpose 1's question — and
they are already in the file the view has in hand.

So a **second, explicitly scoped reader** runs from the stop point onward:

`parseCoverageNotes(text, stopOffset) -> CoverageReport | null`

| Field | Content |
|---|---|
| `nodeKinds` | one entry per row of D7a's `### Node kinds` table: `{kind, carrier, status, nodes}` where `status ∈ {present, absent}` |
| `exclusions` | one entry per row of D7a's `### Enumeration exclusions` table: `{exclusion, applied, note}` |
| `extra` | the extra rows below each fixed block, as `{table, key, cells}` — read as **whatever is present**, never against a hardcoded key set |

Four rules bound this reader, and together they are what keep AC-10 and AC-S2 true:

1. **It cannot contribute to graph membership.** Its output reaches `ViewModel.coverage` and is consumed
   only by the legend, the coverage panel and the table's captions. No value from it appears in
   `visibleNodes`, `visibleEdges`, `edgeFold`, `groups`, `foldedInto`, `nodeEmphasis`, `edgeEmphasis` or
   `coverageGaps`. AC-S2 asserts this directly, and the structural guarantee is that `project()` never
   receives it: `CoverageReport` is a field on `GraphModel` that `project()` copies through untouched.
2. **It is not a second extraction path.** It reads the same bytes of the same file the view already
   renders from — the argument feature-006 § D6 makes for reading `kb_gaps` from frontmatter, applied to
   a second region of the same document. AC-10 forbids a second *extraction*, not a second *region*.
3. **It hardcodes no row set.** feature-003 D7a fixes the two tables' fixed rows and D7a-1 gives extra
   rows a total order, but the extra-row set is owned by its **producers** — feature-003 contributes
   `fact-unanchored` and `section-empty-slug`, feature-004 `image-external` and
   `source-artifact-dropped`, feature-005 `concept-qualified` and `concept-merge-candidates`, and wave 3
   may add more. Reading them generically is the only form that does not go stale, and it is the Q17
   discipline applied to a set this feature does not own: cite the set, never a count of it.
4. **Absence is not an error.** A `relationships.md` predating FR-9a yields `null` and the coverage panel
   states that the run's coverage report was unavailable. Treating that as corruption would be a false
   alarm, and a false alarm trains a reader to ignore the real one.

What the reader does with it is specified at § UI Specs → Coverage panel. One consequence is worth
naming here because it answers a question the widened model raises and FR-3 otherwise leaves unanswered:
**an enumerated `image` or `web-page` node that appears in no relationship row cannot be drawn** —
`GraphModel.nodes` is built from the table's id columns, and unlike a zero-row `source-artifact` such a
node has no `kb_gaps` carrier, because AC-15 as re-keyed scopes the ledger to `Kind = source-artifact`
and FR-20 states plainly that an undocumented image is **not** a KB gap. The per-kind counts in the
notes are therefore the only place a reader learns that such nodes exist at all, and the coverage panel
reports the difference between the enumerated count and the count present in the table. That is an
honest report of a real limit rather than a silent omission, and whether the graph should be able to
draw those nodes is routed as an Open Item with the carrier it would need.

#### D3. `LensState` — the control view-model (the cross-feature contract)

A flat, JSON-serialisable record. Every control writes here and nowhere else; every preset is expressed
purely as values over these fields (FR-13). No field is a function, an element handle or a renderer
object, which is what lets the same state be logged, diffed and replayed in a headless test.

| Field | Type / domain | Meaning | Read by |
|-------|---------------|---------|---------|
| `preset` | `'coverage' \| 'overview' \| 'impact' \| 'provenance' \| null` | Label of the preset last applied. Advisory only — it never gates a control (FR-14, AC-8) | both |
| `grouping` | `'none' \| 'relation-category' \| 'document' \| 'node-kind' \| 'provenance'` | The grouping dimension. `'relation-category'` is FR-6's dimension, offered as a real `<option>` and asserted by **GV26**; `'node-kind'` now partitions **seven** ways, not three; `'document'` is the **kind-dependent** partition D6c fixes — not a bare `kbDoc` key — and it is the one dimension that also **folds** (D6c) | both |
| `expandedGroups` | `string[]`, default `[]` | The group keys the reader has drilled into. The disclosure at D6c clause 3 **toggles** membership, so this shrinks as well as grows and the drill-in is undoable without re-applying a preset. Meaningful only under a **folding** dimension (`'document'`, D6c); under any other dimension it is inert and carried unchanged. Not in the `filters.*` namespace, so a preset may set it (AC-S6 is unaffected) — and the Overview patch does, because FR-13 asks that lens to *start* folded | both |
| `density` | integer `1..5` *(design choice)* | **View density — how much is drawn.** Level `1` performs **no thinning at all**; levels `2`–`5` hide nodes with `degree < density`. Stated as a level rather than a minimum degree precisely so a zero-row node is not excluded by the level that is supposed to exclude nothing | both |
| `filters.kinds` | subset of §5.2's `Kind` enum | Node kinds admitted (FR-14a axis 2). **Seven values**, read at runtime from `keys(KIND_ENCODING)` — the enum carried **in code as a shipped definition**, exactly as `RELATION_CATEGORY` carries the relation vocabulary and for the same AC-10 reason — and *authored* from `canonical/aid/templates/graph/relationship-schema.yml`'s `kinds:` list (feature-003 D1), which **GV16 binds it to** by reading that file from disk. Never a second literal typed on the control side | both |
| `filters.categories` | subset of `GraphModel.categories` | Relation categories admitted (FR-14a axis 1, required by FR-6a) | both |
| `filters.provenance` | subset of `PROVENANCE_VALUES` (`{declared, derived, inferred}`) | Provenances admitted (FR-14a axis 3). Same carrier rule as `filters.kinds`: a frozen in-code constant, authored from the schema file's `provenance:` list and bound to it by **GV16** | both |
| `filters.showOrphans` | boolean, default `true` | FR-14a's **orphan-node toggle**. Default on, and the default is the requirement's own reasoning: isolated nodes are precisely what the Coverage lens and the gap ledger exist to surface, so hiding them must be a deliberate act | both |
| `filters.text` | string | Case-insensitive substring match over the four id/name cells. Matches the **stored** name and the id, never `shortLabel` (AC-S8) | both |
| `focus.nodeId` | node id or `null` | The selected node — FR-14a's single-click gesture and the Impact lens's subject | both |
| `focus.depth` | integer `1..6` *(design choice)* | Neighbourhood radius in hops from `focus.nodeId` — FR-13's "adjustable depth" | both |
| `emphasis` | `'none' \| 'coverage' \| 'provenance-chain'` | The only field that drives **lens-level** dimming and highlighting. Selection dims and highlights too, through `focus.nodeId` (D7a), and the two compose in `nodeEmphasis` — so this is the only *lens* channel, not the only source of a class | both |
| `zoom` | `{scale, panX, panY}` | Viewport transform. **Graph-only** | graph |
| `sort` | `{column, direction}` | Table ordering. **Table-only** | table |

**Two things `LensState` deliberately does not carry, and both are FR-14a requirements stated as
absences.**

1. **No physics parameters.** FR-14a: `density` means node/edge density in the view "and is *not* an
   exposure of `d3-force`'s physics parameters. Repulsion, link distance and centre force are **internal
   constants**, tuned once by the implementation, not user controls." Obsidian exposes them; this
   artifact deliberately does not, on the requirement's own reasoning — a documentation viewer should not
   require physics tuning to become readable, and every exposed parameter is another way to make the
   graph worse. Mechanically: those constants live in feature-008's module and there is **no
   `LensState` field that can reach them**, so the boundary is structural. A control panel that grew a
   repulsion slider would have nowhere to write it.
2. **No hover state.** Hover focuses a neighbourhood and reveals a relationship name (Q11 as amended,
   NFR-5), and it is *transient*: routing it through the store would re-project on every pointer move,
   which is the per-frame accessibility-tree churn feature-002's research names as the expensive
   operation. Hover is therefore feature-008's local concern, bounded by one rule stated in the API
   contract: **hover may change appearance, never membership.** Selection — which does change membership,
   through `focus` — is the gesture that goes through the store.

**The renderer-private carve-out is part of the contract.** `zoom` and `sort` are the *only*
renderer-private fields, and neither may affect which nodes or edges are present or emphasised.
Everything deciding membership or emphasis lives in the shared fields and is interpreted exactly once,
in `project()`. That is the mechanism by which NFR-3 and AC-7 hold — not a convention the two renderings
are asked to honour.

#### D4. `ViewModel` — the derived projection both renderings consume

`ViewModel = project(GraphModel, LensState)` — a pure function: same inputs, same output, no DOM access,
no clock, no randomness. It is also the accessibility model kept beside the visual model, which is why
the announced text and the per-mark labels are fields on it rather than strings each renderer composes.

| Field | Type | Contract |
|-------|------|----------|
| `visibleEdges` | `Edge[]` | The rows surviving the filters and the density level, ordered by `row` ascending — a deterministic order both renderings share, and feature-003 D7's order. Every entry keeps its own `sourceId`, `targetId`, `key` and `row` untouched, so any surface can cite the table row it came from; which two nodes it is **drawn between** is `edgeFold`'s to say, not this field's |
| `visibleNodes` | `Node[]` | Every endpoint of `visibleEdges` **as the fold resolves it** (D6c), plus the zero-row nodes materialised from `kb_gaps` (D10) — complete `Node` records grouped, thinned and filtered exactly like any other node — plus the focused node, likewise resolved, when it has no surviving edges. No key of `foldedInto` is ever present and every head it names is, which is what stops the additive and subtractive clauses colliding. Because the fold runs **last**, a head reached only through a folded member is drawn even where its own `degree` is under the density level — which is what makes Overview's `density: 3` thin sub-document detail rather than the documents it folds into |
| `groups` | `Array<{key, label, nodeIds, foldable, expanded}>` | The `grouping` partition; a single `all` group when `grouping === 'none'`. `nodeIds` lists the group's **drawn** members. `foldable` is the count of members the fold *governs* — a group's non-head members where it has a node head — and is **independent of expansion state**, which is what keeps the disclosure's presence off a count that expanding would zero; it is `0` under every non-folding dimension and for every group with no non-head member. `expanded` is `true` exactly when `foldable > 0` and the key is in `LensState.expandedGroups`, and it is the `aria-expanded` value verbatim, so no consumer derives it |
| `foldedInto` | `Map<id, id>` | **The fold's record (D6c).** Every node the fold removed from `visibleNodes`, mapped to the head drawn in its place. Empty under every non-folding dimension and for every expanded group, so a lens that folds nothing produces an empty map rather than a special case. It is a record, not an instruction: `project()` has already applied it to `visibleNodes`, `edgeFold`, `nodeEmphasis` and `counts`, and a consumer reads it only to say where a node went |
| `edgeFold` | `Map<key, {sourceId, targetId} \| 'collapsed'>` | One entry per `visibleEdges` row: the two node ids it is **drawn between and listed as**, each endpoint resolved through `foldedInto`; or the literal `'collapsed'` where both resolve to one node, which is `project()`'s verdict that neither surface draws or lists that row. Identity pairs under every non-folding dimension, so there is one code path and no mode — and membership stays decided in `project()` rather than by a rule the two renderings are asked to honour (D3) |
| `nodeEmphasis` | `Map<id, 'normal' \| 'dimmed' \| 'kb-unbacked' \| 'artifact-undocumented' \| 'focus'>` | Per-node emphasis class, keyed over **`visibleNodes` and nothing else**, so no class — `'focus'` least of all — can land on a node neither rendering may draw. `'int-undocumented'` is **renamed `'artifact-undocumented'`**, because the class is `Kind = source-artifact` and the old name was the prefix-keyed proxy AC-15's re-key removed |
| `edgeEmphasis` | `Map<key, 'normal' \| 'dimmed' \| 'chain'>` | Per-edge emphasis class, keyed over the `visibleEdges` rows `edgeFold` does **not** mark `'collapsed'` — the drawn set, for the same reason `nodeEmphasis` is keyed over `visibleNodes` |
| `nodeLabels` | `Map<id, string>` | The **accessible name** for a node on every surface. Never the shortened form (AC-S8) |
| `nodeShortLabels` | `Map<id, string>` | The drawing/collapsed-cell label (D9). Presentation only |
| `nodeEncoding` | `Map<id, {colourToken, glyph}>` | The kind-keyed colour **token name** and shape. A token name, not a colour value — the value is resolved from CSS at draw time (D5a), which is what keeps the palette checkable |
| `edgeEncoding` | `Map<key, {colourToken, lineStyle, arrowhead}>` | The category-keyed colour token, line style, and `arrowhead: boolean` = `!edge.symmetric` |
| `coverageGaps` | `{kbUnbacked: string[], artifactUndocumented: string[]}` | Sorted node-id lists; see D10 |
| `coverageOrigin` | `Map<id, 'verified' \| 'ledger-only' \| 'view-only'>` | Where each `artifactUndocumented` id came from. Additive; a renderer ignoring it still shows every gap |
| `coverage` | `CoverageReport \| null` | D2d's report, copied through untouched. Reporting only |
| `lensSummary` | string | One sentence naming the active lens and control values |
| `announcement` | string | The text pushed to the polite live region after a lens change (SC 4.1.3) |
| `canvasAlt` | string | The canvas's text alternative (AC-9 as scoped): counts, active lens, active filters. Written **once per lens change**, never per frame |
| `revision` | integer | Monotonic counter, incremented per successful projection |
| `counts` | `{nodes, edges, hiddenNodes, hiddenEdges}` | What the header, the canvas alternative and the table caption all report, and the two pairs are **commensurable by construction**, each a partition of the loaded whole: `nodes` is `visibleNodes.length` and `edges` is the number of `visibleEdges` rows whose `edgeFold` entry is not `'collapsed'` — the drawn counts on both axes — while `hiddenNodes` is `GraphModel.nodes.size − nodes` and `hiddenEdges` is `rowCount − edges`. So a filter, the density level and the fold are counted the same way on both axes, and nothing is ever counted as visible and hidden at once |

**Emphasis is classification, not styling.** `project()` returns *classes*; the canvas maps them to
shape, opacity and label, and the table maps them to a badge and a row group. Neither maps a class to
colour alone (NFR-5).

**Encoding is resolved here, once, and that is a change from the previous revision.** `nodeEncoding` and
`edgeEncoding` did not exist when the graph was static and the palette was five reused tokens. They
exist now because there are two encoding vocabularies (seven kinds, fourteen categories over eight
colours) and three consumers, and a fourteen-row mapping table duplicated in a draw loop and a table
legend is a guaranteed divergence. Both fields carry **token names** rather than colour values, which is
the mechanism D5a needs: the drawing code resolves a token from CSS at draw time, so the only place a
colour value exists is the stylesheet the contrast checker reads.

#### D5. The palette contract

The previous revision claimed `graph-css.css` "adds **no colour token**", mapping five semantic roles
onto existing contrast-checked tokens so `contrast-check.mjs` would keep passing with no new pairs.
**That claim is void** (feature-002 Open Item 4, routed here): the redesign needs one colour per value
of §5.2's `Kind` enum **plus** up to eight category colours (AC-8a part 3), and no five-role mapping
covers fifteen roles.

##### D5a. The palette is CSS custom properties, and this is a contract because the check is otherwise silent

**The obligation.** WCAG 2.2 **SC 1.4.11 Non-text Contrast is Level AA** and requires a contrast ratio
of at least **3:1** against adjacent colours for "Graphical Objects — Parts of graphics required to
understand the content" (feature-002 D8 fetched and cited it at
w3.org/WAI/WCAG22/Understanding/non-text-contrast.html, accessed 2026-07-29). The graph's node and edge
marks are exactly that, because colour carries node kind and relationship category (NFR-5). NFR-1 sets
AA, and REQUIREMENTS' own 2026-07-29 note **declines** to rest colour conformance on the conforming
alternate version: "extending it to colour would make the graph itself non-conformant and rest all
conformance on the table. Not adopted." So the palette must clear 3:1 **on the graph**, mechanically.

**The verified hole.** `canonical/aid/scripts/summarize/contrast-check.mjs` is a text extractor with no
browser. Read on disk: `extractVars` builds the regex `<selector>\s*\{([^}]*)\}`, matches it with
`String.prototype.match` (**no `g` flag**), and harvests custom properties from the matched block with
`/--([a-z-]+)\s*:\s*([^;]+);/g`. It is called three times — for `:root, html[data-theme="light"]`, for
`:root`, and for `html[data-theme="dark"]` — and it checks a hardcoded `pairs` list of **eleven** token
pairs, every one at `target: 4.5`. Four consequences follow, and each is a rule the palette must obey
rather than a caution:

| # | Verified mechanism | Rule it imposes |
|---|---|---|
| 1 | A colour that is not a CSS custom property is never looked for. A WebGL layer passes fills to its graphics API as values, not as CSS, so a palette living as literals in drawing code produces **no warning and no failure — the check never runs** | **Every palette colour is declared as a CSS custom property**, and the drawing code resolves it at draw time via `getComputedStyle(document.documentElement).getPropertyValue(token)`, caching per theme change. `nodeEncoding`/`edgeEncoding` carry **token names** for exactly this reason (D4). **AC-S4** asserts no colour literal in drawing code |
| 2 | The extraction charset is `[a-z-]+` — **no digits, no underscore, no uppercase** | Token names use lowercase letters and hyphens only. `--gc-evidence` is visible; `--gc-1` is **not**, and would be silently unchecked. This is why the palette is named after kinds and categories rather than numbered |
| 3 | `match` has no `g` flag, so **only the first block per selector is extracted** — and "first" is earlier than it looks. In the assembled page `component-css.css` opens `:root { color-scheme: light dark; }` at line 2, `html[data-theme="dark"]  { color-scheme: dark; }` at line **4**, `:root, html[data-theme="light"] {` at line 7 and its dark **theme-variable** block at line 37; `graph-css.css` is inlined **after** all of them. Re-run against the file and against the generated `.aid/knowledge/kb.html`, the three existing calls win the **same three blocks** in both, at each file's own numbering: `component-css.css` lines 7/2/**4**, and `kb.html` lines 22/17/**19**, the assembled page's head shifting every offset (the dark **theme-variable** block moves 37 → 52 and row 4's `@media print` one 588 → 601). So the dark call harvests the `color-scheme` block and **zero custom properties**, and since the script computes `dark = { ...light, ...darkVars }`, today's "dark theme" run re-checks the **light** values | A second block reusing those selectors in `graph-css.css` would be **invisible** — for the dark selector, doubly so, since even line 37 never wins. So the palette is declared under **selectors that do not already occur** — `html:root` for the light values and `html[data-theme="dark"]:root` for the dark values — and `contrast-check.mjs` is parameterised to extract those two additional blocks and merge them. Both selectors match the same `<html>` element as the existing ones, so the CSS behaves identically |
| 4 | The obvious generalisation — extract **all** occurrences and merge — is **unsafe**, and this is the trap. `component-css.css` carries a **third** `html[data-theme="dark"] { … }` block at line 588, inside `@media print`, which re-declares every dark token with **light** values in order to force a light print rendering. Merging all occurrences in document order would let those print values win, so the dark-theme check would read light values | The parameterisation must be **additional named selectors**, never "all occurrences". Stated precisely, because the harm is not the one it first looks like: `kb.html`'s dark check is not *currently* reading line 37 (row 3), so merge-all would not corrupt a working check — it would **leave that check still not reading the dark palette** while giving the graph's own dark pairs the same defect, which is worse than the hole it appears to fix. The graph's dark selector must therefore occur **exactly once and never inside `@media print`**; `html[data-theme="dark"]:root` satisfies both, verified against the file. That the existing dark extraction harvests nothing is a real defect in the checker, not in the palette, and it is **feature-011's** to fix with the parameterisation — the exact "parameterised, never weakened" line §5.6 consequence 1 draws |

**The two new selectors are verified not to disturb the three existing extractions.** Checked against the
regexes as written. `extractVars(html, ':root')` searches for `:root\s*\{`; `component-css.css` line 2's
`:root { color-scheme: light dark; }` precedes anything `graph-css.css` contributes, and `match` returns
the **first** occurrence, so `html:root { … }` cannot capture that call even though `:root {` occurs
inside its selector text. `extractVars(html, 'html[data-theme="dark"]')` searches for
`html\[data-theme="dark"\]\s*\{`, and in `html[data-theme="dark"]:root {` the `]` is followed by `:root`
rather than by `{`, so it does not match either. Both new blocks are therefore invisible to the existing
calls and visible only to the parameterised ones — which is what keeps `kb.html`'s check byte-for-byte
unchanged while the graph's palette becomes checkable.

**What is routed, and to whom.** This feature owns the **declaration**: the tokens, their names, their
placement, and the runtime resolution. **feature-011** owns the **checker parameterisation** — the two
extra selectors and the new pairs at a **3:1** target, with `kb.html`'s eleven pairs unchanged at 4.5
(feature-002 Open Item 8 already carries the pair-list half; the selector half is added here with the
line-588 reason). The alternative — declaring the graph tokens inside `component-css.css`'s existing
blocks — is admissible and needs no selector parameterisation, but it puts fifteen unused custom
properties into `kb.html` and makes a graph-only palette part of a shared stylesheet; it is recorded as
the fallback rather than chosen.

**One verdict this feature does not own.** Whether the drawing layer can consume computed CSS values at
acceptable cost is feature-002's, as a measurand on the mechanism (its D8: "if it cannot, the
accessible-and-checkable palette is not merely unwritten but unavailable, and that is a finding the
owner needs"). This SPEC states the contract and the fallback position: if resolution per draw proves
costly, the values are resolved **once per theme change** into a local table — which preserves every
property above, because the stylesheet remains the only place a colour value is authored.

##### D5b. Eight category colours over fourteen categories

feature-001 D5 states the category set as a research finding: **fourteen** categories, 31 pairs. AC-8a
part 3 caps the palette at **eight** distinct category colours regardless of count. feature-001 D5a
routed the assignment here (its Open Item 7) together with a recommendation and its basis, and **the
recommendation is adopted**: the categories that must be distinguishable *without* filtering are the
ones FR-13's four lenses key on, two per lens.

| Colour token | Holder category | Lens that keys on it |
|---|---|---|
| `--gc-evidence` | `evidence` | Coverage |
| `--gc-documentation` | `documentation` | Coverage |
| `--gc-provenance` | `provenance` | Provenance |
| `--gc-lineage` | `lineage` | Provenance |
| `--gc-dependency` | `dependency` | Impact |
| `--gc-implementation` | `implementation` | Impact |
| `--gc-structure` | `structure` | Overview |
| `--gc-taxonomy` | `taxonomy` | Overview |

The remaining six reuse a holder's colour and are separated by **line style** (NFR-5's non-colour
channel: solid / dashed / dotted / dash-dot). The assignment, and the rule that generates it:

| Category | Colour token | Line style | Pairing rationale |
|---|---|---|---|
| the eight holders above | own | **solid** | Solid reads as primary, and the eight are the lens-keyed set |
| `definition` | `--gc-taxonomy` | dashed | Both are concept-to-concept relations |
| `identity` | `--gc-taxonomy` | dotted | Same family; identity is the limiting case of `taxonomy`'s associative relation |
| `representation` | `--gc-structure` | dashed | A rendering or depiction is a structural stand-in for its subject |
| `navigation` | `--gc-structure` | dotted | IANA registers `next`/`prev` alongside document-structure relations (feature-001 D5's own grounds for filing *sequence* under `structure`) |
| `agreement` | `--gc-evidence` | dashed | Agreement and evidence are the two claim-about-a-claim families feature-001 D5 deliberately split |
| `annotation` | `--gc-documentation` | dashed | An annotation comments without asserting; documentation records |

**The generating rule, which is what AC-S5 checks and what an extension must obey:** *within any one
colour, every category carries a distinct line style.* That makes the (colour, line-style) pair unique
across all fourteen, which is representable because no colour holds more than three categories here and
four styles exist. It also gives the mechanical bound on extension: a project may add categories
(FR-4a) provided **no colour ends up holding more than four**, and `dash-dot` is deliberately unused by
the core so the first extension per colour needs no re-assignment. Past that bound the encoding is
unrepresentable and the run must say so rather than silently collide.

**What line style can and cannot carry, stated honestly.** Four styles cannot distinguish fourteen
categories, and no arrangement of eight colours and four styles can. Q11's recorded design ceiling says
the same: beyond roughly eight colours and four line styles, simultaneous distinction fails for all
users. So the non-colour route to a relationship's category is **not** line style alone. It is three
things: **filtering to a category**, which FR-6a makes required and AC-21 makes keyboard-operable; the
**relationship name on hover or selection**; and the **table view's text**, where every name is always
present. Line style is the always-on secondary channel, and the property above — distinct within a
colour — is the strongest thing it can carry. Stating it this way matters because "colour plus line
style distinguishes fourteen categories" is exactly the kind of plausible, unmeasured claim this work
has already been burned by; the requirements themselves reach the same conclusion, since AC-8a part 3
prescribes "colour reuse plus line style **plus filtering**" rather than colour and style alone.

##### D5c. Node kind — seven colours and seven shapes

NFR-5 carries node type by **colour and shape**. Both are keyed on §5.2's enum, resolved in
`nodeEncoding`, and stated in words in the legend (SC 1.1.1).

| `Kind` | Colour token | Glyph *(design choice)* |
|---|---|---|
| `document` | `--gk-document` | filled circle |
| `section` | `--gk-section` | filled square |
| `fact` | `--gk-fact` | filled triangle, point up |
| `concept` | `--gk-concept` | filled diamond |
| `source-artifact` | `--gk-source-artifact` | filled hexagon |
| `image` | `--gk-image` | filled pentagon |
| `web-page` | `--gk-web-page` | ring — a circle with a hollow centre |

`image` carries the same colour and glyph whether its prefix is `int:` or `ext:`, because the encoding is
keyed on kind and the prefix is not the kind (D1a). Whether seven shapes remain distinguishable at the
sizes the density and zoom controls reach is a **legibility judgment for the mandatory human visual
gate**, not something this SPEC asserts; the fallback if it fails is to merge glyphs and lean harder on
filtering, which costs no requirement.

##### D5d. Forced colours, and the one place the canvas cannot follow the page

`component-css.css` already carries an `@media (forced-colors: active)` block, and the shell inherits
it. The canvas does not: a WebGL surface is a bitmap, and forced-colours mode remaps CSS-declared
colours on elements rather than pixels inside a bitmap. So in forced-colours mode the page around the
graph is remapped and the graph is not — a real limit, stated rather than discovered.

The response uses the channel NFR-5 already required: in forced-colours mode the shell exposes the
preference and the canvas draws **no palette colour at all** — every mark in the forced foreground
colour on the forced background — leaving **shape** for node kind, **line style** for category, and
filtering for the rest. That is a degraded but coherent picture, and it is only possible because colour
was never the sole carrier. Detection and exposure are this feature's; the drawing is feature-008's.

#### D6. Filtering, the four lenses, and how they compose

##### D6a. The preset table (FR-13, FR-14, FR-15)

Each preset is a **frozen partial assignment** over `LensState`, applied by patching the store. That is
the whole mechanism, and it is why arriving through a preset cannot lock the view (FR-14, AC-8): the
patch lands in the same state every control writes to, so every control keeps working afterwards, and no
control is ever disabled or hidden by a preset.

| Preset | Patch | Serves |
|--------|-------|--------|
| **Coverage** | `emphasis: 'coverage'`, `grouping: 'node-kind'`, `density: 1`, `focus.nodeId: null` | §2 purpose 1 |
| **Overview** | `grouping: 'document'`, `expandedGroups: []`, `density: 3`, `emphasis: 'none'`, `focus.nodeId: null` | §2 purpose 2 |
| **Impact** | `focus.depth: 2`, `density: 1`, `emphasis: 'none'`, `grouping: 'none'`; keeps the current `focus.nodeId` and prompts for one when unset | §2 purpose 3 |
| **Provenance** | `emphasis: 'provenance-chain'`, `grouping: 'provenance'`, `density: 1` | §2 purposes 1 and 4 |

Because all four purposes are equally primary (§2), the **initial** `LensState` is `preset: null`,
`grouping: 'none'`, `expandedGroups: []`, `density: 1`, each of the three enumerable filter axes admitting
its whole domain, `filters.text: ''`, `showOrphans: true`, `emphasis: 'none'`, `focus.nodeId: null`,
`focus.depth: 1`, `zoom: {scale: 1, panX: 0, panY: 0}` and `sort: {column: 'row', direction: 'asc'}` —
feature-003 D7's order, so the table opens in the file's. That is **every** field of `LensState`: the
unfiltered whole with no lens applied and nothing folded, `'none'` not being a folding dimension. No preset
is the default, which is what makes FR-15's "no privileged default" criterion checkable rather than a matter
of taste, and **GV25** is the check — these values, plus that each preset's patch differs from them on at
least one key it sets, which is why `focus.depth` had to be stated: at Impact's `2` that patch would have
differed from the initial state on nothing at all.

##### D6b. Composition is structural, not a convention

FR-14a requires that filters "**compose with** a preset lens rather than resetting it: arriving via a
lens and then filtering narrows that lens's view." The previous revision's presets each carried
`filters all-on`, which is the opposite behaviour: applying a lens would have wiped whatever the reader
had filtered to.

The mechanism is a **domain restriction on the preset patch**: no preset patch may contain a key in the
`filters.*` namespace. Every patch above obeys it, `PRESETS` is frozen, and **AC-S6** asserts
`keys(PRESETS[p]) ∩ filterKeys = ∅` for all four. A preset therefore *cannot* reset a filter — not
because the four patches happen not to, but because a fifth preset could not either without failing a
test. This is the same style of guarantee as the `zoom`/`sort` carve-out: the property is enforced by the
shape of the data, not by asking two renderings to behave.

The reciprocal half is that a filter never changes `preset`, so `aria-pressed` on the lens buttons keeps
reflecting how the reader arrived. `lensSummary` and `announcement` name **both** — "Coverage lens,
filtered to 2 of 14 categories" — because a reader who cannot see the control panel needs to know a
lens is narrowed. That sentence is also the answer to AC-8a part 2 in a form a screen-reader user can
verify.

##### D6c. The `'document'` dimension — the Overview lens's revised grouping model, and the only one that folds

FR-13's Overview lens was "collapsed to categories and doc-level groups at low density". The amendment
of 2026-07-29 states why that no longer covers the picture: sub-document nodes now outnumber documents,
so "doc-level groups" would leave the majority of nodes ungrouped. The amended model, implemented here.

**This table defines `grouping: 'document'` itself, not a behaviour the Overview preset adds** — and
that has to be so, because D6a makes a preset a **frozen value patch** and nothing else, so a dimension
whose meaning depended on how the reader arrived would break the one mechanism NFR-3 rests on. Overview
is this dimension plus `density: 3` and `expandedGroups: []`, no more. The partition is therefore
**kind-dependent rather than a bare `kbDoc` key**, and every consumer derives `groups` from the five
branches below whether a preset was applied or not:

| Node kind | `grouping: 'document'` group | Why |
|---|---|---|
| `section`, `fact` | **their parent document** | Both are document-scoped by grammar (§5.3: `kb:<doc>#…`), so `kbDoc` is populated and the fold is exact |
| `document` | itself | The group's head |
| `source-artifact`, `image` (in-repo) | itself | FR-13's amendment lists source artifacts among what Overview shows. `kbDoc` is `null` for both, and that is why the partition cannot be keyed on `kbDoc`: a `null` key would put every artifact and every concept in one ungrouped bucket, which is the opposite of what the amendment asks for. The in-repo/external split of `image` in this row and the last is a **prefix** read — one of the three D1a enumerates and defends, because the `Kind` column cannot say where an artifact lives and these two rows need exactly that |
| `concept` | **its relationship category** | A concept "has no single parent document by construction (§5.3)", so there is no document to fold into. Grouping by category is FR-13's amendment verbatim |
| `web-page`, `image` (external) | the external group | Neither has a parent document nor a category of its own. The `image` here is the `ext:`-prefixed one (D1a) |

A `concept` participating in edges of more than one category needs a rule, and FR-13 does not give one.
The rule here: **the category of its highest-`Provenance` incident edge**, `declared` > `derived` >
`inferred`, tie-broken by the category's position in feature-001 D5's declared order. It reuses the
provenance ordering FR-14a already fixes for the concept open-target, so the view has one precedence
rule rather than two, and it is total and deterministic — which `project()`'s purity requires. Recorded
as an **author decision** because FR-13 is silent, and stated rather than left to fall out because
"group by relationship category" is not single-valued for a merged concept node and an implementation
would otherwise pick arbitrarily.

**The fold needs a carrier, and the one added 2026-07-30 was under-designed — it is re-derived whole
here.** FR-13's amended sentence — Overview "shows documents, source artifacts and concepts, with sections
and facts folded away until the reader drills in" — is the lens's defining behaviour, and neither mechanism
already here can produce it: a partition **assigns a group key and removes nothing**, and `density: 3`
thins on `degree < 3`, which is degree-keyed and cannot fold a well-connected `section`. Leaving it to each
renderer is the NFR-3 drift § Source forbids, so the whole of it is `project()`'s — **three** clauses over
three `ViewModel` fields, `groups[].foldable`/`.expanded`, `foldedInto` and `edgeFold` (D4):

1. **What folds.** A group folds only where it has a **node head**, and under `'document'` that is exactly
   the document groups, whose head is the `document` itself: its non-head members — `section` and `fact`,
   the table's first row and no other kind — are its `foldable` members, each **folded** unless the group's
   key is in `expandedGroups`. No other branch has a **node head** to fold under: a `source-artifact` or
   in-repo `image` is a single-node group that is its own head, and the category and external groups are
   keyed on a label rather than on a node, so every member of those is drawn. `foldable` is therefore `0`
   for every group but a document's with members, which is
   why **only `section` and `fact` ever fold** — FR-13's sentence exactly rather than a rule that happens to
   agree with it — and `'document'` is today the only folding dimension, every other yielding `foldable: 0`
   and an empty `foldedInto`: one code path with an empty case rather than a mode.
2. **What the fold does, and what resolves through it.** A folded node is absent from `visibleNodes`,
   present in `foldedInto` mapping to its head, and counted in `counts.hiddenNodes`. `project()` then
   resolves every surviving reference to it to that head, once and in one place: an edge's two endpoints
   into `edgeFold`, and `focus.nodeId` before `nodeEmphasis` and D6e's expansion are computed. So **the
   fold is applied last and it wins** — selecting a `section` and then choosing `'document'` moves the
   `'focus'` class to that section's document rather than stranding it on a node neither rendering draws,
   and `focus.nodeId` is untouched in `LensState`, so expanding restores the emphasis exactly. And **no
   edge is synthesised**: `visibleEdges` keeps one entry per surviving row with its real ids, `key` and
   `row`, because an aggregate edge would need a key with no counterpart in feature-003 D7's `rel_row_key`
   — `source_id \x1f target_id \x1f s2t \x1f t2s` (its SPEC.md:1306), unique per row by **V5** (its :1777)
   — and would cost every surface the ability to cite the row a claim came from. A row whose two ends
   resolve to one node is `'collapsed'` in `edgeFold`: drawn and listed by neither surface, counted in
   `counts.hiddenEdges`. That is the accepted cost — a document's internal structure disappears **into**
   the document rather than into a self-loop — and two rows between one pair of heads stay two entries.
3. **Drilling in, and back out.** Every group with `foldable > 0` carries a real focusable
   `<button aria-expanded data-group-toggle>` on its head that **toggles** the group's key in
   `expandedGroups`, with `aria-expanded` set from `groups[].expanded`. Presence is keyed on `foldable`,
   which expanding does not change, so the element that collapses a group is the one that expanded it and
   the drill-in is reversible without re-applying the Overview patch — AC-8's "the preset has not locked the
   view", and what the first carrier could not do, having gated the button on a count expansion drove to
   zero. It is a **group** control and not a third node gesture, so FR-14a's two-gesture split (D7) is
   untouched; why it sits outside `CONTROL_MANIFEST` is at D8; GV22 tests both directions.

##### D6d. The Coverage lens — re-keyed from a prefix to a kind

**Two changes, both Q17-shaped: a clause whose meaning changed while its wording did not. Both are now
the owner's rulings rather than this SPEC's proposals** — the first by the AC-15/FR-20 correction of
2026-07-29, the second by FR-13's amendment the same day (STATE.md Q21 item 1), which this SPEC's own
findings caused.

**Change 1 — the gap class is `Kind = source-artifact`, not the `int:` prefix.** AC-15 and FR-20 were
both re-keyed on 2026-07-29 for the reason the requirements state: the widened model put in-repo
`image` nodes on the `int:` prefix, so a prefix-keyed reading would force an unreferenced picture to be
either lens-highlighted with no ledger row (breaking AC-15's equality) or reported as undocumented
project source (which it is not). feature-004's Open Item 1 verified that this feature's *mechanism* is
already correct — it reads `nodes.tsv`, which after feature-004's stream split contains
`source-artifact` rows exclusively — and that only its **prose** was stale. Both are now keyed on the
kind: the emphasis class is renamed `artifact-undocumented`, `coverageGaps.artifactUndocumented`
replaces `intUndocumented`, and the predicate at D10 is stated over `Kind = source-artifact`.

The distinction is load-bearing rather than cosmetic, and the requirements say why: FR-26 derives gap
severity from FR-21's significance qualifier, and an `image` node qualifies **by kind** under FR-21a and
therefore carries no qualifier at all. feature-004's own R4 makes the same point from the producer side —
its media writer has **no** `qualifier` field, so a significance verdict on an image is unrepresentable.

**Change 2 — `kb-unbacked` is re-scoped off the `kb:` prefix, and the owner has ruled on it.** FR-13
**as amended on 2026-07-29** reads "highlights unbacked **`document` and `concept`** nodes and
undocumented **`Kind = source-artifact`** nodes", both halves "re-keyed from prefixes to kinds (owner
decision)". It previously read "unbacked `kb:` nodes", and §2 item 1 still defines the defect as "a `kb:`
node with no `int:` edge" — the last clause in the family carrying the old wording. Both were exact when
`kb:` meant a document. Under the widened model `kb:` spans four kinds, and applying the old clause
literally produces the two wrong outcomes the owner's ruling names (STATE.md Q21 item 1):

- **`section`** — a document section that cites no source is the normal case, not a defect. Highlighting
  every one would flood the lens with the most numerous kind in the graph and bury the signal.
- **`fact`** — an unbacked fact is *structurally impossible*: Q13 defines a fact as a claim **carrying** a
  checkable anchor and FR-30 emits the `declared` edge to the cited path along with the node. If one
  appears, the defect is in extraction, not in the Knowledge Base.

So `kb-unbacked` is scoped to **`kind ∈ {document, concept}`** — the two kinds that make a claim a
source should back. A `concept` is included because a defined term with no edge to the project source is
precisely §2 purpose 1's unbacked KB claim, now visible at the granularity Q13's merge created. `fact`
is excluded and routed to the integrity channel instead (D1c condition 9). `section` is excluded
outright.

**The *test* is kind-keyed too, and the previous revision had it wrong twice over.** It read "no
incident edge to a node whose `prefix` is `int:`", taking §2 item 1's "no `int:` edge" literally. That
fails Q21's rule on its face — *a prefix is correct when the clause is about where an id comes from, and
wrong when it is about what class a node belongs to* — and this clause is about a class: whether the
thing on the other end of the edge is **project source**. The `int:` prefix spans `source-artifact`
**and** in-repo `image`, so an unreferenced picture counted as backing a Knowledge Base claim. It also
compared `prefix` against a literal that is not in its value space (`'kb' | 'int' | 'ext'`, D1a), so a
literal implementation yielded an **empty** class. The test is therefore:

> an incident edge to a node whose **`kind` is `source-artifact`**.

An in-repo `image` no longer backs a claim, which is the substantive change and the same reason FR-20 and
AC-15 were re-keyed: a picture is not a checkable source for a claim, and FR-21a gives it no significance
qualifier for anything to derive from. A `web-page` does not back one either, which keeps the test faithful
to §2 item 1's *project-source* reading; external chains are the Provenance lens's subject (D6f), where the
prefix is the right key because the clause there really is about which side an id comes from. This closes
feature-006's proxy-sweep row 13 **here** rather than routing it — that row records the substitution as
"real" and "not this feature's to resolve", and it is this feature's.

One consequence of closing it, stated so it is not mistaken for this SPEC contradicting a gated input:
feature-006's **D6a** table still spells this class's test as "no incident edge to an `int:`-prefixed
node", because it was describing the clause as it then stood. That is a **description of a class
feature-006 does not own** — `kbUnbacked` is browser-only and this feature's — and its own row 13
pre-declared that "nothing in this feature's boundary depends on the answer", which holds: **GL09**
asserts only that `kbUnbacked` ids appear in *neither* `kb_gaps` nor the ledger, and that is true under
either keying. So the one-line prose alignment is **editorial** under Q26 and batched into the Q24 item-9
pass; no mechanism of feature-006's moves and its A+ is untouched.

**What is settled, and what is left.** The domain narrowing is the **owner's ruling**, not an author's
call: it was flagged by this SPEC, decided the same day, and FR-13 now carries it in the requirement's own
words — so a reader should find this SPEC *implementing* a requirement, not deviating from one.
`kb-unbacked` also remains **lens-only** with no ledger row, exactly as AC-15's scoping fixes, so no
widening of FR-20 or FR-26 follows from either change. What is left is one clause of **wording**: §2 item
1 still says "a `kb:` node with no `int:` edge", the last unannotated member of the `int:`-for-kind family
that FR-19 got an annotation for and that feature-006's Open Item 8 raises for FR-26/AC-14. That is
**Open Item 2**, classified **editorial** under Q26.

**The two classes, restated at ten columns:**

| Class | Definition | Ledger relationship |
|---|---|---|
| **`artifact-undocumented`** | `kind === 'source-artifact'` and not covered by the predicate at D10 | **Verified.** One ledger row per member (FR-20, FR-26); this is the class AC-15's equality binds |
| **`kb-unbacked`** | `kind ∈ {document, concept}` with no incident edge to a node whose `kind` is `source-artifact`. Deliberately **not** narrowed by `COVERAGE_BEARING`: §2 item 1 asks only for an edge to project source, and any relation satisfies it | **View-only.** Never written to `kb_gaps`, never a ledger row, never compared against one |

Both are surfaced by the lens and labelled distinctly on both surfaces, so a reader can tell which has a
ledger counterpart.

##### D6e. The Impact lens is the local-graph view

Q13's scope note and the requirements' change log both record the finding: **FR-13's Impact lens already
*is* the "local graph"** — "select a node, show its neighborhood to an adjustable depth" — and it was
nearly re-proposed as new scope. It is existing scope, and the only live question is whether it still
means the same thing when nodes are concepts rather than files. It does, and the merge is what makes it
better rather than worse: Q13 converts a term's repeated mentions from duplicate nodes into **graph
degree**, so a concept's neighbourhood at depth 1 is every document and section that mentions it —
which is the impact-analysis answer a file-keyed graph could not give.

Mechanically: `focus.nodeId` plus `focus.depth` (1–6, a design choice) drives a breadth-first expansion
over `visibleEdges` **after** filtering and over the endpoints `edgeFold` gives, so the neighbourhood is a
neighbourhood *of the filtered, folded view* — FR-14a's composition rule applied to the lens that has a
subject, and the reason `focus.nodeId` is resolved through the fold first (D6c clause 2). Depth is applied to the
undirected adjacency, because "what does this change touch" is not a directional question; direction
remains visible in the arrowheads.

##### D6f. The Provenance lens

`'provenance-chain'` emphasis marks edges on a path from a `kb:`-prefixed node to a `source-artifact`,
`image` or `web-page` node and dims the rest — FR-13's "`kb:` → `int:`/`ext:` chains only", read through
the enum. FR-13's "coloured by the `Provenance` column" is carried by a per-provenance **shape marker
and label** in addition to colour, never by colour alone (NFR-5). Note that the chain definition stays
prefix-shaped here rather than kind-shaped, and deliberately: the lens's subject is the **cross-side
chain**, which is what the prefix names, and feature-001 D5's third recorded category boundary makes the
same distinction from the vocabulary side — `lineage` was split from `provenance` precisely so that
document-to-document supersession does not enter a lens whose whole point is the cross-side chain.

#### D7. The two node gestures (FR-14a)

FR-14a separates two jobs that "selecting a node" was doing at once. Both are implemented, both are
keyboard-operable (AC-21), and the split is what stops exploring from navigating away.

##### D7a. Single click — select

Sets `focus.nodeId`. Focuses the node: highlights its neighbourhood, dims the rest, drives the Impact
lens's adjustable-depth view, and scrolls the table view to that node's rows. **Navigates nowhere**, so
exploring never leaves the graph. Keyboard equivalent: `Enter` or `Space` on the focused node control in
the focus combobox, or on the node's row in the table view. FR-14a notes this differs from Obsidian,
where a single click opens the note; here a single click must not navigate, or the Impact lens would be
unusable.

##### D7b. Double click, or the explicit Open control — open the underlying artifact

A second gesture, and a **real focusable `<button>`** in the selected-node detail region — which is what
makes it reachable at all under AC-21, since a double-click has no keyboard equivalent. Per-kind
targets, from `graph.html` at `.aid/knowledge/graph.html`:

| `Kind` | Target | Notes |
|---|---|---|
| `document` | `./<doc>` | Beside `graph.html`, so it resolves against the page's own directory — which is the same basis `validate-html-output.sh` **L2** uses (`href="./X.md"` against `dirname "$HTML"`, **never** against `--kb-dir`, which sets no resolution basis; § Validator surface). **L2 does not reach it**, and the reason is not the shape: L2 greps the **emitted file** (`grep -oE 'href="\./[^"]+\.md"' "$HTML"`), while the Open control is a `<button>` whose target is computed at runtime by `openTarget()`, so no per-node `href` is ever serialised into the page. **GV18** is the test that covers it |
| `section` | `./<doc>#<heading-slug>` | The slug is feature-003 D2a-1's, verbatim. Also unreached by L2, for the same reason as the row above — not because "a fragment defeats the pattern", which was the previous revision's stated reason and is not the operative one, since nothing of this form reaches the emitted file at all. The fragment carries its own test (**GV19**, below) |
| `fact` | `./<doc>` — **the file, with no fragment** | A `fact` id's fragment is `#fact:<anchor-token>`, a **synthetic identifier**, not a document anchor. Appending it would emit a dead link on every fact node. FR-14a asks for "the file it names", and this is it |
| `concept` | its **defining document**, else the highest-provenance mentioning document | Q13(d) and FR-14a. Ordering `declared` > `derived` > `inferred`, tie-broken by `LC_ALL=C` ascending document path so the choice is deterministic. For a `@<doc>`-qualified concept id (feature-003 D2) the qualifier *is* the defining document |
| `source-artifact`, in-repo `image` | `../../<repo-relative-path>` | `graph.html` sits two levels below the repository root, so `../../` reaches it. Doubly outside L2 — never serialised, and not `./X.md` even if it were — so unchecked by it and not failed by it. The in-repo/external split of `image` here and in the next row is a **prefix** read, one of the three D1a enumerates: an `int:` id *is* the path this target needs, and an `ext:` id is a key |
| `web-page`, external `image` | `./external-sources.md`, anchored to the key's row where feature-003 D2c gives one | **Not a raw URL — see below** |

**`web-page` cannot open a resolved URL — a requirement-level finding this SPEC raised and the owner has
since settled.** FR-14a originally said "for a `web-page`, its resolved URL". Resolution requires the KB's
external-sources file: §5.3 states that rows "never carry a raw absolute path or URL for external nodes —
they carry only the key, and the external-sources file remains the single place that resolves it." The view
has the table and nothing else (FR-3, AC-10), so it holds the key and cannot resolve it. **FR-14a as
amended 2026-07-29 (owner decision, STATE.md Q21 item 2) now names `./external-sources.md`** — "the file
that resolves the key ... honest, mechanically checkable, and preserves FR-3's single-input rule" — and
**rejects** carrying the URL in the table, which "would contradict §5.3 and reopen features 003 and 005".
So the target below is the requirement's own text, not this SPEC's substitute, and it is genuinely
L2-checked: the footer carries `./external-sources.md` as a **static** link beside `./relationships.md`
(§ UI Specs), which is the form L2 greps out of the emitted file. **Open Item 1** records the closure
rather than routing a choice.

**The `section` fragment, and feature-003's Open Item 15 — discharged by removing the dependency.**
feature-003 routed here the confirmation that its duplicate-heading `-<N-1>` suffix "is the anchor a
reader's renderer actually resolves", noting that its four other slug rules are each verified against a
KB `## Contents` link but the suffix is not, because this KB's only duplicate-slug group is linked at its
first occurrence only. Three statements discharge it:

1. **The gesture does not depend on the suffix being right.** FR-14a asks the Open gesture to open "the
   file it names". A fragment that does not resolve lands the reader at the top of the correct document —
   correct file, wrong position. So renderer agreement on the suffix is an **enhancement to positioning**,
   not a correctness condition of the gesture, and the dependency feature-003 was routing does not exist.
2. **What *is* tested is agreement with the specified rule, and with the KB's own anchors where they
   exist.** A test recomputes the fragment for every `section` id and asserts (a) it equals feature-003
   D2a-1's algorithm applied to the heading, and (b) where the document's hand-maintained `## Contents`
   links that heading, it equals the fragment that link uses. (b) is a genuine on-disk two-way check and
   it covers all four of feature-003's verified rules.
3. **The residual is stated and not claimed away.** Agreement with any third-party markdown renderer's
   duplicate-heading algorithm is **not verified here and is not claimed**. It could only be verified by
   adding a markdown renderer to the toolchain, which FR-16 permits and no requirement asks for, and the
   affected set is exactly the duplicate-slug headings — which feature-003 established by recomputing
   every heading slug across the KB. Nothing is routed onward.

#### D8. The control manifest — closing AC-21's completeness-in-DOM trap

feature-002 D9 established the route and named the trap, and both are adopted here as the owner of the
controls.

**The route.** AC-21 is decided against the **DOM**, and needs no graphics context. Three facts, each
already on the books: the canvas is visual-only and no control is drawn on it (Q9); every control is a
real focusable HTML element; and NFR-6 states the consequence directly — the accessible table view
provides the keyboard route to select and open, so the canvas's mouse gestures are an enhancement rather
than the only path. So AC-21 survives even total WebGL failure. NFR-4's settled render changes nothing
either: a settled canvas is still a canvas.

**The trap, in AC-21's own words.** The criterion exists because "a control drawn **on the canvas**
rather than as a focusable HTML element would fail WCAG SC 2.1.1 (Level A) while passing AC-7, AC-8 and
AC-8a" — all of which test functional behaviour rather than access. So AC-21 is not a test of the
keyboard handlers; it is a test of **where the controls live**. A keyboard-only drive over whatever DOM
controls happen to exist passes while the criterion fails, because a canvas-drawn control is simply
absent from the set being driven.

**The closure, in three assertions.** The mechanism is a `CONTROL_MANIFEST` — one frozen array, each
entry `{ id, requirement, axis, value }` — from which the shell **builds the control DOM**, so a control
cannot exist without an entry and an entry cannot exist without a control.

| # | Assertion | What it rules out |
|---|---|---|
| **1 — the manifest is data-derived** | For every enumerable axis, the manifest's entries are generated from the same data the model already holds — never re-typed beside it: `filters.categories` from `GraphModel.categories` (feature-001's vocabulary), `filters.kinds` from `keys(KIND_ENCODING)`, `filters.provenance` from `PROVENANCE_VALUES`, and the lens buttons from `keys(PRESETS)`. A test asserts **coverage**: every value of every one of those four sets has an entry (**AC-S7**) | A manifest that is itself incomplete. This is the load-bearing direction: assertion 2 is only as good as the manifest, so the manifest may not be an authored literal. Add a fifteenth category to the vocabulary and the test fails until the filter offers it — which is also AC-8a part 1. **The two closed enums are `Kind` and `Provenance`, and their runtime carrier is deliberately a frozen in-code constant rather than the schema file.** `relationship-schema.yml` is the *authoring* authority (feature-003 D1) and the suite reads it from disk to bind the constants (**GV16**), but the page cannot: a `file://` page has no second fetch (FR-3, AC-10) and the payload it does receive is `relationships.md` alone. Naming a file the browser can never open as a load-time data source is the hole this row closed on 2026-07-30 |
| **2 — manifest ↔ DOM is a bijection** | Every manifest entry has exactly one element in `graph.html` carrying the matching `data-control` attribute, and that element is focusable; and every element carrying `data-control` is in the manifest | A control that moved onto the canvas: its DOM element disappears and the manifest→DOM direction fails. This is the completeness assertion AC-21 asks for, expressed mechanically |
| **3 — each is keyboard-operable** | Each manifest entry is driven by keyboard input only and its effect on `LensState` asserted | Handlers wired to pointer events only. This is the assertion AC-21 names; on its own it is the trap |

The non-enumerable controls — grouping, density, focus, depth, the orphan toggle, select, open, the
**text search**, and zoom/pan's keyboard equivalents — are authored manifest entries. They are authored
because no data set enumerates them; assertions 2 and 3 still bind them, and the entry's own
`requirement` field is what a reviewer checks the list against. That field carries **one of two** values,
and the second exists because one control has no clause:

- **the clause that requires it** — FR-14a (grouping, density, focus, depth, the orphan toggle, select,
  open) or NFR-6 (zoom/pan's keyboard equivalents); or
- the literal **`design-choice`, with its rationale in the entry** — which is the `filters.text` entry
  and nothing else. No requirement asks for a text filter: FR-14a names three filter axes plus the orphan
  toggle, and this is a fourth, added because the fastest way to reach a known node in a graph of this
  size is to type its name. It is labelled the way this SPEC labels every other design choice (the label
  budget, the depth and density ranges) rather than given a citation it does not have — an invented
  citation would be the one failure mode this whole subsection exists to prevent. It is not enumerable, so
  AC-S7 is unaffected; assertions 2 and 3 bind it exactly like a required control, which is what AC-21
  needs.

**The one interactive element deliberately outside the manifest, and why that is not a hole.** A group's
expand/collapse disclosure (D6c clause 3) is **projection-dependent** DOM — which groups exist changes
with every lens and filter — while `CONTROL_MANIFEST` is built once at load from `GraphModel`. A manifest
entry per group would therefore make assertion 2's bijection false the moment a filter removed a group.
So the disclosure carries **`data-group-toggle`**, not `data-control`, which leaves the bijection over
`data-control` exactly as it is, and its completeness is asserted in the other direction instead — **one
focusable disclosure per `ViewModel.groups` entry whose `foldable` is non-zero, and none for any other
group** (GV22, and GV17 at both gate widths so the mobile layout cannot drop it). On `foldable` — the count
the fold *governs* — and never on the count currently folded away, so an expansion cannot delete the
disclosure that has to undo it. That is assertion 1's coverage direction applied to a set derived per
projection rather than per load, so AC-21's real question — is the control set complete against the data,
not merely reachable — is answered for it too. It is a real `<button>`, so NFR-6's keyboard obligation is
met by construction.

Node dragging is excluded, per NFR-6's path-dependent exemption: dragging repositions a node and conveys
no information a keyboard user is denied.

#### D9. Label shortening (feature-003 Open Item 9, discharged)

feature-003 D5 stores full names deliberately — "no truncation is applied to a stored name, even though
a `fact` name can be long" — and routes shortening here as a render-time concern, jointly with
feature-009. The contract:

**Where it applies.** `nodeShortLabels` is used for **on-canvas drawing** and for the table's collapsed
cell. `nodeLabels` — the accessible name on every surface — is **never** the shortened form, so no
screen-reader user is given a truncated identifier (**AC-S8**). `filters.text` matches the stored name
and the id, never the short label.

**When it is computed.** Once, at load, over the **full** `GraphModel.nodes` set — not per projection.
That is what makes a label stable: if uniqueness were resolved over `visibleNodes`, a label would change
whenever a filter changed, and the same node would be called two things in one session. It also keeps
`project()` trivially pure.

**The algorithm.** Budget: **32 characters** — *a design choice, adjustable by the human visual gate, not
a measurement.* Middle-ellipsis with `…`, keeping head and tail, because the distinguishing part of a
path and of an anchor string is at the end.

| `Kind` | Basis | Note |
|---|---|---|
| `document`, `source-artifact`, in-repo `image` | the **basename** | feature-003 D5 keeps full paths because a basename is not unique in this repository — `build-kb-index.sh` exists at several paths — so when a basename is ambiguous across the full node set, the shortest distinguishing leading path segments are prepended before ellipsising. The in-repo/external split of `image` here and in the last row is a **prefix** read, one of the three D1a enumerates: only a path has a basename |
| `section` | the heading text — the part of `<doc> § <heading>` after the separator | The document is conveyed by grouping and by edges |
| `fact` | the anchor string, likewise after the separator | The longest names in the artifact |
| `concept` | the term as written | Usually within budget already |
| `web-page`, external `image` | the key | Opaque and short by construction |

**Collisions are resolved to the point of uniqueness, and termination is guaranteed.** If two nodes'
budgeted forms are equal, the budget for that colliding set is extended in fixed increments until they
differ or the full names are reached. Should two *full* names be equal — which feature-003 **V8** permits,
since it binds one name per id and not one id per name — the short label becomes the **id**, which is
unique by construction. So the procedure always terminates and always yields distinct labels.

#### D10. The coverage predicate — one implementation, two runtimes (AC-15)

*Owner decision, 2026-07-28, unchanged by the redesign except for its keying.* The predicate is defined
**exactly once, in a shared JavaScript module**, imported by the ledger generator in Node and inlined
into the view in the browser. One implementation executed twice, so generator/view agreement is
structural rather than asserted. This subsection is the definitive statement of that module's identity
and its runtime boundary; feature-006 coordinates to it.

##### The module

`canonical/aid/scripts/graph/coverage-predicate.mjs`.

It sits in `scripts/graph/` — beside feature-004's `scan-source.sh` and feature-006's detector, the two
Node-side neighbours it exists to agree with — rather than in the graph's template set, because
`module-map.md` § Conventions places a helper under the phase area it serves and this one serves the
pipeline as well as the page. It is authored under `canonical/` and rendered to every profile tree with
the rest of `aid/scripts/` (**C-2**), so both consumers get the same bytes in every host. The `.mjs`
extension is what makes it importable by Node with no `package.json` in that directory; Node ≥ 20 is
already the floor (**C-5**).

##### The Node/browser boundary, as five rules the file obeys

| Rule | Why it is required |
|---|---|
| No `import`, no `require`, no `node:` specifier | So Node can import it as-is *and* the browser can inline it as-is. A single `import` would break one of the two |
| No `document`, `window`, `globalThis`, `fetch`, timer or event | So a Node process can import it without a DOM shim, and so nothing in it can behave differently between runtimes |
| Only `export function` / `export const` at top level — no `export {}` list, no default export | An `export` declaration is legal at the top level of an inline `<script type="module">`, where it is inert. That is what makes byte-identical inlining possible |
| Every input and output is plain data — arrays, objects, `Map`, `Set` — never a path, handle or stream | All I/O stays in the callers |
| **Render-transform invariant:** no `canonical/…` path reference and none of the three filename placeholders — **in code or in comments** | The profile generator text-processes this file. Without this rule the canonical and rendered copies legitimately differ and GV02 would fail inside a profile tree for a reason that is not a defect |

Rules 1–3 and 5 are greppable, and **GV01** asserts them, so the boundary is checked rather than trusted.

**Why rule 5 exists, verified against the generator.** `.mjs` is a member of `render.py`'s
`_TEXT_EXTENSIONS`, so every rendered copy passes through `substitute_filenames` and then
`rewrite_install_paths`. Both transforms are narrow, which makes the rule cheap to obey:
`substitute_filenames` replaces only the three literal tokens `{project_context_file}`,
`{reviewer_output_file}`, `{open_questions_file}`, leaving every other `{…}` token including a template
literal's `${…}`; and `rewrite_install_paths` rewrites `canonical/…` forms to the profile's install root
— where its comment-skip protection **does not help**, because the skip test is
`line.lstrip().startswith("#")` and a JavaScript `//` or `/* */` comment is not protected. That is the
trap rule 5 prevents: the file must not name its own canonical path even in a header comment. Contrast
the vocabulary artifact, which is `.yml` and therefore absent from `_TEXT_EXTENSIONS`: it is copied
byte-for-byte and needs no such rule. A file obeying rule 5 is a **fixed point of both transforms**,
which is what makes GV02 meaningful in any tree and lets **GV08** assert the invariance directly.

##### How each runtime reaches it

**Browser.** The graph's `post-script.html` emits one inline `<script type="module">` whose body is the
concatenation of `coverage-predicate.mjs` followed by the view's own files in manifest order. The shared
file is inlined **byte-identically** — no transform, no wrapper, no re-export — and **GV02** asserts it
by diffing the inlined region out of `graph.html` against the canonical file. This is the same
inline-a-JS-file idiom `/aid-summarize` already uses for `{{INLINE_LIGHTBOX_JS}}`.

Because the whole block is one module scope, **the view's own files declare no `import` statements** and
reference the shared exports directly; concatenation order is fixed by the manifest, shared module
first. **GV01** asserts it for them too. The constraint is not avoidable by using real module `import`s
at runtime: a `file://` page cannot import a relative ES module, and the entry point is a local `file://`
open. **The same fact constrains the vendored renderer** — see § Packaging.

**Node.** Bash cannot `import` an ES module, so the boundary is: **whatever computes the ledger's gap set
must be a Node process, and must `import` `coverage-predicate.mjs`.** Two shapes satisfy it — (a) a
`detect-kb-gaps.sh` CLI entry that keeps its flags and shells out to a thin `.mjs`, or (b) the detector
authored as `.mjs` outright — and **feature-006 takes shape (b)**:
`canonical/aid/scripts/graph/detect-kb-gaps.mjs`, on the ground that a wrapper "would exist only to
preserve a `.sh` extension and would add a process boundary with nothing on the near side of it", with the
precedent of `validate-visuals.mjs` and `contrast-check.mjs` in the sibling script area. Its interface is
`node detect-kb-gaps.mjs --table PATH --nodes PATH --output PATH [--previous PATH]` plus an `--explain`
read mode, exit `0` for any gap count and `2` for a usage, argument or input-contract error, and it does
`import { detectArtifactGaps, RELATION_CATEGORY } from '../graph/coverage-predicate.mjs'` — a plain
relative sibling specifier, one import, one module. Shape (a) stays admissible for any later Node-side
consumer that needs a `.sh` entry; what is **not** admissible is an awk/grep re-derivation of the
predicate in Bash — the fork this decision exists to remove (**C-4**). *(This paragraph said the detector
was `detect-kb-gaps.sh` and that shape (a) "is the one assumed here"; corrected 2026-07-30 against
feature-006 as gated — a citation that expired when that SPEC was re-specified, and its own Open Item
4(b).)*

##### What the module exports

| Export | Shape | Called by |
|---|---|---|
| `RELATION_CATEGORY` | frozen relation → category, authored from feature-001's vocabulary | both |
| `COVERAGE_BEARING` | `Set<string>` of relation names | both |
| `isCovered(nodeId, edges)` | `boolean` — the three-condition test below | both (internal to the two set functions, exported for its own test) |
| `detectArtifactGaps({nodeIds, edges})` | sorted `string[]` — the `artifact-undocumented` set | both |
| `kbUnbacked({nodes, edges})` | sorted `string[]` — the `kb-unbacked` set | browser only; colocated so all coverage logic reads from one file |

**`RELATION_CATEGORY` is authored *here*, and that is a move rather than an added export** (owner
decision, STATE.md Q25 item 2). The previous revision declared it in `graph-model.js`, which is
**browser-only**, while feature-006's D6 forbids the Node side importing the view model — "importing it
from Node would pull the whole view layer into the pipeline" — so feature-006's F6 false-gap counter had
**no reachable data source at all**, and its AC-G5, GL12 and GL17 were unimplementable as this SPEC
stood. Four properties make this module the right home rather than a compromise: the constant is
**frozen and build-time**, so it is data and not behaviour; this module is **already reached by both
runtimes** (imported under Node, inlined byte-identically in the browser, never imported there); it
imports nothing and touches no DOM global, which a relation→category map cannot change; and rule 3
admits it as-is, since `export const RELATION_CATEGORY = Object.freeze({…})` is an `export const` at top
level. Three consequences, all of them checks getting cheaper rather than looser:

- **GV05** (`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`) becomes a containment check **inside one
  file**, where before it spanned two;
- **GV01** is unaffected **on both sides** — no `import` is added anywhere. Node's detector already
  imports this one module (it now binds two names from it), and the view's files sit in one concatenated
  module scope with this module first, so `graph-model.js` **reads the constant from there** by reference
  and needs neither an `import` nor a re-export;
- the constant has exactly one authored copy, so `categoryOf` (D1) and the F6 counter cannot drift.

Two signature changes from the previous revision, both forced by the ten-column model:

- `detectKbGaps` is renamed **`detectArtifactGaps`**, because the set it returns is
  `Kind = source-artifact` and the old name carried the prefix-keyed reading AC-15's re-key removed.
- `kbUnbacked` takes **`nodes`**, not `nodeIds`. It has to: its **domain** is now `kind ∈ {document,
  concept}` (D6d), and an id cannot supply that, because `kb:` spans four kinds. This is the smallest
  concrete instance of why kind had to become a column — the previous revision's `kbUnbacked({nodeIds,
  edges})` signature was expressible only while `kb:` meant one thing. Its **test** now needs `nodes` for
  the same reason: since D6d re-keyed it to `kind === 'source-artifact'`, the *other* endpoint's kind has
  to be readable too, and `int:` spans two kinds. So one argument change covers both halves.

`detectArtifactGaps` returns the gap **set** and nothing else. Severity and the FR-21 clause stay
Node-side in feature-006, because they need feature-004's `nodes.tsv` (`qualifier`, `evidence`), which
the browser does not have and must not fetch. That split is the point of the boundary: the part both
runtimes must agree on is shared; the part only one runtime can compute is not.

**`nodeIds` is the one input that legitimately differs between the runtimes, and it is why the `orphans`
class exists.** Node passes feature-004's full enumerated `source-artifact` inventory from `nodes.tsv`
— required, not optional (owner decision, 2026-07-28): computing the ledger over table nodes alone would
silently drop the most undocumented artifact there is. The browser can only pass the ids present in the
table. `edges` is identical in both runtimes — the final post-pass-2 table — so the *predicate* has one
behaviour in both; only its candidate set is wider on the side that can see more.

##### The predicate itself

Adopted from feature-006 § D2, which owns its semantics, re-keyed to the kind. An enumerated
`source-artifact` node is **covered** when at least one edge satisfies all three conditions:

1. the node is one of the edge's endpoints, **or** an ancestor path of the node is that endpoint — a KB
   document that documents a directory covers the artifacts inside it (feature-006 class F2). Path
   matching needs no new `Node` field: an `int:`-prefixed id *is* its repo-relative path with the prefix
   stripped, which is what `Node.prefix` is retained for (D1a);
2. the other endpoint's **kind** is `document`, `concept`, `fact` or `section` — the four KB kinds. Stated
   over kinds rather than over the `kb:` prefix so it reads the column the model now carries, which is
   the same set of rows either way, since §5.2 pins all four to `kb:`;
3. the relation naming that direction is a member of `COVERAGE_BEARING`.

Coverage counts from edges of **any** `Provenance`, including `inferred` (feature-006 class F3) — liberal
about what counts as coverage, strict about what counts as a defect. An uncovered node is a gap. F4 is
absent by construction, per the feature-004 invariant recorded at D1a.

**`COVERAGE_BEARING`'s two copies and the test that binds them.** feature-006 owns the *selection* and
**has made it** (its D2a, reached pair by pair from a stated criterion rather than at category
granularity, and discharging feature-001's Open Item 8 there). It records the reviewable copy at
`canonical/aid/templates/graph/coverage-bearing.yml`, a sibling of feature-001's vocabulary artifact so a
reviewer reads the two together; nothing loads it at runtime. `coverage-predicate.mjs` carries the
*executable* copy, because rule 1 forbids importing it. **GV04** asserts the two sets are equal — the same
doc↔code lockstep the project already uses for render drift — and feature-006 states the standing
condition on the pair: if the authored `relation-vocabulary.yml` renames or drops a member, the selection
is **re-derived from D2a's criterion**, never patched. **GV05** asserts
`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`, now a containment inside this one file, so a member that is
not a real relation is a build failure rather than a member that never matches.

##### `kb_gaps` as a recorded result, and the verification against it

*Owner decision, 2026-07-28.* `kb_gaps` stays in `relationships.md` frontmatter but is **demoted from
mechanism to record**: it is the generate-time result, not the lens's source of truth. The view
recomputes with the shared predicate and **verifies** its answer against the record, once per load,
inside `createStore`, after `GraphModel` is built and before either rendering mounts — not per lens
application, since it is a property of the data rather than of the lens.

Let `R` be the recomputed `artifact-undocumented` set, `G` the id set of `recordedGaps`, and `T` the
`source-artifact` ids present in the table:

| Set | Meaning | Verdict |
|---|---|---|
| `viewOnly = R \ G` | the view found a gap the ledger does not carry | **Mismatch** |
| `ledgerOnly = (G ∩ T) \ R` | the ledger carries a gap the view can see the node for but did not find | **Mismatch** |
| `orphans = G \ T` | a ledger gap whose node appears in no row at all — a **zero-row node** | **Expected asymmetry — never a mismatch** |

`coverageGaps.artifactUndocumented` is **always the sorted union `R ∪ G`**. A disagreement therefore
cannot hide a gap on either surface — hiding one is the only failure mode here that costs a reader
something — and `coverageOrigin` records which side each id came from. The union is also what makes
zero-row nodes cost nothing: they arrive through `G` and are surfaced by the same code path as every
other gap.

##### Zero-row nodes (`orphans`) — the most undocumented artifact there is

*Owner decision, 2026-07-28.* `orphans = G \ T` is the same set, under the same definition, feature-006
§ D6 names — one symbol across both SPECs.

An enumerated `source-artifact` node appearing in **no** relationship row is reachable in practice:
feature-004 qualifies by structural significance, and an entry point or a named unit (a test suite, a
manifest, a settings schema) need not have a single typed edge. Such a node is the sharpest instance of
FR-19/FR-20 — an artifact the project considers significant with nothing said about it anywhere — and it
must be impossible for the view to lose. Because `GraphModel.nodes` is built from the table's two id
columns, the view cannot discover these nodes; `kb_gaps` is how they reach the page, which is
`kb_gaps`'s second job beyond verification. Reading it is not a second extraction path: it is
frontmatter of the one file the view already renders from (AC-10).

**Materialisation.** For each id in `orphans`, the loader synthesises a **complete `Node` record**:

| Field | Value | Source |
|---|---|---|
| `id` | the `kb_gaps` entry's `id` | frontmatter |
| `name` | the entry's `name` | frontmatter — the only place a display name for this node exists, which is why `name` is required rather than optional |
| `kind` | `'source-artifact'` | **the class definition, not the id prefix.** `kb_gaps` is scoped to `Kind = source-artifact` by AC-15 as re-keyed and by feature-004's stream split, so the kind is known from *which list the entry came out of*. The previous revision took `'int'` from the prefix; at ten columns that would have been the one place a kind was still prefix-derived, and it would have been ambiguous, since `int:` also carries `image` |
| `prefix` | `'int'` | parsed from the id, and cross-checked against `kind` by D1c check 4 like any node |
| `glyph` | `KIND_ENCODING['source-artifact'].glyph` | assigned by the same rule as every other node; its colour reaches the renderers through `nodeEncoding` like any node's |
| `kbDoc` | `null` | not a KB kind |
| `shortLabel` | computed by D9 over the full node set | no special case |
| `degree`, `degreeByKind` | `0` / empty | it has no edges; the counters are honest, not sentinels |

The record is **complete, not partial, and carries no "synthetic" flag.** That is the load-bearing
choice: every consumer that iterates `visibleNodes` — feature-008's draw loop, feature-009's selection,
the focus combobox, the grouping partition — handles a zero-row node correctly without knowing the class
exists. A flag would invite `if (node.synthetic)` branches in two renderings, which is the drift NFR-3
exists to prevent. The one place the distinction is legible is `coverageOrigin`, which reports
`'ledger-only'` for these ids like any other record-only gap.

**Not a mismatch, and the alarm must not fire on one.** `orphans` is excluded from the comparison **by
construction rather than by a guard clause**: `ledgerOnly` is defined as `(G ∩ T) \ R`, intersected with
`T` precisely so a node the view could never have found is not counted against it. There is no code path
on which a zero-row node reaches the error channel, and the alarm cannot be made to fire on one by a
later edit without changing that set definition, which is a visible change. A run that finds zero-row
nodes is a **normal** run — on a repository with any at all, it is *every* run — and an alarm firing each
time would train the reader to dismiss the one that matters. The reader is told about them in the legend
and the caption, through the ordinary reporting channel.

**Visual distinction — carried by `nodeLabels`, so neither rendering needs a change.** A zero-row node
takes the `artifact-undocumented` emphasis like any gap; the additional fact — that it has no recorded
relationship at all, the more severe of the two — is appended by `project()` to its **`nodeLabels`**
entry: `"<name> — no recorded relationships"`. `nodeLabels` is already the accessible name on every
surface, so both renderings pick the marker up through machinery they already implement and neither can
render it differently from the other. It is text, never colour (NFR-5), so it survives forced-colours
mode; and it is a *label*, not a badge, so it also reaches the announced text, where a purely visual
"this mark has no lines attached" would reach nobody using a screen reader. It is appended to
`nodeLabels` and **not** to `nodeShortLabels`, whose whole purpose is to fit a budget (D9).

**Grouping, density and focus.** Each is specified rather than left to fall out, because a zero-edge node
is exactly where an edge-derived control quietly drops a row:

| Control | Behaviour for a zero-row node | Why |
|---|---|---|
| `grouping: 'node-kind'` | the `source-artifact` group | Derived from the node, not from edges |
| `grouping: 'document'` | **its own single-node group, as its own head** | The same treatment every `source-artifact` node gets under this dimension — D6c's third branch, not a `kbDoc` bucket. `kbDoc` is `null` here, which is exactly why that dimension is kind-dependent rather than keyed on `kbDoc`, and being its own head with no other member it carries `foldable: 0` and is never folded away *(corrected 2026-07-30: this row said "the ungrouped bucket", which contradicted D6c and left `groups` underivable for the kind)* |
| `grouping: 'relation-category'` / `'provenance'` | a dedicated **`no relationships`** group, listed last | These dimensions are edge-derived and this node has none. A dedicated group neither invents a category nor drops the node — and Overview is where a newcomer most benefits from seeing an unattached artifact |
| `density` | shown at level `1`, thinned at `2`–`5` like any node below the threshold | Level 1 thins nothing, and the Coverage preset sets `density: 1`, so a zero-row node is visible in the lens that exists to surface it by two independent routes. Above level 1 the reader has explicitly asked for less |
| `filters.showOrphans` | hidden only when the reader turns the toggle **off** | FR-14a's orphan toggle, default on. This is the one control that may hide such a node, and the requirement says why that must be a deliberate act |
| other `filters` | admitted and excluded exactly like any other node | A reader who filters out `source-artifact` nodes meant it |
| `focus.nodeId` | selectable; at any depth the neighbourhood is the node alone, and `lensSummary` / `announcement` say **"no recorded relationships"** | "What does this touch?" answered with "nothing recorded" is a real and useful answer. Saying it in words is what stops an empty Impact view from reading as a broken one |

**Failing loudly, in a browser artifact.** There is no exit code and no log a reader will see, so
"loudly" means three things at once, and none of them blanks the page:

1. **A persistent error callout**, first child of `<main>`, ahead of both renderings, reusing the existing
   `.callout.err` rule from `component-css.css`. Not dismissible: a reader who closed it would be left
   with a view that looks trustworthy and is not.
2. **Announced.** Its container is present in the shell markup from load with `role="alert"` and empty;
   the text is written one task after mount. A live region must exist before its content is injected in
   order to announce reliably, which is why it is authored empty rather than inserted whole. Written at
   most once per load.
3. **`console.error`** with the stable prefix `graph.html: kb_gaps integrity check failed`, followed by
   the two id lists, so a headless check can assert on the string.

The reader sees plain language, the exact ids both ways, and the fix — that this view recomputed the gap
set and got a different answer from the record, that the lens shows the union so no gap is hidden, that
one of the two is stale, and that the likely cause is `graph.html` and `relationships.md` coming from
different runs. The rest of the view still renders. This mirrors FR-25's reporting-not-gating posture: a
blank page would tell the reader less than a working view with an honest warning, and the gap ledger —
the artifact that *does* need to be right — is a Node-side product this page cannot affect.

**When `kb_gaps` is absent** (`recordedGaps === null`) the check cannot run. That is a `.callout.warn`,
not an error: the page states that the ledger cross-check was unavailable and that the Coverage lens is
showing the view's own recomputation. Treating a file that predates the field as corruption would be a
false alarm, and a false alarm here trains a reader to ignore the real one.

### Feature Flow

The whole flow runs client-side at page load. There is no server and no request.

1. **Read the embedded payload.** The generator embeds `relationships.md` verbatim as
   `<script type="text/markdown" id="graph-relationships" data-encoding="base64">`, reusing the payload
   element contract `/aid-summarize` already ships for its Markdown export (base64 of the UTF-8 bytes,
   decoded with `new TextDecoder().decode(Uint8Array.from(atob(b64), c => c.charCodeAt(0)))`). Reusing it
   matters twice over: the base64 body cannot contain `<`, so it can never be mis-parsed as markup; and a
   `type="text/markdown"` script is the exact case `validate-html-output.sh`'s NM.1 awk rule already
   excludes from its inline-engine heuristic, so a large payload does not trip a Mermaid check it has
   nothing to do with.
2. **Parse the table.** `parseRelationships(text)` performs D2a–D2c and builds `GraphModel`. Any
   condition D1c marks fatal surfaces in **the shell's one `role="alert"` banner** — the same region step
   4b writes, never a third one — and leaves the rest of the shell inert rather than half-rendered. The
   two writers cannot collide: a fatal parse never reaches step 4.
3. **Read the coverage notes.** `parseCoverageNotes(text, stopOffset)` runs over the region the table
   parse stopped before (D2d) and its result is attached to `GraphModel.coverage`. Reporting only; a
   failure here degrades to `null` and never blocks the load.
4. **Create the store.** `createStore(graphModel, INITIAL_LENS)` computes the first `ViewModel` and holds
   `{graphModel, lensState, viewModel}`.
   **4b. Verify against `kb_gaps`.** Still inside `createStore`, before any subscriber exists: recompute
   the `artifact-undocumented` set with the shared predicate, compare it to `recordedGaps`, and store the
   outcome on `graphModel.integrity`. On a mismatch the shell fills the `role="alert"` container one task
   after mount and writes the `console.error` line; on an absent `kb_gaps` it fills the warning callout.
   Both renderings mount either way.
5. **Build the controls from the manifest.** `graph-controls.js` generates the control DOM from
   `CONTROL_MANIFEST` (D8), so the control set is complete by construction rather than by review.
6. **Mount the renderings.** `graph-table.js` (feature-009) and `graph-canvas.js` (feature-008) each
   subscribe and perform a first render from the current `ViewModel`. **The table mounts first and
   unconditionally**, so the artifact is complete and usable on a build where the canvas module is absent
   or where WebGL is unavailable — which is what makes NFR-2's "peer view, not a hidden fallback" true at
   the level of load order rather than only in wording, and what makes the artifact survivable if
   feature-002's Stage-1 probe lands negative.
7. **Interact.** A control or a preset button calls `store.setLens(patch)`. The store merges,
   re-projects, bumps `revision`, and notifies every subscriber with the new `ViewModel`. Both renderings
   update from the same object in the same tick, so there is no window in which the graph and the table
   disagree. Hover does **not** go through the store (D3).
8. **Announce.** `graph-controls.js` writes `viewModel.announcement` into the single
   `aria-live="polite"` status region and `viewModel.canvasAlt` into the canvas's `aria-label` — both
   **once per lens change, never per frame**. This is the SC 4.1.3 status-message obligation, and
   batching it at the state boundary rather than the draw boundary is what keeps accessibility-tree
   rebuilds off the frame path, which feature-002's research names as the expensive operation.

**Exactly two live regions, and no more.** The polite status region carries lens changes; the
`role="alert"` region carries **whichever load-time failure occurred** — D1c's fatal load error (step 2)
or step 4b's `kb_gaps` mismatch — and is written at most once per load, which holds because the two are
mutually exclusive rather than because a guard prevents the second. Two
regions with disjoint purposes and a fixed count stay checkable; a third would make "which region said
that" unanswerable. The canvas's `aria-label` is **not** a live region and is not announced on change.

### Layers & Components

Authored **once in `canonical/`** and rendered to every host profile by the existing generator (**C-2**);
the rendered copies under `profiles/`, `packages/*/_vendor/` and the dogfood `.claude/` tree are build
output and are never hand-edited. New files follow `module-map.md` § Conventions.

```
canonical/aid/templates/knowledge-graph/        # new; sibling of knowledge-summary/
├── graph-skeleton.html        # placeholder shell, seeded from knowledge-summary/html-skeleton.html
├── graph-css.css              # graph, table and control styles — AND the palette custom properties (D5a)
├── graph-model.js             # THIS FEATURE: parser, coverage-notes reader, encoding maps, LensState, project(), store, presets
├── graph-controls.js          # THIS FEATURE: CONTROL_MANIFEST, control wiring, both live regions
├── graph-table.js             # feature-009
├── graph-canvas.js            # feature-008
├── lens-presets.md            # the preset patch table and the palette assignment, in prose, for reviewers
└── accessibility-checklist.md # graph addendum to knowledge-summary/accessibility-checklist.md

canonical/aid/scripts/graph/                    # shared with feature-004, feature-005 and feature-006
└── coverage-predicate.mjs     # THIS FEATURE: the single coverage predicate + RELATION_CATEGORY, run in Node and inlined in the browser
```

`coverage-predicate.mjs` is the one file here that does **not** live in the template set, and the
placement is deliberate: it is imported by a Node process as well as inlined into the page, so it belongs
under the phase area it serves, beside the Node-side scripts it must agree with. It is also why
`RELATION_CATEGORY` is authored in it rather than in `graph-model.js`: the constant is build-time data
that a **Node** process needs (feature-006's F6 counter), and `graph-model.js` is browser-only (D10;
STATE.md Q25 item 2).

**Reused verbatim, not forked (FR-12, C-4, AC-17).** This feature adds **no assembler and no validator**:

| Reused | How |
|--------|-----|
| `canonical/aid/scripts/summarize/assemble.sh` | Invoked with `--src .aid/.temp/graph/graph-src --manifest …/section-manifest.txt --output .aid/knowledge/graph.html`. All three are real flags (verified on disk) and every path it touches is flag-overridable, so the graph needs no fork: it writes the same `skeleton-head.html` / `sections/*.html` / `section-manifest.txt` / `skeleton-foot.html` / `post-script.html` layout the script already validates for existence and non-emptiness |
| `canonical/aid/scripts/summarize/validate-html-output.sh` | Run against `graph.html` for H1, A1–A5, S2, NM, L1, L2 — see § Validator surface for which part of the artifact each binds |
| `canonical/aid/scripts/summarize/contrast-check.mjs` | Run against `graph.html`, **parameterised** for the graph palette's two extra selector blocks and its new pairs at a 3:1 target (D5a). `kb.html`'s eleven pairs stay at 4.5 and unchanged |
| `canonical/aid/templates/knowledge-summary/component-css.css` | Inlined ahead of `graph-css.css`. It already carries `.tbl-wrap`/`table.tbl`, `.callout.err`/`.callout.warn`, `.skip-link`, the `:focus-visible` rule, and the `@media (prefers-reduced-motion: reduce)`, `@media (forced-colors: active)` and `@media print` blocks |
| `canonical/aid/templates/knowledge-summary/lightbox.js` | Inlined **verbatim** into the `{{INLINE_LIGHTBOX_JS}}` tail. It supplies the theme toggle (shared `aid-dashboard-theme` key), scrollspy, and the lightbox with `getLightboxFocusables` / `trapFocusOnTab` / `lastFocused.focus()` / the Escape handler — which is exactly what `validate-html-output.sh`'s A3 greps for |
| `canonical/aid/templates/knowledge-summary/design-tokens.md` | The base palette. `graph-css.css` consumes those tokens via `var(--token)` for chrome, and **adds** the fifteen graph palette tokens D5 specifies — which is the change from the previous revision |

**No modal of our own.** The only dialog in `graph.html` is the reused lightbox, used for the
legend/structure visual. Node and row detail is an inline expanding region, not a modal — so the page
ships exactly one focus trap, A2 and A3 pass against unforked code, and there is no second trap to keep
correct.

#### Packaging and the entry point (FR-16, AC-6, A-4, FR-9, C-8)

All three original packaging restrictions are withdrawn (FR-16; C-1 withdrawn), so this SPEC specifies a
packaging *contract* that admits every layout FR-16 permits rather than mandating one.

- **Entry point:** `.aid/knowledge/graph.html` (FR-9, A-4). This is the documented entry point AC-6
  refers to, and **C-8** records that reaching it through the dashboard is deliberately out of scope: the
  dashboard's leaf allowlist admits `home.html` and `kb.html` only and its CSP is `default-src 'self'`.
  Opening the local file is the intended access path.
- **Companion assets:** `.aid/knowledge/graph-assets/`. A subdirectory is safe by construction — the KB
  index generator enumerates candidates with `find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`,
  so nothing below the first level, nothing without `.md`, and nothing dot-prefixed is ever treated as a
  KB document. This satisfies FR-9's naming requirement three times over and needs no generator change.
- **Reference layout: local-vendored companions, no network at load.** `d3-force` and PixiJS ship as
  files under `graph-assets/`, referenced relatively. Two consequences worth stating because they are
  what make the reused gates pass, both verified on disk: `validate-html-output.sh`'s **S2** greps
  `<script[^>]+src="https?://` and `<link[^>]+href="https?://`, so a relative `src` does not match and S2
  passes; and **NM.1** inspects **inline** scripts only (an awk pass over `<script>` bodies, skipping
  `text/markdown` payloads, failing a non-payload inline block over 100 000 bytes containing `mermaid`),
  so a bundle referenced as a companion file cannot trip it at all. If feature-012 chooses to **inline**
  the bundle instead, NM.1's token condition becomes live and feature-002's measurand 9 verdict is what
  decides it.
- **The vendored bundles must be classic scripts, not ES modules.** A `file://` page cannot import a
  relative ES module — the same fact that forces the view's own files to declare no `import` (D10) — so a
  UMD/IIFE build is required and an `import`-only distribution is not usable at this entry point. Classic
  `<script src>` elements execute in order before deferred and module scripts, so the globals are
  available to the inline module block. Routed to feature-012 as a constraint on the bundle it wires.
- **Runtime prerequisites must be written down (AC-6).** The generator emits, into the page footer *and*
  the run's console summary: whether a network is required, which companion files must travel with the
  entry point, whether a build output is involved, and — new in the redesign — that a **working WebGL
  context** is required for the live graph, with the statement that the table view remains fully usable
  without one. The content of the WebGL sentence depends on feature-002's Stage-1 verdict; its presence
  does not.

#### Validator surface — and AC-9's check-to-surface mapping

AC-9 requires this SPEC to state "which existing check applies to which part of the artifact, so nothing
is asserted against a surface that cannot satisfy it." Read against the scripts as they are:

| Assertion | Surface it binds | Verdict for `graph.html` |
|---|---|---|
| **H1, A1–A5** (`validate-html-output.sh`) | **page structure and the table view** — never the canvas | Pass by construction: real landmarks, a skip link, real `<label for>` controls, the reused `:focus-visible` rule, and the reused lightbox's focus-trap functions A3 greps for |
| **L1** (anchor links resolve) | the page | Every `href="#X"` must match an `id="X"` **in the page** (verified). The Open gesture's target is `./doc.md#slug`, which is computed onto a `<button>` rather than emitted as an `href` and does not begin with `#` either way, so L1 does not reach it |
| **L2** (relative `.md` links resolve) | the page | Greps the **emitted file** for `href="\./[^"]+\.md"` (`validate-html-output.sh`:386) and resolves each against **the file's own directory** — `HTML_DIR=$(dirname "$HTML")` at :62, used at :391; re-read on disk this cycle. `--kb-dir` (default `.aid/knowledge`) sets **no** resolution basis whatever its own help text says: it is assigned at :35/:43 and read only by L2's progress line at :384, so passing it cannot change what L2 resolves against. The two coincide here only because `graph.html` sits in `.aid/knowledge`. Its input set is **three** distinct targets: the footer's `./relationships.md` and `./external-sources.md`, plus `<noscript>`'s `./INDEX.md` (`<noscript>` links `./relationships.md` too, which the script's `sort -u` collapses). All three resolve in the delivered tree — `INDEX.md` and `external-sources.md` are already in `.aid/knowledge/`, verified on disk, and `relationships.md` is this work's own artifact, emitted beside `graph.html`. Per-node Open targets reach it **not at all** — they are computed at runtime onto a `<button>` (D7b) — and an anchored `./doc.md#slug` or a `../../` repo path would not match the pattern even if one were serialised. The anchored form carries its own test (GV19) |
| **S2** (offline render) | the page | Passes under the reference local-vendored layout; fails **by design only if the chosen packaging references a CDN** |
| **NM** (no Mermaid engine) | inline scripts and CDN `<script src>` | All three sub-checks are keyed on the literal token `mermaid`. Under the reference layout the bundle is not inline, so NM.1 cannot see it; NM.2 and NM.3 are unaffected. Passes |
| **C1/C2** (`contrast-check.mjs`) | the **declared CSS custom properties** | The previous revision's "keeps passing without new pairs" claim is **void**. Requires the parameterisation at D5a: two extra selector blocks and the graph pairs at 3:1, with `kb.html` unchanged |
| **S7 / T1–T4** (`validate-visuals.mjs`) | `.diagram-box`, `.infographic`, and top-level `<svg>` — **verified: a `<canvas>` matches none of the three** | The reserved **T2** live-surface exclusion is therefore a **recorded no-op** under the decided architecture (feature-002 Open Item 8). Any *authored* visual — the legend, an infographic — stays inside the gate |
| **S7 hermetic render** | the page under Playwright | The script routes `**/*` and **aborts every request whose URL does not start with `file://`** (verified). A CDN layout renders without its renderer and cannot pass the visual gate — a second reason the reference layout is local-vendored |
| **The canvas element itself** | — | Carries **only a text alternative** (`role="img"` plus `aria-label` from `viewModel.canvasAlt`). No DOM-level a11y assertion is made against it, because Q9 made it visual-only and AA conformance rests on the table view as the conforming alternate version (NFR-2) |

One further capture-time dependency: if feature-002's Stage-1 probe returns "context and readable pixels
but nothing capturable" (its L3 ✗), `validate-visuals.mjs` needs a **capture exemption** rather than an
overlap exclusion. That is feature-011's parameterisation to write and feature-002's verdict to trigger;
nothing here changes.

### API Contracts

The store is the only interface feature-008 and feature-009 hold against this feature. It is a plain
module — no framework, no build step of its own, ES module syntax per `coding-standards.md`.

```js
// graph-model.js — the whole surface feature-008 and feature-009 may use.

parseRelationships(markdownText)        // -> GraphModel        (throws on any D1c fatal condition)
parseCoverageNotes(markdownText, stop)  // -> CoverageReport | null   (reporting only; never membership)
project(graphModel, lensState)          // -> ViewModel         (pure)
PRESETS                                 // frozen preset -> Partial<LensState>; contains no filters.* key
INITIAL_LENS                            // frozen LensState, preset: null
KIND_ENCODING                           // frozen Kind -> { colourToken, glyph }        (D5c)
PROVENANCE_VALUES                       // frozen [declared, derived, inferred]         (D3)
CATEGORY_ENCODING                       // frozen category -> { colourToken, lineStyle } (D5b)
CONTROL_MANIFEST                        // frozen array of control descriptors           (D8)

// RELATION_CATEGORY (frozen relation -> category, FR-6) is on this surface but is NOT authored here:
// it is authored in coverage-predicate.mjs and read from there (D10; STATE.md Q25 item 2). In the
// browser that is a plain reference inside the one concatenated module scope, so no import and no
// re-export is added and GV01 is unaffected; in Node the detector imports it from the shared module.

createStore(graphModel, initialLens)    // -> Store
// Store:
//   getViewModel()        -> ViewModel   (current projection)
//   getLens()             -> LensState   (frozen copy; mutating it does nothing)
//   setLens(patch)        -> ViewModel   (shallow merge, re-project, notify, return the new VM)
//   applyPreset(name)     -> ViewModel   (setLens(PRESETS[name]) plus preset: name)
//   openTarget(nodeId)    -> string      (the D7b href for a node; pure, so it is testable headless)
//   subscribe(listener)   -> unsubscribe
//     listener(viewModel, lensState, changedKeys)
```

**Coverage is not on this surface.** `coverageGaps` and `coverageOrigin` reach feature-008 and
feature-009 as `ViewModel` fields; the functions producing them live in `coverage-predicate.mjs`, which
the renderings never call directly.

Seven rules bind every consumer, and together they are what make NFR-3 and AC-7 mechanical:

1. **Render from `ViewModel`, never from `LensState`.** A renderer may read `lensState` only for its own
   private field (`zoom` for the graph, `sort` for the table). Deciding membership or emphasis from
   `LensState` re-implements `project()` and is the exact drift NFR-3 forbids.
2. **`project()` stays pure.** No DOM, no `Date`, no `Math.random`, no layout measurement. This is what
   lets the same `LensState` be asserted against both renderings in a test with no browser — and, since
   feature-002's Stage-1 probe may report no WebGL context, what keeps every lens assertion runnable
   anyway.
3. **Notification is synchronous and total.** Every subscriber is called on every change with the same
   `ViewModel` instance. A renderer may debounce its own *drawing*, but not its reading — which is how a
   graph that skips frames still never shows a different edge set from the table.
4. **`ViewModel` is treated as frozen.** Ordering (`visibleEdges` by `row`), labels and encodings are
   shared values; a renderer that adjusts them locally makes the two surfaces disagree about what a node
   is called or what colour a category is.
5. **Take kind from `Node.kind`, colour and shape from `nodeEncoding`/`edgeEncoding`, and never parse an
   id.** §5.2's rule, restated as a consumer obligation because the consumers are where it would be
   violated. **AC-S3** asserts it at source level as well as behaviourally, since the failure mode is a
   silent fallback rather than an error.
6. **Hover may change appearance, never membership.** Hover is renderer-local and does not go through
   the store (D3); anything that changes which marks exist goes through `setLens`.
7. **Take each edge's endpoints from `edgeFold` — never from `Edge.sourceId`/`targetId`, never from
   `foldedInto` — and draw or list nothing for a `'collapsed'` entry.** The fold's whole effect on edges is
   applied there already (D6c clause 2); `Edge`'s own ids stay on the record for citation. A renderer that
   resolved the fold itself would make edge membership a per-renderer convention, which is the one thing
   D3's "interpreted exactly once, in `project()`" forbids.

**Test hook for AC-7 and AC-8a.** Because the store is pure and headless, the per-lens obligation is a
plain assertion rather than a UI walk: for each of the four presets, project it over a fixture and assert
(a) the projection differs from the initial projection — "each visibly changes the view" — and (b) the
same `ViewModel` drives both renderings. AC-8a part 1 is the same shape: at `grouping: 'none'`, apply a
single-category filter and compare `counts.edges` — the drawn count AC-8a's "rendered count" names —
against the fixture's row count for that category; under a **folding** dimension the two differ by the
collapsed rows (D6c clause 2). AC-8a part 2 is AC-S6, a property of `PRESETS`, not a UI sequence.

### UI Specs

#### Component breakdown

| Component | Role | Notes |
|-----------|------|-------|
| Skip link | First focusable element, `class="skip-link"` | Reused; asserted by the structural check |
| Top bar | `<header role="banner">` — title, breadcrumb, theme toggle | Mirrors the summary shell; A1.2 asserts the role |
| Lens bar | Four preset buttons, each a real `<button>` in a `<nav aria-label="Preset lenses">` | `aria-pressed` reflects `lensState.preset`; never `disabled` (AC-8). Generated from `keys(PRESETS)` via the manifest (D8) |
| Control panel | Grouping `<select>`; density `<input type="range" min="1" max="5">`; **three** filter fieldsets — category (from `GraphModel.categories`), node kind (the seven values of `keys(KIND_ENCODING)`), provenance (`PROVENANCE_VALUES`); the **orphan toggle** `<input type="checkbox">`; a text `<input type="search">` (the one `design-choice` entry, D8); focus-node combobox; depth stepper | Every control has a real `<label for>`, carries a `data-control` attribute, and is generated from `CONTROL_MANIFEST` — which is what makes the set complete rather than merely present (D8). All remain enabled at all times (FR-14) |
| Group headers | Under a folding dimension, a group whose `foldable` count is non-zero carries a real focusable `<button aria-expanded data-group-toggle>` naming the group and that count, with `aria-expanded` taken from `groups[].expanded` | The Overview drill-in (D6c clause 3), and the same element folds the group again: presence is keyed on `foldable`, which expanding does not change. Deliberately **not** a `data-control` element — the manifest is built once at load and this DOM is per projection (D8) — so its completeness is asserted against `ViewModel.groups` instead; never `disabled` (AC-8) |
| Graph region | `<section aria-label="Relationship graph">` wrapping the drawing surface | Owned by feature-008. The `<canvas>` carries `role="img"` and `aria-label` from `viewModel.canvasAlt` and nothing else (AC-9 as scoped) |
| Table region | `<section aria-label="Relationship table">` wrapping the peer table | Owned by feature-009 |
| Selected-node detail | Inline expanding region: the node's full name, kind, degree, and a real **Open** `<button>` (D7b) | Not a modal. The Open control is what gives the double-click gesture a keyboard equivalent (AC-21) |
| Legend | A `.diagram-box` mapping each glyph to its kind **in words**, each colour to its category, and each line style to the categories sharing a colour; plus the arrowhead/no-arrowhead reading of direction | Authored visual; stays inside the S7 gate. SC 1.1.1's text alternative for the encoding |
| Coverage panel | `viewModel.coverage` rendered: per kind, its carrier convention, `present`/`absent`, and the node count; the FR-22 exclusion statuses; the extra rows as given; and the difference between each enumerated count and the count present in the table | The reporting channel for D2d. Also where feature-005's `concept-merge-candidates` count and **the two reach counters that share its `note`** surface (see Open Item 9) |
| Integrity banner | A `.callout.err` region with `role="alert"`, first child of `<main>`, present but empty at load, filled on **either** load-time failure and at most once per load — a D1c **fatal load error** (step 2), in which case neither rendering mounts, or a `kb_gaps` **mismatch** (step 4b), in which case both do | The two are mutually exclusive, so this is still one region and the page still has exactly two (§ Feature Flow). Not dismissible; degrades to `.callout.warn` when `kb_gaps` is absent. Reuses an existing style |
| Status line | One `aria-live="polite"` region carrying `viewModel.announcement` | The page's only *polite* region |
| Footer | Generation stamp, the relative links to `./relationships.md` **and `./external-sources.md`**, and the AC-6 prerequisites including WebGL | Naming both here is what makes the Validator surface row true: the `web-page` Open target is the same file, but it is a runtime `<button>` target and never an emitted `href` (D7b). These are two of the **three** `./*.md` targets L2 sees — `<noscript>`'s `./INDEX.md` is the third, one row below — and L2 resolves each against the file's own directory |
| `<noscript>` | Explains that the view needs script and links `./relationships.md` and `./INDEX.md` | Asserted by the structural check, and the honest answer to FR-17 |

Both renderings are present in the DOM at all times and neither is nested inside the other — the table is
a **sibling** of the graph, which is the structural form of "peer rendering" (NFR-2). Visual order is
graph-then-table on wide viewports and table-then-graph below the mobile breakpoint; **DOM order is
table-first**, with the visual order set in CSS, so tab order reaches the usable-everywhere surface first
without either region being hidden.

#### State management

One store, one `ViewModel`, no component-local copies of anything in `LensState`. Controls are
uncontrolled inputs whose values are written into the store on `change`/`input`; the store's notification
then reconciles every control's displayed value against `lensState`, so a preset button and a slider can
never disagree about the current density. Nothing is persisted between loads except the theme, which
stays on the existing shared `aid-dashboard-theme` key so the graph, the summary and the dashboard agree
— a new key would visibly desynchronise them.

#### Responsive behaviour

Mobile breakpoint 768 px, max content width 1200 px, matching `design-tokens.md` § "Spacing & sizing" —
the graph must not introduce a second breakpoint scale. Below the breakpoint the control panel collapses
into a `<details>` disclosure and the grid collapses to one column; **the disclosure is open by default
and the controls remain in the DOM when closed**, because D8's manifest↔DOM assertion binds presence, and
a control panel that unmounted its contents would fail it on a narrow viewport while passing on a wide
one. The two widths the visual gate measures at are 732 px and 390 px, so those are the two the layout is
checked against; no region may overflow its own container horizontally at either (T4).

#### Palette integration

`graph-css.css` uses `var(--token)` exclusively for chrome — `--accent` for focus and selection,
`--text-dim` for dimmed marks, `--err`/`--warn` for the callouts — and **adds** the graph palette: seven
`--gk-*` node-kind tokens and eight `--gc-*` category tokens (D5b, D5c), declared in the two blocks D5a
specifies, in both themes, with names inside `contrast-check.mjs`'s `[a-z-]+` charset. Drawing code
resolves a token to a value at draw time and never carries a colour literal (**AC-S4**). Any inline SVG
the graph authors uses `fill="var(--token)"` rather than a hex literal, per `design-tokens.md`, so both
themes work from one authoring.

#### Accessibility

NFR-1 sets WCAG AA. The criteria this feature is answerable for, and how:

| Criterion | How this feature satisfies it |
|-----------|------------------------------|
| 1.3.1 Info & Relationships | Real landmarks and real controls; the table is a real `<table>` (feature-009); the two renderings are siblings |
| **2.1.1 Keyboard (Level A)** | Every control is a native focusable element built from `CONTROL_MANIFEST`, and **completeness** — not merely reachability — is asserted (D8, AC-21). Zoom and pan keyboard equivalents are feature-008's, per NFR-6; dragging is exempt |
| 2.4.7 Focus Visible | The reused `:focus-visible` rule; asserted by A5 |
| 2.4.11 Focus Not Obscured | The top bar is sticky, so scroll-into-view uses `scroll-margin-top` on focusable targets sized to the bar |
| 1.4.3 Contrast (text) | Chrome tokens only; the existing pairs at 4.5 keep passing |
| **1.4.11 Non-text Contrast (Level AA)** | The graph palette is CSS custom properties, checked at **3:1** (D5a). This is the criterion the previous revision's "adds no colour token" claim silently left unchecked |
| **1.4.1 Use of Color (Level A)** | Node kind by colour **and** shape (seven glyphs); category by colour **and** line style with the within-colour uniqueness rule (D5b); relationship name on hover/selection and always as text in the table; direction by arrowhead, its **absence** signalling a symmetric relation |
| 4.1.3 Status Messages | Two live regions and no more: one `aria-live="polite"` written once per lens change; one `role="alert"`, present-but-empty at load and written at most once. The canvas's `aria-label` is not a live region |
| 1.1.1 Non-text Content | Every authored visual carries a text alternative; the legend states each glyph, colour and line style in words; the canvas carries `role="img"` plus `aria-label` |
| Reduced motion | The reused `@media (prefers-reduced-motion: reduce)` block; the shell exposes the preference and the settled-layout obligation is feature-008's (NFR-4, AC-9) |
| Forced colours | The reused `@media (forced-colors: active)` block for the page; the canvas drops colour entirely and relies on shape, line style and filtering (D5d) |

**Granularity, deliberately.** Following the prior art's warning against one tab stop per datum, the
shell exposes the *aggregates* — the lens bar, the controls, each group, and the focused node — as tab
stops, and lets the table carry the raw rows. That keeps announcements useful at Overview density, where
a per-node tab order would be hundreds of stops deep and would say almost nothing.

### Tests

Fixtures are self-built and depend on no work folder's contents (**A-6**); suites live under
`tests/canonical/` as `test-*.sh`, which is how `tests/run-all.sh` discovers them. The `GV*` assertions
live in **`tests/canonical/test-graph-view-shell.sh`**, matching the convention features 010, 012 and 013
already follow.

| ID | Assertion | Criterion |
|---|---|---|
| **GV01** | `coverage-predicate.mjs` contains no `import`/`require`, no `node:` specifier, no `document`/`window`/`globalThis`, no `canonical/` substring and none of the three filename placeholders; the view's `.js` files contain no top-level `import`, and no `fetch`, `XMLHttpRequest` or dynamic `import(` appears in any of them — AC-10's "no second extraction path" in the one form that is greppable, the payload being embedded (§ Feature Flow step 1) | D10 rules 1–3, 5; **AC-10** |
| **GV02** | the module's inlined region in a generated `graph.html` is byte-identical to the `coverage-predicate.mjs` **of the tree that generated it** — `<install-root>/aid/scripts/graph/coverage-predicate.mjs`, never a hard-coded `canonical/…` path | D10 |
| **GV03** | `import`ing the module in a bare Node process succeeds and `detectArtifactGaps` returns the expected set over a fixture; the **same** import binds `RELATION_CATEGORY`, which is what feature-006's F6 counter reaches for — its **GL12** asserts the identical seam from the Node side, so a regression that moved the constant back into `graph-model.js` fails on both | D10 |
| **GV04** | `COVERAGE_BEARING` equals the `coverage_bearing:` sequence in `canonical/aid/templates/graph/coverage-bearing.yml` (feature-006 D2a), the reviewable copy beside feature-001's vocabulary artifact | D10 |
| **GV05** | `COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`, both read from `coverage-predicate.mjs` — a containment inside one file | D10 |
| **GV06** | over a fixture with a deliberately wrong `kb_gaps`, the load-time check reports the exact `viewOnly`/`ledgerOnly` ids, `coverageGaps.artifactUndocumented` is the union, and both renderings still mount | D10 |
| **GV07** | a zero-row `kb_gaps` entry produces a complete `Node` record carrying the entry's `name`, `kind === 'source-artifact'`, `degree === 0`, `coverageOrigin === 'ledger-only'`, **no** mismatch alarm, presence at `density: 1`, membership of the `no relationships` group under the two edge-derived grouping dimensions, its **own single-node group** under `grouping: 'document'` with `foldable === 0` and absence from `foldedInto`, and a `nodeLabels` entry ending `— no recorded relationships` | D10 |
| **GV08** | every rendered copy of `coverage-predicate.mjs` under `profiles/` is byte-identical to the canonical file — the fixed-point property rule 5 buys. The suite may name `canonical/…` freely: rule 5 binds the module, and `tests/` sits outside `canonical/` so the generator never renders it | D10 |
| **GV09** | a fixture whose header row differs from feature-003 D1's literal by one column fails the load with both headers quoted; a nine-column and an eleven-column row each fail | **AC-S1** |
| **GV10** | a fixture whose `## Coverage notes` section contains a pipe table yields a `GraphModel` with exactly the pre-notes row count, and `visibleNodes`/`visibleEdges`/`edgeFold`/every emphasis map are unchanged when the notes are replaced wholesale | **AC-S2** |
| **GV11** | a fixture row carrying `\|` inside a `fact` display name parses to ten cells with the pipe restored | D2b |
| **GV12** | every `Kind` value is exercised; `image` + `ext:` **passes** and `image` + `kb:` **fails**; a `kb:` id whose `Kind` disagrees with its own grammar fails; and two **`ext:`** nodes with different keys, one `web-page` and one `image`, receive different colour tokens and glyphs — the decisive assertion, because feature-003 D1a fixes `ext:` as the one place kind is **unrecoverable from the id**, so no id-deriving implementation can pass it *(a `kb:` `document`/`concept` pair is not decisive: identical ids are one node, and distinct ones differ by the grammar V13 tier 2 derives kind from)* | **AC-S3**, D1c check 4 |
| **GV13** | every `--gk-*` and `--gc-*` token is present in both theme blocks, matches `[a-z-]+`, and is found by a run of the parameterised `contrast-check.mjs`; and no hex or `rgb(` literal appears in `graph-canvas.js` or `graph-model.js` | **AC-S4** |
| **GV14** | over the fourteen categories, the (colour, line-style) pairs are pairwise distinct and no colour holds two categories with the same line style; at most eight distinct colour tokens are used | **AC-S5**, AC-8a part 3 |
| **GV15** | for each preset, `keys(PRESETS[p])` contains no `filters.*` key; and applying each preset after setting a single-category filter leaves `filters.categories` unchanged | **AC-S6**, AC-8a part 2 |
| **GV16** | `CONTROL_MANIFEST` covers every category in the fixture vocabulary, every value of `keys(KIND_ENCODING)` and of `PROVENANCE_VALUES`, and every key of `PRESETS`; **and those two constants equal `canonical/aid/templates/graph/relationship-schema.yml`'s `kinds:` and `provenance:` lists** — the doc↔code lockstep GV04 uses, read from disk by the suite because the page cannot read it (D3, D8 assertion 1). A fixture vocabulary with an extra category fails until the axis grows | **AC-S7** |
| **GV17** | manifest↔DOM bijection over `data-control` attributes in a generated `graph.html`, every matched element focusable; then each is driven by keyboard input only and its `LensState` effect asserted; **and every `data-group-toggle` element is focusable and keyboard-operable** (its completeness is GV22's). Asserted at both gate widths, so the mobile `<details>` collapse of the control panel cannot drop either kind | **AC-21**, D8, NFR-6 |
| **GV18** | `openTarget` returns the D7b href for every kind, including a `fact` href with **no** fragment, a `concept` href resolved by the defining-document rule and then by the provenance fallback with its tie-break, and `./external-sources.md` for a `web-page` | D7b |
| **GV19** | every `section` fragment equals feature-003 D2a-1's algorithm applied to the heading; and where the document's `## Contents` links that heading, it equals the fragment that link uses | D7b |
| **GV20** | `nodeShortLabels` is stable across a filter change and a lens change; `nodeLabels` is never the shortened form; two nodes with equal budgeted forms resolve to distinct labels, and two with equal full names resolve to their ids | **AC-S8**, D9 |
| **GV21** | a `fact` node with no edge to a `source-artifact`/`image`/`web-page` node appears in `integrity.unbackedFacts` and in **no** emphasis class, and a `section` with no such edge appears in neither; and a `document` whose only incident edge reaches an in-repo **`image`** *is* in `kb-unbacked`, which is the assertion the old prefix-keyed test failed | D1c check 9, D6d |
| **GV22** | **the Overview fold, both directions:** under `grouping: 'document'` a document's `section`/`fact` members are absent from `visibleNodes`, present in `foldedInto` mapping to that document, counted in `groups[].foldable` and `counts.hiddenNodes`, and that group's `expanded` is `false`; a row between two members of one group has `edgeFold` `'collapsed'`, is counted in `counts.hiddenEdges`, and still carries its original ids, `key` and `row` in `visibleEdges`; adding the group's key to `expandedGroups` restores every member, leaves `foldable` unchanged, sets `expanded` true and empties that group's share of `foldedInto`, and **removing it folds them again**; exactly one focusable `data-group-toggle` element exists per group whose `foldable` is non-zero — before **and after** an expansion — and none for any other group; a `section` that is `focus.nodeId` when the dimension is chosen is absent from `visibleNodes` with `nodeEmphasis` carrying `'focus'` for its document instead; `counts.nodes + counts.hiddenNodes` equals `GraphModel.nodes.size` and `counts.edges + counts.hiddenEdges` equals `rowCount`; and `foldedInto` is **empty** with every `foldable` `0` under all four other dimensions | D6c, FR-13, D8, **AC-8** ("the preset has not locked the view", for the one control GV24 does not reach) |
| **GV23** | the generated `graph.html` footer **and** the run's console summary each state the runtime prerequisites — network requirement, companion files, build output, and a **working WebGL context** named explicitly, with the sentence that the table view remains usable without one | **AC-6** |
| **GV24** | after each of the four presets is applied, the grouping `<select>`, the density range, every zoom/pan keyboard control and every filter control is present, **not `disabled`**, and a subsequent write to each changes `ViewModel` — AC-8's "then all of them remain usable" over every control the criterion names. GV15 asserts a different property, that a preset does not *reset* a filter (AC-S6, AC-8a part 2) | **AC-8** |
| **GV25** | `INITIAL_LENS` is `preset: null`, `grouping: 'none'`, `expandedGroups: []`, `density: 1`, the three enumerable filter axes each admitting their whole domain, `filters.text: ''`, `showOrphans: true`, `emphasis: 'none'`, `focus.nodeId: null`, `focus.depth: 1`, `zoom: {scale: 1, panX: 0, panY: 0}` and `sort: {column: 'row', direction: 'asc'}` (D6a) — all fourteen `LensState` fields, so the record is asserted **total** and not merely correct where checked; **and** for each of the four presets it differs from that preset's patch on at least one key the patch sets, so no preset *is* the initial state and none is privileged as the default | **FR-15** (the unnumbered criterion, § Acceptance Criteria) |
| **GV26** | the grouping control in a generated `graph.html` offers `'relation-category'` as a real `<option>` alongside the other four values of the `grouping` domain, and projecting with it partitions `groups` by each edge's `category` over `GraphModel.categories` — relation category available as a grouping dimension, not only as a filter axis (which is GV16's) | **FR-6** (the unnumbered criterion, § Acceptance Criteria) |

GV02 and feature-006's GL09 are complementary, not duplicates: GL09 asserts the ledger, the frontmatter
and a from-rows recomputation are the same set on the Node side; GV02 asserts the browser is running the
same bytes that produced it.

### Open Items

Recorded rather than silently assumed. Each names its owner, and — per **Q18 ruling 3** ("if there is a
defect, the A+ is false") and **Q20**'s standing correction ("an Open Item routed **into** a gated SPEC
is a **pending reopen**, not a note; it must be scheduled before that SPEC's grade is relied upon") —
each states the reopen consequence where the owner is gated. None blocks this feature's own
implementation. **An item that has since been settled by the owner or discharged by its owning SPEC keeps
its number and says so in place**, because sibling SPECs cite these numbers and a renumber repoints a live
citation at the wrong subject — the hazard STATE.md Q25 item 1 hit once already, and the same call
feature-003 made for its own Open Item 12. Every item that **asks another owner for a change** also
carries its **Q26 class**, recorded here because Q26 requires the routing SPEC to record it: mechanism
items reopen and re-gate, editorial items are batched into the Q24 item-9 pass and denied nothing.

1. **SETTLED by owner decision 2026-07-29 — FR-14a's `web-page` open target.** *(Filed as: "its resolved
   URL" is unachievable under FR-3.)* D7b sets out why: §5.3 keeps URLs out of the table by design, so the
   view holds an opaque key and cannot resolve it. The owner amended FR-14a to name
   **`./external-sources.md`**, "the file that resolves the key ... honest, mechanically checkable, and
   preserves FR-3's single-input rule", and **rejected** carrying the URL, which "would contradict §5.3 and
   reopen features 003 and 005" (STATE.md Q21 item 2, REQUIREMENTS.md FR-14a as amended). Nothing is
   routed onward: neither feature-003 nor feature-005 is reopened, because the rejected alternative is the
   only one that would have touched them. Kept here as the closure record for a finding this SPEC raised.
2. **`kb-unbacked`'s domain is the owner's ruling; what remains is one clause of §2 item 1's wording.**
   *(Filed as an author decision; it was not one.)* D6d's narrowing to `kind ∈ {document, concept}` —
   `section` excluded as a container, `fact` routed to the integrity channel as structurally impossible —
   is **FR-13 as amended on 2026-07-29 by owner decision** (STATE.md Q21 item 1), on this SPEC's own
   finding, so the SPEC implements a requirement rather than deviating from one. The **test** is likewise
   settled, not open: Q21's refinement decides it (*a prefix is correct about where an id comes from,
   wrong about what class a node belongs to*), so D6d re-keys it to `kind === 'source-artifact'` and
   feature-006's proxy-sweep row 13 — which recorded the substitution as real and "not this feature's to
   resolve" — is **closed here rather than routed**. The residue is that **§2 item 1** still reads "a `kb:`
   node with no `int:` edge", the last unannotated member of the `int:`-for-kind family, wanting the
   one-clause annotation FR-19 received. **Owner: the work owner** (requirements wording). **Q26 class:
   editorial** — it changes nothing an implementer builds — so it **belongs on STATE.md's § Editorial
   queue** beside feature-006's Open Item 8 (E3), which asks for the same annotation on FR-26/AC-14, and
   is fixed in the Q24 item-9 batched pass rather than chased from here. The target is gated A+, so the
   reopen is **batched, not avoided**.
3. **An enumerated `image` or `web-page` node with no relationship row cannot be drawn.** D2d states the
   consequence of FR-3 plus AC-15's kind-keying: `kb_gaps` is scoped to `Kind = source-artifact`, so
   media and external nodes have no carrier into the page and the coverage-note counts are the only place
   a reader learns they exist. This is arguably correct — FR-20 states an undocumented image is **not** a
   KB gap — but it is a silent absence from the picture and the reader should be told, which the coverage
   panel now does. Making them drawable would need a frontmatter carrier for zero-row media nodes — and
   **not** `kb_gaps`, which feature-006 declines outright: that list is scoped to `Kind = source-artifact`
   and every consumer derives severity from a `qualifier` a media node structurally cannot carry, so media
   ids in it "would reintroduce the prefix-keyed defect through the frontmatter instead of through the
   predicate". **Ownership, adopted from feature-006's Open Item 7, which composes all three owner
   records:** **the work owner** decides whether zero-row media nodes are carried at all; **feature-003**
   owns the second reserved frontmatter key, outside the byte-identity boundary as `kb_gaps` already is —
   **gated A+; scheduling reopens and re-gates that SPEC**; **feature-006** is the writer; this feature the
   consumer; **feature-010** assembles; and **feature-004 is the source and makes no change**, because
   `media-nodes.tsv` already exists — so it is **not** among the SPECs a scheduling decision reopens.
   *(Corrected 2026-07-30: this item named **feature-004** as a reopened owner and omitted **feature-003**
   entirely. feature-004 had already refuted its half — "on the composition above this SPEC is not one of
   them, since its contribution is existing content" (its SPEC.md:2325) — and feature-006 corrected the
   identical false reopen in its own text. Same false-reopen class, one SPEC over.)* **Q26 class:
   mechanism** — a new frontmatter key is a contract.
4. **`contrast-check.mjs` needs two parameterisations, and one plausible implementation of them is
   unsafe.** D5a: the graph's palette blocks must be extracted by **named additional selectors**, and the
   new pairs must target **3:1** per SC 1.4.11 while `kb.html`'s eleven stay at 4.5. The unsafe
   implementation is "extract all occurrences and merge", which would let `component-css.css`'s
   `@media print` `html[data-theme="dark"]` block — verified on disk to re-declare every dark token with
   light values — win the dark extraction. **Its stated harm was wrong and is corrected at D5a rows 3–4:**
   there is no working dark check to "silently corrupt", because the existing extraction harvests **zero**
   custom properties, so merge-all would leave that hole open *and* open it for the graph's palette. Hence
   **named additional selectors** whose blocks occur exactly once and never inside `@media print`. The
   vacuous dark extraction is a **second, separable finding against the checker** on the same owner.
   **Owner: feature-011**, extending
   feature-002's Open Item 8 with the selector half, the vacuous-dark finding, and this reason.
   *(feature-011 is gated A+ on the pre-redesign baseline and is in the re-specification set; per
   Q20 (loader sync) this item must be scheduled into that re-specification rather than left as a note.)*
   **Q26 class: mechanism** — it changes what a gate checks.
5. **DISCHARGED by feature-006 — each `kb_gaps` entry carries `name` alongside `id`.** Frontmatter is the
   only place a display name for a zero-row node can come from (D10), and feature-006's D6 now carries
   `name` as a required key of the four-key entry shape, for the same reason stated from its side, and
   records the discharge in its own § Discharged list. Nothing is owed and no reopen follows.
6. **DISCHARGED by feature-006 in both halves — the Node-side boundary and the candidate-set prose.** Its
   detector `import`s `coverage-predicate.mjs` and restates no predicate logic (its D2, D6), and its
   candidate set is re-keyed to `Kind = source-artifact` **and made a checked input assertion rather than
   a description** — `GL14` exits 2 on a `nodes.tsv` row whose `node_kind` is `image`, which is more than
   this item asked for, since it puts the keying beyond the reach of prose drift. Recorded in feature-006's
   § Discharged list. Nothing is owed and no reopen follows.
7. **The vendored bundle must be a classic script, not an ES-module-only distribution.** A `file://` page
   cannot import a relative ES module, so a UMD/IIFE build of `d3-force` and PixiJS is required at this
   entry point. Recorded as a constraint on packaging rather than a preference. **Owner: feature-012**
   (packaging wiring), informed by **feature-002**'s Stage 3. *(feature-012 is gated A+ on the
   pre-redesign baseline and in the re-specification set.)* **Q26 class: mechanism** — it constrains which
   distribution may be wired.
8. **`COVERAGE_BEARING` is selected; what is open is when it becomes checkable, and two shape questions
   this feature co-owns.** The **selection is made** — feature-006's D2a reaches it pair by pair from a
   stated criterion, records the reviewable copy at
   `canonical/aid/templates/graph/coverage-bearing.yml`, and discharges feature-001's Open Item 8 there;
   feature-005's Open Item 9 is discharged in the same place. So nothing about membership is routed from
   here. What remains, in three parts:
   (a) **Both constants are enumerated by name only once feature-001's `relation-vocabulary.yml` is
   authored**, so GV04 and GV05 become runnable then, and if that file renames or drops a member the
   selection is re-derived from D2a's criterion rather than patched. This blocks the task that authors
   `coverage-predicate.mjs`, not this SPEC. **Owner: feature-001** (the file's contents — no change
   requested to its SPEC, so no reopen).
   (b) **The member-token shape, inbound from feature-006's Open Item 5, which names this feature as
   co-owner.** `implemented-by` has a real semantic case for membership — a Knowledge Base document
   specifying behaviour an artifact realises does account for that artifact — and is excluded today partly
   because membership is by `relation` key, so GV05's containment cannot hold for an **`inverse`** name.
   Admitting it needs **directed member tokens** (`implements:T2S`) with **GV05 widened accordingly**,
   which is this feature's constant and this feature's assertion. **Owners: feature-006** (the criterion)
   **with this feature** (the token shape and GV05), **and the work owner** on whether a specification
   document should clear a coverage gap at all. *Ungated both ways.*
   (c) **GV04 over a *merged* set, inbound from feature-006's Open Item 6 (F6).** FR-4a lets a project add
   validated pairs while `COVERAGE_BEARING` is a compile-time constant, so an artifact covered only by an
   extension pair is a **false gap** — the direction feature-006's D3 calls worse than a missed one. If the
   owner decides an extension file may declare coverage-bearing membership, GV04 stops being an equality
   over one recorded set and becomes an equality over the **merge** of core and extension. **Owners: the
   work owner**, **with feature-003** (the extension file's format and loader — **gated A+; scheduling
   reopens and re-gates that SPEC**) **and this feature** (GV04 over a merged set; ungated).
   **Q26 class: mechanism** for (b) and (c) — each changes a constant's shape or an assertion's basis.
9. **feature-005's false-merge candidate presentation — the count is taken here, the set is re-routed.**
   feature-005 Open Item 7 offers the Coverage/Impact lens as a surface for the false-merge candidate
   set, noting that the detection itself is **computed in feature-005** (`build-relationships.sh`), which
   owns the signal — and this SPEC does **not** re-implement it. What it takes: the
   `concept-merge-candidates` extra coverage row — its candidate count and **the two reach counters that
   share its `note`** (feature-005 D7's row, which packs three numbers into one `note`: candidates,
   filtered by shared vocabulary, and concepts skipped as single-concept-defining) — read by D2d and
   displayed in the coverage panel, so the finding and its reach are visible in the view on every run.
   What it **cannot** take: a per-concept mark on the candidate concept nodes, because `relationships.md` carries
   a **count**, not the candidate set — the set lives in `.aid/.temp/graph/concept-merge-candidates.tsv`,
   which is scratch deleted at skill DONE and would be a second input path (FR-3, AC-10). If per-concept
   marking is wanted, the set must be carried inside `relationships.md`. **Owner: the work owner** to
   decide, with **feature-005** (producer) and **feature-003** (a carrier for a set rather than a count)
   — **both gated A+; scheduling reopens and re-gates both.** *(feature-005 flagged its item ungated on
   the assumption the view could render the set from what it already has; it cannot.)* **Q26 class:
   mechanism** — carrying a set where a count is carried today is a schema change. *(Corrected 2026-07-30:
   this item said the row carries "its **three** reach counters", naming a set one member larger than the
   carrier holds. feature-005's row packs the candidate count and **two** counters into one `note`; its
   full reach-counter set goes to transient stdout, which the view cannot read. feature-006 has separately
   **declined** a ledger row for a candidate, with four reasons, so no ledger route exists either.)*
10. **feature-004's stream table names feature-007 as a consumer of `media-nodes.tsv`, and this SPEC
    declines it.** That table lists `.aid/.temp/graph/media-nodes.tsv` with "feature-007/009 (rendering)"
    among its consumers. This feature reads **`relationships.md` and nothing else** (FR-3, AC-10); media
    nodes reach the view *through the table*, because feature-005 uses that stream as its endpoint
    universe and writes rows. As written the column names a scratch file — deleted at skill DONE — as a
    rendering input, which is at best misleading and at worst licenses the second path AC-10 forbids.
    Prose only; no mechanism in either feature changes — verified still standing at feature-004's
    SPEC.md:356. **Owner: feature-004.** **Q26 class: editorial** by its own description, so it **belongs
    on STATE.md's § Editorial queue** and is fixed in the Q24 item-9 batched pass, which carries one
    confirmatory gate over what it touches. *(Reclassified 2026-07-30: this item read "gated A+;
    scheduling reopens and re-gates that SPEC" in the same breath as "no mechanism in either feature
    changes" — the unbounded-cascade reading Q26 replaced. The reopen is batched, not avoided.)*
11. **The runtime-prerequisite text and the packaging shape depend on feature-002.** AC-6 requires the
    prerequisites to be documented and WebGL to be among them; *which* sentence is written depends on
    feature-002's Stage-1 three-level verdict, and the companion-asset list depends on its Stage 3.
    Likewise, whether `validate-visuals.mjs` needs a **capture** exemption depends on Stage 1's L3
    result. This SPEC fixes the obligation and the emission point; the content arrives with the report.
    **Owner: feature-002** for the verdicts, **feature-011** for the capture exemption if it fires.
12. **Whether the drawing layer can read computed CSS custom properties at acceptable cost.**
    feature-002 D8 owes this as a verdict on the mechanism, because if it cannot, "the
    accessible-and-checkable palette is not merely unwritten but unavailable." D5a states the fallback
    that preserves every property — resolve once per theme change into a local table — so this SPEC does
    not block on the answer. **Owner: feature-002.**
13. **AC-6a and NFR-4's settled render are feature-008's, and NFR-8's warning is feature-010's.** Named
    as a boundary rather than a gap: this feature hosts the frame loop, exposes the reduced-motion
    preference and reports the ceiling warning, but measures nothing and gates nothing.
    **Owners: feature-008, feature-010.**

**Discharged here, and recorded so they are not re-routed.** feature-001 Open Item 7 (the eight-colour
assignment — adopted with feature-001's own lens-keyed ranking, D5b); feature-002 Open Item 4 (the void
design-token claim — replaced by the palette contract, D5); feature-003 Open Item 9 (render-time label
shortening — D9); feature-003 Open Item 15 (the duplicate-heading suffix — discharged by **removing the
dependency**, D7b, with the residual stated and nothing claimed about a third-party renderer);
feature-004 Open Item 1 (the `int:`-to-`source-artifact` re-key in this feature's prose and predicate —
D6d, D10); feature-004 Open Item 2 (the three-way "kind" collision — resolved by splitting `Node.kind`
from `Node.prefix`, D1a; feature-004 left the choice here and no mechanism changes in either feature);
and **feature-006's Open Item 4 in all three parts** — `recordedGaps`'s fourth key is `qualifier` (D1),
the detector is the outright `.mjs` of shape (b) (D10), and `RELATION_CATEGORY` is **authored in
`coverage-predicate.mjs`** (D1, D10, § API Contracts, § Layers, GV03/GV05), which is the move STATE.md
Q25 item 2 decided rather than an export-surface confirmation.

**Discharged *by* another SPEC, and recorded so they are not re-raised from here.** This SPEC's **Open
Item 5** (`name` in every `kb_gaps` entry) and **Open Item 6** in both halves (the Node-side boundary and
the candidate-set prose) are discharged in feature-006's own § Discharged list, the second more strongly
than asked, as an input assertion rather than prose. Both keep their numbers.

**Not open, and recorded so they are not reopened.** The module's identity and its Node/browser boundary;
`RELATION_CATEGORY`'s home in that module; AC-15's scope — the equality binds `Kind = source-artifact`
only; the `kb-unbacked` domain **and** its test, both kind-keyed, the first by owner decision (Q21) and
the second by the rule that decision carries; FR-14a's `web-page` open target, `./external-sources.md` by
the same decision; that a zero-row node is an expected
asymmetry the integrity alarm never fires on, surfaced through the union rather than through equality;
that the canvas is visual-only with no DOM proxy layer (Q9); and that `graph.html` is deliberately not
dashboard-reachable (C-8).
