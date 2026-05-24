---
name: aid-monitor
description: >
  Observe production, classify findings, and route actions. Combines telemetry
  interpretation with triage — detect anomalies, perform root cause analysis
  for bugs, and route to aid-execute (bugs) or aid-discover (change requests).
  Per-work scope. Use post-deployment, on schedule, or on-demand.
allowed-tools: Read, Glob, Grep, Terminal, Write
---

# Observe, Classify, Act

Monitor production. Detect what's wrong. Route it to where it gets fixed.

## Agents Involved

- **Default executor:** `orchestrator` (routes findings; never implements directly).
- **Telemetry interpretation:** `researcher` (reads logs/metrics, classifies anomalies).
- **Routing targets:**
  - BUG classification → re-enters at `aid-execute` with a new task for `developer`.
  - Change Request → re-enters at `aid-discover` (full lifecycle).
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

<!-- NOTE (FR2 area-STATE rule, work-003-traceability/feature-002 OQ-3 resolution): The Monitor area STATE is deferred until the area matures. When authored, MONITOR-STATE.md follows the area-STATE pattern documented at canonical/templates/work-state-template.md (per-work) and .aid/knowledge/data-model.md §1A. -->

## Pre-flight

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
- No prior run context → **OBSERVE** (Step 1)
- Active findings present → **CLASSIFY/ROUTE** (Step 2–4)
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

## Process

#
---

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `canonical/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** from `.aid/knowledge/STATE.md` top-of-file
   `**Heartbeat Interval:** N minutes` (default 1; `0` = disabled).
3. **If ETA LOW > 5 min AND heartbeat enabled:**
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
4. **Arm 3 L2 timers** (via `run_in_background: true`):
   - `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time. Log to
  `STATE.md ## Calibration Log` for L1 calibration. Delete heartbeat file.
- **Failure:** emit `✗ <agent> FAILED after <elapsed> (reason: <one-line>)`.
  Decide whether to re-dispatch, fall back, or surface to user. Delete
  heartbeat file.

**References:**

- `canonical/templates/long-wait-protocol.md` — full L2 spec
- `canonical/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `canonical/templates/rough-time-hints.md` — current measured ETAs
- `canonical/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

## Step 1: Observe

Pull data from configured sources. Scope the observation window:
- **Post-deploy:** last deploy → now
- **Scheduled:** last monitor run → now
- **On-demand:** user-specified window

▶ telemetry pull starting (~30 s–2 min per source per `canonical/templates/rough-time-hints.md`)
For each data source, capture:
- Raw signals (errors, latency spikes, failures, ticket clusters)
- Metadata (timestamps, affected users/endpoints, frequency)
- Trends vs. baseline (is this new? worsening? stable?)
✓ telemetry pull done (record actual time, sources hit, signals collected) — or ✗ telemetry pull failed: {source, reason}

▶ anomaly detection starting (~10–30 s)
**Anomaly detection — compare to baseline:**
- Error rate changes (new error types, rate spikes)
- Performance degradation (latency, throughput)
- Test instability (new flaky tests, persistent failures)
- Behavioral anomalies (unexpected patterns in usage or data)

**Correlation — connect signals:**
- "Error spike started 23 min after deploy of package-002"
- "Performance drop coincides with new region traffic"
- Correlation narrows investigation scope — don't just list, connect.

Use KB to filter: known conditions, expected variation, already-documented issues.
✓ anomaly detection done (record actual time, N findings above threshold) — or ✗ anomaly detection failed: {reason}

### Step 2: Classify

For each finding above threshold:

```
Does code do what the feature SPEC says?
├── NO → BUG (spec right, code wrong)
├── YES, spec doesn't cover this case →
│     Obvious fix? → BUG (spec gap)
│     Needs requirements input? → CHANGE REQUEST
├── YES, spec is now wrong → CHANGE REQUEST
├── NOT CODE → INFRASTRUCTURE
└── FALSE POSITIVE → NO ACTION
```

Assess severity per finding:
- **Critical:** Data loss, security breach, total outage → Immediate
- **High:** Core functionality broken → Same day
- **Medium:** Non-critical affected, workaround exists → This week
- **Low:** Minor, limited impact → Next cycle

### Step 3: Analyze (BUGs only)

▶ root cause analysis starting (~2–5 min per BUG per `canonical/templates/rough-time-hints.md`)
Root cause analysis before routing:

1. **Reproduce the path.** Trace from evidence: endpoint → module → function.
2. **Identify the fault.** What specific code is wrong?
3. **Understand why.** Spec ambiguous? Edge case? KB assumption wrong?
4. **Assess blast radius.** Check module consumers via INDEX.md → module-map.
5. **Define patch scope.** Exactly which files change. Minimal surface — fix the bug, don't refactor.
6. **Test requirements.** Fix verification + regression + coverage gap.

Root cause = one sentence:
"The `PaymentService.Process()` method doesn't validate null `currency` field,
which spec says must default to USD."
✓ root cause analysis done (record actual time, root cause, patch scope) — or ✗ root cause analysis blocked: {reason — usually KB gap or unreproducible}

### Step 4: Propose Actions

Present findings to the user with proposed routing:

```
📊 Monitor Report — work-001 (since 2026-03-20)

Finding 1: [CRITICAL] [BUG] Null currency causes 500 error
  Evidence: 342 errors in 48h, payment module, started after package-002
  Root cause: PaymentService.Process() missing null validation
  Patch scope: PaymentService.cs + PaymentServiceTests.cs
  → Proposed: Create task in delivery-hotfix → aid-execute

Finding 2: [MEDIUM] [CHANGE REQUEST] Reports need local timezone
  Evidence: 12 support tickets requesting midnight-local instead of midnight-UTC
  → Proposed: Route to aid-discover → new work cycle

Finding 3: [LOW] [NO ACTION] Intermittent 504 on health endpoint
  Evidence: 3 occurrences in 7 days, all self-resolved < 30s
  → Proposed: Document, no action

[1] Approve all routes
[2] Adjust — change routing for specific findings
```

### Step 5: Act

For each approved finding:

**BUG → aid-execute (short path):**
- Create a new task file in `.aid/{work}/tasks/` with type IMPLEMENT
- Include: root cause, patch scope, test requirements, severity
- The task goes through the normal execute cycle (code → review → done)

**CHANGE REQUEST → aid-discover:**
- Write a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` describing the gap
- Optionally create a new work if scope is large enough

**INFRASTRUCTURE → escalate:**
- Document in the monitor run summary with recommended ops action
- Not in AID's scope — human handles this

**NO ACTION → close:**
- Document justification in the monitor run summary → Resolved Findings list

**Update known-issues.md** if findings reveal new known issues affecting other features.

### Step 6: Update State

Print monitor run summary: date, window, finding count, routing summary.

▶ PM tool ticket creation starting (~10–30 s per ticket per `canonical/templates/rough-time-hints.md`; skip block entirely if no PM tool)
If PM tool configured (infrastructure.md § Project Management):
- Create tickets for BUG tasks
- Link to existing Sprint/Epic
✓ PM tool ticket creation done (record actual time, N tickets created) — or ✗ PM tool ticket creation failed: {reason — usually auth/network}

## Severity Thresholds

| Signal | Threshold | Classification |
|--------|-----------|----------------|
| New error type | Any | Finding |
| Error rate increase | >200% baseline | Finding |
| Performance degradation | >50% latency | Finding |
| Persistent test failure | Any new | Finding |
| Support ticket cluster | 3+ same issue | Finding |
| Below all thresholds | — | Clean report, no findings |

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
4. If [1] → Step 1 with new window (previous run end → now).
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
