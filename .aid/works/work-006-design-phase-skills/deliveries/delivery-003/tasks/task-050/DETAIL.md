# task-050: Ninety-four catalog rows validated over the finished set

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-050/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-049

> **Count-guard re-scope (owner decision, 2026-08-14).** This DETAIL cites
> `tests/canonical/check-skill-counts.mjs`, which was **retired upstream** (deleted by
> work-004). Those citations are superseded by `../../RESCOPE-COUNT-GUARD.md`: public-facing
> doc counts are guarded by `tests/canonical/test-doc-counts.sh`, and counts inside
> `canonical/` / `.aid/knowledge/` are reviewer-governed under criterion `G-01`. Read that
> document before executing this task.

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §10 row *Rows valid* and its
  first acceptance criterion, plus REQUIREMENTS NFR-2. It closes BLUEPRINT criterion **1** -- *"The
  catalog validates over the finished set"*, the first checkbox in § Gate Criteria.
- **It is delivery-003's entry task and it writes nothing.** It is the single edge by which this
  delivery joins the graph, so every delivery-001 and delivery-002 task is one of its ancestors and
  the set it validates is complete. Validation before mutation is the point: every later task here
  consumes the catalog, and a bad row would be propagated by the render into five profiles and two
  dogfood trees before anything noticed.
- Over the finished catalog assert, per row: the row `name` equals its directory under
  `canonical/skills/`, equals that directory's frontmatter `name:`, and carries the `aid-` prefix;
  `alias_of` is `null`; and every hand-authored row carries `repurpose: true`.
- **The `repurpose` half is asserted count-free, against `master`, not against an integer.** The set
  of row `name`s carrying **no** `repurpose` key must be identical to the same set derived from
  `git show master:canonical/aid/templates/shortcut-catalog.yml`. All thirty-six rows this work adds
  are hand-authored, so a row that lost the key appears in that difference. No expected integer is
  stated here, because the integers belong to task-059, task-062 and task-069, and a figure stated
  in two places is how the two copies drift.
- **Which instruments run here and which deliberately do not.**
  `tests/canonical/test-catalog-dirs-parity.sh` runs: it is count-agnostic by design (`:21-22` --
  *"derives its row set from the catalog and holds NO expected total, so it passes at any row
  count"*), so it extends by data and must be green **unmodified**.
  `tests/canonical/test-deploy-monitor-repurpose.sh` and `tests/canonical/check-skill-counts.mjs`
  do **not** run here -- both still hold the pre-work integers that task-062 and task-069 retune,
  and running them now would report a correct mid-work state as a failure.
- Out of scope: the build helper and the render (task-060); every count-bearing integer and comment
  (task-059, task-062, task-069); the `tests/coverage-baseline.tsv` re-bootstrap (task-063); and any
  edit at all -- this task is a read-only audit.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** -- no row is reported as covered without its oracle and result (TEST default: all
      acceptance criteria from the source feature covered)
- [ ] **BLUEPRINT criterion 1 -- ninety-four rows, one hundred and twelve directories.** With
      `C=canonical/aid/templates/shortcut-catalog.yml`, `grep -c '^  - name:' "$C"` captured to a
      variable -> `94`, and `ls -1d canonical/skills/*/ | wc -l` captured to a variable -> `112`.
      The two are different quantities and are asserted separately, because the corpus is larger
      than the catalog by the eighteen curated skills that own no row
- [ ] **`name` == directory == frontmatter `name:`, `aid-` prefixed, for all ninety-four rows.**
      `bash tests/canonical/test-catalog-dirs-parity.sh` passes -- `CDP{i}a`, `CDP{i}b`, `CDP{i}c`
      and `CDP{i}d` are exactly these conjuncts, one set per row (`:126-141`) -- and
      `git diff master -- tests/canonical/test-catalog-dirs-parity.sh` is **empty**. `git diff
      master`, not `--exit-code`, which compares the working tree to `HEAD` and passes trivially
      once an edit is committed
- [ ] **`alias_of: null` on every row, count-free.** With the same `$C`,
      `[ "$(grep -c '^    alias_of: null$' "$C")" = "$(grep -c '^  - name:' "$C")" ]`. It fails if
      any row omits, misspells or aliases the field, and it holds at any row count.
      `test-catalog-dirs-parity.sh` is **not** an oracle for this -- `:72-77` of the catalog's own
      field contract records `alias_of` as parsed-then-never-read dead input in that suite
- [ ] **`repurpose: true` on every hand-authored row, asserted so the emitting count cannot move.**
      `comm -3` over the sorted set of row `name`s carrying no `repurpose` key, taken from the
      working tree and from `git show master:canonical/aid/templates/shortcut-catalog.yml`, is
      **empty**. This is the count-free form of *the `shortcuts` (emitting) quantity does not move*
- [ ] **`CDP-HELPER` is green, which is the independent byte-level cross-check.**
      `test-catalog-dirs-parity.sh:199-202` runs `build-shortcut-skills.py --check`; it must exit 0
      and print a line beginning `OK:`. That proves the sixty `repurpose` rows were skipped and the
      thirty-four generated doorways are byte-current, **before** task-060 renders them
- [ ] **The two count-bearing instruments were deliberately NOT run, and the record says so with
      the reason.** `tests/canonical/test-deploy-monitor-repurpose.sh` and
      `tests/canonical/check-skill-counts.mjs` are neither executed nor edited here, and
      `git diff master -- tests/` shows no change to either
- [ ] This task writes nothing: `git status --porcelain` over `canonical/`, `tests/`,
      `site/`, `docs/`, `.aid/knowledge/`, `profiles/`, `.claude/` and `.cursor/` is **identical
      before and after**, and `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- every row is a `grep`, a `comm`, a
      scoped `git diff` or a named suite over committed content, so two executions produce
      identical outcomes and there is nothing to tear down
- [ ] All section-6 quality gates pass
