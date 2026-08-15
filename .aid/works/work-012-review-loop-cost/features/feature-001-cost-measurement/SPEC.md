# Cost Measurement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-15, §9 AC-1, §10 step 1 | /aid-define |
| 2026-08-15 | Measurement subject named, discharging STATE.yml Q-03's obligation on Define | /aid-define |
| 2026-08-15 | **AC-1 realigned with REQUIREMENTS.md §9 after cycle 2 found them contradicting.** §9's AC-1 had been re-specified around two size-robust metrics and this SPEC was left on the old single-figure wording, so a reviewer grading feature-001 against its own SPEC would have admitted evidence §9 explicitly refuses. Both metrics and the refusal are now stated here | /aid-define |
| 2026-08-15 | Technical Specification authored: the declared-read-surface proxy, the meter, and the two metrics' computation | /aid-specify |
| 2026-08-15 | **Specify gate cycle 1 (C) — the storage design was replaced, not patched.** The draft extended `dispatch_log` with three optional keys. `artifact-schemas.md § Conventions` prices a STATE field at template + `writeback-state.sh` + the (triplicated) reader twins, plus a render — for a number no dashboard reads. The meter now owns one work-folder TSV instead, so this feature makes no `canonical/` edit at all. Also: the false "`diff`/`report`" convention claim corrected, the split made rebase-safe via `--split-at-task`, and the W5-19 attribution fixed | /aid-specify |
| 2026-08-15 | **Specify gate cycle 2 (B) — `outcome` dropped, run identifier defined.** The `outcome` column could not be populated by a dispatch-time call, and neither metric needs it, so the column is gone rather than a second write added. The run-identifier mechanism, previously asserted, is now specified for an incremental appender: both files created together on the first `record`, every later `record` refusing to append on a mismatch, and `report` refusing to compute — a write-time check `coverage-parity.sh` does not need because it writes both files in one invocation | /aid-specify |

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

- [ ] **AC-1** Given the named measurement subject, when cost is measured before any remedy
      lands and again after, then the after figure is lower on **both** of the two metrics
      REQUIREMENTS.md §9 AC-1 defines, and both readings are recorded together with the
      command that produced them:
      1. **cycles to close** — a count, unaffected by task size;
      2. the **within-task re-read ratio** — bytes read on cycles 2+ as a fraction of that
         same task's cycle-1 bytes, so each task is its own control.
- [ ] Given a raw cross-task byte comparison offered as the reduction, when it is assessed,
      then it is **refused** as evidence: a smaller later task reads fewer bytes whether or
      not the remedy works. This criterion is stated here because feature-001 is the feature
      that would otherwise be tempted to accept it.
- [ ] Given the same unchanged tree, when the meter runs twice, then it reports the same
      figures — the instrument is deterministic, or the comparison means nothing.
- [ ] Given this repository alone, when the meter runs, then it needs no artifact from any
      other work (§8) — the baseline is not contingent on another branch's merge order.
- [ ] Given the baseline has not yet been captured, when a task from feature-002 or
      feature-003 is executed, then that is a sequencing violation — §10 step 1 puts this
      feature first precisely so it cannot happen.

---

## Technical Specification

### The measurement problem, and what is actually observable

A review cycle is performed by a dispatched LLM sub-agent. Nothing in this repository can
observe how many bytes that agent truly consumed, and §4 puts host-cooperating token
accounting out of scope. So the first design decision is **what to measure instead**, and
it has to be something that (a) is deterministic from disk, and (b) is precisely the thing
FR-3 changes. Measuring an approximation of the wrong quantity would be worse than not
measuring.

**The measured quantity is the DECLARED READ SURFACE** — the set of paths a cycle's
dispatch brief names under `ARTIFACTS UNDER REVIEW`, and their byte sizes on disk at that
commit.

This is the right quantity, not a convenient one:

- FR-3 does not change how an agent reads. It changes **what the brief tells it to hunt
  in**. The declared surface *is* the mechanism under test.
- `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` already makes the list binding: "The
  reviewer MUST NOT open any file not listed here", with three narrow exceptions
  (resolving a citation, looking up a named rubric, resolving declared criteria). Declared
  is therefore also *permitted*, which is the enforceable quantity.
- It needs no host cooperation, so NFR-2 holds and AC-1 does not depend on any tool
  outside this repository.

**Stated limitation, not hidden:** the declared surface is what a cycle was instructed to
read, not what it demonstrably read. An agent could read less, or could use an exception
clause to read more. The metric measures the contract, and the contract is what this work
changes. Any claim in the final report says "declared read surface", never "tokens
consumed".

### Data Model

No database, no schema change, and — after the decision below — **no STATE field either.**

