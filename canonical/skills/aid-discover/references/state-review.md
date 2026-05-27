# State: REVIEW

REVIEW grades all 16 KB documents for accuracy, completeness, and evidence quality; it is selected when all 16 documents are populated and no grade has been assigned yet.

### Step 1: Dispatch the Reviewer

Print: `[Review 1/2] Reviewing Knowledge Base quality...`

**Dispatch package:**
1. Render the universal 5-section brief from `references/reviewer-brief.md`,
   substituting `{{ARTIFACTS}}` (the list of 16 KB doc paths under review for
   this cycle) and `{{CONTEXT}}` (descriptive-only — no downstream phase
   references; see the brief's CONTEXT discipline rule).
2. Append the rubric-detail body from `references/reviewer-prompt.md` — that
   file contains the per-claim verification checklist + spot-check minimums
   that go beyond the universal rubric pointer in the brief.
3. Dispatch the **discovery-reviewer** subagent with the combined prompt.

**⚠️ CLEAN CONTEXT:** Do NOT include any info about generation process, which agents ran,
or prior state. The reviewer evaluates purely on what's on disk.

**⚠️ CONTAMINATION PREVENTION (also applies in FIX mode Step 6):**
- Do NOT include previous review results in the prompt
- Do NOT tell the reviewer what was fixed or previous grade
- Do NOT say "re-review" — reviewer must approach fresh

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 2: Post-Process `.aid/knowledge/STATE.md`

Verify `.aid/knowledge/STATE.md` `## KB Documents Status` and `## Issues` sections contain:
- [ ] Grade for every document (16 KB + {project_context_file} + INDEX.md + README.md)
- [ ] Issues with severity levels ([CRITICAL], [HIGH], [MEDIUM], [MINOR])
- [ ] Verification spot-checks (minimum 10) under `## Verification Spot-Checks`
- [ ] Overall grade and recommendation under `## Review History`
- [ ] Cross-cutting concerns

If `--grade` provided, update `.aid/settings.yml` `discover.minimum_grade` (via `/aid-config` or direct YAML edit). Add first Review History entry under `## Review History`. Resolve current minimum via `bash canonical/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A`.

Print: `[Review 2/2] Review complete. Grade: {overall}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.`

Print: `[State: REVIEW] complete.`

**Advance:** Next: [State: Q-AND-A] — run /aid-discover again
