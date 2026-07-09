# State: DELIVERY-GATE

Per-delivery quality gate — runs **once per delivery** as the closing step of
`aid-execute`, triggered from pool dispatch PD-5 after all tasks reach `Done`.
Implements Flow B from the feature-004 two-tier review SPEC.

**FR6 interlock:** this state MUST NOT run while any task in the delivery has
status `Failed` or `Blocked`. PD-5 Case B handles that guard; when this state
file is entered, the guard has already passed (all tasks are `Done`).

## State Entry Trigger

Entered from pool dispatch **PD-5 Case A** (all tasks `Done`, no failures):

```
[State: DELIVERY-GATE] — Per-delivery quality gate running.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [✓ REVIEW ] → [✓ FIX ] → [✓ DONE ] → [● DELIVERY-GATE ]
```

Print this state-entry banner before proceeding to Step 0.

Advance delivery lifecycle to Gated (silent state-write -- no output, no gate):
```bash
bash canonical/scripts/execute/writeback-state.sh --delivery-id NNN --lifecycle Gated
```

## DELIVERY-GATE State Machine

```
                 ┌──────────────────────────────────────────┐
                 ▼                                          │
AGGREGATE → SCORE → REVIEW → GRADE → ROUTE ─── grade ≥ min ──→ RECORD → DELIVERY-DONE
                                           │
                                           └── grade < min ──→ FIX ──────┘
                                                              │
                                             (3 cycles, no improvement)
                                                              ▼
                                                     CIRCUIT-BREAKER-STOP
```

- AGGREGATE and SCORE run **once** (before the review loop begins).
- REVIEW → GRADE → ROUTE → FIX → REVIEW is the review loop (same mechanics as
  the per-task review loop — reuses grade.sh, Minimum Grade exit, circuit
  breaker, and non-CODE loopback routing).
- RECORD runs once on gate PASS.

---

## Step 0: AGGREGATE (Collect Deferred Issues)

Collect every deferred `[HIGH]` issue logged by per-task quick checks across
the delivery, aggregate into `delivery-NNN-issues.md`, then update its rows.

**This step runs serially (single writer) — no concurrent write race (FR6 note
from SPEC Data Model "Parallel-write coordination").**

1. **Locate the delivery id** from the delivery's Source field
   (e.g., `delivery-003` → NNN = `003`).

2. **Check whether `delivery-NNN-issues.md` exists** at
   `.aid/{work}/delivery-NNN-issues.md`.
   - If it exists (written incrementally by quick-check via
     `writeback-state.sh --delivery-id NNN --append-issue ROW`):
     read the file; it already contains all deferred `[HIGH]` rows.
   - If it does not exist: no deferred `[HIGH]` issues were logged
     (all quick checks reported clean or only `[CRITICAL]` fixed on spot).
     Create an empty log via:

     ```bash
     writeback-state.sh --delivery-id NNN --append-issue \
       "| (none) | — | No deferred [HIGH] issues from quick checks | Resolved |"
     ```

     This ensures the file exists for the reviewer as prior context.

3. **Print AGGREGATE summary:**

   ```
   [DELIVERY-GATE Step 0: AGGREGATE]
   Delivery: delivery-NNN
   Deferred [HIGH] issues found: {count from delivery-NNN-issues.md}
   ```

   List each row from the file (task-id / description / status) for the user.

**Advance:** **CHAIN** → Step 1 (SCORE).

---

## Step 1: SCORE (Complexity → Reviewer Tier)

Compute the delivery-complexity score to select the gate reviewer's tier.
This runs **once** — the tier is fixed for the entire gate (all fix cycles use
the same tier reviewer).

### Complexity Score Computation

Read the delivery's Execution Graph from:
- **Flat path (feature-001, single-delivery)** — detected by: a work-root
  `BLUEPRINT.md` present AND `tasks/task-NNN/DETAIL.md` present directly
  under the work root AND no `deliveries/` wrapper under it → the top-level
  `## Execution Graph` in the work-root `PLAN.md` (no
  `### delivery-NNN` heading; the single delivery is implicit).
- **Full path** — otherwise, `PLAN.md` in the work directory (`#### Execution
  Graph` block for this delivery).
