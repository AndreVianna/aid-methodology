---
name: aid-discover
description: >
  Brownfield project discovery with built-in quality gate. Run `/aid-config` first to scaffold
  the KB. Analyzes all repository content (code, configuration, and documentation) to populate
  KB documents. Reviews, collects user input, fixes issues, and gets user approval — one step
  per run. State-machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "[--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart"
---

# Brownfield Project Discovery

Analyze an existing project repository — all code, configuration, and documentation — and
produce a structured `.aid/knowledge/` directory by orchestrating 5 specialized discovery subagents.
Includes a built-in quality gate that reviews, grades, and fixes KB documents.

**State machine — each `/aid-discover` run does ONE step and exits.**

## ⚠️ Pre-flight Checks

Run `bash .cursor/scripts/kb/preflight.sh .aid/knowledge/` to verify:
1. `.aid/knowledge/STATE.md` exists (init has run)
2. Not in Plan Mode (subagents need write access)

If Check 1 fails: `⚠️ Knowledge Base not initialized. Run /aid-config first to set up the project.` — Exit.
If Check 2 fails: Tell user to press `Shift+Tab` to exit Plan Mode, then re-run.

---

## ⚠️ Pre-flight Cleanup (orchestrator-only — never grade these)

**Before dispatching the REVIEW reviewer, sweep the KB for mechanical drift that should never appear as a "finding".** These are housekeeping items the orchestrator owns; they pollute reviewer attention and burn cycles if left for the reviewer to surface.

**Sweep categories (auto-correct silently):**

