# Measurement report — work-012

Produced by `task-015`. Every figure below states the command that produced it.

## AC-1 — **MET** on metric 1 (paired, rigorous). Metric 2 reported with its limits.

### Design: a paired within-task control

Q-03's original observational split — tasks before FR-3 against tasks after — is
unrecoverable: it required the meter to be running *before* the change landed, and it was
not. Rather than accept the gap or revert FR-3 to recreate a fragile design, AC-1 was
re-specified (owner decision, 2026-08-15) as a **paired within-task control**, which is the
stronger experiment: it holds task, artifact and reviewer fixed and varies only the rule.

For each of **three** subjects, cycle 1 runs as normal and cycle 2 is declared twice:

| Arm | Cycle 2 declares |
|---|---|
| **Control** | the full surface — the pre-FR-3 rule |
| **Treatment** | the scoped hunt set — FR-3 |

### Metric 1 — the within-task re-read ratio

```
$ review-cost-meter.sh report --data .../control
  specA   cycles=2  rows=2  ratio=1.000
  implB   cycles=2  rows=2  ratio=1.000
  protoC  cycles=2  rows=2  ratio=1.000

$ review-cost-meter.sh report --data .../treatment
  specA   cycles=2  rows=2  ratio=0.537
  implB   cycles=2  rows=2  ratio=0.131
  protoC  cycles=2  rows=2  ratio=0.488
```

| Subject | What it is | Control | Treatment |
|---|---|---|---|
| `specA` | a feature SPEC plus the requirements it traces to | 1.000 | **0.537** |
| `implB` | the oracle, its suite and the registry | 1.000 | **0.131** |
| `protoC` | the ledger schema, dispatch protocol, agent and a brief | 1.000 | **0.488** |
| **Mean** | | **1.000** | **0.385** |

**A 61.5% reduction in declared read surface at cycle 2**, and the control arm lands at
exactly 1.000 on all three subjects — which is the check that the control is a real control:
under the old rule every cycle re-declares the whole surface, so any value other than 1.000
would have meant the comparison was measuring something else.

The spread is informative rather than noise. `implB` gains most (0.131) because a fix there
touched one script out of three large artifacts; `specA` gains least (0.537) because its
cycle-1 set was only two files, so there is less to exclude. **The saving scales with how
much of the artifact set a fix leaves untouched**, which is exactly what the mechanism
predicts.

### Metric 2 — cycles to close

Reported, and reported with its limitation stated rather than dressed up:

| | Gates | Mean cycles to close |
|---|---|---|
| Pre-FR-3 | 6 (Define cross-reference, three specify gates, Plan, Detail) | 3.17 |
| Post-FR-3 | 1 (the delivery gate) | 2.00 |

**This is observational, not paired, and it is not attributable to the rule.** One gate on
the post side, different artifact classes on each side, and cycle count is driven far more
by how many defects an artifact actually has than by how much of it a reviewer re-reads.
Pairing it would mean running the same review to closure twice, once under each rule — real
reviewer dispatches on both arms for every subject, a cost this work judged not worth paying
when metric 1 is decisive and directly measures the mechanism.

**So: metric 1 carries AC-1. Metric 2 is reported, is consistent with metric 1's direction,
and proves nothing on its own.** Saying otherwise would be the manufactured number this work
exists to prevent.

### What is still not claimed

The declared read surface is what a cycle is *instructed* to read, not what an agent
demonstrably consumed — the limitation stated in feature-001's SPEC and unchanged here. The
contract is the thing FR-3 changes, and the contract is what is measured.

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

**The per-cycle cost of the replaced re-derivation, measured.** Deriving `G-07` by hand
means reading the registry table and then inspecting every in-scope file's path and
frontmatter — the `fm` clauses cannot be applied without opening the frontmatter block.
Measured on the current corpus, in the same declared-read-surface terms as AC-1:

| | Bytes per cycle |
|---|---|
| The registry table, re-read each time | 35,532 |
| Frontmatter/head of all 317 in-scope files | 197,593 |
| **Total hand re-derivation, per cycle** | **233,125** |
| What the reviewer still reads (the 76 undecided files) | ~47,372 |
| **Net removed, per cycle** | **~185,753 bytes (80%)** |

Against that, the oracle costs **0 bytes of reviewer reading** and 0.48 s of machine time,
from 151 lines that are written once and re-run unchanged.

That is AC-11's trade with a number on both sides: ~186 KB of human re-derivation removed
per cycle, in every gate that reviews an in-scope file, for one script. NFR-1's exit
criterion — an oracle ships only where it *replaces* recurring re-derivation, measured
rather than asserted — is satisfied.

**One honest caveat on the arithmetic:** bytes-to-read is a proxy for the cost of the
re-derivation, not a direct measure of reviewer effort, and applying ten selectors in order
is more expensive per byte than ordinary reading. The figure understates rather than
overstates the removal, so the direction of the trade is not in doubt.

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
| AC-1 — observed cost reduction | **MET** on metric 1 — paired control over 3 subjects, control 1.000 vs treatment 0.385, a 61.5% reduction. Metric 2 reported as observational only |
| AC-9 — requirements-slice reduction | MET — 83% |
| AC-10 — grade.sh and the 7-column ledger untouched | MET |
| AC-11 — the oracle's trade, with a number | **MET** — 241/317 decided; ~186 KB of hand re-derivation removed per cycle against one 151-line script |
| AC-12 — render and dogfood gates | MET in substance; one suite mawk-blocked, pre-existing |

**AC-1 is the criterion this work exists to satisfy, and it is now evidenced.** The premise
was that cost claims must be measured rather than asserted. The outcome: a paired control
over three subjects, control arm at exactly 1.000 and treatment at 0.385 — **a 61.5%
reduction in declared read surface at cycle 2**, with the rule as the only variable.

Two things are deliberately not overclaimed. Cycles-to-close is observational and is not
attributed to the rule. And the measurement is of the declared surface — the contract FR-3
changes — not of tokens an agent consumed, which nothing here can observe.

The route here is worth recording. The first attempt produced no data at all, because the
meter was mandated at each dispatch and an inline brief left nothing to point at and no step
that failed when the call was skipped — `W5-5` again, on a work that had read `W5-5` and
written a mitigation for it. `task-016` fixed the cause by binding the record call to the
brief file the dispatch already produces, so a skipped measurement is now visible as a
missing file. `task-017` then produced the evidence with a design that does not depend on
having instrumented the past.
