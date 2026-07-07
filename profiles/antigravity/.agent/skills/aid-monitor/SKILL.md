---
name: aid-monitor
description: >
  Observe production, classify findings, and route actions. Combines telemetry
  interpretation with triage — detect anomalies, perform root cause analysis
  for bugs, and route findings to aid-describe (bugs via its lite bug-fix
  triage; change requests as new/changed requirements).
  Per-work scope. Use post-deployment, on schedule, or on-demand.
  State machine: OBSERVE → CLASSIFY → ROUTE → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Observe, Classify, Act

Monitor production. Detect what's wrong. Route it to where it gets fixed.

## Agents Involved

- **Default executor:** `aid-orchestrator` (routes findings; never implements directly).
- **Telemetry interpretation:** `aid-researcher` (reads logs/metrics, classifies anomalies).
- **Routing targets:**
  - BUG classification → re-enters at `aid-describe` (lite bug-fix triage), which creates the task that `aid-developer` implements via `aid-execute`.
  - Change Request → re-enters at `aid-describe` as new/changed requirements (full lifecycle).
  - Infrastructure → escalated to ops (outside AID scope).

## Argument-Hint

```
/aid-monitor work-NNN
```

Required: work ID. If only one work exists, auto-select it.

Optional flags:
- `--since "YYYY-MM-DD"` — observation window start (default: last deploy or last monitor run)
- `--package package-NNN` — scope to a specific deployment package

## Workspace

```
.aid/{work}/
  packages/                    ← deployment history
  features/                    ← SPECs (expected behavior)
  tasks/                       ← task files (acceptance criteria)
  known-issues.md              ← known problems
```

<!-- NOTE: The Monitor area STATE is deferred until the area matures. When authored, MONITOR-STATE.md follows the area-STATE pattern documented at .agent/aid/templates/work-state-template.md (per-work) and .aid/knowledge/schemas.md §1A. -->

## ⚠️ Pre-flight Checks

1. Verify `.aid/` workspace exists.
2. Resolve work directory.
3. Read or create the in-memory monitor context (observation log, finding statuses):
   ```
   Last Run: {never}
   Window: {start} → {end}
   Findings: 0
   Active Findings: {none}
   Resolved Findings: {none}
   ```
4. Read `PLAN.md` — understand deliveries and what was shipped.
5. Read `packages/` — what's deployed and when.
6. Read `known-issues.md` — filter out already-known problems.

## State Detection

Determine the current entry state from context:
- No prior run context → **OBSERVE** state (pull telemetry; see `references/state-observe.md`)
- Active findings present → **CLASSIFY** state (classify and analyze; see `references/state-classify.md`)
- All findings classified → **ROUTE** state (propose and act; see `references/state-route.md`)
- All findings resolved → **DONE**

Print the state-entry line and "you are here" map:

**OBSERVE:**
```
[State: OBSERVE] — Pulling telemetry signals and correlating against baselines.
aid-monitor  ▸ you are here
  [● OBSERVE ] → [ CLASSIFY ] → [ ROUTE ] → [ DONE ]
```

**CLASSIFY:**
```
[State: CLASSIFY] — Classifying each anomaly as BUG, CHANGE REQUEST, INFRASTRUCTURE, or NO ACTION.
aid-monitor  ▸ you are here
  [✓ OBSERVE ] → [● CLASSIFY ] → [ ROUTE ] → [ DONE ]
```

**ROUTE:**
```
[State: ROUTE] — Proposing and executing routing actions per finding classification.
aid-monitor  ▸ you are here
  [✓ OBSERVE ] → [✓ CLASSIFY ] → [● ROUTE ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — All findings routed; monitor cycle complete.
aid-monitor  ▸ you are here
  [✓ OBSERVE ] → [✓ CLASSIFY ] → [✓ ROUTE ] → [● DONE ]
```

## Severity Thresholds

| Signal | Threshold | Classification |
|--------|-----------|----------------|
| New error type | Any | Finding |
| Error rate increase | >200% baseline | Finding |
| Performance degradation | >50% latency | Finding |
| Persistent test failure | Any new | Finding |
| Support ticket cluster | 3+ same issue | Finding |
| Below all thresholds | — | Clean report, no findings |

## Inputs

**From the project (what to observe):**
Any combination of: error tracking (Sentry, AppInsights, CloudWatch), CI/CD results,
APM/performance metrics, test trends, user feedback, support tickets, log files.

**From AID artifacts (what's expected):**
- Feature SPECs (`.aid/{work}/features/*/SPEC.md`) — expected behavior
- Task files (`.aid/{work}/tasks/task-*.md`) — acceptance criteria
- Package files — what was deployed and when
- `known-issues.md` — exclude known problems

**From KB (context):**
Read `.aid/knowledge/INDEX.md`, pull relevant docs (typically architecture, module-map,
infrastructure, test-landscape) for baseline context and root cause analysis.

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `.agent/aid/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** via
   `bash .agent/aid/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
   (resolves from `.aid/settings.yml`; default 1; `0` = disabled).
3. **Pre-create heartbeat file** (always — unconditional, per work-003 traceability):
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt with explicit instruction to update during long phases
   - SKIP only if `traceability.heartbeat_interval: 0` (user-explicit opt-out in `.aid/settings.yml`)
4. **Arm 3 L2 timers** (always — even for short ETAs use minimums 60s/120s/180s; never gate on ETA):
   - `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`

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

- `.agent/aid/templates/long-wait-protocol.md` — full L2 spec
- `.agent/aid/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `.agent/aid/templates/rough-time-hints.md` — current measured ETAs
- `.agent/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| OBSERVE | `references/state-observe.md` | `aid-researcher` | → CLASSIFY |
| CLASSIFY | `references/state-classify.md` | `aid-researcher` | → ROUTE |
| ROUTE | `references/state-route.md` | `aid-orchestrator` | → DONE |
| DONE | _(inline — see Re-run below)_ | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

## Re-run

When prior findings exist (from conversation context or referenced findings list):

```
[State: RE-RUN] — Prior findings on record; confirming whether to run fresh or review a finding.
aid-monitor  ▸ you are here
  [✓ OBSERVE ] → [✓ CLASSIFY ] → [✓ ROUTE ] → [✓ DONE ] → [● RE-RUN ]
```

1. Show active findings and their current status.
2. Show observation history (last runs).
3. Ask: **[1] New observation** (fresh run) or **[2] Review finding-N** (check if resolved)?
4. If [1] → re-enter the OBSERVE state with a new window (previous run end → now); router exits and user re-invokes `/aid-monitor`.
5. If [2] → Re-check evidence for that specific finding, update status.

## Quality Checklist

- [ ] All configured data sources checked
- [ ] Observation window clearly defined
- [ ] Each finding has concrete evidence (not speculation)
- [ ] Classification references feature SPECs
- [ ] Bug vs CR distinction explicit and justified
- [ ] For bugs: root cause identified (one sentence, specific)
- [ ] For bugs: patch scope defined (minimal — fix, don't refactor)
- [ ] For bugs: test requirements defined
- [ ] Severity with expected response time
- [ ] Routing decision clear for each finding
- [ ] Known issues filtered out (no duplicate findings)
- [ ] Correlations with deployments noted
- [ ] Monitor run summary printed with all findings and statuses
- [ ] KB docs consulted via INDEX.md (not hardcoded)
