# Requirements

- **Name:** Knowledge Relationship Graph
- **Description:** Adds the `/aid-graph` skill, which runs after the Knowledge Base is approved to extract every relationship among KB concepts, facts, sections and documents, project source artifacts, images and web pages into a verifiable `relationships.md` table and render it as a **live, directed, colour-coded** interactive graph view. *(Amended 2026-07-29: "self-contained" struck — withdrawn with C-1 on 2026-07-28; node kinds widened; "interactive" alone did not convey continuous simulation.)*

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Initial interview started | /aid-describe |
| 2026-07-28 | Objective captured; three relationship sources and the `relationships.md` table schema recorded | /aid-describe |
| 2026-07-28 | Node identity confirmed: id + display name per endpoint; `kb:` / `int:` / `ext:<key>` prefixes | /aid-describe |
| 2026-07-28 | Relation vocabulary confirmed closed + research-defined + categorized (FR-4..FR-6) | /aid-describe |
| 2026-07-28 | Skill named /aid-graph; on-demand, KB-approval-gated, read-only, idempotent (FR-7..FR-11) | /aid-describe |
| 2026-07-28 | Confirmed separate skill sharing /aid-summarize scripts; merge alternative rejected (FR-12) | /aid-describe |
| 2026-07-28 | Problem Statement captured — all four purposes equally primary | /aid-describe |
| 2026-07-28 | Graph view: four preset lenses + always-available manual controls (FR-13..FR-15) | /aid-describe |
| 2026-07-28 | Self-containment confirmed (FR-16/FR-17); rendering approach deferred to RESEARCH (FR-18, Q2) | /aid-describe |
| 2026-07-28 | Unrepresented source concept reframed as a KB defect; source-driven enumeration (FR-19/FR-20) | /aid-describe |
| 2026-07-28 | Significance rule, exclusions, granularity, derivability confirmed (FR-21..FR-24) | /aid-describe |
| 2026-07-28 | Gap handling: report to reviewer ledger + route, never gate (FR-25..FR-28) | /aid-describe |
| 2026-07-28 | Accessibility: WCAG AA via first-class accessible table view (NFR-1..NFR-6) | /aid-describe |
| 2026-07-28 | Extraction: script-majority two-pass with bounded agent pass; reproducibility (FR-29..FR-32) | /aid-describe |
| 2026-07-28 | Derived §3 Users, §4 Scope, §7 Constraints, §8 Assumptions, §9 Acceptance Criteria | /aid-describe |
| 2026-07-28 | Priority set to Immediate; three-deliverable shape proposed for /aid-plan | /aid-describe |
| 2026-07-28 | Quality check: added AC-16..AC-18; sharpened C-7; raised Q3 (KB-index pickup of relationships.md) | /aid-describe |
| 2026-07-28 | Identity header confirmed (Name + Description) | /aid-describe |
| 2026-07-28 | Interview complete — approved | /aid-describe |
| 2026-07-28 | KB hydration assessed — no KB writes: all 19 docs already Generated with no Pending/Partial rows, and every fact captured here describes an unbuilt capability, so writing it now would document something that does not exist. KB update deferred to ship. | /aid-describe |
| 2026-07-28 | Decomposed into 11 features | /aid-define |
| 2026-07-28 | Cross-reference complete — Grade A+; FR-1..FR-3 draft labels removed; Q4 raised (external-sources.md has zero entries) | /aid-define |
| 2026-07-28 | **Owner decision — packaging restrictions dropped.** FR-16 rewritten to prioritise interaction quality over packaging; C-1 withdrawn; FR-18's option space unrestricted (multi-file, CDN, and build step all permitted); AC-6 rewritten; four consequences recorded at §5.6 | /aid-specify |
| 2026-07-28 | Q1 resolved — `Strength` column dropped; table is eight columns | /aid-specify |
| 2026-07-28 | Q3 resolved — `relationships.md` is a generated, KB-indexed document with valid frontmatter; C-7 and AC-18 hold | /aid-specify |
| 2026-07-28 | Q4 resolved — `ext:` branch of AC-1 validated against a synthetic fixture, not this project's empty external-sources.md; A-6 added | /aid-specify |
| 2026-07-28 | **Correction** — §5.6 consequence 1 named the wrong validator. `validate-visuals.mjs` T2 (sibling `<g>` overlap) is the real by-design collision for an SVG graph; `NM` is `mermaid`-keyed and passes unchanged; `S2` fails only if the packaging uses a CDN. Verified against the scripts | /aid-specify |
| 2026-07-28 | AC-15 scope clarified — the lens/ledger equality binds the `int:` class only; unbacked `kb:` nodes are a lens-only signal | /aid-specify |
| 2026-07-28 | Q5 raised — `graph.html` is unreachable through the dashboard (leaf allowlist + CSP); entry point scoped to a local file open | /aid-specify |
| 2026-07-28 | **Correction** — FR-30's `Evidence:` carrier does not exist in this KB (2 prose-label hits in one doc). Replaced with the verified carriers: `sources:` frontmatter, inline `CONFIRMED <path> (search: "…")` anchors (7–30 per doc), frontmatter cross-references, external-source keys | /aid-specify |
| 2026-07-28 | Q8 raised — the shared reviewer-ledger lifecycle deletes ledgers at DONE, which would destroy the gap findings FR-26 delivers; needs a retention carve-out at the methodology level | /aid-specify |
| 2026-07-28 | `generator` frontmatter conflict between feature-003 and feature-010 reconciled to the script name, per the `build-kb-index.sh` precedent | /aid-specify |
| 2026-07-28 | Q6/Q7 raised and D-4/D-5 added — FR-22's ignore-list setting does not exist (settings at `format_version: 3`); the external-sources file has no machine-readable entry format and `/aid-graph` may not author one under FR-10 | /aid-specify |
| 2026-07-29 | **Owner decision — the graph must be LIVE; the SVG/static recommendation is superseded.** `graph.html` renders a continuously-simulating force-directed graph in the style of Obsidian's core graph view: nodes drift and settle, dragging a node pulls its neighbours, hovering focuses a neighbourhood and dims the rest, depth conveyed by glow and size. Reference architecture: `d3-force` for physics + **PixiJS (WebGL)** for drawing — the same split Obsidian uses. NFR-4's settled, un-animated render becomes the **reduced-motion fallback**, not the default. Rationale: NFR-4 presupposes layout animation and FR-16 prioritises interaction quality, and the prior recommendation satisfied neither. True 3D (orbit camera) was considered and **not** adopted | owner |
| 2026-07-29 | **Owner decision — the canvas is visual-only.** WCAG AA (NFR-1) is satisfied by the accessible table view as the conforming equivalent (NFR-2 as already written). No DOM proxy layer is built over the canvas | owner |
| 2026-07-29 | **Owner decision — the relation vocabulary must be GENERIC and standards-grounded.** Derived from SKOS, Dublin Core (DCMI Terms), PROV-O, schema.org, IANA link relations (RFC 8288) and CiTO, then verified expressible against a real repository — but explicitly **not** limited to what this repository happens to contain. The 8 harvested pairs are superseded as the *basis*: they were fitted to this repo's own frontmatter carriers, and no standard vocabulary was consulted | owner |
| 2026-07-29 | **Owner decision — the node model is widened beyond files.** Concepts and facts are **first-class nodes, distinct from the files that define them**; so are images, web pages, and sub-file anchors. File-only granularity is superseded. This is the root cause of the undersized vocabulary: file-to-file relations are inherently few, concept-to-concept relations are many. **Narrowed later the same day** by the granularity row below: sub-file anchors mean **document sections only** — code snippets and symbols are **not** nodes, and source files stay whole artifacts | owner |
| 2026-07-29 | **Owner decision — the vocabulary is a generic core plus a per-project extension**, not a strictly closed set. Project extensions are validated by the same inverse-pair rules (closure, totality, involution, symmetric consistency, category totality) | owner |
| 2026-07-29 | **Consequence — genericity was never stated as a requirement.** No FR required the vocabulary or node model to generalise beyond this repository, which is why the research narrowed without violating anything. A genericity FR is owed | owner |
| 2026-07-29 | **Owner decision — the graph departs from Obsidian's in three ways: it is DIRECTED, its edges are LABELLED, and it is colour-coded.** (1) Edges carry direction, so an asymmetric relationship is drawn with an arrowhead read Source→Target; (2) each edge displays its relationship name; (3) colour distinguishes node types and relationship categories. Obsidian's graph does none of these — it is undirected, unlabelled and coloured only by user-defined groups — so this is a deliberate divergence from the reference architecture, not a feature of it. **Clause (2) superseded later the same day**: persistent labels are dropped in favour of hover/selection labels — see the edge-encoding row below. Clauses (1) and (3) stand | owner |
| 2026-07-29 | **Consequence — NFR-5 is satisfied structurally by the above.** Colour is not the sole carrier: node **shape** carries node type alongside its colour, and the edge **label** carries relationship category alongside its colour. **Mechanism amended later the same day**: with persistent labels dropped, the edge's non-colour channel is **line style** (solid/dashed/dotted/dash-dot), not the label. Node shape still carries node type. The conclusion — that NFR-5 is met structurally and cheaply — is unchanged | owner |
| 2026-07-29 | **Consequence — edge labels are the binding rendering cost, and were never measured.** Labels are per-edge text objects (~750 at bench scale) that must be redrawn every simulation tick, must not overlap, and in WebGL each becomes a texture. Obsidian is fast partly *because* it has no edge labels, so its architecture is not evidence that labelled edges perform. The superseded research measured node and edge paint only — never text. The replacement research must measure labelled-edge cost during live simulation | owner |
| 2026-07-29 | **Owner decision — persistent edge labels dropped; edge encoding settled.** Relationship category is carried by **colour + line style** (solid/dashed/dotted/dash-dot); the relationship **name appears on hover or selection** rather than being drawn every tick; and full names are always available as text in the accessible table view. This removes the per-tick text cost identified above while keeping the information reachable | owner |
| 2026-07-29 | **Owner decision — granularity is asymmetric: deep in the KB, whole-artifact in code.** Concepts, facts and document sections are nodes; images and web pages are nodes; source files stay whole artifacts with no function/symbol nodes. FR-23 rewritten, A-5 voided | owner |
| 2026-07-29 | **Owner considered relaxing NFR-5 (colour not the sole carrier) and it was NOT relaxed — verified as WCAG 2.2 SC 1.4.1, Level A.** Level A is the lowest tier, and AA conformance requires satisfying all Level A criteria (or providing a Level AA conforming alternate version), so dropping it would forfeit NFR-1's AA claim — the bar `kb.html` already holds. The relaxation would also have bought **no performance**: the cost was the per-tick text, already removed by hover-only labels, whereas line-dash patterns were **believed** to cost nothing per frame. Verified against w3.org/TR/WCAG22 (accessed 2026-07-29). *(Cost claim **withdrawn 2026-07-29** — it was argued in review and never measured. Line-style cost is now a verdict the FR-18 research owes. The NFR-5 decision is unaffected: it turned on WCAG 1.4.1 being Level A, not on the cost.)* Recorded because the option was raised and declined on evidence, so it is not silently revisited | owner |
| 2026-07-29 | **Owner decision — a "fact" is a claim carrying a checkable source anchor.** In an AID repository that is the inline `CONFIRMED <path> (search: "…")` anchor — **33 lines carry one here** *(count corrected 2026-07-29: this entry originally said "227 of them", which was the count of the **bare token** `CONFIRMED`, not of anchored markers. That wrong figure was inherited by A-5 and became the "verified" 616 — this line is where it entered)*; **generically** it is any statement carrying an explicit, resolvable reference to the source that supports it — a citation, a link, a footnote, or a statement-scoped `sources:` reference. Consequence: a fact node's provenance is always `declared` or `derived`, **never `inferred`**, which keeps FR-24's "derivable rather than judged" intact and bounds the node count. Rejected: "any assertive statement the agent judges significant" — unbounded, `inferred`-only, and in tension with FR-24/FR-25 | owner |
| 2026-07-29 | **Consequence — the absence of fact nodes is itself the KB-quality signal, not a failure of the definition.** A repository with no anchoring convention yields few or zero fact nodes; a KB document making claims with no checkable anchor is precisely the "unbacked KB claim" defect of §2 purpose 1. So graceful degradation and the gap ledger (FR-25–FR-28) are the same mechanism, and the definition reinforces rather than undercuts genericity | owner |
| 2026-07-29 | **Owner decision — one node per concept, merged on its defined term.** A concept named in five documents is **one** node, not five. Identity is the normalised defined term, keyed to the glossary/definition entry where one exists. Each mention becomes an **edge** from the mentioning document or section to the concept node, so mention-count becomes graph degree rather than node duplication. **Two sub-rules owed to the spec:** the exact normalisation (case, whitespace, punctuation, plurals) and a disambiguation rule for two genuinely distinct concepts sharing one label | owner |
| 2026-07-29 | **Owner decision — performance floor is ≥30fps, not 60.** To be testable this is recorded as: **≥30fps sustained at the derived bench during both steady simulation and node-drag interaction**, measured headless through the Playwright harness FR-12 already reuses. *(This entry originally read "~1,200+ nodes for this repository"; that figure is **withdrawn** — it was built from the bare-token fact count. NFR-7 asserts no size, and the bench is the research's to derive.)* Rationale accepted: this is a documentation viewer, not a game. **Layout settle time is reported, not gated** — that scoping is the author's, not the owner's, and is flagged for confirmation. Without a stated floor "live" was unverifiable and no acceptance criterion could test it | owner |
| 2026-07-29 | **Owner decision — clicking a concept node opens its defining document**; where no definition exists, it opens the highest-provenance mentioning document, ordered `declared` > `derived` > `inferred`. Resolves the fact that a concept node, unlike an Obsidian note, owns no single file | owner |
| 2026-07-29 | **Owner decision — genericity scope: any project with an approved AID Knowledge Base.** FR-7/FR-8 already gate `/aid-graph` on one, so the genericity claim is bounded and testable, and the KB's own authoring conventions are carriers the skill may rely on. Wider scopes (any git repository; any documentation set) considered and not adopted | owner |
| 2026-07-29 | **Owner decision — a "concept" is a glossary entry or a convention-marked defined term, and nothing else.** A KB with no glossary yields **no** concept nodes, which is itself a quality signal — the same graceful-degradation logic as unanchored facts. Chosen partly because it keeps AC-1 mechanically checkable: a concept id resolves by grepping its definition. Rejected: falling back to document headings (blurs with the separate section node kind) and agent-extracted terms (unbounded, `inferred`-only, unverifiable) | owner |
| 2026-07-29 | **Owner decision — node kind is carried by EXPLICIT COLUMNS, not by the id prefix.** The renderer needs each endpoint's kind to choose colour and shape, and `kb:` alone cannot distinguish document from concept from fact from section. `Source Kind` and `Target Kind` become **required** columns. The author's recommendation (splitting the prefix into `kbd:`/`kbc:`/`kbf:`/`kbs:`/`img:`/`web:`) was **not** adopted; the three-prefix scheme `kb:`/`int:`/`ext:` stands unchanged | owner |
| 2026-07-29 | **Consequence — `relationships.md` is now a TEN-column table, and every "eight-column" statement in the work is void.** New shape, Kind adjacent to the Id it qualifies: `Source Id \| Source Kind \| Source Name \| Target Id \| Target Kind \| Target Name \| S2T Relation \| T2S Relation \| Provenance \| Observation`. This voids §5.2's "Eight columns" heading text, the `Strength`-dropped note's closing claim ("the table is therefore eight columns, not nine"), the worked example rows in feature-001's research report, delivery-001's gate criterion 4, and every "eight-column §5.2 shape" reference in the feature SPECs and task DETAILs | owner |
| 2026-07-29 | **Consequence — `Kind` needs a closed enum and a cross-consistency validator.** Permitted values: `document`, `concept`, `fact`, `section`, `source-artifact`, `image`, `web-page`. Because kind and prefix are now partly redundant, a new validator rule must assert they agree — `document`/`concept`/`fact`/`section` ⇒ `kb:`, `source-artifact` ⇒ `int:`, `web-page` ⇒ `ext:` — so the two can never drift. This is a second closed vocabulary alongside the relation vocabulary and needs the same fail-closed load-time treatment | owner |
| 2026-07-29 | **Owner decision — symmetric relations render with no arrowhead.** The absence of an arrow reads naturally as "no direction" and costs nothing. Double-headed arrows rejected; line style was unavailable as a channel because it already carries category | owner |
| 2026-07-29 | **Owner decision — interactive filtering/highlighting by relationship category is a REQUIRED feature with its own acceptance criterion**, not advisory guidance and not merely part of FR-14's manual controls. It is the mechanism that keeps a large vocabulary usable once category count exceeds the ~8-colour palette ceiling | owner |
| 2026-07-29 | **Owner decision — scale degradation is OUT of scope; the ceiling is measured, documented, and warned about.** No degraded mode is built. Replacing voided A-5: the research must **measure** the practical node-count ceiling, the requirements must **document** it, and the skill must **warn** when a target project exceeds it. A warning is cheap; an adaptive degraded mode is not, and is not being bought | owner |
| 2026-07-29 | **Owner decision — Q5 resolved: `graph.html` stays unreachable from the dashboard, deliberately.** The local-file entry point is recorded as the intended access path; making it dashboard-reachable is a separate change to the dashboard allowlist and CSP and is not in this work. To be recorded as a constraint so the limitation is deliberate rather than incidental | owner |
| 2026-07-29 | **Owner decision — Q8 resolved: ledger retention becomes its own methodology work item, raised now.** The shared reviewer-ledger lifecycle deletes ledgers at skill DONE, which would destroy the very gap findings FR-26 exists to deliver. This is a defect in the shared methodology, not something feature-006 should work around locally, so it is lifted out of this work into its own item | owner |
| 2026-07-29 | **Owner decision — "generic" means any project with an approved AID Knowledge Base.** `/aid-graph` is already gated on one (FR-7/FR-8), so the scope is bounded and testable, and the KB's **own conventions** — frontmatter, glossary, citation anchors — are legitimately assumable carriers. Rejected: any git repository (no convention could be assumed at all) and any documentation set. **This sharpens the earlier criticism rather than reversing it:** harvesting from *AID KB conventions* is legitimate and portable; harvesting from *this repository's particular instances* — "keep `int:->int:` only, the only harvested instance is script→data file" — was not. The vocabulary must still be standards-grounded, because the conventions name carriers, not the full range of relation types content can bear | owner |
| 2026-07-29 | **Owner decision — a "concept" is a glossary entry plus any term the KB's authoring conventions mark as defined.** Document sections remain a **separate** node kind, not a source of concepts. Rejected: glossary-only (too thin) and agent-extracted significant terms (unbounded and `inferred`-only — the same objection that ruled out the loose definition of "fact") | owner |
| 2026-07-29 | **Owner decision — fenced code blocks inside KB documents are NOT nodes**; a code example is content within a section. Confirms the narrowing already applied to FR-23. Note the ~1,200-node figure quoted at the granularity decision **included** 25 such blocks for this repository. *(Corrected 2026-07-29: an earlier version of this line said the true figure was "marginally lower", which understated it — **the whole ~1,200 figure is withdrawn**, not merely reduced by 25. Its fact term counted bare `CONFIRMED` tokens rather than anchored markers (33, not 227), and its source-artifact term (583) is unreproducible. See A-5: the bench asserts no size and the research derives it.)* | owner |
| 2026-07-29 | **Owner decision — a symmetric relation renders with NO arrowhead.** The absence of an arrow reads naturally as "no direction" and costs nothing. Arrowheads at both ends rejected; a distinct line style was not available, because line style already carries relationship category | owner |
| 2026-07-29 | **Owner decision — interactive filtering/highlighting by relationship category is a REQUIRED feature with its own acceptance criterion**, not merely a manual control under FR-14. It is the mechanism that keeps a large vocabulary usable once the category count exceeds what a palette can distinguish (~8 colours plus ~4 line styles) | owner |
| 2026-07-29 | **Owner decision — scale degradation is out of scope as a built mode, but measuring and warning is required.** No degraded rendering mode is built. Instead: the practical node-count ceiling is **measured and documented**, and the skill **warns** when a target project exceeds it. This replaces the voided A-5 — the ceiling becomes a measured, published number rather than an assumption granted to the design | owner |
| 2026-07-29 | **Finding — FR-13's Impact lens already IS the "local graph" view.** It reads "select a node, show its neighborhood to an adjustable depth," which is Obsidian's local-graph feature under another name. It was nearly re-proposed as new scope; it is existing scope, and the live question is only whether it still means the same thing when nodes are concepts rather than files | owner |
| 2026-07-29 | **Owner decision — there is NO `agent` node kind, and the graph therefore cannot answer "who wrote this".** Surfaced by feature-001's standards-first vocabulary: PROV-O's `wasAttributedTo`, DCMI's `creator` and CiTO's author network are all expressible relations with **no legal endpoint**, because §5.2's `Kind` enum has no agent value. The authorship half of those standards is deliberately **not imported**. Rationale: none of §2's four purposes (drift/coverage detection, navigation and onboarding, impact analysis, agent/RAG routing) needs authorship; no resolvable agent registry exists, so AC-1's resolvability could not be satisfied for such a node; and the change would touch §5.2, §5.3, feature-003's loader and feature-004's enumeration. Recorded as a **node-model boundary**, not a traversal gap — a later work adding an `agent` kind would be a deliberate extension with a defined id form and resolution check, not a bug fix | owner |
| 2026-07-29 | **REQUIREMENTS' A+ REOPENED A THIRD TIME — FR-13's Coverage lens carried TWO proxy defects, and FR-14a specified an unachievable open target.** Both found by feature-007's re-specification. **(a)** The lens read "unbacked `kb:` nodes and undocumented `int:` nodes". `kb:` now spans four kinds, so literally it floods with `section` and includes `fact`, which is **structurally unbackable** — FR-30 emits a fact node and its anchor edge together. Owner decision: domain narrowed to **`{document, concept}`**, unbacked `fact` becomes an **integrity warning**. **(b)** The same clause's `int:` half is the defect already corrected in AC-15 and FR-20 — **this clause was missed** — now keyed on **`Kind = source-artifact`**, since in-repo images share the prefix and carry no FR-21a significance qualifier. That is the **sixth** instance of the proxy pattern and the **third** clause keyed on `int:` where a kind was meant. **(c)** FR-14a said a `web-page` node opens "its resolved URL", which **FR-3 forbids** — §5.3 keeps raw URLs out of the table, so the view holds an opaque key. Owner decision: it opens **`./external-sources.md`**, the file that resolves the key. Rejected: carrying the URL, which would contradict §5.3 and reopen features 003 and 005 | owner |
| 2026-07-29 | **REQUIREMENTS' OWN A+ REOPENED — A-5's "verified" KB figure was built from the count feature-003 forbids.** Found during feature-002's re-specification. A-5 asserted "**616** KB nodes … each figure verified by count", whose fact term was **227 occurrences of the bare token `CONFIRMED`**. But Q13 defines a fact as a claim carrying a **checkable source anchor**, and feature-003's gated D2a-2 says counting every `CONFIRMED` occurrence "would manufacture nodes that resolve to nothing". Only **33** lines in this KB carry both `CONFIRMED` and an anchor string — independently re-counted 2026-07-29. So the asserted total was built from precisely the forbidden count: **the arithmetic was verified while its input never was.** Recomputed on the anchored definition the KB term is ~422, but **no figure is now stated at all** — the fact term is owned by feature-003's definition and the bench is a research deliverable (FR-18), so a requirement hardcoding a derived quantity becomes wrong the moment the derivation moves, which is exactly what happened. Q17's fourth instance, and the first hiding **inside a figure presented as verified** | owner |
| 2026-07-29 | **Correction — D-2a understated its own prerequisite set.** It named only feature-005, but the bench has **three terms with two producing features**: the `source-artifact`/`image`/`web-page` term needs feature-004's enumerator, the KB term needs feature-005's Pass 1, and the degree distribution needs Q13's merge. Mitigation recorded: feature-002 splits measurement into a parametric response surface measurable before extraction lands plus a later lookup, so the serialisation delays a verdict rather than all measurement | owner |
| 2026-07-29 | **Correction — FR-11's staleness set omitted the TOOL ITSELF, and the count "five" was hardcoded in four clauses.** Found while re-gating feature-003, whose wave-3 argument leaned on "the tool is one of FR-11's five inputs" — it is not. The extraction and coverage-producing scripts are none of inputs 1–5, so a tool upgrade that changes what is emitted (a new coverage row, a widened carrier, a corrected slug rule) would trip no staleness check and the artifact would go **silently stale**. **Input 6 added: the installed tool version**, by version string where exposed, else a digest over the installed scripts and templates that affect output. This is the **third** instance of the same omission after inputs 4 and 5 | owner |
| 2026-07-29 | **Consequence — the hardcoded count was itself a Q17 proxy defect, committed by the author hours after recording the warning.** FR-11, FR-32, AC-5 and AC-12 all said "all **five** of FR-11's staleness inputs" — a **count standing in for a set**, which is exactly the pattern Q17 flags as breaking without any edit. All four now read "all of FR-11's staleness inputs", and FR-11 states explicitly that the **list is authoritative, not its cardinality**. Recorded rather than quietly corrected, because the author both wrote the warning and then demonstrated it | owner |
| 2026-07-29 | **Owner decision — unreachable relations are KEPT, and reachability is reported per project.** feature-005's producer map found **ten of the vocabulary's 31 pairs have no producer** (`has-member`, `precedes`, `generated-by`, `quotes`, `revision-of`, `lockstep-with`, `tests`, `renders-to`, `alternate-of`, `canonical-form-of`) plus eleven tokens on mapped relations. They stay: pruning the vocabulary to what *this* repository can produce is exactly the fit-to-this-repo error the 2026-07-29 re-specification exists to correct, FR-5 prefers comprehensiveness, and a project extension or a new carrier can make any of them live later. feature-001's **W3 layer reports** reachability per project rather than gating on it | owner |
| 2026-07-29 | **Owner decision — the undetectable false merge MUST BE CLOSED before A+; a recorded blind spot is not acceptable.** feature-005 admitted that a *defined* concept sharing a label with an *undefined* second sense silently collects the wrong mention edges with no validator able to see it, bounded it three ways, and routed it. The owner **overrode** the author's recommendation to accept it: silent wrong edges corrupt the artifact's trustworthiness, which is the tool's entire purpose. A detection mechanism is required. **Constraint on that mechanism:** FR-24 forbids manufacturing defects from `inferred` opinion alone, so it must be **decidable** and should surface *candidates* advisorily rather than assert a defect it cannot prove | owner |
| 2026-07-29 | **Owner principle — "if there is a defect, the A+ is false."** Standing rule, stated when asked whether a spec already gated A+ should be reopened on a downstream feature's finding. A gate grade is a **claim about the artifact**, not a milestone banked and then defended: a grade that coexists with a known defect was never true. Consequently a gated SPEC **is reopened** whenever a real defect is found in it, and the cost of reopening is never itself an argument against doing so. This binds every gate in this work | owner |
| 2026-07-29 | **Owner decision — no `agent` node kind; the graph deliberately cannot answer "who wrote this".** Surfaced by feature-001's standards-first vocabulary: PROV-O's `wasAttributedTo`, DCMI's `creator` and CiTO's author network are all expressible relations whose **endpoints `Kind` cannot name**, because the enum has no agent value. The agent-half relations are therefore **not imported**. Three grounds: (a) none of §2's four purposes — drift/coverage detection, onboarding, impact analysis, RAG routing — needs authorship; (b) no resolvable agent registry exists in this project, so AC-1's resolvability requirement could not be satisfied for such a node; (c) it would touch §5.2, §5.3, feature-003's loader and feature-004's enumeration. Recorded as a **deliberate node-model boundary** so it is not mistaken for an oversight and quietly re-litigated | owner |
| 2026-07-29 | **Correction found during feature-004's re-specification — AC-15 and FR-20 were keyed on a PREFIX where they meant a KIND.** Both scoped the KB-gap class to `int:`, which was exact while `int:` meant source artifacts alone. The widened node model put in-repo `image` nodes on the same prefix, so the old wording would force an unreferenced picture to be either lens-highlighted with no ledger row (breaking AC-15's equality) or reported as undocumented project source. Both now key on **`Kind = source-artifact`**. Load-bearing because FR-26 derives gap severity from FR-21's significance qualifier, and an `image` qualifies by kind under FR-21a with no qualifier at all. **Notable as a process finding:** the impact map classified AC-15 as *surviving* and six review cycles passed over it, because the clause changed **meaning** without changing **wording** — a class of defect that only surfaced when a downstream SPEC tried to implement it | owner |
| 2026-07-29 | **Finding — the requirements ALREADY asked for concept-level nodes, and §5.3 has contradicted FR-23 since /aid-define.** §5.3 defines `kb:` as "A Knowledge Base **concept, fact**, or document" with an id form of "doc plus the **concept/heading** within it", and defines `int:` as a repo-relative path "**optionally narrowed to a symbol** within the file". Original FR-23 said granularity is "the whole artifact … **never** individual functions or lines." Those cannot both hold. The contradiction survived `/aid-define`'s cross-reference gate (graded A+) and `/aid-specify` (graded A+), and the research then resolved it **silently** in favour of the narrow reading — which is the direct cause of the undersized vocabulary. Today's decisions resolve it explicitly: §5.3's reading wins for the KB (concepts, facts, sections are nodes), FR-23's wins for code (no symbol nodes). **§5.3's `int:` "optionally narrowed to a symbol" clause is now definitively wrong and must be struck** in the amendment pass | owner |
| 2026-07-29 | **Note — the conforming-alternate-version route remains available but unused for colour.** WCAG permits conformance via a conforming alternate version, and the accessible table view is one; that is the mechanism licensing the canvas to be visual-only with no DOM proxy. Extending it to colour would make the graph itself non-conformant and rest all conformance on the table. Not adopted, because a non-colour channel was available at acceptable cost. *(This entry originally read "line style is free" — **withdrawn 2026-07-29**, unmeasured; see NFR-5.)* **Design ceiling to settle later** — beyond roughly 8 colours and 4 line styles, simultaneous distinction fails for all users, so a high category count is answered by interactive filtering/highlighting by category, not by more visual channels | owner |

