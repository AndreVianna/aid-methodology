# Requirements — work-003-traceability

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-23 | **FR2 added — state-file consolidation.** Reorganize AID's state files from per-skill / per-artifact scatter into **one STATE.md per area**: Discovery (`.aid/knowledge/STATE.md`) and Work (`.aid/work-NNN/STATE.md`). Monitor deferred (area not mature). Absorbs DISCOVERY-STATE + SUMMARY-STATE on the Discovery side; INTERVIEW-STATE + per-feature STATE.md + per-task task-NNN-STATE + DEPLOYMENT-STATE on the Work side. Artifact files (REQUIREMENTS / SPEC / PLAN / task-NNN) lose their per-artifact state files; their inline `## Change Log` sections (artifact content history) are unchanged. Drives feature-002's SPEC. Supports FR1: one file per area means traceability has a single trace destination per area instead of hunting across files. | extension |
| 2026-05-23 | **FR1 extended — sub-unit drill-down.** Added a fourth requirement to FR1's third component (the "you are here" map): for states that iterate over a known list of sub-units (notably `aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`), the map drills in to show the sub-unit list with per-item status and an iteration counter, with re-renders coalesced per second. AC added to §9; soft dependency on `work-001/feature-009` added to §8. Drives feature-001 SPEC's new AC4. | extension |
| 2026-05-23 | **Split from `work-001-aid-lite`.** Extracted FR4 (progress traceability) and pain-point #4 ("no progress visibility") into this dedicated work. `feature-007` in work-001 was renamed to `feature-001` here per AID per-work numbering convention. Reason: traceability is orthogonal to AID-Lite's speed concern; separating them keeps each work's scope tight. Prior history lives in `work-001-aid-lite/REQUIREMENTS.md`. | split from work-001 |

## 1. Objective

Make AID's pipeline progress continuously visible. Users running any AID skill — full path or lite path — always know what state they are in, what operation is happening, and that the process is not stuck.

**Success looks like:**

- The user never has to wonder "is it stuck?" — every long operation is visibly in-progress.
- The user always knows which state of which skill they are in.
- All visibility is delivered as plain printed text in the chat, so it works on every host tool without exception (no hooks, no event streams, no schemas, no HTML viewers).
- The maintainer (and any skill) can answer "where is this work at?" by reading exactly one state file per area — the supporting state-file consolidation (FR2) makes traceability direct rather than scattered.

## 2. Problem Statement

AID skills currently provide almost no progress feedback. Long operations — dispatching sub-agents, running validators, generating large artifacts — appear as silent waits in the chat. Users disengage or assume the process is stuck.

The benchmark documented in `work-001-aid-lite/REQUIREMENTS.md §2` also surfaced this perception cost: even when AID *was* making progress, the user often could not tell, which compounded the perception of slowness on top of the actual overhead.

This work delivers the visibility layer that addresses the perception cost. The orthogonal speed concern is owned by `work-001-aid-lite`.

## 3. Users & Stakeholders

Same as `work-001-aid-lite §3` — the primary user is the developer running AID on a project. The methodology maintainer also benefits when debugging skills (visible state + timing).

## 4. Scope

**In scope:**

- Pure skill-body text mechanisms for progress visibility (state-entry prints, bracket-pair operation framing, ASCII state-map "you are here" rendering).
- Reorganization of AID's state-file layout: **one STATE.md per area** (Discovery, Work; Monitor deferred), absorbing the per-skill and per-artifact state files into the appropriate area STATE.
- Application across all 10 AID skills.

**Out of scope:**

- Hook-emitted JSONL event stream (was FR4-P3 in the original work-001; dropped during the fresh-eyes reshape).
- HTML / web viewer (was FR4-P2; dropped).
- Self-telemetry: per-phase/skill/task timing aggregation (was FR7 in the original work-001; dropped).
- Native host-tool progress UI (task checklists, background-run notifications) — opportunistic only, not committed (was P4 in the original work-001).

## 5. Functional Requirements

**FR1 — Progress traceability via "you are here" + bracket-pair floor.** Make pipeline progress continuously visible so the user always knows what is happening, where they are, and that the process is not stuck. **Pure skill-body text** — no hooks, no event stream, no HTML viewer, no schema. Three components, all printed in the chat:

