---
name: aid-report
description: >
  Analyse data or usage into an insight report. Use when the user needs the data or usage
  explained.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the data/usage to analyze (a dataset, logs, metrics, an A/B result)"
---

# Report (analyze now, resolve nothing)

`/aid-report` analyzes data/usage **now** and returns a **curated, verified insight
report**. Like `/aid-research` it resolves nothing -- it presents the picture and you
decide -- but its subject is *data* (a dataset, logs, telemetry, metrics, an A/B result)
rather than an open question.

- **Boundary:** `aid-report` = a **one-time** analysis + insight. A **durable, refreshable**
  BI view is `/aid-create-dashboard`, not this. If the user wants the analysis to recur,
  that's a printed handoff to `/aid-create-dashboard`.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> ANALYZE -> VERIFY (loop) -> PRESENT [user
resolves] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

1. **Check the subject.** Note whether the argument is empty. Do not ask here.
2. **Pick the path:** **Fast** -- a clear data source + a clear analytical ask ("analyze
   the A/B results in `results.csv`", "error-rate breakdown from these logs") -> analyze
   now. **Guided** -- vague ("analyze our usage") -> scope *which data, which metrics, what
   question* first, in INTAKE-ASK, then analyze.
3. **Classify complexity (model + effort):** simple (small dataset, one metric) ->
   `aid-researcher` at **sonnet / medium**; standard/complex (large data, A/B significance,
   deep telemetry) -> **opus / high**. Verifier tier >= producer tier.
4. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.

**Advance:** CHAIN -> [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works exist; otherwise CHAIN -> [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("What data should I analyze, and what
   question about it?"). The answer is the subject; the path and complexity are then set from it.
2. **Guided path** -> scope *which data, which metrics, what question*.
3. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

**Advance:** ASK -> [State: ALLOCATE].

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name (`aid-report`),
  its saved step (`ANALYZE`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), `--path lite`, and a kebab-case slug from the subject. The gate's `§ 3a` step 2 creates and enters the worktree
  (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." This skill drives no `phase`.
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

**Advance:** CHAIN -> [State: ANALYZE].

---

## State: ANALYZE

Access the data **read-only** and dispatch **`aid-researcher`** (clean context, tiered) to
analyze + consolidate:

- **Data access:** files / logs / exports -> read directly (never mutate the source). A
  live DB / analytics / telemetry service -> **MCP-first connector**
  (`connectors/consumption-protocol.md`): scan `.aid/connectors/INDEX.md`, request the
  connection from the host MCP; no catalogued connector -> the main conversation asks the user for the export, inside this step
  before the dispatch (the researcher never asks). Optional, never blocks.
- **Two-tier grounding (enforced):** the **data** + KB/source (what a metric means) are
  authoritative; external baselines/benchmarks are supplementary, cited URL + date. A
  data-vs-KB-assumption contradiction is surfaced with its reason, never resolved.
- It writes `REPORT.md` into the work folder (see [Response shape](#response-shape)).

**Advance:** CHAIN -> [State: VERIFY].

---

## State: VERIFY

1. **Mechanical grounding check** (no dispatch): findings cite the data; external claims a
   URL+date; the **Caveats** and **Conflicts** sections exist.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks `REPORT.md`:
   findings supported by the data; **no metric or A/B conclusion stated without its caveat**
   (sampling, significance, denominator, confounders); conflicts surfaced with reasons;
   conclusions not overstated into resolutions. Writes a review-quality ledger to
   `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to ANALYZE. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer.

**Advance:** CHAIN -> [State: PRESENT].

---

## State: PRESENT  (hard stop -- the user resolves)

The hard stop follows the ASK step of `skill-steps.md`. Present `REPORT.md` clearly: findings
(metrics/tables), conclusions (+/-), **caveats & data-quality gaps** (first-class),
conflicts with reasons, and gaps. Assert no resolution.

**Advance:** ASK -> [State: HANDOFF].

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions the user may act on: make it recurring (`/aid-create-dashboard`), record
a decision (`/aid-document-decision`), act on a conclusion (`/aid-create*` / `/aid-update*`),
or comment on a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`).
Never auto-invoked; never a resolution. Ask which one, if any, the user takes; a picked one is named
in one plain line.

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the work folder (`REPORT.md`, the verify ledger) as the audit record.

**Advance:** HALT.

---

## Response shape

`REPORT.md`, sections in order:

1. **Question / Scope** -- the analytical ask, as scoped.
2. **Data & method** -- what data, its source, and how it was analyzed.
3. **Findings** -- the metrics / tables / EDA output.
4. **Conclusions** -- positive *and* negative, each tied to a finding.
5. **Caveats & data-quality gaps** -- sampling, confounders, significance, missing data;
   `none` only if genuinely none.
6. **Conflicts & contradictions** -- data<->KB especially, each with its reason + citations;
   `none` if none.
7. **Sources** -- data source(s) + KB/`file:line` (authoritative) and external baselines
   `URL (accessed YYYY-MM-DD)` (supplementary), separated.

---

## Constraints

- **Resolves nothing**; presents findings/conclusions/caveats/conflicts/gaps.
- **Read-only on the data source**; never mutates it.
- **Two-tier grounding, enforced**; data<->KB conflicts surfaced with reasons.
- **Caveats are mandatory** -- a metric/A-B conclusion without its caveat fails VERIFY.
- **Clean context**; **verification always a sub-agent** (`aid-reviewer`).
- **Boundary:** durable/refreshable dashboards are `/aid-create-dashboard`, not this.
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).
