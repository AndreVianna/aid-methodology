---
name: aid-specify
description: >
  Write a feature's technical specification. Use when the features are defined and each
  one needs a specification.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit
argument-hint: "work-001/feature-001 (required)  [--reset] clear technical spec for this feature"
---

# Technical Specification — Conversational Refinement

Specify the technical implementation of a single feature through conversational refinement
with the user.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

**The agent is a tech lead.** It proposes concrete solutions grounded
in the existing architecture. The user validates, redirects, or deepens the discussion.

**One feature at a time.** The feature path is a required argument.

**The Loop:**

Every section follows the same cycle:

```
1. PROPOSE  → agent proposes (grounded in KB, codebase, SPEC)
2. DISCUSS  → user and agent refine together
3. WRITE    → save what was agreed into REQUIREMENTS.md §11 / Feature NNN
4. REVIEW   → grade what was written against KB/codebase reality
             → pass? next section. fail? back to 1.
```

**Re-run = enter at step 4 with existing content.**

**Workspace:**
```
.aid/
  knowledge/               ← shared KB
  work-NNN-{name}/
    STATE.yml              ← process (features sequence, qa sequence)
    REQUIREMENTS.md        ← product: §11 Features holds one section per
                              feature (decomposition from /aid-define +
                              Technical Specification from here). Features have
                              no folders and no files of their own.
```

> **Accuracy note.** Features State is **AUTHORED**: the `features:` sequence in
> `work-state-template.yml` holds one entry per feature, created by `/aid-define` at
> decomposition and updated here as each feature advances. Questions are recorded
> through `writeback-state.sh --ask` and `--answer` in the work's STATE.yml, never in a
> delivery's `qa`: this skill runs before any delivery exists (Specify precedes Plan).

---

## ⚠️ Pre-flight Checks

### Check 1: Feature Path Required

If no feature path was provided, resolve **work-first**: features live inside each
work's own worktree, so they cannot be listed from the main checkout until one is
entered — the feature glob below runs only after that.

1. Enumerate works **cross-worktree**: run
   `bash .aid/runtime/scripts/works/enumerate-works.sh` (main tree + every git
   worktree; never the local `.aid/works/` glob, which is empty on `master`), taking
   each record's field-1 `work_id`.
2. **Zero works** → **STOP.**
   ```
   No works found. Run /aid-describe first.
   ```
   Exit.
3. **Single work** → normalize its `work_id` to the bare `work-NNN` branch name and
   `locate`+enter it (`.aid/runtime/templates/downstream-worktree-entry.md` — the
   same mechanics as "Locate + Enter the Work's Worktree" below), then list *that*
   work's features locally, now visible inside the entered tree:
   ```
   Usage: /aid-specify feature-001

   Available features in work-001-user-auth:
     feature-001-login        [No STATE — not started]
     feature-002-password      [In Discussion — 2/5 sections]
   ```
   Read `REQUIREMENTS.md § 11 Features` inside the entered worktree. For each `###`
   feature subsection, check the work STATE.yml's `features:` entry (the one whose id is that
   feature) and show status.
   Exit.
4. **Multiple works** → show the work list, then ask which work in the question form
   (`.aid/runtime/templates/question-protocol.md`; no work is chosen yet, so nothing is
   recorded with `--ask`). Why I ask: the features belong to one work. My recommendation: the
   work named in the user's request, or the most recently updated one. The run waits for the
   answer; once chosen, normalize + `locate`+enter it exactly as step 3, then list its features
   the same way and exit.
   ```
   Usage: /aid-specify work-001/feature-001

   Available works:
     work-001-user-auth
     work-002-reporting
   ```

**Shortcut:** If only one work exists, accept bare `feature-001` and resolve
automatically — this is step 3 above; the single-work case already enters the work
before the feature glob runs.

### Locate + Enter the Work's Worktree

**As soon as the `work-NNN` prefix is parsed / auto-selected** (right after Check 1) and
**before** Check 2 resolves the feature in `REQUIREMENTS.md §11`, follow
`.aid/runtime/templates/downstream-worktree-entry.md` to normalize `<work-id>` to its bare
`work-NNN` branch name, `locate` the worktree (which **always exits 0** and returns
`<path>\t<status>`), and enter the returned path. Keep the defensive empty-path/non-zero backstop
that stops rather than operate blindly — it should not fire against the real helper. Never create
a new worktree — creation belongs to the work-starting skills only.

### Check 2: Feature Exists

Resolve the feature to a `###` subsection of `REQUIREMENTS.md § 11 Features` by its
three-digit number:
- `feature-001` → the `### Feature 001 — …` subsection of `.aid/works/{work}/REQUIREMENTS.md`
- `work-001/feature-002` → the `### Feature 002 — …` subsection of `.aid/works/work-001-*/REQUIREMENTS.md`

