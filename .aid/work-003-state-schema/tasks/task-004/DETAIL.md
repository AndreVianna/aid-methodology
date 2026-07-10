# task-004: Emit/update frontmatter in the STATE writers

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-003

**Scope:**
- **New frontmatter-writer path (not just a repoint).** `writeback-state.sh` today has six write
  modes covering several BODY sections (`--pipeline`→Pipeline State, `--field`→Task State /
  `### Tasks lifecycle`, `--findings`→Quick Check Findings, `--block`→Delivery Gate,
  `--lifecycle`→Delivery Lifecycle, `--append-issue`→issues) — but **none writes a YAML frontmatter
  block**, and none writes the header-blockquote fields (`Started` / `Minimum Grade` /
  `User Approved`). Add a frontmatter-writer path so the machine fields are emitted/updated in the
  frontmatter atomically (surgical YAML-block rewrite; body byte-unchanged), and redirect the
  existing modes' machine fields there. Edit the **canonical** sources (NOT the generated `.claude/aid/...` mirror):
  - `canonical/aid/scripts/execute/writeback-state.sh` (existing modes: `--pipeline`, task
    `--field`, `--findings`, `--block`, `--lifecycle`, `--append-issue`) → redirect to the
    frontmatter; preserve enum validation + sentinel-lock atomicity; add fields for
    `started`/`minimum_grade`/`user_approved`/`pipeline.*` as needed.
  - `canonical/aid/scripts/summarize/writeback-state.sh` — write the KB run-state frontmatter
    (`kb_status`/`kb_grade`/`summary_approved`/`last_summary`/`last_kb_review`).
  - **The pipeline-starting skills must author the pipeline block at scaffold time:** the shortcut
    engine (`shortcut-engine.md` Step 4 "Scaffold STATE.md") writes `pipeline.path` +
    `pipeline.initiator = {name}` (the shortcut skill); `aid-describe` FIRST-RUN writes
    `pipeline.path` + `pipeline.initiator: aid-describe`. Also `started`/`minimum_grade`/
    `user_approved` at scaffold.
  - The hand-authoring skill reference files under `canonical/skills/*/references/` that write
    STATE grade/approval/status (aid-discover, aid-summarize, aid-update-kb, aid-execute,
    aid-describe, aid-housekeep) — update their write instructions to target the frontmatter block.
- Render: run `python .claude/skills/generate-profile/scripts/run_generator.py` to render
  `canonical/` into all 5 `profiles/`, resync the dogfood `.claude/`, and confirm
  `tests/canonical/test-dogfood-byte-identity.sh` passes.
- Gated behind task-003 so writers never emit a format the shipped reader cannot yet read.

**Acceptance Criteria:**
- [ ] A frontmatter-writer path exists (beyond the Pipeline-State subset); every writer mode updates the correct frontmatter field and leaves the markdown narrative body byte-unchanged (verified by before/after body diff) (traces to BLUEPRINT gate criteria #5, #7).
- [ ] The pipeline-starting skills (shortcut engine + aid-describe) author `pipeline.{path,initiator}` (+ `started`/`minimum_grade`/`user_approved`) at scaffold time (traces to gate criteria #13).
- [ ] Enum validation and lock/atomicity semantics preserved (no partial-write corruption).
- [ ] A STATE file written by the updated writers is read back correctly by both twins from task-002.
- [ ] `run_generator.py` re-rendered; `tests/canonical/test-dogfood-byte-identity.sh` passes (canonical → profiles + dogfood in sync) (traces to BLUEPRINT gate criteria #8).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
