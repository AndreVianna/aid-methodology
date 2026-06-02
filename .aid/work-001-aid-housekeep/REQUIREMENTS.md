# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Initial interview started | /aid-interview |
| 2026-06-02 | All 10 sections captured (FR1–FR7, NFR1–5, C1–3, D1–2, AC1–11); Priority=Immediate | /aid-interview CONTINUE |
| 2026-06-02 | Interview complete — approved | /aid-interview |
| 2026-06-02 | Cross-reference complete (Grade A); Q1 resolved & applied to feature-002 | /aid-interview |

## 1. Objective

Add an **optional** on-demand pipeline skill, `/aid-housekeep`, that reconciles drift
between the repository's current state and its AID artifacts. It performs three jobs in
sequence:

1. **KB delta refresh** — detect what changed on `master` since the KB was last approved
   (primarily via git history), inspect the changed sources, update only the affected KB
   documents, and request re-approval.
2. **Summary delta refresh** — determine whether that KB delta affects
   `knowledge-summary.html`; if so, regenerate/update it and re-run its quality gate;
   otherwise leave it untouched.
3. **`.aid/` cleanup** — gather stale artifacts (temp files, completed/merged work
   folders, stray reports, outdated build-only artifacts, orphaned docs) into a
   **checklist**, present it to the user, and delete only what the user confirms per item.

## 2. Problem Statement

After work merges to `master`, the Knowledge Base and `knowledge-summary.html` drift out
of sync with the codebase, and `.aid/` accumulates stale artifacts (temp files, completed
work folders, stray tool reports like `verify-deterministic-report.json`, build-only
outputs). Today reconciliation is manual and heavyweight — the only tool is a full
`/aid-discover` re-run, which re-analyzes everything rather than just the delta. There is
no lightweight, on-demand way to (a) detect only what changed since the last approval,
(b) update only the affected KB/summary, and (c) safely sweep cruft under user control.

## 3. Users & Stakeholders

Primary user: the **AID maintainer/adopter** running the pipeline on a project — the same
audience as every other `/aid-*` skill. They invoke `/aid-housekeep` on demand to reconcile
drift after merges and to sweep `.aid/` cruft.

## 4. Scope

### In Scope

- A new optional skill `/aid-housekeep` with the three capabilities above.
- Git-history-based delta detection against the KB's last-approved baseline.
- Incremental KB update + re-approval (a "lite" cousin of `/aid-discover`, not a full re-discovery).
- Conditional summary regeneration gated on whether the delta affects the summary.
- A user-confirmed, checklist-driven `.aid/` cleanup.
- Pipeline integration (rendered into all profiles like the other skills).

### Out of Scope

- Full re-discovery from scratch (that remains `/aid-discover --reset`).
- Destructive cleanup without per-item user confirmation.
- Auto-pushing or committing directly to `master` (the skill commits only on an
  `aid/housekeep-*` branch and never pushes).
- Effect-aware (fine-grained) summary regeneration — summary staleness is coarse/date-based
  by design (FR3).

## 5. Functional Requirements

> Design model chosen at interview: **(c) hybrid** — `/aid-housekeep` owns a lightweight
> delta-scoping layer of its own, but **delegates the heavy, gated work** to the existing
> skills (KB review/approval to `/aid-discover`; summary staleness/regeneration to
> `/aid-summarize`). It does not duplicate their review/approval or staleness logic.

- **FR1 — Delta detection (SHA-anchored, date fallback).** Anchor "since the KB was last
  approved" on a recorded **commit SHA**:
  - On KB approval, persist the `master` commit SHA to a new `Approved-At-Commit:` field
    in `knowledge/STATE.md`. Housekeep writes it after its own approval; `/aid-discover`'s
    approval writeback should set it going forward (dependency — see §8).
  - **Online-first:** `git fetch origin` first, then compute the delta as
    `git log/diff <approved-sha>..origin/master` (so merges/pushes the user hasn't pulled
    are still caught). If the fetch **fails** (no network), do **not** silently fall back —
    **halt and request explicit user permission** to proceed offline against local
    `master`; only then diff `<approved-sha>..master`.
  - **Bootstrap fallback:** when no `Approved-At-Commit:` exists yet (first run / legacy
    KB), fall back to the existing approval **date** (`Last KB Review` / `User Approved`)
    via `git log --since=<date> origin/master`, and record a SHA at the next approval so
    subsequent runs use the precise path.
  - Scope the delta to decide which KB areas (discovery sub-agents / KB docs) are
    potentially affected.
