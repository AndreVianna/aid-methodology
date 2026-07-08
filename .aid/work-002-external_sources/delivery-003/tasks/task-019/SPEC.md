# task-019: Reconcile scenario tests

**Type:** TEST

**Source:** work-002-external_sources -> delivery-003

**Depends on:** task-018

**Scope:**
- Deterministic fixture-registry scenario tests for the composed reconcile guarantees: add -> new entry present, others + secrets preserved; change -> descriptor updated in place, secret preserved; remove -> descriptor deleted + secret purged + `mcp` host entry unwired, surviving entries/secrets intact; a second run on unchanged input -> byte-identical `INDEX.md` no-op; an interrupted REMOVE -> re-derived and re-applied (re-purge / re-unwire are clean no-ops).
- Q9 branches: `SKIPPED` -> registry untouched; `DECLARED-EMPTY` -> all connectors removed-and-purged.

**Acceptance Criteria:**
- [ ] Tests are deterministic with clean setup/teardown over a fixture `.aid/connectors/` tree (+ a fixture host config)
- [ ] AC-6 three cases covered (add / change / remove) with preservation of surviving entries and their secrets
- [ ] Idempotent no-op proven (byte-identical `INDEX.md` on a second run); interrupt re-convergence proven via idempotent purge / unwire
- [ ] Q9 skip-vs-empty branches covered: `SKIPPED` NO-OP vs `DECLARED-EMPTY` remove-all
- [ ] All §6 quality gates pass
