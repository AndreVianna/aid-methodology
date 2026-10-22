---
kb-category: meta
source: hand-authored
objective: Defines the one question protocol every AID skill uses to ask the user anything, and the one record shape each answer is kept in.
summary: One question at a time, each with its reason, a recommendation and a free answer, grouped by subject in groups of 3 to 5; asked only by the main conversation, recorded before it is shown and after it is answered, and resumed when skipped.
review-criteria: []
---

# Question Protocol

**Every question AID puts to the user follows this file.** The rules are FR-17 of the project's
requirements, stated here as the procedure a skill runs. A skill that talks with the user carries
one line: "Talking with the user: follow `.aid/runtime/templates/question-protocol.md`."

**Only the main conversation asks.** The main conversation is the only one that can talk with the
user. A sub-agent never asks: it records each open question with `--ask`, leaves it `Pending`, and
lists it in its report, and the main conversation asks it. Skills run the protocol in the main
conversation only.

## The FR-17 rules

Each rule below is the rule itself. A question that breaks one of them is a defect.

### Rule 1 -- One question at a time

Never put one question that answers several topics at once.

### Rule 2 -- Short, with a reason

Every question is short and clear, and carries a short reason for asking it: **Why I ask**.

### Rule 3 -- Respect the user's technical level

Never ask a technical question of a non-technical user. Always assume the lower level. Give deeper
technical detail only when the user asks for it. The level is not stored.

### Rule 4 -- Always a recommendation

Every question has a recommendation, or a proposed answer, with its reason: **My recommendation**.

### Rule 5 -- Only valid options

Never offer an option that could lead to an error or a worse result.

- **Rule 5.1 -- One valid option is a confirmation.** When the recommendation is the only valid
  option, the question becomes a confirmation: "I'll do X because Y -- all right?"
- **Rule 5.2 -- Equal options are all shown.** When two or more options are equally valid and good,
  present them all, and say which is best.
- **Rule 5.3 -- No obvious questions.** Do not ask a question whose answer is obvious and needs no
  confirmation.
- **Rule 5.4 -- Free text always.** The closing line always lets the user give a different answer,
  ask for an explanation, or skip the question, in free text. An approval offers no skip: it ends with the
  approval line (see One question) and stays open until the user approves or declines (see Reviews and small decisions).

### Rule 6 -- Grouped by subject, most important first

Open questions are grouped by subject, so the user concentrates on one topic at a time. Within a
subject the most important question comes first. A group holds 3 to 5 questions. Small subjects
merge into one group only when they are genuinely related (for example naming and skill
descriptions); otherwise a small group stands alone.

### Rule 7 -- Offer a break

Offer a break after each group and whenever the subject changes:

    That's all on {subject}. Take a break, or go on to {next}?

A break offer decides nothing and is not recorded.

### Rule 8 -- Follow-ups come at once

A follow-up question comes straight after the question that raised it, inside the same group, so
the user keeps track.

### Rule 9 -- Skip what is already answered

When an earlier answer settles a question, or makes it trivial, do not ask it. Record it `Assumed`,
with the reason, and move on.

### Rule 10 -- Record every question and answer

Every question and its answer is recorded in the record shape below (a Knowledge Base question in
the Q&A section of its state file, see Where each record lives). A user who cannot answer
(lack of knowledge, and so on) may skip a question, except an approval, which cannot be skipped. A
skipped question stays open, and is offered again later to the same user or to another one.

## One question

Each question is shown in this plain-text form, one per message:

```text
Connections -- question 2 of 3 -- importance: high
Should AID reach your Jira through the connection your tool already has?
Why I ask: AID stores no passwords, so it needs your tool's own connection.
My recommendation: yes -- your tool is already signed in to Jira.
  1. Yes, use my tool's connection (recommended)
  2. Not now, skip Jira
Or answer in your own words, ask me to explain, or skip this question.
```

- The first line gives the group subject, the question's place in its group and its importance.
- Options appear only when two or more are valid, the recommended one first (Rule 5).
- The form shows two closing lines. A plain question ends with the question line above. An approval ends with
  the approval line, `Or answer in your own words, or ask me to explain.`, which has no skip. An approval is a yes
  that lets the agent change, build, delete, publish or push something, or that approves a document or design. A
  question that changes nothing when skipped, such as a reopen or close menu, is a plain question and ends with
  the skip line.
- **End-of-turn check.** Before you end a turn that waits on the user, the message has the first line
  with its importance, `Why I ask`, `My recommendation` and the right closing line, and its `--ask` record
  ran first. A closing or follow-up question ("Your call", "which would you like?", "shall I go on?") is a
  question like any other: the second and the last as much as the first. The exceptions are the break offer
  and the confirmations this protocol leaves unrecorded (recovery, cancel); a skill with no writer for its
  place records where Where each record lives says, or says it cannot.
- **An offer to start a skill is a go-ahead question.** Show it in the form with the approval line and record it
  like any other question; a bare "do you want to run /aid-x now?" is not one. A yes to an open question that
  already covers the action is the go-ahead (Rule 5.3): carry it out and do not ask again.
- The host tool's own question picker is never used. Every question is shown in this one form in
  every tool, so the reason and the recommendation read the same everywhere.

## Importance labels

Each question carries one importance label: `High`, `Medium` or `Low`. The most important question
of a group comes first. `Required` is retired.

## Reviews and small decisions

- **Reviews come in chunks.** A document is reviewed one topic at a time, most important topic
  first. Each chunk is a short plain summary of the decisions inside it, then one approval question.
