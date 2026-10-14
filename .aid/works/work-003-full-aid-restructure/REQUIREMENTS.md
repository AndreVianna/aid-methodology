# Requirements

- **Name:** Conversational AID Restructure
- **Description:** Restructure AID so the agent in the user's tool reads plain requests, runs only the phases each work needs, and brings decisions to the user one topic at a time, with a smaller, clearer skill set underneath.

## 1. Objective

Restructure AID -- what each skill does, what it produces, and how the skills are organized --
around the phase model the community is consolidating on, while removing the friction that
model carries today.

**Leading goal -- transparent skill use.** The use of skills becomes transparent to the user. The
user states what they want in plain words ("I want to fix a bug", "I want to refactor this code",
"I want to discuss a new feature"); the orchestrator identifies the proper process to start, and the
natural conversation leads the way to the conclusion. The whole process reads as a conversation,
with phases, skills and artifacts handled underneath. (Differs from today's `/aid-triage`, which
only suggests a skill for the user to invoke.)

**State-aware guidance.** The orchestrator understands at what point of the process the work is,
and guides it from there:

- *Rich input* -- e.g. "I want to work on Jira ticket XYZ", where the ticket already carries enough
  to generate the full requirements and break them into tasks: the orchestrator produces them, presents the
  result to the user in a digestible way, and on the user's approval the process moves to Building.
- *Thin input* -- the user has only an idea: the orchestrator discusses more topics, asks more
  questions, proposes the requirements, discusses them, proposes a task breakdown, executes part of it, reviews
  with the user, and so on.

All of it runs as one process in which the user deals with the information they can, but stays in
control through the final approvals.

**The skill set underneath.** Skills are shrunk and renamed so each has one clear job, because the
orchestrator (and maintainers) need a clean, unambiguous set to route to. The user never *needs* to
know them; power users can still invoke a skill directly.

**Digestible review.** Digestible means **one topic at a time**. A requirements document may hold several sections of
related, interdependent items, all crucial to the task -- too much to absorb and decide at once.
Humans need to focus on one decision item or topic at a time. At the same time, many disconnected
decisions in rapid sequence are overwhelming, confusing and tiresome. So:

- Information is delivered in **logical chunks** that make sense together, with **time to rest** in
  between.
- The **most important decisions come first**, and each question states **how important** it is.
- **Trivial decisions** create noise: the AI makes them and the user **confirms them at the end**.

## 2. Problem Statement

The community is consolidating around a well-defined set of phases, each with its artifact:

| # | Phase | Produces |
|---|---|---|
| 1 | Preparation | the Knowledge Base (KB) |
| 2 | Ideation | a seed |
| 3 | Specification | a PRD (fully specified requirements) |
| 4 | Planning | the tasks to be executed |
| 5 | Building | the desired outcome |
| 6 | CI | review and deployment of the final result |

These phases and their artifacts have several problems (not an exhaustive list):

1. **Bureaucracy for smaller tasks.** Every task, large or small, goes through these phases one
   way or another, but for most tasks the phases are implicit inside the work. A bug fix skips
   phases 2-4 and goes straight to Building once the problem is defined; a small refactor does
   not need a full Ideation. The process should streamline itself without requiring an explicit
   skill invocation per phase: the user starts with what they want to do, and an orchestrator
   handles the phases and the artifact generation in the background.
2. **Information overload for humans.** The artifacts each phase produces are important: they
   guide the AI agent through the next phase with quality and guardrails. But humans feel
   overwhelmed reviewing and validating all of their content. Part of the cause is a lingering
   lack of trust -- in the AI generation, in the KB content that constrains it, or in the
   precision of the problem definition. Even with that distrust, reviewing ~400 lines of dry
   technical markdown is too much for most humans, many of whom have only non-technical skills
   or a short attention span (ADHD or other factors).
3. **Too many skills and agents.** The number of skills and agents makes it hard to know which
   skill to use and when, and several names are too similar (`describe`, `define`, `plan`,
   `specify`, ...).

## 3. Users & Stakeholders

| Who | Role | What they need from this |
|---|---|---|
| **People who use AID through their AI coding tool** (Claude Code, Codex, Cursor, ...) -- developers, and non-technical or attention-limited people who review and approve work | Primary users | Say what they want in plain words; review one topic at a time; stay in control through the approvals |
| **AID maintainers** | Secondary users | A clean skill set with one clear, non-overlapping job per skill |
| **The AID maintainer (Andre Vianna)** | Decision-maker | Approves the requirements and the final result |

## 4. Scope

### In Scope

**Base direction** (accepted by the maintainer, from `analysis/skills-restructure-proposal.md` as
corrected by FR-5):

- The host agent is the orchestrator, guided by `rules.md` (short orchestration section + skill
  guide) and an on-demand playbook skill (FR-5).
- The skill set shrinks substantially -- **no fixed target number**; the final count is decided after the
  work, by whether the agents solve developers' problems efficiently. Indicative shape: phase skills (Preparation/KB build, Definition,
  Specification, Planning, Building, CI), setup skills (config, connectors, chat), and supporting
  skills (KB query/update/view, research, prototype, review, test, ticket, release, monitor).
- The skills that pair an action with a kind of thing (78 today, e.g. `/aid-create-api`) become one
  skill per action (create, update, document, test, prototype), with the kind as an argument; the rules
  for each kind live in one catalog (Feature 009). `/aid-design` retires: shaping an idea for a kind is
  `/aid-brainstorm`'s job, and the kept design is the technical part of Specification.
- Phases are flexible around a fixed core: Specify -> Plan -> Execute almost always happens; Definition
  runs when the work must first be defined (discussion or an external ticket); Preparation runs once
  plus on demand; CI always closes the work (at minimum, marking it done). `full` / `lite` changes how much the
  user reviews; intent is read by meaning and validated against the KB (FR-4); depth escalates or
  de-escalates as the work evolves.
- The orchestrator and interviewer sub-agents retire (only the main conversation can talk with the
  user). `aid-tech-writer` and `aid-developer` stay separate; reviewer specialization stays open (FR-13);
  the other agents (architect, researcher, operator, clerk) keep their roles in this work.
- One work layout: a single `STATE.yml` per work; no delivery- or task-level state files; `PLAN.md` shows
  the waves, derived from task dependencies.
- The proposal's F3 (does the front door engage on every plain-language request?) is settled by
  FR-5: `rules.md` guides the host agent on every request.

### Out of Scope

- **Changes to the host tools themselves** -- AID only supplies rules and skills.
- **The KB's internal content model** -- covered by the separate knowledge-graph redesign seed
  (`.aid/design/knowledge-graph-redesign.md`); this work changes how the KB is used, not its
  document structure.
- **Other backlog follow-ups:** hooks, the model-tier settings map, a shared agents folder.
- **The dashboard and chat features**, beyond adjusting them to the new skill names and state layout.
- **Compatibility stubs for old slash names** (see M1).

## 5. Functional Requirements

### FR-1 Phase model

AID adopts the community's six phases as its phase model, replacing today's seven. Users rarely
see phase names; the phases are the backbone the orchestrator tracks.

The phases are **flexible around a fixed core**: **Specify -> Plan -> Execute** almost always happens.
Preparation runs once (plus on-demand KB updates), Definition runs when the work first has to be
defined, and CI always closes the work -- its PR/MR and pipeline steps apply only when the project
uses a repository and a pipeline.

| Phase | Produces | Absorbs today's | Notes |
|---|---|---|---|
| Preparation | the KB | Discover | Runs **once**, when the KB is created, and then **on demand** when the KB needs an update -- not a step of every work. |
| Definition | a seed (when the problem is discussed) | Describe, Brainstorm | Digests what the work is through `/aid-brainstorm` when the user is discussing the problem. External sources (a Jira ticket, a GitHub issue, ...) can enter at any phase (FR-18). Describe and Brainstorm overlap. |
| Specification | `REQUIREMENTS.md` | Define, Specify | The "feature" concept must be revisited: the current skill almost always proposes more features than are actually necessary, and its notion of a feature is not what a feature represents in a business model. |
| Planning | the tasks | Plan, Detail | Deliveries and waves are only groupings of tasks; the atomic tasks and their dependencies are the most important information. |
| Building | the outcome | Execute | Building is executing **and testing**. |
| CI | a merged PR/MR and a closed work | (new) | The pull-request phase -- see FR-7. **Always runs**: its minimum action is marking the work done, even without git or a repository; the PR/MR and pipeline steps apply when they exist. Not deploy/monitor: those are works of their own. |

### FR-2 Knowledge Base management

The KB is managed through four operations, **always handled by the orchestrator**: it identifies
when the KB should be updated, and when a piece of information about the project should be queried
from the KB. The user never needs to trigger them (FR-8).

| Operation | Purpose | Absorbs today's |
|---|---|---|
| Build KB (`/aid-kb-build`) | Create the KB (Preparation phase) | `/aid-discover` |
| Query KB (`/aid-kb-query`) | Answer project questions from the KB | `/aid-ask` |
| Update KB (`/aid-kb-update`) | Keep the KB current as the project changes | `/aid-update-kb` |
| Visualize KB (`/aid-kb-show`) | Only exposes the existing HTML view (`kb.html`): gives a link to open it. It builds nothing. | (new) |

Summarize is no longer a separate skill: building the HTML view (what `/aid-summarize` did) is absorbed
by Build KB and Update KB, which generate and refresh `kb.html` automatically. In the old -> new table,
`/aid-summarize` maps to "automatic in `/aid-kb-build` and `/aid-kb-update`", not to `/aid-kb-show`.

### FR-3 What a feature is

"Feature" keeps only its business meaning: a capability a user or customer can see and would value
on its own. The requirements document is built from **requirements with acceptance criteria**. A work is split into
several features only when it truly delivers several such capabilities; most works have one, or none
(a bug fix, a refactor). Tasks trace to requirements and acceptance criteria, not to feature folders.

`REQUIREMENTS.md` has **two parts**:

1. **Business** -- what and why: objective, problem, users, scope, requirements, acceptance criteria.
2. **Technical** -- how it will be built: the approach, the parts of the system it touches, data and
   interfaces, risks, and the design that is kept. Written **once for the whole work**, or **once per
   feature** when the work splits into features; each technical section names the requirements it serves.

### FR-4 Intent interpretation

The orchestrator does not map phrasings; it interprets **meaning**, the way a colleague would.

- **Matched against the skill guide.** Every user request is compared against the skill guide in
  `rules.md` (FR-5) to find a skill that corresponds to it. One match: the agent proposes that
  skill's workflow. Several candidates: the agent decides itself whenever it can, and asks the user
  for the path only when it genuinely cannot decide. No match: the agent just continues normally --
  no AID workflow is forced.
- **Meaning, not keywords.** Different wordings of the same intent land in the same place; example
  phrasings are illustrations, not a lookup list.
- **Verified against the project.** The user's words are a hint, not the truth: the orchestrator
  checks the interpreted intent against the KB and the code. Example: a "refactor" that adds a new
  API endpoint changes behavior, so it is treated as a new capability.
- **Stated before starting.** The orchestrator states its reading and the reason in one line, which
  the user can correct, before starting a route. It asks one question (with a recommendation,
  NFR-Q) only when genuinely unsure.
- **Re-classified as the work evolves.** When the conversation reveals the work is bigger or
  different, the orchestrator re-routes and says so.
- **Questions and decisions are always validated against the KB** -- at intake and throughout the
  work. A question about the project starts no work: it is answered from the KB, with sources.

### FR-5 Where orchestration lives

- **The orchestrator is the host agent** -- the agent in the tool the user is already talking to
  (Claude Code, Codex, Cursor, ...). AID adds no separate orchestrator actor: no front-door skill to
  invoke and no orchestrator sub-agent.
- **AID supplies guidance, not an actor:**
  - `rules.md` (loaded at every session start) carries a **short orchestration section** (about
    10-20 lines): read the intent, always consult the KB, find where the work stands, size the work,
    and follow the one-topic-at-a-time and approval rules.
  - `rules.md` also carries a **guide to the AID skills**: what each one is for and when to use it,
    so the agent knows what is available and picks the right one. (This absorbs the intent-to-skill
    routing idea in `.aid/design/skill-routing.md`.)
  - The **detailed procedures** (richness checklist, depth rules, resuming a work, ...) live in an
    on-demand playbook skill that the agent loads when it starts or resumes a work.
- **Why the split:** the rules must be present every time, or the agent will not apply them to a plain
  request; the detailed procedures are only needed when a work starts, so keeping them out of
  `rules.md` keeps every session's context small.

### FR-6 Approvals and the merge boundary

| Depth | Mandatory document approvals |
|---|---|
| `full` | **Every document** is confirmed by the user (seed, requirements, task plan, ...), plus the final result. |
| `lite` | **One approval before Building starts** -- the agent always confirms what it is about to build (for a small fix, one short line) -- plus the final result. |

- The table covers the approval of **documents**. The building milestones below apply at **every depth**.
- **There is no depth without a confirmation before building.** Even the smallest work is confirmed before Building starts.
  `/aid-execute` opens with this confirmation: in `lite` it is the single pre-build approval; in `full` it follows
  the plan approval, or is the same approval when both fall at the same moment. It is where the per-wave
  option below is asked.
- **Always an approval at the end**, on the final result, at every depth. Like every approval, it comes
  **before the push it controls**: nothing reaches the PR/MR without the approval that covers it.
- **Building milestones.** After the confirmation before building (which is not a milestone), building runs
  without the user and stops for approval only at milestones. This is the single definition of the
  milestone flow; features and criteria refer to it.
  - **Required:** the end of **each delivery** and the end of **the whole build**.
  - **Optional** (asked during the confirmation before building): the end of **each wave** -- a review per
    wave, optionally **with a PR/MR update** per wave. The PR/MR update is offered only together with the
    review.
  - **Approvals that fall at the same moment are one approval.** On a work with a single delivery, the
    delivery milestone, the whole-build milestone and the final-result approval are the same approval.
  - **Every milestone runs the same steps:**
    1. After verification (FR-19), a **read-only quick hand-off** to `/aid-monitor-pipeline` reads the new
       review comments and pipeline results (when a PR/MR exists) and hands straight back.
    2. Building prepares their corrections (FR-19).
    3. The approval shows what was built since the last milestone, plus those corrections.
    4. At a milestone **that may push** (every required one, and a wave with a PR/MR update), the approval
       also asks **"Create or update the PR/MR now?"**. The user's yes is the instruction FR-7 requires:
       a **quick hand-off** to `/aid-monitor-pipeline` (FR-20) pushes the approved work, creates or
       updates the PR/MR, and hands straight back to Building.
  - **Nothing runs in parallel**, `/aid-monitor-pipeline` is the only skill that touches the PR/MR, every
    push carries only approved work, and **full CI monitoring** starts only after the whole build is
    approved (FR-7).
  - **Real blockers** are raised when they happen: something the agent cannot decide or fix on its
    own, including a decision that conflicts with the KB (AC-5). They are interruptions, not milestones.
- **One worktree and one branch per work, always.** A work has exactly one worktree, and one branch
  (on the remote once the worktree is pushed). There are no per-delivery branches; one PR/MR per
  work is created or updated at the milestones above. `/aid-execute`'s per-delivery branches and
  its "merge to main" step are removed.
- **AID never merges anything.** The furthest it goes is pushing to the work's own branch; the merge
  is always a human act.

### FR-7 The CI phase, and operational works

- **Opening the PR is part of CI, and happens only when the user instructs it.** The agent opens a
  pull request (GitHub) or merge request (GitLab) for the work only on the user's instruction; it
  never opens one on its own.
- **CI is the pull-request phase.** Once the PR/MR exists and **the whole build is approved** (before
  that, see the building milestones in FR-6), CI manages it to a mergeable
  state: it handles code reviews from other agents or developers, makes sure the CI pipeline
  completes green, and runs the hardening, security and quality reviews. It never merges (FR-6).
- **The CI phase ends when the PR/MR is merged** -- by a human -- into its parent branch (usually
  `main` or `master`). Until then the agent keeps reacting to reviews and pipeline failures; after
  the merge, deploying and monitoring production are separate works.
- **Reacting to reviews and failures.**
  - A review comment that reports a **bug or a required correction** is corrected by the agent on its own.
  - A **suggestion or plain comment** is evaluated by the agent and brought to the user as options with a
    recommendation (FR-17).
  - A pipeline failure is diagnosed and corrected by the agent on its own; when the same failure
    survives 3 correction attempts, the agent stops and asks.
  - **Every correction, automatic or not, is a build** (FR-19) and is **approved by the user before it is
    pushed**, like any other change.
- **Only the real changes are pushed.** What the work pushes is exactly what will land in the parent
  branch: the PR/MR holds only the proper changes. AID's temporary files are never pushed, and
  nothing is pushed only to be removed later by a clean-up commit.
- **What happens to a work folder is a project setting** (`.aid/settings.yml`):
  - **push** -- the work folder is part of the work's changes and lands in the parent branch;
  - **keep local** -- preserved on the local machine only, never pushed;
  - **delete** -- removed at clean-up, e.g. when the team keeps its source of truth in Jira or
    another tool and asks the agent to update it (FR-18) before the work closes.
- **Closing a work.** Marking the work **done** is the minimum action of this phase -- it means there is
  nothing left to monitor -- and it applies even when the user uses no git or repository. After the
  merge, clean-up is **local only**: remove the temporary folders and files, delete the local branch,
  and exit and delete the worktree -- handling the work folder as the project setting says.
- **AID never deletes a remote branch.** That is part of the merge process or reserved to the user.
- **Operational activities are works of their own, not phases:** preparing a release, publishing,
  deploying, and starting monitoring are each an individual work, started like any other request
  ("prepare release 4.0", "deploy to staging"). They act on merged history, not on a single work.

### FR-8 How skills are invoked

- **The user never needs to run any skill**: the agent starts the right one from a plain request. But
  every skill stays available to a user who wants to run it.
- **Every AID skill stays invocable by slash command** -- that is part of the host tool's behavior,
  and AID does not change it. There is no hidden/internal split: all skills are always available.
- **The agent also starts and follows skills on its own**, behind the scenes -- equally a native
  capability of the host tools. This is how the orchestration of FR-5 works in practice.

### FR-9 Where the Definition seed lives

The seed (the shaped idea: framing, candidate directions, open questions) lives in
`.aid/design/<name>.md` while the idea is being shaped, and is **deleted once its requirements is approved**;
its content then lives on in the requirements. An idea can survive across sessions before it is ready, and
may never become a work; work folders are disposable by rule, so the seed does not live there.

### FR-10 The KB in a greenfield project

In a greenfield project the user does not start with "build me a KB"; they start with an idea or a
task. The orchestrator **builds the KB organically from that**, and **keeps updating it along the
construction of the initial features**: each fact (stack, conventions, architecture, decisions)
enters the KB when it is actually decided or built, not guessed up front.

### FR-11 Phase skill names

Plain, familiar names -- no invented verbs, no acronyms (NFR-N):

| Phase | Skill |
|---|---|
| Preparation (builds the KB) | `/aid-kb-build` |
| Definition | `/aid-brainstorm` (when discussing the problem) |
| Specification | `/aid-specify` *(M2)* |
| Planning | `/aid-plan` *(M2)* |
| Building (execute and test) | `/aid-execute` *(M2)* |
| CI (the pull-request phase) | `/aid-monitor-pipeline` |

### FR-12 Deliveries and waves live in `PLAN.md`

Deliveries stay: a delivery is a way to group tasks so they build something that can be delivered.
What goes away is **dedicated documents** for them (no per-delivery folder, state file or blueprint).
The Planning phase's `PLAN.md` holds them all:

- each **delivery**, with its acceptance criteria;
- the **waves** inside each delivery;
- the atomic **tasks** and their **dependencies** -- still the most important information.

Each task keeps **one instruction file** (what to build, for the building agent) with no state of its
own; `PLAN.md` links to it, and progress lives in the work's single `STATE.yml`.

`PLAN.md` is **an improved TODO list**: a simple, scannable checklist (deliveries, waves, tasks with
their dependencies and state), not a heavy document.

### FR-13 Agents

The **orchestrator** sub-agent retires (the host agent orchestrates, FR-5), and the **interviewer**
sub-agent retires (the question protocol, FR-17, runs in the main conversation, the only one that can
talk with the user).

The `aid-tech-writer` agent (prose for people: docs, READMEs, release notes) stays separate from the
`aid-developer` agent (code): clear writing is a different skill, and agents are invisible to users,
so merging them would simplify nothing the user notices.

**Open question -- reviewer specialization.** A single generic reviewer may be too broad a judge. A
possible split is separate reviewers for **completeness**, **correctness** and **semantic
consistency** (correlations across documents). This is still a big unknown, to be settled in a later
phase (by experimentation), not decided here.

### FR-14 Product-planning documents

Roadmap and backlog stay as **ordinary KB documents**, and the MVP stays a section of the roadmap: created and updated through the normal
flow (brainstorm, then update the KB), with no dedicated skills (today's six
`aid-create/update-{roadmap,backlog,mvp}` skills retire). They let the agent act on requests such as
"work on the next backlog item" or "what's on the roadmap?"; teams that prefer their tracker can
simply not use them.

### FR-15 Effort-level check before Specification

Interpreting intent and doing analysis well depend on the model's reasoning effort level. In the
maintainer's tests, analysis-heavy tasks (e.g. discovery and specification) run below **high** effort
give sub-optimal results, up to completely wrong answers. The agent checks the current effort level
**once the work has been captured (after Definition) and before Specification starts**, and, when it
is below high, recommends a higher one to the user. Building the KB carries no effort check.

### FR-16 Help establish unreachable connections

When an environment the work needs (e.g. GitHub or GitLab for the CI phase) is out of reach, the
agent first tries to help the user establish the connection, and only gives up if that fails.

### FR-17 Question protocol

There is no separate interview step: the Q&A is **one protocol**, used **always**, whenever any
skill needs information from the user or discusses something with them -- brainstorm,
requirements, planning, questions during building, building the KB.

