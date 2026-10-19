# State: FIX-DECISION

The checks failed in VERIFYING. The user decides whether to fix the failures here or loop back to aid-execute.

### Step 3a: Decide

- Show the failures logged in `{{LEDGER}}` (one line each).
- Ask user: fix here (minor) or loop back to aid-execute (non-trivial)?
- Fix here is offered while fewer than three fix attempts have been made. After the third failed
  attempt, only the loop back is offered.
- If looping back: set work `STATE.yml`'s Deploy State (`deploy` key) → Idle, keep package file as Draft.
  Delete ledger: `rm -f {{LEDGER}}`. Set the lifecycle to `Paused-Awaiting-Input` and the pause reason to
  'Release checks failed -- fix with /aid-execute, then run /aid-deploy again' through the writer. Then name
  `/aid-execute` as the skill to run next, in one plain line.

The question is blocking: this step pauses on it until the user answers, and then goes on with the
branch the user chose.

**Advance:** **CHAIN** → [State: RE-VERIFY] when the user chooses to fix here; **HALT** when the user loops back to
`/aid-execute` (after the writes above).
