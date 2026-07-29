# task-052: `test-graph-gap-ledger.sh` detection, severity, shape and zero-row assertions

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-047

**Scope:**
- Create `tests/canonical/test-graph-gap-ledger.sh` (feature-006 L4). It is discovered automatically
  by the `tests/canonical/test-*.sh` glob -- `.aid/knowledge/test-landscape.md` states that adding a
  suite needs no edit to `tests/run-all.sh`.
- The suite builds its **own** fixture tree under `mktemp -d`, in the style of
  `tests/canonical/test-guardrails-d012.sh` (which writes its own compliant `kb.html` inline), so A-6
  holds and nothing depends on `.aid/works/work-005-knowledge-graph/`. The fixture supplies its own
  `nodes.tsv`, `candidates.tsv`, relationship table and KB tree, and every path is passed to
  `detect-kb-gaps.mjs` through its four explicit flags.
- Assertions landed by this task: **`GL01`-`GL07`, `GL12` and `GL13`.**
- `tests/` sits outside `canonical/` and is never rendered, so this suite may name `canonical/...`
  paths freely -- boundary rule 5 binds the module, not the test.
- **This task creates the file; task-053 adds `GL08`-`GL11` to the same file.** That is why task-053
  depends on this one. Structure the suite -- helper functions, the fixture builder, the assertion
  reporting -- so task-053 can append its four assertions without restructuring anything, and so
  none of this task's assertions need to move.
- Out of scope: `GL08`-`GL11` (task-053); `GV01` in `tests/canonical/test-graph-view-shell.sh`
  (task-054); the enumeration suites `test-source-enumeration.sh`, `test-graph-single-scanner.sh`,
  `test-graph-node-partition.sh` and `test-graph-node-provenance.sh` (tasks 032 and 033,
  delivery-002).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-graph-gap-ledger.sh` exists, is discovered by `bash tests/run-all.sh`
      with no edit to the runner, and builds its entire fixture under `mktemp -d`.
- [ ] **`GL01`** -- a node with a `COVERAGE_BEARING` edge to a `kb:` id produces **no** row, asserted
      at every `Provenance` value including `inferred`.
- [ ] **`GL02`** -- a node covered only through an ancestor path produces **no** row.
- [ ] **`GL03`** -- every id in the fixture inventory carries `evidence_provenance` of `declared` or
      `derived`, and no `int:` id present in `candidates.tsv` appears in the ledger. This asserts
      feature-004's `no-inferred-node` invariant at the seam rather than a filter applied here, and
      goes red if that guarantee is ever weakened.
- [ ] **`GL04`** -- an uncovered entry-point node yields `[HIGH]`, depended-upon yields `[MEDIUM]`,
      named-unit-only yields `[LOW]`, and a node satisfying two clauses takes the higher.
- [ ] **`GL05`** -- the emitted file is exactly one seven-column table: no frontmatter, no heading,
      no summary section.
- [ ] **`GL06`** -- every `Line` cell is `—`, and every `Doc` cell is a repo-relative path that
      exists in the fixture.
- [ ] **`GL07`** -- a fixture with many gaps yields a non-empty ledger **and** exit status 0
      (FR-25 / AC-14). The many-gaps case is the tested case, not the untested one.
- [ ] **`GL12`** -- the import
      `import { detectKbGaps, kbUnbacked, COVERAGE_BEARING } from '../graph/coverage-predicate.mjs'`
      succeeds in a bare Node process run from the detector's own directory, and
      `canonical/aid/scripts/graph/` contains **no** `package.json`.
- [ ] **`GL13`** -- a fixture whose inventory contains an enumerated `int:` node appearing in **no**
      table row yields a ledger row for it with the severity from its clause, a `kb_gaps` entry
      carrying both `id` and `name`, and a `Description` ending `; no relationships in the table`;
      and removing that node from `nodes.tsv` while leaving the table untouched makes the row
      disappear, proving the candidate set is the inventory and not the table.
- [ ] Each assertion is separately identified by its `GL` id in the suite's output, so a failure
      names which one broke.
- [ ] Tests are deterministic (TEST default): no timing dependency, no external state leak, and no
      dependence on the host repository's own Knowledge Base, `nodes.tsv` or ledger directory.
- [ ] Clean setup and teardown (TEST default): every `mktemp -d` tree is removed on exit, including
      on failure, and no file is written under `.aid/.temp/review-pending/` outside the fixture.
- [ ] Source-feature acceptance criteria covered by this task (TEST default): **AC-14** via `GL07`,
      **AC-16**'s whole-artifact granularity via `GL06`, and the zero-row closure of FR-19/FR-20 via
      `GL13`. `GL08`-`GL11`, including AC-15's ledger-side agreement, are **task-053's**, and the
      suite records that so its coverage is not read as complete.
- [ ] The suite is left structured for extension, and a comment records that task-053 appends
      `GL08`-`GL11` to this same file.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
