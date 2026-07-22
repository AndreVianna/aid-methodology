# State: ANALYZE

ANALYZE maps the user's instruction onto concrete KB locations and produces
the **Impact Map** -- the "correct understanding" to be confirmed, plus a
per-location record of what the KB currently says, how it relates to the
instruction, and how confidently that relation is grounded. It is selected
on a fresh run (no run-state file yet) or when the run-state file records
`**State:** ANALYZE`.

**Clean-context dispatch (HL-8/AC-9).** ANALYZE runs as a dispatch to
`aid-researcher` (medium tier / low effort per
`canonical/aid/templates/agent-dispatch-tiering.md` -- Retrieval-heavy work).
The sub-agent receives ONLY the verbatim instruction plus KB/codebase read
access -- **never** the session transcript, and never anything discussed
earlier in this conversation that is absent from the instruction itself.
Read-only; ANALYZE never edits a file.

**Cross-delivery dependency (task-014/f005):** ANALYZE loads
`.aid/knowledge/INDEX.md` (f002 routing table) -- the same navigation table
`aid-query-kb` and `aid-discover` use -- to locate the docs the instruction
actually concerns.

**Cross-delivery dependency (task-040/f007):** `kb-freshness-check.sh`
(delivery-007) supplies advisory-only per-doc freshness verdicts (`suspect` /
`current` / `unknown`). Freshness NEVER adds or removes a doc from scope by
itself (HL-5) -- it is context ANALYZE records alongside a location the
instruction already concerns. If the script is absent (branch ordering),
ANALYZE proceeds without the advisory signal.

---

## Step 0: Initialize run-state (first entry only)

If `<STATE_FILE>` does not yet contain a `**Prompt:**` field (first entry
into ANALYZE for this run), write the opening block:

```
**State:** ANALYZE
**Prompt:** <the user's argument verbatim>
**Started:** <ISO-8601 timestamp>
**Branch:** <the aid/update-kb-<ts> branch Pre-flight ISOLATE already created and entered>
```

The `**Branch:**` value is already known -- Pre-flight ISOLATE ran before
ANALYZE and created + entered this worktree's branch; nothing here is a
placeholder for a later state to fill in (unlike today's design, DONE
creates no branch of its own).

If the run-state file already has a `**Prompt:**` (a resumed ANALYZE -- e.g.
returning from the ungroundable-concept PAUSE in Step 4 below), do NOT
re-initialize; keep the existing `**Prompt:**`/`**Started:**`/`**Branch:**`
values and proceed.

Print the `[State: ANALYZE]` banner from `SKILL.md § State Detection`.

---

## Step 1: Dispatch aid-researcher (clean-context)

Dispatch a **clean-context** `aid-researcher` sub-agent (medium tier, low
effort per `agent-dispatch-tiering.md`). Use the Dispatch Protocol from
`SKILL.md § Dispatch Protocol`.

The dispatch prompt contains ONLY:
- The verbatim instruction (`**Prompt:**` from run-state) -- word for word,
  never paraphrased, never supplemented with anything discussed earlier in
  this conversation (HL-8/AC-9).
- Read access to `.aid/knowledge/` (including `INDEX.md`) and the project
  codebase.
- This state's task: produce the Impact Map (Step 2 below defines its shape).
- The freshness advisory (Step 1a) if available.

It NEVER receives the session transcript, prior chat turns, or any
paraphrase of them. If the orchestrator is tempted to add "context" from
earlier in the conversation that is not itself present in the verbatim
instruction, that is exactly what HL-8 forbids -- don't.

### Step 1a: Freshness advisory (optional, f007)

