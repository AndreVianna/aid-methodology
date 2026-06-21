# Work State -- work-005-profile-generator-simplify

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory.

> **State:** Detailing
> **Phase:** Detail
> **Minimum Grade:** A (resolved at runtime from `.aid/settings.yml`)
> **Started:** 2026-06-20
> **User Approved:** yes

---

## Pipeline State

<!-- AUTHORED -- written at every phase/state transition. All values closed enums. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-21T07:14:00Z
- **Pause Reason:** delivery-001 COMPLETE + gated A+ (8 tasks, 9 commits); PR #100 open against master (CI green so far; canonical/installer checks pending). deliveries 002 + 003 not yet executed. Release-Safety Gate: no release until all 3 merge.
- **Block Reason:** --
- **Block Artifact:** --

---

## Triage

<!-- AUTHORED -- populated by `aid-interview` TRIAGE state. -->

- **Path:** full
- **Decision rationale:** Large multi-target architectural refactor (~7,000 LOC across 13 generator scripts, 40+ dependent files); user explicitly requested a careful full work. No single-recipe match → full.

---

## Interview State

<!-- AUTHORED -- updated by `aid-interview` as each section is completed. -->

**State:** Approved  **Grade:** A+ (CROSS-REFERENCE passed 2026-06-20; min A) — zero counted findings; cross-reference Complete

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-06-20 |
| 2 | Problem Statement | Complete | 2026-06-20 |
| 3 | Users & Stakeholders | Complete | 2026-06-20 |
| 4 | Scope | Complete | 2026-06-20 |
| 5 | Functional Requirements | Complete | 2026-06-20 |
| 6 | Non-Functional Requirements | Complete | 2026-06-20 |
| 7 | Constraints | Complete | 2026-06-20 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-20 |
| 9 | Acceptance Criteria | Complete | 2026-06-20 |
| 10 | Priority | Complete | 2026-06-20 |

Seeded from the A+ intake description authored collaboratively before `/aid-interview`.
**Approved 2026-06-20** by user (COMPLETION Step 5, choice [1]).

**Review History:** Requirements built via full-path conversational interview (one question per
turn). All 4 scope decisions resolved — Q1 uniform-format (commit, verify-first); update-all-tools
one-version (FR10/FR11); Q3 routing directive dropped [a]; Q4 migration = complete replacement.
Quality check passed (AC4b added for the FR4a gating study). KB hydrated (format⊥behavior term).
Grade pending CROSS-REFERENCE.

**Review History (structured):**