## 1. Objective

Add a new AID skill that — like `/aid-summarize` — runs **after the Knowledge Base is
complete** and generates two artifacts from it:

1. **`relationships.md`** — all relationships among the **concepts, facts, sections and documents**
   held in the Knowledge Base, the project's **source artifacts**, and the **images** and **web
   pages** they reference.
2. **A live HTML graph view** of those relationships — a continuously-simulating, directed,
   colour-coded force-directed graph in the spirit of Obsidian's graph view, where the reader can
   change groupings, adjust density, filter by category, zoom, drag nodes, and focus a neighbourhood
   by hovering.

## 2. Problem Statement

The Knowledge Base is a lossy summary of the project source, informed by external sources. Today
that wiring is implicit: nothing records which source artifact generated which KB fact, or which
external source contributed it, in a form anyone can check. Four consequences follow, and all four
are in scope as purposes of this work — the owner rated them equally important:

1. **Drift and coverage detection.** A KB doc can go stale after the code it describes changes,
   and nothing surfaces it. Unbacked KB claims (a `kb:` node with no `int:` edge) and
   undocumented source (an `int:` node no KB doc points at) are both invisible today.

   **A source concept important enough to appear in the graph but absent from the KB is a gap in
   the KB — a defect, not merely a missing edge.** The graph is therefore a KB *quality* signal,
   not only a navigation aid: it reveals what the KB failed to capture. This raises the bar on
   source enumeration (§5.7), because an enumeration that never surfaces such a concept cannot
   detect the defect.
