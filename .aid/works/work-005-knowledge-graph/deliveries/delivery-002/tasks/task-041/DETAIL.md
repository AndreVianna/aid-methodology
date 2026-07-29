# task-041: `test-graph-stale-check.sh` staleness suite

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

**Depends on:** task-027

**Scope:**

- Create `tests/canonical/test-graph-stale-check.sh`, the suite feature-010's L3 table names for
  **AC-12**: "`CURRENT` on an unchanged fixture; `STALE` after `--reset`; and the wider-input-set
  criterion: mutate only a `SRC` file, leave the KB untouched, assert `STALE`".
- This suite is only meaningful because task-038 proves the class-0 block is byte-identical on an
  unchanged tree: without that, an unchanged-input `CURRENT` verdict could not be distinguished
  from generator churn. Assert the digest property directly rather than relying on that
  inference -- recompute the digest twice on an unchanged fixture and assert the identical hex
  string.
- **The three verdicts** of feature-010's STALE-CHECK table, each with a fixture:
  - `FIRST_RUN` -- asserted twice: `relationships.md` **absent**, and present but carrying **no
    `graph_inputs_digest`**.
  - `STALE` -- the recomputed digest differs from the stored one; and, separately, `graph.html`
    is expected for the build and its embedded `<!-- aid-graph inputs-digest: <hex> -->` differs
    from `relationships.md`'s.
  - `CURRENT` -- both artifacts present and both digests equal the recomputed digest.
- **AC-12's three named cases:**
  1. **`CURRENT` on an unchanged fixture** -- no input touched, verdict `CURRENT`, and the run is
     a true no-op: no file written anywhere.
  2. **`--reset` forces `STALE`** -- with inputs unchanged and digests equal, `--reset` still
     yields `STALE`, bypassing the comparison.
  3. **Source-only mutation still yields `STALE`** -- mutate exactly one file in the enumerated
     node set, leave every `.aid/knowledge/*.md` byte-unchanged, and assert the verdict is
     `STALE` and the changed-component report names **`SRC`** and not `KB`. This is FR-11's wider
     input set, and it is the criterion a date-comparison mechanism cannot satisfy.
- **The three digest components, each independently asserted:**
  - `KB` -- mutating a non-allowlisted `.aid/knowledge/*.md` changes the digest; mutating
    `relationships.md` or `graph.html` (both on the D3 allowlist) does **not**. Assert `INDEX.md`
    **is** included, since its exclusion would blind the check to genuine index changes.
  - `SRC` -- mutating a path listed in `nodes.tsv` changes the digest; adding a file that is
    *not* enumerated does not.
  - `EXT` -- mutating `.aid/knowledge/external-sources.md` changes the digest.
- **Byte-stability of the digest.** Recomputing over the same fixture under a deliberately
  non-C caller locale yields the identical hex string, proving the component lists are
  `LC_ALL=C`-sorted and the join order is fixed.
- **No `CURRENT_UNAPPROVED` verdict exists.** Assert by grepping the script and by asserting the
  verdict vocabulary is exactly the three values -- `/aid-summarize`'s third verdict has no
  counterpart, because currency here is content-addressed rather than approval-addressed.
- **Always exit 0.** Assert exit status `0` for all three verdicts and for `--reset`; `2` only
  for a usage error. The decision is informational, never a failure.
- **No second traversal.** Assert the script derives `SRC` from the paths listed in
  `.aid/.temp/graph/nodes.tsv` and performs no repository-rooted `find` or `git ls-files`, so
  feature-004's single-scanner seam holds.
- **The verdict is the last stdout line.** Assert the changed-component report precedes it and
  does not displace it.
- Each fixture builds its own KB, node list and artifacts under `mktemp -d` (A-6); the suite
  never mutates this repository's `.aid/knowledge/` and reads no work folder.
- Out of scope: the refusal suite (**task-040**), the fence suite (**task-042**), the reuse
  verification (**task-043**), and `graph-stale-check.sh` itself (task-027).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-graph-stale-check.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] Recomputing the digest twice on an unchanged fixture is asserted to yield the identical hex
      string.
- [ ] `FIRST_RUN` is asserted for both the absent-`relationships.md` and the
      present-without-`graph_inputs_digest` fixtures.
- [ ] `STALE` is asserted both for a digest mismatch and for a `graph.html` whose embedded digest
      differs from `relationships.md`'s.
- [ ] `CURRENT` is asserted on an unchanged fixture, and the run is asserted to write no file.
- [ ] `--reset` is asserted to force `STALE` with inputs unchanged.
- [ ] The source-only mutation case is asserted: exactly one enumerated source file changed, the
      KB byte-unchanged, verdict `STALE`, and the changed-component report naming `SRC` and not
      `KB`.
- [ ] Each of `KB`, `SRC`, `EXT` is asserted to move the digest independently; mutating an
      allowlisted path (`relationships.md`, `graph.html`) is asserted **not** to; `INDEX.md` is
      asserted to be inside `KB`; an unenumerated new file is asserted **not** to move `SRC`.
- [ ] The digest is asserted byte-stable under a non-C caller locale.
- [ ] The verdict vocabulary is asserted to be exactly `FIRST_RUN` / `STALE` / `CURRENT`, with no
      `CURRENT_UNAPPROVED` anywhere in the script.
- [ ] Exit status is asserted `0` for all three verdicts and for `--reset`, and `2` only on a
      usage error.
- [ ] The script is asserted to perform no repository-rooted `find` or `git ls-files`.
- [ ] The verdict is asserted to be the last stdout line, after the changed-component report.
- [ ] The suite never mutates this repository's `.aid/knowledge/`, and reads no path under
      `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-010 that this suite carries is covered**:
      **AC-12** in all three named cases, and FR-11's three-input staleness set.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
