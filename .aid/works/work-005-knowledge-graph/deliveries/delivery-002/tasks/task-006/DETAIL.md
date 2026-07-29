# task-006: `graph:` settings section version and reconcile decision (Q6)

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

**Type:** RESEARCH

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** --

**Scope:**

- Answer Q6, the question delivery-002's BLUEPRINT requires decided **before** feature-004's
  implementation task: does adding a top-level `graph:` section to the settings file require a
  `format_version` bump from the live `format_version: 3`, and what reconcile rule applies to
  installs that predate the section?
- Compare at least two options and price each: **(a)** no bump — an additive, optional section that
  an existing install simply lacks; **(b)** bump `format_version: 3 -> 4` with a named reconcile
  rule that `/aid-config` applies on an older install.
- Read and cite, by path: `.aid/settings.yml` (live — `format_version: 3`, verified),
  `canonical/aid/templates/settings.yml` (the shipped seed),
  `canonical/aid/scripts/config/read-setting.sh` (its `lookup_list` dotted-path resolution, its
  skill-mode fall-through, and `--default` semantics), the `/aid-config` reconcile states, and
  `tests/canonical/test-reconcile-scenarios.sh` (the suite that already covers the reconcile
  ground).
- Produce a written decision record naming exactly one answer plus the reconcile rule, in a form
  task-013 can seed from without re-deciding anything. It lands as `FINDINGS.md` in this task's own
  folder (`.aid/works/work-005-knowledge-graph/deliveries/delivery-002/tasks/task-006/FINDINGS.md`)
  and is reported to the orchestrator for the Q6 entry in the work `STATE.md`; this task does not
  edit the work `STATE.md`, `REQUIREMENTS.md`, or any `BLUEPRINT.md`.
- **Surface the gap rather than closing it silently.** If the recommendation is a bump, the
  follow-on `/aid-config` reconcile change and a matching `tests/canonical/test-reconcile-scenarios.sh`
  case are genuinely required and are **not tasked** anywhere in this breakdown. Report them for the
  owner; do not pre-create tasks for them.
- **Out of scope:** seeding the section itself — that is task-013 (CONFIGURE), deliberately split
  from this task so the decision is reviewable separately from its application, as the one-type rule
  requires. Also out of scope: any edit to `.aid/settings.yml`,
  `canonical/aid/templates/settings.yml`, `/aid-config`, or
  `tests/canonical/test-reconcile-scenarios.sh`.

**Acceptance Criteria:**

- [ ] At least two alternatives are compared — additive-no-bump versus `format_version` bump with a
      reconcile rule — each with its stated consequence for an install that predates the section, its
      cost in `/aid-config` work, and its cost in reconcile-suite coverage.
- [ ] Every claim is sourced: each cited file is named by repository-relative path, and each quoted
      behaviour (the live `format_version: 3`, `read-setting.sh`'s list resolution and `--default`
      handling, the reconcile suite's existing coverage) is verified on the branch rather than
      recalled.
- [ ] The record ends in one actionable recommendation — exactly one answer to the bump question —
      stated concretely enough that task-013 can apply it without making a further decision.
- [ ] The recommendation names the reconcile rule explicitly and says what `/aid-config` must do for
      a pre-existing install that has no `graph:` section.
- [ ] Whichever option is recommended, the record confirms that `graph.ignore` resolves through
      `bash canonical/aid/scripts/config/read-setting.sh --path graph.ignore --default ''` and that
      an absent section is therefore not an error — enumeration degrades to "no ignore list" rather
      than failing (feature-004 D4 Class 3; delivery-002 BLUEPRINT's Q6 criterion).
- [ ] If — and only if — the recommendation is a bump, the record states in its own section that the
      follow-on `/aid-config` reconcile work and a `tests/canonical/test-reconcile-scenarios.sh` case
      are required, are **not covered by any task in this breakdown**, and are raised for the owner
      to schedule.
- [ ] The record is written to this task's folder and nothing else is written: `git status` shows no
      modification to `.aid/settings.yml`, `canonical/aid/templates/settings.yml`, `/aid-config`,
      `tests/canonical/test-reconcile-scenarios.sh`, the work `STATE.md`, or any `BLUEPRINT.md`.
- [ ] The delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's
      resolved `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`; the work's
      `minimum_grade: "A+"`) — zero findings with Status `Pending` or `Recurred`. REQUIREMENTS.md §6
      is not a code baseline; it holds only the six accessibility NFRs.
