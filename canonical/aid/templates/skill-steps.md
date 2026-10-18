---
kb-category: meta
source: hand-authored
objective: Defines the one rule set that every AID skill follows to move between its steps, hand work to another skill, ask for approvals and keep the work record.
summary: The step table and its advance words, the six-part step procedure, the work record and its recovery, the one State Detection rule, the approvals table, the never-merges boundary and what the user sees; each skill cites this file rather than restating these rules.
review-criteria: []
---

# Skill Steps

**Every AID skill moves between its steps by this file.** A skill keeps only its own step table
(its steps, the reference that does each one, the worker, and the advance word) and a fallback
detection from its artifacts. No skill restates how to move; it cites this file (FR-20).

Questions are asked through `.aid/runtime/templates/question-protocol.md` (FR-17). Only the main
conversation asks the user; a sub-agent records its open questions and lists them in its report.

## The step table

Each skill has one table of its steps, with these columns:

| Column | Holds |
|--------|-------|
| Step | the step's name, in upper case |
| Reference | the reference file that does the step's work |
| Worker | `inline`, or the agent that does the work |
| Advance | the advance word for the step, and the step it names when that is needed |

Every step ends with exactly one advance word, on its advance line. A line that names only its next
step is a `CHAIN`.

## The advance words

The advance words are internal. They are never shown to the user.

| Word | Meaning |
|------|---------|
| `CHAIN` | Go on to the next step now, in the same run. |
| `ASK` | Stop for the user through the question protocol, then continue to the step the line names once every question is answered. |
| `WAIT` | The user must do something outside the conversation. Say what, plainly, and stop. |
| `PASS` | End of this skill's process. Hand the work to the next skill and start it in the same turn. |
| `CALL` | In the middle of this skill's process. Hand the work to another skill, and come back to this step when it finishes. |
| `HALT` | This run is finished. After returning to an open call, if there is one; otherwise the run ends here. |

## The step procedure

Every step runs these six parts, in this order.

1. **Enter.** Before any work in the step, and before dispatching any worker for it, the main
   conversation runs the writer in step mode:
   `bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill <skill> --name <STEP> [--detail '<where>']`.
   The saved step is written first, so a session that stops during the step resumes at it.
2. **Work.** Inline, or by a worker. A worker returns its questions to the main conversation; it
   never asks them.
3. **`ASK`.** Save the step the advance line names as the next one, with `--step` and a detail that
   says what is waited for. Record each question with `--ask`. Set the lifecycle to
   `Paused-Awaiting-Input` and the pause reason through the writer. Then ask.
   - Answered in the same conversation: record each answer with `--answer`, set the lifecycle back to
     `Running`, and continue to the named step in the same run.
   - Answered later: the session that resumes finds the saved step and the open questions, asks the
     open questions first, then continues at that step.
4. **`PASS`.** If the approvals table requires an approval at this depth at this point, `ASK` it
   first. Then run
   `--handoff --to <skill> --step <its entry step> --why '<reason>' --returns no --phase <phase>`,
   and start that skill in the same turn. Where a tool cannot start a skill itself, name the command
   to run instead.
5. **`CALL`.** Bring the detail up to date with what is done, with `--step`. Then run
   `--handoff --to <skill> --step <its entry step> --why '<reason>' --returns yes`. The called skill
   runs as usual. The phase does not change.
6. **`HALT`.** With an open call, run `--handoff-return`. It restores the caller's skill, step and
   detail, and the caller continues at that step. Calls nest, and the newest call returns first.
   Without an open call, the run ends.

## The work record

The work record is the work's `STATE.yml` keys that say where it is: `intent.reading` (its type),
`active_skill`, `step` and `step_detail`. It is the only thing that decides where a work continues.
Every record write goes through the writer, `.aid/runtime/scripts/execute/writeback-state.sh`, and
never by hand. The record's template is `.aid/runtime/templates/work-state-template.yml`.

### When the record is written

- **From creation, however the work starts**: a plain request through `/aid-orchestrate`, a typed
  slash command, or a one-pass doorway skill. The gate is the only creator of a work's record, as
  `.aid/runtime/templates/work-initiation-gate.md` § 3a describes. The gate runs the writer's
  create mode before it hands the new work back:
  `--create --work-dir <dir> --reading <type> --request '<words>' --skill <caller> --step <first step> [--phase <phase>] [--depth lite or full]`.
  One locked write creates the record with the type, the request, the saved skill and step, the phase
  when there is one, and the lifecycle `Running`. No work exists without its record.
- **At every step entry**, before any work in that step.
- **At every hand-off and return**, and at every re-route (`--reroute`), which also appends an entry
  to `intent.changes`.
- **At finish.**

A skill never writes the record's keys by hand. If it needs a key the writer does not set, it sets
that key through the writer.

### Fail-closed

A non-zero exit from any record write stops the skill at once. The agent tells the user, in one plain
line, what failed, and that nothing more runs until it is fixed. There is no silent continue and no
retry beyond the writer's own lock wait. A write either completes or leaves the file untouched.

### Starting and resuming

- **Starting fresh** on a work: a `PASS`, a `CALL`, or the user typing a skill other than the one the
  record names. The skill runs its own detection inside its entry step to decide how far that step
  goes.
- **Resuming**: typing the command the record already names is a resume. The record alone decides
  the skill and the step. The resumed skill runs its detection only to validate the saved step
  against what is on disk (State Detection below).

A hand-off writes the target skill and its entry step (the first row of its step table) in the same
locked write. A work therefore never has a skill without a step, even when a hand-off is interrupted.

