# task-040: `test-graph-preflight.sh` refusal suite

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

**Depends on:** task-026

**Scope:**

- Create `tests/canonical/test-graph-preflight.sh`, the suite feature-010's L3 table names for
  **AC-11**: "each of P1-P6 refuses with an actionable message".
- **One refusal fixture per check**, each asserting exit `1`, a cause line, and an actionable
  `->` line naming the remediation feature-010's PREFLIGHT table specifies:
  - `P1` -- `.aid/knowledge/STATE.md` absent; the message directs the user to run `/aid-config`
    then `/aid-discover`.
  - `P2` -- the KB is not approved; the message directs the user to run `/aid-discover` to
    APPROVAL.
  - `P3` -- no populated KB document; the message directs the user to run `/aid-discover` to
    populate the KB.
  - `P4` -- `CLAUDE_PLAN_MODE=1`; the message says to exit Plan Mode and re-run.
  - `P5` -- a reported Node major version below 20; the message says to install or upgrade
    Node.js.
  - `P6` -- `.aid/knowledge/external-sources.md` absent; the message names `/aid-discover`'s
    ELICIT state as its author.
- **The P2 scoping fixture, called out explicitly by feature-010's L3 table.** A fixture whose KB
  is **unapproved** but whose `## Knowledge Summary Status` section records
  `**User Approved:** yes` must **still be refused**. This is the check `summarize-preflight.sh`
  gets wrong -- it matches `^(> *)?\*\*User Approved:\*\* yes` against the whole file, and in this
  repository `.aid/knowledge/STATE.md` carries that literal twice. Assert both halves of the fix:
  - the frontmatter scalar `kb_status: Approved` is read **first** and passes on its own;
  - when `kb_status` is absent, the blockquoted `> **User Approved:** yes` fallback is matched
    **only above the first `##` heading**, so a summary-section approval does not satisfy it.
- **P3's predicate is asserted precisely**: a depth-1 `.aid/knowledge/*.md` other than
  `STATE.md` / `README.md` / `INDEX.md`, with **more than 30 non-blank lines** and **no
  `^❌ Pending` marker**. Assert the boundary (exactly 30 non-blank lines fails, 31 passes), the
  three excluded filenames, and a 40-line doc carrying a `^❌ Pending` marker failing.
- **The pass case and the exit contract.** A fixture satisfying all six checks exits `0` and
  prints no refusal. An unknown flag exits `2`. Assert the three-value contract `0` pass, `1`
  prerequisite failed, `2` usage.
- **Refusal is actionable, not merely non-zero.** For each of the six, assert the presence of the
  `->` remediation line, following `summarize-preflight.sh`'s `err()` shape.
- Each fixture builds its own KB under `mktemp -d` (A-6) and depends on no work folder's
  contents. `.aid/knowledge/` of this repository is never mutated by the suite.
- Out of scope: the staleness suite (**task-041**), the fence suite (**task-042**), the reuse
  verification (**task-043**), `graph-preflight.sh` itself (task-026), and any change to
  `canonical/aid/scripts/summarize/summarize-preflight.sh` -- feature-010 records that defect as
  reported upstream and out of this work's scope.
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-graph-preflight.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] Each of `P1`-`P6` has a refusal fixture asserting exit `1`, a cause line, and an `->`
      remediation line naming the action feature-010's PREFLIGHT table specifies.
- [ ] The unapproved-KB-with-approved-summary fixture is asserted **refused**.
- [ ] `kb_status: Approved` in the leading YAML block is asserted to pass on its own, and the
      `> **User Approved:** yes` fallback is asserted to be honoured only above the first `##`
      heading.
- [ ] `P3`'s boundary is asserted: 30 non-blank lines fails, 31 passes; `STATE.md`, `README.md`
      and `INDEX.md` do not count; a `^❌ Pending` marker disqualifies an otherwise-populated doc.
- [ ] `P5` is asserted to fail below Node major 20 and pass at 20 and above.
- [ ] A fully satisfying fixture exits `0` with no refusal output; an unknown flag exits `2`.
- [ ] The suite never mutates this repository's `.aid/knowledge/`, and reads no path under
      `.aid/works/` (A-6).
- [ ] `canonical/aid/scripts/summarize/summarize-preflight.sh` is not modified.
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; the Node-version case is driven by a controlled stub or environment rather than
      the host's installed version; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-010 that this suite carries is covered**:
      **AC-11** in full (all six checks refuse actionably) and FR-8's approval gate including its
      scoping fix.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
