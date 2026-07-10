---
name: aid-update-kb
description: >
  Optional on-demand targeted KB update skill. Takes a free-form prompt
  describing what changed and applies the delta through the same
  review/calibration gate as aid-discover. Analyzes which KB docs the
  prompt implies, applies targeted summary+pointer edits, reviews them
  through f005's five-mandate panel (scoped to the changed docs), and
  commits only after explicit human approval. State-machine:
  ANALYZE -> APPLY -> REVIEW -> APPROVAL -> DONE (FIX loop inside REVIEW).
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<what changed / what to update in the KB>"
---

# Targeted KB Update

Applies a prompt-driven, targeted delta to the Knowledge Base through the
same review/calibration gate as `/aid-discover`. One pass per run --
each invocation drives the state machine to the next natural pause point.

**Optional, off-pipeline.** `/aid-update-kb` is NOT in the numbered
phase-to-skill pipeline; no phase gate references it. It is an on-demand
maintenance skill (like `/aid-housekeep` / `/aid-query-kb`).

**Run-state is transient.** Its run-state lives in a project-level file
under `.aid/.temp/` (`.aid/.temp/UPDATEKB_STATE_<ts>.md`, gitignored per
`.gitignore`, removed at DONE). It does NOT write to any work `STATE.md`
for its own run-state. The KB it edits has its own `.aid/knowledge/STATE.md`
for review/approval history.

**Boundary: prompt-driven-targeted vs source-driven-global.** This skill
is the prompt-driven-targeted half of the KB freshness loop -- the user
supplies the scoping seed (what changed) and ANALYZE turns it into a
(doc, change) plan. The source-driven-global sweep is `aid-housekeep`'s
KB-DELTA job. The non-overlap contract between the two (FR-33/FR-34) is
drawn in f010; this skill references that boundary but does not own it.

**Human-gated (NFR-6/C4/AC13).** Detection and grading are automatic; the
change to KB content cannot proceed to DONE without an explicit human
`[1] Approved` at APPROVAL. No auto-apply path exists.

**State machine -- each `/aid-update-kb` invocation drives the state machine
until it hits a natural pause point per
`canonical/aid/templates/state-machine-chaining.md`.
Mechanical states auto-chain; only PAUSE-FOR-USER-ACTION and HALT stop the
run.**

> ```
> aid-update-kb  > one step per run
>   [ ANALYZE ] -> [ APPLY ] -> [ REVIEW ] -> [ APPROVAL ] -> [ DONE ]
>                                 ^     |
>                                 +-FIX-+   (REVIEW->FIX->REVIEW until grade>=min AND teach-back PASS)
> ```

---

## Pre-flight

Confirm a prompt was supplied. If `/aid-update-kb` is invoked with no
argument, print:

```
Usage: /aid-update-kb "<what changed / what to update in the KB>"
Example: /aid-update-kb "work-003 added the content-isolation cornerstone (AID:BEGIN/END boundary)"
```

Then exit without entering the state machine.

---

## Dispatch Protocol (L1+L2+L3 subagent visibility)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10-25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `canonical/aid/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW-HIGH band.
2. **Read heartbeat config** via
   `bash canonical/aid/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
   (resolves from `.aid/settings.yml`; default 1; `0` = disabled).
3. **Pre-create heartbeat file** (always -- unconditional, per work-003 traceability):
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
   - SKIP only if `traceability.heartbeat_interval: 0` (user-explicit opt-out)
4. **Arm 3 L2 timers as SEPARATE background dispatches** (always -- even for short
   ETAs use minimums 60s/120s/180s; never gate on ETA). Each timer is its OWN
   `Bash(..., run_in_background=true)` call.

**References:**

- `canonical/aid/templates/long-wait-protocol.md` -- full L2 spec
- `canonical/aid/templates/subagent-heartbeat-protocol.md` -- full L3 spec
- `canonical/aid/templates/rough-time-hints.md` -- current measured ETAs

---

## State Detection

**FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read actual files on disk.

Resolve `<STATE_FILE>` to the project-level update-kb run-state file under
`.aid/.temp/`. The file is transient (gitignored, never committed/pushed) and
is named `UPDATEKB_STATE_<YYYYMMDDHHMM>.md`; the DONE state removes it (and
any stale siblings) at the end of a run.

```bash
mkdir -p .aid/.temp
STATE_FILE=$(ls -1 .aid/.temp/UPDATEKB_STATE_*.md 2>/dev/null | sort | tail -1)
if [ -n "$STATE_FILE" ] && \
   grep -q "^\*\*State:\*\* DONE" "$STATE_FILE" 2>/dev/null; then
    STATE_FILE=""   # a leftover DONE file is stale -- start fresh
fi
[ -z "$STATE_FILE" ] && \
    STATE_FILE=".aid/.temp/UPDATEKB_STATE_$(date +%Y%m%d%H%M).md"
