# Work State — work-002-canonical-generator

> **Status:** Deployed
> **Phase:** Deploy (delivery-001 shipped to master via PR #6 on 2026-05-23)
> **Minimum Grade:** A
> **Started:** 2026-05-22
> **User Approved:** yes (Interview · Spec · Plan · Deploy)

This is the single state file for `work-002-canonical-generator` — single canonical source for all install-tree content, with profile-driven generator. **Shipped.** Consolidates what used to be `INTERVIEW-STATE.md` + per-feature `STATE.md` × 1 + per-task `task-NNN-STATE.md` × 27 (across 33 task definitions; 2 had stale STATE, 8 had no STATE file).

## Interview Status

**Status:** Approved · **Grade:** A

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-05-22 |
| 2 | Problem Statement | Complete | 2026-05-22 |
| 3 | Users & Stakeholders | Complete | 2026-05-22 |
| 4 | Scope | Complete | 2026-05-22 |
| 5 | Functional Requirements | Complete | 2026-05-22 |
| 6 | Non-Functional Requirements | Complete | 2026-05-22 |
| 7 | Constraints | Complete | 2026-05-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-05-22 |
| 9 | Acceptance Criteria | Complete | 2026-05-22 |
| 10 | Priority | Complete | 2026-05-22 |

## Features Status

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 001 | `feature-001-profile-driven-generator` | Ready | A+ | 0 open / 5 resolved | Single canonical source + 3 TOML profiles + 8 render/verify Python scripts + emission-manifest JSONL safety boundary. Originally feature-001 in work-001-aid-lite (FR5); moved to work-002 and sequenced first during the fresh-eyes reshape. Resolved OQs: OQ1 (Claude-Code-only maintainer interface — accepted), OQ4 (Cursor beta hooks annotation), OQ5 (canonical/ in install path — out of scope), plus implicit Python-3.11+ tomllib dependency confirmation, plus user-required no-Python-for-end-users constraint. |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Shipped | 33 | Single delivery (user pushed back against the 3-way split proposal during /aid-plan). 9-task critical path; W0 → W1 (16-task parallel) → W2 → W2.5 → W3 (parallel) → W4 (parallel) → W5 → W6 → W7 → W8a (parallel) → W8b. |

## Tasks Status

> 33 tasks across 11 waves (W0 – W8b). All Done with grade A.

| # | Task | Type | Wave | Status | Grade | Notes |
|---|------|------|------|--------|-------|-------|
| 001 | `task-001-fix-h6-codex-installer` | MIGRATE | W0 | Done | A | H6 fix; STATE was stale at 'In Progress' pre-migration |
| 002 | `task-002-smoke-test-h6-fix` | TEST | W0 | Done | A | H6 smoke; STATE was stale at 'In Progress' pre-migration |
| 003 | `task-003-design-emission-manifest-format` | DESIGN | W1 | Done | A | Manifest format design; no STATE file existed (executor didn't create) |
| 004 | `task-004-bootstrap-canonical-agents` | MIGRATE | W1 | Done | A | Canonical agents bootstrap; no STATE file |
| 005 | `task-005-bootstrap-canonical-templates` | MIGRATE | W1 | Done | A | Canonical templates bootstrap; no STATE file |
| 006 | `task-006-bootstrap-skill-aid-deploy` | MIGRATE | W1 | Done | A | aid-deploy SKILL bootstrap; no STATE file |
| 007 | `task-007-bootstrap-skill-aid-monitor` | MIGRATE | W1 | Done | A | aid-monitor SKILL bootstrap; no STATE file |
| 008 | `task-008-bootstrap-skill-aid-init` | MIGRATE | W1 | Done | A | aid-init SKILL bootstrap; no STATE file |
| 009 | `task-009-bootstrap-skill-aid-summarize` | MIGRATE | W1 | Done | A | aid-summarize SKILL bootstrap |
| 010 | `task-010-bootstrap-skill-aid-plan-and-detail` | MIGRATE | W1 | Done | A | aid-plan + aid-detail bundled |
| 011 | `task-011-bootstrap-skill-aid-discover` | MIGRATE | W1 | Done | A | aid-discover SKILL.md bootstrap (split into 011a/b/c for references) |
| 011a | `task-011a-bootstrap-aid-discover-agent-prompts` | MIGRATE | W1 | Done | A | aid-discover references/agent-prompts.md |
| 011b | `task-011b-bootstrap-aid-discover-document-expectations` | MIGRATE | W1 | Done | A | aid-discover references/document-expectations.md |
| 011c | `task-011c-bootstrap-aid-discover-reviewer-prompt` | MIGRATE | W1 | Done | A | aid-discover references/reviewer-prompt.md |
| 012 | `task-012-bootstrap-skill-aid-interview` | MIGRATE | W1 | Done | A | aid-interview SKILL bootstrap |
| 013 | `task-013-bootstrap-skill-aid-specify` | MIGRATE | W1 | Done | A | aid-specify SKILL bootstrap |
| 014 | `task-014-bootstrap-skill-aid-execute` | MIGRATE | W1 | Done | A | aid-execute SKILL bootstrap |
| 015 | `task-015-author-profile-claude-code` | IMPLEMENT | W1 | Done | A | Claude Code profile.toml |
| 016 | `task-016-author-profile-codex` | IMPLEMENT | W1 | Done | A | Codex profile.toml |
| 017 | `task-017-author-profile-cursor` | IMPLEMENT | W1 | Done | A | Cursor profile.toml |
| 018 | `task-018-profile-parser-and-harness` | IMPLEMENT | W2 | Done | A | profile.py + harness.py (tomllib 3.11+) |
| 022 | `task-022-emission-manifest-implementation` | IMPLEMENT | W2.5 | Done | A | EmissionManifest class + JSONL safety boundary (ships BEFORE renderers) |
| 019 | `task-019-agent-renderer` | IMPLEMENT | W3 | Done | A | render_agents.py — markdown for CC/Cursor, TOML for Codex |
| 020 | `task-020-skill-renderer` | IMPLEMENT | W3 | Done | A | render_skills.py — verbatim frontmatter preservation |
| 021 | `task-021-template-renderer` | IMPLEMENT | W3 | Done | A | render_templates.py |
| 023 | `task-023-verify-4a-deterministic-gate` | TEST | W4 | Done | A | verify_deterministic.py — byte-identical re-render + presence audit + frontmatter parse |
| 024 | `task-024-verify-4b-advisory-layer` | TEST | W4 | Done | A | verify_advisory.py — graceful-degraded stub for vendor URL conformance |
| 025 | `task-025-orchestration-skill` | IMPLEMENT | W5 | Done | A | aid-generate/SKILL.md state machine |
| 026 | `task-026-bootstrap-verification` | TEST | W6 | Done | A | Bootstrap diff documented in bootstrap-diff.md |
| 027 | `task-027-commit-generated-install-trees` | MIGRATE | W7 | Done | A | Cutover commit — 311 files emitted live, 3 manifests written |
| 028 | `task-028-replace-contributing-cross-tree-rule` | DOCUMENT | W8a | Done | A | CONTRIBUTING.md updated with canonical-generator workflow |
| 030 | `task-030-final-clean-target-installer-smoke-test` | TEST | W8a | Done | A | Clean-target install smoke test |
| 029 | `task-029-final-roundtrip-via-generator` | TEST | W8b | Done | A | Round-trip verification — AC1/AC2/AC3/AC4/AC5 all live-verified |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| delivery-001 | Deployed | #6 (merged 2026-05-23 into master at `4dddaff`) | yes — KB doc bulk-rewrite PR #6 + canonical restructure PRs #7/#8 | — (no tag created) | Cutover commit `15560ff` (task-027 — 311 files emitted live, 3 emission manifests). End users see no change; maintainer edits are now single-source. |

## Cross-phase Q&A (Pending)

*(none — all questions resolved during /aid-interview, /aid-specify, and /aid-plan)*

## Lifecycle History

| # | Date | Phase Transition / Gate | Grade | Notes |
|---|------|------------------------|-------|-------|
| 1 | 2026-05-22 | /aid-interview complete — Approved | A | Interview happened as part of the fresh-eyes reshape of work-001; FR5 split out to this new work. |
| 2 | 2026-05-22 | /aid-specify feature-001 — Ready | A+ | Spec graded A+ after full review cycle. Data Model, Feature Flow (LOAD → VALIDATE → RENDER → VERIFY → REPORT), Layers, 7-step Migration Plan. |
| 3 | 2026-05-22 | /aid-plan delivery-001 — Approved | — | Single delivery (rejected the 3-way split). 33-task Execution Graph appended to PLAN.md. |
| 4 | 2026-05-22 | /aid-detail delivery-001 — Approved | A+ | 33 task-NNN.md files; design refinements baked in (emission manifest JSONL, aid-generate placement, AC3 smoke test, task-011 split into 4, Option B for task-022 sequencing). |
| 5 | 2026-05-22 / 2026-05-23 | /aid-execute delivery-001 — Wave-by-wave shipped | A | All 33 tasks Done, grade A. Wave-based execution; per-task quick check + per-wave grade A gate (the manually-applied two-tier review pattern from work-001/feature-004). |
| 6 | 2026-05-23 | Cutover commit `15560ff` (task-027) | A | 311 files emitted live; 3 emission manifests written; install trees committed. |
| 7 | 2026-05-23 | Dogfood install refresh (commit `f121ab4`) | A | `.claude/` install tree refreshed from generator output to verify end-to-end. |
| 8 | 2026-05-23 | Canonical restructure (Phase A `05e5cc1`, Phase B `2c9d89b`) | A | Folded READMEs into `canonical/agents/<name>/{AGENT.md, README.md}` folders; relocated `{claude-code,codex,cursor}/` → `profiles/<tool>/`. |
| 9 | 2026-05-23 | PR #6 merged into master | A | Final landing on master at `4dddaff`. |
| 10 | 2026-05-23 | CW5: state files migrated to area-STATE shape | — | INTERVIEW-STATE.md + feature-001 STATE.md + 27 task-NNN-STATE.md absorbed into this STATE.md per the new FR2 rule from work-003. 8 tasks (003-008) had no STATE file pre-migration; 2 (001, 002) had stale "In Progress" STATE — all normalized to Done since install trees ship and VERIFY-4a passes. |
| 11 | 2026-05-24 | FR8 back-port: `recipes` asset kind added (work-001 task-024) | — | `render_recipes.py` added; `profile.py` extended with `recipes_dir`; `run_generator.py` + `verify_deterministic.py` updated to include recipes in render loop. `canonical/EMISSION-MANIFEST.md` declares the new asset kind contract. Attributed to work-001 FR8 (feature-011-recipes) implementation. Generator is idempotent when `canonical/recipes/` is empty. |