2. **Navigation and onboarding.** There is no overview of how the KB's concepts and the project's
   parts relate; a newcomer must read documents serially to build that map mentally.
3. **Impact analysis.** Answering "what does this change touch" — across KB docs, source
   artifacts, and external dependencies — is manual today.
4. **Agent/RAG routing.** Agents route over the KB via `INDEX.md`; explicit relationships give a
   richer structure to route on.

Because all four are primary, the artifacts must serve verification *and* comprehension — which
is a design constraint on the view, not just a list of benefits (see §5.6).

## 3. Users & Stakeholders

*Derived from §2; confirm at read-back.*

| Stakeholder | Interest |
|-------------|----------|
| **Maintainer / architect** | Primary human consumer. Uses the graph for structural inspection, impact analysis before a change, and reading the gap list. |
| **KB reviewer** | Consumes the gap ledger (FR-26) as review input; needs each finding to arrive with checkable evidence (FR-24). |
| **Newcomer to the project** | Uses the Overview lens to build a mental map without reading documents serially. |
| **AI agents** | Consume `relationships.md` as structure to route over, richer than `INDEX.md` alone (§2 item 4). Also the reason the artifact must stay machine-parseable, not merely human-readable. |
| **AID methodology owner** | Owns whether the KB-gap signal is trustworthy; affected by any incentive to weaken the significance rule (FR-25 rationale). |

## 4. Scope

*Derived from §5; confirm at read-back.*

### In Scope

- A new on-demand skill, `/aid-graph`, gated on an approved KB (FR-7, FR-8).
- Two generated artifacts: `relationships.md` and the interactive `graph.html` (FR-1, FR-2, FR-9).
- Source enumeration by structural significance, independent of the KB (FR-19 – FR-24).
- Two-pass extraction: deterministic scan plus a bounded agent pass (FR-29 – FR-32).
- Four preset lenses plus always-available manual controls (FR-13 – FR-15).
- An accessible table view as a peer rendering of the graph (NFR-2).
- A KB-gap reviewer ledger, routed onward (FR-25 – FR-28).
- Research to define the relation vocabulary (FR-5, **standards-first**) and to **validate the
  decided rendering architecture** (FR-18) — *not* to choose a renderer, which is already decided
  *(amended 2026-07-29; a research team reading only this line would have thought the choice was open)*.
- Reuse of `/aid-summarize`'s HTML toolchain at the script layer (FR-12).

### Out of Scope

- **Fixing KB gaps.** Findings route to `/aid-update-kb` / `/aid-housekeep` (FR-27).
- **Any mutation of KB content.** The skill is read-only with respect to the KB (FR-10).
- **Gating on KB completeness.** The run never fails because gaps exist (FR-25, FR-28).
- **Merging into `/aid-summarize`.** Considered and rejected; sharing is at the script layer (FR-12).
- **Automatic ticket creation** for detected gaps.
- **Function- or symbol-level granularity in project source code** (FR-23's code clause). *(Amended
  2026-07-29 — KB concepts, facts and sections ARE in-scope first-class nodes; only code stays
  whole-artifact.)*
- **A degraded rendering mode for very large graphs.** The ceiling is measured, documented and
  warned about; no adaptive degradation is built *(owner decision 2026-07-29, replacing voided A-5)*.
- **Dashboard reachability for `graph.html`** — the local-file entry point is the intended access
  path; wiring the dashboard allowlist and CSP is a separate change *(Q5 resolved 2026-07-29)*.
- **Enumerating generated/derived trees or vendored code** (FR-22).
- **Validating KB content quality** beyond the structural gap signal — that remains discovery's job.

