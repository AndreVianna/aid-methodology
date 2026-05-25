---
name: aid-interview
description: >
  Adaptive requirements gathering through conversational interview. First run
  builds REQUIREMENTS.md incrementally. Subsequent runs cross-reference against
  KB, grade, and ask targeted questions to resolve gaps and contradictions.
  Final step decomposes functional requirements into discrete feature files.
  State machine: FIRST-RUN → Q-AND-A → TRIAGE → {full: CONTINUE → COMPLETION → FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE | lite: CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW → LITE-DONE | escalated: any lite state → CONTINUE → ...full path...}.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit
argument-hint: "[work-001] resume work  [--reset work-001] clear and restart  [--features work-001] re-run feature decomposition"
---

# Adaptive Requirements Gathering

## Agents Involved

aid-interview is **multi-agent** — different states use different agents.

| State | Phase | Agent | Why |
|-------|-------|-------|-----|
| 1–4, TRIAGE | Conversational interview + triage | `interviewer` | Empathetic dialogue, deterministic routing |
| L1 CONDENSED-INTAKE | Lite-path condensed interview | `interviewer` | Sub-path-specific slot-fill dialogue |
| L2 TASK-BREAKDOWN | Lite-path task design | `architect` | Design work — proposing typed task breakdown |
| L3 LITE-REVIEW | Lite-path pre-execution gate | `reviewer` | Adversarial validation of task set against SPEC |
| L4 LITE-DONE | Lite-path terminal | (no dispatch) | Hand-off prompt to `/aid-execute` |
| 5 | Feature Decomposition | `architect` | Design work — breaking requirements into structured features |
| 6 | Cross-Reference & Refine | `reviewer` | Adversarial validation against KB and codebase |
| 7 | DONE | (no dispatch) | Terminal state, user choice prompt |

The frontmatter default `agent: interviewer` covers States 1–4, TRIAGE, and L1. L2 and 5 dispatch `architect`; L3 and 6 dispatch `reviewer`. L4 and 7 run inline.

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time
conversation. Builds REQUIREMENTS.md incrementally — each answer updates the document
immediately.

**Workspace structure (full path):**
```
.aid/
  knowledge/           ← shared KB (populated by /aid-discover)
  work-001-name/       ← one work = one interview cycle
    STATE.md           ← process (§§ Triage, Interview Status, Cross-phase Q&A, Features Status…)
    REQUIREMENTS.md    ← product (clean document, only project information)
    features/          ← product (one folder per feature, created after approval)
      feature-001-name/
        SPEC.md        ← product (technical specification, added by /aid-specify)
```

**Workspace structure (lite path):**
```
.aid/
  knowledge/           ← shared KB (populated by /aid-discover)
  work-001-name/       ← one lite work
    STATE.md           ← process (§§ Triage, Tasks Status, Lifecycle History…)
    SPEC.md            ← the ONE consolidated work-root spec (lite path only)
    tasks/
      task-001.md      ← 6-section flat task file
      task-002.md
      ...
```

A lite work has **no `features/` folder, no per-feature `SPEC.md`, no `REQUIREMENTS.md`, no `PLAN.md`** — just the work-root `SPEC.md` and `tasks/` folder.

**First run:** Conversational interview from scratch.
**Subsequent runs (before approval):** Resume interview for incomplete sections.
**After approval:** Feature decomposition from functional requirements.
**After features created:** Cross-reference REQUIREMENTS.md against KB, grade, ask questions.
**Loopback:** Process Q&A injected by downstream phases (e.g., `/aid-specify`).

## ⚠️ Pre-flight Checks

### Check 1: Verify Workspace Exists

Check if `.aid/` directory exists. If it doesn't:
```
⚠️ AID workspace not found. Run /aid-init first to set up the project.
```
Exit. Do not proceed.

### Check 2: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Work on the specified work item. |
| `--reset work-NNN` | Delete the work folder and restart from scratch. |
| `--features work-NNN` | Re-run feature decomposition for this work even if features exist. |
| *(no argument)* | Task routing (see below). |

