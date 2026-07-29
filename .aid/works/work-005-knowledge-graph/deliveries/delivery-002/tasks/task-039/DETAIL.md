# task-039: `test-agent-pass-bounds.sh` pass-2 bound suite

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

**Depends on:** task-024

**Scope:**

- Create `tests/canonical/test-agent-pass-bounds.sh`: "each of the four bounds rejects a crafted
  violating row (new node id, colliding key, non-`inferred` provenance, and -- for the typing
  bound -- a non-vocabulary label, a relation whose `passes` excludes `inferred`, and a relation
  whose `endpoint_kinds` excludes the row's prefix pair)" (feature-005 Layers table).
- The suite tests the **merge**, not the prompt. Feature-005 step 9 states plainly that "a
  prompt-only bound is not a bound": every rejection below is performed by
  `build-relationships.sh`'s class-1 merge (task-024). The suite therefore feeds crafted
  `rows-class1.tsv` content directly and asserts the merge's behaviour -- it never dispatches an
  agent, which is also what keeps it deterministic.
- **Bound 1 -- closed node set.** A crafted row whose source endpoint, and separately whose
  target endpoint, is an id present in neither `nodes.tsv` nor `kb-nodes.tsv` is **rejected**.
  This is the downstream half of feature-004's `no-inferred-node` invariant: pass 2 cannot mint a
  node. Assert the positive control too -- a row whose both endpoints exist is accepted.
- **Bound 2 -- no revisiting.** A crafted row whose `rel_row_key` is already in the frozen
  class-0 key set is **rejected**. Assert both the verbatim-repeat form and the
  inverse-orientation form, since D7 normalises orientation before keying and both collapse to
  the same key.
- **Bound 3 -- class 1 only.** A crafted row stamped `declared`, one stamped `derived`, and one
  with an empty provenance are each **rejected**; only `provenance = inferred` / `class = 1` is
  accepted.
- **Bound 4 -- typed from the vocabulary**, all three rejection shapes:
  - a `s2t` label that is **not a vocabulary member**;
  - a relation whose **`passes` excludes `inferred`** -- a relation the vocabulary reserves for
    the deterministic passes;
  - a relation whose **`endpoint_kinds` excludes the row's `<source-prefix>-><target-prefix>`
    pair**.
  Assert also that `t2s` is **looked up as the mapped relation's `inverse` and never taken from
  the crafted row** -- a row supplying a wrong `t2s` is corrected by lookup, not accepted as
  written.
- **De-duplication within class 1.** Two crafted class-1 rows sharing a `rel_row_key` collapse to
  one; the survivor is chosen by the same total rule, so it does not depend on arrival order.
- **Rejections are reported, never fatal.** Each rejected row is reported to **stderr with a
  reason**, the run continues, and the exit status is not raised by a rejection alone --
  FR-25's reporting-not-gating posture applies to the run as a whole. Assert the reason text
  names the bound that fired.
- **The class-0 block is untouched by every rejection and every acceptance.** Assert byte
  identity of the class-0 block before and after the class-1 merge in each case, closing the loop
  with task-038.
- **Free text belongs in `observation`.** Assert an accepted class-1 row may carry free prose in
  `Observation` (§5.4), while a class-0 row may not (feature-003 V11) -- the two halves of the
  same rule.
- Fixtures -- a fixture `nodes.tsv`, `kb-nodes.tsv`, `rows-class0.tsv`, a crafted
  `rows-class1.tsv`, a fixture vocabulary and a fixture edge-relation map -- are built under
  `mktemp -d` and depend on no work folder's contents (A-6). No agent is dispatched and no
  network call is made.
- Out of scope: the dispatch prose `references/agent-pass.md` itself (**task-025**) -- this suite
  deliberately does not test prose, because enforcement does not live there; the reproducibility
  suite (**task-038**); and `build-relationships.sh` itself (tasks 023, 024).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-agent-pass-bounds.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] The suite exercises `build-relationships.sh`'s class-1 merge against a crafted
      `rows-class1.tsv`; it dispatches no agent and makes no network call.
- [ ] Bound 1 is asserted for an unknown **source** endpoint and, separately, an unknown
      **target** endpoint, with a positive control where both endpoints exist.
- [ ] Bound 2 is asserted for both a verbatim key collision and an inverse-orientation collision
      with the frozen class-0 key set.
- [ ] Bound 3 is asserted for `declared`, `derived`, and an empty provenance, all rejected.
- [ ] Bound 4 is asserted in all three shapes: non-vocabulary label, `passes` excluding
      `inferred`, and `endpoint_kinds` excluding the row's prefix pair.
- [ ] A crafted row supplying a wrong `t2s` is asserted to be corrected by `inverse` lookup
      rather than accepted as written.
- [ ] Two class-1 rows sharing a `rel_row_key` are asserted to collapse to one, with the same
      survivor under two different input orders.
- [ ] Every rejection is asserted to print a stderr reason naming the bound that fired, and to
      leave the run non-fatal -- the exit status is not raised by a rejection alone.
- [ ] The class-0 block is asserted byte-identical before and after the class-1 merge in every
      case.
- [ ] Free prose in `Observation` is asserted accepted on a class-1 row and rejected on a
      class-0 row.
- [ ] The suite uses a fixture vocabulary and a fixture edge-relation map, never feature-001's
      real `relation-vocabulary.yml`.
- [ ] No fixture reads any path under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no agent invocation,
      no ordering dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-005 that this suite carries is covered**: the
      four bounds of Feature Flow step 9, the merge-enforced half of FR-31, the `no-inferred-node`
      downstream guarantee FR-24 rests on, and AC-5's one-way-merge mechanism.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
