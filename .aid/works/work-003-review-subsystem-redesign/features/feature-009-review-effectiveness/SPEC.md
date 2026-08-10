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
seeded-defect shaped: `dual-intent/content/` carries `good-kb`, `shallow-kb` and `wrong-kb` variants of
the same document set, and `test-dual-intent-self-eval.sh` asserts over a good-vs-shallow pair
(`DI23`–`DI26`: the shallow KB's `data-schemas.md` must lack a `## Contracts` section, the good one must
have it).

That is exactly this feature's mechanism, hand-built for one rule. `FR-H1` generalises it:

| | `dual-intent` today | This feature |
|---|---|---|
| Seeded defects | one, implicit in a folder name | catalogued, one row each |
| Rules covered | one presence check | every rule set the rubric index routes |
| What is asserted | that the fixture differs | that the **check reacts** |
| Recall reported | not reported | per rule set and overall |

**Consequence for the design:** the corpus lives at `tests/canonical/fixtures/recall-corpus/`, under
the existing convention, and does not introduce a new fixture location. The catalogue lives beside the
other machine-readable baselines at `tests/recall-catalogue.tsv`, matching
`tests/coverage-baseline.tsv`'s existing shape and placement.

### 2. Data model — the defect catalogue

The catalogue is the deliverable of record (`delivery-024`), because a fixture with an uncatalogued
defect makes recall look worse than it is and gives no way to tell a miss from a mis-seed.

**Format: TSV, one row per seeded defect.** Tab-separated so `join`, `comm` and `cut` work on it
directly — the same reason `coverage-baseline.tsv` is a TSV, and the same reason the coverage-parity
gate compares with `comm` rather than by counting.

| Column | Content | Notes |
|---|---|---|
| `defect_id` | `RC-NNN` | Stable across runs. Never renumbered — a renumber breaks every recorded baseline |
| `fixture` | path under `tests/canonical/fixtures/recall-corpus/` | Must resolve; asserted (§ 6) |
| `rule_set` | one of the rubric index's routed sets | `KB`, `REQ`, `SPEC`, `PLAN`, `TASK`, `CODE`, `TEST`, `DATA`, `AID`, `SUMMARY`, `SETTINGS`, `STATE` — twelve, read from `review-rubrics/INDEX.md` rather than hardcoded here |
| `rule_id` | the specific rule expected to catch it | e.g. `DEF-04` |
| `enforcement` | `script` \| `judgment` | **This column is what routes the row to a lane.** A row is `script` only when a named script can decide it |
| `oracle` | the script for a `script` row, `--` for `judgment` | e.g. `lint-modality.sh` |
| `locator` | a content anchor in the fixture | An anchor, not a line number, so re-seeding does not invalidate it — the durable-anchor standard `FR-G1` already applies |
| `summary` | one line, plain text | Machine-read, so plain text with no glyphs |

**Seeded per rule, not per artifact.** A rule with no row is visible as an absent `rule_id` when the
catalogue is joined against the rubric index — which is precisely what `AC-16` fails on. Seeding per
artifact would let a rule be silently uncovered inside a fixture that looks populated.

**One defect per fixture region.** Two seeded defects that a single finding could plausibly discharge
would make a miss unattributable, which defeats the figure's purpose.

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
3. join reported (Doc, Rule) against the catalogue
4. report: found / seeded, per rule_set and overall
5. write the figure to the baseline
```

Step 3's join key is `(Doc, Rule)` — the same key `reviewer-ledger-schema.md § RECONCILE` already uses,
and for the same reason: a row ID is per-dispatch and would double-count a defect two mandates both
found.

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
| `canonical/aid/scripts/review/recall-measure.sh` | Lane B: join a ledger against the catalogue, report per rule set | 027 |
| `tests/recall-baseline.tsv` | the recorded Lane B figures | 027 |

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
surfaced eleven derived figures restated across up to four artifacts each, while the convention
forbidding exactly that was being adopted.

### 6. Verification strategy — proving the corpus is not lying

A corpus that cannot fail is worth nothing, so three checks come with it, all in
`test-recall-corpus.sh` and all in Lane A:

| # | Check | What it catches |
|---|---|---|
| 1 | **Every catalogue row resolves.** `fixture` exists; `locator` is found inside it | A defect that was re-seeded or removed while its row stayed, which would report as a permanent miss |
| 2 | **Every routed rule set has at least one row.** Joined against `review-rubrics/INDEX.md` | `AC-16`'s failure condition: a rule set reporting nothing and reading as clean |
| 3 | **Mutation of the mutation.** For each `script` row, temporarily repair the seeded defect in a scratch copy and assert Lane A's assertion for that row **flips to failing** | A fixture whose oracle passes for a reason unrelated to the seeded defect — the vacuous-assertion class `delivery-022` found in `test-review-extraction.sh`, where a minority of the reads fail loudly and the rest pass on nothing (the counts are in that delivery's `BLUEPRINT.md § Scope`) |

Check 3 is the one that matters, and it is the same technique tech-debt `L4` reports working: mutation
caught three canonical suites that were green against a broken subject, in each case because the broken
and the correct reading agreed on ordinary data. Reviewing the suite would not have found those.

**Run one at a time.** Check 3 must confirm *that row's* assertion flips, not that the suite goes red
overall — a suite-level red is satisfied by any one row failing, which is the same defect
`delivery-022`'s gate criteria call out for its four silent assertions.

### 7. Wiring and cost

**Lane A** is an ordinary canonical suite: `tests/canonical/test-recall-corpus.sh`, picked up by
`tests/run-all.sh`, and carrying a `# COVERS:` header so change-set selection reaches it. Cost is a
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

Already reflected in `PLAN.md`, which this spec follows rather than re-decides:

| Delivery | Carries | Track |
|---|---|---|
| `delivery-024` | `FR-H1` — the corpus and catalogue | free |
| `delivery-025` | `FR-E2`, `AC-17` — the class sweep | free |
| `delivery-027` | `FR-H2`, `FR-H3`, `AC-16` — the measurement | spine |

`delivery-026` carries `FR-D10` and belongs to `feature-005`, not here.
