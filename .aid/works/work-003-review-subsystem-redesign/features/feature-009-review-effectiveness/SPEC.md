---
feature: feature-009-review-effectiveness
priority: Must
ticket_ref: "--"
---

# feature-009 — review effectiveness

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-10 | Feature created; owns group H and `FR-E2` | owner decisions `STATE.md` Q28 / Q29 |
| 2026-08-10 | Two-lane measurement: script-decided rules asserted in CI, judgment-decided rules measured on demand | owner decision `STATE.md` Q31 |
| 2026-08-10 | Reduced under `REVIEW-DISCIPLINE.md` `D1`-`D5`: the justification layer removed, four specification defects fixed | /aid-specify FIX cycle 5 |
| 2026-08-10 | Section numbers restored after the reduction broke six cites; lost qualifiers restored | /aid-specify FIX cycle 6 |
| 2026-08-10 | The tally and the series separated; `FR-H3`'s trigger defined once; the sweep phrase made falsifiable | /aid-specify FIX cycle 7 |
| 2026-08-11 | One normative home per mechanism (§ Technical Specification), after 49 of 81 findings proved to be internal contradictions between duplicate descriptions | /aid-specify FIX cycle 8 |
| 2026-08-11 | **Mechanism reduced:** the second TSV, the invented regression threshold, the ledger-plumbing chain, the Lane A series, the `rule_set` column and the `INDEX.md` pointer all deleted. § 4 is the inventory of record; this row states no count | /aid-specify FIX cycles 7-8 |

## Description

Measure whether a review finds what is there, and make a fix account for its whole class.

This adds a denominator to a system that reports only a numerator, and makes `F1` — a finding is a
class — mechanical rather than advisory.

## User Stories

- **As the owner of this repository**, I want a number for how much a review misses, so that a clean
  pass is evidence rather than an impression.
- **As a reviewer agent**, I want each rule I am graded against to have a worked example, so an
  ambiguous rule shows up as a rule problem rather than as my miss.
- **As a contributor changing a review rule or a linter**, I want CI to tell me when my change stops a
  check catching the defect it exists to catch.
- **As a fixer closing a finding**, I want the sweep for that claim's other sites to be part of
  finishing the fix.

## Priority

**Must.** Every requirement here is `MUST` except `FR-H3`, which is `SHOULD`.

## Source

| Requirement | Modality | Owned here |
|---|---|---|
| `FR-H1` | MUST | A fixture corpus with seeded, catalogued defects exists |
| `FR-H2` | MUST | Recall is measured and reported — the fraction of seeded defects a review pass finds, per rule set as well as overall |
| `FR-H3` | SHOULD | A recall regression is a defect in the review subsystem |
| `FR-E2` | MUST | A fix is not complete until its class has been swept |

Requirement text, rationale and modality live in `REQUIREMENTS.md § 5`.

## Acceptance Criteria

| ID | Modality | Criterion |
|---|---|---|
| `AC-16` | MUST | Measured recall is reported for every rule set, and no rule set reports zero fixtures |
| `AC-17` | MUST | A fix reports its class sweep |

Stated in full in `REQUIREMENTS.md § 9`.

## Scope

**In scope**

1. The fixture corpus (§ 4), and the defect catalogue that indexes it (§ 2).
3. The two-lane measurement and its report (§ 3).
4. The accumulated series (§ 4), and `FR-H3`'s regression rule (§ 3 step 5, § 8 item 3).
5. The class-sweep obligation and its fixture (§ 5).

**Out of scope**

1. **Gating on the recall figure** — `FR-H2` makes this a measurement, and `FR-F6` forbids a second
   grading arithmetic (§ 3).
2. **Automating the repair** of siblings a sweep finds.
3. **Generating a coverage worklist** for an arbitrary artifact class — `FR-D10`, `feature-005`.
4. **Changing what `grade.sh` counts.** `NFR-1` and `AC-9` unaffected.

## Technical Specification

**One normative home per mechanism.** Each mechanism below is specified in exactly one section.
Outside it, the mechanism may be **named** but no behaviour, value, threshold or artifact name is
restated — including in `## Scope`, `## Source` and `## Acceptance Criteria`, which name and point.

| Mechanism | Normative section |
|---|---|
| the defect catalogue | § 2 |
| the corpus domain | § 2b |
| the two lanes, the report, the denominator, the join | § 3 |
| every artifact this feature adds or changes | § 4 |
| the class sweep, and `AC-17`'s fixture | § 5 |
| the verification checks | § 6 |
| where each lane runs, and what each delivery close gives | § 7 |

