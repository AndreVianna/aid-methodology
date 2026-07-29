# task-045: `coverage-predicate.mjs` and the `coverage_bearing` declaration

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

**Depends on:** task-002, task-015

**Scope:**
- Create `canonical/aid/scripts/graph/coverage-predicate.mjs`. **This is deliberately one task and
  not two**: feature-006 § Coordination obligations requires `/aid-detail` to produce **one** task
  for this file, dependent on both features, rather than two tasks editing the same lines. It owns
  the predicate's *semantics* (feature-006 D2) and the file's *contract* (feature-007 § The coverage
  predicate) together.
- The module exports exactly four symbols, all as top-level `export function` / `export const`
  declarations:
  - `COVERAGE_BEARING` -- `Set<string>` of relation names;
  - `isCovered(nodeId, edges)` -- `boolean`, the three-condition test;
  - `detectKbGaps({nodeIds, edges})` -- sorted `string[]`, the `int-undocumented` set;
  - `kbUnbacked({nodeIds, edges})` -- sorted `string[]`, the `kb-unbacked` set (browser-only caller,
    colocated so all coverage logic reads from one file).
- **The predicate**, adopted verbatim from feature-006 D2. An enumerated `int:` node is *covered*
  when at least one edge satisfies all three conditions: (1) the node is one of the edge's
  endpoints, **or** an ancestor path of the node is that endpoint -- an `int:` id *is* its
  repo-relative path with the prefix stripped, so path matching needs no new field; (2) the other
  endpoint carries the `kb:` prefix; (3) the relation naming that direction is a member of
  `COVERAGE_BEARING`. Coverage counts from edges of **any** `Provenance`, `inferred` included. The
  F4 class has an empty domain by feature-004's `no-inferred-node` invariant and is **not**
  implemented here.
- **The five boundary rules** of feature-007 § The Node/browser boundary, all of which the file
  obeys: (1) no `import`, no `require`, no `node:` specifier; (2) no `document`, `window`,
  `globalThis`, `fetch`, timer or event; (3) only top-level `export function` / `export const` --
  no `export {}` list and no default export; (4) every input and output is plain data (arrays,
  objects, `Map`, `Set`) and never a path, handle or stream, so all I/O stays in the callers;
  (5) the **render-transform invariant** -- no `canonical/...` path reference and none of the three
  filename placeholders, **in code or in comments**. Rule 5 is not optional politeness: `.mjs` is in
  `render.py`'s `_TEXT_EXTENSIONS`, and `rewrite_install_paths`' comment-skip test is
  `line.lstrip().startswith("#")`, which does **not** protect a JavaScript `//` or `/* */` comment.
- Author the **`coverage_bearing` sibling file** at the fixed path
  **`canonical/aid/templates/graph/coverage-bearing.yml`**, beside
  `canonical/aid/templates/graph/relation-vocabulary.yml` -- the reviewable, human-readable
  enumeration of the same subset by pair name, so a reviewer reads the vocabulary and the subset
  together (feature-006 D2). **Owner decision: a sibling file, not a third top-level key inside
  `relation-vocabulary.yml`.**
  **Its name and shape are fixed by owner decision (2026-07-28), not left to this task's executor:**
  one top-level key `coverage_bearing:` holding a flow-or-block sequence of `relation` names, each of
  which MUST be a `relation` value present in `relation-vocabulary.yml`'s `pairs:`. Same restricted
  YAML subset as the vocabulary (no nested mappings), and `.yml` so the renderer copies it verbatim
  rather than rewriting paths. Task-070's `GV04` reads **this** path -- it does not discover it. That keeps the vocabulary's two-top-level-key parse contract
  (`pairs:` + `categories:`) intact, keeps `rel_load_vocabulary` (task-015) from having to tolerate
  a third key, and avoids a delivery-003 task editing a delivery-001 artifact. If task-002's
  research produced a category that already means exactly "this KB concept describes / is derived
  from this artifact", the subset **is** that category: the sibling file records that and declares
  nothing further.
