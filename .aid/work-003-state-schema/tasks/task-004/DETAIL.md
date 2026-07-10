# task-004: Emit/update frontmatter in the STATE writers

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-003

**Scope:**
- Update the STATE writers to write/update machine-parsed fields in the frontmatter block
  atomically, without corrupting the markdown narrative body. Edit the **canonical** sources
  (NOT the generated `.claude/aid/...` mirror):
  - `canonical/aid/scripts/execute/writeback-state.sh` (all modes: `--pipeline`, task
    `--field`, `--findings`, `--block`, `--lifecycle`, `--append-issue`) — preserve enum
    validation and sentinel-lock atomicity.
  - `canonical/aid/scripts/summarize/writeback-state.sh` — KB grade/approval + Summarization
    History.
  - The hand-authoring skill reference files under `canonical/skills/*/references/` that
    write STATE grade/approval/status (aid-discover, aid-summarize, aid-update-kb,
    aid-execute, aid-describe, aid-housekeep) — update their write instructions to target
    the frontmatter block.
- Render: run `python .claude/skills/generate-profile/scripts/run_generator.py` to render
  `canonical/` into all 5 `profiles/`, resync the dogfood `.claude/`, and confirm
  `tests/canonical/test-dogfood-byte-identity.sh` passes.
- Gated behind task-003 so writers never emit a format the shipped reader cannot yet read.

**Acceptance Criteria:**
- [ ] Every writer mode updates the correct frontmatter field and leaves the markdown narrative body byte-unchanged (verified by before/after body diff) (traces to BLUEPRINT gate criteria #5, #7).
- [ ] Enum validation and lock/atomicity semantics preserved (no partial-write corruption).
- [ ] A STATE file written by the updated writers is read back correctly by both twins from task-002.
- [ ] `run_generator.py` re-rendered; `tests/canonical/test-dogfood-byte-identity.sh` passes (canonical → profiles + dogfood in sync) (traces to BLUEPRINT gate criteria #8).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
