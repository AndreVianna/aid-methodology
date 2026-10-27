# Work-004 (lean AID): handoff

Written 2026-10-27 for the next agent (Codex) to resume this work without the previous session's context. Read this
file first, then the files it points to. Everything named here is committed on branch `work-004` of
`github.com/andrevianna/aid-methodology`.

## 1. The goal

The maintainer's goal, unchanged since the start: **AID must become faster, cheaper and less bureaucratic**, while
keeping its three strengths:

1. **Brownfield context:** the Knowledge Base (`.aid/knowledge/`) gives agents the project's real constraints.
2. **Staying on track in complex work:** no drift, hallucination, gaps or over-engineering.
3. **Agents reviewing agents.**

The maintainer's fear, stated more than once: a lean process must not let real defects through ("slop, gaps,
drift"). Ignoring a failure must never mean accepting a defect. The answer is evidence over opinion (DESIGN.md).

## 2. Why work-003 was abandoned

Work-003 (branch `work-003`, kept, not merged) aimed to redesign AID: rename and merge skills, merge brainstorm and
describe, question whether "features" are needed, add verify/simplify loops, PR watching and KB automation. An
independent re-analysis (`DEFINITION.md` in this folder, approved as Q1) found it aimed at the wrong target:

- It reorganized names, phases and documents and added capabilities, but did not attack what makes a task slow and
  expensive: rules loaded twice, a huge always-loaded skill list (114 descriptions, 78 of them kind variants),
  helper fan-out (9-11 helper sessions for a one-line fix), documents for small work, review loops, and the rule
  that no step may ever be skipped.
- Its own plan was the problem in miniature: 367 tasks, 88 done; about 4 helper sessions and 4 commits per task;
  `rules.md` grew from 115 to 237 lines during the work; about 120k lines of work-folder text for about 9.5k lines of
  product change.
- Its tests mostly grepped instruction wording, which proves nothing about behaviour.
- A typed `/aid-fix` on a planted one-line bug ran over 31 minutes, cost about $24 and changed no code; the plain
  request fixed it in 30 seconds for $0.22 (`measurements.md`).

Decision (Q2, answered 1): start fresh from `master` in a new, small work (this one), leaving work-003 on its branch.
DEFINITION.md § 5 lists the parts of work-003 worth porting later (plain-language routing, the question form,
banner removal, retired agents); none has been ported yet, and that is not part of the next step.

Note: the main checkout's root `CLAUDE.md`/`AGENTS.md` on branch `work-003` describe work-003's process
(`/aid-orchestrate` and so on). Branch `work-004` is based on `master`, where that skill is `/aid-triage`.

## 3. What work-004 has done

### Step 1: foundation (done, approved as Q10)

Goal card: `STEP-1.md`. Results in `measurements.md`.

- Rules loaded once (the project notes import them; the second ordered read is gone); `rules.md` cut to about 60
  lines, every dropped rule moved or justified in `rules-inventory.md`.
- A one-page project card template plus this repo's own card (`.aid/knowledge/PROJECT.md`), always loaded; the installer imports it only when the
  file exists, in both installer twins.
