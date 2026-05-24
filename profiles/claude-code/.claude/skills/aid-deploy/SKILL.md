---
name: aid-deploy
description: >
  Package completed deliveries into a release. Selects eligible deliveries,
  verifies the combined build, packages according to project infrastructure,
  generates release notes, and updates artifact statuses. Use when deliveries
  are complete and ready to ship.
  State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Package & Ship

Package completed deliveries into a release.

## Agents Involved

- **Default executor:** `operator` (orchestrates the release: verifies build, packages artifacts, updates statuses).
- **Specialist consults (optional):** `tech-writer` for release notes / changelog, `devops` if CI/CD configuration changes are needed during release, `reviewer` for final pre-release verification.

## Argument-Hint

```
/aid-deploy work-NNN
```

Required: work ID. If only one work exists, auto-select it.

## Workspace

```
.aid/
  knowledge/
    STATE.md                   ← minimum grade, Q&A (Pending)
.aid/{work}/
  STATE.md                     ← § Deploy Status (current operation status, history)
  packages/                    ← product (one file per release)
    package-001-{name}.md
    package-002-{name}.md
  PLAN.md                      ← deliveries and sequencing
  tasks/                       ← task files with statuses
  features/                    ← feature SPECs
```

## ⚠️ Pre-flight Checks

1. Verify `.aid/` workspace exists.
2. Resolve work directory (same routing as other skills).
3. Read work `STATE.md` `## Deploy Status` section (or create it if absent).
4. Read `PLAN.md` — identify deliveries and their statuses.
5. Check work `STATE.md` `## Tasks Status` — check statuses and grades.
6. If Deploy Status shows an active package → resume from that step (see State Detection).

## State Detection

Read work `STATE.md` `## Deploy Status`:
- **Status: Idle** → Start new package (Step 1)
- **Status: Selecting** → Resume delivery selection (Step 2)
- **Status: Verifying** → Resume verification (Step 3)
- **Status: Packaging** → Resume packaging (Step 4)
- **Status: Done** → Re-run mode (see Re-run section)

Print the state-entry line and "you are here" map:

**IDLE / first run:**
```
[State: IDLE] — No active release; begin assessing eligible deliveries.
aid-deploy  ▸ you are here
  [● IDLE ] → [ SELECTING ] → [ VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**SELECTING:**
```
[State: SELECTING] — Presenting eligible deliveries for user to include in this release.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [● SELECTING ] → [ VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**VERIFYING:**
```
[State: VERIFYING] — Running full build, tests, and lint against selected deliveries.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [● VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**PACKAGING:**
```
[State: PACKAGING] — Producing release artifacts per infrastructure.md § Deployment.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [● PACKAGING ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Release complete; all deliveries and tasks marked Shipped.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [● DONE ]
```

## Inputs

- `.aid/{work}/PLAN.md` — deliveries, sequencing, success criteria
- `.aid/{work}/tasks/task-*.md` — task statuses and scope
- `.aid/{work}/features/*/SPEC.md` — what was specified
- Work `STATE.md` `## Tasks Status` table — review grades per task
- `known-issues.md` — if exists, check for Critical/High blockers
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, pull:
  - `infrastructure.md` § Deployment — how to package, where to publish
  - `infrastructure.md` § Source Control — VCS commands, branching strategy
  - `technology-stack.md` § Commands — build, lint, test commands
  - Any other docs INDEX summaries indicate are relevant

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

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| IDLE | `references/state-idle.md` | `operator` | → SELECTING |
| SELECTING | `references/state-selecting.md` | `operator` | → VERIFYING |
| VERIFYING | `references/state-verifying.md` | `operator` | → PACKAGING |
| PACKAGING | `references/state-packaging.md` | `operator` | → DONE |
| DONE | _(inline — see Re-run below)_ | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-deploy again` and exit.

## Re-run

When work `STATE.md` `## Deploy Status` is Done:

```
[State: DONE] — Release complete; all deliveries and tasks marked Shipped.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [● DONE ]
```

1. Show package history (from work `STATE.md` `## Deploy Status` History section).
2. Ask: **[1] New release** or **[2] Review package-NNN**?
3. If [1] → reset Status to Idle, proceed with Step 1 (only unshipped deliveries eligible).
4. If [2] → read the package file, compare against current state of tasks/deliveries,
   flag any discrepancies (tasks modified after shipping, new known issues).
   Offer to regenerate release notes if content changed.

## Quality Checklist

- [ ] All selected deliveries have all tasks complete
- [ ] All task grades meet minimum (from `.aid/knowledge/STATE.md` `**Minimum Grade:**`)
- [ ] No Critical/High known-issues unresolved
- [ ] Full build passes (not incremental)
- [ ] Full test suite passes
- [ ] Lint/format clean
- [ ] Package created per infrastructure.md § Deployment
- [ ] Package file saved with all sections filled
- [ ] Release notes generated in package file
- [ ] KB updates routed to `.aid/knowledge/STATE.md` `## Q&A (Pending)` (not direct edits)
- [ ] Delivery and task statuses updated to Shipped in work STATE.md
- [ ] Work STATE.md `## Deploy Status` updated (Done + History entry)