---

## Task Routing

When no work ID is provided:

### No tasks exist

If `.aid/` has no `work-*` directories:

1. Ask for a short name for this work:
   ```
   What's a short name for this work? (e.g., "user-auth", "reporting", "api-v2")
   ```
2. Create `.aid/work-001-{name}/`
3. Proceed to State Detection with this work.

### Tasks exist

If `.aid/` has one or more `work-*` directories:

```
Existing works:
  work-001-user-auth   [Status: Approved, 3 features]
  work-002-reporting   [Status: In Progress, §5 Partial]

[1] Continue work-001-user-auth
[2] Continue work-002-reporting
[3] Create new work
```

Wait for response:
- **Continue existing:** proceed to State Detection for that work
- **Create new:** ask for name, create `work-{N+1}-{name}/`, proceed

**Shortcut:** If only one work exists and it's not yet Approved, go directly to it
without asking.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

All paths below are relative to `.aid/{work}/`.

```plaintext
State 1:  No STATE.md (§ Interview Status)                          → FIRST-RUN
State 2:  STATE.md § Cross-phase Q&A has Pending entries            → Q-AND-A
State T:  STATE.md § Triage absent or § Triage **Path:** missing    → TRIAGE
State L1: **Path:** lite, SPEC.md § Acceptance Criteria absent      → CONDENSED-INTAKE
State L2: **Path:** lite, SPEC.md § Acceptance Criteria present,
          tasks/ absent or empty                                    → TASK-BREAKDOWN
State L3: **Path:** lite, tasks/ present, LITE-REVIEW not complete  → LITE-REVIEW
State L4: **Path:** lite, LITE-REVIEW complete                      → LITE-DONE
State 3:  **Path:** full, Interview Status: In Progress, incomplete → CONTINUE
State 4:  **Path:** full, Interview Status: In Progress, all done   → COMPLETION
State 5:  **Path:** full, Interview Status: Approved,
          no feature folders                                        → FEATURE-DECOMPOSITION
State 6:  **Path:** full, Interview Status: Approved, features exist,
          cross-reference not yet done                              → CROSS-REFERENCE
State 7:  **Path:** full, Interview Status: Approved, features +
          cross-ref already complete                                → DONE
```

**Detection logic:**

