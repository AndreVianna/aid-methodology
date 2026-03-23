# REQUIREMENTS.md Template

This template defines the structure for `knowledge/REQUIREMENTS.md` — a first-class methodology artifact produced by [aid-interview](../../skills/aid-interview/).

## Usage

- **First run:** aid-interview walks through each section with the stakeholder and fills them in.
- **Subsequent runs:** aid-interview cross-references this file against the Knowledge Base, grades consistency, and asks targeted questions.

## Conventions

- **Change Log is mandatory.** Every modification — initial creation, cross-reference updates, targeted re-interviews — gets an entry.
- **Sections can be marked N/A** if not applicable to the project.
- **`*(pending)*`** marks sections not yet addressed during the interview.
- **Cross-reference runs** add Change Log entries with source `/aid-interview (cross-reference)`.
- **File is uppercase** (`REQUIREMENTS.md`) — it's a first-class artifact in `knowledge/`.

---

## Template

```markdown
# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| {date} | Initial interview started | /aid-interview |

## 1. Objective

{What are we building and why? In the stakeholder's words.}

## 2. Problem Statement

{What problem does this solve? What's the current pain?}

## 3. Users & Stakeholders

{Who uses this? Who cares about the outcome?}

| Role | Description | Primary Needs |
|------|-------------|---------------|
| {role} | {who} | {needs} |

## 4. Scope

### In Scope

{What's included in this project.}

### Out of Scope

{What's explicitly excluded. Prevents scope creep.}

## 5. Functional Requirements

{What the system must do. Specific enough to implement.}

## 6. Non-Functional Requirements

{Performance, security, reliability, scalability targets. Measurable where possible.}

## 7. Constraints

{Timeline, budget, team, compliance, technical limitations.}

## 8. Assumptions & Dependencies

{What we're assuming to be true. External dependencies.}

## 9. Acceptance Criteria

{How do we know it's done? Testable conditions for key features.}

## 10. Priority

{Feature/requirement priority ordering. Must/Should/Could or numbered.}
```

---

## Notes

- Sections not yet discussed during the interview should contain `*(pending)*` as a placeholder.
- The Change Log tracks the full history of the document. Example entries after cross-reference:

  ```
  | 2026-03-15 | Updated NFRs: added latency target from load-test results | /aid-interview (cross-reference) |
  | 2026-03-20 | Revised scope: moved mobile app to Out of Scope per stakeholder | /aid-interview |
  ```

- The stakeholder's own language is preferred in Objective and Problem Statement. Don't rewrite their words into technical jargon.
- Acceptance Criteria should be testable — "the system is fast" is not a criterion; "API response < 200ms p95" is.
