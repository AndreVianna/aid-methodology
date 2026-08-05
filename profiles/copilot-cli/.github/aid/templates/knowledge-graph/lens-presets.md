# Lenses, Filters And The Palette — The Reviewable Statement

This is the prose copy of what `graph-model.js` implements: the four preset lenses, the
control state they patch, how a filter composes with a lens, and the colour and line-style
assignment. It exists so a reviewer can check the design without reading the code, and so a
consumer building a rendering can check the contract without reading the shell's internals.

Nothing loads this file at run time. Where it and the code disagree, the code is what ships —
so a disagreement is a defect in this file, and the test suite binds the two.

---

## 1. `LensState` — the control state

A **flat** record, JSON-serialisable, fourteen members. The record's own keys are the dotted
leaf names, and that is load-bearing: it makes "no preset resets a filter" a question about
strings rather than about a traversal, and it makes a patch a plain object over the same key
space.

| Key | Domain | Meaning | Read by |
|---|---|---|---|
| `preset` | one of the four names, or null | Which preset was last applied. Advisory: it never gates a control | both |
| `grouping` | `none`, `relation-category`, `document`, `node-kind`, `provenance` | The grouping dimension. `document` is the only one that folds | both |
| `expandedGroups` | array of group keys | Which groups the reader has drilled into. The disclosure **toggles** membership, so it shrinks as well as grows | both |
| `density` | 1–5 | **View** density — how much is drawn. Level 1 thins nothing; 2–5 hide nodes with fewer connections than the level | both |
| `filters.kinds` | subset of the seven kinds | Node kinds admitted | both |
| `filters.categories` | subset of the loaded categories | Relationship categories admitted | both |
| `filters.provenance` | subset of `declared`, `derived`, `inferred` | Provenances admitted | both |
| `filters.showOrphans` | boolean, default **true** | Whether nodes with no recorded relationship are drawn | both |
| `filters.text` | string | Case-insensitive substring match on the stored name and the identifier — never on the shortened label | both |
| `focus.nodeId` | node id, or null | The selected node | both |
| `focus.depth` | 1–6 | Neighbourhood radius in hops from the selection | both |
| `emphasis` | `none`, `coverage`, `provenance-chain` | The only **lens-level** dimming and highlighting channel | both |
| `zoom` | `{scale, panX, panY}` | Viewport transform. **Graph-only** | graph |
| `sort` | `{column, direction}` | Table ordering. **Table-only** | table |

`zoom` and `sort` are the only renderer-private members, and **neither may affect which nodes
or edges are present or emphasised.** Everything deciding membership or emphasis is in the
other twelve and is interpreted exactly once, in `project()`.

### Two absences, both deliberate

- **No physics parameters.** Repulsion, link distance and centre force are internal constants
  of the drawing rendering, tuned once. A documentation viewer should not need physics tuning
  to become readable, and every exposed parameter is another way to make the graph worse.
  Mechanically: there is no member a repulsion slider could write to, so the boundary is
  structural rather than a matter of restraint.
- **No hover state.** Hover reveals a relationship name and focuses a neighbourhood, and it is
  transient; routing it through the store would reproject on every pointer move. **Hover may
  change appearance, never membership.** Selection changes membership and goes through the
  store.

### The initial state

`preset: null`, `grouping: 'none'`, `expandedGroups: []`, `density: 1`, all three enumerable
filter axes admitting their whole domain, `filters.text: ''`, `filters.showOrphans: true`,
`emphasis: 'none'`, `focus.nodeId: null`, `focus.depth: 1`,
`zoom: {scale: 1, panX: 0, panY: 0}`, `sort: {column: 'row', direction: 'asc'}`.

That is every one of the fourteen members: the unfiltered whole, with no lens applied and
nothing folded. The sort opens in the file's own row order, so the table's first reading is the
file's.

**No preset is the default.** All four purposes this view serves are equally primary, so
privileging one would answer a question the reader has not asked. Four of these values are
stated for a second reason as well — each preset patch has to differ from the initial state on
at least one key it sets, and at Impact's depth of two an unstated `focus.depth` would have
made that patch differ on nothing at all.

---

## 2. The four presets

Each is a **frozen partial assignment** over the record above, applied by patching the store.
That is the whole mechanism, and it is why arriving through a preset cannot lock the view: the
patch lands in the same record every control writes to, so every control keeps working
afterwards and **nothing is ever disabled or hidden by a preset**.

