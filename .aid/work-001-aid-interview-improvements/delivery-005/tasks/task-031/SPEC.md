# task-031: Human-gated flag-not-overwrite reconciliation flow

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** task-030

**Scope:**
- The authority-preserving reconciliation flow that closes the conformance lane in
  `canonical/skills/aid-housekeep/references/state-kb-delta.md`, consuming the carried-forward divergence
  set (task-030's `placeholder-resolved` / `code-ahead` / `contradiction` deltas). Author it by reusing
  KB-DELTA's existing present-scope gate (Step 3) and Required-Q&A pattern (Step 4), with the action
  INVERTED from overwrite to choose-and-flag:
  1. **Present the divergence set** (PAUSE-FOR-USER-DECISION), grouped by class, with the three choices per
     item: `[1] Evolve the design` (deliberately update the forward-authored doc to match code) /
     `[2] Fix the code` (raise a code task; design held; doc untouched) / `[3] Accept / defer` (record as a
     known divergence). State that the design stays authoritative until the human reconciles.
  2. **Write a Required Q&A entry** to `.aid/knowledge/STATE.md ## Q&A (Pending)` (Style A, the exact format
     KB-DELTA Step 4 uses) recording the divergence set + the per-item human choice. The entry carries the
     reconciliation, never an auto-applied edit.
  3. **Apply the human choice (human-gated):** "Evolve the design" -> the human approves and the doc is
     updated via `/aid-discover` targeted re-entry (the existing `Impact: Required` -> targeted-re-entry
     path) naming that doc -- the ONLY path by which a forward-authored doc is edited from as-built, and only
     with explicit human approval. "Fix the code" -> raise a code task; doc untouched. "Accept / defer" ->
     record as known; doc untouched.
- **Author the flag-never-overwrite invariant explicitly:** the check's output is a divergence flag, NEVER a
  doc edit; it writes ONLY `.aid/.temp/conformance/` (shadow extraction + divergence report) and the
  Required Q&A entry; the forward-authored doc's bytes, its `source: forward-authored` marker, and its f007
  `current` verdict are UNCHANGED by the check. Until a human chooses, the design is unchanged -- the
  design->code-until-reconciled invariant (NFR-5 / AC-6) made operational. Authority stays design->code.
- Edit the canonical source form; host-tree propagation is task-032. ASCII-only.
- **Out of scope:** the carve (task-029); the extract-and-diff mechanism + classifier (task-030); the
  `output_root` parameter (task-028); the render (task-032); verification (task-034).

**Acceptance Criteria:**
- [ ] On a non-empty divergence set the lane PAUSES, presents the set grouped by class with the three choices (evolve-design / fix-code / accept-defer), and states the design stays authoritative until reconciled. *(AC-6, NFR-5; gate criteria 1, 2)*
- [ ] A Required Q&A entry (Style A) is written to `.aid/knowledge/STATE.md ## Q&A (Pending)` recording the divergence set + per-item choice; the entry carries the reconciliation, never an auto-applied edit. *(AC-6; gate criterion 1)*
- [ ] The check NEVER writes `.aid/knowledge/*.md`: it writes only `.aid/.temp/conformance/` + the Q&A entry; the forward-authored doc bytes, its `source` marker, and its f007 `current` verdict are unchanged by the check. The ONLY path that edits the doc is an explicit human "evolve the design" choice via `/aid-discover` targeted re-entry. *(AC-6, NFR-5; gate criteria 1, 2, 3)*
- [ ] Until a human choice is applied, the forward-authored design is byte-unchanged (flag, never reconcile) -- authority stays design->code. *(NFR-5, C-4; DoD V1/V2)*
- [ ] ASCII-only; skill reference is prose-executed (no inline unit test; IMPLEMENT unit-test default overridden -- the flag-not-overwrite + human-gated behavior are exercised by task-034). All REQUIREMENTS.md §6 quality gates pass (heavy gates at task-034).
