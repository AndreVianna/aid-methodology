# Plan -- Review Subsystem Redesign

> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28
> **Deliveries:** 27 -- 18 re-cut from the 26 the eight feature SPECs recommend, plus five added
> 2026-08-09 (019-023) and four added 2026-08-10 (024-027), each set carrying decisions taken after
> the plan was graded

---

## The AGENT.md spine -- a named invariant

Six of the eight features claim regions in `canonical/agents/aid-reviewer/AGENT.md` **line by
line**, and the no-region-touched-twice property depends on them landing in order. That order is
this work's central sequencing constraint and is named here so Detail and Execute can cite it:

```
the spine:  003 -> 004 -> 005 -> 006 -> 007 -> 009 -> 011
```

Delivery **010** inserts the two `{{include:}}` tokens and is the only other writer of that file.

Three obligations follow, and each spine delivery carries them as gate criteria:

1. **Regions are restated as quoted strings, not line numbers.** Every SPEC's affected-artifact
   inventory is valid only against the pre-003 base and goes stale the moment 003 lands.
2. **A diff assertion at each spine gate:** the delivery's `git diff` on that file touches only its
   declared regions, and no line is changed twice -- **except the two declared collateral cases**
   (feature-002's 96-99, deleted by feature-003; feature-003's line-79 clause, deleted by
   feature-005).
3. **No new script.** The assertion is a diff check, not tooling.

**Standalone-functional vs enabling.** The methodology's "every delivery is an MVP" rule holds for
**22 of 27**. Five ship no user-visible capability on their own and are labelled **enabling**
rather than dressed up as MVPs: **001** (baseline and fix-first), **005** (the eighth column),
**010** (the boilerplate split, whose success criterion is an *empty diff*), **023** (the host
chaining confirmation, whose output is evidence rather than capability), and **024** (the seeded-defect
corpus, which supplies the denominator every later recall figure divides by but asserts nothing about
reviewer behaviour on its own).

---

## Deliverables

`Track` -- **spine** = on the AGENT.md serial chain; **free** = escapes it.

### delivery-001: Baseline and fix-first
- **What it delivers:** the AC-11 and AC-13 measurement baselines, captured before any edit; the
  `aid-reviewer/AGENT.md` working tree reconciled to the committed base; the stale emission
  manifests corrected.
- **Features:** feature-006 (D0), plus three Q3 prerequisites
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** enabling

### delivery-002: Citation lint
- **What it delivers:** a working citation checker over work artifacts -- the en-dash tokenizer
  fix, `--profile resolvable`, `--depth`, the resolver with its `find` fallback, range and
  resolution checks, and the fix commit on all eight SPECs.
- **Features:** feature-008 (D1)
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** standalone

### delivery-003: Severity single source
- **What it delivers:** one canonical severity scale; "established best practice" removed as a
  criterion source. AC-1, AC-2.
- **Features:** feature-001 (D1)
- **Depends on:** delivery-001
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-004: Rubric catalog
- **What it delivers:** the rubric catalog skeleton, the per-class rule sets, and the
  content-isolation relocation -- severity becomes a lookup rather than a judgment.
- **Features:** feature-002 (D1 + D2)
- **Depends on:** delivery-003
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-005: The eighth column
- **What it delivers:** the `Rule` column added to the ledger schema and migrated tree-wide, with
  five-profile render parity. AC-3's carrier.
- **Features:** feature-002 (D3)
- **Depends on:** delivery-004
- **Priority:** Must
- **Track:** spine
- **Kind:** enabling

### delivery-006: Ledger substrate
- **What it delivers:** `writeback-ledger.sh` and the schema and documentation migration --
  surgical row writes replace whole-file rewrites. AC-9.
- **Features:** feature-003 (D1 + D2)
- **Depends on:** delivery-005
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-007: Criteria-gap interrupt
- **What it delivers:** `check-gaps.sh`, `gap-register.sh`, the durable gap register, and the
  semantic edits that make "no rule to judge this by" an actionable outcome. AC-4, AC-5, AC-10.
- **Features:** feature-004 (D1 + D2)
- **Depends on:** delivery-006
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-008: Gap gate wiring
- **What it delivers:** no grade is computed while a criteria gap is open, enforced at all 18
  grade sites.
- **Features:** feature-004 (D3)
- **Depends on:** delivery-007
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-009: Review resume
- **What it delivers:** `plan-resume.sh`, the ledger lifecycle rewrite, the FR-D5 migration moving
  status reconciliation to the orchestrator, and the non-task review stop signal. AC-6, AC-7, AC-8.
