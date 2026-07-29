# task-007: `/aid-graph` SKILL.md runtime sections and nine-state dispatch

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

- Create `canonical/skills/aid-graph/SKILL.md` and author the frontmatter feature-010 owns —
  `name`, `description`, `allowed-tools`, `argument-hint` — per the Skill contract in
  `.aid/knowledge/module-map.md`, with `canonical/skills/aid-summarize/SKILL.md` as the shape
  precedent.
- Author exactly six body sections and no others: `## Pre-flight Checks`, `## Arguments`,
  `## State Detection`, `## Dispatch`, `## Quality Gate`, `## Failure modes and recovery`.
- **`## References` is out of scope.** feature-012 owns that one section and it lands in task-008.
  This is the feature-010 ÷ feature-012 named-section seam (feature-010 "The ownership seam"; the
  `SKILL.md` serialisation is 007 -> 008 -> 051 -> 067), and it exists so no two tasks edit the same
  lines. Do not create a `## References` heading, even empty.
- **The shipped state machine is nine states, and that is intentional.** PREFLIGHT, ENUMERATE,
  STALE-CHECK, EXTRACT, EMIT, VALIDATE, VISUAL-GATE, FIX, DONE. **GAP-REPORT is absent** — task-051
  adds it in delivery-003 — and **RENDER is absent** — task-067 adds it in delivery-004. Nobody may
  "complete" the eleven-state map in feature-010's State Machines section early. With both absent,
  EMIT's Advance is `CHAIN -> VALIDATE` in this delivery, and tasks 051 and 067 splice their state in.
- `## Arguments` carries exactly feature-010 D1's three rows: *(none)*, `--reset`, `--grade X`.
  `--reset` discards the recomputed-digest comparison and does **not** delete artifacts. No
  `--table-only` argument is added.
- `## State Detection` and `## Dispatch` order STALE-CHECK **third**, after ENUMERATE — feature-010
  D2's consequence, since the `SRC` digest component is defined over the enumerated node set — and
  route `CURRENT` to DONE's idempotent variant.
- `## Quality Gate` names `canonical/aid/scripts/grade.sh`, unmodified, as the sole grading
  algorithm; resolves the floor with
  `bash canonical/aid/scripts/config/read-setting.sh --skill graph --key minimum_grade --default A`
  (which resolves to `A+` here); states D5's shape — one machine pool plus the single mandatory
  human check `G1`, Overall = `min(Machine, Human)`, human pool `N/A` when `graph.html` is out of
  scope; and records that the `V-*` rows emit nothing while no view artifact exists.
- `## Pre-flight Checks` summarises P1–P6 and points at `references/state-preflight.md`; the check
  bodies and the script are tasks 026 and 030.
- `## Failure modes and recovery` carries the documented bounded one-extra-run `INDEX.md`
  consequence (D2) and the fence-violation failure (E2: the run fails with exit 1 naming every
  offending path and the closing summary says the artifacts must not be trusted).
- Declare the D3 write allowlist W1–W5 in the file — mechanism E1, whose whole point is that an
  undeclared write target cannot reach implementation unnoticed.
- **Out of scope:** `canonical/skills/aid-graph/README.md` (task-009); every `references/state-*.md`
  body (tasks 030, 031, and later deliveries); the four `graph/` scripts (tasks 026–029); the site
  roster (task-010); the count surfaces (tasks 011, 012). Only `SKILL.md` is created here.

**Acceptance Criteria:**

- [ ] `canonical/skills/aid-graph/SKILL.md` exists and carries valid skill frontmatter — `name`,
      `description`, `allowed-tools`, `argument-hint` — per `.aid/knowledge/module-map.md`'s Skill
      contract, with `allowed-tools` holding no tool the skill does not need (E3).
- [ ] The file contains exactly the six named sections above and **no `## References` section**;
      task-008 is the only task that may add one.
- [ ] The `## Dispatch` table and the state map list exactly nine states — PREFLIGHT, ENUMERATE,
      STALE-CHECK, EXTRACT, EMIT, VALIDATE, VISUAL-GATE, FIX, DONE — with no GAP-REPORT row and no
      RENDER row, and the file records in prose that task-051 adds GAP-REPORT and task-067 adds
      RENDER so the omission reads as deliberate rather than as an oversight.
- [ ] EMIT's Advance is `CHAIN -> VALIDATE` in this delivery's map.
- [ ] STALE-CHECK is the third state, after ENUMERATE, and its `CURRENT` verdict routes to DONE's
      idempotent variant; the file states why the order differs from `/aid-summarize`'s (feature-010
      D2 / State Machines difference 4).
- [ ] Every Advance is CHAIN or HALT — no `PAUSE-FOR-USER-ACTION` and no `PAUSE-FOR-USER-DECISION` —
      per `.claude/aid/templates/state-machine-chaining.md`; `G1` is asked inline via
      `AskUserQuestion`, which is why VISUAL-GATE chains rather than pausing.
- [ ] `## Arguments` carries exactly the three D1 rows; `--reset` is specified as discarding the
      digest comparison rather than deleting artifacts, so a previous `graph-kb-gaps.md` survives;
      `--grade X` is validated against `[A-F][+-]?`; no `--table-only` appears anywhere in the file.
- [ ] `## Quality Gate` names `grade.sh` as the only grading algorithm, resolves the floor through
      `read-setting.sh --skill graph --key minimum_grade --default A`, describes D5's one-machine-pool
      -plus-`G1` shape, and records that the `V-*` rows emit no rows while no view artifact exists.
- [ ] The D3 write allowlist W1–W5 is declared verbatim in the file (E1), and no path outside it
      appears as a write target anywhere in the skill's prose.
- [ ] `## Failure modes and recovery` names both the bounded one-extra-run `INDEX.md` regeneration
      and the fence-violation exit-1 path.
- [ ] Only `canonical/skills/aid-graph/SKILL.md` is created. No file under `profiles/`, `.cursor/`,
      `.codex/`, `.agent/` or `.claude/` is hand-edited — the FULL `run_generator.py` render for this
      delivery is task-044.
- [ ] All existing canonical suites still pass (`bash tests/run-all.sh` over
      `tests/canonical/test-*.sh`). IMPLEMENT's default "unit tests for all new public
      methods/endpoints" is **overridden** here: `.aid/knowledge/test-landscape.md` records
      prompt-driven skill state machines as "not machine-tested (by design)", and the testable
      surface — the scripts the states call — is covered by tasks 040, 041 and 042.
- [ ] The authoring baseline holds (`.aid/knowledge/authoring-conventions.md` "Prose Over Scripts";
      `.aid/knowledge/coding-standards.md` for anything the prose quotes), and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the
      six accessibility NFRs.