- 112 skills folded to 37: the 75 kind variants (`/aid-create-api` and so on) became family skills with the kind as
  first argument (`/aid-create api`). Source: `canonical/aid/templates/shortcut-catalog.yml` (`kind_of` on 75 rows),
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`, kind texts moved to
  `canonical/skills/<family>/references/<kind>.md`. Test `tests/canonical/test-lean-rules-card.sh` LR09 holds the skill list at 40
  skills or fewer, 300 characters per description, 6,000 characters in total.
- Measured: AID adds +24% start context over plain (goal +25%, from +85%/+140%); 12 of 12 hidden checks pass.
- Hook-based push/merge protection (old C7) was moved out: master's installer has no hook support (Q7).

### Measurement harness (built in this work, keep using it)

| File | What it does |
|---|---|
| `tests/measure/measure.py` | Small scenarios (fix, feature, complex tags task) on a fixture with a planted bug; with and without AID; hidden checks; `--report` medians; start-context tokens |
| `tests/measure/repo_task.py` | The brownfield benchmark: clones this repo at a commit, strips AID for the plain run, drives `claude -p` turns (fixed reply to questions, sends next-phase commands, "go on" otherwise), records cost and turns; `--resume SESSION --cwd DIR`, `--max-cost` |
| `tests/measure/hidden/check_*.py` | Hidden graders; `check_site.py` grades a reworked site: build, stale/unknown `/aid-*` names, broken links, axe accessibility scan (needs Playwright and `AXE_JS`), machinery line counts, screenshots |

Harness lessons, all already fixed in the code:

- `total_cost_usd` is the session's running total; never sum it across resumed turns.
- AID hands work to background helpers and ends its turn; in a headless run the helpers die. The "go on" message tells
  it to wait for its helpers; it only partly complies. A killed turn reports no cost: price from transcript tokens.
- The per-turn limit is `AID_MEASURE_TIMEOUT` (AID turns can run for hours).
- A run is finished when a "go on" turn makes no tool call, or the same closing message repeats three times (AID
  ends asking "merge or PR?", which the driver otherwise answers forever).
- `child_env()` strips the parent session's identity variables from child runs.
- Grader: wait 300 ms after load before the axe scan (code blocks get focus from a script), skip redirect pages, do
  not count file names as commands. **Known gap:** it does not detect markdown tables rendered as raw text
  (`| --- |` in the HTML); add that check before the next site run.

### The complex-task evidence

1. **Tags task** (`measure.py`, complex scenario): plain $0.08 and 23 s; today's AID full pipeline $4.31 and 17 min,
   8 user replies, 13 helpers, 34 state writes; both 12/12 correct.
2. **Site rework** (Q13: run it twice from the same commit, plain and full AID, grade both). Request text is in
   `repo_task.py` `TASKS["site"]`. Notes: `site-run-notes.md` (timeline, red tape, execute stats, grades, both blind
   reviews, conclusion). Planning analysis: `site-run-analysis-planning.md`. Grades: `site-results/`. The two built
   sites are pushed as branches `work-004-site-plain` (AID stripped, as the plain run had it) and
   `work-004-site-aid` (the AID run's worktree branch, with its whole work folder).

| | Plain | Today's AID |
|---|---|---|
| Cost / time | about $11.50 / 25 min | about $176 (reported $135, ceiling $314) / about 10.5 h |
| Look | real redesign | old look, cleaned up |
| Visible defects | 42 markdown tables shown as raw text on 11 pages | none |
| Accuracy (blind, 8 topics against the repo) | 223 claims, 3 stale (copied from the repo's own old docs) | 193 claims, 0 wrong; it corrected that old text |
| Completeness | full skill pages | skill pages cut to header facts (a cut its plan invented) |
| Blind verdicts | content: slightly better | design: slightly better |

Conclusion: quality is a tie at 15 times the cost. AID's extra cost bought two cheap things: checks of the built
result and claims checked against the repo. Its plan (about $84, 98 findings of which about 5 mattered, 49 tasks)
caused the drift: invented cuts and the lost "modern look". Plain plus two checks would most likely beat both.

## 4. The design for the next step

`DESIGN.md` (53 lines; keep it that short). In brief:

- One entry skill, `/aid-change`, with five rules: size the work (planned work gets a goal card and a plan, one
  approval); tests first, by a different agent; build in the foreground, then run `checks`; a finding blocks only
  with proof (a request line, a repo fact with file and line, or a failing check); one fix round, then stop and show
  the user.
- Four scripts: `checks` (baseline of failing tests, messages and tests run; blocks on new failures, changed messages
  or fewer tests run; reports pre-existing failures every time), `trace` (criteria to tasks and back), `red-first`
  (new tests must fail on the old code), `state` (one small state file, one call).
- Review at two points only: plan against request, and result against reality after each milestone.
- Budget: `/aid-change` about 100 lines, its review brief about 60, held by a test. New rules only on benchmark
  evidence, and each replaces something.
- Targets: hidden checks as good or better than plain; about 1.5 to 2 times plain cost; at most two approvals.

## 5. Where it stands now

- `STATE.yml`: lifecycle Running; questions are recorded by hand in its `qa:` list (master's writer script has no
  `--ask`). Q12 is superseded by Q14 (it asked the step order before the site evidence existed).
- **Q14 is Pending and must be answered by the maintainer before anything is built.** Its text: build the lean design
  as one entry skill (`aid-change`) with lane references, three agents (builder, test writer, reviewer) and scripts
  for the mechanics, reviews at two checkpoints with the proof rule, beside today's skills, proven on the tags and site
  benchmarks before the old phase skills retire. Recommended answer: approve, build as one step (old steps 2 and 3
  together). The last offer also listed: approve, but first run a cheap test (plain plus the two checks on the site
  task, about $20) to confirm the gain before building.
- `STEP-2.md` is a draft goal card for the old step 2 (direct lane only); if Q14 is approved, replace it with one goal
  card for the whole `/aid-change` build.

## 6. Next steps, in order

1. Ask Q14 again, with its recorded text (do not record it twice), and record the answer in `STATE.yml`.
2. If approved, write the goal card (`STEP-2.md`, replacing the draft): criteria tied to the targets in § 4, the line
   budgets, and the benchmark runs that prove it. Get one approval.
3. Add the raw-table check to `tests/measure/hidden/check_site.py` and re-grade both site branches with it.
4. Build beside today's skills, in `canonical/` (source of truth; host copies under `profiles/` and `.claude/` are
   generated, see `CONTRIBUTING.md` and `/generate-profile`):
   - `canonical/skills/aid-change/SKILL.md` plus `references/planned.md` and `references/review.md`;
   - three agents (builder, test writer, reviewer), reusing today's agent files where they fit;
   - the four scripts with unit tests (behaviour, not wording);
   - a size test that holds the line budgets.
5. Teach `repo_task.py` and `measure.py` a lean mode (start with `/aid-change` instead of `/aid-describe`).
6. Run the benchmarks: the fix and feature scenarios, the tags task, and the site rework from the same commit as the
   other two site runs. Grade with the same graders plus a blind review. Record every result in `measurements.md` and
   `site-run-notes.md`.
7. Show the maintainer the result against the targets. Only after approval retire the old phase skills (about 37 to
   15 skills) in a separate step.

## 7. Rules to keep while working

- Commit on `work-004` and push there. Never merge; the maintainer merges.
- Record every state change and every question in `STATE.yml` before showing it; questions use the form in
  `.aid/runtime/templates/question-protocol.md` (one question per message, subject line with importance, why I ask,
  recommendation, options).
- Never name a work id or work-folder path in `.aid/knowledge/**`.
- Each benchmark run of the site task costs real money (plain about $12; today's AID about $176): say the estimate
  and get a yes before starting one.
- The maintainer prefers plain, short messages, tables and lists, and options with a recommendation.
