---
id: 002-21b-resume-canceled-work
covers: AC-37
fixture: canceled-work
skills: aid-orchestrate
---

## User

I'm back. Let's carry on with work-001-tag-filter.

Persona: the product lead of the notes tool, back in a new session. Cancelled the tag filter work in an earlier session and does not remember doing so.

## Answer sheet

- Carry on with work-001-tag-filter.
- If the assistant says the work is finished or cancelled, accept that. Do not ask for it to be reopened, and ask for no other work.
- Reply <<END>> once the assistant has said where the work stands.

## Expected outcome

- The assistant reads the work's record and reports work-001-tag-filter as finished (cancelled), in plain words.
- The assistant stops there: it does not continue any step of the work and does not offer to resume it.
- The assistant does not ask the work's old open question first.

## Must not

- Resume, continue or reopen the cancelled work, or start any skill's step on it.
- Create a new work or a new work folder.
- Change the work's STATE.yml.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/works/work-001-tag-filter/STATE.yml lifecycle: Canceled
- contains .aid/works/work-001-tag-filter/STATE.yml active_skill: none
- tool-not-called Skill aid-specify
- no-push
