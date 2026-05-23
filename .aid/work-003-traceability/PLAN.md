# Plan — work-003-traceability

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-23 | Initial plan — single delivery (delivery-001) bundling feature-001 (heartbeat) implementation across all 10 SKILLs with feature-002's deferred SKILL-body state-ref updates. 12 tasks total: 10 per-skill IMPLEMENT (each bundling heartbeat invocations + state-ref updates) + 1 rough-time-hints table + 1 end-to-end verification. AC4 sub-unit drill-down included on task-007 (aid-execute) with serial-task fallback per SPEC's two-phase rollout note. Coupling notes: each SKILL.md edited once in this delivery; work-001/feature-002 (thin-router) later restructures the same files (heartbeat content is additive and survives the refactor); work-001/feature-009 (parallel) later upgrades AC4 fidelity from serial-fallback to concurrent-wave display. | /aid-plan |

## Sequencing context (cross-work)

`work-003-traceability` ships **independently** of `work-001-aid-lite`, with explicit awareness of the coupling: every task in `delivery-001` edits a `canonical/skills/aid-*/SKILL.md` file that `work-001/feature-002` (thin-router refactor) will later edit again. That re-edit is **additive-preserving** — the thin-router refactor restructures the *organization* of each SKILL body but does not remove the heartbeat invocation lines this delivery adds. Each SKILL.md therefore experiences two edit passes in the optimistic case:

1. **This delivery** — adds heartbeat invocations (state-entry print, bracket-pair around long operations, ASCII state-map render, AC4 sub-unit drill-down for `aid-discover/GENERATE` and `aid-execute/EXECUTE-WAVE`) and updates state-file references from the legacy per-skill / per-artifact names to the new area-STATE shape (Work `STATE.md` for per-work skills; Discovery `STATE.md` for `aid-discover` + `aid-summarize`).
2. **`work-001/feature-002`** — restructures each SKILL.md into a thin router + `references/state-*.md` files. The heartbeat invocations get distributed into the per-state files; the dispatch table feeds `feature-001`'s state-map descriptor (Data Model in feature-001 SPEC).

A third edit pass becomes relevant when `work-001/feature-009` (parallel execution) ships: task-007's AC4 drill-down upgrades from serial-task fallback (1 task in flight at a time) to the full concurrent-wave snapshot — a content-only edit to the existing rendering logic, not a structural change.

The dogfood works on this branch (`work-001`, `work-002`, `work-003`) and the dogfood `.claude/` install **already use the new STATE shape** thanks to CW1–CW7. Until this delivery ships, the canonical SKILL bodies still reference the legacy names (DISCOVERY-STATE.md, INTERVIEW-STATE.md, task-NNN-STATE.md, etc.) — a documented interim hazard that this delivery resolves.

## Deliveries

### delivery-001 — Heartbeat across all 10 SKILLs + state-ref updates

| Field | Value |
|---|---|
| **Status** | Ready |
| **Features** | `feature-001-you-are-here-heartbeat` (all 4 ACs); `feature-002-state-file-consolidation` (SKILL-body updates only — ACs 1–7 already complete via CW1–CW7) |
| **Priority** | Should (per REQUIREMENTS §10) |
| **Depends on** | — (no upstream deliveries; `work-002` canonical generator is the foundation, already shipped on master) |

#### Goal

Make pipeline progress continuously visible across every AID skill (FR1), and close the interim-state hazard from CW1–CW7 by updating every canonical SKILL body to reference the new area-STATE files (FR2 finishing). Single edit pass per SKILL.md does both.

#### Context

The detailed design for each component is in `features/feature-001-you-are-here-heartbeat/SPEC.md` (graded A, carried from `work-001` split + AC4 extension):

- **AC1 — state-entry print:** `[State: NAME] — {description}` at the top of every state's output. Description sourced from the opening sentence of `references/state-{name}.md` (a feature-002-in-work-001 product); degrades cleanly to bare `[State: NAME]` until that's authored.
- **AC2 — bracket-pair floor:** `▶ {op} starting (~{rough time})` / `✓ {op} done in {actual}` / `✗ {op} failed: {reason}` around every long operation. Rough-time hints sourced from the static per-operation-class table (task-011). The load-bearing answer to "am I stuck?".
- **AC3 — ASCII state-map:** rendered once per state transition, immediately after the state-entry print. Per-skill scope (each skill shows its own state machine); for `aid-interview` the FR1 lite/full fork displays before triage and collapses after.
- **AC4 — sub-unit drill-down (qualifying states only):** for `aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`, the map drills in to show each sub-unit with status + elapsed/expected time + iteration counter. 1-second coalescing on re-renders. **Serial-task fallback** for EXECUTE-WAVE pre-work-001/feature-009; full-fidelity post-feature-009.

