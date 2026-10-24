---
name: aid-orchestrate
description: >
  Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts, continues, closes or cancels a work.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit
argument-hint: "[request]  -- what you want to do, in your own words"
---

# Start, Resume, Close or Cancel a Work

`/aid-orchestrate` is the on-demand intake behind a plain request, sent here by the skill guide in
`.aid/runtime/rules.md` (a typed command never is). It runs in the main conversation and dispatches no
sub-agent: only the main conversation can talk with the user. Every question follows
`.aid/runtime/templates/question-protocol.md`.

## Steps

Work through the steps in order, as `.aid/runtime/templates/skill-steps.md` sets them, loading each reference
when its step comes up. No work exists before FIND-OR-CREATE: every question asked until then is recorded with
`--ask --design` in a design document, which `--rename-design` moves to the work's slug and the work's
`--create --seed` takes into its `qa` (`work-initiation-gate.md` § Recording the questions asked before a work
exists). A step that acts on an existing work (a continued work, CANCEL, CLOSE) follows `skill-steps.md`
§ Acting on an existing work.

1. **Project question** (`PROJECT-QUESTION`). `references/check-intent.md` step 0 spots a question about the
   project; `references/start-or-resume.md` step 1 answers it from the Knowledge Base, with sources.
   **Advance:** **CHAIN** → CHECK-READING when the request is not a project question; **HALT** when it is.
2. **Check the reading** (`CHECK-READING`). `references/check-intent.md` steps 1 to 5 classify the request by its
   observable effect, against the Knowledge Base and the code. **Advance:** **CHAIN** → CANCEL when it names a work
   to cancel; **CHAIN** → CLOSE when it names a work to close; otherwise **CHAIN** → SIZE-READING.
3. **Size the reading** (`SIZE-READING`). `references/size-and-route.md` sections 1 and 2 pick the phases and the
   depth; with no Knowledge Base, offer Preparation too (section 5). **Advance:** **CHAIN** → SHOW-READING.
4. **Show the reading** (`SHOW-READING`). One line with its reason, the phases and the depth, inside the go-ahead: one approval question
   that asks to start it (the reading never rides on a separate clarifying question), or alone when
   `references/size-and-route.md` section 6 starts the skill at once. Otherwise wait; it is never a turn of its own.
   When CHECK-READING kept two plausible outcomes, this go-ahead offers both in plain words rather
   than only confirming the preferred one. Decide between those outcomes before asking for symptom or implementation
   details; clarify first only when the possible outcomes themselves cannot yet be identified. Explain why the recommendation fits the reported problem;
   a workflow's requirement to ask permission is not the reason for choosing that reading.
   **Advance:** **CHAIN** → FIND-OR-CREATE when section 6 applies; otherwise **ASK** → ACTION-HANDOVER.
5. **Read the answer** (`ACTION-HANDOVER`). Only a yes to the SHOW-READING go-ahead decides; an answer to a clarifying question never
   does. A reading that matches an action skill (`/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`, `/aid-test`,
   `/aid-prototype`) goes to START-ACTION; any other reading goes on to FIND-OR-CREATE. A correction goes back to the check.
   **Advance:** **CHAIN** → START-ACTION when the approved reading matches an action skill; **CHAIN** → FIND-OR-CREATE when it matches
   none; **CHAIN** → CHECK-READING when the user corrects it; **HALT** when the user declines.
5a. **Start an action skill** (`START-ACTION`). Start that skill in this turn, with the reading as an `intent:` block
   (`.aid/runtime/templates/work-state-template.yml`); its START creates the work. **Advance:** **PASS**.
6. **Find or create the work** (`FIND-OR-CREATE`). `references/start-or-resume.md` section 3: a matching work is
   continued and keeps its reading; otherwise the gate creates the work. **Advance:** **CHAIN** → ASK-FIRST when
   several works plausibly match; otherwise **CHAIN** → RECORD-INTENT.
6a. **Ask before going on** (`ASK-FIRST`). `references/start-or-resume.md` sections 3a and 4: which work, when several
   match, and every open `qa:` question of a resumed work. Skip this step when neither applies.
   **Advance:** **CHAIN** → RECORD-INTENT.
7. **Record the intent** (`RECORD-INTENT`). `references/start-or-resume.md` section 6, through the writer only; a
   continued work already holds its intent. **Advance:** **CHAIN** → HAND-OVER.
8. **Cancel a named work** (`CANCEL`). `references/start-or-resume.md` section 5: one confirmation question, then
   the writer on a confirmed cancel. **Advance:** **HALT**.
9. **Close a work** (`CLOSE`). `references/size-and-route.md` section 3. **Advance:** **HALT**.
10. **Hand over** (`HAND-OVER`). Nothing more is asked. Start the first phase skill of a new work (`intent.phases`),
   or a continued work's skill at its saved step (`references/start-or-resume.md` section 4), in this turn,
   by `.aid/runtime/templates/skill-steps.md` § Starting a skill. **Advance:** **PASS**.
11. **During the work** (`DURING-WORK`). Load `references/external-sources.md` when a source is pulled in, applied
    or written back, and `references/feedback-routing.md` when feedback arrives; a re-route is said in one line
    and added to `intent.changes`. **Advance:** **CHAIN** → CHECK-READING when a new fact arrives; **HALT** when none does.

## Rules

- The user always decides how a work is persisted. When a tool cannot hold what must be written, stop, say so,
  and offer the workable options as one question.
- Detection never routes: it shapes the entry step and validates a saved step on resume (`skill-steps.md`
  § State Detection); the work record decides where a work continues.
