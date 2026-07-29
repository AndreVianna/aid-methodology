# task-077: `test-validate-html-profiles.sh` VP01-VP06

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-076

**Scope:**
- **Conditional (feature-011 contingency C1).** This suite is authored **only if** task-076 fired
  -- that is, only if delivery-001's FR-18 decision selected external delivery and task-075
  recorded the `S2` failure that triggers it.
- When it fires: author `tests/canonical/test-validate-html-profiles.sh` carrying `VP01`-`VP06`
  exactly as feature-011 § L3 defines them, including the two golden-output proofs (D4 proofs 3
  and 4) that the default path is byte-unchanged and the `graph` profile differs by exactly one
  line.
- **Out of scope:** the validator edit itself (task-076); `test-validate-visuals-profiles.sh`
  (`VV01`-`VV04`, contingency C2, task-085 in delivery-005); modifying
  `tests/canonical/test-guardrails-d012.sh`, which must keep passing **unmodified** as the
  standing pin.

**Acceptance Criteria:**
- [ ] **If task-076 was a recorded no-op -- the C1 trigger did not hold -- this task is a recorded
      no-op**: no suite is authored, and the gate records why, citing task-075's determination and
      task-076's no-op record.
- [ ] `VP01`: with no `--profile`, the validator selects `kb-summary` and enforces `S2` plus
      `NM.1`, `NM.2` and `NM.3`.
- [ ] `VP02`: `--profile graph` reports **only** `S2` as `[N/A]`, with its printed reason.
- [ ] `VP03`: `--profile graph` still **fails** each of three fixtures -- an inline > 100 KB
      `mermaid` bundle (`NM.1`), a `mermaid.initialize(` call (`NM.2`), and a CDN Mermaid
      `<script src>` (`NM.3`) -- proving D-012 binds both artifacts.
- [ ] `VP04`: an unknown `--profile` value exits **2**.
- [ ] `VP05` (D4 proof 3): the no-`--profile` stdout over a fixed fixture is **byte-identical** to
      the committed baseline.
- [ ] `VP06` (D4 proof 4): the `--profile graph` stdout differs from the default run by **exactly
      one line**, so the carve-out cannot widen beyond its single named check without the suite
      going red.
- [ ] `bash tests/canonical/test-guardrails-d012.sh` passes unmodified alongside this suite.
- [ ] **Tests are deterministic** (TEST default): the fixtures are fixed, the golden baseline is
      committed, and repeated runs produce identical stdout.
- [ ] **Clean setup/teardown** (TEST default): each fixture is built under `mktemp -d` and removed
      on exit; the suite depends on no work folder (**A-6**), sources `tests/lib/assert.sh`, and
      uses the `ID + description` label convention of `test-guardrails-d012.sh`.
- [ ] The suite is discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob with no
      runner edit, and `bash tests/canonical/test-validate-html-profiles.sh` exits 0.
- [ ] Source-feature coverage: feature-011's C1 mechanism and D4 proofs 2-4 are each covered by a
      labelled assertion, so no amended validator ships without its guard.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
