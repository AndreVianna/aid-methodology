---
feature: feature-009-review-effectiveness
spec_state: In Discussion
spec_grade: "Pending"
priority: Must
ticket_ref: "--"
---

# feature-009 — review effectiveness

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-10 | Feature created after Plan REVIEW tripped the circuit breaker; owns group H and `FR-E2` | /aid-plan (REVIEW), owner decisions `STATE.md` Q28 / Q29 |

## Why this feature exists

Every other feature in this work improves the handling of findings that were **already found** — one
severity source, a rule ID on every row, durable surgical writes, no finding without a criterion,
none lost to interruption, resolvable evidence. That is a **precision** programme end to end.

Nothing in it asks whether a review found what was actually **there**. `grade.sh` counts findings
found; there is no term for findings **missed**. Without a denominator, a clean pass is
unfalsifiable, and a grade measures reviewer attention rather than artifact quality.

The evidence is this work's own Plan review, measured and recorded in `STATE.md` Q27 and Q28: it
produced immaculate bookkeeping while missing each pre-existing defect several times over. Those
measurements are **cited, not restated here**, per the Restatement convention in
`REQUIREMENTS.md § 5`.

Two further points make the gap structural rather than incidental:

- **Two shipped features plausibly lower recall.** The no-criterion-no-row contract
  (`feature-004`) and severity-by-lookup (`feature-001`) both raise the cost of writing a finding
  down. Neither is wrong; both are untested against the thing they might cost.
- **A rigorous-looking clean pass is worse than a scruffy one**, because it invites belief. This
  feature exists so that "the review is thorough" becomes a number instead of a mandate.

## Description

Measure whether a review finds what is there, and make a fix account for its whole class. The feature
adds two things AID has never had: a **corpus of artifacts carrying known, catalogued defects**, and a
**reported fraction** of those defects that a review pass actually finds. It also makes the existing
`F1` rule -- a finding is a class -- mechanical rather than advisory, by requiring a fix to sweep for
the corrected claim's siblings before it is complete.

It changes nothing about how a finding is severity-tagged, ruled, stored or graded. It adds a
denominator to a system that currently reports only a numerator.

## User Stories

- **As the owner of this repository**, I want a number for how much a review misses, so that a clean
  pass is evidence rather than an impression.
- **As a reviewer agent**, I want the rule set I am graded against to have at least one worked example
  of each defect it names, so that an ambiguous rule is visible as a rule problem rather than as my
  miss.
- **As a contributor changing a review rule or a linter**, I want CI to tell me immediately when my
  change stops a check from catching the defect it exists to catch.
- **As a fixer closing a finding**, I want the sweep for that claim's other sites to be part of
  finishing the fix, so that a sibling is found now rather than in the next review cycle.

## Priority

**Must.**

`REQUIREMENTS.md § 10` places group H fifth in the requirement-group order, which is a **sequencing**
position rather than a priority: the corpus depends on nothing and is built early, while the
measurement must run against a built subsystem. Every requirement this feature owns is `MUST` except
`FR-H3`, which is `SHOULD` because a baseline must exist before a regression is meaningful.

## Source

| Requirement | Modality | Owned here |
|---|---|---|
| `FR-H1` | MUST | A fixture corpus with seeded, catalogued defects exists |
| `FR-H2` | MUST | Recall is measured and reported — the fraction of seeded defects a review pass finds, per rule set as well as overall |
| `FR-H3` | SHOULD | A recall regression is a defect in the review subsystem |
| `FR-E2` | MUST | A fix is not complete until its class has been swept |

Full requirement text, rationale and modality live in `REQUIREMENTS.md § 5` (group H and group E).
This spec does not restate them.

**Relationship to tech-debt `L4`.** `L4` asks whether AID's ~144 canonical **test suites** bite,
and its named techniques are mutation testing, invariant-anchoring, behavioural-surface coverage
and escaped-defect tracking. This feature asks whether a **review** finds what is there. The
technique is the same shape — seed a known defect, see whether the thing under test reacts — but
the subject differs, so this feature **discharges the review-path slice of `L4` and leaves the
rest open**. Where a rule set in the corpus is enforced by a *script* rather than an agent
(`lint-modality.sh`, `kb-citation-lint.sh`), the overlap is direct and the same fixture serves
both readings; where it is enforced by reviewer judgment, only this feature reaches it.

