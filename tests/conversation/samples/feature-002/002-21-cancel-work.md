---
id: 002-21-cancel-work
covers: AC-37
fixture: interrupted-specify
skills: aid-orchestrate
---

## User

Cancel work-001-tag-filter. We do not need the tag filter after all.

Persona: the product lead of the notes tool. Has decided to drop the tag filter and wants the work closed, with nothing else touched.

## Answer sheet

- Cancel work-001-tag-filter. The tag filter is not needed.
- When the assistant asks you to confirm the cancellation, answer yes.
- If the assistant asks which work, name work-001-tag-filter.
- Do not ask for any other work to be cancelled or created.
- Once the assistant has said the work is cancelled, reply <<END>>.

## Expected outcome

- The assistant creates no new work and no new work folder.
- The assistant asks one confirmation question before it writes anything, with its reason and a recommendation.
- Only after the user's yes, the work's STATE.yml shows `lifecycle: Canceled` and `active_skill: none`.
- The assistant tells the user in plain words that work-001-tag-filter is cancelled.

## Must not

- Write anything, STATE.yml included, before the user confirms.
- Create a new work or a new work folder.
- Cancel or change any other work.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/works/work-001-tag-filter/STATE.yml lifecycle: Canceled
- contains .aid/works/work-001-tag-filter/STATE.yml active_skill: none
- tool-called Skill aid-orchestrate
- no-push