```

**Resume detection:**

| # | Disk condition (read run-state file) | Resume target |
|---|--------------------------------------|---------------|
| 1 | No run-state file (fresh run) | ANALYZE |
| 2 | `**State:** ANALYZE` present | ANALYZE |
| 3 | `**State:** APPLY` present | APPLY |
| 4 | `**State:** REVIEW` or `**State:** FIX` present | REVIEW |
| 5 | `**State:** APPROVAL` present | APPROVAL |
| 6 | `**State:** DONE` present | report "nothing to resume" -- HALT |

If row 6 is reached, print:

```
/aid-update-kb: nothing to resume -- the last run completed (DONE) and the
run-state file was removed. To start a new update, run:
  /aid-update-kb "<what changed / what to update in the KB>"
```

Then HALT.

**State-entry banners.** At the start of each state, print the matching banner:

**ANALYZE:**
```
[State: ANALYZE] -- Mapping prompt to KB docs and building a (doc, change) plan.
aid-update-kb  > you are here
  [* ANALYZE ] -> [ APPLY ] -> [ REVIEW ] -> [ APPROVAL ] -> [ DONE ]
```

**APPLY:**
```
[State: APPLY] -- Applying targeted summary+pointer edits to the KB docs.
aid-update-kb  > you are here
  [+ ANALYZE ] -> [* APPLY ] -> [ REVIEW ] -> [ APPROVAL ] -> [ DONE ]
```

**REVIEW:**
```
[State: REVIEW] -- Grading the changed KB docs through f005's five-mandate panel.
aid-update-kb  > you are here
  [+ ANALYZE ] -> [+ APPLY ] -> [* REVIEW ] -> [ APPROVAL ] -> [ DONE ]
```

**APPROVAL:**
```
[State: APPROVAL] -- Human gate: confirm the approved changes before committing.
aid-update-kb  > you are here
  [+ ANALYZE ] -> [+ APPLY ] -> [+ REVIEW ] -> [* APPROVAL ] -> [ DONE ]
```

**DONE:**
```
[State: DONE] -- Restamp approved_at_commit:, commit, and clean run-state.
aid-update-kb  > you are here
  [+ ANALYZE ] -> [+ APPLY ] -> [+ REVIEW ] -> [+ APPROVAL ] -> [* DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| ANALYZE | `references/state-analyze.md` | inline (Read/Glob/Grep + `kb-freshness-check.sh`) | CHAIN -> APPLY (or PAUSE-FOR-USER-ACTION if the prompt is un-groundable -- Q&A escalation to `.aid/knowledge/STATE.md`) |
| APPLY | `references/state-apply.md` | inline (Edit) or `aid-architect`/`aid-researcher` for the owning doc-set | CHAIN -> REVIEW |
| REVIEW | `references/state-review.md` (REUSES f005's panel scoped to the changed docs) | `aid-reviewer` panel (f005) | CHAIN -> FIX if below gate; CHAIN -> APPROVAL if grade>=min AND teach-back PASS |
| APPROVAL | `references/state-approval.md` | inline | PAUSE-FOR-USER-ACTION (human gate) -> DONE on approval |
| DONE | `references/state-done.md` | inline | HALT (restamp `approved_at_commit:`, commit on `aid/update-kb-*` branch, clean run-state) |

> **FIX loop.** Below-gate REVIEW findings route to the FIX cycle (REVIEW ->
> fix edits -> REVIEW) until `grade >= minimum_grade AND teach-back PASS`.
> The minimum grade resolves via:
> `bash canonical/aid/scripts/config/read-setting.sh --skill update-kb --key minimum_grade --default A`

> **REVIEW reuse (f005).** The REVIEW state does not redefine the review gate
> -- it invokes f005's five-mandate panel (`aid-reviewer` Correctness,
> Anatomy/Coverage, Concept-closure, Teach-back, Calibration) with
> `{{ARTIFACTS}}` scoped to the changed-doc set (the (doc, change) list from
> APPLY) and `<scope>` = `update-kb`. The merged ledger is written to
> `.aid/.temp/review-pending/update-kb.md`. Grade and teach-back are evaluated
> via the unchanged `grade.sh`.

> **DONE (commit convention).** Work happens on an `aid/update-kb-*` branch
> (the `aid-housekeep` branch-per-run precedent). The skill never pushes;
> the human pushes / opens the PR. `approved_at_commit:` is restamped in DONE
> (after the human gate), never in APPLY -- so a doc that is edited-but-not-yet-
> approved is correctly suspect to f007, never falsely current.

On state entry, print `[State: NAME]` + the "you are here" banner from State
Detection above. When a state completes, route by its `**Advance:**` type per
`canonical/aid/templates/state-machine-chaining.md`:

- **CHAIN** -> begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** -> print the pause reason + resume command and exit.
- **HALT** -> print the closing summary and exit.

> **State-machine chaining:** Each `/aid-update-kb` invocation drives the state
> machine until it hits a natural pause point per
> `canonical/aid/templates/state-machine-chaining.md`. Mechanical states
> auto-chain; only PAUSE-FOR-USER-ACTION and HALT stop the run.
