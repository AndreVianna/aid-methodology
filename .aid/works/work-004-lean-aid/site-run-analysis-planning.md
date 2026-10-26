# Site rework benchmark: what AID's planning phase cost and what it produced

Scope: the AID run from the first user turn (18:09:33 UTC) to the start of `/aid-execute` (22:11:50 UTC).
Sources (all under the scratchpad folder, "S"):
- the main transcript, `.../work-005-site-rework/eeb5954d-....jsonl` (called "main" below);
- the 42 helper transcripts in its `subagents/` folder (called "agents" below);
- the work folder `.../.aid/works/work-005-site-rework/` (called "W" below);
- the driver logs `site-aid.err`, `site-aid.json`, `site-aid2-part1.err` and `site-aid2-part1.json`.

How cost was worked out: the driver's running `total_cost_usd` is the reference figure. It was $86.81 at 22:37:23, a point
that also includes execute tasks 001 to 003 (about $2.50 by token estimate). That leaves about **$84 for planning**,
not $65. The $65 figure was the reading at 21:40, before the detail reviews and fixes. Per-phase splits use the driver
reading at each turn boundary. Inside a turn, the split follows each helper's tokens (from the JSONL `usage` fields,
priced at $3/$15/$0.30/$3.75 per million tokens for input, output, cache read and cache write).

## 1. Timeline by phase

| Phase | Wall clock (UTC) | Helpers dispatched | Cost (≈) | Documents produced |
|---|---|---|---|---|
| Describe | 18:09:33-18:13:30 (4 min) | none | $0.75 | REQUIREMENTS.md §1-10: 130 lines, 2,094 words |
| Define | 18:13:37-18:19:40 (6 min) | 2 reviewers | $1.17 | §11: 6 feature stubs, plus FR-12 and AC-15 added after review |
| Specify | 18:19:48-19:25:50 (66 min) | 11 architects, 6 reviewers | $37 | §11 specs: 2,545 lines, 25,821 words; site-audit.md: 199 lines |
| Plan | 19:25:50-19:41:22 (16 min) | 2 architects, 2 reviewers | $5 | PLAN.md: 429 lines, 4,632 words; 4 delivery STATE.yml files of 88 lines each |
| Detail | 19:41:23-22:11:48 (2 h 30 min, including a 49-min usage-limit pause) | 11 architects, 8 reviewers | $40 | 49 DETAIL.md files: 5,202 lines, 56,776 words, 636 acceptance criteria; 49 task STATE.yml files: 3,871 lines |
| **Total** | **4 h 02 min (3 h 13 min of active time)** | **42 helpers (24 architect runs, 18 reviewer runs) + 3 resumes** | **≈ $84** | **≈ 89,000 words of planning text** |

- Usage: helpers produced 85% of the token-estimated spend. Planning used 1.78 M output tokens and 188 M cache-read tokens.
- Comparison: the plain run did the whole job in 25 min for $11.52 (`site-plain.json`). AID's planning alone cost 7.3 times that.
- Driver cost readings: $2.14 at the end of Define (turn 8); $35.85 at 19:17 in the middle of Specify (turn 11); $46.43 at 19:51
  (turn 12); $55.92 when the usage limit hit (turn 15); $64.52 at 21:40; $86.81 at 22:37 (`site-aid.err`, `site-aid2-part1.err`).

**Where the helper money went** (token estimate, planning helpers only):

| Role | Runs | Share |
|---|---|---|
| Writers whose run was cut off mid-way | 10 | 35% |
| Writers that finished normally | 6 | 17% |
| Reviewers | 18 | 28% |
| Fixers (one of them was cut off) | 8 | 20% |

**Cut-off runs.** Eleven helper runs were still going in the background when the main agent ended its turn, and the
next turn found them stopped. Main says: "The architect agent stopped before it finished... Nothing was saved."
(18:33) and "The task writer was cut off... Nothing was saved." (19:51). The spec writers ran three times: first 1
agent, then 3, then 4. At least 8% of helper spend produced nothing at all, and up to about 20% was redone.

## 2. Review cycles

The bar is a minimum grade of A, and a single MEDIUM finding drops a review to C+. Severity counts below are the rows
each review added, read from the ledger tables in the reviewer transcripts.

