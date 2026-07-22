# State: APPROVAL

APPROVAL is the explicit human gate before the KB change is committed. It is
selected when the run-state file records `**State:** APPROVAL`.

**Human-gated (NFR-6/C4/AC13).** Detection and grading are automatic; the
change to KB content cannot proceed to DONE without an explicit human `[1]`.
No auto-apply path exists -- DONE is unreachable from this state without a
human `[1] Approved`.

**Pattern reuse.** This state reuses `aid-discover`'s approval-gate pattern
(`.agent/skills/aid-discover/references/state-approval.md`: `[1]`/`[2]`
prompt, consideration loop), scoped to the `aid-update-kb` context -- with one
deliberate deviation: `[2]` here re-scopes back to CONFIRM/SCOPE, not APPLY
(see Step 3).

Print the `[State: APPROVAL]` banner from `SKILL.md § State Detection`.

---

## Step 1: Present the diff summary

Read the following from `<STATE_FILE>`:
- `**Prompt:**` (the original user prompt)
- `**Branch:**` (the `aid/update-kb-<ts>` branch this run has lived on since
  Pre-flight)
- `**Confirmed Scope:**` (the frozen doc set CONFIRM approved -- also the
  docs actually edited, since REVIEW's scope-diff guard already confirmed
  the disk-derived edited set equals it)
- `**Pre-APPLY baseline:**` (the commit/marker to diff the edits against)
- `**Scope-diff:**` (REVIEW's disk-derived scope-fidelity verdict -- `PASS`
  at this point; REVIEW would not have chained here otherwise)
- `**Review Grade:**` (grade from REVIEW)
- `**Review Teach-back:**` (teach-back verdict from REVIEW)
- `**Review Act-back:**` (act-back verdict from REVIEW)

Print a human-readable summary that shows the disk-derived scope-fidelity
result and a **real diff pointer** -- an actual command the user can run to
see the edits, not merely a doc list:

```
[APPROVAL] KB update summary
Prompt : <prompt>
Scope-diff : PASS -- disk-derived edited set == Confirmed Scope (REVIEW Step 0)
Docs changed (Confirmed Scope):
  <list of .aid/knowledge/<doc>.md (kind: in-scope|closure|new-file)>
Grade  : <grade> (minimum: <minimum_grade>)
Teach-back : <PASS|FAIL>
Act-back   : <PASS|FAIL>
Fix cycles : <N>

Full diff:
  git diff <Pre-APPLY baseline> -- <space-separated Confirmed Scope doc paths>

Please review the changed docs in .aid/knowledge/ (or run the diff command
above) to verify the edits.
```

---

## Step 2: Ask for explicit user approval

```
The KB update has passed the review gate (Scope-diff: PASS, Grade: {grade},
Teach-back: {verdict}, Act-back: {verdict}).

[1] Approved -- commit the changes on <Branch> (created at Pre-flight; no
    new branch is created here)
[2] Additional consideration / re-scope: ___
```

Wait for the user's explicit response. Do not advance until a response is
received.

---

## Step 3: Process the response

### [1] Approved

Update the run-state file:

```
**State:** DONE
**User Approved:** yes
**Approved At:** <ISO-8601 timestamp>
```

Print: `[APPROVAL] Approved. Advancing to DONE.`

**Advance:** CHAIN -> DONE (continue inline).

---

### [2] Additional consideration / re-scope

This does **not** loop blindly back to APPLY (the prior gap). It is a
**re-scope**: the consideration may add, drop, or change a doc in scope, so
it must go back through SCOPE (which re-plans the Scope Plan and, per its own
Step 5, auto-chains to CONFIRM) so the user re-confirms a possibly-revised
`**Confirmed Scope:**` before any further edit is made.

Record the consideration as a new Q&A entry in `.aid/knowledge/STATE.md
## Q&A (Pending)`:

```
### Q{N}
- **Category:** User Feedback / KB-Update Re-scope
- **Impact:** High
- **Status:** Pending
- **Context:** User provided additional consideration during /aid-update-kb
  APPROVAL for prompt: "<prompt>". Consideration: "<the user's text>".
- **Suggested:** Re-plan the Scope Plan (SCOPE) to fold in the consideration,
  then re-confirm at CONFIRM before APPLY re-runs.
```

Update the run-state file:

```
**State:** SCOPE
**Consideration:** Q{N} -- <one-line summary>
```

If the consideration challenges the **Understanding** itself (not merely the
scope of the change) -- set `**State:** ANALYZE` instead of `SCOPE`,
mirroring CONFIRM's own `[2] Adjust` conditional
(`state-confirm.md § Step 3 [2]`) so the researcher re-reads the instruction
against the corrected understanding before SCOPE re-plans.

**Re-scope revert (HL-7/AC-5).** APPLY already wrote edits before this
consideration was raised. If the next CONFIRM freezes a *smaller*
`**Confirmed Scope:**` that drops one of those already-edited docs, the
working tree must not keep carrying that edit -- the tree can never be
broader than the currently confirmed scope. **Nothing is reverted here at
APPROVAL time** -- the revised `Confirmed Scope` is not known until CONFIRM
re-freezes it. The revert is enforced mechanically the next time APPLY runs:
`state-apply.md § Step 0` reverts (`git restore -- <doc>` against
`**Pre-APPLY baseline:**`) every doc still changed on disk that the revised
`Confirmed Scope` no longer includes -- **disk-derived**, not limited to the
prior `**Edited Docs:**` self-report (the same mechanism also strips a stray
out-of-scope edit REVIEW's Step 0 scope-diff guard catches, which was never
in `Edited Docs` in the first place -- see `state-review.md § 4(b)`) --
before making any new edit.

Print:

```
[APPROVAL] Consideration recorded as Q{N} in .aid/knowledge/STATE.md --
re-scoping via SCOPE/CONFIRM (not a blind return to APPLY).
Run /aid-update-kb again to address it and return to this gate.
```

**Advance:** PAUSE-FOR-USER-ACTION -- return to SCOPE (or ANALYZE) on the
next invocation; SCOPE auto-chains to CONFIRM once it has re-planned.