- **Lite path** — the work-root `SPEC.md` (`.aid/{work}/SPEC.md`), which
  contains the merged delivery + dependency graph information.

Parse the `| Task | Depends On |` table to build the dependency map.

**Score components (sum all):**

| Factor | Source | Contribution |
|--------|--------|--------------|
| Task count | tasks in this delivery (Execution Graph) | +1 per task |
| Graph depth | longest dependency chain (longest path in DAG) | +1 per edge on the longest chain |
| Risk-weighted types | each task's `Type` field (`deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; flat path: `tasks/task-NNN/DETAIL.md` directly under the work root) | `MIGRATE`/`REFACTOR` +2; `IMPLEMENT`/`TEST` +1; `RESEARCH`/`DESIGN`/`DOCUMENT`/`CONFIGURE` +0 |
| Specialist consults | count of: quick-check `[CRITICAL]` fix-on-spot events (from `## Quick Check Findings`) + tasks whose Agent-Selection row triggers an `aid-researcher` analysis consult | +1 each |

### Tier Selection

Read thresholds from `.aid/knowledge/STATE.md` (fields set at `/aid-config`):
- `**Gate Tier Low Threshold:**` (default `6` if absent)
- `**Gate Tier High Threshold:**` (default `14` if absent)

| Complexity score | Gate reviewer tier |
|------------------|--------------------|
| score ≤ Low Threshold | Small (cheap) |
| Low Threshold < score < High Threshold | Medium |
| score ≥ High Threshold | Large |

**Print SCORE result:**

```
[DELIVERY-GATE Step 1: SCORE]
Complexity score: {N}  (tasks={T}, depth={D}, risk={R}, consults={C})
Gate reviewer tier: {Small | Medium | Large}
```

**Advance:** **CHAIN** → Step 2 (REVIEW).

---

## Step 2: REVIEW (Gate Reviewer — Fresh Issue List)

Dispatch the `aid-reviewer` agent at the **score-selected tier** (Small / Medium /
Large). Clean context — reviewer must NOT inherit any executor working notes.

**Before dispatching, print:**
`[DELIVERY-GATE Step 2] Dispatching aid-reviewer (gate, {tier} tier) → subagent_type=aid-reviewer`

Dispatch metadata is logged via the Calibration Log appendix in the work
`STATE.md` (per work-003 traceability rule — never optional).

Follow the Dispatch Protocol (L1+L2+L3 subagent visibility) from `SKILL.md`:
arm 3 L2 timers; pre-create heartbeat file; include `HEARTBEAT_FILE` +
`HEARTBEAT_INTERVAL` in prompt.

### Gate Reviewer Inputs

The gate reviewer receives a **fresh, clean-context package** — not a summary
of per-task reviews. The package wrapper is the universal brief at
`references/reviewer-brief.md` rendered with:
- `{{MODE}}` = `per-delivery`
- `{{ARTIFACTS}}` = the full delivery branch diff + every task's STATE.md row + the PLAN.md delivery section
- `{{CONTEXT}}` = `delivery-NNN aggregates tasks {NNN..MMM}; this is the post-execution quality gate before merge to main.`

Include in the prompt:
- **Ledger lifecycle:** "Read the existing `.aid/.temp/review-pending/execute-delivery-NNN.md`
  if it exists. For each existing row: verify on disk, update Status if needed
  (Pending→Fixed if resolved; Fixed→Recurred if regressed). Append new findings
  as rows with Status: Pending."
- **Schema reference:** "Output per `canonical/templates/reviewer-ledger-schema.md`.
  The ledger is the entire file — ONE markdown table, no headers, no narrative."

Then append the gate-specific prompt below. The reviewer reads directly from source:

- **All delivery artifacts** — every file produced or modified by tasks in the
  delivery (code, docs, configs, tests, etc.)
- **All task DETAIL.md files** for this delivery — Definition zones (Type,
  Source, Scope, Acceptance Criteria):
  - Full path: `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`
  - Flat path: `tasks/task-NNN/DETAIL.md` directly under the work root
