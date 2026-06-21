# task-004: Delete rules machinery + reconcile methodology into root files

**Type:** REFACTOR

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-002

**Scope:**
- Delete the `canonical/rules/` source directory (the retired `aid-methodology.mdc` + `aid-review.mdc` rules; feature-002 FR3 / A1).
- Delete the `[[extras.rules]]` configuration **and the top-level `rules_dir` key** from `profiles/cursor.toml` and `profiles/antigravity.toml` (the `[extras]` rules-folder mechanism config + its dir key).
- Confirm the two retired rules' **always-on substance** already lives in the committed `CLAUDE.md` / `AGENTS.md` `AID:BEGIN/END` region (Finding G1 — the root context file is install-merged, NOT a generator output). If it is **not** already present, reconcile it there as a **one-time content edit** to the committed root context files — NOT a new generator step (feature-002 Finding G1 / A1: no "write-root-file" generator pass is added).
- **Boundary (load-bearing):** this task owns `canonical/rules/` + the extras **config** removal + the root-file content reconciliation. The emitter **code** deletion (`_render_cursor_extras` / `_build_trigger_frontmatter` / `_split_rule_body`) is owned by **task-005**. The rendered rules-folder **outputs** (`profiles/cursor/.cursor/rules/`, `profiles/antigravity/.agent/rules/`) are removed by the re-render in **task-006**.

**Acceptance Criteria:**
- [ ] `canonical/rules/` is deleted (no rules source dir remains).
- [ ] `[extras.rules]` / `[[extras.rules]]` **and the top-level `rules_dir` key** are removed from both `profiles/cursor.toml` and `profiles/antigravity.toml`.
- [ ] The retired rules' methodology/review always-on substance is present in the committed `CLAUDE.md` / `AGENTS.md` `AID:BEGIN/END` region (confirmed already present, or reconciled there by a one-time content edit).
- [ ] No new "write root file" generator step is added (Finding G1 — the root file remains install-lib-merged, not generator-emitted).
- [ ] REFACTOR defaults: all tests pass before AND after; no behavior change to surviving outputs (this task does not itself re-render — task-006 does).
- [ ] All §6 quality gates pass.
