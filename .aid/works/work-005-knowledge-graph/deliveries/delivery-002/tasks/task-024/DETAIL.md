# task-024: `build-relationships.sh` bounded pass-2 residue and class-1 merge

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

**Depends on:** task-023

**Scope:**

- Add feature-005's Feature Flow **steps 8–10** to the existing
  `canonical/aid/scripts/graph/build-relationships.sh`, **without disturbing task-023's steps 7, 11
  and 12** — the `build-relationships.sh` serialisation is 023 -> 024.
- **Step 8 — compute the residue, and nothing more.** Pass 2's entire input is two closed sets:
  `.aid/.temp/graph/candidates.tsv` (the edges the rules could not settle), and the concept-level
  `kb:` residue — heading-level `kb:` ids carrying **zero** class-0 edge. Both are *computed* from
  step 7's frozen output rather than judged, so the residue is itself reproducible.
- **Step 9/10 — the four bounds, enforced by the merge and not by the prompt.** A prompt-only bound
  is not a bound; agent output is untrusted input to this script.
  - **Closed node set.** Both endpoints must already exist in `nodes.tsv` or `kb-nodes.tsv`. Pass 2
    cannot mint a node. This is the downstream half of feature-004's `no-inferred-node` invariant
    (its D3): enumeration never admits a node on inferred evidence, and this bound stops the only
    later stage that could reintroduce one, so FR-24 holds end to end.
  - **No revisiting.** A row whose `rel_row_key` is already in step 7's key set is rejected — the
    mechanical form of "the second pass does not revisit a relationship the first pass settled".
  - **Class 1 only.** Every pass-2 row is stamped `provenance = inferred`, `class = 1`; a row
    arriving with any other provenance is rejected.
  - **Typed from the vocabulary.** `s2t` must be a vocabulary member and `t2s` is looked up as its
    inverse, exactly as in pass 1. Two further checks apply here: the chosen relation's `passes` must
    include `inferred`, and its `endpoint_kinds` must list the row's
    `<source-prefix>-><target-prefix>` pair. A relation the vocabulary reserves for the deterministic
    passes, or one used across an endpoint pair it does not admit, is rejected. Free text goes in
    `observation`.
- Then normalise, key, de-duplicate against **both** the class-0 key set and other class-1 rows, and
  sort with `LC_ALL=C`. Rejected rows are reported to stderr with a reason and dropped; **a rejection
  is never fatal**, because FR-25's reporting-not-gating posture applies to the run as a whole.
- **Graceful degradation.** If the pass cannot run — no host agent available, dispatch failure, or an
  empty residue — the run completes and the artifact ships with class-0 rows only. The deterministic
  majority is the product; the reading pass is an enrichment. This mirrors the precedent
  `test-landscape.md` records for the Playwright visual gate, which exits 0 with a `SKIP`.
- **Out of scope:** steps 7, 11 and 12 (task-023 — do not modify); the `aid-researcher` dispatch
  prompt and its prose form of the four bounds (task-025 —
  `canonical/skills/aid-graph/references/agent-pass.md`; the enforcement stays here in the script);
  the byte-identity suite (task-038); the bound suite (task-039).

**Acceptance Criteria:**

- [ ] The residue is computed, not judged: `candidates.tsv` plus the heading-level `kb:` ids carrying
      zero class-0 edge, both derived from step 7's frozen output, so the same repository yields the
      same residue on every run.
- [ ] Each of the four bounds is enforced **in the merge, in code** — not in prose — and each rejects
      a crafted violating row: a new node id, a key colliding with the class-0 set, a non-`inferred`
      provenance, and, for the typing bound, a non-vocabulary label, a relation whose `passes`
      excludes `inferred`, and a relation whose `endpoint_kinds` excludes the row's prefix pair.
- [ ] A rejection prints its reason to stderr and drops the row; no rejection aborts the run or
      changes the exit code.
- [ ] Class-1 de-duplication runs against both the class-0 key set and other class-1 rows, on a
      total tie-break, and the class-1 block is `LC_ALL=C`-sorted.
- [ ] Pass 2 has **no write path into class 0**: adding, removing, or rewording a class-1 row leaves
      the class-0 block byte-identical, which is the property
      `tests/canonical/test-relationships-reproducible.sh` (task-038) asserts as a suite.
- [ ] Every emitted class-1 row satisfies feature-003's `V4 [REL-PAIR]` by construction, because
      `t2s` is looked up rather than accepted from the agent.
- [ ] An empty residue, an unavailable host agent, or a dispatch failure completes the run with
      class-0 rows only, prints a clear stderr note, and still writes the artifact.
- [ ] Agent output is treated as untrusted input throughout: nothing the agent supplies reaches the
      table without passing all four bounds.
- [ ] `git diff` shows task-023's steps 7, 11 and 12 unchanged.
- [ ] The only files written remain `.aid/knowledge/relationships.md` and paths under
      `.aid/.temp/graph/` (allowlist W1 and W5).
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into separate TEST tasks; the named suites land in **task-039**
      (`test-agent-pass-bounds.sh`, one crafted violating row per bound) and **task-038**
      (the class-0 stability half).
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
