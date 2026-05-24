# State: REVIEW

Task output is graded by a lightweight quick-check pass first; then a clean-context reviewer agent produces the full grade. Routing to FIX or DONE follows from the computed grade.

<!-- INSERTION POINT: task-022 (per-delivery gate) — when delivery-003 ships,
     a ## Delivery Gate section will be inserted after Step 3: Present and Route
     (when grade ≥ min) to run the delivery-level gate before marking DONE. The
     gate checks cross-task consistency within the delivery. -->

## Step 1.5: QUICK CHECK (Pre-Reviewer Triage)

A lightweight single-pass reviewer runs **before** the full reviewer to catch
obvious `[CRITICAL]` and `[HIGH]` issues early. No grade is computed, no loop
runs — this is a fast filter only.

**Before dispatching, print:** `[Step 1.5] Dispatching reviewer (quick-check, Small tier) for quick-check → subagent_type=reviewer`.

Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule).

### Quick-Check Dispatch

Dispatch the `reviewer` agent with `subagent_type: reviewer` at **Small tier**
(cheap, fast). Pass the following context:

- Task deliverables / artifacts produced by Step 1 (EXECUTE)
- `task-NNN.md` — acceptance criteria and scope
- Feature SPEC — expected behaviour
- Grading rubric (`../../templates/grading-rubric.md`) — for severity tag reference only

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

▶ reviewer (quick-check) starting (~1 min)
✓ reviewer (quick-check) done (record actual time) — or ✗ quick-check failed: {reason}

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
4. Mark the finding as `Fixed-on-spot` in the quick-check findings block (see §
   Write Findings to STATE.md below).

Only one fix attempt per critical finding. There is no loop here.

#### HIGH Deferral

For each `[HIGH]` finding:

1. Mark the finding as `Deferred-to-gate` in the quick-check findings block.
2. Write a deferred-issue row to the delivery's issue log using
   `writeback-task-status.sh --delivery-id NNN --append-issue ROW` where `ROW`
   is a pipe-delimited markdown table row:

   ```
   | task-NNN | [HIGH] | {one-line description} | Open |
   ```

   The delivery issue log is at `.aid/work-NNN/delivery-NNN-issues.md`. The
   script creates the file (from the `delivery-issues.md` template) if it does
   not yet exist.

3. Continue to Step 2 — `[HIGH]` findings do **not** block the full reviewer
   dispatch. They are deferred to the per-delivery gate.

### Write Findings to STATE.md

After triage, write the quick-check findings block to the work `STATE.md`
`## Quick Check Findings` section via the helper:

```bash
writeback-task-status.sh --task-id NNN --findings "BLOCK"
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

**Advance:** After triage and findings write, proceed to Step 2 (full reviewer).

## Step 2: REVIEW (Grade)

Dispatch the `reviewer` agent (Task tool with `subagent_type: reviewer`). Clean context — the reviewer must NOT see the executor's working notes.

**Before dispatching, print:** `[Step 2] Dispatching reviewer for review → subagent_type=reviewer`.

Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule).

▶ reviewer starting (~1–2 min)
**Reviewer receives:**
- All changes/artifacts produced by the task
- task-NNN.md — acceptance criteria and scope
- Feature SPEC — expected behavior
- KB docs via INDEX.md (as relevant to the type)
- Grading rubric (`../../templates/grading-rubric.md`)

Read `references/reviewer-guide.md` for severity/source classifications and type-specific review checklists.

## Grading

The grade is **computed deterministically**, not judged. The reviewer outputs a structured issue list with `[CRITICAL]`/`[HIGH]`/`[MEDIUM]`/`[LOW]`/`[MINOR]` severity tags. The grade follows from the rubric.

- Rubric: `../../templates/grading-rubric.md`
- Script: `../../templates/scripts/grade.sh` — run it on the reviewer's issue list (recorded in the work `STATE.md` `## Tasks Status` table).
- Minimum grade: read from `.aid/knowledge/STATE.md` field `**Minimum Grade:**`

Run the script after the reviewer completes. The script prints the grade. Compare against minimum grade to decide DONE vs FIX.

**⚠️ The reviewer NEVER fixes anything.** It only grades and lists issues.

✓ reviewer done (record actual time) — or ✗ reviewer failed: {reason}
**Output:** Update work `STATE.md` `## Tasks Status` table row for this task:
- Set Cycle number (increment)
- Set Grade
- Write all issues in the task's issues section with severity, source, description
- Append cycle summary to the task's review history

## Step 3: Present and Route

**Present ALL issues to the user** regardless of source.

```
[Review — Cycle {N} — Grade: {grade} — Minimum: {min}]

Issues found:

| # | Severity | Source | Description |
|---|----------|--------|-------------|
| 1 | Medium | CODE | ... |
| 2 | Low | TASK | ... |

{If grade ≥ minimum:}
✅ Grade meets minimum. Marking as Done.

{If grade < minimum:}
Grade below minimum. Next steps:
- CODE issues (#1, #3): I'll fix these automatically.
- TASK issues (#2): This needs a task update. {explain}
- SPEC issues: Would require re-running /aid-specify.
- KB issues: Would require re-running /aid-discover.

Proceed with auto-fix of CODE issues?
```

**Routing:**

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Mark all issues as `Accepted`. Set Status to `Done`. ✅ |
| Grade < minimum | Auto-fix CODE issues (Step 4 — FIX state). Present non-CODE for user decision. |

**Non-CODE issues (TASK, SPEC, KB):**
- **TASK** → Present to user with suggestion. User updates task, re-run.
- **SPEC** → Write Q&A to `.aid/{work}/STATE.md` `## Cross-phase Q&A` → suggest `/aid-specify`
- **KB** → Write Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)` → suggest `/aid-discover`

Mark non-CODE issues as `Loopback` in work `STATE.md` `## Tasks Status` with target phase.

**If ONLY non-CODE issues remain:** **STOP.** The work is as good as it can be —
the problem is upstream. Present what needs to change and where.

**Advance:** Next state is `FIX` when grade < minimum (CODE issues to fix), or `DONE` when grade ≥ minimum — router prints `Next: [State: FIX] — run /aid-execute again` (or `Next: [State: DONE] — run /aid-execute again`) and exits.
