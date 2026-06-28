---
name: aid-housekeep
description: >
  Optional on-demand housekeeping skill. Runs three gated jobs in strict order:
  KB-DELTA (re-discover changed docs since last KB approval; brownfield docs take the
  doc<-code drift path, while source: forward-authored greenfield docs take the
  Conformance Lane -- a code->design shadow-extract that FLAGS design vs as-built
  divergence for human reconciliation and never auto-overwrites the design) → SUMMARY-DELTA
  (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale
  work-area artifacts). Each stage commits its own changes on an aid/housekeep-*
  branch; the skill never pushes. Re-entrant: a stalled run resumes at the stalled
  stage on re-invocation. State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA →
  CLEANUP → DONE. Source-driven global reconcile; for a targeted prompt-named delta
  use /aid-update-kb.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "[--cleanup-only] [--grade X] jump to cleanup stage, or set minimum summary grade"
---

# Knowledge Base Housekeeping

Runs the three standard housekeeping jobs in a safe, fixed order, on a dedicated
`aid/housekeep-*` branch, with one commit per stage. Re-running after a stalled
gate resumes at the stalled stage — not job 1.

**Prerequisite:** A `.aid/` directory must exist (init has run). Not Plan Mode
(stages write). A git repository must be present and clean enough to branch.

**Absent from the mandatory pipeline flow.** `/aid-housekeep` is an optional,
on-demand skill (REQUIREMENTS.md FR6). It is NOT inserted into the phase-to-skill
pipeline mapping and no phase gate references it.

**State machine — each `/aid-housekeep` invocation drives the state machine until
it hits a natural pause point per
[`.cursor/aid/templates/state-machine-chaining.md`](../../templates/state-machine-chaining.md).
Mechanical states auto-chain; only PAUSE-FOR-USER-ACTION and HALT stop the run.**

> ```
> aid-housekeep  ▸ one step per run
>   [ PREFLIGHT ] → [ KB-DELTA ] → [ SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]
> ```

---

## Arguments

| Argument | Effect |
|----------|--------|
| *(none)* | Full gated sequence: `KB-DELTA → SUMMARY-DELTA → CLEANUP` (FR7 default). |
| `--cleanup-only` | Jump straight to CLEANUP, skipping KB and summary (AC10). Sets `**Mode:** cleanup-only`. KB/Summary stage rows are left `—` (a deliberate cleanup-only run does not violate C1 — REQUIREMENTS.md FR7). `--grade X` is ignored under `--cleanup-only` (SUMMARY-DELTA is bypassed). |
| `--grade X` | Pass-through to the SUMMARY-DELTA delegation to `/aid-summarize`. Format: `[A-F][-+]?` (e.g., `A`, `A-`, `B+`). Without this, resolved via `bash .cursor/aid/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A`. Ignored when `--cleanup-only` is also given. |

> **`--fetch` / offline:** The online-first / permissioned-offline gate
> (REQUIREMENTS.md C2, AC3) is feature-002's concern. The skeleton does not parse
> a `--fetch` flag; it simply routes into KB-DELTA, whose body (feature-002)
> performs `git fetch origin` and the offline-permission prompt.

---

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `.cursor/aid/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** via
   `bash .cursor/aid/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
   (resolves from `.aid/settings.yml`; default 1; `0` = disabled).
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

- `.cursor/aid/templates/long-wait-protocol.md` — full L2 spec
- `.cursor/aid/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `.cursor/aid/templates/rough-time-hints.md` — current measured ETAs
- `.cursor/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read actual files on disk.

Resolve `<STATE_FILE>` to the **project-level housekeep run-state file** under
`.aid/.temp/` — `/aid-housekeep` is project maintenance, so its run-state does NOT
live in any work-area `STATE.md`. The file is transient (gitignored, never
committed/pushed) and is named `HOUSEKEEP_STATE_<YYYYMMDDHHMM>.md`; the DONE state
removes it (and any stale siblings) at the end of a run.

```bash
mkdir -p .aid/.temp
# Reuse the most recent in-progress run-state file; otherwise start a fresh one.
STATE_FILE=$(ls -1 .aid/.temp/HOUSEKEEP_STATE_*.md 2>/dev/null | sort | tail -1)
if [ -n "$STATE_FILE" ] && \
   [ "$(bash .cursor/aid/scripts/housekeep/housekeep-state.sh --state "$STATE_FILE" --read --field State)" = "DONE" ]; then
    STATE_FILE=""   # a leftover DONE file is stale (DONE-cleanup missed it) — start fresh
fi
[ -z "$STATE_FILE" ] && STATE_FILE=".aid/.temp/HOUSEKEEP_STATE_$(date +%Y%m%d%H%M).md"
```

