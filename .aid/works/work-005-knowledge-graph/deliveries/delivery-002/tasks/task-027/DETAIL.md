# task-027: `graph-stale-check.sh` composite input digest and verdicts

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

**Depends on:** task-019

**Scope:**

- Create `canonical/aid/scripts/graph/graph-stale-check.sh`, the script the STALE-CHECK state
  runs after ENUMERATE.
- Implement feature-010 D2's **composite input digest**: a SHA-256 over three sorted component
  lists joined in fixed order, so the digest is byte-stable across runs and platforms.
  - `KB` -- `path + sha256` for every `.aid/knowledge/*.md` at depth 1, **excluding the paths on
    the D3 write allowlist**, sorted by path. `INDEX.md` is deliberately **included**; the
    recorded consequence (one extra regeneration after the KB owner regenerates the index) is
    accepted and must be reflected in the script's header rather than engineered away.
  - `SRC` -- `path + sha256` for every artifact in feature-004's enumerated node set
    (`.aid/.temp/graph/nodes.tsv`), sorted by path. This is a hash pass over an
    already-produced list, **never a second repository traversal** -- a second walk under
    `canonical/aid/scripts/graph/` would fail feature-004's seam guard
    (`tests/canonical/test-graph-single-scanner.sh`).
  - `EXT` -- `sha256` of `.aid/knowledge/external-sources.md`.
  - No fourth `TOOL` component: the vocabulary and the `graph/` script area already live inside
    `SRC` wherever they qualify, and adding one would double-count them and exceed FR-11's
    declared input set.
- Implement the three verdicts of feature-010's STALE-CHECK table, printed as the **last stdout
  line**:
  - `FIRST_RUN` -- `relationships.md` absent, or present with no `graph_inputs_digest`.
  - `STALE` -- recomputed digest != the stored digest, **or** `graph.html` is expected for this
    build and its embedded `<!-- aid-graph inputs-digest: <hex> -->` differs from
    `relationships.md`'s.
  - `CURRENT` -- both artifacts present and both digests equal the recomputed digest.
- There is **no `CURRENT_UNAPPROVED` verdict**. `/aid-summarize`'s third verdict has no
  counterpart here, because currency is content-addressed rather than approval-addressed
  (feature-010 State Machines, difference 2).
- Implement `--reset`, which bypasses the comparison and forces `STALE`.
- Implement the **changed-component report**: print which of `KB` / `SRC` / `EXT` changed, so the
  user is told *why* regeneration is happening rather than shown a bare verdict. This is the
  mechanism behind AC-12's source-only case -- `SRC` changes while `KB` does not and the
  composite digest still changes.
- **Always exit 0** for every verdict; the decision is informational, never a failure, following
  `stale-check.sh`'s documented header contract. `2` for a usage error only.
- The script **reads** digests; it never writes `relationships.md`. The two frontmatter scalars
  `graph_inputs_digest` and `graph_generated_at` are written by the EMIT path
  (`build-relationships.sh`, task-023) from the value this script computes.
- Out of scope: the write fence (task-028), the preflight (task-026), the rubric orchestrator
  (task-029), `references/state-stale-check.md`'s body (task-030), and the staleness suite
  (task-041).
- Standard script conventions: `#!/usr/bin/env bash`, `set -euo pipefail`, Purpose / Usage /
  Exit-codes header with `-h|--help`, the `while [[ $# -gt 0 ]]` argument loop, `LC_ALL=C` on
  every sort, and settings read only through `read-setting.sh`.
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/graph-stale-check.sh` exists with the standard header,
      `set -euo pipefail`, and a working `-h|--help`.
- [ ] The digest is a SHA-256 over the three components `KB`, `SRC`, `EXT` joined in that fixed
      order, each component's list `LC_ALL=C`-sorted by path, so recomputing it twice on an
      unchanged tree yields the identical hex string.
- [ ] `KB` covers exactly the depth-1 `.aid/knowledge/*.md` set minus the D3 allowlist paths, and
      includes `INDEX.md`; the header records the accepted one-extra-run consequence.
- [ ] `SRC` is computed from the paths listed in `.aid/.temp/graph/nodes.tsv` and performs no
      `find` or `git ls-files` rooted at the repository root.
- [ ] `EXT` is the SHA-256 of `.aid/knowledge/external-sources.md`.
- [ ] The last stdout line is exactly one of `FIRST_RUN`, `STALE`, `CURRENT`; no
      `CURRENT_UNAPPROVED` value exists anywhere in the script.
- [ ] `FIRST_RUN` is produced both when `relationships.md` is absent and when it is present
      without a `graph_inputs_digest`.
- [ ] `STALE` is produced when the recomputed digest differs from the stored one, and also when
      `graph.html` is expected and its embedded digest differs from `relationships.md`'s.
- [ ] `--reset` forces `STALE` without comparing digests.
- [ ] The changed-component report names which of `KB` / `SRC` / `EXT` changed.
- [ ] Exit status is `0` for all three verdicts and for `--reset`; `2` only for a usage error.
- [ ] The script writes no file under `.aid/knowledge/`.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden**: the named suite is
      **task-041** (`tests/canonical/test-graph-stale-check.sh`).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md`; the delivery gate reaches this
      repository's resolved `minimum_grade` of **A+** (`review.minimum_grade` in
      `.aid/settings.yml`), i.e. zero ledger rows with Status `Pending` or `Recurred`.
      REQUIREMENTS.md section 6 holds only the six accessibility NFRs and is not a code baseline.
