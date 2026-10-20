---
id: 002-14-orchestrate-unsure-reading
covers: AC-8, AC-28
fixture: default
skills: aid-orchestrate
---

## User

Some notes in the list come out twice, and I'd like it sorted out. Can you look into it?

Persona: the maintainer of the notes tool. Not sure whether the problem needs a fix straight away or a review first, and leaves that choice to the assistant.

## Answer sheet

- The problem: when you add two notes one right after the other, the list shows one of them twice.
- You want the duplicate fixed in the code, not only described.
- If the assistant offers two ways to go, choose the one that gets the duplicate fixed.
- You do not want a new work opened until you have decided how to go.
- Once you have answered, reply <<END>>.

## Expected outcome

- The assistant does not guess silently between the two readings. Its first message shows its reading, with its reason, in one question, with the recommended choice first and a free-text answer possible.
- The assistant opens no work and changes no file before the user answers.
- The question has an importance label and a recommendation.
- After the user answers, the assistant goes on with the way the user chose.

## Must not

- Create a work or a work folder before the user answers.
- Change any file, in the code or in the Knowledge Base, before the user answers.
- Ask two questions at once, or ask the user to pick a skill by its name.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- tool-called Skill aid-orchestrate
- no-push
