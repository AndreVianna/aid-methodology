# Discovery State

## Settings
- **Minimum Grade:** {grade, default A}
- **Last Run:** {ISO timestamp}
- **User Approved:** {yes / no}

## Current Grade: {overall grade}

**Recommendation:** {Pass / Needs Improvement / Fail}

## Documents

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| architecture.md | {grade} | {✅ Pass / ❌ Below minimum} | {one-line summary or —} |
| technology-stack.md | {grade} | {status} | {issues} |
| module-map.md | {grade} | {status} | {issues} |
| coding-standards.md | {grade} | {status} | {issues} |
| data-model.md | {grade} | {status} | {issues} |
| api-contracts.md | {grade} | {status} | {issues} |
| integration-map.md | {grade} | {status} | {issues} |
| domain-glossary.md | {grade} | {status} | {issues} |
| test-landscape.md | {grade} | {status} | {issues} |
| security-model.md | {grade} | {status} | {issues} |
| tech-debt.md | {grade} | {status} | {issues} |
| infrastructure.md | {grade} | {status} | {issues} |
| additional-info.md | {grade} | {status} | {issues} |
| INDEX.md | {grade} | {status} | {issues} |
| README.md | {grade} | {status} | {issues} |
| AGENTS.md | {grade} | {status} | {issues} |
| CLAUDE.md | {grade} | {status} | {issues} |

## Issues Found

### {document} ({grade})
- [CRITICAL] {specific issue with evidence}
- [HIGH] {issue}
- [MEDIUM] {issue}
- [MINOR] {issue}

### {document} ({grade})
- [HIGH] {issue}
...

**Grade caps (absolute):**
Multiple [CRITICAL] → max D. One [CRITICAL] → max D+.
Multiple [HIGH] → max C. One [HIGH] → max C+.
Multiple [MEDIUM] → max B. One [MEDIUM] → max B+.
Multiple [MINOR] → max A-. One [MINOR] → max A. Only zero issues = A+.

## Verification Spot-Checks

| Claim | Document | Verified | Evidence |
|-------|----------|----------|----------|
| {specific claim} | {doc} | ✅/❌ | {file path or reason} |
{minimum 15 spot-checks, at least 5 version verifications}

## Cross-Cutting Concerns
- {issues spanning multiple documents}
- {inconsistencies between documents}

## Review History

| Run | Date | Grade | Action | Issues Fixed | Q&A Pending |
|-----|------|-------|--------|-------------|-------------|
| 1 | {date} | {grade} | {Review/Fix/Q&A/Approval} | {— or count} | {count or —} |
