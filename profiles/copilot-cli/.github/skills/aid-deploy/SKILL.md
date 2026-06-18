---
name: aid-deploy
description: >
  Package completed deliveries into a release. Selects eligible deliveries,
  verifies the combined build, packages according to project infrastructure,
  generates release notes, and updates artifact statuses. Use when deliveries
  are complete and ready to ship.
  State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.
allowed-tools: Read, Glob, Grep, shell, Write
---

# Package & Ship

Package completed deliveries into a release.

## Agents Involved

- **Default executor:** `aid-operator` (orchestrates the release: verifies build, packages artifacts, updates statuses).
- **Specialist consults (optional):** `aid-tech-writer` for release notes / changelog, `aid-operator` if CI/CD configuration changes are needed during release, `aid-reviewer` for final pre-release verification.

## Argument-Hint

```
/aid-deploy work-NNN
```

Required: work ID. If only one work exists, auto-select it.

## Workspace

```
.aid/
  knowledge/
    STATE.md                   ← Q&A, Review History (settings → .aid/settings.yml), Q&A (Pending)
.aid/{work}/
  STATE.md                     ← § Deploy State (current operation status, history)
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
3. Read work `STATE.md` `## Deploy State` section (or create it if absent).
4. Read `PLAN.md` — identify deliveries and their statuses.
5. Check work `STATE.md` `## Tasks State` — check statuses and grades.
6. If Deploy State shows an active package → resume from that step (see State Detection).

## State Detection

Read work `STATE.md` `## Deploy State`:
- **Status: Idle** → IDLE state (start new package; see `references/state-idle.md`)
- **Status: Selecting** → SELECTING state (resume delivery selection; see `references/state-selecting.md`)
- **Status: Verifying** → VERIFYING state (resume verification; see `references/state-verifying.md`)
- **Status: Packaging** → PACKAGING state (resume packaging; see `references/state-packaging.md`)
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
- Work `STATE.md` `## Tasks State` table — review grades per task
- `known-issues.md` — if exists, check for Critical/High blockers
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, pull:
  - `infrastructure.md` § Deployment — how to package, where to publish
  - `infrastructure.md` § Source Control — VCS commands, branching strategy
  - `technology-stack.md` § Commands — build, lint, test commands
  - Any other docs INDEX summaries indicate are relevant

## Dispatch Protocol

This skill follows the L1+L2+L3 subagent-visibility protocol (work-003 traceability —
heartbeats, ETA timers, calibration). The full checklist lives in
`.github/aid/templates/dispatch-protocol-checklist.md`; read it before any subagent
dispatch in this skill.

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| IDLE | `references/state-idle.md` | `aid-operator` | → SELECTING |
| SELECTING | `references/state-selecting.md` | `aid-operator` | → VERIFYING |
| VERIFYING | `references/state-verifying.md` | `aid-operator` | → PACKAGING |
| PACKAGING | `references/state-packaging.md` | `aid-operator` | → DONE |
| DONE | `references/state-done.md` | `inline` | → halt |
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

## Quality Checklist

- [ ] All selected deliveries have all tasks complete
- [ ] All task grades meet minimum (from `bash .github/aid/scripts/config/read-setting.sh --skill deploy --key minimum_grade --default A`)
- [ ] No Critical/High known-issues unresolved
- [ ] Full build passes (not incremental)
- [ ] Full test suite passes
- [ ] Lint/format clean
- [ ] Package created per infrastructure.md § Deployment
- [ ] Package file saved with all sections filled
- [ ] Release notes generated in package file
- [ ] KB updates routed to `.aid/knowledge/STATE.md` `## Q&A (Pending)` (not direct edits)
- [ ] Delivery and task statuses updated to Shipped in work STATE.md
- [ ] Work STATE.md `## Deploy State` updated (Done + History entry)