- **Features:** feature-005 (D1-D4)
- **Depends on:** delivery-007
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-010: Boilerplate split and aid-screener
- **What it delivers:** `agent-discipline-boilerplate.md`, the nine include-token insertions, the
  new `aid-screener` agent, and the roster growth 9 -> 10 across 21 count assertions.
- **Features:** feature-006 (D1)
- **Depends on:** delivery-001
- **Priority:** Must
- **Track:** free
- **Kind:** enabling

### delivery-011: aid-reviewer rewrite
- **What it delivers:** the FR-A10 agent-body rewrite, the README corrections, and the nine-item
  verify-do-not-redo conformance check.
- **Features:** feature-006 (D4)
- **Depends on:** delivery-009, delivery-010
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-012: Review extraction
- **What it delivers:** `aid-light-review` and `aid-deep-review`, the shared brief template, the
  six shrunken briefs, and nine caller migrations. AC-11 (provisional), AC-12.
- **Features:** feature-006 (D2 + D3)
- **Depends on:** delivery-009, delivery-010
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-013: Modality enforcement
- **What it delivers:** `lint-modality.sh`, the four template updates, the four skill wiring sites,
  and the retroactive back-fill.
- **Features:** feature-001 (D2)
- **Depends on:** delivery-003
- **Priority:** Must
- **Track:** free
- **Kind:** standalone

### delivery-014: Settings and frontmatter gates
- **What it delivers:** `lint-settings.sh` gating the settings file; `lint-frontmatter.sh` wired as
  a runtime gate with the M2 hand-check subtraction. Re-certifies AC-11.
- **Features:** feature-007 (D1 + D2)
- **Depends on:** delivery-004, delivery-012
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-015: One grading backend
- **What it delivers:** the weighted-points model retired; `grade.sh` becomes the sole producer of
  a letter grade. NFR-7.
- **Features:** feature-007 (D4)
- **Depends on:** delivery-004, delivery-008
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-016: kb.html content pass
- **What it delivers:** an adversarial content review of the generated summary, alongside its
  existing machine validators and human checklist.
- **Features:** feature-007 (D5)
- **Depends on:** delivery-004, delivery-012, delivery-015
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-017: Quote check and citation wiring
- **What it delivers:** the attributed-quote check, the `aid-deep-review` RESOLVE gate, the CI step,
  and the `quality-gates.md` gate rows. AC-14.
- **Features:** feature-008 (D2)
- **Depends on:** delivery-002, delivery-004, delivery-012
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-018: BLUEPRINT and specify-section reviews
- **What it delivers:** `BLUEPRINT.md` graded rather than merely read; the per-section specify
  review gains a ledger and a `grade.sh` call.
- **Features:** feature-007 (D3)
- **Depends on:** delivery-012
- **Priority:** Should
- **Track:** spine
- **Kind:** standalone
- **Note:** the work's only `Should`. It was numbered last of the original 18, but the five
  deliveries added 2026-08-09 are all `Must` and are numbered after it, and `delivery-022` (a
  `Must`) depends on it -- so it is neither last by number nor preceded by every `Must`. See
  `§ Sequencing decisions`, *Priority ordering*, for what replaces that property.

### delivery-019: Criteria and catalog additions
- **What it delivers:** three checks a reviewer is told to perform become reportable findings, and
  one becomes reportable for the first time. Authors the temp-file/trap convention in
  `coding-standards.md § Shell (Bash) Conventions` and adds `EXE-14` citing it; adds the two
  kb-anatomy rules whose criteria already exist; authors item 11 in
  `kb-authoring/review-rubric.md § Rubric: Full Primary` and adds its rule.
- **Features:** feature-002 (catalog extension)
- **Depends on:** delivery-004
- **Priority:** Must
- **Track:** free
- **Kind:** standalone
- **Note:** under the No-Criterion-no-row contract these checks are currently **unwritable** — a
  reviewer that finds one can only re-register the same criteria gap, cycle after cycle. Two of the
  three need no KB edit; the temp-file rule and item 11 each author a criterion first, then cite it.

### delivery-020: Ledger sighting log
- **What it delivers:** a durable ledger row keeps a short list of one-line problem statements, one
  per sighting, instead of only a status and a count — so a new defect at an already-visited
  `(Doc, Rule)` key is distinguishable from the same defect returning.
