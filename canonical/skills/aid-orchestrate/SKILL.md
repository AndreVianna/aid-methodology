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

Work through the steps in order. Load each reference when its step comes up.

1. **Question or work.** `references/check-intent.md` step 0 spots a question about the
   project; `references/start-or-resume.md` step 1 answers it from the Knowledge Base, and the
   flow stops there.
2. **Find the work.** `references/start-or-resume.md` steps 2 and 3. A matching work is
   continued from its resume point. Its reading stands unless a new fact has arrived.
3. **Check the reading.** `references/check-intent.md` steps 1 to 5, for a new work or for a
   continued work with a new fact. It compares the request with the Knowledge Base and the
   code, and classifies it by its observable effect.
4. **Size and record.** `references/start-or-resume.md` step 5 with
   `references/size-and-route.md`. The reading picks the phases; the richness of the input
   picks the depth. Record the `intent:` block in the work's `STATE.yml` at once.
5. **Show the reading.** In one line with its reason, inside the same message as the first
   real question or approval. Then wait for the answer. It is never a turn of its own.
6. **Hand over.** Start the first phase skill yourself. Where the tool cannot start a skill,
   name its slash command instead and let the user run it.
7. **During the work.** Load `references/external-sources.md` when a source is pulled in,
   applied or written back. Load `references/feedback-routing.md` when feedback arrives. A new
   fact or source triggers a re-check; a re-route is said in one line and added to
   `intent.changes`.

## Rules

- Record every state change in the work's `STATE.yml` the moment it happens: `intent:`,
  `sources:`, `write_backs:`, `lifecycle:`, `phase:` and `active_skill:`.
- Check every decision against the Knowledge Base. A conflict with it is raised with the
  user, never settled alone.
- Ask one topic at a time. Every question states its reason and gives a recommendation, lists
  only valid options and allows a free-text answer (FR-17).
- The user always decides how a work is persisted. When a tool cannot hold what must be
  written, stop, say so, and offer the workable options under the same question rule.
- AID stores no credential. Reads and writes to a tracker go through the host tool's own
  connection.
