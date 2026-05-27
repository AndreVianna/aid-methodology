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
     `writeback-task-status.sh --delivery-id NNN --append-issue ROW`):
     read the file; it already contains all deferred `[HIGH]` rows.
   - If it does not exist: no deferred `[HIGH]` issues were logged
     (all quick checks reported clean or only `[CRITICAL]` fixed on spot).
     Create an empty log via:

     ```bash
     writeback-task-status.sh --delivery-id NNN --append-issue \
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

**Advance:** Proceed to Step 1 (SCORE).

---

## Step 1: SCORE (Complexity → Reviewer Tier)

Compute the delivery-complexity score to select the gate reviewer's tier.
This runs **once** — the tier is fixed for the entire gate (all fix cycles use
the same tier reviewer).

### Complexity Score Computation

Read the delivery's Execution Graph from:
- **Full path** — `PLAN.md` in the work directory (`#### Execution Graph` block
  for this delivery).
- **Lite path** — the work-root `SPEC.md` (`.aid/{work}/SPEC.md`), which
  contains the merged delivery + dependency graph information.

Parse the `| Task | Depends On |` table to build the dependency map.

**Score components (sum all):**

| Factor | Source | Contribution |
|--------|--------|--------------|
| Task count | tasks in this delivery (Execution Graph) | +1 per task |
| Graph depth | longest dependency chain (longest path in DAG) | +1 per edge on the longest chain |
| Risk-weighted types | each task's `Type` field (`task-NNN.md`) | `MIGRATE`/`REFACTOR` +2; `IMPLEMENT`/`TEST` +1; `RESEARCH`/`DESIGN`/`DOCUMENT`/`CONFIGURE` +0 |
| Specialist consults | count of: quick-check `[CRITICAL]` fix-on-spot events (from `## Quick Check Findings`) + tasks whose Agent-Selection row triggers a `security` or `performance` consult | +1 each |

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

**Advance:** Proceed to Step 2 (REVIEW).

---

## Step 2: REVIEW (Gate Reviewer — Fresh Issue List)

Dispatch the `reviewer` agent at the **score-selected tier** (Small / Medium /
Large). Clean context — reviewer must NOT inherit any executor working notes.

**Before dispatching, print:**
`[DELIVERY-GATE Step 2] Dispatching reviewer (gate, {tier} tier) → subagent_type=reviewer`

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

Then append the gate-specific prompt below. The reviewer reads directly from source:

- **All delivery artifacts** — every file produced or modified by tasks in the
  delivery (code, docs, configs, tests, etc.)
- **All `task-NNN.md` files** for this delivery — Definition zones (Type,
  Source, Scope, Acceptance Criteria)
- **Feature SPEC(s):**
  - Full path: per-feature `SPEC.md` files (`.aid/{work}/features/*/SPEC.md`)
  - Lite path: work-root `SPEC.md` (`.aid/{work}/SPEC.md`)
