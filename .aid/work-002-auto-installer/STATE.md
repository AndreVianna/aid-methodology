# Work State — work-002-auto-installer

> **Status:** Detailing Complete — ready for /aid-execute
> **Phase:** Detail
> **Minimum Grade:** A
> **Started:** 2026-06-04
> **User Approved:** yes (requirements approved; specs/plan/tasks all A-gated)

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy. One STATE.md per `.aid/work-NNN-{name}/` directory.

## Triage

- **Path:** escalated
- **Decision rationale:** description = "find a better way to deploy AID methodology into an adopter repo; research/brainstorm then implement" → inferred new-feature; no matching recipe; user confirmed lite/LITE-FEATURE → escalated to full — task-001 research revealed the chosen direction spans four distribution channels (M2 tarball+bootstrap, M3a npm CLI, M3b PyPI CLI) plus M7 CI release automation; multiple features needing full REQUIREMENTS, feature decomposition, and a sequenced delivery plan — exceeds a single bounded lite IMPLEMENT unit.

## Escalation Carry

> Written by lite→full escalation. Full-path interview reads this section to seed
> REQUIREMENTS.md without re-asking questions already answered.

- **Escalated from:** LITE-DONE (Sub-path: LITE-FEATURE) — escalation triggered during /aid-execute task-001 after research re-run
- **Escalated at:** 2026-06-04T00:00:00Z
- **Escalation rationale:** Research (task-001 v2) established the target architecture as M2 + M3a + M3b + M7 (four install surfaces + CI release engine). This is multi-feature work requiring the full pipeline.

### Captured Slot Values

- **feature-title:** One-command AID installer for adopter repos
- **goal:** Replace "clone the whole repo + run setup.sh/setup.ps1" with a frictionless one-command install/update/uninstall that fetches only the needed rendered profile tree, auto-detects the host tool, supports online and offline, and pins versions.
- **scope:** Research-then-implement a deployment mechanism; build it with host-tool detect+override, version pinning/update, uninstall, online+offline modes; docs. (Now expanded by research to M2+M3a+M3b+M7.)
- **ac-1:** Given a developer in a target repo with no prior AID setup, when they run the one-command installer (auto-detect or --tool), then the correct rendered profile tree is installed OR updated at a pinned version without cloning the full repo.
- **ac-additional:** scored research comparison; clean uninstall; host-tool auto-detect+override; cross-platform (bash+PowerShell); minimal deps (best-effort, weighted preference — NOT a hard constraint); version recorded for reproducible updates; online AND offline installer modes.

### Decision (post-research target)

- **Adopted mechanisms:** M2 (versioned GitHub Release tarball + `install.sh`/`install.ps1` bootstrap — zero-dependency fallback, offline-capable) · M3a (published CLI via npm/npx) · M3b (published CLI via PyPI/pipx) · M7 (CI-automated GitHub Release that builds tarballs AND publishes npm + PyPI from one tag).
- **Key architecture constraint for SPECs:** four install surfaces must NOT duplicate install logic four ways — settle a single canonical installer with M3a/M3b as thin wrappers that download the shared release tarball and delegate; M7 publishes all channels from one tag. Resolve version sync across git tag / VERSION file / package.json / pyproject.toml.
- **Reframing locked in:** current absence of a release pipeline / registry presence is the status quo this work changes (NOT a constraint); minimal-deps is a weighted preference, not a gate.

### Artifacts at Escalation

- **Research:** `.aid/work-002-auto-installer/research/deployment-mechanism-comparison.md` (v2, unbiased, 7 mechanisms, 3-scenario sensitivity) + `…v1-superseded.md` — the load-bearing input for feature decomposition.
- **SPEC.md (lite):** preserved as `SPEC.lite-superseded.md` — contains Goal, Context (scope in/out), 8 Acceptance Criteria; seeds REQUIREMENTS §§ Objective, Scope, Functional Requirements, Acceptance Criteria.
- **tasks/:** 4 lite task files present (task-001 RESEARCH Done; 002/003/004 superseded by full feature decomposition) — task-001's output carries forward.

## Interview Status

