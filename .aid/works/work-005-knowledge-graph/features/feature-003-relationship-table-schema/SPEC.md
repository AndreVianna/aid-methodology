# Relationship Table Schema And Validation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.2, §5.3, FR-1, FR-4, FR-9, §7 (C-7), §9 (AC-1–AC-4, AC-18); STATE.md Q1, Q3 | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned — Q1/Q3 recorded Resolved (eight columns, KB-indexed); stale nine-column and rework-warning text removed | /aid-specify |
| 2026-07-28 | Final-gate findings fixed — D4's two "residual mismatches with feature-001" and Open Items 6/7 removed: the ownership mismatch was already corrected in feature-001, and the encoding mismatch never existed (its record table specifies no encoding). Both restated as closed | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — vocabulary entry widened to feature-001's full field set, seven fields as of that date (D4, D9), ownership restated (feature-001 creates and authors the file; this feature owns only the loader/validation contract), advisory endpoint check V12 added | /aid-specify |
| 2026-07-28 | Gate finding 2 [LOW] fixed — `build-kb-index.sh`'s scan quoted accurately (bare `sort`, no `LC_ALL=C`) in D2a and the Feature Flow inputs; ordering claims re-grounded on this feature's own `LC_ALL=C` sorts (D7) | /aid-specify |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles; STATE.md Q9–Q15).** Both halves reworked, because the model this SPEC contracted was superseded on three axes at once: (1) the table is **ten** columns — `Source Kind` / `Target Kind` added by owner decision (Q14 item 3), voiding every eight-column assertion here including the old D1 header/delimiter grammar and the `contracts:` frontmatter line; (2) node identity is **per kind, not per prefix** — §5.3 now gives each kind in the enum its own grammar and resolution check, a `concept` id is deliberately **not** document-scoped, and the `int:` symbol-narrowing clause the old D2b preserved as a "deliberate tension" is **struck**, so V7 is redefined from *reject a narrowed id* to *reject any `int:` fragment*; (3) the relation vocabulary is **core + project extension**, not closed, so D4 gains a merge-and-collision contract (FR-4, FR-4a). Also: `Kind` is a second closed vocabulary needing a fail-closed load and a cross-consistency validator (AC-2a, new V13); `relationships.md` gains a `## Coverage notes` section that must coexist with FR-3 (FR-9a, AC-20, new V14); and FR-32/AC-5 byte-identity is rekeyed from "an unchanged repository" to "all of FR-11's staleness inputs unchanged". The six author-level decisions Q15 deferred here are made and made checkable: heading slugification (D2a-1), the `<anchor-token>` format (D2a-2), concept-label normalisation and same-label disambiguation (D2a-3), section-id stability under renames (D2d), row ordering over the new grammars (D7), and the extension file's location/format/precedence (D4). Reused unchanged: the inverse-pair properties, the restricted-YAML entry mechanism, and V1–V12's numbering and concerns. One new cross-feature finding raised, not absorbed: `endpoint_kinds` is keyed on the three id prefixes, which the widened `Kind` enum has made too coarse to state a relation's legal endpoints — feature-001's to re-key (Open Item 12) | /aid-specify |
| 2026-07-29 | **A+ gate findings fixed (4 rows: 1 HIGH, 1 MEDIUM, 2 LOW) plus the unverifiable-claim retraction, and one further defect found in the same sweep.** Row 1 [HIGH]: "block body" is given an explicit boundary in new **D2a-3a** — a heading's body runs to the next ATX heading of **any** level 1–6 — stated as a single-pass algorithm, justified (the rejected same-or-higher reading is not a partition, so one marker would mint a concept for every ancestor at level ≥ 3, silently and invisibly to V15), with the fenced-code guard confirmed to sit before **both** the boundary test and the marker test, and the rule traced concretely over `domain-glossary.md`'s duplicate `Concept Spine` group (the `##` at 69 is declined, the `###` at 214 qualifies, yielding three distinct ids and a plain-form concept resolution). Row 2 [MEDIUM]: D2a-2's truncation is restated as a four-step total algorithm whose **fallback is a hard cut at exactly 40 characters** when no `-` lies in range, with the collision handled by the existing ordinal. Row 3 [LOW]: the class-0 extraction is stated as new **D7b**, exposed as `rel_class0_block` in D9, named in Feature Flow step 8, and explicitly ordered after V10 because its single-pass prefix scan is sound only on a V10-passing table. Row 4 [LOW]: the two spec-authored criteria become **AC-S1** and **AC-S2**; the peer SPECs were checked first and **no convention exists to follow** — all twelve leave spec-authored criteria unlabelled — so `AC-S<n>` is introduced, collision-proof because every requirement id places a digit immediately after `AC-`. Unverifiable claim: the `_`-retention appeal to GitHub is **withdrawn and replaced by an on-disk instance** — `decisions.md` line 248's heading against its own line 52 Contents link — and the gate's premise that no KB heading contains `_` is corrected (two do). The remaining external-authority appeals in D2a-1 are retracted in the same sweep: fenced-code exclusion is regrounded on GFM semantics, non-ASCII deletion is restated as an unverified branch specified for genericity, and the duplicate-heading suffix is restated as an author decision with **no** on-disk verification and routed to feature-007 (new Open Item 14). **Found in self-review, not in the ledger:** D2a-1 step 5 said "replace each **run** of spaces", which contradicted all four verification instances the same section cites and would have emitted the wrong anchor for every heading containing a deleted character between spaces — corrected to one-for-one with no run collapsing, and the deliberate contrast with D2a-2's collapsing anchor-slug made explicit. Test and fixture rows extended for every new branch, including the level-4-nesting fixture this repository's KB cannot supply | /aid-specify |
| 2026-07-29 | **A+ reopened (STATE.md Q19) and fixed — coverage-note extra rows had no order, so AC-5's byte-identity guarantee was unachievable as written.** Found by **cross-feature reading, not by review of this SPEC**: the defect was invisible from inside any single SPEC and surfaced only once feature-003, feature-004 and feature-005 had each contributed rows — six of them across two producer files (`kb-coverage.tsv`, `coverage.tsv`) assembled by a feature-010 that is not yet re-specified. Filed as feature-005's Open Item 16, which correctly named this feature as owner of the ordering contract and declined to choose an order from outside it. Under the owner's standing rule (Q18 ruling 3, "if there is a defect, the A+ is false") the gated SPEC is reopened rather than defended. **The defect:** D7a permitted extra rows below each fixed block and had V14 "check the fixed part and ignore the rest", while D7 item 2 byte-compares the **whole** section — so the guarantee rested on an ordering this SPEC never stated. **Remedy chosen: define a total order (option 1), not exclude the rows from the comparison (option 2)**, because exclusion buys no simplification — mechanically excluding extra rows requires the same row-key identification that sorting them requires — while discarding real drift-detection value over counters feature-005 built to be byte-stable, and leaving a determinism claim that nothing validates. New **D7a-1** states the rule: per table, fixed rows first and contiguous, then extra rows as a contiguous block in **`LC_ALL=C` ascending order of their first-cell key**, keys constrained to D2a-3's `[a-z0-9-]` charset, unique within the table and never equal to a fixed key. Totality is the same argument the gate already accepted for D7 — a single-component sort made total by a uniqueness rule (there V5, here the key-uniqueness clause). Keying on the row rather than on its producer file or a declared rank makes feature-010's assembly order **unobservable** (the six known keys interleave the two producer files when sorted) and makes a new row a **one-line** insertion that moves nothing else. The open set is answered by AC-5's already-amended scope: a new row ships in a tool upgrade, and FR-32 is keyed on all of FR-11's staleness inputs unchanged, so the upgrade boundary is one across which AC-5 asserts nothing — visible attributable churn, not drift, and not an exception carved out of the scope. **V14 now enforces all six clauses** (contiguity, charset, no fixed-key collision, uniqueness, recomputed sort order, cell count) and its no-timestamp check is stated to cover extra rows; it recomputes the sort and compares it to the file, exactly as V10 does for the relationship table. New **AC-S3** makes the order citable; new **Open Item 14** routes the assembly obligation to feature-010. feature-005's decision to pack three counters into an existing row's `note` is preserved as the cheaper path, deliberately: the row set is a coordinated namespace requiring a unique validated key, a `note` is not. **D7 item 2, D7b, and the whole-section comparison are unchanged**, as are the ten-column contract, the Kind-independent grammar, the parser-stops guarantee, the total row order, the block-body algorithm, slugification, the anchor-token format, concept normalisation, and V1–V13/V15 | /aid-specify |
| 2026-07-29 | **Ledger row 6 [LOW] fixed — D7a-1's wave-3 justification cited a mechanism that did not exist, and the count-as-proxy sweep it triggered.** The conclusion was right and the premise was false: the paragraph argued that a new coverage row is safe because "FR-32 is keyed on FR-11's staleness inputs **and the tool is one of them**", when FR-11 then listed only the KB, the project source, the external-sources file, `.aid/settings.yml` and the vocabulary — the coverage-producing scripts were none of them, so a tool upgrade fired no staleness check at all. That is the more dangerous shape of error, since a sound conclusion on a false premise survives review and fails only when someone relies on the premise. FR-11 has since gained **input 6, the tool itself** (version string where exposed, else a digest over the installed scripts and templates that affect output) — the third extension of that set after inputs 4 and 5 — and the justification now cites it, keeping the conclusion: a new row is not a breaking change to this contract, while adding one **silently within** a tool version breaks AC-5. The correction is recorded inline rather than silently overwritten. **Q17 sweep, per the same instruction:** every hardcoded count standing in for an externally-owned set is removed — FR-11's inputs in seven places (§Source ×2, AC-5, D7's scope note, D8's digest, D9, Open Item 4), feature-001's vocabulary entry keys and cross-entry properties (D4 ×7, D9), §5.2's `Kind` enum cardinality (D4, Open Item 12), and the profile set (Layers). A standing rule is now stated under D7's AC-5 scope: cite the set, or enumerate it locally and make the enumeration authoritative — never a numeral. Counts that **are** the contract rather than a summary of one are deliberately kept, D1's ten columns being the case in point, as are historical counts in this log and counts of items enumerated on the spot. **Open Item 4 extended** to name tool-upgrade detection as what operationalises input 6 and therefore D7a-1's open-set argument, with the two detection forms and the digest's file scope called out as feature-010's to settle. Nothing else touched | /aid-specify |
| 2026-07-30 | **A+ reopened (STATE.md Q20) and fixed — the loader as specified would have rejected the vocabulary it exists to load.** Nothing inside either document was wrong: feature-001 was re-specified and re-gated *after* this SPEC was gated, and the **four** loader changes it routed here (its Open Items 1–4, SPEC.md:1527–1550, each stamped "Owner: feature-003") went unscheduled across two intervening reopens — so this SPEC still specified a **seven-key, prefix-keyed** entry against a vocabulary now shipping an **eight-key, kind-keyed** one, and would have exited 2 on an unknown key and on totality. **None of the four was in this SPEC's ledger**, which is Q20's standing correction: before a re-gate, check the SPEC's inbound open-item queue, not only its ledger. Reconciled against feature-001 as a **fixed input**, not against the requirements alone. **(1) The eighth key** — `derived_from` **inserted at position 5**, not appended, per feature-001 D2's rule that new keys go before `endpoint_kinds` and never after `definition` (:318–324). Of that field's four value-rule clauses the loader enforces three in full and the token grammar **less its standard-key membership**: `coined` forbidden in a **core** entry is the mechanical half of FR-5 and is decidable here because the loader knows which of its two files each entry came from, while hardcoding the standard keys would put one inside this feature's shipped `graph/` tree, which feature-001's **AC-S11** forbids — so that residual is stated inline and left to **AC-S2**'s audit rather than pretended away. **(2) `endpoint_kinds` re-keyed** from the id prefixes to §5.2's `Kind` values, validated against the `kinds:` list `rel_load_schema` already loads — one value rule replacing another over an enum already in memory, which *removes* a second copy of a closed set rather than adding one. This **closes Open Item 12**, routed out by this SPEC and answered by feature-001; the item is kept in place with its number, which feature-001 cites four times. The stale worked value and the note asking whose call the token form was are **resolved**, not left standing as an open question. **(3) Pair coherence — the sixth cross-entry property**, gating by the same line the other five pass (decidable from the vocabulary files alone; feature-001's layer W2) and stated in **AC-S5**'s terms. Its symmetric clause is **vacuous on the core as delivered**, so AC-S9's two negative fixtures are all that stands between it and untested code — the same argument as this SPEC's `image` + `ext:` fixture — plus one fixture per **agreement** clause, since a loader checking only transposition would pass all three. **(4) V12 re-keyed and given a second direction** — per row, the `(Source Kind, Target Kind)` pair instead of the prefix pair, free because V13 already computes both kinds; per run, the declared tokens **no row exercised**, as a set difference over rows already parsed. **Both stay advisory** (AC-2's scope; FR-25/FR-28; and gating the second would forbid the comprehensiveness FR-5 requires), and V12 is **re-keyed, not renumbered** — V1–V12's numbering invariant holds. **Already discharged by the Q17 count-as-proxy sweep and therefore not re-fixed:** the entry table's preamble, the "every declared key is validated" rule, the cross-entry-invariant bullet and D9's `rel_load_vocabulary` line had already traded their numerals for citations, so items 1 and 3 owed a **row** and a **property** rather than a count change anywhere — and no clause added here says "eight". **Consequence sweep, because a stale example is how this class regenerates (Q17):** the file-shape YAML, `rel_load_schema`'s `Kind`-enum cross-link, Feature Flow steps 6 and 9, the fields-this-feature-uses bullet, the one-physical-line clause, the validator-table preamble, V12's row and the advisories paragraph, three Layers rows, § Source (FR-5 now has a mechanical half here), and D4's **and** the Layers table's claim that the file on disk is reused as a *format* — true of its **carrier**, false of the **field contract its header comment documents**, which feature-001's rewrite supersedes. Closes **Q20** | /aid-specify |
| 2026-07-30 | **Reopened a second time and fixed — six findings (3 MEDIUM, 3 LOW), every one of them in prose the *previous* cycle added.** That is the lesson worth keeping over the fixes: the Q20 pass added 153 lines to close four inbound loader items, and the lines it added were the only lines that failed. New prose is unreviewed prose. All six are **mechanism** under Q26 and so are fixed now rather than batched onto the editorial queue. **Cycle 1's four Q20 items remain closed, and were re-verified rather than assumed** — every distinct `<kind>-><kind>` token feature-001 declares has both sides in `relationship-schema.yml`'s `kinds:` list, and every distinct standard token matches this loader's `derived_from` grammar, so the loader can no longer exit 2 on the vocabulary it exists to load; nothing below touches them. **Row 7 [MEDIUM], the substantive one — V12's new unobserved-token direction was not orientation-safe.** D7 *emits* rows in normalised orientation, so on a row whose ids sorted the other way the stored `S2T Relation` is the **inverse** of the relation the run discovered; an accumulation reading the stored `S2T` alone reports the forward token of roughly half of every asymmetric pair as unobserved — a false advisory, systematically, and worst on precisely the relations the report exists to inform. Fixed by accumulating **both readings a row asserts** — `(S2T, source-kind→target-kind)` *and* `(T2S, target-kind→source-kind)` — so the (relation, token) facts a row contributes are identical whichever orientation it was stored in: invariance by construction rather than by care at the call site, which is what §5.2's one-row-two-readings shape means applied to a report. The partition predicate is corrected on the same ground ("appears in **either** relation column"), the cost is restated honestly as one insert per reading, and one fixture is added that an implementation reading stored cells fails while passing the existing one. feature-005 meets the identical hazard on its W3 report and routes around it on the same ground (SPEC.md:1176–1179); W4 must read emitted rows, so it takes the pairing and not the map. **The per-row direction needed nothing, and that reason is now stated** so the class sweep is visible rather than implied: pair coherence makes `endpoint_kinds(r')` the exact transpose, so the swap moves a row from one side of a coherent pair to the other and cannot change that verdict. **Both directions stay advisory; nothing became a gate.** **Row 8 [MEDIUM] — pair coherence's "equal" is now defined, because a gating verdict may not be implementation-defined.** `derived_from` and `passes` are multi-valued, so "equal" had two readings and **exit 2** turned on which one an implementer picked. They compare as **token sets**, order-insensitive. The reading is feature-001's own rather than this SPEC's invention (`passes` specified as a *subset*, :310; `derived_from`'s two halves "carry the same **set**", :326–332; **AC-S5** says the entries "agree on" those keys, :180–183), and it makes every clause of the property compare sets, since the transpose clause already did. A **positive** fixture is owed and added — same tokens, different order, must **load** — because a sequence-comparing loader passes all three negative agreement fixtures and rejects a legal pair. **Row 9 [MEDIUM] — `rel_load_vocabulary`'s exposure surface was short two keys, not one.** `passes` was missing (feature-005's pass-legality axis, read through this loader) and so was `definition` (feature-009's row labels) — found by reading feature-001's consumer table (:1294–1304), which is now cited as the authority on that surface; the two keys that stay unexposed each carry their reason (`derived_from` has no runtime reader; `symmetry`'s only consumer is **V4**, inside this feature), and D4's fields bullet gained `definition` in the same sweep. **Row 10 [LOW] — the residual named a catcher that cannot reach the case.** feature-001's **AC-S2** is scoped to the delivered **core**, so a mistyped standard key in a project **extension** is caught by nothing at all. The judgment not to gate standard-key membership **stands** — gating it breaches **AC-S11** and re-creates the second copy of a closed set the `endpoint_kinds` re-key removed — so what changed is honesty, not mechanism: the residual is stated at its true size and routed as **new Open Item 16** (owner: feature-001), with what bounds it on the record (no runtime reader; a typo on **one** half of a pair still exits 2 via pair coherence). **Row 11 [LOW] — an enforced value rule with no negative test.** The `derived_from` token grammar had no rejection-class fixture while the field's other three clauses each got one; added, plus the two sibling gaps the same sweep found in the **pre-existing** list — a `relation`/`inverse` label breaking its charset, and a restricted-subset violation. **Row 12 [LOW] — category-name uniqueness is re-attributed to the check that owns it.** feature-001 :595–602 states in terms that property 5 checks that a name an entry **references** is declared and says nothing about two `categories:` blocks **declaring** one; the clause moves out of category totality and into the `categories:` name-uniqueness check, stated over the **merged** block as feature-001 has it. **Row 13, routed OOS, verified not re-raised:** FR-4 now reads "**this list is the authority, not its length**" and names the rules rather than counting them, pair coherence included (REQUIREMENTS.md:292–298), and every FR-4 citation here agrees with the corrected text, so no edit was owed. **Held invariant through the pass:** no cardinality numeral introduced, no field added to the `Checked: N rows \| Findings: M` trailer, V1–V15's numbers and gate/advisory postures unchanged, and Open Items 12–15 untouched | /aid-specify |

## Source

- REQUIREMENTS.md §5.2 `relationships.md` table schema — **ten** columns, and the **`Kind` closed
  enum** with its required-prefix pairing table *(amended 2026-07-29, Q14 item 3; `Strength` remains
  dropped per Q1 and is not reinstated by the widening)*
- REQUIREMENTS.md §5.3 Node identity — the three prefixes `kb:` / `int:` / `ext:<key>` unchanged, but
  **one id grammar and one resolution check per `Kind`**; the `concept` id is not document-scoped; the
  `int:` symbol narrowing is struck
- REQUIREMENTS.md §5 FR-1 (the artifact this feature contracts), **FR-3** (the table is the single
  input to the graph), FR-4 + **FR-4a** (core-plus-extension vocabulary, collisions are a hard
  failure), **FR-5** ("each term records **which standard it derives from**", REQUIREMENTS.md:308 —
  feature-001's research to conduct, and as of 2026-07-30 a field this loader validates: D4's
  `derived_from`), FR-9 (`relationships.md` placement), **FR-9a** (the `## Coverage notes` section)
- REQUIREMENTS.md §5.7 FR-23 (asymmetric granularity — sub-document nodes in the KB, whole artifacts
  in code) and FR-22 (the exclusion statuses the coverage notes report)
