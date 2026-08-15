# Cost Measurement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-15, §9 AC-1, §10 step 1 | /aid-define |
| 2026-08-15 | Measurement subject named, discharging STATE.yml Q-03's obligation on Define | /aid-define |

## Source

- REQUIREMENTS.md §5 FR-15 (the before-and-after measurement)
- REQUIREMENTS.md §9 AC-1 (the observed reduction)
- REQUIREMENTS.md §10 Priority step 1 (this feature is first; the baseline gates everything after it)
- REQUIREMENTS.md §8 (FR-15 stands on its own instrument — no dependency on another work's meter)

## Description

The instrument, and the first reading taken with it.

This whole work is a cost argument, so every later claim it makes is either measured or
merely asserted. This feature builds the thing that measures, then takes the baseline
before any remedy lands. It comes first for a blunt reason: once a remedy is in the tree,
the "before" figure is gone and cannot be recovered.

What it measures is a review cycle's cost — the bytes a cycle reads, the tokens where the
host reports them, and the number of cycles a gate takes to close. It measures with a
local, deterministic count, so it depends on nothing outside this repository.

**The measurement subject, named here (Q-03).** This work's own **per-task review cycles
during Execute**, split at the task that lands FR-3 (the scoped hunt). Tasks reviewed
before that task lands are the "before" sample; tasks reviewed after it are the "after"
sample — same reviewer, same task-review rubric, many readings on each side. The
delivery-002 gate is a secondary reading.

The specify gates were considered and rejected as the subject: all three run before any
code lands, so they are all "before" and yield no comparison. A replay of a past work's
gate was rejected as the primary because a replay models rather than observes; it stays
available as a supplement if the live sample proves too small.

**Consequence for `/aid-plan`:** FR-3's task must land EARLY in delivery-002, or there are
too few "after" samples to compare. This is a sequencing constraint, not a preference.

## User Stories

- As the repo owner, I want a change's saving measured rather than argued, so that a cost
  decision rests on a number I can reproduce.
- As a reviewer of this work, I want the baseline captured before the first remedy lands,
  so that "it got cheaper" is a comparison rather than a claim.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-1** Given a real artifact and the named measurement subject, when a gate's cost
      is measured before any remedy lands and again after, then the after figure is lower
      and both figures are recorded together with the command that produced them.
- [ ] Given the same unchanged tree, when the meter runs twice, then it reports the same
      figures — the instrument is deterministic, or the comparison means nothing.
- [ ] Given this repository alone, when the meter runs, then it needs no artifact from any
      other work (§8) — the baseline is not contingent on another branch's merge order.
- [ ] Given the baseline has not yet been captured, when a task from feature-002 or
      feature-003 is executed, then that is a sequencing violation — §10 step 1 puts this
      feature first precisely so it cannot happen.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
