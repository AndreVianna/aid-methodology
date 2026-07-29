# task-033: The three enumeration seam and invariant suites

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-019, task-021, task-032

**Scope:**

- Create the three suites feature-004's Layers table names, each guarding an invariant other
  features are told to trust:
  1. **`tests/canonical/test-graph-single-scanner.sh`** -- the seam guard. Assert that within
     `canonical/aid/scripts/graph/`, **no file other than `scan-source.sh`** contains a
     *repository* traversal -- a `find` or `git ls-files` whose root is the repository root. A
     second walk fails the suite. The scoping to *repository* traversal is load-bearing and must
     be asserted as such: the suite must **not** fire on the sibling reads that are legitimately
     not a second walk -- feature-005's pass 1a reading `.aid/knowledge/` non-recursively at
     `-maxdepth 1`, and feature-010's staleness digest hashing the paths already listed in
     `nodes.tsv` plus that same depth-1 KB directory. Include a positive control (a temporary
     fixture script containing a root-rooted `find`, asserted to be caught) and negative
     controls for both legitimate shapes.
  2. **`tests/canonical/test-graph-node-partition.sh`** -- the `kb:` / `int:` disjointness
     invariant (D4 Class 4). Assert over `nodes.tsv` that no `int:` node id names a path under
     `.aid/knowledge/`, and that the `int:` node set and the `kb:` node set of
     `.aid/.temp/graph/kb-nodes.tsv` share no member. The invariant exists so a KB doc cannot
     appear on both sides of the coverage question -- documenting itself, or being reported as an
     undocumented source artifact.
  3. **`tests/canonical/test-graph-node-provenance.sh`** -- the `no-inferred-node` invariant
     (D3). Assert, **on the fixture tree and on this repository**, that field 6 of every
     `nodes.tsv` row is `declared` or `derived` and never `inferred`; and that no `candidates.tsv`
     row whose `candidate_kind` is `node` has a `subject` appearing as a `nodes.tsv` `node_id`.
     The scoping to `node` candidates is deliberate and must be preserved: an **edge** candidate's
     subject legitimately involves enumerated nodes -- an unresolvable reference between two real
     artifacts is exactly what `unresolved-reference` records -- so asserting over all candidates
     would fail on correct output. Also assert the single-writer guard: a row whose
     `evidence_provenance` is neither `declared` nor `derived` makes the writer exit non-zero
     rather than be silently filtered.
- Fixtures reuse the miniature repository task-032 builds at
  `tests/canonical/fixtures/graph/tree/`, materialised into a `mktemp -d` git repository; the
  repository-scoped assertions of `test-graph-node-provenance.sh` run against a scan of this
  checkout. No fixture depends on any work folder's contents (A-6).
- Out of scope: the per-clause / per-class / granularity / settling suite (**task-032**); the
  scanner and rules library (tasks 017, 018, 019); feature-005's `kb-nodes.tsv` producer
  (task-021), whose output the partition suite consumes.
- Each suite is discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob with **no
  edit to `tests/run-all.sh`**, sources `tests/lib/assert.sh`, and uses the `ID + description`
  assertion-label convention of `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] All three suites exist at `tests/canonical/test-graph-single-scanner.sh`,
      `tests/canonical/test-graph-node-partition.sh`, and
      `tests/canonical/test-graph-node-provenance.sh`; each sources `tests/lib/assert.sh`, uses
      the `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] `test-graph-single-scanner.sh` fails when a file other than `scan-source.sh` under
      `canonical/aid/scripts/graph/` contains a repository-rooted `find` or `git ls-files`, and
      passes on a `-maxdepth 1` read of `.aid/knowledge/` and on a hash pass over paths listed in
      `nodes.tsv` -- with an explicit positive control and both negative controls asserted.
- [ ] `test-graph-node-partition.sh` asserts no `int:` node id names a path under
      `.aid/knowledge/`, and that the `int:` and `kb:` node sets are disjoint.
- [ ] `test-graph-node-provenance.sh` asserts field 6 of every `nodes.tsv` row is `declared` or
      `derived`, on both the fixture tree and this repository.
- [ ] `test-graph-node-provenance.sh` asserts no `candidates.tsv` row with `candidate_kind` =
      `node` has a `subject` appearing as a `nodes.tsv` `node_id`, and the assertion is scoped to
      `node` candidates only -- an `edge` candidate whose subject is an enumerated node does not
      fail it.
- [ ] The single-writer guard is asserted: an out-of-enum `evidence_provenance` makes the writer
      exit non-zero rather than filter the row.
- [ ] No suite and no fixture reads any path under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every artifact is created under `mktemp -d` and removed on
      exit including on failure (`trap`); `git status --porcelain` is clean after each suite
      runs.
- [ ] **Every acceptance criterion from feature-004 that these suites carry is covered**: the
      single-scanner seam, the `kb:`/`int:` disjointness invariant, and the `no-inferred-node`
      invariant that FR-24 rests on end to end.
- [ ] All three suites pass under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing
      suite regresses.
