# task-062: Eight catalog edit sites moved together across two test files

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-062/STATE.md.
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

**Depends on:** task-061

**Scope:**
- Source: REQUIREMENTS **AC-11** and `features/feature-006-integration-and-close-out/SPEC.md` §4a and
  §4b, which table the sites. It closes BLUEPRINT criterion **5** -- *"All eight catalog edit sites
  move together across the two test files"*.
- **`tests/` is outside the count guard's scan entirely** (`check-skill-counts.mjs:36-39` lists it
  under NOT YET SCANNED), so nothing catches a stale integer anywhere below it. The suites themselves
  are the only oracle, which is why this task's evidence is a green run and not a grep.
- **File (a), `tests/canonical/test-deploy-monitor-repurpose.sh` -- four assertions and two comment
  blocks.** Each expected literal **and** its message: `:319` `DMR30` `TOTAL_ROWS` 58 -> 94; `:320`
  `DMR31` `CANONICAL_ROWS` 58 -> 94; `:321-323` `DMR32`, whose expected value is the whole sentence
  `0 alias of 58 rows carrying an alias_of field` plus `the 58 rows` in its message; `:324` `DMR33`
  `REPURPOSE_ROWS` 24 -> 60 with the decomposition in its message moving `24 + 34 = 58` -> `60 + 34 =
  94`. Plus the Part 4 header comment at `:31-34` and the *Catalog size, by version* comment at
  `:308-318`.
- **`DMR32` is the site a sweep misses, and the reason is that its zero is not the moving part.** Its
  expected value pairs the alias count with `ALIAS_FIELD_LINES`, the same-anchor control at `:300-304`
  that stops *"0 alias rows"* passing for the wrong reason. `ALIAS_FIELD_LINES` counts every row
  carrying an `alias_of:` key, so at 94 rows it reads 94 and the hardcoded `58` fails the suite. The
  zero itself stays `0` -- every new row carries `alias_of: null` -- and the assertion still moves.
- **The `:308-318` comment is appended to, never rewritten.** `:316-318` says the record is
  *"deliberately preserved, not overwritten"* and that only its last figures are asserted. Add one
  sentence for this work (`58 -> 94` rows, `24 -> 60` repurpose); do not touch the work-004 or
  work-005 narration.
- **File (b), `tests/canonical/test-catalog-dirs-parity.sh` -- two comment blocks and zero
  assertions.** The suite is count-agnostic by design (`:21-22`), and that survives this work; its
  **header** does not. `:13-17` carries `24 \`repurpose\` rows` -> **60**, and the
  `3 classic re-registered pipeline skills` figure at `:15` stays **3**. `:21-31` carries
  `measured 2026-07-31` -> the date this work re-measures, `58-row catalog = 58 canonical names + 0
  aliases` -> **94 / 94 / 0**, and `24 repurpose + 34 shortcuts -- 58 - 24 = 34` -> **60 / 34 /
  `94 - 60 = 34`**, with the independent awk pass still reaching 34. **No assertion in this file is
  edited.**
- **The closing report must state the split explicitly** -- four assertions and two comment blocks in
  (a), two comment blocks and no assertion in (b) -- rather than implying (b) was left untouched, or
  that an assertion in it changed. feature-006 §4 records that an earlier framing did exactly that.
- **What must not move.** Every `34` in either file, and the `3` classic figure. All thirty-six new
  rows are `repurpose: true`, so the emitting quantity does not move; a sweep that changed a `34` to a
  `70` would corrupt a correct assertion, and that is this delivery's most likely error mode.
- **feature-001 AC-3 is reconciled, not overridden, and the reconciliation is stated here because this
  is the first task in the work to write under `tests/canonical/`.** AC-3's oracle is
  `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` clean, and it is evaluated at
  **feature-001's own close** -- inside delivery-001, where it holds -- because what it asserts is that
  the *conditional* doc-set decision cost no test edit. It is not a work-wide freeze on `tests/`: this
  delivery's BLUEPRINT criteria 5 and 7 require exactly these edits, and REQUIREMENTS AC-11 names the
  assertions by key. What survives untouched, and is re-asserted below, is the **seed-count** suite set
  AC-3 actually enumerates. `site/scripts/__tests__/` stays writer-free for the whole work.
