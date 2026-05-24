# State: REVIEW

REVIEW grades all 16 KB documents for accuracy, completeness, and evidence quality; it is selected when all 16 documents are populated and no grade has been assigned yet.

### Step 1: Dispatch the Reviewer

Print: `[Review 1/2] Reviewing Knowledge Base quality...`

Read `references/reviewer-prompt.md` for the full prompt to pass to the **discovery-reviewer** subagent.

**⚠️ CLEAN CONTEXT:** Do NOT include any info about generation process, which agents ran,
or prior state. The reviewer evaluates purely on what's on disk.

**⚠️ CONTAMINATION PREVENTION (also applies in FIX mode Step 3):**
- Do NOT include previous review results in the prompt
- Do NOT tell the reviewer what was fixed or previous grade
- Do NOT say "re-review" — reviewer must approach fresh

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 2: Post-Process `.aid/knowledge/STATE.md`

Verify `.aid/knowledge/STATE.md` `## KB Documents Status` and `## Issues` sections contain:
- [ ] Grade for every document (16 KB + CLAUDE.md + INDEX.md + README.md)
- [ ] Issues with severity levels ([CRITICAL], [HIGH], [MEDIUM], [MINOR])
- [ ] Verification spot-checks (minimum 10) under `## Verification Spot-Checks`
- [ ] Overall grade and recommendation under `## Review History`
- [ ] Cross-cutting concerns

Set Minimum Grade (from `--grade` or default `A`). Add first Review History entry under `## Review History`.

Print: `[Review 2/2] Review complete. Grade: {overall}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.`

Print: `[State: REVIEW] complete.`

**Advance:** Next: [State: Q-AND-A] — run /aid-discover again