**Status:** Approved · **Grade:** N/A (full-path interview) · **Cross-Reference Grade:** A+

> **Review History:**
> - 2026-06-04 — Requirements approved by user (10/10 sections Complete). Escalated from lite; seeded from task-001 research + lite SPEC, then completed (§§3,7,8,10) and confirmed (§§1,2,4,5,6,9).
> - 2026-06-04 — Feature Decomposition: 6 features created (5 + invariant-agents-md from cross-ref).
> - 2026-06-04 — Cross-Reference: initial Grade D (3 HIGH on multi-tool AGENTS.md accuracy); 7 findings Fixed, 2 routed to /aid-specify; re-graded **A+**. FR11 (protect-on-diff) + FR12 (invariant AGENTS.md) added; Q1/Q2 answered.

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-06-04 |
| 2 | Problem Statement | Complete | 2026-06-04 |
| 3 | Users & Stakeholders | Complete | 2026-06-04 |
| 4 | Scope | Complete | 2026-06-04 |
| 5 | Functional Requirements | Complete | 2026-06-04 |
| 6 | Non-Functional Requirements | Complete | 2026-06-04 |
| 7 | Constraints | Complete | 2026-06-04 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-04 |
| 9 | Acceptance Criteria | Complete | 2026-06-04 |
| 10 | Priority | Complete | 2026-06-04 |

## Features Status

> One row per feature. Tracks /aid-specify progress per feature.

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 001 | shared-install-core-and-bootstrap (M2) | Ready | A+ | 0 | Foundation; removes setup.sh/ps1; FR1-5,9. Authoritative interface (CLI/manifest/exit codes/delegation). |
| 002 | release-packaging-and-checksums | Ready | A+ | 0 | Artifact contract (tarballs + SHA256SUMS); FR1/5. Manifest not shipped (001 self-computes). |
| 003 | npm-installer-cli (M3a) | Ready | A+ | 0 | `@aid/installer`; FR6,9. Vendor-and-spawn over feature-001 core. |
| 004 | pypi-installer-cli (M3b) | Ready | A+ | 0 | `aid-installer` (PyPI); FR7,9. CasuloAI Labs org registration = external blocker. |
| 005 | ci-release-automation-and-version-sync (M7) | Ready | A+ | 0 | FR8,10; tag-triggered, self-gated, provenance + Trusted Publishing. |
| 006 | invariant-agents-md | Ready | A | 0 | FR12; direct edit of 4 hand-maintained AGENTS.md line 16 + CI invariance guard; Should |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Done — live-verified Linux(zsh)+Windows(pwsh 7.6.2), CI-green both OS, v0.7.5 | 001–010 + 020–030 | Persistent `aid` CLI; foundation installer; closed by user after cross-platform live verification |
| delivery-002 | Detailed (A+) | 011–012 (2) | npm channel; depends on d-001; Must |
| delivery-003 | Detailed (A+) | 013–015 (3) | PyPI channel; depends on d-001; CasuloAI org blocker; Must |
| delivery-004 | Detailed (A+) | 016–017 (2) | CI release automation; depends on d-001/002/003; Should |
| delivery-005 | Detailed (A+) | 018–019 (2) | Invariant AGENTS.md; independent; sequence early; Should |

## Tasks Status