- **Small decisions are confirmed in one batch.** A decision the agent takes on its own is recorded
  `Assumed`. It is confirmed in one batch with the next approval that covers it: the document's
  approval at `full` depth, the confirmation before building at `lite` depth, or the next milestone
  while building. No extra approval is asked for it.
- **An approval cannot be skipped.** It is shown without a skip option, and it stays open, with its
  step paused, until the user approves or declines.
- **A rejected decision reopens** as an ordinary question, in the usual group.

## The question record

One shape is used for the work's record and the project file alike:

```yaml
qa:
  - id: Q12
    category: Connections
    impact: High
    state: Answered
    asked_by: aid-set-connector
    step: --
    context: 'Reach Jira through the tool''s own connection? AID stores no passwords'
    suggested: 'Yes -- the tool is already signed in to Jira'
    answer: 'Yes'
    answered_by: 'Andre Vianna'
    applied_to: 'connector jira'
```

| Key | Meaning |
|-----|---------|
| `id` | `Q<n>`, the next free number in the file |
| `category` | the subject the groups follow |
| `impact` | the importance label: `High`, `Medium` or `Low` |
| `state` | one of the four states below |
| `asked_by` | the skill that asked the question |
| `step` | the step where the work resumes (`--` when none) |
| `context` | the question as it was shown, in one line |
| `suggested` | the recommendation as it was shown |
| `answer` | the user's answer, or the agent's decision for `Assumed` |
| `answered_by` | `git config user.name`, or `--` when there is no name |
| `applied_to` | what the answer changed, in one line |
| `covers` | approvals only: the items the approval covers |
| `commit` | approvals only: the commit the approval is given for |

### The four states

- `Pending` -- asked, and still open. Written before the question is shown.
- `Answered` -- the user answered it.
- `Skipped` -- the user did not answer. The question stays open and is offered again later, to the
  same user or to another one.
- `Assumed` -- the agent's own decision, waiting for its batch (see Reviews and small decisions).
  It becomes `Answered` once the batch is confirmed.

## Recording: `--ask` and `--answer`

A work's question and a project question are written through `writeback-state.sh`, the one writer
of those records (`.aid/runtime/scripts/execute/writeback-state.sh`). A Knowledge Base question is
written to the Knowledge Base state file instead, in the same states, until that file takes this shape.

- **`--ask`** appends a `Pending` entry and prints its id. It runs **before** the question is shown.
- **`--answer`** updates that entry with the state and the answer. It runs **right after** the
  answer is given.
- **`--project`** points either mode at the project file `.aid/STATE.yml`, which is created from
  the project-state template the first time it is needed. Without `--project`, the target is the
  work the writer finds for the current directory, which is its own `STATE.yml`.

## Where each record lives

| Asked while | Record |
|-------------|--------|
| working on a work | the work's `STATE.yml`, in its `qa` list |
| before a work exists (the design stage) | the design document under `.aid/design/`, in its `## Questions` table, with `--design`; a question asked before the subject is known opens `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, which `--rename-design <from> --to <to>` moves to `.aid/design/<slug>.md` once the subject is known |
| building the Knowledge Base | the Knowledge Base state file, `.aid/knowledge/STATE.md` |
| setting up the project (configure, connectors), in chat, or in any other skill that keeps no work record and can run the writer | the project file `.aid/STATE.yml`, with `--project` |
| in a ticket skill (no shell, so no writer) | nothing: the skill's own questions (the connector pick, the confirmation) are not recorded |

## Questions before a work exists

Before a work exists we are in the design stage. Every question asked then, with its answer, is
**recorded in the design document** under `.aid/design/`, in its `## Questions` table, with
`--ask --design <file>` before it is shown and `--answer --design <file> --id D<n>` right after the
answer. The table is `| id | question | answer | state | answered_by | category |`, and its ids (`D1`, `D2`, ...)
are the ones the writer prints, never written by hand. A question asked before the subject is known opens
`.aid/design/untitled-<YYYYMMDD-HHMMSS>.md` (`status: draft`); once the subject is known,
`--rename-design <from> --to <to>` moves it to `.aid/design/<slug>.md`, or, when that document exists,
appends its rows there and deletes the untitled one. Every `--design` path stays inside `.aid/design/`.
These are such questions: "what do you want?" on a bare start, which skill fits when the reading is
unsure, whether to start new work or continue an existing one, a work's short name, and every question a
design-stage skill asks. Design-stage skills open no work.

Their outcome travels with the document: a build skill that opens the work from it passes `--create --seed
<file>`, which lists the document in the work's `sources:` and copies its questions into the work's `qa`
list. If the user does not answer, nothing is created beyond the document.

Two questions concern a work that already exists and are not recorded: the recovery confirmation, which
proposes repairing a work record that is missing or inconsistent (`skill-steps.md` § Recovery; nothing is
written before its yes), and the confirmation to cancel a named work (`/aid-orchestrate`; the work's own
record is not paused or touched, and the answer is acted on at once). The orchestrator, the
work-initiation gate (`.aid/runtime/templates/work-initiation-gate.md`) or a starter asks them.

Questions from setup skills and from building the Knowledge Base are **not** design-stage questions. They
follow the normal recording above.

On start or resume, the open entries (`Pending` and `Skipped`) are offered first, in the usual groups.

## Quick reference

- One question, one topic, with **Why I ask**, **My recommendation**, valid options and a free answer.
- Groups of 3 to 5 by subject, most important first; a break after each group and at each change of subject.
- Follow-ups right after the question that raised them; answered or trivial questions recorded `Assumed`.
- Written `Pending` by `--ask` before it is shown; answered by `--answer` right after.
- Asked by the main conversation only; sub-agents record and list their questions.
