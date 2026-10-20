# State: FIX-DECISION

The checks failed in VERIFYING. The user decides whether to fix the failures here or loop back to aid-execute.

### Step 3a: Decide

- Show the failures logged in `{{LEDGER}}` (one line each).
- Ask the user, through the question protocol (`.aid/runtime/templates/question-protocol.md`): one question, in
  the question form with **Why I ask** and **My recommendation**, never the host tool's picker. The question is
  fix here (minor) or loop back to aid-execute (non-trivial). Record it first with
  `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Release --impact High --context '<the question, as shown>' --suggested '<the recommendation>' --asked-by aid-deploy --step FIX-DECISION`
  (it prints the question's id), bring the step detail up to date with `--step`, and set the lifecycle to
  `Paused-Awaiting-Input` and the pause reason to the open question through the writer. When the user
  answers, record it with `--answer --id <id> --state <Answered|Skipped> --value '<the answer>' --applied-to '<fix here, or loop back>'`
  and set the lifecycle back to `Running`.
- Fix here is offered while fewer than three fix attempts have been made. After the third failed
  attempt, only the loop back is offered.
- If looping back: set work `STATE.yml`'s Deploy State (`deploy` key) → Idle, keep package file as Draft.
  Delete ledger: `rm -f {{LEDGER}}`. Set the lifecycle to `Paused-Awaiting-Input` and the pause reason to
  'Release checks failed; the failures need work in /aid-execute' through the writer. Then say in one plain line
  that the failures need work in `/aid-execute`.

The question is blocking: this step pauses on it until the user answers, and then goes on with the
branch the user chose.

**Advance:** **CHAIN** → [State: RE-VERIFY] when the user chooses to fix here; **HALT** when the user loops back to
`/aid-execute` (after the writes above).
