# task-366: Conversation runner: judge input size, environment isolation, end conditions

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 366 --field State.

**Type:** TEST

**Source:** feature-001-plain-language-requests -> delivery-001 -> NFR-T (Q147 diagnosis, root cause RC-4)

**Depends on:** task-018

**Scope:**
- `tests/conversation/run.py` (REQUIREMENTS.md § 11 Feature 001 `##### 6. Testing`, Transcript capture and Driving the conversation; `.aid/works/work-003-full-aid-restructure/analysis/delivery-001-sample-diagnosis.md` § 3 fixes 1-4 and § 4):
  - `build_diff`: a file under the fixture's `.claude/worktrees/<wt>/` is diffed against the fixture's baseline file of the same relative path, and is omitted when byte-identical; nothing the agent changes is hidden, so `.claude/worktrees/` and `.aid/` are never excluded wholesale;
  - `home_skip`: also exclude `.ccr/`, `.pki/`, `.local/share/pki/`, `.aws/` and `.boto` (the sandbox's own set-up and credential files);
  - the judge prompt only (the full `files.diff` stays on disk): cap each file's diff text and the total, with a `[... N lines of <path> truncated ...]` marker;
  - `base_env`: drop the parent session's `CLAUDE_CODE_*`, `CLAUDECODE` and `CLAUDE_EFFORT` variables, keep proxy and CA variables, pass an explicit `--model` (default named in the header, overridable by an environment variable) and write the model into the run folder.
- `tests/conversation/simulated-user.md` and the per-turn prompt in `run.py`: the answer sheet's end conditions come first and override every other rule.
- `tests/conversation/judge.md`: truncated diff content must not be read as absent; no row that is not an EO-n or MN-n item, and an item met in substance gets no row.
- `tests/canonical/test-conversation-runner.sh`: one case per behaviour above, each with its mutation.
- Update `.aid/knowledge/test-landscape.md` § The Skill Guide and Conversation Suites where it states what `files.diff` holds or which model runs.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-366.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-366`.
       That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
     - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
     - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
     - Run `rm -rf "$S"` before step 4.
     - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
  4. **Live half.**
     - When `LIVE` is every suite outside `COPY`, run `HOME="$(mktemp -d)" bash tests/run-all.sh` and
       drop the `COPY` suites' results by name.
     - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
  5. **Outside `run-all.sh`.**
     - Run `(cd site && npm test)` when this task changes anything under `canonical/skills/`,
       `canonical/agents/` or `canonical/aid/templates/`, or under `docs/` or `site/` (G5). Run `npm ci`
       there first if `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).


**Acceptance Criteria:**
- [ ] A run whose agent creates a worktree under the fixture's `.claude/worktrees/` yields a `files.diff` that diffs each worktree file against the fixture's baseline file of the same path and omits identical files; the sandbox set-up files under HOME (`.ccr/`, `.pki/`, `.local/share/pki/`, `.aws/`, `.boto`) are excluded; the judge prompt caps each file's diff and the total with an explicit truncation marker, and `judge.md` says truncated content is not absent.
- [ ] The agent under test runs with an explicit model and with the parent session's `CLAUDE_CODE_*` / `CLAUDECODE` / `CLAUDE_EFFORT` variables removed (proxy and CA variables kept); the model is recorded in the run folder.
- [ ] `simulated-user.md` makes the answer sheet's end conditions override every other rule, and the per-turn prompt repeats it; `judge.md` forbids any row that is not an EO-n or MN-n item.
- [ ] `test-conversation-runner.sh` has a passing case for each of these four behaviours, each failing its own mutation in a throwaway copy of `run.py` inside the tree.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