| Review | Cycle 1 grade | Cycle 1 findings (H/M/L/minor) | Cycle 2 grade | New in cycle 2 | Closed by |
|---|---|---|---|---|---|
| Define cross-reference | D+ | 1 / 6 / 5 / 0 | A | 0 / 0 / 0 / 2 | orchestrator fix, no third review |
| Specify 001+002 | C | 0 / 2 / 5 / 0 | A+ | none | |
| Specify 003+004 | D+ | 1 / 6 / 5 / 0 | B+ | 0 / 0 / 1 / 1 | fixer, then "I'll check them myself" |
| Specify 005+006 | D | 2 / 6 / 5 / 1 | A+ | none | |
| Plan | D+ | 1 / 2 / 6 / 1 | B+ | 0 / 0 / 1 / 0 | orchestrator fix, A+ self-declared |
| Detail delivery 1 | B | 0 / 0 / 4 / 0 | A+ | none | |
| Detail delivery 2 | D+ | 1 / 4 / 5 / 3 | A | 1 minor came back | accepted |
| Detail delivery 3 | C+ | 0 / 1 / 5 / 3 | C+ | 0 / 1 / 0 / 0 | orchestrator fix, A+ self-declared |
| Detail delivery 4 | C | 0 / 3 / 7 / 0 | C+ | 0 / 1 / 0 / 0 | orchestrator fix, A+ self-declared |

Totals:
- **98 findings**: 91 in cycle 1 and 7 new ones in cycle 2.
- **18 review runs and 8 fix runs.**
- **Every cycle-1 review except one failed the bar.** The exception was detail delivery 1, which got a B and still needed a second cycle.
- **Three defects were reported twice**, because reviewers worked on pairs of features: `.md` versus `.mdx`
  (Specify 001+002 row 1 and Specify 003+004 row 4); who removes Mermaid (003+004 row 5 and 005+006 row 2); and the B5 grep
  (003+004 row 7 and 005+006 row 4).

### What the findings were

| Type | Count | Changes the site the user gets? |
|---|---|---|
| C. Acceptance command or budget that AID wrote itself and that could not run, could never pass, or proved nothing | 25 | No |
| P. Process, state, ordering or task-size bookkeeping | 22 | No |
| I. Contradiction between AID's own documents | 17 | No (each would surface at build or test time) |
| M. Missing coverage or check | 15 | 3 yes |
| W. Wording, format or traceability | 11 | No |
| R. Wrong claim about the repo or a tool, invented by a writer | 8 | 2 yes |

Examples of each type (row numbers refer to the ledger tables extracted from the reviewer transcripts):

- **C, self-made checks that fail.**
  - Detail d4 row 1: "about 15 acceptance commands put markdown-escaped backticks inside bash single quotes".
  - Detail d2 row 1: "ls sorts `agents.mdx` before `aid-and-sdd.mdx`... the criterion fails on a correct split".
  - Specify 003+004 row 11: "`tokens.css` is capped at 110 lines, but the spec's own content is ... 112 before any comment".
- **P, bookkeeping.**
  - Plan row 3: "`git status --porcelain` prints nothing cannot reliably pass at gate time: `aid-execute` writes task and delivery `STATE.yml`".
  - Detail d2 row 2 (HIGH): the criterion runs `grade.sh` on a ledger that "is created by the delivery-gate reviewer after every task is Done".
  - Detail d4 row 10: one task "is at the edge of one session".
- **I, AID contradicting itself.**
  - Specify 005+006 row 1 (HIGH): the final `package.json` "keeps `@fontsource/inter` and lists no `axe-core`... while Feature 004 removes" it.
  - Specify 001+002 row 1: Feature 001 names pages `.md` that Feature 003 creates as `.mdx`.
  - Define row 1 (HIGH): "AC-5 says `npm test` runs only the four groups... AC-8 ... AC-10" need other tests.
- **M, missing coverage.**
  - Define row 7: no feature owned "moving `docs/` content into `site/`" or replacing the release-data fetch.
  - Detail d2 row 5: no task checks diagrams D9 and D10 "against their cited sources".
  - Specify 003+004 row 10: the drawing rules "have no check that can fail".
- **W, wording and format.**
  - Specify 003+004 cycle 2 row 13: "The spec still cites places by bare `file:LINE`".
  - Detail d3 row 8: "Type is IMPLEMENT for a deletion-only change while task-030 ... as REFACTOR".
  - Detail d4 row 7: Source "lists AC-2, AC-3, AC-8 and AC-12, which ... gives to features 002, 001 and 003".
