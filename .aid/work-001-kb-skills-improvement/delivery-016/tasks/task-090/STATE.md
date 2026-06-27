# Task State -- task-090

> **Task:** task-090
> **Delivery:** delivery-016
> **Work:** work-001-kb-skills-improvement

---

## Task State

- **State:** Done
- **Review:** Pending
- **Elapsed:** ~35m
- **Capstone result:** Intent 1 (assertiveness) PASS (10/10 work probes STATED ~100%); Intent 2 (essence) initially caught 1 real [FIDELITY] divergence (TB-001: Contract E over-claimed "every shipped canonical script" vs the 20-of-34 work-critical subset) — the engine working as designed; fixed by a one-line scoping correction (validation-only, uncommitted) -> Intent 2 now PASS (zero divergence). Signature-exception regression CLOSED (host-tool matrix + exit-codes resolve STATED, were a load-bearing REACH pre-D-016). Thresholds (>=90%) HOLD, §8 calibration resolved. Build/render-parity green (DBI 559/0, dual-intent 63/0). `.aid/knowledge` doc-content stays uncommitted per the owner's validation-only decision.
- **Notes:** Capstone dual-intent dogfood RUN live on AID's depth-restored on-disk KB
  (validation-only; `.aid/knowledge/` NOT committed per owner). Intent 1 (Blind
  Work-Simulation / assertiveness) = PASS; Intent 2 (Blind Reconstruction +
  Source-Confrontation / essence) = FAIL on ONE [HIGH] [FIDELITY] Divergence (Contract E
  completeness over-claim — a task-089 re-injection WORDING defect the engine correctly
  SURFACED, not an engine defect). Build/hygiene all green. See ## Notes + ledger
  `.aid/.temp/review-pending/d016-dogfood.md`.

---

## Notes

### Probe derivation (kb-dual-intent-probes.sh, doc-set = software+methodology, 21 docs, K=medium)
- `work` -> 10 work probes WP-001..010 spanning C5/C2/C3/C6/C9; nouns seeded from AID's REAL
  C9 docs (capability-inventory.md headings: Pipeline capabilities, On-demand capabilities,
  Typical path; feature-inventory.md). Domain-appropriate (no "endpoint" nonsense).
- `essence` -> 15 essence probes EP-001..015 spanning C0-C9+D; real glossary terms
  (AID_HOME, Agent tier model, CODE home, bare-box ethos), real capabilities, real decisions
  (D1 single-source render, D2 deterministic dependency-free tooling).
- DETERMINISTIC confirmed (two identical `work` runs -> byte-identical sha256). PROBE-CACHE +
  PROBE-EXTEND sentinels emitted. Minor: the heading extractor also picks a few structural
  headings ("Contents", "Change Log") as probe nouns — non-blocking; the PROBE-EXTEND
  human-confirm hook exists to prune these, and the load-bearing probes are sound.

### Intent 1 — Blind Work-Simulation (assertiveness + quality) : PASS
- All 10 work probes plan to a complete, correct, convention-honoring outline using ONLY the KB.
- Zero [HIGH] [ACTBACK] rows. STATED-coverage ~100% on load-bearing steps.
- C5 add-field (WP-001/006): schemas.md "Adding a Field (Per Contract)" + "Field-Naming &
  Typing Convention" supply field name/type/constraints, every per-contract downstream
  consumer, naming/typing house style, optionality rule — fully STATED (field types
  re-injected inline by task-089).
- C2 wire (WP-002/007): module-map.md (Conv/Inv/Gotcha present) + pipeline-contracts Contract
  C + integration-map — STATED. C3 (WP-003/008): coding-standards "Conventions
  (Recurring-Change Checklist)" + authoring-conventions — STATED. C6 (WP-004/009):
  test-landscape Run Commands / Canonical Bash Suite / CI Gates + quality-gates — STATED.
  C9 (WP-005/010): capability-inventory + workflow-map — STATED.

### Intent 2 — Blind Reconstruction + Source Confrontation (essence) : FAIL (1 Divergence)
- Stage 1 KB-only reconstruction of AID's what/why/how is coherent and largely source-faithful.
- Stage 2 confrontation found ONE [HIGH] [FIDELITY] Divergence (TB-001): pipeline-contracts.md
  Contract E states its 20-row table is "the contract surface for every shipped canonical
  script," but 34 scripts exist on disk and several uncovered ones (parse-recipe.sh,
  compute-block-radius.sh, spot-check-facts.sh, manual-checklist.sh) are skill-invoked AND
  declare branching exit codes. The completeness claim is contradicted by source.
