# KB Gap Ledger And Routing

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.9 (FR-20, FR-25–FR-27), §2 item 1, §7 (C-6), §9 (AC-14, AC-15) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Finding 1 [CRITICAL] fixed — the coverage predicate is now a single shared module; `kb_gaps` demoted to a verified generate-time record; `kb:`-unbacked confirmed lens-only *(prefix-keyed claim **superseded** 2026-07-29 and annotated 2026-07-30: the lens-only signal's domain is now `Kind ∈ {document, concept}`, `section` is out, and an unbacked `fact` is an **integrity warning** rather than a coverage signal — proxy-sweep row 4, D6a. That the signal is lens-only with no ledger row is unchanged)*. Finding 2 [HIGH] fixed — D3 F4 restated as an invariant owned by feature-004, not a filter applied here | /aid-specify |
| 2026-07-28 | Owner corrections applied: (1) the shared predicate module is repointed to `canonical/aid/scripts/graph/coverage-predicate.mjs` per feature-007, and the `package.json` ESM-marker requirement is **deleted**; (2) the zero-row-node residue is **closed** — gap detection now runs over feature-004's enumerated node set, so an `int:` node with no table row becomes a `kb_gaps` entry and a ledger row *(prefix-keyed claim **superseded** 2026-07-29 and annotated 2026-07-30: as written it is now **false**, because an in-repo `image` is also an `int:` node and never becomes a `kb_gaps` entry or a ledger row — D4 case 1 and AC-G2 exclude it. The clause holds for `Kind = source-artifact` only; the zero-row closure itself stands)*, and `kb_gaps` entries gain `name` | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the render and manifest lockstep is now **feature-012**'s and the ship-time Knowledge Base update is **feature-013**'s, in the Layers preamble, L3 and Migration steps 3–4. No decision in this SPEC changes | /aid-specify |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles then three reopens; STATE.md Q9–Q21) and against the A+ contracts of features 003, 004 and 005, consumed as immutable inputs.** The central change is that **this feature's gap class was keyed on the `int:` prefix and is now keyed on `Kind = source-artifact`** (FR-20, AC-15, and FR-13's Coverage lens, all re-keyed by owner decision; Q17's sixth proxy instance and its third `int:`-for-`source-artifact` substitution). feature-004 verified the *mechanism* was already correct — `nodes.tsv` holds `source-artifact` rows exclusively after its D1a stream split — so what changed here is that the keying is now **explicit, asserted at the input, and testable** rather than incidentally right: D1a states the field map through which `node_kind` is read as data, and the detector rejects a candidate row of any other kind. Nine further changes follow from it, none cosmetic. (1) **Severity now derives from feature-004's four-value `qualifier` field**, not from "the FR-21 clause", and the old **highest-applicable-severity tie-break is void** — feature-004 assigns exactly one qualifier per node, so a tie-break here was unimplementable and contradicted a gated contract. (2) **A node with no qualifier is enumerated in three cases and none of them yields a row**, which is the load-bearing reason the class is a kind and not a prefix (D4). (3) **The lens/ledger asymmetry is stated rather than left implicit** (D6a): the ledger's class is `Kind = source-artifact`, the lens additionally signals unbacked `{document, concept}` with **no** ledger row, an unbacked `fact` is an **integrity warning** and not a coverage gap, and `section` is out. (4) **`COVERAGE_BEARING` is selected here, at pair granularity, from a complete enumeration of the thirteen vocabulary pairs that can join a KB node to a source artifact** — discharging feature-001 Open Item 8 and feature-005 Open Item 9. Category granularity is shown to be *inexpressive*, not merely coarse: `documentation` holds one coverage-bearing pair and one that disclaims coverage in its own definition, and `annotation` disclaims it too. (5) **The retention carve-out written into the shared ledger schema is withdrawn** — Q8/D-6 lift ledger retention out of this work into its own methodology item, and writing it locally is exactly the workaround that decision removed; D7 now states the interim shortfall, including that `Fixed`/`Recurred` are **unreachable** until D-6 lands. (6) **`Evidence`'s recheck command is replaced** — the old `grep -c 'int:<path>' = 0` is *false* for a node whose only rows are `mentions` edges and would read as contradicting its own row. (7) The export is `detectArtifactGaps` and the set is `artifactUndocumented`, per feature-007's re-specification. (8) **`kb_gaps`'s `clause` key is renamed `qualifier`**, values unchanged, because `clause` named FR-21's three clauses while the data carries four values. (9) **A false-gap class is admitted rather than excluded** (F6): a project extension cannot widen `COVERAGE_BEARING`, so an artifact covered only by an extension pair is a false gap; it is **measured by a per-run counter** rather than described, and routed. Struck: every "eight-column" claim, every prefix-keyed claim about the gap class, and the shared-schema retention amendment. Discharged inbound: feature-001 Open Item 8; feature-004 Open Items 1 (consumer half), 2 and 10; feature-005 Open Items 7 (the ledger half, declined with reasons) and 9; feature-007 Open Items 5 and 6. Nine Open Items routed, each with its owner and — where the owner is gated A+ — the reopen-and-re-gate consequence (Q18 ruling 3, Q20 (loader sync)). No measured figure is asserted anywhere: every number here is a contract count or an enumeration made on the spot | /aid-specify |
| 2026-07-30 | **Fix pass after the first A+ gate — 14 counted findings closed, none deferred, no mechanism reversed.** *(Gate grade `D`; ledger `.aid/.temp/review-pending/feature-006-spec.md`: 2 HIGH, 6 MEDIUM, 4 LOW, 2 MINOR, plus one row routed OOS to feature-010.)* The gate's own lesson is recorded because it explains the shape of the whole pass: **both HIGH findings were ordering artifacts of the wave rather than authoring errors** — this SPEC was drafted against feature-004's *previous* revision and faithfully described a contract that had ceased to exist by the time the gate ran (STATE.md **Q25**). Hence the two largest changes are both **expired cross-references**, the Q20 (loader sync) class, in opposite directions. (1) **Open Item 2 is closed as discharged and moved to the Discharged list**, with every consequence that followed from its being open stripped: feature-004's D3a now supplies four assigning rules and a carrier → `qualifier` map **total over D3** (its SPEC.md:1019–1050) plus the direct monotonicity verdict (:1265–1301), so the claims that `public-surface` and `named-unit` "have no producer stated anywhere" and that half this feature's severity domain is unreachable were **false on disk**, and the "scheduling this reopens and re-gates that SPEC" consequence is withdrawn — it would have demanded a reopen of work already delivered (feature-004's own Open Item 14 asks for exactly this closure, :2326–2374). D4's stale quotation of feature-004 D1 — "the first-matching clause … wins", the exact **negation** of the gated precedence rule (:405–411) — is corrected, and its conclusion, which never depended on the misquotation, stands. (2) **`RELATION_CATEGORY` moves from `graph-model.js` into `coverage-predicate.mjs`** (owner decision, STATE.md Q25 item 2): L2 had claimed the shared module "already exports" it, while feature-007 places it in a browser-only file D6 forbids the Node side importing (:291, :1334, :1434; its export table at :1103–1110 omits it) — so the F6 counter had **no reachable data source**, and the claim contradicted this SPEC's own coordination obligation 3. Restated as a **move between two feature-007 files**, with GV05 becoming checkable inside one file and GV01 unaffected on both sides; routed as Open Item 4. (3) **A new Open Item 3 records the correction feature-010 owes** — its DONE and `--reset` clauses retain `graph-kb-gaps.md` citing "feature-006 §D7", an authority this SPEC **withdrew** (Q22). **D7, AC-G6 and Open Items 1 and 2 are correct and unchanged**; the defect was a *missing route*, and per Q8 the fix is neither adopted here nor written locally. **Owner: feature-010 — ungated, no reopen consequence.** (4) **The derived `[HIGH]` for a test suite stays and the worked example is corrected** — a shebang-carrying `tests/canonical/test-*.sh` is `entry-point` under D3a (:1321–1328), so the `kb_gaps` example's `named-unit`/`LOW` was one gated rule applied two ways in one block; feature-004 Open Item 14(ii)'s phrasing call is now answered in D6: `[HIGH]` is **intended**, and the `artifact_class` discriminator is declined because a carve-out would break D4's totality and manufacture the under-reporting incentive. (5) **F2's ancestor condition is kept and its necessity argument deleted** — the predicted dogfooding flood is false under **both** readings of the `sources:` carrier, so the row now rests on **totality** and states that the condition is currently unreachable; GL02's fixture must construct the shape. Also: the `--explain` recheck gains the two arguments it always required and its scratch precondition (D5, GL16); `int:canonical/aid/scripts/summarize/` gains its directory-marking trailing `/` (F2); D5's `Status` cell now quotes the schema's three *different* actor rules instead of one (:94–96); `media-nodes.tsv` is stated as a **suite-level** input with no detector flag (D1, step 3, GL15); **GL20** is added so FR-27's routing hand-off is asserted rather than only specified; D2a's "none of them a whole category" is corrected (`evidence` is taken whole); two 2026-07-28 change-log entries are **annotated** where they assert superseded prefix-keyed claims, per the Q20 (A-5 figure) precedent of annotating rather than deleting; and the "Discharged here" list gains feature-004 Open Item 14 and feature-007 Open Item 6, whose omission defeated the list's own purpose. **Proxy sweep re-run: rows 6 and 9 extended, five rows (14–18) added** — an authorization rule standing in for three, an export name standing in for the file that declares it, a feature standing in for one of its components, a summary standing in for its enumeration, and a predicted instance standing in for a structural property. All five were found by the gate, not by the author's sweep, which is recorded with its lesson. **Open Items: still nine** (one closed, one added, the survivors renumbered with a numbering note, since other features cite these numbers). No count that **is** a contract was weakened (Q19) | /aid-specify |
| 2026-07-30 | **Second fix pass after the re-gate — six findings (1 HIGH, 1 LOW, 4 MINOR) closed; cycle 1's fourteen were re-verified closed rather than assumed, and nothing below touches one of them.** *(Gate grade `D+`; same ledger, rows 16–21.)* *(Reading note, because it has already misfired once: every withdrawn string quoted in this row is quoted **only** here, as the record of what was struck, and is asserted **nowhere** in the SPEC — the live text is named beside each. Verifying this pass by counting occurrences of a struck phrase instead of reading them is Q20 (A-5 figure)'s own documented failure mode, and it produced three false "still open" verdicts against this row.)* The lesson first, because feature-003's second cycle recorded the identical one and two instances make it a pattern: **every one of the six sat in prose the *first* fix pass wrote.** New prose is unreviewed prose — so this pass is clause surgery, introduces no subsection, and five of the six are single corrections. **Row 16 [HIGH], the substantive one — Open Item 7 demanded a reopen its own target had already refuted.** It named feature-003 *and* feature-004 as "both gated A+; scheduling reopens and re-gates both", but feature-004's Open Item 13 quotes this item by name, reconciles all three owner records (STATE.md Q22, feature-007's Open Item 3, and this one) and concludes that as the **source** of `media-nodes.tsv` — content it already produces — "it needs no change here and makes none … on the composition above this SPEC is not one of them" (its SPEC.md:2315–2325). The item now **adopts that composition** instead of restating a competing one: the work owner decides; **feature-003 keeps its reopen consequence**, because a second reserved frontmatter key is a D8 change it nowhere disclaims; this feature is the writer, feature-007 the consumer, feature-010 assembles, and **feature-004 is the source with no reopen**. The defect was worse than a stale cite: the Discharged list below already said "No reopen of feature-004 is scheduled or needed", so **the document asserted both**. Same false-reopen class as the former Open Item 2 (cycle-1 row 1), **one item over, left standing by the pass that closed it** — so all nine items were swept, and the only surviving reopen consequences (Open Items 6 and 7, both feature-003) are unrefuted on disk: feature-003 mentions this feature at :63, :1205, :1640 and :1930–1931 and addresses neither. **Row 17 [LOW] — GL20 misattributed its own obligation.** It claimed "the ticket half of AC-13" and a "Knowledge-Base-modification half"; AC-13 has one half and no ticket clause at all ("No KB file is modified by any run", REQUIREMENTS.md:951), and the no-ticket obligation is **§4 Out of Scope**'s (:166, `ticket`'s only occurrence in that document), which § Source already attributed correctly. Re-attributed at both ends of the row, and the change-log clause announcing GL20 with it; the assertion GL20 makes was right and is unchanged. **Row 18 [MINOR] — F2's one line-numbered feature-003 citation drifted** across that SPEC's second re-specification; the trailing-`/` directory-artifact sentence it quotes is now `:839`. Every other feature-003 reference here is section-only and was re-verified against the current file (D1 :239, D1a :334, D2 :387, D2b :830, D4 :934 with the flush points it relies on at :1144–1146, D7 :1284, D8 :1579, V13 :1785). **Row 19 [MINOR], the only mechanism row — GL13 asserted a suffix D5 does not emit.** D5's zero-row form closes its parenthesis *after* the clause, so the emitted `Description` ends `table)`; GL13's suffix omitted the `)` and would have failed against a correct implementation. Aligned on D5, which is unchanged and stays the single authority — the two are the only sites stating that string. **Row 20 [MINOR] — a KB citation named the wrong section for the right line.** `coding-standards.md`:104 mandates `#!/usr/bin/env bash` inside **§ Shell (Bash) Conventions** (:102); § File Header Convention (:61) mandates the Purpose/Usage/Exit-codes block and says "not just a shebang" — which is the rule L2 cites it for, correctly. Label fixed; line, rule and conclusion unchanged. **Row 21 [MINOR] — a measured figure deleted rather than corrected.** The first pass' change log quantified the interval between this SPEC's drafting and the landing of the feature-004 fixes that superseded it. It was wrong against the timestamps its own cited source gives *and* — decisively — a **measured quantity**, which § Figures asserts appears nowhere in this SPEC; so its presence falsified this SPEC's own claim, and correcting the arithmetic would have left it falsified. The clause now says the drafting preceded the fixes and quantifies nothing; § Figures records the removal and adds `no duration` to what it asserts absent. STATE.md **Q25** carries the arithmetic and its own correction — this SPEC carries neither. Swept for siblings: no other unit-bearing quantity is asserted here — the Description's "fifty gaps" and S2's "five hundred" are hypotheticals, the gate ledgers' severity counts are reproducible from the ledger cited beside them, and feature-001's 31 pairs is a contract count at its SPEC.md:643. **One correction not on the ledger: every bare `Q20` citation now carries its subject suffix** — two STATE.md entries share that number, and the entry above cited **both** of them bare in one row. **Nothing else moved:** D7, AC-G6, Open Items 1 and 2, the `RELATION_CATEGORY` move, the derived `[HIGH]` for a test suite, and F2's ancestor condition with its unreachability statement all stand as the owner settled them (Q25); the proxy sweep stays **eighteen** rows and the Open Items **nine**; and per Q26 the five **editorial** rows were fixed here rather than queued because this SPEC holds no gated grade to chase — it was already open for row 19, which is **mechanism** — so "collect, not chase" bounds nothing here | /aid-specify |
| 2026-07-30 | **Third fix pass after the cycle-3 gate — two findings (1 LOW, 1 MINOR) closed; the twenty findings of cycles 1 and 2 were confirmed `Fixed` by that gate rather than re-litigated here, and nothing below touches one of them.** *(Gate grade `B+`; same ledger, rows 23–24.)* The lesson has now held **three cycles running**, which stops it being a coincidence: **both findings sat in prose an earlier pass wrote** — row 23 in the scratch-precondition paragraph the *first* pass added to D5, and its companion clause in § Description; row 24 in an Open Item the first pass renumbered. So this pass is clause surgery again: two sites corrected, one disposition added, no new subsection, no mechanism reversed. **Row 23 [LOW], the mechanism one — the interim reproduce path was stated two ways, and a reader of § Description met the false one first.** § Description and D5 said the printed command regenerates the ledger **from** the durable `kb_gaps` carrier. The command actually printed is `/aid-graph --reset`, which forces regeneration by *discarding the recomputed-digest comparison* (feature-010's SPEC.md:138) — so it **re-runs the pipeline**, FR-31's bounded agent pass included, recomputes the gap set and **overwrites** `kb_gaps` at Feature Flow step 6 instead of reading it; L2 declares no mode that could take it as input, so D5 read literally asked for a third detector mode. Both sites now carry **D7 obligation 3's** own formulation — regenerate "from durable inputs" — plus the half the withdrawn wording hid: reproducible-on-demand costs a full re-run, not a read-back, which is exactly why it is the weaker guarantee D7 already calls it. **D7 is unchanged and stays the single authority**, and AC-G6 and GL18 require only that the command be *printed* — both re-verified after the edit — so no operative artifact moves and the routing block is untouched. Swept for a third false site by reading every hit rather than counting: there is none. AC-G6 and GL18 name the command without claiming a source, D7 states it correctly, the routing block prints the carrier and the command on **separate** lines, and Open Item 3 describes only `--reset`'s actual mechanism. **Row 24 [MINOR] — the one Open Item routed into a gated document with no disposition.** Open Item 8 sends a one-clause requirements annotation to REQUIREMENTS.md while the Open Items preamble promises that an item routed into a SPEC already gated A+ "says so"; items 1–7 and 9 each say it and 8 was the only exception whose target is gated. The disposition is now stated **truthfully rather than conveniently**: a pending reopen of an A+ **already reopened four times** — the fourth on 2026-07-30 for FR-4's one-line count (STATE.md:195) — classified **editorial** under Q26, so it belongs on the § Editorial queue instead of being chased, and the reopen is **batched, not avoided**, a fifth re-gate of the document every other artifact here is graded against. Item 9 was checked and is **not** a second instance: its sibling owner feature-013 is an ungated pre-decision draft slated for fresh authoring (STATE.md:1004), so the preamble's promise does not bind it. **Nothing else moved:** every Q25 owner decision stands (D7, AC-G6, Open Items 1 and 2, the `RELATION_CATEGORY` move, the derived `[HIGH]`, F2's ancestor condition); the proxy sweep stays **eighteen** rows and the Open Items **nine**; and § Figures still asserts no measured quantity, since neither edit introduces one. **One Q26 exception, recorded so it is deliberate:** row 24 is editorial and would normally be batched, but the file was already open for row 23 — batching it would have bought a second touch of the same file and nothing else | /aid-specify |
| 2026-07-30 | **Fourth fix pass after the cycle-4 gate — one finding (1 LOW) closed; the twenty-two counted findings of cycles 1–3 were confirmed `Fixed` by that gate rather than re-litigated here, and nothing below touches one of them.** *(Gate grade `B+`; same ledger, row 25. **Q26 class: mechanism**, so it is fixed here rather than queued.)* The lesson holds a **fourth** cycle, and this instance sharpens it: the finding sat in prose an earlier pass wrote, and it is **row 23's own family** — two sites the cycle-3 sweep did not reach because that sweep keyed on the *printed command* rather than on the class. **Row 25 [LOW], mechanism — an unadopted option was described as delivering strictly more than the mechanism can.** D7's cheaper-alternative paragraph and Open Item 2 both said that stashing the previous run's `kb_gaps` before EMIT "would give `--previous` an input" and make `Fixed`/`Recurred` reachable while D-6 is open. **Both halves are false against this SPEC's own declarations.** `--previous` takes this feature's own prior **ledger** (D1's reader split, L2's two modes, D7 obligation 4), so the stash alone is not an input it can take, and synthesising a ledger from the snapshot fails on the same column the snapshot lacks. And a `kb_gaps` entry carries `id`, `name`, `severity` and `qualifier` and **no `Status`** (D6's example, L3's four-key shape) and lists only the gaps current at that run — so one snapshot gives `Pending` (present, present) and `Fixed` (present, absent) but leaves absent-then-present **indistinguishable** between a first-time gap and a recurrence, because D5 defines `Recurred` over a prior `Fixed` — a value only a previous ledger's `Status` column records — and the ledger carrying that row was deleted at its own run's DONE. Both sites now state precisely what such a stash could and could not restore: **`Fixed` derivable, `Recurred` undecidable, and an interface change travelling with the option.** **The decision does not move.** The option stays **unadopted** and the sizing *strengthens* the decline, since the substitute is more partial than the text admitted; D7's decision, AC-G6 and Open Item 1 are untouched, and **no `--previous` mode that reads `kb_gaps` is added** — L2's "exactly these two modes" stands. The sizing was worth correcting rather than left as a nicety for two reasons on the page: Open Item 2 hands a **live decision** to the work owner *on this description*, and feature-010 — authored fresh in **Wave 3c**, carrying the retention correction (STATE.md:1003–1004) — reads it. **Swept by shape, not by token**, per this SPEC's own standing correction — **one third site found and corrected**: Open Item 3's closing clause called item 2 "the *only* sanctioned way to restore **the transitions** early", and now names the transition it actually reaches. Every other site was re-derived by reading each hit with its line number: D5's `Status` cell, D7 obligation 4, Open Items 1 and 3, GL10 and Feature Flow step 2 all state that `Fixed`/`Recurred` are unreachable while D-6 is open — which this fix leaves true, since the stash is unadopted — while AC-G6, GL11 and GL18 make no reachability claim at all, and the two quotations of feature-010's own retention sentence are verbatim and attributed to it. One candidate examined and **left standing**: D7 obligation 2's "the *findings* survive DONE" is not the same overclaim, because `kb_gaps` does carry the gap set with its severity and qualifier, and D5 already says in terms that the ledger comes back only by re-run and not by read-back. **Nothing else moved:** the proxy sweep stays **eighteen** rows, the Open Items **nine** with no renumbering, and § Figures still asserts no measured quantity — the correction names Status values rather than counting them | /aid-specify |

## Source

- REQUIREMENTS.md §5.9 (FR-25, FR-26, FR-27, FR-28) and its Rationale paragraph
- REQUIREMENTS.md §5.7 — **FR-20** (a source concept with no Knowledge Base representation is reported
  as a defect, **keyed on `Kind = source-artifact`** as re-keyed 2026-07-29), **FR-21** (the three
  significance criteria whose qualifier this feature's severity derives from), **FR-21a** (`image`,
  `web-page` and the four KB kinds qualify **by kind** and carry no qualifier), **FR-24** (derivable, not
  judged), **FR-19** (whose `int:` is deliberate prefix scoping — it names the discovery mechanism, not
  this feature's gap class; Q21)
- REQUIREMENTS.md §5.6 — **FR-13**'s Coverage lens, whose two halves were re-keyed the same day: the
  undocumented half to `Kind = source-artifact`, the unbacked half to **`{document, concept}`**
- REQUIREMENTS.md §5.5 — **FR-8a** (genericity, and the ruling that a **convention absence is not a
  gap-ledger row**), **FR-9a** (the coverage notes those absences go to instead), **FR-10** (read-only
  with respect to Knowledge Base content), **FR-11** (the staleness inputs; feature-010 owns the check)
- REQUIREMENTS.md §2 Problem Statement item 1 — drift and coverage detection, the purpose this feature
  serves, and the source of the "unbacked Knowledge Base claim" half the lens carries alone
- REQUIREMENTS.md §4 Out of Scope — fixing gaps; automatic ticket creation; validating Knowledge Base
  content quality beyond the structural gap signal
- REQUIREMENTS.md §7 — **C-6** (the project-wide seven-column reviewer ledger written to
  `.aid/.temp/review-pending/`; no bespoke findings format)
- REQUIREMENTS.md §8 — **D-6** (FR-26 depends on the ledger-retention methodology change raised as its
  own work item under Q8), **D-1** (the relation vocabulary this feature selects a subset of)
- REQUIREMENTS.md §9 — **AC-14**, **AC-15** (the equality binding `Kind = source-artifact` only),
  AC-16 (granularity, which fixes the `Line` cell), AC-19 and AC-20 (the coverage-notes path that
  convention absences take instead of this ledger)
- STATE.md **Q8** (resolved — retention becomes its own work item), **Q17** (the proxy defect class and
  the standing sweep instruction), **Q18** ruling 3 (a defect makes an A+ false; an inbound item on a
  gated SPEC is a pending reopen), **Q20 (loader sync)** (check the inbound queue, not only the ledger,
  before any re-gate — cited with its suffix throughout, because a second STATE.md entry carries the same
  number), **Q21** (FR-13's double re-key, and the refinement that a prefix is correct when the clause
  is about *where nodes come from* and wrong when it is about *what class they belong to*)
- `.claude/aid/templates/reviewer-ledger-schema.md` — the seven-column shape, the severity and status
  enums, the file location table, and the lifecycle whose deletion-at-DONE is what D-6 is about

**Immutable inputs, consumed and not restated.** feature-003 (the ten-column schema, the `Kind` enum and
its per-kind id grammars, V13's two-tier kind/prefix check, the reserved `kb_gaps` frontmatter key and
its position outside the byte-identity boundary), feature-004 (`nodes.tsv`, the `qualifier` and
`evidence` fields, the `no-inferred-node` invariant, and the `media-nodes.tsv` stream split that makes
`nodes.tsv` `source-artifact`-only), feature-005 (the final post-pass-2 table, its provenance rule, and
the carrier map that determines which relations exist to be coverage-bearing at all). Where this SPEC
needs something from one of them that it does not state, that is an Open Item, not an assumption.

**Dependency position.** Blocked by feature-004 (the enumerated candidate set) and feature-005 (the
final table the predicate is evaluated against). Blocked for *delivery* by **D-6**, which is not this
feature's to close (D7). Not blocked by either RESEARCH feature, though `COVERAGE_BEARING`'s membership
becomes *checkable* only when feature-001's vocabulary file is authored (D2a).

**Shared acceptance criterion — AC-15.** The Coverage lens and this ledger must agree, and the equality
binds **`Kind = source-artifact` only**. The agreement *is* the criterion, so this feature owns it, but
feature-007 and feature-008 must satisfy it from the view side. AC-15 appears in this SPEC and in
feature-007's as a mutual obligation; neither feature may consider it met alone.

## Description

When a structurally significant part of the project source turns out to have no representation in the
Knowledge Base, that is a defect in the Knowledge Base — not a curiosity, and not merely a node with no
edges. This feature is how such findings leave the tool and reach someone who can act on them.

**What counts as "part of the project source" is a node *kind*, not an id prefix.** The class is
`Kind = source-artifact`: a whole artifact in the project source. It is not "everything the enumeration
walk found", because that walk also yields in-repo **images**, which share the `int:` prefix and are
first-class nodes **by kind** rather than by passing a significance assessment. An unreferenced picture
is not undocumented project source, and — decisively — it carries no significance qualifier for this
feature's severity to derive from. Keying on the prefix would therefore force one of two wrong
behaviours: a picture highlighted by the Coverage lens with no ledger row behind it, breaking AC-15's
equality; or a picture reported as undocumented project source, which it is not.

Findings are written as a reviewer ledger in the same seven-column shape the project uses everywhere
else, in the same place reviewers already look. One row per gap, and each row carries the offending
source artifact as its evidence, so a reviewer can go straight to the thing that is undocumented rather
than reconstructing what the finding meant.

Crucially, finding gaps never stops the run. `/aid-graph` reports; it does not gate. A run that
uncovers fifty gaps completes exactly as successfully as one that uncovers none. This is deliberate and
load-bearing: gating on Knowledge Base completeness would fail the tool for reasons entirely outside its
own control, and worse, it would create a standing incentive to loosen the significance rule until the
gaps stopped appearing — destroying the very signal the artifact exists to produce. Reporting-only also
keeps trust flowing one way: the tool observes the Knowledge Base and cannot alter what it observes.

Fixing the gaps is somebody else's job. Findings route onward to the skills that already own targeted
Knowledge Base updates and re-discovery. This feature does not repair anything, and it does not open
tickets.

**One thing this feature cannot yet deliver, stated here rather than buried.** The shared reviewer-ledger
lifecycle deletes ledgers at skill DONE. That would destroy the findings FR-26 exists to deliver, and the
owner ruled (Q8, D-6) that the fix is a **methodology work item of its own**, not a local workaround
here. Until it lands, the ledger is written in the right shape at the right path and then removed with
every other ledger at DONE; what survives the run is the `kb_gaps` list in `relationships.md`'s
frontmatter, and the run prints the command that regenerates the ledger **from durable inputs** — a full
re-run of the pipeline, FR-31's bounded agent pass included, and not a read-back of `kb_gaps`. D7 states
the shortfall precisely, including which behaviours are unreachable in the meantime.

## User Stories

- As a **KB reviewer**, I want each gap delivered as a ledger row in the format I already review, with
  the offending source artifact named as evidence, so that I can verify and act on it without learning a
  new findings format.
- As a **KB reviewer**, I want the severity of a row to mean something I can check, so that I can triage
  a long ledger without reading every row's evidence.
- As a **maintainer/architect**, I want the run to succeed even when it finds many gaps, so that I get
  the report instead of a failure and can decide what to do about it.
- As a **maintainer/architect**, I want an unreferenced image never to appear as undocumented project
  source, so that the ledger stays a list of real Knowledge Base defects rather than a list of things the
  scanner happened to see.
- As the **AID methodology owner**, I want the tool to have no incentive to under-report, so that the gap
  signal stays trustworthy over time.
- As a **maintainer/architect**, I want findings pointed at the skills that already own Knowledge Base
  repair, so that a gap becomes tracked work rather than a note I forget.

## Priority

Must

## Acceptance Criteria

- [ ] AC-14: Given a run that detects one or more Knowledge Base gaps, when the run finishes, then each
      gap appears as a ledger row carrying the offending source artifact as its evidence, **and** the run
      still completes successfully.
- [ ] AC-15 *(shared with feature-007 — mutual obligation; neither feature may consider this met
      alone)*: Given a generated ledger and a generated graph view, when the Coverage lens is applied,
      then the lens surfaces exactly the gaps present in the ledger — the two agree, with no gap in one
      that is absent from the other. The equality binds **`Kind = source-artifact` only**; the lens's
      unbacked-`{document, concept}` signal has no ledger row and its presence does not breach this.
- [ ] **AC-G1** *(new — the keying, made checkable)*: Given a candidate stream containing a row whose
      `node_kind` is anything other than `source-artifact`, when the detector runs, then it **fails with
      exit 2 and writes no ledger**, rather than emitting a row for a node of another kind.
- [ ] **AC-G2** *(new — the keying, from the output side)*: Given a generated ledger, when every `Doc`
      cell is checked, then none names a path whose extension is a member of feature-003's
      `image_extensions:`, and the `kb_gaps` id set is **disjoint** from feature-004's
      `media-nodes.tsv` id set.
- [ ] **AC-G3** *(new — severity)*: Given a node for each of feature-004's four `qualifier` values, when
      the ledger is emitted, then each row's `Severity` is the value this SPEC's mapping assigns, the
      mapping is **total** over the four values, and a row is never emitted for a node whose `qualifier`
      is absent or outside that enum — such a stream is exit 2.
- [ ] Given any number of detected gaps, when the run completes, then its exit status is success — the
      run never fails because gaps exist.
- [ ] Given a generated gap ledger, when its structure is checked, then it uses the project-wide
      seven-column reviewer-ledger shape at the shared review-pending location, with no bespoke findings
      format and no narrative anywhere in the file.
- [ ] **AC-G4** *(new — the evidence is true)*: Given a gap row for an artifact that **does** appear in
      the table but only under relations outside `COVERAGE_BEARING`, when a reviewer runs the `Evidence`
      cell's recheck command, then it reports the artifact's rows and the relation on each and returns
      the same uncovered verdict — the evidence never contradicts the row it justifies.
- [ ] **AC-G5** *(new — the measured blind spot)*: Given a project whose relation vocabulary carries an
      extension, when the run completes, then it reports the number of table rows typed by an extension
      relation, so the F6 false-gap risk is a quantity on the run's output rather than a caveat in a
      document.
- [ ] Given a completed run that detected gaps, when the output is read, then it names the skills that
      own Knowledge Base repair as the route onward, and the run itself has neither modified the
      Knowledge Base nor opened a ticket.
- [ ] **AC-G6** *(new — the D-6 shortfall is honest)*: Given that the retention carve-out has not landed,
      when the run completes, then the routing block states that the ledger does not survive skill DONE
      and names both the durable carrier (`kb_gaps`) and the command that reproduces the ledger — and the
      shared ledger schema carries **no** retention exception written by this feature.

---

## Technical Specification

> Grounded in `.aid/knowledge/quality-gates.md` (The Reviewer Ledger, How the Grade Is Computed),
> `.claude/aid/templates/reviewer-ledger-schema.md`, `.claude/aid/scripts/grade.sh`,
> `.aid/knowledge/authoring-conventions.md` (Reviewer Ledger Convention, Prose Over Scripts),
> `.aid/knowledge/coding-standards.md` (File Header Convention, Exit Codes),
> `.aid/knowledge/module-map.md` (Conventions — "Where a new helper script goes"), and
> `canonical/aid/scripts/kb/build-kb-index.sh` / `lint-frontmatter.sh` (verified tolerance of
> generator-written frontmatter keys). Upstream contracts are cited to feature-003 D1/D1a/D2/D8,
> feature-004 D1/D1a/D3/D7, feature-005 D4/D8, and feature-007 D6d/D10.

### Data Model

#### D1 — Inputs (all read-only)

| Input | Producer | Shape consumed here |
|---|---|---|
| The enumerated **`Kind = source-artifact`** node set — `.aid/.temp/graph/nodes.tsv` | feature-004 D1 | **The candidate set.** Every row is a candidate, whether or not it appears in the table (D2). Its `qualifier` field supplies each emitted row's `Severity` (D4) and its `evidence` field supplies half of each row's `Evidence` cell (D5). Read through the field map of D1a. |
| The final relationship table — `.aid/knowledge/relationships.md` | feature-003 (schema) + feature-005 (rows) | The **ten** columns of REQUIREMENTS.md §5.2 *(this input was described as eight columns before 2026-07-29; every eight-column claim in this SPEC is struck)*, after **both** extraction passes have completed (FR-30, FR-31). Supplies the **edge set** each candidate is tested against. |
| The relation vocabulary, with each pair's `category`, `endpoint_kinds`, `passes` and `definition` | feature-001 | Fixes the membership of `COVERAGE_BEARING` — condition 3 of the predicate (D2a). Consumed as the reviewable statement of that subset, not as a runtime input; the executable copy lives in the shared module. |
| `.aid/.temp/graph/media-nodes.tsv` | feature-004 D1a | **Read by the test suite for one assertion, and by nothing else** — AC-G2's disjointness, asserted at **suite** level by GL15, which opens this file and the emitted `kb_gaps` list directly. It is **not a detector input**: L2's interface declares no flag for it and forbids baked-in path defaults, so there is deliberately no way to hand it to `detect-kb-gaps.mjs` at all, and no way for a later edit to widen the candidate inventory to "both streams" without adding a flag — the visible, reviewable change feature-004 Open Item 1 warns about. Named here because the disjointness is a check rather than a hope, and because a reader tracing AC-G2 needs to know which of this feature's two surfaces reads it. |

**Which surface reads what, stated because the three readers are not interchangeable.** The first two
inputs are read by the **detector** (L2), each through its own explicit flag — `--table` and `--nodes`
(plus `--previous` for its own prior ledger, which is this feature's output and not another producer's
artifact, hence not a row above). The **vocabulary is read at run time by nothing at all**: it is the
reviewable statement of the subset, and the executable copy is a constant inside `coverage-predicate.mjs`,
which is why L2 declares no `--vocabulary` flag (D2a). And `media-nodes.tsv` is read only by the **suite**
(L4). That last split is what keeps AC-G2 checkable without giving the detector an input it must not have:
a detector that can read the media stream is a detector that can enumerate from it, which is the exact
regression feature-004 Open Item 1 predicts. Nothing in this feature writes back into any of the four. It
adds no new scan and no second traversal — the gap set is a query over data that already exists, which is
why it can be computed after extraction rather than during it.

#### D1a — How `nodes.tsv` is read: the field map, and why `node_kind` is data

`nodes.tsv` has **no header row** (feature-004 D1). "Reading a field by name" therefore cannot mean
"looking it up in a header"; it means the detector binds each of feature-004 D1's seven field names to
its index **once**, in a single map, and every read goes through that map:

```js
const NODE_FIELDS = {
  node_id: 0, name: 1, artifact_class: 2, qualifier: 3,
  evidence: 4, evidence_provenance: 5, node_kind: 6,
};
```

Three properties of that one declaration matter, and each was previously implicit:

1. **`node_kind` is read, not assumed.** feature-004 D1 field 7 carries §5.2's `Kind`, and in this
   stream its value is the constant `source-artifact`. The detector reads it and **asserts** it on every
   row; a row carrying any other value is an input-contract violation and exits 2 (AC-G1). This is what
   turns "correct because the stream happens to hold only one kind" into "correct because the kind is
   checked". feature-004 states the constant is "carried anyway, because *carried as data, not as code*
   is the same posture feature-003 adopted for the enum itself" — this is the consumer that makes that
   carriage pay.
2. **Field 3's rename cost nothing and field 7's addition cost nothing.** `kind` → `artifact_class` kept
   its position and value space, and `node_kind` was appended. Because every read is a named lookup into
   one map, a rename is a one-line change and an append is an added entry. This feature never reads
   `artifact_class` at all.
3. **The map is the only place a field index appears.** feature-004 Open Item 2 records that this feature
   reads `name` positionally and `qualifier`/`evidence` by name — a split that was true of the prose and
   is now unnecessary: with the map, *every* field is read by name and nothing is positional at the call
   sites. That discharges the residue of that item; no mechanism in either feature changes.

#### D2 — The coverage predicate: one implementation, in a shared `.mjs` module

**There is exactly one implementation of the predicate, and this feature does not hold it.** It is
`detectArtifactGaps({nodeIds, edges})`, exported from
`canonical/aid/scripts/graph/coverage-predicate.mjs` — the purpose-built module feature-007 specifies
and owns. This feature owns the predicate's *semantics*, which feature-007 adopts verbatim; feature-007
owns the *file*. Both consumers call that one function: this feature's generator `import`s it under
Node, and the view runs the same bytes inlined in the browser. Agreement between the ledger and the
Coverage lens is therefore structural — one implementation, two runtimes — rather than two readings of
the same prose. D6 records how the two runtimes reach the same bytes and how the result is verified.

**The name is `detectArtifactGaps`, not `detectKbGaps`** *(feature-007's re-specification, adopted
here)*. The set it returns is `Kind = source-artifact`, and the old name carried the prefix-keyed reading
AC-15's re-key removed. The renamed export is matched by `coverageGaps.artifactUndocumented` and by the
`'artifact-undocumented'` emphasis class on the view side.

**The predicate.** An enumerated **`source-artifact`** node is **covered** when at least one edge of the
final table satisfies all three conditions:

1. the node is one of the edge's endpoints, **or** an ancestor path of the node is that endpoint — a
   Knowledge Base document that documents a directory covers the artifacts inside it (D3, false-gap class
   F2). Path matching needs no new field: an `int:`-prefixed id *is* its repo-relative path with the
   prefix stripped (D5, `Doc` column). **The second arm is currently unreachable and is kept for
   totality**, not for a live case — F2 states why, and GL02 must build the shape to test it;
2. the **other endpoint's `Kind`** is one of `document`, `concept`, `fact`, `section` — the four
   Knowledge Base kinds. Stated over kinds rather than over the `kb:` prefix because that is the column
   the table now carries; it selects the same rows either way, since §5.2 pins all four kinds to `kb:`,
   but a kind-keyed condition cannot silently widen when a prefix's meaning does;
3. the relation naming the direction **from that Knowledge Base endpoint to the artifact** is a member of
   `COVERAGE_BEARING` (D2a).

A candidate that is **not** covered is a **gap**. Condition 3 is what stops a bare mention from clearing a
gap — a live, load-bearing exclusion. Condition 1's ancestor arm is the opposite case and is labelled as
such rather than sold as a mitigation: it makes the predicate **total** over directory nodes, and on
today's streams nothing reaches it, because the coarse-grain coverage F2 describes arrives as a *per-file*
edge instead (feature-005 D4 expands a `sources:` glob against feature-004's streams). F2 states both
halves.

**Condition 3 reads one of two cells, and which one is not arbitrary.** A row names both directions
(`S2T Relation`, `T2S Relation`) and feature-003 D7 emits rows in a **normalised orientation**, so the
Knowledge Base endpoint may land on either side. The predicate therefore selects the cell naming the
Knowledge Base→artifact reading: `S2T Relation` when the Knowledge Base node is the row's `Source`,
`T2S Relation` when it is the `Target`. Stating it this way is what lets `COVERAGE_BEARING` hold four
plain relation names rather than four names plus a direction rule the reader has to infer — and it is
also the constraint that decides two of D2a's exclusions.

**Coverage counts from rows of any `Provenance`, including `inferred`** (D3, F3). The asymmetry is
deliberate: liberal about what counts as coverage, strict about what counts as a qualified node.

**The candidate set is feature-004's enumerated inventory, not the table's node column.** This is the
load-bearing choice, and it is deliberate: FR-19 and FR-20 are about *source artifacts with no Knowledge
Base representation*, and an artifact with no relationships at all is the extreme case of that, not an
exception to it. feature-004 qualifies by structural significance — an entry point or a named unit need
have no edge — so a zero-row node is reachable in practice. Computing over table rows alone would make
the ledger silently blind to precisely the worst finding it exists to produce. `detectArtifactGaps`'s
`nodeIds` argument exists for this: Node passes the full `nodes.tsv` inventory, the browser passes what
the table contains, and the difference between the two is the `orphans` class feature-007's verification
names and materialises (D6).

#### D2a — `COVERAGE_BEARING`: the selection, its criterion, and where it lives

feature-001 owns the vocabulary and its categories; this feature owns the **selection**. Two inbound
items are discharged here: feature-001 Open Item 8 ("`coverage_bearing` becomes an explicit selection
rather than an emergent one … feature-006 must state which it takes") and feature-005 Open Item 9
("feature-006's coverage-bearing selection must avoid `documentation`").

**The selection is at pair granularity, and category granularity is inexpressive rather than merely
coarse.** feature-001's Open Item 8 frames the choice as one among three categories — `documentation`,
`evidence`, `provenance`. That framing cannot produce a correct answer, and the reason is a single pair:
`mentions` sits in `documentation` and its own authored definition is *"The source names the target in
its content **without asserting that the target is its subject or its evidence**."* Condition 3 exists
precisely to stop a bare mention from clearing a gap, so admitting `documentation` wholesale would
defeat condition 3 by construction and make the ledger under-report by design. `annotation`'s single
pair disclaims coverage in the same way (*"adds a scoping remark, caveat or commentary … without
asserting a claim of its own"*). Two categories therefore contain a disclaimer, which settles the
granularity question: **a category is a shortlist, a pair is a decision.**

**The criterion, stated before the verdicts so the verdicts can be checked against it.** A pair is
coverage-bearing iff, read in the Knowledge Base→artifact direction, its `definition` asserts at least
one of three things about the artifact:

- **(a) aboutness** — the Knowledge Base endpoint is a record *of* the artifact;
- **(b) citation as support** — the Knowledge Base endpoint names the artifact as something a reader can
  consult or check a claim against;
- **(c) derivation** — the Knowledge Base endpoint's content came *from* the artifact.

Anything less is co-location. §2 item 1's defect is "a source artifact no Knowledge Base document points
at *in a way that accounts for it*", and (a)–(c) are the three ways a vocabulary derived from SKOS, DCMI,
PROV-O, schema.org, IANA and CiTO expresses being accounted for. (b) is why feature-001 split `evidence`
from `documentation` in the first place — its own stated ground is that "FR-13's Coverage lens and
FR-26's gap ledger key on 'a Knowledge Base claim backed by a checkable source', which is evidence".

**The candidate universe is enumerated, not sampled.** Every pair in feature-001 D6 whose
`endpoint_kinds` carries a token joining a Knowledge Base kind to `source-artifact`, in either reading.
Ten are authored with the Knowledge Base endpoint as `relation` source; three are authored the other way
and reach a Knowledge Base→artifact reading only through their `inverse`.

| Pair | Category | Verdict | Why |
|---|---|---|---|
| `documents` | `documentation` | **member** | (a). "An authored record of the target, written by drawing on the target for its factual content" — the criterion's aboutness clause almost verbatim. Its producer is `frontmatter-sources-path` (feature-005 D4), so it is the document-level backbone of coverage — and, because that producer expands a `sources:` glob to one edge **per matching file** (feature-005 D4, its SPEC.md:827), it is also what carries the coarse-grain coverage F2 is about, through condition 1's *first* arm rather than its ancestor arm |
| `mentions` | `documentation` | excluded | Its definition **disclaims** both (a) and (b). Admitting it would defeat condition 3; this is the pair feature-005 Open Item 9 is about, and the reason category granularity fails. **The exclusion is not academic:** `mentions` admits `inferred`, so feature-005 D8 puts its unmapped `<KB kind>->source-artifact` tokens in Pass 2's discovery scope rather than among the unreachable ones — meaning an agent-inferred bare mention is a row that really can exist, and admitting the category would let one clear a gap |
| `cites` | `evidence` | **member** | (b). "Names the target as a reference a reader may consult." Producer of the arm that matters here: `kb-inline-path-citation` (`document`/`section`/`fact` → `source-artifact`). The same relation's `kb-ext-key-citation` arm targets `web-page`, which is not a candidate |
| `cites-as-evidence` | `evidence` | **member** | (b), in its strongest form: "the checkable support for one specific claim the source makes." Its producer is `kb-fact-anchor` — the `fact`→`source-artifact` edge FR-30 emits alongside every fact node, and the sharpest coverage signal the vocabulary has |
| `derived-from` | `provenance` | **member** | (c). "The content of the source came from the target." Reachable through Pass 2 (`inferred`), which F3 accepts deliberately |
| `generated-by` | `provenance` | excluded | Direction of account, not strength of evidence: a generated Knowledge Base document is an **output of** the artifact, and nothing in it need describe the artifact. `INDEX.md` being generated by `build-kb-index.sh` says nothing about what that script does, so an artifact whose only Knowledge Base edge is `generated-by` is genuinely undocumented. feature-005 D8 additionally marks the pair `unreachable`, so admitting it would be untestable as well as wrong |
| `quotes` | `provenance` | excluded | Reproducing a fragment verbatim asserts nothing about the artifact as a whole — it is neither (a) nor (c), and (b) requires the target to be named as support rather than copied. feature-005 D8 also marks it `unreachable` (no mechanical carrier, and its `passes` excludes `inferred`), so a member here would be one GV05 accepts and no test can exercise |
| `has-member` | `structure` | excluded | Enrolment in a declared set is co-location: a document listing the artifact among a set records nothing about it. Also `unreachable` today (feature-005 D8) |
| `renders-to` | `representation` | excluded | A format sibling, not a record: "the target carries the same content as the source in a different format". Also `unreachable` today, and for a reason worth knowing — feature-005 D8 records that the real canonical→profile render edge is cut upstream by feature-004 D4 Class 1, so its target is not a node at all |
| `annotates` | `annotation` | excluded | Disclaims (a) explicitly — "without asserting a claim of its own" — and is `inferred`-only |
| `implements` → `implemented-by` | `implementation` | excluded **today**, with the case recorded | This is the one exclusion with a real argument against it: a Knowledge Base document that **specifies** the behaviour an artifact realises does account for that artifact, which is (a). It is excluded for two reasons that are both current rather than permanent: the Knowledge Base→artifact reading is the pair's **`inverse`** name, and membership is by `relation` key so GV05's `COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)` containment could not hold for it; and it is `inferred`-only with no class-0 producer (feature-005 D8), so admitting it today would let an agent's reading alone clear a gap in the direction FR-24 is most sensitive about. Routed as Open Item 5 rather than resolved by picking whichever answer the test allows |
| `tests` → `tested-by` | `implementation` | excluded | Same inverse-direction constraint, and a weaker semantic case: the specification of what a test checks accounts for the test only partially. `unreachable` today (feature-005 D8, and its Open Item 13 records the two routes that would give it a producer) |
| `exemplifies` → `exemplified-by` | `definition` | excluded | Same inverse-direction constraint. On the merits it is co-location from the artifact's side: a concept illustrated by an artifact records nothing about the artifact |

**The selection.**

```
COVERAGE_BEARING = { documents, cites, cites-as-evidence, derived-from }
```

Four pairs, drawn from three categories, and **exactly one of those categories is taken whole**: one of
`documentation`'s two, **both** of `evidence`'s two — that is, all of `evidence` — and one of
`provenance`'s three (feature-001 D5's pair counts, its SPEC.md:631–633). The coincidence is not the
argument and is not relied on anywhere: `evidence` is taken pair-by-pair like the other two, and it comes
out whole only because both of its pairs happen to satisfy criterion (b). That is the shape feature-005
Open Item 9's fact predicts — `evidence` and `provenance` carry the claim-to-source edges, `documentation`
contributes only its non-disclaiming pair — reached from the criterion rather than adopted from the advice.
The granularity argument above is unaffected by it: `documentation` and `annotation` each hold a
definition that disclaims coverage, so **a category is a shortlist and a pair is a decision** even where a
shortlist and a decision agree.

**Where the reviewable copy lives, and why not in the vocabulary file.**
`canonical/aid/templates/graph/coverage-bearing.yml` — a sibling of feature-001's
`relation-vocabulary.yml` in the same directory, so a reviewer reads the two together. One top-level key,
`coverage_bearing:`, a block sequence of plain relation tokens, plus a header comment carrying the
criterion above and the thirteen-row verdict table's outcome. `.yml` is absent from `render.py`'s
`_TEXT_EXTENSIONS`, so it renders as verbatim bytes and is byte-stable across profiles — the same
property feature-001 relies on for the vocabulary itself. **Nothing reads it at runtime**: the executable
copy is a constant inside `coverage-predicate.mjs` (which may not `import`, D6), and feature-007's
**GV04** asserts the two are equal. It therefore needs no loader.

*Rejected: a third top-level key inside `relation-vocabulary.yml`.* feature-003 D4's loader specifies a
forward pass whose entry-flush points are `  - relation:`, `categories:`, and end of file, and states no
treatment for any other top-level key — so adding one would require feature-003 to define its handling,
which is a change to a **gated A+ SPEC and therefore a reopen** (Q18 ruling 3). The sibling file buys the
same reviewability at no such cost, and the "beside the vocabulary" requirement was always about
adjacency for a reader rather than about co-location in one file.

**Membership is fixed here; it becomes *checkable* when the vocabulary file is authored.** GV04 and GV05
are runnable once `relation-vocabulary.yml` exists with the 31 pairs feature-001 specifies. If the
authored file renames or drops any of the four members, this selection must be re-derived from the
criterion rather than patched — Open Item 5.

#### D3 — False-gap classes and how each is handled

A false gap is worse than a missed one: it teaches a reviewer to distrust the ledger, and it is the first
pressure toward loosening FR-21. Five classes are excluded **structurally**, not by tuning. A sixth is
**not** excluded, and is measured rather than described.

| # | False-gap class | Structural exclusion |
|---|---|---|
| F1 | A covering edge exists but was not yet typed when the predicate ran | The predicate runs **once, after** the pass-2 agent step (FR-31) completes, over the final table only. There is no early evaluation to be wrong. |
| F2 | The Knowledge Base documents the artifact at a coarser grain — a doc covers a directory or a script area, not the file | D2's **condition 1**, ancestor-path matching: a `document` ↔ `int:canonical/aid/scripts/summarize/` edge covers every enumerated node beneath that path. *(The trailing `/` is not decoration — feature-003 D2b (its SPEC.md:839) makes it the directory-artifact marker, and D5 and GL06 enforce it on the emitted cell.)* **The condition is currently unreachable, and it is kept for totality rather than for a live case.** Under feature-004's collapse rules as gated (its Feature Flow step 6, :1965–1974) the only directory ids emitted are `canonical/skills/<name>/` and `canonical/agents/<name>/`, and those **suppress their member files** — so no enumerated `source-artifact` node has an ancestor that is also a node, and condition 1's second arm cannot fire on today's streams. It stays because deleting it would make the predicate **wrong for directory nodes generally**: if a later revision of those rules ever emits an ancestor and a descendant as nodes together, coverage of the ancestor must count for the descendant, and a predicate testing endpoint identity alone would report the descendant as a gap. Keeping a total predicate costs one path comparison; re-deriving it later costs a reopen. |
| F3 | The covering edge is only `inferred`, so a strict reading would discard it and report a gap | Coverage is counted from rows of **any** `Provenance` value — none of D2's three conditions reads the `Provenance` column. The asymmetry with F4's invariant is deliberate: be liberal about what counts as coverage, strict about what counts as a qualified node. |
| F4 | The gap rests on a node that only qualified by agent opinion | **Excluded upstream, by an invariant this feature relies on rather than a filter it applies.** feature-004 owns it: its node record carries `evidence_provenance` ∈ {`declared`, `derived`} and its D3 states the hard rule — "`evidence_provenance` is never `inferred`, and a candidate that only a reading would qualify is **not emitted as a node**", written instead to `candidates.tsv` with a `drop_reason`. Such a node therefore never enters the node set, never reaches the table, and cannot become a ledger row. feature-004 D3 consequence 1 states the same conclusion from its side: a filter here would be **vacuous**, so it is dropped rather than reimplemented. |
| F5 | The artifact is a rendered copy, vendored code, or ignore-listed | Never enumerated at all (FR-22, AC-16) — it cannot reach this feature. |
| F6 | **The artifact is covered only by a relation from a project extension** | **Not excluded. Measured and routed.** `COVERAGE_BEARING` is a compile-time constant in `coverage-predicate.mjs`, so a project that adds an extension pair under FR-4a **cannot** widen it, and an artifact whose only Knowledge Base edge carries that pair is reported as a gap it is not. This is the false-gap direction, so it is not the safe failure. The mitigation is a **counter, not a heuristic**: the detector reports how many table rows are typed by a relation outside the core vocabulary, so a reader can see on their own project whether the blind spot is live (AC-G5). Whether an extension may declare coverage-bearing membership is a decision above this feature — Open Item 6. |

**F2's necessity argument is withdrawn, and the withdrawal is recorded rather than the argument quietly
dropped.** The previous revision justified condition 1 by predicting that without it, dogfooding
`/aid-graph` on AID "would report nearly every file under those trees as a gap while `module-map.md`
demonstrably documents them" — pointing at `.aid/knowledge/module-map.md`'s own `sources:`, which does
list bare directories (`bin/`, `lib/`, `canonical/`, `profiles/`, `packages/`, `dashboard/`, `site/`,
`tests/`) alongside file-level entries. **That prediction is false under both readings of the carrier, so
it is deleted rather than softened.** Read as a **glob** — feature-005 D4's rule, "a `sources:` glob is
expanded against feature-004's streams and each match becomes an edge" (its SPEC.md:827), and the reading
feature-005 harvest kind 9 states (:773) — each matching file gets its **own** `documents` edge, which
clears it under condition 1's *first* arm; no ancestor match is involved and no flood exists to prevent.
Read as a literal **repo-relative path**, the entry resolves to `int:bin/`, which feature-004 never emits,
so it names no node, produces no edge, and prevents nothing. Either way the argument was for a mechanism
the mechanism does not have. What survives is the totality argument in the row above, which does not
depend on a live case — and stating it that way is the point: a structural exclusion earns its place by
making a class impossible, not by a prediction about one repository.

**Why F4 is stated as an invariant and not implemented as a check.** A filter here would need per-node
qualification provenance available at predicate-evaluation time, and the shared predicate of D2 is
computed from plain node ids and edges alone, whose records carry no such field. Adding one would put a
second, weaker copy of feature-004's rule in the view layer — the exact duplication the 2026-07-28
finding removed. Since feature-004 guarantees the set is already clean, the correct engineering answer is
to depend on the guarantee and name its owner. If feature-004's guarantee were ever weakened, this row is
where the consequence lands, and `GL03` (L4) is the assertion that would go red.

**Why F6 is admitted rather than argued away.** Q19's lesson is that a sound conclusion resting on an
unverified premise survives review; the honest alternative to a blind spot is a number that measures it,
which is what feature-005's D2f reach counters do for its own detector. The counter costs one pass over
the table's relation cells and introduces no judgment, so it is available whether or not the decision in
Open Item 6 is ever made.

#### D4 — Severity derives from the significance qualifier

FR-26's severity must be **derivable, not judged** (FR-24), and the derivation is a total function of one
field: feature-004 D1 field 4, `qualifier`.

| `qualifier` | `Severity` | Why this rank |
|---|---|---|
| `entry-point` | `[HIGH]` | An undocumented public surface is the class the Knowledge Base exists to describe; matches the schema's `[HIGH]` band, "Wrong claim, dead reference, broken citation, or missing post-merge content" |
| `public-surface` | `[HIGH]` | The same FR-21 criterion — "an entry point **or** public surface" is one clause with two qualifier values, and both carry the same consequence |
| `depended-upon` | `[MEDIUM]` | Internal contract drift — the schema's `[MEDIUM]` band |
| `named-unit` | `[LOW]` | Real but low-consequence documentation debt |

**The domain is the four-value `qualifier` enum, not FR-21's three clauses, and the difference is not
pedantic.** FR-21 states three criteria; feature-004's field carries four values, because criterion 1
splits into `entry-point` and `public-surface`. A severity rule stated over "clauses" would need a
clause↔value translation. **One now exists** — feature-004's D3a, which maps every D3 carrier to exactly
one of the four values and names itself as precisely this translation, "defined here, where the values are
produced" (its SPEC.md:1019–1050 and :1296–1301) — *(an earlier revision of this paragraph said no document
defined one, which was true when written and is not now)*. Routing severity through it anyway would still
be the wrong design: it would add an indirection between the field the data carries and the rank the row
prints, and it could not distinguish two values a reviewer reading a `[HIGH]` row will want distinguished.
The mapping above is stated over the values the data actually carries, is total over them, and is asserted
total by AC-G3.

**The old tie-break is void.** The previous revision said "a node satisfying more than one FR-21 clause
takes the highest applicable severity". That is unimplementable and contradicts a gated contract:
feature-004 D1 states that a path "carries **exactly one** `qualifier`; when more than one clause
qualifies it, the **strongest applicable clause under D3a's precedence order** wins — not the first clause
the flow happens to test" (its SPEC.md:405–411, restated as a maximum over clauses at :1054–1055). So the
record carries exactly one qualifier and multiplicity is resolved upstream — and resolved by taking a
**maximum**, which is strictly what the withdrawn tie-break was reaching for. There is nothing here to
break a tie between, and re-adding one would range over a single-valued field.

The consequence is stated plainly rather than absorbed: **this feature's severity rank is exactly as good
as feature-004's precedence order** — and that order now has a stated answer to point at rather than an
open question. feature-004 D3a supplies four assigning rules, a carrier → value map total over D3
(:1019–1050), and the direct monotonicity verdict (:1265–1301): the assignment is severity-monotone by
construction for any severity function that is monotone in `P1 > P2 > P3` **and** constant on `P1`. The
D4 mapping above satisfies both — `entry-point` and `public-surface` both `[HIGH]` *is* constancy on `P1`
— which feature-004 verified against this table on 2026-07-29 (:1287–1291). **The obligation this puts on
this feature is a standing one, not a discharged one:** a later revision of D4 that ranked `named-unit`
above `depended-upon`, or that split `P1` by ranking `public-surface` above `entry-point`, would void the
no-under-reporting guarantee and own the consequence. That is why the mapping is stated over the four
values rather than over FR-21's clauses, and why AC-G3 asserts totality.

##### A node with no qualifier — three cases, and none of them is a ledger row

This is the mechanism that makes the gap class a **kind** rather than a prefix, so it is enumerated
rather than asserted.

| Case | Where such a node lives | What happens | Why that is right |
|---|---|---|---|
| An **`image`** (in-repo or external) or a **`web-page`** | `media-nodes.tsv`, which **has no `qualifier` field at all** (feature-004 D1a) | Never a candidate; never a `kb_gaps` entry; never a ledger row. AC-G2 asserts the disjointness | FR-21a makes these kinds first-class **by kind**, exempt from FR-21's three criteria, so there is no qualifier for a severity to derive from. FR-20 states directly that an undocumented image is **not** a Knowledge Base gap. feature-004 made the exemption *structural* — "a record with nowhere to put a qualifier cannot carry one" — and this is the consumer that depends on it |
| A **`document`**, **`concept`**, **`fact`** or **`section`** | feature-005's Pass 1 output; never in `nodes.tsv` | Never a candidate. The Coverage lens signals the unbacked ones separately, with no ledger row (D6a) | FR-21a: Knowledge Base kinds likewise qualify by kind, via FR-30's deterministic extraction. Same absence of a qualifier, same conclusion |
| A **`source-artifact`** whose `qualifier` cell is empty or holds a value outside the enum | Cannot occur in a well-formed stream: `qualifier` is required, and feature-004 step 11 drops every unqualified candidate to `candidates.tsv` | **Exit 2, no ledger written** (AC-G3) | It is a scanner bug, not a data condition — the same posture feature-004's single-writer function takes when it rejects a bad `evidence_provenance` and aborts. Guessing a severity, or defaulting to `[MINOR]`, would manufacture a finding from a malfunction |

Two enum values are **never** assigned, and the reason is recorded so a later change cannot widen the
range by accident:

- `[CRITICAL]` — reserved by the schema for "will mislead downstream phases or break tooling". A
  documentation gap breaks nothing at run time, and a never-graded ledger that shouted `[CRITICAL]` would
  read as a blocker it is not.
- `[MINOR]` — a gap is never cosmetic. Emitting `[MINOR]` would let a reviewer sort the whole ledger to
  the bottom of their queue, and it is the value a "default when the qualifier is unreadable" rule would
  reach for, which is the third case above.

#### D5 — The ledger row

Exactly the project-wide seven columns of `.claude/aid/templates/reviewer-ledger-schema.md`, with no
additional column and no narrative anywhere in the file (C-6).

| Column | Value for a gap row |
|---|---|
| `#` | Next sequential row number within the file; never renumbered across cycles |
| `Severity` | The bracketed value from D4 — one of `[HIGH]`, `[MEDIUM]`, `[LOW]` |
| `Status` | `Pending` on first emission. On a later run, a node still uncovered stays `Pending`; a node now covered becomes `Fixed`; a node that was `Fixed` and is uncovered again becomes `Recurred`. **While D-6 is unmet, `Fixed` and `Recurred` are unreachable in practice** — see D7. `Accepted`, `OOS` and `Invalid` are the schema's **human-cycle** values and `/aid-graph` never writes any of them; who may is the schema's call and is quoted rather than paraphrased, because the three differ: `canonical/aid/templates/reviewer-ledger-schema.md`'s Status table (:94–96 — byte-identical in the `.claude/` render this SPEC is otherwise grounded in, verified 2026-07-30) sets `Accepted` by "Orchestrator with user authorization", `OOS` by "Reviewer or orchestrator", and `Invalid` by "Reviewer in a subsequent cycle, or orchestrator with evidence". Only `Accepted` requires user authorization; the operative point here is unaffected — a generator is none of those actors |
| `Doc` | The offending artifact's **repo-relative path** — the node id with its `int:` prefix stripped, so the cell is directly openable. For a **directory artifact** (feature-004 step 6 collapses `canonical/skills/<name>/**` and `canonical/agents/<name>/**` to a directory id; feature-003 D2b gives it a trailing `/` and D1a requires it to carry `Kind: source-artifact`) the cell carries the trailing `/`, which is still the repo-relative path the schema asks for |
| `Line` | `—` always. FR-23 fixes source-code granularity at the whole artifact, so there is no line to name, and inventing one would contradict AC-16 |
| `Description` | One sentence, fixed form: `no Knowledge Base node covers <int-id> (qualified as <qualifier>)`. **"node", not "document"** — the predicate accepts a covering edge from any of the four Knowledge Base kinds (D2 condition 2), so the previous wording named a narrower class than the mechanism tests |
| `Evidence` | Two parts, separated by `; ` — the qualification anchor and the coverage recheck. See below |

**`Evidence`, and why its recheck command changed.** The cell carries:

1. **the qualification anchor, verbatim from feature-004's `evidence` field** — a path plus a
   grep-recoverable symbol, heading, glob or matched literal, stamped `declared` or `derived`. This is
   the disk-truth half: it is why the artifact is a node at all, and FR-24 is discharged at enumeration
   time so every row inherits it (feature-004 D3 consequence 3);
2. **the coverage recheck**, written out with **every** argument `--explain` requires, so the cell is
   paste-runnable rather than schematic:
   `coverage recheck: node detect-kb-gaps.mjs --explain <int-id> --table <the run's --table value> --nodes
   <the run's --nodes value>`. On a `/aid-graph` run those two values are `.aid/knowledge/relationships.md`
   and `.aid/.temp/graph/nodes.tsv`, so the emitted cell reads
   `… --explain int:site/src/lib/foo.ts --table .aid/knowledge/relationships.md --nodes .aid/.temp/graph/nodes.tsv`.
   It prints every table row naming that artifact, the relation on each in the Knowledge Base→artifact
   direction, and the covered/uncovered verdict — computed by the same one predicate.

**Every flag `--explain` requires is present in the cell, and that is a correctness property rather than
tidiness.** L2's read mode is `--explain NODE_ID --table PATH --nodes PATH`, "all explicit with no
baked-in default", and L2 reserves exit `2` for a usage or argument error. A cell carrying only
`--explain <int-id>` would therefore exit 2 on a usage error for every reviewer who pasted it — the same
failure shape as the withdrawn `grep -c` form, one level up: an `Evidence` cell that does not do what it
says.

**The two paths are echoed from the flags the run received, not hardcoded**, for three reasons that
coincide. L2 requires that "every path it touches arrives through the flags", so the detector holds no
path literal to print. Echoing makes the cell true of *whatever* invocation produced the ledger, which is
what lets GL16 parse the cell out of a fixture ledger and run it verbatim against the fixture's own
`mktemp -d` paths — an assertion that would be impossible against baked-in `.aid/…` literals. And on a real
run the echoed values *are* those literals, because feature-010 passes exactly them, so a reviewer reading
a real ledger sees the real paths with no indirection.

**The precondition, stated plainly instead of implied.** `--nodes` resolves to `.aid/.temp/graph/nodes.tsv`
on a real run, and that is run scratch: feature-010 removes `.aid/.temp/graph/` at skill DONE, and under D7
the ledger does not survive DONE either. So the pasted cell is runnable **while the run's scratch exists** —
which is exactly the window in which the ledger it sits in also exists, so the cell is never the weaker half
of the pair it belongs to, and a reviewer working the ledger in a REVIEW→FIX cycle has both. After DONE, the
reproduce path is the one D7 obligation 3 specifies — regenerate **from durable inputs** with the command the
routing block prints — and it is a **re-run, not a read-back**: `--reset` forces regeneration by discarding
the recomputed-digest comparison (feature-010's SPEC.md:138), so the pipeline runs again, FR-31's bounded
agent pass included, and step 6 **overwrites** `kb_gaps` with a recomputed gap set rather than reading it —
L2 declares no mode that could take it as input. What the durable carrier buys is that the *findings*
survive DONE, not a cheaper path back to the ledger. Nothing here waits on D-6; when D-6 lands and the
ledger is retained, a retained ledger's cells become runnable again against the next run's scratch, and this
paragraph stops needing to be said.

The previous revision's `recheck: grep -c 'int:<path>' .aid/knowledge/relationships.md = 0` is
**withdrawn, because it is false for a real and expected case.** An artifact that appears in the table
only under `mentions` edges *is* a gap — that is what condition 3 is for — and yet the grep returns a
**non-zero** count, so the evidence would appear to contradict the row it justifies, in exactly the class
of case a reviewer is most likely to check. The `--explain` form is true in every case: for a zero-row
node it prints no rows and the same verdict; for a mentions-only node it prints the rows and shows why
none of them counts. AC-G4 pins it, and GL16 exercises both the pasted form and the withdrawn one.

**A zero-row node emits an ordinary row — no special case anywhere in this table.** Its `Doc` is its path
like any other and its `Description` reads the same. The one difference is informational, and it belongs
in `Description`, which gains a trailing clause when the node has no relationships:
`no Knowledge Base node covers <int-id> (qualified as <qualifier>; no relationships in the table)`. That
is the FR-20 sentence a reviewer most needs to read, and burying it would be the "silently dropped"
failure FR-20 names.

`Evidence` carries the **offending node** as AC-14 requires, and carries it as something a reviewer can
run rather than a claim they must trust. Any `|` inside `Description` or `Evidence` is escaped `\|` per
the schema's pipe rule.

**On FR-26's and AC-14's wording, "the offending `int:` node".** Read here as the **id form** of the
class FR-20 defines, not as an independent scoping: every `source-artifact` id is `int:`-prefixed, so
carrying a `source-artifact` id satisfies the words exactly. The residue is that the words alone would
*also* be satisfied by an in-repo `image` id, which FR-20 and AC-15 exclude — so the clause is
satisfiable-while-wrong in the same family as the three already corrected. It is **not** a defect,
because FR-20 and AC-15 scope the class; a one-clause annotation like the one FR-19 received (Q21) would
close the family. Routed as Open Item 8 rather than absorbed, and rather than left unsaid because it
happens to come out right.

#### D6 — The AC-15 carrier: one implementation, two runtimes

AC-15 requires the Coverage lens and this ledger to agree. Agreement is made **structural** by having one
function compute the set on both sides, and then *verified* rather than assumed.

**The shared module.** `canonical/aid/scripts/graph/coverage-predicate.mjs` (feature-007) is the single
implementation. Three properties of that choice matter to this feature and are stated so a later change
cannot quietly undo them:

- **`.mjs`, not `.js`.** The extension alone makes the file unambiguously an ES module to Node, so no
  `package.json` marker is needed anywhere. A marker would otherwise have to sit in a *template*
  directory that renders into all five profile trees, putting a stray `package.json` into every adopter's
  install where their own tooling could misread it. **This SPEC's earlier `package.json` ESM-marker
  requirement is withdrawn entirely** — there is no marker file in this work.
- **Purpose-built, not the view model.** `graph-model.js` also carries the markdown parser, the store and
  the presets; importing it from Node would pull the whole view layer into the pipeline. The predicate
  module imports nothing, touches no DOM global, and exchanges plain data only (feature-007's five
  boundary rules, asserted by its **GV01**). **This rule is what decides where `RELATION_CATEGORY`
  lives.** The F6 counter (Feature Flow step 4) needs the core relation names on the **Node** side;
  feature-007 currently declares that constant in `graph-model.js` (its SPEC.md:291, :1334, :1434), which
  is browser-only. Importing it from the pipeline is precisely what this bullet forbids, so the constant
  **moves into `coverage-predicate.mjs`** instead of being reached across the boundary (L2, coordination
  obligation 3, Open Item 4). The Node side still imports exactly one module, and that module still
  imports nothing.
- **It renders as text, so it must contain no paths.** `.mjs` is in `render.py`'s `_TEXT_EXTENSIONS`, so
  every rendered copy passes through `substitute_filenames` and `rewrite_install_paths` — unlike a
  `.yml`, which is copied verbatim. The module must therefore contain **no `canonical/…` path and no
  filename placeholder, in code or in comments**, or the canonical and rendered copies diverge and
  feature-007's **GV02** byte-identity test breaks. Nothing in the predicate needs a path — its only
  path-shaped data is the node ids passed in as plain strings — so the constraint costs nothing, but it is
  a real authoring rule for whoever writes the file.

| Runtime | How it reaches the module |
|---|---|
| **Node, at generate time** | `detect-kb-gaps.mjs` (L2) does `import { detectArtifactGaps, RELATION_CATEGORY } from '../graph/coverage-predicate.mjs'` — a sibling in the same script area, so the specifier is a plain relative path with no resolution machinery behind it. Two names, one import, one module: the predicate for the gap set and the core relation keys for the F6 counter, which is the whole of what the Node side needs from the view's shared code (L2, GL12) |
| **Browser, at load time** | The generate step inlines the same file byte-identically as the first segment of one `<script type="module">` (feature-007's § "How each runtime reaches it"). No second copy is authored and no transpile step intervenes |

**`kb_gaps` frontmatter: a recorded result, not a second source of truth.** `relationships.md` carries a
generator-written key listing what `detectArtifactGaps` returned at generate time. feature-003 D8 reserves
the key for this feature and places it **outside the byte-identity boundary**, which is what lets a
per-run varying list live in the frontmatter without colliding with FR-32:

```yaml
kb_gaps:
  - id: "int:canonical/aid/scripts/graph/detect-kb-gaps.mjs"
    name: "canonical/aid/scripts/graph/detect-kb-gaps.mjs"
    severity: "HIGH"
    qualifier: "entry-point"
  - id: "int:tests/canonical/test-graph-gap-ledger.sh"
    name: "tests/canonical/test-graph-gap-ledger.sh"
    severity: "HIGH"
    qualifier: "entry-point"
```

**Both entries above are `entry-point`, and the second one is the case worth reading twice.**
`tests/canonical/test-graph-gap-ledger.sh` is a shebang-carrying `tests/canonical/test-*.sh`, so it
satisfies feature-004's Q1 (executable header) *and* its Q3 (the test-suite convention), and D3a's
precedence emits the stronger clause — `entry-point`, hence `[HIGH]` under D4 (feature-004
SPEC.md:1321–1328). The shebang is not incidental: `.aid/knowledge/coding-standards.md` § Shell (Bash)
Conventions mandates `#!/usr/bin/env bash` for this project's scripts (its line 104), and the suite L4 adds
is authored in the style of `tests/canonical/test-guardrails-d012.sh`, which carries one. *(A previous
revision of this block wrote `named-unit`/`LOW` here while applying the same gated rule correctly to
`detect-kb-gaps.mjs` in the entry above — one rule, two answers, in one block. Corrected 2026-07-30.)*

**A `[HIGH]` row for an undocumented test suite is intended, not a mis-rank** — the one-sentence phrasing
call feature-004's Open Item 14(ii) hands to this feature (its SPEC.md:2358–2363). A test suite nobody has
documented is a real `[HIGH]`: it is invoked by the runner, so FR-21 clause 1 is what qualifies it, and a
reviewer triaging by severity should meet it above an undocumented internal helper. The discriminator
feature-004 offers for softening it — `artifact_class` = `test-suite` — is deliberately **not taken**: D4
is a total function of `qualifier` alone (D1a point 2: this feature never reads `artifact_class`), a
carve-out for one `artifact_class` would break that totality, and tuning a severity down to manage ledger
volume is exactly the FR-21-loosening incentive FR-25's rationale and D3's opening sentence exist to
prevent. Volume is managed by the routing block's cluster line (§ Routing hand-off), never by the rank.

**The fourth key is renamed `clause` → `qualifier`; its values are unchanged.** The values were already
`qualifier` values drawn from feature-004's four-value enum rather than clause names, so the rename costs
nothing and removes a name standing in for a different thing: `clause` names FR-21's **three** clauses
while the field carries **four** values, so a consumer reading `clause` to explain a `[HIGH]` row could not
say which of the two `[HIGH]` values it was. feature-007's `recordedGaps` type changes one key name and nothing else — Open Item 4.

`name` is the display name from feature-004's `nodes.tsv` field 2. It is carried rather than derived
because a consumer must be able to *present* an entry whose node appears in no table row and therefore
has no node record to read a label from; feature-007's D10 states the same requirement from its side and
makes `name` required rather than optional (its Open Item 5, discharged here).

- The **ledger** emits exactly one row per `kb_gaps` entry, in list order. `kb_gaps` is written from the
  same call whose result the rows are built from, so the two cannot diverge within a run.
- The **Coverage lens** does **not** read `kb_gaps` as its input. It calls `detectArtifactGaps` over the
  nodes it can see and **verifies** the result against the record, publishing
  `coverageGaps.artifactUndocumented` as the **union** of the two (feature-007's D10 verification table).
  A disagreement it cannot explain fails loudly into the page's visible error region rather than
  rendering a picture that quietly contradicts the ledger.
- FR-3 and AC-10 hold, and the zero-row case is where that is worth saying explicitly: `kb_gaps` lives in
  `relationships.md`'s own frontmatter, so the view still reads **exactly one artifact**. A zero-row node
  reaches the page from the same file the table is in — not from a second file, not from a second
  extraction, and not from a fetch.

**How AC-15's equality holds.** Both surfaces resolve to the same **node set**: the generator evaluates
the predicate over feature-004's full inventory and records the answer; the view evaluates the same
predicate over the nodes it can see and unions in the record, which restores exactly the entries its own
candidate set could not contain. `orphans = G \ T` is the expected, named difference between the two
candidate sets — not a mismatch — and after the union both surfaces list the same gaps. `ledgerOnly` is
defined as `(G ∩ T) \ R` precisely so a node the view could never have found is not counted against it,
which is why the integrity alarm cannot fire on a zero-row node.

Verified safe to add: `canonical/aid/scripts/kb/lint-frontmatter.sh` validates only the named fields
(`objective`, `summary`, `sources`, `tags`, `see_also`, `audience`, `owner`, `approved_at_commit`) and
emits nothing for an unrecognised key — and skips `source: generated` documents outright in any case;
`canonical/aid/scripts/kb/build-kb-index.sh` composes its row from named fields only. `kb_gaps` is
therefore a generator-written field in the same class as `generator:` and `graph_inputs_digest:` and does
not disturb C-7 / AC-18.

**The agreement test** asserts three sets are equal: the `kb_gaps` list in the frontmatter, the `Doc`
column of the ledger, and an in-test call to `detectArtifactGaps` over the fixture's node inventory and
table. The third is not an independent reimplementation — that is the point — it is the check that the
*carrier* has not drifted from what the one predicate returns, which is the only failure mode a single
implementation still permits.

#### D6a — The lens/ledger asymmetry, and why it is correct

The Coverage lens carries **two** signals; this ledger carries **one**. The asymmetry is deliberate and
is stated here rather than left for a reader to reconstruct, because a reader who assumes symmetry will
read AC-15 as broken.

| Signal | Domain | Ledger row? | Computed by |
|---|---|---|---|
| `artifact-undocumented` | `Kind = source-artifact`, uncovered by D2's predicate | **Yes — one row per member.** This is the class AC-15's equality binds | `detectArtifactGaps`, in both runtimes |
| `kb-unbacked` | `Kind ∈ {document, concept}` with no incident edge to an `int:`-prefixed node | **No — never, and written to no carrier** | `kbUnbacked`, browser only |
| unbacked `fact` | a `fact` with no edge to a `source-artifact`, `image` or `web-page` | **No — and not a lens class either.** An **integrity warning** (feature-007's `integrity.unbackedFacts`, surfaced as a warning callout) | feature-007's load-time check |
| unbacked `section` | — | **No, and no signal at all** | — |

**Four reasons the ledger stops where it does.** Each is independent, so weakening one does not open the
boundary:

1. **FR-26's evidence rule.** Every ledger row must carry the offending node as evidence, and FR-20
   defines the offending thing as a source artifact with no Knowledge Base representation. For an
   unbacked `document` the defect is *in* the Knowledge Base node itself, so the `Doc` and `Evidence`
   cells would invert their meaning — pointing a reviewer at the claim rather than at the thing that is
   undocumented. This is the same boundary FR-8a draws for convention absences and feature-005 draws for
   untyped edges and false-merge candidates: three different classes, one rule.
2. **Severity would have no derivation.** FR-26's severity derives from FR-21's significance qualifier,
   and `document`/`concept` qualify **by kind** under FR-21a with no qualifier at all (D4's second case).
   A `kb-unbacked` row would need either an invented severity or a second, weaker row shape — the same
   objection that keeps images out.
3. **An unbacked `fact` is structurally impossible, so reporting it as a coverage gap would misdescribe a
   different defect.** FR-30 emits a fact node **and its anchor edge together**, so an unbacked fact
   means the extraction is corrupt rather than the Knowledge Base incomplete. FR-13 as re-keyed calls
   this an **integrity warning**, and routing it to a gap ledger would send a reviewer to fix a
   Knowledge Base that is not at fault.
4. **`section` is a container, not a claim.** Read on the old `kb:` prefix the lens would flood with
   sections, which is the first of FR-13's two proxy defects (Q21). A section makes no claim of its own,
   so "unbacked" is not a property it can have.

**AC-15 is not breached by the asymmetry, and says so itself.** Its text scopes the equality to
`Kind = source-artifact`, records that the lens's unbacked signal is "a **lens-only signal** with no
corresponding ledger row", and states that "its presence does not breach this criterion" — and it records
the alternative (extending the ledger to emit `kb:`-unbacked rows) as considered and **not** adopted,
because FR-20 and FR-26 are explicitly source-artifact-keyed.

**What the asymmetry is not.** It is not "the lens shows more of the same class than the ledger". For the
ledger's own class the two are equal by construction — one predicate, two runtimes, verified by union and
mismatch reporting (D6). The extra lens signal is a **different class**, computed by a **different
export**, over a **different domain**, and written to no carrier. That distinction is what makes AC-15
testable: GL09 asserts the equality on one class *and* asserts that `kbUnbacked` ids appear in neither
`kb_gaps` nor the ledger.

**One inbound consequence, acknowledged — and it contains the family's last prefix-in-a-class-position
clause, which sits on the other side of the seam.** feature-007's D6d makes the lens-only signal's
**domain** kind-keyed (`{document, concept}`) while keeping its **test** prefix-keyed: "no incident edge to
a node whose `prefix` is `int:`", read literally from §2 item 1's "a `kb:` node with no `int:` edge". Under
the widened model that prefix spans `source-artifact` **and** in-repo `image`, so an in-repo image counts as
backing a Knowledge Base claim. feature-007 flags both halves — the domain narrowing and the prefix-keyed
test — and routes them together to the work owner as its Open Item 2, rather than settling a requirement's
wording as an author. That is the right disposition and this SPEC does not relitigate it. What matters here
is that **this feature's boundary does not depend on the answer**: whatever domain and test the lens-only
signal ends up with, it produces no ledger row, for the four reasons above. Recorded so the sweep is
visibly complete across the seam rather than only inside this document.

#### D7 — Two ledger scopes, and the D-6 shortfall

FR-25's "reports, never gates" and FR-28's "own artifacts only" are enforced by **file separation**,
because `.claude/aid/scripts/grade.sh` grades exactly one file passed as its argument and has no
row-filtering flag. Splitting by file makes conflation impossible rather than merely discouraged.

| Ledger | Path | Contents | Graded by `grade.sh`? | Lifecycle |
|---|---|---|---|---|
| Own-artifact findings | `.aid/.temp/review-pending/graph.md` | feature-010's FR-28 rubric failures only — id resolvability, inverse-pair consistency, provenance population, view validity | **Yes** — this file is the run's gate | Standard schema lifecycle: persists across REVIEW→FIX cycles, deleted at DONE |
| KB gap findings | `.aid/.temp/review-pending/graph-kb-gaps.md` | One row per `kb_gaps` entry | **Never.** No state passes this path to `grade.sh` | **Standard schema lifecycle — deleted at DONE — until D-6 lands.** See below |

Both paths obey C-6: the mandated directory, the mandated seven-column shape, no bespoke format. Both are
registered in the shared schema's **location** table (L3) so neither path is bespoke.

##### The retention carve-out is withdrawn, and what this feature does instead

The previous revision wrote a **named retention exception for `graph-kb-gaps.md` into
`reviewer-ledger-schema.md`'s lifecycle section.** That amendment is **withdrawn.** Q8 was resolved by
the owner on 2026-07-29: "The shared reviewer-ledger lifecycle deletes ledgers at skill DONE, which would
destroy the very gap findings FR-26 exists to deliver. This is a defect in the shared methodology, **not
something feature-006 should work around locally**, so it is lifted out of this work into its own item."
D-6 records the same thing from the dependency side. Writing the exception here is precisely the local
workaround that decision removed, and doing it anyway would also mean this feature silently amending a
project-wide lifecycle that every other skill obeys.

**So the shortfall is named rather than closed.** FR-26 has four obligations, and exactly one of them is
unmet:

| FR-26 obligation | Status while D-6 is unmet |
|---|---|
| The seven-column shape | **Met** — D5, GL05 |
| The mandated location | **Met** — D7's table, registered in the schema's location table |
| One row per gap, carrying the offending node as evidence | **Met** — D5, GL01–GL07 |
| The findings **survive to reach a reviewer** | **Not met.** The ledger is deleted with every other ledger at skill DONE |

**Interim behaviour, stated so an implementer needs no invention and a reader is not misled:**

1. **The ledger is still written**, in the right shape at the right path, on every run. Nothing about its
   content waits for D-6.
2. **The durable carrier is `kb_gaps` in `relationships.md`'s frontmatter.** It is not in `.aid/.temp/`,
   it is a key feature-003 D8 already reserves and places outside the byte-identity boundary, and
   feature-007 already reads it. So the *findings* survive DONE even while the *ledger* does not. This is
   not a second findings format and does not breach C-6: C-6 binds **reviewer output**, and `kb_gaps` is a
   generator-written record of the same computation, contracted upstream and consumed by the view.
3. **The routing block says so** (AC-G6): it names the ledger path, states that the ledger does not
   survive skill DONE until the retention change lands, names `kb_gaps` as what does, and prints the
   command that regenerates the ledger from durable inputs. Reproducible-on-demand is a weaker guarantee
   than retained, and calling it that is the point.
4. **`Fixed` and `Recurred` are unreachable in practice, and this is the sharpest consequence.** D5's
   Status transitions are computed by diffing against the previous ledger via `--previous`. If the ledger
   is deleted at DONE, no later run ever finds one, so every run is cycle 1 and every row is `Pending`.
   The transition logic is **still specified and still tested** (GL10, against a fixture that supplies a
   previous ledger — A-6 permits it, since fixtures are self-built), so nothing is owed when D-6 lands;
   what is missing until then is the input, not the mechanism.
5. **No claim is made that the carve-out exists.** Anywhere this SPEC would previously have relied on
   retention, it now relies on `kb_gaps` or says the behaviour is unavailable.

A cheaper alternative exists, is **not** adopted here, and restores less than advertised: feature-010
could stash the previous run's `kb_gaps` before EMIT overwrites `relationships.md`. Two limits follow from
this SPEC's own text. (a) `--previous` takes this feature's own prior **ledger** (D1; L2's "exactly these
two modes"), so the stash alone is **not** an input it can take — an interface change travels with the
option, and synthesising a ledger from the snapshot instead fails on (b). (b) A `kb_gaps` entry carries
`id`, `name`, `severity` and `qualifier` and **no `Status`** (D6, L3), and lists only the gaps current at
that run: it separates `Pending` (present, then present) from `Fixed` (present, then absent) but cannot
tell absent-then-present from a first-time gap, the `Fixed` row that would settle it having died with its
own run's ledger (obligation 4). **So a single-snapshot stash makes `Fixed` derivable and leaves `Recurred`
— which D5 defines over a prior `Fixed` that only a previous ledger's `Status` records — undecidable.**
Routed rather than taken (Open Item 2): it restores `Fixed` alone and not the *hand-off artifact* FR-27
routes onward — a partial substitute even easier to mistake for a full one than the old wording admitted.

**A correction feature-010 owes this section, routed and not applied.** feature-010 as currently written
does the opposite of what this table says: its DONE state deletes "**only** `.aid/.temp/review-pending/graph.md`"
and states that "`graph-kb-gaps.md` is retained (feature-006 §D7)" (its SPEC.md:497–498), and its `--reset`
row asserts that "the previous `graph-kb-gaps.md` must survive so the `Fixed` / `Recurred` transitions of
feature-006 still work" (:138). Both cite this section as their authority, and this section no longer says
that — the retention carve-out is the thing the revision above **withdrew**. The lifecycle in the table is
therefore the operative one and feature-010's retention is a correction owed, **not** an alternative
reading: Open Item 3 records it with its owner. Stated here rather than only in the Open Items because a
reader arriving from feature-010 will land on this table first.

### Feature Flow

Runs as one state of the `/aid-graph` state machine (feature-010 owns the machine; this feature owns the
state's body — see L1). Every step below reads real paths.

1. **Enter GAP-REPORT.** Precondition asserted by feature-010's dispatch: EMIT has completed, so
   `.aid/knowledge/relationships.md` exists and contains the final post-pass-2 table.
2. **Load the previous gap ledger** if `.aid/.temp/review-pending/graph-kb-gaps.md` exists, so existing
   row numbers, severities and descriptions are preserved and only `Status` moves (the schema's
   append-only rule). Absent file → this is cycle 1 and every row starts `Pending`, which while D-6 is
   unmet is **every** run (D7).
3. **Read the candidate inventory and assert its kind.** Read `.aid/.temp/graph/nodes.tsv` through D1a's
   field map. For every row, assert `node_kind == 'source-artifact'`; a row of any other kind is exit 2
   with no ledger written (AC-G1). Assert `qualifier` is one of D4's four values; otherwise exit 2
   (AC-G3). `media-nodes.tsv` is **not read by the detector at all** — no flag names it (L2), so it is
   neither a candidate source nor any other kind of input here; AC-G2's disjointness against it is asserted
   by the suite, which reads both files directly (D1, GL15).
4. **Read the table into an edge list** and count the rows whose relation is outside the core vocabulary,
   for the F6 counter (AC-G5). "Outside the core" means **not a key of `RELATION_CATEGORY`**, imported from
   `coverage-predicate.mjs` alongside the predicate itself (D6, L2) — one module, one import, no second
   input and no vocabulary file read at run time.
5. **Call the shared predicate.** `detectArtifactGaps({ nodeIds, edges })` (D2) with `nodeIds` = **every**
   enumerated `source-artifact` id, including those appearing in no row. Decorate each returned id with
   its `name`, `qualifier` and `evidence` from the same inventory. Result: the ordered gap set.
   `kbUnbacked` is not called here — it is lens-only (D6a). No predicate logic is written in this feature.
6. **Write `kb_gaps` into `.aid/knowledge/relationships.md` frontmatter** (D6). This is the only write
   this feature performs inside `.aid/knowledge/`, and `relationships.md` is on `/aid-graph`'s own
   write-allowlist (feature-010's FR-10 fence), so the AC-13 fence is not tripped.
7. **Write the ledger.** Emit `.aid/.temp/review-pending/graph-kb-gaps.md` as a single seven-column table
   and nothing else. Status transitions per D5 against the step-2 file.
8. **Print the routing block** (see below), including the D-6 statement of AC-G6 and the F6 counter. Never
   invoke a repair skill, never open a ticket.
9. **Exit 0 whatever the gap count** — see the FR-25 enforcement below.
10. **Advance: CHAIN** to feature-010's next state
    (`.claude/aid/templates/state-machine-chaining.md` §CHAIN — this is a mechanical state with no user
    interaction, so it must not pause).

**Where the gap count is *not* recorded, and why.** Not in FR-9a's `## Coverage notes`. feature-003 D7
places that section **inside** FR-32/AC-5's byte-identity guarantee, and a gap count legitimately varies
between runs over an unchanged tool, so a count there would break AC-5 for a reason that is not drift.
This is the boundary feature-005 Open Item 10 already established for its Pass-2 disposition count. The
count goes to stdout (transient) and the gap **list** goes to `kb_gaps` (durable, and outside the
byte-identity boundary by feature-003 D8's explicit design).

#### How FR-25 is enforced structurally

Four independent mechanisms, none of which is a convention a later edit could quietly drop:

| # | Mechanism | Why a violation is impossible rather than unlikely |
|---|---|---|
| S1 | **File separation** (D7) | The gate reads `graph.md`. The gap rows are in a different file. `grade.sh` cannot see them because it is never given that path |
| S2 | **The exit status is independent of the gap count** | `detect-kb-gaps.mjs` exits `0` whether it emits zero rows or five hundred, following the precedent of `canonical/aid/scripts/summarize/stale-check.sh`, whose header states "Exit 0 always (the 'decision' is informational, not a failure)". Gap count is reported on stdout, never in the exit status. Reserved: `2` for a usage, argument or **input-contract** error only (D1a, D4), per `.aid/knowledge/coding-standards.md` Exit Codes. That reservation does not weaken S2 — a malformed candidate stream is a scanner bug on a different axis from "gaps exist", and feature-004's own single writer aborts on the same class of condition |
| S3 | **The state's Advance line has no failure branch** | `state-gap-report.md` declares a single `**Advance:** CHAIN` with no conditional. There is no route from this state to FIX, to a blocked lifecycle, or to a non-zero skill exit. Adding one would require editing the Advance line, which is a visible, reviewable change |
| S4 | **A test asserts the property, over a fixture built to fail** | `tests/canonical/test-graph-gap-ledger.sh` (L4) constructs a fixture whose Knowledge Base deliberately covers nothing, runs the detector, and asserts a non-empty ledger **and** exit 0. The many-gaps case is the tested case, not the untested one |

S1 also settles the FR-28-versus-this-feature question: the skill's gate and this ledger cannot be
conflated because they are not the same file, and neither state reads the other's path.

#### Routing hand-off (FR-27)

DONE prints a routing block. It names commands the user runs; the skill runs none of them, opens no
ticket, and writes nothing into `.aid/knowledge/STATE.md` (which would violate AC-13).

```
KB gaps: 7 (3 HIGH, 2 MEDIUM, 2 LOW) — 2 with no relationships at all
         most in one subtree: site/src/ (4)
Ledger:  .aid/.temp/review-pending/graph-kb-gaps.md   (not graded; the run succeeded)
         NOT RETAINED past skill DONE until the ledger-retention change lands (D-6).
         Durable copy of the findings: kb_gaps: in .aid/knowledge/relationships.md
         Reproduce the ledger:  /aid-graph --reset
Rows typed by a project-extension relation: 0   (coverage is evaluated over the core vocabulary only)

Route onward — /aid-graph does not fix gaps:
  Targeted, one gap or a named few:
    /aid-update-kb "document canonical/aid/scripts/graph/detect-kb-gaps.mjs in module-map.md"
  Broad sweep, many gaps or a whole subsystem:
    /aid-housekeep          # KB-DELTA re-discovers drifted docs against the repo
```

The two targets are chosen from their own declared boundary, not invented here:
`canonical/skills/aid-update-kb/SKILL.md` describes itself as "the prompt-driven-targeted half of the KB
freshness loop" whose `argument-hint` is `<what changed / what to update in the KB>`, and routes the
"source-driven-global sweep" to `aid-housekeep`'s KB-DELTA job. A single named gap is
prompt-driven-targeted; a subsystem's worth is source-driven-global. The `[HIGH]` rows are listed first
in the block so the suggested `/aid-update-kb` instruction is drawn from the most consequential gap.

**The "no relationships at all" count is a slice of the rows already in the ledger.** Every one of those
nodes has its own row, its own severity and its own evidence; the count is there only because "this
artifact has no relationships whatsoever" is a stronger statement than "this artifact is undocumented"
and a reader should not have to infer it by reading `Description` cells. If the slice is empty the clause
is omitted rather than printed as `0`.

**The extension-relation counter is printed even when it is zero, and the difference from the clause above
is deliberate.** A `0` for the no-relationship slice is noise: it says nothing about rows that are already
in the ledger. A `0` for the extension counter is an affirmative statement — *coverage was evaluated over
the core vocabulary alone, and nothing on this project was typed by anything else* — which is exactly what
a reader needs to know whether F6's blind spot is live for them. This is the same reasoning FR-9a applies to
the coverage notes, which are written on every run and not only when something is missing (AC-20).

**Gap clusters are reported as ordinary rows, plus one summary line** *(feature-004 Open Item 10,
discharged)*. feature-004 records that a large, conventionally-organised tree with no AID-authored naming
rule — `site/src/**` on this repository — will qualify mostly via `depended-upon`, so its Knowledge Base
coverage is thinner than the toolkit's and this feature will report a cluster of `[MEDIUM]` rows there.
That is a **true finding about the Knowledge Base**, not a detector artefact, so nothing is aggregated
away and nothing is suppressed: suppressing a cluster is the first form of the FR-21-loosening pressure
FR-25's rationale exists to prevent, and it would hide exactly the subsystem a `/aid-housekeep` sweep
should target. What the block adds is one deterministic line naming the **top-level path prefix holding
the most rows** and its count, computed by grouping the emitted rows' `Doc` cells on their first two path
segments and taking the largest — so a cluster reads as a cluster and the broad-sweep branch is the
obvious response. The line is omitted when no group holds more than one row.

### Layers & Components

Canonical-first: the skill, script, and template files below (L1–L3) are authored under `canonical/` and
rendered to the five profile trees plus the dogfood `.claude/` by the full generator
(`.aid/knowledge/module-map.md` Invariants — "Single source of truth"). The test suite (L4) lives under
`tests/canonical/`, which is repository test infrastructure and is not rendered. **feature-012** owns the
render and the manifest/count lockstep and **feature-013** owns the documentation surfaces; this feature
owns the content of the files it introduces.

#### L1 — Skill state body (the feature-010 seam)

| File | Owner | This feature's obligation |
|---|---|---|
| `canonical/skills/aid-graph/SKILL.md` | **feature-010** | Contributes exactly one row to the Dispatch table: `\| GAP-REPORT \| references/state-gap-report.md \| inline \| → RENDER \|` (the successor feature-010's state machine declares), and the corresponding node in the "you are here" map. No other edit to this file |
| `canonical/skills/aid-graph/references/state-gap-report.md` | **feature-006** | Owned outright. Names the shared predicate the state calls (D2 — it restates no predicate logic), and carries the D4 severity rule, the D5 row form, the routing block including its D-6 statement, and the single unconditional `**Advance:**` line of S3 |

Stated this explicitly so `/aid-detail` produces one task that edits `SKILL.md` (feature-010's) and a
separate task that creates `state-gap-report.md`, rather than two tasks editing the same file.

#### L2 — Helper script

`canonical/aid/scripts/graph/detect-kb-gaps.mjs` — a new script in the `graph/` script area, placed per
`.aid/knowledge/module-map.md` Conventions ("Where a new helper script goes: place it under the phase
area it serves").

**It is Node, not bash, and the reason is D6.** The predicate has exactly one implementation, and that
implementation is an ES module the browser also loads. Bash cannot `import` an ES module, so a bash
generator would have to restate the predicate in awk/grep — reintroducing a second implementation and the
fork C-4 forbids. feature-007 D10 allows either a bash CLI shelling out to a thin `.mjs` or an outright
`.mjs`; **this feature takes the outright `.mjs`**, because the wrapper would exist only to preserve a
`.sh` extension and would add a process boundary with nothing on the near side of it. The `.mjs`
extension follows the precedent already set in the sibling script area, where
`canonical/aid/scripts/summarize/validate-visuals.mjs` and `contrast-check.mjs` are Node entry points
called from bash-driven skill states. *(feature-007's D10 says shape (a), the bash wrapper, "is the one
assumed here" while permitting either; the shape taken is (b), and the one-line prose correction is Open
Item 4.)*

**Why the name still says `kb-gaps` when the class is `source-artifact`.** Both names are accurate about
different things and neither is a proxy: the **class** the detector computes is `Kind = source-artifact`
(hence the export `detectArtifactGaps`), while the **finding** it reports is a *Knowledge Base gap* —
FR-20's own words, "reported as a KB gap (a defect)". The script, the ledger file
(`graph-kb-gaps.md`) and the frontmatter key (`kb_gaps`, reserved under that name by feature-003 D8) all
name the finding; the module's export names the set. Recorded so the mismatch is not later "fixed" into a
rename that would churn a gated frontmatter contract for no gain.

It sits beside `coverage-predicate.mjs` in the same `graph/` area, so the import is a plain relative
sibling specifier. Two consequences of `.mjs` being in `render.py`'s `_TEXT_EXTENSIONS` apply to this file
as they do to the module: it is text-processed at render, so it must carry **no `canonical/…` path and no
filename placeholder** — every path it touches arrives through the flags below.

Justified against `.aid/knowledge/authoring-conventions.md` "Prose Over Scripts", which says a script is
added only when real logic warrants it: the Status transitions require diffing against a previous ledger
file, severity and evidence must be joined from a second inventory through a field map, the input
assertions of AC-G1/AC-G3 must abort rather than degrade, and S4 needs a callable unit to test. That is
real logic, not state or argument shuffling.

Conforming to `.aid/knowledge/coding-standards.md` § JavaScript / Node Conventions and its Exit Codes
rule:

- ES module syntax, Node ≥ 20 (C-5, the floor `graph-preflight.sh` P5 asserts);
- a header comment block stating Purpose / Usage / Exit codes, matching the shape `validate-visuals.mjs`
  uses;
- exit codes `0` for any gap count, `2` for a usage, argument or input-contract error. No other code is
  defined, because no other outcome exists — this is what keeps S2 honest;
- stdout carries the result (the gap counts, the no-relationship slice, the cluster line, the F6 counter
  and the ledger path); stderr carries diagnostics, messages prefixed `detect-kb-gaps.mjs: `;
- any configuration read through `canonical/aid/scripts/config/read-setting.sh`, never by parsing
  `.aid/settings.yml` directly.

Interface:

```
node detect-kb-gaps.mjs --table PATH --nodes PATH --output PATH [--previous PATH]
node detect-kb-gaps.mjs --explain NODE_ID --table PATH --nodes PATH
```

The write mode takes four paths, all explicit with no baked-in default, so the fixture of S4 supplies its
own and satisfies A-6 (fixtures are self-built and depend on no work folder's contents). `--explain` is
the read-only mode the `Evidence` cell's recheck command invokes (D5): it prints the named artifact's
table rows, the Knowledge Base→artifact relation on each, and the covered/uncovered verdict from the same
one predicate, and exits `0`. It writes nothing. **`--explain` takes three arguments, not one** — the id
plus both input paths — because the no-baked-in-default rule binds this mode too; that is why D5's
`Evidence` cell spells all three out, and why a cell carrying only `--explain <id>` would exit 2.

**Every flag is declared here and there are exactly these two modes.** There is no flag for
`media-nodes.tsv` (D1: it is a suite-level input, not a detector one, and GL15 reads it directly), and no
`--vocabulary` flag: `COVERAGE_BEARING` is a compile-time constant inside `coverage-predicate.mjs`, kept in
lockstep with the reviewable subset of D2a by feature-007's GV04, so passing the vocabulary in at run time
would create a second way for the two to disagree.

**Where the F6 counter's data comes from — a constant that must move, not an export to confirm.** Step 4
needs the core relation names, and they live in `RELATION_CATEGORY`. feature-007 currently declares that
constant in **`graph-model.js`** (its SPEC.md:291 — "a build-time constant (`RELATION_CATEGORY` in
`graph-model.js`)"; :1334, which assigns the constant to that file; :1434, which lists it among that
file's API exports), and its export table for `coverage-predicate.mjs` (:1103–1110) lists only
`COVERAGE_BEARING`, `isCovered`, `detectArtifactGaps` and `kbUnbacked`. `graph-model.js` is browser-only
and D6 forbids the Node side importing it, so as those two contracts stand today **the F6 counter has no
reachable data source** — and an earlier revision of this section asserted the opposite, that
`coverage-predicate.mjs` "already exports" `keys(RELATION_CATEGORY)`. That claim is **false and is
withdrawn** — and it contradicted, inside one document, that same revision's coordination obligation 3 and
Open Item 4, which said the constant "must be exported, not merely internal". Both halves were wrong in the
same direction: the export does not exist, *and* adding an export keyword would not have been the fix.

**The decision: `RELATION_CATEGORY` is authored in `coverage-predicate.mjs`, and `graph-model.js` reads it
from there.** This applies the precedent this work already set for the identical problem — the coverage
predicate itself was unified into one shared ESM module executed in both runtimes rather than duplicated
per runtime — and it holds for four reasons that are all properties of the constant rather than
conveniences: it is **frozen and build-time**, so it has no runtime state to be near;
`coverage-predicate.mjs` is **already reached by both runtimes** — imported under Node, inlined
byte-identically in the browser — so no new dependency edge appears anywhere;
`graph-model.js` is **browser-only**, so it is the wrong home for data a Node process needs; and moving it
makes feature-007's **GV05** (`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`) a check **inside a single
file** rather than one spanning two. So the move strictly **reduces duplication** — the only other way to
give the Node side those names without breaching D6 is a second copy of them inside the detector, a second
source of truth for the vocabulary's keys and the same class of fork the 2026-07-28 finding already removed
once from the predicate itself — and strictly **increases what is checkable**. **No `import` is added on either side, so GV01 is unaffected:** `coverage-predicate.mjs`
gains one `export const` and still imports nothing (feature-007's boundary rule 1), and the view's files
need no import to see it, because feature-007 concatenates the shared module first into **one** module
scope in which "the view's own files declare no `import` statements and reference the shared exports
directly" (:1088–1090). Whether `graph-model.js`'s documented API surface (:1434) keeps naming
`RELATION_CATEGORY` as a re-export is feature-007's call and changes nothing here. This is a **move between
two files feature-007 owns**, not an export keyword — coordination obligation 3, routed as Open Item 4, and
pinned from this side by GL12.

**No marker file, and no other new file in this area.** The earlier
`canonical/aid/templates/knowledge-graph/package.json` requirement is withdrawn with the module repoint
(D6) — `.mjs` needs none.

#### L3 — Shared-contract amendments and one new file

All three live under `canonical/aid/templates/`, so all three require a full generator run afterwards
(feature-012's obligation, `.aid/knowledge/tech-debt.md` Gotchas — "Render-drift needs the FULL
generator").

| File | Amendment |
|---|---|
| `canonical/aid/templates/reviewer-ledger-schema.md` | **Two rows in the "File: location" scope table only** — `/aid-graph` own-artifact validators → `graph.md`, and `/aid-graph` KB-gap findings → `graph-kb-gaps.md`. Registering the paths is what keeps them non-bespoke under C-6, and it changes no rule. **The retention exception the previous revision added to "Lifecycle (per skill invocation)" is withdrawn** — that is D-6's own work item (D7), not this feature's amendment to make |
| `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | The `kb_gaps:` generator-written field, in the same class as `generator:` and `graph_inputs_digest:`, with its four-key entry shape (`id`, `name`, `severity`, `qualifier`) and its sole producer named |
| `canonical/aid/templates/graph/coverage-bearing.yml` | **New** (D2a). One top-level `coverage_bearing:` block sequence of relation tokens, plus a header comment carrying the selection criterion and the exclusions. Verbatim-rendered (`.yml`); no loader reads it; feature-007's GV04 binds it to the executable copy |

Neither amendment changes an existing rule, so no existing ledger or Knowledge Base document is
invalidated. The new file adds one entry to the manifests, which is feature-012's lockstep obligation
(C-3).

#### L4 — Tests

`tests/canonical/test-graph-gap-ledger.sh`, discovered automatically by the glob
`tests/canonical/test-*.sh` — `.aid/knowledge/test-landscape.md` states adding a suite needs no edit to
`tests/run-all.sh`. It builds its own fixture tree under `mktemp -d` in the style of
`tests/canonical/test-guardrails-d012.sh` (which writes its own compliant `kb.html` inline), so A-6 holds
and nothing depends on `.aid/works/work-005-knowledge-graph/`.

| ID | Assertion |
|---|---|
| GL01 | A node with a `COVERAGE_BEARING` edge to a Knowledge Base node produces **no** row, at any `Provenance` value including `inferred` (D2, F3) |
| GL02 | A node covered only through an ancestor path produces **no** row (F2). The fixture must **construct** this shape — a directory endpoint in the table plus a descendant node in the inventory — because feature-004's current collapse rules emit no such pair (F2), which is precisely why the assertion is worth having: it is the only place the totality half of condition 1 is exercised at all |
| GL03 | **The F4 invariant holds at the seam:** every id in feature-004's fixture inventory carries `evidence_provenance` of `declared` or `derived`, and no id present in `candidates.tsv` appears in the ledger. This asserts the invariant this feature depends on rather than a filter it applies — it goes red if feature-004's guarantee is ever weakened (D3 F4) |
| GL04 | **Severity is a total function of `qualifier`:** `entry-point` and `public-surface` each yield `[HIGH]`, `depended-upon` yields `[MEDIUM]`, `named-unit` yields `[LOW]`; the fixture exercises **all four** values; and a fifth, unknown value yields **exit 2 with no ledger written** rather than a defaulted severity (D4, AC-G3). *(This replaces the previous revision's "a node satisfying two clauses takes the higher", which asserted a tie-break feature-004's one-qualifier-per-node record makes unreachable.)* |
| GL05 | The emitted file is exactly one seven-column table — no frontmatter, no heading, no summary section (C-6, and the schema's anti-`## Summary` rule) |
| GL06 | Every `Line` cell is `—`; every `Doc` cell is a repo-relative path that exists in the fixture; and a **directory** node id yields a `Doc` cell carrying its trailing `/` (D5, AC-16) |
| GL07 | **FR-25:** a fixture with many gaps yields a non-empty ledger and exit status 0 (S4, AC-14) |
| GL08 | `grade.sh` over `graph.md` returns `A+` while `graph-kb-gaps.md` holds `[HIGH]` rows — proving the gap rows are invisible to the gate (S1) |
| GL09 | **AC-15:** the `kb_gaps` id list, the ledger `Doc` column, and an in-test call to `detectArtifactGaps` over the fixture's **full node inventory** plus its table are the same set; and `kbUnbacked` ids from that same fixture appear in **neither** `kb_gaps` nor the ledger (D6, D6a — the lens-only scope) |
| GL10 | Re-running against a previous ledger moves a now-covered row to `Fixed` and a re-broken row to `Recurred`, and renumbers nothing (D5). The fixture **supplies** the previous ledger, which is why this assertion is meaningful while D-6 leaves the transitions unreachable on a real run (D7) |
| GL11 | `grade.sh` over a ledger whose rows are all `Fixed` returns `A+`, confirming the Status enum is being written in the form `grade.sh` counts |
| GL12 | The shared module loads under Node with no marker file — `import { detectArtifactGaps, kbUnbacked, COVERAGE_BEARING, RELATION_CATEGORY } from '../graph/coverage-predicate.mjs'` succeeds from the detector's own directory, and `canonical/aid/scripts/graph/` contains **no** `package.json` (D6). **This is also the assertion that pins the `RELATION_CATEGORY` move** (L2, coordination obligation 3): if the constant stays in `graph-model.js`, this import fails to bind it and the F6 counter has no source, so the row goes red at the seam rather than the counter silently reporting zero |
| GL13 | **The zero-row case:** a fixture whose inventory contains an enumerated node appearing in **no** table row yields a ledger row for it with the correct severity from its `qualifier`, a `kb_gaps` entry carrying both `id` and `name`, and a `Description` ending `; no relationships in the table)` — closing parenthesis included, because D5's fixed form closes it after that clause, so a suffix assertion written without it fails against a correct implementation (D2, D5). Removing the node from `nodes.tsv` — leaving the table untouched — makes the row disappear, proving the candidate set is the inventory and not the table |
| **GL14** | **The keying, from the input side (AC-G1):** a `nodes.tsv` carrying one row whose `node_kind` is `image` causes **exit 2 and no ledger file**, and the message names the offending id and field. Without this the correctness of the class rests on feature-004's stream split alone, which is a property of another feature's implementation rather than a check in this one |
| **GL15** | **The keying, from the output side (AC-G2):** over a fixture whose tree contains an unreferenced in-repo image that also satisfies a significance clause, no ledger `Doc` cell has an extension in `image_extensions:` — compared **case-folded**, per feature-004 D2a point 5, so an upper-case `LOGO.PNG` is caught — the image's id appears in `media-nodes.tsv` and **not** in `nodes.tsv`, and the `kb_gaps` id set is disjoint from `media-nodes.tsv`'s. These are feature-004's own fixture cases (its `test-graph-media-nodes.sh` builds the same shapes, including the upper-case instance) read from the consumer end |
| **GL16** | **The evidence never contradicts its row (AC-G4):** for a node whose only table rows are `mentions` edges, the row is emitted **and** `--explain` on that id lists those rows, names `mentions` as the Knowledge Base→artifact relation, and returns `uncovered`. The recheck is invoked **exactly as the emitted `Evidence` cell spells it** — parsed out of the cell and run verbatim, flags and paths included, against the fixture's own paths — so an incomplete command is a test failure and not a documentation nit. A `grep -c` recheck over the same fixture returns non-zero, which is why that form was withdrawn (D5) |
| **GL17** | **The F6 counter is reported (AC-G5):** a fixture whose table carries a row typed by a relation outside `RELATION_CATEGORY` reports a non-zero extension-relation count on stdout, and the same fixture with no such row reports zero |
| **GL18** | **The D-6 statement is present (AC-G6):** the routing block names the ledger as not retained past DONE, names `kb_gaps` as the durable carrier, and prints the reproduce command; and `reviewer-ledger-schema.md` contains **no** retention exception for `graph-kb-gaps.md` — asserted as an absence so a future well-meaning local carve-out fails the suite |
| **GL19** | **The cluster line is deterministic:** a fixture whose gaps concentrate in one two-segment path prefix reports that prefix and its count; a fixture with no group above one row omits the line entirely |
| **GL20** | **The routing hand-off happens and nothing else does (FR-27, and the no-ticket rule of REQUIREMENTS.md §4 Out of Scope — "Automatic ticket creation" for detected gaps, its :166, which is where this SPEC's § Source already attributes it):** over a fixture with gaps, stdout names **both** `/aid-update-kb` and `/aid-housekeep` as the route onward (§ Routing hand-off), and **no ticket is opened** — asserted as two absences, since that is the only way to test a negative: the run's writes are exactly the two declared outputs (the ledger path and `relationships.md`'s frontmatter) and no other file appears anywhere in the fixture tree, and `detect-kb-gaps.mjs` together with `state-gap-report.md` contain no reference to `/aid-create-ticket`, `/aid-update-ticket` or `/aid-read-ticket`. **AC-13 has no ticket clause and no second half** — its whole content is "No KB file is modified by any run" (REQUIREMENTS.md:951) — and it is not re-asserted here at all: it is feature-010's write fence (Feature Flow step 6), and duplicating it would put a second, weaker copy of another feature's rule in this suite — the objection D3 F4 already makes |

GL08 and GL11 are the two assertions that would fail if a future change filtered by row instead of by
file, or wrote a Status value outside the schema's enum. GL14, GL15 and GL18 are the three that would fail
if the gap class drifted back to the prefix or the retention workaround came back. **GL20 is the one that
would fail if the reporting-only boundary eroded** — a future edit that "helpfully" filed a ticket, or
dropped the route onward and left the reader with a ledger and no next step, fails it; FR-27's whole content
is that hand-off, so it gets an assertion rather than only a specified format.

### Migration Plan

Nothing existing changes shape; two shared contracts gain content, one new template file is added, and
one Knowledge Base doc gains a row.

| Step | Change | Verification |
|---|---|---|
| 1 | Add `detect-kb-gaps.mjs` to the `graph/` script area, beside feature-007's `coverage-predicate.mjs` (L2). No marker file | `bash tests/canonical/test-graph-gap-ledger.sh` |
| 2 | Add `coverage-bearing.yml` (L3, D2a) | feature-007's **GV04** once `coverage-predicate.mjs` is authored; until then, review against D2a's criterion table |
| 3 | Amend `reviewer-ledger-schema.md` (location rows **only**) and `frontmatter-schema.md` (L3) | `bash tests/canonical/test-grade.sh` still passes — the amendments add scopes and a field, and change no parsing rule; **GL18** asserts the lifecycle section gained no exception |
| 4 | Add a `graph/` row to `.aid/knowledge/module-map.md` "Script Modules by Area" at ship time | The doc's own review gate |
| 5 | Run the FULL profile generator, then confirm no render drift | `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` |

Step 4 is **feature-013's** ship-time Knowledge Base update and step 5 is **feature-012's** render and
manifest mechanism (both were feature-011's before its three-way split); they are listed here because
steps 1–3 are not complete without them.

**Deliberately left open.** `COVERAGE_BEARING`'s four members are **selected** here (D2a) but become
mechanically checkable only when feature-001's `relation-vocabulary.yml` is authored (D-1). This SPEC
fixes the selection, its criterion, and the file it is recorded in, so `/aid-detail` can schedule the
work; the executable constant is written by the task that authors `coverage-predicate.mjs` (feature-007's
file), and feature-007's GV04 binds the two copies.

**Coordination obligations on feature-007, stated so they are scheduled and not discovered.** Obligations 1
and 2 land inside `coverage-predicate.mjs` or its type surface; obligation 3 spans **that file and
`graph-model.js`**, because it is a move between them. All three files are feature-007's, so `/aid-detail`
must produce **one** task covering them, dependent on both features, rather than several tasks editing the
same lines.

| # | Obligation | Status |
|---|---|---|
| 1 | The predicate's three conditions, the direction rule of condition 3, and the `COVERAGE_BEARING` selection are this feature's semantics, authored into feature-007's module | feature-007's D10 adopts them verbatim and re-keys condition 2 to the four Knowledge Base kinds; the direction rule and the selection are **new with this revision** |
| 2 | `recordedGaps` widens to `{id, name, severity, qualifier}` — `name` was already required by feature-007 D10; the fourth key is **renamed** from `clause`, values unchanged (D6) | **New with this revision** — one key name; Open Item 4 |
| 3 | **`RELATION_CATEGORY` moves out of `graph-model.js` and is authored in `coverage-predicate.mjs`**, which exports it; the F6 counter imports it there to decide whether a row's relation is outside the core (D3 F6, step 4, L2) | **New with this revision, and larger than the previous revision claimed.** This is a **move between two feature-007 files**, not an export-surface confirmation: feature-007 places the constant in the browser-only `graph-model.js` (its SPEC.md:291, :1334, :1434) and its `coverage-predicate.mjs` export table (:1103–1110) does not list it, so nothing on the Node side can reach it without breaching D6. **Consequences named:** GV05 (`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`) becomes a check inside one file instead of one spanning two; GV01 is unaffected, because no `import` is added on either side (the module still imports nothing, and the view's concatenated single module scope needs none — feature-007 :1088–1090). Routed as Open Item 4 |

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the methodology,
that owner is named and the item is **not** absorbed here. Per **Q18 ruling 3** and **Q20 (loader sync)**, an item
routed **into** a SPEC already gated A+ is a **pending reopen, not a note** — it must be scheduled before
that SPEC's grade is relied upon — and each such item says so. None blocks this feature's own
implementation; **item 1 blocks its delivery**, which is a different thing and is stated as such.

**Numbering note, because these numbers are cited across features.** The previous revision's **item 2** —
feature-004's missing carrier → `qualifier` mapping — is **closed as discharged** this revision and has
moved to the Discharged list below; the survivors are renumbered, and one new item (**3**, feature-010's
withdrawn-authority retention) is inserted beside its sibling. So a citation to "feature-006 Open Item N"
made against an earlier revision of this file may not resolve to the same item. That is the Q20 (loader
sync) hazard stated against itself: a cross-reference outlives the text it cites unless someone says it moved.

1. **The ledger-retention change (D-6 / Q8) — the one item that blocks this feature's deliverable.** The
   shared reviewer-ledger lifecycle deletes ledgers at skill DONE, so FR-26's fourth obligation — that
   the findings survive to reach a reviewer — cannot be met, and `Fixed`/`Recurred` are unreachable
   (D7). Q8 resolved that this is a defect in the **shared methodology**, lifted out of this work into
   its own item, so this SPEC states the shortfall and its interim rather than writing a local
   carve-out. **Owner: the ledger-retention methodology work item** (raised 2026-07-29 under Q8). *Not a
   reopen of any SPEC in this work: the artifact to change is
   `canonical/aid/templates/reviewer-ledger-schema.md`'s lifecycle section, which no feature here owns.*
2. **Restoring `Fixed` — not `Recurred` — without the methodology change.** feature-010 could stash the
   previous run's `kb_gaps` before EMIT overwrites `relationships.md`. **D7 sizes it, and the sizing is part
   of this decision:** the stash alone is not an input `--previous` can take (that flag takes this feature's
   own prior **ledger**), so an interface change travels with the option; and `kb_gaps` carries no `Status`
   key, so one snapshot makes **`Fixed`** reachable while D-6 is still open and leaves **`Recurred`**
   undecidable. Recorded as an option and **not adopted here** — the reason is unchanged and the sizing
   strengthens it: it restores `Fixed` alone and not the hand-off artifact FR-27 routes onward, and a partial
   substitute presented as a fix is how D-6 would quietly stop being scheduled. **Owner: feature-010** (run
   orchestration; ungated — no reopen consequence), **with the work owner** on whether that partial
   restoration — `Fixed` alone, at the price of an interface change — is wanted before D-6.
3. **feature-010's DONE and `--reset` clauses retain `graph-kb-gaps.md` on an authority this SPEC has
   withdrawn, so the retention must be removed when feature-010 is re-specified.** *(New 2026-07-30.)*
   feature-010's DONE state deletes "**only** `.aid/.temp/review-pending/graph.md`" and records that
   "`graph-kb-gaps.md` is retained (feature-006 §D7)" (its SPEC.md:497–498), and its `--reset` row states
   that "the previous `graph-kb-gaps.md` must survive so the `Fixed` / `Recurred` transitions of
   feature-006 still work" (:138). Both cite **§D7** — and the §D7 they cite is this SPEC's *previous*
   revision, which carried a retention carve-out in `reviewer-ledger-schema.md`. This revision **withdrew**
   that carve-out (D7, and STATE.md **Q22**, which records the withdrawal), so the citation is **expired
   rather than wrong when made**: the class Q20 (loader sync) exists to catch, and the second instance of
   it in this work.
   **D7 stands unchanged and is the operative lifecycle** — the ledger is deleted with every other ledger
   at DONE, `Fixed`/`Recurred` are unreachable, and every run is cycle 1. This SPEC neither adopts
   feature-010's retention nor edits feature-010: STATE.md **Q8** ruled that the retention fix is a
   methodology work item and explicitly **not something this feature works around locally**, and a
   skill-local skipped delete is a *worse* workaround than the withdrawn schema amendment, because a schema
   amendment is at least visible to everyone reading the schema. The correction owed is therefore to delete
   the retention from both clauses and let `--reset` keep only its actual mechanism (discarding the
   recomputed-digest comparison). Routed rather than applied per this SPEC's own rule in § Source —
   "Where this SPEC needs something from one of them that it does not state, that is an Open Item, not an
   assumption" — and per the one-writer-per-file discipline that keeps two features from editing one
   lifecycle in opposite directions. **Owner: feature-010 — ungated; no reopen consequence** (scheduled
   with its re-specification, so nothing here is blocked on it). Item 2 above is the *only* sanctioned way
   to restore a Status transition early, it reaches `Fixed` and not `Recurred`, and it too is unadopted.
4. **Three corrections in feature-007 — two prose, one a file-placement move.** (a)
   `recordedGaps`'s fourth key is `qualifier`, not `clause` (D6). (b) D10 states that shape (a) — a bash
   CLI shelling out to a thin `.mjs` — "is the one assumed here"; this feature takes shape (b), the
   outright `.mjs`, which D10 explicitly permits (L2). (c) **`RELATION_CATEGORY` moves** from
   `graph-model.js` into `coverage-predicate.mjs`, which exports it, so the F6 counter has a source the
   Node side may reach (coordination obligation 3, L2). (c) is not a one-line export keyword and is not
   described as one: feature-007 declares the constant in `graph-model.js` (its SPEC.md:291, :1334, :1434)
   and omits it from `coverage-predicate.mjs`'s export table (:1103–1110), while this SPEC's D6 forbids the
   Node side importing the view model — so today the counter has no reachable data source at all. The move
   is the resolution, its rationale is at L2, and its consequences are GV05 becoming checkable inside one
   file and GV01 being unaffected (no `import` is added on either side; the view's files sit in one
   concatenated module scope, :1088–1090). **Owner: feature-007 — ungated; no reopen consequence.**
5. **`COVERAGE_BEARING` is selected but not yet checkable, and one exclusion is a live question rather
   than a settled one.** GV04 and GV05 become runnable when `relation-vocabulary.yml` is authored with
   feature-001's 31 pairs; if the authored file renames or drops any of `documents`, `cites`,
   `cites-as-evidence` or `derived-from`, the selection must be re-derived from D2a's criterion rather
   than patched. Separately, **`implemented-by` has a real semantic case for membership** (a Knowledge
   Base document specifying behaviour an artifact realises does account for that artifact) and is
   excluded today for two current reasons: membership is by `relation` key so GV05's containment cannot
   hold for an `inverse` name, and the pair is `inferred`-only with no class-0 producer. Closing it needs
   either **directed member tokens** (`implements:T2S`) with GV05 widened accordingly, or a producer.
   **Owners: feature-001** (the file's contents — *no change requested to its SPEC, so no reopen*), **with
   feature-007** for the token shape and GV05 (ungated), **and the work owner** on whether specification
   documents should clear a coverage gap at all.
6. **A project extension cannot widen `COVERAGE_BEARING`, so an artifact covered only by an extension pair
   is a false gap (F6).** FR-4a lets a project add validated pairs; `COVERAGE_BEARING` is a compile-time
   constant, so those pairs can never count as coverage, and the failure is in the *false-gap* direction
   that D3 calls worse than a missed one. This SPEC **measures** it (AC-G5) rather than describing it, and
   does not fix it, because the fix is a decision above this feature: whether the extension file may
   declare coverage-bearing membership. If yes, it needs a carrier in the extension format and GV04's
   equality becomes an equality over a **merged** set. **Owner: the work owner** to decide, **with
   feature-003** (the extension file's format and loader) — **gated A+; scheduling reopens and re-gates
   that SPEC** — **and feature-007** (GV04 over a merged set; ungated).
7. **Zero-row `image` and `web-page` nodes have no carrier into the view, and `kb_gaps` must not become
   one** *(inbound: feature-007 Open Item 3)*. feature-007 records that because `kb_gaps` is scoped to
   `Kind = source-artifact`, an enumerated media node with no relationship row cannot be drawn, and the
   coverage-note counts are the only place a reader learns it exists. This feature's position: **not
   adopted into `kb_gaps`**. FR-20 states an undocumented image is not a Knowledge Base gap, and every
   `kb_gaps` consumer derives severity from a `qualifier` that a media node structurally cannot carry
   (D4) — so putting media ids in that list would reintroduce the prefix-keyed defect through the
   frontmatter instead of through the predicate. If the owner wants them drawable it needs a **separate**
   frontmatter key with its own shape and no severity. **Ownership is adopted from feature-004's
   composition of all three owner records** — STATE.md Q22, feature-007's Open Item 3, and this item (its
   SPEC.md:2315–2325): **the work owner** decides whether zero-row media nodes are carried at all;
   **feature-003** owns the second reserved frontmatter key — **gated A+; scheduling reopens and re-gates
   that SPEC**; this feature is the **writer**; feature-007 the consumer; feature-010 assembles; and
   **feature-004 is the source**, which "needs no change here and makes none" because `media-nodes.tsv`
   already exists — so it is **not** among the SPECs a scheduling decision reopens. *(Corrected
   2026-07-30: this item claimed a reopen of **both** owners. feature-004 had already refuted its half —
   "on the composition above this SPEC is not one of them, since its contribution is existing content"
   (:2325) — and this SPEC's own Discharged list says the same, so the document asserted both. Same
   false-reopen class as the former Open Item 2, one item over.)*
8. **FR-26's and AC-14's "the offending `int:` node" is the last unannotated member of the `int:`-for-kind
   family.** Read here as the id **form** of the class FR-20 defines (D5), which is correct — but the words
   alone would also be satisfied by an in-repo `image` id, so they are satisfiable-while-wrong in the same
   way FR-20, AC-15 and FR-13 were before they were re-keyed. This is **not** a defect, because FR-20 and
   AC-15 scope the class; what is missing is the one-clause annotation FR-19 received under Q21, which
   would close the family and stop a future reader re-deriving the scope from the wrong clause. Raised
   because Q19's lesson is to sweep in **both** directions — not only for real proxies, but for clauses
   that read like one and are not. **Owner: the work owner** (requirements wording). **The target is
   REQUIREMENTS.md, gated A+, so this is a pending reopen and not a note** — that A+ has been reopened
   **four** times already, the fourth on 2026-07-30 for FR-4's one-line count (STATE.md:195). **Q26 class:
   editorial** (a prose annotation; it changes nothing an implementer builds, which is the test that
   classified FR-4 the other way), so it **belongs on the § Editorial queue** and is fixed in the Q24 item 9
   batched pass rather than chased from here. The reopen is therefore **batched, not avoided**: that pass
   edits REQUIREMENTS.md and carries one confirmatory gate over what it touches, so scheduling this item
   schedules a **fifth** re-gate of the document every other artifact here is graded against.
9. **A `[MEDIUM]` cluster in a thinly-covered subtree is a true finding, and the phrasing is the only
   thing open** *(inbound: feature-004 Open Item 10, discharged)*. feature-004 asks this feature to
   consider how it reports the cluster `site/src/**` will produce. Discharged in the routing block: no
   aggregation, no suppression, plus one deterministic cluster line (§ Routing hand-off, GL19). What
   remains is not this feature's: whether the **Knowledge Base should cover** `site/src/**` at the grain
   the ledger will ask for, or whether a coarser `sources:` entry should cover it instead — which under
   feature-005 D4's glob expansion clears each matching file through condition 1's **first** arm, a
   per-file `documents` edge, and not through F2's ancestor matching (F2, whose second arm is unreachable
   on today's streams). **Owner: the work owner**, with **feature-013** if the answer is a Knowledge Base
   authoring change.

**Discharged here, and recorded so they are not re-routed.** feature-001 Open Item 8 (the
`coverage_bearing` selection — D2a); feature-004 Open Item 1's consumer half (the `int:`-to-
`source-artifact` re-key in this feature's prose, plus the input assertion that makes it a check — D1a,
D2, GL14); feature-004 Open Item 2 (the field-3 rename and field-7 append — D1a's field map makes both
free, and this feature never reads field 3); feature-004 Open Item 10 (the gap-cluster phrasing — Open
Item 9 above and the routing block); feature-005 Open Item 9 (avoid `documentation` — D2a, reached from a
criterion and going further, at pair rather than category granularity); feature-007 Open Item 5 (`name` in
every `kb_gaps` entry — D6, already carried); feature-007 **Open Item 6** in both halves (the Node-side
boundary — the detector `import`s `coverage-predicate.mjs` and restates no predicate logic, D2 and D6; and
the candidate-set prose — re-keyed to `Kind = source-artifact` and made a checked input assertion rather
than a description, D1a and GL14).

**And feature-004 Open Item 14, in all four of its parts — which is also what closes this SPEC's own
former Open Item 2** *(2026-07-30)*. **(i)** The standing obligation that D4 stay monotone in
`P1 > P2 > P3` and constant on `P1` is recorded **in D4**, as an obligation this feature owns rather than an
assumption it makes. **(ii)** The phrasing call on a `[HIGH]` row for an undocumented test suite is made in
D6: `[HIGH]` is **intended**, the offered `artifact_class` = `test-suite` discriminator is declined with
reasons, and the worked example is corrected to match the rule it was contradicting. **(iii)** D4's stale
quotation of feature-004 D1 is replaced with the precedence rule as gated (its SPEC.md:405–411). **(iv)**
This feature's **Open Item 2** — "feature-004 does not state which `qualifier` value each carrier assigns" —
is **closed as discharged in full** and no longer appears above: D3a's four assigning rules and its
carrier → value map total over D3 (:1019–1050) answer its part (a); the monotonicity section (:1265–1301)
answers its part (b) with *yes, by construction*; and every one of the four values now has an assigning
rule, so no part of this feature's severity domain is unreachable and D4's closing sentence has an answer to
point at. feature-004 states from its side that this "does not reopen feature-006 — which feature-006 itself
pre-declared" (:2326–2374), and that pre-declaration was accurate: the interim this SPEC wrote — the
detector maps whatever the record carries, invents nothing, and exits 2 on an out-of-enum value — needed no
change when the mapping landed. **No reopen of feature-004 is scheduled or needed**, and the item's earlier
"gated A+; scheduling this reopens and re-gates that SPEC" consequence is **withdrawn with the item**,
because the work it asked for is already delivered and gated. Recorded at this length because the wrong
version of this entry would send a reviewer to reopen and re-gate an A+ SPEC for work already delivered —
which is exactly what the previous revision's text did.

**Declined, with reasons, so it is not re-routed as an open question.** feature-005 Open Item 7's second
half asks whether a false-merge candidate should "additionally appear as a `[LOW]` finding rather than only
as a lens signal". **No ledger row.** Four independent reasons: (a) FR-26 requires the offending node as
evidence and FR-20 keys the class on `Kind = source-artifact` — a candidate is a (concept, document) pair
and neither endpoint is a source artifact; (b) there is no `qualifier`, so `[LOW]` would be an invented
severity, which is the same objection that keeps images and unbacked documents out (D4, D6a); (c) Q18
ruling 2's constraint on that mechanism is that it "surface *candidates* advisorily rather than assert a
defect it cannot prove", and a ledger row is an assertion a reviewer is expected to act on; (d)
feature-005's own **AC-S7** asserts that a run with candidates "writes **no** gap-ledger row", so a row
here would break a gated acceptance criterion. The underlying condition — an ambiguous glossary label — is
a Knowledge Base **authoring** defect and a real §2 purpose-1 signal, which is why it belongs in the
coverage notes (feature-005 D7's `concept-merge-candidates` row) and in the view (feature-007 Open Item 9),
not in a source-artifact-keyed ledger.

**Not this feature's inbound at all, recorded because a reader may expect it to be.** Convention absences
(no glossary, no citation anchors, no headings, an empty external-sources file) do **not** arrive here.
FR-8a and AC-19 route them to **FR-9a's coverage notes**, and FR-8a states the reason in this feature's own
terms: FR-26 requires every ledger row to carry the offending node as evidence, and a missing glossary has
none, so routing absences here would either break FR-26's evidence rule or force a second, weaker row
shape. The producing features are feature-004 (its three kinds and the FR-22 exclusion rows) and
feature-005 (the four Knowledge Base kinds), assembled by feature-010. This feature writes no coverage-note
row and contributes no kind.

**Not open, and recorded so they are not reopened.** That the gap class is `Kind = source-artifact` and not
the `int:` prefix; that a node with no `qualifier` never becomes a row, in all three cases (D4); that the
lens's unbacked signal is lens-only with no ledger row and that this does not breach AC-15 (D6a); that an
unbacked `fact` is an integrity warning rather than a coverage gap; that coverage counts from rows of any
`Provenance` including `inferred` (F3) while a node's qualification never may be (F4); that the two ledgers
are separated **by file** rather than by row filtering (S1); and that the exit status never depends on the
gap count (S2).

### Proxy sweep — Q17's standing instruction, applied to this SPEC

Q17's rule: *when a model changes, sweep for clauses keyed on a **proxy** for the thing that changed — a
prefix standing in for a kind, a count standing in for a set, a path standing in for a role — because those
are the clauses that break without being edited.* Q19 adds the refinement that a count which **is** the
contract stays, and that the sweep must run in **both** directions: no real proxy left standing, and no
normative count weakened. Every instance found in this SPEC, with its resolution:

| # | Clause, as it read | Proxy | Resolution |
|---|---|---|---|
| 1 | D1: "the enumerated `int:` node set" as the candidate set | prefix → kind | Re-keyed: the enumerated **`Kind = source-artifact`** set, asserted at the input (D1a, AC-G1) |
| 2 | D2: "An enumerated `int:` node is **covered** when…" | prefix → kind | Re-keyed to `source-artifact`, and the export renamed `detectArtifactGaps` |
| 3 | D2 condition 2: "the edge's other endpoint carries the `kb:` prefix" | prefix → kind | Re-keyed to `Kind ∈ {document, concept, fact, section}`, matching feature-007 D10. Same row set today; cannot silently widen tomorrow |
| 4 | D6: "`kb:`-unbacked is lens-only" | prefix → kind | Re-keyed to `Kind ∈ {document, concept}`; `section` excluded and an unbacked `fact` routed to the integrity channel (D6a) |
| 5 | D5 `Description`: "no Knowledge Base **document** covers `<int-id>`" | one kind standing in for four | Rewritten to "no Knowledge Base **node** covers…" — the predicate accepts a covering edge from any of the four Knowledge Base kinds, so the sentence named a narrower class than the mechanism tests |
| 6 | D4: severity assigned by "the FR-21 **clause** the node qualified under" | three clauses standing in for a four-value field | Restated over feature-004's `qualifier` enum, and the unimplementable highest-severity tie-break voided (D4). **Extended 2026-07-30:** the sentence that justified the voiding quoted feature-004 D1 as "the first-matching clause in the D3 evaluation order wins" — the exact **negation** of the gated text, which says the **strongest applicable clause under D3a's precedence order** wins, "not the first clause the flow happens to test" (its SPEC.md:405–411). Corrected to the precedence rule; the conclusion is unchanged and is now better supported, since the upstream resolution is a **maximum** — which is what the withdrawn tie-break was reaching for |
| 7 | `kb_gaps`'s `clause:` key | same substitution, in the emitted data | Renamed `qualifier:`; values unchanged (D6, Open Item 4) |
| 8 | D1: "The **eight** columns of REQUIREMENTS.md §5.2" | a stale contract count | Corrected to **ten**. This is a count that **is** the contract (feature-003 D1's ten columns are normative, and changing the number is a breaking change by design), so it stays a number — Q19's exemption, applied rather than assumed |
| 9 | D5 `Evidence`: `grep -c 'int:<path>' … = 0` as the recheck | a count standing in for the predicate | Withdrawn: the count is **non-zero** for a mentions-only node, which is a gap, so the evidence contradicted its own row. Replaced by `--explain`, which runs the predicate (D5, GL16). **Extended 2026-07-30:** the replacement was itself written schematically — `--explain <int-id>` alone, omitting the `--table` and `--nodes` arguments L2's signature requires with "no baked-in default" — so a pasted cell exited 2 on a usage error, the same failure one level up. The cell now carries all three arguments, echoed from the flags the run received, and its scratch precondition is stated (D5); GL16 runs the emitted cell verbatim so an incomplete command is a test failure |
| 10 | D2: "`COVERAGE_BEARING` — the coverage-bearing subset of the **closed** vocabulary" | "closed" standing in for core-plus-extension | Corrected: FR-4 makes the vocabulary core **plus validated project extensions**, which is what surfaced F6 — the extension case the word "closed" hid |
| 11 | D5 `Doc`: "the `int:` id with its prefix stripped" | **not a proxy** | Kept, annotated. This clause is about the id's **lexical form**, not about a class — the same ruling Q21 gave FR-19's `int:`: a prefix is correct when the clause is about where an id comes from or how it is spelled, and wrong when it is about what class a node belongs to |
| 12 | L2: the file name `detect-kb-gaps.mjs`, the ledger `graph-kb-gaps.md`, the key `kb_gaps` | **not a proxy** | Kept, with the reason stated (L2): these name the **finding** — FR-20's own "reported as a KB gap" — while the export names the **set**. Renaming them would churn a frontmatter key feature-003 D8 has already reserved, for no correctness gain |
| 13 | feature-007 D6d: `kb-unbacked`'s **test** is "no incident edge to a node whose `prefix` is `int:`" | prefix → kind, **and it is real** | **Not this feature's to resolve.** The prefix spans `source-artifact` and in-repo `image`, so an image counts as backing a claim — feature-007 flags it with its domain narrowing and routes both to the work owner (its Open Item 2). Recorded here because the sweep must cross the seam, and because nothing in this feature's boundary depends on the answer (D6a) |
| 14 | D5 `Status`: "`Accepted` / `OOS` / `Invalid` are set only by the orchestrator with the user authorization the schema requires" | **one authorization rule standing in for three different ones** | Corrected against the source rather than paraphrased: the schema sets `Accepted` by "Orchestrator with user authorization", `OOS` by "Reviewer or orchestrator", and `Invalid` by "Reviewer in a subsequent cycle, or orchestrator with evidence" (`canonical/aid/templates/reviewer-ledger-schema.md`:94–96). Only one of the three needs authorization. The operative conclusion — `/aid-graph` writes none of them — never depended on the misstatement, which is exactly why it survived |
| 15 | L2: the F6 counter's relation names come from what "the same module **already exports** as `keys(RELATION_CATEGORY)`" | **an export name standing in for the file that declares it** | Withdrawn as false: feature-007 declares the constant in the browser-only `graph-model.js` (its SPEC.md:291, :1334, :1434) and omits it from `coverage-predicate.mjs`'s export table (:1103–1110), while D6 forbids the Node side importing the view model — so the counter had **no reachable source** and the SPEC contradicted its own coordination obligation 3. Resolved by a **move**, not an export keyword (L2, obligation 3, Open Item 4) |
| 16 | D1: `media-nodes.tsv` listed as an input "this feature reads", followed by "this feature reads those inputs" | **the feature standing in for one of its two components** | Corrected: three inputs are the **detector's**, each behind an explicit flag; `media-nodes.tsv` is the **suite's** and has no flag, which is what keeps AC-G2 checkable without giving the detector an input it must not have (D1, step 3, GL15). The old wording left an implementer no specified way to pass the file without breaching L2's no-baked-in-default rule |
| 17 | D2a: "Four pairs, drawn from three categories, **none of them a whole category**" | **a summary standing in for the enumeration beneath it** | Corrected: `evidence` holds exactly two pairs (feature-001 D5:631–633, D6:760–763) and the selection takes both, so one category *is* taken whole. The pair-granularity argument is untouched and does not rest on the summary — `documentation` and `annotation` each hold a definition that disclaims coverage, which is the whole of the case |
| 18 | D3 F2: ancestor matching justified because without it "dogfooding … would report nearly every file under those trees as a gap" | **a predicted instance standing in for a structural property** | Withdrawn as false under **both** readings of the `sources:` carrier (F2): as a glob it yields a per-file `documents` edge (feature-005 D4:827, kind 9:773), and as a literal path it resolves to `int:bin/`, which feature-004 never emits. The condition is **kept** — deleting it would make the predicate wrong for directory nodes — but now on the totality argument, with its current unreachability stated. Q19's class, in the direction that is easiest to miss: the mechanism was right and only its justification was invented |

**Rows 14–18 were found by this SPEC's A+ gate, not by the author's own sweep, and that is recorded rather
than smoothed over.** Four of the five are the same family the earlier rows are — a name, a summary, a
component or a predicted instance standing in for the thing itself — which means the sweep as first run was
aimed only at the model change that prompted it (`int:` → `Kind`) and not at the shape Q17 actually names.
The standing correction: sweep for the **shape**, not for the token that made the shape salient.

**Figures.** No measured quantity is asserted anywhere in this SPEC. Every number is one of: a contract
count (ten table columns, seven ledger columns, feature-004's seven `nodes.tsv` fields, L2's two modes and
`--explain`'s three arguments), an enumeration made on the spot and reproducible from the cited source
(four `qualifier` values and feature-004's four assigning rules for them at its SPEC.md:1019–1050; four
`COVERAGE_BEARING` members; thirteen candidate pairs; feature-001 D5's per-category pair counts —
`documentation` 2, `evidence` 2, `provenance` 3, at its SPEC.md:631–633; five excluded false-gap classes
plus one admitted; **nine** Open Items and **eighteen** proxy-sweep rows, both countable in the sections
above), or a labelled design choice (three severity bands used, two never assigned). The routing block's
`7 (3 HIGH, 2 MEDIUM, 2 LOW)` and `site/src/ (4)` are **illustrative output format**, not counts of anything
on this repository — the same posture feature-004 takes with its worked examples, and the same for the two
`kb_gaps` entries of D6, whose `severity` and `qualifier` values illustrate the D4 mapping and are derived
from the gated rule rather than observed. No node count, no bench size, **no duration**, and no "verified by
count" appears here — the one exception, a change-log clause quantifying the interval between two observed
timestamps, was **removed rather than corrected** on 2026-07-30, because a duration is none of the three
classes above whatever its value; per the standing practice of Q20 (A-5 figure), the claim to check is the
derivation, not the arithmetic. **Two counts this revision was careful *not* to weaken** (Q19's second
direction): the ten columns and the seven ledger columns stay numbers because each **is** the contract, and
feature-004's seven `nodes.tsv` fields likewise.
