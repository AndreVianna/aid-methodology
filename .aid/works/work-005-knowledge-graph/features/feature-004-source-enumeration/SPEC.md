# Source, Media And External Node Enumeration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.7 (FR-19–FR-24), §2 item 1, §9 (AC-16) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Gate finding 3 [HIGH] fixed — the `never inferred` rule promoted to a named, citable invariant (`no-inferred-node`, D3) with its enforcement and its consequences for feature-006 and feature-007 stated explicitly | /aid-specify |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles; STATE.md Q9–Q15) and against feature-003's fixed contracts (A+, 2026-07-29).** The node model widened under this feature on three axes and the old SPEC enumerated only whole-artifact source files. (1) **FR-23 is rewritten and granularity is asymmetric**: source code stays whole-artifact — §5.3's `int:` "narrowed to a symbol" clause is struck, so the granularity cut is now total rather than a tension — while the KB side is deep, and those KB-side nodes are **feature-005's Pass 1 output, not this feature's**; the boundary is stated as its own section because the old Description's "Everything is enumerated at the level of a whole artifact" now reads as a claim over the whole node model. (2) **Two node kinds are added here** — `image` (in-repo `int:` or external `ext:`) and `web-page` (`ext:`) — which per **FR-21a** qualify **by kind, not by significance**, so FR-21's three criteria are re-scoped to `source-artifact` only and the two classes are emitted through **separate writers with no `qualifier` field**, making the exemption unrepresentable rather than merely instructed (new **D1a**, **D2a**, `media-nodes.tsv`). (3) **FR-22's ignore-list arm is rewritten**: the old D4 Class 3 read `graph.ignore` with `--default ''` and could not tell an *absent* section from a *declared-empty* one, which is exactly the silent behaviour FR-22 now forbids — replaced by a three-state availability probe (**D4a**) and reported through FR-9a's coverage notes. Also new: **D7**, the coverage-note content this feature owes (FR-9a part 2, AC-20), routed here by feature-003's Open Item 5; `image_extensions` and the `ext:` registry predicate are **consumed from feature-003** rather than restated; `node_kind` is carried in both node records because feature-003 D1a trusts it from this record for `ext:` ids and cannot check it. **Deleted: the "Sanity check against A-5" block and every node-count claim** — A-5 is void, the inherited "583 source artifacts" figure is unreproducible, and NFR-7's bench is a research finding, so no count is asserted anywhere below. **Retitled** from "Source Enumeration By Structural Significance", which was false for two of the three kinds this feature now owns; the feature id and folder are unchanged. **Seven new cross-feature findings raised rather than absorbed** (Open Items 1, 2, 4, 5, 6, 7, 11), the sharpest being that AC-15's lens/ledger equality and feature-006's candidate set are keyed on the **`int:` prefix**, which in-repo images now share — both must re-key on `Kind`, and this SPEC supplies the discriminator rather than leaving it to be derived (Open Item 1) | /aid-specify |
| 2026-07-29 | **Gate round 2 — six findings fixed (2 MEDIUM, 3 LOW, 1 MINOR); zero CRITICAL/HIGH to fix.** (1) [MEDIUM] **D2a's ordering argument had no working example.** Its cited instance, `site/public/favicon.svg` via `site/astro.config.mjs`, is ruled an `unresolved-reference` by this SPEC's own D5 — a site-absolute URL is not a repository path — so it could not demonstrate the defect it was cited for. Replaced with a **two-link chain that resolves**, each link verified and each with its D5 resolution stated in the table so the example cannot rot the same way: `site/astro.config.mjs:147` → `Header.astro` (making the override an enumerated `source-artifact`), then `Header.astro:14`'s `import … '../../assets/casulo-ai-labs.png'` → `site/src/assets/casulo-ai-labs.png` (git-tracked, surviving every D4 class). The favicon is **kept as the contrasting case** — genuinely referenced, still not `depended-upon`, and a node by kind alone — because the pair shows classification and ordering doing different jobs, and shows that "is referenced" and "resolves" are different tests. The ordering rule itself is untouched. (2) [MEDIUM] **D7's `image` note would have generated a false statement.** It reproduced feature-003 D7a's `image files in-repo; external image keys` verbatim, but under tier B no `ext:` key is ever an `image`, so on any project with external-sources entries the notes asserted a carrier that cannot contribute a node — an AC-20 accuracy failure. Corrected to `image files in-repo; no external key is an image (D-5)`, with the string **selected by the same tier constant that selects the classification** (tier-A wording given) so the two cannot drift, and a test asserting the pair. The divergence from D7a's example is safe and shown to be: V14 validates kind, order, status and count, **not** the carrier text. (3) [LOW] **Open Item 2's "prose only" verdict is now verified rather than assumed** — read against both consumers' SPECs: feature-006 reads field 2 positionally and `qualifier`/`evidence` by name, feature-007 reads ids only, and feature-007's `Node.kind` is the **id prefix** ("never inferred from anything else"), a different concept sharing the word. Neither reads field 3; no mechanism change in either. (4) [LOW] **D7 now states a fallback** if feature-003 declines the V14 extra-row tolerance: both facts move into fixed-row `note` cells, so the reliance costs presentation rather than content. (5) [LOW] **D2a point 5's case-folding rule gains a fixture** — an upper-case `LOGO.PNG` in the fixture tree and an assertion in `test-graph-media-nodes.sh`, since no repository path exercises the rule. (6) [MINOR] **Open Item 11 corrected — its own claim was false.** PLAN.md and delivery-002's BLUEPRINT do **not** carry the old title string; they cite the feature by folder id, which the retitle did not change. The real stale cross-references are three citations of **renumbered Open Items** (`PLAN.md:86` and `BLUEPRINT.md:130` → now item 8; `task-017/DETAIL.md:103` → now item 9), one of which is a delivery gate criterion. **Requirements correction absorbed:** AC-15 and FR-20 are re-keyed to `Kind = source-artifact`; Open Item 1's requirements half is closed and only the consumer half remains — where the verified finding is that both consumers' *mechanisms* are already correct, because `nodes.tsv` holds `source-artifact` rows exclusively after D1a's split, and only their prose still says `int:`. **Also found in self-review, same defect class as row 2 — generated text that must match feature-003's D7a skeleton:** the three `exclusion` rows' `key`s are TSV keys and D7a renders them as different labels, which V14 checks, so the key → label translation is named as feature-010's and routed as a third arm of Open Item 7; the `kind` keys render as themselves, which is exactly what would make a reader assume the exclusion keys do too. Two smaller self-review fixes: D2a's list intro said "Four things" over five items, and D5's relative-reference bullet now states that it keys on the reference's **form** rather than the citing file's language — the reading the new ordering example depends on. No node count reintroduced | /aid-specify |
| 2026-07-29 | **Gate round 3 — five findings fixed (1 MEDIUM, 3 LOW, 1 MINOR).** (1) [MEDIUM] **`--probe` ownership decided: this feature owns and implements it.** The Layers table committed to the change while Open Item 5 called the landing undecided, which an implementer cannot act on. D4a now carries an ownership table separating the three shared-settings surfaces — the flag (here, because this is its only caller, AC-S7/AC-20 depend on it, and it is additive with no existing-mode change), the **commented-out** template seed (here, because a comment declares nothing and so raises neither the reconcile nor the `format_version` question), and the **live** `graph:` declaration with those two questions (feature-010/012, Open Item 8). **There is no interim behaviour to specify**: the flag lands with this feature's first task, so the ignore-list-absent behaviour specified against its output is available from that point. Open Item 5 rewritten to carry coordination only. (2) [LOW] **`artifact_class` gains an assignment algorithm and a catch-all.** D2's "representative real path" column becomes a **first-match ordered list of 16 rules** — 15 globs plus a catch-all — over the node id alone, evaluated at Feature Flow step 12, independent of `qualifier`, with every ordering constraint stated (located rules above generic ones — `dashboard/*` and `tests/*` must precede the extension-based `script` rule, `.md` sits last) and one overlap resolved by fiat and flagged as such. The FR-8a tension is resolved by **one shipped catch-all, `source`** — the honest generic class for a project AID did not author — which makes the enum **total** while keeping it closed and byte-stable. feature-001's `coined` precedent was considered and **not adopted**: it works there because that vocabulary has an extension file, loader, precedence rules and validator, where `artifact_class` has **no consumer in any sibling SPEC and no validator** (verified), so an authoring surface would be scope with nothing reading it — recorded as Open Item 12 instead. D2's over-claim that feature-006/007 read the field is corrected to "intended, not yet consumed", and `agent`-as-`artifact_class` is distinguished from the owner's no-`agent`-**node-kind** decision. (3) [LOW] **Feature Flow step 9 no longer says "both node streams".** It now names the two arms separately — in-repo targets against `nodes.tsv` plus `media-nodes.tsv`'s `int:` rows (written at step 7), `ext:` citations against the **key set loaded at step 3** — and D5's matching sentence is tightened the same way, since it carried the same loose phrase. (4) [LOW] **The `present` predicate is rebuilt on the carrier, not the node count.** FR-9a asks whether the **convention** was present in this project, and every carrier it names is project-side; FR-21's ruleset ships with the tool and is never absent, so `present` iff ≥ 1 node reported `absent` for a project whose source was wholly excluded — or wholly cut by the rule — asserting a missing convention that in fact applied. Now: **`present` iff this project supplied ≥ 1 instance of the kind's carrier**, with the count still the node count, so **`present` with `0` is legal** and pairs with the `source-artifact-dropped` row. Per-kind carrier instances are named for the three kinds owned here, each a number the run already holds before it emits. **Uniformity across all seven kinds is preserved, and what it delegates is only the per-kind *carrier definition*** — which is where the old predicate went wrong, by hard-coding the carrier as "a node". Unchanged in effect for `document`/`section`/`concept`; for `fact` it surfaces a genuine choice, since feature-003's own "CONFIRMED markers skipped for want of an anchor" example is a present convention yielding no node — both readings are stated and **neither is picked here**, because that call is feature-005's (Open Item 4). (5) [MINOR] **The comma limitation gets a diagnostic, in the only place it is decidable.** The comma-joined string destroys the distinction before the scanner sees it, and re-reading settings in the scanner is forbidden, so the check rides on `--probe` where the raw items are still separate: a stderr warning naming the offending item, stdout and exit code unchanged, plus a deterministic suffix on the `declared, <n> patterns` coverage note so the durable record carries it too. **Also updated:** Open Item 4's first half is **closed** — feature-001's D6c discharged the `image-reference` mapping to `illustrated-by`/`illustrates` — leaving only feature-005's coverage rows. Fixtures and three test rows extended for the catch-all, the ordering pairs, the `present`/`0` case and the comma warning. No node count reintroduced; rule ordering, the feature-005 producer boundary and the tier A/B split untouched | /aid-specify |
| 2026-07-29 | **A+ REOPENED and fixed — the `qualifier` field declared four values and assigned two. Found by cross-feature reading during feature-006's re-specification, not by any review of this SPEC** (Q18 ruling 3, "if there is a defect, the A+ is false"; this instance recorded at **STATE.md Q22**). **The defect.** D1 field 4 declared `entry-point` \| `public-surface` \| `depended-upon` \| `named-unit` and described itself as "which FR-21 clause qualified it", but across this SPEC `public-surface` and `named-unit` each occurred **exactly once** — in that value-space cell — with **no assigning rule anywhere**. D3 specified *which mechanisms qualify a node* and D1 specified *which values the field may hold*; **nothing stated which mechanism writes which value**. Because feature-006's severity function is a total function of this field, half its severity domain was unreachable: both specs were individually coherent and jointly wrong, the same shape as the disposition-versus-byte-identity collision and the coverage-row accumulation. **Resolution: all four values are assigned (new D3a), and the two routed sub-items are the same defect one level down and are closed with it.** (1) **A total carrier → qualifier map.** Every one of D3's declared carriers and derived mechanisms now maps to **exactly one** value, and the map is what surfaced two arms that can qualify nothing here: `knowledge.doc_set`'s KB-doc arm (its target is cut by D4 Class 4; it survives as D5's one cross-side `dependency` observation) and — after correction — nothing else. **No mechanism is added**: the map re-uses D3's carriers verbatim, and the only new statement is the value each writes. (2) **The four-values-over-three-clauses mismatch is resolved rather than papered over.** The field is a **refinement**, not a bijection: FR-21's clause 1 is itself disjunctive and its own examples mix things this project *executes* with things it *exposes*, so `entry-point`/`public-surface` split clause 1 on that line and the field's description now says so. The split is **severity-neutral** in every consumer, which bounds the one fiat in it. Collapsing the value space (the alternative) was **rejected**: the rules do produce clause-1 and clause-3 candidates — the gap was the mapping, not the mechanisms — and collapsing would have destroyed feature-006's `[HIGH]` and `[LOW]` sources and reopened it for a defect this SPEC created. (3) **`qualifier` is now the strongest applicable clause under a stated precedence (P1 clause 1 > P2 `depended-upon` > P3 `named-unit`), not the first match in flow order** — so **severity-monotonicity holds by construction** for any severity function monotone in that precedence, feature-006's included. The superseded first-match order was **not** monotone and a live instance exists: `packages/npm/package.json` is named by `.aid/knowledge/integration-map.md`'s `sources:` list (⇒ `named-unit`, `[LOW]`) and its path literal appears in `canonical/aid/scripts/release/check-version-sync.sh:151` (⇒ `depended-upon`, `[MEDIUM]`) — both verified 2026-07-29 — so the old rule under-reported a severity, the direction FR-25's rationale warns about. Realised by one **promotion** at the settling pass; the citing set, `observations.tsv`, the fixed point and the stage ordering are all untouched. **Also fixed, found in self-review while writing the map — a second defect of the same class in previously-upheld text:** the enumeration boundary claimed "the single KB file this feature reads is `external-sources.md`", which D3's own `sources:`-frontmatter carrier contradicts. Corrected to state **both** narrow KB reads, with the load-bearing claim (no KB document becomes a node here, and no KB-side node is discovered here) preserved and FR-19 independence re-argued: the read can only **add** a source node, never withhold one, and omission is the failure mode FR-19 exists to prevent. **Routed, not absorbed:** the zero-row media-node carrier (new Open Item 13 — needs a `relationships.md` frontmatter key that must **not** be `kb_gaps`, and the reason is now mechanical as well as semantic: feature-007's loader materialises zero-row nodes *from* `kb_gaps` and its GV07 fixes such a record's `kind` to `source-artifact`, so that key would relabel a media node as the class FR-20 says it is not. Verified to be the same finding as **feature-007's Open Item 3** and **feature-006's Open Item 7**, both of which reach the same conclusion — feature-006's stated shape for it is "a separate key, with its own shape and no severity"; owners split as the work owner (whether they are carried), feature-003 (the schema key), feature-006 (the writer), feature-007 (consumer), feature-010 (assembly) — this feature supplies content it already produces and changes nothing) and feature-006's coordination (new Open Item 14). **This revision discharges feature-006's own Open Item 2**, which asked for exactly these two things — the total carrier → `qualifier` mapping and an explicit monotonicity answer — and named this feature as owner with the reopen consequence stated; **it does not reopen feature-006**, which pre-declared that "nothing changes here when the mapping lands", keeps all four severity keys with each now reachable, and whose withdrawal of the "highest applicable severity" tie-break becomes *more* correct since the maximum is now computed at the producer. feature-006 also independently reached the same reading of FR-21's clause 1 ("criterion 1 splits into `entry-point` and `public-surface`"; "a clause↔value translation that no document defines" — D3a is that translation), which is the strongest available evidence that the refinement is the requirement's distinction and not this SPEC's invention. Its two owed edits are stale-quotation class, not defects: it quotes the superseded "first-matching clause wins" sentence, and its Open Item 2 can be closed. No node count reintroduced; rule ordering, the feature-005 producer boundary, the tier A/B split, the 16-rule `artifact_class` list, `--probe` ownership and the carrier-convention `present` predicate all untouched | /aid-specify |
| 2026-07-29 | **Re-gate of the D3a revision — four findings fixed (1 MEDIUM, 2 LOW, 1 MINOR); the reopen stays closed and nothing upheld is disturbed.** (1) [MEDIUM] **`qualifier` was undetermined for one real input shape, and is now a single stated rule.** Step 8 said `declared` is tried before `derived` "within a precedence level" while D3a said that ordering runs "within a precedence level and never across one" — but **P1 spans Q1 and Q2**, Q1 holding a *derived* mechanism and Q2 five *declared* carriers, so a path whose only Q1 carrier is the executable header and which also carries a declared Q2 carrier emitted `public-surface` under one text and `entry-point` under the other. A field specified as a pure function of disk state cannot have two rules. **The rule, now stated in the same words in D3a §Precedence, in the promotion section's evidence bullet and in Feature Flow step 8: the clause order Q1 → Q2 → Q3 decides the `qualifier`; `declared`-before-`derived` runs inside the matched clause only, over that clause's own carrier disjunction, and decides the `evidence`/`evidence_provenance` pair — never the clause, and never across two clauses.** The `declared`-across-clauses reading is **rejected** with its three grounds recorded: it replaces the maximum-over-clauses rule with a maximum over provenance; it makes field 4 record how the scanner learned of a path rather than what role the path plays, so the same shebang script would change value when an unrelated catalog row names it; and nothing in this SPEC prefers `declared` for its own sake (AC-S4 accepts either, and the P3 → P2 promotion already lets `derived` evidence carry the stronger clause). Severity-neutral for feature-006 either way, so this is a determinacy fix — which is why it was fixed rather than tolerated: severity neutrality is a property of today's consumer set, not of the rule. The Layers test row and the fixture entry now **assert the evidence pair as well as the value** on that exact shape, so the row fails under the rejected reading instead of passing under either; this repository supplies no surviving instance (`generated-files.txt`'s three output paths are all cut by D4 Class 1/4), so the fixture is where the case lives — the D2a point 5 posture. (2) [LOW] **The monotonicity guarantee over-quantified and is narrowed.** It claimed to hold for "any severity function monotone in P1 > P2 > P3", but that ordering does not order `entry-point` against `public-surface` — both sit at P1 — so the Q1-before-Q2 tie-break needs a second hypothesis. Restated as **monotone in P1 > P2 > P3 *and* constant on P1** (or, weaker and sufficient, ranking `entry-point` ≥ `public-surface`), with the reason (b) is not a consequence of (a) written out, the consumer obligation at the same strength, and Open Item 14(i) updated to match. feature-006 satisfies both — `[HIGH]` for both P1 values *is* constancy on P1 — so no live consumer is affected; the point of writing the hypothesis down is that a future function which splits P1 now fails the check loudly rather than being silently mis-ordered. (3) [LOW] **A latent contradiction over `.aid/settings.yml`, masked by this repository, is resolved.** D4 Class 4 called it "a `settings-schema` node" unconditionally, yet no non-contingent D3a clause reaches it: it qualifies only through Q4, whose inbound reference here is `canonical/aid/scripts/config/read-setting.sh:46` `SETTINGS_FILE=".aid/settings.yml"` from a file enumerated by Q1 (shebang, line 1) — all four links verified 2026-07-29. On a project where nothing names the settings file, the old sentence asserted a node this SPEC's rules cannot produce. **Resolved by stating the general rule rather than patching the instance: an allowlist entry is an exemption from an exclusion and never a grant of nodehood** — an allow-listed path re-enters the candidate set at step 5 and is a node iff a D3a clause qualifies it; **a declared allowlist entry may legitimately fail to qualify**, and then becomes a `candidates.tsv` row with `no-rule-match` at step 11 and is counted in D7's dropped contribution. Stated for **both** allowlists (Class 4 and Class 5), which makes it the general form of D2's already-upheld "a declared allowlist entry in D4, not an exception in the significance rule", and it is the same rule step 11 already enforces ("file existence alone never qualifies"). The alternative — inventing a non-contingent Q2 carrier for the settings surface — is **rejected**: it would add a mechanism D3a is built not to add, with no project-side convention behind it (FR-24), and it would move the path from `depended-upon`/`[MEDIUM]` to `public-surface`/`[HIGH]` on this repository, a live severity change bought for a wording fix. **The resolution changes no node on any project.** The same gap is stated for FR-21 clause 3's other two named examples: "a manifest, a settings schema" name *kinds of unit*, not conventions, so they qualify only through a carrier a project actually supplies — this repository supplies one for both manifests via `integration-map.md`'s `sources:` list — and the clause-3 row's "one value" claim is clarified as a statement about the value space, not about carrier coverage. (4) [MINOR] **The monotonicity counter-example mis-labelled its own citing node.** `check-version-sync.sh` opens with `#!/usr/bin/env bash`, so Q1 qualifies it `entry-point` and the `canonical/aid/scripts/<area>/*` convention never writes a value; it was labelled "an enumerated node under Q3's script convention". Corrected, with the note that the label is inert to the example — the promotion turns on the *cited* node's clauses and the citing node's only role is being enumerated — but is not left standing inside the worked example that justifies the precedence rule. **Nothing else moved:** the rule ordering, the feature-005 producer boundary, the tier A/B split, the 16-rule `artifact_class` list with its `source` catch-all, `--probe` ownership, the carrier-convention `present` predicate, the citing set, `observations.tsv`, the fixed point and the stage ordering are all untouched, and **feature-006 is not reopened** — its two owed edits remain the same two stale-quotation prose changes | /aid-specify |
| 2026-07-29 | **Re-gate round 2 — three findings fixed (1 MEDIUM, 1 LOW, 1 MINOR); the reopen stays closed and nothing upheld moves.** (1) [MEDIUM] **`evidence` and `evidence_provenance` were undetermined one level below the `qualifier` fix, and now have a total rule.** Fixing the clause order settled *which clause* is credited but not *which string*: step 8's `declared`-before-`derived` order cannot choose among two `declared` carriers inside one clause, and step 9 named no rule for choosing among multiple citers — so two conforming implementations emitted different bytes for the same input, on a **required** field D1 specifies as a pure function of disk state, and FR-32's byte-identity rested on iteration order rather than on a rule. Both cases occur here: `.aid/settings.yml` matches Q3's `sources:` carrier in three depth-1 KB documents and is cited by many enumerated artifacts under `canonical/`, and `canonical/EMISSION-MANIFEST.md` matches the same carrier in a different and disjoint set of KB documents (corrected in the following revision, which found "strictly larger" false under set inclusion). **New D3a §The evidence selection rule — the emitted `evidence` is the `LC_ALL=C`-least member of the set of admissible evidence strings for the matched clause and the chosen provenance class**: at step 8 over that clause's matching carriers of that class, at step 9 over the node's resolved inbound observations. The order runs over the **fully-formed string as written to field 5** — not a carrier, a citing path or an invented rank — so it decides the row directly. **Totality** is the shape feature-003 used and the gate already accepted, a single-component sort made total by a uniqueness rule, with the uniqueness structural here (the domain is a *set* of byte strings and the ordered component *is* the emitted field, so two carriers producing the same string produce the same row) and non-emptiness given by the clause having matched. **Collation `LC_ALL=C`** — this work's precedent (`build-project-index.sh:185`, `kb-freshness-check.sh:460`), deliberately not `build-kb-index.sh:471`'s bare `sort`. The tie-break is **semantics-free by design**: inventing a rank among `declared` carriers or among citers would be a fiat with no project-side convention, the ground on which D4 refuses to invent a settings carrier. **Nothing is discarded** — every citation stays a row of `observations.tsv`. **A validator checks it in two clauses, recomputed rather than trusted:** `significance-rules.sh` exposes the candidate-set enumerator as a function *separate* from the selector, and the test asserts each emitted `evidence` is a **member** of the recomputed set with **no member sorting before it**; membership plus minimality *is* the rule rather than a sample of it, and it fails the first-match-traversal implementation instead of passing it. AC-S9, the Layers test row and the fixture tree now carry **multi-candidate** rows for both cases — two `declared` carriers in one clause, and two citers ordered so the least is not the one a first-match traversal reaches — because both check clauses are vacuous on a single-candidate row. (2) [LOW] **The allow-list subsection's evidence for its own premise was wrong and is corrected.** It claimed no non-contingent clause reaches `.aid/settings.yml` and that Q4 is what fires here. **Q3 fires independently and first**: `.aid/knowledge/pipeline-contracts.md`, `.aid/knowledge/quality-gates.md` and `.aid/knowledge/README.md` each name the path in their frontmatter `sources:` list and all three are depth-1 KB documents — the read the Feature Flow input line declares — so the path is a provisional `named-unit` before Q4 is evaluated. The **emitted value is unchanged** (Q4 promotes P3 → P2, so `depended-upon` either way) and the resolution stands; the premise is restated as what is actually true and load-bearing — **every clause that can reach the path is contingent on some *other* artifact supplying a carrier**, with Q1 and Q2 reaching it on no project at all — so the old unconditional sentence remains unimplementable on a project supplying neither a KB `sources:` entry nor a citer. D3a's clause-3 note carried the same omission, naming only the manifests, and now names the settings schema with the same three documents. (3) [MINOR] **The "in the same words" claim is made accurate.** The promotion bullet stated only the carrier-order half; it now carries the clause-order half too, so all three texts state **both** halves, and the identity claim is narrowed to what is checkable — both halves in each, with "inside the matched clause only" and "across two clauses" verbatim. **Nothing else moved:** the clause-order determinacy rule and its three rejection grounds, the monotonicity hypothesis pair, the allow-list resolution and its "changes no node on any project" claim, the 16-rule `artifact_class` list with its `source` catch-all, the feature-005 producer boundary, tier A/B, `--probe` ownership, the `present` predicate, the citing set, `observations.tsv`, the fixed point, the stage ordering and D3a's totality are all untouched; **feature-006 is not reopened**, its two owed prose edits unchanged; no node count reintroduced | /aid-specify |
| 2026-07-29 | **Re-gate round 3 — six findings fixed (1 MEDIUM, 3 LOW, 2 MINOR); the reopen stays closed, nothing upheld moves, and the descent that ran through four rounds is closed at the bottom.** (1) [MEDIUM] **The set D3a's order ranges over could not be constructed, because no evidence string had bytes.** D3 fixed each `source-artifact` string as a *composition* — "the KB doc path + the matched `sources:` entry", "the citing path plus the matched literal" — with no separator, component order or quoting, while D1a fixed its two media forms byte-exactly; so `evidence` was still not a pure function of disk state across two conforming implementations, on a required field that FR-32's byte-identity and AC-S8 both rest on, and the candidate-set enumerator the Layers table requires could not be written from the SPEC at all. **New D3b: one byte-exact template per emitting arm of D3a's carrier map — 14 of them — in D1a's own two shapes** (Shape A where the matched token *is* the greppable literal; Shape B, D1a's in-repo image form, where the pattern the scanner matched is not what a reviewer greps). Shape B is needed for exactly the two convention arms and the need is verified, not assumed: `tests/run-all.sh` carries `tests/canonical/test-*.sh` verbatim, but `module-map.md`'s prose does **not** contain D3's skill/agent/script patterns verbatim (its text is `canonical/skills/aid-<name>/SKILL.md` at line 235, `canonical/agents/aid-<role>/AGENT.md` at 242, `canonical/aid/scripts/<area>/` at 247 — read 2026-07-29), so a Shape-A template there would print a search token absent from the file it names. **No carrier is added or removed and no `qualifier` changes**; D3b is a formatting contract over the set D3 already fixed, and D3's two "evidence string form" columns are retitled to say they name components while D3b fixes bytes. (2) [LOW] **Step 9's selection rule gains its missing time index.** The qualified set grows across rounds, so a node's resolved inbound observation set grows with it, and latch-at-first-qualification and recompute-at-the-end both conformed while emitting different bytes. **The set is frozen at the fixed point**: the rounds decide only which paths qualify and under which clause, and `evidence`/`evidence_provenance` for every step-9 qualification — Q4's own and the P3 → P2 promotion's alike — are assigned in one pass **after the last round**, over the completed `observations.tsv`. Latching is rejected on the ground the fixed point exists for: it makes field 5 depend on the round a node happened to qualify in. Stated in D3a and in Feature Flow step 9. (3) [LOW] **The discriminating fixture can now have the property claimed for it.** It could not before: every candidate string led with the carrier's own path while steps 4 and 12 sort `LC_ALL=C`, so under the natural sorted-path traversal least-string and first-reached coincided for *any* arrangement of two fixture documents, and re-ordering files could not help because the two orders were one order. **Fixed by construction, in D3b**: every template leads with `<subject>` — identical bytes across all candidates of one node — and puts the matched **token** ahead of the carrier path, so the order turns on the match rather than on the traversal key. Both fixture cases are now given with their bytes and their differing byte offset: `lib/shared.sh` named by `alpha.md` through the literal path and by `beta.md` through the glob `lib/` (least = `beta.md`, reached second), and `lib/cited.sh` cited by `bin/one.sh` through the full path and by `bin/two.sh` through the bare basename (least = `bin/two.sh`, reached second). The live shape is real: `canonical/EMISSION-MANIFEST.md` is matched by the same `sources:` carrier under two different tokens, its literal path and a `canonical/` glob entry. (4) [LOW] **The validator was separate but not independent, and now carries one assertion that is.** Both the scanner's emitted string and the test's recomputed set read the **same** enumerator, so for the natural selector (enumerate → sort → take first) membership and minimality hold by construction and decide "the least element of *the enumerator's* set"; an enumerator that misses a carrier is invisible to both. The pair is **kept** and its scope is now stated — it decides the *selector*, given the enumerator — and the fixture gains a **golden expected value**: `tests/canonical/fixtures/graph/expected-evidence.tsv`, a **sibling of** `tree/` so the scanner never enumerates its own expectations, carrying the exact expected `evidence` bytes written by hand from D3b for both multi-candidate nodes, one node per template, and the `LOGO.PNG` media row. Independent by construction, and the clause that fails when a carrier is missing. Carried into AC-S9 and both test rows. (5) [MINOR] **"A strictly larger set" was false under set inclusion** — the two `sources:` carrier sets are disjoint, so neither contains the other and only their cardinalities compare, a count standing in for a set relation eighty lines above the section that forbids exactly that. Both sets are now **named**: `.aid/settings.yml` from `pipeline-contracts.md`, `quality-gates.md` and `README.md`; `canonical/EMISSION-MANIFEST.md` from `architecture.md`, `artifact-schemas.md`, `authoring-conventions.md`, `decisions.md`, `domain-glossary.md`, `module-map.md` and `tech-debt.md` by literal path plus `architecture.md`, `domain-glossary.md`, `module-map.md` and `project-structure.md` by the `canonical/` glob — from a full parse of all 21 `.aid/knowledge/*.md` frontmatter blocks, 2026-07-29. No relation is claimed beyond disjointness. (6) [MINOR] **`<ext>` in D1a's image template had two admissible renderings on the one case the fixture must carry.** D2a point 5 folds the extension before the membership test and neither section said which form is emitted, so `LOGO.PNG` admitted `PNG` and `png` inside AC-S8's byte-identity scope. **The folded form is emitted**, and it is forced rather than chosen: the string asserts membership of a list that ships lowercase, so `PNG` is not a member and printing it would make the evidence contradict its own test. `LOGO.PNG` emits `'png'`; `<path>` keeps the path's own bytes. Stated in D1a and D2a point 5, asserted in the media test against the same golden file. **Found in self-review and closed in the same pass — the fifth layer, which is the last:** D3b's components were themselves only described, so **§Token formation** now fixes what "as written" means (a scalar and never a line: the carrier format's own unquoting, `- ` markers and table pipes and backticks removed, edges trimmed, terminators stripped), states the **one forced normalisation** (a tab inside a token becomes one space, because a TSV field cannot carry a tab — with a **fourth** single-writer assertion added in D3 so a leak aborts rather than corrupts), and states that **no escaping is performed** because field 5 is never re-parsed. The recursion terminates there and the argument is given: every component of every template is now either a literal fixed in this SPEC or a byte range read from a named file under a stated trim rule, and disk bytes are the enumeration's input rather than a choice this SPEC can make. **A second self-review find, in D5, which the new token rule is what exposed:** every full path contains its own basename, so a single occurrence of `lib/cited.sh` matched a target under two forms and D5 said which forms resolve but never how many literals one occurrence yields — leaving template 13's token undetermined and, with it, the least string, which would have made the new fixture's second case non-discriminating on a conforming implementation. **D5 now attributes an occurrence to the longest form that matches at it, and to one form only**; two *distinct* occurrences, one writing the path and one the bare basename, remain two observations, which is the difference the fixture turns on. **Nothing else moved:** the clause-order determinacy rule and its three rejection grounds, the monotonicity hypothesis pair, the allow-list resolution and its "changes no node on any project" claim, `evidence_provenance`'s determinacy and the collision handling, step-9 non-emptiness, the 16-rule `artifact_class` list with its `source` catch-all, the feature-005 producer boundary, tier A/B, `--probe` ownership, the `present` predicate, the citing set, `observations.tsv`, the fixed point, the stage ordering and D3a's map totality are all untouched; **feature-006 is not reopened**, its two owed prose edits unchanged; no node count reintroduced | /aid-specify |

## Source

- REQUIREMENTS.md §5.7 — **FR-19** (KB-independent enumeration), **FR-20** (an unrepresented source
  concept is a KB defect — *re-keyed 2026-07-29* from the `int:` prefix to **`Kind = source-artifact`**,
  so an undocumented in-repo image is not a KB gap; **AC-15** was re-keyed with it, and both readings are
  used in their corrected form throughout), **FR-21** (structural significance), **FR-21a** (*new* — FR-21's criteria
  bind `source-artifact` only; `image` and `web-page` qualify **by kind**), **FR-22** (exclusions, and
  the stated behaviour when the ignore-list setting is absent), **FR-23** (*rewritten* — asymmetric
  granularity), **FR-24** (derivable rather than judged)
- REQUIREMENTS.md §5.2 — the `Kind` closed enum and its required-prefix pairing table; this feature
  assigns `Kind` to every node it emits
- REQUIREMENTS.md §5.3 — the per-kind id grammars; the `int:` symbol narrowing is **struck**
- REQUIREMENTS.md §5.5 — **FR-8a** (genericity: any project with an approved AID KB; degrade
  gracefully and record the absence in the coverage notes), **FR-9a** (*new* — the `## Coverage notes`
  section, part 2 of which is this feature's content), FR-10 (read-only), FR-11 (`.aid/settings.yml`
  is a staleness input **because** FR-22's ignore list changes which nodes are enumerated)
- REQUIREMENTS.md §5.8 — **FR-30** (Pass 1 produces the KB-side nodes: sections, facts, concepts —
  **not this feature**), FR-31/FR-31a (Pass 2 creates edges, never nodes), **FR-32** (byte-identity
  over the grown deterministic majority)
- REQUIREMENTS.md §5.9 — FR-25/FR-26 (the gap ledger is keyed on the offending node and carries it as
  evidence), FR-28
- REQUIREMENTS.md §2 Problem Statement item 1 — a source concept significant enough to appear in the
  graph but absent from the KB is a **defect**, which is why enumeration must not be KB-driven
- REQUIREMENTS.md §4 Out of Scope — no function- or symbol-level granularity **in project source
  code** (the clause is now scoped; KB sub-document nodes are in scope, elsewhere)
- REQUIREMENTS.md §8 — **A-5 (void)**, A-6 (fixtures are self-built), **D-4** (the ignore-list setting
  does not exist), **D-5** (no machine-readable external-sources entry format, and it must now also
  carry `web-page` and external `image` nodes)
- REQUIREMENTS.md §6 — **NFR-8** (the node-count ceiling is measured, documented and warned about; no
  degraded mode) — consumed, not owned
- REQUIREMENTS.md §9 — **AC-16** (*amended*), **AC-19** (the zero-`web-page` case), **AC-20** (coverage
  notes on a healthy run), and the `int:` half of AC-1, which feature-003 validates
- **feature-003's SPEC (A+, 2026-07-29)** — treated as an **immutable input**: D1/D1a (the ten columns,
  the `Kind` enum, its permitted-prefix sets, and `image_extensions:`), D2/D2b/D2c (the per-kind id
  grammars, `int:` bodies, the `ext:` registry predicate), D5 (display names), D9 (`rel_load_schema`),
  V7/V13 (the validators that decide this feature's output), and its Open Items 5, 6 and 7, which route
  work here
- STATE.md `## Cross-phase Q&A` — Q6 (the settings section), Q7 (the external-sources format), Q10
  (the widened node model), Q12 (asymmetric granularity, A-5 voided), Q14 (the `Kind` enum), Q15 (the
  withdrawn node counts), **Q17** (a count never stands in for a set), **Q18 ruling 3** ("if there is a
  defect, the A+ is false"), **Q22** (the reopen this revision answers)
- **feature-006's SPEC (D4 and its Open Item 2), read 2026-07-29** — the **inbound** finding, not a
  contract this feature consumes: its Open Item 2 named this feature as owner of the carrier →
  `qualifier` mapping and of an explicit severity-monotonicity answer, and its D4 severity map is the
  consumer contract D3a's monotonicity guarantee is stated against. Both are discharged in D3a and
  Open Item 14. *(feature-007's Open Item 3 and feature-006's Open Item 7 are read the same way for the
  zero-row media-node carrier, Open Item 13.)*

**Genericity posture, stated once because it constrains every rule below (FR-8a).** No enumeration
rule below is defined by what this repository happens to contain. Every rule keys on either a **shipped
AID convention** (a template, `module-map.md`'s placement rules, `authoring-conventions.md`, a
tool-shipped data file) or a **git-native, project-agnostic predicate**. Where this SPEC cites a path
under this repository, it is to show that a rule **fires** on real content — never to derive the rule.
That is the distinction Q10 found the superseded vocabulary research on the wrong side of.

**Shared implementation seam with feature-005.** This feature and feature-005 share **one scanner
walk** over the project source: the same traversal that decides whether an artifact is structurally
significant also observes the references, invocations and dependency edges feature-005's deterministic
pass harvests. These are two specifications over one mechanism. `/aid-detail` must treat them that way
and **must not produce two competing scanners** — a second independent walk would drift from this one
and the two would disagree about what exists. The split is deliberate: the significance rule is the
highest-risk decision in this work and deserves its own specification, its own reviewer and its own
acceptance criterion, independent of row production.

**Dependency position.** Not blocked by either RESEARCH feature — enumeration needs no relation
vocabulary and no rendering decision. **Blocked by feature-003** for two data contracts it consumes
rather than restates: `image_extensions:` in `relationship-schema.yml` (D2a) and the `ext:` registry
predicate (D1a). That edge already exists in the plan — feature-003's SPEC records that it "Blocks
feature-004 (which assigns `Kind` to each node record)" — so nothing in the delivery graph moves; only
the reason widens. Blocks feature-005 (which needs the node set) and feature-006 (which detects gaps
against it).

## Description

The graph's value as a quality signal depends entirely on how the project's own artifacts are
discovered. If they were discovered by following what the Knowledge Base already mentions, then
anything the Knowledge Base failed to capture could never appear — and the single most important
defect this work exists to reveal would be structurally invisible. So the project source is enumerated
on its own terms, independently of the Knowledge Base, and whatever the Knowledge Base does not
account for is surfaced rather than silently absent.

This feature discovers three of the seven kinds of thing the graph can hold. The other four — whole
Knowledge Base documents, their sections, the claims within them that carry a checkable reference to
their evidence, and the concepts they define — are discovered by the extraction pass that reads the
Knowledge Base, not here. That boundary is a real division of labour and not a formality: the deep,
sub-document reading happens on the Knowledge Base side, and nothing this feature does produces a node
inside a document.

Not every source file deserves to be a node. A source artifact earns its place by mattering
structurally: because it is an entry point or public surface that others reach through, because
something else depends on it, or because the project's own conventions already treat it as a named
unit. Mere existence on disk is not enough — a graph of every file would be noise, and noise would
bury the signal.

Two kinds do not answer to that test at all. An image and an external web page are nodes because of
**what they are**, not because they passed an assessment: a picture a document depicts and a page a
document cites are each a distinct thing the graph is meant to show, and asking whether a picture is an
entry point is a category error. So they are discovered by a different rule and are deliberately held
in a different place, where the machinery that judges significance cannot reach them and where nothing
downstream can mistake an unreferenced picture for an undocumented piece of the project.

Source code is enumerated at the level of a whole artifact — a script, a skill, a template — and never
at the level of a function, a symbol or a line. That is a rule about code specifically, not about
everything: it is what keeps the code side of the graph legible, and it is now total, with no
remaining case in which a source identifier may name something smaller than a file or a
convention-marked directory.

Some things are excluded outright. Mechanically generated and rendered trees are excluded because they
are reproductions of a single source and would multiply every node, and every reported gap, by the
number of renderings. Third-party vendored code is excluded because it is not the project's to
document. And anything the project has explicitly asked to be ignored in its own settings is excluded,
because that is the project's stated intent. That third exclusion is the one that can be unavailable —
the setting it reads does not exist in the settings schema yet — and when it is unavailable the run
says so in writing rather than behaving as though the project had asked for nothing to be ignored. The
difference between "you configured an empty list" and "there is no list to configure" is exactly the
difference the report exists to preserve.

Finally, significance is decided by rules, not by opinion. A reported gap that rests on a judgment call
is a gap a reviewer cannot check and may reasonably dismiss. So every node arrives with evidence a
reviewer can paste into a search and see what the scanner saw, and nothing is ever promoted to a node
on the strength of a reading alone.

## User Stories

- As a **maintainer/architect**, I want the project's significant artifacts discovered independently of
  what the Knowledge Base says, so that the graph can show me what the Knowledge Base missed rather
  than only confirming what it already claims.
- As a **KB reviewer**, I want an artifact's qualification as significant to rest on a rule with
  checkable evidence, so that I can verify a reported gap instead of taking it on trust.
- As the **AID methodology owner**, I want the significance rule stated explicitly and held to, so that
  it cannot be quietly loosened until inconvenient gaps disappear.
- As a **maintainer/architect**, I want generated trees, vendored code and ignored paths kept out
  entirely, so that the graph is not swamped by copies and the gap list is not padded with findings I
  would never act on.
- As a **maintainer/architect**, I want the images my documents depict and the external pages they cite
  to be nodes in their own right, so that I can see what a document illustrates and what it depends on
  outside the repository — without those things being judged as if they were code.
- As a **maintainer/architect**, I want an unreferenced picture never to be reported to me as
  undocumented project source, so that the gap list keeps meaning the one thing it is supposed to mean.
- As a **maintainer/architect**, I want to be told when an exclusion I believe is configured is in fact
  unavailable, so that a missing setting cannot silently widen what the graph enumerates.
- As an **AI agent**, I want each node record to state its `Kind` explicitly, so that the row I write
  carries a kind that was decided where the evidence lives rather than guessed from an identifier.

## Priority

Must

## Acceptance Criteria

- [ ] AC-16 (enumeration side): Given an enumeration run over the project source, when the resulting
      node set is inspected, then no node originates from a generated or derived tree, from vendored
      third-party code, or from a path matched by the project's ignore list **when that list is
      available**; and **no source-code node is finer-grained than a whole artifact** — no emitted
      `int:` identifier names a function, a symbol or a line range, and none carries a `#` fragment of
      any kind. *(KB concepts, facts and sections are first-class sub-document nodes per FR-23's KB
      clause; they are produced by feature-005, not here — see The enumeration boundary.)*
- [ ] AC-19 (enumeration side): Given a project whose external-sources file registers no keys — or has
      none at all — when enumeration runs, then it **completes successfully** and yields **zero**
      `web-page` nodes and zero external `image` nodes, and the coverage notes record the carrier as
      `absent` with a count of `0`. *(Proven against fixtures per A-6, and against this repository,
      whose `external-sources.md` registers no keys — verified 2026-07-29.)*
- [ ] AC-20 (enumeration side): Given a run on a project where every carrier is present, when the
      coverage-note contributions are read, then this feature has supplied a `present`/`absent` status
      and a non-negative count for **each** of `source-artifact`, `image` and `web-page`, and an
      `Applied` status plus note for **each** of the three FR-22 exclusions — including whether the
      `.aid/settings.yml` ignore list was **available**.
- [ ] AC-1 (`int:` support): Given the emitted node records, when every `int:` identifier is resolved,
      then each names an existing repository-relative path (or an existing directory, for the
      trailing-`/` form), and every `ext:` identifier names a key the external-sources registry
      registers — so feature-003's V2 can never fail on a node this feature emitted.
- [ ] AC-S1: Given a source artifact that is an entry point or public surface, is depended upon by
      another artifact, or is a named unit the project's conventions already treat as a unit, when
      enumeration runs, then that artifact appears as a `source-artifact` node.
- [ ] AC-S2: Given a source file that satisfies none of the significance conditions and is not an
      image, when enumeration runs, then it does not appear as a node — file existence alone never
      qualifies.
- [ ] AC-S3: Given enumeration runs on a project whose Knowledge Base never mentions a particular
      significant artifact, when the node set is produced, then that artifact is nonetheless present —
      proving enumeration is independent of the Knowledge Base and can therefore surface the defect
      described in §2 item 1.
- [ ] AC-S4: Given any node in the enumerated set, when its qualification is examined, then it carries
      rule-based evidence a reviewer can check and an `evidence_provenance` of `declared` or `derived`;
      no node qualifies on inference alone.
- [ ] AC-S5: Given an in-repo file whose extension is in feature-003's `image_extensions:` list, when
      enumeration runs, then it is emitted as an **`image`** node **whether or not** any significance
      clause would have matched it, and it is **not** emitted as a `source-artifact` — so the two node
      streams never both claim one path.
- [ ] AC-S6: Given an in-repo image that no other artifact references, when enumeration runs, then it
      is still a node (FR-21a — kind, not significance), and it appears in `media-nodes.tsv` and **not**
      in `nodes.tsv` — the stream gap detection reads — so it can never become a gap-ledger row.
      *(Checkable on this feature's own outputs; the matching change to how feature-006 and the Coverage
      lens name that class is Open Item 1.)*
- [ ] AC-S7: Given `.aid/settings.yml` in each of its three states — no `graph.ignore` declaration, a
      declaration with zero patterns, and a declaration with patterns — when enumeration runs, then the
      coverage-note exclusion row distinguishes all three, the unconditional exclusions are applied in
      every case, and the run completes in every case.
- [ ] AC-S8: Given two runs with all five of FR-11's staleness inputs unchanged, when the node records
      and the coverage-note contributions are compared, then both are **byte-identical** — no
      timestamp, absolute path, line number, file size or count-ordered row appears in any of them
      (FR-32).
- [ ] AC-S9: Given the fixture tree, when the emitted `nodes.tsv` is inspected, then **each of the four
      declared `qualifier` values appears on at least one row**; and given a fixture path that satisfies
      both a `named-unit` carrier and an inbound reference, then its emitted `qualifier` is
      **`depended-upon`**, not `named-unit` — the emitted value is the strongest applicable clause under
      D3a's precedence, so no node carries a qualifier whose severity is lower than that of a clause it
      also satisfies (for a severity function meeting D3a's two stated hypotheses); and given a fixture
      path whose **only** Q1 carrier is the *derived* executable header and which also carries a
      *declared* Q2 carrier, then its emitted `qualifier` is **`entry-point`** and its `evidence` is the
      shebang line with `evidence_provenance` `derived` — the clause order decides the value, and the
      `declared`-before-`derived` carrier order never reaches across two clauses; **and given a fixture
      path whose matched clause admits two or more evidence strings of the chosen provenance class —
      one carrying two `declared` carriers inside one clause, one receiving inbound references from two
      citers — then each emitted `evidence` is a member of that row's recomputed candidate set with no
      member sorting before it under `LC_ALL=C`** (D3a §The evidence selection rule), which decides the
      selector against the enumerator; **and given the fixture's `expected-evidence.tsv`, then every
      `evidence` it lists is emitted byte-for-byte as written there** — a golden literal taken from
      D3b's templates and computed by no part of the scanner, which is the clause that is independent of
      the enumerator and therefore the one that fails when an admissible carrier is missing from it.

> **The `AC-S<n>` scheme is borrowed, not invented.** feature-003's SPEC introduced it for
> SPEC-authored criteria, established that no requirement id can take the form `AC-S<n>` (the
> requirements' grammar always places a digit immediately after `AC-`), and stated that "the same shape
> is available to the sibling SPECs if they choose to label their own criteria." This SPEC takes it up,
> so the two specs label spec-authored criteria the same way and `AC-S` stays greppable. The four
> previously-unlabelled criteria of the 2026-07-28 revision are AC-S1–AC-S4, unchanged in substance
> except that AC-S2 now names the image exemption.

---

## Technical Specification

> The amended REQUIREMENTS.md (2026-07-29) is the authority, and **feature-003's contracts are
> immutable inputs**. Where this SPEC needed something feature-003 owns, it consumes feature-003's data
> or its loader; where it disagrees or needs more, the item is routed to feature-003 under Open Items
> and never resolved silently here.

**How to read the "which requirement, checked how" claims.** Every rule below names the requirement it
satisfies and the mechanism that decides it, and every rule is **decidable** — a total function of disk
state and shipped data, with no reviewer judgment at any step. That pairing is deliberate: this work's
recorded failure mode (Q9, Q15) was an artifact that was complete, traceable and internally consistent
while answering the wrong question, and FR-24 independently requires significance to be *derivable
rather than judged*. A rule stated without a decision procedure is treated here as undelivered.

**Reading convention for the `D`-references, because two specs now use the same labels.** An
unqualified `D1`, `D1a`, `D2a`, `D5` and so on always means **this SPEC's** section. A reference to
feature-003's is always written `feature-003 D<n>`. The overlap is real and unavoidable — feature-003's
`D1a` is the `Kind` enum while this SPEC's is the media node record, and its `D5` is the display-name
rule while this SPEC's is the observation record — so the qualification is load-bearing rather than
pedantic, and every cross-spec citation below carries it.

### The enumeration boundary — what this feature does **not** produce

FR-23 is asymmetric, and the asymmetry falls exactly on this boundary. Stated first, and as its own
section, because the old revision's "Everything is enumerated at the level of a whole artifact" read as
a claim over the whole node model, and a reader must not come away thinking enumeration produces the
KB-side nodes.

| §5.2 `Kind` | Produced by | Mechanism |
|-------------|-------------|-----------|
| `source-artifact` | **this feature** | the single source walk + FR-21 significance (D1, D3) |
| `image` | **this feature** | the same walk + the `image_extensions:` test (D1a, D2a); or the `ext:` registry |
| `web-page` | **this feature** | the `ext:` registry predicate (D1a) |
| `document` | **feature-005**, Pass 1a | the KB scan set (FR-30; feature-003 D2a) |
| `section` | **feature-005**, Pass 1 | ATX headings, levels 2–6 (FR-30; feature-003 D2a-1) |
| `fact` | **feature-005**, Pass 1 | checkable source anchors (FR-30; feature-003 D2a-2) |
| `concept` | **feature-005**, Pass 1 | definition markers under a level-3+ heading (FR-30; feature-003 D2a-3) |

Three consequences, each stated so it is checkable rather than trusted:

1. **No KB document becomes a node here, and no KB-side node is discovered here.** `.aid/**` is cut from
   the source walk (D4 Class 4) with one declared allowlist entry, so no KB document can become a node
   here at all — let alone a section, fact or concept inside one. **This feature reads the KB in exactly
   two narrow ways, and both are reads of a file, never a discovery of one:**

   | Read | What it is used for | Why it cannot cross the boundary |
   |---|---|---|
   | `.aid/knowledge/external-sources.md` | the **registry of external keys** (§5.1 item 3), read as a table predicate and not as prose | the keys become `ext:` nodes; the file itself never becomes an `int:` node (D4 Class 4's "the cut is on paths becoming nodes, not on reading") |
   | a KB document's frontmatter `sources:` list | one of D3's **declared carriers** — it can qualify an already-enumerated `int:` path (D3a Q3) | it reads frontmatter of a document that is itself excluded, and it emits nothing for the document; the only node it can affect is an `int:` path that survived D4 |

   **The earlier text said "the single KB file this feature reads is `external-sources.md`", which D3's
   own `sources:` carrier contradicts** — a claim that was false as written while its load-bearing half
   (nothing here produces a KB-side node) was and remains true. Corrected rather than left standing,
   because the reopen that produced this revision was itself a declared-but-unassigned value space and
   this was the same class of defect one section away.

   **FR-19 independence survives the `sources:` read, and the argument is directional.** FR-19's
   "independently of the KB" exists to prevent **omission** — an artifact the KB failed to mention being
   structurally invisible (§2 item 1). A `sources:` entry can only **add** a qualification to a path the
   walk already found; it can never withhold one, and no path's enumerability depends on the KB
   mentioning it, because Q1, Q2 and Q4 read nothing under `.aid/knowledge/` at all and Q3's remaining
   carriers — `tests/run-all.sh`'s discovery glob and the two convention patterns — are KB-free. FR-19's wording
   additionally scopes the principle to `int:` nodes, so reading the registry for `ext:` nodes is the
   design rather than an exception to it. **The seam guard is not tripped either**: a depth-1 read of
   `.aid/knowledge/` is not a repository traversal, which is the guard's own stated scope — the same
   ground on which feature-005's pass 1a and feature-010's digest read that directory.
2. **The `kb:` and `int:` node sets are disjoint**, which is what stops a KB document appearing on both
   sides of the coverage question (D4 Class 4). `test-graph-node-partition.sh` asserts it over both of
   this feature's streams.
3. **The deep-granularity work is on the far side of the boundary.** FR-31a part 2 additionally forbids
   the agent pass to create nodes at all, so the complete node set is: this feature's two streams plus
   feature-005's Pass 1 output. There is no third producer and no promotion path (D3).

### Enumeration rules at a glance

One row per rule this feature owns. Every "decision procedure" column entry is a total function whose
inputs are on disk or in a shipped data file — which is what makes FR-24's *derivable rather than
judged* hold by construction rather than by discipline.

| # | Rule | Requirement | Decision procedure (what makes it decidable) | Checked by |
|---|------|-------------|----------------------------------------------|-----------|
| R1 | Exclusions applied before anything else | FR-22, AC-16 | git-native predicates (`check-ignore`, `check-attr`) plus literal path prefixes and globs; no content judgment, no per-file heuristic | AC-16; `test-source-enumeration.sh` (one fixture per class); the single-writer assertion in D3 |
| R2 | Ignore-list availability is a three-state probe | FR-22, FR-11, D-4 | one resolver call that returns `declared` / `undeclared`; the pattern list is then read through the same parser (D4a) | AC-S7; `test-read-setting.sh` (probe modes); `test-source-enumeration.sh` |
| R3 | Media classification precedes significance and partitions the surviving paths | FR-21a, FR-23, §5.2 | extension membership in feature-003's `image_extensions:`, read via `rel_load_schema`; a path lands in exactly one stream (D2a) | AC-S5; feature-003 **V13** tier 2 on the emitted table; `test-graph-media-nodes.sh` |
| R4 | In-repo images are nodes by kind, never by significance | FR-21a, FR-23 | the extension test alone; the media writer has **no** `qualifier` field, so a significance verdict is unrepresentable (D1a) | AC-S5, AC-S6; `test-graph-media-nodes.sh` (an unreferenced image is a node) |
| R5 | External nodes are exactly the registered keys | FR-21a, §5.1 item 3, A-1 | feature-003 D2c's registry predicate — a table row inside `## Sources` whose first cell is a backticked key (D1a) | AC-1, AC-19; the Q4 synthetic fixture; an empty-registry fixture |
| R6 | An `ext:` node's `Kind` is `web-page` unless a media type says otherwise | §5.2, D-5, feature-003 D1a/Open Item 6 | a constant today, and an `image/*` prefix test on the declared media type once the format carries one (D1a) | `test-graph-media-nodes.sh`; **unverifiable in the table by construction** — feature-003 D1a records why, Open Item 3 tracks the fix |
| R7 | Significance qualifies `source-artifact` only | FR-21, FR-21a, FR-24 | a fixed evaluation order over declared carriers then derived mechanisms; every mechanism is a literal match, a pattern match, or a count ≥ 1 (D3) | AC-S1, AC-S2, AC-S4; `test-source-enumeration.sh` per clause |
| R7a | Every `qualifier` value has exactly one assigning rule, the emitted value is the **strongest applicable** clause, and the rule is total — every candidate resolves to exactly one clause or to no clause | FR-21, FR-24, FR-26 | a total carrier → value map plus a stated precedence (P1 > P2 > P3) closed into a **total order over clauses** by the P1 tie-break (Q1 > Q2 > Q4 > Q3); the value is the maximum applicable clause, not the first match in flow order and not a function of evidence provenance, which is what makes a severity function that is **monotone in that precedence and constant on P1** monotone over this field (D3a) | AC-S9; `test-source-enumeration.sh` (one fixture per value, the promotion case, and the P1 tie-break in its derived-Q1/declared-Q2 shape) |
| R8 | No node is ever qualified by a reading | FR-24 | `evidence_provenance` has two values and one writer that rejects a third; `candidates.tsv` is write-only (D3) | AC-S4; `test-graph-node-provenance.sh` |
| R9 | Source-code granularity is whole-artifact, totally | FR-23 code clause, AC-16, §5.3 | directory collapse for the two convention-marked directory kinds; **no code path emits `#` in an `int:` id** (Feature Flow step 6) | AC-16; feature-003 **V7** (rejects *any* `#` in an `int:` body) |
| R10 | `Kind` is carried, never inferred downstream | §5.2, feature-003 D1a/D5 | `node_kind` is an explicit field in both records, decided where the evidence is (D1, D1a) | feature-003 **V13** tier 1 and 2; **V8** (one kind per id) |
| R11 | Coverage-note statuses are functions of the run's own state | FR-9a part 2, FR-8a, AC-20 | `present` iff this project supplied ≥ 1 instance of the kind's carrier, which is a count the run holds before it emits anything; `Applied` from the exclusion's own result; the ignore row from R2's probe (D7) | AC-20, AC-19; feature-003 **V14**; `test-graph-coverage-notes.sh` |
| R12 | Every output is byte-stable | FR-32, AC-5 | no timestamp, absolute path, line number or size in any field; `LC_ALL=C` sort by `node_id`; fixed row order in the coverage contribution (D1, D1a, D7) | AC-S8; `test-source-enumeration.sh` re-run comparison |

### The shared scanner seam (binding on `/aid-detail`)

**This feature owns the walk. Feature-005 consumes its output and never walks the project source
itself.**

One script, `canonical/aid/scripts/graph/scan-source.sh`, performs a single traversal of the project
source and writes **four** streams into the gitignored scratch space (`.gitignore` carries
`.aid/.temp/`; `authoring-conventions.md` designates `.aid/.temp/*` as the ledger/scratch space,
deleted at skill DONE):

| Stream | Owner | Consumer | Content |
|--------|-------|----------|---------|
| `.aid/.temp/graph/nodes.tsv` | this feature | feature-005 (pass 1b, pass 2 bounding), feature-006 (gap detection), feature-010 (staleness digest) | one row per structurally significant **`source-artifact`** (D1) |
| `.aid/.temp/graph/media-nodes.tsv` | this feature | feature-005 (endpoint universe), feature-007/009 (rendering) | one row per **`image`** and per **`web-page`** node (D1a) |
| `.aid/.temp/graph/observations.tsv` | this feature (mechanism) | feature-005 pass 1b (meaning) | one row per mechanically observed reference/invocation/dependency seen during the same walk (D5) |
| `.aid/.temp/graph/candidates.tsv` | this feature | feature-005 pass 2 only | one row per artifact or reference the walk noticed but could **not** qualify or resolve by rule (D6) |

A fifth output, `.aid/.temp/graph/coverage.tsv`, carries this feature's coverage-note contribution
(D7). It is a report about the run rather than a node stream, which is why it is listed separately.

The division of labour: **this feature decides which nodes exist**; feature-005 decides which rows
exist. The scanner therefore *emits* observations without typing them — it never consults the relation
vocabulary and never writes a relationship row. Feature-005's `derive-edges.sh` reads
`observations.tsv` and does all typing.

The seam is enforced mechanically, not by convention, so `/aid-detail` cannot decompose this into two
competing scanners: `tests/canonical/test-graph-single-scanner.sh` asserts that within
`canonical/aid/scripts/graph/`, no file other than `scan-source.sh` contains a **repository**
traversal — a `find` or `git ls-files` whose root is the repo root. A second walk fails that suite.

The guard is deliberately scoped to *repository* traversal so it does not obstruct the sibling features
that legitimately read a fixed single directory or an already-enumerated list: feature-005's pass 1a
reads `.aid/knowledge/` non-recursively at depth 1 (it produces the KB-side node set, which no walk of
the source could produce), and feature-010's staleness digest hashes the paths this feature enumerated
plus that same depth-1 KB directory. Neither is a second walk of the project source, and neither can
disagree with this scanner about what exists.

**Sourcing feature-003's loader is not a second walk.** `scan-source.sh` sources
`relationship-schema.sh` for `rel_load_schema` (feature-003 D9), which reads one shipped data file and
walks no tree. The seam guard tests for a repository traversal, not for a library import, so the two
coexist by construction. The relation vocabulary is **not** loaded here — this feature never types an
edge, so `rel_load_vocabulary` is feature-005's call, not the scanner's.

### Data Model

#### D1. `source-artifact` node record

`nodes.tsv` — tab-separated, no header, `LC_ALL=C`-sorted by `node_id`, LF-only, one row per node.
Tab-separated because the values contain `/`, `#` and spaces but never a tab, and because the repo
already uses TSV for deterministic machine streams (`kb-freshness-check.sh --format tsv`, and
`build-project-index.sh`'s internal `path\tlang\tlines\tmtime` join).

| # | Field | Value space |
|---|-------|-------------|
| 1 | `node_id` | `int:<repo-relative-path>` for a file, `int:<repo-relative-path>/` for a directory artifact — feature-003 D2b |
| 2 | `name` | display name; feature-003 D5 requires the full repo-relative path verbatim, so this equals `node_id` minus the `int:` prefix |
| 3 | `artifact_class` | closed descriptive enum, **total** — assigned by D2's ordered rule list, whose last rule is a catch-all, so a required field always has a value — **renamed** from `kind` this revision |
| 4 | `qualifier` | `entry-point` \| `public-surface` \| `depended-upon` \| `named-unit` — the **strongest applicable** FR-21 clause, at the granularity FR-21's clause 1 itself distinguishes. **Four values over three clauses is a refinement, not a bijection**, and each value has exactly one assigning rule with a stated evaluation position and precedence level — D3a |
| 5 | `evidence` | a durable anchor: a path plus a grep-recoverable symbol, heading, glob or matched literal (D3), **fixed to the byte** by D3b's per-carrier template. **One string, chosen totally**: where the node's clause admits more than one, it is the `LC_ALL=C`-least of them — D3a §The evidence selection rule |
| 6 | `evidence_provenance` | `declared` \| `derived` — **never `inferred`**; the field has no third value (FR-24, and invariant `no-inferred-node` in D3) |
| 7 | `node_kind` | §5.2's `Kind`; in this stream the constant **`source-artifact`** — **appended** this revision |

`node_id` is the primary key. A given path appears at most once and carries **exactly one** `qualifier`;
when more than one clause qualifies it, the **strongest applicable clause under D3a's precedence order**
wins — not the first clause the flow happens to test. The record stays a pure function of disk state and
the row cannot flip between runs, because precedence plus D3a's P1 tie-break is a fixed **total** order
over the four clauses — Q1 > Q2 (both P1) > Q4 (P2) > Q3 (P3) — over a value space that is itself fixed,
and because the one place the flow cannot evaluate in precedence order is settled by a
single one-directional promotion (D3a, Feature Flow step 9).

No field carries a timestamp, an absolute path, a line number or a file size. That is what makes
`nodes.tsv` — and therefore the deterministic half of `relationships.md` — byte-identical across runs
(FR-32, R12).

**Field 3 is renamed and field 7 is appended, and the shape is otherwise untouched on purpose.**
Both changes are forced, and both were made in the way that costs a sibling the least:

- **`kind` → `artifact_class`.** §5.2 made `Kind` a closed enum with seven values and a required
  prefix each. A field also called `kind`, holding `script`/`template`/`manifest`, would collide with it
  in every downstream conversation and in every task DETAIL. Renaming this one is correct because it is
  the *descriptive* attribute, not the schema's `Kind`. The **position and value space are unchanged**,
  so a positional reader is unaffected.
- **`node_kind` appended, not inserted.** feature-003 D5 requires that "for a node feature-004 emits,
  the name must equal that node record's `name` field", and feature-003 D1a states that for `ext:` ids the
  `image`-versus-`web-page` distinction "is trusted from feature-004's node record" because it cannot be
  recovered from the key. So the `Kind` must be an explicit field of this record, not a value a consumer
  derives. It is **appended** so that fields 1–6 keep their positions: feature-006 reads field 2 by
  position and `qualifier`/`evidence`/`evidence_provenance` by name, and it is **not** in this work's
  re-specification set, so preserving its contract is a requirement rather than a courtesy. In this
  stream the value is a constant — carried anyway, because "carried as data, not as code" is the same
  posture feature-003 adopted for the enum itself, and because a constant read is what stops
  feature-005 hard-coding the literal in its writer.

#### D1a. `image` and `web-page` node record

`media-nodes.tsv` — tab-separated, no header, `LC_ALL=C`-sorted by `node_id`, LF-only:

| # | Field | Value space |
|---|-------|-------------|
| 1 | `node_id` | `int:<repo-relative-path>` (in-repo image) or `ext:<key>` (external image or web page) — feature-003 D2b / D2c |
| 2 | `name` | feature-003 D5: `<path>` verbatim for an in-repo image; `<key>` for an external image or a web page |
| 3 | `node_kind` | `image` \| `web-page` |
| 4 | `evidence` | a durable anchor (D3), per the two forms below |
| 5 | `evidence_provenance` | `declared` \| `derived` — never `inferred` (the `no-inferred-node` invariant extends here unchanged) |

**There is no `qualifier` field, and its absence is the enforcement of FR-21a.** FR-21a says FR-21's
three significance criteria "apply to project source artifacts (`int:`) only" and that `image` and
`web-page` are first-class "by kind … not by passing a significance assessment". A record with nowhere
to put a qualifier cannot carry one, so the exemption is structural rather than instructed — the same
technique feature-003 used to make a naive one-to-one kind/prefix check unrepresentable. The
significance evaluator is never invoked on a media path: step 6 partitions the survivors and step 8
evaluates only the `source-artifact` side of that partition.

**FR-21a's own parenthetical is prefix-shaped, and this feature reads it by kind.** Its first sentence
scopes the criteria to "project source artifacts (`int:`)", which in-repo images now also carry; its
second sentence then carves `image` out **by kind**, so the requirement is self-consistent and needs no
correction. It is called out because reading that parenthetical as the operative scope is exactly the
error that made AC-15 and FR-20 wrong before they were re-keyed to `Kind = source-artifact`. Here the
scope is the **partition**, not the prefix, which is why the media record has no qualifier field to fill.

**Two rows, two carriers, two provenances:**

| Node | Discovery rule | `evidence` form | `evidence_provenance` |
|------|----------------|-----------------|-----------------------|
| in-repo `image` | a surviving path whose extension is a member of feature-003's `image_extensions:` (D2a) | `<path> -- extension '<ext>' listed in relationship-schema.yml (search: "image_extensions")`, where **`<ext>` is the lower-cased form** — see below | `derived` — the scanner computed the extension match |
| external `image` / `web-page` | a key the external-sources registry registers, by feature-003 D2c's predicate | `.aid/knowledge/external-sources.md (search: "<key>")` — the key as written in its registry cell | `declared` — the project registered the key itself |

**`<ext>` renders the folded form, and that is forced rather than chosen.** D2a point 5 lower-cases the
extension *before* the membership test, and the template did not say which form reaches field 4 — so
`LOGO.PNG`, the exact case the fixture tree is required to carry, admitted both `PNG` and `png` with no
rule picking, inside `media-nodes.tsv`, which is inside AC-S8's byte-identity scope. The rule is
**`<ext>` is the folded (lower-cased) bytes, the ones actually tested**, and it is forced by what the
string asserts: the string claims the extension is *listed in* `image_extensions:`, and
`image_extensions:` ships as a lowercase list, so `PNG` is not a member of it and printing `PNG` would
make the evidence contradict the test it reports. `LOGO.PNG` therefore emits
`LOGO.PNG -- extension 'png' listed in relationship-schema.yml (search: "image_extensions")`. Nothing is
lost: the path's own bytes are preserved verbatim in `<path>`, so the row stays greppable at both ends —
the path in the repository, the key in the schema file.

Both evidence strings are literally greppable, which is what FR-24 asks of them: a reviewer pastes the
search token and sees what the scanner saw. **Neither cites a tool-internal absolute path**: the schema
file is named by basename plus the key to search for, because its resolved location is the install root
of whichever AID installation ran the skill (feature-003's Feature Flow resolves it as
`<install-root>/aid/templates/graph/relationship-schema.yml`), and an evidence string carrying an
install-specific path would neither be greppable in the target repository nor byte-stable across
machines (FR-32).

**The external registry, and exactly what is and is not specifiable today.** The predicate is
feature-003's, consumed and not restated: within `external-sources.md`'s `## Sources` section, a GFM
table row whose first cell is a key rendered as inline code registers that key. Three properties follow
and each matters to an acceptance criterion:

- **Every registered key becomes exactly one node.** Enumeration does not wait for a KB document to
  cite the key — that is FR-19's independence principle applied to the external side, and it is what
  lets an unreferenced external source appear as an orphan node, which FR-14a's orphan toggle exists to
  surface. A URL appearing in a document's `sources:` list but **not** registered yields **no** node
  here; feature-005 records the unresolvable reference as a candidate.
- **An empty or missing registry is not a failure.** The predicate is match-based, so there is no
  malformed-input branch to fail on: a file with no matching row registers no key, and an absent file
  registers no key. Zero external nodes is a well-formed outcome, the run exits `0`, and the coverage
  notes carry the `absent` status and the `0` count. That is AC-19's `web-page` arm satisfied by
  construction rather than by a guard. **On this repository it is the live case**: `external-sources.md`
  registers no keys — its `## Sources` section is prose ("No external documentation was provided during
  discovery") and its `sources:` frontmatter holds the placeholder `- (none)` (verified 2026-07-29).
- **`Kind` for an `ext:` node is where the missing format bites, and it is not silently guessed.** An
  `ext:` key is opaque: feature-003 D1a records that `image` versus `web-page` "cannot be recovered from
  the key" and that this is "the single place in the schema where `Kind` is unchecked by construction",
  trusted from this record. Two-tier rule, so the blocked part is visible rather than latent:

  1. **Tier A — available once the entry format carries a media type.** `node_kind` is `image` iff the
     declared media type begins `image/`, else `web-page`. `evidence_provenance` stays `declared`. This
     is the arm D-5 and feature-003 Open Item 1 are about, and it is the arm that makes feature-003's
     unchecked cross-check checkable.
  2. **Tier B — today, with no media type in the format.** Every registered key is emitted as
     **`web-page`**, and **no external `image` node is emitted at all**. The class is therefore *empty*
     rather than *mis-populated*, which is the failure mode worth preferring: a wrong `image` kind is
     undetectable by any validator (feature-003 D1a says so explicitly), so the conservative constant is
     the only assignment whose error mode is bounded. The coverage notes carry an additional
     `image-external` row with status `absent` naming the reason (D7).

  **An `Origin`-column extension test was considered and rejected.** feature-003's example registry
  table shows an `Origin` column holding a URL, and keying `image` on that URL's file extension would be
  mechanical. It is not adopted for three reasons: feature-003's *predicate* is defined over the **first
  cell only**, so the second column's name and position are illustration and not contract — keying on it
  would be exactly the silent divergence this SPEC is instructed to avoid; a URL extension is not a media
  type, and a page may end `.png` while an image endpoint may have no extension at all; and because the
  result is unverifiable by construction, a heuristic here buys reach at the cost of an error nobody can
  detect. Routed to Open Item 3 with the media-type requirement restated, not worked around.

#### D2. `artifact_class` enum, and the rule that assigns it

**This is not §5.2's `Kind`.** It is descriptive metadata, and it was renamed from `kind` this revision
precisely so the two can never be confused (D1). It is *intended* for feature-007's grouping and
feature-006's gap phrasing; **no sibling SPEC reads it today** (verified 2026-07-29 — the identifier
appears in no other SPEC, PLAN.md or task DETAIL), and **no validator constrains it**, because the field
never reaches `relationships.md`. Both facts matter below: they are what make a catch-all value safe here
in a way it would not be in a schema column.

**Assignment is a first-match ordered rule list over the node id, and nothing else.** Stated because the
2026-07-29 revision made the field required without saying how it is filled, which left a path that
qualifies only by step 9's `depended-upon` settling with no defined value for a required field:

| # | `artifact_class` | Match rule — repo-relative glob, bash `case` semantics | Unit |
|---|---|---|---|
| 1 | `skill` | `canonical/skills/*/` | directory |
| 2 | `agent` | `canonical/agents/*/` | directory |
| 3 | `workflow` | `.github/workflows/*` | file |
| 4 | `renderer` | `.claude/skills/generate-profile/scripts/*` | file |
| 5 | `installer` | `install.sh`, `install.ps1` | file |
| 6 | `cli-entrypoint` | `bin/*`, `packages/*/bin/*` | file |
| 7 | `library` | `lib/*` | file |
| 8 | `settings-schema` | `.aid/settings.yml`, `canonical/aid/templates/settings.yml` | file |
| 9 | `manifest` | `canonical/EMISSION-MANIFEST.md`, `*/package.json`, `*/pyproject.toml`, `canonical/aid/templates/generated-files.txt` | file |
| 10 | `test-suite` | `tests/*` | file |
| 11 | `template` | `canonical/aid/templates/*` | file |
| 12 | `dashboard-module` | `dashboard/*` | file |
| 13 | `site-module` | `site/*` | file |
| 14 | `script` | `canonical/aid/scripts/*`, or a final extension of `sh`, `ps1`, `psm1` or `py` | file |
| 15 | `doc` | a final extension of `md` | file |
| 16 | `source` | *(catch-all — matches every remaining path)* | file |

Every pattern above is grounded in a path this repository actually tracks, verified 2026-07-29 against
`git ls-files`: `canonical/agents/aid-architect/` and `canonical/skills/aid-discover/` are real
directories; `packages/npm/bin/aid.js` is why rule 6 carries the `packages/*/bin/*` arm alongside `bin/*`;
`packages/npm/package.json`, `packages/pypi/pyproject.toml` and `canonical/aid/scripts/summarize/package.json`
are what rule 9 matches; and there is **no root-level `package.json`**, so no pattern claims one.

Four properties make this exact:

1. **It is a total function of the id.** Rule 16 matches unconditionally, so every emitted node has a
   value no matter which clause qualified it. The `depended-upon`-only path the ledger names is covered by
   whichever of rules 1–15 its path matches, or by 16.
2. **It is evaluated once, at emit (Feature Flow step 12), and is independent of `qualifier`.** The two
   answer different questions — `artifact_class` is *what the thing is*, `qualifier` is *why it is a node*
   — and keeping them separate is what stops "it is a script, therefore it matters" from smuggling file
   existence in as a qualification (the failure mode FR-21's second sentence forbids). Nothing in the rule
   list consults evidence, provenance or the qualifier.
3. **Order resolves every overlap, and each ordering constraint is stated rather than incidental.** The
   generic rules must sit below the located ones, because the located ones are the informative answer:
   `settings.yml` and `generated-files.txt` live under `canonical/aid/templates/`, so 8 and 9 precede 11;
   `tests/*` files carry `.sh` extensions and `dashboard/reader/*.py` carries `.py`, so 10, 12 and 13
   all precede the extension-based rule 14, or a dashboard module would be filed as a bare `script`;
   `canonical/aid/scripts/summarize/package.json` is a real path that rules 9 and 14 both match, and 9
   winning is what makes it a `manifest` rather than a `script`; and
   `.md` is common enough that 15 sits last before the catch-all, or it would swallow
   `EMISSION-MANIFEST.md` and every template. One overlap is resolved by fiat rather than by principle —
   `site/src/content/docs/*.md` is a `site-module` (13) and not a `doc` (15) — and that is *why* the list is
   ordered rather than a set of independent predicates: an unordered rule set would make it a coin flip.
   Under `case` semantics `*` spans `/`, which is why the patterns are short, and that is the same matching
   style D4a's ignore patterns use, grounded in `build-project-index.sh`'s `NOTABLE_PATH_PATTERNS`.
4. **It is byte-stable.** A pure path function over a `LC_ALL=C`-sorted id set consults no clock, no
   environment and no file content, so it lands inside FR-32 with the rest of the record.

**The closed-enum-versus-genericity tension, resolved rather than noted.** Rules 1–15 key on **AID's own
authoring conventions**; a TypeScript project's modules and a Rust project's crates match none of them.
Before rule 16 existed that was FR-8a's failure mode reappearing in a field — the shipped artifact fitted
to one repository. The resolution is deliberately the smaller of the two available:

- **Adopted: one shipped catch-all, `source`.** It is not an error marker or an "unknown" sentinel; it is
  the honest generic class — *a project source artifact whose class the shipped rules do not name* — and
  it is what an ordinary module gets in any project AID did not author. That makes the enum **total for
  every project** while keeping it **closed**, so a consumer can still switch on it exhaustively and the
  stream stays byte-stable. A generic project's graph loses per-class grouping granularity and loses
  nothing else; every node still carries its `qualifier`, `evidence` and `node_kind`.
- **Considered and not adopted now: feature-001's `coined` precedent.** feature-001 permits `coined` in a
  **project extension** of the relation vocabulary, which works there because that vocabulary already has
  an extension file with a fixed location, a loader, precedence rules and a validator (feature-003 D4).
  `artifact_class` has none of those, and — verified above — no consumer and no validator either. Adding a
  per-project taxonomy authoring surface with nothing that loads it and nothing that reads it is exactly
  the scope FR-25's rationale warns against. FR-8a asks that the tool **work** on any project, which the
  catch-all delivers; it does not ask that every project author its own taxonomy. If a consumer ever
  needs finer classes, feature-001's shape is the precedent to copy, and that is Open Item 12.

**`agent` here is an `artifact_class`, not a `Kind`.** The owner's decision that there is **no `agent`
node kind** governs §5.2's enum and is untouched by this row: `canonical/agents/<name>/` is a
`source-artifact` node — `node_kind` is the constant `source-artifact` in this stream (D1 field 7) — whose
descriptive class happens to be `agent`. The two words coexisting is the reason field 3 was renamed in the
first place.

The `renderer` row is the one node that legitimately lives under a normally-excluded tree:
`.claude/skills/generate-profile/` is maintainer tooling authored in place, not a render of `canonical/`
(`module-map.md`: "Lives at `.claude/skills/generate-profile/scripts/`"). It is therefore a declared
allowlist entry in D4, not an exception in the significance rule.

Media nodes carry **no** `artifact_class`. An image is not one of the project's structural artifact
kinds, and inventing a `media` value would put a non-significance-bearing thing into an enum whose
consumers read it alongside `qualifier`.

#### D2a. Kind classification precedes significance — the partition rule (FR-21a, §5.2, feature-003 V13)

**Author decision, and the ordering is load-bearing rather than tidy.** After exclusions, every
surviving path is classified **before** any significance clause is evaluated:

> A surviving path whose final extension is a member of feature-003's `image_extensions:` is an
> **`image`** and goes to `media-nodes.tsv`. Every other surviving path is a **`source-artifact`**
> candidate and goes on to the significance evaluator. No path goes to both.

Five things make this exact:

1. **The extension set is data, not code.** It is read from `relationship-schema.yml`'s
   `image_extensions:` key through feature-003's `rel_load_schema` (feature-003 D1, D9), which is the
   file's stated purpose — authored at `canonical/aid/templates/graph/relationship-schema.yml` and
   resolved at run time as `<install-root>/aid/templates/graph/relationship-schema.yml`, per
   feature-003's own Feature Flow. This feature neither restates the list nor keeps a copy, so the two
   cannot drift, and adding an extension stays a one-file change.
2. **The ordering is forced by feature-003's V13, not chosen.** V13 tier 2 asserts that for an `int:`
   id, the kind is `image` **iff** the extension is in `image_extensions:` and `source-artifact`
   otherwise. So an emitted `source-artifact` whose extension is in that list is a **table finding**,
   not a matter of taste. Running significance first and classifying afterwards would let a path qualify
   as `depended-upon`, be written as a `source-artifact`, and then fail V13 — a defect produced by rule
   ordering alone.

   **A live instance exists, and it *resolves* under D5 rather than merely existing.** Both links
   verified 2026-07-29:

   | Link | Reference as written | Resolves to | Why it resolves under D5 |
   |---|---|---|---|
   | `site/astro.config.mjs:147` | `Header: './src/components/overrides/Header.astro'` | `site/src/components/overrides/Header.astro` | D5's relative-reference bullet: resolved against the citing file's directory (`site/`), normalised, matched as a full path. So the override is itself an enumerated `source-artifact`, qualified `depended-upon` |
   | `site/src/components/overrides/Header.astro:14` | `import casuloLogo from '../../assets/casulo-ai-labs.png';` | `site/src/assets/casulo-ai-labs.png` | same bullet: `../../` normalises the citing directory `site/src/components/overrides/` to `site/src/`; the result is **inside** the repository root, so D5's escape branch does not fire; and the target survives every D4 class — git-tracked (so no `check-ignore` hit), under `site/src/` rather than `site/dist/`, not vendored, not under `.aid/` |

   The second link is a repo-relative `import` from an enumerated source artifact to an image, which is
   exactly what the `depended-upon` clause is written to catch. Classify first and the image goes to
   `media-nodes.tsv` with no qualifier; classify second and it is written into `nodes.tsv` as a
   `depended-upon` `source-artifact` whose extension is in `image_extensions:` — the V13 tier-2 failure
   above, produced by nothing but rule order. **The resolution argument is spelled out rather than
   asserted precisely so the example cannot rot**: if D5 ever stopped resolving relative imports, the
   row above would visibly stop supporting the claim instead of quietly ceasing to.

   **The contrasting case belongs here too, because it is the other half of the same rule.**
   `site/public/favicon.svg` is *also* referenced from `site/astro.config.mjs` — `favicon: '/favicon.svg'`,
   verified — and yet it is **not** `depended-upon`: D5 rules a site-absolute URL path an
   `unresolved-reference` rather than guessing it onto `public/` by way of a framework convention the
   scanner may not assume. It is still an `image` node, reached **by kind alone** under FR-21a with no
   reference resolving to it anywhere. The pair shows the two halves of D2a working together —
   classification is what makes the favicon a node at all, and ordering is what keeps the logo out of the
   wrong stream. It also shows that "is referenced" and "resolves" are different tests, which is why the
   ordering argument is carried by the reference that resolves.
3. **The classification is total and decidable.** Extension membership is a string test on the path;
   a path with no extension, or one whose extension is absent from the list, is not an image. No
   content sniffing, no MIME probing, no judgment — which also keeps the result byte-stable under R12.
4. **A directory artifact is never an image.** The trailing-`/` form is a `source-artifact`
   unconditionally, which is feature-003 D1a's own rule ("a directory is never an image") consumed
   rather than re-derived.
5. **The extension is lower-cased before the membership test**, since `image_extensions:` ships as a
   lowercase list. Stated because the two specs must fold case *identically* or the same file would be
   classified differently at either end: a `LOGO.PNG` classified `image` here and re-checked
   case-sensitively by V13 would be reported as a table defect with no defect in it. No instance exists
   on disk — every image path in this repository carries a lowercase extension (verified 2026-07-29) —
   so this is specified for genericity, the same posture feature-003 takes toward its unverified
   non-ASCII branch. Being unexercised by the repository is exactly why the **fixture tree carries an
   upper-case instance** (`LOGO.PNG`, Layers): a rule with no live case is a rule a test must supply, or
   it is specified and never run. The matching validator-side confirmation is Open Item 6b. **The fold is
   visible in exactly one place in the output, and D1a now says which form appears there**: the `<ext>`
   of D1a's in-repo image evidence template is the **folded** form, not the path's own bytes, so
   `LOGO.PNG` emits `'png'`. Stated in both sections because a fold applied in one and rendered in the
   other is the shape that left the case undecided.

**The granularity collapse yields to the classification, and this is the one case where the two rules
could disagree.** Feature Flow step 6 collapses `canonical/skills/<name>/**` and
`canonical/agents/<name>/**` to a single directory id and suppresses their member files. An image
inside such a directory is **exempt from that suppression** and is still emitted as an `image` node.
Reasons, in order: FR-23's whole-artifact clause is explicitly about **project source** ("a script, a
skill, a template … individual functions, symbols and lines"), and an image is not source; FR-23's own
media clause makes images "nodes in their own right, with their own kinds"; and suppressing them would
make an edge from a document to a depicted image *unrepresentable* whenever the image happened to live
under a collapsed directory, which is a silent loss of exactly the relation class the widened node model
exists to carry. **No such case exists on disk today** (the repository's image files sit under `docs/`
and `site/`, verified 2026-07-29), so this is a forward-looking rule fixed now, while the contract is
being written, rather than discovered later by a project that nests a diagram inside a skill.

**The two streams are disjoint by path**, and that is asserted rather than assumed:
`test-graph-media-nodes.sh` checks that no `int:` `node_id` appears in both `nodes.tsv` and
`media-nodes.tsv`. Without the assertion, a refactor that moved the classification after
qualification would produce a duplicated path and two rows claiming one artifact — and feature-003's V8
(one kind per id) would then fail on the table, one feature away from the cause.

#### D3. What counts as derivable evidence (FR-24 — the highest-risk requirement)

FR-24 requires significance to be **derivable rather than judged**, so that a KB gap arrives with
evidence a reviewer can check. Concretely: `evidence` must be a string a reviewer can paste into `grep`
and see the same thing the scanner saw, and `evidence_provenance` must say whether the project *stated*
it or the scanner *computed* it. Nothing else qualifies a node.

**`declared` evidence — the project itself names the artifact.** Each item below is a real,
present-on-disk carrier. **The third column names the string's *components*; D3b fixes its *bytes*** —
separator, component order and quoting — and D3b is what an implementer builds from, so no reader has to
turn a composition into a format.

| Carrier | What it declares | Evidence components (bytes: D3b) |
|---------|------------------|----------------------|
| `canonical/aid/templates/generated-files.txt` | an output path, and the script named in its `\|`-separated build command | the registry path + the matched output-path token |
| `canonical/aid/templates/shortcut-catalog.yml` | a shortcut skill by name (`module-map.md`: the doorways are emitted from this catalog) | the catalog path + the matched row's `name` |
| `.aid/settings.yml` `knowledge.doc_set` | a KB doc and the agent that authors it | the settings path + the matched `doc_set` entry |
| `canonical/EMISSION-MANIFEST.md` "Asset Kinds" table | the canonical asset roots the renderer emits | the manifest path + the matched table row |
| a KB doc's frontmatter `sources:` list | a path or glob the KB claims to summarise | the KB doc path + the matched `sources:` entry |
| `.github/workflows/*.yml` | a path a CI step invokes | the workflow path + the matched command token |
| `packages/npm/package.json` (`bin`, `files`), `packages/pypi/pyproject.toml` | a published entry point | the manifest path + the matched key |
| `tests/run-all.sh` | the suite glob `tests/canonical/test-*.sh` (`test-landscape.md`, "Glob discovery") | `tests/run-all.sh` + the glob |

**`derived` evidence — the scanner computes it, with no judgment.** Three mechanisms only; the
"Evidence string" sentences below likewise name components, and **D3b fixes their bytes**:

1. **Convention membership.** The path matches a naming convention the project's *own* documented rule
   treats as a unit. Each pattern is quoted from a rule that exists: `canonical/skills/*/SKILL.md` ⇒
   the containing directory is a `skill`; `canonical/agents/*/AGENT.md` ⇒ the containing directory is an
   `agent` (both from `module-map.md` "Where a new skill goes" / "Where a new agent goes");
   `canonical/aid/scripts/<area>/*` ⇒ a `script` (`module-map.md` "Where a new helper script goes");
   `tests/canonical/test-*.sh` ⇒ a `test-suite` (`tests/run-all.sh`'s discovery glob). Evidence string:
   the matched pattern plus the rule's grep-recoverable anchor.
2. **Inbound reference count ≥ 1.** Another *already-enumerated* artifact's bytes contain this
   artifact's repo-relative path, or contain its basename in a resolvable position (D5). Evidence
   string: the citing path plus the matched literal. This is the `depended-upon` clause of FR-21 and the
   only qualifier that depends on other nodes, so it runs in a settling pass (Feature Flow step 9).
3. **Executable-header presence.** The file's first line is a `#!/usr/bin/env {bash,node,python3}`
   shebang, or the file is a `.ps1` carrying `#Requires -Version 5.1`. `coding-standards.md` makes the
   header block and the shebang a project rule, so their presence is a declared intent-to-be-invoked,
   mechanically visible. Evidence string: the path plus the matched shebang/`#Requires` line. This
   yields `entry-point`.

**Which of these carriers writes which `qualifier` value is D3a**, which maps every carrier and
mechanism above to exactly one value and states the precedence between them. This section says *what
qualifies*; D3a says *as what*. Keeping them apart is why the second was missing for three revisions, so
each now points at the other.

**Media nodes carry evidence by the same standard and are outside this section's significance
machinery.** D1a fixes their two evidence forms and their provenance. The point of stating it twice is
that FR-24's *evidence* obligation is universal while its *significance* obligation is, per FR-21a,
scoped to `source-artifact` — so a media node has checkable evidence and no qualifier, which is
coherent rather than a gap.

##### The hard rule — invariant `no-inferred-node` (stated for feature-006 and feature-007 to rely on)

> **`evidence_provenance` is never `inferred`, and a candidate that only a reading would qualify is not
> emitted as a node.** Equivalently, as a property of the output: every row of `nodes.tsv` **and of
> `media-nodes.tsv`** carries `evidence_provenance ∈ {declared, derived}`, and the field has no third
> value. Such a candidate is written to `candidates.tsv` with a `drop_reason`, where feature-005's pass
> 2 may use it to *type an edge between nodes that already exist*, and may never promote it to a node.

This is the mechanical form of FR-24's second sentence ("The skill must not manufacture defects from
`inferred` opinion alone"). It is deliberately stated as an invariant of the *node set*, not as a
property of a downstream view, because that is where it can actually be enforced. It is stated over
**both** streams this revision, because a media node is a node and an invariant with a hole in it is not
one.

**Three consequences, so downstream features can rely on it rather than re-deriving it:**

1. **feature-006 needs no gap-predicate filter for this case.** A predicate of the form "drop `int:`
   nodes whose sole qualification is `inferred`" is **vacuous** over this node set — the set it would
   filter cannot contain such a node. The filter should be dropped, not reimplemented: it is not merely
   hard to express in the view layer, there is nothing for it to remove.
2. **feature-007's node record needs no qualification-provenance field for this purpose.** Its absence
   is correct rather than an omission. (Whether feature-007 carries `artifact_class` or `qualifier` for
   display or grouping is its own call; nothing in FR-24 requires it to.)
3. **FR-24 is discharged once, at enumeration time**, instead of being re-checked at each consumer.
   Every KB gap feature-006 reports therefore inherits checkable provenance by construction: it names a
   node, and every node carries a `grep`-recoverable `evidence` string plus a `declared`/`derived` stamp.

**How it is enforced** — an invariant other features are told to trust must be mechanically held, not
merely asserted:

- **One emission path per stream.** `scan-source.sh` writes each node stream through a single writer
  function. That function rejects any row whose `evidence_provenance` is not `declared` or `derived` and
  exits non-zero: such a row would be a scanner bug, not a data condition, so it must abort rather than
  be filtered. The same writer asserts that no emitted `int:` `node_id` contains a `#` (R9), that no
  emitted path matches an exclusion predicate (R1), and — added this revision with D3b — that **no
  emitted field contains a tab**, which is what makes D3b's one forced normalisation unbypassable rather
  than merely instructed. Four assertions at the one choke point rather than four scattered guards.
- **No promotion path exists.** `candidates.tsv` is the only channel from the rules to the agent pass
  (D6), and it is write-only from the scanner's side; nothing reads a candidate back into a node set.
- **Test.** `tests/canonical/test-graph-node-provenance.sh` asserts, on the fixture tree and on this
  repository, that the `evidence_provenance` field of every row of **both** node streams is `declared`
  or `derived`, and that no `candidates.tsv` row with `candidate_kind` = `node` has a `subject`
  appearing as a `node_id` in either stream. The scoping to `node` candidates matters: an **edge**
  candidate's subject legitimately involves enumerated nodes — an unresolvable *reference* between two
  real artifacts is exactly what `unresolved-reference` records — so asserting over all candidates would
  fail on correct output.
- **Downstream half.** Feature-005's pass 2 carries a closed-node-set bound — both endpoints of an
  inferred edge must already exist in this feature's streams or in the KB-side node set, enforced by the
  merge and not by the prompt. FR-31a part 2 states the same bound at the requirements level. So the one
  non-deterministic stage in the pipeline cannot reintroduce an inferred node either.

**Scope, stated precisely so the invariant is not over-read.** It binds *nodes*. **Edges** may of
course be `inferred` — that is what pass 2 produces, and feature-003's `Provenance` enum has the value
for exactly that reason. An `inferred` *row* between two `declared`/`derived` *nodes* is normal and
expected; feature-003 D3 makes the same point from the row side.

#### D3b. The evidence string templates — one per carrier, fixed to the byte (FR-24, FR-32, AC-S8)

**Why this section exists, and why it sits between D3 and D3a.** D3 above fixes each `source-artifact`
evidence string only as a *composition* — "the KB doc path + the matched `sources:` entry", "the citing
path plus the matched literal" — with no separator, no component order and no quoting. D1a, by
contrast, fixes its two media forms **byte-exactly**. So field 5 of `nodes.tsv` was still not a pure
function of disk state across two conforming implementations: each would invent a format, and both
would satisfy D3. That matters three times over. D1 calls the field a pure function of disk state and
FR-32/AC-S8 rest on byte-identity; D3a's selection rule below orders "the bytes that would be written
to `nodes.tsv` field 5", and a set of byte strings cannot be constructed from a composition; and the
candidate-set enumerator the Layers table requires cannot be written from a SPEC that never says what a
candidate *is*. This SPEC's own standard applies to itself here: "a rule stated without a decision
procedure is treated here as undelivered." **D3b precedes D3a because D3a's rule orders D3b's output**;
D3 says what qualifies, D3b says in what bytes, D3a says as what value and which byte string wins.

##### The two shapes, both taken from D1a

> **Shape A** — the matched token *is* the literal a reviewer greps in the carrier:
> `<subject> -- <carrier phrase> (search: "<token>" in <carrier path>)`
>
> **Shape B** — the thing the scanner matched is *not* the thing a reviewer greps:
> `<subject> -- <carrier phrase> '<matched>' (search: "<anchor>" in <carrier path>)`

Shape B is D1a's in-repo image form with the file made explicit — that form already separates the
matched value (`'<ext>'`) from the greppable key (`(search: "image_extensions")`) for exactly this
reason. Shape A is D1a's external form with a subject and a phrase in front of it. **No third shape is
introduced**, and the separators are literal: one space, two hyphens, one space for ` -- `; then
` (search: "`, the token, `" in `, the carrier path, `)`.

**Component definitions, so no component is left to a reading:**

- **`<subject>`** — the candidate node's `node_id` **minus its `int:` prefix**: the repo-relative path,
  carrying the trailing `/` for a directory artifact (D1 field 1). For template 13, whose subject is an
  observation's `to_id`, the same rule applies to that id: an `int:` prefix is stripped, and any other
  id — a registered `ext:` key, or the one KB-side target D5's `dependency` kind reaches — is carried
  **verbatim, prefix included**, since there is no path there to strip and the prefix is what identifies
  it.
- **`<carrier phrase>`** — the fixed lowercase phrase given in the table below. It is one per carrier
  arm, and in Shape B the quoted `'<matched>'` completes the identification (rows 11 and 12 share the
  phrase `convention` and are told apart by the pattern), so the arm that produced a string is always
  recoverable from the string.
- **`<token>` / `<matched>` / `<anchor>`** — §Token formation below.
- **`<carrier path>`** — the repo-relative path of the file that carries the match.

**`<subject>` leads every template, and that placement is load-bearing rather than stylistic.** It is
the **same bytes for every candidate string of one node**, so the order D3a imposes is never decided by
it; the first component that can differ is the phrase, and after it the **token** — which is a property
of the *match*, not of the traversal. The carrier path comes last. That is what lets the
`LC_ALL=C`-least candidate be one a sorted-path traversal reaches second, which the composition-only
description made impossible (D3a §Why the discriminating fixture is now constructible).

##### The templates — one row per emitting arm of D3a's carrier map

| # | D3 carrier or mechanism | Clause | `evidence` template, byte for byte | `<token>` / `<matched>` + `<anchor>` — the exact bytes |
|---|---|---|---|---|
| 1 | `generated-files.txt` — the script in the `\|`-separated build command | Q1 | `<subject> -- build-command script (search: "<token>" in <carrier path>)` | the script path **as written** in the build command |
| 2 | `generated-files.txt` — the matched output-path token | Q2 | `<subject> -- registered output path (search: "<token>" in <carrier path>)` | the output-path field **as written**, i.e. the text left of the first `\|` |
| 3 | `shortcut-catalog.yml` row | Q2 | `<subject> -- shortcut catalog row (search: "<token>" in <carrier path>)` | the row's `name` value |
| 4 | `.aid/settings.yml` `knowledge.doc_set` — the **agent** arm | Q2 | `<subject> -- doc_set agent (search: "<token>" in <carrier path>)` | the agent name **as written** in the matched `doc_set` entry |
| 5 | `canonical/EMISSION-MANIFEST.md` "Asset Kinds" row | Q2 | `<subject> -- asset-kind root (search: "<token>" in <carrier path>)` | the asset root **as written** in the row's path cell — the cell, never the whole row |
| 6 | a KB doc's frontmatter `sources:` entry | Q3 | `<subject> -- frontmatter sources: entry (search: "<token>" in <carrier path>)` | the list entry's scalar, path or glob, **as written** |
| 7 | `.github/workflows/*.yml` command token | Q1 | `<subject> -- workflow command token (search: "<token>" in <carrier path>)` | the path token **as written** in the step's command |
| 8 | `package.json` `bin` / `pyproject.toml` entry point | Q1 | `<subject> -- published entry point (search: "<token>" in <carrier path>)` | the matched key **as written** |
| 9 | `package.json` `files` | Q2 | `<subject> -- published payload (search: "<token>" in <carrier path>)` | the matched `files` list entry **as written** |
| 10 | `tests/run-all.sh` discovery glob | Q3 | `<subject> -- suite discovery glob (search: "<token>" in <carrier path>)` | the glob **as written** — `tests/canonical/test-*.sh` here, present verbatim in `tests/run-all.sh` at lines 7, 112, 117 and 125 (read 2026-07-29) |
| 11 | convention membership — `canonical/skills/*/SKILL.md`, `canonical/agents/*/AGENT.md` | Q2 | **Shape B**: `<subject> -- convention '<matched>' (search: "<anchor>" in <carrier path>)` | `<matched>` = D3's pattern; `<anchor>` = the rule's own heading text, `Where a new skill goes` / `Where a new agent goes`; `<carrier path>` = the document stating the rule, `.aid/knowledge/module-map.md` here |
| 12 | convention membership — `canonical/aid/scripts/<area>/*`, `tests/canonical/test-*.sh` | Q3 | **Shape B**, as row 11 | `<matched>` = D3's pattern; `<anchor>` = `Where a new helper script goes` in `.aid/knowledge/module-map.md`, and for the test convention the glob `tests/canonical/test-*.sh` in `tests/run-all.sh` — where `<matched>` and `<anchor>` coincide, since that pattern *is* in the runner verbatim; the same benign repetition as template 14 |
| 13 | inbound reference count ≥ 1 | Q4, and the P3 → P2 promotion | `<subject> -- inbound reference (search: "<token>" in <carrier path>)` | `<token>` = the referencing literal **as written in the citing file's bytes** — the full path, the bare basename or the un-normalised relative reference, whichever matched (D5), never the resolved path; `<carrier path>` = the citing node's path |
| 14 | executable-header presence | Q1 | `<subject> -- executable header (search: "<token>" in <carrier path>)` | `<token>` = the matched shebang or `#Requires` line, terminator removed; `<carrier path>` = `<subject>` |
| — | `.aid/settings.yml` `knowledge.doc_set` — the **KB-doc** arm | *(none)* | *(no template — it qualifies nothing in this stream; D3a's map)* | — |

**Template 14's two path components coincide, and that is stated rather than special-cased.** The
executable header's carrier *is* the artifact, so `<carrier path>` repeats `<subject>`. A conditional
component would give the template two forms and put the byte question straight back; a repeated one
costs a few bytes and keeps one form. The arm is single-valued anyway — a file has one first line — so
it never enters a multi-candidate set.

**Why rows 11 and 12 need Shape B, verified rather than assumed.** Read on disk 2026-07-29:
`tests/run-all.sh` carries the string `tests/canonical/test-*.sh` verbatim, so the tests-glob carrier is
Shape A. But `.aid/knowledge/module-map.md` states its three conventions in prose that does **not**
contain D3's patterns verbatim — its text is `canonical/skills/aid-<name>/SKILL.md` (line 235),
`canonical/agents/aid-<role>/AGENT.md` (242) and `canonical/aid/scripts/<area>/` (247). A Shape-A
template here would print a search token that is absent from the file it names, breaking exactly the
paste-and-see property FR-24 asks for. Shape B prints the pattern the scanner matched **and** an anchor
that is in the document.

##### Token formation — what "as written" means, byte for byte

This is the layer below the template, and it is closed here rather than left as the next round's
finding: a template whose components are described but not delimited is a composition again.

> **A token is a scalar, never a line.** `<token>`, `<matched>` and `<anchor>` are the value the
> carrier's **own syntax** yields for the match: a YAML list entry contributes its scalar with the
> `- ` marker and any surrounding `'` or `"` removed; a Markdown table cell contributes its content
> with the surrounding `|`, its padding and any inline-code backticks removed; a shell command
> contributes the matched word. Leading and trailing spaces and tabs are stripped. Any line terminator
> — `\n`, and a `\r` immediately before it — is removed. A token never carries a trailing comment and
> never carries the carrier's own punctuation.

> **One forced normalisation, and exactly one.** These streams are TSV, so no field may contain a tab.
> A tab **inside** a token is replaced by a single space as the string is formed. This is forced by the
> container format, not a preference — the alternative is an unparseable row — and the single-writer
> tab assertion (D3) makes a leak abort rather than corrupt a stream. No token on this repository
> contains a tab; the rule exists so that a project whose paths do is specified rather than surprising.

> **No escaping is performed, and none is needed.** The `'` and `"` in the templates are delimiters for
> a human reader; field 5 is never re-parsed by anything — feature-006 displays it and feature-007 does
> not read it — so a token that itself contains a quote is emitted as-is and the string stays a total
> function of disk state, which is the only property the field is required to have.

**Where the recursion stops, stated because this is the fourth consecutive round in which fixing one
layer exposed the next.** Every component of every template above is now one of exactly two things: a
**literal fixed in this SPEC** (the phrases, the separators, the `search:` frame), or a **byte range
read from a named file under a stated trim rule** (the tokens, the anchors, the paths). There is no
third kind, and disk bytes are the *input* to the enumeration rather than a choice this SPEC can make —
so there is nothing under this layer left to under-specify. That is the argument, not a promise; the
check is that `evidence` is now computable from `git ls-files` plus the bytes of the named carriers,
with no implementer decision at any point.

**What this closes.** D1's "pure function of disk state" and field 5's "one string, chosen totally" are
now true across two conforming implementations rather than only within one; the Layers candidate-set
enumerator is writable from this SPEC; the fixture's ordering requirement is computable, and computable
in a way that can *distinguish* least-string from first-reached (D3a); and the golden expected values
that make the validator independent of the enumerator can be written down at all. No carrier is added,
no carrier is removed, and no `qualifier` changes: D3b is a formatting contract over the set D3 already
fixed.

#### D3a. The `qualifier` assignment — one rule per value, a total carrier map, a stated precedence (FR-21, FR-24, R7a)

**Why this section exists, stated plainly because the omission it repairs cost a gate.** D3 above states
*which mechanisms qualify a node*; D1 field 4 states *which values the field may hold*. Until this
revision **nothing stated which mechanism writes which value** — so `public-surface` and `named-unit`
appeared exactly once each in this SPEC, in the value-space cell that declares them, and no rule could
produce either. That is not a cosmetic gap: feature-006's gap severity is a total function of this field,
so half its severity domain was unreachable and a reviewer reading feature-006 would expect ledger rows
this enumerator could not produce. The two specs were individually coherent and jointly wrong. This
section is the missing map, and it is written as **one rule per value** so that "exactly one assigning
rule" is a visible property rather than something a reader reconstructs.

**The value space is a refinement of FR-21's clauses, not a bijection with them.** FR-21 has three
clauses; this field has four values, and the field's description no longer claims a one-to-one
correspondence, because none exists. The fourth value is not a fourth clause — **FR-21's first clause is
itself disjunctive** ("an entry point **or** public surface") and its own examples name both roles: "a
skill, a CLI command, a template, or a script another script invokes" mixes things this project
*executes* with things it *exposes*. The field therefore records which clause qualified the node, at the
granularity clause 1 itself distinguishes:

| FR-21 clause | Values | Reading |
|---|---|---|
| 1 — an entry point **or** public surface | `entry-point`, `public-surface` | split on the line the clause's own examples already draw: **executed** by this project versus **exposed** to a consumer |
| 2 — depended upon by another source artifact | `depended-upon` | one value; the clause is not disjunctive |
| 3 — a named unit the project's own conventions treat as a unit | `named-unit` | one value; the clause is not disjunctive |

**"One value" is a claim about the value space, not a claim that every example FR-21 gives has a
carrier here.** Clause 3's examples are "a test suite, a manifest, a settings schema", and Q3 below
carries the test-suite convention plus the two general ones (`sources:` frontmatter, the script/test
naming conventions). It carries no convention that names *a settings schema* or *a manifest* as such —
because FR-24 admits only carriers that are **derivable from something the project states**, and clause
3's qualifying phrase is "the project's **own** conventions". An example naming a *kind of unit* is not
itself a convention; a project that supplies one qualifies them through the carrier it supplied, and a
project that supplies none leaves the path a candidate. **This repository supplies one for all three
of clause 3's named kinds**, which is why none of them is a live gap here: the manifests through
`.aid/knowledge/integration-map.md`'s `sources:` list, and the settings schema through the
`sources:` lists of `.aid/knowledge/pipeline-contracts.md`, `.aid/knowledge/quality-gates.md` and
`.aid/knowledge/README.md` — all read on disk 2026-07-29. Naming only the manifests here would have
implied the settings schema had no carrier on this repository, which is the same wrong premise D4's
allow-list subsection carried. That is FR-8a's
degrade-gracefully behaviour, and Feature Flow step 11 already states what becomes of such a path — a
`candidates.tsv` row with `no-rule-match`, counted in D7's dropped contribution. D4's §"When an
allow-listed path does not qualify" says the same for the one case where the path was explicitly
named by an allowlist and a reader might expect otherwise.

**The split is severity-neutral, which bounds the one fiat in this section.** `entry-point` and
`public-surface` are the same clause and carry the **same** severity in every consumer that reads this
field today — feature-006 is the only one (feature-007 reads ids), both `[HIGH]`, verified 2026-07-29 —
so a carrier placed on the wrong side of the executed/exposed line changes the *description* of why a
node is a node and cannot change a ledger row's severity. That is why the split is safe to draw at all;
a distinction with a severity consequence would need requirements-level authority this SPEC does not
have. **This is an observation about the current consumer set, not a law**, which is why the
monotonicity guarantee below carries it as an explicit hypothesis instead of leaning on it silently.

**Collapsing the value space was the alternative, and it is rejected on the merits.** The rules do
produce clause-1 and clause-3 candidates — the map below draws every one of them from carriers D3
already specifies, and **no mechanism is added by this section**. What was missing was the mapping, not
the mechanisms, so collapsing would delete reachable values rather than unreachable ones. It would also
destroy feature-006's `[HIGH]` and `[LOW]` sources and reopen it for a defect this SPEC would have
created — which is a worse outcome than the reopen that produced this revision, not a cheaper one. (Cost
is not the argument: Q18 ruling 3 rules out cost as a defence. The argument is that the collapse leaves a
defect somewhere, and the refinement leaves none.)

##### The four assigning rules

| # | Value | Rule — the disjunction of its carriers, each named in D3 | Precedence | Evaluated at |
|---|---|---|---|---|
| Q1 | `entry-point` | **any of**: an executable header (D3 derived 3); a `.github/workflows/*.yml` command token; the script named in a `generated-files.txt` build command; a `package.json` `bin` entry or a `pyproject.toml` entry point | **P1** | step 8, position 1 — final on match |
| Q2 | `public-surface` | **any of**: a `shortcut-catalog.yml` row; an `EMISSION-MANIFEST.md` "Asset Kinds" root (the carrier that qualifies a **template**, clause 1's third example); a `generated-files.txt` output path; a `package.json` `files` entry; `knowledge.doc_set`'s **agent** arm; convention membership of `canonical/skills/*/` or `canonical/agents/*/` | **P1** | step 8, position 2 — final on match |
| Q3 | `named-unit` | **any of**: a KB document's frontmatter `sources:` entry; `tests/run-all.sh`'s discovery glob; convention membership of `canonical/aid/scripts/<area>/*` or `tests/canonical/test-*.sh` | **P3** | step 8, position 3 — **provisional**; finalised at step 11 |
| Q4 | `depended-upon` | inbound reference count ≥ 1 (D3 derived 2, resolved by D5) | **P2** | step 9, the settling pass — final, and **promotes** a provisional Q3 |

##### The carrier → value map, total over D3

Every carrier and mechanism D3 names appears exactly once below, and maps to exactly one value. The map
is stated as its own table because writing it is what makes an unassignable carrier visible — and it
found one.

| D3 carrier or mechanism | Value | Why that clause |
|---|---|---|
| `generated-files.txt` — the script in the `\|`-separated build command | `entry-point` | the registry names a script the build **invokes** — clause 1's "a script another script invokes" |
| `generated-files.txt` — the matched output-path token | `public-surface` | the registry names an artifact the tool **emits**; enumerability of that path is D4 Class 1's question, not this map's |
| `shortcut-catalog.yml` row | `public-surface` | the doorway is the surface a shortcut skill is reached **through** (`module-map.md`: the doorways are emitted from this catalog) |
| `.aid/settings.yml` `knowledge.doc_set` — the **agent** arm | `public-surface` | the project addresses that agent **by name** as the authority for a KB doc |
| `.aid/settings.yml` `knowledge.doc_set` — the **KB-doc** arm | *(none — cannot qualify anything here)* | its target is a KB document, which D4 Class 4 excludes from this stream. The fact is not lost: it survives as D5's one `dependency` observation that crosses to the KB side. **Found by writing this map**, and stated rather than left to be re-discovered |
| `canonical/EMISSION-MANIFEST.md` "Asset Kinds" row | `public-surface` | a canonical asset root is what the renderer **emits** to a target project |
| a KB doc's frontmatter `sources:` entry | `named-unit` | the `sources:` convention **names** the path as a unit the KB summarises — neither an invocation nor an exposure, which is clause 3 exactly |
| `.github/workflows/*.yml` command token | `entry-point` | a CI step **invokes** the path |
| `packages/npm/package.json` `bin`, `packages/pypi/pyproject.toml` entry points | `entry-point` | a **published executable** |
| `packages/npm/package.json` `files` | `public-surface` | a published **payload** — exposed to the consumer, not executed here |
| `tests/run-all.sh` discovery glob | `named-unit` | clause 3's own example, "a test suite" |
| convention membership — `canonical/skills/*/SKILL.md`, `canonical/agents/*/AGENT.md` | `public-surface` | clause 1's first example, "a skill"; the agent directory is the same shape (`module-map.md`) |
| convention membership — `canonical/aid/scripts/<area>/*`, `tests/canonical/test-*.sh` | `named-unit` | the convention treats the path as a unit and evidences neither invocation nor exposure |
| inbound reference count ≥ 1 | `depended-upon` | clause 2, verbatim |
| executable-header presence | `entry-point` | already stated in D3 ("This yields `entry-point`") — the one mapping the old text carried, and the reason `entry-point` was the only value with an assigning rule |

##### Precedence, and why it is stated in this SPEC's own terms

> **P1 > P2 > P3**, and the emitted `qualifier` is the **strongest applicable** clause — the maximum over
> every clause the node satisfies, never the first clause the flow happens to test.

The order is intrinsic to what the clauses claim, and is deliberately **not** borrowed from any
consumer's severity ladder:

- **P1 — the project itself declares the artifact as a surface, or executes it.** The strongest claim
  available, because the project makes it about the artifact directly.
- **P2 — another enumerated artifact needs it.** A claim made about it by a third party; still a use.
- **P3 — only a naming convention treats it as a unit.** No declaration, no use: a pattern match. That is
  why it is the residual clause, and why it is the weakest.

**Within P1 the tie-break is Q1 before Q2**, and it is severity-neutral (above), so it settles a
description and never a severity. A node satisfying carriers on both sides is an `entry-point`, because
being executed is the more specific observation.

**Two orderings run in step 8, and exactly one of them decides the value.** They are separated here
because two texts in this SPEC previously read differently on one real input shape — a path carrying a
*declared* Q2 carrier whose only Q1 carrier is the *derived* executable header — leaving a field that is
specified as a pure function of disk state undetermined for that shape:

> **The clause order Q1 → Q2 → Q3 decides the `qualifier`.** The `declared`-before-`derived` order runs
> **inside the matched clause only**, over that clause's own carrier disjunction, and decides the
> `evidence` / `evidence_provenance` pair. It never decides the clause, and it is never consulted across
> two clauses — not even two at the same precedence level.

So the shape above emits **`entry-point`**, with the shebang line as `evidence` and `derived` as
`evidence_provenance`, because evidence must support the clause it is offered for (below) and the clause
is Q1. The Q2 carrier is recorded nowhere: a node carries one qualifier and one evidence string. The
ordering is meaningful *within* Q1 in its own right — Q1's disjunction holds declared carriers (the
workflow command token, the `generated-files.txt` build-command script, the `package.json` `bin` /
`pyproject.toml` entry points) alongside the derived header — which is the job it was written for.

**The other reading — `declared` before `derived` across Q1 and Q2, which would emit `public-surface`
here — is rejected on the merits, and cost is not among them (Q18 ruling 3):**

1. **It contradicts the rule the whole section rests on.** The emitted value is the **strongest
   applicable clause**. Evidence provenance is not a clause and carries no precedence; letting it
   select between clauses replaces a maximum over clauses with a maximum over something else.
2. **It makes the value depend on the wrong variable.** The same shebang-carrying path would be
   `entry-point` on its own and `public-surface` the moment an unrelated catalog row names it — so
   field 4 would record *how the scanner learned of the path* rather than *what role the path plays*,
   which is the opposite of what D1 field 4 says it records, and it would break the locality every
   other clause has.
3. **Nothing in this SPEC prefers `declared` for its own sake.** AC-S4 accepts either provenance and
   D3 makes both legal; the preference exists only to hand a reviewer the strongest checkable string
   **for a clause already chosen**. Promoting it to a clause-selector gives it authority it was never
   granted — and would be inconsistent with the P3 → P2 promotion, which already lets a `derived`
   evidence string carry a stronger clause than a `declared` one.

The rejected reading is severity-neutral for today's consumers (both P1 values → `[HIGH]`), so this is
a determinacy fix, not a severity fix. That is precisely why it had to be fixed rather than tolerated:
a field specified as a pure function of disk state is undelivered while two of its own rules disagree
(this SPEC's own standard under FR-24: "a rule stated without a decision procedure is treated here as
undelivered"), and severity
neutrality is a property of the consumer set today, not of the rule.

##### The evidence selection rule — total where the carrier order stops being decisive

The clause order fixes the `qualifier`; the `declared`-before-`derived` order fixes the **provenance
class**. Neither picks a *string*, and there are two places where more than one is admissible: a
clause whose chosen provenance class holds **two or more matching carriers** (step 8), and a node
reached by **two or more resolved inbound references** (step 9 — Q4 and the promotion). Both are
ordinary rather than exotic. `.aid/settings.yml` matches Q3's `sources:` carrier once per depth-1 KB
document whose frontmatter names it — `.aid/knowledge/pipeline-contracts.md`,
`.aid/knowledge/quality-gates.md` and `.aid/knowledge/README.md`, each read on disk 2026-07-29 — and
`canonical/EMISSION-MANIFEST.md` matches the same carrier in a **different, and disjoint, set** of
depth-1 KB documents: `architecture.md`, `artifact-schemas.md`, `authoring-conventions.md`,
`decisions.md`, `domain-glossary.md`, `module-map.md` and `tech-debt.md` by the literal path, and
`architecture.md`, `domain-glossary.md`, `module-map.md` and `project-structure.md` again by the
`canonical/` glob entry — all read on disk 2026-07-29 from a full parse of the 21 `.aid/knowledge/*.md`
frontmatter `sources:` blocks. **The set is named, and no relation between the two is claimed beyond
the one that holds**: neither contains the other, so "larger" would be a statement about counts wearing
the clothes of a statement about sets — the substitution Q17 forbids, and the one D3a's §Reachability
subsection below invokes by name. The `EMISSION-MANIFEST.md` case is also the live instance of the
shape the fixture reproduces — **one node matched by the same carrier under two different tokens**, the
literal path and the `canonical/` glob. On the Q4 side, that path's citer set is every enumerated
artifact whose bytes contain the literal `.aid/settings.yml`; a complete scan of `canonical/`
(2026-07-29) finds the literal in many files there, and more than one of them is itself enumerated by
Q1's executable header — `canonical/aid/scripts/config/read-setting.sh` line 46 and
`canonical/aid/scripts/kb/closure-check.sh`, both `#!/usr/bin/env bash` on line 1 — so the set has more
than one member on this repository, not one. Leaving the pick unstated would put a **required**
field that D1 specifies as a pure function of disk state back exactly where §Precedence has just
taken the `qualifier` from — two conforming implementations emitting different bytes for the same
input, separated only by iteration order.

> **The emitted `evidence` is the `LC_ALL=C`-least member of the set of admissible evidence strings
> for the matched clause and the chosen provenance class**, and `evidence_provenance` is that class.
> At step 8 the set is the strings produced by that clause's matching carriers of that class, each
> formed exactly as **D3b** specifies, byte for byte; at step 9 it is the evidence strings of the
> node's resolved inbound observations **as they stand at the fixed point** — not as they stood in the
> round the node first qualified.

**What the order is over, stated precisely, because it is the whole of the rule.** It is over the
**fully-formed evidence string** — the bytes that would be written to `nodes.tsv` field 5, as D3b's
per-carrier template forms them — and not over the carrier, the citing path, the declaration site or
any assigned rank. Ordering the emitted value itself is what makes the rule decide the row directly,
rather than decide an intermediate that still has to be projected onto one. **The set is constructible
because D3b exists**: before it, the order ranged over strings no two implementations would agree on,
so a rule that reads as total was in fact defined over a domain the reader had to invent.

**The step-9 set has a time index, and it is the fixed point.** Step 9 iterates, and the qualified set
only grows — which means a node's set of *resolved inbound observations* grows with it: a node that
qualifies in round *k* can acquire further citers in round *k+1*, when a citer of its own qualifies.
Without a stated round, latch-at-first-qualification and recompute-at-the-end both conform to the
sentence above and emit different bytes for the same tree. **The set is frozen once, after the
iteration terminates.** Step 9's rounds decide only *which* paths qualify and *under which clause*; the
`evidence` and `evidence_provenance` for every step-9 qualification — Q4's own and the P3 → P2
promotion's alike — are computed in a single pass **after the last round**, over the completed
`observations.tsv`, and nothing written before that pass is authoritative. Latching is rejected on the
ground the fixed point exists for: a latched value depends on the round a node happened to qualify in,
which is exactly the traversal dependence the promotion section ("the outcome is independent of
traversal order") and Feature Flow step 9 ("fixed-point iteration is what makes the result independent
of traversal order and therefore reproducible") both claim to have removed. The fixed-point set depends
only on the final observation stream, which is itself order-independent. One property comes free and is
worth naming: because the set only grows, the least member can only fall across rounds, so the emitted
string is the minimum over the whole run rather than over a prefix of it.

**Why it is total, not merely usually decisive.** The domain is a *set* of byte strings and `LC_ALL=C`
is a strict total order on distinct byte strings, so the set has exactly one least member. Two
carriers that would produce the *same* string are the same member, and the emitted row is
byte-identical whichever produced it — so there is no input the order fails to decide, and no
secondary tie-break to specify or forget. The set is non-empty because the clause matched: a clause
qualifies only through a carrier, and a carrier that matched produces its evidence string. This is
deliberately the same shape feature-003 used for both of its orders — **a single-component sort made
total by a uniqueness rule** — with the uniqueness structural here rather than a separate clause,
because the ordered component *is* the emitted field.

**Collation.** `LC_ALL=C`, this work's precedent: `build-project-index.sh` line 185 (`| LC_ALL=C
sort`) and `kb-freshness-check.sh` line 460 (`LC_ALL=C find … | LC_ALL=C sort`) — and deliberately
**not** `build-kb-index.sh` line 471's bare `| sort`, which is locale-dependent. It is also the
collation this feature already applies to every stream it writes (step 12), so no second collation
enters the scanner.

**The tie-break carries no meaning, and that is deliberate.** Nothing in this SPEC ranks one
`declared` carrier above another, or one citer above another; the single evidence ranking it does
state — `declared` over `derived` — has already been consumed by the provenance class. Inventing a
further rank ("prefer the shallowest citing path", "prefer the carrier declared first") would be a
fiat with no project-side convention behind it, which is the ground on which D4 below refuses to
invent a carrier for `.aid/settings.yml`. Byte order is arbitrary *and* total; FR-32 needs the second
property and is indifferent to the first.

**Nothing is discarded by the choice.** `evidence` is one durable anchor for a reviewer, not the
citation set. Every resolved inbound reference is already its own row of `observations.tsv` (D5), so a
node cited many times keeps every citation in the stream feature-005 consumes; what the rule removes
is only the arbitrariness of which one the node record — and therefore feature-006's ledger
`Evidence` column — shows.

**How a validator checks this — a golden value first, then two recomputed clauses, and each is honest
about what it decides.**

The recomputed pair comes first in the telling because it was over-claimed. `significance-rules.sh`
exposes a **candidate-set enumerator** — all admissible evidence strings for a node under a given
clause and provenance class — as a function separate from the selector the scanner calls, for the
reason feature-003 separates `rel_coverage_extra_keys` from its emitter. `test-source-enumeration.sh`
asserts, per emitted row, that the row's `evidence` **(1)** is a **member** of the recomputed set for
that row's clause and class, and **(2)** has **no member sorting before it** under `LC_ALL=C`. That
pair is a decision procedure for the **selector, given the enumerator** — it fails a selector that
bypasses the enumerator, sorts under the wrong collation, or returns a string from the wrong clause.
It is **not** a check on the rule, and the separation of the two functions is structural rather than
evidential: **both sides read the same enumerator**, so for the natural selector — enumerate,
`LC_ALL=C sort`, take the first — both clauses hold by construction on every row, and an enumerator
that **omits an admissible carrier** is invisible to the scanner and the test identically. What the
pair decides is "the least element of *the enumerator's* set", not "the least element of *the rule's*
set". The same limitation applies to the feature-003 precedent it is modelled on, and it is recorded
here rather than left as an implied guarantee.

So the fixture supplies one assertion that does **not** depend on the enumerator at all: a **golden
expected value**. `tests/canonical/fixtures/graph/expected-evidence.tsv` — deliberately a **sibling of**
`tree/` and never inside it, so the golden file is not itself a path the scanner enumerates and cannot
perturb the tree it describes — carries `node_id`, `stream` and the **exact expected `evidence` bytes**,
written out by hand from D3b's templates rather than computed by any part of the scanner. It covers
every multi-candidate fixture node and one single-candidate node per D3b template.
`test-source-enumeration.sh` compares the emitted field 5 to that literal, byte for byte. This is
independent **by construction** — the expected side comes from the SPEC, the emitted side from the code
— and it is precisely the clause that catches a missing carrier: drop `bin/two.sh`'s citation from the
enumerator and membership and minimality both still pass on `bin/one.sh`'s string, while the golden
comparison fails on the node. It is also what makes D3b testable at all, since a formatting contract has
no other check than a literal. **Writing the golden file is possible only because D3b fixed the bytes**;
under the composition-only description its cells could not have been written.

Both recomputed clauses remain vacuous on a single-candidate row, which is why AC-S9 and the fixture
tree carry **multi-candidate** rows for both cases rather than relying on the single-carrier fixtures the
other clauses use — and the golden value is asserted on those same rows, so the three checks fail
independently rather than together.

**Why the discriminating fixture is now constructible, and what makes it discriminate.** The fixture is
required to order its two candidates so that the `LC_ALL=C`-least is **not** the one a first-match
traversal reaches. Under the composition-only description that property was **unobtainable**: every
candidate string led with the carrier's own path — the KB doc path, the citing path — while step 4 sorts
the candidate set `LC_ALL=C` and step 12 writes every stream `LC_ALL=C`-sorted, so the natural
implementation walks carriers and citers in sorted-path order and least-string and first-reached
coincide for *any* arrangement of two fixture documents. Re-ordering fixture files could not fix it,
because the two orders were the same order. **D3b removes the coincidence by construction**: every
template leads with `<subject>` — identical bytes for every candidate of one node — and places the
matched **token** ahead of the carrier path, so the order is decided by a property of the match rather
than by the key a traversal iterates on. The fixture then only has to make its two candidates differ at
the token. Both prescribed cases, with the bytes:

| Fixture case | The two candidate strings, in sorted-path traversal order | `LC_ALL=C`-least, and where it sorts |
|---|---|---|
| **Two `declared` carriers inside one clause (Q3).** `lib/shared.sh` is named by two fixture KB documents: `.aid/knowledge/alpha.md` by the **literal path**, `.aid/knowledge/beta.md` by the **glob** `lib/` | `lib/shared.sh -- frontmatter sources: entry (search: "lib/shared.sh" in .aid/knowledge/alpha.md)`, then `lib/shared.sh -- frontmatter sources: entry (search: "lib/" in .aid/knowledge/beta.md)` | the **second**. The strings agree through `… (search: "lib/` and then differ at `s` (0x73) against `"` (0x22), so `beta.md`'s string is least while `alpha.md` is what a sorted-path walk reaches first |
| **Two citers (Q4).** `lib/cited.sh` is referenced by `bin/one.sh` using the **full path** and by `bin/two.sh` using the **bare basename**, which D5 resolves because the basename is unique in the tree | `lib/cited.sh -- inbound reference (search: "lib/cited.sh" in bin/one.sh)`, then `lib/cited.sh -- inbound reference (search: "cited.sh" in bin/two.sh)` | the **second**. The strings agree through `… (search: "` and then differ at `l` (0x6C) against `c` (0x63), so `bin/two.sh`'s string is least while `bin/one.sh` is reached first |

Neither case turns on which file the fixture author names first: the discriminating bytes are the
**token**, and the token is fixed by what each carrier wrote. Both fixture subjects are chosen so the
case survives to the emitted row — `lib/shared.sh` receives no inbound reference, so its Q3 evidence is
not replaced by the promotion (and the two KB documents are cut by D4 Class 4, so they are carriers and
never citers), while `lib/cited.sh` carries no Q1/Q2/Q3 carrier, so it is a held path that Q4 qualifies
at step 9.

##### Severity-monotonicity — the direct answer

> **Yes, this SPEC's assignment is severity-monotone — by construction, and it was not before.**

- **The property, quantified over exactly the functions it holds for.** For any severity function that
  is **(a) monotone in P1 > P2 > P3** and **(b) constant on P1** — it gives `entry-point` and
  `public-surface` the same severity (or, weaker and sufficient, ranks `entry-point` at least as high as
  `public-surface`) — the severity of the emitted `qualifier` is the maximum over the clauses the node
  satisfies. So no node can be assigned a lower-severity qualifier than a higher-severity clause it also
  satisfies. This is exactly what "strongest applicable clause" buys, and it is why the rule is stated as
  a precedence rather than as a first-match order over the flow's convenience.
- **(b) is a genuine second hypothesis, not a consequence of (a), and the earlier statement of this
  guarantee omitted it.** P1 > P2 > P3 orders the three *levels*; it says nothing whatever about the two
  values that share P1. The Q1-before-Q2 tie-break is a choice made *inside* a level, so a function
  ranking `public-surface` above `entry-point` would be under-reported by it and the guarantee would be
  false — not because the precedence is wrong, but because the claim would have been quantified over
  functions the precedence never constrained. The severity-neutrality assertion above is what makes (b)
  true for today's consumers; carrying it here **as a hypothesis of the theorem** is what makes a future
  severity function that splits P1 fail this check loudly instead of being silently mis-ordered.
- **The consumer's obligation, stated so it is a contract and not an assumption.** A severity function
  over this field must be **monotone in this precedence and constant on P1**; a consumer that ranks
  `named-unit` above `depended-upon`, or that splits P1 by ranking `public-surface` above `entry-point`,
  voids the guarantee and owns the consequence. feature-006's function — read from
  its **D4** table, verified 2026-07-29: `entry-point` → `[HIGH]`, `public-surface` → `[HIGH]`,
  `depended-upon` → `[MEDIUM]`, `named-unit` → `[LOW]`, with `[CRITICAL]` and `[MINOR]` never assigned —
  satisfies **both**: it is monotone in the precedence, and `[HIGH]` for both P1 values *is* constancy on
  P1. So the guarantee holds for it specifically. **STATE.md Q22 records the same
  mapping**, which is how it reached this SPEC: feature-006's own file was still unwritten when this
  revision began and Q22 was then the only verifiable record. The obligation is stated over the
  *property* rather than over those four labels precisely so a later relabelling cannot silently void it
  (Open Item 14).
- **feature-006 reached the same reading of FR-21's clause 1 independently**, which is the strongest
  available evidence that the refinement above is the requirement's own distinction rather than this
  SPEC's invention: its D4 states that "the domain is the four-value `qualifier` enum, not FR-21's three
  clauses", that "criterion 1 splits into `entry-point` and `public-surface`", and that a severity rule
  stated over clauses "needs a clause↔value translation that **no document defines**". D3a is that
  translation, defined here, where the values are produced.
- **The superseded rule was not monotone, and a live instance exists — both links verified 2026-07-29.**
  `packages/npm/package.json` is named by `.aid/knowledge/integration-map.md`'s frontmatter `sources:`
  list, so Q3 qualifies it `named-unit` in step 8; and the literal `packages/npm/package.json` appears in
  the bytes of `canonical/aid/scripts/release/check-version-sync.sh` (line 151,
  `NPM_JSON="${REPO_ROOT}/packages/npm/package.json"`), so Q4 also applies. Under
  first-match-in-flow-order the node emitted `named-unit` → `[LOW]` while
  `[MEDIUM]` was applicable: an **under-reported** severity, which is the direction FR-25's rationale
  warns about ("an incentive to tune the significance rule downward until gaps disappear"). Under
  precedence it emits `depended-upon`. `packages/pypi/pyproject.toml` is a second instance of the same
  pair by the same two carriers.

  **The citing file's own clause, corrected.** `check-version-sync.sh` is enumerated as an
  **`entry-point`**, not a `named-unit`: its first line is `#!/usr/bin/env bash` (verified 2026-07-29),
  so Q1 matches at step 8 position 1 and is final, and the `canonical/aid/scripts/<area>/*` convention
  that also matches it never gets to write a value, since Q1 outranks Q3. Its clause is inert to the
  example — the promotion turns on the **cited** node's clauses, and the citing node's only role is
  being enumerated, so that its bytes are scanned at step 9, which holds under either label — but a
  wrong clause label inside the worked example that justifies the precedence rule is not something to
  leave standing.
- **Where the two orders genuinely disagree and precedence wins anyway.** A shebang-carrying
  `tests/canonical/test-*.sh` satisfies Q1 (executable header) *and* Q3 (the test-suite convention) and
  emits `entry-point`. That is monotone-correct — the file is invoked by the runner, which is clause 1's
  own example — and it is not this SPEC's call whether `[HIGH]` is the ledger priority a reviewer wants
  for a test file. `artifact_class` = `test-suite` (D2 rule 10) is available to feature-006 as the
  discriminator, and D2 already names its gap phrasing as the field's intended consumer. Routed as
  Open Item 14; **not** managed by distorting this field, which would reintroduce a non-monotone
  assignment to solve a presentation problem.

##### The schedule that realises the precedence, and what it does not change

`depended-upon` (P2) is structurally the **last** clause the flow can evaluate: it needs the qualified
set that step 8 produces, which is why step 9 is a settling pass at all. Precedence and the flow
therefore disagree on exactly one pair — Q3 (P3) is decidable before Q4 (P2) — and the disagreement is
resolved by one promotion rather than by reordering the stages:

1. **Step 8, positions 1 then 2.** A Q1 or Q2 match is **final**: nothing outranks P1, so no later pass
   can change it.
2. **Step 8, position 3.** A Q3 match is **provisional** `named-unit`. The node is qualified and enters
   the qualified set exactly as before — which is the point: its bytes are scanned at step 9 just as
   today, so the citing set, `observations.tsv` and the fixed point are **bit-for-bit the same as the
   upheld flow**.
3. **Step 9.** Q4 finalises `depended-upon` for a held (unqualified) path receiving ≥ 1 inbound
   reference, exactly as before, **and promotes** a provisional `named-unit` that receives one, since
   P2 > P3.
4. **Step 11.** A provisional `named-unit` that received no inbound reference finalises as `named-unit`.
   Still-unqualified paths become `candidates.tsv` rows with `no-rule-match`, unchanged.

Four properties make the promotion safe, and each is the same kind of argument the fixed point already
rests on:

- **Termination and determinism are unaffected.** A qualifier moves at most once and only in one
  direction, P3 → P2. The fixed-point iteration's bound is unchanged (the qualified set only grows and is
  bounded by the candidate set), and the outcome is independent of traversal order.
- **Byte-stability is unaffected** (R12, FR-32): the promotion consults only disk state and the resolved
  reference set, never a clock, a count-ordered list or an environment value.
- **Exactly one qualifier per node still holds** — the promotion replaces a provisional value, it does
  not add a second. Consumers that rely on single-valuedness (feature-006 withdrew a severity tie-break
  precisely because of it) are unaffected, and are now better served: the maximum they wanted is
  computed here.
- **`evidence` and `evidence_provenance` move with the qualifier**, because evidence must support the
  clause it is offered for: a promoted node carries D3b's template-13 string — the matched literal and
  the citing path, in those bytes — with provenance `derived`, and where more than one inbound reference
  resolved, the `LC_ALL=C`-least such string over the observation set **as it stands at the fixed
  point** (§The evidence selection rule). So the single rule is that **the clause order Q1 → Q2 → Q3 decides
  the `qualifier`**, while step 8's "`declared` before `derived`, so a node's evidence is the strongest
  available" orders carriers **inside the matched clause only** — never across two clauses, and
  therefore never across a precedence level either: a stronger clause with `derived` evidence beats a
  weaker clause with `declared` evidence, and AC-S4 is satisfied either way since both values are legal
  and neither is `inferred` (D3's `no-inferred-node` invariant is untouched). This is the same single
  rule stated in §Precedence above and in Feature Flow step 8 — **both** of its halves in all three
  places, with the operative phrases "inside the matched clause only" and "across two clauses"
  verbatim in each — because the three texts previously did not agree, and because a bullet that
  carried only the carrier-order half was still claiming an identity it did not have.

**Nothing else in the flow moves.** Exclusions → kind classification → granularity collapse →
significance is unchanged; the media streams are unchanged (a media node has no `qualifier` field to
assign — D1a); the feature-005 producer boundary is unchanged; `artifact_class` remains a pure function
of the id evaluated at step 12 and independent of `qualifier` (D2 property 2).

##### Reachability, stated the way Q17 requires — the carrier set, never a count standing in for it

Every declared value now has at least one carrier, which is what makes the value space **total** rather
than half-declarative. Whether a given value *fires on a given project* is a property of that project,
not of this rule set (FR-8a), and this SPEC asserts no count:

| Value | Fires on this repository? | Evidence, verified 2026-07-29 |
|---|---|---|
| `entry-point` | yes | every `.sh` under `canonical/aid/scripts/**` opens with a `#!/usr/bin/env bash` shebang — checked by reading the first line of each file in that set, not by counting them — and `install.sh` does likewise |
| `public-surface` | yes | `canonical/skills/aid-discover/` and `canonical/agents/aid-architect/` are real convention directories (already verified for D2 rules 1–2) |
| `named-unit` | **the carrier fires; whether a row survives is not asserted** | `.aid/knowledge/integration-map.md`'s `sources:` list names `packages/npm/package.json` and `packages/pypi/pyproject.toml`, so Q3 matches — and **both are then promoted** to `depended-upon` because both are referenced from `check-version-sync.sh`. On a densely cross-referenced repository `named-unit` is *expected* to be rare: it is the residual clause, and precedence deliberately prefers the stronger one. A surviving instance is therefore supplied by the **fixture tree** (a convention-named path with no P1 carrier and no inbound reference), the same posture D2a point 5 takes for the case-folding rule |
| `depended-upon` | yes | `site/src/components/overrides/Header.astro` via `site/astro.config.mjs:147` (already verified for D2a), plus the two manifests above |

**A value that a given project rarely produces is not a value with no rule** — that distinction is the
whole content of this revision, and stating it here is what should stop the finding being re-raised on a
project where `[LOW]` rows happen to be scarce.

#### D4. Exclusion filter (FR-22 / AC-16 / R1)

Exclusions are applied **before** classification and **before** significance, so an excluded path can
never qualify by any clause and can never become an image. Each class has a derivable test; the
mechanisms marked *(precedent)* are the exact invocations `build-project-index.sh` already uses in its
"Scope refinement" block, which is documented there as "DETERMINISTIC + git-native +
machine-neutralized (byte-reproducible cross-OS/AID-update)" and verified at lines 203–222.

**Class 1 — generated / derived trees.** These are reproductions of a single source; including them
would multiply every node and every reported gap by the number of renderings (FR-22). **Unconditional
— never dependent on settings.**

| Excluded | Why, verified |
|----------|---------------|
| `profiles/**` | render output of `canonical/`; `module-map.md` Invariants: "MUST be regenerated, never hand-edited" |
| `.claude/**`, `.cursor/**`, `.codex/**`, `.agent/**` | the dogfood/rendered install trees. `build-project-index.sh` prunes exactly these four with exactly this rationale ("the AID install itself, never target-project source … Pruning them keeps the harvest/index scoped to the target project and byte-reproducible across AID updates") |
| `.github/aid/**` | the copilot-cli install tree. Excluded **by subpath, not by pruning `.github/`** — `build-project-index.sh`'s own comment states why: "`.github` is a standard project dir with legitimate content, so it is not pruned wholesale". Pruning it would drop the `workflow` nodes |
| `packages/npm/{bin/aid,bin/aid.ps1,bin/aid.cmd,lib/**,dashboard/**,VERSION}`, `packages/pypi/aid_installer/_vendor/**`, `packages/pypi/dist/**` | each is an explicit `.gitignore` entry labelled "vendored copies (generated … not committed)" |
| `site/dist/**` | `project-structure.md`: "built site output (generated)" |
| `.aid/generated/**` | gitignored discovery scratch |
| any file whose first two lines match `@generated`, `DO NOT EDIT`, or `DO NOT MODIFY` | *(precedent)* — the same two-line predicate `build-project-index.sh` applies (`FNR<=2 && /@generated\|DO NOT EDIT\|DO NOT MODIFY/`, verified line 220) |
| any path with `linguist-generated` set | *(precedent)* `git check-attr --stdin linguist-generated` (verified line 216) |

**Class 2 — vendored third-party code.** "not the project's to document." **Unconditional.**

- `git check-attr --stdin linguist-vendored` set *(precedent)*, verified line 216.
- `**/node_modules/**` — gitignored; present under `site/` and `canonical/aid/scripts/summarize/`
  (which carries its own `package.json` + `package-lock.json`).
- `packages/*/_vendor/**`.

**Class 3 — ignore-listed paths.**

- `git -c core.excludesFile=/dev/null check-ignore --stdin` *(precedent)*, verified line 215. The
  `-c core.excludesFile=/dev/null` is load-bearing, not incidental: it neutralises the developer's
  global gitignore, which is what makes the exclusion set identical on every machine and therefore
  compatible with FR-32.
- **plus FR-22's ignore list in `.aid/settings.yml`** — the one arm that can be **unavailable**. Its
  three-state behaviour is D4a, which is where FR-22's 2026-07-29 reporting rule is discharged.

**Class 4 — the `.aid/` partition, and why it is not optional.** No path under `.aid/**` may **become**
a node, with a single declared allowlist entry: `.aid/settings.yml` (`project-structure.md` lists it in
Key Files as "the authoritative settings other skills read"; its `artifact_class` is `settings-schema`,
D2 rule 8, **if** it becomes a node — see below). Three reasons, in order of importance:

1. `.aid/knowledge/**` is the KB side's territory. If a KB document were also an `int:` node, it would
   appear on both sides of the coverage question — a doc could "document itself" and satisfy its own
   gap, or be reported as an undocumented source artifact. Either outcome corrupts the signal FR-20
   exists to produce. **The KB-side and `int:` node sets must be disjoint**; that is an invariant, and
   `test-graph-node-partition.sh` asserts it over both of this feature's streams. The partition also
   covers images: a diagram committed under `.aid/knowledge/` is not enumerated here, because the KB
   side owns everything under that root.
2. `.aid/works/**` is transient. The project's tracking-discipline rule states work folders "may be
   pruned once the work ships" and that no permanent artifact may depend on their contents. Enumerating
   them would put transient state into a committed artifact.
3. `.aid/generated/**`, `.aid/.temp/**`, `.aid/.trash/**`, `.aid/.heartbeat/**`, `.aid/.control/**`,
   `.aid/knowledge/.cache/**` are all gitignored (verified in the `.gitignore` "AID managed" block) and
   already fall to Class 3's git-native arm.

**The cut is on paths becoming nodes, not on reading.** `external-sources.md` lives under `.aid/` and is
read by step 10 as a **registry of external keys** (§5.1 item 3, A-1); the keys it registers become
`ext:` nodes and the file itself never becomes an `int:` node. Stating the distinction matters because
"exclude `.aid/**`" and "enumerate the registered external keys" would otherwise read as contradictory
instructions to an implementer.

`.aid/connectors/*.md` is deliberately left out of the allowlist: the catalog is per-project state, not
project source, and `INDEX.md` there is generated by `build-connectors-index.sh`. Recorded as an Open
Item in case the owner wants connector descriptors visible in the graph.

**Class 5 — the maintainer-tooling allowlist.** `.claude/skills/generate-profile/**` is allow-listed
back in from Class 1, because it is hand-authored maintainer tooling that happens to live under
`.claude/` rather than a render of `canonical/` (`module-map.md` places the renderer there explicitly,
and `test-landscape.md` lists its `--self-test` entry points). Excluding it would hide the most
load-bearing module in the render plane and manufacture a false "no gap" for it.

##### When an allow-listed path does not qualify — an allowlist re-admits a candidate, it does not grant nodehood

Both allowlists above (Class 4's `.aid/settings.yml`, Class 5's `.claude/skills/generate-profile/**`)
are **exemptions from an exclusion**, and nothing more. D2's already-upheld statement of this for the
Class 5 entry — "a declared allowlist entry in D4, **not an exception in the significance rule**" — is
the general rule, and it is restated here because Class 4's wording read the other way and produced a
latent contradiction:

> **An allow-listed path re-enters the `source-artifact` candidate set at step 5 and is then subject to
> every rule that governs any other candidate.** It is a node if and only if some D3a clause qualifies
> it. **A declared allowlist entry may legitimately fail to qualify**, and when it does it becomes a
> `candidates.tsv` row with `drop_reason` `no-rule-match` at step 11, exactly like any other
> unqualified candidate, and is counted in D7's dropped-candidate contribution so the outcome is
> visible rather than silent.

**The contradiction this repairs, stated because it is the shape of defect this SPEC has been
correcting.** The old Class 4 sentence called `.aid/settings.yml` "a `settings-schema` node"
unconditionally, while **every D3a clause that can reach the path is contingent on some *other*
artifact supplying a carrier for it**. Q1 and Q2 cannot reach it at all — Q1 needs a shebang, a
workflow token, a build-command script or a `bin`/entry-point key; Q2 needs a catalog row, an asset
root, an output path, a `files` entry, a `doc_set` agent arm or a `canonical/skills|agents` convention
directory, and a settings file carries none of these on any project. The two that remain are Q3 and
Q4, and each needs a second artifact to exist: **Q3** needs a KB document whose frontmatter `sources:`
list names the path (or the `tests/run-all.sh` glob, or a script/test naming convention, neither of
which matches it), and **Q4** needs a citer.

**On this repository both fire, and Q3 is the one that fires first.** Three depth-1 KB documents carry
`- .aid/settings.yml` in their frontmatter `sources:` list — `.aid/knowledge/pipeline-contracts.md`,
`.aid/knowledge/quality-gates.md` and `.aid/knowledge/README.md`, all three read on disk 2026-07-29 —
and depth-1 KB documents are exactly the read Feature Flow's input line declares. So Q3 matches at step
8 position 3 and the path is a **provisional `named-unit`** before Q4 is evaluated at all; Q4 then
promotes it P3 → P2. Q4's own link is live too — `canonical/aid/scripts/config/read-setting.sh` is
enumerated (Q1: `#!/usr/bin/env bash` on line 1) and its line 46 is
`SETTINGS_FILE=".aid/settings.yml"`, an inbound reference D5 resolves — so the **emitted value is
`depended-upon` (P2) either way**, and the resolution below is unaffected by which clause is credited.
What does not survive the removal of both carriers is nodehood itself: on a project supplying neither a
KB `sources:` entry naming the settings file nor a citer of it, no clause fires, and the old sentence
asserted a node this SPEC's own rules could not produce. "True on this repository, false in
general" is exactly the FR-8a failure this SPEC exists to avoid, and a masked contradiction is still a
contradiction — the masking was two clauses deep, not one.

**Why re-admission is the resolution, and why the alternative was rejected.** The alternative was to
give `.aid/settings.yml` a non-contingent clause — a Q2 carrier for "the project's declared settings
surface". It is rejected on two grounds. (1) It would **add a mechanism**, which D3a is explicitly built
not to do: the map re-uses D3's carriers verbatim, and inventing a carrier for a single hard-coded path
is a fiat with no project-side convention behind it, which is what FR-24 forbids. (2) It would **change
live output**: on this repository the path would move from `depended-upon` (P2, `[MEDIUM]` in
feature-006) to `public-surface` (P1, `[HIGH]`), a severity change made for the convenience of a
wording fix. Re-admission changes **no node on any project**: on projects where a clause fires the path
is a node with the qualifier that clause assigns, and on projects where none fires it was never
producible as a node in the first place — the correction is to the sentence that claimed otherwise.

**This is the same rule step 11 already enforces**, and stating it here removes the appearance of an
exception: "**File existence alone never qualifies** — this step is where that requirement is actually
enforced." An allowlist entry is a statement about *existence in the candidate set*. It was never a
statement about qualification, and now says so.

#### D4a. Ignore-list availability — three states, one probe (FR-22, FR-11, D-4, R2)

**The requirement changed and the old mechanism could not express it.** FR-22 now says: when the
ignore-list setting is absent, the skill must **report** that the ignore list is unavailable — in
FR-9a's coverage notes — and proceed with the other two exclusions, "rather than silently behaving as
though an empty ignore list were configured." The 2026-07-28 revision read the setting as
`read-setting.sh --path graph.ignore --default ''` and noted that "an absent section is not an error."
That is precisely the forbidden behaviour: it collapses two distinct states into one empty string.

**The collapse is a property of the resolver, verified rather than assumed.** In
`canonical/aid/scripts/config/read-setting.sh`, `lookup_list` prints its accumulated items only
`if (items != "")` at `END`, and `lookup` returns empty for a block-form marker. So a **declared-empty**
list and an **absent** key produce byte-identical stdout, and with `--default ''` both exit `0`. No
combination of existing flags — including a sentinel default — distinguishes them, because the default
is substituted in both cases.

**Author decision: an additive probe mode on the one settings parser.** `read-setting.sh` gains
`--probe`, which prints exactly `declared` or `undeclared` on stdout and exits `0` (`2` on an argument
error, unchanged). It is implemented on the **same** `lookup` / `lookup_list` awk scanners — a
declaration hit is the `in_section && $0 ~ "^[[:space:]]+"key":"` branch those functions already
contain — so the probe and the read cannot disagree about what is declared.

Three alternatives were considered and rejected:

- **Grep `settings.yml` from the scanner.** Rejected: `coding-standards.md` requires settings to be read
  only through the resolver and never hand-parsed, and a second parser is a second thing that can
  disagree with the first about section boundaries — the exact failure this probe exists to prevent.
- **A new exit code (e.g. `3`) instead of a stdout token.** Rejected: `0`/`1`/`2` are the documented
  contract of every script in this toolkit, and inventing a fourth code for one caller is a wider blast
  radius than a new flag that no existing caller passes. Printing a token keeps the exit-code contract
  untouched.
- **Infer availability from the settings template.** Rejected: the live file is what governs the run,
  and a project may edit it independently of the template.

**No existing caller changes behaviour**: `--probe` is a new flag, the three existing modes are
untouched, and `tests/canonical/test-read-setting.sh` is extended rather than rewritten.

**Ownership, decided — feature-004 implements `--probe`.** The earlier text left this open, and the
Layers table simultaneously committed to it, which is a contradiction an implementer cannot act on. Three
reasons settle it in this direction:

1. **This feature is the only caller and the only feature whose criteria depend on it.** AC-S7 asserts the
   three-state behaviour and AC-20 asserts the coverage note that reports it. Deferring the flag to another
   feature makes two of this feature's own acceptance criteria unimplementable by its own tasks — a gap, not
   a sequencing choice.
2. **The change is additive with no behavioural blast radius**, established above rather than assumed: a
   new flag, the same awk scanners, the same exit codes, no existing mode touched. There is nothing here
   for a settings-schema owner to arbitrate.
3. **The dependency it creates is internal.** The `--probe` task and the scanner task are both this
   feature's, so the ordering is expressible in this feature's own task graph instead of across features.

**What genuinely belongs elsewhere is a different change**, and separating the three shared-settings
surfaces is what removes the ambiguity:

| Change | Owner | Why there |
|---|---|---|
| `read-setting.sh` gains `--probe` | **feature-004** | sole caller; additive; AC-S7/AC-20 depend on it |
| the shipped template gains a **commented-out** `graph:`/`ignore:` block | **feature-004** | a comment declares nothing, so it cannot trip the reconcile or `format_version` questions — it only carries the shape |
| a **live** `graph:` declaration, the `format_version` bump question and the reconcile rule | **feature-010 / feature-012** | those are settings-schema decisions with install-upgrade consequences this feature neither makes nor needs (Open Item 8) |

There is therefore **no interim state and no fallback to specify**: `--probe` exists as soon as this
feature's first task lands, and the ignore-list-absent behaviour specified against its output is available
from that point. Open Item 5 now records only the coordination the other two features need — that the
mechanism already exists, so neither should add a second one.

**The three states and their behaviour**, which is R2's whole decision procedure:

| Probe result | Pattern list | Class 3 second arm | Coverage note `Applied` / note (D7) |
|---|---|---|---|
| `undeclared` | none to read | **not applied** — the list is unavailable | `no` / `setting absent — ignore list unavailable (D-4)` |
| `declared`, resolver returns empty | zero patterns | **applied**, excludes nothing | `yes` / `declared, 0 patterns` |
| `declared`, resolver returns items | the comma-joined items | **applied** | `yes` / `declared, <n> patterns` (suffixed when an item was comma-split — below) |

Alongside the note, the scanner prints one line to **stderr** in the `undeclared` case:
`[scan] notice: graph.ignore not declared in <resolved path> -- ignore list unavailable; proceeding
with the unconditional exclusions`. stderr carries diagnostics per `coding-standards.md`, and it is
outside FR-32's byte-identity boundary, so the notice is free. **Classes 1 and 2 are applied in all
three states** — FR-22 calls them unconditional and they never consult settings, which is what makes
"proceed with the other two exclusions" a property of the code rather than an instruction.

**The setting this feature introduces**, seeded commented-out in the shipped template so a fresh
install carries the shape without declaring an empty list by accident:

```yaml
graph:
  ignore:                          # repo-relative globs excluded from node enumeration
    - examples/**
```

Verified 2026-07-29: **neither** `.aid/settings.yml` (which declares `format_version: 3`) **nor**
`canonical/aid/templates/settings.yml` declares a `graph:` section or an ignore list of any kind — so
today's live state is the `undeclared` row of the table above, and the coverage note on this repository
reads `no / setting absent`. Values are read through
`read-setting.sh --path graph.ignore --default ''`, which resolves a list-valued dotted key through
`lookup_list` and returns the items comma-joined (documented in the script's own usage block and
exercised there against `tools.installed`). One limitation follows from that comma-joined output and is
stated rather than discovered later: **an ignore pattern may not contain a comma.** Patterns are matched
as repo-relative globs with bash `case` semantics, the same matching style `build-project-index.sh` uses
for its `NOTABLE_PATH_PATTERNS`.

**The limitation gets a diagnostic, and it has to live in the resolver for the same reason the probe
does.** By the time the scanner receives the comma-joined string the information is **destroyed**: a
pattern written `a,b` and two patterns `a` and `b` are byte-identical at that point, so no check the
scanner can perform will ever see the difference, and re-reading `settings.yml` in the scanner is
forbidden (`coding-standards.md`: settings are read only through the resolver). The only place the raw
items are still separate is inside `lookup_list`'s scanner — which is where `--probe` already runs. So the
check rides on the flag this feature is already adding:

- **`--probe` also warns.** While scanning the declaration it prints one **stderr** line per raw list item
  containing a comma: `[read-setting] warning: graph.ignore item "<item>" contains a comma; it will be
  split into separate patterns`. stdout stays exactly `declared` / `undeclared` and the exit code stays
  `0`, so the probe's contract is unchanged and **no existing mode is touched** — the property the
  ownership decision above rests on.
- **It warns and proceeds; it does not fail the run.** FR-22's posture for this setting is to degrade and
  report, not to abort, and the same choice was made for the `undeclared` notice. Naming the offending item
  verbatim is what makes it actionable per `coding-standards.md`.
- **The durable record carries it too**, because stderr is ephemeral and FR-22's obligation is to *report*:
  when any item was split, the `declared, <n> patterns` note of the table above reads
  `declared, <n> patterns (<m> item(s) contained a comma and were split)`. Both numbers are functions of
  the settings file alone, so the note stays inside FR-32's byte-identity guarantee.
- **The scanner always sees the warning**, because Feature Flow step 3 probes before it reads — the probe is
  not optional, it is how the three states are distinguished at all.

**Why FR-11 counts settings as a staleness input, restated because this section is where it bites.** A
settings-only edit changes both which nodes are enumerated *and* the status these notes assert. Omitting
it from the digest would skip regeneration while the coverage notes went on claiming a stale
availability — the silent wrongness FR-22's reporting rule exists to prevent.

#### D5. Observation record (feature-005's input)

`observations.tsv` — tab-separated, `LC_ALL=C`-sorted, LF-only. The scanner emits these while walking;
it does not interpret them.

| # | Field | Value space |
|---|-------|-------------|
| 1 | `from_id` | an `int:` node id — the artifact whose bytes contained the reference |
| 2 | `to_id` | an `int:`, `ext:` or KB-side node id — the referenced artifact |
| 3 | `observation_kind` | `path-reference` \| `invocation` \| `dependency` \| `include` \| `convention` \| `image-reference` |
| 4 | `evidence` | **D3b template 13, byte for byte** — `<to_id rendered by D3b's <subject> rule> -- inbound reference (search: "<the matched literal, as written in the citing file>" in <from_id path>)`; a durable anchor, never a line number. Step 9 draws a step-9-qualified node's `evidence` from **this** stream, so the observation string and the node string are the same bytes by construction rather than by two agreeing descriptions |

**Resolution of a reference to a `to_id` is deterministic and never guesses.** For an **in-repo** target
the resolution set is the `nodes.tsv` candidate set **plus the `int:` rows of `media-nodes.tsv`** — because
a reference to an image must resolve to the image node rather than becoming a spurious unresolved
candidate. For an **`ext:`** target it is the **key set loaded at Feature Flow step 3**, never
`media-nodes.tsv`'s `ext:` rows, which do not exist until step 10. The two arms are named separately
because a single "both streams" phrasing would imply the external rows are readable during resolution:

- A full repo-relative path that matches an enumerated node → that node.
- **An occurrence is attributed to the longest form that matches at it, and to one form only.** Every
  full path contains its own basename, so a byte range matching `lib/cited.sh` also contains a range
  matching `cited.sh`; without this rule the same occurrence would yield **two** admissible literals,
  one implementation would emit both and another one, and D3b's template-13 token — and therefore the
  `LC_ALL=C`-least string D3a selects — would differ between them. So a basename occurrence lying
  **inside** a matched full-path occurrence is not separately matched. Two *distinct* occurrences in one
  file, one writing the path and one writing the bare basename, remain two observations and two
  admissible strings; that is a real difference in what the file says, and it is the shape the
  evidence-selection fixture uses. Stated here rather than in D3b because it is a property of the scan,
  not of the string: D3b renders whatever literal this rule attributes.
- A **basename** that matches exactly one enumerated node after exclusions → that node. This works
  precisely because Class 1 removes the render copies: `build-kb-index.sh` exists at several paths on
  disk (`canonical/`, the `profiles/` renders, `.claude/`, `.cursor/`), and excluding the copies leaves
  `canonical/aid/scripts/kb/build-kb-index.sh` as the unique survivor. The exclusion filter is
  therefore not just noise reduction — it is what makes basename resolution single-valued.
- A **relative** reference, which is how markdown addresses images, is resolved against the **citing
  file's directory**, normalised, and then matched as a full path. **The rule keys on the reference's
  *form*, not on the citing file's language** — a `./`- or `../`-prefixed path in a config file or a
  JavaScript `import` resolves by the same procedure as one in a markdown link, which is what D2a's
  ordering example relies on. Two verified instances, both of which resolve:

  | Citing file | Reference as written | Resolves to |
  |---|---|---|
  | `docs/aid-methodology.md` (line 174) | `images/3-ironman.png` | `docs/images/3-ironman.png` |
  | `site/src/content/docs/concepts/methodology.md` (line 178) | `../../../assets/3-ironman.png` | `site/src/assets/3-ironman.png` |

  **Normalisation happens before the id is formed, and that is why this does not contradict feature-003
  D2b.** D2b forbids a `..` segment inside an `int:` **id**; the `..` here is in the *reference text*,
  which is resolved and normalised first, so the emitted id is already `..`-free. A reference that
  normalises to a path **outside** the repository root is not resolved — it becomes a candidate — which
  keeps D2b's path-confinement rule intact at the one place a `..` could otherwise escape.
- A citation of a **registered `ext:` key** resolves to that key's node — the key set is read at Feature
  Flow step 3, before any resolution runs. An unregistered key resolves to nothing and becomes a
  candidate, which is the same treatment feature-005 gives an unregistered URL in a `sources:` list.
- A basename matching **more than one** surviving node, or **zero** → a `candidates.tsv` row with
  `drop_reason` `ambiguous-basename` or `unresolved-reference`. Never a guess, never a row. Both
  branches have live instances: `3-ironman.png` exists at two enumerated paths (`docs/images/` and
  `site/src/assets/`, verified 2026-07-29), so a bare-basename citation of it is `ambiguous-basename`
  while both full-path citations above resolve; and `site/astro.config.mjs`'s `favicon: '/favicon.svg'`
  is a site-absolute URL path, not a repository path, so it is `unresolved-reference` rather than being
  guessed onto `site/public/favicon.svg` by way of a framework convention the scanner is not entitled to
  assume.

`observation_kind` values and their literal triggers:

| Kind | Trigger |
|------|---------|
| `path-reference` | the bytes of one node contain another node's path or uniquely-resolving basename |
| `invocation` | `bash <p>`, `sh <p>`, `source <p>`, `. <p>`, `node <p>`, `python <p>`, `python3 <p>`, `pwsh -File <p>`, `powershell -File <p>`, `Import-Module <p>` |
| `dependency` | a manifest edge: `package.json` `bin`/`files`/`dependencies`; `pyproject.toml` entry points; `profiles/<tool>.toml`; `generated-files.txt` output ↔ build command; `shortcut-catalog.yml` row ↔ emitted doorway; `.aid/settings.yml` `knowledge.doc_set` ↔ the named KB doc (the one `dependency` that crosses to the KB side) |
| `include` | the `{{include:agent-boilerplate}}` directive — present in the `canonical/agents/*/AGENT.md` files, and recorded in `module-map.md`'s dependency graph as `canonical/agents/* -> canonical/aid/templates/agent-boilerplate.md (include directive)` |
| `convention` | a rule-based structural edge, e.g. `canonical/skills/*` → `canonical/aid/templates/shortcut-engine.md` for a shortcut doorway |
| `image-reference` | *(new)* a markdown image (`![alt](<ref>)`) or an HTML `src`/`href` whose resolved target is an `image` node — emitted so feature-005 can type the depiction relation the widened model exists to carry |

**`image-reference` is a separate kind rather than a `path-reference`, and the reason is downstream.**
feature-005 chooses a relation per **harvest kind** through its edge-relation map, so an observation
whose target is a picture must be distinguishable from one whose target is a script — otherwise the two
would be typed identically and the depiction relation class FR-5's standards-first vocabulary is
expected to supply (schema.org / CiTO / Dublin Core all carry one) would have no carrier. Naming the
kind here costs nothing; discovering the need in feature-005 would cost a re-specification. The
mapping itself is feature-005's (Open Item 4).

#### D6. Candidate record

`candidates.tsv` — tab-separated, `LC_ALL=C`-sorted, LF-only:
`candidate_kind | subject | context | drop_reason`, where `candidate_kind` is `node` or `edge`. This is
the *only* channel by which anything the rules could not settle reaches feature-005's agent pass, and it
never carries a promotion path to a node (D3).

`drop_reason` values this feature emits: `no-rule-match` (an unqualified source path),
`ambiguous-basename`, `unresolved-reference`, and `outside-repo-root` (a relative reference that
normalised above the root, D5).

#### D7. The coverage-note content this feature supplies (FR-9a part 2, AC-19, AC-20, R11)

**Routed here by feature-003, and this is the discharge.** feature-003 owns the `## Coverage notes`
section's shape, row set, order and validation (its D7a, V14) and its Open Item 5 assigns the
**content** to this feature for "enumeration and exclusions", to feature-005 for extraction counts, and
to feature-010 for run orchestration. This feature writes its contribution to
`.aid/.temp/graph/coverage.tsv`; feature-010 assembles the rendered section from the contributions.

`coverage.tsv` — tab-separated, LF-only, **emitted in fixed order** (never sorted by a count, which
would reorder the section whenever a count changed and break FR-32):

| # | Field | Value space |
|---|-------|-------------|
| 1 | `scope` | `kind` \| `exclusion` |
| 2 | `key` | for `kind`: `source-artifact` \| `image` \| `web-page`, plus permitted extra keys; for `exclusion`: `generated-trees` \| `vendored-code` \| `ignore-list` |
| 3 | `status` | for a `kind` row: `present` \| `absent`, or `--` where the row reports something other than a carrier's availability; for `exclusion`: `yes` \| `no` (feature-003 D7a's `Applied` column) |
| 4 | `count` | a non-negative **node** count, or `--` |
| 5 | `note` | for `kind`: the carrier-convention text; for `exclusion`: the note text |

`--` is this project's existing unset marker in state frontmatter, so neither column needs a new
convention. **The `count` column carries a node count or nothing**, and that restriction is deliberate
rather than tidy: it keeps the rendered `Nodes` column summable, so a consumer that ever totals it
cannot pick up a number that is not a node count. The second extra row below reports exactly such a
number — how many surviving paths the significance rule dropped — and therefore reports it in the
`note`, not in the `count`.

**The `present`/`absent` predicate, stated because feature-003 fixed the enum but not the test.**

> A kind's status is **`present` iff this project supplied at least one instance of that kind's carrier
> convention** for the run to read, **`absent` otherwise**. The `count` remains the number of nodes
> emitted — so **`present` with a count of `0` is legal and meaningful**: the carrier was there, and the
> rule that reads it qualified nothing.

**This replaces "`present` iff ≥ 1 node", which conflated two different questions.** FR-9a asks for "the
**carrier convention** the kind depends on (glossary, checkable source anchors, headings, the
external-sources file); whether that convention was **present or absent** in this project". Every carrier
FR-9a names is a **project-side** thing. For `source-artifact` the significance ruleset is not that thing —
it is FR-21, it ships with the tool, and it is never absent from any project; what a project can supply or
fail to supply is **source for the ruleset to read**. So a project whose entire tree fell to FR-22's
exclusions, or one where paths survived but no clause qualified any of them, would have been reported
`source-artifact: absent` under the old predicate — asserting the convention was missing when in fact it
applied and simply cut everything. The revised predicate reports `present` with a count of `0`, and the
`source-artifact-dropped` row below then shows the size of the cut, which is the pair a reader needs.

**What counts as one instance of the carrier, for the three kinds this feature owns.** Each is a number the
run already computes *before* it decides which nodes to emit, so the predicate stays decidable from the
run's own state with no second probe:

| Kind | One instance of the carrier | Where the run already has it |
|---|---|---|
| `source-artifact` | a path that survived D4 and reached the significance evaluator | step 8's input set |
| `image` | a surviving path whose extension is in `image_extensions:` | step 6's image partition |
| `web-page` | a registered key in the external-sources registry | the key set loaded at step 3 |

For the two media kinds every carrier instance becomes a node — FR-21a qualifies them **by kind**, with no
test to fail — so status and a non-zero count still coincide exactly as before, including AC-19's case: an
empty *or* missing registry yields zero keys, hence `absent` with a count of `0`, "naming the convention,
its status, and the resulting count." Only `source-artifact` can now legally read `present` / `0`, and only
because only it has a rule that can reject its own input.

**It stays uniform across all seven kinds — which was the original predicate's best property and is not
given up — because what it delegates is only the *carrier definition*, and that is the one part each kind's
owner knows better than this feature does.** The old predicate hard-coded the carrier as "a node", which is
precisely where it went wrong. The revised one keeps a single test and lets each owner name what one
instance of its carrier is:

| Kind *(feature-005's)* | Carrier named by FR-9a | Effect of the revision |
|---|---|---|
| `document` | a KB document under `.aid/knowledge/` | none — every such document is a node, so the two readings coincide |
| `section` | an ATX heading, levels 2–6 | none — every heading is a node |
| `concept` | the glossary convention — a definition marker under a level-3+ heading | none — every marker is a node |
| `fact` | "checkable source anchors" | **a choice feature-005 must now make deliberately** — see below |

**The `fact` row is where the revision has teeth, and this feature states the choice rather than making
it.** feature-003 D7a's own extra-row example is "the count of `CONFIRMED` markers skipped for want of an
anchor string" — so a project can carry the convention while producing no `fact` node. FR-9a's parenthetical
is a list of *conventions*, not of instances (for `concept` it says "glossary", not "each marker"), and the
`fact` convention has two parts, so the carrier can be read either way:

- **the marker is the carrier**, the anchor being the qualifying test → an unanchored-marker project reads
  `present` / `0` plus the skipped count, the same shape as `source-artifact` / `source-artifact-dropped`;
- **the anchored marker is the carrier** → the behaviour is identical to the old predicate.

Both are expressible under one predicate, which is the property being claimed here — not that this feature
knows which is right for a kind it does not own. **Owner: feature-005**, and it is the substance of Open
Item 4's remaining half. feature-003 D7a's worked example stays satisfiable under either reading, because
every zero in it comes from a genuinely absent carrier; the two predicates can only differ where a carrier
is present and produces nothing, which the example does not exercise.

**The three fixed `kind` rows this feature owns.** The `note` text reproduces feature-003 D7a's example
wording **verbatim in two rows of three**, so the rendered table matches the skeleton in its own SPEC
rather than diverging from it. The `image` row is the one deliberate divergence, and the reason is
below the table:

| `key` | `note` (carrier convention) | `status` | `count` |
|---|---|---|---|
| `source-artifact` | `project source, per FR-21 significance` | `present` iff ≥ 1 path reached the evaluator | rows in `nodes.tsv` |
| `image` | `image files in-repo; no external key is an image (D-5)` | `present` iff ≥ 1 image path survived exclusions | `image` rows in `media-nodes.tsv` |
| `web-page` | `entries in the external-sources file` | `present` iff ≥ 1 key was registered | `web-page` rows in `media-nodes.tsv` |

**Why the `image` note diverges from D7a's example, and why diverging is the safe direction.** D7a's
example reads `image files in-repo; external image keys`, which describes a two-armed carrier. Under
D1a's tier B — the only behaviour currently specifiable, because the registry declares no media type
(D-5) — **no `ext:` key is ever classified `image`**; every registered key emits as `web-page`. Shipping
the example wording unchanged would make the generated section assert a carrier that can never
contribute a single node, and AC-20 requires these notes to record what the run could actually see. The
divergence costs nothing mechanically: **V14 validates the kind label, its enum position, the `Status`
value and the count — not the carrier text** (feature-003 D7a: "every enum kind appears exactly once in
enum order with a `Status` from the enum and a non-negative integer count"), so a corrected note passes
the same validator the example wording would. D7a's block is a shape skeleton, not a fixed string.

**The note text is selected by the same tier constant that selects the classification**, which is what
keeps it true if tier A is later enabled (Open Item 3):

| Tier | Classification of a registered `ext:` key | `image` note text |
|---|---|---|
| B *(current)* | always `web-page`; no external `image` node | `image files in-repo; no external key is an image (D-5)` |
| A *(if the registry gains a declared media type)* | `image` when the declared type is `image/*`, else `web-page` | `image files in-repo; external keys typed as images` |

One constant drives both, so the pair cannot drift: whoever flips the tier changes the classification
and the sentence in the same edit, and `test-graph-coverage-notes.sh` asserts the tier-B string against
the tier-B classification, so a half-done flip fails a test rather than shipping a false note. Correcting
the wording in D7a's own example is feature-003's to make, and is routed as Open Item 6c rather than
assumed.

**Two permitted additional rows, using the mechanism feature-003 provided rather than inventing one.**
D7a permits extra rows below the fixed ones and states that V14 "checks the fixed part and ignores the
rest, so a producer can report more without breaking the contract." This feature uses it twice:

| `scope` | `key` | `status` | `count` | `note` |
|---|---|---|---|---|
| `kind` | `image-external` | `absent` | `0` | `external-sources entries carry no media type -- external image nodes cannot be distinguished from web pages (D-5)` |
| `kind` | `source-artifact-dropped` | `--` | `--` | `paths surviving exclusions that no significance clause qualified: <n>` |

The first gives the blocked external-`image` arm an explicit **zero and a reason**, where the fixed
`image` row above has only a carrier phrase to spend: the fixed row says the arm contributes nothing, and
this row says why and shows the count. The second makes the significance rule's *cut* visible, which
matters because FR-25's rationale warns about the incentive to tune the rule downward — a reader who can
see how much the rule dropped can notice it moving. Both rows rely on V14 tolerating a **non-enum label**
in an extra row's first cell; that reliance is stated and routed to feature-003 as Open Item 6a rather
than assumed.

**Fallback if feature-003 declines or defers that tolerance**, so this feature is not left specifying a
table its own validator would reject. Both facts move into the fixed rows' `note` cells, which V14 does
not constrain:

| Fact | Fallback carrier |
|---|---|
| the external `image` arm is blocked and contributes zero | already carried — the corrected `image` note above states it, so this arm loses only the explicit `0` |
| how many surviving paths no significance clause qualified | appended to the `source-artifact` note as `; dropped <n>`, making three of the three fixed notes diverge from D7a's example wording instead of one |

The fallback is strictly weaker — a note cell is prose a consumer cannot parse, where an extra row is
tabular — which is why it is the fallback and not the design. It is nonetheless total: no fact reported
here depends on the extension mechanism surviving, so a `no` from feature-003 costs presentation rather
than content, and it changes nothing about which nodes are enumerated.

**The three `exclusion` rows**, whose `status` is FR-22's "report" obligation discharged:

| `key` | `status` | `note` |
|---|---|---|
| `generated-trees` | `yes` | `unconditional (FR-22)` |
| `vendored-code` | `yes` | `unconditional (FR-22)` |
| `ignore-list` | `yes` / `no` per D4a | D4a's note text for the observed state |

**These three `key`s are TSV keys, not the rendered labels, and the mapping is feature-010's.** D7a's
skeleton renders the same three rows as `generated/derived trees`, `vendored third-party code` and
`` `.aid/settings.yml` ignore list ``, and V14 checks "the three exclusion rows are present in order" —
against those labels, not against these keys. A machine-readable key is the right thing to put in a TSV
and the wrong thing to put in a rendered table, so the two differ by design; what matters is that
**exactly one component owns the translation**, and that component is the one that assembles the section
(feature-010, per feature-003's Open Item 5). Stated here because the three `kind` keys need no
translation — `source-artifact`, `image` and `web-page` render as themselves — so a reader could
reasonably assume the exclusion keys pass through untranslated too, and V14 would then fail on labels
this feature had no way to see were wrong. Routed as part of Open Item 7.

**Every value here is byte-stable.** No timestamp appears; no absolute path appears; the row order is
fixed rather than derived from a count; and every count is a function of the deterministic node streams,
never of the agent pass — FR-31a part 2 forbids Pass 2 to create nodes, which is what puts these counts
inside FR-32's guarantee and inside feature-003 AC-5's second byte-comparison.

### Feature Flow

Inputs: the repository working tree; `.aid/settings.yml` (`graph.ignore`, via the D4a probe and the
resolver); `.aid/knowledge/external-sources.md` (the `ext:` registry, or a fixture via
`--external-sources`); the **frontmatter `sources:` lists** of the KB documents at depth 1 under
`.aid/knowledge/` (a D3 declared carrier and one of the two narrow KB reads the enumeration boundary
enumerates — listed here because it was absent from this line while D3 depended on it); `<install-root>/aid/templates/graph/relationship-schema.yml` (for
`image_extensions:` and the `Kind` enum, via `rel_load_schema`); git (for `check-ignore`, `check-attr`, and
`rev-parse --show-toplevel`). Outputs: the four streams plus `coverage.tsv` in `.aid/.temp/graph/`.
`scan-source.sh` writes nothing else and modifies no source file or KB file (FR-10).

1. **Resolve the root.** `git rev-parse --show-toplevel`, as `kb-freshness-check.sh` does. Not a git
   repo → exit `2` with an actionable message: Classes 1–3 depend on `git check-ignore` and
   `git check-attr`, so a non-git checkout cannot produce a reproducible exclusion set.
2. **Load the schema.** Source feature-003's `relationship-schema.sh` and call `rel_load_schema`, which
   supplies `image_extensions:` and the `Kind` enum and **exits `2` fail-closed** on an absent, empty or
   malformed schema file (feature-003 D1a). Loading before the walk means a configuration error is never
   reported as an enumeration result.
3. **Probe the ignore list (D4a)** and read its patterns if declared. Emit the stderr notice in the
   `undeclared` case. This runs before the walk so the exclusion set is fixed before any path is
   classified. **Read the external-sources registry here too** — feature-003 D2c's predicate over
   `external-sources.md` — so the `ext:` key set exists before any reference is resolved; the rows
   themselves are emitted at step 10, which is a write and not a read.
4. **Collect candidate paths.** One `find` from the root with a directory-prune expression built the way
   `build-project-index.sh` builds `PRUNE_EXPR` (verified at its line 183), then `LC_ALL=C sort`. The
   prune set is the cheap, directory-shaped half of D4 (`.git`, `node_modules`, `profiles`, `.claude`,
   `.cursor`, `.codex`, `.agent`, `.aid`, `site/dist`, …); the remaining exclusions are path- and
   content-shaped and run in step 5.
5. **Apply the exclusion filter (D4)** in class order, as batched removals — one process per mechanism,
   never one per file: a single `git check-ignore --stdin`, a single `git check-attr --stdin`, a single
   batched two-line `awk` for the `@generated` header predicate, and one `case`-glob pass for the ignore
   patterns when they are available. Batching is not an optimisation detail;
   `build-project-index.sh` records that per-file forks under Windows Git Bash / MSYS cost 0.5–1.8 s
   each and dominated its runtime. Then apply the Class 4 `.aid/` cut and the Class 5 allowlist.
   Removal-only, so the result is order-independent.
6. **Classify by kind (D2a), then apply the granularity cut.** Partition the survivors: a path whose
   extension is in `image_extensions:` is an `image`; every other path is a `source-artifact` candidate.
   Then, over the `source-artifact` candidates only, collapse `canonical/skills/<name>/**` to the
   directory id `int:canonical/skills/<name>/` and `canonical/agents/<name>/**` to
   `int:canonical/agents/<name>/`, suppressing their member files; **image members are exempt from the
   suppression** (D2a). Every other node is file-level. **No node id is ever narrowed to a symbol or a
   line range** — the scanner has no code path that produces a `#` in an `int:` id, the single-writer
   assertion in D3 rejects one, and feature-003's V7 re-checks the emitted table. This is FR-23's code
   clause and R9, now total: §5.3's "optionally narrowed to a symbol" clause is struck, so there is no
   remaining case to accommodate.
7. **Emit the in-repo image nodes.** Every classified image becomes a `media-nodes.tsv` row with its
   `derived` extension evidence (D1a). **No significance clause is evaluated** — FR-21a — and the media
   writer has no field to record one in.
8. **Qualify the source artifacts by rule (first pass).** For each surviving `source-artifact`
   candidate, test D3a's clauses **in clause order** — **Q1 `entry-point`, then Q2 `public-surface`,
   then Q3 `named-unit`** — and stop at the first clause any of whose carriers matches. That clause
   alone decides the qualifier: the first two are **final** on match, since nothing outranks P1; **Q3 is
   provisional**, because P2's clause is decidable only at step 9. **Then, and only inside the matched
   clause**, order that clause's own carriers — `declared` (D3) before the `convention`-membership and
   `executable-header` mechanisms — to pick the `evidence` / `evidence_provenance` pair, so a node's
   evidence is the strongest available **for the clause it qualifies under**. That ordering runs **inside
   the matched clause only**; it is never consulted across two clauses, and therefore never across a
   precedence level either (D3a §Precedence, both halves in the same operative phrases: the clause order
   decides the value, the carrier order decides only the evidence). **Where that class holds more than
   one matching carrier the order is not yet decisive, and the pick is stated rather than left to
   iteration order: the emitted `evidence` is the `LC_ALL=C`-least of the admissible strings for that
   clause and class** (D3a §The evidence selection rule), **each string formed by D3b's template for
   the carrier that produced it** — so the set being ordered is a set of bytes rather than a set of
   descriptions. A path with no match is held for step 9.
9. **Settle `depended-upon` (second pass).** Scan the bytes of the nodes qualified in step 8 for
   references (D5), emitting `observations.tsv`. **The resolution target set is what exists by now, and
   the two arms differ** (D5): in-repo references resolve against `nodes.tsv`'s candidate set **and the
   `int:` rows of `media-nodes.tsv`** — written at step 7 — so a reference to an image resolves rather
   than becoming a spurious candidate; `ext:` citations resolve against the **key set loaded at step 3**,
   not against `media-nodes.tsv`'s `ext:` rows, which step 10 has not written yet. Stated this way because
   "both node streams" reads as though the external rows were available here, and an implementer who took
   it literally would either resolve against an unwritten table or reorder the flow to make it true. A held path that receives
   at least one inbound reference qualifies as `depended-upon`, with the D3b template-13 string of an
   inbound observation as evidence — **and where more than one inbound reference resolved, the
   `LC_ALL=C`-least such string over all of them** (D3a §The evidence selection rule; every one of them
   stays a row of `observations.tsv`, so the choice narrows the node record and discards nothing) —
   **and so does a provisional `named-unit` node that receives one, which is promoted from
   P3 to P2 with its evidence and provenance replaced** (D3a: the emitted qualifier is the strongest
   applicable clause, and this is the one pair the flow cannot evaluate in precedence order). Iterate to
   a fixed point — a newly qualified node's own references can qualify another —
   which terminates because the qualified set only grows and is bounded by the candidate set; the
   promotion does not weaken that bound, since a qualifier moves at most once and only P3 → P2.
   Fixed-point iteration is what makes the result independent of traversal order and therefore
   reproducible. **The rounds decide qualification only; the evidence is frozen after the last one.**
   Because the qualified set grows, so does each node's resolved inbound observation set, so the
   selection above is **not** evaluated inside the loop: once the iteration has terminated, one final
   pass assigns `evidence` and `evidence_provenance` to every node this step qualified — Q4's own and
   the promoted `named-unit`s alike — from the **completed** `observations.tsv`. Latching the least
   string in the round a node first qualified would make field 5 depend on that round, which is the
   traversal dependence the fixed point exists to remove (D3a §The evidence selection rule).
10. **Enumerate the external nodes.** Apply feature-003 D2c's registry predicate to
    `external-sources.md` and emit one `media-nodes.tsv` row per registered key, with the D1a tier-B
    kind assignment and `declared` evidence. A missing or key-less file yields zero rows and is **not**
    an error (AC-19).
11. **Drop the residue, and finalise the provisional qualifiers.** A provisional `named-unit` that
    received no inbound reference finalises as `named-unit` — no clause outranking P3 applied. Every
    still-unqualified `source-artifact` candidate becomes a
    `candidates.tsv` row with `drop_reason` `no-rule-match`. **File existence alone never qualifies** —
    this step is where that requirement is actually enforced, and its count is reported in the coverage
    contribution (D7) so the cut is visible.
12. **Emit.** Assign each `nodes.tsv` row's `artifact_class` by D2's ordered rule list — a pure function
    of the node id, evaluated here rather than during qualification so that no path can reach the writer
    without a value for a required field. Then write the four streams `LC_ALL=C`-sorted with LF endings,
    each through its single writer
    with D3's four assertions, plus `coverage.tsv` in fixed order (D7). Print a one-line summary to
    stderr in the `[index]`-prefixed diagnostic style `build-project-index.sh` uses. Exit `0` on a
    successful scan, `1` on a write failure, `2` on a usage, schema-load or environment error.

**No node count is stated here or anywhere else in this SPEC, deliberately.** The 2026-07-28 revision
closed with a "Sanity check against A-5" that estimated several hundred nodes and concluded the figure
sat in A-5's assumed band. **That block is deleted.** A-5 is void (Q12); the "583 source artifacts"
figure it leaned on is inherited from research known to contain fabricated figures and is not
reproducible against this repository; and NFR-7's bench is explicitly a research finding that "states no
node count." What this SPEC guarantees instead is that the rules above are **enumerable and total**, so
the count is something feature-002's research can *measure* on any target project rather than something
the requirements grant. NFR-8's ceiling warning consumes that measurement and is feature-010's (Open
Item 7).

### Layers & Components

New files, plus one additive change to an existing shared script. Authored in `canonical/`, then
rendered by the FULL `run_generator.py` — never hand-edited under `profiles/` or the dogfood `.claude/`
(C-2; `module-map.md` Invariants). `canonical/aid/scripts/` and `canonical/aid/templates/` are both
recognised asset kinds in `canonical/EMISSION-MANIFEST.md`'s "Asset Kinds" table, so the `graph/`
subdirectory renders into all five profiles with no renderer change; the per-profile
`emission-manifest.jsonl` records regenerate in the same run and the render-drift CI job gates the
result (C-3). `canonical/aid/templates/graph/` already exists on disk (holding feature-001's
`relation-vocabulary.yml`), while `canonical/aid/scripts/graph/` is new — both verified 2026-07-29.

| Layer | Path | Purpose |
|-------|------|---------|
| Script (the walk) | `canonical/aid/scripts/graph/scan-source.sh` | the single traversal; owns exclusions, kind classification, granularity, qualification, external enumeration, the four data streams, and the coverage contribution |
| Script library | `canonical/aid/scripts/graph/significance-rules.sh` | sourceable predicates — one function per D3 mechanism, per D4 class, plus D2a's kind classification, **D2's ordered `artifact_class` rule list**, **D3a's carrier → `qualifier` map and its precedence comparison**, **D3b's per-carrier evidence-string renderer (one function, the templates and the token-formation rule in one place, so no caller composes a string itself)**, **D3a's evidence candidate-set enumerator and, as a separate function, its `LC_ALL=C`-least selector** and D4a's three-state probe result — so the scanner and its test suite exercise the *same* code, not two readings of the rule. The `artifact_class` list lives here rather than inline in the walk because its correctness is entirely about **rule order**, which is testable only if the ordered list is callable; the `qualifier` map is here for the same reason, plus one of its own — the precedence comparison (`strongest applicable clause`, including the P3 → P2 promotion) is the one predicate a reader cannot verify by inspecting the walk, since its two halves execute in different passes. **The evidence enumerator and the selector are two functions, not one**, and deliberately so: the test recomputes the candidate set from the enumerator and checks the scanner's emitted string for membership and minimality against it, which a single combined function would make circular — feature-003 separates `rel_coverage_extra_keys` from its emitter for the identical reason. **What that separation buys is bounded and stated where the claim is made** (D3a): both sides read the same enumerator, so the pair decides the *selector* and cannot see an enumerator that omits a carrier — which is why the fixture also carries a golden expected value that no function here produces |
| Script *(feature-003's file — read, not created here)* | `canonical/aid/scripts/graph/relationship-schema.sh` | `rel_load_schema` for `image_extensions:` and the `Kind` enum (feature-003 D9) |
| Script *(existing — additive change, **owned and implemented by this feature**)* | `canonical/aid/scripts/config/read-setting.sh` | gains `--probe`: prints `declared`/`undeclared` on stdout using the same `lookup`/`lookup_list` scanners, and warns on **stderr** for any raw list item containing a comma (D4a). No existing mode changes, and no exit code changes. Ownership is decided, not deferred — see D4a's ownership table; only the *settings-schema* half is feature-010/012's (Open Item 5) |
| Settings | `canonical/aid/templates/settings.yml` | seed the `graph:` section with a commented-out `ignore:` list (D4a) |
| Test | `tests/canonical/test-source-enumeration.sh` | per-clause qualification, per-class exclusion, the granularity cut, fixed-point settling, all **three** ignore-list states (AC-S7), byte-identical re-run on an unchanged fixture tree (AC-S8), **D3a's `qualifier` assignment** (AC-S9): every one of the four declared values emitted on at least one row, one fixture per Q1/Q2/Q3/Q4 carrier family, the **promotion** case — a `named-unit`-carrier path that is also referenced emits `depended-upon` with `derived` evidence — the P1 tie-break case **in the one shape that distinguishes clause-order from provenance-order**: a path whose *only* Q1 carrier is the **derived** executable header and which also carries a **declared** Q2 carrier emits `entry-point` **with the shebang line as its `evidence` and `derived` as its `evidence_provenance`** — asserting the evidence pair as well as the value is what makes the row fail under the rejected `declared`-across-clauses reading instead of passing under either, which is the defect the row exists to catch — plus the plain both-carriers-declared tie-break, the Q1-over-Q3 case (a shebang-carrying `test-*.sh` emits `entry-point`), a **surviving** `named-unit` (convention-named, no P1 carrier, no inbound reference), and a re-run assertion that the promotion is byte-stable; **the evidence-selection rule (D3a §The evidence selection rule, AC-S9) on two deliberately multi-candidate rows** — a path matching **two** `declared` carriers inside one clause, and a path receiving resolved inbound references from **two** citers — each asserted three ways: the two-clause check against the **separately recomputed** candidate set (the row's `evidence` is a member, and no member sorts before it under `LC_ALL=C`), never against the selector's own answer, so an implementation that emits the first candidate its traversal reaches fails rather than passes — and, because both of those clauses read the same enumerator and so cannot see a **missing** carrier, a third check that reads no scanner function at all: **the emitted field 5 equals, byte for byte, the literal in `fixtures/graph/expected-evidence.tsv`** (D3a, D3b). The golden file is also asserted for one single-candidate row per D3b template, which is what tests the formatting contract itself; single-candidate rows remain insufficient for the first two clauses, since both are vacuous on them; and **D2's `artifact_class` assignment**: every emitted row carries a value; a `depended-upon`-only path carries one; the ordering pairs that would break under an unordered list (a `.py` under `dashboard/`, a `.sh` under `tests/`, a `.md` under `canonical/aid/templates/`) each resolve to the located class; and a path matching no shipped rule resolves to the `source` catch-all |
| Test | `tests/canonical/test-graph-media-nodes.sh` | the media half: an image classified **before** significance and never emitted as a `source-artifact` (AC-S5); an **unreferenced** image that is still a node (AC-S6); an image member of a collapsed skill directory that survives the collapse (D2a); an **upper-case** extension classified `image` and not `source-artifact` (D2a point 5 — the rule is otherwise specified but unexercised, since no repository path folds case), **with its emitted `evidence` asserted byte-for-byte against the same `expected-evidence.tsv` golden file, rendering the extension in its folded form (`'png'`, not `'PNG'`) while `<path>` keeps the path's own bytes** — the one place the fold is visible in output (D1a); the two node streams disjoint by path; an `ext:` registry with resolvable and unresolvable keys (Q4 fixture); an **empty** registry and a **missing** registry each yielding zero nodes with exit `0` (AC-19); and every `ext:` node emitted as `web-page` under tier B |
| Test | `tests/canonical/test-graph-coverage-notes.sh` | D7's contribution: all three fixed `kind` rows present with the carrier-instance predicate, including the case that distinguishes it from the old one — **a fixture whose paths all survive exclusions but qualify under no clause yields `source-artifact` `present` with a count of `0`** and a non-zero `source-artifact-dropped` note; the `image` row carrying the **tier-B** note string while every `ext:` node is a `web-page` — the pair that keeps the note honest (D7) — all three `exclusion` rows present, the `ignore-list` row distinguishing all three D4a states plus the comma-split note variant, both additional rows emitted, fixed row order, and no timestamp anywhere (AC-20, AC-19) |
| Test | `tests/canonical/test-graph-single-scanner.sh` | the seam guard — no second repository traversal under `canonical/aid/scripts/graph/`; a library import is not a traversal |
| Test | `tests/canonical/test-graph-node-partition.sh` | the KB-side and `int:` node sets are disjoint, over **both** streams (D4 Class 4) |
| Test | `tests/canonical/test-graph-node-provenance.sh` | the `no-inferred-node` invariant (D3) over **both** streams, and no `node`-kind candidate appearing as a `node_id` in either |
| Test *(existing — extended)* | `tests/canonical/test-read-setting.sh` | `--probe` returns `declared` for a declared-empty list and `undeclared` for an absent section — the distinction the existing modes cannot make (D4a) — and emits the comma warning on **stderr** for a comma-containing item while stdout and the exit code stay unchanged, which is the assertion that keeps "no existing mode changes" true |
| Fixtures | `tests/canonical/fixtures/graph/tree/` | a self-built miniature repository containing one instance of every exclusion class, **one instance of every carrier family in D3a's map — so all four `qualifier` values are emitted — plus the four cases the precedence rule exists for: a `named-unit`-carrier path that is also referenced (promotion to `depended-upon`), a path carrying a *declared* Q2 carrier whose only Q1 carrier is the *derived* executable header (the severity-neutral P1 tie-break, in the shape the two readings disagreed on — this repository supplies no surviving instance, since `generated-files.txt`'s three output paths are all cut by D4 Class 1/4, so the fixture is where this case lives, the same posture D2a point 5 takes), a path carrying both a Q1 and a Q2 carrier where both are *declared* (the plain tie-break), and a convention-named path with no P1 carrier and no inbound reference (a `named-unit` row that survives, which this repository does not supply — the D2a point 5 posture)**, **plus the two cases the evidence-selection rule exists for, both deliberately multi-candidate and both constructed so that the `LC_ALL=C`-least candidate is **not** the one a sorted-path traversal reaches — a property obtainable only because D3b's templates put the matched token ahead of the carrier path (D3a §Why the discriminating fixture is now constructible, which gives both strings in full): (i) `lib/shared.sh`, named by two fixture KB documents whose frontmatter `sources:` lists both reach it — `.aid/knowledge/alpha.md` by the **literal path** and `.aid/knowledge/beta.md` by the **glob** `lib/`, so the tokens differ and `beta.md`'s string is least while `alpha.md` is reached first (the live shape of `canonical/EMISSION-MANIFEST.md`, matched here both by its literal path and by a `canonical/` glob entry) — and receiving no inbound reference, so the Q3 evidence survives to the row; and (ii) `lib/cited.sh`, carrying no Q1/Q2/Q3 carrier and cited by two enumerated artifacts, `bin/one.sh` by the **full path** and `bin/two.sh` by the **bare basename**, so `bin/two.sh`'s string is least while `bin/one.sh` is reached first**, **plus the golden expected values that make the check independent of the enumerator: `tests/canonical/fixtures/graph/expected-evidence.tsv`, a **sibling of** `tree/` and never inside it — so the scanner never enumerates its own expectations — carrying `node_id`, `stream` and the exact expected `evidence` bytes for both multi-candidate nodes, for one node per D3b template, and for the `LOGO.PNG` media row, each cell written by hand from D3b and by no scanner function**, an image with an `image_extensions` extension that also satisfies a significance clause, an unreferenced image, an image whose extension is **upper-case** (`LOGO.PNG`, D2a point 5 — the case no repository path currently exercises), an image nested inside a collapsed skill directory, a relative `![](…)` reference with a `..` segment, a reference normalising **above** the root, a duplicated image basename, a path matching **no** `artifact_class` rule (the `source` catch-all, D2) together with the three ordering pairs above, a subtree that survives exclusions but qualifies under no clause (D7's `present`/`0` case), **four** `settings.yml` variants for D4a's three states plus a comma-containing pattern, and three `external-sources.md` variants (populated, empty, missing) |

Conventions honoured (`coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; header block with Purpose / Usage / Exit codes; `-h|--help` re-printing a slice
  of it (`build-project-index.sh` uses `sed -n '2,17p' "$0"`).
- `set -euo pipefail` for the scanner (it writes files, so a failed step must abort); `set -eu` for the
  sourceable library, with no import-time side effects.
- Argument parsing via the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with `shift 2` per
  flag; unknown flag → stderr + exit `2`.
- Settings read only through `read-setting.sh` — never a hand-parse of `settings.yml`
  (`module-map.md` Invariants). D4a's probe is a mode **of** that resolver for exactly this reason.
- `image_extensions:` and the `Kind` enum are read through feature-003's loader, never copied. No
  extension literal and no `Kind` literal other than the constant `source-artifact` appears in this
  feature's code — a reviewer can prove it by grepping the `graph/` script tree.
- No new exit code is invented; `0`/`1`/`2` reuse the documented linter/script semantics, and D4a's
  probe reports through stdout precisely to keep that true.
- Portability probes before use (`stat --version` / `stat -f` style) if any file metadata is ever
  needed; today none is, which is itself the reproducibility choice.
- `LC_ALL=C` on every sort and comparison; batched processes, never per-file forks.
- Tests are discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob, so no runner edit is
  needed. The fixture tree is self-built and references nothing under `.aid/works/`, per A-6 and the
  project's transient-work-folder rule.

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the methodology,
that owner is named and the item is **not** absorbed here. None blocks this feature's own
implementation.

1. **The gap-bearing class was keyed on the `int:` prefix, which in-repo images now share.
   Requirements half RESOLVED 2026-07-29; the consumer half remains.** *(Status updated this round.)*

   **Resolved:** REQUIREMENTS.md now re-keys both clauses from the prefix to the kind. **AC-15**'s
   lens/ledger equality binds "**`Kind = source-artifact` only**", and **FR-20**'s "source concept" is
   defined as "a node of **`Kind = source-artifact`** — not everything carrying the `int:` prefix, which
   now also includes in-repo `image` nodes", with the same reasoning this SPEC gave: an image qualifies
   **by kind** under FR-21a and therefore carries no FR-21 `qualifier` for FR-26's severity to derive
   from, so a media node structurally cannot produce a well-formed ledger row. This SPEC's text is
   written against the corrected wording, not the superseded prefix-keyed reading.

   **Remaining — and the shape of what remains is better than expected, verified rather than assumed.**
   Both consumers read **`nodes.tsv` and nothing else**, and after D1a's split that stream contains
   `source-artifact` rows *exclusively*, so **both mechanisms are already correctly keyed** — as a
   consequence of the stream split rather than by anyone's intent. What is stale is their **prose**,
   which still says `int:` where it now means `source-artifact`: feature-006's SPEC takes its candidate
   set to be "the enumerated `int:` node set (`nodes.tsv`)"; feature-007's coverage predicate is stated
   over "an enumerated `int:` node" and materialises a zero-row node with `kind: 'int'` (all verified
   2026-07-29).

   **Why stale prose is still worth an item, and why it is worth *this* item.** Open Item 7 asks
   feature-010 to widen its staleness digest to **both** streams, which is correct there. If anyone
   applies that same reasoning to feature-006's or feature-007's *candidate inventory* — a plausible
   move, since "feature-004's enumerated node set" now spans two files — the prefix-keyed prose becomes a
   live defect on the spot: the lens would highlight an unreferenced picture with no ledger row behind it,
   which is precisely the AC-15 breach the requirements correction was made to prevent. The prose is the
   only thing standing between a correct mechanism and that regression, which is why it should read
   `Kind = source-artifact` rather than `int:`. **Owners: feature-006, feature-007** (wording; neither
   needs a mechanism change, and neither is in this work's re-specification set).
2. **`nodes.tsv`'s field 3 rename and field 7 addition break no consumer — verified against both
   consumers' SPECs, not inferred from the rename's shape.** *(Verified this round; the earlier text
   asserted "prose only" without having checked how field 3 is read.)* `kind` → `artifact_class` keeps its
   position and value space, and `node_kind` is appended, so fields 1–6 are undisturbed. What the two
   consumers actually read:

   | Consumer | What it reads from `nodes.tsv` | How | Effect of the rename |
   |---|---|---|---|
   | feature-006 | `name` (field 2); `qualifier` and `evidence` | field 2 **positionally**, the other two **by name** | none — it never reads field 3 |
   | feature-007 | the id inventory; `qualifier`/`evidence` reach it via feature-006 | ids only | none — it never reads field 3 |

   **feature-007's `kind` is a different concept that merely shares the word.** Its `Node.kind` is
   one of `'kb'`, `'int'` or `'ext'`, taken from the **id prefix** and, in its own words, "never inferred from
   anything else" — including in the zero-row materialisation table, where `kind` is `'int'` sourced from
   the prefix. So the "`kind` or `qualifier`" display discussion the earlier text worried about is not a
   reference to field 3 at all, and there is no mechanism change to make in either feature.

   **The residue is a vocabulary collision, not a contract break.** Three distinct things are called
   "kind" across this document set: feature-003's `Kind` column (the node kind), this feature's former
   field-3 `kind` (the descriptive artifact class), and feature-007's `Node.kind` (the id prefix). The
   rename removes one of the three; feature-007's remains, and whether to rename it is feature-007's call.
   **Owners: feature-006, feature-007** (optional wording only; **no mechanism change in either**).
3. **The external-sources entry format must carry a media type, and until it does one arm of the kind
   cross-check is permanently unverifiable.** D1a's tier B emits every registered `ext:` key as
   `web-page` and emits no external `image` node, because feature-003 D1a establishes that `image`
   versus `web-page` "cannot be recovered from the key" and is "trusted from feature-004's node record."
   This SPEC therefore ships the conservative constant and reports the arm as `absent` in the coverage
   notes. Closing it needs a **declared media type** per registry entry — the requirement feature-003
   raised and this SPEC now depends on. `/aid-graph` may not author the format itself (FR-10), and the
   file's writer is `/aid-discover`'s ELICIT state. **Owner: `/aid-discover` ELICIT (upstream), tracked
   as feature-003 Open Item 1 and D-5.** When it lands, tier A is a **one-constant** change here: the
   same constant selects the classification predicate and the `image` coverage-note string (D7's tier
   table), so the behaviour and the sentence describing it cannot be flipped independently. Nothing else
   moves.
4. **First half CLOSED by feature-001; the coverage-row half remains with feature-005.** *(Status updated
   this round.)* **Closed:** feature-001's D6c discharges the `image-reference` mapping — it maps to the
   `illustrated-by` (S2T) / `illustrates` (T2S) pair, with the direction, `endpoint_kinds` and `passes`
   legality stated there, and `document->image`, `section->image` and `fact->image` named as legal
   endpoints. Nothing further is owed to this feature on that arm; feature-001 also records that it
   **relayed** the second arm rather than adopting it. **Remaining:** feature-005 supplies the `document` /
   `section` / `fact` / `concept` coverage rows and should use the **revised** carrier-instance predicate
   D7 now fixes, or the section will mix two definitions of `present`. The revision **narrows** what this
   arm asks for rather than widening it: the predicate is unchanged in effect for `document`, `section` and
   `concept`, and for `fact` it asks feature-005 for one decision it is better placed to make than this
   feature — whether the carrier is the `CONFIRMED` marker or the anchored marker. Marker-as-carrier turns a
   project full of unanchored markers from a false `absent` into `present` with a count of `0`
   — or, if it reads the anchor rather than the marker as the carrier, reproduces the old behaviour
   deliberately instead of by default (D7 states both readings and picks neither). **Owner: feature-005**,
   which is in this work's re-specification set.
5. **`read-setting.sh --probe` — decided; this item now carries coordination only, not a decision.**
   *(Rewritten this round; it previously called the landing undecided while the Layers table committed to
   it, which is a contradiction an implementer cannot act on.)* **feature-004 implements `--probe`**, for
   the three reasons D4a states: this feature is its only caller, AC-S7 and AC-20 depend on it existing, and
   the change is additive with no existing-mode behaviour change. What the other two features need is
   awareness, not a decision: **the mechanism will already exist**, so neither should add a second way to
   distinguish an absent setting from a declared-empty one, and the **live** `graph:` declaration with its
   `format_version` and reconcile questions remains theirs (Open Item 8). The commented-out template seed is
   this feature's and declares nothing, so it raises neither question. **Owners: feature-010 / feature-012
   — for the settings-schema change only.**
6. **Three small confirmations feature-003 owes, all stated rather than assumed. None blocks this
   feature: each has a stated fallback or a stated consequence.** (a) **V14 must tolerate a non-enum
   label in an extra coverage row's first cell.** D7 emits two additional rows (`image-external`,
   `source-artifact-dropped`) using the extension mechanism feature-003 D7a explicitly provides ("Extra
   rows below the fixed ones are ignored"); the reliance is that V14's "every enum kind appears exactly
   once" check reads only the fixed rows and does not reject an unrecognised label below them. **If this
   is declined or deferred, D7's fallback applies** — both facts move into fixed-row `note` cells, which
   V14 does not constrain — so a `no` costs presentation, not content. (b) **V13 tier 2 must fold
   extension case the way D2a point 5 does.** `image_extensions:` ships lowercase and this feature
   lower-cases before testing; a case-sensitive re-check at the validator would report a `LOGO.PNG` as a
   defect with no defect in it. The scanner side of that rule is exercised by the fixture tree's
   upper-case instance regardless of the answer. (c) **D7a's example wording for the `image` row should
   be corrected.** Its skeleton reads `image files in-repo; external image keys`, which describes a
   carrier that cannot contribute a node under tier B; D7 diverges deliberately and says why. The
   divergence is safe because V14 validates the kind, order, status and count rather than the carrier
   text, so this is a documentation correction in feature-003's own example, not a contract change.
   **Owner: feature-003.**
7. **Three things feature-010 owes, all consequences of this feature having two streams and a TSV
   contribution rather than a rendered section.** *(The third added this round.)* **NFR-8's ceiling
   warning must count both node streams, and so must feature-010's `SRC` digest.**
   feature-010's SPEC describes `SRC` as "`path + sha256` for every artifact in feature-004's enumerated
   node set." That must now include `media-nodes.tsv`'s `int:` rows, or editing an image would not
   trigger regeneration (FR-11 input 2). The same applies to the total node count AC-16a warns on, which
   spans this feature's two streams plus feature-005's Pass 1 output. **Third: the assembler owns the
   `coverage.tsv` key → rendered-label translation for the three `exclusion` rows** (D7). The `kind` keys
   render as themselves and the `exclusion` keys do not, so an assembler that passes all six through
   verbatim produces a section V14 rejects on labels this feature cannot see. **Owner: feature-010.**
8. **`graph.ignore` and the settings reconcile.** `.aid/settings.yml` declares `format_version: 3` and
   the shipped template declares neither a `format_version` nor a `graph:` section (both verified
   2026-07-29). Whether adding the section requires a `format_version` bump and a reconcile rule — the
   ground `/aid-config` and `tests/canonical/test-reconcile-scenarios.sh` already cover — is a decision
   for the skill-wiring feature, not this one. This feature requires only that the patterns resolve
   through `read-setting.sh` and that availability be probeable (D4a). **Owners: feature-010 /
   feature-012, plus the settings-schema change itself** (STATE.md Q6, D-4).
9. **`.aid/connectors/*.md` visibility.** Excluded by D4 Class 4 as per-project state. If the owner
   wants connector descriptors in the graph, they are one allowlist entry away. **Owner: the work owner.**
10. **`site/` depth.** `site/src/**` is a large, conventionally-organised Astro tree with no AID-authored
    naming rule to key on, so most of it will qualify only via `depended-upon`. That is the correct
    conservative outcome, but it means the graph's site coverage is thinner than its toolkit coverage —
    worth stating before feature-006 reports it as a gap cluster. Note the site's images are unaffected:
    they enumerate by kind regardless (D2a). **Owner: feature-006** (gap-cluster phrasing).
11. **The re-specification left three stale *cross-references* outside this SPEC — and they are not the
    ones this item previously claimed.** *(Corrected this round: the earlier text asserted that PLAN.md
    and delivery-002's BLUEPRINT "carry the old title string". They do not. A repository-wide search for
    "Structural Significance" returns only this SPEC's own change log and this item, verified 2026-07-29;
    every sibling document refers to the feature by its **folder id**, `feature-004-source-enumeration`,
    which the retitle did not change. The retitle therefore needs no reference update at all, and the
    claim that it did was itself an unverified assertion of the kind this section exists to prevent.)*

    What the re-specification *did* break is **Open Item numbering**. This section was renumbered, and
    three sibling documents cite the old numbers (all verified 2026-07-29):

    | Citing document | Cites | For | Now |
    |---|---|---|---|
    | `PLAN.md:86` | feature-004 Open Item 1 | the `graph.ignore` settings-section and reconcile question | Open Item 8 |
    | `deliveries/delivery-002/BLUEPRINT.md:130` | feature-004 Open Item 1 | the same question, as a delivery gate criterion | Open Item 8 |
    | `deliveries/delivery-002/tasks/task-017/DETAIL.md:103` | feature-004 Open Item 2 | `.aid/connectors/*.md` not being allow-listed | Open Item 9 |

    Each now points at a different item than the one it means — the first two at the AC-15 re-keying, the
    third at the field-3 rename. Nothing mechanical breaks, but a reader following the citation lands on
    an unrelated finding, and the BLUEPRINT's entry is a **gate criterion**, so a reader checking it off
    would be checking the wrong item. Q14's amendment-sequencing decision hand-amends PLAN.md rather than
    patching regenerated artifacts, so this belongs to that pass. **Owner: whoever performs the PLAN.md
    amendment** (precedent: feature-011 was renamed and retitled the same way on 2026-07-28).
12. **A project-declared `artifact_class` extension, recorded as the path but deliberately not built.**
    *(New this round.)* D2's rules key on AID's own authoring conventions, and the `source` catch-all is what
    makes the enum total for a project AID did not author. Finer per-project classes would need what
    feature-001's `coined` token has and this field does not: an extension file with a fixed location, a
    loader, precedence rules and a validator (feature-003 D4). Verified 2026-07-29, `artifact_class` has
    **no consumer** in any sibling SPEC and **no validator**, because it never reaches `relationships.md` —
    so building an authoring surface now would add a thing to maintain that nothing reads. Recorded so the
    decision is visible rather than looking like an oversight, and so the precedent to copy is named if a
    consumer ever arrives. **Owner: whichever feature first needs a class the shipped rules do not name**
    (feature-006 phrasing or feature-007 grouping are the likely candidates).
13. **A zero-row media node has no durable carrier, and the carrier it must NOT be is `kb_gaps`.**
    *(New this round — routed here by feature-006's re-specification, recorded at STATE.md Q22 as a
    reopen candidate co-owned by the owner, feature-003 and this feature. Routed rather than absorbed,
    because closing it means adding a key to a schema this SPEC treats as an immutable input.)*

    **The gap, stated in terms of this feature's own outputs.** `relationships.md` holds **rows**; a node
    exists in it only as an endpoint of a row. This feature emits media nodes **by kind** (FR-21a), with
    no requirement that anything reference them — AC-S6 makes that explicit, and FR-14a's orphan toggle
    exists to surface exactly such nodes. So the two node classes this feature can legitimately emit with
    **zero rows** are an in-repo `image` no artifact references and a registered `ext:` key no document
    cites. Both are required to exist and neither survives into the durable artifact, which means the
    guarantee AC-S6 makes on this feature's outputs stops at this feature's outputs — the wording AC-S6
    already carries, and this item is why that hedge is there.

    **`kb_gaps` is the wrong carrier, for one semantic reason and one mechanical one.** *Semantic:* it is
    the frontmatter key feature-006 writes for the gap findings whose class FR-20 and AC-15 were
    **re-keyed to `Kind = source-artifact`** on 2026-07-29, precisely so an undocumented picture is not
    reported as a KB gap (Open Item 1) — and a media node carries no `qualifier` for FR-26's severity to
    derive from (D1a), so the row would be ill-formed as well as wrong. *Mechanical, verified in
    feature-007's SPEC on 2026-07-29:* its loader materialises zero-row nodes **from `kb_gaps`** (its D10),
    and its own criterion GV07 fixes such a record's `kind` to `source-artifact`. So `kb_gaps` could not
    carry a media node even if someone routed one through it — the consumer would relabel it as the very
    class FR-20 says it is not.

    **Two sibling SPECs already record the same finding, and both reach this conclusion**, which is what
    makes it a real gap rather than a reading — all verified on disk 2026-07-29: **feature-007's Open Item
    3** states that such a node "cannot be drawn", that "making them drawable would need a frontmatter
    carrier for zero-row media nodes", and that its coverage panel telling the reader they exist is the
    current mitigation. **feature-006's Open Item 7** states its own position — **"not adopted into
    `kb_gaps`"**, because "every `kb_gaps` consumer derives severity from a `qualifier` that a media node
    structurally cannot carry", so putting media ids there "would reintroduce the prefix-keyed defect
    through the frontmatter instead of through the predicate" — and specifies the shape the carrier must
    have if the owner wants it: **a separate key, with its own shape and no severity**. This item is this
    feature's half of that same one, not a fourth issue, and it agrees with both.

    **What this feature can supply with no change of its own, and what it cannot.** `media-nodes.tsv`
    **is already the complete, byte-stable list** of every media node this run emitted, and Open Item 7
    already requires feature-010 to read it, so the *content* exists and needs no new production here. What does not exist is a **frontmatter key in `relationships.md`** to carry it, outside the
    byte-identity boundary the way feature-003 already reserves for `kb_gaps`. This SPEC does not invent
    it: naming a key in feature-003's schema is the silent divergence the routing discipline exists to
    prevent, and the same gap exists for a zero-row **`source-artifact`**, so whether the carrier is
    media-only or node-kind-general is a schema decision rather than this feature's.

    **Consequence if it does not land**, stated so the choice is visible rather than defaulted into: an
    unreferenced in-repo image and an uncited registered key exist in the graph's node set and are absent
    from its picture, discoverable only through the coverage-note counts D7 supplies. Nothing in *this*
    feature's acceptance criteria fails — AC-S5/AC-S6 are checkable on `media-nodes.tsv`, which is why
    AC-S6 is worded that way — so this is a completeness decision about the artifact, not a defect in this
    stream.

    **Owners, reconciled — the three records name overlapping sets and each is right about a different
    half.** STATE.md Q22 lists the owner, feature-003 and feature-004; feature-007's Open Item 3 lists the
    owner, feature-006 (the frontmatter writer) and feature-004 (the media stream); feature-006's Open Item
    7 lists the owner, feature-003 (a second reserved key in the frontmatter contract) and feature-004 (the
    media stream as its source), with itself as the writer. Composed: **the work owner** decides whether
    zero-row media nodes are carried at all; **feature-003** owns the second reserved frontmatter key,
    outside the byte-identity boundary as `kb_gaps` already is; **feature-006** is the writer;
    **feature-007** is the consumer; **feature-010** assembles; **this feature is the source** and supplies
    `media-nodes.tsv`, which it already produces — so **it needs no change here and makes none**. Both
    sibling items note that scheduling the decision **reopens and re-gates** the gated SPECs it touches;
    on the composition above this SPEC is not one of them, since its contribution is existing content.
14. **This revision discharges feature-006's Open Item 2 in full, and does not reopen feature-006 —
    which feature-006 itself pre-declared.** *(New this round.)*

    **Its item, verified on disk 2026-07-29, asked for exactly two things** and named this feature as the
    owner, "gated A+; scheduling this reopens and re-gates that SPEC" — which is the reopen this revision
    is: **(a)** "state the carrier/mechanism → `qualifier` mapping as a total function" → **D3a's carrier
    map**, which covers every carrier and mechanism D3 names, including the `declared` carrier table that
    "has no qualifier column" and the `convention` membership that "states only the `artifact_class` it
    implies"; **(b)** "state whether the step-8 evaluation order … is **severity-monotone**, or record that
    it is not" → **D3a's monotonicity section**, which answers *yes, by construction, and no, it was not
    before* — including the concrete case its item predicted, "an entry point that first matches a
    `declared` carrier or a naming convention takes that qualifier and is ranked below its consequence".

    **Why no reopen of feature-006 follows, in its own words.** Its Open Item 2 states the interim:
    "the detector reads whatever value the record carries and maps it; it invents nothing, and a value
    outside the enum is exit 2 (AC-G3), so **nothing changes here when the mapping lands**." This revision
    changed how field 4 is *assigned* — not its name, its position or its value space — so:

    | What feature-006 does | Effect of D3a |
    |---|---|
    | maps all four values to a severity (`entry-point`/`public-surface` → `[HIGH]`, `depended-upon` → `[MEDIUM]`, `named-unit` → `[LOW]`) | **all four keys are now reachable**; the function was already total and is now total over a domain the producer can actually populate |
    | withdrew a "highest applicable severity" tie-break as unimplementable, because this feature assigns exactly one qualifier per node | **the withdrawal becomes more correct, not less**: exactly one qualifier still holds, and the maximum it wanted is now computed **at the producer** under D3a's precedence. It must **not** be re-added — a consumer-side maximum over a single-valued field has nothing to range over |
    | reads `qualifier` by name from `nodes.tsv` (Open Item 2) | unchanged — same field name, same position, same value space |

    **Two things it should take from this, both routed rather than decided here.** *(Lettered `(i)`–`(iv)`
    below so they cannot be confused with feature-006's own parts `(a)` and `(b)` quoted above.)*
    (i) **Its severity
    function must stay monotone in D3a's precedence (P1 > P2 > P3) *and* constant on P1** — the second
    condition being the one the precedence itself does not supply, since P1 holds two values and the
    Q1-before-Q2 tie-break sits inside it. Its function satisfies both today (`entry-point` and
    `public-surface` both `[HIGH]`), and the guarantee that no node under-reports a severity is stated
    relative to those two properties, not to the particular labels: a later function that splits P1
    would void it, which is why the hypothesis is written down rather than assumed. (ii) A shebang-carrying `tests/canonical/test-*.sh` emits `entry-point` and therefore `[HIGH]`,
    because it *is* invoked (FR-21 clause 1's own example) and precedence prefers the stronger clause.
    Whether `[HIGH]` is the ledger priority a reviewer wants for a test file is feature-006's phrasing
    call, and `artifact_class` = `test-suite` is available to it as the discriminator (D2 names its gap
    phrasing as that field's intended consumer). **This SPEC will not distort field 4 to manage ledger
    volume** — doing so would reintroduce the non-monotone assignment D3a exists to remove.

    **Two prose updates it does owe, both of the stale-cross-reference class this SPEC's own Open Item 11
    covers, neither a mechanism change and neither making anything it asserts false.** (iii) Its D4 quotes
    feature-004 D1 as saying "when more than one clause qualifies it, the **first-matching clause in the D3
    evaluation order wins**" — a sentence this revision replaced with the precedence rule. Its
    *conclusion* from that quotation survives intact and unchanged (the record carries exactly one
    qualifier, so "multiplicity is resolved upstream" and the old tie-break stays void); only the quoted
    words moved, and the upstream resolution is now a **maximum** rather than a first match, which is
    strictly what its withdrawn tie-break was reaching for. (iv) Its Open Item 2 can be closed as
    discharged, and its closing sentence — "this feature's severity rank is exactly as good as
    feature-004's evaluation order, and that order is Open Item 2" — now has an answer to point at.

    **A provenance note kept deliberately.** When this revision began, feature-006's SPEC file was not yet
    on disk (it was being re-specified concurrently) and **STATE.md Q22** was the only verifiable record of
    its severity mapping; the file landed mid-revision and every citation above is now read from it
    directly. D3a's guarantee is nonetheless stated over the **monotonicity property** rather than over
    those four labels, so a later relabelling changes what must be re-checked and not whether the
    guarantee was ever true. **Owner: feature-006** (wording and item closure only).