`L4` must not be closed on this feature shipping. Q28 recorded it as superseded; that was too
strong and is corrected here and in `REQUIREMENTS.md § 5`.

## Acceptance Criteria

| ID | Modality | Criterion |
|---|---|---|
| `AC-16` | MUST | Measured recall is reported for every rule set, and no rule set reports zero fixtures |
| `AC-17` | MUST | A fix reports its class sweep |

Stated in full in `REQUIREMENTS.md § 9`.

## Scope

**In scope**

1. A fixture corpus of reviewable artifacts carrying known, catalogued defects, seeded **per rule**.
2. The defect catalogue pairing each seeded defect with the rule ID expected to catch it.
3. The measurement: run a review over the corpus, report the found fraction per rule set and overall.
4. The recorded baseline, and the rule that a later drop is a defect to be justified or reverted.
5. The class-sweep obligation in `aid-execute/references/state-fix.md`, plus its own fixture.

**Out of scope**

1. **Gating on the recall figure.** `FR-H2` is explicit that this is a measurement. Turning recall
   into a pass/fail bar would need a second grading arithmetic, which `FR-F6` forbids.
2. **Automating the repair** of siblings a class sweep finds. The obligation is to make them visible.
3. **Generating a coverage worklist automatically** for an arbitrary artifact class — that belongs to
   `FR-D10` and `feature-005`, not here.
4. **Changing what `grade.sh` counts.** `NFR-1` and `AC-9` are unaffected.

## The tension this feature must resolve

A recall figure is only useful if a miss is **attributable** — you need to know not just that a
defect was missed, but which pass should have caught it. That attribution depends on `FR-D10`
(`feature-005`), which makes a coverage row's unit the claim rather than the file. So this feature
has a hard dependency on another feature's requirement, and the plan sequences it accordingly:
`delivery-027` depends on `delivery-026`.

The opposite tension pulls the corpus early: a baseline taken after the change is not a baseline.
`REQUIREMENTS.md § 10` therefore places group H fifth and says the group straddles the order
deliberately — `FR-H1` depends on nothing and is built first (`delivery-024`), while `FR-H2` must run
against a built subsystem (`delivery-027`).

## Technical Specification

**Owner decision, 2026-08-10 (`STATE.md` Q31): the measurement is split in two lanes.** Script-enforced
rules are measured in CI, automatically, on every run. Agent-judged rules are measured on demand. The
reason is not preference: measuring whether a *reviewer agent* finds a seeded defect requires a live
model call, which a CI runner cannot make, and wiring one in would make a deterministic gate depend on
a non-deterministic agent. Everything below follows from that split.

### 1. Prior art this builds on, rather than inventing

`tests/canonical/fixtures/` already holds nine committed fixture families, and one of them is already
seeded-defect shaped: `dual-intent/` carries `good-kb` and `shallow-kb` variants of the same document
set in each of three domains (`content/`, `data-ml/`, `design/`), and
`test-dual-intent-self-eval.sh` asserts a presence/absence pair per domain — `DI33`/`DI34` over
`content/`'s `content-model.md`, `DI23`/`DI24` over `data-ml/`'s `data-schemas.md`, and
`DI25`/`DI26` over `design/`'s `design-tokens.md`. In each pair the good variant must carry a
`## Contracts` section and the shallow one must lack it.

That is exactly this feature's mechanism, hand-built for one check and repeated three times by hand.
`FR-H1` generalises it:

| | `dual-intent` today | This feature |
|---|---|---|
| Seeded defects | one, implicit in a folder name | catalogued, one row each |
| Rules covered | one presence check | every **kind-A** rule set (§ 2b defines the domain; this row does not restate it) |
| What is asserted | that the fixture differs | that the **check reacts** |
| Recall reported | not reported | per rule set and overall |

**Consequence for the design:** the corpus lives at `tests/canonical/fixtures/recall-corpus/`, under
the existing convention, and does not introduce a new fixture location. The catalogue lives beside the
other machine-readable baselines at `tests/recall-catalogue.tsv`; § 2 states what it borrows from
`tests/coverage-baseline.tsv` and what it deliberately does not.

### 2. Data model — the defect catalogue

