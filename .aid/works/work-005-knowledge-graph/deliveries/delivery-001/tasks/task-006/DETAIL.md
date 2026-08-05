# task-006: Seed the commented-out graph.ignore settings section

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-006/STATE.md.
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

**Type:** CONFIGURE

**Source:** feature-004-source-enumeration -> delivery-001 (Wave 1)

**Depends on:** task-005

**Scope:**
- Add the `graph` section to `canonical/aid/templates/settings.yml`, **seeded commented out**,
  exactly as feature-004's SPEC specifies at `:1609` — `graph:` / `ignore:` with the inline comment
  "repo-relative globs excluded from node enumeration" and the single seed pattern `examples/**`.
- **Commented out is the load-bearing detail, not a stylistic choice.** `read-setting.sh`'s
  `lookup_list` prints only when `items != ""`, so `undeclared` and `declared-empty` are
  byte-identical on stdout. Shipping the block commented out keeps a fresh install honestly in the
  `undeclared` state rather than silently asserting an empty ignore list.
- **This also dissolves the `format_version` question**: a commented-out block is semantically
  inert, so there is no version bump and no reconcile rule. `/aid-config` and
  `tests/canonical/test-reconcile-scenarios.sh` are untouched by design.
- The reader half already exists (`scan-source.sh:152` / `:171`,
  `significance-rules.sh:722`) and is not edited here.
- **The render is NOT this task's, and that is now a decision rather than an executor choice.** An
  earlier version offered "either render it here or leave it to task-024", while also forbidding the
  state one of those branches produces -- so an acceptance-criteria-driven executor could end gate
  wave 1 in exactly the condition the same bullet prohibited, and no criterion covered either branch.
  **This task edits `canonical/` only.** `task-024` owns every render, and it depends on this task.
  The transient divergence between `canonical/` and the five profile roots is therefore expected and
  bounded, not a defect, for the interval between wave 1 and wave 5.

**Acceptance Criteria:**
- [ ] The section is present in `canonical/aid/templates/settings.yml`, commented out, matching
      feature-004 SPEC `:1609` including the inline comment text and the seed pattern
- [ ] `format_version` is UNCHANGED and no reconcile rule is added — recorded as a deliberate
      consequence of inertness, not left to inference
- [ ] A fresh install resolves the ignore list to the `undeclared` state, not `declared-empty`, and
      the `scan-source.sh:171` notice still fires
- [ ] SPEC-pinned constraint 1 carried into the section's comment: patterns are **repo-relative
      globs matched with bash `case` semantics**
- [ ] SPEC-pinned constraint 2, which is a correctness trap and not a style note: **an ignore
      pattern may NOT contain a comma.** The resolver returns items comma-joined, so `a,b` is
      indistinguishable downstream from two patterns. `--probe` emits its per-item stderr warning
      and the durable note reads
      `declared, <n> patterns (<m> item(s) contained a comma and were split)`
- [ ] Uncommenting the block yields a working ignore list with no other edit required
- [ ] `test-reconcile-scenarios.sh` and the settings-template suites still pass unchanged
- [ ] **The render is deliberately absent here**: `profiles/` and both dogfood trees are untouched by
      this task, and the byte-identity gate is expected to be red for the settings template until
      `task-024` renders it. Asserting a green render gate here would be asserting work this task does
      not own
- [ ] **Configuration is idempotent** and **no plaintext secret is introduced** (CONFIGURE
      type-defaults, `task-decomposition.md`:178). Idempotence is the load-bearing one here: applying
      the seeded section twice, or applying it to a tree that already carries it, must leave one
      commented block and not two -- and re-running `/aid-config` over an install that predates the
      section must not duplicate or uncomment it
- [ ] All section-6 quality gates pass
