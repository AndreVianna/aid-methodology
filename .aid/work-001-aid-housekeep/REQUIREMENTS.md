# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Initial interview started | /aid-interview |
| 2026-06-02 | All 10 sections captured (FR1–FR7, NFR1–5, C1–3, D1–2, AC1–11); Priority=Immediate | /aid-interview CONTINUE |
| 2026-06-02 | Interview complete — approved | /aid-interview |
| 2026-06-02 | Cross-reference complete (Grade A); Q1 resolved & applied to feature-002 | /aid-interview |
| 2026-06-02 | Design pivot (user review during /aid-execute): FR1/FR2 reframed to agent-driven KB reconciliation (inspect repo content vs KB; git = hint, not boundary). Dropped SHA-anchoring, path→doc map, Approved-At-Commit + D1, detect-delta/scope-delta scripts. C2/NFR5/AC1–5/§8-D1 updated. Rule: scripts only for deterministic / eliminate-subjectivity work; analysis→agent. | /aid-execute (loopback) |

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
- Agent-driven KB reconciliation: the agent inspects actual repo content (code/data/docs)
  against the KB to find and correct drift, with git history as an optional hint (not a boundary).
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

> Design model (revised 2026-06-02 after user review): `/aid-housekeep` is **agent-driven**.
> The KB stage is a lightweight, drift-focused **re-discovery** — the agent reasons about what
> has drifted and plans the fix; it does NOT encode that judgment in scripts. It **delegates**
> the gated heavy lifting to the existing skills (KB review/approval to `/aid-discover`; summary
> staleness/regeneration to `/aid-summarize`) and does not duplicate their logic. Scripts are
> reserved for deterministic work or where we want to eliminate the subjectivity of an analysis
> (the branch/commit safety guard, run-state I/O, the cleanup safety classification); anything
> needing analysis, understanding, or planning is the agent's job.

- **FR1 — KB reconciliation (agent-driven; git is a hint, not a boundary).** The KB stage is a
  drift-focused re-discovery: the agent **autonomously inspects the actual repo content**
  (codebase + data + documentation) and reconciles it against the KB's claims, finding
  discrepancies — including drift a purely git-scoped pass would miss (e.g. KB claims that were
  subtly wrong all along). Git history is an **optional hint** to focus attention first: the
  agent may run `git log/diff` since the last recorded KB review (`Last KB Review` date, already
  in `knowledge/STATE.md`) to see what changed recently, but it is **not limited to the git
  delta**. There is **no SHA-anchored detection script, no `Approved-At-Commit` field, and no
  path→doc mapping table** — detecting and scoping drift is analysis/understanding the agent
  performs, not deterministic logic to encode.
- **FR2 — Scoped refresh + re-approval (delegated, gated).** The agent proposes the set of
  affected KB docs/areas and the corrections it found, **shows them for confirm-and-adjust**,
  then drives `/aid-discover`'s existing **targeted re-discovery** + REVIEW → (Q&A/FIX) →
  APPROVAL gate to a fresh `**User Approved:** yes`. The agent reuses the review/approval gate;
  it does not duplicate it. (It may synthesize an `Impact: Required` Q&A entry in
  `knowledge/STATE.md` naming the affected docs to drive `/aid-discover`'s re-entry — Q1, 2026-06-02.)
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
- **NFR5 — Tested.** The new **deterministic** logic — the branch/commit safety guard
  (`branch-commit`), run-state I/O + the resume-resolution rule (`housekeep-state`), and the
  cleanup classification + work-folder safety rules (`cleanup-classify`) — has canonical unit
  suites under `tests/canonical/` (the project convention). The agent-driven prose (the KB
  reconciliation, the summary delegation, the state-machine flow) has **no unit suite** — it is
  analysis/judgment, not deterministic logic — and is verified by **dogfooding + the existing
  render-drift CI / generator self-tests**. There is **no bespoke integration or distribution
  test** (consistent with AID's no-E2E-tier policy, `test-landscape.md`).

## 7. Constraints

- **C1 — Ordering is mandatory.** KB → summary → cleanup, gated. No stage may run before
  the previous stage has reached its passing/approved state.
- **C2 — Git is a hint, handled conversationally.** When the agent uses git history to focus
  the reconciliation, it prefers up-to-date remote state (it may `git fetch`); if the network
  is unavailable it says so and proceeds from local state / broader content inspection — the
  reconciliation is not bounded by git, so there is no hard online-only gate. (Down-graded from
  the former SHA-anchored "online-first/permissioned-offline" rule, 2026-06-02.)
- **C3 — Auto-commit on a dedicated branch; never push.** The skill works on an
  `aid/housekeep-*` branch (creating it if needed — never operating directly on `master`)
  and **commits each stage as it completes** (KB refresh, summary refresh, cleanup → one
  commit per stage with a descriptive message). It **never pushes**; the user pushes and
  opens the PR. Aligns with the project rule "never commit to `master` directly — branch +
  PR always."

## 8. Assumptions & Dependencies

- **D1 — REMOVED (2026-06-02).** Formerly "approval writeback records the SHA." Dropped with
  the SHA-anchoring redesign — the agent uses the existing `Last KB Review` date as a hint;
  no `Approved-At-Commit:` field, no `/aid-discover` writeback edit needed.
- **D2 — Overlap with known crud fix.** The recurring `verify-deterministic-report.json`
  in the `work-*` namespace already has a recorded KB Q&A resolution (change
  `run_generator.py` to pass `report_path=None`). The cleanup job (FR4) should coordinate
  with / not conflict with that fix.

## 9. Acceptance Criteria

- **AC1 — KB reconciliation (content-driven).** Given a KB out of sync with the repo, the
  agent inspects actual repo content (code/data/docs) — using git history since `Last KB Review`
  as an optional starting hint, not a boundary — and identifies the KB docs/areas that have
  drifted, including drift not attributable to a recent git change.
- **AC2 — Scope proposal + confirm.** The agent presents the affected docs + proposed
  corrections for confirm-and-adjust before any KB change (NFR3 transparency).
- **AC3 — Delegated re-approval.** The agent drives `/aid-discover`'s targeted re-discovery →
  REVIEW → (Q&A/FIX) → APPROVAL to a fresh `**User Approved:** yes` (reusing the gate; e.g. via
  a synthesized `Impact: Required` Q&A entry naming the affected docs).
- **AC4 — No-drift no-op.** Given the KB already matches the repo, the KB stage reports
  "current," makes no changes, and advances (NFR2).
- **AC5 — Offline tolerance.** Given no network, the agent proceeds from local state / content
  inspection (git fetch is a best-effort hint) — it does not hard-fail.
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