- Per the teach-back binary bar (zero-Divergence is mandatory; no grading on a curve), this
  single Divergence FAILs the essence gate. Load-bearing essence-coverage is otherwise high
  (>=90%): capability matrix, decisions, glossary, capability narratives all source-faithful.
- IMPORTANT framing: this FAIL is a property of the TASK-089 RE-INJECTION WORDING (an
  over-broad completeness phrase), NOT a defect in the delivery-015 dual-intent engine. The
  engine performed exactly as designed — it surfaced a real KB-vs-source divergence in AID's
  own depth-restored KB. FIX target: re-word Contract E to "every work-critical canonical
  helper (20 of 34)" or extend the table to the missing branching scripts (a one-line
  task-089-class KB edit, validation-only/uncommitted).

### Signature-exception regression (the key check) : PASS
- The re-injected host-tool matrix resolves STATED, not a load-bearing REACH: host-tool-
  capabilities.md Capability Flags matrix covers all 5 tools x 4 flags and is byte-exact vs
  every profiles/<tool>.toml [capabilities] block (verified). Tool-name remaps, model tiers,
  install roots, dispatch contract all present + source-grounded.
- The re-injected exit codes resolve STATED for the work-critical scripts: pipeline-contracts
  Contract E exit-code table matches the actual script headers (writeback-state.sh 0-6,
  grade.sh 0-2 verified). An agent planning a work probe needing a capability flag or a
  work-critical script's exit code now finds it in the KB — pre-D-016 these were a
  REACH/insufficiency. Regression CLOSED. (The completeness over-claim above is a separate
  fidelity wording issue, not a re-injection-insufficiency.)

### Threshold calibration (task-086 / §8) : HOLDS, no adjustment
- The >=90% STATED (assertiveness) and >=90% essence-coverage (essence) thresholds plus the
  zero-[HIGH]-[ACTBACK] / zero-[FIDELITY] hard conditions are correctly wired into
  state-review.md grade aggregation (verified: lines 403-432). They held against the AID
  dogfood: assertiveness cleared comfortably (zero ACTBACK, ~100% STATED); essence cleared
  the coverage threshold but was held to FAIL by the zero-Divergence hard gate — exactly the
  intended binary behavior. No calibration adjustment needed; the §8 deferral resolves with
  the starting-strict values intact.

### Build / hygiene (committed skill code only; .aid/knowledge doc-content-commit + INDEX-fresh-CI WAIVED per validation-only owner decision)
- `python3 .claude/skills/generate-profile/scripts/run_generator.py --verify` : VERIFY PASS
  (1385 emitted / 0 deleted; byte-identical + presence + frontmatter all PASS).
- `tests/canonical/test-dogfood-byte-identity.sh` : 559 passed / 0 failed (HOME-pinned).
- `tests/canonical/test-dual-intent-self-eval.sh` : 63 passed / 0 failed.
- `tests/canonical/test-ascii-only.sh` : 29 passed / 0 failed; kb-dual-intent-probes.sh in
  allow-list and ASCII-clean.
- Render-parity: canonical/aid/scripts/kb/kb-dual-intent-probes.sh == .claude copy (diff -q OK).
- node_modules: none present/left. Staged files: 0 (.aid/knowledge changes are working-tree
  only, consistent with the uncommitted dogfood decision).

### Per-AC confirmation
- AC1 (eval runs on AID KB, both gates): Intent 1 PASS; Intent 2 **FAIL (1 Divergence)** —
  see TB-001. The "both gates PASS" outcome is NOT met as-is; resolving the one-line Contract E
  wording is required for a clean capstone pass.
- AC2 (signature exception no longer FAILs on a REACH; host-tool/exit-codes STATED): PASS.
- AC3 (task-086 thresholds confirmed; calibration recorded): PASS (hold, no adjustment).
- AC4 (DBI render-parity + ASCII + affected suites green; .aid/knowledge doc-content-sync +
  KB-hygiene/INDEX-fresh CI): committed-skill-code portion PASS; the `.aid/knowledge/*`
  doc-content-commit + INDEX-fresh CI portion WAIVED per the validation-only owner decision.
- AC5 (section-6 quality gates): build/hygiene gates PASS; the dual-intent keystone is the
  blocking item via TB-001.

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** _none yet_

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
| 2026-06-25 | aid-reviewer | Medium | ~35m | Capstone dogfood: Intent1 PASS / Intent2 FAIL (1 [HIGH][FIDELITY] TB-001, Contract E over-claim — engine correctly surfaced it); sig-exception regression CLOSED; thresholds hold; build/hygiene green. State -> In Review. |
