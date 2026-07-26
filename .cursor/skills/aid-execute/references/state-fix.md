# State: FIX

CODE-source issues from the most recent REVIEW cycle are dispatched to the executor agent for repair; the loop returns to REVIEW on completion.

> ⚠️ **State-Write Protocol note:** this state does NOT write the task's
> `State` field itself -- the task correctly stays `In Review` for the
> entire FIX loop (it is still awaiting a reviewer verdict; `In Progress`
> would be wrong since EXECUTE already completed, and `Done` would be
> premature). The mandate in `references/state-execute.md § MANDATORY:
> State-Write Protocol` is satisfied by the transitions that bracket this
> loop (EXECUTE's `In Review` write before entry; REVIEW's terminal `Done`/
> `Failed` write on exit) -- do not add a redundant write here, and do not
> skip either of those bracketing writes on the theory that "FIX will handle
> it."

## Step 4: FIX

Dispatch agent with:
- Issues from STATE.md where Source = CODE and Status = Pending
- Original task context

**Agent fixes CODE issues only.** Verifies gates still pass.

When done:
1. Mark fixed issues as `Fixed` in STATE.md
2. → **Back to Step 2 (REVIEW)** — fresh reviewer, clean context

**Loop continues until grade ≥ minimum.**

⚠️ **Circuit breaker:** If grade has not improved after 3 consecutive
cycles (same or worse), **STOP.** Something systemic is wrong.

**Advance:** **CHAIN** → [State: REVIEW] (continue inline).
