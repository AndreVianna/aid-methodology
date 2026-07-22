# State: SCOPE

SCOPE turns ANALYZE's Impact Map into the **minimal Scope Plan** -- every
item traced to an explicit instruction clause or a closure need, kind-tagged,
plus the explicit **Not-Changing** list of docs considered but excluded. It
is selected when the run-state file records `**State:** SCOPE`.

**Clean-context dispatch (HL-8/AC-9).** SCOPE runs as a dispatch to
`aid-architect` (large tier / medium effort per
`.codex/aid/templates/agent-dispatch-tiering.md`). The sub-agent receives
ONLY the verbatim instruction + the Impact Map + (on a re-plan loop-back)
the recorded `**Adjustments:**`/`**Consideration:**` field + KB/codebase
read access -- **never** the ambient session transcript, and never anything
discussed earlier in this conversation that is absent from the
instruction/Impact Map/recorded field. Read-only over the KB; SCOPE never
edits a file (that is APPLY's job, after CONFIRM).

**Authorized input vs. forbidden input (HL-8).** The user's explicit
gate-time `**Adjustments:**` (written by `state-confirm.md`'s `[2] Adjust`)
or `**Consideration:**` (written by `state-approval.md`'s `[2]`) is part of
the instruction dialogue -- given directly AT a gate, recorded to disk, and
read back here verbatim. It is **authorized, first-class scoping input**,
not the ambient session transcript / prior-work conversation HL-8 actually
forbids. Conflating the two would defeat the very re-plan mechanisms
(`state-confirm.md § Step 3 [2]`, `state-approval.md § Step 3 [2]`,
`state-review.md § 4(b)` "accept") that route back here expecting the
adjustment to change the Scope Plan.

---

## Step 1: Dispatch aid-architect (clean-context)

Dispatch a **clean-context** `aid-architect` sub-agent. Use the Dispatch
Protocol from `SKILL.md § Dispatch Protocol`.

The dispatch prompt contains ONLY:
- The verbatim instruction (`**Prompt:**` from run-state).
- The full Impact Map from `<STATE_FILE>` (`**Understanding:**`,
  `**Impact Findings:**`, `**Contradictions & open questions:**`).
- **On a re-plan loop-back** (this SCOPE entry follows `state-confirm.md`'s
  `[2] Adjust`, `state-approval.md`'s `[2]`, or `state-review.md`'s 4(b)
  "accept" -- detectable by a `**Adjustments:**` or `**Consideration:**`
  field already present in `<STATE_FILE>` with a `Q{N}` value, not the bare
  `--` that CONFIRM's `[1]` writes): that field verbatim, PLUS its full
  `Q{N}` entry read from `.aid/knowledge/STATE.md ## Q&A (Pending)` (already
  covered by the read access below -- no new grant needed) for complete
  context, including the disputed doc's identity when the loop-back
  originated from REVIEW 4(b)'s escalation (the `<doc>` named in that Q{N}
  entry's `Context`). This is authorized, first-class scoping input (see
  above), not the ambient session transcript.
- Read access to `.aid/knowledge/` and the project codebase (to verify a
  closure need, e.g. confirm a coined term truly has no existing glossary
  entry).
- This state's task: produce the minimal Scope Plan + Not-Changing list +
  CONFIRM's draft questions (Steps 2-4 below) -- on a re-plan loop-back,
  **fold in** the recorded Adjustments/Consideration field (and its Q{N}
  context) to actually change the Scope Plan (add, drop, or modify the row
  the user asked for); never reproduce the prior pass's Scope Plan
  byte-for-byte when a loop-back field is present (Step 2 below).

It NEVER receives the ambient session transcript or anything discussed
earlier in this conversation that is absent from the instruction/Impact
Map/recorded Adjustments-Consideration field (HL-8/AC-9).

---

## Step 2: Build the minimal Scope Plan

**On a re-plan loop-back (Step 1's Adjustments/Consideration field is
present), fold it in -- do not silently reproduce the prior pass's Scope
Plan.** The recorded field (plus its Q{N} context) is what actually changes
this pass's outcome versus the original SCOPE pass: add the row it asks for
(e.g. the REVIEW 4(b)-accept disputed doc, `kind: in-scope` or `closure` per
Q{N}'s context), drop/narrow a row it asks to remove, or re-derive
`Traces-to`/`Description` for a row whose understanding it corrects. A
loop-back that produces the byte-identical Scope Plan as the pass before it
is a bug -- the whole point of routing back through SCOPE is that the
recorded field changes at least one row, Not-Changing entry, or Confirm
Question versus the prior pass.

For each Impact Finding, decide whether it becomes a Scope Plan item:

- **Include** only if it traces to an **explicit instruction clause**
  (something the instruction actually asks for), a **closure need** (e.g.
  a coined term the instruction introduces needs a `domain-glossary.md`
  entry to stay groundable -- HL-2), or -- on a re-plan loop-back only -- a
  **recorded Adjustment/Consideration** (Step 1). Every included item's
  `Traces-to` cites the instruction text (a quoted clause), the KB/code
  location that makes the closure necessary, or the `Q{N}` Adjustment/
  Consideration entry that added it -- never "the session" or prior discussion
  (HL-8/AC-9).
- **Exclude** (-> Not-Changing, Step 3) a doc that is merely domain-adjacent,
  or `suspect` per the freshness advisory, but not itself named or implied
  by the instruction (HL-5 -- that is `aid-housekeep`'s job, not this
  skill's).
- A `LIKELY`/`UNCERTAIN`-confidence Impact Finding is NEVER promoted to a
  Scope Plan item on SCOPE's own authority (HL-3) -- it becomes a CONFIRM
  question instead (Step 4); only if the user's answer confirms it does it
  become a Scope Plan item, on the next SCOPE pass after a CONFIRM `[2]
  Adjust` loop-back.

Write:

```
**Scope Plan:**
| # | Doc | Change-type | Description | Traces-to | Kind |
| 1 | .aid/knowledge/<doc>.md | <change-type> | <one-line description> | "<instruction clause>" (or closure: <reason>) | in-scope\|closure\|new-file |
```

- **Change-type** -- one of: `New summary+pointer entry` / `Corrected fact` /
  `New sources: entry` / `New concept on the spine` / `No change needed`
  (unchanged taxonomy).
- **Kind** -- `in-scope` (directly named/implied by the instruction),
  `closure` (necessary to keep an in-scope edit groundable, e.g. the
  glossary entry for a coined term the instruction introduces), `new-file`
  (the item creates a file that does not exist yet -- HL-6, never a silent
  side effect).
- Every row MUST have a non-empty `Traces-to`. A row without one is not a
  Scope Plan item -- it is either a Not-Changing entry or a CONFIRM question.

---

## Step 3: Emit the Not-Changing list

Every doc that appeared in the Impact Map (or was a candidate the
researcher considered) but did NOT make the Scope Plan is listed here with
its exclusion reason (HL-5):

```
**Not-Changing:**
- .aid/knowledge/<doc>.md -- <reason, e.g. "domain-adjacent but not named by
  the instruction; route to aid-housekeep if genuinely stale">
```

If nothing was excluded (every located doc made the Scope Plan), write
`**Not-Changing:** -- none --`.

---

## Step 4: Draft the CONFIRM questions

Collect, verbatim from ANALYZE's Contradictions & open questions plus any
new question SCOPE itself needed to decide inclusion/exclusion, into a
single list CONFIRM will present:

```
**Confirm Questions:**
- Q1: ...
```

If there are none (a fully-grounded, unambiguous instruction), write
`**Confirm Questions:** -- none --`.

---

## Step 5: Advance

If the Scope Plan has at least one item:

```
**State:** CONFIRM
```

Print: `[SCOPE] Scope Plan ready. {N} item(s) in scope, {M} in Not-Changing. Advancing to CONFIRM.`

**Advance:** CHAIN -> CONFIRM (continue inline).

If the Scope Plan is empty (every Impact Finding was `No change needed` or
excluded to Not-Changing), print:

```
[SCOPE] No KB update needed -- every location the instruction concerns
already reflects it, or falls outside the instruction's scope (see
Not-Changing). No edit will be made.
```

Then HALT (do not advance to CONFIRM with an empty Scope Plan).
