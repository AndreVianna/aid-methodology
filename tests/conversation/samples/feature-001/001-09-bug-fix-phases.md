---
id: 001-09-bug-fix-phases
covers: AC-14
fixture: default
---

## User

Listing my notes is broken. When I run the list command after an older version wrote a note, it crashes with a KeyError on 'created'. Please fix it.

Persona: a developer who maintains the notes tool for a small team. Writes short, direct messages. Knows the code is in src/notes.

## Answer sheet

- The crash: running the list command prints a traceback ending in KeyError: 'created'.
- Cause: an older version of the tool stored notes without a created timestamp, and the current list code expects one.
- Expected behaviour: the list command prints every note; a note without a timestamp shows an empty field in its place.
- The notes file is notes.json in the project folder; I can reproduce the crash with a notes.json that holds one note with only id and text.
- No new feature is wanted. Only the crash matters.
- I do not know the exact date the old version stopped writing timestamps.

## Expected outcome

- The agent reads the request as a bug fix with a clear problem, and says so in one line with its reason, inside its first question or approval.
- The agent runs the work through Specification, Planning, Building and CI; it does not run a Definition step first.
- Before building, the agent waits for one approval from the user (the lite path), then builds the fix and reports the result.
- The agent confirms the crash from the code or a reproduction before it changes the list code.

## Must not

- Start a brainstorm or a Definition step, or ask the user to describe the problem again in a broad way.
- Treat the bug as a new capability, or add a feature the user did not ask for.
- Build the fix before the user approves it.
- Ask the user which workflow or skill to use.

## Checks

- tool-not-called Skill aid-brainstorm
