---
name: aid-interview
description: >
  Adaptive requirements gathering through conversational interview. First run
  builds REQUIREMENTS.md incrementally. Subsequent runs cross-reference against
  KB, grade, and ask targeted questions to resolve gaps and contradictions.
  Final step decomposes functional requirements into discrete feature files.
  State machine: FIRST-RUN → Q-AND-A → CONTINUE → COMPLETION → FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[work-001] resume work  [--reset work-001] clear and restart  [--features work-001] re-run feature decomposition"
---

# Adaptive Requirements Gathering

## Agents Involved

aid-interview is **multi-agent** — different states use different agents.

| State | Phase | Agent | Why |
|-------|-------|-------|-----|
| 1–4 | Conversational interview | `interviewer` | Empathetic dialogue, one question at a time |
| 5 | Feature Decomposition | `architect` | Design work — breaking requirements into structured features |
| 6 | Cross-Reference & Refine | `reviewer` | Adversarial validation against KB and codebase |
| 7 | DONE | (no dispatch) | Terminal state, user choice prompt |

The frontmatter default `agent: interviewer` covers States 1–4. States 5 and 6 explicitly override `subagent_type` at dispatch (see those state sections below).

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time
conversation. Builds REQUIREMENTS.md incrementally — each answer updates the document
immediately.

**Workspace structure:**
```
.aid/
  knowledge/           ← shared KB (populated by /aid-discover)
  work-001-name/       ← one work = one interview cycle
    STATE.md           ← process (§§ Interview Status, Cross-phase Q&A, Features Status…)
    REQUIREMENTS.md    ← product (clean document, only project information)
    features/          ← product (one folder per feature, created after approval)
      feature-001-name/
        SPEC.md        ← product (technical specification, added by /aid-specify)
```

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
State 1: No STATE.md (§ Interview Status)                          → FIRST-RUN
State 2: STATE.md § Cross-phase Q&A has Pending entries            → Q-AND-A
State 3: STATE.md § Interview Status: In Progress, incomplete      → CONTINUE
State 4: STATE.md § Interview Status: In Progress, all done        → COMPLETION
State 5: STATE.md § Interview Status: Approved, no feature folders → FEATURE-DECOMPOSITION
State 6: STATE.md § Interview Status: Approved, features exist,
         cross-reference not yet done                              → CROSS-REFERENCE
State 7: STATE.md § Interview Status: Approved, features + cross-ref
         already complete                                          → DONE
```

**Detection logic:**

1. If `--reset` → delete the work folder → recreate → proceed as State 1
2. Check for `STATE.md` in the work folder and look for the `## Interview Status` section
3. If missing → **State 1: FIRST-RUN**
4. If exists:
   a. Check `## Cross-phase Q&A` section for entries with `**Status:** Pending`
   b. If Pending entries exist → **State 2: Q-AND-A**
   c. Read `**Interview Status:**` field in `## Interview Status`
   d. If Status is `In Progress`:
      - Read Section Status table under `## Interview Status`
      - If any section is `Pending` or `Partial` → **State 3: CONTINUE**
      - If all sections are `Complete` or `N/A` → **State 4: COMPLETION**
   e. If Status is `Approved`:
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
  [● FIRST-RUN ] → [ Q&A ] → [ CONTINUE ] → [ COMPLETION ] → [ FEATURES ] → [ CROSS-REF ] → [ DONE ]
```

**Q-AND-A:**
```
[State: Q-AND-A] — Resolve pending cross-phase questions before continuing.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [● Q&A ] → [ CONTINUE ] → [ COMPLETION ] → [ FEATURES ] → [ CROSS-REF ] → [ DONE ]
```

**CONTINUE:**
```
[State: CONTINUE] — Resume the conversational interview for incomplete sections.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q&A ] → [● CONTINUE ] → [ COMPLETION ] → [ FEATURES ] → [ CROSS-REF ] → [ DONE ]
```

**COMPLETION:**
```
[State: COMPLETION] — All sections captured; run KB hydration and present requirements for approval.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q&A ] → [✓ CONTINUE ] → [● COMPLETION ] → [ FEATURES ] → [ CROSS-REF ] → [ DONE ]
```

**FEATURE-DECOMPOSITION:**
```
[State: FEATURE-DECOMPOSITION] — Decompose approved requirements into discrete feature folders.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q&A ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [● FEATURES ] → [ CROSS-REF ] → [ DONE ]
```

**CROSS-REFERENCE:**
```
[State: CROSS-REFERENCE] — Validate REQUIREMENTS.md against KB and codebase; create Q&A for gaps.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q&A ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [✓ FEATURES ] → [● CROSS-REF ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Interview complete, approved, decomposed, and cross-referenced.
aid-interview  ▸ you are here
  [✓ FIRST-RUN ] → [✓ Q&A ] → [✓ CONTINUE ] → [✓ COMPLETION ] → [✓ FEATURES ] → [✓ CROSS-REF ] → [● DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FIRST-RUN | `references/state-first-run.md` | `interviewer` | → CONTINUE |
| Q-AND-A | `references/state-q-and-a.md` | `interviewer` | → CONTINUE |
| CONTINUE | `references/state-continue.md` | `interviewer` | → COMPLETION |
| COMPLETION | `references/state-completion.md` | `interviewer` | → FEATURE-DECOMPOSITION |
| FEATURE-DECOMPOSITION | `references/state-feature-decomposition.md` | `architect` | → CROSS-REFERENCE |
| CROSS-REFERENCE | `references/state-cross-reference.md` | `reviewer` | → DONE |
| DONE | `references/state-done.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-interview again` and exit.

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
