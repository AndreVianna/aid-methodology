---
name: aid-discovery-review
description: >
  Grade A gate for the Discovery phase. Reviews all Knowledge Base documents produced by
  aid-discover, grades each document (A+ to F), identifies gaps and inaccuracies, and
  produces a DISCOVERY-REVIEW.md report. Use after aid-discover completes to validate
  KB quality before proceeding to the Interview phase. Idempotent — run multiple times
  to iteratively improve KB quality.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
user-invocable: true
argument-hint: "[--grade A-] minimum grade threshold  [--fix] auto-fix documents below threshold"
---

# Discovery Review — Grade A Gate

Review every Knowledge Base document produced by Discovery. Grade each one. Identify gaps,
inaccuracies, and shallow coverage. Produce a structured review report.

**This is a quality gate.** The KB feeds every downstream phase. Bad KB = bad specs = bad code.

## Arguments

Two independent flags:

| Flag | Effect |
|------|--------|
| _(none)_ | Review all documents. Grade everything. Report only. |
| `--grade X` | Set minimum acceptable grade (format: `[A-F][-+]?`). Report highlights documents below threshold. |
| `--fix` | Auto-fix documents below threshold. **Requires `--grade`.** |

**Examples:**
- `/aid-discovery-review` — full review, no fixes
- `/aid-discovery-review --grade A-` — review with A- threshold, report what fails
- `/aid-discovery-review --grade A- --fix` — review, then fix documents below A-
- `/aid-discovery-review --fix` — ❌ Error: `--fix requires --grade`

**Idempotent:** Run multiple times. Each run re-reads, re-grades, and (with `--fix`) improves.
A document at C today might reach B after one fix run, then A- after a second.

## When to Use

- After `/aid-discover` completes (all 13 documents + README + INDEX + AGENTS.md + CLAUDE.md)
- When a human wants to validate Discovery output before proceeding
- Iteratively after manual edits to verify improvement
- After re-running Discovery on updated code

## Inputs

- `knowledge/` directory with 13 expected documents + README.md + INDEX.md
- `AGENTS.md` and `CLAUDE.md` in project root (updated by Discovery)
- The codebase itself (for cross-referencing claims)
- `knowledge/DISCOVERY-REVIEW.md` if it exists (previous review — used for delta comparison)

## Pre-flight Check

**Parse arguments first.** If `--fix` is present without `--grade`, print error and stop.
If `--grade` value doesn't match `[A-F][-+]?`, print error and stop.

Verify all expected files exist:

```
knowledge/architecture.md
knowledge/technology-stack.md
knowledge/module-map.md
knowledge/coding-standards.md
knowledge/data-model.md
knowledge/api-contracts.md
knowledge/integration-map.md
knowledge/domain-glossary.md
knowledge/test-landscape.md
knowledge/security-model.md
knowledge/tech-debt.md
knowledge/infrastructure.md
knowledge/open-questions.md
knowledge/README.md
knowledge/INDEX.md
AGENTS.md
CLAUDE.md
```

If any are missing, report them immediately and stop. Discovery must complete first.

If `knowledge/DISCOVERY-REVIEW.md` exists from a previous run, note the previous grades
for delta comparison in the new report.

## Review Process

### Step 1: Dispatch the Reviewer

Dispatch **discovery-reviewer** subagent with ALL KB documents as context.

Print: `[1/3] Reviewing Knowledge Base quality...`

Prompt to pass to the subagent:
> Review every document in knowledge/ for quality. For each document, assess:
> 1. **Completeness** — Does it cover what it should? Are there obvious gaps?
> 2. **Accuracy** — Cross-reference claims against actual code. Are file paths real? Are version numbers correct?
> 3. **Depth** — Is it surface-level listing or does it show understanding of patterns and relationships?
> 4. **Usefulness** — Would an agent working on this codebase find this document helpful?
> 5. **Evidence** — Are claims grounded in code (file paths, class names) or generic?
>
> Grade each document: A+ (exceptional), A (thorough), B+ (good with minor gaps), B (adequate),
> B- (shallow), C+ (significant gaps), C (barely useful), D (misleading or wrong), F (missing/empty).
>
> Also review AGENTS.md and CLAUDE.md — are the discovered values accurate and useful?
>
> Write the full review to knowledge/DISCOVERY-REVIEW.md using the exact template format.

Wait for completion.

---

### Step 2: Verify Review Quality

Read `knowledge/DISCOVERY-REVIEW.md`. Verify it contains:
- [ ] Grade for every document (13 KB docs + AGENTS.md + CLAUDE.md + INDEX.md + README.md)
- [ ] Specific issues identified per document (not generic complaints)
- [ ] Cross-reference evidence (verified at least some claims against actual code)
- [ ] Overall grade and recommendation
- [ ] Improvement suggestions per document graded below A

