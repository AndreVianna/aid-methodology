# Step 2: lean AID (goal card for approval)

**Goal:** make small work fast and keep complex work on track, with results at least as good as a plain agent and less process than today's AID. Build the design in `DESIGN.md` alongside the current skills; keep the project card, relevant Knowledge Base context and independent review.

**Out of scope:** retiring existing skills, changing the benchmark's starting commit or grading away failures, deploying or merging. Retirement is a separate decision after results are shown.

| # | Acceptance criterion | Evidence |
|---|---|---|
| C1 | One `/aid-change` entry routes small work directly and larger or riskier work to a goal card and plan. Planned work gets at most two approvals: plan and result. | Routing behavior tests and benchmark transcripts, including approval counts. |
| C2 | Bugs get a failing test before the fix; planned work has acceptance tests written by a different agent. The build runs in the foreground and runs the relevant checks. | Behavior tests and ordered run evidence; record when a check cannot run. |
| C3 | `checks` records each starting failure and message and the number of tests run; it reports existing failures and blocks new failures, changed messages or fewer tests. `trace`, `red-first` and `state` enforce the contracts in `DESIGN.md`. | Behavior tests including passing, failing and missing-test cases. |
| C4 | An independent review checks the plan against the request, and the result against reality at milestones. It also checks the whole result against the original request and repository, including cross-page consistency and rendered output where relevant. Findings block only with the specified evidence; after one fix round, unresolved findings are shown to the user. | Review records cite the request, repository or failing check; site grade and blind review inspect the built result. |
| C5 | The entry skill is at most about 100 lines and its review brief at most about 60, held by a test. New rules respond to benchmark evidence and replace or remove something. | Line-budget test and recorded rationale for any new rule. |
| C6 | Fix, feature, tags and site benchmarks use the same scenarios, starting commits and graders as the comparisons, with a raw-table rendering check added to the site grader. Record correctness, cost, elapsed time, approvals, helper runs and interrupted or repeated work. | Saved results and transcripts; re-grade both existing site results with the updated grader. |
| C7 | Lean results are as good as or better than plain on hidden checks and blind review, with cost about 1.5–2 times plain. Show measured results and any misses; do not treat the target as already met. | Side-by-side benchmark report, with estimates distinguished from measured cost. |

**Plan:** (1) add the site raw-table check and re-grade existing results (C6); (2) build the entry skill, lane references, three agent roles and four scripts with behavior tests (C1–C5); (3) add lean mode to the measurement drivers and run the cheaper scenarios (C6–C7); (4) with separate approval for site-run spend, run and grade the site benchmark, review the whole result, and report all targets and misses (C4, C6–C7).

**Budget and safeguards:** keep the design and instructions short. No paid site benchmark starts until the maintainer sees its estimated cost and agrees; check that Claude CLI is installed and signed in before any benchmark. Preserve the old results and disclose unavailable checks. Stop and report a remaining evidenced defect after the one fix round; do not call it accepted.