1. **One question at a time.** Never one question that answers several topics at once.
2. **Short and clear**, presented with a short, clear reason why it is asked.
3. **Respect the user's technical level.** Never ask a technical question of a non-technical
   user; always assume the lower level. Give deeper technical detail only when the user asks.
4. **Always a recommendation** (or proposed answer), with its reasoning.
5. **Only valid options** -- never one that could lead to errors or worse results.
   1. When the recommendation is the only valid option, the question becomes a confirmation.
   2. When two or more options are equally valid and good, present them all, and say which is best.
   3. Do not ask obvious questions that need no confirmation.
   4. Always let the user give a different answer, or ask for clarification, as free text.
6. **Grouped by subject**, so the user concentrates on one topic at a time; within a subject,
   the most important question first. Groups hold **3 to 5 questions**.
7. **Offer a break** after each group and **whenever the subject changes**.
8. **Follow-ups come immediately** after the question that raised them, so the user keeps track.
9. **Skip what is already answered**: when an earlier answer settles a question, or makes it
   trivial, assume the answer and skip it.
10. **Every question and answer is recorded.** A user who cannot answer (lack of knowledge, ...)
    can skip a question; it stays open and is resumed later, with the same user or another one.

### FR-18 External sources

Information from external sources (a Jira ticket, a GitHub issue, any other source) can enter a
work **at any moment**, not only at its start. There are two kinds:

| Kind | Where it lives | Reach |
|---|---|---|
| **Project sources** | Catalogued in the KB (external sources, connectors) | Used by every work when needed, without being attached |
| **Work sources** | Recorded in that work's `STATE.yml` | Apply to that work only (e.g. the ticket behind it) |

- When the user asks the agent to pull in a source, its information becomes part of the work: it is
  **analysed and applied** -- it may move the work to the next phase, answer pending questions, or
  raise new ones (asked through the question protocol, FR-17).
- **Two-way:** on the user's request, the agent also updates the source with information from the work,
  and attaches the files the user picks (usually `REQUIREMENTS.md`) -- for teams whose source of truth
  is the external tool.

### FR-19 Verification and simplification

Every task goes through **build -> verify -> simplify -> re-verify (only if something changed)**:

- **Verify** is the review cycle: agents other than the one that did the work review it against its
  acceptance criteria and the KB, under the grading protocol; the tests must pass.
- **Simplify** comes **only after verification passes**: a lighter review cycle that looks for what
  can be simplified or cleaned, to avoid over-engineering and clutter.
  - It runs **once** per task -- no simplify/verify loop.
  - It **never changes behaviour**: the same tests must pass, and no test is changed or removed to fit.
- **Re-verify** runs only when the simplification changed something, scoped to what it changed. No
  change, no extra review cycle.
- **At the end of each delivery** the same sequence runs over the whole delivery (verify, then one
  light simplification for duplication across tasks, then a scoped re-verify if anything changed),
  before the delivery milestone (FR-6).

### FR-20 Skill state machines and hand-offs

A skill's state machine is the fixed set of steps it moves through. It is revised so that:

1. **Steps are invisible to the user.** No state banners or "you are here" maps; at most one plain
   progress line, and more only when the user asks.
2. **The current step is always saved** in the work's `STATE.yml`, so any session -- or another
   user -- resumes exactly where the work stopped.
3. **Every stop that needs the user uses the question protocol (FR-17)**; no skill-specific prompts.
4. **One shared set of rules** governs how every skill moves between its steps, instead of each skill
   describing its own.
5. **Automatic hand-offs between skills.** A skill can pass the work to another skill on its own:
   - **at the end** of its process (e.g. Definition -> Specification), when no approval is required in
     between; and
   - **in the middle** of its process (e.g. Building needs a KB update), with the work coming back to
     the exact step it left once the other skill finishes.
   The state machine and the `STATE.yml` layout are reviewed as a whole to support this: each hand-off
   records where it came from, where it went, why, and where to return.

### FR-21 Review focus

Every review (by an agent or a script) reports **only issues that affect the work**: a step that cannot
be built, a check that would fail on the real files, or something that contradicts another part of the
document or a decision the user made. Exact counts, word-for-word comparisons and wording or cosmetic
points are **not findings**. This keeps review cycles short and every round meaningful.

## 6. Non-Functional Requirements

- **NFR-N (naming).** No acronyms in artifact or skill names: names say plainly what the thing is.
  The Specification phase produces `REQUIREMENTS.md` (not a "PRD" file). Accepted exception: **KB**,
  an established term in AID (`/aid-kb-build`, `/aid-kb-query`, `/aid-kb-update`, `/aid-kb-show`).
  **Every skill name is a verb**, or "KB" plus a verb (`/aid-kb-build`); `/aid-config` is renamed
  `/aid-configure` (old -> new table, no alias).

- **NFR-T (testing behaviour).** Criteria about how the agent behaves are checked by a **conversation
  test suite**: each has a few scripted sample conversations with an expected outcome; each runs
  **3 times** and passes only if all 3 runs meet it; an independent reviewer agent judges the
  transcripts. "Every skill in all five tools" is checked statically, against each tool's installed
  files. Feature 001 builds the suite; every feature adds its own samples.
  **When tests run:** unit tests are isolated and run with every feature; integration tests run only once
  everything they need exists -- until then each is recorded in a **deferred-tests list** (test, waiting
  for which feature); the **full integration suite** runs at the end, before release, with that list empty.

- **NFR-Q (how questions are asked).** Every question put to the user follows the question
  protocol (FR-17).

## 7. Constraints

1. **Ships as part of AID v4.0.0.** v4 (the shared skills folder) is merged but not yet released;
   folding this restructure into the same release gives users one breaking upgrade, not two in a row.
2. **Works the same in all five supported tools:** Claude Code, Codex, Cursor, Antigravity, Copilot CLI.
3. **Keeps AID's engineering rules:** one source (`canonical/`) rendered for every tool; bash and
   PowerShell CLIs with byte-identical output (PowerShell 5.1-safe, ASCII); the tracking discipline;
   no work ids in the KB.
4. **`rules.md` stays short.** It loads in every session, so its orchestration section and skill guide
   must stay compact (FR-5).

## 8. Assumptions & Dependencies

**Assumptions**

1. Every supported tool reliably reads `rules.md` at session start (confirmed for all five tools by the
   v4 SESSION START probes).
2. Every tool's agent can pick and run skills on its own, not only by slash command (FR-8).
3. The agent's model can interpret intent by meaning and check it against the KB (FR-4) -- **only at a
   sufficient reasoning effort level**; below it, analysis-heavy tasks degrade (FR-15).
4. For the CI phase the agent can reach GitHub/GitLab through the tool's own access or a connector;
   when it cannot, it helps the user establish the connection before giving up (FR-16).

If assumption 1 or 2 fails in a tool, transparent orchestration degrades there to plain slash commands.

**Dependencies**

- AID v4's shared layout (one skills folder, `.aid/runtime/`, `rules.md`), merged on master.

## 9. Acceptance Criteria

### Understanding the request

| # | Check | Covers |
|---|---|---|
| AC-1 | Every user request is compared against the skill guide; when one skill matches, the agent **proposes that skill's workflow** before starting. | FR-4, FR-5 |
| AC-2 | When several skills match, the agent decides itself whenever it can, and **asks the user for the path only when it genuinely cannot decide**. | FR-4, NFR-Q |
| AC-3 | When no skill matches, the agent **continues normally**, without forcing an AID workflow. | FR-4 |
| AC-4 | A question about the project ("how does X work?") is answered **from the KB, with sources**, and starts no work. | FR-4 |
| AC-5 | During a work, a decision that conflicts with the KB is **raised to the user**, never resolved silently. | FR-4 |
| AC-6 | `rules.md` has an orchestration section of **at most 20 lines** plus a skill guide covering **every** AID skill (what it is for, when to use it); there is no front-door skill and no orchestrator sub-agent. | FR-5 |
| AC-7 | A ticket with objective, users, scope, acceptance criteria and constraints goes straight to requirements + plan with **one approval** before building (`lite`); a bare idea starts brainstorming (`full`). | Objective, FR-1 |

### Conversation and control

| # | Check | Covers |
|---|---|---|
| AC-8 | Every question to the user carries **one recommendation** and an **importance label**; several options only for real forks, never a bad option, and a free-form answer is always possible. | Objective, NFR-Q |
| AC-9 | Reviews come **one topic at a time**, in logical chunks, most important first; trivial decisions are taken by the AI and confirmed **in one batch at the end**. | Objective (digestible review) |
| AC-10 | `full`: the user confirms every document. `lite`: exactly one approval before building. Every depth: a final approval of the result; every approval comes **before the push it controls**. | FR-6 |
| AC-11 | **Nothing in AID ever merges**: no skill or script merges a branch or a PR/MR, and a PR/MR is opened only on the user's instruction. | FR-6, FR-7 |
| AC-12 | After Definition and before Specification starts, the agent checks the effort level and **recommends a higher one** when it is below high; no effort check runs before building the KB. | FR-15 |
| AC-13 | When GitHub/GitLab cannot be reached, the agent **offers to help establish the connection** before stopping. | FR-16 |

### Phases and documents

| # | Check | Covers |
|---|---|---|
| AC-14 | Phases flex around the core: every work that builds something runs **Specify -> Plan -> Execute** (Execute includes **testing**); **Definition** runs when the work must first be defined (`/aid-brainstorm`); external sources can enter at any phase (FR-18); **Preparation** runs once when the KB is created and on demand for updates; **CI** always closes the work (at minimum marking it done), with its PR/MR and pipeline steps only when a repository and pipeline exist; release, deploy and monitoring run as **works of their own**. | FR-1, FR-7 |
| AC-15 | The KB is built, queried, updated and shown as HTML **through the agent's own judgment**, with no user step required; there is no separate summarize skill. | FR-2 |
| AC-16 | Specification produces `REQUIREMENTS.md` made of **requirements with acceptance criteria**; it splits into features **only** when several user-visible capabilities exist (a bug fix produces none). | FR-3, NFR-N |
| AC-17 | An idea's seed lives in `.aid/design/` and is **deleted once its requirements are approved**. | FR-9 |
| AC-18 | In a new project, KB facts appear **as they are decided or built**, never guessed up front. | FR-10 |
| AC-19 | `PLAN.md` is a scannable checklist (deliveries with their acceptance criteria, waves, tasks, dependencies, state); **no separate delivery documents or state files**; each task has one instruction file with no state. | FR-12 |
| AC-26 | Building: `/aid-execute` runs each task's tests as part of the task; a task is marked **Done only after its tests pass**, and the final result shows the test results. | FR-1 |
| AC-27 | CI: for an open PR/MR, once the whole build is approved, `/aid-monitor-pipeline` corrects reported bugs, required corrections and pipeline failures on its own, and brings each suggestion or plain comment to the user as options with a recommendation; **every correction goes through the build process and the user's approval before it is pushed**; this continues **until a human merges the PR/MR** into its parent branch; the agent **never merges**. | FR-7 |
| AC-28 | For each skill that asks the user questions, a scripted test conversation shows: one topic per question, each with its reason, a recommendation, only valid options and a free-text answer; groups of 3-5 by subject, most important first; a break offered after each group and at each change of subject; follow-ups right after the question that raised them; answered or trivial questions skipped; a skipped question recorded as open and resumable later by the same or another user. | FR-17 |
| AC-29 | A ticket pulled in mid-work is **recorded as a work source** in `STATE.yml`; the pending questions it answers are closed, any new questions are added, and the phase advances when its conditions are met; on request, the agent **writes the work's information back** to the source; project sources are used by every work when needed without being attached. | FR-18 |
| AC-30 | For every kind in the catalog, the typed form (`/aid-<action> <kind> ...`) and a plain-words request for the same thing reach **the same skill and the same rules**. | FR-4, FR-8 |
| AC-31 | No skill name combines an action (create, update, design, document, test, prototype) with a kind of thing (e.g. no `/aid-create-api`); the dashboard and chat show **only current skill names**. | Scope, M1 |
| AC-32 | During building, the user is asked for approval **only** at the end of each delivery and at the end of the whole build (each after verification, before a PR/MR is created or updated), plus at the end of each wave **only when the user opted in** during the confirmation before building (a PR/MR update per wave only together with the review per wave); these milestones apply at every depth, and approvals that fall at the same moment count as one; real blockers (something the agent cannot decide or fix on its own, including a conflict with the KB) are the only other interruptions. | FR-6 |
| AC-33 | For each task and each delivery, the work record shows verify -> simplify, and a scoped re-verify **only when** the simplification changed something; simplification runs once, and the test set before and after it is identical and passing. | FR-19 |
| AC-34 | Running a work from start to PR/MR creates **exactly one worktree and one branch** for it; no skill or script creates a per-delivery branch or merges anything. | FR-6 |
| AC-35 | The PR/MR's **final content** (its net diff against the parent branch) contains **only changes meant for the parent branch**: no file under `.aid/.temp/`, files under `.aid/works/` only when the project setting is **push**, and no idea draft. A work folder is never pushed only to be removed by a later clean-up commit; a work's own idea draft may appear in earlier commits of its branch and be removed before the PR/MR's final content. | FR-7 |
| AC-36 | After a human merges the PR/MR, the work is marked **done** and clean-up is local only (temporary files, local branch, worktree); **no remote branch is deleted** by AID. The work folder is pushed, kept locally, or deleted exactly as the project setting says. A work in a project with no repository is still marked done at the end. | FR-7 |
| AC-37 | During a work, no state banner or "you are here" map is shown unless the user asks; after an interrupted session, a new session resumes at the step saved in `STATE.yml`; every stop that needs the user follows FR-17. | FR-20 |
| AC-38 | In a scripted work, (a) at the end of Definition the work passes to Specification **without the user typing a command**, and (b) when Building needs a KB update mid-task, the KB update runs and the work **returns to the same step**; `STATE.yml` records each hand-off (from, to, why, return point). | FR-20 |
| AC-39 | Roadmap and backlog are ordinary KB documents and the MVP is a section of the roadmap, all created and updated through the normal flow with **no dedicated skills**. | FR-14 |
| AC-40 | The question protocol is run by the main conversation; the interviewer sub-agent no longer exists. | FR-13, FR-17 |
| AC-41 | The dashboard reads the work's state from the new `STATE.yml` layout (FR-20) and shows it correctly for a work at each phase; the chat reads no work state, so it needs no change. | FR-20, Scope |
| AC-42 | Every building milestone follows the FR-6 steps: a read-only hand-off to `/aid-monitor-pipeline` collects new review comments and pipeline results, Building prepares their corrections, and the approval shows the work since the last milestone plus those corrections; at a milestone that may push, the approval asks whether to create or update the PR/MR, and on yes `/aid-monitor-pipeline` alone pushes the approved work and returns to Building; no push ever carries unapproved commits; full monitoring starts only after the whole build is approved. | FR-6, FR-7, FR-20 |
| AC-43 | No `/aid-design` skill exists; a request to design a kind of thing (e.g. "design the orders API") reaches `/aid-brainstorm` with that kind's catalog rules, and only `/aid-brainstorm` writes idea drafts under `.aid/design/`. | Scope, FR-9 |
| AC-44 | Every approved `REQUIREMENTS.md` has a business part and a technical part; the technical part exists once for the whole work, or once per feature when it splits, and each technical section names the requirements it serves. | FR-3 |
| AC-45 | After all features are built, one documentation pass (the tech-writer agent) rewrites the user documentation (`docs/`, `site/src/content/`, `README.md`) against the finished product; a pre-release check fails if any user document still names a retired skill or an old phase name. | Scope, M1 |
| AC-46 | The reviewer agent, the shared review instructions and every review brief template carry the FR-21 "What to report" rule (only issues that affect the work; counts, word-for-word comparisons and cosmetic points are not findings); a static check fails if any of them lacks it. | FR-21 |

### Skills, naming and constraints

| # | Check | Covers |
|---|---|---|
| AC-20 | Each skill has **one clear job** and no two skills overlap; skills that hold no logic of their own (pure wrappers) are gone, their variations kept as data. **No fixed skill count**: the final number is set by evaluating whether the agents solve developers' problems efficiently. | Scope, Problem 3 |
| AC-21 | **Every** AID skill can be run by slash command in all five tools, and the agent can also run it on its own. | FR-8 |
| AC-22 | Phase skills are named `/aid-kb-build`, `/aid-brainstorm`, `/aid-specify`, `/aid-plan`, `/aid-execute`, `/aid-monitor-pipeline`; **no skill or artifact name uses an acronym**, and **every skill name is a verb** (or KB + a verb). | FR-11, NFR-N |
| AC-23 | `aid-tech-writer` and `aid-developer` remain separate agents; the orchestrator sub-agent is retired. Reviewer specialization is settled in a later phase (open question, FR-13). | FR-13 |
| AC-24 | The release notes carry an **old -> new table** for every retired slash name. | M1 |
| AC-25 | AID's engineering rules hold: one source rendered for all five tools, byte-identical bash/PowerShell output, the tracking discipline, no work ids in the KB, and **all CI green on Linux and Windows**. | Constraints |
## 10. Priority

Every feature is **Must**. The build order is the §11 feature order (Feature 001 first); each feature
lists its own requirements and criteria there. Feature 001 leads -- everything else hangs off it --
and Feature 002 comes next because every phase skill built after it follows its rules.

Every feature must also pass AC-22 (names), AC-24 (old -> new table rows for the skills it retires)
and AC-25 (engineering rules, CI green), and adds its own sample conversations to the conversation
test suite (NFR-T).

After the last feature, **one documentation pass** updates the user documentation against the finished
product (AC-45), instead of each feature rewriting the same pages.

## Minor decisions

- **M1 -- Old slash names.** Skills that are retired take their slash names with them (clean break in
  the next major version); the release notes carry an old -> new table. *(Confirmed by the maintainer.)*
- **M2 -- Remaining phase skill names.** Specification, Planning and Building keep today's familiar
  names: `/aid-specify`, `/aid-plan`, `/aid-execute`. *(Confirmed by the maintainer.)*
- **M3 -- Knowledge Base operation names.** *(Set by the maintainer.)* `/aid-kb-build` (replaces
  `/aid-discover` as the Preparation skill -- v4 is a breaking release), `/aid-kb-query`,
  `/aid-kb-update`, `/aid-kb-show` (gives a link to open `kb.html`).
- **M4 -- Work-folder setting.** Values `push` / `keep-local` / `delete`; default `push`. *(Set by the maintainer.)*
- **M5 -- Idea draft deletion.** When an idea draft exists, it is deleted at the first approval that
  covers its requirements. *(Confirmed by the maintainer.)*
- **M6 -- Pause cadence.** A break is offered after each group of 3-5 questions and at each change of
  subject (FR-17). *(Set by the maintainer.)*
- **M7 -- Pipeline retry limit.** When the same pipeline failure survives 3 correction attempts, the
  agent stops and asks (FR-7). *(Confirmed by the maintainer.)*
- **M8 -- Feature names 001, 002, 009.** "Ask for Work in Plain Language", "Clear, Step-by-Step
  Decisions", "One Obvious Skill for Each Need". *(Confirmed by the maintainer.)*
- **M9 -- Other agents.** Architect, researcher, operator and clerk keep their roles in this work (§4).
  *(Confirmed by the maintainer.)*
- **M10 -- Collection at every milestone.** The read-only collection of review comments and pipeline
  results runs before every building milestone, including a review-only wave, so one rule covers all
  milestones (FR-6). *(Confirmed by the maintainer.)*
- **M11 -- Coinciding approvals.** Approvals that fall at the same moment are one approval (FR-6).
  *(Confirmed by the maintainer.)*
- **M12 -- Confirmation before building.** `/aid-execute` opens with it (FR-6); in `full` it follows the plan
  approval, or is the same approval when both fall at the same moment. *(Confirmed by the maintainer.)*

## 11. Features

Every feature is **Must**; the order below is the build order (§10). Every feature must also pass
AC-22, AC-24 and AC-25. AC-45 (the final documentation pass) runs once, after all features.

### Feature 001 — Ask for Work in Plain Language

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-4, FR-5, FR-7, FR-8, FR-13, FR-18; §6 NFR-Q, NFR-T
- **Criteria:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-14, AC-21, AC-23, AC-29

#### Description

The agent in the user's own tool reads a plain request by its meaning, checks it against the skill guide in `rules.md`, the KB and the code, and proposes the matching workflow -- or just continues when nothing matches. It sizes the work (`full` / `lite`) and runs only the phases the work needs around the Specify -> Plan -> Execute core. Project questions are answered from the KB with sources. Information from external sources -- project sources in the KB, or work sources attached to one work -- is applied to the work at any moment, and written back to the source on request. `/aid-triage` folds into the skill guide. The orchestrator sub-agent retires; every skill stays runnable by slash command.

#### User Stories

- As an AID user, I want to say what I need in my own words and have the agent pick the right process, so that I never need to know skill names.
- As an AID user with a complete ticket, I want to go straight to requirements and plan with one approval, so that small, well-defined work is not slowed down.
- As an AID user, I want a question about my project answered from the KB, with sources, without starting a work, so that a quick question stays quick.

#### Technical Specification

