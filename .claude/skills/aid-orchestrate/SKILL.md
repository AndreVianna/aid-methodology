---
name: aid-orchestrate
description: >
  Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts, continues, closes or cancels a work.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit
argument-hint: "[request]  -- what you want to do, in your own words"
---

# Start, Resume, Close or Cancel a Work

`/aid-orchestrate` is the on-demand intake behind a plain request. It runs in the main
conversation and dispatches no sub-agent: only the main conversation can talk with the user.
The skill guide in `.aid/runtime/rules.md` sends a plain request here; a typed command never does.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

## Steps

Work through the steps in order, as `.aid/runtime/templates/skill-steps.md` sets them. Load
each reference when its step comes up. No work is created before FIND-OR-CREATE.

A step that acts on a work that already exists (a continued work, CANCEL, CLOSE) follows
`skill-steps.md` § Acting on an existing work: it writes no `--step` of its own into that work's
record, which keeps its saved skill, step and `step_detail`. The only writes are the answers to the
work's open questions (`--answer`), the lifecycle set back to `Running` through the writer once every one is
answered or skipped, and the cancel or close the user confirmed. A new work is saved from the gate's `--create`,
with RECORD-INTENT as its first step.

1. **Project question** (`PROJECT-QUESTION`). `references/check-intent.md` step 0 spots a question about the
   project; `references/start-or-resume.md` step 1 answers it from the Knowledge Base, with
   sources. No work is created. **Advance:** **CHAIN** → CHECK-READING when the request is not a
   project question; **HALT** when it is a project question.
2. **Check the reading** (`CHECK-READING`). `references/check-intent.md` steps 1 to 5 compare the request with
   the Knowledge Base and the code, and classify it by its observable effect. **Advance:** **CHAIN** → CANCEL when the request names a work to cancel;
   **CHAIN** → CLOSE when it names a work to close; otherwise **CHAIN** → SIZE-READING.
3. **Size the reading** (`SIZE-READING`). `references/size-and-route.md` sections 1 and 2 pick the phases and the
   depth. When the project has no Knowledge Base, offer Preparation too
   (`references/size-and-route.md` section 5). **Advance:** **CHAIN** → SHOW-READING.
4. **Show the reading** (`SHOW-READING`). One line with its reason, the phases and the depth, in the same
   message as the first real question or approval. Then wait for the answer; it is never a
   turn of its own. **Advance:** **ASK** → ACTION-HANDOVER.
5. **Read the answer** (`ACTION-HANDOVER`). The user's answer to SHOW-READING decides. A reading that matches an
   action skill (`/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`,
   `/aid-test`, `/aid-prototype`) goes to START-ACTION; any other reading goes on to FIND-OR-CREATE. A
   correction goes back to the check. **Advance:** **CHAIN** → START-ACTION when the approved reading matches an
   action skill; **CHAIN** → FIND-OR-CREATE when it matches none; **CHAIN** → CHECK-READING when the user corrects it;
   **HALT** when the user declines.
5a. **Start an action skill** (`START-ACTION`). Start that skill in this turn, with the reading as an `intent:`
   block (see `.aid/runtime/templates/work-state-template.yml`); where the tool cannot start it, name its
   command. No work exists yet, so there is no hand-off to write; its START creates the work.
   **Advance:** **PASS**.
6. **Find or create the work** (`FIND-OR-CREATE`). `references/start-or-resume.md` section 3. A matching work is
   continued from its resume point and keeps its reading; otherwise the gate creates the work,
   the flow's first write. **Advance:** **CHAIN** → ASK-FIRST when several works plausibly match;
   otherwise **CHAIN** → RECORD-INTENT.
6a. **Ask before going on** (`ASK-FIRST`). Ask one question when several works plausibly match
   (`references/start-or-resume.md` section 3a), and ask every open `qa:` question of a resumed
   work (section 4). The questions pause the step where it stands; when the answer is "a new work",
   the gate then creates it (section 3). Once the resumed work's open questions are answered, record
   each answer with `--answer` and set its lifecycle back to `Running` through the writer (section 4).
   Skip this step when neither applies.
   **Advance:** **CHAIN** → RECORD-INTENT.
7. **Record the intent** (`RECORD-INTENT`). `references/start-or-resume.md` section 6. The record's keys are set
   through the writer only, never by hand; a continued work already holds its intent and writes nothing.
   **Advance:** **CHAIN** → HAND-OVER.
8. **Cancel a named work** (`CANCEL`). `references/start-or-resume.md` section 5: one confirmation question,
   asked in this step as an intake question (the target work's record is not paused or touched),
   then the writer on a confirmed cancel. No new work is created. **Advance:** **HALT**.
9. **Close a work** (`CLOSE`). `references/size-and-route.md` section 3: when every task is `Done` (or, for an
   investigation, when nothing was to land), set the phase to `CI` and the lifecycle to
   `Completed`, both through the writer (`--pipeline`). The flow stops there. **Advance:** **HALT**.
10. **Hand over** (`HAND-OVER`). The user approved the reading at SHOW-READING, so nothing more is asked. Start the
    first phase skill of a new work (`intent.phases`), or, for a continued work, the skill its record names at
    its saved step (`references/start-or-resume.md` section 4), in this turn; where the tool cannot, name its
    slash command. A continued work is handed over unchanged: write no `--handoff` and no `--step`, so
    its record keeps the saved skill, step and `step_detail`. **Advance:** **PASS**.
11. **During the work** (`DURING-WORK`). Load `references/external-sources.md` when a source is pulled in, applied
    or written back, and `references/feedback-routing.md` when feedback arrives. A re-route is said
    in one line and added to `intent.changes`. **Advance:** **CHAIN** → CHECK-READING when a new fact arrives;
    **HALT** when none does.

## Rules

- Record every state change in the work's `STATE.yml` the moment it happens, through the writer
  (`writeback-state.sh`), never by hand: the intent, the sources, the write-backs, the lifecycle, the
  phase and the active skill.
- Check every decision against the Knowledge Base. A conflict with it is raised with the
  user, never settled alone.
- Ask only as `.aid/runtime/templates/question-protocol.md` says (FR-17): one topic at a time,
  with a reason and a recommendation; every question and answer is recorded.
- The user always decides how a work is persisted. When a tool cannot hold what must be
  written, stop, say so, and offer the workable options under the same question rule.
- State Detection (`skill-steps.md`): detection shapes the entry step and validates a saved
  step on resume; it never routes. The work record decides where a work continues.
- AID stores no credential. Reads and writes to a tracker go through the host tool's own
  connection.
