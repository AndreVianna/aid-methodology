# Requirements — work-003-traceability

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-23 | **FR1 extended — sub-unit drill-down.** Added a fourth requirement to FR1's third component (the "you are here" map): for states that iterate over a known list of sub-units (notably `aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`), the map drills in to show the sub-unit list with per-item status and an iteration counter, with re-renders coalesced per second. AC added to §9; soft dependency on `work-001/feature-009` added to §8. Drives feature-001 SPEC's new AC4. | extension |
| 2026-05-23 | **Split from `work-001-aid-lite`.** Extracted FR4 (progress traceability) and pain-point #4 ("no progress visibility") into this dedicated work. `feature-007` in work-001 was renamed to `feature-001` here per AID per-work numbering convention. Reason: traceability is orthogonal to AID-Lite's speed concern; separating them keeps each work's scope tight. Prior history lives in `work-001-aid-lite/REQUIREMENTS.md`. | split from work-001 |

## 1. Objective

Make AID's pipeline progress continuously visible. Users running any AID skill — full path or lite path — always know what state they are in, what operation is happening, and that the process is not stuck.

**Success looks like:**

- The user never has to wonder "is it stuck?" — every long operation is visibly in-progress.
- The user always knows which state of which skill they are in.
- All visibility is delivered as plain printed text in the chat, so it works on every host tool without exception (no hooks, no event streams, no schemas, no HTML viewers).

## 2. Problem Statement

AID skills currently provide almost no progress feedback. Long operations — dispatching sub-agents, running validators, generating large artifacts — appear as silent waits in the chat. Users disengage or assume the process is stuck.

The benchmark documented in `work-001-aid-lite/REQUIREMENTS.md §2` also surfaced this perception cost: even when AID *was* making progress, the user often could not tell, which compounded the perception of slowness on top of the actual overhead.

This work delivers the visibility layer that addresses the perception cost. The orthogonal speed concern is owned by `work-001-aid-lite`.

## 3. Users & Stakeholders

Same as `work-001-aid-lite §3` — the primary user is the developer running AID on a project. The methodology maintainer also benefits when debugging skills (visible state + timing).

## 4. Scope

**In scope:**

- Pure skill-body text mechanisms for progress visibility (state-entry prints, bracket-pair operation framing, ASCII state-map "you are here" rendering).
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
- **Soft coupling to `work-001/feature-009` (parallel execution)** for the `aid-execute/EXECUTE-WAVE` sub-unit drill-down. The drill-down ships with this work; its fidelity scales up as `feature-009` lands (pre-`feature-009` the wave runs serially and the snapshot shows one task in flight). `aid-discover/GENERATE`'s drill-down has no such coupling — discovery already runs in parallel.

## 9. Acceptance Criteria

**FR1 — Progress traceability (pure skill-body text):**

- Every state prints `[State: NAME] — {description}` on entry.
- Every long operation prints `▶ {op} starting (~{rough time})` before and `✓ {op} done in {actual time}` after (the bracket-pair floor).
- The skill body renders an ASCII "you are here" state-map on each state transition with the current state marked.
- For qualifying states that iterate over a known list of sub-units (`aid-execute/EXECUTE-WAVE` and `aid-discover/GENERATE`), the map drills in to show each sub-unit with status, elapsed / expected time, and an iteration counter; re-renders are coalesced per second.

## 10. Priority

| Bucket | Items | Rationale |
|---|---|---|
| **Should** | FR1 (`feature-001`) | The single functional requirement. Inherits the "Should" priority it held as FR4 in `work-001`. Pain-point #4 (no progress visibility) is a user-perceived but non-blocking concern; visibility is valuable but does not gate AID's functional correctness. |

**Recommended build order:** can ship anytime; no hard dependency on other works. Loosely coupled with `work-001-aid-lite/feature-002` (FR3 thin-router) — uses the dispatch-table descriptors that FR3-M1 makes structured.

### Pain-point → feature coverage

| Pain point (origin: `work-001 §2` pain #4) | Owning feature | Mechanism |
|---|---|---|
| **No progress visibility.** Skills provide almost no traceability or progress feedback; users feel disconnected and assume the process is stuck. | `feature-001-you-are-here-heartbeat` | Pure skill-body text: `[State: NAME]` print + bracket-pair floor around long operations + ASCII state-map |