Serves FR-1, FR-4, FR-5, FR-7, FR-8, FR-13, FR-18, NFR-Q and NFR-T. Paths are `canonical/` sources;
each is rendered to `.agents/skills/`, `.claude/skills/`, `.aid/runtime/` and the five tool profiles
by the existing render (`.claude/skills/generate-profile/scripts/run_generator.py`). Skill names used
here follow whatever names exist when each line is written (renames such as `/aid-config` ->
`/aid-configure` belong to Feature 009).

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Edit | `canonical/aid/rules.md` | Replace `## Workflow` with `## Handling a request` (at most 20 lines); add `## Skill guide`; add one summary bullet; fix the stale state-file wording (known issue KI-001) |
| Create | `canonical/skills/aid-orchestrate/SKILL.md` | The on-demand procedures skill (FR-5) |
| Create | `canonical/skills/aid-orchestrate/references/` | `start-or-resume.md`, `check-intent.md`, `size-and-route.md`, `external-sources.md`, `feedback-routing.md` |
| Edit | every hand-authored `canonical/skills/*/SKILL.md` that stays in this work | `description:` rewritten as "what it is for. Use when ..." (see Components) |
| Edit | `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` (the `description = (...)` template) | Same shape for the generated doorway skills: the what-sentence is the catalog row's `intent:` field in `canonical/aid/templates/shortcut-catalog.yml`, followed by one "Use when ..." sentence. Regenerate with the builder; never hand-edit a file carrying the `GENERATED by generate-profile/scripts/build-shortcut-skills.py` marker; `--check` stays green (SBI05 in `tests/canonical/test-shortcut-builder-invariants.sh`) |
| Edit | `canonical/aid/templates/work-state-template.yml` | Add `intent:` and `sources:`; remove `ticket_ref` |
| Edit | `canonical/aid/templates/delivery-state-template.yml`, `task-state-template.yml`, `requirements/requirements-template.md` | Remove `ticket_ref` and the feature `**Ticket:**` line |
| Edit | `canonical/skills/aid-update-ticket/SKILL.md` | Add an `attachment` part (see External sources) |
| Edit | `canonical/skills/aid-monitor/SKILL.md`, `references/state-route.md` | ROUTE runs in the main conversation; findings become plain requests (see Components) |
| Delete | `canonical/skills/aid-triage/` | Folded into the skill guide and `/aid-orchestrate` |
| Delete | `canonical/agents/aid-orchestrator/` | The host agent orchestrates (FR-13) |
| Delete | `.aid/design/skill-routing.md` | Absorbed by the skill guide, as the seed itself instructs |
| Create | `tests/canonical/test-skill-guide.sh` | Static check (see Testing) |
| Create | `tests/conversation/` | Conversation test suite (see Testing) |

New work `STATE.yml` keys (authored by the work's active branch; their final place in the single
layout is set with Features 002 and 006):

```yaml
intent:
  request: 'make login sessions last longer'   # the user's words, short
  reading: change          # bug fix | refactor | change | new capability | document | operational | knowledge update
  reason: 'session length is fixed in the auth module; users see new behaviour'
  depth: lite              # lite | full
  # block style: the state readers reject inline lists
  phases:
    - Specification
    - Planning
    - Building
    - CI
  changes: []              # one entry per re-route: at, from, to, why
sources: []                # see External sources
```

Constraint carried by `tests/canonical/test-shared-layout-sources.sh`: `rules.md` names no tool
folder (`.claude/`, `.codex/`, ...), no `canonical/` path and no extra `<!-- AID` comment, so the new
sections use slash names and `.aid/runtime/` paths only and are located by heading.

##### 2. Orchestration flow

1. **Match.** Read the request by its meaning and compare it with the skill guide (FR-4).
2. **Project question** -> answer from the KB with sources (`/aid-ask`, later `/aid-kb-query`);
   no work folder is created.
3. **No match** -> carry on normally. **One match** -> propose that skill's workflow. **Several** ->
   choose; ask one question with a recommendation only when truly undecidable. A typed `/aid-<skill>`
   always wins.
4. **Check the reading** against the KB and the code (`check-intent.md`): read
   `.aid/knowledge/INDEX.md`, then `capability-inventory.md`, `module-map.md` and `architecture.md`;
   search the code for what the user named; classify by observable effect (new behaviour -> new
   capability; same behaviour -> refactor; behaviour broken against the KB -> bug fix). The user's
   label is a hint only.
5. **Start or resume** with `/aid-orchestrate`: find or create the work (reusing
   `.aid/runtime/scripts/works/enumerate-works.sh` and `.aid/runtime/templates/work-initiation-gate.md`,
   not restating them), read the resume point from `STATE.yml`, size the work, pick its phases, and
   record `intent:`.
6. **Show the reading** -- one line with its reason -- in the same message as the first real question
   or approval, and wait for the answer (never a turn of its own): in `lite`, the confirmation before
   building; in `full`, the first brainstorm or specification question.
7. **Hand over** to the first phase skill, started by the agent itself (FR-8). Where a tool cannot
   start skills on its own, the agent names the slash command instead (the fallback in §8 Assumptions).
8. **During the work**: new facts or sources trigger a re-check; a re-route is said in one line and
   added to `intent.changes`; a decision that conflicts with the KB is raised with the user.

Routing rule (`size-and-route.md`), stated once: **the reading decides which phases run; the richness
check decides the depth.** Definition runs only when the problem itself must be shaped (an idea, or a
problem that is unclear). Missing details in an otherwise clear bug fix, change or capability are asked
inside Specification through the question protocol; they never add Definition.

Which phases run (by reading):

| Reading | Phases |
|---|---|
| Question about the project | none: answered from the KB |
| Bug fix, refactor, change, new capability, document -- with a clear problem | Specification -> Planning -> Building -> CI |
| Any reading whose problem is unclear, or a bare idea | Definition (`/aid-brainstorm`) -> Specification -> Planning -> Building -> CI |
| Knowledge update ("we moved to Postgres") | KB update only (Preparation on demand) |
| Operational (release, deploy, monitor) | a work of its own, run by its own skill, closed by CI |
| Before the first phase, when an existing codebase has no KB | Preparation is offered first |
| Every work | CI closes it, at minimum by marking it done; until Feature 008 delivers `/aid-monitor-pipeline`, `/aid-orchestrate` does this minimum itself (`writeback-state.sh --pipeline --field Lifecycle --value Completed`) |

How much the user reviews (depth, by richness):

| Input | Depth |
|---|---|
| Objective, users, scope, acceptance criteria and constraints all present -- each counts as present when the request, a source or the KB states it (e.g. a complete ticket) | `lite`: one approval before building, plus the final result |
| Any of the five missing | `full`: the user confirms every document |
| Several user-visible capabilities, a data migration, or security-sensitive work | `full`, whatever the input |

##### 3. Components

**`## Handling a request`** in `canonical/aid/rules.md` -- at most 20 lines. **How lines are counted**
(the same rule SG-01 applies): from the `## Handling a request` heading line through the last non-blank
line before the next `## ` heading, so the heading and the blank line under it count and the trailing
blank lines do not. The draft below is 16 body lines: with the heading and its blank line it counts
**18**, leaving a margin of 2. Final text is set at build, within the cap:

```markdown
- Read what the user wants by its meaning, not its wording, and match it to the skill guide below.
- A question about this project starts no work: answer it from the Knowledge Base, citing sources.
- One skill fits: propose its workflow. Several fit: choose yourself; ask one question, with your
  recommendation, only if you cannot choose. None fits: carry on with no AID workflow.
- A typed `/aid-<skill>` always wins.
- The user's words are a hint: check your reading against the Knowledge Base and the code (a
  "refactor" that adds an endpoint changes behaviour, so it is new work).
- To start, resume or cancel a work, run `/aid-orchestrate`: it finds where the work stands, sizes it and
  picks the phases it needs.
- Show your reading and its reason in one line, inside your first question or approval; then wait.
- Specification, Planning and Building (with tests) almost always run; Definition only when the problem
  must first be shaped; Preparation builds the Knowledge Base once, then updates it on demand; CI always
  closes the work. Release, deploy and monitoring are works of their own.
- If the work turns out bigger or different, re-route and say so in one line.
- Check every decision against the Knowledge Base; raise a conflict, never settle it alone.
- Ask one topic at a time, with a recommendation; the user approves before building and the result.
```

**Summary bullet** (copied into every `AGENTS.md` / `CLAUDE.md` region by `lib/aid-install-core.sh`
`_aid_rules_summary`): "Read every request by its meaning and match it to the skill guide in
`.aid/runtime/rules.md`; answer project questions from the Knowledge Base." The summary goes from
7 to 8 bullets.

**`## Skill guide`** in `canonical/aid/rules.md`:
- One line per skill, at most 100 characters: `` - `/aid-x` -- what it is for; when to use it ``.
- Order: phase skills, KB skills, supporting skills, setup skills.
- Hand-written; the static test keeps it equal to `canonical/skills/` both ways.
- Until Feature 009 collapses them, each action-and-kind family is one line written with a `<kind>`
  placeholder (e.g. `` `/aid-create-<kind>` ``); the test expands it against
  `canonical/aid/templates/shortcut-catalog.yml`. Feature 009 removes these lines and the expansion.
- Measured cost for the target skill set: about 900-1,200 tokens per session.

**Skill descriptions** -- every skill's `description:` uses the same shape as its guide line: first
sentence says what it is for, then a sentence starting "Use when". Skills a later feature of this work
retires are listed in the static test as exempt; the test fails if an exempt skill no longer exists, so
the list empties as they go. Generated doorway skills get the shape from the builder template, not by
hand (see Files and layout).

**`/aid-orchestrate`** -- runs in the main conversation (no sub-agent: only the main conversation can
talk with the user). `SKILL.md` at most 80 lines, each reference at most 120 lines. Its description
follows the shared shape: "Start, resume or cancel an AID work: find where it stands, size it and pick its
phases. Use when a plain request starts a new work, continues an existing one, or cancels one." References:

| Reference | Holds |
|---|---|
| `start-or-resume.md` | Find or create the work; read the resume point from `STATE.yml` |
| `check-intent.md` | The KB-and-code check (Orchestration flow, step 4); `/aid-triage`'s question shortcut and work-type heuristic move here |
| `size-and-route.md` | The routing rule, the phase table and the depth table (Orchestration flow); triage's scope judgement moves here |
| `external-sources.md` | Pull-in, apply and write-back (see External sources) |
| `feedback-routing.md` | The table moved from the orchestrator agent: work questions -> main conversation; KB questions -> KB update; impediments -> Building; monitor bugs and change requests -> new works through this same intake |

**Kind catalog hook** -- `check-intent.md` matches kinds of things against the `intent:` field of
`shortcut-catalog.yml`, as `/aid-triage` does today; Feature 009 points it at the new catalog.

**`aid-monitor` re-point** -- its "Default executor" and ROUTE dispatch row name `aid-orchestrator`, and
`references/state-route.md` sends change requests to `/aid-triage`. ROUTE now runs inline and hands each
finding back as a plain request (bug -> fix work; change request -> new work).

##### 4. External sources

| Kind | Where | Reach |
|---|---|---|
| Project sources | `.aid/connectors/INDEX.md` and `.aid/knowledge/external-sources.md` (unchanged) | Used by any work when needed; never attached |
| Work sources | the work's `sources:` list | That work only |

```yaml
sources:
  - ref: 'jira:PROJ-123'   # connector-stem:id, a URL, or a repo-relative path
    kind: ticket           # ticket | issue | document | link | file
    added: '2026-10-14T10:00:00Z'
    phase: Planning        # phase when it entered
    effect: 'answered Q4, Q6; raised Q9'
# one entry per write-back, at the top level (three levels at most)
write_backs:
  - at: '2026-10-15T09:00:00Z'
    source: 'jira:PROJ-123'  # the sources[].ref written to
    part: attachment
    files: 'REQUIREMENTS.md, PLAN.md'   # one comma-separated string
```

- **Pull in** (any phase): a tracker item through `/aid-read-ticket`, whose connector resolution and
  fetch through the tool's own connection stay unchanged
  (`.aid/runtime/templates/connectors/consumption-protocol.md`); a file or link is read directly. Add
  the `sources:` entry.
- **Apply**: compare with open `qa:` entries -- answered ones are closed with the source named in the
  answer; new questions follow the question protocol (FR-17); the phase moves on when its conditions are
  met. Record the outcome in `effect`.
- **Write back** only on the user's request, through `/aid-update-ticket` (preview and confirm, as
  today); its closed part list gains `attachment` for the files the user picks (usually
  `REQUIREMENTS.md`).
- **Tool limits**: when the tool cannot hold what is written (no attachments, size caps, missing
  permission, ...), the agent stops, tells the user, and offers the workable options with a
  recommendation under the question protocol. The user always decides how the work is persisted; the
  agent never picks a workaround on its own.
- AID stores no credential; aid-managed connection types stay deferred.

##### 5. Migration

| Old | New |
|---|---|
| `/aid-triage` | Say what you want in plain words; the skill guide in the rules routes it |
| agent `aid-orchestrator` | The agent in your tool, guided by `rules.md` and `/aid-orchestrate` |
| `ticket_ref` (work, feature, delivery, task) | One `sources:` list in the work's `STATE.yml` |

- **Release notes**: the first two rows go into the old -> new table (AC-24), drafted in
  `.aid/knowledge/backlog.md` § Next Release. No stubs (M1).
- **Installed projects**: `aid update` removes the retired skill and agent files through the install
  manifest (decisions.md § D9); no installer change.
- **Existing works**: `ticket_ref: X` becomes `sources: [{ref: X, kind: ticket}]` automatically, in the
  work-state migration built with Feature 006 (bash and PowerShell twins, identical output).
- **`ticket_ref` sites**: `consumption-protocol.md` § Multi-level `ticket_ref` linkage (rewritten for
  `sources:`), `aid-specify` `references/state-initialize.md` Step 3b, `aid-plan`
  `references/first-run-loop.md`, `shortcut-engine.md`, `aid-describe` `references/state-first-run.md`;
  tests `test-connector-consumption-linkage.sh`, `test-ticket-retirement-structural.sh`,
  `dashboard/server/tests/test_task033_execution_control_round_trips.py`, `tests/coverage-baseline.tsv`,
  `tests/coverage-rehome-allowlist.tsv`; KB `artifact-schemas.md` (Pipeline State, Delivery Lifecycle and Task State rows)
  and `infrastructure.md` (its `ticket_ref` traceability sentence); regenerated site skill flows
  (`site/src/data/skill-flows/`).
- **Orchestrator sites**: `canonical/aid/templates/agent-dispatch-tiering.md` § Per-agent defaults,
  `canonical/aid/templates/self-review-protocol.md`, `aid-monitor`, `tests/canonical/test-deploy-monitor-repurpose.sh`,
  `docs/aid-methodology.md`, `examples/brownfield-full-path/README.md`, the site's agents, methodology and
  `aid-monitor` pages, `tests/cost-baseline.tsv`, `tests/coverage-baseline.tsv`; KB `architecture.md`.
  `tests/windows/Test-AidInstaller.ps1` uses `aid-orchestrator.md` only as a legacy file name in a fixture
  and stays.
- **Triage sites**: `canonical/aid/templates/shortcut-catalog.yml`; `aid-describe` (`SKILL.md`,
  `references/elicitation-engine.md`, `references/state-first-run.md`); `aid-monitor` (`SKILL.md`,
  `references/state-route.md`); `.claude/skills/generate-profile/SKILL.md` (its curated-skill count that
  includes the triage router); `README.md`; `docs/aid-methodology.md`, `docs/diagram-content-reference.md`,
  `docs/faq.md`, `docs/glossary.md`, `docs/repository-structure.md`; the site pages under `site/src/content/docs/`:
  `index.mdx`, `guides/pipeline.mdx`, `concepts/faq.md`, `concepts/methodology.md`,
  `get-started/first-work.mdx`, `get-started/lite-path.mdx`, `reference/artifacts.md`,
  `reference/glossary.md`, `reference/overview.md`, `reference/repository-structure.md`,
  `reference/skills.md`, `skills/aid-monitor.md`, `skills/index.md` (and `skills/aid-triage.md` is deleted);
  the regenerated flows `site/src/data/skill-flows/aid-monitor.flow.json` and `aid-describe.flow.json`
  (`aid-triage.flow.json` is deleted); `site/scripts/skills/` (roster, groups,
  counts, index), `site/scripts/gen-reference.mjs`, `site/scripts/.skills-manifest.json` and their tests
  in `site/scripts/__tests__/`; `tests/canonical/test-cutover-no-dangling.sh`,
  `tests/canonical/test-deploy-monitor-repurpose.sh`, `tests/cost-baseline.tsv`; KB `tech-debt.md` row W1-6
  (the `aid-triage` roster entry); `tests/canonical/test-triage-routing.sh` is deleted.
- **Left as they are**: `.aid/knowledge/release-tracking.md` (shipped history) and
  `tests/coverage-accepted-removals.tsv` (history of removals, only appended to); `.aid/knowledge/kb.html`
  is regenerated by the KB build or update, never hand-edited.
- **Baselines**: removed assertions go to `tests/coverage-accepted-removals.tsv`; the per-session growth of
  `AGENTS.md` / `CLAUDE.md` is an excused increase in `tests/cost-baseline.tsv`.
- **Suites that assert the rules text** (a full search of `tests/` for the summary markers, the summary
  wording and the rules headings):

  | Suite | Today | Change |
  |---|---|---|
  | `tests/canonical/test-shared-layout-sources.sh` | summary block has 7 bullets | 8 bullets |
  | `tests/canonical/test-install-core-primitives.sh` | summary block is 8 physical lines (7 bullets, one wrapped) | the new physical line count |
  | `tests/canonical/test-aid-cli-parity.sh` FIX-D8 (also in the `installer-tests.yml` lane) | `^## Workflow$` appears twice in an inlined `AGENTS.md` (the user's line plus the rules' own) | use a heading the rules still carry, `## Handling a request` |
  | `test-shared-install.sh`, `test-shared-remove.sh`, `test-aid-migrate.sh`, `test-dogfood-byte-identity.sh`, `test-release-install-e2e.sh` | read the summary from `rules.md` at run time | none |
  | `tests/canonical/test-install-provisioning.sh`, `tests/windows/Test-InstallProvisioning.ps1` | use their own synthetic `## Workflow` fixtures | none |
- **KB** (no work ids): architecture, pipeline-contracts (entry doors), capability-inventory,
  domain-glossary, module-map, project-structure, test-landscape (the two new suites), integration-map and
  artifact-schemas (`intent:`, `sources:`); decisions gains "the host agent orchestrates", which
  supersedes D21 (`/aid-triage` as a suggest-only router) and D25's change-request route to `/aid-triage`
  (both marked Superseded in the summary table and their sections, matching the re-pointed `aid-monitor`),
  and amends D14 (its pointer to D21) and D15 (the agent count); then `INDEX.md` is regenerated. A final
  search for `aid-triage`, `/aid-triage` and "triage router" across `site/`, `docs/`, `.aid/knowledge/`
  and `canonical/` finds no file beyond the lists above, except history that stays as it is.
- The interviewer agent's retirement is Feature 002's (AC-40); the effort check is Feature 005's.

##### 6. Testing

**Static check -- `tests/canonical/test-skill-guide.sh`** (bash harness, `# COVERS:` headers for
`canonical/aid/rules.md`, `canonical/skills`, `canonical/agents`). Runs on every push: picked up by
`tests/run-all.sh` and added to the suite list of `.github/workflows/installer-tests.yml`, which is
the lane feature branches run.

| Group | Asserts |
|---|---|
| SG-01 | `## Handling a request` counts at most 20 lines: from its heading line through the last non-blank line before the next `## ` heading (trailing blank lines excluded) |
| SG-02 | The skill guide names exactly the skills in `canonical/skills/`, both ways (with `<kind>` expansion while it exists) |
| SG-03 | Every guide line is at most 100 characters |
| SG-04 | Every non-exempt `description:` has the what/when shape; every exempt skill still exists |
| SG-05 | No front-door skill (`canonical/skills/aid/` absent); no `aid-orchestrator` agent; `aid-developer` and `aid-tech-writer` both present |
| SG-06 | One staged bundle (`tests/lib/bundle.sh`) installed for each of the five tools: every skill is present where that tool reads skills (`.claude/skills/` for Claude Code, `.agents/skills/` for the others), byte-identical to `canonical/`, `name` equal to its folder, a non-empty `description`, and no flag that blocks slash or agent invocation |

**Conversation suite -- `tests/conversation/`** (NFR-T). Outside the `tests/canonical/test-*.sh`
glob, so neither `run-all.sh` nor GitHub CI runs it; run on demand at each feature's end and before a
release.
- `run.py` (Python 3, standard library only): `--feature 001 [--sample ID] [--hosts claude-code,...] [--runs 3]`.
  Claude Code is required; Codex, Cursor, Copilot CLI and Antigravity run only when named.
- Each run builds a fresh throwaway fixture: a small git project with code, a seeded KB unless the
  sample says otherwise, and AID installed from a bundle staged from the working tree
  (`tests/lib/bundle.sh`).
- **Driving the conversation (Claude Code).** Each agent turn is one `claude -p` run in the fixture
  folder with `--output-format stream-json`: the first turn starts a session, every later turn passes
  `--resume <session-id>` with the next user message. Why: it is the real tool reading the installed
  `CLAUDE.md`, rules and skills exactly as a user's session does, and it needs no extra package
  (AID ships with zero dependencies). Fallback, when resuming misbehaves: one long-running
  `claude -p --input-format stream-json` process fed one user message per turn. The other four tools use
  an adapter with the same three steps (start, send, read) through their own non-interactive mode; a
  tool without one is skipped with a notice.
