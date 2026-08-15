# Measurement report — work-012

Produced by `task-015`. Every figure below states the command that produced it.

## AC-1 — **NOT MET**

**No before/after measurement exists, because `review-cost-meter.sh record` was never
invoked during execution.** `.aid/works/work-012-review-loop-cost/review-cost.tsv` does not
exist. There is no "before" sample and no "after" sample.

This is not a tooling failure. The meter works — `task-002`'s 18 assertions pass and two
injected mutants were killed. The instrument was built and then **not used**.

**It is the exact failure feature-001's own SPEC predicted, in the section titled "The
agent-must-invoke-it risk, and an honest account of the mitigation":**

> The measurement depends on the orchestrator actually running `record` at each dispatch.
> That is the same class of failure `tech-debt.md` `W5-5` documents at length: fourteen
> mandated state-writes across seven skills that every call site failed to make work,
> silently, for as long as nobody looked.
>
> The mitigation **detects, it does not prevent** — stated plainly because the distinction
> is the whole lesson of W5-5.

The detection worked: the absence is visible here rather than hidden behind a plausible
number. The prevention did not exist, because the SPEC deliberately did not claim it would.

**Why it happened, concretely.** `record` takes `--brief <path>`: it measures a brief that
exists as a file on disk. Every review in this work was dispatched as a sub-agent call with
the brief composed inline, so there was no brief file to point at and no step in the
execution loop that would have failed if `record` were skipped. Nothing was bypassed —
there was no wiring to bypass.

**The fix this points to, and it is not "remember next time".** The invocation has to be
part of the dispatch step itself rather than a discipline layered on top of it: the brief
must be rendered to a file before dispatch (which `reviewer-dispatch.md` already asks for
under its inspectability requirement), and the `record` call must sit in the same step that
renders it. A mandate that an agent can satisfy by doing nothing is the W5-5 shape exactly.
Recorded as a follow-up, not silently absorbed.

**What is deliberately NOT done here:** the gate-cycle counts from Describe, Define, Specify,
Plan and Detail are real and recorded in `STATE.yml`, and they are *not* presented as AC-1
evidence. Every one of those gates ran before `task-008` landed, so they are all "before"
and yield no comparison — which is precisely the reason Q-03 rejected the specify gates as
the measurement subject in the first place. Presenting them as a result would be the
manufactured-number failure this work exists to prevent.

### A demonstration of the mechanism — clearly not AC-1's evidence

The mechanism can be shown to work end to end, on real files, at this commit. This is a
**constructed demonstration**, not the observational before/after AC-1 requires, and it is
labelled that way so no reader mistakes it for the missing result.

```
$ review-cost-meter.sh record --task task-demo --cycle 1 --brief <full artifact set>
  declared read surface 63,454 bytes
$ review-cost-meter.sh record --task task-demo --cycle 2 --brief <scoped hunt set>
  declared read surface 34,414 bytes
$ review-cost-meter.sh record --task task-demo --cycle 3 --brief <scoped hunt set>
  declared read surface 34,414 bytes
$ review-cost-meter.sh report
  task-demo   cycles=3  rows=3  ratio=0.542
```

A within-task re-read ratio of **0.542** — cycles 2 and 3 declare 54% of what cycle 1
declared, for the same task. Under today's unscoped rule that ratio would be 1.000, because
every cycle re-declares the whole surface.

## AC-9 — **MET**

Command: the byte size of a feature's traced requirements slice against the whole document,
at the same commit.

| | Bytes |
|---|---|
| Whole `REQUIREMENTS.md` | 29,040 |
| The slice `feature-002` traces to (§9, from its `## Source`) | 4,977 |
| **Reduction per specify-gate load** | **24,063 bytes — 83% smaller** |

## AC-10 — **MET**

`canonical/aid/scripts/grade.sh` is byte-identical to `origin/master`:
`sha256 478103d69baa1eb0…` on both sides. The ledger header is still the 7-column form.

## AC-11 — **MET**

One oracle shipped: `scripts/checks/g07-selector-partition.sh`, 151 lines, 0.48 s per run.

| | |
|---|---|
| Files decided | **241 of 317 (76%)** |
| Undecided | 76 — all of `canonical/aid/templates/`, where `template-payload`'s recognizers test frontmatter *shape* |
| Re-derivation replaced | reading the registry, reading the corpus definition, enumerating every in-scope file, and applying each selector in order — by hand, every cycle, in every gate reviewing an in-scope file |
| Evidence the re-derivation recurs | `tech-debt.md` § L5 records `G-07` as "re-derived by hand each cycle … expensive and inconsistent between cycles" |

The trade is favourable on the axis AC-11 asks about: 241 files per cycle that a human no
longer enumerates, against 151 lines that run in half a second. **What is not claimed** is a
measured per-cycle cost of the replaced re-derivation — that would have come from the AC-1
data, which does not exist. The count is real; the saving it implies is an inference.

## AC-12 — **MET in substance, one check environment-blocked**

The full generator ran: 1,770 files emitted, 0 deleted, and all three verify gates pass —
byte-identical re-render, file-presence audit, frontmatter parse. Both dogfood trees resynced
manifest-driven: `.claude/` and `.cursor/` each report **354 of 354 entries byte-identical,
0 missing, 0 differing**.

`tests/canonical/test-dogfood-byte-identity.sh` could not run here: it uses gawk syntax and
this host has `mawk 1.3.4`, so it dies on an awk parse error before its first assertion.
**Verified pre-existing** — the suite fails identically on `origin/master` with the same
error, so this is the `W4-3` portability class, not a regression. CI, which has gawk, remains
the authority.

## Summary

| Criterion | Verdict |
|---|---|
| AC-1 — observed cost reduction | **NOT MET** — the instrument exists and works; the data was never collected |
| AC-9 — requirements-slice reduction | MET — 83% |
| AC-10 — grade.sh and the 7-column ledger untouched | MET |
| AC-11 — the oracle's trade, with a number | MET — 241/317 decided |
| AC-12 — render and dogfood gates | MET in substance; one suite mawk-blocked, pre-existing |

**AC-1 is the criterion this work exists to satisfy, and it is the one that failed.** The
premise was that cost claims must be measured rather than asserted; the honest outcome is
that this work can demonstrate its mechanism and cannot yet evidence its saving.
