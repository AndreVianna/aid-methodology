# task-046: `detect-kb-gaps.mjs` gap detection, ledger emission and `kb_gaps` record

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-019, task-023, task-045

**Scope:**
- Create `canonical/aid/scripts/graph/detect-kb-gaps.mjs` (feature-006 L2) -- Node, not bash, ES
  module syntax, Node >= 20 (C-5). It sits beside `coverage-predicate.mjs` in the same `graph/`
  script area, so the import is a plain relative sibling specifier.
- Command-line interface, four explicit paths with **no baked-in default**, so task-052's fixture
  supplies its own and A-6 holds:
  `node detect-kb-gaps.mjs --table PATH --nodes PATH --output PATH [--previous PATH]`.
  There is **no `--vocabulary` flag**: `COVERAGE_BEARING` is a compile-time constant inside
  `coverage-predicate.mjs`, and passing the vocabulary in at run time would create a second way for
  the two copies to disagree.
- `import { detectKbGaps } from './coverage-predicate.mjs'`. **No predicate logic is written in this
  file** -- feature-006 D2 states there is exactly one implementation and that this feature does not
  hold it. `kbUnbacked` is not called here; it is lens-only.
- Read the final post-pass-2 relationship table (feature-003's eight columns, written by task-023)
  into the edge list, and feature-004's `.aid/.temp/graph/nodes.tsv` (task-019) into the candidate
  inventory. Call `detectKbGaps({ nodeIds, edges })` with `nodeIds` = **every** enumerated `int:` id,
  including those appearing in no table row. The candidate set is the **inventory**, never the
  table's node column -- computing over table rows alone would make the ledger blind to the worst
  finding it exists to produce.
- Decorate each returned id from the same inventory: display `name` from `nodes.tsv` field 2, FR-21
  clause from field 4 (`qualifier`), FR-24 `evidence` from field 5.
- **D4 severity join**, derivable and never judged: `entry-point` / `public-surface` -> `[HIGH]`;
  `depended-upon` -> `[MEDIUM]`; `named-unit` only -> `[LOW]`. A node satisfying more than one clause
  takes the **highest**. `[CRITICAL]` and `[MINOR]` are never assigned, for the reasons D4 records.
- **D5 row emission** -- exactly the seven columns of
  `canonical/aid/templates/reviewer-ledger-schema.md`, with no extra column and no narrative
  anywhere in the file: `#` sequential; `Severity` bracketed; `Status`; `Doc` = the `int:` id with
  its prefix stripped, so the cell is a directly openable repo-relative path; `Line` = `—` always
  (FR-23 fixes granularity at the whole artifact); `Description` in the fixed form
  `no Knowledge Base document covers <int-id> (qualified as <clause>)`, gaining the trailing
  `; no relationships in the table` clause when the node appears in no row; `Evidence` in the form
  `<rule> — <disk fact>; recheck: grep -c 'int:<path>' .aid/knowledge/relationships.md = 0`. Any `|`
  inside `Description` or `Evidence` is escaped `\|` per the schema's pipe rule.
- Write **`kb_gaps`** into `.aid/knowledge/relationships.md`'s own frontmatter: one entry per gap, in
  list order, each carrying `id`, `name`, `severity` and `clause`. It is written from the same call
  the rows are built from, so the two cannot diverge within a run. This is the only write inside
  `.aid/knowledge/`, and `relationships.md` is on `/aid-graph`'s own write allowlist (task-028's
  fence), so AC-13 is not tripped.
- Conventions per `.aid/knowledge/coding-standards.md`: a header comment block stating Purpose /
  Usage / Exit codes matching `validate-visuals.mjs`'s shape; stdout carries the result, stderr
  carries diagnostics prefixed `detect-kb-gaps.mjs: `; configuration read through
  `canonical/aid/scripts/config/read-setting.sh`, never by parsing `.aid/settings.yml` directly. The
  file is `.mjs` and therefore text-processed at render, so it carries **no `canonical/...` path and
  no filename placeholder**.
- Out of scope: the `Pending`/`Fixed`/`Recurred` transitions and the previous-ledger diff, the
  routing block, and the exit contract (all task-047); the predicate itself (task-045); the
  GAP-REPORT state body (task-050) and its `SKILL.md` dispatch row (task-051); the FULL render
  (task-055).

**Acceptance Criteria:**
- [ ] `canonical/aid/scripts/graph/detect-kb-gaps.mjs` exists, accepts exactly `--table`, `--nodes`,
      `--output` and optional `--previous` with no baked-in path default, and declares no
      `--vocabulary` flag.
- [ ] It imports `detectKbGaps` from `./coverage-predicate.mjs` and contains **no** reimplementation
      of the three coverage conditions: grep of this file finds no `COVERAGE_BEARING` membership
      test, no `kb:`-endpoint test and no ancestor-path test.
- [ ] `nodeIds` is the full `nodes.tsv` inventory, not the table's node column: on a fixture whose
      inventory contains an enumerated `int:` node appearing in no table row, that node is in the
      returned gap set; removing it from `nodes.tsv` while leaving the table untouched removes it.
      (`GL13`, asserted in task-052.)
- [ ] Severity derives from `nodes.tsv` field 4 exactly as D4 maps it, the multi-clause case takes
      the higher, and no input can make the script emit `[CRITICAL]` or `[MINOR]`.
- [ ] The emitted file at `--output` is exactly one seven-column markdown table -- no frontmatter, no
      heading, no summary section (C-6 and the schema's anti-`## Summary` rule).
- [ ] Every `Line` cell is `—`, and every `Doc` cell is the `int:` id with its prefix stripped,
      yielding an existing repo-relative path.
- [ ] `Description` matches the fixed form, and gains the trailing `; no relationships in the table`
      clause for exactly those nodes appearing in no table row and no others.
- [ ] `Evidence` carries feature-004's FR-24 qualification evidence verbatim plus the runnable
      recheck command, and any `|` in `Description` or `Evidence` is escaped `\|`.
- [ ] `kb_gaps` is written into `relationships.md`'s frontmatter with one entry per emitted row in
      list order, each carrying all four keys `id`, `name`, `severity`, `clause`; `name` comes from
      `nodes.tsv` field 2 and is never re-derived from the id, because a zero-row node has no
      `GraphModel` node to read a label from.
- [ ] No file under `.aid/knowledge/` other than `relationships.md`'s frontmatter is written by this
      script, and no ticket is opened.
- [ ] `canonical/aid/scripts/kb/lint-frontmatter.sh` emits nothing for a document carrying
      `kb_gaps:`, and `build-kb-index.sh` composes an unchanged row for it -- both read named fields
      only, so C-7 and AC-18 are undisturbed.
- [ ] The file contains no `canonical/` substring and no filename placeholder, and its header block
      states Purpose / Usage / Exit codes; stderr messages carry the `detect-kb-gaps.mjs: ` prefix.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports no newly red suite.
- [ ] **The named suite lands in task-052** (`tests/canonical/test-graph-gap-ledger.sh`, covering
      `GL01`-`GL07`, `GL12` and `GL13`). *This replaces IMPLEMENT's "unit tests for all new public
      methods" default, which has no vehicle here: Node scripts in this repository are covered by the
      `tests/canonical/test-*.sh` suites, which the one-type-per-task rule forces into separate TEST
      tasks.*
- [ ] The build for this repository is the profile render, and it runs for this delivery in
      **task-055**; this task hand-edits no file under `profiles/`, `.claude/` or `.cursor/`.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
