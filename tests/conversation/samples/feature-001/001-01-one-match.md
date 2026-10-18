---
id: 001-01-one-match
covers: AC-1
fixture: empty-notes-file
---

## User

Since I saved notes.json as an empty file in my editor, the list command fails with a long error, and add fails too. Can you sort it out?

I maintain this notes tool. I found the problem this morning and want it fixed in the code, not worked around by hand.

## Answer sheet

- You saved notes.json as an empty file by accident, from a text editor.
- Both `list` and `add` fail now with an error; before the accident they worked.
- You want the bug fixed in the code, not by editing the file by hand.
- You do not have the exact error text; if asked for it, say you do not have it.
- You know nothing else about how the code is organised; if asked, say you don't know.
- Once the assistant has said how it will handle this and has asked you to go ahead, reply <<END>>.

## Expected outcome

- The assistant reads the request as a bug fix: something that worked is broken, and the Knowledge Base describes it as working. It says so in one line, with its reason.
- It matches the request to the one workflow that fits, the fix workflow (`/aid-fix`), and proposes that workflow to the user before it changes any code.
- It shows that reading and its reason in the same message as its proposal or question, then waits for the user.
- It does not ask the user to choose between several workflows, because only one fits.

## Must not

- Change any file under `src/` before the user has agreed to the proposal.
- Ask the user to choose between several workflows when only one fits.
- Push anything to a remote.

## Checks

- tool-not-called Edit src/*
- tool-not-called Write src/*
- no-push