- **Features:** feature-003 (amendment)
- **Depends on:** delivery-009
- **Priority:** Must
- **Track:** free
- **Kind:** standalone
- **Note:** the FIX circuit breaker is declared as non-improvement — *"each cycle closing more than
  it opens"* — and today nothing can compute it: the durable row freezes its description at first
  sighting, and `§ DONE` deletes the scratch files that hold the per-cycle text. Measured on this
  work's own `/aid-detail` review. The derivation matters, because a naive row count double-counts:
  the durable ledger **copies** the first sighting's description, so it overlaps the scratch
  ledgers. The seven ledgers hold **22 rows** -- 12 durable plus 10 across `cycle2..cycle7` -- of
  which **5 durable rows repeat a scratch row's description verbatim**, so the honest total is
  **17 sightings** over **12 distinct `(Doc, Rule)` keys**. Comparing scratch against scratch gives
  **0 identical descriptions**: 4 keys were seen more than once and every repeat was textually
  different -- the 5 extra sightings over those 4 keys are exactly what takes 12 keys to 17 -- and
  all 5 apparent repeats are the durable row's frozen copy of a scratch row.
  **That double-count is the defect itself** -- an analyst reading the ledger cannot tell a
  returning defect from a new one at the same key.

### delivery-021: Greenfield split and record corrections
- **What it delivers:** the greenfield criteria-vs-evidence split that delivery-007 closed `Done`
  without delivering, plus the two work-record statements that disk contradicts.
- **Features:** feature-004 (undelivered scope)
- **Depends on:** delivery-007
- **Priority:** Must
- **Track:** free
- **Kind:** standalone
- **Note:** carries decided-but-unbuilt work rather than reopening a closed delivery — reopening
  would rewrite what that gate actually certified, and the defect worth preserving is precisely that
  a delivery's recorded scope outran what was performed.

### delivery-022: One review skill
- **What it delivers:** `aid-deep-review` and `aid-light-review` merge into a single `/aid-review`
  carrying **three named** entry paths, one per caller shape — **ad-hoc** (a human, no manifest),
  **gate** (a pipeline skill, full manifest, graded) and **screening** (cheap, ungraded) — per
  `FR-A1` as amended and `STATE.md` Q1(a). The ad-hoc case is **not** folded into the gate path:
  Q1(a) rejects that inference by name. Retires
  `aid-execute/references/reviewer-guide.md`, which was to have been deleted and never was.
- **Features:** feature-006 (consolidation)
- **Depends on:** delivery-016, delivery-017, delivery-018, delivery-019, delivery-020, delivery-021
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone
- **Note:** **deliberately after every delivery the rename would churn** -- `delivery-023` follows
  it, but 023 is written against the post-merge name and so is unaffected. It renames the skill this work is built around. Four delivery
  folders name it on disk today -- `012`, `014`, `017` and 022's own BLUEPRINT, by
  `grep -rl "aid-deep-review\|aid-light-review" deliveries/` run from this work folder. Of the six
  deliveries 022 waits on, **only `delivery-017` is authored against the retired name**, so running
  the rename earlier would force that work to be written against a name already decided for
  retirement and then re-written. (`delivery-016` says *"A deep-review dispatch"* -- the concept,
  not the skill -- so the rename does not reach it.) Neither merged skill has ever shipped: `git ls-tree --name-only
  origin/master:canonical/skills/` returns 76 names, among them `aid-review` and **neither**
  `aid-deep-review` **nor** `aid-light-review`. So this is prevention, not migration, and no adopter
  sees a retired name. The three entry paths must be **named, never inferred**: the rejection of a
  `depth` flag stands, because its objection was to *silent* selection.

### delivery-023: Host chaining confirmation
- **What it delivers:** evidence that `/aid-review` is actually reachable by a chain-call on codex,
  copilot-cli and antigravity — the three hosts where `skill_chaining` has only ever been declared.
- **Features:** feature-006 (NFR-2)
- **Depends on:** delivery-022
- **Priority:** Must
- **Track:** spine
- **Kind:** enabling — it ships no capability; it retires an assumption
- **Note:** runs **after** the merge so it confirms the shape that actually ships, not one being
  replaced. It cannot be discharged by a canonical test: `RX13`-`RX16` prove the artifacts *render*
  to all five profiles, which is a different claim from a chain *executing* on three of them. The
  `skill_chaining = true` lines for those hosts predate this work, so they restate the assumption
  rather than verify it.

### delivery-024: Seeded-defect corpus
- **What it delivers:** a fixture corpus of reviewable artifacts carrying **known, catalogued**
  defects, each seeded defect naming the rule that should catch it. FR-H1.
