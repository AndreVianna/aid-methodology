# task-018: Rewrite the multi-tool isolation suite for reference counting and drift

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-9, AC-10, AC-14

**Depends on:** task-012, task-013, task-014

**Scope:**
- `tests/canonical/test-multitool-isolation.sh`: replace the per-root T-cases with the shared
  layout; build bundles with `tests/lib/bundle.sh` instead of from `profiles/<tool>/`.
- AC-9 sequence exactly as worded in REQUIREMENTS.md § 9: `aid add claude-code,cursor,codex`;
  `aid remove cursor` (shared sha256 unchanged, `.cursor/agents/aid-*` gone, no `users` list names
  `cursor`); `aid remove codex` (shared entries present); `aid remove claude-code` (no
  `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/`); non-AID
  `.agents/skills/my-skill/SKILL.md` and `.claude/skills/my-skill/SKILL.md` keep sha256 throughout.
- AC-10 sequence exactly as worded: after `aid add claude-code`, append a byte to
  `.claude/skills/aid-ask/SKILL.md`, delete `.claude/skills/aid-fix/SKILL.md`, append a byte to
  `.agents/skills/aid-plan/SKILL.md`; `aid status` names the three paths and `aid update`;
  `aid update --from-bundle <same staging>` restores canonical bytes; the two modified files exist
  byte-for-byte under `.aid/.trash/` at their original relative paths; a second `aid status` reports
  no drift.
- AC-14 case (d), as worded (the § 11 test plan places it here): in a fixture with no prior
  `CLAUDE.md` and in one whose user `CLAUDE.md` has no markers, run `aid add claude-code,cursor`
  then `aid remove claude-code`; `CLAUDE.md` is then absent in the first and equal to its pre-add
  bytes in the second; in both, `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line,
  `shared.agents_md.users` is `["cursor"]` and the manifest has no `shared.claude_md`.
- Every removed or renamed assertion key gets a row in `tests/coverage-accepted-removals.tsv`
  (or the re-home allowlist when it moved to another suite).

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-multitool-isolation.sh --verbose` exits `0` with a `PASS:` line for every clause of AC-9, AC-10 and AC-14 (d) listed in Scope.
- [ ] `grep -c 'profiles/' tests/canonical/test-multitool-isolation.sh` prints `0`.
- [ ] The coverage-parity gate (`bash tests/coverage-parity.sh diff --baseline tests/coverage-baseline.tsv --collect --accept tests/coverage-accepted-removals.tsv --allow tests/coverage-rehome-allowlist.tsv`, run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.
