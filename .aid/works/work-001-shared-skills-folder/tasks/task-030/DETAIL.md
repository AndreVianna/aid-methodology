# task-030: State the shared layout in the README, docs and CI workflow text

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

**Type:** DOCUMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-19

**Depends on:** task-026, task-027

**Scope:**
- `README.md`, `docs/install.md` and `docs/aid-methodology.md`: describe what `aid add` places for
  every tool (`.agents/skills/aid-*`, `.aid/runtime/`, the `AGENTS.md` region, each tool's agents),
  the Claude Code `.claude/skills` mirror and `CLAUDE.md` `@AGENTS.md` import region, running
  several tools on one repo (reference counting, one version per repo, `aid update` to upgrade,
  `aid status` drift report), the release artifact set, and the format-4 -> 5 migration on
  `aid update` (with `.aid/.trash/`). `--from-bundle` takes a staging directory.
- `.github/workflows/test.yml`: the header comment (search: "the shippable product is the rendered
  install trees") and the `render-drift` job text describe agents-only renders plus the shared
  payload; any step that still assumes rendered skills or a per-tool runtime is corrected.
- `site/`: every doc or data file that states the old layout (find them with the AC-19 grep
  pathspec `site`; e.g. `site/src/data/skill-flows/aid-discover.flow.json`) is updated to the
  `.aid/runtime/` / `.agents/skills/aid-*` layout.
- The repo-root `CLAUDE.md` and `AGENTS.md` are NOT hand-edited here: they come out of the dogfood
  resync (task-027), sourced from `canonical/AGENTS.md`.
- Match each doc's existing style; no work id or work-folder path appears in any of these files.

**Acceptance Criteria:**
- [ ] `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- CLAUDE.md AGENTS.md README.md docs .github/workflows` prints no lines.
- [ ] `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- site 'profiles/*/README.md'` prints no lines.
- [ ] `grep -n '\.agents/skills' README.md docs/install.md` and `grep -n '\.aid/runtime' README.md docs/install.md` each print at least one line per file.
- [ ] `grep -cE 'work-[0-9]{3}|\.aid/works/' README.md docs/install.md docs/aid-methodology.md` prints `0` for each file.
- [ ] `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test.yml'))"` exits `0` (the workflow still parses).
- [ ] All section-6 quality gates pass.
