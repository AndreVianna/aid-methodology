---
name: aid-specify
description: >
  Technical specification through conversational refinement, one feature at a time.
  The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes
  technical solutions, and builds the spec collaboratively with the user.
  Writes to SPEC.md in the feature folder.
  State machine: INITIALIZE → CONTINUE → REVIEW → DONE (SPIKE / BLOCKED are loopback states that return to CONTINUE).
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit
argument-hint: "work-001/feature-001 (required)  [--reset] clear technical spec for this feature"
---

# Technical Specification — Conversational Refinement

Specify the technical implementation of a single feature through conversational refinement
with the user.

**The agent is a tech lead, not an interviewer.** It proposes concrete solutions grounded
in the existing architecture. The user validates, redirects, or deepens the discussion.

**One feature at a time.** The feature path is a required argument.

**The Loop:**

Every section follows the same cycle:

```
1. PROPOSE  → agent proposes (grounded in KB, codebase, SPEC)
2. DISCUSS  → user and agent refine together
3. WRITE    → save what was agreed to SPEC.md
4. REVIEW   → grade what was written against KB/codebase reality
             → pass? next section. fail? back to 1.
```

**Re-run = enter at step 4 with existing content.**

**Workspace:**
```
.aid/
  knowledge/               ← shared KB
  work-NNN-{name}/
    STATE.md               ← process (§ Features State table, § Cross-phase Q&A)
    REQUIREMENTS.md
    features/
      feature-NNN-{name}/
        SPEC.md            ← product (requirements + technical specification)
```

---

## ⚠️ Pre-flight Checks

### Check 1: Feature Path Required

If no feature path was provided, list available features across all works:

```
Usage: /aid-specify work-001/feature-001

Available features:
  work-001-user-auth/feature-001-login        [No STATE — not started]
  work-001-user-auth/feature-002-password      [In Discussion — 2/5 sections]
  work-002-reporting/feature-001-dashboard     [Ready ✅]
```

Scan all `.aid/work-*/features/feature-*/` directories.
For each, check the work STATE.md `## Features State` row for this feature and show status. Exit.

**Shortcut:** If only one work exists, accept bare `feature-001` and resolve automatically.

### Check 2: Feature Exists

Resolve the feature path using **prefix matching** (glob):
- `feature-001` → match `.aid/{work}/features/feature-001-*/SPEC.md`
- `work-001/feature-002` → match `.aid/work-001-*/features/feature-002-*/SPEC.md`

**If zero matches:** Exit with instruction to run `/aid-interview` first.
**If multiple matches:** List them, ask user to be more specific. Exit.
**If exactly one match:** Use that path. Print: `[Resolved: {full-path}]`

### Check 3: Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

---

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN/feature-NNN` | **Required.** Path to the feature to specify. |
| `feature-NNN` | Shortcut when only one work exists. |
| `--reset` | Clear `## Technical Specification` from SPEC.md and delete STATE.md. |

---

## State Detection

All paths relative to `.aid/{work}/features/{feature}/`.

```
State 1: No Feature State row in work STATE.md               → INITIALIZE
State 2: Feature State: In Discussion                         → CONTINUE
State 3: Feature State: Spike Needed                          → SPIKE
State 4: Feature State: Blocked (loopback pending)            → BLOCKED
State 5: Feature State: Ready                                 → REVIEW (enter loop at step 4)
```

Print the state-entry line and "you are here" map. Examples for INITIALIZE:

```
[State: INITIALIZE] — First run for this feature; load context, determine sections, begin The Loop.
aid-specify ({feature})  ▸ you are here
  [● INITIALIZE ] → [ CONTINUE ] → [ REVIEW ] → [ DONE ]
```

For CONTINUE:
```
[State: CONTINUE] — Resume The Loop (Propose → Discuss → Write → Review) for the next pending section.
aid-specify ({feature})  ▸ you are here
  [✓ INITIALIZE ] → [● CONTINUE ] → [ REVIEW ] → [ DONE ]
```

For REVIEW:
```
[State: REVIEW] — All sections complete; re-review entire spec against current KB and codebase.
aid-specify ({feature})  ▸ you are here
  [✓ INITIALIZE ] → [✓ CONTINUE ] → [● REVIEW ] → [ DONE ]
```

For DONE (Ready):
```
[State: DONE] — Spec is Ready and has met the minimum grade.
aid-specify ({feature})  ▸ you are here
  [✓ INITIALIZE ] → [✓ CONTINUE ] → [✓ REVIEW ] → [● DONE ]
```

**SPIKE:**
```
[State: SPIKE] — Feature has unknowns requiring investigation; spike work needed.
aid-specify ({feature})  ▸ you are here
  [✓ INITIALIZE ] → [ CONTINUE ] → [● SPIKE ] → [ REVIEW ] → [ DONE ]
```

**BLOCKED:**
```
[State: BLOCKED] — Feature has a pending loopback that must be resolved before continuing.
aid-specify ({feature})  ▸ you are here
  [✓ INITIALIZE ] → [ CONTINUE ] → [● BLOCKED ] → [ REVIEW ] → [ DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| INITIALIZE | `references/state-initialize.md` | `aid-architect` | → CONTINUE |
| CONTINUE | `references/state-continue.md` | `aid-architect` | → REVIEW |
| SPIKE | `references/state-spike.md` | `inline` | → CONTINUE |
| BLOCKED | `references/state-blocked.md` | `inline` | → CONTINUE |
| REVIEW | `references/state-review.md` | `aid-reviewer` | → DONE |
| DONE | `references/state-done.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

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
