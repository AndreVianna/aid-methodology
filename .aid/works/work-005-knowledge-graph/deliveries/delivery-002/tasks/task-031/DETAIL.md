# task-031: ENUMERATE / EXTRACT / EMIT state reference bodies

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

**Depends on:** task-007, task-019, task-023, task-024

**Scope:**

- Author the three **pipeline** state reference bodies under
  `canonical/skills/aid-graph/references/`: `state-enumerate.md`, `state-extract.md`,
  `state-emit.md`.
- These bodies are owned by the pipeline features -- ENUMERATE by feature-004, EXTRACT by
  feature-005, EMIT by feature-003 -- while feature-010 owns each file's `**Advance:**` line and
  its Dispatch-table row. This task writes the **bodies against feature-010's Advance lines**.
  The Dispatch-table rows themselves live in `SKILL.md` (task-007).
- Like task-030's six, these are agent-executed skill behaviour rather than documentation, so the
  task is IMPLEMENT with prose as its medium (`authoring-conventions.md` "Prose Over Scripts").
- Advance lines, every one **CHAIN** per `.claude/aid/templates/state-machine-chaining.md`:
  - `state-enumerate.md` -- **CHAIN -> STALE-CHECK**.
  - `state-extract.md` -- **CHAIN -> EMIT**.
  - `state-emit.md` -- **CHAIN -> VALIDATE**. **This is the one Advance line that differs from
    feature-010's eleven-state table**, which reads `CHAIN -> GAP-REPORT`. GAP-REPORT is
    introduced by feature-006 in delivery-003 (tasks 050/051) and does not exist in the
    nine-state machine delivery-002 ships, so pointing at it here would name a state the skill
    cannot enter. Write `CHAIN -> VALIDATE` and record, in the body, that task-051 re-points this
    line to GAP-REPORT when that state lands -- so the change is a scheduled edit rather than a
    later surprise.
- Body content, per state:
  - **ENUMERATE** (feature-004) -- runs first, before STALE-CHECK, because the `SRC` digest
    component is defined over the enumerated node set and a newly added artifact is invisible to
    any stored path list. Invoke `scan-source.sh` (tasks 018/019). State that the state is
    **write-free** with respect to the repository: its only outputs are the three streams
    `.aid/.temp/graph/nodes.tsv`, `observations.tsv`, `candidates.tsv`. Carry the `no-inferred-node`
    invariant as the guarantee downstream states rely on: every `nodes.tsv` row's
    `evidence_provenance` is `declared` or `derived`, and `candidates.tsv` carries no promotion
    path to a node. Name the exit contract (`0` scan, `1` write failure, `2` usage or a non-git
    checkout) and the one-line `[scan] N nodes, M observations, K candidates` stderr summary.
  - **EXTRACT** (feature-005) -- sequences the two passes as one state. Pass 1a
    `harvest-declared.sh` (task-021) builds the `kb:` node set and the six declared carriers;
    pass 1b `derive-edges.sh` (task-022) types feature-004's observations through the
    edge-relation map. Then `build-relationships.sh` merges and **freezes class 0** (task-023),
    computes the residue, and dispatches the bounded pass 2 (task-024) using
    `references/agent-pass.md` (task-025). State the reproducibility boundary explicitly: it sits
    **after pass 1b and before the class-0 merge**, and pass 2 has no write path into class 0
    because the merge rejects any class-1 row colliding with a class-0 key and any row not
    stamped `inferred`. State the graceful-degradation rule: no host agent, a dispatch failure,
    or an empty residue means the run completes with class-0 rows only.
  - **EMIT** (feature-003) -- writes `.aid/knowledge/relationships.md` (allowlist W1): D8's
    frontmatter as the first bytes of the file, the `AUTO-GENERATED` marker **with no timestamp**,
    the `# Relationships` title, then the eight-column table with the class-0 rows as a contiguous
    prefix and class-1 rows as a contiguous suffix. State that feature-010 supplies the
    `graph_inputs_digest` and `graph_generated_at` values and that they sit **outside** the
    byte-identity boundary by design. State the self-validation step: invoke
    `validate-relationships.sh` on the file just written; a non-zero exit is reported and surfaces
    as ledger findings, and the artifact is still written so the failure is visible rather than
    hidden behind a missing file.
- Out of scope: the six feature-010-owned state bodies (**task-030**), `state-gap-report.md`
  (task-050) and `state-render.md` (task-066) -- neither exists in delivery-002 -- every
  `SKILL.md` section including the Dispatch-table rows (tasks 007 and 008), the pass-2 dispatch
  prose (task-025), and all of the scripts these states invoke (tasks 018, 019, 021, 022, 023,
  024).
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] All three files exist under `canonical/skills/aid-graph/references/`:
      `state-enumerate.md`, `state-extract.md`, `state-emit.md`.
- [ ] Each carries exactly one `**Advance:**` line: enumerate **CHAIN -> STALE-CHECK**, extract
      **CHAIN -> EMIT**, emit **CHAIN -> VALIDATE**.
- [ ] No body contains `PAUSE-FOR-USER-ACTION` or `PAUSE-FOR-USER-DECISION`.
- [ ] `state-emit.md` records, in prose, that its Advance line targets VALIDATE because
      delivery-002 ships a nine-state machine, and that task-051 re-points it to GAP-REPORT when
      feature-006's state lands.
- [ ] `state-enumerate.md` names `scan-source.sh`, lists the three `.aid/.temp/graph/` output
      streams, states the state is write-free with respect to the repository, carries the
      `no-inferred-node` invariant, and states the `0`/`1`/`2` exit contract.
- [ ] `state-extract.md` names `harvest-declared.sh`, `derive-edges.sh`, and
      `build-relationships.sh` in that order, locates the reproducibility boundary after pass 1b
      and before the class-0 merge, states that pass 2 has no write path into class 0, and
      carries the graceful-degradation rule.
- [ ] `state-emit.md` names `.aid/knowledge/relationships.md` as its single write target (W1),
      requires the frontmatter to be the first bytes of the file, requires no timestamp in the
      `AUTO-GENERATED` marker or the table, states the class-0-prefix / class-1-suffix layout,
      attributes `graph_inputs_digest` / `graph_generated_at` to feature-010 and places them
      outside the byte-identity boundary, and requires the `validate-relationships.sh`
      self-validation with the artifact still written on a non-zero exit.
- [ ] No body instructs a write to any `.aid/knowledge/` path outside the D3 allowlist.
- [ ] No rendered copy is hand-authored under `profiles/`, `.claude/`, `.cursor/`, `.codex/`,
      `.agent/` or `.github/aid/`.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden.** Prose state bodies
      expose no method, and `test-landscape.md` records prompt-driven skill state machines as not
      machine-tested by design. The testable surface is the scripts these states call, whose
      suites are **task-032** and **task-033** (enumeration), **task-036**, **task-037**,
      **task-038** and **task-039** (extraction), and **task-035** (emission validation).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md` and
      `.aid/knowledge/authoring-conventions.md`; the delivery gate reaches this repository's
      resolved `minimum_grade` of **A+** (`review.minimum_grade` in `.aid/settings.yml`), i.e.
      zero ledger rows with Status `Pending` or `Recurred`. REQUIREMENTS.md section 6 holds only
      the six accessibility NFRs and is not a code baseline.
