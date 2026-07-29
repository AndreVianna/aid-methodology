# task-029: `grade-graph.sh` rubric orchestrator (`R*` rows)

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

**Depends on:** task-016

**Scope:**

- Create `canonical/aid/scripts/graph/grade-graph.sh`, the orchestrator the VALIDATE state runs:
  `grade-graph.sh .aid/knowledge/relationships.md [.aid/knowledge/graph.html]`.
- Implement feature-010 D4's **check -> severity mapping** by invoking the already-existing leaf
  validators and translating their output into `Pending` rows of the seven-column reviewer
  ledger at `.aid/.temp/review-pending/graph.md`. Row shape and phrasing follow the mapping table
  in `canonical/skills/aid-summarize/references/state-validate.md` ("Translate Script Output to
  Schema Rows"), so the two skills report comparable failures the same way.
- The data rows this delivery can actually run, all implemented by feature-003's
  `validate-relationships.sh` (task-016):
  - `R1` id resolvability -> `[HIGH]`, one row per unresolvable id.
  - `R2` inverse-pair consistency -> `[HIGH]`, one row per offending table row.
  - `R3` no duplicate relationship -> `[MEDIUM]`, one row per duplicate pair.
  - `R4` provenance population -> `[HIGH]`, one row per offending table row.
  - `R5` frontmatter validity via `canonical/aid/scripts/kb/lint-frontmatter.sh` -> `[HIGH]`, one
    row per `[FM-MISSING]` / `[FM-INVALID]` finding.
- The `V-*` rows (`V-H1`, `V-A`, `V-L`, `V-C`, `V-S2`, `V-NM`, `V-T`) belong to the same D4 table
  but have no artifact to run against in this delivery: **`graph.html` does not exist until
  delivery-004.** Wire the `V-*` branch so it is reached only when the optional `graph.html`
  argument is supplied, and so it **emits nothing** otherwise. Under `grade.sh` that needs no
  special mechanism -- absent rows are absent rows, and no maximum has to be recomputed.
- Compute the grade by calling `bash canonical/aid/scripts/grade.sh --explain
  .aid/.temp/review-pending/graph.md`. **No other grade computation exists in this skill**: D4
  assigns severities and `grade.sh` turns them into the letter. Do not implement a points pool,
  a maximum, a percentage, or a weight.
- Print Machine / Human / Overall. With `graph.html` out of scope the human pool is `N/A` and
  Overall = Machine (feature-010 D5).
- Exit codes: `0` Machine >= `A-`, `1` below, `2` usage -- the same contract `grade-summary.sh`
  documents.
- **This is a sibling orchestrator, not a fork** (AC-17 / C-4). It must contain **no copied check
  body**: every check is performed by invoking the existing leaf validator. `grade-summary.sh` is
  the one deliberate non-reuse (it hardcodes `KB_DIR` and a `manual-checklist.json` path, and its
  70-point pool is centred on `COV`, whose import would grade KB completeness -- forbidden by
  FR-28). Reuse happens one layer down, at the leaves.
- Resolve the minimum grade through `read-setting.sh`'s standard per-skill -> top-level ->
  `--default` chain for skill `graph`; never hand-parse `settings.yml`.
- Out of scope: the leaf validators themselves (feature-003 task-016 and, later,
  feature-007/008/009), any edit to `canonical/aid/scripts/summarize/*` (feature-011 owns every
  such edit), `references/state-validate.md`'s body (task-030), and the reuse verification
  (task-043).
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/grade-graph.sh` exists with the standard header,
      `set -euo pipefail`, and a working `-h|--help`.
- [ ] It accepts `relationships.md` as its first argument and `graph.html` as an optional second.
- [ ] `R1`-`R5` are each emitted at exactly the severity D4 assigns (`R3` `[MEDIUM]`; the other
      four `[HIGH]`) and at the row cardinality D4's "One row per" column states.
- [ ] Findings are written to `.aid/.temp/review-pending/graph.md` in the seven-column schema
      `.claude/aid/templates/reviewer-ledger-schema.md` fixes: `# | Severity | Status | Doc |
      Line | Description | Evidence`, Status `Pending`, no narrative or summary section.
- [ ] A passed check adds **no** row ("no row = no finding").
- [ ] With no `graph.html` argument, no `V-*` row is emitted and the script still produces a
      grade.
- [ ] The grade is obtained solely by invoking `canonical/aid/scripts/grade.sh --explain`; the
      script contains no points pool, maximum, percentage, or weight.
- [ ] Machine, Human, and Overall are printed; with `graph.html` out of scope Human is `N/A` and
      Overall equals Machine.
- [ ] Exit `0` when Machine >= `A-`, `1` below, `2` on usage error.
- [ ] `grep` shows no check body shared with `canonical/aid/scripts/summarize/grade-summary.sh`:
      every check is an invocation of an existing leaf validator, and `COV` appears nowhere.
- [ ] No file under `canonical/aid/scripts/summarize/` is modified by this task.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden**: the named suite is
      **task-043** (the shared-validator reuse and degradation verification).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md`; the delivery gate reaches this
      repository's resolved `minimum_grade` of **A+** (`review.minimum_grade` in
      `.aid/settings.yml`), i.e. zero ledger rows with Status `Pending` or `Recurred`.
      REQUIREMENTS.md section 6 holds only the six accessibility NFRs and is not a code baseline.