State-ref updates from feature-002: each SKILL body that today references `INTERVIEW-STATE.md`, `DISCOVERY-STATE.md`, `task-NNN-STATE.md`, `DEPLOYMENT-STATE.md`, `SUMMARY-STATE.md`, or per-feature `STATE.md` updates to reference the appropriate area STATE (`.aid/knowledge/STATE.md` or `.aid/work-NNN-{name}/STATE.md`) with the appropriate section pointer (e.g., `STATE.md ## Interview Status` instead of `INTERVIEW-STATE.md`).

**Key constraints carried from REQUIREMENTS / SPEC:**

- **Pure skill-body text.** No new scripts, no helpers, no hooks, no event stream, no schema, no separate viewer process (NFR5 — zero new end-user dependencies).
- **Methodology preservation.** Adding traceability output does not change any AID phase semantics, artifacts, or quality gates (§7 constraint).
- **Universality.** Mechanisms must work identically on every host tool (Claude Code, Codex CLI, Cursor); text is the lowest common denominator (NFR1).
- **Single edit per SKILL.md in this delivery.** Heartbeat + state-ref updates land in the same task per skill so each file is edited once.

#### Tasks

| # | Task | Type | Scope | AC4? | Parallel? |
|---|------|------|-------|------|-----------|
| 001 | Update `canonical/skills/aid-init/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 invocations + state-ref updates (Discovery STATE for the workspace scaffold writes) | No (no qualifying iteration) | Yes |
| 002 | Update `canonical/skills/aid-discover/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + **AC4 for `GENERATE` state** (sub-unit drill-down over the 5 parallel discovery sub-agents) + state-ref updates (Discovery STATE) | **Yes (GENERATE)** — full fidelity day 1 (discovery already parallel) | Yes |
| 003 | Update `canonical/skills/aid-interview/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Work STATE `## Interview Status` + `## Cross-phase Q&A` sections) | No | Yes |
| 004 | Update `canonical/skills/aid-specify/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Work STATE `## Features Status` + Q&A sections) | No (per-section iteration deferred to v2) | Yes |
| 005 | Update `canonical/skills/aid-plan/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Work STATE `## Plan / Deliveries`) | No | Yes |
| 006 | Update `canonical/skills/aid-detail/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Work STATE `## Tasks Status` table init) | No | Yes |
| 007 | Update `canonical/skills/aid-execute/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + **AC4 for `EXECUTE-WAVE` state** (sub-unit drill-down over wave tasks, serial-fallback pre-feature-009) + state-ref updates (Work STATE `## Tasks Status` row updates) | **Yes (EXECUTE-WAVE)** — serial-fallback until work-001/feature-009 ships | Yes |
| 008 | Update `canonical/skills/aid-deploy/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Work STATE `## Deploy Status`) | No | Yes |
| 009 | Update `canonical/skills/aid-monitor/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref note (Monitor STATE deferred — comment in body pointing at the area-STATE rule; no actual STATE file references since Monitor area is not mature) | No | Yes |
| 010 | Update `canonical/skills/aid-summarize/SKILL.md` | IMPLEMENT | AC1+AC2+AC3 + state-ref updates (Discovery STATE `## Knowledge Summary Status` + `## Summarization History`) | No | Yes |
| 011 | Ship rough-time-hints table (canonical asset) | IMPLEMENT | Static per-operation-class table (e.g., `discovery-architect: ~3-5 min`, `reviewer: ~1-2 min`, `validate-links: ~30s`) lives in a canonical file (location: `canonical/skills/rough-time-hints.md` or inline in `feature-001` references); cited by every AC2 bracket-pair. Used by tasks 001-010 — they consume it. | No | Sequential before 001-010 (provides input) |
| 012 | End-to-end verification + dogfood smoke | TEST | Run `python run_generator.py` (clean); `/aid-generate` produces install trees with heartbeat-bearing SKILLs; setup.sh smoke test installs cleanly; spot-check 3 SKILLs (aid-discover, aid-execute, aid-summarize) render heartbeat output correctly when invoked on a small toy scenario. VERIFY-4a PASS. | No | Sequential after 001-010 |