> 19 tasks from /aid-detail (A+ per-delivery gate). Wave = per-delivery wave. (Prior lite-path
> RESEARCH task superseded by full pipeline; its output preserved in research/.)

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | Release-artifact contract & `release.sh` packaging core | IMPLEMENT | d1·W1 | Done | — | — | delivery-001; deps — |
| 002 | `release.sh` packaging test suite | TEST | d1·W2 | Done | — | — | delivery-001; deps 001 |
| 003 | Bash install core + `install.sh` bootstrap | IMPLEMENT | d1·W2 | Done | — | — | delivery-001; deps 001 |
| 004 | Bash installer test suite (`test-install.sh`) | TEST | d1·W3 | Done | — | — | delivery-001; deps 003 |
| 005 | PowerShell install core + `install.ps1` bootstrap | IMPLEMENT | d1·W2 | Done | — | — | delivery-001; deps 001 |
| 006 | PowerShell installer test suite (`test-install-ps1.sh`) | TEST | d1·W3 | Done | — | — | delivery-001; deps 005 |
| 007 | Cross-platform install parity verification (e2e) | TEST | d1·W4 | Done | — | — | delivery-001; deps 001,004,006 |
| 008 | Remove `setup.sh`/`setup.ps1` + update all references | REFACTOR | d1·W4 | Done | — | — | delivery-001; deps 004,006 |
| 009 | Install/update/uninstall flow docs + first-release runbook | DOCUMENT | d1·W5 | Done | — | — | delivery-001; deps 006,008 |
| 010 | First manual release dry-run + d-001 e2e validation | TEST | d1·W5 | Done | — | — | delivery-001; deps 001,007 |
| 011 | npm wrapper `@aid/installer` (vendor-and-spawn) | IMPLEMENT | d2·W1 | Pending | — | — | delivery-002; deps 003,005 |
| 012 | npm wrapper test suite + packaging smoke | TEST | d2·W2 | Pending | — | — | delivery-002; deps 011 |
| 013 | PyPI wrapper `aid-installer` (vendor-and-spawn) | IMPLEMENT | d3·W1 | Pending | — | — | delivery-003; deps 003,005 |
| 014 | PyPI wrapper test suite + vendored-payload parity | TEST | d3·W2 | Pending | — | — | delivery-003; deps 013 |
| 015 | PyPI org registration prereq + publish runbook | DOCUMENT | d3·W3 | Pending | — | — | delivery-003; deps 014; external blocker |
| 016 | One-tag release workflow `release.yml` + version-sync gate | IMPLEMENT | d4·W1 | Pending | — | — | delivery-004; deps 001,011,013 |
| 017 | Version-sync unit test + workflow validation | TEST | d4·W2 | Pending | — | — | delivery-004; deps 016 |
| 018 | Normalize root `AGENTS.md` byte-invariant ×4 | IMPLEMENT | d5·W1 | Pending | — | — | delivery-005; deps —; independent/early |
| 019 | CI invariance guard for root `AGENTS.md` | TEST | d5·W2 | Pending | — | — | delivery-005; deps 018 |
| 020 | `aid` dispatcher (Bash) — subcommand parse + map to engine modes | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; net-new; deps 003 |
| 021 | Core read additions (Bash) — `manifest_list_tools` + `aid_status` (exit 7) | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; net-new; deps 003 |
| 022 | Global layout + bootstrap reshape (Bash) — arg-free `~/.aid` install; convenience chain; idempotent | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; amends 003; deps 020,021 |
| 023 | PATH wiring + self-uninstall (Unix) — idempotent marked-block; `--no-path` | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; net-new; deps 022 |
| 024 | `aid` dispatcher (PowerShell) — `aid.cmd`+`aid.ps1`, subcommand parity | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; amends 005; deps 020,005 |
| 025 | Core read additions (PowerShell) — `Get-ManifestToolList` + `Get-AidStatus` (parity w/021) | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; net-new; deps 005,021 |
| 026 | Global layout + bootstrap + USER-PATH wiring + self-uninstall (Windows) | IMPLEMENT | d1·W6 | Done | — | — | delivery-001 CLI; amends 005; deps 024,025 |
| 027 | `aid` CLI test suite (Bash) — subcommands, status/exit 7, convenience chain, PATH idempotency | TEST | d1·W7 | Done | — | — | delivery-001 CLI; net-new; deps 020–023; run at end |
| 028 | `aid` CLI test suite (PowerShell) — parity w/027; USER-PATH dedup; cmd/ps1 resolution | TEST | d1·W7 | Done | — | — | delivery-001 CLI; net-new; deps 024–027; run at end |
| 029 | Cross-platform `aid` parity e2e | TEST | d1·W8 | Done | — | — | delivery-001 CLI; net-new; deps 027,028; run at end |
| 030 | Docs — `aid` CLI usage + 003/004 ripple note; update `docs/install.md` | DOCUMENT | d1·W8 | Done | — | — | delivery-001 CLI; amends 009; deps 023,026 |

