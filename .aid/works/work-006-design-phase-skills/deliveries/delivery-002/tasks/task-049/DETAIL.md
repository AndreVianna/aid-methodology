# task-049: Static and greppable verification sweep over the finished twenty-seven

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-049/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-048

**Scope:**
- Source specs: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V1**, **V2**
  (its row-count half), **V12**, **V13**, **V15**, **V22**, **V24** and **V25**'s static half; and
  `features/feature-005-design-grid-and-brainstorm/SPEC.md` §8 rows **V1**, **V2**, **V3**, **V4**,
  **V5**, **V6**, **V7**, **V8**, **V9**, **V10**, **V12**, **V13**, **V15**, **V16**, **V17**,
  **V18** and **V19**; plus `features/feature-002-design-lifecycle-machinery/SPEC.md` §7 row **G1**.
  It closes BLUEPRINT criteria 1, 2, 6's static half, 8, 9, 10 and 11.
- **It is the delivery's leaf and runs after task-048 deliberately, so that it audits a clean
  tree.** Every row here reads committed content; running it while task-039's throwaway render is
  still live would let a rendered artifact satisfy a criterion the canonical tree must satisfy on its
  own. This task **writes nothing** -- it is a read-only audit.
- **Aggregate presence, both features together** (BLUEPRINT criterion 1): the twenty-seven skill
  directories and twenty-seven complete catalog rows, each with `name` equal to its directory and to
  its frontmatter `name:`, `alias_of: null`, and `repurpose: true`.
- **The grid selection, verified in both directions** (BLUEPRINT criterion 2, CC-8): re-run
  feature-005 §2's derivation against `git show master:canonical/aid/templates/shortcut-catalog.yml`
  and `comm -3` its sorted output against the sorted `artifact` values of the fourteen `design` rows
  task-029 through task-031 added. Empty output, both directions. **And no "unpaired artifact"
  exclusion rule is asserted anywhere** -- a positive selection, not the residue of an exclusion.
- **The description sweep this delivery owns, and the one it does not** (BLUEPRINT criterion 9).
  Every side written here is
  checked -- feature-004's twelve, feature-005's fifteen, and the five shipped edits -- against the
  assignment tables in feature-004 §10 and feature-005 §7b/§7c, in both directions: every assigned
  neighbour appears, and no unassigned neighbour does. The **whole-set** pair check across all
  thirty-six is delivery-003's (feature-006 §8a).
- **The seed-count surfaces that must not move** (BLUEPRINT criterion 8): no file was added under
  `canonical/aid/templates/knowledge-base/`, and the named doc-set and matrix suites are green with
  their own files unchanged.
- **Bare `/aid-design`'s behavior** (BLUEPRINT criterion 10, feature-002 G1): the scoped diff,
  re-asserted at the gate rather than trusted from task-028, because this is the one shipped-behavior
  claim in the delivery that a wrong edit would silently break.
