# State: CONFIRM

CONFIRM is the **new pre-apply human gate** -- the root fix this redesign
exists for (HL-1). No KB file is edited before this gate returns `[1]
Confirm`. It is selected when the run-state file records `**State:**
CONFIRM`.

**Pattern reuse.** Shaped like this skill's own APPROVAL-gate pattern (`[1]`/
`[2]` prompt, PAUSE-FOR-USER-ACTION), plus a `[3] Cancel` exit, but gates
SCOPE before any edit exists rather than the finished edits.

Print the `[State: CONFIRM]` banner from `SKILL.md § State Detection`.

---

## Step 1: Present understanding + scope + questions

Read from `<STATE_FILE>`:
- `**Understanding:**` (ANALYZE)
- `**Scope Plan:**` and `**Not-Changing:**` (SCOPE)
- `**Confirm Questions:**` (SCOPE)

Print:

```
[CONFIRM] KB update scope

Understanding: <the Understanding restatement>

Will change:
  <# | doc | change-type | description | kind, from Scope Plan>

Will NOT change:
  <doc -- reason, from Not-Changing>

Open questions:
  <Q1, Q2, ... from Confirm Questions -- or "-- none --">
```

---

## Step 2: Ask for explicit user confirmation

```
[1] Confirm -- freeze this scope, proceed to APPLY
[2] Adjust: ___ (free text -- corrects understanding or scope; loops back)
[3] Cancel -- stop here, no edit made
```

Wait for the user's explicit response. Answering any open questions is part
of a `[1]`/`[2]` response -- CONFIRM does not advance past unanswered
Contradictions/open questions per HL-3/HL-4; fold the user's answers into
`**Adjustments:**` either way. Do not advance until a response is received.

---

## Step 3: Process the response

### [1] Confirm

Freeze the confirmed scope and capture the pre-APPLY baseline (HL-1, and the
baseline REVIEW's scope-diff guard and any later re-scope revert both need --
captured now, before APPLY makes its first edit):

```bash
PRE_APPLY_BASELINE="$(git rev-parse HEAD 2>/dev/null || echo clean)"
```

Update the run-state file:

```
**State:** APPLY
**Confirmed:** yes
**Confirmed At:** <ISO-8601 timestamp>
**Confirmed Scope:**
- .aid/knowledge/<doc1>.md (kind: in-scope)
- .aid/knowledge/<doc2>.md (kind: closure)
**Pre-APPLY baseline:** <PRE_APPLY_BASELINE>
**Adjustments:** -- (or the user's answers to the open questions, if any)
```

`**Confirmed Scope:**` lists exactly one bullet per in-scope/closure/new-file
Scope Plan item (same doc-path + parenthetical convention as the existing
`**Edited Docs:**` field APPLY writes) -- it is the scope contract for the
rest of the run: APPLY may only touch it, and REVIEW's scope-diff guard
hard-fails on any divergence between it and the disk-derived edited set.

Print: `[CONFIRM] Confirmed. {N} doc(s) in scope. Advancing to APPLY.`

**Advance:** CHAIN -> APPLY (continue inline).

---

### [2] Adjust: ___

Record the adjustment as a new Q&A entry in `.aid/knowledge/STATE.md ## Q&A
(Pending)` (mirrors the existing APPROVAL `[2]` convention):

```
### Q{N}
- **Category:** User Feedback / KB-Update Scope Adjustment
- **Impact:** High
- **Status:** Pending
- **Context:** User adjusted /aid-update-kb CONFIRM for instruction:
  "<prompt>". Adjustment: "<the user's text>".
- **Suggested:** Address the adjustment; re-run /aid-update-kb to re-enter
  SCOPE (or ANALYZE, if the adjustment changes the Understanding itself),
  then return to CONFIRM.
```

Update the run-state file:

```
**State:** SCOPE
**Adjustments:** Q{N} -- <one-line summary>
```

If the adjustment corrects the Understanding itself -- not just the scope --
set `**State:** ANALYZE` instead, so the researcher re-reads the instruction
against the corrected understanding before SCOPE re-plans.

Print:

```
[CONFIRM] Adjustment recorded as Q{N} in .aid/knowledge/STATE.md.
Run /aid-update-kb again to address it and return to this gate.
```

**Advance:** PAUSE-FOR-USER-ACTION -- return to SCOPE (or ANALYZE) on the
next invocation.

---

### [3] Cancel

No edit has been made yet (HL-1 -- CONFIRM gates APPLY, and APPLY has not
run). Clean up and stop:

```bash
rm -f "$STATE_FILE"
```

Print:

```
[CONFIRM] Cancelled -- no KB edit made. Run-state cleaned.
```

**Advance:** HALT.
