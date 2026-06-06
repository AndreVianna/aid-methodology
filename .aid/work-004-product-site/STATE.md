# Work State — work-004-product-site

> **Status:** Plan Complete (4 deliveries @ A+ — ready for /aid-detail)
> **Phase:** Plan
> **Minimum Grade:** {resolved at runtime by `bash .claude/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-06-06
> **User Approved:** yes

This is the single state file for **this work** — the full dev lifecycle from req → spec → plan → impl → deploy. One STATE.md per `.aid/work-NNN-{name}/` directory.

## Triage

> Populated by `aid-interview` TRIAGE state for lite-path works. Left empty for full-path works (aid-interview runs the full interview flow instead).

- **Path:** full
- **Decision rationale:** description (build a multi-page GitHub Pages product website for AID) → new-feature, multi-target, no confident lite-recipe match → full

## Interview Status

**Status:** Approved · **Grade:** A+ (cross-reference, 2026-06-06)

> **Review History:**
> - 2026-06-06 — all 10 sections Complete; presented summary; **user approved** requirements.
> - 2026-06-06 — CROSS-REFERENCE (aid-reviewer): initial **C+** (1 MEDIUM + 3 LOW + 2 MINOR), feature coverage clean. All 6 findings resolved (user-approved resolutions + obvious corrections); re-grade **A+**.

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-06-06 |
| 2 | Problem Statement | Complete | 2026-06-06 |
| 3 | Users & Stakeholders | Complete | 2026-06-06 |
| 4 | Scope | Complete | 2026-06-06 |
| 5 | Functional Requirements | Complete | 2026-06-06 |
| 6 | Non-Functional Requirements | Complete | 2026-06-06 |
| 7 | Constraints | Complete | 2026-06-06 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-06 |
| 9 | Acceptance Criteria | Complete | 2026-06-06 |
| 10 | Priority | Complete | 2026-06-06 |

## Features Status

> One row per feature. Tracks /aid-specify progress per feature.

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 1 | feature-001-site-foundation | Ready | A+ | 0 | FR1,FR2,FR13 · Must · spec'd (Astro+Starlight `site/`, casulo theme, Pagefind, astro-mermaid) |
| 2 | feature-002-build-and-deploy | Ready | A+ | 0 | FR12 · Must · spec'd (docs.yml workflow, Pages+CNAME, release-data contract `getAidVersion`/`getLatestRelease`/`getAllReleases`) |
| 3 | feature-003-home-and-get-started | Ready | A+ | 0 | FR3,FR4 · Must · spec'd (splash home, get-started autogenerate, InstallCommand/VersionBadge) |
| 4 | feature-004-installation-guide | Ready | A+ | 0 | FR5 · Must · spec'd (installation.mdx, per-OS+per-tool tabs, 5 channels incl. irm) |
| 5 | feature-005-content-migration | Ready | A+ | 0 | FR11 · Must · spec'd (sync-docs.mjs, committed-generated + CI drift-check, docs/ single source) |
| 6 | feature-006-concepts-and-reference | Ready | A+ | 0 | FR8,FR9 · Should · spec'd (concepts arrange + reference autogenerate; gen-reference.mjs for skills/agents/KB/settings) |
| 7 | feature-007-pipeline-and-maintainer-guides | Ready | A+ | 0 | FR6,FR7 · Could · spec'd (pipeline.mdx v3.2 phase→skill; maintainer.mdx cut-a-release + regenerate-trees) |
| 8 | feature-008-version-injection | Ready | A+ | 0 | FR15 · Must · spec'd (imports getAidVersion; `<InstallCommand>`/`<VersionBadge>`) |
| 9 | feature-009-releases-and-banner | Ready | A+ | 0 | FR10,FR16 · Should/Could · spec'd (changelog.astro from getAllReleases, Banner override, sanitized notes) |
| 10 | feature-010-feedback-and-issues | Ready | A+ | 0 | FR14 · Should · spec'd (.github/ISSUE_TEMPLATE/feedback.yml form w/ field-id prefill; Footer override "Report an issue"; concepts/feedback) |

## Plan / Deliveries

> One row per delivery from PLAN.md. Tracks /aid-plan + /aid-detail completion.

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Planned | — | Live branded site shell on domain · features 001,002 · Must · depends: — |
| delivery-002 | Planned | — | Version-bound front door (home, get-started, install) · features 008,003,004 · Must · depends: d-001 |
| delivery-003 | Planned | — | Knowledge surfaces (migration, concepts, reference, releases+banner, feedback) · features 005,006,009,010 · Must(005)+Should · depends: d-001 |
| delivery-004 | Planned | — | Pipeline & maintainer guides · feature 007 · Could · depends: d-001 |

## Tasks Status

> One row per task from PLAN.md execution graph. Tracks /aid-execute progress per task.

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Deploy Status

> One row per delivery from /aid-deploy. Tracks deploy lifecycle.

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Cross-phase Q&A (Pending)

> Consolidated open questions across all phases of this work. The entries below were raised
> by the CROSS-REFERENCE pass and are all **Answered** (no Pending items remain).

### Q1

- **Category:** Requirements / Releases
- **Impact:** Medium
- **Status:** Answered
- **Context:** `CHANGELOG.md` was cited as a release-data source but does not exist in the repo (surfaced by /aid-interview cross-reference).
- **Answer:** Use the **GitHub Releases API only**; drop all `CHANGELOG.md` references.
- **Applied to:** REQUIREMENTS.md §4/§5(FR10)/§8/§9(AC9); feature-009 SPEC.

### Q2

- **Category:** Requirements / Reference
- **Impact:** Low
- **Status:** Answered
- **Context:** FR9 "settings keys" Reference page had no source doc.
- **Answer:** Treat as **net-new content generated from `.aid/settings.yml`**.
- **Applied to:** REQUIREMENTS.md §5(FR9); feature-006 SPEC.

### Q3

- **Category:** Documentation accuracy
- **Impact:** Low
- **Status:** Answered
- **Context:** Install tabs omitted Antigravity (the 5th shipped profile).
- **Answer:** Include all five profiles (Claude Code / Codex / Cursor / Copilot CLI / Antigravity).
- **Applied to:** REQUIREMENTS.md §5(FR5)/§9(AC7); feature-004 SPEC.

### Q4

- **Category:** Documentation accuracy
- **Impact:** Low
- **Status:** Answered
- **Context:** Pipeline flow framed deploy/monitor as numbered phases and omitted aid-config, vs KB methodology v3.2.
- **Answer:** Reframe as **aid-config + 6 numbered phases (Discover→Execute), deploy/monitor as optional Deliver skills**.
- **Applied to:** REQUIREMENTS.md §5(FR6); feature-007 SPEC.

### Q5

- **Category:** Documentation accuracy (MINOR)
- **Impact:** Low
- **Status:** Answered
- **Context:** "regenerate trees/profiles" had no single source doc; "offline tarball" singular vs multi-asset reality.
- **Answer:** Soften "regenerate trees/profiles" to "the canonical render/generate workflow"; use "offline bundle asset(s)".
- **Applied to:** REQUIREMENTS.md §5(FR7)/§9(AC7); feature-007 SPEC; feature-009 SPEC.

## Lifecycle History

> One row per phase transition or gate approval. Append-only audit trail.

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-06 | Work created | — | Initial scaffold by /aid-interview (FIRST-RUN) |
| 2026-06-06 | TRIAGE → full path | — | new-feature, multi-target, no lite-recipe match |
| 2026-06-06 | Interview approved | — | All 10 sections complete; user-approved; key decisions: Astro Starlight, aid.casuloailabs.com, casulo brand |
| 2026-06-06 | Scope addition | — | User added FR14 (feedback→prefilled GitHub issue), FR15 (always-current version/install), FR16 (release banner), FR10 bound to release event |
| 2026-06-06 | Feature Decomposition | — | aid-architect; 10 features created (feature-008 split into version-injection + releases-and-banner; feedback → feature-010); user-approved cut |
| 2026-06-06 | Cross-Reference | A+ | aid-reviewer; initial C+ (1 MEDIUM + 3 LOW + 2 MINOR), coverage clean; all 6 resolved; re-grade A+. Interview phase complete. |
| 2026-06-06 | Specify (all 10 features) | A+ | /aid-specify run across all features with an A+ (zero-finding) gate each; aid-architect authored, aid-reviewer gated, fix-loops to A+; cross-feature contracts reconciled (release-data accessor, sidebar, content-migration, irm channel, issue-form prefill). All 10 specs Ready @ A+. Ready for /aid-plan. |
| 2026-06-06 | Plan | A+ | /aid-plan; aid-architect sequenced 10 features into 4 dependency-ordered standalone deliveries; aid-reviewer gated C+→A+ (1 MEDIUM priority-label fixed). All features assigned, none deferred; 3 cross-cutting risks. Ready for /aid-detail. |
