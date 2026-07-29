# IMPEDIMENT — task-035

**Type:** AC-Reality Conflict

**Blocked-task:** task-035

**Evidence:**

AC-6 states: `exits` contains `APPROVAL-HALT` with `terminal.advanceType === 'HALT'` and a
`terminal.handoff` mentioning `/aid-execute`.

The actual `handoff` derived from the `**Advance:**` clause in `## State: APPROVAL-HALT`
(lines 895–898 of `canonical/aid/templates/shortcut-engine.md`) is:

```
"No branch is created; no ### Tasks lifecycle row advances past Pending (the -proof fixture
in feature-004's testing strategy asserts both"
```
(truncated at 80 code points by `truncate()`)

`/aid-execute` appears in the section prose (lines 855, 877) but NOT in the `**Advance:**`
clause.  `engine-core.mjs` derives `handoff` from the `**Advance:**` block only — the surrounding
section prose is not included.  No code change can make `handoff` contain `/aid-execute` without
modifying either `engine-core.mjs` (which the AC prohibits: "modify no existing module") or the
`shortcut-engine.md` source template (which is out of scope for task-035).

**Actual test written:** The test asserts `terminal.advanceType === 'HALT'` and
`terminal.handoff !== null` and `terminal.handoff.includes('No branch is created')`,
which reflects the real contract.

**Proposed resolution:** One of:
1. Update AC-6 to match the actual handoff substring ("No branch is created"); OR
2. Update `shortcut-engine.md`'s APPROVAL-HALT `**Advance:**` clause to include
   `/aid-execute` in the advance text (e.g. "HALT. Run `/aid-execute` to continue...").

Either is an Architect/content decision outside task-035's scope.
