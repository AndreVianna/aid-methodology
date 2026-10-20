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
- The notes tool's code already exists (brownfield) and the team keeps it in git.
- If the assistant proposes a way to go (such as `/aid-config`) and asks to go ahead, say yes.
- If asked for a one-line description of the project, say: "A small command-line tool that keeps short text notes in a local file."
- If asked about the minimum grade, say you are not sure and that you want to skip that question.
- If asked about the heartbeat interval, first answer "every few minutes". If the assistant then says it needs a whole number of minutes and asks again, answer 5.
- If the assistant asks again for the project's name after you have given it, say: "I already told you, it is notes."
- Once you have answered or skipped every question, reply <<END>>.

## Expected outcome

- Each question comes one at a time, with its reason, a recommendation, and an importance label.
- When an answer raises a follow-up question (for example, a value that fails validation and must be asked for again), it comes right after the answer that raised it, in the same group.
- The question the user skips (the minimum grade) is recorded as Skipped, stays open, and the assistant says it will offer it again later.
- A question the user has already answered is not asked again.

## Must not

- Ask the same question twice in the conversation, including the project's name, unless an answer failed validation and the question must be asked again.
- Ask two questions in one message.
- Create a work or a work folder for the settings.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/STATE.yml state: Skipped
- tool-called Skill aid-config
- no-push
