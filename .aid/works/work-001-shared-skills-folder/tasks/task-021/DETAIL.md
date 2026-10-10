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

**Depends on:** task-015

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
- AC-14 case (c), as worded (the § 11 test plan places (a) and (b) in `test-shared-install.sh`,
  task-017, and (d) in `test-multitool-isolation.sh`, task-018): three format-4 claude-code
  fixtures -- a user-edited `CLAUDE.md` with user content above and below the full AID region (the
  result equals the pre-update content with the marked region replaced by the import region, and the
  pre-update file is at `.aid/.trash/CLAUDE.md`); an unedited `CLAUDE.md` (same replacement, file
  still exists); a no-marker `CLAUDE.md` holding AID sections (the (b) prefix check passes and the
  WARN line naming `CLAUDE.md` is printed). In each, exactly one `@AGENTS.md` line in `CLAUDE.md`
  and one `<!-- AID:BEGIN -->` line in `AGENTS.md`.
- Format-4 fixtures are built by hand or with the frozen format-4 core of task-020 if it has
  landed; the suite never reads a work folder. Removed or renamed keys get coverage rows.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-migrate.sh --verbose` exits `0`, with `PASS:` lines for each AC-13 clause per tool fixture (five plus the legacy `.agents/aid/` case) and the second-run checks.
- [ ] The same run prints `PASS:` lines for AC-14 (c) in its three variants (user-edited with trash copy, unedited and still present, no-marker with WARN) and the one-`@AGENTS.md` / one-`AID:BEGIN` invariant in each.
- [ ] `grep -cE 'profiles/[a-z-]+/' tests/canonical/test-aid-migrate.sh` prints `0`.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.
