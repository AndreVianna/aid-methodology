# Measurement report — work-012

Produced by `task-015`. Every figure below states the command that produced it.

## AC-1 — **PARTIALLY MET.** One real reading, on one gate.

### What exists

The delivery gate is itself a review cycle, and FR-3 had already landed when it ran — so
its cycles are measurable, and were measured:

```
$ review-cost-meter.sh report --data .aid/works/work-012-review-loop-cost
  delivery-001-gate  cycles=2  rows=2  ratio=0.546
```

| Cycle | Declared read surface | What it was |
|---|---|---|
| 1 | 189,505 bytes | the full artifact set — FR-1 keeps cycle 1 unscoped |
| 2 | 103,538 bytes | the scoped hunt set plus the full verification set |

**Within-task re-read ratio: 0.546.** Cycle 2 declared 55% of what cycle 1 declared, for
the same task, same reviewer, same rubric. Under the unscoped rule that ratio is 1.000 by
construction, because every cycle re-declares the whole surface. Each task is its own
control, so this figure is not confounded by task size — and a raw cross-task byte
comparison is refused as evidence, per §9 AC-1.

### Why this is PARTIAL and not MET

**One task, two cycles, is a sample of one.** AC-1's subject (Q-03) is *per-task review
cycles across Execute, split at the task that lands FR-3* — six tasks before, seven after.
That sample does not exist, because `record` was not invoked during task execution.

**Why it was not invoked, concretely.** `record` takes `--brief <path>`: it measures a brief
that exists as a file on disk. Every per-task review in this delivery was dispatched with
the brief composed inline, so there was no file to point at, and no step in the loop that
would fail if `record` were skipped.

**This is the failure feature-001's own SPEC predicted**, in the section "The
agent-must-invoke-it risk, and an honest account of the mitigation":

> The measurement depends on the orchestrator actually running `record` at each dispatch.
> That is the same class of failure `tech-debt.md` `W5-5` documents … The mitigation
> **detects, it does not prevent**.

The detection worked — the gap is visible here rather than hidden behind a plausible
number, and `report` shows a row count of 2 beside the ratio precisely so a thin sample
cannot pass for a strong one. The prevention did not exist, because the SPEC never claimed
it would.

### The fix this points to

Not "remember next time". The invocation must live inside the dispatch step: render the
brief to a file before dispatching — which `reviewer-dispatch.md` already requires under
its inspectability rule — and call `record` from that same step. A mandate an agent can
satisfy by doing nothing is the W5-5 shape exactly. **Recorded as a follow-up.**

### What is deliberately NOT claimed

The gate-cycle counts from Describe, Define, Specify, Plan and Detail are real and recorded
in `STATE.yml`, and they are **not** offered as AC-1 evidence: every one ran before
`task-008` landed, so they are all "before" and yield no comparison. That is exactly why
Q-03 rejected the specify gates as the measurement subject. Presenting them as a result
would be the manufactured number this work exists to prevent.

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

## AC-11 — **PARTIALLY MET**

One oracle shipped: `scripts/checks/g07-selector-partition.sh`, 151 lines, 0.48 s per run.

| | |
|---|---|
| Files decided | **241 of 317 (76%)** |
| Undecided | 76 — all of `canonical/aid/templates/`, where `template-payload`'s recognizers test frontmatter *shape* |
| Re-derivation replaced | reading the registry, reading the corpus definition, enumerating every in-scope file, and applying each selector in order — by hand, every cycle, in every gate reviewing an in-scope file |
| Evidence the re-derivation recurs | `tech-debt.md` § L5 records `G-07` as "re-derived by hand each cycle … expensive and inconsistent between cycles" |

The trade is favourable on the axis AC-11 asks about: 241 files per cycle that a human no
longer enumerates, against 151 lines that run in half a second.

**But AC-11 asks for the measured per-cycle cost of the replaced re-derivation, and that
figure does not exist.** The count of files decided is real and reproducible; what it would
cost a reviewer to enumerate them by hand is not measured, only inferred. The gate marked
this MET on an earlier pass, which contradicted this section's own body — corrected here to
PARTIALLY MET rather than left as a verdict the evidence does not carry.

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
| AC-1 — observed cost reduction | **PARTIALLY MET** — one real gate measured at ratio 0.546; the per-task Execute sample was never collected |
| AC-9 — requirements-slice reduction | MET — 83% |
| AC-10 — grade.sh and the 7-column ledger untouched | MET |
| AC-11 — the oracle's trade, with a number | **PARTIALLY MET** — 241/317 decided is measured; the per-cycle cost it replaces is not |
| AC-12 — render and dogfood gates | MET in substance; one suite mawk-blocked, pre-existing |

**AC-1 is the criterion this work exists to satisfy, and it is the weakest one here.** The
premise was that cost claims must be measured rather than asserted. The honest outcome:
there is now one real measurement on one real gate — a 0.546 within-task re-read ratio,
which is the shape the work predicted — and a sample of one is evidence, not proof. The
mechanism is demonstrated; the saving is indicated rather than established.
