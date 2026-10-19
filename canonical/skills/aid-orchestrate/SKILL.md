---
name: aid-orchestrate
description: >
  Start, resume, close or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts, continues, closes or cancels a work.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit AskUserQuestion
argument-hint: "[request]  -- what you want to do, in your own words"
---

# Start, Resume, Close or Cancel a Work

`/aid-orchestrate` is the on-demand intake behind a plain request. It runs in the main
conversation and dispatches no sub-agent: only the main conversation can talk with the user.
The skill guide in `.aid/runtime/rules.md` sends a plain request here; a typed command for
another skill never runs here.

## Steps

Work through the steps in order, as `.aid/runtime/templates/skill-steps.md` sets them. Load
each reference when its step comes up. No work is created before step 6.

1. **Project question.** `references/check-intent.md` step 0 spots a question about the
   project; `references/start-or-resume.md` step 1 answers it from the Knowledge Base, with
   sources. The flow stops there, and no work is created.
2. **Check the reading.** `references/check-intent.md` steps 1 to 5 compare the request with
   the Knowledge Base and the code, and classify it by its observable effect. A request that
   names a work to cancel or close is an action on that work: it goes to step 8 or step 9.
3. **Size the reading.** `references/size-and-route.md` sections 1 and 2 pick the phases and the
   depth. When the project has no Knowledge Base, offer Preparation too
   (`references/size-and-route.md` section 5).
4. **Show the reading.** One line with its reason, the phases and the depth, in the same
   message as the first real question or approval. Then wait for the answer. It is never a
   turn of its own.
5. **Hand over an action-skill reading.** Once the user approves, a reading that matches an
   action skill (`/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`,
   `/aid-test`, `/aid-prototype`) is handed to that skill. Pass the block as an `intent:` line
   with its keys indented two spaces beneath it (`request`, `reading`, `reason`, `depth`,
   `phases` as `- <phase>` lines, `changes`), as in `.aid/runtime/templates/work-state-template.yml`.
   The skill's START creates the work through the gate and writes that block into it
   (`shortcut-engine.md` INTAKE Step 5). No work is created here, and this skill is done.
6. **Find or create the work.** `references/start-or-resume.md` steps 3 and 4. A matching work
   is continued from its resume point and keeps its reading; otherwise the gate creates the
   work. This is the first write the flow makes.
7. **Record the intent.** `references/start-or-resume.md` step 6. Write the `intent:` block
   into the new work's `STATE.yml` at once.
8. **Cancel a named work.** `references/start-or-resume.md` step 5. The flow stops there.
9. **Close a work.** `references/size-and-route.md` section 3: when every task is `Done` (or, for an
   investigation, when nothing was to land), set `phase` to `Building` and `lifecycle` to
   `Completed`. The flow stops there.
10. **Hand over.** Start the first phase skill yourself. Where the tool cannot start a skill,
    name its slash command instead and let the user run it.
11. **During the work.** Load `references/external-sources.md` when a source is pulled in,
    applied or written back. Load `references/feedback-routing.md` when feedback arrives. A new
    fact or source triggers a re-check; a re-route is said in one line and added to
    `intent.changes`.

## Rules

- Record every state change in the work's `STATE.yml` the moment it happens: `intent:`,
  `sources:`, `write_backs:`, `lifecycle:`, `phase:` and `active_skill:`.
- Check every decision against the Knowledge Base. A conflict with it is raised with the
  user, never settled alone.
- The question rule (FR-17), in full:
  - One topic and one question at a time, short, with a short reason for asking.
  - Pitch it at the user's technical level: never a technical question to a non-technical
    user; give deeper technical detail only when the user asks.
  - Always give a recommendation or proposed answer, with its reasoning.
  - Offer only valid options. One valid option makes it a confirmation; several equally good
    options are all shown, with the best one named. Skip obvious questions. Always let the
    user answer in free text or ask for clarification.
  - Group questions by subject, 3 to 5 per group, the most important first. Offer a break
    after each group and whenever the subject changes.
  - Ask a follow-up right after the question that raised it. Skip a question that an earlier
    answer settles or makes trivial.
  - Record every question and answer. A skipped question stays open and is resumed later.
- The user always decides how a work is persisted. When a tool cannot hold what must be
  written, stop, say so, and offer the workable options under the same question rule.
- State Detection (`skill-steps.md`): detection shapes the entry step and validates a saved
  step on resume; it never routes. The work record decides where a work continues.
- AID stores no credential. Reads and writes to a tracker go through the host tool's own
  connection.
