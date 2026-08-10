# task-034: `quality-gates.md` completed across CC-4's four registration surfaces

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-034/STATE.md.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-033

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §8, §8a (the four
  surfaces, their state on disk and the per-surface oracle), §8b (why this repository needs no
  dogfood migration), §8c, and AC-7. The surface **set** is REQUIREMENTS **CC-4**, defined once
  in feature-001 §1b; this task substitutes no different set and adds no fifth.
- **It runs after task-033 and before the `create` bodies** for a stated reason: feature-004 §12
  makes the registration land *"with, or after, feature-001 §2b's amendment"* (delivery-001's, so
  already in), and the `create` bodies that reference the completed surfaces are task-035
  onward. `/aid-create-testing-strategy` is the skill that creates this document on demand, so
  its doctrine must exist before its body cites it.
- **Two surfaces are this task's to write. Two are already occupied and are asserted, not
  edited.** That is what makes the work smaller than "four surfaces" suggests:
  - **Surface 1 -- `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`.** Today
    `quality-gates.md` has exactly one row: `methodology-tooling`, C6, `aid-researcher-quality`,
    `required` (`:321`). Add a `conditional:<when>` row in each domain section whose C6 doc is
    `test-landscape.md` -- **`software-cli`** and **`software-web`**, whose `test-landscape.md`
    C6 rows sit at `:142` and `:171` -- in the manner of `decisions.md`'s conditional rows
    (`:146`, `:176`). Owner `aid-researcher-quality`, matching `:321`. **Not** added to
    `methodology-tooling`, which already carries it as required, nor to the five domains that
    realize C6 differently. The `<when>` hint carries **no comma**
    (`canonical/skills/aid-discover/references/doc-set-resolve.md:46-54`).
  - **Surface 2 -- `canonical/aid/templates/kb-authoring/concern-model.md`.** `quality-gates.md`
    is **absent** there today (`grep -c 'quality-gates'` -> `0`). List it with the other
    conditional docs alongside `decisions.md`, carrying concern **C6**.
  - **Surface 3 -- `canonical/skills/aid-discover/references/document-expectations.md`.** Already
    occupied: `### quality-gates.md` at `:632`. **No edit**; the block stays and its oracle must
    still return its hit.
  - **Surface 4 -- `_dim_of_filename`, both twins.** Already occupied:
    `canonical/aid/scripts/kb/kb-actback-task.sh:216` and
    `canonical/aid/scripts/kb/kb-dual-intent-probes.sh:237` both list it in the C6 arm. **No
    edit** to either; both entries stay.
- **The concern id is `C6`**, matching this repository's live tags
  (`.aid/knowledge/quality-gates.md:15`) and the matrix's methodology row. It is asserted on
  surfaces 1 and 2 **by grep** and explicitly **not** by `AS07`, whose loop runs over a `find`
  across `canonical/aid/templates/knowledge-base/`
  (`tests/canonical/test-kb-template-authoring-standard.sh:50`, loop `:117-131`) and therefore
  can never see a document that has no template there.
- **No canonical template is added, and that is the point.** `quality-gates.md` stays a
  **conditional** document created on demand -- the `decisions.md` treatment -- so `AS06`'s
  find-count and every other seed-count assertion are untouched.
- **Why a conditional row cannot move the three suites that read this file** (§1d's table, and
  the reason each criterion below is an assertion rather than a hope): `MT01`/`MT02` compare only
  the **required** sets (`tests/canonical/test-domain-doc-matrix.sh:152-173`), extracting rows via
  `/\| required/`; `MT07`/`MT08` assert each of the eleven dimensions is covered by >= 1 doc
  (`:227-252`), and C6 is already covered in both domains by `test-landscape.md`, so a second C6
  doc cannot uncover it; `SD04`/`SD05` assert each non-meta matrix doc's dimension resolves to a
  present, non-empty depth block (`tests/canonical/test-spine-depth-coverage.sh:152-193`) and C6's
  block exists and is non-empty, while `SD07` is a `>=58` floor (`:205-211`) that added rows can
  only raise.
