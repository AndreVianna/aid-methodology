# State: SCOPE

SCOPE turns ANALYZE's Impact Map into the **minimal Scope Plan** -- every
item traced to an explicit instruction clause or a closure need, kind-tagged,
plus the explicit **Not-Changing** list of docs considered but excluded. It
is selected when the run-state file records `**State:** SCOPE`.

**Clean-context dispatch (HL-8/AC-9).** SCOPE runs as a dispatch to
`aid-architect` (large tier / medium effort per
`canonical/aid/templates/agent-dispatch-tiering.md`). The sub-agent receives
ONLY the verbatim instruction + the Impact Map + KB/codebase read access --
**never** the session transcript, and never anything discussed earlier in
this conversation that is absent from the instruction/Impact Map. Read-only
over the KB; SCOPE never edits a file (that is APPLY's job, after CONFIRM).

---

## Step 1: Dispatch aid-architect (clean-context)

Dispatch a **clean-context** `aid-architect` sub-agent. Use the Dispatch
Protocol from `SKILL.md § Dispatch Protocol`.

The dispatch prompt contains ONLY:
- The verbatim instruction (`**Prompt:**` from run-state).
- The full Impact Map from `<STATE_FILE>` (`**Understanding:**`,
  `**Impact Findings:**`, `**Contradictions & open questions:**`).
- Read access to `.aid/knowledge/` and the project codebase (to verify a
  closure need, e.g. confirm a coined term truly has no existing glossary
  entry).
- This state's task: produce the minimal Scope Plan + Not-Changing list +
  CONFIRM's draft questions (Steps 2-4 below).

It NEVER receives the session transcript or anything discussed earlier in
this conversation that is absent from the instruction/Impact Map (HL-8/AC-9).

---

## Step 2: Build the minimal Scope Plan

For each Impact Finding, decide whether it becomes a Scope Plan item:

- **Include** only if it traces to an **explicit instruction clause**
  (something the instruction actually asks for), or a **closure need** (e.g.
  a coined term the instruction introduces needs a `domain-glossary.md`
  entry to stay groundable -- HL-2). Every included item's `Traces-to` cites
  either the instruction text (a quoted clause) or the KB/code location that
  makes the closure necessary -- never "the session" or prior discussion
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
