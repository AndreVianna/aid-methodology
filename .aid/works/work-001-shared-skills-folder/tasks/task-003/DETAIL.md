# task-003: Cut the profile generator down to agents and `aid-tool.conf`

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-1, AC-21

**Depends on:** task-002

**Scope:**
- `canonical/agents/**`: apply the task-001 token mapping so the generator applies no text
  transform (task-002 already neutralised the `{{include:agent-boilerplate}}` source in
  `canonical/aid/templates/agent-boilerplate.md`, which is why this task depends on it).
- `.claude/skills/generate-profile/scripts/render.py`: `render_profile` renders only
  `canonical/agents/` and writes `profiles/<tool>/aid-tool.conf` (recorded in that profile's
  emission manifest). Delete `copy_tree`'s `skills` and `none` branches and
  `_rewrite_skill_frontmatter`. Keep `_translate_agent` (the `[tool_names]` remap on `tools:`, model
  resolution, the Codex TOML branch) and `{{include:...}}` expansion. VERIFY fails when a rendered
  agent still carries a `canonical/` token. Update `--self-test`.
- `aid-tool.conf` format and content exactly per REQUIREMENTS.md § 11 Feature 001 › Data Model ›
  Descriptor format and Per-profile placement data: ASCII, LF, `key=value`; `tool=<id>`;
  `skill_mirror=<dir>` (0..n); `worktree_root=<dir>` (0..1).
- `render_lib.py`: delete `rewrite_install_paths` and `substitute_filenames` and their call sites
  and self-test cases.
- `aid_profile.py`: validate the new TOML keys `skill_mirrors` (list; each matches
  `^\.[a-z]+/skills$`, is not `.agents/skills`, and sits under the profile's own root) and
  `worktree_root` (`.aid/.worktrees` or `<root_dir>/worktrees`, relative, no `..`); `root_file`
  must be `"AGENTS.md"`.
- `profiles/*.toml`: `root_file = "AGENTS.md"` in all five; `claude-code.toml` gains
  `skill_mirrors = [".claude/skills"]` and `worktree_root = ".claude/worktrees"`; the other four
  declare neither. Header comments stop saying the profile emits a skills/runtime tree.
- `verify_deterministic.py`, `verify_advisory.py` (and `test_manifest_safety.py` where affected):
  scope cut to agents plus `aid-tool.conf`.
- `run_generator.py`: stays the single full-render command; its pure-mirror deletion removes
  every former `skills/` and `aid/` row and file. It keeps chaining the dogfood resync script
  (task-027 re-points that script).
- `canonical/EMISSION-MANIFEST.md` § Asset Kinds: agents and `aid-tool.conf` only, for all five
  profiles. `profiles/*/README.md`: no longer describe a skills or runtime tree.
- Re-key the existing suites that read rendered skill/runtime trees under `profiles/`:
  `test-chat-node-wake.sh` (WK23), `test-cutover-no-dangling.sh` (Part 2 mirror-deletion), and the
  profile-README rows of `test-doc-counts.sh`. Removed or renamed keys get rows in
  `tests/coverage-accepted-removals.tsv`.
- Commit `profiles/`, `canonical/agents/`, `canonical/EMISSION-MANIFEST.md`, the generator scripts
  and the re-keyed suites only. The chained dogfood sync will also rewrite `.claude/agents/` and
  `.cursor/agents/`: discard those changes (`git checkout -- .claude/agents .cursor/agents`). The
  re-rendered agents point at `.aid/runtime/`, which this repo does not have until task-027, and the
  agents executing this work must keep resolving their templates.
- Known red until later tasks: `test-release.sh` (task-007) and `test-dogfood-byte-identity.sh`
  (task-028).

**Acceptance Criteria:**
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py` exits `0` and prints `VERIFY (deterministic): PASS`.
- [ ] `grep -cE '"dst": *"[^"]*/(skills|aid)/' profiles/*/emission-manifest.jsonl` prints `0` for all five manifests.
- [ ] `find profiles -type d \( -name skills -o -name aid \)` prints nothing.
- [ ] `profiles/claude-code/aid-tool.conf` holds exactly the lines `tool=claude-code`, `skill_mirror=.claude/skills`, `worktree_root=.claude/worktrees`; each other profile's `aid-tool.conf` holds exactly `tool=<id>`; each file is listed in its profile's `emission-manifest.jsonl`.
- [ ] `grep -L 'root_file *= *"AGENTS.md"' profiles/*.toml` prints nothing.
- [ ] `grep -rlE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/' canonical/agents profiles | wc -l` prints `0`.
- [ ] `grep -nE 'def (rewrite_install_paths|substitute_filenames|_rewrite_skill_frontmatter)' .claude/skills/generate-profile/scripts/*.py` prints nothing.
- [ ] `python .claude/skills/generate-profile/scripts/render_lib.py --self-test`, `test_manifest_safety.py --self-test`, `render.py --self-test --canonical-root .`, `verify_deterministic.py --self-test --canonical-root .` and `verify_advisory.py --self-test --canonical-root .` all exit `0`; the `aid_profile.py` validation rejects a profile whose `skill_mirrors` contains `.agents/skills` (a self-test case shows it).
- [ ] `bash tests/canonical/test-chat-node-wake.sh`, `test-cutover-no-dangling.sh` and `test-doc-counts.sh` exit `0`.
- [ ] `git diff --name-only` for this task's commit lists no path under `.claude/` outside `.claude/skills/generate-profile/`, and none under `.cursor/`.
- [ ] All section-6 quality gates pass.