## 5. Functional Requirements

*(confirmed)*

- **FR-1:** Emit `relationships.md` capturing relationships between KB **concepts, facts, sections
  and documents**, project **source artifacts**, **images**, and **web pages** *(node kinds widened
  2026-07-29; see §5.2's `Kind` enum)*.
- **FR-2:** Emit a **live, continuously-simulating, interactive** HTML graph view of those
  relationships with controls for grouping, density, and zoom. *(Amended 2026-07-29: "single-file"
  struck — it was already contradicted by FR-16's packaging release on 2026-07-28 and never updated;
  "interactive" alone did not capture continuous simulation.)*

### 5.1 Relationship sources (confirmed)

Relationships are drawn from exactly three sources:

1. **The Knowledge Base documents** — relationships among the concepts and facts the KB holds.
2. **The project source the KB represents** — the KB is a summary of information contained in
   the project source, so every KB fact is expected to connect to the source that generated it.
3. **The external sources the KB references** — the KB carries a document listing the external
   sources that contributed information to it (`external-sources.md`), so KB info is expected to
   connect to its contributing external source.

### 5.2 `relationships.md` table schema (proposed by owner; open to alternatives)

One table; each row is a single relationship, recorded once (never twice) because both
directions are named on the same row. Each endpoint is carried as **three** things: a
machine-verifiable id, its node **kind**, and a human-friendly display name. **Ten columns**
*(amended 2026-07-29 — `Source Kind` and `Target Kind` added by owner decision; was eight)*.

| Column | Required | Meaning |
|--------|----------|---------|
| Source Id | required | Machine-verifiable identifier of the originating node (see §5.3). |
| Source Kind | required | The originating node's kind, from the closed enum below. |
| Source Name | required | Human-friendly display name for the source node. |
| Target Id | required | Machine-verifiable identifier of the other node (see §5.3). |
| Target Kind | required | The other node's kind, from the closed enum below. |
| Target Name | required | Human-friendly display name for the target node. |
| S2T Relation | required | The type of relationship read Source → Target. |
| T2S Relation | required | The type of relationship read Target → Source — present so the inverse never needs a second row. |
| Provenance | required | How the relationship was established: `declared` (explicitly stated in the KB or source), `derived` (computed by a deterministic scan, no judgment), or `inferred` (concluded by the agent from reading content). |
| Observation | optional | A description or comment about the relationship. |

**`Kind` is a closed enum** *(added 2026-07-29)*. Permitted values:

| Kind | Required prefix | Meaning |
|------|-----------------|---------|
| `document` | `kb:` | A whole Knowledge Base document. |
| `concept` | `kb:` | A glossary entry or convention-marked defined term. |
| `fact` | `kb:` | A claim carrying a checkable source anchor. |
| `section` | `kb:` | A document section, addressed by its heading. |
| `source-artifact` | `int:` | A whole artifact in the project source — never a function or symbol. |
| `image` | `int:` or `ext:` | An image, in-repo or external. |
| `web-page` | `ext:` | An external web page. |

**The enum is closed, and it deliberately contains no `agent`** *(owner decision 2026-07-29)*. There is
no node kind for a person, team or tool, so a standards-derived vocabulary's authorship relations —
PROV-O's `wasAttributedTo`, DCMI's `creator`, CiTO's author network — have **no legal endpoint here**
and are not imported (FR-5), and **the graph cannot answer "who wrote this."** That is a recorded
boundary, not a gap: no §2 purpose needs authorship, no resolvable agent registry exists for AC-1 to
check against, and adding the kind would touch this section, §5.3, feature-003's loader and
feature-004's enumeration together. *(De-duplicated 2026-07-29 — two near-identical paragraphs stated
this, one of which said the enum was "closed at seven", a **count standing in for the set** and so a
Q17 defect. The list above is the authority, not its length.)*

The renderer reads `Kind` directly to choose node colour and shape; it never parses the id to
recover kind. Because kind and prefix are partly redundant, a **cross-consistency validator** must
assert the pairing in the table above, so the two can never drift. **`image` is the one branching
case** — it permits `int:` *or* `ext:`, where every other kind pins exactly one prefix, so the
validator needs a two-way test there and a naive one-to-one implementation would wrongly reject valid
external images. `Kind` is therefore a second
closed vocabulary alongside the relation vocabulary, and it is loaded fail-closed in the same way.

**`Strength` is dropped** *(Q1 resolved 2026-07-28)*. The column was retained as a possible
confidence-or-distance measure, but `Provenance` carries trust and the graph layout already conveys
distance through hop count, so a per-row number would duplicate what the picture shows while being
unreproducible across runs. It is not reinstated by the 2026-07-29 widening.

### 5.3 Node identity (confirmed)

Every node id carries a prefix naming which of the three sources it belongs to, and resolves to
something a validator can check. **Amended 2026-07-29** — the three prefixes are unchanged, but each
`Kind` (§5.2) now has its own id grammar and its own resolution check:

| Kind | Id form | How a validator resolves it |
|------|---------|------------------------------|
| `document` | `kb:<doc-path>` | The file exists under `.aid/knowledge/`. |
| `section` | `kb:<doc-path>#<heading-slug>` | A heading in that document slugifies to `<heading-slug>`. |
| `fact` | `kb:<doc-path>#fact:<anchor-token>` | That document carries the corresponding checkable source anchor. |
| `concept` | `kb:concept:<normalised-term>` | A glossary entry or convention-marked definition exists for `<normalised-term>`. |
| `source-artifact` | `int:<repo-relative-path>` | The path exists in the repository. |
| `image` | `int:<repo-relative-path>` (in-repo) or `ext:<key>` (external) | As for `source-artifact` or `web-page` respectively. |
| `web-page` | `ext:<key>` | `<key>` resolves to an entry in the KB's external-sources file. |

**A `concept` id is deliberately NOT document-scoped, and that follows from the merge rule.** Because
a concept named in five documents is **one** node (Q13), its identity cannot be qualified by any one
document — so it is keyed on the normalised term and resolves through the glossary that defines it,
while each mentioning document reaches it by an **edge**. Facts and sections, which are not merged,
stay document-scoped.

**The `int:` symbol narrowing is struck.** The former "optionally narrowed to a symbol within the
file" clause is removed: source code is whole-artifact only (FR-23), and that parenthetical was the
clause that contradicted FR-23 from `/aid-define` onwards.

Still owed to the SPEC (author-level): the exact slugification rule for `<heading-slug>`, the
`<anchor-token>` format, the `<normalised-term>` normalisation (case, whitespace, punctuation,
plurals), section-id stability under heading renames, and a disambiguation rule for two distinct
concepts sharing one label.

Because the KB already maintains a file mapping each external source to its origin (path or
URL), `relationships.md` rows never carry a raw absolute path or URL for external nodes — they
carry only the key, and the external-sources file remains the single place that resolves it.

### 5.4 Relation vocabulary (confirmed)

- **FR-4:** `S2T Relation` and `T2S Relation` draw from a **generic core vocabulary of
  relation/inverse pairs, plus validated project-defined extensions** — not free text. Every
  extension pair satisfies the same cross-entry inverse-pair rules as the core — **this list is the
  authority, not its length**: closure, totality, involution, symmetric consistency, category
  totality, and pair coherence — and is loaded fail-closed. Free-text nuance
  that no pair captures belongs in `Observation`. *(Amended 2026-07-29: "closed vocabulary" replaced
  — no fixed set fits every project.)*
- **FR-4a:** *(new 2026-07-29)* The **project extension** is a separate file from the shipped core,
  so an upgrade never overwrites project-defined pairs. A project may **add** pairs and **add**
  categories; it may not redefine or remove a core pair. A collision between an extension pair and a
  core pair is a **hard failure**, not a silent override — consistent with the project's existing
  fail-closed map-load-time gates. *(Location, file format and precedence are owed to the SPEC.)*
- **FR-5:** The vocabulary is to be established by **standards-first research**, deriving from
  **SKOS, Dublin Core (DCMI Terms), PROV-O, schema.org, IANA link relations (RFC 8288) and CiTO**,
  and producing a comprehensive set of relationship types with their inverses. A large vocabulary is
  acceptable and expected — comprehensiveness is preferred over brevity. The research must be
  **generic**: it verifies each term is expressible against a real repository but is explicitly
  **not** limited to what any one repository happens to contain. Each term records **which standard
  it derives from**. *(Amended 2026-07-29. The prior 8-pair set is superseded as the basis: it was
  harvested from this repository's own frontmatter conventions, and no standard was consulted.)*
- **FR-6:** Relationship types are **categorized**, and the category is available as a grouping
  dimension for the graph view (see §5.5).
- **FR-6a:** *(new 2026-07-29)* **Filtering and highlighting by relationship category is a required
  feature**, not merely one of FR-14's manual controls. Once the category count exceeds what colour
  can distinguish (about eight values, with contrast constraints), filtering — not additional visual
  channels — is what keeps the graph usable. It carries its own acceptance criterion.
- **FR-6b:** *(new 2026-07-29 — category governance, previously unbounded)* Categories are part of the
  vocabulary artifact, not free-form:
  - The **core** category set is closed and shipped with the core vocabulary. Its size is a research
    finding (FR-5), and the research must state the count explicitly rather than leaving it emergent.
  - A **project extension** may add categories, subject to FR-4a's rules, and each added category
    carries a one-line meaning.
  - **Every relation type belongs to exactly one category** — this is the category-totality rule the
    inverse-pair contract already enforces.
  - **The colour palette does not grow with the category count.** At most eight distinct category
    colours are assigned (AC-8a); further categories reuse colours and are separated by line style
    and by filtering. Without this, a thirty-category vocabulary would satisfy every requirement while
    being unreadable.

### 5.5 Skill shape and placement (confirmed)

- **FR-7:** The skill is named **`/aid-graph`** and is a standalone, on-demand skill — a sibling
  of `/aid-summarize` occupying the same post-KB slot in the lifecycle, not a phase of it and not
  auto-triggered by `/aid-discover`.
- **FR-8:** Preflight gates on a **completed, approved KB** — `.aid/knowledge/STATE.md` present
  with `User Approved: yes` — so it never runs mid-discovery.
- **FR-8a:** *(new 2026-07-29 — the genericity requirement, previously absent)* `/aid-graph` must
  work on **any project with an approved AID Knowledge Base**, not only on this repository. Because
  FR-8 already gates on an approved KB, that is the scope boundary: the skill **may** rely on the
  KB's own authoring conventions (frontmatter fields, citation anchors, a glossary) as carriers, and
  **may not** rely on anything specific to this repository's content, layout, or history. Concretely:
  no relation type, node kind, extraction carrier, or threshold may be defined by what this project
  happens to contain. Where a convention is absent in a target project, the skill **degrades
  gracefully** — it yields fewer nodes of that kind and records the absence in the **coverage notes**
  of FR-9a rather than failing.

  **Reporting path, twice corrected.** A convention absence is **not** a gap-ledger row: FR-26 requires
  every ledger row to carry the offending `int:` node as evidence, and a missing glossary has no `int:`
  node to cite, so routing absences there would either break FR-26's evidence rule or force a second,
  weaker row shape. That keeps the ledger source-artifact-keyed, consistent with AC-15's scoping of the
  same boundary. A first correction sent absences to a "run summary" — **which no requirement defined**,
  making the obligation point at a phantom artifact. They now go to FR-9a's coverage notes, inside an
  artifact that already exists and is already validated.

  The absence of this requirement is what allowed the first
  vocabulary research to fit its output to this repository without violating anything.
- **FR-9:** Both artifacts land in `.aid/knowledge/`, alongside `kb.html`:
  `.aid/knowledge/relationships.md` and the graph view at `.aid/knowledge/graph.html`.
  `relationships.md` carries **valid KB frontmatter and is indexed like any other KB document**
  *(Q3 resolved 2026-07-28)* — consistent with `INDEX.md` itself being generated. If the graph view
  ships as multiple files (permitted by FR-16), its companion assets live in a subdirectory under
  `.aid/knowledge/` and must be named so the KB index generator does not treat them as KB documents.
- **FR-9a:** *(new 2026-07-29 — defines the coverage notes, which FR-8a and AC-19 previously referred to
  as a "run summary" that no requirement created)* `relationships.md` carries a **`## Coverage notes`**
  section, after the relationship table, written on **every** run and not only when something is missing.
  It records two things — what the run could see, and what it deliberately did not.
  1. **Per node kind:** the **carrier convention** the kind depends on (glossary, checkable source
     anchors, headings, the external-sources file); whether that convention was **present or absent** in
     this project; and the **node count** produced for that kind. Every kind in §5.2's enum appears,
     including those with a count of zero.
  2. **Per enumeration exclusion (FR-22):** whether generated/derived trees and vendored code were
     excluded, and whether the **`.aid/settings.yml` ignore list was available or absent** — which is the
     reporting channel FR-22's "report" obligation requires and previously lacked (D-4 explains why the
     setting may not exist).

  It is part of `relationships.md` rather than a separate output because that file already exists, is
  already schema-validated, is already indexed (C-7), and is already covered by FR-32's reproducibility
  guarantee — so the notes are deterministic and testable without inventing an artifact or a second
  output channel. It sits **after** the table so FR-3's "the table is the single input to the graph"
  still holds: a parser reads the table and may ignore everything below it.