- Out of scope: `tests/canonical/check-skill-counts.mjs`, whose `CLAIMS`, `SUPERSEDED`, `MARKER_CAP`
  and `CLAIM_FLOOR` are task-069's and whose `MARKER_CAP` sits at exactly its live figure with no
  headroom; `tests/coverage-baseline.tsv` and `.meta`, which are task-063's CI-only re-bootstrap;
  every count-bearing prose surface (task-065 through task-069); and authoring any new test script or
  assertion id under `tests/` or `site/scripts/__tests__/` -- the ground is feature-001 AC-3.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 5 -- the suite that carries the assertions is green at its new values.**
      `bash tests/canonical/test-deploy-monitor-repurpose.sh` passes, with `DMR30`, `DMR31`, `DMR32`
      and `DMR33` each individually reported `PASS` and each new expected literal recorded
- [ ] **All four assertions moved, message included.** `git diff HEAD --
      tests/canonical/test-deploy-monitor-repurpose.sh` shows the expected literal **and** the message
      changed on each of `:319`, `:320`, `:321-323` and `:324`; `DMR33`'s message reads the
      decomposition `60 + 34 = 94`; and `DMR32`'s expected sentence reads
      `0 alias of 94 rows carrying an alias_of field`
- [ ] **The four derived assertions needed no edit, and that is asserted rather than assumed.**
      `DMR34` (`:326`), `DMR35a` (`:331`), `DMR35b` (`:340`) and `DMR36` (`:367`) are unchanged in the
      diff and all four report `PASS` -- they derive their expectations, so an edit to any of them
      would be the defect
- [ ] **The two comment blocks in file (a) moved, and the version narration was appended to, not
      rewritten.** `:31-34` states 94 / 94 / 0 / 60 / 34 and `60 + 34 = 94`; the diff over `:308-318`
      shows **only added lines** in the narration region, with no line of the work-004 or work-005
      record deleted or altered
- [ ] **File (b)'s two comment blocks moved and its assertions did not.**
      `git diff HEAD -- tests/canonical/test-catalog-dirs-parity.sh` shows every changed line
      beginning with `#`; `bash tests/canonical/test-catalog-dirs-parity.sh` is green; and the header
      now reads 60 `repurpose`, `94 / 94 / 0`, `94 - 60 = 34`, awk still 34, the `3` classic figure
      unchanged, and a re-measurement date this work actually measured on
- [ ] **The negative half: no `34` and no `3` moved in either file.** `grep -n '\b34\b' ` and
      `grep -n 'classic' ` over each of the two files produce output whose changed lines are only
      those the criteria above authorise, and no occurrence of `34` was rewritten to any other value
- [ ] **The eight-site split is stated explicitly in this task's record** -- four assertions plus two
      comment blocks in `test-deploy-monitor-repurpose.sh`, two comment blocks and no assertion in
      `test-catalog-dirs-parity.sh` -- with the two files named
- [ ] **task-055's two pinned literals survive this file's edit.** The assertions at `:138` and `:150`
      of `test-deploy-monitor-repurpose.sh` are unchanged in the diff and both report `PASS`; this
      task edits four *other* assertions in the same file, which is why the guard is hunk-scoped rather
      than a whole-file `--exit-code`
- [ ] **No new test script and no new assertion id.** `git diff --name-only HEAD -- tests/` lists
      exactly the two files this task owns, `git diff --exit-code -- site/scripts/__tests__/` is clean,
      and no assertion id that did not exist before appears in either file
- [ ] **The seed-count suite set feature-001 AC-3 enumerates is still unmodified and still green.**
      `git diff master --` is **empty** on each of `tests/canonical/test-doc-set-read.sh`,
      `tests/canonical/test-doc-set-mapping.sh`, `tests/canonical/test-domain-doc-matrix.sh`,
      `tests/canonical/test-spine-depth-coverage.sh` and
      `tests/canonical/test-kb-template-authoring-standard.sh`, all five are green, and
      `npx vitest run gen-reference` from `site/` passes. That is AC-3's substance; its tree-scoped
      clean-diff was evaluated at feature-001's own close and is not re-evaluated here
- [ ] Tests are deterministic and setup/teardown is clean -- both suites are pure reads over committed
      content, so two executions produce identical outcomes and there is nothing to tear down
- [ ] All section-6 quality gates pass
