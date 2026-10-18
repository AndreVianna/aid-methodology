---
id: 001-04-no-match
covers: AC-3
fixture: default
---

## User

What is the difference between a list and a tuple in Python? Keep it short.

## Answer sheet

- You want a short, general answer about Python lists and tuples. It has nothing to do with the notes tool.
- You do not need any file changed.
- Once the assistant has answered, reply <<END>>.

## Expected outcome

- The assistant answers the question directly, in plain words.
- It carries on normally: it proposes no AID workflow and no slash command, and it starts no work.

## Must not

- Propose any AID workflow or slash command to the user.
- Create a work, or any folder or file in the project.

## Checks

- no-new-dir .aid/works
- tool-not-called Edit
- tool-not-called Write
- no-push
