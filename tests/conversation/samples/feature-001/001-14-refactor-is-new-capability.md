---
id: 001-14-refactor-is-new-capability
covers: AC-1
fixture: default
---

## User

Please refactor the notes tool so I can search my notes by a word. I want to type a word and see only the notes that contain it.

Persona: a developer who uses the notes tool every day. Calls the change a refactor because the code is being reorganised, but cares only about the result.

## Answer sheet

- The notes tool has no search today; there is only add and list.
- I want a new search command that prints the notes whose text contains a given word.
- Matching is case-insensitive.
- Nothing else in the tool should change; the add and list commands keep working as they do.
- I do not know whether the tests need changes; that is for the agent to decide.

## Expected outcome

- The agent checks the request against the code, sees that a search command adds behaviour the tool does not have today, and reads the request as a new capability, not as a refactor.
- The agent says so in one line with its reason, inside its first question or approval.
- The agent runs the work through Specification, Planning, Building and CI, with the approval the lite path needs before building.
- The agent does not claim that the behaviour is unchanged.

## Must not

- Keep the refactor label and carry the work out as a change that keeps behaviour the same.
- Build the search command before the user approves the work.
- Run a Definition step, since the problem is clear.

## Checks

- tool-not-called Skill aid-refactor
- tool-not-called Skill aid-brainstorm