The catalogue is the deliverable of record (`delivery-024`), because a fixture with an uncatalogued
defect makes recall look worse than it is and gives no way to tell a miss from a mis-seed.

**Format: TSV, one row per seeded defect.** Tab-separated so `join`, `comm` and `cut` work on it
directly, matching `tests/coverage-baseline.tsv`'s existing shape and placement.

**One thing the coverage-parity gate is *not* precedent for.** That gate compares **per-key counts** —
its inventory rows are `<suite>\t<key>\t<count>` and its `diff` loads both sides into arrays keyed
`<suite>\t<key>` and tests a numeric reduction. This catalogue is a **set** of uniquely-keyed rows and
is compared by membership, not by count. The shared TSV shape is the whole of the borrowing; the
comparison method deliberately differs, and conflating them would import a count-delta reading that
this catalogue's uniqueness rule exists to avoid.

| Column | Content | Notes |
|---|---|---|
| `defect_id` | `RC-NNN` | Stable across runs. Never renumbered — a renumber breaks every recorded baseline |
| `fixture` | fixture path, **relative to the repo root** | Under `tests/canonical/fixtures/recall-corpus/`. Repo-root-relative deliberately, so it is byte-identical to the ledger's `Doc` and the Lane B join needs no path rewriting. Must resolve; asserted (§ 6) |
| `class` | the artifact class the fixture belongs to | Read from `review-rubrics/INDEX.md` at build time, **never hardcoded** — a new class must widen this column's domain with no edit here. `--` where a fixture exercises a family rule set no class routes to (§ 2b) |
| `rule_set` | **the rule-set file that governs the fixture** | A class route where the routing table gives one, the **family** file otherwise. Deliberately not defined as "the routing table's `Rule set` column": that column names only the five class files, and four kind-A family files are reachable *only* by fallback, so a column-derived domain would exclude them by construction. Distinct from `class` — four classes route to `definition.md` — and `FR-H2`'s *"per rule set"* is reported per **`rule_set`** |
| `rule_id` | the specific rule expected to catch it | e.g. `DEF-04` |
| `enforcement` | `script` \| `judgment` | **This column is what routes the row to a lane.** A row is `script` only when a named script can decide it |
| `oracle` | the script for a `script` row, `--` for `judgment` | e.g. `lint-modality.sh` |
| `locator` | a content anchor in the fixture | An anchor, not a line number, so re-seeding the fixture does not invalidate the row. `FR-G1` is **not** the authority for this — that requirement scopes the durable-anchor standard to the KB and to work artifacts, and a TSV under `tests/` is in neither set. The reason here is practical and local: a fixture is edited by every re-seed, and a line-numbered catalogue would go stale on each one |
| `summary` | one line, plain text | Machine-read, so plain text with no glyphs |

**Seeded per rule, not per artifact.** A rule with no row is visible as an absent `rule_id` when the
catalogue is joined against the rubric index — which is precisely what `AC-16` fails on. Seeding per
artifact would let a rule be silently uncovered inside a fixture that looks populated.

**One seeded defect per `(fixture, rule_id)` pair.** Not merely one per region: the pair must be
**unique**, so that a Lane B join on `(Doc, Rule)` addresses exactly one catalogue row. Without
uniqueness the join cannot tell which of two same-key rows a finding discharged —
`reviewer-ledger-schema.md`'s only tiebreaker for a legitimately repeated `(Doc, Rule)` is `Line`, and
nothing makes a reviewer's `Line` equal this catalogue's anchor-based `locator`. A fixture may still
carry several seeded defects; they must differ in `rule_id`.

### 2b. The corpus domain — one predicate, defined here and nowhere else

**Every rule set whose kind is `A` is in the corpus. Nothing else is.** This section is the single
definition of that domain; every other site in this SPEC cites it rather than restating it, and no site
enumerates the members.

**Why a predicate and not a list.** `review-rubrics/INDEX.md` states that **only kind A needs rule
rows**, and a rule set declares its own kind — each rule-set file opens with a `**Kind:**` line, and
`INDEX.md`'s per-class declarations table carries a `Kind` column per class. The **routing table does
not**: it has four columns (`Artifact selector`, `Producing skill`, `Class`, `Rule set`) and names a
kind only inside three non-A `Rule set` cells. So a list built from the routing table is wrong in both
directions, and an enumeration goes stale the moment a rule set is added.

