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

_Pending — authored section by section by `/aid-specify` (The Loop). See the work `STATE.md`
`## Features State` row for progress._

## Delivery recommendation

Already reflected in `PLAN.md`, which this spec follows rather than re-decides:

| Delivery | Carries | Track |
|---|---|---|
| `delivery-024` | `FR-H1` — the corpus and catalogue | free |
| `delivery-025` | `FR-E2`, `AC-17` — the class sweep | free |
| `delivery-027` | `FR-H2`, `FR-H3`, `AC-16` — the measurement | spine |

`delivery-026` carries `FR-D10` and belongs to `feature-005`, not here.
