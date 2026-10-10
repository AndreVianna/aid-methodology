# task-001: Make the canonical skills tool-neutral final bytes

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-4, AC-6

**Depends on:** -- (none)

**Scope:**
- Rewrite every `canonical/...` token in `canonical/skills/**` on EVERY line, headings and code
  blocks included (the old `rewrite_install_paths` skipped `#`-prefixed lines; these bytes are now
  final). Mapping per REQUIREMENTS.md § 11 Feature 001 › Layers & Components › Canonical sources:
  `canonical/(aid/)?scripts/` -> `.aid/runtime/scripts/`; `canonical/(aid/)?templates/` ->
  `.aid/runtime/templates/`; `canonical/skills/` -> `.agents/skills/`; `canonical/agents/<a>/AGENT.md`
  (and the `canonical/agents/*/AGENT.md` glob form) -> the agent name (e.g. `aid-architect`); any
  `canonical/(aid/)?recipes/` token is resolved by the same rule or removed if it names a retired path.
- Resolve the filename placeholders: `{project_context_file}` -> `AGENTS.md`,
  `{reviewer_output_file}` -> `STATE.md`, `{open_questions_file}` -> `additional-info.md`.
- Remove every host install-root path from `canonical/skills/`: the `.claude/aid/scripts/...`
  commands in `aid-discover/references/state-generate.md` and `aid-discover/references/agent-prompts.md`
  become `.aid/runtime/scripts/...`; the dogfood description in `aid-discover/SKILL.md` (search:
  "this is the **dogfood install**") and the `canonical/ -> profiles/* -> .claude/, .cursor/` row in
  `aid-execute/references/state-fix.md` are reworded to the new chain (canonical -> release payload
  -> CLI install into `.agents/skills/` and `.aid/runtime/`) with no `.claude/`/`.cursor/` path.
- Worktree call sites (Feature Flow 9): in `aid-update-kb/SKILL.md` replace the line
  `WT_ROOT="${MAIN_ROOT}/.claude/worktrees"` with
  `WT_ROOT="$(bash .aid/runtime/scripts/works/worktree-lifecycle.sh root)"`; in `aid-execute/SKILL.md`
  the nesting paragraph (search: "work-level `.claude/worktrees/work-NNN-{name}`") names "the
  work-level worktree root that `worktree-lifecycle.sh root` prints". The `root` operation itself is
  built by task-011.
- `allowed-tools` (FR-2): every value space-separated; wherever `Bash` is listed it becomes the
  three aliases `Bash Shell Terminal`; no skill carries a `context:` or `agent:` frontmatter key.
- `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`: emit the neutral body tokens,
  the space-separated `allowed-tools` (`_ALLOWED_TOOLS`) with `Bash Shell Terminal`, and a
  provenance comment naming `generate-profile/scripts/build-shortcut-skills.py` with no host install
  root. Regenerate the doorways by running it, so a later regeneration cannot reintroduce the old form.
- Update every existing suite or repo check that pins the old skill-content strings (for example
  the `allowed-tools: Read, Glob, Grep, AskUserQuestion` literals in
  `tests/canonical/test-ticket-skills-structural.sh`, TR01a in `test-triage-routing.sh`,
  `test-shortcut-builder-invariants.sh`, the `*-family-scaffold.sh` suites, `test-criterion-oracles.sh`,
  and `scripts/checks/review-path-audit.sh` if it parses skill references). A renamed or removed
  assertion key gets a row in `tests/coverage-accepted-removals.tsv` or the re-home allowlist.
- Out of scope: `canonical/aid/**` (task-002) and `canonical/agents/**` (task-003). Do NOT run
  `run_generator.py` and do NOT commit changes under `profiles/`, `.claude/` (other than
  `.claude/skills/generate-profile/**`) or `.cursor/`: task-003 runs the full render after the
  generator stops rendering skills, and task-027 resyncs the dogfood trees, so the installed tree
  that is executing this work stays self-consistent until then.

**Acceptance Criteria:**
- [ ] `grep -rlE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/' canonical/skills | wc -l` prints `0`.
- [ ] `grep -rlE '\{(project_context_file|reviewer_output_file|open_questions_file)\}' canonical/skills | wc -l` prints `0`.
- [ ] `grep -rlE '\.(claude|codex|cursor|agent)/' canonical/skills | wc -l` prints `0`, and `grep -rlE '\.github/(aid|skills|agents)/' canonical/skills | wc -l` prints `0`.
- [ ] `grep -rn '\.claude/worktrees' canonical/skills | wc -l` prints `0`, and `grep -c 'worktree-lifecycle.sh root' canonical/skills/aid-update-kb/SKILL.md canonical/skills/aid-execute/SKILL.md` prints at least `1` for each file.
- [ ] `grep -l '^allowed-tools:.*,' canonical/skills/*/SKILL.md | wc -l` prints `0`.
- [ ] The count of `canonical/skills/*/SKILL.md` whose `allowed-tools` line names `Bash` equals the count whose `allowed-tools` line contains `Bash Shell Terminal`.
- [ ] `grep -lE '^(context|agent):' canonical/skills/*/SKILL.md | wc -l` prints `0`.
- [ ] Running `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py` a second time leaves `git status --porcelain canonical/skills` empty (the builder already emits the committed form), and no generated doorway contains `.claude/skills/generate-profile`.
- [ ] Every suite this task edited passes when run on its own (`bash tests/canonical/<suite>.sh` exits `0`), and `bash tests/coverage-parity.sh diff --baseline tests/coverage-baseline.tsv --collect --accept tests/coverage-accepted-removals.tsv --allow tests/coverage-rehome-allowlist.tsv` (run where `pwsh`, `node` and `python3` are on PATH, as its runtime precondition requires) reports no un-excused removal for those suites.
- [ ] `git diff --name-only` for this task's commit lists no path under `profiles/`, `canonical/aid/`, `canonical/agents/`, `.cursor/`, or `.claude/` outside `.claude/skills/generate-profile/`.
- [ ] All section-6 quality gates pass.