**If §11 is absent or has no such subsection:** Exit with instruction to run
`/aid-define` first (or `/aid-describe`, if REQUIREMENTS.md itself is missing).
**If found:** continue; the feature's `### Feature NNN — {Title}` heading names it.

The number is exact, not a prefix match: sections are numbered, so there is nothing
to disambiguate and no glob to widen.

### Check 3: Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

---

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN/feature-NNN` | **Required.** Path to the feature to specify. |
| `feature-NNN` | Shortcut when only one work exists. |
| `--reset` | Clear the feature section's `#### Technical Specification` back to its placeholder and delete STATE.yml. |

---

## State Detection

The feature is a section of `.aid/works/{work}/REQUIREMENTS.md § 11`; its per-feature process state is its entry in the work `STATE.yml`'s `features:` sequence.

Steps move and record by `.aid/runtime/templates/skill-steps.md` (the step entry, the advance words and the
work record); this skill restates none of them.

**Detection shapes the entry step and validates a saved step, and never routes.** A fresh start on a work
runs the checks below to decide how far the entry step goes. On resume the saved step is checked against what
is on disk, and a mismatch goes to recovery, never to a silent re-route. Which skill and which step a work
continues at come only from its work record.

**Saving the step.** Every step saves itself on entry, before any work, with
`bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill aid-specify --name <STEP> --detail '<where>'`,
where `<STEP>` is one of INITIALIZE, CONTINUE, SPIKE, BLOCKED, REVIEW or DONE. On a resume, validate the saved step
first: a step whose artifact is missing writes no `--step` and goes to recovery. The detail holds what the step has
settled: the work, the feature and the section being specified. When the work record does not already name
`aid-specify` (the user typed `/aid-specify`; no skill handed the work on), the first step first records the typed
start: `--handoff --to aid-specify --step INITIALIZE --why 'user ran the command' --returns no`, with no `--phase`.

```
State 1: No features[] entry, or state Pending, in work STATE.yml -> INITIALIZE
State 2: Feature State: In Discussion                         → CONTINUE
State 3: Feature State: Spike Needed                          → SPIKE
State 4: Feature State: Blocked (loopback pending)            → BLOCKED
State 5: Feature State: Ready                                 → REVIEW (enter loop at step 4)
```

A saved REVIEW or DONE whose feature has no `#### Technical Specification` content in § 11 is a mismatch.
Its recovery proposes CONTINUE: the feature's state goes back to `In Discussion`, and the specification
is written again from its first pending section. Ask that repair question alone, in plain words with no
step name and no state-entry line or map, and change no file, the work record included, before the
user's yes. The first section's own question comes after the repair is written.

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| INITIALIZE | `references/state-initialize.md` | `aid-architect` | CHAIN → CONTINUE |
| CONTINUE | `references/state-continue.md` | `aid-architect` | CHAIN → REVIEW when every section is Complete; CHAIN → SPIKE when a spike is needed; CHAIN → BLOCKED when a loopback blocks it |
| SPIKE | `references/state-spike.md` | `inline` | WAIT → CONTINUE |
| BLOCKED | `references/state-blocked.md` | `inline` | WAIT → CONTINUE |
| REVIEW | `references/state-review.md` | `aid-reviewer` | CHAIN → DONE when the spec stays Ready; CHAIN → CONTINUE when below minimum and fixable; HALT when core assumptions are wrong |
| DONE | `references/state-done.md` | `inline` | HALT |

When a state completes, its `**Advance:**` line decides the next move, as [`skill-steps.md`](../../aid/templates/skill-steps.md) § The advance words sets it. A HALT with an open call returns to the caller.

---

## Handling Outcomes During Discussion

Read `references/handling-outcomes.md` for how to handle KB issues, requirement gaps,
spikes, blocks, feature splits, and feature merges during discussion.

---

## Known Issues & Quality Gates

Read `references/known-issues-scope.md` for the known-issues filter (what to register
vs skip) and feature-specific quality gates (test/lint requirements beyond baseline).

---

## Conversation Style

**Do:**
- Propose concrete solutions based on what exists
- Reference specific files, classes, patterns
- Explain trade-offs when multiple approaches exist
- Push back if the user contradicts KB patterns
- Admit when you don't know something

**Don't:**
- Ask generic questions — propose based on KB
- Generate walls of spec without discussion
- Move to next section without clear agreement
- Be a yes-machine — if you see a problem, say so

**The rhythm:**
```
Agent: "Based on {KB}, I propose {concrete approach}."
Dev:   "Actually, we should do X because Y."
Agent: "Good point. That means we also need Z. Updated approach..."
Dev:   "Yeah, works."
Agent: [writes] [reviews: ✅ consistent] [next section]
```