| Preset | Patch | The purpose it serves |
|---|---|---|
| **Coverage** | `emphasis: 'coverage'`, `grouping: 'node-kind'`, `density: 1`, `focus.nodeId: null` | What is unbacked or undocumented, with the well-formed parts dimmed |
| **Overview** | `grouping: 'document'`, `expandedGroups: []`, `density: 3`, `emphasis: 'none'`, `focus.nodeId: null` | The shape of the project, with a document's sections and claims folded back into it |
| **Impact** | `focus.depth: 2`, `density: 1`, `emphasis: 'none'`, `grouping: 'none'` | A selected node's neighbourhood to a chosen depth. Keeps the current selection and prompts for one when there is none |
| **Provenance** | `emphasis: 'provenance-chain'`, `grouping: 'provenance'`, `density: 1` | Only the chains from Knowledge Base content out to source and external origins |

### Composition is structural

**No patch above contains a key in the `filters.` namespace**, and that is a domain restriction
rather than a coincidence of these four. A filter therefore *narrows* a lens rather than being
reset by it, and a fifth preset could not break the property without failing a test.

The reciprocal half: a filter never writes `preset`, so the pressed state of the lens buttons
keeps reporting how the reader arrived, and the announced summary names **both** — "Coverage
lens, filtered to 2 of 14 categories" — because a reader who cannot see the control panel needs
to know a lens is narrowed.

---

## 3. Filtering — the two readings, and why they differ

Three axes are node-level and one is row-level, and the difference is not an inconsistency.

- **Node kind, density and the orphan toggle admit or exclude a NODE.** A node that is not
  admitted cannot be drawn, so neither can a row touching it: row admission is a **conjunction**
  over the two endpoints.
- **The text filter is stated over the row's four identifier and name cells**, which is a
  **disjunction** over the two endpoints. So typing a name shows the matched node *in its
  context* rather than only the rows between two matches — which is what makes it useful as a
  way of reaching a node. Applied to a node with no surviving row, the same predicate reduces to
  the node's own name and identifier.
- **Category and provenance are row properties** and admit or exclude a row directly.

---

## 4. The `document` dimension, and the only fold

This dimension is **kind-dependent rather than keyed on a document identifier**, and it has to
be: the document part of an identifier is null for a concept and for every artifact, so keying
on it would put every artifact and every concept in one ungrouped bucket — the opposite of what
this dimension is for.

| Node kind | Group | Why |
|---|---|---|
| `section`, `fact` | their parent document | Both are document-scoped by grammar, so the document part is populated and the fold is exact |
| `document` | itself | The group's head |
| `source-artifact`, in-repo `image` | itself | A single-node group that is its own head |
| `concept` | its relationship category | A concept has no single parent document by construction, so there is no document to fold into |
| `web-page`, external `image` | the external group | Neither has a parent document nor a category of its own |

A concept in rows of more than one category needs a rule and the requirement gives none. The
rule here, recorded as an **author decision**: the category of its **highest-provenance**
incident row, declared over derived over inferred, tie-broken by the category's position in the
vocabulary's declared order. It reuses the ordering the open target already fixes, so the view
has one precedence rule rather than two, and it is total and deterministic — which the
projection's purity requires.

### The fold, in three clauses

1. **What folds.** A group folds only where it has a **node head**, and under this dimension
   that is exactly the document groups. Its non-head members — a `section` or a `fact`, and no
   other kind — are the members the fold governs, each folded unless the group's key is in
   `expandedGroups`. No other branch has a node head: an artifact is its own head, and the
   category and external groups are keyed on a *label* rather than on a node. So only a section
   and a fact ever fold, and every other dimension yields nothing foldable and an empty record —
   one code path with an empty case, not a mode.
2. **What the fold does.** A folded node is absent from the drawn node set, present in the
   record mapping it to its head, and counted as hidden. Every surviving reference to it
   resolves to that head, once and in one place: a row's two endpoints, and the selection,
   before any class is assigned. **The fold is applied last and it wins** — selecting a section
   and then choosing this dimension moves the focus class to that section's document rather than
   stranding it on a node neither rendering draws, and the selection itself is untouched, so
   expanding restores it exactly.
   **No edge is synthesised.** A row keeps its real identifiers, its key and its row number, so
   every surface can still cite the row a claim came from — which an aggregate edge could not,
   having no key in the file. A row whose two ends resolve to one node is marked `collapsed`:
   drawn and listed by neither surface, and counted as hidden. That is the accepted cost — a
   document's internal structure disappears **into** the document rather than into a self-loop —
   and two rows between one pair of heads stay two entries.
3. **Drilling in, and back out.** Every group the fold governs carries a real focusable button
   that **toggles** its key in `expandedGroups`. Presence is keyed on the count the fold
   *governs*, which expanding does not change — **not** on the count currently folded away,
   which expanding drives to zero. So the element that collapses a group is the one that
   expanded it, and the drill-in is reversible without re-applying the preset.