| # | Date | Grade | Phase | Notes |
|---|------|-------|-------|-------|
| 1 | 2026-06-20 | — | Feature Decomposition | aid-architect proposed 7 features → user-requested adversarial A+ gate (aid-reviewer, 11 findings) FAILED it: overlap (003/004 one change), over-granularity (study-as-feature + catch-all lockstep), 2 unowned gaps (dead-test removal, §7a guard). Corrected to **4 features**; user approved; 4 SPEC.md scaffolds created. |
| 2 | 2026-06-20 | C → re-grade pending | Cross-Reference | aid-reviewer graded **C** (all load-bearing claims verified TRUE; 3 Required Architecture contradictions). Resolved with user: Q1 internal-shape (not literal `.{tool}/`), Q2 FR3 cursor-scoped (keep `canonical/rules/` for Antigravity), Q3 FR2 supersedes cornerstone R6 for Codex. REQUIREMENTS + feature-002/004 SPECs updated; awaiting re-grade. |
| 3 | 2026-06-20 | B | Cross-Reference (re-grade) | aid-reviewer re-graded **B**: Q1/Q2/Q3 all confirmed Fixed (verified vs `profiles/*.toml`), **zero regressions/new findings**. Grade dragged by 2 carried-over LOW (FR1 extras-clause tension, FR10 unflagged positional/`--dry-run` deltas) + 1 MINOR (KB staleness, OOS). Raised Q4 (editorial) to reach A. |
| 4 | 2026-06-20 | (pending re-grade) | Research-driven consolidation | User requested all-tools rules/format research (5 agents). Finding: every tool reads its root file always-on; rules folders are conditional-only (AID uses none). Consolidated update: FR3 drops ALL rules folders + deletes `canonical/rules`/mechanism (supersedes Q2), folds always-on into root file; FR1 reworded (dissolves row-4); FR10 note (row-5); Codex-TOML + cursor-reliability routed to FR4a. Q4 resolved [A]. |
| 5 | 2026-06-20 | B | Cross-Reference (final re-grade) | aid-reviewer: rows 4-5 (prior LOW) cleared; but the consolidated edit **introduced 2 new LOW** — it over-claimed hedged research (Cursor always-on guarantee; `.agent/` = legacy) as confirmed fact. Softened FR1/FR3/A1/A3/FR4a + feature-001/002 SPECs to "research-indicated, verified in FR4a." Only the OOS MINOR (KB staleness) remains. Confirming re-grade pending. |
| 6 | 2026-06-20 | **A+** | Cross-Reference (confirming) | **Zero counted findings** (rows 9-10 → Fixed; all load-bearing claims re-verified accurate on disk — LOC counts, profile roots, `bin/aid`, 53 suites, extras mechanism; feature mapping 1:1; KB-staleness OOS). A+ ≥ min A → **CROSS-REFERENCE PASSED**. |

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-20 | Work created | -- | Scaffolded by aid-interview FIRST-RUN |
| 2026-06-20 | TRIAGE -> full | -- | Large architectural refactor; user requested full path |
| 2026-06-20 | Interview seeded | -- | REQUIREMENTS.md populated from A+ intake; 3 sections Partial pending scope decisions |
| 2026-06-20 | TRIAGE confirmed -> full (user chose [1]) | -- | CHAIN to CONTINUE; running conversational interview one question per turn |
| 2026-06-20 | COMPLETION -> Interview Approved (user [1]) | -- | All sections Complete; PAUSE-FOR-USER-DECISION; next: FEATURE-DECOMPOSITION on re-invoke |
| 2026-06-20 | FEATURE-DECOMPOSITION complete | -- | A+ gate corrected 7->4 features; 4 SPEC.md scaffolds created; CHAIN to CROSS-REFERENCE |
| 2026-06-20 | CROSS-REFERENCE graded | C | Below min A; all load-bearing claims verified TRUE; 3 Required Architecture contradictions raised as Q1-Q3 (resolving one at a time) |
| 2026-06-20 | CROSS-REFERENCE Q&A resolved | -- | Q1-Q3 answered; REQUIREMENTS + feature-002/004 SPECs updated; re-grade pending (expect >= A) |
| 2026-06-20 | CROSS-REFERENCE re-graded | B | 3 contradictions Fixed, no regressions; 2 LOW + 1 MINOR editorial remain; Q4 raised to reach A |
| 2026-06-20 | All-tools rules/format research (5 agents) | -- | Every tool reads root file always-on; rules folders conditional-only; Codex agents TOML-native (only divergence) |
| 2026-06-20 | Consolidated update applied | -- | FR1/FR3/FR10/FR4a/A1/A3 + feature-001/002/004 SPECs; Q2 superseded, Q4 resolved [A]; re-grade pending (expect >= A) |
| 2026-06-20 | CROSS-REFERENCE final re-grade | B | rows 4-5 cleared; 2 self-introduced LOW (over-claimed research as fact) found + softened to research-indicated; only OOS MINOR remains; confirming re-grade pending |
| 2026-06-20 | CROSS-REFERENCE passed | A+ | Zero counted findings; cross-reference Complete; CHAIN to DONE |
| 2026-06-20 | DONE — interview closed (user [3]) | A+ | Approved + 4 features + cross-ref A+; review ledgers cleaned; ready for /aid-specify |
| 2026-06-20 | SPECIFY feature-001 → Ready | A+ | Capability study + format decision spec; codebase Finding D1 (no native dispatch); 1 B+→A+ fix cycle. Next: feature-002 |
| 2026-06-20 | SPECIFY feature-002 → Ready | A+ | Copy-based generator spec; 13→4 scripts (~7k→~900–1.3k LOC); Finding G1 (root file install-merged); 1 B+→A+ fix cycle. Next: feature-003 |
| 2026-06-20 | SPECIFY feature-003 → Ready | A+ | Atomic aid-update spec (bash+PS); stage-all-first atomicity, marker-prune + retired-root sweep, manifest-diff EXTENDS era-detection; 1 D→A+ fix cycle (PS twin names). Next: feature-004 |
| 2026-06-20 | SPECIFY feature-004 → Ready | A+ | Lockstep + CI-closeout spec; residual-vs-owned delineation (no gap/overlap), content-isolation R6 revision, capability-study KB promotion, two-part AC4; 1 D+→A+ fix cycle. |
| 2026-06-20 | SPECIFY phase complete — all 4 features Ready at A+ | A+ | PAUSE; ready for /aid-plan (delivery sequencing) |
| 2026-06-20 | INTENT-FIDELITY review (user-requested) | — | Specs necessary + sufficient-w/-caveat but NOT lean. 3 corrections adopted: (1) FR5 (a)→(c) MINIMAL — orchestrator had recommended (a), over-eng; (2) slim feature-001 study apparatus; (3) widen AC4a behavioral sample to 3 tools + name asserted-not-exercised (Copilot/Antigravity). +trim feature-003 atomicity. 4 pillars confirmed exactly-right. Revising + re-gating. |
| 2026-06-20 | INTENT revisions applied + re-gated | A+ | All 4 corrections landed coherently (C+→A+, 2 feature-001 dangling-ref fixes); specs now necessary + sufficient + LEAN. All 4 features Ready at A+. PAUSE; ready for /aid-plan. |
| 2026-06-20 | PLAN complete | A+ | 3 deliveries (d001=feat-001+002, d002=feat-003, d003=feat-004), linear, bound by a Release-Safety Gate (no release until all 3 merge; verified release.yml is tag-triggered). All features assigned, no cycle. delivery-00{1,2,3}/ created (Pending-Spec). PAUSE; ready for /aid-detail. |
| 2026-06-21 | DETAIL complete | A+ | 20 tasks across 3 deliveries (d001: 8 / d002: 5 / d003: 7); each delivery's breakdown ran an adversarial A+ gate that corrected over-granularity (d001 11→8, d002 7→5, d003 9→7+2 gate-steps) + a per-deliverable file review to A+. Execution graphs + wave-maps written to PLAN.md; AC3/AC4-behavioral recorded as delivery-gate steps. PAUSE; ready for /aid-execute. |

