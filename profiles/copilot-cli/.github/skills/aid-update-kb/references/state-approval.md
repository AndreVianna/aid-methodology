# State: APPROVAL

APPROVAL is the explicit human gate before the KB change is committed. It is
selected when the run-state file records `**State:** APPROVAL`.

**Human-gated (NFR-6/C4/AC13).** Detection and grading are automatic; the
change to KB content cannot proceed to DONE without an explicit human `[1]`.
No auto-apply path exists -- DONE is unreachable from this state without a
human `[1] Approved`.

**Pattern reuse.** This state reuses `aid-discover`'s approval-gate pattern
(`.github/skills/aid-discover/references/state-approval.md`: `[1]`/`[2]`
prompt, consideration loop), scoped to the `aid-update-kb` context.

Print the `[State: APPROVAL]` banner from `SKILL.md § State Detection`.

---

## Step 1: Present the diff summary

Read the following from `<STATE_FILE>`:
- `**Prompt:**` (the original user prompt)
- `**Edited Docs:**` (docs changed by APPLY)
- `**Review Grade:**` (grade from REVIEW)
- `**Review Teach-back:**` (teach-back verdict from REVIEW)
- `**Review Act-back:**` (act-back verdict from REVIEW)

Print a human-readable summary:

```
[APPROVAL] KB update summary
Prompt : <prompt>
Docs changed:
  <list of .aid/knowledge/<doc>.md>
Grade  : <grade> (minimum: <minimum_grade>)
Teach-back : <PASS|FAIL>
Act-back   : <PASS|FAIL>
Fix cycles : <N>

Please review the changed docs in .aid/knowledge/ to verify the edits.
```

---

## Step 2: Ask for explicit user approval

```
The KB update has passed the review gate (Grade: {grade}, Teach-back: {verdict},
Act-back: {verdict}).

[1] Approved -- commit the changes on aid/update-kb-* branch
[2] Additional consideration: ___
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

### [2] Additional consideration

Record the consideration as a new Q&A entry in `.aid/knowledge/STATE.md
## Q&A (Pending)`:

```
### Q{N}
- **Category:** User Feedback / KB-Update Consideration
- **Impact:** High
- **Status:** Pending
- **Context:** User provided additional consideration during /aid-update-kb
  APPROVAL for prompt: "<prompt>". Consideration: "<the user's text>".
- **Suggested:** Address the consideration, re-run /aid-update-kb to re-enter
  APPLY or REVIEW as appropriate, then return to APPROVAL.
```

Update the run-state file:

```
**State:** APPLY
**Consideration:** Q{N} -- <one-line summary>
```

Print:

```
[APPROVAL] Consideration recorded as Q{N} in .aid/knowledge/STATE.md.
Run /aid-update-kb again to address it and return to this gate.
```

**Advance:** PAUSE-FOR-USER-ACTION -- return to APPLY on the next invocation.
