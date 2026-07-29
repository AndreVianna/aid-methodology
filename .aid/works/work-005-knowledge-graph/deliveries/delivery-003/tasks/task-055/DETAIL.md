# task-055: Full profile render and render-drift confirmation for delivery-003

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-045, task-047, task-048, task-050, task-051

**Scope:**
- Run the **FULL** profile generator over delivery-003's canonical additions and confirm no render
  drift. Never a per-script renderer: `.aid/knowledge/tech-debt.md` Gotchas is explicit that
  "Render-drift needs the FULL generator ... otherwise the render-drift gate fails on stale
  `profiles/` emission manifests".
- The canonical surface this render covers:
  - `canonical/aid/scripts/graph/coverage-predicate.mjs` and
    `canonical/aid/scripts/graph/detect-kb-gaps.mjs` (tasks 045, 046, 047);
  - the `coverage_bearing` sibling file under `canonical/aid/templates/graph/` (task-045);
  - `canonical/aid/templates/reviewer-ledger-schema.md` and
    `canonical/aid/templates/kb-authoring/frontmatter-schema.md` (task-048);
  - `canonical/skills/aid-graph/references/state-gap-report.md` (task-050) and the `SKILL.md`
    Dispatch row (task-051).
- Commands, in this order:
  ```
  python .claude/skills/generate-profile/scripts/run_generator.py
  python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
  ```
  The documented check re-runs the generator and *then* diffs, deliberately: a second render over an
  already-rendered tree must produce byte-identical output, so the command proves both that
  `profiles/` matches `canonical/` and that the render itself is stable.
- All five `profiles/<tool>/emission-manifest.jsonl` files move together with the rendered trees. No
  profile copy, `.claude/` copy or `.cursor/` copy is hand-edited -- `module-map.md` Invariants:
  "Edit `canonical/`, never `profiles/`".
- `.mjs` **is** in `render.py`'s `_TEXT_EXTENSIONS`, so both new modules are text-processed at
  render. Because both obey the no-`canonical/`-path, no-placeholder rule, each is a fixed point of
  `substitute_filenames` and `rewrite_install_paths` and every rendered copy is byte-identical to the
  canonical file -- the property task-071's `GV08` later asserts. A **non**-byte-identical render of
  `coverage-predicate.mjs` is a defect in the module (a stray path or placeholder), not in the
  render, and is routed back to task-045 rather than patched in the rendered copy.
- Out of scope: authoring any of the files being rendered (tasks 045-051); delivery-002's render
  (task-044) and delivery-004's (task-069); the count surfaces and the site roster (tasks 010-012,
  delivery-002 -- this delivery registers no new skill, so no `${SKILLS}` surface moves); `GV08`
  itself (task-071).

**Acceptance Criteria:**
- [ ] The **FULL** generator was run -- `python .claude/skills/generate-profile/scripts/run_generator.py`
      with no per-script or partial-render flag -- and its verify spine passed.
- [ ] The re-render-then-diff check exits 0 --
      `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/`
      -- proving both that `profiles/` matches `canonical/` and that a second render is
      byte-identical.
- [ ] All five `profiles/<tool>/emission-manifest.jsonl` files carry a record for each newly rendered
      canonical file, each with a current `sha256`; no manifest is left behind.
- [ ] Every rendered copy of `coverage-predicate.mjs` under `profiles/` is byte-identical to
      `canonical/aid/scripts/graph/coverage-predicate.mjs`. A difference is reported as a defect in
      the module -- a stray `canonical/...` path or a filename placeholder -- and routed back to
      task-045; it is never patched in the rendered copy.
- [ ] Every rendered copy of `detect-kb-gaps.mjs`, `state-gap-report.md`, `SKILL.md`,
      `reviewer-ledger-schema.md`, `frontmatter-schema.md` and the `coverage_bearing` sibling file is
      present in all five profile trees and in the dogfood `.claude/` tree.
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` was hand-edited: every change in those
      trees is generator output.
- [ ] **Configuration is idempotent (CONFIGURE default):** a third generator run produces no further
      diff.
- [ ] **No plaintext secrets (CONFIGURE default):** the render introduces no credential, token, or
      absolute machine path into any emitted file or manifest.
- [ ] All existing canonical suites still pass after the render -- `bash tests/run-all.sh` reports no
      newly red suite -- including `bash tests/canonical/test-doc-counts.sh`, which is unchanged
      because this delivery registers no new skill and moves no `${SKILLS}` count surface.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
