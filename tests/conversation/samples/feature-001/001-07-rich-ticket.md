---
id: 001-07-rich-ticket
covers: AC-7, AC-21
fixture: default
---

## User

Please take this ticket from here, it is complete as written. Objective: let the user export every note to a CSV file for a spreadsheet. Users: the maintainers of the notes tool and the team members who open the exported file in a spreadsheet. Scope: a new `export` command that writes `notes.csv` in the current folder, with a header row and one row per note in insertion order, with the columns id, created and text; the command prints how many rows it wrote. Acceptance criteria: running `export` on a file with three notes writes a header and three rows; running it with no notes writes the header only; running it does not change notes.json; a unit test covers both cases. Constraints: standard library only, no network access, and no change to the existing `add` and `list` output.

## Answer sheet

- The ticket above is complete and correct as written. Everything you know about the request is in it.
- If the assistant asks whether it should start the work, say: carry on, and ask me only when you need my approval before building.
- When the assistant asks you to approve before it builds anything, reply <<END>>.
- If the assistant asks about something the ticket does not cover, say you don't know.
- Do not ask for anything beyond the ticket.

## Expected outcome

- The assistant recognises the complete ticket and takes it straight to requirements and planning, with no brainstorming first, and says so in one line with its reason.
- It sizes the work as lite, one approval before building, and says so in one line with its reason.
- It starts the workflow itself, using the Skill tool, rather than asking the user to type a command.
- There is exactly one approval before building: the assistant asks the user once, before it changes any code, and does not ask for other approvals before that point.

## Must not

- Brainstorm the feature again, or ask the user about the objective, users, scope, acceptance criteria or constraints the ticket already gives.
- Ask for approval more than once before building.
- Raise a Knowledge Base conflict about the export file, or ask for approval of the export file separately from the one approval before building.
- Push anything to a remote.

## Checks

- tool-called Skill
- tool-not-called Skill aid-brainstorm
- tool-not-called Edit src/*
- tool-not-called Write src/*
- no-push
