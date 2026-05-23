# Two-Tier Review Model

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR2) | /aid-interview |
| 2026-05-22 | Technical Specification — Data Model section written (per-task quick check vs. per-delivery gate STATE shapes; delivery-issue-log artifact) | /aid-specify |
| 2026-05-22 | Technical Specification — Feature Flow section written (per-task quick-check flow; per-delivery gate as aid-execute closing step; FR2 deferrals resolved) | /aid-specify |
| 2026-05-22 | Technical Specification — Layers & Components section written (quick-reviewer cheap-tier dispatch; proportional gate-reviewer tier from complexity score) | /aid-specify |
| 2026-05-22 | Technical Specification — State Machines section written (revised aid-execute state machine + new delivery-gate state machine) | /aid-specify |
| 2026-05-22 | Technical Specification revised — (A) merged-task-file: quick check + delivery gate record into the `task-NNN.md` Execution Record zone, no separate `task-NNN-STATE.md`; (B) lite path uses one consolidated work-root `SPEC.md`, gate + complexity score read inputs from `PLAN.md` (full) or work-root `SPEC.md` (lite) | /aid-specify |
| 2026-05-22 | Cross-cutting + precision fixes (CR7) — (1) corrected the `task-NNN-STATE.md` reference count from ~12 to **16** and enumerated all 16 line cites in the `aid-execute/SKILL.md` edit surface (67, 83, 119, 155, 159, 172, 194, 203, 208, 218, 234, 281, 291, 297, 360, 386); (2) added "Template authorship — feature-002 owns the two-zone `task-NNN.md` (CR7)" subsection in Layers & Components — feature-004 *writes into* the Execution Record scaffold created by `aid-detail` (delivered by feature-002), it does **not** create the zone; (3) reconciled the Data Model "Changed — Execution Record zone of `task-NNN.md`" passage with the same model — `aid-detail` creates `task-NNN.md` with Definition filled and Execution Record as empty scaffold, `aid-execute` populates the scaffold (no contradiction with Layers & Components); (4) replaced the stray `[MAJOR…]` token in the `### Findings` table row with `[HIGH]` for consistency with the spec's "major" → `[HIGH]` mapping; (5) made the `## Delivery Gate` block location-rule **explicit and FR6-aware** in Data Model — terminal node of the Execution Graph, highest-numbered tiebreak, identical for writer (`aid-execute`) and reader (`aid-deploy`); (6) added a "Naming reconciliation (both forms intentional)" note pinning instance to `.aid/{work}/delivery-NNN-issues.md` and template to `templates/delivery-issues.md` — mirrors the `task-template.md` → `task-NNN.md` convention; (7) added a "Parallel-write coordination (FR6)" note — quick checks write deferred `[HIGH]` rows into their own `task-NNN.md` Execution Record (single-writer), and the gate's new step 0 (`AGGREGATE`) writes `delivery-NNN-issues.md` once, serially, after the all-`Done` trigger — no append race; updated Flow A TRIAGE and Flow B gate to reflect this; (8) corrected the IMPEDIMENT line cite from `aid-execute/SKILL.md:308-330` to `:305-330`. `## Open Questions` (OQ1–3) already present and inline-ref-consistent — verified, no change. | reviewer |

## Source

- REQUIREMENTS.md §5 FR2, §6 NFR6, §9, §10

## Description

Today every task in `aid-execute` is put through a full quality gate — a review →
fix → review loop run until it grades A — which is slow and runs the expensive
Large-tier reviewer once per task. This feature replaces that with a two-tier
model. During execution each task gets a single quick check: one review pass, no
grade loop, run by a cheap-tier reviewer, surfacing only major and critical errors;
a critical error gets one immediate fix on the spot, while major errors and below
are logged for later. Then a single per-delivery quality gate runs the rigorous
review → fix → review loop once, at the end of the whole delivery, until it reaches
the A-grade minimum, with a reviewer whose model and effort scale proportionally to
the delivery's complexity. The deterministic grade computation is preserved and runs
at the per-delivery gate, so speed is gained without making grading subjective.

## User Stories

- As an AID end user, I want each task checked quickly for showstoppers so that a
  broken task is caught early without paying for a full grade loop on every task.
- As an AID end user, I want the rigorous A-grade quality gate to run once per
  delivery so that the methodology stays fast while the overall quality bar is still
  enforced.
- As an AID end user, I want the delivery-gate reviewer right-sized to the delivery
  so that simple deliveries are not over-reviewed and complex ones get the depth they
  need.

## Priority

Must

## Acceptance Criteria

> "Major" is FR2's source wording; the universal rubric (`templates/grading-rubric.md`)
> has no "Major" tier, so throughout this feature **"major" = rubric `[HIGH]`** and
> **"critical" = rubric `[CRITICAL]`** (see the Severity vocabulary note in Data Model).

