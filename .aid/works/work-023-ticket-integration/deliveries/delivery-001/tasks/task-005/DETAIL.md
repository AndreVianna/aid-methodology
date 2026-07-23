# task-005: Structural/parse test suite for the ticket skills

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

**Type:** TEST

**Source:** work-023-ticket-integration -> delivery-001

**Depends on:** task-002, task-003, task-004

**Scope:**
- Author `tests/canonical/test-ticket-skills-*.sh` -- structural / parse-level tests (host MCP + a live tracker are unavailable in CI, so no live-call tests) covering feature-001 §Testing. Glob-discovered by `tests/run-all.sh`; MUST NOT depend on any `.aid/works/work-023*` path (work-folder-transience rule).
- Skill anatomy: each of the three `SKILL.md` (aid-read-ticket, aid-create-ticket, aid-update-ticket) carries the required frontmatter (incl. `AskUserQuestion` in `allowed-tools`; `argument-hint` = its grammar line) and the Feature-Flow states; each points to the shared `ticket-resolution.md` (task-001).
- Grammar parse cases: read `id` and `stem:id`; update `part` enum accept/reject; create `--connector` (no leading-token heuristic -- a description beginning with a stem-matching word stays wholly the description), `--level` accept (`epic`/`story`/`task`, case-insensitive) / reject (bare non-tier -> usage line) / quoted-literal passthrough (`--level "Sub-task"`), `--parent <ref>`, and flags-in-any-order with the whole non-flag remainder taken verbatim as the description.
- Resolution-ladder branch coverage: 0 / 1 / 2+ `issue-tracker` connectors; explicit-override wins; `api`-type fall-through; the `"no issue-tracker connector found."` notify string.
- Create level & parent behavior: no `--level` -> the pick is carried on the confirm gate (never a silent default); a description-inferred level is surfaced for confirmation; tier -> tracker-type resolution via the ordered synonym set + the quoted-literal passthrough; graceful degradation to a plain issue + optional `type:<tier>` label; `--parent` sets the native link when supported and falls back to a preview note (create still succeeds) when not.
- Confirm gate present in create/update, absent in read.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-ticket-skills-*.sh` exists, is glob-discovered by `tests/run-all.sh`, and does NOT reference any `.aid/works/work-023*` path (work-folder-transience rule).
- [ ] Tests cover AC-1..AC-6 structurally: skill anatomy / frontmatter / states + the shared-ref pointer; the full grammar parse matrix; the resolution-ladder branches (0/1/2+, override, `api` fall-through, notify string); create level/parent behavior; confirm present in create/update and absent in read (feature-001 §Testing).
- [ ] Tests are deterministic with clean setup/teardown and cover all acceptance criteria from feature-001; no live MCP / tracker call is made.
- [ ] Tests pass locally (HOME-pinned).
- [ ] Byte/path-parity of the rendered copies is delivery-003's gate, not asserted here.
- [ ] All section-6 quality gates pass.
