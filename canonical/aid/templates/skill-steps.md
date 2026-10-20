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

Every step ends with exactly one ending, on its advance line: one advance word, or `ASK then HALT`,
which is one composite ending and not two words (see the advance words below). A line that names
only its next step is a `CHAIN`, and is written with the word and the arrow: `CHAIN → NAME`.

The step an advance line names is a step of the same skill's table, by its name. It is never a part
of a step, such as "Step 5" or "GENERATE -- Step 0d". When the next step depends on what the user
answers, the line names the one step that reads the answer and moves on from there. A step that has
read the answer may branch on one `CHAIN` line: one named step per case, and `HALT when ...` for the
case on which the run ends.

## The advance words

The advance words are internal. They are never shown to the user.

| Word | Meaning |
|------|---------|
| `CHAIN` | Go on to the next step now, in the same run. |
| `ASK` | The step ends with a question that blocks the work. The step pauses on it; once every question is answered or skipped (an approval is never skipped: it stays open until the user approves or declines), the step is finished and the work goes on to the step the line names. Use it only when no write that depends on the answer remains in the step; if any does, the question is a pause inside the step (part 3 of the step procedure), and the step ends with the advance that follows that work. |
| `ASK then HALT` | The run ends with a question that blocks the work, such as which skill to run next. The question stays open; any resume shows it first, and once it is answered or skipped (an approval is never skipped) the run ends as `HALT` does. |
| `WAIT` | The user must do something outside the conversation. Say what, plainly, and stop. The step stays saved and its detail says what is waited for; once the user says it is done, the work goes on to the step the line names. |
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
3. **Questions, at any point.** The main conversation may ask the user anything at any point of a
   step, through the question protocol, whenever it needs to.
   - A question that does not block the work is asked, and the step carries on.
   - A question that blocks the work pauses the step where it stands. Keep the same step saved and
     bring its detail up to date with `--step`: what is done, and which question is open. Record each
     question with `--ask`. Set the lifecycle and the pause reason through the writer
     (`--pipeline --field Lifecycle --value Paused-Awaiting-Input`, then
     `--pipeline --field "Pause Reason" --value '<why>'`). Then ask.
   - Answered in the same conversation: record each answer with `--answer`, set the lifecycle back to
     `Running` (`--pipeline --field Lifecycle --value Running`), and continue the same step from
     where it stopped.
   - Answered later: any session that resumes finds the saved step and the open questions, and asks
     the open questions first, until each is answered or skipped (an approval is never skipped: see
     When approvals happen). It records each answer with `--answer` and sets the lifecycle back to
     `Running` with `--pipeline --field Lifecycle --value Running`, the same call as in the bullet
     above. Then it continues the same step from its detail, and does not redo what the detail says
     is done.
   - An `ASK` advance is this pause at the end of a step, used only when no write that depends on
     the answer remains in the step. Once its questions are answered or skipped (an approval is never
     skipped), whichever session reads the answer records it with `--answer`, sets the lifecycle back
     to `Running` with `--pipeline --field Lifecycle --value Running`, and the step is finished: the
     work goes on to the step the line names, which is then saved with `--step`.
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

The writer finds the record itself: the file `AID_STATE_FILE` names when it is set; otherwise the
`STATE.yml` of the work folder it runs in, or under; otherwise the one work whose worktree it runs in.
A skill passes no path. This holds for every mode that writes the work's record, `--pipeline`
(lifecycle, phase, pause and block reasons) included, and the task and delivery modes (`--task-id
--field`, `--findings`, `--block`, `--lifecycle`, `--gate-field`, `--append-issue`) too; those find
the work the same way unless the caller names where the work lives: `AID_WORK_DIR` for all of them,
or the mode's own override (`AID_TASK_STATE_FILE`, `AID_DELIVERY_STATE_FILE`, `AID_DELIVERY_DIR`, and
`AID_DELIVERY_ISSUES_DIR` for `--append-issue`). When none of these finds exactly one work, the
writer exits 1 and says so; the third way needs git, and the message says when git is the cause.

### Before a work exists

Steps that run before the gate creates the work, such as a skill's intake and its new-or-continue
question, save nothing, because there is no record yet. Their questions are asked through the
question protocol, and their answers go into the record when the gate creates it: the user's words
into `intent.request`, and the step the caller names into `step`. A skill that never creates a work,
such as a Knowledge Base, ticket, connector, setting or chat skill, saves no steps; it records its
questions where `question-protocol.md` § Where each record lives says (the Knowledge Base state file
while building the Knowledge Base, the project file `.aid/STATE.yml` with `--project` for every other
skill that keeps no work record and can run the writer: setting up the project, chat). The ticket
skills cannot run the writer; they ask their own questions (the connector pick, and the confirmation
before a ticket is filed or changed), and record nothing.

### Acting on an existing work (`/aid-orchestrate`)

