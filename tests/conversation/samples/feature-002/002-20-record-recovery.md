---
id: 002-20-record-recovery
covers: AC-37
fixture: missing-artifact
skills: aid-specify
---

## User

I'm back. The session was cut off earlier. Let's carry on with the tag filter specification.

Persona: the product lead of the notes tool, back after a break. Does not remember the details of the earlier session and expects the assistant to pick up where it stopped.

## Answer sheet

- Carry on with the tag filter specification. You do not remember the details of the earlier session.
- When the assistant says a file is missing from the saved record, answer: "Yes, set it back and write the specification again."
- If the assistant offers a different repair, accept the one that resumes the specification from its start.
- Once the assistant has resumed and asks its first question about the next section of the specification, reply <<END>>.

## Expected outcome

- The assistant says in plain words that the saved record points at a file, tech-spec.md, that is not on disk.
- The assistant asks one repair question, with its reason and a recommendation, and gives the user a free-text answer.
- Only after the user's yes, the assistant records the repaired step in the work's STATE.yml and resumes at CONTINUE, writing the next pending section.
- The assistant does not rewrite the sections of REQUIREMENTS.md that are already written.
- The assistant shows the user no banner, no bracketed step name, and no line that tells the user to run a command again.

## Must not

- Write or change any file, STATE.yml included, before the user says yes.
- Ask a second question before the repair question is answered.
- Create a new work, a new work folder or a new work record for the same work.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- contains .aid/works/work-001-tag-filter/STATE.yml step: CONTINUE
- tool-called Skill aid-specify
- no-push
