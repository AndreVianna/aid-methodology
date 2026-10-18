---
id: 002-09-lite-one-approval
covers: AC-10
fixture: draft-lite-requirements
skills: aid-specify, aid-plan, aid-execute
---
<!-- Waits for Features 005, 006 and 007. -->

## User

Please take the tag filter from the draft to a build, and keep the questions to a minimum. I will look at the result when it is ready.

Persona: a developer on the notes team, in a hurry. Wants a short route and is happy to confirm once, as long as the confirmation says what it covers.

## Answer sheet

- The draft is right; accept it as it is.
- Do not ask to see the requirements or the plan separately. You trust the assistant on them.
- If the assistant asks you to confirm before it starts building, say yes.
- If the assistant asks about a small choice on the way, accept its recommendation.
- Once the build is confirmed, reply <<END>>.

## Expected outcome

- The work runs in the lite depth: the assistant asks for approval once, before building, and asks for no approval of the requirements or the plan on their own.
- The one confirmation says in plain words what it covers, including the small decisions taken on the way.
- The approval is recorded in the work's record with the decisions it covers.

## Must not

- Ask for a separate approval of the requirements or of the plan.
- Start building before the one confirmation.
- Push or publish anything.

## Checks

- contains .aid/works/work-001-tag-filter/STATE.yml category: Approval
- no-push