- [ ] Given a task is being executed, when its review runs, then it gets exactly one
  quick review pass with no grade loop, reporting only major (= rubric `[HIGH]`) and
  critical (= rubric `[CRITICAL]`) issues.
- [ ] Given a quick check finds a critical (`[CRITICAL]`) issue, when it is reported,
  then exactly one immediate fix is applied; given it finds major-or-below
  (`[HIGH]`-or-below) issues, then those are logged for the per-delivery gate.
- [ ] Given a delivery's full set of tasks is complete, when the per-delivery quality
  gate runs, then the full review → fix → review loop runs until the grade reaches
  the minimum (A).
- [ ] Given a delivery enters its quality gate, when the gate's reviewer is selected,
  then its model tier varies with the delivery's complexity.
- [ ] Given the per-delivery quality gate runs, when the grade is determined, then it
  is computed deterministically (`grade.sh`) from a severity-tagged issue list.

---

## Technical Specification

> This feature changes the **review granularity** of `aid-execute` — not the
> methodology (REQUIREMENTS.md §7). The phases, artifacts, the reviewer ≠ executor
> invariant, and the deterministic grade (`grade.sh` from a severity-tagged issue
> list, NFR6) are all preserved. What changes: the rigorous review → fix → review
> loop moves from once-per-task to once-per-delivery, and a new lightweight
> per-task quick check replaces it during execution.
>
> Consistent with `work-002`'s `feature-001-profile-driven-generator` spec style, the design is grounded in the **real
> `aid-execute` skill structure** — `claude-code/.claude/skills/aid-execute/SKILL.md`
> and its `references/reviewer-guide.md` / `references/task-type-rules.md`. The
> `aid-execute` skill is itself in scope for the FR3 thin-router refactor
> (`feature-002`); this spec is written against the **current monolithic SKILL.md**
> and notes where each piece lands in the future `references/state-*.md` structure.

### Data Model

FR2 changes two AID artifacts and adds one. No host-tool schema and no `grade.sh`
contract change.

#### Changed — the Execution Record zone of `task-NNN.md`

There is **no separate `task-NNN-STATE.md`** and no `implementation-state.md`
template. Per the merged-task-file decision (the **two-zone `task-NNN.md`
template is owned by feature-002 / CR7** — see Layers & Components), `task-NNN.md`
has two zones:

- a **Definition** zone (`Type` / `Source` / `Depends on` / `Scope` /
  `Acceptance Criteria`) — written by `aid-detail` (filled), stable, never
  touched by FR2;
- an **Execution Record** zone — `Status`, review record, dispatches — created
  by `aid-detail` as an **empty scaffold** (section headers only) when the
  `task-NNN.md` is first generated, and then **populated by `aid-execute`** as
  the task runs. FR2 changes only this zone's contents (the `## Quick Check`
  and `## Delivery Gate` blocks); the scaffold itself is delivered by
  feature-002. There is no "create the file" step at execute time — the file
  and its empty scaffold already exist.

The pre-FR2 Execution Record carried a `## Current Review` block (`Cycle` +
`Grade` + `### Issues`) and a `## Review History` — both of which assumed the
per-task grade loop. Under FR2 a task is **no longer graded** during execution.
The review part of the Execution Record is replaced:

| Field / block in the Execution Record | Before (current) | After (FR2) |
|---------------------------------------|------------------|-------------|
| `## Current Review` | `Cycle`, `Grade`, `### Issues` | Renamed `## Quick Check` — `Reviewer Tier`, `### Findings` (the single quick-check pass; no `Cycle`, no `Grade`) |
| `### Issues` | severity-tagged list, all severities | `### Findings` — severity-tagged list, **only `[CRITICAL]` and `[HIGH]` and above** surfaced; lower severities not reported by the quick reviewer at all |
| `### Findings` row status | `Pending / Fixed / Accepted / Loopback` | `Fixed-on-spot` (a critical, one immediate fix) · `Deferred-to-gate` (a major or below, rolled into the delivery issue log) |
| `## Review History` | one entry per review cycle | dropped — there is no loop; the single quick check is the whole record |
| `## Dispatches` | unchanged | unchanged — the quick-check dispatch is logged as one row in the Execution Record |

The per-task quick check writes its result into the Execution Record zone of
`task-NNN.md` itself — not into a separate STATE file. The per-delivery gate
likewise records into the Execution Record zone (see the `## Delivery Gate`
block below and Feature Flow).

> **Severity vocabulary note.** The universal rubric
> (`templates/grading-rubric.md`) uses `Minor / Low / Medium / High / Critical`.
> FR2's source text uses "major and critical". This spec maps **"major and above"
> to rubric `[HIGH]` and `[CRITICAL]`**, and **"critical" to rubric `[CRITICAL]`**.
> The quick check surfaces `[HIGH]` + `[CRITICAL]` only; of those, `[CRITICAL]`
> gets the immediate fix and `[HIGH]` is deferred. This keeps one severity
> vocabulary across the whole methodology — see Open Question 1.

