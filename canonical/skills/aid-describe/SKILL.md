---
name: aid-describe
description: >
  Gather requirements through an adaptive interview and write them to REQUIREMENTS.md. Use
  this skill when you know roughly what you want built but the scope, the users, and the
  acceptance criteria are not yet pinned down. It asks one question at a time, each chosen
  by a seasoned-analyst elicitation engine that picks its next move from the gaps in what
  you have said so far. The first run builds the document incrementally; a later run resumes
  wherever it is still incomplete. It ends by presenting the finished requirements for your
  approval and handing off to `/aid-define`.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit
argument-hint: "[work-001] resume work"
---

# Conversational Requirements Gathering

State machine: FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [approval, then HALT: /aid-define].

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

## Agents Involved

aid-describe is run by the main conversation, the only one that asks the user. Its states differ
only in what they do, not in who asks.

| State | Phase | Worker | Why |
|-------|-------|--------|-----|
| 1–4 | Conversational interview | inline (main conversation) | Empathetic dialogue, deterministic advancing; every question is asked through the question protocol |
| DESCRIBE-SEED | Greenfield KB seed authoring (aid-describe step per D3) | inline; dispatches `aid-reviewer` for step 5 | Engine-driven 5-element seed elicitation + doc authoring + coherence check + greenfield-mode review gate |

No sub-agent asks the user. DESCRIBE-SEED dispatches `aid-reviewer` for its step 5 greenfield-mode review gate, and that reviewer records its open questions and lists them in its report.

Gather requirements from a human stakeholder through the **seasoned-analyst elicitation
engine** (`references/elicitation-engine.md`): one fixed D1 opener followed by a
deterministic five-step next-move selector that adapts each question to the current gap,
calibration state, and move playbook (`references/move-playbook.md`,
`references/calibration.md`, `references/advisor-stance.md`). One question per turn.
Builds REQUIREMENTS.md incrementally -- each confirmed answer updates the document
immediately.

**Workspace structure:**
```
.aid/
  knowledge/           <- shared KB (populated by /aid-discover)
  work-001-name/       <- one work = one interview cycle
    STATE.md           <- process (§§ Interview State, Features State...; open questions are the work's `qa`)
    REQUIREMENTS.md    <- product (clean document, only project information)
    features/          <- product (one folder per feature, created by /aid-define)
      feature-001-name/
                       #  § 11 feature sections gain their technical specification
                       #  when /aid-specify runs
```

**First run:** Conversational interview from scratch.
**Subsequent runs (before approval):** Resume interview for incomplete sections.
**After approval:** Approved REQUIREMENTS.md is ready — run `/aid-define {work}` to decompose into features.
**Loopback:** Process Q&A injected by downstream phases (e.g., `/aid-specify`).

**Not sure where to start?** If you don't know whether this is a full requirements
gathering effort or a small single-purpose change, say what you need in plain words. The
plain-request routing in `rules.md` § Handling a request matches it to a skill; to start or
resume a work, `/aid-orchestrate` finds where the work stands, sizes it and picks the phases
it needs (a specific shortcut, or this skill, is among the outcomes).

## ⚠️ Pre-flight Checks

### Check 1: Verify Workspace Exists

Check if `.aid/` directory exists. If it doesn't:
```
⚠️ AID workspace not found. Run /aid-config first to set up the project.
```
Exit. Do not proceed.

### Check 2: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Work on the specified work item, through the gate (`.aid/runtime/templates/work-initiation-gate.md`). |
| *(no argument)* | Task routing (see below). |

### Direct `work-NNN` argument -- through the gate

A direct `work-NNN` argument goes through the gate's `§ 3a` (new) or `§ 3b` (continuation),
as Task Routing below does. An existing work is resumed through `§ 3b`: the gate locates and
enters its worktree, checks its record, and runs the skill the record names at its saved step.
A named `work-NNN` that does not exist is said so in one line, and then goes through the gate's
`§ 3a` like any new work, which gives it the next id.

---

## Task Routing

When no work ID is provided, consult the shared **Work Initiation Gate**
(`.aid/runtime/templates/work-initiation-gate.md`) before doing anything else. Run its
enumeration helper (which scans `.aid/works/*` across the main tree **and every git
worktree**):

```bash
bash .aid/runtime/scripts/works/enumerate-works.sh
```

### No works exist (empty output) -> NEW, no prompt

Run the gate's `§ 3a` (`.aid/runtime/templates/work-initiation-gate.md`) with this skill as the
caller, its first step `FIRST-RUN`, phase `Definition`, depth `full`, path `full`, and the minimum
grade from `bash .aid/runtime/scripts/config/read-setting.sh --skill describe --key minimum_grade --default A`.
This skill is the FULL-pipeline starter, never a flattened Lite shortcut. The gate resolves the id,
runs `worktree-lifecycle.sh create <work-id> <name>` to create and enter the worktree, reads the work's
type, and creates the work record through the writer before it hands the work back. This skill derives
the work's kebab-case short name, as the gate's `§ 3a` says the starter does, and passes it on. If the user gave no words, ask what they want to build, as
`.aid/runtime/templates/question-protocol.md` says; that answer is the request. No work exists yet, so that question and its answer are recorded in a design document, as the gate's "Recording the questions asked before a work exists" says: `--ask --design .aid/design/untitled-<YYYYMMDD-HHMMSS>.md` before it is shown, `--answer --design` after the reply (with the id the writer printed), then `--rename-design .aid/design/untitled-<YYYYMMDD-HHMMSS>.md --to .aid/design/<slug>.md` once the short name is known, and the gate's `--create` passes `--seed .aid/design/<slug>.md`.

