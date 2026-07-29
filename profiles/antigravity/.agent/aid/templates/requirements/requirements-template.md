# REQUIREMENTS.md Template

This template defines the structure for `.aid/works/{work}/REQUIREMENTS.md` — a first-class methodology artifact produced by [aid-describe](../../skills/aid-describe/) on the full path, or by the shortcut engine on the lite path.

## Usage

- **First run:** aid-describe walks through each section with the stakeholder and fills them in.
- **Subsequent runs:** aid-describe cross-references this file against the Knowledge Base, grades consistency, and asks targeted questions.

## Conventions

- **Change Log is mandatory.** Every modification — initial creation, cross-reference updates, targeted re-interviews — gets an entry.
- **Sections can be marked N/A** if not applicable to the project.
- **`*(pending)*`** marks sections not yet addressed during the interview.
- **Cross-reference runs** add Change Log entries with source `/aid-describe (cross-reference)`.
- **File is uppercase** (`REQUIREMENTS.md`) — it's a first-class artifact at the work root, `.aid/works/{work}/REQUIREMENTS.md`.

---

## Template

```markdown
# Requirements

- **Name:** *(pending)*
- **Description:** *(pending)*

## Change Log

| Date | Change | Source |
|------|--------|--------|
| {date} | Initial interview started | /aid-describe |

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

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-1 | MUST | {what the system does} |

## 6. Non-Functional Requirements

{Performance, security, reliability, scalability targets. Measurable where possible.}

| ID | Modality | Requirement |
|----|----------|-------------|
| NFR-1 | SHOULD | {measurable target} |

## 7. Constraints

{Timeline, budget, team, compliance, technical limitations.}

## 8. Assumptions & Dependencies

{What we're assuming to be true. External dependencies.}

## 9. Acceptance Criteria

{How do we know it's done? Testable conditions for key features.}

| ID | Modality | Criterion |
|----|----------|-----------|
| AC-1 | MUST | Given {precondition}, when {action}, then {expected result}. |

## 10. Priority

{Feature/requirement priority ordering. Must/Should/Could or numbered.}
```

---

## Notes

- Sections not yet discussed during the interview should contain `*(pending)*` as a placeholder.
- The Change Log tracks the full history of the document. Example entries after cross-reference:

  ```
  | 2026-03-15 | Updated NFRs: added latency target from load-test results | /aid-describe (cross-reference) |
  | 2026-03-20 | Revised scope: moved mobile app to Out of Scope per stakeholder | /aid-describe |
  ```

- The stakeholder's own language is preferred in Objective and Problem Statement. Don't rewrite their words into technical jargon.
- Acceptance Criteria should be testable — "the system is fast" is not a criterion; "API response < 200ms p95" is.

## Modality is mandatory, and not for tidiness

Every requirement **and every acceptance criterion** carries a `Modality` of `MUST`, `SHOULD` or
`COULD`. It is the **first thing the severity scale reads**: a MUST violation continues to the
blast-radius step, a SHOULD is `[LOW]`, a COULD is `[MINOR]`. The defect taxonomy's *unmet criterion*
class likewise **inherits** the criterion's modality.

So an untagged criterion is not untidy — it makes every finding against it **ungradeable**, and severity
falls back to the judgment the scale exists to remove. Once a reviewer meets one it becomes a criteria
gap, which blocks the grade and costs a human round trip.

Gated at authoring time by
`.agent/aid/scripts/kb/lint-modality.sh --root .aid/works`, which is strictly cheaper than catching
it during a review.

**Acceptance criteria carry a modality too, and this is the part usually missed.** A criterion the work
*should* meet and one it *must* meet produce different severities for the same failure — recording only
the text loses that distinction.
