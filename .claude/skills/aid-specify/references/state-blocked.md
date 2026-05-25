# State: BLOCKED

> **Source:** `references/handling-outcomes.md` §"Blocked (State 4)" (the body below is preserved verbatim from there for state-file self-containment).

Feature STATUS is `Blocked` with a loopback pending; check each pending loopback for resolution.

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

**Advance:** Next state is `CONTINUE` — when the block is resolved, router prints `Next: [State: CONTINUE] — run /aid-specify again` and exits.
