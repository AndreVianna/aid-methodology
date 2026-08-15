# Impediment — delivery-001

**Type:** wrong-assumption

**Raised:** 2026-08-15, at the delivery gate, cycle 2. Grade **E+** against a floor of **A**.

## What happened

The delivery gate cannot be cleared, and the blocker is not fixable by more work.

**AC-1 requires a before/after measurement whose baseline had to be captured before any
feature-002 or feature-003 task landed. Those tasks have landed. The baseline moment has
passed and cannot be recreated on this delivery.**

Two of three remaining findings are minor. The blocker is one `[CRITICAL]`: AC-1 is not met
and cannot now be met here.

## Why it happened — the mechanism, not the blame

`review-cost-meter.sh record` takes `--brief <path>`: it measures a brief that exists as a
file on disk. Every per-task review in this delivery was dispatched with its brief composed
inline, so there was no file to point at — and, decisively, **no step in the execution loop
that would fail if `record` were skipped.** Nothing was bypassed; there was nothing to
bypass.

**This is the failure feature-001's own SPEC predicted**, in the section "The
agent-must-invoke-it risk, and an honest account of the mitigation":

> The measurement depends on the orchestrator actually running `record` at each dispatch.
> That is the same class of failure `tech-debt.md` `W5-5` documents at length … The
> mitigation **detects, it does not prevent** — stated plainly because the distinction is
> the whole lesson of W5-5.

The prediction was correct and the mitigation performed exactly as specified: the gap is
**visible** rather than hidden behind a plausible number. What the SPEC never claimed, and
what did not exist, was prevention.

## What the delivery does have

| | |
|---|---|
| The mechanism, working end to end | `delivery-001-gate` cycle 1 = 189,505 bytes (full), cycle 2 = 103,538 bytes (scoped) — **within-task re-read ratio 0.546**, where the unscoped rule gives 1.000 by construction |
| AC-9 | MET — the traced slice is 4,977 bytes against 29,040, an 83% reduction per specify-gate load |
| AC-10 | MET — `grade.sh` byte-identical to master; the ledger is still 7 columns |
| AC-12 | MET in substance — 1,770 files rendered, all verify gates pass, both dogfood trees 354/354 byte-identical |
| AC-2/3/4/5/6/7/8/13/14/15/16 | MET — 54 assertions across three suites, several mutation-checked |

The direction is right and the mechanism is demonstrated. What is missing is the
observational sample, on the one criterion whose entire purpose is to be observational.

## Options

**1. Accept the delivery at E+ with AC-1 recorded as PARTIALLY MET, and carry the
measurement forward as its own work.**
The mechanism ships and starts paying immediately; the 0.546 datapoint stands as an
indication, not a proof. The structural fix — render the brief to a file at dispatch and
call `record` from that same step — becomes a small follow-up work, and the *next*
full-path work produces the real per-task sample as a by-product of running normally.
*Cost:* the work ships without having proved its central claim.
*Honest framing:* AC-1 was written to stop exactly this, so accepting it is a deliberate
owner override, not a technicality.

**2. Add a task to this delivery that wires `record` into the dispatch step, then re-run
enough task-level reviews to build a sample.**
*Cost:* the re-run cycles would be manufactured for the measurement rather than performed
because a review was needed — measuring a process staged for the measurement. It also
cannot recover a true "before" baseline, since FR-3 has already landed; every new cycle is
an "after".

**3. Revert `task-008` (FR-3), collect a real "before" sample across several task reviews,
then re-land it and collect the "after".**
*Cost:* large and invasive — a revert plus a re-land of the central change, plus enough
review cycles on both sides to be meaningful. It is the only option that yields the sample
AC-1 actually specifies.

## Recommendation

**Option 1.**

The criterion's purpose was to stop a cost claim being asserted without evidence. That
purpose is served here even though the criterion is not met: the report states plainly that
the sample is one task, `report` prints `rows=2` beside the ratio so a thin sample cannot
read as a strong one, and nothing in this work claims a saving it has not measured.

Option 3 would satisfy the letter of AC-1 by manufacturing the conditions for it, which is
a worse kind of dishonesty than an unmet criterion — the number would be real and the
situation that produced it would be staged. Option 2 has the same defect without the
benefit of a true baseline.

The genuinely valuable output is the diagnosis: **a measurement mandate an agent can satisfy
by doing nothing will be satisfied by doing nothing.** That is W5-5 restated, confirmed a
second time, on a work that had read W5-5 and written a mitigation for it. Wiring `record`
into the dispatch step is the fix, and it is small.
