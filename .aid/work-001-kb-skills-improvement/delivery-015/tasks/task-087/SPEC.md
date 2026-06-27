# task-087: Per-domain GOOD/SHALLOW/WRONG mini-KB fixtures + test-dual-intent-self-eval.sh

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-087/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-015

**Depends on:** task-083, task-084, task-085, task-086

**Scope:**
- Prove feature-016 §6 — the dual-intent gates **fire correctly off-software** (FR-54 + FR-55).
  TEST only — no skill behavior changes here.
- **Per-domain mini-KB fixtures** (the full KBs, extending delivery-014's thin doc-set TSVs) under
  `tests/canonical/fixtures/{actback-task,dual-intent}/`, per non-software domain (data-ml, design,
  content) in two variants each:
  - a **GOOD** mini-KB (work-actionable depth + faithful essence -> must **PASS** both gates);
  - a **SHALLOW/WRONG** mini-KB (omits field types / **diverges** from a tiny fixture "source" ->
    must **FAIL** the right limb);
  - each with a matching doc-set TSV carrying its spine dimensions + a **tiny fixture "source" tree**
    for the source-confrontation stage.
- **The new `tests/canonical/test-dual-intent-self-eval.sh`** (the essence limb + source-confrontation
  fixtures) plus extended `tests/canonical/test-actback-fixtures.sh` (the per-domain GOOD/SHALLOW
  assertions). Assert: (a) probe derivation produces a **domain-appropriate** task (not "add an
  endpoint"); (b) the re-keyed owning-table presence check **fires on the domain's C5/C3/etc. doc**;
  (c) the **assertiveness** limb **FAILs the SHALLOW KB** on the missing contract; (d) the
  **essence** limb **FAILs the WRONG KB** on divergence; (e) the **GOOD KB PASSes both gates**.
- **Determinism + ASCII + HOME-pinning** per the existing suite conventions (the suite scans no real
  `$HOME`/`.aid`; pin HOME to a throwaway dir — the AID-scan-tests-must-pin-HOME lesson). Keep suites
  small + per-concern (the split-big-TEST-tasks lesson); if a single suite balloons, split per-domain.
- ASCII-only + WinPS-5.1 lint for any shipped/changed script in the suite. DBI here is the
  canonical -> `.claude` render-parity check (this delivery edits only `canonical/` sources + test
  fixtures, **not** AID's own `.aid/knowledge/*` doc content — that doc-content sync is delivery-016's).

**Acceptance Criteria:**
- [ ] Per-domain **GOOD** + **SHALLOW/WRONG** mini-KB fixtures (data-ml, design, content) land under
  `tests/canonical/fixtures/{actback-task,dual-intent}/`, each with a doc-set TSV carrying spine
  dimensions + a **tiny fixture "source" tree**. *(FR-54, FR-55, §6)*
- [ ] The fixtures prove the gates fire off-software: GOOD **PASSes both** gates; SHALLOW **FAILs**
  the assertiveness limb on the missing contract; WRONG **FAILs** the essence limb on divergence;
  probe derivation is **domain-appropriate** (not "add an endpoint"); the owning-table presence check
  fires on the domain's C5/C3 doc. *(FR-54, FR-55, §6)*
- [ ] The new `test-dual-intent-self-eval.sh` + extended `test-actback-fixtures.sh` are
  **deterministic + ASCII-only + HOME-pinned** (no real `$HOME`/`.aid` scan). *(suite conventions,
  HOME-pin lesson)*
- [ ] **DBI green** (canonical -> `.claude` render-parity); the new + affected canonical suites
  (`test-dual-intent-self-eval.sh`, actback-task, actback-fixtures) re-run green. *(section-6)*
- [ ] All section-6 quality gates pass.
