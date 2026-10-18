# Start or Resume a Work

Use this from SKILL.md step 1 onward. In order, it answers a project question, finds the work
the request belongs to, creates one only when none exists, reads its resume point, handles a
cancel, and records the intent. The reading is checked, sized and shown first (SKILL.md steps 2
to 4). An action-skill reading never reaches this file: its skill's START creates the work.

## 1. Project question

A request that asks for information about the project -- how a part works, what a document
says, where something stands -- starts no work. Answer it with `/aid-ask`:

- Answer from `.aid/knowledge/` first, then from the code when the Knowledge Base does not
  cover the point.
- Cite every source by its document name or file path.
- Create no `.aid/works/` folder and write nothing into a work.
- Say so plainly when the sources cannot answer. Do not guess.

Then stop. The flow does not continue to the next step.

## 2. Check, size and show the reading

Any other request is checked first: `references/check-intent.md` steps 1 to 5 read the
Knowledge Base and the code and classify the reading. Then SKILL.md steps 3 and 4 size it
(`size-and-route.md`) and show it, and the flow waits for the user's answer. Nothing below
runs before that answer.

An action-skill reading (`size-and-route.md` section 1) is handed to that skill now (SKILL.md step
5). No work is created here. Otherwise carry the reading into step 3.

## 3. Find the work

Look for an existing work before creating one. List every work of the project, across the main
tree and each git worktree, with `.aid/runtime/scripts/works/enumerate-works.sh`. The work
initiation gate, `.aid/runtime/templates/work-initiation-gate.md`, decides whether the request
continues one of those works or needs a new one. Follow the gate as written.

- A matching work is continued. Its `STATE.yml` already holds the `intent:` block, which stands
  unless the check found a new fact.
- No match: the gate creates the work. This is the first write the flow makes.
- Several plausible works: ask one question -- which work the request continues. Give its reason
  (the request could fit more than one), your recommendation (the work whose phase fits best),
  the plausible works by name plus "a new work", and a free-text answer.

## 4. Read the resume point

Read the work's `STATE.yml` and take the resume point from these keys:

- `lifecycle:` -- `Running`, `Paused-Awaiting-Input`, `Blocked`, `Completed` or `Canceled`.
- `phase:` and `active_skill:` -- the phase and the skill that was running.
- `pause_reason:` and `block_reason:` -- why the work stopped, when it did.
- `intent.phases` -- the phases the work runs, in order.
- `qa:` -- the open questions, when the work is in Specification or later.

A work that is `Paused-Awaiting-Input` resumes by asking the question it is waiting on. A work
that is `Blocked` says what blocks it before anything else runs.

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
   Give the reason (a canceled work stops for good), your recommendation (keep it paused when
   the user is unsure), the options "cancel" and "keep", and a free-text answer.
4. **Write.** When the user confirms, run:

```bash
AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Canceled
```

## 6. Record the intent

The reading was sized and shown before this step (SKILL.md steps 3 and 4), and the user has
approved it. Write the `intent:` block into the new work's `STATE.yml` at once. The block is
authored, so write it in block style and keep its keys to the three levels the readers allow:

- `request` -- the user's words, short.
- `reading` -- one of: bug fix, refactor, change, new capability, document, operational,
  knowledge update, investigation.
- `reason` -- why the reading fits, in a short phrase.
- `depth` -- `lite` or `full`.
- `phases` -- one `- <phase>` line each, in order.
- `changes` -- starts as `[]`; one entry per re-route, with `at`, `from`, `to` and `why`.

A resumed work keeps its `intent:` block. Change it only through a re-route, and append the
re-route to `changes`.
