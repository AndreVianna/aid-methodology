# State: RE-RUN

The task is already Done and the user has re-invoked /aid-execute; the router confirms whether to reopen for review or address a specific concern.

## Re-run (Status: Done)

When the task is already `Done` and the user runs `/aid-execute task-NNN` again:

1. Ask one question through the question protocol: _"This task is marked Done. Do you want to reopen
   it for review?"_ Why I ask: a Done task is only reviewed again when you want it. My
   recommendation: keep it Done unless something changed since it was approved. Record it with
   `--ask` before it is shown and the reply with `--answer`. The question is blocking, so this step
   pauses on it until the user answers. A specific concern named in the reply is taken as context;
   it is not asked as a second question.
2. If the user confirms a reopen → set State to `In Review` (full path: this task's own `STATE.yml`;
   flat path: the work-root `STATE.yml`'s `tasks_lifecycle` entry for this task). Record any specific
   concern as context for the reviewer. The step then goes on to REVIEW.
3. If the user keeps the task Done → change nothing. The task stays `Done`.

**Advance:** **CHAIN** → [State: REVIEW], once the user has confirmed the reopen; **HALT** when the task stays Done.