**Rejected: extending `dispatch_log`.** The obvious design is to reuse the sanctioned
per-dispatch record. `task-state-template.yml` declares `dispatch_log: []` with
`date / agent / eta_band / actual / outcome`, appended by the dispatcher, which is the
natural home for a per-dispatch fact. It was rejected on cost, once the real cost was
looked up rather than assumed. `artifact-schemas.md § Conventions` sets the price of
adding a STATE field: *"add it to the AUTHORED zone of the right level's template, teach
`writeback-state.sh` to write it, and update the Node reader twin `reader.mjs`."* Both
readers are triplicated (`tech-debt.md § Duplication`), and a `canonical/` template edit
also triggers the NFR-5 render. That is a template, a writer, two reader twins across
their vendored copies, and a render — **for a number no dashboard ever displays.** The
measurement is per-work evidence with a transient lifetime; it does not belong in the
durable state schema a dashboard reads.

*(An earlier draft of this SPEC took the extension route and justified the added keys with
`frontmatter-schema.md § Parsing rules`. That rule is scoped to `review-criteria:` entries,
so the citation was an overreach as well as unnecessary. Recorded rather than quietly
dropped, because the reasoning error — reaching for a tolerance rule instead of the
schema-change convention — is the kind that recurs.)*

**Adopted: the meter owns one file, in the work folder.**

`review-cost.tsv`, one row per review cycle, tab-separated, deterministically sorted:

```
#run  <run-id>
task    cycle    commit    surface_bytes
```

Written a row at a time by `review-cost-meter.sh record` at dispatch, and read by
`report`. No template, no `writeback-state.sh` change, no reader twin, no render. It lives
in the work folder because it is per-work evidence, and because no permanent artifact may
depend on a work folder — AC-1's **conclusion** is what is reported out; the raw rows need
not outlive the work.

**There is deliberately no `outcome` column.** An earlier draft carried one, and it was
incoherent: `record` runs at dispatch, but a cycle's outcome is not known until the
reviewer returns, so a single dispatch-time call could never populate it. The choice was
between a two-phase write and dropping the column — and **neither metric needs it.**
Cycles-to-close is a row count; the ratio is arithmetic over `surface_bytes`. Adding a
second write to carry a field nothing consumes would have bought only the risk that the
second write is the one that gets skipped. One row, written once, at the moment the
declared surface becomes fixed.

**Convention followed, and where it is deliberately departed from.**
`tests/coverage-parity.sh` is the house precedent for a measurement tool: a `collect`
subcommand writing a deterministic `.tsv` plus a `.meta` provenance sidecar, and a reader
subcommand over the pair. Its actual subcommands are **`collect` and `diff`** — there is no
`report`. This meter keeps the `.tsv` + `.meta` shape and the deterministic-output
discipline, and departs by naming its two subcommands `record` (append one row, at
dispatch) and `report` (compute the two metrics). `record` exists because this data accrues
one cycle at a time rather than being collected in one sweep, and `report` computes rather
than compares, so neither `collect` nor `diff` would be an honest name.

**Designed around a known defect rather than into it.** `tech-debt.md` `W5-19` records that
`coverage-parity.sh`'s `.tsv` and `.meta` can be committed out of step with nothing
detecting it — and that the committed pair *was* out of step, which made its staleness
warning untrustworthy in both directions. W5-19's recommended fix is to stamp one run
identifier into both files and have **its `diff`** refuse when they disagree.

Adopting that fix needs more care here than in `coverage-parity.sh`, and the difference is
worth stating: there, `collect` writes both files in **one** invocation, so they cannot
disagree. This meter appends **one row per invocation** across many invocations, so the
pair is exposed for the whole life of the work. The run identifier is therefore defined
concretely rather than gestured at:

| Moment | Behaviour |
|--------|-----------|
| First `record` | Both files are created together. A run id is generated once — the work id plus a UTC timestamp — and written as the `.tsv`'s first line (`#run <run-id>`) **and** into the `.meta` alongside the usual provenance. |
| Every later `record` | Reads both ids first. **Refuses to append** if they disagree, if either file is missing, or if the `.tsv` has no `#run` line. Only then appends. |
| `report` | Re-checks the same equality and refuses to compute on a mismatch (W5-19's `diff` behaviour, at this tool's equivalent point). |

Checking at **write** time as well as read time is the part that goes beyond W5-19: a
mismatch is caught at the invocation that would have widened it, not discovered later by a
reader trying to trust the pair. Regenerating a `.tsv` without its `.meta`, or restoring
one file from a stale copy, is refused rather than silently absorbed.

### Feature Flow

