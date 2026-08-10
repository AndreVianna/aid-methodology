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

## Description

Measure whether a review finds what is there, and make a fix account for its whole class.

Two mechanisms: a corpus of artifacts carrying **known, catalogued** defects, and a **reported
fraction** of those defects that a review pass finds. Plus one existing rule made mechanical: `F1` says
a finding is a class, and nothing checks it, so a corrected claim keeps its siblings.

Nothing changes about how a finding is severity-tagged, ruled, stored or graded. This adds a
denominator to a system that reports only a numerator.

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

1. A fixture corpus of reviewable artifacts carrying known, catalogued defects, seeded per rule.
2. The defect catalogue (§ 2).
3. The two-lane measurement and its report (§ 3).
4. The recorded baseline (§ 4), and `FR-H3`'s regression rule — which is a **review obligation, not
   a mechanism**: a run whose fraction has dropped against the prior run for the same rule set is
   reported as a defect in the review subsystem, to be justified or reverted. `recall-measure.sh`
   emits the delta (§ 3 step 5); acting on it is the reviewer's, which is why § 4 assigns it no
   further artifact.
5. The class-sweep obligation and its fixture (§ 5).

**Out of scope**

1. **Gating on the recall figure.** `FR-H2` makes this a measurement. A pass/fail bar would need a
   second grading arithmetic, which `FR-F6` forbids.
2. **Automating the repair** of siblings a sweep finds.
3. **Generating a coverage worklist** for an arbitrary artifact class — `FR-D10`, `feature-005`.
4. **Changing what `grade.sh` counts.** `NFR-1` and `AC-9` unaffected.

## Technical Specification

### 2. Data model — the defect catalogue

TSV, one row per seeded defect, at `tests/recall-catalogue.tsv`.

| Column | Content | Contract |
|---|---|---|
| `defect_id` | `RC-NNN` | Never renumbered — a renumber breaks every recorded baseline |
| `fixture` | fixture path, **relative to the repo root** | Byte-identical to a ledger `Doc`, so the § 3 join needs no path rewriting |
| `class` | the artifact class the fixture belongs to | Always populated; read from `review-rubrics/INDEX.md` at build time, never hardcoded |
| `rule_set` | the rule-set file whose rules should catch the defect | Several classes share a rule set, so this is not derivable from `class`. `FR-H2`'s *"per rule set"* is reported per `rule_set` |
| `rule_id` | the rule expected to catch it | Mandatory. A rule set with no rule rows can supply none, which is what § 2 excludes |
| `enforcement` | `script` \| `judgment` | Routes the row to a lane. `script` only where the named oracle can decide it |
| `oracle` | the script for a `script` row, `--` otherwise | |
| `polarity` | `present` \| `absent` | **Whether the seeded defect is the locator being IN the fixture or MISSING from it.** Absence-shaped rules exist — a mandated section that must be there, a missing-content class — and without this column a check for "the locator is found" fails by construction on every one of them |
| `locator` | a content anchor | An anchor, never a line number: a fixture is edited by every re-seed. Read together with `polarity` — the defect is the anchor being present, or being absent, as that column says |
| `summary` | one line, plain text | Machine-read, so no glyphs. **States what makes this defect findable** — the § 8 judgement about whether the corpus is representative reads this column |

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
for each catalogue row where enforcement = script:
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
       found / seeded(judgment)   -- a fraction, or `--` where the rule set has no
                                    judgment-decided rule
       asserted / total(script)   -- Lane A's count, or `--` where the rule set has no
                                    script-decided rule
   Either term may be `--`; NEITHER is ever `0/0`, which reads as a measured zero. Every in-domain
   rule set gets its line with both terms present, one of which may be `--`: that is what makes
   AC-16's "reported for every rule set" decidable for a rule set seeded entirely in one lane.
5. APPEND every line to the baseline, stamped with a run identity; report the delta against the
   most recent prior run for the same rule_set
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
| `tests/recall-unseeded.tsv` | rule rows deliberately left unseeded, each with a reason — § 6 check 3 reads it | 024 |
| `tests/canonical/fixtures/class-sweep/**` | `AC-17`'s fixture: a claim corrected in one file and restated in two others | 025 |
| `tests/canonical/test-class-sweep.sh` | asserts `AC-17` on that fixture, with and without the sweep | 025 |
| `canonical/aid/scripts/review/recall-measure.sh` | Lane B: join, then emit the § 3 report | 027 |
| `tests/recall-baseline.tsv` | the recorded report, appended never overwritten, with a run-identity column | 027 |

**Changed:**

| Artifact | Change | Delivery |
|---|---|---|
| `canonical/skills/aid-execute/references/state-fix.md` | the class-sweep obligation, and the requirement that the fixer's report carry the sweep output (§ 5) | 025 |
| `canonical/aid/scripts/review/writeback-ledger.sh` | a mode appending to an existing row's `Evidence` | 025 |
| `canonical/aid/templates/reviewer-ledger-schema.md` | its enumeration of `writeback-ledger.sh`'s modes and guarantees, extended for the new mode | 025 |
| `canonical/aid/templates/review-rubrics/INDEX.md` | a pointer to the corpus, so a new rule set is told it needs a fixture | 024 |

