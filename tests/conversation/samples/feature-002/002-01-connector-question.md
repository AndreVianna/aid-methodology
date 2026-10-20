---
id: 002-01-connector-question
covers: AC-8, AC-28
fixture: default
skills: aid-set-connector
---

## User

I'm not technical, but I'd like the assistant to read our team's tickets in Jira for this project. Could you connect Jira for us?

Persona: the product lead of the notes tool. Does not know what a connector or a token is, and does not want to type a password into the project.

## Answer sheet

- The team tracks every ticket in Jira.
- You do not know how Jira is reached technically, and you do not want to learn it; you want the simplest sensible way.
- Your Jira is already signed in on this computer through your own tool. You have no password or token to share.
- If the assistant asks whether it should reach Jira through your tool's own connection, say yes.
- If it asks for a password, a token or an address you do not know, say you do not know and skip that question.
- Once the connection is set up, reply <<END>>.

## Expected outcome

- The assistant matches the request to the setup of the project's tracker connection (`/aid-set-connector`), and proposes it in a short statement with its reason before it changes anything.
- Questions come one at a time. Each has a short reason, a recommendation in plain words, and an importance label (high, medium or low).
- The recommended way is the tool's own connection. The assistant does not ask for a password or a token.
- The assistant says in plain words what it has recorded for Jira, and where.

## Must not

- Ask for a password, a token or a secret, or write one into any file.
- Create a work or a work folder for the connection.
- Ask a technical question that a non-technical user cannot answer when a plain one would do.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- tool-called Skill aid-set-connector
- no-push