> **Amended (reopened) delivery-001 tasks:** 003 → 022 (Bash bootstrap gains CLI/global-install scope), 005 → 024/026 (PS bootstrap), 007 → 029 (e2e), 009 → 030 (docs). These were "Done — gate A"; reopening is the consequence of the user-approved CLI direction folded into delivery-001. Tests (027–029) run at the END per the user's testing cadence. Final delivery-gate re-run before push.

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Quick Check Findings

### task-001

- **Reviewer Tier:** Small
- **Findings (v2 re-run):** none (no [CRITICAL]/[HIGH]; deferred MEDIUM — sensitivity-table `≈/~` totals are loose approximations of exact scores, rankings/winner correct)

## Delivery Gates

### delivery-001 (LITE-REVIEW pre-execution gate)

- **Reviewer Tier:** Small
- **Grade:** A+ (first pass C; fixed 5, accepted 1; re-graded A+)
- **Issue List:** none open (5 Fixed, 1 Accepted — task-002 five-deliverable bundle, by-design for LITE-FEATURE)
- **Ledger:** `.aid/.temp/review-pending/interview-work-002-auto-installer-lite.md`
- **Timestamp:** 2026-06-04


### delivery-001 (EXECUTE delivery-gate)

- **Reviewer Tier:** Large
- **Complexity Score:** 26
- **Grade:** A
- **Cycles:** 4 (E → D → D+ → A)
- **Timestamp:** 2026-06-04T00:00:00Z
- **Issue List:** 16 findings Fixed across 4 cycles (2 CRITICAL broken one-liners, 1 CRITICAL PS multi-tool crash fixed-on-spot, 2 HIGH manifest-data-loss + fail-open lib verification, plus MEDIUM/LOW); 2 open MINOR (SHA256SUMS-matcher regex parity nit (fail-closed-safe); IN10b test-resource flake under parallel HTTP-server tests).

## Cross-phase Q&A (Pending)

> Consolidated open questions across all phases of this work.

### Q1

