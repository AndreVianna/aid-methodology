# task-086: Full profile render and render-drift confirmation for delivery-005

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-082, task-083

**Scope:**
- Run the **FULL** profile generator over delivery-005's canonical additions -- never a per-script
  renderer. `.aid/knowledge/tech-debt.md` Gotchas is explicit: "Render-drift needs the FULL
  generator ... otherwise the render-drift gate fails on stale `profiles/` emission manifests."
  ```
  python .claude/skills/generate-profile/scripts/run_generator.py
  ```
- The canonical surface this render covers: `canonical/aid/templates/knowledge-graph/graph-canvas.js`,
  this delivery's additions to `canonical/aid/templates/knowledge-graph/graph-css.css`, and -- if
  task-083 fired -- any vendored renderer tree under
  `canonical/aid/templates/knowledge-graph/vendor/<name>/`.
- Confirm no render drift with the documented check, whose re-run is deliberate: a second render
  over an already-rendered tree must produce byte-identical output, so the command proves both
  that `profiles/` matches `canonical/` and that the render is stable.
  ```
  python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
  ```
- Confirm all five `profiles/<tool>/emission-manifest.jsonl` files moved together in the same run,
  that the five profile trees and the dogfood `.claude/` tree all carry the new files, and that no
  rendered copy was hand-edited -- `canonical/` is the single source of truth and `profiles/`,
  `.claude/` and `.cursor/` are build output.
- If task-083 fired, additionally confirm that `node_modules/` appears in no profile tree and no
  emission manifest (`render.py`'s `_EXCLUDE_DIRS`), and that the vendored tree rendered as part
  of the `knowledge-graph/` template set.
- **Shell note for this machine:** bare `bash` resolves to the WSL launcher and corrupts git
  worktree paths. Invoke Git Bash explicitly
  (`"C:\Program Files\Git\bin\bash.exe"`) for any shell step.
- **Out of scope:** count-surface reconciliation and the `SKILL_GROUPS` roster pair (feature-012,
  delivery-002); the roster entries in `docs/` and `README.md` (task-090); the registration suite
  that asserts the shipped result across all trees (task-091).

**Acceptance Criteria:**
- [ ] Configuration is idempotent: a second `run_generator.py` run produces byte-identical output
      and `git diff --exit-code -- profiles/` exits 0.
- [ ] No plaintext secrets are introduced by this render.
- [ ] The **FULL** generator was run, not a per-script renderer.
- [ ] `graph-canvas.js` and this delivery's `graph-css.css` changes are present in all five
      `profiles/<tool>/` trees and in the dogfood `.claude/` tree.
- [ ] All five `emission-manifest.jsonl` files are rewritten in the same run; none is stale.
- [ ] No rendered copy was hand-edited -- every change in `profiles/`, `.claude/` and `.cursor/`
      traces to a `canonical/` edit made by tasks 079-083.
- [ ] If task-083 fired, `node_modules/` is absent from every profile tree and every emission
      manifest, and the vendored tree rendered with the `knowledge-graph/` template set.
- [ ] If task-083 is a recorded no-op, this task records that no vendored tree was rendered.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
