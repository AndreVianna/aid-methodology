# task-031: Full regression, coverage parity and the documentation grep

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-19, AC-21

**Depends on:** task-016, task-017, task-018, task-019, task-020, task-021, task-022, task-023, task-024, task-025, task-026, task-028, task-029, task-030

**Scope:**
- Add the AC-19 grep to `tests/canonical/test-shared-layout-sources.sh` as a keyed assertion:
  `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- CLAUDE.md AGENTS.md README.md docs .github/workflows .aid/knowledge site ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'`
  prints no lines.
- Run the whole regression on a host with `pwsh`, `node` and `python3` (the coverage-parity
  gate's runtime precondition): `HOME=$(mktemp -d) bash tests/run-all.sh`, the generator self-tests,
  the full `run_generator.py` with the render-drift check, and the KB hygiene checks of
  `.github/workflows/test.yml`.
- Every failure found is a finding: fix it only when it is a test-side omission (a missing coverage
  row, a stale assertion key); a product defect is reported as an IMPEDIMENT naming the owning task,
  not patched here.
- Confirm every assertion key removed or renamed across the delivery has a row in
  `tests/coverage-accepted-removals.tsv` or `tests/coverage-rehome-allowlist.tsv`.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/run-all.sh` exits `0`, including the coverage-parity gate.
- [ ] `python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .` exits `0`, and `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` exits `0` (no render drift).
- [ ] `bash tests/canonical/test-shared-layout-sources.sh --verbose` prints a `PASS:` line for the AC-19 grep.
- [ ] `git status --porcelain` is empty after the run (no suite wrote into the real repo).
- [ ] All section-6 quality gates pass.