Print: `[2/3] Verifying review completeness...`

If the review is missing any of the above, report the gaps.

---

### Step 3: Report

Print: `[3/3] Review complete.`

Present a summary table to the user:

```
| Document              | Grade | Previous | Key Issues                              |
|-----------------------|-------|----------|-----------------------------------------|
| architecture.md       | A     | —        |                                         |
| technology-stack.md   | B     | C+       | Missing framework versions              |
| ...                   | ...   | ...      | ...                                     |
```

The "Previous" column shows the grade from the last review if DISCOVERY-REVIEW.md existed
before this run. Use "—" if no previous review or first run.

**Without `--grade`:**
- Report all grades. No pass/fail judgment. The human decides.

**With `--grade`:**
- Count documents below threshold.
- **All at or above threshold**: "✅ KB passes quality gate at {threshold}. Ready for Interview phase."
- **Some below, none D/F**: "⚠️ {N} documents below {threshold}. See DISCOVERY-REVIEW.md."
- **Any D or F**: "❌ Critical failures found. Re-run targeted discovery before proceeding."

**Without `--fix`:** Stop here.

**With `--fix`:** Proceed to Step 4.

---

### Step 4: Auto-Fix (only with --grade AND --fix)

**Grade ordering** (highest to lowest):
`A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F`

For each document graded **below** the `--grade` threshold:

1. Read the specific issues from DISCOVERY-REVIEW.md
2. Read the relevant source code to gather missing information
3. Edit the document to address the issues — be specific, add evidence (file paths, code references)
4. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

After all fixes:
- Regenerate INDEX.md if any document summaries changed
- Update DISCOVERY-REVIEW.md:
  - Original grades preserved (struck through) in a "Review History" section
  - New grades in the main table
  - Note: "Auto-fixed on {date} — minimum grade: {threshold}"

**Final report:**
- For each improved document: `✅ {document}: {old} → {new}`
- For documents still below threshold: `⚠️ {document}: {old} → {new} (still below {threshold}). Manual intervention needed.`
- Overall: "Fixed {X}/{Y} documents. {Z} still need attention." or "All documents now meet {threshold}."

---

## Output

### knowledge/DISCOVERY-REVIEW.md

```markdown
# Discovery Review

**Reviewed**: {date}
**Reviewer**: discovery-reviewer (AID quality gate)
**Overall Grade**: {grade}
**Minimum Grade**: {threshold if --grade was set, otherwise "not set"}
**Recommendation**: {Pass / Needs Improvement / Fail}
**Run**: {N} (increment on each review)

## Summary

| Document | Grade | Previous | Status | Issues |
|----------|-------|----------|--------|--------|
| architecture.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| technology-stack.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| module-map.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| coding-standards.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| data-model.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| api-contracts.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| integration-map.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| domain-glossary.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| test-landscape.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| security-model.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| tech-debt.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| infrastructure.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| open-questions.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| INDEX.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| README.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| AGENTS.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |
| CLAUDE.md | {grade} | {prev or —} | {✅/⚠️/❌} | {one-line or "—"} |

## Detailed Reviews

### architecture.md — {Grade}

**Completeness**: {assessment}
**Accuracy**: {verified claims vs code}
**Depth**: {surface vs deep understanding}
**Usefulness**: {would an agent benefit from this?}

**Issues**:
- {specific issue with evidence}

**Suggestions**:
- {specific improvement}

---

{repeat for each document}

## Cross-Cutting Concerns

- {issues that span multiple documents}
- {inconsistencies between documents}
- {information in wrong document (should be in X instead of Y)}

## Verification Spot-Checks

| Claim | Document | Verified | Evidence |
|-------|----------|----------|----------|
| {specific claim from KB} | {doc} | ✅/❌ | {file path or reason} |
{minimum 10 spot-checks across different documents}

## Review History

| Run | Date | Overall | Notes |
|-----|------|---------|-------|
| 1   | {date} | {grade} | Initial review |
| 2   | {date} | {grade} | After auto-fix (threshold: A-) |
```

## Grading Criteria

| Grade | Meaning |
|-------|---------|
| A+ | Exceptional — comprehensive, accurate, evidence-rich, immediately useful |
| A | Thorough — covers expected scope with solid evidence |
| B+ | Good — minor gaps or missing details that don't block work |
| B | Adequate — covers basics but lacks depth in important areas |
| B- | Shallow — lists things without explaining patterns or relationships |
| C+ | Significant gaps — missing important sections or inaccurate in places |
| C | Barely useful — an agent would need to re-discover most information |
| D | Misleading — contains wrong information that could cause bad decisions |
| F | Missing or empty |

**Overall grade** = weighted average where architecture, module-map, and coding-standards
count double (they're referenced most by downstream phases).