- **Features:** feature-009
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** enabling -- it ships no reviewer behaviour; it supplies the denominator every later
  recall figure divides by
- **Note:** first of the four added 2026-08-10 from the Plan review's own evidence
  (`STATE.md` Q27-Q30). Deliberately depends on nothing, so the corpus exists **before** the
  precision work lands and the baseline is not taken after the fact.

### delivery-025: Class sweep in FIX
- **What it delivers:** the class-sweep obligation in `aid-execute/references/state-fix.md` --
  a fix is not complete until the distinguishing phrase of the corrected claim has been grepped
  across the work and every site reported -- plus the fixture that fails without it. FR-E2,
  AC-17.
- **Features:** feature-009
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** standalone
- **Note:** it gives `F1` an oracle instead of an instruction, so it needs no new rule set and
  nothing upstream. Independent of delivery-024 despite sharing a feature: this one changes how
  fixing works, that one measures how finding works.

### delivery-026: Per-claim coverage
- **What it delivers:** the coverage unit becomes the **claim**. The brief carries an enumerated
  worklist for its scope, a `U-` row cites the worklist item it discharges, and RECONCILE's
  `Pending` -> `Fixed` transition rests on every worklist item covering that `Doc` being
  examined. FR-D10, AC-15.
- **Features:** feature-005 (coverage rows), amending `reviewer-ledger-schema.md` and
  `reviewer-brief-template.md`
- **Depends on:** delivery-009
- **Priority:** Must
- **Track:** free
- **Kind:** standalone
- **Note:** it must land **after** delivery-009, which writes the ledger lifecycle and moves
  reconciliation to the orchestrator -- this changes the join that migration installs, so doing
  it first would mean writing the join twice.

### delivery-027: Recall measurement
- **What it delivers:** the measured fraction of seeded defects a review pass finds, reported
  **per rule set** as well as overall, and a recorded baseline against which a later drop is a
  defect. FR-H2, FR-H3, AC-16.
- **Features:** feature-009
- **Depends on:** delivery-022, delivery-024, delivery-026
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone
- **Note:** last because it measures the shipped shape. It needs delivery-024's corpus to have
  something to count, delivery-022's merged skill so the figure describes the review that
  actually ships, and delivery-026 because a file-granular coverage row makes a recall figure
  unattributable -- you would know a defect was missed but not which pass should have caught it.

---

## Dependency graph

Edges as an adjacency list, which is unambiguous where ASCII art is not:

| Delivery | Depends on | Blocks |
|---|---|---|
| 001 | -- | 003, 010 |
| 002 | -- | 017 |
| 003 | 001 | 004, 013 |
| 004 | 003 | 005, 014, 015, 016, 017, 019 |
| 005 | 004 | 006 |
| 006 | 005 | 007 |
| 007 | 006 | 008, 009, 021 |
| 008 | 007 | 015 |
| 009 | 007 | 011, 012, 020, 026 |
| 010 | 001 | 011, 012 |
| 011 | 009, 010 | -- |
| 012 | 009, 010 | 014, 016, 017, 018 |
| 013 | 003 | -- |
| 014 | 004, 012 | -- |
| 015 | 004, 008 | 016 |
| 016 | 004, 012, 015 | 022 |
| 017 | 002, 004, 012 | 022 |
| 018 | 012 | 022 |
| 019 | 004 | 022 |
| 020 | 009 | 022 |
| 021 | 007 | 022 |
| 022 | 016, 017, 018, 019, 020, 021 | 023, 027 |
| 023 | 022 | -- |
| 024 | -- | 027 |
| 025 | -- | -- |
| 026 | 009 | 027 |
| 027 | 022, 024, 026 | -- |

Every edge runs from a lower number to a higher one, so the ordering is a valid topological sort.
**No cycles.**

**Free tracks -- work available while the spine is blocked:** delivery-002 (fully independent),
delivery-001 (nothing upstream), delivery-010 (needs 001 only), delivery-013 (needs 003 only),
the three added 2026-08-09 -- delivery-019 (needs 004 only), delivery-020 (needs 009 only),
delivery-021 (needs 007 only) -- and three of the four added 2026-08-10: delivery-024 and
delivery-025 (nothing upstream) and delivery-026 (needs 009 only). **This paragraph and the
table above are where the free/spine split is stated; nothing else restates it.** That is
**10 free** and **17 on the spine** across the 27 deliveries. No grouping breaks the spine,
because the spine is a property of one file rather than of the grouping. Only delivery-027 of
the four is on the spine, and by design -- it measures the shape delivery-022 ships.

