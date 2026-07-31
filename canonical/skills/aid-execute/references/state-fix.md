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

## ⚠️⚠️ MANDATORY: the FIX contract -- read before touching anything

**The reviewer is a safety net, not the quality process.** The target is a review that
finds nothing. A cycle that returns findings the executor could have prevented is a
failure of THIS state, not a success of the reviewer.

The ledger is **not a to-do list**. Treating it as one -- close the row, hand it back, let
the next cycle find the rest -- is what makes a FIX loop run for cycles without
converging, and it pushes the executor's own analysis onto the reviewer. Six rules, all
binding, each written because skipping it costs a full cycle:

### F1. A finding is a CLASS, not the line it was reported on

The `Description` names **one** site. The `Evidence` column specifies the **extent** --
every sibling the reviewer already found. Fix all of them.

Then go further: **grep the defect's signature across the repository before declaring it
fixed.** If a stale number appears in one document it is usually in five; if one contract
statement was superseded, every document reasoning from it was too.

A row closed on its Description alone comes back marked `Recurred`, repeatedly, because
nothing about the class changed.

### F2. Trace the impact chain BEFORE editing

Ask every time: *is this file a source, or something derived from one?* Editing a derived
file is a defect even when the edit is correct -- the next render erases it, and the copies
diverge meanwhile.

| Chain | Edit here | Then run |
|---|---|---|
| `canonical/` -> `profiles/*` -> `.claude/`, `.cursor/` | `canonical/` | the profile generator, then resync both dogfood trees |
| repo-root `docs/*.md` -> synced `site/src/content/docs/*` | `docs/` | the site's `sync:docs` |
| KB doc `summary:` frontmatter -> `.aid/knowledge/INDEX.md` | the frontmatter | the KB index builder |
| a generator -> its generated pages | the generator | that generator |

If a file's header says it is generated, or a sibling copy exists, the chain applies.

### F3. Read the line; do not pattern-match it

A number or claim inside a **dated changelog row**, a **history bullet**, or a *"before X
it was Y"* comparative is a **record of a moment**. It was true when written. "Correcting"
it to today's value **falsifies the record** -- strictly worse than the stale value a scan
flagged.

A tool's output is a list of candidates, never a list of edits. Read each in its
surrounding lines and decide whether it asserts something about **now** or reports
something about **then**. Only the first kind gets corrected.

### F4. Name the oracle that would catch you, then run it

Before claiming a fix verified, state **which check fails if this fix is wrong** -- and run
that one.

A green suite structurally incapable of observing the defect is not evidence. If no
existing check can see it, say so plainly rather than substituting one that cannot. "The
suite passed" means nothing until you have established that the suite looks at what you
changed.

### F5. Mark `Fixed` from the artifact, never from intent

Re-read the file on disk and confirm every site the `Evidence` names before setting a row
`Fixed`. A row marked `Fixed` because an edit was *attempted* forces the next reviewer to
re-derive the finding from scratch -- the exact work this state exists to spare them.

Leave a row `Pending` with a reason if it was not addressed. An honest `Pending` costs
nothing; a false `Fixed` costs a cycle.

### F6. A fix that introduces a defect is worse than the finding

After editing, re-read the surrounding context: does the sentence still parse, the count
still sum, the brackets still balance, the comment still describe the code beneath it, and
no adjacent claim get contradicted?

If the fix is a new guard: **do not re-implement the thing it checks.** Invoke the real
oracle -- the generator, the derivation, the parser. A guard that restates its subject's
rules is a second implementation that will drift, and one whose assumptions are wrong is
worse than no guard, because a noisy check trains readers to ignore it.

## Step 4: FIX

Dispatch agent with:
- Issues from STATE.md where Source = CODE and Status = Pending
- Original task context
- **The FIX contract above (F1-F6), in full.** It binds a dispatched agent exactly as it
  binds the orchestrator fixing directly.

**Agent fixes CODE issues only.** Verifies gates still pass.

When done:
1. Confirm each fix against the artifact on disk (**F5**), then mark those issues `Fixed`
   in STATE.md. Rows not addressed stay `Pending`, with the reason.
2. → **Back to Step 2 (REVIEW)** — fresh reviewer, clean context

**Loop continues until grade ≥ minimum.**

⚠️ **Circuit breaker:** If grade has not improved after 3 consecutive
cycles (same or worse), **STOP.** Something systemic is wrong.

> **Reading the circuit breaker correctly.** Repeated `Recurred` rows, or new findings
> arriving faster than old ones close, is not "a harsh reviewer" -- it is the signal this
> breaker exists for. The usual cause is **F1**: fixes landing on Descriptions while the
> classes stay open. The next most usual is a scope mismatch -- the gate grading a surface
> wider than the task being fixed. Diagnose which before spending another cycle.

**Advance:** **CHAIN** → [State: REVIEW] (continue inline).