1. If `--reset` → delete the work folder → recreate → proceed as State 1
2. Check for `STATE.md` in the work folder and look for the `## Interview Status` section
3. If missing → **State 1: FIRST-RUN**
4. If exists:
   a. Check `## Cross-phase Q&A` section for entries with `**Status:** Pending`
   b. If Pending entries exist → **State 2: Q-AND-A**
   c. Check `## Triage` section for a populated `**Path:**` field
      - If `## Triage` section is absent **or** `**Path:**` field is missing/empty → **State T: TRIAGE**
        (Exception: if `## Interview Status` exists and is not an empty scaffold — i.e., any
        section has status other than `Pending` — treat absent `**Path:**` as `full` and skip
        TRIAGE, to preserve backward compatibility with pre-TRIAGE in-flight works.)
   d. Read `**Path:**` from `## Triage`
   e. **If `**Path:** lite`** — route through lite-path detection:
      - Check work-root `SPEC.md` (``.aid/{work}/SPEC.md``):
        - If absent **or** `## Acceptance Criteria` section is absent/empty → **State L1: CONDENSED-INTAKE**
      - Check `tasks/` folder:
        - If `tasks/` absent or no `task-NNN.md` files present → **State L2: TASK-BREAKDOWN**
      - Check `STATE.md ## Lifecycle History` for a `LITE-REVIEW complete` entry:
        - If absent → **State L3: LITE-REVIEW**
        - If present → **State L4: LITE-DONE**
   f. **If `**Path:** escalated`** — check for incomplete escalation first:
      - Check if `.aid/{work}/SPEC.md` (work-root) still exists.
      - If **`Path: escalated` AND work-root `SPEC.md` still exists** → the
        final delete step (Step 9c of `lite-to-full-escalation.md`) did not
        complete (crash recovery). Replay escalation steps 9a–9c idempotently:
        ensure `features/feature-001-*/SPEC.md` placeholder exists, ensure
        `PLAN.md` placeholder exists, then delete the work-root `SPEC.md`.
        After replay, continue to full-path detection below.
      - Then route through full-path detection as `Path: full`:

   **If `**Path:** full` (or `escalated` after crash-recovery check above)** — route through full-path detection.
      `Path: escalated` is treated identically to `Path: full`. The `## Escalation Carry`
      block in STATE.md provides context for CONTINUE to avoid re-asking questions that
      were already answered during the lite-path session.
      - Read `**Interview Status:**` field in `## Interview Status`
      - If Status is `In Progress`:
        - Read Section Status table under `## Interview Status`
        - If any section is `Pending` or `Partial` → **State 3: CONTINUE**
        - If all sections are `Complete` or `N/A` → **State 4: COMPLETION**
      - If Status is `Approved`:
        - If `--features` flag provided → **State 5: FEATURE-DECOMPOSITION**
        - Check if `features/` directory exists and contains `feature-*` subdirectories
        - If no feature folders → **State 5: FEATURE-DECOMPOSITION**
        - If feature folders exist:
          - Check STATE.md `## Interview Status` `## Cross-Reference` sub-section for `**Status:** Complete`
            (or check if cross-reference entries exist from a prior run)
          - If cross-reference not yet done → **State 6: CROSS-REFERENCE**
          - If cross-reference already complete → **State 7: DONE**

Print the state-entry line and "you are here" map. Examples for each state:

**FIRST-RUN:**
```
[State: FIRST-RUN] — Start a new interview from scratch; create STATE.md and REQUIREMENTS.md scaffold.
aid-interview  ▸ you are here
  [● FIRST-RUN ] → [ Q-AND-A ] → [ TRIAGE ] → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**Q-AND-A:**
```
[State: Q-AND-A] — Resolve pending cross-phase questions before continuing.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [● Q-AND-A ] → [ TRIAGE ] → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**TRIAGE:**
```
[State: TRIAGE] — 3 deterministic questions to choose lite or full path.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [● TRIAGE ] → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
  (lite path)  → [ CONDENSED-INTAKE ] → [ TASK-BREAKDOWN ] → [ LITE-REVIEW ] → [ LITE-DONE ]
```

**CONDENSED-INTAKE (lite path L1):**
```
[State: CONDENSED-INTAKE] — Sub-path-specific condensed interview; write work-root SPEC.md.
aid-interview  ▸ you are here (lite path)
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [● CONDENSED-INTAKE ] → [ TASK-BREAKDOWN ] → [ LITE-REVIEW ] → [ LITE-DONE ]
  (escalate at any point) → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**TASK-BREAKDOWN (lite path L2):**
```
[State: TASK-BREAKDOWN] — Architect proposes typed task breakdown; writes tasks/task-NNN.md files.
aid-interview  ▸ you are here (lite path)
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONDENSED-INTAKE ] → [● TASK-BREAKDOWN ] → [ LITE-REVIEW ] → [ LITE-DONE ]
  (escalate at any point) → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**LITE-REVIEW (lite path L3):**