- **FR-10:** The skill is **read-only with respect to KB content** — it reads the KB, the project
  source, and the external-sources file, and writes only its own two artifacts. It never edits
  the KB.
- **FR-11:** The skill is **idempotent** — a staleness check makes re-running on an unchanged KB
  a no-op, with `--reset` to force regeneration. Its staleness input set is **wider** than
  `/aid-summarize`'s and comprises **the inputs listed below** *(extended twice on 2026-07-29 — each
  omission would have produced silently stale output)*. **The list is authoritative, not its
  cardinality:** other clauses must refer to "all of FR-11's staleness inputs" and never to a count,
  because a hardcoded number becomes wrong the moment the set grows — the proxy-keyed defect class
  recorded at STATE.md Q17, which this requirement itself demonstrated by hardcoding "five" in four
  places.
  1. the **KB**;
  2. the **project source**;
  3. the **external-sources file**;
  4. **`.aid/settings.yml`** — because FR-22's ignore list changes which nodes are enumerated, and
     FR-9a part 2 reports whether that ignore list was available. Omitting it meant a settings-only
     change would skip regeneration while the coverage notes went on asserting a stale ignore-list
     status — precisely the silent-wrongness FR-22's reporting rule exists to prevent;
  5. the **relation vocabulary — core *and* project extension** (FR-4, FR-4a). A project that adds an
     extension pair changes how edges are typed, so an unchanged KB can legitimately produce a
     different table. Omitting this meant a vocabulary change would not trigger regeneration at all.
  6. the **tool itself** — `/aid-graph`'s own installed version, identified by its version string
     where one is exposed and otherwise by a digest over the installed scripts and templates that
     affect output *(added 2026-07-29)*. The extraction and coverage-producing scripts are **not**
     any of inputs 1–5, so a tool upgrade that changes what is emitted — a new coverage row, a
     widened carrier, a corrected slug rule — would change none of them, the staleness check would
     not fire, and the artifact would go **silently stale**. This is the third instance of the same
     omission (after inputs 4 and 5) and the reason the list above is authoritative rather than its
     count.

  **Consequence for FR-32 and AC-5.** Byte-identity is asserted only across runs where **all** of
  these are unchanged. A tool upgrade is therefore a boundary across which byte-identity asserts
  nothing, and the first run after one legitimately re-baselines — attributable churn, not drift.
- **FR-12:** `/aid-graph` **reuses `/aid-summarize`'s HTML toolchain at the script layer** rather
  than reimplementing it — single-file assembly, contrast checking, HTML output validation, and
  Playwright-backed visual validation. Sharing happens through the scripts, not by merging the
  skills.

### 5.6 Graph view — presets and controls (confirmed)

- **FR-13:** The view ships **four named preset lenses**, one per purpose in §2, each a saved
  configuration of the same underlying controls over the same table:
  - **Coverage** — highlights unbacked **`document` and `concept`** nodes and undocumented
    **`Kind = source-artifact`** nodes; dims well-formed structure. Serves purpose 1 (drift/coverage).
    ***Both halves re-keyed from prefixes to kinds, 2026-07-29 (owner decision).*** This clause
    previously read "unbacked `kb:` nodes and undocumented `int:` nodes", which was exact while each
    prefix meant one kind. It now carries **two** proxy defects at once (Q17):
    - **`kb:` spans four kinds.** Read literally the lens floods with `section` nodes and includes
      `fact` — which is **structurally unbackable**, because FR-30 emits a fact node and its anchor
      edge together, so an unbacked fact cannot exist unless extraction is corrupt. The domain is
      therefore **`{document, concept}`**, and an unbacked `fact` is an **integrity warning**, not a
      coverage gap.
    - **`int:` now also carries in-repo `image` nodes**, so the undocumented half is keyed on
      **`Kind = source-artifact`** — the same correction already applied to AC-15 and FR-20, which
      **missed this clause**. An undocumented image is not a KB gap (FR-21a: images qualify by kind and
      carry no significance qualifier for a severity to derive from).
  - **Overview** — collapsed to categories and doc-level groups at low density. Serves purpose 2
    (navigation/onboarding). **Grouping model amended 2026-07-29:** "doc-level groups" no longer
    covers the majority of nodes, because sub-document nodes now outnumber documents. Sub-document
    nodes (`section`, `fact`) collapse into **their parent document**; `concept` nodes, which have no
    single parent document by construction (§5.3), group by **relationship category** instead. So the
    Overview lens shows documents, source artifacts and concepts, with sections and facts folded away
    until the reader drills in.
  - **Impact** — select a node, show its neighborhood to an adjustable depth. Serves purpose 3
    (impact analysis).
  - **Provenance** — `kb:` → `int:`/`ext:` chains only, colored by the `Provenance` column.
    Serves purposes 1 and 4.
- **FR-14:** **Full manual controls remain available at all times** — grouping, density, filters,
  and zoom — whether the user arrived via a preset or started from scratch. Presets are entry
  points, not modes that lock the view.
