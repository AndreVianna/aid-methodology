# task-036 — corpus size, the NFR-3 floor, and where a recall regression routes

**Three questions.** How many defects should the seeded corpus hold? What measured re-derivation
must `review-recall.sh` remove to be worth merging at all? And when recall regresses, does that get
a criterion id or a tech-debt row?

**Three answers.** Twenty. A pairing count that is not merely tedious but *wrong by default*. And
neither yet — the routing is an owner decision, raised as a Q&A entry rather than settled here.

## The re-derivation, and why it is wrong rather than tedious

NFR-3 asks what a script removes. The honest version of that question is not "how much typing" but
"what does a human get wrong when they do this by hand". Recall is `found / seeded`, so computing it
by hand means deciding, for each seeded defect, whether any ledger row reports it.

The trap is in the denominator's sibling — counting what a ledger *found*. The obvious count is its
rows. That count is wrong, and measurably so:

```
$ L=.aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-025/FINDINGS.md
$ grep -cE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' $L
5
$ awk -F'|' '/^\|[[:space:]]*[0-9]+[[:space:]]*\|/{gsub(/ /,"",$4); if ($4=="Pending"||$4=="Recurred") n++} END{print n+0}' $L
0
```

Five rows, zero of them open. `grade.sh` counts only `Pending` and `Recurred`; a `Fixed` row is
history. Across three ledgers from delivery-001:

| Ledger | naive row count | status-aware | agree? |
|---|---|---|---|
| task-010 | 7 | 0 | **no** |
| task-016 | 7 | 0 | **no** |
| task-021 | 0 | 0 | yes |

Two of three disagree, and they disagree in the direction that flatters: a naive count reports
findings that were already closed. A hand-computed recall figure built on it overstates what the
review caught, which is the exact opposite of what a recall measurement is for. This is the
re-derivation the script removes — not labour, but a default-wrong answer that looks right.

**Across the whole corpus the claim is stronger than that sample.** The gate reviewer widened it
from three ledgers to all of them, and the sample turned out to be conservative:

```
$ # for each FINDINGS.md: naive row count vs rows whose Status is Pending or Recurred
  ledgers: 21   disagree: 17   agree: 0   empty: 4
```

Seventeen disagree, four are empty, and **not one non-empty ledger agrees**. The naive count is not
sometimes wrong; on this corpus it is wrong every time it says anything at all.

## Corpus size

The corpus is compared by what actually scales with it: pair-checks — each seeded defect against
each ledger row — and the read surface a cycle pays.

Current ledger corpus, measured:

```
$ find .aid/works -name 'FINDINGS.md' | wc -l
21
$ find .aid/works -name 'FINDINGS.md' -exec grep -chE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' {} \; | awk '{s+=$1} END{print s}'
90
```

| Corpus | Pair-checks vs 90 rows | By hand | Script upkeep |
|---|---|---|---|
| 10 | 900 | plausible once, never twice | one catalogue, ~10 fixtures |
| **20** | **1800** | not plausible | one catalogue, ~20 fixtures |
| 40 | 3600 | not plausible | fixtures start needing their own structure |

**The by-hand alternative is the option NFR-3 forces onto the table, so it is priced rather than
dismissed.** At 10 defects it is genuinely possible — 900 judgements is a long afternoon. It is also
the option that produces the wrong answer for the reason above, and produces a *different* wrong
answer each time it is run, which makes a recall trend meaningless. That is what rules it out, not
the arithmetic.

**Twenty is chosen** because it is the smallest size at which a per-rule-set breakdown has more than
a couple of defects per scope, and because the jump from 20 to 40 buys resolution the report cannot
yet use while doubling the fixtures someone must keep true. Forty is where fixtures stop being flat
files and start needing organisation of their own; the corpus should not reach that before anyone
has read a single recall report.

## The NFR-3 floor, as a number

**`review-recall.sh` does not merge unless it reports recall over at least 20 seeded defects against
at least 90 real ledger rows, both produced by commands in its own header.**

```
$ find .aid/works -name 'FINDINGS.md' -exec grep -chE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' {} \; | awk '{s+=$1} END{print s}'
90
```

The 90 is a floor, not a target: it is what exists now, so a script measured against fewer rows than
already exist is measuring a sample of a sample. Stating it as a number is the point —
"the script does not merge" becomes decidable rather than arguable.

## "The script does not merge" is an admissible outcome

Agreed in advance, so it cannot be reinterpreted later as failure:

> If task-038 cannot produce a recall report meeting the floor above, `review-recall.sh` is **not
> merged**, and task-038 is discharged by recording the measurement that fell short together with
> the by-hand alternative it was compared against. A script that cannot show what it removes is
> exactly what NFR-3 exists to stop, and stopping it is the requirement working, not the task
> failing.

The discharge wording is fixed here rather than at the moment of disappointment, because a floor
agreed after the measurement is not a floor.

## Where a recall regression routes — not decided here

A recall report is only useful if a drop has somewhere to go. Two routes:

- **A criterion id.** A reviewer would then cite it, and a regression becomes an ordinary finding
  with a severity. This puts a *trend* into a mechanism built for per-artifact facts, and the
  criterion would have no membership test — it is not true "of" any file.
- **A tech-debt row.** A regression becomes visible and prioritisable, but nothing blocks on it.

**No id is allocated by this task**; the allocation is out of scope pending an owner decision, per
`Q9`. The question is raised as a Q&A entry in this delivery's state file. The recommendation, for
the owner to accept or reject, is **tech debt**: a criterion's `Applies to` names files, and recall
is a property of a review rather than of any artifact, so the cascade is the wrong home for it.
