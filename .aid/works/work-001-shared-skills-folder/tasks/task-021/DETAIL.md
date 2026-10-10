# task-021: Migration suite for every format-4 layout and the `CLAUDE.md` import region

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-13, AC-14

**Depends on:** task-012, task-015

**Scope:**
- `tests/canonical/test-aid-migrate.sh`: build bundles with `tests/lib/bundle.sh`; re-key the
  existing format-migration cases whose expectations change (settings stamp 5, manifest format 3).
- AC-13, exactly as worded in REQUIREMENTS.md § 9: one format-4 fixture per tool (Antigravity
  `.agent/skills`, and a Codex fixture with the legacy `.agents/aid/`), each holding one
  user-modified AID file in the old `skills/aid-*` and one in the old `aid/` subtree, plus one
  non-AID user file in each old directory. After `aid update --from-bundle <staging>`: the AC-3 and
  AC-7 checks; no `aid-*` under `.codex/skills`, `.cursor/skills`, `.github/skills`,
  `.agent/skills`; no `<root>/aid/`; modified files byte-for-byte at `.aid/.trash/<original-path>`;
  non-AID files unchanged; `.aid/settings.yml` `format_version` = 5. A second `aid update` prints
  `up to date` for every tool and leaves `.aid/.trash/` unchanged.
- AC-14, every clause as worded: (a) created when missing (and not created for `cursor`); (b)
  appended to a no-marker user file, stable across a following `aid update`; (c) migrated from the
  full region (user-edited with content above and below; unedited; no-marker with AID sections +
  WARN), with the trash copy; (d) removed on `aid remove claude-code` after
  `aid add claude-code,cursor`, with `shared.agents_md.users` = `["cursor"]` and no
  `shared.claude_md`; and in every fixture while Claude Code is installed, exactly one `@AGENTS.md`
  line in `CLAUDE.md` and one `<!-- AID:BEGIN -->` line in `AGENTS.md`.
- Format-4 fixtures are built by hand or with the frozen format-4 core of task-020 if it has
  landed; the suite never reads a work folder. Removed or renamed keys get coverage rows.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-migrate.sh --verbose` exits `0`, with `PASS:` lines for each AC-13 clause per tool fixture (five plus the legacy `.agents/aid/` case) and the second-run checks.
- [ ] The same run prints `PASS:` lines for AC-14 (a), (b), (c) in its three variants, (d) for both fixtures, and the one-`@AGENTS.md` / one-`AID:BEGIN` invariant.
- [ ] `grep -cE 'profiles/[a-z-]+/' tests/canonical/test-aid-migrate.sh` prints `0`.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.
