# task-028: `kb-write-fence.sh` snapshot/verify fence

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** --

**Scope:**

- Create `canonical/aid/scripts/graph/kb-write-fence.sh` -- mechanism **E2** of feature-010, the
  pre/post digest fence that turns FR-10 / AC-13 from a promise into a check.
- Implement two modes:
  - `--snapshot` -- walk `.aid/knowledge/` and write `path + sha256` for every file **not**
    matching the D3 write allowlist to `.aid/.temp/graph/kb-fence.txt`. This is deliberately the
    same walk that produces the `KB` digest component (task-027), so the snapshot costs nothing
    extra.
  - `--verify` -- re-walk the same non-allowlisted set and diff against the snapshot. Any
    **added, removed, or changed** path is an FR-10 violation.
- Encode the D3 allowlist as the complement set the fence hashes. The five writable patterns are
  W1 `.aid/knowledge/relationships.md`, W2 `.aid/knowledge/graph.html`, W3
  `.aid/knowledge/graph-assets/**`, W4 `.aid/.temp/review-pending/graph.md` and
  `.aid/.temp/review-pending/graph-kb-gaps.md`, W5 `.aid/.temp/graph/**`. Only W1-W3 fall inside
  the `.aid/knowledge/` walk; W4 and W5 are outside it and need no exclusion rule.
- On a `--verify` violation: **exit 1 naming every offending path**, not just the first, so the
  closing summary can state that the artifacts must not be trusted.
- Exit codes: `0` clean, `1` violation, `2` usage -- feature-010's script table.
- Record in the header that `--verify` is designed to run on **every** exit path, including the
  idempotent `CURRENT` route and the failure routes; wiring it into those routes is the state
  bodies' job (task-030), not this script's.
- What the fence catches that an allowlist alone cannot, and should be stated in the header: an
  accidental `build-kb-index.sh` invocation regenerating `INDEX.md`, or a sub-agent editing a KB
  doc it was only asked to read.
- Deterministic output: `LC_ALL=C`-sorted snapshot lines, LF endings, no timestamp and no
  absolute path in the snapshot file, so a snapshot is comparable across runs and platforms.
- Out of scope: the staleness digest (task-027), the preflight (task-026),
  `references/state-*.md` bodies (task-030), and the fence suite (task-042).
- Standard script conventions: `#!/usr/bin/env bash`, `set -euo pipefail`, Purpose / Usage /
  Exit-codes header with `-h|--help`, the `while [[ $# -gt 0 ]]` argument loop with unknown
  flag -> stderr + exit 2.
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/kb-write-fence.sh` exists with the standard header,
      `set -euo pipefail`, and a working `-h|--help`.
- [ ] `--snapshot` writes `.aid/.temp/graph/kb-fence.txt` containing one `path + sha256` line per
      `.aid/knowledge/` file **not** matching the D3 allowlist, `LC_ALL=C`-sorted, LF-only, with
      no timestamp and no absolute path.
- [ ] `relationships.md`, `graph.html`, and anything under `graph-assets/` are absent from the
      snapshot, and every other `.aid/knowledge/` file is present.
- [ ] `--verify` exits `0` when the non-allowlisted set is byte-unchanged since the snapshot.
- [ ] `--verify` exits `1` when a non-allowlisted file is changed, when one is added, and when
      one is removed -- all three cases.
- [ ] A `--verify` failure prints **every** offending path, not only the first, each on its own
      line.
- [ ] Modifying `relationships.md` or `graph.html` between snapshot and verify does **not** make
      `--verify` fail.
- [ ] Exit `2` on a usage error (no mode given, unknown flag, both modes given).
- [ ] The script writes nothing under `.aid/knowledge/` in either mode.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden**: the named suite is
      **task-042** (`tests/canonical/test-graph-read-only.sh`).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md`; the delivery gate reaches this
      repository's resolved `minimum_grade` of **A+** (`review.minimum_grade` in
      `.aid/settings.yml`), i.e. zero ledger rows with Status `Pending` or `Recurred`.
      REQUIREMENTS.md section 6 holds only the six accessibility NFRs and is not a code baseline.