- REQUIREMENTS.md §5.8 FR-30 (Pass 1 produces the section, fact and concept nodes this schema must
  address), FR-31/FR-31a (Pass 2 creates edges, never nodes), **FR-32** (byte-identity over the grown
  deterministic majority, keyed to **all of** FR-11's staleness inputs)
- REQUIREMENTS.md §5.9 FR-28 (this feature implements the data half of the skill's
  own-artifacts-only quality gate; feature-010 owns the gate and rubric)
- REQUIREMENTS.md §5.5 FR-8a (genericity — any project with an approved AID KB; the skill may rely on
  **KB authoring conventions** and may not rely on this repository's content), FR-10 (read-only),
  FR-11 (the staleness input **set** — its list is authoritative, not its cardinality; the vocabulary
  core *and* extension are one member, and the **tool itself** is another)
- REQUIREMENTS.md §7 Constraints — **C-7** (KB-adjacent artifact must obey KB authoring
  conventions; the index generator emits one entry per non-dot KB document), C-2/C-3/C-4
- REQUIREMENTS.md §8 (A-1 external-sources file resolves `ext:` keys; A-3 provenance is required by
  construction; A-6 fixtures are self-built; D-1, D-4, D-5)
- REQUIREMENTS.md §9 — AC-1, AC-2, **AC-2a**, AC-3, AC-4, **AC-5**, AC-16 (table side), AC-18,
  **AC-19**, **AC-20**
- STATE.md `## Cross-phase Q&A` — Q10 (widened node model, generic vocabulary), Q12 (asymmetric
  granularity), Q13 (fact and concept definitions; concept merge), Q14 (the ten-column consequence and
  the `Kind` enum), Q15 (the six items deferred to this SPEC)

**Genericity posture, stated once because it constrains every rule below (FR-8a).** Every carrier
this SPEC relies on is drawn from an **AID KB authoring convention** — a shipped template or
`authoring-conventions.md` — never from an instance in this repository. Where this SPEC cites a file
under `.aid/knowledge/`, it is to show a rule *fires* on real content, never to derive the rule.
That distinction is the one Q10 found the superseded vocabulary research on the wrong side of.

**Dependency position.** Blocked by feature-001 (the vocabulary core this schema validates against;
its *contents* are being re-researched standards-first, its *mechanism* is reused here). Blocks
feature-004 (which assigns `Kind` to each node record), feature-005 (which writes rows in this
shape), feature-006 (which reads coverage from it), feature-007/008/009 (which render from it), and
feature-010 (which gates on it).

## Description

The relationship table is the single artifact everything else in this work depends on. This
feature defines its shape and the checks that prove a given table is well-formed.

Each row records exactly one relationship, once and never twice, because both readings —
source-to-target and target-to-source — are named on the same row. Each endpoint is carried three
times over: as a machine-verifiable identifier a validator can resolve, as the **kind** of thing that
identifier names, and as a human-friendly display name a reader can recognise. The kind is carried in
its own column rather than being read out of the identifier, because the view needs it to choose a
colour and a shape, and because a single prefix covers several kinds of thing.

Identifiers say which of the three relationship sources they belong to: the Knowledge Base, the
project source, or an external source that contributed information. Inside the Knowledge Base they go
further and name *what* they point at — a whole document, one section of it, one claim within it that
carries a checkable reference to its evidence, or a defined concept. A concept is deliberately not
tied to any one document: a term defined once and mentioned in five places is one thing, so it is one
node, and each mention is a relationship pointing at it. External identifiers carry only a key, never
a raw path or address, because the Knowledge Base already keeps the file that resolves those keys —
and keeping resolution in one place means it stays correct in one place.

Every row also records how the relationship was established: explicitly stated, mechanically
computed, or concluded by reading. That value is what lets a reader trust or discount a row, so
it is never absent.

The relationship names themselves come from a shipped core vocabulary that a project may extend but
may never rewrite. An extension that tries to redefine something the core already owns fails the run
outright rather than quietly winning, so two projects reading the same relationship name always mean
the same thing. And because a relationship is one thing described twice, its two names must agree
about which kinds of thing may sit at each end, and about what the relationship is for and where it
came from; a vocabulary whose two halves disagree fails to load rather than letting one direction of
a relationship mean something the other does not.

After the table the file records what the run could see and what it deliberately did not: for each
kind of node, the convention it depends on, whether that convention was present, and how many nodes
resulted; and for each enumeration exclusion, whether it applied. These notes sit after the table
precisely so that anything reading the table can stop when the table ends.

Because the file lives alongside the Knowledge Base, it must behave like a Knowledge Base
document where the conventions apply — carrying the frontmatter the index generator needs, so
that regenerating the index leaves the index and the file consistent rather than at odds.

This feature also delivers the validation that makes the table checkable rather than merely
conventional: that every identifier resolves to something real by the rule for its own kind, that
every kind is a permitted value and agrees with its identifier, that both relation directions on a
row are a genuine inverse pair, that no relationship was recorded twice, that no row is missing its
provenance, and that the coverage notes are complete even when nothing is wrong.

## User Stories

- As an **AI agent**, I want every endpoint identifier to resolve to a real document, section,
  claim, concept, path, or external-source key, so that I can follow a row to its subject instead of
  dead-ending on a stale reference.
- As an **AI agent**, I want each endpoint to declare its kind in its own column, so that I can tell
  a concept from the document that defines it without parsing an identifier.
- As a **KB reviewer**, I want each row to state how the relationship was established, so that
  I can weigh a mechanically-derived claim differently from one concluded by reading.
- As a **maintainer/architect**, I want each relationship recorded exactly once with both
  readings on the same row, so that the table's row count means something and I never have to
  reconcile a forward row against its mirror.
- As a **maintainer/architect**, I want to read, on every run and not only on a bad one, which
  conventions the run found and which it did not, so that a thin graph tells me whether my Knowledge
  Base is thin or my tooling failed.
- As a **maintainer/architect adopting AID on another project**, I want to add my own relationship
  types without my additions being overwritten on upgrade or silently colliding with the shipped
  ones, so that extending the vocabulary is safe.
- As an **AI agent**, I want `relationships.md` to carry valid Knowledge Base frontmatter, so
  that it appears in the routing index like every other Knowledge Base document rather than
  being invisible to the mechanism I route by.

## Priority

Must

## Acceptance Criteria

- [ ] AC-1: Given a generated `relationships.md`, when every row's source and target identifier
      is resolved **by the protocol for its own `Kind`**, then a `document` resolves to an existing
      Knowledge Base file, a `section` to a heading in that file that slugifies to its fragment, a
      `fact` to a checkable source anchor in that file whose recomputed token equals its fragment, a
      `concept` to **exactly one** definition of its normalised term, a `source-artifact` or in-repo
      `image` to an existing repository-relative path, and a `web-page` or external `image` to an
      entry in the external-sources file — with no unresolvable identifier. *(The `ext:` branch is
      proven against a self-built synthetic fixture, per Q4 and A-6, because this project's own
      `external-sources.md` registers no keys and would satisfy the criterion vacuously.)*
- [ ] AC-2: Given a generated `relationships.md`, when each row's two relation columns are
      checked against the **merged core-plus-extension** vocabulary, then both values are members of
      that merged set and form a valid inverse pair, and no row's two directions disagree — a
      symmetric relation, where both columns hold the same label, being valid rather than a
      disagreement.
- [ ] AC-2a: Given a generated `relationships.md`, when each row's `Source Kind` and `Target Kind`
      are checked, then each is a member of §5.2's closed enum and **agrees with its identifier's
      prefix** by the pairing table there — including the branching `image` case, which permits
      `int:` **or** `ext:` and must not be rejected for carrying `ext:`.
- [ ] AC-3: Given a generated `relationships.md`, when the table is scanned for duplicates,
      then no relationship appears twice — neither as a repeated row nor as a forward row plus
      a separate inverse row for the same endpoint pair.
- [ ] AC-4: Given a generated `relationships.md`, when every row's provenance column is read,
      then each carries exactly one of the three permitted values and none is empty.
- [ ] AC-5: Given `relationships.md` regenerated with **all of FR-11's staleness inputs unchanged** —
      at the time of writing the KB, the project source, the external-sources file, `.aid/settings.yml`,
      the relation vocabulary **core and extension**, and the **tool itself**, but FR-11's list is the
      authority and this restatement is not, so a member added there is in scope here without an edit
      here — then the deterministic (`declared` + `derived`) row block and the `## Coverage notes`
      section are both byte-identical to the previous artifact.
- [ ] AC-16 (table side): Given a generated `relationships.md`, when every `int:` identifier is
      inspected, then none carries a fragment of any kind — no function, symbol, or line narrowing —
      while `kb:` identifiers **do** carry section, fact and concept forms.
- [ ] AC-18: Given `relationships.md` in `.aid/knowledge/`, when the Knowledge Base index is
      regenerated, then `relationships.md` carries frontmatter valid for the index generator
      and both the index and `relationships.md` are left consistent with each other.
- [ ] AC-19 (table side): Given a KB lacking a carrier convention, when `relationships.md` is
      validated, then a kind with **zero** nodes is a well-formed outcome rather than a schema
      violation, and its absence is recorded in the coverage notes as a `Status` of `absent` — not as
      a gap-ledger row, since FR-26 requires an `int:` node as evidence and a missing convention has
      none. *(Validated against fixtures, per A-6, because this repository has all four conventions
      and would satisfy the criterion vacuously.)*
- [ ] AC-20: Given a run on a project where **every** carrier convention is present, when
      `relationships.md` is read, then it still carries a `## Coverage notes` section listing every
      kind in §5.2's enum — including any with a count of zero — with its convention and status, plus
      the FR-22 exclusion statuses including whether the ignore list was available.
- [ ] AC-S1: Given the resolved schema, when the table is emitted, then it has exactly **ten**
      columns in §5.2's order, with `Kind` adjacent to the identifier it qualifies, and no `Strength`
      column appears in the header or in any row.
- [ ] AC-S2: Given a `relationships.md` that carries a `## Coverage notes` section, when a parser
      reads the table, then it reaches the end of the table without reading any part of the notes —
      so FR-3's "the table is the single input to the graph" continues to hold.
- [ ] AC-S3: Given coverage-note rows contributed by more than one producer file and assembled in an
      arbitrary order, when `## Coverage notes` is emitted, then within each table the fixed rows come
      first in their fixed order and the extra rows follow as a contiguous block in `LC_ALL=C`
      ascending order of their keys — so the section's bytes are a function of the row set alone and
      not of assembly order (D7a-1). *(Added 2026-07-29 by the Q19 reopen; this is the ordering AC-5's
      byte comparison of the section was silently assuming.)*

> **The `AC-S<n>` scheme, and why it is introduced rather than borrowed.** The `AC-S` criteria above are
> **SPEC-authored**: no requirement states them, so they carry no requirement number. They are
> numbered here so task DETAILs and test plans can cite them.
>
> The peer SPECs were checked first, as instructed. **There is no existing convention to follow**: all
> twelve other feature SPECs in this work leave their spec-authored criteria entirely unlabelled —
> only requirement-originated criteria are numbered, and every one of those matches `AC-<digit>`
> optionally followed by a letter (`AC-1`, `AC-2a`, `AC-16a`). A repository-wide search for any
> `AC-<letter>` form returns nothing. So `AC-S<n>` is **new**, and it is collision-proof by
> construction: the requirements' grammar always places a **digit** immediately after `AC-`, so no
> requirement id can ever take the form `AC-S<n>`, in this work or a later amendment. It also stays
> greppable — `AC-S` selects exactly the spec-authored set — and keeps the `AC-` prefix so the two
> read as acceptance criteria alongside the rest. The same shape is available to the sibling SPECs if
> they choose to label their own criteria; nothing here obliges them to.

---

## Technical Specification

> The amended REQUIREMENTS.md (2026-07-29) is the authority for everything below. Q1 and Q3 remain
> **Resolved**: there is no `Strength` column, and `relationships.md` is a generated, KB-indexed
> document. Q9–Q14 are the changes this revision absorbs; Q15 lists the six decisions this SPEC now
> makes.

This feature ships a **contract plus its validators**, not a pipeline. Everything below is
stated so that a machine, not a reviewer's judgment, decides whether a given
`relationships.md` conforms: the column shape, the two closed enums, the per-kind id grammars, the
vocabulary merge rule, the total row order, and the frontmatter live in declarative files under
`canonical/aid/templates/graph/`, and one linter reads those files and grades the artifact against
them.

**How to read the "which requirement, checked how" claims.** Every contract below names the
requirement it satisfies and the validator that decides it. That pairing is deliberate: this work's
recorded failure mode (Q9, Q15) was an artifact that was complete, traceable and internally
consistent while answering the wrong question, so a contract with no validator behind it is treated
here as undelivered.

### Data Model

#### D1. Column contract — ten columns

`.aid/knowledge/relationships.md` carries exactly one GFM pipe table, with **ten** columns in this
fixed order (§5.2; `Kind` adjacent to the id it qualifies):

| # | Column | Required | Value space |
|---|--------|----------|-------------|
| 1 | `Source Id` | yes | a node id (D2), per its kind |
| 2 | `Source Kind` | yes | a member of the `Kind` enum (D1a) |
| 3 | `Source Name` | yes | display name of `Source Id` (D5) |
| 4 | `Target Id` | yes | a node id (D2), per its kind |
| 5 | `Target Kind` | yes | a member of the `Kind` enum (D1a) |
| 6 | `Target Name` | yes | display name of `Target Id` (D5) |
| 7 | `S2T Relation` | yes | a member of the merged vocabulary (D4) |
| 8 | `T2S Relation` | yes | a member of the merged vocabulary (D4) |
| 9 | `Provenance` | yes | `declared` \| `derived` \| `inferred` (D3) |
| 10 | `Observation` | no | free text or a durable anchor (D6) |

Byte-level row grammar, fixed so the artifact is byte-stable (FR-32):

- Header row, verbatim:
  `| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |`
- Delimiter row: `|---|---|---|---|---|---|---|---|---|---|` (**ten** cells).
- Every data row: a leading `|`, then each cell surrounded by exactly one space, then a
  trailing `|`. An empty `Observation` renders as a single space (`| |`) — the same
  well-formed-empty-cell rule `build-kb-index.sh` applies to its own blank cells (see its
  `END` block, "Empty cell renders as a single space").
- Cell content contains no newline and no raw `|`. A literal pipe inside a cell is escaped as
  `\|`, reusing the escaping already implemented by `build-kb-index.sh` `esc()`. This matters more
  than it did at eight columns, because a `fact` display name (D5) reproduces a quoted anchor string
  from a KB document verbatim and such a string may legitimately contain a pipe.
- Line endings are **LF only**, including the last line — the rule
  `canonical/EMISSION-MANIFEST.md` states at its "Line endings" bullet ("**`LF` (`\n`) only**, even
  on Windows"), which matters here because this repository is authored on Windows.

**File skeleton, fixed — and this is what keeps FR-3 true alongside FR-9a.** FR-9a adds a
`## Coverage notes` section to a file that FR-3 declares "the single input to the graph". The two
coexist by position and by a one-pass stopping rule, not by convention:

```markdown
---
<frontmatter — D8>
---
<!-- AUTO-GENERATED by aid/scripts/graph/build-relationships.sh -- regenerate with /aid-graph. Do not edit. -->

# Relationships

| Source Id | Source Kind | ... | Observation |
|---|---|---|---|
| ...data rows, in D7 order... |

## Coverage notes

<D7a's two tables>
```

The rules a parser and a validator both rely on:

1. The first non-blank line after the `# Relationships` H1 is the header row.
2. The table runs from the header row to the **first line that is not a table row**. A parser stops
   there. It therefore never reads the notes, and FR-3 holds structurally rather than by trust.
3. That first non-table line is blank, and the next non-blank line is the `## Coverage notes`
   heading. So the notes are always *after* the table, never interleaved, and **V14** asserts the
   ordering.
4. `## Coverage notes` is the only `##` heading in the body, and the relationship table is the only
   pipe table above it. Tables *inside* the notes are permitted and expected (D7a) and are outside
   the parse contract.

The machine-readable form of this contract is `canonical/aid/templates/graph/relationship-schema.yml`
(new; see Layers & Components), a flat YAML file parsed with the project's existing awk
frontmatter/list extractors rather than a YAML binary, per `coding-standards.md`
("**YAML/text parsing without binaries:** scripts parse the simple, flat YAML AID [uses]"):

```yaml
columns: [Source Id, Source Kind, Source Name, Target Id, Target Kind, Target Name, S2T Relation, T2S Relation, Provenance, Observation]
required: [Source Id, Source Kind, Source Name, Target Id, Target Kind, Target Name, S2T Relation, T2S Relation, Provenance]
optional: [Observation]
provenance: [declared, derived, inferred]
prefixes: [kb, int, ext]
kinds:
  - "document|kb"
  - "concept|kb"
  - "fact|kb"
  - "section|kb"
  - "source-artifact|int"
  - "image|int,ext"
  - "web-page|ext"
image_extensions: [png, jpg, jpeg, gif, svg, webp, avif, bmp, ico]
```

No script hard-codes the column list, either enum, or the prefix set; all are read from this file.
Adding a column is therefore a one-file change plus a validator-test update, not a grep across the
pipeline — a property this revision has just cashed in, since the eight-to-ten widening is a change
to this file plus the header/delimiter literals, not a rewrite of the validator.

#### D1a. The `Kind` enum — the second closed vocabulary

§5.2 makes `Kind` a closed enum, each value pinned to a required prefix, "loaded fail-closed in the
same way" as the relation vocabulary. The `kinds:` list above **is** that enum, and the pairing is
carried as **data** rather than as code:

| `Kind` | Permitted prefixes | What the id names |
|--------|--------------------|-------------------|
| `document` | `kb` | a whole KB document |
| `concept` | `kb` | a glossary entry or convention-marked defined term |
| `fact` | `kb` | a claim carrying a checkable source anchor |
| `section` | `kb` | a document section, addressed by its heading |
| `source-artifact` | `int` | a whole artifact in the project source — never a function or symbol |
| `image` | `int` **or** `ext` | an image, in-repo or external |
| `web-page` | `ext` | an external web page |

**The `image` row is why the pairing is data.** §5.2 flags it explicitly: `image` is the one
branching case, and "a naive one-to-one implementation would wrongly reject valid external images."
Encoding the permitted prefixes as a **set** per kind (`"image|int,ext"`) makes the branch a value
the loader reads, so the naive implementation is not merely discouraged but unrepresentable. Two
fixtures make the hazard a test rather than a warning: `image` + `ext:` **must pass** and `image` +
`kb:` **must fail** (see Layers & Components). Without the positive fixture, an implementation that
rejects every `ext:` image would pass a test suite that only checked rejections.

**V13 checks the pairing in two tiers, the second stronger than AC-2a requires.**

1. **Prefix tier (AC-2a as written).** `Kind` is a member of the enum, and the id's prefix is a
   member of that kind's permitted-prefix set.
2. **Fragment tier, for `kb:` ids only.** Because §5.3 now gives each KB kind its own id grammar,
   kind is a *function* of a `kb:` id and the check can be exact rather than merely consistent: a
   body beginning `concept:` ⇒ `concept`; a `#fact:` fragment ⇒ `fact`; any other `#` fragment ⇒
   `section`; no fragment ⇒ `document`. A `kb:` id whose kind disagrees with its own grammar is a
   finding even though it satisfies tier 1.

**Where `Kind` carries information no id can, and where it must therefore be trusted.** Stated
plainly because it bounds what any validator can do:

- For `kb:` ids, `Kind` is fully redundant with the grammar — tier 2 above.
- For `int:` ids, `image` versus `source-artifact` is decided by the path's extension against
  `image_extensions:`. **V13** asserts the agreement in both directions: an `int:` path with an image
  extension must carry `image`, and one without must carry `source-artifact`. A **directory** id
  (trailing `/`, D2b) must carry `source-artifact`, since a directory is never an image.
- For `ext:` ids, `image` versus `web-page` **cannot be recovered from the key** — the key is opaque
  and the external-sources file is the only thing that resolves it. This is the single place in the
  schema where `Kind` is unchecked by construction, and it is trusted from feature-004's node record.
  Recording the gap here rather than pretending to a check is deliberate: a validator that claimed to
  verify it would have to guess. Closing it needs an entry format for the external-sources file that
  records a media type, which is D-5's missing format and is recorded under Open Items.

Loading is **fail-closed**, matching the relation vocabulary: an absent, empty, or malformed
`kinds:` list exits 2 before any row is examined, so a broken enum can never be read as "every kind
is acceptable."

#### D2. Node id grammars and resolution, one pair per `Kind` (§5.3)

Every id is `<prefix>:<body>` with `<prefix>` ∈ {`kb`, `int`, `ext`}. The three prefixes are
unchanged from the original design; what changed on 2026-07-29 is that the **body** grammar and the
**resolution check** are now selected by `Kind`, not by prefix.

| `Kind` | Id form | Resolution check (AC-1) |
|--------|---------|-------------------------|
| `document` | `kb:<doc>` | `<doc>` is a member of the KB scan set (D2a) |
| `section` | `kb:<doc>#<heading-slug>` | some heading in `<doc>` slugifies to `<heading-slug>` under D2a-1, counter included |
| `fact` | `kb:<doc>#fact:<anchor-token>` | some checkable source anchor in `<doc>` yields `<anchor-token>` under D2a-2 |
| `concept` | `kb:concept:<normalised-term>` or `kb:concept:<normalised-term>@<doc>` | **exactly one** definition block in the KB normalises to `<normalised-term>` under D2a-3 — or, in the qualified form, exactly one in `<doc>` |
| `source-artifact` | `int:<repo-relative-path>` or `int:<repo-relative-path>/` | the path exists as a file (or a directory, for the trailing-`/` form) from the repo root (D2b) |
| `image` | `int:<repo-relative-path>` (in-repo) or `ext:<key>` (external) | as `source-artifact` or as `web-page` respectively |
| `web-page` | `ext:<key>` | `<key>` is registered in the KB's external-sources file (D2c) |

**The grammar is unambiguous without consulting `Kind`, and that is load-bearing.** A validator must
be able to parse an id *before* it trusts the `Kind` column, or tier 2 of V13 would be circular. Two
lexical facts make the split total:

- A `kb:` body beginning with the literal `concept:` is a concept id; nothing else can be, because
  `<doc>` is a `*.md` basename (D2a) and contains no `:`.
- A `#` fragment beginning `fact:` is a fact id; a heading slug can never begin `fact:` because the
  slug charset (D2a-1) excludes `:`.

**A `concept` id is not document-scoped, and the merge rule is why (§5.3, Q13).** A concept named in
five documents is one node, so its identity cannot be qualified by any one of them; it is keyed on the
normalised term and resolves through the definition that introduces it, while each mentioning
document or section reaches it by an **edge**. Facts and sections are not merged and stay
document-scoped. One consequence worth naming, because it looks like a collision and is not: a
glossary entry is both a `section` of the glossary document and a `concept`, and the two are
different nodes with different ids (`kb:domain-glossary.md#canonical` and `kb:concept:canonical`).
That is the merge rule working, not a defect.

**The `int:` symbol narrowing is struck, and V7 changes accordingly.** §5.3's former "optionally
narrowed to a symbol within the file" clause is removed as definitively wrong (it is the clause that
contradicted FR-23 from `/aid-define` onward). The previous revision of this SPEC preserved it as a
"deliberate, recorded tension" — a grammar that admitted `int:<path>#<symbol>` while V7 rejected any
instance. That accommodation is now void: the grammar itself admits **no `int:` fragment at all**, and
V7 is redefined from *reject a narrowed id* to *reject any `#` in an `int:` body*. This is simpler and
strictly stronger, and it removes the only place in the old SPEC where the grammar and the
requirements disagreed on purpose.

##### D2a. `kb:` bodies — the KB scan set

`<doc>` is the *basename* of a file in the KB scan set, and that set is defined by the same
**membership predicate** `build-kb-index.sh` applies to the docs it indexes. Quoted exactly, from
`canonical/aid/scripts/kb/build-kb-index.sh` line 471:

```bash
done < <(find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)
```

Two consequences, which must not be conflated:

- **Membership is what AC-18 needs, and membership is locale-independent.** The `find`
  predicates (`-maxdepth 1`, `-type f`, `-name '*.md'`, `! -name '.*'`) select the same *set*
  under any locale; the trailing `sort` only orders it. So the AC-18 property holds
  unconditionally: a doc the index lists is exactly a doc a `kb:` id may name, and vice versa.
- **That `sort` is bare — there is no `LC_ALL=C` on it** (verified at line 471) — so
  `build-kb-index.sh`'s row *order* is locale-dependent. This feature therefore inherits no ordering
  from it. Every byte-identity claim here rests on **this feature's own** `LC_ALL=C` sorts (D7). The
  repo is not uniform: `kb-citation-lint.sh` line 37 also enumerates the KB with a bare `| sort`,
  where order affects only the sequence findings print. The scripts that *do* pin the locale —
  `build-project-index.sh` (`| LC_ALL=C sort`, line 185) and `kb-freshness-check.sh`
  (`LC_ALL=C find … | LC_ALL=C sort`, line 460) — are this feature's precedent.

`<doc>` matches `[A-Za-z0-9._-]+\.md`, exact on-disk case, no path separator. It is a basename because
the scan set is flat by the predicate above (`-maxdepth 1`).

###### D2a-1. Heading slugification — **author decision 1** (Q15; §5.3; FR-30's "heading-level cutoff")

The slug of a heading is computed by this algorithm. Its target property is that a `section` id **is**
the anchor a reader's renderer resolves — what feature-007's "open the underlying artifact" gesture
(FR-14a) depends on. What is **verified** here is narrower and stronger than an appeal to any external
renderer: the algorithm reproduces, byte for byte, the anchors this KB's own hand-maintained
`## Contents` links already encode, on every instance in the KB that discriminates between candidate
rules.

1. Take the heading text after the leading `#`s; trim surrounding whitespace.
2. Remove inline markup delimiters that carry no text: backticks, `*`, `_` used as emphasis, and the
   `[`/`]`/`(`…`)` of a link, keeping the link text.
3. Lowercase.
4. Delete every character outside `[a-z0-9_ -]`. Deletion **removes only the character itself** — any
   space beside it stays.
5. Replace **each** space with a single `-`, one for one. Runs of spaces are **not** collapsed, and
   runs of `-` are **not** collapsed.

**Step 5 is one-for-one, and that is load-bearing.** A rule that collapsed runs would produce a
different slug on every KB heading containing a deleted-character-between-spaces, and would therefore
break the id-equals-anchor property on real content. Verified against the KB's own links, four
instances, each chosen because it discriminates:

| Heading (on disk) | On-disk `## Contents` anchor | What it pins |
|---|---|---|
| `coding-standards.md` `## JavaScript / Node Conventions` | `#javascript--node-conventions` | `/` deleted leaves two spaces → **two** hyphens |
| `domain-glossary.md` `## Lexicon — Pipeline Run-State` | `#lexicon--pipeline-run-state` | em dash deleted the same way; an existing `-` is kept |
| `decisions.md` line 248 `` ## D13 — Per-repo `format_version` stamp (git model) `` | line 52 `#d13--per-repo-format_version-stamp-git-model` | **`_` is retained**; backticks stripped; `(`/`)` deleted without adding hyphens |
| shipped `canonical/aid/templates/knowledge-base/domain-glossary.md` `## Abbreviations & Acronyms` | `#abbreviations--acronyms` | the rule holds in the template, not only in this repository |

**The `_` rule, restated as verified fact and no longer as an appeal to GitHub.** The previous revision
justified retaining `_` at step 4 by asserting it "matches GitHub" and claimed no KB heading
distinguished the two. **Both statements are withdrawn.** The first was unverifiable — renderer
underscore handling is not authoritatively fixed in one specification — and the second is simply
false: `decisions.md` carries `` ## D13 — Per-repo `format_version` stamp (git model) `` at line 248,
and its own `## Contents` link at line 52 is
`#d13--per-repo-format_version-stamp-git-model`, which **retains the `_`**. A second heading,
`domain-glossary.md` line 270 `### AID_HOME`, carries one too. So the rule needs no external
authority: retaining `_` is what this KB's links do, it is checkable by anyone with the two files, and
a rule deleting `_` would emit `#d13--per-repo-formatversion-stamp-git-model` and resolve to nothing.

That verified instance also pins a deliberate divergence worth naming, since one heading feeds two
different normalisations: `### AID_HOME` yields the **section** slug `aid_home` (`_` retained, D2a-1)
and the **concept** term `aid-home` (`_` folded to `-`, D2a-3 step 4). The two are different on
purpose — a section id must equal a resolvable anchor, while a concept term must be a stable label in
the `[a-z0-9-]` charset — and V2 checks each against its own recomputation, so the divergence cannot
be mistaken for an inconsistency.

**Non-ASCII headings.** Step 4 deletes non-ASCII letters. Whether a given renderer would instead retain
them lowercased is **not** verified here and nothing below relies on it. The branch is untested against
real content and specified for genericity alone: enumerating every non-ASCII character across all KB
headings returns exactly two, `—` (U+2014) and `→` (U+2192), both punctuation — **no** non-ASCII
*letter* appears in any KB heading. Both are handled by the ordinary step-4 deletion, which is what the
`#lexicon--pipeline-run-state` instance above verifies. The deletion is a deliberate narrowing: ids
must be ASCII so that D7's `LC_ALL=C` total order is well defined.
A heading whose slug comes out **empty** yields **no** `section` node; the count of such headings is
reported in the coverage notes (D7a) rather than failing the run, which is FR-8a's
degrade-gracefully rule applied to a non-English project.

**Heading-level cutoff (owed by FR-30).** `section` nodes are emitted for heading levels **2–6**.
Level 1 is excluded, because the H1 is the document and a section node spanning the whole document
would duplicate the `document` node.

**Headings inside fenced code blocks are not headings.** Lines within a ``` or `~~~` fence are
skipped, so a `# comment` inside a shell example never becomes a section. The ground for this is
structural, not an appeal to a renderer: under GFM, a line inside a fenced code block is code content
and cannot be an ATX heading at all — the same semantics D-level argument the parser-stops guarantee
(AC-S2) already rests on. It matters because KB documents quote shell freely.

**Duplicate headings within one document — the rule, and it fires on real content.** Slug collisions
are resolved by numbering: headings are counted in document order and the *N*th occurrence of a slug
(for *N* ≥ 2) gets `-<N-1>` appended. Two details make this exact:

- The counter runs over **all** heading levels 1–6, even though only 2–6 are emitted as nodes. A
  counter that skipped level 1 would number an H2 colliding with the H1 differently, so the two rules
  are not interchangeable and this one is fixed here.
- Fenced-code lines are excluded from the counter as well as from emission.

**This is an author decision, and its verification status is stated rather than assumed.** The
`-<N-1>` shape is chosen because it is total (every collision gets an id), order-deterministic (document
order is already the scan order), and stable under D7's sort. The *motivation* is agreement with the
anchor a renderer generates for a repeated heading — but unlike the four rules verified in the table
above, **no on-disk instance verifies it**: the KB's only duplicate-slug group is
`domain-glossary.md`'s `## Concept Spine` / `### Concept Spine`, and the document's `## Contents`
links only the first (`- [Concept Spine](#concept-spine)`, line 53), so nothing on disk exercises the
suffix. The previous revision presented the choice as adopting GitHub's rule; that appeal is
**withdrawn** and the rule stands on the three properties above. Confirming that the emitted suffix
matches what a reader's renderer resolves belongs to feature-007, which owns the gesture that depends
on it (Open Item 15).

The collision itself is not hypothetical. `domain-glossary.md` carries `## Concept Spine` at line 69
and `### Concept Spine` at line 214 — both slugify to `concept-spine`, and it is the only
duplicate-slug group in this repository's KB (verified by recomputing every heading slug across
`.aid/knowledge/*.md`). So the first keeps `concept-spine` and the second becomes `concept-spine-1`,
yielding the two distinct `section` ids `kb:domain-glossary.md#concept-spine` and
`kb:domain-glossary.md#concept-spine-1`. D2a-3 returns to this group to show what the concept
predicate does with it, which is a separate question with a separate answer.

**V2** resolves a `section` id by recomputing every heading slug in the named document, in document
order and with the counter, and testing membership. It never parses the document's own `## Contents`
list, which is hand-maintained and therefore not authoritative.

###### D2a-2. The `<anchor-token>` for `fact` ids — **author decision 2** (Q15; §5.3; FR-30)

A `fact` is "a claim carrying a checkable source anchor" (Q13). The **portable** carrier is the
Citation Rule in `authoring-conventions.md` § "Citation Rule (Durable Anchors)", which requires "a
file path plus a grep-recoverable symbol, heading, or unique string -- never a bare `file.ext:LINE`"
and whose verdict table admits exactly two correct spellings:

| Verdict table row (verbatim) | Form |
|---|---|
| `` `read-setting.sh` -> `lookup_list` `` — correct (greppable symbol) | **symbol form** |
| `` `principles.md` "P1(d) Positional citations" `` — correct (greppable heading) | **quoted-string form** |

So a **checkable source anchor**, for the purpose of a `fact` node, is a citation carrying *both* a
path and a grep-recoverable anchor string in one of those two forms. The `(search: "…")` spelling
this KB uses in its `CONFIRMED` markers is an instance of the quoted-string form.

**What is deliberately excluded, and why it matters.** A citation naming a path with **no** anchor
string is not checkable — there is nothing to grep for — and yields **no** fact node. This is not a
theoretical edge: this repository's KB carries `CONFIRMED` markers of the form
`CONFIRMED via directory listing.` with no path and no anchor at all, alongside well-formed ones such
as `CONFIRMED. \`README.md\` (search: "A full-lifecycle methodology for building software with …")`.
An implementation that counted every `CONFIRMED` occurrence as a fact would manufacture nodes that
resolve to nothing, which is precisely what AC-1 exists to prevent. The count of markers skipped for
want of an anchor is reported in the coverage notes (D7a).

**Token grammar.** For an anchor citing `<path>` with anchor string `<anchor>`:

```
<anchor-token> = <path-slug> "--" <anchor-slug> [ "-" <N-1> ]
```

- `<path-slug>` — `<path>` lowercased, `/` and `.` replaced by `-`, then D2a-1 steps 4–5 applied,
  runs of `-` collapsed, leading/trailing `-` trimmed.
- `<anchor-slug>` — `<anchor>` with newlines and whitespace runs collapsed to single spaces, then
  D2a-1 steps 2–5 applied, runs of `-` collapsed, leading/trailing `-` trimmed, then **truncated** by
  the rule below.
- `[ "-" <N-1> ]` — the same document-order disambiguation suffix D2a-1 uses, applied when two
  anchors in one document yield the same `<path-slug>--<anchor-slug>`. One rule serves both fragment
  grammars, which is one fewer thing to get wrong.

**Both slugs here collapse runs of `-`; D2a-1's section slug deliberately does not.** The collapse is
correct for a fact token and wrong for a section slug, because only the section slug carries an
anchor-equality obligation (D2a-1 step 5). A fact token answers to nothing but itself, so the tidier
form is chosen. Stating the difference explicitly is what stops an implementer from unifying the two
helpers and silently breaking `section` ids — which is why D9 exposes `rel_slug_heading` and the fact
tokeniser as **separate** functions rather than one with a flag.

**Truncation, total in every case.** The `<anchor-slug>` is truncated as follows. The rule is stated as
an ordered algorithm because the previous revision's phrasing left a case silent, and a silent case
makes AC-5's byte-identity unattainable:

1. If the slug is **40 characters or fewer**, use it whole. Stop.
2. Otherwise, look for a `-` at index ≤ 40 (1-based). If one exists at index *p* with *p* > 1, take
   characters 1…*p*−1 — the word-boundary cut.
3. **Fallback — if no such `-` exists**, take characters 1…40 exactly: a **hard cut at 40, mid-word**.
   This is the case the previous revision left undefined (a UUID, a hash, a base64 fragment, or any
   long unbroken token). Legibility is a preference; totality is a requirement, so the preference
   yields.
4. Trim any trailing `-` from the result of step 2 or 3.

The result is always non-empty: leading `-` is already trimmed before truncation, so no branch can
return a bare `-` or an empty string, and steps 2–3 each return at least one character.

**Why truncation cannot cost correctness.** Truncation is lossy by design and two distinct anchors can
collide after it — including two hard-cut UUIDs sharing a 40-character prefix. That is handled, not
tolerated: the `[ "-" <N-1> ]` ordinal disambiguates any post-truncation collision in document order,
so the map from anchors to tokens stays injective within a document. And **V2** recomputes the tokens
with this same algorithm rather than trusting the ones in the table, so writer and validator cannot
disagree about where a cut fell.

**Newline handling is required, not defensive.** Anchor strings wrap across source lines in this KB
(the `README.md` example above continues onto the next physical line), so the anchor is matched over
a **block** — the marker line plus continuation lines up to the next blank line — with newlines
normalised to single spaces before slugification. A line-scoped matcher would silently produce a
different token for every wrapped anchor, and the ids would not be reproducible.

**V2** resolves a `fact` id by recomputing the token for every well-formed anchor in the named
document, in document order and with the counter, and testing membership. Truncation is therefore not
a correctness risk: collisions it creates are resolved by the ordinal suffix, and the validator
recomputes the same tokens the writer did.

###### D2a-3. Concept-label normalisation and same-label disambiguation — **author decision 3** (Q15; Q13; §5.3)

**The carrier convention, taken from the shipped template and not from this repository.**
`canonical/aid/templates/knowledge-base/domain-glossary.md` defines two definition markers, each
under a `###` heading whose text is the term:

- `**Definition-as-used-here:**` — Concept Spine entries;
- `**Definition:**` — Core Domain Terms entries.

So the **concept predicate** is: a heading at level 3 or deeper, in any document under
`.aid/knowledge/`, whose **block body** — as defined by D2a-3a, which is part of this predicate and not
a gloss on it — contains a line beginning with either marker. The heading text is the concept label.
The predicate is marker-based rather than location-based so that a project which defines terms outside
a glossary document still yields concepts — FR-8a genericity at no extra cost, since the grep is
identical. In this repository the markers occur only in `domain-glossary.md`, which is the expected
shape, not a requirement.

**Glossary *tables* are not concepts.** The shipped template also carries term tables
(`## Abbreviations & Acronyms`, `## Terms with Specific Domain Meanings`, `## Terms to Avoid`,
`## Business Process Vocabulary`). None becomes a concept node, for three stated reasons: their first
columns mean four different things (an abbreviation, a term, a banned word, a process), so no uniform
label rule exists; they carry no definition marker and no `sources:` grounding, so a node from a row
would resolve to nothing beyond the row itself; and `## Terms to Avoid` would create nodes for
vocabulary the project explicitly bans. Q14 item 2's "a glossary entry or convention-marked defined
term, **and nothing else**" is read here as the marker, not the document.

**Normalisation, producing `<normalised-term>`:**

1. Take the heading text; apply D2a-1 step 2 (strip inline markup delimiters, keep text).
2. **Split compounds** — insert a space at a lower-or-digit → upper boundary, and at an
   ACRONYM → Word boundary. This is the project's own term-normalisation precedent, implemented in
   `canonical/aid/scripts/kb/harvest-coined-terms.sh` as two explicit passes returning `tolower(out)`
   (the `sed s/([a-z0-9])([A-Z])/\1 \2/g` and `sed s/([A-Z]+)([A-Z][a-z])/\1 \2/g` equivalents), so
   `AidInstallCore` normalises to `aid-install-core` rather than `aidinstallcore`.
3. Lowercase.
4. Replace `_`, `-`, and whitespace runs with a single `-`. (`harvest-coined-terms.sh`'s
   `splitcompound` does the same `gsub(/[_-]/," ")`, so `AID_HOME` → `aid-home`.)
5. Delete every character outside `[a-z0-9-]`; collapse runs of `-`; trim leading and trailing `-`.

Punctuation and whitespace are therefore fully specified, and case is fully folded.

**Plurals are NOT folded, and near-plurals are reported instead.** Q13 asks for a stated rule on
plurals; this is it, with the reasoning, because the tempting answer is wrong:

- Rule-based singularisation needs English morphology, which is irregular (so not mechanical), is
  English-specific (so violates FR-8a), and is **unverifiable** — no validator can check that
  folding `statuses` to `status` was correct rather than that folding `aliases` to `aliase` was.
- Two definitions whose labels differ only by plurality is a **glossary defect**, and §2 purpose 1
  makes the graph a KB *quality* signal. Silently merging them would hide exactly the class of thing
  this artifact exists to surface.
- So identity is **exact after steps 1–5**, and **V15** emits an advisory `[LOW]` finding when two
  distinct normalised terms differ only by a trailing `s`/`es` or an `ies`↔`y` alternation. The
  ambiguity becomes a report, which is the same measure-and-warn posture Q14 item 7 and NFR-8 adopt
  for scale.

**Aliases are not part of identity.** This repository's glossary carries an `**Aliases:**` line that
the shipped template does not define. It is therefore treated as **optional and tolerated**: a
concept id is **never** derived from an alias, no alias creates a node, and nothing in this contract
degrades when the line is absent. Feature-005 may use it as a mention-detection aid; that is its
call, not this schema's.

**Disambiguation — two genuinely distinct concepts sharing one label.** §5.3 hands this rule to the
SPEC; it is:

- If **exactly one** definition block in the KB normalises to `<normalised-term>`, the id is the
  plain `kb:concept:<normalised-term>` and it resolves.
- If **two or more** do, the plain form is **never emitted** for that term. Each definition instead
  gets a **document-qualified** id, `kb:concept:<normalised-term>@<doc>`, giving one node per
  definition — so nothing is merged wrongly and nothing is dropped. The `@` separator is chosen
  because it lies outside the `<normalised-term>` charset (`[a-z0-9-]`), so parsing stays
  unambiguous; `<doc>` contains a `.` for the same reason.
- This is an extension of §5.3's stated grammar, authorised by §5.3's own hand-off of "a
  disambiguation rule for two distinct concepts sharing one label", and it is confined to the case
  that needs it so the common form stays clean.

**How a validator decides it, with no judgment.** **V2**'s `concept` branch resolves an id by
counting matching definition blocks and requires **exactly one**: zero is unresolvable, and two or
more is *also* unresolvable for the plain form, which is what forces the qualified form mechanically
rather than by instruction. A qualified id resolves against `<doc>` alone and likewise requires
exactly one match there. **V15** additionally reports, at `[LOW]`, every term carrying more than one
definition, so the underlying glossary defect is visible and not merely worked around. It is *not* a
gap-ledger row: FR-26 requires every ledger row to carry an offending `int:` node as evidence, and a
duplicated definition has none — the same boundary FR-8a draws for convention absences.

###### D2a-3a. **Block body** — the boundary rule, stated as an algorithm

The previous revision used "block body" without defining where a block ends. That was a real defect,
not a wording gap: with sub-headings in play, two conforming implementations could enumerate different
definition sets and both pass every validator here, which would make **V2** irreproducible and **AC-1**
uncheckable for the `concept` kind. The boundary is therefore fixed:

> **A heading's block body is the lines strictly after its own line, up to but excluding the next ATX
> heading line of *any* level 1–6, or end of file.** Equivalently: every non-heading line is owned by
> the **nearest preceding heading**, and by that one only.

**The algorithm.** One forward pass, no level stack, sharing its fence state with D2a-1's slug counter
and D2a-2's tokeniser:

````text
in_fence = false
owner    = none                      # heading currently accumulating a body
marked   = {}                        # headings whose body carries a marker

for each line L, in document order:
    if L opens or closes a ``` or ~~~ fence:
        in_fence = not in_fence
        continue
    if in_fence:
        continue                     # not a heading, and not a marker
    if L matches ^#{1,6}[ \t]:
        owner = (level, text, position)      # body starts at the NEXT line
        continue
    if owner is not none and L matches ^\*\*Definition(-as-used-here)?:\*\*:
        marked[owner] = true

concepts = { h in marked : level(h) >= 3 }
````

The block is closed by *encountering* the next heading, so no lookahead and no backtracking is needed,
and the pass is `O(lines)`.

**Why "next heading of any level" and not "next heading of the same or higher level".** The rejected
reading treats nested sub-headings as part of the parent's block, which matches document-outline
intuition — and is wrong here for three reasons, the first decisive:

1. **It is not a partition, so one definition mints several nodes.** Under same-or-higher, blocks nest,
   so a single marker falls inside its own heading's block *and* inside the block of every ancestor. A
   marker under a `######` would qualify that heading and its `#####`, `####` and `###` ancestors —
   **four** concept nodes from **one** definition, the number depending on nesting depth rather than on
   content. Worse, it would be *silent*: the ancestors carry different heading text, so their labels
   differ, so **V15**'s duplicate-definition report never fires and the inflation is invisible. That
   directly contradicts Q13's one-node-per-concept intent. Under "any level" each marker is owned by
   exactly one heading, so the map from markers to candidate concepts is a function, and the node set
   is determined by content alone.
2. **It needs no level stack**, so it is the same single forward pass as the slug counter and the fact
   tokeniser — one scan of each document computes all three, with one shared fence state. Fewer moving
   parts is fewer things that can disagree between writer and validator.
3. **Nothing legitimate is lost.** The carrier convention places the marker directly beneath the term
   heading, and that is verified rather than assumed: recomputing the nearest preceding heading for
   **every** definition marker in this KB — exhaustively, not by sample — returns a level-**3** heading
   in **every** case, with no intervening heading and no exceptions. The narrower rule therefore accepts
   every definition this KB actually carries. *(No count is given, here or anywhere in this SPEC: the
   requirements deliberately state none, and a marker tally would read as one.)*

**Fenced code is excluded from the body scan, not only from the heading counter — and both directions
matter.** The `in_fence` guard above sits *before* both the heading test and the marker test, so within
a fence:

- a heading-shaped line does **not** close a block, and
- a marker-shaped line does **not** qualify one.

The first direction is exercised heavily by real content: **44** heading-shaped lines sit inside fenced
blocks across **six** KB documents (`technology-stack.md` 18, `test-landscape.md` 10, `infrastructure.md`
7, `module-map.md` 4, `quality-gates.md` 4, `artifact-schemas.md` 1 — the last being `## <Decision title>`
at line 523, a level-2 shape). An implementation that let those terminate a block would cut bodies short
at spurious boundaries in six of the KB's documents. The second direction has **no** instance today —
no `**Definition` marker appears inside a fence anywhere in `.aid/knowledge/` or `canonical/` (checked)
— but a document quoting the glossary template inside a fence would otherwise manufacture concepts that
resolve to nothing, which is the failure AC-1 exists to catch, so the guard is specified rather than
left to chance.

**What this does to the real duplicate-slug group, concretely.** `domain-glossary.md` carries
`## Concept Spine` at line 69 and `### Concept Spine` at line 214 — the KB's only duplicate-slug group.
Applying the rule line by line:

| Heading | Block body under the rule | Marker in body? | Level ≥ 3? | Concept? |
|---|---|---|---|---|
| `## Concept Spine` (line 69) | lines 70–73, closed by `### Canonical` at line **74** — a blank line, a two-line blockquote (`> The project's native load-bearing concepts…`), a blank line | **no** | no (level 2) | **no** |
| `### Concept Spine` (line 214) | lines 215–236, closed by `### Emission Manifest` at line **237** — including `**Aliases:**` at 216 and `**Definition-as-used-here:**` at **218** | **yes** (line 218) | yes (level 3) | **yes** |

So the group yields **three** nodes with three distinct ids, and no collision between them:

- `kb:domain-glossary.md#concept-spine` — a `section` node, the `##` at line 69.
- `kb:domain-glossary.md#concept-spine-1` — a `section` node, the `###` at line 214, suffixed because it
  is the second occurrence of the slug in document order (D2a-1).
- `kb:concept:concept-spine` — a `concept` node, from the marker at line 218 owned by the `###` at 214.

The `##` at line 69 is a heading whose *text* names the concept but whose *body* is only the section's
blockquote preamble; the rule declines it, which is the right answer — the section is the container, not
the definition. And because **exactly one** definition block in the KB normalises to `concept-spine`,
V2 resolves the concept through the **plain** form: no `@<doc>` qualification is emitted and V15 raises
no advisory. That is the whole group, decided mechanically, with no reviewer judgment at any step.

**Where the two candidate rules would actually diverge, and why this KB cannot show it.** Divergence
needs a marker under a heading nested below another candidate heading — i.e. a level-4-or-deeper
heading. This KB has **none**: enumerating headings across `.aid/knowledge/*.md` returns no level 4, 5
or 6 heading at all. So on today's content the two readings produce **identical** node sets, including
for the `Concept Spine` group above, and the choice is forward-looking — made now, while the contract is
being fixed, precisely because it cannot be settled later by observation.

##### D2b. `int:` bodies

Repo-relative, `/`-separated, exact on-disk case, no leading `./`, no `\`, no `..` segment, no drive
letter, no leading `/`, and — new since the symbol clause was struck — **no `#` fragment of any
kind**. Rejecting `..`/`\` before any I/O follows the path-confinement rule `coding-standards.md`
records for `connector-secret.sh` ("both reject a `<stem>` containing `/`, `\`, or `..` before any
I/O"). The repo root is resolved once via `git rev-parse --show-toplevel`, the same way
`kb-freshness-check.sh` resolves `--repo`.

A trailing `/` marks a **directory artifact**, and directory ids remain necessary because two of this
project's artifact kinds *are* directories by its own convention: a skill is
`canonical/skills/aid-<name>/` (verified: `canonical/skills/aid-summarize/` holds `SKILL.md`,
`README.md`, `references/`) and an agent is `canonical/agents/aid-<role>/` (verified: every entry
under `canonical/agents/` is a directory, none a file). The directory form also matches the shape KB
frontmatter `sources:` entries already use. Per D1a, a directory id must carry `Kind: source-artifact`.

##### D2c. `ext:` bodies and the registry gap

`<key>` matches `[A-Za-z0-9][A-Za-z0-9._-]*` — no whitespace, no `/`, no `\`, no `..`, no `://`
scheme. Rows never carry a raw path or URL for an external node (§5.3, A-1); the key is all that
appears.

`.aid/knowledge/external-sources.md` today registers **zero entries** and says so in prose ("No
external documentation was provided during discovery", verified in its `## Sources` section), with a
placeholder `- (none)` in its `sources:` frontmatter. It therefore has no machine-readable entry
format at all. This feature defines the one the resolver reads: **within the `## Sources` section, a
GFM table row whose first cell is a key rendered as inline code registers that key** —

```markdown
| Key | Origin | Contributed to |
|-----|--------|----------------|
| `docker-dockerfile` | https://docs.docker.com/reference/dockerfile/ | integration-map.md |
```

The resolver's predicate is a single awk scan: inside `## Sources`, a line matching
`^\|[[:space:]]*` + a backticked key + `[[:space:]]*\|` registers that key. A table-first format is
chosen because `authoring-conventions.md` makes tables the primary structure for KB reference
material and `external-sources.md` already carries one for its `## Change Log`. Against today's
prose-only file the predicate registers zero keys, which is the literal truth and exactly why Q4
resolved to a fixture: AC-1's `ext:` branch is proven against a self-built synthetic
`external-sources.md` supplying both resolvable and deliberately unresolvable keys (A-6 — fixtures
are self-built and depend on no work folder).

**This gap is more urgent than it was, per D-5.** `ext:` was a minor branch when it carried only
external-source references; it now carries the `web-page` and external `image` **node kinds**, which
the graph is expected to display. And D1a records that `image` versus `web-page` cannot be recovered
from the key, so the missing format is also the reason one arm of the kind cross-check is
unverifiable. Two consequences are recorded rather than assumed: `/aid-graph` is read-only with
respect to the KB (FR-10) so it can never *register* a key itself; and the writer of
`external-sources.md` is `/aid-discover`'s ELICIT state, so emitting this table form — and extending
it to record a media type — is an upstream change outside this feature's scope. See Open Items.

##### D2d. Section-id stability under heading renames — **author decision 4** (Q15)

A `section` id is a **derived address, not a durable identifier**, and this SPEC does not promise
rename stability. What it does promise is that a rename is never *silent*:

1. **Within a run, no dangling id can be written.** Ids are recomputed from the current document text
   on every run and are never authored by hand, so a renamed heading produces a new id and the old id
   simply does not appear. **V2** exists for the hand-edit case, and turns a stale id into a
   mechanical finding rather than a dead link.
2. **Across runs, the rename is a detectable event.** A heading rename changes the KB, so FR-11's
   staleness check fires and the table regenerates. Because rows carry a **total** order (D7), the
   result is a git diff of `relationships.md` showing exactly one id removed and one added, attached
   to the rows that moved. That is visible, attributable churn — not drift.
3. **The exposure is bounded by an existing one.** D2a-1's slug is computed from the heading text by
   the rule the KB's own `## Contents` links encode, so a renamed heading breaks the graph's "open the
   artifact" target by exactly the same mechanism, and at exactly the same moment, as it already breaks
   those hand-maintained links. The graph is no worse than the document it describes. This argument
   needs only that the slug tracks the heading text — which every rule in D2a-1 does, verified or not —
   so it is unaffected by Open Item 14.

What would be needed for genuine rename stability is a heading-level durable-anchor convention in the
KB — an explicit, author-assigned id per heading. No such convention exists, no requirement asks for
one, and introducing one is a **KB authoring-convention change**, not a feature of this work. Recorded
under Open Items with that owner named rather than absorbed here.

#### D3. `Provenance` enum

Closed, lowercase, exactly one value per row, never empty (A-3 — provenance is required by
construction):

| Value | Meaning | Producer |
|-------|---------|----------|
| `declared` | stated outright in the KB or the source | feature-005 pass 1 |
| `derived` | computed by a deterministic scan, no judgment | feature-005 pass 1 |
| `inferred` | concluded by the agent from reading | feature-005 pass 2 |

`declared` and `derived` together form the **deterministic class** (class 0); `inferred` is
class 1. The class partition is what FR-32/AC-5 is stated over and what D7's ordering rule
makes contiguous.

**This column is *edge* provenance, and conflating it with node provenance would produce a wrong
validator.** Q13 records that "a fact node's provenance is always `declared` or `derived`, never
`inferred`". That is a property of the **node record** feature-004 owns, not of the rows here: FR-31a
part 2 lets Pass 2 create **edges** over nodes that already exist, so an `inferred` edge touching a
`fact` node is legitimate. No validator here restricts a row's provenance by the kinds at its ends.
Stated explicitly because the plausible-looking rule — "a row touching a `fact` may not be
`inferred`" — would forbid exactly the reading-dependent edges FR-31 exists to produce, which is the
same mistake FR-31a's first draft made and Q15 records being corrected.

FR-24's rule that a reported KB gap must carry `declared` or `derived` provenance is enforced on
feature-004's node evidence, not on this table; this enum is what makes that enforcement expressible.

#### D4. Vocabulary loading — core plus project extension — **author decision 6** (Q15; FR-4, FR-4a)

**What survives from the previous revision, and what does not.** The **carrier** survives intact: the
restricted-YAML subset, the two top-level keys, one key per physical line, a declared key set in a
fixed order, and the `categories:` block with its `|` separator.
`canonical/aid/templates/graph/relation-vocabulary.yml` exists on disk with that carrier today, and
this SPEC reuses it as a *format*. Its **contents** do not survive — Q10 supersedes the harvested pairs
as the basis of the vocabulary, and feature-001 is re-researching them standards-first (SKOS, DCMI
Terms, PROV-O, schema.org, IANA RFC 8288, CiTO). Nor does the **field contract that file's header
comment documents**: as of 2026-07-30 the declared key set is the table below, and `endpoint_kinds` is
keyed on kinds rather than on prefixes, so the file on disk is superseded on both counts and rewriting
it — header comment included — is feature-001's execution work, not this SPEC's. No relation label
appears anywhere in this feature's code or tests; the tests run against a *fixture* vocabulary. A
reviewer can prove the split by grepping the `graph/` script tree.

**Ownership.** Feature-001 owns the core vocabulary's schema **and** its content — which relation
types exist, what each field means, and each field's value rule — and creates the core file. This
feature owns the **loader and validation contract**: how the files are parsed, how core and extension
are merged, which invariants the loader enforces, and what happens when a file is absent, empty, or
malformed.

**Two files, two trees — location and precedence (FR-4a).**

| Role | Path | Written by | Absent ⇒ |
|------|------|-----------|----------|
| **Core** | `<install-root>/aid/templates/graph/relation-vocabulary.yml`, authored at `canonical/aid/templates/graph/relation-vocabulary.yml` | feature-001; shipped and upgraded with the tool | **exit 2** — fail closed |
| **Project extension** | `.aid/graph/relation-vocabulary.yml` | the project, by hand; never by `/aid-graph` | core only; **not an error** |

The separation is what makes FR-4a's "an upgrade never overwrites project-defined pairs" structural
rather than procedural: the installer writes only under the install root and has no reason to touch
`.aid/graph/`, so there is no code path by which an upgrade could reach the extension.
`.aid/graph/` is deliberately **not** in `.gitignore`'s AID-managed block (which ignores `.aid/.temp/`,
`.aid/.trash/`, `.aid/.heartbeat/`, `.aid/.control/`, `.aid/generated/` and `.aid/knowledge/.cache/`
— verified), so the extension is committed and travels with the project. `.aid/` is the right parent
because it already holds project-level, non-KB registries maintained outside `settings.yml` —
`.aid/connectors/` is the precedent. The extension is **not** a section of `.aid/settings.yml`,
because FR-11 counts settings and the vocabulary as two **separate** staleness inputs and folding
them would make one indistinguishable from the other.

**Format: identical to the core, deliberately.** The extension file carries the same two top-level
keys (`pairs:`, `categories:`), entries carrying the same declared keys in the same fixed order, and the same
restricted YAML subset. One parser reads both, so there is no second format to specify, test, or
drift.

**Precedence: there is none, by design.** FR-4a permits a project to **add** pairs and **add**
categories, and forbids redefining or removing a core pair, with a collision a **hard failure**
rather than a silent override. So the loader forms the **union** and rejects overlap:

- An extension entry whose `relation` equals any core entry's `relation` → **exit 2**, naming both
  resolved absolute paths and the colliding label.
- **`categories:` name uniqueness over the merged block** — no name is declared twice, so an extension
  name equal to a core name → **exit 2**. Without this, an extension could silently redefine a core
  category's *meaning* while adding no relation at all. This is the check that **owns** name
  uniqueness: cross-entry property 5, category *totality*, checks only that a name an entry
  **references** is declared (feature-001 SPEC.md:595–602).
- The cross-entry properties are then checked over the **merged** set, not per file.

**"May not redefine a core pair" needs no special rule beyond the above — involution enforces it.**
If an extension adds `foo` with `inverse: <core-relation>`, then `inverse(inverse(foo))` is that core
relation's own inverse, which is not `foo`, so involution fails and the load exits 2. The prohibition
falls out of a property the loader already checks, which is why it cannot be forgotten.

**File shape** (values are placeholders — this feature fixes no vocabulary member; the
`endpoint_kinds` tokens carry real **kind** names only because the `Kind` enum is this SPEC's own
data, D1a, while `derived_from`'s standard key stays abstract for the reason its note below gives):

```yaml
pairs:
  - relation: <relation>
    inverse: <inverse>
    symmetry: asymmetric          # or: symmetric
    category: <category>
    derived_from: ["<standard>:<term>"]           # or exactly ["coined"] — never in the core
    endpoint_kinds: ["section->concept", "document->concept"]
    passes: [declared, derived]
    definition: "<one sentence>"

categories:
  - "<name>|<one-line meaning>"
```

Precedent for the physical shape, on both counts: `canonical/aid/templates/shortcut-catalog.yml` is a
`.yml` under `canonical/aid/templates/` holding a block sequence of flat mappings, machine-read by
tooling *and* by a shell consumer — `tests/canonical/test-catalog-dirs-parity.sh` parses it in awk
and names the subset it relies on ("Restricted YAML subset (flat single-level mappings, one row per
`- name:` line)"). This spec adopts the same shape and the same restricted subset. YAML is used
because the runtime consumers are shell and the repo ships no YAML library for shell.

**Entry shape — the declared keys, fixed order, one key per physical line.** The table below **is the
declared key set for this contract**; it is the authority, not its length, so a field feature-001 adds
lands as a new row here and no count elsewhere has to be chased. **Row order below is the fixed key
order the loader enforces**, which is why `derived_from` arrived as an insertion at position 5 rather
than as an append: feature-001 D2 fixes the position and states the rule for every future key — new
keys are inserted before `endpoint_kinds`, never after `definition`, so the one prose field stays
terminal (feature-001 SPEC.md:318–324). The table is what the loader accepts and rejects;
feature-001's SPEC remains authoritative on what each field *means*.

| Key | Physical form | Value space this loader enforces |
|-----|---------------|----------------------------------|
| `relation` | plain scalar, **always the entry's first key** (`  - relation:`) | required, non-empty, `[a-z][a-z0-9-]*`; **unique** across the merged `pairs:` |
| `inverse` | plain scalar | required, `[a-z][a-z0-9-]*`; must itself appear as some merged entry's `relation` |
| `symmetry` | plain scalar | closed enum `asymmetric` \| `symmetric` |
| `category` | plain scalar | required, single-valued; **must be a name declared in the merged `categories:`** |
| `derived_from` | one-line **flow sequence** of double-quoted tokens | required, non-empty; each token is either exactly `coined` or matches `[a-z][a-z0-9]*:[A-Za-z][A-Za-z0-9-]*`; `coined` never shares an entry with a `<key>:<term>` token, and **never appears in an entry read from the core file** — see the note below on the one clause of this field's value rule the loader deliberately does not check |
| `endpoint_kinds` | one-line **flow sequence** of double-quoted tokens | non-empty; each token `<kind>-><kind>` with **both sides a name in the `kinds:` list `rel_load_schema` already holds** (D1's YAML, D1a's table) — **not** the prefix set; a token naming an id prefix is a defect rather than a tolerated legacy form |
| `passes` | one-line **flow sequence** | non-empty subset of `declared`, `derived`, `inferred` — the same three values D3's `Provenance` enum holds |
| `definition` | double-quoted scalar, one physical line | required, non-empty |

`categories:` is a block sequence of double-quoted `"<name>|<one-line meaning>"` scalars — the same
intra-entry `|` separator `.aid/settings.yml` uses for `knowledge.doc_set` (verified). It is the
closed set every entry's `category` is checked against, which is how category totality becomes
mechanical here.

**`derived_from` is validated for shape and for its core prohibition, and deliberately not for
standards membership.** feature-001 D2 makes per-term attribution a required key (feature-001
SPEC.md:296–311, the field at :308; "All eight keys are required in a fixed order; an absent or empty
value is a defect and exits 2", :299–300). That field's value rule has four clauses (:308) — the
flow-sequence shape, the token grammar, `coined` forbidden in a **core** entry, and `coined` never
alongside a standard token in any entry. This loader enforces the first, third and fourth in full, and
the second **less its standard-key membership**. The core prohibition is enforceable here because the
loader reads core and extension as two separate positional arguments and so knows which file an entry
came from; it is the mechanical half of FR-5, and it is the reason `derived_from` is enforced rather
than merely carried through like `category`: "because
`coined` is forbidden in the core, a core entry with no standard behind it cannot load" (feature-001
SPEC.md:359–365). A loader tolerating the key's absence would let a core entry ship with no standard
behind it, which is the defect feature-001's re-specification exists to make impossible.

What is **not** checked here is membership of a token's `<key>` in the closed standard-key set
feature-001 D1 declares. Two reasons, and the second is binding. Unlike the `Kind` enum, that set has
no data carrier this loader reads, so checking it would mean writing the standard keys into this
feature's own files — and feature-001's **AC-S11** makes "a reviewer greps the shipped `graph/` script tree for any
relation label, category name or **standard key** from this vocabulary" and finds nothing a stated
criterion (feature-001 SPEC.md:207–209). That is the same one-copy discipline the re-key below rests
on, applied where there is no copy to share, and it is the same split D4 already draws for relation
labels: the loader knows the *shape* of vocabulary content and never its *values*. So a mistyped
`skos2:broader` loads. In a **core** entry it is then caught by feature-001's **AC-S2** token audit —
but AC-S2 opens "Given the delivered **core** vocabulary" (feature-001 SPEC.md:167–172), and the
extension is project-authored and never written by AID (the table above), so in an **extension** entry a
mistyped standard key is caught by **nothing**: not by exit 2 here, not by AC-S2 there. Said plainly
because the previous revision named a catcher that does not reach the case, and routed as **Open Item
16** rather than absorbed. Stated rather than left to be discovered, because "every declared key is
validated" below would otherwise read as a stronger claim than this one field can honour.

**`endpoint_kinds` is keyed on §5.2's `Kind` values, not on the three id prefixes — the flag this SPEC
raised, answered by its owner.** The previous revision recorded the prefix form as under-expressive and
left the token form open as feature-001's call: with the widened enum, `"kb:->kb:"` cannot distinguish
a document *defining* a concept from a section *mentioning* one, so a standards-first vocabulary
(FR-5) carries relation types whose legal endpoints that form cannot state. feature-001 has settled it
and re-keyed the field (feature-001 SPEC.md:378–397; routed back here as its Open Item 2, :1534–1538;
its **AC-S4** requires that no token names an id prefix, :177–179), which **closes this SPEC's Open
Item 12**. The consequence here is exactly the one that note predicted — **one value rule replaced by
another** — and it needs no new data: the kind names are already in `relationship-schema.yml`'s
`kinds:` list, which `rel_load_schema` loads before any entry is read (D1, D1a, D9), so the loader
validates against an enum it already has in memory and the vocabulary file carries **no** second copy
of a closed set (feature-001 SPEC.md:391–397). Two things do not change: the field is still
feature-001's, and this loader still enforces whatever form the vocabulary declares; and the prefix
set stays in use for the id/kind pairing V13 checks (D1a). The re-key moves `endpoint_kinds` off the
prefixes, not the ids.

**The re-key is visible in a row of this SPEC's own shape, which is the cheapest way to check the two
contracts agree.** feature-001's worked row for its AC-S6 types `kb:domain-glossary.md#aid_home` →
`kb:concept:aid-home` as `section` → `concept` with `defines` / `defined-by` (feature-001
SPEC.md:1141–1152). Under the prefix form that row's endpoint pair was `"kb:->kb:"`, indistinguishable
from a section that merely *mentions* the term; under the kind form it is `"section->concept"`, which
both `defines` and `mentions` may declare — so V12 accepts either typing and its precision now rests on
the **relation** rather than on the prefix. The same row shows the ownership boundary holding: every id,
kind and display name in it follows this SPEC's D1, D2 and D5 unchanged.

What the re-key does change is how much a mistake can hide. The token space is no longer the square of
the prefix set but the square of the `Kind` enum — feature-001 SPEC.md:387–389 states both sizes, and
this SPEC cites them rather than restating them, per D7's standing rule — which is what turns the next
property from something a reviewer could eyeball into something the loader has to check.

**Pair coherence is the sixth cross-entry property, and it gates for the same reason the other five
do.** feature-001 adds it (its D4 property 6, SPEC.md:519–531; routed here as its Open Item 3,
:1539–1543) and its **AC-S5** states the criterion this loader decides, in the same terms the bullet
below uses (:180–183). It qualifies as a gate by the line feature-001 draws and this SPEC already
applies to the other five — a check gates exactly when it is decidable from the vocabulary files
alone, and reports exactly when it depends on a producer set or a corpus (feature-001
SPEC.md:447–458, layer **W2**). Pair coherence is decidable here: one set comparison per pair over
data the loader has already parsed, with no KB, no producer map and no generated table involved. Why
it is worth gating: the transpose clause catches the single most likely authoring error once endpoint
sets can be long — updating one half of a pair and forgetting the other, which feature-001 records a
reviewer could see under the prefix form and cannot under this one (SPEC.md:460–473) — and each
agreement clause turns a silent inconsistency into a load failure, because halves disagreeing on
`category` would show one direction under FR-6a's filter and hide the other, halves disagreeing on
`passes` would make a row legal read one way and illegal read the other with a single `Provenance` to
answer for both, and halves disagreeing on `derived_from` would attribute one relationship to two
standards (feature-001 SPEC.md:523–531). `symmetry` needs no clause because property 4 already forces
it, and `definition` needs none because the two halves are different prose by design.

**One consequence for the fixture set, and it is not completionist coverage.** feature-001 records
that every symmetric entry the core ships declares same-kind tokens only, each its own transpose, so
the transposition-closure clause is **vacuously satisfied by the core as delivered** (feature-001
SPEC.md:559–567). That is the same shape as this SPEC's `image` + `ext:` case and AC-1's `ext:` branch:
the real repository cannot exercise the clause, so it would pass vacuously and an implementation that
skipped the symmetric branch entirely would pass everything else.
feature-001's **AC-S9** names both negative fixtures the loader therefore owes — a non-transposed
asymmetric pair, and a symmetric entry whose set is not closed under transposition (:197–203). Both
are listed under Layers & Components, together with one fixture per agreement clause.

**No new `AC-S<n>` is minted here for it, and that is a decision rather than an omission.** The other
five properties carry no criterion of this SPEC's own either — they answer feature-001's AC-S1 — so
numbering only the sixth would misrepresent the set, and stating one criterion in two documents is the
drift the one-copy discipline above exists to avoid. A task DETAIL cites **feature-001 AC-S5** plus the
D4 bullet below, exactly as it does for the other five. Contrast D7a-1, where **AC-S3** *was* minted:
that ordering rule is this SPEC's own invention and no sibling states it.

Loader contract (`rel_load_vocabulary`, D9):

- **Parse.** A single forward pass per file with one flush point: a four-space-indented `key: value`
  line belongs to the most recent `  - relation:` line, and an entry ends at the next
  `  - relation:`, at `categories:`, or at end of file. Comments (`#`) and blank lines are skipped
  anywhere. Implemented as a small awk state machine — the class of parser
  `test-catalog-dirs-parity.sh` already proves sufficient for a block sequence of flat mappings in
  this repo. It is **not** a `read-setting.sh` `lookup_list` reuse: that helper handles flat-section
  dotted-path lookups plus list-valued top-level keys and defers to `yq` for anything nested, and a
  sequence of mappings is past it. Writing the state machine here rather than acquiring `yq` keeps
  the toolkit's zero-runtime-dependency posture. Values are read as **opaque data**.
- **The restricted subset is enforced, not assumed.** No anchors, aliases, merge keys, multi-line
  block scalars (`|`, `>`), or a second document (`---`); no nesting below an entry's scalar and
  flow values; `derived_from`, `endpoint_kinds` and `passes` on one physical line each. Any of these →
  exit 2. This is what makes two independently written loaders read the same values.
- **Every declared key is validated, whether or not this feature consumes it.** An entry missing a
  key, carrying one twice, carrying a key outside the declared set, holding an empty value, or presenting
  its keys out of the fixed order → exit 2 with an actionable message naming the resolved absolute
  path of the file, the entry's `relation` (or its ordinal, when `relation` is what is missing),
  and the offending key. Being tolerant of the fields it does not use while still refusing a
  malformed one is deliberate: this loader is the single mechanical check on the vocabulary's shape,
  so it must not silently pass a defect in a field only a sibling feature reads.
- **Cross-entry invariants over the merged set** — this list is the authority, not its length, and it is
  enforced here rather than assumed: **closure** (every `inverse` is some entry's `relation`), **totality** (every entry has all
  declared keys, checked above), **involution** (`inverse(inverse(r)) == r`), **symmetric consistency**
  (`symmetry == symmetric` iff `inverse == relation`, `asymmetric` iff not — no third case),
  **category totality** (every entry's `category` is declared in the merged `categories:` — a
  **reference** check only; re-*declaration* of a name belongs to the name-uniqueness check above,
  which is where this SPEC now states it), and **pair coherence** (for every asymmetric pair
  `(r, r')`, `category`, `derived_from` and `passes` are **equal** across the two entries — equality as
  defined immediately below — and `endpoint_kinds(r')` is the
  exact **transpose** of `endpoint_kinds(r)` — `"a->b"` is declared on `r` iff `"b->a"` is declared on
  `r'`; for every symmetric entry, `endpoint_kinds` is **closed under transposition**, so a symmetric
  entry declaring `"source-artifact->image"` without its mirror is rejected outright). Plus `relation`
  and `categories:`-name uniqueness. Any violation → exit 2. These are file-level defects, never row
  findings.

  **What "equal" means, spelled out because a gating verdict may not be implementation-defined.**
  `derived_from` and `passes` are multi-valued, so equality has two readings and **exit 2** would
  otherwise turn on which one an implementer picked. They compare as **token sets**: order is not
  significant, and a pair listing the same tokens in a different order — or one repeating a token — is
  coherent and must not fail the load. The reading is feature-001's own rather than this SPEC's
  invention: `passes` is specified as a *subset* of `declared`/`derived`/`inferred` (SPEC.md:310),
  `derived_from` as a pair-level attribution whose two halves "carry the same **set**" (:326–332), and
  **AC-S5** states the clause as the two entries "**agree on**" those keys rather than as sequence
  equality (:180–183). It also makes every clause of this property compare sets, since the transpose
  clause already does — the `iff` above is set semantics written out. `category` is single-valued (the
  entry table above), so scalar equality is the only reading available to it.
- **Entry order is not enforced.** Sorting `pairs:` by `category` then `relation` is an authoring
  convention with no acceptance criterion behind it, and membership and pairing are order-free, so
  the loader neither requires nor checks it.
- **Membership** (V3): a label is valid iff it is some merged entry's `relation` or `inverse`.
- **Pairing** (V4): the ordered pair `(S2T, T2S)` is valid iff some merged entry has
  `relation == S2T && inverse == T2S`, **or** `relation == T2S && inverse == S2T`. Accepting the
  mirror is what makes D7's orientation normalisation safe. A **symmetric** entry
  (`relation == inverse`) is permitted and yields rows where `S2T Relation == T2S Relation`;
  V4 accepts those rows rather than reading them as "the two directions disagree" — the edge case a
  naive validator gets wrong. And because D7 normalises orientation *before* keying, a symmetric
  relation's `(A,B)` and `(B,A)` rows collapse to a single `rel_row_key`, which is what AC-3 requires
  for the symmetric case.
- **Which fields this feature uses, and which it only carries — the loader's exposure surface is the
  union of the two** (feature-001's consumer table, SPEC.md:1294–1304, is the authority on who reads
  what, and every consumer reads through this loader). `relation` + `inverse` drive V3 and V4.
  `category` is carried through untouched and exposed to feature-006/007/008/009 as FR-6's grouping
  dimension and FR-6a's filter axis; this feature never interprets it. `definition` is likewise carried
  through untouched and exposed to feature-009, which labels the accessible table with it (feature-001
  SPEC.md:1300); this loader checks only that it is present, non-empty and one physical line.
  `endpoint_kinds` drives **V12** in both its
  directions — an advisory on a row whose **`(Source Kind, Target Kind)`** pair the chosen relation
  does not list, and an advisory over the declared tokens no row exercised — advisory because AC-2 is
  scoped to membership and inverse consistency only. `symmetry` is read, enforced against
  `inverse == relation`, and used by V4 as the *declaration* that a self-inverse entry is intentional;
  V4 lives in this feature, so `symmetry` needs no accessor beyond it. `passes` is validated here and
  **exposed** to feature-005, which reads it through this loader as its pass-legality axis and never
  re-parses the file (feature-005 SPEC.md:643–657); this validator itself never reads it.
  `derived_from` is validated here and interpreted by **no** runtime consumer at all (feature-001
  SPEC.md:359–365) —
  which makes this loader the only mechanical check that field will ever get, and is precisely the case
  the "every declared key is validated" rule above exists for.
- **Missing core file, absent `pairs:` key, or a present-but-empty `pairs:`** → exit 2, naming
  feature-001 as the blocking dependency (D-1). Failing closed is deliberate: an absent vocabulary
  must halt validation, never silently pass every row.
- **Missing extension file** → not an error; the merged set is the core set. Most projects will have
  no extension, and treating its absence as a failure would break FR-8a's genericity claim on the
  majority case.
- **Override flags for tests.** `--vocabulary <path>` and `--vocabulary-extension <path>` point the
  loader at fixtures. These exist because AC-12 requires proving that a change to the **vocabulary**
  staleness input triggers regeneration, and the core vocabulary ships inside the tool where a test
  cannot edit it in place — the mechanism Q15 lists as owed. This SPEC supplies the loader-side
  flags; wiring them into the staleness digest is feature-010's, and is recorded under Open Items.

#### D5. Display-name rule

`Source Name` / `Target Name` are **derived values, never authored per row**. For `document`,
`source-artifact`, `image` and `web-page` they are pure functions of the id. For `section`, `fact` and
`concept` they are functions of the id **and the document it names** — necessarily, because a slug or
a token is not invertible to the text it came from. Both classes are deterministic and both are
recomputable by the validator, which is what keeps AC-1 checkable in both directions and removes a
churn source from FR-32.

| `Kind` | Name |
|--------|------|
| `document` | `<doc>` |
| `section` | `<doc> § <heading-text>` — heading text verbatim, `#`s and surrounding whitespace stripped, inline markup delimiters removed |
| `fact` | `<doc> § <anchor-string>` — the grep-recoverable anchor string verbatim, whitespace runs collapsed to single spaces |
| `concept` | `<term-as-written>` — the defining heading's text verbatim; for a qualified id, `<term-as-written> (<doc>)` |
| `source-artifact` | `<path>` or `<path>/` verbatim |
| `image` (in-repo) | `<path>` verbatim |
| `image` (external) / `web-page` | `<key>` |

**No truncation is applied to a stored name**, even though a `fact` name can be long. Shortening for
legibility is a *render-time* concern owned by feature-007 and feature-009, not a stored value — the
same division the previous revision established for long `int:` paths, and for the same reason: the
full repo-relative path is the name because a basename is not unique in this repository
(`build-kb-index.sh` exists at several paths).

For a node feature-004 emits, the name must equal that node record's `name` field, which is where
feature-004's per-kind naming lives. This feature enforces only that **the same id never carries two
different names, and never two different kinds, anywhere in the file** (V8).

#### D6. `Observation` cell

Optional, and constrained by provenance so it cannot destabilise class 0:

- On a `declared` or `derived` row, `Observation` is either empty or a **rule-derived durable
  anchor** — a path plus a grep-recoverable symbol, heading, or unique string, per
  `authoring-conventions.md` § "Citation Rule (Durable Anchors)". Free prose is forbidden here,
  because prose is not reproducible and would break AC-5.
- On an `inferred` row, free prose is permitted; §5.4 designates `Observation` as the home for
  nuance no vocabulary pair captures.
- A bare `file.ext:LINE` citation is forbidden in any row. This is not a new rule — it is the
  existing one `kb-citation-lint.sh` already gates mechanically, and line numbers would also
  make the row churn on every unrelated edit above them.

"Durable anchor" is given a mechanical predicate so **V11** is falsifiable rather than a judgment
call: on a class-0 row, `Observation` is empty, **or** its first whitespace-delimited token matches
`kb-citation-lint.sh`'s own path pattern, quoted from its line 45:
`[A-Za-z0-9_.\/-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)`. A prose sentence cannot satisfy
it. The bare-line-citation half of V11 reuses that script's discrimination verbatim: a colon followed
by digits is a violation unless the next character is a letter, a `-` plus a letter, or a `.` plus a
digit (an IP or version).

#### D7. Row normalisation and ordering — **author decision 5** (Q15; FR-32, AC-5)

This feature owns the ordering contract; feature-005 implements it and feature-007 renders it.
FR-32's byte-identity requires a **total** order over the new id grammars, and this section supplies
one together with the argument that it is total.

**Normalisation.** Before comparison or sorting, a row is put in canonical orientation: if
`Source Id > Target Id` under `LC_ALL=C` byte ordering, swap the two **`(Id, Kind, Name)` triples**
and swap `S2T Relation` with `T2S Relation`. The swap is information-preserving precisely because both
readings live on one row (§5.2). Self-edges (`Source Id == Target Id`) are left as written.

**Rows are *emitted* in normalised orientation, not merely compared in it.** Byte-identity depends on
this: if normalisation were a comparison-time transform only, two runs that happened to discover the
same edge from opposite ends would emit different bytes for the same relationship. So the normalised
row is the stored row, and the sort key below reads the stored values directly.

**The triple, not the pair, is what swaps — and this is a direct consequence of the ten-column
shape.** At eight columns the rule swapped ids and names. A rule that moved ids and names while
leaving the two `Kind` cells in place would produce a row whose kinds no longer match their ids, and
**V13** would fail on a row that was correct before normalisation. Any implementation carried over
from the eight-column design has this bug.

**Row key.** `key = source_id \x1f target_id \x1f s2t \x1f t2s` on the *normalised* row (`\x1f` is
US, which cannot occur in any id or label). A verbatim repeat and a separately written inverse row
both collapse to the same key, which is what makes **V5** catch both halves of AC-3. `Kind` is
deliberately **not** in the key: an id determines its kind (V8), so adding it could only mask a
duplicate.

**Sort order.** `LC_ALL=C` lexicographic ascending over the tuple

```
(class, source_id, target_id, s2t, t2s)
```

where `class` is `0` for `declared`/`derived` and `1` for `inferred` (D3).

**Why this is a total order, which FR-32 needs and the previous revision asserted without
argument.** The last four components are exactly `rel_row_key`, and **V5** forbids two rows sharing a
row key. So on any table that passes V5 the tuple is **unique per row**, the order is strict and
total, and the emitted byte sequence is therefore uniquely determined by the row set. Byte-identity
follows from reproducing the row set, with no further tie-breaking rule to specify or forget. On a
table that *fails* V5 the order is not total — which is correct behaviour, because such a table is
already reported as defective and no byte-identity claim is made about it.

**Locale is load-bearing, not cosmetic.** `int:` ids carry exact on-disk case (D2b), so a locale that
folds or reorders case would reorder rows; `LC_ALL=C` is what removes the environment from the
contract. This follows the two repo scripts that pin the locale for reproducible output —
`build-project-index.sh` line 185 and `kb-freshness-check.sh` line 460 — and deliberately does **not**
follow `build-kb-index.sh`, whose scan uses a bare `| sort` (line 471, quoted in D2a). Every sort this
feature writes is `LC_ALL=C`.

**Class-major ordering** keeps the agent pass from destabilising the deterministic majority: the
class-0 rows are a **contiguous prefix** of the table and the class-1 rows a contiguous suffix, so
adding, removing, or rewording any `inferred` row cannot move, split, or reflow a single
deterministic row. No in-file boundary marker is used, which keeps §5.2's one-table rule intact; the
block boundary is a *predicate* (`Provenance ∈ {declared, derived}`) that the ordering guarantees is
contiguous.

**AC-5's mechanical check, and the scope it is keyed on.** FR-32's scope was corrected on 2026-07-29
from "an unchanged repository" to **all of FR-11's staleness inputs unchanged**, because a change
outside the repository can legitimately change the table: the vocabulary ships inside the tool, and so
does every script that decides what is emitted. And the deterministic majority itself grew, to cover the
section, fact and concept nodes FR-30 extracts and their declaring edges.

> **The scope is a set, never a count — a standing rule for this SPEC (Q17).** FR-11's staleness set has
> been extended **three** times (inputs 4, 5 and 6), and each time a clause that had hardcoded its
> cardinality became wrong **without being edited**. This SPEC therefore refers to "all of FR-11's
> staleness inputs" and never to a number, and where it restates the members for the reader it says so
> and defers to FR-11. The same rule applies to every other externally-owned set this SPEC names: cite
> the set, or enumerate it here and make the enumeration the authority — never stand a numeral in for
> either. The exception is a count that **is** the contract rather than a summary of one, such as D1's
> ten columns, where the number is normative and changing it is a breaking change by design.

So the check is: regenerate, then byte-compare **two** extractions against the previously committed
artifact obtained with `git show HEAD:.aid/knowledge/relationships.md` —

1. the class-0 row block (the contiguous prefix) — extracted by the procedure in D7b, and
2. the whole `## Coverage notes` section (D7a) — **whole**, extra rows included, which is sound only
   because D7a-1 gives those rows a total order and V14 enforces it.

Both are inside the byte-identity boundary; the class-1 rows and the sibling-owned frontmatter
scalars (D8) are outside it. This needs no side-channel file and no stored hash, and it reuses the
git-native comparison style `kb-freshness-check.sh` already established. `.aid/knowledge/` is not
gitignored (verified — only `.aid/knowledge/.cache/` is), so the previous blob is always available.
Whether a staleness *decision* is taken from that comparison is feature-010/FR-11's call.

#### D7a. `## Coverage notes` — shape and byte-stability (FR-9a, AC-19, AC-20)

FR-9a requires this section on **every** run, not only when something is missing, and AC-20 exists
because an implementation that wrote notes only on failure would satisfy every other criterion while
violating FR-9a on every healthy project. This feature owns the section's **shape and validation**;
its *content* is produced by feature-004 (enumeration and exclusions), feature-005 (extraction
counts) and feature-010 (run orchestration).

Two tables, each opening with a **fixed row set in a fixed order** — and, below it, any extra rows the
producers contribute, ordered by D7a-1. Both parts are byte-stable, which is what puts the whole section
inside AC-5's comparison:

```markdown
## Coverage notes

### Node kinds

| Kind | Carrier convention | Status | Nodes |
|------|--------------------|--------|-------|
| document | KB documents under `.aid/knowledge/` | present | <n> |
| concept | definition marker under a level-3+ heading | present | <n> |
| fact | checkable source anchor (path + grep-recoverable string) | absent | 0 |
| section | ATX headings, levels 2-6 | present | <n> |
| source-artifact | project source, per FR-21 significance | present | <n> |
| image | image files in-repo; external image keys | present | <n> |
| web-page | entries in the external-sources file | absent | 0 |

### Enumeration exclusions

| Exclusion | Applied | Note |
|-----------|---------|------|
| generated/derived trees | yes | unconditional (FR-22) |
| vendored third-party code | yes | unconditional (FR-22) |
| `.aid/settings.yml` ignore list | no | setting absent — ignore list unavailable (D-4) |
```

The contract, and what each part answers:

- **Row set is closed and ordered by §5.2's enum**, top to bottom, with **every** kind present
  including those whose count is zero. That is AC-20 literally, and the fixed order is also what
  makes the section byte-identical across runs — a table sorted by count would reorder whenever a
  count changed.
- **Status is a closed enum**: `present` | `absent`. This is the reporting channel FR-8a and AC-19
  require for a missing convention, and FR-8a states why it is not a gap-ledger row: FR-26 requires
  every ledger row to carry an offending `int:` node as evidence, and a missing glossary has none.
- **The exclusions table carries the ignore-list status explicitly**, which is FR-22's "report"
  obligation and the reason FR-11 counts `.aid/settings.yml` as a staleness input: without it, a
  settings-only change would skip regeneration while these notes went on asserting a stale status.
- **No timestamp appears anywhere in the section**, and no value varies between two runs on identical
  inputs. Every count is deterministic because FR-31a part 2 lets Pass 2 create edges but **never
  nodes**, so node counts come entirely from FR-30's deterministic pass. That is what puts the whole
  section inside FR-32's guarantee and inside AC-5's second extraction (D7).
- **Additional rows are permitted** below each fixed table's fixed rows — for example the count of
  headings whose slug came out empty (D2a-1) or of `CONFIRMED` markers skipped for want of an anchor
  string (D2a-2) — and they are **ordered by D7a-1**, not left to the producer.

##### D7a-1. Extra rows — the total order (reopen fix, 2026-07-29)

**The defect this replaces.** The previous revision permitted extra rows below each fixed block and had
**V14** "check the fixed part and ignore the rest", while **D7 item 2** byte-compares the **whole**
section. Those two cannot both hold: with the extra rows' order unspecified, two runs on identical
inputs could emit them differently and AC-5 would fail for a reason that is not drift. The byte-identity
guarantee was therefore contingent on an ordering this SPEC never stated — a guarantee unachievable as
written. It was invisible from inside any one SPEC and surfaced only once three features had each
contributed rows; the routing that found it (feature-005's Open Item 16, naming this feature as owner of
the ordering contract) was correct, and this is that contract.

**The rule.** Within **each** of the two tables, independently:

1. The **fixed rows come first**, complete and in their fixed order (§5.2's enum order for the kinds
   table; the three FR-22 rows in D7a's order for the exclusions table). Unchanged, and still AC-20.
2. **Every row below the fixed block is an extra row.** The two groups are contiguous — no extra row may
   appear between or above fixed rows.
3. An extra row's **key is its first cell**, and it matches `[a-z0-9][a-z0-9-]*` — the same
   `[a-z0-9-]` charset D2a-3 already fixes for `<normalised-term>`, reused rather than reinvented, and
   ASCII so that step 5's collation is well defined.
4. An extra row key **must not equal any fixed row key** in its table, and **must be unique** among the
   extra rows of that table.
5. Extra rows appear in **`LC_ALL=C` ascending order by key**.
6. An extra row carries the **same cell count** as its host table.

**Why this is a total order — the same argument the gate already accepted for D7.** Step 5 orders on a
single component, so it is total exactly when that component is unique per row, and step 4 is what makes
it unique. This is deliberately the identical shape as D7's row order, whose totality rests on **V5**
forbidding two rows to share a row key: one rule creates the uniqueness, the sort consumes it, and there
is no secondary tie-break to specify or forget. As there, a table that violates step 4 is reported as
defective and no byte-identity claim is made about it.

**Collation.** `LC_ALL=C`, per D7 — this work's precedent, and deliberately **not** `build-kb-index.sh`'s
bare `sort` (line 471). Step 3's ASCII-only charset is what makes the byte order the only order.

**Why the key, and not the producer file or a declared rank.** Three candidates were considered:

- **Producer file, then position within it** — rejected. It would bind this contract to feature-010's
  assembly, which is not yet specified, and to a producer set that is open. Renaming or splitting a
  producer file would silently change the artifact's bytes.
- **A declared rank per row** — rejected. It needs a central registry, which is coordination at exactly
  the point where coordination already failed, and two wave-3 features could claim the same rank
  independently. It is also the worst option for diffs: inserting a row can renumber every row after it.
- **The row's own key** — chosen. It is intrinsic to the row, needs no registry and no cross-feature
  negotiation beyond not colliding, and inserting a row adds **one line** without moving any other.

**The property that de-risks feature-010.** Because the order keys on the row and never on its origin,
**feature-010 may read and concatenate the producer files in any order** — the sort makes assembly order
unobservable in the artifact. Concretely, over the six extra rows verified to exist today across the two
producer files (`kb-coverage.tsv`: `section-empty-slug`, `fact-unanchored`, `concept-qualified`,
`concept-merge-candidates`; `coverage.tsv`: `image-external`, `source-artifact-dropped`), the emitted
order for any table receiving all six is:

```text
concept-merge-candidates   (kb-coverage.tsv)
concept-qualified          (kb-coverage.tsv)
fact-unanchored            (kb-coverage.tsv)
image-external             (coverage.tsv)
section-empty-slug         (kb-coverage.tsv)
source-artifact-dropped    (coverage.tsv)
```

The two files **interleave** — `image-external` lands between two `kb-coverage.tsv` rows — which is the
demonstration that the result is a function of the row set alone. Note also that all six keys already
satisfy steps 3 and 4 as written, so **no producer has to change anything** to conform; the rule
describes the shape those features independently chose. Which of the two tables receives which row is
the producer's decision, not this contract's; the rule applies per-table and identically either way.

**Notes stay free-form, and that is what keeps feature-005's choice worth making.** feature-005 packed
three counters into the existing `concept-merge-candidates` row's `note` rather than adding three rows,
specifically to avoid enlarging this problem. This fix preserves that incentive rather than dissolving
it: the **row set is a coordinated namespace** — a new key must be unique across every producer, must
survive step 3's charset, and is validated by V14 — while a `note` needs no key allocation, cannot
collide with another feature, and adds nothing to the ordering surface. Adding a row remains the more
expensive act, which is the asymmetry that made feature-005's call the right one. What a `note` does
**not** escape is determinism: it sits inside AC-5's comparison, so like every other cell it must not
vary between two runs on identical inputs.

**The open set — how a wave-3 row joins without invalidating an existing artifact.** It joins by sorting
into position on its key; no registry entry, no renumbering, and no change to any other row's bytes. The
comparison question is answered by **FR-11 input 6, the tool itself** — `/aid-graph`'s own installed
version, identified by its version string where one is exposed and otherwise by a digest over the
installed scripts and templates that affect output. FR-32 and AC-5 are keyed on **all of FR-11's
staleness inputs unchanged**, so input 6 puts a tool upgrade inside the staleness set: a new coverage row
ships in an upgraded tool, the digest changes, the staleness check fires, and the upgrade boundary is one
across which **byte-identity asserts nothing** — which is what FR-11 now states as the consequence, and
exactly how a vocabulary change (input 5) already behaves when it retypes edges while every repository
file stays untouched. So:

- **Within one tool version**, the extra rows are byte-stable and inside the comparison, which is the
  drift-detection value this remedy exists to keep.
- **Across a tool upgrade that adds a row**, the first regeneration legitimately **re-baselines** and
  shows a one-line diff. That is visible, attributable churn rather than drift — FR-11's own words for
  it, and the same distinction D2d draws for a renamed heading — and it is inside FR-32's stated scope,
  not an exception carved out of it.

Adding a row is therefore **not** a breaking change to this contract, but it **is** a versioned change to
the artifact, and a producer that adds one **silently within** a single tool version has broken AC-5
rather than the contract having failed to cover it.

> **Correction, recorded rather than quietly fixed (2026-07-29, ledger row 6).** The paragraph above
> previously reached this same conclusion from a **false premise**: it asserted that FR-32 was keyed on
> FR-11's inputs "and the tool is one of them", when at the time FR-11 listed only the KB, the project
> source, the external-sources file, `.aid/settings.yml`, and the relation vocabulary. The extraction and
> coverage-producing scripts were none of those, so the mechanism cited did not exist and a tool upgrade
> tripped no staleness check at all. The conclusion was right and the mechanism was wrong, which is worse
> than being plainly wrong: a sound conclusion resting on a false premise survives review and then fails
> when someone relies on the premise. FR-11 has since gained input 6 at the requirements level — the
> **third** extension of that set, after inputs 4 and 5 — and the justification above now cites it. The
> lesson generalises past this paragraph: it is why this SPEC refers to FR-11's inputs as a **set** and
> never by a count (see the note under D7's AC-5 scope).

**V14** asserts: the section is present; it appears **after** the relationship table; every enum kind
appears exactly once in enum order with a `Status` from the enum and a non-negative integer count; the
three exclusion rows are present in order; **every D7a-1 rule holds for the extra rows of both tables —
contiguity below the fixed block, key charset, no collision with a fixed key, uniqueness within the
table, `LC_ALL=C` ascending order, and matching cell count**; and no timestamp appears anywhere in the
section, extra rows included. The ordering is no longer merely stated: an order nothing validates is the
same class of defect as a guarantee nothing achieves, so V14 recomputes the sort and compares it against
the file's actual row sequence, exactly as **V10** does for the relationship table.

Because the remedy orders the extra rows rather than excluding them, **D7 item 2 is unchanged**: AC-5
still byte-compares the whole `## Coverage notes` section, and D7b's extraction is untouched.

#### D7b. Extracting the class-0 row block — the procedure AC-5 compares

The contiguity of the class-0 block is guaranteed above and enforced by **V10**, but the guarantee is
not the same thing as a way to find the boundary in a file. Stated so an implementer reading D7 alone
can reproduce it, and exposed as `rel_class0_block <file>` (D9) so it is a named, testable surface
rather than prose repeated at two call sites:

1. **Locate the table** by D1's rules: the header row, then the delimiter row, then data rows until the
   first line that is not a table row. `## Coverage notes` is below the table and is never reached
   (V14, AC-S2).
2. **Walk the data rows in file order**, reading cell 9, `Provenance`.
3. **The block ends** immediately before the first row whose `Provenance` is `inferred`. If no row is
   `inferred`, the block is every data row. No in-file marker is consulted — there is none (D7) — and no
   sort is performed: the file order *is* the sorted order on any artifact that passes V10.
4. **The extracted bytes** are the header row, the delimiter row, and those data rows, in file order,
   each terminated by LF. The header and delimiter are included **deliberately**: the ten-column
   contract (AC-S1) is part of what must not change between runs, so a column rename or reorder must
   fail the AC-5 comparison rather than slip through it.
5. **Frontmatter is excluded**, because D8 assigns some of its scalars to sibling features and they are
   outside the byte-identity boundary.

**The procedure is sound only because V10 holds, and that is a feature.** Step 3 takes the maximal
*prefix* of non-`inferred` rows, which equals *all* class-0 rows exactly when no class-0 row appears
after the first class-1 row — which is what V10 asserts. So a single forward pass suffices, with no
second scan to catch stragglers. On an artifact that **fails** V10 the extraction would under-count, and
that is the correct outcome for the same reason D7 gives for a V5 failure: such an artifact is already
reported as defective and no byte-identity claim is made about it. The validator therefore runs V10
before any AC-5 comparison is attempted (Feature Flow step 8).

#### D8. Emitted KB frontmatter (AC-18, C-7)

`relationships.md` opens with this block, as the first bytes of the file (no BOM, no blank
line before), followed by the `<!-- AUTO-GENERATED ... -->` marker, the `# Relationships`
title, the table, and the coverage notes (D1's skeleton):

```yaml
---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: Every recorded relationship among Knowledge Base documents, sections, facts and concepts, project source artifacts, images and web pages, with both readings named on one row.
summary: Read this to trace which Knowledge Base claim is backed by which source artifact or external source; it is the single input to the graph view and the machine-readable structure agents route over.
sources:
  - .aid/knowledge/
  - .aid/knowledge/external-sources.md
tags: [C2, relationships, graph, provenance, coverage, routing]
see_also: [INDEX.md, external-sources.md]
owner: architect
audience: [developer, architect]
contracts:
  - "Ten columns in fixed order: Source Id / Source Kind / Source Name / Target Id / Target Kind / Target Name / S2T Relation / T2S Relation / Provenance / Observation"
  - "Source Kind and Target Kind are members of a closed enum and agree with their id prefix"
  - "Every row carries a Provenance of declared, derived, or inferred"
  - "One row per relationship; both readings named on the same row"
  - "A Coverage notes section follows the table on every run"
---
```

Every field choice is forced by a checked fact, not preference:

- **`kb-category: primary` + `source: generated`** mirrors `INDEX.md` exactly (verified in
  `.aid/knowledge/INDEX.md`'s own frontmatter). `frontmatter-schema.md` states that this
  combination routes to the "Full Primary + Build-Verify" rubric, where both content
  correctness and generator freshness are checked — the right rubric for a generated,
  load-bearing routing artifact. Q3's resolution ("consistent with `INDEX.md` itself being
  generated") is satisfied literally.
- **`generator: build-relationships.sh`** — a bare basename naming the *build script*, as
  `frontmatter-schema.md` § "`generator:` (required iff `source: generated`)" specifies ("Name of the
  build script (relative to `canonical/aid/scripts/` or as a project-relative path)", examples
  `build-kb-index.sh`, `build-metrics.sh`, `build-project-index.sh`) and as `INDEX.md` does.
  Feature-010's SPEC named the *skill* (`aid-graph`) in this field; the schema wants the script.
  Flagged for cross-feature reconciliation rather than resolved unilaterally — see Open Items.
- **`objective:` and `summary:` are single physical lines containing no `|`.** Both are
  required: `build-kb-index.sh` reads them with `ef()`, a single-line scalar extractor scoped
  to the first frontmatter block, and pipes each through `esc()` into an INDEX table cell. A
  block scalar (`objective: |`) would render an empty Objective cell. `frontmatter-schema.md` states
  the same rule ("Single physical line (no `|`/`>` block scalars)").
- **`tags:` includes the concern id `C2`** — `authoring-conventions.md` makes the concern id a
  by-convention requirement, and C-7 names `tags` explicitly. C2 (modules/dependencies/wiring)
  is the spine dimension this artifact serves.
- **No `changelog:`, and no timestamp in the table, in the coverage notes, in any row, or in the
  `AUTO-GENERATED` comment.** This is a deliberate divergence from `INDEX.md`, which embeds a
  timestamp in both its `changelog:` entry and its `AUTO-GENERATED` comment and therefore churns on
  every run. A date inside the table or the notes would make the deterministic content differ across
  runs and defeat FR-32 outright. `changelog:` is optional and review-exempt per
  `frontmatter-schema.md`, so omitting it costs nothing. The `AUTO-GENERATED` comment carries the
  generator path and the regenerate command only.
- **Three generator-written fields are reserved for sibling features** and appear in the block
  alongside this feature's own: `graph_inputs_digest` and `graph_generated_at` (feature-010's
  content-addressed staleness record — the composite digest over **all of** FR-11's inputs, and an
  informational UTC timestamp) and `kb_gaps` (feature-006's gap list). They are named here so the
  frontmatter contract is complete, but their values, shapes, semantics, and writers belong to those
  features; this feature neither produces nor validates them. **They sit outside the byte-identity
  boundary by design** (D7): scoping byte-identity to the class-0 block plus the coverage notes,
  rather than to the whole file, is what lets a content-addressed staleness record and a gap list live
  in the frontmatter without colliding with FR-32. `frontmatter-schema.md` tolerates unknown fields
  ("Unknown fields are tolerated"), and `build-kb-index.sh` composes its INDEX row from named fields
  only, so none of the three disturbs the index generator or any lint.
- **No `approved_at_commit:`** — generator-written on approval by `/aid-discover` or
  `/aid-update-kb`, never by this skill; absence is always valid.
- **No `intent:`** — superseded by `objective:` + `summary:`.
- **`sources:` and the frontmatter lint.** `lint-frontmatter.sh` skips every `source: generated` doc
  outright (verified: its header lists "docs with `source: generated`" as out of scope, and its
  `lint_doc` body carries an explicit `# --- Skip: generated docs ---` branch on
  `[[ "$src" == "generated" ]]`), so none of these fields is lint-graded. They are emitted anyway
  because C-7 requires four of them and because a generated doc with no `objective:`/`summary:` would
  render a degraded INDEX row.

A body-level `---` thematic break is safe but is not used: `build-kb-index.sh`'s extractors exit when
they leave the first frontmatter block, so a body-level thematic-break `---` cannot re-enter
"frontmatter mode". The file's body carries no column-0 `---` line regardless.

#### D9. Loader library surface

`canonical/aid/scripts/graph/relationship-schema.sh` is sourceable and side-effect-free on
import, carrying a `Provides:` header index in the style of `lib/aid-install-core.sh`:

| Function | Contract |
|----------|----------|
| `rel_load_schema <file>` | populates the column list, required set, provenance enum, prefix set, **`Kind` enum with its per-kind permitted-prefix sets**, and `image_extensions` from D1's YAML; exit 2 on absent/empty/malformed (fail closed, D1a). The same `Kind` enum is what `endpoint_kinds` tokens are validated against (D4), so the closed set has one carrier and one loader — call this before `rel_load_vocabulary`, which depends on it |
| `rel_load_vocabulary <core> [<extension>]` | parses the entries of both files per D4, merges them, rejects `relation`/category collisions, validates every key D4 declares — including the `derived_from` clauses, for which it must know which of the two files each entry came from — and every cross-entry property D4 lists over the merged set, pair coherence included; exposes membership, pairing, and per-entry `category`, `passes`, `definition` and **kind-keyed** `endpoint_kinds` lookups — every key feature-001's consumer table routes through this loader (SPEC.md:1294–1304), `passes` for feature-005 and `definition` for feature-009; exit 2 on absent/empty/malformed core, on a malformed extension, or on any collision. A missing extension is not an error. Two declared keys are validated and **not** exposed, each for its own reason: `derived_from`, because no runtime consumer reads it (its one reader is a human, feature-001 SPEC.md:1301), and `symmetry`, because its only consumer is **V4** inside this feature |
| `rel_parse_id <id>` | splits `<prefix>` / `<body>` / `<fragment>` and returns the **kind implied by the grammar** for a `kb:` id; non-zero on a grammar violation |
| `rel_kind_prefix_ok <kind> <id>` | D1a's two-tier check, including the `image` two-prefix branch and the `image_extensions` test for `int:` ids |
| `rel_slug_heading <text>` | D2a-1 steps 1–5, without the duplicate counter |
| `rel_doc_slugs <doc>` | every emitted heading slug for `<doc>`, in document order, with the levels-1–6 counter and fenced-code exclusion applied |
| `rel_fact_tokens <doc>` | every `<anchor-token>` for `<doc>`, in document order, with the collision counter applied (D2a-2) |
| `rel_normalise_term <text>` | D2a-3 steps 1–5 |
| `rel_block_bodies <doc>` | every heading in `<doc>` with its **block body** per **D2a-3a** — body ends at the next ATX heading of any level 1–6, fenced-code lines excluded from both the boundary test and the body content |
| `rel_concept_defs <term>` | the definition blocks in the KB whose normalised label equals `<term>`, as `<doc>` values, where "definition block" is `rel_block_bodies`' output filtered to level ≥ 3 with a marker line (D2a-3a) — resolution requires exactly one (D2a-3) |
| `rel_resolve_id <kind> <id>` | resolves by the protocol for `<kind>` per D2; prints `ok` or a reason token |
| `rel_display_name <kind> <id>` | the D5 derived name |
| `rel_normalise_row <10 fields>` | the D7 orientation swap over `(Id, Kind, Name)` triples |
| `rel_row_key <10 fields>` | the D7 `\x1f` key |
| `rel_sort_key <10 fields>` | the D7 `(class, source_id, target_id, s2t, t2s)` tuple |
| `rel_coverage_extra_keys <file> <table>` | the first-cell keys of `<table>`'s extra rows (**D7a-1**), in **file order** — the fixed block is identified by its own keys and excluded. V14 compares this against its own `LC_ALL=C` sort; a mismatch is the ordering violation. Separated from the emitter for the same reason `rel_class0_block` is: the check must recompute, never trust |
| `rel_class0_block <file>` | the **D7b** extraction — header row, delimiter row, and the maximal prefix of data rows whose `Provenance` is not `inferred`, each LF-terminated, frontmatter excluded. This is the byte sequence AC-5 compares; callers must run V10 first (D7b) |

### Feature Flow

Validation is a single read-only run. Inputs, steps, outputs:

**Inputs**

1. `.aid/knowledge/relationships.md` — the artifact under test (or a fixture path via `--file`).
2. `<install-root>/aid/templates/graph/relationship-schema.yml` — D1 and D1a.
3. `<install-root>/aid/templates/graph/relation-vocabulary.yml` — the core vocabulary; created and
   authored by feature-001, read-only here. Overridable with `--vocabulary`.
4. `.aid/graph/relation-vocabulary.yml` — the project extension, if present (D4). Overridable with
   `--vocabulary-extension`.
5. The KB scan set — D2a's membership predicate
   `find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'`, consumed as a set, plus the
   text of each document for heading, anchor and definition recomputation.
6. The repo root — `git rev-parse --show-toplevel`.
7. `.aid/knowledge/external-sources.md` — the `ext:` registry (or a fixture via
   `--external-sources`).

**Steps** (`validate-relationships.sh`)

1. Parse arguments with the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop and
   `shift 2` per flag that `read-setting.sh` establishes; unknown flag → stderr + exit 2.
2. Load the schema (including both enums) and the merged vocabulary (D9). Any missing or malformed
   required input, or a core/extension collision → exit 2 before any check runs, so a configuration
   error is never reported as an artifact defect.
3. Read the frontmatter block once with the awk extractor pattern shared by
   `lint-frontmatter.sh` / `kb-freshness-check.sh` (one pass, arrays populated). Run **V9**.
4. Locate the single table above `## Coverage notes`; assert the header row and delimiter row
   byte-equal D1's forms. Run **V1** over every data row (ten cells, padding, escaping, no embedded
   newline, LF). A V1 failure is fatal for the remaining checks on that row — the row is reported and
   skipped, not guessed at.
5. Build the per-document derived sets in **one** pass per document — `rel_doc_slugs`,
   `rel_fact_tokens`, and the definition index (D2a-3a's block-body scan) — so resolution is a set
   membership test per row rather than a rescan. All three share the single fenced-code state that pass
   maintains, which is what keeps the heading counter, the block boundaries and the marker scan from
   disagreeing about where a fence begins. This is the same scan-once-then-test discipline
   `kb-citation-lint.sh` adopts in its header comment.
6. For each well-shaped row: check `Kind` membership and the two-tier kind/prefix agreement
   (**V13**); resolve both ids by the protocol for their kind (**V2**); check vocabulary membership
   (**V3**) and inverse-pairing (**V4**); provenance membership (**V6**); `int:` fragment-freedom
   (**V7**); name and kind consistency (**V8**); the `Observation` constraints of D6 (**V11**); and
   the advisory endpoint-kind check (**V12**), which reads the row's two `Kind` cells that **V13** has
   just checked rather than the ids' prefixes — the re-key costs nothing here because the kind pair is
   already computed. Then accumulate, for the second advisory step 9 emits, **both readings the row
   asserts** — `(S2T Relation, "<Source Kind>-><Target Kind>")` *and*
   `(T2S Relation, "<Target Kind>-><Source Kind>")` — never the stored `S2T` reading alone, which is
   what makes that advisory orientation-invariant (V12 below). On a row **V13 has flagged**, V12 is
   skipped and neither reading is accumulated: an advisory keyed on a pair that is not a legal kind pair
   adds nothing to a finding already reported at `[HIGH]`.
7. Accumulate `rel_row_key` per row; a repeated key is a duplicate (**V5**).
8. Assert the table's actual row order equals the D7 sort order and that class 0 is a
   contiguous prefix (**V10**). **Then, and only then, extract the class-0 row block** by D7b's
   procedure (`rel_class0_block`) — this is the extraction AC-5 byte-compares, and it is ordered after
   V10 because its single-pass prefix scan is sound only on a table V10 has passed.
9. Read the `## Coverage notes` section and check its fixed shape and position, **then recompute the
   `LC_ALL=C` sort of each table's extra-row keys and compare it against the file's actual sequence**
   (**V14**, D7a-1) — the coverage-notes counterpart of step 8's V10 check, and for the same reason:
   AC-5 byte-compares this section whole, so an unenforced order would make that comparison
   unachievable. Then emit the two advisories that need the whole table parsed before they can be
   stated: the concept-ambiguity findings (**V15**), and the declared `endpoint_kinds` tokens no row
   exercised (**V12**'s second direction, D4) — a set difference against the sets step 6 accumulated,
   needing no second pass over the file.
10. Print every finding to stdout as `[TAG] <doc>: <message>` and a
    `Checked: N rows | Findings: M` trailer, mirroring `lint-frontmatter.sh`'s output shape.

**Outputs**

- stdout: findings + trailer. stderr: diagnostics only. (`coding-standards.md`: "stdout carries the
  **result**; stderr carries diagnostics.")
- Exit codes: `0` clean, `1` one or more findings, `2` usage / unreadable input / malformed
  schema or vocabulary. This is the linter scheme `coding-standards.md` records verbatim:
  "Linters use `0` clean, `1` violations, `2` usage".
- No file writes. The skill's REVIEW state transcribes findings into the 7-column ledger at
  `.aid/.temp/review-pending/<scope>.md` and grades them with `grade.sh` (C-6, FR-28). The
  validator emits **rubric tags**, not severities — the same division of labour
  `lint-frontmatter.sh` uses with `[FM-MISSING]`/`[FM-INVALID]`.

#### Validators

V1–V12 keep their numbers and their concerns; V7 and V8 are widened and **V12 is re-keyed** as noted —
its concern, an advisory on a row's declared-endpoint legality, is unchanged, and it is re-keyed rather
than renumbered for exactly that reason; V13–V15 are new.

| # | Tag | Check | New / changed | Ledger severity | AC |
|---|-----|-------|---------------|-----------------|-----|
| V1 | `[REL-SHAPE]` | header/delimiter byte-equal D1's **ten-column** forms; every data row has 10 cells with D1 padding; no embedded newline; no unescaped `\|`; LF endings. Row reported and excluded from V2–V8, V11–V13 | **changed** — 8 → 10 cells | `[HIGH]` | — (enables AC-1–AC-4, AC-2a) |
| V2 | `[REL-UNRESOLVED]` | each id resolves **by the protocol for its `Kind`** (D2): `document` in the scan set; `section` slug in `rel_doc_slugs`; `fact` token in `rel_fact_tokens`; `concept` matching **exactly one** definition; `source-artifact`/in-repo `image` path exists; `ext:` key registered | **changed** — per-prefix → per-kind; concept exactly-one rule added | `[HIGH]` | AC-1 |
| V3 | `[REL-VOCAB]` | both relation labels are members of the **merged** core-plus-extension vocabulary | **changed** — closed set → merged set | `[HIGH]` | AC-2 |
| V4 | `[REL-PAIR]` | `(S2T, T2S)` is a merged-vocabulary pair in either orientation (D4); a symmetric relation's row (`S2T == T2S`) is **valid**, not a disagreement | unchanged in concept | `[HIGH]` | AC-2 |
| V5 | `[REL-DUPLICATE]` | no two rows share a `rel_row_key` — this is also what makes D7's order total | unchanged | `[HIGH]` | AC-3 |
| V6 | `[REL-PROVENANCE]` | exactly one of `declared`/`derived`/`inferred`, non-empty, lowercase | unchanged | `[HIGH]` | AC-4 |
| V7 | `[REL-GRANULARITY]` | no `int:` id carries **any** `#` fragment; `kb:` ids may carry section, fact and concept forms | **changed** — was "no `#<symbol>` narrowing", now total, per §5.3's struck clause | `[HIGH]` | AC-16 (table side) |
| V8 | `[REL-IDENTITY]` | each name equals `rel_display_name` for its kind; **no id carries two different names or two different `Kind` values** anywhere in the file; no name is empty | **changed** — widened to kinds (was `[REL-NAME]`) | `[HIGH]` | AC-1 (support), AC-2a (support) |
| V9 | `[REL-FRONTMATTER]` | D8's block is present and is the first content in the file; `kb-category`, `source`, `generator`, `objective`, `summary`, `tags` all present and non-empty; `objective`/`summary` single-line and pipe-free; no timestamp in the table, in any row, in the coverage notes, or in the `AUTO-GENERATED` marker. Sibling-owned and other unknown keys tolerated | **changed** — timestamp ban extended to the notes; `contracts:` text now ten-column | `[HIGH]` | AC-18 |
| V10 | `[REL-ORDER]` | actual row order equals D7's sort order; class 0 is a contiguous prefix | **changed** — key is now over the new grammars | `[HIGH]` | AC-5 (support) |
| V11 | `[REL-OBSERVATION]` | on a class-0 row, `Observation` is empty or a durable anchor, not free prose; no row's `Observation` carries a bare `file.ext:LINE` citation | unchanged | `[HIGH]` | AC-5 (support) |
| V12 | `[REL-ENDPOINT]`, `[REL-ENDPOINT-UNUSED]` | **advisory in both directions, neither gating.** Per row: the row's **`(Source Kind, Target Kind)`** pair appears in the chosen relation's `endpoint_kinds` (D4). Per run: the declared tokens **no row exercised**, as a set difference over the pairs step 6 already accumulated from **both readings of every row** — never from the orientation D7 stored the row in | **changed** — re-keyed from the prefix pair to the kind pair, and the unobserved-token direction added (feature-001's Open Item 4). Two tags, one validator: same field, same advisory posture, opposite directions | `[LOW]` | none (by design) |
| V13 | `[REL-KIND]` | **tier 1:** `Source Kind`/`Target Kind` ∈ the closed enum, and the id's prefix ∈ that kind's permitted-prefix **set** — so `image` + `ext:` passes. **tier 2:** for a `kb:` id, `Kind` equals the kind its own fragment grammar implies; for an `int:` id, `image` iff the extension is in `image_extensions:` and `source-artifact` otherwise, with a trailing-`/` id always `source-artifact` | **new** | `[HIGH]` | AC-2a |
| V14 | `[REL-COVERAGE]` | `## Coverage notes` present, positioned **after** the table; every enum kind appears exactly once in enum order with a `present`/`absent` status and a non-negative count; the three FR-22 exclusion rows present in order; no timestamp anywhere in the section, **extra rows included**. **Extra rows are enforced, not ignored (D7a-1)**: per table, they form a contiguous block below the fixed rows; each key matches `[a-z0-9][a-z0-9-]*`; no key equals a fixed key; keys are unique within the table; the actual row sequence equals the recomputed `LC_ALL=C` ascending sort of those keys; and each row's cell count matches its host table | **new** — extra-row clauses added 2026-07-29 (reopen, Q19) | `[HIGH]` | AC-20, AC-S3, AC-19 (support), AC-5 (precondition) |
| V15 | `[REL-CONCEPT-AMBIG]` | **advisory** — a normalised term carrying more than one definition (so the qualified `@<doc>` form is required, D2a-3); and two distinct terms differing only by a trailing `s`/`es` or `ies`↔`y`. Reports, never merges; never gates | **new** | `[LOW]` | none (by design) |

V1–V11, V13 and V14 map to `[HIGH]` because each maps to a stated acceptance criterion; no middle
tier is defined, so a passing grade cannot be bought with tier arithmetic among them.

**V12 and V15 are the two deliberate advisories, each for a stated reason rather than for
convenience.** `endpoint_kinds` is a consumer aid that exists to serve consumers rather than to add a
gate, and no acceptance criterion checks it — AC-2 is scoped to membership and inverse consistency.
That holds for **both** of V12's directions, and the re-key sharpens its precision without changing its
posture: a row outside the declared set and a declared token no row reached are both findings about how
this project's Knowledge Base and producers happen to populate a generic vocabulary, and gating either
would fail `/aid-graph` for a property of an artifact it is only permitted to observe — exactly the
incentive FR-25 and FR-28 exist to remove. The second direction carries one further reason of its own:
gating it would forbid the comprehensiveness FR-5 requires, since a core vocabulary is deliberately
larger than any one project's producers and a token unused here may be central on the next project
(feature-001 SPEC.md:447–451, :486–489). Concept ambiguity is a **glossary** defect surfaced by this
artifact, and gating on it would fail the run for a defect in the KB. Each keeps the signal without
inventing a gate the requirements do not have.

**What the unobserved-token advisory prints, since the widened token space makes the shape of the report
the whole of its value.** For each merged relation, the tokens it declares minus the kind pairs observed
for it — over **both readings** of every row (step 6), not over the orientation D7 stored the row in —
**partitioned by whether the relation appears in *either* relation column of
any row**: a relation *with* rows has its unobserved tokens listed individually, because that
is the actionable over-declaration signal; the relations with **no** rows are named together in a
**single** advisory line rather than one line per token. Nothing is lost by the second form — for a
relation no row used, *every* declared token is unobserved by construction, so the relation's name
carries the whole of that report — while listing them one by one would turn a report meant to surface
over-declaration into a recitation of the vocabulary's ordinary breadth, burying the actionable class in
the routine one. Both forms print in the same `[TAG] <doc>: <message>` shape as every other finding,
`<doc>` being the artifact under test, and neither adds a field to the fixed
`Checked: N rows | Findings: M` trailer. Whether an unexercised token is reachable **at all** is a
different question and not this validator's: it needs feature-005's producer map and is that feature's
report (feature-001 SPEC.md:453–458 layer W3, :475–489). The cost is one set insert per reading — two per
row — over a kind pair V13 has already computed, the pair-level correction to feature-001's per-row
estimate (SPEC.md:491–497) and the same order, which is why the second direction is worth having at all.

**Why the accumulation is over readings and not over stored cells — the one place normalisation could
have made this report lie.** D7 emits rows in normalised orientation, so on a row whose ids sorted the
other way the stored `S2T Relation` is the **inverse** of the relation the run discovered. An
accumulation reading the stored `S2T` alone would credit the inverse entry and leave the forward
entry's token looking unobserved on roughly half of every asymmetric pair — a false advisory,
systematically, and worst on the relations the report exists to inform. Taking both readings removes the
hazard by construction rather than by care at the call site: normalisation swaps the two
`(Id, Kind, Name)` triples **and** the two relation labels *together* (D7), so the (relation, token)
facts a row contributes are identical whichever orientation it was stored in. feature-005
meets the same hazard on its own W3 report and routes around it on the same ground — "the (relation,
token) pairing survives normalisation and the report can be computed from the map rather than from
emitted rows" (feature-005 SPEC.md:1176–1179); W4 must read emitted rows, so it takes the pairing and
not the map. **V12's per-row direction needs no such treatment**, and the reason is what confines this to
one place: pair coherence makes `endpoint_kinds(r')` the exact transpose of `endpoint_kinds(r)` (D4), so
a normalised row's kind pair is in the stored relation's declared set exactly when the row as discovered
was in the discovered relation's — the swap moves a row from one side of a coherent pair to the other and
cannot change the verdict.

**Three interpretation decisions, recorded so they are not re-litigated:**

1. **Multiple rows over the same endpoint pair are legal** when their relation pairs differ.
   AC-3's wording ("nor as a forward row plus a separate inverse row for the same endpoint
   pair") could be read as one-row-per-pair, but FR-4 admits a comprehensive vocabulary and
   §5.4 says nuance no *pair* captures goes to `Observation` — so two genuinely different
   typed relations between the same two nodes are distinct relationships. V5 keys on the
   relation pair as well as the endpoints, which catches every repeat and every mirror of the
   *same* relationship while permitting a second, different one.
2. **`Observation` is not part of the duplicate key.** Two rows identical but for their
   `Observation` text are the same relationship recorded twice and V5 flags them.
3. **`Kind` is not part of the duplicate key either, and that is safe rather than lax.** V8
   guarantees an id carries one kind throughout the file, so kind is functionally determined by the
   id and adding it to the key could only *mask* a duplicate.

### Layers & Components

New files only; no existing script is forked (C-4). Every row below is created by this feature
except `relation-vocabulary.yml`, which is feature-001's and is listed so the read dependency is
visible, and the project extension, which is authored by a target project and never by AID. Authored
in `canonical/`, then rendered by the FULL `run_generator.py` — never hand-edited under `profiles/`
or the dogfood `.claude/` (C-2). `canonical/aid/scripts/` and `canonical/aid/templates/` are both
recognised asset kinds in `canonical/EMISSION-MANIFEST.md`'s "Asset Kinds" table, so the `graph/`
subdirectory under either is rendered into **every** profile without a renderer change; the
per-profile `emission-manifest.jsonl` records are regenerated by the same run, and the render-drift
CI job gates the result (C-3). `canonical/aid/templates/graph/` already exists on disk, holding
`relation-vocabulary.yml`, so the path is proven rather than proposed.

| Layer | Path | Purpose |
|-------|------|---------|
| Template / contract | `canonical/aid/templates/graph/relationship-schema.yml` | D1 + D1a — the ten columns, required set, provenance enum, prefix set, **`Kind` enum with per-kind prefix sets**, and `image_extensions` |
| Template / contract *(feature-001's file — not created here)* | `canonical/aid/templates/graph/relation-vocabulary.yml` | D4 core — created and authored by feature-001, which owns its schema and content. Present on disk today; its **carrier** is reused here, while both its **contents** and the **field contract its header comment documents** are superseded — the contents by Q10's standards-first re-research, the field contract by the 2026-07-30 loader sync (D4: an eighth key, kind-keyed endpoints). Rewriting the file, header comment included, is feature-001's execution work |
| Project file *(never created by AID)* | `.aid/graph/relation-vocabulary.yml` | D4 extension — optional, project-authored, same format as the core; documented here, produced by no feature |
| Script library | `canonical/aid/scripts/graph/relationship-schema.sh` | D9 — sourceable loader/normaliser; no import-time side effects |
| Script | `canonical/aid/scripts/graph/validate-relationships.sh` | V1–V15; `0`/`1`/`2` exit scheme |
| Test | `tests/canonical/test-relationship-schema.sh` | the D9 library: the per-kind id grammars; `rel_slug_heading` and `rel_doc_slugs` (including the **duplicate-heading** case, the level-1 counter, the fenced-code exclusion, and — as regression cases pinned to the four verified on-disk instances — **one-for-one space→hyphen with no run collapsing** and **`_` retention**, i.e. `` D13 — Per-repo `format_version` stamp (git model) `` must yield `d13--per-repo-format_version-stamp-git-model` exactly); `rel_fact_tokens` (including a **wrapped** anchor string, an anchor-less marker that yields no fact, a >40-character slug cut at a hyphen, and a >40-character slug with **no** hyphen in range taking the D2a-2 **hard cut**, plus two such slugs colliding after the cut and being separated by the ordinal); `rel_block_bodies` (a body closed by a **deeper** heading, a body closed by a same-level heading, a body closed by end-of-file, a fenced heading-shaped line that must **not** close a body, and a fenced marker that must **not** qualify one); `rel_normalise_term` (compound splitting, `_`, and the **no-plural-folding** rule); `rel_concept_defs` exactly-one resolution and the `@<doc>` qualified form, plus the D2a-3a case where a marker nested under a deeper heading yields **one** concept and not one per ancestor; `rel_class0_block` (block ends at the first `inferred` row; block is every data row when none is `inferred`; header and delimiter included; frontmatter excluded); `rel_normalise_row` swapping **`Kind` with its id**; `rel_row_key`; `rel_sort_key`; and `rel_load_vocabulary` — a well-formed fixture carrying every declared key loads, one fixture per rejection class (missing key, unknown key, duplicate key, empty value, keys out of order, enum violation, undeclared `category`, a `relation` or `inverse` label breaking its `[a-z][a-z0-9-]*` charset, a restricted-subset violation, broken closure, broken involution, `symmetry`/`inverse` disagreement, absent core, empty `pairs:`), **plus the classes the 2026-07-30 loader sync adds**: an `endpoint_kinds` token naming an **id prefix** (the migration regression feature-001's AC-S4 forbids — a fixture that would have *passed* the superseded value rule); a token whose side is not a name in `kinds:`; `derived_from` absent; a `derived_from` token failing its **token grammar**, one with no colon at all and one whose key begins with a digit; `coined` in a **core** entry; `coined` alongside a standard token in one entry; an asymmetric pair whose `endpoint_kinds` are **not transposes**; a **symmetric** entry whose set is not closed under transposition (feature-001 AC-S9 names these last two, and the second is the only thing that exercises a clause the delivered core satisfies vacuously); and an asymmetric pair disagreeing on `category`, one disagreeing on `derived_from`, and one disagreeing on `passes` — one fixture per agreement clause, because a loader that checked only the transpose clause would pass all three — **plus one positive fixture for the set reading of that equality**: a pair whose `derived_from` and `passes` carry the same tokens in a **different order**, which must **load**, since an implementation comparing sequences passes every negative fixture above and rejects a legal pair (the `image` + `ext:` argument, applied to the vocabulary); **plus the merge cases**: extension adds cleanly; extension collides on `relation` → exit 2; extension collides on a category name → exit 2; extension `inverse` pointing at a core relation → exit 2 via involution; extension **absent** → core-only, exit 0. Every one of these fixtures is authored with placeholder relation labels and placeholder `derived_from` tokens, so none of them puts a shipped label, category or standard key in this tree (feature-001 AC-S11) |
| Test | `tests/canonical/test-validate-relationships.sh` | one negative fixture per validator, proving each check fires, plus a clean-pass fixture. **Three fixtures exist specifically to catch a plausible wrong implementation:** `image` + `ext:` **must pass** (the naive one-to-one kind/prefix check §5.2 warns about would reject it); `image` + `kb:` **must fail**; and a healthy project with every convention present **must still carry full coverage notes** (AC-20 — an implementation writing notes only on absence passes every other test). **V14's extra-row clauses (D7a-1, AC-S3) get one negative fixture each**: an extra row above a fixed row (contiguity); a key with an uppercase letter or a space (charset); an extra key equal to an enum kind (fixed-key collision); the same extra key twice in one table (uniqueness); two extra rows in descending key order (sort); an extra row with the wrong cell count. Plus a **positive** fixture carrying the six verified keys from both producer files, emitted in the D7a-1 order, which must pass — and the same six shuffled, which must fail, since a shuffle is exactly what an unsorted assembly produces. **V12's re-key gets two fixtures of its own**, because an advisory that fires on nothing is indistinguishable from one that was never implemented: a row whose `(Source Kind, Target Kind)` pair the chosen relation does not declare — built as a `document`→`concept` row typed with a fixture relation declaring only `"section->concept"`, which the superseded prefix-keyed check **could not see at all**, both ids being `kb:` — and a fixture vocabulary declaring a token no row exercises, which must produce the `[REL-ENDPOINT-UNUSED]` advisory while leaving every gating check's verdict untouched. **The unobserved direction gets one further fixture, because normalisation is the one thing that could make it lie**: a row whose ids sort so that D7 stores it **flipped**, typed with an asymmetric pair both of whose tokens are declared, which must produce **no** `[REL-ENDPOINT-UNUSED]` line for either half of the pair — an implementation accumulating the stored `S2T` reading alone reports the forward token as unobserved and fails here while passing the fixture above |
| Fixtures | `tests/canonical/fixtures/graph/` | hand-built ten-column tables (well-formed and one per defect class); a fixture KB carrying a duplicate heading, a heading with `_`, a heading with a deleted character between spaces, a wrapped anchor, an anchor-less `CONFIRMED` marker, a >40-character hyphen-free anchor, a **level-4 heading nested under a level-3 one with the marker in the child** (the D2a-3a discriminating case this repository's KB cannot supply, since it has no level-4+ heading), a fenced heading-shaped line inside a definition body, a term defined twice, and a near-plural pair; the Q4 synthetic `external-sources.md` with both resolvable and unresolvable keys; core and extension vocabulary fixtures for the merge cases, for the `derived_from` clauses, for both pair-coherence clauses and for the prefix-keyed `endpoint_kinds` regression; and an all-conventions-absent KB for AC-19 |

Conventions honoured (all from `coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; a header block stating Purpose / Usage / Exit codes; `-h|--help`
  re-printing a slice of that header.
- `set -uo pipefail` (not `-euo`) for `validate-relationships.sh`, following the read-only
  linter precedent (`kb-citation-lint.sh`) which intentionally tolerates non-zero from
  `grep`/`awk`; the library uses `set -eu` like `build-kb-index.sh`.
- kebab-case file names, `snake_case` bash functions with a `rel_` prefix, `UPPER_SNAKE`
  globals.
- Every sort **this feature writes** is `LC_ALL=C`, following `build-project-index.sh` line 185 and
  `kb-freshness-check.sh` line 460. The repo is not uniform on this (D2a), so the convention is
  stated as this feature's own rule rather than as an inherited one, and D7 explains why it is
  load-bearing here.
- File errors print the resolved absolute path. This matters more now that two vocabulary files share
  a basename: every collision and load message names both resolved paths, so core and extension can
  never be confused in a diagnostic.
- No new exit code is invented; `0`/`1`/`2` reuse the documented linter semantics.
- `tests/run-all.sh` discovers `tests/canonical/test-*.sh` by glob, so no runner edit is needed.
  Fixtures are self-built and reference nothing under `.aid/works/` (A-6, and the project's
  transient-work-folder rule).
- `relationships.md` is **not** added to `canonical/aid/templates/generated-files.txt`. That
  registry's declared consumers are `/aid-discover`'s FIX state and its `state-fix.md` Step 4
  `test -f` loop, which run *before* KB approval — whereas `/aid-graph` is gated on an approved KB
  (FR-8). Registering it would make discovery attempt to build the graph mid-cycle. The
  `AUTO-GENERATED` marker and the `source: generated` + `generator:` frontmatter that
  `authoring-conventions.md` requires of generated content are still emitted (D8). See Open Items.

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the
methodology, that owner is named and the item is **not** absorbed here. None blocks this feature's
own implementation. A **closed** item stays in place with its number and is marked closed rather than
deleted, so that inbound references from sibling SPECs keep resolving and the round trip stays
readable — item 12 is the first of those.

1. **`external-sources.md` entry format is an upstream change — and now blocks more than one
   criterion.** D2c defines the table form the resolver reads, but `/aid-graph` cannot author it
   (FR-10) and the file's writer is `/aid-discover`'s ELICIT state. Two things follow. (a) Until
   ELICIT emits it, `ext:` resolution registers zero keys on this project and AC-1's `ext:` branch
   lives entirely on the Q4 fixture, which is what Q4 decided. (b) Per D-5 the format must now also
   carry `web-page` and external `image` **nodes**, and to close D1a's one unchecked arm it must
   record a **media type** so `image` and `web-page` can be distinguished from an `ext:` key.
   **Owner: `/aid-discover` ELICIT (upstream), with the media-type requirement raised by this SPEC.**
2. **`generator:` value — reconciliation with feature-010.** This SPEC emits
   `build-relationships.sh` (the script, per `frontmatter-schema.md`); feature-010's SPEC emitted
   `aid-graph` (the skill). One value must win before V9 is implemented, since V9 checks the field's
   presence and the two specs would otherwise disagree about its content. The schema text favours the
   script name. **Owner: feature-010**, whose re-specification is the natural place to settle it.
3. **Frontmatter scalars owned elsewhere.** `graph_inputs_digest` and `graph_generated_at` are
   feature-010's; `kb_gaps` is feature-006's. If feature-010 moves the staleness record outside the
   artifact, D8 loses two lines and nothing else here moves. **Owners: feature-010, feature-006.**
4. **The vocabulary staleness input needs a digest, not just a loader flag.** D4 supplies
   `--vocabulary` / `--vocabulary-extension` so a test can exercise a vocabulary change (Q15's owed
   item). Composing both files into FR-11's staleness digest is the staleness record's business.
   **Owner: feature-010.**

   **The same owner also holds what operationalises D7a-1's open-set argument: FR-11 input 6,
   tool-upgrade detection.** D7a-1 answers "how does a wave-3 coverage row join without invalidating an
   existing artifact" by pointing at input 6 — a new row ships in an upgraded tool, so the boundary is
   one across which byte-identity asserts nothing. That answer is only as good as the detection: FR-11
   specifies input 6 as the installed version by version string **where one is exposed** and otherwise a
   **digest over the installed scripts and templates that affect output**, and someone must decide which
   of those two applies here and, for the digest form, which files are in scope — the graph scripts and
   `canonical/aid/templates/graph/` at minimum, since those are what decide what is emitted. Until that
   is settled, a tool upgrade that adds a coverage row would still re-baseline silently rather than
   through a fired staleness check, which is the precise failure input 6 was added to close. Nothing in
   *this* feature blocks on it — V14 and AC-5 behave correctly either way, and D7a-1's ordering holds
   regardless. **Owner: feature-010**, at its re-specification.
5. **Coverage-notes content, as distinct from its shape.** This feature fixes the section's shape,
   row set, order and validation (D7a, V14). Determining each convention's present/absent status, the
   per-kind node counts, and the FR-22 exclusion statuses is production work. **Owners: feature-004**
   (enumeration and exclusions), **feature-005** (extraction counts), **feature-010** (run
   orchestration and the ignore-list availability check).
6. **`Kind` assignment for `ext:` nodes cannot be validated here.** D1a records that `image` versus
   `web-page` is unrecoverable from an opaque key, so that one arm is trusted from the node record.
   Assigning it correctly, and supplying whatever evidence makes it checkable once item 1 lands, is
   **feature-004's**.
7. **FR-22's ignore list depends on a settings section that does not exist.** `.aid/settings.yml` is
   at `format_version: 3` (verified) with no ignore list; adding one may need a version bump and a
   reconcile rule (D-4, STATE.md Q6). This SPEC only requires the *status* to be reportable in the
   coverage notes, which is satisfiable today by reporting it absent. **Owners: feature-004 /
   feature-010, plus the settings-schema change itself.**
8. **Rename-stable heading identity would need a new KB authoring convention.** D2d makes a rename
   detectable but not tracked. Durable, author-assigned heading ids would fix that, and no
   requirement asks for them. **Owner: the KB authoring conventions (methodology), outside this
   work.**
9. **Render-time label shortening.** D5 stores full names deliberately. Abbreviating a long `fact`
   name or a long `int:` path for legibility is a view concern. **Owners: feature-007** (canvas
   labels), **feature-009** (table view).
10. **Generated-file registry placement.** The decision not to register `relationships.md` in
    `generated-files.txt` is argued above. If the owner prefers registration for symmetry with
    `INDEX.md`, the registry line must be conditioned on KB approval, which the registry's flat
    `<output-path>|<build-command>` format cannot currently express. **Owner: feature-012**
    (canonical registration).
11. **`build-kb-index.sh`'s KB scan is locale-dependent** (bare `| sort`, line 471; the same is true
    of `kb-citation-lint.sh` line 37). Nothing here depends on it — D2a consumes the scan set as a
    set, and D7 supplies its own `LC_ALL=C` order — but `INDEX.md`'s own row order can differ between
    machines, which is a pre-existing reproducibility wrinkle in a *generated* KB artifact. Out of
    scope here (C-4 forbids forking it). **Owner: a separate methodology fix.**
12. **`endpoint_kinds` is prefix-keyed and the widened node model outgrew it — CLOSED 2026-07-30 by
    feature-001, and absorbed here.** *(Kept in place, with its number, rather than deleted or
    renumbered: feature-001 cites "feature-003's Open Item 12" by number in four places — its Change
    Log, its § Source at :53, its D3 at :380 and its own Open Item 2 at :1535 — and D4 and this SPEC's
    Change Log cite it too, so renumbering the items below it would break live references for no gain.
    The round trip is also the point.)* The finding
    was that with §5.2's `Kind` enum, `"kb:->kb:"` cannot distinguish a document *defining* a concept
    from a section *mentioning* one, so a standards-first vocabulary would carry relations whose legal
    endpoints the token form could not state; the fix named was re-keying on the `Kind` enum, and the
    owner named was feature-001. feature-001 has re-keyed the field (its D3, SPEC.md:378–397) and
    routed the loader half back here as its own Open Item 2 (:1534–1538). **Absorbed:** D4's entry
    table now validates each token as `<kind>-><kind>` against the `kinds:` list `rel_load_schema`
    already loads, and V12 is re-keyed to the row's `(Source Kind, Target Kind)` pair. **Nothing
    remains open.** The one process lesson worth keeping: this item was routed out, answered, and
    routed back as **three further loader changes** — the eighth key, pair coherence, and V12's second
    direction — none of which any gate on this SPEC could have found, which is why an Open Item routed
    *into* a gated SPEC is a pending reopen rather than a note (STATE.md Q20).
13. **Ledger retention.** Per Q8/D-6 the shared reviewer-ledger lifecycle deletes ledgers at skill
    DONE. This feature writes no ledger — it prints findings and the skill's REVIEW state transcribes
    them — so it is unaffected, but the validator's findings share that lifecycle. **Owner: the
    separate methodology work item Q8 raised.**
14. **Coverage-note assembly must apply D7a-1's sort — feature-010's obligation, stated here because it
    is not yet re-specified.** D7a-1 fixes the order; *applying* it at emission is assembly work. The
    obligation is deliberately weak by design: feature-010 may read the producer files
    (`kb-coverage.tsv`, `coverage.tsv`, and whatever wave 3 adds) in any order and concatenate them
    however it likes, provided it sorts the extra rows by key under `LC_ALL=C` within each table before
    writing. V14 fails the artifact if it does not, so the obligation is enforced rather than trusted —
    but it should be written into feature-010's own SPEC rather than discovered from a validator
    failure. **Owner: feature-010**, at its re-specification. *(Raised by feature-005's Open Item 16,
    which correctly declined to choose the order from outside this contract.)*
15. **The duplicate-heading `-<N-1>` suffix has no on-disk verification.** D2a-1's four other slug rules
    are each verified against a KB `## Contents` link, but the suffix is not: the KB's only
    duplicate-slug group is linked only at its first occurrence
    (`domain-glossary.md` line 53), so nothing on disk exercises `concept-spine-1`. The rule is fixed
    here on its own merits — total, order-deterministic, sort-stable — and the appeal to an external
    renderer that the previous revision made is withdrawn. Confirming that the emitted suffix is the
    anchor a reader's renderer actually resolves belongs to the feature that depends on it: FR-14a's
    "open the underlying artifact" gesture. Nothing in this feature blocks on it — a `section` id is
    well-formed and resolvable by V2 either way. **Owner: feature-007.**
16. **A mistyped standard key in a project *extension* is caught by nothing.** D4 states the residual: this
    loader checks `derived_from`'s token *grammar* and not its `<key>`'s membership of feature-001 D1's
    standard-key set, because the set has no data carrier this loader reads and hardcoding it would breach
    feature-001's **AC-S11**; and feature-001's **AC-S2** audit, which catches the core case, is scoped to
    the delivered **core** vocabulary. The judgment not to gate membership stands — gating it is what would
    breach AC-S11 and re-create the second copy of a closed set the `endpoint_kinds` re-key removed — so
    what is owed is a decision, not a fix here: whether the standard-key set gains a data carrier a loader
    could read (feature-001 D3 rejected a third top-level key in the vocabulary file for a different
    purpose, SPEC.md:423–425, so the trade is already on the record there), or whether the residual is
    accepted and AC-S2's audit stays core-only. What bounds it meanwhile: no runtime consumer reads the
    field, and a typo on **one** half of a pair still exits 2 via pair coherence's `derived_from` clause —
    so an undetected typo must be made identically in both halves. **Owner: feature-001**, which owns the
    standard-key set and its audit.
