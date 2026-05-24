# State: REVIEW

Task output is graded by a clean-context reviewer agent and all issues are presented to the user; routing to FIX or DONE follows from the computed grade.

<!-- INSERTION POINT: task-021 (per-task quick-check) — when delivery-003 ships,
     a ## Quick Check section will be inserted here (before Step 2: REVIEW) to
     run the automated quick-check gate against the task's acceptance criteria
     before dispatching the full reviewer. If quick-check finds no issues, the
     reviewer dispatch may be skipped for passing tasks.

     INSERTION POINT: task-022 (per-delivery gate) — when delivery-003 ships,
     a ## Delivery Gate section will be inserted after Step 3: Present and Route
     (when grade ≥ min) to run the delivery-level gate before marking DONE. The
     gate checks cross-task consistency within the delivery. -->

## Step 2: REVIEW (Grade)

Dispatch the `reviewer` agent (Task tool with `subagent_type: reviewer`). Clean context — the reviewer must NOT see the executor's working notes.

**Before dispatching, print:** `[Step 2] Dispatching reviewer for review → subagent_type=reviewer`.

Also update the task's row in work `STATE.md` `## Dispatches` sub-column: `| 2 | reviewer | REVIEW | {cycle} |`.

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
