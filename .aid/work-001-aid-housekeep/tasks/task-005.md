# task-005: Stub-no-op bodies — `state-summary-delta.md` + `state-cleanup.md`

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** task-001, task-004

**Scope:**
- Author `canonical/skills/aid-housekeep/references/state-summary-delta.md` and
  `canonical/skills/aid-housekeep/references/state-cleanup.md` as **inert stub no-op bodies**
  per feature-001 SPEC § "Incremental-delivery stub no-op (skeleton contract)".
- Each stub body: writes `**Stage Status:** skipped` and its own `**<X> Stage:** skipped`
  (`**Summary Stage:** skipped` / `**Cleanup Stage:** skipped`) to `## Housekeep Status` via
  `housekeep-state.sh`, does **no work**, does **not pause**, makes **no commit**, and **CHAINs
  straight onward** (SUMMARY-DELTA → CLEANUP → DONE), so a KB-refresh run terminates cleanly at
  DONE.
- The stubs are distinct from a runtime `skipped` (a real, fully-implemented stage deciding to
  skip): note in the body that a later delivery replaces the stub with the feature's real
  logic (003 = summary, 004 = cleanup).
- These bodies fill the feature-001 SPEC § Layers & Components stub slots; the substantive
  bodies are owned by feature-003 / feature-004 in later deliveries.

**Acceptance Criteria:**
- [ ] `state-summary-delta.md` writes `**Summary Stage:** skipped` + `**Stage Status:**
  skipped` and CHAINs to CLEANUP with no work, no pause, no commit.
- [ ] `state-cleanup.md` writes `**Cleanup Stage:** skipped` + `**Stage Status:** skipped` and
  CHAINs to DONE with no work, no pause, no commit.
- [ ] Each body explicitly documents that it is a stub no-op to be replaced by its owning
  feature in a later delivery (no new design — verbatim per the stub-no-op contract).
- [ ] Both bodies write only through `housekeep-state.sh` (never hand-edit `## Housekeep
  Status`).
- [ ] All §6 quality gates pass; build/render passes; all existing tests pass.
