---
id: 002-16-research-without-a-question
covers: AC-28
fixture: default
skills: aid-research
---

## User

I want to look into something for the notes tool, we need to decide about its storage. Please research it.

Persona: a developer on the notes team who knows that a decision is coming up but has not yet written down what it is about.

## Answer sheet

- The open decision is whether the notes tool should keep its notes in the JSON file it uses now, or move them to a small database file.
- What matters to you: the notes must stay in one file that a person can copy, and the tool must not need a server to run.
- You have not written the question down in words; if asked for the exact question, say the question is the storage one above.
- You do not know how many notes a user has; if asked, say you do not know.
- If the assistant proposes a way to go (such as `/aid-research`) and asks to go ahead, say yes.
- If it asks something you cannot answer from this sheet, say you do not know.
- Once the assistant has set out the options it weighed, reply <<END>>.

## Expected outcome

- The assistant notices that the request names no question to investigate, and asks for one before it starts the research, with its reason. This opening question is the question protocol's intake exception, so only its missing `Pending` record is excused; it still carries a reason and a recommendation. Any further scoping question follows the protocol in full.
- Its questions for the user are scoped one topic at a time, each with a recommendation, and it does not ask a long list of them at once.
- Once the storage question is clear, the assistant investigates it against the project's code and Knowledge Base and sets out the options it weighed, with what each one costs.
- The assistant does not decide the storage question for the user; it presents the options and says the choice is the user's.

## Must not

- Start the investigation with no question at all, without saying what it is investigating.
- Change any file under `src/` or `tests/`.
- Ask the user several questions in one message without a recommendation for each.
- Push anything, or try to push to a remote.

## Checks

- tool-called Skill aid-research
- tool-not-called Edit *src/*
- tool-not-called Write *src/*
- no-push
