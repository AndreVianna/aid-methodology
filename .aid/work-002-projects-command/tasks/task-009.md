# task-009: bash↔PowerShell parity tests for `aid projects`

**Type:** TEST

**Source:** feature-001-projects-command → delivery-002

**Depends on:** task-007

**Scope:** Add parity assertions to `tests/canonical/test-aid-cli-parity.sh` (new `PAR0NN-*` IDs) confirming bash and PowerShell produce equivalent results for `aid projects`:
- `list` output shape (columns, state values, marker) equivalent across bash/PS for the same fixture registry;
- `add` / `remove` exit codes and registry effect equivalent (incl. add-rejects-non-`.aid/` exit 2; idempotent);
- tier-resolution outcome equivalent for matching scope/location inputs, including that **neither** bash nor PS prompts on a global outside-`$HOME` `add` (FR7/AC6 reconcile parity).
- Follow the suite's existing dual-run harness + ID convention; HOME-pinned.

**Acceptance Criteria:**
- [ ] New parity IDs assert bash≡PS for `projects list/add/remove` (output shape + exit codes + registry effect).
- [ ] `tests/canonical/test-aid-cli-parity.sh` passes locally (HOME-pinned); the existing PAR057 set (updated in task-002) remains green.
- [ ] All §6 quality gates pass.