- Out of scope: the doc-set entry in `.aid/settings.yml` and the `README.md` Completeness row --
  those are **runtime writes by the `create` skill** under CC-2, specified in feature-004 §3b, and
  are **not a fifth surface**; any edit to `.aid/settings.yml` or `.aid/knowledge/quality-gates.md`
  in this repository, which §8b shows already carry exactly what §3b would write; any test-script
  edit; and the pre-existing `kb-category: extension` / doc-set-membership mismatch on the live
  document, which predates this work and is a `/aid-housekeep` hygiene item.

**Acceptance Criteria:**
- [ ] feature-004 V12 / AC-7 surface 1: `grep -n 'quality-gates.md' canonical/aid/templates/kb-authoring/domain-doc-matrix.md`
      returns `:321` **plus exactly two new rows**, one inside the `software-cli` table and one
      inside the `software-web` table. Membership in the right table is asserted positionally
      against `S = grep -n '^### Domain: .software-cli.'` (today `:121`),
      `W = grep -n '^### Domain: .software-web.'` (`:151`) and
      `N = grep -n '^### Domain: .data-ml.'` (`:183`): the first new row's line lies in
      `(S, W)` and the second in `(W, N)`
- [ ] Each new row carries four fields in the schema's order with concern **C6**, owner
      **`aid-researcher-quality`**, and a `conditional:<when>` presence whose `<when>` contains
      **no comma**
- [ ] feature-004 V12 / AC-7 surface 2:
      `grep -c 'quality-gates' canonical/aid/templates/kb-authoring/concern-model.md` captured to
      a variable is `>= 1` (it is `0` today) and the hit names **C6**
- [ ] feature-004 V12 / AC-7 surface 3, asserted **without** an edit:
      `grep -c '^### quality-gates.md' canonical/skills/aid-discover/references/document-expectations.md`
      captured to a variable -> `1`, and
      `git diff --exit-code master -- canonical/skills/aid-discover/references/document-expectations.md`
      shows only the hunks delivery-001 committed
- [ ] feature-004 V12 / AC-7 surface 4, asserted **without** an edit:
      `grep -c 'quality-gates.md'` captured to a variable is `>= 1` in **each** of
      `canonical/aid/scripts/kb/kb-actback-task.sh` and
      `canonical/aid/scripts/kb/kb-dual-intent-probes.sh`, and
      `git diff --exit-code master -- canonical/aid/scripts/kb/` shows only the hunks
      delivery-001 committed. Both twins, because one twin passing is how the pair drifts
- [ ] **All four surfaces pass together**, which is what AC-7 requires -- a run that lands
      surfaces 1 and 2 while surface 3's or 4's hit has disappeared fails this criterion
- [ ] feature-004 AC-7's suite half: `bash tests/canonical/test-domain-doc-matrix.sh` is green
      **and** `git diff master -- tests/canonical/test-domain-doc-matrix.sh` is empty -- MT01
      through MT18 unmodified. `git diff master` rather than `--exit-code`, which compares the
      working tree to `HEAD` and passes trivially once an edit is committed
- [ ] feature-004 V13 / AC-15, the part this task can move and must not:
      `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`, and
      `bash tests/canonical/test-spine-depth-coverage.sh`,
      `bash tests/canonical/test-kb-template-authoring-standard.sh`,
      `bash tests/canonical/test-doc-set-read.sh` and
      `bash tests/canonical/test-doc-set-mapping.sh` are green with `git diff master --` empty on
      each of their files and on
      `canonical/skills/aid-discover/references/doc-set-resolve.md`
- [ ] This repository is **not** migrated: `git diff --exit-code master -- .aid/settings.yml .aid/knowledge/quality-gates.md`
      shows only what delivery-001 committed to `.aid/settings.yml` and nothing at all on
      `quality-gates.md` (§8b -- the live entry already reads
      `quality-gates.md|aid-researcher-quality|required` at `.aid/settings.yml:53`)
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean and
      `git status --porcelain profiles/ .claude/ .cursor/` is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