- **Permissions of the agent under test**, on every turn: working folder = the fixture;
  `--permission-mode acceptEdits` (file edits inside the working folder need no prompt);
  `--tools` limited to `Read,Glob,Grep,Edit,Write,Bash,Skill,Task`; `--allowedTools` naming the same
  tools, with **`Bash` allowed in full** -- AID's own skills and agents write through shell commands
  (e.g. the installed `aid-reviewer` has no Write tool and writes its ledger with a heredoc), so a narrower
  shell rule would make any sample that reaches a review fail for the wrong reason. Isolation comes from
  the run, not from the shell rule: each run uses a throwaway fixture folder **and a throwaway `HOME`**
  (holding only the credentials the host needs), no `--add-dir`, `--strict-mcp-config` with no
  `--mcp-config` (no MCP server), and `--setting-sources project` (the fixture's installed AID files load;
  the maintainer's own settings and plugins do not). The suite runs on demand on the maintainer's
  machine, never in CI. `files.diff` records every change the agent makes inside the fixture and the throwaway
  `HOME` (see Transcript capture for the exclusions);
  a write elsewhere through an absolute path is **not** recorded -- a known limit of running on the
  maintainer's machine rather than in a container.
- **The simulated user** is a separate `claude -p` call per turn with only text in and out: run from a new
  empty temporary folder, with `--tools ""` (every built-in tool disabled), `--safe-mode` (no
  `CLAUDE.md`, skills, plugins, agents or hooks), `--strict-mcp-config` with no `--mcp-config` (no MCP
  server), and `--system-prompt` set to the simulated-user brief. It therefore cannot read the fixture
  or see a skill name. Its prompt is `tests/conversation/simulated-user.md` plus the
  sample's `## User` persona, its `## Answer sheet` and the transcript so far. It answers only from the
  sheet ("I don't know" otherwise), never volunteers a skill name, and replies `<<END>>` when the sheet
  has nothing left to say or the agent has finished.
- **Turn cap**: 12 user turns; hitting the cap before `<<END>>` fails the run. Each agent turn has a
  10-minute timeout.
- **Transcript capture** in `.aid/.temp/conversation-tests/<run-id>/<sample>/run-<n>/`:
  `transcript.jsonl` (one object per message: `turn`, `role` user or agent, `text`, the `tools` the agent
  called with their names and target paths, `ts`), `transcript.md` (the same, readable, given to the
  judge), `files.diff` (a before/after comparison of the whole fixture folder -- git-ignored files such as
  `.aid/.temp/` included -- and of the throwaway `HOME`; format: a unified diff of contents for text
  files, path and size only for binary files; **excluded**: the fixture's `.git/` and, in `HOME`, the host
  tool's own files (`.claude/`, `.claude.json`) and any credential file, so the judge sees only the
  agent's own changes and no secret is copied into a run folder), `checks.txt`
  and the judge's ledger.
- `samples/feature-NNN/<id>.md`: frontmatter `id`, `covers`, `fixture`; sections `## User` (opening
  message and persona), `## Answer sheet` (all the simulated user knows), `## Expected outcome`,
  `## Must not`, `## Checks` (file assertions run before judging).
- An independent `aid-reviewer` judge: a fresh `claude -p` with the same text-only settings as the
  simulated user, whose system prompt is the installed `aid-reviewer` agent body plus
  `tests/conversation/judge.md`, and whose input is `transcript.md`, `files.diff`, `checks.txt` and the
  sample's expected outcome. It returns only a 7-column ledger table, which `run.py` saves in the
  fixture's `.aid/.temp/review-pending/` and in the run folder; any Pending row fails the run.
- **Flags checked** against `claude --help` of Claude Code 2.1.296: `-p`, `--resume`,
  `--output-format`, `--input-format`, `--permission-mode` (`acceptEdits`), `--tools`, `--allowedTools`,
  `--add-dir`, `--strict-mcp-config`, `--mcp-config`, `--setting-sources`, `--safe-mode`,
  `--system-prompt`. To confirm at build time: the built-in tool names `Skill` and `Task` (the
  sub-agent tool's current name). No `Bash(...)` pattern rule is used: `Bash` is allowed in full (see
  Permissions of the agent under test).
- A sample passes only when all 3 runs pass. Exit codes: 0 all pass, 1 any failure, 2 invocation error.
- Every later feature adds its own `samples/feature-NNN/` folder.

Feature 001 samples: `001-01-one-match`, `001-02-several-decide`, `001-03-several-ask`,
`001-04-no-match`, `001-05-project-question`, `001-06-kb-conflict`, `001-07-rich-ticket`,
`001-08-bare-idea`, `001-09-bug-fix-phases`, `001-10-release-own-work`, `001-11-ticket-mid-work`,
`001-12-write-back-limit`, `001-13-project-source-unattached`, `001-14-refactor-is-new-capability`,
`001-15-no-kb-offers-preparation` (fixture: code with no `.aid/knowledge/`; checks: Preparation is
offered before any Specification question and no KB file is written before the user agrees),
`001-16-work-closes-done` (fixture: a work whose tasks are all `Done`, in a project with no git remote;
checks: `STATE.yml` ends with `lifecycle: Completed` and the agent pushes nothing).

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-1 | Orchestration flow steps 1, 3, 4, 6; Components (Handling a request) | `001-01-one-match`, `001-14-refactor-is-new-capability` |
| AC-2 | Orchestration flow step 3 | `001-02-several-decide`, `001-03-several-ask` |
| AC-3 | Orchestration flow step 3 | `001-04-no-match` |
| AC-4 | Orchestration flow step 2 | `001-05-project-question` (check: no new `.aid/works/` folder; answer cites sources) |
| AC-5 | Orchestration flow step 8; Components (Handling a request) | `001-06-kb-conflict` |
| AC-6 | Components (Handling a request, Skill guide); Files and layout (deletions) | SG-01, SG-02, SG-03, SG-05 |
| AC-7 | Orchestration flow (routing rule, depth table) | `001-07-rich-ticket`, `001-08-bare-idea` |
| AC-14 | Orchestration flow (routing rule, phase table) | `001-09-bug-fix-phases`, `001-10-release-own-work`, `001-15-no-kb-offers-preparation`, `001-16-work-closes-done` |
| AC-21 | Components (Skill guide, descriptions); Orchestration flow step 7 | SG-06; agent-started skills in `001-07-rich-ticket` |
| AC-23 | Files and layout (deletions); Migration (orchestrator sites) | SG-05 |
| AC-29 | External sources | `001-11-ticket-mid-work` (check: `sources:` entry, closed `qa:` entries), `001-12-write-back-limit`, `001-13-project-source-unattached` |

### Feature 002 — Clear, Step-by-Step Decisions

- **Priority:** Must
- **Requirements:** §4 Scope; §5 FR-6, FR-7, FR-13, FR-17, FR-20, FR-21; §6 NFR-Q
- **Criteria:** AC-8, AC-9, AC-10, AC-11, AC-28, AC-37, AC-38, AC-40, AC-41, AC-46

#### Description

Improves how AID talks with the user and how skills move through their states. Questions come one topic at a time, each with a recommendation and an importance label; reviews arrive in chunks, most important first; minor decisions are confirmed in one batch at the end. Approvals follow the depth, and every approval comes before the push it controls, including a final approval of the result, and nothing ever merges. Includes the question protocol (FR-17), which replaces the separate interview step and is used by every skill that talks with the user, and a revision of the skill state machines (FR-20): steps invisible to the user, the current step always saved, one shared set of rules, and automatic hand-offs to another skill -- at the end of a process or in the middle of it, returning to the same step. Every phase skill built after this feature follows these rules.

#### User Stories

- As an AID user who tires of long documents, I want decisions one topic at a time, most important first, each with a recommendation, so that I can decide well without being overwhelmed.
- As the decision-maker, I want every push approved before it happens, including a final approval of the result, and a guarantee that nothing merges on its own, so that I keep control of what ships.

#### Technical Specification

Serves §4 Scope (interviewer retirement, one state layout), FR-6, FR-7, FR-13, FR-17, FR-20 and NFR-Q.
Paths are `canonical/` sources, rendered as in Feature 001. **Ownership of the work's `STATE.yml`** (Q34):
this feature owns its overall shape -- template, writer, readers, phase names; Feature 006 owns the
planning part inside it (deliveries, waves, tasks), the removal of delivery and task state files, and the
single migration of existing works. The phase skills rebuilt by Features 003-008 follow the two shared
files defined here; today's skills change only where a rule must hold for every skill now (no banners,
the shared files cited, questions recorded in one place, no interviewer).

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Create | `canonical/aid/templates/question-protocol.md` | The one question protocol (FR-17) and the one question-record shape (see Question protocol); type `template-own` |
| Create | `canonical/aid/templates/skill-steps.md` | The one rule set for steps, hand-offs, approvals and the work record (FR-20, FR-6, Q42); type `template-own` |
| Delete | `canonical/aid/templates/state-machine-chaining.md` | Replaced by `skill-steps.md` |
| Edit | `canonical/agents/aid-reviewer/AGENT.md`, `canonical/aid/templates/reviewer-dispatch.md`, every `canonical/skills/*/references/reviewer-brief.md` | Add the `### What to report` rule (FR-21; see Review focus) |
| Create | `canonical/aid/templates/project-state-template.yml` | The project-level `.aid/STATE.yml`: the question record only (Q38) |
| Edit | `canonical/aid/rules.md` § Handling a request | Its last bullet names the protocol and the merge rule (see Question protocol) |
| Edit | `canonical/aid/templates/work-state-template.yml` | New keys, `qa` on every work, phase names, the block-style rule (see Work state layout) |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | Modes `--create`, `--step`, `--handoff`, `--handoff-return`, `--reroute`, `--check`, `--repair`, `--ask`, `--answer`; the new phase names |
| Edit | `dashboard/scripts/writeback-state.sh` (the deliberate fork) | The new phase names only; it keeps `Deploy` |
| Edit | every phase site of Work state layout, including `canonical/aid/templates/work-initiation-gate.md` § 3b CONTINUATION and `aid-deploy` `references/state-idle.md` | The new phase names; the gate's resume table re-keyed (Work state layout) |
| Edit | every hand-authored `canonical/skills/*/SKILL.md` and `references/*.md` that prints a banner, routes by the old advance words or asks the user; `canonical/aid/templates/shortcut-engine.md`, `design-lifecycle.md` | Banners removed, `skill-steps.md` and the protocol cited, advance words updated, host question pickers dropped (see Steps and hand-offs). The generated doorway skills print nothing themselves: they run `shortcut-engine.md`, so they change through it |
| Edit | `canonical/skills/aid-orchestrate/references/start-or-resume.md` (Feature 001) | Creates a work through the gate's `--create`; resume reads only the work record (see The work record) and the open questions |
| Edit | `canonical/skills/aid-orchestrate/references/start-or-resume.md` (Feature 001) | Requests about an existing work: "cancel work-NNN" is read as an action on that work, not a new request -- one confirmation question, then `writeback-state.sh --pipeline --field Lifecycle --value Canceled` (clears the saved skill and step) |
| Edit | `canonical/aid/rules.md` § Handling a request (the `/aid-orchestrate` line) and `canonical/skills/aid-orchestrate/SKILL.md` `description:` and its skill-guide line | "start or resume" becomes "start, resume or cancel", so a request such as "cancel work-NNN" matches `/aid-orchestrate` (same line count; SG-01 unchanged) |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3a NEW and § 3b CONTINUATION | The gate becomes the only creator of a work's `STATE.yml`: § 3a runs `writeback-state.sh --create` (type, request, the calling skill, its first step, phase) before it hands the new work back; § 3b routes by the record only (see The work record) |
| Edit | every **allocation point** -- the places a work's `STATE.yml` is created today: `canonical/aid/templates/design-lifecycle.md` § Allocation (used by `aid-brainstorm`, every `aid-design-*` and the KB-writing `aid-create-*` / `aid-update-*`); `aid-design/SKILL.md` § State: INTAKE step 4; `canonical/aid/templates/shortcut-engine.md` § State: INTAKE, Step 4 (every doorway skill); `aid-describe/SKILL.md` § No works exist, § Direct `work-NNN` argument, § Arguments and the `--reset` step of § State Detection, with `references/state-first-run.md` § 1b / 1b-ii; and the `SKILL.md` of the starters that stay -- `aid-research`, `aid-review`, `aid-test`, `aid-prototype`, `aid-report`, `aid-create-document`, `aid-update-document` | Each calls the gate's § 3a with its request, its own name, its first step and, where it sets them today, `pipeline.path` and minimum grade; the gate's `--create` makes `STATE.yml`. Their copy-the-template instructions, the two `phase: Describe` scaffold blocks and their hand-written `initiator:` / `active_skill:` / `lifecycle:` lines go (SS-11, SS-14). `aid-describe`'s `--reset` is removed, and a directly named `work-NNN` that does not exist goes through the gate like any new work (see The work record) |
| Edit | the starters' own continuation lines: `aid-research`, `aid-test`, `aid-prototype`, `aid-report`, `aid-create-document`, `aid-update-document`, `aid-design` (each in its allocation step: "on continuation route to the chosen work's resume door and STOP"), `aid-review` § Step 5, `shortcut-engine.md` § Design Notes and § State: INTAKE Step 3 (both route by the `phase`-matched skill and HALT), `aid-describe/SKILL.md` § One or more works exist (the Continuation bullet keyed on a Describe-phase work) | Each becomes one line: "On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step." SS-14 (d) keeps phase-keyed continuation out |
| Exempt (not edited) | the per-skill files of skills a later feature rebuilds or retires, which allocate through the converted points above but keep a binding line of their own (`initiator: aid-<name>`, sometimes `active_skill:`): `aid-brainstorm` -> Feature 003; every `aid-design-*` (`api`, `architecture`, `backlog`, `cicd`, `cli`, `config`, `dashboard`, `data-model`, `data-pipeline`, `document`, `infra`, `integration`, `job`, `messaging`, `mvp`, `roadmap`, `stack`, `test`, `testing-strategy`, `theme`, `ui`) -> Features 003/009; `aid-create-*` / `aid-update-*` for `architecture`, `backlog`, `cicd`, `mvp`, `roadmap`, `stack`, `testing-strategy` -> Feature 004 | On the shared exempt list for SS-14 (Testing). Their works are still created by the gate's `--create`, because their allocation runs through the converted `design-lifecycle.md` § Allocation (see The work record) |
| Edit | every `canonical/skills/*/SKILL.md` § State Detection (or its equivalent) | Detection never routes: it only shapes the entry step of a skill starting fresh and validates a saved step on resume (see The work record) |
| Edit | the delivery-level `qa` writers (`aid-ask/SKILL.md` § Target-file resolution, `aid-plan/SKILL.md` § Feedback Loops, `aid-execute/references/state-delivery-gate.md` § Non-CODE issues) and every skill file naming `## Cross-phase Q&A` (in `aid-specify`, `aid-define`, `aid-detail` and `aid-describe`, whose engine references `elicitation-engine.md`, `move-playbook.md`, `advisor-stance.md`, `state-describe-seed.md`, `state-q-and-a.md` included) | Every question recorded in the work's `qa` through `--ask` / `--answer` (known issue KI-003) |
| Delete | `canonical/agents/aid-interviewer/` | FR-13, AC-40 |
| Edit | `canonical/aid/templates/agent-boilerplate.md` (inlined into every `canonical/agents/*/AGENT.md` by `{{include:agent-boilerplate}}`); the "When to Escalate" lines of `aid-architect`, `aid-researcher` and `aid-reviewer` that write a Q&A entry | A new `## Talking with the user` section: a sub-agent never asks the user; it records its open questions with `--ask` and lists them in its report, and the main conversation asks them. The escalation lines record through `--ask` (AC-40) |
| Edit | `aid-describe` (`SKILL.md` Dispatch, `references/advisor-stance.md`), `aid-define/references/` (`state-feature-decomposition.md`, `state-cross-reference.md`, `reviewer-brief.md`), `aid-specify/SKILL.md` (its "not an interviewer" line), `canonical/agents/aid-architect/AGENT.md` ("that's the Interviewer"), `canonical/aid/templates/agent-dispatch-tiering.md` § Per-agent defaults | Interviewer references removed (see Migration) |
| Edit | `site/scripts/lib/flow-graph/advance.mjs` | The new advance words; flows regenerated by `site/scripts/gen-skills.mjs` |
| Edit | `dashboard/reader/models.py`, `dashboard/reader/parsers.py`, `dashboard/reader/reader.py`, `dashboard/server/server.py` § `_ser_work`, `dashboard/server/reader.mjs`, `dashboard/home.html` | The dashboard reads the new layout (see Dashboard and chat) |
| Create | `tests/canonical/test-skill-steps.sh`, `tests/canonical/skill-steps-exempt.tsv`, `tests/canonical/test-never-merges.sh`, `tests/canonical/test-deferred-tests.sh`, `dashboard/server/tests/test_home_stage_rails.mjs`; `tests/conversation/protocol-checks.md`, `tests/conversation/deferred.tsv`, `tests/conversation/samples/feature-002/` | See Testing |

##### 2. Work state layout

**Block style only**, for every state file (work, project, and the KB file Feature 004 converts): the
dashboard readers (`dashboard/reader/state_schema.py` and its Node twin) accept no inline list or
mapping other than the literal `[]` / `{}`, nothing deeper than three levels, and no comment on the line
of a key that opens a list or mapping (the key then reads as empty). Each template's header states the
rule, the writer emits nothing else, and SS-08 parses the templates with the dashboard reader (known issue
KI-002).

New and changed keys in the work's `STATE.yml`:

```yaml
# [W] Definition | Specification | Planning | Building | CI
phase: Building
# [W] the skill running the work now
active_skill: aid-execute
# [W] that skill's current step; -- when none
step: EXECUTE
# [W] where inside the step, in plain words; -- when none
step_detail: 'task-004: tests written, code half done'
# [W] append-only, newest last; one entry per hand-off
handoffs:
  - at: '2026-10-15T10:00:00Z'
    from: aid-execute
    from_step: EXECUTE
    from_detail: 'task-004: tests written, code half done'
    to: aid-update-kb
    why: 'task-004 moved sessions to Redis; the KB still says in memory'
    returns: 'yes'
    returned: --
# [W] every question and answer, newest last (shape: see Question protocol)
qa: []
```

- **`phase`** is a display label: shown to the user and on the dashboard, never used to route or resume
  (the work record below does that). It takes the FR-1 names. Preparation is not a work phase: the KB's own state shows it, as it
  shows Discover today. Old -> new: Describe -> Definition, Define and Specify -> Specification, Plan and
  Detail -> Planning, Execute -> Building. The writer accepts only the new names; both readers map the old
  ones, so a work not yet migrated still shows its phase. **Phase sites** -- every place outside tests
  where an old name is data or logic, from a sweep of the whole tracked tree (the dashboard page's sites
  are in Dashboard and chat):

  | Site | Today | Change |
  |---|---|---|
  | `canonical/aid/scripts/execute/writeback-state.sh` (header enum, `--pipeline` Phase check and its error text) | the six old names | the five new ones; an old name is refused |
  | `dashboard/scripts/writeback-state.sh` (the fork; same three places) | old names plus `Deploy` | the new names plus `Deploy` |
  | `canonical/aid/templates/work-state-template.yml` (enum comment and default) | `phase: Describe` | the new enum; default `phase: Specification`, the first phase of the fixed core (the skill creating the work writes `Definition` when that phase runs first) |
  | The nine `--field Phase --value` writes: `aid-specify` `references/state-initialize.md`, `references/state-continue.md`; `aid-define` `references/state-feature-decomposition.md`; `aid-plan` `references/first-run-loop.md`; `aid-detail` `references/first-run.md`; `aid-execute` `references/state-execute.md`; `shortcut-engine.md` § State: SPEC, § State: PLAN, § State: DETAIL | old names | by the mapping |
  | The two literal seeds that bypass the writer: `aid-describe` `references/state-first-run.md`, `shortcut-engine.md` § State: INTAKE | `phase: Describe` written by hand | replaced by `writeback-state.sh --create ... --phase Definition` (The work record) |
  | `shortcut-engine.md` § State: GATE (the `Phase` enum sentence, "`Phase` stays `Detail`") | old enum | new enum; stays `Planning` |
  | `canonical/aid/templates/work-initiation-gate.md` § 3b CONTINUATION (the resume table and the same-invocation sentence below it) | keyed on old names | routes by the work record only; old names survive only in the legacy block that proposes a repair (The work record) |
  | `aid-deploy` `references/state-idle.md` ("it stays at `Execute`") | `Execute` | `Building` |
  | `dashboard/reader/models.py` (`Phase` enum and its docstring); `dashboard/server/reader.mjs` (`Phase` object) | old members | `Definition`, `Specification`, `Planning`, `Building`, `CI`, plus `Unknown` |
  | `dashboard/reader/parsers.py` and `dashboard/server/reader.mjs` (the phase map) | old name -> member | new name -> member, plus the old names in a block marked `legacy-phase-map: begin` / `end` |
  | `dashboard/reader/state_schema.py` (a comment's example value) | `'Execute'` | `'Building'` |

  **Finishing clears the saved skill:** the writer, whenever it sets `lifecycle` to `Completed` or `Canceled`,
  also sets `active_skill: none` and clears `step` / `step_detail` in the same locked write (a
  `test-writeback-state.sh` case covers it). Every skill that today finishes a work by writing
  `lifecycle: Completed` / `Canceled` by hand (e.g. `aid-research`, `aid-test`, `aid-prototype`,
  `aid-report`) switches to the writer; static check **SS-12** fails on any hand-written `lifecycle:
  Completed` / `Canceled` in `canonical/skills/` or `canonical/aid/templates/`, so no stale saved skill
  outlives its work. Today 42 skill files do it (`aid-deploy` already uses the writer; its
  `state-done.md` prose that quotes `lifecycle: Completed` is reworded so SS-12 does not match it). Feature 002 converts the 7 that stay (`aid-research`,
  `aid-test`, `aid-prototype`, `aid-report`, `aid-review`, `aid-create-document`,
  `aid-update-document`); the rest are skills a later feature rebuilds or retires (the `aid-design-*`
  family and `aid-design` -> Features 003/009; the KB-writing `aid-create-*` / `aid-update-*` for
  architecture, stack, testing strategy, CI/CD, roadmap, backlog and MVP -> Feature 004; `aid-brainstorm` ->
  Feature 003) and sit on the shared exempt list (Testing) that names the owning feature; the list fails
  if an exempt entry no longer exists, and -- like DT-02 -- fails under `AID_RELEASE_CHECK=1` while it is
  not empty, so a skill rebuilt under the same name (e.g. `aid-brainstorm`) cannot stay exempt for good.

  **Tests** follow one rule: a hand-written old name in a fixture's input stays (it exercises the readers'
  mapping); every reader output asserted (`Phase.Execute`, golden files such as
  `dashboard/reader/tests/fixtures/task011_golden/*.json`) and every value fed to a writer changes to the
  new names -- in the sweep, `tests/canonical/test-writeback-state.sh`, `test-pipeline-status-walkthrough.sh`
  (A1, M4), `test-work-state-template.sh`, `test-describe-full-only.sh`, `test-producer-completeness.sh`,
  `test-disjoint-merge.sh` (its `phase: Execute` assertion), and the `Phase.<old>` assertions and writer
  calls under `dashboard/reader/tests/`. Left as they are: `site/src/data/skill-flows/` (regenerated),
  `tests/coverage-baseline.tsv` (assertion names, re-recorded), `tests/canonical/test-diagram-content.sh`
  and `canonical/aid/scripts/summarize/` (diagram text, not state), and documentation prose that describes
  today's seven steps (`docs/`, `site/src/content/docs/`, with the site check
  `site/src/data/__tests__/ac13-version-injection.test.ts`), which is not phase data. SS-11 keeps an old
  name from coming back.
