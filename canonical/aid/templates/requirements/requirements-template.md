# REQUIREMENTS.md Template

This template defines the structure for `.aid/works/{work}/REQUIREMENTS.md` — a first-class methodology artifact produced by [aid-describe](../../skills/aid-describe/) on the full path, or by the shortcut engine on the lite path.

## Usage

- **First run:** aid-describe walks through each section with the stakeholder and fills them in.
- **Subsequent runs:** aid-describe cross-references this file against the Knowledge Base, grades consistency, and asks targeted questions.

## Conventions

- **No Change Log section.** Git records this document's history — author, date, and full diff — at higher fidelity than a hand-maintained table, and without drift. This is the same reason `.aid/knowledge/` docs carry no Change Log (see the tracking-discipline rule in `CLAUDE.md` / `AGENTS.md`); it applies identically here. Use `git log --follow` on this file.
- **Sections can be marked N/A** if not applicable to the project.
- **`*(pending)*`** marks sections not yet addressed during the interview.
- **File is uppercase** (`REQUIREMENTS.md`) — it's a first-class artifact at the work root, `.aid/works/{work}/REQUIREMENTS.md`.

---

## Template

```markdown
# Requirements

- **Name:** *(pending)*
- **Description:** *(pending)*

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
- Document history is git's job, not this file's. `git log --follow -p` on this path gives every
  change with author, date, and diff.

- The stakeholder's own language is preferred in Objective and Problem Statement. Don't rewrite their words into technical jargon.
- Acceptance Criteria should be testable — "the system is fast" is not a criterion; "API response < 200ms p95" is.