Before dispatch, run the freshness check to have advisory verdicts ready to
hand the researcher (never a substitute for the researcher's own reading):

```bash
bash canonical/aid/scripts/kb/kb-freshness-check.sh \
  --root .aid/knowledge --format tsv
```

If the script is absent or exits non-zero, skip silently -- ANALYZE proceeds
on the researcher's own INDEX.md-routed reading alone.

---

## Step 2: Build the Impact Map

The researcher locates the docs the instruction *actually concerns* via
`INDEX.md`'s Objective/Tags/Audience routing -- NOT every doc whose domain
merely overlaps. A doc's presence in the Impact Map means the instruction
itself points there, not that its tags merely resemble the topic (there is
no tag-overlap candidate net -- HL-5). If the instruction names a specific
doc, that doc is unconditionally included.

For each located doc, read it (and its `sources:` frontmatter) and record
one row:

```
**Understanding:** <plain restatement of what the instruction asks -- the
"correct understanding" CONFIRM will ask the user to confirm>
**Impact Findings:**
| # | KB location (doc §, file:line) | Current KB statement | Relation | Confidence |
| 1 | .aid/knowledge/<doc>.md § <heading> (L<n>) | <quoted/paraphrased current text> | <MATCHES\|CONTRADICTS\|MISMATCH\|GAP\|ABSENT> | <CONFIRMED\|LIKELY\|UNCERTAIN> |
```

- **Relation** -- `MATCHES` (KB already says this), `CONTRADICTS` (KB
  asserts the opposite), `MISMATCH` (KB is adjacent but not quite what the
  instruction states), `GAP` (doc covers the topic but lacks this entry),
  `ABSENT` (no doc covers this at all).
- **Confidence** -- `CONFIRMED` (the instruction states this explicitly, or
  it is directly readable from the cited KB/code location), `LIKELY` (a
  reasonable inference, not stated outright), `UNCERTAIN` (a guess that
  needs the user).
- Every row cites a real `file:line` (or `file` + heading if line numbers do
  not apply, e.g. a not-yet-existing doc). No location is asserted without a
  citation -- an ungroundable claim is not a row, it becomes a
  Contradiction/open-question entry instead (Step 3).
- Freshness (Step 1a) is recorded as a parenthetical note on a row it
  overlaps (e.g. "(freshness: suspect)") -- advisory context only, never a
  reason to add or drop a row (HL-5).

**HL-3 -- forbid silent inference.** Any row whose Confidence is `LIKELY` or
`UNCERTAIN` is a candidate CONFIRM question, not a fact ANALYZE (or any
later state) may act on as if it were `CONFIRMED`. ANALYZE records the
confidence; it never upgrades a `LIKELY`/`UNCERTAIN` reading into a
`CONFIRMED` one by its own judgment.

---

## Step 3: Contradictions & open questions

Any row that is `CONTRADICTS`, `MISMATCH`, or carries `LIKELY`/`UNCERTAIN`
confidence becomes an entry here -- surfaced for CONFIRM to ask, never
resolved by ANALYZE itself (HL-3/HL-4):

```
**Contradictions & open questions:**
- Q1: <the KB currently states X at file:line; the instruction implies Y --
  which is correct?> (or: <the instruction's use of "<term>" could mean A or
  B -- which?>)
```

If there are none, write `**Contradictions & open questions:** -- none --`.

---

## Step 4: Un-groundable escalation

Before advancing, check whether the instruction requires a project-specific
coined term that cannot be grounded from `.aid/knowledge/` or the
`sources:` frontmatter of any located doc:

- Already in `domain-glossary.md`, or inferable from a located doc's
  `sources:` entries -- grounded, no escalation (record it as a `GAP` row
  instead; its `Kind` -- `in-scope` vs `closure` -- is decided at SCOPE).
- Genuinely new and ungroundable from available artifacts -- do NOT invent a
  definition:

  1. Append a new Q&A entry to `.aid/knowledge/STATE.md ## Q&A (Pending)`:

     ```
     ### Q{N}
     - **Category:** Update-KB / Ungroundable Concept
     - **Impact:** Required
     - **Status:** Pending
     - **Context:** /aid-update-kb ANALYZE cannot ground the term "<term>" from
       the available artifacts. The instruction states: "<relevant excerpt>".
       Sources checked: <list of sources:> entries examined.
     - **Suggested:** Provide a definition or point to the source artifact where
       "<term>" is defined so SCOPE can plan the correct glossary entry.
     ```

  2. Update the run-state file:

     ```
     **State:** ANALYZE
     **Escalation:** Ungroundable Concept "<term>" -- Q{N} appended to
       .aid/knowledge/STATE.md
     ```

  3. Print:

     ```
     [ANALYZE] Pausing -- concept "<term>" cannot be grounded from available
     artifacts. Q{N} appended to .aid/knowledge/STATE.md. Provide a definition
     or source pointer, then run /aid-update-kb again to resume.
     ```

  4. PAUSE-FOR-USER-ACTION -- do NOT advance to SCOPE.

---

## Step 5: Emit the Impact Map and advance

Write `**Understanding:**`, `**Impact Findings:**`, and `**Contradictions &
open questions:**` into `<STATE_FILE>` (Step 2/3's shape).

If the Impact Map has at least one Impact Finding row and no un-groundable
escalation was triggered:

```
**State:** SCOPE
```

Print: `[ANALYZE] Impact Map ready. {N} location(s) recorded. Advancing to SCOPE.`

**Advance:** CHAIN -> SCOPE (continue inline).

If ANALYZE finds NO location the instruction concerns at all (a truly empty
Impact Map -- the instruction does not describe anything KB-relevant),
print:

```
[ANALYZE] No KB-relevant location identified for the supplied instruction.
Verify the instruction describes a concrete change to the project that
should be reflected in the Knowledge Base. If the change is purely internal
(e.g. a refactor with no observable contract change), no KB update is needed.
```

Then HALT (do not advance to SCOPE with an empty Impact Map).