Then proceed to State Detection with this work.

### One or more works exist -> ASK (never auto-continue)

Present the gate's single new-vs-continuation question, showing the enumerated list
(group by `work_id`; annotate each with its `[phase · lifecycle]` and worktree/branch
label from the helper's record columns):

No work is chosen yet, so record this question in the design document before it is shown (`--ask --design`) and its answer after the reply (`--answer --design`), as the gate's "Recording the questions asked before a work exists" says. Show it in the
protocol's form, with the list above it:

```text
Existing works:
  work-001-user-auth        [Definition · Running]                (main)
  work-002-reporting        [Planning · Running]                 (main)
  work-016-numberless-...   [Specification · Paused-Awaiting-Input] (worktree: work-016)

Your work -- question 1 of 1 -- importance: high
Is this a new work, or a continuation of one of those above?
Why I ask: a continuation picks up where that work stopped; a new work starts a fresh record.
My recommendation: {the one that fits the request best, and why; a new work when none fits}
  1. New work
  2. Continue work-001-user-auth
  3. Continue work-002-reporting
  4. Continue work-016-numberless-...
Or answer in your own words, ask me to explain, or skip this question.
```

Wait for the response, then act per the gate:

- **New work:** the gate's `§ 3a`, as above (`FIRST-RUN`, phase `Definition`).
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

> There is **no** auto-continue shortcut: a lone unapproved work is never silently
> resumed. The gate always asks when any work exists (deliberate UX change; the previous
> "if only one work exists and it's not yet Approved, go directly to it" behavior is
> removed).

---

## State Detection

State detection reads the files on disk, every run. Nothing remembered from an
earlier run or from this conversation counts as state, because the files may
have changed since.

Per `.aid/runtime/templates/skill-steps.md` § State Detection, this detection shapes the entry
step of a fresh start and validates a saved step on resume; it never routes. The work record
decides where a work continues.

All paths below are relative to `.aid/works/{work}/`.

```plaintext
State 1:  No STATE.md (§ Interview State)                           -> FIRST-RUN
State 2:  the work's qa has open entries, Pending or Skipped (STATE.yml) -> Q-AND-A
State 3:  Interview State: In Progress, incomplete                  -> CONTINUE
State GS: Interview State: In Progress, all done,
          greenfield (no brownfield KB on disk) + seed not complete -> DESCRIBE-SEED
State 4:  Interview State: In Progress, all done,
          not greenfield OR seed already complete                   -> COMPLETION
Approved: Interview State: Approved                                 -> hand-off to /aid-define
```

**Detection logic:**

1. Check for `STATE.md` in the work folder and look for the `## Interview State` section
2. If missing → **State 1: FIRST-RUN**
3. If exists:
   a. Check the work's `qa` (STATE.yml) for entries with `state: Pending` or `state: Skipped` (both are open)
   b. If open entries exist → **State 2: Q-AND-A**
   c. Read `**Interview State:**` field in `## Interview State`
      - If State is `In Progress`:
        - Read Section Status table under `## Interview State`
        - If any section is `Pending` or `Partial` → **State 3: CONTINUE**
        - If all sections are `Complete` or `N/A`:
          **Greenfield check:** read `.aid/knowledge/` -- if no `.md` files are present OR every
          `.md` file present carries `source: forward-authored` (authored by DESCRIBE-SEED in a
          prior session), the project is greenfield (no brownfield KB on disk). If any file
          carries `source: hand-authored` or `source: generated`, the project is brownfield.
          **Seed check:** read STATE.md `## Seed Authoring` `**Status:**`. If the section is
          absent or its value is not `Complete`, the seed is not yet done.
          - If greenfield AND seed not done → **State GS: DESCRIBE-SEED**
          - Otherwise → **State 4: COMPLETION**
      - If State is `Approved`:
        - Print: Requirements for {work} are approved. Run /aid-define {work} to decompose into features.
        - HALT

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FIRST-RUN | `references/state-first-run.md` | inline | CHAIN → CONTINUE |
| Q-AND-A | `references/state-q-and-a.md` | inline | CHAIN → CONTINUE |
| CONTINUE | `references/state-continue.md` | inline | CHAIN → DESCRIBE-SEED when the work is greenfield and its seed is not yet complete; CHAIN → COMPLETION when the work is brownfield, or its seed is already complete |
| DESCRIBE-SEED | `references/state-describe-seed.md` | inline; dispatches `aid-reviewer` for step 5 | CHAIN → COMPLETION |
| COMPLETION | `references/state-completion.md` | inline | CHAIN → CONTINUE when the user adds a consideration; HALT when the user approves, naming `/aid-define {work}` |

Each state's `**Advance:**` word is applied as [`skill-steps.md`](../../aid/templates/skill-steps.md) defines it.

---

## Targeted Interview (Loopback Re-entry)

When a downstream phase (e.g., `/aid-specify`) needs clarification on requirements:

1. The calling phase records its question with `writeback-state.sh --ask` in the work's `qa`
   (`Pending`, with `--asked-by` set to its own skill)
2. Next `/aid-describe {work}` run detects open Q&A (Pending or Skipped) → enters State 2 (Q-AND-A)
3. Questions are presented to the user one at a time, through the question protocol
4. Each answer is recorded with `writeback-state.sh --answer` in the work's `qa`, and in REQUIREMENTS.md
5. The affected `§ 11` feature section is updated if the answer bears on one feature

The entry is the question record of `.aid/runtime/templates/question-protocol.md`, written by the
writer; the calling phase does not write it by hand.