- **State-entry print:** every state prints `[State: NAME] — {one-line description}` on entry.
- **Bracket-pair floor:** every long operation brackets itself —
  `▶ {operation} starting (~{rough expected time})` before,
  `✓ {operation} done in {actual time}` after,
  `✗ {operation} failed: {reason}` on error.
  This is the load-bearing answer to "am I stuck?" — guaranteed on every host tool because every host tool can print text.
- **"You are here" map:** the skill body renders an ASCII state-map on each state transition with the current state marked. **For states that iterate over a known list of sub-units** (notably `aid-execute/EXECUTE-WAVE` — the tasks in a wave — and `aid-discover/GENERATE` — the parallel discovery sub-agents), the map drills in to show the sub-units with per-item status (done / running with elapsed time / queued / failed) and an iteration counter (e.g. `Wave 1 of 2 · 2/6 done`). Re-renders triggered by sub-unit transitions within the same second are coalesced into one render to bound chat noise.

*Note: this FR was numbered **FR4** in `work-001-aid-lite`, where its companion mechanisms (event stream, HTML viewer, native UI) were dropped in the fresh-eyes reshape (2026-05-22). Renumbered to FR1 for this dedicated work.*

**FR2 — State-file consolidation: one STATE.md per area.** Reorganize AID's state files into a coherent per-area shape that makes traceability direct. The repo has **three areas**, each with its own lifecycle:

- **Discovery** (persistent to the repo, runs once + maintained) — the Knowledge Base plus the visual summary. Lifecycle: build + validate the KB.
- **Work** (per work, repeats per delivery) — the development lifecycle. Lifecycle: req → spec → plan → impl → deploy.
- **Monitor** (per work, post-conclusion) — observation and feedback. Lifecycle: observe → classify → route. **Deferred** (the area is not mature yet).

Each area gets **exactly one STATE.md**:

- `.aid/knowledge/STATE.md` — absorbs `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.
- `.aid/work-NNN-{name}/STATE.md` — absorbs `INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N + (future) `DEPLOYMENT-STATE.md`.
- `.aid/work-NNN-{name}/MONITOR-STATE.md` — *(deferred — author when the Monitor area matures).*

**Artifact files keep their inline `## Change Log` sections** — that is *content history* (what changed in this document), distinct from *process state* (where are we in the workflow). Same file, different concern. Artifact files include REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, KB documents — none of these change shape.

**What goes away:** `DISCOVERY-STATE.md`, `SUMMARY-STATE.md`, `INTERVIEW-STATE.md`, per-feature `STATE.md`, `task-NNN-STATE.md`, `DEPLOYMENT-STATE.md` (when authored — never existed as separate from area STATE). The per-skill naming pattern (INTERVIEW-STATE / SUMMARY-STATE) dies; the per-artifact pattern (task-NNN-STATE) dies; the plain `STATE.md` per feature dies. All absorbed into the area STATE.

**How it serves FR1.** With one STATE.md per area, the traceability heartbeat has a single trace destination: the user sees "working on task-003 in delivery-001" → opens `.aid/work-001-aid-lite/STATE.md` → sees the full lifecycle in one view. The sub-unit drill-down (AC4) reads its iteration source from the same file (Tasks Status section). Traceability becomes a single-file experience per area.

## 6. Non-Functional Requirements

- **Universality.** Mechanisms must work identically on every host tool (Claude Code, Codex CLI, Cursor). Text is the lowest common denominator.
- **Zero new dependencies.** No hooks, no schemas, no separate viewer process. Skill bodies print text; that is the entire dependency.
- **Methodology preservation.** Adding progress-traceability output must not change any AID phase semantics, artifacts, or quality gates.

## 7. Constraints

- Sub-second operations are **not** bracketed (would create noise without value).
- The threshold for "long operation" is per-skill judgment, with the rough-time-hints table in `feature-001`'s SPEC as the source of truth for what gets bracketed.
- ASCII state-map must fit within typical terminal widths (no horizontal scrolling required).

## 8. Assumptions & Dependencies