This is not tidiness. Eight review cycles on this artifact produced 81 findings, **49 of them internal
contradictions**, because seven of ten mechanisms were described in three or more sections and every
design change had to be swept across all of them. One home makes that class of defect impossible
rather than merely discouraged.

### 2. Data model — the defect catalogue

TSV, one row per seeded defect, at `tests/recall-catalogue.tsv`.

| Column | Content | Contract |
|---|---|---|
| `defect_id` | `RC-NNN` | Never renumbered — a renumber breaks every recorded baseline |
| `fixture` | fixture path, **relative to the repo root**, or `--` | Byte-identical to a ledger `Doc`, so the § 3 join needs no path rewriting. **`--` marks a rule deliberately left unseeded**, and then `summary` carries the reason: one file records both what is covered and what is knowingly not, so there is no second list to keep in step |
| `class` | the artifact class the fixture belongs to | Always populated; read from `review-rubrics/INDEX.md` at build time, never hardcoded |
| `rule_id` | the rule expected to catch it | Mandatory. A rule set with no rule rows can supply none, which is what § 2b excludes |
| `enforcement` | `script` \| `judgment` | Routes the row to a lane. `script` only where the named oracle can decide it |
| `oracle` | the script for a `script` row, `--` otherwise | |
| `polarity` | `present` \| `absent` | **Whether the seeded defect is the locator being IN the fixture or MISSING from it.** Absence-shaped rules exist — a mandated section that must be there, a missing-content class — and without this column a check for "the locator is found" fails by construction on every one of them |
| `locator` | a content anchor | An anchor, never a line number: a fixture is edited by every re-seed. Read together with `polarity` — the defect is the anchor being present, or being absent, as that column says |
| `summary` | one line, plain text | Machine-read, so no glyphs. **States what makes this defect findable** — the § 8 judgement about whether the corpus is representative reads this column |

**`rule_set` is derived, not stored.** `FR-H2` reports *"per rule set"*, and the rule set is fixed twice
over by columns already present: `review-rubrics/INDEX.md` maps `class` to exactly one rule set, and a
`rule_id`'s prefix is unique across the rule-set files. Storing it would be a third source that can
disagree with the other two.

**Uniqueness: one seeded defect per `(fixture, rule_id)`.** The § 3 join is on `(Doc, Rule)`, and
without uniqueness it cannot tell which of two same-key rows a finding discharged. A fixture may carry
several seeded defects; they must differ in `rule_id`.

### 2b. The corpus domain

**A rule set is in the corpus if, and only if, it contains at least one rule row.**

That predicate follows from § 2's mandatory `rule_id`: a rule set with no rule rows offers none, so a
row for it cannot be authored, and `AC-16`'s *"no rule set reports zero fixtures"* would be
permanently unsatisfiable rather than merely pending.

**This SPEC does not enumerate the members.** The implementation evaluates the predicate by reading
the rule sets. Which rule sets satisfy it today is `delivery-024`'s task `DETAIL.md` content.

### 3. Feature flow — two lanes

Owner decision `STATE.md` Q31. Script-decided rules are asserted in CI; judgment-decided rules are
measured on demand. A CI runner cannot make the model call a judgment rule needs, and wiring one in
would make a deterministic gate depend on a non-deterministic agent.

**Lane A — script-decided, in CI.**

```
for each SEEDED catalogue row (fixture != --) where enforcement = script:
    run <oracle> over <fixture>
    assert the run REPORTS the defect -- always a positive assertion, whatever `polarity` says.
    `polarity` describes the fixture (is the anchor there, or missing?); it never inverts
    what the oracle is expected to do, which is to complain.
```

Lane A **asserts, it does not average**: expected recall for a script rule is 1.0, so a miss is a bug
in the oracle. It is a pass/fail suite like any other, which is what keeps `FR-F6` intact.

**Lane B — judgment-decided, on demand.**

```
1. dispatch a review over the corpus
2. take the resulting ledger
3. join reported (Doc, Rule) against catalogue rows where enforcement = judgment
4. report one line per rule_set, then one OVERALL line, each carrying the terms that apply:
       found / seeded(judgment)   -- a fraction over SEEDED judgment rows, or `--` where the rule
                                    set has no seeded judgment row
       asserted / total(script)   -- Lane A's count, or `--` where the rule set has no seeded
                                    script row
   Either term may be `--`; NEITHER is ever `0/0`, which reads as a measured zero. Every in-domain
   rule set gets its line with both terms present, one of which may be `--`: that is what makes
   AC-16's "reported for every rule set" decidable for a rule set seeded entirely in one lane.
5. APPEND every line to the series, stamped with a run identity, and print that rule_set's prior
   runs alongside the new one
```

