# Feature Inventory

> **Source:** aid-discover (orchestrator) — populated from user-confirmed Q-FEATURES (Required) answer in `DISCOVERY-STATE.md`.
> **Status:** Populated (initial dogfood pass, 2026-05-21)
> **Last Updated:** 2026-05-21
> **Cross-references:** `architecture.md` (overall AID architecture), `module-map.md` (per-module location of each feature), `data-model.md` (per-artifact schema for each feature's outputs), `host-tools-matrix.md` (per-tool availability), `tech-debt.md` (known gaps per feature).

## Framing

This is a **methodology + multi-tool tooling repository**, not a typical application. "Features" here are AID *deliverables* — methodology phases, install bundles, supporting capabilities — not user-facing app capabilities. The HTTP / RPC "Endpoints" column maps to **slash commands** (`/aid-discover`, `/aid-init`, etc.) since those are the user-facing surface; "Data Entities" maps to the artifact types each feature produces or consumes.

Status legend: ✅ Shipped at V3 = feature is complete and exercised in all 3 install trees. ⚠️ Partial = ships but with a known issue or gap (cross-linked to Q&A / tech-debt). 🔮 Future = on the roadmap (no install tree yet).

## Inventory

| # | Feature | Description | Status | Modules | Endpoints (slash commands) | Data Entities |
|---|---------|-------------|--------|---------|----------------------------|---------------|
| 1 | AID Methodology Document | The V3 canonical spec (1,158 lines). The single normative document everything else derives from. | ✅ Shipped | `methodology/aid-methodology.md`, `methodology/images/` (4 pipeline diagrams) | n/a (reference doc) | n/a |
| 2 | Init phase + `aid-init` skill | Scaffold `.aid/`, ask greenfield/brownfield, collect metadata + external doc paths, create `CLAUDE.md` / `AGENTS.md` placeholders. Runs once at project bootstrap. | ✅ Shipped | `skills/aid-init/`, `claude-code/.claude/skills/aid-init/`, `codex/.agents/skills/aid-init/`, `cursor/.cursor/skills/aid-init/` | `/aid-init` | `DISCOVERY-STATE.md` (skeleton), `CLAUDE.md` / `AGENTS.md` (template with placeholders), `.gitignore` (adds `.aid/`), the 16 standard KB doc files (initial-empty) |
| 3 | Discovery phase + `aid-discover` skill + 6 sub-agents | Brownfield codebase analysis populating 16 KB docs via 5 parallel discovery sub-agents + reviewer; built-in REVIEW → Q&A → FIX → APPROVAL state machine. The only skill that uses the host `Agent` tool. | ✅ Shipped | `skills/aid-discover/`, 3 install-tree variants; `agents/discovery-*/` (canonical READMEs absent per Q18); `claude-code/.claude/agents/discovery-{scout,architect,analyst,integrator,quality,reviewer}.md` + Codex + Cursor variants | `/aid-discover` | All 16 KB docs (architecture.md, etc.), `project-index.md` (pre-pass), `DISCOVERY-STATE.md` (consolidated Q&A — supersedes the older `additional-info.md` pattern per Q102 / Q115), `host-tools-matrix.md` (extension) |
| 4 | Interview phase + `aid-interview` skill | Adaptive one-question-at-a-time dialogue. Produces `REQUIREMENTS.md` and per-feature `SPEC.md` (requirements side). | ✅ Shipped | `skills/aid-interview/`, 3 install-tree variants; `agents/interviewer/`; `claude-code/.claude/agents/interviewer.md` + Codex + Cursor variants | `/aid-interview` | `REQUIREMENTS.md`, `INTERVIEW-STATE.md`, `FEATURE-STATE.md`, per-feature `SPEC.md` (requirements section) |
| 5 | Specify phase + `aid-specify` skill | Per-feature technical refinement; agent acts as tech lead, proposes solutions grounded in KB + codebase. Adds Technical Specification section to per-feature `SPEC.md`. | ✅ Shipped | `skills/aid-specify/`, 3 install-tree variants; `agents/architect/`; per-tool architect agent | `/aid-specify` | per-feature `SPEC.md` (Technical Specification section) |
| 6 | Plan phase + `aid-plan` skill | Sequence features into Delivery MVP slices. Each Delivery is a self-contained functional slice. | ✅ Shipped | `skills/aid-plan/`, 3 install-tree variants; `agents/architect/` | `/aid-plan` | `PLAN.md` (format defined inline by `aid-plan`), `KNOWN-ISSUES.md` (per-work) |
| 7 | Detail phase + `aid-detail` skill | Decompose deliveries into typed TASKs (8 types). | ✅ Shipped | `skills/aid-detail/`, 3 install-tree variants; `agents/architect/` | `/aid-detail` | `task-NNN.md` files + execution graph appended to `PLAN.md` |
| 8 | Execute phase + `aid-execute` skill | Type-aware TASK execution with built-in REVIEW loop. Default agent is Developer; per-task-type executor varies (e.g., Data Engineer for DATA tasks, Security for SECURITY tasks). | ✅ Shipped | `skills/aid-execute/`, 3 install-tree variants; `agents/developer/`, all 6 Specialist agents | `/aid-execute` | `task-NNN-STATE.md`, `IMPEDIMENT.md`, updated code in user project |
| 9 | Deploy phase + `aid-deploy` skill | Package + verify + ship completed Delivery to production. | ✅ Shipped | `skills/aid-deploy/`, 3 install-tree variants; `agents/operator/` | `/aid-deploy` | `package-NNN.md`, `DEPLOYMENT-STATE.md` |
| 10 | Monitor phase + `aid-monitor` skill | Observe production, classify findings (BUG / Change Request / Infrastructure / No Action), route to actions. | ⚠️ Partial — templates `MONITOR-STATE.md` + `track-report-template.md` referenced but unauthored (see DISCOVERY-STATE Q8 — author both per resolution) | `skills/aid-monitor/`, 3 install-tree variants; `agents/orchestrator/` | `/aid-monitor` | `MONITOR-STATE.md` (TO AUTHOR per Q8), `track-report-*.md` (TO AUTHOR per Q8), `KNOWN-ISSUES.md` (per-work) |
| 11 | Summarize phase + `aid-summarize` skill | Generate a single-file `knowledge-summary.html` from `.aid/knowledge/`. Inlines CSS / JS / Mermaid; supports light/dark theme; lightbox; breadcrumb scrollspy. 9-state machine. | ✅ Shipped (optional) | `skills/aid-summarize/` (not in canonical `skills/` tree per project-structure.md — only in install trees), 3 install-tree variants; `templates/knowledge-summary/` assets (~25 files) | `/aid-summarize` | `knowledge-summary.html` (single-file offline output) |
| 12 | Claude Code install bundle | Install payload for Anthropic Claude Code. | ✅ Shipped | `claude-code/.claude/{agents,skills,templates}/` + `claude-code/CLAUDE.md` (project-config template) | n/a (install-time via `setup.sh`/`setup.ps1`) | 22 agent `.md` files + 10 SKILL.md packages + `templates/` assets + `CLAUDE.md` template |
| 13 | Codex install bundle | Install payload for OpenAI Codex CLI. Split layout: `.codex/` (agents only) + `.agents/` (skills + templates). | ⚠️ Partial — installer omits `.agents/` copy (DISCOVERY-STATE Q70 CONFIRMED bug; setup.sh:142-145 and setup.ps1:137-141). Patch trivial. | `codex/.codex/agents/` (22 TOMLs) + `codex/.agents/{skills,templates}/` + `codex/AGENTS.md` | n/a (install-time) | 22 agent `.toml` files + 10 SKILL.md packages (inlined) + `templates/` assets + `AGENTS.md` template |
| 14 | Cursor install bundle | Install payload for Cursor IDE. Includes `.mdc` rules (always-on context). | ⚠️ Partial — agent `tools:` field inconsistent within tree (`Terminal` vs `Bash` — DISCOVERY-STATE Q52). CONTRIBUTING.md omits Cursor from triplication rule (Q72). Both pending CONTRIBUTING + cleanup. | `cursor/.cursor/{agents,rules,skills,templates}/` + `cursor/AGENTS.md` | n/a (install-time) | 22 agent `.md` files + 10 SKILL.md packages (inlined) + 2 `.mdc` rule files + `templates/` assets + `AGENTS.md` template |
| 15 | Installer scripts (`setup.sh` / `setup.ps1`) | Cross-platform interactive installer. Menu-driven selection of one or more tools. Safe re-run (skip identical, prompt different, `--force` to overwrite). | ⚠️ Partial — Codex branch omits `.agents/` copy (Q70 CONFIRMED). Missing `--dry-run` and `--prune` modes (Q79). Missing version-print on completion (Q1). | `setup.sh` (Bash 161 lines), `setup.ps1` (PowerShell 156 lines) | command-line: `bash setup.sh /path` or `pwsh setup.ps1 C:\path` | n/a (modifies user project's filesystem) |
| 16 | Per-tool agent definitions (22 agents × 3 trees = 66 agent files) | Same 22 agents in each install tree's native format. All tier-consistent across trees (May 2026 migration applied cleanly per `tech-debt.md` L6 + Q36 verified). | ⚠️ Partial — per-agent BODY divergence (line-count drift) across trees, especially for the 6 discovery sub-agents (claude `.md` 153-381 lines vs codex `.toml` 127-314 lines). Cause: Claude Code uses `references/` decomposition; Codex/Cursor inline. Propagation script pending per Q3 / Q73. | `claude-code/.claude/agents/*.md` (22 files), `codex/.codex/agents/*.toml` (22 files), `cursor/.cursor/agents/*.md` (22 files) | n/a (invoked by skills via host-tool Agent dispatch) | agent frontmatter schemas (3 per host tool — see `api-contracts.md §1-3`) |
| 17 | Examples | Three anonymized real-world case studies showing AID's `.aid/` workspace shape. | ✅ Shipped (anonymization verified by reviewer spot-check across all 3) | `examples/brownfield-enterprise/` (Java/OSGi monorepo), `examples/desktop-app/` (.NET/Avalonia/MVVM), `examples/data-pipeline/` (multi-agent e-commerce analytics) | n/a (reference) | example `.aid/` snapshots (KB docs + REQUIREMENTS + SPEC etc.) |
| 18 | Reference documentation | Top-level human-readable docs: project overview, contribution rules, FAQ, glossary seed. | ⚠️ Partial — `README.md:267` and `CONTRIBUTING.md:58` and `docs/faq.md:28` imply Copilot + Antigravity support that doesn't ship (Q5 resolution: update wording to reflect actual 3-tool support matrix). `CONTRIBUTING.md:21-26` triplication rule omits Cursor (Q34/Q72). | `README.md` (286 lines), `CONTRIBUTING.md` (116 lines), `docs/faq.md`, `docs/glossary.md` | n/a | n/a |

## Status Summary

| Status | Count | Notes |
|--------|-------|-------|
| ✅ Shipped (no known issues) | 12 | Features 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 17 |
| ⚠️ Partial (known issue / gap) | 6 | Features 10 (templates unauthored — Q8/H7), 13 (Codex installer bug — Q70/H6), 14 (Cursor inconsistencies — Q52/M6, Q72), 15 (installer omissions — Q70, Q79), 16 (cross-tree drift — Q3, Q73, Q18), 18 (doc wording — Q5, Q34, Q72) |
| 🔮 Future | 0 (in this inventory) | Tracked separately in `host-tools-matrix.md §1` — GitHub Copilot CLI + Google Antigravity remain future targets per Q5 |

## Per-Feature Health → Q&A Cross-Reference

| Feature | Affected by Q&A |
|---------|-----------------|
| #10 Monitor | Q8 / Q31 / Q77 (missing templates) |
| #13 Codex bundle | Q70 (CONFIRMED installer bug), Q9 (split layout rationale) |
| #14 Cursor bundle | Q52 (Terminal/Bash internal inconsistency), Q72 (CONTRIBUTING omission) |
| #15 Installers | Q70 (Codex .agents omission), Q79 (no --dry-run / --prune), Q1 (version-print) |
| #16 Agent definitions | Q3 / Q73 (cross-tree body drift), Q18 (missing discovery sub-agent READMEs), Q50 / Q81 (placeholder lifecycle) |
| #18 Reference docs | Q5 (supported tools wording), Q34 / Q72 (CONTRIBUTING triplication rule) |

## Notes on the Inventory Shape

The 18-item inventory reflects the user-confirmed canonical scope of AID at V3 (per `DISCOVERY-STATE.md` Q-FEATURES answered 2026-05-21). Three observations:

1. **No HTTP / RPC endpoints exist.** The "Endpoints" column repurposed for slash commands is the user-facing surface for the 10 phase-skill features; install bundle features have no command surface (only install-time invocation via `setup.{sh,ps1}`).
2. **Data Entities map to AID's pipeline artifacts.** See `data-model.md` for full schemas of every artifact named here (DISCOVERY-STATE.md, REQUIREMENTS.md, SPEC.md, PLAN.md, TASK files, task-NNN-STATE.md, DEPLOYMENT-STATE.md, etc.).
3. **Status accuracy depends on Q70 verification.** Feature 13 (Codex bundle) is marked ⚠️ Partial based on reviewer's static-analysis confirmation of the installer bug. A hands-on smoke test (run `setup.sh` against an empty Codex project and verify `.agents/skills/` populated) would close the verification loop.