- **Category:** Architecture / Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-interview (cross-reference). The requirements model install as single-tool auto-detect, but the existing `setup.sh` is a **multi-select** menu that installs several host tools into one repo, sharing one root `AGENTS.md` (last-writer-wins survivor; `setup.sh:137-165`). Four tools (codex, cursor, copilot-cli, antigravity) write the shared `AGENTS.md`; claude-code uses `CLAUDE.md`. Since this work **replaces** `setup.sh`, the new installer must decide: (a) does it support installing multiple tools into one repo, and (b) how do host-detect (FR2), the install manifest, and uninstall (FR4) handle a **shared root `AGENTS.md` owned by 2+ installed tools** (uninstalling one tool must not orphan/delete a root file another installed tool still needs)?
- **Suggested:** Support multi-tool (parity with setup.sh, since we're replacing it): per-tool install manifests + a ref-count / ownership record for shared root files (`AGENTS.md`), so uninstall removes a shared root file only when the last owning tool is removed; keep the last-writer-wins survivor rule for `AGENTS.md` content on multi-tool install.
- **Answer:** Per-tool, **argument-driven** install (`--tool`, optional comma-list; auto-detect default) replaces the interactive multi-select menu — friendlier + scriptable. Tool dirs are isolated. For the shared root `AGENTS.md`: adopt **protect-on-diff** (FR11) — never silently overwrite a root agent file the installer didn't write; warn + write `*.aid-new`; `--force` overrides. Uninstall removes a root agent file only if it still checksum-matches what this tool wrote. **Plus** make the four profiles' `AGENTS.md` byte-**invariant** (FR12, canonical normalization) so tool-vs-tool collisions vanish and the warning only fires for the user's own file.
- **Applied to:** REQUIREMENTS.md §4, §5 (FR2 reframed, FR11 + FR12 added), §9; feature-001 SPEC (per-tool + protect-on-diff ACs); new feature-006 (invariant AGENTS.md).

### Q2

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Answered
- **Context:** Surfaced by /aid-interview (cross-reference). Beyond the profile dirs, the installer copies **root agent files** (`CLAUDE.md` for claude-code, shared `AGENTS.md` for the other four). The uninstall manifest (FR4) must explicitly scope these root files — especially the shared `AGENTS.md` (see Q1) — and decide whether root `README.md`/other root files are in or out of installer scope.
- **Suggested:** Manifest tracks every installed path including root agent files; shared `AGENTS.md` handled per Q1 ref-count; do not touch files the installer didn't create.
- **Answer:** Manifest tracks every installed path incl. the root agent file (`CLAUDE.md`/`AGENTS.md`); root agent files handled by protect-on-diff + checksum-safe uninstall (Q1/FR11). `profiles/*/README.md` are **NOT installed** (repo-presentation only); the installer never touches files it didn't create.
- **Applied to:** REQUIREMENTS.md §4 Out-of-Scope (README.md not installed), §5 FR11; feature-001 SPEC.

## Lifecycle History

> One row per phase transition or gate approval. Append-only audit trail.

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-04 | Work created | — | Initial scaffold by /aid-interview |
| 2026-06-04 | Interview started | — | FIRST-RUN → TRIAGE |
| 2026-06-04 | TRIAGE complete | — | Path: lite · new-feature · LITE-FEATURE · no recipe → CONDENSED-INTAKE |
| 2026-06-04 | CONDENSED-INTAKE complete — SPEC.md written | /aid-interview CONDENSED-INTAKE |
| 2026-06-04 | TASK-BREAKDOWN complete — 4 tasks written | /aid-interview TASK-BREAKDOWN |
| 2026-06-04 | LITE-REVIEW complete — Grade: A+ | /aid-interview LITE-REVIEW |
| 2026-06-04 | LITE-DONE — lite path complete; 4 tasks ready | /aid-interview LITE-DONE |
| 2026-06-04 | task-001 [RESEARCH] complete — quick-check clean; rec: M2 (GitHub Release tarball) | /aid-execute task-001 |
| 2026-06-04 | task-001 RE-RUN triggered — v1 premise biased (current-state + minimal-deps as hard constraints); SPEC checkpoint de-biased; re-research with weighted analysis | /aid-execute task-001 |
| 2026-06-04 | task-001 [RESEARCH] v2 complete — quick-check clean; M2 wins all 3 weighting scenarios; lite holds | /aid-execute task-001 |
| 2026-06-04 | Escalated from LITE-DONE to full path — target expanded to M2+M3a+M3b+M7 (4 channels + CI release); multi-feature, needs full pipeline | /aid-interview escalation |
| 2026-06-04 | CONTINUE complete — all 10 sections done; latest master merged (ff) into worktree branch; VERSION → 0.7.0 | /aid-interview CONTINUE |
| 2026-06-04 | COMPLETION — requirements Approved by user | /aid-interview COMPLETION |
| 2026-06-04 | FEATURE-DECOMPOSITION — 5 features created (M2 core+bootstrap, release-packaging, npm CLI, PyPI CLI, CI release); placeholder replaced; all FR1-10 mapped | /aid-interview FEATURE-DECOMPOSITION |
| 2026-06-04 | CROSS-REFERENCE — Grade D→A+ after fixes; multi-tool AGENTS.md resolved (per-tool --tool + FR11 protect-on-diff + FR12 invariant); feature-006 added; Q1/Q2 answered | /aid-interview CROSS-REFERENCE |
| 2026-06-04 | SPECIFY — all 6 feature SPECs authored + A-gated (001 A+, 002 A+, 003 A+, 004 A+, 005 A+, 006 A); 2 waves, architect-authored + reviewer-gated, fixes to A | /aid-specify work-002 (all features) |
| 2026-06-04 | PLAN — 5-delivery roadmap (foundation → npm ∥ pypi → CI-release; invariant-AGENTS.md independent/early); Grade A+ | /aid-plan work-002 |
| 2026-06-04 | DETAIL — 19 tasks across 5 deliveries; per-delivery A-gate (initial 001 D / 002 C / 003 C+ / 004 D+ / 005 A+ → fixed → all A+); cross-feature exit-code + package-lock reconciled | /aid-detail work-002 |
