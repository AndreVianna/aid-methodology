# Work State — work-001-cli-install-scope

> **Status:** Planning complete (3 deliveries, PLAN A+)
> **Phase:** Plan
> **Minimum Grade:** A (resolved via read-setting)
> **Started:** 2026-06-15
> **User Approved:** yes

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy.

## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Interview
- **Active Skill:** aid-interview
- **Updated:** 2026-06-15T16:36:01Z
- **Pause Reason:** —
- **Block Reason:** —
- **Block Artifact:** —

## Triage

- **Path:** full
- **Work Type:** refactor
- **Sub-path:** —
- **Sub-path (auto):** —
- **Decision rationale:** Multi-component refactor of the install/state model (scope detection, code/state home split, per-repo stamp, migration retirement, two-tier registry, installer provisioning, PowerShell parity, tests) — no single recipe fits; routed full per the conservative rule.
- **Override:** no
- **Recipe:** none

## Escalation Carry

> Not applicable — work started directly on the full path.

## Interview Status

**Status:** Approved · **Grade:** A+ (reviewer cycle 2; 0 Pending/Recurred)

> Requirements were seeded from the pre-existing, user-approved design note
> `.aid/design/cli-install-scope-and-migration.md` (settled 2026-06-15) rather than
> gathered via a fresh conversational interview — the stakeholder intent was already
> captured and approved there. Sections below map to that note's §1–§7.

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-06-15 |
| 2 | Problem Statement | Complete | 2026-06-15 |
| 3 | Users & Stakeholders | Complete | 2026-06-15 |
| 4 | Scope | Complete | 2026-06-15 |
| 5 | Functional Requirements | Complete | 2026-06-15 |
| 6 | Non-Functional Requirements | Complete | 2026-06-15 |
| 7 | Constraints | Complete | 2026-06-15 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-15 |
| 9 | Acceptance Criteria | Complete | 2026-06-15 |
| 10 | Priority | Complete | 2026-06-15 |

## Features Status

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 1 | feature-001-runtime-scope-and-home-split | Ready | A+ | 0 | FR1/FR2/FR8/FR10 — root-cause foundation (Priority 1); spec C+→A+; +seam: global AID_STATE_HOME = ${AID_SHARED_STATE_HOME:-/var/lib/aid} (re-verified A+) |
| 2 | feature-002-global-state-provisioning | Ready | A+ | 0 | FR7 — /var/lib/aid (Priority 1); spec D→A+→re-spec→A+ (HYBRID: install-time primary + non-prompting runtime fallback; AID_SHARED_STATE_HOME seam unified runtime+install+test) |
| 3 | feature-003-per-repo-format-stamp | Ready | A+ | 0 | FR3 — fail-safe stamp (Priority 2); spec C+→A+ (replicate strip logic, not reuse closure) |
| 4 | feature-004-two-tier-registry-and-dispatch | Ready | A+ | 0 | FR4/FR5/FR6 — registry, cwd dispatch, migration (Priority 2); spec C→A+ (ps1 parity symbol fixes) |
| 5 | feature-005-bootstrap-and-test-migration | Ready | A+ | 0 | FR9 + test-suite migration — rollout (Priority 3); spec B→A+ (test-file citation fixes) |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Planned | — | Root-cause fix: feature-001 (scope + CODE/STATE split, marker/scan removal) + feature-002 (/var/lib/aid provisioning) + feature-003 (stamp gate = REPLACEMENT trigger). §10 P1 + 003 pulled in for the trigger coupling. Standalone MVP. |
| delivery-002 | Planned | — | Coherent discovery: feature-004 (two-tier registry union + cwd A/B/C dispatch + update-self registry-migration, replacing the d001 no-op stub). §10 P2. Depends on d001. Standalone MVP. |
| delivery-003 | Planned | — | Rollout: feature-005 (v1.0/v1.1 bootstrap stamp+register on visit, no scan; + canonical test-suite migration to CODE/STATE split). §10 P3. Depends on d001+d002. Standalone MVP. |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Cross-phase Q&A (Pending)

> Raised by /aid-interview cross-reference (State 6). Low-impact pre-specify design
> details with suggested answers; to be formally resolved during /aid-specify.

### Q1

- **Category:** Architecture
- **Impact:** Low
- **Status:** Pending
- **Context:** bin/aid:46 falls back to `${HOME}/.aid` when `BASH_SOURCE` can't resolve. After the CODE/STATE split (feature-001), that fallback must become a CODE-home fallback; behavior when code-home self-location fails (piped/sourced invocation) is unspecified. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Code home is mandatory to operate (it locates `lib/`); if self-location fails, error out clearly rather than silently falling back to a state dir. Resolve in /aid-specify feature-001.

### Q2