- **Two suites that must be green, and three instruments that must NOT be run here.**
  `tests/canonical/test-catalog-dirs-parity.sh` is **count-agnostic by design** (`:22-27`: *"derives
  its row set from the catalog and holds NO expected total, so it passes at any row count"*), so it
  extends by data with no edit and must be green. `tests/canonical/test-domain-doc-matrix.sh` and the
  other doc-set suites likewise. But `tests/canonical/test-deploy-monitor-repurpose.sh` carries
  `DMR30`/`DMR31` (`TOTAL_ROWS`/`CANONICAL_ROWS == 58`, `:319-320`), `DMR32`'s paired `58` (`:321-322`)
  and `DMR33` (`REPURPOSE_ROWS == 24`, `:324`), and `tests/canonical/check-skill-counts.mjs` is a
  repo-wide count guard whose `MARKER_CAP` is `12` (`:319`) with no headroom at exactly 12 -- all of
  these are **aggregates over the finished set of thirty-six and are retuned once, by delivery-003**.
  Running them here would report a **correct** mid-work state as a failure, and editing them here
  would move a ratchet delivery-003 owns. They are named so that a sweep does not reach for them.
- Out of scope: every count-bearing assertion and its retune (`TOTAL_ROWS`, `CANONICAL_ROWS`, the
  repurpose decomposition, `check-skill-counts.mjs`, the site card counts, the KB and methodology
  narratives) -- all delivery-003's; the `tests/coverage-baseline.tsv` re-bootstrap, which gains
  **144** rows (thirty-six catalog rows times the four per-row parity assertions a `repurpose` row
  emits -- `CDP{i}a` through `CDP{i}d`, since `CDP{i}e` is a `log` for such rows,
  `test-catalog-dirs-parity.sh:143-145`) and is a **CI-only** run that cannot execute from this
  Windows worktree; the full render and the byte-identity gate; and authoring any test script under
  `tests/` or adding any bash assertion id -- the ground is **feature-001 AC-3**.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** -- no row is reported as covered without its oracle and result (TEST default: all
      acceptance criteria from the source feature covered)
- [ ] **BLUEPRINT criterion 1 -- twenty-seven directories.**
      `ls -d canonical/skills/aid-design-{api,ui,theme,cli,data-model,data-pipeline,messaging,integration,job,config,infra,test,document,dashboard} canonical/skills/aid-brainstorm canonical/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}`
      returns 27 lines, exit 0 (feature-004 V1, feature-005 V1)
- [ ] **BLUEPRINT criterion 1 -- twenty-seven complete rows.**
      `grep -cE '^  - name: aid-(design|create|update)-(architecture|stack|testing-strategy|cicd)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `12` (feature-004 V2), and
      `grep -cE '^  - name: (aid-brainstorm|aid-design-(api|ui|theme|cli|data-model|data-pipeline|messaging|integration|job|config|infra|test|document|dashboard))$'`
      on the same file captured to a variable -> `15`. For each of the twenty-seven, frontmatter
      `name:` == directory name == row `name`
- [ ] **`alias_of: null` on every row, count-free** (feature-005 V4): with
      `C=canonical/aid/templates/shortcut-catalog.yml`,
      `[ "$(grep -c '^    alias_of: null$' "$C")" = "$(grep -c '^  - name:' "$C")" ]`. It fails if any
      row omits, misspells or aliases the field, and it holds at any row count.
      `test-catalog-dirs-parity.sh` is **not** an oracle for this -- `:72-77` records `alias_of` as
      dead input there, parsed and never asserted -- and `DMR31`/`DMR32` are count-bearing and are
      delivery-003's from here
- [ ] **`repurpose: true` on all twenty-seven, asserted so that the emitting count cannot move.** The
      set of row `name`s carrying **no** `repurpose` key is **identical** to that set derived from
      `git show master:canonical/aid/templates/shortcut-catalog.yml` -- `comm -3` over the two sorted
      lists is empty. This is the count-free form of *the `shortcuts` (emitting) quantity does not
      move*: every row this work adds is hand-authored, so a row that lost the key would appear in
      this diff. No expected integer is stated, because the integers are delivery-003's
- [ ] **BLUEPRINT criterion 2 / feature-005 V2, V17 -- the grid selection is exactly the paired
      set.** Run feature-005 §2's derivation against
      `git show master:canonical/aid/templates/shortcut-catalog.yml > <tmp>` and `comm -3` its sorted
      output against the sorted `artifact` values of this work's fourteen `design` grid rows -> empty,
      **both** directions. In particular the fourteen include no row for `architecture`, `stack`,
      `testing-strategy` or `cicd`, which are feature-004's four
- [ ] **BLUEPRINT criterion 2 / CC-8 -- no exclusion rule is asserted anywhere.**
      `grep -rniE 'unpaired' canonical/skills/ canonical/aid/templates/` returns **nothing**, and no
      body or catalog comment states that an artifact is excluded because it lacks a `create`/`update`
      pair. The selection is stated positively wherever it is stated at all
- [ ] **feature-005 V18 -- `kb` and the ticket skills stay outside the catalog.**
      `grep -cE '^  - name: (aid-update-kb|aid-(read|create|update)-ticket)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `0`. Anchored on the row form, because the catalog mentions
      `aid-update-kb` in a comment at `:457`
- [ ] **feature-005 V3 -- the parity suite is green, unmodified.**
      `bash tests/canonical/test-catalog-dirs-parity.sh` passes and
      `git diff master -- tests/canonical/test-catalog-dirs-parity.sh` is empty. It asserts
      `CDP{i}a` (directory exists), `CDP{i}c` (SKILL.md exists) and `CDP{i}d` (frontmatter `name:` ==
      directory == row name) for every row and is count-agnostic, so it extends by data with no edit
- [ ] **feature-005 V5, V6 and BLUEPRINT criterion 10 / feature-002 G1 -- bare `/aid-design`.**
      `grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md` captured to a variable ->
      `0`; its `description:` names the dedicated `design` rows as the route away from itself and
      reads as a **catch-all** rather than an artifact list (a reviewer judgement, recorded with the
      text quoted); and `git diff master -- canonical/skills/aid-design/SKILL.md` shows hunks
      confined to the YAML frontmatter block with **no hunk touching the four `DESIGN.md` sites**
      (`grep -n 'DESIGN.md'` locates them). A whole-file `--exit-code` diff is the wrong shape and
      would be unsatisfiable by construction
- [ ] **feature-005 V7, V8, V9 -- the three pairs this feature owns end to end are mutual.**
      `aid-research` <-> `aid-brainstorm`; `aid-prototype-ui` <-> `aid-design-ui`, each also stating
      the kept-versus-throwaway distinction (a reviewer read); and the `document` trio --
      `aid-design-document` naming both neighbours, with `aid-document` and `aid-create-document`
      each naming `/aid-design-document`. Every hit inside the file's frontmatter `description:`
      block
- [ ] **BLUEPRINT criterion 9 / feature-005 V10 and feature-004 V15 -- every side this delivery wrote, both directions.** For
      each row of feature-004 §10 and feature-005 §7b/§7c, the assigned neighbour's literal name
      appears in that skill's `description:`, **and** no description names a neighbour its table does
      not assign. The twelve foundation sides, the fifteen new feature-005 sides and the five shipped
      edits are all in scope; the whole-set check across thirty-six is delivery-003's
- [ ] **feature-004 V22 -- lane disclosure, all four `create` bodies.**
      `grep -c 'Conformance Lane' canonical/skills/aid-create-<A>/SKILL.md` captured to a variable is
      `>= 1` for `<A>` in `architecture stack testing-strategy cicd`, with the hit inside the
      frontmatter `description:` block
- [ ] **feature-004 V24 -- `testing-strategy` and `test` are two artifacts.** The catalog contains
      rows with `artifact: testing-strategy` **and** rows with `artifact: test`, and
      `grep -c 'artifact: test-strategy' canonical/aid/templates/shortcut-catalog.yml` captured to a
      variable -> `0` (its value today). `canonical/skills/aid-create-test/` and
      `canonical/skills/aid-create-testing-strategy/` are distinct directories
- [ ] **feature-004 V12 -- `quality-gates.md` on all four CC-4 surfaces, re-asserted whole.** The four
      per-surface oracles of feature-004 §8a all pass **together**, including the two "no edit"
      surfaces -- `grep -c '^### quality-gates.md' canonical/skills/aid-discover/references/document-expectations.md`
      -> `1`, and `grep -c 'quality-gates.md'` >= 1 in **each** of
      `canonical/aid/scripts/kb/kb-actback-task.sh` and
      `canonical/aid/scripts/kb/kb-dual-intent-probes.sh` -- plus the concern-id greps returning
      **C6** on surfaces 1 and 2, plus `bash tests/canonical/test-domain-doc-matrix.sh` green with
      `git diff master -- tests/canonical/test-domain-doc-matrix.sh` empty
- [ ] **feature-004 V13 / BLUEPRINT criterion 8 -- no seed-count assertion moved.**
      `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable -> `14`, and
      `git diff master --` is **empty** on each of
      `tests/canonical/test-kb-template-authoring-standard.sh`,
      `tests/canonical/test-doc-set-read.sh`, `tests/canonical/test-doc-set-mapping.sh`,
      `tests/canonical/test-domain-doc-matrix.sh`, `tests/canonical/test-spine-depth-coverage.sh` and
      `canonical/skills/aid-discover/references/doc-set-resolve.md`, with all five suites green
      unmodified. `git diff master` rather than `--exit-code`, which compares the working tree to
      `HEAD` and passes trivially once an edit is committed
- [ ] **feature-004 V25's static half:** `git diff master -- canonical/aid/templates/work-state-template.md`
      is empty. The behavioral half -- no `phase:` value in any run's work `STATE.md` -- was recorded
      per run by task-040 through task-047, whose evidence lives in their STATE.md notes
- [ ] **BLUEPRINT criterion 11 -- the twenty-seven bind the shared contract rather than forking it**,
      four conjuncts: (a)
      `grep -L 'canonical/aid/templates/design-lifecycle.md'` over all twenty-seven `SKILL.md` files
      produces **empty** output (feature-005 V15); (b) a reviewer confirms no body restates the
      contract's rules -- the `design` invariant, the allocation steps, the seed headings or the
      verify depth (feature-005 V16); (c) every `design` body states that it writes only within
      `.aid/design/`, and no body drives a `phase:` value; (d) each of the four `update` bodies
      carries the derived-outputs prompt as an unconditional step storing no answer
- [ ] **feature-005 V12 and V13 -- the engine read, statically.**
      `grep -c '\.aid/design/{artifact}\.md' canonical/aid/templates/shortcut-engine.md` captured to a
      variable -> `1`;
      `grep -l '\.aid/design/document\.md' canonical/skills/aid-create-document/SKILL.md canonical/skills/aid-update-document/SKILL.md`
      lists both; and `git diff --numstat master -- canonical/aid/templates/shortcut-engine.md` shows
      **0 deletions** with the additions in exactly two hunks
- [ ] **feature-005 V19 -- the `brainstorm` family renders**, as a reading rather than a run:
      `aid-brainstorm` is absent from `CURATED_GROUPS` in `site/scripts/skills/groups.mjs` (`:63`
      onward) and its row is in the catalog, and that file derives families by walking `catalog.rows`
      in file order (`:254-262`), so a one-card section appears with no code change. The run-time
      oracle is delivery-003's site guard
- [ ] **The three instruments named in § Scope are NOT run and NOT edited here** --
      `tests/canonical/test-deploy-monitor-repurpose.sh`, `tests/canonical/check-skill-counts.mjs`
      and the `tests/coverage-baseline.tsv` re-bootstrap. `git diff master -- tests/` shows no change
      to any of them, and this task's record states that they were deliberately not executed, with
      the reason: each is an aggregate over the finished thirty-six and would report a correct
      mid-work state as a failure
- [ ] This task writes nothing: `git status --porcelain` over `canonical/`, `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `.aid/works/`, `profiles/`, `.claude/`, `.cursor/`,
      `tests/` and `site/scripts/__tests__/` is **identical before and after**, and
      `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- every row is a grep, a diff, a `comm` or
      a named suite over committed content, so two executions produce identical outcomes and there is
      nothing to tear down
- [ ] All section-6 quality gates pass