Then resolve the resume target from the `## Housekeep Status` block:

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh --state "$STATE_FILE" --resume
```

(On a fresh run `$STATE_FILE` does not exist yet; `housekeep-state.sh` creates it on
the first `--write`, and `--resume`/`--read` treat an absent file as "no section".)

**Argument pre-check (before resume detection):**

1. If `--cleanup-only` was passed → set `**Mode:** cleanup-only` via
   `bash .cursor/aid/scripts/housekeep/housekeep-state.sh --state <STATE_FILE> --write --field "Mode" --value "cleanup-only"`.
   Route PREFLIGHT → CLEANUP directly (row 2 of the resume table). Any `--grade X` value is
   noted but ignored (SUMMARY-DELTA is bypassed in cleanup-only mode).
2. If `--grade X` was passed (without `--cleanup-only`) → validate format `[A-F][-+]?`; if
   invalid, exit non-zero with:
   ```
   ⚠️  --grade value must be a letter A–F with optional +/- suffix (e.g., A, A-, B+).
       Got: <value>
   ```
   If valid, store the grade value for pass-through to SUMMARY-DELTA.
3. Any other unrecognized flag → exit non-zero with:
   ```
   ⚠️  Unknown argument: <flag>
       Usage: /aid-housekeep [--cleanup-only] [--grade X]
   ```

**Resume detection (the six-row re-entry table):**

| # | Disk condition (read `## Housekeep Status`) | Resume target |
|---|---------------------------------------------|---------------|
| 1 | No `## Housekeep Status` section (fresh run), no `--cleanup-only` | PREFLIGHT → KB-DELTA |
| 2 | No section, `--cleanup-only` flag | PREFLIGHT → CLEANUP (Mode=cleanup-only) |
| 3 | `**KB Stage:**` is `stalled` / `running` / `—` | resume at **KB-DELTA** |
| 4 | `**KB Stage:**` passed/skipped AND `**Summary Stage:**` stalled/running/`—` | resume at **SUMMARY-DELTA** |
| 5 | KB + Summary passed/skipped AND `**Cleanup Stage:**` not passed | resume at **CLEANUP** |
| 6 | All three passed/skipped AND `**State:** DONE` | report "nothing to resume" (NFR2 idempotent no-op) |

If row 6 is reached, print:
```
✅ /aid-housekeep: nothing to resume — the last run completed successfully (DONE).
   The run-state file under .aid/.temp/HOUSEKEEP_STATE_*.md is cleaned at DONE, so a
   fresh /aid-housekeep simply starts a new run. (Row 6 is reached only if a stale
   DONE file lingered; deleting .aid/.temp/HOUSEKEEP_STATE_*.md also resets it.)
```
Then HALT.

**State-entry banner.** At the start of each state, print the matching banner:

**PREFLIGHT:**
```
[State: PREFLIGHT] — Verifying prerequisites: .aid/ exists, not Plan Mode, git repo present.
aid-housekeep  ▸ you are here
  [● PREFLIGHT ] → [ KB-DELTA ] → [ SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]
```

**KB-DELTA:**
```
[State: KB-DELTA] — Detecting KB delta since last approval; dispatching targeted re-discovery.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [● KB-DELTA ] → [ SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]
```

**SUMMARY-DELTA:**
```
[State: SUMMARY-DELTA] — Checking whether the visual summary needs regeneration.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [✓ KB-DELTA ] → [● SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]
```

**CLEANUP:**
```
[State: CLEANUP] — Sweeping stale work-area artifacts.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [✓ KB-DELTA ] → [✓ SUMMARY-DELTA ] → [● CLEANUP ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Housekeeping complete.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [✓ KB-DELTA ] → [✓ SUMMARY-DELTA ] → [✓ CLEANUP ] → [● DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| PREFLIGHT | `references/state-preflight.md` | inline | CHAIN → KB-DELTA (or CLEANUP if Mode=cleanup-only) |
| KB-DELTA | `references/state-kb-delta.md` | `aid-architect` (feat-002 dispatches sub-agents via `/aid-discover`) | CHAIN → SUMMARY-DELTA / PAUSE-FOR-USER-ACTION if stalled |
| SUMMARY-DELTA | `references/state-summary-delta.md` | inline (delegates to `/aid-summarize`) | CHAIN → CLEANUP / PAUSE-FOR-USER-ACTION if stalled |
| CLEANUP | `references/state-cleanup.md` | inline | CHAIN → DONE |
| DONE | `references/state-done.md` | inline | HALT |

> **KB-DELTA sub-agent dispatch (feature-002).** The `aid-architect` Worker for
> KB-DELTA detects delta since the last KB approval, scopes/confirms the affected
> documents, and dispatches targeted re-discovery via `/aid-discover`. The
> `## Dispatch Protocol (L1+L2+L3)` block above applies to all sub-agent dispatches
> within KB-DELTA. The full dispatch protocol is documented inside
> `references/state-kb-delta.md` (authored by task-004 / feature-002).

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

> **State-machine chaining:** Each `/aid-housekeep` invocation drives the state
> machine until it hits a natural pause point per
> `.cursor/aid/templates/state-machine-chaining.md`. Mechanical and inline-question
> states auto-chain; only PAUSE-FOR-USER-ACTION / HALT stop the run.
