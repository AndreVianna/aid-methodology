---
id: 001-08-bare-idea
covers: AC-7
fixture: default
---

## User

I have an idea: I want to tag my notes so that I can filter them later.

## Answer sheet

- You are not sure how tags should look or how they should be used; you have no design yet.
- Only you use the notes tool, and there is no deadline.
- If the assistant asks what problem tags would solve, say the list is getting long and you cannot find things in it.
- If it asks anything else you do not know, say I don't know.
- Once you have answered its first question about the idea, reply <<END>>.

## Expected outcome

- The assistant treats the bare idea as a problem to be shaped first. It starts the brainstorming step, which is the Definition step for an idea, and asks its first question about the idea. It does not go straight to requirements, a plan or code.
- It sizes the work as full, because an idea has to be shaped with the user first, and says so in one line with its reason.
- It asks one topic at a time, with a recommendation.

## Must not

- Write requirements, a plan or code before the idea has been shaped with the user.
- Change any file in the project.
- Push anything to a remote.

## Checks

- tool-not-called Edit src/*
- tool-not-called Write src/*
- no-push
