# task-007: Canonical test suites covering AC1–AC11

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

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** task-005, task-006

**Scope:**
- Author canonical test suites (`tests/canonical/`) covering AC1–AC11. Each test traces to a
  specific AC; tests are deterministic (no timing dependencies, no external-state leaks) and clean
  up their fixtures:
  - **set/unset behavior** — `aid-set-connector` create (AC1), api upsert + fresh-repo gitignore
    precondition (AC2), in-place type-transition secret reconcile (AC3), field-only no-reprompt vs
    `--rotate-secret`/`auth_method`-change reprompt (AC4); `aid-unset-connector` remove + a second
    idempotent no-op (AC5).
  - **no-collateral single-stem** (AC6) — with ≥2 connectors catalogued, operating on one stem
    leaves every other connector's descriptor + secret intact (assert both persist unchanged).
  - **fresh-repo gitignore precondition ordering** (AC2/AC10) — `connector-secret write` is never
    invoked before the `.secrets/` gitignore precondition holds; **write-zone confinement** — the
    skills write only within `.aid/connectors/` (AC10).
  - **ELICIT regression** (AC7) — the shared `reconcile.md` bulk-mode reuse produces the same
    ADD/UPDATE/NO-OP/REMOVE + INDEX outcomes as the pre-extraction inline ELICIT reconcile.
  - **profile `## Connectors` presence** in all 5 context files **plus the four-`AGENTS.md`
    byte-identity invariant** (`tests/canonical/test-agents-md-invariant.sh`, AC8).
  - **linkage/consumption smoke check** (AC9) — a `ticket_ref` resolves to the correct ticket by
    nearest-ancestor containment and the wired seam acts via the host MCP; the host MCP is
    stubbed/mocked (no live external call).
  - **standing gates** (AC11) — `/generate-profile` deterministic render + dogfood byte-identity +
    connector-twin PS-parity + PS 5.1.

**Acceptance Criteria:**
- [ ] Test coverage exists for `aid-set-connector` create/upsert/type-transition/no-reprompt and
  `aid-unset-connector` remove/idempotent, each tracing to its AC and passing (traces to AC1–AC5).
- [ ] A no-collateral single-stem test asserts other connectors' descriptor + secret are untouched
  (AC6); a fresh-repo test asserts the gitignore precondition precedes any secret write and writes
  stay within `.aid/connectors/` (traces to AC6, AC2, AC10).
- [ ] An ELICIT-regression test confirms bulk-mode reconcile via `reconcile.md` is behaviorally
  unchanged (AC7); a `## Connectors`-presence + `test-agents-md-invariant.sh` byte-identity test
  passes (traces to AC7, AC8).
- [ ] A linkage/consumption smoke check asserts `ticket_ref` nearest-ancestor resolution + host-MCP
  action without a live external call (AC9); the standing render/parity/PS 5.1 gates pass (traces
  to AC9, AC11).
- [ ] All section-6 quality gates pass.
