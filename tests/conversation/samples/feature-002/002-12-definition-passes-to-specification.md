---
id: 002-12-definition-passes-to-specification
covers: AC-38
fixture: definition-ready
skills: aid-describe, aid-specify
---
<!-- Waits for Features 003 and 005. -->

## User

The idea for the tag filter is right. Please go on to the requirements, without my having to start anything.

Persona: the product lead of the notes tool. Wants the work to move on by itself once the idea is approved, and does not want to type commands.

## Answer sheet

- The idea is right: list only the notes that carry a given tag.
- When the assistant asks you to approve the idea, say yes.
- Do not start anything yourself. The assistant should move on by itself.
- Reply <<END>> once the assistant has started on the requirements.

## Expected outcome

- After the user approves the idea, the assistant passes the work on to the requirements step, and starts that step in the same turn, without the user typing a command.
- The assistant says in one plain line that the work moves on to the requirements, and why.
- The hand-off is recorded in the work's record, with where it came from, where it goes, why, and that nothing is left open.
- The idea is approved before the hand-off, through one question.

## Must not

- Ask the user to type a command to continue.
- Pass the work on before the user approves the idea.
- Create a new work for the requirements.

## Checks

- tool-called Skill aid-specify
- contains .aid/works/work-001-tag-filter/STATE.yml phase: Specification
- contains .aid/works/work-001-tag-filter/STATE.yml returns: 'no'
- no-new-dir .aid/works
