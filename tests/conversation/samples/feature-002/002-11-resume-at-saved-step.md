---
id: 002-11-resume-at-saved-step
covers: AC-37
fixture: interrupted-specify
skills: aid-specify
---
<!-- Waits for Feature 005. -->

## User

I'm back. The session was cut off earlier. Let's carry on with the tag filter requirements.

Persona: the product lead of the notes tool, back after lunch. Does not remember the details of the earlier session and expects the assistant to pick up where it stopped.

## Answer sheet

- Carry on where the draft stopped. You do not remember the details of the earlier session.
- The sections already written are fine as they are.
- On the open question about how many tags a note may carry: several tags are allowed.
- Reply <<END>> once the assistant has moved on to the section after the one that was cut off.

## Expected outcome

- The assistant reads the saved state and continues at the step the work's record names, without starting the draft again from the top.
- The assistant says where the work stands in plain words: what is written, what is next, and the open question.
- The open question is asked first, as one question with its reason and a recommendation.
- The assistant shows the user no banner, no bracketed step name, and no line that tells the user to run a command again.

## Must not

- Print a banner, a bracketed step name, or a line such as "re-run the command to continue".
- Create a new work or a new work record for the same work.
- Rewrite the sections that are already written.

## Checks

- no-new-dir .aid/works
- tool-not-called Bash *--create*
- no-push
