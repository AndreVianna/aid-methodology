# task-001: aid-execute arg-order refactor

**Type:** REFACTOR

**Source:** work-002-execute-arg-order → delivery-001

**Depends on:** — (none)

**Scope:**
- `canonical/skills/aid-execute/SKILL.md`: change `argument-hint` (line ~9) to lead
  with the work (e.g., `work-001 (required if multiple works)  task-001 (required)`),
  matching aid-detail/aid-plan; update "Check 1: Locate Work and Task" parsing prose
  to read the work argument first while still auto-selecting the work when only one
  exists; update the example invocations (lines ~183–188) to the work-first order.
- Preserve the backward-compatible single-work shorthand: `/aid-execute task-001`
  must still resolve by `work-`/`task-` prefix detection when only one work exists.
- Update all cross-references to the new order:
  - `canonical/skills/aid-execute/README.md` (lines ~44–45)
  - `canonical/skills/aid-execute/references/state-execute.md` (lines ~44, ~380) and `references/state-re-run.md` (line ~7) — these are single-work **shorthand** mentions (`/aid-execute task-NNN`); preserve the shorthand per AC3, only fix any two-arg example to work-first.
  - `canonical/skills/aid-interview/references/state-lite-done.md` — the hand-off command (lines ~61, ~95) AND line ~85, the prose that says the work id is "appended" to the command (reword: after the refactor the work id leads, it is no longer appended).
  - `canonical/templates/reviewer-ledger-schema.md` (line ~49)
- No script changes: the execute helper scripts parse named flags (`--task-id`,
  `--tasks-dir`), not positional skill args.
- Run the FULL generator (`run_generator.py`) to re-render all 5 install trees.
- Verify the CI gates in `.github/workflows/test.yml` pass: render-drift,
  canonical-tests, generator-selftests, and kb-hygiene.

**Acceptance Criteria:**
- [ ] aid-execute `argument-hint` leads with the work, consistent with the sibling skills. (SPEC AC1)
- [ ] "Check 1: Locate Work and Task" parses the work argument first and still auto-selects the work when only one exists. (SPEC AC2)
- [ ] The single-work shorthand `/aid-execute task-001` still resolves (backward-compatible). (SPEC AC3)
- [ ] Every canonical example invocation and cross-reference (aid-execute SKILL.md/README/state-execute/state-re-run, aid-interview state-lite-done, reviewer-ledger-schema) shows the work-first order. (SPEC AC4)
- [ ] `/aid-execute` is byte-identical across all 5 install trees; render-drift, canonical-tests, generator-selftests, and kb-hygiene gates pass. (SPEC AC5)
- [ ] All existing tests pass — no behavior regression. (SPEC AC6)