Every canonical change renders to five profiles, so `AC-12` parity and dogfood byte-identity apply.

### 5. `FR-E2` — the class sweep

```
before marking a fix complete:
    phrase := the distinguishing phrase quoted in the ledger row's Evidence cell
    grep the phrase across the work
    report every site
```

**The phrase is read out of the row, not chosen** — it is the string the row's `Evidence` already
quotes, so two fixers discharging the same row sweep the same string. Where a row's `Evidence` quotes
no phrase, the sweep obligation cannot be discharged mechanically and the fixer says so rather than
inventing one.

**A deletion sweeps like a correction.** If the corrected claim was restated elsewhere, the
restatement goes too.

**Where the output is recorded.** The fixer cannot write the canonical ledger: it has a single writer,
the orchestrator. So `state-fix.md` gains the obligation that the fixer's return carry the sweep
output, and the orchestrator appends it to the row's `Evidence` when it reconciles — which is the
`writeback-ledger.sh` mode § 4 inventories. `AC-17` is then decided by `test-class-sweep.sh` (§ 4) reading the reconciled row on its fixture: the
`Evidence` names the two other files, or the assertion fails. The actor is the suite, so the criterion
is decided mechanically rather than by whoever happens to look.

**`AC-17`'s fixture is a triple**: a claim corrected in one file and **restated in two other files**.
Asserted in both directions — with the sweep it passes, without it fails.

### 6. Verification — proving the corpus is not lying

All in `test-recall-corpus.sh`. **Checks 1-3 run in the default pass; check 4 runs only behind its
flag.** Lane A is the in-CI lane, so checks 1-3 are part of it and check 4 is an opt-in extra.

| # | Check | What it catches |
|---|---|---|
| 1 | **Every catalogue row resolves**, in the direction `polarity` declares: a `present` row's `locator` is found in its `fixture`, an `absent` row's is not | A defect re-seeded or removed while its row stayed, which would otherwise report as a permanent miss |
| 2 | **Every in-domain rule set has at least one row** (§ 2's predicate, evaluated by reading the rule sets) | `AC-16`'s failure condition: a rule set reporting nothing and reading as clean |
| 3 | **Every rule row in an in-domain rule set either has a catalogue row, or a row in `tests/recall-unseeded.tsv` carrying a reason** (§ 4 inventories that file) | `FR-H1` mandates seeding **per rule**, and check 2 is per rule **set** — one seeded row satisfies check 2 while the rest of that rule set is uncovered. This closes the gap between them, and the reason column is what keeps an exemption honest rather than silent |
| 4 | **Mutation of the mutation**, behind an explicit flag, **for each `script` row only**: repair that row's seeded defect in a scratch copy and assert **that row's** Lane A assertion flips to failing. A `judgment` row has no Lane A assertion to flip | A fixture whose oracle passes for a reason unrelated to the seeded defect |

**Check 4 runs one row at a time**, and behind a flag rather than in the default pass. A suite-level
red is satisfied by any one row failing, so it must confirm *that row's* assertion flipped.

### 7. Wiring

**Lane A** is `tests/canonical/test-recall-corpus.sh`, picked up by `run-all.sh`'s glob, carrying a
`# COVERS:` header — read by `select-suites.sh` — which narrows change-set selection to the paths it
names.

**Lane A's tally is a run artifact, not a tracked file.** `test-recall-corpus.sh` writes
`rule_set \t asserted \t total` to `.aid/.temp/recall-lane-a.tsv`, which `recall-measure.sh` reads
when assembling the § 3 report. `.aid/.temp/` is gitignored, so this does not mutate the source tree
and needs no separate tool and no CI wiring: the tally exists in whatever working tree the suite has
run in, which is the tree Lane B runs in too.

**Lane B** is invoked deliberately, is not in CI, needs no credentials there, and adds nothing to CI
time.

**When each series starts.** `PLAN.md § Cross-Cutting Risks` row 6 records the risk that a figure
first taken at `delivery-027` is unattributable.

| From | Signal available |
|---|---|
| `delivery-024` closing | Lane A's **pass/fail result in CI**, on every run — a script rule that stops catching its seeded defect breaks the build from this close onward |
| `delivery-027` closing | Lane B's fraction, per deliberate run |

Lane A's signal is a build result, not a stored series: the tally is a run artifact. Lane B cannot
start earlier than `recall-measure.sh`, which ships with 027. `STATE.md` Q31 carries the correction to
its own mitigation wording.

**Lane B is not counted in `AC-13`.** That criterion measures whether the review split is cheaper;
Lane B's dispatches are measurement overhead, not review cost.

### 8. What could still go wrong

1. **A seeded defect can be too easy.** A corpus of obvious defects reports high recall and proves
   nothing. The catalogue's `summary` states what makes each defect findable, so a reviewer of the
   corpus can judge whether it is representative.
2. **Recall on fixtures is not recall on real artifacts.** The figure is a floor and a trend line.
   `FR-H3` treats a *drop* as the signal, which is robust to the absolute number being optimistic.
3. **Judgment rows depend on a non-deterministic reviewer**, so Lane B's figure moves between runs
   with no change at all. The baseline appends one stamped row per run per rule set, so the run count
   is derived by counting rows over a window; a single run's movement is not a regression.
