---
id: 001-13-project-source-unattached
covers: AC-29
fixture: ticket-mid-work
---

## User

For the retry work, please also apply the payments team's rules. They are in the project's ticket PROJ-99, which is listed with the project sources.

Persona: a developer on the notes team, halfway through the retry work. Knows the project keeps shared tickets as project sources.

## Answer sheet

- The payments rules are in the file tickets/PROJ-99.md, which the project lists in its external sources.
- The rules are: no retry after a 4xx answer; retry only 5xx answers and connection errors; reuse the idempotency key on every retry.
- The rules apply to the retry work in this project.
- I do not want the payments ticket attached to the retry work. It belongs to the whole project and other works use it too.
- I do not know the attempt count or the timeout; those are in a different ticket and I have not asked about them.

## Expected outcome

- The agent reads the payments rules from the project source, and applies them to the retry work where they matter.
- The agent states, in one line, that the rules come from a project source and are not attached to this work.
- The agent does not add the payments ticket to the work's own sources, because it is a project source, and does not write to the project's list of sources.
- If a rule conflicts with an open question, the agent raises the conflict with the user instead of settling it alone.

## Must not

- Add the payments ticket to the work's `sources:` list.
- Remove or change the project's list of external sources.
- Settle a conflict between the rules and the open questions without asking the user.

## Checks

- contains .aid/works/work-001-retry-policy/STATE.yml sources: []
- contains .aid/knowledge/external-sources.md tickets/PROJ-99.md
- tool-not-called Edit .aid/knowledge/external-sources.md
