---
pipeline:
  path: lite
  initiator: aid-change-cli
started: "2026-07-22"
minimum_grade: "A+"
user_approved: yes
lifecycle: Paused-Awaiting-Input
phase: Execute
active_skill: aid-execute
updated: "2026-07-22T23:34:31Z"
pause_reason: "PR #166 open; CI-caught regression fixed (f447f6ab), re-running CI; awaiting merge"
block_reason: --
block_artifact: --
delivery_state: Done
gate_tier: Large
gate_grade: "A+"
gate_timestamp: "2026-07-22T22:40:05Z"
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
| 2026-07-22 | EXECUTE (/aid-execute work-022) -- 3 tasks Done | -- | Reconciled onto master 60a3c70f (beta.3). task-001 IMPLEMENT (e1ed9b86 + 81a1b862 LOW fix), task-002 TEST (654e94fa, PAR022 66/66), task-003 DOCUMENT (d453d6ce). |
| 2026-07-22 | DELIVERY GATE (delivery-001) PASS | A+ | aid-reviewer (opus): 0 in-scope findings, all 15 gate criteria PASS. Execution complete; awaiting PR/merge to master. |
| 2026-07-22 | PR #166 opened -> master | -- | CI caught a regression the A+ gate missed (gate ran bash -n + ps51-compat + logic review, NOT test-aid-remote.sh). |
| 2026-07-22 | CI regression FIXED (f447f6ab) | -- | test-aid-remote.sh failed: its `_make_fn_src` extracts + evals a bin/aid slice under `set -u` (AID_STATE_HOME unset), and task-001's top-level `readonly _AID_SCAN_CONFIG="${AID_STATE_HOME}/..."` (line 3004) hit unbound-var -> subshell exit 1 -> all expose T-1..T-8 failed. Fix: resolve the path at runtime inside the functions (registry precedent); audited window = no other top-level runtime-var refs. Reproduction proved before(exit1)/after(exit0). Re-pushing to re-run CI. |

---

## Delivery Lifecycle

<!-- AUTHORED — single-delivery flattened work. State scalar = frontmatter `delivery_state`. -->

- **Updated:** 2026-07-22T22:40:05Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

<!-- AUTHORED — single-writer per-task mutable state.
     State enum: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| task-001 | Done | quick-check: 0 HIGH, 1 LOW (fixed) | -- | Quick-check clean (98 Tier-A / 21 Tier-B byte-identical; AC-5/6/7/8/9/11/12 verified). LOW fixed: both twins' seeders now degrade to $HOME/.aid when the primary state home is absent/not writable (mirrors registry_register / Registry-Register's degrade), avoiding a repeat-WARN-forever on global installs; verified via ps51-compat-check (0 findings), AST ParseFile, and disposable-fixture smoke tests (both twins: degrade lands the seed in $HOME/.aid silently, --verbose shows the notice, repeat runs are silent/idempotent; normal per-user case unchanged -- seeds primary once, idempotent). | Expand both twins' prune sets + user-level config read/merge/seed |
| task-002 | Done | 66/66 (hand-verified) | -- | PAR022 block added to test-aid-cli-parity.sh (66 assertions, AC-3..AC-10); bash -n clean; hand-verified locally via a throwaway driver against the real bin/aid + bin/aid.ps1 -- 66/66 passed on both twins; full canonical suite deferred to CI. Independent review deferred to the delivery GATE (covers tests + docs + code together). Commit 654e94fa. | Parity + guardrail tests |
| task-003 | Done | -- | -- | cli.mdx + install.md + release-tracking Unreleased [CHANGE]; astro-build render-verified; commit d453d6ce. Flagged pre-existing OOS: .mdx pipe-tables render as literal text (site GFM-plugin gap). | Docs: cli.mdx + install help + release ledger |

---

## Delivery Gate

<!-- AUTHORED — gate criteria read from BLUEPRINT.md § Gate Criteria; grade in frontmatter. -->

- **Issue List:** none (delivery gate A+, 0 in-scope findings; 2 OOS not counted — pre-existing pwsh stray-`0` + `.mdx` pipe-table render gap, both routed as follow-ups).

---

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|
