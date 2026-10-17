# Start or Resume a Work

Use this step first. It answers a project question, or finds the work the request belongs to,
creates one when none exists, and sizes it.

## 1. Project question

A request that asks for information about the project -- how a part works, what a document
says, where something stands -- starts no work. Answer it with `/aid-ask`:

- Answer from `.aid/knowledge/` first, then from the code when the Knowledge Base does not
  cover the point.
- Cite every source by its document name or file path.
- Create no `.aid/works/` folder and write nothing into a work.
- Say so plainly when the sources cannot answer. Do not guess.

Then stop. The flow does not continue to the next step.

## 2. Find the work

Look for an existing work before creating one. List every work of the project, across the main
tree and each git worktree, with `.aid/runtime/scripts/works/enumerate-works.sh`. The work
initiation gate, `.aid/runtime/templates/work-initiation-gate.md`, decides whether the request
continues one of those works or needs a new one. Follow the gate as written.

- A matching work is continued. Its `STATE.yml` already holds the `intent:` block.
- No match: the gate creates the work. Create it before any other write.
- Several plausible works: ask one question -- which work the request continues. Give its reason
  (the request could fit more than one), your recommendation (the work whose phase fits best),
  the plausible works by name plus "a new work", and a free-text answer.

## 3. Read the resume point

Read the work's `STATE.yml` and take the resume point from these keys:

- `lifecycle:` -- `Running`, `Paused-Awaiting-Input`, `Blocked`, `Completed` or `Canceled`.
- `phase:` and `active_skill:` -- the phase and the skill that was running.
- `pause_reason:` and `block_reason:` -- why the work stopped, when it did.
- `intent.phases` -- the phases the work runs, in order.
- `qa:` -- the open questions, when the work is in Specification or later.

A work that is `Paused-Awaiting-Input` resumes by asking the question it is waiting on. A work
that is `Blocked` says what blocks it before anything else runs.

## 4. Cancel

Cancel only on the user's confirmed answer. Ask one question: whether to cancel the work, named
with its phase. Give the reason (a canceled work stops for good), your recommendation (keep it
paused when the user is unsure), the options "cancel" and "keep", and a free-text answer. When
the user confirms, run:

```bash
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Canceled
```

## 5. Size and record

Size the work with `size-and-route.md`: it gives the phases and the depth. Then write the
`intent:` block into the work's `STATE.yml` at once. The block is authored, so write it in
block style and keep its keys to the three levels the readers allow:

- `request` -- the user's words, short.
- `reading` -- one of: bug fix, refactor, change, new capability, document, operational,
  knowledge update, investigation.
- `reason` -- why the reading fits, in a short phrase.
- `depth` -- `lite` or `full`.
- `phases` -- one `- <phase>` line each, in order.
- `changes` -- starts as `[]`; one entry per re-route, with `at`, `from`, `to` and `why`.

A resumed work keeps its `intent:` block. Change it only through a re-route, and append the
re-route to `changes`.
