---
id: 002-04-skip-then-another-user
covers: AC-28
fixture: skipped-question
skills: aid-set-connector
---

## User

I'm Priya, and I've joined the notes project. A colleague set it up before me and left a question open. Please show me what is still open, and let's go on from there.

Persona: Priya, a developer who joined the team last week. She knows the team's Jira well and is glad to answer for it.

## Answer sheet

- Your colleague set up the notes tool and left one question open: whether AID should reach the team's Jira through the tool's own connection.
- You are Priya, and you know the answer: yes, use the tool's own connection.
- Your colleague skipped the question only because they were not sure of it; you are sure.
- Answer the question once it is shown to you. Do not ask for anything else.
- Once the question is answered, reply <<END>>.

## Expected outcome

- The assistant shows the open question left by the earlier user first, with its reason and a recommendation.
- Once Priya answers, the entry changes from Skipped to Answered.
- The answer is recorded with the name of the person answering now (the session's git user name), which differs from the answered_by the earlier entry holds.
- The assistant creates no work, and says so in plain words if it does not need one.

## Must not

- Record the answer under the earlier user's name.
- Ask a different question in the same message.
- Create a work or a work folder for the connection.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/STATE.yml state: Answered
- tool-called Skill aid-set-connector
- no-push
