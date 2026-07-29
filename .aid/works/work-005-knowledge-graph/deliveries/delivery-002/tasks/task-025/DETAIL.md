# task-025: `references/agent-pass.md` pass-2 dispatch prose

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

**Depends on:** task-007, task-024

**Scope:**

- Author `canonical/skills/aid-graph/references/agent-pass.md` -- the single file
  feature-005 contributes into `canonical/skills/aid-graph/`. The directory itself is
  created by the skill-wiring task (task-007); this task adds one reference file into it.
- **This is IMPLEMENT, not DOCUMENT, and the distinction is load-bearing.** The file is
  agent-executed skill behaviour, not documentation about behaviour: it is the pass-2
  dispatch prompt the EXTRACT state issues, so a wrong line changes what the skill does.
  It is authored as skill prose per `.aid/knowledge/authoring-conventions.md` "Prose Over
  Scripts", which is the project's chosen implementation medium for an agent step -- not a
  reason to type the task DOCUMENT.
- Write the dispatch prompt for feature-005 Feature Flow step 9: the role
  (`aid-researcher` -- the agent whose remit is reading code and docs to produce
  structured analysis; `aid-architect` designs and `aid-developer` writes production code,
  so neither fits a read-and-classify task), the whole input context (the two closed
  residue sets of step 8 -- `.aid/.temp/graph/candidates.tsv` and the computed
  heading-level `kb:` residue, i.e. heading-level `kb:` ids carrying zero class-0 edge --
  plus the relation vocabulary), and the sole output target
  (`.aid/.temp/graph/rows-class1.tsv`, in feature-005 D1's nine-field TSV order). Nothing
  else is writable by the pass.
- State the four hard bounds as prose the dispatched agent must observe:
  1. **Closed node set** -- both endpoints must already exist in `nodes.tsv` or
     `kb-nodes.tsv`; pass 2 cannot mint a node (the downstream half of feature-004's
     `no-inferred-node` invariant).
  2. **No revisiting** -- a row whose `rel_row_key` is already in step 7's class-0 key set
     is out of bounds.
  3. **Class 1 only** -- every pass-2 row is `provenance = inferred`, `class = 1`.
  4. **Typed from the vocabulary** -- `s2t` must be a vocabulary member, `t2s` is looked up
     as its inverse and never chosen; the relation's `passes` must include `inferred` and
     its `endpoint_kinds` must list the row's `<source-prefix>-><target-prefix>` pair. Free
     text goes in `observation`.
- Carry feature-005's External Integrations clauses: **graceful degradation** (no host
  agent, dispatch failure, or an empty residue -> the run completes and the artifact ships
  with class-0 rows only; the deterministic majority is the product and the reading pass is
  an enrichment) and **heartbeat / cooperative stop** (`HEARTBEAT_FILE` /
  `HEARTBEAT_INTERVAL`, with `heartbeat_interval` resolved from `.aid/settings.yml` where it
  is a top-level scalar).
- Record the trust boundary: the agent's output is **untrusted input** to
  `build-relationships.sh`.
- **Explicitly out of scope: enforcement.** The four bounds are enforced by
  `build-relationships.sh`'s class-1 merge (task-024), never by this prompt --
  feature-005 step 9 states plainly that "a prompt-only bound is not a bound". This file
  must not restate a bound as if the prompt were the check, and no enforcement logic may
  be moved out of the script and into this prose. Make the division explicit in the file
  itself so a later editor cannot relocate it by accident.
- Also out of scope: every `SKILL.md` section (tasks 007 and 008), every
  `references/state-*.md` body including the EXTRACT body that dispatches this pass
  (task-031), and the bound suite (task-039).
- Authored in `canonical/` only. No copy is hand-written under `profiles/`, `.claude/`,
  `.cursor/`, `.codex/`, `.agent/` or `.github/aid/` (C-2; `module-map.md` Invariants).

**Acceptance Criteria:**

- [ ] `canonical/skills/aid-graph/references/agent-pass.md` exists; no rendered copy is
      hand-authored anywhere under `profiles/`, `.claude/`, `.cursor/`, `.codex/`,
      `.agent/` or `.github/aid/`.
- [ ] The file names `aid-researcher` as the dispatched role and states feature-005's
      stated reason for choosing it over `aid-architect` and `aid-developer`.
- [ ] The input contract names exactly `.aid/.temp/graph/candidates.tsv`, the computed
      heading-level `kb:` residue, and the relation vocabulary -- and nothing else.
- [ ] The output contract names exactly `.aid/.temp/graph/rows-class1.tsv` and states
      feature-005 D1's field order; the file states that nothing else is writable by the
      pass.
- [ ] All four bounds of feature-005 Feature Flow step 9 appear, each phrased in the same
      terms the merge enforces, including the `passes`-includes-`inferred` and
      `endpoint_kinds`-lists-the-prefix-pair halves of bound 4.
- [ ] The file states that `t2s` is looked up as the mapped relation's `inverse` and never
      supplied by the agent.
- [ ] The file states explicitly that enforcement lives in `build-relationships.sh`
      (task-024) and that the prompt is not the check; it contains no instruction that
      implies the prompt gates anything, and no bound is worded as a self-check the agent
      performs in place of the merge.
- [ ] The graceful-degradation clause and the heartbeat / cooperative-stop clause of
      feature-005 External Integrations are both present, with `heartbeat_interval` named
      as a top-level `.aid/settings.yml` scalar.
- [ ] The trust-boundary sentence is present: the pass's output is untrusted input to
      `build-relationships.sh`, which drops violations.
- [ ] The file is prose per `authoring-conventions.md` "Prose Over Scripts" -- no
      executable shell block is embedded.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden here.** A prose
      reference file exposes no method, and the one-type-per-task rule puts suites in their
      own tasks. The named suite that exercises the bounds this prose describes is
      **task-039** (`tests/canonical/test-agent-pass-bounds.sh`).
- [ ] Build passes: this task introduces no canonical construct the renderer cannot emit;
      the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md` and
      `.aid/knowledge/authoring-conventions.md`; the delivery gate reaches this
      repository's resolved `minimum_grade` of **A+** (`review.minimum_grade` in
      `.aid/settings.yml`), i.e. zero ledger rows with Status `Pending` or `Recurred`.
      REQUIREMENTS.md section 6 holds only the six accessibility NFRs and is not a code
      baseline.