- **Feature SPEC(s):**
  - Full path: per-feature `SPEC.md` files (`.aid/{work}/features/*/SPEC.md`)
  - Flat path (feature-001, single-delivery): work-root `SPEC.md` (single feature)
  - Lite path: work-root `SPEC.md` (`.aid/{work}/SPEC.md`)
- **Delivery-level acceptance criteria:**
  - Full path: from the delivery's `BLUEPRINT.md § Gate Criteria`
  - Flat path: from the work-root `BLUEPRINT.md § Gate Criteria`
  - Lite path: from work-root `SPEC.md`
- **`delivery-NNN-issues.md`** — the deferred `[HIGH]` prior context (from
  AGGREGATE). Read as context only; the reviewer produces its own fresh list.
- **KB docs via INDEX.md** — load relevant docs per INDEX summaries
- **Grading rubric** (`../../../templates/grading-rubric.md`)

### Gate Reviewer Prompt (gate mode)

> You are running a **delivery-level quality gate review** (not a per-task
> quick check). This is a full review pass across the entire delivery.
>
> Your job:
> 1. Review ALL delivery artifacts against the delivery-level acceptance
>    criteria and each task's acceptance criteria.
> 2. Check **cross-task coherence** — do the task outputs fit together?
>    Are there integration gaps, naming inconsistencies, or missing glue?
> 3. Review the deferred `[HIGH]` issues in `delivery-NNN-issues.md` — are
>    they still present? Have they been addressed as a side effect of other
>    work, or do they require explicit attention?
> 4. Produce ONE fresh severity-tagged issue list — ALL severities
>    `[MINOR]`…`[CRITICAL]` — for ALL issues found, including unresolved
>    deferred-`[HIGH]`s from prior quick checks.
>
> Use the grading rubric severity tags exactly: `[CRITICAL]`, `[HIGH]`,
> `[MEDIUM]`, `[LOW]`, `[MINOR]`.
>
> Do NOT inherit grades from per-task reviews. Do NOT grade. Grade computation
> is done separately by `grade.sh` on your issue list.
>
> **Reviewer ≠ executor invariant:** you are a reviewer. You do NOT fix
> anything. Only list issues.

▶ aid-reviewer (gate, {tier}) starting (~{ETA from rough-time-hints})
✓ aid-reviewer (gate) done (record actual time) — or ✗ gate reviewer failed: {reason}

**Advance:** **CHAIN** → Step 3 (GRADE).

---

## Step 3: GRADE (Deterministic Grade Computation)

Run `grade.sh` on the ledger file:

```bash
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/execute-delivery-NNN.md
```

The script parses the Severity and Status columns from the markdown table, counts
findings where Status ∈ {Pending, Recurred}, and prints a grade letter
(`A+`, `A`, `A-`, `B+`, …, `F`). The `--explain` flag prints the count
breakdown to stderr.

**Record the grade** in the work `STATE.md` `## Delivery Gates` section
(partial write — will be completed by RECORD step on PASS):

```
[DELIVERY-GATE Step 3: GRADE]
Gate grade: {grade}   Minimum: {min}   Cycle: {N}
```

**Advance:** **CHAIN** → Step 4 (ROUTE).

---

## Step 4: ROUTE (Pass or Fix)

| Condition | Action |
|-----------|--------|
| Grade ≥ Minimum Grade | Gate PASS → proceed to Step 6 (RECORD) |
| Grade < Minimum Grade | → proceed to Step 5 (FIX) |

**Present all issues to the user:**

```
[DELIVERY-GATE — Cycle {N} — Grade: {grade} — Minimum: {min}]

Gate reviewer issue list:

| # | Severity | Source | Description |
|---|----------|--------|-------------|
| 1 | [HIGH]   | CODE   | ... |
| 2 | [MEDIUM] | TASK   | ... |

Deferred [HIGH]s from quick checks (from delivery-NNN-issues.md):
| Source task | Severity | Description | Status |
| task-NNN    | [HIGH]   | ...         | Open   |

{If grade ≥ minimum:}
✅ Gate PASS. Grade meets minimum. Proceeding to RECORD.

{If grade < minimum:}
Gate grade below minimum. Next steps:
- CODE issues (#1, #3): I'll fix these automatically.
- TASK issues (#2): Task spec update needed. {explain}
- SPEC issues: Would require re-running /aid-specify.
- KB issues: Would require re-running /aid-discover.
```

