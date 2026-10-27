You are taking over an in-progress piece of work on the AID methodology repository
(github.com/andrevianna/aid-methodology). The previous agent (Claude Code) ran out of usage. Resume the work from
where it stopped.

SETUP
1. Check out branch `work-004` (git fetch origin work-004 && git checkout work-004). Work and commit only on this
   branch, and push only to it. Never merge anything: the maintainer merges.
2. Read, in this order:
   - `.aid/works/work-004-lean-aid/HANDOFF.md` (the full handoff: goal, history, evidence, current state, next steps)
   - `.aid/works/work-004-lean-aid/DESIGN.md` (the lean design to build; 53 lines)
   - `.aid/works/work-004-lean-aid/STATE.yml` (the work's state and its question records, `qa:`)
   - `.aid/works/work-004-lean-aid/site-run-notes.md` and `measurements.md` (the evidence)
   - `AGENTS.md`, `.aid/runtime/rules.md` and `.aid/knowledge/PROJECT.md` (project rules and card)

WHY THE PREVIOUS WORK WAS ABANDONED
The maintainer's goal is to make AID faster, cheaper and less bureaucratic, while keeping its three strengths: the
Knowledge Base as brownfield context, keeping complex work on track (no drift, hallucination, gaps or
over-engineering), and agents reviewing agents. Work-003 (branch `work-003`, kept, not merged) tried to redesign AID
by renaming and merging skills and adding new loops. An independent re-analysis (`DEFINITION.md`) showed it aimed at
the wrong target: it never cut what makes AID slow and expensive (rules loaded twice, a huge skill list, 9-11 helper
agents for a one-line fix, documents for small work, review loops, a rule that no step may be skipped), and its own
plan had 367 tasks with 4 helper sessions per task while the rules grew. A typed `/aid-fix` on a one-line bug took
over 31 minutes and about $24 and changed no code; plain Claude fixed it in 30 seconds for $0.22. The maintainer
approved starting fresh from master in a new small work, work-004.

WHAT WORK-004 HAS DONE
- Step 1 (done, approved): rules loaded once and cut to 58 lines, a project card, and 112 skills folded to 37 (kind
  variants became an argument: `/aid-create api`). AID now adds +24% start context instead of +85-140%; all hidden
  checks pass.
- A measurement harness in `tests/measure/` (scenarios, a brownfield benchmark driver `repo_task.py`, hidden graders).
- Two complex-task benchmarks, plain Claude against today's full AID pipeline:
  - a tags feature: both correct; plain $0.08 and 23 s, AID $4.31 and 17 min.
  - a full rework of the product site `site/`: plain about $11.50 and 25 min, AID about $176 and 10.5 h. Two blind
    reviews called quality a tie: AID had no broken rendering and fixed stale facts (because it checked the built
    result and checked claims against the repo), but its plan invented cuts (skill pages reduced to stubs) and lost
    the "modern look" the request asked for; plain made a real redesign but left 42 tables rendering as raw text and
    copied 3 stale facts. Conclusion: AID's cost bought two cheap checks; its long planning caused the drift.
  - The built sites are on branches `work-004-site-plain` and `work-004-site-aid`.

WHAT WE ARE DOING NOW
Building "lean AID" from DESIGN.md: one entry skill `/aid-change` (about 100 lines) with five rules (size the work;
tests first by a different agent; build in the foreground then run the checks; a finding blocks only with proof: a
request line, a repo fact with file and line, or a failing check; one fix round, then stop and show the user), four
scripts (`checks` with an exact failing-test baseline, `trace`, `red-first`, `state`), and review at only two points:
plan against request, and result against reality. Targets: results as good or better than plain, about 1.5 to 2
times plain cost, at most two approvals for planned work. New rules are added only on benchmark evidence, and each
replaces something.

WHAT STAGE WE ARE AT
Paused on Q14 in STATE.yml, which is Pending. It asks the maintainer to approve building this lean design (one
entry skill `aid-change` with lane references, three agents: builder, test writer and reviewer, scripts for the
mechanics, two review checkpoints with the proof rule), beside today's skills, proven on the tags and site
benchmarks before the old phase skills retire. Q12 is superseded; do not ask it.

NEXT STEPS
1. Ask Q14 again with its recorded text, in the question form of `.aid/runtime/templates/question-protocol.md`
   (subject line with importance, the question, "Why I ask", "My recommendation", numbered options, closing line).
   Recommended answer: approve and build it as one step beside the current skills. The alternative offered: first
   run a cheap test, plain plus the two checks on the site task (about $20), before building. Record the answer in
   STATE.yml (`qa:` entry Q14: state, answer) before acting on it. Do not build anything before the answer.
2. If approved: replace the draft `STEP-2.md` with one goal card for the whole build (criteria tied to the targets,
   the line budgets, the benchmark runs that prove it) and get one approval.
3. Add a check for markdown tables rendered as raw text to `tests/measure/hidden/check_site.py`; re-grade both site
   branches with it.
4. Build in `canonical/` (the source of truth; host copies are generated, see CONTRIBUTING.md):
   `canonical/skills/aid-change/SKILL.md` with `references/planned.md` and `references/review.md`, the three agents,
   the four scripts with behaviour tests (not wording greps), and a test that holds the line budgets.
5. Add a lean mode to `tests/measure/repo_task.py` and `measure.py` (start with `/aid-change`).
6. Run the benchmarks (fix, feature, tags, site from the same commit as the earlier site runs), grade them with the
   same graders plus a blind review, and record the results. Each site run costs real money: state the estimate and
   get the maintainer's yes before starting one.
7. Report against the targets. Retiring the old phase skills (about 37 to 15) is a later, separate step, only after
   the maintainer approves the result.

HOW TO WORK WITH THE MAINTAINER
- Record every state change and every question in STATE.yml before you show it (the writer script on this branch has
  no `--ask`; edit the `qa:` list directly, as earlier entries do).
- One question per message. Plain, short sentences; tables and lists; at most three options, with your
  recommendation and why.
- Never name a work id or work-folder path inside `.aid/knowledge/`.
- Keep DESIGN.md and the new skill short: the maintainer explicitly rejected a design that grows as complex as
  today's AID.
- Commit with clear messages and push to `work-004` after each meaningful step.
