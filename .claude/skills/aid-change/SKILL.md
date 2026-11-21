---
name: aid-change
description: Make a small change directly or plan larger work, with evidence-based tests and independent review.
allowed-tools: Read Glob Grep Write Edit Bash Shell Terminal Task
argument-hint: "what should change"
hooks:
  PreToolUse:
    - matcher: "Bash|PowerShell"
      hooks:
        - type: command
          command: 'python3 "$CLAUDE_PROJECT_DIR/.aid/runtime/scripts/change/safeguard.py"'
---

# Change

Keep the request and the project card in view. Use targeted searches to identify relevant KB facts and project rules; verify them against current source when they describe implementation, and carry applicable constraints into the checks. Report conflicts or unavailable evidence. Exclude `.git` and generated trees unless needed; prefer relevant sections or command help over dumping whole files. Preserve unrelated edits; never merge. Ask before pushing unless the user already authorized it.

The Claude shell hook covers direct Git push and merge commands only when the host actually loads it; host support, aliases, indirect commands and other tools require separate verification. Do not claim comprehensive enforcement from the hook declaration.

For Codex on WSL/Linux in a Git project, activate the installed `python3 .aid/runtime/scripts/change/codex_hook_config.py install --project <git-root>` before work. The hook is project-wide, denies direct push and merge, and must be reviewed and trusted in Codex `/hooks` before it can protect a session. If activation, the required Git/Python tools, or trust cannot be established, stop and explain the missing step; existing user hook configuration is never overwritten. Windows and non-Git enforcement are unverified. Before removing AID, manually remove the AID hook entry from `.codex/hooks.json` so it does not point to a missing handler.

1. **Size:** a change to few files and one capability with no schema, security, data, dependency or public API change is direct. Otherwise use the planned lane in `references/planned.md`. When uncertain, use the planned lane.
2. **Tests first:** for a bug, write a reproducing test and prove it fails on the old code. For planned work, a different agent writes acceptance tests; wait for them and record the failing baseline before building. Check that failures are real assertions, not setup errors. For each relevant outcome, choose an observable positive check as well as failure checks where needed; for content and visual work use checks suited to the output. Disclose outcomes that could not be checked. Treat a required outcome without evidence as unverified; do not report the task complete.
3. **Build and check:** for a direct continuation of related active work, record progress in its existing `STATE.yml`; do not reuse unrelated, completed or canceled work. Execute in the foreground; wait for every helper you start. Run the project card's relevant build, test, lint and rule checks to completion. Capture existing failures and test counts before building, then compare afterwards using `.aid/runtime/scripts/change/checks.py`; disclose any unavailable check. Use `red-first.py` to test the old revision with new tests. For planned work, use `trace.py` and `state.py` as described in the planned lane.
   For new direct work, use the shared work-initiation gate to identify or allocate the work directory before authoring state. The newly allocated directory must be empty and exclusively owned by this operation; do not allow other writers into it during initialization. Initialize its state with `python3 .aid/runtime/scripts/change/state.py --init-work-dir <allocated-work-dir> --goal <goal>`. Use the writer's `Direct Next Step` and `Direct Evidence` pipeline fields to record the actual next action and evidence as work progresses. On resumption, check the recorded goal, next action, evidence and current files before acting; do not assume a check, review or approval happened or replay a failed operation. Respect completed, canceled, paused and blocked states before resuming.
   For a standalone `pipeline.path: direct` work, write state through `writeback-state.sh --pipeline` as events occur. Only after its whole goal and required checks and independent whole-result review have actually succeeded, record their evidence, set `Lifecycle` to `Completed`, and set `Active Skill` to `none`; never mark incomplete or unverified work complete or invent approval. When a real blocker prevents progress, set `Lifecycle` to `Blocked` and record its actual `Block Reason` and next step. When waiting for required user input, set `Lifecycle` to `Paused-Awaiting-Input` and record the actual `Pause Reason` and next step. On a valid continuation, record `Running` and the active skill before continuing. For a follow-up in a larger existing work, update that work's actual task and progress using its own lifecycle rules; never complete the broader work merely because the follow-up passed.
4. **Review against evidence:** for planned work, an independent reviewer checks the plan against the request before building, and the result against reality after each milestone. Apply `references/review.md`, including a whole-result review against the original request and repository. A finding blocks only when it cites a request it violates, a repository fact with its location, or a failing check. Record whether it changed the result; show other findings without repeated review loops.
5. **One fix round:** fix evidenced findings once, rerun affected checks and review the fixes. If a finding or check remains unresolved, stop and show the evidence. Do not report the work as complete or treat an unresolved defect as accepted.

For planned work, show the goal card and plan together for approval before building; show the finished result for approval. For direct work, report the result and checks. Respect existing authorization and any explicit spending limits. Do not conceal failed commands, unavailable evidence, or pre-existing failures.
