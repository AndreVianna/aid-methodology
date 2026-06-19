# State: BLOCKED

> **Source:** `references/handling-outcomes.md` §"Blocked (State 4)" (the body below is preserved verbatim from there for state-file self-containment).

Feature State is `Blocked` with a loopback pending; check each pending loopback for resolution.

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

Emit pipeline pause signal (silent state-write — no output, no gate):
```
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "Blocker pending — awaiting loopback resolution before /aid-specify can continue"
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **PAUSE-FOR-USER-ACTION** → blocker resolution happens outside /aid-specify (Discovery loopback, requirement clarification, or upstream phase fix). Re-run `/aid-specify` after the blocker clears to continue to [State: CONTINUE].
