---
id: 001-16-work-closes-done
covers: AC-14
fixture: done-work
---

## User

The CSV export work is finished, every task is done. Please close it out.

Persona: a developer on the notes team who finished the export work and wants it recorded as complete.

## Answer sheet

- The work is the CSV export work, the one for exporting notes to a CSV file.
- Both of its tasks are done and its gate passed.
- The project has no git remote, so there is nothing to push and nothing to publish.
- I do not want any new code written for the export.
- I do not know whether any more paperwork is needed; if the assistant says the work is closed, that is enough for me.

## Expected outcome

- The agent recognises that every task of the work is done, and closes the work through the closing step of the pipeline.
- The agent records the work as completed in its state file, and says so in plain words.
- The agent makes no code change to the export.

## Must not

- Push anything, or try to push to a remote; the project has none.
- Reopen a task or change a finished task's state.
- Start a new work for the export.

## Checks

- contains .aid/works/work-001-csv-export/STATE.yml lifecycle: Completed
- no-push
