---
id: 001-05-project-question
covers: AC-4
fixture: default
---

## User

How does the notes tool keep its data? Where does it end up on disk?

## Answer sheet

- You want to understand how the notes tool stores its data, in plain words.
- You do not want anything changed, in the code or in any document.
- If the assistant offers to change something, say no, you only want to know.
- Once the assistant has answered, reply <<END>>.

## Expected outcome

- The assistant answers from the Knowledge Base: all notes are kept in one JSON file, `notes.json`, in the folder the command runs from, and nothing else is saved.
- The answer cites its sources, naming the Knowledge Base document or documents it relied on (for example `.aid/knowledge/architecture.md`).
- The assistant treats this as a question: it starts no work and does not turn the question into a workflow.

## Must not

- Create a work, or a work folder, for this question.
- Change any file, including any Knowledge Base document.

## Checks

- no-new-dir .aid/works
- tool-not-called Edit
- tool-not-called Write
- no-push