---

## 5. Emphasis — a total precedence, not a composition

The node map holds **one** class per identifier while two inputs assign classes, so an order is
required rather than optional.

1. the fold-resolved **selection** is `focus`, whatever else applies to it;
2. else, under the coverage lens, its **gap class** — `kb-unbacked` or
   `artifact-undocumented`. The two are keyed on **disjoint kinds**, so they cannot contend and
   no order between them is needed. Everything else under that lens is `dimmed`;
3. else `dimmed`, where the active lens or the selection dims it;
4. else `normal`.

Total over all five values, so no node is ever unclassed and none is classed twice.

**Ranking the selection first loses no fact**, because both are published independently: the two
gap sets are their own field, computed once per load, and the selection is in the control state.
A surface wanting both draws the gap marker from the set and the focus treatment from the map.
The opposite order left no marked identifier at all when a gap node was selected.

The **edge** axis needs no precedence: the provenance lens is the only thing that assigns an
edge class, and a selection assigns none, so every drawn row carries exactly one value from
exactly one clause — `chain` or `dimmed` under that lens, `normal` under the other two.

---

## 6. The palette

### 6.1 Why it is CSS custom properties, and not values in drawing code

The project's contrast checker is a text extractor with no browser: it looks for CSS custom
properties inside a named block. A colour that a drawing layer passes to its graphics API as a
value is therefore **never looked for** — the check produces no warning and no failure, because
it never runs. So every palette colour is declared as a custom property, the drawing code
resolves a token to a value at draw time, and the projection carries **token names** rather than
colour values for exactly this reason.

Three consequences, each a rule rather than a caution:

- **Names use lowercase letters and hyphens only.** The checker's property charset admits
  nothing else, so `--gc-evidence` is visible and a numbered token would be silently unchecked.
  That is why the palette is named after kinds and categories rather than numbered.
- **The two declaration blocks use selectors that do not already occur** — `html:root` and
  `html[data-theme="dark"]:root`. The checker resolves the *first* block matching a selector, so
  a second block reusing an existing selector would be invisible. Both match the same element as
  the plain forms, so the cascade is unchanged.
- **The dark block occurs exactly once and never inside a print block.** The shared stylesheet's
  print rules re-declare every dark token with light values in order to force a light print
  rendering, so any reader that merged every occurrence of a dark selector would read print
  values as screen values.

### 6.2 The target

Node and edge marks are graphical objects that carry meaning, so the applicable threshold is
**3:1** against the adjacent colour, not the 4.5:1 that applies to text. The adjacent colour is
the graph surface, which is the shared elevated-background token in both themes.

### 6.3 Node kind — seven colours, seven shapes

| Kind | Token | Shape |
|---|---|---|
| `document` | `--gk-document` | filled circle |
| `concept` | `--gk-concept` | filled diamond |
| `fact` | `--gk-fact` | filled triangle, point up |
| `section` | `--gk-section` | filled square |
| `source-artifact` | `--gk-source-artifact` | filled hexagon |
| `image` | `--gk-image` | filled pentagon |
| `web-page` | `--gk-web-page` | ring — a circle with a hollow centre |

An `image` carries the same colour and the same shape wherever it lives, because the encoding is
keyed on the kind and **an identifier prefix is not the kind**.

Whether seven shapes stay distinguishable at the sizes the density and zoom controls reach is a
**legibility judgment for the human visual gate**, not something asserted here. If it fails, the
answer is to merge shapes and lean harder on filtering, which costs no requirement.

### 6.4 Relationship category — eight colours over fourteen categories

The eight categories holding a colour of their own are the ones the four presets key on, two per
lens, because those are the ones a reader must tell apart *without* filtering.

| Category | Token | Line style | Why this pairing |
|---|---|---|---|
| `structure` | `--gc-structure` | solid | Overview keys on it |
| `taxonomy` | `--gc-taxonomy` | solid | Overview keys on it |
| `documentation` | `--gc-documentation` | solid | Coverage keys on it |
| `evidence` | `--gc-evidence` | solid | Coverage keys on it |
| `provenance` | `--gc-provenance` | solid | Provenance keys on it |
| `lineage` | `--gc-lineage` | solid | Provenance keys on it |
| `dependency` | `--gc-dependency` | solid | Impact keys on it |
| `implementation` | `--gc-implementation` | solid | Impact keys on it |
| `definition` | `--gc-taxonomy` | dashed | Both are concept-to-concept relations |
| `identity` | `--gc-taxonomy` | dotted | Identity is the limiting case of an associative relation |
| `representation` | `--gc-structure` | dashed | A rendering is a structural stand-in for its subject |
| `navigation` | `--gc-structure` | dotted | Sequence and cross-reference are filed together in the vocabulary for the same reason |
| `agreement` | `--gc-evidence` | dashed | Agreement and evidence are the two claim-about-a-claim families the vocabulary split |
| `annotation` | `--gc-documentation` | dashed | An annotation comments without asserting; documentation records |