- **Line-count drift** — `wc -l` every cited file (SKILL.md, AGENT.md, scripts, templates, methodology) and replace stale citations with disk truth.
- **Off-by-1 drift** — small numerical changes in file sizes / counts that the prior cycle missed.
- **Aggregate counts** — per-skill or per-tree file/script/reference totals computed from current disk state (`find ... | wc -l`).
- **Path & citation hygiene** — bare citations missing skill prefix (`SKILL.md:NNN` → `.cursor/skills/<skill>/SKILL.md:NNN`); out-of-range line cites (line numbers that no longer exist after a file shrunk); broken `path:line` references.
- **Math** — verify any `%` calculations using real values (e.g., "X% over Y" assertions). If the underlying numbers changed, recompute.
- **Ghost references** — once confirmed a file/feature was removed, delete references to it (don't leave "(retired)" or "(see below)" stubs in current-state docs; historical change-log entries are fine).
- **Meta-doc counting** — `INDEX.md` / `README.md` per-doc line counts, feature counts, file-type tallies (same nature as line-count drift).

**Out of KB scope — never check, never claim:**

- **`.claude/` at the repo root** — this is the **dogfood install** (AID applied to AID itself), conceptually identical to any user's `.claude/` after running `setup.sh`. The KB makes **no claims** about it. Byte-identity comparisons are scoped to **4-tree** (canonical + 3 profile trees), NOT 5-tree.

**Why pre-flight cleanup matters:**
- Reviewer focus should be **semantic** quality (missing post-merge content, internal contradictions, factually wrong claims that mislead downstream phases) — not arithmetic drift.
- Sweeping these first lets the reviewer score the KB on what actually matters.
- Edits in this sweep should be **manual one-by-one** (not regex scripts). Scripts generalize and produce new defects (replacing historical-narrative values, mangling section headers via context-bleed, embedding authoring annotations as user-facing prose, missing inline variants the anchor didn't anticipate). Each edit should see its full surrounding context.

> **State machine for this skill:**
> ```
> aid-discover  ▸ one step per run
>   [ GENERATE ] → [ REVIEW ] → [ Q-AND-A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
> ```
> Each run detects which state to enter from disk and does exactly that step.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Set minimum acceptable grade. Format: `[A-F][-+]?` (e.g., A, A-, B+). Default: `A`. Persists in `.aid/knowledge/STATE.md`. |
| `--reset` | Clear entire `.aid/knowledge/` directory and restart from scratch. |

**Grade persistence:** Saved to `.aid/knowledge/STATE.md` on first run. `--grade` updates it; omitting it reads the stored value.

---

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `.cursor/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** from `.aid/knowledge/STATE.md` top-of-file
   `bash .cursor/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1` (default 1; `0` = disabled).
3. **Pre-create heartbeat file** (always — unconditional, per work-003 traceability):
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt with explicit instruction to update during long phases
   - SKIP only if `traceability.heartbeat_interval: 0` (user-explicit opt-out in `.aid/settings.yml`)
4. **Arm 3 L2 timers as SEPARATE background dispatches** (always — even for short ETAs use minimums 60s/120s/180s; never gate on ETA). Each timer is its OWN `Bash(..., run_in_background=true)` call:
   - Call A: `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"` — own background dispatch
   - Call B: `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"` — own background dispatch
   - Call C: `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"` — own background dispatch
   - ⚠️ **DO NOT chain timers with `&` inside a single wrapper Bash call.** If you do, the wrapper exits when the last `&` is queued, orphaning the sleeps — their stdout is silently lost and you'll never see the timer fire. Each timer needs its own `run_in_background: true` task so the harness can track and notify on completion.

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time. Append a row to
  the work `STATE.md ## Calibration Log` section (create section if missing) with
  format `| YYYY-MM-DD | <agent> | <task-id/cycle> | <ETA-band> | <actual> | <notes> |`.
  Also update the task's `## Dispatches` sub-column with the dispatch record.
  Both are mandatory per work-003 traceability (never optional, never "if tracked").
  Delete heartbeat file.
- **Failure:** emit `✗ <agent> FAILED after <elapsed> (reason: <one-line>)`.
  Decide whether to re-dispatch, fall back, or surface to user. Delete
  heartbeat file.

**References:**

- `.cursor/templates/long-wait-protocol.md` — full L2 spec
- `.cursor/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `.cursor/templates/rough-time-hints.md` — current measured ETAs
- `.cursor/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read actual files on disk.

Read the filesystem to determine which mode to enter:

```
State 1: Missing or empty KB docs                     → GENERATE mode
State 2: All docs populated, no GRADE file             → REVIEW mode
State 3: GRADE file, (grade < min AND has Pending Q&A)
         OR has Pending Q&A with Impact: Required       → Q-AND-A mode
State 4: GRADE file, grade < min, no Pending Q&A       → FIX mode
State 5: GRADE file, grade >= min, not user-approved    → APPROVAL mode
State 6: GRADE file, grade >= min, user-approved        → DONE
```

**Detection logic:**

1. Check `.aid/knowledge/` for the 16 expected documents:
   `project-structure.md`, `external-sources.md`, `architecture.md`, `technology-stack.md`,
   `module-map.md`, `coding-standards.md`, `data-model.md`, `api-contracts.md`,
   `integration-map.md`, `domain-glossary.md`, `test-landscape.md`, `security-model.md`,
   `tech-debt.md`, `infrastructure.md`, `ui-architecture.md`, `feature-inventory.md`
2. A document is "populated" only if it contains real content (files with only `❌ Pending` = missing). If any are missing → **GENERATE**
3. If all 16 populated and `.aid/knowledge/STATE.md` has `**Grade:** Pending` or `Not Started` → **REVIEW**
4. If all 16 populated but no `.aid/knowledge/STATE.md` → **REVIEW** (legacy)
5. If `.aid/knowledge/STATE.md` exists with a grade:
   - Read current/minimum grade; if `--grade` provided, update minimum
   - Read `## Q&A (Pending)` section of `.aid/knowledge/STATE.md` for `**Status:** Pending` entries
   - If any Pending with `**Impact:** Required` → **Q-AND-A** (regardless of grade)
   - If grade < minimum: Pending entries → **Q-AND-A**; no Pending → **FIX**
   - If grade >= minimum and no Required Pending Q&A:
     - `**User Approved:** yes` → **DONE**; otherwise → **APPROVAL**

**Grade ordering** (highest to lowest):
`A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F`

Print the state-entry line with description, then the "you are here" state-map. Use one of these depending on the detected state:

**GENERATE:**
```
[State: GENERATE] — Populate missing KB documents by orchestrating parallel discovery sub-agents.
aid-discover  ▸ you are here
  [● GENERATE ] → [ REVIEW ] → [ Q-AND-A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**REVIEW:**
```
[State: REVIEW] — Grade all KB documents for accuracy, completeness, and evidence quality.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [● REVIEW ] → [ Q-AND-A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**Q-AND-A:**
```
[State: Q-AND-A] — Resolve pending questions with the user before attempting automated fixes.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [● Q-AND-A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**FIX:**
```
[State: FIX] — Apply Q&A answers and reviewer feedback to bring KB documents up to minimum grade.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q-AND-A ] → [● FIX ] → [ APPROVAL ] → [ DONE ]
```

**APPROVAL:**
```
[State: APPROVAL] — KB meets minimum grade; ask the user to confirm it is ready for Interview.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q-AND-A ] → [✓ FIX ] → [● APPROVAL ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Discovery is complete and user-approved; KB is ready for Interview.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q-AND-A ] → [✓ FIX ] → [✓ APPROVAL ] → [● DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| GENERATE | `references/state-generate.md` | `architect` | → REVIEW |
| REVIEW | `references/state-review.md` | `architect` | → Q-AND-A |
| Q-AND-A | `references/state-q-and-a.md` | inline | → FIX |
| FIX | `references/state-fix.md` | `architect` | → APPROVAL |
| APPROVAL | `references/state-approval.md` | inline | → halt |
| DONE | `references/state-done.md` | inline | → halt |

> **Sub-agent fanout (GENERATE):** The `architect` Worker for GENERATE dispatches
> discovery sub-agents internally — `discovery-scout` (Step 1, sequential), then
> `discovery-architect`, `discovery-analyst`, `discovery-integrator`, and
> `discovery-quality` in parallel (Steps 2–5). The full fanout protocol is
> documented inside `references/state-generate.md`. The Dispatch Protocol above
> (L1+L2+L3 visibility) applies to all sub-agent dispatches.

> **REVIEW scope (semantic only).** The REVIEW reviewer's job is to grade
> **semantic quality** — missing post-merge content, internal contradictions,
> factual claims that would mislead a downstream phase (architecture,
> module-map, coding-standards weighted highest). **Mechanical drift is OUT
> of scope** — line counts, off-by-1, aggregate counts, bare-cite resolver
> edge cases, math arithmetic, ghost references, meta-doc counting are
> orchestrator-side **Pre-flight Cleanup** (above), swept BEFORE the
> reviewer is dispatched. The reviewer should never need to flag mechanical
> drift as a finding; if it does, the pre-flight sweep was incomplete.

> **FIX parallelism (parallel-agent dispatch when independent).** The
> `architect` Worker for FIX **partitions the reviewer's findings by KB
> file** and dispatches **one sub-agent per affected file** (typically
> `tech-writer` for KB docs, or `researcher` if depth is needed). All agents
> run in **parallel** — single message with multiple `Agent` tool calls.
> Each agent's prompt contains only that file's finding list and a clear
> manual-edits directive (no regex scripts — scripts generalize and produce
> new defects). Each agent commits-stages its file's changes only. After
> ALL agents return, the orchestrator runs a **sequential aggregate step**:
> `verify-claims.sh`, then a single `git commit` + `git push`. The
> serial constraint exists only at the commit/push boundary; the edits
> themselves are parallel-safe because each file has exactly one writer.

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-discover again` and exit.

---

## Targeted Discovery (Re-entry)

When a Q&A entry in `.aid/knowledge/STATE.md` or an IMPEDIMENT triggers re-discovery:

1. Read the Q&A entry in STATE.md `## Q&A (Pending)` or the IMPEDIMENT to understand what's missing
2. Identify which subagent owns the documents (see `scripts/kb/verify-claims.sh` comments for mapping)
3. Dispatch ONLY the relevant subagent
4. Regenerate README.md and INDEX.md
5. Update README.md revision history
6. Reset the `**Grade:**` field in STATE.md to `Pending` so next run re-reviews
7. Report completion

---

## Quality Checklist

- [ ] No overlap between KB documents
- [ ] Claims grounded in code evidence (file paths, line numbers)
- [ ] Inferred info marked with ⚠️
- [ ] `.aid/knowledge/STATE.md` Q&A captures everything needing human input
- [ ] external-sources.md documents all sources (or states none provided)
- [ ] README.md reflects completeness and revision history
- [ ] INDEX.md has 2-3 line summaries per document
- [ ] feature-inventory.md exists (template or populated)
- [ ] AGENTS.md placeholders filled with discovered data
- [ ] All issues have severity: [CRITICAL], [HIGH], or [MEDIUM]
- [ ] Minimum 10 spot-checks in `.aid/knowledge/STATE.md` `## Verification Spot-Checks`

---

## Grading Criteria

| Grade | Meaning |
|-------|---------|
| A+ | Exceptional — comprehensive, accurate, evidence-rich, immediately useful |
| A | Thorough — covers expected scope with solid evidence |
| B+ | Good — minor gaps or missing details that don't block work |
| B | Adequate — covers basics but lacks depth in important areas |
| B- | Shallow — lists things without explaining patterns or relationships |
| C+ | Significant gaps — missing important sections or inaccurate in places |
| C | Barely useful — agent would need to re-discover most information |
| D | Misleading — wrong information that could cause bad decisions |
| F | Missing or empty |

**Overall grade** = weighted average where architecture, module-map, and coding-standards
count double (referenced most by downstream phases).

---

## Document Expectations

Read `references/document-expectations.md` for the full expectations per document,
including "Must have" and "Red flags" for each of the 16 KB documents plus meta-documents.