- Loosely depends on `work-001-aid-lite/feature-002` (thin-router refactor — FR3) for the structured state list each skill exposes via its dispatch table. Works inline before that refactor lands; benefits more after.
- No dependency on hooks, event streams, or any cross-process coordination.
- `canonical/` single-source editing (delivered by `work-002`) is assumed in place so the FR1 mechanisms ship once and propagate to all three install trees via `/aid-generate`.
- **FR2 — `canonical/templates/` migration.** Implementing the new STATE.md shape requires updating `canonical/templates/` (new area-STATE templates; retire per-artifact state templates), `.aid/knowledge/data-model.md` (document the new rule), and `.aid/knowledge/coding-standards.md` (naming convention update). The dogfood works (`.aid/work-001-aid-lite`, `.aid/work-002-canonical-generator`, `.aid/work-003-traceability`) get migrated in-place as part of feature-002. Skill body updates (aid-interview, aid-specify, aid-detail, aid-execute, aid-deploy, aid-summarize) to read/write the new shape land alongside work-001's `feature-002-skill-footprint-refactor` (thin-router) when that refactor edits the same SKILL.md files anyway.
- **FR2 — concurrent-write design deferred to `/aid-specify`.** When `feature-009` (parallel execution) is shipped, multiple in-flight tasks may simultaneously want to update the Work STATE.md `## Tasks Status` table. The serialization mechanism (single-writer orchestrator vs. per-task event-append vs. file-lock) is a real design question flagged in feature-002's SPEC and resolved when feature-002 reaches `/aid-specify`.
- **Soft coupling to `work-001/feature-009` (parallel execution)** for the `aid-execute/EXECUTE-WAVE` sub-unit drill-down. The drill-down ships with this work; its fidelity scales up as `feature-009` lands (pre-`feature-009` the wave runs serially and the snapshot shows one task in flight). `aid-discover/GENERATE`'s drill-down has no such coupling — discovery already runs in parallel.

## 9. Acceptance Criteria

**FR1 — Progress traceability (pure skill-body text):**

- Every state prints `[State: NAME] — {description}` on entry.
- Every long operation prints `▶ {op} starting (~{rough time})` before and `✓ {op} done in {actual time}` after (the bracket-pair floor).
- The skill body renders an ASCII "you are here" state-map on each state transition with the current state marked.
- For qualifying states that iterate over a known list of sub-units (`aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`), the map drills in to show each sub-unit with status, elapsed / expected time, and an iteration counter; re-renders are coalesced per second.

**FR2 — State-file consolidation:**

- `.aid/knowledge/STATE.md` exists and contains the consolidated Discovery-area state (KB documents status, summary status, Q&A pending, review history, summarization history); `DISCOVERY-STATE.md` and `SUMMARY-STATE.md` no longer exist.
- Each work folder contains `.aid/work-NNN-{name}/STATE.md` consolidating the Interview / Features / Plan / Tasks / Deploy / Q&A / Lifecycle sections; `INTERVIEW-STATE.md`, per-feature `STATE.md`, and per-task `task-NNN-STATE.md` no longer exist in any work folder.
- Artifact files (REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, KB docs) keep their inline `## Change Log` sections; their content schemas are unchanged.
- `canonical/templates/` ships `work-state-template.md` and `discovery-state-template.md`; deprecated templates (`interview-state.md`, `feature-state.md`, `implementation-state.md`, plus the discovery-state and summary-state templates) are retired.
- `.aid/knowledge/data-model.md` and `.aid/knowledge/coding-standards.md` document the new area-STATE rule.

## 10. Priority

| Bucket | Items | Rationale |
|---|---|---|
| **Should** | FR1 (`feature-001`) · FR2 (`feature-002`) | FR1 is the traceability mechanism (state-entry prints, bracket-pair floor, ASCII state-map, sub-unit drill-down). FR2 is the state-file consolidation that makes FR1's trace destination unambiguous (one STATE.md per area). Pain-point #4 (no progress visibility) is a user-perceived but non-blocking concern; visibility is valuable but does not gate AID's functional correctness. |

**Recommended build order:** can ship anytime; no hard dependency on other works. Loosely coupled with `work-001-aid-lite/feature-002` (FR3 thin-router) — uses the dispatch-table descriptors that FR3-M1 makes structured.

### Pain-point → feature coverage

| Pain point (origin: `work-001 §2` pain #4) | Owning feature | Mechanism |
|---|---|---|
| **No progress visibility.** Skills provide almost no traceability or progress feedback; users feel disconnected and assume the process is stuck. | `feature-001-you-are-here-heartbeat` | Pure skill-body text: `[State: NAME]` print + bracket-pair floor around long operations + ASCII state-map |
