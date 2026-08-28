# task-005: Wire kb-language-lint.sh into the kb-hygiene CI job and the discover REVIEW oracles

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

**Type:** CONFIGURE

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** task-002

**Scope:**
- `.github/workflows/test.yml`, `kb-hygiene` job: add one step that runs
  `bash canonical/aid/scripts/kb/kb-language-lint.sh --root .`, positioned after the existing
  frontmatter-lint step and before the INDEX-freshness step, so a violation fails a merge. Repo-local
  file; not rendered to `profiles/`.
- `canonical/skills/aid-discover/references/state-review.md`: add `kb-language-lint.sh` to the
  deterministic oracles the orchestrator runs before dispatching the reviewer panel, alongside
  `closure-check.sh` and `kb-dual-intent-probes.sh`, so a violation surfaces as a ledger finding
  rather than passing silently.
- Verify the wiring actually blocks rather than merely existing: run the same command the CI step
  runs against `tests/canonical/fixtures/kb-language-lint/undefined/` and confirm the non-zero exit
  that would fail the job.
- Wiring only. The rule prose lives in task-004, the script in task-002, the suite in task-003, and
  the `profiles/` render in task-014.

**Acceptance Criteria:**
- [ ] The `kb-hygiene` job in `.github/workflows/test.yml` contains a step invoking
      `kb-language-lint.sh --root .`, and its position in the step list is after the frontmatter lint
      and before the INDEX-freshness check (AC-15).
- [ ] The workflow file parses as valid YAML and the job's other steps are unchanged (`git diff` shows
      only the added step).
- [ ] `canonical/skills/aid-discover/references/state-review.md` lists `kb-language-lint.sh` among the
      deterministic oracles run before the reviewer panel dispatch, with the same invocation shape the
      neighbouring oracles use (AC-15).
- [ ] Running the CI step's exact command against
      `tests/canonical/fixtures/kb-language-lint/undefined/` exits non-zero, and against
      `.../defined/` exits 0 -- the wired check can actually fail.
- [ ] Re-applying the configuration is a no-op: a second read of both files shows one step and one
      oracle entry, not two (idempotence).
- [ ] `git status --porcelain -- profiles/` prints nothing: the render is task-014's, and nothing under
      `profiles/` was hand-edited.
- [ ] `bash tests/canonical/test-ascii-only.sh` passes over the edited canonical file.
- [ ] All section-6 quality gates pass.
