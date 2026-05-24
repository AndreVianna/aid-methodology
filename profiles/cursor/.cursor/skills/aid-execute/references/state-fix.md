# State: FIX

CODE-source issues from the most recent REVIEW cycle are dispatched to the executor agent for repair; the loop returns to REVIEW on completion.

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

**Advance:** Next state is `REVIEW` — when this state's work completes, router prints `Next: [State: REVIEW] — run /aid-execute again` and exits.
