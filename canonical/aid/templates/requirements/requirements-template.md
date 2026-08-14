# REQUIREMENTS.md Template

This template defines the structure for `.aid/works/{work}/REQUIREMENTS.md` — a first-class methodology artifact produced by [aid-describe](../../skills/aid-describe/) on the full path, or by the shortcut engine on the lite path.

## Usage

- **First run:** aid-describe walks through each section with the stakeholder and fills them in.
- **Subsequent runs:** aid-describe cross-references this file against the Knowledge Base, grades consistency, and asks targeted questions.

## Conventions

- **No Change Log section.** Git records this document's history — author, date, and full diff — at higher fidelity than a hand-maintained table, and without drift. This is the same reason `.aid/knowledge/` docs carry no Change Log (see the tracking-discipline rule in `CLAUDE.md` / `AGENTS.md`); it applies identically here. Use `git log --follow` on this file.
- **Every acceptance criterion must be verifiable** — see [Verifiable Acceptance Criteria](#verifiable-acceptance-criteria) below. This is the rule downstream SPEC and task DETAIL criteria inherit; both cite this section rather than restating it.
- **Sections can be marked N/A** if not applicable to the project.
- **`*(pending)*`** marks sections not yet addressed during the interview.
- **File is uppercase** (`REQUIREMENTS.md`) — it's a first-class artifact at the work root, `.aid/works/{work}/REQUIREMENTS.md`.

---

## Verifiable Acceptance Criteria

An acceptance criterion states what would prove the work done. If nobody can say
what would prove it **false**, it is not a criterion — it is a hope, and it will
survive every review unchallenged while the document grows around it.

So every criterion must name an **observable**:

| Form | Example |
|------|---------|
| A command and its expected result | `aid --version` prints the value in `VERSION` |
| A file and its expected content | `.aid/settings.yml` contains `minimum_grade` |
| A count derived from disk | every `canonical/skills/*/SKILL.md` has a `description` |
| A measurable threshold | first paint under 200 ms on the reference fixture |
| A user-visible behaviour + how to reproduce it | submitting an empty form shows an inline error naming the empty field |

**Judgment is allowed, but it must be pinned.** Some criteria genuinely need a
person: clarity, tone, whether a design fits. Those are legitimate — but name
*what* is judged and *against what*, so it can at least be verified that the
judgment happened against the stated standard.

- ✗ `The error message is clear.` — nothing would prove this false.
- ✓ `A reviewer confirms the error message names the offending field and the accepted format.` — the standard is stated; a reviewer either confirms it or does not.

**Prefer the form a script could check.** A criterion a script can evaluate costs
nothing to re-verify on every later change; one that needs a reader costs a
dispatch every time. Reach for judgment when the thing being checked is genuinely
a judgment, not when stating the observable is merely more work.

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

{How do we know it's done? One criterion per line, each carrying a stable `AC-N`
id and naming an observable -- see Verifiable Acceptance Criteria above. A
criterion nothing could falsify is not one. Ids are never reused or renumbered:
§11 feature sections and task DETAILs cite them. This is the ONLY place a
criterion is stated -- features cite ids, they do not restate the text.}

- **AC-1** — {criterion}
- **AC-2** — {criterion}

## 10. Priority

{Feature/requirement priority ordering. Must/Should/Could or numbered.}

## 11. Features

{Added by `/aid-define`, one `###` subsection per feature. A feature is a
decomposition of §5 into an independently implementable unit -- not a new place to
state requirements. Every §5 functional requirement maps to at least one feature,
and every §9 criterion is owned by exactly one feature, so both are checkable.}

### Feature 001 — {Title}

- **Priority:** Must | Should | Could
- **Requirements:** §5 FR-{n}[, FR-{n}]
- **Criteria:** AC-{n}[, AC-{n}]  ← ids from §9; never restated here

#### Description

{What this feature delivers, in stakeholder language.}

#### User Stories

{As a {§3 user type}, I want {capability}, so that {benefit}.}

#### Technical Specification

{Added by `/aid-specify`. Leave as this placeholder during /aid-define.}
```

---

## Notes

- Sections not yet discussed during the interview should contain `*(pending)*` as a placeholder.
- Document history is git's job, not this file's. `git log --follow -p` on this path gives every
  change with author, date, and diff.

- The stakeholder's own language is preferred in Objective and Problem Statement. Don't rewrite their words into technical jargon.
- Acceptance Criteria must name an observable — see Verifiable Acceptance Criteria above.
