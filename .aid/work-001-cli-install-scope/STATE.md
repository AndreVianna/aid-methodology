# Work State — work-001-cli-install-scope

> **Status:** delivery-002 COMPLETE — 4/4 Done, gate A+, suite 51/51; PR to master open. delivery-003 (feature-005 bootstrap) remains.
> **Phase:** Execute
> **Minimum Grade:** A (resolved via read-setting)
> **Started:** 2026-06-15
> **User Approved:** yes

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy.

## Pipeline Status

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-16T02:00:00Z
- **Pause Reason:** delivery-002 complete (4/4 Done, gate A+, suite 51/51); PR to master open for review/merge. Next: delivery-003 (feature-005 bootstrap runbook + final reconciliation, tasks 014-016) — resume via /aid-execute after delivery-002 merges.
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
| delivery-001 | MERGED (PR #80) | 9/9 Done | Root-cause fix shipped to master 2026-06-16 (merge 5fa59fea). Gate A+; CI green (canary CI-portability fix). |
| delivery-002 | Done (gate A+) | 4/4 Done | feature-004: two-tier registry union + cwd A/B/C dispatch + update-self registry-migration. All 4 tasks Done; delivery gate A+; suite 51/51 (incl. CI layout); PR to master open. |
| delivery-003 | Detailed | 3 (task-014..016) | Rollout: feature-005 (v1.0/v1.1 bootstrap stamp+register on visit, no scan; + canonical test-suite migration to CODE/STATE split). §10 P3. Depends on d001+d002. Standalone MVP. |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| task-001 | CODE/STATE home split + scope + marker/scan/sentinel removal (bash) | IMPLEMENT | d001 w1 | Done | A+ | — | feature-001; bin/aid 2485→2217; all ACs verified; suite red until sibling tasks land (by design, green@delivery) |
| task-002 | CODE/STATE home split (ps1 parity) | IMPLEMENT | d001 w2 | Done | A+ | — | feature-001; ps1 parity twin; PARSE OK, grep-zero, ASCII; no ps1 priv-helper (writability probe) |
| task-003 | /var/lib/aid provisioning helper + install hooks + runtime fallback (bash) | IMPLEMENT | d001 w2 | Done | A+ | — | feature-002; D+→A+ (fixed registry degrade: mktemp-in-nonwritable-dir dropped entry; now preserved in ~/.aid) |
| task-004 | Global provisioning Windows parity (%ProgramData%\aid) (ps1) | IMPLEMENT | d001 w3 | Done | A | — | feature-002; reviewer A — task-003-class mktemp-before-degrade bug NOT present (entry preserved to %LOCALAPPDATA%, no temp leak, no UAC prompt); 1 MINOR cosmetic double-WARN in unregister Accepted (parity-shared with committed bash twin; fix would touch both sides — deferred polish) |
| task-005 | Per-repo format stamp + fail-safe gate (bash) | IMPLEMENT | d001 w2 | Done | A+ | — | feature-003; D+→A+ (fixed bare-aid refuse exit-code: exit 0→exit $?); AID_SUPPORTED_FORMAT=1, _aid_repo_format, _aid_format_gate (refuse>1/warn<1/silent==1), era-a+era-b stamp v1; migrate G4A-02/PAR077-C02 red OOS (by-design, owned by TEST 007/009) |
| task-006 | Per-repo format stamp + fail-safe gate (ps1 parity) | IMPLEMENT | d001 w3 | Done | A+ | — | feature-003; D+→A+ (added missing 4th gate site Invoke-DcStart — dashboard-start was launching on newer-format repos); $AidSupportedFormat, Get-AidRepoFormat, Invoke-AidFormatGate, era-a/era-b stamp; parity 235/0 |
| task-007 | d001 test migration — fixture split + retired marker/scan/sentinel + home-split asserts | TEST | d001 w3 | Done | green | — | feature-001 slice; overshot to whole suite — ALL 50 canonical suites pass (238/0) HOME-pinned; fixed 1 non-hermetic test (TRG-T2-01 AID_HOME leak → seam pin); likely absorbed much of 008/009 |
| task-008 | d001 test migration — /var/lib/aid provisioning asserts (seam) | TEST | d001 w4 | Done | A+ | — | feature-002 slice; NEW test-aid-provisioning.sh (42 asserts, seam-sandboxed, /var/lib never touched); B+→A+ (dropped misleading PRV-N03 + dead stub) |
| task-009 | d001 test migration — stamp + gate asserts (parity constant, refuse/offer/malformed) | TEST | d001 w4 | Done | A+ | — | feature-003 slice; PAR009-V in test-aid-cli-parity.sh (constant-drift, refuse-on-newer byte/mtime identity, malformed→0, bash+ps1); 249/0 |
| task-010 | Two-tier registry union read + write-tier selection (bash) | IMPLEMENT | d002 w1 | Done | A+ | — | feature-004; E→A+ (gate caught CRITICAL: user-tier hardcoded $HOME/.aid ignored AID_HOME override → write-escape + test-registry 68→43; fixed to $AID_STATE_HOME-primary scope-aware tiers); _registry_read_union dedup+prune; run-all 51/51 |
| task-011 | cwd A/B/C dispatch matrix + update-self registry migration swap (bash) | IMPLEMENT | d002 w2 | Done | A+ | — | feature-004; C+→A+ (added bare-aid C-table wiring); B/C matrix per design §4, update-self migrates registry union (no scan, no .migrated). Decision #5 exit-0-on-missing-.aid breaks ~16 old assertions across 6 suites — ALL task-013-owned behavior change (verified no real regression); suite 45/51 until task-013 |
| task-012 | Two-tier registry + dispatch + update-self migration (ps1 parity) | IMPLEMENT | d002 w3 | Done | A+ | — | feature-004; D+→A+ (gate caught HIGH ps1 fn-ordering → register-on-encounter dead for bare-aid/status; + removed Invoke-AidScanAndMigrate for parity). Get-RegistryUnion, tier-aware register (AID_HOME honored), B/C matrix, inlined union migration; full bash↔ps1 parity, no divergence |
| task-013 | d002 test migration — registry union + A/B/C + update-self migration | TEST | d002 w4 | Done | A | — | feature-004 slice; split into 4 parallel per-suite agents (lesson). Migrated decision-#5 dispatch assertions (exit7/6→0+offer; .aid fixtures for landing/notice tests) across cli/ps1/parity/dashboard/npm; NEW REG-V01-07 (union/collapse/degrade/prune/no-scan/migrate-exactly/AID_HOME-redirect) + PAR029-W parity. run-all 51/51 (incl. CI layout). 2 MINOR cosmetic |
| task-014 | v1.0/v1.1 bootstrap runbook (manual, per-repo, no scan) | DOCUMENT | d003 w1 | Pending | — | — | feature-005; procedure, no production code |
| task-015 | Bootstrap assertions — stamp+register on first encounter, no scan (AC9) | TEST | d003 w1 | Pending | — | — | feature-005; new bootstrap tests |
| task-016 | Final full-suite reconciliation green sweep (bash + ps1) | TEST | d003 w2 | Pending | — | — | feature-005; whole-suite closeout audit |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Cross-phase Q&A

> Raised by /aid-interview cross-reference (State 6). Low-impact pre-specify design
> details with suggested answers; to be formally resolved during /aid-specify.

### Q1

- **Category:** Architecture
- **Impact:** Low
- **Status:** Answered
- **Context:** bin/aid:46 falls back to `${HOME}/.aid` when `BASH_SOURCE` can't resolve. After the CODE/STATE split (feature-001), that fallback must become a CODE-home fallback; behavior when code-home self-location fails (piped/sourced invocation) is unspecified. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Code home is mandatory to operate (it locates `lib/`); if self-location fails, error out clearly rather than silently falling back to a state dir. Resolve in /aid-specify feature-001.
- **Answer:** Code home is mandatory; on self-locate failure the CLI errors out (non-zero) rather than falling back to a state dir.
- **Applied to:** feature-001 SPEC Technical Specification (Approach — mandatory-code-home error path, Q1).

### Q2

- **Category:** Architecture
- **Impact:** Low
- **Status:** Answered
- **Context:** With `_aid_check_migrate_sentinel` + the `$HOME` scan removed (feature-001/FR8), migration relies entirely on the per-repo stamp gate (feature-003) firing on every repo command. Confirm no first-run/version-change trigger is expected beyond the per-command stamp check. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Correct — the per-command stamp check (feature-003) is the sole trigger; there is intentionally no machine-level first-run trigger. Document this explicitly in /aid-specify feature-003.
- **Answer:** Confirmed — the per-command stamp gate is the sole migration trigger; no machine-level first-run trigger.
- **Applied to:** feature-003 SPEC Technical Specification (Q2 resolution).

### Q3

- **Category:** Architecture
- **Impact:** Low
- **Status:** Answered
- **Context:** Features 003/005 introduce `AID_SUPPORTED_FORMAT` but don't say whether it's defined once in a shared spot or duplicated in `bin/aid` + `bin/aid.ps1`; the lockstep-manifest constraint suggests it needs an explicit parity home. Surfaced by /aid-interview (cross-reference).
- **Suggested:** Define `AID_SUPPORTED_FORMAT` once per language entrypoint (bash `bin/aid`, PowerShell `bin/aid.ps1`) as a near-top constant, with a parity assertion in the canonical suite so the two never drift. Resolve in /aid-specify feature-003.
- **Answer:** One near-top constant per language entrypoint (bin/aid + bin/aid.ps1) with a canonical-suite parity assertion.
- **Applied to:** feature-003 SPEC (Q3 resolution); task-009 parity-constant assertion.

### Q4

- **Category:** Implementation
- **Impact:** Medium
- **Status:** Open
- **Context:** task-005 REVIEW cycle-1 (feature-003). The format gate is wired into 4 entry points; 3 (`_dc_start`:1039, status:2023, update:2347) propagate the gate's non-zero return via `exit $?`. The bare-`aid` dashboard-landing path does NOT: `_cmd_dashboard` correctly does `_aid_format_gate "." || return $?` (bin/aid:1954), but the dispatch at bin/aid:1972-1973 runs `_cmd_dashboard` then unconditionally `exit 0`, so a refused newer-format repo prints the refuse message but exits 0 (AC3/AC4 require non-zero). The body still short-circuits so no `.aid/` write/operate occurs — fail-safe data protection holds; only the observable exit code is wrong.
- **Suggested:** At bin/aid:1972-1973 propagate the return code, e.g. `_cmd_dashboard || exit $?` then `exit 0` (or `_cmd_dashboard; exit $?`), so bare `aid` exits non-zero on refuse like the other three sites. Verify with the cwd `format_version: 2` E2E (expect rc!=0).
- **Answer:** _pending FIX_
- **Applied to:** _pending_

## Delivery Gates

### delivery-001

- **Reviewer Tier:** Large
- **Grade:** A+
- **Issue List:** none (gate passed clean; 0 deferred [HIGH] from per-task quick checks)
- **Timestamp:** 2026-06-16T02:00:00Z
- **Notes:** Holistic cross-task pass — delivery ACs (AC1/2/3/4/6/7/8/10) verified end-to-end incl. the v1.0→v1.1 root-cause scenario (unprivileged global aid degrades to ~/.aid, no prompt, no re-prompt loop); bash↔ps1 parity (4↔4 gate sites, both stamp constants =1); full canonical suite 51/51 (238/0).

### delivery-002

- **Reviewer Tier:** Large
- **Grade:** A+
- **Issue List:** none (0 deferred [HIGH]; all per-task findings fixed inline — task-010 E→A+, task-011 C+→A+, task-012 D+→A+, task-013 A)
- **Timestamp:** 2026-06-16T06:00:00Z
- **Notes:** Holistic cross-task pass — AC2 (no scan) + AC5 (update-self migrates exactly registered: A+B stamped, C not) verified end-to-end; FR4 two-tier union (dedup/prune/collapse/AID_HOME-honoring), FR5 cwd A/B/C dispatch (decision #5 offer exit 0), FR6 registry migration; full bash↔ps1 parity; suite 51/51 (standard + CI layout). Record-note: SPEC §Affected-components describes user-primary tiers but impl is $AID_STATE_HOME-primary (the AID_HOME-honoring task-010 fix) — AC-conformant SPEC-wording divergence, reconcile in housekeep.

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
| 2026-06-15 | Tasks detailed | — | 16 tasks across 3 deliveries; bash/ps1 split; per-delivery TEST tasks; execution waves |
| 2026-06-15 | Detail graded (cycle 1) | B+ | aid-reviewer: 1 LOW (task-007 missing 005 dep) + 2 MINOR; no blocking issues |
| 2026-06-15 | Detail graded (cycle 2) | A+ | All 3 fixed; 16 tasks exact 6-section format, acyclic DAG, green-per-delivery; 0 Pending |
| 2026-06-15 | DESIGN PIPELINE COMPLETE | A+ | interview→specify→plan→detail all A+. Ready for /aid-execute (gated on PR #78 merge) |
| 2026-06-16 | delivery-001 executed | A+×8/A×1 | 9 tasks: 001/002/003/005/006/007/008/009 A+, 004 A. Gates caught 4 real bugs (registry-drop, swallowed exit-code, missing ps1 gate site, non-hermetic test) — all fixed |
| 2026-06-16 | delivery-001 DELIVERY GATE | A+ | Large-tier holistic pass, 0 findings; v1.0→v1.1 root-cause scenario verified clean; suite 51/51 (238/0); PR to master opened |
| 2026-06-16 | PR #80 CI fix | — | test-aid-migrate.sh ISO-CANARY-01 hardcoded empty REAL_HOME expectation → tripped on the repo's own .aid under CI's /home/runner checkout (local HOME-pin masked it; gate reviewer too). Fixed to before/after snapshot (matches sibling suites). PR #80 CI now GREEN (all 7 checks). |
| 2026-06-16 | delivery-001 MERGED | — | PR #80 merged to master (5fa59fea); root-cause fix shipped |
| 2026-06-16 | delivery-002 executed | A+/A+/A+/A | feature-004 tasks 010(E→A+)/011(C+→A+)/012(D+→A+)/013(A). Gates caught: registry write-escape+25-test regression, bare-aid C-table gap, ps1 fn-ordering register-dead + scan-fn divergence — all fixed |
| 2026-06-16 | delivery-002 DELIVERY GATE | A+ | Large-tier holistic, 0 findings; AC2/AC5 + FR4/5/6 verified; bash↔ps1 parity; suite 51/51 (incl CI layout); PR to master opened |
| 2026-06-15 | Plan created — 3 deliveries | — | aid-plan: 5 features → d001 (001+002+003, root-cause + stamp-gate replacement trigger), d002 (004), d003 (005). 001↔003 trigger coupling resolved by grouping 003 into d001. PR #78 hard prerequisite (gated to master first, not a deliverable). |
| 2026-06-15 | Tasks detailed — 16 tasks across 3 deliveries | — | aid-detail: d001=9 (task-001..009: f001/f002/f003 bash+ps1 IMPLEMENT + 3 green-per-delivery TEST), d002=4 (task-010..013: f004 bash split + ps1 + TEST), d003=3 (task-014 bootstrap runbook DOCUMENT, task-015 bootstrap TEST, task-016 final reconciliation TEST). bash/ps1 split as parity twins; per-delivery TEST tasks keep run-all.sh green at each boundary. Per-delivery execution graph + wave-maps appended to PLAN.md. |

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

### task-NNN

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
