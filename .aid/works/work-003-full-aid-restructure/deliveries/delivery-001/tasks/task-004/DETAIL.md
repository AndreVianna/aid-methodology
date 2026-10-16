# task-004: Conversation-suite runner tests/conversation/run.py

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14, AC-21, AC-29

**Depends on:** task-001

**Scope:**
- Create `tests/conversation/run.py` (Python 3, standard library only), as REQUIREMENTS.md § 11
  Feature 001 `##### 6. Testing`, "Conversation suite", says. This task builds the harness that verifies
  the ACs above (NFR-T).
  - **Arguments:** `--feature NNN [--sample ID] [--hosts claude-code,...] [--runs 3]`.
  - **Exit codes:** 0 when every run passes, 1 on any failure, 2 on an invocation error.
  - **Samples:** reads `tests/conversation/samples/feature-NNN/<id>.md`, with frontmatter `id`, `covers`
    and `fixture`, and the sections `## User`, `## Answer sheet`, `## Expected outcome`, `## Must not`
    and `## Checks`. Any other frontmatter key is kept and ignored, never rejected. Feature 002's samples
    add `skills:`.
  - **Checks:** the `## Checks` grammar is documented in `run.py`'s header. It covers a file that exists
    or is absent, a file that contains a text, no new folder under a path, and no push.
  - **Fixture:** each run builds a fresh throwaway git project from `tests/conversation/fixtures/<fixture>/`.
    - AID is installed in it from a bundle staged by `tests/lib/bundle.sh`.
    - A sample's `bin/` goes first on the `PATH` of the agent under test.
    - Each run gets a throwaway `HOME`.
  - **Claude Code driver:** `claude -p` with `--output-format stream-json`, and `--resume <session-id>`
    for later turns. The fallback is one `--input-format stream-json` process.
  - **Other hosts:** each other host gets a start/send/read adapter through its non-interactive mode. A
    host without one is skipped with a notice.
  - **Flags:** the spec's flags for the agent under test, the simulated user and the judge (Permissions,
    Simulated user, judge). Confirm the tool names `Skill` and `Task` against `claude --help`, and
    record them in a comment.
  - **Limits:** a 12-user-turn cap and a 10-minute timeout per agent turn.
  - **Capture:** writes into `.aid/.temp/conversation-tests/<run-id>/<sample>/run-<n>/`:
    - `transcript.jsonl` and `transcript.md`;
    - `files.diff`, excluding the fixture's `.git/`, and `HOME`'s `.claude/`, `.claude.json` and
      credential files; a binary file appears as path and size only;
    - `checks.txt`;
    - the judge's ledger, also saved in the fixture's `.aid/.temp/review-pending/`.
  - **Pass rule:** any Pending ledger row fails the run, and a sample passes only when all its runs pass.
- Suites to update in this same task: none exist. The stub checks below run from a scratch area and are
  not committed. The permanent suite is task-019.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-004`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-004: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-004`.
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
     - Run `(cd site && npm test)` when this task changes `canonical/skills/`,
       `canonical/aid/templates/shortcut-catalog.yml`, `docs/` or `site/`. Run `npm ci` there first if
       `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `python3 tests/conversation/run.py --feature 001 --sample no-such-sample` exits 2, and so does a call without `--feature`. Every module `run.py` imports is in `sys.stdlib_module_names`.
- [ ] With a stub `claude` first on `PATH` that logs its argv and answers in stream-json, one `--runs 1` run writes `transcript.jsonl`, `transcript.md`, `files.diff`, `checks.txt` and the ledger into the run folder. For agent turns, the log shows `--permission-mode acceptEdits`, `--tools Read,Glob,Grep,Edit,Write,Bash,Skill,Task`, the same `--allowedTools`, `--strict-mcp-config`, `--setting-sources project`, no `--add-dir`, and `--resume` from turn 2 on. For the simulated user and the judge, it shows `--tools ""`, `--safe-mode`, `--strict-mcp-config` and `--system-prompt`.
- [ ] A stub turn that writes into the fixture's `.git/`, `HOME/.claude/`, `HOME/.claude.json` and a credential file leaves none of them in `files.diff`. A binary file appears as path and size only.
- [ ] A stub judge ledger with one Pending row fails its run. A sample with one failed run of 3 makes `run.py` exit 1. A stub that never sends `<<END>>` fails at the 12-turn cap.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
