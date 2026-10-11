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
Per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 7 and Upgrade from v3 › This repo (dogfood).
- Re-point `.claude/skills/generate-profile/scripts/sync_dogfood.py`: it no longer copies profile
  renders; it runs `bash release.sh --stage-only --out <tmp>`, then the repo's own
  `bin/aid update --from-bundle <tmp> --target <repo>` with `AID_HOME=<tmp-home>` and
  `AID_NO_UPDATE_CHECK=1`, so the maintainer's registry and the network are never touched. `--check`
  reports drift (via `aid status`'s `Shared files` block) without writing. `run_generator.py` keeps
  chaining it; no recursion, because `--stage-only` never runs the generator.
- Run it once against this repo (manifest format 2, tools `claude-code` and `cursor`). This is the
  clean-slate upgrade: `retire_v3_layout` moves `.claude/aid/`, `.cursor/aid/` and
  `.cursor/skills/aid-*` (and the old `.claude/skills/aid-*` files) to `.aid/.trash/` and copies the
  root `CLAUDE.md` and `AGENTS.md` to the trash with their old AID regions removed; then the fresh
  install writes `.agents/skills/aid-*`, the `.claude/skills/aid-*` mirror, `.aid/runtime/` (with
  `rules.md` and `host.conf` = `worktree_root=.claude/worktrees`), the agents, the `AGENTS.md`
  pointer region, the `CLAUDE.md` import region (the `## Project` section is kept byte for byte, the
  pre-resync file goes to `.aid/.trash/CLAUDE.md`), and the `.gitignore` and `.gitattributes`
  managed blocks (the fresh-install commit steps write `update_gitattributes`; the repo-root
  `.gitattributes` exists, so the block is inserted into it). It keeps
  `.claude/skills/generate-profile/`, `.claude/skills/release-aid/`, `.claude/settings.json`,
  `.claude/output-styles/` and `.cursor/rules/`.
- Commit the results: `.aid/.aid-manifest.json`, `.aid/settings.yml`, `.agents/skills/`,
  `.claude/skills/aid-*`, `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`, `AGENTS.md`,
  `CLAUDE.md`, `.gitignore`, `.gitattributes`, and the deletions of the retired trees.
  `.aid/.trash/` stays untracked (it is gitignored).
- Runbook in `.claude/skills/generate-profile/SKILL.md`: the release-faithful procedure
  (`bash release.sh --dry-run`, then `aid update --from-bundle .aid/.temp/release-<V>`), the
  `sync_dogfood.py` shortcut, and the rollback (`git checkout <pre-resync> -- .claude .cursor
  CLAUDE.md AGENTS.md .aid/.aid-manifest.json .aid/settings.yml .gitignore .gitattributes`, then
  remove `.agents/skills/aid-*` and `.aid/runtime/`).
- Idempotency: a second resync changes nothing (`git status --porcelain` is empty).
- Heads-up for the executor: from this commit on, the installed skills and agents that drive the
  pipeline resolve their runtime under `.aid/runtime/`; finish this task in one step and confirm the
  pipeline's own scripts resolve (for example, `bash .aid/runtime/scripts/execute/derive-waves.sh --from-tasks <this work's folder>`
  prints the same wave map it printed before the resync).
- Bootstrap switch (task-set review row 25): this resync removes `.claude/aid/`, which the running pipeline uses for state writes. Run the resync as the last step of this task, after this task's `In Review` state write. From then on every state write (this task's terminal state and tasks 028-032) calls `.aid/runtime/scripts/execute/writeback-state.sh` with the same arguments and `AID_STATE_FILE`, and the orchestrator re-reads `.claude/skills/aid-execute/SKILL.md` from the resynced mirror before dispatching the next task.

**Acceptance Criteria:**
- [ ] For every file `canonical/skills/<rel>`, `cmp canonical/skills/<rel> .agents/skills/<rel>` and `cmp canonical/skills/<rel> .claude/skills/<rel>` succeed; `diff -r -x node_modules -x '.*' canonical/aid .aid/runtime` prints only `Only in .aid/runtime: host.conf` (so `scripts`, `templates` and `rules.md` equal their canonical sources under the payload exclusions); `cat .aid/runtime/host.conf` prints exactly `worktree_root=.claude/worktrees`.
- [ ] `.claude/aid/`, `.cursor/aid/` and every `.cursor/skills/aid-*` are absent; `.claude/skills/generate-profile/SKILL.md` (apart from the runbook this task adds to it), `.claude/skills/release-aid/SKILL.md` and `.cursor/rules/output-style.mdc` are present, and the latter two are unchanged by the resync (`git diff --quiet <pre-resync> -- <path>` succeeds).
- [ ] `.aid/.aid-manifest.json` has `"format_version": 3` and records `shared.skills`, `shared.runtime`, `shared.agents_md` (users `claude-code`, `cursor`), the `.claude/skills` mirror and `shared.claude_md` (users `claude-code` for both); `.aid/settings.yml` has `format_version: 5`.
- [ ] `AGENTS.md` equals the five-line pointer region plus any user content it held, with exactly one `<!-- AID:BEGIN -->` line; the root `CLAUDE.md` keeps its `## Project` section (all pre-resync content outside the old AID region) byte for byte, and its AID region holds only `@AGENTS.md` (exactly one `@AGENTS.md` line in the file); `.gitattributes` holds the AID managed block and every pre-resync line of it is unchanged.
- [ ] Running `python .claude/skills/generate-profile/scripts/sync_dogfood.py` a second time prints `up to date` for `shared` and both tools, and `git status --porcelain` is empty afterwards (the first resync's commit already includes `.gitattributes`).
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py` exits `0` and leaves `git status --porcelain` empty.
- [ ] After the resync, `AID_STATE_FILE=.aid/works/work-001-shared-skills-folder/STATE.yml bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Updated --value <timestamp>` exits 0, and `grep -rl '.claude/aid/scripts' .claude/skills/aid-execute/` prints nothing.
- [ ] All section-6 quality gates pass.
