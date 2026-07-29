# task-013: `graph.ignore` settings section in the settings template

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-006

**Scope:**

- Seed the `graph:` section, with its `ignore:` list, into
  `canonical/aid/templates/settings.yml` — **exactly as task-006's Q6 decision record specifies**,
  including whatever that decision determined about `format_version` (currently `3`). This task
  applies the decision; it does not make one. That split is deliberate: merging the decision and its
  application would violate the one-type rule and would hide the version question from review.
- Shape, per feature-004 D4 Class 3 and its Layers & Components row ("seed the `graph:` section with
  a commented-out `ignore:` list"):

  ```yaml
  graph:
    ignore:                          # repo-relative globs excluded from int: enumeration
      # - examples/**
  ```

  Seeded commented-out so a fresh install carries no ignore list and
  `read-setting.sh --path graph.ignore --default ''` resolves to empty.
- Carry two limitations in the template comment, so they are discovered by reading rather than by
  debugging: `lookup_list` returns items **comma-joined**, so an ignore pattern may not contain a
  comma; and patterns match as repo-relative globs with bash `case` semantics, the same matching
  style `build-project-index.sh` uses for `NOTABLE_PATH_PATTERNS`.
- Match the surrounding file's existing comment style and placement conventions — the template is
  read by humans configuring a project, and every other section is annotated.
- **Out of scope:** deciding the bump/reconcile question (task-006); `.aid/settings.yml`, this
  repository's live per-project settings, which `/aid-config` owns and which is not the shipped
  seed; `/aid-config` itself and `tests/canonical/test-reconcile-scenarios.sh`, which task-006
  reports as required-but-untasked follow-on **if** the decision was a bump; and `scan-source.sh`'s
  consumption of the setting (task-018 wires the read, through task-017's Class-3 predicate).

**Acceptance Criteria:**

- [ ] `canonical/aid/templates/settings.yml` declares a top-level `graph:` section with an `ignore:`
      key, seeded commented-out, annotated in the file's existing comment style.
- [ ] The `format_version` line matches task-006's recorded decision exactly — bumped or left at
      `3` — and the template carries a one-line pointer to the reconcile rule that decision named.
- [ ] `bash canonical/aid/scripts/config/read-setting.sh --path graph.ignore --default ''` returns
      empty against a settings file seeded from this template, and returns the comma-joined list once
      patterns are uncommented. An absent or empty section is **not** an error, so enumeration
      degrades to "no ignore list" rather than failing (delivery-002 BLUEPRINT's Q6 criterion).
- [ ] Configuration is idempotent (CONFIGURE default): re-applying the seed produces no second
      `graph:` section, no duplicated key, and no diff on a second application.
- [ ] No plaintext secret is introduced (CONFIGURE default) — the section holds repo-relative glob
      patterns and nothing else.
- [ ] The template comment states both limitations: no comma inside a pattern, and bash-`case` glob
      semantics on repo-relative paths.
- [ ] `git status` shows no modification to `.aid/settings.yml`, to any `/aid-config` file, or to
      `tests/canonical/test-reconcile-scenarios.sh`.
- [ ] All existing canonical suites still pass, including
      `bash tests/canonical/test-reconcile-scenarios.sh` **unmodified** — if that suite goes red, the
      decision recorded in task-006 was incomplete and the finding routes back there rather than
      being patched here.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      `run_generator.py` render for this delivery is task-044).
- [ ] The delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's
      resolved `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`;
      `.aid/knowledge/coding-standards.md` Configuration Access for the read path) — zero findings
      with Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only
      the six accessibility NFRs.
