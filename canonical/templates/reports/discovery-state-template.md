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
| project-structure.md | {grade} | {✅ Pass / ❌ Below minimum} | {one-line summary or —} |
| external-sources.md | {grade} | {status} | {issues} |
| architecture.md | {grade} | {status} | {issues} |
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
| ui-architecture.md | {grade} | {status} | {issues} |
| feature-inventory.md | {grade} | {status} | {issues} |
| INDEX.md | {grade} | {status} | {issues} |
| README.md | {grade} | {status} | {issues} |
| {project_context_file} | {grade} | {status} | {issues} |

## Issues Found

### {document} ({grade})
- [CRITICAL] {specific issue with evidence}
- [HIGH] {issue}
- [MEDIUM] {issue}
- [LOW] {issue}
- [MINOR] {issue}

### {document} ({grade})
- [HIGH] {issue}
...

**Grade caps (absolute):**
Any [CRITICAL] → E range (E- / E / E+). Any [HIGH] → D range. Any [MEDIUM] → C range. Any [LOW] → B range. Any [MINOR] → A range. Zero issues → A+.
See `templates/grading-rubric.md` for the full scale.

## Verification Spot-Checks

| Claim | Document | Verified | Evidence |
|-------|----------|----------|----------|
| {specific claim} | {doc} | ✅/❌ | {file path or reason} |
{minimum 10 spot-checks, at least 5 version verifications}

## Cross-Cutting Concerns
- {issues spanning multiple documents}
- {inconsistencies between documents}

## Review History

| Run | Date | Grade | Action | Issues Fixed | Q&A Pending |
|-----|------|-------|--------|-------------|-------------|
| 1 | {date} | {grade} | {Review/Fix/Q&A/Approval} | {— or count} | {count or —} |