**The denominator.** Lane B's fraction is over `enforcement = judgment` rows only. A `script` row is
never in a Lane B denominator — Lane A decides it and no agent behaviour can move it.

**Both terms of `FR-H2` are produced**: per rule set, and overall. The overall line is reported in
addition to the per-rule-set lines, never instead of them.

**The two lane terms are printed side by side, never blended** — on the per-rule-set lines and on the
OVERALL line. A blend would be the second grading arithmetic `FR-F6` retires, and would hide which
lane moved.

**The join key is `(Doc, Rule)`**, matching `reviewer-ledger-schema.md § Attempts and reconciliation`.

**Attribution needs `FR-D10`.** A miss is only useful if it names the pass that should have caught it,
which needs a coverage row whose unit is the claim.

### 4. Layers and components — affected artifacts

This is the feature's affected-artifact inventory. The `Delivery` column is part of it;
`PLAN.md` owns sequencing and dependency edges, which do not appear here.

**New:**

| Artifact | Purpose | Delivery |
|---|---|---|
| `tests/canonical/fixtures/recall-corpus/**` | the seeded artifacts | 024 |
| `tests/recall-catalogue.tsv` | the catalogue (§ 2) | 024 |
| `tests/canonical/test-recall-corpus.sh` | Lane A's assertions, plus § 6 checks 1-3 by default and check 4 behind a flag | 024 |
| `tests/canonical/fixtures/class-sweep/**` | `AC-17`'s fixture: a claim corrected in one file and restated in two others | 025 |
| `tests/canonical/test-class-sweep.sh` | asserts `AC-17` on that fixture: a phrase from the correction reports both other files, and a phrase absent from it reports no sites (§ 5) | 025 |
| `canonical/aid/scripts/review/class-sweep.sh` | the sweep: takes a phrase and a root, prints every matching site (§ 5) | 025 |
| `canonical/aid/scripts/review/recall-measure.sh` | Lane B: join, then emit the § 3 report | 027 |
| `tests/recall-baseline.tsv` | the accumulated series: one appended, run-stamped row per rule set per Lane B run. Created and appended by `recall-measure.sh`, so it needs no other writer | 027 |

**Changed:**

| Artifact | Change | Delivery |
|---|---|---|
| `canonical/skills/aid-execute/references/state-fix.md` | the class-sweep obligation: the fixer runs `class-sweep.sh` and includes its output in its report (§ 5) | 025 |


Every canonical change renders to five profiles, so `AC-12` parity and dogfood byte-identity apply.

### 5. `FR-E2` — the class sweep

```
before marking a fix complete, for each corrected claim:
    phrase := a distinguishing substring OF THE CLAIM THE FIX CORRECTED
    class-sweep.sh --phrase "$phrase" --root <the work>
    include the phrase and every site it printed in the fix report
```

**The phrase must be a substring of the text the fix changed.** That is what makes the obligation
falsifiable without needing a canonical way to derive the phrase: a sweep whose phrase does not appear
in the correction has not swept the corrected claim, and is not a discharge.

**A deletion sweeps like a correction.** If the corrected claim was restated elsewhere, the
restatement goes too.

**No ledger plumbing.** An earlier draft routed the sweep output into the reconciled row's `Evidence`,
which needed a new `writeback-ledger.sh` mode, an extension to the ledger schema's mode enumeration,
and a new step in `aid-deep-review`'s `RECONCILE` — three artifacts and a cross-skill duty to file one
string. `AC-17` requires that a fix **reports** its sweep, and a suite can assert that against
`class-sweep.sh` directly, so none of it is needed.

**`AC-17`'s fixture is a triple**: a claim corrected in one file and **restated in two other files**.
`test-class-sweep.sh` runs `class-sweep.sh` over it and asserts the output names **both** other files;
it then asserts a phrase absent from the correction reports no sites, so a sweep that matches nothing
cannot be mistaken for a sweep that found nothing to fix.

### 6. Verification — proving the corpus is not lying

