# Start or Resume a Work

Use this from PROJECT-QUESTION onward. In order, it answers a project question, finds the work,
creates one only when none exists, reads its resume point, handles a cancel and records the
intent. The reading is checked, sized and shown first (SKILL.md steps CHECK-READING to SHOW-READING); an
action-skill reading never reaches this file, since its skill's START creates the work.

## 1. Project question

A request that asks for information about the project -- how a part works, what a document
says, where something stands -- starts no work. Answer it with `/aid-ask`:

- Answer from `.aid/knowledge/` first, then from the code when the Knowledge Base does not
  cover the point.
- Cite every source by its document name or file path.
- Create no `.aid/works/` folder and write nothing into a work.
- Say so plainly when the sources cannot answer. Do not guess.

Then stop. A request that is not a project question goes on to the check (section 2).

**Advance:** **CHAIN** → CHECK-READING when the request is not a project question; **HALT** when it is a project question.

## 2. Check, size and show the reading

Any other request is checked first: `references/check-intent.md` steps 1 to 5 classify the
reading, SKILL.md steps 3 and 4 size and show it, and the flow waits for the answer, except when
`size-and-route.md` section 6 starts the skill at once. An action-skill reading goes to
START-ACTION and creates no work here. Every other reading goes on to section 3.

## 3. Find the work

Look for an existing work before creating one: list every work across the main tree and each git
worktree with `.aid/runtime/scripts/works/enumerate-works.sh`, then follow the work initiation
gate (`.aid/runtime/templates/work-initiation-gate.md`) as written.

- A matching work is continued. Its `STATE.yml` already holds the `intent:` block, which stands
  unless the check found a new fact.
- No match: the gate's § 3a runs `writeback-state.sh --create` with `--skill aid-orchestrate --step
  RECORD-INTENT`, the step the work continues at once it exists (the steps before it save nothing),
  and with `--reason '<the reading's reason>'` and `--phases <P1,P2,...>` from the shown reading,
  plus `--seed` for the design document that holds the questions asked so far (the go-ahead at
  SHOW-READING and any new-or-continue question), when one exists: first move it to
  `.aid/design/<slug>.md`, the slug being the work's, with `writeback-state.sh --rename-design
  .aid/design/untitled-<YYYYMMDD-HHMMSS>.md --to .aid/design/<slug>.md`. A skill started at once under
  `size-and-route.md` section 6 with no question asked has no such document: no rename and no `--seed`.
  The flow creates no work by hand.
- Several plausible works: section 3a asks which one.

**Advance:** **CHAIN** → ASK-FIRST when several works plausibly match; otherwise **CHAIN** → RECORD-INTENT.

## 3a. Ask which work

Ask one question -- which work the request continues: its reason, your recommendation (the work
whose phase fits best), the plausible works by name plus "a new work", and a free-text answer. No work
is chosen yet, so record it in the design document before it is shown (`--ask --design`) and its
answer after (`--answer --design`), with the id the writer printed. The question pauses the step where it stands. On "a new work", the gate creates it as in section 3,
with `--step RECORD-INTENT`; on an existing work, that work is continued and its record is not
written by this step.

**Advance:** **CHAIN** → RECORD-INTENT.

## 4. Read the resume point

Resume reads the work record only: the work's `STATE.yml`. Take the resume point from these keys,
and from no other file or folder. `phase:` is a display label and never routes.

- `lifecycle:` -- `Running`, `Paused-Awaiting-Input`, `Blocked`, `Completed` or `Canceled`.
- `active_skill:`, `step:` and `step_detail:` -- the skill and the step that were running. An open
  call means the work continues inside the called skill.
- `pause_reason:` and `block_reason:` -- why the work stopped, when it did.
- `intent.phases` -- the phases the work runs, in order.
- `qa:` -- the open questions.

Ask the open questions first: every `qa:` entry in state `Pending` or `Skipped`, in the usual
groups (FR-17), before the work goes on. A `Skipped` question is offered again here.

Record each answer with `--answer`, and then set the lifecycle back to `Running` through the writer,
aimed at that work as in section 5 step 2 (`AID_STATE_FILE` and `AID_WORK_DIR`):
`bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running`.
Do this once every open question is answered or skipped, and also for a `Paused-Awaiting-Input` work that had none, so the
skill started by HAND-OVER finds the work `Running` and runs it. An approval is never skipped: it stays
open, and the work stays paused, until the user approves or declines.

A work that is `Paused-Awaiting-Input` resumes by asking the question it is waiting on. A work
that is `Blocked` says what blocks it before anything else runs. A work that is `Completed` or
`Canceled` is finished: say so in plain words and end the run, with no offer to reopen it and none of
its old questions. No flow reopens a finished work; a new work is the only way on.

A continued work resumes at the skill and step its record names, which HAND-OVER starts once the open
questions above are asked (ASK-FIRST). This flow writes no `--step` and no `--handoff` into a continued
work, so the record keeps its saved step and `step_detail`.

## 5. Cancel a named work

A request such as "cancel work-NNN" is an action on that work, not a new request. Cancel only on
the user's confirmed answer, and in this order:

1. **Resolve the work.** Take the named work from the list in step 3. When the request names no
   work and several are open, ask one question: which work to cancel -- its reason, your
   recommendation (the work the request most plausibly means), the open works by name, and a
   free-text answer. With exactly one open work, that work is the candidate.
2. **Select it.** Set `AID_STATE_FILE` to that work's `STATE.yml` and `AID_WORK_DIR` to its work
   folder, so the write lands on that work and on no other.
3. **Confirm once.** Ask one question: whether to cancel the work, named with its id and phase.
   Its first line uses the fixed subject `Cancel work` (`Cancel work -- question 1 of 1 -- importance:
   high`), the name that marks it as unrecorded on purpose. Give the reason (a canceled work stops for
   good), your recommendation (keep it paused when the user is unsure), the options "cancel" and "keep",
   and a free-text answer. The question pauses this step where it stands; once it is answered, the step
   goes on to the write.
4. **Write.** When the user confirms, run:

```bash
AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Canceled
```

The writer also clears the saved skill and step. The cancel creates no new work and writes
nothing else. When the user answers "keep", nothing is written. Either way, one plain line says
what happened and that no new work was created.

**Advance:** **HALT**.

## 6. Record the intent

The reading was sized and shown before this step (SKILL.md steps SIZE-READING and SHOW-READING), and
the user has approved it or section 6 of `size-and-route.md` started it at once. The record's keys are set through the writer only, never by hand:

- The gate's `--create` (section 3) has already written `intent.request`, `intent.reading` and
  `intent.depth`, from the user's words, the reading and the depth. Nothing else writes them.
- The same `--create` wrote `intent.reason` and `intent.phases`, from `--reason` and `--phases`. If
  either is missing from the record, set it with `writeback-state.sh --intent --reason '<reason>'
  --phases <P1,P2,...>`; a non-zero exit stops the flow, as the fail-closed rule in `skill-steps.md`
  requires.
- A resumed work keeps its `intent:` block. Change it only through a re-route (`--reroute`), which
  appends the re-route to `changes`.

**Advance:** **CHAIN** → HAND-OVER.