---

## Deploy State

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS (assembled at read time; never written directly)
     ============================================================ -->

## Features State

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-behavioral-parity-format | Ready | A+ | 6 | Intent-lean: study slimmed to 1 doc+decision (cite-join ledger dropped); AC4a widened to Cursor+Claude+Codex (Copilot/Antigravity asserted-via-D1, not exercised) |
| 2 | feature-002-symmetric-copy-generator | Ready | A+ | 8 | Intent-lean: FR5 → (c) MINIMAL (one-line `{root}`-prefix; ~93-file `{AID_ROOT}` churn avoided); 13→4 scripts; Finding G1; §7a guard |
| 3 | feature-003-atomic-aid-update | Ready | A+ | 9 | Intent-lean: atomicity = stage-all-first + idempotent re-run; bash+PS; marker-prune + retired-root sweep; FR10 one-version |
| 4 | feature-004-lockstep-ci-closeout | Ready | A+ | 5 | Intent-lean: residual delineation (no gap/overlap); R6 revision; `test-multitool-isolation.sh`; AC4 3-tool behavioral half |

## Plan / Deliveries

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- Work-owner-authored cross-reference Q&A (single writer, work active branch). -->

### Q1

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered ([1] adopt suggested, 2026-06-20)
- **Context:** FR1 promises all 5 tools render to a literal `.{tool}/{agents,skills,aid}`, but copilot-cli installs to host-mandated `.github/` and antigravity to `.agent/` — not freely renamable. Surfaced by /aid-interview cross-reference (grade C). Evidence: `profiles/copilot-cli.toml` output_root=`.github`, `profiles/antigravity.toml` output_root=`.agent`.
- **Suggested:** Keep host-required outer dirs (`.claude`/`.cursor`/`.codex`/`.github`/`.agent`); FR1 promises the uniform **internal** `{agents,skills,aid}` shape, not a literal `.{tool}` outer name.
- **Answer:** Adopted. FR1, AC1, Objective §1.1, and feature-002 SPEC reworded — symmetry = the uniform internal `{agents, skills, aid}` shape under each tool's host-required root dir; outer dirs are not renamed.