- **Delivery-level acceptance criteria:**
  - Full path: from `PLAN.md` (the delivery's acceptance criteria block)
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

▶ reviewer (gate, {tier}) starting (~{ETA from rough-time-hints})
✓ reviewer (gate) done (record actual time) — or ✗ gate reviewer failed: {reason}

**Advance:** Proceed to Step 3 (GRADE).

---

## Step 3: GRADE (Deterministic Grade Computation)

Run `grade.sh` on the gate reviewer's issue list.

```bash
grade.sh --explain <gate-reviewer-issue-list-file>
```

Or pipe the reviewer's output:

```bash
echo "<reviewer-output>" | grade.sh --explain
```

The script prints a grade letter (`A+`, `A`, `A-`, `B+`, …, `F`). The
`--explain` flag prints the count breakdown to stderr.

**Record the grade** in the work `STATE.md` `## Delivery Gates` section
(partial write — will be completed by RECORD step on PASS):

```
[DELIVERY-GATE Step 3: GRADE]
Gate grade: {grade}   Minimum: {min}   Cycle: {N}
```

**Advance:** Proceed to Step 4 (ROUTE).

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
- **SPEC** → Write Q&A to `.aid/{work}/STATE.md` `## Cross-phase Q&A` →
  suggest `/aid-specify`
- **KB** → Write Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)` →
  suggest `/aid-discover`

**If ONLY non-CODE issues remain:** **STOP.** The delivery is as good as it
can be — the problem is upstream. Present what needs to change and where.

**Advance:** → Step 5 (FIX) when grade < minimum; → Step 6 (RECORD) when
grade ≥ minimum.

---

## Step 5: FIX (Fix CODE Issues, Loop Back to REVIEW)

Auto-fix all CODE issues from the gate reviewer's current issue list.

Dispatch the **executor agent** (same agent type that executed the tasks —
determined from the delivery's task types; if mixed, use `developer` as the
default multi-type executor). Do NOT dispatch the reviewer — reviewer ≠
executor invariant applies here too.

**Executor fixes CODE issues only.** Non-CODE issues (TASK, SPEC, KB) were
surfaced to the user in Step 4 and do not reach this step.

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

Write impediment to `.aid/{work}/IMPEDIMENT-delivery-NNN.md` if stopping.

**Advance:** → back to Step 2 (REVIEW) — fresh reviewer, clean context.

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

### 6b: Write to `## Delivery Gates` in Work STATE.md

Use the writeback helper:

```bash
writeback-task-status.sh --delivery-id NNN --block "BLOCK"
```

> **Helper target:** `writeback-task-status.sh --delivery-id NNN --block BLOCK`
> writes the `### delivery-NNN` block under `## Delivery Gates` in the work
> `STATE.md`. Task files are not modified. This is the canonical write target
> per feature-004 Alignment Update and SPEC L240-260.

### 6c: Mark Deferred Issues Resolved/Accepted

For each row in `delivery-NNN-issues.md`:
- If the gate reviewer's issue list contains a matching issue that was fixed
  in the fix cycles → mark the row `Resolved`.
- If the issue is still present but the gate grade cleared the minimum
  (accepted at this grade level) → mark the row `Accepted`.

Update the file directly (no helper needed — single writer by construction).

### 6d: Update Delivery Row in STATE.md

Update the `## Plan / Deliveries` row for this delivery:

```bash
writeback-task-status.sh --task-id NNN --field Status --value "Done"
```

_(Uses the delivery's gate-record task id to mark the delivery row done.)_

### 6e: Emit DELIVERY-DONE

```
[DELIVERY-GATE] Gate PASS — delivery-NNN is Done.
Grade: {grade}  Cycles: {N}  Tier: {tier}

✅ Delivery complete. Branch aid/delivery-NNN is ready for /aid-deploy.
```

Print the final delivery snapshot:

```
delivery-NNN  ·  {N} tasks  ·  gate grade {grade}  ·  Done at {timestamp}

| Task | Type | Status | Quick-Check | Notes |
|------|------|--------|-------------|-------|
| task-NNN | IMPLEMENT | Done | [HIGH] × 1 (Resolved) | — |
| task-NNN | TEST | Done | none | — |
```

**Advance:** → halt (DELIVERY-GATE is the terminal state for a delivery).

---

## Unit Tests for the AGGREGATE + Grade + Loopback Logic

These tests verify the delivery-gate logic in isolation, without dispatching
actual reviewer sub-agents. They use the `writeback-task-status.sh` helper
with test fixtures.

Test harness: `tests/canonical/delivery-gate-aggregate.sh`

See that file for the 6 test scenarios covering:
1. AGGREGATE with existing `delivery-NNN-issues.md` (rows preserved)
2. AGGREGATE with no issues file (creates clean log)
3. SCORE computation for 3 sample deliveries of varying complexity
4. Grade computation via grade.sh (deterministic output)
5. Loopback (grade < min → fix cycle → re-review, no quick-check re-run)
6. FR6 interlock (gate does not fire when any task is Failed/Blocked)
