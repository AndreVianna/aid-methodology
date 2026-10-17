---
name: aid-orchestrate
description: >
  Start, resume or cancel an AID work: find where it stands, size it and pick its phases. Use when a plain request starts a new work, continues an existing one, or cancels one.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit AskUserQuestion
argument-hint: "[request]  -- what you want to do, in your own words"
---

# Start, Resume or Cancel a Work

`/aid-orchestrate` is the on-demand intake behind a plain request. It runs in the main
conversation and dispatches no sub-agent: only the main conversation can talk with the user.
The skill guide in `.aid/runtime/rules.md` sends a plain request here; a typed command for
another skill never runs here.

## Steps

Work through the steps in order. Load each reference when its step comes up. No work is
created before step 4.

1. **Project question.** `references/check-intent.md` step 0 spots a question about the
   project; `references/start-or-resume.md` step 1 answers it from the Knowledge Base, with
   sources. The flow stops there, and no work is created.
2. **Check the reading.** `references/check-intent.md` steps 1 to 5 compare the request with
   the Knowledge Base and the code, and classify it by its observable effect.
3. **Hand over an action-skill reading.** A reading that matches an action skill is handed to
   that skill now, as `references/size-and-route.md` step 1 lists. No work is created here: the
   skill's START creates it through the gate. This skill is done.
4. **Find or create the work.** `references/start-or-resume.md` steps 3 and 4. A matching work
   is continued from its resume point, and its reading stands unless a new fact has arrived.
   A request that cancels a named work goes to step 5 instead.
5. **Cancel a named work.** `references/start-or-resume.md` step 5: resolve the named work,
   select it, confirm once, then write `Canceled`. The flow stops there.
6. **Size and record.** `references/start-or-resume.md` step 6 with
   `references/size-and-route.md`. The reading picks the phases; the richness of the input
   picks the depth. Record the `intent:` block in the work's `STATE.yml` at once.
7. **Show the reading.** In one line with its reason, inside the same message as the first
   real question or approval. Then wait for the answer. It is never a turn of its own.
8. **Hand over.** Start the first phase skill yourself. Where the tool cannot start a skill,
   name its slash command instead and let the user run it.
9. **During the work.** Load `references/external-sources.md` when a source is pulled in,
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
- AID stores no credential. Reads and writes to a tracker go through the host tool's own
  connection.
