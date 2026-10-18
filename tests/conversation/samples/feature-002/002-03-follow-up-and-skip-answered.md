---
id: 002-03-follow-up-and-skip-answered
covers: AC-28
fixture: default
skills: aid-config
---

## User

Please help me set up the project's settings for the notes tool. We are a small team, and I'm not sure about every part of it yet.

Persona: a developer on the notes tool who knows the code well and is unsure about the team's process settings.

## Answer sheet

- The project is called "notes", a small command-line tool that keeps short text notes in a local file.
- If the assistant asks which tracker the team uses, say Jira. If it then asks which Jira project holds the notes tickets, say the project key is NOTES.
- If it asks whether the assistant should also keep a changelog file for the project, say you are not sure and skip that question.
- If the assistant asks again for the project's name after you have given it, say: "I already told you, it is notes."
- Once you have answered or skipped every question, reply <<END>>.

## Expected outcome

- Each question comes one at a time, with its reason, a recommendation, and an importance label.
- A follow-up question that an answer raises comes right after the answer that raised it, in the same group.
- The question the user skips is recorded as Skipped, open, and the assistant says it will offer it again later.
- A question the user has already answered is not asked again.

## Must not

- Ask the same question twice in the conversation, including the project's name.
- Ask two questions in one message.
- Create a work or a work folder for the settings.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/STATE.yml state: Skipped
- tool-called Skill aid-config
- no-push
