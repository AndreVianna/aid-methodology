# State: REVIEW

Task output is graded by a lightweight quick-check pass first; then a clean-context reviewer agent produces the full grade. Routing to FIX or DONE follows from the computed grade.

> **Two-tier review model (feature-004):** Per-task REVIEW (this state) runs the
> quick-check + full reviewer loop for an individual task. The **per-delivery
> quality gate** runs once for the whole delivery after all tasks are `Done` —
> that is a separate state; see `references/state-delivery-gate.md`. The gate
> is triggered from pool dispatch PD-5 (in `references/state-execute.md`), not
> from this per-task state.

> ⚠️ **MANDATORY State-Write Protocol applies in this state too:** this task's
> `State` MUST be written the moment it changes -- to `Failed` if a
> `[CRITICAL]` finding persists after fix-on-spot (below), and to `Done` at
> this state's terminal chain. See `references/state-execute.md § MANDATORY:
> State-Write Protocol` for the full mandate -- it binds whoever is running
> this state, main/orchestrator agent or dispatched sub-agent, no exceptions.

## Step 1.5: QUICK CHECK (Pre-Reviewer Triage)

A lightweight single-pass reviewer runs **before** the full reviewer to catch
obvious `[CRITICAL]` and `[HIGH]` issues early. No grade is computed, no loop
runs — this is a fast filter only.

**Before dispatching, print:** `[Step 1.5] Dispatching aid-reviewer (quick-check, Small tier) for quick-check → subagent_type=aid-reviewer`.

Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule).

### Quick-Check Dispatch

Dispatch the `aid-reviewer` agent with `subagent_type: aid-reviewer` at **Small tier**
(cheap, fast).

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{MODE}}` = `per-task`
- `{{ARTIFACTS}}` = the files/artifacts the executor produced in Step 1
- `{{CONTEXT}}` = `task-NNN of type {Type} produced these artifacts; AC list lives in task-NNN.md.`

Then append the quick-check-specific prompt below.

The brief carries the universal rubric pointer (`.codex/aid/templates/grading-rubric.md`)
and the OOS policy. Pass the rendered brief + the quick-check prompt as a single
dispatch.

**Reviewer prompt (quick-check mode):**

> You are running a quick-check pass (not a full review). Report ONLY
> `[CRITICAL]` and `[HIGH]` findings — issues at `[MEDIUM]`, `[LOW]`, and
> `[MINOR]` severity are intentionally out of scope for this pass and must NOT
> be reported. Output a plain list of findings tagged with `[CRITICAL]` or
> `[HIGH]` per the rubric. Do NOT compute a grade; do NOT iterate.
>
> Severity vocabulary: "critical" = `[CRITICAL]` (system failure, data loss,
> security breach, fundamentally wrong); "major" = `[HIGH]` (blocks
> functionality, security risk, data integrity concern).

▶ aid-reviewer (quick-check) starting (~1 min)
✓ aid-reviewer (quick-check) done (record actual time) — or ✗ quick-check failed: {reason}

### Quick-Check Triage (Severity Routing)

After the quick-check reviewer responds, triage findings by severity:

| Finding type | Action |
|---|---|
| `[CRITICAL]` found | Fix inline immediately (see § CRITICAL Fix-on-Spot below) |
| `[HIGH]` found | Mark `Deferred-to-gate` and write to delivery issues file (see § HIGH Deferral below) |
| No `[CRITICAL]` or `[HIGH]` | Continue to Step 2 (full reviewer) |

#### CRITICAL Fix-on-Spot

For each `[CRITICAL]` finding:

1. Apply **one immediate fix** using the same executor agent type as Step 1
   (do not dispatch the reviewer — the reviewer ≠ executor invariant is preserved).
   Print: `[Quick-Check] CRITICAL found — applying fix-on-spot: {description}`.