**The generating rule an extension must obey:** *within any one colour, every category carries a
distinct line style.* That makes the (colour, style) pair unique across all fourteen. It also
gives the bound — a colour may hold at most four categories, because four styles exist — and
`dash-dot` is deliberately unused by the core, so the first added category per colour needs no
reassignment of an existing one. Past that bound the encoding is unrepresentable, and the loader
says so with the category named rather than colliding in silence.

### 6.5 What line style can and cannot carry

Four styles cannot distinguish fourteen categories, and no arrangement of eight colours and four
styles can. Distinctness *within a colour* is the strongest property line style has, and stating
it that way matters, because "colour plus line style distinguishes fourteen categories" is
exactly the kind of plausible, unmeasured claim this design would otherwise rest on.

The route to a category that does not depend on colour is threefold, and none of it is line style
alone:

1. **filtering to a category**, which is a required feature with its own criterion and is
   keyboard-operable;
2. the **relationship name on hover or selection**;
3. the **table rendering**, where every name is always present as text.

### 6.6 Forced colours — the one place the drawing surface cannot follow the page

A forced-colours mode remaps colours declared on elements. It does not remap pixels inside a
bitmap. So in that mode the page around the graph is remapped and the drawing surface is not —
a real limit, stated rather than discovered.

The response uses the channel that was always required: the shell detects the preference and
publishes it, and the drawing rendering then draws **no palette colour at all** — every mark in
the forced foreground colour on the forced background — leaving **shape** for node kind, **line
style** for category, and filtering for the rest. A degraded but coherent picture, and it is
only possible because colour was never the sole carrier of anything.

---

## 7. The two node gestures

| Gesture | Effect | Keyboard equivalent |
|---|---|---|
| **Select** | Writes `focus.nodeId`. Highlights the neighbourhood, dims the rest, drives the depth view, and moves the table to that node's rows. **Navigates nowhere** | The focus combobox, and the Select button beside it |
| **Open** | Opens the artifact the node stands for | The Open button, which is why it exists — a double click has no keyboard equivalent |

Per-kind open targets, written from the page's own directory:

| Kind | Target |
|---|---|
| `document` | `./<doc>` |
| `section` | `./<doc>#<heading-slug>` |
| `fact` | `./<doc>` — **the file, with no fragment**, because a fact's fragment is a synthetic identifier rather than a document anchor, and appending it would emit a dead link on every fact node |
| `concept` | its defining document, else the highest-provenance mentioning document, tie-broken by ascending path |
| `source-artifact`, in-repo `image` | `../../<repo-relative-path>` |
| `web-page`, external `image` | `./external-sources.md`, anchored to the key's row |

A web page's target is **the file that resolves the key, not a URL.** The table carries only the
key by design — the external-sources file remains the single place that resolves it — so the view
holds a key it cannot resolve. Naming the resolving file is honest, is mechanically checkable,
and keeps the single-input rule intact.

---

## 8. Where a prefix is read, and where it must never be

An identifier prefix says **where an id came from**. A `Kind` cell says **what class a node
belongs to**. They are different facts and they do not agree: one kind is spelled with either of
two prefixes, and one prefix spans four kinds. So a prefix read is a defect precisely when it
**stands in for the kind**.

Every prefix read in this feature, enumerated rather than counted:

1. the **kind/prefix agreement check** at load — a question about spelling, which is what a
   prefix answers;
2. **path semantics** — a repository-relative identifier *is* its path with the prefix stripped,
   which is what lets the coverage predicate match an ancestor directory with no extra field.
   That read lives in the shared predicate;
3. the **provenance lens's cross-side chain** — the one thing a prefix names and no kind does;
4. the **`document` dimension's** in-repo/external split of an image;
5. the **open target** and the **label basis**, which need that same split, because only a path
   has a basename and only a path can be opened as one.

Sites 3 to 5 all ask one question — *where does the artifact live* — about the one kind that
spans two sides, and the `Kind` cell cannot answer it.

**Colour, shape, every filter axis, every group and every emphasis class key on `kind`.** None of
them reads a prefix. A test suite written over a corpus where the two happen to agree cannot
tell the difference, so this is stated as a rule rather than left to a fixture to discover.