**delivery-022 is the one convergence point.** It depends on six deliveries rather than the usual
one or two, and that is deliberate rather than accidental coupling. **One of the six edges is the
rename edge:** it renames the skill `delivery-017` is written against — the only one of the six
that names it — so that edge exists to stop 017's work being authored against a name already
decided for retirement and then re-authored. **The other five edges are sequencing, not coupling:**
022 performs a rename sweep over the whole work, so placing it after every delivery that still
authors text means the sweep runs once over settled artifacts instead of once per delivery as each
lands. That is the owner decision recorded in `§ Sequencing decisions`; it is a cost choice, not a
technical prerequisite, and no gate of 016-021 depends on 022 having run. Downstream it blocks the
two deliveries the table above gives it, and for the same reason in both cases: delivery-023 verifies
the shape 022 produces, and delivery-027 measures it. Neither would describe what ships if it ran
first.

---

## Sequencing decisions

| Decision | Resolution |
|---|---|
| Group by feature or across features? | **By feature.** Cross-feature merging would internally re-serialize anyway, and it would break the 1:1 delivery-to-SPEC-oracle mapping -- the only mechanical verification this work has. Merged *within* features where a sub-delivery ships nothing alone: 26 -> 18. Five more were added 2026-08-09 (019-023), taking the plan to 23; they carry decisions, not a re-cut. |
| Where does the citation lint go? | **Second, ahead of the severity work.** Its own spec: *"D1 depends on nothing and gates nothing."* Every finding across 33 review cycles was a citation or count defect, so catching them mechanically beats paying a review cycle each time. Its fix commit on the eight SPECs is the input every downstream DETAIL reads. |
| AC-11's provisional status | delivery-012 earns AC-11 **provisionally**; **delivery-014 re-certifies it**, per feature-007's amendment to feature-006. 014 cannot move earlier -- its M2 subtraction sits in a file 012 migrates -- so the re-measure is accepted. |
| Priority ordering | The work has one `Should` (the BLUEPRINT and specify-section reviews, delivery-018). It was numbered last of the original 18; the five added 2026-08-09 are all `Must` and are numbered after it, so it is **no longer last by number**, and **delivery-022 (a `Must`) does depend on it**. The original property therefore no longer holds and is not claimed. What replaces it: 018 depends only on delivery-012, so it is free to run as soon as 012 closes, in parallel with the five `Must` deliveries 022 also waits on. It **can** be the last of the six to finish and so **can** be 022's binding constraint -- nothing rules that out -- but nothing in the graph *forces* it late, so the `Should` adds no critical-path length that the `Must` set does not already impose. That is the weaker claim the graph actually supports. |
| Extra parallelism | **Declined at first cut.** Splitting the settings gate out of 014 would have added another free track at the cost of another delivery gate, and the four free tracks then available (001, 002, 010, 013) were judged sufficient. Superseded in effect on 2026-08-09, and again on 2026-08-10: deliveries 019-021 and then 024-026 are each free, so the split is now the one `§ Dependency graph` states -- **cited, not restated here**, per the restatement convention in `REQUIREMENTS.md`'s conventions preamble. The decision not to split 014 stands; the scarcity that motivated it does not. |
| The WSL gitdir bug | **Leaves this work**, per concern N4. Not review-path. |
| Where does the skill merge go? (2026-08-09) | **After every delivery the rename would churn, as delivery-022.** Owner decision. `delivery-023` follows it and is unaffected, being written against the post-merge name. It renames the skill `delivery-017` is written against -- the only one of 016-021 that names it -- so running it earlier would force that delivery to be authored against `aid-deep-review`, then re-authored against `/aid-review`. Placing it there costs one thing knowingly: `delivery-017/task-002`'s Scope is the gate in `aid-deep-review` RESOLVE, so 017 builds under a name 022 then retires. That churn is bounded to a rename sweep 022 performs anyway, whereas the alternative re-details three already-graded deliveries. |
| Does `FR-G3`'s re-disposition need its own delivery? (2026-08-09) | **No — it amends delivery-017.** `Q25` makes the attributed-quote check a cheap pre-filter whose miss escalates to judgment. That is 017's own subject matter and 017 is still `Pending-Spec`, so a separate delivery would compete with it for the same files. |
| Why four deliveries for four amendments, not one? (2026-08-10) | **Because three of the four have different upstreams and one needs no delivery at all.** `Q30(a)`'s restatement convention is a convention -- it lands in `REQUIREMENTS.md`'s conventions preamble and constrains authoring, so it ships no artifact. Of the remaining three: the corpus (024) and the class sweep (025) depend on nothing and are free tracks; per-claim coverage (026) must follow delivery-009's ledger-lifecycle migration or the join gets written twice; and the measurement (027) must follow the merged skill or it measures a shape that is being replaced. Merging any pair would re-serialize inside the delivery and hide that. |
| Why does the recall corpus come early when the measurement comes last? (2026-08-10) | **Because a baseline taken after the change is not a baseline.** `REQUIREMENTS.md § 10` puts group H fifth for this reason: FR-H1 depends on nothing, so the corpus can exist before the precision work lands, while FR-H2 has to run against a built subsystem. The group straddles the order deliberately rather than by oversight. |
| Why is the host-chaining check a delivery rather than a test? (2026-08-09) | **Because no test can discharge it.** `RX13`-`RX16` prove the artifacts render identically to all five profiles; the open claim is that a chain *executes* on three of them. That needs a host runtime, so it is delivery-023 with an `enabling` kind — it ships no capability, it retires an assumption. |

