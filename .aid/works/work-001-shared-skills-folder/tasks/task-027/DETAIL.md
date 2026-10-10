# task-027: Resync this repo's installed trees by CLI install from a local release staging

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

**Type:** MIGRATE

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-18

**Depends on:** task-001, task-003, task-011, task-012, task-013, task-015

**Scope:**
Per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 7 and Migration Plan › This repo (dogfood).
- Re-point `.claude/skills/generate-profile/scripts/sync_dogfood.py`: it no longer copies
  emission-manifest rows; it runs `bash release.sh --stage-only --out <tmp>`, then the repo's own
  `bin/aid update --from-bundle <tmp> --target <repo>` with `AID_HOME=<tmp-home>` and
  `AID_NO_UPDATE_CHECK=1`, so the maintainer's registry and the network are never touched. `--check`
  reports drift (via `aid status`'s `Shared files` block) without writing. `run_generator.py` keeps
  chaining it; no recursion, because `--stage-only` never runs the generator.
- Run it once against this repo (manifest format 2, tools `claude-code` and `cursor`). This is the
  forward migration: it writes `.agents/skills/aid-*`, rewrites `.claude/skills/aid-*` as the
  mirror, writes `.aid/runtime/` (with `host.conf` = `worktree_root=.claude/worktrees`), the agents
  and the `AGENTS.md` region; moves `.claude/aid/`, `.cursor/aid/` and `.cursor/skills/aid-*` to
  `.aid/.trash/`; migrates the root `CLAUDE.md` through `_ensure_claude_md_region` (its full AID
  region becomes the `@AGENTS.md` import region, the `## Project` section outside the markers is
  kept byte for byte, and the pre-resync file goes to `.aid/.trash/CLAUDE.md`); keeps
  `.claude/skills/generate-profile/`, `.claude/skills/release-aid/`, `.claude/settings.json`,
  `.claude/output-styles/` and `.cursor/rules/`.
- Commit the results: `.aid/.aid-manifest.json`, `.aid/settings.yml`, `.agents/skills/`,
  `.claude/skills/aid-*`, `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`, `AGENTS.md`,
  `CLAUDE.md`, `.gitignore`, and the deletions of the retired trees. `.aid/.trash/` stays untracked
  (it is gitignored).
- Runbook in `.claude/skills/generate-profile/SKILL.md`: the release-faithful procedure
  (`bash release.sh --dry-run`, then `aid update --from-bundle .aid/.temp/release-<V>`), the
  `sync_dogfood.py` shortcut, and the rollback (`git checkout <pre-resync> -- .claude .cursor
  CLAUDE.md AGENTS.md .aid/.aid-manifest.json .aid/settings.yml .gitignore`, then remove
  `.agents/skills/aid-*` and `.aid/runtime/`).
- Idempotency: a second resync changes nothing.
- Heads-up for the executor: from this commit on, the installed skills and agents that drive the
  pipeline resolve their runtime under `.aid/runtime/`; finish this task in one step and confirm the
  pipeline's own scripts resolve (for example, `bash .aid/runtime/scripts/execute/derive-waves.sh --from-tasks <this work's folder>`
  prints the same wave map it printed before the resync).

**Acceptance Criteria:**
- [ ] For every file `canonical/skills/<rel>`, `cmp canonical/skills/<rel> .agents/skills/<rel>` and `cmp canonical/skills/<rel> .claude/skills/<rel>` succeed; `diff -r canonical/aid/scripts .aid/runtime/scripts` and `diff -r canonical/aid/templates .aid/runtime/templates` print nothing.
- [ ] `.claude/aid/`, `.cursor/aid/` and every `.cursor/skills/aid-*` are absent; `.claude/skills/generate-profile/SKILL.md`, `.claude/skills/release-aid/SKILL.md` and `.cursor/rules/output-style.mdc` are present and unchanged.
- [ ] `.aid/.aid-manifest.json` has `"format_version": 3` and records `shared.skills`, `shared.runtime`, `shared.agents_md` (users `claude-code`, `cursor`), the `.claude/skills` mirror and `shared.claude_md` (users `claude-code` for both); `.aid/settings.yml` has `format_version: 5`.
- [ ] `grep -c '^<!-- AID:BEGIN -->$' AGENTS.md` prints `1`; the root `CLAUDE.md` keeps its `## Project` section (all pre-resync content outside the AID markers) byte for byte, and its AID region holds only `@AGENTS.md` (exactly one `@AGENTS.md` line in the file).
- [ ] Running `python .claude/skills/generate-profile/scripts/sync_dogfood.py` a second time prints `up to date` for `shared` and both tools, and `git status --porcelain` is empty afterwards.
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py` exits `0` and leaves `git status --porcelain` empty.
- [ ] All section-6 quality gates pass.