### Q2

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered ([1] adopt suggested, 2026-06-20)
- **Context:** FR3 deletes `canonical/rules/` + the extras mechanism, but Antigravity's `.agent/rules/aid-methodology.md` + `aid-review.md` are emitted from `canonical/rules/*.mdc` via the same `_render_cursor_extras` / `[[extras.rules]]` path. Wholesale deletion breaks Antigravity. Surfaced by cross-reference.
- **Suggested:** Scope FR3 to remove only the **cursor** `[extras]` block + `.cursor/rules/` output; retain `canonical/rules/` + the extras mechanism for Antigravity (or explicitly re-home Antigravity's methodology rules).
- **Answer:** Adopted. FR3 reworded to Cursor-scoped (cursor `[extras]` + `.cursor/rules/` only); `canonical/rules/` + `[[extras.rules]]` mechanism RETAINED for Antigravity (out of scope). Updated FR3, Scope §4.1, feature-002 SPEC.
- **[SUPERSEDED 2026-06-20]** by the all-tools rules/format research: FR3 now drops **ALL** rules folders (cursor **and** antigravity) and **deletes `canonical/rules/` + the mechanism entirely**; Antigravity's always-on rules fold into `AGENTS.md` (research-confirmed always-on) — they are NOT retained. The Q2 retention was based on the now-corrected assumption that `.agent/rules/` was required.

### Q3

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered ([1] adopt suggested, 2026-06-20)
- **Context:** FR2 unifies Codex to `.codex/{agents,skills,aid}`, but the work-003 content-isolation cornerstone (R6/D1) mandates Codex AID-own content nest under `.agents/aid/` and that `.codex/` carry **only** `agents/`. FR2 and R6 contradict. Surfaced by cross-reference.
- **Suggested:** This work **supersedes R6 for Codex** (retiring `.agents/` is the point); update `content-isolation.md` R6 as part of feature-002/004's KB lockstep, and have FR2 explicitly note it revises R6.
- **Answer:** Adopted. FR2 now states it consciously supersedes R6 for Codex; C1 + D1 note the revision; feature-004 SPEC owns the `content-isolation.md` R6 doc update (KB lockstep). Cornerstone evolves on purpose, with a paper trail.

### Q4

- **Category:** Editorial / Requirements
- **Impact:** Required-to-reach-A
- **Status:** Answered ([A] uniformize, 2026-06-20) — consolidated update **APPLIED** after the all-tools research (FR1 reword, FR3 rewrite, FR10 note, FR4a inputs, A1/A3; feature-001/002/004 SPECs). Row-4 LOW dissolved by the FR1 reword (no carve-out needed); row-5 FR10 deliberate-change note added; Q2 superseded.
- **Context:** Cross-reference RE-GRADE = B (min A). The 3 MEDIUM contradictions are confirmed Fixed (no regressions); grade is dragged by 2 carried-over LOW: (row 4) FR1's blanket "no tool-only extras folders" now in mild tension with the Q2-retained Antigravity `.agent/rules/` surface; (row 5) FR10 silently removes the existing `aid update [<tool>...]` positional + broadens `--dry-run` — intentional deltas not flagged. Surfaced by /aid-interview cross-reference re-grade. Evidence: ledger `interview-work-005-cross-ref-regrade.md` rows 4–5; `bin/aid:147-148`.
- **Research finding (Antigravity, 2026-06-20):** `.agent/rules/` is NOT hard-required — Antigravity reads `AGENTS.md` always-on (v1.20.3+); `.agent/` is the *legacy* folder (default moved to `.agents/` plural); only glob-scoped rules need a folder, and glob rules were already dropped for Cursor. → Decision [A]: drop Antigravity's glob rule, fold its always-on methodology into `AGENTS.md`, delete `canonical/rules/` + extras mechanism entirely, no FR1 exception (revises Q2/FR3). Verify vs live docs in feature-001.
- **Suggested:** Tighten FR1's closing clause to "no tool-only extras **beyond a tool's host-native rule surface** (e.g. Antigravity's retained `.agent/rules/` per FR3)"; add an explicit note to FR10 that it **intentionally** (a) removes the `aid update [<tool>...]` positional and (b) broadens `--dry-run` to the main update path — deliberate behavior changes flagged for feature-003 / aid-specify.

_MINOR (row 6): AC3 "53+" is disk-accurate; KB test-landscape says 49 → KB staleness, routed to /aid-discover (OOS, not a REQUIREMENTS defect). OOS (route to /aid-discover): KB suite count 49 vs disk 53._

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