A typed start of another skill is a pass without a phase change, with no open call:
`--handoff --to <skill> --step <its entry step> --returns no --why 'user ran the command'`, with no
`--phase`. The current phase stays. An on-demand skill drives no phase.

### Recovery

On every resume the agent first runs `writeback-state.sh --check`. It writes nothing. It prints one
line for each problem and exits 9 when there is one. The problems are:

- the record is missing a part of itself: no `intent.reading`, `active_skill` set to `none` on an open
  work, or a saved skill with `step` set to `--`;
- the record is inconsistent: a finished work that still names a saved skill, a saved skill that is
  not installed, or a malformed open call;
- the resumed skill's validation finds a saved step whose artifact is not on disk.

The agent does not repair on its own. It tells the user what it found, and proposes the whole
repaired record (the type, the skill and the step) as **one** confirmation question under the
question protocol, with its recommendation:

- the skill and step come from the skill's own detection (for a work started before the record
  existed, from the legacy block of the gate);
- the type is proposed only when `intent.reading` is missing, from the evidence on disk: the request
  or objective in the work's requirements, an idea draft, or the caller that started the work.

Only after the user confirms, or corrects any part in the same answer, does the agent run
`--repair --skill <skill> --name <step> [--detail '<where>'] [--reading <type>]`. `--reading` is
required when the record has none; the writer refuses without it. The repair appends a
`lifecycle_history` entry that names the old and the new record. After one confirmed repair the
record is complete, and `--check` passes.

### Writer modes

Every mode uses the writer's lock and writes one complete file. Exit 2 is a lock timeout, and the
file is then unchanged.

| Mode | Writes |
|------|--------|
| `--create` | the record, from the template, in one write. Run only by the gate. Exit 8 when the work already has a `STATE.yml`; exit 5 when a required option is missing; exit 4 when a value is invalid |
| `--step --skill S --name N [--detail D]` | `active_skill`, `step`, `step_detail` (`--` when no detail), and `updated` |
| `--reroute --reading R [--depth D] --why W` | `intent.reading` and `intent.depth`, plus an `intent.changes` entry |
| `--check` | nothing. Exit 9 when there is a problem, 0 when the record is healthy |
| `--repair --skill S --name N [--detail D] [--reading R]` | the record in one write, plus a `lifecycle_history` entry. Used only after the user confirms |
| `--handoff --to S --step N --why W --returns yes` | a `handoffs` entry holding the current skill, step and detail as the `from` values; then `active_skill` S, `step` N and `step_detail` `--`, in the same write |
| `--handoff --to S --step N --why W --returns no [--phase P]` | the same as the call, with no open call left; `phase` P is set only when `--phase` is given |
| `--handoff-return` | `returned` on the open call, and `active_skill`, `step` and `step_detail` restored from it. Exit 7 when there is no open call |
| `--ask ...` | a `Pending` entry in `qa`, and its id printed |
| `--answer --id Q<n> --state Answered or Skipped or Assumed ...` | that entry |

Finishing clears the saved skill. Whenever the writer sets the lifecycle to `Completed` or `Canceled`,
it also sets `active_skill` to `none` and clears `step` and `step_detail` in the same locked write.

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes.** Which skill and
which step a work continues at always come from the work record. A skill's own detection from its
artifacts does two things only: a skill starting fresh on a work runs it inside its entry step to
decide how far that step goes; and on resume it checks the saved step against what is on disk. A
mismatch goes to recovery, never to a silent re-route.

## When approvals happen

Approvals are asked by the main conversation, at the moments below. The depth is the work's
`intent.depth`; with none recorded, `full` applies.

| Moment | `full` | `lite` |
|--------|--------|--------|
| The idea draft, when one is written (Definition) | approve | -- |
| The business part of the requirements, before the technical part is designed (Specification) | approve | -- |
| The requirements document (Specification) | approve | -- |
| The plan (Planning) | approve | -- |
| Confirmation before building, when building opens; the per-wave option is asked here | approve | approve |
| End of each wave, only when chosen | approve | approve |
| End of each delivery | approve | approve |
| End of the whole build | approve | approve |
| The final result | approve | approve |

- **Coinciding approvals are one approval (M11).** Approvals that fall at the same moment are one
  approval. On a work with one delivery, the delivery, whole-build and final-result approvals are
  one.
- **Each approval also confirms the small decisions it covers (Q36).** Small decisions the agent took
  alone are recorded as `Assumed`, and are confirmed in one batch with the next approval that covers
  them. Each approval is recorded as a `qa` entry with `category: Approval`, its `covers` (the document
  or the milestone) and, when a push may follow, `commit` (the newest commit it approves). The
  final-result approval also sets `user_approved` to `'yes'`.
- **Each approval comes before the push it controls.** A push carries only commits up to the newest
  approved `commit`. The push itself is made by `/aid-monitor-pipeline`, which checks this first.

## Never merges

AID never merges a work into its parent branch, and no skill or script merges a PR or MR. The one
exception is the conflict merge that brings the parent branch, or the work branch's own remote copy,
into the work's branch, only to resolve a conflict. That exception belongs to Feature 008
(`/aid-monitor-pipeline`), and its result is approved before it is pushed (Q85). A PR or MR is created
only on the user's yes, and only by `/aid-monitor-pipeline`.

## What the user sees

- **No banners.** No step names are shown in entry lines, and there is no position map of the
  process. No advancing or dispatching notices, and no closing messages that ask the user to run a
  command again. A step name appears only as the target of an advance line, which the site flow
  builder reads.
- **At most one plain progress line,** when a step starts work that takes noticeable time, for example
  "Checking the plan against the Knowledge Base." It never names a step.
- **"Where are we?"** is answered from the work record: the phase, what is done, what is next, the
  open questions, and any open call.
