# task-082: D-014 doc-set TSV fixtures + safeguard-fires-off-software assertions + DBI

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-082/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-014

**Depends on:** task-081

**Scope:**
- Prove feature-016 **Change 2 (FR-53)** makes the safeguard fire off-software, deterministically,
  with the software seed unperturbed. TEST only — no skill behavior changes here.
- **D-014's own minimal doc-set TSV fixtures** (the substrate this delivery's gate asserts against,
  **not** the full mini-KBs — those are delivery-015's): author
  `tests/canonical/fixtures/actback-task/data-ml.tsv` and `.../design.tsv` —
  `filename<TAB>owner<TAB>presence<TAB>spine-dimension` rows (per task-080's substrate decision) that
  the re-keyed `_doc_expects_class` + the C9-derived selector fire on.
- **Safeguard-fires-off-software assertions** in `tests/canonical/test-actback-task.sh`: on the
  `data-ml.tsv` / `design.tsv` doc-sets, assert `kb-actback-task.sh` emits a **domain-appropriate**
  representative task (e.g. "add a feature/column to «pipeline/dataset»", "add a token/component
  variant") — **NOT** "add an endpoint" — and the operational-class **presence check is non-empty**,
  firing on whatever doc realizes the owning dimension (C5 -> Contracts, C3 -> Conventions, C2 ->
  Conventions/Parts, C7 -> Gotchas). The gate asserts **only** the owning-table + task-selector
  behavior on these TSVs; full GOOD/SHALLOW/WRONG mini-KB PASS/FAIL assertions defer to delivery-015.
- **Determinism + software-seed byte-stability:** assert same doc-set + same C9 doc -> byte-identical
  task spec; assert the **byte-stable software seed** and existing TSV-consumers stay green (the
  matrix seed-consistency check is the regression guard). Keep suites small + per-concern (the
  split-big-TEST-tasks lesson).
- **DBI / render-parity:** run the canonical -> `.claude` render-parity check (this delivery edits
  only `canonical/` sources + test fixtures, **not** AID's own `.aid/knowledge/*` doc content — the
  doc-content DBI sync is delivery-016's). ASCII-only + WinPS-5.1 lint for the changed
  `kb-actback-task.sh` re-runs green.

**Acceptance Criteria:**
- [ ] Minimal `data-ml.tsv` + `design.tsv` doc-set fixtures (with the `spine-dimension` substrate)
  land under `tests/canonical/fixtures/actback-task/`. *(FR-53)*
- [ ] On those non-software doc-sets, `kb-actback-task.sh` emits a **domain-appropriate** task (NOT
  "add an endpoint") and a **non-empty** operational-class presence check firing on the owning
  dimension's doc (C5/C3/C2/C7). *(FR-53)*
- [ ] **Determinism + byte-stability:** same doc-set + C9 doc -> byte-identical task; the byte-stable
  software seed + existing TSV-consumers stay green. *(FR-53, NFR-3)*
- [ ] **DBI green** (canonical -> `.claude` render-parity); **ASCII-only + WinPS-5.1** lint green for
  the changed `kb-actback-task.sh`. *(section-6)*
- [ ] The affected canonical suites (actback-task, actback-fixtures, matrix) re-run green.
  *(section-6)*
- [ ] All section-6 quality gates pass.
