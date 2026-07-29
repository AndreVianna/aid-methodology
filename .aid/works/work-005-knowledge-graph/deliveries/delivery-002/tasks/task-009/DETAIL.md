# task-009: `canonical/skills/aid-graph/README.md` maintainer documentation

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

**Type:** DOCUMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-007

**Scope:**

- Author `canonical/skills/aid-graph/README.md` as **canonical-only contributor documentation**,
  following `canonical/skills/aid-summarize/README.md` as the shape precedent.
- Content: what `/aid-graph` is and where it sits in the lifecycle (a sibling of `/aid-summarize`,
  on-demand, never triggered by discovery); the script area it owns
  (`canonical/aid/scripts/graph/`); the template set it reads
  (`canonical/aid/templates/graph/`); the current shape of the state machine and which deliveries
  extend it; the D3 write allowlist W1–W5 and why the pre/post fence exists; and how to run the
  suites a contributor will need (`bash tests/canonical/test-graph-*.sh`, and the HOME-pinned full
  run that is a master-only gate).
- **Record, with its verification, that this file never ships.** `README` matches zero records in
  all five `profiles/<tool>/emission-manifest.jsonl`, and `render.py`'s `translate == "skills"`
  branch emits `SKILL.md` plus `references/*.md` and — when present — a verbatim copy of `scripts/`,
  and nothing else. `canonical/skills/aid-summarize/README.md` is the live proof: it exists and
  appears in no install tree. The file is therefore written for contributors reading `canonical/`,
  and it is explicitly **not** one of the surfaces that satisfies the discoverability requirement —
  those belong to feature-013 (task-090, delivery-006).
- Record that the delivery-002 state machine is deliberately **nine** states, and name task-051
  (GAP-REPORT, delivery-003) and task-067 (RENDER, delivery-004) as the additions, so a contributor
  reading this file mid-work does not read the omission as a defect.
- **Out of scope:** `SKILL.md` in any section (tasks 007 and 008); the five hand-maintained
  `profiles/<tool>/README.md` count edits (task-012); the discoverability surfaces and the
  Knowledge Base entries (tasks 090, 094, 095).

**Acceptance Criteria:**

- [ ] `canonical/skills/aid-graph/README.md` exists and follows the structure of
      `canonical/skills/aid-summarize/README.md`.
- [ ] Accuracy is verified against the current branch (DOCUMENT default): every path, script name,
      state name, template name and suite name the document cites either exists on disk or is a
      named output of a task in this work, and each was checked rather than recalled.
- [ ] The document states plainly that it is canonical-only maintainer documentation that ships to
      no profile tree, and carries the verification behind that claim — zero `README` records across
      all five `emission-manifest.jsonl` files, and `render.py`'s `skills` branch emitting only
      `SKILL.md`, `references/*.md` and an optional verbatim `scripts/`.
- [ ] The document states that it is **not** a discoverability surface and points at feature-013 /
      task-090 for the surfaces that are.
- [ ] The document states that the shipped delivery-002 machine is nine states and names task-051 and
      task-067 as the two later additions.
- [ ] The document reproduces the D3 write allowlist W1–W5 and does not introduce a sixth entry.
- [ ] The task records the expectation it hands to task-044: the FULL `run_generator.py` render adds
      no emission-manifest record for this file, so `git diff --exit-code -- profiles/` stays clean
      because of it; `tests/canonical/test-graph-skill-registration.sh` (task-091) is the suite that
      asserts the shipped result across all five trees.
- [ ] Only `canonical/skills/aid-graph/README.md` is created; no file under `profiles/` or `.claude/`
      is hand-edited.
- [ ] The authoring baseline holds (`.aid/knowledge/authoring-conventions.md`), and the delivery
      gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