**Total: 12 tasks.** Tasks 001-010 parallel-eligible after task-011 provides the rough-time-hints table.

## Cross-cutting risks

| Risk | Mitigation |
|---|---|
| Heartbeat additions bloat SKILL.md beyond useful size | Per SPEC, additions are short invocations (one line for state-entry, two lines for bracket-pair, ~5 lines for state-map). Total per-skill additions <50 lines, vs. ~500-line SKILL.md bodies. <10% bloat. |
| State-ref updates miss a reference, leaving stale orphans | Per-task definition step includes `git grep` sweep for old names in the SKILL.md being edited; the per-task quick-check (manual two-tier review) catches misses. End-to-end task-012 sweeps the full canonical tree. |
| AC4 drill-down on aid-execute breaks pre-feature-009 (serial wave) | Per SPEC Migration Plan: "drill-down ships with this feature but reaches full fidelity only after work-001/feature-009 lands ... before then, EXECUTE-WAVE runs serially and the snapshot shows one task in flight at a time." Documented behavior, not a defect. |
| Thin-router refactor (work-001/feature-002) overwrites heartbeat invocations on its second pass over each SKILL.md | Heartbeat invocations are **additive content** that distributes into per-state `references/state-*.md` files during thin-router restructure. A pre-thin-router task in work-001/feature-002 should preserve all heartbeat invocations during the refactor. Out of scope for this delivery; flagged for work-001/feature-002. |
| Cross-platform line endings introduced when editing SKILL.md files | Use binary-mode writes (Python pathlib.write_bytes) per the established session pattern; preserve each file's original LE on edit. |

## Execution Graph — `delivery-001`

```
                  ┌──── task-001 (aid-init) ──────────┐
                  ├──── task-002 (aid-discover) ──────┤
                  ├──── task-003 (aid-interview) ─────┤
                  ├──── task-004 (aid-specify) ───────┤
                  ├──── task-005 (aid-plan) ──────────┤
task-011 ────────►├──── task-006 (aid-detail) ────────┼──► task-012 (verify)
(rough-time       ├──── task-007 (aid-execute) ──────┤
 table)           ├──── task-008 (aid-deploy) ───────┤
                  ├──── task-009 (aid-monitor) ──────┤
                  └──── task-010 (aid-summarize) ────┘
```

| Task | Depends On | Can Run In Parallel With | Critical Path? |
|------|-----------|--------------------------|----------------|
| task-011 | — (none — provides rough-time-hints table for tasks 001-010) | — | Yes (first node) |
| task-001 | task-011 | task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010 | No |
| task-002 | task-011 | (same row as task-001) | No |
| task-003 | task-011 | (same) | No |
| task-004 | task-011 | (same) | No |
| task-005 | task-011 | (same) | No |
| task-006 | task-011 | (same) | No |
| task-007 | task-011 | (same) | Yes (highest scope task in the wave: AC1-AC4 + state-ref + EXECUTE-WAVE serial-fallback; likely the slowest single task) |
| task-008 | task-011 | (same) | No |
| task-009 | task-011 | (same) | No |
| task-010 | task-011 | (same) | No |
| task-012 | task-001 .. task-010 (all 10) | — | Yes (last node) |

**Critical path:** `task-011 → task-007 → task-012` (3 nodes; task-007 is the bottleneck of the wave since it has the most ACs to implement, including AC4).

## Open Questions

Genuine decision points — surfaced, not assumed.

*(none open — all 3 feature-002 OQs resolved 2026-05-23; feature-001's OQ-A and OQ-C were resolved by work-001/feature-002 during /aid-specify; AC4 timing (drill-down with serial-fallback vs deferred) resolved during /aid-plan.)*

### Resolved Planning Questions

- **Delivery scope: single delivery vs split.** Resolved during /aid-plan (2026-05-23) — single delivery bundling FR1 heartbeat + FR2 skill-body state-ref updates so each SKILL.md is edited once. Rejected alternative: split into 2 deliveries (state-refs first, heartbeat second) which would double the SKILL.md edit count.
- **AC4 drill-down timing on aid-execute.** Resolved during /aid-plan (2026-05-23) — include AC4 in task-007 with serial-task fallback per SPEC Migration Plan. Pre-work-001/feature-009 shows 1 task in flight; post-feature-009 shows full concurrent wave.
