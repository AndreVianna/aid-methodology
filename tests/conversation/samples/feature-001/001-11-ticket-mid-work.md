---
id: 001-11-ticket-mid-work
covers: AC-29
fixture: ticket-mid-work
---

## User

I'm partway through the retry work. The ticket for it, PROJ-42, was updated yesterday. The new details are in tickets/PROJ-42.md, so please use them.

Persona: a developer on the notes team, halfway through a feature. Writes plainly and expects the assistant to keep track of what is open.

## Answer sheet

- The ticket is the file tickets/PROJ-42.md in this project.
- The retry work is the one already open in this project; it has two open questions, Q4 and Q6.
- The ticket says the new number of attempts and the new timeout. Those are the answers.
- I do not want anything written back to the ticket.
- I do not know anything about the payments rules; that is a separate ticket and I have not asked about it.

## Expected outcome

- The agent reads the ticket file and applies its details to the open work.
- The agent adds an entry for the ticket to the work's own sources, with the file as its ref and the kind ticket.
- The agent closes each open question that the ticket answers, and names the ticket as the source of each answer.
- The agent says how the ticket changed the work in one line, and does not move the work to a new phase without the conditions for that phase being met.

## Must not

- Write anything back to the ticket, or change the ticket file.
- Add the ticket to the project's own list of sources, or to the knowledge base.
- Leave Q4 or Q6 open when the ticket answers them.

## Checks

- contains .aid/works/work-001-retry-policy/STATE.yml ref: 'tickets/PROJ-42.md'
- contains .aid/works/work-001-retry-policy/STATE.yml kind: ticket
- contains .aid/works/work-001-retry-policy/STATE.yml 5 attempts
- contains .aid/works/work-001-retry-policy/STATE.yml 30 seconds
- tool-not-called Edit tickets/PROJ-42.md
- tool-not-called Write tickets/PROJ-42.md
