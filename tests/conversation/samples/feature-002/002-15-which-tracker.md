---
id: 002-15-which-tracker
covers: AC-28
fixture: two-trackers
skills: aid-read-ticket
---

## User

Can you show me what ticket PROJ-42 says? It's the retry policy one.

Persona: a product owner who keeps the team's tickets in two places, the engineering tracker and the product tracker. Does not know the names of the connectors and does not care how they are set up.

## Answer sheet

- The ticket is PROJ-42, about the retry policy for the sync job.
- It lives in the engineering tracker, the one the team calls Jira.
- You do not know the names of the connectors or how they are set up; if asked which connector to use, answer with the team's name for it, Jira.
- You do not know whether the ticket has attachments; if asked, say you do not know.
- Once the assistant has shown the ticket's fields, or has said it cannot fetch the ticket, reply <<END>>.

## Expected outcome

- The assistant reads the request as a request to show one ticket, and sees that the project has two issue-tracker connectors catalogued, so it cannot pick one silently.
- It asks which tracker the ticket is in, as one question, listing both trackers by their names, with its recommendation and the reason for it.
- It waits for the user's answer before it fetches anything.
- After the answer, it fetches or tries to fetch the ticket from the named tracker, and says plainly what it found or why it could not fetch it.

## Must not

- Pick one of the two trackers without asking when both are catalogued.
- Ask more than one question at a time, or ask a question whose options are not real trackers of this project.
- Change, file or comment on any ticket, or write any file in the project.
- Push anything, or try to push to a remote.

## Checks

- tool-called Skill aid-read-ticket
- tool-not-called Write *
- tool-not-called Edit *
- no-push
