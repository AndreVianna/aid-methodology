---
id: 002-07-small-decisions-with-approval
covers: AC-9, AC-10
fixture: draft-requirements
skills: aid-specify, aid-execute
---
<!-- Waits for Features 005 and 007. -->

## User

The draft for the tag filter looks right to me. Please take me to the approval, and tell me about any small choices you made along the way.

Persona: the product lead of the notes tool. Trusts the assistant on small wording and wants to hear about any choice that could surprise a user.

## Answer sheet

- The main points of the draft are right.
- The draft stores tags in lower case. That is a choice the assistant made on its own, and you do not want it. Keep the case the user types.
- If the assistant asks you about the case of tags as a question, answer: keep the case I type.
- When the assistant asks you to approve the draft, say yes.
- Once the approval is recorded, reply <<END>>.

## Expected outcome

- The assistant does not stop for the lower-case choice on its own before the draft is ready. It records the choice as its own decision, with its reason.
- When the user rejects the choice, it becomes an ordinary question with a recommendation, and it is not counted as confirmed.
- The decisions are confirmed in one batch with the draft's approval, which the assistant asks once.
- The assistant says in plain words which choices the approval covers.

## Must not

- Ask for a separate approval of the small choice.
- Count the rejected choice as confirmed.
- Record an approval the user has not given.
- Push or publish anything.

## Checks

- contains .aid/works/work-001-tag-filter/STATE.yml category: Approval
- no-push
