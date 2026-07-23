# task-014: Byte/path-parity + CLI-parity + KB-lint terminal gate

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

**Source:** work-023-ticket-integration -> delivery-003

**Depends on:** task-012, task-013

**Scope:**
- Run the terminal gate suites (feature-005 §Testing), HOME-pinned locally (`HOME="$(mktemp -d)" bash tests/run-all.sh` for the glob-discovered suites; the heavy gates run master-only / on release tags). Uses EXISTING `tests/canonical/` suites -- no new test files:
  - **Render-drift (load-bearing):** `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` -- a fresh render must equal the committed `profiles/*` (AC-12 / NFR-4).
  - **Byte/path-parity:** `tests/canonical/test-dogfood-byte-identity.sh` green -- the repo-root dogfood `.claude/` is byte-identical to `profiles/claude-code/.claude/` for every generator-owned path (three-direction guard: forward, reverse, orphan-sweep).
  - **CLI-parity:** `tests/canonical/test-aid-cli-parity.sh` green -- this change does not touch the CLI, so it must simply stay green (a regression flags an unexpected side effect).
  - **AC-13 KB checks:** per-site (`document-expectations.md` `### infrastructure.md` no longer contains `entity mapping`, and still contains `tool or "none"` + `access method`); `.aid/knowledge/infrastructure.md § Project Management Tooling` documents the connectors + dedicated-skills model; `tests/canonical/test-kb-citation-lint.sh` + `tests/canonical/test-frontmatter-lint.sh` pass; grep the KB edit for any `CLAUDE.md` / `AGENTS.md` citation -> zero; `INDEX.md` freshness holds (regenerate via `build-kb-index.sh` only if the summary shifted).
  - **NFR-3:** a project with no `issue-tracker` connector and no `ticket_ref` is unaffected by the guidance/KB text.
- Confirm the three new `aid-*-ticket` skills and every features-001-004 edit are present in each of the 5 profiles and the dogfood tree.

**Acceptance Criteria:**
- [ ] Render-drift green: a fresh `run_generator.py` leaves `git diff --exit-code -- profiles/` clean (AC-12 / NFR-4).
- [ ] `test-dogfood-byte-identity.sh` green (dogfood `.claude/` byte-identical to `profiles/claude-code/.claude/`) and `test-aid-cli-parity.sh` green (AC-12 / NFR-4).
- [ ] AC-13 checks pass: the `document-expectations.md` per-site check; the KB `## Project Management Tooling` model + citation discipline; `test-kb-citation-lint.sh` + `test-frontmatter-lint.sh` green; zero `CLAUDE.md`/`AGENTS.md` citations in the KB edit; `INDEX.md` fresh.
- [ ] NFR-3 confirmed: a no-`issue-tracker`-connector / no-`ticket_ref` project is unaffected by the guidance/KB text.
- [ ] Checks are deterministic, run HOME-pinned, cover feature-005's ACs (AC-12 / AC-13), use existing `tests/canonical/` suites, and do not depend on any `.aid/works/work-023*` path.
- [ ] All section-6 quality gates pass.
