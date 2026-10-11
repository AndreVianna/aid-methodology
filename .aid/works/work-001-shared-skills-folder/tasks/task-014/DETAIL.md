# task-014: `aid update` commits every installed tool and the shared payload at one version

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-10, AC-11, AC-14

**Depends on:** task-010

**Scope:**
Bash and PowerShell twins together (`bin/aid` and `bin/aid.ps1`, plus any core helper they
need), per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 4.
- The self-update preamble and the format gate run unchanged first.
- The commit set is every installed tool plus any named tool, all at one version; a named subset is
  widened, and the CLI prints a notice listing the tools it added. A subset can no longer advance the
  shared files ahead of the other tools.
- Stage everything (Flow 2) before any write, then run the Flow 3 commit steps for all tools
  (shared skills, mirrors, runtime + `host.conf`, agents, `AGENTS.md` pointer region, the `CLAUDE.md`
  import region while `claude-code` is installed, manifest, `prune_shared`, settings seed,
  `update_gitignore`, then `update_gitattributes` right after it, then `_migrate_term_exclusions`).
  Every `copy_file_guarded` call passes the recorded sha256 of the previous manifest, so an
  unedited file of the previous version is overwritten with no trash entry and only a DRIFTED file
  is trashed first (FR-9; task-004). Every tool `version` and every `shared.*.version` ends equal to
  `aid_version`.
- A v3 layout (a format-2 manifest, or the old `<root>/aid/` and `<root>/skills/aid-*` paths) is
  the clean-slate upgrade's branch: this task leaves a single, clearly named dispatch point that
  task-015 fills with `retire_v3_layout` followed by the fresh install; until then `aid update` on
  such a layout exits non-zero naming the missing upgrade and writes nothing.
- Runtime-local paths (FR-6: any `node_modules/` under `.aid/runtime/`) survive every update; they
  reach neither the prune list nor the trash (the exclusion lives in `prune_shared`, task-010).
- Run `_aid_migrate_repo` afterwards (it stamps 5 on a format-3 manifest, per task-006's cap).
- `--dry-run` stops after staging and prints, in addition to today's copy list, the shared copies,
  the trash moves and the prune list.
- Idempotency: a second `aid update` at the same version prints `up to date (N files)` for `shared`
  and for every tool and changes nothing, `.aid/.trash/` included.
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] After `aid add claude-code,cursor`, `aid update cursor --from-bundle "$S"` prints a notice naming `claude-code` as added to the commit set, and afterwards every `tools.*.version` and `shared.*.version` in the manifest equals `aid_version`; `.gitattributes` holds the managed block with the three `text eol=lf` lines and a pre-existing user line in it is unchanged.
- [ ] Non-drifted upgrade: in a fixture installed from staging X, `aid update --from-bundle <staging Y>` (Y built from a scratch copy of the tree with one `canonical/skills` file changed) overwrites the unedited installed copy of that file with the new bytes and no entry for that path exists under `.aid/.trash/`.
- [ ] With the AC-10 drift applied (one byte appended to `.claude/skills/aid-ask/SKILL.md`, `.claude/skills/aid-fix/SKILL.md` deleted, one byte appended to `.agents/skills/aid-plan/SKILL.md`), `aid update --from-bundle "$S"` restores all three to canonical bytes; the two modified files exist byte-for-byte at `.aid/.trash/.claude/skills/aid-ask/SKILL.md` and `.aid/.trash/.agents/skills/aid-plan/SKILL.md`; a following `aid status` prints `Shared files: clean`.
- [ ] A stray `.aid/runtime/stray.txt` is absent from `.aid/runtime/` after the next `aid update`, while a fixture file `.aid/runtime/scripts/summarize/node_modules/x.js` survives it with unchanged sha256, nothing from it lands in `.aid/.trash/`, and `aid status` prints no `extra:` line for it.
- [ ] `aid update` on a fixture holding a format-2 manifest reaches the upgrade dispatch point, not the normal commit path (until task-015: exits non-zero naming the missing upgrade and writes nothing; the fixture snapshot is unchanged).
- [ ] A second `aid update --from-bundle "$S"` prints `up to date` in the `shared` block and every tool block, and the sha256 snapshot of `.aid/.trash/` and of the whole fixture is unchanged.
- [ ] In a fixture whose user `CLAUDE.md` (no markers, LF-terminated) received the import region on `aid add claude-code`, a following `aid update --from-bundle "$S"` leaves `CLAUDE.md`'s sha256 unchanged.
- [ ] `aid update --dry-run --from-bundle "$S"` on a drifted fixture lists the shared copies, the trash moves and the prune list, and the fixture snapshot is unchanged.
- [ ] The same cases under `bin/aid.ps1` give the same output lines, exit codes and manifest bytes (masked timestamps) where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