- **R, invented facts.**
  - Specify 003+004 row 6: the spec planned to publish "a reviewer never runs on a smaller tier", but "the repo disagrees".
  - Detail d2 row 3: "Starlight adds a heading anchor link... to every heading".
  - Specify 005+006 row 6: the `mailto:` form shows "AID:+request+for+a+conversation".

**Which findings mattered for the user.** About **5 of 98 (5%)** would have changed the site the user receives:
- the unowned `docs/` move and changelog source (Define row 7);
- the false statement about reviewer tiers on a public page (Specify 003+004 row 6);
- the garbled `mailto:` subject (Specify 005+006 row 6);
- the unverified wording of two diagrams (Detail d2 row 5);
- text that would have been deleted before it was moved (Detail d2 row 6).

A sixth finding, the missing `readFileSync` import (005+006 row 3), was a real bug, but the first build would have caught it.

The other ~93 findings only repaired AID's own paperwork. Most of them (C + I + P = 64) are flaws in text that AID's
own process asked for: acceptance commands it chose to write, budgets it invented (300 lines, 110 lines, 150 KB, 60%),
and cross-feature ownership that exists only because the work was split into six features and 49 tasks. Main said as
much after the first review: "All 13 findings are gaps in my own draft, not in your intent." (18:17:22)

## 3. Red tape and redundancy

**The same facts, restated.** Verbatim 6-word overlap between layers is low: 5% of PLAN.md repeats the specs, and 6% of
the DETAILs repeat the specs or the plan. The writers paraphrase, so the restatement is semantic rather than copied.
Counting facts makes it visible:
- The scope and "no tag" check of AC-13 appears in **49 of 49** DETAILs, in 110 lines. It is also in REQUIREMENTS, 3
  spec sections and 5 places in PLAN.
- **48 of 49** DETAILs re-run the two KB lints. **44 of 49** run a full `npm run build`.
- 28 DETAILs repeat a "Not in this task (binding): no deploy, no publish, no push..." paragraph.
- 42% of all 6-word phrases in the DETAILs appear in more than one task. Reviewer d2 row 11: "The ~20-line shared check
  block is copied into eleven tasks and already disagrees with itself".
- Each DETAIL opens with the same 12-line "Execution protocol" block (588 lines in all). It restates a rule that CLAUDE.md
  already loads every session.
- **Judgement:** about 40-45% of the DETAIL text restates something written elsewhere (the shared phrases, plus the
  repeated scope, build and lint criteria). The specs (25.8k words) are restated again in tasks (56.8k words) that
  quote spec step numbers back ("Feature 005 § Feature Flow step 1").

**Boilerplate nobody reads.**
- Task STATE.yml files: 3,332 of their 3,871 lines (86%) are template comments copied 49 times. The four delivery
  STATE.yml files carry 300 comment lines, and the work STATE.yml carries 194.
- `review-cost.tsv` holds one data row, `cross-ref 1 ... 0` (surface_bytes 0). The meter was started and then never recorded a cycle.
- The 10 planning briefs (193 lines) exist only to hand context to helpers that then re-read the 2,500-line REQUIREMENTS.md.

**Task granularity.** task-001 is "replace the `scripts` block of `site/package.json`". Its DETAIL is 60 lines with 8
criteria, including a full `npm ci && npm run build`. The 49 tasks break down as 18 DOCUMENT, 13 IMPLEMENT, 10 TEST,
6 CONFIGURE and 2 REFACTOR.

**State and gate calls.**
- 82 calls to `writeback-state.sh` (34 in main, 48 in helpers) and 64 calls to `grade.sh` (14 in main, 50 in helpers).
- 131 tool errors (14 in main, 117 in helpers).
- In main, the state writer failed twice before it worked ("It reads `AID_STATE_FILE`, not `AID_WORK_DIR`", 18:13:20).
  The setup script assumed a `master` branch (18:10:06). Main also wrote and deleted three stray brief files (21:43-21:44).

**Approvals.**
- AID asked 6 questions before the driver said "Go on with the next step until the work is finished" (18:20:43):
  1. new work or not;
  2. approve the requirements, asked twice;
  3. approve the features, asked twice;
  4. three design choices for Feature 002.
- Every reply was "Take your recommendation", so the approvals carried no information.
- Describe asked no interview questions: "I filled the whole interview myself instead of asking many questions." (18:12:27)

## 4. Cohesion with the original request

**Followed the request.** FR-1 (audit every page), FR-3 (accessible diagrams), FR-4 (modern look), FR-5 (keyboard and
screen-reader support), FR-6 (every level), FR-7 and FR-8 (simplify generators and tests) and "nothing deployed" all
trace directly to the task text.

