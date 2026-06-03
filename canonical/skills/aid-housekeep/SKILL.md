---
name: aid-housekeep
description: >
  Optional on-demand housekeeping skill. Runs three gated jobs in strict order:
  KB-DELTA (re-discover changed docs since last KB approval) → SUMMARY-DELTA
  (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale
  work-area artifacts). Each stage commits its own changes on an aid/housekeep-*
  branch; the skill never pushes. Re-entrant: a stalled run resumes at the stalled
  stage on re-invocation. State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA →
  CLEANUP → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--grade X] minimum summary grade  [--cleanup-only] jump straight to CLEANUP (delivery-003+)"
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
[`canonical/templates/state-machine-chaining.md`](../../templates/state-machine-chaining.md).
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
| `--grade X` | Pass-through to the SUMMARY-DELTA delegation to `/aid-summarize`. Format: `[A-F][-+]?` (e.g., `A`, `A-`, `B+`). Without this, resolved via `bash canonical/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A`. |

> **`--cleanup-only` is NOT offered in delivery-001.** The CLEANUP body is a stub
> no-op until delivery-003 (task-008/task-009). Once the real CLEANUP body ships,
> `--cleanup-only` will jump straight to CLEANUP (AC10), setting `**Mode:**
> cleanup-only` and leaving KB/Summary stage rows as `—` (a deliberate
> cleanup-only run does not violate C1 — REQUIREMENTS.md FR7). Until then,
> passing `--cleanup-only` is an error: exit non-zero with:
> ```
> ⚠️  --cleanup-only is not yet available. It will be enabled in delivery-003.
>     Run /aid-housekeep without arguments to execute the full sequence.
> ```

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

1. **Look up ETA** in `canonical/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** via
   `bash canonical/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
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

- `canonical/templates/long-wait-protocol.md` — full L2 spec
- `canonical/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `canonical/templates/rough-time-hints.md` — current measured ETAs
- `canonical/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read actual files on disk.

Run `bash canonical/scripts/housekeep/housekeep-state.sh --state <STATE_FILE> --resume`
to resolve the resume target from the `## Housekeep Status` block. Locate `<STATE_FILE>`
as the work-area `STATE.md` for this work (`.aid/work-NNN-*/STATE.md`).

**Argument pre-check (before resume detection):**

1. If `--cleanup-only` was passed → exit non-zero with the "not yet available" message from `## Arguments`.
2. If `--grade X` was passed → validate format `[A-F][-+]?`; if invalid, exit non-zero with:
   ```
   ⚠️  --grade value must be a letter A–F with optional +/- suffix (e.g., A, A-, B+).
       Got: <value>
   ```
   If valid, store the grade value for pass-through to SUMMARY-DELTA.

**Resume detection (the six-row re-entry table):**

| # | Disk condition (read `## Housekeep Status`) | Resume target |
|---|---------------------------------------------|---------------|
| 1 | No `## Housekeep Status` section (fresh run), no `--cleanup-only` | PREFLIGHT → KB-DELTA |
| 2 | No section, `--cleanup-only` flag | PREFLIGHT → CLEANUP (Mode=cleanup-only) — *rejected in delivery-001* |
| 3 | `**KB Stage:**` is `stalled` / `running` / `—` | resume at **KB-DELTA** |
| 4 | `**KB Stage:**` passed/skipped AND `**Summary Stage:**` stalled/running/`—` | resume at **SUMMARY-DELTA** |
| 5 | KB + Summary passed/skipped AND `**Cleanup Stage:**` not passed | resume at **CLEANUP** |
| 6 | All three passed/skipped AND `**State:** DONE` | report "nothing to resume" (NFR2 idempotent no-op) |

If row 6 is reached, print:
```
✅ /aid-housekeep: nothing to resume — the last run completed successfully (DONE).
   To re-run housekeeping, clear ## Housekeep Status in the work-area STATE.md
   (or delete the section) and re-invoke /aid-housekeep.
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
| KB-DELTA | `references/state-kb-delta.md` | `architect` (feat-002 dispatches sub-agents via `/aid-discover`) | CHAIN → SUMMARY-DELTA / PAUSE-FOR-USER-ACTION if stalled |
| SUMMARY-DELTA | `references/state-summary-delta.md` | inline (delegates to `/aid-summarize`) | CHAIN → CLEANUP / PAUSE-FOR-USER-ACTION if stalled |
| CLEANUP | `references/state-cleanup.md` | inline | CHAIN → DONE |
| DONE | `references/state-done.md` | inline | HALT |

> **KB-DELTA sub-agent dispatch (feature-002).** The `architect` Worker for
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
> `canonical/templates/state-machine-chaining.md`. Mechanical and inline-question
> states auto-chain; only PAUSE-FOR-USER-ACTION / HALT stop the run.
