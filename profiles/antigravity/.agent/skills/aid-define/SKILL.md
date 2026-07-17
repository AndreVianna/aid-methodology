---
name: aid-define
description: >
  Feature decomposition and cross-reference validation from approved requirements.
  Begins from an approved REQUIREMENTS.md (produced by /aid-describe) and decomposes
  functional requirements into discrete feature folders with SPEC.md stubs
  (FEATURE-DECOMPOSITION), then validates the requirements and feature boundaries
  against the KB and codebase (CROSS-REFERENCE), then halts at DONE ready for
  /aid-specify.
  State machine: (Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT -> /aid-specify].
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[work-001] decompose approved requirements  [--features work-001] re-run feature decomposition"
---

# Feature Definition from Approved Requirements

## Agents Involved

aid-define is **multi-agent** — different states use different agents.

| State | Phase | Agent | Why |
|-------|-------|-------|-----|
| 5 FEATURE-DECOMPOSITION | Feature Decomposition | `aid-architect` | Design work — breaking requirements into structured features |
| 6 CROSS-REFERENCE | Cross-Reference & Refine | `aid-reviewer` | Adversarial validation against KB and codebase |
| 7 DONE | DONE | (no dispatch) | Terminal state, user choice prompt |

Decompose approved `REQUIREMENTS.md` into feature folders, then cross-reference the
result against the Knowledge Base and codebase. Produces per-feature `SPEC.md` stubs
ready for `/aid-specify`.

**Precondition:** `## Interview State: Approved` must be present in `.aid/works/{work}/STATE.md`.
If requirements are not yet approved, run `/aid-describe {work}` first to gather and
approve requirements.

**Workspace structure:**
```
.aid/
  knowledge/           <- shared KB (populated by /aid-discover)
  work-001-name/
    STATE.md           <- process (Interview State: Approved, Cross-Reference, Features State)
    REQUIREMENTS.md    <- approved requirements (produced by /aid-describe)
    features/          <- created by FEATURE-DECOMPOSITION
      feature-001-name/
        SPEC.md        <- requirements side (from Interview) + tech spec (added by /aid-specify)
```

**First run (after approval):** Decompose functional requirements into feature folders.
**After features created:** Cross-reference REQUIREMENTS.md against KB, grade, ask questions.
**After cross-reference:** DONE — ready for `/aid-specify`.
**Re-run decomposition:** pass `--features {work}` to re-run even if features exist.

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
| `work-NNN` | Work on the specified work item. |
| `--features work-NNN` | Re-run feature decomposition for this work even if features exist. |
| *(no argument)* | Select from existing approved works (see Task Routing). |

---

## Task Routing

When no work ID is provided:

### No approved works exist

If `.aid/` has no `work-*` directories with `Interview State: Approved`:

```
No approved works found. Run /aid-describe first to gather and approve requirements.
```

Exit.

### Approved works exist

If `.aid/` has one or more approved `work-*` directories:

```
Approved works ready for feature definition:
  work-001-user-auth   [3 features, cross-reference pending]
  work-002-reporting   [no features yet]

[1] Continue work-001-user-auth
[2] Continue work-002-reporting
```

Wait for response and proceed to State Detection for that work.

**Shortcut:** If only one approved work exists, go directly to it without asking.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

All paths below are relative to `.aid/works/{work}/`.

```plaintext
Precondition: Interview State: Approved in STATE.md -- HALT if not met (see below)
State 5:  **Path:** full, Interview State: Approved,
          no feature folders                                        -> FEATURE-DECOMPOSITION
State 6:  **Path:** full, Interview State: Approved, features exist,
          cross-reference not yet done                             -> CROSS-REFERENCE
State 7:  **Path:** full, Interview State: Approved, features +
          cross-ref already complete                               -> DONE
```

**Detection logic:**

1. Read `STATE.md` `## Interview State` `**Interview State:**` field.
2. If field is absent or value is NOT `Approved`:
   - Print: `[aid-define] Requirements for {work} are not yet approved. Run /aid-describe {work} first to gather and approve requirements.`
   - HALT
3. If State is `Approved`:
   - If `--features` flag provided → **State 5: FEATURE-DECOMPOSITION**
   - Check if `features/` directory exists and contains `feature-*` subdirectories
   - If no feature folders → **State 5: FEATURE-DECOMPOSITION**
   - If feature folders exist:
     - Check STATE.md `## Interview State` `## Cross-Reference` sub-section for `**State:** Complete`
       (or check if cross-reference entries exist from a prior run)
     - If cross-reference not yet done → **State 6: CROSS-REFERENCE**
     - If cross-reference already complete → **State 7: DONE**

Print the state-entry line and "you are here" map. Examples for each state:

**FEATURE-DECOMPOSITION:**
```
[State: FEATURE-DECOMPOSITION] — Decompose approved requirements into discrete feature folders.
aid-define  ▸ you are here
  (from /aid-describe: COMPLETION -> approved REQUIREMENTS)
  [● FEATURE-DECOMPOSITION ] → [ CROSS-REFERENCE ] → [ DONE ] → [ /aid-specify ]
```

**CROSS-REFERENCE:**
```
[State: CROSS-REFERENCE] — Validate REQUIREMENTS.md against KB and codebase; create Q&A for gaps.
aid-define  ▸ you are here
  [✓ FEATURE-DECOMPOSITION ] → [● CROSS-REFERENCE ] → [ DONE ] → [ /aid-specify ]
```

**DONE:**
```
[State: DONE] — Interview complete, approved, decomposed, and cross-referenced.
aid-define  ▸ you are here
  [✓ FEATURE-DECOMPOSITION ] → [✓ CROSS-REFERENCE ] → [● DONE ] → [ /aid-specify ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FEATURE-DECOMPOSITION | `references/state-feature-decomposition.md` | `aid-architect` | → CROSS-REFERENCE |
| CROSS-REFERENCE | `references/state-cross-reference.md` | `aid-reviewer` | → DONE |
| DONE | `references/state-done.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **HALT** → print the closing summary and exit.
