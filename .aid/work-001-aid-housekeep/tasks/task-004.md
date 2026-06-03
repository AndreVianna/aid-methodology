# task-004: `state-kb-delta.md` — agent-driven KB-DELTA body (inspect → scope → delegate → gate)

**Type:** IMPLEMENT

**Source:** feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-001, task-002, task-003

**Scope:**
- Author `canonical/skills/aid-housekeep/references/state-kb-delta.md` (fills the feature-001
  stub) as **agent-driven, step-numbered prose** in the style of
  `canonical/skills/aid-summarize/references/state-*.md` (feature-002 SPEC § "Feature Flow (the
  KB-DELTA state body)", Steps 1–6). The KB reconciliation is **analysis the agent performs**,
  not deterministic logic — this task ships **no `canonical/scripts/`** (no `detect-delta.sh`,
  no `scope-delta.sh`, no path→doc map, no `Approved-At-Commit:` field, no `/aid-discover` edit).
- **On entry** — write `**State:** KB-DELTA`, `**Stage Status:** running`, `**Last Run:**` via
  `housekeep-state.sh`; ensure the `aid/housekeep-*` branch via `branch-commit.sh --ensure-branch`
  and record `**Branch:**` (feature-002 SPEC § "On entry"). Never hand-edit `## Housekeep Status`.
- **Step 1 — read the hint (C2).** Read `**Last KB Review:**` from `.aid/knowledge/STATE.md`;
  optionally `git fetch origin master 2>/dev/null || true` and, on success, `git log/diff` since
  that date as a **focus hint only**. Offline → say so and proceed from local/content; **no
  offline-permission prompt, no hard gate** (feature-002 SPEC § "Offline Behavior").
- **Step 2 — inspect repo content vs KB claims (AC1).** Autonomously read the actual repo
  content (code/data/docs) and reconcile against each KB doc's claims, prioritizing the
  git-hinted areas then widening (catch drift a git-only pass would miss). Plan the corrections.
  No drift found → print `✓ KB current …`, write `**KB Stage:** skipped`, no dispatch, no commit,
  CHAIN (AC4; feature-002 SPEC § "No-Drift No-Op").
- **Step 3 — confirm-and-adjust the scope (AC2, NFR3).** Present the affected docs + corrections
  (`[1] Confirm / [2] Adjust / [3] Cancel`; feature-002 SPEC § "Scope Proposal + Confirm"). `[3]`
  → `**KB Stage:** stalled` + `**Stall Reason:** KB refresh scope cancelled` + PAUSE.
- **Step 4 — delegate (AC3).** Synthesize an `**Impact:** Required` Q&A entry in
  `.aid/knowledge/STATE.md` `## Q&A (Pending)` in canonical Style A (`coding-standards.md §12`;
  `### Q{N}` = next integer after highest existing), carrying the **user-confirmed affected-doc
  set** from Step 3; then invoke `/aid-discover` to drive its **existing** targeted re-entry
  (REVIEW → Q-AND-A → FIX → APPROVAL). **Owner resolution is `/aid-discover`'s job** (its
  `owns-<agent>` accessor) — this body names docs, not owners. Sub-agent dispatch runs **under
  feature-001's `## Dispatch Protocol (L1+L2+L3)`** already on `SKILL.md` (inherit, do not
  re-implement); ETA band from `canonical/templates/rough-time-hints.md`
  (feature-002 SPEC § "/aid-discover Delegation").
- **Steps 5–6 (re-entry).** Read back `.aid/knowledge/STATE.md`: fresh `**User Approved:** yes`
  newer than this run's start → Step 6: write `**KB Stage:** passed`, commit via
  `branch-commit.sh`, CHAIN to SUMMARY-DELTA. No fresh approval → `**KB Stage:** stalled` +
  `**Stall Reason:** KB re-approval declined` + PAUSE.
- All `## Housekeep Status` writes go through `housekeep-state.sh`; all commits through
  `branch-commit.sh`; never hand-edit the status block; **no edit to any `/aid-discover` file**
  (feature-002 SPEC § "Cross-feature contracts honored").

**Acceptance Criteria:**
- [ ] AC1: the agent inspects actual repo content (using `Last KB Review` + git as an optional
  hint, not a boundary) and identifies the drifted KB docs/areas, including drift not
  attributable to a recent git change.
- [ ] AC2: the affected docs + corrections are shown for confirm-and-adjust before any KB change
  (NFR3 transparency).
- [ ] AC3: the body synthesizes an `**Impact:** Required` Q&A entry and drives `/aid-discover`'s
  targeted re-entry → REVIEW → APPROVAL to a fresh `**User Approved:** yes`; on that fresh
  approval Step 6 writes `**KB Stage:** passed`, commits once via `branch-commit.sh`, and CHAINs
  to SUMMARY-DELTA.
- [ ] AC4 (no-drift): KB already matches the repo → reports "current," dispatches no sub-agents,
  makes no commit, writes `**KB Stage:** skipped`, and CHAINs.
- [ ] AC5 (offline tolerance): a failed `git fetch` does not hard-fail and triggers no
  offline-permission prompt — the body says so and proceeds from local/content inspection.
- [ ] Declined/no-resolution → `**KB Stage:** stalled` + `**Stall Reason:**` + PAUSE
  (feature-001 resume banner; re-run resumes at KB-DELTA via State Detection row 3 — AC9).
- [ ] No new scripts and no `/aid-discover` edits are introduced; `**KB Stage:**` is written only
  through `housekeep-state.sh` and commits only through `branch-commit.sh`.
- [ ] The deterministic state transitions this body wires are verified by dogfooding +
  render-drift CI / generator self-tests; there is no bespoke integration test (AID has no E2E
  tier, per test-landscape.md). The LLM-authored prose body has no runtime behavioral test, and
  the agent reconciliation has no unit suite (it is analysis, not deterministic logic).
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
