# task-009: `state-kb-delta.md` — KB-DELTA body (detection → scope → delegation → writeback)

**Type:** IMPLEMENT

**Source:** feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-004, task-005, task-006, task-007, task-008

**Scope:**
- Author `canonical/skills/aid-housekeep/references/state-kb-delta.md` (fills the feature-001
  stub), step-numbered prose in the style of `canonical/skills/aid-summarize/references/state-*.md`
  (feature-002 SPEC § "Feature Flow (the KB-DELTA state body)", Steps 1–6).
- Step 1 — run `detect-delta.sh`: exit 10 / empty affected-doc set → print `✓ KB current …`,
  write `**KB Stage:** skipped`, no dispatch, no commit, CHAIN (AC5; feature-002 SPEC §
  "No-Delta No-Op"). Exit 3 → surface the explicit offline-permission prompt (`[1] proceed
  offline / [2] abort`); `[1]` re-invokes `detect-delta.sh --offline-ok`, `[2]` → `**KB Stage:**
  stalled` + PAUSE (AC3; § "Offline / Bootstrap Behavior").
- Step 2 — run `scope-delta.sh` (path→doc map → affected docs → owning agents).
- Step 3 — confirm-and-adjust the proposed scope with the user (`[1] Confirm / [2] Adjust /
  [3] Cancel`; feature-002 SPEC § "Scope Confirmation Flow"; NFR3). `[3]` → `**KB Stage:**
  stalled` + `**Stall Reason:** KB refresh scope cancelled` + PAUSE.
- Step 4 — synthesize a `**Impact:** Required` Q&A entry in `.aid/knowledge/STATE.md` `## Q&A
  (Pending)` in canonical Style A (`coding-standards.md:541-546`; `### Q{N}` = next integer
  after highest existing), carrying the user-confirmed affected-doc/owning-agent set verbatim
  from `scope-delta.sh`; then invoke `/aid-discover` to drive its targeted re-entry
  (GENERATE/targeted → REVIEW → Q-AND-A → FIX → APPROVAL). Sub-agent dispatch runs **under
  feature-001's `## Dispatch Protocol (L1+L2+L3)`** already on `SKILL.md` (inherit, do not
  re-implement); ETA band from `canonical/templates/rough-time-hints.md`
  (feature-002 SPEC § "/aid-discover Delegation").
- Steps 5–6 (re-entry) — read back `.aid/knowledge/STATE.md`: fresh `**User Approved:** yes`
  newer than this run's start → Step 6: write `**Approved-At-Commit:**` = `git rev-parse
  origin/master` (post-fetch; feature-002 SPEC § "Baseline-ref reconciliation"), `**KB Stage:**
  passed`, commit via `branch-commit.sh`, CHAIN to SUMMARY-DELTA. No fresh approval →
  `**KB Stage:** stalled` + `**Stall Reason:** KB re-approval declined` + PAUSE.
- All `## Housekeep Status` writes go through `housekeep-state.sh`; all commits through
  `branch-commit.sh`; never hand-edit the status block (feature-002 SPEC § "Cross-feature
  contracts honored").

**Acceptance Criteria:**
- [ ] AC1: a delta is detected and the changed paths from `X..origin/master` are reported.
- [ ] AC4: scope is shown for confirm/adjust, then only the owning sub-agents are dispatched
  through `/aid-discover` REVIEW→APPROVAL, ending in a fresh `**User Approved:** yes`.
- [ ] AC5: no delta (or all-KB-self-edit) → reports "current," dispatches no sub-agents, makes
  no commit, writes `**KB Stage:** skipped`, and CHAINs.
- [ ] AC3: fetch failure surfaces the explicit offline-permission prompt; without permission the
  stage does not diff and stalls; with `[1]` it re-runs `--offline-ok`.
- [ ] On fresh approval, Step 6 writes `**Approved-At-Commit:** = git rev-parse origin/master`
  and `**KB Stage:** passed`, commits once via `branch-commit.sh`, and CHAINs to SUMMARY-DELTA
  (D1).
- [ ] Declined/no-resolution → `**KB Stage:** stalled` + `**Stall Reason:**` + PAUSE
  (feature-001 resume banner; re-run resumes at KB-DELTA via State Detection row 3 — AC9).
- [ ] Unit coverage of the new deterministic logic lands with its scripts (task-006/007); the
  deterministic state transitions this body wires are exercised by the integration TEST
  (task-010); the LLM-authored prose body itself is verified by the render/self-test gate
  (task-011), consistent with the no-E2E-tier policy (test-landscape.md) — there is no runtime
  behavioral test of the prose.
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
