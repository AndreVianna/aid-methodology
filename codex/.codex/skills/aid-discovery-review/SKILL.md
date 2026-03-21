---
name: aid-discovery-review
description: >
  Grade A gate for the Discovery phase. Reviews all Knowledge Base documents produced by
  aid-discover, grades each document (A+ to F), identifies gaps and inaccuracies, and
  produces a DISCOVERY-REVIEW.md report. Idempotent — run multiple times to iteratively
  improve KB quality.
argument-hint: "[--grade A-] minimum grade threshold  [--fix] auto-fix documents below threshold"
---

# Discovery Review — Grade A Gate

Review every Knowledge Base document produced by Discovery. Grade each one. Identify gaps,
inaccuracies, and shallow coverage. Produce a structured review report.

**This is a quality gate.** The KB feeds every downstream phase. Bad KB = bad specs = bad code.

## Arguments

| Flag | Effect |
|------|--------|
| _(none)_ | Review all documents. Grade everything. Report only. |
| `--grade X` | Set minimum acceptable grade (format: `[A-F][-+]?`). Highlights failures. |
| `--fix` | Auto-fix documents below threshold. **Requires `--grade`.** |

**Examples:**
- `/aid-discovery-review` — full review, no fixes
- `/aid-discovery-review --grade A-` — review, report what's below A-
- `/aid-discovery-review --grade A- --fix` — review, then fix documents below A-
- `/aid-discovery-review --fix` — ❌ Error: `--fix requires --grade`

**Idempotent:** Run multiple times. Each run re-reads, re-grades, and (with `--fix`) improves.

## Pre-flight Check

Parse arguments first. `--fix` without `--grade` → error. `--grade` format must match `[A-F][-+]?`.

Verify all expected files exist:
- `knowledge/` directory with 13 documents + README.md + INDEX.md
- `AGENTS.md` and `CLAUDE.md` in project root

If any are missing, report and stop.

If `knowledge/DISCOVERY-REVIEW.md` exists, load previous grades for delta comparison.

## Review Process

### Step 1: Review All Documents

Read every document in `knowledge/`, plus `AGENTS.md` and `CLAUDE.md`. For each document:

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
**Minimum Grade**: {threshold or "not set"}
**Recommendation**: {Pass / Needs Improvement / Fail}
**Run**: {N}

## Summary

| Document | Grade | Previous | Status | Issues |
|----------|-------|----------|--------|--------|
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

## Review History

| Run | Date | Overall | Notes |
|-----|------|---------|-------|
{one row per run}
```

### Step 3: Report

**Without `--grade`:** Report all grades. No pass/fail judgment. Human decides.

**With `--grade`:**
- All at or above threshold → "✅ KB passes quality gate at {threshold}."
- Some below, none D/F → "⚠️ {N} documents below {threshold}."
- Any D or F → "❌ Critical failures found."

**Without `--fix`:** Stop here.
**With `--fix`:** Proceed to Step 4.

### Step 4: Auto-Fix (only with --grade AND --fix)

Grade ordering: `A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F`

For each document below threshold:
1. Read specific issues from DISCOVERY-REVIEW.md
2. Read relevant source code
3. Edit document to address issues
4. Re-grade

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

After fixes: regenerate INDEX.md, update DISCOVERY-REVIEW.md with new grades
and review history entry.

Final report:
- `✅ {document}: {old} → {new}` for improved
- `⚠️ {document}: {old} → {new} (still below {threshold})` for still failing
- "Fixed {X}/{Y}. {Z} still need attention." or "All documents now meet {threshold}."

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

- **architecture.md**: folder structure, patterns with evidence, data flow, entry points
- **technology-stack.md**: versions from actual config (not "TBD")
- **module-map.md**: every module with purpose AND dependencies
- **coding-standards.md**: conventions from actual code, not generic advice
- **data-model.md**: entities with relationships, not just lists
- **api-contracts.md**: actual URLs/paths, not just class names
- **integration-map.md**: connection details, NOT same content as module-map
- **domain-glossary.md**: project-specific terms
- **test-landscape.md**: which modules have real tests vs placeholders
- **security-model.md**: project-specific assessment, not generic OWASP
- **tech-debt.md**: severity-categorized with file locations
- **infrastructure.md**: CI/CD flow, deployment, monitoring details
- **open-questions.md**: specific, answerable, comprehensive
- **AGENTS.md/CLAUDE.md**: no placeholders, real working commands
