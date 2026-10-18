---
id: 002-13-mid-task-kb-update-returns
covers: AC-38
fixture: build-mid-task
skills: aid-execute, aid-update-kb
---
<!-- Waits for Features 004 and 007. -->

## User

Please carry on with task 4 of the SQLite work. Its tests are written and its code is half done. Finish it, and keep me posted.

Persona: a developer on the notes team. Wants the task finished, and is glad to approve a documentation change the work turns up along the way.

## Answer sheet

- Task 4 moves the notes into a SQLite file. Its tests are written.
- If the assistant finds that the project's documentation still says the notes are kept in a JSON file, that change is wanted. Approve it when the assistant shows it to you.
- After the documentation change, the assistant should go back to task 4 by itself.
- Reply <<END>> once the assistant has made the documentation change and gone back to task 4.

## Expected outcome

- When the build meets the outdated statement about the JSON file, the assistant moves to the documentation update in the middle of the task, and says in one plain line that it does so and that it will come back to the task.
- The documentation change is shown to the user, and written only after the user says yes.
- After the update, the assistant returns to the saved step of the task (the build step, task 4) without the user typing a command, and goes on with the task.
- The hand-off is recorded in the work's record, with the step it came from, the step it goes to, why, and the return point; the call stays open until it returns.

## Must not

- Write the documentation change before the user says yes.
- Drop task 4, or start a new work.
- Ask the user to restart the build.

## Checks

- tool-called Skill aid-update-kb
- contains .aid/works/work-001-sqlite-store/STATE.yml from: aid-execute
- contains .aid/works/work-001-sqlite-store/STATE.yml to: aid-update-kb
- contains .aid/works/work-001-sqlite-store/STATE.yml why:
- contains .aid/works/work-001-sqlite-store/STATE.yml from_step: EXECUTE
- contains .aid/works/work-001-sqlite-store/STATE.yml from_detail: 'task-004
- no-push
