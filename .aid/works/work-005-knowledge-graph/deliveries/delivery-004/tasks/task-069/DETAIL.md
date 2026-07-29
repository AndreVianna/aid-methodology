# task-069: Full profile render and render-drift confirmation for delivery-004

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-057, task-058, task-061, task-062, task-064, task-065, task-066, task-067, task-068

**Scope:**
- Run the **FULL** profile generator over this delivery's canonical edits -- the new
  `canonical/aid/templates/knowledge-graph/` template set (`graph-skeleton.html`, `graph-css.css`,
  `graph-model.js`, `graph-controls.js`, `graph-table.js`, `lens-presets.md`,
  `accessibility-checklist.md`, the section manifest), plus
  `canonical/skills/aid-graph/references/state-render.md` and the `SKILL.md` edit -- and confirm
  no render drift:
  ```bash
  python .claude/skills/generate-profile/scripts/run_generator.py
  python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
  ```
- Confirm all five `emission-manifest.jsonl` files move together with the new file set (C-3).
- **Out of scope:** editing any rendered copy under `profiles/`, `packages/*/_vendor/` or
  `.claude/` by hand -- every change originates in `canonical/`; a per-script renderer, which
  leaves stale emission manifests and is explicitly not the tool here; the count surfaces and the
  site roster (feature-012, delivery-002); the registration suite (task-091, delivery-006).

**Acceptance Criteria:**
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py` completes successfully,
      rendering all five profile trees plus `.claude/`, rewriting all five emission manifests,
      performing the manifest diff/deletion pass and running the verify spine.
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code --
      profiles/` exits **0** -- the render is both complete and stable, which is exactly what the
      re-render-then-diff form proves.
- [ ] Every file this delivery added appears as a record in **all five** `emission-manifest.jsonl`
      files: each member of the `knowledge-graph/` template set and
      `references/state-render.md`; no manifest is left behind (C-3).
- [ ] **Configuration is idempotent** (CONFIGURE default): the second generator run produces
      byte-identical output to the first, evidenced by the `&& git diff --exit-code` above.
- [ ] **No plaintext secrets** (CONFIGURE default): the render introduces no credential, token or
      key into any tree.
- [ ] No rendered copy is hand-edited: `git diff -- profiles/ packages/ .claude/` before the run
      shows no manual change, and after the run every difference is generator output.
- [ ] `git status` shows no untracked canonical file that the generator failed to emit -- a new
      canonical file missing from the manifests is the L4 lockstep failure this task exists to
      catch.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
