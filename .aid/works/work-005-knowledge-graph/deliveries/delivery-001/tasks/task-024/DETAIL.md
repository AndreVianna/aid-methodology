# task-024: Re-render all five profiles plus dogfood, and reconcile every count and roster

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-024/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** feature-012-canonical-registration -> delivery-001 (Wave 5)

**Depends on:** task-006, task-008, task-015, task-021, task-023

**Scope:**
- **Registration itself already landed** in commit `55453fd3`: `aid-graph` is in all five
  `profiles/*/skills/aid-graph/`, both dogfood trees, all five `emission-manifest.jsonl` files, and
  `generated-files.txt`; `generate-profile/SKILL.md` was updated. Canonical-versus-render sha256
  spot-checks agree for the graph scripts and the `knowledge-graph` templates. So this is **the
  final re-render made necessary by tasks 006, 008, 013, 015, 017, 019, 021 and 023**, not initial
  registration.
- **The count and roster reconciliation is DISCHARGED, and this task must verify-and-preserve rather
  than move it.** The corpus stands at 76 skill directories and `aid-graph` **is** among them (it is
  the 76th; pre-registration was 75). All eleven `${SKILLS}`-compared documentation phrases already
  state the current figure, and the five hand-maintained `profiles/<tool>/README.md` files already
  name `/aid-graph`. This task confirms that, and does not bump anything.
- D3's byte-identity per render class and per root; D4's count and roster surfaces; D5's
  generated-file registry.

**Acceptance Criteria:**
- [ ] Byte-identical re-render across all five profile roots and both dogfood trees; every emission
      manifest updated
- [ ] **No corpus numeral is written into this task's verification as an expectation** — every count
      assertion compares a **derived** artifact against the source of truth, never against a sibling
      literal. That is tech-debt L4's own invariant-anchoring remedy, and the `io_bounds.py` incident
      is why: five install manifests plus two installer test lists all asserted each other and
      "passed" while every one of them was missing a shipped, security-relevant file
- [ ] The eleven documentation phrases are verified **unchanged and correct**; any edit to one is
      raised as a finding, because the reconciliation is already discharged and a change means
      something else moved
- [ ] The five hand-maintained `profiles/<tool>/README.md` files are verified to still name
      `/aid-graph` — they sit inside generated trees but match zero `emission-manifest.jsonl`
      records, so they survive the render and are hand-edited
- [ ] `gen-reference.mjs`'s `[gen-reference] skills drift` throw and `gen-reference.test.mjs`'s
      `CURATED_SKILL_NAMES` length assertion are both green — the two surfaces that fail hard and so
      cannot be silently missed
- [ ] The dogfood `.claude/` tree is resynced from `profiles/claude-code/` so the byte-identity gate
      passes
- [ ] `test-doc-counts.sh` and `check-skill-counts.mjs` pass; `render VERIFY` reports a byte-identical
      re-render
- [ ] All section-6 quality gates pass
