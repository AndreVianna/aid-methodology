# Relation Vocabulary Research

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.4 (FR-4–FR-6), §8 (D-1), §10 (deliverable 1) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Reconciled with features 003/005 — file ownership corrected to this feature (was feature-003); `endpoint_kinds`/`passes` restated as load-time fail-closed gates rather than consumer-only; `endpoint_kinds` validator open item closed (V12 `[LOW]`) | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — vocabulary carrier realigned to features 003/005: file is now YAML (`relation-vocabulary.yml`, owner decision), parse contract restated as a YAML entry contract, P2a render hazard re-derived for `.yml`, consumer table restated against the entry shape, and the former Markdown sections re-homed | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the manifest and install wiring and the emission-manifest records are now **feature-012**'s, and the two ship-time Knowledge Base updates (`artifact-schemas.md`, `domain-glossary.md`) are **feature-013**'s. No decision in this SPEC changes | /aid-specify |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles; STATE.md Q9–Q15) and against feature-003's and feature-004's fixed contracts.** The basis of the delivered vocabulary was invalidated, not its mechanism: FR-5 now requires a **standards-first derivation** from six named standards, and the shipped 8 pairs / 15 entries / 5 categories were harvested from this repository's own frontmatter carriers with **no standard consulted**. Both halves of this SPEC are reworked. (1) **Derivation is standards-first and per-term attribution is a required field** — the entry grows from **seven keys to eight** with `derived_from`, whose token set is closed over the six standards plus `coined`, and `coined` is **forbidden in the core**, which is FR-5's "each term records which standard it derives from" made mechanical rather than editorial. (2) **`endpoint_kinds` is re-keyed from the three id prefixes to §5.2's seven `Kind` values** — feature-003's Open Item 12, routed here and closed here: `"kb:->kb:"` cannot distinguish a document *defining* a concept from a section *mentioning* one, and a standards-first vocabulary carries relations whose legal endpoints the prefix form cannot state. The token space grows from 9 to 49, so the SPEC states the migration (expand-then-narrow) and adds a **sixth cross-entry property, pair coherence**, plus a four-layer answer to how a declared endpoint set is checked for satisfiability — because expressiveness bought at the cost of undetectable over-declaration would be a worse defect than the one it fixes. (3) **The vocabulary is core plus project extension** (FR-4, FR-4a), consuming feature-003 D4's already-fixed location, format and precedence rather than restating them. (4) **The category set is a stated research finding: fourteen**, each with a one-line meaning, with the legibility consequence of exceeding AC-8a's eight-colour bound stated and the eight recommended colour holders derived from FR-13's four lenses. (5) **The vocabulary content is specified** — 31 pairs / 57 entries across the 14 categories, each with its standard, endpoints, passes and definition — while authoring `relation-vocabulary.yml` remains execution work and no file is edited here. (6) **The relation-mapping half of feature-004's Open Item 4 is discharged**: `image-reference` maps to the `illustrated-by` / `illustrates` pair, whose direction, `endpoint_kinds` and `passes` legality are stated; that item's unrelated second half — the coverage-note `present` predicate — is relayed to feature-005 unchanged and not adopted. Reused unchanged: the restricted-YAML carrier and its verbatim-copy render analysis (P1–P4), the five inverse-pair properties, `relation` as the identifying key, and the one-loader rule. Stale claims struck: "closed vocabulary", the eight-column worked-example shape, prefix-keyed endpoints, and harvest-as-basis. Thirteen Open Items: **four to feature-003** (the loader changes this revision forces), **two to feature-005**, one each to features 002, 006, 010 and 013, one to features 007/008/009 jointly, one to the PLAN.md amendment pass, and one **coverage limit of the standards themselves** — their agent half has no expressible endpoint under §5.2's `Kind` enum — recorded and routed to the work owner rather than hidden | /aid-specify |
| 2026-07-29 | **Citation-semantics round: six A+ gate findings (1 HIGH, 2 MEDIUM, 2 LOW, 1 MINOR) closed, all six instances of one defect class — a cited property that exists but does not mean what the entry uses it for.** Treated as a class sweep rather than six spot fixes, which is why the round changes **eight** tokens and not six. (1) **HIGH — `cites-as-evidence` no longer co-attributes `cito:citesAsAuthority`.** Authority is backing by standing, evidence is a checkable claim, so the co-attribution let a row pointing at an authoritative reference work satisfy `derived_from` while contradicting `definition`. The entry now cites `cito:citesAsEvidence` alone; the authority sense is **merged into the generic `cites`**, recorded as D6b's fourth merge row with the rejected alternative (a 32nd `cites-as-authority` pair) argued on the screen's own unreliable-choice test. (2) **MEDIUM — D1's scope columns are now closed under citation, as a stated rule with an AC behind it.** `cito:citesForInformation` was cited by `mentions` and missing from the CiTO row; the sweep compared all **64** token occurrences across the 31 pairs against all six columns and found no second gap. AC-S2 now checks the closure. (3) **MEDIUM — the extension failure-mode list is eight, not seven**: an extension re-declaring a **core category name** is caught by the loader's `categories:` name uniqueness and by none of the six properties, which D7 rule 3 already implied; the list also now separates which rows are merge-*induced* from which fail an extension standing alone. (4) **LOW — `skos:definition` is flagged as an acknowledged analogy** (**S16** declares it an `owl:AnnotationProperty` carrying a literal), in the same idiom D6a uses for `lockstep-with` — **and so is `skos:example`**, which the same condition declares and which was not reported. (5) **LOW — `iana:icon` dropped** from `illustrated-by`: an icon represents a link's *context* and need not depict a subject, and it is the artifact feature-004 uses as its own contrasting case. (6) **MINOR — the `skos:broader` direction is resolved in the data**, by citing `skos:narrower` alongside it. **New section D6d — the citation audit**: fifteen flagged token occurrences with the standard's own wording and the treatment, four classes of flag (direction, argument, neutrality, value type), the eight token changes with their provenance, and the note that a dropped token stays in D1's scope column by design. **Four further defects found by the sweep and not by the gate**: `cito:citesAsEvidence` dropped from `tests` (a test *confirms* a specification, it does not cite it as evidence for its own claims), `iana:collection` → `iana:item` in `has-member`, `iana:version-history` → `iana:predecessor-version` in `revision-of`, and `schema:predecessorOf` → `iana:prev` in `precedes` (a GoodRelations product term that D1's own schema.org exclusion already forbade). D1's PROV row is restated because `wasGeneratedBy` and `used` are **not** entity-to-entity, and D2 gains the direction-audit pointer plus the one-time class-conformance statement. Unchanged, and deliberately so: the 14 categories, `annotates`, the four-layer W1–W4 satisfiability split, the `endpoint_kinds` re-key, the eight-key entry schema, and 31 pairs / 57 entries | /aid-specify |

## Source

- REQUIREMENTS.md §5.4 — **FR-4** (*amended* — a generic core plus validated project extensions, not a closed
  set), **FR-4a** (*new* — the extension is a separate file; add-only; a collision is a hard failure),
  **FR-5** (*amended* — **standards-first** derivation from SKOS, Dublin Core (DCMI Terms), PROV-O,
  schema.org, IANA link relations (RFC 8288) and CiTO; comprehensiveness preferred over brevity; each term
  records which standard it derives from; verified expressible against a real repository but **not** limited
  to it), **FR-6** (categories are a grouping dimension), **FR-6a** (*new* — filtering and highlighting by
  category is a required feature), **FR-6b** (*new* — category governance: the core set is closed, its size
  is a research finding this SPEC must state, every relation is in exactly one category, and the palette
  does not grow with the count)
- REQUIREMENTS.md §5.2 — the **ten**-column table the relation names land in, and the **`Kind` closed enum**
  (`document`, `concept`, `fact`, `section`, `source-artifact`, `image`, `web-page`) that `endpoint_kinds` is
  now keyed on
