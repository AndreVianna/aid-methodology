# task-014: Regenerate INDEX.md, re-render profiles/, and resync the dogfood trees

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

**Depends on:** task-005, task-007, task-008, task-009, task-010, task-011, task-012, task-013

**Scope:**
- Refresh every generated artifact this work invalidated, in the order SPEC.md
  `#### Sequencing constraints` fixes -- generated files refresh last:
  1. `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output
     .aid/knowledge/INDEX.md`, run only after every in-scope doc's frontmatter is final. `INDEX.md` is
     regenerated, never authored.
  2. `python .claude/skills/generate-profile/scripts/run_generator.py`, propagating every
     `canonical/` change from task-002, task-004, and task-005 into the five profile trees and
     refreshing each profile's `emission-manifest.jsonl`.
  3. Resync the repo-root `.claude/` and `.cursor/` dogfood trees, which this repo installs from its
     own output.
- Verify each step's determinism: a second `build-kb-index.sh` run and a second `run_generator.py` run
  must each leave the tree unchanged.
- This task owns the render and dogfood-resync obligation for everything that landed under
  `canonical/` in this delivery. It hand-edits nothing under `profiles/`.
- It depends on task-005 (the last canonical edit) and on every corpus rewrite task (the last
  frontmatter edit); task-004 and task-006 reach it transitively.

**Acceptance Criteria:**
- [ ] `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output
      .aid/knowledge/INDEX.md` exits 0, and the resulting `INDEX.md` carries the rewritten
      `objective:`/`summary:` text for all 17 in-scope docs (AC-5).
- [ ] A second `build-kb-index.sh` run followed by `git diff --exit-code -- .aid/knowledge/INDEX.md`
      exits 0, and `git diff` shows no hand edit to `INDEX.md` (AC-5).
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code --
      profiles/` exits 0, and a second generator run leaves the tree unchanged (AC-9).
- [ ] `bash tests/canonical/test-dogfood-byte-identity.sh` passes -- manifest-to-dogfood hash match,
      manifest completeness, and the repo-orphan sweep all clean (AC-9).
- [ ] `git diff --stat -- profiles/` shows changes only in files the generator emits from the
      `canonical/` paths this delivery touched (`kb/kb-language-lint.sh`, `kb/closure-check.sh`, the
      three `kb-authoring/` templates, and the three `aid-discover/references/` files) -- no unrelated
      churn.
- [ ] `grep -rE 'work-[0-9]{3}' .aid/knowledge/` returns no match after regeneration, so the rebuilt
      `INDEX.md` introduced none (AC-11).
- [ ] All section-6 quality gates pass.
