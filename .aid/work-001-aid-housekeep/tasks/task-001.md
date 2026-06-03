# task-001: Housekeep run-state — `## Housekeep Status` section + `housekeep-state.sh`

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** —

**Scope:**
- Add a `## Housekeep Status` section to the work-area state template
  `canonical/templates/work-state-template.md`, authored as a key-value block in the exact
  `**Field:** value` shape used by `## Knowledge Summary Status` in `.aid/knowledge/STATE.md`
  (one `**Field:**` per line, grep-recoverable) — fields per feature-001 SPEC § C-2 table:
  `**State:**`, `**Stage Status:**`, `**Branch:**`, `**Mode:**`, `**Stall Reason:**`,
  `**Last Run:**`, `**KB Stage:**`, `**Summary Stage:**`, `**Cleanup Stage:**`
  (feature-001 SPEC § "C-1. Where run-state lives", § "C-2. `## Housekeep Status` fields").
- Implement helper `canonical/scripts/housekeep/housekeep-state.sh` (new
  `canonical/scripts/housekeep/` directory) that reads/writes individual `**Field:**` lines in
  the `## Housekeep Status` block and resolves the resume target from the block contents —
  the deterministic State-Detection logic (feature-001 SPEC § "Resume detection (the re-entry
  table)", rows 1–6, and § Layers & Components `housekeep-state.sh` bullet). Mirror the role
  and bash conventions of `canonical/scripts/summarize/stale-check.sh` and the project bash
  style in `.aid/knowledge/coding-standards.md`; arg/usage error → exit 2 (read-setting.sh
  convention).
- Place the script under `canonical/scripts/housekeep/` per `.aid/knowledge/module-map.md`
  layout; no `yq`/`python` dependency (bash + grep/sed only).

**Acceptance Criteria:**
- [ ] `## Housekeep Status` section exists in `canonical/templates/work-state-template.md` with
  all nine fields from the C-2 table in the `**Field:** value` shape.
- [ ] `housekeep-state.sh` can write a named field, read it back verbatim, and is idempotent
  (writing a field that already exists replaces its line rather than duplicating).
- [ ] `housekeep-state.sh` resolves the correct resume target for each of the six re-entry rows
  (feature-001 SPEC re-entry table), including the `--cleanup-only` Mode and the
  `**State:** DONE` "nothing to resume" no-op (row 6).
- [ ] A canonical unit suite `tests/canonical/test-housekeep-state.sh` (auto-discovered by the
  `tests/canonical/test-*.sh` glob in `tests/run-all.sh`, sourcing `tests/lib/assert.sh`)
  drives the round-trip write/read and asserts the resume target for all six rows.
- [ ] All §6 quality gates pass (NFR4/NFR5: deterministic, CI-wired); build/render passes;
  all existing tests pass.
