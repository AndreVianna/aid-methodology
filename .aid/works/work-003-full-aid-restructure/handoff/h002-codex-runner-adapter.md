# h002: the Codex adapter for the conversation runner (part of task-365, Q152)

**From:** Claude. **To:** Codex. **Type:** edit source, named files only. Read `handoff/PROTOCOL.md`
first. Start only when `NEXT.md` names h002.

## Why

`tests/conversation/run.py` drives the agent under test through an adapter per host (`ADAPTERS`).
Only Claude Code has one. This job adds the one for Codex, on your machine, where the `codex` CLI is.
It is the Codex part of task-365
(`.aid/works/work-003-full-aid-restructure/deliveries/delivery-014/tasks/task-365/DETAIL.md`); the
Cursor, Copilot CLI and Antigravity adapters stay in task-365.

## Step 0: check the tools, then decide

Run `codex --version`, `codex exec --help` (or the non-interactive mode your CLI has) and
`claude --version`. Put the output in your reply.

- No `codex` CLI on your machine: stop, reply `status: blocked`, change nothing.
- Otherwise go on. A missing `claude` CLI is expected: the runner's simulated user and judge run on
  `claude`, so you cannot do a live run; the stub tests below stand in for it.

## What to build

Read first: `run.py` in full (the `ClaudeCodeAgent` class near line 300, `ADAPTERS` near line 376,
`run_once` near line 930, `main` near line 1025), task-365's DETAIL.md, and REQUIREMENTS.md § 11
Feature 001 `##### 6. Testing`, Conversation suite.

1. **A `CodexAgent` class** beside `ClaudeCodeAgent`, with the same start / send / read steps, through
   Codex's own non-interactive mode. Confirm each flag against `--help` and record the flags in a
   comment, as the Claude Code driver does. It keeps the same limits (12 user turns, 10 minutes per
   agent turn), runs in the fixture folder with the throwaway `HOME`, and fills the same transcript
   entries, so `## Checks` and the judge work unchanged. A check kind the Codex output cannot answer
   (for example `tool-called`, if its output names no tools) is reported as not run for that host,
   never as a pass. Resuming a conversation: use the CLI's own resume or session option if it has one;
   say in a comment what you used.
2. **Register it** in `ADAPTERS` as `"codex"`, and make `run_once` use the adapter of the host being
   run (today it always takes `ADAPTERS["claude-code"]`). Claude Code's behaviour must not change.
3. **Not installed or not signed in:** the host is skipped with a NOTICE, and the run goes on as before
   for Claude Code, so cloud sessions and CI keep working without `codex`.
4. Update the "Other hosts" comment and the header so they name the Codex adapter.
5. **Tests** in `tests/canonical/test-conversation-runner.sh`, in the style of its Claude Code cases
   (a stub `codex` first on `PATH`): start, a second turn, the capture files, a check kind reported as
   not run, and the missing-tool NOTICE. Each new case fails on a throwaway copy of `run.py` with its
   part reverted, as the suite's mutation cases do. New ids must not reuse existing ones.

## Tests to run

`python3 -m py_compile tests/conversation/run.py`, `bash -n tests/canonical/test-conversation-runner.sh`,
then `HOME="$(mktemp -d)" bash tests/canonical/test-conversation-runner.sh` (about a minute). Every
existing case must still pass. Do not run `tests/run-all.sh`.

## Files you may write

- `tests/conversation/run.py`
- `tests/canonical/test-conversation-runner.sh`
- `handoff/replies/h002.md`

Do not edit task-365's files, `known-issues.md` or any state file: Claude records the split.

## Reply and commit

In `replies/h002.md`: status; the step-0 output; the flags you used and why; each test result; what a
live run on a machine with both CLIs still has to confirm. Commit the three files as
`h002: Codex adapter for the conversation runner`, push, and tell the maintainer: "h002 done".
