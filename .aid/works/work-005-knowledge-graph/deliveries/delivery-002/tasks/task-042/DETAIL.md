# task-042: `test-graph-read-only.sh` fence suite

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

**Depends on:** task-028

**Scope:**

- Create `tests/canonical/test-graph-read-only.sh`, the suite feature-010 names as mechanism
  **E4** -- "a test that tries to violate it" -- and which closes **AC-13**. Its whole point is
  that the violation path is the tested path: the suite builds a fixture KB, snapshots it, runs
  the fence's verify against a **deliberately mutated** KB doc, and asserts a non-zero exit
  naming that path.
- **The core E4 assertion.** `kb-write-fence.sh --snapshot` over a fixture `.aid/knowledge/`,
  then mutate one non-allowlisted KB doc, then `--verify`: exit is **non-zero (1)** and the
  offending path is **named in the output**.
- **All three violation shapes**, because the fence diffs a set and not just contents: a
  non-allowlisted file **changed**, one **added**, and one **removed** each make `--verify` exit
  1 and name the path.
- **Multiple violations are all reported.** With three files mutated at once, assert all three
  paths appear -- the fence must name **every** offending path, not only the first, because the
  closing summary has to state which artifacts cannot be trusted.
- **The clean case.** With nothing changed between snapshot and verify, `--verify` exits `0` and
  prints no path.
- **The D3 allowlist holes are asserted individually**, so a future widening of the allowlist is
  a visible test change rather than a silent one:
  - `W1` `.aid/knowledge/relationships.md` -- writing it between snapshot and verify does **not**
    fail.
  - `W2` `.aid/knowledge/graph.html` -- likewise.
  - `W3` `.aid/knowledge/graph-assets/**` -- creating and writing a companion asset there does
    **not** fail.
  - Every other `.aid/knowledge/` file **does** fail. Include `INDEX.md` explicitly: the
    accidental-`build-kb-index.sh` case is the concrete scenario feature-010 gives for why an
    allowlist alone is insufficient, so assert that regenerating `INDEX.md` between snapshot and
    verify is caught.
  - `W4` and `W5` live outside `.aid/knowledge/` and are asserted to be outside the walked set
    entirely -- writing `.aid/.temp/review-pending/graph.md` or anything under
    `.aid/.temp/graph/` does not fail verify.
- **FR-9's companion-asset rule is asserted as the concrete predicate feature-010 states**: no
  companion asset may be a `*.md` file sitting directly in `.aid/knowledge/`. A fixture asset
  placed at `.aid/knowledge/graph-assets/x.css` passes; one placed at `.aid/knowledge/x.md`
  fails the fence.
- **Snapshot determinism.** Two snapshots of the same unchanged fixture are byte-identical; the
  snapshot file is `LC_ALL=C`-sorted, LF-only, and contains no timestamp and no absolute path.
- **The exit contract.** `0` clean, `1` violation, `2` usage (no mode, unknown flag, both modes).
- Each fixture KB is built under `mktemp -d` (A-6). The suite **never** mutates this repository's
  `.aid/knowledge/` -- which would be the very violation it exists to detect -- and reads no work
  folder.
- Out of scope: the refusal suite (**task-040**), the staleness suite (**task-041**), the reuse
  verification (**task-043**), `kb-write-fence.sh` itself (task-028), and the state bodies that
  wire `--snapshot` / `--verify` into every exit path (task-030).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-graph-read-only.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] The E4 core case is asserted: snapshot, mutate a non-allowlisted KB doc, verify -> exit
      non-zero **and** the mutated path is named in the output.
- [ ] All three violation shapes -- changed, added, removed -- are each asserted to exit `1` and
      name the path.
- [ ] With three simultaneous violations, all three paths are asserted present in the output.
- [ ] The clean case is asserted to exit `0` with no path printed.
- [ ] `W1`, `W2` and `W3` writes are each asserted **not** to fail verify, and each is a separate
      assertion.
- [ ] Regenerating `INDEX.md` between snapshot and verify is asserted **caught**.
- [ ] Writing `.aid/.temp/review-pending/graph.md` and writing under `.aid/.temp/graph/` are each
      asserted not to fail verify.
- [ ] FR-9's predicate is asserted: an asset at `.aid/knowledge/graph-assets/x.css` passes and an
      asset at `.aid/knowledge/x.md` fails.
- [ ] Two snapshots of an unchanged fixture are asserted byte-identical, `LC_ALL=C`-sorted,
      LF-only, and free of timestamps and absolute paths.
- [ ] Exit `2` is asserted for no mode, an unknown flag, and both modes given.
- [ ] The suite never mutates this repository's `.aid/knowledge/`, and reads no path under
      `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-010 that this suite carries is covered**:
      **AC-13** via E4, and FR-10's read-only guarantee including the D3 allowlist boundary and
      FR-9's companion-asset rule.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