- **FR2 — KB refresh (auto-scoped, delegated, gated).** If a delta exists:
  - **Auto-map** the changed file paths to the KB docs/sub-agents they affect, using the
    declared doc-set ownership map (e.g., `canonical/skills/**` → architecture + module-map
    + feature-inventory; `tests/**` → test-landscape; `profiles/**` → architecture +
    pipeline-contracts; etc.). This path→doc mapping is the **new "delta-scoping" logic the
    skill owns**.
  - **Confirm-and-adjust:** show the user the proposed refresh scope (which docs /
    sub-agents will run) and let them adjust before dispatch.
  - **Dispatch targeted re-discovery:** run only the in-scope discovery sub-agents on the
    delta via `/aid-discover`'s existing targeted re-discovery path, then route through its
    REVIEW → (Q&A/FIX) → APPROVAL gate, ending in a fresh `**User Approved:** yes`.
  - Own the delta-scoping; reuse the review/approval gate (no duplication).
- **FR3 — Summary refresh (delegated, coarse staleness).** Once the KB is current &
  approved, reconcile `knowledge-summary.html` by delegating to `/aid-summarize`. Use its
  existing **STALE-CHECK** (date-based: any KB approval newer than the last summary →
  regenerate) — *coarse by design*: no effect-aware KB-doc→section mapping. Regeneration
  runs through `/aid-summarize`'s two-grade quality gate, so "regenerate whenever the KB
  moved" is always safe; the cost is just a rebuild. No-op when the summary is already
  current.
- **FR4 — `.aid/` cleanup (checklist, user-confirmed, tiered).** Gather stale artifacts
  into a checklist, present it to the user, and delete only the items the user confirms
  per item.
  - **Tiered defaults:** clearly-safe items (e.g., `.aid/.temp/`, `.aid/.heartbeat/`, stray
    tool reports like `verify-deterministic-report.json`, build-only artifacts) start
    **checked**; higher-risk items (work folders, anything that looks hand-authored) start
    **unchecked** and flagged "review."
  - **Work-folder removal criteria:** a `work-*` folder is offered only when it is
    **merged to `master`** — signal **(i)**, the necessary/primary signal (the work's
    deliverable commits are in `master`, detectable via git). `STATE.md` marked
    Deployed/concluded — signal **(ii)** — is the secondary confirmation:
    - (i) pass **and** (ii) pass → offer it (unchecked, per tiering).
    - (i) pass **but** (ii) fail → do **not** auto-offer; **prompt the user for explicit
      confirmation**, surfacing why (ii) didn't agree.
    - (i) fail → not offered (not merged ⇒ not safe).
  - **Absolute rule:** never offer the **currently active** work folder (the one in flight)
    for deletion, regardless of signals.
  - **Deletion mechanism:** **`git rm` (staged)** for tracked items (work folders,
    committed docs) — deletions appear in `git status` / the next commit and are
    recoverable from git history. Untracked cruft that git cannot stage (`.aid/.temp/`,
    `.aid/.heartbeat/`, stray tool reports) is removed with plain `rm`. No separate trash
    directory (it would itself become crud).
- **FR5 — Strict sequencing with hard gates; halt-and-resume.** The three jobs run
  **in order**: `KB refresh → summary refresh → cleanup`. Each stage must reach a
  passing/approved state before the next begins (KB up to date & approved before the
  summary is touched; summary OK before cleanup runs). Implemented as a **re-entrant state
  machine** (e.g., `KB-DELTA → SUMMARY-DELTA → CLEANUP` states) consistent with the rest
  of the pipeline: when a gate stalls (user declines KB re-approval, or the summary
  quality gate is below minimum), the skill **halts cleanly with a "resume here" message**.
  Re-running `/aid-housekeep` picks up at the stalled stage — it does not restart from
  job 1. Filesystem state is the source of truth for which stage to resume.
- **FR6 — Optional on-demand skill.** `/aid-housekeep` is not part of the mandatory
  pipeline flow; it is invoked on demand and rendered into all install profiles like the
  other `/aid-*` skills.