**What the predicate admits that a routed-class list would miss:**

| Reached how | Rule sets | Why a class list misses them |
|---|---|---|
| Class route | `kb.md`, `definition.md`, `executable.md`, `summary.md`, `aid.md` | — |
| **Family fallback** | `interface.md`, `narrative.md`, `presentation.md`, `process.md` | Each declares `**Kind:** A` in its own header, and each is reachable only through classes that appear in **no** routing row. A routed-class enumeration excludes all four |
| Declared but unrouted | `DATA` (kind A in the per-class declarations table, no routing row) | A routing-table list omits it while the kind table declares it |

**What the predicate excludes, and why that is permanent rather than deferred.** § 2 requires a
`rule_id` naming the rule expected to catch each seeded defect. A kind that the index declares has
*no rule rows* — `SETTINGS` (kind D, mechanical gate), `STATE` (kind C, spot-check),
`INDEX`/`METRICS`/`PROJECT-INDEX` (kind B, build-verify) — offers no rule to name, so a catalogue row
for it cannot be authored at all, and `AC-16`'s *"no rule set reports zero fixtures"* would be
unsatisfiable for it forever. This is a property of what those kinds are: a mechanical gate either
passes or fails and needs no recall figure.

`FR-F1` already puts `.aid/settings.yml` behind a kind-D mechanical gate, so `SETTINGS` is covered by
its own gate rather than left unreviewed. That requirement is `feature-007`'s and is not duplicated
here.

### 3. Feature flow — two lanes

**Lane A — script-enforced, in CI, deterministic.**

```
for each catalogue row where enforcement = script:
    run <oracle> over <fixture>
    assert the run reports <defect_id>'s locator
```

**Lane A asserts, it does not average.** For a script rule the expected recall is exactly 1.0: if a
lint does not catch a defect seeded specifically for it, that is a bug in the lint, not a statistic.
So Lane A is a pass/fail suite like every other canonical suite — which is what keeps `FR-F6` (one
grading backend) intact. No percentage, no second arithmetic, no override channel.

**Lane B — agent-judged, on demand.**

```
1. dispatch a review over the corpus, with the normal brief and rule set
2. take the resulting ledger
3. join reported (Doc, Rule) against the catalogue rows where enforcement = judgment
4. report one line per rule_set, and then one OVERALL line, each carrying both terms:
       found / seeded(judgment)   -- a fraction
       asserted / total(script)   -- Lane A's assertion count, stated beside it
5. write every line -- the per-rule-set lines and the OVERALL line -- to the baseline
```

**The denominator, stated once so it cannot be read two ways.** Lane B's fraction is over
`enforcement = judgment` rows **only**. A `script` row is never in a Lane B denominator, because Lane A
already decides it and no agent behaviour can move it — leaving script rows in would understate agent
recall by an amount that varies with how much of the corpus happens to be script-enforced.

**How `FR-H2` and `AC-16` are satisfied**, given that no single number covers both lanes. `FR-H2`
requires the fraction *"reported **per rule set** as well as overall, because an aggregate hides a rule
that never fires."* Both terms of that requirement are produced:

- **Per rule set** — one line per `rule_set`, always carrying both lane terms, so every seeded defect
  appears in exactly one of them and every in-domain rule set is reported.
- **Overall** — one further line, aggregating the same two terms across all rule sets. It is reported
  **in addition to**, never instead of, the per-rule-set lines. `FR-H2`'s own clause states the reason
  the per-rule-set lines cannot be dropped in its favour, and this SPEC does not weaken it.

`AC-16`'s *"reported for every rule set"* is decided by each in-domain rule set having its line with
both terms; its *"no rule set reports zero fixtures"* clause is § 6 check 2.

**Why the two lane terms sit side by side rather than blended into one number**, on both the
per-rule-set lines and the OVERALL line: a blend would be the second grading arithmetic `FR-F6`
retires, and it would hide which lane a change moved.