- **FR-14a:** *(new 2026-07-29 — the control surface, previously left generic)* FR-14's controls are
  specified rather than implied:
  - **Filter axes** — at minimum **relationship category** (required by FR-6a), **node kind**
    (§5.2's enum), and **provenance** (`declared` / `derived` / `inferred`). Plus an **orphan-node
    toggle**, which matters here because isolated nodes are precisely what the Coverage lens and the
    gap ledger exist to surface, so hiding them must be a deliberate act.
  - **Composition** — filters **compose with** a preset lens rather than resetting it: arriving via
    a lens and then filtering narrows that lens's view. This is what makes FR-14's "presets are entry
    points, not modes" concrete.
  - **Density** means **node/edge density in the view** — how much is drawn — and is *not* an
    exposure of `d3-force`'s physics parameters. Repulsion, link distance and centre force are
    **internal constants**, tuned once by the implementation, not user controls. Obsidian exposes
    them; this artifact deliberately does not, because a documentation viewer should not require
    physics tuning to become readable, and every exposed parameter is another way to make the graph
    worse.
  - **Two distinct node gestures, because "selecting a node" was doing two jobs.** FR-13's Impact lens
    says "select a node, show its neighborhood"; the owner's decision says selecting a node opens its
    document. Both are wanted, so they are separated:
    - **Single click — select.** Focuses the node: highlights its neighbourhood, dims the rest, drives
      the Impact lens's adjustable-depth view, and shows the node's rows in the table view. Navigates
      nowhere, so exploring never leaves the graph.
    - **Double click (or an explicit Open control) — open the underlying artifact.** For a `document`,
      `section`, `fact`, `source-artifact` or in-repo `image`, the file it names; for a **`concept`**,
      which owns no single file by construction (§5.3), its **defining document**, falling back to the
      highest-provenance mentioning document ordered `declared` > `derived` > `inferred`; for a
      **`web-page` or external `image`**, **`./external-sources.md`** — the file that resolves the key.
      ***Amended 2026-07-29 (owner decision).*** This previously said "its resolved URL", which **FR-3
      makes unachievable**: §5.3 deliberately keeps raw URLs out of the table, so the view holds an
      opaque `ext:<key>` and cannot resolve it without a second data path. Opening the registry is
      honest, mechanically checkable, and preserves FR-3's single-input rule. Rejected: carrying the URL
      in the table, which would contradict §5.3 and reopen features 003 and 005.

    *(Open **target** is the owner's decision of 2026-07-29. The **gesture split** is an author
    decision made because the Impact lens independently requires a selection gesture — flagged for
    owner confirmation. Note this differs from Obsidian, where a single click opens the note; here a
    single click must not navigate, or the Impact lens would be unusable.)*
- **FR-15:** No purpose is privileged by being the default layout; because all four purposes are
  equally primary (§2), acceptance criteria are stated per lens.
- **FR-16:** **Quality and interaction take priority over packaging constraints**
  *(owner decision 2026-07-28 — supersedes the original self-containment requirement).* The graph
  view is **no longer required** to be a single self-contained file. All three original packaging
  restrictions are dropped: it **may** ship as multiple files, it **may** fetch from a CDN or the
  network, and it **may** be produced by a real build step with third-party dependencies. The
  rendering research (FR-18) is to optimise for interaction quality and graph legibility, and is
  explicitly **not** to narrow its option space to preserve packaging purity.
- **FR-17:** Interactivity (grouping, density, zoom) makes **runtime JS mandatory**, so
  `kb.html`'s "no runtime diagram engine" rule does not apply to this artifact. That rule remains
  in force for diagrams in `kb.html`; the graph is a documented exception.
- **FR-18:** *How* the graph is rendered is **decided, not deferred** *(amended 2026-07-29; Q9)*.
  The architecture is **`d3-force` for physics + PixiJS (WebGL) for drawing** — the same split
  Obsidian's graph view uses. 2D; a true-3D orbit camera was considered and rejected. The remaining
  RESEARCH task is no longer a renderer selection but a **viability-and-performance validation** of
  the decided architecture, in this order:
  1. **WebGL under headless validation, first.** Establish whether the Playwright toolchain FR-12
     reuses can validate a WebGL canvas at all when no GPU is present. This gates everything below,
     because a negative result changes either the renderer or C-5.
  2. **Live performance at the real bench** — which the research **derives itself** by A-5's stated
     derivation, asserting **no size here**: both the KB term and the source-artifact term are the
     research's to produce, and every figure previously written into this requirement has been
     withdrawn as either void or built from a forbidden count. Tested with directed edges, colour and
     line-style encoding, hover labels, and node drag, against NFR-7's floor.
  3. **Payload, licence, attribution and the update mechanism** for `d3-force` + PixiJS.
  The former option space is closed. Its prior recommendation — a static SVG graph settling once
  before first paint — is **superseded**: it satisfied neither NFR-4's premise that the default path
  animates nor FR-16's instruction to optimise for interaction quality.

**Consequences of dropping the packaging restrictions.** Recorded here because they change work
that was already scoped, and none of them are optional to handle:

1. **One reused validator collides with the graph by design, and it is not the one first assumed.**
   *(Corrected 2026-07-28 after reading the scripts.)*
   - `validate-visuals.mjs` is the real collision. It collects **every** `<svg>` in the document
     and applies its T2 check — sibling `<g>` bounding boxes may not overlap by more than 20% of
     the smaller element's area. A force-directed graph drawn as SVG with a `<g>` per node
     **overlaps by nature**, so it fails T2 by design and needs an explicit, parameterised
     exclusion. A `<canvas>` or WebGL surface matches none of that script's three selectors
     (`.diagram-box`, `.infographic`, `svg`) and needs no exemption at all.
   - `validate-html-output.sh`'s **NM** assertion does *not* fail by design: all three sub-checks
     are keyed on the literal token `mermaid` (an inline engine bundle, a `mermaid.initialize()`
     call, or a CDN Mermaid `<script src>`), so a non-Mermaid renderer passes it unchanged.
   - Its **S2** CDN-free assertion fails only *if* the selected packaging actually fetches from a
     CDN — a conditional consequence of the packaging choice, not an automatic one.

   In every case `kb.html` must keep all checks unchanged; any exemption is per-artifact and
   parameterised, never achieved by weakening the shared script (feature-011).

   **Note the trade-off this creates:** SVG is the cheaper renderer for accessibility (NFR-1) but
   is the one that trips T2; Canvas/WebGL avoid the validator entirely but raise the accessibility
   cost. Neither choice is free, and FR-18's research must weigh both together.
2. **A build step, if adopted, adds a generate-time dependency chain** — `node_modules`, a lockfile,
   and a bundler — to a repository whose CLI is currently pure Bash/Node-stdlib. That touches
   `technology-stack.md`, `infrastructure.md`, CI, and the skill's own preflight (C-5), and it means
   `/aid-graph` can fail for reasons unrelated to the KB.
3. **A CDN dependency makes the artifact non-portable and network-dependent**, so a graph generated
   today may not render later or offline. The research must state this cost plainly for whichever
   option it recommends, and prefer vendoring when the interaction quality is comparable.
4. **Third-party code acquires licence, attribution, and update obligations** regardless of how it
   is delivered.

### 5.7 Source enumeration (confirmed)

- **FR-19:** *(Prefix scoping confirmed deliberate 2026-07-29 — this is **not** a Q17 proxy. `int:` here
  names the **discovery mechanism**, a walk of the project source, which legitimately yields both
  `source-artifact` and in-repo `image` nodes. Where a clause instead means the **gap class**, it must
  key on `Kind = source-artifact` — see FR-20, AC-15 and FR-13.)*
  `int:` nodes are discovered by enumerating the project source **independently of the
  KB** — not only where a KB doc happens to reference something. KB-driven enumeration is rejected
  because it structurally cannot surface the defect described in §2 item 1: a source concept the
  KB never mentions would never become a node.
- **FR-20:** A source concept that appears in the graph with no KB representation is reported as a
  **KB gap** (a defect), not silently dropped and not merely rendered as an unconnected node.
  **Keying clarified 2026-07-29:** "source concept" means a node of **`Kind = source-artifact`** — not
  everything carrying the `int:` prefix, which now also includes in-repo `image` nodes. An
  undocumented image is not a KB gap: images qualify by kind under FR-21a, so they carry no
  significance qualifier for a gap severity to derive from. See AC-15, which was re-keyed for the same
  reason.
- **FR-21:** A source artifact qualifies as a node by **structural significance**, not by mere
  file existence. It qualifies if any of the following holds:
  - it is an **entry point or public surface** — a skill, a CLI command, a template, or a script
    another script invokes;
  - it is **depended upon** by another source artifact;
  - it is a **named unit the project's own conventions treat as a unit** — a test suite, a
    manifest, a settings schema.
- **FR-21a:** *(clarified 2026-07-29)* FR-21's three significance criteria apply to **project source
  artifacts (`int:`) only**. `image` and `web-page` nodes are first-class **by kind** (FR-23, §5.2),
  not by passing a significance assessment, and are not subject to those criteria. KB-side nodes
  (`document`, `section`, `fact`, `concept`) likewise qualify by kind, via FR-30's deterministic
  extraction, not by significance.
- **FR-22:** Excluded from enumeration: **generated/derived trees** (rendered profile and package
  outputs, which are mechanically produced from the canonical tree and would multiply every node
  and every reported gap by the number of profiles), **vendored third-party code**, and anything
  matched by an **ignore list in `.aid/settings.yml`**.
  **Behaviour when the ignore-list setting is absent, stated 2026-07-29:** that settings section does
  not yet exist (D-4), so the skill must **report** that the ignore list is unavailable — in FR-9a's
  coverage notes, which is the defined channel — and proceed with the other two exclusions, rather than
  silently behaving as though an empty ignore list were configured. The generated-tree and vendored-code exclusions are unconditional and never depend on
  settings. Without this, a missing settings section would disable an exclusion invisibly.
- **FR-23:** ~~Enumeration granularity is the **whole artifact** — a script, a skill, a template —
  never individual functions or lines.~~ **Rewritten 2026-07-29 (owner decision): granularity is
  asymmetric — deep in the Knowledge Base, whole-artifact in code.**
  - **Knowledge Base:** **concepts**, **facts** and **document sections** are first-class nodes,
    each addressable independently of the file that carries it. A concept is not the same node as
    the document that defines it.
  - **Project source:** granularity remains the **whole artifact** — a script, a skill, a template.
    Individual functions, symbols and lines are **not** nodes.
  - **Media and external:** images and web pages are nodes in their own right, with their own kinds.

  The original whole-artifact-everywhere rule is superseded because it made the relationship
  vocabulary structurally small: file-to-file relations are inherently few, so no amount of
  vocabulary research could have produced the range of relations this feature is for.
- **FR-24:** Significance must be **derivable rather than judged** wherever possible, so that a
  reported KB gap carries `declared` or `derived` provenance and arrives with evidence a reviewer
  can check. The skill must not manufacture defects from `inferred` opinion alone.

### 5.8 Extraction pipeline (confirmed)

- **FR-29:** Extraction is **script-majority, agent-in-the-gaps** — two passes, not one mechanism.
- **FR-30:** **Pass 1 — deterministic scan.** Harvests what is already declared and what is
  mechanically derivable. Rows are stamped `declared` or `derived`.
  **Declared carriers corrected 2026-07-28** — an earlier draft named `Evidence:` citations, which
  do not exist in this KB (two occurrences, both prose labels in a single document). The real
  carriers, verified present across the KB, are:
  - **`sources:` frontmatter lists** — one per KB document, naming the files that document draws on;
  - **inline durable anchors** of the form `CONFIRMED <path> (search: "<token>")` — between 7 and 30
    per document;
  - **frontmatter cross-references** (`see_also`, `contracts`) and the generated routing index;
  - **external-source keys** resolved through the KB's external-sources file.

  Mechanically derivable edges remain file references, invocations, and dependency relations.

  **Widened 2026-07-29 — Pass 1 also produces the sub-document nodes**, because all three are
  mechanically extractable and therefore must not fall to the agent pass:
  - **Section nodes** from document headings (`kb:<doc-path>#<heading-slug>`);
  - **Fact nodes** from checkable source anchors (`kb:<doc-path>#fact:<anchor-token>`), each also
    yielding a `declared` edge to the `int:` path the anchor cites;
  - **Concept nodes** from glossary entries and convention-marked definitions
    (`kb:concept:<normalised-term>`), plus a `declared` edge from each defining document.

  This is a **deliberate reassignment of work from Pass 2 to Pass 1**: a glossary entry and a
  citation anchor are both literal text, so identifying them needs no judgment and must carry
  `declared`/`derived` provenance rather than `inferred` (FR-24). *(Heading-level cutoff,
  anchor-token format and collision handling are owed to the SPEC.)*
- **FR-31:** **Pass 2 — bounded agent pass.** Runs only over what the scan could not settle:
  candidate edges the scan surfaced but could not **type**, and relationships that genuinely require
  reading to identify. Rows are stamped `inferred`.

  **Narrowed 2026-07-29.** Pass 2 no longer identifies concept nodes — FR-30 now extracts them
  deterministically from the glossary, so Pass 2's job is **typing edges, not discovering nodes**.
  This keeps the agent pass bounded even though the node count roughly doubled, and it is the reason
  the widened node model does not enlarge the `inferred` share of the artifact.
- **FR-31a:** *(new 2026-07-29 — "bounded" is now defined, having been asserted since FR-29 without
  ever being specified. **Corrected in the same day's review**: a first draft bounded Pass 2 by
  forbidding it to "look for additional relationships", which would have banned the very
  reading-dependent edges FR-31 exists to produce. The bound constrains what Pass 2 may **read** and
  what it may **create**, never whether it may discover.)* Pass 2's bound has four parts, all of which
  must hold:
  1. **A closed input set.** Pass 2 reads only the KB documents, and reads **each at most once** per
     run. It may not follow references outward, crawl the source tree, or fetch anything. The input
     set is therefore finite and known before the pass starts, and its size is reportable up front.
  2. **It may create edges, never nodes.** Every node comes from FR-30's deterministic extraction, so
     Pass 2 may only relate nodes that already exist. This is what keeps the node count reproducible
     under FR-32 while still allowing `inferred` edges.
  3. **Two kinds of work, both bounded by (1).** Typing the candidate edges Pass 1 surfaced but could
     not classify — a closed list — and recording relationships that are only visible by reading a
     document it is already permitted to read once. The second kind is discovery, and it is in scope.
  4. **A completion signal.** The pass ends when every Pass-1 candidate carries either a typed
     relation or an explicit *cannot-type* disposition, and every document in the input set has been
     read exactly once. An untyped, undispositioned candidate is a failure, not a silent omission —
     otherwise the pass could "finish" by giving up quietly.

  Without this, an unbounded implementation satisfied every other requirement while calling itself
  bounded.
- **FR-32:** With **all of FR-11's staleness inputs unchanged** the deterministic majority of
  `relationships.md` is **byte-identical across runs**. *(Scope corrected 2026-07-29: this said
  "unchanged repository", which no longer covers the set — the relation vocabulary ships inside the
  tool rather than in the project, so a vocabulary change can alter how edges are typed while every
  repository file stays untouched. A reader of the old wording would have thought byte-identity
  survived a tool upgrade.)* This is what makes FR-11's staleness check meaningful: without a
  reproducible majority, the staleness check could not distinguish real drift from model
  nondeterminism and the artifact would churn on every invocation.

  **The deterministic majority grew 2026-07-29** and now covers section, fact and concept nodes and
  their declaring edges, in addition to the file-declared and derived edges it already covered. The
  byte-identity guarantee applies to that larger set, so id **ordering** must be defined over the new
  id grammars too.

### 5.9 Gap reporting and routing (confirmed)

- **FR-25:** `/aid-graph` **reports gaps, it does not gate on them.** The run completes
  successfully regardless of how many KB gaps it finds.
- **FR-26:** Gap findings are written as a **reviewer ledger** in the project-wide 7-column shape
  (`# | Severity | Status | Doc | Line | Description | Evidence`) at
  `.aid/.temp/review-pending/<scope>.md`, one row per gap, each carrying the offending `int:` node
  as evidence.
- **FR-27:** Fixing gaps is **out of scope for this skill**. Findings route to `/aid-update-kb` or
  `/aid-housekeep`, which already own targeted KB updates and re-discovery.
- **FR-28:** The skill's own quality gate covers **its own artifacts only** — id resolvability,
  inverse-pair consistency, provenance population, and the HTML view's validity — never the KB's
  completeness.

**Rationale.** Gating on KB completeness would fail `/aid-graph` for reasons outside its own
control, and would create an incentive to tune the significance rule (FR-21) downward until gaps
disappear — corrupting the signal the artifact exists to produce. Reporting-only also preserves the
one-way trust direction set by FR-10: the tool observes and cannot alter what it observes.

**Decision — separate skill, shared scripts.** Folding this into `/aid-summarize` was considered
and rejected. The two artifacts differ in audience (`kb.html` targets a non-technical newcomer and
forbids KB authoring-rule leakage; the graph targets a maintainer doing structural inspection), in
grading model (`relationships.md` grades as *data* — id resolvability, inverse-pair consistency,
provenance coverage — while `kb.html` grades on visual fidelity behind a mandatory human visual
gate), and in staleness inputs (see FR-11). The reuse argument is satisfied at the script layer
because the HTML machinery already lives outside the skill, in `aid/scripts/summarize/`. Accepted
cost: one more skill in the canonical→profiles render and the install manifests, plus some
duplicated preflight/writeback prose.

- **FR-3:** This table is the **single input** to the graph display — the HTML view renders from
  it rather than from an independent extraction pass.

## 6. Non-Functional Requirements

### 6.1 Accessibility (confirmed)

- **NFR-1:** `graph.html` meets **WCAG AA**, matching the bar `kb.html` already holds.
- **NFR-2:** AA is satisfied by shipping **two first-class renderings of the same data**: the
  interactive graph, and an **accessible table view** — sortable, filterable, keyboard-navigable,
  screen-reader friendly — which is the `relationships.md` content rendered as real HTML. The
  table is not a hidden fallback; it is a peer view.
- **NFR-3:** Every preset lens (FR-13) applies to **both** renderings. "Coverage" in table form
  lists exactly the gap rows the graph highlights.
- **NFR-4:** **Reduced-motion** preference disables layout animation and renders a settled graph.
  *(Clarified 2026-07-29: this is the **fallback path**, not the default. The default path animates
  continuously — FR-2, FR-18. The settled render was mistakenly adopted as the only behaviour by the
  superseded rendering research, which made this requirement vacuous.)*
- **NFR-5:** **Colour is never the sole carrier of meaning.** *(Encoding settled 2026-07-29.)*
  - **Node type** — carried by **colour and shape**.
  - **Relationship category** — carried by **colour and line style** (solid / dashed / dotted /
    dash-dot).
  - **Relationship name** — shown on **hover or selection**, and always readable as text in the
    accessible table view. There are no persistent edge labels.
  - **Direction** — carried by an **arrowhead** on asymmetric relations; a symmetric relation has
    **no arrowhead**, and the absence is itself the signal.

  This is **WCAG 2.2 SC 1.4.1 Use of Color, Level A** — verified at w3.org/TR/WCAG22 on 2026-07-29.
  AA conformance (NFR-1) requires every Level A criterion, so this requirement is not optional and
  was explicitly **considered for relaxation and retained**. *(An earlier version of this clause
  asserted "line style costs nothing per frame". **Withdrawn 2026-07-29** — that was argued and never
  measured, and it is exactly the kind of untested performance claim this work has already been burned
  by. Line-style cost is now a **feasibility-and-cost verdict the FR-18 research owes**, not a fact the
  requirements assert. Nothing in NFR-5 depends on it: the requirement is that a non-colour channel
  exist, and if line style proves expensive the research must propose another.)*
- **NFR-6:** Zoom and pan have **keyboard equivalents**. **Widened 2026-07-29** to every interactive
  gesture, because FR-14a added two that this requirement did not cover: **selecting** a node and
  **opening** its artifact must both be keyboard-operable, as must category filtering (FR-6a) and lens
  selection. This is **WCAG 2.2 SC 2.1.1 Keyboard, Level A**, which AA conformance requires — the same
  reasoning that retained NFR-5.
  - **Node dragging is exempt**, as SC 2.1.1 excludes input that is genuinely path-dependent: dragging
    repositions a node and conveys no information the keyboard user is denied.
  - The **accessible table view** provides the keyboard-operable route to select and open, so the
    canvas's mouse gestures are an enhancement rather than the only path — which is what lets the canvas
    stay visual-only (NFR-2) without failing this criterion.
- **NFR-7:** *(new 2026-07-29 — the performance floor, previously absent)* The live graph sustains
  **≥30 frames per second at the project's derived bench**, **during both steady simulation and
  node-drag interaction**, measured headless through the same Playwright harness FR-12 reuses. The
  bench is whatever the research derives under FR-18 from the widened node model — this requirement
  deliberately states **no node count**, because the previously-quoted figures were either voided
  (784) or unreproducible (see A-5). Layout **settle time is measured and reported, but not gated**.
  Without a stated floor, "live" was unverifiable and no acceptance criterion could test it.
- **NFR-8:** *(new 2026-07-29, replacing voided A-5)* The practical **node-count ceiling is measured
  and documented**, and `/aid-graph` **warns** when a target project exceeds it. No adaptive
  degraded rendering mode is built — the warning is the required behaviour.

**Rationale.** The table carries the accessibility burden the canvas cannot, without fighting the
medium — and for verification work a filterable list of gap rows is often the better tool anyway.
It is also mechanically validatable, so it can inherit `validate-html-output.sh` and the existing
a11y checks, leaving the human visual gate to judge whether the graph is legible. Because the
table *is* the single input to the view (FR-3), this adds no second data path.

## 7. Constraints

*Derived from the existing codebase and KB; confirm at read-back.*

- **C-1:** ~~`graph.html` must be a single self-contained file~~ — **withdrawn 2026-07-28** per the
  owner's decision recorded at FR-16. No packaging constraint binds the graph view. `kb.html`'s own
  S2 self-containment gate is unaffected and remains in force for that artifact.
- **C-2:** The skill is authored in the canonical tree and rendered to every host profile by the
  existing profile renderer; it must not be hand-maintained per profile.
- **C-3:** Adding a skill touches the install and emission manifests, which the KB already flags as
  lockstep hazards — the change must keep them consistent.
- **C-4:** Reuse rather than reimplement `/aid-summarize`'s HTML scripts (FR-12); do not fork them.
- **C-5:** Existing validator tooling requires Node.js ≥ 20, and Playwright-based visual validation
  must degrade gracefully when the browser is not provisioned (as `/aid-summarize` already does).
  **Extended 2026-07-29 — a second, distinct failure mode.** With a WebGL renderer (FR-18), Playwright
  may be provisioned *and still be unable to draw*, because the headless browser has no GPU or no
  WebGL context. That is not the same case as an unprovisioned browser and needs its own fallback:
  a software-renderer flag, a reduced screenshot scope, or an explicit skip-with-recorded-skip. **This
  is the highest-risk open item in the work** — FR-12's whole reuse of the visual-validation toolchain
  rests on it, so FR-18's research resolves it *before* any performance measurement, since a negative
  result would force a change to either the renderer or this constraint.
- **C-6:** Reviewer output must use the project-wide 7-column ledger schema written to
  `.aid/.temp/review-pending/` (FR-26) — no bespoke findings format.
- **C-7:** `relationships.md` lives in the KB folder and is a KB-adjacent artifact, so it must obey
  KB authoring conventions where they apply (frontmatter, machine-parseability). **Specifically:**
  the KB index generator emits one entry per non-dot KB document, so a `relationships.md` placed in
  `.aid/knowledge/` will be picked up by the index and must therefore carry valid KB frontmatter
  (`kb-category`, `objective`, `summary`, `tags`). **Resolved 2026-07-28 (Q3):** it satisfies that
  contract — `relationships.md` is a generated, indexed KB document.
- **C-8:** *(new 2026-07-29 — Q5 resolved)* `graph.html` is **deliberately not reachable from the
  dashboard**. The dashboard's leaf allowlist and CSP would both need changing, and a CDN-fetching or
  multi-file artifact would violate the existing CSP. The intended access path is **opening the local
  file**. Recorded as a constraint so the limitation is deliberate rather than incidental.

## 8. Assumptions & Dependencies

*Confirm at read-back.*

- **A-1:** The KB maintains a file mapping each external source to its origin (path or URL), so
  `ext:` rows carry only a key and never a raw URL (§5.3).
- **A-2:** The KB is complete and approved before this skill runs; it does not validate KB content.
- **A-3:** `Provenance` is a required column — every row has a provenance by construction (§5.2).
- **A-4:** The graph view's entry point is `graph.html` (FR-9); companion assets, if the selected
  packaging produces any, sit beside it under `.aid/knowledge/`.
- **A-6:** Test fixtures are self-built and do not depend on any work folder's contents, per the
  project's transient-work-folder rule — this binds the Q4 `ext:` fixture (AC-1).
- **A-5:** ~~Node counts land in the hundreds, not tens of thousands, given FR-22/FR-23 — this is
  what makes the layout tractable. If a target project violates it, the density controls alone will
  not rescue the view.~~ **Void 2026-07-29 — FR-23's granularity widened, so this assumption no
  longer holds.** **No KB total is stated, and the earlier one was wrong** *(corrected 2026-07-29 —
  see below)*. The KB term is the sum of: documents, glossary concepts, H2–H6 sections, and **facts as
  Q13 defines them — claims carrying a checkable source anchor.** Fenced code snippets are excluded
  (Q14).

  **Why no figure appears here.** An earlier version asserted "**616** KB nodes … each figure verified
  by count", built from **227 occurrences of the bare token `CONFIRMED`**. That is the wrong input:
  only **33** lines in this KB carry both `CONFIRMED` *and* an anchor string, and feature-003's gated
  D2a-2 states that counting every `CONFIRMED` occurrence "would manufacture nodes that resolve to
  nothing." So the asserted total was built from precisely the count the schema forbids, and the
  arithmetic was verified while its input never was. Recomputed on the anchored definition the KB term
  is about **422** — but that number is *also* not stated as a requirement, because the fact term
  depends on a definition owned by feature-003 and the bench as a whole is a **research deliverable**
  (FR-18, feature-002's derivation procedure). A requirement that hardcodes a derived quantity becomes
  wrong when the derivation changes, which is what happened here.

  **The source-artifact term is likewise unstated.** The old "583" is unreproducible — this repository
  has 374 tracked files under `canonical/` and 1,725 outside `.aid/` and `profiles/`, neither of which
  is 583 — and it came from research containing fabricated figures.

  What the requirements **do** state: the old 784-node bench and every performance conclusion built on
  it are void, the "bounded to the hundreds" premise is gone, and layout tractability is a finding the
  research owes rather than an assumption granted to it.

- **D-1:** Depends on the relation-vocabulary research (FR-5) completing before implementation.
  **Scope enlarged 2026-07-29:** it is now a standards-first traversal (SKOS, DCMI Terms, PROV-O,
  schema.org, IANA RFC 8288, CiTO), a core-plus-extension architecture, and per-term attribution to
  its originating standard — materially larger than the original harvest, so its estimate rises.
- **D-2:** Depends on the **rendering viability-and-performance research** (FR-18) completing before
  implementation. *(Restated 2026-07-29: the renderer is decided; what remains is validating it.)*
- **D-2a:** *(new 2026-07-29; prerequisite set corrected the same day)* The rendering research now
  **depends on the extraction and enumeration work**, which it previously did not. Its bench can no
  longer be derived by counting files: concept **merging** (Q13) turns repeated mentions into graph
  degree rather than duplicate nodes, and hub distribution is exactly what layout cost depends on.
  The bench has **three terms with two producing features** — the `source-artifact`/`image`/`web-page`
  term needs **feature-004's enumerator**, the KB term needs **feature-005's Pass 1**, and the degree
  distribution needs Q13's merge. An earlier version named only feature-005, which understated it.
  **This serialises features that used to run in parallel** and must be reflected in the delivery
  sequencing. Mitigation available: feature-002 splits its measurement into a **parametric response
  surface** measurable before extraction lands, plus a later lookup for the project-specific verdict —
  so the serialisation delays a verdict rather than all measurement.
- **D-3:** Depends on `/aid-summarize`'s script layer remaining stable, or on extracting the shared
  pieces to a neutral location.
- **D-4:** FR-22's ignore list depends on a **new settings section that does not yet exist**
  (`.aid/settings.yml` is at `format_version: 3`); adding it may require a version bump and a
  reconcile rule — see STATE.md Q6.
- **D-5:** Real-world `ext:` resolution depends on an **entry format for the KB's external-sources
  file that does not yet exist**, and which `/aid-graph` may not author itself under FR-10 — see
  STATE.md Q7. **More urgent as of 2026-07-29:** that format must now also carry **`web-page` and
  external `image` nodes**, which are first-class kinds (§5.2). Previously `ext:` was a minor branch
  validated against a fixture; it is now a node kind the graph is expected to display, so the missing
  format blocks more than one acceptance criterion.
- **D-6:** *(new 2026-07-29)* FR-26's gap ledger depends on the **ledger-retention methodology change
  raised as its own work item** (Q8). The shared reviewer-ledger lifecycle deletes ledgers at skill
  DONE, which would destroy the very findings FR-26 exists to deliver, so feature-006 cannot satisfy
  FR-26 until that carve-out lands. Recorded here because a planner reading §8 would otherwise not see
  the prerequisite at all.

## 9. Acceptance Criteria

*Derived; per-lens per FR-15. Confirm at read-back.*

**`relationships.md`**

- **AC-1:** Every `Source Id` and `Target Id` resolves, **by the per-kind protocol in §5.3**
  *(amended 2026-07-29)*: a `document` to an existing KB file; a `section` to a heading that
  slugifies to its fragment; a `fact` to the checkable source anchor it names; a `concept` to the
  glossary entry or convention-marked definition of its normalised term; a `source-artifact` or
  in-repo `image` to an existing repo-relative path; a `web-page` or external `image` to an entry in
  the external-sources file. Choosing glossary-anchored concepts (Q14) is what keeps the `concept`
  branch mechanically checkable rather than a matter of judgment.
  **The `ext:` branch is validated against a synthetic test fixture**
  *(Q4 resolved 2026-07-28)*, because this project's own `external-sources.md` has zero entries and
  would satisfy the criterion vacuously. The fixture supplies a controlled external-sources file
  with both resolvable and deliberately unresolvable keys, so the check is proven to fire.
- **AC-2:** Every row's `S2T Relation` and `T2S Relation` are a valid inverse pair from the **core
  vocabulary or a validated project extension** *(amended 2026-07-29)*; no row's two directions
  disagree.
- **AC-2a:** *(new 2026-07-29)* Every row's `Source Kind` and `Target Kind` are members of §5.2's
  closed enum, and each **agrees with its id's prefix** by the pairing table there — so `Kind` and
  prefix can never drift.
- **AC-3:** No relationship is recorded twice (once forward, once inverse) — one row per
  relationship.
- **AC-4:** Every row carries a `Provenance` value of `declared`, `derived`, or `inferred`.
- **AC-5:** Re-running with **all of FR-11's staleness inputs unchanged** leaves the deterministic
  (`declared` + `derived`) rows byte-identical (FR-32) — *not* merely "an unchanged repository", since
  the relation vocabulary is tool-internal *(corrected 2026-07-29)*. **Scope grew 2026-07-29:** that set now includes the section, fact and
  concept nodes FR-30 extracts and their declaring edges, so the guarantee covers a substantially
  larger share of the artifact than when this criterion was written.

**`graph.html`**

- **AC-6:** *(rewritten 2026-07-28; extended 2026-07-29.)* Given the artifact as delivered by whatever
  packaging the rendering research selected, when it is opened by its documented entry point, then it
  renders the graph successfully, and its runtime prerequisites are **documented explicitly** so a
  reader knows what the artifact needs to work. **"Renders successfully" now means the live simulation
  runs** — nodes drift toward equilibrium, hovering focuses a neighbourhood and dims the rest, and
  dragging a node pulls its neighbours. **WebGL support is itself a runtime prerequisite** and must be
  documented alongside network access, companion assets and build output.
- **AC-6a:** *(new 2026-07-29)* The graph sustains **NFR-7's ≥30fps floor** at the research-derived
  bench during steady simulation and during node drag, measured headless. This is the criterion that
  makes "live" testable; before it existed, every criterion here was satisfied by a static picture.
- **AC-7:** All four preset lenses are present and each visibly changes the view; each applies to
  both the graph and the table rendering.
- **AC-8:** Grouping, density, filter, and zoom controls remain usable after arriving via a preset.
- **AC-8a:** *(new 2026-07-29 — FR-6a; made testable after review)* **Filtering and highlighting by
  relationship category** is present and functional in both renderings. Testable form, in three parts
  rather than one subjective predicate:
  1. Every category in the loaded vocabulary is offered as a filter value, and selecting one reduces
     the rendered edge set to exactly the rows carrying that category — checkable by comparing the
     rendered count against `relationships.md`.
  2. Filters **compose** with the four preset lenses rather than resetting them (FR-14a).
  3. The palette assigns **at most eight** distinct category colours; beyond that, categories reuse
     colours and are disambiguated by line style and by filtering. This replaces the untestable word
     "legible" with a countable bound.
- **AC-9:** Passes the existing HTML structural and a11y checks at WCAG AA; the table view is
  keyboard-navigable and screen-reader usable; reduced-motion yields a settled graph.
  **Scoped 2026-07-29:** the DOM-level structural and a11y checks apply to the **page structure and
  the table view**, not to the canvas element — the canvas is visual-only (Q9) and carries only a
  text alternative. AA conformance rests on the table as the conforming alternate version (NFR-2). The
  SPEC must state which existing check applies to which part of the artifact, so nothing is asserted
  against a surface that cannot satisfy it.
- **AC-10:** Renders from `relationships.md` alone — no second extraction path (FR-3).

**Skill behavior**

- **AC-11:** Preflight refuses to run without an approved KB, with an actionable message.
- **AC-12:** Re-running with **all of FR-11's staleness inputs unchanged** is a no-op, and changing
  **any one of them** — the KB, the project source, the external-sources file, `.aid/settings.yml`,
  the relation vocabulary (core or project extension), or **the installed tool version** — triggers
  regeneration;
  `--reset` forces it unconditionally. *(Amended 2026-07-29: this criterion named only "KB and source",
  so it would have passed an implementation that ignored the other three inputs entirely.)*
- **AC-13:** No KB file is modified by any run.
- **AC-14:** Detected KB gaps appear as ledger rows with the offending `int:` node as evidence, and
  the run still completes successfully.
- **AC-15:** The Coverage lens surfaces exactly the gaps present in the ledger — the two agree.
  **Scope re-keyed 2026-07-29 — from a prefix to a kind.** The equality binds **`Kind =
  source-artifact` only**. It previously read "the `int:` class only", which was accurate when `int:`
  meant source artifacts and nothing else; the widened node model put **in-repo `image` nodes on the
  same `int:` prefix**, so a prefix-keyed reading would force an unreferenced picture to be either
  highlighted by the lens with no ledger row (breaking this equality) or reported as undocumented
  project source (which it is not). The distinction is load-bearing rather than cosmetic: FR-26's
  ledger derives severity from FR-21's significance qualifier, and an `image` node qualifies **by
  kind** under FR-21a and therefore carries no qualifier at all. `Kind = source-artifact` is the class
  FR-20 defines as a KB gap and the class FR-26 requires the ledger to carry as evidence. The Coverage lens additionally highlights unbacked **`document` and `concept`** nodes per FR-13 *(cross-reference updated 2026-07-29 when FR-13's domain was narrowed from "`kb:` nodes"; `section` is excluded and an unbacked `fact` is an integrity warning)*; that
  is a **lens-only signal** with no corresponding ledger row, and its presence does not breach this
  criterion. (The alternative reading — extending the ledger to emit `kb:`-unbacked rows too — was
  considered and not adopted, because FR-20 and FR-26 are explicitly source-artifact-keyed.)
- **AC-16:** Enumeration honours the exclusions in FR-22 — no node originates from a generated or
  derived tree, from vendored code, or from an ignore-listed path; and **no *source-code* node is
  finer-grained than a whole artifact**, with no function or symbol nodes (FR-23's code clause). KB
  concepts, facts and sections **are** first-class sub-document nodes per FR-23's KB clause.
  *(Amended 2026-07-29 — as written, this criterion contradicted the rewritten FR-23 outright.)*
- **AC-16a:** *(new 2026-07-29 — NFR-8)* When a target project's node count exceeds the documented
  ceiling, the run **warns** and still completes.
- **AC-17:** The HTML pipeline invokes `/aid-summarize`'s existing scripts rather than forked copies
  (FR-12) — verified by review, and by the absence of duplicated assembler/validator logic.
- **AC-18:** `relationships.md` carries KB frontmatter valid for the KB index generator, and
  regenerating the KB index leaves both the index and `relationships.md` consistent (C-7).
- **AC-19:** *(new 2026-07-29 — tests FR-8a's genericity, which had no criterion)* Run against a KB
  that lacks each convention in turn, the skill **completes successfully** and yields zero nodes of
  the affected kind rather than failing: no glossary ⇒ zero `concept` nodes; no checkable source
  anchors ⇒ zero `fact` nodes; no headings ⇒ zero `section` nodes; an empty external-sources file ⇒
  zero `web-page` nodes. Each absence appears in **FR-9a's coverage notes** — naming the convention, its
  status, and the resulting count — and **not** as a gap-ledger row (FR-8a explains why: FR-26's rows
  must carry an `int:` node as evidence, and a missing convention has none). Validated against fixtures,
  since this repository has all four conventions and would satisfy the criterion vacuously — the same
  reasoning as AC-1's `ext:` fixture (A-6).
- **AC-20:** *(new 2026-07-29 — tests FR-9a on the **normal** path, which AC-19 does not)* On a run where
  every carrier convention is present, `relationships.md` still carries a `## Coverage notes` section
  listing **every** node kind in §5.2's enum with its convention status and node count, and the FR-22
  exclusion statuses including whether the ignore list was available. Without this, an implementation
  that writes notes **only** when something is absent would satisfy AC-19 and every other criterion
  while violating FR-9a on every healthy project — which is the majority case.
- **AC-21:** *(new 2026-07-29 — tests NFR-6's widened scope, which no criterion reached)* Every
  interactive control is **operable by keyboard alone**: selecting a node, opening its artifact,
  choosing a preset lens, and filtering by category. Verified by driving each with keyboard input only.
  This matters because a control drawn **on the canvas** rather than as a focusable HTML element would
  fail **WCAG SC 2.1.1 (Level A)** while passing AC-7, AC-8 and AC-8a, all of which test functional
  behaviour rather than access. Node dragging is excluded, per NFR-6's path-dependent exemption.

## 10. Priority

**Immediate — highest priority.** The owner directed that this work start now, ahead of other
candidate work.

Rationale: two of the four purposes in §2 are quality signals about the Knowledge Base itself, and
the KB is load-bearing for every downstream pipeline phase — a KB with undetected gaps degrades
everything built on it.

**Proposed delivery shape** (recommendation carried into `/aid-plan`, which owns final sequencing):

1. **Research** — the **standards-first** relation vocabulary (FR-5: SKOS, DCMI Terms, PROV-O,
   schema.org, IANA RFC 8288, CiTO, with core-plus-extension architecture) and the rendering
   **viability-and-performance validation** (FR-18: WebGL-under-headless first, then live performance
   against NFR-7). Both block implementation (D-1, D-2). **Both are larger than originally scoped.**
2. **`relationships.md` + gap ledger** — a functional MVP on its own: it delivers verification,
   impact analysis, and agent-routable structure with no view at all, because the table is readable
   as markdown. Nearly all the value and nearly all the risk live here — the extraction, the
   identity scheme, and the significance rule.
3. **`graph.html`** — the live interactive view plus the accessible table view, built on
   deliverable 2's output.

**Sequencing amended 2026-07-29 — the shape above no longer holds cleanly.** D-2a records why: the
rendering research now needs a bench built from **merged concept nodes**, which only exist once the
extraction of deliverable 2 runs. So the rendering half of step 1 is no longer fully parallel with
step 2, and `/aid-plan` must re-sequence rather than reuse this shape. The vocabulary half remains a
true prerequisite and can still run first.

Sequenced this way, the expensive research blocks nothing from being usable: if the rendering
research stalls, `relationships.md` and the gap ledger still ship.