- **FR7 — Invocation modes.** Default (no args) runs the full gated sequence
  `KB → summary → cleanup`. A `--cleanup-only` flag jumps straight to the cleanup checklist
  (job #3), skipping the KB and summary stages, for quick housekeeping when the KB is known
  to be current. (The gating is a *correctness-ordering* guarantee; a deliberate
  cleanup-only run does not violate it.)

## 6. Non-Functional Requirements

- **NFR1 — Safety / no-data-loss.** No file is removed without explicit per-item user
  confirmation. Tracked deletions go through `git rm` (recoverable from history). The
  currently active work folder is never offered for deletion.
- **NFR2 — Idempotency.** Re-running on a clean state (no KB delta, summary current,
  nothing stale) is a no-op that reports "nothing to do" — never regenerates or deletes
  needlessly.
- **NFR3 — Transparency.** Every mutating action is shown to the user before execution:
  the proposed KB refresh scope (FR2 confirm-and-adjust) and the cleanup checklist (FR4).
  No silent KB edits, summary rebuilds, or deletions.
- **NFR4 — Pipeline consistency.** Implemented as a thin-router state-machine SKILL.md
  consistent with the other `/aid-*` skills (state-entry banners, halt/resume semantics,
  L1/L2/L3 traceability for any long-running sub-agent dispatch). Authored in `canonical/`
  and rendered into all install profiles.
- **NFR5 — Tested.** The new deterministic logic — delta detection, path→KB-doc mapping,
  cleanup classification, and work-folder safety rules — is covered by a canonical test
  suite under `tests/canonical/` (the project convention).

## 7. Constraints

- **C1 — Ordering is mandatory.** KB → summary → cleanup, gated. No stage may run before
  the previous stage has reached its passing/approved state.
- **C2 — Online-first, permissioned offline.** Default operation assumes network access
  (`git fetch origin`). On fetch failure, the skill must request explicit user permission
  before operating offline against local `master`. No silent offline fallback.
- **C3 — Auto-commit on a dedicated branch; never push.** The skill works on an
  `aid/housekeep-*` branch (creating it if needed — never operating directly on `master`)
  and **commits each stage as it completes** (KB refresh, summary refresh, cleanup → one
  commit per stage with a descriptive message). It **never pushes**; the user pushes and
  opens the PR. Aligns with the project rule "never commit to `master` directly — branch +
  PR always."

## 8. Assumptions & Dependencies

- **D1 — Approval writeback records the SHA.** FR1's precise path depends on
  `Approved-At-Commit:` being written at KB approval. `/aid-housekeep` writes it after its
  own approval; ideally `/aid-discover`'s APPROVAL/WRITEBACK is also updated to set it
  (otherwise housekeep stays on the date fallback after a plain `/aid-discover` approval).
- **D2 — Overlap with known crud fix.** The recurring `verify-deterministic-report.json`
  in the `work-*` namespace already has a recorded KB Q&A resolution (change
  `run_generator.py` to pass `report_path=None`). The cleanup job (FR4) should coordinate
  with / not conflict with that fix.

## 9. Acceptance Criteria

- **AC1 — Delta detection (SHA path).** Given a KB approved at commit `X` with merges to
  `origin/master` since, `/aid-housekeep` fetches, computes `X..origin/master`, and reports
  the changed paths.
- **AC2 — Delta detection (bootstrap).** Given no `Approved-At-Commit:` recorded, the skill
  falls back to the approval date and records a SHA at the next approval.
- **AC3 — Offline gate.** Given the fetch fails, the skill halts and requests explicit
  permission before diffing local `master`; without permission it does not proceed.
- **AC4 — KB scope + refresh.** Given a delta, the skill auto-maps changed paths to owning
  KB docs/sub-agents, shows the scope for confirm/adjust, dispatches only those sub-agents,
  and routes through `/aid-discover`'s REVIEW→APPROVAL to a fresh `User Approved: yes`.
- **AC5 — No-delta no-op.** Given no delta, the KB stage reports "current," dispatches no
  sub-agents, and advances.
- **AC6 — Summary reconciliation.** After KB approval, the summary regenerates iff its
  STALE-CHECK says the KB is newer than the last summary, passing the two-grade gate before
  advancing; otherwise no-op.
- **AC7 — Cleanup checklist.** The cleanup presents a tiered checklist (safe items checked,
  work folders unchecked); only merged-to-`master` work folders are offered; an
  (i)-pass/(ii)-fail folder triggers an explicit-confirm prompt; the active work folder is
  never offered.
- **AC8 — Deletion mechanism.** Confirmed tracked items are removed via `git rm` (staged);
  untracked cruft via `rm`; changes are committed per stage on an `aid/housekeep-*` branch;
  the skill never pushes and never commits to `master`.
- **AC9 — Halt & resume.** A stalled gate (declined KB approval, summary gate below min)
  halts with a resume message; re-running resumes at the stalled stage, not job 1.
- **AC10 — Cleanup-only.** `--cleanup-only` jumps straight to the cleanup checklist,
  skipping the KB and summary stages.
- **AC11 — Distribution.** The skill is rendered into all install profiles and is absent
  from the mandatory pipeline flow (optional / on-demand).

## 10. Priority

**Immediate / High.** Build next. Directly addresses current pain: post-merge KB and
summary drift, and accumulating `.aid/` cruft (e.g., the recurring
`verify-deterministic-report.json` in the `work-*` namespace).