**Invented by Describe (the user never saw these; the reviews then polished them):**
- Hard numbers: the facts script must be "at most 300 lines" (FR-2); machinery "smaller ... by at least 60%" (NFR-3,
  AC-4); "at most 150 KB" per page (NFR-2, AC-15); exactly "four groups" of tests (FR-8); screenshots at 320 px and
  1280 px (AC-11).
- FR-12 removes the network fetch, so the changelog page "shows the version from the `VERSION` file and links to the
  GitHub Releases page". That is a visible feature cut nobody asked for. Define then added it as a Must.
- Through Specify, NFR-2 ("no client-side JavaScript...") led to "Copy buttons on code blocks are off", "Plain headings
  replace tabs on four pages" and "System fonts replace Inter" (main, 18:56:20). These are design removals justified by an
  invented budget.

**Scope creep:**
- FR-10 and the cross-ref fix widened the work to "any other KB document whose site statement becomes false", adding
  three KB documents and their lints (delivery 4).
- Feature 006, "Workflow, KB entry and safety", turns "do not deploy" into a whole feature plus a scope check in every
  task. Its "never pushed" proof uses the network (`git ls-remote`), which main flagged as an open question (21:44:34).
- A 199-line audit file with baseline figures, a keyboard table and a screenshot table.

**Weakened or missing:**
- Skill pages become "Facts only" (Feature 002 decision A, 18:20:34), and the 37 per-skill flow diagrams are deleted
  rather than redrawn.
- The page audit itself, the core of "check every page", is not done in planning. site-audit.md still has 87 `pending`
  cells, and the audit is pushed into 11 DOCUMENT tasks.

**"Simplify the machinery":**
- Partly respected. One generator replaces four, and the old flow engine and tests are deleted.
- But delivery 4's "lean tests" are 4 test files plus a helper (`facts`, `a11y`, `contrast` and `dist.mjs`) with about
  40 named checks (T1-T11, S1-S9, U1-U7, W1-W4, A1, K1-K5, C1-C5).
- They add two dev dependencies, `axe-core` 4.14.0 and `jsdom` 29.1.1. FR-11 itself had listed `jsdom` as something to remove.
- The plain run ended with 1 script and 2 test files (`site/scripts/generate.mjs`, `site/tests/{dist,generate}.test.mjs`).

**Verdict:** the plan is faithful to the headline goals. About a third of its content (the numeric budgets, FR-12, KB
widening, Feature 006 and the per-task safety proofs) comes from AID itself, not from the user. Most review effort went
into making that self-added content internally consistent.

## 5. Conclusions for a leaner process

1. **Only a few steps produced value the end result depends on.**
   - The code-reading done in Specify: for example, "the old `prebuild` step overwrites the pages the new script writes"
     (18:52:10), and that diagram pages must be `.mdx`.
   - About 5 review findings.
   - That is roughly the first spec pass plus one cross-check. A single plan document of a few hundred lines would have
     carried it, at perhaps a tenth of the $84.
2. **Executable acceptance criteria are the biggest source of review churn.** 25 of 98 findings were commands AID
   wrote that could not run or pass, and 22 more were state and gate bookkeeping. Let the executor build and test
   against a short list of observable outcomes, and drop per-task shell-command criteria and invented numeric budgets.
3. **Splitting into 6 features, 4 deliveries and 49 tasks created most of the contradictions it then paid to review.**
   17 findings were cross-document conflicts, and 3 were reported twice by parallel reviewers. For a single-surface job
   like this, use one feature, one delivery and a handful of tasks, and reserve deep decomposition for work that is truly multi-part.
4. **Run one review per phase, on content only, with a pass bar that tolerates LOW and MINOR findings.**
   - Eighteen review runs and eight fix runs cost about 48% of helper spend.
   - Requiring A, where one MEDIUM means C+, forced a second cycle almost everywhere. Then the orchestrator still closed
     4 reviews with its own fix and a self-declared A+, so the second cycle added little certainty.
5. **Cut boilerplate and make helpers survive a turn end.**
   - 86% of task STATE.yml is comments, and every DETAIL carries a 12-line protocol block; generate these files lean.
   - 11 cut-off background runs wasted 8-20% of spend. Run planning helpers in the foreground, or have them save as they go.
   - When the user says "take your recommendation", stop asking further approval questions; this run asked 6 that
     carried no information.
