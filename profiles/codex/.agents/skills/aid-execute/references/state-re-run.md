# State: RE-RUN

The task is already Done and the user has re-invoked /aid-execute; the router confirms whether to reopen for review or address a specific concern.

## Re-run (Status: Done)

When the task is already `Done` and the user runs `/aid-execute task-NNN` again:

```
[State: RE-RUN] — Task already Done; confirming whether to reopen for review.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [✓ REVIEW ] → [✓ FIX ] → [✓ DONE ] → [● RE-RUN ]
```

1. Ask: _"This task is marked Done. Do you want to reopen it for review?
   Is there something specific you want to re-examine?"_
2. If user confirms → set Status to `In Review` in work `STATE.md` `## Tasks Status`, proceed to Step 2 (REVIEW)
3. If user has a specific concern → record it as context for the reviewer

**Advance:** **PAUSE-FOR-USER-DECISION** → this is a human-gated decision point. The router prints the prompt above and exits; the user re-invokes `/aid-execute` with their answer to continue to [State: REVIEW] or [State: DONE] depending on the decision.
