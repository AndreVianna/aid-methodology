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
3. Include in the prompt:
   - **Ledger lifecycle:** "Read the existing `.aid/.temp/review-pending/discovery.md`
     if it exists. For each existing row: verify on disk, update Status if needed
     (Pending→Fixed if resolved; Fixed→Recurred if regressed). Append new findings
     as rows with Status: Pending. The ledger is the entire output file — no headers,
     no narrative."
   - **Schema reference:** "Output per `canonical/templates/reviewer-ledger-schema.md`."
4. Dispatch the **discovery-reviewer** subagent with the combined prompt.

**⚠️ CLEAN CONTEXT:** Do NOT include any info about generation process, which agents ran,
or prior state. The reviewer evaluates purely on what's on disk.

**⚠️ CONTAMINATION PREVENTION (also applies in FIX mode Step 6):**
- Do NOT include previous review results in the prompt
- Do NOT tell the reviewer what was fixed or previous grade
- Do NOT say "re-review" — reviewer must approach fresh

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 2: Grade via grade.sh

After the reviewer returns, run grade.sh on the ledger:

```bash
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/discovery.md
```

The grade is printed to stdout; the `--explain` breakdown goes to stderr.

### Step 3: Post-Process `.aid/knowledge/STATE.md`

Verify the reviewer's return message (not the ledger file) contains:
- [ ] Overall grade and recommendation
- [ ] Per-document summaries
- [ ] Verification spot-checks (minimum 10)
- [ ] Cross-cutting concerns

Update `.aid/knowledge/STATE.md` `## Review History` with the new entry.
Record the grade computed by grade.sh, not any grade mentioned in the reviewer's prose.

If `--grade` provided, update `.aid/settings.yml` `discover.minimum_grade` (via `/aid-config` or direct YAML edit). Resolve current minimum via `bash canonical/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A`.

Print: `[Review 2/2] Review complete. Grade: {overall}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.`

Print: `[State: REVIEW] complete.`

**Advance:** Next: [State: Q-AND-A] — run /aid-discover again