- **`step` / `step_detail`** are written together with `active_skill`, by `--step` (Steps and hand-offs).
- **The work record** (Q42) -- `intent.reading` (the work's type, Feature 001), `active_skill`, `step` and
  `step_detail`. It is the **only** thing that decides where a work resumes, in the gate, in
  `/aid-orchestrate` and inside every skill.
  - **From creation, however the work starts**: a plain request through `/aid-orchestrate`, a typed slash
    command, or a one-pass doorway skill. **The gate is the only creator of a work's `STATE.yml`.** The
    calling skill hands the gate the user's words, its own name and its first step (and its phase, when it
    is a phase skill). On NEW, § 3a resolves the work id, creates and enters the worktree, reads the work's
    type with `/aid-orchestrate`'s `check-intent.md` (a typed command's own kind is only a hint, FR-4), and
    runs one locked write -- `writeback-state.sh --create --work-dir <dir> --reading <type> --request
    '<words>' --skill <caller> --step <first step> [--phase <phase>] [--depth lite or full]` -- **before**
    it hands the new work back. `--create` copies `work-state-template.yml` and fills the record,
    `pipeline.initiator` (the caller), `lifecycle: Running`, `started` and `updated` in that one write, so no
    work ever exists without its record. The caller then adds only its own keys, through the writer.
    `--create` also takes `--path` (`pipeline.path`, until Feature 006 drops it) and `--minimum-grade`, which
    the converted scaffolds set today. Every allocation point -- the shared ones every exempt skill
    allocates through (`design-lifecycle.md` § Allocation, `aid-design` INTAKE step 4, `shortcut-engine.md`
    § INTAKE Step 4) and `aid-describe`'s new-work and `--reset` paths -- is converted in this feature
    (Files and layout), so this holds for every entry point on disk. `--create` stays gate-only:
    - **`/aid-describe --reset` is removed** (the skill retires with Feature 003, so it gets no new
      machinery): a user who wants a fresh start cancels the work and starts a new one through the gate
      (Migration). **Cancelling a work** is a plain request ("cancel work-003") handled by `/aid-orchestrate`:
      it asks one confirmation question (question protocol), then runs `writeback-state.sh --pipeline
      --field Lifecycle --value Canceled`, which also clears the saved skill and step (Finishing clears the
      saved skill); the gate then reports the work as finished and the dashboard shows it as canceled.
    - **A directly named `work-NNN` that does not exist** is not created by `/aid-describe`: the agent says
      so in one line and the request goes through the gate like any new work, which gives it the next id.
    - **The request words** passed to `--create` are the user's message that started the work. When a
      skill is started by a bare slash command with no words, its first question (question protocol) asks
      what the user wants, and that answer is the request the gate reads with `check-intent.md` before
      `--create`. That question is not recorded separately: its answer becomes `intent.request` in the
      record `--create` writes, which is the question's record. If the user does not answer, no work is
      created, so there is nothing to resume.
  - **Exempt skills until their feature lands**: a skill on the shared exempt list keeps a binding line of
    its own (`initiator: aid-<name>`, sometimes `active_skill:`), but it allocates through the converted
    `design-lifecycle.md` § Allocation, so `--create` has already written the record, with those same
    values, when the skill reads that line. **The record `--create` wrote wins**: the converted allocation
    text and the gate's hand-back both say, in one line, "`STATE.yml` was created by the gate; skip any
    instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand; set other keys
    through the writer." `--create` refuses an existing `STATE.yml` (exit 8), so nothing may create the file
    before the gate does; and if an agent overwrote the record anyway, the next resume's `--check` finds it
    missing and recovery repairs it with the user.
  - **Kept current**: written at creation, at every step entry **before** any work in that step, at every
    hand-off and return, at every re-route (`--reroute`, which also appends Feature 001's `intent.changes`
    entry), and at finish. Only the writer touches it -- never a hand edit (SS-14).
  - **Fail-closed**: a non-zero exit from any record write stops the skill at once; the agent tells the user
    in one plain line what failed and that nothing more runs until it is fixed. No silent continue, no retry
    beyond the writer's own lock wait.
  - **Routing never uses detection** -- which skill and which step always come from the record. A skill's
    own artifact detection has exactly two uses: (a) a skill **starting fresh** on a work (a `PASS`, a
    `CALL`, or the user typing a skill other than the one the record names) runs it inside its entry step
    to decide how far that step goes; (b) on **resume**, the resumed skill runs it to **validate** the saved
    step against what is on disk -- a mismatch goes to recovery, never to a silent re-route. Typing the
    command the record already names is a resume. A hand-off writes the target skill **and its entry step**
    (the first row of its step table) in the same locked write, so there is never a moment with a skill
    but no step: an interrupted hand-off, or a tool that cannot start skills and names the command instead,
    still leaves a resumable step. A typed start of another skill is a pass without a phase change:
    `--handoff --to <skill> --step <its entry step> --returns no --why 'user ran /aid-<skill>'`, with no
    `--phase` -- the current phase stays (an on-demand skill drives none), and no open call is left behind.
  - **Recovery, never silent**: on every resume the agent first runs `writeback-state.sh --check`. It
    reports the record missing (an open work with no `intent.reading`, with `active_skill: none`, or with a
    saved skill but `step: --`) or inconsistent (a finished work with a saved skill; a saved skill that is
    not installed; a malformed open call); the resumed skill's validation (use (b) above) adds a saved step
    whose artifact is not on disk. The agent tells the user and proposes the **whole** repaired record --
    type, skill, step -- as **one** confirmation question under the question protocol, with its
    recommendation:
    - **skill and step**: from the skill's detection; for a work not yet migrated, from the gate's legacy block;
    - **type** (only when `intent.reading` is missing): proposed from the evidence on disk -- the request
      or objective in `REQUIREMENTS.md` § 1, an idea draft in `.aid/design/`, `pipeline.initiator` (e.g. a
      `/aid-fix` work is a bug fix) -- read the same way as `check-intent.md`.
    Only after the user confirms (or corrects any part, in the same answer) does it run `--repair`, which
    **requires `--reading` when the record has none** and appends a `lifecycle_history` entry naming the old
    and the new record. **After one confirmed repair the record is complete and `--check` passes**, so row 2
    of the resume table never fires twice for the same problem.

  **Resume table** of `work-initiation-gate.md` § 3b, written out in full, first match wins:

  | # | Chosen work's state | Resume entry point |
  |---|---|---|
  | 1 | Already `Completed` / `Canceled` | Tell the user the work is finished (nothing to resume) and stop; suggest a new work if they meant to start fresh |
  | 2 | `--check` reports the record missing or inconsistent | The recovery above; once the user confirms and `--repair` has written, continue at row 3 |
  | 3 | The record (every other open work) | `active_skill` at its saved `step`; with an open call, inside the called skill. A halted Lite work resumes at its doorway skill's APPROVAL-HALT step, which asks for the pending approval again (today's separate Lite row folds into this one) |

  After the table, a **legacy block** between `<!-- legacy-phase-map: begin -->` and
  `<!-- legacy-phase-map: end -->` holds today's phase-and-file rows (old phase name -> its skill; the
  halted-Lite and `delivery_state` rows -> `/aid-execute`; `active_skill: aid-deploy` -> `/aid-deploy`).
  They never route: recovery reads them only to propose the skill and step of a work started before the
  record existed (its type comes from the evidence named above). Feature 006's migration fills the record
  for every old work, then removes the block.

  The same-invocation sentence goes: the starter always enters the chosen work's worktree (the steps that
  follow the table) and runs the skill the record names -- itself or another (FR-8) -- with no special case.
  `tests/canonical/test-work-initiation-gate.sh` gains `--check` fixtures for every row: a finished work,
  which stops even when a leftover saved skill makes `--check` report it inconsistent (row 1); a work with
  no `intent.reading` and one whose saved skill is not installed (row 2, each with its reason); a healthy
  work and one with an open call (row 3); and an old-name work with no type, whose single confirmed
  `--repair` (skill and step from the legacy block, type from its `REQUIREMENTS.md`) makes `--check` return 0
  and the next resume land on row 3.


- **`handoffs`**: `returns: 'yes'` is a call -- the work comes back to `from`, `from_step`,
  `from_detail`; `'no'` is a pass at the end of a process. `returned` stays `--` while the work is away
  (and always for a pass). The newest entry with `returns: 'yes'` and `returned: --` is the **open call**.
- **`qa` on every work**: the template's full-layout omission rule goes, and delivery-level `qa` is no
  longer written. It existed so two delivery branches never wrote one file; FR-6 leaves one branch per
  work. The readers keep merging delivery `qa` until Feature 006 removes the delivery files.
- **Unchanged**: `lifecycle`, `pause_reason`, `user_approved` (now written `'yes'` at the final-result
  approval), Feature 001's `intent`, `sources` and `write_backs`. `pipeline.path` is replaced by
  `intent.depth`; Feature 006's migration drops it.
- **Project file `.aid/STATE.yml`** (Q38): created on first use from `project-state-template.yml` by
  `--ask --project`; holds only `qa`. It is not in the install manifest, so `aid update` never touches it.
  It does **not** follow `.aid/settings.yml` on uninstall: when the last tool is removed, `aid remove`
  deletes `settings.yml` (`uninstall_tool` in `lib/aid-install-core.sh`, `Uninstall-AidTool` in
  `lib/AidInstallCore.psm1`) and removes `.aid/` only if it is then empty. `.aid/STATE.yml` is not added
  to that deletion -- it holds the user's answers -- so it stays, and keeps `.aid/` in place, as
  `.aid/knowledge/` and `.aid/works/` do. A case in `tests/canonical/test-shared-remove.sh` checks it.
- **KB file**: questions while building the KB keep today's place (`.aid/knowledge/STATE.md`
  § Q&A (Pending)) until Feature 004 converts it to `.aid/knowledge/STATE.yml`, which then carries the
  same `qa` shape (Q39).

##### 3. Question protocol

`question-protocol.md` holds the procedure once. It runs only in the main conversation, the only one
that can talk with the user.

**Where it applies and how skills use it**
- `rules.md` (read in every session) points at it. The last bullet of § Handling a request becomes two
  lines, so the section counts 19 of its 20 lines by SG-01's rule:
  ```markdown
  - Ask only as `.aid/runtime/templates/question-protocol.md` says; the user approves before building
    and the result; AID never merges.
  ```
- Every skill that talks with the user carries one line: "Talking with the user: follow
  `.aid/runtime/templates/question-protocol.md`." The generated doorway skills get it from
  `shortcut-engine.md`, which they run; `skill-steps.md` makes every `ASK` step use it.
- **Sub-agents never ask the user**: the `## Talking with the user` section of
  `canonical/aid/templates/agent-boilerplate.md`, inlined into every agent, says so -- a sub-agent records
  its open questions (`--ask`, left `Pending`) and lists them in its report; the main conversation asks
  them. This is what lets the interviewer agent go; SS-10 checks it.
- **One plain-text form in all five tools.** The host's own question picker (`AskUserQuestion` in
  today's `aid-config`, `aid-set-connector`, ticket skills, `aid-summarize` and `aid-housekeep`) is no
  longer used, so every question shows its reason and recommendation the same way everywhere.

**One question**

```text
Connections -- question 2 of 3 -- importance: high
Should AID reach your Jira through the connection your tool already has?
Why I ask: AID stores no passwords, so it needs your tool's own connection.
My recommendation: yes -- your tool is already signed in to Jira.
  1. Yes, use my tool's connection (recommended)
  2. Not now, skip Jira
Or answer in your own words, ask me to explain, or skip this question.
```

- One question, one topic; short, with **Why I ask** (FR-17 rules 1-2).
- The lower technical level is assumed in every session; deeper detail only on request; the level is
  not stored (rule 3).
- Always **My recommendation**, with its reason (rule 4).
- Options only when two or more are valid, the recommended one first; with one valid option the question
  becomes a confirmation ("I'll do X because Y -- all right?"); no question whose answer is obvious; the
  closing line always allows a free answer, an explanation or a skip (rule 5).
- **Importance**: high, medium or low (AC-8); the most important first.
- **Groups**: open questions sorted by subject, then importance; one subject per group, 3 to 5 questions.
  Small subjects merge into one group only when they are genuinely related (e.g. naming and skill
  descriptions); otherwise a small group stands (rule 6, Q37).
- **Breaks**: offered after each group and at every change of subject -- "That's all on {subject}. Take a
  break, or go on to {next}?" (rule 7). A break offer decides nothing and is not recorded.
- **Follow-ups** come right after the question that raised them, inside the same group (rule 8).
- **Already answered** by an earlier answer, or made trivial by it: not asked; recorded `Assumed`, with
  the reason (rule 9).

**Reviews and small decisions** (AC-9)
- A document is reviewed in chunks: one topic per chunk, most important first; each chunk is a short
  plain summary plus the decisions inside it; then one approval question.
- Small decisions the agent takes itself are recorded `Assumed` and confirmed **in one batch with the next
  approval that covers them**: the document's approval in `full`, the confirmation before building in
  `lite`, the next milestone during building. No extra approval (Q36). An item the user rejects reopens as
  an ordinary question.

**The question record** -- one shape for the work, project and KB files (rule 10):

```yaml
qa:
  - id: Q12
    category: Connections
    impact: High
    state: Answered
    asked_by: aid-set-connector
    step: --
    context: 'Reach Jira through the tool''s own connection? AID stores no passwords'
    suggested: 'Yes -- the tool is already signed in to Jira'
    answer: 'Yes'
    answered_by: 'Andre Vianna'
    applied_to: 'connector jira'
```

- `category` is the subject the groups follow; `impact` is the importance label (`High`, `Medium`,
  `Low`; `Required` retires).