```
[State: LITE-REVIEW] — Reviewer grades task set against SPEC; pre-execution quality gate.
aid-interview  ▸ you are here (lite path)
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONDENSED-INTAKE ] → [✓ TASK-BREAKDOWN ] → [● LITE-REVIEW ] → [ LITE-DONE ]
  (escalate at any point) → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**LITE-DONE (lite path L4):**
```
[State: LITE-DONE] — Lite path complete; SPEC.md set to Ready; hand-off to /aid-execute.
aid-interview  ▸ you are here (lite path)
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONDENSED-INTAKE ] → [✓ TASK-BREAKDOWN ] → [✓ LITE-REVIEW ] → [● LITE-DONE ]
  (escalate: [E]) → [ CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**CONTINUE:**
```
[State: CONTINUE] — Resume the conversational interview for incomplete sections.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [● CONTINUE ] → [ COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**COMPLETION:**
```
[State: COMPLETION] — All sections captured; run KB hydration and present requirements for approval.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONTINUE ] → [● COMPLETION ] → [ FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**FEATURE-DECOMPOSITION:**
```
[State: FEATURE-DECOMPOSITION] — Decompose approved requirements into discrete feature folders.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [● FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ]
```

**CROSS-REFERENCE:**
```
[State: CROSS-REFERENCE] — Validate REQUIREMENTS.md against KB and codebase; create Q&A for gaps.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [✓ FEATURE-DECOMPOSITION ] → [● CROSS-REFERENCE ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Interview complete, approved, decomposed, and cross-referenced.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q-AND-A ] → [✓ TRIAGE ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [✓ FEATURE-DECOMPOSITION ] → [✓ CROSS-REFERENCE ] → [● DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FIRST-RUN | `references/state-first-run.md` | `interviewer` | → TRIAGE |
| Q-AND-A | `references/state-q-and-a.md` | `interviewer` | → TRIAGE |
| TRIAGE | `references/state-triage.md` | `interviewer` | → CONDENSED-INTAKE (Path: lite) / → CONTINUE (Path: full) |
| CONDENSED-INTAKE | `references/state-condensed-intake.md` | `interviewer` | → TASK-BREAKDOWN |
| TASK-BREAKDOWN | `references/state-task-breakdown.md` | `architect` | → LITE-REVIEW |
| LITE-REVIEW | `references/state-lite-review.md` | `reviewer` | → LITE-DONE (grade ≥ min) / → CONDENSED-INTAKE (grade < min, loopback). User-driven escalate → CONTINUE handled separately via `lite-to-full-escalation.md`. |
| LITE-DONE | `references/state-lite-done.md` | `inline` | → halt |
| CONTINUE | `references/state-continue.md` | `interviewer` | → COMPLETION |
| COMPLETION | `references/state-completion.md` | `interviewer` | → FEATURE-DECOMPOSITION |
| FEATURE-DECOMPOSITION | `references/state-feature-decomposition.md` | `architect` | → CROSS-REFERENCE |
| CROSS-REFERENCE | `references/state-cross-reference.md` | `reviewer` | → DONE |
| DONE | `references/state-done.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-interview again` and exit.

**User-driven escalate-to-full (lite → full):** Not represented as a dispatch-row branch (per feature-002 SPEC: Conditional advance is for *computed* criteria only, never user input). From any lite-path state (CONDENSED-INTAKE / TASK-BREAKDOWN / LITE-REVIEW / LITE-DONE), if the user invokes escalate, the orchestrator loads `references/lite-to-full-escalation.md` (a state-detection-driven re-entry), which writes `Path: escalated` to STATE.md and routes to CONTINUE on the next run.

---

## Targeted Interview (Loopback Re-entry)

When a downstream phase (e.g., `/aid-specify`) needs clarification on requirements:

1. The calling phase writes Q&A entries directly to the work's STATE.md
   in the `## Cross-phase Q&A` section
2. Next `/aid-interview {work}` run detects Pending Q&A → enters State 2 (Q-AND-A)
3. Questions are presented to the user one at a time
4. Answers are recorded in STATE.md `## Cross-phase Q&A` and REQUIREMENTS.md
5. Feature SPEC.md files are updated if the answer affects a specific feature

**Q&A entry format for downstream phases to write:**

```markdown
### IQ{N}: [{Category}: {Impact}]

**Question:** {question text}
**Context:** {why this matters — what the downstream phase found}
**Source:** {calling phase, e.g., /aid-specify work-001/feature-001}
**Suggested:** {answer if inferrable, or "—"}
**Status:** Pending
```
