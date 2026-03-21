---
name: aid-discovery-review
description: >
  Grade A gate for the Discovery phase. Reviews all Knowledge Base documents produced by
  aid-discover, grades each document (A+ to F), identifies gaps and inaccuracies, and
  produces a DISCOVERY-REVIEW.md report.
argument-hint: "[--grade A-] minimum acceptable grade (format: [A-F][-+]?, default: review only)"
---

# Discovery Review — Grade A Gate

Review every Knowledge Base document produced by Discovery. Grade each one. Identify gaps,
inaccuracies, and shallow coverage. Produce a structured review report.

**This is a quality gate.** The KB feeds every downstream phase. Bad KB = bad specs = bad code.

## When to Use

- After Discovery completes (all 13 documents + README + INDEX + AGENTS.md + CLAUDE.md)
- When a human wants to validate Discovery output before proceeding

## Pre-flight Check

Verify all expected files exist:
- knowledge/ directory with 13 documents + README.md + INDEX.md
- AGENTS.md and CLAUDE.md in project root

If any are missing, report and stop.

## Review Process

### Step 1: Read All Documents

Read every document in knowledge/, plus AGENTS.md and CLAUDE.md. For each document:

1. **Completeness** — Does it cover what it should?
2. **Accuracy** — Cross-reference 3-5 claims per doc against actual source code
3. **Depth** — Lists things vs explains patterns and relationships
4. **Usefulness** — Would an agent building a feature find this helpful?
5. **Grade** — A+ through F (see grading scale below)

**Minimum 10 total spot-checks** where you verify a claim from a KB doc against actual code.

### Step 2: Write Review

Write `knowledge/DISCOVERY-REVIEW.md` with:

```markdown
# Discovery Review

**Reviewed**: {date}
**Overall Grade**: {grade}
**Recommendation**: {Pass / Needs Improvement / Fail}

## Summary

| Document | Grade | Issues |
|----------|-------|--------|
{one row per document}

## Detailed Reviews

### {document} — {Grade}

**Completeness**: {assessment}
**Accuracy**: {verified claims}
**Depth**: {surface vs deep}
**Usefulness**: {agent perspective}

**Issues**: {specific problems}
**Suggestions**: {improvements}

---

## Cross-Cutting Concerns
{contradictions, duplications, misplaced info}

## Verification Spot-Checks

| Claim | Document | Verified | Evidence |
|-------|----------|----------|----------|
{minimum 10 rows}
```

### Step 3: Report

Present summary table. Recommend:
- **All documents meet minimum grade**: "✅ KB passes quality gate."
- **Some below but none critical**: "⚠️ KB needs improvement."
- **Any D or F**: "❌ Critical failures found."

### Auto-Fix (with --grade argument)

If `--grade` is provided (e.g. `--grade A-`), validate format: `[A-F][-+]?`.

Grade ordering: `A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F`

For each document graded **below** the threshold:
1. Read specific issues from DISCOVERY-REVIEW.md
2. Read relevant source code to gather missing information
3. Edit the document to address issues
4. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

After fixes, regenerate INDEX.md. Update DISCOVERY-REVIEW.md with original grades (struck through),
new grades, and note: "Auto-fixed on {date} — minimum grade: {threshold}".

If any document still doesn't meet threshold after fix:
`⚠️ {document} improved from {old} to {new} but still below {threshold}. Manual intervention needed.`

## Grading Scale

| Grade | Meaning |
|-------|---------|
| A+ | Exceptional — comprehensive, accurate, evidence-rich |
| A | Thorough — covers scope with solid evidence |
| B+ | Good — minor gaps that don't block work |
| B | Adequate — basics covered, depth lacking |
| B- | Shallow — lists without explaining |
| C+ | Significant gaps — missing important sections |
| C | Barely useful — would need to re-discover |
| D | Misleading — wrong information |
| F | Missing or empty |

**Overall grade** = weighted average (architecture, module-map, coding-standards count double).

## Document Expectations

- **architecture.md**: folder structure, patterns, module boundaries, data flow, entry points
- **technology-stack.md**: languages/frameworks with versions from actual config files
- **module-map.md**: every module with purpose and dependencies
- **coding-standards.md**: naming, layout, DI, error handling from actual code
- **data-model.md**: entities with relationships, not just lists
- **api-contracts.md**: actual URLs/paths, not just class names
- **integration-map.md**: external systems with connection details, NOT same as module-map
- **domain-glossary.md**: project-specific terms, not generic programming vocabulary
- **test-landscape.md**: per-module coverage, real vs placeholder tests
- **security-model.md**: project-specific OWASP assessment, not generic checklist
- **tech-debt.md**: categorized by severity with actionable locations
- **infrastructure.md**: CI/CD details, deployment process, monitoring
- **open-questions.md**: specific, answerable questions organized by area
- **AGENTS.md/CLAUDE.md**: no remaining placeholders, real commands that work