- REQUIREMENTS.md §5.3 — the per-kind id grammars, and the fact that a `concept` id is deliberately not
  document-scoped (which is why concept-to-concept relations are the vocabulary's densest family)
- REQUIREMENTS.md §5.1 — the three relationship sources every worked example must cover
- REQUIREMENTS.md §5.5 — **FR-8a** (*new* — genericity: any project with an approved AID Knowledge Base; the
  skill may rely on KB **authoring conventions** and may not rely on this repository's content; absent
  conventions degrade gracefully into FR-9a's coverage notes), **FR-11 input 5** (the relation vocabulary
  **core *and* extension** are the fifth staleness input)
- REQUIREMENTS.md §5.8 — **FR-30** (Pass 1 emits `declared` / `derived`), **FR-31** (Pass 2 emits
  `inferred`), **FR-31a** (Pass 2 may create edges, never nodes — so an `inferred` relation may join any
  pair of already-existing nodes), **FR-32** (byte-identity over the deterministic majority)
- REQUIREMENTS.md §6 — NFR-5 (colour is never the sole carrier; relationship category is carried by colour
  **and line style**, four styles), consumed as the constraint on the category count
- REQUIREMENTS.md §8 — **D-1** (implementation depends on this research completing; scope enlarged
  2026-07-29 to a standards traversal plus per-term attribution)
- REQUIREMENTS.md §9 — **AC-2** (*amended* — valid inverse pair from the **merged** core-plus-extension set;
  feature-003 validates it), **AC-8a** part 3 (at most **eight** distinct category colours), **AC-19** (the
  genericity criterion whose zero-node outcomes this vocabulary must survive)
- REQUIREMENTS.md §10 — deliverable 1; the vocabulary half remains a true prerequisite and still runs first
- **feature-003's SPEC (A+ and FIXED, 2026-07-29)** — treated as an **immutable input**. It owns the loader
  and validation contract, and this SPEC consumes rather than restates: D1/D1a (the ten columns, the `Kind`
  enum and its permitted-prefix sets, `image_extensions:`), D2/D2a-1/D2a-2/D2a-3 (the per-kind id grammars
  and the slug, anchor-token and concept-normalisation algorithms), D4 (the two-file core/extension
  location, the identical format, the union-with-hard-fail precedence, the restricted-YAML parse contract),
  D5 (display names), D7 (row order), D9 (`rel_load_schema`, `rel_load_vocabulary`), and V3/V4/V12. Its
  **Open Item 12** routes the `endpoint_kinds` re-key here, and this SPEC closes it
- **feature-004's SPEC (re-specified 2026-07-29, gate pending)** — treated as an **input**. It owns which
  `source-artifact`, `image` and `web-page` nodes exist. Its **Open Item 4** routes the `image-reference`
  relation mapping here in part; its D7 `present`-iff-≥1 coverage predicate is noted where it touches this
  feature and relayed, not adopted
- STATE.md `## Cross-phase Q&A` — **Q10** (the vocabulary must be generic and standards-grounded; the widened
  node model is the root cause of the undersized vocabulary), **Q11** (directed, colour-coded edges; the
  ~8-colour and ~4-line-style design ceiling), **Q12** (asymmetric granularity), **Q13** (fact and concept
  definitions; the concept merge rule), **Q14** (the ten-column table; the `Kind` enum), **Q15** (the
  extension file's location, format and precedence — settled by feature-003 and consumed here)

**Genericity posture, stated once because it constrains every entry below (FR-8a).** No relation type,
category, endpoint pair or `passes` value below is defined by what this repository contains. Every entry is
derived from a **published standard**, and its expressibility is then *checked* against this repository.
Where this SPEC cites a path under this repository, it is to show that an entry **can be instanced** on real
content — never to decide whether the entry exists. **An entry this repository cannot instance is kept**, and
§ Feature Flow step 6 states that rule as a hard rule rather than a preference. That inversion is the whole
correction: the superseded research recorded decisions of the form "keep `["int:->int:"]` only — the only
harvested instance is script→data file", which is fitting a shipped artifact to one repository's observed
instances, and it is the reason whole families of relation were absent.

**Dependency position.** This is one of the two RESEARCH features that block implementation. It blocks
feature-003 (whose loader validates against the vocabulary, and whose entry contract this SPEC changes in two
places), feature-005 (whose deterministic scan cannot type a row without it), feature-006 (whose
`coverage_bearing` subset is drawn from these categories) and features 007/008/009 (which group, colour and
label by category). It does **not** block feature-004, which is enumeration and needs no relation types —
though feature-004 blocks *nothing* here either: this SPEC reads feature-004's node kinds and observation
kinds as an input, not as a prerequisite artifact.

## Description

This is a **RESEARCH feature. Its output is a decision, not shipped code** — a written, machine-loadable
vocabulary specification that later features bind to.

Relationships recorded in `relationships.md` must not be free text. Both directions of every relationship —
read source-to-target and read target-to-source — are drawn from a named set of relation/inverse pairs, so
that a machine can check a row and a reader sees consistent language across the whole table. Nuance that no
pair captures belongs in the row's free-text observation field, never in the relation columns.

The set is **generic and shipped as a core, which a project may extend but never rewrite**. It is not closed,
because no fixed set fits every project; but it is not open either, because an extension that redefined a
shipped meaning would make two projects using the same relation name mean different things. So a project may
add pairs and add categories, and an attempt to redefine or remove a shipped pair fails the run outright.

The core is derived from **published standards for relating things**, not from this project's own habits. Six
standards are traversed — a thesaurus standard for how concepts relate to concepts, a metadata standard for
how documents relate to documents, a provenance standard for how a thing relates to what it came from, a web
vocabulary for how a page relates to what it is about and what illustrates it, the web's registry of link
relation types, and a citation ontology for how one claim relates to the evidence for it. Every relation type
records **which of those standards it comes from**, and that record is a required field, not a footnote: a
core type with no standard behind it is a defect the loader rejects, which is what stops the vocabulary
drifting back into a set of locally-invented names.

A large vocabulary is wanted and expected. Comprehensiveness is preferred over brevity, because a vocabulary
too small to name a real relationship forces contributors back into free text — and because the vocabulary's
size is what lets a project with no glossary, no citation convention or no external sources simply produce
*fewer rows* instead of producing rows nobody can type. Absence has to show up as an empty result, never as
an unnameable edge.

Every relation type also declares **which kinds of thing it may join**. That declaration used to be made in
terms of the three broad families an identifier can belong to, which was too coarse to be useful once the
model grew to seven kinds of node: it could not tell a document that *defines* a concept from a section that
merely *mentions* one. It is now made in terms of those seven kinds directly. That is a large gain in
precision and a matching increase in the number of ways to be wrong, so the specification also says how a
declaration is checked — what a machine can decide from the vocabulary file alone, what it can only decide by
looking at what actually produces rows, and why the second kind of check reports rather than blocks.

Finally, every relation type belongs to exactly one category, and those categories become a grouping and
filtering dimension for the graph view. The number of categories the standards traversal yields is itself a
finding, and it is larger than any colour palette can carry — which is stated here plainly, together with
what the view must therefore do about it.

## User Stories

- As a **maintainer/architect**, I want every relationship in the table to be named from one agreed set of
  terms, so that I can read the whole table without guessing whether two differently-worded rows mean the
  same thing.
- As an **AI agent**, I want the relation types to be a machine-readable set with known inverses, so that I
  can route over `relationships.md` mechanically instead of interpreting prose.
- As a **maintainer/architect**, I want relation types grouped into categories, so that I can collapse the
  graph to a category level and see structure rather than a hairball.
- As a **maintainer/architect adopting AID on another project**, I want the shipped relation types to come
  from published standards rather than from the habits of the project that wrote the tool, so that the names
  mean what a newcomer to my project would already expect them to mean.
- As a **KB reviewer**, I want each relation type to record the standard it derives from, so that I can
  challenge a definition against its source instead of against an opinion.
- As a **maintainer/architect adopting AID on another project**, I want to add my own relationship types
  without my additions being overwritten on upgrade and without silently colliding with the shipped ones, so
  that extending the vocabulary is safe.
- As an **AI agent**, I want each relation type to state which kinds of node it may join — a document, a
  section, a claim, a concept, an artifact, an image, a web page — so that I can tell a definition from a
  mention without reading the two documents.
- As a **maintainer/architect**, I want a relation type's declared endpoints to be checked rather than
  trusted, so that a declaration nothing produces is visible to me instead of sitting in the file looking
  authoritative.
- As a **maintainer/architect on a project with no glossary and no citation convention**, I want the
  vocabulary to be larger than my project needs, so that my thin graph tells me my Knowledge Base is thin
  rather than telling me the tool could not name what it found.

## Priority

Must

## Acceptance Criteria

Completion criteria for the research. This feature ships a decision, so its criteria are deliverables and
checkable properties of them rather than runtime behaviour. They are **SPEC-authored** — no requirement
states them, so they carry no requirement number — and they use the `AC-S<n>` scheme feature-003 introduced
and offered to its siblings, which feature-004 has since adopted. AC-2 is the one requirement-originated
criterion this feature is answerable for, and it is stated last because feature-003 is what decides it.

- [ ] AC-S1: Given the delivered core vocabulary, when it is **loaded** rather than read, then the five
      inverse-pair properties hold over it — closure, totality, involution, symmetric consistency, category
      totality — with every entry carrying all **eight** keys.
- [ ] AC-S2: Given the delivered core vocabulary, when every entry's `derived_from` is inspected, then each
      carries at least one token naming one of the six standards FR-5 names, every token matches the closed
      grammar, and the token `coined` appears in **no** core entry; **and** every token appears in D1's
      in-scope column for its own standard, and is either classed in **D6d**'s audit or runs source → target
      as its entry's `definition` reads it — so no citation can enter the file without its meaning and its
      direction being on the record.
- [ ] AC-S3: Given the delivered core vocabulary, when its `categories:` block is read, then the category
      count equals the count this SPEC states, each category carries a one-line meaning, every entry's
      `category` is a declared name, and **no declared category is empty** — so the stated count is the
      count of categories that actually classify something.
- [ ] AC-S4: Given the delivered core vocabulary, when every `endpoint_kinds` token is inspected, then each
      is `<kind>-><kind>` with both sides members of §5.2's seven-value `Kind` enum **as read from
      `relationship-schema.yml`**, and no token names an id prefix.
- [ ] AC-S5: Given the delivered core vocabulary, when the sixth property — **pair coherence** — is checked,
      then for every asymmetric pair the two entries agree on `category`, `derived_from` and `passes` and
      their `endpoint_kinds` sets are exact transposes of each other; and for every symmetric entry the
      `endpoint_kinds` set is closed under transposition.
- [ ] AC-S6: Given the delivered core vocabulary, when sufficiency is demonstrated, then a worked
      `relationships.md` row in the **ten**-column shape of §5.2 is shown for each of §5.1's three
      relationship sources — KB-to-KB, KB-to-source, KB-to-external — plus one for the `image-reference`
      mapping feature-004 routed here, each using only vocabulary terms in both relation columns and putting
      nothing but free-text nuance in `Observation`.
- [ ] AC-S7: Given the delivered core vocabulary, when every entry's `passes` is read, then each is a
      non-empty subset of `declared` / `derived` / `inferred`, and the union across the vocabulary contains
      all three — so feature-005 knows for every type which of its two passes may emit it, and neither pass
      is left with nothing it is permitted to produce.
- [ ] AC-S8: Given the delivered core vocabulary, when it is checked for genericity, then no entry's
      `definition`, `endpoint_kinds` or `passes` names a file path, a filename, a repository, or a
      convention token specific to this project, and the vocabulary loads and passes all six properties with
      no Knowledge Base present at all.
- [ ] AC-S9: Given the delivered core plus a fixture extension, when the merged set is loaded, then an
      extension that only **adds** loads cleanly; and an extension that collides on a `relation` name,
      collides on a `categories:` name, names an inverse it does not define, redefines a core pair, supplies a
      non-transposed `endpoint_kinds` set across an asymmetric pair, or declares a **symmetric** entry whose
      `endpoint_kinds` is not closed under transposition each fails the load — each proven by its own fixture.
      The last fixture is load-bearing rather than completionist: the shipped core satisfies that clause
      vacuously (D4), so nothing else exercises it.
- [ ] AC-S10: Given the delivered core vocabulary, when the **endpoint-satisfiability report** is produced,
      then it lists every entry's declared tokens, each marked with whether some named producer can emit it,
      and the report is a report — it records findings and does not fail the load.
- [ ] AC-S11: Given the delivered core vocabulary, when a reviewer greps the shipped `graph/` script tree
      for any relation label, category name or standard key from this vocabulary, then nothing is found —
      the vocabulary is opaque data to every consumer, and all consumers read it through one loader.
- [ ] AC-2: Given the delivered vocabulary, when feature-003 validates a row's two relation columns against
      the **merged** core-plus-extension set, then AC-2 (both values are members; the pair is a valid
      inverse pair; no row's two directions disagree, a symmetric row being valid rather than a
      disagreement) is decidable without human judgment.

---

## Technical Specification

> The amended REQUIREMENTS.md (2026-07-29) is the authority for everything below, and feature-003's fixed
> SPEC is the authority for how the vocabulary is loaded and validated. Where the two touch, this SPEC
> defines the vocabulary's **content and schema**; feature-003 defines its **loading and validation**;
> feature-004 defines **which non-KB nodes exist**. Disagreement with either is recorded as an Open Item
> naming the owner, never as a silent divergence, and neither feature's contract is restated here as though
> this feature owned it.

### Data Model

**There is no database, no schema, and no migration.** This feature ships a decision: a written,
machine-loadable vocabulary that later features bind to. What follows specifies the *shape and the content of
that research output*, in the place of the table-and-column model a runtime feature would carry here.

**How to read the "which requirement, checked how" claims.** Every contract below names the requirement it
satisfies and the mechanism that decides it. That pairing is deliberate, and it is the direct lesson of this
work's two recorded failures (Q9, Q10): a document that was complete, traceable and internally consistent
while answering the wrong question, and a vocabulary that satisfied every stated rule while being unable to
name most of what the graph contains. A contract with no mechanism behind it is treated here as undelivered,
and a *content* claim with no standard or verified file behind it is treated as unsupported.

#### D1. The standards basis (FR-5)

The six standards FR-5 names, with the exact version each term below is drawn from. Every URL was fetched and
the version string read from the document itself on **2026-07-29**; nothing here is quoted from memory.

| Key | Standard | Version / status read from the document | Source URL (accessed 2026-07-29) |
|-----|----------|------------------------------------------|-----------------------------------|
| `skos` | SKOS Simple Knowledge Organization System Reference | W3C Recommendation **18 August 2009** | `https://www.w3.org/TR/skos-reference/` |
| `dcterms` | DCMI Metadata Terms | DCMI Recommendation, Date Issued **2020-01-20** | `https://www.dublincore.org/specifications/dublin-core/dcmi-terms/` |
| `prov` | PROV-O: The PROV Ontology | W3C Recommendation **30 April 2013** | `https://www.w3.org/TR/prov-o/` |
| `schema` | Schema.org vocabulary | Version **30.0**, released **2026-03-19** (the current published release; term pages footer `V30.0 \| 2026-03-19`) | `https://schema.org/`, term pages, and `https://schema.org/version/latest/schemaorg-current-https-properties.csv` |
| `iana` | IANA **Link Relation Types** registry, whose registration procedure is defined by **RFC 8288 "Web Linking"** (IETF Standards Track, **October 2017**, obsoletes RFC 5988) | Registry created 2005-08-26, **Last Updated 2026-06-12** | `https://www.iana.org/assignments/link-relations/link-relations.xhtml`, `https://www.rfc-editor.org/rfc/rfc8288.txt` |
| `cito` | CiTO, the Citation Typing Ontology | Revision **2.8.2**, Modified on **2026-06-22** (`http://purl.org/spar/cito/2026-06-22`) | `https://sparontologies.github.io/cito/current/cito.html` |

**What was taken from each, and what was not.** Recorded because a traversal that says only "derived from six
standards" is unfalsifiable:

| Key | Terms the traversal recorded as in scope for edge typing | What it deliberately leaves | Why |
|-----|----------------------------|------------------------------|-----|
| `skos` | The semantic relations between concepts — `skos:broader` / `skos:narrower` (declared inverses at integrity condition **S25**), `skos:related` (declared **symmetric** at **S23**), the mapping properties `skos:exactMatch` / `skos:closeMatch` (both **symmetric**, **S44**; `exactMatch` also transitive, **S45**, and disjoint from `broadMatch` and `relatedMatch`, **S46**), `skos:member` (**S30–S32**), and the documentation properties `skos:definition` and `skos:example` — which **S16** declares are each instances of `owl:AnnotationProperty`, conventionally carrying a **literal**, so both are cited as acknowledged analogies rather than as object properties between two nodes (D6a, audited at D6d) | The transitive twins `broaderTransitive` / `narrowerTransitive` (**S26**), the concept-scheme properties, `skos:notation`, and all of SKOS-XL | The transitive twins are, by SKOS's own convention (§8.3), "not used to make assertions" but to infer closure — and `relationships.md` records asserted edges, not inferred closure. Scheme and label machinery has no node kind to attach to |
| `dcterms` | The six declared inverse pairs — `hasPart`/`isPartOf`, `hasVersion`/`isVersionOf`, `replaces`/`isReplacedBy`, `requires`/`isRequiredBy`, `references`/`isReferencedBy`, `hasFormat`/`isFormatOf` (each stated in the term's own description as "an inverse property of …", all twelve statements verified) — plus `dcterms:source`, `dcterms:relation` and `dcterms:conformsTo` | Every literal-valued descriptive term (`title`, `abstract`, `created`, `extent`, `medium`, …) and the agent terms (`creator`, `contributor`, `publisher`, `rightsHolder`) | This vocabulary types **edges between two nodes**. A literal-valued property has no second node, and an agent-valued one has no node **kind** to land on — see the coverage limit at D8 |
| `prov` | The **entity-to-entity** properties — `wasDerivedFrom`, its three sub-properties `wasQuotedFrom`, `wasRevisionOf` and `hadPrimarySource`, plus `hadMember`, `specializationOf` and `alternateOf` — and, kept separate because they are **not** entity-to-entity, the two activity-involving properties `wasGeneratedBy` (`prov:Entity` → `prov:Activity`) and `used` (`prov:Activity` → `prov:Entity`), whose qualification table states those domains and ranges verbatim and which are therefore cited as acknowledged analogies, never as node-to-node properties (D6a, audited at D6d); and the reserved inverse names from the normative **Table 5, "Names of inverses"** (`hadDerivation`, `quotedAs`, `hadRevision`, `wasPrimarySourceOf`, `generated`, `wasUsedBy`, `wasMemberOf`, `generalizationOf`, and — for `alternateOf` — **`alternateOf` itself**, which is where its symmetry is verified rather than assumed) | The Agent class and every property whose domain or range is an agent (`wasAssociatedWith`, `wasAttributedTo`, `actedOnBehalfOf`, …), the activity-to-activity and lifetime properties (`wasInformedBy`, `wasStartedBy`, `wasEndedBy`, `wasInvalidatedBy`), and the whole qualified-influence pattern | Same reason: no `Kind` value denotes an activity or an agent, so those properties have **no expressible endpoints**. Recorded at D8 as a stated coverage limit of this vocabulary, and routed as an Open Item, rather than left looking like an oversight. The two retained activity-involving properties are the boundary case: each has *one* entity argument, so the relation they name is expressible only with the activity **elided to the artifact that embodies it**, which is exactly what D6d records rather than letting the citation read as a direct adoption |
| `schema` | `about`/`subjectOf`, `hasPart`/`isPartOf`, `exampleOfWork`/`workExample`, `encoding`/`encodesCreativeWork`, `mainEntity`/`mainEntityOfPage` — all five verified as **declared `inverseOf` pairs** by reading the `inverseOf` column of the published properties CSV — plus `image`, `citation`, `isBasedOn`, `sameAs` and `inDefinedTermSet`/`hasDefinedTerm`, which the same CSV shows carry **no** declared inverse | The entire commercial, event, place, person, action and medical vocabulary — **including `predecessorOf`/`successorOf`**, which the term pages credit to the **GoodRelations e-commerce** vocabulary and define over a product variant ("a pointer from a previous, often discontinued variant of the product to its newer variant", accessed 2026-07-29) | Out of domain. Nothing in `relationships.md` denotes a product, an offer, a place or an action. `predecessorOf` is moved into this column by the 2026-07-29 review round: `precedes` had cited it for **section and document** ordering, which the exclusion this cell states already forbade — the registry's `next`/`prev` pair says the same thing without the product domain (D6d) |
| `iana` | `describes`/`describedby` (the registry's own note states "This link relation type is the inverse of the 'describedby' relation type"), `up`, `item`/`collection`, `next`/`prev`, `first`/`last`, `predecessor-version`/`successor-version`, `latest-version`, `version-history`, `working-copy`/`working-copy-of`, `alternate`, `related`, `via`, `canonical`, `icon`, `about`, `type`, `profile`, `glossary`, `deprecation` and `sunset` | Protocol and transport relations (`restconf`, `service-doc`, `payment`, `search`, `geofeed`, `memento`/`timegate`/`original`, …) | They relate a resource to a *service*, not to a documented artifact. The registry is used as an attestation that a relation type is a recognised web relation, never as a transport contract |
| `cito` | The citation-typing half — `cites`/`isCitedBy` and the sub-properties this vocabulary needs, each with the inverse CiTO itself defines: `citesAsEvidence`/`isCitedAsEvidenceBy`, `citesAsAuthority`/`isCitedAsAuthorityBy`, `citesForInformation`/`isCitedForInformationBy`, `documents`/`isDocumentedBy`, `describes`/`isDescribedBy`, `supports`/`isSupportedBy`, `confirms`/`isConfirmedBy`, `disagreesWith`/`isDisagreedWithBy`, `refutes`/`isRefutedBy`, `agreesWith`/`isAgreedWithBy`, `updates`/`isUpdatedBy`, `extends`/`isExtendedBy`, `corrects`/`isCorrectedBy`, `qualifies`/`isQualifiedBy`, `discusses`/`isDiscussedBy`, `usesMethodIn`/`providesMethodFor`, `usesDataFrom`/`providesDataFor` | The rhetorical-stance properties with no analogue in a code repository (`derides`, `ridicules`, `parodies`, `plagiarizes`, `likes`, `critiques`, `speculatesOn`) and the whole author-network family (`sharesAuthorsWith`, `sharesAuthorInstitutionWith`, `sharesFundingAgencyWith`, `sharesJournalWith`) | The stance properties are about scholarly polemic; the author-network family needs an agent, which again has no `Kind`. CiTO's own overview records that `cites` has forty-one sub-properties, so selectivity here is mandatory, not optional |

**In scope is not the same as cited, and the difference is deliberate.** The middle column above lists what
the traversal recorded as usable for typing an edge between two nodes; D6's `derived_from` values record the
subset an admitted relation actually cites. A term that appears above and in no D6 entry is one the traversal
considered and no admitted relation needed — either because another term expressed the same assertion more
precisely (D6b records the four candidates merged away on exactly that ground) or because the relation it
would have typed has no expressible endpoint over §5.2's kinds (D8). Recording the wider set is what makes the
traversal falsifiable: a reader can check that a term was seen and set aside rather than missed.

**The converse closure is a *rule*, not a habit — because its absence was a real defect.** Every token that
appears in any D6 `derived_from` **must** appear in the middle column above; **AC-S2** checks that closure over
the delivered file. The 2026-07-29 review round found exactly one violation: `cito:citesForInformation`, cited
by `mentions`, was missing from the CiTO row, so the one column presented as making the traversal falsifiable
could not be used to check the one relation that depended on it. The sweep that followed compared **all 64
token occurrences** across D6's 31 pairs against all six middle columns and found **no second instance** — the
CiTO row was the only gap, and the other five standards' rows were already closed. The rule matters more than
the fix: a middle column that silently omits a cited term is indistinguishable from one that never saw it.

**Why the six are enough between them, and where they overlap.** The six were chosen by FR-5, not by this
research, but the traversal confirms they are complementary rather than redundant: SKOS is the only one that
relates *concepts* to concepts, CiTO the only one that types the *reason* for a citation, PROV the only one
with a derivation calculus, DCMI the only one with a clean set of declared document-to-document inverses,
schema.org the only one covering depiction, and the IANA registry the only one that is a *registry* — an
attestation that a relation type is in recognised use on the web rather than a single body's model. Where two
standards attest the same relation (part–whole is in both DCMI and schema.org; supersession is in DCMI, IANA
and PROV), `derived_from` records **both**, because multiple attestation is the strongest available evidence
that a relation is generic rather than local, and hiding it would discard that evidence. **With one
qualification the 2026-07-29 round had to add:** multiple attestation is only evidence where every attestation
attests the **same** assertion. Two tokens on one entry, one of which means something the `definition` does not
say, is weaker than one exact token — it is a claim the entry cannot honour. Three entries lost a co-attribution
on exactly that ground (D6d), and one exact token is now the delivered value for each of them.

#### D2. The vocabulary record — **eight** fields (was seven)

The delivered vocabulary is a set of records, one per relation type, each expressed as one YAML mapping entry
in the restricted subset feature-003 D4 fixes. All eight keys are required in a fixed order; an absent or
empty value is a defect and exits 2.

| # | Key | Meaning | Value rule |
|---|-----|---------|-----------|
| 1 | `relation` | The relation name read Source → Target — the value that may appear in a `relationships.md` `S2T Relation` cell. | Lowercase, hyphen-separated, active-voice verb phrase (`documents`, `depends-on`), matching `[a-z][a-z0-9-]*`. **Unique** across the merged vocabulary; it is the entry's identifying key and always the entry's first key. |
| 2 | `inverse` | The name of the same relationship read Target → Source — the value that must appear in `T2S Relation` when `S2T Relation` holds `relation`. | Must itself be a `relation` value somewhere in the **merged** vocabulary (the set is closed under inversion). |
| 3 | `symmetry` | Whether the pair is directionless. | Closed enum: `asymmetric` \| `symmetric`. `symmetric` **iff** `inverse` equals `relation`. |
| 4 | `category` | The single grouping bucket this type belongs to (FR-6, FR-6b). | Exactly one value, drawn from the **merged** `categories:` set. Never blank, never multi-valued. |
| 5 | `derived_from` | **New 2026-07-29 (FR-5).** Which standard, or standards, this relation type derives from. | Non-empty one-line flow sequence of double-quoted tokens. Each token matches `(skos\|dcterms\|prov\|schema\|iana\|cito):[A-Za-z][A-Za-z0-9-]*` — the closed standard-key set of D1 followed by the standard's own local term name, verbatim including case — **or** is exactly `coined`. `coined` may not appear in a **core** entry, and may not appear alongside a standard token in any entry. |
| 6 | `endpoint_kinds` | **Re-keyed 2026-07-29 (D3).** Which ordered pairs of node **kinds** (§5.2) this relation may legally join when it appears as `S2T Relation`. | Non-empty one-line flow sequence of double-quoted `<kind>-><kind>` tokens, each side a member of §5.2's seven-value `Kind` enum. |
| 7 | `passes` | Which extraction passes (§5.8) may emit this type. | Non-empty one-line flow sequence; a subset of `declared`, `derived`, `inferred` — the same three values `Provenance` uses (§5.2, feature-003 D3). |
| 8 | `definition` | What the relation asserts, in one sentence, precise enough that two authors pick the same type for the same fact. | One sentence, on one line, double-quoted. |

**`relation` remains the identifying key**, unchanged: feature-005 D3's `edge-relation-map.yml` names
vocabulary pairs "by their `s2t` label" and looks `t2s` up as that entry's inverse, so `relation` is the join
column the rest of the work already references and `inverse` is reached through it rather than being
separately addressable.

**`derived_from` sits at position 5, and the position is fixed rather than convenient.** It is placed after
`category` because positions 1–5 are then the entry's *classification* fields and 6–8 its *applicability and
prose* fields, and because `definition` reads best last. Appending it after `definition` was the alternative
and is rejected: feature-003's loader validates key **order**, so a machine field after the one prose field
would be the only place in the file where prose is not terminal, and every future added key would face the
same arbitrary choice with no rule to appeal to. The rule stated here is: **new keys are inserted before
`endpoint_kinds`, never after `definition`.**

**`derived_from` is a *pair-level* attribution, and that has one consequence worth stating.** Property 6
requires both halves of a pair to carry the same set, because a relation and its inverse are one relationship
described twice — so a cited term may name **either** reading of the relationship, not necessarily the `S2T`
one. `supersedes` citing `iana:successor-version` is correct even though that registered relation points from
the older resource to the newer: the token attributes the *relationship*, and which of its two names a
standard happened to register is an accident of that standard's perspective. Stated because a reader checking
tokens against their sources will hit this on the first version-related entry.

**But a principle stated once and applied silently is indistinguishable from a mistake, so the direction of
every token is audited individually at D6d.** The 2026-07-29 review round was opened by exactly this failure:
`broader-than` cited `skos:broader` alone, and in SKOS the *subject* of `skos:broader` is the **narrower**
concept (S25 declares `skos:narrower` its inverse), so the vocabulary's most-checked taxonomy entry attributed
the reading opposite to the one its own `definition` states — correct under the paragraph above, and
indefensible without it being said. The remedy is two-part and both parts are load-bearing: where the standard
declares an inverse **name** for the term, the entry now cites **both halves** (`skos:broader` *and*
`skos:narrower`; `iana:next` *and* `iana:prev`), so the pair-level attribution is visible in the data rather
than only in this paragraph; and where no same-direction term is available to cite — because the standard
registers none (`iana:up`, `iana:canonical`), because it reserves the inverse only as a *name* and declares no
property (`prov:specializationOf`), or because the term that would run source → target belongs to a different
entry and citing it here would misattribute (`iana:successor-version`, whose counterpart is `revision-of`'s
token) — the entry keeps the inverted token and **D6d names it, quotes the source, and says which of the pair's
two readings it matches**. Those are the **four unpaired inversions** in the delivered core, three of them
IANA's. A reader should never have to infer that an inversion was intended.

**One class-conformance point, stated once here so D6d does not repeat it 64 times.** No AID node is an
instance of any class these six standards define: an AID `concept` is not an RDF `skos:Concept`, a `document`
is not a `schema:CreativeWork`. Every token therefore attributes the **relationship** a standard defines, never
a claim that the endpoints conform to that standard's classes — which is why `skos:member` may be cited by an
entry whose endpoints are documents. What that general point does **not** cover, and what D6d flags
individually, are the two cases where the standard's *other argument* is not a node of any kind at all: a
**literal** (an `owl:AnnotationProperty`), or a **`prov:Activity`**, the one class §5.2 deliberately cannot
denote (D8).

**What `derived_from` is for, stated honestly.** No runtime consumer interprets it. It exists for two
reasons, one editorial and one mechanical. Editorially it is the audit trail FR-5 requires, so a reviewer can
challenge a definition against its source instead of against an opinion. Mechanically it is what makes
"standards-first" a **checkable property of the artifact** rather than a claim about how the artifact was
produced: because `coined` is forbidden in the core, a core entry with no standard behind it cannot load. That
is the single most important structural difference between this vocabulary and the one it replaces — the
superseded file could not have failed any check for the defect it actually had.

**When a genuinely necessary core relation has no antecedent in the six standards.** It is **not** given a
stretched citation and it is **not** given `coined`. It is raised as an **Open Item recording a coverage gap
in the standards**, and the owner decides whether to widen FR-5's standard list or accept the absence. This
research found no such case; it did find **two** entries whose derivation is a deliberate **narrowing** of a
broader standard term rather than a direct adoption, and both are flagged at **D6a** rather than being allowed
to read as direct adoptions. It also found **five token occurrences across five entries** whose cited property
is not an object property between two nodes of the kinds the entry declares — **two** citing an
`owl:AnnotationProperty` whose value is a literal, **three** citing a property whose other argument is a
`prov:Activity`. Those are neither narrowings nor adoptions but **acknowledged analogies**, and they carry the
same kind of explicit flag (D6a's fourth bullet, every occurrence audited at D6d).

#### D3. `endpoint_kinds`, re-keyed from prefixes to kinds — the blocking defect, and its closure

**The defect, as feature-003 routed it (its D4 and Open Item 12).** `endpoint_kinds` was keyed on the three id
prefixes `kb:` / `int:` / `ext:`. With seven node kinds, `"kb:->kb:"` cannot distinguish a document
*defining* a concept from a section *mentioning* one — so a standards-first vocabulary carries relations whose
legal endpoints the token form **cannot state**. feature-003 can be A+ with this open because its V12 is
advisory; feature-001 cannot, because the field is this feature's and an unstatable endpoint contract is a
defect in the vocabulary itself, not in its validator.

**The new token form.** A token is `<source-kind>-><target-kind>`, each side a member of §5.2's closed
`Kind` enum: `document`, `concept`, `fact`, `section`, `source-artifact`, `image`, `web-page`. The token space
therefore grows from 3 × 3 = **9** to 7 × 7 = **49**.

**One enum, one source.** The kinds are not restated in the vocabulary file. feature-003 D1a already carries
the enum as data in `relationship-schema.yml`'s `kinds:` list, and D9's `rel_load_schema` already loads it —
so the loader validates `endpoint_kinds` tokens against **that** list. This is why the re-key is cheap: it
replaces one value rule (`both <p> in prefixes:`) with another (`both <k> in kinds:`) over an enum the loader
already has in memory, and it removes the second copy of a closed set rather than adding one. Had the kinds
been listed in the vocabulary file, the two copies could drift, and drift between two closed vocabularies is
exactly the hazard §5.2's cross-consistency validator exists to prevent.

**The migration from the prefix-keyed form: expand, then narrow, and the narrowing is the work.** Stated as an
algorithm so a reviewer can check the delivered file against the superseded one:

1. **Expand.** Each prefix expands to the kinds §5.2 pins to it: `kb:` → {`document`, `concept`, `fact`,
   `section`}; `int:` → {`source-artifact`, `image`}; `ext:` → {`web-page`, `image`}. A prefix token
   `"<p>-><q>"` expands to the Cartesian product of the two expansions — so `"kb:->kb:"` becomes 16 tokens,
   `"int:->int:"` becomes 4, `"kb:->ext:"` becomes 8.
2. **Narrow.** Each expanded set is then reduced by hand to the tokens the entry's `definition` actually
   admits.
3. **Record.** The narrowing is not recoverable from the file, so the *reason* for each entry's endpoint set
   lives in D6's table and in the file's header comment, not in a comment beside the flow sequence (which
   feature-003's one-key-per-physical-line rule has no room for).

**Step 1 alone would be a regression dressed as a migration, and this is the point of stating the algorithm.**
Mechanical expansion of `"kb:->kb:"` declares all sixteen KB-to-KB kind pairs legal, which is *precisely* the
statement the prefix form was criticised for making implicitly. A migration that stopped at expansion would
therefore satisfy AC-S4 — every token well-formed, every kind in the enum — while preserving the defect in a
new notation. The narrowing in step 2 is the deliverable; the expansion is only how it starts.

**No wildcard, and the reason is the defect being fixed.** A `*` on either side of a token was considered — it
would shorten the longest sets — and is **rejected**. `"*->*"` declares nothing, so V12 becomes vacuous on
every entry that uses it, and an entry that declares nothing is under-expressive in exactly the way this
re-key exists to end. The cost of refusing it is bounded and was checked: the largest `endpoint_kinds` set in
D6 has eight tokens, which fits the one-physical-line rule comfortably, and feature-003's loader imposes no
line-length limit. A named-group mechanism (a third top-level key aliasing kind sets) was also considered and
rejected, because it adds a key to feature-003's two-key file contract to save keystrokes in a file with
57 entries authored once.

**Pair coherence — the sixth cross-entry property, and why 49 tokens make it necessary.** See D4 property 6.
It is stated as a new property rather than folded into the existing five because it is a genuinely new
obligation on the file, and hiding it inside "the five properties" would misrepresent what feature-003's
loader has to change.

##### D3a. How a declared endpoint set is checked for satisfiability

The expressiveness gained above cuts both ways, and this is the sharpest question the re-key raises: a
kind-keyed set is much easier to get **wrong in ways nothing detects**. Two failure modes, only one of which
was ever visible:

- **Under-declaration** — a token missing that a real row needs. This *is* detected: feature-003's V12 fires
  on a row whose kind pair the chosen relation does not list. Re-keyed, V12 becomes strictly more precise —
  it now catches a `document`-defines-`concept` row typed with a mention relation, which the prefix form
  could not see at all.
- **Over-declaration** — a token no producer could ever emit. This is detected by **nothing** in the current
  design, because V12 only fires on rows *outside* the declared set and a superfluous token never puts a row
  outside anything. Under 9 tokens this was a small surface; under 49 it is the dominant failure mode, and
  the entire answer below exists for it.

The answer is four layers, and the line between them is principled: **a check is a gate exactly when it is
decidable from the vocabulary files alone; it is a report exactly when it depends on a producer set or a
corpus.** Gating the second kind would forbid the comprehensiveness FR-5 requires, because a core vocabulary
is deliberately larger than any one project's producers and a project extension exists precisely to type what
the core producers do not.

| Layer | What it checks | Decidable from | Gate or report | Owner |
|-------|----------------|----------------|----------------|-------|
| **W1 — well-formedness** | every token is `<k>-><k>` with both sides in `relationship-schema.yml`'s `kinds:` | the two files | **gate** — exit 2 | feature-003 loader (Open Item 2) |
| **W2 — pair coherence** | the transposition and agreement clauses of D4 property 6 | the vocabulary file(s) alone | **gate** — exit 2 | feature-003 loader (Open Item 3) |
| **W3 — producer satisfiability** | for each declared token, whether **some** named producer can emit it | the vocabulary + feature-005's `edge-relation-map.yml` + feature-004's node kinds | **report** | feature-005 (Open Item 6) |
| **W4 — observed coverage** | per run, which declared tokens the produced table actually exercised, and which it did not | the vocabulary + a generated `relationships.md` | **report** | feature-003 (Open Item 4) |

**W2 is the strong file-local check, and it is new.** If entry `r` has inverse `r'`, then a row typed
`(S2T = r, T2S = r')` reads `source --r--> target` and `target --r'--> source`. So the legal endpoint set of
`r'` must be **exactly the transpose** of the legal endpoint set of `r`: `"a->b" ∈ endpoint_kinds(r)` if and
only if `"b->a" ∈ endpoint_kinds(r')`. For a symmetric entry (`relation == inverse`) this degenerates to a
non-trivial constraint on a single entry: the set must be **closed under transposition**, so a symmetric
relation declared only as `"source-artifact->image"` is rejected outright. This catches the single most
likely authoring error in a 49-token space — updating one half of a pair and forgetting the other — and it
costs one set comparison per pair at load time.

**Honest note on W2's novelty.** The property was statable on the prefix-keyed form too, and was not stated.
What the re-key changes is not whether it *can* be checked but whether it *must* be: at 9 tokens, both halves
of a pair typically carried one or two tokens each and a human reviewer could see a mismatch — the superseded
file happens to satisfy transposition on all eight of its pairs, verified by reading it. At 49 tokens with
sets of up to eight, a reviewer cannot, so the check moves from redundant to load-bearing.

**W3 is the real answer to "are these endpoints satisfiable", and it is a report by necessity.** Define:

> A token `"a->b"` on relation `r` is **satisfiable** iff at least one entry of feature-005's edge-relation
> map that resolves to `r` — or resolves to `r`'s inverse with the token transposed — can produce a source
> node of kind `a` and a target node of kind `b`, where the producible kinds are feature-004's two node
> streams for `source-artifact` / `image` / `web-page` and feature-005's Pass 1 output for `document` /
> `section` / `fact` / `concept`.

The report lists every entry's tokens, each marked `producer` (some map entry can emit it), `inferred-only`
(no deterministic producer, but the entry's `passes` includes `inferred`, so Pass 2 may legitimately create
it under FR-31a part 2), or `unreachable` (no producer and no `inferred` pass — the actionable case). An
`unreachable` token is a finding to fix in the vocabulary or the map; it is **not** a load failure, because a
core relation may be unreachable on one project and central on another, and because feature-005's map is
allowed to grow after the vocabulary ships. Making this a gate would mean a project could not ship a
comprehensive core until it also shipped a producer for every entry, which inverts FR-5.

**W4 is the empirical half, and it is cheap.** feature-003's validator already parses every row and already
computes each row's kind pair for V13. Accumulating the set of observed `(Source Kind, Target Kind)` pairs per
relation costs one set insert per row, and the difference against `endpoint_kinds` gives both directions at
once: rows outside the declared set (V12, unchanged in role, sharpened in precision) and declared tokens no
row exercised (new). Both are advisory for the reasons feature-003 already records — AC-2 is scoped to
membership and inverse consistency, not endpoints, and FR-25/FR-28 forbid `/aid-graph` gating on properties of
the Knowledge Base it is only permitted to observe.

**What this buys, stated plainly so the trade is visible.** Over-declaration goes from *undetectable* to
*reported by two independent mechanisms* — one that needs no corpus (W3) and one that needs no producer map
(W4) — while nothing new can fail a run. That is the whole of the answer: the re-key does not make wrongness
impossible, it makes wrongness **visible**, and it does so without buying visibility with a gate the
requirements do not have.

#### D4. The inverse-pair contract — five properties, plus a sixth

The `relation` → `inverse` map is an **involution** on the merged vocabulary: applying it twice returns the
original name. Properties 1–5 are unchanged from the previous revision and continue to bind **every** entry,
core and extension. Property 6 is added by this revision.

1. **Closure** — every `inverse` value is present as some entry's `relation` value.
2. **Totality** — every entry has all **eight** keys, each non-empty, in the fixed order of D2. *(The key
   count is what changed; the property did not.)*
3. **Involution** — for every entry, `inverse(inverse(relation)) == relation`.
4. **Symmetric consistency** — `symmetry` is `symmetric` exactly when `inverse == relation`, and
   `asymmetric` exactly when it does not. No third case.
5. **Category totality** — every entry carries exactly one `category`, and every `category` used appears in
   the merged `categories:` set with its one-line meaning.
6. **Pair coherence** *(new 2026-07-29)* — for every asymmetric pair `(r, r')`: `category`, `derived_from`
   and `passes` are **equal** across the two entries, and `endpoint_kinds(r')` is the exact **transpose** of
   `endpoint_kinds(r)`. For every symmetric entry: `endpoint_kinds` is **closed under transposition**.

**Why property 6's three agreement clauses are one property and not three.** They share a single ground: a
relation and its inverse are **one relationship described twice**, and a `relationships.md` row carries both
descriptions and exactly one `Provenance`. So a pair whose halves disagree on `category` would show one
direction under a category filter and hide the other (breaking FR-6a's filter semantics); a pair whose halves
disagree on `passes` would let a row be legal read one way and illegal read the other, with no way to decide
which reading the row's single provenance answers to; and a pair whose halves disagree on `derived_from` would
attribute one relationship to two different standards. `symmetry` needs no clause because property 4 already
forces it, and `definition` needs none because the two definitions are *different prose by design* — they
describe opposite readings.

**`definition` is the one field the executor must author twice.** Everything else in an inverse entry is
mechanically derivable from its partner under property 6, which is why D6's table carries one row per **pair**
rather than one per entry. The inverse's definition follows a stated pattern — swap the subject and object of
the partner's sentence and keep the same assertion — and § Feature Flow step 7 makes writing both halves in
one edit a rule, so a pair can never be half-added.

**Property 4 is the edge case a naive inverse-pair validator gets wrong**, and it is unchanged. **Symmetric
relations are the fixed points of the involution**, so a validator written as "assert `inverse != relation`"
rejects every legitimate symmetric type, and one written as "assert a row's two relation cells differ"
rejects every legitimate symmetric *row*. The rules are therefore explicit:

- A symmetric relation's entry has `relation == inverse` and `symmetry: symmetric`; `symmetry` makes the
  self-inverse case **declared** rather than merely tolerated, so the loader asserts property 4 instead of
  guessing.
- A `relationships.md` row typed with a symmetric relation has `S2T Relation == T2S Relation`, and that is
  **valid** under AC-2, not a "both directions disagree" failure — feature-003 V4 accepts it.
- For a symmetric relation, `(A,B)` and `(B,A)` are the *same* relationship, so AC-3's duplicate check must
  collapse the unordered endpoint pair; feature-003 D7 normalises orientation before keying, which is what
  makes that true structurally.

**This vocabulary ships five symmetric entries, and four of them are symmetric on the authority of their
standard rather than on this SPEC's judgment** — `skos:related` (S23), `skos:exactMatch` and
`skos:closeMatch` (S44), and `prov:alternateOf`, whose PROV-O Table 5 entry gives its recommended inverse name
as `prov:alternateOf` itself. The fifth, `lockstep-with`, is the one symmetric entry whose symmetry is this
vocabulary's own narrowing, and D6a flags it as such.

**One limit of property 6's symmetric clause, stated rather than left for a reviewer to find.** All five
shipped symmetric entries declare **same-kind** tokens only (`concept->concept`, `document->document`,
`source-artifact->source-artifact`, `image->image`, `web-page->web-page`), every one of which is its own
transpose. So the transposition-closure clause is **vacuously satisfied by the core as delivered**, and the
clause's real force — rejecting a symmetric entry declared as `"source-artifact->image"` without its mirror —
is exercised only by a fixture. That fixture is therefore not optional coverage; it is the only thing standing
between the clause and being untested code. AC-S9 names it, and the same reasoning applies as to
feature-003's `image` + `ext:` fixture: without the negative case, an implementation that skipped the
symmetric branch entirely would pass every other check.

**The five properties are verified over the *merged* set, never per file, and that is what makes FR-4a's
prohibitions structural.** feature-003 D4 owns the mechanism; what matters to this feature is which
extension mistake each property catches, because that is the argument that FR-4a needs no rules beyond the
six:

| Extension mistake FR-4a forbids | The property that catches it | Failure mode |
|---|---|---|
| Redefines a core pair by claiming a core relation as its `inverse` | **3 — involution** (feature-003 D4 makes this argument; it is repeated here only because it is the load-bearing one) | `inverse(inverse(foo))` is the core relation's own inverse, not `foo` → exit 2 |
| Adds one half of a pair and forgets the other | **1 — closure** | the orphan `inverse` names no entry's `relation` → exit 2 |
| Files a pair under a category it never declared | **5 — category totality** | undeclared `category` → exit 2 |
| Declares a self-inverse entry as `asymmetric`, or a distinct-inverse entry as `symmetric` | **4 — symmetric consistency** | no third case exists → exit 2 |
| Omits `derived_from` because the project does not care about attribution | **2 — totality** | eight keys required → exit 2 |
| Updates one half's endpoints and not the other's | **6 — pair coherence** | sets are not transposes → exit 2 |
| Re-uses a shipped `relation` name for a different meaning | `relation` **uniqueness** over the merged `pairs:` (feature-003 D4) | naming both resolved paths → exit 2 |
| Re-declares a shipped **category** — same name, its own one-line meaning | `category` **name uniqueness** over the merged `categories:` (feature-003 D4) | naming both resolved paths → exit 2 |

Two consequences of "merged, never per file" that a reader should not have to derive:

- **Order-independence.** The merge is a set union, so the property checks are independent of which file was
  read first and of the order of entries within either. Nothing in the contract depends on load order, which
  is what lets feature-003's loader take core and extension as two positional arguments without a
  precedence rule.
- **The core alone must pass.** Since an extension can only add, the core is required to satisfy all six
  properties standing alone (AC-S1, AC-S5) — and the *only* ways an extension can turn a passing core into a
  failing merged set are the **eight** rows above. That closed list is the substance of FR-4a's "a collision is
  a hard failure, not a silent override".
- **Eight, not seven, and the eighth is not caught by any of the six properties** — a correction the 2026-07-29
  review round forced. Property 5 checks that every entry's `category` **references** a name the merged
  `categories:` block declares; it says nothing about two `categories:` blocks **declaring** the same name.
  Row 7 keys uniqueness over the merged `pairs:`, not over `categories:`. So an extension that re-declares
  `evidence` with its own wording is a collision that the six properties would let through, and it is caught
  only by the loader's separate name-uniqueness check over the merged `categories:` block. D7 rule 3 is the
  other side of the same coin — an extension pair may *reference* a core category and must not *re-declare*
  one — and the two statements now agree instead of the failure-mode list quietly being one short.
- **Which of the eight are merge-*induced*, since that is a different question from which are in the list.**
  Rows 1, 7 and 8 need the core to exist — they are collisions, and a collision needs two declarations. Rows 4,
  5 and 6 fail the extension **standing alone**, and the merge neither causes nor cures them. Rows 2 and 3 are
  the instructive middle: each fails the extension read alone and the merge can **cure** it, because an orphan
  `inverse` may name a core `relation` and a `category` the extension never declared may be one the core
  declares (D7 rule 3). That asymmetry is the whole argument for verifying over the merged set and never per
  file: checking an extension alone would reject legitimate extensions, and checking only the core would miss
  rows 1, 7 and 8 entirely. The claim above is therefore about the closed set of ways a *merged* set can fail,
  not a claim that all eight are unique to merging.

#### D5. The category set — **fourteen**, and what that means for legibility

FR-6b requires the core category set to be closed, requires its **size to be a research finding stated
explicitly** rather than left emergent, and requires every relation to belong to exactly one category.

> **The finding: the core category set has fourteen members.**

The axis is **what the relation asserts about the two nodes**, not which of §5.1's three sources the row
spans. The source axis was the alternative the previous revision offered as a starting proposal and it is
**rejected**: with kind-keyed endpoints, the source span is already recoverable from the two `Kind` columns of
every row, so a category on that axis would carry no information the table does not already have, and FR-13's
Overview lens would collapse to three buckets that say only "KB", "code" and "outside".

| # | Category | One-line meaning | Pairs |
|---|----------|------------------|-------|
| 1 | `structure` | One node is a constituent, a declared member, or an ordered neighbour of the other. | 3 |
| 2 | `taxonomy` | One concept is a generalisation, a specialisation, or an associate of another concept. | 2 |
| 3 | `definition` | One node introduces or exemplifies the term the other node is. | 2 |
| 4 | `documentation` | One node records or names facts about the other. | 2 |
| 5 | `evidence` | One node is cited as the checkable support for a claim in the other. | 2 |
| 6 | `provenance` | One node was derived from, generated from, or reproduced from the other. | 3 |
| 7 | `lineage` | One node is a later version of, or a replacement for, the other. | 2 |
| 8 | `dependency` | One node requires, invokes, or is jointly constrained with the other in order to function. | 3 |
| 9 | `implementation` | One node realises or verifies the specification the other states. | 2 |
| 10 | `representation` | One node is a rendering, an encoding, or a depiction of the other. | 2 |
| 11 | `identity` | The two nodes denote the same thing, or are equivalent or alternative presentations of it. | 4 |
| 12 | `agreement` | One node supports, confirms, contradicts, or refutes a claim in the other. | 2 |
| 13 | `annotation` | One node qualifies or comments on the other without asserting an independent claim. | 1 |
| 14 | `navigation` | One node directs a reader to the other for related or supplementary reading. | 1 |

Total: **31 pairs**, and — since 26 pairs are asymmetric (two entries each) and 5 are symmetric (one entry
each) — **57 entries**. Against the superseded 8 pairs / 15 entries / 5 categories, that is close to four
times the vocabulary, which is what FR-5's "comprehensiveness is preferred over brevity" asks for and what
the widened node model makes necessary: `concept`, `fact` and `section` are nodes now, and
concept-to-concept and fact-to-source relations are the two densest families in the standards.

**Three category boundaries are drawn where a requirement needs them, not where taxonomy would put them.**
Recorded because each is the kind of split a reviewer should challenge:

- **`evidence` is separate from `documentation`.** Taxonomically CiTO makes `citesAsEvidence` a sub-property
  of `cites` and both are "citation". They are split because FR-13's **Coverage** lens and FR-26's gap ledger
  key on "a KB claim backed by a checkable source", which is evidence, while §2 purpose 2's navigation use
  keys on "which document describes what", which is description. One category serving both would make the
  Coverage lens's filter select rows it does not want.
- **`lineage` is separate from `provenance`.** A revision usually *is* derived from what it revises, so
  PROV makes `wasRevisionOf` a sub-property of `wasDerivedFrom`. They are split because FR-13's
  **Provenance** lens is defined as "`kb:` → `int:`/`ext:` chains", and folding document-to-document
  supersession into that category would put same-side edges into a lens whose whole point is the cross-side
  chain.
- **`agreement` is separate from `evidence`.** Evidence answers "where is the support for this claim";
  agreement answers "do these two claims conflict". §2 purpose 1 wants the second visible on its own, because
  a contradiction between two KB documents is a defect that no amount of well-formed citation reveals.

**Two families the prompt for this research names do not become categories, and both merges are recorded
rather than silent.** *Depiction* is filed under `representation`, on the ground that an image is a visual
representation of the subject it illustrates and a `representation` filter that excluded images would answer
the wrong question. *Sequence* is filed under `structure`, on the ground that document order is a structural
property of a document and IANA registers `next`/`prev` alongside `up` and `section` as document-structure
relations. Both are judgments; both are stated so they can be overturned without archaeology.

##### D5a. Fourteen categories against an eight-colour palette — the legibility consequence

FR-6b caps the palette at **eight** distinct category colours (AC-8a part 3) regardless of category count, and
NFR-5 gives the edge a second, non-colour channel of **four** line styles. Fourteen categories therefore
exceed the colour bound by six. The consequence, stated in the three parts a reader needs:

1. **The encoding is representable.** Eight colours × four line styles is 32 distinct (colour, style)
   combinations, so fourteen categories can each be given a unique pair with room to spare — and an extension
   that adds categories has headroom.
2. **The encoding is not simultaneously readable, and no design makes it so.** Q11's recorded design ceiling
   is that beyond roughly eight colours and four line styles "simultaneous distinction fails for all users".
   A reader looking at a graph with all fourteen categories drawn at once cannot reliably tell category 11
   from category 12, and that is a property of human vision rather than of the palette.
3. **So the graph is legible only because filtering is required, not advisory.** This is exactly the
   mechanism FR-6a was added for and AC-8a made testable. The honest statement is: **a fourteen-category
   vocabulary is unreadable unfiltered and readable filtered**, and the requirements already bought the
   filter. Had FR-6a not existed, the correct response to this finding would have been to reduce the category
   count — which would have reduced the vocabulary's expressiveness to fit a palette, the same
   fit-to-the-constraint error in a different dimension.

**Which eight categories should hold a dedicated colour — a recommendation with its basis, and the assignment
is not this feature's.** The basis is FR-13: the four preset lenses are the four ways the graph is actually
read, so the categories a lens keys on are the categories that must be distinguishable *without* filtering.
That yields exactly eight, two per lens:

| Lens (FR-13) | §2 purpose | Categories that must be distinguishable in it |
|---|---|---|
| Coverage | 1 — drift and coverage | `evidence`, `documentation` |
| Provenance | 1 and 4 | `provenance`, `lineage` |
| Impact | 3 — impact analysis | `dependency`, `implementation` |
| Overview | 2 — navigation and onboarding | `structure`, `taxonomy` |

The remaining six — `definition`, `representation`, `identity`, `agreement`, `annotation`, `navigation` —
share colours and are separated by line style and by filtering. **The palette assignment itself belongs to
feature-007 and feature-008**, which own the view and the contrast budget; this SPEC supplies the ranking and
its basis so the assignment is a design decision made against a stated rule rather than an arbitrary pick
(Open Item 7).

#### D6. The core vocabulary

One row per **pair**. The `inverse` entry's `category`, `derived_from` and `passes` equal the row's by
property 6, and its `endpoint_kinds` is this row's set transposed; only its `definition` is authored
separately, from the inverse reading. `endpoint_kinds` is given for the **`relation`** direction.

Definitions are given in the shape "The source … the target …" so that the reading direction is never in
doubt. `sym` is `A` for asymmetric, `S` for symmetric.

**`structure`** — one node is a constituent, a declared member, or an ordered neighbour of the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `has-part` / `part-of` | A | `dcterms:hasPart`, `schema:hasPart`, `iana:up` | `document->section`, `section->section`, `document->fact`, `section->fact` | `declared`, `derived` | "The target is a constituent of the source's own content and has no existence independent of it." |
| `has-member` / `member-of` | A | `skos:member`, `prov:hadMember`, `iana:item` | `document->document`, `concept->concept`, `source-artifact->source-artifact`, `document->source-artifact` | `declared` | "The source declares a set in which the target is enrolled, and the target exists independently of that set." |
| `precedes` / `follows` | A | `iana:next`, `iana:prev` | `section->section`, `document->document` | `declared`, `derived` | "The source and the target are members of one ordered series in which the target comes immediately after the source." |

**`has-part` is deliberately KB-only, and that is a worked instance of the migration's narrowing step.**
Mechanical expansion of the prefix token `"int:->int:"` would have handed this entry
`source-artifact->source-artifact`, and it is removed: FR-23 makes project source **whole-artifact**, so there
is no code-side constituency to express, and feature-004 D2a's skill- and agent-directory collapse
*suppresses* the member files rather than emitting them as parts. A `source-artifact->source-artifact`
part–whole token would therefore have had no producer on any project — an `unreachable` token in D3a's W3
report, sitting in the file looking authoritative. Enrolment in a declared set, which *is* a real code-side
relation, is `has-member` instead.

**`taxonomy`** — one concept is a generalisation, a specialisation, or an associate of another concept.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `broader-than` / `narrower-than` | A | `skos:broader`, `skos:narrower` | `concept->concept` | `declared`, `inferred` | "The source concept is a direct, immediate generalisation of the target concept." |
| `related-concept` / `related-concept` | S | `skos:related` | `concept->concept` | `declared`, `inferred` | "The source and target concepts are associated without either being a generalisation of the other." |

**`definition`** — one node introduces or exemplifies the term the other node is.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `defines` / `defined-by` | A | `skos:definition`, `schema:hasDefinedTerm` | `document->concept`, `section->concept` | `declared` | "The source introduces the target concept by stating what it means." |
| `exemplifies` / `exemplified-by` | A | `skos:example`, `schema:exampleOfWork` | `section->concept`, `source-artifact->concept`, `image->concept`, `fact->concept` | `declared`, `inferred` | "The source is an instance or illustration of the target concept rather than a statement of what it means." |

**`documentation`** — one node records or names facts about the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `documents` / `documented-by` | A | `cito:documents`, `schema:about`, `iana:describes` | `document->source-artifact`, `section->source-artifact`, `document->document`, `section->document`, `document->image`, `document->web-page` | `declared` | "The source is an authored record of the target, written by drawing on the target for its factual content." |
| `mentions` / `mentioned-in` | A | `cito:citesForInformation`, `dcterms:references` | `document->concept`, `section->concept`, `fact->concept`, `document->document`, `section->document`, `document->source-artifact`, `section->source-artifact`, `fact->source-artifact` | `declared`, `derived`, `inferred` | "The source names the target in its content without asserting that the target is its subject or its evidence." |

**`evidence`** — one node is cited as the checkable support for a claim in the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `cites` / `cited-by` | A | `cito:cites`, `cito:citesAsAuthority`, `dcterms:references` | `document->source-artifact`, `section->source-artifact`, `fact->source-artifact`, `document->web-page`, `section->web-page`, `fact->web-page`, `fact->document` | `declared` | "The source names the target as a reference a reader may consult." |
| `cites-as-evidence` / `cited-as-evidence-by` | A | `cito:citesAsEvidence` | `fact->source-artifact`, `fact->web-page`, `fact->image`, `fact->document` | `declared` | "The source names the target as the checkable support for one specific claim the source makes." |

**`provenance`** — one node was derived from, generated from, or reproduced from the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `derived-from` / `source-of` | A | `prov:wasDerivedFrom`, `prov:hadPrimarySource`, `dcterms:source`, `iana:via` | `document->source-artifact`, `section->source-artifact`, `fact->source-artifact`, `document->web-page`, `fact->web-page`, `source-artifact->source-artifact`, `image->image` | `declared`, `derived`, `inferred` | "The content of the source came from the target, whether by a person reading it or by a process transforming it." |
| `generated-by` / `generates` | A | `prov:wasGeneratedBy` | `source-artifact->source-artifact`, `image->source-artifact`, `document->source-artifact` | `derived` | "The source was produced from the target by a named deterministic process rather than by an author." |
| `quotes` / `quoted-in` | A | `prov:wasQuotedFrom` | `document->source-artifact`, `section->source-artifact`, `fact->source-artifact`, `document->web-page` | `declared` | "The source reproduces part of the target verbatim." |

**`lineage`** — one node is a later version of, or a replacement for, the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `supersedes` / `superseded-by` | A | `dcterms:replaces`, `iana:successor-version` | `document->document`, `section->section`, `source-artifact->source-artifact`, `concept->concept`, `fact->fact` | `declared`, `inferred` | "The source takes the place of the target, which is retired in the source's favour." |
| `revision-of` / `has-revision` | A | `prov:wasRevisionOf`, `dcterms:isVersionOf`, `iana:predecessor-version` | `document->document`, `source-artifact->source-artifact`, `image->image` | `declared`, `derived` | "The source is a later version of the target, both of which remain current as versions of one thing." |

**`dependency`** — one node requires, invokes, or is jointly constrained with the other in order to function.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `depends-on` / `dependency-of` | A | `dcterms:requires`, `prov:used` | `source-artifact->source-artifact`, `source-artifact->image`, `source-artifact->web-page` | `declared`, `derived` | "The source requires the target as a data input in order to function correctly." |
| `invokes` / `invoked-by` | A | `prov:used` | `source-artifact->source-artifact` | `derived` | "The source executes or dispatches the target as a subprocess or called script at runtime." |
| `lockstep-with` / `lockstep-with` | S | `dcterms:requires`, `skos:related` | `source-artifact->source-artifact`, `document->document` | `declared` | "The source and the target share a maintenance invariant they must satisfy together, with no primary direction." |

**`implementation`** — one node realises or verifies the specification the other states.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `implements` / `implemented-by` | A | `dcterms:conformsTo`, `schema:isBasedOn`, `iana:profile` | `source-artifact->document`, `source-artifact->source-artifact`, `source-artifact->section`, `source-artifact->fact` | `declared`, `inferred` | "The source realises the behaviour or the shape that the target specifies." |
| `tests` / `tested-by` | A | `cito:confirms` | `source-artifact->source-artifact`, `source-artifact->document`, `source-artifact->fact`, `source-artifact->section` | `declared`, `derived` | "The source verifies that the behaviour the target specifies or provides actually holds." |

**`representation`** — one node is a rendering, an encoding, or a depiction of the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `renders-to` / `rendered-from` | A | `dcterms:hasFormat`, `schema:encoding` | `source-artifact->source-artifact`, `document->source-artifact`, `image->image` | `declared`, `derived` | "The target carries the same content as the source in a different format or for a different target environment." |
| `illustrated-by` / `illustrates` | A | `schema:image` | `document->image`, `section->image`, `fact->image`, `source-artifact->image` | `declared`, `derived` | "The source is illustrated by the target image, which depicts the source's subject." |

**`identity`** — the two nodes denote the same thing, or are equivalent or alternative presentations of it.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `same-as` / `same-as` | S | `schema:sameAs`, `skos:exactMatch` | `concept->concept`, `document->document`, `source-artifact->source-artifact`, `image->image`, `web-page->web-page` | `declared`, `inferred` | "The source and the target are two identifiers for one and the same thing." |
| `similar-to` / `similar-to` | S | `skos:closeMatch` | `concept->concept`, `document->document` | `inferred` | "The source and the target are close enough to be interchangeable in some contexts but are not the same thing." |
| `alternate-of` / `alternate-of` | S | `prov:alternateOf`, `iana:alternate` | `source-artifact->source-artifact`, `document->document`, `image->image`, `web-page->web-page` | `declared`, `derived` | "The source and the target present aspects of the same thing without necessarily presenting the same aspects." |
| `canonical-form-of` / `has-canonical-form` | A | `iana:canonical`, `prov:specializationOf` | `source-artifact->source-artifact`, `document->document`, `image->image` | `declared`, `derived` | "The source is the authoritative form of which the target is a copy or a narrower presentation." |

**`agreement`** — one node supports, confirms, contradicts, or refutes a claim in the other.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `supports` / `supported-by` | A | `cito:supports`, `cito:confirms`, `cito:agreesWith` | `fact->fact`, `document->fact`, `fact->document`, `section->fact`, `section->section` | `inferred` | "The claim the source makes strengthens or corroborates the claim the target makes." |
| `contradicts` / `contradicted-by` | A | `cito:disagreesWith`, `cito:refutes`, `cito:corrects` | `fact->fact`, `fact->document`, `document->document`, `section->section` | `inferred` | "The claim the source makes cannot hold together with the claim the target makes." |

**`annotation`** — one node qualifies or comments on the other without asserting an independent claim.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `annotates` / `annotated-by` | A | `cito:qualifies`, `cito:discusses` | `section->fact`, `section->section`, `section->source-artifact`, `document->document`, `fact->fact` | `inferred` | "The source adds a scoping remark, caveat or commentary that qualifies the target without asserting a claim of its own." |

**`navigation`** — one node directs a reader to the other for related or supplementary reading.

| relation / inverse | sym | `derived_from` | `endpoint_kinds` | `passes` | `definition` (relation reading) |
|---|---|---|---|---|---|
| `cross-references` / `cross-referenced-by` | A | `iana:related`, `dcterms:relation` | `document->document`, `section->section`, `document->section`, `concept->document` | `declared` | "The source instructs a reader to consult the target for supplementary or related information." |

##### D6a. The two narrowings, the two analogy classes, one modelling choice worth defending, and the one entry whose necessity is weakest

Flagged individually so none reads as a direct adoption, and so a reviewer's attention lands where it should.
The first two bullets are the two **narrowings** D2 refers to; the next two are the two **acknowledged
analogies** — citations whose standard term is not an object property between two nodes at all; the fifth is a
modelling decision that follows a standard rather than narrowing one; the sixth is where this vocabulary is most
vulnerable to challenge. Every token in the vocabulary, flagged or not, is accounted for in the audit at
**D6d**; these six are the ones that need an argument rather than a table row.

- **`lockstep-with` narrows two standards and is the vocabulary's one self-declared symmetric entry.**
  `dcterms:requires` is asymmetric and `skos:related` is a generic symmetric association between *concepts*;
  neither expresses "these artifacts must be maintained together". The entry takes the symmetry from
  `skos:related` and the obligation from `dcterms:requires`, and the composition is this vocabulary's, not
  either standard's. It is kept because a mutual maintenance invariant is a real and checkable relation with
  no direction — this repository's `infrastructure.md` § "Install Bootstrap and Manifests" records five
  install manifests that "must stay byte-lockstep on that file set" — and because dropping it would force
  such a fact into two asymmetric rows that both assert a direction that does not exist.
- **`invokes` narrows `prov:used` to execution.** `prov:used` covers any consumption of an entity by an
  activity. `depends-on` and `invokes` both derive from it and are distinguished by *how* the target is
  consumed — as data, or as a program to run. The two are kept separate rather than merged because FR-13's
  Impact lens answers "what does this change touch", and a data dependency and a call edge propagate change
  differently. The distinction survives from the superseded vocabulary; what changed is that it now rests on
  a standard rather than on this repository's observed instances.
- **`defines` and `exemplifies` cite two SKOS *annotation* properties, which is an analogy and not an
  adoption.** SKOS integrity condition **S16** declares `skos:definition` and `skos:example` each an instance
  of `owl:AnnotationProperty`, and the Reference's own worked example shows the conventional use —
  `skos:Concept skos:definition "…"@en`, a **literal** documentation note with no second node
  (`https://www.w3.org/TR/skos-reference/`, accessed 2026-07-29). AID splits what SKOS keeps in one place: the
  concept is a node and the prose that defines or exemplifies it lives in a *different* node, so an assertion
  SKOS makes with a literal becomes an **edge between two nodes** here. The flag matters because the
  object-property half of each derivation is what actually carries the entry — `schema:hasDefinedTerm` ("A
  Defined Term contained in this term set") for `defines` and `schema:exampleOfWork` for `exemplifies`, both
  genuine object properties running source → target (`https://schema.org/hasDefinedTerm`, accessed
  2026-07-29). Neither token is dropped: the assertion is real, the standards' own word for it is the word AID
  uses, and the honest record is that SKOS reifies it differently. `exemplifies` is flagged here although only
  `defines` was challenged — the two properties are declared by the **same** integrity condition, so fixing one
  and not the other would have left the identical defect one line below.
- **`generated-by`, `depends-on` and `invokes` cite two PROV properties whose *other* argument is an Activity,
  the one class §5.2 cannot denote.** PROV-O's qualification table states the arguments verbatim:
  `prov:Entity prov:wasGeneratedBy prov:Activity`, and `prov:Activity prov:used prov:Entity`
  (`https://www.w3.org/TR/prov-o/`, accessed 2026-07-29). No `Kind` value denotes an activity (D8), so each of
  these three occurrences is cited with the **activity elided to the artifact that embodies it** — the script
  that ran, the program that consumed the input. That elision is what makes the three entries expressible at
  all, and it is D8's coverage limit surfacing as an attribution caveat rather than as a missing relation. The
  alternative was to re-cite all three on `prov:wasDerivedFrom`, whose two arguments are both entities, and it
  is rejected: `wasDerivedFrom` is already `derived-from`'s citation, so collapsing "produced by a named
  process" and "required as a data input" into it would erase exactly the distinction the `invokes` bullet
  above defends.
- **`contradicts` keeps CiTO's asymmetry although contradiction is logically symmetric.** CiTO models
  `disagreesWith` / `isDisagreedWithBy` as an inverse *pair*, not as a symmetric property, and this
  vocabulary follows it: the direction records **which node asserts the disagreement**, which for §2 purpose
  1 is the load-bearing information — it is how a reader tells which of two conflicting documents is the one
  that has gone stale.
- **`annotates` is the entry with the weakest independent justification, and it is named as such.** Its
  standards footing is sound (`cito:qualifies` and `cito:discusses` both exist), but FR-4 already sends
  "free-text nuance that no pair captures" to the `Observation` column, so a relation meaning "adds a
  remark" risks competing with that column. It is kept on two grounds: its `passes` is `[inferred]` alone, so
  it can only ever be produced by the reading pass and never competes with a deterministic carrier; and an
  annotation is a relation **between two nodes**, which `Observation` — a per-row free-text cell — cannot
  express at all. If a reviewer removes one entry from this vocabulary, this is the one to argue about.

##### D6b. Definitional overlaps that were resolved by merging, and the two that were kept apart deliberately

The Step-5 screen (§ Feature Flow) forbids admitting a type whose `definition` covers the same assertion as
an admitted one. **Four** candidates were merged away, and the merges are recorded because "why is there no
`describes`?" is the first question a reader of the standards will ask.

| Candidate | Standard offering it | Merged into | Why |
|---|---|---|---|
| `describes` / `described-by` | `cito:describes`, `iana:describes` | `documents` | CiTO distinguishes documenting from describing by the depth of the account, which is a matter of degree and not of kind. Two authors could not reliably pick between them, and an unreliable choice reintroduces the ambiguity a named set exists to remove |
| `has-primary-source` / `primary-source-of` | `prov:hadPrimarySource` | `derived-from` | PROV makes it a sub-property of `wasDerivedFrom`, distinguished by first-hand knowledge. No carrier in an AID Knowledge Base distinguishes a first-hand source from any other source, so the distinction would never be decidable from the artifact |
| `conforms-to` / `conformed-to-by` | `dcterms:conformsTo`, `iana:profile` | `implements` | Conforming to a specification and implementing it are the same assertion about a source artifact and a specifying document. Both standards are recorded in `implements`'s `derived_from`, so nothing is lost but a second name |
| `cites-as-authority` / `cited-as-authority-by` | `cito:citesAsAuthority` | `cites` | *Merged 2026-07-29.* CiTO defines the property as citing an entity "as one that provides an **authoritative description or definition** of the subject under discussion" (`https://sparontologies.github.io/cito/current/cito.html`, accessed 2026-07-29) — backing by standing, which is a different assertion from the checkable support for one specific claim that `cites-as-evidence` states. It merges into the **generic** `cites`, whose definition ("a reference a reader may consult") subsumes it, because no AID carrier distinguishes a citation made for standing from one made for any other reason — the same argument that sends `prov:hadPrimarySource` to `derived-from` two rows up. The token therefore moves to `cites`'s `derived_from`, so the attestation is kept and only the second name is lost |

**Why the fourth row records a *defect* and not merely a merge.** Until 2026-07-29 `cites-as-evidence` carried
**both** `cito:citesAsEvidence` and `cito:citesAsAuthority` in one `derived_from`, while its definition — "the
checkable support for one specific claim the source makes" — matches only the first. The consequence was
concrete rather than stylistic: a row pointing at an authoritative reference work would have **satisfied
`derived_from` while contradicting `definition`**, which is the single thing this field exists to make
impossible. The entry now cites `cito:citesAsEvidence` alone, whose CiTO wording — "cites the cited entity as
source of factual evidence for statements it contains" — is that definition almost word for word. **Splitting**
instead, into a 32nd pair `cites-as-authority`, was the other available fix and is rejected on the screen's own
terms: choosing between "cited for its standing" and "cited as a reference" is not decidable from an AID
artifact, which is the same unreliable-choice test that merged `describes` away in row 1. And the general rule
this round establishes: D1's "multiple attestation is the strongest available evidence" holds **only** where
every attestation attests the *same* assertion — one exact token beats two of which one is wrong, and the audit
at D6d is where that is checked entry by entry rather than asserted once.

**And the rule that makes moving a token to the absorbing entry safe, since it looks like the same move in
reverse.** `cites` now carries `cito:citesAsAuthority`, a **sub**-property of the `cito:cites` it also carries,
and a `cites` row need not be an authority citation — so why is that not the defect just fixed? Because the
direction of subsumption is the opposite one, and that is what decides it: everything `citesAsAuthority`
asserts **is** a `cites`, so the entry's definition is *entailed by* the token. The defect above was a token
asserting something the definition does **not** say, which let a conforming row contradict it. Stated as a
general rule, since every row of this table relies on it: a merged-away candidate's token may be recorded on
the entry that absorbs it **only** where the absorbing entry's definition is entailed by that token, never the
reverse — which is also what licenses `prov:hadPrimarySource` on `derived-from` and `dcterms:conformsTo` on
`implements`.

Two pairs that *look* like overlaps and are kept apart, with the discriminator stated so a future reviewer
does not merge them by mistake:

- **`renders-to` versus `canonical-form-of`.** The first is about **format or target environment**; the
  second is about **authority**. Both put the original, authoritative artifact in **Source**, which is why they
  are comparable at all (D6d, first table, row 5). This repository instances both on the same endpoint pair — a canonical
  source and its five profile renders are format variants *and* copies of an authoritative form — and
  feature-003's interpretation decision 1 explicitly permits "two genuinely different typed relations
  between the same two nodes", keying V5's duplicate check on the relation pair as well as the endpoints. So
  the two coexisting on one endpoint pair is the schema working as specified, not a duplicate.
- **`same-as` versus `alternate-of` versus `similar-to`.** SKOS itself separates these: `exactMatch` is a
  sub-property of `closeMatch` (S42) and is disjoint from `broadMatch` and `relatedMatch` (S46), and PROV
  defines `alternateOf` as entities that "present aspects of the same thing, but not necessarily the same
  aspects or at the same time" — a weaker claim than identity. Three names for three distinct claims, each
  with a standard behind the distinction.

##### D6c. The `image-reference` mapping — feature-004's Open Item 4, discharged

feature-004's D5 emits an `image-reference` observation whose `from_id` is the artifact whose bytes contained
the reference and whose `to_id` is the image node, and its own SPEC states the reason for making it a distinct
observation kind: "the depiction relation class FR-5's standards-first vocabulary is expected to supply
(schema.org / CiTO / Dublin Core all carry one) would have no carrier." That expectation is now met.

> **`image-reference` maps to `illustrated-by` (S2T) / `illustrates` (T2S).**

Its legality against this feature's own fields, which is the part feature-004 could not settle and
feature-005 needs:

- **Direction.** feature-004's `from_id` is the citing artifact and `to_id` is the image, so the row's Source
  is the citing node and its Target is the image. `illustrated-by` is therefore the correct `S2T` label. The
  naming follows `schema:image`, which runs Thing → ImageObject; naming the S2T direction `depicts` was
  considered and rejected because it reads backwards — it is the *image* that depicts, so a row typed
  `document depicts image` asserts the opposite of what it means.
- **`endpoint_kinds` covers both producers, and stops there.** `source-artifact->image` is satisfied by
  feature-004's `image-reference` observation. `document->image`, `section->image` and `fact->image` are
  satisfied by feature-005's Pass 1 reading of the Knowledge Base, since feature-004 walks the project source
  only and its `from_id` is typed as an `int:` id. **One relation with two producers in two different features
  is exactly the case D3a's W3 report exists to make visible**, and it is the worked example that shows the
  report is not ceremony.
- **`concept->image` was considered and is excluded**, which is the narrowing step of D3's migration applied to
  this entry. An illustration edge needs a literal reference in some text extent, and a `concept` is the one
  kind with **no text extent of its own** — it is a term merged across every document that defines or mentions
  it (Q13), so its identity is a normalised label rather than a span of bytes. The reference that ties a
  concept to a picture always lives in the document or section that mentions the concept, and that is the
  `document->image` or `section->image` token. Declaring `concept->image` would have produced a token no pass
  could satisfy, given the `passes` set below.
- **`passes` is `[declared, derived]`.** A markdown `![alt](ref)` is literal text in the citing file, so the
  observation is `declared`; where the target is reached by feature-004's basename or relative-path
  resolution rather than by a literal full path, the row is `derived`. `inferred` is deliberately **excluded**:
  an image reference is always a literal in some file, so a reading pass has nothing to add and an `inferred`
  illustration edge would be an unfalsifiable claim about what a picture is of. Excluding `inferred` is also
  what makes the `concept->image` exclusion above forced rather than merely tidy — with no `inferred` pass
  available, Pass 2 could not have supplied that token either.

**What is relayed and not adopted.** feature-004's Open Item 4 carries a second, unrelated half — that
feature-005's coverage rows should use the same `present`-iff-≥1 predicate feature-004's D7 fixes, so the
coverage-notes section does not mix two definitions of `present`. That is feature-004 → feature-005 and has
nothing to do with the vocabulary; it is relayed at Open Item 6 with feature-005 named, and no predicate is
restated here.

##### D6d. The citation audit — every token checked for meaning and direction, not existence

**Why this section exists.** The 2026-07-29 review round found one defect class, six times: *a cited property
that exists but does not mean what the entry uses it for.* Every token checked out on existence; five of six
findings were semantic. Existence is the cheap half of a citation and it is the half a reader can verify
unaided — so recording only that a term exists shifts the expensive half onto every future reviewer. This
audit is the expensive half, done once and written down. It is also the reason the fixes below are eight and
not six: two came from sweeping the class the reviewer named rather than the rows it reported.

**Scope and totality.** The delivered core carries **64 `derived_from` token occurrences** across D6's 31 pairs
(a token counts once per entry that cites it, so `prov:used`, `dcterms:references`, `dcterms:requires` and
`cito:confirms` each count twice). **Fifteen** are flagged in the first table below. The remaining **49** run
source → target as their entry reads it, or are declared symmetric by their own standard and cited by a
symmetric entry. The general class-conformance caveat that D2 states once — no AID node is an instance of any
class these standards define — covers all 64 and is not repeated per row. **AC-S2** makes this audit's totality
a checked property of the delivered file: every token is classed here or runs direct, with nothing silent.

**Provenance of the quotations.** Every phrase quoted in the two tables was read on **2026-07-29** from the
document D1's table names for that standard, at the version recorded there — `https://www.w3.org/TR/skos-reference/`,
`https://www.dublincore.org/specifications/dublin-core/dcmi-terms/`, `https://www.w3.org/TR/prov-o/`,
`https://www.iana.org/assignments/link-relations/link-relations.xhtml` and
`https://sparontologies.github.io/cito/current/cito.html` — plus, because schema.org publishes one page per
term, `https://schema.org/predecessorOf`, `https://schema.org/sameAs`, `https://schema.org/image` and
`https://schema.org/hasDefinedTerm`, each footed `V30.0 | 2026-03-19`, the release D1 records. No wording here
is quoted from memory, and where a converted page dropped the RDF placeholders from a definition the
surrounding normative prose is quoted instead (row 2 is that case).

| # | Entry (S2T) | Token | What the live standard says, and the flag it earns | Treatment |
|---|---|---|---|---|
| 1 | `has-part` | `iana:up` | **[direction]** "Refers to a parent document in a hierarchy of documents" — the subject is the **child**, so the registered relation runs part → whole | Retained unpaired: the registry has no `down`. `dcterms:hasPart` and `schema:hasPart` both run whole → part and carry the entry; `iana:up` contributes the registry's attestation that part–whole is a recognised web relation, and it matches the `part-of` reading |
| 2 | `broader-than` | `skos:broader` | **[direction]** §8.1 states it in the clearest possible terms — a triple `A skos:broader B` "asserts that `B`, the object of the triple, is a broader concept than `A`, the subject of the triple" — so the property runs **narrower → broader**, which is the `narrower-than` reading, not this entry's. **S25** declares `skos:narrower` its inverse | **Paired 2026-07-29.** The entry now also cites `skos:narrower`, of which the same section says a triple `A skos:narrower B` asserts that `B` "is a narrower concept than" `A` — broader → narrower, matching the S2T reading exactly. The inversion is now resolved in the data rather than only in D2's prose |
| 3 | `precedes` | `iana:prev` | **[direction]** "Indicates that the link's context is a part of a series, and that the previous in the series is the link target" — the subject is the later member | Paired: cited alongside `iana:next` ("the next in the series is the link target"), which matches the S2T reading. Added this round in place of `schema:predecessorOf` (second table, row 7) |
| 4 | `supersedes` | `iana:successor-version` | **[direction]** "Points to a resource containing the successor version in the version history" — the subject is the **older** resource, matching `superseded-by` | Retained unpaired, and it is D2's worked illustration of the pair-level principle. `dcterms:replaces` runs source → target and carries the entry. Citing `iana:predecessor-version` here as well is rejected: it is `revision-of`'s token, and version-history navigation is not the retirement claim this entry makes |
| 5 | `canonical-form-of` | `iana:canonical` | **[direction]** "Designates the preferred version of a resource (the IRI and its contents)" — the subject is the **non**-preferred form and the target is the canonical one, matching `has-canonical-form` | Retained unpaired; it is the entry's whole attestation of the *authority* claim. Naming the S2T direction `has-canonical-form`, so that both of this entry's tokens ran source → target, was the alternative and is rejected: `renders-to` — the pair D6b tells a reader to compare this one with, and which instances the same endpoint pair — puts the **original** artifact in Source (`canonical/` → its five `profiles/` renders). Naming this pair the other way round would put the *copy* in Source and make two relations that a reader is told to compare read in opposite directions |
| 6 | `canonical-form-of` | `prov:specializationOf` | **[direction]** "`prov:specializationOf` links a more specific Entity to a more general one" — the subject is the **more specific** entity, matching `has-canonical-form` | Retained unpaired. Table 5 reserves `generalizationOf` as the inverse *name*, which is the reading that would match S2T — but PROV-O declares no such property, only the name, so there is no token to cite in its place |
| 7 | `cross-references` | `iana:related` | **[neutral]** "Identifies a related resource" — the registry fixes no direction | Retained. The entry's asymmetry ("instructs a reader to consult") is this vocabulary's narrowing of a deliberately generic term, not a reading of it. Recorded so the audit is total, not because there is a conflict |
| 8 | `cross-references` | `dcterms:relation` | **[neutral]** "A related resource" — DCMI fixes no direction and declares no inverse | Retained, same treatment as row 7 |
| 9 | `defines` | `skos:definition` | **[argument]** **S16** declares it an `owl:AnnotationProperty`; its conventional use carries a **literal**, so the standard's second argument is not a node at all | Retained as an acknowledged analogy, argued at D6a. `schema:hasDefinedTerm` is the entry's object-property derivation and runs source → target |
| 10 | `exemplifies` | `skos:example` | **[argument]** Declared by the **same** condition **S16**, with the same literal-valued convention | Retained as an acknowledged analogy, argued at D6a. Flagged although unreported: the two properties share one integrity condition, so fixing only `defines` would have left the identical defect one line below. `schema:exampleOfWork` is the object-property derivation |
| 11 | `generated-by` | `prov:wasGeneratedBy` | **[argument]** The qualification table states `prov:Entity prov:wasGeneratedBy prov:Activity` — the other argument is an **Activity**, the one class §5.2 cannot denote (D8) | Retained as an acknowledged analogy, argued at D6a: the activity is elided to the artifact that embodies it |
| 12 | `depends-on` | `prov:used` | **[argument]** `prov:Activity prov:used prov:Entity` — here the **subject** is the Activity | Retained as an acknowledged analogy, argued at D6a, same elision |
| 13 | `invokes` | `prov:used` | **[argument]** As row 12; the second occurrence of the same token | Retained; the narrowing to execution is separately argued at D6a |
| 14 | `lockstep-with` | `dcterms:requires` | **[symmetry]** The property is **asymmetric** ("A related resource that is required by the described resource…"), and it is cited by the vocabulary's one self-declared **symmetric** entry | Retained; this is the composition D6a's first bullet defends — the obligation comes from `dcterms:requires` and the symmetry from `skos:related`, and the combination is this vocabulary's, not either standard's |
| 15 | `same-as` | `schema:sameAs` | **[value type]** "URL of a reference Web page that unambiguously indicates the item's identity" — the value is a **URL**, so what the property points at is a reference page rather than a graph node | Retained: the *identity* assertion is what the token attributes, and `skos:exactMatch` — declared symmetric at **S44** — carries the entry's symmetry and its node-to-node reading |

**What this round changed, and where each change came from.** Eight token changes across eight of the 31 pairs.
No pair, entry or category is added or removed: the vocabulary remains 31 pairs / 57 entries / 14 categories,
and every entry still satisfies `derived_from`'s non-empty rule.

| # | Entry | Was | Now | Why, against the live standard |
|---|---|---|---|---|
| 1 | `cites-as-evidence` | `cito:citesAsEvidence`, `cito:citesAsAuthority` | `cito:citesAsEvidence` | Authority is backing by standing; evidence is a checkable claim. The co-attribution let a row pointing at an authoritative reference work satisfy `derived_from` while contradicting `definition`. Full argument and the rejected split at D6b |
| 2 | `cites` | `cito:cites`, `dcterms:references` | `cito:cites`, `cito:citesAsAuthority`, `dcterms:references` | Receives the authority sense merged out of row 1. `cites`'s definition — "a reference a reader may consult" — subsumes it, so the attestation is kept rather than discarded |
| 3 | `tests` | `cito:confirms`, `cito:citesAsEvidence` | `cito:confirms` | **Found by sweeping the class, not reported.** A test does not cite its specification as evidence *for the test's own claims*; it confirms the claim the specification makes, which is `cito:confirms` almost verbatim: "The citing entity confirms facts, ideas or statements presented in the cited entity" |
| 4 | `illustrated-by` | `schema:image`, `iana:icon` | `schema:image` | `icon` is "an icon representing the link's **context**" — a UI symbol identifying a resource, which need not depict its subject, while the definition requires depiction. `schema:image` ("An image of the item") is that claim. Keeping it would also have cited as depiction the exact artifact feature-004 uses as its *contrasting* case for a reference that is real without implying what a reader assumes |
| 5 | `has-member` | `skos:member`, `prov:hadMember`, `iana:collection` | `skos:member`, `prov:hadMember`, `iana:item` | **Found by sweeping the class.** `collection`'s subject is the member ("The target IRI points to a resource which represents the collection resource for the context IRI"); `item`'s is the collection ("…a resource that is a member of the collection represented by the context IRI"). Both are registered and both were already in D1's scope, so the entry now cites the one that runs source → target |
| 6 | `revision-of` | `prov:wasRevisionOf`, `dcterms:isVersionOf`, `iana:version-history` | `prov:wasRevisionOf`, `dcterms:isVersionOf`, `iana:predecessor-version` | **Found by sweeping the class.** `version-history`'s target is a **history resource** ("Points to a resource containing the version history for the context") — not an earlier version, and not a thing either declared endpoint kind denotes. `predecessor-version` ("Points to a resource containing the predecessor version in the version history") runs newer → older, matching the S2T reading |
| 7 | `precedes` | `iana:next`, `schema:predecessorOf` | `iana:next`, `iana:prev` | **Found by sweeping the class.** `schema:predecessorOf` is credited to the **GoodRelations e-commerce** vocabulary and defined over a product variant, which D1's schema.org row already excluded as out of domain — so the citation contradicted this SPEC's own scope statement. `iana:prev` states the ordering inside a registry the entry already cites |
| 8 | `broader-than` | `skos:broader` | `skos:broader`, `skos:narrower` | The added token runs broader → narrower and matches the S2T reading, so the inversion is resolved in the data rather than only by D2's principle (first table, row 2) |

**Three dropped tokens stay in D1's scope columns, and that is not an inconsistency.** `iana:icon`,
`iana:collection` and `iana:version-history` remain listed as terms the traversal considered, because D1's
middle column records what was *examined* and its closing rule only forbids the converse — a cited token
missing from the column. `schema:predecessorOf` is the one exception and it **moves** to the "what it leaves"
column, because the reason it is no longer cited is that it was out of domain all along.

#### D7. Core plus project extension (FR-4, FR-4a)

**Consumed from feature-003 D4, not restated.** The extension's location
(`.aid/graph/relation-vocabulary.yml`), the core's location
(`<install-root>/aid/templates/graph/relation-vocabulary.yml`, authored at
`canonical/aid/templates/graph/relation-vocabulary.yml`), the identical file format, the union-with-hard-fail
precedence, the fail-closed treatment of an absent core, the not-an-error treatment of an absent extension,
and the `--vocabulary` / `--vocabulary-extension` test overrides are all **feature-003's contract**, already
fixed and graded. This SPEC binds to them.

What is **this** feature's, because it is about the vocabulary's content rather than its loading:

1. **An extension entry satisfies the same eight-key contract**, including `derived_from` — with one
   difference: an extension entry **may** use the token `coined`, because a project-specific relation type
   may legitimately have no antecedent in the six standards, whereas a shipped core type may not. This is the
   one place where the core and an extension are held to different content rules, and the asymmetry is the
   point: `coined` is what makes the core's prohibition on it enforceable without forbidding projects to
   extend.
2. **An extension entry's `endpoint_kinds` is kind-keyed over the same enum**, read from the same
   `relationship-schema.yml`. An extension cannot introduce a node kind, because `Kind` is §5.2's closed enum
   and adding to it is a requirements change — so no extension can produce a token the loader would have to
   reject for naming an unknown kind, and W1 is total over the merged set for free.
3. **An extension pair may be filed under a *core* category, and that is not a collision.** feature-003 D4
   rejects an extension `categories:` **name** equal to a core category name, which forbids **re-declaring**
   a core category's meaning; category totality then checks every entry's `category` against the **merged**
   set, which permits **referencing** one. Stated explicitly because the two rules read as contradictory
   until you notice one is about declarations and the other about references, and a project that filed its
   own pair under `evidence` and had the run fail would reasonably read that as a defect.
4. **An extension may not narrow a core relation's `endpoint_kinds`.** `endpoint_kinds` is part of a pair's
   definition, and FR-4a forbids redefining a core pair, so a project wanting different endpoints for a
   shipped relation must add its **own** pair with its own name. Stated because narrowing is the plausible
   thing an adopter would try first, and because it is the same fit-to-this-repository move that produced the
   superseded vocabulary — this time it would be scoped to one project, which is legitimate as a *new* pair
   and illegitimate as an *edit*.
5. **An extension is bound by property 6 over the merged set.** A project adding `foo` / `bar` must give
   transposed endpoint sets and matching `category`, `derived_from` and `passes` — the same obligation the
   core carries, checked by the same loader on the same merged set.
6. **The extension is the fifth staleness input alongside the core.** FR-11 input 5 names both files, and
   FR-32/AC-5 rest on it: a project that adds an extension pair changes how edges are typed, so an unchanged
   Knowledge Base can legitimately produce a different table. Composing both files into the staleness digest
   is feature-010's (Open Item 9).

**How comprehensiveness and genericity interact, since this is where the superseded design failed.** A core
that is larger than any one project needs is not waste; it is the mechanism by which AC-19's genericity
outcomes are reachable. A project with no glossary yields **zero** `concept` nodes (Q14 item 2), so every
relation whose `endpoint_kinds` require a `concept` simply produces no rows — the absence shows up as an
empty result and as an `absent` status in FR-9a's coverage notes, not as an edge nobody can type. Narrowing
`endpoint_kinds` to what a given project contains would convert that graceful degradation into a hard limit
on what any *other* project could express, which is precisely the error Q10 identified. So the rule is stated
as a rule: **`endpoint_kinds` declares what the relation *means*, never what a particular repository
*contains*.**

#### D8. Stated coverage limit: the standards' agent half has no expressible endpoint

Recorded here rather than omitted, because a reader comparing this vocabulary against the six standards will
notice the gap and should find it named.

PROV-O's Agent and Activity classes and every property whose domain or range is one of them
(`wasAttributedTo`, `wasAssociatedWith`, `actedOnBehalfOf`, `wasInformedBy`, `wasStartedBy`, `wasEndedBy`),
CiTO's author-network family (`sharesAuthorsWith`, `sharesAuthorInstitutionWith`, `sharesFundingAgencyWith`),
and DCMI's agent terms (`creator`, `contributor`, `publisher`, `rightsHolder`) are all **unexpressible in this
vocabulary** — not because they were judged unimportant, but because §5.2's `Kind` enum contains no value
denoting a person, an organisation, an agent or a process run. An entry declaring
`endpoint_kinds: ["document->agent"]` would fail W1 on the enum, and there is no honest way to land such a
relation on one of the seven kinds that exist.

The consequence is worth stating plainly: **this graph cannot answer "who wrote this" or "which run produced
this".** That is a bounded and deliberate limit of the node model (Q12, Q14), not of the standards traversal.
Adding a `person` or `agent` kind would be a requirements change touching §5.2's enum, §5.3's id grammars,
feature-003's pairing table and feature-004's enumeration, so it is routed to the work owner (Open Item 10)
rather than absorbed.

#### D9. Worked examples — the ten-column shape (AC-S6)

Four rows, in §5.2's **ten**-column order — `Source Id | Source Kind | Source Name | Target Id | Target Kind |
Target Name | S2T Relation | T2S Relation | Provenance | Observation` — covering §5.1's three relationship
sources plus the `image-reference` mapping. Every id and name follows feature-003's grammars (D2, D2a-1,
D2a-2, D2a-3) and display-name rule (D5); every relation label is from D6.

All four are built on content verified on disk in this repository on **2026-07-29**: `.aid/knowledge/` holds
**21** top-level `.md` documents; `domain-glossary.md` line 270 carries `### AID_HOME`;
`technology-stack.md` line 72 carries ``CONFIRMED `README.md` (search: "PowerShell 5.1+")``;
`docs/aid-methodology.md` line 174 carries `![…](images/3-ironman.png)` and `docs/images/3-ironman.png`
exists; and `.aid/knowledge/external-sources.md` records `**Status:** No External Sources` with no registered
keys.

**1 — KB-to-KB, and specifically KB-to-concept, which the superseded vocabulary could not type at all:**

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| `kb:domain-glossary.md#aid_home` | `section` | `domain-glossary.md § AID_HOME` | `kb:concept:aid-home` | `concept` | `AID_HOME` | `defines` | `defined-by` | `declared` | |

*Why this row is the one to look at first.* Under the prefix-keyed form this row's endpoint pair was
`"kb:->kb:"` — indistinguishable from a section that merely mentions the term. Under the kind-keyed form it is
`"section->concept"`, and `defines` declares that token while `mentions` also declares it, so V12 accepts
both and V12's precision now rests on the relation rather than on the prefix. Note also that the section slug
`aid_home` retains its underscore while the concept term `aid-home` folds it, exactly as feature-003
D2a-1 records — two different normalisations of one heading, by design.

**2 — KB-to-source, on the `fact` kind and the evidence category:**

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| `kb:technology-stack.md#fact:readme-md--powershell-51` | `fact` | `technology-stack.md § PowerShell 5.1+` | `int:README.md` | `source-artifact` | `README.md` | `cites-as-evidence` | `cited-as-evidence-by` | `declared` | |

*The fragment is illustrative of feature-003 D2a-2's output, not a second definition of it.* That algorithm
composes `<path-slug>--<anchor-slug>`, and the token shown is what its steps yield for this anchor; the
authoritative token is whatever `rel_fact_tokens` computes, and V2 recomputes it rather than trusting the
table. This row is also why `cites-as-evidence` is separate from `cites`: the `CONFIRMED … (search: "…")`
carrier is what makes this node a `fact` at all (Q13), so typing it as a generic citation would erase the
distinction the fact kind exists to carry.

**3 — KB-to-external, which this repository cannot instance, and is therefore shown against the Q4 fixture:**

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| `kb:domain-glossary.md` | `document` | `domain-glossary.md` | `ext:wcag-22-aa` | `web-page` | `wcag-22-aa` | `cites` | `cited-by` | `declared` | Fixture key; this project's external-sources file registers none |

*This is the row the superseded research reasoned backwards from.* Its evidence file recorded that the
external half of the vocabulary was closed with no real instance to test against, and the response was to
narrow. The response here is the opposite and is the rule of § Feature Flow step 6: the `ext:` branch is
demonstrated against the self-built synthetic fixture that Q4 resolved and A-6 requires to be self-built, and
**every relation whose endpoints include `web-page` is kept regardless**, because `external-sources.md`
having no entries is a fact about this repository and not about the relation.

**4 — the `image-reference` mapping (D6c), on real content:**

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| `int:docs/aid-methodology.md` | `source-artifact` | `docs/aid-methodology.md` | `int:docs/images/3-ironman.png` | `image` | `docs/images/3-ironman.png` | `illustrated-by` | `illustrates` | `declared` | |

*Three things this row pins.* The `image` kind sits on the `int:` prefix here, which feature-003 D1a permits as
a **set** of prefixes rather than a single one — so the pairing check must not reject it, and the same relation
with an `ext:` image would also be legal. The kinds are `source-artifact->image`, which is one of the four
tokens `illustrated-by` declares; the `document->image` token on the same relation is produced by a different
feature entirely, which is the multi-producer case D3a's W3 report surfaces. And the row assumes
`docs/aid-methodology.md` qualifies as a `source-artifact` under FR-21's significance rule — **which is
feature-004's determination, not this SPEC's**. If it does not qualify, the relation and its endpoint token are
unaffected; only this illustration would need a different citing file.

### Feature Flow

The research method, as an ordered sequence. It is reading, naming, and self-testing — no product code
changes, consistent with the RESEARCH task-type rules at
`.claude/skills/aid-execute/references/task-type-rules.md` § RESEARCH ("No code changes to the project —
research produces documents only").

**Step 1 — Fix the frame.** Read REQUIREMENTS.md §5.1 (the three relationship sources), §5.2 (the **ten**
columns and the `Kind` enum the names and endpoints land in), §5.3 (the per-kind id grammars), §5.4
(FR-4, FR-4a, FR-5, FR-6, FR-6a, FR-6b), §5.5 (FR-8a genericity), §5.8 (which pass may emit what), and
STATE.md Q10–Q15. Read **feature-003's SPEC** for the loader contract this vocabulary must satisfy and
**feature-004's SPEC** for which non-KB nodes exist and which observation kinds need a relation. Read
`.aid/knowledge/domain-glossary.md` so a relation name does not collide with an existing Concept Spine term.

**Step 2 — Traverse the standards, before naming anything.** For each of D1's six standards in turn, read the
specification itself — not a summary — and record, per candidate term: its local name verbatim, its declared
inverse if the standard declares one and the clause where it does so, whether the standard declares it
symmetric or transitive, and the version string read from the document. This is the step the superseded
research skipped entirely, and it is deliberately **before** any contact with this repository's content, so
that the vocabulary's shape is set by what relations exist in general and not by what carriers exist here.

**Step 3 — Group the recorded terms into families, then into categories.** The families are the recurring
relation shapes the traversal surfaces — part–whole, concept hierarchy, versioning and supersession,
provenance and derivation, requirement, representation and format, depiction, implementation and testing,
definition and exemplification, identity and similarity, contradiction and support, sequence, alternatives,
annotation. Categories are then chosen on the **relation-nature** axis under the D5 constraints, and the
resulting **count is recorded as a finding** (FR-6b) rather than allowed to emerge.

**Step 4 — Name each family's pairs in the AID lexical form.** Lowercase, hyphen-separated, active-voice.
Naming is **per pair, never per direction**: a relation is never admitted without its inverse in the same
edit, and both halves are written together so property 1 cannot be broken by a half-finished thought.

**Step 5 — Screen each candidate. A type is admitted only if all three hold.** *(Three tests, up from two;
the first is rewritten and the third is new.)*

1. **It has a standards antecedent** among D1's six — recorded in `derived_from`. Not "it seems useful", and
   not "an instance of it exists here". A candidate with no antecedent is either dropped or raised as an Open
   Item reporting a coverage gap in the standards; it is never admitted with a stretched citation and never
   with `coined`, which the core forbids.
   **And the antecedent must *mean* what the entry's `definition` says, read in the entry's own direction.**
   Strengthened 2026-07-29, because this step as previously written is the screen the whole
   citation-semantics round got past: a ban on "stretched citations" with no procedure behind it checks
   existence and nothing else. The procedure is now three questions per token, asked against the fetched
   standard rather than from memory — does its **wording** assert what the definition asserts; does it run
   **source → target** as the entry reads it; and is its **other argument** a node of a kind the entry
   declares? A token failing any one is dropped, replaced by a same-family token that passes, or retained
   with an explicit flag. The outcome for all 64 delivered tokens is the audit at **D6d**, whose totality
   AC-S2 checks.
2. **No already-admitted type's `definition` covers the same assertion.** Where two candidates overlap,
   either merge them — recording the merge and its reason, as D6b does — or sharpen both definitions until an
   author cannot reasonably pick either.
3. **Its endpoints are expressible over §5.2's seven kinds.** A relation with no legal `<kind>-><kind>` token
   cannot be typed on any row and must not be admitted. This is the test that keeps D8's coverage limit
   honest: the agent-directed properties fail it, and they are recorded as a stated limit rather than
   admitted with an endpoint set that would never resolve.

Comprehensiveness beats brevity (FR-5), so the bar for **adding** is low — but the bar for adding a type whose
meaning duplicates another is absolute, because two interchangeable types reintroduce exactly the ambiguity a
named set exists to remove.

**Step 6 — Verify expressibility against a real repository, without narrowing. This step is the correction.**
For each admitted entry, attempt to exhibit one instance in a real repository — this one — using only carriers
that are **AID Knowledge Base authoring conventions** (frontmatter fields, the citation rule, glossary
definition markers, headings) or git-native facts, never this repository's particular content. Then:

> **An entry this repository cannot instance is kept, and the inability is recorded as a fact about the
> repository.** Failure to instance is **never** grounds for removing an entry, for narrowing its
> `endpoint_kinds`, or for reducing its `passes`.

The superseded research inverted this rule, recording decisions of the form "keep `["int:->int:"]` only — the
only harvested instance is script→data file". Under FR-8a that is not merely suboptimal, it is a violated
requirement: no relation type, node kind, extraction carrier or threshold may be defined by what this project
happens to contain. The rule is stated as a rule, in the file's header comment as well as here, because it is
the one that has already been broken once.

**Step 7 — Author the single source.** Write the vocabulary file (§ Layers & Components): the `pairs:` entries
in the eight-key contract, the `categories:` block, and the header comment block carrying the field contract,
the standards table, the worked examples, the step-6 rule, and the addition process. **Both halves of every
asymmetric pair are written in the same edit**, with the inverse's `endpoint_kinds` transposed and its
`definition` authored from the inverse reading. This is execution work; no part of it happens in this SPEC,
and no part of it edits `relation-vocabulary.yml` before the task that owns it runs.

**Step 8 — Self-test the six properties by loading the file, not by reading it.** Closure, totality (eight
keys), involution, symmetric consistency, category totality, and pair coherence — over the core alone, and
then over the core plus each extension fixture (AC-S1, AC-S5, AC-S9). This is what makes the set
"machine-readable, not only prose". The check is small and deterministic, so it belongs with the other
canonical validators rather than in skill prose (KB `decisions.md` D17 — "only non-trivial, reused,
deterministic operations are extracted to `canonical/aid/scripts/`"); **feature-003 owns implementing it**,
since it owns validation, and Open Items 1–3 record what its loader must gain.

**Step 9 — Demonstrate sufficiency and satisfiability.** Produce the four worked ten-column rows of D9
(AC-S6), and produce the **endpoint-satisfiability report** of D3a's W3 (AC-S10) so that every declared token
is accounted for as `producer`, `inferred-only` or `unreachable` before the vocabulary is accepted.

**Step 10 — Record and hand off.** Two outputs land in two different places, and the split is not incidental
— see § Layers & Components.

**Consumers.** Who reads the vocabulary, and for what:

| Consumer | Reads | To do what |
|----------|-------|-----------|
| feature-003 | `relation` + `inverse` of every merged `pairs:` entry, plus `endpoint_kinds` and `symmetry`, via its own `rel_load_vocabulary` (D4/D9) | Decide AC-2 — `V3` membership on both relation labels, `V4` valid inverse pair — without human judgment. `symmetry` lets `V4` accept a self-inverse pair as declared rather than as a tolerated accident. `endpoint_kinds` drives `V12`, now **kind**-keyed and still advisory, plus W4's declared-but-unobserved report |
| feature-005 | `relation`, `inverse`, `passes`, `endpoint_kinds` — same loader | Resolve `edge-relation-map.yml`'s right-hand `s2t` label to an entry, look `t2s` up as that entry's `inverse` (its D3), bound which types each pass may emit, and type the `image-reference` observation as `illustrated-by` (D6c) |
| feature-006 | `relation` + `category` | Evaluate its D2 coverage predicate over its `coverage_bearing` subset. With `evidence` and `documentation` now **separate** categories (D5), the choice of subset is an explicit selection rather than an emergent one; feature-006 selects the members, this feature only supplies the categories they are drawn from |
| feature-007 / feature-008 | `category` | Offer category as a grouping dimension (FR-6), as the required filter axis (FR-6a), and collapse to it for the Overview lens (FR-13); assign the eight colours over fourteen categories per D5a |
| feature-009 | `category`, `definition` | Group and label the accessible table's peer rendering identically (NFR-3), where the full relation name is always readable as text (NFR-5) |
| A human reviewer | `derived_from` | Challenge a definition against the standard it claims, which is the whole editorial purpose of the field |

Every consumer reads through **one** loader — feature-003 D9's `rel_load_vocabulary` in
`canonical/aid/scripts/graph/relationship-schema.sh` — never by parsing the file itself. That is what keeps
feature-003 D4's reviewable invariant true, and AC-S11 states it as a checkable criterion: no relation label,
category name or standard key appears in any `graph/` script, so a reviewer can prove the vocabulary is
opaque data by grepping the script tree and finding nothing.

### Layers & Components

#### Two outputs, two homes

| Output | Path | Lifetime |
|--------|------|----------|
| The **research report** — the standards traversal record, the family map, the merges and their reasons, the step-6 instance attempts including the failures, the endpoint-satisfiability report, and the rejected alternatives | the path named in the RESEARCH task's `Scope` field, under `.aid/works/work-005-knowledge-graph/` (assigned by `/aid-detail`, per `task-type-rules.md` § RESEARCH "Write findings to the path specified in task Scope") | **transient** — disposable with the work folder |
| The **vocabulary file** — the core set both the generator and the validator load | `canonical/aid/templates/graph/relation-vocabulary.yml`, plus its five profile renders | **permanent** |

This split is mandatory, not stylistic. `CLAUDE.md` § "Tracking discipline" states that work folders are
transient and that "no permanent artifact — product code, `canonical/` content (or its `profiles/` render),
tests, docs, the Knowledge Base, or these context files — may depend on the contents of a specific work
folder". The vocabulary is loaded at runtime by shipped scripts, so it cannot live in the work folder; the
report is pipeline evidence, so it can.

**One consequence the standards traversal creates and this split absorbs.** The traversal record is large —
six specifications, their versions, their clause numbers, and the per-term inverse and symmetry declarations —
and it is the evidence behind every `derived_from` token. It lives in the **report**, which is transient,
while the token itself lives in the **file**, which is permanent. That is the right division (a `.yml` cannot
carry a bibliography) but it means the permanent artifact's justification is disposable, so the file's header
comment carries D1's standards table — the six names, versions and URLs — in full, so a reader of an installed
profile can resolve any token without the report.

#### Where the single source lives

Requirement FR-4 plus AC-S1 mean the generator and the validator must read **one** core file. That file
satisfies the properties below. **All four are unchanged from the previous revision**, including the render
analysis, because the carrier and the renderer did not change — only the file's contents and its entry shape
did.

- **P1 — Canonical-authored.** It lives under `canonical/` and is rendered to every host profile by the
  existing generator (C-2; `infrastructure.md` § "The Build: Multi-Profile Render"), never hand-maintained
  per profile.
- **P2 — Rendered to every install tree as a runtime-loadable data file.** Precedent verified on disk
  2026-07-29: `canonical/aid/templates/shortcut-catalog.yml` is a machine-consumed YAML data catalog that
  renders to all **five** install trees (`profiles/antigravity/.agent/`, `profiles/claude-code/.claude/`,
  `profiles/codex/.codex/`, `profiles/copilot-cli/.github/`, `profiles/cursor/.cursor/`, each at
  `aid/templates/shortcut-catalog.yml`), and `canonical/aid/templates/settings.yml` is a second `.yml` in the
  same directory. So a YAML data file that a script loads at runtime is an established shape here, in exactly
  the directory this file goes to.
- **P2a — Copied verbatim, because `.yml` is not text-transformed.** A `.yml` is copied byte-for-byte, so
  nothing in it is rewritten — and nothing in it is *fixed up* either. The consequence that binds: the file
  must carry **no path that has to resolve at runtime**.
- **P3 — One file, both faces.** The machine contract and the human definitions are the *same* file — the
  entries carry the contract, the header comment block carries the standards table, the definitions and the
  process — so they cannot drift.
- **P4 — Registered in the emission manifests.** Every canonical file emits one record per profile
  (`canonical/EMISSION-MANIFEST.md` § "Record Schema"), and the render-drift gate re-runs the full generator
  and diffs `profiles/` — so the file is added by running the full generator, never by hand-editing a profile
  copy.

**The path is `canonical/aid/templates/graph/relation-vocabulary.yml`** — the same path features 003, 004 and
005 already specify, and the file exists on disk today with the correct **mechanism** and superseded
**contents**.

**Ownership, restated because the re-specification changes the split slightly.** *This* feature owns the core
vocabulary's schema **and** its content — which relation types exist, what each field means, each field's
value rule, and the category set — and creates the core file. Feature-003 owns the **loader and validation
contract** and explicitly does not create the file. What is new is that this revision **changes feature-003's
entry contract in two places** (an eighth key, and a re-keyed token grammar) and **adds one property to its
loader**, so the boundary is now a two-way dependency in practice: this SPEC decides, feature-003 enforces,
and Open Items 1–4 name every enforcement change so neither side can drift. The `graph/` script tree contains
no relation label either way (AC-S11), which is what keeps the vocabulary opaque data despite the coupling.

Two consequences of YAML rather than Markdown, both unchanged and both deliberate:

- **No frontmatter, and no `lint-frontmatter.sh` exposure.** A `.yml` data file carries no YAML frontmatter
  block, so the toolkit-template frontmatter style does not apply here; `shortcut-catalog.yml` likewise
  carries none, its equivalent metadata being the header comment block. The KB-document required set never
  applied either: this is not a `.aid/knowledge/` document.
- **Data and documentation share the file via comments, not sections.** See § What the header comment block
  carries.

#### The render-time path rewriter, for `.yml`

**Unchanged from the previous revision, and re-confirmed rather than re-derived.** `render.py` declares the
transform set and applies it by suffix:

```python
# Extensions that receive text transforms (substitute_filenames + rewrite_install_paths)
_TEXT_EXTENSIONS = frozenset({
    ".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css", ".py",
})
```

and, in the copy loop, `if src_file.suffix.lower() in _TEXT_EXTENSIONS:` applies `substitute_filenames` then
`rewrite_install_paths`, `else: encoded = src_file.read_bytes()`. `.yml` is **not** in that set, so a `.yml`
takes the `else` branch — a verbatim byte copy. `shortcut-catalog.yml`'s own header states the rule from the
other side: it "Renders as VERBATIM BYTES … a `.yml` is not in render.py's `_TEXT_EXTENSIONS`".

So the hazard is not *"a path in this file may be rewritten unexpectedly"*; it is **"a path in this file will
never be rewritten, and there is no `canonical/` directory in an installed profile for it to point at."** The
rules that follow, now checked against the **eight**-key entry:

1. **No entry field may contain an install-relative path.** None does, and the eighth key does not change
   this: the eight fields are two labels, two closed enums, one closed-vocabulary token list, one
   kind-token list, one pass list, and one sentence of prose. `derived_from` carries standard names and term
   names, never paths or URLs — the URLs live in the header comment, where nothing resolves them.
2. **Worked examples live in comments and are illustrative only.** An `int:canonical/…` id in a comment
   survives verbatim into all five profiles, where that path does not exist. Nothing resolves a comment, so
   it is safe, but it must read as an example rather than as an instruction. D9's four rows are the examples
   the header carries, and three of the four use paths that exist in an installed tree or in a fixture.
3. **`substitute_filenames` does not run either**, so the file must use no `{placeholder}` tokens.

One benefit worth recording: verbatim copying makes the file **byte-stable across profiles**, so a vocabulary
edit produces exactly six changed files — the canonical source and five identical renders — plus the five
`sha256` updates in the emission manifests, and the render-drift gate compares one byte-stream against five
copies of it.

#### The parse contract

**Owned by feature-003 D4 and consumed here.** The restricted-YAML subset — one key per physical line, fixed
key order, flow-only lists, no anchors or aliases or merge keys or block scalars or second document, comments
and blank lines anywhere — is feature-003's, and this SPEC does not restate its clauses. What this SPEC adds
to it is exactly two things, both recorded as Open Items so the loader and the file cannot diverge:

- an **eighth key**, `derived_from`, at position 5 of the fixed order (D2);
- a **re-keyed** `endpoint_kinds` token grammar, validated against `relationship-schema.yml`'s `kinds:`
  rather than its `prefixes:` (D3).

The file shape, with the eighth key in place and values illustrative:

```yaml
pairs:
  - relation: documents
    inverse: documented-by
    symmetry: asymmetric
    category: documentation
    derived_from: ["cito:documents", "schema:about", "iana:describes"]
    endpoint_kinds: ["document->source-artifact", "section->source-artifact"]
    passes: [declared]
    definition: "The source is an authored record of the target, written by drawing on the target for its factual content."

categories:
  - "documentation|One node records or names facts about the other."
```

`derived_from` tokens are **always double-quoted**, for the same reason `endpoint_kinds` tokens are: a token
contains a `:`, which a plain scalar in flow context cannot carry safely. That the two list-valued keys share
one quoting rule is convenient rather than accidental — it means the loader's flow-sequence scanner needs no
per-key special case.

**Entry ordering.** Entries are authored sorted by `category`, then `relation`, so a vocabulary change shows
as a readable diff, and `categories:` is authored sorted by name. feature-003 D4 records that the loader
neither requires nor checks this, because membership and pairing are order-free; it remains an authoring
convention and § How a proposed addition is reviewed is where it is enforced.

#### What the header comment block carries

YAML has no sections, so the human half of P3 lives in the header comment. It carries, in this order:

| Content | Why there |
|---------|-----------|
| The **eight-key field contract** and the enum values | It is what an author needs before editing, and `shortcut-catalog.yml` sets the precedent of a header carrying the full per-field contract |
| **D1's standards table** — the six keys, standard names, versions and URLs | The `derived_from` tokens are unresolvable without it, and the research report that justifies them is transient (§ Two outputs, two homes) |
| **D6d's fifteen flagged tokens**, one line each: entry, token, flag class | *Added 2026-07-29.* A header carrying only the six URLs tells the next editor where to look and not what was already found there — which is how a mis-directed token gets re-added by someone doing the diligent thing. Fifteen lines is the cheapest possible defence against repeating this round |
| The **fourteen categories** with their one-line meanings | Duplicated deliberately as prose alongside the `categories:` data, because the meaning is what an author picking a category needs and the data form is optimised for the loader |
| The **step-6 rule** — an entry this repository cannot instance is kept | It is the rule that was broken once; putting it where the next editor will read it is cheaper than trusting a SPEC in a transient work folder |
| **D9's four worked rows** | Illustration, not data: no consumer reads them, and a ten-column markdown row cannot be a YAML value without quoting that would make it unreadable |
| The **addition process** and the **consumer list** | Process prose, not data — the same shape `shortcut-catalog.yml` uses for its own "then run the FULL `run_generator.py`" rule |

#### How a proposed addition is reviewed

The core is shipped and closed to redefinition, so "closed" has to mean something procedurally:

1. A proposal is a change to the single canonical core file — never a row in `relationships.md` carrying an
   unlisted term, and never a local override. A project-specific type goes in the **extension** file instead
   (D7), which is the one legitimate second place and is add-only by construction.
2. It arrives as a pair — two entries, or one self-inverse `symmetry: symmetric` entry — with all **eight**
   keys filled. The **Step 5 screen applies to additions forever**, not only at first authoring: a standards
   antecedent recorded in `derived_from` **that the proposer has read in the live standard and shown to mean
   what the new `definition` says, in the new entry's direction** (step 1's three questions, D6d), no
   definitional overlap with an admitted type, and endpoints expressible over §5.2's kinds. A new `category`
   value means a `categories:` entry in the same edit, or property 5 fails; and a token not already in D1's
   in-scope column means adding it there in the same edit, or AC-S2's closure fails.
3. It passes the Step 8 property self-test — all **six** properties, over the core alone and over the core
   plus the extension fixtures.
4. Its declared `endpoint_kinds` appear in the Step 9 satisfiability report with no `unreachable` token, or
   with each `unreachable` token argued for in the review.
5. The **full** profile generator is re-run and the render-drift check passes, so all five profile copies and
   their emission manifests move together (`infrastructure.md` § "The Build: Multi-Profile Render").
6. It goes through the project's normal review gate for a canonical edit — a reviewer ledger at
   `.aid/.temp/review-pending/<scope>.md` in the seven-column shape, graded by `grade.sh`
   (`quality-gates.md` § "The Reviewer Ledger").

**Adding is cheap; removing and renaming are not.** Adding a pair leaves every existing `relationships.md` row
valid. Removing or renaming one invalidates rows — but `relationships.md` is a *generated* artifact (FR-9,
and the `--reset` regeneration path in FR-11), so the remedy is regeneration, not data migration. That
asymmetry is the reason FR-5's "comprehensiveness over brevity" is safe to follow: an over-large vocabulary
costs review attention, whereas an over-small one forces free text into the relation columns and destroys the
named-set guarantee outright.

**One asymmetry the extension does not share.** A project may add to its extension freely, but it may not
remove a **core** pair to make room — FR-4a permits addition only. A project that finds a core pair actively
wrong should raise it against this feature rather than working around it, because a locally-suppressed core
pair would make two AID projects disagree about what a shipped name means, which is the one property the
core/extension split exists to guarantee.

#### Artifacts to update on adoption

Not this feature's writes — recorded so the obligation is not lost:

| Artifact | Update | Owner |
|----------|--------|-------|
| `.aid/knowledge/artifact-schemas.md` | Add `relationships.md` and the relation-vocabulary contract to the artifact schema set, per that doc's § "Conventions" rule for adding an artifact type. **The contract to document is now the eight-key entry with kind-keyed endpoints**, not the seven-key prefix-keyed one | feature-013's ship-time KB update |
| `.aid/knowledge/domain-glossary.md` | Only if the research coins a term that belongs to the Concept Spine; relation names themselves are data values, not spine concepts. **Two candidates this revision creates**: the core/extension split and the `derived_from` attribution rule are both project-level concepts a reader would look up | feature-013's ship-time KB update |
| `profiles/*/emission-manifest.jsonl` | One record per profile for the canonical file — produced by running the full generator, never hand-edited | feature-012 |

No entry in `canonical/aid/templates/generated-files.txt` is warranted: that registry lists files regenerated
during `/aid-discover`'s FIX state, and the vocabulary is an authored source file, not a generated one.

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the methodology, that
owner is named and the item is **not** absorbed here. Items 1–4 are the enforcement changes this
re-specification creates and are the only ones that must land before the vocabulary can be loaded as
specified.

1. **The vocabulary entry grows from seven keys to eight.** `derived_from` is added at position 5 of the fixed
   key order (D2), so feature-003 D4's entry table, its "all seven keys are validated" rule, its per-rejection
   -class fixture set, and D9's `rel_load_vocabulary` contract line all move to eight. The change is
   mechanically small — one row, one count, one more required-key check — and it is not optional: FR-5 makes
   per-term attribution a required field, and a loader that tolerated its absence would let a core entry ship
   with no standard behind it, which is the exact defect this re-specification exists to make impossible.
   **Owner: feature-003.**
2. **`endpoint_kinds` is re-keyed from the three id prefixes to §5.2's seven `Kind` values, which closes
   feature-003's Open Item 12.** The loader validates each token as `<kind>-><kind>` against
   `relationship-schema.yml`'s `kinds:` list — which `rel_load_schema` already loads — rather than against
   `prefixes:`. This is one value rule replacing another over an enum already in memory, and it *removes* a
   second copy of a closed set rather than adding one (D3). **Owner: feature-003.**
3. **A sixth cross-entry property, pair coherence, is added to the loader.** For every asymmetric pair the two
   entries must agree on `category`, `derived_from` and `passes` and their `endpoint_kinds` sets must be exact
   transposes; for every symmetric entry the set must be closed under transposition (D4 property 6). It is a
   gating file-level check like the other five, decidable from the vocabulary files alone, and it is what
   makes the 49-token space safe to author (D3a layer W2). **Owner: feature-003.**
4. **V12 is re-keyed and gains a second, complementary report.** The advisory endpoint check now compares a
   row's `(Source Kind, Target Kind)` pair against `endpoint_kinds` — strictly more precise than the prefix
   pair, and it costs nothing extra because V13 already computes both kinds per row. The addition is the
   other direction: **declared tokens no row exercised**, accumulated as a set difference over rows already
   parsed (D3a layer W4). Both stay advisory, for the reasons feature-003 already records — AC-2 is scoped to
   membership and inverse consistency, and FR-25/FR-28 forbid gating on properties of the Knowledge Base the
   skill may only observe. **Owner: feature-003.**
5. **The `image-reference` relation mapping is settled here; wiring it into the edge-relation map is
   feature-005's.** `image-reference` maps to `illustrated-by` / `illustrates`, with the direction,
   `endpoint_kinds` and `passes` legality stated at D6c. What remains is the map row itself in
   `edge-relation-map.yml` and the Pass 1 producer for the `document->image` and `section->image` tokens,
   which feature-004 cannot supply because it walks the project source only. This discharges the first half of
   **feature-004's Open Item 4**. **Owner: feature-005.**
6. **The endpoint-satisfiability report needs the producer map to exist.** D3a's W3 report is defined here and
   cannot be produced without feature-005's `edge-relation-map.yml`, which is the only enumeration of what
   produces which relation. The report is a report and never a gate, for the reason D3a states: a core
   vocabulary is deliberately larger than any one project's producers. Relayed in the same item: the second
   half of **feature-004's Open Item 4** — feature-005's four coverage rows should use feature-004 D7's
   `present`-iff-≥1 predicate so the coverage-notes section does not carry two definitions of `present`. That
   half is feature-004's finding, relayed unchanged and not adopted here. **Owner: feature-005.**
7. **Eight colours over fourteen categories — the assignment.** D5a supplies the finding (fourteen
   categories), the constraint (AC-8a's eight-colour bound, NFR-5's four line styles), the consequence (not
   simultaneously readable; legible only because FR-6a's filtering is required) and a **recommended set of
   eight** derived from FR-13's four lenses, with the basis stated. Choosing and contrast-checking the actual
   palette, and deciding the (colour, line-style) pairing for the remaining six categories, belongs to the
   view. **Owners: feature-007** (canvas encoding), **feature-008** (rendering), with **feature-009** needing
   the same category labels in the table view for NFR-3.
8. **`coverage_bearing` becomes an explicit selection rather than an emergent one.** feature-006 D2 needs "the
   pairs that mean 'this KB concept describes / is derived from this artifact'", and previously hoped a single
   category would already mean exactly that. Under D5 the candidates are three separate categories —
   `documentation`, `evidence` and `provenance` — which is a better outcome (the choice is now visible) but
   means feature-006 must state which it takes rather than inheriting one. This feature supplies the
   categories; selecting the subset remains feature-006's, as its own SPEC says. **Owner: feature-006.**
9. **The fifth staleness input must digest both vocabulary files.** FR-11 input 5 names the core **and** the
   extension, and FR-32/AC-5's byte-identity is stated over all five inputs. feature-003 supplies the
   `--vocabulary` / `--vocabulary-extension` loader overrides that let a test exercise a vocabulary change;
   composing both files into the staleness digest, and deciding how a *tool upgrade* is detected, is the
   staleness record's business. Relayed from **feature-003's Open Item 4**. **Owner: feature-010.**
10. **The standards' agent half has no expressible endpoint, and closing it is a requirements change.** D8
    records the limit: PROV-O's Agent and Activity properties, CiTO's author-network family and DCMI's agent
    terms cannot be expressed, because §5.2's `Kind` enum contains no value denoting a person, an
    organisation or a process run — so this graph cannot answer "who wrote this" or "which run produced
    this". Adding a `person` or `agent` kind would touch §5.2's enum, §5.3's id grammars, feature-003's
    pairing table and feature-004's enumeration. Raised so the limit is a decision rather than an oversight.
    **Owner: the work owner.**
11. **The rendering bench must exercise fourteen categories, not five.** feature-002's viability-and-
    performance validation encodes relationship category as colour plus line style (NFR-5) and must sustain
    NFR-7's floor with category **filtering** active (FR-6a), because filtering is what makes a fourteen-
    category graph legible (D5a) and is therefore part of the interaction being measured rather than a
    feature layered on afterwards. The superseded bench was built against a five-category vocabulary.
    **Owner: feature-002.**
12. **Two prose-only reference updates outside this SPEC.** PLAN.md and delivery-001's BLUEPRINT describe this
    feature's deliverable as a *closed* vocabulary of relation/inverse pairs, and delivery-001's gate criteria
    reference the seven-field entry. Q14's amendment-sequencing decision hand-amends PLAN.md rather than
    patching regenerated artifacts, so this belongs to that pass; nothing mechanical breaks in the meantime.
    **Owner: whoever performs the PLAN.md amendment.**
13. **Ship-time Knowledge Base updates.** `artifact-schemas.md` must document the **eight**-key entry with
    kind-keyed endpoints, and `domain-glossary.md` gains two candidate spine concepts (the core/extension
    split and the standards-attribution rule). Both were already routed to feature-013; the content they must
    carry is what changed. **Owner: feature-013.**
