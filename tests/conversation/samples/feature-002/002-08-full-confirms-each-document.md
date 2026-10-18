---
id: 002-08-full-confirms-each-document
covers: AC-10
fixture: draft-requirements
skills: aid-specify, aid-plan
---
<!-- Waits for Features 003, 005, 006 and 007. -->

## User

Please take the tag filter through its documents with me, one at a time. I want to approve each document before the next one starts.

Persona: the product lead of the notes tool. Wants to decide on every document, and does not want anything started before the document it depends on is approved.

## Answer sheet

- The requirements draft is right; approve it when the assistant asks.
- The plan will split the work into deliveries. Read what the assistant shows you, and approve it when it asks.
- Do not expect the plan to be approved together with the requirements. Each one is its own question.
- Once the plan is approved, reply <<END>>.

## Expected outcome

- Each document is approved on its own: the requirements before the plan is written, and the plan after it is shown.
- The assistant does not combine the approvals into one question.
- Each approval question says which document it covers and lists the decisions it confirms, in plain words.
- Each approval is recorded in the work's record with the document it covers.

## Must not

- Start the plan before the requirements are approved.
- Record an approval the user has not given.
- Push or publish anything.

## Checks

- contains .aid/works/work-001-tag-filter/STATE.yml category: Approval
- no-push
