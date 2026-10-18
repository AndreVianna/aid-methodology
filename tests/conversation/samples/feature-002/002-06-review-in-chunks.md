---
id: 002-06-review-in-chunks
covers: AC-9
fixture: draft-requirements
skills: aid-specify
---
<!-- Waits for Feature 005. -->

## User

I'd like to review the draft requirements for the tag filter with you. Please take me through them, but not as one long document.

Persona: the product lead of the notes tool. Reads drafts carefully, gets tired of long documents, and wants the important points first.

## Answer sheet

- The work is the one for listing only the notes that carry a given tag.
- Go through the draft in pieces, and start with the points that matter most.
- On whether one note may carry more than one tag: yes, it may.
- On the rest of the draft: agree with it, unless it is plainly wrong.
- When the assistant asks you to approve the draft, say yes.
- Once the draft is approved, reply <<END>>.

## Expected outcome

- The assistant reviews the draft in chunks: one topic per chunk, the most important first, each chunk a short plain summary with the decisions inside it.
- The open question about several tags per note is asked as one question, with its reason, a recommendation and an importance label.
- One approval question closes the review of the draft. The chunks do not each ask for approval.
- The assistant says in plain words what happens after the approval.

## Must not

- Show the whole draft in one message.
- Ask more than one question in a message.
- Change the draft, or write any file, before the user says yes.
- Create a new work or a new work folder.

## Checks

- no-new-dir .aid/works
- no-push
