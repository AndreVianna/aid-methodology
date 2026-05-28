# State: BLOCKED

> **Source:** `references/handling-outcomes.md` §"Blocked (State 4)" (the body below is preserved verbatim from there for state-file self-containment).

Feature STATUS is `Blocked` with a loopback pending; check each pending loopback for resolution.

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

**Advance:** **PAUSE-FOR-USER-ACTION** → blocker resolution happens outside /aid-specify (Discovery loopback, requirement clarification, or upstream phase fix). Re-run `/aid-specify` after the blocker clears to continue to [State: CONTINUE].
