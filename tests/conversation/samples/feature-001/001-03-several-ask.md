---
id: 001-03-several-ask
covers: AC-2
fixture: default
---

## User

The notes project has got messy. Clean it up for me.

I have not looked at the code for a while, so I do not have a list of problems.

## Answer sheet

- You have no particular picture of the mess; you only feel the project needs tidying.
- You do not know the different kinds of clean-up that exist. If the assistant asks what kind of clean-up it should do, say you do not know, and ask it what it would recommend.
- No behaviour the users see may change.
- Once the assistant has asked its question and given its recommendation, reply <<END>>.

## Expected outcome

- The assistant sees that several kinds of clean-up could fit this request, and that the request alone does not say which is meant.
- It asks exactly one question, about which kind of clean-up the user means. Its options are valid kinds of clean-up for this project, and it gives its own recommendation together with that question.
- It does not start any work and does not change any file before the user answers.

## Must not

- Ask several questions at once.
- Start building, or change any file in the project, before the user has answered.

## Checks

- tool-not-called Edit src/*
- tool-not-called Write src/*
- no-push