**Non-CODE issues (TASK, SPEC, KB):**
- **TASK** → Present to user with suggestion. User updates task, re-run.
- **SPEC** → Write Q&A to `deliveries/delivery-NNN/STATE.md` `## Cross-phase Q&A` (SD-5:
  the delivery gate writes to its OWN delivery STATE.md, not the shared work STATE.md,
  to preserve the disjoint-write property -- two delivery branches cannot collide) →
  suggest `/aid-specify`
- **KB** → Write Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)` →
  suggest `/aid-discover`

**If ONLY non-CODE issues remain:** **STOP.** The delivery is as good as it
can be -- the problem is upstream. Present what needs to change and where.
Emit delivery and pipeline pause signals (silent state-writes -- no output, no gate):
```bash
bash canonical/scripts/execute/writeback-state.sh --delivery-id NNN --lifecycle Blocked
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
bash canonical/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "Delivery gate blocked on non-CODE issues -- upstream fix required (SPEC/TASK/KB)"
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **CHAIN** → Step 5 (FIX) when grade < minimum; **CHAIN** → Step 6 (RECORD) when grade ≥ minimum.

---

## Step 5: FIX (Fix CODE Issues, Loop Back to REVIEW)

Read `.aid/.temp/review-pending/execute-delivery-NNN.md`. Pass the Pending and
Recurred rows to the executor agent — cite row numbers in fix commit messages
(e.g., "fix row #2 (HIGH: missing null check)").

Auto-fix all CODE issues. Dispatch the **executor agent** (same agent type that executed
the tasks — if mixed, use `aid-developer` as the default). Do NOT dispatch the reviewer —
reviewer ≠ executor invariant applies here too.

**Executor fixes CODE issues only.** Non-CODE issues (TASK, SPEC, KB) were
surfaced to the user in Step 4 and do not reach this step.

**Do NOT modify the ledger during FIX.** Status updates happen in the next REVIEW cycle
when the reviewer re-verifies.

After the executor reports done:
1. Re-verify build/lint/test gates pass (as applicable to the delivery's
   task types).
2. Increment cycle counter.

**Circuit breaker:** if the grade has not improved after **3 consecutive
cycles** (same grade or worse), **STOP.**

```
[DELIVERY-GATE] Circuit breaker triggered — grade has not improved after
3 cycles ({grade-history}). Something systemic is wrong.

Please inspect the delivery artifacts and the gate reviewer's issue list.
Options:
1. Resolve the root cause manually, then re-invoke /aid-execute to re-run
   the gate from AGGREGATE.
2. Raise an IMPEDIMENT (architecture-conflict) if the issue is structural.
```

