# task-035: Deploy/Monitor re-purpose verification test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-033, task-034

**Scope:**
- Re-point test (part b): `aid-monitor` `state-route.md` routes BUG -> `/aid-fix` and CHANGE REQUEST -> `/aid-triage` (fixture findings); grep proves no aid-monitor file (SKILL.md, state-route.md, README.md) references `aid-describe`, "lite bug-fix triage", or `LITE-BUG-FIX`; `pipeline-contracts.md` L9/L10 targets updated.
- Pipeline-role no-regression (AC-9): with `work-NNN` present both skills run their existing pipeline states unchanged; `tests/run-all.sh` green.
- Shortcut mode (part a): no `work-NNN` + description scaffolds a flattened lite work and halts at approval (never executes); the catalog parity-exemption for the 2 repurpose rows holds.
- Full catalog: the catalog-to-dirs parity test now asserts the full 69 rows (45 canonical incl. the 2 repurpose + 24 alias); no orphan dir, no orphan row.

**Acceptance Criteria:**
- [ ] Re-point routing verified (BUG -> `/aid-fix`, CR -> `/aid-triage`; no `aid-describe`-lite refs; L9/L10 lockstep).
- [ ] Pipeline-role no-regression (work-NNN present -> pipeline unchanged; `tests/run-all.sh` green) (AC-9).
- [ ] Shortcut mode scaffolds + halts; repurpose rows exempt from the thin-doorway parity assertion.
- [ ] Full 69-row catalog-to-dirs parity green (45 canonical + 24 alias; no orphans).
- [ ] Test is deterministic with clean setup/teardown; covers feature-012 ACs.
- [ ] All §6 quality gates pass.
