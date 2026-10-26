# Delivery gate brief (per delivery, clean-context reviewer)

Working directory (git worktree on branch `work-005`; stay inside it):
/tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework

You run the DELIVERY-LEVEL quality gate for the delivery named in your prompt: a full review of everything its tasks produced. You are a reviewer: you list issues and DO NOT FIX anything. You may run commands (including `npm ci`, `npm run build`, `npm test`, `node` checks) in `site/` to prove the gate criteria; you may not change tracked files (build output in `site/dist` and `node_modules` are ignored/untracked and fine; remove nothing else). No network except the npm registry for `npm ci`.

## Read
- The delivery's stanza in `.aid/works/work-005-site-rework/PLAN.md` (`### delivery-NNN`): Objective, Scope, Notes and the **Gate Criteria** list; they are the delivery-level acceptance criteria.
- Every task's `DETAIL.md` in `.aid/works/work-005-site-rework/deliveries/delivery-NNN/tasks/` and its `STATE.yml` (all must be `Done`; quick-check findings listed there).
- The feature sections of `.aid/works/work-005-site-rework/REQUIREMENTS.md` section 11 that this delivery claims (the specs), and the `AC-N` entries in section 9 that the gate criteria cite.
- The delivery diff: `git diff --stat <base>...HEAD` where `<base>` is the commit just before the delivery's first task commit (find it with `git log --oneline`), and the changed files themselves.
- `.aid/works/work-005-site-rework/delivery-NNN-issues.md` if it exists (deferred HIGH findings from quick checks).
- `.aid/runtime/templates/grading-rubric.md`, and via `.aid/knowledge/INDEX.md` the KB documents you need (coding-standards, test-landscape, authoring-conventions, quality-gates).

## Do
1. RUN every Gate Criterion command of the delivery's stanza (and the standing items: all tasks Done; the mechanical quality gates the stanza lists). Record command, expected, actual. A criterion you could not run is a finding (MEDIUM) unless it needs something outside this sandbox (a browser, a remote): then record it as `OOS-not-run` with the reason and do not count it against the grade.
2. Check cross-task coherence: names, paths, imports, the order rules of PLAN.md Notes, no leftover placeholders, no duplicated statements of one fact, content true to the repository (spot-check statements against `canonical/` and the repo), nothing outside the AC-13 allowed paths (`git diff --name-only site-aid...HEAD` lists only `site/**`, `.github/workflows/docs.yml`, `.aid/knowledge/**` documents the audit lists, and `.aid/works/work-005-site-rework/**`), no deploy/publish/push/tag.
3. Review the deferred HIGH issues of `delivery-NNN-issues.md`.
4. `select-suites.sh --since site-aid --run` may show failures in suites unrelated to this work (for example dashboard CLI tests). For any failing suite, decide with evidence whether the delivery diff can affect it (which files it tests vs `git diff --name-only`); if the diff cannot reach it, record one `OOS` row naming the suite, the evidence and "pre-existing/environmental"; if it can, record a finding.
5. Produce ONE fresh severity-tagged ledger of ALL issues, every severity `CRITICAL|HIGH|MEDIUM|LOW|MINOR`, each with its source tag (CODE | TASK | SPEC | KB), at the ledger path in your prompt: ONE markdown table, 7 columns, no narrative, per `.aid/runtime/templates/reviewer-ledger-schema.md`; Status `Pending` (or `OOS`). If the ledger already exists: read it, for each existing row verify on disk and set Fixed / Recurred, append new findings as Pending.
6. Run `bash .aid/runtime/scripts/grade.sh <ledger>` and return: the grade; counts by severity (open rows); one line per open row of MEDIUM or higher with its source tag; the table of gate criteria (command -> actual -> pass/fail/not-run); the OOS rows.
Never edit tasks, PLAN.md, REQUIREMENTS.md, STATE files, or any tracked file.