All in `test-recall-corpus.sh`. **Checks 1-3 run in the default pass; check 4 runs only behind its
flag.** Lane A is the in-CI lane, so checks 1-3 are part of it and check 4 is an opt-in extra.

| # | Check | What it catches |
|---|---|---|
| 1 | **Every seeded catalogue row resolves**, in the direction `polarity` declares: a `present` row's `locator` is found in its `fixture`, an `absent` row's is not. Rows with `fixture = --` are exempt and must carry a `summary` reason | A defect re-seeded or removed while its row stayed, which would otherwise report as a permanent miss |
| 2 | **Every in-domain rule set has at least one SEEDED row** — a row with a real `fixture`, not a `--` exemption. A rule set whose every row is exempt reports zero fixtures, which is exactly what this check exists to catch | `AC-16`'s failure condition: a rule set reporting nothing and reading as clean |
| 3 | **Every rule row in an in-domain rule set has a catalogue row** — seeded, or `fixture = --` with a reason in `summary` | `FR-H1` mandates seeding **per rule**, and check 2 is per rule **set**: one seeded row satisfies check 2 while the rest of that rule set is uncovered. This closes the gap between them, and the `--` row is what makes an exemption explicit rather than silent |
| 4 | **Mutation of the mutation**, behind an explicit flag, **for each `script` row only**: repair that row's seeded defect in a scratch copy and assert **that row's** Lane A assertion flips to failing. A `judgment` row has no Lane A assertion to flip | A fixture whose oracle passes for a reason unrelated to the seeded defect |

**Check 4 runs one row at a time**, and behind a flag rather than in the default pass. A suite-level
red is satisfied by any one row failing, so it must confirm *that row's* assertion flipped.

### 7. Wiring

**Lane A** is `tests/canonical/test-recall-corpus.sh`, picked up by `run-all.sh`'s glob, carrying a
`# COVERS:` header — read by `select-suites.sh` — which narrows change-set selection to the paths it
names.

**Neither the tally nor the series needs a writer beyond § 4's.** The tally is gitignored, so the suite
that writes it mutates nothing tracked; the series has exactly one writer, so it needs no per-close
duty. § 4 states both files and their writers.

**There is deliberately no Lane A series.** An earlier draft had the delivery closing step append Lane A
terms from `delivery-024` onward. That is removed, because such a series would be **inert**: § 3 fixes
Lane A's expected value at 1.0 and a Lane A failure breaks the build, so a delivery can only close while
`asserted == total`. Every row before the first Lane B run would be the same constant, which makes
nothing attributable. What actually guards against a late unattributable figure is that **Lane A breaks
the build from `delivery-024`'s close onward** — a script rule that stops catching its seeded defect is
caught at that close, not at 027.

**`recall-measure.sh` fails if `.aid/.temp/recall-lane-a.tsv` is absent.** Absence means the suite has
not run in this tree, which is an error and not a value — reporting `--` for it would collide with
`--`'s one meaning in § 3.

**Lane B** is invoked deliberately, is not in CI, needs no credentials there, and adds nothing to CI
time.

**When each series starts.** `PLAN.md § Cross-Cutting Risks` row 6 records the risk that a figure
first taken at `delivery-027` is unattributable.

| From | Signal |
|---|---|
| `delivery-024` closing | **Lane A breaks the build** — a script rule that stops catching its seeded defect fails CI from this close onward |
| `delivery-027` closing | **Lane B's fraction**, per deliberate run, accumulating in the series |

Lane B cannot start earlier than `recall-measure.sh`, which ships with 027. `STATE.md` Q31 carries the
correction to its own mitigation wording.

**Lane B is not counted in `AC-13`.** That criterion measures whether the review split is cheaper;
Lane B's dispatches are measurement overhead, not review cost.

### 8. What could still go wrong

1. **A seeded defect can be too easy.** A corpus of obvious defects reports high recall and proves
   nothing. There is no mechanical guard: judging whether the corpus is representative is a review of
   the corpus, which § 2's `summary` column exists to make possible.
2. **Recall on fixtures is not recall on real artifacts.** A fixture is smaller than a real artifact
   and its defects were placed deliberately, so the figure is likely to be **higher** than live recall.
   Read it as a trend, not as a level.
3. **Judgment rows depend on a non-deterministic reviewer**, so Lane B's figure moves between runs
   with no change at all. One run below the last is therefore not evidence of a regression, which is
   why `FR-H3` is left to a reviewer's judgment and no threshold is specified anywhere.
