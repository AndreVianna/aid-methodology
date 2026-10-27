# Planned work

Write one short goal card and plan: the user's goal, exclusions, testable criteria, milestones with tasks tied to criteria, and a budget. Ask an independent reviewer to check the plan against the original request before presenting the card and plan together for approval. Do not build until approved.

Use `.aid/runtime/scripts/change/trace.py --file plan.json` with `criteria` as a list of criterion IDs and `tasks` as objects with unique `id` and a nonempty `criteria` list. Resolve missing, unknown or unlinked items before building.

Ask a different agent to write acceptance tests; wait for it. Use `red-first.py --repo DIR --revision REV --tests DIR --junit REPORT -- COMMAND...` to prove each new test fails on the old revision in a disposable checkout. The test directory is overlaid in that checkout by its basename; use a report path relative to the checkout and select only the new tests. A missing report, setup error or passing test is not red evidence.

Keep one small state object with goal, checklist, milestones, decisions and budget used. Write it atomically with `state.py --file FILE --data JSON`; keep evidence and approvals available to the user. Capture the checks baseline on the starting commit with `checks.py baseline --spec FILE --baseline FILE`, then use `compare` after changes. The spec is JSON with `commands`, each containing a unique `name`, an `argv` array and, for tests, a `junit` report path. Run commands from the project root; never overwrite the original baseline. Untracked and ignored files must be absent or listed explicitly under `allowed_untracked` and hashed; use a clean checkout to avoid inventorying unrelated dependencies. If a test cannot produce usable JUnit evidence, disclose it and do not claim its count was verified.

Work through milestones in the foreground. At each milestone run the checks and request the independent result review in `review.md`. At the end review the whole result and show the user the outcome, evidence, pre-existing failures and unresolved issues for approval.