- `state`: `Pending` (asked, open), `Answered`, `Skipped` (still open: offered again later to whoever
  continues the work), `Assumed` (the agent's own decision, waiting for its batch; `Answered` once confirmed).
- New keys: `asked_by`, `step` (where to resume), `answered_by` (`git config user.name`, or `--`).
  Approval entries add `covers` and `commit` (Approvals).
- Every question is written `Pending` before it is shown (`--ask`), and its outcome right after the
  answer (`--answer`). **One exception -- intake questions:** questions asked **while starting or choosing a work** -- by
  `/aid-orchestrate`, the gate, or a starter before `--create` ("what do you
  want?" on a bare slash start, which skill fits when the reading is unsure, new work or continue an existing
  one, a work's short name) are not written with `--ask`, because there is no work record yet. Their
  outcome is recorded where it lands: a new work's `intent` and name in the record `--create` writes, or
  the chosen work's own record on resume -- so rule 10 is met there. If the user does not answer, nothing
  is created and nothing needs resuming. Questions from setup skills and from building the KB are **not** intake questions:
  they follow the next bullet (`.aid/STATE.yml` and the KB state file). `question-protocol.md` and `protocol-checks.md` state this
  exception, so the judge does not fail samples `002-14`, `002-16` and `002-18` on it. On start or resume, the open entries (`Pending`, `Skipped`) come first, in the
  usual groups -- `start-or-resume.md` gains this step.
- Where: a work's questions in its `STATE.yml`; KB building in the KB state file; setup skills
  (configure, connectors) in `.aid/STATE.yml`.

`aid-describe` keeps its interview engine until Feature 003 replaces it: the envelope section of its
`advisor-stance.md` becomes a pointer to the protocol, and the envelope's "Not applicable" option goes
(rule 5).

##### 4. Steps and hand-offs

`skill-steps.md` is the one rule set (FR-20.4). A skill keeps only its step table (Dispatch: step,
reference, worker, next) and a fallback detection from its artifacts; no skill restates how to move.

Advance words (the `**Advance:**` line of every step; internal, never shown to the user):

| Word | Meaning | Replaces |
|---|---|---|
| `CHAIN` | Go on to the next step now | `CHAIN` |
| `ASK` | Stop for the user through the question protocol, then continue to the step the line names once answered | `PAUSE-FOR-USER-DECISION`, without "re-run the command" |
| `WAIT` | The user must do something outside the conversation; say what, plainly | `PAUSE-FOR-USER-ACTION` |
| `PASS` | End of this skill's process: hand the work to the next skill | (new) |
| `CALL` | In the middle of the process: hand the work to another skill, then come back to this step | (new) |
| `HALT` | This run is finished -- after returning to an open call, if there is one | `HALT` |

Each step:
1. **Enter**: the main conversation runs `writeback-state.sh --step --skill <skill> --name <STEP>
   [--detail '<where>']` before doing or dispatching the step's work (FR-20.2).
2. **Work**: inline or by a worker; a worker returns its questions, never asks them.
3. **`ASK`**: save the step the `**Advance:**` line names as the next one (`--step`, with `--detail
   'waiting for Q12, Q13'`); record the questions (`--ask`); set `lifecycle: Paused-Awaiting-Input` with
   `pause_reason: 'Waiting for the user: Q12, Q13'`; ask. Answered in the same conversation: record the
   answers, back to `Running`, and continue to that step in the same run. Answered later: the session that
   resumes finds the saved step and the open entries, asks them first, then continues there.
4. **`PASS`**: if the approvals table requires an approval here at the work's depth, `ASK` it first. Then
   `--handoff --to <skill> --step <its entry step> --why '<reason>' --returns no --phase <phase>`, and start that skill in the same
   turn (FR-8); where a tool cannot start a skill itself, name the command (Feature 001's fallback). This is
   how Definition reaches Specification without the user typing a command (AC-38).
5. **`CALL`**: bring `--detail` up to date with what is done, then `--handoff --to <skill> --step <its entry
   step> --why '<reason>' --returns yes`. The called skill runs as usual; `phase` does not change.
6. **`HALT`**: with an open call, `--handoff-return` restores the caller's skill, step and detail, and the
   caller continues there (AC-38). Calls nest; the newest returns first. Without one, the run ends.

**Resume** (any session, any user): only the work record decides where the work continues -- the saved
`active_skill`, `step` and `step_detail`; an open call means it continues inside the called skill. A
skill's own artifact detection never routes: it only shapes the entry step of a skill starting fresh, and
validates a saved step against disk on resume (Work state layout, The work record). `skill-steps.md` § The work record holds these
rules once: when the record is written, fail-closed, starting versus resuming, and recovery.

**What the user sees** (FR-20.1, AC-37):
- Removed everywhere: `[State: X] -- ...` entry lines, "you are here" maps, "-> Advancing to [State: X]",
  "[State N] Dispatching ..." and "[Resolved: ...]" lines, and "Re-run `/aid-...` to continue" messages.
  `[State: X]` survives only as a target inside `**Advance:**` lines, which the site flow builder reads.
- At most one plain progress line, when a step starts work that takes noticeable time ("Checking the plan
  against the Knowledge Base."); never a step name.
- "Where are we?" is answered from `STATE.yml`: phase, what is done, what is next, open questions, an open call.

**Today's skills**: banners removed, `skill-steps.md` cited in place of the chaining file, advance words
translated one for one: `PAUSE-FOR-USER-DECISION` -> `ASK`, keeping the step it named ("Re-run
`/aid-<skill>` to continue to [State: X]" becomes `ASK` -> [State: X]); `PAUSE-FOR-USER-ACTION` -> `WAIT`,
keeping its step the same way. A pause that today ends the skill and points at another one (e.g.
`aid-describe` COMPLETION -> `/aid-define`) becomes `ASK` then `HALT`, with that skill named in one plain
line, until the rebuilt phase skill turns it into a `PASS`. They gain no new `PASS` or `CALL` edges: the
rebuilt phase skills of Features 003-008 add those (Q35).

**Writer modes** in `writeback-state.sh` -- same lock and quoting as today, block style only; a write
either completes or leaves the file untouched (it writes a temporary copy and renames it into place under
the lock). New exit codes, documented in its header: 7 (no open call), 8 (`STATE.yml` already exists),
9 (`--check` found a problem). They are scripts, not prose, because every skill runs
them and the hand-off bookkeeping must be exact (decisions.md § D17):

| Mode | Writes |
|---|---|
| `--create --work-dir W --reading R --request T --skill S --step N [--phase P] [--depth D] [--path P] [--minimum-grade G]` | run only by the gate; copies `work-state-template.yml` into W and fills `intent.reading`, `intent.request`, `intent.depth`, `active_skill`, `step`, `pipeline.initiator` (S), `phase` (`--` when omitted: an on-demand skill drives no phase), `lifecycle: Running`, `started`, `updated` in one write; exit 5 when a required option is missing, 4 when a value is invalid, 8 when W already holds a `STATE.yml` |
| `--step --skill S --name N [--detail D]` | `active_skill`, `step`, `step_detail` (`--` when omitted), `updated` |
| `--reroute --reading R [--depth D] --why W` | `intent.reading` (and `intent.depth`), plus an `intent.changes` entry (at, from, to, why) |
| `--check` | writes nothing; prints one line per problem with the record (missing or inconsistent, Work state layout) and exits 9 when there is any, 0 otherwise |
| `--repair --skill S --name N [--detail D] [--reading R]` | the record in one write, plus a `lifecycle_history` entry naming the old and the new record; `--reading` is required when the record has none (exit 5); used only after the user confirms |
| `--handoff --to S --step N --why W --returns yes` | appends a `handoffs` entry whose `from*` keys are the current skill, step and detail; sets `active_skill` to S and `step` to N (S's entry step), `step_detail` to `--`, in the same write |
| `--handoff --to S --step N --why W --returns no [--phase P]` | the same, plus `phase` P (validated) when given; without `--phase` the phase stays -- a typed start of another skill, or a pass to an on-demand skill |
| `--handoff-return` | sets `returned` on the open call; restores `active_skill`, `step`, `step_detail` from it; exit 7 when there is none |
| `--ask --category C --impact I --context T --suggested T [--asked-by S] [--step N] [--covers X] [--project]` | appends a `Pending` entry; prints its id (the next free `Q<n>`) |
| `--answer --id Q<n> --state Answered or Skipped or Assumed [--value T] [--by B] [--applied-to T] [--commit C] [--project]` | updates that entry |

`--project` targets `.aid/STATE.yml`, created from its template when missing; without it the target is
the work's `STATE.yml`, resolved as today (`AID_STATE_FILE`).

**Review focus (FR-21).** `canonical/agents/aid-reviewer/AGENT.md` and the shared review instructions
(`canonical/aid/templates/reviewer-dispatch.md`, and every skill's `references/reviewer-brief.md`) gain one
short "What to report" rule: only issues that affect the work -- a step that cannot be built, a check that
would fail on the real files, a contradiction with another part of the document or a user decision.
Exact counts, word-for-word comparisons and wording or cosmetic points are not findings. The rule sits under a
`### What to report` heading in each of those files. Static check **SS-13** fails if any of them lacks that
heading (a presence check -- it does not scan wording, so the rule's own text and existing lines such as
`aid-discover`'s "render ... verbatim" do not trip it).

##### 5. Approvals and the merge boundary

`skill-steps.md` § When approvals happen states the FR-6 approvals once for AID; how a milestone runs is
`/aid-execute`'s (Feature 007) and the push is `/aid-monitor-pipeline`'s (Feature 008).

| Moment | `full` | `lite` |
|---|---|---|
| The idea draft, when one is written (Definition) | approve | -- |
| `REQUIREMENTS.md` (Specification) | approve | -- |
| `PLAN.md` (Planning) | approve | -- |
| Confirmation before building -- opens `/aid-execute`; the per-wave option is asked here | approve | approve |
| End of each wave -- only when chosen | approve | approve |
| End of each delivery | approve | approve |
| End of the whole build | approve | approve |
| The final result | approve | approve |

- **Approvals at the same moment are one approval** (M11) -- on a one-delivery work, the delivery,
  whole-build and final-result approvals.
- **Each approval also confirms the small decisions it covers** (Q36). It is recorded as a `qa` entry
  with `category: Approval`, `covers` (the document or milestone) and, when a push may follow, `commit`
  (the newest commit it approves). The final-result approval also sets `user_approved: 'yes'`.
- **Who applies it**: the main conversation, at each phase skill's last step (`ASK` then `PASS`, or
  straight `PASS`) and at `/aid-execute`'s milestones. The depth is `intent.depth`; with none recorded,
  `full` applies.
- **Before the push it controls**: a push carries only commits up to the newest approved `commit`;
  `/aid-monitor-pipeline` makes the push and checks this.
- **AID never merges** (FR-6, FR-7, AC-11): no skill or script merges a branch or a PR/MR, and a PR/MR
  is created only on the user's yes, by `/aid-monitor-pipeline` alone. Stated in `skill-steps.md` and in
  `rules.md`; enforced by `test-never-merges.sh` (Testing).

##### 6. Dashboard and chat

- **Both readers** (`dashboard/reader/` and `dashboard/server/reader.mjs`, kept equal by the parity tests):
  - `phase`: the new names; the old ones mapped as in Work state layout; anything else reads `Unknown`, as today;
  - `qa`: read at work level on every layout; open = `Pending` + `Skipped`; delivery `qa` still merged
    until Feature 006;
  - new work fields: `step`, `step_detail`, and the open call (where the work went, why, which phase it
    returns to).
- **Python files**: `models.py` gains the three fields on the work model; `parsers.py` reads them and
  `qa` on every layout; `reader.py` passes them into the work model it builds and merges the work-level
  `qa` on the full layout too (today it merges only delivery `qa` there); `dashboard/server/server.py`
  `_ser_work` adds `step`, `step_detail` and `open_call` to the fixed field list it sends to the page.
- **Node files**: `reader.mjs` does the same in its parser and in every place it builds a work object;
  `server.mjs` passes the work object through unchanged.
- **`dashboard/home.html`** -- its phase sites:
  - `PHASE_ORDER` becomes `['Definition', 'Specification', 'Planning', 'Building', 'CI']`;
  - `PRE_EXEC_STEPS` becomes 3 (Definition, Specification, Planning), with its comment;
  - `_renderLiteStageRail`: `LITE_STAGES` becomes `['Specification', 'Building', 'CI', 'Done']`; the stage
    is Done when `lifecycle` is `Completed`, else `Building` or `CI` when `phase` is that name, else
    Specification; the comments above `renderStageRail` and `_renderLiteStageRail` that name the old
    phases are rewritten with it.
  The readers hand the page only new names, so the page holds no old-name mapping. The work card shows the
  phase, one plain line from `step_detail`, "Waiting for your answer (N)" when open questions exist, and
  "Away in /aid-update-kb -- back to Building after" while a call is open. No step names, no maps.
- **Work record warning**: both readers compute `record_status` (`ok`, `missing`, `inconsistent`) with the
  field rules of `--check` (the installed-skill rule stays with `--check`, which knows the tool's skills
  folder); `_ser_work` and `reader.mjs` pass it on, and the work card shows a visible warning -- "This
  work's record is incomplete: the agent will ask you to confirm a repair when the work resumes" -- for any
  status other than `ok`. Works not yet migrated show it too, until Feature 006's migration fills their record.
- **Chat**: `chat-node/` reads no work state -- no `.aid/works/` path, no `STATE.yml` -- so nothing changes
  (AC-41); SS-07 keeps it so.
- The skill names shown are Feature 009's (AC-31).

##### 7. Migration

| Old | New |
|---|---|
| agent `aid-interviewer` | The agent in your tool asks the questions itself, one topic at a time (question protocol) |
| `/aid-describe --reset work-NNN` | Cancel the work and start a new one (say what you want; the agent starts it through the gate) |

- **Release notes**: the row joins the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md`
  § Next Release. `state-machine-chaining.md` is internal: no row.
- **Installed projects**: `aid update` removes the agent's files through the install manifest
  (decisions.md § D9).
- **Existing works**: nothing is rewritten here -- the readers map the old phase names and still read
  delivery `qa`. An old work has no work record, so its first resume goes through the recovery path (a
  confirmed repair proposed from the gate's legacy block) and the dashboard shows the record warning.
  Feature 006's migration fills the record for every old work, rewrites the phase names, moves delivery `qa`
  into the work, drops `pipeline.path`, and then removes the gate's legacy block.
- **Interviewer sites** (a full search for `interviewer`, any case, outside work folders and renders):
  those in Files and layout, plus `docs/aid-methodology.md`, `docs/diagram-content-reference.md`,
  `examples/brownfield-lite-path/README.md` (its CONDENSED-INTAKE walk-through), `examples/greenfield/README.md`,
  the site pages `reference/agents.md`, `concepts/methodology.md` and `skills/aid-describe.md` under
  `site/src/content/docs/`, the regenerated flows `aid-describe.flow.json` and `aid-define.flow.json`,
  `tests/canonical/test-describe-full-only.sh` and `tests/cost-baseline.tsv`; KB `architecture.md`,
  `module-map.md` and `pipeline-contracts.md`. The `profiles/*` and dogfood copies (`.claude/agents/`,
  `.cursor/agents/`) and `.aid/.aid-manifest.json` follow the render. Left as they are:
  `canonical/aid/scripts/summarize/validate-diagram-content.mjs` (it only masks the name, outside SS-05's
  scope), `.aid/knowledge/release-tracking.md` (shipped history) and `.aid/knowledge/kb.html` (regenerated).
  The `aid-orchestrator` agent and `tests/canonical/test-triage-routing.sh` are already gone with Feature 001.
- **Chaining-file sites**: the `SKILL.md` of `aid-create-ticket`, `aid-define`, `aid-deploy`,
  `aid-describe`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-housekeep`, `aid-monitor`, `aid-plan`,
  `aid-specify`, `aid-summarize`, `aid-update-kb`, `aid-update-ticket`; `aid-discover`
  `references/state-elicit.md` and `references/state-generate.md`; `shortcut-engine.md`;
  `connectors/ticket-resolution.md`; `tests/canonical/test-pipeline-status-walkthrough.sh` (group B2 moves to
  `skill-steps.md`'s `ASK` handler); `tests/cost-baseline.tsv`, `tests/coverage-baseline.tsv`; the regenerated
  `aid-discover.flow.json`; KB `architecture.md`.
- **Banner and advance-word sites**: every file the SS-01 and SS-03 searches find under `canonical/`,
  fixed at the source: the hand-authored files and the two shared engines (the generated doorway skills
  carry no banner of their own). The `writeback-state.sh` header's "<- you are here (edit this)" becomes "<- this is the source
  (edit this)". `site/scripts/__tests__/flow-advance.test.mjs` learns the new words.
- **Question-record sites** (Files and layout): this resolves the question-record slice of tech-debt
  SY-6; the AD13 ratchet ceilings in `tests/canonical/test-artifact-discipline.sh` drop to the new
  measured counts.
- **Other suites**: `tests/canonical/test-writeback-state.sh` and `test-pipeline-status-walkthrough.sh`
  (phase names), `dashboard/server/tests/test_index_html.py` (`PHASE_ORDER`). Removed assertions go to
  `tests/coverage-accepted-removals.tsv`; `tests/cost-baseline.tsv` drops the deleted agent and template
  and adds the two new templates.
- **KB** (no work ids): `architecture.md` (state machines, the agent table), `module-map.md` (the agents
  row), `pipeline-contracts.md`
  (§ Per-Skill State Machines rewritten -- its "one invocation advances one state" claim is stale today),
  `artifact-schemas.md` (the new keys, `qa`, `handoffs`, `.aid/STATE.yml`, phase names),
  `domain-glossary.md` (question protocol, step, hand-off; the interviewer goes), `decisions.md` (a new
  decision -- one question protocol run by the main conversation, saved steps, pass and call -- which
  supersedes the chaining rule and amends D15's agent count), `test-landscape.md` (the new
  suites and the deferred-tests list), `tech-debt.md` (SY-6 narrowed); then `INDEX.md` is regenerated.

##### 8. Testing

Per NFR-T (Q35): unit tests and static checks run now; a conversation sample runs only when every skill it
needs exists, and until then it is listed in the deferred-tests list.

**Static checks -- `tests/canonical/test-skill-steps.sh`** (picked up by `tests/run-all.sh`; added to the
suite list of `.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| SS-01 | No banner form (Steps and hand-offs) under `canonical/skills/` or `canonical/aid/templates/` |
| SS-02 | `state-machine-chaining.md` is absent and cited nowhere; every `SKILL.md` with a Dispatch table or a `## State:` section, and `shortcut-engine.md` and `design-lifecycle.md`, cite `skill-steps.md`, whose step-entry rule writes the record before any work in the step |
| SS-03 | No `**Advance:**` line uses a word other than `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL`, `HALT` (a line naming only its next step is a `CHAIN`, as today) |
| SS-04 | Every hand-authored `SKILL.md`, and `shortcut-engine.md` for the generated ones, cites `question-protocol.md`, except the test's never-asks list (each listed skill must exist); no `AskUserQuestion` in any `allowed-tools` |
| SS-05 | No `canonical/agents/aid-interviewer/`; the word `interviewer`, in any case, appears nowhere in `canonical/agents/`, `canonical/skills/`, `canonical/aid/templates/`, `docs/`, `examples/` or `site/src/content/` |
| SS-06 | No file under `canonical/skills/` names `## Cross-phase Q&A` or sends a question to a delivery-level `qa` (the migration scripts, which must read the old shapes, are outside its scope) |
| SS-07 | Nothing under `chat-node/` names `.aid/works` or `STATE.yml` |
| SS-08 | `work-state-template.yml` and `project-state-template.yml` parse through the dashboard reader with no warning |
| SS-09 | Every asking skill -- each skill that cites the protocol, and the generated doorway skills through `shortcut-engine.md` -- has a sample whose frontmatter `skills:` names it and whose `covers` holds AC-28, or a `skill:` row of the deferred list matching it (the table below) |
| SS-10 | `canonical/aid/templates/agent-boilerplate.md` has the `## Talking with the user` section; every `canonical/agents/*/AGENT.md` includes `{{include:agent-boilerplate}}`; no `AGENT.md` tells its agent to ask the user (`AskUserQuestion`, "ask the user") |
| SS-11 | No old phase name (`Describe`, `Define`, `Specify`, `Plan`, `Detail`, `Execute`) as data or logic. **Scope**: tracked files under `canonical/skills/`, `canonical/aid/templates/`, `canonical/aid/scripts/` (except `summarize/`, whose diagram tokens are text), `dashboard/home.html`, `dashboard/reader/*.py`, `dashboard/server/*.mjs`, `dashboard/server/*.py`, `dashboard/scripts/writeback-state.sh` -- never a `tests/` or `__tests__/` folder. **Forms**: `phase: <old>`; `--field Phase --value <old>`; a quoted `'<old>'` or `"<old>"`; an enum list `<old> \| <old>`; `Phase.<old>`; `=== '<old>'`; a backticked old name on a line that mentions the phase. **Excluded**: lines between `legacy-phase-map: begin` and `end` markers (the two readers' maps and the gate's old-name rows). Run on today's tree, these forms reach 55 lines, all of them listed in the phase-sites table or the page's sites; only the deploy sentence, prose split over two lines, is listed without being reachable |
| SS-12 | No hand-written finish: no line matching `lifecycle: (Completed\|Canceled)` (any quoting) in tracked files under `canonical/skills/` and `canonical/aid/templates/`, except files of entries on the shared exempt list marked for SS-12. Lives in `tests/canonical/test-skill-steps.sh`. |
| SS-14 | The gate is the only creator and the writer the only writer of the work record. (a) `work-initiation-gate.md` § 3a runs `writeback-state.sh --create` with `--reading`, `--skill` and `--step`. (b) No tracked file under `canonical/skills/` or `canonical/aid/templates/` -- except `work-state-template.yml`, `project-state-template.yml`, `delivery-state-template.yml`, `task-state-template.yml` and `work-initiation-gate.md` -- has a line matching `initiator:` (only a creator writes it), `[Cc]opy.*work-state-template\.yml` or ``work-state-template\.yml` to\b`` (copying the template), or `^(active_skill\|step\|step_detail\|phase):` (a hand-written record block). Files of entries on the shared exempt list marked for SS-14 are skipped. Run on today's tree, every file (b) matches is in Files and layout, as a converted allocation point or an exempt per-skill file; once this feature lands it matches only the exempt per-skill files. (c) `skill-steps.md` § The work record carries the fail-closed and recovery rules. (d) No tracked file under `canonical/skills/` or `canonical/aid/templates/` other than `work-initiation-gate.md` routes a continuation itself: no line matching `resume door\|\`?phase\`?-matched\|[A-Z][a-z]+-phase work\|route per the chosen work`. Run on today's tree, (d) matches exactly the continuation lines listed in Files and layout, and none after this feature. Lives in `tests/canonical/test-skill-steps.sh`. |
| SS-13 | Each of `canonical/agents/aid-reviewer/AGENT.md`, `canonical/aid/templates/reviewer-dispatch.md` and every `canonical/skills/*/references/reviewer-brief.md` (today: `aid-define`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-plan`, `aid-specify`) has a `### What to report` heading (FR-21). Presence check only. Lives in `tests/canonical/test-skill-steps.sh`. |

**Shared exempt list -- `tests/canonical/skill-steps-exempt.tsv`** (tab-separated: `entry` -- a skill
folder name or a `canonical/` path --, `checks` -- `SS-12`, `SS-14` or both --, `owner` -- the feature that
rebuilds or retires it). One list serves SS-12 and SS-14: `test-skill-steps.sh` fails when an entry no
longer exists on disk (its feature landed: the row goes), and under `AID_RELEASE_CHECK=1` while the list
is not empty. Its rows are the exempt per-skill files of Files and layout (SS-14) and the exempt finishers
of Work state layout (SS-12); the converted allocation points are not on it (`aid-design` stays only for
SS-12, for its hand-written finish).

**Static checks -- `tests/canonical/test-never-merges.sh`**, over the tracked files (`git ls-files`) that
match:
- **include**: `canonical/**`, `bin/**`, `lib/**`, `dashboard/**`, `chat-node/**`, `scripts/**`,
  `release.sh`, `install.sh`, `install.ps1`;
- **exclude**: every path with a `tests/` or `__tests__/` folder at any depth (`**/tests/**`,
  `**/__tests__/**` -- their fixtures name merge commands on purpose, e.g. the dashboard reader's
  mutating-verb lists), and the document templates `canonical/aid/templates/knowledge-summary/**` and
  `canonical/aid/templates/knowledge-base/**`, whose example commands and placeholder rows are text for a
  reader, not instructions.

| Group | Asserts |
|---|---|
| NM-01 | No `git merge` (`git merge-base` excepted) and no `git pull` without `--ff-only` |
| NM-02 | No `gh pr merge`, `glab mr merge`, call to a hosting service's merge endpoint (`pulls/<n>/merge`, `merge_requests/<n>/merge`), or `git push` naming `main` or `master` as its target |
| NM-03 | `gh pr create` / `glab mr create` only under `canonical/skills/aid-monitor-pipeline/`; exempt: `aid-housekeep` (`references/state-done.md`), until Feature 004 retires it; fails once an exempt skill is gone |
| NM-04 | No "merge to main" under `canonical/skills/`; exempt: `aid-execute` (`SKILL.md`, `references/reviewer-brief.md`, `references/state-delivery-gate.md`), until Feature 007; same rule |

Run against today's tree with these globs, only the two exemptions fire.

**Deferred tests -- `tests/conversation/deferred.tsv`** (tab-separated: `test`, `covers`, `waiting_for`,
`needs`) **and `tests/canonical/test-deferred-tests.sh`**. A row's `test` is either a sample written now
that needs skills a later feature brings (`samples/feature-002/<id>`), or `skill:<name or glob>` -- the
AC-28 sample owed for a skill a later feature rebuilds or retires, which that feature writes (or the row
goes with the skill).

| Group | Asserts |
|---|---|
| DT-01 | Every row has a criterion and a `waiting_for`; a sample row names an existing file under `tests/conversation/samples/`; a `skill:` row matches at least one folder under `canonical/skills/` |
| DT-02 | With `AID_RELEASE_CHECK=1` the list must be empty -- set on the `run-all.sh` step of `.github/workflows/release.yml` and in `release.sh`'s checks before it stages |

A row leaves the list when what it waits for has landed and its sample passes 3 runs of 3.

**Asking skills and their AC-28 coverage** (as they stand once Feature 002 lands: `aid-triage` is gone and
`/aid-orchestrate` exists, both from Feature 001):

| Skills | Covered by |
|---|---|
| `aid-orchestrate`, `aid-set-connector`, `aid-config`, `aid-read-ticket`, `aid-research`, `aid-review`, `aid-report`, `aid-monitor` -- no later feature rebuilds or retires them | Feature 002 samples, now (table below) |
| `aid-brainstorm`, `aid-describe` | `skill:` rows waiting for Feature 003 |
| `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`, `aid-housekeep`, and `aid-create-` / `aid-update-` for `architecture`, `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog`, `mvp` | rows waiting for Feature 004 |
| `aid-define`, `aid-specify` | rows waiting for Feature 005 |
| `aid-plan`, `aid-detail`, `aid-deploy` (its delivery inputs change with the single layout) | rows waiting for Feature 006 |
| `aid-execute` | a row waiting for Feature 007 |
| `aid-design`, `aid-design-*`, `aid-create-ticket`, `aid-update-ticket`, `aid-create-diagram`, `aid-create-document`, `aid-document`, `aid-document-*`, `aid-update-document`, `aid-test`, `aid-test-*`, `aid-prototype`, `aid-prototype-ui`, and the generated doorway skills (through `shortcut-engine.md`) | rows waiting for Feature 009 |
| Never asks: `aid-chat` (it talks with other agents, not the user), `aid-unset-connector` (no question in its flow) | the test's never-asks list (SS-04) |

**Unit tests**
- `tests/canonical/test-writeback-state.sh`: `--create` writes type, skill, step, phase and lifecycle in
  one write, and exits 5, 4 or 8 on a missing option, a bad value or an existing `STATE.yml`; a write that
  fails (lock timeout, exit 2; unwritable file) leaves the file byte-for-byte unchanged; `--check` reports
  each missing and inconsistent case with exit 9, and 0 on a healthy record; `--repair` writes the record
  and its history entry; `--reroute`; `--step`; `--handoff` as call, as pass with `--phase`, and as pass without it (phase
  unchanged, no open call left); `--handoff-return`
  with two nested calls (newest first) and exit 7 with none; `--ask` id numbering, and `--project` creating
  `.aid/STATE.yml`; `--answer` for each state, including an approval's `--covers` / `--commit`; the phase
  names (an old name refused on write); every file written parses through the dashboard reader with no warning.
- Dashboard: fixtures for a work at each phase -- Definition, Specification, Planning, Building, Building
  during a call, CI, Completed -- one with old phase names, and one each with a missing and an inconsistent
  record (`record_status` and the card warning), in `dashboard/reader/tests/` and the Node
  suite, plus a parity test; `test_index_html.py` for `PHASE_ORDER` and the card lines.
- Dashboard page: a new Node test, `dashboard/server/tests/test_home_stage_rails.mjs` (standard library
  `node:vm`), takes `PHASE_ORDER`, `renderStageRail` and `_renderLiteStageRail` from `home.html` by name,
  runs them against a small stand-in for the page, and checks the marked stage for a full and a lite work
  at each phase -- e.g. a lite work at `Building` marks the Building stage, not the first one.
- Site: `flow-advance.test.mjs` for the new words.

**Conversation samples -- `tests/conversation/samples/feature-002/`** (frontmatter adds `skills:`). The
judge also applies `tests/conversation/protocol-checks.md` -- one check per FR-17 rule, plus the importance
label -- to every sample, of any feature, that covers AC-8 or AC-28.

| Sample | Covers | Runs |
|---|---|---|
| `002-01-connector-question` -- a non-technical user connects a tracker (`/aid-set-connector`) | AC-8, AC-28 | now |
| `002-02-settings-groups-and-breaks` -- settings across several subjects (`/aid-config`) | AC-8, AC-28 | now |
| `002-03-follow-up-and-skip-answered` | AC-28 | now |
| `002-04-skip-then-another-user` -- two sessions, two personas; check: the entry in `.aid/STATE.yml` goes `Skipped` -> `Answered` with a different `answered_by` | AC-28 | now |
| `002-05-merge-request-declined` -- fixture: a work branch; "merge it into main"; check: `main` unchanged, no merge command run | AC-11 | now |
| `002-14-orchestrate-unsure-reading` -- a request two skills fit equally (`/aid-orchestrate`) | AC-8, AC-28 | now |
| `002-15-which-tracker` -- two trackers catalogued (`/aid-read-ticket`) | AC-28 | now |
| `002-16-research-without-a-question` (`/aid-research`) | AC-28 | now |
| `002-17-review-publish-approval` (`/aid-review`) | AC-28 | now |
| `002-18-report-what-to-analyze` (`/aid-report`) | AC-28 | now |
| `002-19-monitor-finding-question` (`/aid-monitor`) | AC-28 | now |
| `002-20-record-recovery` -- fixture: a work whose saved step names an artifact that is not on disk; the user asks to continue; check: the agent says so, proposes the repaired record as one question, writes nothing before the yes, then resumes there | AC-37 | now |
| `002-21-cancel-work` -- fixture: an open work; the user says "cancel work-NNN"; check: no new work is created, the agent asks one confirmation question, and only after yes the record shows `lifecycle: Canceled` with no saved skill; the next resume reports the work as finished (runs now) |
| `002-06-review-in-chunks` | AC-9 | deferred: Feature 005 |
| `002-07-small-decisions-with-approval` | AC-9, AC-10 | deferred: Features 005, 007 |
| `002-08-full-confirms-each-document` | AC-10 | deferred: Features 003, 005, 006, 007 |
| `002-09-lite-one-approval` | AC-10 | deferred: Features 005, 006, 007 |
| `002-10-pull-request-only-when-asked` | AC-11 | deferred: Feature 008 |
| `002-11-resume-at-saved-step` -- interrupted session; check: no banner text, resumes at the saved step | AC-37 | deferred: Feature 005 |
| `002-12-definition-passes-to-specification` | AC-38 | deferred: Features 003, 005 |
| `002-13-mid-task-kb-update-returns` | AC-38 | deferred: Features 004, 007 |

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-8 | Question protocol (one question, rules) | SS-04; `002-01`, `002-02`, `002-14`; `protocol-checks.md` |
| AC-9 | Question protocol (reviews and small decisions) | `002-06`, `002-07` (deferred) |
| AC-10 | Approvals and the merge boundary | writer unit tests (approval record); `002-07`, `002-08`, `002-09` (deferred) |
| AC-11 | Approvals and the merge boundary (never merges) | NM-01 to NM-04; `002-05`; `002-10` (deferred) |
| AC-28 | Question protocol | `002-01` to `002-04`, `002-14` to `002-19`; SS-09 with the coverage table (a sample or a `skill:` row per asking skill); `protocol-checks.md` |
| AC-37 | Steps and hand-offs (what the user sees, resume); Work state layout (The work record) | SS-01, SS-02, SS-14; writer unit tests (`--create`, `--step`, `--check`, `--repair`, failed writes); gate `--check` fixtures; `002-20`; `002-11` (deferred); `002-21` |
| AC-38 | Steps and hand-offs (`PASS`, `CALL`, `HALT`) | writer unit tests (`--handoff`, `--handoff-return`, nesting); `002-12`, `002-13` (deferred) |
| AC-40 | Question protocol (sub-agents never ask); Migration | SS-05, SS-10 |
| AC-41 | Dashboard and chat | dashboard fixtures and parity test; SS-07 |
| AC-46 | Steps and hand-offs (Review focus) | SS-13 |

### Feature 003 — Shape an Idea or Ticket into a Clear Work Definition

- **Priority:** Must
- **Requirements:** §4 Scope; §5 FR-1, FR-9, FR-11
- **Criteria:** AC-17, AC-43

#### Description

`/aid-brainstorm` shapes an idea with the user, across sessions if needed -- also for a specific kind of thing (an API, a UI, a data model, ...), using the catalog's rules for that kind, which replaces today's `/aid-design-*` skills; a ticket or other external source can feed it, as it can any phase (FR-18). The shaped idea lives in `.aid/design/` and is deleted once its requirements are approved. Absorbs today's describe step.

#### User Stories

- As an AID user, I want to shape an idea across sessions, or hand over a ticket, and have it turned into a clear starting point, so that work begins from a well-understood problem.

#### Technical Specification

Serves §4 Scope (`/aid-design` retires, Q22), FR-1 (the Definition phase), FR-9 and FR-11, and follows
FR-17, FR-18 and FR-20 as Features 001 and 002 define them. Maintainer decisions: Q44-Q50. Paths are
`canonical/` sources, rendered as in Feature 001. "Idea draft" is the plain name for FR-9's seed; the
folder keeps its name, `.aid/design/`.

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Rewrite | `canonical/skills/aid-brainstorm/SKILL.md` | The Definition phase skill: its step table (see Flow), `skill-steps.md` and `question-protocol.md` cited, `description:` in Feature 001's what/when shape (see Components), `argument-hint: "[<kind>] <idea>"`. At most 100 lines |
| Create | `canonical/skills/aid-brainstorm/references/` | `start.md`, `converse.md`, `check.md`, `reviewer-brief.md`, `finish.md`, `shaping-moves.md`; each at most 120 lines |
| Delete | `canonical/skills/aid-describe/` | Retired whole (Q48; see Components for where its parts go) |
| Delete | `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/` | Retired (Q22, AC-43) |
| Create | `canonical/aid/templates/kind-catalog.yml` | The rules for each kind of thing (Q45; see Kinds of things); type `template-own` |
| Edit | `canonical/aid/templates/shortcut-catalog.yml` | Every `verb: design` row goes, with any comment naming them; the `aid-brainstorm` row stays, its `intent:` rewritten |
| Edit | `canonical/aid/templates/design-seed.md` | The idea draft's shape (see The idea draft) |
| Edit | `canonical/aid/templates/design-folder-readme.md` and this repository's `.aid/design/README.md` | One lifecycle (see The idea draft) |
| Create | `canonical/aid/scripts/works/idea-drafts.sh` | Bash, like the other `works/` scripts: where a draft is, and the only code that moves, commits or deletes one (see The idea draft) |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | `--pipeline` accepts the field `"Idea Draft"`, key `idea_draft`; value `--` or `.aid/design/<name>.md` (lowercase letters, digits and hyphens), anything else exit 4 |
| Edit | `canonical/aid/templates/work-state-template.yml` | `idea_draft: --` with its `[W]` comment |
| Edit | `canonical/aid/templates/skill-steps.md` § When approvals happen (Feature 002) | The deletion rule (see The idea draft) |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3b, its legacy block (Feature 002) | Rows for old idea and design works (see Migration) |
| Edit | `canonical/skills/aid-orchestrate/references/size-and-route.md`, `check-intent.md` (Feature 001) | Two routing rows, the kind hook, drafts as evidence (see Components) |
| Edit | `canonical/aid/rules.md` § Skill guide | The `/aid-describe`, `/aid-design` and `/aid-design-<kind>` lines go; the `/aid-brainstorm` line is rewritten |
| Edit | `canonical/aid/templates/shortcut-engine.md` § Step 2: Read context; `canonical/skills/aid-create-document/SKILL.md`, `canonical/skills/aid-update-document/SKILL.md` | Their reads of `.aid/design/<kind>.md` go: no skill writes a draft under a kind's name any more, and a draft reaches the next phase through the work record |
| Edit | `canonical/aid/templates/design-lifecycle.md` | Only the rules for the KB-writing `create` / `update` skills Feature 004 retires stay (see Components) |
| Edit | every other `canonical/` line naming `/aid-describe`, `/aid-design` or an `aid-design-*` skill | Re-pointed (see Migration) |
| Edit | `dashboard/home.html` (the empty-state steps) and `dashboard/server/tests/test_index_html.py` | "run `/aid-describe`" becomes "tell your AI tool what you want to build" |
| Create | `tests/canonical/test-idea-shaping.sh`, `tests/canonical/test-idea-drafts.sh`, `tests/conversation/samples/feature-003/` | See Testing |

##### 2. The idea draft

**Where it lives (Q44, Q50; known issue KI-004).** A draft has exactly one live copy, found through
`idea-drafts.sh path <name>`:

- **Loose** (the default): in the project's **main folder**, `.aid/design/<name>.md`, never staged and never
  committed, so it outlives a cancelled work and every later work and session can find it.
- **Tracked on the work's branch**: in the work's worktree, `.aid/design/<name>.md`, when git tracks it on the
  branch checked out there -- because the user asked to keep it with the work, or because the work inherited
  it from its parent branch (a seed someone committed by hand).

The work record stores only the draft's identity, `idea_draft: .aid/design/<name>.md`. **Every reader and
writer resolves the live copy with `idea-drafts.sh path` first** -- `aid-brainstorm`, the deletion rule,
and Feature 005 when Specification reads the draft -- and never opens the identity as a path inside a
worktree. A sub-agent never touches the draft: it returns text, and the main conversation writes it.

`idea-drafts.sh` is the only code that moves, commits or deletes a draft:

| Operation | Does |
|---|---|
| `dir` | Prints the absolute path of the main folder's `.aid/design/` (the main worktree, resolved the way `worktree-lifecycle.sh` resolves it, from any worktree); without git, the project folder's `.aid/design/` |
| `path <name>` | Prints the live copy: the current worktree's `.aid/design/<name>.md` when git tracks it on the current branch, otherwise `dir`'s `<name>.md` |
| `list` | One line per draft in the main folder (name, first line under `## Problem`), plus drafts left untracked in another worktree by an old run (KI-004), each marked with that worktree |
| `collect <name> --from <worktree>` | Moves such a left-behind draft into the main folder, loose |
| `keep <name>` | Run inside a work's worktree: moves the loose draft into it and commits that path alone on the work's branch; run again, commits the draft's later changes |
| `release <name>` | The reverse: copies the worktree copy to the main folder, loose, and commits the draft's removal from the work's branch (that path alone) |
| `commit-on <name> <branch>` | Commits the loose draft onto an existing local branch the user named: a normal commit of that path alone when the main folder has that branch checked out, otherwise a commit made without checking the branch out, so the main folder's checked-out branch and files stay as they were |
| `delete <name>` | Loose: removes the file. Tracked on the current branch: removes it and commits the removal (that path alone) on that branch |

- Exit codes: 0 done; 2 a bad `<name>` (only lowercase letters, digits and hyphens; `README` refused) or a
  path outside `.aid/design/`, checked before anything runs; 3 git needed and absent; 4 the branch cannot
  take a commit (none checked out, a merge or rebase in progress) or `keep` / `release` run outside a work's
  worktree; 5 no such draft or branch.
- **No push, ever.** The script has no `git push`, and no other code stages `.aid/design/`.

**Committing is never the default (Q50).**
- **A draft of a work** is committed only when the user asks to keep it with the work (`keep`), and then on
  **that work's branch**; it is re-committed when the user pauses or ends the conversation, and at FINISH. It is removed
  from the branch at the covering approval (below), so the PR/MR's final content never holds it -- its
  history may (AC-35). FINISH asks once (see Flow).
- **A parked idea** (no work continues with it) stays loose in the main folder unless the user names a
  branch to commit it on. Then the agent first says in one line that every work started from that branch
  will carry the draft, and runs `commit-on`. No commit ever lands on the main folder's branch by default.
- With no git, nothing is asked.

**Deletion (M5, AC-17)** -- `skill-steps.md` § When approvals happen gains one rule, applied right after the
approval is recorded, when the record names an `idea_draft`:

| The draft was handed on | Deleted at |
|---|---|
| To Specification, or back into a work whose covering approval is still ahead (a side idea, see Flow) | the `REQUIREMENTS.md` approval (`full`) or the confirmation before building (`lite`) |
| To a KB update | the approval of the KB change (owed by Feature 004, see Flow) |
| Back into a work already past that approval (a side idea) | the work's next approval of any kind |

The approval's own message says the draft will be removed, so the user's yes covers it. `idea-drafts.sh
delete` then removes the live copy -- committing the removal when the draft is tracked on the work's branch,
including one inherited from the parent branch, whose removal the PR/MR then carries -- and the key is
cleared (`--pipeline --field "Idea Draft" --value --`).

**Name**: a new draft takes the work's short name, asked once at intake (Feature 002). A draft picked up
again keeps its own name. When the name is taken by an unrelated draft, the agent proposes `<name>-2` as a
confirmation question. **One draft per work**: a side idea started while the work still names an
`idea_draft` continues that draft.

**Its shape** (`design-seed.md`) -- one plain document that stands on its own, because it can outlive the work
and the work's `qa` record:

```markdown
# {Idea title}
## Where we left off  -- the subject under discussion and what waits for the user; rewritten every exchange
## Problem            -- in the user's words
## Who it is for
## Options considered -- including the ones rejected, and why
## Current direction  -- rewritten as the conversation moves
## Constraints
## Open questions     -- what is still undecided; carried into Specification
## Kind               -- optional: a kind from kind-catalog.yml
## Sources            -- optional: tickets, issues, files that fed it
```

`## Destination` and the readiness gate on `## Open questions` go: what is still open when the user decides
to go on is carried into Specification, whose question protocol asks it. No `## Change Log`.

**Folder README** (`design-folder-readme.md`): one lifecycle -- "An idea draft is written by `/aid-brainstorm`
(or by hand) while an idea is shaped, and is deleted at the first approval that covers its content. Drafts
of ideas not taken forward are kept. AID commits a draft only when you ask." The write-on-first-use rule
stays (in `start.md`): copy it when `README.md` is absent, never overwrite one.

##### 3. Flow

Brainstorm is a **conversation** (Q49). The gate creates the work with
`--skill aid-brainstorm --step START --phase Definition` (Feature 002); `/aid-orchestrate` starts it for a
bare idea, an unclear problem or a request to design something (Feature 001 routing).

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` | main conversation | `CHAIN` -> CONVERSE |
| CONVERSE | `references/converse.md` | main conversation (may dispatch `aid-architect`) | `ASK` -> CONVERSE after every agent turn; `CHAIN` -> CHECK only when the user ends the conversation |
| CHECK | `references/check.md` (brief: `references/reviewer-brief.md`) | `aid-reviewer` | `CHAIN` -> FINISH |
| FINISH | `references/finish.md` | main conversation | `ASK`, then `PASS` or `HALT` (below) |

1. **START** -- gather what the idea starts from: the request, the kind (`check-intent.md`'s match against
   `kind-catalog.yml`, or the typed `<kind>` argument), and the work's `sources:` (Feature 001). Run
   `idea-drafts.sh list`; when a draft matches the request by meaning, or the user named one, offer to
   continue it -- one question with a recommendation; a draft left in another worktree is first `collect`ed.
   Otherwise create the draft from `design-seed.md`. Write the folder README on first use. Record
   `idea_draft`.
2. **CONVERSE** -- a loop the user leads. Each turn:
   - the user shares, reacts, answers or redirects;
   - the agent **proposes** -- options, suggestions, alternatives, challenges, concrete examples --
     grounded in the KB and the code, and **asks** what it needs under the question protocol, the kind's
     `shape` points among the first (`shaping-moves.md` says how);
   - the agent updates the draft (resolved with `path`) after **every** exchange, `## Where we left off`
     included, records the answers (`--answer`), and saves the step with `--detail` naming the subject
     under discussion (e.g. `'talking about: who it is for; waiting for Q14'`).

   When the agent needs research to propose well, it dispatches `aid-architect` (tiered by
   `agent-dispatch-tiering.md`) as a worker: it reads the KB, the code and the draft, and returns options
   and evidence as text; it never asks the user and never writes a file.
   - **Only the user ends the loop.** When the agent has nothing pressing to propose or ask, it asks
     exactly: "Do you have anything else you would like to add or discuss?" -- with no recommendation and
     no options, an exception to the protocol's recommendation rule set by Q49 -- and never suggests
     wrapping up. The user ending it, in any words, moves to CHECK.
   - **Pausing** is allowed at any moment: the work stays at CONVERSE, and any later session (FR-20)
     resumes the conversation from the draft's `## Where we left off`, the saved `step_detail` and the open
     questions, which come first.
   - A ticket or file pulled in meanwhile goes through Feature 001's apply step (`external-sources.md`): the
     questions it answers are closed and the draft updated.
3. **CHECK (Q46)** -- one clean-context `aid-reviewer` pass. It reads the draft, the KB documents it cites
   and the work's `qa` answers, and reports only, under `### What to report`: a conflict with the KB, a
   conflict with a user's answer, something stated as decided that the user never decided, and a `shape`
   point of the kind neither settled nor listed as open. Ledger:
   `.aid/.temp/review-pending/<work>-idea-check.md` (7 columns). The main conversation fixes each row once,
   or brings it to the user. No grade, no second pass.
4. **FINISH** -- the draft is shown in chunks, one topic per chunk, most important first (Feature 002
   reviews), then one group of questions, subject "The idea draft". What it asks depends on how brainstorm
   is running.

**In Definition** (the work's phase is Definition and there is no open call):
1. **Approve the draft** -- `full` only (Feature 002's approvals table), importance high; recorded
   `category: Approval`, `covers: idea draft`.
2. **Where it goes next (Q47)** -- importance high. The user decides; the agent recommends the kind's `then`
   (Specification when there is no kind):
   - *Specification* -- turn it into requirements and build it: `PASS` -- `--handoff --to aid-specify --step
     <its entry step> --returns no --phase Specification --why 'idea shaped: <draft>'`, and `aid-specify`
     starts in the same turn (AC-38 (a)); its entry step is the first row of its step table, read when the
     skill runs;
   - *KB update* -- record it in the KB (e.g. the roadmap, the backlog, the MVP): `PASS` -- `--handoff --to
     aid-update-kb --step <its entry step> --returns no --why ...`, with no `--phase` (Preparation is not a
     work phase); what happens next is Feature 004's (Dependencies below);
   - *Keep it for later* -- **park** it.
3. **Keep the draft with this work?** -- asked only when the idea goes on and git exists; importance low;
   recommendation **no**, because the draft is deleted at the next covering approval and stays safe in the
   main folder meanwhile; yes runs `keep`. The user may also ask to keep it at any moment in CONVERSE.

**Parking** -- choosing *Keep it for later*, or saying so at any question. The answer that chooses it is the
confirmation; said elsewhere, one confirmation question comes first ("Close this work and keep the draft for
later?"). Then: a draft kept with the work is `release`d to the main folder; one question, "Commit the draft
on a branch?", recommendation **no** (it stays in the main folder, uncommitted), with the user naming a
branch as the other answer (`commit-on`, after its one-line warning); then the work is cancelled the way
`/aid-orchestrate` cancels one (`writeback-state.sh --pipeline --field Lifecycle --value Canceled`), and the
user is told in one line how to pick the idea up: say so, and a new work's START offers the draft. Pausing
is not parking.

**As a side idea** -- brainstorm runs inside a work that continues: an open call from another skill, or a
typed start on a work already past Definition. **The work is never cancelled.** No approval of the draft
(it is not in the approvals table outside Definition). One question, where it goes:
- *Back into the work* (recommended) -- the draft stays the work's `idea_draft`, the work's own skill takes
  it in, and it is deleted at the work's next approval (deletion table);
- *Keep it for later* -- the draft becomes a standalone idea: `release` it if it was kept with the work, clear
  `idea_draft`, then the same branch question as parking.

Either way the work goes back where it was: `HALT`, which returns to the open call; or, after a typed start,
`PASS` back to the skill that drives the work's phase, at its entry step, without `--phase`.

**What Feature 004 must provide for the KB-update branch** (row on the deferred list, see Testing):
- a `KB change` row in `skill-steps.md`'s approvals table: the approval of the KB change a work makes, at
  every depth where that change is the work's result, recorded `category: Approval`, `covers: KB change`
  -- the deletion rule fires on it;
- the KB update skill, when it is a work's `PASS` target, reads the work record, uses the draft (resolved
  with `path`), and ends by passing the work to its close: the CI minimum (marking the work done), run by
  `/aid-orchestrate` until Feature 008 delivers `/aid-monitor-pipeline` (Feature 001 phase table).

Until Feature 004 lands, the KB-update answer reaches today's `aid-update-kb`, which reads no work state, so
the work stays open; nothing is released in between.

##### 4. Kinds of things

`canonical/aid/templates/kind-catalog.yml` (Q45) -- block style, one entry per kind. Feature 003 creates it;
Feature 009 adds its own fields to the same entries and makes it the one catalog. It installs as-is to
`.aid/runtime/templates/kind-catalog.yml`, like `shortcut-catalog.yml`.

```yaml
version: 1
kinds:
  - kind: api
    about: 'an API: what other programs call, its resources and contract'
    shape: 'the resource shape; the request and response contract; the error model'
    then: Specification
  - kind: roadmap
    about: 'the project roadmap: where it is going and in what order'
    shape: 'what is committed and what is only wanted; the order, and why'
    then: KB update
```

- **Kinds**: those of today's `aid-design-*` skills -- api, ui, theme, cli, data-model, data-pipeline,
  messaging, integration, job, config, infra, test, document, dashboard, architecture, stack,
  testing-strategy, cicd, roadmap, mvp, backlog.
- **`about`**: one line in plain words, used to read a plain request (`check-intent.md`).
- **`shape`**: what an idea of that kind must settle, taken from the retiring skill's own statement of what
  its seed must settle.
- **`then`**: `Specification` or `KB update` -- only the **default recommendation** at FINISH (Q47).
  `KB update` for roadmap, mvp and backlog (FR-14); `Specification` for every other kind, since what it
  shapes is built and the KB records it once decided or built (FR-10).
- A typed `/aid-brainstorm api orders` and "design the orders API" reach the same entry.

##### 5. Components

**`/aid-brainstorm` description** (Feature 001's shape; final text set at build):
"Talk an idea through, or a problem that is not yet clear, into an idea draft in `.aid/design/`, across
sessions if needed, also for a kind of thing (an API, a screen, a data model). Use when the user has only an
idea, wants to design something before it is built, or cannot yet say what the problem is." Skill-guide
line, within SG-03's limit: `` - `/aid-brainstorm` -- talk an idea or a design through; when the problem is unclear ``.

**Where `aid-describe`'s parts go (Q48):**

| Part | Goes to |
|---|---|
| The analyst moves and the assumption guards (`references/move-playbook.md`; `references/advisor-stance.md` § Anti-Anchoring, Assumption-Flagging, and Distortion Guards) | Condensed into `aid-brainstorm/references/shaping-moves.md`: propose something concrete and let the user correct it; keep the user's own terms; ask what is in and out; offer one concrete example; challenge an assumption with a reason; at most two "why" questions in a row; note what can wait and move on; restate an answer before replacing it |
| The question envelope and `references/calibration.md` | Not kept: the question protocol (Feature 002) covers them |
| The requirements interview (`state-first-run.md`, `state-continue.md`, `state-q-and-a.md`, `state-completion.md`, `interview-loop.md`, `interview-strategies.md`, `elicitation-engine.md`) | Not kept: `/aid-specify` gathers requirements through the question protocol (Q1, Feature 005) |
| The new-project KB seed (`state-describe-seed.md`, `kb-hydration.md`, `coherence-check.md`) | Not kept: the KB grows as things are decided or built (FR-10, Feature 004) |

**Routing** -- `size-and-route.md` (Feature 001) gains two rows in its phase table:

| Reading | Phases |
|---|---|
| Design a kind of thing (shape it before building) | Definition (`/aid-brainstorm` with that kind) -> then as the user decides at FINISH |
| Shape a roadmap, backlog or MVP | Definition -> KB update, unless the user decides otherwise at FINISH |

`check-intent.md`'s kind hook matches design requests against `kind-catalog.yml` `about:`; a draft that
`idea-drafts.sh list` shows matching the request is evidence of an idea already under way, offered at START.

**`design-lifecycle.md`** -- the rules that bind only design-stage writers and `/aid-brainstorm` go (the
`design` stage, the two classes' design rows, the seed naming by kind, `/aid-brainstorm`'s case, their rows
in "What binds which"). What stays serves only the KB-writing `aid-create-*` / `aid-update-*` skills for
architecture, backlog, cicd, mvp, roadmap, stack and testing-strategy, which Feature 004 retires together with
this file.

**Kept invariant**: `/aid-brainstorm` writes only its draft (and the folder README on first use): no KB
document, no production code.

##### 6. Migration

| Old | New |
|---|---|
| `/aid-describe` | Say what you want in plain words; an idea is talked through by `/aid-brainstorm`, requirements are gathered by `/aid-specify` |
| `/aid-design` | `/aid-brainstorm` shapes it; the design that is kept is the technical part of `REQUIREMENTS.md` (`/aid-specify`) |
| `/aid-design-<kind>` | `/aid-brainstorm <kind> ...`, or "design the <kind> ..." in plain words |

- **Release notes**: the three rows join the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md`
  § Next Release. No stubs (M1).
- **Installed projects**: `aid update` removes the retired skill files through the install manifest
  (decisions.md § D9). An existing `.aid/design/README.md` is user data and is never overwritten.
- **Existing works** -- through Feature 002's recovery, which takes the skill and step of a work without a
  record from the legacy block of `work-initiation-gate.md` § 3b. This feature puts two rows at the **top**
  of that block, so they win over the phase rows:

  | Old work | Proposed skill and step |
  |---|---|
  | `pipeline.initiator` is `aid-brainstorm`, `aid-design` or an `aid-design-*` skill (whatever its `phase`) | `/aid-brainstorm` at **START** -- which finds the old draft with `list` (it sits untracked in that work's own worktree), `collect`s it to the main folder and writes `idea_draft`, then continues at CONVERSE |
  | `pipeline.initiator` is `aid-describe`, or `phase: Describe` | `/aid-specify` at its entry step (requirements are gathered there now) |

  An old idea or design work already `Completed` is not resumed (Feature 002's resume table, row 1); its
  draft is found by any new work's START through `list` and `collect`. Feature 006's migration, which fills
  the record of every old work and then removes the legacy block, uses the same two rows. Old `interview:`
  keys are left for that migration.
- **Re-pointed lines** -- a line telling the user to run `/aid-describe` says instead to tell the agent
  what they want: the "No works found" messages of `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`,
  `aid-execute`, `aid-deploy`; the greenfield signpost of `canonical/aid/scripts/kb/recon-classify.sh` and
  `aid-discover` `references/state-generate.md`. Descriptive mentions are reworded or dropped:
  `connectors/consumption-protocol.md`, `requirements/requirements-template.md`, `reviewer-ledger-schema.md`,
  the `> **Source:**` lines of `knowledge-base/domain-glossary.md`, `infrastructure.md`, `integration-map.md`,
  `pipeline-contracts.md`, `shortcut-engine.md`, `shortcut-scaffolding/analyze-report.md`,
  `work-initiation-gate.md`, `work-state-template.yml`, `aid-define` `references/state-done.md`, the
  reviewer briefs of `aid-discover`, `aid-plan` and `aid-specify`, `aid-discover` `references/path-config.md`
  and `references/state-review.md`, `aid-monitor` `references/state-route.md` where Feature 001 left a mention;
  the boundary lines naming `/aid-design` in `aid-prototype`, `aid-prototype-ui`, `aid-document` and
  `aid-create-document`; `aid-research`'s boundary line with `/aid-brainstorm`, reworded to its new job;
  `scripts/checks/review-path-audit.sh`. `aid-discover`'s `greenfield: true` review mode, used only by the
  retired seed step, is left for Feature 004.
- **Tests**: `tests/canonical/test-describe-full-only.sh` is deleted; the suites that name the retired
  skills (`test-work-initiation-gate.sh`, `test-path-fixtures.sh`, `test-pipeline-status-walkthrough.sh`,
  `test-work-state-template.sh`, `test-cutover-no-dangling.sh`, `test-connector-consumption-linkage.sh`,
  `test-ticket-retirement-structural.sh`, `test-deploy-monitor-repurpose.sh`, `test-prototype-family-scaffold.sh`)
  change with them; `test-work-initiation-gate.sh` gains a `--check` fixture for each new legacy row; the
  site scripts that list skills (`site/scripts/skills/`, `site/scripts/lib/flow-graph/`,
  `site/scripts/.skills-manifest.json`) and their `__tests__`; pages and flows regenerated by
  `site/scripts/gen-skills.mjs`. Removed assertions go to `tests/coverage-accepted-removals.tsv`;
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv` are re-recorded.
- **User documentation** waits for the final documentation pass (Q40, AC-45). The only edit now: the
  numbers `tests/canonical/test-doc-counts.sh` asserts in `docs/`, so CI stays green.
- **Dashboard**: the readers' `SHORTCUT_KIND_MAP` (`dashboard/reader/state_schema.py`, `reader.mjs`) keeps
  the retired names as historical initiators, and `_FULL_PATH_INITIATOR` stays, so old works still show
  their kind; only the empty-state text changes.
- **KB** (no work ids): `architecture.md` (the design family row), `capability-inventory.md`,
  `module-map.md`, `pipeline-contracts.md` (the `design` verb rows), `domain-glossary.md` (idea draft;
  the design family and describe go), `project-structure.md` (`.aid/design/`), `artifact-schemas.md`
  (`idea_draft`, `kind-catalog.yml`), `test-landscape.md` (the two new suites), `roadmap.md` § MVP (the
  delivered `/aid-design-roadmap`, `/aid-design-mvp`, `/aid-design-backlog` are retired), `tech-debt.md`
  row SY-4 (resolved: the DESCRIBE-SEED tracking block goes with `aid-describe`). `decisions.md` gains
  "ideas are talked through by one skill; drafts live in the main folder and are committed only on
  request", which supersedes D27 (`design` as a grid verb) and D24 (`/aid-describe` reduced to the full
  path), and amends D28's consequence (no `create` step now turns a seed into a KB fact: a KB update does,
  through the normal flow); all three marked in the summary table and their sections. Then `INDEX.md` is
  regenerated.

##### 7. Testing

Per NFR-T (Q35): unit tests and static checks now; a sample that needs a later feature waits on the
deferred-tests list.

**Static checks -- `tests/canonical/test-idea-shaping.sh`** (picked up by `tests/run-all.sh`; added to the
suite list of `.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| ID-01 | No `canonical/skills/aid-describe/`, `canonical/skills/aid-design/` or `canonical/skills/aid-design-*/`; no `verb: design` row in `shortcut-catalog.yml` |
| ID-02 | `aid-describe` and `aid-design` (any form) appear nowhere under `canonical/` or in `dashboard/home.html`, except files of entries on the shared exempt list marked for ID-02, and the legacy block of `work-initiation-gate.md` |
| ID-03 | Under `canonical/skills/` and `canonical/aid/templates/`, `.aid/design/` is named only by `aid-brainstorm`'s files, `design-seed.md`, `design-folder-readme.md`, `kind-catalog.yml`, `shortcut-catalog.yml` (the `aid-brainstorm` row), `skill-steps.md`, `work-initiation-gate.md`, `aid-orchestrate`'s references, and entries on the shared exempt list marked for ID-03; no file but `idea-drafts.sh` runs `git add`, `git rm` or `git commit` on `.aid/design/`; no `git push` in `idea-drafts.sh` |
| ID-04 | Every `kind-catalog.yml` entry has non-empty `kind`, `about`, `shape`, and `then` equal to `Specification` or `KB update`; `aid-brainstorm`'s `start.md` cites the file |
| ID-05 | `design-seed.md` has the headings of The idea draft; `design-folder-readme.md` has its lifecycle section (presence only) |
| ID-06 | `skill-steps.md` § When approvals happen names `idea_draft` and `idea-drafts.sh`; `work-state-template.yml` has the key |
| ID-07 | `aid-brainstorm`'s step table has START, CONVERSE, CHECK and FINISH; FINISH advances by `PASS` and `finish.md` names `aid-specify`; `converse.md` holds the closing question of Q49 |

**Shared exempt list** -- `tests/canonical/skill-steps-exempt.tsv` (Feature 002) gains the codes `ID-02` and
`ID-03` in its `checks` column, for the KB-writing `aid-create-*` / `aid-update-*` skills of architecture,
backlog, cicd, mvp, roadmap, stack and testing-strategy, and for `canonical/aid/templates/design-lifecycle.md`,
all with owner Feature 004. Its rows for `aid-brainstorm`, `aid-design` and every `aid-design-*` go. Feature
001's description exempt list (SG-04) loses its describe, design and brainstorm rows.

**Unit tests**
- `tests/canonical/test-idea-drafts.sh`, on throwaway git fixtures with a main folder and a worktree: `dir`
  gives the same main-folder path from both, and the project folder without git; `path` gives the worktree
  copy only when git tracks it on the worktree's branch, the main-folder copy otherwise; `list` shows a draft
  left untracked in another worktree, and `collect` moves it; `keep` moves the draft into the worktree and
  commits only that path on the work's branch, and refuses in the main folder; `release` restores the loose
  copy and commits only the removal; `commit-on` commits on the checked-out branch, and on another branch
  leaves the main folder's branch, index and files unchanged; `delete` removes a loose draft without a
  commit, and a tracked one with a removal commit of that path alone; another staged file is never committed;
  exit 3 without git, 4 on a detached head or during a merge, 5 for an unknown draft or branch, 2 for
  `README`, a name with `/` or `..`, or a path outside `.aid/design/`, each changing nothing.
- `tests/canonical/test-writeback-state.sh`: `--pipeline --field "Idea Draft"` accepts `--` and a valid
  identity, refuses any other value with exit 4; the file still parses through the dashboard reader.

**Conversation samples -- `tests/conversation/samples/feature-003/`** (frontmatter `skills: aid-brainstorm`)

| Sample | Covers | Runs |
|---|---|---|
| `003-01-conversation-across-sessions` -- a bare idea; the agent proposes options and challenges, the user pauses; a second session by another persona continues; check: the draft in the main folder updated after every exchange, `## Where we left off` and `step_detail` match the last subject, the second session picks up there, no wrap-up is suggested, and the conversation ends only when the user says so | AC-17, AC-28, AC-37 | now |
| `003-02-design-a-kind` -- "design the orders API"; check: no `aid-design*` skill exists or is run, the draft's `## Kind` is `api` and api's `shape` points are raised early, no KB or code file written | AC-43, AC-28 | now |
| `003-03-unclear-ticket` -- a ticket exported as a file, whose problem is unclear; check: a `sources:` entry, the draft's `## Sources` names it, questions the ticket answers are not asked | AC-28 | now |
| `003-04-park-and-pick-up` -- the user parks the idea and names no branch; a later session picks it up; check: the work `Canceled`, the draft loose and uncommitted in the main folder, no commit made anywhere, the new work's START offers it | AC-17 | now |
| `003-05-park-on-named-branch` -- the user names the branch `ideas`; check: the one-line warning, one commit on `ideas` touching only the draft, the main folder's checked-out branch unchanged, nothing pushed | AC-17 | now |
| `003-06-side-idea-never-cancels` -- fixture: a work in Specification; the user brainstorms a side idea and keeps it for later; check: the work not cancelled, its skill and phase restored, the draft loose in the main folder, `idea_draft` cleared | AC-17, AC-37 | deferred: Feature 005 |
| `003-07-finish-next-step` -- check: the next-step question recommends the kind's `then`, the user's choice is recorded, and the hand-off goes where the user chose | AC-17, AC-38 | deferred: Feature 005 |
| `003-08-kept-draft-removed-at-approval` -- the user keeps the draft with the work; check: committed on the work's branch only, removed with a commit at the `REQUIREMENTS.md` approval, the branch's final content holds no draft, `idea_draft` cleared | AC-17, AC-35 | deferred: Feature 005 |
| `003-09-deleted-at-lite-confirmation` | AC-17 | deferred: Feature 007 |
| `003-10-roadmap-to-kb` -- "let's rethink the roadmap"; check: KB update recommended and chosen, the roadmap KB document updated, the draft deleted at the KB change approval, the work closed as done | AC-43 | deferred: Feature 004 (needs: the `KB change` approval row and the KB update skill's close, Flow) |

**Deferred list** (`tests/conversation/deferred.tsv`): the rows `skill:aid-brainstorm`, `skill:aid-describe`,
`skill:aid-design` and `skill:aid-design-*` go (the first is covered by these samples, the others leave with
their skills); `002-12` now waits only for Feature 005 and `002-08` for Features 005, 006 and 007; the five
deferred samples above are added, `003-10` with the two Feature 004 needs in its `needs` column. Feature
001's `001-08-bare-idea` is run again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-17 | The idea draft (where it lives, the record, `idea-drafts.sh`, the deletion rule, commits only on request); Flow (START, CONVERSE, FINISH, parking, side ideas) | ID-03, ID-05, ID-06, ID-07; `test-idea-drafts.sh`; writer unit tests; `003-01`, `003-04`, `003-05`; `003-06` to `003-09` (deferred) |
| AC-43 | Files and layout (deletions); Kinds of things; Components (routing, the kept invariant) | ID-01 to ID-04; `003-02`; `003-10` (deferred) |

### Feature 004 — Self-Maintaining KB with an Always-Current Web View

- **Priority:** Must
- **Requirements:** §5 FR-2, FR-10, FR-14
- **Criteria:** AC-15, AC-18, AC-39

#### Description

`/aid-kb-build`, `/aid-kb-query`, `/aid-kb-update` and `/aid-kb-show`, run by the agent's own judgment; summarize, `/aid-housekeep` and the skills that only wrote KB documents (architecture, stack, testing strategy, CI/CD, roadmap, backlog, MVP) are absorbed. In a new project the KB grows as things are decided and built. Roadmap, backlog and MVP become ordinary KB documents. KB management is simplified: the HTML view (`kb.html`) is generated automatically when the KB is built and refreshed whenever it is updated.

#### User Stories

- As an AID user, I want the KB built, consulted and kept current without asking, so that the agent always works from accurate facts.
- As an AID user starting a new project, I want the KB to grow as decisions are made, so that it never holds guesses.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 005 — Specification with Both Business and Technical Detail

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-3, FR-11, FR-15; §6 NFR-N
- **Criteria:** AC-12, AC-16, AC-44

#### Description

`/aid-specify` (today's define and specify merged) produces `REQUIREMENTS.md` made of requirements with acceptance criteria. It splits the work into features only when it delivers several user-visible capabilities. The document carries both the business view of the work (what and why) and its technical view (how). Before it starts, the agent checks the effort level and recommends a higher one when it is below high.

#### User Stories

- As an AID user, I want one requirements document, split into features only when there really are several capabilities, so that I review what matters and nothing invented.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 006 — Planning by Deliveries and Waves That Follow Task Dependencies

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-11, FR-12
- **Criteria:** AC-19

#### Description

`/aid-plan` (today's plan and detail merged) writes `PLAN.md` as an improved TODO list: deliveries with their acceptance criteria, waves, atomic tasks, dependencies and state. Each task keeps one instruction file, linked from `PLAN.md`, with no state of its own. One `STATE.yml` per work; no delivery documents or state files. Tasks are grouped into deliveries and waves that respect the task dependency tree. Moving existing works to the single state file includes turning each old `ticket_ref` into an entry of the work's `sources:` list (FR-18; bash and PowerShell twins with identical output).

#### User Stories

- As an AID user, I want the plan as a short checklist of tasks and their order, so that I can see progress at a glance.
- As a maintainer, I want one state file per work and no delivery documents, so that there is less to keep consistent.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 007 — Hands-Off Building with Built-In Verification and Simplification

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-6, FR-11, FR-19
- **Criteria:** AC-26, AC-32, AC-33, AC-34

#### Description

`/aid-execute` carries out the plan's tasks and tests them: a task is done only when its tests pass, and the result shows the test outcome. It opens with the confirmation before building (where the per-wave option is asked); after that the user is involved only at the building milestones defined in FR-6 and for real blockers; each task, and each delivery as a whole, goes through verification, then a lighter simplification pass, then a scoped re-verification only when the simplification changed something (FR-19). Each work builds on its one worktree and branch; the per-delivery branches are removed. It runs the FR-6 milestone steps, including the hand-offs to the CI skill.

#### User Stories

- As an AID user, I want every task built and tested before it counts as done, so that what I approve at the end actually works.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 008 — Pull Requests Kept on Track Through Reviews and Pipeline Failures

- **Priority:** Must
- **Requirements:** §5 FR-6, FR-7, FR-11, FR-16, FR-20
- **Criteria:** AC-13, AC-27, AC-35, AC-36, AC-42

#### Description

`/aid-monitor-pipeline` creates or updates the PR/MR only on the user's instruction -- during building it acts only through the FR-6 milestone hand-offs, and full monitoring starts once the whole build is approved -- and takes it to a mergeable state: review comments, a green pipeline, hardening, security and quality reviews -- without ever merging. Reported bugs, required corrections and pipeline failures are corrected automatically; suggestions are brought to the user with a recommendation; every correction is built, verified and approved by the user before it is pushed. When GitHub or GitLab cannot be reached, the agent first helps the user connect. The PR/MR holds only the real changes; whether the work folder is pushed, kept locally or deleted is a project setting. After the merge the agent marks the work done and cleans up locally only (temporary files, local branch, worktree); it never deletes a remote branch. Marking the work done is the minimum of this phase, even for a project with no repository. It integrates with and monitors the project's CI/CD process, reacting to reviews and to pipeline failures until a human merges the PR/MR into its parent branch (usually `main` or `master`) -- the end of the work's CI. Deploying and monitoring production are separate works.

#### User Stories

- As an AID user, I want the agent to bring my PR/MR to a mergeable state when I ask, and to help me connect if it cannot reach GitHub or GitLab, so that the last step does not stall while the merge stays mine.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 009 — One Obvious Skill for Each Need

- **Priority:** Must
- **Requirements:** §4 Scope (wrapper skills); §5 FR-4, FR-8; M1
- **Criteria:** AC-20, AC-30, AC-31

#### Description

Today AID has a separate skill for every pair of action and kind of thing (`/aid-create-api`,
`/aid-update-ui`, `/aid-design-data-model`, ...) -- 78 near-identical names. They become **one skill
per action**: `/aid-create`, `/aid-update`, `/aid-document`, `/aid-test`, `/aid-prototype`.
`/aid-design` retires: shaping an idea for a kind of thing is `/aid-brainstorm`'s job (using the
catalog's rules for that kind, Feature 003), and the design that is kept -- how it will be built --
is the technical part of Specification (Feature 005). The kind of thing is given as an argument (`/aid-create api endpoint for orders`)
or in plain words (*"create an API endpoint for orders"*); both reach the same skill and the same
rules. The rules for each kind of thing (what to ask, what to check, which tests) live in **one
catalog**, which the agent also uses to understand plain requests (FR-4). Skills that only wrote KB
documents (architecture, stack, testing strategy, CI/CD, roadmap, backlog, MVP) and `/aid-housekeep`
fold into KB management (Feature 004); `/aid-triage` folds into the skill guide (Feature 001). `/aid-config` becomes `/aid-configure`, so every skill name is a verb. The
dashboard and chat show the new names.

#### User Stories

- As an AID user, I want one clear skill for each action, so that I never have to choose between near-identical names.
- As an AID user, I want to type `/aid-create api ...` or just say "create an API endpoint", so that both routes give the same result.
- As a maintainer, I want the rules for each kind of thing in one catalog, so that a change happens in one place.

#### Technical Specification

*(pending -- added by `/aid-specify`)*