- The module's `COVERAGE_BEARING` and the sibling file are two copies by design; task-070's `GV04`
  binds them, and `GV05` asserts `COVERAGE_BEARING` is a subset of `RELATION_CATEGORY`'s keys.
- Header comment block stating Purpose / Usage / Exit codes per `.aid/knowledge/coding-standards.md`
  § JavaScript / Node Conventions -- carrying no path and no placeholder, per rule 5.
- **No `package.json` is created** in `canonical/aid/scripts/graph/`. The `.mjs` extension is the
  ESM marker; a marker file in a template-rendered tree would land a stray `package.json` in every
  adopter's install. `GL12` (task-052) asserts that directory contains none.
- Out of scope: `detect-kb-gaps.mjs` (task-046); the Status transitions, routing block and exit
  contract (task-047); the inlining into `graph.html` and `GV02`/`GV04`/`GV08` (delivery-004,
  tasks 065, 070, 071); `GV01`'s assertions (task-054); the FULL render (task-055).

**Acceptance Criteria:**
- [ ] `canonical/aid/scripts/graph/coverage-predicate.mjs` exists and exports exactly
      `COVERAGE_BEARING`, `isCovered`, `detectKbGaps` and `kbUnbacked` -- all as top-level
      `export function` / `export const` declarations, with no `export {}` list and no default
      export.
- [ ] Boundary rules 1, 2, 3 and 5 are greppable-clean: the file contains no `import`, no `require`,
      no `node:` specifier, no `document`, no `window`, no `globalThis`, no `fetch`, no timer or
      event API, no `canonical/` substring, and none of the three filename placeholders -- in code
      **and** in comments.
- [ ] Rule 4 holds: every exported function's inputs and outputs are plain data (arrays, objects,
      `Map`, `Set`); none takes or returns a path, file handle or stream.
- [ ] `isCovered` implements all three conditions including ancestor-path matching, and returns
      `true` for a covering edge at every `Provenance` value including `inferred`.
- [ ] `detectKbGaps({nodeIds, edges})` returns a sorted `string[]` of uncovered `int:` ids over
      whatever `nodeIds` it is given, so Node's full-inventory call and the browser's table-only call
      differ in candidate set and **not** in behaviour.
- [ ] `kbUnbacked({nodeIds, edges})` returns the sorted `kb:` ids having no edge to an `int:` node,
      and is **not** narrowed by `COVERAGE_BEARING` -- §2 item 1 says "no `int:` edge", full stop.
- [ ] The sibling file exists at exactly `canonical/aid/templates/graph/coverage-bearing.yml`, carries
      exactly one top-level key `coverage_bearing:`, and enumerates the subset by `relation` name in
      the same restricted YAML subset the vocabulary uses.
- [ ] `relation-vocabulary.yml` is **unmodified** by this task and still carries exactly two
      top-level keys, `pairs:` and `categories:` -- verified by `git diff` on that file being empty
      and by listing its column-0 `key:` lines.
- [ ] Every member of `COVERAGE_BEARING` appears as a `relation` value in `relation-vocabulary.yml`,
      and the module's set and the sibling file's list are the same set.
- [ ] `canonical/aid/scripts/graph/` contains no `package.json`, and importing the module in a bare
      Node process (Node >= 20, the C-5 floor) from that directory succeeds.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports the same set of
      green suites it did before this change, with none newly red.
- [ ] **The named suites land in task-054** (`tests/canonical/test-graph-view-shell.sh`, `GV01`'s
      boundary-rule assertions) **and task-052** (`tests/canonical/test-graph-gap-ledger.sh`,
      `GL12`'s bare-Node import and no-`package.json` assertion). *This replaces IMPLEMENT's "unit
      tests for all new public methods" default, which has no vehicle here: shell and Node scripts in
      this repository are covered by the `tests/canonical/test-*.sh` suites, which the
      one-type-per-task rule forces into separate TEST tasks.*
- [ ] The build for this repository is the profile render, and it runs for this delivery in
      **task-055**; this task hand-edits no file under `profiles/`, `.claude/` or `.cursor/`.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
