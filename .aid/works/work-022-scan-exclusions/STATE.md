---
pipeline:
  path: lite
  initiator: aid-change-cli
started: "2026-07-22"
minimum_grade: "A+"
user_approved: yes
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: "2026-07-22T21:51:36Z"
pause_reason: --
block_reason: --
block_artifact: --
delivery_state: Executing
gate_tier: Large
gate_grade: "A+"
gate_timestamp: "2026-07-22T19:20:58Z"
---

# Work State -- work-022-scan-exclusions

> **State:** Describing | Defining | Specifying | Planning | Detailing | Executing
> **Phase:** Describe | Define | Specify | Plan | Detail | Execute

Single state file for **work-022-scan-exclusions** — a Lite (flattened, single-delivery)
change work initiated by `/aid-change-cli`. Makes `aid projects scan`'s directory-exclusion
set comprehensive AND user-configurable.

---

## Pipeline State

> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

Values live in the YAML frontmatter block above (written by `writeback-state.sh --pipeline`).

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-22 | Work created (shortcut: aid-change-cli) | -- | INTAKE scaffold; work-022 forced (git-history max = work-021; allocation-bug guard). Branch work-022-scan-exclusions off master, in place (no worktree, per session config). |
| 2026-07-22 | CAPTURE complete -- REQUIREMENTS.md written | -- | /aid-change-cli CAPTURE (aid-architect, opus) |
| 2026-07-22 | SPEC complete -- SPEC.md written | -- | /aid-change-cli SPEC |
| 2026-07-22 | PLAN complete -- PLAN.md + BLUEPRINT.md written | -- | /aid-change-cli PLAN |
| 2026-07-22 | DETAIL complete -- 3 tasks written (IMPLEMENT/TEST/DOCUMENT) | -- | /aid-change-cli DETAIL. Authoring collapsed into one aid-architect dispatch (design pre-specified); writer != reviewer preserved for GATE. |
| 2026-07-22 | Reconciled onto master @ b45d501a (PR #164 work-020) | -- | Disjoint footprint; no conflicts. DETAIL artifacts committed. |
| 2026-07-22 | GATE cleared -- all 7 definition artifacts | A+ | /aid-change-cli GATE (aid-reviewer opus). Cycle 1: 3 MEDIUM + 2 MINOR (grade C); cycle 2: all 5 Fixed, 0 regressions (A+). 1 OOS routed to delivery-blueprint-template.md maintenance. |
| 2026-07-22 | APPROVAL-HALT -- flattened work ready; nothing executed | A+ | /aid-change-cli. Awaiting user approval before /aid-execute work-022. |

---

## Delivery Lifecycle

<!-- AUTHORED — single-delivery flattened work. State scalar = frontmatter `delivery_state`. -->

- **Updated:** 2026-07-22T19:00:52Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

<!-- AUTHORED — single-writer per-task mutable state.
     State enum: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| task-001 | Done | quick-check: 0 HIGH, 1 LOW (fixed) | -- | Quick-check clean (98 Tier-A / 21 Tier-B byte-identical; AC-5/6/7/8/9/11/12 verified). LOW fixed: both twins' seeders now degrade to $HOME/.aid when the primary state home is absent/not writable (mirrors registry_register / Registry-Register's degrade), avoiding a repeat-WARN-forever on global installs; verified via ps51-compat-check (0 findings), AST ParseFile, and disposable-fixture smoke tests (both twins: degrade lands the seed in $HOME/.aid silently, --verbose shows the notice, repeat runs are silent/idempotent; normal per-user case unchanged -- seeds primary once, idempotent). | Expand both twins' prune sets + user-level config read/merge/seed |
| task-002 | In Review | -- | -- | PAR022 block added to test-aid-cli-parity.sh (66 assertions, AC-3..AC-10); bash -n clean; hand-verified locally via a throwaway driver against the real bin/aid + bin/aid.ps1 -- 66/66 passed on both twins (deleted after verification); full canonical suite deferred to CI. Awaiting reviewer dispatch. | Parity + guardrail tests |
| task-003 | Pending | -- | -- | -- | Docs: cli.mdx + install help + release ledger |

---

## Delivery Gate

<!-- AUTHORED — gate criteria read from BLUEPRINT.md § Gate Criteria; grade in frontmatter. -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|
