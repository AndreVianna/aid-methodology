---
name: aid-discovery-review
description: >
  Grade A gate for the Discovery phase. Reviews all Knowledge Base documents produced by
  aid-discover, grades each document (A+ to F), identifies gaps and inaccuracies, and
  produces a DISCOVERY-REVIEW.md report. Use after aid-discover completes to validate
  KB quality before proceeding to the Interview phase.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
user-invocable: true
argument-hint: "[--fix] to auto-fix issues graded B or below"
---

# Discovery Review — Grade A Gate

Review every Knowledge Base document produced by Discovery. Grade each one. Identify gaps,
inaccuracies, and shallow coverage. Produce a structured review report.

**This is a quality gate.** The KB feeds every downstream phase. Bad KB = bad specs = bad code.

## When to Use

- After `/aid-discover` completes (all 13 documents + README + INDEX + AGENTS.md + CLAUDE.md)
- When a human wants to validate Discovery output before proceeding
- When re-running Discovery on updated code and need to verify improvements

## Inputs

- `knowledge/` directory with 13 expected documents + README.md + INDEX.md
- `AGENTS.md` and `CLAUDE.md` in project root (updated by Discovery)
- The codebase itself (for cross-referencing claims)

## Pre-flight Check

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
- [ ] Overall grade and go/no-go recommendation
- [ ] Improvement suggestions per document graded below A

Print: `[2/3] Verifying review completeness...`

If the review is missing any of the above, report the gaps.

---

### Step 3: Report and Recommend

Print: `[3/3] Review complete.`

Present a summary table to the user:

```
| Document              | Grade | Key Issues                              |
|-----------------------|-------|-----------------------------------------|
| architecture.md       | A     |                                         |
| technology-stack.md   | B     | Missing framework versions              |
| ...                   | ...   | ...                                     |
```

Then:
- **If overall grade is A- or above**: "✅ KB passes quality gate. Ready for Interview phase."
- **If overall grade is B+ or below**: "⚠️ KB needs improvement. See DISCOVERY-REVIEW.md for details."
- **If any document is graded C or below**: "❌ Critical gaps found. Re-run targeted discovery or fix manually before proceeding."

If `--fix` argument was provided and any document is graded B or below, proceed to Step 4.

---

### Step 4: Auto-Fix (only with --fix argument)

For each document graded B or below:

1. Read the specific issues from DISCOVERY-REVIEW.md
2. Read the relevant source code to gather missing information
3. Edit the document to address the issues
4. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

After all fixes, regenerate INDEX.md (summaries may have changed).

Update DISCOVERY-REVIEW.md with:
- Original grades preserved (struck through)
- New grades after fixes
- Note: "Auto-fixed on {date}"

---

## Output

### knowledge/DISCOVERY-REVIEW.md

```markdown
# Discovery Review

**Reviewed**: {date}
**Reviewer**: discovery-reviewer (AID quality gate)
**Overall Grade**: {grade}
**Recommendation**: {Pass / Needs Improvement / Fail}

## Summary

| Document | Grade | Issues |
|----------|-------|--------|
| architecture.md | {grade} | {one-line summary or "—"} |
| technology-stack.md | {grade} | {one-line summary or "—"} |
| module-map.md | {grade} | {one-line summary or "—"} |
| coding-standards.md | {grade} | {one-line summary or "—"} |
| data-model.md | {grade} | {one-line summary or "—"} |
| api-contracts.md | {grade} | {one-line summary or "—"} |
| integration-map.md | {grade} | {one-line summary or "—"} |
| domain-glossary.md | {grade} | {one-line summary or "—"} |
| test-landscape.md | {grade} | {one-line summary or "—"} |
| security-model.md | {grade} | {one-line summary or "—"} |
| tech-debt.md | {grade} | {one-line summary or "—"} |
| infrastructure.md | {grade} | {one-line summary or "—"} |
| open-questions.md | {grade} | {one-line summary or "—"} |
| INDEX.md | {grade} | {one-line summary or "—"} |
| README.md | {grade} | {one-line summary or "—"} |
| AGENTS.md | {grade} | {one-line summary or "—"} |
| CLAUDE.md | {grade} | {one-line summary or "—"} |

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
| {specific claim from KB} | {doc} | ✅/❌ | {file path or reason} |
| {specific claim from KB} | {doc} | ✅/❌ | {file path or reason} |
{minimum 10 spot-checks across different documents}
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
