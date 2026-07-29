# task-008: SKILL.md `## References` shared-script and template list

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

**Depends on:** task-007

**Scope:**

- Add **exactly one** section — `## References` — to `canonical/skills/aid-graph/SKILL.md`. This is
  feature-012's only `SKILL.md` section, per the 010/012 named-section seam (feature-010 "The
  ownership seam"; feature-012 L2). The `SKILL.md` serialisation is 007 -> 008 -> 051 -> 067.
- The section lists the shared scripts and templates the skill calls, so a reader can see the skill's
  whole borrowed surface in one place:
  - this work's own script area — `canonical/aid/scripts/graph/graph-preflight.sh`,
    `graph-stale-check.sh`, `kb-write-fence.sh`, `grade-graph.sh`, `scan-source.sh`,
    `significance-rules.sh`, `harvest-declared.sh`, `derive-edges.sh`, `build-relationships.sh`,
    `validate-relationships.sh`, `relationship-schema.sh`;
  - the project-shared scripts — `canonical/aid/scripts/grade.sh`,
    `canonical/aid/scripts/config/read-setting.sh`,
    `canonical/aid/scripts/kb/lint-frontmatter.sh`;
  - the reused `/aid-summarize` toolchain, invoked unmodified by default —
    `canonical/aid/scripts/summarize/assemble.sh`, `validate-html-output.sh`, `contrast-check.mjs`,
    `validate-visuals.mjs`;
  - the template set — `canonical/aid/templates/graph/relationship-schema.yml`,
    `relation-vocabulary.yml`, `edge-relation-map.yml`;
  - the governing shared templates — `canonical/aid/templates/reviewer-ledger-schema.md`,
    `canonical/aid/templates/kb-authoring/frontmatter-schema.md`,
    `canonical/aid/templates/state-machine-chaining.md`.
- **Out of scope: every other part of `SKILL.md`.** Do not touch the frontmatter,
  `## Pre-flight Checks`, `## Arguments`, `## State Detection`, `## Dispatch`, `## Quality Gate`, or
  `## Failure modes and recovery` — feature-010 owns all of them and task-007 wrote them.
- **Out of scope, and flagged rather than silently pre-added:** delivery-003's
  `canonical/aid/scripts/graph/detect-kb-gaps.mjs` and delivery-004's
  `canonical/aid/scripts/graph/coverage-predicate.mjs` and
  `canonical/aid/templates/knowledge-graph/*`. They do not exist in this delivery and no task in this
  breakdown adds them to `## References` later — tasks 051 and 067 edit the dispatch row and state-map
  node only. Report this as a gap for the owner rather than listing paths this delivery does not
  produce.

**Acceptance Criteria:**

- [ ] `canonical/skills/aid-graph/SKILL.md` gains exactly one new section, `## References`, and
      `git diff` shows no change to any other line of the file — the named-section seam holds
      literally, not just in intent.
- [ ] Every path listed either exists on disk today or is a named output of a delivery-002 task
      (013–029); no listed path is speculative.
- [ ] No listed path is rooted in a rendered tree — nothing under `profiles/`, `.claude/`,
      `.cursor/`, `.codex/` or `.agent/`. Every reference is to `canonical/`, which is the single
      source of truth (`.aid/knowledge/module-map.md` Invariants).
- [ ] The four reused `canonical/aid/scripts/summarize/*` entries are described as *invoked
      unmodified by default*, with the two feature-011 contingencies (`--profile graph` for S2, the
      `validate-visuals.mjs` T2 exclusion) named as contingent and owned elsewhere — so the section
      cannot be read as licence to fork or edit them (AC-17).
- [ ] The section adds no new behaviour, no new argument, and no new state; it is a reference list.
- [ ] The delivery-003 / delivery-004 shared modules are absent from the list, and the omission plus
      the missing follow-on task are reported to the owner at review rather than fixed here.
- [ ] Only `canonical/skills/aid-graph/SKILL.md` is modified; nothing under `profiles/` or `.claude/`
      is hand-edited (the FULL render is task-044).
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden**: this task adds prose to a skill file, which
      `.aid/knowledge/test-landscape.md` records as not machine-tested by design; the shipped result
      across all five trees is asserted by `tests/canonical/test-graph-skill-registration.sh` in
      task-091.
- [ ] The authoring baseline holds (`.aid/knowledge/authoring-conventions.md`), and the delivery
      gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