- **Category:** Architecture
- **Impact:** Low
- **Status:** Pending
- **Context:** With `_aid_check_migrate_sentinel` + the `$HOME` scan removed (feature-001/FR8), migration relies entirely on the per-repo stamp gate (feature-003) firing on every repo command. Confirm no first-run/version-change trigger is expected beyond the per-command stamp check. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Correct — the per-command stamp check (feature-003) is the sole trigger; there is intentionally no machine-level first-run trigger. Document this explicitly in /aid-specify feature-003.

### Q3

- **Category:** Architecture
- **Impact:** Low
- **Status:** Pending
- **Context:** Features 003/005 introduce `AID_SUPPORTED_FORMAT` but don't say whether it's defined once in a shared spot or duplicated in `bin/aid` + `bin/aid.ps1`; the lockstep-manifest constraint suggests it needs an explicit parity home. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Define `AID_SUPPORTED_FORMAT` once per language entrypoint (bash `bin/aid`, PowerShell `bin/aid.ps1`) as a near-top constant, with a parity assertion in the canonical suite so the two never drift. Resolve in /aid-specify feature-003.

## Delivery Gates

> _none yet_

## Quick Check Findings

> _none yet_

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-15 | Work created | — | Scaffold by aid-interview (dogfood) |
| 2026-06-15 | TRIAGE → full | — | Multi-component refactor; no single recipe |
| 2026-06-15 | Requirements seeded | — | From approved design note cli-install-scope-and-migration.md |
| 2026-06-15 | Requirements graded (cycle 1) | C | aid-reviewer: 2 MEDIUM (FR9/FR10 no AC), 1 LOW, 1 MINOR |
| 2026-06-15 | Requirements graded (cycle 2) | A+ | All 4 findings Fixed; 0 Pending/Recurred |
| 2026-06-15 | Requirements approved | A+ | User approved at COMPLETION gate |
| 2026-06-15 | Decision: PR #78 dependency | — | Gate on PR #78 merging to master first; decomposition treats _aid_priv_run as given |
| 2026-06-15 | Decision: KB hydration | — | Deferred to /aid-housekeep (avoid canonical INDEX/render-drift CI churn mid-pipeline) |
| 2026-06-15 | Feature decomposition | — | 5 features created (Scaffolded); FR1–FR10 fully covered, no orphans; PR #78 treated as given |
| 2026-06-15 | Cross-reference graded (cycle 1) | A | aid-reviewer: 1 MINOR (feature-001 undeclared AC6 ref), 3 pre-specify Q&A |
| 2026-06-15 | Cross-reference graded (cycle 2) | A+ | MINOR Fixed (AC6/AC8 declared); 0 Pending/Recurred |
| 2026-06-15 | Interview DONE | A+ | Requirements + decomposition validated; 3 Cross-phase Q&A carried to /aid-specify |
| 2026-06-15 | Specify all 5 features (cycle 1) | C+/D/C+/C/B | aid-architect authored tech specs; aid-reviewer found real impl-blocking issues per feature |
| 2026-06-15 | Specify all 5 features (cycle 2) | A+ ×5 | All findings Fixed; feature-002 re-anchored to runtime-lazy provisioning (validated reachable) |
| 2026-06-15 | Open decision raised | — | feature-002: install-time vs runtime/lazy provisioning of /var/lib/aid (fixer chose runtime; pending user confirm). Windows shared-state = %ProgramData%\aid (design Decision-D addendum) |
| 2026-06-15 | Decision RESOLVED | — | Re-analysis (aid-researcher) confirmed runtime/lazy-primary wrong (fails AC1, sudo-prompts in aid add, inverts mlocate). User confirmed HYBRID: install-time primary + non-prompting runtime fallback. Design note Decision-D addendum updated. feature-002 re-spec |
| 2026-06-15 | feature-002 re-spec graded | D→D→A+ | Hybrid re-spec; reviewer caught dead curl guard + spec/design contradiction + no test seam; fixed (env-preset capture guard, AID_SHARED_STATE_HOME seam) → A+ |
| 2026-06-15 | Seam unified (feature-001+002) | A+ ×2 | Global AID_STATE_HOME default = ${AID_SHARED_STATE_HOME:-/var/lib/aid} (single source: runtime+install+test); both re-verified A+ |
| 2026-06-15 | Plan created | — | 3 deliveries (d001 root-cause = f001+f002+f003; d002 = f004; d003 = f005); execution graph + PR #78 prerequisite |
| 2026-06-15 | Plan graded (cycle 1) | C+ | aid-reviewer: 1 MEDIUM (test migration deferral breaks green-per-delivery), 1 LOW, 1 MINOR |
| 2026-06-15 | Plan graded (cycle 2) | A+ | Per-delivery test migration (green-per-delivery); staging-coordination note; 0 Pending |
| 2026-06-15 | Plan created — 3 deliveries | — | aid-plan: 5 features → d001 (001+002+003, root-cause + stamp-gate replacement trigger), d002 (004), d003 (005). 001↔003 trigger coupling resolved by grouping 003 into d001. PR #78 hard prerequisite (gated to master first, not a deliverable). |

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

### task-NNN

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
