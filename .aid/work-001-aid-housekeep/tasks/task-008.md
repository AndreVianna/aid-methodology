# task-008: D1 edit — `Approved-At-Commit:` writeback in `/aid-discover` approval

**Type:** IMPLEMENT

**Source:** feature-002-kb-delta-refresh → delivery-001

**Depends on:** —

**Scope:**
- Edit `canonical/skills/aid-discover/references/state-approval.md` Step 3, the
  `**[1] Approved:**` bullet (currently `state-approval.md:23`) to **also** record
  `**Approved-At-Commit:**` going forward (dependency D1; feature-002 SPEC § "Approval Baseline
  Writeback — this feature's own + the D1 edit", § Components / Scripts "Edited by THIS
  feature").
- Add the single line specified verbatim in feature-002 SPEC: `Also set
  **Approved-At-Commit:** to the approved commit SHA (git rev-parse HEAD) — replace the line if
  present, else insert after **Last KB Review:** (idempotent; back-compatible — older KBs simply
  lack the line until the next approval, which is the AC2 bootstrap path).`
- The field joins the existing approval anchors in the `### Discovery State` header block of
  `.aid/knowledge/STATE.md` as a `> **Field:** value` blockquote line, matching its siblings
  `> **User Approved:**` / `> **Last KB Review:**` (feature-002 SPEC § "S-1. Approval baseline").
- This is a body-text edit to an existing rendered skill; the renderer re-emits it to all 5
  profiles automatically (no renderer edit). No new design — the line is dictated by the SPEC.

**Acceptance Criteria:**
- [ ] `state-approval.md` Step 3 `**[1] Approved:**` bullet records `**Approved-At-Commit:**` =
  `git rev-parse HEAD` as a new behavior of the discover approval path, idempotently (replace
  the line if present, else insert after `**Last KB Review:**`).
- [ ] A unit/self-test asserts the writeback's idempotency (running it twice yields one
  `**Approved-At-Commit:**` line; insert-after-`**Last KB Review:**` when absent; replace-in-place
  when present).
- [ ] Back-compatible: a KB lacking the field is unaffected until the next approval (the AC2
  bootstrap path); the rest of the discover approval flow behaves as before.
- [ ] The `/aid-discover` self-tests / approval flow remain green after the edit (cross-cutting
  Risk #1 mitigation).
- [ ] All §6 quality gates pass; build/render passes (CI render-drift); all existing tests pass.
