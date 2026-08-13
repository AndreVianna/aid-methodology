# task-011: On-disk data rename of the field-bearing KB docs and fixtures

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-002

**Depends on:** task-010

**Scope:** perform the full on-disk data rename `contracts:` → `review-criteria:` that feature-001 SPEC
§6 assigns to "feature-002 (the on-disk data pass)". Three sets:
- The **18** KB docs on disk that carry the key (of 22; 4 — `README.md`, `STATE.md`,
  `capability-inventory.md`, `release-tracking.md` — have no key and are untouched).
- The **18 canonical "carry-as-data" files** (feature-001 SPEC line 330), **which an earlier draft of
  this task dropped entirely** — verified `grep -rl "contracts:" canonical --include=*.md --include=*.yml
  | grep -vE "build-|migrate-kb|kb-authoring/"`:
  - the 14 `canonical/aid/templates/knowledge-base/*.md` doc templates (their frontmatter is the emitted
    KB doc's — rename the placeholder key so emitted docs carry `review-criteria:`);
  - `canonical/aid/templates/feature-inventory.md`, `canonical/aid/templates/state-machine-chaining.md`,
    `canonical/aid/templates/reviewer-ledger-schema.md` (populated — its own declaration);
  - the `contracts:` mention in the `canonical/aid/templates/graph/relationship-schema.yml` comment.
- The **4** test fixtures under `tests/canonical/fixtures/**` (dual-intent ×2, kb-essence `schemas.md`
  ×2) — only if a consuming test reads the field name; otherwise leave under the coexistence parser and
  record that decision.

Depends on task-010 so `reviewer-ledger-schema.md`'s and the KB docs' criteria **content** is settled
(task-010) before the key is renamed here — the two tasks touch the same files, and the edge serializes
them.

**NOT in scope here:** the emitters (5), the migration parser, and the 4 `kb-authoring/` definition docs
— those are feature-001/task-006 and task-002.

**Acceptance Criteria:**
- [ ] The 18 field-bearing KB docs are renamed; the 4 field-less docs untouched.
- [ ] **All 18 canonical carry-as-data files** are renamed (14 knowledge-base templates + feature-inventory
      + state-machine-chaining + reviewer-ledger-schema + the relationship-schema.yml comment) — verified
      by `grep -rl "contracts:" canonical --include=*.md --include=*.yml | grep -vE "build-|migrate-kb|kb-authoring/"`
      returning **only** legitimately-remaining hits (none in this set).
- [ ] The 4 fixtures are renamed or explicitly left (with the reason) per their consuming test.
- [ ] No file gains the key in the drift sense; the rename adds no new key.
- [ ] The KB index / relationships builders still parse; all §6 quality gates pass.
