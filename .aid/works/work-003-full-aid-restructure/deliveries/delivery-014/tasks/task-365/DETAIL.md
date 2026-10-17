# task-365: Conversation runner: adapters for Codex, Cursor, Copilot CLI and Antigravity

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 365 --field State.

**Type:** IMPLEMENT

**Source:** feature-001-plain-language-requests -> delivery-014 -> NFR-T (KI-006, Q144)

**Depends on:** --

**Where it runs:** on the maintainer's machine, where the `codex`, `cursor-agent`, `copilot` and
Antigravity command-line tools are installed and signed in (Q144). A session without them cannot build or
test this task; it stops this task with `write-control-signal.sh` and runs the rest of the delivery.

**Scope:**
- `tests/conversation/run.py` (REQUIREMENTS.md § 11 Feature 001 `##### 6. Testing`, Conversation suite,
  Driving the conversation: "The other four tools use an adapter with the same three steps (start, send,
  read) through their own non-interactive mode; a tool without one is skipped with a notice"; Feature 009
  `##### 6. Risks`, The stand-ins: "one run against a scratch repository on each host is part of the full
  integration suite before release"):
  - add a start/send/read adapter to `ADAPTERS` for each of `codex`, `cursor`, `copilot-cli` and
    `antigravity`, beside the Claude Code driver, through that tool's own non-interactive mode. Confirm each
    tool's flags against its own `--help` and record them in a comment, as the Claude Code driver does;
  - each adapter keeps the Claude Code driver's limits (12 user turns, 10 minutes per agent turn), runs in the
    fixture folder with the throwaway `HOME`, and writes the same capture files, so `## Checks` and the judge
    work unchanged. A check kind a tool's output cannot answer (for example `tool-called` on a tool whose
    transcript names no tools) is reported as not run for that host, never as a pass;
  - a tool that is not installed, or not signed in, is still skipped with a NOTICE, so the cloud sessions and
    CI keep working with Claude Code alone;
  - update the "Other hosts" comment and the header so they name the four adapters.
- `tests/canonical/test-conversation-runner.sh`: one case per adapter, with a stub of that tool first on
  `PATH` (as the Claude Code cases do), covering start, a second turn and the capture files; and one case that
  a missing tool is skipped with the NOTICE.
- One smoke run of one Feature 001 sample per host with `--hosts <host> --runs 1`, in a scratch copy made as
  the test step says. Report each result; a failure caused by the product is reported, not hidden.
- Close KI-006 in `known-issues.md` with a `**Status:**` line naming this task.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-365.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-365`.
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
- [ ] `ADAPTERS` holds an entry for each of `claude-code`, `codex`, `cursor`, `copilot-cli` and `antigravity`, and `python3 tests/conversation/run.py --feature 001 --sample <id> --hosts <host> --runs 1` runs, not skips, on each of the four new hosts on the maintainer's machine.
- [ ] With a host's tool absent from `PATH`, the run prints `NOTICE: no non-interactive adapter for host <host>; skipped` or a NOTICE that the tool is not installed, and exits as before for Claude Code.
- [ ] `test-conversation-runner.sh` has one passing case per new adapter and one for the missing-tool skip, each failing its own mutation in a throwaway copy of `run.py`.
- [ ] Each host's smoke run is reported, and KI-006 carries its `**Status:**` line.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