#### New — delivery issue log: `delivery-NNN-issues.md`

Per-task quick checks across a delivery accumulate their deferred findings here so
the per-delivery gate has them in one place. One file per delivery, named
`delivery-NNN-issues.md` (`NNN` = the delivery id), at the **exact path
`.aid/{work}/delivery-NNN-issues.md`** — a sibling of the `tasks/` directory, not
inside it. The instance file name (`delivery-NNN-issues.md`) is per-delivery; the
**template** it is created from is the single shared `templates/delivery-issues.md`
(name without the `NNN` — the Layers table is intentionally correct).

> **Naming reconciliation (both forms intentional).** Two names, two purposes:
> the **template** at `templates/delivery-issues.md` is **one file** shared by
> every delivery — it is not parameterised by `NNN`. Each delivery's
> **instance** at `.aid/{work}/delivery-NNN-issues.md` is created from that
> template, with `NNN` substituted in the filename and in the `# Delivery Issue
> Log — delivery-NNN` H1. The mismatch (template without `NNN`, instance with
> `NNN`) is deliberate, not a typo — it mirrors the existing
> `templates/delivery-plans/task-template.md` → `task-NNN.md` convention.

One template, many `delivery-NNN-issues.md` instances:

```
# Delivery Issue Log — delivery-NNN

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded — grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-003 | [HIGH] | error path not covered by a test | Open |
| task-005 | [HIGH] | naming deviates from coding-standards | Open |
```

`Status` is `Open` until the per-delivery gate's review → fix loop resolves it,
then `Resolved` (or `Accepted` if the gate grade clears the minimum with it still
present). This file is **input context** to the gate reviewer, *not* the graded
artifact — the gate reviewer produces its own fresh severity-tagged issue list,
and `grade.sh` runs on that (NFR6 preserved: the grade is computed, never
inherited).

> **Parallel-write coordination (FR6).** Under FR6 multiple per-task quick
> checks may complete concurrently and each may want to append a deferred
> `[HIGH]` row to the same `delivery-NNN-issues.md`. The chosen model is **write
> locally, aggregate at the gate**: each quick check writes its findings into
> *its own* `task-NNN.md` Execution Record `## Quick Check` block (which is
> single-writer by construction — one task, one Execution Record), and the
> per-delivery gate's **Step 0 AGGREGATE** (run before SCORE — see Flow B)
> **aggregates** the deferred `[HIGH]` rows from every task's `## Quick Check`
> block into `delivery-NNN-issues.md` in
> a single serial pass. There is therefore **no concurrent writer** to
> `delivery-NNN-issues.md` — the file is written once, by `aid-execute`'s
> closing-step gate, after every task is `Done` (the same all-`Done` predicate
> that triggers the gate). This sidesteps file-locking entirely and stays
> consistent with Pattern 1 ("filesystem is the only source of truth"); no
> append race is possible.

#### New — `## Delivery Gate` block in the Execution Record

The per-delivery gate records its outcome in a `## Delivery Gate` block. There is
no separate per-delivery STATE file: the block is appended to the Execution Record
zone of the delivery's **gate-record task** — a **deterministic** identity, since
under FR6 parallel execution "the last task to finish" is a race, not a stable
identity. The gate-record task is defined as the **terminal node of the delivery's
Execution Graph** — the task that has no outgoing dependency edge within the
delivery; if the graph has more than one terminal node, the **highest-numbered
`task-NNN.md`** among them. This rule is computed from the same Execution Graph the
complexity score uses, so it is identical no matter which task happened to finish
last. The block holds the tier used, the final grade, the cycle count, and the gate
reviewer's issue list. One delivery has exactly one `## Delivery Gate` block, and it
is the canonical record that the delivery is gate-passed.

#### Changed — `DEPLOYMENT-STATE.md` precondition (read-only)