Step 3's join key is `(Doc, Rule)` — the same key `reviewer-ledger-schema.md § Attempts and
reconciliation` already uses (*"The join key is (Doc, Rule)"*), and for the reason that document gives,
which is **availability, not double-counting**: a row ID is only stable while the scratch that minted it
still exists, and scratches are deleted at merge, so an ID-keyed join has its input removed before it is
read. That reason applies here unchanged — the catalogue outlives any single review's scratch.

**Two things must line up for that join to execute**, both settled in § 2 rather than left implicit:
the catalogue's `fixture` is written **relative to the repo root**, so it is the same string as the
ledger's `Doc` (which `reviewer-ledger-schema.md` defines as repo-root-relative); and
`(fixture, rule_id)` is unique, so the join addresses exactly one row and needs no tiebreaker.

**Attribution depends on `FR-D10`.** A miss is only useful if it names the pass that should have caught
it. That requires a coverage row whose unit is the claim, which is `feature-005`'s `FR-D10`
(`delivery-026`). This is why `delivery-027` depends on `delivery-026` and not merely on the corpus.

### 4. Layers and components — affected artifacts

**New:**

| Artifact | Purpose | Delivery |
|---|---|---|
| `tests/canonical/fixtures/recall-corpus/**` | the seeded artifacts | 024 |
| `tests/recall-catalogue.tsv` | the catalogue (§ 2) | 024 |
| `tests/canonical/test-recall-corpus.sh` | Lane A, plus the § 6 self-checks | 024 |
| `canonical/aid/scripts/review/recall-measure.sh` | Lane B: join a ledger against the catalogue, then emit the report — the per-rule-set lines and the OVERALL line, each with both lane terms | 027 |
| `tests/recall-lane-a.tsv` | **Lane A's machine-readable tally**, `rule_set \t asserted \t total`, written by `test-recall-corpus.sh` on every run | 024 |
| `tests/recall-baseline.tsv` | the recorded report: **both lanes' terms**, per rule set and overall | 027 |

**Changed:**

| Artifact | Change | Delivery |
|---|---|---|
| `canonical/skills/aid-execute/references/state-fix.md` | the class-sweep obligation (§ 5) | 025 |
| `canonical/aid/templates/review-rubrics/INDEX.md` | a pointer to the corpus, so a new rule set is told it needs a fixture | 024 |

`canonical/aid/scripts/review/` already holds `check-gaps.sh`, `gap-register.sh`, `plan-resume.sh` and
`writeback-ledger.sh`, so `recall-measure.sh` joins an existing family rather than creating one. Every
canonical change renders to five profiles, so `AC-12` parity and dogfood byte-identity apply.

### 5. `FR-E2` — the class sweep

Mechanically separate from the recall lanes, and carried by its own delivery (`025`), because it changes
how **fixing** works rather than how finding is measured.

```
before marking a fix complete:
    phrase := the distinguishing phrase of the corrected claim, taken from the ledger row
    grep the phrase across the work
    report every site
```

**The phrase comes from the ledger row being discharged, not from the fixer's choice.** Two fixers
sweeping the same finding must sweep the same thing, or the obligation is unfalsifiable.
`feature-003`'s ledger substrate already puts that row in the fixer's hands.

**`AC-17`'s fixture is a triple**: a claim corrected at one site and restated at two others. The fix is
rejected until the sweep output naming both other sites is on the record. Asserted in both directions —
with the sweep it passes, without it fails.

**This rule has already paid for itself twice**, before being written down. Sweeping the `delivery-022`
trim surfaced a `PLAN.md` claim that the delivery *"blocks only delivery-023"*, which the blueprint
edits alone would have left contradicting the dependency graph; and sweeping the amendment text
surfaced a further crop of derived figures restated across several artifacts each, while the
convention forbidding exactly that was being adopted. The measured restatement count for this work is
`STATE.md` Q30's, and is not restated here.

### 6. Verification strategy — proving the corpus is not lying

A corpus that cannot fail is worth nothing, so three checks come with it, all in
`test-recall-corpus.sh` and all in Lane A:

| # | Check | What it catches |
|---|---|---|
| 1 | **Every catalogue row resolves.** `fixture` exists; `locator` is found inside it | A defect that was re-seeded or removed while its row stayed, which would report as a permanent miss |
| 2 | **Every in-domain rule set has at least one row.** The domain is § 2b's predicate — a rule set whose own kind is `A` — read at check time from each rule-set file's `**Kind:**` line, so a rule set added tomorrow fails this check until it is seeded | `AC-16`'s failure condition: a rule set reporting nothing and reading as clean. Kinds B/C/D are outside the domain by construction, not overlooked (§ 2b) |
| 3 | **Mutation of the mutation.** For each `script` row, temporarily repair the seeded defect in a scratch copy and assert Lane A's assertion for that row **flips to failing** | A fixture whose oracle passes for a reason unrelated to the seeded defect — the vacuous-assertion class `delivery-022` found in `test-review-extraction.sh`, where a minority of the reads fail loudly and the rest pass on nothing (the counts are in that delivery's `BLUEPRINT.md § Scope`) |

Check 3 is the one that matters, and it is the same technique tech-debt `L4` reports working: mutation
caught three canonical suites that were green against a broken subject, in each case because the broken
and the correct reading agreed on ordinary data. Reviewing the suite would not have found those.

**Run one at a time.** Check 3 must confirm *that row's* assertion flips, not that the suite goes red
overall — a suite-level red is satisfied by any one row failing, which is the same defect
`delivery-022`'s gate criteria call out for the silently-failing assertions its own Scope identifies.

### 7. Wiring and cost

**Lane A** is an ordinary canonical suite: `tests/canonical/test-recall-corpus.sh`, picked up by
`tests/run-all.sh`, and carrying a `# COVERS:` header so change-set selection reaches it.

**Lane A also emits a tally, and that is a requirement rather than a convenience.** Every report line
must carry the script-lane term, and Lane B runs outside CI where Lane A's pass/fail output is not
available to it. So `test-recall-corpus.sh` writes `tests/recall-lane-a.tsv` —
`rule_set \t asserted \t total` — which `recall-measure.sh` reads. The file has a named consumer, which
is what distinguishes it from a report nothing reads; without it the script-lane term has no producer
and the two-term report cannot be assembled. Cost is a
handful of script invocations over small fixtures — the same order as the suites it sits beside. It is
**not** master-only; there is no reason to defer a deterministic check that costs seconds.

**Lane B** is invoked deliberately: `recall-measure.sh` over a ledger a review has just produced. It is
**not** in CI, needs no credentials there, and adds nothing to CI time.

**When Lane B runs, and why that is stated here.** `PLAN.md § Cross-Cutting Risks` row 6 records the
risk that a baseline taken at `delivery-027` arrives after 26 deliveries have changed the reviewer, so a
low figure is unattributable. The mitigation is to run Lane B **at every delivery close from 024
onward**, so a series exists before the number matters. That makes the on-demand lane a habit with a
named trigger rather than an intention.

**The cost claim this feature must not make.** `AC-13` measures whether the review split is cheaper.
Lane B adds dispatches, so it must not be counted inside `AC-13`'s fixture passage — it is measurement
overhead, not review cost. Stated because conflating them would corrupt a criterion another feature
owns.

### 8. What could still go wrong

Recorded rather than smoothed over, since this feature exists because a polished-looking pass was
believed:

1. **A seeded defect can be too easy.** A corpus of obvious defects reports high recall and proves
   nothing. Mitigation is honest labelling, not a mechanism: the catalogue's `summary` states what makes
   each defect findable, and a reviewer of the corpus can judge whether it is representative.
2. **Recall on fixtures is not recall on real artifacts.** A fixture is smaller and its defects are
   deliberate. The figure is a floor and a trend line, not a promise about live review — and `FR-H3`
   treats a *drop* as the signal, which is robust to the absolute number being optimistic.
3. **`judgment` rows depend on a non-deterministic reviewer**, so Lane B's figure moves between runs
   even with no change. Report the run count alongside the fraction; do not treat a single run's
   movement as a regression.


## Delivery recommendation

**`PLAN.md` owns this, and this SPEC states none of it.** Which delivery carries which requirement,
the sequencing, the free/spine split and the dependency edges are all recorded in
`PLAN.md § Deliverables` and `§ Dependency graph`. `REQUIREMENTS.md § 5` names *"a
which-delivery-carries-what assignment"* verbatim as a derived fact that is stated once in the artifact
that owns it — so the assignment table that stood here has been removed rather than trimmed, and the
reader is pointed at the owner.

Three deliveries carry this feature's requirements; `delivery-026` carries `FR-D10` and belongs to
`feature-005`. `PLAN.md` states which is which.
