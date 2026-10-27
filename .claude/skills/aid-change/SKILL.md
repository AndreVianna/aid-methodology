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

Keep the request and the project card in view. Read relevant Knowledge Base documents and existing code before deciding what to change. Preserve unrelated edits; never merge. Ask before pushing unless the user already authorized it.

The Claude shell hook covers direct Git push and merge commands only when the host actually loads it; host support, aliases, indirect commands and other tools require separate verification. Do not claim comprehensive enforcement from the hook declaration.

1. **Size:** a change to few files and one capability with no schema, security, data, dependency or public API change is direct. Otherwise use the planned lane in `references/planned.md`. When uncertain, use the planned lane.
2. **Tests first:** for a bug, write a reproducing test and prove it fails on the old code. For planned work, a different agent writes acceptance tests; wait for them and record the failing baseline before building. Check that test failures are real assertions, not setup errors. For content and visual work, choose observable checks suitable for that work.
3. **Build and check:** execute in the foreground; wait for every helper you start. Run the project card's relevant build, test, lint and rule checks to completion. Capture existing failures and test counts before building, then compare afterwards using `.aid/runtime/scripts/change/checks.py`; disclose any unavailable check. Use `red-first.py` to test the old revision with new tests. For planned work, use `trace.py` and `state.py` as described in the planned lane.
4. **Review against evidence:** for planned work, an independent reviewer checks the plan against the request before building, and the result against reality after each milestone. Apply `references/review.md`, including a whole-result review against the original request and repository. A finding blocks only when it cites a request it violates, a repository fact with its location, or a failing check. Record whether it changed the result; show other findings without repeated review loops.
5. **One fix round:** fix evidenced findings once, rerun affected checks and review the fixes. If a finding or check remains unresolved, stop and show the evidence. Do not report the work as complete or treat an unresolved defect as accepted.

For planned work, show the goal card and plan together for approval before building; show the finished result for approval. For direct work, report the result and checks. Respect existing authorization and any explicit spending limits. Do not conceal failed commands, unavailable evidence, or pre-existing failures.