`/aid-orchestrate` is the one skill whose steps may act on a work that already exists (a continued
work, a cancel, a close) without being that work's skill. Its steps for such a work write no `--step`,
no pause and no `--handoff`: the work's record keeps its saved skill, step and `step_detail`, because
those belong to the skill that is running the work, and a write of its own would overwrite them. The
only writes are:

- each answer to an open question of that work, with `--answer`, and the lifecycle back to `Running`
  through the writer once none is left open (part 3 of the step procedure), also for a paused work
  that had none open;
- the cancel or close the user confirmed, through the writer.

The questions it asks of such a work (which work the request continues, the work's open questions, the
cancel confirmation) pause the step where it stands, as any blocking question does, but write no pause:
the work's record is not touched until they are answered. The cancel confirmation is an intake question
(`question-protocol.md`, The intake-question exception), and is not recorded with `--ask`.

Its `PASS` for a continued work runs no `--handoff` (part 4 of the step procedure does not apply): the
record already names the skill and the step the work continues at, so the skill is started, in the same
turn, from the record. A `PASS` to start a new work's first phase skill, and every start of a new work,
follow the procedure unchanged.

### When the record is written

- **From creation, however the work starts**: a plain request through `/aid-orchestrate`, a typed
  slash command, or a one-pass doorway skill. The gate is the only creator of a work's record, as
  `.aid/runtime/templates/work-initiation-gate.md` § 3a describes. The gate runs the writer's
  create mode before it hands the new work back:
  `--create --work-dir <dir> --reading <type> --request '<words>' --skill <caller> --step <first step> [--phase <phase>] [--depth lite or full] [--path lite or full] [--minimum-grade G] [--reason R] [--phases P1,P2,...]`.
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
question protocol, with its recommendation. It is the only question of that turn; any other question
waits until it is answered. Nothing is written before the user's yes, the work record included, and the
question names no step: it says in plain words what is missing and what will be done again:

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
| `--create` | the record, from the template, in one write, with `pipeline.path` and `minimum_grade` set when `--path` and `--minimum-grade` are given, and `intent.reason` and `intent.phases` set when `--reason` and `--phases P1,P2,...` are given (phase names: Preparation, Definition, Specification, Planning, Building, CI). Run only by the gate. Exit 8 when the work already has a `STATE.yml`; exit 5 when a required option is missing; exit 4 when a value is invalid |
| `--pipeline --field F --value V` | one work-level key: `Lifecycle`, `Phase`, `Active Skill`, `Updated`, `Pause Reason`, `Block Reason`, `Block Artifact`, `Started`, `Minimum Grade`, `User Approved`, `Pipeline Path` or `Pipeline Initiator`. The record is found as above |
| `--step --skill S --name N [--detail D]` | `active_skill`, `step`, `step_detail` (`--` when no detail), and `updated` |
| `--reroute --reading R [--depth D] --why W` | `intent.reading` and `intent.depth`, plus an `intent.changes` entry |
| `--check` | nothing. Exit 9 when there is a problem, 0 when the record is healthy |
| `--intent [--reason R] [--phases P1,P2,...]` | `intent.reason` and/or `intent.phases` on an existing record, in one write; `--phases` replaces the whole list. Exit 5 when neither option is given; exit 4 for a phase name outside the six above |
| `--repair --skill S --name N [--detail D] [--reading R]` | the record in one write, plus a `lifecycle_history` entry. Used only after the user confirms |
| `--handoff --to S --step N --why W --returns yes` | a `handoffs` entry holding the current skill, step and detail as the `from` values; then `active_skill` S, `step` N and `step_detail` `--`, in the same write |
| `--handoff --to S --step N --why W --returns no [--phase P]` | the same as the call, with no open call left; `phase` P is set only when `--phase` is given |
| `--handoff-return` | `returned` on the open call, and `active_skill`, `step` and `step_detail` restored from it. Exit 7 when there is no open call |
| `--ask ...` | a `Pending` entry in `qa`, and its id printed |
| `--answer --id Q<n> --state Answered or Skipped or Assumed ...` | that entry |

A mode that appends to a list the record does not have yet (`handoffs`, `qa`, `intent.changes` or
`lifecycle_history`) adds the list first, in the same write. A work created before these lists
existed needs no repair for them.

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

- **An approval cannot be skipped (Q160).** It stays open, and its step stays paused, until the
  user approves or declines. Every other question may be skipped.
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

The rule holds when the user asks for the merge, however plainly or often. The agent says that the
merge is the user's own step, leaves every branch as it is, and offers no merge for later, in any form.

## What the user sees

- **No banners.** No step names are shown in entry lines, and there is no position map of the
  process. No advancing or dispatching notices, and no closing messages that ask the user to run a
  command again. A step name appears only as the target of an advance line, which the site flow
  builder reads.
- **At most one plain progress line,** when a step starts work that takes noticeable time, for example
  "Checking the plan against the Knowledge Base." It never names a step.
- **"Where are we?"** is answered from the work record: the phase, what is done, what is next, the
  open questions, and any open call.