Write impediment to `.aid/{work}/IMPEDIMENT-delivery-NNN.md` if stopping. When the impediment
is written, emit the delivery and pipeline block signals (silent state-writes -- no output, no gate):
```bash
bash canonical/scripts/execute/writeback-state.sh --delivery-id NNN --lifecycle Blocked
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Blocked
bash canonical/scripts/execute/writeback-state.sh --pipeline --field "Block Reason" --value "Delivery gate circuit breaker triggered -- grade not improving after 3 cycles"
bash canonical/scripts/execute/writeback-state.sh --pipeline --field "Block Artifact" --value ".aid/{work}/IMPEDIMENT-delivery-{NNN}.md"
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **CHAIN** → back to Step 2 (REVIEW) — fresh reviewer, clean context.

---

## Step 6: RECORD (Write Gate Outcome to STATE.md)

Gate has PASSED (grade ≥ minimum). Write the gate record and mark the
delivery Done.

### 6a: Build the Delivery Gate Block

Compose the final gate block:

```markdown
- **Reviewer Tier:** {Small | Medium | Large}
- **Complexity Score:** {N}
- **Grade:** {grade}
- **Cycles:** {N}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}
- **Issue List:**
  {gate reviewer's issue list, all severities, or "none" if A+}
```

### 6b: Write to `## Delivery Gate` in Delivery STATE.md

Use the writeback helper:

```bash
writeback-state.sh --delivery-id NNN --block "BLOCK"
```

> **Helper target:** `writeback-state.sh --delivery-id NNN --block BLOCK`
> writes the `## Delivery Gate` block in `deliveries/delivery-NNN/STATE.md` (SD-5:
> the delivery gate block is authored by this delivery's branch only; it is NOT
> written into the shared work STATE.md). The work-level `## Delivery Gates`
> view is DERIVED at read time as the union of all delivery gate blocks.
>
> **Flat path (feature-001, single-delivery):** with a work-root `BLUEPRINT.md`
> present and no `deliveries/` wrapper (`--delivery-id 001`), the SAME helper
> call instead writes the singular
> AUTHORED `## Delivery Gate` block directly into the work-root `STATE.md`
> (there is exactly one delivery, so the disjoint-write concern above does not
> apply — see `writeback-state.sh`). This is distinct from the plural DERIVED
> `## Delivery Gates` view (different heading, singular vs. plural).

### 6b-2: Advance delivery lifecycle to Done

```bash
bash canonical/scripts/execute/writeback-state.sh --delivery-id NNN --lifecycle Done
```

### 6c: Mark Deferred Issues Resolved/Accepted

For each row in `delivery-NNN-issues.md`:
- If the gate reviewer's issue list contains a matching issue that was fixed
  in the fix cycles → mark the row `Resolved`.
- If the issue is still present but the gate grade cleared the minimum
  (accepted at this grade level) → mark the row `Accepted`.

Update the file directly (no helper needed — single writer by construction).

### 6d: Update Delivery Row in Work STATE.md

The work-level `## Plan / Deliveries` derived view is computed at read time from
the per-delivery `## Delivery Lifecycle` State values. Since we already advanced the
delivery lifecycle to Done in step 6b-2, the dashboard reader will reflect `Done`
in the work-level view automatically. No additional writeback is needed here.

_(Previously this step wrote a "Status: Done" row to the work STATE.md; under the
hierarchical layout, the delivery's lifecycle State is the authoritative source.)_

### 6e: Delete Ledger

```bash
rm -f .aid/.temp/review-pending/execute-delivery-NNN.md
rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
```

### 6f: Emit DELIVERY-DONE

```
[DELIVERY-GATE] Gate PASS — delivery-NNN is Done.
Grade: {grade}  Cycles: {N}  Tier: {tier}

✅ Delivery complete. Branch aid/{work}-delivery-NNN is Done.
Optional next steps (independent, not required, not sequential): /aid-deploy, /aid-monitor.

If this work has forward-authored seed docs (a KB doc with `source: forward-authored` in its
frontmatter), consider running `/aid-housekeep` to surface any divergence between the
as-built code and the original design.  This is a discoverability pointer only -- it is NOT
a required gate step and does NOT affect this delivery's grade.
```

Print the final delivery snapshot:

```
delivery-NNN  ·  {N} tasks  ·  gate grade {grade}  ·  Done at {timestamp}

| Task | Type | State | Quick-Check | Notes |
|------|------|-------|-------------|-------|
| task-NNN | IMPLEMENT | Done | [HIGH] × 1 (Resolved) | — |
| task-NNN | TEST | Done | none | — |
```

**Advance:** **HALT** (DELIVERY-GATE is the terminal state for a delivery).

---

## Unit Tests for the AGGREGATE + Grade + Loopback Logic

These tests verify the delivery-gate logic in isolation, without dispatching
actual reviewer sub-agents. They use the `writeback-state.sh` helper
with test fixtures.

Test harness: `tests/canonical/test-delivery-gate-aggregate.sh`

See that file for the 6 test scenarios covering:
1. AGGREGATE with existing `delivery-NNN-issues.md` (rows preserved)
2. AGGREGATE with no issues file (creates clean log)
3. SCORE computation for 3 sample deliveries of varying complexity
4. Grade computation via grade.sh (deterministic output)
5. Loopback (grade < min → fix cycle → re-review, no quick-check re-run)
6. FR6 interlock (gate does not fire when any task is Failed/Blocked)