```
Reviewer dispatched for task T, cycle N
  └─ orchestrator renders the brief (the ARTIFACTS list is fixed at this moment)
  └─ meter: record --task T --cycle N --brief <path>
        └─ verifies the .tsv/.meta run ids agree (creating both on first call)
        └─ sums the on-disk sizes of the paths named under ARTIFACTS UNDER REVIEW
        └─ appends one row: task, cycle, commit (HEAD), surface_bytes
     ONE command in the hot path, appending ONE row, at the moment the declared
     surface becomes fixed. Nothing else is written, and nothing is written later.

... cycles repeat, tasks complete ...

Reporting (out of band, any time)
  └─ meter: report --split-at-task task-NNN   (or --split-at <commit>)
        └─ refuses if the .tsv and .meta run ids disagree (W5-19)
        └─ per task: cycles-to-close, and the within-task re-read ratio
        └─ assigns each task to the before or after side of the split
        └─ prints both metrics for each side, and the row count behind each
```

**The before/after split is mechanical, not judged — and its primary form survives a
rebase.**

`--split-at-task task-NNN` is the **preferred** form: FR-3's task id is the boundary, tasks
are ordered by the execution graph, and a task id is stable under rebase, cherry-pick and
squash. `--split-at <commit>` is offered as a secondary form using
`git merge-base --is-ancestor`.

**The commit form is fragile and is documented as such rather than presented as
equivalent.** Recorded SHAs are orphaned by a rebase or a squash-merge of the delivery
branch, at which point `merge-base` either errors on an unknown object or silently
misclassifies rows. Since this work's own branch is expected to be merged, that is a
likely condition, not a hypothetical. `report` therefore fails loudly when a recorded
commit is no longer reachable, naming the rows affected, instead of reporting a split it
cannot justify. The `commit` column is retained for provenance and for spot-checking a
single row by hand; it is not the mechanism the headline figure rests on.

### Layers & Components

| Component | Path | Responsibility |
|-----------|------|----------------|
| Meter | `tests/review-cost-meter.sh` | `record` and `report`. Bash + awk only (NFR-2). Sits in `tests/` beside `coverage-parity.sh`, its convention sibling — **outside `canonical/`**, so it never enters the render chain (the same placement rule Q-02 sets for oracles, applied here for the same reason). |
| Data | `.aid/works/work-012-review-loop-cost/review-cost.tsv` + `.meta` | The only data this feature creates. Work-folder scoped; see Data Model. |

**Two components. No `canonical/` edit, no template change, no reader-twin change, and this
feature triggers no render** — a direct consequence of the Data Model decision above, and
the main reason that decision was made.

**The agent-must-invoke-it risk, and an honest account of the mitigation.** The measurement
depends on the orchestrator actually running `record` at each dispatch. That is the same
class of failure `tech-debt.md` `W5-5` documents at length: fourteen mandated state-writes
across seven skills that every call site failed to make work, silently, for as long as
nobody looked.

The mitigation **detects, it does not prevent** — stated plainly because the distinction is
the whole lesson of W5-5:

- `report` prints the row count behind every figure it produces, so a thin sample is
  visible on the same line as the number it produced.
- `report` refuses to compute a ratio for any task with fewer than two recorded cycles,
  rather than averaging over the hole.
- A task with no rows at all appears in the output as *missing*, never as zero.

A missing measurement must look like a missing measurement. It cannot be made to look like
a small one, which is the failure mode that would quietly manufacture a passing AC-1.

### Telemetry & Tracking

Activated: this feature *is* the telemetry. The two metrics are fixed by §9 AC-1 and
restated here only as their computation:

| Metric | Computation | Why it survives task-size differences |
|--------|-------------|----------------------------------------|
| Cycles to close | count of `review-cost.tsv` rows for the task | a count; task size does not enter it |
| Within-task re-read ratio | `mean( surface_bytes[cycle >= 2] ) / surface_bytes[cycle 1]` — the mean cycle-2-and-later surface, divided by that same task's cycle-1 surface | the denominator is the task's own cycle 1, so the task is its own control and its size cancels |

Expected reading: near `1.0` before FR-3 (every cycle re-declares the whole surface), below
it after. A raw cross-task byte comparison is refused as evidence (§9 AC-1).

### Sections not applicable

API contracts, UI, events/messaging, DDD, CQRS, state machines, security, cache, external
integrations, batch/jobs, mobile, search, AI, recovery, cloud, hardware — none apply. No
schema and no data to move, so no migration plan.

### Known issues touched

None registered. `W5-19` (the baseline pair drifting) and `W5-5` (silently-failing state
writes) are both **pre-existing entries already in `tech-debt.md`**, and both are designed
around above rather than inherited — so neither is a new issue this feature discovers.