---

## Open at Plan

**`feature-009`'s `SPEC.md` is authored but not yet `Ready`, and three deliveries name it.** Group H
(recall measurement) and `FR-E2` (the class sweep) were added to `REQUIREMENTS.md` on 2026-08-10, after
Specify had closed for all eight existing features, so deliveries **024**, **025** and **027** named a
feature with no spec at all.

**Resolved on 2026-08-10:** `/aid-specify` ran for `feature-009` and authored the SPEC, including the
affected-artifact inventory those three deliveries need. Its `Spec State` is `In Discussion` in
`## Features State`, and the SPEC's own review is what advances it to `Ready`.

**What remains blocked and what does not.** Nothing blocks the other 24 deliveries, and nothing blocks
this plan being graded. `/aid-detail` for **024**, **025** and **027** waits on the SPEC reaching
`Ready`, because a task breakdown reads the SPEC for its module map. Kept as a section rather than
deleted, because a delivery pointing at a SPEC that is not yet graded is exactly the kind of dangling
reference this work exists to catch.

---

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Line-number inventories go stale the moment delivery-003 lands | H | Restate regions as quoted strings at Detail; per-delivery diff gate on `AGENT.md` |
| 2 | AC-12 (five-profile parity) is only checked at delivery-012, so render drift from ten earlier deliveries arrives as one undiagnosable failure (concern N3) | H | Re-run parity as a regression gate at **every** delivery close; 012 owns the criterion of record |
| 3 | One blocked spine delivery stalls every other delivery on the spine (the count is in `§ Dependency graph`, and is not restated here) | H | Content anchors make skip-and-return survivable; 002, 010 and 013 provide work while blocked |
| 4 | The AC-13 cost baseline is unrecoverable once editing starts | M | delivery-001 is first and is a hard gate -- nothing else begins until the fixture gate-passage is recorded |
| 6 | A recall figure first taken late in the work cannot be attributed to any one delivery | M | delivery-024 lands the corpus early and free **and ships the series file**, which the closing step appends to at every delivery close from 024 onward, so a series exists before the number matters. The agent-lane term cannot start earlier than the script that computes it -- `feature-009`'s SPEC § 7 states which term joins the series when, and this row does not restate it |
| 5 | delivery-010's success criterion is an **empty diff**, so a behavioural regression could hide inside a zero-diff claim | M | Keep 010 as its own delivery, never bundled -- feature-006's own recommendation |

---

## Deferred

| Item | Reason | Revisit when |
|---|---|---|
| WSL `worktree-lifecycle.sh` gitdir bug | Not review-path (concern N4) | Re-triaged into a worktree-tooling work |
| The `OOS` authorization bypass | Deliberately deferred pending a decision | A decision is taken |
| `DOC` and `REL` artifact classes | No KB doc declares their criteria; adding them would mean authoring standards inside feature-002 | Those standards exist |
| Tier-3's `repurpose` VERIFY dispatches | Out of FR-A6's scope: they carry a dispatch but no brief template, and no ledger-grade-FIX loop | A successor work |
| FR-G4's count-claim re-runner | Executes strings from markdown -- a code-execution surface the security conventions do not address | The convention has adoption |
| Historical two-grade `kb.html` values | Re-deriving a letter for findings that were never itemised would be fabrication | Never |
