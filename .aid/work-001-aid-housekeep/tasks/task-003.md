# task-003: `parse-args.sh` — argument grammar parser

**Type:** IMPLEMENT

**Source:** feature-001-skill-and-state-machine → delivery-001

**Depends on:** —

**Scope:**
- Implement `canonical/scripts/housekeep/parse-args.sh` (feature-001 SPEC § Layers &
  Components `parse-args.sh` bullet, § Invocation / CLI Arguments table).
- Recognize the delivery-001 arg grammar: *(none)* = full gated sequence; `--grade X`
  (`[A-F][-+]?`) pass-through for the SUMMARY-DELTA delegation; unknown flag → exit 2.
- Per feature-001 SPEC § "Incremental-delivery stub no-op": **`--cleanup-only` is absent from
  the arg grammar in delivery-001** (the CLEANUP body is still a stub no-op; the flag arrives
  with the delivery that ships the real CLEANUP body). Do not parse `--cleanup-only` here.
- The skeleton does **not** parse `--fetch`/offline (that boundary lives in feature-002's body)
  — feature-001 SPEC § "`--fetch` / offline".
- Bash style per `.aid/knowledge/coding-standards.md`; mirror the
  `tests/canonical/test-read-setting.sh` style for arg-parsing tests; place under
  `canonical/scripts/housekeep/`.

**Acceptance Criteria:**
- [ ] No-args parse yields the full-sequence mode; `--grade A-` is accepted and surfaced;
  an unknown flag exits 2 (matching the read-setting.sh exit convention).
- [ ] `--cleanup-only` is rejected as an unknown flag in delivery-001 (exit 2) — confirming the
  flag is not yet offered.
- [ ] A canonical unit suite `tests/canonical/test-housekeep-parse-args.sh` (auto-discovered by
  the `tests/canonical/test-*.sh` glob, sourcing `tests/lib/assert.sh`) covers no-args,
  `--grade`, and unknown-flag→exit-2 (feature-001 SPEC § Testing
  `test-housekeep-parse-args.sh`).
- [ ] All §6 quality gates pass (NFR4/NFR5); build/render passes; all existing tests pass.
