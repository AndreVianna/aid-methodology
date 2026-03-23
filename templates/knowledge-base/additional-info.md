# Additional Information

> **Source:** aid-discover (Phase 1)
> **Status:** Active — feeds directly into aid-interview
> **Last Updated:** {date}

> Structured Q&A capturing gaps, assumptions, and clarifications from code analysis. Every entry is something an AI agent would have to guess about — guessing creates specs that don't match reality.

---

## Questions & Answers

| ID | Question | Category | Impact | Status |
|----|----------|----------|--------|--------|
| Q1 | {question} | {category} | {High/Medium/Low} | {Pending/Answered/Skipped} |

**Categories:** Architecture · Infrastructure · Security · Data · Business · Integration · Process · UI-UX · Performance · Testing

---

## Detailed Entries

### Q1: {Question}

**Category:** {Architecture / Infrastructure / Security / Data / Business / Integration / Process / UI-UX / Performance / Testing}
**Impact:** {High / Medium / Low}
**Status:** {Pending / Answered / Skipped}

**Context:**
{Specific evidence from the codebase that raises this question. Don't say "unknown" — say "SearchService has three implementations with different timeout values (5s, 15s, 30s) with no comments. We don't know which is correct."}

**What we found in code:**
- {concrete evidence: file path, pattern, or behavior observed}

**Impact if wrong:**
{What happens if we spec or implement against the wrong assumption}

**Suggested Answer:**
{Optional — best guess based on code analysis, with reasoning}

**Likely answer options:**
- Option A: {description} — {implication}
- Option B: {description} — {implication}

**Who can answer:** {architect / product owner / technical lead / the person who wrote {module}}

**Actual Answer:** {leave blank until answered}

**Applied to:** {leave blank — updated by Fix step when answer is applied to KB documents}

---

### Q2: {Question}

**Category:** {category}
**Impact:** {impact}
**Status:** {Pending}

**Context:** {evidence from code}

**What we found in code:**
- {specifics}

**Impact if wrong:** {consequence}

**Suggested Answer:** {optional}

**Who can answer:** {role}

**Actual Answer:** {leave blank}

**Applied to:** {leave blank}

---

## Answered Questions

> Entries moved here once resolved. Keep as record of what was discovered and when.

| ID | Question | Answer | Source | Date |
|----|----------|--------|--------|------|
| Q{n} | {question} | {answer} | {aid-interview Q7 / stakeholder email / code comment} | {date} |

---

## Assumptions Made Without Answers

> Items where we made an assumption to proceed. These are risks — flag for early interview confirmation.

| Assumption | What We Assumed | Risk if Wrong | Related Entry |
|------------|-----------------|---------------|---------------|
| {e.g., Auth model} | {JWT, 24h expiry} | {Security model and session handling will need rework} | Q{n} |
| {e.g., Multi-tenancy} | {Single tenant} | {Data isolation, schema, and API design may all be wrong} | Q{n} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial additional information from code analysis |
