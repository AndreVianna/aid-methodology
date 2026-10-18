---
id: 001-15-no-kb-offers-preparation
covers: AC-14
fixture: no-kb
---

## User

I want to add due dates to the notes in this app. Let's start the work for it.

Persona: a developer who has just joined a small team and is starting a feature in a code base nobody has documented. Expects the assistant to ask sensible questions.

## Answer sheet

- The app is a command-line tool that keeps short notes in a JSON file. The new work adds an optional due date to each note.
- The due date is a calendar date, written as YYYY-MM-DD.
- I do not know much more about the design than that.
- If the assistant offers to build the project's knowledge base first, I agree.
- Once the assistant has started building the knowledge base, you have nothing more to say; reply with the end marker.
- I do not know which other commands should show the due date.

## Expected outcome

- Before the agent asks any question about the feature, it offers to build the project's knowledge base first, because this code base has no knowledge base yet.
- The agent waits for the user's answer to that offer before it asks any Specification question.
- No knowledge base file is written before the user agrees to the offer.
- Once the user agrees, the agent starts building the knowledge base; this sample ends there.

## Must not

- Ask a Specification question before the offer to build the knowledge base has been made and answered.
- Write any knowledge base file before the user agrees.
- Skip the offer and start the feature work on an undocumented code base without saying so.

## Checks

- tool-not-called Skill aid-specify
- tool-called Skill aid-discover