2. Re-verify build/lint/test gates after the fix.
3. If the critical persists after the fix → **STOP.** Raise an IMPEDIMENT
   (`type: architecture-conflict`). Do not attempt a second fix cycle.
   **MANDATORY (State-Write Protocol, `state-execute.md`) — update this
   task's own State to `Failed` before or alongside the pipeline block
   signal below** (the task must not be left showing `In Progress`/`In
   Review` while blocked on an unresolved impediment):
   ```bash
   bash .codex/aid/scripts/execute/writeback-state.sh --delivery-id DDD --task-id NNN --field State --value "Failed"
   ```
   Write the IMPEDIMENT to `.aid/works/{work}/IMPEDIMENT-task-{NNN}.md` and emit the pipeline block
   signal (silent state-write — no output, no gate):
   ```bash
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Blocked
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Block Reason" --value "Critical finding persists after fix attempt — architecture-conflict impediment raised"
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Block Artifact" --value ".aid/works/{work}/IMPEDIMENT-task-{NNN}.md"
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```
4. Mark the finding as `Fixed-on-spot` in the quick-check findings block (see §
   Write Findings to STATE.md below).

Only one fix attempt per critical finding. There is no loop here.

#### HIGH Deferral

For each `[HIGH]` finding:

1. Mark the finding as `Deferred-to-gate` in the quick-check findings block.
2. Write a deferred-issue row to the delivery's issue log using
   `writeback-state.sh --delivery-id NNN --append-issue ROW` where `ROW`
   is a pipe-delimited markdown table row:

   ```
   | task-NNN | [HIGH] | {one-line description} | Open |
   ```

   The delivery issue log is at `.aid/works/work-NNN/delivery-NNN-issues.md`. The
   script creates the file (from the `delivery-issues.md` template) if it does
   not yet exist.

3. Continue to Step 2 — `[HIGH]` findings do **not** block the full reviewer
   dispatch. They are deferred to the per-delivery gate.

### Write Findings to STATE.md

After triage, write the quick-check findings block to the work `STATE.md`
`## Quick Check Findings` section via the helper:

```bash
writeback-state.sh --task-id NNN --findings "BLOCK"
```

Where `BLOCK` is the findings text in this format:

```
- **Reviewer Tier:** Small
- **Findings:**
  - [CRITICAL] {description} — {source-file:line if known} — Fixed-on-spot
  - [HIGH] {description} — {source-file:line if known} — Deferred-to-gate
```

If there are no `[CRITICAL]` or `[HIGH]` findings, write:

```
- **Reviewer Tier:** Small
- **Findings:** none
```

The helper writes/replaces the `### task-NNN` block under `## Quick Check
Findings` in the work `STATE.md` (keyed by task-id, single-writer per task
by construction — safe under FR6 parallel execution).

### MANDATORY Terminal Write: Task State → Done

Per `references/state-execute.md § MANDATORY: State-Write Protocol` — this is
the task's own terminal state write for a **single-task invocation** (whether
run directly by the main/orchestrator agent or by a sub-agent running its own
per-task pipeline under pool dispatch, per `state-execute.md`'s `PD-2a`
prompt template). It happens HERE, the moment REVIEW's quick-check triage
completes — not deferred, not left for whatever process happens to touch
this task next:

```bash
bash .codex/aid/scripts/execute/writeback-state.sh \
    --delivery-id DDD --task-id NNN --field State --value "Done"
```

This write is also what makes `SKILL.md § Check 2b` (dependency-readiness)
and pool dispatch's own ready-set computation (`PD-1`/`PD-4` step 3 in
`state-execute.md`) see this task as unblocking its dependents — without it,
a task that finished its own work would never actually register as `Done`
anywhere the rest of the pipeline reads from. (Under pool dispatch, PD-4
step 2 in `state-execute.md` ALSO writes `Done` for this task from the
orchestrator side after the sub-agent reports back — that is a second,
redundant, idempotent write, not a substitute for this one; the sub-agent
must not skip its own write on the assumption "the orchestrator will do it.")

**Advance:** **CHAIN** → [State: DONE] after triage, findings write, and the terminal State write above (continue inline).

> **Two-tier model contract (feature-004 SPEC §State Machines):** Per-task REVIEW
> runs the quick-check pass only. **No grade is computed at the task level.**
> `TASK-DONE` is reached regardless of `[HIGH]` findings — those findings are
> deferred to the per-delivery quality gate via `--append-issue` (above). The
> per-delivery gate (`references/state-delivery-gate.md`) is the layer that
> dispatches the full reviewer, computes the grade via `grade.sh`, and runs
> the FIX loop. This separation is the entire point of FR2.
>
> The historical per-task grade loop (REVIEW Grade → Present/Route → FIX → back
> to REVIEW) was removed in the work-001 recovery; its function moved to
> `state-delivery-gate.md`.