The per-delivery gate is the **closing step of `aid-execute`** (see Feature Flow).
`aid-deploy` does not run the gate; it only *checks* that the gate passed. Its
Step 1 "Assess" (`aid-deploy/SKILL.md:76-88`) already reads task grades; FR2
changes the field it reads — from per-task grades to the **per-delivery gate
grade** recorded in the `## Delivery Gate` block in the **gate-record task's**
Execution Record (the deterministic Execution-Graph terminal node defined above —
so `aid-deploy`'s read is deterministic, not dependent on task finish order). No
new file; one new block in an existing artifact.

> **Determinism rule (explicit, FR6-aware).** Under FR6 parallel execution
> multiple tasks may complete simultaneously, so "the last task" is a race and
> cannot be used. The `## Delivery Gate` block is therefore **always** written
> to — and read from — the deterministic **gate-record task**, computed from the
> delivery's Execution Graph: (1) the unique task with no outgoing dependency
> edge within the delivery; (2) if there is more than one such terminal node,
> the **highest-numbered `task-NNN.md`** among them (lexical compare on the
> three-digit id). Both `aid-execute` (writer) and `aid-deploy` (reader) apply
> the **same** rule against the **same** Execution Graph, so the location is
> identical no matter the actual finish order under FR6.

#### Delivery-complexity signal (drives the proportional reviewer)

FR2 defers the complexity signal to `aid-specify`. **Resolved:** the signal is
**computed deterministically from the delivery's Execution Graph and its task
files** — data `aid-execute` already loads. No new input, no human judgement, no
LLM estimate.

The Execution Graph that feeds the score has **two source locations** depending
on the path (see also "Lite-path deliveries" below):

- **Full path** — the delivery is defined in `PLAN.md`; the Execution Graph and
  the delivery-level task list are read from `PLAN.md` (`SKILL.md:185-186`).
- **Lite path** — there is no `PLAN.md` and no feature folder. The lite path
  produces one consolidated `SPEC.md` at the work root (`.aid/work-NNN/SPEC.md`)
  that merges the per-feature spec with the PLAN information — delivery,
  dependency graph, delivery-level acceptance criteria, and task list. On the
  lite path the score reads the Execution Graph and task list from that
  **work-root `SPEC.md`**.

In both cases the per-task `Type` fields are read from the `task-NNN.md`
Definition zones. The complexity score is the sum of:

| Factor | Source | Contribution |
|--------|--------|--------------|
| Task count | tasks in the delivery (Execution Graph — `PLAN.md` on the full path, work-root `SPEC.md` on the lite path) | 1 point per task |
| Graph depth | longest dependency chain in the delivery's Execution Graph (same source as above) | 1 point per edge on the longest chain |
| Risk-weighted types | each task's `Type` field (`task-NNN.md` Definition zone) | `MIGRATE` / `REFACTOR` +2; `IMPLEMENT` / `TEST` +1; `RESEARCH` / `DESIGN` / `DOCUMENT` / `CONFIGURE` +0 |
| Specialist consults | quick-check `[CRITICAL]` fix-on-spot count + tasks whose Agent-Selection row triggers a `security` / `performance` consult | +1 each |

The score maps to the gate reviewer's tier by two thresholds stored in
`DISCOVERY-STATE.md` (new fields, defaulted at `/aid-init`):

| Score band | Gate reviewer tier | Rationale |
|------------|--------------------|-----------|
| `≤` `**Gate Tier Low Threshold:**` (default 6) | Small (cheap) | trivial delivery — a lite-path delivery typically lands here |
| between the two thresholds | Medium | the common case |
| `≥` `**Gate Tier High Threshold:**` (default 14) | Large | big or risky delivery — full depth warranted |

Thresholds are config, not hardcoded, so the methodology owner can tune them
without a skill edit — consistent with how `Minimum Grade` is already handled
(`SKILL.md:124`). See Open Question 2.

### Feature Flow

Two flows replace the single per-task grade loop. Both run inside `aid-execute`.

#### Flow A — per-task quick check (replaces current Steps 2–4 per task)

Current `aid-execute` runs, per task: `EXECUTE → REVIEW → Present → FIX → back to
REVIEW … → DONE when grade ≥ minimum` (`SKILL.md:19-23, 212-300`). FR2 replaces
the REVIEW/FIX loop with a single non-looping pass:

```
EXECUTE (Step 1 — unchanged)
  └─ executor reports done; gates verified (build/lint/test) — SKILL.md:207
QUICK-CHECK (new — replaces Step 2 REVIEW)
  └─ dispatch the reviewer at the cheap (Small) tier, clean context
     (reviewer ≠ executor invariant preserved — SKILL.md:56)
  └─ reviewer runs ONE pass; reports ONLY [HIGH] + [CRITICAL] findings
  └─ NO grade.sh, NO grade, NO loop
TRIAGE (new — replaces Steps 3–4 per task)
  ├─ [CRITICAL] finding(s)  → ONE immediate fix dispatch (executor agent),
  │                           re-verify build/lint/test, mark Fixed-on-spot in
  │                           the task-NNN.md Execution Record.
  │                           No re-review, no loop. If a critical persists
  │                           after the one fix → STOP, raise an IMPEDIMENT
  │                           (architecture-conflict) — SKILL.md:305-330.
  └─ [HIGH] finding(s)      → mark Deferred-to-gate in this task's
                              ## Quick Check block (per-task, single-writer);
                              the gate aggregates all Deferred-to-gate rows
                              into delivery-NNN-issues.md in one serial pass.
TASK DONE
  └─ task-NNN.md Execution Record: Status → Done; ## Quick Check block written.
     No grade recorded for the task.
```

The per-task quick check exists to **stop a broken task cascading into its
dependents** (REQUIREMENTS.md FR2) — hence `[CRITICAL]` (breaks the build or
breaks something a dependent task needs) is the only severity worth an on-the-spot
fix; everything else waits for the gate where it can be fixed in batch under a
real grade.

#### Flow B — per-delivery quality gate (new — runs once per delivery)

**Deferral resolved — trigger/location.** The gate is the **closing step of
`aid-execute`**, *not* the opening step of `aid-deploy`. Rationale:

- `aid-execute` already owns the delivery branch, the Execution Graph, and every
  `task-NNN.md` (with its Execution Record zone) — the gate's inputs. `aid-deploy`
  would have to re-load all of it.
- `aid-execute`'s circuit breaker, IMPEDIMENT mechanism, and loopback routing
  (to `aid-specify` / `aid-discover`) already exist for exactly the review → fix
  loop the gate runs; reusing them inside `aid-execute` is zero new machinery.
- `aid-deploy` packages **one or more already-complete deliveries**
  (`aid-deploy/SKILL.md:78-82`). A delivery must be *done* — gate-passed — to be
  eligible. Putting the gate in `aid-deploy` would conflate "finish a delivery"
  with "ship a release". Keeping it in `aid-execute` means a delivery is either
  fully gated or not done — a clean precondition for `aid-deploy`.
- §7 (preserve the methodology): `aid-execute`'s job is "produce a delivery that
  meets the quality bar"; the bar simply moves from per-task to per-delivery,
  staying inside the same phase.

`aid-execute` detects that **every task in the delivery's Execution Graph has
reached `Done`** (not "the last task" by finish order — under FR6 parallel
execution that is a race; the trigger is the deterministic "all-`Done`" predicate
over the graph) and runs the gate. **Which delivery the gate scopes depends on the
path** (decision B):

- **Full path** — the gate scopes the delivery defined in `PLAN.md`; the task set
  and Execution Graph are read from `PLAN.md`. A full work has feature folders and
  per-feature `SPEC.md` files.
- **Lite path** — there is no `PLAN.md` and no feature folder. The gate scopes
  the **single delivery defined in the work-root `SPEC.md`** (`.aid/work-NNN/SPEC.md`),
  the consolidated spec that merges the per-feature spec with the PLAN information
  (delivery, dependency graph, delivery-level acceptance criteria, task list). The
  task set and Execution Graph are read from that work-root `SPEC.md`.

```
DELIVERY-GATE  (closing step of aid-execute, once every task in the delivery is Done)
  0. AGGREGATE  serially read every task-NNN.md ## Quick Check block in the
                delivery and write the deferred [HIGH] rows into a fresh
                delivery-NNN-issues.md (single writer, no race — see Data
                Model "Parallel-write coordination").
  1. SCORE      compute the delivery-complexity score (see Data Model) →
                select gate reviewer tier (Small / Medium / Large).
  2. REVIEW     dispatch the reviewer at the selected tier, clean context.
                Inputs: every artifact the delivery produced, all task-NNN.md
                (Definition + Execution Record zones); the spec —
                feature SPEC(s) on the full path, the work-root SPEC.md on the
                lite path; delivery-NNN-issues.md (the deferred [HIGH]s);
                delivery-level acceptance criteria (PLAN.md full / work-root
                SPEC.md lite); KB via INDEX, grading-rubric.md.
                Reviewer produces ONE fresh severity-tagged issue list — all
                severities, [MINOR]…[CRITICAL] — exactly as the current Step 2.
  3. GRADE      run grade.sh on that issue list (NFR6 — unchanged contract).
  4. ROUTE      grade ≥ Minimum Grade  → gate PASS (go to 6)
                grade <  Minimum Grade → go to 5
  5. FIX        auto-fix CODE issues (current Step 4 logic, SKILL.md:289-300);
                non-CODE issues route to loopback (TASK/SPEC/KB) exactly as
                today (SKILL.md:276-285). → back to step 2 (fresh reviewer).
                Circuit breaker: no improvement across 3 cycles → STOP
                (SKILL.md:302-303 — unchanged).
  6. RECORD     write the ## Delivery Gate block (tier used, final grade, cycle
                count, issue list) into the Execution Record zone of the
                delivery's gate-record task-NNN.md (the Execution-Graph terminal
                node — see Data Model); mark every delivery-NNN-issues.md row
                Resolved/Accepted. Delivery → Done.
```

> **SPEC-loopback target on the lite path.** Step 5's non-CODE routing sends
> SPEC issues to `/aid-specify`. On the full path a SPEC issue loops back through
> the per-feature `SPEC.md`; on the lite path it loops back through the work-root
> `SPEC.md`. The loopback *mechanism* is unchanged — only the file the Q&A is
> written against differs, consistent with decision B's single-spec model.

The gate **is** the current per-task review → fix → review loop, relocated and run
once. Steps 2–5 reuse the existing Step 2 (REVIEW), Step 3 (Present and Route),
and Step 4 (FIX) logic verbatim — including the deterministic grade, the
loop-to-minimum, the loopback routing, and the circuit breaker. The single
behavioural change is *cardinality*: once per delivery instead of once per task.

#### Lite-path deliveries (FR1 interplay — deferral resolved)

FR1's lite path produces **one consolidated `SPEC.md` at the work root**
(`.aid/work-NNN/SPEC.md`) that merges the per-feature spec with the PLAN
information — delivery, dependency graph, delivery-level acceptance criteria, and
task list — plus the `task-NNN.md` files for that single small delivery. A lite
work has **no `PLAN.md` and no feature folder** (REQUIREMENTS.md FR1;
feature-005). FR2's gate keys off "the delivery's task set" and the complexity
score keys off the Execution Graph. **Resolved:**

- The lite path's single small delivery **is one delivery** and gets **exactly one
  per-delivery gate**, identical in mechanism to a full-path delivery's gate.
- The gate's two graph-derived inputs are read from a different file by path —
  not degraded, just relocated: on the full path the **task set** and the
  **Execution Graph** come from `PLAN.md`; on the lite path they come from the
  consolidated work-root `SPEC.md`, which carries exactly that information (the
  dependency graph and task list are part of the merged PLAN content). The gate
  and the complexity score therefore have a complete, structured Execution Graph
  on both paths — there is no reconstruction from scattered `Depends on:` fields.
- The lite path's input contract to `aid-execute` is the work-root `SPEC.md`
  itself (decision B). It carries the **delivery id**, the **task list**, the
  **dependency graph**, and the **delivery-level acceptance criteria** — every
  input FR2's gate needs. FR2 places no dependency on FR1 beyond this single
  consolidated file existing; FR2 does **not** require a `PLAN.md`.
- A lite delivery is small by construction (FR1 eligibility: "a few simple
  tasks"), so its complexity score normally lands in the **Small** band — the gate
  reviewer is cheap, keeping the lite path fast (NFR1) while still enforcing the
  A-grade bar once (NFR6). This is the correct outcome, not a special case.

### Layers & Components

`aid-execute` is a state-machine orchestrator skill (`architecture.md` pattern 1)
that dispatches sub-agents (pattern 2). FR2 touches the **review components only**;
the executor side (Step 1, the Agent Selection table, task-type rules) is
unchanged.

| Layer | Component | Change |
|-------|-----------|--------|
| Orchestration | `aid-execute/SKILL.md` state machine | State machine revised: per-task loop → per-task single quick check; new closing `DELIVERY-GATE` state. See State Machines. |
| Orchestration | dispatch / tier-selection logic in `SKILL.md` | Quick check dispatches `reviewer` pinned to **Small tier** via the Task tool `model` parameter. Gate dispatches `reviewer` at the **score-selected tier**. Both reuse the existing `subagent_type: reviewer` dispatch and the reviewer ≠ executor rule (`SKILL.md:56, 214`). |
| Review | `reviewer` agent (existing, unchanged) | Same agent, same `references/reviewer-guide.md` checklists, same rubric. It is **invoked in two modes** by prompt, not redefined: *quick mode* — "report only [HIGH]/[CRITICAL], one pass, do not grade"; *gate mode* — "full issue list, all severities" (today's behaviour). No new agent file; no change across the 3 install trees beyond the skill body. |
| Review | `grade.sh` + `grading-rubric.md` | **Unchanged.** Runs only at the gate, on the gate reviewer's issue list. NFR6 satisfied by leaving the contract untouched. |
| Data | `task-NNN.md` Execution Record zone (`templates/delivery-plans/task-template.md`) | The Execution Record zone gains the FR2 review shape: `## Quick Check` (replacing the old `## Current Review`), the `## Delivery Gate` block on the delivery's gate-record task (Execution-Graph terminal node — Data Model), and `## Review History` dropped (Data Model). There is **no `task-NNN-STATE.md`** and no `implementation-state.md` template — those are merged away repo-wide. The task template is triplicated — update in all relevant trees per the cross-tree rule. |
| Data | `delivery-NNN-issues.md` (new) | New per-delivery artifact + a new template `templates/delivery-issues.md`. Logged in `data-model.md` KB doc. |
| Data | `DISCOVERY-STATE.md` | Two new config fields: `**Gate Tier Low Threshold:**`, `**Gate Tier High Threshold:**`, set at `/aid-init`. |

**Reviewer ≠ executor invariant (a hard constraint).** Both the quick check and
the gate dispatch `reviewer` with clean context, never the executor agent — the
quick-check critical fix-on-spot is dispatched to the **executor** agent (it is a
fix, not a review), keeping the two roles separate exactly as `SKILL.md:56`
requires.

**Template authorship — feature-002 owns the two-zone `task-NNN.md` (CR7).**
The two-zone `task-NNN.md` template — Definition zone + empty Execution Record
zone scaffold — is **defined and delivered by feature-002**
(`templates/delivery-plans/task-template.md`), which also updates `aid-detail`
to write both zones (Definition filled, Execution Record empty scaffold) and
**deletes** the retired `templates/implementation-state.md`. feature-004 does
**not** create the Execution Record zone — it **writes into the scaffold**
already laid down by `aid-detail`: the per-task quick check writes the
`## Quick Check` block, and the per-delivery gate writes the `## Delivery Gate`
block, both into the Execution Record zone of the relevant `task-NNN.md`. This
closes the previously-open "no feature owns the template" gap: feature-002 owns
authorship; feature-004 owns the FR2 content that lands in the scaffold.

**FR3 thin-router placement.** When `feature-002` refactors `aid-execute` to the
thin-router shape, the FR2 logic lands as: `references/state-quick-check.md`
(per-task quick check + triage), `references/state-delivery-gate.md` (Flow B), and
the complexity-scoring helper as a deterministic `scripts/` script (it is pure
arithmetic over task files). This spec defines
*what* those states do; `feature-002` decides *where* the files sit. The two
features must stay consistent — see Open Question 3.

**`aid-execute/SKILL.md` edit surface for the `task-NNN-STATE.md` retirement.**
Merging `task-NNN-STATE.md` / `implementation-state.md` into the `task-NNN.md`
Execution Record zone is not free — the current `aid-execute/SKILL.md` carries
**16 references** to the retired `task-NNN-STATE.md` artifact (literal
`task-NNN-STATE.md` mentions plus bare `STATE file` / `STATE.md` forms that refer
to it in context), at lines **67, 83, 119, 155, 159, 172, 194, 203, 208, 218,
234, 281, 291, 297, 360, 386** — all of which FR2 must redirect to the
`task-NNN.md` Execution Record zone:

- the `grade.sh` instruction (`SKILL.md:67`) — "recorded in `task-NNN-STATE.md`" →
  recorded in the `task-NNN.md` Execution Record (`## Delivery Gate` block);
- the artifact-tree comment (`SKILL.md:83`) — `task-NNN-STATE.md ← execution state`
  → drop the line; execution state lives in `task-NNN.md`;
- the dependency-status check (`SKILL.md:119`) — "tasks listed in `Depends on:`
  have Status `Done` in their STATE files" → read Status from the dependent
  `task-NNN.md` Execution Record zone;
- the "read state" step (`SKILL.md:155`) — `Read task-NNN-STATE.md if it exists` →
  read the `task-NNN.md` Execution Record zone;
- the state-detection table (`SKILL.md:159`) — `No STATE file exists` → the
  `task-NNN.md` Execution Record `## Status` block is empty / unset;
- the reopen step (`SKILL.md:172`) — `set Status to In Review in STATE.md` →
  update the `task-NNN.md` Execution Record `## Status`;
- the `implementation-state.md` dispatch (`SKILL.md:194`) — `Create task-NNN-STATE.md
  from template templates/implementation-state.md` → **removed**; the Execution
  Record zone is part of the `task-NNN.md` created by `aid-detail` (the empty
  scaffold delivered by **feature-002 / CR7** — see below), so there is no
  separate file to create and `templates/implementation-state.md` is retired
  (deletion owned by feature-002);
- the two `## Dispatches` append rows (`SKILL.md:203, 218`) → append to the
  `task-NNN.md` Execution Record `## Dispatches` block;
- the post-execute Status update (`SKILL.md:208`) — `update STATE.md Status to
  In Review` → update the `task-NNN.md` Execution Record `## Status` to
  `In Review`;
- the REVIEW output update (`SKILL.md:234`) — `Update task-NNN-STATE.md` → update
  the `task-NNN.md` Execution Record (now the `## Quick Check` block, per Data Model);
- the Loopback marking step (`SKILL.md:281`) — `Mark non-CODE issues as Loopback
  in STATE.md` → mark in the `task-NNN.md` Execution Record;
- the FIX-step input read (`SKILL.md:291`) — `Issues from STATE.md where Source
  = CODE and Status = Pending` → read from the `task-NNN.md` Execution Record;
- the FIX-step output (`SKILL.md:297`) — `Mark fixed issues as Fixed in STATE.md`
  → mark in the `task-NNN.md` Execution Record;
- the completion-artifact line (`SKILL.md:360`) — `task-NNN-STATE.md with full
  review history` → the `task-NNN.md` Execution Record `## Quick Check` block (no
  review history; the loop is gone);
- the final-check item (`SKILL.md:386`) — `STATE.md has full review history` →
  drop the "history" wording (no loop, no history): the check becomes "the
  `task-NNN.md` Execution Record `## Quick Check` block is written".

These are part of FR2's edit surface, not a separate cleanup.
`templates/implementation-state.md` is **deleted by feature-002** (CR7) — see
"Template authorship — feature-002 owns the two-zone `task-NNN.md`" below.

**Cross-tree scope.** `aid-execute/SKILL.md` exists in all three install trees
(currently with line-count drift); the `task-NNN-STATE.md` references and the
`implementation-state.md` dispatch above must be retired in **all three** (the
16-place edit is per-tree). Alternatively, if `work-002`'s
`feature-001-profile-driven-generator` has landed first, the edit is applied to
`canonical/skills/aid-execute/` and re-rendered.
Sequencing is `aid-plan`'s call.

### State Machines

#### Revised `aid-execute` per-task state machine

Current (`SKILL.md:19-23`):

```
EXECUTE → REVIEW → [present issues] → FIX → back to REVIEW
                                          → DONE when grade ≥ minimum
```

FR2 per-task:

```
EXECUTE → QUICK-CHECK → TRIAGE ┬─ [CRITICAL] → FIX-ON-SPOT → (re-verify gates) ─┐
                               └─ [HIGH] → log to delivery-issues ─────────────┤
                                                                               ▼
                                                                            TASK-DONE
```

- No loop. `QUICK-CHECK` runs exactly once. `FIX-ON-SPOT` runs at most once
  (criticals only); if a critical survives it → IMPEDIMENT, not another cycle.
- No grade at the task level. `TASK-DONE` is reached regardless of `[HIGH]`
  findings — those are deferred, by design.
- All state — `Status`, the `## Quick Check` block, dispatches — is written to
  the Execution Record zone of `task-NNN.md`; there is no `task-NNN-STATE.md`.

#### New per-delivery gate state machine

Runs as the closing step of `aid-execute` once all of a delivery's tasks are
`Done`:

```
                 ┌──────────────────────────────────────────┐
                 ▼                                          │
SCORE → REVIEW → GRADE → ROUTE ┬─ grade ≥ min ─→ RECORD → DELIVERY-DONE
                               │
                               └─ grade < min ─→ FIX ──────┘
                                                  │
                                  (3 cycles, no improvement)
                                                  ▼
                                              CIRCUIT-BREAKER-STOP
```

- `SCORE` runs once (the tier is fixed for the whole gate — it does not change
  between fix cycles).
- `REVIEW → GRADE → ROUTE → FIX → REVIEW` is the existing per-task loop, verbatim,
  now scoped to the delivery — same `grade.sh`, same Minimum Grade exit, same
  circuit breaker (`SKILL.md:302-303`), same non-CODE loopback routing
  (`SKILL.md:276-285`). The delivery and its task set are read from `PLAN.md` on
  the full path and from the work-root `SPEC.md` on the lite path (decision B).
- `RECORD` writes the `## Delivery Gate` block into the Execution Record zone of
  the delivery's **gate-record `task-NNN.md`** — the Execution-Graph terminal node
  (highest-numbered if several), a deterministic identity under FR6 parallel
  execution (see Data Model) — there is no per-delivery STATE file.
- A delivery is `DELIVERY-DONE` only after a gate `PASS`. This is the precondition
  `aid-deploy` checks (it does not run the gate).

---

## Open Questions

Genuine decision points for the methodology owner — surfaced, not assumed.

- **OQ1 — confirm the "major" → `[HIGH]` severity remap.** FR2's source text says
  "major and critical"; the universal rubric (`templates/grading-rubric.md`) has no
  "Major" tier. This spec maps **"major" = `[HIGH]`** and **"critical" =
  `[CRITICAL]`**, so the quick check surfaces `[HIGH]` + `[CRITICAL]` only (see the
  Severity vocabulary note in Data Model and the Acceptance Criteria note). The
  alternative — adding a "Major" tier to the rubric — would change `grade.sh` and
  the rubric across the whole methodology and is out of FR2's scope. Confirm the
  remap rather than a rubric change.
- **OQ2 — confirm the default `Gate Tier Low/High Threshold` values (6 / 14).** The
  complexity-score thresholds that pick the gate reviewer tier are stored as
  `DISCOVERY-STATE.md` config (defaulted at `/aid-init`), consistent with how
  `Minimum Grade` is handled. The defaults (`≤6` → Small, `≥14` → Large) are a
  first estimate; the owner may want different bands. The mechanism is settled — only
  the default numbers are open.
- **OQ3 — confirm FR2 ↔ FR3 (`feature-002`) consistency on state-file placement.**
  This spec defines *what* the FR2 states (`quick-check`, `delivery-gate`) and the
  complexity-scoring helper do; `feature-002`'s thin-router refactor decides *where*
  the files sit (`references/state-quick-check.md`, `references/state-delivery-gate.md`,
  a `scripts/` scoring helper). The two features must land a consistent file layout —
  `aid-plan` sequences them so the contract is agreed before either is built.
