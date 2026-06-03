# task-009: Real CLEANUP body — `state-cleanup.md` (replaces the stub)

**Type:** IMPLEMENT

**Source:** feature-004-aid-cleanup → delivery-003

**Depends on:** task-001, task-002, task-003, task-007, task-008

**Scope:**
- **Replace** the delivery-001 stub no-op at
  `canonical/skills/aid-housekeep/references/state-cleanup.md` (authored by task-003) with the
  **real CLEANUP body** — step-numbered prose in the style of
  `canonical/skills/aid-summarize/references/state-*.md` (feature-004 SPEC § Description /
  Checklist UI). This is the terminal-stage body that plugs into the feature-001 interface; it is
  reachable BOTH after the SUMMARY-DELTA gate (full sequence) AND directly via `--cleanup-only`
  (Mode=cleanup-only via task-008).
- **Step 1 — scan + classify:** invoke `canonical/scripts/housekeep/cleanup-classify.sh`
  (task-007) to get the candidate list; the body does NOT reimplement scan/tier/matrix/split
  logic — it consumes the helper's output (the "deterministic logic lives in a tested bash
  helper" pattern, feature-004 SPEC § Testing).
- **Step 2 — present the tiered checklist** (feature-004 SPEC § "Checklist UI") via the host
  `AskUserQuestion` tool (in feature-001 `SKILL.md` `allowed-tools`; precedent
  `aid-summarize/references/state-manual-checklist.md`), grouped by tier — Tier-0 rows
  pre-checked `[x] path — reason`, Tier-1/2 rows unchecked `[ ] path — review: reason`, each
  annotated `(git rm)` / `(untracked)` so the user sees the deletion mechanism (NFR3). Mirror the
  established propose→confirm interaction of `/aid-discover`'s `state-generate.md`.
- **Step 3 — per-item confirm (NFR1):** the user toggles items and confirms the final selection;
  **no item is removed without appearing checked at confirm time.** Each `(i)✓/(ii)✗` work folder
  (gate=explicit-confirm from task-007) is NOT in the togglable list — it gets its own
  `AskUserQuestion` prompt that **states the discrepancy** before it may join the deletion set.
- **Step 4 — apply deletions, tracked/untracked split** (feature-004 SPEC § "Deletion
  Mechanism", AC8): partition the confirmed set into `to_git_rm[]` / `to_rm[]` using the
  per-path classification from task-007; `rm -rf` each `to_rm` path and `git rm -r --quiet` each
  `to_git_rm` path (staging deletions). **No trash directory.**
- **Step 5 — single commit, never push:** hand off the staged deletions to feature-001's
  `canonical/scripts/housekeep/branch-commit.sh` for **exactly one** commit on the
  `aid/housekeep-*` branch (e.g. `chore(housekeep): cleanup stale .aid artifacts [feature-004]`),
  **never push, never commit to `master`** (C3, NFR1; feature-001 § Git/VC Boundary).
- **Step 6 — gate output + chain:** write `**Cleanup Stage:** passed` to `## Housekeep Status`
  **only** through `canonical/scripts/housekeep/housekeep-state.sh` (never hand-edit the block),
  then CHAIN to DONE (cleanup is the terminal stage; field enum `passed | —`). Per feature-004
  SPEC § "Gate Output … Cancel-All": `passed` means "the cleanup step RAN to a user-resolved
  conclusion," not "files were deleted" — so **cancel-all / unchecked-everything → `passed` with
  NO commit** (nothing staged), and **zero candidates found → `passed` with no commit**. Cancel-all
  is NOT `stalled` (cleanup always *can* conclude); this keeps a re-run reporting "nothing to
  resume" (resume table row 6, NFR2).
- **`--cleanup-only` inputs guard** (feature-004 SPEC § "`--cleanup-only` Entry", AC10): when
  reached via Mode=cleanup-only, the body MUST NOT read or assume any KB-delta or summary
  run-state — it reads only the filesystem scan, git, `gh` (signal (i)), and each work folder's
  own `STATE.md`. It does NOT read any `**Summary Stage:**` field. The C1 predecessor gate is
  feature-001's (satisfied by the Mode=cleanup-only deliberate-skip path); this body does NOT
  re-implement the gate.
- **D2 coordination** (feature-004 SPEC § "D2 Coordination"): the body does NOT touch
  `run_generator.py` and does NOT re-litigate the already-applied `report_path=None` fix; it only
  sweeps any *residual* stray `verify-deterministic-report.json` / `verify-advisory-report.json`
  as S4 Tier-0-safe candidates (complementary to the source fix — no conflict).
- **No new design** — every step (scan→checklist→per-item confirm→git rm/rm split→single
  commit→`passed`+CHAIN; cancel-all=passed/no-commit; `--cleanup-only` input boundary; D2
  non-overlap) is dictated verbatim by feature-004 SPEC; this task slices it into the body that
  fills the feature-001 stub slot.

**Acceptance Criteria:**
- [ ] `state-cleanup.md` no longer reads as a stub no-op: it invokes `cleanup-classify.sh`
  (task-007) for candidates, presents the tiered `AskUserQuestion` checklist (Tier-0 pre-checked,
  Tier-1/2 unchecked, each annotated `(git rm)`/`(untracked)`), and acts only on the final checked
  set — it reimplements no scan/tier/matrix/split logic.
- [ ] **AC7** (UI half): safe items are checked and work folders unchecked; only offered folders
  appear; an (i)✓/(ii)✗ folder triggers its own explicit-confirm `AskUserQuestion` stating the
  discrepancy before it can be added; the active folder never appears (guaranteed upstream by
  task-007).
- [ ] **NFR1:** no candidate is removed without explicit confirmation — the checklist is always
  shown before any `rm`/`git rm`; an unconfirmed/unchecked item is never deleted.
- [ ] **AC8:** confirmed tracked items are removed via `git rm -r` (staged, recoverable) and
  untracked cruft via `rm -rf`, committed in **exactly one** `branch-commit.sh` commit on the
  `aid/housekeep-*` branch, with **no push and no commit to `master`**.
- [ ] Gate output matches the SPEC table: ≥1 confirmed item → `**Cleanup Stage:** passed` + one
  commit + CHAIN→DONE; **cancel-all / unchecked-everything → `passed` with NO commit**; **zero
  candidates → `passed` with no commit** — all written only via `housekeep-state.sh`; cancel-all
  is `passed` (never `stalled`).
- [ ] `--cleanup-only` (Mode=cleanup-only) path reads no KB/summary run-state (no
  `**Summary Stage:**`); its only inputs are the filesystem scan, git, `gh`, and each work
  folder's `STATE.md`.
- [ ] The body does not touch `run_generator.py` (D2 fix untouched) and sweeps only residual
  stray verify reports as S4 candidates.
- [ ] The deterministic logic this body wires is covered by task-007's classification suites and
  the cross-stage transitions by the integration TEST (task-010); the LLM-authored prose body
  itself is verified by the render/self-test gate (no runtime behavioral test of prose, per
  `test-landscape.md` no-E2E-tier policy).
- [ ] All §6 quality gates pass; build/render passes (CI render-drift re-emits the body to all 5
  profiles, no renderer edit); all existing tests pass.
